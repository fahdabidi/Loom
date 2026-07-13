import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loom_communities_app_shell/loom_communities_app_shell.dart';
import 'package:loom_demo_local_backend/loom_demo_local_backend.dart';

const _memberId = 'tabletop-member';

LocalInstalledCommunity _community({
  required String extensionId,
  required List<Map<String, Object?>> threads,
}) => LocalInstalledCommunity(
  communityId: '$extensionId-community',
  displayName: 'Tabletop Club',
  extensionId: extensionId,
  logoAssetId: null,
  cardImageAssetId: null,
  heroImageAssetId: null,
  accentColor: '#4a3b2a',
  experienceConfiguration: {
    'workflows': [
      {
        'workflowId': 'tabletop-discussion',
        'title': 'Tabletop discussion',
        'entryText': 'Discussion is available.',
        'actionText': 'Open discussion.',
        'resultText': 'Discussion opened.',
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
    'threads': threads,
  },
);

Map<String, Object?> _thread(String id, String subject) => {
  'threadId': id,
  'subject': subject,
  'participantPersonaIds': [_memberId],
  'messages': [
    {
      'messageId': '$id-message',
      'senderPersonaId': 'tabletop-organizer',
      'body': 'Seeded message for $subject',
      'timestamp': '2026-07-10T18:00:00Z',
    },
  ],
};

Widget _host(LocalInstalledCommunity community) => MaterialApp(
  home: LocalExtensionScreen(community: community, seedDataFiles: const []),
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

Future<void> _openMessages(WidgetTester tester, Finder readyFinder) async {
  await tester.tap(find.byKey(const ValueKey('community-tab-messages')));
  await tester.pump();
  await _pumpUntilFound(tester, readyFinder);
  await tester.ensureVisible(readyFinder);
  await tester.pump();
  // The finder can exist before the tab fade's IgnorePointer is removed.
  // Keep this bounded: RepeaterSurface.live has a periodic refresh timer, so
  // pumpAndSettle would not terminate here.
  await tester.pump(const Duration(milliseconds: 300));
}

Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pump();
  await tester.tap(finder);
}

void main() {
  testWidgets('Messages repeater renders the live seeded thread cardinality', (
    tester,
  ) async {
    final first = _community(
      extensionId: 'v3-messages-cardinality-three',
      threads: [
        _thread('one', 'Thread one'),
        _thread('two', 'Thread two'),
        _thread('three', 'Thread three'),
      ],
    );
    await tester.pumpWidget(_host(first));
    await _openMessages(tester, find.byKey(const ValueKey('repeater-item-0')));
    expect(find.byKey(const ValueKey('repeater-item-0')), findsOneWidget);
    expect(find.byKey(const ValueKey('repeater-item-1')), findsOneWidget);
    expect(find.byKey(const ValueKey('repeater-item-2')), findsOneWidget);
    expect(find.byKey(const ValueKey('repeater-item-3')), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
    final second = _community(
      extensionId: 'v3-messages-cardinality-four',
      threads: [
        _thread('one', 'Thread one'),
        _thread('two', 'Thread two'),
        _thread('three', 'Thread three'),
        _thread('four', 'Thread four'),
      ],
    );
    await tester.pumpWidget(_host(second));
    await _openMessages(tester, find.byKey(const ValueKey('repeater-item-0')));
    expect(find.byKey(const ValueKey('repeater-item-3')), findsOneWidget);
    expect(find.byKey(const ValueKey('repeater-item-4')), findsNothing);
  });

  testWidgets('posted message survives full Messages widget reconstruction', (
    tester,
  ) async {
    final community = _community(
      extensionId: 'v3-messages-post-persistence',
      threads: [_thread('persist', 'Persistence thread')],
    );
    await tester.pumpWidget(_host(community));
    final threadItem = find.byKey(
      const ValueKey('messages-inbox-item-persist'),
    );
    await _openMessages(tester, threadItem);
    await _tapVisible(tester, threadItem);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.ensureVisible(
      find.byKey(const ValueKey('messages-composer-field')),
    );
    await tester.pump();
    await tester.enterText(
      find.byKey(const ValueKey('messages-composer-field')),
      'This reply must survive reconstruction.',
    );
    await _tapVisible(
      tester,
      find.byKey(const ValueKey('messages-send-button')),
    );
    await _pumpUntilFound(
      tester,
      find.text('This reply must survive reconstruction.'),
    );
    await tester.pump(const Duration(milliseconds: 300));
    expect(
      find.text('This reply must survive reconstruction.'),
      findsOneWidget,
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(_host(community));
    await _openMessages(tester, threadItem);
    await _tapVisible(tester, threadItem);
    await tester.pump(const Duration(milliseconds: 300));
    expect(
      find.text('This reply must survive reconstruction.'),
      findsOneWidget,
    );
  });

  testWidgets('archived thread survives full Messages widget reconstruction', (
    tester,
  ) async {
    final community = _community(
      extensionId: 'v3-messages-archive-persistence',
      threads: [_thread('archive', 'Archive persistence thread')],
    );
    await tester.pumpWidget(_host(community));
    final threadItem = find.byKey(
      const ValueKey('messages-inbox-item-archive'),
    );
    await _openMessages(tester, threadItem);
    await _tapVisible(tester, threadItem);
    await tester.pump(const Duration(milliseconds: 300));
    await _tapVisible(tester, find.byTooltip('Archive'));
    await _pumpUntilAbsent(tester, find.text('Archive persistence thread'));
    expect(find.text('Archive persistence thread'), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(_host(community));
    await _openMessages(tester, find.text('No messages yet'));
    expect(find.text('Archive persistence thread'), findsNothing);
  });
}
