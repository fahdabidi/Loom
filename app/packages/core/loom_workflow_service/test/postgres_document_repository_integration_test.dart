import 'dart:io';

import 'package:loom_workflow_service/loom_workflow_service.dart';
import 'package:postgres/postgres.dart' as pg;
import 'package:test/test.dart';

void main() {
  final password = Platform.environment['LOOM_POSTGRES_PASSWORD'];

  test(
    'real PostgreSQL lists all document acknowledgements and current version only',
    () async {
      final host = Platform.environment['LOOM_POSTGRES_HOST'] ?? '127.0.0.1';
      final port = int.parse(
        Platform.environment['LOOM_POSTGRES_PORT'] ?? '15432',
      );
      final database =
          Platform.environment['LOOM_POSTGRES_DATABASE'] ?? 'loom_app_access';
      final username = Platform.environment['LOOM_POSTGRES_USERNAME'] ?? 'loom';
      final schema =
          'document_repository_test_${DateTime.now().microsecondsSinceEpoch}_$pid';
      final connection = await pg.Connection.open(
        pg.Endpoint(
          host: host,
          port: port,
          database: database,
          username: username,
          password: password,
        ),
        settings: const pg.ConnectionSettings(sslMode: pg.SslMode.disable),
      );

      var schemaCreated = false;
      try {
        await connection.execute('CREATE SCHEMA $schema');
        schemaCreated = true;
        await connection.execute('SET search_path TO $schema');

        final repository = PostgresDocumentRepository(connection);
        await repository.migrate();
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
        if (schemaCreated) {
          await connection.execute('DROP SCHEMA $schema CASCADE');
        }
        await connection.close();
      }
    },
    skip: password == null || password.isEmpty
        ? 'Set LOOM_POSTGRES_PASSWORD to run against the k3s PostgreSQL '
              'port-forward.'
        : false,
  );
}
