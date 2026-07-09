import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loom_communities_demo/main.dart';

import 'workflow_ui_test_harness.dart';

void main() {
  testWidgets('garden engine tabs preserve app behavior parity', (tester) async {
    final target = loomEvidenceTargets.singleWhere(
      (target) => target.extensionId == 'ext_garden_club',
    );

    await tester.pumpWidget(const LoomCommunitiesDemoApp());
    await installEvidenceTarget(tester, target);
    await _openGardenTarget(tester, target);

    await _selectPersona(tester, 'garden-member');

    await _selectTab(tester, 'home');
    await _waitForFinder(
      tester,
      find.byKey(const ValueKey('garden-engine-home')),
    );
    expect(find.byKey(const ValueKey('garden-engine-home')), findsOneWidget);
    expect(find.byKey(const ValueKey('garden-home-activity')), findsOneWidget);
    expect(find.byKey(const ValueKey('garden-home-exchange')), findsOneWidget);
    expect(find.byKey(const ValueKey('garden-home-records')), findsOneWidget);

    await _selectTab(tester, 'calendar');
    await _waitForFinder(
      tester,
      find.byKey(const ValueKey('garden-engine-calendar')),
    );
    expect(find.byKey(const ValueKey('garden-engine-calendar')), findsOneWidget);
    await _tapGardenAction(tester, 'join-waitlist');
    expect(find.text('State: Waitlisted'), findsOneWidget);
    await _tapGardenAction(tester, 'rsvp-going');
    expect(find.text('State: RSVPed'), findsOneWidget);
    await _tapGardenAction(tester, 'cancel-rsvp');
    expect(find.text('State: Open'), findsOneWidget);

    await _selectTab(tester, 'marketplace');
    await _waitForFinder(
      tester,
      find.byKey(const ValueKey('garden-engine-marketplace')),
    );
    expect(
      find.byKey(const ValueKey('garden-engine-marketplace')),
      findsOneWidget,
    );
    await tester.enterText(
      find.byKey(const ValueKey('garden-edit-plantType')),
      'Thai basil starts',
    );
    await tester.enterText(
      find.byKey(const ValueKey('garden-edit-quantity')),
      '8 starter pots',
    );
    await tester.ensureVisible(
      find.byKey(
        const ValueKey('garden-save-edit-plant-exchange-submission'),
      ),
    );
    await _pumpForUi(tester);
    await tester.tap(
      find.byKey(
        const ValueKey('garden-save-edit-plant-exchange-submission'),
      ),
    );
    await tester.pumpAndSettle();

    await _tapGardenAction(tester, 'request-loan');
    expect(find.text('State: Loaned'), findsOneWidget);
    await _tapGardenAction(tester, 'join-queue');
    expect(find.text('Queue: 1'), findsOneWidget);
    await _tapGardenAction(tester, 'leave-queue');
    expect(find.text('Queue: 1'), findsNothing);
    await _tapGardenAction(tester, 'return-tool');
    expect(find.text('State: Returned'), findsOneWidget);

    await _tapGardenAction(tester, 'submit-listing');
    expect(find.text('State: Submitted'), findsOneWidget);
    expect(find.text('Thai basil starts'), findsOneWidget);
    await _tapGardenAction(tester, 'claim');
    expect(find.text('State: Claimed'), findsOneWidget);
    await _tapGardenAction(tester, 'cancel-claim');
    expect(find.text('State: Submitted'), findsOneWidget);
    await _tapGardenAction(tester, 'withdraw');
    expect(find.text('State: Withdrawn'), findsOneWidget);

    await _selectTab(tester, 'care');
    await _waitForFinder(
      tester,
      find.byKey(const ValueKey('garden-engine-care')),
    );
    expect(find.byKey(const ValueKey('garden-engine-care')), findsOneWidget);
    await _tapGardenAction(tester, 'sign-up');
    expect(find.text('State: Signed up'), findsOneWidget);
    await _tapGardenAction(tester, 'cancel-signup');
    expect(find.text('State: Open'), findsOneWidget);

    await _selectPersona(tester, 'garden-coordinator');
    await _selectTab(tester, 'documents');
    await _waitForFinder(
      tester,
      find.byKey(const ValueKey('garden-engine-documents')),
    );
    expect(
      find.byKey(const ValueKey('garden-engine-documents')),
      findsOneWidget,
    );
    expect(find.text('Review and confirm export scope'), findsOneWidget);
    await _tapGardenAction(tester, 'generate-export');
    expect(find.text('State: Generated'), findsOneWidget);
    await _tapGardenAction(tester, 'rollback-export');
    expect(find.text('State: Rolled back'), findsOneWidget);
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

Future<void> _tapGardenAction(WidgetTester tester, String transitionId) async {
  final action = find.byKey(ValueKey('garden-action-$transitionId'));
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

Future<void> _openGardenTarget(
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
