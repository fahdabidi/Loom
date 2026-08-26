import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'plan.dart';

/// Credentials and endpoints used only after the caller explicitly selects
/// `--apply`. The client secret is deliberately never part of a plan/result.
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

/// State changes made by one reconciliation. Existing stale entries are
/// reported but never removed.
class AppAccessProvisioningResult {
  const AppAccessProvisioningResult({
    required this.createdGroupIds,
    required this.createdRoleIds,
    required this.updatedRolePermissionIds,
    required this.unchangedGroupIds,
    required this.unchangedRoleIds,
    required this.extraGroupIds,
    required this.extraRoleIds,
  });

  final List<String> createdGroupIds;
  final List<String> createdRoleIds;
  final List<String> updatedRolePermissionIds;
  final List<String> unchangedGroupIds;
  final List<String> unchangedRoleIds;
  final List<String> extraGroupIds;
  final List<String> extraRoleIds;

  JsonMap toJson() => <String, Object?>{
    'createdGroupIds': createdGroupIds,
    'createdRoleIds': createdRoleIds,
    'updatedRolePermissionIds': updatedRolePermissionIds,
    'unchangedGroupIds': unchangedGroupIds,
    'unchangedRoleIds': unchangedRoleIds,
    'extraGroupIds': extraGroupIds,
    'extraRoleIds': extraRoleIds,
  };
}

/// The only network-capable portion of this package. It deliberately performs
/// no derivation and has no deletion method.
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
    final desiredGroups = <String, CommunityProvisioningEntry>{
      for (final community in plan.communities) community.groupId: community,
    };
    final desiredRoles = <String, _DesiredRole>{
      for (final community in plan.communities)
        for (final role in community.roles)
          role.roleId: _DesiredRole(role, community.groupId),
    };
    if (desiredGroups.length != plan.communities.length) {
      throw const FormatException(
        'The provisioning plan contains duplicate group ids.',
      );
    }
    if (desiredRoles.length !=
        plan.communities.fold<int>(
          0,
          (count, community) => count + community.roles.length,
        )) {
      throw const FormatException(
        'The provisioning plan contains duplicate role ids.',
      );
    }

    final existingGroups = await _listById(
      'v1/apps/${Uri.encodeComponent(config.appId)}/groups',
      'groupId',
    );
    final existingRoles = await _listById(
      'v1/apps/${Uri.encodeComponent(config.appId)}/roles',
      'roleId',
    );
    final createdGroups = <String>[];
    final unchangedGroups = <String>[];
    for (final desired in desiredGroups.entries) {
      final existing = existingGroups[desired.key];
      if (existing == null) {
        await _sendJson(
          method: 'POST',
          path: 'v1/apps/${Uri.encodeComponent(config.appId)}/groups',
          body: <String, Object?>{
            'groupId': desired.key,
            'displayName': desired.value.displayName,
          },
          mutating: true,
        );
        createdGroups.add(desired.key);
        continue;
      }
      _requireStringField(existing, 'displayName', 'group ${desired.key}');
      if (existing['displayName'] != desired.value.displayName) {
        throw StateError(
          'Group ${desired.key} has displayName "${existing['displayName']}"; '
          'the App Access API exposes no group update operation. Refusing to '
          'silently accept mismatched provisioning state.',
        );
      }
      unchangedGroups.add(desired.key);
    }

    final createdRoles = <String>[];
    final updatedPermissions = <String>[];
    final unchangedRoles = <String>[];
    for (final desired in desiredRoles.entries) {
      final existing = existingRoles[desired.key];
      if (existing == null) {
        await _sendJson(
          method: 'POST',
          path: 'v1/apps/${Uri.encodeComponent(config.appId)}/roles',
          body: <String, Object?>{
            'roleId': desired.key,
            'groupId': desired.value.groupId,
            'displayName': desired.value.role.displayName,
            'permissionIds': desired.value.role.permissionIds,
          },
          mutating: true,
        );
        createdRoles.add(desired.key);
        continue;
      }
      _verifyExistingRole(existing, desired.value);
      final existingPermissionIds = _stringSet(
        existing['permissionIds'],
        'role ${desired.key} permissionIds',
      );
      final desiredPermissionIds = desired.value.role.permissionIds.toSet();
      if (!_sameSet(existingPermissionIds, desiredPermissionIds)) {
        await _sendJson(
          method: 'PUT',
          path:
              'v1/apps/${Uri.encodeComponent(config.appId)}/roles/'
              '${Uri.encodeComponent(desired.key)}/permissions',
          body: <String, Object?>{
            'permissionIds': desired.value.role.permissionIds,
          },
          mutating: true,
        );
        updatedPermissions.add(desired.key);
      } else {
        unchangedRoles.add(desired.key);
      }
    }

    return AppAccessProvisioningResult(
      createdGroupIds: _sorted(createdGroups),
      createdRoleIds: _sorted(createdRoles),
      updatedRolePermissionIds: _sorted(updatedPermissions),
      unchangedGroupIds: _sorted(unchangedGroups),
      unchangedRoleIds: _sorted(unchangedRoles),
      extraGroupIds: _sorted(
        existingGroups.keys.where(
          (groupId) => !desiredGroups.containsKey(groupId),
        ),
      ),
      extraRoleIds: _sorted(
        existingRoles.keys.where((roleId) => !desiredRoles.containsKey(roleId)),
      ),
    );
  }

  Future<Map<String, JsonMap>> _listById(String path, String idField) async {
    final itemsById = <String, JsonMap>{};
    String? cursor;
    do {
      final query = <String, String>{'limit': '100'};
      if (cursor != null) query['cursor'] = cursor;
      final response = await _sendJson(
        method: 'GET',
        path: path,
        queryParameters: query,
      );
      if (response is! Map) {
        throw FormatException('$path returned a non-object list response.');
      }
      final rawItems = response['items'];
      if (rawItems is! List) {
        throw FormatException('$path response must contain an items list.');
      }
      for (final item in rawItems) {
        if (item is! Map) {
          throw FormatException('$path items must be objects.');
        }
        final json = Map<String, Object?>.from(item);
        final id = _requireStringField(json, idField, '$path item');
        if (itemsById.containsKey(id)) {
          throw FormatException('$path returned duplicate $idField $id.');
        }
        itemsById[id] = json;
      }
      final pageInfo = response['pageInfo'];
      if (pageInfo == null) break;
      if (pageInfo is! Map || pageInfo['hasMore'] is! bool) {
        throw FormatException('$path pageInfo is malformed.');
      }
      if (pageInfo['hasMore'] == false) break;
      final nextCursor = pageInfo['nextCursor'];
      if (nextCursor is! String || nextCursor.isEmpty) {
        throw FormatException('$path pageInfo hasMore requires nextCursor.');
      }
      cursor = nextCursor;
    } while (true);
    return itemsById;
  }

  Future<Object?> _sendJson({
    required String method,
    required String path,
    Map<String, String>? queryParameters,
    JsonMap? body,
    bool mutating = false,
  }) async {
    final token = await _loadAccessToken();
    final uri = config.appAccessBaseUri
        .resolve(path)
        .replace(queryParameters: queryParameters);
    final request = await _httpClient.openUrl(method, uri);
    request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
    request.headers.set('x-loom-correlation-id', _newUuidV4());
    if (mutating) {
      request.headers.set('idempotency-key', 'provisioning-${_newUuidV4()}');
    }
    if (body != null) {
      request.headers.contentType = ContentType.json;
      request.write(jsonEncode(body));
    }
    final response = await request.close();
    final encoded = await utf8.decoder.bind(response).join();
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw HttpException(
        '$method $uri returned HTTP ${response.statusCode}.',
        uri: uri,
      );
    }
    if (encoded.trim().isEmpty) return null;
    try {
      return jsonDecode(encoded);
    } on FormatException {
      throw HttpException('$method $uri returned malformed JSON.', uri: uri);
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
        'Token endpoint returned HTTP ${response.statusCode}.',
        uri: config.tokenUri,
      );
    }
    final Object? decoded;
    try {
      decoded = jsonDecode(encoded);
    } on FormatException {
      throw const FormatException('Token endpoint returned malformed JSON.');
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

class _DesiredRole {
  const _DesiredRole(this.role, this.groupId);

  final RoleProvisioningEntry role;
  final String groupId;
}

void _verifyExistingRole(JsonMap existing, _DesiredRole desired) {
  final roleId = desired.role.roleId;
  final groupId = _requireStringField(existing, 'groupId', 'role $roleId');
  if (groupId != desired.groupId) {
    throw StateError(
      'Role $roleId belongs to $groupId rather than ${desired.groupId}; '
      'the App Access API exposes no role group update operation.',
    );
  }
  final displayName = _requireStringField(
    existing,
    'displayName',
    'role $roleId',
  );
  if (displayName != desired.role.displayName) {
    throw StateError(
      'Role $roleId has displayName "$displayName"; the App Access API '
      'exposes no role display-name update operation.',
    );
  }
}

String _requireStringField(JsonMap value, String field, String location) {
  final fieldValue = value[field];
  if (fieldValue is! String || fieldValue.isEmpty) {
    throw FormatException('$location must contain non-empty $field.');
  }
  return fieldValue;
}

Set<String> _stringSet(Object? value, String location) {
  if (value is! List || value.any((item) => item is! String)) {
    throw FormatException('$location must be a list of strings.');
  }
  return value.cast<String>().toSet();
}

bool _sameSet(Set<String> left, Set<String> right) =>
    left.length == right.length && left.containsAll(right);

Uri _normalizedBaseUri(Uri uri) {
  _absoluteUri(uri, 'appAccessBaseUri');
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

List<String> _sorted(Iterable<String> values) =>
    values.toSet().toList()..sort();
