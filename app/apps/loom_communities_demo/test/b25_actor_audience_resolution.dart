import 'package:loom_workflow_engine/loom_workflow_engine.dart';

/// An actor identity B25 may sign in as while exercising a shipped workflow.
///
/// B25 selection must use the same individual fan id and role id the App
/// Shell gives the workflow engine. A role id alone is not an ownership rule.
class B25ActorAudienceCandidate {
  const B25ActorAudienceCandidate({required this.fanId, required this.roleId});

  final String fanId;
  final String roleId;
}

/// The one resolver failure that means B25 cannot even attempt this row.
///
/// Keeping this distinct from a generic [StateError] lets the walkthrough
/// record a malformed actor audience as a blocked row while preserving loud
/// failures for every other selector defect.
class B25ActorAudienceResolutionFailure extends StateError {
  B25ActorAudienceResolutionFailure({
    required this.workflowId,
    required this.instanceId,
    required this.roleId,
    required this.actorEqualsField,
  }) : super(
         'B25 audience resolution failed promptly: workflow $workflowId, '
         'instance $instanceId, role $roleId, actorEqualsField '
         '$actorEqualsField is absent from the instance data. '
         'deriveInstanceRoles did not resolve an actor audience, so B25 will '
         'not wait for a widget the renderer cannot show.',
       );

  static const absentActorEqualsFieldCause =
      'actorEqualsField absent from the instance data';

  final String workflowId;
  final String instanceId;
  final String roleId;
  final String actorEqualsField;
}

/// The selector result for one row with an `audience: "actor"` binding.
///
/// A blocked result is deliberately not a substitute selector. Callers must
/// record it as `blocked_by_audience`, not try a fallback identity or action.
class B25ActorAudienceRowSelection<T> {
  const B25ActorAudienceRowSelection.selected(this.selector)
    : blockedReason = null,
      blockedCause = null;

  const B25ActorAudienceRowSelection.blocked({
    required this.blockedReason,
    required this.blockedCause,
  }) : selector = null;

  final T? selector;
  final String? blockedReason;
  final String? blockedCause;

  bool get isBlockedByAudience => blockedReason != null;
}

/// Runs one B25 selector and converts only a known absent actor identity into
/// a row-local blocked result.
///
/// All other errors propagate. In particular, this is not a silent fallback
/// for an unrelated malformed package, a missing workflow, or a bad tab.
B25ActorAudienceRowSelection<T> selectB25ActorAudienceRow<T>(
  T Function() select,
) {
  try {
    return B25ActorAudienceRowSelection<T>.selected(select());
  } on B25ActorAudienceResolutionFailure catch (error) {
    return B25ActorAudienceRowSelection<T>.blocked(
      blockedReason: error.message,
      blockedCause:
          B25ActorAudienceResolutionFailure.absentActorEqualsFieldCause,
    );
  }
}

/// The actor candidates the rendering resolver accepts for [instance].
///
/// This deliberately delegates the ownership decision to
/// [deriveInstanceRoles]. In particular, it must not use `createdByFanId` as
/// a fallback when a workflow declares an `actorEqualsField`: the App Shell
/// does not do so either.
List<B25ActorAudienceCandidate> b25ResolvableActorAudienceCandidates({
  required LoomWorkflowStateMachine machine,
  required WorkflowInstance instance,
  required Iterable<B25ActorAudienceCandidate> candidates,
}) {
  return [
    for (final candidate in candidates)
      if (deriveInstanceRoles(
        machine,
        instance,
        viewerFanId: candidate.fanId,
        viewerRoleId: candidate.roleId,
      ).contains('actor'))
        candidate,
  ];
}

/// Resolves the identity B25 may use for an `audience: "actor"` binding.
///
/// The returned fan id is safe to hand to the UI because it was accepted by
/// the renderer's own role resolver. Failure is synchronous and descriptive
/// so a malformed seed cannot consume a full widget wait budget.
String requireB25ActorBindingAudience({
  required String workflowId,
  required WorkflowInstance instance,
  required String roleId,
  required Iterable<B25ActorAudienceCandidate> candidates,
  required LoomWorkflowStateMachine machine,
}) {
  final resolved = b25ResolvableActorAudienceCandidates(
    machine: machine,
    instance: instance,
    candidates: candidates,
  );
  if (resolved.isNotEmpty) return resolved.first.fanId;

  final actorEqualsField = _firstActorEqualsField(machine);
  if (actorEqualsField != null &&
      !instance.instanceData.containsKey(actorEqualsField)) {
    throw B25ActorAudienceResolutionFailure(
      workflowId: workflowId,
      instanceId: instance.instanceId,
      roleId: roleId,
      actorEqualsField: actorEqualsField,
    );
  }

  throw StateError(
    'B25 audience resolution failed promptly: workflow $workflowId, '
    'instance ${instance.instanceId}, role $roleId. '
    'deriveInstanceRoles did not resolve an actor audience for the selected '
    'identity.',
  );
}

/// Mirrors only the field declaration order used by [deriveInstanceRoles] to
/// make a failed audience diagnostic actionable. It never makes an audience
/// decision; that decision is exclusively delegated to the shared resolver.
String? _firstActorEqualsField(LoomWorkflowStateMachine machine) {
  for (final transition in machine.transitions) {
    final actorEqualsField = transition.guard.actorEqualsField;
    if (actorEqualsField != null) return actorEqualsField.key;
  }
  return null;
}
