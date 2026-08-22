import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loom_communities_app_shell/loom_communities_app_shell.dart';
import 'package:loom_workflow_engine/loom_workflow_engine.dart';

Widget _host(Widget child) => MaterialApp(home: Scaffold(body: child));

class _BespokeFixture {
  const _BespokeFixture({
    required this.family,
    required this.actionKey,
    required this.engine,
    required this.resolved,
  });

  final String family;
  final ValueKey<String> actionKey;
  final LocalWorkflowEngineApi engine;
  final EngineNativeResolvedBinding resolved;
}

Future<_BespokeFixture> _seed({
  required String family,
  required String transitionId,
}) async {
  final workflowType = 'input-$family';
  final engine = LocalWorkflowEngineApi(
    db: WorkflowDatabase.memory(),
    communityId: workflowType,
  );
  final machine = LoomWorkflowStateMachine.fromJson({
    'initialState': 'open',
    'states': {
      'open': {'label': 'Open'},
    },
    'transitions': [
      {
        'id': transitionId,
        'label': 'Configure',
        'from': ['open'],
        'to': null,
        'inputs': {
          'selection': {'type': 'list', 'required': true},
        },
        'effects': [
          {'op': 'set', 'key': 'selection', 'value': '{input.selection}'},
        ],
      },
    ],
    'instanceDataSchema': {
      'title': {
        'type': 'text',
        'labelTemplate': '{value}',
        'displayContexts': ['tile'],
      },
      'query': {
        'type': 'text',
        'labelTemplate': '{value}',
        'displayContexts': ['tile'],
      },
      'answer': {
        'type': 'textarea',
        'labelTemplate': '{value}',
        'displayContexts': ['tile'],
      },
      'selection': {
        'type': 'list',
        'labelTemplate': '{value.length} selected',
        'displayContexts': ['tile'],
      },
      'savedFanIds': {'type': 'fanId[]'},
    },
  }, workflowType);
  engine.registerDefinition(machine);
  final instanceId = await engine.createInstance(
    workflowType: workflowType,
    fanId: 'member',
    initialInstanceData: {
      'title': 'Package-defined action',
      'query': 'What should be selected?',
      'answer': 'Nothing yet',
      'selection': <String>['original'],
      'savedFanIds': <String>[],
    },
  );
  final instance = (await engine.queryInstances(
    tabId: 'test',
    fanId: 'member',
  )).items.singleWhere((item) => item.instanceId == instanceId);
  final binding = RenderBinding(
    tabId: 'test',
    states: const ['open'],
    role: 'member',
    cardSurfaceFamily: family,
    bindingKind: 'primary',
  );
  return _BespokeFixture(
    family: family,
    actionKey: switch (family) {
      'equipment-loan' => ValueKey(
        'equipment-loan-action-$transitionId-$instanceId',
      ),
      'documentLibrary' => ValueKey(
        'document-library-$instanceId-action-$transitionId',
      ),
      'exportWizard' => ValueKey(
        'export-wizard-$instanceId-action-$transitionId',
      ),
      'searchAiAnswer' => ValueKey(
        'searchAiAnswer-$instanceId-action-$transitionId',
      ),
      _ => throw StateError('Unsupported family $family'),
    },
    engine: engine,
    resolved: EngineNativeResolvedBinding(
      instance: instance,
      machine: machine,
      binding: binding,
      definitionBindingIndex: 0,
    ),
  );
}

Widget _card(_BespokeFixture fixture) => switch (fixture.family) {
  'equipment-loan' => EquipmentLoanArchetypeCard(
    resolved: fixture.resolved,
    engine: fixture.engine,
    fanId: 'member',
    accent: Colors.blue,
    onInstanceChanged: (_) {},
  ),
  'documentLibrary' => DocumentLibraryArchetypeCard(
    resolved: fixture.resolved,
    engine: fixture.engine,
    fanId: 'member',
    accent: Colors.blue,
    onInstanceChanged: (_) {},
  ),
  'exportWizard' => ExportWizardArchetypeCard(
    resolved: fixture.resolved,
    engine: fixture.engine,
    fanId: 'member',
    accent: Colors.blue,
    onInstanceChanged: (_) {},
  ),
  'searchAiAnswer' => SearchAiAnswerArchetypeCard(
    resolved: fixture.resolved,
    engine: fixture.engine,
    fanId: 'member',
    accent: Colors.blue,
    onInstanceChanged: (_) {},
  ),
  _ => throw StateError('Unsupported family ${fixture.family}'),
};

void main() {
  testWidgets('every exposed bespoke card collects declared inputs', (
    tester,
  ) async {
    final fixtures = <_BespokeFixture>[
      await _seed(family: 'equipment-loan', transitionId: 'borrow'),
      await _seed(family: 'documentLibrary', transitionId: 'save-resource'),
      await _seed(family: 'exportWizard', transitionId: 'configure'),
      await _seed(family: 'searchAiAnswer', transitionId: 'configure'),
    ];

    for (final fixture in fixtures) {
      await tester.pumpWidget(_host(_card(fixture)));
      await tester.pumpAndSettle();
      final action = find.byKey(fixture.actionKey);
      expect(action, findsOneWidget, reason: fixture.family);

      await tester.tap(action);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('generic-transition-input-dialog')),
        findsOneWidget,
        reason: fixture.family,
      );
      await tester.enterText(
        find.byKey(const ValueKey('generic-transition-input-selection')),
        'alpha, beta',
      );
      await tester.tap(
        find.byKey(const ValueKey('generic-transition-input-confirm')),
      );
      await tester.pumpAndSettle();

      final updated =
          (await fixture.engine.queryInstances(
            tabId: 'test',
            fanId: 'member',
          )).items.singleWhere(
            (item) => item.instanceId == fixture.resolved.instance.instanceId,
          );
      expect(updated.instanceData['selection'], <String>[
        'alpha',
        'beta',
      ], reason: fixture.family);
    }
  });
}
