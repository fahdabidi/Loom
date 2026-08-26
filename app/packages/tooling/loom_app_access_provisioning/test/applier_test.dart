import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:loom_app_access_provisioning/loom_app_access_provisioning.dart';
import 'package:test/test.dart';

void main() {
  test('dry run is the default and makes no HTTP calls', () async {
    final fake = await _FakeAppAccessServer.start();
    addTearDown(fake.close);
    final planFile = await _writePlanFile(_testPlan());
    addTearDown(planFile.delete);
    final out = StringBuffer();
    final err = StringBuffer();

    final exitCode = await runApplyAppAccessProvisioning(
      [planFile.path],
      stdoutSink: out,
      stderrSink: err,
    );

    expect(exitCode, 0);
    expect(err.toString(), isEmpty);
    expect(out.toString(), contains('Dry run: 0 network calls made.'));
    expect(
      out.toString(),
      contains('WOULD POST installation for community_test'),
    );
    expect(out.toString(), contains('"communityHandle": "test"'));
    expect(fake.requests, isEmpty);
  });

  test('200 installation records its returned group id', () async {
    final fake = await _FakeAppAccessServer.start();
    addTearDown(fake.close);
    final applier = _applierFor(fake);
    addTearDown(applier.close);

    final result = await applier.apply(_testPlan());

    expect(result.hasFailures, isFalse);
    expect(result.communityGroupIds, {'community_test': 'server-group-test'});
    expect(result.installations.single.rolesWithNoPermissions, [
      'test-observer',
    ]);
    final installationRequests = fake.requests
        .where(
          (request) =>
              request.path ==
                  '/v1/apps/loom_communities/community-installations' &&
              request.method == 'POST',
        )
        .toList();
    expect(installationRequests, hasLength(1));
    final request = installationRequests.single;
    expect(request.correlationId, matches(_uuidV4));
    expect(request.idempotencyKey, startsWith('community-installation-'));
    expect(request.body, _testPlan().communities.single.request.toJson());
    expect(
      fake.requests.where(
        (request) =>
            request.path.startsWith('/v1/apps/loom_communities/') &&
            request.path != '/v1/apps/loom_communities/community-installations',
      ),
      isEmpty,
    );
  });

  test('422 surfaces every server finding and fails that community', () async {
    final fake = await _FakeAppAccessServer.start();
    addTearDown(fake.close);
    fake.installationResponses['test'] = const _FakeResponse(
      HttpStatus.unprocessableEntity,
      {
        'appId': 'loom_communities',
        'groupId': 'server-group-test',
        'rolesRegistered': <String>[],
        'permissionsGranted': 0,
        'findings': [
          {
            'code': 'unknown_action_for_archetype',
            'message': 'test-do is not allowed for event-rsvp',
            'workflowType': 'test-workflow',
            'transitionId': 'test-transition',
          },
          {
            'code': 'undeclared_role_in_guard',
            'message': 'missing-role is not declared',
            'workflowType': 'test-workflow',
            'transitionId': 'other-transition',
          },
        ],
      },
    );
    final planFile = await _writePlanFile(_testPlan());
    addTearDown(planFile.delete);
    final out = StringBuffer();
    final err = StringBuffer();

    final exitCode = await runApplyAppAccessProvisioning(
      [planFile.path, '--apply'],
      environment: _environmentFor(fake),
      stdoutSink: out,
      stderrSink: err,
    );

    expect(exitCode, 1);
    expect(out.toString(), contains('"communityGroupIds": {}'));
    expect(err.toString(), contains('unknown_action_for_archetype'));
    expect(err.toString(), contains('test-do is not allowed for event-rsvp'));
    expect(err.toString(), contains('undeclared_role_in_guard'));
    expect(err.toString(), contains('missing-role is not declared'));
  });

  test('HTTP failures retain their JSON error body', () async {
    final fake = await _FakeAppAccessServer.start();
    addTearDown(fake.close);
    fake.installationResponses['test'] = const _FakeResponse(
      HttpStatus.internalServerError,
      {
        'code': 'installation_unavailable',
        'message': 'App Access is unavailable',
      },
    );
    final applier = _applierFor(fake);
    addTearDown(applier.close);

    await expectLater(
      applier.apply(_testPlan()),
      throwsA(
        isA<HttpException>().having(
          (error) => error.message,
          'message',
          allOf(contains('installation_unavailable'), contains('HTTP 500')),
        ),
      ),
    );
  });

  test(
    'successful apply reports roles with no permissions prominently',
    () async {
      final fake = await _FakeAppAccessServer.start();
      addTearDown(fake.close);
      final planFile = await _writePlanFile(_testPlan());
      addTearDown(planFile.delete);
      final out = StringBuffer();
      final err = StringBuffer();

      final exitCode = await runApplyAppAccessProvisioning(
        [planFile.path, '--apply'],
        environment: _environmentFor(fake),
        stdoutSink: out,
        stderrSink: err,
      );

      expect(exitCode, 0);
      expect(err.toString(), isEmpty);
      expect(
        out.toString(),
        contains(
          'WARNING: community_test rolesWithNoPermissions: test-observer',
        ),
      );
      expect(out.toString(), contains('"community_test": "server-group-test"'));
    },
  );
}

final _uuidV4 = RegExp(
  r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
);

AppAccessProvisioningPlan _testPlan() => const AppAccessProvisioningPlan(
  communities: [
    CommunityInstallationPlanEntry(
      communityId: 'community_test',
      request: InstallCommunityPackageRequest(
        communityHandle: 'test',
        displayName: 'Test Community',
        grammarVersion: 4,
        roles: [
          DerivedRoleInput(roleId: 'test-member', label: 'Member'),
          DerivedRoleInput(roleId: 'test-observer', label: 'Observer'),
        ],
        workflows: [
          DerivedWorkflowInput(
            workflowType: 'test-workflow',
            cardSurfaceFamily: 'event-rsvp',
            createRoleIds: ['test-member'],
            transitions: [
              DerivedTransitionInput(
                transitionId: 'test-transition',
                action: null,
                tone: 'primary',
                isTerminal: false,
                allowedRoleIds: ['test-member'],
              ),
            ],
          ),
        ],
      ),
    ),
  ],
);

HttpAppAccessProvisioningApplier _applierFor(_FakeAppAccessServer fake) =>
    HttpAppAccessProvisioningApplier(
      config: AppAccessProvisioningConfig(
        appAccessBaseUri: fake.baseUri,
        tokenUri: fake.baseUri.resolve('token'),
        clientId: 'test-client',
        clientSecret: 'test-secret',
        appId: 'loom_communities',
      ),
    );

Map<String, String> _environmentFor(_FakeAppAccessServer fake) => {
  'LOOM_APP_ACCESS_BASE_URL': fake.baseUri.toString(),
  'LOOM_KEYCLOAK_TOKEN_URL': fake.baseUri.resolve('token').toString(),
  'LOOM_APP_ACCESS_CLIENT_ID': 'test-client',
  'LOOM_APP_ACCESS_CLIENT_SECRET': 'test-secret',
  'LOOM_APP_ID': 'loom_communities',
};

Future<File> _writePlanFile(AppAccessProvisioningPlan plan) async {
  final file = File(
    '${Directory.systemTemp.path}/'
    'loom-app-access-provisioning-${DateTime.now().microsecondsSinceEpoch}.json',
  );
  await file.writeAsString(plan.encode());
  return file;
}

class _FakeAppAccessServer {
  _FakeAppAccessServer._(this._server) {
    _subscription = _server.listen(_handle);
  }

  final HttpServer _server;
  late final StreamSubscription<HttpRequest> _subscription;
  final Map<String, _FakeResponse> installationResponses = {};
  final List<_CapturedRequest> requests = [];

  Uri get baseUri =>
      Uri.parse('http://${_server.address.address}:${_server.port}/');

  static Future<_FakeAppAccessServer> start() async => _FakeAppAccessServer._(
    await HttpServer.bind(InternetAddress.loopbackIPv4, 0),
  );

  Future<void> _handle(HttpRequest request) async {
    final body = await utf8.decoder.bind(request).join();
    requests.add(
      _CapturedRequest(
        method: request.method,
        path: request.uri.path,
        correlationId: request.headers.value('x-loom-correlation-id'),
        idempotencyKey: request.headers.value('idempotency-key'),
        body: request.uri.path == '/token' || body.trim().isEmpty
            ? null
            : Map<String, Object?>.from(jsonDecode(body) as Map),
      ),
    );
    if (request.uri.path == '/token' && request.method == 'POST') {
      await _json(request.response, HttpStatus.ok, {
        'access_token': 'test-token',
        'expires_in': 3600,
      });
      return;
    }
    if (request.uri.path ==
            '/v1/apps/loom_communities/community-installations' &&
        request.method == 'POST') {
      final payload = Map<String, Object?>.from(jsonDecode(body) as Map);
      final communityHandle = payload['communityHandle'] as String;
      final result =
          installationResponses[communityHandle] ??
          const _FakeResponse(HttpStatus.ok, {
            'appId': 'loom_communities',
            'groupId': 'server-group-test',
            'rolesRegistered': ['test-member', 'test-observer'],
            'removedRoleIds': <String>[],
            'permissionsGranted': 3,
            'rolesWithNoPermissions': ['test-observer'],
            'findings': <Object>[],
          });
      await _json(request.response, result.statusCode, result.body);
      return;
    }
    await _json(request.response, HttpStatus.notFound, {'error': 'not found'});
  }

  Future<void> close() async {
    await _subscription.cancel();
    await _server.close(force: true);
  }
}

class _FakeResponse {
  const _FakeResponse(this.statusCode, this.body);

  final int statusCode;
  final JsonMap body;
}

Future<void> _json(HttpResponse response, int status, Object value) async {
  response.statusCode = status;
  response.headers.contentType = ContentType.json;
  response.write(jsonEncode(value));
  await response.close();
}

class _CapturedRequest {
  const _CapturedRequest({
    required this.method,
    required this.path,
    required this.correlationId,
    required this.idempotencyKey,
    required this.body,
  });

  final String method;
  final String path;
  final String? correlationId;
  final String? idempotencyKey;
  final Map<String, Object?>? body;
}
