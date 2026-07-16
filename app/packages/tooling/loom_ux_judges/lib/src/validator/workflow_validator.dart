import 'dart:collection';

import 'package:loom_workflow_engine/src/evaluator/formula_evaluator.dart';
import 'package:loom_workflow_engine/src/evaluator/source_query.dart';
import 'package:loom_workflow_engine/src/models/workflow_models.dart';

/// A single validation finding — either an error (blocks pass) or a warning.
class ValidationFinding {
  final String type;
  final String message;
  final String location;
  final bool isWarning;

  const ValidationFinding({
    required this.type,
    required this.message,
    required this.location,
    this.isWarning = false,
  });

  Map<String, dynamic> toJson() => {
    'type': type,
    'message': message,
    'location': location,
    'isWarning': isWarning,
  };

  @override
  String toString() => '[$type] $location: $message';
}

/// The validation report produced by running all checks.
class ValidationReport {
  final List<ValidationFinding> findings;

  ValidationReport(this.findings);

  List<ValidationFinding> get errors =>
      findings.where((f) => !f.isWarning).toList();
  List<ValidationFinding> get warnings =>
      findings.where((f) => f.isWarning).toList();
  bool get passed => errors.isEmpty;

  Map<String, dynamic> toJson() => {
    'status': passed ? 'pass' : 'fail',
    'errorCount': errors.length,
    'warningCount': warnings.length,
    'findings': findings.map((f) => f.toJson()).toList(),
  };
}

/// Validates a set of workflow definitions against the §7c checks.
///
/// Usage:
/// ```dart
/// final report = WorkflowValidator.validate(workflows);
/// if (!report.passed) {
///   for (final e in report.errors) print(e);
/// }
/// ```
///
/// Optional [templates] and [tableArchetypeConfigs] enable the
/// action-button-row and sortable-column checks respectively.
/// When not provided, those checks are skipped.
class WorkflowValidator {
  static const _knownEffectOps = <String>{
    'set',
    'append',
    'appendUnique',
    'removeValue',
    'increment',
    'decrement',
    'branch',
    'createInstance',
    'removeFromTileGrid',
  };

  static const _knownInputTypes = <String>{
    'text',
    'textarea',
    'number',
    'bool',
    'date',
    'time',
    'list',
    'map',
    'personaId',
    'personaId[]',
    'image',
    'text?',
    'textarea?',
    'number?',
    'bool?',
    'date?',
    'time?',
    'list?',
    'map?',
    'personaId?',
    'personaId[]?',
    'image?',
  };

  /// Templates map: templateName → { "slots": ["WorkflowActionButtonRow", ...] }
  /// Used by the action-button-row check (§7d).
  final Map<String, Map<String, dynamic>>? templates;

  /// Table archetype configs map: workflowType → { "columns": [{ "key": "...", "sortable": true }] }
  /// Used by the sortable-column check.
  final Map<String, Map<String, dynamic>>? tableArchetypeConfigs;

  /// Declared persona IDs that may be used in `allowedPersonaIds`.
  /// When provided, this drives dangling-persona checks.
  /// When omitted, persona-id dangling checks are skipped.
  final Set<String>? knownPersonaIds;

  WorkflowValidator({
    this.templates,
    this.tableArchetypeConfigs,
    this.knownPersonaIds,
  });

  /// Runs all validation checks against the given workflow definitions.
  /// [workflows] is a map of workflowType → LoomWorkflowStateMachine.
  ValidationReport validate(Map<String, LoomWorkflowStateMachine> workflows) {
    final findings = <ValidationFinding>[];

    for (final entry in workflows.entries) {
      final wfType = entry.key;
      final machine = entry.value;

      _checkStuckStates(machine, findings);
      _checkUnreachableStates(machine, findings);
      _checkDanglingReferences(machine, workflows, findings);
      _checkMissingLabels(machine, findings);
      _checkBindingCap(machine, findings);
      _checkEditableFieldsReferences(machine, findings);
      _checkFormulas(machine, findings);
      _checkGuardFormulas(machine, findings);
      _checkUnknownInputTypes(machine, findings);
      _checkInputReferences(machine, findings);
      _checkContextReferenceOutsideCreatable(machine, findings);
      _checkSourceQueries(machine, workflows, findings);
      _checkItemActionsInputs(machine, workflows, findings);
      _checkCreatablePrefill(machine, findings);

      if (knownPersonaIds != null && knownPersonaIds!.isNotEmpty) {
        _checkCreatablePersonaIds(machine, findings);
      }

      if (templates != null) {
        _checkActionButtonRow(machine, findings);
      }
      if (tableArchetypeConfigs != null &&
          tableArchetypeConfigs!.containsKey(wfType)) {
        _checkSortableFieldReferences(
          machine,
          tableArchetypeConfigs![wfType]!,
          findings,
        );
      }
    }

    _checkDependencyCycles(workflows, findings);

    return ValidationReport(findings);
  }

  // ---------------------------------------------------------------------------
  // Computed fields: formula references stay inside this workflow's schema,
  // function calls use the fixed engine vocabulary, and formula dependencies
  // form a directed acyclic graph.
  // ---------------------------------------------------------------------------
  void _checkFormulas(
    LoomWorkflowStateMachine machine,
    List<ValidationFinding> findings,
  ) {
    final dependencies = <String, Set<String>>{};
    for (final entry in machine.instanceDataSchema.entries) {
      final formula = entry.value.formula;
      if (formula == null) continue;
      final location =
          '${machine.workflowType}/instanceDataSchema/${entry.key}/formula';
      final referencedFields = _checkFormulaString(
        machine,
        formula,
        location,
        findings,
      );
      dependencies[entry.key] = referencedFields
          .where((field) => machine.instanceDataSchema[field]?.formula != null)
          .toSet();
    }

    final visiting = <String>{};
    final visited = <String>{};
    void visit(String field, List<String> path) {
      if (visiting.contains(field)) {
        final cycleStart = path.indexOf(field);
        final cycle = [...path.sublist(cycleStart), field];
        findings.add(
          ValidationFinding(
            type: 'circular_formula_dependency',
            message: 'Circular formula dependency: ${cycle.join(' → ')}',
            location:
                '${machine.workflowType}/instanceDataSchema/$field/formula',
          ),
        );
        return;
      }
      if (!visited.add(field)) return;
      visiting.add(field);
      for (final dependency in dependencies[field] ?? const <String>{}) {
        visit(dependency, [...path, field]);
      }
      visiting.remove(field);
    }

    for (final field in dependencies.keys) {
      visit(field, const []);
    }
  }

  /// Analyzes one formula string against [machine]'s schema. Returns the set
  /// of referenced fields (empty on syntax error).
  Set<String> _checkFormulaString(
    LoomWorkflowStateMachine machine,
    String formula,
    String location,
    List<ValidationFinding> findings,
  ) {
    FormulaAnalysis analysis;
    try {
      analysis = analyzeFormula(formula);
    } on FormulaEvaluationException catch (error) {
      findings.add(
        ValidationFinding(
          type: 'invalid_formula_syntax',
          message: error.message,
          location: location,
        ),
      );
      return const <String>{};
    }
    for (final field in analysis.referencedFields) {
      if (!machine.instanceDataSchema.containsKey(field)) {
        findings.add(
          ValidationFinding(
            type: 'unknown_formula_field',
            message:
                'Formula references "$field", which is not declared in instanceDataSchema.',
            location: location,
          ),
        );
      }
    }
    for (final function in analysis.functionNames) {
      if (!formulaFunctionNames.contains(function)) {
        findings.add(
          ValidationFinding(
            type: 'unknown_formula_function',
            message: 'Formula calls unknown function "$function".',
            location: location,
          ),
        );
      }
    }
    return analysis.referencedFields.toSet();
  }

  void _checkGuardFormulas(
    LoomWorkflowStateMachine machine,
    List<ValidationFinding> findings,
  ) {
    for (final t in machine.transitions) {
      final formula = t.guard.formula;
      if (formula == null) continue;
      _checkFormulaString(
        machine,
        formula,
        '${machine.workflowType}/transitions/${t.id}/guard/formula',
        findings,
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Stuck states (§7c): every non-terminal state must have ≥1 outgoing transition
  // ---------------------------------------------------------------------------
  void _checkStuckStates(
    LoomWorkflowStateMachine machine,
    List<ValidationFinding> findings,
  ) {
    for (final entry in machine.states.entries) {
      final stateName = entry.key;
      final state = entry.value;

      if (state.isTerminal) continue;

      final outgoing = machine.transitionsFrom(stateName);
      if (outgoing.isEmpty) {
        findings.add(
          ValidationFinding(
            type: 'stuck_state',
            message:
                'State "$stateName" (${state.label}) has no outgoing transitions '
                'and is not declared terminal. Add at least one transition '
                'originating from this state, or set "isTerminal": true.',
            location: '${machine.workflowType}/states/$stateName',
          ),
        );
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Unreachable states (§7c): BFS from initialState
  // ---------------------------------------------------------------------------
  void _checkUnreachableStates(
    LoomWorkflowStateMachine machine,
    List<ValidationFinding> findings,
  ) {
    final reachable = <String>{};
    final queue = Queue<String>.from([machine.initialState]);

    while (queue.isNotEmpty) {
      final current = queue.removeFirst();
      if (!reachable.add(current)) continue; // already visited

      for (final t in machine.transitionsFrom(current)) {
        if (t.to != null && !reachable.contains(t.to)) {
          queue.add(t.to!);
        }
      }
    }

    for (final stateName in machine.states.keys) {
      if (!reachable.contains(stateName)) {
        findings.add(
          ValidationFinding(
            type: 'unreachable_state',
            message:
                'State "$stateName" (${machine.states[stateName]!.label}) '
                'is not reachable from initialState '
                '"${machine.initialState}" via any transition path.',
            location: '${machine.workflowType}/states/$stateName',
          ),
        );
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Dangling references (§7c):
  //   - allowedPersonaIds: any persona ID referenced in a guard should exist
  //     (heuristic: check against all persona IDs across all workflows)
  //   - requiresWorkflowsComplete: target workflow type must exist in loaded set
  //   - linkedWorkflowId: target must exist (warning, may be external)
  //   - instanceDataSchema keys in guards/effects must exist in the schema
  // ---------------------------------------------------------------------------
  void _checkDanglingReferences(
    LoomWorkflowStateMachine machine,
    Map<String, LoomWorkflowStateMachine> allWorkflows,
    List<ValidationFinding> findings,
  ) {
    for (final t in machine.transitions) {
      // Check requiresWorkflowsComplete
      if (t.guard.requiresWorkflowsComplete != null) {
        for (final depWfType in t.guard.requiresWorkflowsComplete!) {
          if (!allWorkflows.containsKey(depWfType)) {
            findings.add(
              ValidationFinding(
                type: 'dangling_requires_workflows_complete',
                message:
                    'Transition "${t.id}"\'s guard.requiresWorkflowsComplete '
                    'references "$depWfType", which is not a known workflow type '
                    'in the loaded definitions set.',
                location:
                    '${machine.workflowType}/transitions/${t.id}/guard/'
                    'requiresWorkflowsComplete',
              ),
            );
          }
        }
      }

      // Check linkedWorkflowId (warning — may be external)
      if (t.linkedWorkflowId != null) {
        if (!allWorkflows.containsKey(t.linkedWorkflowId!)) {
          findings.add(
            ValidationFinding(
              type: 'dangling_linked_workflow_id',
              message:
                  'Transition "${t.id}"\'s linkedWorkflowId '
                  '"${t.linkedWorkflowId}" is not a known workflow type in the '
                  'loaded definitions set. If this is an external workflow, '
                  'this warning can be ignored.',
              location:
                  '${machine.workflowType}/transitions/${t.id}/linkedWorkflowId',
              isWarning: true,
            ),
          );
        }
      }

      // Check allowedPersonaIds against known persona IDs.
      // This is a warning, not an error — without a global persona registry,
      // a persona used by only one workflow in the loaded set may be
      // intentionally scoped, not a typo.
      if (t.guard.allowedPersonaIds != null) {
        // If a real persona registry is not available, skip this check rather
        // than failing valid fixture references due to reduced context.
        if (knownPersonaIds == null || knownPersonaIds!.isEmpty) {
          continue;
        }

        for (final personaId in t.guard.allowedPersonaIds!) {
          if (!knownPersonaIds!.contains(personaId)) {
            findings.add(
              ValidationFinding(
                type: 'dangling_allowed_persona_id',
                message:
                    'Transition "${t.id}"\'s guard.allowedPersonaIds references '
                    '"$personaId", which does not appear in the known persona '
                    'registry. This may indicate a typo or a persona ID that '
                    'was not declared anywhere.',
                location:
                    '${machine.workflowType}/transitions/${t.id}/guard/'
                    'allowedPersonaIds',
                isWarning: true,
              ),
            );
          }
        }
      }

      // Check instanceDataSchema keys in guard
      if (t.guard.actorInList != null) {
        final key = t.guard.actorInList!.key;
        if (!machine.instanceDataSchema.containsKey(key)) {
          findings.add(
            ValidationFinding(
              type: 'dangling_instance_data_key',
              message:
                  'Transition "${t.id}"\'s guard.actorInList references '
                  '"$key", which is not declared in instanceDataSchema.',
              location:
                  '${machine.workflowType}/transitions/${t.id}/guard/actorInList',
            ),
          );
        }
      }
      if (t.guard.instanceDataEquals != null) {
        final key = t.guard.instanceDataEquals!.key;
        if (!machine.instanceDataSchema.containsKey(key)) {
          findings.add(
            ValidationFinding(
              type: 'dangling_instance_data_key',
              message:
                  'Transition "${t.id}"\'s guard.instanceDataEquals references '
                  '"$key", which is not declared in instanceDataSchema.',
              location:
                  '${machine.workflowType}/transitions/${t.id}/guard/'
                  'instanceDataEquals',
            ),
          );
        }
      }

      if (t.guard.relatedListMembership != null) {
        final field = t.guard.relatedListMembership!.relatedInstanceField;
        if (!machine.instanceDataSchema.containsKey(field)) {
          findings.add(
            ValidationFinding(
              type: 'dangling_related_instance_field',
              message:
                  'guard.relatedInstanceField references "$field", which is not declared in instanceDataSchema.',
              location:
                  '${machine.workflowType}/transitions/${t.id}/guard/relatedInstanceField',
            ),
          );
        }
      }

      _checkEffects(machine, allWorkflows, t, t.effects, 'effects', findings);
    }
  }

  void _checkEffects(
    LoomWorkflowStateMachine machine,
    Map<String, LoomWorkflowStateMachine> allWorkflows,
    LoomWorkflowTransition transition,
    List<WorkflowEffect> effects,
    String path,
    List<ValidationFinding> findings,
  ) {
    for (var i = 0; i < effects.length; i++) {
      final effect = effects[i];
      final location =
          '${machine.workflowType}/transitions/${transition.id}/$path[$i]';

      if (!_knownEffectOps.contains(effect.op)) {
        final knownOps = _knownEffectOps.toList()..sort();
        findings.add(
          ValidationFinding(
            type: 'unknown_effect_op',
            message:
                'Effect uses unknown op "${effect.op}". Known ops: $knownOps.',
            location: location,
          ),
        );
        continue;
      }

      if (effect.op == 'branch') {
        final condition = effect.condition;
        if (condition == null || condition.isEmpty) {
          findings.add(
            ValidationFinding(
              type: 'invalid_formula_syntax',
              message: 'branch effect has no "if" condition.',
              location: location,
            ),
          );
        } else {
          _checkFormulaString(machine, condition, '$location/if', findings);
        }
        _checkEffects(
          machine,
          allWorkflows,
          transition,
          effect.thenEffects,
          '$path[$i]/then',
          findings,
        );
        _checkEffects(
          machine,
          allWorkflows,
          transition,
          effect.elseEffects,
          '$path[$i]/else',
          findings,
        );
        continue;
      }

      if (effect.op == 'createInstance') {
        final targetType = effect.workflowType;
        final target = targetType == null ? null : allWorkflows[targetType];
        if (targetType == null || target == null) {
          findings.add(
            ValidationFinding(
              type: 'dangling_create_instance_target',
              message:
                  'createInstance references workflowType "${targetType ?? '<missing>'}", which is not a known workflow type in the loaded definitions set.',
              location: location,
            ),
          );
          continue;
        }
        for (final key in (effect.fields ?? const <String, dynamic>{}).keys) {
          final targetField = target.instanceDataSchema[key];
          if (targetField == null) {
            findings.add(
              ValidationFinding(
                type: 'dangling_instance_data_key',
                message:
                    'createInstance sets "$key", which is not declared in "$targetType"\'s instanceDataSchema.',
                location: '$location/fields/$key',
              ),
            );
          } else if (targetField.formula != null || targetField.source != null) {
            findings.add(
              ValidationFinding(
                type: 'computed_field_written_by_effect',
                message:
                    'createInstance sets computed field "$key" on "$targetType". Computed fields are read-only.',
                location: '$location/fields/$key',
              ),
            );
          }
        }
        continue;
      }

      if (effect.key == null) continue;

      if (effect.relatedInstance != null) {
        if (!machine.instanceDataSchema.containsKey(effect.relatedInstance)) {
          findings.add(
            ValidationFinding(
              type: 'dangling_related_instance_field',
              message:
                  'Effect\'s relatedInstance references "${effect.relatedInstance}", which is not declared in this workflow\'s instanceDataSchema. It must be a field holding the target instance\'s id.',
              location: location,
            ),
          );
        }
        continue;
      }

      if (!machine.instanceDataSchema.containsKey(effect.key)) {
        findings.add(
          ValidationFinding(
            type: 'dangling_instance_data_key',
            message:
                'Effect references "${effect.key}", which is not declared in instanceDataSchema.',
            location: location,
          ),
        );
      } else if (machine.instanceDataSchema[effect.key]?.formula != null || machine.instanceDataSchema[effect.key]?.source != null) {
        findings.add(
          ValidationFinding(
            type: 'computed_field_written_by_effect',
            message:
                'Effect attempts to write computed field "${effect.key}". Computed fields are read-only.',
            location: location,
          ),
        );
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Dependency cycles (§7c): DFS on requiresWorkflowsComplete graph
  // ---------------------------------------------------------------------------
  void _checkDependencyCycles(
    Map<String, LoomWorkflowStateMachine> workflows,
    List<ValidationFinding> findings,
  ) {
    // Build adjacency map from requiresWorkflowsComplete
    final adj = <String, Set<String>>{};
    for (final entry in workflows.entries) {
      adj.putIfAbsent(entry.key, () => <String>{});
      for (final t in entry.value.transitions) {
        if (t.guard.requiresWorkflowsComplete != null) {
          for (final dep in t.guard.requiresWorkflowsComplete!) {
            if (workflows.containsKey(dep)) {
              adj[entry.key]!.add(dep);
            }
          }
        }
      }
    }

    // DFS cycle detection
    const white = 0, gray = 1, black = 2;
    final color = <String, int>{};
    final parent = <String, String?>{};

    bool dfs(String node) {
      color[node] = gray;
      for (final neighbor in adj[node] ?? <String>{}) {
        if ((color[neighbor] ?? white) == gray) {
          // Build cycle path
          final cycle = <String>[];
          var cur = node;
          cycle.add(neighbor);
          while (cur != neighbor) {
            cycle.add(cur);
            cur = parent[cur]!;
          }
          cycle.add(neighbor);
          findings.add(
            ValidationFinding(
              type: 'dependency_cycle',
              message:
                  'Dependency cycle detected in requiresWorkflowsComplete: '
                  '${cycle.reversed.join(' → ')}',
              location: 'requiresWorkflowsComplete graph',
            ),
          );
          return false;
        }
        if ((color[neighbor] ?? white) == white) {
          parent[neighbor] = node;
          if (!dfs(neighbor)) return false;
        }
      }
      color[node] = black;
      return true;
    }

    for (final node in adj.keys) {
      if ((color[node] ?? white) == white) {
        dfs(node);
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Missing labels (§7c): every transition must have a label
  // ---------------------------------------------------------------------------
  void _checkMissingLabels(
    LoomWorkflowStateMachine machine,
    List<ValidationFinding> findings,
  ) {
    for (final t in machine.transitions) {
      if (t.label.isEmpty) {
        findings.add(
          ValidationFinding(
            type: 'missing_label',
            message:
                'Transition "${t.id}" has no label. Every transition must have '
                'a non-empty label for button display text.',
            location: '${machine.workflowType}/transitions/${t.id}',
          ),
        );
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Binding cap (§2a, §7c): ≤32 renderBindings, ≤16 distinct roles
  // ---------------------------------------------------------------------------
  void _checkBindingCap(
    LoomWorkflowStateMachine machine,
    List<ValidationFinding> findings,
  ) {
    final bindingCount = machine.renderBindings.length;
    if (bindingCount > 32) {
      findings.add(
        ValidationFinding(
          type: 'binding_cap_exceeded',
          message:
              'Workflow "${machine.workflowType}" has $bindingCount renderBindings '
              '(cap is 32). This many bindings almost always indicates two '
              'workflows that should be separated.',
          location: '${machine.workflowType}/renderBindings',
          isWarning: true,
        ),
      );
    }

    final roles = machine.renderBindings.map((b) => b.role).toSet();
    if (roles.length > 16) {
      findings.add(
        ValidationFinding(
          type: 'binding_cap_exceeded',
          message:
              'Workflow "${machine.workflowType}" declares ${roles.length} '
              'distinct roles (cap is 16). This many roles is a smell — '
              'consider splitting into multiple workflows.',
          location: '${machine.workflowType}/renderBindings',
          isWarning: true,
        ),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Mandatory action-button-row slot (§7d):
  //   Every bindingKind:"primary" template must include WorkflowActionButtonRow
  // ---------------------------------------------------------------------------
  void _checkActionButtonRow(
    LoomWorkflowStateMachine machine,
    List<ValidationFinding> findings,
  ) {
    for (final binding in machine.renderBindings) {
      if (binding.bindingKind != 'primary') continue;

      final template = templates![binding.cardSurfaceFamily];
      if (template == null) {
        findings.add(
          ValidationFinding(
            type: 'missing_template',
            message:
                'Card surface family "${binding.cardSurfaceFamily}" used by '
                'renderBinding for states [${binding.states.join(', ')}] '
                '(role: ${binding.role}) has no registered template.',
            location:
                '${machine.workflowType}/renderBindings/${binding.cardSurfaceFamily}',
            isWarning: true,
          ),
        );
        continue;
      }

      final slots =
          (template['slots'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          <String>[];

      if (!slots.contains('WorkflowActionButtonRow')) {
        findings.add(
          ValidationFinding(
            type: 'missing_action_button_row',
            message:
                'Primary binding "${binding.cardSurfaceFamily}" for states '
                '[${binding.states.join(', ')}] (role: ${binding.role}) is '
                'missing the mandatory WorkflowActionButtonRow slot. '
                'Every primary-binding template must include exactly one '
                'WorkflowActionButtonRow (§7d).',
            location:
                '${machine.workflowType}/renderBindings/${binding.cardSurfaceFamily}/'
                'WorkflowActionButtonRow',
          ),
        );
      }
    }
  }

  // ---------------------------------------------------------------------------
  // editableFields only references writableBy:"formEntry" keys (§7a-i)
  // ---------------------------------------------------------------------------
  void _checkEditableFieldsReferences(
    LoomWorkflowStateMachine machine,
    List<ValidationFinding> findings,
  ) {
    for (final entry in machine.states.entries) {
      final stateName = entry.key;
      final state = entry.value;

      if (state.editableFields == null) continue;

      for (final fieldName in state.editableFields!) {
        final field = machine.instanceDataSchema[fieldName];
        if (field == null) {
          findings.add(
            ValidationFinding(
              type: 'dangling_instance_data_key',
              message:
                  'State "$stateName" editableFields references "$fieldName", '
                  'which is not declared in instanceDataSchema.',
              location:
                  '${machine.workflowType}/states/$stateName/editableFields',
            ),
          );
          continue;
        }

        if (field.writableBy != 'formEntry') {
          findings.add(
            ValidationFinding(
              type: 'effect_field_in_editable_fields',
              message:
                  'State "$stateName" editableFields references "$fieldName", '
                  'which is writableBy: "${field.writableBy ?? 'unspecified'}" — '
                  'only writableBy: "formEntry" fields may appear in editableFields '
                  '(§7a-i).',
              location:
                  '${machine.workflowType}/states/$stateName/editableFields',
            ),
          );
        }
      }
    }
  }

  // ---------------------------------------------------------------------------
  // sortable table column without backing sortable:true field (§3b, §7c)
  // ---------------------------------------------------------------------------
  void _checkSortableFieldReferences(
    LoomWorkflowStateMachine machine,
    Map<String, dynamic> tableConfig,
    List<ValidationFinding> findings,
  ) {
    final columns =
        (tableConfig['columns'] as List<dynamic>?)
            ?.map((e) => e as Map<String, dynamic>)
            .toList() ??
        <Map<String, dynamic>>[];

    for (final col in columns) {
      final key = col['key'] as String?;
      final sortable = col['sortable'] as bool? ?? false;

      if (!sortable || key == null) continue;

      final field = machine.instanceDataSchema[key];
      if (field == null) {
        findings.add(
          ValidationFinding(
            type: 'dangling_instance_data_key',
            message:
                'Table archetype column "$key" is declared sortable but the key '
                'is not declared in instanceDataSchema.',
            location: 'tableConfig/${machine.workflowType}/columns/$key',
          ),
        );
        continue;
      }

      if (!field.sortable) {
        findings.add(
          ValidationFinding(
            type: 'sortable_column_without_backing_field',
            message:
                'Table archetype column "$key" is declared sortable:true but '
                'the instanceDataSchema field "$key" has sortable:false. '
                'A sortable column requires the backing field to also declare '
                'sortable:true (§3b).',
            location: 'tableConfig/${machine.workflowType}/columns/$key',
          ),
        );
      }
    }
  }
  // ---------------------------------------------------------------------------
  // unknown_input_type: every transitions[].inputs[].type must be a known type
  // ---------------------------------------------------------------------------
  void _checkUnknownInputTypes(
    LoomWorkflowStateMachine machine,
    List<ValidationFinding> findings,
  ) {
    for (final t in machine.transitions) {
      final inputs = t.inputs;
      if (inputs == null) continue;
      for (final entry in inputs.entries) {
        if (!_knownInputTypes.contains(entry.value.type)) {
          final knownTypes = _knownInputTypes.toList()..sort();
          findings.add(
            ValidationFinding(
              type: 'unknown_input_type',
              message:
                  'Transition "${t.id}" input "${entry.key}" has unknown type '
                  '"${entry.value.type}". Known types: $knownTypes.',
              location:
                  '${machine.workflowType}/transitions/${t.id}/inputs/${entry.key}',
            ),
          );
        }
      }
    }
  }

  // ---------------------------------------------------------------------------
  // unknown_input_reference: every {input.<name>} inside a transition's own
  // effects must name a key declared in that transition's inputs map.
  // ---------------------------------------------------------------------------
  void _checkInputReferences(
    LoomWorkflowStateMachine machine,
    List<ValidationFinding> findings,
  ) {
    final inputTokenPattern = RegExp(r'\{input\.(\w+)\}');
    for (final t in machine.transitions) {
      final declaredInputs = t.inputs?.keys.toSet() ?? const <String>{};
      _scanInputTokens(
        machine,
        t,
        t.effects,
        'effects',
        inputTokenPattern,
        declaredInputs,
        findings,
      );
    }
  }

  void _scanInputTokens(
    LoomWorkflowStateMachine machine,
    LoomWorkflowTransition transition,
    List<WorkflowEffect> effects,
    String path,
    RegExp tokenPattern,
    Set<String> declaredInputs,
    List<ValidationFinding> findings,
  ) {
    for (var i = 0; i < effects.length; i++) {
      final effect = effects[i];
      final location =
          '${machine.workflowType}/transitions/${transition.id}/$path[$i]';

      void checkString(String? value, String subPath) {
        if (value == null) return;
        for (final match in tokenPattern.allMatches(value)) {
          final name = match.group(1)!;
          if (!declaredInputs.contains(name)) {
            findings.add(
              ValidationFinding(
                type: 'unknown_input_reference',
                message:
                    'Effect references {input.$name}, but "$name" is not '
                    'declared in this transition\'s inputs map.',
                location: '$location/$subPath',
              ),
            );
          }
        }
      }

      final effectValue = effect.value;
      if (effectValue != null) {
        checkString(effectValue.toString(),
            effect.key != null ? 'key=${effect.key}' : 'value');
      }

      final fields = effect.fields;
      if (fields != null) {
        for (final entry in fields.entries) {
          final v = entry.value;
          if (v != null) {
            checkString(v.toString(), 'fields/${entry.key}');
          }
        }
      }

      if (effect.op == 'branch') {
        _scanInputTokens(
          machine,
          transition,
          effect.thenEffects,
          '$path[$i]/then',
          tokenPattern,
          declaredInputs,
          findings,
        );
        _scanInputTokens(
          machine,
          transition,
          effect.elseEffects,
          '$path[$i]/else',
          tokenPattern,
          declaredInputs,
          findings,
        );
      }
    }
  }

  // ---------------------------------------------------------------------------
  // itemActions[].inputs reference check
  // ---------------------------------------------------------------------------
  void _checkItemActionsInputs(
    LoomWorkflowStateMachine machine,
    Map<String, LoomWorkflowStateMachine> allWorkflows,
    List<ValidationFinding> findings,
  ) {
    final itemTokenPattern = RegExp(r'\{item\.(\w+)\}');
    for (final binding in machine.renderBindings) {
      final repeater = binding.repeater;
      if (repeater == null) continue;
      final source = repeater.source;

      Map<String, InstanceDataField>? itemSchema;

      final query = SourceQuery.tryParse(source);
      if (query != null) {
        final targetMachine = allWorkflows[query.workflowType];
        if (targetMachine != null) {
          itemSchema = targetMachine.instanceDataSchema;
        }
      } else {
        final field = machine.instanceDataSchema[source];
        if (field != null && (field.type == 'list' || field.type == 'list?')) {
          continue;
        }
      }

      if (itemSchema == null) continue;

      for (final action in repeater.itemActions) {
        final actionInputs = action.inputs;
        if (actionInputs == null) continue;
        final location =
            '${machine.workflowType}/renderBindings/${binding.states.join(",")}/'
            'repeater/itemActions/${action.transitionId}';
        for (final entry in actionInputs.entries) {
          final value = entry.value?.toString() ?? '';
          for (final match in itemTokenPattern.allMatches(value)) {
            final fieldName = match.group(1)!;
            if (!itemSchema.containsKey(fieldName)) {
              findings.add(
                ValidationFinding(
                  type: 'unknown_item_reference',
                  message:
                      'itemActions[].inputs references {item.$fieldName}, '
                      'but "$fieldName" is not declared in the source type\'s '
                      'instanceDataSchema.',
                  location: '$location/inputs/${entry.key}',
                ),
              );
            }
          }
        }
      }
    }
  }

  // ---------------------------------------------------------------------------
  // creatable.byPersonaIds dangling-persona check
  // ---------------------------------------------------------------------------
  void _checkCreatablePersonaIds(
    LoomWorkflowStateMachine machine,
    List<ValidationFinding> findings,
  ) {
    if (knownPersonaIds == null || knownPersonaIds!.isEmpty) return;

    for (final binding in machine.renderBindings) {
      final creatable = binding.creatable;
      if (creatable == null) continue;
      for (final personaId in creatable.byPersonaIds) {
        if (!knownPersonaIds!.contains(personaId)) {
          findings.add(
            ValidationFinding(
              type: 'dangling_allowed_persona_id',
              message:
                  'creatable.byPersonaIds references "$personaId", which does '
                  'not appear in the known persona registry. This may indicate '
                  'a typo or a persona ID that was not declared anywhere.',
              location:
                  '${machine.workflowType}/renderBindings/${binding.states.join(",")}/'
                  'creatable/byPersonaIds',
              isWarning: true,
            ),
          );
        }
      }
    }
  }

  // ---------------------------------------------------------------------------
  // creatable.prefill field check
  // ---------------------------------------------------------------------------
  void _checkCreatablePrefill(
    LoomWorkflowStateMachine machine,
    List<ValidationFinding> findings,
  ) {
    for (final binding in machine.renderBindings) {
      final creatable = binding.creatable;
      if (creatable == null) continue;
      final prefill = creatable.prefill;
      if (prefill == null) continue;
      final location =
          '${machine.workflowType}/renderBindings/${binding.states.join(",")}/'
          'creatable/prefill';
      for (final key in prefill.keys) {
        final field = machine.instanceDataSchema[key];
        if (field == null) {
          findings.add(
            ValidationFinding(
              type: 'dangling_instance_data_key',
              message:
                  'creatable.prefill sets "$key", which is not declared in '
                  'instanceDataSchema.',
              location: '$location/$key',
            ),
          );
        } else if (field.formula != null || field.source != null) {
          findings.add(
            ValidationFinding(
              type: 'computed_field_written_by_effect',
              message:
                  'creatable.prefill writes computed field "$key". Computed '
                  'fields are read-only.',
              location: '$location/$key',
            ),
          );
        }
      }
    }
  }

  // ---------------------------------------------------------------------------
  // context_reference_outside_creatable
  // ---------------------------------------------------------------------------
  void _checkContextReferenceOutsideCreatable(
    LoomWorkflowStateMachine machine,
    List<ValidationFinding> findings,
  ) {
    final contextTokenPattern = RegExp(r'\{context\.(\w+)\}');

    for (final t in machine.transitions) {
      _scanContextTokens(
        machine,
        t,
        t.effects,
        'effects',
        contextTokenPattern,
        findings,
      );
    }
  }

  void _scanContextTokens(
    LoomWorkflowStateMachine machine,
    LoomWorkflowTransition transition,
    List<WorkflowEffect> effects,
    String path,
    RegExp tokenPattern,
    List<ValidationFinding> findings,
  ) {
    for (var i = 0; i < effects.length; i++) {
      final effect = effects[i];
      final location =
          '${machine.workflowType}/transitions/${transition.id}/$path[$i]';

      void checkString(String? value, String subPath) {
        if (value == null) return;
        if (tokenPattern.hasMatch(value)) {
          findings.add(
            ValidationFinding(
              type: 'context_reference_outside_creatable',
              message:
                  '{context.x} interpolation is only valid inside '
                  'creatable.prefill values, not in transition effects.',
              location: '$location/$subPath',
            ),
          );
        }
      }

      final effectValue = effect.value;
      if (effectValue != null) {
        checkString(effectValue.toString(),
            effect.key != null ? 'key=${effect.key}' : 'value');
      }

      final fields = effect.fields;
      if (fields != null) {
        for (final entry in fields.entries) {
          final v = entry.value;
          if (v != null) {
            checkString(v.toString(), 'fields/${entry.key}');
          }
        }
      }

      if (effect.op == 'branch') {
        _scanContextTokens(
          machine,
          transition,
          effect.thenEffects,
          '$path[$i]/then',
          tokenPattern,
          findings,
        );
        _scanContextTokens(
          machine,
          transition,
          effect.elseEffects,
          '$path[$i]/else',
          tokenPattern,
          findings,
        );
      }
    }
  }

  // ---------------------------------------------------------------------------
  // GAP-4 source query syntax validation
  // ---------------------------------------------------------------------------
  void _checkSourceQueries(
    LoomWorkflowStateMachine machine,
    Map<String, LoomWorkflowStateMachine> allWorkflows,
    List<ValidationFinding> findings,
  ) {
    for (final entry in machine.instanceDataSchema.entries) {
      final fieldName = entry.key;
      final field = entry.value;
      final source = field.source;
      if (source == null) continue;

      final location =
          '${machine.workflowType}/instanceDataSchema/$fieldName/source';

      final query = SourceQuery.tryParse(source);
      if (query == null) {
        findings.add(
          ValidationFinding(
            type: 'invalid_source_query_syntax',
            message:
                'Source query "$source" does not match the expected grammar: '
                'query(<workflowType> where <foreignField> == <localField>).',
            location: location,
          ),
        );
        continue;
      }

      final targetMachine = allWorkflows[query.workflowType];
      if (targetMachine == null) {
        findings.add(
          ValidationFinding(
            type: 'dangling_source_query_workflow_type',
            message:
                'Source query references workflowType "${query.workflowType}", '
                'which is not a known workflow type in the loaded definitions set.',
            location: location,
          ),
        );
        continue;
      }

      if (!targetMachine.instanceDataSchema.containsKey(query.foreignField)) {
        findings.add(
          ValidationFinding(
            type: 'dangling_instance_data_key',
            message:
                'Source query foreignField "${query.foreignField}" is not '
                'declared in "${query.workflowType}"\'s instanceDataSchema.',
            location: location,
          ),
        );
      }

      if (query.localField != 'id' &&
          !machine.instanceDataSchema.containsKey(query.localField)) {
        findings.add(
          ValidationFinding(
            type: 'dangling_instance_data_key',
            message:
                'Source query localField "${query.localField}" is not "id" and '
                'is not declared in this workflow\'s instanceDataSchema.',
            location: location,
          ),
        );
      }
    }
  }

}
