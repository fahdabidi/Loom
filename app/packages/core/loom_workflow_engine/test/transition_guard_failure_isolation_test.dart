import 'package:loom_workflow_engine/loom_workflow_engine.dart';
import 'package:test/test.dart';

void main() {
  test(
    'a throwing guard excludes only its transition while a later guard passes',
    () {
      final diagnostics = <GuardEvaluationFailure>[];
      final machine = LoomWorkflowStateMachine.fromJson({
        'initialState': 'unreviewed',
        'states': {
          'unreviewed': {'label': 'Unreviewed'},
          'acknowledged': {'label': 'Acknowledged'},
        },
        'transitions': [
          {
            'id': 'request-restoration',
            'label': 'Request restoration',
            'from': ['unreviewed'],
            'to': 'acknowledged',
            'guard': {'formula': '!isSuppressionActive'},
          },
          {
            'id': 'acknowledge-proof',
            'label': 'Acknowledge proof',
            'from': ['unreviewed'],
            'to': 'acknowledged',
            'guard': {
              'allowedRoleIds': ['ad-off-member'],
              'actorEqualsField': {'key': 'memberFanId'},
            },
          },
        ],
        'instanceDataSchema': {
          'memberFanId': {'type': 'fanId'},
        },
      }, 'ad-off-ad-suppression');

      final engine =
          LocalWorkflowEngineApi(
              db: WorkflowDatabase.memory(),
              communityId: 'ad-free-community',
              onGuardEvaluationFailure: diagnostics.add,
            )
            ..setRoleForFan('fan-1', 'ad-off-member')
            ..registerDefinition(machine);

      final transitions = engine.availableTransitions(
        workflowType: 'ad-off-ad-suppression',
        instanceId: 'suppression-1',
        currentState: 'unreviewed',
        instanceData: const {'memberFanId': 'fan-1'},
        fanId: 'fan-1',
      );

      expect(transitions.map((transition) => transition.id), [
        'acknowledge-proof',
      ]);
      expect(diagnostics, hasLength(1));
      final failure = diagnostics.single;
      expect(failure.workflowType, 'ad-off-ad-suppression');
      expect(failure.instanceId, 'suppression-1');
      expect(failure.transitionId, 'request-restoration');
      expect(failure.error, isA<FormulaEvaluationException>());
      expect(failure.stackTrace.toString(), contains('evaluateGuard'));
      expect(failure.logLine, contains('LOOM_GUARD_EVALUATION_FAILURE'));
    },
  );
}
