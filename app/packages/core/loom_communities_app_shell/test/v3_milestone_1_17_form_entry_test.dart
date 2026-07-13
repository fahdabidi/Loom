import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loom_communities_app_shell/loom_communities_app_shell.dart';
import 'package:loom_demo_local_backend/loom_demo_local_backend.dart';

const _memberId = 'tabletop-member';
const _referenceTime = '2026-08-01T18:00:00.000Z';

LocalInstalledCommunity _community() => const LocalInstalledCommunity(
  communityId: 'v3-form-entry-community',
  displayName: 'Tabletop Club',
  extensionId: 'v3-form-entry',
  logoAssetId: null,
  cardImageAssetId: null,
  heroImageAssetId: null,
  accentColor: '#4a3b2a',
  experienceConfiguration: {
    'workflows': [
      {
        'workflowId': 'tabletop-form-entry-workflow',
        'title': 'Tournament reminder setup',
        'entryText': 'Configure your notification preference.',
        'actionText': 'Save preference.',
        'resultText': 'Preference saved.',
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
    'formEntry': {
      'formId': 'tabletop-tournament-reminder',
      'title': 'Tournament reminder setup',
      'referenceTime': _referenceTime,
      'notificationsEnabled': false,
      'reminderOffset': 'at-time',
    },
  },
);

Widget _host() => MaterialApp(
  home: LocalExtensionScreen(community: _community(), seedDataFiles: const []),
);

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

void main() {
  testWidgets(
    'checkbox toggle and reminder offset persist through the engine',
    (tester) async {
      await tester.pumpWidget(_host());
      await _tapVisible(
        tester,
        find.byKey(const ValueKey('community-tab-form')),
      );
      await _pumpUntilText(tester, 'notificationsEnabled: false');

      expect(find.text('notificationsEnabled: false'), findsOneWidget);
      expect(find.text('reminderAt: $_referenceTime'), findsOneWidget);

      await _tapVisible(
        tester,
        find.byKey(const ValueKey('form-notifications-enabled')),
      );
      await _pumpUntilText(tester, 'notificationsEnabled: true');
      expect(find.text('notificationsEnabled: true'), findsOneWidget);

      await _tapVisible(
        tester,
        find.byKey(const ValueKey('form-reminder-offset')),
      );
      await tester.pumpAndSettle();
      await _tapVisible(tester, find.text('1 day before').last);
      await tester.pumpAndSettle();

      const expectedReminderAt = '2026-07-31T18:00:00.000Z';
      await _pumpUntilText(tester, 'reminderAt: $expectedReminderAt');
      expect(find.text('reminderAt: $expectedReminderAt'), findsOneWidget);
    },
  );
}
