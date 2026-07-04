import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loom_communities_demo/main.dart';

import 'workflow_ui_test_harness.dart';

const _extensionId = 'ext_verify_tabletop_club';

void main() {
  // ── Mode-agnostic engine tests (Gap 5): sale / trade / giveaway ──

  group('B34 mode-agnostic state-machine engine', () {
    test('sale machine: available → purchased (removesFromList)', () {
      final machine = LoomListingStateMachine(
        initialState: 'available',
        states: {
          'available': const LoomListingState(label: 'Available', tone: 'positive'),
          'purchased': const LoomListingState(label: 'Purchased', tone: 'positive'),
        },
        transitions: [
          const LoomListingTransition(
            id: 'buy',
            label: 'Buy now',
            fromStates: ['available'],
            to: 'purchased',
            allowedPersonaIds: ['tabletop-member'],
            linkedWorkflowId: 'sale-checkout',
            removesFromList: true,
          ),
        ],
      );

      // Parse round-trip: transitionsFrom available returns buy
      final actions = machine.availableActions('available', 'tabletop-member');
      expect(actions, isNotEmpty);
      expect(actions.single.id, 'buy');
      expect(actions.single.removesFromList, isTrue);

      // Persona gating: non-member sees nothing
      expect(machine.availableActions('available', 'tabletop-organizer'), isEmpty);
    });

    test('trade machine: offered → pending → traded (multi-step)', () {
      final machine = LoomListingStateMachine(
        initialState: 'offered',
        states: {
          'offered': const LoomListingState(label: 'Offered', tone: 'positive'),
          'pending': const LoomListingState(label: 'Pending', tone: 'warning'),
          'traded': const LoomListingState(label: 'Traded', tone: 'positive'),
        },
        transitions: [
          const LoomListingTransition(
            id: 'propose',
            label: 'Propose trade',
            fromStates: ['offered'],
            to: 'pending',
            allowedPersonaIds: ['tabletop-member'],
            linkedWorkflowId: 'trade-propose',
          ),
          const LoomListingTransition(
            id: 'accept',
            label: 'Accept trade',
            fromStates: ['pending'],
            to: 'traded',
            allowedPersonaIds: ['tabletop-organizer'],
            linkedWorkflowId: 'trade-accept',
          ),
        ],
      );

      expect(
        machine.availableActions('offered', 'tabletop-member').single.id,
        'propose',
      );
      expect(
        machine.availableActions('pending', 'tabletop-organizer').single.id,
        'accept',
      );
      // pending state has no actions for member
      expect(machine.availableActions('pending', 'tabletop-member'), isEmpty);
    });

    test('giveaway machine: available → claimed (removesFromList)', () {
      final machine = LoomListingStateMachine(
        initialState: 'available',
        states: {
          'available': const LoomListingState(label: 'Available', tone: 'positive'),
          'claimed': const LoomListingState(label: 'Claimed', tone: 'positive'),
        },
        transitions: [
          const LoomListingTransition(
            id: 'claim',
            label: 'Claim giveaway',
            fromStates: ['available'],
            to: 'claimed',
            allowedPersonaIds: ['tabletop-member'],
            linkedWorkflowId: 'giveaway-claim',
            removesFromList: true,
          ),
        ],
      );

      final actions = machine.availableActions('available', 'tabletop-member');
      expect(actions.single.id, 'claim');
      expect(actions.single.removesFromList, isTrue);

      // Claimed state has NO actions (terminal)
      expect(machine.availableActions('claimed', 'tabletop-member'), isEmpty);
    });

    test(
      'queue machine: join-then-leave roundtrip via per-member tracking',
      () {
        final machine = LoomListingStateMachine(
          initialState: 'available',
          states: {
            'available': const LoomListingState(label: 'Available', tone: 'positive'),
            'queued': const LoomListingState(label: 'Queue open', tone: 'info', showsQueue: true),
          },
          transitions: [
            const LoomListingTransition(
              id: 'join-queue',
              label: 'Join queue',
              fromStates: ['available', 'queued'],
              allowedPersonaIds: ['tabletop-member'],
              addsActorToQueue: true,
              requiresActorNotInQueue: true,
            ),
            const LoomListingTransition(
              id: 'leave-queue',
              label: 'Leave queue',
              fromStates: ['queued'],
              allowedPersonaIds: ['tabletop-member'],
              requiresActorInQueue: true,
              removesActorFromQueue: true,
            ),
          ],
        );

        // Member NOT in queue → sees "Join queue", NOT "Leave queue"
        final notInQueue = LoomMarketplaceListing(
          listingId: 'l',
          title: 'X',
          availability: 'available',
          queuedPersonaIds: const [],
        );
        var actions = machine.availableActions(
          'available',
          'tabletop-member',
          listing: notInQueue,
        );
        expect(actions.map((a) => a.id), contains('join-queue'));
        expect(actions.map((a) => a.id), isNot(contains('leave-queue')));

        // Member IS in queue → sees "Leave queue", NOT "Join queue"
        final inQueue = LoomMarketplaceListing(
          listingId: 'l',
          title: 'X',
          availability: 'queued',
          queuedPersonaIds: const ['tabletop-member'],
        );
        actions = machine.availableActions(
          'queued',
          'tabletop-member',
          listing: inQueue,
        );
        expect(actions.map((a) => a.id), contains('leave-queue'));
        expect(actions.map((a) => a.id), isNot(contains('join-queue')));
      },
    );
  });

  // ── Browse surface widget tests ─────────────────────────────────

  group('B34 marketplace browse', () {
    // ── (a) positive + (b) negative proof ──────────────────────────

    testWidgets('wf_marketplace-grid-renders-when-listings-declared', (
      tester,
    ) async {
      final fixture = _writeFixture(includeListings: true);
      await tester.pumpWidget(const LoomCommunitiesDemoApp());
      await _installAndOpen(tester, fixture);

      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Navigate to Marketplace tab
      await _tapTab(tester, 'marketplace');

      // (a) positive: grid renders listing cards
      expect(
        find.byKey(const ValueKey('marketplace-listing-listing-catan')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('marketplace-listing-listing-wingspan')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('marketplace-listing-listing-root')),
        findsOneWidget,
      );
      // Placeholder must NOT be visible
      expect(
        find.textContaining('is coming to'),
        findsNothing,
      );
    });

    testWidgets('wf_marketplace-placeholder-when-no-listings', (tester) async {
      final fixture = _writeFixture(includeListings: false);
      await tester.pumpWidget(const LoomCommunitiesDemoApp());
      await _installAndOpen(tester, fixture);

      await tester.pumpAndSettle(const Duration(seconds: 3));

      await _tapTab(tester, 'marketplace');

      // (b) negative: placeholder shows
      expect(find.textContaining('is coming to'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('marketplace-listing-listing-catan')),
        findsNothing,
      );
    });

    // ── (c) search filtering ───────────────────────────────────────

    testWidgets('wf_marketplace-search-filters-listings', (tester) async {
      final fixture = _writeFixture(includeListings: true);
      await tester.pumpWidget(const LoomCommunitiesDemoApp());
      await _installAndOpen(tester, fixture);
      await tester.pumpAndSettle(const Duration(seconds: 3));
      await _tapTab(tester, 'marketplace');

      // All 3 visible initially
      expect(
        find.byKey(const ValueKey('marketplace-listing-listing-catan')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('marketplace-listing-listing-wingspan')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('marketplace-listing-listing-root')),
        findsOneWidget,
      );

      // Type "Wingspan" — only Wingspan should remain
      final searchField = find.byKey(const ValueKey('marketplace-search-field'));
      expect(searchField, findsOneWidget);
      await tester.enterText(searchField, 'Wingspan');
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('marketplace-listing-listing-catan')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('marketplace-listing-listing-wingspan')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('marketplace-listing-listing-root')),
        findsNothing,
      );
    });

    // ── (d) category chip filtering ────────────────────────────────

    testWidgets('wf_marketplace-category-chip-filters', (tester) async {
      final fixture = _writeFixture(includeListings: true);
      await tester.pumpWidget(const LoomCommunitiesDemoApp());
      await _installAndOpen(tester, fixture);
      await tester.pumpAndSettle(const Duration(seconds: 3));
      await _tapTab(tester, 'marketplace');

      // Tap "Strategy Games" chip — only Root (queued) should remain
      final chip = find.byKey(const ValueKey('marketplace-filter-Strategy Games'));
      expect(chip, findsOneWidget);
      await tester.ensureVisible(chip);
      await tester.pumpAndSettle();
      await tester.tap(chip);
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('marketplace-listing-listing-catan')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('marketplace-listing-listing-wingspan')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('marketplace-listing-listing-root')),
        findsOneWidget,
      );

      // Tap again to deselect — all 3 back
      await tester.tap(chip);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('marketplace-listing-listing-catan')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('marketplace-listing-listing-wingspan')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('marketplace-listing-listing-root')),
        findsOneWidget,
      );
    });

    // ── (e) detail anatomy (organizer, persona-agnostic content) ──

    testWidgets('wf_marketplace-detail-anatomy', (tester) async {
      final fixture = _writeFixture(includeListings: true);
      await tester.pumpWidget(const LoomCommunitiesDemoApp());
      await _installAndOpen(tester, fixture);
      await tester.pumpAndSettle(const Duration(seconds: 3));
      await _tapTab(tester, 'marketplace');

      await _openListingDetail(tester, 'listing-wingspan');

      // (e) detail anatomy — content visible regardless of persona
      expect(
        find.byKey(const ValueKey('marketplace-listing-detail-listing-wingspan')),
        findsOneWidget,
      );
      expect(find.textContaining('Excellent'), findsOneWidget);
      expect(find.textContaining('On loan'), findsOneWidget);
      expect(find.textContaining('Board Games'), findsOneWidget);
      expect(find.textContaining('Jamie (Member)'), findsOneWidget);
    });

    // ── (f) persona-gated actions: organizer sees only shared ─────

    testWidgets('wf_marketplace-actions-organizer', (tester) async {
      final fixture = _writeFixture(includeListings: true);
      await tester.pumpWidget(const LoomCommunitiesDemoApp());
      await _installAndOpen(tester, fixture);
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Default persona = organizer (listed first in fixture).
      await _tapTab(tester, 'marketplace');

      // Organizer opens Wingspan (onLoan) — sees return but NOT borrow/join-queue
      await _openListingDetail(tester, 'listing-wingspan');
      expect(
        find.byKey(const ValueKey('marketplace-action-return')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('marketplace-action-borrow')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('marketplace-action-join-queue')),
        findsNothing,
      );
    });

    // ── (f) persona-gated actions: member sees own transitions ─────

    testWidgets('wf_marketplace-actions-member', (tester) async {
      final fixture = _writeFixture(includeListings: true);
      await tester.pumpWidget(const LoomCommunitiesDemoApp());
      await _installAndOpen(tester, fixture);
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Select member persona BEFORE navigating
      await selectPersona(tester, 'tabletop-member');
      await tester.pumpAndSettle();
      await _tapTab(tester, 'marketplace');
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Diagnostic: verify Wingspan listing is in the tree
      expect(
        find.byKey(const ValueKey('marketplace-listing-listing-wingspan')),
        findsOneWidget,
      );

      // Member opens Wingspan (onLoan) — sees join-queue + return
      await _openListingDetail(tester, 'listing-wingspan');
      expect(
        find.byKey(const ValueKey('marketplace-action-join-queue')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('marketplace-action-return')),
        findsOneWidget,
      );

      // Wingspan is onLoan, so borrow (from available) should NOT appear
      expect(
        find.byKey(const ValueKey('marketplace-action-borrow')),
        findsNothing,
      );
    });

    // ── (g) per-listing giveaway: inline stateMachine + removesFromList ──

    testWidgets('wf_marketplace-giveaway-per-listing', (tester) async {
      final fixture = _writeFixture(
        includeListings: true,
        includeGiveaway: true,
      );
      await tester.pumpWidget(const LoomCommunitiesDemoApp());
      await _installAndOpen(tester, fixture);
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Select member persona first
      await selectPersona(tester, 'tabletop-member');
      await tester.pumpAndSettle();
      await _tapTab(tester, 'marketplace');
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Giveaway card is in the grid alongside loan listings
      expect(
        find.byKey(const ValueKey('marketplace-listing-listing-old-catan')),
        findsOneWidget,
      );

      // Open the giveaway listing
      await _openListingDetail(tester, 'listing-old-catan');

      // Member sees "Claim giveaway" action (NOT "Request loan")
      expect(
        find.byKey(const ValueKey('marketplace-action-claim')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('marketplace-action-borrow')),
        findsNothing,
      );
    });
  });
}

// ══════════════════════════════════════════════════════════════════
// Helpers
// ══════════════════════════════════════════════════════════════════

_PackagePairFixture _writeFixture({
  required bool includeListings,
  bool includeGiveaway = false,
}) {
  final tempDir = Directory.systemTemp.createTempSync('loom_b34_');
  final extensionFile = File('${tempDir.path}/$_extensionId.loom-extension.zip');
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

  final experience = <String, dynamic>{
    'displayName': 'Tabletop Club',
    'tagline':
        'Board game nights, loaner games, and dues for local tabletop fans.',
    'accentColor': '#C4703F',
    'theme': {
      'accent': '#C4703F',
    },
    'personas': [
      {
        'personaId': 'tabletop-organizer',
        'label': 'Organizer',
        'roleLabel': 'Organizer',
        'description':
            'Plans game nights, manages the game library, and collects dues.',
      },
      {
        'personaId': 'tabletop-member',
        'label': 'Member',
        'roleLabel': 'Member',
        'description': 'RSVPs to game nights, borrows games, and pays dues.',
      },
    ],
    'workflows': [
      {
        'workflowId': 'tabletop-game-loan',
        'title': 'Borrow a game',
        'entryText': 'A game is available.',
        'actionText': 'Request to borrow',
        'resultText': 'Loan request submitted.',
      },
    ],
    'personaPolicies': {
      'tabletop-game-loan': {
        'actorPersonaIds': ['tabletop-member'],
        'receiverPersonaIds': ['tabletop-organizer'],
        'receiverEntryText': 'A member requested to borrow a game.',
        'receiverActionText': 'Approve loan',
        'receiverResultText': 'Loan approved.',
      },
    },
    'marketplace': {
      'templates': {
        'loan': {
          'initialState': 'available',
          'states': {
            'available': {'label': 'Available', 'tone': 'positive'},
            'onLoan': {
              'label': 'On loan',
              'tone': 'warning',
              'showsHolder': true,
              'showsDue': true,
            },
            'queued': {'label': 'Queue open', 'tone': 'info', 'showsQueue': true},
          },
          'transitions': [
            {
              'id': 'borrow',
              'label': 'Request loan',
              'from': ['available'],
              'to': 'onLoan',
              'allowedPersonaIds': ['tabletop-member'],
              'linkedWorkflowId': 'tabletop-game-loan',
              'setsHolderToActor': true,
            },
            {
              'id': 'join-queue',
              'label': 'Join queue',
              'from': ['onLoan', 'queued'],
              'allowedPersonaIds': ['tabletop-member'],
              'addsActorToQueue': true,
              'requiresActorNotInQueue': true,
            },
            {
              'id': 'leave-queue',
              'label': 'Leave queue',
              'from': ['queued'],
              'allowedPersonaIds': ['tabletop-member'],
              'requiresActorInQueue': true,
              'removesActorFromQueue': true,
            },
            {
              'id': 'return',
              'label': 'Return',
              'from': ['onLoan'],
              'to': 'available',
              'allowedPersonaIds': ['tabletop-member', 'tabletop-organizer'],
              'clearsHolder': true,
            },
          ],
        },
      },
    },
  };

  if (includeListings) {
    experience['marketplaceListings'] = [
      {
        'listingId': 'listing-catan',
        'title': 'Catan',
        'category': 'Board Games',
        'condition': 'Like new',
        'availability': 'available',
        'queueLength': 0,
        'description':
            'Classic resource-trading strategy game. Includes expansion.',
        'linkedWorkflowId': 'tabletop-game-loan',
      },
      {
        'listingId': 'listing-wingspan',
        'title': 'Wingspan',
        'category': 'Board Games',
        'condition': 'Excellent',
        'availability': 'onLoan',
        'currentHolderLabel': 'Jamie (Member)',
        'dueLabel': 'Due back Jul 17',
        'description': 'Award-winning engine-building bird game.',
        'linkedWorkflowId': 'tabletop-game-loan',
      },
      {
        'listingId': 'listing-root',
        'title': 'Root',
        'category': 'Strategy Games',
        'condition': 'Good',
        'availability': 'queued',
        'queueLength': 2,
        'description': 'Asymmetric woodland strategy game.',
        'linkedWorkflowId': 'tabletop-game-loan',
      },
      {
        'listingId': 'listing-old-catan',
        'title': 'Catan (retired club copy)',
        'category': 'Board Games',
        'condition': 'Fair',
        'availability': 'giveaway',
        'description': 'Free to a member — retired club copy.',
        'stateMachine': {
          'initialState': 'available',
          'states': {
            'available': {'label': 'Available', 'tone': 'positive'},
            'claimed': {'label': 'Claimed', 'tone': 'positive'},
          },
          'transitions': [
            {
              'id': 'claim',
              'label': 'Claim giveaway',
              'from': ['available'],
              'to': 'claimed',
              'allowedPersonaIds': ['tabletop-member'],
              'linkedWorkflowId': 'tabletop-game-loan',
              'removesFromList': true,
            },
          ],
        },
      },
    ];
  }

  initializationFile.writeAsStringSync(
    jsonEncode({
      'schemaVersion': 1,
      'communityId': 'community_verify_tabletop_club',
      'communityName': 'Tabletop Club',
      'extensionId': _extensionId,
      'seedDataFiles': ['seed/community.json', 'seed/workflows.json'],
      'branding': {'accentColor': '#C4703F'},
      'experience': experience,
    }),
  );

  return _PackagePairFixture(
    extensionPath: extensionFile.path,
    initializationPath: initializationFile.path,
  );
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
    find.byKey(const ValueKey('community-card-community_verify_tabletop_club')),
  );
  await tester.pumpAndSettle();
}

Future<void> _openListingDetail(WidgetTester tester, String listingId) async {
  final card = find.byKey(ValueKey('marketplace-listing-$listingId'));
  expect(card, findsOneWidget, reason: 'card $listingId must exist');
  // Drag the parent scrollable downward to bring grid cards into view
  // (grid uses NeverScrollableScrollPhysics; ensureVisible on its own
  // does not scroll the parent SingleChildScrollView)
  final scrollable = find.byType(SingleChildScrollView);
  await tester.drag(scrollable, const Offset(0, -300));
  await tester.pumpAndSettle();
  await tester.ensureVisible(card);
  await tester.pumpAndSettle();
  await tester.tap(card, warnIfMissed: false);
  await tester.pumpAndSettle();
}

Future<void> _backToBrowse(WidgetTester tester) async {
  await tester.tap(find.byTooltip('Back to browse'), warnIfMissed: false);
  await tester.pumpAndSettle();
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
  await tester.ensureVisible(tabFinder);
  await tester.pumpAndSettle();
  await tester.tap(tabFinder, warnIfMissed: false);
  await tester.pumpAndSettle();
}

class _PackagePairFixture {
  const _PackagePairFixture({
    required this.extensionPath,
    required this.initializationPath,
  });

  final String extensionPath;
  final String initializationPath;
}