import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loom_auth_session/loom_auth_session.dart';
import 'package:loom_communities_app_shell/loom_communities_app_shell.dart';

final class _MemorySecureStorage implements LoomAuthSecureStorageBackend {
  @override
  Future<void> delete({required String key}) async {}

  @override
  Future<String?> read({required String key}) async => null;

  @override
  Future<void> write({required String key, required String value}) async {}
}

LoomAuthSession _session() => LoomAuthSession(
  tokenEndpoint: Uri.parse('https://identity.test/token'),
  clientId: 'replica-sync-policy-test',
  secureStorage: _MemorySecureStorage(),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late LoomMemoryReplicaSyncPolicyStore store;
  late List<String> refreshes;
  late LoomReplicaSyncPolicyController controller;

  setUp(() {
    store = LoomMemoryReplicaSyncPolicyStore();
    refreshes = <String>[];
    controller = LoomReplicaSyncPolicyController(
      store: store,
      visibleCommunityRefreshInterval: const Duration(days: 1),
      refreshCommunity: ({required memberId, required extensionId}) async {
        refreshes.add('$memberId:$extensionId');
      },
    );
  });

  tearDown(() {
    controller.dispose();
    resetLoomAuthSessionForTesting();
    resetLoomReplicaSyncPolicyControllerForTesting();
  });

  test(
    'a member who has never chosen receives community-open refreshes',
    () async {
      expect(
        await controller.policyFor('alice'),
        LoomReplicaSyncPolicy.communityOpen,
      );

      await controller.activateCommunity(
        memberId: 'alice',
        extensionId: 'garden',
      );
      await controller.onAppForeground();
      await controller.runVisibleCommunityRefreshForTesting();

      expect(refreshes, isEmpty);
      expect(controller.isVisibleCommunityPolling, isFalse);
    },
  );

  test('each policy triggers only its promised additional refreshes', () async {
    await controller.activateCommunity(
      memberId: 'alice',
      extensionId: 'garden',
    );

    await controller.setPolicy(
      memberId: 'alice',
      policy: LoomReplicaSyncPolicy.appForeground,
    );
    await controller.onAppForeground();
    await controller.runVisibleCommunityRefreshForTesting();
    expect(refreshes, <String>['alice:garden']);
    expect(controller.isVisibleCommunityPolling, isFalse);

    refreshes.clear();
    await controller.setPolicy(
      memberId: 'alice',
      policy: LoomReplicaSyncPolicy.visibleCommunity,
    );
    await controller.onAppForeground();
    await controller.runVisibleCommunityRefreshForTesting();
    expect(refreshes, <String>['alice:garden', 'alice:garden']);
    expect(controller.isVisibleCommunityPolling, isTrue);

    refreshes.clear();
    controller.deactivateCommunity(memberId: 'alice', extensionId: 'garden');
    await controller.runVisibleCommunityRefreshForTesting();
    expect(refreshes, isEmpty);

    await controller.activateCommunity(memberId: 'alice', extensionId: 'chess');
    await controller.setPolicy(
      memberId: 'alice',
      policy: LoomReplicaSyncPolicy.knownCommunitiesOnForeground,
    );
    await controller.onAppForeground();
    await controller.runVisibleCommunityRefreshForTesting();
    expect(refreshes, <String>['alice:garden', 'alice:chess', 'alice:chess']);
  });

  test('logout stops every scheduled policy action', () async {
    await controller.setPolicy(
      memberId: 'alice',
      policy: LoomReplicaSyncPolicy.knownCommunitiesOnForeground,
    );
    await controller.activateCommunity(
      memberId: 'alice',
      extensionId: 'garden',
    );

    overrideLoomReplicaSyncPolicyControllerForTesting(controller);
    final session = _session();
    overrideLoomAuthSessionForTesting(session);
    await session.logout();

    await controller.onAppForeground();
    await controller.runVisibleCommunityRefreshForTesting();
    expect(refreshes, isEmpty);
    expect(controller.activeMemberId, isNull);
    expect(controller.isVisibleCommunityPolling, isFalse);
  });

  test(
    'members on one device keep independent settings when switching',
    () async {
      await controller.setPolicy(
        memberId: 'alice',
        policy: LoomReplicaSyncPolicy.appForeground,
      );
      await controller.setPolicy(
        memberId: 'bob',
        policy: LoomReplicaSyncPolicy.visibleCommunity,
      );

      await controller.activateCommunity(
        memberId: 'alice',
        extensionId: 'garden',
      );
      await controller.onAppForeground();
      await controller.runVisibleCommunityRefreshForTesting();

      await controller.activateCommunity(memberId: 'bob', extensionId: 'chess');
      await controller.onAppForeground();
      await controller.runVisibleCommunityRefreshForTesting();

      await controller.activateCommunity(
        memberId: 'alice',
        extensionId: 'garden',
      );
      await controller.onAppForeground();
      await controller.runVisibleCommunityRefreshForTesting();

      expect(refreshes, <String>[
        'alice:garden',
        'bob:chess',
        'bob:chess',
        'alice:garden',
      ]);
    },
  );

  test('a policy change takes effect in the active session', () async {
    await controller.activateCommunity(
      memberId: 'alice',
      extensionId: 'garden',
    );
    await controller.runVisibleCommunityRefreshForTesting();
    expect(refreshes, isEmpty);

    await controller.setPolicy(
      memberId: 'alice',
      policy: LoomReplicaSyncPolicy.visibleCommunity,
    );
    await controller.runVisibleCommunityRefreshForTesting();
    expect(refreshes, <String>['alice:garden']);

    await controller.setPolicy(
      memberId: 'alice',
      policy: LoomReplicaSyncPolicy.communityOpen,
    );
    await controller.runVisibleCommunityRefreshForTesting();
    expect(refreshes, <String>['alice:garden']);
  });

  testWidgets('D explains the honest foreground-wide fallback', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: LoomReplicaSyncSettingsScreen(
          memberId: 'alice',
          controller: controller,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final fallbackCopy = find.textContaining(
      'Background execution is not available in this app',
    );
    expect(fallbackCopy, findsOneWidget);

    await tester.tap(
      find.byKey(
        const ValueKey('replica-sync-policy-knownCommunitiesOnForeground'),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      await store.readForMember('alice'),
      LoomReplicaSyncPolicy.knownCommunitiesOnForeground,
    );
  });
}
