import 'package:loom_ux_judges/src/permissions/archetype_resolver.dart';
import 'package:loom_ux_judges/src/validator/workflow_validator.dart';
import 'package:loom_workflow_engine/src/models/workflow_models.dart';

class CommunityPackageValidator {
  static const supportedEnvelopeVersions = <int>{1};
  static const supportedExperienceVersions = <int>{1, 2};
  static const supportedGrammarVersions = <int>{1};

  ValidationReport validate(Map<String, dynamic> package) {
    final findings = <ValidationFinding>[];
    final envelopeVersion = package['schemaVersion'];
    if (envelopeVersion is! int) {
      findings.add(
        _finding(
          'missing_schema_version',
          'schemaVersion must be present and an int.',
          'schemaVersion',
        ),
      );
    } else if (!supportedEnvelopeVersions.contains(envelopeVersion)) {
      findings.add(
        _finding(
          'unsupported_schema_version',
          'Unsupported schemaVersion "$envelopeVersion".',
          'schemaVersion',
        ),
      );
    }
    final rawExperience = package['experience'];
    if (rawExperience is! Map) {
      findings.add(
        _finding(
          'missing_experience',
          'Package must contain an experience object.',
          'experience',
        ),
      );
      return ValidationReport(findings);
    }
    final experience = Map<String, dynamic>.from(rawExperience);
    final experienceVersion = experience['experienceSchemaVersion'];
    if (experienceVersion is! int) {
      findings.add(
        _finding(
          'missing_schema_version',
          'experience.experienceSchemaVersion must be stamped as an int.',
          'experience/experienceSchemaVersion',
        ),
      );
      return ValidationReport(findings);
    }
    if (!supportedExperienceVersions.contains(experienceVersion)) {
      findings.add(
        _finding(
          'unsupported_schema_version',
          'Unsupported experienceSchemaVersion "$experienceVersion".',
          'experience/experienceSchemaVersion',
        ),
      );
      return ValidationReport(findings);
    }
    if (experienceVersion == 1) {
      findings.add(
        _finding(
          'legacy_experience_schema',
          'Experience schema v1 is legacy and cannot express state machines; engine-native validation was skipped.',
          'experience/experienceSchemaVersion',
          warning: true,
        ),
      );
      return ValidationReport(findings);
    }
    final grammarVersion = experience['workflowGrammarVersion'];
    if (grammarVersion is! int) {
      findings.add(
        _finding(
          'missing_schema_version',
          'experience.workflowGrammarVersion must be stamped as an int.',
          'experience/workflowGrammarVersion',
        ),
      );
      return ValidationReport(findings);
    }
    if (!supportedGrammarVersions.contains(grammarVersion)) {
      findings.add(
        _finding(
          'unsupported_schema_version',
          'Unsupported workflowGrammarVersion "$grammarVersion".',
          'experience/workflowGrammarVersion',
        ),
      );
      return ValidationReport(findings);
    }
    final rawDefinitions = experience['workflowDefinitions'];
    if (rawDefinitions is! Map || rawDefinitions.isEmpty) {
      findings.add(
        _finding(
          'missing_workflow_definitions',
          'experience.workflowDefinitions must be a non-empty map.',
          'experience/workflowDefinitions',
        ),
      );
      return ValidationReport(findings);
    }
    final personas = _personaIds(experience['personas']);
    final declaredTabIds = _declaredTabIds(package);
    final workflows = <String, LoomWorkflowStateMachine>{};
    for (final entry in rawDefinitions.entries) {
      final type = entry.key.toString();
      try {
        workflows[type] = LoomWorkflowStateMachine.fromJson(
          Map<String, dynamic>.from(entry.value as Map),
          type,
        );
      } catch (error) {
        findings.add(
          _finding(
            'invalid_workflow_definition',
            'Workflow "$type" could not be parsed: $error',
            'experience/workflowDefinitions/$type',
          ),
        );
      }
    }
    findings.addAll(
      WorkflowValidator(
        knownPersonaIds: personas,
        declaredTabIds: declaredTabIds,
      ).validate(workflows).findings,
    );
    findings.addAll(_validateTransitionActions(rawDefinitions));
    final rawInstances = experience['workflowInstances'];
    if (rawInstances is! List) return ValidationReport(findings);
    final instances = <String, Map<String, dynamic>>{};
    for (var i = 0; i < rawInstances.length; i++) {
      final path = 'experience/workflowInstances[$i]';
      if (rawInstances[i] is! Map) continue;
      final instance = Map<String, dynamic>.from(rawInstances[i] as Map);
      final id = instance['instanceId'];
      if (id is! String || id.isEmpty) {
        findings.add(
          _finding(
            'missing_instance_id',
            'Instance must have a non-empty instanceId.',
            '$path/instanceId',
          ),
        );
      } else if (instances.containsKey(id)) {
        findings.add(
          _finding(
            'duplicate_instance_id',
            'instanceId "$id" occurs more than once.',
            '$path/instanceId',
          ),
        );
      } else {
        instances[id] = instance;
      }
      final type = instance['workflowType'];
      final workflow = type is String ? workflows[type] : null;
      if (workflow == null) {
        findings.add(
          _finding(
            'unknown_instance_workflow_type',
            'workflowType "${type ?? '<missing>'}" is not defined.',
            '$path/workflowType',
          ),
        );
        continue;
      }
      if (id is String && instances.containsKey(id)) {
        instances[id]!['_validatorSchema'] = workflow.instanceDataSchema;
      }
      final state = instance['currentState'];
      if (state is! String || !workflow.states.containsKey(state)) {
        findings.add(
          _finding(
            'invalid_instance_state',
            'currentState "${state ?? '<missing>'}" is invalid. Valid states: ${workflow.states.keys.join(', ')}.',
            '$path/currentState',
          ),
        );
      }
      final creator = instance['createdByPersonaId'];
      if (creator != null &&
          (creator is! String || !personas.contains(creator)))
        findings.add(
          _finding(
            'unknown_instance_persona',
            'createdByPersonaId "$creator" is not a known persona.',
            '$path/createdByPersonaId',
            warning: true,
          ),
        );
      final data = instance['instanceData'] is Map
          ? Map<String, dynamic>.from(instance['instanceData'] as Map)
          : <String, dynamic>{};
      for (final key in data.keys) {
        final field = workflow.instanceDataSchema[key];
        if (field == null)
          findings.add(
            _finding(
              'unknown_instance_data_key',
              '"$key" is not declared in instanceDataSchema.',
              '$path/instanceData/$key',
            ),
          );
        else if (field.formula != null || field.source != null)
          findings.add(
            _finding(
              'computed_field_seeded',
              'Computed field "$key" must not be seeded.',
              '$path/instanceData/$key',
            ),
          );
      }
      for (final entry in workflow.instanceDataSchema.entries) {
        if (entry.value.required &&
            entry.value.formula == null &&
            entry.value.source == null &&
            (!data.containsKey(entry.key) || data[entry.key] == null))
          findings.add(
            _finding(
              'missing_required_field',
              'Required field "${entry.key}" is missing or null.',
              '$path/instanceData/${entry.key}',
            ),
          );
      }
    }
    for (var i = 0; i < rawInstances.length; i++) {
      if (rawInstances[i] is! Map) continue;
      final instance = Map<String, dynamic>.from(rawInstances[i] as Map);
      final workflow = workflows[instance['workflowType']];
      if (workflow == null) continue;
      final data = instance['instanceData'] is Map
          ? Map<String, dynamic>.from(instance['instanceData'] as Map)
          : <String, dynamic>{};
      final path = 'experience/workflowInstances[$i]';
      for (final transition in workflow.transitions) {
        final guard = transition.guard.relatedListMembership;
        if (guard != null)
          _checkReference(
            data[guard.relatedInstanceField],
            instances,
            guard.relatedListField,
            '$path/instanceData/${guard.relatedInstanceField}',
            findings,
            list: true,
          );
        final aggregate = transition.guard.relatedAggregate;
        final compareTo = aggregate?.compareTo;
        if (compareTo is Map) {
          final relatedInstanceField = compareTo['relatedInstanceField'];
          final field = compareTo['field'];
          if (relatedInstanceField is String && field is String) {
            _checkReference(
              data[relatedInstanceField],
              instances,
              field,
              '$path/instanceData/$relatedInstanceField',
              findings,
            );
          }
        }
        _walkEffects(transition.effects, (effect) {
          if (effect.relatedInstance != null && effect.key != null)
            _checkReference(
              data[effect.relatedInstance],
              instances,
              effect.key!,
              '$path/instanceData/${effect.relatedInstance}',
              findings,
            );
        });
      }
    }
    return ValidationReport(findings);
  }

  void _checkReference(
    dynamic value,
    Map<String, Map<String, dynamic>> instances,
    String targetField,
    String location,
    List<ValidationFinding> findings, {
    bool list = false,
  }) {
    if (value == null || value == '') return;
    final target = value is String ? instances[value] : null;
    if (target == null) {
      findings.add(
        _finding(
          'dangling_instance_reference',
          'Reference "$value" does not name an existing instanceId.',
          location,
        ),
      );
      return;
    }
    // workflow type is looked up from the valid target data through the captured instance map.
    // A sentinel is attached by the caller-independent lookup below.
    final type = target['workflowType'];
    // Definitions are not needed here because target fields have already been validated from instance data;
    // retain the declared schema on the instance map for this localized lookup.
    final schema =
        target['_validatorSchema'] as Map<String, InstanceDataField>?;
    final field = schema?[targetField];
    if (field == null)
      findings.add(
        _finding(
          list ? 'dangling_related_list_field' : 'dangling_instance_data_key',
          'Target instance workflow "$type" does not declare "$targetField".',
          location,
        ),
      );
    else if (!list && (field.formula != null || field.source != null))
      findings.add(
        _finding(
          'computed_field_written_by_effect',
          'Effect writes computed target field "$targetField".',
          location,
        ),
      );
  }

  void _walkEffects(
    List<WorkflowEffect> effects,
    void Function(WorkflowEffect) visit,
  ) {
    for (final effect in effects) {
      visit(effect);
      _walkEffects(effect.thenEffects, visit);
      _walkEffects(effect.elseEffects, visit);
    }
  }

  Set<String> _personaIds(dynamic raw) {
    if (raw is! List) return {};
    return raw
        .whereType<Object>()
        .map(
          (p) => p is String
              ? p
              : p is Map
              ? p['personaId'] as String?
              : null,
        )
        .whereType<String>()
        .toSet();
  }

  Set<String> _declaredTabIds(Map<String, dynamic> package) {
    final appShell = _objectMap(package['appShell']) ??
        _objectMap(package['appShellCustomization']) ??
        _objectMap(_objectMap(package['extension'])?['appShell']);
    if (appShell == null) return {};

    final declared = <String>{};
    final rawTabs = appShell['tabs'];
    if (rawTabs is List) {
      for (final rawTab in rawTabs) {
        final tab = _objectMap(rawTab);
        final id = tab?['tabId'];
        if (id is String && id.isNotEmpty) declared.add(id);
      }
    }

    final personaTabs = _objectMap(appShell['personaTabs']);
    if (personaTabs == null) return declared;

    for (final rawPersonaTabs in personaTabs.values) {
      if (rawPersonaTabs is! List) continue;
      for (final rawTab in rawPersonaTabs) {
        final tab = _objectMap(rawTab);
        final id = tab?['tabId'];
        if (id is String && id.isNotEmpty) declared.add(id);
      }
    }
    return declared;
  }

  Map<String, Object?>? _objectMap(Object? value) {
    return value is Map<String, Object?> ? value : null;
  }

  /// permissions.md §8's rules for the `action` field.
  ///
  /// A transition's `action` is what the platform maps to the permission the
  /// transition requires, so a missing or misspelled one leaves a permission
  /// ungranted and the action then fails at runtime for a reason no author can
  /// see in the JSON. That is why every rule here is an error rather than a
  /// warning.
  ///
  /// Reads the raw definitions on purpose: `LoomWorkflowStateMachine.fromJson`
  /// only picks out the keys it knows, and `action` is not one of them.
  List<ValidationFinding> _validateTransitionActions(Map<Object?, Object?> raw) {
    const resolver = ArchetypeResolver();
    final definitions = <String, Object?>{
      for (final entry in raw.entries) entry.key.toString(): entry.value,
    };
    final archetypes = resolver.resolveAll(definitions);
    final findings = <ValidationFinding>[];

    for (final entry in definitions.entries) {
      final type = entry.key;
      final workflow = entry.value;
      if (workflow is! Map) continue;
      final archetype = archetypes[type];
      if (archetype == null) continue;
      final path = 'experience/workflowDefinitions/$type';

      if (archetype.conflictingBespokeFamilies.length > 1) {
        findings.add(
          _finding(
            'ambiguous_workflow_archetype',
            'Workflow "$type" names more than one bespoke cardSurfaceFamily '
                '(${archetype.conflictingBespokeFamilies.join(", ")}), so its '
                'archetype is undecidable and its transitions could belong to '
                'either closed vocabulary. Mixing one bespoke family with '
                'generic bindings is fine; two bespoke families is not.',
            '$path/renderBindings',
          ),
        );
      }

      final transitions = workflow['transitions'];
      if (transitions is! List) continue;
      for (var i = 0; i < transitions.length; i++) {
        final transition = transitions[i];
        if (transition is! Map) continue;
        final id = transition['id'];
        final label = id is String && id.isNotEmpty ? id : '[$i]';
        final transitionPath = '$path/transitions/$label';
        final action = transition['action'];
        final family = archetype.family;

        if (!archetype.requiresAction) {
          if (action != null) {
            final because = archetype.origin == ArchetypeOrigin.none
                ? 'has no renderBindings and is not a responseTable target, so '
                      'it derives no permission at all'
                : 'is the generic family "$family", which derives its '
                      'permissions structurally from tone and isTerminal';
            findings.add(
              _finding(
                'unexpected_transition_action',
                'Transition "$label" declares action "$action", but workflow '
                    '"$type" $because. Remove the action field.',
                '$transitionPath/action',
              ),
            );
          }
          continue;
        }

        if (action == null) {
          final via = archetype.origin ==
                  ArchetypeOrigin.inheritedFromResponseTable
              ? ' (archetype inherited from "${archetype.inheritedFrom}" via '
                    'its binding\'s responseTable)'
              : '';
          findings.add(
            _finding(
              'missing_transition_action',
              'Transition "$label" of bespoke workflow "$type" must declare an '
                  'action$via. Without it the transition derives no '
                  'permission and will fail at runtime.',
              '$transitionPath/action',
            ),
          );
          continue;
        }

        if (action is! String ||
            family == null ||
            !resolver.isActionInVocabulary(family, action)) {
          final allowed =
              (ArchetypeResolver.bespokeVocabularies[family]?.toList() ??
                  const <String>[])
                ..sort();
          findings.add(
            _finding(
              'unknown_transition_action',
              'Transition "$label" declares action "$action", which is not in '
                  'the closed vocabulary for "$family". Allowed: '
                  '${allowed.join(", ")}.',
              '$transitionPath/action',
            ),
          );
        }
      }
    }
    return findings;
  }

  ValidationFinding _finding(
    String type,
    String message,
    String location, {
    bool warning = false,
  }) => ValidationFinding(
    type: type,
    message: message,
    location: location,
    isWarning: warning,
  );
}
