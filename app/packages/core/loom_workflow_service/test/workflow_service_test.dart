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
const _aggregateWorkflowType = 'aggregate-record';
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

  test('routes every community path through its transaction runner', () async {
    final communities = <String>[];
    final transactionService = WorkflowService(
      database: database,
      identityExtractor: const HeaderWorkflowIdentityExtractor(),
      appAccessClient: appAccessClient,
      communityGroupIdResolver: MapCommunityGroupIdResolver({
        _communityId: 'loom_communities_service_unit',
      }),
      communityTransactionRunner:
          <T>(String communityId, Future<T> Function() action) async {
            communities.add(communityId);
            return action();
          },
    );

    final response = await transactionService.handler(
      Request(
        'GET',
        Uri.parse(
          'http://localhost/v1/communities/$_communityId/no-such-route',
        ),
      ),
    );

    expect(response.statusCode, 404);
    expect(communities, [_communityId]);
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
      expect(stored!.createdByFanId, 'fan-creator');

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
    'unexpected database errors log one structured record while preserving the generic 500',
    () async {
      final logRecords = <String>[];
      final loggingService = WorkflowService(
        database: database,
        identityExtractor: const HeaderWorkflowIdentityExtractor(),
        appAccessClient: appAccessClient,
        communityGroupIdResolver: MapCommunityGroupIdResolver({
          _communityId: 'loom_communities_service_unit',
        }),
        unexpectedErrorLogSink: logRecords.add,
      );
      await _installCreatableDefinition(database);
      await database.execute('DROP TABLE workflow_instances');

      final response = await loggingService.handler(
        Request(
          'POST',
          Uri.parse('http://localhost/v1/communities/$_communityId/instances'),
          headers: {
            ..._headers('fan-creator'),
            'authorization': 'Bearer must-not-reach-the-log',
          },
          body: jsonEncode({
            'workflowType': _workflowType,
            'instanceData': {
              'ownerFanId': 'fan-creator',
              'privateMemberContent': 'must-not-reach-the-log',
            },
          }),
        ),
      );

      expect(response.statusCode, 500);
      expect(jsonDecode(await response.readAsString()), {
        'code': 'workflow_service_error',
        'message': 'The workflow instance could not be created.',
        'correlationId': _correlationId,
      });
      expect(response.headers['x-loom-correlation-id'], _correlationId);

      expect(logRecords, hasLength(1));
      final record = jsonDecode(logRecords.single) as Map<String, dynamic>;
      expect(record['correlationId'], _correlationId);
      expect(record['method'], 'POST');
      expect(record['path'], '/v1/communities/$_communityId/instances');
      expect(record['errorType'], isA<String>());
      expect(record['error'], isA<String>());
      expect(record['stackTrace'], isA<String>());
      expect(record['stackTrace'], isNotEmpty);
      expect(logRecords.single, isNot(contains('must-not-reach-the-log')));
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
              'fanId': 'fan-victim',
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
      ).queryInstances(tabId: 'home', fanId: 'fan-denied');
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
        expect(stored!.createdByFanId, 'fan-batch-creator');
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
      ).queryInstances(tabId: 'home', fanId: 'fan-batch-denied');
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
              {'eventId': 'fabricated-event', 'fanId': 'fan-victim'},
              {'eventId': 'fabricated-event', 'fanId': 'fan-other'},
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
      ).queryInstances(tabId: 'calendar', fanId: 'fan-event-organizer');
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
      ).queryInstances(tabId: 'home', fanId: 'fan-batch-creator');
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
      ).queryInstances(tabId: 'home', fanId: 'fan-batch-creator');
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
        createdByFanId: 'fan-owner',
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
        _replaceDefinitionsRequest(
          <String, dynamic>{},
          specVersion: '$currentCommunitySpecVersion',
        ),
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
          specVersion: currentCommunitySpecVersion + 1,
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
        createdByFanId: 'fan-owner',
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
        createdByFanId: 'fan-other',
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
        createdByFanId: 'fan-other',
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
          createdByFanId: 'fan-owner',
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

  test('aggregate returns a filtered count without App Access', () async {
    await _seedAggregateRows(database);

    final response = await service.handler(
      _aggregateRequest(
        fanId: 'fan-owner',
        body: {
          'workflowType': _aggregateWorkflowType,
          'column': 'amount',
          'op': 'count',
          'filter': {'status': 'unread'},
        },
      ),
    );

    expect(response.statusCode, 200);
    expect(
      jsonDecode(await response.readAsString()),
      containsPair('result', 2),
    );
    expect(appAccessClient.callCount, 0);
  });

  test('aggregate groups rows and returns each group value', () async {
    await _seedAggregateRows(database);

    final response = await service.handler(
      _aggregateRequest(
        fanId: 'fan-owner',
        body: {
          'workflowType': _aggregateWorkflowType,
          'column': 'amount',
          'op': 'sum',
          'groupBy': 'category',
        },
      ),
    );

    expect(response.statusCode, 200);
    final body =
        jsonDecode(await response.readAsString()) as Map<String, dynamic>;
    expect(
      body['result'],
      unorderedEquals([
        {'category': 'alpha', 'sum': 7},
        {'category': 'beta', 'sum': 11},
      ]),
    );
    expect(appAccessClient.callCount, 0);
  });

  test('aggregate preserves empty sum and average semantics', () async {
    await _seedAggregateRows(database);
    final body = {
      'workflowType': _aggregateWorkflowType,
      'column': 'amount',
      'filter': {'status': 'missing'},
    };

    final sumResponse = await service.handler(
      _aggregateRequest(fanId: 'fan-owner', body: {...body, 'op': 'sum'}),
    );
    final avgResponse = await service.handler(
      _aggregateRequest(fanId: 'fan-owner', body: {...body, 'op': 'avg'}),
    );

    expect(sumResponse.statusCode, 200);
    expect(
      jsonDecode(await sumResponse.readAsString()),
      containsPair('result', 0),
    );
    expect(avgResponse.statusCode, 200);
    expect(
      jsonDecode(await avgResponse.readAsString()),
      containsPair('result', isNull),
    );
    expect(appAccessClient.callCount, 0);
  });

  test('aggregate rejects an unsupported operation as 400', () async {
    final response = await service.handler(
      _aggregateRequest(
        fanId: 'fan-owner',
        body: {
          'workflowType': _aggregateWorkflowType,
          'column': 'amount',
          'op': 'median',
        },
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
    'aggregate rejects missing, empty, and malformed fields as 400',
    () async {
      final invalidBodies = <Map<String, dynamic>>[
        {'column': 'amount', 'op': 'count'},
        {'workflowType': '   ', 'column': 'amount', 'op': 'count'},
        {'workflowType': _aggregateWorkflowType, 'op': 'count'},
        {
          'workflowType': _aggregateWorkflowType,
          'column': '   ',
          'op': 'count',
        },
        {
          'workflowType': _aggregateWorkflowType,
          'column': 'amount',
          'op': 'count',
          'filter': <dynamic>[],
        },
      ];

      for (final body in invalidBodies) {
        final response = await service.handler(
          _aggregateRequest(fanId: 'fan-owner', body: body),
        );
        expect(response.statusCode, 400, reason: '$body');
        expect(
          jsonDecode(await response.readAsString()),
          containsPair('code', 'invalid_request'),
          reason: '$body',
        );
      }
      expect(appAccessClient.callCount, 0);
    },
  );

  test(
    'aggregate counts only instances visible to the extracted fan',
    () async {
      await _seedAggregateRows(database, guarded: true);

      final response = await service.handler(
        _aggregateRequest(
          fanId: 'fan-owner',
          body: {
            'workflowType': _aggregateWorkflowType,
            'column': 'amount',
            'op': 'count',
            // A body value cannot select aggregate's unscoped engine path.
            'fanId': null,
          },
        ),
      );

      expect(response.statusCode, 200);
      expect(
        jsonDecode(await response.readAsString()),
        containsPair('result', 1),
      );
      expect(appAccessClient.callCount, 0);
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

  test('updateInstanceFields resolves roles for a role-guarded edit', () async {
    await _seedEditableInstance(database, roleGuarded: true);
    appAccessClient.roleIds = {'hoa-board'};

    final response = await service.handler(
      _fieldUpdateRequest(
        fanId: 'fan-board-member',
        body: {
          'fieldUpdates': {'title': 'Updated by board'},
        },
      ),
    );

    expect(response.statusCode, 200);
    expect(appAccessClient.roleResolutionCallCount, 1);
    expect(appAccessClient.roleResolutionFanId, 'fan-board-member');
    expect(appAccessClient.roleResolutionAppId, 'loom_communities');
    expect(
      appAccessClient.roleResolutionGroupId,
      'loom_communities_service_unit',
    );
    expect(appAccessClient.roleResolutionCorrelationId, _correlationId);
    expect(
      jsonDecode(
        (await database.readInstance(_editableInstanceId))!.instanceData,
      ),
      containsPair('title', 'Updated by board'),
    );
  });

  test(
    'updateInstanceFields refuses a member without the required role',
    () async {
      await _seedEditableInstance(database, roleGuarded: true);

      final response = await service.handler(
        _fieldUpdateRequest(
          fanId: 'fan-member-without-role',
          body: {
            'fieldUpdates': {'title': 'Must not persist'},
          },
        ),
      );

      expect(response.statusCode, 403);
      expect(
        jsonDecode(await response.readAsString()),
        containsPair('code', 'workflow_field_edit_refused'),
      );
      expect(appAccessClient.roleResolutionCallCount, 1);
      expect(
        jsonDecode(
          (await database.readInstance(_editableInstanceId))!.instanceData,
        ),
        containsPair('title', 'Before'),
      );
    },
  );

  test(
    'updateInstanceFields refuses a non-member before a role guard',
    () async {
      await _seedEditableInstance(database, roleGuarded: true);
      appAccessClient.roleIds = {'hoa-board'};
      appAccessClient.activeMembership = false;

      final response = await service.handler(
        _fieldUpdateRequest(
          fanId: 'fan-former-board-member',
          body: {
            'fieldUpdates': {'title': 'Must not persist'},
          },
        ),
      );

      expect(response.statusCode, 403);
      expect(
        jsonDecode(await response.readAsString()),
        containsPair('code', 'community_membership_required'),
      );
      expect(appAccessClient.roleResolutionCallCount, 1);
      expect(
        jsonDecode(
          (await database.readInstance(_editableInstanceId))!.instanceData,
        ),
        containsPair('title', 'Before'),
      );
    },
  );

  test(
    'updateInstanceFields returns 503 when role resolution is unavailable',
    () async {
      await _seedEditableInstance(database, roleGuarded: true);
      appAccessClient.roleResolutionError = const AppAccessDecisionException(
        'App Access role resolution failed.',
      );

      final response = await service.handler(
        _fieldUpdateRequest(
          fanId: 'fan-board-member',
          body: {
            'fieldUpdates': {'title': 'Must not persist'},
          },
        ),
      );

      expect(response.statusCode, 503);
      expect(
        jsonDecode(await response.readAsString()),
        containsPair('code', 'authorization_service_unavailable'),
      );
      expect(appAccessClient.roleResolutionCallCount, 1);
      expect(
        jsonDecode(
          (await database.readInstance(_editableInstanceId))!.instanceData,
        ),
        containsPair('title', 'Before'),
      );
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
      expect(
        encoded,
        isNot(
          contains(
            'allowedPer'
            'sonaIds',
          ),
        ),
      );
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

  test('applyTransition fills an empty declared opaqueId field', () async {
    await _seedPlatformSourceInstance(database);

    final response = await service.handler(
      _transitionRequest(fanId: 'fan-owner', body: {'transitionId': 'record'}),
    );

    expect(response.statusCode, 200);
    final instanceData =
        (jsonDecode(await response.readAsString())
                as Map<String, dynamic>)['instanceData']
            as Map<String, dynamic>;
    expect(instanceData['transferReference'], matches(_uuidV4Pattern));
    final stored =
        jsonDecode((await database.readInstance(_instanceId))!.instanceData)
            as Map<String, dynamic>;
    expect(stored['transferReference'], instanceData['transferReference']);
  });

  test('applyTransition never rewrites an opaqueId', () async {
    await _seedPlatformSourceInstance(database);

    final first = await service.handler(
      _transitionRequest(fanId: 'fan-owner', body: {'transitionId': 'record'}),
    );
    expect(first.statusCode, 200);
    final firstId =
        ((jsonDecode(await first.readAsString())
                as Map<String, dynamic>)['instanceData']
            as Map<String, dynamic>)['transferReference'];

    final second = await service.handler(
      _transitionRequest(
        fanId: 'fan-owner',
        idempotencyKey: 'second-opaque-id-transition',
        body: {'transitionId': 'record'},
      ),
    );
    expect(second.statusCode, 200);
    final secondId =
        ((jsonDecode(await second.readAsString())
                as Map<String, dynamic>)['instanceData']
            as Map<String, dynamic>)['transferReference'];

    expect(secondId, firstId);
  });

  test('applyTransition does not mint a checksum field', () async {
    await _seedPlatformSourceInstance(database);

    final response = await service.handler(
      _transitionRequest(fanId: 'fan-owner', body: {'transitionId': 'record'}),
    );

    expect(response.statusCode, 200);
    final instanceData =
        (jsonDecode(await response.readAsString())
                as Map<String, dynamic>)['instanceData']
            as Map<String, dynamic>;
    expect(instanceData, isNot(contains('servedBundleChecksum')));
  });

  test(
    'applyTransition mints unique opaqueIds across an instance batch',
    () async {
      await _installPlatformSourceDefinition(database);
      const batchSize = 24;
      final instanceIds = List<String>.generate(
        batchSize,
        (index) => 'opaque-batch-instance-$index',
      );
      for (final instanceId in instanceIds) {
        await database.insertInstance(
          instanceId: instanceId,
          communityId: _communityId,
          workflowType: _workflowType,
          currentState: 'draft',
          instanceData: const {'ownerFanId': 'fan-owner'},
          createdByFanId: 'fan-owner',
        );
      }

      for (final (index, instanceId) in instanceIds.indexed) {
        final response = await service.handler(
          _transitionRequest(
            fanId: 'fan-owner',
            instanceId: instanceId,
            idempotencyKey: 'opaque-batch-transition-$index',
            body: {'transitionId': 'record'},
          ),
        );
        expect(response.statusCode, 200);
      }

      final ids = <String>{
        for (final instanceId in instanceIds)
          (jsonDecode((await database.readInstance(instanceId))!.instanceData)
                  as Map<String, dynamic>)['transferReference']
              as String,
      };
      expect(ids, hasLength(batchSize));
    },
  );

  test('applyTransition opaqueIds do not encode request context', () async {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    await _seedPlatformSourceInstance(
      database,
      instanceData: {
        'ownerFanId': 'fan-owner',
        'batchCounter': 'batch-counter-00001',
        'transitionTimestamp': timestamp,
      },
    );

    final response = await service.handler(
      _transitionRequest(fanId: 'fan-owner', body: {'transitionId': 'record'}),
    );
    expect(response.statusCode, 200);
    final opaqueId =
        ((jsonDecode(await response.readAsString())
                    as Map<String, dynamic>)['instanceData']
                as Map<String, dynamic>)['transferReference']
            as String;

    for (final forbiddenSubstring in [
      _communityId,
      _instanceId,
      _workflowType,
      'fan-owner',
      'batch-counter-00001',
      timestamp,
    ]) {
      expect(opaqueId, isNot(contains(forbiddenSubstring)));
    }
  });

  test('applyTransition accepts a role guard resolved by App Access', () async {
    await _seedRoleGuardedTransition(database);
    appAccessClient.roleIds = {'hoa-board'};

    final response = await service.handler(
      _transitionRequest(
        fanId: 'fan-board-member',
        body: {'transitionId': 'approve'},
      ),
    );

    expect(response.statusCode, 200);
    expect(appAccessClient.roleResolutionCallCount, 1);
    expect(appAccessClient.roleResolutionFanId, 'fan-board-member');
    expect(appAccessClient.roleResolutionAppId, 'loom_communities');
    expect(
      appAccessClient.roleResolutionGroupId,
      'loom_communities_service_unit',
    );
    expect(appAccessClient.roleResolutionCorrelationId, _correlationId);
    expect(
      (await database.readInstance(_instanceId))!.currentState,
      'approved',
    );
  });

  test(
    'applyTransition fails closed for empty and unavailable role resolution',
    () async {
      await _seedRoleGuardedTransition(database);

      appAccessClient.roleIds = <String>{};
      final emptyRoles = await service.handler(
        _transitionRequest(
          fanId: 'fan-board-member',
          body: {'transitionId': 'approve'},
        ),
      );
      expect(emptyRoles.statusCode, 403);
      expect(
        jsonDecode(await emptyRoles.readAsString()),
        containsPair('code', 'workflow_guard_refused'),
      );
      expect(appAccessClient.roleResolutionCallCount, 1);

      appAccessClient.roleResolutionError = const AppAccessDecisionException(
        'App Access role resolution failed.',
      );
      final unavailable = await service.handler(
        _transitionRequest(
          fanId: 'fan-board-member',
          idempotencyKey: 'role-resolution-unavailable',
          body: {'transitionId': 'approve'},
        ),
      );
      expect(unavailable.statusCode, 503);
      expect(
        jsonDecode(await unavailable.readAsString()),
        containsPair('code', 'authorization_service_unavailable'),
      );
      expect(appAccessClient.roleResolutionCallCount, 2);
      expect((await database.readInstance(_instanceId))!.currentState, 'draft');
    },
  );

  test(
    'applyTransition fails closed when the community group is unavailable',
    () async {
      await _seedRoleGuardedTransition(database);
      final unmappedService = WorkflowService(
        database: database,
        identityExtractor: const HeaderWorkflowIdentityExtractor(),
        appAccessClient: appAccessClient,
        communityGroupIdResolver: MapCommunityGroupIdResolver(const {}),
      );

      final response = await unmappedService.handler(
        _transitionRequest(
          fanId: 'fan-board-member',
          body: {'transitionId': 'approve'},
        ),
      );

      expect(response.statusCode, 503);
      expect(
        jsonDecode(await response.readAsString()),
        containsPair('code', 'authorization_service_unavailable'),
      );
      expect(appAccessClient.roleResolutionCallCount, 0);
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
    createdByFanId: 'fan-owner',
  );
}

const _uuidV4Pattern =
    r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$';

Future<void> _seedPlatformSourceInstance(
  WorkflowDatabase database, {
  Map<String, dynamic> instanceData = const {'ownerFanId': 'fan-owner'},
}) async {
  await _installPlatformSourceDefinition(database);
  await database.insertInstance(
    instanceId: _instanceId,
    communityId: _communityId,
    workflowType: _workflowType,
    currentState: 'draft',
    instanceData: instanceData,
    createdByFanId: 'fan-owner',
  );
}

Future<void> _installPlatformSourceDefinition(WorkflowDatabase database) async {
  final definition = _definitionMap();
  definition['transitions'] = [
    {
      'id': 'record',
      'label': 'Record',
      'from': ['draft', 'recorded'],
      'to': 'recorded',
      'guard': {
        'actorEqualsField': {'key': 'ownerFanId'},
      },
    },
  ];
  final schema = definition['instanceDataSchema'] as Map<String, dynamic>;
  schema['transferReference'] = {
    'type': 'text?',
    'writableBy': 'platform',
    'platformSource': 'opaqueId',
  };
  schema['servedBundleChecksum'] = {
    'type': 'text?',
    'writableBy': 'platform',
    'platformSource': 'checksum',
  };
  await database.upsertDefinition(
    definitionId: '${_communityId}_$_workflowType',
    workflowType: _workflowType,
    definitionJson: jsonEncode(definition),
    version: 4,
  );
}

Future<void> _seedRoleGuardedTransition(WorkflowDatabase database) async {
  await database.upsertDefinition(
    definitionId: '${_communityId}_$_workflowType',
    workflowType: _workflowType,
    definitionJson: jsonEncode({
      'initialState': 'draft',
      'states': {
        'draft': {'label': 'Draft'},
        'approved': {'label': 'Approved'},
      },
      'transitions': [
        {
          'id': 'approve',
          'label': 'Approve',
          'from': ['draft'],
          'to': 'approved',
          'guard': {
            'allowedRoleIds': ['hoa-board'],
          },
        },
      ],
      'instanceDataSchema': <String, dynamic>{},
    }),
    version: 4,
  );
  await database.insertInstance(
    instanceId: _instanceId,
    communityId: _communityId,
    workflowType: _workflowType,
    currentState: 'draft',
    instanceData: const <String, dynamic>{},
    createdByFanId: 'fan-creator',
  );
}

Future<void> _seedEditableInstance(
  WorkflowDatabase database, {
  bool roleGuarded = false,
}) async {
  await database.upsertDefinition(
    definitionId: '${_communityId}_$_editableWorkflowType',
    workflowType: _editableWorkflowType,
    definitionJson: jsonEncode({
      'initialState': 'draft',
      'states': {
        'draft': {
          'label': 'Draft',
          'editableFields': ['title', 'computedTitle', 'effectOnly'],
          'editGuard': roleGuarded
              ? {
                  'allowedRoleIds': ['hoa-board'],
                }
              : {
                  'actorEqualsField': {'key': 'editorFanId'},
                },
        },
      },
      'transitions': <Map<String, dynamic>>[],
      'instanceDataSchema': {
        'title': {'type': 'text', 'writableBy': 'formEntry'},
        'locked': {'type': 'text', 'writableBy': 'formEntry'},
        'computedTitle': {'type': 'text', 'formula': 'title'},
        'effectOnly': {'type': 'text', 'writableBy': 'effect'},
        'editorFanId': {
          'type': 'fanId',
          'required': true,
          'writableBy': 'formEntry',
        },
      },
    }),
    version: 4,
  );
  await database.insertInstance(
    instanceId: _editableInstanceId,
    communityId: _communityId,
    workflowType: _editableWorkflowType,
    currentState: 'draft',
    instanceData: {
      'title': 'Before',
      'locked': 'Locked',
      'editorFanId': 'fan-editor',
    },
    createdByFanId: 'fan-editor',
  );
}

Future<void> _seedAggregateRows(
  WorkflowDatabase database, {
  bool guarded = false,
}) async {
  final definition = _definitionMap();
  if (guarded) {
    definition['visibility'] = {
      'default': 'guarded',
      'readGuard': {
        'actorEqualsField': {'key': 'ownerFanId'},
      },
    };
  }
  await database.upsertDefinition(
    definitionId: '${_communityId}_$_aggregateWorkflowType',
    workflowType: _aggregateWorkflowType,
    definitionJson: jsonEncode(definition),
    version: 4,
  );
  final rows = guarded
      ? const [
          ('aggregate-visible', 'fan-owner', 'alpha', 'unread', 2),
          ('aggregate-hidden', 'fan-other', 'beta', 'read', 11),
        ]
      : const [
          ('aggregate-alpha-first', 'fan-owner', 'alpha', 'unread', 2),
          ('aggregate-alpha-second', 'fan-owner', 'alpha', 'unread', 5),
          ('aggregate-beta', 'fan-owner', 'beta', 'read', 11),
        ];
  for (final (id, ownerFanId, category, status, amount) in rows) {
    await database.insertInstance(
      instanceId: id,
      communityId: _communityId,
      workflowType: _aggregateWorkflowType,
      currentState: 'draft',
      instanceData: {
        'ownerFanId': ownerFanId,
        'category': category,
        'status': status,
        'amount': amount,
      },
      createdByFanId: ownerFanId,
    );
  }
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
      'audience': 'any',
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
      'audience': 'any',
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
      'fanId': {'type': 'fanId', 'required': true},
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

Request _aggregateRequest({
  required String fanId,
  required Map<String, dynamic> body,
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
  body: jsonEncode(body),
);

Request _transitionRequest({
  String? fanId,
  String instanceId = _instanceId,
  String correlationId = _correlationId,
  String idempotencyKey = 'unit-test-key',
  required Map<String, dynamic> body,
}) => Request(
  'POST',
  Uri.parse(
    'http://localhost/v1/communities/$_communityId/instances/'
    '$instanceId/transitions',
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
  Object specVersion = currentCommunitySpecVersion,
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
  @override
  Future<List<GroupMember>> listGroupMembers({
    required String appId,
    required String groupId,
    required String correlationId,
  }) async => const <GroupMember>[];
  bool allowed = true;
  // True by default so the tests written before membership was resolved
  // keep their original behaviour. None of them use `membersOnly`.
  bool activeMembership = true;
  int callCount = 0;
  Set<String> roleIds = const {};
  Object? roleResolutionError;
  int roleResolutionCallCount = 0;
  String? fanId;
  String? appId;
  String? permissionId;
  String? groupId;
  String? roleResolutionFanId;
  String? roleResolutionAppId;
  String? roleResolutionGroupId;
  String? roleResolutionCorrelationId;

  @override
  Future<bool> hasActiveMembership({
    required String fanId,
    required String appId,
    required String groupId,
    required String correlationId,
  }) async => activeMembership;

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

  @override
  Future<Set<String>> resolveRoleIds({
    required String fanId,
    required String appId,
    required String groupId,
    required String correlationId,
  }) async {
    roleResolutionCallCount += 1;
    roleResolutionFanId = fanId;
    roleResolutionAppId = appId;
    roleResolutionGroupId = groupId;
    roleResolutionCorrelationId = correlationId;
    final error = roleResolutionError;
    if (error != null) throw error;
    return roleIds;
  }
}
