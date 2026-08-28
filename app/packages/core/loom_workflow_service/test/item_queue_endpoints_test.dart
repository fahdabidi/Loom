import 'dart:convert';

import 'package:loom_workflow_engine/loom_workflow_engine.dart';
import 'package:loom_workflow_service/loom_workflow_service.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

const _communityId = 'queue-test-community';
const _groupId = 'loom_communities_queue-test-community';
const _workflowType = 'equipment-item';
const _instanceId = 'item-one';
const _secondInstanceId = 'item-two';
const _correlationId = '88888888-8888-4888-8888-888888888888';
const _memberOne = 'fan-member-one';
const _memberTwo = 'fan-member-two';
const _memberThree = 'fan-member-three';
const _admin = 'fan-queue-admin';
const _observer = 'fan-observer';

const _queueDefinition = '''
{
  "initialState": "published",
  "visibility": {"default": "public"},
  "states": {"published": {"label": "Published"}},
  "transitions": [
    {"id": "join-queue", "label": "Join queue", "action": "join_queue",
     "from": ["published"], "to": null,
     "guard": {"allowedRoleIds": ["queue-member"]}},
    {"id": "leave-queue", "label": "Leave queue", "action": "leave_queue",
     "from": ["published"], "to": null,
     "guard": {"allowedRoleIds": ["queue-member"]}},
    {"id": "decide-request", "label": "Decide request", "action": "decide_request",
     "from": ["published"], "to": null,
     "guard": {"allowedRoleIds": ["queue-admin"]}}
  ],
  "renderBindings": [
    {"states": ["published"], "audience": "any", "tabId": "marketplace",
     "cardSurfaceFamily": "equipment-loan", "bindingKind": "primary"}
  ],
  "instanceDataSchema": {
    "title": {"type": "text", "writableBy": "formEntry"},
    "currentHolderFanId": {"type": "fanId?", "writableBy": "effect"}
  }
}
''';

const _noJoinDefinition = '''
{
  "initialState": "published",
  "visibility": {"default": "public"},
  "states": {"published": {"label": "Published"}},
  "transitions": [
    {"id": "leave-queue", "label": "Leave queue", "action": "leave_queue",
     "from": ["published"], "to": null,
     "guard": {"allowedRoleIds": ["queue-member"]}},
    {"id": "decide-request", "label": "Decide request", "action": "decide_request",
     "from": ["published"], "to": null,
     "guard": {"allowedRoleIds": ["queue-admin"]}}
  ],
  "renderBindings": [
    {"states": ["published"], "audience": "any", "tabId": "marketplace",
     "cardSurfaceFamily": "equipment-loan", "bindingKind": "primary"}
  ],
  "instanceDataSchema": {
    "title": {"type": "text", "writableBy": "formEntry"}
  }
}
''';

void main() {
  late WorkflowDatabase database;
  late WorkflowService service;
  late DateTime now;

  setUp(() async {
    database = WorkflowDatabase.memory();
    now = DateTime.utc(2026, 8, 28, 16);
    service = WorkflowService(
      database: database,
      identityExtractor: const HeaderWorkflowIdentityExtractor(),
      appAccessClient: const _QueueAppAccessClient(),
      communityGroupIdResolver: MapCommunityGroupIdResolver({
        _communityId: _groupId,
      }),
      itemQueueRepository: InMemoryItemQueueRepository(),
      queueOfferHoldWindows: <String, Duration>{
        _communityId: const Duration(minutes: 30),
      },
      clock: () => now,
    );
    await database.upsertDefinition(
      definitionId: '${_communityId}_$_workflowType',
      workflowType: _workflowType,
      definitionJson: _queueDefinition,
      version: 4,
    );
    await _insertItem(database, _instanceId, title: 'Community camera');
  });

  tearDown(() {
    database.close();
  });

  test(
    'joining gives contiguous positions and each member sees their own',
    () async {
      final first = await _join(service, _memberOne);
      final second = await _join(service, _memberTwo);

      expect(first.response.statusCode, 201, reason: first.rawBody);
      expect(first.body['position'], 1);
      expect(second.response.statusCode, 201, reason: second.rawBody);
      expect(second.body['position'], 2);

      final firstQueue = await _getQueue(service, _memberOne);
      final secondQueue = await _getQueue(service, _memberTwo);
      expect(firstQueue.body['length'], 2);
      expect(firstQueue.body['viewerPosition'], 1);
      expect(secondQueue.body['viewerPosition'], 2);
    },
  );

  test('joining twice keeps the original position and returns 200', () async {
    final first = await _join(service, _memberOne);
    now = now.add(const Duration(minutes: 1));
    final repeated = await _join(service, _memberOne);

    expect(first.response.statusCode, 201, reason: first.rawBody);
    expect(repeated.response.statusCode, 200, reason: repeated.rawBody);
    expect(repeated.body['position'], 1);
    expect(repeated.body['joinedAt'], first.body['joinedAt']);
  });

  test('leaving from the middle closes the gap by exactly one', () async {
    await _join(service, _memberOne);
    await _join(service, _memberTwo);
    await _join(service, _memberThree);

    final left = await service.handler(
      _request(
        'DELETE',
        '/v1/communities/$_communityId/instances/$_instanceId/queue',
        fanId: _memberTwo,
      ),
    );
    expect(left.statusCode, 204);

    final queue = await _getQueue(service, _admin);
    final entries = queue.body['entries'] as List<dynamic>;
    expect(entries, hasLength(2));
    expect(entries[0], containsPair('fanId', _memberOne));
    expect(entries[0], containsPair('position', 1));
    expect(entries[1], containsPair('fanId', _memberThree));
    expect(entries[1], containsPair('position', 2));
  });

  test('leaving a queue the member is not in is a successful 204', () async {
    final response = await service.handler(
      _request(
        'DELETE',
        '/v1/communities/$_communityId/instances/$_instanceId/queue',
        fanId: _memberOne,
      ),
    );

    expect(response.statusCode, 204);
  });

  test('a non-member sees viewerPosition zero', () async {
    await _join(service, _memberOne);

    final queue = await _getQueue(service, _observer);
    expect(queue.response.statusCode, 200, reason: queue.rawBody);
    expect(queue.body['viewerPosition'], 0);
  });

  test(
    'entries are omitted for a member and present for an administrator',
    () async {
      await _join(service, _memberOne);

      final memberQueue = await _getQueue(service, _memberOne);
      final adminQueue = await _getQueue(service, _admin);
      expect(memberQueue.body.containsKey('entries'), isFalse);
      expect(adminQueue.body['entries'], isA<List<dynamic>>());
      expect((adminQueue.body['entries'] as List<dynamic>), hasLength(1));
    },
  );

  test('advance offers the head and an empty queue returns 204', () async {
    final empty = await _advance(service);
    expect(empty.statusCode, 204);

    await _join(service, _memberOne);
    final offered = await _advance(service, idempotencyKey: 'advance-offer');
    final body =
        jsonDecode(await offered.readAsString()) as Map<String, dynamic>;
    expect(offered.statusCode, 200);
    expect(body['instanceId'], _instanceId);
    expect(body['fanId'], _memberOne);
    expect(body['offerExpiresAt'], isA<String>());
    expect(
      DateTime.parse(body['offerExpiresAt'] as String),
      now.add(const Duration(minutes: 30)),
    );
  });

  test(
    'a lapsed offer removes its head and passes to the next member',
    () async {
      await _join(service, _memberOne);
      await _join(service, _memberTwo);
      final first = await _advance(service, idempotencyKey: 'advance-first');
      expect(first.statusCode, 200);

      now = now.add(const Duration(minutes: 31));
      final second = await _advance(service, idempotencyKey: 'advance-second');
      final body =
          jsonDecode(await second.readAsString()) as Map<String, dynamic>;
      expect(second.statusCode, 200);
      expect(body['fanId'], _memberTwo);

      final queue = await _getQueue(service, _admin);
      final entries = queue.body['entries'] as List<dynamic>;
      expect(entries, hasLength(1));
      expect(entries.single, containsPair('fanId', _memberTwo));
      expect(entries.single, containsPair('position', 1));
    },
  );

  test('removing another member requires decide_request', () async {
    await _join(service, _memberOne);
    final forbidden = await service.handler(
      _request(
        'DELETE',
        '/v1/communities/$_communityId/instances/$_instanceId/queue/$_memberOne',
        fanId: _memberTwo,
      ),
    );

    expect(forbidden.statusCode, 403);
    final queue = await _getQueue(service, _admin);
    expect(queue.body['length'], 1);
  });

  test(
    'joining without an available join_queue transition is forbidden',
    () async {
      const noJoinInstanceId = 'item-without-join';
      await database.upsertDefinition(
        definitionId: '${_communityId}_no-join-item',
        workflowType: 'no-join-item',
        definitionJson: _noJoinDefinition,
        version: 4,
      );
      await _insertItem(
        database,
        noJoinInstanceId,
        workflowType: 'no-join-item',
        title: 'No waiting list',
      );

      final response = await service.handler(
        _request(
          'POST',
          '/v1/communities/$_communityId/instances/$noJoinInstanceId/queue',
          fanId: _memberOne,
        ),
      );
      expect(response.statusCode, 403);
    },
  );

  test(
    'a missing correlation id is rejected before queue processing',
    () async {
      final response = await service.handler(
        _request(
          'GET',
          '/v1/communities/$_communityId/instances/$_instanceId/queue',
          fanId: _memberOne,
          includeCorrelationId: false,
        ),
      );

      expect(response.statusCode, 400);
      expect(
        jsonDecode(await response.readAsString()),
        containsPair('code', 'invalid_correlation_id'),
      );
    },
  );

  test(
    'listMyQueueMemberships returns only the caller across item instances',
    () async {
      await _insertItem(database, _secondInstanceId, title: 'Tripod');
      await _join(service, _memberOne);
      await _join(service, _memberTwo);
      await _join(service, _memberOne, instanceId: _secondInstanceId);

      final response = await service.handler(
        _request(
          'GET',
          '/v1/communities/$_communityId/queue-memberships',
          fanId: _memberOne,
        ),
      );
      final body =
          jsonDecode(await response.readAsString()) as Map<String, dynamic>;
      final memberships = (body['memberships'] as List<dynamic>)
          .cast<Map<String, dynamic>>();
      expect(response.statusCode, 200);
      expect(body['fanId'], _memberOne);
      expect(memberships, hasLength(2));
      expect(
        memberships.map((membership) => membership['instanceId']).toSet(),
        {_instanceId, _secondInstanceId},
      );
      expect(memberships.map((membership) => membership['itemTitle']).toSet(), {
        'Community camera',
        'Tripod',
      });
    },
  );
}

Future<void> _insertItem(
  WorkflowDatabase database,
  String instanceId, {
  String workflowType = _workflowType,
  required String title,
}) => database.insertInstance(
  instanceId: instanceId,
  communityId: _communityId,
  workflowType: workflowType,
  currentState: 'published',
  instanceData: <String, dynamic>{'title': title},
  createdByFanId: _admin,
);

Future<_JsonResponse> _join(
  WorkflowService service,
  String fanId, {
  String instanceId = _instanceId,
}) async {
  final response = await service.handler(
    _request(
      'POST',
      '/v1/communities/$_communityId/instances/$instanceId/queue',
      fanId: fanId,
    ),
  );
  final rawBody = await response.readAsString();
  return _JsonResponse(
    response: response,
    rawBody: rawBody,
    body: jsonDecode(rawBody) as Map<String, dynamic>,
  );
}

Future<_JsonResponse> _getQueue(WorkflowService service, String fanId) async {
  final response = await service.handler(
    _request(
      'GET',
      '/v1/communities/$_communityId/instances/$_instanceId/queue',
      fanId: fanId,
    ),
  );
  final rawBody = await response.readAsString();
  return _JsonResponse(
    response: response,
    rawBody: rawBody,
    body: jsonDecode(rawBody) as Map<String, dynamic>,
  );
}

Future<Response> _advance(
  WorkflowService service, {
  String idempotencyKey = 'advance-empty',
}) async => await service.handler(
  _request(
    'POST',
    '/v1/communities/$_communityId/instances/$_instanceId/queue/advance',
    fanId: _admin,
    idempotencyKey: idempotencyKey,
  ),
);

Request _request(
  String method,
  String path, {
  required String fanId,
  bool includeCorrelationId = true,
  String? idempotencyKey,
}) => Request(
  method,
  Uri.parse('http://localhost$path'),
  headers: <String, String>{
    if (includeCorrelationId) 'x-loom-correlation-id': _correlationId,
    if (idempotencyKey != null) 'idempotency-key': idempotencyKey,
    HeaderWorkflowIdentityExtractor.defaultHeaderName: fanId,
  },
);

class _JsonResponse {
  const _JsonResponse({
    required this.response,
    required this.rawBody,
    required this.body,
  });

  final Response response;
  final String rawBody;
  final Map<String, dynamic> body;
}

class _QueueAppAccessClient implements AppAccessDecisionClient {
  const _QueueAppAccessClient();

  @override
  Future<bool> checkAccess({
    required String fanId,
    required String appId,
    required String permissionId,
    required String groupId,
    required String correlationId,
  }) async => true;

  @override
  Future<bool> hasActiveMembership({
    required String fanId,
    required String appId,
    required String groupId,
    required String correlationId,
  }) async => true;

  @override
  Future<List<GroupMember>> listGroupMembers({
    required String appId,
    required String groupId,
    required String correlationId,
  }) async => const <GroupMember>[];

  @override
  Future<Set<String>> resolveRoleIds({
    required String fanId,
    required String appId,
    required String groupId,
    required String correlationId,
  }) async => switch (fanId) {
    _admin => const <String>{'queue-admin'},
    _memberOne || _memberTwo || _memberThree => const <String>{'queue-member'},
    _ => const <String>{},
  };
}
