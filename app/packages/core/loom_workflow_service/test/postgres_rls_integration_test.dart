import 'dart:io';

import 'package:loom_workflow_service/loom_workflow_service.dart';
import 'package:postgres/postgres.dart' as pg;
import 'package:test/test.dart';

void main() {
  final configuration = _PostgresConfiguration.fromEnvironment(
    Platform.environment,
  );
  final skip = configuration == null
      ? 'Set LOOM_POSTGRES_PASSWORD and LOOM_POSTGRES_APP_USERNAME/'
            'LOOM_POSTGRES_APP_PASSWORD to run against the k3s PostgreSQL '
            'port-forward.'
      : false;

  test(
    'forced RLS isolates every community tenant table and permits its owner',
    () async {
      const communityA = 'rls-community-a';
      const communityB = 'rls-community-b';
      final schema = _uniqueIdentifier('workflow_rls_test');
      final administrator = await _openDirectConnection(configuration!);
      WorkflowPostgresConnection? migrationConnection;
      WorkflowPostgresConnection? postgres;
      var schemaCreated = false;

      try {
        await administrator.execute('CREATE SCHEMA $schema');
        schemaCreated = true;
        await administrator.execute('SET search_path TO $schema');
        migrationConnection = await _openAdminPool(configuration, schema);
        await migrationConnection.migrateWorkflowSchema();
        await PostgresDocumentRepository(
          migrationConnection.connection,
        ).migrate();
        await PostgresExportBundleRepository(
          migrationConnection.connection,
        ).migrate();
        await PostgresItemQueueRepository(
          migrationConnection.connection,
        ).migrate();
        await migrationConnection.close();
        migrationConnection = null;
        await _grantRuntimeAccess(administrator, schema, configuration);
        postgres = await _openPool(configuration, schema);
        expect(
          (await postgres.connection.execute(
            'SELECT current_user',
          )).single.single,
          configuration.appUsername,
        );
        expect(await _connectingRoleBypassesRls(postgres.connection), isFalse);

        await _expectForcedPolicies(administrator);
        await _seedTenantRows(postgres, communityA, 'a');
        await _seedTenantRows(postgres, communityB, 'b');

        // An unscoped session is the exact failure mode RLS is meant to stop.
        for (final tableName in workflowCommunityTenantTables) {
          final administratorRows = await administrator.execute(
            'SELECT community_id FROM $tableName',
          );
          expect(
            administratorRows,
            hasLength(2),
            reason: '$tableName setup did not create its expected 2 rows',
          );
          final rows = await postgres.connection.execute(
            'SELECT community_id FROM $tableName',
          );
          expect(
            rows,
            isEmpty,
            reason: '$tableName exposed ${rows.length}/2 rows without context',
          );
        }

        // The same rows are readable only under their owning context.
        await postgres.runWithCommunity(communityA, () async {
          for (final tableName in workflowCommunityTenantTables) {
            final rows = await postgres!.session.execute(
              pg.Sql.named(
                'SELECT community_id FROM $tableName '
                'WHERE community_id = @communityId',
              ),
              parameters: <String, Object?>{'communityId': communityA},
            );
            expect(
              rows.length,
              1,
              reason: '$tableName did not return its owner row',
            );
          }

          // This uses the shared engine through the request transaction, not
          // raw SQL, and proves ordinary per-community work still succeeds.
          await postgres!.database.insertInstance(
            instanceId: 'engine-context-instance',
            communityId: communityA,
            workflowType: 'rls-workflow',
            currentState: 'draft',
            instanceData: const <String, Object?>{'source': 'rls-test'},
            createdByFanId: 'fan-a',
          );
          expect(
            await postgres.database.readInstance('engine-context-instance'),
            isNotNull,
          );
        });

        await postgres.runWithCommunity(communityB, () async {
          for (final tableName in workflowCommunityTenantTables) {
            final rows = await postgres!.session.execute(
              pg.Sql.named(
                'SELECT community_id FROM $tableName '
                'WHERE community_id = @communityId',
              ),
              parameters: <String, Object?>{'communityId': communityA},
            );
            expect(rows, isEmpty, reason: '$tableName leaked to community B');
          }
          final update = await postgres!.session.execute(
            pg.Sql.named('''
              UPDATE workflow_instances
              SET current_state = 'cross-community-write'
              WHERE instance_id = @instanceId
            '''),
            parameters: const <String, Object?>{'instanceId': 'instance-a'},
          );
          expect(update.affectedRows, 0);
        });

        await postgres.runWithCommunity(communityA, () async {
          final rows = await postgres!.session.execute(
            pg.Sql.named('''
              SELECT current_state FROM workflow_instances
              WHERE instance_id = @instanceId
            '''),
            parameters: const <String, Object?>{'instanceId': 'instance-a'},
          );
          expect(rows.single.toColumnMap()['current_state'], 'draft');
        });
      } finally {
        await migrationConnection?.close();
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

Future<bool> _connectingRoleBypassesRls(pg.Session connection) async {
  final rows = await connection.execute('''
    SELECT rolsuper, rolbypassrls
    FROM pg_roles
    WHERE rolname = current_user
  ''');
  if (rows.length != 1) {
    throw StateError(
      'Could not resolve attributes for the connecting DB role.',
    );
  }
  final attributes = rows.single.toColumnMap();
  return attributes['rolsuper'] as bool || attributes['rolbypassrls'] as bool;
}

Future<void> _expectForcedPolicies(pg.Connection administrator) async {
  for (final tableName in workflowCommunityTenantTables) {
    final rows = await administrator.execute(
      pg.Sql.named('''
        SELECT class.relrowsecurity, class.relforcerowsecurity, policy.polname
        FROM pg_class AS class
        INNER JOIN pg_namespace AS namespace
          ON namespace.oid = class.relnamespace
        INNER JOIN pg_policy AS policy
          ON policy.polrelid = class.oid
        WHERE namespace.nspname = current_schema()
          AND class.relname = @tableName
          AND policy.polname = 'community_isolation'
      '''),
      parameters: <String, Object?>{'tableName': tableName},
    );
    expect(rows, hasLength(1), reason: '$tableName policy is missing');
    final values = rows.single.toColumnMap();
    expect(values['relrowsecurity'], isTrue);
    expect(values['relforcerowsecurity'], isTrue);
    expect(values['polname'], 'community_isolation');
  }
}

Future<void> _seedTenantRows(
  WorkflowPostgresConnection postgres,
  String communityId,
  String suffix,
) => postgres.runWithCommunity(communityId, () async {
  final session = postgres.session;
  await session.execute(
    pg.Sql.named('''
      INSERT INTO workflow_instances (
        instance_id, community_id, workflow_type, current_state, instance_data,
        created_at, updated_at, created_by_fan_id
      ) VALUES (
        @instanceId, @communityId, 'rls-workflow', 'draft', '{}', 1, 1, 'fan'
      )
    '''),
    parameters: <String, Object?>{
      'instanceId': 'instance-$suffix',
      'communityId': communityId,
    },
  );
  await session.execute(
    pg.Sql.named('''
      INSERT INTO workflow_documents (
        document_id, community_id, instance_id, workflow_type, field_name,
        title, filename, content_type, byte_size, owner_fan_id, object_key,
        uploaded_at
      ) VALUES (
        @documentId, @communityId, @instanceId, 'rls-workflow', 'attachment',
        'Title', 'document.txt', 'text/plain', 1, 'fan', @objectKey, 1
      )
    '''),
    parameters: <String, Object?>{
      'documentId': 'document-$suffix',
      'communityId': communityId,
      'instanceId': 'instance-$suffix',
      'objectKey': 'objects/$suffix',
    },
  );
  await session.execute(
    pg.Sql.named('''
      INSERT INTO workflow_document_acknowledgements (
        community_id, document_id, fan_id, version, acknowledged_at
      ) VALUES (@communityId, @documentId, 'fan', 1, 1)
    '''),
    parameters: <String, Object?>{
      'communityId': communityId,
      'documentId': 'document-$suffix',
    },
  );
  await session.execute(
    pg.Sql.named('''
      INSERT INTO workflow_document_member_states (
        community_id, document_id, fan_id, is_read, is_saved
      ) VALUES (@communityId, @documentId, 'fan', false, false)
    '''),
    parameters: <String, Object?>{
      'communityId': communityId,
      'documentId': 'document-$suffix',
    },
  );
  await session.execute(
    pg.Sql.named('''
      INSERT INTO workflow_document_revision_requests (
        community_id, document_id, idempotency_key, version
      ) VALUES (@communityId, @documentId, @idempotencyKey, 1)
    '''),
    parameters: <String, Object?>{
      'communityId': communityId,
      'documentId': 'document-$suffix',
      'idempotencyKey': 'revision-$suffix',
    },
  );
  await session.execute(
    pg.Sql.named('''
      INSERT INTO workflow_document_revisions (
        community_id, document_id, version, title, filename, content_type,
        byte_size, object_key, revised_at
      ) VALUES (
        @communityId, @documentId, 1, 'Title', 'document.txt', 'text/plain',
        1, @objectKey, 1
      )
    '''),
    parameters: <String, Object?>{
      'communityId': communityId,
      'documentId': 'document-$suffix',
      'objectKey': 'objects/$suffix',
    },
  );
  await session.execute(
    pg.Sql.named('''
      INSERT INTO workflow_export_bundles (
        export_id, community_id, instance_id, checksum, checksum_algorithm,
        byte_size, record_count, redacted, generated_at, object_key,
        idempotency_key
      ) VALUES (
        @exportId, @communityId, @instanceId, 'checksum', 'sha256', 1, 1,
        false, 1, @objectKey, @idempotencyKey
      )
    '''),
    parameters: <String, Object?>{
      'exportId': 'export-$suffix',
      'communityId': communityId,
      'instanceId': 'instance-$suffix',
      'objectKey': 'exports/$suffix',
      'idempotencyKey': 'export-$suffix',
    },
  );
  await session.execute(
    pg.Sql.named('''
      INSERT INTO workflow_item_queue_entries (
        community_id, instance_id, fan_id, joined_at
      ) VALUES (@communityId, @instanceId, 'fan', 1)
    '''),
    parameters: <String, Object?>{
      'communityId': communityId,
      'instanceId': 'instance-$suffix',
    },
  );
});

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

Future<WorkflowPostgresConnection> _openPool(
  _PostgresConfiguration configuration,
  String schema,
) => WorkflowPostgresConnection.open(
  host: configuration.host,
  port: configuration.port,
  databaseName: configuration.databaseName,
  username: configuration.appUsername,
  password: configuration.appPassword,
  onConnectionOpen: (connection) =>
      connection.execute('SET search_path TO $schema'),
  migrationsManagedExternally: true,
);

Future<WorkflowPostgresConnection> _openAdminPool(
  _PostgresConfiguration configuration,
  String schema,
) => WorkflowPostgresConnection.open(
  host: configuration.host,
  port: configuration.port,
  databaseName: configuration.databaseName,
  username: configuration.adminUsername,
  password: configuration.adminPassword,
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
    username: configuration.adminUsername,
    password: configuration.adminPassword,
  ),
  settings: const pg.ConnectionSettings(sslMode: pg.SslMode.disable),
);

String _uniqueIdentifier(String prefix) =>
    '${prefix}_${DateTime.now().microsecondsSinceEpoch}_$pid';

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
