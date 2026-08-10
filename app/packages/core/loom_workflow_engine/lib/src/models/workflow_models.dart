/// Specification for a single input parameter on a transition.
/// Each input is resolved from the caller-supplied values map
/// and interpolated as {input.<name>} inside effect values.
class TransitionInputSpec {
  final String type;
  final bool required;
  final String? visibleWhen;
  final List<String>? options;
  final String? modeGroup;
  final String? modeValue;
  final int? maxSelections;
  final String? writesTo;

  const TransitionInputSpec({
    required this.type,
    this.required = false,
    this.visibleWhen,
    this.options,
    this.modeGroup,
    this.modeValue,
    this.maxSelections,
    this.writesTo,
  });

  factory TransitionInputSpec.fromJson(Map<String, dynamic> json) =>
      TransitionInputSpec(
        type: json['type'] as String,
        required: json['required'] as bool? ?? false,
        visibleWhen: json['visibleWhen'] as String?,
        options: (json['options'] as List<dynamic>?)
            ?.map((value) => value as String)
            .toList(),
        modeGroup: json['modeGroup'] as String?,
        modeValue: json['modeValue'] as String?,
        maxSelections: json['maxSelections'] as int?,
        writesTo: json['writesTo'] as String?,
      );
}

/// A scalar field whose value must equal the acting individual persona ID.
class ActorEqualsFieldGuard {
  final String key;

  const ActorEqualsFieldGuard({required this.key});

  factory ActorEqualsFieldGuard.fromJson(Map<String, dynamic> json) =>
      ActorEqualsFieldGuard(key: json['key'] as String);
}

/// A guard condition on a transition. All non-null fields must pass (AND semantics).
class WorkflowGuard {
  final List<String>? allowedPersonaIds;
  final ListMembershipGuard? actorInList;
  final ActorEqualsFieldGuard? actorEqualsField;
  final KeyValueGuard? instanceDataEquals;

  /// A computed-field formula which must evaluate to true.
  final String? formula;
  final RelatedListGuard? relatedListMembership;
  final RelatedAggregateGuard? relatedAggregate;
  final CancellationDeadlineGuard? cancellationDeadline;
  final LocationOverlapGuard? locationOverlap;
  final List<String>? requiresWorkflowsComplete;

  const WorkflowGuard({
    this.allowedPersonaIds,
    this.actorInList,
    this.actorEqualsField,
    this.instanceDataEquals,
    this.formula,
    this.relatedListMembership,
    this.relatedAggregate,
    this.cancellationDeadline,
    this.locationOverlap,
    this.requiresWorkflowsComplete,
  });

  factory WorkflowGuard.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const WorkflowGuard();
    return WorkflowGuard(
      allowedPersonaIds: (json['allowedPersonaIds'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      actorInList: json['actorInList'] != null
          ? ListMembershipGuard.fromJson(
              json['actorInList'] as Map<String, dynamic>,
            )
          : null,
      actorEqualsField: json['actorEqualsField'] != null
          ? ActorEqualsFieldGuard.fromJson(
              json['actorEqualsField'] as Map<String, dynamic>,
            )
          : null,
      instanceDataEquals: json['instanceDataEquals'] != null
          ? KeyValueGuard.fromJson(
              json['instanceDataEquals'] as Map<String, dynamic>,
            )
          : null,
      formula: json['formula'] as String?,
      relatedListMembership: json['relatedInstanceField'] != null
          ? RelatedListGuard.fromJson(json)
          : null,
      relatedAggregate: json['relatedAggregate'] != null
          ? RelatedAggregateGuard.fromJson(
              json['relatedAggregate'] as Map<String, dynamic>,
            )
          : null,
      cancellationDeadline: json['cancellationDeadline'] != null
          ? CancellationDeadlineGuard.fromJson(
              json['cancellationDeadline'] as Map<String, dynamic>,
            )
          : null,
      locationOverlap: json['locationOverlap'] != null
          ? LocationOverlapGuard.fromJson(
              json['locationOverlap'] as Map<String, dynamic>,
            )
          : null,
      requiresWorkflowsComplete:
          (json['requiresWorkflowsComplete'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList(),
    );
  }

  bool get isEmpty =>
      (allowedPersonaIds == null || allowedPersonaIds!.isEmpty) &&
      actorInList == null &&
      actorEqualsField == null &&
      instanceDataEquals == null &&
      formula == null &&
      relatedListMembership == null &&
      relatedAggregate == null &&
      cancellationDeadline == null &&
      locationOverlap == null &&
      (requiresWorkflowsComplete == null || requiresWorkflowsComplete!.isEmpty);
}

/// A cutoff that permits a transition only while enough time remains before
/// an instance's date (and optional time) field.
class CancellationDeadlineGuard {
  final String dateField;
  final String? timeField;
  final num hoursBefore;

  const CancellationDeadlineGuard({
    required this.dateField,
    this.timeField,
    required this.hoursBefore,
  });

  factory CancellationDeadlineGuard.fromJson(Map<String, dynamic> json) =>
      CancellationDeadlineGuard(
        dateField: json['dateField'] as String,
        timeField: json['timeField'] as String?,
        hoursBefore: json['hoursBefore'] as num,
      );
}

/// Prevents overlapping bookings of the same location within one workflow
/// type. Evaluation requires a live sibling-instance query, so it is handled
/// by [LocalWorkflowEngineApi] rather than [evaluateGuard].
class LocationOverlapGuard {
  final String locationField;
  final String dateField;
  final String? timeField;
  final num durationMinutes;

  const LocationOverlapGuard({
    required this.locationField,
    required this.dateField,
    this.timeField,
    required this.durationMinutes,
  });

  factory LocationOverlapGuard.fromJson(Map<String, dynamic> json) =>
      LocationOverlapGuard(
        locationField: json['locationField'] as String,
        dateField: json['dateField'] as String,
        timeField: json['timeField'] as String?,
        durationMinutes: json['durationMinutes'] as num,
      );
}

/// A live aggregate over instances in a related workflow type.
class RelatedAggregateGuard {
  final String workflowType;
  final Map<String, dynamic> filter;
  final String op;
  final String? field;
  final String comparator;
  final dynamic compareTo;

  const RelatedAggregateGuard({
    required this.workflowType,
    required this.filter,
    required this.op,
    this.field,
    required this.comparator,
    required this.compareTo,
  });

  factory RelatedAggregateGuard.fromJson(Map<String, dynamic> json) =>
      RelatedAggregateGuard(
        workflowType: json['workflowType'] as String,
        filter: Map<String, dynamic>.from(json['filter'] as Map),
        op: json['op'] as String,
        field: json['field'] as String?,
        comparator: json['comparator'] as String,
        compareTo: json['compareTo'],
      );
}

/// A query that selects an instance to transition from another instance's
/// effect.
class RelatedTransitionQuery {
  final String workflowType;
  final Map<String, dynamic> filter;
  final String? sortKey;
  final int? limit;

  const RelatedTransitionQuery({
    required this.workflowType,
    required this.filter,
    this.sortKey,
    this.limit,
  });

  factory RelatedTransitionQuery.fromJson(Map<String, dynamic> json) =>
      RelatedTransitionQuery(
        workflowType: json['workflowType'] as String,
        filter: Map<String, dynamic>.from(json['filter'] as Map),
        sortKey: json['sortKey'] as String?,
        limit: json['limit'] as int?,
      );
}

class RelatedListGuard {
  final String relatedInstanceField;
  final String relatedListField;
  const RelatedListGuard({
    required this.relatedInstanceField,
    required this.relatedListField,
  });
  factory RelatedListGuard.fromJson(Map<String, dynamic> json) =>
      RelatedListGuard(
        relatedInstanceField: json['relatedInstanceField'] as String,
        relatedListField: json['relatedListField'] as String,
      );
}

/// Guards that check list membership: whether a persona ID is present or absent
/// in a list-valued `instanceData` field.
class ListMembershipGuard {
  final String key;
  final bool present;

  const ListMembershipGuard({required this.key, required this.present});

  factory ListMembershipGuard.fromJson(Map<String, dynamic> json) {
    return ListMembershipGuard(
      key: json['key'] as String,
      present: json['present'] as bool,
    );
  }
}

/// Guards that check value equality on an arbitrary `instanceData` field.
class KeyValueGuard {
  final String key;
  final dynamic value;

  const KeyValueGuard({required this.key, required this.value});

  factory KeyValueGuard.fromJson(Map<String, dynamic> json) {
    return KeyValueGuard(key: json['key'] as String, value: json['value']);
  }
}

/// An effect applied to `instanceData` on a successful transition.
class WorkflowEffect {
  /// Operation: `set`, `appendUnique`, `removeValue`, `increment`, `decrement`,
  /// plus presentation-only ops like `removeFromTileGrid`.
  final String op;

  /// The key in `instanceData` to operate on. May be null for presentation-only
  /// ops (e.g. `removeFromTileGrid`) that don't touch instanceData at all.
  final String? key;

  /// The value for the operation. `$actor` is resolved to the acting persona ID,
  /// `null` sets the key to null.
  final dynamic value;
  final String? workflowType;
  final Map<String, dynamic>? fields;
  final String? relatedInstance;
  final RelatedTransitionQuery? relatedQuery;
  final String? transitionId;
  final String? anchorField;
  final Map<String, dynamic>? recurrenceRule;
  final String? condition;
  final List<WorkflowEffect> thenEffects;
  final List<WorkflowEffect> elseEffects;
  final List<WorkflowEffect>? onSuccessEffects;

  const WorkflowEffect({
    required this.op,
    this.key,
    this.value,
    this.workflowType,
    this.fields,
    this.relatedInstance,
    this.relatedQuery,
    this.transitionId,
    this.anchorField,
    this.recurrenceRule,
    this.condition,
    this.thenEffects = const [],
    this.elseEffects = const [],
    this.onSuccessEffects,
  });

  factory WorkflowEffect.fromJson(Map<String, dynamic> json) {
    List<WorkflowEffect> parseEffects(dynamic value) =>
        (value as List<dynamic>?)
            ?.map(
              (effect) =>
                  WorkflowEffect.fromJson(effect as Map<String, dynamic>),
            )
            .toList() ??
        const [];

    return WorkflowEffect(
      op: (json['op'] as String?) ?? '',
      key: json['key'] as String?,
      value: json['value'],
      workflowType: json['workflowType'] as String?,
      fields: (json['fields'] as Map<String, dynamic>?)?.map(
        (key, value) => MapEntry(key, value),
      ),
      relatedInstance: json['relatedInstance'] as String?,
      relatedQuery: json['relatedQuery'] != null
          ? RelatedTransitionQuery.fromJson(
              json['relatedQuery'] as Map<String, dynamic>,
            )
          : null,
      transitionId: json['transitionId'] as String?,
      anchorField: json['anchorField'] as String?,
      recurrenceRule: (json['recurrenceRule'] as Map<String, dynamic>?)?.map(
        (key, value) => MapEntry(key, value),
      ),
      condition: json['if'] as String?,
      thenEffects: parseEffects(json['then']),
      elseEffects: parseEffects(json['else']),
      onSuccessEffects: json['onSuccessEffects'] == null
          ? null
          : parseEffects(json['onSuccessEffects']),
    );
  }

  @override
  String toString() => 'WorkflowEffect(op: $op, key: $key, value: $value)';
}

/// A single transition: a label, icon, source states, target state, guard, effects.
class LoomWorkflowTransition {
  final String id;
  final String label;
  final String? icon;
  final String? tone;
  final List<String> from;
  final String? to; // null for orthogonal-lifecycle transitions (§2d)
  final WorkflowGuard guard;
  final List<WorkflowEffect> effects;
  final String? linkedWorkflowId;

  /// Input parameters declared by this transition (GAP-1).
  final Map<String, TransitionInputSpec>? inputs;

  const LoomWorkflowTransition({
    required this.id,
    required this.label,
    this.icon,
    this.tone,
    required this.from,
    this.to,
    this.guard = const WorkflowGuard(),
    this.effects = const [],
    this.linkedWorkflowId,
    this.inputs,
  });

  factory LoomWorkflowTransition.fromJson(Map<String, dynamic> json) {
    return LoomWorkflowTransition(
      id: json['id'] as String,
      label: json['label'] as String,
      icon: json['icon'] as String?,
      tone: json['tone'] as String?,
      from: (json['from'] as List<dynamic>).map((e) => e as String).toList(),
      to: json['to'] as String?,
      inputs: (json['inputs'] as Map<String, dynamic>?)?.map(
        (k, v) => MapEntry(
          k,
          TransitionInputSpec.fromJson(v as Map<String, dynamic>),
        ),
      ),
      guard: WorkflowGuard.fromJson(json['guard'] as Map<String, dynamic>?),
      effects:
          (json['effects'] as List<dynamic>?)
              ?.map((e) => WorkflowEffect.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      linkedWorkflowId: json['linkedWorkflowId'] as String?,
    );
  }
}

/// Metadata for a single state.
class LoomWorkflowState {
  final String label;
  final String? tone;
  final List<String>? editableFields;
  /// Optional, closed-by-default authorization for rendering field editors.
  ///
  /// This deliberately remains null when omitted from JSON. Unlike transition
  /// guards, an absent edit guard must not be interpreted as an open guard.
  final WorkflowGuard? editGuard;

  /// Optional authorization for creating an instance in this state.
  ///
  /// Unlike [editGuard], an absent creation guard deliberately means creation
  /// remains open.
  final WorkflowGuard? creationGuard;

  /// Optional authorization for reading this state. This is data-only for now;
  /// read-path enforcement is intentionally handled by a later ticket.
  final WorkflowGuard? readGuard;
  final bool isTerminal;

  const LoomWorkflowState({
    required this.label,
    this.tone,
    this.editableFields,
    this.editGuard,
    this.creationGuard,
    this.readGuard,
    this.isTerminal = false,
  });

  factory LoomWorkflowState.fromJson(Map<String, dynamic> json) {
    return LoomWorkflowState(
      label: json['label'] as String,
      tone: json['tone'] as String?,
      editableFields: (json['editableFields'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      editGuard: json['editGuard'] != null
          ? WorkflowGuard.fromJson(json['editGuard'] as Map<String, dynamic>)
          : null,
      creationGuard: json['creationGuard'] != null
          ? WorkflowGuard.fromJson(
              json['creationGuard'] as Map<String, dynamic>,
            )
          : null,
      readGuard: json['readGuard'] != null
          ? WorkflowGuard.fromJson(json['readGuard'] as Map<String, dynamic>)
          : null,
      isTerminal: json['isTerminal'] as bool? ?? false,
    );
  }
}

/// The workflow-level default visibility vocabulary.
enum WorkflowVisibilityDefault { public, membersOnly, guarded }

/// Workflow-level read-visibility declaration.
///
/// [isDeclared] keeps the distinction between an omitted visibility block and
/// an explicitly declared `public` block so validators can warn about legacy
/// workflows without changing their public default behavior.
class WorkflowVisibility {
  final WorkflowVisibilityDefault defaultValue;
  final WorkflowGuard? readGuard;
  final bool isDeclared;

  const WorkflowVisibility({
    this.defaultValue = WorkflowVisibilityDefault.public,
    this.readGuard,
    this.isDeclared = true,
  });

  /// Alias that reads naturally at call sites describing the resolved policy.
  WorkflowVisibilityDefault get defaultVisibility => defaultValue;

  factory WorkflowVisibility.fromJson(Object? value) {
    if (value == null) {
      return const WorkflowVisibility(isDeclared: false);
    }
    if (value is! Map) {
      throw const FormatException(
        'Workflow visibility must be an object when declared.',
      );
    }

    final rawDefault = value['default'];
    final defaultValue = switch (rawDefault) {
      null => WorkflowVisibilityDefault.public,
      'public' => WorkflowVisibilityDefault.public,
      'membersOnly' => WorkflowVisibilityDefault.membersOnly,
      'guarded' => WorkflowVisibilityDefault.guarded,
      _ => throw FormatException(
          'Invalid workflow visibility.default "$rawDefault". '
          'Expected one of: public, membersOnly, guarded.',
        ),
    };

    final rawReadGuard = value['readGuard'];
    WorkflowGuard? readGuard;
    if (rawReadGuard != null) {
      if (rawReadGuard is! Map) {
        throw const FormatException(
          'Workflow visibility.readGuard must be an object when declared.',
        );
      }
      readGuard = WorkflowGuard.fromJson(
        Map<String, dynamic>.from(rawReadGuard),
      );
    }

    if (defaultValue == WorkflowVisibilityDefault.guarded &&
        readGuard == null) {
      throw const FormatException(
        'Workflow visibility.default "guarded" requires a sibling readGuard.',
      );
    }

    return WorkflowVisibility(
      defaultValue: defaultValue,
      readGuard: readGuard,
      isDeclared: true,
    );
  }
}

/// A single action button on a repeated item in a repeater (GAP-1).
class RepeaterItemAction {
  final String transitionId;
  final Map<String, dynamic>? inputs;

  const RepeaterItemAction({required this.transitionId, this.inputs});

  factory RepeaterItemAction.fromJson(Map<String, dynamic> json) =>
      RepeaterItemAction(
        transitionId: json['transitionId'] as String,
        inputs: (json['inputs'] as Map<String, dynamic>?),
      );
}

/// Specification for a repeater widget that renders per-item action buttons (GAP-1).
class RepeaterSpec {
  final String source;
  final List<RepeaterItemAction> itemActions;

  const RepeaterSpec({required this.source, this.itemActions = const []});

  factory RepeaterSpec.fromJson(Map<String, dynamic> json) => RepeaterSpec(
    source: json['source'] as String,
    itemActions:
        (json['itemActions'] as List<dynamic>?)
            ?.map((e) => RepeaterItemAction.fromJson(e as Map<String, dynamic>))
            .toList() ??
        const [],
  );
}

/// An archetype-owned action (GAP-2, grammar v2).
///
/// This deliberately parses all fields for both action kinds. Conditional
/// validation belongs in the validator rather than the JSON model.
class WorkflowAction {
  final String kind;
  final String? label;
  final List<String>? byPersonaIds;
  final String? workflowType;
  final String? transitionId;
  final String? scope;
  final String? presentation;

  /// Values may contain {context.x} tokens resolved by the App Shell caller,
  /// never by the engine itself.
  final Map<String, dynamic>? prefill;
  final Map<String, dynamic>? inputs;

  const WorkflowAction({
    required this.kind,
    this.label,
    this.byPersonaIds,
    this.workflowType,
    this.transitionId,
    this.scope,
    this.presentation,
    this.prefill,
    this.inputs,
  });

  factory WorkflowAction.fromJson(Map<String, dynamic> json) => WorkflowAction(
    kind: json['kind'] as String,
    label: json['label'] as String?,
    byPersonaIds: (json['byPersonaIds'] as List<dynamic>?)
        ?.map((e) => e as String)
        .toList(),
    workflowType: json['workflowType'] as String?,
    transitionId: json['transitionId'] as String?,
    scope: json['scope'] as String?,
    presentation: json['presentation'] as String?,
    prefill: json['prefill'] as Map<String, dynamic>?,
    inputs: json['inputs'] as Map<String, dynamic>?,
  );
}

/// A render binding: where a workflow instance of a given state and role
/// should be rendered (tab + card surface family).
class RenderBinding {
  final List<String> states;
  final String role;
  final String tabId;
  final String cardSurfaceFamily;
  final String bindingKind; // "primary" or "summary"
  final String? audienceMemberField;
  final String? styleField;

  /// Repeater configuration (GAP-1) — renders per-item action buttons.
  final RepeaterSpec? repeater;

  /// Archetype-owned create and transition actions (GAP-2, grammar v2).
  final List<WorkflowAction> actions;
  final ResponseTableSpec? responseTable;
  final List<FilterableFacetSpec>? filterableFacets;

  const RenderBinding({
    required this.states,
    required this.role,
    required this.tabId,
    required this.cardSurfaceFamily,
    required this.bindingKind,
    this.audienceMemberField,
    this.styleField,
    this.repeater,
    this.actions = const [],
    this.responseTable,
    this.filterableFacets,
  });

  factory RenderBinding.fromJson(Map<String, dynamic> json) {
    return RenderBinding(
      states: (json['states'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      role: json['role'] as String,
      tabId: json['tabId'] as String,
      cardSurfaceFamily: json['cardSurfaceFamily'] as String,
      bindingKind: json['bindingKind'] as String,
      audienceMemberField: json['audienceMemberField'] as String?,
      styleField: json['styleField'] as String?,
      repeater: json['repeater'] != null
          ? RepeaterSpec.fromJson(json['repeater'] as Map<String, dynamic>)
          : null,
      actions: (json['actions'] as List<dynamic>?)
              ?.map((e) => WorkflowAction.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      responseTable: json['responseTable'] != null
          ? ResponseTableSpec.fromJson(
              json['responseTable'] as Map<String, dynamic>,
            )
          : null,
      filterableFacets: (json['filterableFacets'] as List<dynamic>?)
          ?.map((e) => FilterableFacetSpec.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class ResponseTableSpec {
  final String workflowType;
  final String eventField;
  final List<String> pendingStates;
  const ResponseTableSpec({
    required this.workflowType,
    required this.eventField,
    required this.pendingStates,
  });
  factory ResponseTableSpec.fromJson(Map<String, dynamic> json) =>
      ResponseTableSpec(
        workflowType: json['workflowType'] as String,
        eventField: json['eventField'] as String,
        pendingStates: (json['pendingStates'] as List<dynamic>)
            .map((e) => e as String)
            .toList(),
      );
}

class FilterableFacetSpec {
  final String field;
  final String label;
  const FilterableFacetSpec({required this.field, required this.label});
  factory FilterableFacetSpec.fromJson(Map<String, dynamic> json) =>
      FilterableFacetSpec(
        field: json['field'] as String,
        label: json['label'] as String,
      );
}

/// Schema metadata for a single field in `instanceData`.
class InstanceDataField {
  final String type;
  final bool required;
  final String? writableBy; // "formEntry" | "effect"
  final String? storage; // "inline" | "reference"
  final String? storageTarget;
  final bool searchable;
  final bool sortable;
  final String? displayIcon;
  final String? labelTemplate;
  final List<String>? displayContexts;
  final bool hideWhenEmpty;
  final int? maxLength;

  /// Optional metadata naming the external source for a field. This does not
  /// hydrate or evaluate that source; it only lets read-time formulas defer
  /// when the source value has not been supplied.
  final String? source;

  /// A pure, read-time formula. Computed fields cannot be written by effects
  /// or form edits.
  final String? formula;

  /// An optional formula which controls whether this field is shown by a
  /// schema-driven creation or editing surface.
  final String? visibleWhenEditing;

  /// Controls how a `type: "url"` field is opened.
  /// Valid values are handled by the app-shell renderer.
  final String? openMode;

  const InstanceDataField({
    required this.type,
    this.required = false,
    this.writableBy,
    this.storage,
    this.storageTarget,
    this.searchable = false,
    this.sortable = false,
    this.displayIcon,
    this.labelTemplate,
    this.displayContexts,
    this.hideWhenEmpty = false,
    this.maxLength,
    this.source,
    this.formula,
    this.visibleWhenEditing,
    this.openMode,
  });

  factory InstanceDataField.fromJson(Map<String, dynamic> json) {
    return InstanceDataField(
      type: json['type'] as String,
      required: json['required'] as bool? ?? false,
      writableBy: json['writableBy'] as String?,
      storage: json['storage'] as String?,
      storageTarget: json['storageTarget'] as String?,
      searchable: json['searchable'] as bool? ?? false,
      sortable: json['sortable'] as bool? ?? false,
      displayIcon: json['displayIcon'] as String?,
      labelTemplate: json['labelTemplate'] as String?,
      displayContexts: (json['displayContexts'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      hideWhenEmpty: json['hideWhenEmpty'] as bool? ?? false,
      maxLength: json['maxLength'] as int?,
      source: json['source'] as String?,
      formula: json['formula'] as String?,
      visibleWhenEditing: json['visibleWhenEditing'] as String?,
      openMode: json['openMode'] as String?,
    );
  }
}

/// A domain-agnostic workflow state machine definition.
class LoomWorkflowStateMachine {
  final String workflowType;
  final String initialState;
  final Map<String, LoomWorkflowState> states;
  final List<LoomWorkflowTransition> transitions;
  final List<RenderBinding> renderBindings;
  final Map<String, InstanceDataField> instanceDataSchema;
  final WorkflowVisibility visibility;

  const LoomWorkflowStateMachine({
    required this.workflowType,
    required this.initialState,
    required this.states,
    required this.transitions,
    this.renderBindings = const [],
    this.instanceDataSchema = const {},
    this.visibility = const WorkflowVisibility(isDeclared: false),
  });

  factory LoomWorkflowStateMachine.fromJson(
    Map<String, dynamic> json,
    String workflowType,
  ) {
    return LoomWorkflowStateMachine(
      workflowType: workflowType,
      initialState: json['initialState'] as String,
      states: (json['states'] as Map<String, dynamic>).map(
        (k, v) =>
            MapEntry(k, LoomWorkflowState.fromJson(v as Map<String, dynamic>)),
      ),
      transitions: (json['transitions'] as List<dynamic>)
          .map(
            (e) => LoomWorkflowTransition.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
      renderBindings:
          (json['renderBindings'] as List<dynamic>?)
              ?.map((e) => RenderBinding.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      instanceDataSchema:
          (json['instanceDataSchema'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(
              k,
              InstanceDataField.fromJson(v as Map<String, dynamic>),
            ),
          ) ??
          const {},
      visibility: json.containsKey('visibility')
          ? WorkflowVisibility.fromJson(json['visibility'])
          : const WorkflowVisibility(isDeclared: false),
    );
  }

  /// Returns all transitions originating from the given state.
  List<LoomWorkflowTransition> transitionsFrom(String state) {
    return transitions.where((t) => t.from.contains(state)).toList();
  }
}
