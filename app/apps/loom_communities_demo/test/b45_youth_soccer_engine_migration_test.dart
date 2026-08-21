import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loom_communities_demo/main.dart';

import 'workflow_ui_test_harness.dart';

void main() {
  testWidgets(
    'youth soccer engine tabs preserve guided, protected, and export parity',
    (tester) async {
      final target = loomEvidenceTargets.singleWhere(
        (target) => target.extensionId == 'ext_youth_soccer',
      );
      await tester.pumpWidget(const LoomCommunitiesDemoApp());
      await installEvidenceTarget(tester, target, useShippedPackage: true);
      await openEvidenceTarget(tester, target);
      await seedEvidenceAccounts(tester, target, const [
        LoomAccount(
          accountId: 'soccer-guardian',
          displayName: 'River guardian',
          personaTypeId: 'soccer-guardian',
        ),
        LoomAccount(
          accountId: 'soccer-guardian-peer',
          displayName: 'Another soccer guardian',
          personaTypeId: 'soccer-guardian',
        ),
        LoomAccount(
          accountId: 'soccer-owner',
          displayName: 'Seeded league owner',
          personaTypeId: 'soccer-owner',
        ),
      ]);
      await signInEvidenceAccount(tester, 'River guardian');

      expect(
        find.byKey(const ValueKey('community-tab-calendar')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('community-tab-giving')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('community-tab-team')), findsOneWidget);
      expect(
        find.byKey(const ValueKey('community-tab-documents')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('community-tab-admin')), findsNothing);
      expect(
        find.byKey(const ValueKey('community-tab-registration')),
        findsNothing,
        reason:
            'Registration is declared as a Home workflow, not a package tab.',
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
          const ValueKey(
            'generic-instance-card-soccer-registration-case-river',
          ),
        ),
        findsOneWidget,
      );
      expect(find.text("River's fall registration"), findsWidgets);
      expect(find.text('Riverside Rapids U12 practice'), findsWidgets);
      expect(
        find.byKey(
          const ValueKey('generic-instance-card-soccer-payment-river'),
        ),
        findsOneWidget,
        reason: 'The seeded payer must see their own registration payment.',
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
      await _tapEngineAction(
        tester,
        instanceId: 'soccer-practice-aug-18',
        transitionId: 'respond-maybe',
      );
      expect(
        _engineAction('soccer-practice-aug-18', 'cancel-rsvp'),
        findsOneWidget,
      );
      await _tapEngineAction(
        tester,
        instanceId: 'soccer-practice-aug-18',
        transitionId: 'cancel-rsvp',
      );
      expect(
        _engineAction('soccer-practice-aug-18', 'respond-going'),
        findsOneWidget,
      );

      await _selectTab(tester, 'team');
      await _waitForFinder(
        tester,
        find.byKey(
          const ValueKey('workflow-table-grid-team-soccer-team-roster'),
        ),
      );
      expect(
        find.byKey(
          const ValueKey('workflow-table-grid-team-soccer-team-roster'),
        ),
        findsOneWidget,
      );
      expect(find.text('Jordan R.'), findsWidgets);
      final rosterRow = find.byKey(
        const ValueKey(
          'workflow-table-row-team-soccer-team-roster-'
          'soccer-roster-jordan-0',
        ),
      );
      expect(rosterRow, findsOneWidget);
      await tester.ensureVisible(rosterRow);
      await _pumpForUi(tester);
      await tester.tap(rosterRow, warnIfMissed: false);
      final rosterDialog = find.byKey(
        const ValueKey('workflow-table-detail-dialog-soccer-roster-jordan'),
      );
      await _waitForFinder(tester, rosterDialog);
      expect(rosterDialog, findsOneWidget);
      expect(
        find.text('Privacy: Guardian Approved Limited Share'),
        findsOneWidget,
      );
      await tester.tap(
        find.byKey(
          const ValueKey('workflow-table-detail-close-soccer-roster-jordan'),
        ),
      );
      await _pumpForUi(tester);
      await _waitForFinder(
        tester,
        find.byKey(
          const ValueKey('generic-instance-card-soccer-redaction-jordan'),
        ),
      );
      expect(
        find.byKey(
          const ValueKey('generic-instance-card-soccer-redaction-jordan'),
        ),
        findsOneWidget,
        reason: 'The seeded guardian must see their own privacy record.',
      );
      expect(find.textContaining('Full birth date hidden'), findsWidgets);
      expect(find.textContaining('Medical notes hidden'), findsWidgets);

      await _selectTab(tester, 'giving');
      await _waitForFinder(
        tester,
        find.byKey(const ValueKey('engine-native-list-root-giving')),
      );
      expect(
        find.byKey(const ValueKey('engine-native-list-root-giving')),
        findsOneWidget,
      );
      expect(
        find.byKey(
          const ValueKey('generic-instance-card-soccer-payment-river'),
        ),
        findsOneWidget,
        reason: 'The seeded payer must see their payment on the Giving tab.',
      );
      expect(find.textContaining(r'$185'), findsWidgets);

      await _selectTab(tester, 'messages');
      await _waitForFinder(
        tester,
        find.byKey(const ValueKey('engine-native-list-root-messages')),
      );
      expect(
        find.byKey(const ValueKey('engine-native-list-root-messages')),
        findsOneWidget,
      );
      expect(find.text('Saturday field update'), findsWidgets);

      await signInEvidenceAccount(tester, 'Another soccer guardian');
      await openEvidenceTarget(tester, target);
      await _selectTab(tester, 'home');
      await _waitForFinder(
        tester,
        find.byKey(const ValueKey('engine-native-list-root-home')),
      );
      expect(
        find.byKey(
          const ValueKey(
            'generic-instance-card-soccer-registration-case-river',
          ),
        ),
        findsOneWidget,
        reason:
            'The same-role account still renders role-visible Home content.',
      );
      expect(
        find.byKey(
          const ValueKey('generic-instance-card-soccer-payment-river'),
        ),
        findsNothing,
        reason:
            'A different guardian account must not see the seeded payer\'s '
            'registration payment.',
      );

      await _selectTab(tester, 'team');
      await _waitForFinder(
        tester,
        find.byKey(
          const ValueKey('workflow-table-grid-team-soccer-team-roster'),
        ),
      );
      expect(
        find.byKey(
          const ValueKey('workflow-table-grid-team-soccer-team-roster'),
        ),
        findsOneWidget,
        reason: 'The same-role account still renders the role-visible roster.',
      );
      expect(
        find.byKey(
          const ValueKey('generic-instance-card-soccer-redaction-jordan'),
        ),
        findsNothing,
        reason:
            'A different guardian account must not see the seeded guardian\'s '
            'privacy record.',
      );

      await _selectTab(tester, 'giving');
      await _waitForFinder(
        tester,
        find.byKey(const ValueKey('engine-native-list-empty-giving')),
      );
      expect(
        find.byKey(const ValueKey('engine-native-list-error-giving')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('engine-native-list-empty-giving')),
        findsOneWidget,
      );
      expect(
        find.byKey(
          const ValueKey('generic-instance-card-soccer-payment-river'),
        ),
        findsNothing,
        reason:
            'A different guardian account must not see the seeded payer\'s '
            'payment on the Giving tab.',
      );

      await _selectPersona(tester, 'soccer-coach');
      expect(find.byKey(const ValueKey('community-tab-admin')), findsOneWidget);
      expect(find.byKey(const ValueKey('community-tab-giving')), findsNothing);
      await _selectTab(tester, 'admin');
      await _waitForFinder(
        tester,
        find.byKey(const ValueKey('engine-native-list-root-admin')),
      );
      expect(
        find.byKey(const ValueKey('engine-native-list-root-admin')),
        findsOneWidget,
      );
      await _tapEngineAction(
        tester,
        instanceId: 'soccer-registration-case-river',
        transitionId: 'approve-request',
      );
      expect(
        _engineAction('soccer-registration-case-river', 'approve-request'),
        findsNothing,
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
          const ValueKey('document-library-facts-soccer-waiver-river-tile'),
        ),
        findsOneWidget,
      );
      expect(
        find.text('2026 Player Safety and Participation Waiver'),
        findsWidgets,
      );

      await signInEvidenceAccount(tester, 'Seeded league owner');
      await openEvidenceTarget(tester, target);
      expect(find.byKey(const ValueKey('community-tab-team')), findsNothing);
      expect(
        find.byKey(const ValueKey('community-tab-documents')),
        findsNothing,
      );
      await _selectTab(tester, 'admin');
      await _waitForFinder(
        tester,
        find.byKey(
          const ValueKey(
            'export-wizard-state-badge-soccer-export-fall-2026-tile',
          ),
        ),
      );
      expect(
        find.byKey(
          const ValueKey(
            'export-wizard-state-badge-soccer-export-fall-2026-tile',
          ),
        ),
        findsOneWidget,
        reason: 'The seeded league owner must see their own export.',
      );
      expect(
        _engineAction('soccer-export-fall-2026', 'start-export'),
        findsOneWidget,
      );
      final engine = await workflowEngineForExtensionId(target.extensionId);
      await engine.applyTransition(
        workflowType: 'soccer-export-metadata',
        instanceId: 'soccer-export-fall-2026',
        transitionId: 'start-export',
        personaId: 'soccer-owner',
        inputs: const {'operationMode': 'export'},
      );
      await openEvidenceTarget(tester, target);
      await _selectTab(tester, 'admin');
      await _waitForFinder(
        tester,
        _engineAction('soccer-export-fall-2026', 'record-export-ready'),
      );
      expect(
        _engineAction('soccer-export-fall-2026', 'record-export-ready'),
        findsOneWidget,
      );
    },
  );
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
