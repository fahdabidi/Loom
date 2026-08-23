import '../models/workflow_models.dart';
import 'guard_evaluator.dart';

/// Returns the list of transitions available from [currentState] for the given
/// [fanId] and [instanceData]. Returns an empty list (never null) — the
/// stuck-state regression case is handled here, not at parse time.
///
/// [roleId], when provided, is passed through to [evaluateGuard] so
/// [allowedRoleIds]-style guards check the role rather than the
/// individual id.
List<LoomWorkflowTransition> availableTransitions(
  LoomWorkflowStateMachine machine,
  String currentState,
  String fanId,
  Map<String, dynamic> instanceData, {
  String? roleId,
  Set<String>? completedWorkflowIds,
  bool skipRelatedAggregate = false,
  DateTime Function()? clock,
}) {
  return machine
      .transitionsFrom(currentState)
      .where(
        (t) => evaluateGuard(
          t.guard,
          fanId,
          instanceData,
          roleId: roleId,
          completedWorkflowIds: completedWorkflowIds,
          skipRelatedAggregate: skipRelatedAggregate,
          clock: clock,
        ),
      )
      .toList();
}
