part of '../loom_communities_app_shell.dart';

/// App Access client for the authenticated fan's community memberships.
///
/// This is deliberately separate from [RemoteLoomAuthApi]. A fan can belong
/// to more than one installed community, so the list is fetched once for the
/// bearer session and shared by the per-community auth APIs that consume it.
final class FanCommunityMembershipClient {
  FanCommunityMembershipClient({
    required Uri baseUri,
    required LoomAuthSession session,
    http.Client? httpClient,
  }) : _baseUri = _normaliseBaseUri(baseUri),
       _session = session,
       _httpClient = httpClient ?? http.Client();

  final Uri _baseUri;
  final LoomAuthSession _session;
  final http.Client _httpClient;

  /// Calls `GET /v1/fans/{fanId}/communities` for the bearer-token fan.
  ///
  /// [appId] narrows the server response to the Communities application; the
  /// service remains the authority for every returned group, role, and state.
  Future<List<FanCommunityMembership>> listFanCommunities({
    required String fanId,
    String? appId,
  }) async {
    final response = await _send(
      method: 'GET',
      uri: _baseUri
          .resolve('v1/fans/${Uri.encodeComponent(fanId)}/communities')
          .replace(
            queryParameters: appId == null
                ? null
                : <String, String>{'appId': appId},
          ),
    );
    final Object? decoded;
    try {
      decoded = jsonDecode(response.body);
    } on FormatException {
      throw StateError(
        'App Access returned malformed JSON for '
        'GET v1/fans/$fanId/communities.',
      );
    }
    if (decoded is! Map) {
      throw StateError(
        'App Access returned an unexpected shape for '
        'GET v1/fans/$fanId/communities.',
      );
    }
    final body = Map<String, Object?>.from(decoded);
    final values = body['communities'];
    if (values is! List) {
      throw StateError(
        'App Access response for GET v1/fans/$fanId/communities must '
        'contain a communities array.',
      );
    }
    return List<FanCommunityMembership>.unmodifiable(
      values.map(
        (value) =>
            _parseMembership(value, source: 'GET v1/fans/$fanId/communities'),
      ),
    );
  }

  Future<http.Response> _send({
    required String method,
    required Uri uri,
  }) async {
    final accessToken = await _session.currentAccessToken();
    final request = http.Request(method, uri)
      ..headers['authorization'] = 'Bearer $accessToken'
      ..headers['accept'] = 'application/json'
      ..headers['x-loom-correlation-id'] = _newUuidV4();

    late final http.Response response;
    try {
      response = await http.Response.fromStream(
        await _httpClient.send(request),
      );
    } on Exception catch (error) {
      throw StateError('App Access request $method $uri failed: $error');
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final detail = response.body.trim().isEmpty
          ? ''
          : ' Body: ${response.body.trim()}';
      throw StateError(
        'App Access request $method $uri returned HTTP '
        '${response.statusCode}.$detail',
      );
    }
    return response;
  }

  FanCommunityMembership _parseMembership(
    Object? value, {
    required String source,
  }) {
    if (value is! Map) {
      throw StateError('$source contains a non-object community membership.');
    }
    final object = Map<String, Object?>.from(value);
    final roleValues = object['roleIds'];
    if (roleValues is! List || !roleValues.every((role) => role is String)) {
      throw StateError('$source must contain a roleIds string array.');
    }
    final joinedAtValue = _requiredString(object, 'joinedAt', source);
    final joinedAt = DateTime.tryParse(joinedAtValue);
    if (joinedAt == null) {
      throw StateError('$source must contain an ISO-8601 joinedAt timestamp.');
    }
    return FanCommunityMembership(
      appId: _requiredString(object, 'appId', source),
      groupId: _requiredString(object, 'groupId', source),
      fanId: _requiredString(object, 'fanId', source),
      roleIds: List<String>.unmodifiable(roleValues.cast<String>()),
      state: _assignmentStateFromWire(
        _requiredString(object, 'state', source),
        source: source,
      ),
      joinedAt: joinedAt,
      communityId: _requiredString(object, 'communityId', source),
      displayName: _requiredString(object, 'displayName', source),
    );
  }
}

AssignmentState _assignmentStateFromWire(
  String value, {
  required String source,
}) => switch (value) {
  'requested' => AssignmentState.requested,
  'active' => AssignmentState.active,
  'suspended' => AssignmentState.suspended,
  'revoked' => AssignmentState.revoked,
  'rejected' => AssignmentState.rejected,
  _ => throw StateError('$source contains unknown membership state "$value".'),
};
