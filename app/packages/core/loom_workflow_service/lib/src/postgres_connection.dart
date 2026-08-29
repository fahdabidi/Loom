import 'package:drift_postgres/drift_postgres.dart';
import 'package:loom_workflow_engine/loom_workflow_engine.dart';
import 'package:postgres/postgres.dart' as pg;

const workflowPostgresDefaultDatabaseName = 'loom_workflow_service';

String workflowPostgresDatabaseName(Map<String, String> environment) =>
    environment['LOOM_POSTGRES_DATABASE'] ??
    workflowPostgresDefaultDatabaseName;

/// Owns the PostgreSQL connection and the shared engine database wrapper.
class WorkflowPostgresConnection {
  final pg.Connection _connection;
  final WorkflowDatabase database;

  WorkflowPostgresConnection._(this._connection, this.database);

  /// The raw connection, for tables the engine does not own.
  ///
  /// Document metadata lives beside the engine's tables in the same database so
  /// a document and the instance it belongs to cannot end up in two databases
  /// that disagree, but it is not the engine's schema and is not managed by it.
  pg.Connection get connection => _connection;

  static Future<WorkflowPostgresConnection> open({
    required String host,
    required int port,
    required String databaseName,
    required String username,
    required String password,
    pg.SslMode sslMode = pg.SslMode.disable,
  }) async {
    final connection = await pg.Connection.open(
      pg.Endpoint(
        host: host,
        port: port,
        database: databaseName,
        username: username,
        password: password,
      ),
      settings: pg.ConnectionSettings(sslMode: sslMode),
    );
    final workflowDatabase = WorkflowDatabase.withExecutor(
      PgDatabase.opened(connection, enableMigrations: false),
      dialect: WorkflowSqlDialect.postgres,
    );
    return WorkflowPostgresConnection._(connection, workflowDatabase);
  }

  /// Completes migrations owned by the shared workflow engine.
  Future<void> migrateWorkflowSchema() => database.initialize();

  Future<void> close() async {
    database.close();
    await _connection.close();
  }
}
