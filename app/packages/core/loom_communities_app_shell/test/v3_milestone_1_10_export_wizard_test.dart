import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loom_communities_app_shell/loom_communities_app_shell.dart';
import 'package:loom_demo_local_backend/loom_demo_local_backend.dart';
import 'package:loom_ux_judges/src/validator/jsonc.dart';
import 'package:loom_workflow_engine/loom_workflow_engine.dart';

import 'authz_p6_test_helpers.dart';

const _chessFixtureRelative =
    'docs/references/communities/Loom_Communities_Workflow_Engine_ChessClub_Example.jsonc';
const _cedarFixtureRelative =
    'docs/references/communities/Loom_Communities_Workflow_Engine_CedarCommonsHOA_Example.jsonc';

const _chessInstanceId = 'chess-export-august';
const _cedarInstanceId = 'hoa-export-board-records-2026-q2';

const _chessPersona = 'chess-organizer';
const _cedarPersona = 'hoa-board';
const _adminTab = 'admin';

class _InstalledFixture {
  const _InstalledFixture(this.community, this.engine, this.temp);

  final LocalInstalledCommunity community;
  final WorkflowEngineApi engine;
  final Directory temp;

  Future<void> dispose() => temp.delete(recursive: true);
}

File _fixtureFile(String relativePath) {
  var directory = Directory.current;
  for (var i = 0; i < 8; i++) {
    final candidate = File('${directory.path}/$relativePath');
    if (candidate.existsSync()) {
      return candidate;
    }
    directory = directory.parent;
  }
  throw StateError('Could not locate fixture: $relativePath');
}

Future<_InstalledFixture> _installFixture(String extensionId, String fixtureRelative) async {
  final source = jsonDecode(
    stripJsonComments(_fixtureFile(fixtureRelative).readAsStringSync()),
  ) as Map<String, dynamic>;
  source['extensionId'] = extensionId;
  final temp = await Directory.systemTemp.createTemp('loom-exportwizard-$extensionId-');
  final init = File('${temp.path}/community.loom-init.zip');
  final extension = File('${temp.path}/community.loom-extension.zip');
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
  // Register the engine-native store before requesting the engine --
  // workflowEngineForExtensionId throws "No engine-native experience is
  // installed" without this (confirmed against the established pattern in
  // v3_milestone_phaseb_votepoll_archetype_test.dart's own _install helper).
  experienceForExtensionId(
    community.extensionId,
    displayName: community.displayName,
    experienceConfiguration: community.experienceConfiguration,
  );
  final engine = await workflowEngineForExtensionId(community.extensionId);
  return _InstalledFixture(community, engine, temp);
}

Widget _host(_InstalledFixture installed, String personaId) => MaterialApp(
  home: LocalExtensionScreen(
    community: installed.community,
    seedDataFiles: const [],
    authApi: activeAuthForInstalledCommunity(
      community: installed.community,
      personaTypeId: personaId,
    ),
  ),
);

Future<void> _pumpUntilFound(WidgetTester tester, Finder finder) async {
  for (var attempt = 0; attempt < 120; attempt += 1) {
    if (finder.evaluate().isNotEmpty) return;
    // A plain tester.pump() only advances the fake-async test zone -- it
    // never lets the real sqlite-backed local-demo engine's own async work
    // (community entry gate check, engine queries) actually complete.
    // Confirmed by direct diagnostic: without this real-async yield, the
    // widget tree stays stuck on the "community-entry-checking" gate
    // indefinitely, no matter how many plain pumps run.
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump(const Duration(milliseconds: 50));
  }
  await tester.pump(const Duration(milliseconds: 50));
}

Future<void> _pumpUntilNoThrow(WidgetTester tester, Finder finder) async {
  await _pumpUntilFound(tester, finder);
  expect(finder, findsOneWidget);
}

Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pump();
  await tester.tap(finder);
  await tester.pump();
}

Future<WorkflowInstance> _queryInstance({
  required WorkflowEngineApi engine,
  required String instanceId,
  required String personaId,
  required String tabId,
}) async {
  final page = await engine.queryInstances(tabId: tabId, personaId: personaId, limit: 200);
  return page.items.firstWhere((item) => item.instanceId == instanceId);
}

Future<List<LoomWorkflowTransition>> _queryTransitions({
  required WorkflowEngineApi engine,
  required WorkflowInstance instance,
  required String personaId,
}) => engine.availableTransitionsAsync(
  workflowType: instance.workflowType,
  instanceId: instance.instanceId,
  currentState: instance.currentState,
  instanceData: instance.instanceData,
  personaId: personaId,
);

Future<void> _openTab(WidgetTester tester, String tabId) async {
  await _pumpUntilFound(
    tester,
    find.byKey(ValueKey('community-tab-$tabId')),
  );
  await _tapVisible(tester, find.byKey(ValueKey('community-tab-$tabId')));
  await tester.pump(const Duration(milliseconds: 100));
}

void main() {
  testWidgets(
    'Chess fixture exportWizard renders schema-divergent core fields without assumptions',
    (tester) async {
      final installed = (await tester.runAsync(
        () => _installFixture('ext_chess_exportwizard_chess', _chessFixtureRelative),
      ))!;
      addTearDown(() => tester.runAsync(installed.dispose));

      await tester.pumpWidget(_host(installed, _chessPersona));
      await _openTab(tester, _adminTab);
      final badgeFinder = find.byKey(
        const ValueKey('export-wizard-state-badge-$_chessInstanceId-tile'),
      );
      await _pumpUntilNoThrow(tester, badgeFinder);

      expect(find.byKey(const ValueKey('export-wizard-facts-$_chessInstanceId-tile')), findsOneWidget);
      expect(find.text('Ready to export'), findsOneWidget);
      expect(find.text('August ladder and match archive'), findsOneWidget);
      expect(find.text('Ready to generate'), findsOneWidget);
      // exportScope's labelTemplate is "Scope: {value}" -- the fact-pill
      // renderer always includes the template's own prefix text.
      expect(
        find.text('Scope: match results, ranking rows, pairing history'),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('export-wizard-history-heading-$_chessInstanceId-tile')),
        findsNothing,
      );
      expect(find.text('checksum'), findsNothing);
      expect(find.text('transferId'), findsNothing);
      expect(find.text('transfer id'), findsNothing);

      final instance = (await tester.runAsync(
        () => _queryInstance(
          engine: installed.engine,
          instanceId: _chessInstanceId,
          personaId: _chessPersona,
          tabId: _adminTab,
        ),
      ))!;
      final actions = (await tester.runAsync(
        () => _queryTransitions(
          engine: installed.engine,
          instance: instance,
          personaId: _chessPersona,
        ),
      ))!;
      expect(actions, isNotEmpty);
      // The widget's own action-button load is a separate real async round
      // trip from the query above -- wait for it to settle before checking.
      await _pumpUntilNoThrow(
        tester,
        find.byKey(
          ValueKey(
            'export-wizard-$_chessInstanceId-action-${actions.first.id}',
          ),
        ),
      );
      for (final action in actions) {
        expect(
          find.byKey(
            ValueKey('export-wizard-$_chessInstanceId-action-${action.id}'),
          ),
          findsOneWidget,
        );
      }
      await _tapVisible(
        tester,
        find.byKey(
          const ValueKey(
            'export-wizard-$_chessInstanceId-action-generate-export',
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
      await _pumpUntilFound(
        tester,
        find.text('Export generated; checksum pending platform verification'),
      );
      expect(find.text('Export generated; checksum pending platform verification'), findsOneWidget);
    },
  );

  testWidgets(
    'Cedar fixture exportWizard renders divergent instance fields and handles rolled-back flow',
    (tester) async {
      final installed = (await tester.runAsync(
        () => _installFixture('ext_hoa_exportwizard_hoa', _cedarFixtureRelative),
      ))!;
      addTearDown(() => tester.runAsync(installed.dispose));

      await tester.pumpWidget(_host(installed, _cedarPersona));
      await _openTab(tester, _adminTab);
      final badgeFinder = find.byKey(
        const ValueKey('export-wizard-state-badge-$_cedarInstanceId-tile'),
      );
      await _pumpUntilNoThrow(tester, badgeFinder);

      expect(find.byKey(const ValueKey('export-wizard-facts-$_cedarInstanceId-tile')), findsOneWidget);
      expect(find.text('Ready for download'), findsOneWidget);
      expect(
        find.text('Board records through 2026 Q2'),
        findsOneWidget,
      );
      expect(
        find.text('Approved minutes, governing-document versions, architectural case audit, and offline payment ledger'),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('export-wizard-history-heading-$_cedarInstanceId-tile')),
        findsOneWidget,
      );
      expect(
        find.byKey(
          const ValueKey('export-wizard-history-$_cedarInstanceId-tile-0'),
        ),
        findsOneWidget,
      );
      // Kebab-case values that look like identifiers get humanized by the
      // shared fact-pill renderer's _valueText (manual-review -> Manual
      // Review, awaiting-platform -> Awaiting Platform) -- confirmed via
      // part18_marketplace_rendering.dart's _looksLikeIdentifierValue/
      // humanizeIdentifierValue.
      expect(find.text('Verification: Manual Review'), findsOneWidget);
      expect(find.text('Checksum status: Awaiting Platform'), findsOneWidget);
      expect(find.text('Transfer ID:'), findsNothing);

      var instance = (await tester.runAsync(
        () => _queryInstance(
          engine: installed.engine,
          instanceId: _cedarInstanceId,
          personaId: _cedarPersona,
          tabId: _adminTab,
        ),
      ))!;
      final readyActions = (await tester.runAsync(
        () => _queryTransitions(
          engine: installed.engine,
          instance: instance,
          personaId: _cedarPersona,
        ),
      ))!;
      final beginTransfer = readyActions.firstWhere(
        (action) => action.to == 'transferring',
        orElse: () => throw StateError(
          'Could not locate a transition from ready that enters transferring',
        ),
      );
      final beginTransferKey = ValueKey(
        'export-wizard-$_cedarInstanceId-action-${beginTransfer.id}',
      );
      await _pumpUntilNoThrow(tester, find.byKey(beginTransferKey));
      await _tapVisible(tester, find.byKey(beginTransferKey));
      await _pumpUntilFound(
        tester,
        find.text('Transfer in progress'),
      );
      instance = (await tester.runAsync(
        () => _queryInstance(
          engine: installed.engine,
          instanceId: _cedarInstanceId,
          personaId: _cedarPersona,
          tabId: _adminTab,
        ),
      ))!;
      final transferringActions = (await tester.runAsync(
        () => _queryTransitions(
          engine: installed.engine,
          instance: instance,
          personaId: _cedarPersona,
        ),
      ))!;
      final recordTransfer = transferringActions.firstWhere(
        (action) => action.to == 'transferred',
        orElse: () => throw StateError('Could not locate transfer-complete transition'),
      );
      final recordTransferKey = ValueKey(
        'export-wizard-$_cedarInstanceId-action-${recordTransfer.id}',
      );
      await _pumpUntilNoThrow(tester, find.byKey(recordTransferKey));
      await _tapVisible(tester, find.byKey(recordTransferKey));
      await _pumpUntilFound(
        tester,
        find.text('Transferred'),
      );

      instance = (await tester.runAsync(
        () => _queryInstance(
          engine: installed.engine,
          instanceId: _cedarInstanceId,
          personaId: _cedarPersona,
          tabId: _adminTab,
        ),
      ))!;
      final transferredActions = (await tester.runAsync(
        () => _queryTransitions(
          engine: installed.engine,
          instance: instance,
          personaId: _cedarPersona,
        ),
      ))!;
      final rollback = transferredActions.firstWhere(
        (action) => action.to == 'rolled-back',
        orElse: () => throw StateError('Could not locate rollback transition'),
      );
      final rollbackKey = ValueKey(
        'export-wizard-$_cedarInstanceId-action-${rollback.id}',
      );
      await _pumpUntilNoThrow(tester, find.byKey(rollbackKey));
      await _tapVisible(tester, find.byKey(rollbackKey));
      await _pumpUntilFound(
        tester,
        find.byKey(
          const ValueKey('export-wizard-off-path-$_cedarInstanceId-tile'),
        ),
      );
      expect(
        find.byKey(
          const ValueKey('export-wizard-off-path-$_cedarInstanceId-tile'),
        ),
        findsOneWidget,
      );
      expect(find.text('Rollback requested'), findsOneWidget);
    },
  );
}
