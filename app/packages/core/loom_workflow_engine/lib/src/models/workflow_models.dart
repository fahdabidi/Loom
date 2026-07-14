/// A guard condition on a transition. All non-null fields must pass (AND semantics).
class WorkflowGuard {
  final List<String>? allowedPersonaIds;
  final ListMembershipGuard? actorInList;
  final KeyValueGuard? instanceDataEquals;

  /// A computed-field formula which must evaluate to true.
  final String? formula;
  final RelatedListGuard? relatedListMembership;
  final List<String>? requiresWorkflowsComplete;

  const WorkflowGuard({
    this.allowedPersonaIds,
    this.actorInList,
    this.instanceDataEquals,
    this.formula,
    this.relatedListMembership,
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
      instanceDataEquals: json['instanceDataEquals'] != null
          ? KeyValueGuard.fromJson(
              json['instanceDataEquals'] as Map<String, dynamic>,
            )
          : null,
      formula: json['formula'] as String?,
      relatedListMembership: json['relatedInstanceField'] != null
          ? RelatedListGuard.fromJson(json)
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
      instanceDataEquals == null &&
      formula == null &&
      relatedListMembership == null &&
      (requiresWorkflowsComplete == null || requiresWorkflowsComplete!.isEmpty);
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
  final String? condition;
  final List<WorkflowEffect> thenEffects;
  final List<WorkflowEffect> elseEffects;

  const WorkflowEffect({
    required this.op,
    this.key,
    this.value,
    this.workflowType,
    this.fields,
    this.relatedInstance,
    this.condition,
    this.thenEffects = const [],
    this.elseEffects = const [],
  });

  factory WorkflowEffect.fromJson(Map<String, dynamic> json) {
    return WorkflowEffect(
      op: (json['op'] as String?) ?? '',
      key: json['key'] as String?,
      value: json['value'],
      workflowType: json['workflowType'] as String?,
      fields: (json['fields'] as Map<String, dynamic>?)?.map(
        (key, value) => MapEntry(key, value),
      ),
      relatedInstance: json['relatedInstance'] as String?,
      condition: json['if'] as String?,
      thenEffects:
          (json['then'] as List<dynamic>?)
              ?.map(
                (effect) =>
                    WorkflowEffect.fromJson(effect as Map<String, dynamic>),
              )
              .toList() ??
          const [],
      elseEffects:
          (json['else'] as List<dynamic>?)
              ?.map(
                (effect) =>
                    WorkflowEffect.fromJson(effect as Map<String, dynamic>),
              )
              .toList() ??
          const [],
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
  });

  factory LoomWorkflowTransition.fromJson(Map<String, dynamic> json) {
    return LoomWorkflowTransition(
      id: json['id'] as String,
      label: json['label'] as String,
      icon: json['icon'] as String?,
      tone: json['tone'] as String?,
      from: (json['from'] as List<dynamic>).map((e) => e as String).toList(),
      to: json['to'] as String?,
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
  final bool isTerminal;

  const LoomWorkflowState({
    required this.label,
    this.tone,
    this.editableFields,
    this.isTerminal = false,
  });

  factory LoomWorkflowState.fromJson(Map<String, dynamic> json) {
    return LoomWorkflowState(
      label: json['label'] as String,
      tone: json['tone'] as String?,
      editableFields: (json['editableFields'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      isTerminal: json['isTerminal'] as bool? ?? false,
    );
  }
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

  const RenderBinding({
    required this.states,
    required this.role,
    required this.tabId,
    required this.cardSurfaceFamily,
    required this.bindingKind,
    this.audienceMemberField,
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
    );
  }
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

  const LoomWorkflowStateMachine({
    required this.workflowType,
    required this.initialState,
    required this.states,
    required this.transitions,
    this.renderBindings = const [],
    this.instanceDataSchema = const {},
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
    );
  }

  /// Returns all transitions originating from the given state.
  List<LoomWorkflowTransition> transitionsFrom(String state) {
    return transitions.where((t) => t.from.contains(state)).toList();
  }
}
