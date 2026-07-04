import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loom_communities_demo/main.dart';

import 'workflow_ui_test_harness.dart';

const _extensionId = 'ext_verify_tabletop_club';

void main() {
  group('B35 Giving payment tab', () {
    // (a) Rule 2 positive: fixture with givingPayment declared renders
    // the real Giving UI and the placeholder text is absent.
    testWidgets('wf_giving-renders-real-when-payment-declared', (
      tester,
    ) async {
      final fixture = _writeTabletopClubPackagePair();
      await tester.pumpWidget(const LoomCommunitiesDemoApp());
      await _installAndOpen(tester, fixture);

      await _tapTab(tester, 'giving');

      // Real giving surface + amount summary render
      expect(find.byKey(const ValueKey('giving-tab-surface')), findsOneWidget);
      expect(
        find.byKey(const ValueKey('giving-amount-summary')),
        findsOneWidget,
      );
      // Exact match (not textContaining) so this doesn't also match the
      // checkout button's "Pay $15" label.
      expect(find.text('\$15'), findsOneWidget);
      expect(
        find.textContaining('Quarterly club dues'),
        findsOneWidget,
      );
      // Checkout button exists
      expect(
        find.byKey(const ValueKey('giving-checkout-tabletop-club-dues-payment')),
        findsOneWidget,
      );
      // Placeholder text must NOT appear (rule 2 positive)
      expect(
        find.textContaining('is coming to Tabletop Club'),
        findsNothing,
      );
    });

    // (b) Rule 2 negative: fixture without givingPayment still shows
    // the placeholder and real Giving keys are absent.
    testWidgets('wf_giving-shows-placeholder-without-payment', (
      tester,
    ) async {
      final fixture = _writeTabletopClubPackagePair(includeGivingPayment: false);
      await tester.pumpWidget(const LoomCommunitiesDemoApp());
      await _installAndOpen(tester, fixture);

      await _tapTab(tester, 'giving');

      // Placeholder text renders
      expect(
        find.textContaining('is coming to Tabletop Club'),
        findsOneWidget,
      );
      // Real Giving keys must NOT appear (rule 2 negative)
      expect(
        find.byKey(const ValueKey('giving-tab-surface')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('giving-amount-summary')),
        findsNothing,
      );
    });

    // (c) Checkout → complete workflow → receipt state
    testWidgets('wf_giving-checkout-to-receipt', (tester) async {
      final fixture = _writeTabletopClubPackagePair();
      await tester.pumpWidget(const LoomCommunitiesDemoApp());
      await _installAndOpen(tester, fixture);

      await _tapTab(tester, 'giving');

      // Verify unpaid state: checkout button exists, no receipt
      expect(
        find.byKey(const ValueKey('giving-checkout-tabletop-club-dues-payment')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('giving-receipt-tabletop-club-dues-payment')),
        findsNothing,
      );

      // Tap checkout → opens action surface (scroll into view first; the
      // button can sit below the fold on the default test viewport)
      final checkoutButton = find.byKey(
        const ValueKey('giving-checkout-tabletop-club-dues-payment'),
      );
      await tester.ensureVisible(checkoutButton);
      await tester.tap(checkoutButton);
      await tester.pumpAndSettle();

      // Confirm the workflow
      final submitFinder = find.byKey(
        const ValueKey('workflow-action-submit-tabletop-club-dues-payment'),
      );
      if (submitFinder.evaluate().isNotEmpty) {
        await tester.tap(submitFinder);
        await tester.pumpAndSettle();
      }

      // After confirming, re-navigate to giving tab (the app may have
      // switched to Home after the workflow). Re-open community if needed.
      await _navigateToTab(tester, 'giving');
      await tester.pumpAndSettle();

      // Receipt should now be visible
      expect(
        find.byKey(const ValueKey('giving-receipt-tabletop-club-dues-payment')),
        findsOneWidget,
      );
      expect(find.textContaining('\$15 — complete'), findsOneWidget);
    });

    // (d) Failure/retry: dismiss checkout without completing → unpaid
    // state persists, checkout is still tappable
    testWidgets('wf_giving-retry-after-dismiss', (tester) async {
      final fixture = _writeTabletopClubPackagePair();
      await tester.pumpWidget(const LoomCommunitiesDemoApp());
      await _installAndOpen(tester, fixture);

      await _tapTab(tester, 'giving');

      // Tap checkout (scroll into view first; the button can sit below the
      // fold on the default test viewport)
      final checkoutButton = find.byKey(
        const ValueKey('giving-checkout-tabletop-club-dues-payment'),
      );
      await tester.ensureVisible(checkoutButton);
      await tester.tap(checkoutButton);
      await tester.pumpAndSettle();

      // Dismiss without confirming — the action surface's leading button is
      // a plain close (X) IconButton, not a tooltip'd/Cupertino back button.
      await tester.tap(find.byIcon(Icons.close).first);
      await tester.pumpAndSettle();

      // Re-navigate to giving tab
      await _navigateToTab(tester, 'giving');
      await tester.pumpAndSettle();

      // Checkout is still present, no receipt
      expect(
        find.byKey(const ValueKey('giving-checkout-tabletop-club-dues-payment')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('giving-receipt-tabletop-club-dues-payment')),
        findsNothing,
      );
      // Amount and purpose are still visible (exact match so this doesn't
      // also match the checkout button's "Pay $15" label).
      expect(find.text('\$15'), findsOneWidget);
      expect(
        find.textContaining('Quarterly club dues'),
        findsOneWidget,
      );
    });

    // (e) Cadence/entitlement conditional: render only when declared;
    // absent otherwise (another rule-2 pair within one test)
    testWidgets('wf_giving-cadence-and-entitlement-conditional', (
      tester,
    ) async {
      // Positive: cadence + entitlement declared → both render
      final fixtureWith = _writeTabletopClubPackagePair(
        includeCadence: true,
        includeEntitlement: true,
      );
      await tester.pumpWidget(const LoomCommunitiesDemoApp());
      await _installAndOpen(tester, fixtureWith);
      await _tapTab(tester, 'giving');

      expect(find.textContaining('recurring'), findsOneWidget);
      expect(
        find.textContaining('Voting member badge'),
        findsOneWidget,
      );

      // Restart with a bare fixture (no cadence, no entitlement)
      await tester.pumpWidget(const MaterialApp(home: SizedBox()));
      await tester.pumpAndSettle();

      final fixtureBare = _writeTabletopClubPackagePair(
        includeCadence: false,
        includeEntitlement: false,
      );
      await tester.pumpWidget(const LoomCommunitiesDemoApp());
      await _installAndOpen(tester, fixtureBare);
      await _tapTab(tester, 'giving');

      // Cadence + entitlement must NOT appear
      expect(find.textContaining('recurring'), findsNothing);
      expect(find.textContaining('Voting member badge'), findsNothing);
    });
  });
}

Future<void> _tapTab(WidgetTester tester, String tabId) async {
  final tabFinder = find.byKey(ValueKey('community-tab-$tabId'));
  final tabRail = find.byKey(const ValueKey('community-bottom-tabs'));
  for (
    var attempt = 0;
    attempt < 8 && tabFinder.evaluate().isEmpty;
    attempt += 1
  ) {
    await tester.drag(tabRail, const Offset(-220, 0), warnIfMissed: false);
    await tester.pumpAndSettle();
  }
  expect(tabFinder, findsOneWidget, reason: tabId);
  await tester.tap(tabFinder, warnIfMissed: false);
  await tester.pumpAndSettle();
}

Future<void> _navigateToTab(WidgetTester tester, String tabId) async {
  // Try tapping the tab directly; if the community isn't open, re-open it.
  final tabFinder = find.byKey(ValueKey('community-tab-$tabId'));
  if (tabFinder.evaluate().isNotEmpty) {
    await _tapTab(tester, tabId);
    return;
  }
  // Re-open the community
  final communityCard = find.byKey(
    const ValueKey('community-card-community_verify_tabletop_club'),
  );
  if (communityCard.evaluate().isNotEmpty) {
    await tester.tap(communityCard);
    await tester.pumpAndSettle();
  }
  await _tapTab(tester, tabId);
}

class _PackagePairFixture {
  const _PackagePairFixture({
    required this.extensionPath,
    required this.initializationPath,
  });

  final String extensionPath;
  final String initializationPath;
}

Future<void> _installAndOpen(
  WidgetTester tester,
  _PackagePairFixture fixture,
) async {
  await tester.tap(find.byKey(const ValueKey('add-community-button')));
  await tester.pumpAndSettle();
  await tester.enterText(
    find.byKey(const ValueKey('extension-package-path-field')),
    fixture.extensionPath,
  );
  await tester.enterText(
    find.byKey(const ValueKey('initialization-package-path-field')),
    fixture.initializationPath,
  );
  await tester.tap(find.byKey(const ValueKey('load-local-community-button')));
  await tester.pumpAndSettle();
  await tester.tap(
    find.byKey(
      const ValueKey('community-card-community_verify_tabletop_club'),
    ),
  );
  await tester.pumpAndSettle();
}

_PackagePairFixture _writeTabletopClubPackagePair({
  bool includeGivingPayment = true,
  bool includeCadence = true,
  bool includeEntitlement = true,
}) {
  final tempDir = Directory.systemTemp.createTempSync('loom_b35_tabletop_');
  final extensionFile = File(
    '${tempDir.path}/$_extensionId.loom-extension.zip',
  );
  final initializationFile = File(
    '${tempDir.path}/$_extensionId.loom-init.zip',
  );
  extensionFile.writeAsStringSync(
    jsonEncode({
      'schemaVersion': 1,
      'mode': 'local-demo',
      'extensionId': _extensionId,
      'displayName': 'Tabletop Club',
      'version': '1.0.0',
      'permissions': ['content.publish', 'events.write', 'forms.write'],
    }),
  );
  final workflows = <Map<String, dynamic>>[
    {
      'workflowId': 'tabletop-game-night-rsvp',
      'title': 'RSVP to Friday game night',
      'entryText':
          'Friday game night at the community room, 7-10pm. 12 of 20 seats filled.',
      'actionText': "Reserve a seat at Friday's game night.",
      'resultText': "You're on the roster for Friday's game night.",
      'calendar': {
        'date': '2026-07-10',
        'time': '19:00',
        'location': 'Community room',
        'capacityLabel': '12 of 20 seats filled',
      },
    },
  ];
  // The dues workflow itself is always declared (so the Giving tab still
  // appears in the bar per the "empty tabs get a placeholder" guardrail —
  // `_sectionTitleFor` maps this workflowId to the 'Giving' section
  // regardless of `givingPayment`); only the `givingPayment` field is
  // conditional, since that's what gates real UI vs. placeholder.
  final duesWorkflow = <String, dynamic>{
    'workflowId': 'tabletop-club-dues-payment',
    'title': 'Quarterly club dues',
    'entryText': 'Quarterly club dues are due. \$15 covering venue, snacks, and game purchases.',
    'actionText': 'Pay quarterly club dues of \$15.',
    'resultText': 'Thank you for paying your quarterly club dues! Your membership is current.',
  };
  if (includeGivingPayment) {
    final givingPayment = <String, dynamic>{
      'amountLabel': '\$15',
      'purpose': 'Quarterly club dues',
    };
    if (includeCadence) {
      givingPayment['cadence'] = 'recurring';
    }
    if (includeEntitlement) {
      givingPayment['entitlement'] = 'Voting member badge';
    }
    duesWorkflow['givingPayment'] = givingPayment;
  }
  workflows.add(duesWorkflow);
  final personaPolicies = <String, dynamic>{
    'tabletop-game-night-rsvp': {
      'actorPersonaIds': ['tabletop-member'],
      'receiverPersonaIds': ['tabletop-organizer'],
      'receiverEntryText': "A member RSVP'd to Friday's game night.",
      'receiverActionText': 'Acknowledge RSVP',
      'receiverResultText': 'RSVP acknowledged and added to the roster.',
    },
    'tabletop-club-dues-payment': {
      'actorPersonaIds': ['tabletop-member', 'tabletop-organizer'],
      'receiverPersonaIds': ['tabletop-organizer'],
      'receiverEntryText': 'A member has paid their quarterly dues.',
      'receiverActionText': 'Confirm payment receipt',
      'receiverResultText': 'Payment confirmed and membership updated.',
    },
  };
  initializationFile.writeAsStringSync(
    jsonEncode({
      'schemaVersion': 1,
      'communityId': 'community_verify_tabletop_club',
      'communityName': 'Tabletop Club',
      'extensionId': _extensionId,
      'seedDataFiles': ['seed/community.json'],
      'branding': {'accentColor': '#C4703F'},
      'experience': {
        'displayName': 'Tabletop Club',
        'tagline':
            'Board game nights, loaner games, and dues for local tabletop fans.',
        'accentColor': '#C4703F',
        'personas': [
          {
            'personaId': 'tabletop-member',
            'label': 'Member',
            'roleLabel': 'Member',
            'description': 'RSVPs to game nights, borrows games, and pays dues.',
          },
          {
            'personaId': 'tabletop-organizer',
            'label': 'Organizer',
            'roleLabel': 'Organizer',
            'description':
                'Plans game nights, manages the game library, and collects dues.',
          },
        ],
        'workflows': workflows,
        'personaPolicies': personaPolicies,
      },
    }),
  );
  return _PackagePairFixture(
    extensionPath: extensionFile.path,
    initializationPath: initializationFile.path,
  );
}