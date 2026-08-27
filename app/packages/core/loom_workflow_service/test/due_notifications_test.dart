import 'dart:convert';

import 'package:loom_workflow_engine/loom_workflow_engine.dart';
import 'package:loom_workflow_service/loom_workflow_service.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

/// Reminders that have come due, served to the fan they belong to.
///
/// The scoping is the point. The engine's `dueNotifications` returns every
/// instance in the community carrying a past `dueAt` — correct for a device
/// holding one member's database, and a leak of everyone's reminders if that
/// list were returned over HTTP unchanged.
const _communityId = 'reminder-community';
const _groupId = 'loom_communities_reminder_community';
const _workflowType = 'club-notification';
const _correlationId = '44444444-4444-4444-8444-444444444444';

const _alice = 'fan-alice';
const _bob = 'fan-bob';

/// Modelled on the shipped notification workflows: guarded, readable only by
/// the fan named in `recipientFanId`.
const _definitionJson = '''
{
  "initialState": "unread",
  "visibility": {
    "default": "guarded",
    "readGuard": {"actorEqualsField": {"key": "recipientFanId"}},
    "fields": {"recipient": "recipientFanId"}
  },
  "states": {
    "unread": {"label": "Unread"},
    "read": {"label": "Read"}
  },
  "renderBindings": [
    {
      "states": ["unread", "read"],
      "audience": "any",
      "tabId": "home",
      "cardSurfaceFamily": "notificationInbox",
      "bindingKind": "primary",
      "actions": [
        {"kind": "create", "label": "Remind me", "scope": "tab",
         "presentation": "fab"}
      ]
    }
  ],
  "transitions": [
    {"id": "mark-read", "label": "Mark read", "from": ["unread"], "to": "read"}
  ],
  "instanceDataSchema": {
    "recipientFanId": {"type": "fanId", "required": true,
      "writableBy": "formEntry", "storage": "inline"},
    "title": {"type": "text", "writableBy": "formEntry", "storage": "inline"},
    "dueAt": {"type": "text", "writableBy": "formEntry", "storage": "inline"}
  }
}
''';

void main() {
  late WorkflowDatabase database;
  late WorkflowService service;

  setUp(() async {
    database = WorkflowDatabase.memory();
    service = WorkflowService(
      database: database,
      identityExtractor: const HeaderWorkflowIdentityExtractor(),
      appAccessClient: _EveryoneIsAMember(),
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

  test('a fan gets only their own due reminders', () async {
    await _seed(service, recipient: _alice, dueAt: '2026-01-01T09:00:00Z');
    await _seed(service, recipient: _bob, dueAt: '2026-01-01T09:00:00Z');

    final aliceTitles = await _dueFor(service, _alice);
    expect(aliceTitles, hasLength(1));
    final aliceData =
        aliceTitles.single['instanceData'] as Map<String, dynamic>;
    expect(aliceData['recipientFanId'], _alice);

    // The decisive assertion: both reminders are due, and Alice sees one.
    final bobTitles = await _dueFor(service, _bob);
    expect(bobTitles, hasLength(1));
    final bobData = bobTitles.single['instanceData'] as Map<String, dynamic>;
    expect(bobData['recipientFanId'], _bob);
  });

  test('a reminder that has not come due yet is withheld', () async {
    await _seed(service, recipient: _alice, dueAt: '2099-01-01T09:00:00Z');
    expect(await _dueFor(service, _alice), isEmpty);
  });

  test("asOf comes from the caller, so a backlog is delivered late", () async {
    await _seed(service, recipient: _alice, dueAt: '2026-06-01T09:00:00Z');

    // A device that was offline asks for everything up to now.
    expect(
      await _dueFor(service, _alice, asOf: '2026-05-01T00:00:00Z'),
      isEmpty,
      reason: 'not yet due at that instant',
    );
    expect(
      await _dueFor(service, _alice, asOf: '2026-07-01T00:00:00Z'),
      hasLength(1),
      reason: 'a reminder that came due while offline must still arrive',
    );
  });

  test('a malformed asOf is refused rather than silently defaulted', () async {
    final response = await service.handler(
      Request(
        'GET',
        Uri.parse(
          'http://localhost/v1/communities/$_communityId/notifications/due'
          '?asOf=not-a-timestamp',
        ),
        headers: _headers(_alice),
      ),
    );
    expect(response.statusCode, 400);
    final body = jsonDecode(await response.readAsString())
        as Map<String, dynamic>;
    expect(body['code'], 'invalid_as_of');
  });

  test('an unauthenticated request is refused', () async {
    final response = await service.handler(
      Request(
        'GET',
        Uri.parse(
          'http://localhost/v1/communities/$_communityId/notifications/due',
        ),
        headers: {'x-loom-correlation-id': _correlationId},
      ),
    );
    expect(response.statusCode, 401);
  });
}

Future<void> _seed(
  WorkflowService service, {
  required String recipient,
  required String dueAt,
}) async {
  final response = await service.handler(
    Request(
      'POST',
      Uri.parse('http://localhost/v1/communities/$_communityId/instances'),
      headers: _headers(recipient),
      body: jsonEncode({
        'workflowType': _workflowType,
        'instanceData': {
          'recipientFanId': recipient,
          'title': 'Meeting soon',
          'dueAt': dueAt,
        },
      }),
    ),
  );
  final raw = await response.readAsString();
  expect(response.statusCode, 201, reason: raw);
}

Future<List<Map<String, dynamic>>> _dueFor(
  WorkflowService service,
  String fanId, {
  String? asOf,
}) async {
  final query = asOf == null ? '' : '?asOf=$asOf';
  final response = await service.handler(
    Request(
      'GET',
      Uri.parse(
        'http://localhost/v1/communities/$_communityId/notifications/due$query',
      ),
      headers: _headers(fanId),
    ),
  );
  // Read once: shelf refuses a second read of the same body, and reading it
  // for the failure reason counts.
  final raw = await response.readAsString();
  expect(response.statusCode, 200, reason: raw);
  final body = jsonDecode(raw) as Map<String, dynamic>;
  return [
    for (final item in body['items'] as List<dynamic>)
      item as Map<String, dynamic>,
  ];
}

int _idempotency = 0;

Map<String, String> _headers(String fanId) => {
  'content-type': 'application/json',
  'x-loom-correlation-id': _correlationId,
  'idempotency-key': 'reminder-test-${_idempotency++}',
  HeaderWorkflowIdentityExtractor.defaultHeaderName: fanId,
};

/// Both fans are ordinary members holding no roles.
class _EveryoneIsAMember implements AppAccessDecisionClient {
  @override
  Future<bool> checkAccess({
    required String fanId,
    required String appId,
    required String permissionId,
    required String groupId,
    required String correlationId,
  }) async => true;

  @override
  Future<Set<String>> resolveRoleIds({
    required String fanId,
    required String appId,
    required String groupId,
    required String correlationId,
  }) async => const <String>{};

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
}
