import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loom_auth_session/loom_auth_session.dart';
import 'package:loom_communities_app_shell/loom_communities_app_shell.dart';
import 'package:loom_demo_local_backend/loom_demo_local_backend.dart';
import 'package:loom_workflow_engine/loom_workflow_engine.dart'
    show currentCommunitySpecVersion;

const _cedarCommunityId = 'community_cedar_commons_hoa';
const _cedarExtensionId = 'ext_cedar_commons_hoa';

class _CountingLocalAuthApi extends LocalAuthApi {
  int listAccountsCalls = 0;

  @override
  Future<List<LoomAccount>> listAccounts({
    required String communityExtensionId,
  }) {
    listAccountsCalls += 1;
    return super.listAccounts(communityExtensionId: communityExtensionId);
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

LoomRemoteServiceConfiguration _remoteConfiguration() =>
    LoomRemoteServiceConfiguration(
      session: LoomAuthSession(
        tokenEndpoint: Uri.parse('https://identity.test/token'),
        clientId: 'preloaded-package-test',
        secureStorage: _MemoryStorage(),
      ),
      workflowServiceBaseUri: Uri.parse('https://workflow.test/api/'),
      appAccessBaseUri: Uri.parse('https://app-access.test/api/'),
      fanPassportBaseUri: Uri.parse('https://passport.test/api/'),
      communityGroupIds: const {_cedarCommunityId: 'cedar-group'},
    );

LocalInstalledCommunity _legacyCedarCommunity() =>
    const LocalInstalledCommunity(
      communityId: _cedarCommunityId,
      displayName: 'Cedar Commons HOA',
      extensionId: _cedarExtensionId,
      logoAssetId: null,
      cardImageAssetId: null,
      heroImageAssetId: null,
      accentColor: '#285A7B',
      specVersion: currentCommunitySpecVersion,
    );

Widget _host(LocalInstalledCommunity community, {LoomAuthApi? authApi}) =>
    MaterialApp(
      home: LocalExtensionScreen(
        community: community,
        seedDataFiles: const [],
        authApi: authApi,
      ),
    );

void main() {
  tearDown(resetLoomAuthSessionForTesting);

  testWidgets(
    'preloading Cedar installs its canonical package identity and workflows',
    (tester) async {
      final preload = await tester.runAsync(preloadBundledExampleCommunities);
      expect(preload, isNotNull);
      final resolvedPreload = preload!;
      final cedar = resolvedPreload.snapshot.communities.singleWhere(
        (community) => community.communityId == _cedarCommunityId,
      );

      expect(cedar.extensionId, _cedarExtensionId);
      expect(cedar.specVersion, currentCommunitySpecVersion);
      expect(cedar.appShellConfiguration, isNotEmpty);
      expect(
        cedar.experienceConfiguration['workflowDefinitions'],
        isA<Map<Object?, Object?>>(),
      );
      expect(
        (cedar.experienceConfiguration['workflowDefinitions']
                as Map<Object?, Object?>)
            .isNotEmpty,
        isTrue,
      );
      expect(
        resolvedPreload.seedFilesByCommunityId,
        contains(_cedarCommunityId),
      );
    },
  );

  testWidgets(
    'a remote-configured preloaded engine-native community runs its entry gate',
    (tester) async {
      overrideLoomRemoteServiceConfigurationForTesting(_remoteConfiguration());
      final preload = await tester.runAsync(preloadBundledExampleCommunities);
      expect(preload, isNotNull);
      final resolvedPreload = preload!;
      final cedar = resolvedPreload.snapshot.communities.singleWhere(
        (community) => community.communityId == _cedarCommunityId,
      );
      final authApi = _CountingLocalAuthApi();

      await tester.pumpWidget(_host(cedar, authApi: authApi));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(authApi.listAccountsCalls, greaterThanOrEqualTo(1));
      expect(
        find.byKey(const ValueKey('community-entry-gate')),
        findsOneWidget,
      );
      expect(
        find.byKey(ValueKey('opened-community-${cedar.communityId}')),
        findsNothing,
      );
    },
  );

  testWidgets(
    'a remote-configured legacy Cedar experience fails closed instead of using its alias fallback',
    (tester) async {
      overrideLoomRemoteServiceConfigurationForTesting(_remoteConfiguration());
      final community = _legacyCedarCommunity();

      await tester.pumpWidget(
        _host(community, authApi: _CountingLocalAuthApi()),
      );
      await tester.pump();

      final error = tester.takeException();
      expect(error, isA<StateError>());
      expect(
        (error! as StateError).message,
        allOf(
          contains('Cedar Commons HOA'),
          contains(_cedarCommunityId),
          contains('bundled package experience'),
        ),
      );
      expect(
        find.byKey(ValueKey('opened-community-${community.communityId}')),
        findsNothing,
      );
    },
  );

  testWidgets('a local-only legacy Cedar community keeps its existing path', (
    tester,
  ) async {
    final community = _legacyCedarCommunity();

    await tester.pumpWidget(_host(community, authApi: _CountingLocalAuthApi()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(tester.takeException(), isNull);
    expect(
      find.byKey(ValueKey('opened-community-${community.communityId}')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('community-entry-gate')), findsNothing);
  });
}
