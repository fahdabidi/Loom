import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loom_communities_demo/main.dart';

import 'workflow_ui_test_harness.dart';

void main() {
  testWidgets('camera engine tabs preserve app behavior parity', (tester) async {
    final target = loomEvidenceTargets.singleWhere(
      (target) => target.extensionId == 'ext_camera_club',
    );

    await tester.pumpWidget(const LoomCommunitiesDemoApp());
    await installEvidenceTarget(tester, target);
    await _openCameraTarget(tester, target);

    await _selectPersona(tester, 'camera-member');

    await _selectTab(tester, 'home');
    await _waitForFinder(
      tester,
      find.byKey(const ValueKey('camera-engine-home')),
    );
    expect(find.byKey(const ValueKey('camera-home-walk')), findsOneWidget);
    expect(find.byKey(const ValueKey('camera-home-critique')), findsOneWidget);
    expect(find.byKey(const ValueKey('camera-home-gear')), findsOneWidget);

    await _selectTab(tester, 'calendar');
    await _waitForFinder(
      tester,
      find.byKey(const ValueKey('camera-engine-calendar')),
    );
    await _tapCameraAction(tester, 'rsvp-going');
    expect(find.text('State: Going'), findsOneWidget);
    await _tapCameraAction(tester, 'rsvp-maybe');
    expect(find.text('State: Maybe'), findsOneWidget);
    await _tapCameraAction(tester, 'rsvp-not-going');
    expect(find.text('State: Not going'), findsOneWidget);

    await _selectTab(tester, 'critique');
    await _waitForFinder(
      tester,
      find.byKey(const ValueKey('camera-engine-critique')),
    );
    expect(find.byKey(const ValueKey('camera-critique-grid')), findsOneWidget);
    expect(find.byKey(const ValueKey('camera-critique-thread')), findsOneWidget);
    await tester.enterText(
      find.byKey(const ValueKey('camera-edit-photoTitle')),
      'Neon rain reflections',
    );
    await tester.ensureVisible(
      find.byKey(const ValueKey('camera-save-edit-critique-submission')),
    );
    await _pumpForUi(tester);
    await tester.tap(
      find.byKey(const ValueKey('camera-save-edit-critique-submission')),
      warnIfMissed: false,
    );
    await _pumpForUi(tester);
    await _tapCameraAction(tester, 'submit-critique');
    expect(find.text('State: Submitted'), findsOneWidget);
    expect(find.text('Neon rain reflections'), findsWidgets);

    await _selectTab(tester, 'messages');
    await _waitForFinder(
      tester,
      find.byKey(const ValueKey('camera-engine-messages')),
    );
    expect(find.byKey(const ValueKey('camera-critique-thread')), findsOneWidget);

    await _selectTab(tester, 'critique');
    await _tapCameraAction(tester, 'edit-critique');
    expect(find.text('State: Draft'), findsOneWidget);
    await _tapCameraAction(tester, 'submit-critique');
    await _tapCameraAction(tester, 'withdraw-critique');
    expect(find.text('State: Withdrawn'), findsOneWidget);

    await _selectTab(tester, 'marketplace');
    await _waitForFinder(
      tester,
      find.byKey(const ValueKey('camera-engine-marketplace')),
    );
    await _tapCameraAction(tester, 'request-loan');
    expect(find.text('State: Loaned'), findsOneWidget);
    await _tapCameraAction(tester, 'join-queue');
    expect(find.text('Queue: 1'), findsOneWidget);
    await _tapCameraAction(tester, 'leave-queue');
    expect(find.text('Queue: 1'), findsNothing);
    await _tapCameraAction(tester, 'return-gear');
    expect(find.text('State: Returned'), findsOneWidget);
    await _tapCameraAction(tester, 'offer-giveaway');
    expect(find.text('State: Giveaway'), findsOneWidget);
    await _tapCameraAction(tester, 'claim-giveaway');
    expect(find.text('State: Claimed'), findsOneWidget);

    await _selectPersona(tester, 'camera-organizer');
    await _selectTab(tester, 'admin');
    await _waitForFinder(
      tester,
      find.byKey(const ValueKey('camera-engine-admin')),
    );
    expect(
      find.byKey(const ValueKey('camera-admin-validation-status')),
      findsOneWidget,
    );
    await _tapCameraAction(tester, 'mark-validated');
    expect(find.text('State: Validated'), findsOneWidget);
  });
}

Future<void> _selectTab(WidgetTester tester, String tabId) async {
  final tab = find.byKey(ValueKey('community-tab-$tabId'));
  final rail = find.byKey(const ValueKey('community-bottom-tabs'));
  for (var attempt = 0; attempt < 12 && tab.evaluate().isEmpty; attempt += 1) {
    await tester.drag(rail, const Offset(-240, 0), warnIfMissed: false);
    await tester.pumpAndSettle();
  }
  expect(tab, findsOneWidget);
  await tester.tap(tab, warnIfMissed: false);
  await _pumpForUi(tester);
}

Future<void> _tapCameraAction(WidgetTester tester, String transitionId) async {
  final action = find.byKey(ValueKey('camera-action-$transitionId')).first;
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

Future<void> _openCameraTarget(
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
    if (finder.evaluate().isNotEmpty) {
      return;
    }
    await tester.pump(const Duration(milliseconds: 150));
  }
}
