import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loom_communities_demo/main.dart';

import 'workflow_ui_test_harness.dart';

void main() {
  testWidgets('mosque engine tabs preserve audience, privacy, giving, admin, messages, and search parity', (tester) async {
    final target = loomEvidenceTargets.singleWhere(
      (target) => target.extensionId == 'ext_mosque',
    );
    await tester.pumpWidget(const LoomCommunitiesDemoApp());
    await installEvidenceTarget(tester, target);
    await _openTarget(tester, target);

    await _selectPersona(tester, 'mosque-member');
    await _selectTab(tester, 'home');
    await _waitForFinder(tester, find.byKey(const ValueKey('mosque-engine-home')));
    expect(find.byKey(const ValueKey('mosque-home-event')), findsOneWidget);
    expect(find.byKey(const ValueKey('mosque-home-donation')), findsOneWidget);
    expect(find.byKey(const ValueKey('mosque-home-care-status')), findsOneWidget);

    await _selectTab(tester, 'calendar');
    await _waitForFinder(tester, find.byKey(const ValueKey('mosque-engine-calendar')));
    expect(find.text('Friday service and community iftar'), findsWidgets);
    expect(find.text('Private consultation'), findsNothing);
    expect(find.text('Event creation form'), findsNothing);
    expect(find.byKey(const ValueKey('mosque-action-publish-event')), findsNothing);
    await _tapMosqueAction(tester, 'rsvp-going');
    expect(find.text('State: Going'), findsOneWidget);
    await _tapMosqueAction(tester, 'rsvp-maybe');
    expect(find.text('State: Maybe'), findsOneWidget);
    await _tapMosqueAction(tester, 'rsvp-not-going');
    expect(find.text('State: Not going'), findsOneWidget);

    await _selectTab(tester, 'giving');
    await _waitForFinder(tester, find.byKey(const ValueKey('mosque-engine-giving')));
    await _tapMosqueAction(tester, 'pay-donation');
    expect(find.text('State: Paid'), findsOneWidget);
    expect(find.textContaining('MN-2026-050'), findsWidgets);
    await _tapMosqueAction(tester, 'open-receipt');
    expect(find.text('State: Receipt opened'), findsOneWidget);
    await _tapMosqueAction(tester, 'set-anonymous');
    expect(find.text('Anonymous donor'), findsWidgets);
    await _tapMosqueAction(tester, 'set-public');
    expect(find.text('Public donor'), findsWidgets);

    await _selectTab(tester, 'care');
    await _waitForFinder(tester, find.byKey(const ValueKey('mosque-engine-care')));
    expect(find.text('Private details: Please contact privately after Jummah'), findsWidgets);
    await _tapMosqueAction(tester, 'submit-care-request');
    expect(find.text('State: Submitted'), findsOneWidget);
    await _tapMosqueAction(tester, 'edit-care-request');
    expect(find.text('State: Draft'), findsOneWidget);
    await _tapMosqueAction(tester, 'submit-care-request');
    await _tapMosqueAction(tester, 'sign-up-volunteer');
    expect(find.text('State: Signed up'), findsOneWidget);
    await _tapMosqueAction(tester, 'edit-volunteer-signup');
    expect(find.text('State: Edited'), findsOneWidget);
    await _tapMosqueAction(tester, 'cancel-volunteer-signup');
    expect(find.text('State: Withdrawn'), findsOneWidget);

    await _selectPersona(tester, 'mosque-admin');
    await _selectTab(tester, 'home');
    await _waitForFinder(tester, find.byKey(const ValueKey('mosque-engine-home')));
    expect(find.byKey(const ValueKey('mosque-home-composer')), findsOneWidget);
    expect(find.byKey(const ValueKey('mosque-home-volunteers')), findsOneWidget);
    expect(find.byKey(const ValueKey('mosque-home-care-review')), findsOneWidget);

    await _selectTab(tester, 'calendar');
    await _waitForFinder(tester, find.text('Event creation form'));
    expect(find.byKey(const ValueKey('mosque-edit-audienceScope')), findsWidgets);
    expect(find.byKey(const ValueKey('mosque-edit-invitedPersonaIds')), findsWidgets);
    await _tapMosqueAction(tester, 'publish-event');
    await _waitForFinder(tester, find.text('State: Published'));
    expect(find.text('State: Published'), findsOneWidget);

    await _selectTab(tester, 'admin');
    await _waitForFinder(tester, find.byKey(const ValueKey('mosque-engine-admin')));
    expect(find.text('Private details: Masked for this viewer'), findsWidgets);
    await _tapMosqueAction(tester, 'assign-care-request');
    expect(find.text('Private details: Please contact privately after Jummah'), findsWidgets);
    await _tapMosqueAction(tester, 'respond-care-request');
    expect(find.text('Care team will call after Jummah'), findsWidgets);
    await _tapMosqueAction(tester, 'close-care-request');
    expect(find.text('State: Resolved'), findsOneWidget);
    await _tapMosqueAction(tester, 'preview-announcement');
    expect(find.text('State: Previewed'), findsOneWidget);
    await _tapMosqueAction(tester, 'publish-announcement');
    expect(find.text('State: Sent'), findsOneWidget);
    await _tapMosqueAction(tester, 'contact-volunteer');
    expect(find.text('Protected contact sent'), findsWidgets);
    await _tapMosqueAction(tester, 'close-volunteer-shift');
    expect(find.text('State: Closed'), findsOneWidget);

    await _selectPersona(tester, 'mosque-member');
    await _selectTab(tester, 'messages');
    await _waitForFinder(tester, find.byKey(const ValueKey('mosque-engine-messages')));
    expect(find.text('Care request received'), findsWidgets);
    expect(find.textContaining('Please contact privately'), findsNothing);
    await _tapMosqueAction(tester, 'reply-thread');
    expect(find.text('State: Replied'), findsOneWidget);
    await _tapMosqueAction(tester, 'mark-neutral-read');
    expect(find.text('State: Read'), findsOneWidget);
    await _tapMosqueAction(tester, 'mark-announcement-read');
    expect(find.text('State: Read'), findsWidgets);

    await _selectTab(tester, 'search');
    await _waitForFinder(tester, find.byKey(const ValueKey('mosque-engine-search')));
    await _tapMosqueAction(tester, 'refine-search');
    expect(find.text('State: Refined'), findsOneWidget);
    await _tapMosqueAction(tester, 'hide-source');
    expect(find.text('State: Source hidden'), findsOneWidget);
    await _tapMosqueAction(tester, 'report-stale-citation');
    expect(find.text('State: Reported stale'), findsOneWidget);
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

Future<void> _tapMosqueAction(WidgetTester tester, String transitionId) async {
  final action = find.byKey(ValueKey('mosque-action-$transitionId')).first;
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
