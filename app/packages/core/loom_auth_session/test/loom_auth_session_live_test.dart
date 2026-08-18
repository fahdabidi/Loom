import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:loom_auth_session/loom_auth_session.dart';
import 'package:test/test.dart';

void main() {
  test('live Keycloak login returns test-fan-alice fanId claim', () async {
    final client = _TimeoutClient(http.Client(), const Duration(seconds: 5));
    final session = LoomAuthSession(
      tokenEndpoint: Uri.parse(
        'http://localhost:30082/realms/loom/'
        'protocol/openid-connect/token',
      ),
      clientId: 'loom-test-client',
      secureStorage: _MemorySecureStorage(),
      httpClient: client,
    );

    try {
      await session.loginWithTestCredentials(
        username: 'test-fan-alice',
        password: 'LoomTest123!',
      );
    } on LoomAuthNetworkException catch (error) {
      markTestSkipped('Live Keycloak NodePort is unreachable: $error');
      return;
    } finally {
      client.close();
    }

    final token = await session.currentAccessToken();
    final claims = _decodeJwtClaims(token);
    expect(claims['iss'], 'http://localhost:30082/realms/loom');
    expect(claims['fanId'], 'fan-test-alice');
  });
}

Map<String, dynamic> _decodeJwtClaims(String token) {
  final parts = token.split('.');
  if (parts.length != 3) {
    throw const FormatException('Keycloak access token is not a compact JWT');
  }
  final payload = utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
  final decoded = jsonDecode(payload);
  if (decoded is! Map<String, dynamic>) {
    throw const FormatException('Keycloak JWT claims are not a JSON object');
  }
  return decoded;
}

class _TimeoutClient extends http.BaseClient {
  _TimeoutClient(this._inner, this._timeout);

  final http.Client _inner;
  final Duration _timeout;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) =>
      _inner.send(request).timeout(_timeout);

  @override
  void close() => _inner.close();
}

class _MemorySecureStorage implements LoomAuthSecureStorageBackend {
  final Map<String, String> _values = {};

  @override
  Future<String?> read({required String key}) async => _values[key];

  @override
  Future<void> write({required String key, required String value}) async {
    _values[key] = value;
  }

  @override
  Future<void> delete({required String key}) async {
    _values.remove(key);
  }
}
