import 'dart:convert';

import 'package:http/http.dart' as http;

import 'auth_exceptions.dart';
import 'secure_storage_backend.dart';

/// Persists and renews the bearer-token session used by Loom API clients.
///
/// This core does not implement interactive browser authorization. Its
/// [loginWithTestCredentials] method bypasses the interactive browser flow and
/// exists only for automated/local testing with Keycloak-native test accounts;
/// production UI code must never call it.
class LoomAuthSession {
  LoomAuthSession({
    required Uri tokenEndpoint,
    required String clientId,
    required LoomAuthSecureStorageBackend secureStorage,
    http.Client? httpClient,
    DateTime Function()? clock,
    this.refreshSkew = defaultRefreshSkew,
    this.storageKey = defaultStorageKey,
  }) : _tokenEndpoint = _requireAbsoluteUri(tokenEndpoint),
       _clientId = _requireNonEmpty(clientId, 'clientId'),
       _secureStorage = secureStorage,
       _httpClient = httpClient ?? http.Client(),
       _ownsHttpClient = httpClient == null,
       _clock = clock ?? DateTime.now {
    if (refreshSkew.isNegative) {
      throw ArgumentError.value(
        refreshSkew,
        'refreshSkew',
        'must not be negative',
      );
    }
    _requireNonEmpty(storageKey, 'storageKey');
  }

  static const Duration defaultRefreshSkew = Duration(seconds: 30);
  static const String defaultStorageKey = 'loom.auth_session.tokens.v1';

  final Uri _tokenEndpoint;
  final String _clientId;
  final LoomAuthSecureStorageBackend _secureStorage;
  final http.Client _httpClient;
  final bool _ownsHttpClient;
  final DateTime Function() _clock;

  final Duration refreshSkew;
  final String storageKey;

  _StoredSession? _session;
  bool _storageWasRead = false;
  Future<String>? _refreshingAccessToken;
  int _sessionGeneration = 0;

  /// Returns an access token that is outside the proactive refresh window.
  ///
  /// A stored refresh token is exchanged silently when the access token is
  /// expired or nearing expiry. Distinct exception types identify a missing
  /// login, an expired refresh token, and a network failure.
  Future<String> currentAccessToken() async {
    final session = await _loadStoredSession();
    if (session == null) throw const LoomAuthNotLoggedInException();
    if (_accessTokenIsFresh(session, _clock())) return session.accessToken;

    final inFlight = _refreshingAccessToken;
    if (inFlight != null) return inFlight;

    final generation = _sessionGeneration;
    final refresh = _refreshAccessToken(session, generation);
    _refreshingAccessToken = refresh;
    try {
      return await refresh;
    } finally {
      if (identical(_refreshingAccessToken, refresh)) {
        _refreshingAccessToken = null;
      }
    }
  }

  /// Logs in through Keycloak's Direct Access Grant for tests only.
  ///
  /// This bypasses the interactive browser flow and exists only for
  /// automated/local testing against Keycloak-native accounts. Never call this
  /// method from real production UI code.
  Future<void> loginWithTestCredentials({
    required String username,
    required String password,
  }) async {
    _requireNonEmpty(username, 'username');
    _requireNonEmpty(password, 'password');

    final response = await _postToken({
      'grant_type': 'password',
      'client_id': _clientId,
      'username': username,
      'password': password,
    });
    if (response.statusCode != 200) {
      final oauthError = _readOAuthError(response.body);
      if (oauthError == 'invalid_grant') {
        throw LoomAuthTestCredentialsRejectedException(
          message:
              'Keycloak rejected the test-only credentials (invalid_grant).',
          statusCode: response.statusCode,
          oauthError: oauthError,
        );
      }
      throw LoomAuthTokenEndpointException(
        message:
            'Keycloak rejected the test-only token exchange'
            '${oauthError == null ? '.' : ' ($oauthError).'}',
        statusCode: response.statusCode,
        oauthError: oauthError,
      );
    }

    final tokens = _TokenResponse.parse(
      response.body,
      requireRefreshToken: true,
    );
    final session = _sessionFromTokenResponse(tokens, previous: null);
    await _persistSession(session);
  }

  /// Clears only the locally persisted tokens.
  ///
  /// This deliberately does not call Keycloak's browser-oriented end-session
  /// endpoint.
  Future<void> logout() async {
    try {
      await _secureStorage.delete(key: storageKey);
    } on Exception catch (error) {
      throw LoomAuthStorageException(
        'Failed to clear the persisted Loom authentication session: $error',
      );
    }
    _sessionGeneration++;
    _session = null;
    _storageWasRead = true;
  }

  /// Closes the internally created HTTP client, if this instance owns it.
  void close() {
    if (_ownsHttpClient) _httpClient.close();
  }

  Future<_StoredSession?> _loadStoredSession() async {
    if (_storageWasRead) return _session;

    final String? encoded;
    try {
      encoded = await _secureStorage.read(key: storageKey);
    } on Exception catch (error) {
      throw LoomAuthStorageException(
        'Failed to read the persisted Loom authentication session: $error',
      );
    }
    if (encoded == null) {
      _storageWasRead = true;
      return null;
    }

    try {
      _session = _StoredSession.fromJson(encoded);
    } on FormatException catch (error) {
      throw LoomAuthStorageException(
        'The persisted Loom authentication session is malformed: '
        '${error.message}',
      );
    }
    _storageWasRead = true;
    return _session;
  }

  bool _accessTokenIsFresh(_StoredSession session, DateTime now) =>
      now.isBefore(session.accessTokenRefreshAt);

  Future<String> _refreshAccessToken(
    _StoredSession previous,
    int generation,
  ) async {
    final refreshExpiry = previous.refreshTokenExpiresAt;
    if (refreshExpiry != null && !_clock().isBefore(refreshExpiry)) {
      await _clearExpiredSession(generation);
      throw const LoomAuthRefreshTokenExpiredException();
    }

    final response = await _postToken({
      'grant_type': 'refresh_token',
      'client_id': _clientId,
      'refresh_token': previous.refreshToken,
    });
    if (response.statusCode != 200) {
      final oauthError = _readOAuthError(response.body);
      if (oauthError == 'invalid_grant') {
        await _clearExpiredSession(generation);
        throw const LoomAuthRefreshTokenExpiredException();
      }
      throw LoomAuthTokenEndpointException(
        message:
            'Keycloak rejected the refresh-token exchange'
            '${oauthError == null ? '.' : ' ($oauthError).'}',
        statusCode: response.statusCode,
        oauthError: oauthError,
      );
    }

    final tokens = _TokenResponse.parse(
      response.body,
      requireRefreshToken: false,
    );
    final refreshed = _sessionFromTokenResponse(tokens, previous: previous);
    if (generation != _sessionGeneration) {
      throw const LoomAuthNotLoggedInException();
    }
    await _persistSession(refreshed);
    return refreshed.accessToken;
  }

  Future<http.Response> _postToken(Map<String, String> body) async {
    try {
      return await _httpClient.post(
        _tokenEndpoint,
        headers: const {
          'content-type': 'application/x-www-form-urlencoded; charset=utf-8',
        },
        body: body,
      );
    } on Exception catch (error) {
      throw LoomAuthNetworkException(
        'Failed to reach the Keycloak token endpoint: $error',
      );
    }
  }

  _StoredSession _sessionFromTokenResponse(
    _TokenResponse tokens, {
    required _StoredSession? previous,
  }) {
    final now = _clock();
    final lifetime = Duration(seconds: tokens.expiresIn);
    final effectiveSkew = refreshSkew < lifetime
        ? refreshSkew
        : Duration(microseconds: lifetime.inMicroseconds ~/ 2);
    final refreshToken = tokens.refreshToken ?? previous?.refreshToken;
    if (refreshToken == null || refreshToken.isEmpty) {
      throw const LoomAuthProtocolException(
        'Keycloak token response did not contain a refresh token.',
      );
    }

    final refreshTokenExpiresAt = tokens.refreshExpiresIn == null
        ? previous?.refreshTokenExpiresAt
        : now.add(Duration(seconds: tokens.refreshExpiresIn!));
    return _StoredSession(
      accessToken: tokens.accessToken,
      refreshToken: refreshToken,
      accessTokenExpiresAt: now.add(lifetime),
      accessTokenRefreshAt: now.add(lifetime - effectiveSkew),
      refreshTokenExpiresAt: refreshTokenExpiresAt,
    );
  }

  Future<void> _persistSession(_StoredSession session) async {
    try {
      await _secureStorage.write(key: storageKey, value: session.toJson());
    } on Exception catch (error) {
      throw LoomAuthStorageException(
        'Failed to persist the Loom authentication session: $error',
      );
    }
    _sessionGeneration++;
    _session = session;
    _storageWasRead = true;
  }

  Future<void> _clearExpiredSession(int generation) async {
    if (generation != _sessionGeneration) return;
    try {
      await _secureStorage.delete(key: storageKey);
    } on Exception catch (error) {
      throw LoomAuthStorageException(
        'The refresh token expired, but its stored session could not be '
        'cleared: $error',
      );
    }
    if (generation == _sessionGeneration) {
      _sessionGeneration++;
      _session = null;
      _storageWasRead = true;
    }
  }

  static String? _readOAuthError(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic> && decoded['error'] is String) {
        return decoded['error'] as String;
      }
    } on FormatException {
      // The HTTP status still provides a stable failure when the body is not
      // an OAuth error object.
    }
    return null;
  }

  static Uri _requireAbsoluteUri(Uri uri) {
    if (!uri.hasScheme || uri.host.isEmpty) {
      throw ArgumentError.value(
        uri,
        'tokenEndpoint',
        'must be an absolute URI',
      );
    }
    return uri;
  }

  static String _requireNonEmpty(String value, String name) {
    if (value.isEmpty) {
      throw ArgumentError.value(value, name, 'must not be empty');
    }
    return value;
  }
}

final class _TokenResponse {
  const _TokenResponse({
    required this.accessToken,
    required this.expiresIn,
    required this.refreshToken,
    required this.refreshExpiresIn,
  });

  final String accessToken;
  final int expiresIn;
  final String? refreshToken;
  final int? refreshExpiresIn;

  factory _TokenResponse.parse(
    String encoded, {
    required bool requireRefreshToken,
  }) {
    final Object? decoded;
    try {
      decoded = jsonDecode(encoded);
    } on FormatException {
      throw const LoomAuthProtocolException(
        'Keycloak token endpoint returned malformed JSON.',
      );
    }
    if (decoded is! Map<String, dynamic>) {
      throw const LoomAuthProtocolException(
        'Keycloak token response must be a JSON object.',
      );
    }

    final accessToken = decoded['access_token'];
    final expiresIn = decoded['expires_in'];
    final refreshToken = decoded['refresh_token'];
    final refreshExpiresIn = decoded['refresh_expires_in'];
    if (accessToken is! String ||
        accessToken.isEmpty ||
        expiresIn is! int ||
        expiresIn <= 0 ||
        refreshToken != null &&
            (refreshToken is! String || refreshToken.isEmpty) ||
        requireRefreshToken && refreshToken is! String ||
        refreshExpiresIn != null &&
            (refreshExpiresIn is! int || refreshExpiresIn <= 0)) {
      throw const LoomAuthProtocolException(
        'Keycloak token endpoint returned an incomplete token response.',
      );
    }

    return _TokenResponse(
      accessToken: accessToken,
      expiresIn: expiresIn,
      refreshToken: refreshToken as String?,
      refreshExpiresIn: refreshExpiresIn as int?,
    );
  }
}

final class _StoredSession {
  const _StoredSession({
    required this.accessToken,
    required this.refreshToken,
    required this.accessTokenExpiresAt,
    required this.accessTokenRefreshAt,
    required this.refreshTokenExpiresAt,
  });

  final String accessToken;
  final String refreshToken;
  final DateTime accessTokenExpiresAt;
  final DateTime accessTokenRefreshAt;
  final DateTime? refreshTokenExpiresAt;

  factory _StoredSession.fromJson(String encoded) {
    final Object? decoded;
    try {
      decoded = jsonDecode(encoded);
    } on FormatException {
      throw const FormatException('expected valid JSON');
    }
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('expected a JSON object');
    }

    final accessToken = decoded['access_token'];
    final refreshToken = decoded['refresh_token'];
    final expiresAtValue = decoded['access_token_expires_at'];
    final refreshAtValue = decoded['access_token_refresh_at'];
    final refreshExpiresAtValue = decoded['refresh_token_expires_at'];
    final expiresAt = expiresAtValue is String
        ? DateTime.tryParse(expiresAtValue)
        : null;
    final refreshAt = refreshAtValue is String
        ? DateTime.tryParse(refreshAtValue)
        : null;
    final refreshExpiresAt = refreshExpiresAtValue is String
        ? DateTime.tryParse(refreshExpiresAtValue)
        : null;
    if (accessToken is! String ||
        accessToken.isEmpty ||
        refreshToken is! String ||
        refreshToken.isEmpty ||
        expiresAt == null ||
        refreshAt == null ||
        refreshExpiresAtValue != null && refreshExpiresAt == null) {
      throw const FormatException('required token fields are missing');
    }

    return _StoredSession(
      accessToken: accessToken,
      refreshToken: refreshToken,
      accessTokenExpiresAt: expiresAt,
      accessTokenRefreshAt: refreshAt,
      refreshTokenExpiresAt: refreshExpiresAt,
    );
  }

  String toJson() => jsonEncode({
    'access_token': accessToken,
    'refresh_token': refreshToken,
    'access_token_expires_at': accessTokenExpiresAt.toIso8601String(),
    'access_token_refresh_at': accessTokenRefreshAt.toIso8601String(),
    'refresh_token_expires_at': refreshTokenExpiresAt?.toIso8601String(),
  });
}
