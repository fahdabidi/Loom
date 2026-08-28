import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:loom_workflow_engine/loom_workflow_engine.dart';
import 'package:loom_workflow_service/loom_workflow_service.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

const _communityId = 'export-test-community';
const _groupId = 'loom_communities_export-test-community';
const _exportWorkflowType = 'community-export';
const _recordWorkflowType = 'member-record';
const _exportInstanceId = 'export-control-instance';
const _recordInstanceId = 'record-001';
const _correlationId = '77777777-7777-4777-8777-777777777777';
const _exporter = 'fan-exporter';
const _runOnly = 'fan-run-only';
const _viewer = 'fan-viewer';

const _exportDefinition = '''
{
  "initialState": "ready",
  "visibility": {"default": "public"},
  "states": {
    "ready": {"label": "Ready"}
  },
  "transitions": [
    {"id": "generate", "label": "Generate", "action": "run",
     "from": ["ready"], "to": null,
     "guard": {"allowedRoleIds": ["exporter", "run-only"]}},
    {"id": "download", "label": "Download", "action": "download",
     "from": ["ready"], "to": null,
     "guard": {"allowedRoleIds": ["exporter"]}}
  ],
  "renderBindings": [
    {"states": ["ready"], "audience": "any", "tabId": "admin",
     "cardSurfaceFamily": "exportWizard", "bindingKind": "primary"}
  ],
  "instanceDataSchema": {
    "checksum": {"type": "text?", "writableBy": "platform"},
    "checksumAlgorithm": {"type": "text?", "writableBy": "platform"},
    "checksumVerified": {"type": "bool", "writableBy": "platform"},
    "protectedFields": {"type": "list", "writableBy": "formEntry"}
  }
}
''';

const _recordDefinition = '''
{
  "initialState": "active",
  "visibility": {"default": "public"},
  "states": {"active": {"label": "Active"}},
  "transitions": [],
  "renderBindings": [
    {"states": ["active"], "audience": "any", "tabId": "home",
     "cardSurfaceFamily": "formEntry", "bindingKind": "primary"}
  ],
  "instanceDataSchema": {
    "displayName": {"type": "text", "writableBy": "formEntry"},
    "privateNote": {"type": "text", "writableBy": "formEntry", "redactOnExport": true},
    "updatedAt": {"type": "date?", "writableBy": "effect"}
  }
}
''';

void main() {
  late WorkflowDatabase database;
  late WorkflowService service;
  late InMemoryDocumentObjectStore objectStore;
  late InMemoryExportBundleRepository bundleRepository;

  setUp(() async {
    database = WorkflowDatabase.memory();
    objectStore = InMemoryDocumentObjectStore();
    bundleRepository = InMemoryExportBundleRepository();
    service = WorkflowService(
      database: database,
      identityExtractor: const HeaderWorkflowIdentityExtractor(),
      appAccessClient: _ExportAppAccessClient(),
      communityGroupIdResolver: MapCommunityGroupIdResolver({
        _communityId: _groupId,
      }),
      documentRepository: InMemoryDocumentRepository(),
      documentObjectStore: objectStore,
      exportBundleRepository: bundleRepository,
    );
    _activeService = service;
    await database.upsertDefinition(
      definitionId: '${_communityId}_$_exportWorkflowType',
      workflowType: _exportWorkflowType,
      definitionJson: _exportDefinition,
      version: 4,
    );
    await database.upsertDefinition(
      definitionId: '${_communityId}_$_recordWorkflowType',
      workflowType: _recordWorkflowType,
      definitionJson: _recordDefinition,
      version: 4,
    );
    await database.insertInstance(
      instanceId: _exportInstanceId,
      communityId: _communityId,
      workflowType: _exportWorkflowType,
      currentState: 'ready',
      instanceData: <String, dynamic>{'protectedFields': <String>[]},
      createdByFanId: _exporter,
    );
    await database.insertInstance(
      instanceId: _recordInstanceId,
      communityId: _communityId,
      workflowType: _recordWorkflowType,
      currentState: 'active',
      instanceData: <String, dynamic>{
        'displayName': 'Ava Exportable',
        'privateNote': 'leave this out of redacted bundles',
        'updatedAt': '2026-08-26T17:18:19-07:00',
      },
      createdByFanId: _exporter,
    );
  });

  tearDown(() {
    _activeService = null;
    database.close();
  });

  test('generate, download, and verify hash the same served bytes', () async {
    final generated = await _generate();
    expect(generated.response.statusCode, 201, reason: generated.rawBody);
    final bundle = generated.body;
    final exportId = bundle['exportId'] as String;
    final checksum = bundle['checksum'] as String;

    final metadata = await _get(exportId);
    expect(metadata.response.statusCode, 200, reason: metadata.rawBody);
    expect(metadata.body['checksum'], checksum);

    final download = await _download(exportId);
    expect(download.statusCode, 200);
    final bytes = await _responseBytes(download);
    // Independent of service responses: this is the digest a recipient can
    // reproduce with sha256sum over the downloaded octets.
    expect(sha256.convert(bytes).toString(), checksum);
    expect(download.headers['etag'], '"$checksum"');

    final verify = await _verify(exportId);
    expect(verify.response.statusCode, 200, reason: verify.rawBody);
    expect(verify.body['verified'], isTrue);
    expect(verify.body['recordedChecksum'], checksum);
    expect(verify.body['observedChecksum'], checksum);

    final stored = await database.readInstance(_exportInstanceId);
    final data = jsonDecode(stored!.instanceData) as Map<String, dynamic>;
    expect(data['checksum'], checksum);
    expect(data['checksumAlgorithm'], 'sha-256');
    expect(data['checksumVerified'], isTrue);
  });

  test('two unchanged generations have identical checksums', () async {
    final first = await _generate(idempotencyKey: 'determinism-one');
    final second = await _generate(idempotencyKey: 'determinism-two');

    expect(first.response.statusCode, 201, reason: first.rawBody);
    expect(second.response.statusCode, 201, reason: second.rawBody);
    expect(first.body['checksum'], second.body['checksum']);
  });

  test('verification rehashes storage and reports tampering', () async {
    final generated = await _generate();
    final exportId = generated.body['exportId'] as String;
    final recorded = generated.body['checksum'] as String;
    final storedBundle = await bundleRepository.findById(
      communityId: _communityId,
      exportId: exportId,
    );
    expect(storedBundle, isNotNull);
    objectStore.objects[storedBundle!.objectKey] = utf8.encode(
      'tampered bytes',
    );

    final verification = await _verify(exportId);
    expect(verification.response.statusCode, 200, reason: verification.rawBody);
    expect(verification.body['verified'], isFalse);
    expect(verification.body['recordedChecksum'], recorded);
    expect(verification.body['observedChecksum'], isNot(recorded));

    final instance = await database.readInstance(_exportInstanceId);
    final data = jsonDecode(instance!.instanceData) as Map<String, dynamic>;
    expect(
      data['checksum'],
      recorded,
      reason: 'mismatch must preserve evidence',
    );
    expect(data['checksumVerified'], isFalse);
  });

  test(
    'redacted and full bundles differ and each hashes its served bytes',
    () async {
      final full = await _generate(
        redactProtectedData: false,
        idempotencyKey: 'full-bundle-test',
      );
      final redacted = await _generate(
        redactProtectedData: true,
        idempotencyKey: 'redacted-bundle-test',
      );
      expect(full.body['checksum'], isNot(redacted.body['checksum']));

      final redactedDownload = await _download(
        redacted.body['exportId'] as String,
      );
      final redactedBytes = await _responseBytes(redactedDownload);
      expect(
        sha256.convert(redactedBytes).toString(),
        redacted.body['checksum'],
      );
      final decoded =
          jsonDecode(utf8.decode(redactedBytes)) as Map<String, dynamic>;
      final records = decoded['records'] as List<dynamic>;
      final data =
          (records.single as Map<String, dynamic>)['instanceData']
              as Map<String, dynamic>;
      expect(data.containsKey('privateNote'), isFalse);
    },
  );

  test(
    'missing stored object returns 410 rather than verified false',
    () async {
      final generated = await _generate();
      final exportId = generated.body['exportId'] as String;
      final bundle = await bundleRepository.findById(
        communityId: _communityId,
        exportId: exportId,
      );
      objectStore.objects.remove(bundle!.objectKey);

      final verification = await _verify(exportId);
      expect(verification.response.statusCode, 410);
      expect(verification.body['code'], 'export_bundle_content_missing');
      expect(verification.body.containsKey('verified'), isFalse);
    },
  );

  test('a caller without run is refused generation with 403', () async {
    final generated = await _generate(fanId: _viewer);

    expect(generated.response.statusCode, 403);
    expect(generated.body['code'], 'export_bundle_generate_forbidden');
  });

  test('a caller without download is refused download with 403', () async {
    final generated = await _generate(fanId: _runOnly);
    expect(generated.response.statusCode, 201, reason: generated.rawBody);

    final download = await _download(
      generated.body['exportId'] as String,
      fanId: _runOnly,
    );
    expect(download.statusCode, 403);
    final body =
        jsonDecode(await download.readAsString()) as Map<String, dynamic>;
    expect(body['code'], 'export_bundle_download_forbidden');

    final verification = await _verify(
      generated.body['exportId'] as String,
      fanId: _runOnly,
    );
    expect(verification.response.statusCode, 403);
    expect(verification.body['code'], 'export_bundle_download_forbidden');
  });

  test('a missing correlation id is rejected with 400', () async {
    final response = await service.handler(
      Request(
        'POST',
        Uri.parse(
          'http://localhost/v1/communities/$_communityId/instances/'
          '$_exportInstanceId/export-bundle',
        ),
        headers: <String, String>{
          'content-type': 'application/json',
          'idempotency-key': 'missing-correlation',
          HeaderWorkflowIdentityExtractor.defaultHeaderName: _exporter,
        },
        body: jsonEncode(_requestBody()),
      ),
    );
    expect(response.statusCode, 400);
    final body =
        jsonDecode(await response.readAsString()) as Map<String, dynamic>;
    expect(body['code'], 'invalid_correlation_id');
  });

  test(
    'idempotency replay returns the original export id and checksum',
    () async {
      const idempotencyKey = 'same-export-intent';
      final first = await _generate(idempotencyKey: idempotencyKey);
      final replay = await _generate(idempotencyKey: idempotencyKey);

      expect(first.response.statusCode, 201, reason: first.rawBody);
      expect(replay.response.statusCode, 200, reason: replay.rawBody);
      expect(replay.body['exportId'], first.body['exportId']);
      expect(replay.body['checksum'], first.body['checksum']);
    },
  );
}

Future<_JsonResponse> _generate({
  String fanId = _exporter,
  String idempotencyKey = 'round-trip-export',
  bool redactProtectedData = false,
}) async {
  final response = await _service().handler(
    Request(
      'POST',
      Uri.parse(
        'http://localhost/v1/communities/$_communityId/instances/'
        '$_exportInstanceId/export-bundle',
      ),
      headers: _headers(fanId, idempotencyKey: idempotencyKey),
      body: jsonEncode(_requestBody(redactProtectedData: redactProtectedData)),
    ),
  );
  return _JsonResponse.from(response);
}

// Set per test to avoid a global service locator in the assertions above.
WorkflowService? _activeService;
WorkflowService _service() => _activeService!;

Future<_JsonResponse> _get(String exportId, {String fanId = _exporter}) async {
  final response = await _service().handler(
    Request(
      'GET',
      Uri.parse(
        'http://localhost/v1/communities/$_communityId/export-bundles/'
        '$exportId',
      ),
      headers: _headers(fanId),
    ),
  );
  return _JsonResponse.from(response);
}

Future<Response> _download(String exportId, {String fanId = _exporter}) async =>
    _service().handler(
      Request(
        'GET',
        Uri.parse(
          'http://localhost/v1/communities/$_communityId/export-bundles/'
          '$exportId/content',
        ),
        headers: _headers(fanId),
      ),
    );

Future<_JsonResponse> _verify(
  String exportId, {
  String fanId = _exporter,
}) async {
  final response = await _service().handler(
    Request(
      'POST',
      Uri.parse(
        'http://localhost/v1/communities/$_communityId/export-bundles/'
        '$exportId/verification',
      ),
      headers: _headers(fanId),
    ),
  );
  return _JsonResponse.from(response);
}

Map<String, dynamic> _requestBody({bool redactProtectedData = false}) =>
    <String, dynamic>{
      'redactProtectedData': redactProtectedData,
      'componentIds': <String>[_recordWorkflowType],
      'includeDocuments': false,
    };

Map<String, String> _headers(String fanId, {String? idempotencyKey}) =>
    <String, String>{
      'content-type': 'application/json',
      'x-loom-correlation-id': _correlationId,
      HeaderWorkflowIdentityExtractor.defaultHeaderName: fanId,
      if (idempotencyKey != null) 'idempotency-key': idempotencyKey,
    };

Future<List<int>> _responseBytes(Response response) =>
    response.read().expand((chunk) => chunk).toList();

class _JsonResponse {
  const _JsonResponse({
    required this.response,
    required this.rawBody,
    required this.body,
  });

  final Response response;
  final String rawBody;
  final Map<String, dynamic> body;

  static Future<_JsonResponse> from(Response response) async {
    final rawBody = await response.readAsString();
    return _JsonResponse(
      response: response,
      rawBody: rawBody,
      body: jsonDecode(rawBody) as Map<String, dynamic>,
    );
  }
}

class _ExportAppAccessClient implements AppAccessDecisionClient {
  static const _roles = <String, Set<String>>{
    _exporter: <String>{'exporter'},
    _runOnly: <String>{'run-only'},
    _viewer: <String>{'viewer'},
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
  }) async => <GroupMember>[
    for (final entry in _roles.entries)
      GroupMember(fanId: entry.key, roleIds: entry.value, state: 'active'),
  ];

  @override
  Future<Set<String>> resolveRoleIds({
    required String fanId,
    required String appId,
    required String groupId,
    required String correlationId,
  }) async => _roles[fanId] ?? const <String>{};
}
