import 'package:loom_workflow_engine/loom_workflow_engine.dart';
import 'package:test/test.dart';

LoomWorkflowStateMachine _machine() => LoomWorkflowStateMachine.fromJson({
  'initialState': 'unread',
  'states': {
    'unread': {'label': 'Unread'},
    'read': {'label': 'Read'},
  },
  'transitions': [
    {
      'id': 'mark-read',
      'label': 'Mark read',
      'from': ['unread'],
      'to': 'read',
      'guard': {
        'actorEqualsField': {'key': 'recipientPersonaId'},
      },
    },
  ],
  'instanceDataSchema': {
    'recipientPersonaId': {'type': 'personaId'},
  },
}, 'notification');

Future<String> _stateFor(LocalWorkflowEngineApi api, String instanceId) async =>
    (await api.queryInstances(tabId: 'messages', personaId: 'viewer')).items
        .singleWhere((instance) => instance.instanceId == instanceId)
        .currentState;

void main() {
  test(
    'actorEqualsField enforces the specific actor on applyTransition',
    () async {
      final api = LocalWorkflowEngineApi(
        db: WorkflowDatabase.memory(),
        communityId: 'actor-equals-field',
      )..registerDefinition(_machine());
      api.setPersonaType('recipient-1', 'member');
      api.setPersonaType('other-member', 'member');

      final matching = await api.createInstance(
        workflowType: 'notification',
        personaId: 'creator',
        initialInstanceData: {'recipientPersonaId': 'recipient-1'},
      );
      await api.applyTransition(
        workflowType: 'notification',
        instanceId: matching,
        transitionId: 'mark-read',
        personaId: 'recipient-1',
      );
      expect(await _stateFor(api, matching), 'read');

      final mismatched = await api.createInstance(
        workflowType: 'notification',
        personaId: 'creator',
        initialInstanceData: {'recipientPersonaId': 'recipient-1'},
      );
      await expectLater(
        api.applyTransition(
          workflowType: 'notification',
          instanceId: mismatched,
          transitionId: 'mark-read',
          personaId: 'other-member',
        ),
        throwsA(isA<StateError>()),
      );
      expect(await _stateFor(api, mismatched), 'unread');
    },
  );
}
