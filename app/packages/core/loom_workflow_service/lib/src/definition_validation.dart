import 'package:loom_workflow_engine/loom_workflow_engine.dart';

const supportedWorkflowSpecVersions = <int>{currentCommunitySpecVersion};

/// How a finding should be treated.
///
/// Added because not every true thing about a definition should stop it being
/// installed. A package that is coherent but worth a second look needs a way to
/// say so; without one, the only options were to fail a correct package or to
/// stay silent, and staying silent is what let five document libraries ship as
/// link lists without anyone noticing.
enum WorkflowFindingSeverity {
  /// The definition cannot be installed.
  error,

  /// The definition installs. Something about it is worth reading.
  warning,
}

class WorkflowDefinitionFinding {
  final String code;
  final String message;
  final String? workflowType;
  final String? transitionId;
  final WorkflowFindingSeverity severity;

  const WorkflowDefinitionFinding({
    required this.code,
    required this.message,
    this.workflowType,
    this.transitionId,
    this.severity = WorkflowFindingSeverity.error,
  });

  bool get isError => severity == WorkflowFindingSeverity.error;

  Map<String, dynamic> toJson() => {
    'code': code,
    'message': message,
    'severity': severity.name,
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
  _validateDocumentContent(definitions, findings);
  return findings;
}

/// Where a `documentLibrary` workflow's document content comes from.
///
/// Every shipped document library turned out to be a list of links: a member
/// types a URL into a `url` field and the library shows its title, source and
/// version. That is a coherent product and it is what all five product docs
/// describe -- "open embedded, launch external, download". It is also invisible
/// from the outside, which is why nobody noticed that the platform's document
/// storage had no packages using it.
///
/// These checks make the choice explicit rather than latent.
void _validateDocumentContent(
  Map<String, Map<String, dynamic>> definitions,
  List<WorkflowDefinitionFinding> findings,
) {
  const resolver = ArchetypeResolver();
  final archetypes = resolver.resolveAll(definitions);

  for (final entry in definitions.entries) {
    if (archetypes[entry.key]?.family != 'documentLibrary') continue;

    final schema = entry.value['instanceDataSchema'];
    final linkFields = <String>{};
    if (schema is Map<String, dynamic>) {
      for (final field in schema.entries) {
        final declared = field.value;
        if (declared is Map && declared['type'] == 'url') {
          linkFields.add(field.key);
        }
      }
    }

    final transitions = entry.value['transitions'];
    if (transitions is! List) continue;

    var declaresUpload = false;
    for (final transition in transitions) {
      if (transition is! Map) continue;
      if (transition['action'] != 'upload') continue;
      declaresUpload = true;

      final transitionId = transition['id'] is String
          ? transition['id'] as String
          : null;

      // An upload whose document location is typed in by the member is a link
      // publish wearing the upload action's name. That matters beyond
      // vocabulary now: the document library API derives permission to store
      // files from the presence of an `upload` transition, so mislabelling one
      // hands out file-upload authority as a side effect of pasting a URL.
      final memberSuppliedFields = _fieldsSetFromInput(
        transition['effects'],
        linkFields,
      );
      if (memberSuppliedFields.isEmpty) continue;

      findings.add(
        WorkflowDefinitionFinding(
          code: 'document_upload_stores_no_content',
          message:
              'Transition "${transitionId ?? '<unknown>'}" declares the '
              '"upload" action but sets '
              '${memberSuppliedFields.map((f) => '"$f"').join(', ')} from a '
              'member-supplied input, so it publishes a link rather than '
              'storing a document. Declaring "upload" also grants permission '
              'to store files through the document library API. Use a '
              'community-defined transition or "edit" for a link publish.',
          workflowType: entry.key,
          transitionId: transitionId,
        ),
      );
    }

    if (!declaresUpload && linkFields.isNotEmpty) {
      findings.add(
        WorkflowDefinitionFinding(
          code: 'document_library_is_link_only',
          severity: WorkflowFindingSeverity.warning,
          message:
              'This document library holds links, not stored documents: its '
              'content lives in ${linkFields.map((f) => '"$f"').join(', ')} '
              'and no transition declares the "upload" action, so no document '
              'can be stored through the document library API. Intended for a '
              'library of external resources; declare an "upload" transition '
              'if members should be able to add files.',
          workflowType: entry.key,
        ),
      );
    }
  }
}

/// Which of [candidateFields] an effect list assigns from a member input.
///
/// Matches on the effect's own shape rather than on field names. A field called
/// `documentUrl` is not evidence of anything -- the project has been bitten
/// before by inferring meaning from identifier spelling.
Set<String> _fieldsSetFromInput(
  Object? effects,
  Set<String> candidateFields,
) {
  final matched = <String>{};
  if (effects is! List || candidateFields.isEmpty) return matched;
  for (final effect in effects) {
    if (effect is! Map) continue;
    if (effect['op'] != 'set') continue;
    final key = effect['key'];
    if (key is! String || !candidateFields.contains(key)) continue;
    final value = effect['value'];
    if (value is String && value.contains('{input.')) {
      matched.add(key);
    }
  }
  return matched;
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
