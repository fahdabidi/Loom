import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loom_communities_demo/main.dart';

import 'workflow_ui_test_harness.dart';

const _extensionId = 'ext_verify_marketplace_dues_gate';
var _fixtureSequence = 0;

void main() {
  group('M3.2 Marketplace dues-current gate', () {
    testWidgets('dues-not-current guard hides borrow on rendered listing', (
      tester,
    ) async {
      final fixture = _writeFixture();
      await tester.pumpWidget(const LoomCommunitiesDemoApp());
      await _installAndOpen(tester, fixture);
      await selectPersona(tester, 'tabletop-member');
      await _tapTab(tester, 'marketplace');
      await _openListingDetail(tester, 'listing-root');

      expect(
        find.byKey(const ValueKey('engine-native-marketplace-root')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('marketplace-detail-dialog-listing-root')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('marketplace-transition-fab-borrow')),
        findsNothing,
      );
      expect(find.text('Request loan'), findsNothing);
      expect(find.text('Waiting'), findsNothing);
    });

    testWidgets('paying dues makes guarded Marketplace borrow available', (
      tester,
    ) async {
      final fixture = _writeFixture();
      await tester.pumpWidget(const LoomCommunitiesDemoApp());
      await _installAndOpen(tester, fixture);
      await selectPersona(tester, 'tabletop-member');
      await _tapTab(tester, 'giving');

      final pay = find.byKey(
        const ValueKey(
          'generic-instance-tabletop-club-dues-payment-action-pay-dues',
        ),
      );
      await waitForEngineNativeWidget(
        tester,
        pay,
        description: 'engine-native dues payment transition',
      );
      await tester.ensureVisible(pay);
      await tester.tap(pay);
      await tester.pumpAndSettle();
      await waitForEngineNativeWidget(
        tester,
        find.text('Payment status: Paid'),
        description: 'persisted paid dues state',
      );

      await _tapTab(tester, 'marketplace');
      await _openListingDetail(tester, 'listing-root');

      expect(
        find.byKey(const ValueKey('engine-native-marketplace-root')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('marketplace-transition-fab-borrow')),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(
            const ValueKey('marketplace-detail-dialog-listing-root'),
          ),
          matching: find.text('Request loan'),
        ),
        findsOneWidget,
      );
      expect(find.text('Waiting'), findsNothing);
    });
  });
}

Future<void> _installAndOpen(
  WidgetTester tester,
  ({EvidencePackagePair package, String communityId}) fixture,
) async {
  await tester.tap(find.byKey(const ValueKey('add-community-button')));
  await tester.pumpAndSettle();
  await tester.enterText(
    find.byKey(const ValueKey('extension-package-path-field')),
    fixture.package.extensionPath,
  );
  await tester.enterText(
    find.byKey(const ValueKey('initialization-package-path-field')),
    fixture.package.initializationPath,
  );
  await tester.tap(find.byKey(const ValueKey('load-local-community-button')));
  await tester.pumpAndSettle();
  await tester.tap(
    find.byKey(ValueKey('community-card-${fixture.communityId}')),
  );
  await tester.pumpAndSettle();
}

Future<void> _tapTab(WidgetTester tester, String tabId) async {
  await tapCommunityTab(tester, tabId);
  if (tabId == 'marketplace') {
    await waitForEngineNativeMarketplaceSurface(tester);
  } else {
    await waitForEngineNativeWidget(
      tester,
      find.byKey(ValueKey('engine-native-list-root-$tabId')),
      description: 'engine-native $tabId list surface',
    );
  }
}

Future<void> _openListingDetail(WidgetTester tester, String listingId) async {
  final card = find.byKey(ValueKey('marketplace-listing-$listingId'));
  await waitForEngineNativeWidget(
    tester,
    card,
    description: 'Marketplace listing $listingId',
  );
  expect(card, findsOneWidget);
  final tapTarget = find.byKey(ValueKey('marketplace-listing-tap-$listingId'));
  await tester.ensureVisible(tapTarget);
  final tapRect = tester.getRect(tapTarget);
  await tester.tapAt(Offset(tapRect.center.dx, tapRect.top + 20));
  await tester.pumpAndSettle();
  await waitForEngineNativeWidget(
    tester,
    find.byKey(ValueKey('marketplace-detail-dialog-$listingId')),
    description: 'Marketplace detail for $listingId',
  );
}

({EvidencePackagePair package, String communityId}) _writeFixture() {
  final sequence = _fixtureSequence++;
  final extensionId = '${_extensionId}_$sequence';
  final communityId = 'community_verify_marketplace_dues_gate_$sequence';
  final marketplace = engineNativeMarketplaceTestFixture(
    loanWorkflowType: 'tabletop-game-loan',
    memberRoleId: 'tabletop-member',
    organizerRoleId: 'tabletop-organizer',
    organizerFanId: 'tabletop-organizer-01',
    borrowRequiresWorkflowsComplete: const <String>[
      'tabletop-club-dues-payment',
    ],
    loanSeeds: const <EngineNativeMarketplaceLoanSeed>[
      EngineNativeMarketplaceLoanSeed(
        instanceId: 'listing-root',
        title: 'Root',
        category: 'Strategy Games',
        condition: 'Good',
        description: 'Borrow Root from the club library.',
      ),
    ],
  );

  final duesDefinition = engineNativeTestWorkflowDefinition(
    initialState: 'due',
    states: <String, Object?>{
      'due': <String, Object?>{'label': 'Payment due'},
      'paid': <String, Object?>{'label': 'Paid', 'isTerminal': true},
    },
    transitions: <Map<String, Object?>>[
      <String, Object?>{
        'id': 'pay-dues',
        'label': 'Pay quarterly dues',
        'from': <String>['due'],
        'to': 'paid',
        'guard': <String, Object?>{
          'allowedRoleIds': <String>['tabletop-member'],
        },
        'effects': <Object?>[
          <String, Object?>{
            'op': 'set',
            'key': 'receiptStatus',
            'value': 'paid',
          },
        ],
      },
    ],
    renderBindings: <Map<String, Object?>>[
      engineNativeTestRenderBinding(
        states: <String>['due', 'paid'],
        tabId: 'giving',
        cardSurfaceFamily: 'paymentCheckout',
      ),
    ],
    instanceDataSchema: <String, Object?>{
      'title': <String, Object?>{
        'type': 'text',
        'required': true,
        'storage': 'inline',
        'labelTemplate': '{value}',
      },
      'amount': <String, Object?>{
        'type': 'number',
        'required': true,
        'storage': 'inline',
        'labelTemplate': 'Amount: \${value}',
      },
      'receiptStatus': <String, Object?>{
        'type': 'text',
        'storage': 'inline',
        'labelTemplate': 'Payment status: {value}',
      },
    },
  );

  final package = writeEngineNativeTestPackagePair(
    tempDirectoryPrefix: 'loom_b37_dues_gate_',
    extensionId: extensionId,
    communityId: communityId,
    displayName: 'Tabletop Club',
    permissions: const <String>['content.publish', 'payments.write'],
    experience: <String, Object?>{
      'displayName': 'Tabletop Club',
      'tagline': 'Board game library and member dues.',
      'accentColor': '#C4703F',
      'theme': <String, Object?>{'accent': '#C4703F'},
      'roles': const <Object?>[
        <String, Object?>{
          'roleId': 'tabletop-member',
          'label': 'Member',
          'roleLabel': 'Member',
          'description': 'Borrows games and pays dues.',
        },
        <String, Object?>{
          'roleId': 'tabletop-organizer',
          'label': 'Organizer',
          'roleLabel': 'Organizer',
          'description': 'Runs the club.',
        },
      ],
      'workflowDefinitions': <String, Object?>{
        ...marketplace.workflowDefinitions,
        'tabletop-club-dues-payment': duesDefinition,
      },
      'workflowInstances': <Object?>[
        ...marketplace.workflowInstances,
        engineNativeTestWorkflowInstance(
          instanceId: 'tabletop-club-dues-payment',
          workflowType: 'tabletop-club-dues-payment',
          currentState: 'due',
          // LocalAuthApi's first open-signup account uses this deterministic
          // id; completion lookup is intentionally per individual account.
          createdByFanId: 'tabletop-member-20',
          instanceData: <String, Object?>{
            'title': 'Quarterly club dues',
            'amount': 15,
            'receiptStatus': 'due',
          },
        ),
      ],
    },
    appShell: <String, Object?>{
      'tabs': <Object?>[
        engineNativeMarketplaceTestTab(),
        <String, Object?>{
          'tabId': 'giving',
          'label': 'Giving',
          'iconKey': 'payment',
        },
      ],
    },
  );
  return (package: package, communityId: communityId);
}
