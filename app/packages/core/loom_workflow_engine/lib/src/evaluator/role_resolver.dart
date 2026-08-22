import '../api/workflow_engine_api.dart';
import '../models/workflow_models.dart';
import 'transition_evaluator.dart';

/// Derives which rendering roles a given viewer holds for one persisted
/// workflow [instance] under [machine]'s transition guards.
///
/// Returns a role set containing:
/// - `'actor'` when [viewerFanId] is the resolved actor of the instance.
/// - `'receiver'` when [viewerFanId] is not the actor and passes at least
///   one guard from the instance's current-state transitions.
Set<String> deriveInstanceRoles(
  LoomWorkflowStateMachine machine,
  WorkflowInstance instance, {
  required String viewerFanId,
  String? viewerRoleId,
}) {
  final Set<String> roles = <String>{};

  String? actorFanId;
  var foundActorEqualsField = false;
  for (final transition in machine.transitions) {
    final actorEqualsField = transition.guard.actorEqualsField;
    if (actorEqualsField != null) {
      foundActorEqualsField = true;
      actorFanId = instance.instanceData[actorEqualsField.key] as String?;
      break;
    }
  }

  if (!foundActorEqualsField) actorFanId = instance.createdByFanId;

  if (viewerFanId == actorFanId) {
    roles.add('actor');
    return roles;
  }

  if (availableTransitions(
    machine,
    instance.currentState,
    viewerFanId,
    instance.instanceData,
    roleId: viewerRoleId,
    skipRelatedAggregate: true,
  ).isNotEmpty) {
    roles.add('receiver');
  }

  return roles;
}
