import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loom_communities_app_shell/loom_communities_app_shell.dart';
import 'package:loom_demo_local_backend/loom_demo_local_backend.dart';
import 'package:loom_ux_judges/src/validator/jsonc.dart';

import 'package:loom_workflow_engine/loom_workflow_engine.dart';

import 'authz_p6_test_helpers.dart';

const _fixtureRelative =
    'docs/references/communities/Loom_Communities_Workflow_Engine_Phase1_TabletopClub_Example.jsonc';

File _fixtureFile() {
  var directory = Directory.current;
  for (var i = 0; i < 8; i++) {
    final candidate = File('${directory.path}/$_fixtureRelative');
    if (candidate.existsSync()) return candidate;
    directory = directory.parent;
  }
  throw StateError('Could not find frozen Tabletop fixture');
}

class _InstalledTabletop {
  const _InstalledTabletop(this.community, this.engine, this.temp);

  final LocalInstalledCommunity community;
  final WorkflowEngineApi engine;
  final Directory temp;

  Future<void> dispose() => temp.delete(recursive: true);
}

class _MarketplaceCountingEngine implements WorkflowEngineApi {
  _MarketplaceCountingEngine(this.delegate);

  final WorkflowEngineApi delegate;
  int queries = 0;

  @override
  Future<InstancePage> queryInstances({
    required String tabId,
    required String personaId,
    SurfaceQuery query = const SurfaceQuery.empty(),
    int limit = 25,
    String? cursor,
  }) {
    queries++;
    return delegate.queryInstances(
      tabId: tabId,
      personaId: personaId,
      query: query,
      limit: limit,
      cursor: cursor,
    );
  }

  @override
  Future<List<LoomWorkflowTransition>> availableTransitionsAsync({
    required String workflowType,
    required String instanceId,
    required String currentState,
    required Map<String, dynamic> instanceData,
    required String personaId,
  }) => delegate.availableTransitionsAsync(
    workflowType: workflowType,
    instanceId: instanceId,
    currentState: currentState,
    instanceData: instanceData,
    personaId: personaId,
  );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<_InstalledTabletop> _install(String extensionId) async {
  final source =
      jsonDecode(stripJsonComments(_fixtureFile().readAsStringSync()))
          as Map<String, dynamic>;
  source['extensionId'] = extensionId;
  final temp = await Directory.systemTemp.createTemp(
    'loom-phasec-$extensionId-',
  );
  try {
    final init = File('${temp.path}/tabletop.loom-init.zip');
    final extension = File('${temp.path}/tabletop.loom-extension.zip');
    await init.writeAsString(jsonEncode(source));
    await extension.writeAsString(
      jsonEncode(<String, Object?>{
        'schemaVersion': 1,
        'extensionId': extensionId,
        'displayName': source['displayName'],
        'version': '1.0.0',
        'mode': 'local-demo',
        'permissions': <String>[],
      }),
    );
    final community = LocalInAppBackend()
        .installLocalPackagePairFromFiles(
          extensionPackagePath: extension.path,
          initializationPackagePath: init.path,
        )
        .community;
    // Register and fully resolve the engine-native store before the widget
    // is pumped. This keeps the native sqlite connection in the real async
    // zone, matching the proven Phase B test-install pattern.
    experienceForExtensionId(
      community.extensionId,
      displayName: community.displayName,
      experienceConfiguration: community.experienceConfiguration,
    );
    final engine = await workflowEngineForExtensionId(community.extensionId);
    return _InstalledTabletop(community, engine, temp);
  } catch (_) {
    await temp.delete(recursive: true);
    rethrow;
  }
}

Future<void> _pumpUntil(WidgetTester tester, Finder finder) async {
  for (var attempt = 0; attempt < 40; attempt++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 5)),
    );
    await tester.pump(const Duration(milliseconds: 50));
    if (finder.evaluate().isNotEmpty) return;
  }
  throw TestFailure('Timed out waiting for $finder');
}

Future<void> _pumpUntilGone(WidgetTester tester, Finder finder) async {
  for (var attempt = 0; attempt < 40; attempt++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 5)),
    );
    await tester.pump(const Duration(milliseconds: 50));
    if (finder.evaluate().isEmpty) return;
  }
  throw TestFailure('Timed out waiting for $finder to disappear');
}

Future<void> _selectPersona(WidgetTester tester, String personaId) async {
  await selectTestTabletopPersona(tester, personaId);
}

Widget _app(_InstalledTabletop installed) => MaterialApp(
  home: LocalExtensionScreen(
    community: installed.community,
    seedDataFiles: const [],
    authApi: activeAuthForInstalledCommunity(
      community: installed.community,
      personaTypeId: 'tabletop-organizer',
    ),
  ),
);

Future<void> _selectMarketplace(WidgetTester tester) async {
  final marketplace = find.byKey(const ValueKey('community-tab-marketplace'));
  await _pumpUntil(tester, marketplace);
  await tester.ensureVisible(marketplace);
  await tester.tap(marketplace);
  await _pumpUntil(
    tester,
    find.byKey(const ValueKey('engine-native-marketplace-root')),
  );
}

Future<WorkflowInstance> _readMarketplaceInstance(
  WorkflowEngineApi engine, {
  required String instanceId,
  required String personaId,
}) async {
  final page = await engine.queryInstances(
    tabId: 'marketplace',
    personaId: personaId,
    limit: 100,
  );
  return page.items.singleWhere(
    (instance) => instance.instanceId == instanceId,
  );
}

Future<Set<String>> _availableMarketplaceTransitionIds(
  WorkflowEngineApi engine,
  WorkflowInstance instance,
  String personaId,
) async {
  final transitions = await engine.availableTransitionsAsync(
    workflowType: instance.workflowType,
    instanceId: instance.instanceId,
    currentState: instance.currentState,
    instanceData: instance.instanceData,
    personaId: personaId,
  );
  return transitions.map((transition) => transition.id).toSet();
}

void main() {
  test(
    'real equipment-loan dues guard rejects unpaid borrow and permits paid borrow',
    () async {
      final installed = await _install('phasec3-marketplace-dues-guard');
      try {
        await expectLater(
          installed.engine.applyTransition(
            workflowType: 'equipment-loan',
            instanceId: 'listing-catan',
            transitionId: 'borrow',
            personaId: 'tabletop-member',
          ),
          throwsStateError,
        );

        final payment = await installed.engine.applyTransition(
          workflowType: 'tabletop-club-dues-payment',
          instanceId: 'dues-2026-q3-member',
          transitionId: 'pay',
          personaId: 'tabletop-member',
        );
        expect(payment.newState, 'paid');
        expect(payment.newInstanceData['receiptStatus'], 'complete');

        final borrow = await installed.engine.applyTransition(
          workflowType: 'equipment-loan',
          instanceId: 'listing-catan',
          transitionId: 'borrow',
          personaId: 'tabletop-member',
        );
        expect(borrow.newState, 'published');
        expect(borrow.newInstanceData['availabilityState'], 'onLoan');
        expect(borrow.newInstanceData['holderPersonaId'], 'tabletop-member');

        final marketplace = await installed.engine.queryInstances(
          tabId: 'marketplace',
          personaId: 'tabletop-member',
          limit: 100,
        );
        final catan = marketplace.items.singleWhere(
          (instance) => instance.instanceId == 'listing-catan',
        );
        expect(catan.currentState, 'published');
        expect(catan.instanceData['availabilityState'], 'onLoan');
        expect(catan.instanceData['holderPersonaId'], 'tabletop-member');
      } finally {
        await installed.dispose();
      }
    },
  );

  test(
    'real equipment-loan queue and return transitions mutate seeded listings',
    () async {
      final installed = await _install('phasec4-marketplace-queue-return');
      const memberId = 'tabletop-member';
      try {
        final catanBefore = await _readMarketplaceInstance(
          installed.engine,
          instanceId: 'listing-catan',
          personaId: memberId,
        );
        expect(catanBefore.instanceData['availabilityState'], 'available');
        expect(catanBefore.instanceData['queuedPersonaIds'], isEmpty);
        expect(catanBefore.instanceData['queueLength'], 0);

        final joined = await installed.engine.applyTransition(
          workflowType: 'equipment-loan',
          instanceId: 'listing-catan',
          transitionId: 'join-queue',
          personaId: memberId,
        );
        expect(joined.newState, 'published');
        expect(joined.newInstanceData['queuedPersonaIds'], contains(memberId));

        final catanAfterJoin = await _readMarketplaceInstance(
          installed.engine,
          instanceId: 'listing-catan',
          personaId: memberId,
        );
        expect(
          catanAfterJoin.instanceData['queuedPersonaIds'],
          contains(memberId),
        );
        expect(catanAfterJoin.instanceData['queueLength'], 1);
        final afterJoinTransitions = await _availableMarketplaceTransitionIds(
          installed.engine,
          catanAfterJoin,
          memberId,
        );
        expect(afterJoinTransitions, contains('leave-queue'));
        expect(afterJoinTransitions, isNot(contains('join-queue')));

        final left = await installed.engine.applyTransition(
          workflowType: 'equipment-loan',
          instanceId: 'listing-catan',
          transitionId: 'leave-queue',
          personaId: memberId,
        );
        expect(left.newState, 'published');
        expect(left.newInstanceData['queuedPersonaIds'], isEmpty);

        final catanAfterLeave = await _readMarketplaceInstance(
          installed.engine,
          instanceId: 'listing-catan',
          personaId: memberId,
        );
        expect(catanAfterLeave.instanceData['queuedPersonaIds'], isEmpty);
        expect(catanAfterLeave.instanceData['queueLength'], 0);
        final afterLeaveTransitions = await _availableMarketplaceTransitionIds(
          installed.engine,
          catanAfterLeave,
          memberId,
        );
        expect(afterLeaveTransitions, contains('join-queue'));
        expect(afterLeaveTransitions, isNot(contains('leave-queue')));

        // Root is already available and queued for two different members. A
        // fresh join here proves reserve-ahead works independently of loan
        // availability, not only after an item is on loan.
        final rootBefore = await _readMarketplaceInstance(
          installed.engine,
          instanceId: 'listing-root',
          personaId: memberId,
        );
        expect(rootBefore.instanceData['availabilityState'], 'available');
        expect(rootBefore.instanceData['queuedPersonaIds'], hasLength(2));
        expect(rootBefore.instanceData['queueLength'], 2);
        final rootJoined = await installed.engine.applyTransition(
          workflowType: 'equipment-loan',
          instanceId: 'listing-root',
          transitionId: 'join-queue',
          personaId: memberId,
        );
        expect(rootJoined.newState, 'published');
        expect(
          rootJoined.newInstanceData['queuedPersonaIds'],
          contains(memberId),
        );
        final rootAfter = await _readMarketplaceInstance(
          installed.engine,
          instanceId: 'listing-root',
          personaId: memberId,
        );
        expect(rootAfter.instanceData['availabilityState'], 'available');
        expect(rootAfter.instanceData['queuedPersonaIds'], contains(memberId));
        expect(rootAfter.instanceData['queueLength'], 3);

        // Wingspan is seeded on loan with a real due date. The equipment-loan
        // return guard authorizes the generic member role and does not require
        // the actor to match holderPersonaId.
        const returnerId = 'tabletop-member';
        final wingspanBefore = await _readMarketplaceInstance(
          installed.engine,
          instanceId: 'listing-wingspan',
          personaId: returnerId,
        );
        expect(wingspanBefore.instanceData['availabilityState'], 'onLoan');
        expect(
          wingspanBefore.instanceData['holderPersonaId'],
          'tabletop-member-03',
        );
        expect(wingspanBefore.instanceData['dueDate'], '2026-07-17');
        final wingspanTransitions = await _availableMarketplaceTransitionIds(
          installed.engine,
          wingspanBefore,
          returnerId,
        );
        expect(wingspanTransitions, contains('return'));

        final returned = await installed.engine.applyTransition(
          workflowType: 'equipment-loan',
          instanceId: 'listing-wingspan',
          transitionId: 'return',
          personaId: returnerId,
        );
        expect(returned.newState, 'published');
        expect(returned.newInstanceData['availabilityState'], 'available');
        expect(returned.newInstanceData['holderPersonaId'], isNull);
        expect(returned.newInstanceData['dueDate'], isNull);

        final wingspanAfter = await _readMarketplaceInstance(
          installed.engine,
          instanceId: 'listing-wingspan',
          personaId: returnerId,
        );
        expect(wingspanAfter.currentState, 'published');
        expect(wingspanAfter.instanceData['availabilityState'], 'available');
        expect(wingspanAfter.instanceData['holderPersonaId'], isNull);
        expect(wingspanAfter.instanceData['dueDate'], isNull);
      } finally {
        await installed.dispose();
      }
    },
  );

  test('real equipment-giveaway claim mutates the seeded listing', () async {
    final installed = await _install('phasec5-marketplace-giveaway-engine');
    try {
      final before = await _readMarketplaceInstance(
        installed.engine,
        instanceId: 'listing-old-catan',
        personaId: 'tabletop-member',
      );
      expect(before.workflowType, 'equipment-giveaway');
      expect(before.currentState, 'available');
      expect(before.instanceData['claimedByPersonaId'], isNull);

      final claimed = await installed.engine.applyTransition(
        workflowType: 'equipment-giveaway',
        instanceId: 'listing-old-catan',
        transitionId: 'claim',
        personaId: 'tabletop-member',
      );
      expect(claimed.newState, 'claimed');
      expect(claimed.newInstanceData['claimedByPersonaId'], 'tabletop-member');

      // removeFromTileGrid is presentation-only. The persisted row remains
      // queryable, while its available-only render binding no longer
      // resolves for the Marketplace dispatcher.
      final after = await _readMarketplaceInstance(
        installed.engine,
        instanceId: 'listing-old-catan',
        personaId: 'tabletop-member',
      );
      expect(after.currentState, 'claimed');
      expect(after.instanceData['claimedByPersonaId'], 'tabletop-member');
    } finally {
      await installed.dispose();
    }
  });

  testWidgets('claimed equipment giveaway leaves the real Marketplace grid', (
    tester,
  ) async {
    final installed = (await tester.runAsync(
      () => _install('phasec5-marketplace-giveaway-grid'),
    ))!;
    try {
      await tester.pumpWidget(_app(installed));
      await _selectPersona(tester, 'tabletop-member');
      await _selectMarketplace(tester);

      final giveaway = find.byKey(
        const ValueKey('marketplace-listing-listing-old-catan'),
      );
      await _pumpUntil(tester, giveaway);
      expect(giveaway, findsOneWidget);
      expect(tester.takeException(), isNull);

      final claim = find.byKey(
        const ValueKey('equipment-loan-listing-old-catan-action-claim'),
      );
      await _pumpUntil(tester, claim);
      await tester.ensureVisible(claim);
      expect(
        find.descendant(of: giveaway, matching: find.text('Claim giveaway')),
        findsOneWidget,
      );
      await tester.tap(claim);
      await _pumpUntilGone(tester, giveaway);

      expect(giveaway, findsNothing);
      expect(tester.takeException(), isNull);
      final after = await tester.runAsync(
        () => _readMarketplaceInstance(
          installed.engine,
          instanceId: 'listing-old-catan',
          personaId: 'tabletop-member',
        ),
      );
      expect(after!.currentState, 'claimed');
      expect(after.instanceData['claimedByPersonaId'], 'tabletop-member');
    } finally {
      await tester.runAsync(installed.dispose);
    }
  });

  testWidgets(
    'real seeded Marketplace listings render through the shared engine grid, search, category filters, and detail',
    (tester) async {
      final installed = (await tester.runAsync(
        () => _install('phasec-marketplace-browse'),
      ))!;
      try {
        await tester.pumpWidget(_app(installed));
        await _selectPersona(tester, 'tabletop-organizer');
        await _selectMarketplace(tester);
        expect(tester.takeException(), isNull);

        for (final listingId in const [
          'listing-catan',
          'listing-wingspan',
          'listing-root',
        ]) {
          expect(
            find.byKey(ValueKey('marketplace-listing-$listingId')),
            findsOneWidget,
          );
        }
        final rootListing = find.byKey(
          const ValueKey('marketplace-listing-listing-root'),
        );
        final catanListing = find.byKey(
          const ValueKey('marketplace-listing-listing-catan'),
        );
        expect(
          find.descendant(of: catanListing, matching: find.text('Catan')),
          findsOneWidget,
        );
        expect(
          find.descendant(of: catanListing, matching: find.text('Board Games')),
          findsOneWidget,
        );
        expect(
          find.descendant(of: catanListing, matching: find.text('Available')),
          findsOneWidget,
        );
        expect(
          find.descendant(of: catanListing, matching: find.text('0')),
          findsNothing,
        );
        expect(
          find.descendant(of: catanListing, matching: find.text('true')),
          findsNothing,
        );

        await tester.ensureVisible(catanListing);
        await tester.tap(catanListing);
        await _pumpUntil(
          tester,
          find.byKey(const ValueKey('marketplace-detail-dialog-listing-catan')),
        );
        final catanDetailCard = find.byKey(
          const ValueKey('marketplace-detail-card-listing-catan'),
        );
        expect(
          find.descendant(of: catanDetailCard, matching: find.text('Catan')),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: catanDetailCard,
            matching: find.text('Board Games'),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(of: catanDetailCard, matching: find.text('Like new')),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: catanDetailCard,
            matching: find.text(
              'Classic resource-trading strategy game for 3-4 players. Includes 5-6 player expansion.',
            ),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: catanDetailCard,
            matching: find.text('Available'),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(of: catanDetailCard, matching: find.text('0')),
          findsNothing,
        );
        expect(
          find.descendant(of: catanDetailCard, matching: find.text('true')),
          findsNothing,
        );
        await tester.tap(
          find.byKey(const ValueKey('marketplace-detail-close-listing-catan')),
        );
        await tester.pump();

        final wingspanListing = find.byKey(
          const ValueKey('marketplace-listing-listing-wingspan'),
        );
        await tester.ensureVisible(wingspanListing);
        await tester.tap(wingspanListing);
        await _pumpUntil(
          tester,
          find.byKey(
            const ValueKey('marketplace-detail-dialog-listing-wingspan'),
          ),
        );
        final wingspanDetailCard = find.byKey(
          const ValueKey('marketplace-detail-card-listing-wingspan'),
        );
        expect(
          find.descendant(
            of: wingspanDetailCard,
            matching: find.text('On Loan'),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: wingspanDetailCard,
            matching: find.text('Holder: tabletop-member-03'),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: wingspanDetailCard,
            matching: find.text('Queue: 1'),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: wingspanDetailCard,
            matching: find.text('Due back 2026-07-17'),
          ),
          findsOneWidget,
        );
        await tester.tap(
          find.byKey(
            const ValueKey('marketplace-detail-close-listing-wingspan'),
          ),
        );
        await tester.pump();

        final gloomhavenListing = find.byKey(
          const ValueKey('marketplace-listing-share-gloomhaven'),
        );
        expect(gloomhavenListing, findsOneWidget);
        expect(find.text('On Loan'), findsOneWidget);
        expect(find.text('Holder: tabletop-member-03'), findsOneWidget);
        expect(find.text('Queue: 1'), findsOneWidget);
        expect(
          find.descendant(of: rootListing, matching: find.text('Queue: 2')),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: gloomhavenListing,
            matching: find.text('Queue: 2'),
          ),
          findsOneWidget,
        );
        for (final category in const [
          'Board Games',
          'Strategy Games',
          'Family Games',
          'Abstract Games',
        ]) {
          expect(
            find.byKey(ValueKey('marketplace-filter-$category')),
            findsOneWidget,
          );
        }

        final search = find.byKey(const ValueKey('marketplace-search-field'));
        await tester.enterText(search, 'Wingspan');
        await _pumpUntil(tester, wingspanListing);
        expect(wingspanListing, findsOneWidget);
        expect(catanListing, findsNothing);
        expect(
          find.byKey(const ValueKey('marketplace-listing-listing-root')),
          findsNothing,
        );

        await tester.enterText(search, '');
        await _pumpUntil(tester, catanListing);
        final strategy = find.byKey(
          const ValueKey('marketplace-filter-Strategy Games'),
        );
        await tester.ensureVisible(strategy);
        await tester.tap(strategy);
        await _pumpUntilGone(tester, catanListing);
        await _pumpUntilGone(tester, wingspanListing);
        expect(tester.widget<ChoiceChip>(strategy).selected, isTrue);
        expect(
          find.byKey(const ValueKey('marketplace-listing-listing-root')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('marketplace-listing-listing-catan')),
          findsNothing,
        );
        expect(
          find.byKey(const ValueKey('marketplace-listing-listing-wingspan')),
          findsNothing,
        );

        await tester.ensureVisible(strategy);
        await tester.tap(strategy);
        await _pumpUntil(tester, catanListing);
        expect(tester.widget<ChoiceChip>(strategy).selected, isFalse);
        final root = find.byKey(
          const ValueKey('marketplace-listing-listing-root'),
        );
        await tester.ensureVisible(root);
        await tester.tap(root);
        await _pumpUntil(
          tester,
          find.byKey(const ValueKey('marketplace-detail-dialog-listing-root')),
        );
        expect(find.text('Good'), findsOneWidget);
        expect(
          find.text(
            'Asymmetric woodland strategy game. Faction boards for 3-4 players.',
          ),
          findsOneWidget,
        );
        await tester.tap(
          find.byKey(const ValueKey('marketplace-detail-close-listing-root')),
        );
        await tester.pump();
      } finally {
        await tester.runAsync(installed.dispose);
      }
    },
  );

  testWidgets(
    'paid-up members see Request loan from the real borrow guard while organizers and unpaid members do not',
    (tester) async {
      final installed = (await tester.runAsync(
        () => _install('phasec-marketplace-eligibility'),
      ))!;
      try {
        await tester.pumpWidget(_app(installed));
        await _selectPersona(tester, 'tabletop-member');
        final borrowIsAvailable = await tester.runAsync(() async {
          await installed.engine.applyTransition(
            workflowType: 'tabletop-club-dues-payment',
            instanceId: 'dues-2026-q3-member',
            transitionId: 'pay',
            personaId: 'tabletop-member',
          );
          final page = await installed.engine.queryInstances(
            tabId: 'marketplace',
            personaId: 'tabletop-member',
            limit: 100,
          );
          final catan = page.items.singleWhere(
            (item) => item.instanceId == 'listing-catan',
          );
          final actions = await installed.engine.availableTransitionsAsync(
            workflowType: catan.workflowType,
            instanceId: catan.instanceId,
            currentState: catan.currentState,
            instanceData: catan.instanceData,
            personaId: 'tabletop-member',
          );
          return actions.any((action) => action.id == 'borrow');
        });
        expect(borrowIsAvailable, isTrue);
        await _selectMarketplace(tester);
        await _pumpUntil(
          tester,
          find.byKey(
            const ValueKey('equipment-loan-action-borrow-listing-catan'),
          ),
        );
        expect(
          find.byKey(
            const ValueKey('equipment-loan-action-borrow-listing-catan'),
          ),
          findsOneWidget,
        );
        final catanListing = find.byKey(
          const ValueKey('marketplace-listing-listing-catan'),
        );
        expect(
          find.descendant(
            of: catanListing,
            matching: find.text('Request loan'),
          ),
          findsOneWidget,
        );

        await tester.tap(find.byKey(const ValueKey('persona-picker-button')));
        await tester.pump();
        await _pumpUntil(
          tester,
          find.byKey(const ValueKey('persona-option-tabletop-organizer')),
        );
        await tester.tap(
          find.byKey(const ValueKey('persona-option-tabletop-organizer')),
        );
        await tester.pump();
        await _selectMarketplace(tester);
        expect(
          find.byKey(
            const ValueKey('equipment-loan-action-borrow-listing-catan'),
          ),
          findsNothing,
        );
      } finally {
        await tester.runAsync(installed.dispose);
      }
    },
  );

  testWidgets('an unpaid member cannot see the guarded borrow action', (
    tester,
  ) async {
    final installed = (await tester.runAsync(
      () => _install('phasec-marketplace-unpaid'),
    ))!;
    try {
      await tester.pumpWidget(_app(installed));
      await _selectPersona(tester, 'tabletop-member');
      await _selectMarketplace(tester);
      await _pumpUntil(
        tester,
        find.byKey(const ValueKey('marketplace-listing-listing-catan')),
      );
      expect(
        find.byKey(
          const ValueKey('equipment-loan-action-borrow-listing-catan'),
        ),
        findsNothing,
      );
    } finally {
      await tester.runAsync(installed.dispose);
    }
  });

  testWidgets(
    'Marketplace local filters do not re-query the engine on every change',
    (tester) async {
      final installed = (await tester.runAsync(
        () => _install('phasec-marketplace-callback-count'),
      ))!;
      final experience = experienceForExtensionId(
        installed.community.extensionId,
        displayName: installed.community.displayName,
        experienceConfiguration: installed.community.experienceConfiguration,
      );
      final organizer = personasForExtensionId(
        experience.extensionId,
        experience: experience,
      ).singleWhere((persona) => persona.personaId == 'tabletop-organizer');
      final engine = _MarketplaceCountingEngine(installed.engine);
      try {
        await tester.pumpWidget(
          MaterialApp(
            home: ActiveIdentityScope(
              identity: ActiveIdentityContext(
                accountId: organizer.personaId,
                authApi: LocalAuthApi(),
                personaId: organizer.personaId,
              ),
              child: Scaffold(
                body: SingleChildScrollView(
                  child: EngineNativeMarketplaceSurface(
                    experience: experience,
                    persona: organizer,
                    accent: Colors.indigo,
                    engine: engine,
                  ),
                ),
              ),
            ),
          ),
        );
        await _pumpUntil(
          tester,
          find.byKey(const ValueKey('engine-native-marketplace-root')),
        );
        final search = find.byKey(const ValueKey('marketplace-search-field'));
        await _pumpUntil(tester, search);
        final initialQueries = engine.queries;
        expect(initialQueries, greaterThanOrEqualTo(1));

        for (final value in const ['W', 'Wi', 'Win']) {
          await tester.enterText(search, value);
          await tester.pump();
          expect(
            engine.queries,
            initialQueries,
            reason: 'local search update $value must not reload bindings',
          );
        }

        final strategy = find.byKey(
          const ValueKey('marketplace-filter-Strategy Games'),
        );
        await tester.ensureVisible(strategy);
        await tester.tap(strategy);
        await tester.pump();
        expect(
          engine.queries,
          initialQueries,
          reason: 'local category update must not reload bindings',
        );
      } finally {
        await tester.runAsync(installed.dispose);
      }
    },
  );
}
