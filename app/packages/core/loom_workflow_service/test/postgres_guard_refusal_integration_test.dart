import 'dart:convert';
import 'dart:io';

import 'package:drift_postgres/drift_postgres.dart';
import 'package:loom_workflow_engine/loom_workflow_engine.dart';
import 'package:loom_workflow_service/loom_workflow_service.dart';
import 'package:postgres/postgres.dart' as pg;
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

const _communityId = 'service-postgres-integration';
const _workflowType = 'server-guard-proof';
const _instanceId = 'guarded-instance';
const _editableWorkflowType = 'server-field-edit-proof';
const _editableInstanceId = 'editable-postgres-instance';
const _aggregateWorkflowType = 'server-aggregate-proof';
const _correlationId = '22222222-2222-4222-8222-222222222222';
const _definitionJson = '''
{
  "initialState": "draft",
  "states": {
    "draft": {"label": "Draft"},
    "approved": {"label": "Approved", "tone": "positive"}
  },
  "transitions": [
    {
      "id": "approve",
      "label": "Approve",
      "from": ["draft"],
      "to": "approved",
      "guard": {"actorEqualsField": {"key": "ownerFanId"}},
      "effects": [
        {"op": "set", "key": "decision", "value": "approved"}
      ]
    }
  ],
  "instanceDataSchema": {
    "ownerFanId": {
      "type": "text",
      "required": true,
      "writableBy": "formEntry",
      "storage": "inline"
    },
    "decision": {
      "type": "text",
      "writableBy": "effect",
      "storage": "inline"
    }
  }
}
''';
const _editableDefinitionJson = '''
{
  "initialState": "draft",
  "states": {
    "draft": {
      "label": "Draft",
      "editableFields": ["title"],
      "editGuard": {"allowedRoleIds": ["fan-editor"]}
    }
  },
  "transitions": [],
  "instanceDataSchema": {
    "title": {
      "type": "text",
      "writableBy": "formEntry",
      "storage": "inline"
    }
  }
}
''';

void main() {
  final password = Platform.environment['LOOM_POSTGRES_PASSWORD'];

  test(
    'a client-allowed transition is genuinely refused by the service guard',
    () async {
      final host = Platform.environment['LOOM_POSTGRES_HOST'] ?? '127.0.0.1';
      final port = int.parse(
        Platform.environment['LOOM_POSTGRES_PORT'] ?? '15432',
      );
      final databaseName =
          Platform.environment['LOOM_POSTGRES_DATABASE'] ?? 'loom_app_access';
      final username = Platform.environment['LOOM_POSTGRES_USERNAME'] ?? 'loom';
      final schema =
          'workflow_service_test_${DateTime.now().microsecondsSinceEpoch}_$pid';

      final connection = await pg.Connection.open(
        pg.Endpoint(
          host: host,
          port: port,
          database: databaseName,
          username: username,
          password: password,
        ),
        settings: const pg.ConnectionSettings(sslMode: pg.SslMode.disable),
      );

      WorkflowDatabase? serverDatabase;
      WorkflowDatabase? clientDatabase;
      var schemaCreated = false;
      try {
        await connection.execute('CREATE SCHEMA $schema');
        schemaCreated = true;
        await connection.execute('SET search_path TO $schema');

        serverDatabase = WorkflowDatabase.withExecutor(
          PgDatabase.opened(connection, enableMigrations: false),
          dialect: WorkflowSqlDialect.postgres,
        );
        await _seed(serverDatabase);

        // This is the same engine the app client runs. With the locally active
        // owner identity, its guard evaluation allows and applies the action.
        clientDatabase = WorkflowDatabase.memory();
        await _seed(clientDatabase);
        final clientEngine = LocalWorkflowEngineApi(
          db: clientDatabase,
          communityId: _communityId,
        );
        final clientResult = await clientEngine.applyTransition(
          workflowType: _workflowType,
          instanceId: _instanceId,
          transitionId: 'approve',
          fanId: 'fan-owner',
        );
        expect(clientResult.newState, 'approved');

        // The real service runs in-process over the real PostgreSQL executor.
        // A forged body identity cannot override the extracted header identity.
        final service = WorkflowService(
          database: serverDatabase,
          identityExtractor: const HeaderWorkflowIdentityExtractor(),
          appAccessClient: const _DenyAppAccessClient(),
          communityGroupIdResolver: MapCommunityGroupIdResolver({
            _communityId: 'loom_communities_service_postgres_integration',
          }),
        );
        final refused = await service.handler(
          _request(
            headerFanId: 'fan-attacker',
            bodyFanId: 'fan-owner',
            idempotencyKey: 'postgres-refusal',
          ),
        );
        expect(refused.statusCode, 403);
        final refusedBody = await refused.readAsString();
        final refusedJson = jsonDecode(refusedBody) as Map<String, dynamic>;
        expect(refusedJson['code'], 'workflow_guard_refused');
        expect(
          refusedJson['message'],
          'The requested transition is not allowed.',
        );
        expect(refusedBody, isNot(contains('ownerFanId')));
        expect(refusedBody, isNot(contains('fan-attacker')));
        expect(
          (await serverDatabase.readInstance(_instanceId))!.currentState,
          'draft',
        );

        // The same route succeeds for the server-extracted owner. This rules
        // out a blanket HTTP denial and proves the refusal came from evaluating
        // the stored actorEqualsField guard against the server identity.
        final accepted = await service.handler(
          _request(
            headerFanId: 'fan-owner',
            bodyFanId: 'fan-attacker',
            idempotencyKey: 'postgres-accepted',
          ),
        );
        expect(accepted.statusCode, 200);
        final acceptedJson =
            jsonDecode(await accepted.readAsString()) as Map<String, dynamic>;
        expect(acceptedJson['currentState'], 'approved');
        expect(
          acceptedJson['instanceData'] as Map<String, dynamic>,
          containsPair('decision', 'approved'),
        );
        expect(
          (await serverDatabase.readInstance(_instanceId))!.currentState,
          'approved',
        );
      } finally {
        clientDatabase?.close();
        serverDatabase?.close();
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
    'Phase B.2 definition replacement and authoritative reads use PostgreSQL',
    () async {
      final host = Platform.environment['LOOM_POSTGRES_HOST'] ?? '127.0.0.1';
      final port = int.parse(
        Platform.environment['LOOM_POSTGRES_PORT'] ?? '15432',
      );
      final databaseName =
          Platform.environment['LOOM_POSTGRES_DATABASE'] ?? 'loom_app_access';
      final username = Platform.environment['LOOM_POSTGRES_USERNAME'] ?? 'loom';
      final schema =
          'workflow_service_b2_test_'
          '${DateTime.now().microsecondsSinceEpoch}_$pid';

      final connection = await pg.Connection.open(
        pg.Endpoint(
          host: host,
          port: port,
          database: databaseName,
          username: username,
          password: password,
        ),
        settings: const pg.ConnectionSettings(sslMode: pg.SslMode.disable),
      );

      WorkflowDatabase? database;
      var schemaCreated = false;
      try {
        await connection.execute('CREATE SCHEMA $schema');
        schemaCreated = true;
        await connection.execute('SET search_path TO $schema');
        database = WorkflowDatabase.withExecutor(
          PgDatabase.opened(connection, enableMigrations: false),
          dialect: WorkflowSqlDialect.postgres,
        );
        final service = WorkflowService(
          database: database,
          identityExtractor: const HeaderWorkflowIdentityExtractor(),
          appAccessClient: const _DenyAppAccessClient(),
          communityGroupIdResolver: MapCommunityGroupIdResolver({
            _communityId: 'loom_communities_service_postgres_integration',
          }),
        );

        final publicDefinition =
            jsonDecode(_definitionJson) as Map<String, dynamic>;
        final privateDefinition =
            jsonDecode(_definitionJson) as Map<String, dynamic>
              ..['visibility'] = {
                'default': 'guarded',
                'readGuard': {
                  'actorEqualsField': {'key': 'ownerFanId'},
                },
              };
        final firstReplace = await service.handler(
          _replaceRequest(
            definitions: {
              _workflowType: publicDefinition,
              'private-read': privateDefinition,
              'retired-type': publicDefinition,
            },
            idempotencyKey: 'postgres-b2-first',
          ),
        );
        expect(firstReplace.statusCode, 200);

        final secondReplace = await service.handler(
          _replaceRequest(
            definitions: {
              _workflowType: publicDefinition,
              'private-read': privateDefinition,
            },
            idempotencyKey: 'postgres-b2-second',
          ),
        );
        expect(secondReplace.statusCode, 200);
        expect(
          jsonDecode(await secondReplace.readAsString()),
          containsPair('removedWorkflowTypes', ['retired-type']),
        );
        expect(
          await database.loadDefinitionJson('${_communityId}_retired-type'),
          isNull,
        );

        await database.insertInstance(
          instanceId: _instanceId,
          communityId: _communityId,
          workflowType: _workflowType,
          currentState: 'draft',
          instanceData: {'ownerFanId': 'fan-owner', 'title': 'Action'},
          createdByFanId: 'fan-owner',
        );
        await database.insertInstance(
          instanceId: 'postgres-visible',
          communityId: _communityId,
          workflowType: 'private-read',
          currentState: 'draft',
          instanceData: {'ownerFanId': 'fan-owner', 'title': 'Visible'},
          createdByFanId: 'fan-owner',
        );
        await database.insertInstance(
          instanceId: 'postgres-hidden',
          communityId: _communityId,
          workflowType: 'private-read',
          currentState: 'draft',
          instanceData: {'ownerFanId': 'fan-other', 'title': 'Must not leak'},
          createdByFanId: 'fan-other',
        );

        final queryResponse = await service.handler(
          _getRequest(
            '/v1/communities/$_communityId/instances'
                '?workflowType=private-read&sortKey=title',
            'fan-owner',
          ),
        );
        expect(queryResponse.statusCode, 200);
        final queryBody = await queryResponse.readAsString();
        expect(queryBody, contains('postgres-visible'));
        expect(queryBody, isNot(contains('postgres-hidden')));
        expect(queryBody, isNot(contains('Must not leak')));

        final attackerTransitions = await service.handler(
          _getRequest(
            '/v1/communities/$_communityId/instances/$_instanceId/'
                'available-transitions',
            'fan-attacker',
          ),
        );
        expect(attackerTransitions.statusCode, 200);
        expect(
          jsonDecode(await attackerTransitions.readAsString()),
          containsPair('transitions', isEmpty),
        );

        final ownerTransitions = await service.handler(
          _getRequest(
            '/v1/communities/$_communityId/instances/$_instanceId/'
                'available-transitions',
            'fan-owner',
          ),
        );
        expect(ownerTransitions.statusCode, 200);
        final ownerTransitionsBody =
            jsonDecode(await ownerTransitions.readAsString())
                as Map<String, dynamic>;
        final transitions =
            ownerTransitionsBody['transitions'] as List<dynamic>;
        expect(transitions, hasLength(1));
        expect(transitions.single, containsPair('transitionId', 'approve'));
      } finally {
        database?.close();
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
    'live PostgreSQL updateInstanceFields persists and is readable afterward',
    () async {
      final host = Platform.environment['LOOM_POSTGRES_HOST'] ?? '127.0.0.1';
      final port = int.parse(
        Platform.environment['LOOM_POSTGRES_PORT'] ?? '15432',
      );
      final databaseName =
          Platform.environment['LOOM_POSTGRES_DATABASE'] ?? 'loom_app_access';
      final username = Platform.environment['LOOM_POSTGRES_USERNAME'] ?? 'loom';
      final schema =
          'workflow_service_field_edit_test_'
          '${DateTime.now().microsecondsSinceEpoch}_$pid';

      final connection = await pg.Connection.open(
        pg.Endpoint(
          host: host,
          port: port,
          database: databaseName,
          username: username,
          password: password,
        ),
        settings: const pg.ConnectionSettings(sslMode: pg.SslMode.disable),
      );

      WorkflowDatabase? database;
      var schemaCreated = false;
      try {
        await connection.execute('CREATE SCHEMA $schema');
        schemaCreated = true;
        await connection.execute('SET search_path TO $schema');
        database = WorkflowDatabase.withExecutor(
          PgDatabase.opened(connection, enableMigrations: false),
          dialect: WorkflowSqlDialect.postgres,
        );
        await database.upsertDefinition(
          definitionId: '${_communityId}_$_editableWorkflowType',
          workflowType: _editableWorkflowType,
          definitionJson: _editableDefinitionJson,
          version: 4,
        );
        await database.insertInstance(
          instanceId: _editableInstanceId,
          communityId: _communityId,
          workflowType: _editableWorkflowType,
          currentState: 'draft',
          instanceData: {'title': 'Before'},
          createdByFanId: 'fan-editor',
        );

        final service = WorkflowService(
          database: database,
          identityExtractor: const HeaderWorkflowIdentityExtractor(),
          appAccessClient: const _DenyAppAccessClient(),
          communityGroupIdResolver: MapCommunityGroupIdResolver({
            _communityId: 'loom_communities_service_postgres_integration',
          }),
        );
        final updateResponse = await service.handler(
          _fieldUpdateRequest(fieldUpdates: {'title': 'Persisted in Postgres'}),
        );
        expect(updateResponse.statusCode, 200);
        expect(
          (jsonDecode(await updateResponse.readAsString())
              as Map<String, dynamic>)['instanceData'],
          containsPair('title', 'Persisted in Postgres'),
        );

        final persisted = await database.readInstance(_editableInstanceId);
        expect(persisted, isNotNull);
        expect(
          jsonDecode(persisted!.instanceData),
          containsPair('title', 'Persisted in Postgres'),
        );

        final readResponse = await service.handler(
          _getRequest(
            '/v1/communities/$_communityId/instances'
                '?workflowType=$_editableWorkflowType',
            'fan-editor',
          ),
        );
        expect(readResponse.statusCode, 200);
        final readBody = await readResponse.readAsString();
        expect(readBody, contains(_editableInstanceId));
        expect(readBody, contains('Persisted in Postgres'));
      } finally {
        database?.close();
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
    'live PostgreSQL aggregate reflects persisted rows',
    () async {
      final host = Platform.environment['LOOM_POSTGRES_HOST'] ?? '127.0.0.1';
      final port = int.parse(
        Platform.environment['LOOM_POSTGRES_PORT'] ?? '15432',
      );
      final databaseName =
          Platform.environment['LOOM_POSTGRES_DATABASE'] ?? 'loom_app_access';
      final username = Platform.environment['LOOM_POSTGRES_USERNAME'] ?? 'loom';
      final schema =
          'workflow_service_aggregate_test_'
          '${DateTime.now().microsecondsSinceEpoch}_$pid';

      final connection = await pg.Connection.open(
        pg.Endpoint(
          host: host,
          port: port,
          database: databaseName,
          username: username,
          password: password,
        ),
        settings: const pg.ConnectionSettings(sslMode: pg.SslMode.disable),
      );

      WorkflowDatabase? database;
      var schemaCreated = false;
      try {
        await connection.execute('CREATE SCHEMA $schema');
        schemaCreated = true;
        await connection.execute('SET search_path TO $schema');
        database = WorkflowDatabase.withExecutor(
          PgDatabase.opened(connection, enableMigrations: false),
          dialect: WorkflowSqlDialect.postgres,
        );
        await database.upsertDefinition(
          definitionId: '${_communityId}_$_aggregateWorkflowType',
          workflowType: _aggregateWorkflowType,
          definitionJson: _definitionJson,
          version: 4,
        );
        for (final (id, status, amount) in const [
          ('aggregate-postgres-first', 'posted', 4),
          ('aggregate-postgres-second', 'posted', 8),
          ('aggregate-postgres-excluded', 'draft', 50),
        ]) {
          await database.insertInstance(
            instanceId: id,
            communityId: _communityId,
            workflowType: _aggregateWorkflowType,
            currentState: 'draft',
            instanceData: {
              'ownerFanId': 'fan-aggregate-reader',
              'status': status,
              'amount': amount,
            },
            createdByFanId: 'fan-aggregate-reader',
          );
        }
        expect(
          jsonDecode(
            (await database.readInstance(
              'aggregate-postgres-second',
            ))!.instanceData,
          ),
          containsPair('amount', 8),
        );

        final service = WorkflowService(
          database: database,
          identityExtractor: const HeaderWorkflowIdentityExtractor(),
          appAccessClient: const _DenyAppAccessClient(),
          communityGroupIdResolver: MapCommunityGroupIdResolver({
            _communityId: 'loom_communities_service_postgres_integration',
          }),
        );
        final response = await service.handler(
          _aggregateRequest(
            workflowType: _aggregateWorkflowType,
            fanId: 'fan-aggregate-reader',
            column: 'amount',
            op: 'sum',
            filter: {'status': 'posted'},
          ),
        );

        expect(response.statusCode, 200);
        expect(
          jsonDecode(await response.readAsString()),
          containsPair('result', 12),
        );
      } finally {
        database?.close();
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

Future<void> _seed(WorkflowDatabase database) async {
  await database.upsertDefinition(
    definitionId: '${_communityId}_$_workflowType',
    workflowType: _workflowType,
    definitionJson: _definitionJson,
    version: 1,
  );
  await database.insertInstance(
    instanceId: _instanceId,
    communityId: _communityId,
    workflowType: _workflowType,
    currentState: 'draft',
    instanceData: {'ownerFanId': 'fan-owner'},
    createdByFanId: 'fan-owner',
  );
}

Request _request({
  required String headerFanId,
  required String bodyFanId,
  required String idempotencyKey,
}) => Request(
  'POST',
  Uri.parse(
    'http://localhost/v1/communities/$_communityId/instances/'
    '$_instanceId/transitions',
  ),
  headers: {
    'content-type': 'application/json',
    'x-loom-correlation-id': _correlationId,
    'idempotency-key': idempotencyKey,
    HeaderWorkflowIdentityExtractor.defaultHeaderName: headerFanId,
  },
  body: jsonEncode({'transitionId': 'approve', 'fanId': bodyFanId}),
);

Request _fieldUpdateRequest({required Map<String, dynamic> fieldUpdates}) =>
    Request(
      'PATCH',
      Uri.parse(
        'http://localhost/v1/communities/$_communityId/instances/'
        '$_editableInstanceId/fields',
      ),
      headers: {
        'content-type': 'application/json',
        'x-loom-correlation-id': _correlationId,
        'idempotency-key': 'postgres-field-edit',
        HeaderWorkflowIdentityExtractor.defaultHeaderName: 'fan-editor',
      },
      body: jsonEncode({'fieldUpdates': fieldUpdates}),
    );

Request _aggregateRequest({
  required String workflowType,
  required String fanId,
  required String column,
  required String op,
  Map<String, dynamic>? filter,
}) => Request(
  'POST',
  Uri.parse(
    'http://localhost/v1/communities/$_communityId/instances/aggregate',
  ),
  headers: {
    'content-type': 'application/json',
    'x-loom-correlation-id': _correlationId,
    HeaderWorkflowIdentityExtractor.defaultHeaderName: fanId,
  },
  body: jsonEncode({
    'workflowType': workflowType,
    'column': column,
    'op': op,
    if (filter != null) 'filter': filter,
  }),
);

Request _replaceRequest({
  required Map<String, Map<String, dynamic>> definitions,
  required String idempotencyKey,
}) => Request(
  'PUT',
  Uri.parse(
    'http://localhost/v1/communities/$_communityId/'
    'workflow-definitions',
  ),
  headers: {
    'content-type': 'application/json',
    'x-loom-correlation-id': _correlationId,
    'idempotency-key': idempotencyKey,
    HeaderWorkflowIdentityExtractor.defaultHeaderName: 'fan-installer',
  },
  body: jsonEncode({
    'specVersion': currentCommunitySpecVersion,
    'definitions': definitions,
  }),
);

Request _getRequest(String path, String fanId) => Request(
  'GET',
  Uri.parse('http://localhost$path'),
  headers: {
    'x-loom-correlation-id': _correlationId,
    HeaderWorkflowIdentityExtractor.defaultHeaderName: fanId,
  },
);

class _DenyAppAccessClient implements AppAccessDecisionClient {
  const _DenyAppAccessClient();

  @override
  Future<bool> checkAccess({
    required String fanId,
    required String appId,
    required String permissionId,
    required String groupId,
    required String correlationId,
  }) async => false;
}
