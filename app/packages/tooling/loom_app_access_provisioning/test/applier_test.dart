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
      contains('WOULD ENSURE group loom_communities_test'),
    );
    expect(fake.requests, isEmpty);
  });

  test('applier reconciles once, then reruns as a no-op', () async {
    final fake = await _FakeAppAccessServer.start();
    addTearDown(fake.close);
    final applier = HttpAppAccessProvisioningApplier(
      config: AppAccessProvisioningConfig(
        appAccessBaseUri: fake.baseUri,
        tokenUri: fake.baseUri.resolve('token'),
        clientId: 'test-client',
        clientSecret: 'test-secret',
        appId: 'loom_communities',
      ),
    );
    addTearDown(applier.close);

    final first = await applier.apply(_testPlan());
    final second = await applier.apply(_testPlan());

    expect(first.createdGroupIds, ['loom_communities_test']);
    expect(first.createdRoleIds, ['test-admin', 'test-member']);
    expect(first.updatedRolePermissionIds, isEmpty);
    expect(second.createdGroupIds, isEmpty);
    expect(second.createdRoleIds, isEmpty);
    expect(second.updatedRolePermissionIds, isEmpty);
    expect(second.unchangedGroupIds, ['loom_communities_test']);
    expect(second.unchangedRoleIds, ['test-admin', 'test-member']);
    expect(fake.groups.keys, ['loom_communities_test']);
    expect(fake.roles.keys, ['test-member', 'test-admin']);

    final appRequests = fake.requests.where(
      (request) => request.path.startsWith('/v1/'),
    );
    for (final request in appRequests) {
      expect(request.correlationId, matches(_uuidV4));
      if (request.method == 'POST' || request.method == 'PUT') {
        expect(request.idempotencyKey, startsWith('provisioning-'));
      }
    }
    expect(
      fake.requests.where((request) => request.method == 'DELETE'),
      isEmpty,
    );
  });
}

final _uuidV4 = RegExp(
  r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
);

AppAccessProvisioningPlan _testPlan() => const AppAccessProvisioningPlan(
  communities: const [
    CommunityProvisioningEntry(
      communityId: 'community_test',
      groupId: 'loom_communities_test',
      displayName: 'Test Community',
      roles: [
        RoleProvisioningEntry(
          roleId: 'test-member',
          displayName: 'Member',
          permissionIds: ['event_rsvp.create'],
        ),
        RoleProvisioningEntry(
          roleId: 'test-admin',
          displayName: 'Admin',
          permissionIds: ['event_rsvp.create', 'event_rsvp.cancel'],
        ),
      ],
      workflows: [],
    ),
  ],
  communityGroupIds: {'community_test': 'loom_communities_test'},
);

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
  final Map<String, Map<String, Object?>> groups = {};
  final Map<String, Map<String, Object?>> roles = {};
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
      ),
    );
    if (request.uri.path == '/token' && request.method == 'POST') {
      await _json(request.response, HttpStatus.ok, {
        'access_token': 'test-token',
        'expires_in': 3600,
      });
      return;
    }
    if (request.uri.path == '/v1/apps/loom_communities/groups') {
      if (request.method == 'GET') {
        await _json(request.response, HttpStatus.ok, {
          'items': groups.values.toList(),
          'pageInfo': {'hasMore': false},
        });
        return;
      }
      if (request.method == 'POST') {
        final value = Map<String, Object?>.from(jsonDecode(body) as Map);
        groups[value['groupId'] as String] = <String, Object?>{
          ...value,
          'appId': 'loom_communities',
        };
        await _json(request.response, HttpStatus.created, value);
        return;
      }
    }
    if (request.uri.path == '/v1/apps/loom_communities/roles') {
      if (request.method == 'GET') {
        await _json(request.response, HttpStatus.ok, {
          'items': roles.values.toList(),
          'pageInfo': {'hasMore': false},
        });
        return;
      }
      if (request.method == 'POST') {
        final value = Map<String, Object?>.from(jsonDecode(body) as Map);
        roles[value['roleId'] as String] = <String, Object?>{
          ...value,
          'appId': 'loom_communities',
        };
        await _json(request.response, HttpStatus.created, value);
        return;
      }
    }
    final permissionMatch = RegExp(
      r'^/v1/apps/loom_communities/roles/([^/]+)/permissions$',
    ).firstMatch(request.uri.path);
    if (permissionMatch != null && request.method == 'PUT') {
      final roleId = Uri.decodeComponent(permissionMatch.group(1)!);
      final value = Map<String, Object?>.from(jsonDecode(body) as Map);
      roles[roleId]!['permissionIds'] = value['permissionIds'];
      await _json(request.response, HttpStatus.ok, roles[roleId]!);
      return;
    }
    await _json(request.response, HttpStatus.notFound, {'error': 'not found'});
  }

  Future<void> close() async {
    await _subscription.cancel();
    await _server.close(force: true);
  }
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
  });

  final String method;
  final String path;
  final String? correlationId;
  final String? idempotencyKey;
}
