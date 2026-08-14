import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:io';

import 'package:drift/backends.dart';
import 'package:drift/drift.dart' show OpeningDetails;
import 'package:drift/native.dart';
import 'package:ffi/ffi.dart';

/// Which SQL dialect the underlying executor speaks.
///
/// The engine's SQL is almost entirely portable — every query goes through
/// drift's [QueryExecutor], not a SQLite-specific API. Three things are not:
/// the WAL pragma, JSON extraction for sort keys, and the version probe. This
/// enum exists so those three can branch, rather than forcing a second copy of
/// the whole store.
enum WorkflowSqlDialect {
  sqlite,
  postgres;

  bool get isSqlite => this == WorkflowSqlDialect.sqlite;
}

/// Thin wrapper around a SQL connection with the two-table schema from §3d.
///
/// Runs on SQLite on the device and on PostgreSQL server-side, over the same
/// code. That is the point: the workflow engine is one implementation of the
/// guard, formula and effect semantics, executed in both places. A second
/// implementation for the server would have to agree with this one on every
/// input of a 23-function expression language, and nothing could prove that it
/// did.
class WorkflowDatabase {
  static bool _sqliteProcessSymbolsLoaded = false;

  final QueryExecutor _db;
  final WorkflowSqlDialect _dialect;
  final _WorkflowDatabaseUser _user = _WorkflowDatabaseUser();
  Future<void>? _openAndMigrated;

  WorkflowDatabase._(this._db, this._dialect);

  /// Opens an in-memory SQLite database for tests and ephemeral demo state.
  factory WorkflowDatabase.memory() {
    _loadSqliteProcessSymbols();
    return WorkflowDatabase._(
      NativeDatabase.memory(),
      WorkflowSqlDialect.sqlite,
    );
  }

  /// Opens a file-backed SQLite database.
  factory WorkflowDatabase.file(String path) {
    _loadSqliteProcessSymbols();
    return WorkflowDatabase._(
      NativeDatabase(File(path)),
      WorkflowSqlDialect.sqlite,
    );
  }

  /// Wraps an externally-created executor — the server passes a PostgreSQL one.
  ///
  /// Kept dependency-free on purpose: this package does not depend on
  /// `drift_postgres`, so the service supplies the executor and the engine
  /// stays usable on-device without pulling a Postgres driver into the app.
  factory WorkflowDatabase.withExecutor(
    QueryExecutor executor, {
    required WorkflowSqlDialect dialect,
  }) {
    return WorkflowDatabase._(executor, dialect);
  }

  bool get isSqliteBacked => _dialect.isSqlite;

  String get storageBackend =>
      _dialect.isSqlite ? 'drift-native-sqlite' : 'drift-postgres';

  Future<void> _ensureOpenAndMigrated() {
    return _openAndMigrated ??= () async {
      await _db.ensureOpen(_user);
      if (_dialect.isSqlite) {
        // WAL is a SQLite concept; PostgreSQL is already write-ahead logged.
        await _db.runCustom('PRAGMA journal_mode=WAL;');
      }
      await _migrate();
    }();
  }

  Future<void> _migrate() async {
    await _db.runCustom('''
      CREATE TABLE IF NOT EXISTS workflow_definitions (
        definition_id TEXT PRIMARY KEY,
        workflow_type TEXT NOT NULL,
        definition_json TEXT NOT NULL,
        version INTEGER NOT NULL
      );
    ''');
    await _db.runCustom('''
      CREATE TABLE IF NOT EXISTS workflow_instances (
        instance_id TEXT PRIMARY KEY,
        community_id TEXT NOT NULL,
        workflow_type TEXT NOT NULL,
        current_state TEXT NOT NULL,
        instance_data TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        created_by_persona_id TEXT NOT NULL
      );
    ''');
    await _db.runCustom('''
      CREATE INDEX IF NOT EXISTS idx_instances_lookup
        ON workflow_instances (community_id, workflow_type, current_state);
    ''');
  }

  // ── Definitions ────────────────────────────────────────────────────────

  Future<void> upsertDefinition({
    required String definitionId,
    required String workflowType,
    required String definitionJson,
    required int version,
  }) async {
    await _ensureOpenAndMigrated();
    await _db.runCustom(
      'INSERT OR REPLACE INTO workflow_definitions '
      '(definition_id, workflow_type, definition_json, version) '
      'VALUES (?, ?, ?, ?)',
      [definitionId, workflowType, definitionJson, version],
    );
  }

  Future<String?> loadDefinitionJson(String definitionId) async {
    await _ensureOpenAndMigrated();
    final result = await _db.runSelect(
      'SELECT definition_json FROM workflow_definitions '
      'WHERE definition_id = ?',
      [definitionId],
    );
    if (result.isEmpty) return null;
    return result.first['definition_json'] as String;
  }

  // ── Instances: mutations ───────────────────────────────────────────────

  Future<void> insertInstance({
    required String instanceId,
    required String communityId,
    required String workflowType,
    required String currentState,
    required Map<String, dynamic> instanceData,
    required String createdByPersonaId,
  }) async {
    await _ensureOpenAndMigrated();
    final now = DateTime.now().millisecondsSinceEpoch;
    await _db.runCustom(
      'INSERT INTO workflow_instances '
      '(instance_id, community_id, workflow_type, current_state, '
      'instance_data, created_at, updated_at, created_by_persona_id) '
      'VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
      [
        instanceId,
        communityId,
        workflowType,
        currentState,
        jsonEncode(instanceData),
        now,
        now,
        createdByPersonaId,
      ],
    );
  }

  Future<WorkflowInstanceRow?> readInstance(String instanceId) async {
    await _ensureOpenAndMigrated();
    final result = await _db.runSelect(
      'SELECT * FROM workflow_instances WHERE instance_id = ?',
      [instanceId],
    );
    if (result.isEmpty) return null;
    return WorkflowInstanceRow.fromRow(result.first);
  }

  /// Atomically writes new state + data for one instance.
  Future<void> updateInstanceState({
    required String instanceId,
    required String newState,
    required Map<String, dynamic> newInstanceData,
  }) async {
    await _ensureOpenAndMigrated();
    await _db.runCustom(
      'UPDATE workflow_instances '
      'SET current_state = ?, instance_data = ?, updated_at = ? '
      'WHERE instance_id = ?',
      [
        newState,
        jsonEncode(newInstanceData),
        DateTime.now().millisecondsSinceEpoch,
        instanceId,
      ],
    );
  }

  /// Merges field updates into instance_data JSON (within a transaction).
  Future<void> mergeInstanceFields({
    required String instanceId,
    required Map<String, dynamic> fieldUpdates,
  }) async {
    await transaction(() async {
      final row = await readInstance(instanceId);
      if (row == null) throw StateError('Instance $instanceId not found');
      final data = jsonDecode(row.instanceData) as Map<String, dynamic>;
      data.addAll(fieldUpdates);
      await updateInstanceState(
        instanceId: instanceId,
        newState: row.currentState,
        newInstanceData: data,
      );
    });
  }

  // ── Instances: keyset-paginated query ──────────────────────────────────

  /// Keyset-paginated query sorted by [sortKey] (a field in instance_data).
  ///
  /// The [cursor] is a compound cursor `"$sortKey\x1f$sortValue\x1f$instanceId"`.
  /// If the cursor's embedded sort key does not match [sortKey], the cursor is
  /// ignored and results start from page 1 (§3b sort-change reset rule).
  ///
  /// Returns exactly [limit] + 1 rows so callers can detect hasMore.
  Future<List<WorkflowInstanceRow>> queryInstancesKeyset({
    required String communityId,
    String? cursor,
    required int limit,
    required String sortKey,
  }) async {
    await _ensureOpenAndMigrated();
    // JSON extraction is the one query shape the two dialects spell
    // differently. The sort key is a declared instanceDataSchema field name,
    // never caller-supplied text, so interpolating it into the Postgres path
    // expression cannot carry untrusted input.
    final allRowsResult = _dialect.isSqlite
        ? await _db.runSelect(
            'SELECT * FROM workflow_instances '
            'WHERE community_id = ? '
            'ORDER BY json_extract(instance_data, ?) ASC, instance_id ASC',
            [communityId, '\$.$sortKey'],
          )
        : await _db.runSelect(
            'SELECT * FROM workflow_instances '
            'WHERE community_id = ? '
            "ORDER BY instance_data::jsonb #>> ? ASC, instance_id ASC",
            [communityId, '{$sortKey}'],
          );

    final allRows = allRowsResult
        .map((r) => WorkflowInstanceRow.fromRow(r))
        .toList();

    // Apply keyset cursor: skip rows until we pass the cursor position.
    // Cursor format: "$sortKey\x1f$sortValue\x1f$instanceId"
    int startIndex = 0;
    if (cursor != null) {
      final parts = cursor.split('\x1f');
      if (parts.length == 3) {
        final cursorSortKey = parts[0];
        final cursorValue = parts[1];
        final cursorId = parts[2];

        // §3b: sort change must reset pagination.
        if (cursorSortKey == sortKey) {
          for (var i = 0; i < allRows.length; i++) {
            final row = allRows[i];
            final data = jsonDecode(row.instanceData) as Map<String, dynamic>;
            final rowValue = '${data[sortKey] ?? ''}';
            if (rowValue.compareTo(cursorValue) > 0 ||
                (rowValue == cursorValue &&
                    row.instanceId.compareTo(cursorId) > 0)) {
              startIndex = i;
              break;
            }
            startIndex = i + 1;
          }
        }
        // else: cursor sortKey mismatch -> reset to page 1.
      }
    }

    // Return limit+1 to let caller detect hasMore.
    final endIndex = startIndex + limit + 1;
    return allRows.sublist(
      startIndex,
      endIndex > allRows.length ? allRows.length : endIndex,
    );
  }

  Future<int> countInstances(String communityId) async {
    await _ensureOpenAndMigrated();
    final result = await _db.runSelect(
      'SELECT COUNT(*) as c FROM workflow_instances WHERE community_id = ?',
      [communityId],
    );
    return result.first['c'] as int;
  }

  Future<List<WorkflowInstanceRow>> queryInstancesForPersona({
    required String communityId,
    required String personaId,
  }) async {
    await _ensureOpenAndMigrated();
    final result = await _db.runSelect(
      'SELECT * FROM workflow_instances '
      'WHERE community_id = ? AND created_by_persona_id = ? '
      'ORDER BY workflow_type ASC, instance_id ASC',
      [communityId, personaId],
    );
    return result.map((r) => WorkflowInstanceRow.fromRow(r)).toList();
  }

  Future<void> deleteAllInstances() async {
    await _ensureOpenAndMigrated();
    await _db.runCustom('DELETE FROM workflow_instances');
  }

  Future<void> deleteAllDefinitions() async {
    await _ensureOpenAndMigrated();
    await _db.runCustom('DELETE FROM workflow_definitions');
  }

  /// Runs [action] inside a single SQLite transaction (explicit BEGIN/COMMIT/ROLLBACK).
  Future<void> transaction(Future<void> Function() action) async {
    await _executeTx(action);
  }

  Future<void> _executeTx(Future<void> Function() action) async {
    await _ensureOpenAndMigrated();
    await _db.runCustom('BEGIN IMMEDIATE');
    try {
      await action();
      await _db.runCustom('COMMIT');
    } catch (e) {
      await _db.runCustom('ROLLBACK');
      rethrow;
    }
  }

  void close() {
    unawaited(_db.close());
  }

  /// Executes a raw SQL statement (for expression index creation in tests).
  Future<void> execute(String sql) async {
    await _ensureOpenAndMigrated();
    await _db.runCustom(sql);
  }

  /// Diagnostic only — reports the underlying engine's version string.
  Future<String> sqliteVersion() async {
    await _ensureOpenAndMigrated();
    final result = await _db.runSelect(
      _dialect.isSqlite
          ? 'SELECT sqlite_version() AS version'
          : 'SELECT version() AS version',
      [],
    );
    return result.first['version'] as String;
  }

  static void _loadSqliteProcessSymbols() {
    if (_sqliteProcessSymbolsLoaded || !Platform.isLinux) return;

    const rtldLazy = 0x00001;
    const rtldGlobal = 0x00100;
    final dl = DynamicLibrary.open('libdl.so.2');
    final dlopen = dl
        .lookupFunction<
          Pointer<Void> Function(Pointer<Utf8>, Int32),
          Pointer<Void> Function(Pointer<Utf8>, int)
        >('dlopen');

    final candidates = <String>[
      '/usr/lib/x86_64-linux-gnu/libsqlite3.so.0',
      '/lib/x86_64-linux-gnu/libsqlite3.so.0',
      'libsqlite3.so.0',
    ];

    for (final candidate in candidates) {
      final path = candidate.toNativeUtf8();
      try {
        final handle = dlopen(path, rtldLazy | rtldGlobal);
        if (handle != nullptr) {
          _sqliteProcessSymbolsLoaded = true;
          return;
        }
      } finally {
        malloc.free(path);
      }
    }
  }
}

class _WorkflowDatabaseUser extends QueryExecutorUser {
  @override
  int get schemaVersion => 1;

  @override
  Future<void> beforeOpen(
    QueryExecutor executor,
    OpeningDetails details,
  ) async {}
}

/// Typed row for the workflow_instances table.
class WorkflowInstanceRow {
  final String instanceId;
  final String communityId;
  final String workflowType;
  final String currentState;
  final String instanceData; // raw JSON string
  final int createdAt;
  final int updatedAt;
  final String createdByPersonaId;

  const WorkflowInstanceRow({
    required this.instanceId,
    required this.communityId,
    required this.workflowType,
    required this.currentState,
    required this.instanceData,
    required this.createdAt,
    required this.updatedAt,
    required this.createdByPersonaId,
  });

  factory WorkflowInstanceRow.fromRow(Map<String, Object?> row) {
    return WorkflowInstanceRow(
      instanceId: row['instance_id'] as String,
      communityId: row['community_id'] as String,
      workflowType: row['workflow_type'] as String,
      currentState: row['current_state'] as String,
      instanceData: row['instance_data'] as String,
      createdAt: row['created_at'] as int,
      updatedAt: row['updated_at'] as int,
      createdByPersonaId: row['created_by_persona_id'] as String,
    );
  }
}
