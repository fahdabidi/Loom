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
      await installShippedEvidenceTarget(tester, target);
      await openEvidenceTarget(tester, target);
      await seedEvidenceAccounts(tester, target, const [
        LoomAccount(
          accountId: 'soccer-guardian',
          displayName: 'River guardian',
          roleId: 'soccer-guardian',
        ),
        LoomAccount(
          accountId: 'soccer-guardian-peer',
          displayName: 'Another soccer guardian',
          roleId: 'soccer-guardian',
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
      await waitForEngineNativeWidget(
        tester,
        find.byKey(const ValueKey('engine-native-list-root-home')),
        description: 'guardian Home engine-native list',
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
      await waitForEngineNativeWidget(
        tester,
        find.byKey(const ValueKey('engine-native-calendar-root')),
        description: 'guardian Calendar engine-native surface',
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
      await waitForEngineNativeWidget(
        tester,
        find.byKey(
          const ValueKey('workflow-table-grid-team-soccer-team-roster'),
        ),
        description: 'guardian Team roster grid',
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
      await waitForEngineNativeWidget(
        tester,
        rosterDialog,
        description: 'guardian roster detail dialog',
      );
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
      await waitForEngineNativeWidget(
        tester,
        find.byKey(
          const ValueKey('generic-instance-card-soccer-redaction-jordan'),
        ),
        description: 'guardian exact-identity privacy record',
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
      await waitForEngineNativeWidget(
        tester,
        find.byKey(const ValueKey('engine-native-list-root-giving')),
        description: 'guardian Giving engine-native list',
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
      await waitForEngineNativeWidget(
        tester,
        find.byKey(const ValueKey('engine-native-list-root-messages')),
        description: 'guardian Messages engine-native list',
      );
      expect(
        find.byKey(const ValueKey('engine-native-list-root-messages')),
        findsOneWidget,
      );
      expect(find.text('Saturday field update'), findsWidgets);

      await signInEvidenceAccount(tester, 'Another soccer guardian');
      await openEvidenceTarget(tester, target);
      await _selectTab(tester, 'home');
      await waitForEngineNativeWidget(
        tester,
        find.byKey(const ValueKey('engine-native-list-root-home')),
        description: 'peer guardian Home engine-native list',
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
      await waitForEngineNativeWidget(
        tester,
        find.byKey(
          const ValueKey('workflow-table-grid-team-soccer-team-roster'),
        ),
        description: 'peer guardian Team roster grid',
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
      await waitForEngineNativeWidget(
        tester,
        find.byKey(const ValueKey('engine-native-list-empty-giving')),
        description: 'peer guardian empty Giving state',
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

      await _selectActorIdentity(tester, 'soccer-coach');
      expect(find.byKey(const ValueKey('community-tab-admin')), findsOneWidget);
      expect(find.byKey(const ValueKey('community-tab-giving')), findsNothing);
      await _selectTab(tester, 'admin');
      await waitForEngineNativeWidget(
        tester,
        find.byKey(const ValueKey('engine-native-list-root-admin')),
        description: 'coach Admin engine-native list',
      );
      expect(
        find.byKey(const ValueKey('engine-native-list-root-admin')),
        findsOneWidget,
      );
      expect(
        find.byKey(
          const ValueKey(
            'export-wizard-state-badge-soccer-export-fall-2026-tile',
          ),
        ),
        findsNothing,
        reason: 'A non-owner account must not see the owner export.',
      );
      expect(
        _engineAction('soccer-export-fall-2026', 'start-export'),
        findsNothing,
        reason: 'A non-owner account must not execute the owner export.',
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
      await waitForEngineNativeWidget(
        tester,
        find.byKey(const ValueKey('engine-native-list-root-documents')),
        description: 'coach Documents engine-native list',
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

      await _selectActorIdentity(tester, 'soccer-owner');
      final ownerAccountId = _activeAccountId(tester);
      expect(
        ownerAccountId,
        isNot('soccer-owner'),
        reason:
            'The owner must be a generated account created through the '
            'specific-person switcher, not a role-shaped seeded identity.',
      );
      expect(find.byKey(const ValueKey('community-tab-team')), findsNothing);
      expect(
        find.byKey(const ValueKey('community-tab-documents')),
        findsNothing,
      );
      await _selectTab(tester, 'admin');
      await waitForEngineNativeWidget(
        tester,
        find.byKey(const ValueKey('engine-native-list-root-admin')),
        description: 'fresh owner Admin engine-native list',
      );
      expect(
        find.byKey(const ValueKey('engine-native-list-error-admin')),
        findsNothing,
      );
      expect(
        find.byKey(
          ValueKey('engine-native-bindings-error-admin-$ownerAccountId'),
        ),
        findsNothing,
      );
      await waitForEngineNativeWidget(
        tester,
        find.byKey(
          const ValueKey(
            'export-wizard-state-badge-soccer-export-fall-2026-tile',
          ),
        ),
        description: 'seeded Soccer export for the generated owner account',
      );
      expect(
        find.byKey(
          const ValueKey(
            'export-wizard-state-badge-soccer-export-fall-2026-tile',
          ),
        ),
        findsOneWidget,
        reason:
            'A generated owner account must see the role-guarded export '
            'created by the seeded soccer-owner identity.',
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
        fanId: ownerAccountId,
        inputs: const {'operationMode': 'export'},
      );
      await openEvidenceTarget(tester, target);
      await _selectTab(tester, 'admin');
      await waitForEngineNativeWidget(
        tester,
        _engineAction('soccer-export-fall-2026', 'record-export-ready'),
        description: 'seeded Soccer export ready-recording action',
      );
      expect(
        _engineAction('soccer-export-fall-2026', 'record-export-ready'),
        findsOneWidget,
      );

      const freshExportTitle = 'Fresh owner registration export';
      final createExport = find.byKey(
        const ValueKey('creatable-fab-soccer-export-metadata'),
      );
      await waitForEngineNativeWidget(
        tester,
        createExport,
        description: 'fresh owner New redacted export action',
      );
      await tester.tap(createExport, warnIfMissed: false);
      final exportTitle = find.byKey(
        const ValueKey('new-soccer-export-metadata-editor-exportTitle'),
      );
      await waitForEngineNativeWidget(
        tester,
        exportTitle,
        description: 'new Soccer export title editor',
      );
      await tester.enterText(exportTitle, freshExportTitle);
      final submitExport = find.byKey(
        const ValueKey('new-soccer-export-metadata-submit'),
      );
      await tester.ensureVisible(submitExport);
      await _pumpForUi(tester);
      await tester.tap(submitExport);

      final freshExportBadge = _freshOwnerExportBadge();
      final createExportError = find.byKey(
        const ValueKey('new-soccer-export-metadata-error'),
      );
      await waitForEngineNativeWidget(
        tester,
        _freshOwnerExportCreationOutcome(),
        description: 'new Soccer export result or visible creation error',
      );
      expect(createExportError, findsNothing);
      expect(freshExportBadge, findsOneWidget);
      expect(find.text(freshExportTitle), findsWidgets);

      await openEvidenceTarget(tester, target);
      await _selectTab(tester, 'admin');
      await waitForEngineNativeWidget(
        tester,
        freshExportBadge,
        description: 'fresh owner export after reopening the community',
      );
      expect(
        find.text(freshExportTitle),
        findsWidgets,
        reason:
            'The generated owner must retain creator visibility for the '
            'export created through the visible workflow. The seeded export '
            'assertion above, not this creator-owned row, proves registration.',
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
  await tester.ensureVisible(tab);
  await tester.pumpAndSettle();
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
  await waitForEngineNativeWidget(
    tester,
    action,
    description: '$instanceId action $transitionId',
  );
  expect(action, findsOneWidget);
  await tester.ensureVisible(action);
  await _pumpForUi(tester);
  await tester.tap(action, warnIfMissed: false);
  await _pumpForUi(tester);
}

Future<void> _selectActorIdentity(WidgetTester tester, String fanId) async {
  await selectActorIdentity(tester, fanId);
}

Future<void> _pumpForUi(WidgetTester tester) async {
  for (var attempt = 0; attempt < 8; attempt += 1) {
    await tester.pump(const Duration(milliseconds: 150));
  }
}

String _activeAccountId(WidgetTester tester) {
  final screen = tester.widget<LocalExtensionScreen>(
    find.byType(LocalExtensionScreen),
  );
  final authApi = screen.authApi;
  expect(authApi, isA<LocalAuthApi>());
  final accountId = (authApi as LocalAuthApi).currentSession?.account.accountId;
  expect(accountId, isNotNull);
  return accountId!;
}

Finder _freshOwnerExportBadge() => find.byWidgetPredicate((widget) {
  final key = widget.key;
  return key is ValueKey<String> &&
      key.value.startsWith('export-wizard-state-badge-') &&
      key.value.endsWith('-tile') &&
      !key.value.contains('soccer-export-fall-2026');
}, description: 'fresh owner export state badge');

Finder _freshOwnerExportCreationOutcome() => find.byWidgetPredicate((widget) {
  final key = widget.key;
  if (key == const ValueKey('new-soccer-export-metadata-error')) return true;
  return key is ValueKey<String> &&
      key.value.startsWith('export-wizard-state-badge-') &&
      key.value.endsWith('-tile') &&
      !key.value.contains('soccer-export-fall-2026');
}, description: 'fresh owner export badge or creation error');
