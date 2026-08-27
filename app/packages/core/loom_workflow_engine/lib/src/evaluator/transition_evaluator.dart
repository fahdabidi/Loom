import '../models/workflow_models.dart';
import 'guard_evaluator.dart';

/// Returns the list of transitions available from [currentState] for the given
/// [fanId] and [instanceData]. Returns an empty list (never null) — the
/// stuck-state regression case is handled here, not at parse time.
///
/// [roleIds], when provided, are passed through to [evaluateGuard] so
/// [allowedRoleIds]-style guards check any declared role rather than the
/// individual id. [roleId] is retained for existing single-role callers.
List<LoomWorkflowTransition> availableTransitions(
  LoomWorkflowStateMachine machine,
  String currentState,
  String fanId,
  Map<String, dynamic> instanceData, {
  String? roleId,
  Set<String>? roleIds,
  Set<String>? completedWorkflowIds,
  bool skipRelatedAggregate = false,
  DateTime Function()? clock,
  bool Function(LoomWorkflowTransition transition)? grantedByArchetype,
}) {
  return machine
      .transitionsFrom(currentState)
      .where(
        (t) =>
            evaluateGuard(
              t.guard,
              fanId,
              instanceData,
              roleId: roleId,
              roleIds: roleIds,
              completedWorkflowIds: completedWorkflowIds,
              skipRelatedAggregate: skipRelatedAggregate,
              clock: clock,
            ) ||
            // An archetype grant is an ALTERNATIVE to the guard, never a clause
            // within it. evaluateGuard combines its clauses with AND and has no
            // combinator, so a grant expressed inside a guard would narrow
            // access rather than widen it -- "hoa-board AND granted" instead of
            // "hoa-board OR granted", which is the opposite of a grant.
            //
            // This mirrors how reads already work: _isVisibleThroughArchetype
            // admits a shared-with fan before the visibility default is
            // consulted, rather than becoming part of the readGuard.
            (grantedByArchetype != null && grantedByArchetype(t)),
      )
      .toList();
}
