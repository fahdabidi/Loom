import 'dart:convert';

import 'package:loom_workflow_engine/loom_workflow_engine.dart';
import 'package:loom_workflow_service/loom_workflow_service.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

/// `membersOnly` visibility, resolved server-side.
///
/// The engine's three visibility branches are creator, archetype share, and
/// `visibility.default`. The service had coverage for the first two and none
/// for the third, which is the branch most shipped workflows actually use.
const _communityId = 'members-only-community';
const _groupId = 'loom_communities_members_only';
const _workflowType = 'notice';
const _correlationId = '22222222-2222-4222-8222-222222222222';

/// A workflow whose instances every member may read, and nobody else.
///
/// No `readGuard` anywhere: that is the point. `membersOnly` is not a guard, it
/// is a question about membership, and answering it needs a membership lookup
/// rather than a role list.
const _definitionJson = '''
{
  "initialState": "posted",
  "visibility": {"default": "membersOnly"},
  "states": {
    "posted": {"label": "Posted"}
  },
  "transitions": [],
  "renderBindings": [
    {
      "states": ["posted"],
      "audience": "any",
      "tabId": "home",
      "cardSurfaceFamily": "formEntry",
      "bindingKind": "primary",
      "actions": [
        {
          "kind": "create",
          "label": "Post notice",
          "scope": "tab",
          "presentation": "fab"
        }
      ]
    }
  ],
  "instanceDataSchema": {
    "title": {
      "type": "text",
      "required": true,
      "writableBy": "formEntry",
      "storage": "inline"
    }
  }
}
''';

void main() {
  late WorkflowDatabase database;
  late WorkflowService service;
  late _MembershipAppAccessClient appAccessClient;

  setUp(() async {
    database = WorkflowDatabase.memory();
    appAccessClient = _MembershipAppAccessClient();
    service = WorkflowService(
      database: database,
      identityExtractor: const HeaderWorkflowIdentityExtractor(),
      appAccessClient: appAccessClient,
      communityGroupIdResolver: MapCommunityGroupIdResolver({
        _communityId: _groupId,
      }),
    );
    await database.upsertDefinition(
      definitionId: '${_communityId}_$_workflowType',
      workflowType: _workflowType,
      definitionJson: _definitionJson,
      version: 4,
    );
  });

  tearDown(() {
    database.close();
  });

  test('a member reads a membersOnly instance another member created', () async {
    appAccessClient.activeMembers.addAll({'fan-author', 'fan-reader'});

    final created = await service.handler(
      Request(
        'POST',
        Uri.parse('http://localhost/v1/communities/$_communityId/instances'),
        headers: _headers('fan-author'),
        body: jsonEncode({
          'workflowType': _workflowType,
          'instanceData': {'title': 'Pool closed Saturday'},
        }),
      ),
    );
    expect(created.statusCode, 201);

    // The author reads their own instance through the creator branch, which
    // needs no membership. Asserted first so a failure below cannot be blamed
    // on the instance never having been stored.
    expect(
      await _visibleInstanceIds(service, 'fan-author'),
      isNotEmpty,
      reason: 'the creator branch should admit the author',
    );

    // The reader is an active member of the group and created nothing. Only
    // the membersOnly branch can admit them.
    expect(
      await _visibleInstanceIds(service, 'fan-reader'),
      isNotEmpty,
      reason:
          'an active member must be able to read a membersOnly instance; if '
          'this is empty the service is resolving every fan as a non-member',
    );
  });

  test('a non-member cannot read a membersOnly instance', () async {
    appAccessClient.activeMembers.add('fan-author');

    final created = await service.handler(
      Request(
        'POST',
        Uri.parse('http://localhost/v1/communities/$_communityId/instances'),
        headers: _headers('fan-author'),
        body: jsonEncode({
          'workflowType': _workflowType,
          'instanceData': {'title': 'Board minutes'},
        }),
      ),
    );
    expect(created.statusCode, 201);

    // The other half of the same rule. Without this, wiring the lookup to
    // return true unconditionally would pass the test above and turn every
    // membersOnly workflow public.
    expect(await _visibleInstanceIds(service, 'fan-outsider'), isEmpty);
  });
}

Future<List<String>> _visibleInstanceIds(
  WorkflowService service,
  String fanId,
) async {
  final response = await service.handler(
    Request(
      'GET',
      Uri.parse(
        'http://localhost/v1/communities/$_communityId/instances'
        '?workflowType=$_workflowType',
      ),
      headers: _headers(fanId),
    ),
  );
  expect(response.statusCode, 200);
  final body = jsonDecode(await response.readAsString()) as Map<String, dynamic>;
  return (body['items'] as List<dynamic>)
      .map((instance) => (instance as Map<String, dynamic>)['instanceId'] as String)
      .toList();
}

Map<String, String> _headers(String fanId) => {
  'content-type': 'application/json',
  'x-loom-correlation-id': _correlationId,
  'idempotency-key': 'members-only-test-key',
  HeaderWorkflowIdentityExtractor.defaultHeaderName: fanId,
};

/// Answers role and membership questions from an explicit member set.
class _MembershipAppAccessClient implements AppAccessDecisionClient {
  @override
  Future<List<GroupMember>> listGroupMembers({
    required String appId,
    required String groupId,
    required String correlationId,
  }) async => [
    for (final fanId in activeMembers)
      GroupMember(fanId: fanId, roleIds: const {}, state: 'active'),
  ];
  final Set<String> activeMembers = <String>{};

  @override
  Future<bool> hasActiveMembership({
    required String fanId,
    required String appId,
    required String groupId,
    required String correlationId,
  }) async => activeMembers.contains(fanId);

  @override
  Future<bool> checkAccess({
    required String fanId,
    required String appId,
    required String permissionId,
    required String groupId,
    required String correlationId,
  }) async => activeMembers.contains(fanId);

  @override
  Future<Set<String>> resolveRoleIds({
    required String fanId,
    required String appId,
    required String groupId,
    required String correlationId,
  }) async =>
      // Deliberately empty even for members. A membersOnly workflow names no
      // role, so a service that inferred membership from a non-empty role set
      // would pass this test while still being wrong for a community whose
      // members hold no roles.
      const <String>{};
}
