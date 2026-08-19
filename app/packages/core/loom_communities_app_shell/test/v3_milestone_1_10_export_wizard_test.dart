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

const _cedarInstanceId = 'hoa-export-board-records-2026-q2';

const _chessPersona = 'chess-organizer';
const _cedarPersona = 'hoa-board';
const _adminTab = 'admin';

class _InstalledFixture {
  const _InstalledFixture(
    this.community,
    this.experience,
    this.engine,
    this.temp,
  );

  final LocalInstalledCommunity community;
  final LoomExperienceDefinition experience;
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

Future<_InstalledFixture> _installFixture(
  String extensionId,
  String fixtureRelative,
) async {
  final source =
      jsonDecode(
            stripJsonComments(_fixtureFile(fixtureRelative).readAsStringSync()),
          )
          as Map<String, dynamic>;
  source['extensionId'] = extensionId;
  final temp = await Directory.systemTemp.createTemp(
    'loom-exportwizard-$extensionId-',
  );
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
  final experience = experienceForExtensionId(
    community.extensionId,
    displayName: community.displayName,
    specVersion: community.specVersion,
    experienceConfiguration: community.experienceConfiguration,
  );
  final engine = await workflowEngineForExtensionId(community.extensionId);
  return _InstalledFixture(community, experience, engine, temp);
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
  final page = await engine.queryInstances(
    tabId: tabId,
    personaId: personaId,
    limit: 200,
  );
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

LoomWorkflowStateMachine _exportWorkflow(LoomExperienceDefinition experience) {
  final definitions = experience.workflowDefinitions;
  if (definitions == null) {
    throw StateError('Fixture has no workflow definitions');
  }
  return definitions.values.singleWhere(
    (definition) => definition.renderBindings.any(
      (binding) => binding.cardSurfaceFamily == 'exportWizard',
    ),
  );
}

LoomWorkflowSeedInstance _exportSeed(
  LoomExperienceDefinition experience,
  String workflowType,
) {
  final seeds = experience.workflowInstances;
  if (seeds == null) {
    throw StateError('Fixture has no workflow seed instances');
  }
  return seeds.singleWhere((seed) => seed.workflowType == workflowType);
}

String? _historyFieldKey(LoomWorkflowStateMachine workflow) {
  for (final key in const <String>[
    'exportHistory',
    'statusHistory',
    'auditHistory',
  ]) {
    if (workflow.instanceDataSchema.containsKey(key)) return key;
  }
  for (final entry in workflow.instanceDataSchema.entries) {
    if (entry.key.toLowerCase().endsWith('history') &&
        entry.value.type.toLowerCase() == 'list') {
      return entry.key;
    }
  }
  return null;
}

bool _isEmptyFixtureValue(Object? value) {
  if (value == null) return true;
  if (value is String) return value.trim().isEmpty;
  if (value is Iterable) return value.isEmpty;
  if (value is Map) return value.isEmpty;
  return false;
}

String _fixtureValueText(Object? value) {
  if (value == null) return '';
  if (value is Iterable) {
    return value
        .map((item) => item.toString())
        .where((item) => item.trim().isNotEmpty)
        .join(', ');
  }
  if (value is String) {
    final trimmed = value.trim();
    final looksLikeIdentifier =
        !trimmed.contains(' ') &&
        RegExp(r'^[A-Za-z][A-Za-z0-9_-]*$').hasMatch(trimmed);
    return looksLikeIdentifier ? humanizeIdentifierValue(value) : value;
  }
  if (value is bool) return value ? 'Yes' : 'No';
  return '$value';
}

int _fixtureValueLength(Object? value) {
  if (value is String) return value.length;
  if (value is Iterable) return value.length;
  return 0;
}

String _fixtureFactText(InstanceDataField field, Object? value) {
  final template = field.labelTemplate ?? '{value}';
  return template
      .replaceAll('{value.length}', '${_fixtureValueLength(value)}')
      .replaceAll('{value}', _fixtureValueText(value))
      .trim();
}

Map<String, String> _expectedTileFacts({
  required LoomWorkflowStateMachine workflow,
  required WorkflowInstance instance,
}) {
  final historyKey = _historyFieldKey(workflow);
  final expected = <String, String>{};
  for (final entry in workflow.instanceDataSchema.entries) {
    final key = entry.key;
    final field = entry.value;
    if (key == historyKey || !instance.instanceData.containsKey(key)) {
      continue;
    }
    if (field.displayContexts != null &&
        !field.displayContexts!.contains('tile')) {
      continue;
    }
    final hasFormula = field.formula?.trim().isNotEmpty == true;
    final hasLabelTemplate = field.labelTemplate?.trim().isNotEmpty == true;
    if (hasFormula && !hasLabelTemplate) continue;
    final value = instance.instanceData[key];
    if (field.hideWhenEmpty && _isEmptyFixtureValue(value)) continue;
    final text = _fixtureFactText(field, value);
    if (text.isNotEmpty) expected[key] = text;
  }
  return expected;
}

void _expectFactTexts(Finder factsFinder, Iterable<String> expectedTexts) {
  final counts = <String, int>{};
  for (final text in expectedTexts) {
    counts.update(text, (count) => count + 1, ifAbsent: () => 1);
  }
  for (final entry in counts.entries) {
    expect(
      find.descendant(of: factsFinder, matching: find.text(entry.key)),
      findsNWidgets(entry.value),
    );
  }
}

Future<void> _openTab(WidgetTester tester, String tabId) async {
  await _pumpUntilFound(tester, find.byKey(ValueKey('community-tab-$tabId')));
  await _tapVisible(tester, find.byKey(ValueKey('community-tab-$tabId')));
  await tester.pump(const Duration(milliseconds: 100));
}

void main() {
  testWidgets(
    'Chess fixture exportWizard renders schema-divergent core fields without assumptions',
    (tester) async {
      final installed = (await tester.runAsync(
        () => _installFixture(
          'ext_chess_exportwizard_chess',
          _chessFixtureRelative,
        ),
      ))!;
      addTearDown(() => tester.runAsync(installed.dispose));

      final exportWorkflow = _exportWorkflow(installed.experience);
      final exportSeed = _exportSeed(
        installed.experience,
        exportWorkflow.workflowType,
      );
      final chessInstanceId = exportSeed.instanceId;
      final instance = (await tester.runAsync(
        () => _queryInstance(
          engine: installed.engine,
          instanceId: chessInstanceId,
          personaId: _chessPersona,
          tabId: _adminTab,
        ),
      ))!;
      final currentState = exportWorkflow.states[instance.currentState];
      if (currentState == null) {
        throw StateError(
          'Export seed ${instance.instanceId} has undeclared state '
          '${instance.currentState}',
        );
      }
      final expectedFacts = _expectedTileFacts(
        workflow: exportWorkflow,
        instance: instance,
      );

      await tester.pumpWidget(_host(installed, _chessPersona));
      await _openTab(tester, _adminTab);
      final badgeFinder = find.byKey(
        ValueKey('export-wizard-state-badge-$chessInstanceId-tile'),
      );
      await _pumpUntilNoThrow(tester, badgeFinder);

      expect(
        find.descendant(
          of: badgeFinder,
          matching: find.text(currentState.label),
        ),
        findsOneWidget,
      );
      final factsFinder = find.byKey(
        ValueKey('export-wizard-facts-$chessInstanceId-tile'),
      );
      expect(factsFinder, findsOneWidget);
      // Fact-pill text includes the schema's whole labelTemplate, including
      // any prefix (and {value.length}) rather than only the seed's raw value.
      _expectFactTexts(factsFinder, expectedFacts.values);
      expect(
        find.byKey(
          ValueKey('export-wizard-history-heading-$chessInstanceId-tile'),
        ),
        findsNothing,
      );
      expect(find.text('checksum'), findsNothing);
      expect(find.text('transferId'), findsNothing);
      expect(find.text('transfer id'), findsNothing);

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
          ValueKey('export-wizard-$chessInstanceId-action-${actions.first.id}'),
        ),
      );
      for (final action in actions) {
        expect(
          find.byKey(
            ValueKey('export-wizard-$chessInstanceId-action-${action.id}'),
          ),
          findsOneWidget,
        );
      }
      final progressAction = actions.firstWhere(
        (action) {
          final targetState = action.to == null
              ? null
              : exportWorkflow.states[action.to];
          return targetState != null && !targetState.isTerminal;
        },
        orElse: () => throw StateError(
          'Could not locate an export action that enters a non-terminal state',
        ),
      );
      await _tapVisible(
        tester,
        find.byKey(
          ValueKey(
            'export-wizard-$chessInstanceId-action-${progressAction.id}',
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
      final nextState = exportWorkflow.states[progressAction.to]!;
      await _pumpUntilFound(
        tester,
        find.descendant(of: badgeFinder, matching: find.text(nextState.label)),
      );
      expect(
        find.descendant(of: badgeFinder, matching: find.text(nextState.label)),
        findsOneWidget,
      );

      final updatedInstance = (await tester.runAsync(
        () => _queryInstance(
          engine: installed.engine,
          instanceId: chessInstanceId,
          personaId: _chessPersona,
          tabId: _adminTab,
        ),
      ))!;
      final updatedFacts = _expectedTileFacts(
        workflow: exportWorkflow,
        instance: updatedInstance,
      );
      final effectFactKeys = <String>{
        for (final effect in progressAction.effects)
          if (effect.key != null && updatedFacts.containsKey(effect.key))
            effect.key!,
      };
      expect(effectFactKeys, isNotEmpty);
      _expectFactTexts(
        factsFinder,
        effectFactKeys.map((key) => updatedFacts[key]!),
      );
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
