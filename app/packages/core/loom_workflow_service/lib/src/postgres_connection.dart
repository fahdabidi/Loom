import 'package:drift_postgres/drift_postgres.dart';
import 'package:loom_workflow_engine/loom_workflow_engine.dart';
import 'package:postgres/postgres.dart' as pg;

/// Owns the PostgreSQL connection and the shared engine database wrapper.
class WorkflowPostgresConnection {
  final pg.Connection _connection;
  final WorkflowDatabase database;

  WorkflowPostgresConnection._(this._connection, this.database);

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

  Future<void> close() async {
    database.close();
    await _connection.close();
  }
}
