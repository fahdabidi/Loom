import 'dart:io';

import 'package:loom_workflow_service/loom_workflow_service.dart';
import 'package:postgres/postgres.dart' as pg;
import 'package:test/test.dart';

void main() {
  final configuration = _PostgresConfiguration.fromEnvironment(
    Platform.environment,
  );
  final skip = configuration == null
      ? 'Set LOOM_POSTGRES_PASSWORD to run against the k3s PostgreSQL '
            'port-forward.'
      : false;

  test(
    'concurrent document, revision, and export writes replay the winning record',
    () async {
      final schema = _uniqueIdentifier('workflow_idempotency_race_test');
      final administrator = await _openDirectConnection(configuration!);
      WorkflowPostgresConnection? postgres;
      var schemaCreated = false;

      try {
        await administrator.execute('CREATE SCHEMA $schema');
        schemaCreated = true;
        await administrator.execute('SET search_path TO $schema');
        postgres = await _openPool(configuration, schema);
        final documentsA = PostgresDocumentRepository(postgres.connection);
        final documentsB = PostgresDocumentRepository(postgres.connection);
        final exportsA = PostgresExportBundleRepository(postgres.connection);
        final exportsB = PostgresExportBundleRepository(postgres.connection);
        await documentsA.migrate();
        await exportsA.migrate();

        const communityId = 'idempotency-race-community';
        final uploadedAt = DateTime.utc(2026, 9, 3, 12);
        final createWrites = await Future.wait([
          documentsA.insertIdempotently(
            _document(
              documentId: 'document-race-a',
              objectKey: 'objects/document-race-a',
              uploadedAt: uploadedAt,
            ),
            idempotencyKey: 'document-race-key',
          ),
          documentsB.insertIdempotently(
            _document(
              documentId: 'document-race-b',
              objectKey: 'objects/document-race-b',
              uploadedAt: uploadedAt,
            ),
            idempotencyKey: 'document-race-key',
          ),
        ]);
        _expectOneCreatedAndOneReplay(
          createWrites,
          (write) => write.record.documentId,
        );
        final createdDocumentId = createWrites.first.record.documentId;

        final revision =
            (await documentsA.findById(
              communityId: communityId,
              documentId: createdDocumentId,
            ))!.withRevision(
              version: 2,
              title: 'Revised race document',
              filename: 'race-v2.txt',
              contentType: 'text/plain',
              byteSize: 20,
              objectKey: 'objects/$createdDocumentId/revision-2',
              revisedAt: uploadedAt.add(const Duration(minutes: 1)),
              changeNote: 'Concurrent retry regression coverage',
            );
        final revisionWrites = await Future.wait([
          documentsA.addRevisionIdempotently(
            revision,
            idempotencyKey: 'revision-race-key',
          ),
          documentsB.addRevisionIdempotently(
            revision,
            idempotencyKey: 'revision-race-key',
          ),
        ]);
        _expectOneCreatedAndOneReplay(
          revisionWrites,
          (write) => '${write.record.documentId}/${write.record.version}',
        );

        final exportWrites = await Future.wait([
          exportsA.insertIdempotently(
            _export(
              exportId: 'export-race-a',
              objectKey: 'exports/export-race-a',
              generatedAt: uploadedAt,
            ),
            idempotencyKey: 'export-race-key',
          ),
          exportsB.insertIdempotently(
            _export(
              exportId: 'export-race-b',
              objectKey: 'exports/export-race-b',
              generatedAt: uploadedAt,
            ),
            idempotencyKey: 'export-race-key',
          ),
        ]);
        _expectOneCreatedAndOneReplay(
          exportWrites,
          (write) => write.record.exportId,
        );
      } finally {
        await postgres?.close();
        if (schemaCreated) {
          await administrator.execute('DROP SCHEMA $schema CASCADE');
        }
        await administrator.close();
      }
    },
    skip: skip,
  );
}

StoredDocument _document({
  required String documentId,
  required String objectKey,
  required DateTime uploadedAt,
}) => StoredDocument(
  documentId: documentId,
  communityId: 'idempotency-race-community',
  instanceId: 'idempotency-race-instance',
  workflowType: 'idempotency-race-workflow',
  fieldName: 'attachment',
  title: 'Race document',
  filename: 'race.txt',
  contentType: 'text/plain',
  byteSize: 10,
  ownerFanId: 'fan-race',
  objectKey: objectKey,
  uploadedAt: uploadedAt,
);

StoredExportBundle _export({
  required String exportId,
  required String objectKey,
  required DateTime generatedAt,
}) => StoredExportBundle(
  exportId: exportId,
  communityId: 'idempotency-race-community',
  instanceId: 'idempotency-race-instance',
  checksum: 'race-checksum',
  checksumAlgorithm: 'sha-256',
  byteSize: 10,
  recordCount: 1,
  redacted: false,
  generatedAt: generatedAt,
  objectKey: objectKey,
);

void _expectOneCreatedAndOneReplay<T>(
  List<IdempotentWrite<T>> writes,
  Object? Function(IdempotentWrite<T> write) recordIdentity,
) {
  expect(writes, hasLength(2));
  expect(writes.where((write) => write.created), hasLength(1));
  expect(writes.where((write) => !write.created), hasLength(1));
  expect(recordIdentity(writes.first), recordIdentity(writes.last));
}

class _PostgresConfiguration {
  const _PostgresConfiguration({
    required this.host,
    required this.port,
    required this.databaseName,
    required this.username,
    required this.password,
  });

  final String host;
  final int port;
  final String databaseName;
  final String username;
  final String password;

  static _PostgresConfiguration? fromEnvironment(
    Map<String, String> environment,
  ) {
    final password = environment['LOOM_POSTGRES_PASSWORD'];
    if (password == null || password.isEmpty) return null;
    return _PostgresConfiguration(
      host: environment['LOOM_POSTGRES_HOST'] ?? '127.0.0.1',
      port: int.parse(environment['LOOM_POSTGRES_PORT'] ?? '15432'),
      databaseName: workflowPostgresDatabaseName(environment),
      username: environment['LOOM_POSTGRES_USERNAME'] ?? 'loom',
      password: password,
    );
  }
}

Future<WorkflowPostgresConnection> _openPool(
  _PostgresConfiguration configuration,
  String schema,
) => WorkflowPostgresConnection.open(
  host: configuration.host,
  port: configuration.port,
  databaseName: configuration.databaseName,
  username: configuration.username,
  password: configuration.password,
  onConnectionOpen: (connection) =>
      connection.execute('SET search_path TO $schema'),
);

Future<pg.Connection> _openDirectConnection(
  _PostgresConfiguration configuration,
) => pg.Connection.open(
  pg.Endpoint(
    host: configuration.host,
    port: configuration.port,
    database: configuration.databaseName,
    username: configuration.username,
    password: configuration.password,
  ),
  settings: const pg.ConnectionSettings(sslMode: pg.SslMode.disable),
);

String _uniqueIdentifier(String prefix) =>
    '${prefix}_${DateTime.now().microsecondsSinceEpoch}_$pid';
