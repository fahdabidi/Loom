import 'package:drift_postgres/drift_postgres.dart';
import 'package:loom_workflow_engine/loom_workflow_engine.dart';
import 'package:postgres/postgres.dart' as pg;

const workflowPostgresDefaultDatabaseName = 'loom_workflow_service';

/// A small service-side ceiling keeps one pod from consuming every database
/// connection under a traffic burst.
const workflowPostgresPoolMaxConnectionCount = 8;

/// Bound both acquiring and opening a connection when PostgreSQL is down.
const workflowPostgresConnectTimeout = Duration(seconds: 5);

String workflowPostgresDatabaseName(Map<String, String> environment) =>
    environment['LOOM_POSTGRES_DATABASE'] ??
    workflowPostgresDefaultDatabaseName;

/// Owns the PostgreSQL pool and the shared engine database wrapper.
class WorkflowPostgresConnection {
  final pg.Pool<Object?> _connection;
  final WorkflowDatabase database;

  WorkflowPostgresConnection._(this._connection, this.database);

  /// The raw pooled session, for tables the engine does not own.
  ///
  /// Document metadata lives beside the engine's tables in the same database so
  /// a document and the instance it belongs to cannot end up in two databases
  /// that disagree, but it is not the engine's schema and is not managed by it.
  pg.Pool<Object?> get connection => _connection;

  static Future<WorkflowPostgresConnection> open({
    required String host,
    required int port,
    required String databaseName,
    required String username,
    required String password,
    pg.SslMode sslMode = pg.SslMode.disable,
    Future<void> Function(pg.Connection connection)? onConnectionOpen,
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
    return WorkflowPostgresConnection._(connection, workflowDatabase);
  }

  /// Completes migrations owned by the shared workflow engine.
  Future<void> migrateWorkflowSchema() => database.initialize();

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
