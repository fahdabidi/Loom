import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'plan.dart';

class AppAccessProvisioningConfig {
  AppAccessProvisioningConfig({
    required Uri appAccessBaseUri,
    required Uri tokenUri,
    required this.clientId,
    required this.clientSecret,
    required this.appId,
  }) : appAccessBaseUri = _normalizedBaseUri(appAccessBaseUri),
       tokenUri = _absoluteUri(tokenUri, 'tokenUri') {
    if (clientId.trim().isEmpty) {
      throw ArgumentError.value(clientId, 'clientId', 'must not be empty');
    }
    if (clientSecret.isEmpty) {
      throw ArgumentError.value(
        clientSecret,
        'clientSecret',
        'must not be empty',
      );
    }
    if (appId.trim().isEmpty) {
      throw ArgumentError.value(appId, 'appId', 'must not be empty');
    }
  }

  final Uri appAccessBaseUri;
  final Uri tokenUri;
  final String clientId;
  final String clientSecret;
  final String appId;
}

/// Results of posting every community request in a provisioning plan.
///
/// The `communityGroupIds` map is populated only by successful service
/// responses. It is the value to pass as `LOOM_COMMUNITY_GROUP_IDS` after an
/// all-successful run.
class AppAccessProvisioningResult {
  const AppAccessProvisioningResult({
    required this.installations,
    required this.failures,
  });

  final List<CommunityInstallationOutcome> installations;
  final List<CommunityInstallationFailure> failures;

  bool get hasFailures => failures.isNotEmpty;

  Map<String, String> get communityGroupIds => Map.unmodifiable({
    for (final installation in installations)
      installation.communityId: installation.groupId,
  });

  JsonMap toJson() => <String, Object?>{
    'communityGroupIds': communityGroupIds,
    'installations': [
      for (final installation in installations) installation.toJson(),
    ],
    'failures': [for (final failure in failures) failure.toJson()],
  };
}

/// The usable portion of a 200 `CommunityInstallationResult` response.
class CommunityInstallationOutcome {
  const CommunityInstallationOutcome({
    required this.communityId,
    required this.appId,
    required this.groupId,
    required this.rolesRegistered,
    required this.removedRoleIds,
    required this.permissionsGranted,
    required this.rolesWithNoPermissions,
  });

  final String communityId;
  final String appId;
  final String groupId;
  final List<String> rolesRegistered;
  final List<String> removedRoleIds;
  final int permissionsGranted;
  final List<String> rolesWithNoPermissions;

  JsonMap toJson() => <String, Object?>{
    'communityId': communityId,
    'appId': appId,
    'groupId': groupId,
    'rolesRegistered': rolesRegistered,
    'removedRoleIds': removedRoleIds,
    'permissionsGranted': permissionsGranted,
    'rolesWithNoPermissions': rolesWithNoPermissions,
  };

  factory CommunityInstallationOutcome.fromResponse(
    String communityId,
    JsonMap response,
  ) => CommunityInstallationOutcome(
    communityId: communityId,
    appId: _requiredResponseString(response, 'appId'),
    groupId: _requiredResponseString(response, 'groupId'),
    rolesRegistered: _responseStringList(response, 'rolesRegistered'),
    removedRoleIds: _optionalResponseStringList(response, 'removedRoleIds'),
    permissionsGranted: _requiredResponseInt(response, 'permissionsGranted'),
    rolesWithNoPermissions: _optionalResponseStringList(
      response,
      'rolesWithNoPermissions',
    ),
  );
}

/// A 422 result. Findings are intentionally retained as raw JSON objects so
/// the CLI can print every server diagnostic without rewording or dropping it.
class CommunityInstallationFailure {
  const CommunityInstallationFailure({
    required this.communityId,
    required this.findings,
  });

  final String communityId;
  final List<JsonMap> findings;

  JsonMap toJson() => <String, Object?>{
    'communityId': communityId,
    'findings': findings,
  };

  factory CommunityInstallationFailure.fromResponse(
    String communityId,
    JsonMap response,
  ) {
    final rawFindings = response['findings'];
    if (rawFindings is! List || rawFindings.isEmpty) {
      throw const FormatException(
        'A 422 community-installation response must contain non-empty findings.',
      );
    }
    final findings = <JsonMap>[];
    for (final finding in rawFindings) {
      if (finding is! Map) {
        throw const FormatException(
          'A community-installation finding must be an object.',
        );
      }
      findings.add(Map<String, Object?>.from(finding));
    }
    return CommunityInstallationFailure(
      communityId: communityId,
      findings: List.unmodifiable(findings),
    );
  }
}

/// The only network-capable portion of this package.
///
/// It posts one request to App Access per community. It never writes the
/// permission catalog, groups, or roles itself.
class HttpAppAccessProvisioningApplier {
  HttpAppAccessProvisioningApplier({
    required this.config,
    HttpClient? httpClient,
  }) : _httpClient = httpClient ?? HttpClient(),
       _ownsHttpClient = httpClient == null;

  final AppAccessProvisioningConfig config;
  final HttpClient _httpClient;
  final bool _ownsHttpClient;
  String? _accessToken;
  DateTime? _refreshAt;

  Future<AppAccessProvisioningResult> apply(
    AppAccessProvisioningPlan plan,
  ) async {
    final communityIds = plan.communities.map(
      (community) => community.communityId,
    );
    if (communityIds.toSet().length != plan.communities.length) {
      throw const FormatException(
        'The provisioning plan contains duplicate community ids.',
      );
    }

    final installations = <CommunityInstallationOutcome>[];
    final failures = <CommunityInstallationFailure>[];
    for (final community in plan.communities) {
      final response = await _sendJson(
        method: 'POST',
        path:
            'v1/apps/${Uri.encodeComponent(config.appId)}/'
            'community-installations',
        body: community.toInstallationRequestBody(),
        mutating: true,
        acceptedStatusCodes: const {HttpStatus.unprocessableEntity},
      );
      final body = _responseObject(response, 'community-installations');
      if (response.statusCode == HttpStatus.unprocessableEntity) {
        failures.add(
          CommunityInstallationFailure.fromResponse(
            community.communityId,
            body,
          ),
        );
      } else {
        installations.add(
          CommunityInstallationOutcome.fromResponse(
            community.communityId,
            body,
          ),
        );
      }
    }
    return AppAccessProvisioningResult(
      installations: List.unmodifiable(installations),
      failures: List.unmodifiable(failures),
    );
  }

  Future<_HttpJsonResponse> _sendJson({
    required String method,
    required String path,
    JsonMap? body,
    bool mutating = false,
    Set<int> acceptedStatusCodes = const {},
  }) async {
    final token = await _loadAccessToken();
    final uri = config.appAccessBaseUri.resolve(path);
    final request = await _httpClient.openUrl(method, uri);
    request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
    request.headers.set('x-loom-correlation-id', _newUuidV4());
    if (mutating) {
      request.headers.set(
        'idempotency-key',
        'community-installation-${_newUuidV4()}',
      );
    }
    if (body != null) {
      request.headers.contentType = ContentType.json;
      request.write(jsonEncode(body));
    }
    final response = await request.close();
    final encoded = await utf8.decoder.bind(response).join();
    final success = response.statusCode >= 200 && response.statusCode < 300;
    if (!success && !acceptedStatusCodes.contains(response.statusCode)) {
      throw HttpException(
        '$method $uri returned HTTP ${response.statusCode}; response body: '
        '${_truncatedResponseBody(encoded)}',
        uri: uri,
      );
    }
    if (encoded.trim().isEmpty) {
      throw HttpException(
        '$method $uri returned an empty response body.',
        uri: uri,
      );
    }
    try {
      return _HttpJsonResponse(response.statusCode, jsonDecode(encoded));
    } on FormatException {
      throw HttpException(
        '$method $uri returned malformed JSON; response body: '
        '${_truncatedResponseBody(encoded)}',
        uri: uri,
      );
    }
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
    request.headers.set('x-loom-correlation-id', _newUuidV4());
    request.write(
      _formEncode(<String, String>{
        'grant_type': 'client_credentials',
        'client_id': config.clientId,
        'client_secret': config.clientSecret,
      }),
    );
    final response = await request.close();
    final encoded = await utf8.decoder.bind(response).join();
    if (response.statusCode != HttpStatus.ok) {
      throw HttpException(
        'Token endpoint returned HTTP ${response.statusCode}; response body: '
        '${_truncatedResponseBody(encoded)}',
        uri: config.tokenUri,
      );
    }
    final Object? decoded;
    try {
      decoded = jsonDecode(encoded);
    } on FormatException {
      throw HttpException(
        'Token endpoint returned malformed JSON; response body: '
        '${_truncatedResponseBody(encoded)}',
        uri: config.tokenUri,
      );
    }
    if (decoded is! Map ||
        decoded['access_token'] is! String ||
        (decoded['access_token'] as String).isEmpty ||
        decoded['expires_in'] is! int ||
        (decoded['expires_in'] as int) <= 0) {
      throw const FormatException(
        'Token endpoint returned an incomplete token.',
      );
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
}

class _HttpJsonResponse {
  const _HttpJsonResponse(this.statusCode, this.body);

  final int statusCode;
  final Object? body;
}

JsonMap _responseObject(_HttpJsonResponse response, String operation) {
  final body = response.body;
  if (body is! Map) {
    throw FormatException('$operation returned a non-object JSON response.');
  }
  return Map<String, Object?>.from(body);
}

String _requiredResponseString(JsonMap response, String field) {
  final value = response[field];
  if (value is! String || value.isEmpty) {
    throw FormatException(
      'Community-installation response $field must be a non-empty string.',
    );
  }
  return value;
}

int _requiredResponseInt(JsonMap response, String field) {
  final value = response[field];
  if (value is! int) {
    throw FormatException(
      'Community-installation response $field must be an integer.',
    );
  }
  return value;
}

List<String> _responseStringList(JsonMap response, String field) {
  final value = response[field];
  if (value is! List || value.any((item) => item is! String)) {
    throw FormatException(
      'Community-installation response $field must be a list of strings.',
    );
  }
  return List.unmodifiable(value.cast<String>());
}

List<String> _optionalResponseStringList(JsonMap response, String field) {
  if (!response.containsKey(field)) return const <String>[];
  return _responseStringList(response, field);
}

Uri _normalizedBaseUri(Uri uri) {
  if (!uri.hasScheme || uri.host.isEmpty) {
    throw ArgumentError.value(
      uri,
      'appAccessBaseUri',
      'must be an absolute URI',
    );
  }
  return uri.replace(
    path: uri.path.endsWith('/') ? uri.path : '${uri.path}/',
    query: null,
    fragment: null,
  );
}

Uri _absoluteUri(Uri uri, String name) {
  if (!uri.hasScheme || uri.host.isEmpty) {
    throw ArgumentError.value(uri, name, 'must be an absolute URI');
  }
  return uri;
}

String _formEncode(Map<String, String> values) => values.entries
    .map(
      (entry) =>
          '${Uri.encodeQueryComponent(entry.key)}='
          '${Uri.encodeQueryComponent(entry.value)}',
    )
    .join('&');

String _truncatedResponseBody(String body) {
  const maxLength = 4096;
  if (body.length <= maxLength) return body;
  return '${body.substring(0, maxLength)}… '
      '[truncated ${body.length - maxLength} characters]';
}

String _newUuidV4() {
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
