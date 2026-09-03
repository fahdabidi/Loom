import 'dart:io';

import 'package:loom_workflow_service/loom_workflow_service.dart';
import 'package:postgres/postgres.dart' as pg;
import 'package:test/test.dart';

void main() {
  final configuration = _PostgresConfiguration.fromEnvironment(
    Platform.environment,
  );

  test(
    'real PostgreSQL lists all document acknowledgements and current version only',
    () async {
      final schema =
          'document_repository_test_${DateTime.now().microsecondsSinceEpoch}_$pid';
      final administrator = await pg.Connection.open(
        pg.Endpoint(
          host: configuration!.host,
          port: configuration.port,
          database: configuration.databaseName,
          username: configuration.adminUsername,
          password: configuration.adminPassword,
        ),
        settings: const pg.ConnectionSettings(sslMode: pg.SslMode.disable),
      );
      pg.Connection? runtime;

      var schemaCreated = false;
      try {
        await administrator.execute('CREATE SCHEMA $schema');
        schemaCreated = true;
        await administrator.execute('SET search_path TO $schema');

        await PostgresDocumentRepository(administrator).migrate();
        await _grantRuntimeAccess(administrator, schema, configuration);
        runtime = await pg.Connection.open(
          pg.Endpoint(
            host: configuration.host,
            port: configuration.port,
            database: configuration.databaseName,
            username: configuration.appUsername,
            password: configuration.appPassword,
          ),
          settings: const pg.ConnectionSettings(sslMode: pg.SslMode.disable),
        );
        await runtime.execute('SET search_path TO $schema');
        expect(
          (await runtime.execute('SELECT current_user')).single.single,
          configuration.appUsername,
        );
        final repository = PostgresDocumentRepository(runtime);
        const communityId = 'document-repository-integration';
        const documentId = 'acknowledgement-history';
        await repository.recordAcknowledgement(
          communityId: communityId,
          acknowledgement: StoredDocumentAcknowledgement(
            documentId: documentId,
            fanId: 'fan-version-one',
            version: 1,
            acknowledgedAt: DateTime.utc(2026, 8, 30, 12),
          ),
        );
        await repository.recordAcknowledgement(
          communityId: communityId,
          acknowledgement: StoredDocumentAcknowledgement(
            documentId: documentId,
            fanId: 'fan-version-two-a',
            version: 2,
            acknowledgedAt: DateTime.utc(2026, 8, 30, 13),
          ),
        );
        await repository.recordAcknowledgement(
          communityId: communityId,
          acknowledgement: StoredDocumentAcknowledgement(
            documentId: documentId,
            fanId: 'fan-version-two-b',
            version: 2,
            acknowledgedAt: DateTime.utc(2026, 8, 30, 14),
          ),
        );

        final allAcknowledgements = await repository.listAcknowledgements(
          communityId: communityId,
          documentId: documentId,
          currentVersionOnly: false,
          currentVersion: 2,
        );
        expect(allAcknowledgements.map((item) => (item.fanId, item.version)), [
          ('fan-version-one', 1),
          ('fan-version-two-a', 2),
          ('fan-version-two-b', 2),
        ]);

        final currentAcknowledgements = await repository.listAcknowledgements(
          communityId: communityId,
          documentId: documentId,
          currentVersionOnly: true,
          currentVersion: 2,
        );
        expect(
          currentAcknowledgements.map((item) => (item.fanId, item.version)),
          [('fan-version-two-a', 2), ('fan-version-two-b', 2)],
        );
      } finally {
        await runtime?.close();
        if (schemaCreated) {
          await administrator.execute('DROP SCHEMA $schema CASCADE');
        }
        await administrator.close();
      }
    },
    skip: configuration == null
        ? 'Set LOOM_POSTGRES_PASSWORD and LOOM_POSTGRES_APP_USERNAME/'
              'LOOM_POSTGRES_APP_PASSWORD to run against the k3s PostgreSQL '
              'port-forward.'
        : false,
  );
}

class _PostgresConfiguration {
  const _PostgresConfiguration({
    required this.host,
    required this.port,
    required this.databaseName,
    required this.adminUsername,
    required this.adminPassword,
    required this.appUsername,
    required this.appPassword,
  });

  final String host;
  final int port;
  final String databaseName;
  final String adminUsername;
  final String adminPassword;
  final String appUsername;
  final String appPassword;

  static _PostgresConfiguration? fromEnvironment(
    Map<String, String> environment,
  ) {
    final adminPassword = environment['LOOM_POSTGRES_PASSWORD'];
    final appUsername = environment['LOOM_POSTGRES_APP_USERNAME'];
    final appPassword = environment['LOOM_POSTGRES_APP_PASSWORD'];
    if (adminPassword == null ||
        adminPassword.isEmpty ||
        appUsername == null ||
        appUsername.isEmpty ||
        appPassword == null ||
        appPassword.isEmpty) {
      return null;
    }
    return _PostgresConfiguration(
      host: environment['LOOM_POSTGRES_HOST'] ?? '127.0.0.1',
      port: int.parse(environment['LOOM_POSTGRES_PORT'] ?? '15432'),
      databaseName: workflowPostgresDatabaseName(environment),
      adminUsername: environment['LOOM_POSTGRES_USERNAME'] ?? 'loom',
      adminPassword: adminPassword,
      appUsername: appUsername,
      appPassword: appPassword,
    );
  }
}

Future<void> _grantRuntimeAccess(
  pg.Connection administrator,
  String schema,
  _PostgresConfiguration configuration,
) async {
  final role = _quoteIdentifier(configuration.appUsername);
  await administrator.execute('GRANT USAGE ON SCHEMA $schema TO $role');
  await administrator.execute(
    'GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA $schema '
    'TO $role',
  );
  await administrator.execute(
    'GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA $schema TO $role',
  );
}

String _quoteIdentifier(String value) => '"${value.replaceAll('"', '""')}"';
