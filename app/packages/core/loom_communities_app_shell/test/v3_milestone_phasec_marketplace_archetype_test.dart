import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loom_communities_app_shell/loom_communities_app_shell.dart';
import 'package:loom_demo_local_backend/loom_demo_local_backend.dart';
import 'package:loom_ux_judges/src/validator/jsonc.dart';
import 'package:loom_workflow_engine/loom_workflow_engine.dart';

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
  final personaPicker = find.byKey(const ValueKey('persona-picker-button'));
  await _pumpUntil(tester, personaPicker);
  await tester.tap(personaPicker);
  await tester.pump();
  final option = find.byKey(ValueKey('persona-option-$personaId'));
  await _pumpUntil(tester, option);
  await tester.tap(option);
  await tester.pump();
}

Widget _app(_InstalledTabletop installed) => MaterialApp(
  home: LocalExtensionScreen(
    community: installed.community,
    seedDataFiles: const [],
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
        final gloomhavenListing = find.byKey(
          const ValueKey('marketplace-listing-share-gloomhaven'),
        );
        expect(gloomhavenListing, findsOneWidget);
        expect(find.text('onLoan'), findsOneWidget);
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
        final wingspanListing = find.byKey(
          const ValueKey('marketplace-listing-listing-wingspan'),
        );
        final catanListing = find.byKey(
          const ValueKey('marketplace-listing-listing-catan'),
        );
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
          find.descendant(of: catanListing, matching: find.text('Request loan')),
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
      setCurrentActiveAccountId(organizer.personaId);
      try {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
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
        setCurrentActiveAccountId(null);
        await tester.runAsync(installed.dispose);
      }
    },
  );
}
