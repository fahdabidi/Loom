import '../models/workflow_models.dart';

/// Evaluates a [WorkflowGuard] against the given persona and instance data.
/// All conditions must pass (AND semantics). Empty/null guards always pass.
bool evaluateGuard(
  WorkflowGuard guard,
  String personaId,
  Map<String, dynamic> instanceData,
  // completedWorkflowIds is reserved for Phase 3 (cross-workflow deps).
  // Accepted but not yet enforced in Phase 1.
  {Set<String>? completedWorkflowIds,}
) {
  // allowedPersonaIds — if non-null and non-empty, persona must be in the list.
  if (guard.allowedPersonaIds != null &&
      guard.allowedPersonaIds!.isNotEmpty &&
      !guard.allowedPersonaIds!.contains(personaId)) {
    return false;
  }

  // actorInList — checks list membership in instanceData.
  if (guard.actorInList != null) {
    final raw = instanceData[guard.actorInList!.key];
    final list = (raw is List) ? raw.cast<String>() : <String>[];
    final isPresent = list.contains(personaId);
    if (isPresent != guard.actorInList!.present) {
      return false;
    }
  }

  // instanceDataEquals — checks value equality on an arbitrary field.
  if (guard.instanceDataEquals != null) {
    final current = instanceData[guard.instanceDataEquals!.key];
    if (current != guard.instanceDataEquals!.value) {
      return false;
    }
  }

  // requiresWorkflowsComplete — cross-workflow dependency (Phase 3).
  // For now, guard passes if null/empty; once real data flows in, check
  // that completedWorkflowIds contains every required workflow.
  if (guard.requiresWorkflowsComplete != null &&
      guard.requiresWorkflowsComplete!.isNotEmpty) {
    final completed = completedWorkflowIds ?? const {};
    for (final required in guard.requiresWorkflowsComplete!) {
      if (!completed.contains(required)) return false;
    }
  }

  return true;
}