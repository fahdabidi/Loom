import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loom_communities_demo/main.dart';

import 'workflow_ui_test_harness.dart';

const _extensionId = 'ext_verify_tabletop_giving';
const _paymentId = 'tabletop-club-dues-payment';
const _payerAccountId = 'tabletop-member-jules';
const _peerAccountId = 'tabletop-member-sam';
const _treasurerAccountId = 'tabletop-organizer-treasurer';
var _fixtureSequence = 0;

const _accounts = <LoomAccount>[
  LoomAccount(
    accountId: _payerAccountId,
    displayName: 'Jules Member',
    roleId: 'tabletop-member',
  ),
  LoomAccount(
    accountId: _peerAccountId,
    displayName: 'Sam Member',
    roleId: 'tabletop-member',
  ),
  LoomAccount(
    accountId: _treasurerAccountId,
    displayName: 'Club Treasurer',
    roleId: 'tabletop-organizer',
  ),
];

void main() {
  group('B35 Giving payment tab', () {
    testWidgets('wf_giving-renders-real-when-payment-declared', (tester) async {
      final fixture = _writeTabletopClubPackagePair();
      await tester.pumpWidget(const LoomCommunitiesDemoApp());
      await _installAndSignIn(tester, fixture, 'Jules Member');
      await _openGiving(tester, expectPayment: true);

      expect(
        find.byKey(const ValueKey('engine-native-list-root-giving')),
        findsOneWidget,
      );
      expect(_paymentCard, findsOneWidget);
      expect(find.text(r'$15'), findsWidgets);
      expect(find.text('Quarterly club dues'), findsWidgets);
      expect(find.text('Recipient: Tabletop Club treasury'), findsOneWidget);
      expect(_paymentAction('pay-dues'), findsOneWidget);
      expect(find.textContaining('is coming to Tabletop Club'), findsNothing);

      // `paymentCheckout` is party-scoped by account, not by role.
      await signInEvidenceAccount(tester, 'Sam Member');
      await openEvidenceTarget(tester, fixture.target);
      await tapCommunityTab(tester, 'giving');
      await waitForEngineNativeWidget(
        tester,
        find.byKey(const ValueKey('engine-native-list-empty-giving')),
        description: 'empty Giving tab for a non-party member account',
      );
      expect(_paymentCard, findsNothing);
      expect(
        find.byKey(const ValueKey('engine-native-list-error-giving')),
        findsNothing,
      );
    });

    testWidgets('wf_giving-shows-placeholder-without-payment', (tester) async {
      final fixture = _writeTabletopClubPackagePair(
        includeGivingPayment: false,
      );
      await tester.pumpWidget(const LoomCommunitiesDemoApp());
      await _installAndSignIn(tester, fixture, 'Jules Member');
      await _openGiving(tester, expectPayment: false);

      expect(_paymentCard, findsNothing);
      expect(
        find.byKey(const ValueKey('engine-native-list-empty-giving')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('engine-native-list-error-giving')),
        findsNothing,
      );
    });

    testWidgets('wf_giving-checkout-to-receipt', (tester) async {
      final fixture = _writeTabletopClubPackagePair();
      await tester.pumpWidget(const LoomCommunitiesDemoApp());
      await _installAndSignIn(tester, fixture, 'Jules Member');
      await _openGiving(tester, expectPayment: true);

      expect(_paymentAction('pay-dues'), findsOneWidget);
      expect(find.text('Status: Complete'), findsNothing);

      await _tapVisible(tester, _paymentAction('pay-dues'));
      await waitForEngineNativeWidget(
        tester,
        find.text('Status: Complete'),
        description: 'completed dues receipt status',
      );

      expect(_paymentCard, findsOneWidget);
      expect(find.text('Status: Complete'), findsOneWidget);
      expect(find.textContaining('Paid '), findsOneWidget);
      expect(_paymentAction('pay-dues'), findsNothing);
    });

    testWidgets('wf_giving-retry-after-dismiss', (tester) async {
      final fixture = _writeTabletopClubPackagePair();
      await tester.pumpWidget(const LoomCommunitiesDemoApp());
      await _installAndSignIn(tester, fixture, 'Jules Member');
      await _openGiving(tester, expectPayment: true);

      // The removed shallow checkout dialog had no engine failure state.
      // Retarget the retry intent to the real failed -> due transition cycle.
      await _tapVisible(tester, _paymentAction('record-payment-failure'));
      await waitForEngineNativeWidget(
        tester,
        find.text('Status: Failed'),
        description: 'failed payment state',
      );
      expect(_paymentAction('retry-payment'), findsOneWidget);

      await _tapVisible(tester, _paymentAction('retry-payment'));
      await waitForEngineNativeWidget(
        tester,
        _paymentAction('pay-dues'),
        description: 'pay action after retry',
      );
      expect(find.text('Status: Due'), findsOneWidget);
      expect(_paymentAction('pay-dues'), findsOneWidget);
      expect(find.text(r'$15'), findsWidgets);
      expect(find.text('Quarterly club dues'), findsWidgets);
    });

    testWidgets('wf_giving-cadence-and-entitlement-conditional', (
      tester,
    ) async {
      final fixtureWith = _writeTabletopClubPackagePair(
        includeCadence: true,
        includeEntitlement: true,
      );
      await tester.pumpWidget(const LoomCommunitiesDemoApp());
      await _installAndSignIn(tester, fixtureWith, 'Jules Member');
      await _openGiving(tester, expectPayment: true);

      expect(find.text('Cadence: Recurring'), findsOneWidget);
      expect(find.text('Entitlement: Voting member badge'), findsOneWidget);

      await tester.pumpWidget(const MaterialApp(home: SizedBox()));
      await tester.pumpAndSettle();

      final fixtureBare = _writeTabletopClubPackagePair(
        includeCadence: false,
        includeEntitlement: false,
      );
      await tester.pumpWidget(const LoomCommunitiesDemoApp());
      await _installAndSignIn(tester, fixtureBare, 'Jules Member');
      await _openGiving(tester, expectPayment: true);

      expect(find.textContaining('Cadence:'), findsNothing);
      expect(find.textContaining('Entitlement:'), findsNothing);
      expect(_paymentCard, findsOneWidget);
    });
  });
}

Finder get _paymentCard => find.byKey(
  const ValueKey('generic-instance-card-tabletop-club-dues-payment'),
);

Finder _paymentAction(String transitionId) =>
    find.byKey(ValueKey('generic-instance-$_paymentId-action-$transitionId'));

Future<void> _openGiving(
  WidgetTester tester, {
  required bool expectPayment,
}) async {
  await tapCommunityTab(tester, 'giving');
  await waitForEngineNativeWidget(
    tester,
    expectPayment
        ? _paymentCard
        : find.byKey(const ValueKey('engine-native-list-empty-giving')),
    description: expectPayment
        ? 'engine-native dues payment'
        : 'empty engine-native Giving tab',
  );
}

Future<void> _installAndSignIn(
  WidgetTester tester,
  ({EvidencePackagePair package, String communityId, LoomEvidenceTarget target})
  fixture,
  String displayName,
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
  await seedEvidenceAccounts(tester, fixture.target, _accounts);
  await signInEvidenceAccount(tester, displayName);
}

Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  await waitForEngineNativeWidget(
    tester,
    finder,
    description: 'payment control $finder',
  );
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  expect(finder, findsOneWidget);
  await tester.tap(finder, warnIfMissed: false);
  await tester.pumpAndSettle();
}

Map<String, Object?> _paymentDefinition() => engineNativeTestWorkflowDefinition(
  initialState: 'due',
  visibility: <String, Object?>{
    'default': 'guarded',
    'readGuard': <String, Object?>{
      'actorEqualsField': <String, Object?>{'key': 'payerFanId'},
    },
    'fields': <String, Object?>{
      'parties': <Object?>['payerFanId', 'treasurerFanId'],
    },
  },
  states: <String, Object?>{
    'due': <String, Object?>{'label': 'Payment due'},
    'failed': <String, Object?>{'label': 'Payment failed'},
    'paid': <String, Object?>{'label': 'Paid', 'isTerminal': true},
  },
  transitions: <Map<String, Object?>>[
    <String, Object?>{
      'id': 'pay-dues',
      'label': r'Pay $15',
      'tone': 'primary',
      'from': <String>['due'],
      'to': 'paid',
      'guard': <String, Object?>{
        'allowedRoleIds': <String>['tabletop-member'],
        'actorEqualsField': <String, Object?>{'key': 'payerFanId'},
      },
      'effects': <Object?>[
        <String, Object?>{
          'op': 'set',
          'key': 'receiptStatus',
          'value': 'complete',
        },
        <String, Object?>{'op': 'set', 'key': 'paidAt', 'value': r'$timestamp'},
      ],
    },
    <String, Object?>{
      'id': 'record-payment-failure',
      'label': 'Simulate failure',
      'tone': 'destructive',
      'from': <String>['due'],
      'to': 'failed',
      'guard': <String, Object?>{
        'allowedRoleIds': <String>['tabletop-member'],
        'actorEqualsField': <String, Object?>{'key': 'payerFanId'},
      },
      'effects': <Object?>[
        <String, Object?>{
          'op': 'set',
          'key': 'receiptStatus',
          'value': 'failed',
        },
      ],
    },
    <String, Object?>{
      'id': 'retry-payment',
      'label': 'Retry payment',
      'tone': 'primary',
      'from': <String>['failed'],
      'to': 'due',
      'guard': <String, Object?>{
        'allowedRoleIds': <String>['tabletop-member'],
        'actorEqualsField': <String, Object?>{'key': 'payerFanId'},
      },
      'effects': <Object?>[
        <String, Object?>{'op': 'set', 'key': 'receiptStatus', 'value': 'due'},
      ],
    },
  ],
  renderBindings: <Map<String, Object?>>[
    engineNativeTestRenderBinding(
      states: <String>['due', 'failed', 'paid'],
      tabId: 'giving',
      cardSurfaceFamily: 'paymentCheckout',
    ),
  ],
  instanceDataSchema: <String, Object?>{
    'payerFanId': <String, Object?>{
      'type': 'fanId',
      'required': true,
      'displayContexts': <String>['detail'],
    },
    'treasurerFanId': <String, Object?>{
      'type': 'fanId',
      'required': true,
      'displayContexts': <String>[],
    },
    'amountLabel': <String, Object?>{
      'type': 'text',
      'required': true,
      'labelTemplate': '{value}',
    },
    'purpose': <String, Object?>{
      'type': 'text',
      'required': true,
      'labelTemplate': '{value}',
    },
    'recipient': <String, Object?>{
      'type': 'text',
      'labelTemplate': 'Recipient: {value}',
    },
    'cadence': <String, Object?>{
      'type': 'text',
      'labelTemplate': 'Cadence: {value}',
      'hideWhenEmpty': true,
    },
    'entitlement': <String, Object?>{
      'type': 'text',
      'labelTemplate': 'Entitlement: {value}',
      'hideWhenEmpty': true,
    },
    'receiptStatus': <String, Object?>{
      'type': 'text',
      'writableBy': 'effect',
      'labelTemplate': 'Status: {value}',
    },
    'paidAt': <String, Object?>{
      'type': 'date?',
      'writableBy': 'effect',
      'labelTemplate': 'Paid {value}',
      'hideWhenEmpty': true,
    },
  },
);

Map<String, Object?> _sentinelDefinition() =>
    engineNativeTestWorkflowDefinition(
      initialState: 'active',
      states: <String, Object?>{
        'active': <String, Object?>{'label': 'Active'},
      },
      transitions: <Map<String, Object?>>[
        <String, Object?>{
          'id': 'retain-fixture',
          'label': 'Retain fixture',
          'from': <String>['active'],
          'to': null,
        },
      ],
      renderBindings: <Map<String, Object?>>[
        engineNativeTestRenderBinding(
          states: <String>['active'],
          tabId: 'home',
          cardSurfaceFamily: 'statusTimeline',
        ),
      ],
      instanceDataSchema: <String, Object?>{
        'title': <String, Object?>{'type': 'text'},
      },
    );

({EvidencePackagePair package, String communityId, LoomEvidenceTarget target})
_writeTabletopClubPackagePair({
  bool includeGivingPayment = true,
  bool includeCadence = true,
  bool includeEntitlement = true,
}) {
  final sequence = _fixtureSequence++;
  final extensionId = '${_extensionId}_$sequence';
  final communityId = 'community_verify_tabletop_giving_$sequence';
  final workflowDefinitions = <String, Object?>{
    if (includeGivingPayment) _paymentId: _paymentDefinition(),
    if (!includeGivingPayment) 'fixture-sentinel': _sentinelDefinition(),
  };
  final workflowInstances = <Object?>[
    if (includeGivingPayment)
      engineNativeTestWorkflowInstance(
        instanceId: _paymentId,
        workflowType: _paymentId,
        currentState: 'due',
        createdByFanId: _payerAccountId,
        instanceData: <String, Object?>{
          'payerFanId': _payerAccountId,
          'treasurerFanId': _treasurerAccountId,
          'amountLabel': r'$15',
          'purpose': 'Quarterly club dues',
          'recipient': 'Tabletop Club treasury',
          if (includeCadence) 'cadence': 'recurring',
          if (includeEntitlement) 'entitlement': 'Voting member badge',
          'receiptStatus': 'due',
          'paidAt': null,
        },
      )
    else
      engineNativeTestWorkflowInstance(
        instanceId: 'fixture-sentinel',
        workflowType: 'fixture-sentinel',
        currentState: 'active',
        createdByFanId: _payerAccountId,
        instanceData: <String, Object?>{'title': 'Fixture sentinel'},
      ),
  ];

  final package = writeEngineNativeTestPackagePair(
    tempDirectoryPrefix: 'loom_b35_tabletop_',
    extensionId: extensionId,
    communityId: communityId,
    displayName: 'Tabletop Club',
    permissions: const <String>['payments.write'],
    experience: <String, Object?>{
      'displayName': 'Tabletop Club',
      'tagline': 'Board game nights and account-scoped member dues.',
      'accentColor': '#C4703F',
      'theme': <String, Object?>{'accent': '#C4703F'},
      'roles': const <Object?>[
        <String, Object?>{
          'roleId': 'tabletop-member',
          'label': 'Member',
          'roleLabel': 'Member',
          'description': 'Pays club dues.',
        },
        <String, Object?>{
          'roleId': 'tabletop-organizer',
          'label': 'Organizer',
          'roleLabel': 'Organizer',
          'description': 'Collects club dues.',
        },
      ],
      'workflowDefinitions': workflowDefinitions,
      'workflowInstances': workflowInstances,
    },
    appShell: <String, Object?>{
      'tabs': <Object?>[
        <String, Object?>{
          'tabId': 'giving',
          'label': 'Giving',
          'iconKey': 'payment',
          'visibleRoleIds': <String>['tabletop-member', 'tabletop-organizer'],
        },
      ],
    },
  );
  return (
    package: package,
    communityId: communityId,
    target: LoomEvidenceTarget(
      phase: 'test',
      communityId: communityId,
      communityName: 'Tabletop Club',
      handle: 'tabletop-giving-$sequence',
      extensionId: extensionId,
      accentColor: '#C4703F',
      seedDataFiles: const <String>[
        'seed/community.json',
        'seed/workflows.json',
      ],
    ),
  );
}
