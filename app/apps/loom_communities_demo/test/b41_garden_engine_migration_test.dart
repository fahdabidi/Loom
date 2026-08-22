import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loom_communities_demo/main.dart';

import 'workflow_ui_test_harness.dart';

void main() {
  testWidgets('garden engine tabs preserve app behavior parity', (
    tester,
  ) async {
    final target = loomEvidenceTargets.singleWhere(
      (target) => target.extensionId == 'ext_garden_club',
    );

    await tester.pumpWidget(const LoomCommunitiesDemoApp());
    await installEvidenceTarget(tester, target, useShippedPackage: true);
    await openEvidenceTarget(tester, target);

    await _selectPersona(tester, 'garden-member');

    expect(
      find.byKey(const ValueKey('community-tab-calendar')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('community-tab-marketplace')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('community-tab-care')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('community-tab-documents')),
      findsNothing,
      reason: 'The shipped package restricts Documents to the coordinator.',
    );

    await _selectTab(tester, 'home');
    await _waitForFinder(
      tester,
      find.byKey(const ValueKey('engine-native-list-root-home')),
    );
    expect(
      find.byKey(const ValueKey('engine-native-list-root-home')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('generic-instance-card-tomato-seedling-offer')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('generic-instance-card-basil-start-request')),
      findsNothing,
      reason:
          'Actor-only submissions owned by a different seeded individual '
          'must not leak to a newly created member account.',
    );
    expect(
      find.text('Spring Workshop: Pollinator-Friendly Planting'),
      findsWidgets,
    );
    expect(find.text('Steel wheelbarrow'), findsWidgets);

    expect(
      _engineAction('basil-start-request', 'withdraw-submission'),
      findsNothing,
      reason: 'Another individual must not receive the owner-only action.',
    );

    await _selectTab(tester, 'calendar');
    await _waitForFinder(
      tester,
      find.byKey(const ValueKey('engine-native-calendar-root')),
    );
    expect(
      find.byKey(const ValueKey('engine-native-calendar-root')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('engine-native-calendar-date-strip')),
      findsOneWidget,
    );
    expect(
      find.text('Spring Workshop: Pollinator-Friendly Planting'),
      findsWidgets,
    );

    await _tapEngineAction(
      tester,
      instanceId: 'spring-workshop',
      transitionId: 'respond-waitlist',
    );
    expect(_engineAction('spring-workshop', 'withdraw-rsvp'), findsOneWidget);
    await _tapEngineAction(
      tester,
      instanceId: 'spring-workshop',
      transitionId: 'withdraw-rsvp',
    );
    expect(
      _engineAction('spring-workshop', 'respond-waitlist'),
      findsOneWidget,
    );

    await _selectTab(tester, 'marketplace');
    await _waitForFinder(
      tester,
      find.byKey(const ValueKey('engine-native-marketplace-root')),
    );
    expect(
      find.byKey(const ValueKey('engine-native-marketplace-root')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('marketplace-search-field')),
      findsOneWidget,
    );
    expect(find.text('Steel wheelbarrow'), findsWidgets);
    expect(find.text('Terracotta pots — assorted sizes'), findsWidgets);

    await tester.enterText(
      find.byKey(const ValueKey('marketplace-search-field')),
      'wheelbarrow',
    );
    await _pumpForUi(tester);
    expect(find.text('Steel wheelbarrow'), findsWidgets);
    expect(find.text('Club hand-tool set'), findsNothing);

    await _selectTab(tester, 'care');
    await _waitForFinder(
      tester,
      find.byKey(const ValueKey('engine-native-list-root-care')),
    );
    expect(
      find.byKey(const ValueKey('engine-native-list-root-care')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('generic-instance-card-mulch-delivery-shift')),
      findsOneWidget,
    );
    await _tapEngineAction(
      tester,
      instanceId: 'mulch-delivery-shift',
      transitionId: 'sign-up',
    );
    expect(
      _engineAction('mulch-delivery-shift', 'cancel-signup'),
      findsOneWidget,
    );
    await _tapEngineAction(
      tester,
      instanceId: 'mulch-delivery-shift',
      transitionId: 'cancel-signup',
    );
    expect(_engineAction('mulch-delivery-shift', 'sign-up'), findsOneWidget);

    await _selectPersona(tester, 'garden-coordinator');
    expect(
      find.byKey(const ValueKey('community-tab-documents')),
      findsOneWidget,
    );
    await _selectTab(tester, 'documents');
    await _waitForFinder(
      tester,
      find.byKey(const ValueKey('engine-native-list-root-documents')),
    );
    expect(
      find.byKey(const ValueKey('engine-native-list-root-documents')),
      findsOneWidget,
    );
    expect(
      find.byKey(
        const ValueKey('export-wizard-state-badge-fall-export-package-tile'),
      ),
      findsOneWidget,
    );
    expect(
      _engineAction('fall-export-package', 'start-export'),
      findsNothing,
      reason:
          'A newly created coordinator may read the seeded export summary '
          'but must not run an export owned by another individual.',
    );
    expect(
      find.byKey(const ValueKey('creatable-fab-garden-export-custom-schemas')),
      findsOneWidget,
    );
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

Finder _engineAction(String instanceId, String transitionId) {
  return find.byWidgetPredicate((widget) {
    final key = widget.key;
    return key is ValueKey<String> &&
        key.value.contains(instanceId) &&
        (key.value.endsWith('-action-$transitionId') ||
            key.value.endsWith('-$transitionId-$instanceId'));
  }, description: '$instanceId action $transitionId');
}

Future<void> _tapEngineAction(
  WidgetTester tester, {
  required String instanceId,
  required String transitionId,
}) async {
  final action = _engineAction(instanceId, transitionId).first;
  await _waitForFinder(tester, action);
  expect(action, findsOneWidget);
  await tester.ensureVisible(action);
  await _pumpForUi(tester);
  await tester.tap(action, warnIfMissed: false);
  await _pumpForUi(tester);
}

Future<void> _selectPersona(WidgetTester tester, String fanId) async {
  await selectPersona(tester, fanId);
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
