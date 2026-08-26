import 'dart:convert';
import 'dart:io';

/// App Access operations required by the workflow service.
abstract interface class AppAccessDecisionClient {
  Future<bool> checkAccess({
    required String fanId,
    required String appId,
    required String permissionId,
    required String groupId,
    required String correlationId,
  });

  /// Resolves every effective role held by a fan for an app and community.
  Future<Set<String>> resolveRoleIds({
    required String fanId,
    required String appId,
    required String groupId,
    required String correlationId,
  });

  /// Whether [fanId] holds an active membership in [groupId].
  ///
  /// Separate from [resolveRoleIds] because membership and roles are different
  /// questions and a community may answer them differently. A `membersOnly`
  /// workflow names no role at all, so inferring membership from a non-empty
  /// role set would exclude exactly those members a community chose not to give
  /// a role to.
  Future<bool> hasActiveMembership({
    required String fanId,
    required String appId,
    required String groupId,
    required String correlationId,
  });
}

/// Failure to obtain a well-formed authorization decision from App Access.
class AppAccessDecisionException implements Exception {
  const AppAccessDecisionException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

/// Minimal HTTP client for App Access decisions and effective permissions.
class HttpAppAccessDecisionClient implements AppAccessDecisionClient {
  static const Duration defaultTokenRefreshSkew = Duration(seconds: 30);

  HttpAppAccessDecisionClient({
    required Uri baseUri,
    required Uri tokenUri,
    required String clientId,
    required String clientSecret,
    this.tokenRefreshSkew = defaultTokenRefreshSkew,
    HttpClient? httpClient,
    DateTime Function()? clock,
  }) : _baseUri = _normalizeBaseUri(baseUri),
       _tokenUri = _requireAbsoluteUri(tokenUri, 'tokenUri'),
       _clientId = _requireNonEmpty(clientId, 'clientId'),
       _clientSecret = _requireNonEmpty(clientSecret, 'clientSecret'),
       _httpClient = httpClient ?? HttpClient(),
       _ownsHttpClient = httpClient == null,
       _clock = clock ?? DateTime.now {
    if (tokenRefreshSkew.isNegative) {
      throw ArgumentError.value(
        tokenRefreshSkew,
        'tokenRefreshSkew',
        'must not be negative',
      );
    }
  }

  final Uri _baseUri;
  final Uri _tokenUri;
  final String _clientId;
  final String _clientSecret;
  final Duration tokenRefreshSkew;
  final HttpClient _httpClient;
  final bool _ownsHttpClient;
  final DateTime Function() _clock;

  String? _cachedAccessToken;
  DateTime? _tokenRefreshAt;
  Future<String>? _refreshingToken;

  @override
  Future<bool> checkAccess({
    required String fanId,
    required String appId,
    required String permissionId,
    required String groupId,
    required String correlationId,
  }) async {
    final accessToken = await _loadAccessToken();
    final request = await _httpClient.postUrl(
      _baseUri.resolve('v1/access-decisions'),
    );
    request.headers.contentType = ContentType.json;
    request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $accessToken');
    request.headers.set('x-loom-correlation-id', correlationId);
    request.write(
      jsonEncode({
        'fanId': fanId,
        'appId': appId,
        'permissionId': permissionId,
        'groupId': groupId,
      }),
    );

    final response = await request.close();
    final encoded = await utf8.decoder.bind(response).join();
    if (response.statusCode != HttpStatus.ok) {
      throw AppAccessDecisionException(
        'App Access returned HTTP ${response.statusCode}.',
        statusCode: response.statusCode,
      );
    }

    final Object? decoded;
    try {
      decoded = jsonDecode(encoded);
    } on FormatException {
      throw const AppAccessDecisionException(
        'App Access returned a malformed access decision.',
      );
    }
    if (decoded is! Map<String, dynamic> ||
        decoded['allowed'] is! bool ||
        decoded['fanId'] != fanId ||
        decoded['appId'] != appId ||
        decoded['permissionId'] != permissionId ||
        decoded['groupId'] != groupId) {
      throw const AppAccessDecisionException(
        'App Access returned a malformed access decision.',
      );
    }
    return decoded['allowed'] as bool;
  }

  @override
  Future<Set<String>> resolveRoleIds({
    required String fanId,
    required String appId,
    required String groupId,
    required String correlationId,
  }) async {
    final accessToken = await _loadAccessToken();
    final request = await _httpClient.getUrl(
      _baseUri
          .resolve(
            'v1/apps/${Uri.encodeComponent(appId)}/effective-permissions/'
            '${Uri.encodeComponent(fanId)}',
          )
          .replace(queryParameters: {'groupId': groupId}),
    );
    request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $accessToken');
    request.headers.set('x-loom-correlation-id', correlationId);

    final response = await request.close();
    final encoded = await utf8.decoder.bind(response).join();
    if (response.statusCode != HttpStatus.ok) {
      throw AppAccessDecisionException(
        'App Access returned HTTP ${response.statusCode}.',
        statusCode: response.statusCode,
      );
    }

    final Object? decoded;
    try {
      decoded = jsonDecode(encoded);
    } on FormatException {
      throw const AppAccessDecisionException(
        'App Access returned malformed effective permissions.',
      );
    }
    if (decoded is! Map<String, dynamic> ||
        decoded['fanId'] != fanId ||
        decoded['appId'] != appId ||
        decoded['roleIds'] is! List<dynamic>) {
      throw const AppAccessDecisionException(
        'App Access returned malformed effective permissions.',
      );
    }

    final roleIds = <String>{};
    for (final roleId in decoded['roleIds'] as List<dynamic>) {
      if (roleId is! String) {
        throw const AppAccessDecisionException(
          'App Access returned malformed effective permissions.',
        );
      }
      roleIds.add(roleId);
    }
    return roleIds;
  }

  @override
  Future<bool> hasActiveMembership({
    required String fanId,
    required String appId,
    required String groupId,
    required String correlationId,
  }) async {
    final accessToken = await _loadAccessToken();
    final request = await _httpClient.getUrl(
      _baseUri.resolve(
        'v1/apps/${Uri.encodeComponent(appId)}/groups/'
        '${Uri.encodeComponent(groupId)}/members/${Uri.encodeComponent(fanId)}',
      ),
    );
    request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $accessToken');
    request.headers.set('x-loom-correlation-id', correlationId);

    final response = await request.close();
    final encoded = await utf8.decoder.bind(response).join();

    // Not a member is an ordinary answer, not a failure. Letting the 404 throw
    // would make every non-member read fail closed with a 503 instead of an
    // empty list, which is the same visible outcome for the wrong reason.
    if (response.statusCode == HttpStatus.notFound) return false;
    if (response.statusCode != HttpStatus.ok) {
      throw AppAccessDecisionException(
        'App Access returned HTTP ${response.statusCode}.',
        statusCode: response.statusCode,
      );
    }

    final Object? decoded;
    try {
      decoded = jsonDecode(encoded);
    } on FormatException {
      throw const AppAccessDecisionException(
        'App Access returned a malformed group membership.',
      );
    }
    if (decoded is! Map<String, dynamic> ||
        decoded['fanId'] != fanId ||
        decoded['groupId'] != groupId) {
      throw const AppAccessDecisionException(
        'App Access returned a malformed group membership.',
      );
    }
    return decoded['state'] == 'active';
  }

  Future<String> _loadAccessToken() async {
    if (_tokenIsFresh(_clock())) return _cachedAccessToken!;

    final inFlight = _refreshingToken;
    if (inFlight != null) return inFlight;

    final refresh = _fetchAndCacheAccessToken();
    _refreshingToken = refresh;
    try {
      return await refresh;
    } finally {
      if (identical(_refreshingToken, refresh)) {
        _refreshingToken = null;
      }
    }
  }

  bool _tokenIsFresh(DateTime now) {
    final refreshAt = _tokenRefreshAt;
    return _cachedAccessToken != null &&
        refreshAt != null &&
        now.isBefore(refreshAt);
  }

  Future<String> _fetchAndCacheAccessToken() async {
    try {
      final request = await _httpClient.postUrl(_tokenUri);
      request.headers.contentType = ContentType(
        'application',
        'x-www-form-urlencoded',
        charset: 'utf-8',
      );
      request.write(
        _formEncode({
          'grant_type': 'client_credentials',
          'client_id': _clientId,
          'client_secret': _clientSecret,
        }),
      );

      final response = await request.close();
      final encoded = await utf8.decoder.bind(response).join();
      if (response.statusCode != HttpStatus.ok) {
        throw AppAccessDecisionException(
          'Keycloak token endpoint returned HTTP ${response.statusCode}.',
          statusCode: response.statusCode,
        );
      }

      final Object? decoded;
      try {
        decoded = jsonDecode(encoded);
      } on FormatException {
        throw const AppAccessDecisionException(
          'Keycloak token endpoint returned a malformed token response.',
        );
      }
      if (decoded is! Map<String, dynamic> ||
          decoded['access_token'] is! String ||
          (decoded['access_token'] as String).isEmpty ||
          decoded['expires_in'] is! int ||
          (decoded['expires_in'] as int) <= 0) {
        throw const AppAccessDecisionException(
          'Keycloak token endpoint returned a malformed token response.',
        );
      }

      final accessToken = decoded['access_token'] as String;
      final lifetime = Duration(seconds: decoded['expires_in'] as int);
      final refreshSkew = tokenRefreshSkew < lifetime
          ? tokenRefreshSkew
          : Duration(microseconds: lifetime.inMicroseconds ~/ 2);
      _cachedAccessToken = accessToken;
      _tokenRefreshAt = _clock().add(lifetime - refreshSkew);
      return accessToken;
    } on AppAccessDecisionException {
      rethrow;
    } catch (_) {
      throw const AppAccessDecisionException(
        'Failed to obtain an App Access bearer token from Keycloak.',
      );
    }
  }

  void close({bool force = false}) {
    if (_ownsHttpClient) _httpClient.close(force: force);
  }

  static Uri _normalizeBaseUri(Uri baseUri) {
    _requireAbsoluteUri(baseUri, 'baseUri');
    final path = baseUri.path.endsWith('/') ? baseUri.path : '${baseUri.path}/';
    return baseUri.replace(path: path, query: null, fragment: null);
  }

  static Uri _requireAbsoluteUri(Uri uri, String name) {
    if (!uri.hasScheme || uri.host.isEmpty) {
      throw ArgumentError.value(uri, name, 'must be an absolute URI');
    }
    return uri;
  }

  static String _requireNonEmpty(String value, String name) {
    if (value.isEmpty) {
      throw ArgumentError.value(value, name, 'must not be empty');
    }
    return value;
  }

  static String _formEncode(Map<String, String> values) {
    return values.entries
        .map(
          (entry) =>
              '${Uri.encodeQueryComponent(entry.key)}='
              '${Uri.encodeQueryComponent(entry.value)}',
        )
        .join('&');
  }
}
