import 'package:loom_workflow_engine/loom_workflow_engine.dart';

import 'b25_formula_guard_reachability.dart';

/// Field types this seam fills from the seed's own `instanceData` with a
/// plain text entry, mirroring exactly what
/// `_createAndPublishShippedAnnouncement` already does for Masjid's
/// announcement form. Every other declared type -- `bool`, `date`, `time`,
/// `fanId`, `fanId[]`, `list`, `url` -- needs its own widget interaction this
/// dispatch does not build; a required field of any other type throws
/// [B25ArrangementOutOfScopeFailure] naming it, rather than guessing at an
/// interaction nobody has verified.
const b25ArrangeableFieldTypes = <String>{'text', 'textarea', 'number'};

/// A row B25's remote-arrangement seam cannot satisfy in this dispatch.
///
/// Distinct from every other row-scoped failure in
/// `b25_workflow_row_selection.dart`: an out-of-scope row is neither broken
/// nor unproven by the product -- it is a shape this increment deliberately
/// does not attempt (see `HARNESS-remote-data-strategy.md`,
/// "stop addressing seeded instance ids; arrange each row through the
/// product"). Two-identity rows, effect-born rows, genuinely later-state
/// rows, and required fields of a type this seam does not yet fill all land
/// here, each with the reason stated plainly so the next increment knows
/// exactly what to build.
class B25ArrangementOutOfScopeFailure extends StateError {
  B25ArrangementOutOfScopeFailure(this.reason) : super(reason);

  final String reason;
}

/// The exact steps to arrange a real, remote-addressable instance of
/// [machine]'s workflow through the product, using [fieldValues] (sourced
/// from the row's seed `instanceData`) as the creation form's input.
class B25ArrangementPlan {
  const B25ArrangementPlan({
    required this.creationBinding,
    required this.creationAction,
    required this.fieldValues,
    required this.arrangedState,
    required this.syntheticInstanceData,
  });

  final RenderBinding creationBinding;
  final WorkflowAction creationAction;

  /// Required, form-entry editable field values to submit, in iteration
  /// order of the workflow's `editableFields`. The seed stays the authority
  /// on what the row is about; it stops being an address.
  final Map<String, String> fieldValues;

  /// The state the created instance will actually be in: always
  /// `machine.initialState`, never the seed's own recorded `currentState`.
  /// A seed's state is the row's DATA authority, not its STATE authority --
  /// see "arrange at the row's provable source state".
  final String arrangedState;

  /// The instance data the created row will actually carry: the seed's
  /// values with the creation action's own `prefill` resolved over them
  /// (every literal `"$actor"` replaced with the real acting fan). The
  /// caller must address the created row by this, never by the seed's
  /// untouched `instanceData` -- a resolved `ownerFanId` is the real actor,
  /// not whatever the seed happened to record.
  final Map<String, dynamic> syntheticInstanceData;
}

/// Decides whether [machine]'s initial-state create path can be driven
/// entirely by [roleId] -- the same identity the row will act as -- using
/// [seedInstanceData] as the creation form's input, and if so, returns the
/// exact plan to execute.
///
/// [actorFanId] is the real fan id that will authenticate and create the
/// instance. It is used only to synthesize the instance data the created row
/// would actually carry (the creation action's own `prefill`, with every
/// literal `"$actor"` resolved to [actorFanId]) so that the row's primary
/// candidates' formula guards can be evaluated against the data arrangement
/// would actually produce -- exactly as [formulaGuardVerdictForTransition]
/// already does for the selector's original, seed-addressed candidates. This
/// is what tells a true single-identity row (the actor may legitimately act
/// on their own creation) apart from a row whose role merely matches while a
/// formula guard requires a second, different identity -- Garden Club's
/// `garden-tool-loan`/`garden-tool-giveaway` deny a claimant who is also the
/// listing's own owner, even though both roles are `garden-member`.
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
      );
    }
    denialCheckCandidates = primaryFromInitialState;
  }

  final creationBindings = machine.renderBindings.where(
    (binding) =>
        binding.states.contains(machine.initialState) &&
        binding.actions.any(
          (action) =>
              action.kind == 'create' &&
              (action.byRoleIds == null ||
                  action.byRoleIds!.contains(roleId)),
        ),
  );
  if (creationBindings.isEmpty) {
    throw B25ArrangementOutOfScopeFailure(
      'Shipped workflow ${machine.workflowType} declares no create action '
      '$roleId may use from its initial state. Either the row is '
      'effect-born (created only by a sibling workflow\'s effect) or '
      'creation belongs to a different role than the one this row acts as '
      '-- a two-identity row this dispatch does not arrange.',
    );
  }
  final creationBinding = creationBindings.first;
  final creationAction = creationBinding.actions.firstWhere(
    (action) =>
        action.kind == 'create' &&
        (action.byRoleIds == null || action.byRoleIds!.contains(roleId)),
  );

  final prefill = creationAction.prefill ?? const <String, dynamic>{};
  final syntheticInstanceData = <String, dynamic>{...seedInstanceData};
  for (final entry in prefill.entries) {
    syntheticInstanceData[entry.key] = entry.value == r'$actor'
        ? actorFanId
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
    throw B25ArrangementOutOfScopeFailure(
      'Shipped workflow ${machine.workflowType} candidate transition(s) '
      '${primaryDenialCandidates.map((transition) => transition.id).join(', ')} '
      'would deny $roleId once $roleId also becomes the instance\'s own '
      'creator -- a formula guard requires a second, different identity, '
      'which this dispatch does not arrange.',
    );
  }

  final editableFields =
      machine.states[machine.initialState]?.editableFields ??
      const <String>[];
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
      );
    }
    final seedValue = seedInstanceData[field];
    if (seedValue == null) {
      throw B25ArrangementOutOfScopeFailure(
        'Shipped workflow ${machine.workflowType} requires creation field '
        '"$field", but the seed instance this row was selected from carries '
        'no value for it to submit.',
      );
    }
    fieldValues[field] = '$seedValue';
  }

  return B25ArrangementPlan(
    creationBinding: creationBinding,
    creationAction: creationAction,
    fieldValues: fieldValues,
    arrangedState: machine.initialState,
    syntheticInstanceData: syntheticInstanceData,
  );
}
