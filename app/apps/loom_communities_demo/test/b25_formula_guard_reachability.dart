import 'package:loom_workflow_engine/loom_workflow_engine.dart';

/// Whether a transition's `formula` guard admits an actor, evaluated in
/// isolation from every other guard clause.
///
/// B25's shipped-workflow selector has no engine and precomputes no related
/// aggregates, so it must never route a candidate transition through the
/// shared engine guard evaluator (`evaluateGuard`): a `relatedAggregate`
/// guard would come back denied purely for lacking context the selector
/// cannot supply, which would break several shipped primary actions (Book
/// Club's `submit-nomination`, Youth Soccer's `respond-going`, ...) that pass
/// today. This evaluates `guard.formula` alone, with `evaluateFormula`, and
/// nothing else.
enum FormulaGuardVerdict {
  /// The formula evaluated to `true` for this actor and data.
  allowed,

  /// The formula evaluated to `false` for this actor and data.
  denied,

  /// No formula guard applies, the formula could not be resolved from the
  /// data available, or this transition belongs to a response workflow whose
  /// `instanceData` is the parent's rather than its own.
  unknown,
}

/// Three states, not two. [FormulaGuardVerdict.unknown] is the deliberately
/// safe default: treating it as denied would recreate the defect this file
/// exists to fix -- an unprovable instance would again lose to whichever
/// instance happened to be declared first.
FormulaGuardVerdict formulaGuardVerdictForTransition({
  required LoomWorkflowTransition transition,
  required Map<String, dynamic> instanceData,
  required String? actorId,
  required bool allowViewerResponse,
}) {
  // A response-workflow candidate's `instanceData` belongs to the *parent*
  // instance, not the response machine the transition is drawn from --
  // evaluating one against the other is a category error, so this makes no
  // attempt to resolve it.
  if (allowViewerResponse) return FormulaGuardVerdict.unknown;
  final formula = transition.guard.formula;
  if (formula == null) return FormulaGuardVerdict.unknown;
  try {
    final result = evaluateFormula(
      formula,
      instanceData: instanceData,
      actorId: actorId,
    );
    if (result is! bool) return FormulaGuardVerdict.unknown;
    return result ? FormulaGuardVerdict.allowed : FormulaGuardVerdict.denied;
  } on FormulaEvaluationException {
    return FormulaGuardVerdict.unknown;
  }
}

/// Whether at least one transition in [candidates] both matches a B25
/// primary-action term and remains reachable under its formula guard.
///
/// This ranks; it does not filter. [candidates] is exactly the row's
/// existing actionable-transition list, unchanged -- a formula-denied
/// transition still renders, still sorts, and is still available to a
/// walkthrough that reaches it through a different instance. This answers
/// only the one question the B25 selector's outer loop needs: does THIS
/// instance/binding/role combination genuinely offer the row's primary
/// action, or would the shipped UI refuse it at render time?
///
/// A `false` result must never raise. The caller is expected to reuse its
/// existing fallback slot so the row still ends in the designed, valid
/// `primary_action_unavailable` outcome rather than a selector failure --
/// exactly as it already does for the ordinary "no instance offers the
/// primary action at all" case.
bool b25PrimaryMatchIsReachable({
  required Iterable<LoomWorkflowTransition> candidates,
  required bool Function(LoomWorkflowTransition transition) matchesPrimaryTerm,
  required FormulaGuardVerdict Function(LoomWorkflowTransition transition)
  formulaVerdict,
}) {
  return candidates.any(
    (transition) =>
        matchesPrimaryTerm(transition) &&
        formulaVerdict(transition) != FormulaGuardVerdict.denied,
  );
}
