import 'package:loom_workflow_engine/loom_workflow_engine.dart';

const supportedWorkflowSpecVersions = <int>{currentCommunitySpecVersion};

class WorkflowDefinitionFinding {
  final String code;
  final String message;
  final String? workflowType;
  final String? transitionId;

  const WorkflowDefinitionFinding({
    required this.code,
    required this.message,
    this.workflowType,
    this.transitionId,
  });

  Map<String, dynamic> toJson() => {
    'code': code,
    'message': message,
    if (workflowType != null) 'workflowType': workflowType,
    if (transitionId != null) 'transitionId': transitionId,
  };
}

/// Checks constructs which the shared engine must understand before a
/// definition package can be installed.
///
/// Shape/type errors are rejected while decoding the HTTP request. These are
/// executable-semantics findings, and therefore map to the OpenAPI 422 body.
List<WorkflowDefinitionFinding> validateExecutableDefinitions(
  Map<String, Map<String, dynamic>> definitions,
) {
  final findings = <WorkflowDefinitionFinding>[];
  _validateSurfaceFamilies(definitions, findings);
  _validateActions(definitions, findings);
  _validateFormulas(definitions, findings);
  _validateEffectOps(definitions, findings);
  return findings;
}

void _validateSurfaceFamilies(
  Map<String, Map<String, dynamic>> definitions,
  List<WorkflowDefinitionFinding> findings,
) {
  for (final entry in definitions.entries) {
    final bindings = entry.value['renderBindings'];
    if (bindings is! List) continue;
    for (final binding in bindings) {
      if (binding is! Map) continue;
      final family = binding['cardSurfaceFamily'];
      if (family is String && knownWorkflowArchetypeIds.contains(family)) {
        continue;
      }
      findings.add(
        WorkflowDefinitionFinding(
          code: 'unknown_card_surface_family',
          message:
              'cardSurfaceFamily "${family ?? '<missing>'}" is not supported.',
          workflowType: entry.key,
        ),
      );
    }
  }
}

void _validateActions(
  Map<String, Map<String, dynamic>> definitions,
  List<WorkflowDefinitionFinding> findings,
) {
  const resolver = ArchetypeResolver();
  final archetypes = resolver.resolveAll(definitions);
  for (final entry in definitions.entries) {
    final archetype = archetypes[entry.key];
    if (archetype == null) continue;
    if (archetype.conflictingBespokeFamilies.length > 1) {
      findings.add(
        WorkflowDefinitionFinding(
          code: 'unknown_action_for_archetype',
          message:
              'The workflow names conflicting bespoke archetypes: '
              '${archetype.conflictingBespokeFamilies.join(', ')}.',
          workflowType: entry.key,
        ),
      );
      continue;
    }

    final transitions = entry.value['transitions'];
    if (transitions is! List) continue;
    for (final transition in transitions) {
      if (transition is! Map) continue;
      final transitionId = transition['id'] is String
          ? transition['id'] as String
          : null;
      final action = transition['action'];
      final family = archetype.family;
      final isValid = archetype.requiresAction
          ? action is String &&
                family != null &&
                resolver.isActionInVocabulary(family, action)
          : action == null;
      if (isValid) continue;

      findings.add(
        WorkflowDefinitionFinding(
          code: 'unknown_action_for_archetype',
          message: archetype.requiresAction
              ? 'Transition "${transitionId ?? '<unknown>'}" must declare an '
                    'action from the closed vocabulary for "$family".'
              : 'Transition "${transitionId ?? '<unknown>'}" declares an '
                    'action for a workflow whose permissions are structural.',
          workflowType: entry.key,
          transitionId: transitionId,
        ),
      );
    }
  }
}

void _validateFormulas(
  Map<String, Map<String, dynamic>> definitions,
  List<WorkflowDefinitionFinding> findings,
) {
  for (final entry in definitions.entries) {
    final computedDependencies = <String, Set<String>>{};
    final schema = entry.value['instanceDataSchema'];
    if (schema is Map) {
      final computedFields = <String>{
        for (final field in schema.entries)
          if (field.key is String &&
              field.value is Map &&
              (field.value as Map)['formula'] is String)
            field.key as String,
      };
      for (final field in computedFields) {
        final formula = (schema[field] as Map)['formula'] as String;
        try {
          computedDependencies[field] = analyzeFormula(
            formula,
          ).referencedFields.intersection(computedFields);
        } on FormulaEvaluationException {
          // The recursive syntax pass below emits the actionable finding.
        }
      }
    }

    final active = <String>{};
    final complete = <String>{};
    var reportedCycle = false;
    void visitComputedField(String field) {
      if (reportedCycle || complete.contains(field)) return;
      if (!active.add(field)) {
        findings.add(
          WorkflowDefinitionFinding(
            code: 'unparseable_formula',
            message: 'Circular computed-field dependency at "$field".',
            workflowType: entry.key,
          ),
        );
        reportedCycle = true;
        return;
      }
      for (final dependency
          in computedDependencies[field] ?? const <String>{}) {
        visitComputedField(dependency);
      }
      active.remove(field);
      complete.add(field);
    }

    for (final field in computedDependencies.keys) {
      visitComputedField(field);
    }

    void visit(Object? value, String? transitionId) {
      if (value is List) {
        for (final child in value) {
          visit(child, transitionId);
        }
        return;
      }
      if (value is! Map) return;

      final nestedTransitionId =
          value['id'] is String && value.containsKey('from')
          ? value['id'] as String
          : transitionId;
      for (final formulaKey in const [
        'formula',
        'if',
        'visibleWhen',
        'visibleWhenEditing',
      ]) {
        final formula = value[formulaKey];
        if (formula is! String) continue;
        try {
          final analysis = analyzeFormula(formula);
          final unknownFunctions = analysis.functionNames.difference(
            formulaFunctionNames,
          );
          if (unknownFunctions.isNotEmpty) {
            throw FormulaEvaluationException(
              'Unknown formula function(s): ${unknownFunctions.join(', ')}',
            );
          }
        } on FormulaEvaluationException catch (error) {
          findings.add(
            WorkflowDefinitionFinding(
              code: 'unparseable_formula',
              message: error.message,
              workflowType: entry.key,
              transitionId: nestedTransitionId,
            ),
          );
        }
      }
      for (final child in value.values) {
        visit(child, nestedTransitionId);
      }
    }

    visit(entry.value, null);
  }
}

void _validateEffectOps(
  Map<String, Map<String, dynamic>> definitions,
  List<WorkflowDefinitionFinding> findings,
) {
  for (final entry in definitions.entries) {
    final transitions = entry.value['transitions'];
    if (transitions is! List) continue;
    for (final transition in transitions) {
      if (transition is! Map) continue;
      final transitionId = transition['id'] is String
          ? transition['id'] as String
          : null;

      void visitEffects(Object? effects) {
        if (effects is! List) return;
        for (final effect in effects) {
          if (effect is! Map) continue;
          final op = effect['op'];
          if (op is! String ||
              !supportedWorkflowEffectOperations.contains(op)) {
            findings.add(
              WorkflowDefinitionFinding(
                code: 'unknown_effect_op',
                message: 'Effect op "${op ?? '<missing>'}" is not supported.',
                workflowType: entry.key,
                transitionId: transitionId,
              ),
            );
          }
          visitEffects(effect['then']);
          visitEffects(effect['else']);
          visitEffects(effect['onSuccessEffects']);
        }
      }

      visitEffects(transition['effects']);
    }
  }
}
