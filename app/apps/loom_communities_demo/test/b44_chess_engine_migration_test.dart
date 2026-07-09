import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loom_communities_demo/main.dart';

import 'workflow_ui_test_harness.dart';

void main() {
  testWidgets('chess engine tabs preserve behavior parity and rankings effect', (tester) async {
    final target = loomEvidenceTargets.singleWhere((target) => target.extensionId == 'ext_chess_club');
    await tester.pumpWidget(const LoomCommunitiesDemoApp());
    await installEvidenceTarget(tester, target);
    await _openChessTarget(tester, target);
    await _selectPersona(tester, 'chess-player');

    await _selectTab(tester, 'home');
    await _waitForFinder(tester, find.byKey(const ValueKey('chess-engine-home')));
    expect(find.byKey(const ValueKey('chess-home-next-match')), findsOneWidget);
    expect(find.byKey(const ValueKey('chess-home-pairing')), findsOneWidget);
    expect(find.byKey(const ValueKey('chess-home-standings')), findsOneWidget);

    await _selectTab(tester, 'matches');
    await _waitForFinder(tester, find.byKey(const ValueKey('chess-engine-matches')));
    await tester.enterText(find.byKey(const ValueKey('chess-edit-opponent')), 'Noah Kim updated');
    await tester.ensureVisible(find.byKey(const ValueKey('chess-save-edit-chess-match-meetup')));
    await _pumpForUi(tester);
    await tester.tap(find.byKey(const ValueKey('chess-save-edit-chess-match-meetup')), warnIfMissed: false);
    await _pumpForUi(tester);
    await _tapChessAction(tester, 'propose-match');
    expect(find.text('State: Proposed'), findsOneWidget);
    await _tapChessAction(tester, 'decline-match');
    expect(find.text('Decline recorded; challenge remains open'), findsOneWidget);
    await _tapChessAction(tester, 'suggest-new-time');
    expect(find.text('State: Rescheduled'), findsOneWidget);
    await _tapChessAction(tester, 'cancel-match');
    expect(find.text('Cancellation noted; organizer can rematch if needed'), findsOneWidget);
    await _tapChessAction(tester, 'suggest-new-time');
    await _tapChessAction(tester, 'accept-match');
    expect(find.text('State: Accepted'), findsOneWidget);
    await _tapChessAction(tester, 'confirm-match');
    expect(find.text('State: Confirmed'), findsOneWidget);

    await _selectTab(tester, 'calendar');
    await _waitForFinder(tester, find.byKey(const ValueKey('chess-engine-calendar')));
    expect(find.text('Confirmed match calendar'), findsOneWidget);
    expect(find.text('Thursday Ladder Night'), findsWidgets);

    await _selectTab(tester, 'rankings');
    await _waitForFinder(tester, find.byKey(const ValueKey('chess-rankings-table')));
    expect(find.text('2. Maya Patel - 1480 (0)'), findsOneWidget);

    await _selectTab(tester, 'matches');
    await tester.enterText(find.byKey(const ValueKey('chess-edit-whitePlayer')), 'Ari Stone');
    await tester.enterText(find.byKey(const ValueKey('chess-edit-blackPlayer')), 'Lina Ortiz');
    await tester.enterText(find.byKey(const ValueKey('chess-edit-score')), '0-1');
    await tester.ensureVisible(find.byKey(const ValueKey('chess-save-edit-chess-match-result')));
    await _pumpForUi(tester);
    await tester.tap(find.byKey(const ValueKey('chess-save-edit-chess-match-result')), warnIfMissed: false);
    await _pumpForUi(tester);
    await _tapChessAction(tester, 'submit-result');
    expect(find.text('State: Submitted'), findsOneWidget);
    await _selectTab(tester, 'rankings');
    await _waitForFinder(tester, find.text('3. Lina Ortiz - 1466 (+16)'));
    expect(find.text('3. Lina Ortiz - 1466 (+16)'), findsOneWidget);
    expect(find.text('4. Ari Stone - 1444 (-16)'), findsOneWidget);

    await _selectTab(tester, 'matches');
    await _tapChessAction(tester, 'correct-result');
    expect(find.text('State: Corrected'), findsOneWidget);
    await _selectTab(tester, 'rankings');
    await _waitForFinder(tester, find.text('3. Lina Ortiz - 1478 (+12)'));
    expect(find.text('3. Lina Ortiz - 1478 (+12)'), findsOneWidget);
    expect(find.text('4. Ari Stone - 1432 (-12)'), findsOneWidget);
    await _selectTab(tester, 'matches');
    await _tapChessAction(tester, 'dispute-result');
    expect(find.text('State: Disputed'), findsOneWidget);

    await _selectPersona(tester, 'chess-organizer');
    await _selectTab(tester, 'admin');
    await _waitForFinder(tester, find.byKey(const ValueKey('chess-engine-admin')));
    await _tapChessAction(tester, 'assign-pairing');
    expect(find.text('State: Assigned'), findsOneWidget);
    await _tapChessAction(tester, 'resolve-dispute');
    expect(find.text('State: Resolved'), findsOneWidget);
    await _tapChessAction(tester, 'generate-export');
    expect(find.text('State: Generated'), findsOneWidget);

    await _selectTab(tester, 'documents');
    await _waitForFinder(tester, find.byKey(const ValueKey('chess-engine-documents')));
    await _tapChessAction(tester, 'open-embedded');
    expect(find.text('State: Embedded opened'), findsOneWidget);
    await _tapChessAction(tester, 'open-external');
    expect(find.text('State: External opened'), findsOneWidget);
    await _tapChessAction(tester, 'download-document');
    expect(find.text('State: Downloaded'), findsOneWidget);
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

Future<void> _tapChessAction(WidgetTester tester, String transitionId) async {
  final action = find.byKey(ValueKey('chess-action-$transitionId')).first;
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

Future<void> _openChessTarget(WidgetTester tester, LoomEvidenceTarget target) async {
  final card = find.byKey(ValueKey('community-card-${target.communityId}'));
  expect(card, findsOneWidget);
  await tester.tap(card, warnIfMissed: false);
  await _pumpForUi(tester);
  expect(find.byKey(ValueKey('local-extension-${target.extensionId}')), findsOneWidget);
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
