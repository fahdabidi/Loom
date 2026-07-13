import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loom_communities_app_shell/loom_communities_app_shell.dart';
import 'package:loom_demo_local_backend/loom_demo_local_backend.dart';

const _memberId = 'tabletop-member';

LocalInstalledCommunity _community() => const LocalInstalledCommunity(
  communityId: 'v3-volunteer-roster-community',
  displayName: 'Tabletop Club',
  extensionId: 'v3-volunteer-roster',
  logoAssetId: null,
  cardImageAssetId: null,
  heroImageAssetId: null,
  accentColor: '#4a3b2a',
  experienceConfiguration: {
    'workflows': [
      {
        'workflowId': 'tabletop-volunteer-roster',
        'title': 'Tabletop Club volunteer roster',
        'entryText': 'Choose a shift to support game night.',
        'actionText': 'Sign up for a shift.',
        'resultText': 'Volunteer place reserved.',
      },
    ],
    'personas': [
      {
        'personaId': _memberId,
        'label': 'Member',
        'roleLabel': 'Member',
        'description': 'Tabletop Club member',
      },
    ],
    'volunteerShifts': [
      {
        'shiftId': 'tabletop-welcome-table',
        'title': 'Welcome table',
        'capacity': 3,
        'filled': 1,
      },
      {
        'shiftId': 'tabletop-teach-a-game',
        'title': 'Teach-a-game host',
        'capacity': 2,
        'filled': 0,
      },
    ],
  },
);

Widget _host() => MaterialApp(
  home: LocalExtensionScreen(community: _community(), seedDataFiles: const []),
);

Future<void> _pumpUntilFound(WidgetTester tester, Finder finder) async {
  for (var attempt = 0; attempt < 30; attempt += 1) {
    if (finder.evaluate().isNotEmpty) return;
    await tester.pump(const Duration(milliseconds: 50));
  }
  await tester.pump(const Duration(milliseconds: 50));
}

Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pump();
  await tester.tap(finder);
}

void main() {
  testWidgets('multiple shifts render and capacity updates after sign-up', (
    tester,
  ) async {
    await tester.pumpWidget(_host());
    final rosterTab = find.byKey(const ValueKey('community-tab-roster'));
    await _tapVisible(tester, rosterTab);
    await _pumpUntilFound(
      tester,
      find.byKey(const ValueKey('roster-row-tabletop-welcome-table')),
    );

    expect(
      find.byKey(const ValueKey('roster-row-tabletop-welcome-table')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('roster-row-tabletop-teach-a-game')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('roster-capacity-tabletop-welcome-table')),
      findsOneWidget,
    );
    expect(find.text('1 of 3 filled · 2 remaining'), findsOneWidget);
    expect(find.text('0 of 2 filled · 2 remaining'), findsOneWidget);

    await _tapVisible(
      tester,
      find.byKey(const ValueKey('roster-signup-tabletop-welcome-table')),
    );
    await _pumpUntilFound(tester, find.text('2 of 3 filled · 1 remaining'));

    expect(find.text('2 of 3 filled · 1 remaining'), findsOneWidget);
    expect(find.text('0 of 2 filled · 2 remaining'), findsOneWidget);
  });
}
