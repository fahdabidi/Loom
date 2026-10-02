import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:loom_auth_session/loom_auth_session.dart';
import 'package:loom_communities_demo/main.dart';
import 'package:loom_demo_local_backend/loom_demo_local_backend.dart';
import 'package:loom_workflow_engine/loom_workflow_engine.dart'
    show currentCommunitySpecVersion;

import 'workflow_ui_test_harness.dart';

/// Regression coverage for the gap this ticket closes:
/// `RemoteLoomAuthApi.listAccounts` begins with `_fanIdFromCurrentSession()`,
/// which throws `LoomAuthNotLoggedInException` whenever the auth screen
/// mounts and fetches before a session is stored. On-device this happened
/// because the community route opened, and therefore the auth screen's
/// account fetch ran, BEFORE `authenticateEvidenceFanForRemote` logged in --
/// and nothing re-ran that fetch afterwards, so the seeded account's row
/// never became findable (see
/// HARNESS-remote-account-selection-by-identity.md, "CONFIRMED... the
/// chooser evaluates BEFORE the harness authenticates"). The fix reopens the
/// community route after login, exactly as `seedEvidenceAccounts` already
/// does for the local path and for the same reason.
const _extensionId = 'ext_remote_reopen_after_login';
const _communityId = 'community_remote_reopen_after_login';
const _roleId = 'remote-reopen-member';
const _slug = '$_roleId-1';
const _username = 'loom-$_slug';
const _fanId = 'fan-$_slug';
const _displayName = 'Remote Reopen Member 1';

/// In-memory stand-in for secure storage -- mirrors the fake already used by
/// `remote_auth_session_test.dart` and `remote_auth_api_test.dart` in the app
/// shell package.
final class _MemorySecureStorage implements LoomAuthSecureStorageBackend {
  final Map<String, String> values = {};

  @override
  Future<void> delete({required String key}) async => values.remove(key);

  @override
  Future<String?> read({required String key}) async => values[key];

  @override
  Future<void> write({required String key, required String value}) async {
    values[key] = value;
  }
}

/// Mirrors the one fact of `RemoteLoomAuthApi.listAccounts` this regression
/// is about: it begins with `_fanIdFromCurrentSession()`, which reads the
/// real [loomAuthSession] and throws `LoomAuthNotLoggedInException` whenever
/// no session is stored yet -- never a network failure, and never gated on
/// anything this fake's inner [LocalAuthApi] controls. Every other method
/// delegates straight through, exactly as `_DelayedAuthApi`
/// (`b25_actor_identity_picker_async_open_test.dart`) does for the sibling
/// async-open regression.
final class _SessionGatedAuthApi implements LoomAuthApi {
  _SessionGatedAuthApi(this._inner);

  final LoomAuthApi _inner;

  @override
  Future<List<LoomAccount>> listAccounts({
    required String communityExtensionId,
  }) async {
    await loomAuthSession!.currentAccessToken();
    return _inner.listAccounts(communityExtensionId: communityExtensionId);
  }

  @override
  Future<List<LoomCommunityMember>> listCommunityMembers({
    required String communityExtensionId,
  }) => _inner.listCommunityMembers(communityExtensionId: communityExtensionId);

  @override
  Future<LoomSession> signIn({required String accountId}) =>
      _inner.signIn(accountId: accountId);

  @override
  Future<LoomSignUpResult> signUp({
    required String communityExtensionId,
    required String displayName,
    required String roleId,
  }) => _inner.signUp(
    communityExtensionId: communityExtensionId,
    displayName: displayName,
    roleId: roleId,
  );

  @override
  Future<LoomSession> redeemInvite({
    required String code,
    required String displayName,
  }) => _inner.redeemInvite(code: code, displayName: displayName);

  @override
  Future<LoomCommunityInvite> issueInvite({
    required String roleId,
    required String issuedByAccountId,
  }) =>
      _inner.issueInvite(roleId: roleId, issuedByAccountId: issuedByAccountId);

  @override
  Future<LoomAccount> approveAccount({required String accountId}) =>
      _inner.approveAccount(accountId: accountId);

  @override
  Future<void> signOut() => _inner.signOut();

  @override
  LoomSession? get currentSession => _inner.currentSession;
}

const _community = LocalInstalledCommunity(
  communityId: _communityId,
  displayName: 'Remote Reopen Community',
  extensionId: _extensionId,
  logoAssetId: null,
  cardImageAssetId: null,
  heroImageAssetId: null,
  accentColor: '#2f6f67',
  specVersion: currentCommunitySpecVersion,
  experienceConfiguration: <String, Object?>{
    'workflowDefinitions': <String, Object?>{
      'remote-reopen-workflow': <String, Object?>{
        'initialState': 'open',
        'states': <String, Object?>{
          'open': <String, Object?>{'label': 'Open'},
        },
        'transitions': <Object?>[],
      },
    },
  },
);

const _target = LoomEvidenceTarget(
  phase: 'TEST',
  communityId: _communityId,
  communityName: 'Remote Reopen Community',
  handle: 'remote-reopen-community',
  extensionId: _extensionId,
  accentColor: '#2f6f67',
  seedDataFiles: <String>[],
);

/// A minimal stand-in for the real app's community list: just enough of its
/// key structure (`add-community-button`, `community-list`, the
/// `Loom Communities` title, and a `community-card-<id>` tile) for
/// `openEvidenceTarget` to navigate through. Tapping the card pushes the
/// real `LocalExtensionScreen`, which is where the actual defect lives --
/// this shell exists only so that screen has somewhere to be pushed from and
/// returned to.
class _FakeCommunityListShell extends StatelessWidget {
  const _FakeCommunityListShell({required this.authApi});

  final LoomAuthApi authApi;

  @override
  Widget build(BuildContext context) {
    // `MaterialApp` creates its own Navigator below this build context, so
    // the push below must happen from a context INSIDE that subtree (the
    // home widget's own build context), not from this one.
    return MaterialApp(home: _FakeCommunityListHome(authApi: authApi));
  }
}

class _FakeCommunityListHome extends StatelessWidget {
  const _FakeCommunityListHome({required this.authApi});

  final LoomAuthApi authApi;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Loom Communities')),
      body: Column(
        children: [
          TextButton(
            key: const ValueKey('add-community-button'),
            onPressed: () {},
            child: const Text('Add community'),
          ),
          Expanded(
            child: ListView(
              key: const ValueKey('community-list'),
              children: [
                ListTile(
                  key: const ValueKey('community-card-$_communityId'),
                  title: const Text('Remote Reopen Community'),
                  onTap: () {
                    Navigator.of(context).push<void>(
                      MaterialPageRoute<void>(
                        builder: (_) => LocalExtensionScreen(
                          community: _community,
                          seedDataFiles: const [],
                          authApi: authApi,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

void main() {
  tearDown(resetLoomAuthSessionForTesting);

  testWidgets(
    'authenticateEvidenceFanForRemote reopens the community route after '
    'login so the seeded account becomes findable',
    (tester) async {
      final tokenEndpoint = Uri.parse(
        'https://identity.test/realms/loom/protocol/openid-connect/token',
      );
      final client = MockClient((request) async {
        expect(request.url, tokenEndpoint);
        final body = Uri.splitQueryString(request.body);
        expect(body['grant_type'], 'password');
        expect(body['username'], _username);
        expect(body['password'], seededEvidenceFanPassword);
        return http.Response(
          jsonEncode({
            'access_token': 'token-for-$_fanId',
            'token_type': 'Bearer',
            'expires_in': 3600,
            'refresh_token': 'refresh-for-$_fanId',
            'refresh_expires_in': 7200,
          }),
          200,
          headers: const {'content-type': 'application/json'},
        );
      });
      addTearDown(client.close);

      final session = LoomAuthSession(
        tokenEndpoint: tokenEndpoint,
        clientId: 'remote-reopen-test',
        secureStorage: _MemorySecureStorage(),
        httpClient: client,
      );
      overrideLoomAuthSessionForTesting(session);

      final authApi = _SessionGatedAuthApi(
        LocalAuthApi()
          ..seedAccounts(_extensionId, const [
            LoomAccount(
              accountId: _fanId,
              displayName: _displayName,
              roleId: _roleId,
            ),
          ]),
      );

      await tester.pumpWidget(_FakeCommunityListShell(authApi: authApi));
      await tester.pumpAndSettle();

      // Open the community once before authenticating, mirroring the real
      // walkthrough: `assertB25CommunityRowSurface` opens the route and
      // therefore evaluates `listAccounts` well before
      // `authenticateEvidenceFanForRemote` runs. With no session stored yet,
      // this first fetch throws -- the auth screen renders its error, and
      // without the fix that error is sticky for the rest of the screen's
      // lifetime.
      await openEvidenceTarget(tester, _target);
      expect(
        find.byKey(const ValueKey('community-entry-gate')),
        findsOneWidget,
      );
      expect(find.text(_displayName), findsNothing);

      await authenticateEvidenceFanForRemote(
        tester,
        roleId: _roleId,
        target: _target,
      );

      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('actor-identity-picker-button')),
        findsOneWidget,
      );
    },
  );
}
