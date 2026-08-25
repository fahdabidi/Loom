import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loom_communities_app_shell/loom_communities_app_shell.dart';
import 'package:loom_workflow_engine/loom_workflow_engine.dart';

Widget _host(Widget child) => MaterialApp(home: Scaffold(body: child));

Future<WorkflowInstance> _instance(
  WorkflowEngineApi engine,
  String instanceId,
) async => (await engine.queryInstances(
  tabId: 'test',
  fanId: 'camera-club-member',
)).items.singleWhere((instance) => instance.instanceId == instanceId);

LoomWorkflowStateMachine _critiqueMachine() =>
    LoomWorkflowStateMachine.fromJson({
      'initialState': 'submitted',
      'states': {
        'submitted': {'label': 'Submitted for critique', 'tone': 'info'},
        'withdrawn': {
          'label': 'Critique withdrawn',
          'tone': 'negative',
          'isTerminal': true,
        },
      },
      'transitions': [
        {
          'id': 'withdraw',
          'label': 'Withdraw critique',
          'tone': 'destructive',
          'from': ['submitted'],
          'to': 'withdrawn',
        },
      ],
      'instanceDataSchema': {
        'photoTitle': {
          'type': 'text',
          'labelTemplate': '{value}',
          'displayContexts': ['tile'],
        },
        'commentCount': {
          'type': 'number',
          'labelTemplate': '{value} comments',
          'displayContexts': ['tile'],
        },
      },
    }, 'critique-submission');

Future<(LocalWorkflowEngineApi, WorkflowInstance)> _seedCritique() async {
  final engine = LocalWorkflowEngineApi(
    db: WorkflowDatabase.memory(),
    communityId: 'completed-action-critique',
  );
  engine.registerDefinition(_critiqueMachine());
  final instanceId = await engine.createInstance(
    workflowType: 'critique-submission',
    fanId: 'camera-club-member',
    initialInstanceData: {
      'photoTitle': 'Lighthouse portrait',
      'commentCount': 2,
    },
  );
  return (engine, await _instance(engine, instanceId));
}

Future<(LocalWorkflowEngineApi, EngineNativeResolvedBinding)>
_seedDamageReport() async {
  const workflowType = 'gear-loan-request';
  final machine = LoomWorkflowStateMachine.fromJson({
    'initialState': 'published',
    'states': {
      'published': {'label': 'Gear listing', 'tone': 'positive'},
    },
    'transitions': [
      {
        'id': 'report-damage',
        'label': 'Report damage',
        'tone': 'secondary',
        'from': ['published'],
        'to': null,
        'inputs': {
          'issueDescription': {'type': 'text', 'required': true},
        },
        'effects': [
          {
            'op': 'append',
            'key': 'issueLog',
            'value': {
              'reporterFanId': '\$actor',
              'description': '{input.issueDescription}',
              'reportedAt': '\$timestamp',
            },
          },
        ],
      },
    ],
    'instanceDataSchema': {
      'title': {
        'type': 'text',
        'labelTemplate': '{value}',
        'displayContexts': ['tile'],
      },
      'issueLog': {
        'type': 'list',
        'writableBy': 'effect',
        'labelTemplate': '{value.length} reported issues',
        'hideWhenEmpty': true,
        'displayContexts': ['detail'],
      },
    },
  }, workflowType);
  final engine = LocalWorkflowEngineApi(
    db: WorkflowDatabase.memory(),
    communityId: 'completed-action-damage-report',
  );
  engine.registerDefinition(machine);
  final instanceId = await engine.createInstance(
    workflowType: workflowType,
    fanId: 'camera-club-member',
    initialInstanceData: {
      'title': 'Canon 70-200mm f/2.8 lens',
      'issueLog': <Map<String, String>>[],
    },
  );
  final instance = await _instance(engine, instanceId);
  return (
    engine,
    EngineNativeResolvedBinding(
      instance: instance,
      machine: machine,
      binding: RenderBinding(
        tabId: 'marketplace',
        states: const ['published'],
        role: 'any',
        cardSurfaceFamily: 'equipment-loan',
        bindingKind: 'primary',
      ),
      definitionBindingIndex: 0,
    ),
  );
}

void main() {
  testWidgets('withdrawn critique renders its declared result state', (
    tester,
  ) async {
    final (engine, instance) = await _seedCritique();
    final machine = _critiqueMachine();

    await tester.pumpWidget(
      _host(
        GenericWorkflowInstanceCard(
          instance: instance,
          machine: machine,
          engine: engine,
          fanId: 'camera-club-member',
        ),
      ),
    );
    await tester.pumpAndSettle();

    final withdraw = find.byKey(
      ValueKey('generic-instance-${instance.instanceId}-action-withdraw'),
    );
    expect(withdraw, findsOneWidget);
    await tester.tap(withdraw);
    await tester.pumpAndSettle();

    expect(
      find.byKey(ValueKey('generic-instance-state-${instance.instanceId}')),
      findsOneWidget,
    );
    expect(find.text('Critique withdrawn'), findsOneWidget);
  });

  testWidgets('reported damage shows its issue count on the marketplace tile', (
    tester,
  ) async {
    final (engine, resolved) = await _seedDamageReport();
    final instanceId = resolved.instance.instanceId;

    await tester.pumpWidget(
      _host(
        EquipmentLoanArchetypeCard(
          resolved: resolved,
          engine: engine,
          fanId: 'camera-club-member',
          accent: Colors.blue,
          onInstanceChanged: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    final reportDamage = find.byKey(
      ValueKey('equipment-loan-$instanceId-action-report-damage'),
    );
    expect(reportDamage, findsOneWidget);
    await tester.tap(reportDamage);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('generic-transition-input-issueDescription')),
      'Front element is scratched.',
    );
    await tester.tap(
      find.byKey(const ValueKey('generic-transition-input-confirm')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(ValueKey('equipment-loan-tile-outcome-$instanceId-issueLog')),
      findsOneWidget,
    );
    expect(find.text('1 reported issues'), findsOneWidget);
  });
}
