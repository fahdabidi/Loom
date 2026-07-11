import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loom_communities_demo/main.dart';

import 'workflow_ui_test_harness.dart';

void main() {
  testWidgets('youth soccer engine tabs preserve guided, protected, and export parity', (tester) async {
    final target = loomEvidenceTargets.singleWhere(
      (target) => target.extensionId == 'ext_youth_soccer',
    );
    await tester.pumpWidget(const LoomCommunitiesDemoApp());
    await installEvidenceTarget(tester, target);
    await _openTarget(tester, target);
    await _selectPersona(tester, 'guardian');

    await _selectTab(tester, 'home');
    await _waitForFinder(tester, find.byKey(const ValueKey('soccer-engine-home')));
    expect(find.byKey(const ValueKey('soccer-home-schedule')), findsOneWidget);
    expect(find.byKey(const ValueKey('soccer-home-privacy')), findsOneWidget);
    expect(find.byKey(const ValueKey('soccer-home-receipt')), findsOneWidget);

    await _selectTab(tester, 'registration');
    await _waitForFinder(
      tester,
      find.byKey(const ValueKey('soccer-guided-registration')),
    );
    expect(find.text('Step 1 of 4: Join request'), findsOneWidget);
    expect(find.byKey(const ValueKey('soccer-action-confirm-registration-payment')), findsNothing);
    await _tapSoccerAction(tester, 'submit-join-request');
    expect(find.text('Step 2 of 4: Waiver acknowledgement'), findsOneWidget);
    expect(find.byKey(const ValueKey('soccer-action-confirm-registration-payment')), findsNothing);
    await _tapSoccerAction(tester, 'sign-waiver');
    expect(find.text('Step 3 of 4: Registration payment'), findsOneWidget);
    expect(find.byKey(const ValueKey('soccer-action-confirm-registration-payment')), findsWidgets);
    await _tapSoccerAction(tester, 'confirm-registration-payment');
    expect(find.text('Step 4 of 4: Roster confirmation'), findsOneWidget);

    await _selectTab(tester, 'schedule');
    await _waitForFinder(tester, find.byKey(const ValueKey('soccer-engine-schedule')));
    await _tapSoccerAction(tester, 'rsvp-going');
    expect(find.text('RSVP: Going'), findsWidgets);
    await _tapSoccerAction(tester, 'rsvp-maybe');
    expect(find.text('RSVP: Maybe'), findsWidgets);
    await _tapSoccerAction(tester, 'rsvp-not-going');
    expect(find.text('RSVP: Not going'), findsWidgets);

    await _selectTab(tester, 'team');
    await _waitForFinder(
      tester,
      find.byKey(const ValueKey('soccer-guardian-roster-card')),
    );
    expect(find.textContaining('Sofia Rivera - U10'), findsWidgets);
    expect(find.textContaining('Ari Rivera - U12'), findsWidgets);
    expect(find.textContaining('Miles Chen - U10'), findsNothing);
    expect(find.text('Guardian persona: guardian'), findsWidgets);
    expect(find.text('Birth date: protected by consent scope'), findsNWidgets(2));
    expect(find.textContaining('Birth date: 2016-08-03'), findsNothing);
    await _tapSoccerAction(tester, 'request-access');
    expect(find.text('State: Access requested'), findsOneWidget);

    await _selectTab(tester, 'payments');
    await _waitForFinder(tester, find.byKey(const ValueKey('soccer-engine-payments')));
    await _tapSoccerAction(tester, 'pay-registration');
    expect(find.text('Status: Paid'), findsWidgets);
    await _tapSoccerAction(tester, 'refund-payment');
    expect(find.text('Status: Refunded'), findsWidgets);
    await _tapSoccerAction(tester, 'manage-subscription');
    expect(find.text('Managed in Loom payments'), findsWidgets);

    await _selectTab(tester, 'messages');
    await _waitForFinder(tester, find.byKey(const ValueKey('soccer-engine-messages')));
    await _tapSoccerAction(tester, 'reply-thread');
    expect(find.text('State: Replied'), findsOneWidget);

    await _selectPersona(tester, 'coach');
    await _selectTab(tester, 'registration');
    await _waitForFinder(tester, find.text('Registration reviewer timeline'));
    await _tapSoccerAction(tester, 'approve-registration');
    expect(find.text('State: Approved'), findsOneWidget);

    await _selectTab(tester, 'team');
    await _waitForFinder(
      tester,
      find.byKey(const ValueKey('soccer-coach-roster-table')),
    );
    expect(find.byKey(const ValueKey('soccer-roster-sortable-columns')), findsOneWidget);
    expect(find.textContaining('Miles Chen - U10'), findsWidgets);
    await _tapSoccerAction(tester, 'edit-player');
    expect(find.text('State: Editing'), findsWidgets);
    await _tapSoccerAction(tester, 'request-update');
    expect(find.text('State: Update requested'), findsWidgets);
    await _tapSoccerAction(tester, 'redact-field');
    expect(find.text('State: Redacted'), findsWidgets);
    expect(find.text('Medical notes: redacted (medicalNotes)'), findsWidgets);
    expect(find.text('Redacted fields: medicalNotes'), findsWidgets);
    await _tapSoccerAction(tester, 'undo-redaction');
    expect(find.text('State: Active roster'), findsWidgets);

    await _selectTab(tester, 'schedule');
    await _tapSoccerAction(tester, 'change-practice');
    expect(find.text('Saturday 10:00 AM'), findsWidgets);
    await _tapSoccerAction(tester, 'send-schedule-reminder');
    expect(find.text('Reminder sent'), findsWidgets);

    await _selectTab(tester, 'documents');
    await _waitForFinder(tester, find.byKey(const ValueKey('soccer-engine-documents')));
    await _tapSoccerAction(tester, 'open-embedded-waiver');
    expect(find.text('State: Embedded opened'), findsOneWidget);
    await _tapSoccerAction(tester, 'open-external-waiver');
    expect(find.text('State: External opened'), findsOneWidget);
    await _tapSoccerAction(tester, 'acknowledge-waiver-document');
    expect(find.text('State: Acknowledged'), findsOneWidget);

    await _selectTab(tester, 'coach');
    await _waitForFinder(tester, find.byKey(const ValueKey('soccer-coach-dashboard')));
    await _tapSoccerAction(tester, 'schedule-reminder');
    expect(find.text('State: Scheduled'), findsOneWidget);
    await _tapSoccerAction(tester, 'publish-reminder');
    expect(find.text('State: Published'), findsOneWidget);

    await _selectPersona(tester, 'owner');
    await _selectTab(tester, 'admin');
    await _waitForFinder(tester, find.byKey(const ValueKey('soccer-engine-admin')));
    await _tapSoccerAction(tester, 'preview-redaction');
    expect(find.text('Minor birth dates and medical notes masked'), findsWidgets);
    await _tapSoccerAction(tester, 'generate-export');
    expect(find.text('sha256-rys-77a9'), findsWidgets);
    await _tapSoccerAction(tester, 'transfer-export');
    expect(find.text('State: Transferred'), findsOneWidget);
    await _tapSoccerAction(tester, 'rollback-transfer');
    expect(find.text('State: Rolled back'), findsOneWidget);
    await _tapSoccerAction(tester, 'retry-transfer');
    expect(find.text('State: Retried'), findsOneWidget);
  });
}

Future<void> _selectTab(WidgetTester tester, String tabId) async {
  final tab = find.byKey(ValueKey('community-tab-$tabId'));
  final rail = find.byKey(const ValueKey('community-bottom-tabs'));
  for (var attempt = 0; attempt < 24 && tab.evaluate().isEmpty; attempt += 1) {
    await tester.drag(rail, const Offset(-240, 0), warnIfMissed: false);
    await tester.pumpAndSettle();
  }
  for (var attempt = 0; attempt < 24 && tab.evaluate().isEmpty; attempt += 1) {
    await tester.drag(rail, const Offset(240, 0), warnIfMissed: false);
    await tester.pumpAndSettle();
  }
  expect(tab, findsOneWidget);
  await tester.tap(tab, warnIfMissed: false);
  await _pumpForUi(tester);
}

Future<void> _tapSoccerAction(WidgetTester tester, String transitionId) async {
  final action = find.byKey(ValueKey('soccer-action-$transitionId')).first;
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

Future<void> _openTarget(WidgetTester tester, LoomEvidenceTarget target) async {
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
