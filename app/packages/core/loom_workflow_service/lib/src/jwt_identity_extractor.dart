import 'dart:convert';
import 'dart:io';

import 'package:jose/jose.dart';
import 'package:shelf/shelf.dart';

import 'identity.dart';

/// Extracts a Loom fan identity from a verified RS256 access token.
class JwtWorkflowIdentityExtractor implements WorkflowIdentityExtractor {
  static const Duration defaultJwksCacheDuration = Duration(minutes: 5);
  static final RegExp _bearerPattern = RegExp(
    r'^Bearer[ \t]+(\S+)$',
    caseSensitive: false,
  );

  final Uri jwksUri;
  final String expectedIssuer;
  final Duration jwksCacheDuration;
  final Future<Map<String, dynamic>> Function(Uri uri)? _jwksFetcher;
  final HttpClient? _httpClient;

  Map<String, JsonWebKey>? _cachedKeys;
  DateTime? _cacheExpiresAt;
  Future<Map<String, JsonWebKey>>? _refreshingKeys;

  JwtWorkflowIdentityExtractor({
    required this.jwksUri,
    required this.expectedIssuer,
    this.jwksCacheDuration = defaultJwksCacheDuration,
    Future<Map<String, dynamic>> Function(Uri uri)? jwksFetcher,
  }) : _jwksFetcher = jwksFetcher,
       _httpClient = jwksFetcher == null ? HttpClient() : null;

  void close({bool force = false}) => _httpClient?.close(force: force);

  @override
  Future<WorkflowRequestIdentity?> extract(Request request) async {
    try {
      final authorization = request.headers['authorization'];
      if (authorization == null) return null;

      final match = _bearerPattern.firstMatch(authorization.trim());
      if (match == null) return null;
      final token = match.group(1);
      if (token == null || token.isEmpty) return null;

      final signature = JsonWebSignature.fromCompactSerialization(token);
      final header = signature.commonProtectedHeader;
      if (header.algorithm != 'RS256') return null;

      final keyId = header.keyId;
      if (keyId == null || keyId.isEmpty) return null;
      final key = await _keyFor(keyId);
      if (key == null) return null;

      final keyStore = JsonWebKeyStore()..addKey(key);
      final jwt = await JsonWebToken.decodeAndVerify(
        token,
        keyStore,
        allowedArguments: const ['RS256'],
      );
      final claims = jwt.claims;
      final claimValues = claims.toJson();

      if (claimValues['iss'] != expectedIssuer) return null;

      final now = DateTime.now();
      final expiry = claims.expiry;
      if (expiry == null || !now.isBefore(expiry)) return null;

      final notBefore = claims.notBefore;
      if (notBefore != null && now.isBefore(notBefore)) return null;

      final fanId = claimValues['fanId'];
      if (fanId is! String) return null;
      final normalizedFanId = fanId.trim();
      if (normalizedFanId.isEmpty) return null;

      return WorkflowRequestIdentity(fanId: normalizedFanId);
    } catch (_) {
      return null;
    }
  }

  Future<JsonWebKey?> _keyFor(String keyId) async {
    final cacheWasFresh = _cacheIsFresh(DateTime.now());
    var keys = await _loadKeys();
    var key = keys[keyId];
    if (key != null || !cacheWasFresh) return key;

    // A fresh cache that does not know this kid may predate a Keycloak key
    // rotation, so refresh once immediately instead of waiting for the TTL.
    keys = await _loadKeys(forceRefresh: true);
    key = keys[keyId];
    return key;
  }

  Future<Map<String, JsonWebKey>> _loadKeys({bool forceRefresh = false}) async {
    if (!forceRefresh && _cacheIsFresh(DateTime.now())) {
      return _cachedKeys!;
    }

    final inFlight = _refreshingKeys;
    if (inFlight != null) return inFlight;

    final refresh = _fetchAndCacheKeys();
    _refreshingKeys = refresh;
    try {
      return await refresh;
    } finally {
      if (identical(_refreshingKeys, refresh)) {
        _refreshingKeys = null;
      }
    }
  }

  bool _cacheIsFresh(DateTime now) {
    final expiry = _cacheExpiresAt;
    return _cachedKeys != null && expiry != null && now.isBefore(expiry);
  }

  Future<Map<String, JsonWebKey>> _fetchAndCacheKeys() async {
    final fetcher = _jwksFetcher;
    final decoded = fetcher == null
        ? await _fetchJwksOverHttp()
        : await fetcher(jwksUri);
    final keySet = JsonWebKeySet.fromJson(decoded);
    final keysById = <String, JsonWebKey>{};
    for (final key in keySet.keys) {
      final keyId = key.keyId;
      if (keyId != null && keyId.isNotEmpty) {
        keysById[keyId] = key;
      }
    }

    final keys = Map<String, JsonWebKey>.unmodifiable(keysById);
    _cachedKeys = keys;
    _cacheExpiresAt = DateTime.now().add(jwksCacheDuration);
    return keys;
  }

  Future<Map<String, dynamic>> _fetchJwksOverHttp() async {
    final request = await _httpClient!.getUrl(jwksUri);
    final response = await request.close();
    if (response.statusCode != HttpStatus.ok) {
      await response.drain<void>();
      throw HttpException(
        'JWKS endpoint returned HTTP ${response.statusCode}',
        uri: jwksUri,
      );
    }

    final body = await utf8.decoder.bind(response).join();
    final value = jsonDecode(body);
    if (value is! Map<String, dynamic>) {
      throw const FormatException('JWKS response must be a JSON object');
    }
    return value;
  }
}
