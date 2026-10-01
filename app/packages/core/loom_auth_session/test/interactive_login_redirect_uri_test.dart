import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:loom_auth_session/src/auth_exceptions.dart';
import 'package:loom_auth_session/src/interactive_login_io.dart';
import 'package:loom_auth_session/src/secure_storage_backend.dart';

/// Covers [InteractiveLoginPlatform]'s `redirectUri` constructor parameter.
/// `interactive_login_io_test.dart` covers the rest of this class and is
/// left untouched: every test there always injects its own
/// `authorizationLauncher`, so none of them exercise the default launcher
/// this file mocks via the `flutter_web_auth_2` method channel.
void main() {
  const flutterWebAuth2Channel = MethodChannel('flutter_web_auth_2');
  const sessionStorageKey = 'loom.auth_session.tokens.v1';
  final issuerUri = Uri.parse('https://identity.test/realms/loom');
  late _MemorySecureStorage storage;
  late List<http.Request> requests;

  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    storage = _MemorySecureStorage();
    requests = [];
  });

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(flutterWebAuth2Channel, null);
  });

  test(
    'a configured redirect URI is carried as redirect_uri and used as the '
    'callback URL scheme',
    () async {
      String? capturedUrl;
      String? capturedCallbackUrlScheme;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(flutterWebAuth2Channel, (call) async {
            final arguments = call.arguments as Map<Object?, Object?>;
            capturedUrl = arguments['url'] as String;
            capturedCallbackUrlScheme = arguments['callbackUrlScheme'] as String;
            final authorizationUri = Uri.parse(capturedUrl!);
            return 'com.loom.ai-controller:/oauthredirect?'
                'code=approved-code&'
                'state=${authorizationUri.queryParameters['state']}';
          });

      final platform = _platform(
        issuerUri: issuerUri,
        storage: storage,
        requests: requests,
        redirectUri: Uri.parse('com.loom.ai-controller:/oauthredirect'),
      );

      await platform.start();

      expect(
        Uri.parse(capturedUrl!).queryParameters['redirect_uri'],
        'com.loom.ai-controller:/oauthredirect',
      );
      expect(capturedCallbackUrlScheme, 'com.loom.ai-controller');
      expect(storage.values[sessionStorageKey], contains('access-token'));
    },
  );

  test(
    'a callback on the default scheme is rejected when a non-default '
    'redirect URI is configured',
    () async {
      final platform = _platform(
        issuerUri: issuerUri,
        storage: storage,
        requests: requests,
        redirectUri: Uri.parse('com.loom.ai-controller:/oauthredirect'),
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
    },
  );

  test('omitting the redirect URI sends the long-registered default', () async {
    String? capturedAuthorizationUri;
    final platform = _platform(
      issuerUri: issuerUri,
      storage: storage,
      requests: requests,
      authorizationLauncher: (authorizationUri) async {
        capturedAuthorizationUri = authorizationUri.toString();
        return Uri.parse(
          'com.loom.communities:/oauthredirect?'
          'code=approved-code&state=${authorizationUri.queryParameters['state']}',
        );
      },
    );

    await platform.start();

    expect(
      Uri.parse(capturedAuthorizationUri!).queryParameters['redirect_uri'],
      'com.loom.communities:/oauthredirect',
    );
  });
}

InteractiveLoginPlatform _platform({
  required Uri issuerUri,
  required _MemorySecureStorage storage,
  required List<http.Request> requests,
  Uri? redirectUri,
  Future<Uri> Function(Uri authorizationUri)? authorizationLauncher,
  Future<Uri?> Function()? callbackReader,
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
  persistTokens: (tokens) async {
    await storage.write(
      key: 'loom.auth_session.tokens.v1',
      value: jsonEncode(tokens),
    );
  },
  redirectUri: redirectUri,
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
