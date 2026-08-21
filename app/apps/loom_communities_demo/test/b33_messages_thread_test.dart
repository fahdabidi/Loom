import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loom_communities_demo/main.dart';
import 'package:loom_workflow_engine/loom_workflow_engine.dart'
    show currentCommunitySpecVersion;

const _extensionId = 'ext_verify_tabletop_club';

void main() {
  group('B33 Messages thread test', () {
    // (1) Inbox lists seeded threads by key; fixture without threads shows
    //     empty state (rule-2 pair within one test: positive + negative).
    testWidgets('wf_messages-inbox-lists-seeded-threads', (tester) async {
      final fixture = _writeTabletopClubPackagePair();
      await tester.pumpWidget(const LoomCommunitiesDemoApp());
      await _installAndOpen(tester, fixture);

      await _tapTab(tester, 'messages');

      // Positive: seeded threads appear in the inbox
      expect(
        find.byKey(const ValueKey('messages-inbox-item-thread-welcome')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('messages-inbox-item-thread-game-suggestions')),
        findsOneWidget,
      );
      // Inbox shows thread subjects and preview text (last message body),
      // not individual message bodies
      expect(find.text('Welcome to Tabletop Club'), findsOneWidget);
      expect(find.text('Game suggestions for Friday'), findsOneWidget);
      expect(find.text('Glad to be here.'), findsOneWidget);
      expect(find.text('Any requests?'), findsOneWidget);

      // Negative: restart without threads → empty state
      await tester.pumpWidget(const MaterialApp(home: SizedBox()));
      await tester.pumpAndSettle();

      final bareFixture = _writeTabletopClubPackagePair(includeThreads: false);
      await tester.pumpWidget(const LoomCommunitiesDemoApp());
      await _installAndOpen(tester, bareFixture);
      await _tapTab(tester, 'messages');

      expect(
        find.text('No messages yet'),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('messages-inbox-item-thread-welcome')),
        findsNothing,
      );
    });

    // (2) Opening a thread marks it read; sending a reply appends a
    //     new message bubble visible in the widget tree.
    testWidgets('wf_messages-open-thread-and-send-reply', (tester) async {
      final fixture = _writeTabletopClubPackagePair();
      await tester.pumpWidget(const LoomCommunitiesDemoApp());
      await _installAndOpen(tester, fixture);

      await _tapTab(tester, 'messages');

      // Scroll inbox items into view (content can be below viewport)
      await tester.ensureVisible(
        find.byKey(const ValueKey('messages-inbox-item-thread-welcome')),
      );
      await tester.pumpAndSettle();

      // Open the welcome thread
      await tester.tap(
        find.byKey(const ValueKey('messages-inbox-item-thread-welcome')),
      );
      await tester.pumpAndSettle();

      // Thread detail renders with seeded messages
      expect(
        find.byKey(const ValueKey('messages-thread-detail-thread-welcome')),
        findsOneWidget,
      );
      expect(find.text('Welcome everyone!'), findsOneWidget);
      expect(find.text('Glad to be here.'), findsOneWidget);

      // Type a reply and send it
      await tester.enterText(
        find.byKey(const ValueKey('messages-composer-field')),
        'Test reply from member',
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('messages-send-button')),
      );
      await tester.pumpAndSettle();

      // Third message bubble now appears in the thread detail
      expect(
        find.text('Test reply from member'),
        findsOneWidget,
      );
    });

    // (3) Mute/archive toggles change the inbox list — muted stays,
    //     archived is removed.
    testWidgets('wf_messages-mute-and-archive-toggle', (tester) async {
      final fixture = _writeTabletopClubPackagePair();
      await tester.pumpWidget(const LoomCommunitiesDemoApp());
      await _installAndOpen(tester, fixture);

      await _tapTab(tester, 'messages');

      // Two inbox items visible before any toggle
      expect(
        find.byKey(const ValueKey('messages-inbox-item-thread-welcome')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('messages-inbox-item-thread-game-suggestions')),
        findsOneWidget,
      );

      // Scroll inbox items into view (content can be below viewport)
      await tester.ensureVisible(
        find.byKey(const ValueKey('messages-inbox-item-thread-welcome')),
      );
      await tester.pumpAndSettle();

      // Open thread-welcome and mute it
      await tester.tap(
        find.byKey(const ValueKey('messages-inbox-item-thread-welcome')),
      );
      await tester.pumpAndSettle();

      // Find the mute toggle (tooltip "Mute") and tap it
      final muteButton = find.byTooltip('Mute');
      expect(muteButton, findsOneWidget);
      await tester.tap(muteButton);
      await tester.pumpAndSettle();

      // Go back to inbox
      await tester.tap(find.byTooltip('Back to inbox'));
      await tester.pumpAndSettle();

      // thread-welcome is still visible (muted, not archived)
      expect(
        find.byKey(const ValueKey('messages-inbox-item-thread-welcome')),
        findsOneWidget,
      );

      // Now open thread-game-suggestions and archive it
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('messages-inbox-item-thread-game-suggestions')),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.ensureVisible(
        find.byKey(const ValueKey('messages-inbox-item-thread-game-suggestions')),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(
          const ValueKey('messages-inbox-item-thread-game-suggestions'),
        ),
      );
      await tester.pumpAndSettle();

      final archiveButton = find.byTooltip('Archive');
      expect(archiveButton, findsOneWidget);
      await tester.tap(archiveButton);
      await tester.pumpAndSettle();

      // Archive auto-navigates back to inbox (_selectedThreadId = null);
      // no manual Back tap needed. Only muted thread remains.
      expect(
        find.byKey(const ValueKey('messages-inbox-item-thread-welcome')),
        findsOneWidget,
      );
      expect(
        find.byKey(
          const ValueKey('messages-inbox-item-thread-game-suggestions'),
        ),
        findsNothing,
      );
    });
  });
}

Future<void> _tapTab(WidgetTester tester, String tabId) async {
  final tabFinder = find.byKey(ValueKey('community-tab-$tabId'));
  final tabRail = find.byKey(const ValueKey('community-bottom-tabs'));
  for (
    var attempt = 0;
    attempt < 8 && tabFinder.evaluate().isEmpty;
    attempt += 1
  ) {
    await tester.drag(tabRail, const Offset(-220, 0), warnIfMissed: false);
    await tester.pumpAndSettle();
  }
  expect(tabFinder, findsOneWidget, reason: tabId);
  await tester.tap(tabFinder, warnIfMissed: false);
  await tester.pumpAndSettle();
}

class _PackagePairFixture {
  const _PackagePairFixture({
    required this.extensionPath,
    required this.initializationPath,
  });

  final String extensionPath;
  final String initializationPath;
}

Future<void> _installAndOpen(
  WidgetTester tester,
  _PackagePairFixture fixture,
) async {
  await tester.tap(find.byKey(const ValueKey('add-community-button')));
  await tester.pumpAndSettle();
  await tester.enterText(
    find.byKey(const ValueKey('extension-package-path-field')),
    fixture.extensionPath,
  );
  await tester.enterText(
    find.byKey(const ValueKey('initialization-package-path-field')),
    fixture.initializationPath,
  );
  await tester.tap(find.byKey(const ValueKey('load-local-community-button')));
  await tester.pumpAndSettle();
  await tester.tap(
    find.byKey(
      const ValueKey('community-card-community_verify_tabletop_club'),
    ),
  );
  await tester.pumpAndSettle();
}

_PackagePairFixture _writeTabletopClubPackagePair({
  bool includeThreads = true,
}) {
  final tempDir = Directory.systemTemp.createTempSync('loom_b33_tabletop_');
  final extensionFile = File(
    '${tempDir.path}/$_extensionId.loom-extension.zip',
  );
  final initializationFile = File(
    '${tempDir.path}/$_extensionId.loom-init.zip',
  );
  extensionFile.writeAsStringSync(
    jsonEncode({
      'schemaVersion': 1,
      'mode': 'local-demo',
      'extensionId': _extensionId,
      'displayName': 'Tabletop Club',
      'version': '1.0.0',
      'permissions': ['content.publish', 'events.write', 'forms.write'],
    }),
  );
  final experienceMap = <String, dynamic>{
    'displayName': 'Tabletop Club',
    'tagline':
        'Board game nights, loaner games, and dues for local tabletop fans.',
    'accentColor': '#C4703F',
    'roles': [
      {
        'roleId': 'tabletop-member',
        'label': 'Member',
        'roleLabel': 'Member',
        'description': 'RSVPs to game nights, borrows games, and pays dues.',
      },
      {
        'roleId': 'tabletop-organizer',
        'label': 'Organizer',
        'roleLabel': 'Organizer',
        'description':
            'Plans game nights, manages the game library, and collects dues.',
      },
    ],
    'workflows': [
      {
        'workflowId': 'thread-open-placeholder',
        'title': 'Open thread',
        'entryText': 'Open the thread to read messages.',
        'actionText': 'Open thread',
        'resultText': 'Thread opened for reading.',
      },
    ],
    'personaPolicies': {
      'thread-open-placeholder': {
        'actorPersonaIds': ['tabletop-member', 'tabletop-organizer'],
      },
    },
  };
  if (includeThreads) {
    experienceMap['threads'] = [
      {
        'threadId': 'thread-welcome',
        'subject': 'Welcome to Tabletop Club',
        'participantPersonaIds': ['tabletop-member', 'tabletop-organizer'],
        'messages': [
          {
            'messageId': 'msg-1',
            'senderPersonaId': 'tabletop-organizer',
            'body': 'Welcome everyone!',
            'timestamp': '2026-07-03T10:00:00Z',
          },
          {
            'messageId': 'msg-2',
            'senderPersonaId': 'tabletop-member',
            'body': 'Glad to be here.',
            'timestamp': '2026-07-03T10:05:00Z',
          },
        ],
      },
      {
        'threadId': 'thread-game-suggestions',
        'subject': 'Game suggestions for Friday',
        'participantPersonaIds': ['tabletop-member', 'tabletop-organizer'],
        'messages': [
          {
            'messageId': 'msg-3',
            'senderPersonaId': 'tabletop-organizer',
            'body': 'Any requests?',
            'timestamp': '2026-07-03T11:00:00Z',
          },
        ],
      },
    ];
  }
  initializationFile.writeAsStringSync(
    jsonEncode({
      'specVersion': currentCommunitySpecVersion,
      'communityId': 'community_verify_tabletop_club',
      'communityName': 'Tabletop Club',
      'extensionId': _extensionId,
      'seedDataFiles': ['seed/community.json'],
      'branding': {'accentColor': '#C4703F'},
      'experience': experienceMap,
    }),
  );
  return _PackagePairFixture(
    extensionPath: extensionFile.path,
    initializationPath: initializationFile.path,
  );
}
