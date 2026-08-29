import 'dart:convert';

import 'package:loom_workflow_engine/loom_workflow_engine.dart';
import 'package:loom_workflow_service/loom_workflow_service.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

const _communityId = 'visible-changes-community';
const _groupId = 'loom_communities_visible_changes';
const _publicWorkflowType = 'public-notice';
const _guardedWorkflowType = 'board-notice';
const _correlationId = '33333333-3333-4333-8333-333333333333';

void main() {
  late WorkflowDatabase database;
  late WorkflowService service;
  late _ChangesAppAccessClient appAccessClient;

  setUp(() async {
    database = WorkflowDatabase.memory();
    appAccessClient = _ChangesAppAccessClient();
    service = WorkflowService(
      database: database,
      identityExtractor: const HeaderWorkflowIdentityExtractor(),
      appAccessClient: appAccessClient,
      communityGroupIdResolver: MapCommunityGroupIdResolver({
        _communityId: _groupId,
      }),
    );
    await _installDefinitions(database);
  });

  tearDown(() {
    database.close();
  });

  test(
    'members at the same cursor receive their own visible changes',
    () async {
      appAccessClient.activeMembers.addAll({'fan-board', 'fan-member'});
      appAccessClient.rolesByFan['fan-board'] = {'board-role'};
      await _insertInstance(
        database,
        instanceId: 'public-change',
        workflowType: _publicWorkflowType,
        updatedAt: 1000,
      );
      await _insertInstance(
        database,
        instanceId: 'board-change',
        workflowType: _guardedWorkflowType,
        updatedAt: 1000,
      );

      final board = await _responseBody(
        await service.handler(
          _changesRequest(
            fanId: 'fan-board',
            updatedSince: 1000,
            afterInstanceId: '',
          ),
        ),
      );
      final member = await _responseBody(
        await service.handler(
          _changesRequest(
            fanId: 'fan-member',
            updatedSince: 1000,
            afterInstanceId: '',
          ),
        ),
      );

      expect(
        _changedIds(board),
        unorderedEquals(['public-change', 'board-change']),
      );
      expect(_changedIds(member), ['public-change']);
      expect(
        _visibleIds(board),
        unorderedEquals(['public-change', 'board-change']),
      );
      expect(_visibleIds(member), ['public-change']);
    },
  );

  test('the updatedSince boundary is inclusive', () async {
    appAccessClient.activeMembers.add('fan-member');
    await _insertInstance(
      database,
      instanceId: 'boundary-instance',
      workflowType: _publicWorkflowType,
      updatedAt: 2000,
    );

    final body = await _responseBody(
      await service.handler(
        _changesRequest(
          fanId: 'fan-member',
          updatedSince: 2000,
          afterInstanceId: '',
        ),
      ),
    );

    expect(_changedIds(body), ['boundary-instance']);
    expect(body['nextUpdatedSince'], 2000);
    // A resumed request without a role binding must force a safe resync.
    expect(body['resyncRequired'], isTrue);
  });

  test(
    'a changed instance the caller cannot read is absent from both sets',
    () async {
      appAccessClient.activeMembers.add('fan-member');
      await _insertInstance(
        database,
        instanceId: 'hidden-change',
        workflowType: _guardedWorkflowType,
        createdByFanId: 'fan-author',
        updatedAt: 3000,
      );

      final body = await _responseBody(
        await service.handler(
          _changesRequest(
            fanId: 'fan-member',
            updatedSince: 3000,
            afterInstanceId: '',
          ),
        ),
      );

      expect(_changedIds(body), isEmpty);
      expect(_visibleIds(body), isEmpty);
      expect(body['nextAfterInstanceId'], '');
    },
  );

  test(
    'a visible unchanged instance remains in the complete visible id set',
    () async {
      appAccessClient.activeMembers.add('fan-member');
      await _insertInstance(
        database,
        instanceId: 'unchanged-visible',
        workflowType: _publicWorkflowType,
        updatedAt: 4000,
      );

      final body = await _responseBody(
        await service.handler(
          _changesRequest(
            fanId: 'fan-member',
            updatedSince: 4001,
            afterInstanceId: '',
          ),
        ),
      );

      expect(_changedIds(body), isEmpty);
      expect(_visibleIds(body), ['unchanged-visible']);
      expect(body['nextUpdatedSince'], 4001);
      expect(body['nextAfterInstanceId'], '');
    },
  );

  test(
    'a changed caller role marks the prior cursor as requiring resync',
    () async {
      appAccessClient.activeMembers.add('fan-board');
      appAccessClient.rolesByFan['fan-board'] = {'board-role'};
      await _insertInstance(
        database,
        instanceId: 'role-visible',
        workflowType: _guardedWorkflowType,
        updatedAt: 5000,
      );

      final initial = await _responseBody(
        await service.handler(_changesRequest(fanId: 'fan-board')),
      );
      final priorRoleCursor = initial['nextRoleCursor'] as String;
      expect(priorRoleCursor, matches(RegExp(r'^[0-9a-f]{64}$')));
      expect(priorRoleCursor, isNot(contains('board-role')));
      expect(initial['resyncRequired'], isFalse);

      appAccessClient.rolesByFan['fan-board'] = <String>{};
      final resumed = await _responseBody(
        await service.handler(
          _changesRequest(
            fanId: 'fan-board',
            updatedSince: initial['nextUpdatedSince'] as int,
            afterInstanceId: initial['nextAfterInstanceId'] as String,
            roleCursor: priorRoleCursor,
          ),
        ),
      );

      expect(resumed['resyncRequired'], isTrue);
      expect(resumed['nextRoleCursor'], isNot(priorRoleCursor));
    },
  );

  test('no updatedSince returns a full visible sync', () async {
    appAccessClient.activeMembers.add('fan-board');
    appAccessClient.rolesByFan['fan-board'] = {'board-role'};
    await _insertInstance(
      database,
      instanceId: 'full-public',
      workflowType: _publicWorkflowType,
      updatedAt: 6000,
    );
    await _insertInstance(
      database,
      instanceId: 'full-board',
      workflowType: _guardedWorkflowType,
      updatedAt: 6001,
    );

    final body = await _responseBody(
      await service.handler(_changesRequest(fanId: 'fan-board')),
    );

    expect(_changedIds(body), ['full-public', 'full-board']);
    expect(_visibleIds(body), unorderedEquals(['full-public', 'full-board']));
    expect(body['nextUpdatedSince'], 6001);
    expect(body['nextAfterInstanceId'], 'full-board');
    expect(body['hasMore'], isFalse);
    expect(body['resyncRequired'], isFalse);
  });

  test('visible ids remain complete while changed results are paged', () async {
    appAccessClient.activeMembers.add('fan-member');
    await _insertInstance(
      database,
      instanceId: 'first-page',
      workflowType: _publicWorkflowType,
      updatedAt: 7000,
    );
    await _insertInstance(
      database,
      instanceId: 'boundary-repeat',
      workflowType: _publicWorkflowType,
      updatedAt: 7001,
    );
    await _insertInstance(
      database,
      instanceId: 'second-page',
      workflowType: _publicWorkflowType,
      updatedAt: 7002,
    );

    final first = await _responseBody(
      await service.handler(_changesRequest(fanId: 'fan-member', limit: 2)),
    );
    expect(_changedIds(first), ['first-page', 'boundary-repeat']);
    expect(_visibleIds(first), hasLength(3));
    expect(first['hasMore'], isTrue);
    expect(first['nextUpdatedSince'], 7001);
    expect(first['nextAfterInstanceId'], 'boundary-repeat');

    final second = await _responseBody(
      await service.handler(
        _changesRequest(
          fanId: 'fan-member',
          updatedSince: first['nextUpdatedSince'] as int,
          afterInstanceId: first['nextAfterInstanceId'] as String,
          roleCursor: first['nextRoleCursor'] as String,
          limit: 2,
        ),
      ),
    );
    expect(_changedIds(second), ['second-page']);
    expect(_visibleIds(second), hasLength(3));
    expect(second['hasMore'], isFalse);
  });

  test(
    'more same-millisecond rows than fit in a page progress without repeats',
    () async {
      appAccessClient.activeMembers.add('fan-member');
      for (final instanceId in ['same-a', 'same-b', 'same-c', 'same-d']) {
        await _insertInstance(
          database,
          instanceId: instanceId,
          workflowType: _publicWorkflowType,
          updatedAt: 8000,
        );
      }

      final first = await _responseBody(
        await service.handler(_changesRequest(fanId: 'fan-member', limit: 2)),
      );
      expect(_changedIds(first), ['same-a', 'same-b']);
      expect(first['nextUpdatedSince'], 8000);
      expect(first['nextAfterInstanceId'], 'same-b');
      expect(first['hasMore'], isTrue);

      final second = await _responseBody(
        await service.handler(
          _changesRequest(
            fanId: 'fan-member',
            updatedSince: first['nextUpdatedSince'] as int,
            afterInstanceId: first['nextAfterInstanceId'] as String,
            roleCursor: first['nextRoleCursor'] as String,
            limit: 2,
          ),
        ),
      );
      expect(_changedIds(second), ['same-c', 'same-d']);
      expect(second['nextUpdatedSince'], 8000);
      expect(second['nextAfterInstanceId'], 'same-d');
      expect(second['hasMore'], isFalse);
      expect(
        [..._changedIds(first), ..._changedIds(second)],
        ['same-a', 'same-b', 'same-c', 'same-d'],
      );
    },
  );

  test('a half timestamp cursor is rejected', () async {
    appAccessClient.activeMembers.add('fan-member');

    final onlyTimestamp = await service.handler(
      _changesRequest(fanId: 'fan-member', updatedSince: 9000),
    );
    final onlyInstanceId = await service.handler(
      _changesRequest(fanId: 'fan-member', afterInstanceId: 'same-a'),
    );

    expect(onlyTimestamp.statusCode, 400);
    expect(onlyInstanceId.statusCode, 400);
  });

  test(
    'missing correlation id is rejected and a non-member is forbidden',
    () async {
      final missingCorrelation = await service.handler(
        Request(
          'GET',
          Uri.parse('http://localhost/v1/communities/$_communityId/changes'),
          headers: {
            HeaderWorkflowIdentityExtractor.defaultHeaderName: 'fan-member',
          },
        ),
      );
      expect(missingCorrelation.statusCode, 400);

      final nonMember = await service.handler(
        _changesRequest(fanId: 'fan-outsider'),
      );
      expect(nonMember.statusCode, 403);
    },
  );
}

Future<void> _installDefinitions(WorkflowDatabase database) async {
  await database.upsertDefinition(
    definitionId: '${_communityId}_$_publicWorkflowType',
    workflowType: _publicWorkflowType,
    definitionJson: jsonEncode(_definition(visibility: {'default': 'public'})),
    version: 4,
  );
  await database.upsertDefinition(
    definitionId: '${_communityId}_$_guardedWorkflowType',
    workflowType: _guardedWorkflowType,
    definitionJson: jsonEncode(
      _definition(
        visibility: {
          'default': 'guarded',
          'readGuard': {
            'allowedRoleIds': ['board-role'],
          },
        },
      ),
    ),
    version: 4,
  );
}

Map<String, dynamic> _definition({required Map<String, dynamic> visibility}) =>
    {
      'initialState': 'published',
      'visibility': visibility,
      'states': {
        'published': {'label': 'Published'},
      },
      'transitions': <Map<String, dynamic>>[],
      'instanceDataSchema': {
        'title': {
          'type': 'text',
          'required': true,
          'writableBy': 'formEntry',
          'storage': 'inline',
        },
      },
    };

Future<void> _insertInstance(
  WorkflowDatabase database, {
  required String instanceId,
  required String workflowType,
  required int updatedAt,
  String createdByFanId = 'fan-author',
}) async {
  await database.insertInstance(
    instanceId: instanceId,
    communityId: _communityId,
    workflowType: workflowType,
    currentState: 'published',
    instanceData: {'title': instanceId},
    createdByFanId: createdByFanId,
  );
  await database.execute(
    'UPDATE workflow_instances SET updated_at = $updatedAt '
    "WHERE instance_id = '$instanceId'",
  );
}

Request _changesRequest({
  required String fanId,
  int? updatedSince,
  String? afterInstanceId,
  String? roleCursor,
  int? limit,
}) => Request(
  'GET',
  Uri(
    scheme: 'http',
    host: 'localhost',
    path: '/v1/communities/$_communityId/changes',
    queryParameters: {
      if (updatedSince != null) 'updatedSince': '$updatedSince',
      if (afterInstanceId != null) 'afterInstanceId': afterInstanceId,
      if (roleCursor != null) 'roleCursor': roleCursor,
      if (limit != null) 'limit': '$limit',
    },
  ),
  headers: {
    'x-loom-correlation-id': _correlationId,
    HeaderWorkflowIdentityExtractor.defaultHeaderName: fanId,
  },
);

Future<Map<String, dynamic>> _responseBody(Response response) async {
  expect(response.statusCode, 200);
  return jsonDecode(await response.readAsString()) as Map<String, dynamic>;
}

List<String> _changedIds(Map<String, dynamic> body) =>
    (body['changed'] as List<dynamic>)
        .map(
          (instance) =>
              (instance as Map<String, dynamic>)['instanceId'] as String,
        )
        .toList();

List<String> _visibleIds(Map<String, dynamic> body) =>
    (body['visibleInstanceIds'] as List<dynamic>).cast<String>();

class _ChangesAppAccessClient implements AppAccessDecisionClient {
  final Set<String> activeMembers = <String>{};
  final Map<String, Set<String>> rolesByFan = <String, Set<String>>{};

  @override
  Future<bool> checkAccess({
    required String fanId,
    required String appId,
    required String permissionId,
    required String groupId,
    required String correlationId,
  }) async => activeMembers.contains(fanId);

  @override
  Future<bool> hasActiveMembership({
    required String fanId,
    required String appId,
    required String groupId,
    required String correlationId,
  }) async => activeMembers.contains(fanId);

  @override
  Future<List<GroupMember>> listGroupMembers({
    required String appId,
    required String groupId,
    required String correlationId,
  }) async => [
    for (final fanId in activeMembers)
      GroupMember(
        fanId: fanId,
        roleIds: rolesByFan[fanId] ?? const <String>{},
        state: 'active',
      ),
  ];

  @override
  Future<Set<String>> resolveRoleIds({
    required String fanId,
    required String appId,
    required String groupId,
    required String correlationId,
  }) async => rolesByFan[fanId] ?? const <String>{};
}
