import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loom_communities_app_shell/loom_communities_app_shell.dart';
import 'package:loom_workflow_engine/loom_workflow_engine.dart';

Future<(LocalWorkflowEngineApi, EngineNativeResolvedBinding)> _seedBinding({
  required String cardSurfaceFamily,
  required String actionWorkflowType,
}) async {
  final engine = LocalWorkflowEngineApi(
    db: WorkflowDatabase.memory(),
    communityId: 'instance-scoped-create-$cardSurfaceFamily',
  );
  final workflowType = 'host-$cardSurfaceFamily';
  final machine = LoomWorkflowStateMachine.fromJson({
    'initialState': 'active',
    'states': {
      'active': {'label': 'Active'},
    },
    'transitions': <Object?>[],
    'instanceDataSchema': <String, Object?>{},
  }, workflowType);
  engine.registerDefinition(machine);
  final instanceId = await engine.createInstance(
    workflowType: workflowType,
    fanId: 'portability-owner',
    initialInstanceData: <String, dynamic>{},
  );
  final instance = (await engine.queryInstances(
    tabId: 'admin',
    fanId: 'portability-owner',
  )).items.singleWhere((item) => item.instanceId == instanceId);

  return (
    engine,
    EngineNativeResolvedBinding(
      instance: instance,
      machine: machine,
      binding: RenderBinding(
        states: const ['active'],
        role: 'portability-owner',
        tabId: 'admin',
        cardSurfaceFamily: cardSurfaceFamily,
        bindingKind: 'primary',
        actions: [
          WorkflowAction(
            kind: 'create',
            workflowType: actionWorkflowType,
            label: 'Request rollback',
            byRoleIds: const ['portability-owner'],
            scope: 'instance',
            presentation: 'button',
            prefill: const {'sourceTransferInstanceId': '{context.id}'},
          ),
        ],
      ),
      definitionBindingIndex: 0,
    ),
  );
}

Future<void> _expectAuthorizedInstanceCreateButton(
  WidgetTester tester, {
  required String cardSurfaceFamily,
  required String actionWorkflowType,
}) async {
  final (engine, resolved) = await _seedBinding(
    cardSurfaceFamily: cardSurfaceFamily,
    actionWorkflowType: actionWorkflowType,
  );
  final invokedActions = <WorkflowAction>[];
  final actionKey = ValueKey(
    'instance-create-action-${resolved.instance.instanceId}-$actionWorkflowType',
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
          communityExtensionId: 'data-portability',
          fanId: 'portability-owner',
          roleId: 'portability-owner',
          accent: Colors.indigo,
          onInstanceChanged: (_) {},
          onInstanceScopedCreate:
              ({required action, required instance, required binding}) async {
                invokedActions.add(action);
              },
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();

  expect(find.byKey(actionKey), findsOneWidget);
  expect(find.text('Request rollback'), findsOneWidget);

  await tester.tap(find.byKey(actionKey));
  await tester.pump();
  expect(invokedActions.single.workflowType, actionWorkflowType);
}

void main() {
  testWidgets(
    'exportWizard renders an authorized instance-scoped create button',
    (tester) => _expectAuthorizedInstanceCreateButton(
      tester,
      cardSurfaceFamily: 'exportWizard',
      actionWorkflowType: 'export-transfer-rollback',
    ),
  );

  testWidgets(
    'documentLibrary renders an authorized instance-scoped create button',
    (tester) => _expectAuthorizedInstanceCreateButton(
      tester,
      cardSurfaceFamily: 'documentLibrary',
      actionWorkflowType: 'document-remediation-request',
    ),
  );
}
