import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loom_communities_demo/main.dart';

import 'workflow_ui_test_harness.dart';

void main() {
  testWidgets(
    'chess engine tabs preserve behavior and shipped rankings content',
    (tester) async {
      final target = loomEvidenceTargets.singleWhere(
        (target) => target.extensionId == 'ext_chess_club',
      );
      await tester.pumpWidget(const LoomCommunitiesDemoApp());
      await installEvidenceTarget(tester, target, useShippedPackage: true);
      await openEvidenceTarget(tester, target);
      await _selectPersona(tester, 'chess-member');

      expect(
        find.byKey(const ValueKey('community-tab-calendar')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('community-tab-admin')), findsOneWidget);
      expect(
        find.byKey(const ValueKey('community-tab-messages')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('community-tab-matches')), findsNothing);
      expect(
        find.byKey(const ValueKey('community-tab-rankings')),
        findsNothing,
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
        find.byKey(
          const ValueKey('workflow-table-grid-home-chess-rankings-table'),
        ),
        findsOneWidget,
      );
      expect(find.text('Maya Patel'), findsWidgets);
      expect(find.text('Jordan Lee'), findsWidgets);
      expect(
        find.byKey(
          const ValueKey('document-library-facts-chess-rules-rapid-tile'),
        ),
        findsOneWidget,
      );
      expect(find.text('Club rapid and ladder rules'), findsWidgets);

      await _selectTab(tester, 'calendar');
      await _waitForFinder(
        tester,
        find.byKey(const ValueKey('engine-native-list-root-calendar')),
      );
      expect(
        find.byKey(const ValueKey('engine-native-list-root-calendar')),
        findsOneWidget,
        reason:
            'Chess Calendar declares mixed archetypes and uses generic dispatch.',
      );
      expect(find.text('Friday rapid club night'), findsWidgets);
      expect(find.text('August open Swiss tournament'), findsWidgets);
      expect(
        find.byKey(
          const ValueKey('generic-instance-card-chess-meetup-maya-jordan'),
        ),
        findsOneWidget,
      );
      await _tapEngineAction(
        tester,
        instanceId: 'chess-night-august-14',
        transitionId: 'withdraw-club-night-rsvp',
      );
      expect(
        _engineAction('chess-night-august-14', 'rsvp-club-night'),
        findsOneWidget,
      );
      await _tapEngineAction(
        tester,
        instanceId: 'chess-night-august-14',
        transitionId: 'rsvp-club-night',
      );
      expect(
        _engineAction('chess-night-august-14', 'withdraw-club-night-rsvp'),
        findsOneWidget,
      );
      await _tapEngineAction(
        tester,
        instanceId: 'chess-meetup-maya-jordan',
        transitionId: 'decline-match',
      );
      expect(
        _engineAction('chess-meetup-maya-jordan', 'suggest-new-time'),
        findsOneWidget,
      );

      await _selectTab(tester, 'messages');
      await _waitForFinder(
        tester,
        find.byKey(const ValueKey('engine-native-list-root-messages')),
      );
      expect(
        find.byKey(const ValueKey('engine-native-list-root-messages')),
        findsOneWidget,
      );
      expect(
        find.byKey(
          const ValueKey('generic-instance-card-chess-thread-opening-prep'),
        ),
        findsOneWidget,
      );
      expect(find.text('Preparing against the Sicilian'), findsWidgets);

      await _selectPersona(tester, 'chess-organizer');
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
          const ValueKey('generic-instance-card-chess-pairing-friday-rapid'),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(
          const ValueKey('export-wizard-state-badge-chess-export-august-tile'),
        ),
        findsOneWidget,
      );
      await _tapEngineAction(
        tester,
        instanceId: 'chess-pairing-friday-rapid',
        transitionId: 'close-pairing-queue',
      );
      expect(
        _engineAction('chess-pairing-friday-rapid', 'close-pairing-queue'),
        findsNothing,
      );
      await _tapEngineAction(
        tester,
        instanceId: 'chess-export-august',
        transitionId: 'generate-export',
      );
      expect(
        _engineAction('chess-export-august', 'rollback-export'),
        findsOneWidget,
      );
    },
  );
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

Future<void> _selectPersona(WidgetTester tester, String personaId) async {
  await selectPersona(tester, personaId);
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
