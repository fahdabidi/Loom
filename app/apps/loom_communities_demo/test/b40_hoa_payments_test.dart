import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loom_communities_demo/main.dart';

import 'workflow_ui_test_harness.dart';

const _paymentId = 'hoa-dues-payment';
const _payerAccountId = 'hoa-homeowner-avery';
const _peerAccountId = 'hoa-homeowner-casey';
const _boardAccountId = 'hoa-board-reviewer';
const _boardPeerAccountId = 'hoa-board-reviewer-alternate';
var _fixtureSequence = 0;

const _accounts = <LoomAccount>[
  LoomAccount(
    accountId: _payerAccountId,
    displayName: 'Avery Brooks',
    personaTypeId: 'hoa-homeowner',
  ),
  LoomAccount(
    accountId: _peerAccountId,
    displayName: 'Casey Homeowner',
    personaTypeId: 'hoa-homeowner',
  ),
  LoomAccount(
    accountId: _boardAccountId,
    displayName: 'Board Reviewer',
    personaTypeId: 'hoa-board',
  ),
  LoomAccount(
    accountId: _boardPeerAccountId,
    displayName: 'Alternate Board Reviewer',
    personaTypeId: 'hoa-board',
  ),
];

void main() {
  group('M4.3 HOA payments', () {
    testWidgets('homeowner pays dues and sees receipt history', (tester) async {
      final fixture = _writeFixture();
      await tester.pumpWidget(const LoomCommunitiesDemoApp());
      await _installAndSignIn(tester, fixture, 'Avery Brooks');
      await _openPayments(tester, expectPayment: true);

      expect(find.text('Payments'), findsWidgets);
      expect(_paymentCard, findsOneWidget);
      expect(find.text(r'$450'), findsWidgets);
      expect(find.text('Annual HOA dues'), findsWidgets);
      expect(find.text('Recipient: Cedar Commons HOA'), findsOneWidget);
      expect(find.text('Payer: Avery Brooks'), findsOneWidget);
      expect(find.text('Cadence: Annual dues due July 31'), findsOneWidget);
      expect(find.text('Entitlement: Member in good standing'), findsOneWidget);
      expect(_paymentAction('pay-dues'), findsOneWidget);
      expect(find.text('Status: Complete'), findsNothing);

      await _tapVisible(tester, _paymentAction('pay-dues'));
      await waitForEngineNativeWidget(
        tester,
        find.text('Status: Complete'),
        description: 'completed HOA dues payment',
      );

      expect(_paymentCard, findsOneWidget);
      expect(find.text(r'$450'), findsWidgets);
      expect(find.text('Status: Complete'), findsOneWidget);
      expect(find.text('Payment history'), findsOneWidget);
      expect(find.text('Payment completed'), findsOneWidget);
      expect(find.textContaining('2026-'), findsWidgets);
      expect(_paymentAction('pay-dues'), findsNothing);
    });

    testWidgets('board sees read-only dues ledger, not checkout action', (
      tester,
    ) async {
      final fixture = _writeFixture();
      await tester.pumpWidget(const LoomCommunitiesDemoApp());
      await _installAndSignIn(tester, fixture, 'Board Reviewer');
      await _openPayments(tester, expectPayment: true);

      expect(find.text('Payments'), findsWidgets);
      expect(_paymentCard, findsOneWidget);
      expect(find.text(r'$450'), findsWidgets);
      expect(find.text('Annual HOA dues'), findsWidgets);
      expect(_paymentAction('pay-dues'), findsNothing);

      // This specific board account is the declared counterparty; the role
      // alone must not admit another board account to the private ledger.
      await signInEvidenceAccount(tester, 'Alternate Board Reviewer');
      await openEvidenceTarget(tester, fixture.target);
      await _openPayments(tester, expectPayment: false);
      expect(_paymentCard, findsNothing);

      // The payer direction is individual too: another homeowner with the
      // payer's role is not a transaction party either.
      await signInEvidenceAccount(tester, 'Casey Homeowner');
      await openEvidenceTarget(tester, fixture.target);
      await _openPayments(tester, expectPayment: false);
      expect(_paymentCard, findsNothing);
      expect(
        find.byKey(const ValueKey('engine-native-list-error-giving')),
        findsNothing,
      );
    });
  });
}

Finder get _paymentCard =>
    find.byKey(const ValueKey('generic-instance-card-hoa-dues-payment'));

Finder _paymentAction(String transitionId) =>
    find.byKey(ValueKey('generic-instance-$_paymentId-action-$transitionId'));

Future<void> _openPayments(
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
        ? 'HOA payment card'
        : 'empty party-filtered HOA payments surface',
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
    description: 'HOA payment control $finder',
  );
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  expect(finder, findsOneWidget);
  await tester.tap(finder, warnIfMissed: false);
  await tester.pumpAndSettle();
}

({EvidencePackagePair package, String communityId, LoomEvidenceTarget target})
_writeFixture() {
  final sequence = _fixtureSequence++;
  final extensionId = 'ext_verify_hoa_payments_$sequence';
  final communityId = 'community_verify_hoa_payments_$sequence';
  final definition = engineNativeTestWorkflowDefinition(
    initialState: 'due',
    visibility: <String, Object?>{
      'default': 'guarded',
      'readGuard': <String, Object?>{
        'actorEqualsField': <String, Object?>{'key': 'payerFanId'},
      },
      'fields': <String, Object?>{
        'parties': <String>['payerFanId', 'boardReviewerFanId'],
      },
    },
    states: <String, Object?>{
      'due': <String, Object?>{'label': 'Dues due'},
      'paid': <String, Object?>{'label': 'Paid', 'isTerminal': true},
    },
    transitions: <Map<String, Object?>>[
      <String, Object?>{
        'id': 'pay-dues',
        'label': r'Pay $450',
        'tone': 'primary',
        'from': <String>['due'],
        'to': 'paid',
        'guard': <String, Object?>{
          'actorEqualsField': <String, Object?>{'key': 'payerFanId'},
        },
        'effects': <Object?>[
          <String, Object?>{
            'op': 'set',
            'key': 'receiptStatus',
            'value': 'complete',
          },
          <String, Object?>{
            'op': 'set',
            'key': 'paidAt',
            'value': r'$timestamp',
          },
          <String, Object?>{
            'op': 'append',
            'key': 'history',
            'value': <String, Object?>{
              'senderFanId': r'$actor',
              'body': 'Payment completed',
              'timestamp': r'$timestamp',
            },
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
      'payerFanId': <String, Object?>{
        'type': 'fanId',
        'required': true,
        'displayContexts': <String>['detail'],
      },
      'boardReviewerFanId': <String, Object?>{
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
      'payerLabel': <String, Object?>{
        'type': 'text',
        'labelTemplate': 'Payer: {value}',
      },
      'cadence': <String, Object?>{
        'type': 'text',
        'labelTemplate': 'Cadence: {value}',
      },
      'entitlement': <String, Object?>{
        'type': 'text',
        'labelTemplate': 'Entitlement: {value}',
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
      'history': <String, Object?>{
        'type': 'list',
        'writableBy': 'effect',
        'labelTemplate': 'Payment history',
        'hideWhenEmpty': true,
        'displayContexts': <String>['detail'],
      },
    },
  );

  final package = writeEngineNativeTestPackagePair(
    tempDirectoryPrefix: 'loom_b40_hoa_payments_',
    extensionId: extensionId,
    communityId: communityId,
    displayName: 'Cedar Commons HOA',
    permissions: const <String>['payments.read', 'payments.write'],
    experience: <String, Object?>{
      'displayName': 'Cedar Commons HOA',
      'tagline': 'Account-scoped dues, documents, and board review.',
      'accentColor': '#3E6B8F',
      'theme': <String, Object?>{'accent': '#3E6B8F'},
      'roles': const <Object?>[
        <String, Object?>{
          'roleId': 'hoa-homeowner',
          'label': 'Homeowner',
          'roleLabel': 'Homeowner',
          'description': 'Pays dues and reads their payment history.',
        },
        <String, Object?>{
          'roleId': 'hoa-board',
          'label': 'HOA Board',
          'roleLabel': 'Board',
          'description': 'Reviews payment ledger entries.',
        },
      ],
      'workflowDefinitions': <String, Object?>{_paymentId: definition},
      'workflowInstances': <Object?>[
        engineNativeTestWorkflowInstance(
          instanceId: _paymentId,
          workflowType: _paymentId,
          currentState: 'due',
          createdByFanId: _payerAccountId,
          instanceData: <String, Object?>{
            'payerFanId': _payerAccountId,
            'boardReviewerFanId': _boardAccountId,
            'amountLabel': r'$450',
            'purpose': 'Annual HOA dues',
            'recipient': 'Cedar Commons HOA',
            'payerLabel': 'Avery Brooks',
            'cadence': 'Annual dues due July 31',
            'entitlement': 'Member in good standing',
            'receiptStatus': 'due',
            'paidAt': null,
            'history': <Object?>[],
          },
        ),
      ],
    },
    appShell: <String, Object?>{
      'tabs': <Object?>[
        <String, Object?>{
          'tabId': 'giving',
          'label': 'Payments',
          'iconKey': 'payment',
          'visibleRoleIds': <String>['hoa-homeowner', 'hoa-board'],
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
      communityName: 'Cedar Commons HOA',
      handle: 'hoa-payments-$sequence',
      extensionId: extensionId,
      accentColor: '#3E6B8F',
      seedDataFiles: const <String>[
        'seed/community.json',
        'seed/workflows.json',
      ],
    ),
  );
}
