import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loom_communities_demo/main.dart';

import 'workflow_ui_test_harness.dart';

void main() {
  testWidgets(
    'mosque engine tabs preserve audience, privacy, giving, admin, messages, and search parity',
    (tester) async {
      final target = loomEvidenceTargets.singleWhere(
        (target) => target.extensionId == 'ext_mosque',
      );
      await tester.pumpWidget(const LoomCommunitiesDemoApp());
      await installShippedEvidenceTarget(tester, target);
      await openEvidenceTarget(tester, target);
      await seedEvidenceAccounts(tester, target, const [
        LoomAccount(
          accountId: 'community-member',
          displayName: 'Seeded community member',
          roleId: 'community-member',
        ),
        LoomAccount(
          accountId: 'community-member-peer',
          displayName: 'Another community member',
          roleId: 'community-member',
        ),
      ]);
      await signInEvidenceAccount(tester, 'Seeded community member');
      expect(
        find.byKey(const ValueKey('community-tab-calendar')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('community-tab-giving')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('community-tab-resources')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('community-tab-admin')), findsNothing);
      expect(
        find.byKey(const ValueKey('community-tab-care')),
        findsNothing,
        reason: 'Care requests are declared on Home in the shipped package.',
      );

      await _selectTab(tester, 'home');
      await _waitForFinder(
        tester,
        find.text('Friday service and community iftar'),
      );
      expect(
        find.byKey(const ValueKey('engine-native-list-root-home')),
        findsOneWidget,
      );
      expect(find.text('Friday service and community iftar'), findsWidgets);
      expect(
        find.byKey(
          const ValueKey('generic-instance-card-masjid-care-meal-support'),
        ),
        findsOneWidget,
        reason: 'The seeded requester must see their own care request.',
      );
      expect(
        find.byKey(
          const ValueKey('generic-instance-card-masjid-donation-iftar-offline'),
        ),
        findsOneWidget,
        reason: 'The seeded payer must see their own donation.',
      );

      await _selectTab(tester, 'calendar');
      await _waitForFinder(
        tester,
        find.byKey(const ValueKey('engine-native-list-root-calendar')),
      );
      expect(
        find.byKey(const ValueKey('engine-native-list-root-calendar')),
        findsOneWidget,
        reason: 'Calendar mixes event-rsvp and volunteer form bindings.',
      );
      expect(find.text('Friday service and community iftar'), findsWidgets);
      expect(find.text('Community iftar setup team'), findsWidgets);
      await _tapEngineAction(
        tester,
        instanceId: 'masjid-event-friday-iftar',
        transitionId: 'rsvp-maybe',
      );
      expect(
        _engineAction('masjid-event-friday-iftar', 'cancel-rsvp'),
        findsOneWidget,
      );

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
        find.textContaining('Cash donation recorded by the Masjid office'),
        findsWidgets,
        reason: 'The seeded payer must see their donation receipt summary.',
      );
      expect(
        find.byKey(
          const ValueKey('generic-instance-card-masjid-donor-preference-iftar'),
        ),
        findsOneWidget,
        reason: 'The seeded donor must see their own visibility preference.',
      );
      await _tapEngineAction(
        tester,
        instanceId: 'masjid-donor-preference-iftar',
        transitionId: 'set-donor-public',
      );
      expect(
        _engineAction('masjid-donor-preference-iftar', 'set-donor-anonymous'),
        findsOneWidget,
      );
      await _tapEngineAction(
        tester,
        instanceId: 'masjid-donor-preference-iftar',
        transitionId: 'set-donor-anonymous',
      );
      expect(
        _engineAction('masjid-donor-preference-iftar', 'set-donor-public'),
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
      expect(find.text('Care request received'), findsWidgets);
      expect(find.text('Iftar logistics and food contributions'), findsWidgets);
      await _tapEngineAction(
        tester,
        instanceId: 'masjid-notice-care-received',
        transitionId: 'mark-notification-read',
      );
      expect(
        _engineAction(
          'masjid-notice-care-received',
          'mark-notification-unread',
        ),
        findsOneWidget,
      );

      await _selectTab(tester, 'resources');
      await _waitForFinder(
        tester,
        find.byKey(const ValueKey('engine-native-list-root-resources')),
      );
      expect(
        find.byKey(const ValueKey('engine-native-list-root-resources')),
        findsOneWidget,
      );
      expect(
        find.text('Friday khutbah notes — Mercy in community care'),
        findsWidgets,
      );
      expect(
        find.byKey(
          const ValueKey(
            'search-ai-answer-answer-masjid-search-iftar-time-tile',
          ),
        ),
        findsOneWidget,
      );
      await _tapEngineAction(
        tester,
        instanceId: 'masjid-search-iftar-time',
        transitionId: 'save-search-answer',
      );
      expect(
        find.byKey(
          const ValueKey('search-ai-answer-error-masjid-search-iftar-time'),
        ),
        findsNothing,
        reason: 'The repeatable save transition must complete successfully.',
      );
      expect(
        _engineAction('masjid-search-iftar-time', 'save-search-answer'),
        findsOneWidget,
      );

      await signInEvidenceAccount(tester, 'Another community member');
      await openEvidenceTarget(tester, target);
      await _selectTab(tester, 'home');
      await _waitForFinder(
        tester,
        find.text('Friday service and community iftar'),
      );
      expect(find.text('Friday service and community iftar'), findsWidgets);
      expect(
        find.byKey(
          const ValueKey('generic-instance-card-masjid-care-meal-support'),
        ),
        findsNothing,
        reason:
            'A different community-member account must not see the seeded '
            'requester\'s care request.',
      );
      expect(
        find.byKey(
          const ValueKey('generic-instance-card-masjid-donation-iftar-offline'),
        ),
        findsNothing,
        reason:
            'A different community-member account must not see the seeded '
            'payer\'s donation.',
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
          const ValueKey('generic-instance-card-masjid-donation-iftar-offline'),
        ),
        findsNothing,
        reason:
            'A different community-member account must not see the seeded '
            'payer\'s donation on the Giving tab.',
      );
      expect(
        find.byKey(
          const ValueKey('generic-instance-card-masjid-donor-preference-iftar'),
        ),
        findsNothing,
        reason:
            'A different community-member account must not see the seeded '
            'donor\'s visibility preference.',
      );

      await _selectTab(tester, 'messages');
      await _waitForFinder(
        tester,
        find.byKey(const ValueKey('engine-native-list-root-messages')),
      );
      expect(find.text('Iftar logistics and food contributions'), findsWidgets);
      expect(
        find.text('Care request received'),
        findsNothing,
        reason:
            'A different community-member account must not receive the seeded '
            'member\'s private care notification.',
      );

      await _selectActorIdentity(tester, 'masjid-admin');
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
          const ValueKey('generic-instance-card-masjid-care-meal-support'),
        ),
        findsOneWidget,
      );
      await _tapEngineAction(
        tester,
        instanceId: 'masjid-care-meal-support',
        transitionId: 'approve-and-assign-care-request',
      );
      expect(
        _engineAction('masjid-care-meal-support', 'send-private-care-response'),
        findsOneWidget,
      );
      await _tapEngineAction(
        tester,
        instanceId: 'masjid-volunteer-iftar-setup',
        transitionId: 'close-volunteer-shift',
      );
      expect(
        _engineAction('masjid-volunteer-iftar-setup', 'close-volunteer-shift'),
        findsNothing,
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

Future<void> _selectActorIdentity(WidgetTester tester, String fanId) async {
  await selectActorIdentity(tester, fanId);
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
