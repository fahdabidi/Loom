import 'dart:convert';

import 'package:loom_workflow_engine/loom_workflow_engine.dart';
import 'package:loom_workflow_service/loom_workflow_service.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

const _communityId = 'permissions-unit';
const _workflowType = 'owner-approval';
const _correlationId = '22222222-2222-4222-8222-222222222222';
const _ownerFanId = 'fan-owner';
const _boardFanId = 'fan-board';

/// A `formEntry` workflow whose single transition is guarded on **both** a
/// role (the App Access layer) and an instance field (the engine layer). That
/// combination is exactly what lets one caller hold the permission and still
/// fail the guard, which is the case this whole report exists to narrate.
const _definitionJson = '''
{
  "initialState": "draft",
  "states": {
    "draft": {"label": "Draft"},
    "approved": {"label": "Approved"}
  },
  "transitions": [
    {
      "id": "approve",
      "label": "Approve",
      "from": ["draft"],
      "to": "approved",
      "guard": {
        "allowedRoleIds": ["hoa-board"],
        "actorEqualsField": {"key": "ownerFanId"}
      }
    }
  ],
  "renderBindings": [
    {
      "states": ["draft"],
      "audience": "any",
      "tabId": "admin",
      "cardSurfaceFamily": "formEntry",
      "bindingKind": "primary"
    }
  ],
  "instanceDataSchema": {
    "ownerFanId": {"type": "text", "required": true, "writableBy": "formEntry"},
    "decision": {"type": "text", "writableBy": "effect"}
  }
}
''';

void main() {
  late WorkflowDatabase database;
  late WorkflowService service;
  late _RecordingAppAccessClient appAccessClient;

  /// `createInstance` mints the engine-native id, so the seeded instance's real
  /// id is captured here rather than asserted against a literal.
  late String instanceId;

  setUp(() async {
    database = WorkflowDatabase.memory();
    appAccessClient = _RecordingAppAccessClient();
    service = WorkflowService(
      database: database,
      identityExtractor: const HeaderWorkflowIdentityExtractor(),
      appAccessClient: appAccessClient,
      communityGroupIdResolver: MapCommunityGroupIdResolver({
        _communityId: 'loom_communities_permissions_unit',
      }),
    );
    await _installDefinition(database);
    instanceId = await _seedInstance(database);
  });

  tearDown(() {
    database.close();
  });

  Request reportRequest({
    String fanId = _boardFanId,
    String correlationId = _correlationId,
    String? instanceIdOverride,
  }) => Request(
    'GET',
    Uri.parse(
      'http://localhost/v1/communities/$_communityId/instances/'
      '${instanceIdOverride ?? instanceId}/required-permissions',
    ),
    headers: {
      'x-loom-correlation-id': correlationId,
      HeaderWorkflowIdentityExtractor.defaultHeaderName: fanId,
    },
  );

  test('reports the caller roles, state and each transition requirement', () async {
    appAccessClient.allowed = true;
    appAccessClient.roleIds = const {'hoa-board'};

    final response = await service.handler(reportRequest());

    expect(response.statusCode, 200);
    final body = jsonDecode(await response.readAsString()) as Map<String, dynamic>;
    expect(body['instanceId'], instanceId);
    expect(body['workflowType'], _workflowType);
    expect(body['currentState'], 'draft');
    expect(body['roles'], <String>['hoa-board']);

    final transitions = body['transitions'] as List<dynamic>;
    expect(transitions, hasLength(1));
    final transition = transitions.single as Map<String, dynamic>;
    expect(transition['transitionId'], 'approve');
    expect(transition['requiredPermissionId'], 'form_entry.advance');
    expect(transition['toState'], 'approved');
  });

  test(
    'names `app_access_permission` when the role does not hold the permission',
    () async {
      // The caller's role resolves, but App Access says the permission is not
      // held, and the engine guard therefore cannot pass either.
      appAccessClient.allowed = false;
      appAccessClient.roleIds = const {'hoa-board'};

      final response = await service.handler(reportRequest());

      expect(response.statusCode, 200);
      final body = jsonDecode(await response.readAsString()) as Map<String, dynamic>;
      final transition =
          (body['transitions'] as List<dynamic>).single as Map<String, dynamic>;
      expect(transition['available'], isFalse);
      expect(transition['blockedBy'], 'app_access_permission');
    },
  );

  test(
    'a caller who HOLDS the permission but fails the guard is named '
    '`engine_guard`, not denied',
    () async {
      // The load-bearing case. `fan-board` holds `hoa-board` and App Access
      // grants `form_entry.advance`, but the transition also carries
      // `actorEqualsField: ownerFanId` and this fan is not that actor. The
      // report must say the ENGINE GUARD blocked it -- collapsing the two
      // layers into a bare "denied" is exactly what this endpoint exists to
      // prevent.
      appAccessClient.allowed = true;
      appAccessClient.roleIds = const {'hoa-board'};

      final response = await service.handler(reportRequest(fanId: _boardFanId));

      expect(response.statusCode, 200);
      final body = jsonDecode(await response.readAsString()) as Map<String, dynamic>;
      final transition =
          (body['transitions'] as List<dynamic>).single as Map<String, dynamic>;

      expect(
        transition['requiredPermissionId'],
        'form_entry.advance',
        reason: 'the permission the action class requires is reported',
      );
      expect(
        transition['available'],
        isFalse,
        reason: 'the engine guard refuses this actor on this row',
      );
      expect(
        transition['blockedBy'],
        'engine_guard',
        reason:
            'the caller holds the permission, so the permission layer is not '
            'the blocker; the per-instance guard is',
      );
      // The permission layer must NOT be blamed: App Access said yes.
      expect(transition['blockedBy'], isNot('app_access_permission'));
    },
  );

  test('the named actor sees the transition available', () async {
    appAccessClient.allowed = true;
    appAccessClient.roleIds = const {'hoa-board'};

    final response = await service.handler(reportRequest(fanId: _ownerFanId));

    expect(response.statusCode, 200);
    final body = jsonDecode(await response.readAsString()) as Map<String, dynamic>;
    final transition =
        (body['transitions'] as List<dynamic>).single as Map<String, dynamic>;
    expect(transition['available'], isTrue);
    expect(transition['blockedBy'], isNull);
  });

  test('an unreadable instance reports 404 and leaks nothing', () async {
    // Visibility is `guarded` on nothing here, so the row is readable -- use a
    // different instance id to prove the 404 path discloses no state.
    appAccessClient.allowed = true;
    appAccessClient.roleIds = const {'hoa-board'};

    final response = await service.handler(
      reportRequest(instanceIdOverride: 'no-such-instance'),
    );

    expect(response.statusCode, 404);
    final body = jsonDecode(await response.readAsString()) as Map<String, dynamic>;
    expect(body['code'], 'workflow_instance_not_found');
    expect(
      body.toString(),
      isNot(contains('draft')),
      reason: 'a missing instance must not disclose the state it might hold',
    );
  });

  test('a non-UUID correlation id is refused with 400', () async {
    final response = await service.handler(
      reportRequest(correlationId: 'not-a-uuid'),
    );

    expect(response.statusCode, 400);
    final body = jsonDecode(await response.readAsString()) as Map<String, dynamic>;
    expect(body['code'], 'invalid_correlation_id');
  });

  test('an unauthenticated caller is refused with 401', () async {
    final response = await service.handler(
      Request(
        'GET',
        Uri.parse(
          'http://localhost/v1/communities/$_communityId/instances/'
          '$instanceId/required-permissions',
        ),
        headers: const {'x-loom-correlation-id': _correlationId},
      ),
    );

    expect(response.statusCode, 401);
  });

  test('the report is read-only: it never mutates the instance', () async {
    appAccessClient.allowed = true;
    appAccessClient.roleIds = const {'hoa-board'};

    final before = await database.readInstance(instanceId);
    await service.handler(reportRequest());
    final after = await database.readInstance(instanceId);

    expect(after!.currentState, before!.currentState);
    expect(after.instanceData, before.instanceData);
    expect(after.updatedAt, before.updatedAt);
  });
}

Future<void> _installDefinition(WorkflowDatabase database) async {
  await database.upsertDefinition(
    definitionId: '${_communityId}_$_workflowType',
    workflowType: _workflowType,
    definitionJson: _definitionJson,
    version: currentCommunitySpecVersion,
  );
}

Future<String> _seedInstance(WorkflowDatabase database) async {
  final engine = LocalWorkflowEngineApi(
    db: database,
    communityId: _communityId,
  )..registerDefinition(
    LoomWorkflowStateMachine.fromJson(
      jsonDecode(_definitionJson) as Map<String, dynamic>,
      _workflowType,
    ),
  );
  return engine.createInstance(
    workflowType: _workflowType,
    initialInstanceData: const {'ownerFanId': _ownerFanId},
    fanId: _ownerFanId,
  );
}

class _RecordingAppAccessClient implements AppAccessDecisionClient {
  bool allowed = true;
  bool activeMembership = true;
  Set<String> roleIds = const {};
  int checkAccessCallCount = 0;
  final List<String> requestedPermissionIds = <String>[];

  @override
  Future<bool> checkAccess({
    required String fanId,
    required String appId,
    required String permissionId,
    required String groupId,
    required String correlationId,
  }) async {
    checkAccessCallCount += 1;
    requestedPermissionIds.add(permissionId);
    return allowed;
  }

  @override
  Future<bool> hasActiveMembership({
    required String fanId,
    required String appId,
    required String groupId,
    required String correlationId,
  }) async => activeMembership;

  @override
  Future<Set<String>> resolveRoleIds({
    required String fanId,
    required String appId,
    required String groupId,
    required String correlationId,
  }) async => roleIds;

  @override
  Future<List<GroupMember>> listGroupMembers({
    required String appId,
    required String groupId,
    required String correlationId,
  }) async => const <GroupMember>[];
}
