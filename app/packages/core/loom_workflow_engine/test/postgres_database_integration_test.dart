import 'dart:convert';
import 'dart:io';

import 'package:drift_postgres/drift_postgres.dart';
import 'package:loom_workflow_engine/loom_workflow_engine.dart';
import 'package:postgres/postgres.dart' as pg;
import 'package:test/test.dart';

const _definitionJson = '''
{
  "initialState": "draft",
  "states": {
    "draft": {"label": "Draft"},
    "published": {"label": "Published", "tone": "positive"}
  },
  "transitions": [
    {
      "id": "publish",
      "label": "Publish",
      "from": ["draft"],
      "to": "published",
      "guard": {"allowedPersonaIds": ["member"]},
      "effects": [
        {"op": "set", "key": "status", "value": "published"}
      ]
    }
  ],
  "renderBindings": [
    {
      "states": ["draft", "published"],
      "role": "any",
      "tabId": "postgres-test",
      "cardSurfaceFamily": "postgres-test-card",
      "bindingKind": "primary"
    }
  ],
  "instanceDataSchema": {
    "title": {
      "type": "text",
      "required": true,
      "writableBy": "formEntry",
      "storage": "inline",
      "sortable": true
    },
    "status": {
      "type": "text",
      "writableBy": "effect",
      "storage": "inline",
      "sortable": false
    }
  }
}
''';

void main() {
  final password = Platform.environment['LOOM_POSTGRES_PASSWORD'];

  test(
    'real PostgreSQL supports definition upsert, instance creation, and a '
    'transactional transition',
    () async {
      final host = Platform.environment['LOOM_POSTGRES_HOST'] ?? '127.0.0.1';
      final port = int.parse(
        Platform.environment['LOOM_POSTGRES_PORT'] ?? '15432',
      );
      final database =
          Platform.environment['LOOM_POSTGRES_DATABASE'] ?? 'loom_app_access';
      final username = Platform.environment['LOOM_POSTGRES_USERNAME'] ?? 'loom';
      final schema =
          'workflow_database_test_${DateTime.now().microsecondsSinceEpoch}_$pid';

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

      WorkflowDatabase? workflowDatabase;
      var schemaCreated = false;
      try {
        await connection.execute('CREATE SCHEMA $schema');
        schemaCreated = true;
        await connection.execute('SET search_path TO $schema');

        workflowDatabase = WorkflowDatabase.withExecutor(
          PgDatabase.opened(connection, enableMigrations: false),
          dialect: WorkflowSqlDialect.postgres,
        );
        const communityId = 'postgres-integration';
        const workflowType = 'postgres-write-probe';
        const definitionId = '${communityId}_$workflowType';

        // The second call must take PostgreSQL's ON CONFLICT update path. If it
        // does not replace the deliberately invalid first payload, the engine
        // cannot hydrate the definition for createInstance below.
        await workflowDatabase.upsertDefinition(
          definitionId: definitionId,
          workflowType: workflowType,
          definitionJson: '{}',
          version: 1,
        );
        await workflowDatabase.upsertDefinition(
          definitionId: definitionId,
          workflowType: workflowType,
          definitionJson: _definitionJson,
          version: 2,
        );
        expect(
          await workflowDatabase.loadDefinitionJson(definitionId),
          _definitionJson,
        );

        final api = LocalWorkflowEngineApi(
          db: workflowDatabase,
          communityId: communityId,
        );
        final instanceId = await api.createInstance(
          workflowType: workflowType,
          initialInstanceData: {'title': 'PostgreSQL write probe'},
          personaId: 'member',
        );

        final transition = await api.applyTransition(
          workflowType: workflowType,
          instanceId: instanceId,
          transitionId: 'publish',
          personaId: 'member',
        );
        expect(transition.newState, 'published');
        expect(transition.newInstanceData['status'], 'published');

        final stored = await workflowDatabase.readInstance(instanceId);
        expect(stored, isNotNull);
        expect(stored!.currentState, 'published');
        expect(
          jsonDecode(stored.instanceData),
          containsPair('status', 'published'),
        );
        expect(stored.createdAt, greaterThan(2147483647));
        expect(stored.updatedAt, greaterThan(2147483647));
      } finally {
        workflowDatabase?.close();
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

  test(
    'real PostgreSQL sorts queryInstancesKeyset by a bound top-level key '
    'with and without a workflow type filter',
    () async {
      final host = Platform.environment['LOOM_POSTGRES_HOST'] ?? '127.0.0.1';
      final port = int.parse(
        Platform.environment['LOOM_POSTGRES_PORT'] ?? '15432',
      );
      final database =
          Platform.environment['LOOM_POSTGRES_DATABASE'] ?? 'loom_app_access';
      final username = Platform.environment['LOOM_POSTGRES_USERNAME'] ?? 'loom';
      final schema =
          'workflow_database_test_${DateTime.now().microsecondsSinceEpoch}_$pid';

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

      WorkflowDatabase? workflowDatabase;
      var schemaCreated = false;
      try {
        await connection.execute('CREATE SCHEMA $schema');
        schemaCreated = true;
        await connection.execute('SET search_path TO $schema');

        workflowDatabase = WorkflowDatabase.withExecutor(
          PgDatabase.opened(connection, enableMigrations: false),
          dialect: WorkflowSqlDialect.postgres,
        );

        for (final instance in <({String id, String type, String title})>[
          (id: 'beta-zulu', type: 'beta', title: 'Zulu'),
          (id: 'alpha-middle', type: 'alpha', title: 'Middle'),
          (id: 'alpha-alpha', type: 'alpha', title: 'Alpha'),
          (id: 'beta-bravo', type: 'beta', title: 'Bravo'),
        ]) {
          await workflowDatabase.insertInstance(
            instanceId: instance.id,
            communityId: 'sorted-query-postgres',
            workflowType: instance.type,
            currentState: 'draft',
            instanceData: {'title': instance.title},
            createdByPersonaId: 'member',
          );
        }

        final allTypes = await workflowDatabase.queryInstancesKeyset(
          communityId: 'sorted-query-postgres',
          limit: 10,
          sortKey: 'title',
        );
        expect(allTypes.map((row) => row.instanceId), [
          'alpha-alpha',
          'beta-bravo',
          'alpha-middle',
          'beta-zulu',
        ]);

        final alphaOnly = await workflowDatabase.queryInstancesKeyset(
          communityId: 'sorted-query-postgres',
          workflowType: 'alpha',
          limit: 10,
          sortKey: 'title',
        );
        expect(alphaOnly.map((row) => row.instanceId), [
          'alpha-alpha',
          'alpha-middle',
        ]);
      } finally {
        workflowDatabase?.close();
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
