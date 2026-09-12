import 'dart:convert';
import 'dart:io';

typedef JsonMap = Map<String, Object?>;

/// What one role in the export derives to.
///
/// Parsed from `RolePermissionExport`. The `grants` list is retained because
/// the node-grouped analysis needs the declared action each permission traces
/// back to; the comparison itself only needs [permissionIds].
class ExportedRolePermissions {
  const ExportedRolePermissions({
    required this.roleId,
    required this.permissionIds,
    required this.grants,
  });

  final String roleId;
  final List<String> permissionIds;
  final List<ExportedPermissionGrant> grants;

  Set<String> get permissionIdSet => permissionIds.toSet();

  factory ExportedRolePermissions.fromJson(JsonMap json) {
    final roleId = json['roleId'];
    if (roleId is! String || roleId.isEmpty) {
      throw const FormatException('RolePermissionExport.roleId must be set.');
    }
    return ExportedRolePermissions(
      roleId: roleId,
      permissionIds: _stringList(json['permissionIds'], 'permissionIds'),
      grants: List.unmodifiable([
        for (final grant in _objectList(json['grants'], 'grants'))
          ExportedPermissionGrant.fromJson(grant),
      ]),
    );
  }

  JsonMap toJson() => <String, Object?>{
    'roleId': roleId,
    'permissionIds': permissionIds,
    'grants': [for (final grant in grants) grant.toJson()],
  };
}

/// The declared action a permission traces back to.
class ExportedPermissionGrant {
  const ExportedPermissionGrant({
    required this.permissionId,
    required this.sourceKind,
    this.sourceActionId,
    this.workflowType,
  });

  final String permissionId;

  /// `transition`, `create_action`, or `governance`.
  final String sourceKind;

  /// The transition id or create-action id. Null for `governance`.
  final String? sourceActionId;

  /// The workflow that declared the action. Null for `governance`.
  final String? workflowType;

  factory ExportedPermissionGrant.fromJson(JsonMap json) {
    final permissionId = json['permissionId'];
    final sourceKind = json['sourceKind'];
    if (permissionId is! String || permissionId.isEmpty) {
      throw const FormatException(
        'RolePermissionGrant.permissionId must be set.',
      );
    }
    if (sourceKind is! String || sourceKind.isEmpty) {
      throw const FormatException(
        'RolePermissionGrant.sourceKind must be set.',
      );
    }
    return ExportedPermissionGrant(
      permissionId: permissionId,
      sourceKind: sourceKind,
      sourceActionId: _optionalString(json['sourceActionId']),
      workflowType: _optionalString(json['workflowType']),
    );
  }

  JsonMap toJson() => <String, Object?>{
    'permissionId': permissionId,
    'sourceKind': sourceKind,
    if (sourceActionId != null) 'sourceActionId': sourceActionId,
    if (workflowType != null) 'workflowType': workflowType,
  };
}

/// One derivation finding, kept verbatim.
///
/// Findings do not make the export fail -- the endpoint answers 200 either
/// way -- so the gate reports them and still compares the sets it was given.
class ExportedDerivationFinding {
  const ExportedDerivationFinding(this.raw);

  final JsonMap raw;

  String get code => '${raw['code']}';
  String get message => '${raw['message']}';
  String? get workflowType => _optionalString(raw['workflowType']);
  String? get transitionId => _optionalString(raw['transitionId']);

  String get sentence {
    final where = [
      if (workflowType != null) 'workflow `$workflowType`',
      if (transitionId != null) 'transition `$transitionId`',
    ].join(', ');
    return where.isEmpty ? '$code: $message' : '$code ($where): $message';
  }
}

/// The 200 body of `POST /v1/apps/{appId}/community-permission-exports`.
class CommunityPermissionExport {
  const CommunityPermissionExport({
    required this.appId,
    required this.groupId,
    required this.communityHandle,
    required this.systemAdminRole,
    required this.roles,
    required this.findings,
  });

  final String appId;
  final String groupId;
  final String communityHandle;

  /// The generated `<handle>-admin` role and its fixed governance set.
  /// Null when the vocabulary declares no system-admin template.
  final ExportedRolePermissions? systemAdminRole;

  /// Every package domain role. A role that derives nothing still appears,
  /// with an empty `permissionIds` -- that is a legitimate read-only-by-design
  /// outcome, **not** a finding, and the gate must never treat it as one.
  final List<ExportedRolePermissions> roles;

  final List<ExportedDerivationFinding> findings;

  factory CommunityPermissionExport.fromJson(JsonMap json) {
    final appId = json['appId'];
    final groupId = json['groupId'];
    final communityHandle = json['communityHandle'];
    if (appId is! String || groupId is! String || communityHandle is! String) {
      throw const FormatException(
        'A permission export must carry appId, groupId and communityHandle.',
      );
    }
    final rawSystemAdmin = json['systemAdminRole'];
    return CommunityPermissionExport(
      appId: appId,
      groupId: groupId,
      communityHandle: communityHandle,
      systemAdminRole: rawSystemAdmin == null
          ? null
          : ExportedRolePermissions.fromJson(
              _object(rawSystemAdmin, 'systemAdminRole'),
            ),
      roles: List.unmodifiable([
        for (final role in _objectList(json['roles'], 'roles'))
          ExportedRolePermissions.fromJson(role),
      ]),
      findings: List.unmodifiable([
        for (final finding in _objectList(json['findings'], 'findings'))
          ExportedDerivationFinding(finding),
      ]),
    );
  }

  /// Every role the export names, the system admin included.
  Iterable<ExportedRolePermissions> get allRoles sync* {
    final admin = systemAdminRole;
    if (admin != null) yield admin;
    yield* roles;
  }
}

/// Acquires a bearer token exactly the way
/// `apply_app_access_provisioning.dart` does for its own live calls --
/// client-credentials against Keycloak, cached until shortly before expiry.
class HttpPermissionExportClient {
  HttpPermissionExportClient({
    required this.baseUri,
    required this.tokenUri,
    required this.clientId,
    required this.clientSecret,
    required this.appId,
    HttpClient? httpClient,
    DateTime Function()? clock,
  }) : _httpClient = httpClient ?? HttpClient(),
       _ownsHttpClient = httpClient == null,
       _clock = clock ?? DateTime.now;

  final Uri baseUri;
  final Uri tokenUri;
  final String clientId;
  final String clientSecret;
  final String appId;
  final HttpClient _httpClient;
  final bool _ownsHttpClient;
  final DateTime Function() _clock;

  String? _accessToken;
  DateTime? _refreshAt;

  Future<CommunityPermissionExport> export(JsonMap request, {
    required String correlationId,
  }) async {
    final token = await loadAccessToken();
    final uri = _normalizedBase().resolve(
      'v1/apps/${Uri.encodeComponent(appId)}/community-permission-exports',
    );
    final httpRequest = await _httpClient.postUrl(uri);
    httpRequest.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
    httpRequest.headers.set('x-loom-correlation-id', correlationId);
    httpRequest.headers.contentType = ContentType.json;
    httpRequest.write(jsonEncode(request));

    final response = await httpRequest.close();
    final encoded = await utf8.decoder.bind(response).join();
    if (response.statusCode != HttpStatus.ok) {
      throw HttpException(
        'POST $uri returned HTTP ${response.statusCode}; body: '
        '${_truncate(encoded)}',
        uri: uri,
      );
    }
    final Object? decoded;
    try {
      decoded = jsonDecode(encoded);
    } on FormatException {
      throw HttpException(
        'POST $uri returned malformed JSON; body: ${_truncate(encoded)}',
        uri: uri,
      );
    }
    return CommunityPermissionExport.fromJson(_object(decoded, 'export'));
  }

  Future<String> loadAccessToken() async {
    final now = _clock();
    if (_accessToken case final token?
        when _refreshAt != null && now.isBefore(_refreshAt!)) {
      return token;
    }
    final request = await _httpClient.postUrl(tokenUri);
    request.headers.contentType = ContentType(
      'application',
      'x-www-form-urlencoded',
      charset: 'utf-8',
    );
    request.write(
      _formEncode(<String, String>{
        'grant_type': 'client_credentials',
        'client_id': clientId,
        'client_secret': clientSecret,
      }),
    );
    final response = await request.close();
    final encoded = await utf8.decoder.bind(response).join();
    if (response.statusCode != HttpStatus.ok) {
      throw HttpException(
        'Token endpoint returned HTTP ${response.statusCode}; body: '
        '${_truncate(encoded)}',
        uri: tokenUri,
      );
    }
    final decoded = jsonDecode(encoded);
    if (decoded is! Map ||
        decoded['access_token'] is! String ||
        (decoded['access_token'] as String).isEmpty ||
        decoded['expires_in'] is! int ||
        (decoded['expires_in'] as int) <= 0) {
      throw const FormatException('Token endpoint returned an incomplete token.');
    }
    final token = decoded['access_token'] as String;
    final lifetime = Duration(seconds: decoded['expires_in'] as int);
    final skew = lifetime > const Duration(seconds: 30)
        ? const Duration(seconds: 30)
        : Duration(microseconds: lifetime.inMicroseconds ~/ 2);
    _accessToken = token;
    _refreshAt = now.add(lifetime - skew);
    return token;
  }

  void close({bool force = false}) {
    if (_ownsHttpClient) _httpClient.close(force: force);
  }

  Uri _normalizedBase() {
    if (!baseUri.hasScheme || baseUri.host.isEmpty) {
      throw ArgumentError.value(baseUri, 'baseUri', 'must be an absolute URI');
    }
    final path = baseUri.path.endsWith('/') ? baseUri.path : '${baseUri.path}/';
    return baseUri.replace(path: path, query: null, fragment: null);
  }
}

JsonMap _object(Object? value, String field) {
  if (value is! Map) throw FormatException('$field must be an object.');
  return Map<String, Object?>.from(value);
}

List<JsonMap> _objectList(Object? value, String field) {
  if (value is! List) throw FormatException('$field must be a list.');
  return [
    for (final item in value)
      if (item is Map)
        Map<String, Object?>.from(item)
      else
        throw FormatException('$field must contain objects.'),
  ];
}

List<String> _stringList(Object? value, String field) {
  if (value is! List || value.any((item) => item is! String)) {
    throw FormatException('$field must be a list of strings.');
  }
  return List.unmodifiable(value.cast<String>());
}

String? _optionalString(Object? value) {
  if (value == null) return null;
  return value is String ? value : '$value';
}

String _formEncode(Map<String, String> values) => values.entries
    .map(
      (entry) =>
          '${Uri.encodeQueryComponent(entry.key)}='
          '${Uri.encodeQueryComponent(entry.value)}',
    )
    .join('&');

String _truncate(String body) {
  const max = 2048;
  return body.length <= max ? body : '${body.substring(0, max)}...';
}
