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
/// did. SQL syntax and parameter placeholders branch only where the two
/// engines require different spellings.
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

  /// Opens the underlying database and completes all engine-owned migrations.
  ///
  /// Server startup calls this explicitly so readiness cannot report success
  /// before its workflow tables and compatibility migrations exist.
  Future<void> initialize() => _ensureOpenAndMigrated();

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
        created_at ${_dialect.isSqlite ? 'INTEGER' : 'BIGINT'} NOT NULL,
        updated_at ${_dialect.isSqlite ? 'INTEGER' : 'BIGINT'} NOT NULL,
        created_by_fan_id TEXT NOT NULL
      );
    ''');
    await _migrateWorkflowInstancesCreatorColumn();
    await _db.runCustom('''
      CREATE INDEX IF NOT EXISTS idx_instances_lookup
        ON workflow_instances (community_id, workflow_type, current_state);
    ''');
    // A file-backed workflow database can also be a server-fed, read-only
    // replica. There is exactly one replica owner per database file: callers
    // select a distinct file for each fan/community pair and this row makes a
    // mistaken reuse fail closed instead of exposing another fan's rows.
    await _db.runCustom('''
      CREATE TABLE IF NOT EXISTS workflow_replica_state (
        singleton INTEGER PRIMARY KEY CHECK (singleton = 1),
        fan_id TEXT NOT NULL,
        community_id TEXT NOT NULL,
        next_updated_since ${_dialect.isSqlite ? 'INTEGER' : 'BIGINT'},
        next_after_instance_id TEXT,
        next_role_cursor TEXT
      );
    ''');
  }

  /// Renames the one historical creator column to its current name.
  ///
  /// `CREATE TABLE IF NOT EXISTS` deliberately preserves a pre-existing table,
  /// so schema declaration alone cannot upgrade databases written before the
  /// creator id rename. Inspect the active database dialect's catalog rather
  /// than assuming the declaration represents the persisted shape.
  Future<void> _migrateWorkflowInstancesCreatorColumn() async {
    final columns = await _workflowInstancesColumns();
    const legacyColumn = 'created_by_persona_id';
    const currentColumn = 'created_by_fan_id';
    final hasLegacyColumn = columns.contains(legacyColumn);
    final hasCurrentColumn = columns.contains(currentColumn);

    if (hasLegacyColumn && hasCurrentColumn) {
      throw StateError(
        'workflow_instances has both created_by_persona_id and '
        'created_by_fan_id; refusing to choose between ambiguous creator '
        'columns.',
      );
    }
    if (hasLegacyColumn && !hasCurrentColumn) {
      await _db.runCustom(
        'ALTER TABLE workflow_instances '
        'RENAME COLUMN created_by_persona_id TO created_by_fan_id',
      );
    }
  }

  Future<Set<String>> _workflowInstancesColumns() async {
    final rows = await _db.runSelect(
      _dialect.isSqlite
          ? 'PRAGMA table_info(workflow_instances)'
          : r'''SELECT column_name
              FROM information_schema.columns
              WHERE table_schema = current_schema()
                AND table_name = $1''',
      _dialect.isSqlite ? const [] : const ['workflow_instances'],
    );
    return rows
        .map(
          (row) => (row[_dialect.isSqlite ? 'name' : 'column_name'] as String),
        )
        .toSet();
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
      _dialect.isSqlite
          ? 'INSERT OR REPLACE INTO workflow_definitions '
                '(definition_id, workflow_type, definition_json, version) '
                'VALUES (?, ?, ?, ?)'
          : r'INSERT INTO workflow_definitions '
                '(definition_id, workflow_type, definition_json, version) '
                r'VALUES ($1, $2, $3, $4) '
                'ON CONFLICT (definition_id) DO UPDATE SET '
                'workflow_type = EXCLUDED.workflow_type, '
                'definition_json = EXCLUDED.definition_json, '
                'version = EXCLUDED.version',
      [definitionId, workflowType, definitionJson, version],
    );
  }

  Future<String?> loadDefinitionJson(String definitionId) async {
    await _ensureOpenAndMigrated();
    final result = await _db.runSelect(
      _dialect.isSqlite
          ? 'SELECT definition_json FROM workflow_definitions '
                'WHERE definition_id = ?'
          : r'SELECT definition_json FROM workflow_definitions '
                r'WHERE definition_id = $1',
      [definitionId],
    );
    if (result.isEmpty) return null;
    return result.first['definition_json'] as String;
  }

  /// Loads every raw workflow definition owned by one canonical community.
  ///
  /// Archetype resolution is experience-wide because response-table workflows
  /// can inherit their archetype from another definition. Returning the raw
  /// maps preserves the render bindings needed for that resolution after a
  /// server restart, when the engine's in-memory definition cache is empty.
  Future<Map<String, Map<String, dynamic>>> loadDefinitionsForCommunity(
    String communityId,
  ) async {
    await _ensureOpenAndMigrated();
    final rows = await _db.runSelect(
      'SELECT definition_id, workflow_type, definition_json '
      'FROM workflow_definitions',
      const [],
    );
    final definitions = <String, Map<String, dynamic>>{};
    for (final row in rows) {
      final definitionId = row['definition_id'] as String;
      final workflowType = row['workflow_type'] as String;
      if (definitionId != '${communityId}_$workflowType') continue;
      final decoded = jsonDecode(row['definition_json'] as String);
      if (decoded is! Map<String, dynamic>) {
        throw StateError('Stored workflow definition is not a JSON object');
      }
      definitions[workflowType] = decoded;
    }
    return definitions;
  }

  /// Atomically replaces every definition owned by one community.
  ///
  /// Definition ids predate the server store's community-aware operations and
  /// are encoded as `communityId_workflowType`. Matching both the stored id and
  /// its stored workflow type avoids treating another community's shared id
  /// prefix as ownership.
  Future<Set<String>> replaceDefinitionsForCommunity({
    required String communityId,
    required Map<String, Map<String, dynamic>> definitions,
    required int version,
  }) async {
    final previousWorkflowTypes = <String>{};
    await transaction(() async {
      final rows = await _db.runSelect(
        'SELECT definition_id, workflow_type FROM workflow_definitions',
        const [],
      );
      for (final row in rows) {
        final definitionId = row['definition_id'] as String;
        final workflowType = row['workflow_type'] as String;
        if (definitionId != '${communityId}_$workflowType') continue;
        previousWorkflowTypes.add(workflowType);
        await _db.runCustom(
          _dialect.isSqlite
              ? 'DELETE FROM workflow_definitions WHERE definition_id = ?'
              : r'DELETE FROM workflow_definitions WHERE definition_id = $1',
          [definitionId],
        );
      }

      for (final entry in definitions.entries) {
        await upsertDefinition(
          definitionId: '${communityId}_${entry.key}',
          workflowType: entry.key,
          definitionJson: jsonEncode(entry.value),
          version: version,
        );
      }
    });
    return previousWorkflowTypes.difference(definitions.keys.toSet());
  }

  // ── Instances: mutations ───────────────────────────────────────────────

  Future<void> insertInstance({
    required String instanceId,
    required String communityId,
    required String workflowType,
    required String currentState,
    required Map<String, dynamic> instanceData,
    required String createdByFanId,
  }) async {
    await _ensureOpenAndMigrated();
    final now = DateTime.now().millisecondsSinceEpoch;
    await _db.runCustom(
      _dialect.isSqlite
          ? 'INSERT INTO workflow_instances '
                '(instance_id, community_id, workflow_type, current_state, '
                'instance_data, created_at, updated_at, created_by_fan_id) '
                'VALUES (?, ?, ?, ?, ?, ?, ?, ?)'
          : r'INSERT INTO workflow_instances '
                '(instance_id, community_id, workflow_type, current_state, '
                'instance_data, created_at, updated_at, created_by_fan_id) '
                r'VALUES ($1, $2, $3, $4, $5, $6, $7, $8)',
      [
        instanceId,
        communityId,
        workflowType,
        currentState,
        jsonEncode(instanceData),
        now,
        now,
        createdByFanId,
      ],
    );
  }

  Future<WorkflowInstanceRow?> readInstance(String instanceId) async {
    await _ensureOpenAndMigrated();
    final result = await _db.runSelect(
      _dialect.isSqlite
          ? 'SELECT * FROM workflow_instances WHERE instance_id = ?'
          : r'SELECT * FROM workflow_instances WHERE instance_id = $1',
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
      _dialect.isSqlite
          ? 'UPDATE workflow_instances '
                'SET current_state = ?, instance_data = ?, updated_at = ? '
                'WHERE instance_id = ?'
          : r'UPDATE workflow_instances '
                r'SET current_state = $1, instance_data = $2, updated_at = $3 '
                r'WHERE instance_id = $4',
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
    String? workflowType,
    String? cursor,
    required int limit,
    required String sortKey,
  }) async {
    await _ensureOpenAndMigrated();
    // JSON extraction is the one query shape the two dialects spell
    // differently. The sort key remains a bound parameter in both dialects;
    // it is never interpolated into SQL text. This query and its cursor logic
    // treat sortKey as one top-level instance_data key, so PostgreSQL uses
    // ->> (jsonb, text) rather than #>> (jsonb, text[]).
    final allRowsResult = _dialect.isSqlite
        ? await _db.runSelect(
            workflowType == null
                ? 'SELECT * FROM workflow_instances '
                      'WHERE community_id = ? '
                      'ORDER BY json_extract(instance_data, ?) ASC, '
                      'instance_id ASC'
                : 'SELECT * FROM workflow_instances '
                      'WHERE community_id = ? AND workflow_type = ? '
                      'ORDER BY json_extract(instance_data, ?) ASC, '
                      'instance_id ASC',
            [
              communityId,
              if (workflowType != null) workflowType,
              '\$.$sortKey',
            ],
          )
        : await _db.runSelect(
            workflowType == null
                ? 'SELECT * FROM workflow_instances '
                      r'WHERE community_id = $1 '
                      r'ORDER BY instance_data::jsonb ->> $2 ASC, '
                      'instance_id ASC'
                : 'SELECT * FROM workflow_instances '
                      r'WHERE community_id = $1 AND workflow_type = $2 '
                      r'ORDER BY instance_data::jsonb ->> $3 ASC, '
                      'instance_id ASC',
            [communityId, if (workflowType != null) workflowType, sortKey],
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
      _dialect.isSqlite
          ? 'SELECT COUNT(*) as c FROM workflow_instances '
                'WHERE community_id = ?'
          : r'SELECT COUNT(*) as c FROM workflow_instances '
                r'WHERE community_id = $1',
      [communityId],
    );
    return result.first['c'] as int;
  }

  /// Reads every persisted instance for one community in sync-feed order.
  ///
  /// The workflow service applies viewer-specific visibility after this read,
  /// through the engine's shared visibility resolver; storing a visibility
  /// decision in SQL would make it stale as soon as a caller's roles change.
  Future<List<WorkflowInstanceRow>> queryCommunityInstancesByUpdatedAt({
    required String communityId,
  }) async {
    await _ensureOpenAndMigrated();
    final result = await _db.runSelect(
      _dialect.isSqlite
          ? 'SELECT * FROM workflow_instances '
                'WHERE community_id = ? '
                'ORDER BY updated_at ASC, instance_id ASC'
          : r'SELECT * FROM workflow_instances '
                r'WHERE community_id = $1 '
                r'ORDER BY updated_at ASC, instance_id ASC',
      [communityId],
    );
    return result.map((row) => WorkflowInstanceRow.fromRow(row)).toList();
  }

  Future<List<WorkflowInstanceRow>> queryInstancesForFan({
    required String communityId,
    required String fanId,
  }) async {
    await _ensureOpenAndMigrated();
    final result = await _db.runSelect(
      _dialect.isSqlite
          ? 'SELECT * FROM workflow_instances '
                'WHERE community_id = ? AND created_by_fan_id = ? '
                'ORDER BY workflow_type ASC, instance_id ASC'
          : r'SELECT * FROM workflow_instances '
                r'WHERE community_id = $1 AND created_by_fan_id = $2 '
                'ORDER BY workflow_type ASC, instance_id ASC',
      [communityId, fanId],
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

  // ── Read-only replica state ───────────────────────────────────────────

  /// Claims this database file for the given viewer/community replica.
  ///
  /// A replica is deliberately not a multi-viewer cache. Visibility is
  /// resolved by the server for one fan, so reusing a file for another fan or
  /// community is refused before any rows can be read or written.
  Future<WorkflowReplicaCursor> claimReplica({
    required String fanId,
    required String communityId,
  }) async {
    _requireReplicaIdentity(fanId: fanId, communityId: communityId);
    await _ensureOpenAndMigrated();
    final existing = await _readReplicaCursorRow();
    if (existing != null) {
      _requireReplicaOwner(existing, fanId: fanId, communityId: communityId);
      return existing;
    }
    await _db.runCustom(
      _dialect.isSqlite
          ? 'INSERT INTO workflow_replica_state '
                '(singleton, fan_id, community_id) VALUES (?, ?, ?)'
          : r'INSERT INTO workflow_replica_state '
                r'(singleton, fan_id, community_id) VALUES ($1, $2, $3)',
      [1, fanId, communityId],
    );
    return WorkflowReplicaCursor(fanId: fanId, communityId: communityId);
  }

  /// Returns the persisted change-feed cursor after confirming ownership.
  Future<WorkflowReplicaCursor> readReplicaCursor({
    required String fanId,
    required String communityId,
  }) async {
    _requireReplicaIdentity(fanId: fanId, communityId: communityId);
    await _ensureOpenAndMigrated();
    final existing = await _readReplicaCursorRow();
    if (existing == null) {
      throw StateError(
        'This workflow database has not been claimed as an offline replica.',
      );
    }
    _requireReplicaOwner(existing, fanId: fanId, communityId: communityId);
    return existing;
  }

  /// Applies one server change-feed page and its next cursor atomically.
  ///
  /// [visibleInstanceIds] is authoritative. Rows absent from it are deleted
  /// even if they do not appear in [snapshots], because a visibility change
  /// need not update the instance itself.
  Future<void> replaceReplicaPage({
    required String fanId,
    required String communityId,
    required List<WorkflowInstanceRow> snapshots,
    required Set<String> visibleInstanceIds,
    required int nextUpdatedSince,
    required String nextAfterInstanceId,
    required String nextRoleCursor,
  }) async {
    _requireReplicaIdentity(fanId: fanId, communityId: communityId);
    if (snapshots.any((snapshot) => snapshot.communityId != communityId)) {
      throw ArgumentError.value(
        snapshots,
        'snapshots',
        'must all belong to the replica community',
      );
    }
    final snapshotIds = <String>{};
    for (final snapshot in snapshots) {
      if (snapshot.instanceId.isEmpty ||
          !snapshotIds.add(snapshot.instanceId)) {
        throw ArgumentError.value(
          snapshots,
          'snapshots',
          'must have non-empty, unique instance ids',
        );
      }
      if (!visibleInstanceIds.contains(snapshot.instanceId)) {
        throw ArgumentError.value(
          snapshots,
          'snapshots',
          'must be contained in visibleInstanceIds',
        );
      }
    }

    await _executeTx(() async {
      final state = await _readReplicaCursorRow();
      if (state == null) {
        throw StateError(
          'This workflow database has not been claimed as an offline replica.',
        );
      }
      _requireReplicaOwner(state, fanId: fanId, communityId: communityId);

      for (final snapshot in snapshots) {
        await _upsertReplicaSnapshot(snapshot);
      }

      final localRows = await queryCommunityInstancesByUpdatedAt(
        communityId: communityId,
      );
      for (final localRow in localRows) {
        if (visibleInstanceIds.contains(localRow.instanceId)) continue;
        await _db.runCustom(
          _dialect.isSqlite
              ? 'DELETE FROM workflow_instances WHERE instance_id = ?'
              : r'DELETE FROM workflow_instances WHERE instance_id = $1',
          [localRow.instanceId],
        );
      }

      await _db.runCustom(
        _dialect.isSqlite
            ? 'UPDATE workflow_replica_state SET next_updated_since = ?, '
                  'next_after_instance_id = ?, next_role_cursor = ? '
                  'WHERE singleton = ?'
            : r'UPDATE workflow_replica_state SET next_updated_since = $1, '
                  r'next_after_instance_id = $2, next_role_cursor = $3 '
                  r'WHERE singleton = $4',
        [nextUpdatedSince, nextAfterInstanceId, nextRoleCursor, 1],
      );
    });
  }

  /// Discards every replicated row and cursor while preserving its owner.
  ///
  /// This is used only when the server says a role change invalidated the
  /// cursor. It intentionally does not merge a newly visible page into old
  /// state: a role change can reveal rows that have never changed.
  Future<void> clearReplica({
    required String fanId,
    required String communityId,
  }) async {
    _requireReplicaIdentity(fanId: fanId, communityId: communityId);
    await _executeTx(() async {
      final state = await _readReplicaCursorRow();
      if (state == null) {
        throw StateError(
          'This workflow database has not been claimed as an offline replica.',
        );
      }
      _requireReplicaOwner(state, fanId: fanId, communityId: communityId);
      await _db.runCustom(
        _dialect.isSqlite
            ? 'DELETE FROM workflow_instances WHERE community_id = ?'
            : r'DELETE FROM workflow_instances WHERE community_id = $1',
        [communityId],
      );
      await _db.runCustom(
        _dialect.isSqlite
            ? 'UPDATE workflow_replica_state SET next_updated_since = NULL, '
                  'next_after_instance_id = NULL, next_role_cursor = NULL '
                  'WHERE singleton = ?'
            : r'UPDATE workflow_replica_state SET next_updated_since = NULL, '
                  r'next_after_instance_id = NULL, next_role_cursor = NULL '
                  r'WHERE singleton = $1',
        const [1],
      );
    });
  }

  Future<WorkflowReplicaCursor?> _readReplicaCursorRow() async {
    final rows = await _db.runSelect(
      'SELECT fan_id, community_id, next_updated_since, '
      'next_after_instance_id, next_role_cursor '
      'FROM workflow_replica_state WHERE singleton = ${_dialect.isSqlite ? '?' : r'$1'}',
      const [1],
    );
    if (rows.isEmpty) return null;
    final row = rows.single;
    final updatedSince = row['next_updated_since'];
    final afterInstanceId = row['next_after_instance_id'];
    final roleCursor = row['next_role_cursor'];
    if (row['fan_id'] is! String ||
        row['community_id'] is! String ||
        updatedSince != null && updatedSince is! int ||
        afterInstanceId != null && afterInstanceId is! String ||
        roleCursor != null && roleCursor is! String) {
      throw StateError('Offline replica state has an invalid stored shape.');
    }
    if ((updatedSince == null) != (afterInstanceId == null)) {
      throw StateError('Offline replica state has an incomplete cursor.');
    }
    return WorkflowReplicaCursor(
      fanId: row['fan_id']! as String,
      communityId: row['community_id']! as String,
      nextUpdatedSince: updatedSince as int?,
      nextAfterInstanceId: afterInstanceId as String?,
      nextRoleCursor: roleCursor as String?,
    );
  }

  Future<void> _upsertReplicaSnapshot(WorkflowInstanceRow snapshot) {
    final values = <Object?>[
      snapshot.instanceId,
      snapshot.communityId,
      snapshot.workflowType,
      snapshot.currentState,
      snapshot.instanceData,
      snapshot.createdAt,
      snapshot.updatedAt,
      snapshot.createdByFanId,
    ];
    return _db.runCustom(
      _dialect.isSqlite
          ? 'INSERT INTO workflow_instances '
                '(instance_id, community_id, workflow_type, current_state, '
                'instance_data, created_at, updated_at, created_by_fan_id) '
                'VALUES (?, ?, ?, ?, ?, ?, ?, ?) '
                'ON CONFLICT(instance_id) DO UPDATE SET '
                'community_id = excluded.community_id, '
                'workflow_type = excluded.workflow_type, '
                'current_state = excluded.current_state, '
                'instance_data = excluded.instance_data, '
                'created_at = excluded.created_at, '
                'updated_at = excluded.updated_at, '
                'created_by_fan_id = excluded.created_by_fan_id'
          : r'INSERT INTO workflow_instances '
                r'(instance_id, community_id, workflow_type, current_state, '
                r'instance_data, created_at, updated_at, created_by_fan_id) '
                r'VALUES ($1, $2, $3, $4, $5, $6, $7, $8) '
                r'ON CONFLICT(instance_id) DO UPDATE SET '
                r'community_id = EXCLUDED.community_id, '
                r'workflow_type = EXCLUDED.workflow_type, '
                r'current_state = EXCLUDED.current_state, '
                r'instance_data = EXCLUDED.instance_data, '
                r'created_at = EXCLUDED.created_at, '
                r'updated_at = EXCLUDED.updated_at, '
                r'created_by_fan_id = EXCLUDED.created_by_fan_id',
      values,
    );
  }

  void _requireReplicaIdentity({
    required String fanId,
    required String communityId,
  }) {
    if (fanId.trim().isEmpty) {
      throw ArgumentError.value(fanId, 'fanId', 'must not be empty');
    }
    if (communityId.trim().isEmpty) {
      throw ArgumentError.value(
        communityId,
        'communityId',
        'must not be empty',
      );
    }
  }

  void _requireReplicaOwner(
    WorkflowReplicaCursor state, {
    required String fanId,
    required String communityId,
  }) {
    if (state.fanId == fanId && state.communityId == communityId) return;
    throw StateError(
      'This offline replica belongs to a different member or community and '
      'cannot be opened here.',
    );
  }

  /// Runs [action] inside a single transaction (explicit BEGIN/COMMIT/ROLLBACK).
  Future<void> transaction(Future<void> Function() action) async {
    await _executeTx(action);
  }

  Future<void> _executeTx(Future<void> Function() action) async {
    await _ensureOpenAndMigrated();
    await _db.runCustom(_dialect.isSqlite ? 'BEGIN IMMEDIATE' : 'BEGIN');
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
  final String createdByFanId;

  const WorkflowInstanceRow({
    required this.instanceId,
    required this.communityId,
    required this.workflowType,
    required this.currentState,
    required this.instanceData,
    required this.createdAt,
    required this.updatedAt,
    required this.createdByFanId,
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
      createdByFanId: row['created_by_fan_id'] as String,
    );
  }
}

/// The durable, opaque position of one viewer's workflow change feed.
///
/// `nextUpdatedSince` and `nextAfterInstanceId` are a pair. `nextRoleCursor`
/// is opaque server state and must only be sent back to the service.
class WorkflowReplicaCursor {
  const WorkflowReplicaCursor({
    required this.fanId,
    required this.communityId,
    this.nextUpdatedSince,
    this.nextAfterInstanceId,
    this.nextRoleCursor,
  });

  final String fanId;
  final String communityId;
  final int? nextUpdatedSince;
  final String? nextAfterInstanceId;
  final String? nextRoleCursor;

  bool get isInitial => nextUpdatedSince == null;
}
