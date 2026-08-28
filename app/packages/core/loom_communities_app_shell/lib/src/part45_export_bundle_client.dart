part of '../loom_communities_app_shell.dart';

/// Metadata for a generated export bundle.
///
/// This mirrors the `ExportBundle` schema from the export-bundle OpenAPI
/// surface. The bytes themselves are deliberately kept by the workflow
/// service; the app only keeps this server-returned handle while the process
/// is alive so it can ask the service to download or verify the same bundle.
final class LoomExportBundle {
  const LoomExportBundle({
    required this.exportId,
    required this.communityId,
    required this.instanceId,
    required this.checksum,
    required this.checksumAlgorithm,
    required this.byteSize,
    required this.recordCount,
    required this.redacted,
    required this.generatedAt,
  });

  factory LoomExportBundle.fromJson(Map<String, Object?> json) {
    final generatedAt = DateTime.tryParse(json['generatedAt'] as String? ?? '');
    if (json['exportId'] is! String ||
        json['communityId'] is! String ||
        json['instanceId'] is! String ||
        json['checksum'] is! String ||
        json['checksumAlgorithm'] is! String ||
        json['byteSize'] is! num ||
        json['recordCount'] is! num ||
        json['redacted'] is! bool ||
        generatedAt == null) {
      throw const FormatException(
        'ExportBundle has an invalid response shape.',
      );
    }
    return LoomExportBundle(
      exportId: json['exportId']! as String,
      communityId: json['communityId']! as String,
      instanceId: json['instanceId']! as String,
      checksum: json['checksum']! as String,
      checksumAlgorithm: json['checksumAlgorithm']! as String,
      byteSize: (json['byteSize']! as num).toInt(),
      recordCount: (json['recordCount']! as num).toInt(),
      redacted: json['redacted']! as bool,
      generatedAt: generatedAt.toUtc(),
    );
  }

  final String exportId;
  final String communityId;
  final String instanceId;
  final String checksum;
  final String checksumAlgorithm;
  final int byteSize;
  final int recordCount;
  final bool redacted;
  final DateTime generatedAt;
}

/// A fresh verification observation from the workflow service.
///
/// [verified] is intentionally independent of HTTP success: a mismatch is a
/// successful comparison and must render as a mismatch rather than an error.
final class LoomExportBundleVerification {
  const LoomExportBundleVerification({
    required this.exportId,
    required this.verified,
    required this.recordedChecksum,
    required this.observedChecksum,
    required this.checksumAlgorithm,
    required this.recordedByteSize,
    required this.observedByteSize,
    required this.verifiedAt,
  });

  factory LoomExportBundleVerification.fromJson(Map<String, Object?> json) {
    final verifiedAt = DateTime.tryParse(json['verifiedAt'] as String? ?? '');
    if (json['exportId'] is! String ||
        json['verified'] is! bool ||
        json['recordedChecksum'] is! String ||
        json['observedChecksum'] is! String ||
        json['checksumAlgorithm'] is! String ||
        json['recordedByteSize'] is! num ||
        json['observedByteSize'] is! num ||
        verifiedAt == null) {
      throw const FormatException(
        'ExportBundleVerification has an invalid response shape.',
      );
    }
    return LoomExportBundleVerification(
      exportId: json['exportId']! as String,
      verified: json['verified']! as bool,
      recordedChecksum: json['recordedChecksum']! as String,
      observedChecksum: json['observedChecksum']! as String,
      checksumAlgorithm: json['checksumAlgorithm']! as String,
      recordedByteSize: (json['recordedByteSize']! as num).toInt(),
      observedByteSize: (json['observedByteSize']! as num).toInt(),
      verifiedAt: verifiedAt.toUtc(),
    );
  }

  final String exportId;
  final bool verified;
  final String recordedChecksum;
  final String observedChecksum;
  final String checksumAlgorithm;
  final int recordedByteSize;
  final int observedByteSize;
  final DateTime verifiedAt;
}

/// Client for the four export-bundle operations implemented by the workflow
/// service.
///
/// It owns neither authorization policy nor checksum calculation. Those stay
/// server-side so the bytes served, the recorded digest and verification all
/// refer to the same stored object.
final class LoomExportBundleClient {
  LoomExportBundleClient({
    required Uri workflowServiceBaseUri,
    required LoomAuthSession session,
    http.Client? httpClient,
  }) : _baseUri = _normaliseBaseUri(workflowServiceBaseUri),
       _session = session,
       _httpClient = httpClient ?? http.Client();

  final Uri _baseUri;
  final LoomAuthSession _session;
  final http.Client _httpClient;

  Future<LoomExportBundle> generate({
    required String communityId,
    required String instanceId,
    required bool redactProtectedData,
    List<String>? componentIds,
    bool includeDocuments = true,
  }) async {
    final response = await _send(
      'POST',
      _instanceUri(communityId, instanceId),
      body: jsonEncode(<String, Object?>{
        'redactProtectedData': redactProtectedData,
        if (componentIds != null) 'componentIds': componentIds,
        'includeDocuments': includeDocuments,
      }),
      mutating: true,
      // An export is one durable intent per workflow instance. Retrying the
      // same completed transition must retrieve the recorded bundle rather
      // than create a second valid checksum for later bytes.
      idempotencyKey: 'loom-export-$instanceId',
      expectedStatusCodes: const {200, 201},
    );
    return LoomExportBundle.fromJson(
      jsonDecode(response.body) as Map<String, Object?>,
    );
  }

  Future<LoomExportBundle> get({
    required String communityId,
    required String exportId,
  }) async {
    final response = await _send('GET', _bundleUri(communityId, exportId));
    return LoomExportBundle.fromJson(
      jsonDecode(response.body) as Map<String, Object?>,
    );
  }

  /// Returns the exact octets stored by the workflow service.
  Future<Uint8List> download({
    required String communityId,
    required String exportId,
  }) async {
    final bundle = _bundleUri(communityId, exportId);
    final response = await _send(
      'GET',
      bundle.replace(path: '${bundle.path}/content'),
    );
    return response.bodyBytes;
  }

  Future<LoomExportBundleVerification> verify({
    required String communityId,
    required String exportId,
  }) async {
    final bundle = _bundleUri(communityId, exportId);
    final response = await _send(
      'POST',
      bundle.replace(path: '${bundle.path}/verification'),
      body: jsonEncode(const <String, Object?>{}),
      mutating: false,
    );
    return LoomExportBundleVerification.fromJson(
      jsonDecode(response.body) as Map<String, Object?>,
    );
  }

  void close() => _httpClient.close();

  Uri _instanceUri(String communityId, String instanceId) => _baseUri.resolve(
    'v1/communities/${Uri.encodeComponent(communityId)}/instances/'
    '${Uri.encodeComponent(instanceId)}/export-bundle',
  );

  Uri _bundleUri(String communityId, String exportId) => _baseUri.resolve(
    'v1/communities/${Uri.encodeComponent(communityId)}/export-bundles/'
    '${Uri.encodeComponent(exportId)}',
  );

  Future<Map<String, String>> _headers({
    required bool mutating,
    String? idempotencyKey,
  }) async {
    final accessToken = await _session.currentAccessToken();
    return <String, String>{
      'authorization': 'Bearer $accessToken',
      'accept': 'application/json',
      'x-loom-correlation-id': _newUuidV4(),
      if (mutating)
        'idempotency-key': idempotencyKey ?? 'loom-export-${_newUuidV4()}',
    };
  }

  Future<http.Response> _send(
    String method,
    Uri uri, {
    String? body,
    bool mutating = false,
    String? idempotencyKey,
    Set<int> expectedStatusCodes = const {200},
  }) async {
    final request = http.Request(method, uri)
      ..headers.addAll(
        await _headers(mutating: mutating, idempotencyKey: idempotencyKey),
      );
    if (body != null) {
      request.headers['content-type'] = 'application/json';
      request.body = body;
    }
    final response = await http.Response.fromStream(
      await _httpClient.send(request),
    );
    if (!expectedStatusCodes.contains(response.statusCode)) {
      throw LoomExportBundleException(
        '$method $uri failed',
        statusCode: response.statusCode,
        body: response.body,
      );
    }
    return response;
  }
}

/// A refusal or unavailable export-bundle operation.
final class LoomExportBundleException implements Exception {
  const LoomExportBundleException(
    this.message, {
    required this.statusCode,
    required this.body,
  });

  final String message;
  final int statusCode;
  final String body;

  bool get isUnavailable => statusCode == 410 || statusCode >= 500;

  @override
  String toString() =>
      'LoomExportBundleException($statusCode): $message'
      '${body.isEmpty ? '' : ' -- $body'}';
}

LoomExportBundleClient? _exportBundleClientOverrideForTesting;

/// The export client for this build, or null for an explicitly local build.
LoomExportBundleClient? resolveLoomExportBundleClient() {
  final override = _exportBundleClientOverrideForTesting;
  if (override != null) return override;
  final configuration = loomRemoteServiceConfiguration;
  if (configuration == null) return null;
  return LoomExportBundleClient(
    workflowServiceBaseUri: configuration.workflowServiceBaseUri,
    session: configuration.session,
  );
}

@visibleForTesting
void overrideLoomExportBundleClientForTesting(LoomExportBundleClient? client) {
  _exportBundleClientOverrideForTesting = client;
}

@visibleForTesting
void resetLoomExportBundleClientForTesting() {
  _exportBundleClientOverrideForTesting = null;
  _exportBundlesForCurrentAppSession.clear();
}

/// An app-session handle for an actually generated bundle.
///
/// The service's instance writeback is intentionally limited to checksum
/// fields, so the OpenAPI `exportId` has no schema field to persist in current
/// community packages. Keeping only this genuine server response lets a card
/// invoke download and verify without inventing an identifier or a checksum.
final Map<String, LoomExportBundle> _exportBundlesForCurrentAppSession =
    <String, LoomExportBundle>{};

String _exportBundleSessionKey({
  required String communityId,
  required String instanceId,
}) => '$communityId/$instanceId';

void rememberLoomExportBundleForCurrentAppSession(LoomExportBundle bundle) {
  _exportBundlesForCurrentAppSession[_exportBundleSessionKey(
        communityId: bundle.communityId,
        instanceId: bundle.instanceId,
      )] =
      bundle;
}

LoomExportBundle? rememberedLoomExportBundleForCurrentAppSession({
  required String communityId,
  required String instanceId,
}) =>
    _exportBundlesForCurrentAppSession[_exportBundleSessionKey(
      communityId: communityId,
      instanceId: instanceId,
    )];
