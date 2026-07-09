import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loom_communities_demo/main.dart';

import 'workflow_ui_test_harness.dart';

void main() {
  testWidgets('book engine tabs preserve app behavior parity', (tester) async {
    final target = loomEvidenceTargets.singleWhere(
      (target) => target.extensionId == 'ext_book_club',
    );

    await tester.pumpWidget(const LoomCommunitiesDemoApp());
    await installEvidenceTarget(tester, target);
    await _openBookTarget(tester, target);

    await _selectPersona(tester, 'book-member');

    await _selectTab(tester, 'home');
    await _waitForFinder(tester, find.byKey(const ValueKey('book-engine-home')));
    expect(find.byKey(const ValueKey('book-home-selection')), findsOneWidget);
    expect(find.byKey(const ValueKey('book-home-ballot')), findsOneWidget);
    expect(find.byKey(const ValueKey('book-home-meeting')), findsOneWidget);

    await _selectTab(tester, 'books');
    await _waitForFinder(tester, find.byKey(const ValueKey('book-engine-books')));
    await tester.enterText(
      find.byKey(const ValueKey('book-edit-title')),
      'Parable of the Sower updated',
    );
    await tester.ensureVisible(
      find.byKey(const ValueKey('book-save-edit-book-nomination')),
    );
    await _pumpForUi(tester);
    await tester.tap(
      find.byKey(const ValueKey('book-save-edit-book-nomination')),
      warnIfMissed: false,
    );
    await _pumpForUi(tester);
    await _tapBookAction(tester, 'submit-nomination');
    expect(find.text('State: Submitted'), findsOneWidget);
    await _tapBookAction(tester, 'edit-nomination');
    expect(find.text('State: Draft'), findsWidgets);
    await _tapBookAction(tester, 'submit-nomination');
    await _tapBookAction(tester, 'withdraw-nomination');
    expect(find.text('State: Withdrawn'), findsOneWidget);

    await _tapBookAction(tester, 'cast-vote');
    expect(find.text('State: Vote cast'), findsOneWidget);
    await _tapBookAction(tester, 'change-vote');
    expect(find.text('Left Hand: 7'), findsOneWidget);
    await _tapBookAction(tester, 'clear-vote');
    expect(find.text('State: Open'), findsOneWidget);

    await _selectTab(tester, 'calendar');
    await _waitForFinder(
      tester,
      find.byKey(const ValueKey('book-engine-calendar')),
    );
    await _tapBookAction(tester, 'rsvp-going');
    expect(find.text('State: Going'), findsOneWidget);
    await _tapBookAction(tester, 'rsvp-maybe');
    expect(find.text('State: Maybe'), findsOneWidget);
    await _tapBookAction(tester, 'cancel-rsvp');
    expect(find.text('State: Not going'), findsOneWidget);

    await _selectTab(tester, 'library');
    await _waitForFinder(
      tester,
      find.byKey(const ValueKey('book-engine-library')),
    );
    await _tapBookAction(tester, 'request-loan');
    expect(find.text('State: Borrowed'), findsOneWidget);
    await _tapBookAction(tester, 'join-waitlist');
    expect(find.text('Queue: 1'), findsOneWidget);
    await _tapBookAction(tester, 'leave-waitlist');
    expect(find.text('Queue: 1'), findsNothing);
    await _tapBookAction(tester, 'return-item');
    expect(find.text('State: Returned'), findsOneWidget);
    await _tapBookAction(tester, 'offer-giveaway');
    expect(find.text('State: Giveaway'), findsOneWidget);
    await _tapBookAction(tester, 'claim-giveaway');
    expect(find.text('State: Given'), findsOneWidget);

    await _selectTab(tester, 'discussions');
    await _waitForFinder(
      tester,
      find.byKey(const ValueKey('book-engine-discussions')),
    );
    expect(find.byKey(const ValueKey('book-discussion-thread')), findsOneWidget);
    await _tapBookAction(tester, 'reply');
    expect(find.text('State: Replied'), findsOneWidget);
    await _tapBookAction(tester, 'edit-reply');
    expect(find.text('State: Open'), findsOneWidget);
    await _tapBookAction(tester, 'reply');

    await _selectTab(tester, 'documents');
    await _waitForFinder(
      tester,
      find.byKey(const ValueKey('book-engine-documents')),
    );
    await _tapBookAction(tester, 'open-embedded');
    expect(find.text('State: Embedded opened'), findsOneWidget);
    await _tapBookAction(tester, 'open-external');
    expect(find.text('State: External opened'), findsOneWidget);
    await _tapBookAction(tester, 'download-material');
    expect(find.text('State: Downloaded'), findsOneWidget);

    await _selectTab(tester, 'search');
    await _waitForFinder(tester, find.byKey(const ValueKey('book-engine-search')));
    await _tapBookAction(tester, 'generate-answer');
    expect(find.text('State: Answered'), findsOneWidget);
    expect(find.text('Cited answer generated from discussion notes and reading guide.'), findsOneWidget);

    await _selectPersona(tester, 'book-organizer');
    await _selectTab(tester, 'books');
    await _tapBookAction(tester, 'close-winner');
    expect(find.text('State: Winner selected'), findsOneWidget);
    await _tapBookAction(tester, 'mark-tie');
    expect(find.text('State: Tie'), findsOneWidget);
    await _selectTab(tester, 'discussions');
    await _tapBookAction(tester, 'moderate-thread');
    expect(find.text('State: Moderated'), findsOneWidget);
    await _selectTab(tester, 'admin');
    await _waitForFinder(tester, find.byKey(const ValueKey('book-engine-admin')));
    await _tapBookAction(tester, 'preview-selection');
    await _tapBookAction(tester, 'schedule-selection');
    await _tapBookAction(tester, 'publish-selection');
    expect(find.text('State: Sent'), findsOneWidget);
    await _tapBookAction(tester, 'generate-export');
    expect(find.text('State: Generated'), findsOneWidget);

    await _selectPersona(tester, 'book-member');
    await _selectTab(tester, 'books');
    await _tapBookAction(tester, 'read-selection');
    expect(find.text('State: Read'), findsOneWidget);
  });
}

Future<void> _selectTab(WidgetTester tester, String tabId) async {
  final tab = find.byKey(ValueKey('community-tab-$tabId'));
  final rail = find.byKey(const ValueKey('community-bottom-tabs'));
  for (var attempt = 0; attempt < 16 && tab.evaluate().isEmpty; attempt += 1) {
    await tester.drag(rail, const Offset(-240, 0), warnIfMissed: false);
    await tester.pumpAndSettle();
  }
  expect(tab, findsOneWidget);
  await tester.tap(tab, warnIfMissed: false);
  await _pumpForUi(tester);
}

Future<void> _tapBookAction(WidgetTester tester, String transitionId) async {
  final action = find.byKey(ValueKey('book-action-$transitionId')).first;
  await tester.ensureVisible(action);
  await _pumpForUi(tester);
  await tester.tap(action, warnIfMissed: false);
  await _pumpForUi(tester);
}

Future<void> _selectPersona(WidgetTester tester, String personaId) async {
  await tester.tap(find.byKey(const ValueKey('persona-picker-button')));
  await _pumpForUi(tester);
  await tester.tap(find.byKey(ValueKey('persona-option-$personaId')));
  await _pumpForUi(tester);
}

Future<void> _openBookTarget(
  WidgetTester tester,
  LoomEvidenceTarget target,
) async {
  final card = find.byKey(ValueKey('community-card-${target.communityId}'));
  expect(card, findsOneWidget);
  await tester.tap(card, warnIfMissed: false);
  await _pumpForUi(tester);
  expect(
    find.byKey(ValueKey('local-extension-${target.extensionId}')),
    findsOneWidget,
  );
}

Future<void> _pumpForUi(WidgetTester tester) async {
  for (var attempt = 0; attempt < 8; attempt += 1) {
    await tester.pump(const Duration(milliseconds: 150));
  }
}

Future<void> _waitForFinder(WidgetTester tester, Finder finder) async {
  for (var attempt = 0; attempt < 80; attempt += 1) {
    if (finder.evaluate().isNotEmpty) return;
    await tester.pump(const Duration(milliseconds: 150));
  }
}
