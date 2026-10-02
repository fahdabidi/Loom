import 'package:loom_workflow_engine/loom_workflow_engine.dart';

import 'b25_formula_guard_reachability.dart';

/// Field types this seam fills from the seed's own `instanceData` with a
/// plain text entry, mirroring exactly what
/// `_createAndPublishShippedAnnouncement` already does for Masjid's
/// announcement form -- plus `date`/`time`, filled through their own picker
/// interaction (see `arrangeRemoteInstanceFor`'s date/time handling), not a
/// text entry. Every other declared type -- `bool`, `fanId`, `fanId[]`,
/// `list`, `url` -- needs its own widget interaction this dispatch does not
/// build; a required field of any other type throws
/// [B25ArrangementOutOfScopeFailure] naming it, rather than guessing at an
/// interaction nobody has verified.
const b25ArrangeableFieldTypes = <String>{
  'text',
  'textarea',
  'number',
  'date',
  'time',
};

/// Date/time field types, named separately from [b25ArrangeableFieldTypes]
/// because they need a picker interaction rather than `tester.enterText`.
const b25DateTimeFieldTypes = <String>{'date', 'time'};

/// Clock functions whose presence beside a field's name in a `formula`
/// guard marks that field as bounded relative to the clock at verification
/// time (e.g. `isBefore(now(), expiresAt)`), rather than any value the seed
/// happened to record. This is a heuristic scoped to this seam's own
/// decision ("copy the seed" vs "synthesize a value relative to now"), not a
/// general formula parser -- see `arrangeRemoteInstanceFor`'s date/time
/// handling for what the two decisions mean in practice.
const _clockFunctionTokens = <String>['now(', 'isPast(', 'isFuture('];

/// Which of [dateTimeFields] a guard on [candidateTransitions] clock-compares,
/// so the caller must fill them with a value strictly after submission time
/// rather than accepting the date/time picker's "now" default -- see
/// "For clock-constrained fields that default is WRONG" in
/// `HARNESS-two-identity-arrangement-and-date-time-fields.md`.
Set<String> b25ClockConstrainedFields({
  required Iterable<LoomWorkflowTransition> candidateTransitions,
  required Set<String> dateTimeFields,
}) {
  if (dateTimeFields.isEmpty) return const <String>{};
  final result = <String>{};
  for (final transition in candidateTransitions) {
    final formula = transition.guard.formula;
    if (formula == null) continue;
    if (!_clockFunctionTokens.any(formula.contains)) continue;
    for (final field in dateTimeFields) {
      if (formula.contains(field)) result.add(field);
    }
  }
  return result;
}

/// Why a row is out of scope, coarse enough for a caller to decide whether a
/// second identity is worth authenticating -- see
/// [B25ArrangementOutOfScopeFailure.category] and
/// `arrangeRemoteInstanceFor`'s between-identities protocol. Retrying with a
/// different fan can only ever rescue [selfCreationDenied]: every other
/// category is identity-independent, so a retry would fail again for the
/// same reason and only cost an extra, pointless authentication.
enum B25ArrangementOutOfScopeCategory {
  laterState,
  effectBorn,
  selfCreationDenied,
  differentCreatorDenied,
  readGuardDenied,
  unsupportedFieldType,
  missingFieldValue,
}

/// A row B25's remote-arrangement seam cannot satisfy in this dispatch.
///
/// Distinct from every other row-scoped failure in
/// `b25_workflow_row_selection.dart`: an out-of-scope row is neither broken
/// nor unproven by the product -- it is a shape this increment deliberately
/// does not attempt (see `HARNESS-remote-data-strategy.md`,
/// "stop addressing seeded instance ids; arrange each row through the
/// product"). Two-identity rows this seam still cannot direct, effect-born
/// rows, genuinely later-state rows, a denied read-visibility guard, and
/// required fields of a type this seam does not fill all land here, each
/// with the reason stated plainly so the next increment knows exactly what
/// to build.
class B25ArrangementOutOfScopeFailure extends StateError {
  B25ArrangementOutOfScopeFailure(this.reason, this.category) : super(reason);

  final String reason;
  final B25ArrangementOutOfScopeCategory category;
}

/// One creation binding/action [machine] declares for its own initial state,
/// plus which role actually creates through it.
class _CreatorBindingResolution {
  const _CreatorBindingResolution({
    required this.binding,
    required this.action,
    required this.creatorRoleId,
  });

  final RenderBinding binding;
  final WorkflowAction action;
  final String creatorRoleId;
}

/// Finds the creation binding/action [machine] declares for its own initial
/// state, preferring one [roleId] may already use so a single-identity
/// row's resolved creator role is always [roleId] itself. Falls back to the
/// first declared creator for any other role when [roleId] cannot create,
/// which is what makes a row whose creator and actor are necessarily
/// different roles (`garden-volunteer-shift`: the coordinator creates, the
/// member signs up) resolvable at all. Returns `null` only when no role may
/// create from the initial state -- the row is effect-born.
_CreatorBindingResolution? _resolveCreatorBinding({
  required LoomWorkflowStateMachine machine,
  required String roleId,
}) {
  RenderBinding? fallbackBinding;
  WorkflowAction? fallbackAction;
  for (final binding in machine.renderBindings) {
    if (!binding.states.contains(machine.initialState)) continue;
    for (final action in binding.actions) {
      if (action.kind != 'create') continue;
      fallbackBinding ??= binding;
      fallbackAction ??= action;
      if (action.byRoleIds == null || action.byRoleIds!.contains(roleId)) {
        return _CreatorBindingResolution(
          binding: binding,
          action: action,
          creatorRoleId: roleId,
        );
      }
    }
  }
  if (fallbackBinding == null || fallbackAction == null) return null;
  return _CreatorBindingResolution(
    binding: fallbackBinding,
    action: fallbackAction,
    creatorRoleId: fallbackAction.byRoleIds?.first ?? roleId,
  );
}

/// The role that must create [machine]'s initial-state instance: [roleId]
/// itself whenever it may, otherwise whichever role the package's creation
/// binding names. Returns `null` only when no role may create at all (the
/// row is effect-born, created only by a sibling workflow's effect).
///
/// Pure and identity-independent -- unlike [planB25RemoteArrangement], this
/// needs no fan id, so a caller can learn who must authenticate as the
/// creator (fan A) BEFORE spending a live authentication round trip to find
/// out, and before even knowing whether a second identity will be needed at
/// all.
String? b25CreatorRoleIdFor({
  required LoomWorkflowStateMachine machine,
  required String roleId,
}) => _resolveCreatorBinding(machine: machine, roleId: roleId)?.creatorRoleId;

/// The exact steps to arrange a real, remote-addressable instance of
/// [machine]'s workflow through the product, using [fieldValues] (sourced
/// from the row's seed `instanceData`) as the creation form's input.
class B25ArrangementPlan {
  const B25ArrangementPlan({
    required this.creationBinding,
    required this.creationAction,
    required this.creatorRoleId,
    required this.fieldValues,
    required this.dateTimeFields,
    required this.clockConstrainedFields,
    required this.arrangedState,
    required this.syntheticInstanceData,
  });

  final RenderBinding creationBinding;
  final WorkflowAction creationAction;

  /// The role that actually creates the instance. Equal to the row's own
  /// acting `roleId` whenever that role may create; otherwise the role the
  /// package's creation binding names, so the caller knows who to
  /// authenticate as the instance's creator (fan A) before this plan's
  /// fields can be submitted -- see "take creatorFanId and actorFanId
  /// separately" in `HARNESS-two-identity-arrangement-and-date-time-fields.md`.
  final String creatorRoleId;

  /// Required, form-entry editable field values to submit, in iteration
  /// order of the workflow's `editableFields`. The seed stays the authority
  /// on what the row is about; it stops being an address. `date`/`time`
  /// fields are filled through their own picker, not `tester.enterText` --
  /// see [dateTimeFields].
  final Map<String, String> fieldValues;

  /// The subset of [fieldValues]' keys whose schema type is `date` or
  /// `time`, so the caller knows to drive the picker rather than enter text.
  final Set<String> dateTimeFields;

  /// The subset of [dateTimeFields] a guard on the row's own primary
  /// candidates clock-compares -- see [b25ClockConstrainedFields]. These need
  /// a value strictly after submission time; every other date/time field
  /// may accept the picker's "now" default, which satisfies the package
  /// precisely because nothing clock-compares it.
  final Set<String> clockConstrainedFields;

  /// The state the created instance will actually be in: always
  /// `machine.initialState`, never the seed's own recorded `currentState`.
  /// A seed's state is the row's DATA authority, not its STATE authority --
  /// see "arrange at the row's provable source state".
  final String arrangedState;

  /// The instance data the created row will actually carry: the seed's
  /// values with the creation action's own `prefill` resolved over them
  /// (every literal `"$actor"` replaced with the real creating fan --
  /// [creatorRoleId]'s holder, NOT necessarily the row's acting fan). The
  /// caller must address the created row by this, never by the seed's
  /// untouched `instanceData` -- a resolved `ownerFanId` is the real
  /// creator, not whatever the seed happened to record.
  final Map<String, dynamic> syntheticInstanceData;
}

/// Decides whether [machine]'s initial-state create path can be driven
/// through the product using [seedInstanceData] as the creation form's
/// input, and if so, returns the exact plan to execute.
///
/// [creatorFanId] is the real fan id that will authenticate and create the
/// instance; [actorFanId] is the real fan id that will go on to fire the
/// row's primary candidate transition. These are deliberately two separate
/// identities: the create form's own `prefill` resolves every literal
/// `"$actor"` to [creatorFanId] (that is who the product stamps as the
/// creator), while every primary candidate's `formula` guard is evaluated
/// with [actorFanId] (that is who is actually acting). A true
/// single-identity row passes the same fan id for both -- the caller decides
/// which, never this function.
///
/// This is what tells a true single-identity row (the actor may legitimately
/// act on their own creation) apart from a row whose role merely matches
/// while a formula guard requires a second, different identity -- Garden
/// Club's `garden-tool-loan`/`garden-tool-giveaway` deny a claimant who is
/// also the listing's own owner, even though both roles are `garden-member`.
/// It is also what makes a row whose creating role differs entirely from the
/// acting role (`garden-volunteer-shift`: the coordinator creates, the
/// member signs up) arrangeable at all: the creation-binding search below
/// does not require [roleId] itself to be able to create, and reports which
/// role can on [B25ArrangementPlan.creatorRoleId] so the caller knows who to
/// authenticate as the creator.
///
/// [matchesPrimaryTerm] identifies which of [candidateTransitions] (and, for
/// a later-state seed, which of [machine]'s transitions overall) are the
/// row's B25 primary action, as opposed to an alternate or unrelated
/// actionable transition. It scopes two separate checks: whether a
/// later-state seed's primary action genuinely requires a non-initial state,
/// and whether the formula-denial check below fires on the row's real
/// primary candidates rather than being diluted by an unrelated candidate
/// whose verdict happens to be [FormulaGuardVerdict.unknown].
///
/// A seed's own `currentState` is the row's DATA authority, never its STATE
/// authority: a package author may illustrate a workflow mid-flow while its
/// primary action still fires from `machine.initialState`. So a seed sitting
/// in a later state is arranged at `machine.initialState` whenever a primary
/// match fires from there -- see "arrange at the row's provable source
/// state". Only when no primary match fires from the initial state does this
/// stay out of scope as a genuine later-state row.
///
/// Throws [B25ArrangementOutOfScopeFailure] naming the first disqualifying
/// reason when it cannot.
B25ArrangementPlan planB25RemoteArrangement({
  required LoomWorkflowStateMachine machine,
  required String currentState,
  required String roleId,
  required String creatorFanId,
  required String actorFanId,
  required Map<String, dynamic> seedInstanceData,
  required List<LoomWorkflowTransition> candidateTransitions,
  required bool Function(LoomWorkflowTransition transition) matchesPrimaryTerm,
}) {
  // The candidates the formula-denial check below reasons over. Ordinarily
  // these are exactly the caller's own actionable-transition list; a
  // later-state seed replaces them with the machine's own primary matches
  // reachable from the initial state, since the caller's list was computed
  // against the seed's (irrelevant) recorded state.
  var denialCheckCandidates = candidateTransitions;

  if (currentState != machine.initialState) {
    final primaryFromInitialState = machine.transitions
        .where(
          (transition) =>
              matchesPrimaryTerm(transition) &&
              transition.from.contains(machine.initialState),
        )
        .toList(growable: false);
    if (primaryFromInitialState.isEmpty) {
      throw B25ArrangementOutOfScopeFailure(
        'Shipped workflow ${machine.workflowType} instance is in state '
        '"$currentState", not its initial state "${machine.initialState}", '
        'and no primary-action transition fires from the initial state '
        'either. A later-state row needs its intermediate transitions '
        'fired first, which this dispatch does not attempt.',
        B25ArrangementOutOfScopeCategory.laterState,
      );
    }
    denialCheckCandidates = primaryFromInitialState;
  }

  final creatorBinding = _resolveCreatorBinding(machine: machine, roleId: roleId);
  if (creatorBinding == null) {
    throw B25ArrangementOutOfScopeFailure(
      'Shipped workflow ${machine.workflowType} declares no create action '
      'from its initial state for any role. This row is effect-born '
      '(created only by a sibling workflow\'s effect), which this dispatch '
      'does not arrange.',
      B25ArrangementOutOfScopeCategory.effectBorn,
    );
  }
  final creationBinding = creatorBinding.binding;
  final creationAction = creatorBinding.action;
  final creatorRoleId = creatorBinding.creatorRoleId;

  final prefill = creationAction.prefill ?? const <String, dynamic>{};
  final syntheticInstanceData = <String, dynamic>{...seedInstanceData};
  for (final entry in prefill.entries) {
    syntheticInstanceData[entry.key] = entry.value == r'$actor'
        ? creatorFanId
        : entry.value;
  }

  // Scoped to primary-matching candidates only. The row's actionable-
  // transition list routinely carries alternate or unrelated transitions
  // alongside the primary one (e.g. a `leave-queue` beside `request-loan`),
  // and those carry no `formula` at all -- their verdict is
  // [FormulaGuardVerdict.unknown], never denied. Running `.every(denied)`
  // over the whole list lets such a candidate mask a primary match that is
  // genuinely, permanently denied once the actor becomes the instance's own
  // creator. `unknown` is deliberately left as a third state here too: a
  // primary match whose formula could not be resolved must not be treated
  // as denied, or an unprovable instance loses to whichever happened to be
  // declared first -- exactly the defect `b25_formula_guard_reachability.dart`
  // already exists to avoid.
  final primaryDenialCandidates = denialCheckCandidates
      .where(matchesPrimaryTerm)
      .toList(growable: false);
  if (primaryDenialCandidates.isNotEmpty &&
      primaryDenialCandidates.every(
        (transition) =>
            formulaGuardVerdictForTransition(
              transition: transition,
              instanceData: syntheticInstanceData,
              actorId: actorFanId,
              allowViewerResponse: false,
            ) ==
            FormulaGuardVerdict.denied,
      )) {
    final transitionIds = primaryDenialCandidates
        .map((transition) => transition.id)
        .join(', ');
    throw creatorFanId == actorFanId
        ? B25ArrangementOutOfScopeFailure(
            'Shipped workflow ${machine.workflowType} candidate transition(s) '
            '$transitionIds would deny $roleId once $roleId also becomes '
            'the instance\'s own creator -- a formula guard requires a '
            'second, different identity, which this dispatch does not '
            'arrange.',
            B25ArrangementOutOfScopeCategory.selfCreationDenied,
          )
        : B25ArrangementOutOfScopeFailure(
            'Shipped workflow ${machine.workflowType} candidate transition(s) '
            '$transitionIds would deny $roleId even with a different fan '
            '($creatorFanId, role $creatorRoleId) as the instance\'s '
            'creator -- a formula guard this dispatch cannot satisfy.',
            B25ArrangementOutOfScopeCategory.differentCreatorDenied,
          );
  }

  // A read-visibility gate is evaluated here, not merely a write-side guard:
  // a row this dispatch can create and whose primary formula would allow
  // the actor to act is still useless if the actor can never read the
  // instance back. `relatedAggregate` is left unresolved -- unknown, not
  // denied -- for the same reason b25_formula_guard_reachability.dart never
  // routes a formula guard through the shared engine evaluator: this seam
  // has no engine and precomputes no aggregates.
  final readGuard = machine.visibility.readGuard;
  if (readGuard != null &&
      readGuard.relatedAggregate == null &&
      !evaluateGuard(readGuard, actorFanId, syntheticInstanceData)) {
    throw B25ArrangementOutOfScopeFailure(
      'Shipped workflow ${machine.workflowType} declares a '
      'visibility.readGuard, and $roleId ($actorFanId) cannot read the '
      'instance this plan would create -- a read-visibility gate this '
      'dispatch does not arrange around.',
      B25ArrangementOutOfScopeCategory.readGuardDenied,
    );
  }

  final editableFields =
      machine.states[machine.initialState]?.editableFields ??
      const <String>[];
  final dateTimeFields = <String>{};
  final fieldValues = <String, String>{};
  for (final field in editableFields) {
    final schema = machine.instanceDataSchema[field];
    if (schema == null || !schema.required) {
      continue;
    }
    if (!b25ArrangeableFieldTypes.contains(schema.type)) {
      throw B25ArrangementOutOfScopeFailure(
        'Shipped workflow ${machine.workflowType} requires creation field '
        '"$field" of type "${schema.type}", which this dispatch does not '
        'know how to fill -- only ${b25ArrangeableFieldTypes.join('/')} '
        'fields are arranged today.',
        B25ArrangementOutOfScopeCategory.unsupportedFieldType,
      );
    }
    if (b25DateTimeFieldTypes.contains(schema.type)) {
      dateTimeFields.add(field);
    }
    final seedValue = seedInstanceData[field];
    if (seedValue == null) {
      throw B25ArrangementOutOfScopeFailure(
        'Shipped workflow ${machine.workflowType} requires creation field '
        '"$field", but the seed instance this row was selected from carries '
        'no value for it to submit.',
        B25ArrangementOutOfScopeCategory.missingFieldValue,
      );
    }
    fieldValues[field] = '$seedValue';
  }

  final clockConstrainedFields = b25ClockConstrainedFields(
    candidateTransitions: denialCheckCandidates,
    dateTimeFields: dateTimeFields,
  );

  return B25ArrangementPlan(
    creationBinding: creationBinding,
    creationAction: creationAction,
    creatorRoleId: creatorRoleId,
    fieldValues: fieldValues,
    dateTimeFields: dateTimeFields,
    clockConstrainedFields: clockConstrainedFields,
    arrangedState: machine.initialState,
    syntheticInstanceData: syntheticInstanceData,
  );
}
