import 'dart:convert';

import 'package:loom_workflow_engine/loom_workflow_engine.dart';
import 'package:loom_workflow_service/loom_workflow_service.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

/// The document library's access rules, exercised end to end through HTTP.
///
/// Modelled on Cedar Commons HOA's document policy, because that is the one the
/// archetype documents and the one the reader sets actually differ under: the
/// board may write and read everything, members may read only what is
/// published, and publishing is what moves a document between those two worlds.
const _communityId = 'cedar-commons-hoa';
const _groupId = 'loom_communities_cedar-commons-hoa';
const _workflowType = 'hoa-member-document';
const _correlationId = '33333333-3333-4333-8333-333333333333';

const _boardFan = 'fan-board';
const _memberFan = 'fan-member';
const _outsiderFan = 'fan-outsider';

/// Drafts are board-only; published widens to every member.
///
/// `guarded` rather than the `membersOnly` that shipped Cedar declares. Under
/// `membersOnly` the engine never reaches a per-state `readGuard` at all, so a
/// fixture copied from the shipped package would test nothing about state-level
/// narrowing. That divergence is a real defect in its own right and is filed as
/// one; encoding it here would only hide it.
const _definitionJson = '''
{
  "initialState": "draft",
  "visibility": {
    "default": "guarded",
    "readGuard": {"allowedRoleIds": ["hoa-member"]}
  },
  "states": {
    "draft": {"label": "Draft", "readGuard": {"allowedRoleIds": ["hoa-board"]}},
    "published": {"label": "Published"}
  },
  "renderBindings": [
    {
      "states": ["draft"],
      "audience": "any",
      "tabId": "home",
      "cardSurfaceFamily": "documentLibrary",
      "bindingKind": "primary",
      "actions": [
        {"kind": "create", "label": "Add document", "scope": "tab",
         "presentation": "fab"}
      ]
    }
  ],
  "transitions": [
    {"id": "upload-document", "label": "Upload", "action": "upload",
     "from": ["draft"], "to": null,
     "guard": {"allowedRoleIds": ["hoa-board"]}},
    {"id": "publish-document", "label": "Publish", "action": "publish",
     "from": ["draft"], "to": "published",
     "guard": {"allowedRoleIds": ["hoa-board"]}},
    {"id": "delete-document", "label": "Delete", "action": "delete",
     "from": ["draft"], "to": null,
     "guard": {"allowedRoleIds": ["hoa-board"]}}
  ],
  "instanceDataSchema": {
    "attachmentUrl": {
      "type": "text",
      "writableBy": "formEntry",
      "storage": "inline"
    }
  }
}
''';

void main() {
  late WorkflowDatabase database;
  late WorkflowService service;
  late _CedarAppAccessClient appAccessClient;
  late InMemoryDocumentRepository repository;
  late InMemoryDocumentObjectStore objectStore;

  setUp(() async {
    database = WorkflowDatabase.memory();
    appAccessClient = _CedarAppAccessClient();
    repository = InMemoryDocumentRepository();
    objectStore = InMemoryDocumentObjectStore();
    service = WorkflowService(
      database: database,
      identityExtractor: const HeaderWorkflowIdentityExtractor(),
      appAccessClient: appAccessClient,
      communityGroupIdResolver: MapCommunityGroupIdResolver({
        _communityId: _groupId,
      }),
      documentRepository: repository,
      documentObjectStore: objectStore,
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

  test('the board uploads a document and its bytes reach the store', () async {
    final instanceId = await _createInstance(service, _boardFan);

    final response = await _upload(service, _boardFan, instanceId);
    expect(response.statusCode, 201);

    final body = jsonDecode(await response.readAsString())
        as Map<String, dynamic>;
    expect(body['fieldName'], 'attachmentUrl');
    expect(body['ownerFanId'], _boardFan);
    expect(body['byteSize'], _fileBytes.length);
    expect(body['contentUrl'], contains(body['documentId']));

    // The bytes are in storage, under a key built from ids rather than from
    // the member-chosen filename.
    expect(objectStore.objects, hasLength(1));
    final key = objectStore.objects.keys.single;
    expect(key, contains(instanceId));
    expect(key, isNot(contains('minutes')));
    expect(objectStore.objects[key], _fileBytes);
  });

  test('a member without an upload transition is refused', () async {
    final instanceId = await _createInstance(service, _boardFan);

    final response = await _upload(service, _memberFan, instanceId);

    // 404 rather than 403: a draft is board-only, so the member cannot see the
    // instance at all and must not learn that it exists.
    expect(response.statusCode, 404);
    expect(objectStore.objects, isEmpty);
  });

  test('an upload names a field the workflow declares', () async {
    final instanceId = await _createInstance(service, _boardFan);

    final response = await _upload(
      service,
      _boardFan,
      instanceId,
      fieldName: 'notADeclaredField',
    );

    expect(response.statusCode, 400);
    final body = jsonDecode(await response.readAsString())
        as Map<String, dynamic>;
    expect(body['code'], 'unknown_document_field');
    expect(objectStore.objects, isEmpty);
  });

  test('publishing changes who may read the same document', () async {
    final instanceId = await _createInstance(service, _boardFan);
    final documentId = await _uploadAndReadId(service, instanceId);

    // While the document is a draft, only the board may read it.
    expect(
      (await _getDocument(service, _memberFan, documentId)).statusCode,
      404,
    );
    expect(
      (await _getDocument(service, _boardFan, documentId)).statusCode,
      200,
    );

    await _publish(service, instanceId);

    // The same document, the same request, a different answer -- which is the
    // whole reason access is resolved per request rather than at upload.
    expect(
      (await _getDocument(service, _memberFan, documentId)).statusCode,
      200,
    );
    expect(
      (await _getDocument(service, _outsiderFan, documentId)).statusCode,
      404,
    );
  });

  test('downloading returns the bytes as an attachment', () async {
    final instanceId = await _createInstance(service, _boardFan);
    final documentId = await _uploadAndReadId(service, instanceId);

    final response = await service.handler(
      Request(
        'GET',
        Uri.parse(
          'http://localhost/v1/communities/$_communityId/documents/'
          '$documentId/content',
        ),
        headers: _headers(_boardFan),
      ),
    );

    expect(response.statusCode, 200);
    expect(await response.read().expand((chunk) => chunk).toList(), _fileBytes);
    // Never inline: these bytes came from a member.
    expect(response.headers['content-disposition'], startsWith('attachment'));
  });

  test('access reports the resolved reader set and why', () async {
    final instanceId = await _createInstance(service, _boardFan);
    final documentId = await _uploadAndReadId(service, instanceId);
    await _publish(service, instanceId);

    final response = await service.handler(
      Request(
        'GET',
        Uri.parse(
          'http://localhost/v1/communities/$_communityId/documents/'
          '$documentId/access',
        ),
        headers: _headers(_boardFan),
      ),
    );
    expect(response.statusCode, 200);
    final body = jsonDecode(await response.readAsString())
        as Map<String, dynamic>;

    expect(body['instanceState'], 'published');
    expect(body['readFanIds'], containsAll(<String>[_boardFan, _memberFan]));
    expect(body['readFanIds'], isNot(contains(_outsiderFan)));

    final derivation = body['derivation'] as Map<String, dynamic>;
    expect((derivation['byDefault'] as Map)['model'], 'guarded');
    // The published state declares no readGuard, so the workflow's applies.
    expect((derivation['byDefault'] as Map)['guardState'], 'workflow');
    final byRole = (derivation['byDefault'] as Map)['byRole'] as List<dynamic>;
    final memberRole = byRole.firstWhere(
      (entry) => (entry as Map)['roleId'] == 'hoa-member',
    ) as Map<String, dynamic>;
    expect(memberRole['fanIds'], containsAll(<String>[_boardFan, _memberFan]));
    expect(derivation['byOwner'], [_boardFan]);

    // Empty, and correctly so: upload and delete are declared from the draft
    // state, so publishing ends the window in which anyone may write. Writers
    // are a property of the current state, not of the document.
    expect(body['writeFanIds'], isEmpty);
  });

  test('access reports the board as a writer while the document is a draft',
      () async {
    final instanceId = await _createInstance(service, _boardFan);
    final documentId = await _uploadAndReadId(service, instanceId);

    final response = await service.handler(
      Request(
        'GET',
        Uri.parse(
          'http://localhost/v1/communities/$_communityId/documents/'
          '$documentId/access',
        ),
        headers: _headers(_boardFan),
      ),
    );
    expect(response.statusCode, 200);
    final body = jsonDecode(await response.readAsString())
        as Map<String, dynamic>;

    expect(body['instanceState'], 'draft');
    // The board may upload and delete here, so they are a writer.
    expect(body['writeFanIds'], [_boardFan]);
    // And the member cannot read a draft, so they are not a reader -- the
    // state readGuard narrowing the workflow guard.
    expect(body['readFanIds'], [_boardFan]);
    final byDefault =
        (body['derivation'] as Map<String, dynamic>)['byDefault']
            as Map<String, dynamic>;
    expect(byDefault['guardState'], 'state');
  });

  test('a deployment without storage answers 503 rather than failing', () async {
    final storageless = WorkflowService(
      database: database,
      identityExtractor: const HeaderWorkflowIdentityExtractor(),
      appAccessClient: appAccessClient,
      communityGroupIdResolver: MapCommunityGroupIdResolver({
        _communityId: _groupId,
      }),
    );

    final response = await storageless.handler(
      Request(
        'GET',
        Uri.parse(
          'http://localhost/v1/communities/$_communityId/documents/doc_x',
        ),
        headers: _headers(_boardFan),
      ),
    );

    expect(response.statusCode, 503);
    final body = jsonDecode(await response.readAsString())
        as Map<String, dynamic>;
    expect(body['code'], 'document_storage_unavailable');
  });
}

const _fileBytes = <int>[37, 80, 68, 70, 45, 49, 46, 55, 10, 255, 0, 17];
const _boundary = 'loomtestboundary';

Future<String> _createInstance(WorkflowService service, String fanId) async {
  final response = await service.handler(
    Request(
      'POST',
      Uri.parse('http://localhost/v1/communities/$_communityId/instances'),
      headers: _headers(fanId),
      body: jsonEncode({
        'workflowType': _workflowType,
        'instanceData': <String, dynamic>{},
      }),
    ),
  );
  final raw = await response.readAsString();
  expect(response.statusCode, 201, reason: raw);
  final body = jsonDecode(raw) as Map<String, dynamic>;
  return body['instanceId'] as String;
}

Future<Response> _upload(
  WorkflowService service,
  String fanId,
  String instanceId, {
  String fieldName = 'attachmentUrl',
}) async {
  final head = StringBuffer()
    ..write('--$_boundary\r\n')
    ..write(
      'content-disposition: form-data; name="file"; '
      'filename="board-minutes.pdf"\r\n',
    )
    ..write('content-type: application/pdf\r\n\r\n');
  final tail = StringBuffer()
    ..write('\r\n--$_boundary\r\n')
    ..write('content-disposition: form-data; name="fieldName"\r\n\r\n')
    ..write(fieldName)
    ..write('\r\n--$_boundary--\r\n');

  return service.handler(
    Request(
      'POST',
      Uri.parse(
        'http://localhost/v1/communities/$_communityId/instances/'
        '$instanceId/documents',
      ),
      headers: {
        ..._headers(fanId),
        'content-type': 'multipart/form-data; boundary=$_boundary',
      },
      body: <int>[
        ...utf8.encode(head.toString()),
        ..._fileBytes,
        ...utf8.encode(tail.toString()),
      ],
    ),
  );
}

Future<String> _uploadAndReadId(
  WorkflowService service,
  String instanceId,
) async {
  final response = await _upload(service, _boardFan, instanceId);
  expect(response.statusCode, 201);
  final body = jsonDecode(await response.readAsString())
      as Map<String, dynamic>;
  return body['documentId'] as String;
}

Future<void> _publish(WorkflowService service, String instanceId) async {
  final response = await service.handler(
    Request(
      'POST',
      Uri.parse(
        'http://localhost/v1/communities/$_communityId/instances/'
        '$instanceId/transitions',
      ),
      headers: _headers(_boardFan),
      body: jsonEncode({'transitionId': 'publish-document'}),
    ),
  );
  expect(response.statusCode, 200, reason: await response.readAsString());
}

Future<Response> _getDocument(
  WorkflowService service,
  String fanId,
  String documentId,
) async => service.handler(
  Request(
    'GET',
    Uri.parse(
      'http://localhost/v1/communities/$_communityId/documents/$documentId',
    ),
    headers: _headers(fanId),
  ),
);

/// Unique per request on purpose.
///
/// A shared key would make the second upload in a test return the first
/// document, so the tests would pass while proving the opposite of what they
/// claim.
int _idempotencySequence = 0;

Map<String, String> _headers(String fanId) => {
  'content-type': 'application/json',
  'x-loom-correlation-id': _correlationId,
  'idempotency-key': 'document-test-${_idempotencySequence++}',
  HeaderWorkflowIdentityExtractor.defaultHeaderName: fanId,
};

/// Cedar's group: a board member, an ordinary member, and someone outside it.
class _CedarAppAccessClient implements AppAccessDecisionClient {
  static const _roles = <String, Set<String>>{
    _boardFan: {'hoa-board', 'hoa-member'},
    _memberFan: {'hoa-member'},
  };

  @override
  Future<bool> checkAccess({
    required String fanId,
    required String appId,
    required String permissionId,
    required String groupId,
    required String correlationId,
  }) async => _roles.containsKey(fanId);

  @override
  Future<Set<String>> resolveRoleIds({
    required String fanId,
    required String appId,
    required String groupId,
    required String correlationId,
  }) async => _roles[fanId] ?? const <String>{};

  @override
  Future<bool> hasActiveMembership({
    required String fanId,
    required String appId,
    required String groupId,
    required String correlationId,
  }) async => _roles.containsKey(fanId);

  @override
  Future<List<GroupMember>> listGroupMembers({
    required String appId,
    required String groupId,
    required String correlationId,
  }) async => [
    for (final entry in _roles.entries)
      GroupMember(fanId: entry.key, roleIds: entry.value, state: 'active'),
  ];
}
