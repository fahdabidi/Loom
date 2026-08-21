import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loom_communities_demo/main.dart';

import 'workflow_ui_test_harness.dart';

const _extensionId = 'ext_verify_tabletop_club';

void main() {
  group('B30 cascading card theme', () {
    testWidgets('wf_home-tab-shows-all-three-workflows', (tester) async {
      final fixture = _writeCascadeFixture('home');
      await tester.pumpWidget(const LoomCommunitiesDemoApp());
      await _installAndOpen(tester, fixture);

      expect(
        find.byKey(const ValueKey('engine-native-list-root-home')),
        findsOneWidget,
      );
      for (final id in [
        'tabletop-committee-decision',
        'tabletop-club-dues-payment',
        'tabletop-game-loan',
      ]) {
        expect(
          find.byKey(ValueKey('generic-instance-card-$id')),
          findsOneWidget,
          reason: id,
        );
      }
    });

    testWidgets('wf_marketplace-tab-renders-cascaded-theme-fill', (
      tester,
    ) async {
      final fixture = _writeCascadeFixture('marketplace');
      await tester.pumpWidget(const LoomCommunitiesDemoApp());
      await _installAndOpen(tester, fixture);

      await tapCommunityTab(tester, 'marketplace');

      // Positive: an equipment-loan seed and binding render through the
      // engine-native marketplace, while the placeholder remains absent.
      final listingCardFinder = find.byKey(
        const ValueKey('marketplace-listing-tabletop-game-loan'),
      );
      expect(listingCardFinder, findsOneWidget);
      expect(
        find.byKey(const ValueKey('engine-native-marketplace-root')),
        findsOneWidget,
      );
      expect(find.textContaining('is coming to'), findsNothing);

      // The engine-native equipment-loan contract keeps its outer Card on
      // Material's neutral surface and applies the resolved tab theme to its
      // actionable chrome. The borrow action therefore proves the current v4
      // cascade was consumed (community #C4703F → tab override #2F6F5C).
      final borrowFinder = find.byKey(
        const ValueKey('equipment-loan-action-borrow-tabletop-game-loan'),
      );
      expect(borrowFinder, findsOneWidget);
      final borrow = tester.widget<FilledButton>(borrowFinder);
      expect(
        borrow.style?.backgroundColor?.resolve(const <WidgetState>{}),
        const Color(0xff2F6F5C),
      );
    });

    test('theme-and-binding-owned-tab-overrides-parse-from-v4-fixture', () {
      // V4 definitions have no per-workflow theme block. Their render binding
      // names the tab whose declared override participates in the cascade.
      final fixture = _writeCascadeFixture('parse');
      final json =
          jsonDecode(
                File(fixture.package.initializationPath).readAsStringSync(),
              )
              as Map<String, dynamic>;
      final exp = json['experience'] as Map<String, dynamic>;
      final theme = exp['theme'] as Map<String, dynamic>;

      expect(theme['accent'], '#C4703F');
      final tabThemes = theme['tabThemes'] as Map<String, dynamic>;
      expect(tabThemes['giving'], {'accent': '#8A5A34'});
      expect(tabThemes['marketplace'], {'accent': '#2F6F5C'});

      final definitions = exp['workflowDefinitions'] as Map<String, dynamic>;
      final gameLoan =
          definitions['tabletop-game-loan'] as Map<String, dynamic>;
      final loanBindings = gameLoan['renderBindings'] as List<dynamic>;
      expect(loanBindings, contains(containsPair('tabId', 'marketplace')));
      expect(gameLoan.containsKey('theme'), isFalse);

      final duesPayment =
          definitions['tabletop-club-dues-payment'] as Map<String, dynamic>;
      final duesBindings = duesPayment['renderBindings'] as List<dynamic>;
      expect(duesBindings, contains(containsPair('tabId', 'giving')));
      expect(duesPayment.containsKey('theme'), isFalse);
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
  // Marketplace and Giving are member-action tabs in this fixture. Enter as
  // that role so the shell's permission-derived tab visibility is exercised.
  await selectPersona(tester, 'tabletop-member');
  await waitForEngineNativeWidget(
    tester,
    find.byKey(const ValueKey('engine-native-list-root-home')),
    description: 'Tabletop Club engine-native Home surface',
  );
}

({EvidencePackagePair package, String communityId}) _writeCascadeFixture(
  String suffix,
) {
  final extensionId = '${_extensionId}_$suffix';
  final communityId = 'community_verify_tabletop_club_$suffix';
  Map<String, Object?> homeBinding(List<String> states) =>
      engineNativeTestRenderBinding(
        states: states,
        tabId: 'home',
        cardSurfaceFamily: 'statusTimeline',
        bindingKind: 'summary',
      );

  final committeeDecision = engineNativeTestWorkflowDefinition(
    initialState: 'pending',
    states: <String, Object?>{
      'pending': <String, Object?>{'label': 'Awaiting decision'},
      'approved': <String, Object?>{'label': 'Approved', 'isTerminal': true},
    },
    transitions: <Map<String, Object?>>[
      <String, Object?>{
        'id': 'approve',
        'label': 'Approve purchase',
        'from': <String>['pending'],
        'to': 'approved',
        'guard': <String, Object?>{
          'allowedRoleIds': <String>['tabletop-organizer'],
        },
      },
    ],
    renderBindings: <Map<String, Object?>>[
      homeBinding(<String>['pending', 'approved']),
    ],
    instanceDataSchema: <String, Object?>{
      'title': <String, Object?>{
        'type': 'text',
        'storage': 'inline',
        'labelTemplate': '{value}',
      },
    },
  );
  final duesPayment = engineNativeTestWorkflowDefinition(
    initialState: 'due',
    states: <String, Object?>{
      'due': <String, Object?>{'label': 'Payment due'},
      'paid': <String, Object?>{'label': 'Paid', 'isTerminal': true},
    },
    transitions: <Map<String, Object?>>[
      <String, Object?>{
        'id': 'pay-dues',
        'label': 'Pay \$15',
        'from': <String>['due'],
        'to': 'paid',
        'guard': <String, Object?>{
          'allowedRoleIds': <String>['tabletop-member'],
        },
      },
    ],
    renderBindings: <Map<String, Object?>>[
      homeBinding(<String>['due', 'paid']),
      engineNativeTestRenderBinding(
        states: <String>['due', 'paid'],
        tabId: 'giving',
        cardSurfaceFamily: 'paymentCheckout',
      ),
    ],
    instanceDataSchema: <String, Object?>{
      'title': <String, Object?>{'type': 'text', 'storage': 'inline'},
      'amount': <String, Object?>{'type': 'number', 'storage': 'inline'},
    },
  );
  final gameLoan = engineNativeTestWorkflowDefinition(
    initialState: 'published',
    states: <String, Object?>{
      'published': <String, Object?>{'label': 'In library'},
    },
    transitions: <Map<String, Object?>>[
      <String, Object?>{
        'id': 'borrow',
        'label': 'Request loan',
        'from': <String>['published'],
        'to': null,
        'guard': <String, Object?>{
          'allowedRoleIds': <String>['tabletop-member'],
        },
        'effects': <Object?>[
          <String, Object?>{
            'op': 'set',
            'key': 'availabilityState',
            'value': 'onLoan',
          },
        ],
      },
    ],
    renderBindings: <Map<String, Object?>>[
      homeBinding(<String>['published']),
      engineNativeTestRenderBinding(
        states: <String>['published'],
        tabId: 'marketplace',
        cardSurfaceFamily: 'equipment-loan',
      ),
    ],
    instanceDataSchema: <String, Object?>{
      'title': <String, Object?>{
        'type': 'text',
        'storage': 'inline',
        'labelTemplate': '{value}',
      },
      'category': <String, Object?>{'type': 'text', 'storage': 'inline'},
      'condition': <String, Object?>{'type': 'text', 'storage': 'inline'},
      'description': <String, Object?>{'type': 'textarea', 'storage': 'inline'},
      'availabilityState': <String, Object?>{
        'type': 'text',
        'writableBy': 'effect',
        'storage': 'inline',
        'labelTemplate': 'Availability: {value}',
      },
    },
  );

  final package = writeEngineNativeTestPackagePair(
    tempDirectoryPrefix: 'loom_b30_cascade_',
    extensionId: extensionId,
    communityId: communityId,
    displayName: 'Tabletop Club',
    experience: <String, Object?>{
      'displayName': 'Tabletop Club',
      'tagline':
          'Board game nights, loaner games, and dues for local tabletop fans.',
      'accentColor': '#C4703F',
      'theme': {
        'accent': '#C4703F',
        'tabThemes': {
          'giving': {'accent': '#8A5A34'},
          'marketplace': {'accent': '#2F6F5C'},
        },
      },
      'roles': [
        {
          'roleId': 'tabletop-organizer',
          'label': 'Organizer',
          'roleLabel': 'Organizer',
          'description':
              'Plans game nights, manages the game library, and collects dues.',
        },
        {
          'roleId': 'tabletop-member',
          'label': 'Member',
          'roleLabel': 'Member',
          'description': 'RSVPs to game nights, borrows games, and pays dues.',
        },
      ],
      'workflowDefinitions': <String, Object?>{
        'tabletop-committee-decision': committeeDecision,
        'tabletop-club-dues-payment': duesPayment,
        'tabletop-game-loan': gameLoan,
      },
      'workflowInstances': <Object?>[
        engineNativeTestWorkflowInstance(
          instanceId: 'tabletop-committee-decision',
          workflowType: 'tabletop-committee-decision',
          currentState: 'pending',
          createdByFanId: 'tabletop-member',
          instanceData: <String, Object?>{
            'title': 'Decide on new game purchase',
          },
        ),
        engineNativeTestWorkflowInstance(
          instanceId: 'tabletop-club-dues-payment',
          workflowType: 'tabletop-club-dues-payment',
          currentState: 'due',
          createdByFanId: 'tabletop-member',
          instanceData: <String, Object?>{
            'title': 'Quarterly club dues',
            'amount': 15,
          },
        ),
        engineNativeTestWorkflowInstance(
          instanceId: 'tabletop-game-loan',
          workflowType: 'tabletop-game-loan',
          currentState: 'published',
          createdByFanId: 'tabletop-organizer',
          instanceData: <String, Object?>{
            'title': 'Catan',
            'category': 'Board Games',
            'condition': 'Like new',
            'description': 'Classic resource-trading strategy game.',
            'availabilityState': 'available',
          },
        ),
      ],
    },
    appShell: <String, Object?>{
      'tabs': <Object?>[
        <String, Object?>{
          'tabId': 'marketplace',
          'label': 'Marketplace',
          'iconKey': 'marketplace',
        },
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
