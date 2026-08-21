import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loom_communities_demo/main.dart';

import 'workflow_ui_test_harness.dart';

const _extensionId = 'ext_verify_tabletop_club';
var _fixtureSequence = 0;

void main() {
  // ── Mode-agnostic engine tests (Gap 5): sale / trade / giveaway ──

  group('B34 mode-agnostic state-machine engine', () {
    test('sale machine: available → purchased (removesFromList)', () {
      final machine = LoomListingStateMachine(
        initialState: 'available',
        states: {
          'available': const LoomListingState(
            label: 'Available',
            tone: 'positive',
          ),
          'purchased': const LoomListingState(
            label: 'Purchased',
            tone: 'positive',
          ),
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
      expect(
        machine.availableActions('available', 'tabletop-organizer'),
        isEmpty,
      );
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
          'available': const LoomListingState(
            label: 'Available',
            tone: 'positive',
          ),
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
            'available': const LoomListingState(
              label: 'Available',
              tone: 'positive',
            ),
            'queued': const LoomListingState(
              label: 'Queue open',
              tone: 'info',
              showsQueue: true,
            ),
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
        find.byKey(const ValueKey('engine-native-marketplace-root')),
        findsOneWidget,
      );
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
      expect(find.textContaining('is coming to'), findsNothing);
    });

    testWidgets('wf_marketplace-empty-surface-when-no-listings', (
      tester,
    ) async {
      final fixture = _writeFixture(includeListings: false);
      await tester.pumpWidget(const LoomCommunitiesDemoApp());
      await _installAndOpen(tester, fixture);

      await tester.pumpAndSettle(const Duration(seconds: 3));

      await _tapTab(tester, 'marketplace', marketplaceEmpty: true);

      // (b) the native Marketplace owns a real empty state, not a shallow
      // data-declaration placeholder.
      expect(
        find.byKey(const ValueKey('engine-native-marketplace-empty')),
        findsOneWidget,
      );
      expect(find.text('No shared items are listed yet.'), findsOneWidget);
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
      final searchField = find.byKey(
        const ValueKey('marketplace-search-field'),
      );
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
      final chip = find.byKey(
        const ValueKey('marketplace-filter-Strategy Games'),
      );
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
      final detail = find.byKey(
        const ValueKey('marketplace-detail-dialog-listing-wingspan'),
      );
      expect(
        detail,
        findsOneWidget,
      );
      expect(
        find.descendant(of: detail, matching: find.text('Excellent')),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: detail,
          matching: find.text('On Loan'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(of: detail, matching: find.text('Board Games')),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: detail,
          matching: find.textContaining('Jamie (Member)'),
        ),
        findsOneWidget,
      );
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
        find.byKey(const ValueKey('marketplace-transition-fab-borrow')),
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
      await _installAndOpen(tester, fixture, personaId: 'tabletop-member');
      await tester.pumpAndSettle(const Duration(seconds: 3));
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
        find.byKey(const ValueKey('marketplace-transition-fab-borrow')),
        findsNothing,
      );
    });

    // ── (f.ii) queue join-then-leave roundtrip ─────────────────────

    testWidgets('wf_marketplace-join-then-leave-queue', (tester) async {
      final fixture = _writeFixture(includeListings: true);
      await tester.pumpWidget(const LoomCommunitiesDemoApp());
      await _installAndOpen(tester, fixture, personaId: 'tabletop-member');
      await tester.pumpAndSettle(const Duration(seconds: 3));
      await _tapTab(tester, 'marketplace');
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Open listing-root (queued, no members in queue yet)
      await _openListingDetail(tester, 'listing-root');

      // Member NOT in queue → sees "Join queue"
      expect(
        find.byKey(const ValueKey('marketplace-action-join-queue')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('marketplace-action-leave-queue')),
        findsNothing,
      );

      // Tap "Join queue"
      await tester.tap(
        find.byKey(const ValueKey('marketplace-action-join-queue')),
        warnIfMissed: false,
      );
      await tester.pumpAndSettle();

      // After tapping, "Leave queue" replaces "Join queue"
      expect(
        find.byKey(const ValueKey('marketplace-action-leave-queue')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('marketplace-action-join-queue')),
        findsNothing,
      );

      // Tap "Leave queue" and verify the member can join again.
      await tester.tap(
        find.byKey(const ValueKey('marketplace-action-leave-queue')),
        warnIfMissed: false,
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('marketplace-action-join-queue')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('marketplace-action-leave-queue')),
        findsNothing,
      );
    });

    testWidgets('wf_marketplace-borrow-action-functions', (tester) async {
      final fixture = _writeFixture(includeListings: true);
      await tester.pumpWidget(const LoomCommunitiesDemoApp());
      await _installAndOpen(tester, fixture, personaId: 'tabletop-member');
      await tester.pumpAndSettle(const Duration(seconds: 3));
      await _tapTab(tester, 'marketplace');
      await tester.pumpAndSettle(const Duration(seconds: 2));

      await _openListingDetail(tester, 'listing-catan');
      expect(
        find.byKey(const ValueKey('marketplace-transition-fab-borrow')),
        findsOneWidget,
      );

      await tester.tap(
        find.byKey(const ValueKey('marketplace-transition-fab-borrow')),
        warnIfMissed: false,
      );
      await tester.pumpAndSettle();

      await waitForEngineNativeWidget(
        tester,
        find.byKey(const ValueKey('marketplace-action-return')),
        description: 'return action after borrowing Catan',
      );
      expect(
        find.byKey(const ValueKey('marketplace-detail-dialog-listing-catan')),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(
            const ValueKey('marketplace-detail-dialog-listing-catan'),
          ),
          matching: find.text('On Loan'),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('marketplace-transition-fab-borrow')),
        findsNothing,
      );
    });

    testWidgets('wf_marketplace-return-action-functions', (tester) async {
      final fixture = _writeFixture(includeListings: true);
      await tester.pumpWidget(const LoomCommunitiesDemoApp());
      await _installAndOpen(tester, fixture, personaId: 'tabletop-member');
      await tester.pumpAndSettle(const Duration(seconds: 3));
      await _tapTab(tester, 'marketplace');
      await tester.pumpAndSettle(const Duration(seconds: 2));

      await _openListingDetail(tester, 'listing-wingspan');
      await tester.tap(
        find.byKey(const ValueKey('marketplace-action-return')),
        warnIfMissed: false,
      );
      await tester.pumpAndSettle();

      await waitForEngineNativeWidget(
        tester,
        find.byKey(const ValueKey('marketplace-transition-fab-borrow')),
        description: 'borrow action after returning Wingspan',
      );
      expect(find.text('Available'), findsAtLeastNWidgets(1));
      expect(
        find.byKey(const ValueKey('marketplace-transition-fab-borrow')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('marketplace-action-return')),
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
      await _installAndOpen(tester, fixture, personaId: 'tabletop-member');
      await tester.pumpAndSettle(const Duration(seconds: 3));
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
        find.byKey(const ValueKey('marketplace-transition-fab-borrow')),
        findsNothing,
      );

      await tester.tap(
        find.byKey(const ValueKey('marketplace-action-claim')),
        warnIfMissed: false,
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(
          const ValueKey('marketplace-detail-dialog-listing-old-catan'),
        ),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('engine-native-marketplace-root')),
        findsOneWidget,
      );
    });

    testWidgets('wf_marketplace-queryInstances-loads-second-page', (
      tester,
    ) async {
      final fixture = _writeFixture(
        includeListings: true,
        extraListingCount: 27,
      );
      await tester.pumpWidget(const LoomCommunitiesDemoApp());
      await _installAndOpen(tester, fixture);
      await tester.pumpAndSettle(const Duration(seconds: 3));

      await _tapTab(tester, 'marketplace');
      await tester.pumpAndSettle(const Duration(seconds: 2));

      expect(
        find.byKey(const ValueKey('engine-native-marketplace-root')),
        findsOneWidget,
      );
      await waitForEngineNativeWidget(
        tester,
        find.byKey(const ValueKey('marketplace-listing-listing-extra-26')),
        description: 'Marketplace listing from the second queryInstances page',
      );

      expect(
        find.byKey(const ValueKey('marketplace-listing-listing-extra-26')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('marketplace-load-more')), findsNothing);
    });
  });
}

// ══════════════════════════════════════════════════════════════════
// Helpers
// ══════════════════════════════════════════════════════════════════

({EvidencePackagePair package, String communityId}) _writeFixture({
  required bool includeListings,
  bool includeGiveaway = false,
  int extraListingCount = 0,
}) {
  final sequence = _fixtureSequence++;
  final extensionId = '${_extensionId}_b34_$sequence';
  final communityId = 'community_verify_tabletop_club_b34_$sequence';
  final marketplace = engineNativeMarketplaceTestFixture(
    loanWorkflowType: 'tabletop-game-loan',
    memberRoleId: 'tabletop-member',
    organizerRoleId: 'tabletop-organizer',
    loanSeeds: <EngineNativeMarketplaceLoanSeed>[
      if (includeListings) ...<EngineNativeMarketplaceLoanSeed>[
        const EngineNativeMarketplaceLoanSeed(
          instanceId: 'listing-catan',
          title: 'Catan',
          category: 'Board Games',
          condition: 'Like new',
          description:
              'Classic resource-trading strategy game. Includes expansion.',
        ),
        const EngineNativeMarketplaceLoanSeed(
          instanceId: 'listing-wingspan',
          title: 'Wingspan',
          category: 'Board Games',
          condition: 'Excellent',
          description: 'Award-winning engine-building bird game.',
          availabilityState: 'onLoan',
          holderFanId: 'Jamie (Member)',
          dueDate: '2026-07-17',
        ),
        const EngineNativeMarketplaceLoanSeed(
          instanceId: 'listing-root',
          title: 'Root',
          category: 'Strategy Games',
          condition: 'Good',
          description: 'Asymmetric woodland strategy game.',
          availabilityState: 'onLoan',
          queuedFanIds: <String>['queued-member-1', 'queued-member-2'],
        ),
        for (var index = 0; index < extraListingCount; index += 1)
          EngineNativeMarketplaceLoanSeed(
            instanceId: 'listing-extra-${index.toString().padLeft(2, '0')}',
            title: 'Extra game ${index.toString().padLeft(2, '0')}',
            category: 'Board Games',
            condition: 'Good',
            description: 'Extra paginated fixture game $index.',
          ),
      ] else
        const EngineNativeMarketplaceLoanSeed(
          instanceId: 'listing-delisted-history',
          title: 'Retired listing history',
          category: 'Board Games',
          condition: 'Retired',
          description: 'A terminal row keeps the fixture engine-native.',
          currentState: 'delisted',
        ),
    ],
    giveawaySeeds: includeGiveaway
        ? const <EngineNativeMarketplaceGiveawaySeed>[
            EngineNativeMarketplaceGiveawaySeed(
              instanceId: 'listing-old-catan',
              title: 'Catan (retired club copy)',
              category: 'Board Games',
              condition: 'Fair',
              description: 'Free to a member — retired club copy.',
            ),
          ]
        : const <EngineNativeMarketplaceGiveawaySeed>[],
  );

  final package = writeEngineNativeTestPackagePair(
    tempDirectoryPrefix: 'loom_b34_',
    extensionId: extensionId,
    communityId: communityId,
    displayName: 'Tabletop Club',
    experience: <String, Object?>{
      'displayName': 'Tabletop Club',
      'tagline':
          'Board game nights, loaner games, and dues for local tabletop fans.',
      'accentColor': '#C4703F',
      'theme': <String, Object?>{'accent': '#C4703F'},
      'roles': const <Object?>[
        <String, Object?>{
          'roleId': 'tabletop-organizer',
          'label': 'Organizer',
          'roleLabel': 'Organizer',
          'description':
              'Plans game nights, manages the game library, and collects dues.',
        },
        <String, Object?>{
          'roleId': 'tabletop-member',
          'label': 'Member',
          'roleLabel': 'Member',
          'description': 'RSVPs to game nights, borrows games, and pays dues.',
        },
      ],
      'workflowDefinitions': marketplace.workflowDefinitions,
      'workflowInstances': marketplace.workflowInstances,
    },
    appShell: <String, Object?>{
      'tabs': <Object?>[engineNativeMarketplaceTestTab()],
    },
  );
  return (package: package, communityId: communityId);
}

Future<void> _installAndOpen(
  WidgetTester tester,
  ({EvidencePackagePair package, String communityId}) fixture, {
  String personaId = 'tabletop-organizer',
}) async {
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
  await selectPersona(tester, personaId);
}

Future<void> _openListingDetail(WidgetTester tester, String listingId) async {
  final card = find.byKey(ValueKey('marketplace-listing-$listingId'));
  await waitForEngineNativeWidget(
    tester,
    card,
    description: 'Marketplace listing $listingId',
  );
  expect(card, findsOneWidget, reason: 'card $listingId must exist');
  final tapTarget = find.byKey(ValueKey('marketplace-listing-tap-$listingId'));
  await tester.ensureVisible(tapTarget);
  await tester.pumpAndSettle();
  final tapRect = tester.getRect(tapTarget);
  await tester.tapAt(Offset(tapRect.center.dx, tapRect.top + 20));
  await tester.pumpAndSettle();
  await waitForEngineNativeWidget(
    tester,
    find.byKey(ValueKey('marketplace-detail-dialog-$listingId')),
    description: 'Marketplace detail for $listingId',
  );
}

Future<void> _tapTab(
  WidgetTester tester,
  String tabId, {
  bool marketplaceEmpty = false,
}) async {
  await tapCommunityTab(tester, tabId);
  await waitForEngineNativeMarketplaceSurface(tester, empty: marketplaceEmpty);
}
