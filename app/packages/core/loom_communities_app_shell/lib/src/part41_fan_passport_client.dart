part of '../loom_communities_app_shell.dart';

/// A fan passport as the deployed Fan Passport service actually returns it.
///
/// Deliberately modelled on `spec/identity/fan-passport-api.openapi.yaml`
/// rather than on `FanPassportApi` in `loom_api_contracts`. That contract
/// describes a fan-profile concept the service does not have: it requires an
/// `activeFanProfileId`, and exposes `setFanProfile`, while the service has no
/// profile endpoint at all and its `FanPassport` schema is
/// `fanId, displayName, privacyMode, publicKey, createdAt`.
///
/// Implementing the stale contract would have meant inventing values for
/// fields the service never returns, which is the "faking it while looking
/// real" failure this migration exists to remove. The OpenAPI spec is the
/// contract the running service honours, so it is the one modelled here.
final class FanPassportRecord {
  const FanPassportRecord({
    required this.fanId,
    required this.displayName,
    this.privacyMode,
    this.publicKey,
    this.createdAt,
  });

  /// The fan's id, which since 2026-08-26 is the `fanId` claim of their token.
  ///
  /// Before that the service minted its own `fan_<uuid>`, so a passport could
  /// never be found by the id App Access and the workflow service use — one
  /// subject with two identities, and every lookup a permanent 404.
  final String fanId;
  final String displayName;
  final String? privacyMode;
  final String? publicKey;
  final DateTime? createdAt;
}

/// The Fan Passport operations the communities app needs.
///
/// Only two: read a passport, and create one during sign-up. The service also
/// offers follows, consent grants, creator-category policies, external and
/// pairwise identities — none of which a community models, so none of which
/// are wired. Adding them because they exist would be building surface nobody
/// calls.
final class FanPassportClient {
  FanPassportClient({
    required Uri baseUri,
    required LoomAuthSession session,
    http.Client? httpClient,
  }) : _baseUri = _normaliseBaseUri(baseUri),
       _session = session,
       _httpClient = httpClient ?? http.Client();

  final Uri _baseUri;
  final LoomAuthSession _session;
  final http.Client _httpClient;

  /// Reads a passport, or `null` when the fan has none yet.
  ///
  /// A fan with no passport is an ordinary state, not an error: they have
  /// authenticated but never completed sign-up. `null` says exactly that,
  /// where an exception would force every caller to distinguish "absent" from
  /// "failed".
  Future<FanPassportRecord?> getPassport(String fanId) async {
    final response = await _send(
      method: 'GET',
      uri: _baseUri.resolve('v1/fan-passports/${Uri.encodeComponent(fanId)}'),
      acceptedStatusCodes: const {404},
    );
    if (response.statusCode == 404) return null;
    return _parse(response.body, 'GET v1/fan-passports/$fanId');
  }

  /// Creates the caller's passport.
  ///
  /// The service takes the fan id from the token rather than the body, so a
  /// caller cannot mint a passport for someone else. Creating twice is
  /// idempotent — a passport *is* that fan, so a second call is the same
  /// assertion and returns the existing record rather than a duplicate.
  Future<FanPassportRecord> createPassport({
    required String displayName,
  }) async {
    final response = await _send(
      method: 'POST',
      uri: _baseUri.resolve('v1/fan-passports'),
      body: <String, Object?>{'displayName': displayName},
      mutating: true,
    );
    final parsed = _parse(response.body, 'POST v1/fan-passports');
    if (parsed == null) {
      throw StateError(
        'Fan Passport returned no body when creating a passport.',
      );
    }
    return parsed;
  }

  void close() => _httpClient.close();

  Future<_FanPassportResponse> _send({
    required String method,
    required Uri uri,
    Object? body,
    bool mutating = false,
    Set<int> acceptedStatusCodes = const {},
  }) async {
    final accessToken = await _session.currentAccessToken();
    final request = http.Request(method, uri)
      ..headers['authorization'] = 'Bearer $accessToken'
      ..headers['accept'] = 'application/json'
      // A non-UUID correlation id is rejected with 400 by the Loom services,
      // so this is generated rather than composed from anything readable.
      ..headers['x-loom-correlation-id'] = _newUuidV4();
    if (mutating) {
      // 'loom-auth-', not a passport-specific prefix: this moved out of
      // RemoteLoomAuthApi and the wire format is deliberately unchanged. The
      // uniqueness is the UUID; the prefix only marks the app as the origin.
      request.headers['idempotency-key'] = 'loom-auth-${_newUuidV4()}';
    }
    if (body != null) {
      request.headers['content-type'] = 'application/json';
      request.body = jsonEncode(body);
    }

    late final http.Response response;
    try {
      response = await http.Response.fromStream(
        await _httpClient.send(request),
      );
    } on Exception catch (error) {
      throw StateError('Fan Passport request $method $uri failed: $error');
    }

    final successful = response.statusCode >= 200 && response.statusCode < 300;
    if (!successful && !acceptedStatusCodes.contains(response.statusCode)) {
      // The body carries the service's own error code and message. Discarding
      // it turns every failure into "something went wrong", which is what made
      // an earlier 500 in this stack take a live probe to diagnose.
      final detail = response.body.trim().isEmpty
          ? ''
          : ' Body: ${response.body.trim()}';
      throw StateError(
        'Fan Passport request $method $uri returned HTTP '
        '${response.statusCode}.$detail',
      );
    }
    return _FanPassportResponse(response.statusCode, response.body);
  }

  FanPassportRecord? _parse(String body, String source) {
    if (body.trim().isEmpty) return null;
    final Object? decoded;
    try {
      decoded = jsonDecode(body);
    } on FormatException {
      throw StateError('Fan Passport returned malformed JSON for $source.');
    }
    if (decoded is! Map<String, Object?>) {
      throw StateError('Fan Passport returned an unexpected shape for $source.');
    }
    final fanId = decoded['fanId'];
    final displayName = decoded['displayName'];
    if (fanId is! String || fanId.isEmpty) {
      throw StateError('Fan Passport returned no fanId for $source.');
    }
    if (displayName is! String) {
      throw StateError('Fan Passport returned no displayName for $source.');
    }
    final createdAt = decoded['createdAt'];
    return FanPassportRecord(
      fanId: fanId,
      displayName: displayName,
      privacyMode: decoded['privacyMode'] as String?,
      publicKey: decoded['publicKey'] as String?,
      createdAt: createdAt is String ? DateTime.tryParse(createdAt) : null,
    );
  }
}

final class _FanPassportResponse {
  const _FanPassportResponse(this.statusCode, this.body);
  final int statusCode;
  final String body;
}
