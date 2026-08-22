import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loom_communities_demo/main.dart';

import 'workflow_ui_test_harness.dart';

void main() {
  testWidgets('camera engine tabs preserve app behavior parity', (
    tester,
  ) async {
    final target = loomEvidenceTargets.singleWhere(
      (target) => target.extensionId == 'ext_camera_club',
    );

    await tester.pumpWidget(const LoomCommunitiesDemoApp());
    await installEvidenceTarget(tester, target, useShippedPackage: true);
    await openEvidenceTarget(tester, target);

    await _selectPersona(tester, 'camera-club-member');

    expect(
      find.byKey(const ValueKey('community-tab-calendar')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('community-tab-critique')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('community-tab-marketplace')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('community-tab-admin')), findsNothing);

    await _selectTab(tester, 'home');
    await _waitForFinder(
      tester,
      find.byKey(const ValueKey('engine-native-list-root-home')),
    );
    expect(
      find.byKey(const ValueKey('engine-native-list-root-home')),
      findsOneWidget,
    );
    expect(find.text('Golden Gate sunrise photo walk'), findsWidgets);
    expect(find.text('Canon 70-200mm f/2.8 lens'), findsWidgets);
    expect(
      find.byKey(
        const ValueKey('generic-instance-card-critique-lighthouse-portrait'),
      ),
      findsNothing,
      reason:
          'Actor-only critiques owned by a different seeded individual must '
          'not leak to a newly created member account.',
    );
    expect(
      find.byKey(
        const ValueKey('generic-instance-card-camera-validation-report-1'),
      ),
      findsOneWidget,
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
      find.byKey(const ValueKey('engine-native-calendar-grouped-agenda')),
      findsOneWidget,
    );
    await _tapEngineAction(
      tester,
      instanceId: 'walk-golden-gate-sunrise',
      transitionId: 'respond-going',
    );
    expect(
      _engineAction('walk-golden-gate-sunrise', 'respond-maybe'),
      findsOneWidget,
    );
    await _tapEngineAction(
      tester,
      instanceId: 'walk-golden-gate-sunrise',
      transitionId: 'respond-maybe',
    );
    expect(
      _engineAction('walk-golden-gate-sunrise', 'withdraw-response'),
      findsOneWidget,
    );

    await _selectTab(tester, 'critique');
    await _waitForFinder(
      tester,
      find.byKey(const ValueKey('engine-native-list-empty-critique')),
    );
    expect(
      find.byKey(const ValueKey('engine-native-list-empty-critique')),
      findsOneWidget,
    );
    expect(
      find.byKey(
        const ValueKey('generic-instance-card-critique-lighthouse-portrait'),
      ),
      findsNothing,
    );
    expect(
      find.byKey(
        const ValueKey(
          'generic-instance-card-critique-night-market-reflections',
        ),
      ),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('creatable-fab-critique-submission')),
      findsOneWidget,
    );
    expect(
      _engineAction('critique-lighthouse-portrait', 'withdraw'),
      findsNothing,
      reason: 'Another individual must not receive the author-only action.',
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
    expect(find.text('Canon 70-200mm f/2.8 lens'), findsWidgets);
    expect(find.text('Older speedlite flash — free'), findsWidgets);
    await _tapEngineAction(
      tester,
      instanceId: 'gear-old-speedlite-giveaway',
      transitionId: 'claim-giveaway',
    );
    expect(
      _engineAction('gear-old-speedlite-giveaway', 'claim-giveaway'),
      findsNothing,
    );

    await _selectPersona(tester, 'camera-club-organizer');
    expect(find.byKey(const ValueKey('community-tab-admin')), findsOneWidget);
    await _selectTab(tester, 'admin');
    await _waitForFinder(
      tester,
      find.byKey(const ValueKey('engine-native-list-root-admin')),
    );
    expect(
      find.byKey(const ValueKey('engine-native-list-root-admin')),
      findsOneWidget,
    );
    expect(
      find.byKey(
        const ValueKey('generic-instance-card-camera-validation-report-1'),
      ),
      findsOneWidget,
    );
    await _tapEngineAction(
      tester,
      instanceId: 'camera-validation-report-1',
      transitionId: 'review-completion',
    );
    expect(
      _engineAction('camera-validation-report-1', 'review-completion'),
      findsNothing,
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
