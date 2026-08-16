import 'dart:convert';

import 'package:loom_workflow_engine/loom_workflow_engine.dart';
import 'package:loom_workflow_service/loom_workflow_service.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

const _communityId = 'service-unit';
const _workflowType = 'owner-approval';
const _instanceId = 'instance-unit';
const _editableWorkflowType = 'editable-record';
const _editableInstanceId = 'editable-instance-unit';
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
  late _RecordingAppAccessClient appAccessClient;

  setUp(() {
    database = WorkflowDatabase.memory();
    appAccessClient = _RecordingAppAccessClient();
    service = WorkflowService(
      database: database,
      identityExtractor: const HeaderWorkflowIdentityExtractor(),
      appAccessClient: appAccessClient,
      communityGroupIdResolver: MapCommunityGroupIdResolver({
        _communityId: 'loom_communities_service_unit',
      }),
    );
  });

  tearDown(() {
    database.close();
  });

  test(
    'createInstance keeps declaredBespoke and generic origins creatable',
    () async {
      await _installCreatableDefinition(database);
      var definitions = await database.loadDefinitionsForCommunity(
        _communityId,
      );
      expect(
        const ArchetypeResolver()
            .resolveAll(definitions)[_workflowType]!
            .origin,
        ArchetypeOrigin.declaredBespoke,
      );
      final response = await service.handler(
        _createRequest(
          fanId: 'fan-creator',
          body: {
            'workflowType': _workflowType,
            'instanceData': {'ownerFanId': 'fan-creator'},
            'fanId': 'fan-forged',
          },
        ),
      );

      expect(response.statusCode, 201);
      final body =
          jsonDecode(await response.readAsString()) as Map<String, dynamic>;
      expect(body['workflowType'], _workflowType);
      expect(body['currentState'], 'draft');
      expect(body['instanceData'], {'ownerFanId': 'fan-creator'});
      expect(body['updatedAt'], isA<String>());
      final stored = await database.readInstance(body['instanceId'] as String);
      expect(stored, isNotNull);
      expect(stored!.createdByPersonaId, 'fan-creator');

      expect(appAccessClient.callCount, 1);
      expect(appAccessClient.fanId, 'fan-creator');
      expect(appAccessClient.appId, 'loom_communities');
      expect(appAccessClient.permissionId, 'event_rsvp.create');
      expect(appAccessClient.groupId, 'loom_communities_service_unit');

      const genericWorkflowType = 'generic-entry';
      await _installCreatableDefinition(
        database,
        workflowType: genericWorkflowType,
        family: 'formEntry',
      );
      definitions = await database.loadDefinitionsForCommunity(_communityId);
      expect(
        const ArchetypeResolver()
            .resolveAll(definitions)[genericWorkflowType]!
            .origin,
        ArchetypeOrigin.generic,
      );

      final genericResponse = await service.handler(
        _createRequest(
          fanId: 'fan-generic-creator',
          body: {
            'workflowType': genericWorkflowType,
            'instanceData': {'ownerFanId': 'fan-generic-creator'},
          },
        ),
      );

      expect(genericResponse.statusCode, 201);
      final genericBody =
          jsonDecode(await genericResponse.readAsString())
              as Map<String, dynamic>;
      expect(genericBody['workflowType'], genericWorkflowType);
      expect(appAccessClient.callCount, 2);
      expect(appAccessClient.permissionId, 'form_entry.create');
    },
  );

  test(
    'createInstance refuses a response-table-owned type before App Access',
    () async {
      const responseWorkflowType = 'event-response';
      await _installResponseTableDefinitionPair(
        database,
        responseWorkflowType: responseWorkflowType,
      );
      final definitions = await database.loadDefinitionsForCommunity(
        _communityId,
      );
      final resolved = const ArchetypeResolver().resolveAll(definitions);
      expect(
        resolved[responseWorkflowType]!.origin,
        ArchetypeOrigin.inheritedFromResponseTable,
      );
      expect(resolved[responseWorkflowType]!.family, 'event-rsvp');
      expect(
        const ArchetypeResolver().permissionId(
          resolved[responseWorkflowType]!.family!,
          'create',
        ),
        'event_rsvp.create',
      );
      appAccessClient.allowed = true;

      final response = await service.handler(
        _createRequest(
          fanId: 'fan-event-organizer',
          body: {
            'workflowType': responseWorkflowType,
            'instanceData': {
              'eventId': 'fabricated-event',
              'personaId': 'fan-victim',
            },
          },
        ),
      );

      expect(response.statusCode, 403);
      expect(
        jsonDecode(await response.readAsString()),
        containsPair('code', 'workflow_create_refused'),
      );
      expect(appAccessClient.callCount, 0);
    },
  );

  test(
    'createInstance denies without leaking permission or role details',
    () async {
      await _installCreatableDefinition(database);
      appAccessClient.allowed = false;

      final response = await service.handler(
        _createRequest(
          fanId: 'fan-denied',
          body: {
            'workflowType': _workflowType,
            'instanceData': {'ownerFanId': 'fan-denied'},
          },
        ),
      );

      expect(response.statusCode, 403);
      final encoded = await response.readAsString();
      expect(
        jsonDecode(encoded),
        containsPair('code', 'workflow_create_refused'),
      );
      expect(encoded, isNot(contains('event_rsvp.create')));
      expect(encoded, isNot(contains('grantingRoleIds')));
      expect(encoded, isNot(contains('role')));
      final page = await LocalWorkflowEngineApi(
        db: database,
        communityId: _communityId,
      ).queryInstances(tabId: 'home', personaId: 'fan-denied');
      expect(page.items, isEmpty);
    },
  );

  test(
    'createInstance fails closed when community group mapping is absent',
    () async {
      await _installCreatableDefinition(database);
      final unmappedService = WorkflowService(
        database: database,
        identityExtractor: const HeaderWorkflowIdentityExtractor(),
        appAccessClient: appAccessClient,
        communityGroupIdResolver: MapCommunityGroupIdResolver(const {}),
      );

      final response = await unmappedService.handler(
        _createRequest(
          fanId: 'fan-creator',
          body: {
            'workflowType': _workflowType,
            'instanceData': {'ownerFanId': 'fan-creator'},
          },
        ),
      );

      expect(response.statusCode, 503);
      expect(appAccessClient.callCount, 0);
    },
  );

  test(
    'createInstances allows one batch and returns instances in request order',
    () async {
      await _installCreatableDefinition(database);

      final response = await service.handler(
        _createBatchRequest(
          fanId: 'fan-batch-creator',
          body: {
            'workflowType': _workflowType,
            'initialInstanceDataList': [
              {'ownerFanId': 'fan-first'},
              {'ownerFanId': 'fan-second'},
            ],
          },
        ),
      );

      expect(response.statusCode, 201);
      final body = jsonDecode(await response.readAsString()) as List<dynamic>;
      expect(body, hasLength(2));
      expect(
        body.map((item) => (item as Map<String, dynamic>)['instanceData']),
        [
          {'ownerFanId': 'fan-first'},
          {'ownerFanId': 'fan-second'},
        ],
      );
      for (final item in body.cast<Map<String, dynamic>>()) {
        expect(item['workflowType'], _workflowType);
        expect(item['currentState'], 'draft');
        expect(item['updatedAt'], isA<String>());
        final stored = await database.readInstance(
          item['instanceId'] as String,
        );
        expect(stored, isNotNull);
        expect(stored!.createdByPersonaId, 'fan-batch-creator');
      }

      expect(appAccessClient.callCount, 1);
      expect(appAccessClient.fanId, 'fan-batch-creator');
      expect(appAccessClient.permissionId, 'event_rsvp.create');
    },
  );

  test(
    'createInstances denies generically after one access check and writes zero rows',
    () async {
      await _installCreatableDefinition(database);
      appAccessClient.allowed = false;

      final response = await service.handler(
        _createBatchRequest(
          fanId: 'fan-batch-denied',
          body: {
            'workflowType': _workflowType,
            'initialInstanceDataList': [
              {'ownerFanId': 'fan-first'},
              {'ownerFanId': 'fan-second'},
            ],
          },
        ),
      );

      expect(response.statusCode, 403);
      final encoded = await response.readAsString();
      expect(
        jsonDecode(encoded),
        containsPair('code', 'workflow_create_refused'),
      );
      expect(encoded, isNot(contains('event_rsvp.create')));
      expect(encoded, isNot(contains('grantingRoleIds')));
      expect(encoded, isNot(contains('role')));
      expect(appAccessClient.callCount, 1);
      final page = await LocalWorkflowEngineApi(
        db: database,
        communityId: _communityId,
      ).queryInstances(tabId: 'home', personaId: 'fan-batch-denied');
      expect(page.items, isEmpty);
    },
  );

  test(
    'createInstances refuses a response-table-owned type before App Access',
    () async {
      const responseWorkflowType = 'event-response-batch';
      await _installResponseTableDefinitionPair(
        database,
        responseWorkflowType: responseWorkflowType,
      );
      final definitions = await database.loadDefinitionsForCommunity(
        _communityId,
      );
      expect(
        const ArchetypeResolver()
            .resolveAll(definitions)[responseWorkflowType]!
            .origin,
        ArchetypeOrigin.inheritedFromResponseTable,
      );

      final response = await service.handler(
        _createBatchRequest(
          fanId: 'fan-event-organizer',
          body: {
            'workflowType': responseWorkflowType,
            'initialInstanceDataList': [
              {'eventId': 'fabricated-event', 'personaId': 'fan-victim'},
              {'eventId': 'fabricated-event', 'personaId': 'fan-other'},
            ],
          },
        ),
      );

      expect(response.statusCode, 403);
      expect(
        jsonDecode(await response.readAsString()),
        containsPair('code', 'workflow_create_refused'),
      );
      expect(appAccessClient.callCount, 0);
      final page = await LocalWorkflowEngineApi(
        db: database,
        communityId: _communityId,
      ).queryInstances(tabId: 'calendar', personaId: 'fan-event-organizer');
      expect(page.items, isEmpty);
    },
  );

  test(
    'createInstances rejects an empty batch as 400 without writes',
    () async {
      await _installCreatableDefinition(database);

      final response = await service.handler(
        _createBatchRequest(
          fanId: 'fan-batch-creator',
          body: {
            'workflowType': _workflowType,
            'initialInstanceDataList': <Map<String, dynamic>>[],
          },
        ),
      );

      expect(response.statusCode, 400);
      expect(
        jsonDecode(await response.readAsString()),
        containsPair('code', 'invalid_request'),
      );
      expect(appAccessClient.callCount, 0);
      final page = await LocalWorkflowEngineApi(
        db: database,
        communityId: _communityId,
      ).queryInstances(tabId: 'home', personaId: 'fan-batch-creator');
      expect(page.items, isEmpty);
    },
  );

  test(
    'createInstances rolls back earlier items when later validation fails',
    () async {
      await _installCreatableDefinition(database);

      final response = await service.handler(
        _createBatchRequest(
          fanId: 'fan-batch-creator',
          body: {
            'workflowType': _workflowType,
            'initialInstanceDataList': [
              {'ownerFanId': 'must-be-rolled-back'},
              <String, dynamic>{},
            ],
          },
        ),
      );

      expect(response.statusCode, 400);
      expect(
        jsonDecode(await response.readAsString()),
        containsPair('code', 'invalid_request'),
      );
      expect(appAccessClient.callCount, 1);
      final page = await LocalWorkflowEngineApi(
        db: database,
        communityId: _communityId,
      ).queryInstances(tabId: 'home', personaId: 'fan-batch-creator');
      expect(page.items, isEmpty);
    },
  );

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
    'updateInstanceFields allows an engine-authorized edit and returns it',
    () async {
      await _seedEditableInstance(database);

      final response = await service.handler(
        _fieldUpdateRequest(
          fanId: 'fan-editor',
          body: {
            'fieldUpdates': {'title': 'After'},
          },
        ),
      );

      expect(response.statusCode, 200);
      final body =
          jsonDecode(await response.readAsString()) as Map<String, dynamic>;
      expect(body['instanceId'], _editableInstanceId);
      expect(body['workflowType'], _editableWorkflowType);
      expect(body['currentState'], 'draft');
      expect(
        body['instanceData'] as Map<String, dynamic>,
        containsPair('title', 'After'),
      );
      expect(body['updatedAt'], isA<String>());
      final stored = await database.readInstance(_editableInstanceId);
      expect(jsonDecode(stored!.instanceData), containsPair('title', 'After'));
      expect(appAccessClient.callCount, 0);
    },
  );

  test(
    'updateInstanceFields maps editGuard refusal to a detail-free 403',
    () async {
      await _seedEditableInstance(database);

      final response = await service.handler(
        _fieldUpdateRequest(
          fanId: 'fan-denied',
          body: {
            'fieldUpdates': {'title': 'Must not persist'},
          },
        ),
      );

      expect(response.statusCode, 403);
      final encoded = await response.readAsString();
      expect(
        jsonDecode(encoded),
        containsPair('code', 'workflow_field_edit_refused'),
      );
      expect(encoded, isNot(contains('editGuard')));
      expect(encoded, isNot(contains('allowedPersonaIds')));
      expect(encoded, isNot(contains('fan-editor')));
      expect(encoded, isNot(contains('fan-denied')));
      expect(encoded, isNot(contains('title')));
      expect(
        jsonDecode(
          (await database.readInstance(_editableInstanceId))!.instanceData,
        ),
        containsPair('title', 'Before'),
      );
      expect(appAccessClient.callCount, 0);
    },
  );

  test(
    'updateInstanceFields refuses a field absent from editableFields',
    () async {
      await _seedEditableInstance(database);

      final response = await service.handler(
        _fieldUpdateRequest(
          fanId: 'fan-editor',
          body: {
            'fieldUpdates': {'locked': 'Must not persist'},
          },
        ),
      );

      expect(response.statusCode, 403);
      expect(
        jsonDecode(await response.readAsString()),
        containsPair('code', 'workflow_field_edit_refused'),
      );
      expect(appAccessClient.callCount, 0);
    },
  );

  test('updateInstanceFields refuses a computed field', () async {
    await _seedEditableInstance(database);

    final response = await service.handler(
      _fieldUpdateRequest(
        fanId: 'fan-editor',
        body: {
          'fieldUpdates': {'computedTitle': 'Must not persist'},
        },
      ),
    );

    expect(response.statusCode, 403);
    expect(
      jsonDecode(await response.readAsString()),
      containsPair('code', 'workflow_field_edit_refused'),
    );
    expect(appAccessClient.callCount, 0);
  });

  test('updateInstanceFields refuses an effect-only-writable field', () async {
    await _seedEditableInstance(database);

    final response = await service.handler(
      _fieldUpdateRequest(
        fanId: 'fan-editor',
        body: {
          'fieldUpdates': {'effectOnly': 'Must not persist'},
        },
      ),
    );

    expect(response.statusCode, 403);
    expect(
      jsonDecode(await response.readAsString()),
      containsPair('code', 'workflow_field_edit_refused'),
    );
    expect(appAccessClient.callCount, 0);
  });

  test('updateInstanceFields rejects an empty update as 400', () async {
    final response = await service.handler(
      _fieldUpdateRequest(
        fanId: 'fan-editor',
        body: {'fieldUpdates': <String, dynamic>{}},
      ),
    );

    expect(response.statusCode, 400);
    expect(
      jsonDecode(await response.readAsString()),
      containsPair('code', 'invalid_request'),
    );
    expect(appAccessClient.callCount, 0);
  });

  test(
    'updateInstanceFields returns another community instance as absent',
    () async {
      await _seedEditableInstance(database);

      final response = await service.handler(
        _fieldUpdateRequest(
          fanId: 'fan-editor',
          communityId: 'other',
          body: {
            'fieldUpdates': {'title': 'Must not persist'},
          },
        ),
      );

      expect(response.statusCode, 404);
      expect(
        jsonDecode(await response.readAsString()),
        containsPair('code', 'workflow_instance_not_found'),
      );
      expect(
        jsonDecode(
          (await database.readInstance(_editableInstanceId))!.instanceData,
        ),
        containsPair('title', 'Before'),
      );
      expect(appAccessClient.callCount, 0);
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

Future<void> _seedEditableInstance(WorkflowDatabase database) async {
  await database.upsertDefinition(
    definitionId: '${_communityId}_$_editableWorkflowType',
    workflowType: _editableWorkflowType,
    definitionJson: jsonEncode({
      'initialState': 'draft',
      'states': {
        'draft': {
          'label': 'Draft',
          'editableFields': ['title', 'computedTitle', 'effectOnly'],
          'editGuard': {
            'allowedPersonaIds': ['fan-editor'],
          },
        },
      },
      'transitions': <Map<String, dynamic>>[],
      'instanceDataSchema': {
        'title': {'type': 'text', 'writableBy': 'formEntry'},
        'locked': {'type': 'text', 'writableBy': 'formEntry'},
        'computedTitle': {'type': 'text', 'formula': 'title'},
        'effectOnly': {'type': 'text', 'writableBy': 'effect'},
      },
    }),
    version: 4,
  );
  await database.insertInstance(
    instanceId: _editableInstanceId,
    communityId: _communityId,
    workflowType: _editableWorkflowType,
    currentState: 'draft',
    instanceData: {'title': 'Before', 'locked': 'Locked'},
    createdByPersonaId: 'fan-editor',
  );
}

Future<void> _installCreatableDefinition(
  WorkflowDatabase database, {
  String workflowType = _workflowType,
  String family = 'event-rsvp',
}) async {
  final definition = _definitionMap();
  final transition =
      (definition['transitions'] as List<dynamic>).first
          as Map<String, dynamic>;
  transition['action'] = 'cancel';
  definition['renderBindings'] = [
    {
      'states': ['draft'],
      'role': 'any',
      'tabId': 'home',
      'cardSurfaceFamily': family,
      'bindingKind': 'primary',
      'actions': [
        {
          'kind': 'create',
          'label': 'Create event',
          'byRoleIds': ['event-organizer'],
          'scope': 'tab',
          'presentation': 'fab',
        },
      ],
    },
  ];
  await database.upsertDefinition(
    definitionId: '${_communityId}_$workflowType',
    workflowType: workflowType,
    definitionJson: jsonEncode(definition),
    version: 4,
  );
}

Future<void> _installResponseTableDefinitionPair(
  WorkflowDatabase database, {
  required String responseWorkflowType,
}) async {
  final eventDefinition = _definitionMap();
  eventDefinition['renderBindings'] = [
    {
      'states': ['draft'],
      'role': 'any',
      'tabId': 'calendar',
      'cardSurfaceFamily': 'event-rsvp',
      'bindingKind': 'primary',
      'responseTable': {
        'workflowType': responseWorkflowType,
        'eventField': 'eventId',
        'pendingStates': ['pending'],
      },
    },
  ];
  final responseDefinition = <String, dynamic>{
    'initialState': 'pending',
    'states': {
      'pending': {'label': 'Pending'},
    },
    'transitions': <Map<String, dynamic>>[],
    'renderBindings': <Map<String, dynamic>>[],
    'instanceDataSchema': {
      'eventId': {'type': 'text', 'required': true},
      'personaId': {'type': 'text', 'required': true},
    },
  };

  for (final entry in {
    _workflowType: eventDefinition,
    responseWorkflowType: responseDefinition,
  }.entries) {
    await database.upsertDefinition(
      definitionId: '${_communityId}_${entry.key}',
      workflowType: entry.key,
      definitionJson: jsonEncode(entry.value),
      version: 4,
    );
  }
}

Request _createRequest({
  required String fanId,
  required Map<String, dynamic> body,
}) => Request(
  'POST',
  Uri.parse('http://localhost/v1/communities/$_communityId/instances'),
  headers: _headers(fanId),
  body: jsonEncode(body),
);

Request _createBatchRequest({
  required String fanId,
  required Map<String, dynamic> body,
}) => Request(
  'POST',
  Uri.parse('http://localhost/v1/communities/$_communityId/instances/batch'),
  headers: _headers(fanId),
  body: jsonEncode(body),
);

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

Request _fieldUpdateRequest({
  required String fanId,
  String communityId = _communityId,
  String instanceId = _editableInstanceId,
  String correlationId = _correlationId,
  String idempotencyKey = 'unit-field-edit',
  required Map<String, dynamic> body,
}) => Request(
  'PATCH',
  Uri.parse(
    'http://localhost/v1/communities/$communityId/instances/'
    '$instanceId/fields',
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

class _RecordingAppAccessClient implements AppAccessDecisionClient {
  bool allowed = true;
  int callCount = 0;
  String? fanId;
  String? appId;
  String? permissionId;
  String? groupId;

  @override
  Future<bool> checkAccess({
    required String fanId,
    required String appId,
    required String permissionId,
    required String groupId,
    required String correlationId,
  }) async {
    callCount += 1;
    this.fanId = fanId;
    this.appId = appId;
    this.permissionId = permissionId;
    this.groupId = groupId;
    return allowed;
  }
}
