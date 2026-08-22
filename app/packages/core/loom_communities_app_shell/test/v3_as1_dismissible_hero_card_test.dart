import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loom_communities_app_shell/loom_communities_app_shell.dart';
import 'package:loom_demo_local_backend/loom_demo_local_backend.dart';
import 'package:loom_workflow_engine/loom_workflow_engine.dart'
    show currentCommunitySpecVersion;

import 'authz_p6_test_helpers.dart';

LocalInstalledCommunity _community({
  required String communityId,
  required String displayName,
}) => LocalInstalledCommunity(
  communityId: communityId,
  displayName: displayName,
  extensionId: 'as1-$communityId',
  logoAssetId: null,
  cardImageAssetId: null,
  heroImageAssetId: null,
  accentColor: '#4a3b2a',
  specVersion: currentCommunitySpecVersion,
  experienceConfiguration: {
    'roles': [
      {'roleId': '$communityId-member', 'label': 'Member'},
    ],
    'workflowDefinitions': {
      '$communityId-activity': {
        'initialState': 'open',
        'states': {
          'open': {'label': '$displayName activity'},
        },
        'transitions': <Object?>[],
        'renderBindings': [
          {
            'states': ['open'],
            'audience': 'any',
            'tabId': 'home',
            'cardSurfaceFamily': 'statusTimeline',
            'bindingKind': 'summary',
          },
        ],
        'instanceDataSchema': <String, Object?>{},
      },
    },
  },
);

Widget _host(ValueNotifier<LocalInstalledCommunity> currentCommunity) =>
    MaterialApp(
      home: ValueListenableBuilder<LocalInstalledCommunity>(
        valueListenable: currentCommunity,
        builder: (context, community, child) {
          final experience = experienceForExtensionId(
            community.extensionId,
            displayName: community.displayName,
            specVersion: community.specVersion,
            experienceConfiguration: community.experienceConfiguration,
          );
          return KeyedSubtree(
            key: ValueKey(community.extensionId),
            child: LocalExtensionScreen(
              community: community,
              seedDataFiles: const [],
              authApi: activeAuthForCommunity(
                community: community,
                experience: experience,
                roleId: '${community.communityId}-member',
              ),
            ),
          );
        },
      ),
    );

Future<void> _pumpUntilFound(WidgetTester tester, Finder finder) async {
  for (var attempt = 0; attempt < 30; attempt += 1) {
    if (finder.evaluate().isNotEmpty) return;
    await tester.pump(const Duration(milliseconds: 50));
  }
  throw TestFailure('Timed out waiting for $finder');
}

void main() {
  testWidgets(
    'dismissing a hero hides its banner without affecting tabs or another community',
    (tester) async {
      final first = _community(
        communityId: 'as1-first-community',
        displayName: 'First Club',
      );
      final second = _community(
        communityId: 'as1-second-community',
        displayName: 'Second Club',
      );
      final currentCommunity = ValueNotifier<LocalInstalledCommunity>(first);
      addTearDown(currentCommunity.dispose);

      await tester.pumpWidget(_host(currentCommunity));
      final firstDismiss = find.byKey(
        const ValueKey('community-hero-dismiss-as1-first-community'),
      );
      await _pumpUntilFound(tester, firstDismiss);

      expect(find.text('No sponsored message right now.'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('opened-community-as1-first-community')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('community-tab-home')), findsOneWidget);

      await tester.tap(firstDismiss);
      await tester.pump();

      expect(find.text('No sponsored message right now.'), findsNothing);
      expect(
        find.byKey(const ValueKey('opened-community-as1-first-community')),
        findsNothing,
      );
      expect(firstDismiss, findsNothing);
      expect(find.byKey(const ValueKey('community-tab-home')), findsOneWidget);

      currentCommunity.value = second;
      await tester.pump();
      final secondDismiss = find.byKey(
        const ValueKey('community-hero-dismiss-as1-second-community'),
      );
      await _pumpUntilFound(tester, secondDismiss);

      expect(find.text('No sponsored message right now.'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('opened-community-as1-second-community')),
        findsOneWidget,
      );
      expect(secondDismiss, findsOneWidget);
    },
  );
}
