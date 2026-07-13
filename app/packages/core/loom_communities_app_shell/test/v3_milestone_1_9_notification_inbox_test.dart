import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loom_communities_app_shell/loom_communities_app_shell.dart';
import 'package:loom_demo_local_backend/loom_demo_local_backend.dart';

const _memberId = 'tabletop-member';

const _notifications = [
  {
    'notificationId': 'tabletop-rsvp-reminder',
    'title': 'RSVP closes tomorrow',
    'body': 'Confirm your seat for Friday campaign night.',
    'source': 'Tabletop Club',
    'timestamp': '2026-07-12T18:00:00Z',
    'recipientPersonaIds': [_memberId],
    'isUnread': true,
  },
  {
    'notificationId': 'tabletop-library-arrival',
    'title': 'New game added to the library',
    'body': 'Cascadia is ready to borrow.',
    'source': 'Game library',
    'timestamp': '2026-07-12T15:30:00Z',
    'recipientPersonaIds': [_memberId],
    'isUnread': false,
  },
  {
    'notificationId': 'tabletop-teach-reminder',
    'title': 'Teach-a-game volunteer reminder',
    'body': 'Your host guide is ready for Saturday.',
    'source': 'Game night team',
    'timestamp': '2026-07-12T12:00:00Z',
    'recipientPersonaIds': [_memberId],
    'isUnread': true,
  },
];

LocalInstalledCommunity _community() => const LocalInstalledCommunity(
  communityId: 'v3-notification-inbox-community',
  displayName: 'Tabletop Club',
  extensionId: 'v3-notification-inbox',
  logoAssetId: null,
  cardImageAssetId: null,
  heroImageAssetId: null,
  accentColor: '#4a3b2a',
  experienceConfiguration: {
    'workflows': [
      {
        'workflowId': 'tabletop-notification-center',
        'title': 'Tabletop Club notifications',
        'entryText': 'Member updates are available.',
        'actionText': 'Open notifications.',
        'resultText': 'Notification center opened.',
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
    'notifications': _notifications,
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

Future<void> _pumpUntilAbsent(WidgetTester tester, Finder finder) async {
  for (var attempt = 0; attempt < 30; attempt += 1) {
    if (finder.evaluate().isEmpty) return;
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
    'Tabletop notifications render live, dismiss independently, and aggregate unread count',
    (tester) async {
      await tester.pumpWidget(_host());
      final notificationsTab = find.byKey(
        const ValueKey('community-tab-notifications'),
      );
      await tester.ensureVisible(notificationsTab);
      await tester.pump();
      await tester.tap(notificationsTab);
      await tester.pump();
      await _pumpUntilFound(
        tester,
        find.byKey(const ValueKey('notification-row-tabletop-rsvp-reminder')),
      );

      expect(
        find.byKey(const ValueKey('notification-row-tabletop-rsvp-reminder')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('notification-row-tabletop-library-arrival')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('notification-row-tabletop-teach-reminder')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('notification-unread-count')),
        findsOneWidget,
      );
      expect(find.text('2 unread'), findsOneWidget);

      final dismissed = find.byKey(
        const ValueKey('notification-dismiss-tabletop-rsvp-reminder'),
      );
      await tester.ensureVisible(dismissed);
      await tester.drag(dismissed, const Offset(-500, 0));
      await tester.pump(const Duration(milliseconds: 300));
      await _pumpUntilAbsent(
        tester,
        find.byKey(const ValueKey('notification-row-tabletop-rsvp-reminder')),
      );

      expect(
        find.byKey(const ValueKey('notification-row-tabletop-library-arrival')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('notification-row-tabletop-teach-reminder')),
        findsOneWidget,
      );
      await _pumpUntilFound(tester, find.text('1 unread'));
      expect(find.text('1 unread'), findsOneWidget);

      await _tapVisible(
        tester,
        find.byKey(const ValueKey('notification-row-tabletop-teach-reminder')),
      );
      await _pumpUntilFound(tester, find.text('0 unread'));
      expect(find.text('0 unread'), findsOneWidget);
    },
  );
}
