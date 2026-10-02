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
/// product"). Two-identity rows, effect-born rows, later-state rows, and
/// required fields of a type this seam does not yet fill all land here, each
/// with the reason stated plainly so the next increment knows exactly what
/// to build.
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
  });

  final RenderBinding creationBinding;
  final WorkflowAction creationAction;

  /// Required, form-entry editable field values to submit, in iteration
  /// order of the workflow's `editableFields`. The seed stays the authority
  /// on what the row is about; it stops being an address.
  final Map<String, String> fieldValues;
}

/// Decides whether [machine]'s initial-state create path can be driven
/// entirely by [roleId] -- the same identity the row will act as -- using
/// [seedInstanceData] as the creation form's input, and if so, returns the
/// exact plan to execute.
///
/// [actorFanId] is the real fan id that will authenticate and create the
/// instance. It is used only to synthesize the instance data the created row
/// would actually carry (the creation action's own `prefill`, with every
/// literal `"$actor"` resolved to [actorFanId]) so that
/// [candidateTransitions]' formula guards can be evaluated against the data
/// arrangement would actually produce -- exactly as
/// [formulaGuardVerdictForTransition] already does for the selector's
/// original, seed-addressed candidates. This is what tells a true
/// single-identity row (the actor may legitimately act on their own
/// creation) apart from a row whose role merely matches while a formula
/// guard requires a second, different identity -- Garden Club's
/// `garden-tool-loan`/`garden-tool-giveaway` deny a claimant who is also the
/// listing's own owner, even though both roles are `garden-member`.
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
}) {
  if (currentState != machine.initialState) {
    throw B25ArrangementOutOfScopeFailure(
      'Shipped workflow ${machine.workflowType} instance is in state '
      '"$currentState", not its initial state "${machine.initialState}". A '
      'later-state row needs its intermediate transitions fired first, '
      'which this dispatch does not attempt.',
    );
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

  if (candidateTransitions.isNotEmpty &&
      candidateTransitions.every(
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
      '${candidateTransitions.map((transition) => transition.id).join(', ')} '
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
  );
}
