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
    required this.version,
    this.revisedAt,
    required this.contentUrl,
    this.changeNote,
  });

  factory LoomDocument.fromJson(Map<String, Object?> json) {
    final version = json['version'];
    final revisedAt = _optionalDocumentDateTime(json['revisedAt']);
    if (version is! num || version < 1) {
      throw const FormatException(
        'Document response is missing a service-assigned version.',
      );
    }
    if (json.containsKey('revisedAt') && revisedAt == null) {
      throw const FormatException(
        'Document response has an invalid revisedAt.',
      );
    }
    return LoomDocument(
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
      version: version.toInt(),
      revisedAt: revisedAt?.toUtc(),
      contentUrl: json['contentUrl'] as String? ?? '',
      changeNote: json['changeNote'] as String?,
    );
  }

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

  /// Service-assigned version of the bytes currently stored for this document.
  final int version;

  /// When the current version was published.
  final DateTime? revisedAt;

  /// Optional explanation supplied with the current revision.
  final String? changeNote;

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

/// The calling member's state for one shared document.
///
/// This belongs to the workflow service, never to workflow instance data: one
/// document has one independently durable state for every reader.
final class LoomDocumentMemberState {
  const LoomDocumentMemberState({
    required this.documentId,
    required this.fanId,
    required this.currentVersion,
    required this.read,
    required this.acknowledged,
    required this.saved,
    this.readAt,
    this.savedAt,
    this.acknowledgedAt,
    this.acknowledgedVersion,
  });

  factory LoomDocumentMemberState.fromJson(Map<String, Object?> json) {
    final documentId = json['documentId'];
    final fanId = json['fanId'];
    final currentVersion = json['currentVersion'];
    final read = json['read'];
    final acknowledged = json['acknowledged'];
    final saved = json['saved'];
    final readAt = _optionalDocumentDateTime(json['readAt']);
    final savedAt = _optionalDocumentDateTime(json['savedAt']);
    final acknowledgedAt = _optionalDocumentDateTime(json['acknowledgedAt']);
    final acknowledgedVersion = json['acknowledgedVersion'];
    if (documentId is! String ||
        fanId is! String ||
        currentVersion is! num ||
        read is! bool ||
        acknowledged is! bool ||
        saved is! bool ||
        (json.containsKey('readAt') && readAt == null) ||
        (json.containsKey('savedAt') && savedAt == null) ||
        (json.containsKey('acknowledgedAt') && acknowledgedAt == null) ||
        (acknowledgedVersion != null && acknowledgedVersion is! num)) {
      throw const FormatException(
        'Document member state has an invalid response shape.',
      );
    }
    return LoomDocumentMemberState(
      documentId: documentId,
      fanId: fanId,
      currentVersion: currentVersion.toInt(),
      read: read,
      acknowledged: acknowledged,
      saved: saved,
      readAt: readAt?.toUtc(),
      savedAt: savedAt?.toUtc(),
      acknowledgedAt: acknowledgedAt?.toUtc(),
      acknowledgedVersion: (acknowledgedVersion as num?)?.toInt(),
    );
  }

  final String documentId;
  final String fanId;
  final int currentVersion;
  final bool read;
  final DateTime? readAt;
  final bool acknowledged;
  final DateTime? acknowledgedAt;
  final int? acknowledgedVersion;
  final bool saved;
  final DateTime? savedAt;

  /// True only when the service record is for the bytes currently shown.
  bool get hasAcknowledgedCurrentVersion =>
      acknowledged && acknowledgedVersion == currentVersion;

  /// A historical acknowledgement is not a current acknowledgement.
  bool get acknowledgementIsStale =>
      acknowledged &&
      acknowledgedVersion != null &&
      acknowledgedVersion! < currentVersion;
}

/// One immutable acknowledgement in the document's audit record.
final class LoomDocumentAcknowledgement {
  const LoomDocumentAcknowledgement({
    required this.fanId,
    required this.version,
    required this.acknowledgedAt,
    this.stale,
  });

  factory LoomDocumentAcknowledgement.fromJson(Map<String, Object?> json) {
    final fanId = json['fanId'];
    final version = json['version'];
    final acknowledgedAt = _optionalDocumentDateTime(json['acknowledgedAt']);
    final stale = json['stale'];
    if (fanId is! String ||
        version is! num ||
        acknowledgedAt == null ||
        (stale != null && stale is! bool)) {
      throw const FormatException(
        'Document acknowledgement has an invalid response shape.',
      );
    }
    return LoomDocumentAcknowledgement(
      fanId: fanId,
      version: version.toInt(),
      acknowledgedAt: acknowledgedAt.toUtc(),
      stale: stale as bool?,
    );
  }

  final String fanId;
  final int version;
  final DateTime acknowledgedAt;

  /// The service's current-version comparison, when requested in a list.
  final bool? stale;
}

/// The acknowledgements a document administrator may inspect.
final class LoomDocumentAcknowledgements {
  const LoomDocumentAcknowledgements({
    required this.documentId,
    required this.currentVersion,
    required this.acknowledgements,
  });

  factory LoomDocumentAcknowledgements.fromJson(Map<String, Object?> json) {
    final documentId = json['documentId'];
    final currentVersion = json['currentVersion'];
    final acknowledgements = json['acknowledgements'];
    if (documentId is! String ||
        currentVersion is! num ||
        acknowledgements is! List) {
      throw const FormatException(
        'Document acknowledgements have an invalid response shape.',
      );
    }
    return LoomDocumentAcknowledgements(
      documentId: documentId,
      currentVersion: currentVersion.toInt(),
      acknowledgements: acknowledgements
          .map(
            (acknowledgement) => LoomDocumentAcknowledgement.fromJson(
              _documentObject(acknowledgement, 'Document acknowledgements'),
            ),
          )
          .toList(growable: false),
    );
  }

  final String documentId;
  final int currentVersion;
  final List<LoomDocumentAcknowledgement> acknowledgements;
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
    // Initial uploads deliberately use the API's `contentType` form field.
    // Revision uploads use their file-part media type instead, as that route's
    // contract defines.
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

  /// Replaces the bytes of an existing document and lets the service assign
  /// the next version. A caller must never send a version of its own.
  Future<LoomDocument> addRevision({
    required String communityId,
    required String documentId,
    required String filename,
    required List<int> bytes,
    String? changeNote,
    String contentType = 'application/octet-stream',
  }) async {
    final uri = _documentUri(communityId, documentId, 'revisions');
    final request = http.MultipartRequest('POST', uri)
      ..headers.addAll(await _headers(mutating: true));
    if (changeNote != null && changeNote.trim().isNotEmpty) {
      request.fields['changeNote'] = changeNote.trim();
    }
    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: filename,
        contentType: MediaType.parse(contentType),
      ),
    );

    final response = await http.Response.fromStream(
      await _httpClient.send(request),
    );
    if (response.statusCode != 201 && response.statusCode != 200) {
      throw LoomDocumentException(
        'Adding a revision to "$filename" failed',
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

  /// Reads only the calling member's state for [documentId].
  Future<LoomDocumentMemberState> getDocumentMemberState({
    required String communityId,
    required String documentId,
  }) async {
    final response = await _send(
      'GET',
      _documentUri(communityId, documentId, 'state'),
    );
    return LoomDocumentMemberState.fromJson(
      jsonDecode(response.body) as Map<String, Object?>,
    );
  }

  /// Updates only the member facts supplied by the caller.
  ///
  /// `acknowledged` may be sent only as `true`; the service binds that record
  /// to its own current version.
  Future<LoomDocumentMemberState> setDocumentMemberState({
    required String communityId,
    required String documentId,
    bool? read,
    bool? acknowledged,
    bool? saved,
  }) async {
    if (read == null && acknowledged == null && saved == null) {
      throw ArgumentError(
        'At least one document member-state fact is required.',
      );
    }
    final response = await _send(
      'PUT',
      _documentUri(communityId, documentId, 'state'),
      jsonBody: <String, Object?>{
        if (read != null) 'read': read,
        if (acknowledged != null) 'acknowledged': acknowledged,
        if (saved != null) 'saved': saved,
      },
    );
    return LoomDocumentMemberState.fromJson(
      jsonDecode(response.body) as Map<String, Object?>,
    );
  }

  /// Lists the immutable acknowledgements available to a document
  /// administrator. Ordinary readers are correctly refused by the service.
  Future<LoomDocumentAcknowledgements> listDocumentAcknowledgements({
    required String communityId,
    required String documentId,
    bool currentVersionOnly = false,
  }) async {
    final baseUri = _documentUri(communityId, documentId, 'acknowledgements');
    final uri = currentVersionOnly
        ? baseUri.replace(queryParameters: const {'currentVersionOnly': 'true'})
        : baseUri;
    final response = await _send('GET', uri);
    return LoomDocumentAcknowledgements.fromJson(
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

  Uri _documentUri(String communityId, String documentId, String action) =>
      _baseUri.resolve(
        'v1/communities/${Uri.encodeComponent(communityId)}/documents/'
        '${Uri.encodeComponent(documentId)}/$action',
      );

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
    Map<String, Object?>? jsonBody,
    Set<int> expectedStatusCodes = const {200},
  }) async {
    final request = http.Request(method, uri)
      ..headers.addAll(await _headers(mutating: mutating));
    if (jsonBody != null) {
      request.headers['content-type'] = 'application/json';
      request.body = jsonEncode(jsonBody);
    }
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

DateTime? _optionalDocumentDateTime(Object? value) {
  if (value == null || value is! String) return null;
  return DateTime.tryParse(value);
}

Map<String, Object?> _documentObject(Object? value, String source) {
  if (value is Map) return Map<String, Object?>.from(value);
  throw FormatException('$source must be a JSON object.');
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
