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

  test('createInstance remains an explicit 501 response', () async {
    final response = await service.handler(
      Request(
        'POST',
        Uri.parse('http://localhost/v1/communities/community/instances'),
      ),
    );
    expect(response.statusCode, 501);
    final body = await response.readAsString();
    expect(body, contains('createInstance'));
    expect(body, contains('not implemented'));
  });

  test(
    'replaceWorkflowDefinitions replaces wholesale and reports removals',
    () async {
      final first = await service.handler(
        _replaceDefinitionsRequest({
          _workflowType: _definitionMap(),
          'retired': _definitionMap(),
        }, idempotencyKey: 'replace-first'),
      );
      expect(first.statusCode, 200);
      expect(
        jsonDecode(await first.readAsString()),
        containsPair('workflowTypes', [_workflowType, 'retired']),
      );
      await database.insertInstance(
        instanceId: 'retired-instance',
        communityId: _communityId,
        workflowType: 'retired',
        currentState: 'draft',
        instanceData: {'ownerFanId': 'fan-owner', 'title': 'Retired'},
        createdByPersonaId: 'fan-owner',
      );

      final second = await service.handler(
        _replaceDefinitionsRequest({
          _workflowType: _definitionMap(),
        }, idempotencyKey: 'replace-second'),
      );
      expect(second.statusCode, 200);
      final body = jsonDecode(await second.readAsString());
      expect(body, containsPair('removedWorkflowTypes', ['retired']));
      expect(
        await database.loadDefinitionJson('${_communityId}_retired'),
        isNull,
      );
      expect(
        await database.loadDefinitionJson('${_communityId}_$_workflowType'),
        isNotNull,
      );
      final query = await service.handler(
        _getRequest('/v1/communities/$_communityId/instances', 'fan-owner'),
      );
      final queryBody = await query.readAsString();
      expect(query.statusCode, 200);
      expect(queryBody, isNot(contains('retired-instance')));
    },
  );

  test(
    'replaceWorkflowDefinitions distinguishes malformed input from 422 findings',
    () async {
      final malformed = await service.handler(
        _replaceDefinitionsRequest(<String, dynamic>{}, specVersion: '4'),
      );
      expect(malformed.statusCode, 400);
      expect(
        jsonDecode(await malformed.readAsString()),
        containsPair('code', 'invalid_request'),
      );

      final unsupported = await service.handler(
        _replaceDefinitionsRequest(
          {
            'future-workflow': {'futureConstruct': true},
          },
          specVersion: 99,
          idempotencyKey: 'replace-version',
        ),
      );
      expect(unsupported.statusCode, 422);
      final unsupportedBody =
          jsonDecode(await unsupported.readAsString()) as Map<String, dynamic>;
      expect(
        (unsupportedBody['findings'] as List<dynamic>).single,
        containsPair('code', 'unsupported_spec_version'),
      );

      final invalidEffect = _definitionMap();
      (invalidEffect['transitions'] as List).add({
        'id': 'break-it',
        'label': 'Break it',
        'from': ['draft'],
        'to': 'approved',
        'effects': [
          {'op': 'silentlyIgnoreMe'},
        ],
      });
      final nonExecutable = await service.handler(
        _replaceDefinitionsRequest({
          _workflowType: invalidEffect,
        }, idempotencyKey: 'replace-invalid'),
      );
      expect(nonExecutable.statusCode, 422);
      final nonExecutableBody =
          jsonDecode(await nonExecutable.readAsString())
              as Map<String, dynamic>;
      expect(
        (nonExecutableBody['findings'] as List<dynamic>).single,
        containsPair('code', 'unknown_effect_op'),
      );
    },
  );

  test(
    'queryInstances omits an unreadable instance instead of redacting it',
    () async {
      final guarded = _definitionMap()
        ..['visibility'] = {
          'default': 'guarded',
          'readGuard': {
            'actorEqualsField': {'key': 'ownerFanId'},
          },
        };
      await database.upsertDefinition(
        definitionId: '${_communityId}_$_workflowType',
        workflowType: _workflowType,
        definitionJson: jsonEncode(guarded),
        version: 4,
      );
      await database.insertInstance(
        instanceId: 'visible-instance',
        communityId: _communityId,
        workflowType: _workflowType,
        currentState: 'draft',
        instanceData: {
          'ownerFanId': 'fan-owner',
          'title': 'Visible',
          'secret': 'visible-secret',
        },
        createdByPersonaId: 'fan-owner',
      );
      await database.insertInstance(
        instanceId: 'hidden-instance',
        communityId: _communityId,
        workflowType: _workflowType,
        currentState: 'draft',
        instanceData: {
          'ownerFanId': 'fan-other',
          'title': 'Hidden',
          'secret': 'must-not-leak',
        },
        createdByPersonaId: 'fan-other',
      );

      final response = await service.handler(
        _getRequest('/v1/communities/$_communityId/instances', 'fan-owner'),
      );
      expect(response.statusCode, 200);
      final encoded = await response.readAsString();
      final body = jsonDecode(encoded) as Map<String, dynamic>;
      final items = body['items'] as List<dynamic>;
      expect(items, hasLength(1));
      expect(items.single, containsPair('instanceId', 'visible-instance'));
      expect(encoded, isNot(contains('hidden-instance')));
      expect(encoded, isNot(contains('must-not-leak')));
    },
  );

  test(
    'queryInstances never treats the extracted fan id as a role claim',
    () async {
      final guarded = _definitionMap()
        ..['visibility'] = {
          'default': 'guarded',
          'readGuard': {
            'allowedRoleIds': ['board-role'],
          },
        };
      await database.upsertDefinition(
        definitionId: '${_communityId}_$_workflowType',
        workflowType: _workflowType,
        definitionJson: jsonEncode(guarded),
        version: 4,
      );
      await database.insertInstance(
        instanceId: 'role-guarded-instance',
        communityId: _communityId,
        workflowType: _workflowType,
        currentState: 'draft',
        instanceData: {'ownerFanId': 'fan-other', 'title': 'Board only'},
        createdByPersonaId: 'fan-other',
      );

      final response = await service.handler(
        _getRequest('/v1/communities/$_communityId/instances', 'board-role'),
      );
      expect(response.statusCode, 200);
      final body =
          jsonDecode(await response.readAsString()) as Map<String, dynamic>;
      expect(body['items'], isEmpty);
    },
  );

  test(
    'queryInstances passes workflow type, sort, and cursor pagination',
    () async {
      await database.upsertDefinition(
        definitionId: '${_communityId}_$_workflowType',
        workflowType: _workflowType,
        definitionJson: _definitionJson,
        version: 4,
      );
      await database.upsertDefinition(
        definitionId: '${_communityId}_other-type',
        workflowType: 'other-type',
        definitionJson: _definitionJson,
        version: 4,
      );
      for (final (id, type, title) in const [
        ('second', _workflowType, 'Bravo'),
        ('first', _workflowType, 'Alpha'),
        ('excluded', 'other-type', 'Aardvark'),
      ]) {
        await database.insertInstance(
          instanceId: id,
          communityId: _communityId,
          workflowType: type,
          currentState: 'draft',
          instanceData: {'ownerFanId': 'fan-owner', 'title': title},
          createdByPersonaId: 'fan-owner',
        );
      }

      final firstResponse = await service.handler(
        _getRequest(
          '/v1/communities/$_communityId/instances'
              '?workflowType=$_workflowType&sortKey=title&limit=1',
          'fan-owner',
        ),
      );
      expect(firstResponse.statusCode, 200);
      final firstBody =
          jsonDecode(await firstResponse.readAsString())
              as Map<String, dynamic>;
      expect(
        (firstBody['items'] as List).single,
        containsPair('instanceId', 'first'),
      );
      final pageInfo = firstBody['pageInfo'] as Map<String, dynamic>;
      expect(pageInfo['hasMore'], isTrue);

      final cursor = Uri.encodeQueryComponent(pageInfo['nextCursor'] as String);
      final secondResponse = await service.handler(
        _getRequest(
          '/v1/communities/$_communityId/instances'
              '?workflowType=$_workflowType&sortKey=title&limit=1&cursor=$cursor',
          'fan-owner',
        ),
      );
      final secondBody =
          jsonDecode(await secondResponse.readAsString())
              as Map<String, dynamic>;
      expect(
        (secondBody['items'] as List).single,
        containsPair('instanceId', 'second'),
      );
      expect(
        (secondBody['pageInfo'] as Map<String, dynamic>)['hasMore'],
        isFalse,
      );
    },
  );

  test(
    'availableTransitions omits a guarded action and returns it for the owner',
    () async {
      await _seed(database);

      final refused = await service.handler(
        _getRequest(
          '/v1/communities/$_communityId/instances/$_instanceId/'
              'available-transitions',
          'fan-attacker',
        ),
      );
      expect(refused.statusCode, 200);
      expect(
        jsonDecode(await refused.readAsString()),
        containsPair('transitions', isEmpty),
      );

      final accepted = await service.handler(
        _getRequest(
          '/v1/communities/$_communityId/instances/$_instanceId/'
              'available-transitions',
          'fan-owner',
        ),
      );
      expect(accepted.statusCode, 200);
      final acceptedBody =
          jsonDecode(await accepted.readAsString()) as Map<String, dynamic>;
      final transitions = acceptedBody['transitions'] as List<dynamic>;
      expect(transitions, hasLength(1));
      expect(transitions.single, containsPair('transitionId', 'approve'));
      expect(transitions.single, containsPair('label', 'Approve'));
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

Map<String, dynamic> _definitionMap() =>
    jsonDecode(_definitionJson) as Map<String, dynamic>;

Request _replaceDefinitionsRequest(
  Map<String, dynamic> definitions, {
  Object specVersion = 4,
  String idempotencyKey = 'replace-unit-key',
}) => Request(
  'PUT',
  Uri.parse(
    'http://localhost/v1/communities/$_communityId/'
    'workflow-definitions',
  ),
  headers: {..._headers('fan-installer'), 'idempotency-key': idempotencyKey},
  body: jsonEncode({'specVersion': specVersion, 'definitions': definitions}),
);

Request _getRequest(String path, String fanId) => Request(
  'GET',
  Uri.parse('http://localhost$path'),
  headers: {
    'x-loom-correlation-id': _correlationId,
    HeaderWorkflowIdentityExtractor.defaultHeaderName: fanId,
  },
);
