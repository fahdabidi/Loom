import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:loom_auth_session/loom_auth_session.dart';
import 'package:test/test.dart';

void main() {
  final tokenEndpoint = Uri.parse(
    'https://identity.test/realms/loom/protocol/openid-connect/token',
  );
  late DateTime now;
  late _MemorySecureStorage storage;
  late List<http.Request> requests;
  late List<http.Response> responses;
  late LoomAuthSession session;

  setUp(() {
    now = DateTime.utc(2026, 8, 16, 12);
    storage = _MemorySecureStorage();
    requests = [];
    responses = [];
    session = LoomAuthSession(
      tokenEndpoint: tokenEndpoint,
      clientId: 'loom-test-client',
      secureStorage: storage,
      httpClient: MockClient((request) async {
        requests.add(request);
        return responses.removeAt(0);
      }),
      clock: () => now,
    );
  });

  test('returns a cached access token while it is unexpired', () async {
    responses.add(_tokenResponse(accessToken: 'access-one'));
    await session.loginWithTestCredentials(
      username: 'test-fan-alice',
      password: 'test password',
    );
    final requestCountAfterLogin = requests.length;

    expect(await session.currentAccessToken(), 'access-one');
    expect(requests, hasLength(requestCountAfterLogin));
  });

  test('proactively refreshes a token that is nearing expiry', () async {
    responses.addAll([
      _tokenResponse(accessToken: 'access-one', expiresIn: 120),
      _tokenResponse(accessToken: 'access-two', refreshToken: 'refresh-two'),
    ]);
    await session.loginWithTestCredentials(
      username: 'test-fan-alice',
      password: 'test password',
    );
    now = now.add(const Duration(seconds: 91));

    expect(await session.currentAccessToken(), 'access-two');
    expect(requests.last.bodyFields, {
      'grant_type': 'refresh_token',
      'client_id': 'loom-test-client',
      'refresh_token': 'refresh-one',
    });
  });

  test('refreshes an expired token and re-stores the new tokens', () async {
    responses.addAll([
      _tokenResponse(accessToken: 'access-one', expiresIn: 60),
      _tokenResponse(accessToken: 'access-two', refreshToken: 'refresh-two'),
    ]);
    await session.loginWithTestCredentials(
      username: 'test-fan-alice',
      password: 'test password',
    );
    now = now.add(const Duration(seconds: 61));

    expect(await session.currentAccessToken(), 'access-two');

    final restarted = LoomAuthSession(
      tokenEndpoint: tokenEndpoint,
      clientId: 'loom-test-client',
      secureStorage: storage,
      httpClient: MockClient((_) async => throw StateError('unexpected HTTP')),
      clock: () => now,
    );
    expect(await restarted.currentAccessToken(), 'access-two');
  });

  test('coalesces concurrent refresh-token exchanges', () async {
    responses.add(_tokenResponse(accessToken: 'access-one', expiresIn: 60));
    await session.loginWithTestCredentials(
      username: 'test-fan-alice',
      password: 'test password',
    );
    now = now.add(const Duration(seconds: 61));
    final responseCompleter = Completer<http.Response>();
    session = LoomAuthSession(
      tokenEndpoint: tokenEndpoint,
      clientId: 'loom-test-client',
      secureStorage: storage,
      httpClient: MockClient((request) {
        requests.add(request);
        return responseCompleter.future;
      }),
      clock: () => now,
    );

    final first = session.currentAccessToken();
    final second = session.currentAccessToken();
    await Future<void>.delayed(Duration.zero);
    responseCompleter.complete(
      _tokenResponse(accessToken: 'access-two', refreshToken: 'refresh-two'),
    );

    expect(await Future.wait([first, second]), ['access-two', 'access-two']);
    expect(
      requests.where(
        (request) => request.bodyFields['grant_type'] == 'refresh_token',
      ),
      hasLength(1),
    );
  });

  test('no prior login throws without making an HTTP call', () async {
    await expectLater(
      session.currentAccessToken(),
      throwsA(isA<LoomAuthNotLoggedInException>()),
    );
    expect(requests, isEmpty);
  });

  test(
    'test credential login posts a password grant and stores tokens',
    () async {
      responses.add(_tokenResponse(accessToken: 'access-one'));

      await session.loginWithTestCredentials(
        username: 'test-fan-alice',
        password: 'LoomTest123!',
      );

      expect(requests.single.method, 'POST');
      expect(requests.single.url, tokenEndpoint);
      expect(requests.single.bodyFields, {
        'grant_type': 'password',
        'client_id': 'loom-test-client',
        'username': 'test-fan-alice',
        'password': 'LoomTest123!',
      });
      expect(storage.values.values.single, contains('access-one'));
      expect(storage.values.values.single, contains('refresh-one'));
    },
  );

  test(
    'bad test credentials are clear and do not store a partial session',
    () async {
      responses.add(
        http.Response(
          jsonEncode({
            'error': 'invalid_grant',
            'error_description': 'Invalid user credentials',
          }),
          401,
          headers: const {'content-type': 'application/json'},
        ),
      );

      await expectLater(
        session.loginWithTestCredentials(
          username: 'test-fan-alice',
          password: 'bad password',
        ),
        throwsA(
          isA<LoomAuthTestCredentialsRejectedException>()
              .having((error) => error.statusCode, 'statusCode', 401)
              .having(
                (error) => error.oauthError,
                'oauthError',
                'invalid_grant',
              ),
        ),
      );
      expect(storage.values, isEmpty);
    },
  );

  test('logout clears persistence and leaves no current session', () async {
    responses.add(_tokenResponse(accessToken: 'access-one'));
    await session.loginWithTestCredentials(
      username: 'test-fan-alice',
      password: 'test password',
    );

    await session.logout();

    expect(storage.values, isEmpty);
    await expectLater(
      session.currentAccessToken(),
      throwsA(isA<LoomAuthNotLoggedInException>()),
    );
  });

  test('known refresh-token expiry requires login without HTTP', () async {
    responses.add(
      _tokenResponse(
        accessToken: 'access-one',
        expiresIn: 60,
        refreshExpiresIn: 60,
      ),
    );
    await session.loginWithTestCredentials(
      username: 'test-fan-alice',
      password: 'test password',
    );
    now = now.add(const Duration(seconds: 61));
    final requestCountAfterLogin = requests.length;

    await expectLater(
      session.currentAccessToken(),
      throwsA(isA<LoomAuthRefreshTokenExpiredException>()),
    );
    expect(requests, hasLength(requestCountAfterLogin));
    expect(storage.values, isEmpty);
  });

  test('invalid_grant refresh requires login and clears persistence', () async {
    responses.addAll([
      _tokenResponse(accessToken: 'access-one', expiresIn: 60),
      http.Response(jsonEncode({'error': 'invalid_grant'}), 400),
    ]);
    await session.loginWithTestCredentials(
      username: 'test-fan-alice',
      password: 'test password',
    );
    now = now.add(const Duration(seconds: 61));

    await expectLater(
      session.currentAccessToken(),
      throwsA(isA<LoomAuthRefreshTokenExpiredException>()),
    );
    expect(storage.values, isEmpty);
  });

  test('network failure stays distinct from login-required failures', () async {
    responses.add(_tokenResponse(accessToken: 'access-one', expiresIn: 60));
    await session.loginWithTestCredentials(
      username: 'test-fan-alice',
      password: 'test password',
    );
    now = now.add(const Duration(seconds: 61));
    session = LoomAuthSession(
      tokenEndpoint: tokenEndpoint,
      clientId: 'loom-test-client',
      secureStorage: storage,
      httpClient: MockClient(
        (_) async => throw http.ClientException('network unavailable'),
      ),
      clock: () => now,
    );

    await expectLater(
      session.currentAccessToken(),
      throwsA(isA<LoomAuthNetworkException>()),
    );
    expect(storage.values, isNotEmpty);
  });
}

http.Response _tokenResponse({
  required String accessToken,
  String refreshToken = 'refresh-one',
  int expiresIn = 300,
  int refreshExpiresIn = 1800,
}) => http.Response(
  jsonEncode({
    'access_token': accessToken,
    'refresh_token': refreshToken,
    'expires_in': expiresIn,
    'refresh_expires_in': refreshExpiresIn,
    'token_type': 'Bearer',
  }),
  200,
  headers: const {'content-type': 'application/json'},
);

class _MemorySecureStorage implements LoomAuthSecureStorageBackend {
  final Map<String, String> values = {};

  @override
  Future<String?> read({required String key}) async => values[key];

  @override
  Future<void> write({required String key, required String value}) async {
    values[key] = value;
  }

  @override
  Future<void> delete({required String key}) async {
    values.remove(key);
  }
}
