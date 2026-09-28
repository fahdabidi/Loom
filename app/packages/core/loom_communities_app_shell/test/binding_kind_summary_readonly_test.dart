// `bindingKind: "summary"` (render-bindings.md:553-560) means "compact,
// read-only card": no transition affordances, no editors, no instance-scoped
// create buttons. `bindingKind: "primary"` means the opposite. Nothing in the
// shell read `bindingKind` before this suite existed -- these tests exist to
// keep that true.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loom_communities_app_shell/loom_communities_app_shell.dart';
import 'package:loom_workflow_engine/loom_workflow_engine.dart';

Widget _host(Widget child) => MaterialApp(home: Scaffold(body: child));

LoomWorkflowStateMachine _machine() => LoomWorkflowStateMachine.fromJson({
  'initialState': 'open',
  'states': {
    'open': {
      'label': 'Open',
      'editableFields': ['notes'],
      'editGuard': {
        'allowedRoleIds': ['member'],
      },
    },
  },
  'transitions': [
    {
      'id': 'finish',
      'label': 'Finish',
      'from': ['open'],
      'to': 'done',
    },
  ],
  'instanceDataSchema': {
    'title': {
      'type': 'text',
      'labelTemplate': '{value}',
      'displayContexts': ['tile', 'detail'],
    },
    'notes': {'type': 'text'},
  },
}, 'summary-readonly-test');

const _createAction = WorkflowAction(
  kind: 'create',
  scope: 'instance',
  presentation: 'button',
  byRoleIds: ['member'],
  workflowType: 'related-type',
  label: 'Create related',
);

Future<(LocalWorkflowEngineApi, WorkflowInstance)> _seed() async {
  final api = LocalWorkflowEngineApi(
    db: WorkflowDatabase.memory(),
    communityId: 'summary-readonly',
  );
  final machine = _machine();
  api.registerDefinition(machine);
  final id = await api.createInstance(
    workflowType: 'summary-readonly-test',
    fanId: 'member-1',
    initialInstanceData: {'title': 'Visible Title', 'notes': 'initial notes'},
  );
  final instance = (await api.queryInstances(
    tabId: 'any',
    fanId: 'member-1',
  )).items.singleWhere((row) => row.instanceId == id);
  return (api, instance);
}

EngineNativeResolvedBinding _resolved(
  WorkflowInstance instance,
  LoomWorkflowStateMachine machine,
  String bindingKind, {
  String cardSurfaceFamily = 'genericFallback',
  List<WorkflowAction> actions = const [_createAction],
}) => EngineNativeResolvedBinding(
  instance: instance,
  machine: machine,
  binding: RenderBinding(
    states: const ['open'],
    role: 'member',
    tabId: 'home',
    cardSurfaceFamily: cardSurfaceFamily,
    bindingKind: bindingKind,
    actions: actions,
  ),
  definitionBindingIndex: 0,
);

Widget _card(
  WorkflowInstance instance,
  LocalWorkflowEngineApi api,
  LoomWorkflowStateMachine machine,
  String bindingKind,
) => _host(
  EngineNativeArchetypeCard(
    contentKey: ValueKey('summary-readonly-card-$bindingKind'),
    resolved: _resolved(instance, machine, bindingKind),
    engine: api,
    communityExtensionId: 'summary-readonly',
    fanId: 'member-1',
    roleId: 'member',
    accent: Colors.grey,
    onInstanceChanged: (_) {},
    onInstanceScopedCreate:
        ({
          required WorkflowAction action,
          required WorkflowInstance instance,
          required RenderBinding binding,
        }) async {},
  ),
);

void main() {
  testWidgets(
    'summary binding renders no transition button or instance-scoped create '
    'button, while a primary binding on the same instance and role renders '
    'both',
    (tester) async {
      final (api, instance) = await _seed();
      final machine = _machine();
      final id = instance.instanceId;

      await tester.pumpWidget(_card(instance, api, machine, 'primary'));
      await tester.pump();
      await tester.pumpAndSettle();
      expect(
        find.byKey(ValueKey('generic-instance-$id-action-finish')),
        findsOneWidget,
        reason: 'a primary binding must render the transition button',
      );
      expect(
        find.byKey(ValueKey('instance-create-action-$id-related-type')),
        findsOneWidget,
        reason:
            'a primary binding must render the instance-scoped create button',
      );

      await tester.pumpWidget(_card(instance, api, machine, 'summary'));
      await tester.pump();
      await tester.pumpAndSettle();
      expect(
        find.byKey(ValueKey('generic-instance-$id-action-finish')),
        findsNothing,
        reason: 'a summary binding must not render the transition button',
      );
      expect(
        find.byKey(ValueKey('instance-create-action-$id-related-type')),
        findsNothing,
        reason:
            'a summary binding must not render the instance-scoped create '
            'button',
      );
    },
  );

  testWidgets(
    'summary binding renders no editor even though the current state '
    'declares editableFields and the viewer passes its editGuard',
    (tester) async {
      final (api, instance) = await _seed();
      final machine = _machine();
      final id = instance.instanceId;

      await tester.pumpWidget(_card(instance, api, machine, 'summary'));
      await tester.pump();
      await tester.pumpAndSettle();
      expect(
        find.byKey(ValueKey('generic-instance-editor-$id-notes')),
        findsNothing,
      );
      expect(find.byKey(ValueKey('generic-instance-save-$id')), findsNothing);

      // Contrast: the same instance, role and editGuard on a primary binding
      // does render the editor -- the guard passes, only bindingKind differs.
      await tester.pumpWidget(_card(instance, api, machine, 'primary'));
      await tester.pump();
      await tester.pumpAndSettle();
      expect(
        find.byKey(ValueKey('generic-instance-editor-$id-notes')),
        findsOneWidget,
      );
      expect(
        find.byKey(ValueKey('generic-instance-save-$id')),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'summary binding still renders its fields and its state badge -- a '
    'status view, not a blank card',
    (tester) async {
      final (api, instance) = await _seed();
      final machine = _machine();
      final id = instance.instanceId;

      await tester.pumpWidget(_card(instance, api, machine, 'summary'));
      await tester.pump();
      await tester.pumpAndSettle();
      expect(find.text('Visible Title'), findsOneWidget);
      expect(find.byKey(ValueKey('generic-instance-state-$id')), findsOneWidget);
      expect(find.text('Open'), findsOneWidget);
    },
  );

  testWidgets(
    'a table-family card, which bypasses the archetype dispatcher\'s switch, '
    'gets the same read-only treatment in its detail dialog',
    (tester) async {
      final (api, instance) = await _seed();
      final machine = _machine();
      final id = instance.instanceId;

      Future<void> pumpTableWith(String bindingKind) async {
        await tester.pumpWidget(
          _host(
            WorkflowTableArchetypeCard(
              bindings: [_resolved(instance, machine, bindingKind, cardSurfaceFamily: 'table')],
              engine: api,
              communityExtensionId: 'summary-readonly',
              fanId: 'member-1',
              roleId: 'member',
              accent: Colors.grey,
              onInstanceChanged: (_) {},
            ),
          ),
        );
        await tester.pump();
        await tester.tap(
          find.byKey(
            ValueKey('workflow-table-row-home-summary-readonly-test-$id-0'),
          ),
        );
        await tester.pumpAndSettle();
      }

      await pumpTableWith('primary');
      expect(
        find.byKey(ValueKey('generic-instance-$id-action-finish')),
        findsOneWidget,
        reason: 'a primary table-detail card must render the transition button',
      );
      await tester.tap(
        find.byKey(ValueKey('workflow-table-detail-close-$id')),
      );
      await tester.pumpAndSettle();

      await pumpTableWith('summary');
      expect(
        find.byKey(ValueKey('generic-instance-$id-action-finish')),
        findsNothing,
        reason: 'a summary table-detail card must not render the transition button',
      );
      expect(
        find.descendant(
          of: find.byKey(ValueKey('workflow-table-detail-card-$id')),
          matching: find.text('Visible Title'),
        ),
        findsOneWidget,
        reason: 'a summary table-detail card still renders its fields',
      );
    },
  );
}
