import 'package:loom_workflow_engine/loom_workflow_engine.dart';
import 'package:test/test.dart';

void main() {
  group('resolved fan roles', () {
    test('a fan holding both roles passes either role guard', () {
      final api = _api()
        ..setRolesForFan('fan-board-member', {'hoa-member', 'hoa-board'})
        ..registerDefinition(_machine());

      final transitions = api.availableTransitions(
        workflowType: 'approval',
        instanceId: 'approval-1',
        currentState: 'open',
        instanceData: const {},
        fanId: 'fan-board-member',
      );

      expect(
        transitions.map((transition) => transition.id),
        containsAll(<String>['board-action', 'member-action']),
      );
    });

    test('setting roles again replaces roles that were revoked', () {
      final api = _api()
        ..setRolesForFan('fan-board-member', {'hoa-member', 'hoa-board'})
        ..registerDefinition(_machine());

      expect(
        _transitionIds(api),
        containsAll(<String>['board-action', 'member-action']),
      );

      api.setRolesForFan('fan-board-member', {'hoa-member'});

      expect(_transitionIds(api), isNot(contains('board-action')));
      expect(_transitionIds(api), contains('member-action'));
    });

    test('an empty held-role set fails a non-empty role guard closed', () {
      final api = _api()
        ..setRolesForFan('fan-no-role', <String>{})
        ..registerDefinition(_machine());

      final transitions = api.availableTransitions(
        workflowType: 'approval',
        instanceId: 'approval-1',
        currentState: 'open',
        instanceData: const {},
        fanId: 'fan-no-role',
      );

      expect(transitions, isEmpty);
    });
  });
}

LocalWorkflowEngineApi _api() => LocalWorkflowEngineApi(
  db: WorkflowDatabase.memory(),
  communityId: 'role-resolution',
);

Iterable<String> _transitionIds(LocalWorkflowEngineApi api) => api
    .availableTransitions(
      workflowType: 'approval',
      instanceId: 'approval-1',
      currentState: 'open',
      instanceData: const {},
      fanId: 'fan-board-member',
    )
    .map((transition) => transition.id);

LoomWorkflowStateMachine _machine() => LoomWorkflowStateMachine.fromJson({
  'initialState': 'open',
  'states': {
    'open': {'label': 'Open'},
    'complete': {'label': 'Complete'},
  },
  'transitions': [
    {
      'id': 'board-action',
      'label': 'Board action',
      'from': ['open'],
      'to': 'complete',
      'guard': {
        'allowedRoleIds': ['hoa-board'],
      },
    },
    {
      'id': 'member-action',
      'label': 'Member action',
      'from': ['open'],
      'to': 'complete',
      'guard': {
        'allowedRoleIds': ['hoa-member'],
      },
    },
  ],
  'instanceDataSchema': <String, dynamic>{},
}, 'approval');
