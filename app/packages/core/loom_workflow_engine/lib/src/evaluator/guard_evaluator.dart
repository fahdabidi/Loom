import '../models/workflow_models.dart';
import 'formula_evaluator.dart';

/// Why a field required to evaluate a guard is not available.
///
/// This is deliberately data rather than an exception. An unresolved source is
/// neither a passing nor a failing boolean guard: it is a third outcome which
/// callers must make visible and exclude from mutation.
class GuardInputUnavailable {
  const GuardInputUnavailable({
    required this.code,
    required this.message,
    this.dependency,
    this.cause,
  });

  final String code;
  final String message;

  /// The upstream unavailable field when this field is a dependent formula.
  final String? dependency;

  /// The source read failure, when there was one. This is retained for
  /// diagnostics and is never converted into a default guard value.
  final Object? cause;
}

enum GuardEvaluationStatus { passed, denied, unavailable }

/// A guard's tri-state evaluation result.
class GuardEvaluationResult {
  const GuardEvaluationResult._(this.status, this.unavailableInputs);

  const GuardEvaluationResult.passed()
    : this._(GuardEvaluationStatus.passed, const {});

  const GuardEvaluationResult.denied()
    : this._(GuardEvaluationStatus.denied, const {});

  const GuardEvaluationResult.unavailable(
    Map<String, GuardInputUnavailable> unavailableInputs,
  ) : this._(GuardEvaluationStatus.unavailable, unavailableInputs);

  final GuardEvaluationStatus status;
  final Map<String, GuardInputUnavailable> unavailableInputs;

  bool get passed => status == GuardEvaluationStatus.passed;
}

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
    // `.toUtc()` because the deadline is now an absolute instant and
    // `DateTime.now()` is local. Comparing the two directly was the same
    // mixed-zone mistake this change set out to remove, relocated: a deadline
    // resolved in UTC against a wall clock in whatever zone the host sits in.
    if (deadline == null ||
        (clock ?? DateTime.now)().toUtc().isAfter(deadline)) {
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

/// Evaluates [guard] while preserving unresolved input metadata.
///
/// This is the guard-path companion to formula deferral. Formula values whose
/// source inputs are unavailable are intentionally omitted from the data
/// projection; evaluating a guard over such an omission must not turn into a
/// boolean default (especially for negated guards).
GuardEvaluationResult evaluateGuardWithAvailability(
  WorkflowGuard guard,
  String fanId,
  Map<String, dynamic> instanceData, {
  Map<String, GuardInputUnavailable> unavailableInputs = const {},
  String? roleId,
  Set<String>? roleIds,
  Set<String>? completedWorkflowIds,
  num? precomputedRelatedAggregate,
  num? resolvedRelatedAggregateCompareTo,
  bool skipRelatedAggregate = false,
  DateTime Function()? clock,
}) {
  final referenced = <String>{
    if (guard.actorInList != null) guard.actorInList!.key,
    if (guard.actorEqualsField != null) guard.actorEqualsField!.key,
    if (guard.instanceDataEquals != null) guard.instanceDataEquals!.key,
    if (guard.cancellationDeadline != null) ...[
      guard.cancellationDeadline!.dateField,
      if (guard.cancellationDeadline!.timeField != null)
        guard.cancellationDeadline!.timeField!,
    ],
    if (guard.formula != null)
      ...analyzeFormula(guard.formula!).referencedFields,
  };
  final unavailable = <String, GuardInputUnavailable>{
    for (final field in referenced)
      if (unavailableInputs.containsKey(field))
        field: unavailableInputs[field]!,
  };
  if (unavailable.isNotEmpty) {
    final withDependencies = <String, GuardInputUnavailable>{...unavailable};
    final pending = List<String>.of(unavailable.keys);
    while (pending.isNotEmpty) {
      final field = pending.removeLast();
      final dependency = unavailableInputs[field]?.dependency;
      if (dependency == null || !unavailableInputs.containsKey(dependency)) {
        continue;
      }
      if (!withDependencies.containsKey(dependency)) {
        withDependencies[dependency] = unavailableInputs[dependency]!;
        pending.add(dependency);
      }
    }
    return GuardEvaluationResult.unavailable(withDependencies);
  }

  return evaluateGuard(
        guard,
        fanId,
        instanceData,
        roleId: roleId,
        roleIds: roleIds,
        completedWorkflowIds: completedWorkflowIds,
        precomputedRelatedAggregate: precomputedRelatedAggregate,
        resolvedRelatedAggregateCompareTo: resolvedRelatedAggregateCompareTo,
        skipRelatedAggregate: skipRelatedAggregate,
        clock: clock,
      )
      ? const GuardEvaluationResult.passed()
      : const GuardEvaluationResult.denied();
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
