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
    await openEvidenceTarget(tester, target);

    await selectPersona(tester, 'garden-member');

    await _selectTab(tester, 'calendar');
    expect(find.byKey(const ValueKey('garden-engine-calendar')), findsOneWidget);
    await _tapGardenAction(tester, 'rsvp-going');
    expect(find.text('State: Going'), findsOneWidget);
    await _tapGardenAction(tester, 'cancel-rsvp');
    expect(find.text('State: Cancelled'), findsOneWidget);

    await _selectTab(tester, 'marketplace');
    expect(
      find.byKey(const ValueKey('garden-engine-marketplace')),
      findsOneWidget,
    );
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
    await _tapGardenAction(tester, 'claim');
    expect(find.text('State: Claimed'), findsOneWidget);
    await _tapGardenAction(tester, 'cancel-claim');
    expect(find.text('State: Submitted'), findsOneWidget);

    await _selectTab(tester, 'care');
    expect(find.byKey(const ValueKey('garden-engine-care')), findsOneWidget);
    await _tapGardenAction(tester, 'sign-up');
    expect(find.text('State: Signed up'), findsOneWidget);
    await _tapGardenAction(tester, 'cancel-signup');
    expect(find.text('State: Cancelled'), findsOneWidget);

    await selectPersona(tester, 'garden-coordinator');
    await _selectTab(tester, 'documents');
    expect(
      find.byKey(const ValueKey('garden-engine-documents')),
      findsOneWidget,
    );
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
  await tester.pumpAndSettle();
}

Future<void> _tapGardenAction(WidgetTester tester, String transitionId) async {
  final action = find.byKey(ValueKey('garden-action-$transitionId'));
  await scrollFinderIntoViewport(tester, action);
  await tester.tap(action, warnIfMissed: false);
  await tester.pumpAndSettle();
}
