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
          personaId: 'fan-owner',
        );
        expect(clientResult.newState, 'approved');

        // The real service runs in-process over the real PostgreSQL executor.
        // A forged body identity cannot override the extracted header identity.
        final service = WorkflowService(
          database: serverDatabase,
          identityExtractor: const HeaderWorkflowIdentityExtractor(),
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
    createdByPersonaId: 'fan-owner',
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
