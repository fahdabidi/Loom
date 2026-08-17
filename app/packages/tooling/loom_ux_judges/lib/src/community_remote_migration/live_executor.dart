import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'derivation.dart';
import 'package_parser.dart';

class MigrationExecutionConfig {
  const MigrationExecutionConfig({
    required this.appAccessBaseUri,
    required this.workflowServiceBaseUri,
    required this.tokenUri,
    required this.clientId,
    required this.clientSecret,
    required this.workflowBearerToken,
    required this.appId,
  });

  final Uri appAccessBaseUri;
  final Uri workflowServiceBaseUri;
  final Uri tokenUri;
  final String clientId;
  final String clientSecret;

  /// Existing Loom fan JWT accepted by `JwtWorkflowIdentityExtractor`.
  ///
  /// Unlike App Access, workflow-service requires a `fanId` claim, so its
  /// definition-replacement call cannot assume a service-account token has a
  /// usable request identity.
  final String workflowBearerToken;
  final String appId;
}

class MigrationExecutionResult {
  const MigrationExecutionResult({
    required this.installCommunityPackageResponse,
    required this.replaceWorkflowDefinitionsResponse,
  });

  final Object? installCommunityPackageResponse;
  final Object? replaceWorkflowDefinitionsResponse;
}

abstract interface class LiveMigrationExecutor {
  Future<MigrationExecutionResult> execute(
    ParsedCommunityPackage package,
    CommunityMigrationPlan plan,
  );
}

/// Live executor using the same cached OAuth client-credentials pattern as
/// `HttpAppAccessDecisionClient`.
///
/// This class has deliberately no group-membership operation.
class HttpLiveMigrationExecutor implements LiveMigrationExecutor {
  HttpLiveMigrationExecutor({required this.config, HttpClient? httpClient})
    : _httpClient = httpClient ?? HttpClient(),
      _ownsHttpClient = httpClient == null;

  final MigrationExecutionConfig config;
  final HttpClient _httpClient;
  final bool _ownsHttpClient;
  String? _accessToken;
  DateTime? _refreshAt;

  @override
  Future<MigrationExecutionResult> execute(
    ParsedCommunityPackage package,
    CommunityMigrationPlan plan,
  ) async {
    if (plan.findings.isNotEmpty) {
      throw StateError(
        'Execution refused: ${plan.findings.length} persona-to-role '
        'translation finding(s) require a human decision.',
      );
    }

    final token = await _loadAccessToken();
    final installResponse = await _sendJson(
      method: 'POST',
      uri: _normalizeBase(config.appAccessBaseUri).resolve(
        'v1/apps/${Uri.encodeComponent(config.appId)}/'
        'community-installations',
      ),
      token: token,
      body: plan.installCommunityPackagePayload,
      idempotencyKey: 'community-migration-install-${_uuidV4()}',
    );
    final definitionsResponse = await _sendJson(
      method: 'PUT',
      uri: _normalizeBase(config.workflowServiceBaseUri).resolve(
        'v1/communities/${Uri.encodeComponent(package.communityId)}/'
        'workflow-definitions',
      ),
      token: config.workflowBearerToken,
      body: plan.replaceWorkflowDefinitionsPayload,
      idempotencyKey: 'community-migration-definitions-${_uuidV4()}',
    );
    return MigrationExecutionResult(
      installCommunityPackageResponse: installResponse,
      replaceWorkflowDefinitionsResponse: definitionsResponse,
    );
  }

  Future<String> _loadAccessToken() async {
    final now = DateTime.now();
    if (_accessToken case final token?
        when _refreshAt != null && now.isBefore(_refreshAt!)) {
      return token;
    }

    final request = await _httpClient.postUrl(config.tokenUri);
    request.headers.contentType = ContentType(
      'application',
      'x-www-form-urlencoded',
      charset: 'utf-8',
    );
    request.write(
      _formEncode({
        'grant_type': 'client_credentials',
        'client_id': config.clientId,
        'client_secret': config.clientSecret,
      }),
    );
    final response = await request.close();
    final responseBody = await utf8.decoder.bind(response).join();
    if (response.statusCode != HttpStatus.ok) {
      throw HttpException(
        'Keycloak token endpoint returned HTTP ${response.statusCode}: '
        '$responseBody',
        uri: config.tokenUri,
      );
    }
    final decoded = jsonDecode(responseBody);
    if (decoded is! Map<String, dynamic> ||
        decoded['access_token'] is! String ||
        decoded['expires_in'] is! int) {
      throw const FormatException(
        'Keycloak token response must contain access_token and expires_in.',
      );
    }
    final token = decoded['access_token'] as String;
    final expiresIn = decoded['expires_in'] as int;
    if (token.isEmpty || expiresIn <= 0) {
      throw const FormatException(
        'Keycloak returned an empty or already-expired access token.',
      );
    }
    final lifetime = Duration(seconds: expiresIn);
    final skew = lifetime > const Duration(seconds: 30)
        ? const Duration(seconds: 30)
        : Duration(microseconds: lifetime.inMicroseconds ~/ 2);
    _accessToken = token;
    _refreshAt = now.add(lifetime - skew);
    return token;
  }

  Future<Object?> _sendJson({
    required String method,
    required Uri uri,
    required String token,
    required JsonMap body,
    required String idempotencyKey,
  }) async {
    final request = await _httpClient.openUrl(method, uri);
    request.headers.contentType = ContentType.json;
    request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
    request.headers.set('x-loom-correlation-id', _uuidV4());
    request.headers.set('idempotency-key', idempotencyKey);
    request.write(jsonEncode(body));
    final response = await request.close();
    final responseBody = await utf8.decoder.bind(response).join();
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw HttpException(
        '$method $uri returned HTTP ${response.statusCode}: $responseBody',
        uri: uri,
      );
    }
    if (responseBody.trim().isEmpty) return null;
    try {
      return jsonDecode(responseBody);
    } on FormatException {
      return responseBody;
    }
  }

  void close({bool force = false}) {
    if (_ownsHttpClient) _httpClient.close(force: force);
  }
}

Uri _normalizeBase(Uri uri) {
  if (!uri.hasScheme || uri.host.isEmpty) {
    throw ArgumentError.value(uri, 'uri', 'must be an absolute URI');
  }
  return uri.replace(
    path: uri.path.endsWith('/') ? uri.path : '${uri.path}/',
    query: null,
    fragment: null,
  );
}

String _formEncode(Map<String, String> values) => values.entries
    .map(
      (entry) =>
          '${Uri.encodeQueryComponent(entry.key)}='
          '${Uri.encodeQueryComponent(entry.value)}',
    )
    .join('&');

String _uuidV4() {
  final bytes = List<int>.generate(16, (_) => Random.secure().nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  final hex = bytes
      .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
      .join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
      '${hex.substring(12, 16)}-${hex.substring(16, 20)}-'
      '${hex.substring(20)}';
}
