import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:loom_auth_session/src/auth_exceptions.dart';
import 'package:loom_auth_session/src/interactive_login_io.dart';
import 'package:loom_auth_session/src/secure_storage_backend.dart';
import 'package:test/test.dart';

void main() {
  const sessionStorageKey = 'loom.auth_session.tokens.v1';
  final issuerUri = Uri.parse('https://identity.test/realms/loom');
  late _MemorySecureStorage storage;
  late List<http.Request> requests;

  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    storage = _MemorySecureStorage();
    requests = [];
  });

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
  });

  test('foreign callback state is rejected before the code exchange', () async {
    final platform = _platform(
      issuerUri: issuerUri,
      storage: storage,
      requests: requests,
      authorizationLauncher: (_) async => Uri.parse(
        'com.loom.communities:/oauthredirect?code=foreign-code&state=forged',
      ),
    );

    await expectLater(
      platform.start(),
      throwsA(isA<LoomAuthStateMismatchException>()),
    );

    expect(requests.where((request) => request.method == 'POST'), isEmpty);
    expect(storage.values[sessionStorageKey], isNull);
  });

  test('callback without a pending transaction is rejected', () async {
    final platform = _platform(
      issuerUri: issuerUri,
      storage: storage,
      requests: requests,
      callbackReader: () async => Uri.parse(
        'com.loom.communities:/oauthredirect?code=untrusted&state=untrusted',
      ),
    );

    await expectLater(
      platform.complete(),
      throwsA(isA<LoomAuthStateMismatchException>()),
    );

    expect(requests, isEmpty);
    expect(storage.values[sessionStorageKey], isNull);
  });

  test(
    'unexpected callback redirect is rejected before code exchange',
    () async {
      final platform = _platform(
        issuerUri: issuerUri,
        storage: storage,
        requests: requests,
        authorizationLauncher: (_) async => Uri.parse(
          'com.attacker.app:/oauthredirect?code=foreign-code&state=forged',
        ),
      );

      await expectLater(
        platform.start(),
        throwsA(isA<LoomAuthStateMismatchException>()),
      );

      expect(
        requests.where((request) => request.method == 'POST'),
        isEmpty,
      );
      expect(storage.values[sessionStorageKey], isNull);
    },
  );

  test(
    'cancelled authorization removes the pending transaction and session',
    () async {
      final platform = _platform(
        issuerUri: issuerUri,
        storage: storage,
        requests: requests,
        authorizationLauncher: (_) =>
            Future<Uri>.error(StateError('cancelled')),
      );

      await expectLater(
        platform.start(),
        throwsA(
          isA<LoomAuthInteractiveLoginException>().having(
            (error) => error.oauthError,
            'oauthError',
            'authorization_cancelled',
          ),
        ),
      );

      expect(storage.values, isEmpty);
      expect(requests.where((request) => request.method == 'POST'), isEmpty);
    },
  );

  test('provider error removes the pending transaction and session', () async {
    final platform = _platform(
      issuerUri: issuerUri,
      storage: storage,
      requests: requests,
      authorizationLauncher: (authorizationUri) async => Uri.parse(
        'com.loom.communities:/oauthredirect?'
        'error=access_denied&state=${authorizationUri.queryParameters['state']}',
      ),
    );

    await expectLater(
      platform.start(),
      throwsA(isA<LoomAuthInteractiveLoginException>()),
    );

    expect(storage.values, isEmpty);
    expect(requests.where((request) => request.method == 'POST'), isEmpty);
  });

  test(
    'successful authorization exchanges and persists tokens through storage',
    () async {
      Map<String, dynamic>? persistedTokens;
      final platform = _platform(
        issuerUri: issuerUri,
        storage: storage,
        requests: requests,
        authorizationLauncher: (authorizationUri) async => Uri.parse(
          'com.loom.communities:/oauthredirect?'
          'code=approved-code&state=${authorizationUri.queryParameters['state']}',
        ),
        persistTokens: (tokens) async {
          persistedTokens = tokens;
          await storage.write(
            key: sessionStorageKey,
            value: jsonEncode(tokens),
          );
        },
      );

      await platform.start();

      expect(persistedTokens?['access_token'], 'access-token');
      expect(storage.values[sessionStorageKey], contains('access-token'));
      expect(
        storage.values[InteractiveLoginPlatform.transactionStorageKey],
        isNull,
      );
      final tokenRequest = requests.singleWhere(
        (request) => request.method == 'POST',
      );
      expect(tokenRequest.bodyFields['grant_type'], 'authorization_code');
      expect(tokenRequest.bodyFields, contains('code_verifier'));
    },
  );

  test('non-Android IO targets fail with a clear unsupported error', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    final platform = _platform(
      issuerUri: issuerUri,
      storage: storage,
      requests: requests,
    );

    await expectLater(
      platform.complete(),
      throwsA(
        isA<UnsupportedError>().having(
          (error) => error.message,
          'message',
          contains('Android'),
        ),
      ),
    );
  });
}

InteractiveLoginPlatform _platform({
  required Uri issuerUri,
  required _MemorySecureStorage storage,
  required List<http.Request> requests,
  Future<Uri> Function(Uri authorizationUri)? authorizationLauncher,
  Future<Uri?> Function()? callbackReader,
  Future<void> Function(Map<String, dynamic>)? persistTokens,
}) => InteractiveLoginPlatform(
  issuerUri: issuerUri,
  clientId: 'loom-test-client',
  httpClient: MockClient((request) async {
    requests.add(request);
    if (request.method == 'GET') return _issuerMetadata(request);
    if (request.method == 'POST') return _tokenResponse(request);
    throw StateError('Unexpected HTTP request.');
  }),
  pendingTransactionStorage: storage,
  persistTokens: persistTokens ?? (_) async {},
  authorizationLauncher: authorizationLauncher,
  callbackReader: callbackReader,
);

http.Response _issuerMetadata(http.BaseRequest request) => http.Response(
  jsonEncode({
    'issuer': 'https://identity.test/realms/loom',
    'authorization_endpoint':
        'https://identity.test/realms/loom/protocol/openid-connect/auth',
    'token_endpoint':
        'https://identity.test/realms/loom/protocol/openid-connect/token',
    'response_types_supported': ['code'],
    'subject_types_supported': ['public'],
    'id_token_signing_alg_values_supported': ['RS256'],
    'scopes_supported': ['openid', 'profile', 'email'],
  }),
  200,
  request: request,
  headers: const {'content-type': 'application/json'},
);

http.Response _tokenResponse(http.BaseRequest request) => http.Response(
  jsonEncode({
    'access_token': 'access-token',
    'refresh_token': 'refresh-token',
    'expires_in': 300,
    'refresh_expires_in': 1800,
    'token_type': 'Bearer',
  }),
  200,
  request: request,
  headers: const {'content-type': 'application/json'},
);

final class _MemorySecureStorage implements LoomAuthSecureStorageBackend {
  final Map<String, String> values = {};

  @override
  Future<void> delete({required String key}) async {
    values.remove(key);
  }

  @override
  Future<String?> read({required String key}) async => values[key];

  @override
  Future<void> write({required String key, required String value}) async {
    values[key] = value;
  }
}
