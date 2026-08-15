import 'dart:convert';

import 'package:loom_workflow_engine/loom_workflow_engine.dart';
import 'package:loom_workflow_service/loom_workflow_service.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

const _communityId = 'service-unit';
const _workflowType = 'owner-approval';
const _instanceId = 'instance-unit';
const _correlationId = '11111111-1111-4111-8111-111111111111';
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
  late WorkflowDatabase database;
  late WorkflowService service;

  setUp(() {
    database = WorkflowDatabase.memory();
    service = WorkflowService(
      database: database,
      identityExtractor: const HeaderWorkflowIdentityExtractor(),
    );
  });

  tearDown(() {
    database.close();
  });

  test(
    'the other four OpenAPI operations return explicit 501 responses',
    () async {
      final requests = <(String, String, String)>[
        (
          'PUT',
          '/v1/communities/community/workflow-definitions',
          'replaceWorkflowDefinitions',
        ),
        ('GET', '/v1/communities/community/instances', 'queryInstances'),
        ('POST', '/v1/communities/community/instances', 'createInstance'),
        (
          'GET',
          '/v1/communities/community/instances/instance/available-transitions',
          'availableTransitions',
        ),
      ];

      for (final (method, path, operationId) in requests) {
        final response = await service.handler(
          Request(method, Uri.parse('http://localhost$path')),
        );
        expect(response.statusCode, 501, reason: operationId);
        final body = await response.readAsString();
        expect(body, contains(operationId));
        expect(body, contains('not implemented'));
      }
    },
  );

  test(
    'applyTransition requires identity from the extractor boundary',
    () async {
      final response = await service.handler(
        _transitionRequest(body: {'transitionId': 'approve'}),
      );

      expect(response.statusCode, 401);
      expect(
        jsonDecode(await response.readAsString()),
        containsPair('code', 'authentication_required'),
      );
    },
  );

  test('applyTransition validates required OpenAPI headers and JSON', () async {
    final invalidCorrelation = await service.handler(
      _transitionRequest(
        fanId: 'fan-owner',
        correlationId: 'not-a-uuid',
        body: {'transitionId': 'approve'},
      ),
    );
    expect(invalidCorrelation.statusCode, 400);
    expect(
      jsonDecode(await invalidCorrelation.readAsString()),
      containsPair('code', 'invalid_correlation_id'),
    );

    final invalidBody = await service.handler(
      _transitionRequest(
        fanId: 'fan-owner',
        body: {'inputs': <String, dynamic>{}},
      ),
    );
    expect(invalidBody.statusCode, 400);
    expect(
      jsonDecode(await invalidBody.readAsString()),
      containsPair('code', 'invalid_request'),
    );
  });

  test(
    'applyTransition ignores a body identity and evaluates the header fan',
    () async {
      await _seed(database);

      final refused = await service.handler(
        _transitionRequest(
          fanId: 'fan-attacker',
          body: {'transitionId': 'approve', 'fanId': 'fan-owner'},
        ),
      );
      expect(refused.statusCode, 403);
      final refusedJson =
          jsonDecode(await refused.readAsString()) as Map<String, dynamic>;
      expect(refusedJson['code'], 'workflow_guard_refused');
      expect(
        refusedJson['message'],
        'The requested transition is not allowed.',
      );
      expect((await database.readInstance(_instanceId))!.currentState, 'draft');

      final accepted = await service.handler(
        _transitionRequest(
          fanId: 'fan-owner',
          body: {'transitionId': 'approve', 'fanId': 'fan-attacker'},
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

      final stale = await service.handler(
        _transitionRequest(
          fanId: 'fan-owner',
          idempotencyKey: 'unit-stale-state',
          body: {'transitionId': 'approve'},
        ),
      );
      expect(stale.statusCode, 409);
      expect(
        jsonDecode(await stale.readAsString()),
        containsPair('code', 'workflow_state_conflict'),
      );
    },
  );

  test(
    'an instance belonging to another community is returned as absent',
    () async {
      await _seed(database);

      final response = await service.handler(
        Request(
          'POST',
          Uri.parse(
            'http://localhost/v1/communities/other/instances/'
            '$_instanceId/transitions',
          ),
          headers: _headers('fan-owner'),
          body: jsonEncode({'transitionId': 'approve'}),
        ),
      );

      expect(response.statusCode, 404);
      expect((await database.readInstance(_instanceId))!.currentState, 'draft');
    },
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

Request _transitionRequest({
  String? fanId,
  String correlationId = _correlationId,
  String idempotencyKey = 'unit-test-key',
  required Map<String, dynamic> body,
}) => Request(
  'POST',
  Uri.parse(
    'http://localhost/v1/communities/$_communityId/instances/'
    '$_instanceId/transitions',
  ),
  headers: {
    ..._headers(fanId),
    'x-loom-correlation-id': correlationId,
    'idempotency-key': idempotencyKey,
  },
  body: jsonEncode(body),
);

Map<String, String> _headers(String? fanId) => {
  'content-type': 'application/json',
  'x-loom-correlation-id': _correlationId,
  'idempotency-key': 'unit-test-key',
  if (fanId != null) HeaderWorkflowIdentityExtractor.defaultHeaderName: fanId,
};
