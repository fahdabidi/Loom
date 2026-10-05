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

/// Regression coverage for `authenticateEvidenceFanForRemote` resolving a
/// seeded fan's display name through the account directory
/// (`authApi.listAccounts`) instead of deriving it by title-casing the slug.
///
/// Confirmed live 2026-10-05 against `loom_fan_passport`: several seeded
/// second holders are stored as `Test <slug>` rather than the title-cased
/// convention the first holder of each role happens to follow. The stale
/// derivation would construct a finder for text that is never on screen,
/// which reads as a multi-minute UI stall rather than the seeding mismatch
/// it actually is.
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

LocalInstalledCommunity _communityFor({
  required String communityId,
  required String extensionId,
}) => LocalInstalledCommunity(
  communityId: communityId,
  displayName: 'Display Name Lookup Community',
  extensionId: extensionId,
  logoAssetId: null,
  cardImageAssetId: null,
  heroImageAssetId: null,
  accentColor: '#2f6f67',
  specVersion: currentCommunitySpecVersion,
  experienceConfiguration: const <String, Object?>{
    'workflowDefinitions': <String, Object?>{
      'display-name-lookup-workflow': <String, Object?>{
        'initialState': 'open',
        'states': <String, Object?>{
          'open': <String, Object?>{'label': 'Open'},
        },
        'transitions': <Object?>[],
      },
    },
  },
);

/// A minimal stand-in for the real app's community list -- just enough of
/// its key structure (`add-community-button`, `community-list`, the
/// `Loom Communities` title, and a `community-card-<id>` tile) for
/// `openEvidenceTarget` to navigate through, mirroring
/// `remote_account_chooser_reopen_after_login_test.dart`.
class _FakeCommunityListShell extends StatelessWidget {
  const _FakeCommunityListShell({
    required this.authApi,
    required this.community,
  });

  final LoomAuthApi authApi;
  final LocalInstalledCommunity community;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: _FakeCommunityListHome(authApi: authApi, community: community),
    );
  }
}

class _FakeCommunityListHome extends StatelessWidget {
  const _FakeCommunityListHome({
    required this.authApi,
    required this.community,
  });

  final LoomAuthApi authApi;
  final LocalInstalledCommunity community;

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
                  key: ValueKey('community-card-${community.communityId}'),
                  title: Text(community.displayName),
                  onTap: () {
                    Navigator.of(context).push<void>(
                      MaterialPageRoute<void>(
                        builder: (_) => LocalExtensionScreen(
                          community: community,
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

/// Mocks the one Keycloak round trip `authenticateEvidenceFanForRemote`
/// drives directly: the password-grant token request for [username].
MockClient _tokenClient({
  required Uri tokenEndpoint,
  required String username,
  required String fanId,
}) {
  return MockClient((request) async {
    expect(request.url, tokenEndpoint);
    final body = Uri.splitQueryString(request.body);
    expect(body['grant_type'], 'password');
    expect(body['username'], username);
    expect(body['password'], seededEvidenceFanPassword);
    return http.Response(
      jsonEncode({
        'access_token': 'token-for-$fanId',
        'token_type': 'Bearer',
        'expires_in': 3600,
        'refresh_token': 'refresh-for-$fanId',
        'refresh_expires_in': 7200,
      }),
      200,
      headers: const {'content-type': 'application/json'},
    );
  });
}

void main() {
  tearDown(resetLoomAuthSessionForTesting);

  testWidgets(
    'authenticateEvidenceFanForRemote finds a seeded account whose stored '
    'display name does not match the title-cased slug',
    (tester) async {
      const extensionId = 'ext_display_name_mismatch';
      const communityId = 'community_display_name_mismatch';
      const roleId = 'lookup-member';
      const slug = '$roleId-1';
      const username = 'loom-$slug';
      const fanId = 'fan-$slug';
      // Deliberately NOT the title-cased derivation ("Lookup Member 1") --
      // this is the exact shape of the live mismatch this ticket closes.
      const storedDisplayName = 'Test $slug';
      const derivedDisplayName = 'Lookup Member 1';

      final tokenEndpoint = Uri.parse(
        'https://identity.test/realms/loom/protocol/openid-connect/token',
      );
      final client = _tokenClient(
        tokenEndpoint: tokenEndpoint,
        username: username,
        fanId: fanId,
      );
      addTearDown(client.close);

      overrideLoomAuthSessionForTesting(
        LoomAuthSession(
          tokenEndpoint: tokenEndpoint,
          clientId: 'display-name-lookup-test',
          secureStorage: _MemorySecureStorage(),
          httpClient: client,
        ),
      );

      final authApi = LocalAuthApi()
        ..seedAccounts(extensionId, const [
          LoomAccount(
            accountId: fanId,
            displayName: storedDisplayName,
            roleId: roleId,
          ),
        ]);

      final community = _communityFor(
        communityId: communityId,
        extensionId: extensionId,
      );
      await tester.pumpWidget(
        _FakeCommunityListShell(authApi: authApi, community: community),
      );
      await tester.pumpAndSettle();

      final target = LoomEvidenceTarget(
        phase: 'TEST',
        communityId: communityId,
        communityName: community.displayName,
        handle: 'display-name-mismatch',
        extensionId: extensionId,
        accentColor: community.accentColor,
        seedDataFiles: const <String>[],
      );

      await openEvidenceTarget(tester, target);
      expect(
        find.byKey(const ValueKey('community-entry-gate')),
        findsOneWidget,
      );
      // The stale slug-derived name would never be on screen; the stored one
      // already is, before any sign-in has happened.
      expect(find.text(derivedDisplayName), findsNothing);
      expect(find.text(storedDisplayName), findsOneWidget);

      final resolvedFanId = await authenticateEvidenceFanForRemote(
        tester,
        roleId: roleId,
        target: target,
      );

      expect(resolvedFanId, fanId);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('actor-identity-picker-button')),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'authenticateEvidenceFanForRemote fails immediately, naming the fan id, '
    'when no seeded account matches it in the directory',
    (tester) async {
      const extensionId = 'ext_display_name_missing';
      const communityId = 'community_display_name_missing';
      const roleId = 'absent-member';
      const slug = '$roleId-1';
      const username = 'loom-$slug';
      const fanId = 'fan-$slug';

      final tokenEndpoint = Uri.parse(
        'https://identity.test/realms/loom/protocol/openid-connect/token',
      );
      final client = _tokenClient(
        tokenEndpoint: tokenEndpoint,
        username: username,
        fanId: fanId,
      );
      addTearDown(client.close);

      overrideLoomAuthSessionForTesting(
        LoomAuthSession(
          tokenEndpoint: tokenEndpoint,
          clientId: 'display-name-lookup-test',
          secureStorage: _MemorySecureStorage(),
          httpClient: client,
        ),
      );

      // The Keycloak credential exists (the mock above accepts it), but
      // nothing seeds a matching account into this community's directory --
      // the seeding gap this test proves must fail loudly rather than time
      // out waiting for a ListTile that can never appear.
      final authApi = LocalAuthApi();

      final community = _communityFor(
        communityId: communityId,
        extensionId: extensionId,
      );
      await tester.pumpWidget(
        _FakeCommunityListShell(authApi: authApi, community: community),
      );
      await tester.pumpAndSettle();

      final target = LoomEvidenceTarget(
        phase: 'TEST',
        communityId: communityId,
        communityName: community.displayName,
        handle: 'display-name-missing',
        extensionId: extensionId,
        accentColor: community.accentColor,
        seedDataFiles: const <String>[],
      );

      await openEvidenceTarget(tester, target);

      await expectLater(
        authenticateEvidenceFanForRemote(
          tester,
          roleId: roleId,
          target: target,
        ),
        throwsA(
          isA<TestFailure>().having(
            (failure) => failure.message,
            'message',
            contains(fanId),
          ),
        ),
      );
    },
  );
}
