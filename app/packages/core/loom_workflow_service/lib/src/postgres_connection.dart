import 'dart:async';

import 'package:drift_postgres/drift_postgres.dart';
import 'package:loom_workflow_engine/loom_workflow_engine.dart';
import 'package:postgres/postgres.dart' as pg;

const workflowPostgresDefaultDatabaseName = 'loom_workflow_service';

/// A small service-side ceiling keeps one pod from consuming every database
/// connection under a traffic burst.
const workflowPostgresPoolMaxConnectionCount = 8;

/// Bound both acquiring and opening a connection when PostgreSQL is down.
const workflowPostgresConnectTimeout = Duration(seconds: 5);

/// The service-owned tables whose rows are scoped to exactly one community.
///
/// Keep this list closed: identifiers cannot be bound parameters in DDL, so a
/// caller must never be able to choose a table name for an RLS migration.
const workflowCommunityTenantTables = <String>{
  'workflow_instances',
  'workflow_documents',
  'workflow_document_acknowledgements',
  'workflow_document_member_states',
  'workflow_document_revision_requests',
  'workflow_document_revisions',
  'workflow_export_bundles',
  'workflow_item_queue_entries',
};

final Object _postgresCommunityIdZoneKey = Object();
final Object _postgresCommunitySessionZoneKey = Object();

/// The community bound to the current PostgreSQL transaction, if any.
String? get currentPostgresCommunityId =>
    Zone.current[_postgresCommunityIdZoneKey] as String?;

/// The session bound to the current PostgreSQL community transaction, if any.
///
/// Repository implementations use this instead of their pooled fallback so
/// every statement in an HTTP request remains on the session that received
/// the transaction-local RLS setting.
pg.Session? get currentPostgresCommunitySession =>
    Zone.current[_postgresCommunitySessionZoneKey] as pg.Session?;

/// Runs [action] in one PostgreSQL transaction with its tenant setting set.
///
/// `set_config(..., true)` is PostgreSQL's parameterized equivalent of
/// `SET LOCAL`: its value lasts only for this transaction. Parameterizing the
/// value keeps a community id out of SQL text while ensuring a pool borrower
/// can never retain the previous request's context.
Future<T> runWithPostgresCommunity<T>({
  required pg.SessionExecutor executor,
  required String communityId,
  required Future<T> Function() action,
}) async {
  if (communityId.trim().isEmpty) {
    throw ArgumentError.value(communityId, 'communityId', 'must not be empty');
  }
  final activeSession = currentPostgresCommunitySession;
  if (activeSession != null) {
    final activeCommunityId = currentPostgresCommunityId;
    if (activeCommunityId != communityId) {
      throw StateError(
        'A PostgreSQL transaction for "$activeCommunityId" cannot perform '
        'work for "$communityId".',
      );
    }
    return action();
  }
  return executor.runTx((session) async {
    await session.execute(
      pg.Sql.named(
        "SELECT set_config('app.current_community_id', @communityId, true)",
      ),
      parameters: <String, Object?>{'communityId': communityId},
    );
    return runZoned<Future<T>>(
      action,
      zoneValues: <Object, Object?>{
        _postgresCommunityIdZoneKey: communityId,
        _postgresCommunitySessionZoneKey: session,
      },
    );
  });
}

/// Enables and forces the one policy every community-scoped table uses.
///
/// Recreating the dedicated policy is intentional. It makes this migration
/// both repeatable and corrective: a partially deployed or hand-altered policy
/// cannot leave a table enabled but using a weaker expression.
Future<void> migrateCommunityIsolationPolicy(
  pg.Session connection,
  String tableName,
) async {
  if (!workflowCommunityTenantTables.contains(tableName)) {
    throw ArgumentError.value(
      tableName,
      'tableName',
      'is not a known community tenant table',
    );
  }
  await connection.execute('ALTER TABLE $tableName ENABLE ROW LEVEL SECURITY');
  await connection.execute('ALTER TABLE $tableName FORCE ROW LEVEL SECURITY');
  await connection.execute(
    'DROP POLICY IF EXISTS community_isolation ON $tableName',
  );
  await connection.execute(
    "CREATE POLICY community_isolation ON $tableName "
    "USING (community_id = current_setting('app.current_community_id', true))",
  );
}

String workflowPostgresDatabaseName(Map<String, String> environment) =>
    environment['LOOM_POSTGRES_DATABASE'] ??
    workflowPostgresDefaultDatabaseName;

/// Owns the PostgreSQL pool and the shared engine database wrapper.
class WorkflowPostgresConnection {
  final pg.Pool<Object?> _connection;
  final WorkflowDatabase database;
  final bool _migrationsManagedExternally;

  WorkflowPostgresConnection._(
    this._connection,
    this.database, {
    required bool migrationsManagedExternally,
  }) : _migrationsManagedExternally = migrationsManagedExternally;

  /// The raw pooled session, for tables the engine does not own.
  ///
  /// Document metadata lives beside the engine's tables in the same database so
  /// a document and the instance it belongs to cannot end up in two databases
  /// that disagree, but it is not the engine's schema and is not managed by it.
  pg.Pool<Object?> get connection => _connection;

  /// The request-scoped session when one is active, otherwise the pool.
  ///
  /// New service storage should prefer a repository API. This getter exists
  /// for the few table migrations and tightly scoped raw SQL checks that need
  /// to share the RLS transaction with the engine.
  pg.Session get session => currentPostgresCommunitySession ?? _connection;

  static Future<WorkflowPostgresConnection> open({
    required String host,
    required int port,
    required String databaseName,
    required String username,
    required String password,
    pg.SslMode sslMode = pg.SslMode.disable,
    Future<void> Function(pg.Connection connection)? onConnectionOpen,
    bool migrationsManagedExternally = false,
  }) async {
    final connection = pg.Pool<Object?>.withEndpoints(
      [
        pg.Endpoint(
          host: host,
          port: port,
          database: databaseName,
          username: username,
          password: password,
        ),
      ],
      settings: pg.PoolSettings(
        maxConnectionCount: workflowPostgresPoolMaxConnectionCount,
        connectTimeout: workflowPostgresConnectTimeout,
        sslMode: sslMode,
        onOpen: onConnectionOpen,
      ),
    );
    final pgDatabase = PgDatabase.opened(connection, enableMigrations: false);
    final workflowDatabase = WorkflowDatabase.withExecutor(
      pgDatabase,
      dialect: WorkflowSqlDialect.postgres,
      migrationsManagedExternally: migrationsManagedExternally,
      transactionRunner: (action) async {
        await connection.runTx((transaction) async {
          final transactionDatabase = PgDatabase.opened(
            transaction,
            enableMigrations: false,
          );
          try {
            await action(transactionDatabase);
          } finally {
            await transactionDatabase.close();
          }
        });
      },
    );
    return WorkflowPostgresConnection._(
      connection,
      workflowDatabase,
      migrationsManagedExternally: migrationsManagedExternally,
    );
  }

  /// Completes migrations owned by the shared workflow engine.
  ///
  /// This is deliberately unavailable on a request-serving connection: schema
  /// work must finish on the separately opened administrator connection before
  /// the runtime pool is allowed to receive traffic.
  Future<void> migrateWorkflowSchema() async {
    if (_migrationsManagedExternally) {
      throw StateError(
        'Cannot run workflow schema migrations through the runtime pool. '
        'Use an administrator connection before opening it.',
      );
    }
    await database.initialize();
    await migrateCommunityIsolationPolicy(_connection, 'workflow_instances');
  }

  /// Runs one community request on a single transaction-bound connection.
  ///
  /// This is the server-side transaction runner for all tenant work: it sets
  /// `app.current_community_id` before binding Drift's executor, so engine and
  /// raw repository statements are subject to the same RLS policy.
  Future<T> runWithCommunity<T>(
    String communityId,
    Future<T> Function() action,
  ) {
    return runWithPostgresCommunity<T>(
      executor: _connection,
      communityId: communityId,
      action: () async {
        final activeSession = currentPostgresCommunitySession;
        if (activeSession == null) {
          throw StateError('Community transaction session was not installed.');
        }
        final transactionDatabase = PgDatabase.opened(
          activeSession,
          enableMigrations: false,
        );
        try {
          return await database.runWithTransactionExecutor(
            transactionDatabase,
            action,
          );
        } finally {
          await transactionDatabase.close();
        }
      },
    );
  }

  /// Throws when the database cannot accept a small, fresh query.
  ///
  /// A pool disposes a failed borrowed connection, so a later probe or request
  /// opens a replacement after PostgreSQL returns.
  Future<void> verifyReadiness() async {
    await _connection.execute('SELECT 1');
  }

  Future<void> close() async {
    database.close();
    await _connection.close();
  }
}
