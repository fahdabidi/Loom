import '../models/workflow_models.dart';
import 'guard_evaluator.dart';

/// Resolves a workflow's declared read visibility for one state and viewer.
///
/// Instance ownership and archetype sharing are evaluated by the local engine
/// before this policy runs. This resolver owns the workflow-level default and
/// the state's optional `readGuard`, so every caller applies them in the same
/// order.
bool workflowReadVisibilityAllows({
  required LoomWorkflowStateMachine machine,
  required String currentState,
  required String fanId,
  required Map<String, dynamic> instanceData,
  required bool isActiveMember,
  Set<String>? roleIds,
  DateTime Function()? clock,
}) {
  // A state guard takes precedence over the workflow default. This is the
  // engine's existing narrowing rule for per-state visibility.
  final stateGuard = machine.states[currentState]?.readGuard;
  if (stateGuard != null) {
    return evaluateGuard(
      stateGuard,
      fanId,
      instanceData,
      roleIds: roleIds,
      clock: clock,
    );
  }

  switch (machine.visibility.defaultValue) {
    case WorkflowVisibilityDefault.public:
      return true;
    case WorkflowVisibilityDefault.membersOnly:
      return isActiveMember;
    case WorkflowVisibilityDefault.guarded:
      final readGuard = machine.visibility.readGuard;
      if (readGuard == null) return false;
      return evaluateGuard(
        readGuard,
        fanId,
        instanceData,
        roleIds: roleIds,
        clock: clock,
      );
  }
}
