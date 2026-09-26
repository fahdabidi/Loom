import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loom_communities_app_shell/loom_communities_app_shell.dart';
import 'package:loom_workflow_engine/loom_workflow_engine.dart';

/// workflow-grammar.md's `states` field table marks `label` REQUIRED and
/// "shown in the UI". This registry-driven sweep proves every archetype
/// family reachable through [EngineNativeArchetypeCard] renders it.
const _sentinelLabel = 'ZZ State Sentinel';

/// `table` is intercepted by part32's list surface before the dispatcher is
/// ever reached, so its state-label rendering is out of scope here and
/// tracked separately (see the SHELL ticket's "out of scope" section).
const _exemptFromDispatcherCoverage = <String>{'table'};

Future<(LocalWorkflowEngineApi, EngineNativeResolvedBinding)> _seedBinding({
  required String cardSurfaceFamily,
  String? workflowTypeOverride,
  RepeaterSpec? repeater,
}) async {
  final workflowType =
      workflowTypeOverride ?? 'state-badge-host-$cardSurfaceFamily';
  final engine = LocalWorkflowEngineApi(
    db: WorkflowDatabase.memory(),
    communityId: 'state-badge-$cardSurfaceFamily',
  );
  final machine = LoomWorkflowStateMachine.fromJson({
    'initialState': 'active',
    'states': {
      'active': {'label': _sentinelLabel},
    },
    'transitions': <Object?>[],
    'instanceDataSchema': <String, Object?>{},
  }, workflowType);
  engine.registerDefinition(machine);
  final instanceId = await engine.createInstance(
    workflowType: workflowType,
    fanId: 'state-badge-actor',
    initialInstanceData: <String, dynamic>{},
  );
  final instance = (await engine.queryInstances(
    tabId: 'admin',
    fanId: 'state-badge-actor',
  )).items.singleWhere((item) => item.instanceId == instanceId);

  return (
    engine,
    EngineNativeResolvedBinding(
      instance: instance,
      machine: machine,
      binding: RenderBinding(
        states: const ['active'],
        role: 'state-badge-actor',
        tabId: 'admin',
        cardSurfaceFamily: cardSurfaceFamily,
        bindingKind: 'primary',
        repeater: repeater,
        actions: const [],
      ),
      definitionBindingIndex: 0,
    ),
  );
}

Future<void> _expectSentinelLabelRenders(
  WidgetTester tester, {
  required String cardSurfaceFamily,
  String? workflowTypeOverride,
  RepeaterSpec? repeater,
}) async {
  final (engine, resolved) = await _seedBinding(
    cardSurfaceFamily: cardSurfaceFamily,
    workflowTypeOverride: workflowTypeOverride,
    repeater: repeater,
  );

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: EngineNativeArchetypeCard(
          contentKey: ValueKey(
            '$cardSurfaceFamily-${resolved.instance.instanceId}',
          ),
          resolved: resolved,
          engine: engine,
          communityExtensionId: 'state-badge-conformance',
          fanId: 'state-badge-actor',
          roleId: 'state-badge-actor',
          accent: Colors.indigo,
          onInstanceChanged: (_) {},
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();

  expect(
    find.text(_sentinelLabel),
    findsWidgets,
    reason:
        'cardSurfaceFamily "$cardSurfaceFamily" did not render its declared '
        'state label',
  );
}

void main() {
  for (final archetype in knownWorkflowArchetypes) {
    final id = archetype.id;
    if (_exemptFromDispatcherCoverage.contains(id)) continue;

    testWidgets('$id renders the declared state label', (tester) async {
      await _expectSentinelLabelRenders(
        tester,
        cardSurfaceFamily: id,
        // votePoll only reaches its bespoke ballot card when the binding
        // declares a repeater (see EngineNativeArchetypeCard's switch); a
        // repeater-less binding falls through to the generic card, which
        // already renders the label and would make this case vacuous.
        repeater: id == 'votePoll'
            ? const RepeaterSpec(source: 'candidates')
            : null,
      );
    });
  }

  testWidgets(
    'votePoll tournament-event attendance summary renders the declared '
    'state label',
    (tester) async {
      // The other votePoll-family surface: no repeater, workflowType
      // "tournament-event" -- VotePollArchetypeCard._buildTournamentAttendance.
      await _expectSentinelLabelRenders(
        tester,
        cardSurfaceFamily: 'votePoll',
        workflowTypeOverride: 'tournament-event',
      );
    },
  );
}
