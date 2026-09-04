import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:loom_auth_session/loom_auth_session.dart';
import 'package:loom_communities_app_shell/loom_communities_app_shell.dart';

const _communityId = 'community_cedar_commons_hoa';
const _extensionId = 'ext_hoa';
const _groupId = 'loom_communities_cedar-commons-hoa';
const _appId = 'loom_communities';

final _uuidV4 = RegExp(
  r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
);

void main() {
  tearDown(resetLoomAuthSessionForTesting);

  test('unconfigured production auth resolution stays LocalAuthApi', () {
    final api = resolveLoomAuthApiForCommunity(
      communityId: _communityId,
      communityExtensionId: _extensionId,
      actorIdentityResolver: (_) => _actorIdentities,
      experienceResolver: (_) => _experience(),
    );

    expect(api, isA<LocalAuthApi>());
  });

  test('configured production auth resolution is RemoteLoomAuthApi', () {
    final session = _RemoteTestSession('fan-alice');
    overrideLoomRemoteServiceConfigurationForTesting(_configuration(session));

    final api = resolveLoomAuthApiForCommunity(
      communityId: _communityId,
      communityExtensionId: _extensionId,
      actorIdentityResolver: (_) => _actorIdentities,
      experienceResolver: (_) => _experience(),
    );

    expect(api, isA<RemoteLoomAuthApi>());
  });

  test(
    'listAccounts reads App Access members and maps requested to pending',
    () async {
      final session = _RemoteTestSession('fan-alice');
      final client = MockClient((request) async {
        _expectRemoteHeaders(request, expectedToken: session.token);
        if (request.url.path == '/api/v1/fans/fan-alice/communities') {
          expect(request.method, 'GET');
          expect(request.url.queryParameters, {'appId': _appId});
          return _jsonResponse({
            'communities': [
              _communityMembership(fanId: 'fan-alice', roleId: 'hoa-member'),
            ],
          });
        }
        if (request.url.path ==
            '/api/v1/apps/$_appId/groups/$_groupId/members') {
          expect(request.method, 'GET');
          return _jsonResponse({
            'items': [
              _membership(fanId: 'fan-alice', roleId: 'hoa-member'),
              _membership(
                fanId: 'fan-waiting',
                roleId: 'hoa-member',
                state: 'requested',
              ),
            ],
            'pageInfo': {'hasMore': false, 'nextCursor': null},
          });
        }
        if (request.url.path == '/api/v1/fan-passports/fan-alice') {
          return _jsonResponse(_passport('fan-alice', 'Alice Active'));
        }
        if (request.url.path == '/api/v1/fan-passports/fan-waiting') {
          return _jsonResponse(_passport('fan-waiting', 'Wendy Waiting'));
        }
        throw StateError(
          'Unexpected request: ${request.method} ${request.url}',
        );
      });
      addTearDown(client.close);
      final api = _remoteApi(session, client);

      final accounts = await api.listAccounts(
        communityExtensionId: _extensionId,
      );

      expect(
        accounts,
        containsAll([
          isA<LoomAccount>()
              .having((account) => account.accountId, 'accountId', 'fan-alice')
              .having(
                (account) => account.status,
                'status',
                MembershipStatus.active,
              ),
          isA<LoomAccount>()
              .having(
                (account) => account.accountId,
                'accountId',
                'fan-waiting',
              )
              .having(
                (account) => account.status,
                'status',
                MembershipStatus.pendingApproval,
              ),
        ]),
      );
    },
  );

  test(
    'signIn resolves its group and role from the live fan community membership',
    () async {
      final session = _RemoteTestSession('fan-alice');
      const liveGroupId = 'server-authoritative-cedar-group';
      var fanCommunityRequests = 0;
      final client = MockClient((request) async {
        _expectRemoteHeaders(request, expectedToken: session.token);
        if (request.url.path == '/api/v1/fans/fan-alice/communities') {
          expect(request.method, 'GET');
          expect(request.url.queryParameters, {'appId': _appId});
          fanCommunityRequests += 1;
          return _jsonResponse({
            'communities': [
              _communityMembership(
                fanId: 'fan-alice',
                groupId: liveGroupId,
                roleId: 'server-board',
              ),
            ],
          });
        }
        if (request.url.path == '/api/v1/fan-passports/fan-alice') {
          return _jsonResponse(_passport('fan-alice', 'Alice Active'));
        }
        if (request.url.path ==
            '/api/v1/apps/$_appId/groups/$liveGroupId/members') {
          expect(request.method, 'GET');
          return _jsonResponse({
            'items': [
              _membership(
                fanId: 'fan-alice',
                groupId: liveGroupId,
                roleId: 'server-board',
              ),
            ],
            'pageInfo': {'hasMore': false, 'nextCursor': null},
          });
        }
        throw StateError(
          'Unexpected request: ${request.method} ${request.url}',
        );
      });
      addTearDown(client.close);
      final api = _remoteApi(session, client);

      final signedIn = await api.signIn(accountId: 'fan-alice');

      expect(signedIn.account.displayName, 'Alice Active');
      expect(signedIn.account.roleId, 'server-board');
      expect(api.currentSession, same(signedIn));
      final accounts = await api.listAccounts(
        communityExtensionId: _extensionId,
      );
      expect(accounts.single.roleId, 'server-board');
      expect(fanCommunityRequests, 1);
      await expectLater(
        api.signIn(accountId: 'fan-someone-else'),
        throwsA(isA<LoomAuthException>()),
      );
    },
  );

  test(
    'signIn falls back to the configured group when fan community lookup fails',
    () async {
      final session = _RemoteTestSession('fan-alice');
      var fanCommunityRequests = 0;
      var fallbackMembershipRequests = 0;
      final client = MockClient((request) async {
        _expectRemoteHeaders(request, expectedToken: session.token);
        if (request.url.path == '/api/v1/fans/fan-alice/communities') {
          expect(request.method, 'GET');
          fanCommunityRequests += 1;
          return http.Response('temporarily unavailable', 503);
        }
        if (request.url.path ==
            '/api/v1/apps/$_appId/groups/$_groupId/members/fan-alice') {
          expect(request.method, 'GET');
          fallbackMembershipRequests += 1;
          return _jsonResponse(
            _membership(fanId: 'fan-alice', roleId: 'hoa-member'),
          );
        }
        if (request.url.path == '/api/v1/fan-passports/fan-alice') {
          return _jsonResponse(_passport('fan-alice', 'Alice Active'));
        }
        throw StateError(
          'Unexpected request: ${request.method} ${request.url}',
        );
      });
      addTearDown(client.close);
      final api = _remoteApi(session, client);

      final signedIn = await api.signIn(accountId: 'fan-alice');

      expect(signedIn.account.roleId, 'hoa-member');
      expect(fanCommunityRequests, 1);
      expect(fallbackMembershipRequests, 1);
    },
  );

  test(
    'open signUp creates the passport then creates an active membership',
    () async {
      final session = _RemoteTestSession('fan-new');
      final client = MockClient((request) async {
        _expectRemoteHeaders(request, expectedToken: session.token);
        if (request.url.path == '/api/v1/fans/fan-new/communities') {
          expect(request.method, 'GET');
          return _jsonResponse(<String, Object?>{'communities': <Object?>[]});
        }
        if (request.url.path == '/api/v1/fan-passports/fan-new') {
          expect(request.method, 'GET');
          return http.Response('', 404);
        }
        if (request.url.path == '/api/v1/fan-passports') {
          expect(request.method, 'POST');
          expect(jsonDecode(request.body), {'displayName': 'New Member'});
          return _jsonResponse(
            _passport('fan-new', 'New Member'),
            statusCode: 201,
          );
        }
        if (request.url.path ==
            '/api/v1/apps/$_appId/groups/$_groupId/members/fan-new') {
          expect(request.method, 'PUT');
          expect(jsonDecode(request.body), {
            'roleIds': ['hoa-member'],
            'state': 'active',
          });
          return _jsonResponse(
            _membership(fanId: 'fan-new', roleId: 'hoa-member'),
          );
        }
        throw StateError(
          'Unexpected request: ${request.method} ${request.url}',
        );
      });
      addTearDown(client.close);
      final api = _remoteApi(session, client);

      final result = await api.signUp(
        communityExtensionId: _extensionId,
        displayName: 'New Member',
        roleId: 'hoa-member',
      );

      expect(result, isA<LoomActiveSignUpResult>());
      expect(result.account.accountId, 'fan-new');
      expect(result.account.status, MembershipStatus.active);
    },
  );

  test(
    'approval-gated signUp preserves the pending-result distinction',
    () async {
      final session = _RemoteTestSession('fan-applicant');
      final client = MockClient((request) async {
        _expectRemoteHeaders(request, expectedToken: session.token);
        if (request.url.path == '/api/v1/fans/fan-applicant/communities') {
          expect(request.method, 'GET');
          return _jsonResponse(<String, Object?>{'communities': <Object?>[]});
        }
        if (request.url.path == '/api/v1/fan-passports/fan-applicant') {
          return _jsonResponse(_passport('fan-applicant', 'Avery Applicant'));
        }
        if (request.url.path ==
            '/api/v1/apps/$_appId/groups/$_groupId/members/fan-applicant') {
          expect(request.method, 'PUT');
          expect(jsonDecode(request.body), {
            'roleIds': ['hoa-applicant'],
            'state': 'requested',
          });
          return _jsonResponse(
            _membership(
              fanId: 'fan-applicant',
              roleId: 'hoa-applicant',
              state: 'requested',
            ),
          );
        }
        throw StateError(
          'Unexpected request: ${request.method} ${request.url}',
        );
      });
      addTearDown(client.close);
      final api = _remoteApi(session, client);

      final result = await api.signUp(
        communityExtensionId: _extensionId,
        displayName: 'Avery Applicant',
        roleId: 'hoa-applicant',
      );

      expect(result, isA<LoomPendingApprovalSignUpResult>());
      expect(result.session, isNull);
      expect(api.currentSession, isNull);
    },
  );

  test('approveAccount posts an App Access membership decision', () async {
    final session = _RemoteTestSession('fan-admin');
    var decisionSeen = false;
    final client = MockClient((request) async {
      _expectRemoteHeaders(request, expectedToken: session.token);
      final path = request.url.path;
      if (path == '/api/v1/fans/fan-admin/communities') {
        expect(request.method, 'GET');
        return _jsonResponse({
          'communities': [
            _communityMembership(fanId: 'fan-admin', roleId: 'hoa-board'),
          ],
        });
      }
      if (path == '/api/v1/apps/$_appId/groups/$_groupId/members/fan-admin') {
        return _jsonResponse(
          _membership(fanId: 'fan-admin', roleId: 'hoa-board'),
        );
      }
      if (path == '/api/v1/fan-passports/fan-admin') {
        return _jsonResponse(_passport('fan-admin', 'Ada Admin'));
      }
      if (path == '/api/v1/apps/$_appId/groups/$_groupId/members/fan-waiting') {
        expect(request.method, 'GET');
        return _jsonResponse(
          _membership(
            fanId: 'fan-waiting',
            roleId: 'hoa-member',
            state: 'requested',
          ),
        );
      }
      if (path ==
          '/api/v1/apps/$_appId/groups/$_groupId/membership-requests/'
              'fan-waiting/decision') {
        expect(request.method, 'POST');
        expect(jsonDecode(request.body), {
          'decision': 'approve',
          'roleIds': ['hoa-member'],
        });
        decisionSeen = true;
        return _jsonResponse(
          _membership(fanId: 'fan-waiting', roleId: 'hoa-member'),
        );
      }
      if (path == '/api/v1/fan-passports/fan-waiting') {
        return _jsonResponse(_passport('fan-waiting', 'Wendy Waiting'));
      }
      throw StateError('Unexpected request: ${request.method} ${request.url}');
    });
    addTearDown(client.close);
    final api = _remoteApi(session, client);
    await api.signIn(accountId: 'fan-admin');

    final approved = await api.approveAccount(accountId: 'fan-waiting');

    expect(decisionSeen, isTrue);
    expect(approved.status, MembershipStatus.active);
    expect(approved.roleId, 'hoa-member');
  });

  test(
    'signOut delegates to the real session and clears the app session',
    () async {
      final session = _RemoteTestSession('fan-alice');
      final client = MockClient((request) async {
        throw StateError(
          'Unexpected request: ${request.method} ${request.url}',
        );
      });
      addTearDown(client.close);
      final api = _remoteApi(session, client);

      await api.signOut();

      expect(session.wasLoggedOut, isTrue);
      expect(api.currentSession, isNull);
    },
  );

  test(
    'invite members fail loudly because the deployed API has no code store',
    () async {
      final client = http.Client();
      addTearDown(client.close);
      final api = _remoteApi(_RemoteTestSession('fan-admin'), client);

      await expectLater(
        Future<LoomCommunityInvite>.sync(
          () => api.issueInvite(
            roleId: 'hoa-member',
            issuedByAccountId: 'fan-admin',
          ),
        ),
        throwsA(isA<UnimplementedError>()),
      );
      await expectLater(
        Future<LoomSession>.sync(
          () => api.redeemInvite(code: 'LOOM-ABC123', displayName: 'Invitee'),
        ),
        throwsA(isA<UnimplementedError>()),
      );
    },
  );
}

RemoteLoomAuthApi _remoteApi(_RemoteTestSession session, http.Client client) =>
    createRemoteLoomAuthApiForConfiguration(
      configuration: _configuration(session),
      communityId: _communityId,
      communityExtensionId: _extensionId,
      actorIdentityResolver: (_) => _actorIdentities,
      httpClient: client,
    );

LoomRemoteServiceConfiguration _configuration(_RemoteTestSession session) =>
    LoomRemoteServiceConfiguration(
      session: session,
      workflowServiceBaseUri: Uri.parse('https://workflow.test/api/'),
      appAccessBaseUri: Uri.parse('https://app-access.test/api/'),
      fanPassportBaseUri: Uri.parse('https://fan-passport.test/api/'),
      communityGroupIds: const {_communityId: _groupId},
    );

const _actorIdentities = [
  LoomActorIdentity(
    fanId: 'fan-admin',
    roleId: 'hoa-board',
    label: 'Board member',
    roleLabel: 'Board',
    description: 'Manages membership.',
  ),
  LoomActorIdentity(
    fanId: 'fan-member',
    roleId: 'hoa-member',
    label: 'HOA member',
    roleLabel: 'Member',
    description: 'Participates in the community.',
  ),
  LoomActorIdentity(
    fanId: 'fan-applicant',
    roleId: 'hoa-applicant',
    label: 'HOA applicant',
    roleLabel: 'Applicant',
    description: 'Waits for HOA board approval.',
    accessMode: LoomActorIdentityAccessMode.requiresApproval,
  ),
];

LoomExperienceDefinition _experience() => const LoomExperienceDefinition(
  extensionId: _extensionId,
  displayName: 'Cedar Commons HOA',
  tagline: 'Test community',
  accentColor: 0xff246b62,
  workflows: [],
  actorIdentities: _actorIdentities,
);

Map<String, Object?> _membership({
  required String fanId,
  required String roleId,
  String groupId = _groupId,
  String state = 'active',
}) => {
  'appId': _appId,
  'groupId': groupId,
  'fanId': fanId,
  'roleIds': [roleId],
  'state': state,
  'joinedAt': '2026-08-26T12:00:00Z',
  'requestedAt': state == 'requested' ? '2026-08-26T12:00:00Z' : null,
  'decidedAt': state == 'active' ? '2026-08-26T12:00:00Z' : null,
  'decidedByFanId': state == 'active' ? 'fan-admin' : null,
  'requestNote': null,
};

Map<String, Object?> _communityMembership({
  required String fanId,
  required String roleId,
  String groupId = _groupId,
  String state = 'active',
}) => <String, Object?>{
  ..._membership(fanId: fanId, roleId: roleId, groupId: groupId, state: state),
  'communityId': _communityId,
  'displayName': 'Cedar Commons HOA',
};

Map<String, Object?> _passport(String fanId, String displayName) => {
  'fanId': fanId,
  'displayName': displayName,
  'privacyMode': 'free_personalized',
  'createdAt': '2026-08-26T12:00:00Z',
};

http.Response _jsonResponse(Object body, {int statusCode = 200}) =>
    http.Response(
      jsonEncode(body),
      statusCode,
      headers: const {'content-type': 'application/json'},
    );

void _expectRemoteHeaders(http.BaseRequest request, {String? expectedToken}) {
  expect(
    request.headers['authorization'],
    'Bearer ${expectedToken ?? _jwt('fan-alice')}',
  );
  final correlationId = request.headers['x-loom-correlation-id'];
  expect(correlationId, isNotNull);
  expect(correlationId, matches(_uuidV4));
  if (request.method == 'POST' || request.method == 'PUT') {
    expect(request.headers['idempotency-key'], startsWith('loom-auth-'));
  }
}

String _jwt(String fanId) {
  String encoded(Object value) =>
      base64UrlEncode(utf8.encode(jsonEncode(value))).replaceAll('=', '');
  return '${encoded({'alg': 'none'})}.${encoded({'fanId': fanId})}.signature';
}

final class _RemoteTestSession extends LoomAuthSession {
  _RemoteTestSession(this.fanId)
    : token = _jwt(fanId),
      super(
        tokenEndpoint: Uri.parse(
          'https://identity.test/realms/loom/protocol/openid-connect/token',
        ),
        clientId: 'remote-auth-api-test',
        secureStorage: _MemoryStorage(),
      );

  final String fanId;
  final String token;
  bool wasLoggedOut = false;

  @override
  Future<String> currentAccessToken() async => token;

  @override
  Future<void> logout() async {
    wasLoggedOut = true;
  }
}

final class _MemoryStorage implements LoomAuthSecureStorageBackend {
  @override
  Future<void> delete({required String key}) async {}

  @override
  Future<String?> read({required String key}) async => null;

  @override
  Future<void> write({required String key, required String value}) async {}
}
