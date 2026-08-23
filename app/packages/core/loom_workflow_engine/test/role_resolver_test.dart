import 'package:loom_workflow_engine/loom_workflow_engine.dart';
import 'package:test/test.dart';

LoomWorkflowStateMachine _machine(List<Map<String, dynamic>> transitions) =>
    LoomWorkflowStateMachine.fromJson({
      'initialState': 'open',
      'states': <String, dynamic>{
        'open': <String, dynamic>{'label': 'Open'},
        'approved': <String, dynamic>{'label': 'Approved'},
        'done': <String, dynamic>{'label': 'Done'},
      },
      'transitions': transitions,
      'renderBindings': const <Map<String, dynamic>>[],
    }, 'test-workflow');

WorkflowInstance _instance({
  required String instanceId,
  required String workflowType,
  required String currentState,
  required String createdByFanId,
  Map<String, dynamic> instanceData = const {},
}) => WorkflowInstance(
  instanceId: instanceId,
  workflowType: workflowType,
  currentState: currentState,
  instanceData: instanceData,
  createdByFanId: createdByFanId,
);

void main() {
  test('actor derives from createdByFanId when no actorEqualsField exists', () {
    final machine = _machine([
      <String, dynamic>{
        'id': 'noop',
        'label': 'noop',
        'from': <String>['open'],
        'to': 'done',
      },
    ]);
    final instance = _instance(
      instanceId: 'created-by-actor',
      workflowType: 'test-workflow',
      currentState: 'open',
      createdByFanId: 'payer-creator',
    );
    final roles = deriveInstanceRoles(
      machine,
      instance,
      viewerFanId: 'payer-creator',
      viewerRoleId: 'payer-type',
    );
    expect(roles, {'actor'});
  });

  test(
    'actor uses actorEqualsField when present, even over createdByFanId',
    () {
      final machine = _machine([
        <String, dynamic>{
          'id': 'approve',
          'label': 'Approve',
          'from': <String>['open'],
          'to': 'done',
          'guard': <String, dynamic>{
            'actorEqualsField': <String, dynamic>{'key': 'payerFanId'},
          },
        },
      ]);
      final instance = _instance(
        instanceId: 'actor-equals-field',
        workflowType: 'test-workflow',
        currentState: 'open',
        createdByFanId: 'different-creator',
        instanceData: <String, dynamic>{'payerFanId': 'payer-fan'},
      );
      final roles = deriveInstanceRoles(
        machine,
        instance,
        viewerFanId: 'payer-fan',
        viewerRoleId: 'payer-type',
      );
      expect(roles, {'actor'});
    },
  );

  test(
    'viewer with matching allowedRoleIds guard is receiver when not actor',
    () {
      final machine = _machine([
        <String, dynamic>{
          'id': 'approve',
          'label': 'Approve',
          'from': <String>['open'],
          'to': 'approved',
          'guard': <String, dynamic>{
            'allowedRoleIds': <String>['board-role'],
          },
        },
      ]);
      final instance = _instance(
        instanceId: 'guarded-receiver',
        workflowType: 'test-workflow',
        currentState: 'open',
        createdByFanId: 'creator',
        instanceData: const <String, dynamic>{},
      );
      final roles = deriveInstanceRoles(
        machine,
        instance,
        viewerFanId: 'board-account',
        viewerRoleId: 'board-role',
      );
      expect(roles, {'receiver'});
    },
  );

  test(
    'viewer with no actor role and no passing guard is neither actor nor receiver',
    () {
      final machine = _machine([
        <String, dynamic>{
          'id': 'approve',
          'label': 'Approve',
          'from': <String>['open'],
          'to': 'approved',
          'guard': <String, dynamic>{
            'allowedRoleIds': <String>['board-role'],
          },
        },
      ]);
      final instance = _instance(
        instanceId: 'blocked-viewer',
        workflowType: 'test-workflow',
        currentState: 'open',
        createdByFanId: 'creator',
        instanceData: const <String, dynamic>{},
      );
      final roles = deriveInstanceRoles(
        machine,
        instance,
        viewerFanId: 'other-account',
        viewerRoleId: 'member-role',
      );
      expect(roles, isEmpty);
    },
  );
}
