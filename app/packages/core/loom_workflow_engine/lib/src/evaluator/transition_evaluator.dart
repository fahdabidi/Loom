import '../models/workflow_models.dart';
import 'guard_evaluator.dart';

/// Returns the list of transitions available from [currentState] for the given
/// [personaId] and [instanceData]. Returns an empty list (never null) — the
/// stuck-state regression case is handled here, not at parse time.
List<LoomWorkflowTransition> availableTransitions(
  LoomWorkflowStateMachine machine,
  String currentState,
  String personaId,
  Map<String, dynamic> instanceData, {
  Set<String>? completedWorkflowIds,
}) {
  return machine
      .transitionsFrom(currentState)
      .where((t) =>
          evaluateGuard(t.guard, personaId, instanceData,
              completedWorkflowIds: completedWorkflowIds))
      .toList();
}