import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:loom_workflow_service/loom_workflow_service.dart';
import 'package:test/test.dart';

void main() {
  late _RecordingHttpClient httpClient;
  late HttpAppAccessDecisionClient client;
  var now = DateTime.utc(2026, 8, 16, 12);

  setUp(() {
    httpClient = _RecordingHttpClient();
    client = HttpAppAccessDecisionClient(
      baseUri: Uri.parse('https://app-access.test/'),
      tokenUri: Uri.parse('https://identity.test/realms/loom/token'),
      clientId: 'loom-workflow-service',
      clientSecret: 'test secret',
      httpClient: httpClient,
      clock: () => now,
    );
  });

  tearDown(() {
    client.close(force: true);
  });

  test(
    'attaches the Keycloak bearer token to the App Access request',
    () async {
      httpClient.tokens.add(('token-one', 300));

      final allowed = await _checkAccess(client);

      expect(allowed, isTrue);
      expect(httpClient.authorizationHeaders, ['Bearer token-one']);
      expect(httpClient.tokenRequestCount, 1);
      expect(
        httpClient.tokenRequestBodies.single,
        'grant_type=client_credentials&client_id=loom-workflow-service&'
        'client_secret=test+secret',
      );
    },
  );

  test('reuses a cached token for repeated access decisions', () async {
    httpClient.tokens.add(('token-one', 300));

    await _checkAccess(client);
    await _checkAccess(client);

    expect(httpClient.tokenRequestCount, 1);
    expect(httpClient.authorizationHeaders, [
      'Bearer token-one',
      'Bearer token-one',
    ]);
  });

  test('refreshes a token proactively when it is nearing expiry', () async {
    httpClient.tokens.addAll([('token-one', 120), ('token-two', 120)]);

    await _checkAccess(client);
    now = now.add(const Duration(seconds: 91));
    await _checkAccess(client);

    expect(httpClient.tokenRequestCount, 2);
    expect(httpClient.authorizationHeaders, [
      'Bearer token-one',
      'Bearer token-two',
    ]);
  });

  test(
    'wraps token acquisition failure as AppAccessDecisionException',
    () async {
      httpClient.tokenStatusCode = HttpStatus.unauthorized;

      await expectLater(
        _checkAccess(client),
        throwsA(
          isA<AppAccessDecisionException>().having(
            (error) => error.statusCode,
            'statusCode',
            HttpStatus.unauthorized,
          ),
        ),
      );
      expect(httpClient.tokenRequestCount, 1);
      expect(httpClient.accessRequestCount, 0);
    },
  );

  test(
    'resolves roleIds from effective permissions with group and correlation',
    () async {
      httpClient.tokens.add(('token-one', 300));
      httpClient.effectivePermissionsResponseBody = jsonEncode({
        'fanId': 'fan-123',
        'appId': 'loom_communities',
        'groupId': null,
        'permissionIds': <String>[],
        'roleIds': ['hoa-member', 'hoa-board'],
        'catalogVersion': '2026-08-13.1',
        'resolvedAt': '2026-08-26T00:06:37.282036473Z',
      });

      final roles = await _resolveRoleIds(client);

      expect(roles, {'hoa-member', 'hoa-board'});
      expect(
        httpClient.effectivePermissionsRequestUri,
        Uri.parse(
          'https://app-access.test/v1/apps/loom_communities/'
          'effective-permissions/fan-123?groupId=loom_communities_book-club',
        ),
      );
      expect(httpClient.effectivePermissionsAuthorizationHeaders, [
        'Bearer token-one',
      ]);
      expect(httpClient.effectivePermissionsCorrelationIds, [
        '11111111-1111-4111-8111-111111111111',
      ]);
    },
  );

  test(
    'rejects non-200 and malformed effective-permissions responses',
    () async {
      httpClient.tokens.add(('token-one', 300));

      httpClient.effectivePermissionsStatusCode = HttpStatus.serviceUnavailable;
      await expectLater(
        _resolveRoleIds(client),
        throwsA(isA<AppAccessDecisionException>()),
      );

      httpClient.effectivePermissionsStatusCode = HttpStatus.ok;
      httpClient.effectivePermissionsResponseBody = 'not-json';
      await expectLater(
        _resolveRoleIds(client),
        throwsA(isA<AppAccessDecisionException>()),
      );

      httpClient.effectivePermissionsResponseBody = jsonEncode({
        'fanId': 'fan-123',
        'appId': 'loom_communities',
        'roleIds': ['hoa-member', 3],
      });
      await expectLater(
        _resolveRoleIds(client),
        throwsA(isA<AppAccessDecisionException>()),
      );
    },
  );
}

Future<bool> _checkAccess(HttpAppAccessDecisionClient client) {
  return client.checkAccess(
    fanId: 'fan-123',
    appId: 'loom_communities',
    permissionId: 'event_rsvp.create',
    groupId: 'loom_communities_book-club',
    correlationId: '11111111-1111-4111-8111-111111111111',
  );
}

Future<Set<String>> _resolveRoleIds(HttpAppAccessDecisionClient client) async {
  return client.resolveRoleIds(
    fanId: 'fan-123',
    appId: 'loom_communities',
    groupId: 'loom_communities_book-club',
    correlationId: '11111111-1111-4111-8111-111111111111',
  );
}

class _RecordingHttpClient implements HttpClient {
  final List<(String, int)> tokens = [];
  final List<String?> authorizationHeaders = [];
  final List<String?> effectivePermissionsAuthorizationHeaders = [];
  final List<String?> effectivePermissionsCorrelationIds = [];
  final List<String> tokenRequestBodies = [];
  Uri? effectivePermissionsRequestUri;
  int tokenStatusCode = HttpStatus.ok;
  int effectivePermissionsStatusCode = HttpStatus.ok;
  String effectivePermissionsResponseBody = '{}';
  int tokenRequestCount = 0;
  int accessRequestCount = 0;

  @override
  Future<HttpClientRequest> postUrl(Uri url) async {
    return _RecordingHttpClientRequest(url, this);
  }

  @override
  Future<HttpClientRequest> getUrl(Uri url) async {
    return _RecordingHttpClientRequest(url, this);
  }

  HttpClientResponse closeRequest(
    Uri uri,
    _RecordingHttpHeaders headers,
    String body,
  ) {
    if (uri.path == '/realms/loom/token') {
      tokenRequestCount++;
      tokenRequestBodies.add(body);
      if (tokenStatusCode != HttpStatus.ok) {
        return _RecordingHttpClientResponse(
          tokenStatusCode,
          jsonEncode({'error': 'invalid_client'}),
        );
      }
      final (accessToken, expiresIn) = tokens.removeAt(0);
      return _RecordingHttpClientResponse(
        HttpStatus.ok,
        jsonEncode({'access_token': accessToken, 'expires_in': expiresIn}),
      );
    }

    if (uri.path == '/v1/access-decisions') {
      accessRequestCount++;
      authorizationHeaders.add(headers.value(HttpHeaders.authorizationHeader));
      final decoded = jsonDecode(body) as Map<String, dynamic>;
      return _RecordingHttpClientResponse(
        HttpStatus.ok,
        jsonEncode({...decoded, 'allowed': true}),
      );
    }

    if (uri.path == '/v1/apps/loom_communities/effective-permissions/fan-123') {
      effectivePermissionsRequestUri = uri;
      effectivePermissionsAuthorizationHeaders.add(
        headers.value(HttpHeaders.authorizationHeader),
      );
      effectivePermissionsCorrelationIds.add(
        headers.value('x-loom-correlation-id'),
      );
      return _RecordingHttpClientResponse(
        effectivePermissionsStatusCode,
        effectivePermissionsResponseBody,
      );
    }

    return _RecordingHttpClientResponse(HttpStatus.notFound, '');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _RecordingHttpClientRequest implements HttpClientRequest {
  _RecordingHttpClientRequest(this.uri, this._client);

  final _RecordingHttpClient _client;
  final StringBuffer _body = StringBuffer();

  @override
  final _RecordingHttpHeaders headers = _RecordingHttpHeaders();

  @override
  final Uri uri;

  @override
  void write(Object? object) {
    _body.write(object);
  }

  @override
  Future<HttpClientResponse> close() async {
    return _client.closeRequest(uri, headers, _body.toString());
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _RecordingHttpHeaders implements HttpHeaders {
  final Map<String, List<String>> _values = {};

  @override
  ContentType? contentType;

  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) {
    _values[name.toLowerCase()] = [value.toString()];
  }

  @override
  String? value(String name) => _values[name.toLowerCase()]?.single;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _RecordingHttpClientResponse extends Stream<List<int>>
    implements HttpClientResponse {
  _RecordingHttpClientResponse(this.statusCode, String body)
    : _bytes = utf8.encode(body);

  final List<int> _bytes;

  @override
  final int statusCode;

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return Stream<List<int>>.value(_bytes).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
