import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loom_communities_app_shell/loom_communities_app_shell.dart';
import 'package:loom_demo_local_backend/loom_demo_local_backend.dart';

const _memberId = 'tabletop-member';

LocalInstalledCommunity _community() => const LocalInstalledCommunity(
  communityId: 'v3-single-item-preference-community',
  displayName: 'Tabletop Club',
  extensionId: 'v3-single-item-preference',
  logoAssetId: null,
  cardImageAssetId: null,
  heroImageAssetId: null,
  accentColor: '#4a3b2a',
  experienceConfiguration: {
    'workflows': [
      {
        'workflowId': 'tabletop-reminder-preference',
        'title': 'Game-night reminder preference',
        'entryText': 'Choose one reminder setting.',
        'actionText': 'Set reminder preference.',
        'resultText': 'Reminder preference updated.',
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
    'singleItemPreference': {
      'preferenceId': 'tabletop-game-night-reminders',
      'title': 'Game-night reminders',
      'initialValue': 'all-updates',
    },
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

Future<void> _pumpUntilText(WidgetTester tester, String text) async {
  for (var attempt = 0; attempt < 30; attempt += 1) {
    if (find.text(text).evaluate().isNotEmpty) return;
    await tester.pump(const Duration(milliseconds: 50));
  }
  await tester.pump(const Duration(milliseconds: 50));
}

Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pump();
  await tester.tap(finder);
}

SegmentedButton<String> _control(WidgetTester tester) =>
    tester.widget(find.byKey(const ValueKey('single-item-preference-control')));

void main() {
  testWidgets('segmented preference stays exclusive and persists each choice', (
    tester,
  ) async {
    await tester.pumpWidget(_host());
    await _tapVisible(
      tester,
      find.byKey(const ValueKey('community-tab-preferences')),
    );
    await _pumpUntilFound(
      tester,
      find.byKey(const ValueKey('single-item-preference-control')),
    );

    expect(_control(tester).selected, {'all-updates'});
    expect(find.text('Preference value: all-updates'), findsOneWidget);

    await _tapVisible(tester, find.text('Event updates'));
    await _pumpUntilText(tester, 'Preference value: event-updates');

    expect(_control(tester).selected, {'event-updates'});
    expect(_control(tester).selected, isNot(contains('all-updates')));
    expect(_control(tester).selected, isNot(contains('no-reminders')));
    expect(find.text('Preference value: event-updates'), findsOneWidget);

    await _tapVisible(tester, find.text('No reminders'));
    await _pumpUntilText(tester, 'Preference value: no-reminders');

    expect(_control(tester).selected, {'no-reminders'});
    expect(_control(tester).selected, isNot(contains('all-updates')));
    expect(_control(tester).selected, isNot(contains('event-updates')));
    expect(find.text('Preference value: no-reminders'), findsOneWidget);
  });
}
