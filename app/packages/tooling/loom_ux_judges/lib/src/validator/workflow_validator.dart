import 'dart:collection';

import 'package:loom_workflow_engine/loom_workflow_engine.dart';
import 'package:loom_workflow_engine/src/evaluator/source_query.dart';

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
    'transitionRelated',
    'generateRecurringInstances',
  };

  static final RegExp _availabilityLikeFieldPattern = RegExp(
    r'^(availabilityState|availability|.*Status)$',
    caseSensitive: false,
  );
  static final RegExp _destructiveTransitionIdPattern = RegExp(
    r'(?:delist|remove|cancel|delete|archive|withdraw-listing)',
    caseSensitive: false,
  );

  static const _fabricatedIdentifierKeys = <String>{
    'checksum',
    'hash',
    'receiptid',
    'receipt_id',
    'transactionid',
    'transaction_id',
    'confirmationcode',
    'confirmation_code',
    'trackingnumber',
    'tracking_number',
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
    'fanId',
    'fanId[]',
    'roleId',
    'roleId[]',
    'image',
    'text?',
    'textarea?',
    'number?',
    'bool?',
    'date?',
    'time?',
    'list?',
    'map?',
    'fanId?',
    'fanId[]?',
    'roleId?',
    'roleId[]?',
    'image?',
  };

  /// Templates map: templateName → { "slots": ["WorkflowActionButtonRow", ...] }
  /// Used by the action-button-row check (§7d).
  final Map<String, Map<String, dynamic>>? templates;

  /// Table archetype configs map: workflowType → { "columns": [{ "key": "...", "sortable": true }] }
  /// Used by the sortable-column check.
  final Map<String, Map<String, dynamic>>? tableArchetypeConfigs;

  /// Declared role IDs that may be used in JSON `allowedRoleIds` guards.
  /// When provided, this drives dangling-role checks.
  /// When omitted, role-id dangling checks are skipped.
  final Set<String>? knownPersonaIds;
  final Set<String>? declaredTabIds;

  WorkflowValidator({
    this.templates,
    this.tableArchetypeConfigs,
    this.knownPersonaIds,
    this.declaredTabIds,
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
      _checkRelatedAggregateGuards(machine, workflows, findings);
      _checkMissingLabels(machine, findings);
      _checkDestructiveTransitionIgnoresAvailabilityField(machine, findings);
      _checkPossibleFabricatedIdentifier(machine, findings);
      _checkBindingCap(machine, findings);
      _checkNoReadVisibilityDeclared(machine, findings);
      _checkNoRenderBindingForReachableState(machine, findings);
      _checkDeadRoleBinding(machine, findings);
      _checkKnownCardSurfaceFamily(machine, findings);
      _checkKnownTabId(machine, findings);
      _checkEditableFieldsReferences(machine, findings);
      _checkEditableFieldsWithoutEditGuard(machine, findings);
      _checkNoDestructiveExitForManagedType(machine, findings);
      _checkFormulas(machine, findings);
      _checkGuardFormulas(machine, findings);
      _checkUnknownInputTypes(machine, findings);
      _checkInputReferences(machine, findings);
      _checkContextReferenceOutsideInstanceAction(machine, findings);
      _checkSourceQueries(machine, workflows, findings);
      _checkItemActionsInputs(machine, workflows, findings);
      _checkUnknownActionKinds(machine, findings);
      _checkUnknownActionScopes(machine, findings);
      _checkUnknownActionPresentations(machine, findings);
      _checkTabActionsCannotBeButtons(machine, findings);
      _checkDanglingActionWorkflowTypes(machine, workflows, findings);
      _checkCreateActionsCannotSetInputs(machine, findings);
      _checkDanglingActionTransitionIds(machine, findings);
      _checkTransitionActionsCannotBeTabScoped(machine, findings);
      _checkTransitionActionsCannotSetWorkflowType(machine, findings);
      _checkTransitionActionsCannotSetPrefill(machine, findings);
      _checkTransitionActionsCannotSetByPersonaIds(machine, findings);
      _checkUnknownActionInputReferences(machine, findings);
      _checkDuplicateActionTransitionIds(machine, findings);
      _checkCreatablePrefill(machine, workflows, findings);
      _checkResponseTableAndFacets(machine, workflows, findings);

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
    _checkNoCreationPathForEditableTypes(workflows, findings);

    return ValidationReport(findings);
  }

  void _checkRelatedAggregateGuards(
    LoomWorkflowStateMachine machine,
    Map<String, LoomWorkflowStateMachine> workflows,
    List<ValidationFinding> findings,
  ) {
    for (final transition in machine.transitions) {
      final related = transition.guard.relatedAggregate;
      if (related == null) continue;
      final location =
          '${machine.workflowType}/transitions/${transition.id}/guard/relatedAggregate';
      final target = workflows[related.workflowType];
      if (target == null) {
        findings.add(
          ValidationFinding(
            type: 'dangling_related_aggregate_workflow_type',
            message:
                'relatedAggregate.workflowType "${related.workflowType}" is not declared.',
            location: '$location/workflowType',
          ),
        );
      } else {
        for (final key in related.filter.keys) {
          if (key != r'$state' && !target.instanceDataSchema.containsKey(key)) {
            findings.add(
              ValidationFinding(
                type: 'dangling_related_aggregate_filter_field',
                message:
                    'relatedAggregate.filter references "$key", which is not declared on "${related.workflowType}".',
                location: '$location/filter/$key',
              ),
            );
          }
        }
      }
      final compareTo = related.compareTo;
      if (compareTo is Map) {
        final field = compareTo['relatedInstanceField'];
        if (field is! String ||
            !machine.instanceDataSchema.containsKey(field)) {
          findings.add(
            ValidationFinding(
              type: 'dangling_related_instance_field',
              message:
                  'relatedAggregate.compareTo.relatedInstanceField "${field ?? '<missing>'}" is not declared in instanceDataSchema.',
              location: '$location/compareTo/relatedInstanceField',
            ),
          );
        }
      }
    }
  }

  void _checkResponseTableAndFacets(
    LoomWorkflowStateMachine machine,
    Map<String, LoomWorkflowStateMachine> workflows,
    List<ValidationFinding> findings,
  ) {
    for (final binding in machine.renderBindings) {
      final base =
          '${machine.workflowType}/renderBindings/${binding.states.join(",")}';
      final responseTable = binding.responseTable;
      if (responseTable != null) {
        final target = workflows[responseTable.workflowType];
        if (target == null) {
          findings.add(
            ValidationFinding(
              type: 'dangling_response_table_workflow_type',
              message:
                  'responseTable.workflowType "${responseTable.workflowType}" is not declared.',
              location: '$base/responseTable/workflowType',
            ),
          );
        } else {
          if (!target.instanceDataSchema.containsKey(
            responseTable.eventField,
          )) {
            findings.add(
              ValidationFinding(
                type: 'unknown_response_table_field',
                message:
                    'responseTable.eventField "${responseTable.eventField}" is not declared on "${responseTable.workflowType}".',
                location: '$base/responseTable/eventField',
              ),
            );
          }
          for (final state in responseTable.pendingStates) {
            if (!target.states.containsKey(state)) {
              findings.add(
                ValidationFinding(
                  type: 'unknown_response_table_state',
                  message:
                      'responseTable.pendingStates contains undeclared state "$state".',
                  location: '$base/responseTable/pendingStates',
                ),
              );
            }
          }
        }
      }
      for (final facet
          in binding.filterableFacets ?? const <FilterableFacetSpec>[]) {
        final field = machine.instanceDataSchema[facet.field];
        if (field == null || field.formula == null) {
          findings.add(
            ValidationFinding(
              type: 'dangling_filterable_facet_field',
              message:
                  'filterableFacets field "${facet.field}" must be a declared formula field.',
              location: '$base/filterableFacets/${facet.field}',
            ),
          );
        }
      }
    }
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
  // Reachability + render coverage (§7c heuristic): every state reachable via
  // transitions should be listed in at least one renderBinding's `states`.
  // ---------------------------------------------------------------------------
  void _checkNoRenderBindingForReachableState(
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

    final boundStates = <String>{};
    for (final binding in machine.renderBindings) {
      boundStates.addAll(binding.states);
    }

    for (final stateName in machine.states.keys) {
      if (!reachable.contains(stateName)) continue;
      if (boundStates.contains(stateName)) continue;
      findings.add(
        ValidationFinding(
          type: 'no_render_binding_for_reachable_state',
          message:
              'State "$stateName" (${machine.states[stateName]!.label}) is '
              'reachable via a transition path but no renderBinding\'s "states" '
              'list includes it, so an instance sitting in this state renders '
              'on no tab and is invisible in the UI. Add a renderBinding '
              '(often "bindingKind": "summary") whose "states" list includes '
              'it, or confirm this state is intentionally never surfaced.',
          location: '${machine.workflowType}/states/$stateName',
          isWarning: true,
        ),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Role resolution shape checks: some role/tab combinations can never render.
  // ---------------------------------------------------------------------------
  void _checkDeadRoleBinding(
    LoomWorkflowStateMachine machine,
    List<ValidationFinding> findings,
  ) {
    for (final binding in machine.renderBindings) {
      final location =
          '${machine.workflowType}/renderBindings/${binding.states.join(",")}';

      if (binding.role == 'receiver' &&
          binding.tabId != 'admin' &&
          binding.audienceMemberField == null) {
        findings.add(
          ValidationFinding(
            type: 'dead_role_binding',
            message:
                'role: "receiver" never resolves on tab "${binding.tabId}" '
                '(only "admin" ever grants the receiver role, per '
                'render-bindings.md), so this binding can never render for '
                'anyone; use role: "any" instead, or move it to admin, or '
                'add audienceMemberField if this is meant to be a '
                'dynamic-audience notification.',
            location: '$location/role',
            isWarning: true,
          ),
        );
        continue;
      }

      if (binding.tabId == 'calendar' &&
          binding.role != 'any' &&
          !(binding.role == 'receiver' &&
              binding.audienceMemberField != null)) {
        findings.add(
          ValidationFinding(
            type: 'dead_role_binding',
            message:
                'the `calendar` tab passes no role-resolution callback, so only '
                'role: "any" (or role: "receiver" with a working '
                'audienceMemberField) can ever render there; role: "${binding.role}" '
                'will never resolve for anyone on this tab.',
            location: '$location/role',
            isWarning: true,
          ),
        );
      }
    }
  }

  void _checkKnownCardSurfaceFamily(
    LoomWorkflowStateMachine machine,
    List<ValidationFinding> findings,
  ) {
    for (final binding in machine.renderBindings) {
      if (knownWorkflowArchetypeIds.contains(binding.cardSurfaceFamily))
        continue;
      findings.add(
        ValidationFinding(
          type: 'unknown_card_surface_family',
          message:
              'cardSurfaceFamily "${binding.cardSurfaceFamily}" is not '
              'declared in knownWorkflowArchetypeIds (the registry-backed source '
              'of truth for render-binding families).',
          location:
              '${machine.workflowType}/renderBindings/${binding.states.join(",")}/cardSurfaceFamily',
        ),
      );
    }
  }

  void _checkKnownTabId(
    LoomWorkflowStateMachine machine,
    List<ValidationFinding> findings,
  ) {
    // Unlike _checkKnownCardSurfaceFamily (a fixed global registry, always
    // enforced), tabId declarations are caller-supplied context -- callers
    // that never pass declaredTabIds (most standalone WorkflowValidator unit
    // tests, exercising unrelated checks) haven't opted into this check, so
    // it stays silent rather than treating "no context given" the same as
    // "this community declared zero tabs." CommunityPackageValidator, the
    // one real production call site, always passes a concrete (possibly
    // empty) set, so real package validation is unaffected.
    if (declaredTabIds == null) return;
    final allowedTabIds = <String>{'home', 'messages', ...declaredTabIds!};
    for (final binding in machine.renderBindings) {
      if (allowedTabIds.contains(binding.tabId)) continue;
      findings.add(
        ValidationFinding(
          type: 'unknown_tab_id',
          message:
              'tabId "${binding.tabId}" is not a built-in tab ("home", '
              '"messages") and is not declared in appShell.tabs/roleTabs.',
          location:
              '${machine.workflowType}/renderBindings/${binding.states.join(",")}/tabId',
        ),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Dangling references (§7c):
  //   - allowedRoleIds: any role ID referenced in a guard should exist
  //     (heuristic: check against all role IDs across all workflows)
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

      // Check allowedRoleIds against known role IDs.
      // This is a warning, not an error — without a global role registry,
      // a role used by only one workflow in the loaded set may be
      // intentionally scoped, not a typo.
      if (t.guard.allowedPersonaIds != null) {
        // If a real role registry is not available, skip this check rather
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
                    'Transition "${t.id}"\'s guard.allowedRoleIds references '
                    '"$personaId", which does not appear in the known role '
                    'registry. This may indicate a typo or a role ID that '
                    'was not declared anywhere.',
                location:
                    '${machine.workflowType}/transitions/${t.id}/guard/'
                    'allowedRoleIds',
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

      if (t.guard.actorEqualsField != null) {
        final key = t.guard.actorEqualsField!.key;
        final field = machine.instanceDataSchema[key];
        if (field == null) {
          findings.add(
            ValidationFinding(
              type: 'dangling_actor_equals_field',
              message:
                  'Transition "${t.id}"\'s guard.actorEqualsField references '
                  '"$key", which is not declared in instanceDataSchema.',
              location:
                  '${machine.workflowType}/transitions/${t.id}/guard/actorEqualsField',
            ),
          );
        } else if (field.type == 'list' || field.type == 'list?') {
          findings.add(
            ValidationFinding(
              type: 'actor_equals_field_on_list_type',
              message:
                  'Transition "${t.id}"\'s guard.actorEqualsField references '
                  '"$key", which is list-typed. actorEqualsField compares a single '
                  'scalar value and cannot be used with a list field (use '
                  'actorInList instead).',
              location:
                  '${machine.workflowType}/transitions/${t.id}/guard/actorEqualsField',
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
    bool _isInputToken(dynamic value) =>
        value is String &&
        RegExp(r'^\{input\.[a-zA-Z0-9_]+\}$').hasMatch(value);

    int? parseInt(dynamic value) {
      if (value is int) return value;
      if (value is String) return int.tryParse(value);
      return null;
    }

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
          } else if (targetField.formula != null ||
              targetField.source != null) {
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

      if (effect.op == 'transitionRelated') {
        final relatedQuery = effect.relatedQuery;
        final targetType = relatedQuery?.workflowType;
        final target = targetType == null ? null : allWorkflows[targetType];
        if (target == null) {
          findings.add(
            ValidationFinding(
              type: 'dangling_transition_related_workflow_type',
              message:
                  'transitionRelated references workflowType "${targetType ?? '<missing>'}", which is not a known workflow type in the loaded definitions set.',
              location: '$location/relatedQuery/workflowType',
            ),
          );
          continue;
        }
        final transitionId = effect.transitionId;
        if (transitionId == null ||
            !target.transitions.any(
              (candidate) => candidate.id == transitionId,
            )) {
          findings.add(
            ValidationFinding(
              type: 'dangling_transition_related_transition_id',
              message:
                  'transitionRelated transitionId "${transitionId ?? '<missing>'}" is not declared on "$targetType".',
              location: '$location/transitionId',
            ),
          );
        }
        final sortKey = relatedQuery!.sortKey;
        if (sortKey != null &&
            !target.instanceDataSchema.containsKey(sortKey)) {
          findings.add(
            ValidationFinding(
              type: 'dangling_transition_related_sort_key',
              message:
                  'transitionRelated sortKey "$sortKey" is not declared in "$targetType"\'s instanceDataSchema.',
              location: '$location/relatedQuery/sortKey',
            ),
          );
        }
        final onSuccessEffects = effect.onSuccessEffects;
        if (onSuccessEffects != null) {
          _checkEffects(
            target,
            allWorkflows,
            transition,
            onSuccessEffects,
            '$location/onSuccessEffects',
            findings,
          );
        }
        continue;
      }

      if (effect.op == 'generateRecurringInstances') {
        final targetType = effect.workflowType;
        final target = targetType == null || _isInputToken(targetType)
            ? null
            : allWorkflows[targetType];
        if (targetType == null) {
          findings.add(
            ValidationFinding(
              type: 'dangling_generate_recurring_target',
              message:
                  'generateRecurringInstances references workflowType "${targetType ?? '<missing>'}", which is not a known workflow type in the loaded definitions set.',
              location: '$location/workflowType',
            ),
          );
          continue;
        }
        if (!_isInputToken(targetType) && target == null) {
          findings.add(
            ValidationFinding(
              type: 'dangling_generate_recurring_target',
              message:
                  'generateRecurringInstances references workflowType "$targetType", which is not a known workflow type in the loaded definitions set.',
              location: '$location/workflowType',
            ),
          );
          continue;
        }

        if (target != null) {
          for (final key in (effect.fields ?? const <String, dynamic>{}).keys) {
            final targetField = target.instanceDataSchema[key];
            if (targetField == null) {
              findings.add(
                ValidationFinding(
                  type: 'dangling_instance_data_key',
                  message:
                      'generateRecurringInstances sets "$key", which is not declared in "$targetType"\'s instanceDataSchema.',
                  location: '$location/fields/$key',
                ),
              );
            } else if (targetField.formula != null ||
                targetField.source != null) {
              findings.add(
                ValidationFinding(
                  type: 'computed_field_written_by_effect',
                  message:
                      'generateRecurringInstances sets computed field "$key" on "$targetType". Computed fields are read-only.',
                  location: '$location/fields/$key',
                ),
              );
            }
          }
        }

        final anchorField = effect.anchorField;
        if (anchorField == null || anchorField.isEmpty) {
          findings.add(
            ValidationFinding(
              type: 'missing_recurrence_anchor_field',
              message:
                  'generateRecurringInstances requires a non-empty anchorField.',
              location: '$location/anchorField',
            ),
          );
        } else if (!_isInputToken(anchorField)) {
          if (!(effect.fields ?? const <String, dynamic>{}).containsKey(
            anchorField,
          )) {
            findings.add(
              ValidationFinding(
                type: 'dangling_recurrence_anchor_field',
                message:
                    'generateRecurringInstances anchorField "$anchorField" must be a key in fields.',
                location: '$location/anchorField',
              ),
            );
          }
          final targetField = target?.instanceDataSchema[anchorField];
          if (targetField != null && targetField.type != 'date') {
            findings.add(
              ValidationFinding(
                type: 'invalid_recurrence_anchor_field_type',
                message:
                    'generateRecurringInstances anchorField "$anchorField" must name a date field on "$targetType".',
                location: '$location/anchorField',
              ),
            );
          }
        }

        final recurrenceRule = effect.recurrenceRule;
        if (recurrenceRule == null) {
          findings.add(
            ValidationFinding(
              type: 'missing_recurrence_rule',
              message: 'generateRecurringInstances requires a recurrenceRule.',
              location: '$location/recurrenceRule',
            ),
          );
          continue;
        }

        final freq = recurrenceRule['freq'];
        final hasStaticFreq = !_isInputToken(freq);
        final validFreq =
            freq is String &&
            const {'daily', 'weekly', 'monthly'}.contains(freq);
        if (freq == null) {
          findings.add(
            ValidationFinding(
              type: 'missing_recurrence_freq',
              message: 'recurrenceRule.freq is required.',
              location: '$location/recurrenceRule/freq',
            ),
          );
        } else if (hasStaticFreq && !validFreq) {
          findings.add(
            ValidationFinding(
              type: 'invalid_recurrence_freq',
              message: 'recurrenceRule.freq must be daily, weekly, or monthly.',
              location: '$location/recurrenceRule/freq',
            ),
          );
        }

        final count = recurrenceRule['count'];
        if (count == null) {
          findings.add(
            ValidationFinding(
              type: 'missing_recurrence_count',
              message: 'recurrenceRule.count is required.',
              location: '$location/recurrenceRule/count',
            ),
          );
        } else if (!_isInputToken(count)) {
          final parsedCount = parseInt(count);
          if (parsedCount == null || parsedCount < 1 || parsedCount > 366) {
            findings.add(
              ValidationFinding(
                type: 'invalid_recurrence_count',
                message:
                    'recurrenceRule.count must be an integer from 1 to 366.',
                location: '$location/recurrenceRule/count',
              ),
            );
          }
        }

        final interval = recurrenceRule['interval'];
        if (interval != null && !_isInputToken(interval)) {
          final parsedInterval = parseInt(interval);
          if (parsedInterval == null || parsedInterval < 1) {
            findings.add(
              ValidationFinding(
                type: 'invalid_recurrence_interval',
                message: 'recurrenceRule.interval must be an integer >= 1.',
                location: '$location/recurrenceRule/interval',
              ),
            );
          }
        }

        final byDayOfWeek = recurrenceRule['byDayOfWeek'];
        final hasStaticByDayOfWeek =
            byDayOfWeek != null && !_isInputToken(byDayOfWeek);
        if (hasStaticByDayOfWeek &&
            (byDayOfWeek is! List ||
                byDayOfWeek.isEmpty ||
                byDayOfWeek.any(
                  (value) =>
                      value is! String ||
                      !const {
                        'MO',
                        'TU',
                        'WE',
                        'TH',
                        'FR',
                        'SA',
                        'SU',
                      }.contains(value),
                ) ||
                byDayOfWeek.toSet().length != byDayOfWeek.length)) {
          findings.add(
            ValidationFinding(
              type: 'invalid_recurrence_weekday_code',
              message:
                  'recurrenceRule.byDayOfWeek must be a non-empty list of unique weekday codes.',
              location: '$location/recurrenceRule/byDayOfWeek',
            ),
          );
        }

        final byMonthDay = recurrenceRule['byMonthDay'];
        final hasStaticByMonthDay =
            byMonthDay != null && !_isInputToken(byMonthDay);
        if (hasStaticByMonthDay) {
          final parsedMonthDay = parseInt(byMonthDay);
          if (parsedMonthDay == null ||
              parsedMonthDay < 1 ||
              parsedMonthDay > 31) {
            findings.add(
              ValidationFinding(
                type: 'invalid_recurrence_month_day',
                message:
                    'recurrenceRule.byMonthDay must be an integer from 1 to 31.',
                location: '$location/recurrenceRule/byMonthDay',
              ),
            );
          }
        }

        final bySetPos = recurrenceRule['bySetPos'];
        final hasStaticBySetPos = bySetPos != null && !_isInputToken(bySetPos);
        if (hasStaticBySetPos &&
            (bySetPos is! String ||
                !const {
                  'first',
                  'second',
                  'third',
                  'fourth',
                  'last',
                }.contains(bySetPos))) {
          findings.add(
            ValidationFinding(
              type: 'invalid_recurrence_set_pos_value',
              message:
                  'recurrenceRule.bySetPos must be first, second, third, fourth, or last.',
              location: '$location/recurrenceRule/bySetPos',
            ),
          );
        }

        if (validFreq) {
          if (freq == 'daily') {
            for (final field in <String, dynamic>{
              'byDayOfWeek': byDayOfWeek,
              'byMonthDay': byMonthDay,
              'bySetPos': bySetPos,
            }.entries) {
              if (field.value != null && !_isInputToken(field.value)) {
                findings.add(
                  ValidationFinding(
                    type: 'recurrence_field_invalid_for_freq',
                    message:
                        'recurrenceRule.${field.key} is invalid for daily recurrence.',
                    location: '$location/recurrenceRule/${field.key}',
                  ),
                );
              }
            }
          } else if (freq == 'weekly') {
            for (final field in <String, dynamic>{
              'byMonthDay': byMonthDay,
              'bySetPos': bySetPos,
            }.entries) {
              if (field.value != null && !_isInputToken(field.value)) {
                findings.add(
                  ValidationFinding(
                    type: 'recurrence_field_invalid_for_freq',
                    message:
                        'recurrenceRule.${field.key} is invalid for weekly recurrence.',
                    location: '$location/recurrenceRule/${field.key}',
                  ),
                );
              }
            }
          } else if (freq == 'monthly') {
            if (hasStaticByMonthDay && hasStaticBySetPos) {
              findings.add(
                ValidationFinding(
                  type: 'recurrence_month_day_set_pos_conflict',
                  message:
                      'monthly recurrence cannot use both byMonthDay and bySetPos.',
                  location: '$location/recurrenceRule',
                ),
              );
            }
            if (hasStaticBySetPos) {
              if (byDayOfWeek == null) {
                findings.add(
                  ValidationFinding(
                    type: 'dangling_recurrence_set_pos_without_weekday',
                    message:
                        'monthly recurrence bySetPos requires byDayOfWeek.',
                    location: '$location/recurrenceRule/byDayOfWeek',
                  ),
                );
              } else if (hasStaticByDayOfWeek &&
                  (byDayOfWeek is! List || byDayOfWeek.length != 1)) {
                findings.add(
                  ValidationFinding(
                    type: 'invalid_recurrence_set_pos_weekday_count',
                    message:
                        'monthly recurrence bySetPos requires exactly one byDayOfWeek entry.',
                    location: '$location/recurrenceRule/byDayOfWeek',
                  ),
                );
              }
            }
            if (hasStaticByDayOfWeek && bySetPos == null) {
              findings.add(
                ValidationFinding(
                  type: 'recurrence_weekday_without_set_pos',
                  message: 'monthly recurrence byDayOfWeek requires bySetPos.',
                  location: '$location/recurrenceRule/byDayOfWeek',
                ),
              );
            }
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
      } else if (machine.instanceDataSchema[effect.key]?.formula != null ||
          machine.instanceDataSchema[effect.key]?.source != null) {
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
  // AP-13: a workflow type with real (formEntry) content fields that no
  // create action (renderBindings[].actions[].kind: "create") and no
  // creation effect (createInstance / generateRecurringInstances) anywhere
  // in the loaded package ever targets. Every instance of that type that
  // will ever exist is whatever was seeded in workflowInstances -- the
  // "implemented edit, but no create" pattern, package-wide.
  // ---------------------------------------------------------------------------
  void _checkNoCreationPathForEditableTypes(
    Map<String, LoomWorkflowStateMachine> workflows,
    List<ValidationFinding> findings,
  ) {
    final everCreatedTypes = <String>{};

    void collectEffects(List<WorkflowEffect> effects) {
      for (final effect in effects) {
        if ((effect.op == 'createInstance' ||
                effect.op == 'generateRecurringInstances') &&
            effect.workflowType != null) {
          everCreatedTypes.add(effect.workflowType!);
        }
        collectEffects(effect.thenEffects);
        collectEffects(effect.elseEffects);
        final onSuccess = effect.onSuccessEffects;
        if (onSuccess != null) collectEffects(onSuccess);
      }
    }

    for (final machine in workflows.values) {
      for (final binding in machine.renderBindings) {
        for (final action in binding.actions.where((a) => a.kind == 'create')) {
          everCreatedTypes.add(action.workflowType ?? machine.workflowType);
        }
        // A response table's creation path is archetype-owned, not community-
        // declared: the engine materializes a row in `pending` the first time a
        // member applies a response transition to an event they have no row for
        // (archetypes/event-rsvp.md §4). There is deliberately nothing in the
        // JSON to find, so without this all six response tables in the corpus
        // report a provisioning gap they cannot fix.
        final responseTable = binding.responseTable;
        if (responseTable != null) {
          everCreatedTypes.add(responseTable.workflowType);
        }
      }
      for (final transition in machine.transitions) {
        collectEffects(transition.effects);
      }
    }

    for (final entry in workflows.entries) {
      final type = entry.key;
      final machine = entry.value;
      if (everCreatedTypes.contains(type)) continue;
      final hasWritableField = machine.instanceDataSchema.values.any(
        (field) =>
            field.writableBy == 'formEntry' || field.writableBy == 'effect',
      );
      if (!hasWritableField) continue;
      findings.add(
        ValidationFinding(
          type: 'no_creation_path_for_editable_type',
          message:
              'Workflow "$type" declares writable (formEntry- or effect-'
              'authored) fields, '
              'but no create action targets it anywhere in this package '
              '(renderBindings[].actions[].kind: "create"), and no effect '
              '(createInstance / generateRecurringInstances) ever creates '
              'one either. Every instance of "$type" that will ever exist '
              'is whatever was seeded in workflowInstances -- see '
              'guide/04-antipatterns.md AP-13. If instances of this type '
              'are deliberately provisioned only outside this package, this '
              'warning can be ignored.',
          location: '$type/renderBindings',
          isWarning: true,
        ),
      );
    }
  }

  void _checkDestructiveTransitionIgnoresAvailabilityField(
    LoomWorkflowStateMachine machine,
    List<ValidationFinding> findings,
  ) {
    final availabilityFields = machine.instanceDataSchema.keys
        .where(_availabilityLikeFieldPattern.hasMatch)
        .toList();
    if (availabilityFields.isEmpty) return;

    String? matchingSiblingTransition(
      LoomWorkflowTransition target,
      String field,
    ) {
      for (final transition in machine.transitions) {
        if (transition.id == target.id) continue;
        if (_isTransitionGuardCheckingAvailabilityField(
          transition.guard,
          field,
        )) {
          return transition.id;
        }
      }
      return null;
    }

    for (final field in availabilityFields) {
      final destructiveTransitions = machine.transitions.where((transition) {
        final targetState = machine.states[transition.to];
        return targetState?.isTerminal == true ||
            _destructiveTransitionIdPattern.hasMatch(transition.id);
      }).toList();

      if (destructiveTransitions.isEmpty) continue;

      for (final destructiveTransition in destructiveTransitions) {
        if (_isTransitionGuardCheckingAvailabilityField(
          destructiveTransition.guard,
          field,
        )) {
          continue;
        }
        final siblingId = matchingSiblingTransition(
          destructiveTransition,
          field,
        );
        if (siblingId == null) continue;

        findings.add(
          ValidationFinding(
            type: 'destructive_transition_ignores_availability_field',
            message:
                'Transition "${destructiveTransition.id}" is destructive on '
                'workflow "${machine.workflowType}" but does not guard on '
                'availability field "$field", while sibling transition '
                '"$siblingId" on the same workflow does. This can allow '
                'terminal paths to bypass availability gating.',
            location:
                '${machine.workflowType}/transitions/${destructiveTransition.id}',
            isWarning: true,
          ),
        );
      }
    }
  }

  bool _isTransitionGuardCheckingAvailabilityField(
    WorkflowGuard guard,
    String field,
  ) {
    if (guard.instanceDataEquals != null &&
        guard.instanceDataEquals!.key == field) {
      return true;
    }
    final formula = guard.formula;
    if (formula == null) return false;
    final fieldInFormula = RegExp(
      '\\b${RegExp.escape(field)}\\b',
      caseSensitive: false,
    );
    return fieldInFormula.hasMatch(formula);
  }

  void _checkPossibleFabricatedIdentifier(
    LoomWorkflowStateMachine machine,
    List<ValidationFinding> findings,
  ) {
    for (final transition in machine.transitions) {
      void collectEffects(List<WorkflowEffect> effects, String path) {
        for (var i = 0; i < effects.length; i++) {
          final effect = effects[i];
          final location =
              '${machine.workflowType}/transitions/${transition.id}/$path[$i]';

          if (effect.op == 'set' && effect.key != null) {
            final key = effect.key!;
            if (_fabricatedIdentifierKeys.contains(key.toLowerCase()) &&
                effect.value is String) {
              final value = effect.value as String;
              final trimmedValue = value.trim();
              final isTemplate =
                  (trimmedValue.startsWith('{') &&
                      trimmedValue.endsWith('}')) ||
                  trimmedValue.contains('{');
              if (!isTemplate &&
                  trimmedValue != '\$actor' &&
                  trimmedValue != '\$timestamp') {
                findings.add(
                  ValidationFinding(
                    type: 'possible_fabricated_identifier',
                    message:
                        'Transition "${transition.id}" sets identifier-like field '
                        '"$key" to a hardcoded string value "$trimmedValue", '
                        'which may indicate a fabricated value instead of a '
                        'platform-provided identifier. This pattern aligns with '
                        'docs/references/reference/platform-services.md "Not implemented" '
                        'and solved-patterns.md pattern 4.',
                    location: location,
                    isWarning: true,
                  ),
                );
              }
            }
          }

          collectEffects(effect.thenEffects, '$path[$i]/then');
          collectEffects(effect.elseEffects, '$path[$i]/else');
          final onSuccess = effect.onSuccessEffects;
          if (onSuccess != null) {
            collectEffects(onSuccess, '$path[$i]/onSuccessEffects');
          }
        }
      }

      collectEffects(transition.effects, 'effects');
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
  // editableFields declared with no editGuard. editGuard's absent-default is
  // the OPPOSITE of every other guard in this grammar (guards.md/
  // workflow-grammar.md): with no editGuard, the App Shell never renders any
  // field editor for that state, for any persona -- the editableFields
  // declaration is silently inert, not "anyone may edit." This is the
  // "implemented edit, but nothing can actually save it" pattern.
  // ---------------------------------------------------------------------------
  void _checkEditableFieldsWithoutEditGuard(
    LoomWorkflowStateMachine machine,
    List<ValidationFinding> findings,
  ) {
    for (final entry in machine.states.entries) {
      final stateName = entry.key;
      final state = entry.value;
      if (state.editableFields == null || state.editableFields!.isEmpty) {
        continue;
      }
      if (state.editGuard != null) continue;
      findings.add(
        ValidationFinding(
          type: 'editable_fields_without_edit_guard',
          message:
              'State "$stateName" declares editableFields '
              '(${state.editableFields!.join(', ')}) but no editGuard. An '
              'absent editGuard means editing is not exposed at all for this '
              'state, for any persona -- the editableFields declaration has '
              'no effect. Add an editGuard (e.g. '
              '{"allowedRoleIds": [...]}) naming who may edit, or remove '
              'editableFields if this state was never meant to be editable.',
          location: '${machine.workflowType}/states/$stateName/editGuard',
          isWarning: true,
        ),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Workflow-level read visibility omitted. Public remains the compatibility
  // default, but every workflow should declare its intended read policy.
  // ---------------------------------------------------------------------------
  void _checkNoReadVisibilityDeclared(
    LoomWorkflowStateMachine machine,
    List<ValidationFinding> findings,
  ) {
    if (machine.visibility.isDeclared) return;

    findings.add(
      ValidationFinding(
        type: 'no_read_visibility_declared',
        message:
            'Workflow "${machine.workflowType}" does not declare a '
            'visibility policy. Reads continue to default to public, but '
            'declare "visibility" explicitly so the community\'s intended '
            'read policy is visible in its JSON.',
        location: '${machine.workflowType}/visibility',
        isWarning: true,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // A primary-bound, actively-managed type (declares an editGuard somewhere,
  // i.e. someone is clearly expected to keep editing its instances over time)
  // with no destructive-toned transition anywhere -- the "implemented create,
  // but no cancel/withdraw/delete" pattern. Heuristic, warning-only: plenty
  // of types legitimately never need one.
  // ---------------------------------------------------------------------------
  void _checkNoDestructiveExitForManagedType(
    LoomWorkflowStateMachine machine,
    List<ValidationFinding> findings,
  ) {
    final hasPrimaryBinding = machine.renderBindings.any(
      (binding) => binding.bindingKind == 'primary',
    );
    if (!hasPrimaryBinding) return;

    final isActivelyManaged = machine.states.values.any(
      (state) => state.editGuard != null,
    );
    if (!isActivelyManaged) return;

    final hasDestructiveTransition = machine.transitions.any(
      (t) => t.tone == 'destructive',
    );
    if (hasDestructiveTransition) return;

    findings.add(
      ValidationFinding(
        type: 'no_destructive_exit_for_managed_type',
        message:
            'Workflow "${machine.workflowType}" is primary-bound and '
            'declares an editGuard (its instances are clearly meant to be '
            'actively managed), but no transition anywhere has '
            '"tone": "destructive". If this community expects a way to '
            'cancel, withdraw, delete, or otherwise terminate an instance '
            'once created, no such transition exists. If every instance of '
            'this type is genuinely meant to be permanent once created, '
            'this warning can be ignored.',
        location: '${machine.workflowType}/transitions',
        isWarning: true,
      ),
    );
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
        checkString(
          effectValue.toString(),
          effect.key != null ? 'key=${effect.key}' : 'value',
        );
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

  String _actionLocation(
    LoomWorkflowStateMachine machine,
    RenderBinding binding,
    String field,
  ) =>
      '${machine.workflowType}/renderBindings/${binding.states.join(",")}/actions/$field';

  // ---------------------------------------------------------------------------
  // actions[] grammar-v2 checks
  // ---------------------------------------------------------------------------
  void _checkUnknownActionKinds(
    LoomWorkflowStateMachine machine,
    List<ValidationFinding> findings,
  ) {
    for (final binding in machine.renderBindings) {
      for (final action in binding.actions) {
        if (action.kind == 'create' || action.kind == 'transition') continue;
        findings.add(
          ValidationFinding(
            type: 'unknown_action_kind',
            message:
                'actions[].kind "${action.kind}" is not "create" or "transition".',
            location: _actionLocation(machine, binding, 'kind'),
          ),
        );
      }
    }
  }

  void _checkUnknownActionScopes(
    LoomWorkflowStateMachine machine,
    List<ValidationFinding> findings,
  ) {
    for (final binding in machine.renderBindings) {
      for (final action in binding.actions) {
        if (action.scope == null ||
            action.scope == 'tab' ||
            action.scope == 'instance')
          continue;
        findings.add(
          ValidationFinding(
            type: 'unknown_action_scope',
            message:
                'actions[].scope "${action.scope}" is not "tab" or "instance".',
            location: _actionLocation(machine, binding, 'scope'),
          ),
        );
      }
    }
  }

  void _checkUnknownActionPresentations(
    LoomWorkflowStateMachine machine,
    List<ValidationFinding> findings,
  ) {
    for (final binding in machine.renderBindings) {
      for (final action in binding.actions) {
        if (action.presentation == null ||
            action.presentation == 'fab' ||
            action.presentation == 'button')
          continue;
        findings.add(
          ValidationFinding(
            type: 'unknown_action_presentation',
            message:
                'actions[].presentation "${action.presentation}" is not "fab" or "button".',
            location: _actionLocation(machine, binding, 'presentation'),
          ),
        );
      }
    }
  }

  void _checkTabActionsCannotBeButtons(
    LoomWorkflowStateMachine machine,
    List<ValidationFinding> findings,
  ) {
    for (final binding in machine.renderBindings) {
      for (final action in binding.actions) {
        final scope =
            action.scope ?? (action.kind == 'transition' ? 'instance' : 'tab');
        if (scope != 'tab' || action.presentation != 'button') continue;
        findings.add(
          ValidationFinding(
            type: 'tab_action_cannot_be_button',
            message: 'A tab-scoped action cannot use presentation "button".',
            location: _actionLocation(machine, binding, 'presentation'),
          ),
        );
      }
    }
  }

  void _checkDanglingActionWorkflowTypes(
    LoomWorkflowStateMachine machine,
    Map<String, LoomWorkflowStateMachine> allWorkflows,
    List<ValidationFinding> findings,
  ) {
    for (final binding in machine.renderBindings) {
      for (final action in binding.actions.where((a) => a.kind == 'create')) {
        final workflowType = action.workflowType;
        if (workflowType == null || allWorkflows.containsKey(workflowType))
          continue;
        findings.add(
          ValidationFinding(
            type: 'dangling_action_workflow_type',
            message:
                'Create action workflowType "$workflowType" is not declared.',
            location: _actionLocation(machine, binding, 'workflowType'),
          ),
        );
      }
    }
  }

  void _checkCreateActionsCannotSetInputs(
    LoomWorkflowStateMachine machine,
    List<ValidationFinding> findings,
  ) {
    for (final binding in machine.renderBindings) {
      for (final action in binding.actions.where((a) => a.kind == 'create')) {
        if (action.inputs == null) continue;
        findings.add(
          ValidationFinding(
            type: 'create_action_cannot_set_inputs',
            message: 'Create actions cannot set inputs; use prefill instead.',
            location: _actionLocation(machine, binding, 'inputs'),
          ),
        );
      }
    }
  }

  void _checkDanglingActionTransitionIds(
    LoomWorkflowStateMachine machine,
    List<ValidationFinding> findings,
  ) {
    final transitionIds = machine.transitions
        .map((transition) => transition.id)
        .toSet();
    for (final binding in machine.renderBindings) {
      for (final action in binding.actions.where(
        (a) => a.kind == 'transition',
      )) {
        if (action.transitionId != null &&
            transitionIds.contains(action.transitionId))
          continue;
        findings.add(
          ValidationFinding(
            type: 'dangling_action_transition_id',
            message:
                'Transition action transitionId "${action.transitionId}" is not declared on "${machine.workflowType}".',
            location: _actionLocation(machine, binding, 'transitionId'),
          ),
        );
      }
    }
  }

  void _checkTransitionActionsCannotBeTabScoped(
    LoomWorkflowStateMachine machine,
    List<ValidationFinding> findings,
  ) {
    for (final binding in machine.renderBindings) {
      for (final action in binding.actions.where(
        (a) => a.kind == 'transition',
      )) {
        if (action.scope != 'tab') continue;
        findings.add(
          ValidationFinding(
            type: 'transition_action_cannot_be_tab_scoped',
            message: 'Transition actions must be instance-scoped.',
            location: _actionLocation(machine, binding, 'scope'),
          ),
        );
      }
    }
  }

  void _checkTransitionActionsCannotSetWorkflowType(
    LoomWorkflowStateMachine machine,
    List<ValidationFinding> findings,
  ) {
    for (final binding in machine.renderBindings) {
      for (final action in binding.actions.where(
        (a) => a.kind == 'transition',
      )) {
        if (action.workflowType == null) continue;
        findings.add(
          ValidationFinding(
            type: 'transition_action_cannot_set_workflow_type',
            message: 'Transition actions cannot set workflowType.',
            location: _actionLocation(machine, binding, 'workflowType'),
          ),
        );
      }
    }
  }

  void _checkTransitionActionsCannotSetPrefill(
    LoomWorkflowStateMachine machine,
    List<ValidationFinding> findings,
  ) {
    for (final binding in machine.renderBindings) {
      for (final action in binding.actions.where(
        (a) => a.kind == 'transition',
      )) {
        if (action.prefill == null) continue;
        findings.add(
          ValidationFinding(
            type: 'transition_action_cannot_set_prefill',
            message:
                'Transition actions cannot set prefill; use inputs instead.',
            location: _actionLocation(machine, binding, 'prefill'),
          ),
        );
      }
    }
  }

  void _checkTransitionActionsCannotSetByPersonaIds(
    LoomWorkflowStateMachine machine,
    List<ValidationFinding> findings,
  ) {
    for (final binding in machine.renderBindings) {
      for (final action in binding.actions.where(
        (a) => a.kind == 'transition',
      )) {
        if (action.byPersonaIds == null) continue;
        findings.add(
          ValidationFinding(
            type: 'transition_action_cannot_set_by_persona_ids',
            message:
                'Transition actions cannot set byRoleIds; use the transition guard.',
            location: _actionLocation(machine, binding, 'byRoleIds'),
          ),
        );
      }
    }
  }

  void _checkUnknownActionInputReferences(
    LoomWorkflowStateMachine machine,
    List<ValidationFinding> findings,
  ) {
    final transitions = {
      for (final transition in machine.transitions) transition.id: transition,
    };
    for (final binding in machine.renderBindings) {
      for (final action in binding.actions.where(
        (a) => a.kind == 'transition',
      )) {
        final inputs = action.inputs;
        final transition = transitions[action.transitionId];
        if (inputs == null || transition == null) continue;
        final declaredInputs =
            transition.inputs?.keys.toSet() ?? const <String>{};
        for (final key in inputs.keys) {
          if (declaredInputs.contains(key)) continue;
          findings.add(
            ValidationFinding(
              type: 'unknown_action_input_reference',
              message:
                  'Transition action input "$key" is not declared by transition "${transition.id}".',
              location: _actionLocation(machine, binding, 'inputs/$key'),
            ),
          );
        }
      }
    }
  }

  void _checkDuplicateActionTransitionIds(
    LoomWorkflowStateMachine machine,
    List<ValidationFinding> findings,
  ) {
    for (final binding in machine.renderBindings) {
      final seen = <String>{};
      for (final action in binding.actions.where(
        (a) => a.kind == 'transition',
      )) {
        final transitionId = action.transitionId;
        if (transitionId == null || seen.add(transitionId)) continue;
        findings.add(
          ValidationFinding(
            type: 'duplicate_action_transition_id',
            message:
                'More than one transition action names "$transitionId" on this binding.',
            location: _actionLocation(machine, binding, 'transitionId'),
          ),
        );
      }
    }
  }

  // ---------------------------------------------------------------------------
  // create-action byRoleIds dangling-role check
  // ---------------------------------------------------------------------------
  void _checkCreatablePersonaIds(
    LoomWorkflowStateMachine machine,
    List<ValidationFinding> findings,
  ) {
    if (knownPersonaIds == null || knownPersonaIds!.isEmpty) return;

    for (final binding in machine.renderBindings) {
      for (final action in binding.actions.where((a) => a.kind == 'create')) {
        for (final personaId in action.byPersonaIds ?? const <String>[]) {
          if (!knownPersonaIds!.contains(personaId)) {
            findings.add(
              ValidationFinding(
                type: 'dangling_allowed_persona_id',
                message:
                    'creatable.byRoleIds references "$personaId", which does '
                    'not appear in the known role registry. This may indicate '
                    'a typo or a role ID that was not declared anywhere.',
                location:
                    '${machine.workflowType}/renderBindings/${binding.states.join(",")}/'
                    'actions/byRoleIds',
                isWarning: true,
              ),
            );
          }
        }
      }
    }
  }

  // ---------------------------------------------------------------------------
  // create-action prefill field check
  // ---------------------------------------------------------------------------
  void _checkCreatablePrefill(
    LoomWorkflowStateMachine machine,
    Map<String, LoomWorkflowStateMachine> allWorkflows,
    List<ValidationFinding> findings,
  ) {
    for (final binding in machine.renderBindings) {
      for (final action in binding.actions.where((a) => a.kind == 'create')) {
        final prefill = action.prefill;
        if (prefill == null) continue;
        final targetMachine =
            allWorkflows[action.workflowType ?? machine.workflowType];
        if (targetMachine == null) continue;
        final location =
            '${machine.workflowType}/renderBindings/${binding.states.join(",")}/'
            'actions/prefill';
        for (final key in prefill.keys) {
          final field = targetMachine.instanceDataSchema[key];
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
  }

  // ---------------------------------------------------------------------------
  // context_reference_outside_instance_action
  // ---------------------------------------------------------------------------
  void _checkContextReferenceOutsideInstanceAction(
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
              type: 'context_reference_outside_instance_action',
              message:
                  '{context.x} interpolation is only valid inside '
                  'instance-scoped action prefill or inputs values, not in '
                  'transition effects.',
              location: '$location/$subPath',
            ),
          );
        }
      }

      final effectValue = effect.value;
      if (effectValue != null) {
        checkString(
          effectValue.toString(),
          effect.key != null ? 'key=${effect.key}' : 'value',
        );
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
