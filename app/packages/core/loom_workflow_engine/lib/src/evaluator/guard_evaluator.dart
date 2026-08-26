import '../models/workflow_models.dart';
import 'formula_evaluator.dart';

/// Evaluates a [WorkflowGuard] against the given fan and instance data.
/// All conditions must pass (AND semantics). Empty/null guards always pass.
///
/// [fanId] is the individual account id (e.g. `"tabletop-member-05"`).
/// [roleIds], when provided, are the fan's declared roles
/// (e.g. `"tabletop-member"`) and are used **only** to evaluate
/// [allowedRoleIds] guards. A role-gated check fails closed when they are
/// omitted or empty; an individual fan id is never treated as a role id.
///
/// [roleId] is retained for existing single-role callers and is treated as a
/// one-element role set when [roleIds] is not supplied.
bool evaluateGuard(
  WorkflowGuard guard,
  String fanId,
  Map<String, dynamic> instanceData, {
  String? roleId,
  Set<String>? roleIds,
  // completedWorkflowIds is reserved for Phase 3 (cross-workflow deps).
  // Accepted but not yet enforced in Phase 1.
  Set<String>? completedWorkflowIds,
  num? precomputedRelatedAggregate,
  num? resolvedRelatedAggregateCompareTo,
  bool skipRelatedAggregate = false,
  DateTime Function()? clock,
}) {
  // allowedRoleIds — if non-null and non-empty, any resolved role must be in
  // the list. Never compare the individual fan id to a role value.
  final effectiveRoleIds =
      roleIds ?? (roleId == null ? const <String>{} : <String>{roleId});
  if (guard.allowedRoleIds != null &&
      guard.allowedRoleIds!.isNotEmpty &&
      !effectiveRoleIds.any(guard.allowedRoleIds!.contains)) {
    return false;
  }

  // actorInList — checks list membership in instanceData.
  if (guard.actorInList != null) {
    final raw = instanceData[guard.actorInList!.key];
    final list = (raw is List) ? raw.cast<String>() : <String>[];
    final isPresent = list.contains(fanId);
    if (isPresent != guard.actorInList!.present) {
      return false;
    }
  }

  // actorEqualsField — this guard names one specific fan, so it must use
  // the individual account id rather than the role ID.
  if (guard.actorEqualsField != null) {
    if (fanId != instanceData[guard.actorEqualsField!.key]) return false;
  }

  // instanceDataEquals — checks value equality on an arbitrary field.
  if (guard.instanceDataEquals != null) {
    final current = instanceData[guard.instanceDataEquals!.key];
    if (current != guard.instanceDataEquals!.value) {
      return false;
    }
  }

  if (guard.formula != null) {
    final value = evaluateFormula(
      guard.formula!,
      instanceData: instanceData,
      viewerId: fanId,
      actorId: fanId,
      clock: clock,
    );
    if (value is! bool || !value) return false;
  }

  if (guard.cancellationDeadline != null) {
    final deadline = _cancellationDeadline(
      guard.cancellationDeadline!,
      instanceData,
    );
    if (deadline == null || (clock ?? DateTime.now)().isAfter(deadline)) {
      return false;
    }
  }

  if (guard.relatedAggregate != null && !skipRelatedAggregate) {
    final compareTo =
        resolvedRelatedAggregateCompareTo ?? guard.relatedAggregate!.compareTo;
    if (precomputedRelatedAggregate == null ||
        compareTo is! num ||
        !_compare(
          precomputedRelatedAggregate,
          compareTo,
          guard.relatedAggregate!.comparator,
        )) {
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

DateTime? _cancellationDeadline(
  CancellationDeadlineGuard guard,
  Map<String, dynamic> instanceData,
) {
  final start = combineDateAndTime(
    instanceData,
    dateField: guard.dateField,
    timeField: guard.timeField,
  );
  if (start == null) return null;
  return start.subtract(
    Duration(
      milliseconds: (guard.hoursBefore * Duration.millisecondsPerHour).round(),
    ),
  );
}

/// Combines Loom's ISO date and optional `HH:mm` time fields into a local
/// timestamp. Invalid or missing values return null so guards fail closed.
DateTime? combineDateAndTime(
  Map<String, dynamic> instanceData, {
  required String dateField,
  required String? timeField,
}) {
  final rawDate = instanceData[dateField];
  final rawTime = timeField == null ? null : instanceData[timeField];
  return combineDateAndTimeValues(
    rawDate is String ? rawDate : null,
    rawTime is String ? rawTime : null,
  );
}

bool _compare(num actual, num expected, String comparator) {
  switch (comparator) {
    case '<':
      return actual < expected;
    case '<=':
      return actual <= expected;
    case '>':
      return actual > expected;
    case '>=':
      return actual >= expected;
    case '==':
      return actual == expected;
    case '!=':
      return actual != expected;
  }
  return false;
}
