part of '../loom_communities_app_shell.dart';

/// Resolves the auth API for a community without changing the unconfigured
/// local path.
///
/// A remote configuration is a production input installed by
/// [configureLoomRemoteServicesFromEnvironment]. A test can replace that
/// selection with [overrideLoomRemoteServiceConfigurationForTesting], while
/// [overrideLoomAuthSessionForTesting] remains only a session test seam.
LoomAuthApi resolveLoomAuthApiForCommunity({
  required String communityId,
  required String communityExtensionId,
  required List<LoomActorIdentity> Function(String communityExtensionId)
  actorIdentityResolver,
  required LoomExperienceDefinition Function(String communityExtensionId)
  experienceResolver,
}) {
  final configuration = _loomRemoteServiceConfiguration;
  if (configuration == null) {
    return LocalAuthApi(
      actorIdentityResolver: actorIdentityResolver,
      experienceResolver: experienceResolver,
    );
  }
  return createRemoteLoomAuthApiForConfiguration(
    configuration: configuration,
    communityId: communityId,
    communityExtensionId: communityExtensionId,
    actorIdentityResolver: actorIdentityResolver,
  );
}

/// Builds the real auth implementation for one installed community.
///
/// This explicit factory is useful to production hosts that own their remote
/// configuration directly. It never consults a test override.
RemoteLoomAuthApi createRemoteLoomAuthApiForConfiguration({
  required LoomRemoteServiceConfiguration configuration,
  required String communityId,
  required String communityExtensionId,
  required List<LoomActorIdentity> Function(String communityExtensionId)
  actorIdentityResolver,
  http.Client? httpClient,
}) => RemoteLoomAuthApi(
  session: configuration.session,
  appAccessBaseUri: configuration.appAccessBaseUri,
  fanPassportBaseUri: configuration.fanPassportBaseUri,
  appId: configuration.appId,
  communityId: communityId,
  communityExtensionId: communityExtensionId,
  communityGroupId: configuration.groupIdForCommunity(communityId),
  actorIdentityResolver: actorIdentityResolver,
  httpClient: httpClient,
);

/// A [LoomAuthApi] backed by the deployed Loom identity and membership stack.
///
/// A remote account always belongs to the fan in [session]'s bearer token;
/// this implementation never turns the demo account picker into an
/// impersonation mechanism. Every App Access request carries an independently
/// generated UUID correlation id and every mutating request carries an
/// idempotency key.
class RemoteLoomAuthApi implements LoomAuthApi {
  RemoteLoomAuthApi({
    required LoomAuthSession session,
    required Uri appAccessBaseUri,
    required Uri fanPassportBaseUri,
    required String appId,
    required String communityId,
    required String communityExtensionId,
    required String? communityGroupId,
    required List<LoomActorIdentity> Function(String communityExtensionId)
    actorIdentityResolver,
    http.Client? httpClient,
  }) : _session = session,
       _appAccessBaseUri = _normaliseBaseUri(appAccessBaseUri),
       _fanPassportBaseUri = _normaliseBaseUri(fanPassportBaseUri),
       _appId = _requireNonEmptyRemoteValue(appId, 'appId'),
       _communityId = _requireNonEmptyRemoteValue(communityId, 'communityId'),
       _communityExtensionId = _requireNonEmptyRemoteValue(
         communityExtensionId,
         'communityExtensionId',
       ),
       _communityGroupId = communityGroupId,
       _actorIdentityResolver = actorIdentityResolver,
       _httpClient = httpClient ?? http.Client();

  final LoomAuthSession _session;
  final Uri _appAccessBaseUri;
  final Uri _fanPassportBaseUri;
  final String _appId;
  final String _communityId;
  final String _communityExtensionId;
  final String? _communityGroupId;
  final List<LoomActorIdentity> Function(String communityExtensionId)
  _actorIdentityResolver;
  final http.Client _httpClient;

  LoomSession? _currentSession;

  /// The real identity-provider session used by this community auth API.
  ///
  /// The app's secure-login screen owns interactive redirects; this API only
  /// consumes the resulting bearer session for account and membership calls.
  LoomAuthSession get session => _session;

  @override
  LoomSession? get currentSession => _currentSession;

  @override
  Future<List<LoomAccount>> listAccounts({
    required String communityExtensionId,
  }) async {
    _requireCommunityExtensionId(communityExtensionId);
    final memberships = await _listGroupMembers();
    return Future.wait(
      memberships.map((membership) async {
        final passport = await _getPassport(membership.fanId);
        if (passport == null) {
          throw StateError(
            'App Access membership for fan "${membership.fanId}" in '
            'community "$_communityId" has no Fan Passport record.',
          );
        }
        return _accountFromMembership(membership, passport: passport);
      }),
    );
  }

  @override
  Future<LoomSession> signIn({required String accountId}) async {
    final fanId = await _fanIdFromCurrentSession();
    if (accountId != fanId) {
      throw LoomAuthException(
        code: LoomAuthErrorCode.accountNotFound,
        message:
            'The authenticated Loom identity cannot sign in as account '
            '"$accountId". Sign in with that person’s identity provider '
            'session instead.',
      );
    }
    final membership = await _getGroupMembership(fanId);
    if (membership == null) {
      throw LoomAuthException(
        code: LoomAuthErrorCode.accountNotFound,
        message:
            'Account "$accountId" has no membership in community '
            '"$_communityId".',
      );
    }
    final passport = await _getPassport(fanId);
    if (passport == null) {
      throw StateError(
        'Authenticated fan "$fanId" has a community membership but no Fan '
        'Passport record.',
      );
    }
    final account = _accountFromMembership(membership, passport: passport);
    if (account.status == MembershipStatus.pendingApproval) {
      throw const LoomAuthException(
        code: LoomAuthErrorCode.accountPendingApproval,
        message: 'This account is pending approval and cannot sign in yet.',
      );
    }
    final session = LoomSession(account: account);
    _currentSession = session;
    return session;
  }

  @override
  Future<LoomSignUpResult> signUp({
    required String communityExtensionId,
    required String displayName,
    required String roleId,
  }) async {
    _requireCommunityExtensionId(communityExtensionId);
    if (displayName.trim().isEmpty) {
      throw const LoomAuthException(
        code: LoomAuthErrorCode.invalidDisplayName,
        message: 'A display name is required to sign up.',
      );
    }
    final identity = _actorIdentityForRole(roleId);
    if (identity.accessMode == LoomActorIdentityAccessMode.requiresInvite) {
      throw const LoomAuthException(
        code: LoomAuthErrorCode.roleRequiresInvite,
        message:
            'Direct sign-up is not available for this actor identity. Redeem '
            'a community invite instead.',
      );
    }

    final fanId = await _fanIdFromCurrentSession();
    var passport = await _getPassport(fanId);
    if (passport == null) {
      passport = await _createPassport(displayName.trim());
      if (passport.fanId != fanId) {
        throw StateError(
          'Fan Passport created "${passport.fanId}" for authenticated fan '
          '"$fanId". The identity service must create the passport for the '
          'bearer-token fan before community signup can continue.',
        );
      }
    }

    final desiredState =
        identity.accessMode == LoomActorIdentityAccessMode.requiresApproval
        ? 'requested'
        : 'active';
    final membership = await _setGroupMembership(
      fanId: fanId,
      roleIds: [roleId],
      state: desiredState,
    );
    final account = _accountFromMembership(membership, passport: passport);
    final expectedStatus = desiredState == 'active'
        ? MembershipStatus.active
        : MembershipStatus.pendingApproval;
    if (account.status != expectedStatus) {
      throw StateError(
        'App Access returned membership state "${membership.state}" for '
        'signup role "$roleId"; expected "$desiredState".',
      );
    }

    if (account.status == MembershipStatus.pendingApproval) {
      return LoomPendingApprovalSignUpResult(account: account);
    }
    final result = LoomActiveSignUpResult(account: account);
    _currentSession = result;
    return result;
  }

  @override
  Future<LoomSession> redeemInvite({
    required String code,
    required String displayName,
  }) {
    throw UnimplementedError(
      'redeemInvite is not backed remotely: App Access membership requests '
      'and decisions have no invite-code lookup or redemption endpoint. A '
      'real invitation service that resolves a code to a community and role '
      'is required.',
    );
  }

  @override
  Future<LoomCommunityInvite> issueInvite({
    required String roleId,
    required String issuedByAccountId,
  }) {
    throw UnimplementedError(
      'issueInvite is not backed remotely: App Access can create membership '
      'requests and decide them, but it has no endpoint to mint, persist, or '
      'address an invite code. A real invitation service is required.',
    );
  }

  @override
  Future<LoomAccount> approveAccount({required String accountId}) async {
    final approver = _currentSession?.account;
    if (approver == null || approver.status != MembershipStatus.active) {
      throw const LoomAuthException(
        code: LoomAuthErrorCode.membershipManagementUnauthorized,
        message: 'An active admin account must approve memberships.',
      );
    }

    final pending = await _getGroupMembership(accountId);
    if (pending == null) {
      throw LoomAuthException(
        code: LoomAuthErrorCode.accountNotFound,
        message: 'Account "$accountId" was not found.',
      );
    }
    if (_membershipStatusFor(pending.state) !=
        MembershipStatus.pendingApproval) {
      throw LoomAuthException(
        code: LoomAuthErrorCode.accountNotPendingApproval,
        message: 'Account "$accountId" is not pending approval.',
      );
    }
    final roleId = _onlyRoleId(pending);
    final approved = await _decideMembership(
      fanId: accountId,
      decision: 'approve',
      roleIds: [roleId],
    );
    final passport = await _getPassport(accountId);
    if (passport == null) {
      throw StateError(
        'Approved membership account "$accountId" has no Fan Passport '
        'record.',
      );
    }
    final account = _accountFromMembership(approved, passport: passport);
    if (account.status != MembershipStatus.active) {
      throw StateError(
        'App Access returned membership state "${approved.state}" after '
        'approving account "$accountId".',
      );
    }
    return account;
  }

  @override
  Future<void> signOut() async {
    await _session.logout();
    _currentSession = null;
  }

  LoomActorIdentity _actorIdentityForRole(String roleId) {
    for (final identity in _actorIdentityResolver(_communityExtensionId)) {
      if (identity.roleId == roleId) return identity;
    }
    throw LoomAuthException(
      code: LoomAuthErrorCode.roleNotFound,
      message:
          'Role "$roleId" is not declared by community '
          '"$_communityExtensionId".',
    );
  }

  void _requireCommunityExtensionId(String communityExtensionId) {
    if (communityExtensionId == _communityExtensionId) return;
    throw ArgumentError.value(
      communityExtensionId,
      'communityExtensionId',
      'does not match this remote auth API community '
          '"$_communityExtensionId"',
    );
  }

  String get _groupId {
    final groupId = _communityGroupId;
    if (groupId != null && groupId.trim().isNotEmpty) return groupId;
    throw StateError(
      'Remote Loom auth is configured for canonical community "$_communityId" '
      'but LOOM_COMMUNITY_GROUP_IDS has no App Access group id for it. Use '
      'the server-returned mapping shared with the workflow service.',
    );
  }

  Future<String> _fanIdFromCurrentSession() async {
    final accessToken = await _session.currentAccessToken();
    final parts = accessToken.split('.');
    if (parts.length != 3) {
      throw StateError(
        'The Loom access token is not a compact JWT and cannot identify the '
        'authenticated fan.',
      );
    }
    try {
      final payload = utf8.decode(
        base64Url.decode(base64Url.normalize(parts[1])),
      );
      final decoded = jsonDecode(payload);
      if (decoded is! Map ||
          decoded['fanId'] is! String ||
          (decoded['fanId'] as String).trim().isEmpty) {
        throw const FormatException('fanId claim is missing');
      }
      return decoded['fanId'] as String;
    } on FormatException {
      throw StateError(
        'The Loom access token does not contain a non-empty fanId claim.',
      );
    }
  }

  Future<List<_RemoteGroupMembership>> _listGroupMembers() async {
    final memberships = <_RemoteGroupMembership>[];
    String? cursor;
    do {
      final queryParameters = <String, String>{'limit': '100'};
      if (cursor != null) queryParameters['cursor'] = cursor;
      final response = await _request(
        method: 'GET',
        uri: _appAccessUri(
          'groups',
          _groupId,
          'members',
        ).replace(queryParameters: queryParameters),
      );
      final body = _requiredObject(
        response,
        'App Access group-members response',
      );
      final items = body['items'];
      if (items is! List) {
        throw StateError(
          'App Access group-members response must contain an items array.',
        );
      }
      memberships.addAll(
        items.map((item) => _parseMembership(item, 'App Access group member')),
      );
      cursor = _nextPageCursor(body);
    } while (cursor != null);
    return List.unmodifiable(memberships);
  }

  Future<_RemoteGroupMembership?> _getGroupMembership(String fanId) async {
    final response = await _request(
      method: 'GET',
      uri: _appAccessUri('groups', _groupId, 'members', fanId),
      acceptedStatusCodes: const {404},
    );
    if (response.statusCode == 404) return null;
    return _parseMembership(
      _requiredObject(response, 'App Access group-membership response'),
      'App Access group membership',
    );
  }

  Future<_RemoteGroupMembership> _setGroupMembership({
    required String fanId,
    required List<String> roleIds,
    required String state,
  }) async {
    final response = await _request(
      method: 'PUT',
      uri: _appAccessUri('groups', _groupId, 'members', fanId),
      body: <String, Object?>{'roleIds': roleIds, 'state': state},
      mutating: true,
    );
    return _parseMembership(
      _requiredObject(response, 'App Access membership update response'),
      'App Access membership update',
    );
  }

  Future<_RemoteGroupMembership> _decideMembership({
    required String fanId,
    required String decision,
    required List<String> roleIds,
  }) async {
    final response = await _request(
      method: 'POST',
      uri: _appAccessUri(
        'groups',
        _groupId,
        'membership-requests',
        fanId,
        'decision',
      ),
      body: <String, Object?>{'decision': decision, 'roleIds': roleIds},
      mutating: true,
    );
    return _parseMembership(
      _requiredObject(response, 'App Access membership-decision response'),
      'App Access membership decision',
    );
  }

  Future<_RemotePassport?> _getPassport(String fanId) async {
    final response = await _request(
      method: 'GET',
      uri: _fanPassportUri(fanId),
      acceptedStatusCodes: const {404},
    );
    if (response.statusCode == 404) return null;
    return _parsePassport(
      _requiredObject(response, 'Fan Passport response'),
      'Fan Passport response',
    );
  }

  Future<_RemotePassport> _createPassport(String displayName) async {
    final response = await _request(
      method: 'POST',
      uri: _fanPassportUri(),
      body: <String, Object?>{'displayName': displayName},
      mutating: true,
      expectedStatusCodes: const {201},
    );
    return _parsePassport(
      _requiredObject(response, 'Fan Passport create response'),
      'Fan Passport create response',
    );
  }

  LoomAccount _accountFromMembership(
    _RemoteGroupMembership membership, {
    required _RemotePassport passport,
  }) {
    if (membership.appId != _appId || membership.groupId != _groupId) {
      throw StateError(
        'App Access returned membership for app "${membership.appId}" and '
        'group "${membership.groupId}", not configured app "$_appId" and '
        'group "$_groupId".',
      );
    }
    if (membership.fanId != passport.fanId) {
      throw StateError(
        'App Access membership fan "${membership.fanId}" does not match '
        'Fan Passport "${passport.fanId}".',
      );
    }
    return LoomAccount(
      accountId: membership.fanId,
      displayName: passport.displayName,
      roleId: _onlyRoleId(membership),
      status: _membershipStatusFor(membership.state),
    );
  }

  String _onlyRoleId(_RemoteGroupMembership membership) {
    if (membership.roleIds.length == 1 &&
        membership.roleIds.single.isNotEmpty) {
      return membership.roleIds.single;
    }
    throw UnimplementedError(
      'LoomAuthApi cannot represent App Access membership for fan '
      '"${membership.fanId}" because it has ${membership.roleIds.length} '
      'role ids. LoomAccount currently requires exactly one role id.',
    );
  }

  MembershipStatus _membershipStatusFor(String state) {
    return switch (state) {
      'active' => MembershipStatus.active,
      'requested' || 'pending' => MembershipStatus.pendingApproval,
      _ => throw UnimplementedError(
        'LoomAuthApi cannot map App Access membership state "$state". It '
        'supports active and pending membership requests only.',
      ),
    };
  }

  _RemoteGroupMembership _parseMembership(Object? value, String source) {
    if (value is! Map) {
      throw StateError('$source must be a JSON object.');
    }
    final object = Map<String, Object?>.from(value);
    final roleValues = object['roleIds'];
    if (roleValues is! List || !roleValues.every((role) => role is String)) {
      throw StateError('$source must contain a roleIds string array.');
    }
    return _RemoteGroupMembership(
      appId: _requiredString(object, 'appId', source),
      groupId: _requiredString(object, 'groupId', source),
      fanId: _requiredString(object, 'fanId', source),
      roleIds: List.unmodifiable(roleValues.cast<String>()),
      state: _requiredString(object, 'state', source),
    );
  }

  String? _nextPageCursor(Map<String, Object?> body) {
    final pageInfo = body['pageInfo'];
    if (pageInfo is! Map) {
      throw StateError(
        'App Access group-members response must contain a pageInfo object.',
      );
    }
    final page = Map<String, Object?>.from(pageInfo);
    final hasMore = page['hasMore'];
    final nextCursor = page['nextCursor'];
    if (hasMore is! bool ||
        (nextCursor != null &&
            (nextCursor is! String || nextCursor.trim().isEmpty))) {
      throw StateError(
        'App Access group-members response contains an invalid pageInfo '
        'object.',
      );
    }
    if (!hasMore) return null;
    if (nextCursor is String) return nextCursor;
    throw StateError(
      'App Access group-members response hasMore=true without nextCursor.',
    );
  }

  _RemotePassport _parsePassport(Object value, String source) {
    final object = Map<String, Object?>.from(value as Map);
    return _RemotePassport(
      fanId: _requiredString(object, 'fanId', source),
      displayName: _requiredString(object, 'displayName', source),
    );
  }

  Uri _appAccessUri(
    String first,
    String second,
    String third, [
    String? fourth,
    String? fifth,
  ]) {
    final segments = <String>['v1', 'apps', _appId, first, second, third];
    if (fourth != null) segments.add(fourth);
    if (fifth != null) segments.add(fifth);
    return _uriFromSegments(_appAccessBaseUri, segments);
  }

  Uri _fanPassportUri([String? fanId]) =>
      _uriFromSegments(_fanPassportBaseUri, [
        if (fanId == null) ...[
          'v1',
          'fan-passports',
        ] else ...[
          'v1',
          'fan-passports',
          fanId,
        ],
      ]);

  Future<_RemoteHttpResponse> _request({
    required String method,
    required Uri uri,
    Object? body,
    bool mutating = false,
    Set<int> acceptedStatusCodes = const {},
    Set<int>? expectedStatusCodes,
  }) async {
    final accessToken = await _session.currentAccessToken();
    final request = http.Request(method, uri)
      ..headers['authorization'] = 'Bearer $accessToken'
      ..headers['accept'] = 'application/json'
      ..headers['x-loom-correlation-id'] = _newUuidV4();
    if (mutating) {
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
      throw StateError('Remote auth request $method $uri failed: $error');
    }
    final successful =
        expectedStatusCodes?.contains(response.statusCode) ??
        (response.statusCode >= 200 && response.statusCode < 300);
    if (!successful && !acceptedStatusCodes.contains(response.statusCode)) {
      throw StateError(
        'Remote auth request $method $uri returned HTTP '
        '${response.statusCode}.',
      );
    }
    if (response.body.trim().isEmpty) {
      return _RemoteHttpResponse(response.statusCode, null);
    }
    try {
      return _RemoteHttpResponse(
        response.statusCode,
        jsonDecode(response.body),
      );
    } on FormatException {
      throw StateError(
        'Remote auth request $method $uri returned malformed JSON.',
      );
    }
  }
}

class _RemoteHttpResponse {
  const _RemoteHttpResponse(this.statusCode, this.body);

  final int statusCode;
  final Object? body;
}

class _RemoteGroupMembership {
  const _RemoteGroupMembership({
    required this.appId,
    required this.groupId,
    required this.fanId,
    required this.roleIds,
    required this.state,
  });

  final String appId;
  final String groupId;
  final String fanId;
  final List<String> roleIds;
  final String state;
}

class _RemotePassport {
  const _RemotePassport({required this.fanId, required this.displayName});

  final String fanId;
  final String displayName;
}

Map<String, Object?> _requiredObject(
  _RemoteHttpResponse response,
  String source,
) {
  final body = response.body;
  if (body is Map) return Map<String, Object?>.from(body);
  throw StateError('$source must be a JSON object.');
}

String _requiredString(
  Map<String, Object?> object,
  String field,
  String source,
) {
  final value = object[field];
  if (value is String && value.trim().isNotEmpty) return value;
  throw StateError('$source must contain non-empty string "$field".');
}

String _requireNonEmptyRemoteValue(String value, String name) {
  if (value.trim().isNotEmpty) return value;
  throw ArgumentError.value(value, name, 'must not be empty');
}

Uri _normaliseBaseUri(Uri uri) {
  if (!uri.hasScheme || uri.host.isEmpty) {
    throw ArgumentError.value(uri, 'baseUri', 'must be an absolute URI');
  }
  return uri.path.endsWith('/') ? uri : uri.replace(path: '${uri.path}/');
}

Uri _uriFromSegments(Uri baseUri, List<String> segments) =>
    baseUri.resolve(segments.map(Uri.encodeComponent).join('/'));

String _newUuidV4() {
  final bytes = List<int>.generate(16, (_) => Random.secure().nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  final encoded = bytes
      .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
      .join();
  return '${encoded.substring(0, 8)}-${encoded.substring(8, 12)}-'
      '${encoded.substring(12, 16)}-${encoded.substring(16, 20)}-'
      '${encoded.substring(20)}';
}
