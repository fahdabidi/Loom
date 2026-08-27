part of '../loom_communities_app_shell.dart';

/// A document stored against a workflow instance.
///
/// Mirrors the `Document` schema in
/// `docs/API/OpenAPI/community-surfaces/document-library-api.openapi.yaml`.
/// Deliberately not `CommunityDocument` from `loom_api_contracts`, whose
/// "document" is a `String body` with a three-value visibility enum -- no
/// bytes, and no way to express who may read it.
final class LoomDocument {
  const LoomDocument({
    required this.documentId,
    required this.communityId,
    required this.instanceId,
    required this.workflowType,
    required this.fieldName,
    required this.title,
    required this.filename,
    required this.contentType,
    required this.byteSize,
    required this.ownerFanId,
    required this.uploadedAt,
    required this.contentUrl,
  });

  factory LoomDocument.fromJson(Map<String, Object?> json) => LoomDocument(
    documentId: json['documentId']! as String,
    communityId: json['communityId']! as String,
    instanceId: json['instanceId']! as String,
    workflowType: json['workflowType']! as String,
    fieldName: json['fieldName']! as String,
    title: json['title']! as String,
    filename: json['filename']! as String,
    contentType: json['contentType']! as String,
    byteSize: (json['byteSize']! as num).toInt(),
    ownerFanId: json['ownerFanId']! as String,
    uploadedAt:
        DateTime.tryParse(json['uploadedAt'] as String? ?? '') ??
        DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    contentUrl: json['contentUrl'] as String? ?? '',
  );

  final String documentId;
  final String communityId;
  final String instanceId;
  final String workflowType;

  /// The instance field this document fills, e.g. `documentUrl`.
  final String fieldName;

  final String title;
  final String filename;
  final String contentType;
  final int byteSize;
  final String ownerFanId;
  final DateTime uploadedAt;

  /// Relative path of the content endpoint.
  ///
  /// Not a capability: it carries no token and grants nothing on its own, so it
  /// is safe to keep in instance data where a signed URL would not be.
  final String contentUrl;
}

/// Who may read and write a document, as the service resolved it just now.
final class LoomDocumentAccess {
  const LoomDocumentAccess({
    required this.documentId,
    required this.instanceState,
    required this.readFanIds,
    required this.writeFanIds,
    required this.everyone,
    required this.sharedWithFieldName,
  });

  factory LoomDocumentAccess.fromJson(Map<String, Object?> json) {
    final derivation = json['derivation'] as Map<String, Object?>? ?? const {};
    final byDefault =
        derivation['byDefault'] as Map<String, Object?>? ?? const {};
    final byShare = derivation['byShare'] as Map<String, Object?>? ?? const {};
    return LoomDocumentAccess(
      documentId: json['documentId']! as String,
      instanceState: json['instanceState'] as String? ?? '',
      readFanIds: _stringList(json['readFanIds']),
      writeFanIds: _stringList(json['writeFanIds']),
      everyone: byDefault['everyone'] == true,
      sharedWithFieldName: byShare['fieldName'] as String?,
    );
  }

  final String documentId;

  /// The state the answer was computed against.
  ///
  /// Worth showing: the answer is only true for this state, and one `publish`
  /// changes it.
  final String instanceState;

  final List<String> readFanIds;
  final List<String> writeFanIds;

  /// True when the workflow is `public`.
  ///
  /// [readFanIds] is then empty because there is no list to enumerate, which
  /// means everyone rather than nobody. Read this first or a public document
  /// renders as locked.
  final bool everyone;

  /// The instance field holding explicitly-granted readers, when the community
  /// declared one. Cedar Commons HOA names `explicitReaderFanIds`.
  final String? sharedWithFieldName;

  static List<String> _stringList(Object? value) => value is List
      ? [
          for (final entry in value)
            if (entry is String) entry,
        ]
      : const [];
}

/// Reads and writes the bytes behind `documentLibrary` workflows.
///
/// Holds no access rules of its own. Every refusal comes from the service,
/// which derives it from the community's workflow definition -- so a client
/// that guessed wrong about who may read a document cannot widen anything by
/// guessing.
final class LoomDocumentClient {
  LoomDocumentClient({
    required Uri workflowServiceBaseUri,
    required LoomAuthSession session,
    http.Client? httpClient,
  }) : _baseUri = _normaliseBaseUri(workflowServiceBaseUri),
       _session = session,
       _httpClient = httpClient ?? http.Client();

  final Uri _baseUri;
  final LoomAuthSession _session;
  final http.Client _httpClient;

  /// Stores [bytes] against [instanceId], filling the instance field
  /// [fieldName].
  Future<LoomDocument> upload({
    required String communityId,
    required String instanceId,
    required String fieldName,
    required String filename,
    required List<int> bytes,
    String? title,
    String contentType = 'application/octet-stream',
  }) async {
    final uri = _baseUri.resolve(
      'v1/communities/${Uri.encodeComponent(communityId)}/instances/'
      '${Uri.encodeComponent(instanceId)}/documents',
    );
    final request = http.MultipartRequest('POST', uri)
      ..headers.addAll(await _headers(mutating: true))
      ..fields['fieldName'] = fieldName
      ..fields['contentType'] = contentType;
    if (title != null && title.isNotEmpty) {
      request.fields['title'] = title;
    }
    // The media type travels as the `contentType` form field rather than on
    // the file part. Setting it on the part needs http_parser's MediaType, and
    // the service already prefers the field over the part's own header -- so
    // this avoids a dependency to say the same thing twice.
    request.files.add(
      http.MultipartFile.fromBytes('file', bytes, filename: filename),
    );

    final response = await http.Response.fromStream(
      await _httpClient.send(request),
    );
    // 200 as well as 201: an upload replayed with the same idempotency key
    // returns the document the first attempt created rather than storing the
    // bytes twice.
    if (response.statusCode != 201 && response.statusCode != 200) {
      throw LoomDocumentException(
        'Uploading "$filename" failed',
        statusCode: response.statusCode,
        body: response.body,
      );
    }
    return LoomDocument.fromJson(
      jsonDecode(response.body) as Map<String, Object?>,
    );
  }

  /// The documents on an instance that this fan may read.
  Future<List<LoomDocument>> listForInstance({
    required String communityId,
    required String instanceId,
  }) async {
    final response = await _send(
      'GET',
      _baseUri.resolve(
        'v1/communities/${Uri.encodeComponent(communityId)}/instances/'
        '${Uri.encodeComponent(instanceId)}/documents',
      ),
    );
    final body = jsonDecode(response.body) as Map<String, Object?>;
    return [
      for (final entry in (body['documents'] as List<Object?>? ?? const []))
        LoomDocument.fromJson(entry! as Map<String, Object?>),
    ];
  }

  /// Downloads the bytes.
  Future<Uint8List> download({
    required String communityId,
    required String documentId,
  }) async {
    final response = await _send(
      'GET',
      _baseUri.resolve(
        'v1/communities/${Uri.encodeComponent(communityId)}/documents/'
        '${Uri.encodeComponent(documentId)}/content',
      ),
    );
    return response.bodyBytes;
  }

  /// Who may read and write this document right now.
  Future<LoomDocumentAccess> access({
    required String communityId,
    required String documentId,
  }) async {
    final response = await _send(
      'GET',
      _baseUri.resolve(
        'v1/communities/${Uri.encodeComponent(communityId)}/documents/'
        '${Uri.encodeComponent(documentId)}/access',
      ),
    );
    return LoomDocumentAccess.fromJson(
      jsonDecode(response.body) as Map<String, Object?>,
    );
  }

  /// Removes the document.
  Future<void> delete({
    required String communityId,
    required String documentId,
  }) async {
    await _send(
      'DELETE',
      _baseUri.resolve(
        'v1/communities/${Uri.encodeComponent(communityId)}/documents/'
        '${Uri.encodeComponent(documentId)}',
      ),
      mutating: true,
      expectedStatusCodes: const {204},
    );
  }

  void close() => _httpClient.close();

  Future<Map<String, String>> _headers({bool mutating = false}) async {
    final accessToken = await _session.currentAccessToken();
    return {
      'authorization': 'Bearer $accessToken',
      'accept': 'application/json',
      'x-loom-correlation-id': _newUuidV4(),
      if (mutating) 'idempotency-key': 'loom-document-${_newUuidV4()}',
    };
  }

  Future<http.Response> _send(
    String method,
    Uri uri, {
    bool mutating = false,
    Set<int> expectedStatusCodes = const {200},
  }) async {
    final request = http.Request(method, uri)
      ..headers.addAll(await _headers(mutating: mutating));
    final response = await http.Response.fromStream(
      await _httpClient.send(request),
    );
    if (!expectedStatusCodes.contains(response.statusCode)) {
      throw LoomDocumentException(
        '$method $uri failed',
        statusCode: response.statusCode,
        body: response.body,
      );
    }
    return response;
  }
}

/// A document operation the service refused or could not complete.
///
/// Carries the status and body rather than collapsing to a message, because
/// 404 here means "absent or not yours" and a caller rendering that needs to
/// say so without claiming which.
final class LoomDocumentException implements Exception {
  const LoomDocumentException(
    this.message, {
    required this.statusCode,
    required this.body,
  });

  final String message;
  final int statusCode;
  final String body;

  /// The caller may not read this document, or it does not exist.
  bool get isNotFoundOrForbidden => statusCode == 404 || statusCode == 403;

  /// The deployment has no document storage configured.
  bool get isStorageUnavailable => statusCode == 503;

  @override
  String toString() =>
      'LoomDocumentException($statusCode): $message'
      '${body.isEmpty ? '' : ' -- $body'}';
}
