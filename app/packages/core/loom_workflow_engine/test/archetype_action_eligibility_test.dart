import 'package:loom_workflow_engine/loom_workflow_engine.dart';
import 'package:test/test.dart';

LoomWorkflowStateMachine _gardenToolLoanMachine() =>
    LoomWorkflowStateMachine.fromJson(<String, dynamic>{
      'initialState': 'published',
      'states': <String, dynamic>{
        'published': <String, dynamic>{'label': 'Published'},
      },
      'transitions': <Map<String, dynamic>>[
        <String, dynamic>{
          'id': 'join-queue',
          'label': 'Join queue',
          'action': 'join_queue',
          'from': <String>['published'],
          'to': null,
        },
        <String, dynamic>{
          'id': 'leave-queue',
          'label': 'Leave queue',
          'action': 'leave_queue',
          'from': <String>['published'],
          'to': null,
        },
      ],
      'renderBindings': <Map<String, dynamic>>[
        <String, dynamic>{
          'states': <String>['published'],
          'audience': 'any',
          'tabId': 'tool-shed',
          'cardSurfaceFamily': 'equipment-loan',
          'bindingKind': 'primary',
        },
      ],
      'instanceDataSchema': <String, dynamic>{
        'title': <String, dynamic>{'type': 'text'},
        'queuedFanIds': <String, dynamic>{
          'type': 'fanId[]',
          'writableBy': 'effect',
        },
      },
    }, 'garden-tool-loan');

void main() {
  test(
    'garden-tool-loan derives queue actions from engine-owned membership',
    () async {
      const actor = 'garden-member';
      final api = LocalWorkflowEngineApi(
        db: WorkflowDatabase.memory(),
        communityId: 'garden-club',
      )..registerDefinition(_gardenToolLoanMachine());
      final instanceId = await api.createInstance(
        workflowType: 'garden-tool-loan',
        initialInstanceData: <String, dynamic>{'title': 'Steel wheelbarrow'},
        fanId: 'garden-owner',
      );

      final beforeJoin = await api.availableTransitionsAsync(
        workflowType: 'garden-tool-loan',
        instanceId: instanceId,
        currentState: 'published',
        instanceData: const <String, dynamic>{'title': 'Steel wheelbarrow'},
        fanId: actor,
      );
      expect(beforeJoin.map((transition) => transition.id), <String>[
        'join-queue',
      ]);
      await expectLater(
        api.applyTransition(
          workflowType: 'garden-tool-loan',
          instanceId: instanceId,
          transitionId: 'leave-queue',
          fanId: actor,
        ),
        throwsA(isA<StateError>()),
      );

      final joined = await api.applyTransition(
        workflowType: 'garden-tool-loan',
        instanceId: instanceId,
        transitionId: 'join-queue',
        fanId: actor,
      );
      expect(joined.newState, 'published');
      expect(joined.newInstanceData['queuedFanIds'], <String>[actor]);

      final afterJoin = await api.availableTransitionsAsync(
        workflowType: 'garden-tool-loan',
        instanceId: instanceId,
        currentState: joined.newState,
        instanceData: joined.newInstanceData,
        fanId: actor,
      );
      expect(afterJoin.map((transition) => transition.id), <String>[
        'leave-queue',
      ]);
    },
  );
}
