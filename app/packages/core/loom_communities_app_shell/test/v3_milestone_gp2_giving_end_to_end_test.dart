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

Future<_InstalledTabletop> _install(String extensionId) async {
  final source =
      jsonDecode(stripJsonComments(_fixtureFile().readAsStringSync()))
          as Map<String, dynamic>;
  source['extensionId'] = extensionId;
  final temp = await Directory.systemTemp.createTemp('loom-gp2-$extensionId-');
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
    // Resolve the shared engine before pumping the widget, matching the
    // engine-native test-install pattern and allowing the test to query the
    // persisted result after the UI transition completes.
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

Future<void> _selectTab(
  WidgetTester tester, {
  required String tabId,
  required String rootKey,
}) async {
  final tab = find.byKey(ValueKey('community-tab-$tabId'));
  await _pumpUntil(tester, tab);
  await tester.ensureVisible(tab);
  await tester.tap(tab);
  await _pumpUntil(tester, find.byKey(ValueKey(rootKey)));
}

void main() {
  testWidgets(
    'Giving projects the frozen dues instance through the generic engine-native list',
    (tester) async {
      final installed = (await tester.runAsync(
        () => _install('gp2-giving'),
      ))!;
      try {
        await tester.pumpWidget(
          MaterialApp(
            home: LocalExtensionScreen(
              community: installed.community,
              seedDataFiles: const [],
            ),
          ),
        );
        final personaPicker = find.byKey(
          const ValueKey('persona-picker-button'),
        );
        await _pumpUntil(tester, personaPicker);
        await tester.tap(personaPicker);
        await tester.pump();
        final member = find.byKey(
          const ValueKey('persona-option-tabletop-member'),
        );
        await _pumpUntil(tester, member);
        await tester.tap(member);
        await tester.pump();
        final givingTab = find.byKey(const ValueKey('community-tab-giving'));
        await _pumpUntil(tester, givingTab);
        await tester.ensureVisible(givingTab);
        await tester.tap(givingTab);
        await tester.pump();

        await _pumpUntil(
          tester,
          find.byKey(const ValueKey('engine-native-list-root-giving')),
        );
        expect(
          find.byKey(
            const ValueKey(
              'engine-native-list-item-giving-dues-2026-q3-member-0',
            ),
          ),
          findsOneWidget,
        );
        expect(find.byType(GenericWorkflowInstanceCard), findsOneWidget);
        expect(find.text(r'$15.00'), findsOneWidget);
        expect(find.text('Quarterly club dues'), findsOneWidget);

        // The app bar is community chrome and intentionally stays at the
        // community accent. Card/header surfaces in the selected tab must use
        // the resolved community -> tab theme instead.
        final experience = experienceForExtensionId(
          installed.community.extensionId,
          displayName: installed.community.displayName,
          experienceConfiguration: installed.community.experienceConfiguration,
        );
        final givingTheme = LoomCardTheme.merge(
          LoomCardTheme.merge(
            LoomCardTheme.deriveFromAccent(
              const Color(0xffC4703F),
              lightSurface: true,
            ),
            experience.themeOverride,
          ),
          experience.tabThemeOverrides['giving'],
        );
        expect(givingTheme.accent, const Color(0xff8A5A34));
        expect(
          tester.widget<AppBar>(find.byType(AppBar)).backgroundColor,
          const Color(0xffC4703F),
        );
        final selectedGivingHeader = tester.widget<DecoratedBox>(
          find.byKey(const ValueKey('selected-tab-giving')),
        );
        expect(
          (selectedGivingHeader.decoration as BoxDecoration).color,
          givingTheme.resolvedFill,
        );
        final duesCard = find.byKey(
          const ValueKey('generic-instance-card-dues-2026-q3-member'),
        );
        expect(
          find.descendant(of: duesCard, matching: find.text('receiptStatus')),
          findsNothing,
        );
        final pay = find.byKey(
          const ValueKey('generic-instance-dues-2026-q3-member-action-pay'),
        );
        await _pumpUntil(tester, pay);
        expect(pay, findsOneWidget);
        expect(find.text('Pay \$15'), findsOneWidget);
        expect(
          tester
              .widget<FilledButton>(pay)
              .style
              ?.backgroundColor
              ?.resolve(const {}),
          const Color(0xff8A5A34),
        );
        await tester.ensureVisible(pay);
        await tester.tap(pay);
        await _pumpUntilGone(tester, pay);

        // The effect-owned receipt status has no author-facing label in the
        // frozen schema, so it must not fall back to rendering its key.
        expect(
          find.descendant(of: duesCard, matching: find.text('receiptStatus')),
          findsNothing,
        );

        final paid = await tester.runAsync(() async {
          final page = await installed.engine.queryInstances(
            tabId: 'giving',
            personaId: 'tabletop-member',
            limit: 100,
          );
          return page.items.singleWhere(
            (item) => item.instanceId == 'dues-2026-q3-member',
          );
        });
        expect(paid!.currentState, 'paid');
        expect(paid.instanceData['receiptStatus'], 'complete');
        expect(paid.instanceData['paidAt'], isNotNull);
        expect('${paid.instanceData['paidAt']}', isNotEmpty);
      } finally {
        await tester.runAsync(installed.dispose);
      }
    },
  );

  testWidgets(
    'Giving pay unlocks Marketplace borrow through the shared engine UI',
    (tester) async {
      final installed = (await tester.runAsync(
        () => _install('phase-d4-giving-marketplace'),
      ))!;
      try {
        await tester.pumpWidget(
          MaterialApp(
            home: LocalExtensionScreen(
              community: installed.community,
              seedDataFiles: const [],
            ),
          ),
        );
        await _selectPersona(tester, 'tabletop-member');

        await _selectTab(
          tester,
          tabId: 'marketplace',
          rootKey: 'engine-native-marketplace-root',
        );
        final catan = find.byKey(
          const ValueKey('marketplace-listing-listing-catan'),
        );
        final catanJoinQueue = find.byKey(
          const ValueKey(
            'equipment-loan-listing-catan-action-join-queue',
          ),
        );
        final catanBorrow = find.byKey(
          const ValueKey('equipment-loan-action-borrow-listing-catan'),
        );
        await _pumpUntil(tester, catan);
        await _pumpUntil(tester, catanJoinQueue);
        expect(catan, findsOneWidget);
        expect(catanBorrow, findsNothing);
        expect(
          find.descendant(of: catan, matching: find.text('Request loan')),
          findsNothing,
        );
        expect(tester.takeException(), isNull);

        await _selectTab(
          tester,
          tabId: 'giving',
          rootKey: 'engine-native-list-root-giving',
        );
        final pay = find.byKey(
          const ValueKey('generic-instance-dues-2026-q3-member-action-pay'),
        );
        await _pumpUntil(tester, pay);
        expect(find.text('Pay \$15'), findsOneWidget);
        await tester.ensureVisible(pay);
        await tester.tap(pay);
        await _pumpUntilGone(tester, pay);
        expect(tester.takeException(), isNull);

        await _selectTab(
          tester,
          tabId: 'marketplace',
          rootKey: 'engine-native-marketplace-root',
        );
        await _pumpUntil(tester, catanBorrow);
        expect(catanBorrow, findsOneWidget);
        expect(
          find.descendant(of: catan, matching: find.text('Request loan')),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      } finally {
        await tester.runAsync(installed.dispose);
      }
    },
  );
}
