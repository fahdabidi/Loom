import 'dart:convert';
import 'dart:io';

/// The one App Access operation required by the workflow service.
abstract interface class AppAccessDecisionClient {
  Future<bool> checkAccess({
    required String fanId,
    required String appId,
    required String permissionId,
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

/// Minimal HTTP client for App Access's `POST /v1/access-decisions` operation.
class HttpAppAccessDecisionClient implements AppAccessDecisionClient {
  HttpAppAccessDecisionClient({required Uri baseUri, HttpClient? httpClient})
    : _baseUri = _normalizeBaseUri(baseUri),
      _httpClient = httpClient ?? HttpClient(),
      _ownsHttpClient = httpClient == null;

  final Uri _baseUri;
  final HttpClient _httpClient;
  final bool _ownsHttpClient;

  @override
  Future<bool> checkAccess({
    required String fanId,
    required String appId,
    required String permissionId,
    required String groupId,
    required String correlationId,
  }) async {
    final request = await _httpClient.postUrl(
      _baseUri.resolve('v1/access-decisions'),
    );
    request.headers.contentType = ContentType.json;
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

  void close({bool force = false}) {
    if (_ownsHttpClient) _httpClient.close(force: force);
  }

  static Uri _normalizeBaseUri(Uri baseUri) {
    if (!baseUri.hasScheme || baseUri.host.isEmpty) {
      throw ArgumentError.value(baseUri, 'baseUri', 'must be an absolute URI');
    }
    final path = baseUri.path.endsWith('/') ? baseUri.path : '${baseUri.path}/';
    return baseUri.replace(path: path, query: null, fragment: null);
  }
}
