import '../models/workflow_models.dart';
import 'guard_evaluator.dart';

/// Returns the list of transitions available from [currentState] for the given
/// [personaId] and [instanceData]. Returns an empty list (never null) — the
/// stuck-state regression case is handled here, not at parse time.
///
/// [personaTypeId], when provided, is passed through to [evaluateGuard] so
/// [allowedPersonaIds]-style guards check the persona *type* rather than the
/// individual id.
List<LoomWorkflowTransition> availableTransitions(
  LoomWorkflowStateMachine machine,
  String currentState,
  String personaId,
  Map<String, dynamic> instanceData, {
  String? personaTypeId,
  Set<String>? completedWorkflowIds,
  bool skipRelatedAggregate = false,
  DateTime Function()? clock,
}) {
  return machine
      .transitionsFrom(currentState)
      .where(
        (t) => evaluateGuard(
          t.guard,
          personaId,
          instanceData,
          personaTypeId: personaTypeId,
          completedWorkflowIds: completedWorkflowIds,
          skipRelatedAggregate: skipRelatedAggregate,
          clock: clock,
        ),
      )
      .toList();
}
