import 'dart:developer' as developer;

import '../models/workflow_models.dart';
import 'guard_evaluator.dart';

/// The observable record emitted when one transition's guard cannot run.
///
/// Guard-evaluation errors exclude only the transition that produced them.
/// The original [error] and [stackTrace] are retained so a host can report the
/// engine fault without reducing it to an unavailable action.
class GuardEvaluationFailure {
  const GuardEvaluationFailure({
    required this.workflowType,
    required this.instanceId,
    required this.transitionId,
    required this.error,
    required this.stackTrace,
  });

  final String workflowType;
  final String? instanceId;
  final String transitionId;
  final Object error;
  final StackTrace stackTrace;

  /// The structured record written to the engine diagnostic stream.
  String get logLine =>
      'LOOM_GUARD_EVALUATION_FAILURE '
      'workflowType=$workflowType '
      'instanceId=${instanceId ?? '<unknown>'} '
      'transitionId=$transitionId '
      'errorType=${error.runtimeType} '
      'exception=$error';
}

/// Receives a guard failure that did not prevent another transition from
/// being evaluated. Hosts can use this to distinguish an empty candidate set
/// from a partial guard-evaluation failure.
typedef GuardEvaluationFailureReporter =
    void Function(GuardEvaluationFailure failure);

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
  String? instanceId,
  GuardEvaluationFailureReporter? onGuardEvaluationFailure,
}) {
  final available = <LoomWorkflowTransition>[];
  for (final transition in machine.transitionsFrom(currentState)) {
    final bool guardPassed;
    try {
      guardPassed = evaluateGuard(
        transition.guard,
        fanId,
        instanceData,
        roleId: roleId,
        roleIds: roleIds,
        completedWorkflowIds: completedWorkflowIds,
        skipRelatedAggregate: skipRelatedAggregate,
        clock: clock,
      );
    } catch (error, stackTrace) {
      final failure = GuardEvaluationFailure(
        workflowType: machine.workflowType,
        instanceId: instanceId,
        transitionId: transition.id,
        error: error,
        stackTrace: stackTrace,
      );
      _reportGuardEvaluationFailure(failure, onGuardEvaluationFailure);
      continue;
    }

    if (guardPassed ||
        // An archetype grant is an ALTERNATIVE to the guard, never a clause
        // within it. evaluateGuard combines its clauses with AND and has no
        // combinator, so a grant expressed inside a guard would narrow
        // access rather than widen it -- "hoa-board AND granted" instead of
        // "hoa-board OR granted", which is the opposite of a grant.
        //
        // This mirrors how reads already work: _isVisibleThroughArchetype
        // admits a shared-with fan before the visibility default is
        // consulted, rather than becoming part of the readGuard.
        (grantedByArchetype != null && grantedByArchetype(transition))) {
      available.add(transition);
    }
  }
  return available;
}

void _reportGuardEvaluationFailure(
  GuardEvaluationFailure failure,
  GuardEvaluationFailureReporter? reporter,
) {
  developer.log(
    failure.logLine,
    name: 'loom.workflow_engine',
    error: failure.error,
    stackTrace: failure.stackTrace,
  );
  if (reporter == null) return;
  try {
    reporter(failure);
  } catch (error, stackTrace) {
    developer.log(
      'LOOM_GUARD_EVALUATION_REPORTER_FAILURE '
      'workflowType=${failure.workflowType} '
      'instanceId=${failure.instanceId ?? '<unknown>'} '
      'transitionId=${failure.transitionId} '
      'errorType=${error.runtimeType} '
      'exception=$error',
      name: 'loom.workflow_engine',
      error: error,
      stackTrace: stackTrace,
    );
  }
}
