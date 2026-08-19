import 'dart:convert';

import 'package:loom_ux_judges/src/validator/workflow_validator.dart';
import 'package:loom_workflow_engine/src/archetypes/archetype_resolver.dart';
import 'package:loom_workflow_engine/src/models/workflow_models.dart';

class CommunityPackageValidator {
  /// The current single-number specification version.
  ///
  /// One number versions the whole package. The three legacy stamps below are
  /// still accepted while `spec-version.json` → `pendingMigration` lists the
  /// fixtures, and the legacy branch is deleted once that list is empty.
  static const supportedSpecVersions = <int>{4};

  static const supportedEnvelopeVersions = <int>{1};
  static const supportedExperienceVersions = <int>{1, 2};
  static const supportedGrammarVersions = <int>{1};

  ValidationReport validate(Map<String, dynamic> package) {
    final findings = <ValidationFinding>[];

    // A package declares either the single `specVersion` or the legacy triple,
    // never a mixture. Which one it uses selects the rule set: identity types
    // and `audience` are only enforced from specVersion 4 onward, because a
    // legacy package legitimately still says `personaId` and `role`.
    final specVersion = package['specVersion'];
    final isSpecVersioned = specVersion != null;

    if (isSpecVersioned) {
      if (specVersion is! int) {
        findings.add(
          _finding(
            'missing_schema_version',
            'specVersion must be an int.',
            'specVersion',
          ),
        );
        return ValidationReport(findings);
      }
      if (!supportedSpecVersions.contains(specVersion)) {
        findings.add(
          _finding(
            'unsupported_schema_version',
            'Unsupported specVersion "$specVersion". A loader that meets a '
                'version it does not implement must fail rather than '
                'best-effort-parse: silently ignoring a construct is how a '
                'community ships a guard that never fires.',
            'specVersion',
          ),
        );
        return ValidationReport(findings);
      }
      // The legacy stamps must be gone, not merely ignored. Leaving one behind
      // is how a package ends up declaring two different versions of itself --
      // which is precisely the drift that produced this collapse.
      for (final legacy in const [
        ['schemaVersion', 'schemaVersion'],
        ['experience.experienceSchemaVersion', 'experienceSchemaVersion'],
        ['experience.workflowGrammarVersion', 'workflowGrammarVersion'],
      ]) {
        final present = legacy[0].startsWith('experience.')
            ? (package['experience'] is Map &&
                (package['experience'] as Map).containsKey(legacy[1]))
            : package.containsKey(legacy[1]);
        if (present) {
          findings.add(
            _finding(
              'legacy_version_stamp',
              'A package declaring specVersion must not also carry '
                  '"${legacy[1]}". One number versions the whole package.',
              legacy[0].replaceAll('.', '/'),
            ),
          );
        }
      }
    } else {
      final envelopeVersion = package['schemaVersion'];
      if (envelopeVersion is! int) {
        findings.add(
          _finding(
            'missing_schema_version',
            'Package must declare specVersion (or, until the migration '
                'completes, the legacy schemaVersion).',
            'specVersion',
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

    // The legacy stamps only gate a legacy package. A specVersion package has
    // already been version-checked once, by the single number that governs all
    // of it.
    if (!isSpecVersioned) {
      final legacyGate = _validateLegacyStamps(experience);
      if (legacyGate != null) {
        findings.addAll(legacyGate);
        return ValidationReport(findings);
      }
    }
    findings.addAll(_validateIdentityKeys(package, experience, isSpecVersioned));
    return _validateBody(package, experience, findings);
  }

  /// The three legacy version checks, unchanged. Returns the findings that must
  /// terminate validation, or null to continue.
  List<ValidationFinding>? _validateLegacyStamps(
    Map<String, dynamic> experience,
  ) {
    final experienceVersion = experience['experienceSchemaVersion'];
    if (experienceVersion is! int) {
      return [
        _finding(
          'missing_schema_version',
          'experience.experienceSchemaVersion must be stamped as an int.',
          'experience/experienceSchemaVersion',
        ),
      ];
    }
    if (!supportedExperienceVersions.contains(experienceVersion)) {
      return [
        _finding(
          'unsupported_schema_version',
          'Unsupported experienceSchemaVersion "$experienceVersion".',
          'experience/experienceSchemaVersion',
        ),
      ];
    }
    if (experienceVersion == 1) {
      return [
        _finding(
          'legacy_experience_schema',
          'Experience schema v1 is legacy and cannot express state machines; engine-native validation was skipped.',
          'experience/experienceSchemaVersion',
          warning: true,
        ),
      ];
    }
    final grammarVersion = experience['workflowGrammarVersion'];
    if (grammarVersion is! int) {
      return [
        _finding(
          'missing_schema_version',
          'experience.workflowGrammarVersion must be stamped as an int.',
          'experience/workflowGrammarVersion',
        ),
      ];
    }
    if (!supportedGrammarVersions.contains(grammarVersion)) {
      return [
        _finding(
          'unsupported_schema_version',
          'Unsupported workflowGrammarVersion "$grammarVersion".',
          'experience/workflowGrammarVersion',
        ),
      ];
    }
    return null;
  }

  ValidationReport _validateBody(
    Map<String, dynamic> package,
    Map<String, dynamic> experience,
    List<ValidationFinding> findings,
  ) {
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
    findings.addAll(
      _validateVisibilityFields(
        rawDefinitions,
        declaredRoles: experience['roles'],
      ),
    );
    findings.addAll(_validateTransitionActions(rawDefinitions));
    findings.addAll(_validateResponseRowSweep(rawDefinitions));
    findings.addAll(_validateRedundantTransitions(rawDefinitions));
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

  /// identity-types.md — the `roleId` / `fanId` split, enforced from
  /// specVersion 4.
  ///
  /// A legacy package legitimately still says `personaId` and `role`, so none
  /// of this applies to one. What makes the split worth having is the last
  /// check: comparing `$viewer` to a declared role is a type error rather than
  /// a silent false, and three formulas in the corpus are broken by exactly
  /// that today while producing no diagnostic at all.
  List<ValidationFinding> _validateIdentityKeys(
    Map<String, dynamic> package,
    Map<String, dynamic> experience,
    bool isSpecVersioned,
  ) {
    if (!isSpecVersioned) return const [];
    final findings = <ValidationFinding>[];

    // Renamed keys. Their continued presence means a package was hand-edited
    // to the new version without being regenerated.
    const renamed = {
      'allowedPersonaIds': 'allowedRoleIds',
      'byPersonaIds': 'byRoleIds',
      'visiblePersonaIds': 'visibleRoleIds',
      'personaTabs': 'roleTabs',
      'personas': 'roles',
    };
    void walk(Object? node, String path) {
      if (node is Map) {
        for (final entry in node.entries) {
          final key = entry.key.toString();
          final replacement = renamed[key];
          if (replacement != null) {
            findings.add(
              _finding(
                'legacy_identity_key',
                'specVersion 4 renamed "$key" to "$replacement". '
                    'See identity-types.md.',
                '$path/$key',
              ),
            );
          }
          if (key == 'role' && node.containsKey('cardSurfaceFamily')) {
            findings.add(
              _finding(
                'legacy_identity_key',
                'specVersion 4 renamed renderBindings[].role to "audience". It '
                    'never meant a community role — its values are '
                    'actor/receiver/any, the viewer\'s relationship to an '
                    'instance.',
                '$path/role',
              ),
            );
          }
          walk(entry.value, '$path/$key');
        }
      } else if (node is List) {
        for (var i = 0; i < node.length; i++) {
          walk(node[i], '$path[$i]');
        }
      }
    }

    walk(experience, 'experience');
    walk(package['appShell'], 'appShell');

    // Comparing an identity to a declared role literal. `$actor`/`$viewer` are
    // fanIds; a roleId on the other side can never match, which in a v1
    // package failed silently.
    final roleIds = <String>{
      for (final role in (experience['roles'] as List? ?? const []))
        if (role is Map && role['roleId'] is String) role['roleId'] as String,
    };
    if (roleIds.isNotEmpty) {
      final comparison = RegExp(
        r'''\$(?:actor|viewer)\s*==\s*['"]([^'"]+)['"]|['"]([^'"]+)['"]\s*==\s*\$(?:actor|viewer)''',
      );
      void scanFormulas(Object? node, String path) {
        if (node is Map) {
          for (final entry in node.entries) {
            final key = entry.key.toString();
            final value = entry.value;
            if (value is String &&
                (key == 'formula' || key == 'if' || key.endsWith('Formula'))) {
              for (final match in comparison.allMatches(value)) {
                final literal = match.group(1) ?? match.group(2);
                if (literal != null && roleIds.contains(literal)) {
                  findings.add(
                    _finding(
                      'identity_compared_to_role',
                      'Compares \$actor/\$viewer (a fanId) against "$literal", '
                          'which is a declared roleId. This can never be true. '
                          '"This person, or anyone with this role" is a fanId '
                          'comparison plus an allowedRoleIds guard — they are '
                          'different layers.',
                      '$path/$key',
                    ),
                  );
                }
              }
            }
            scanFormulas(value, '$path/$key');
          }
        } else if (node is List) {
          for (var i = 0; i < node.length; i++) {
            scanFormulas(node[i], '$path[$i]');
          }
        }
      }

      scanFormulas(experience, 'experience');
    }
    return findings;
  }

  /// Decision D9 (`444c6a90`): validate the instance-data field mappings used
  /// by archetype visibility models.
  ///
  /// Archetype resolution stays centralized in [ArchetypeResolver]. This check
  /// reads the raw workflow JSON only after resolution because the mapping's
  /// key presence and list entries are authoring details that must retain their
  /// exact source locations in findings.
  List<ValidationFinding> _validateVisibilityFields(
    Map<Object?, Object?> raw, {
    required Object? declaredRoles,
  }) {
    const resolver = ArchetypeResolver();
    final definitions = <String, Object?>{
      for (final entry in raw.entries) entry.key.toString(): entry.value,
    };
    final archetypes = resolver.resolveAll(definitions);
    final findings = <ValidationFinding>[];
    final declaredRoleIds = <String>{
      for (final role in (declaredRoles as List? ?? const []))
        if (role is Map && role['roleId'] is String) role['roleId'] as String,
    };

    for (final entry in definitions.entries) {
      final type = entry.key;
      final workflow = entry.value;
      if (workflow is! Map) continue;

      final family = archetypes[type]?.family;
      final model = ArchetypeResolver.contracts[family]?.visibility;
      if (model == null) continue;

      final path = 'experience/workflowDefinitions/$type/visibility/fields';
      final visibility = workflow['visibility'];
      final rawFields = visibility is Map ? visibility['fields'] : null;
      final fields = rawFields is Map ? rawFields : null;
      final states = workflow['states'];
      final hasStateReadGuard =
          states is Map &&
          states.values.any(
            (state) => state is Map && state.containsKey('readGuard'),
          );
      final engagesIdentityScopedLayer =
          (visibility is Map &&
              (visibility['default'] == 'guarded' ||
                  visibility.containsKey('readGuard'))) ||
          hasStateReadGuard;
      final requiredKey = switch (model) {
        VisibilityModel.ownerAndShared => 'sharedWith',
        VisibilityModel.participants => 'participants',
        VisibilityModel.parties => 'parties',
        VisibilityModel.roles ||
        VisibilityModel.owner ||
        VisibilityModel.recipient => null,
      };

      if (engagesIdentityScopedLayer &&
          requiredKey != null &&
          (fields == null || !fields.containsKey(requiredKey))) {
        findings.add(
          _finding(
            'missing_visibility_fields',
            "The workflow's archetype uses a visibility model that reads "
                'instance-data identities (`owner_and_shared`, `participants`, '
                '`parties`, `recipient`) but declares no `visibility.fields` '
                'mapping. The engine cannot guess which field is a party rather '
                'than an audit actor.',
            '$path/$requiredKey',
          ),
        );
      }

      if (fields == null) continue;
      final schema = workflow['instanceDataSchema'];
      final declaredFields = schema is Map
          ? schema.keys.map((key) => key.toString()).toSet()
          : const <String>{};

      void checkField(Object? value, String location) {
        if (value is! String || declaredFields.contains(value)) return;
        findings.add(
          _finding(
            'dangling_visibility_field',
            'A field named in `visibility.fields` is not declared in this '
                "workflow's `instanceDataSchema`.",
            location,
          ),
        );
      }

      checkField(fields['sharedWith'], '$path/sharedWith');
      final participants = fields['participants'];
      if (participants is List) {
        for (var i = 0; i < participants.length; i++) {
          checkField(participants[i], '$path/participants[$i]');
        }
      }
      checkField(fields['recipient'], '$path/recipient');

      final parties = fields['parties'];
      if (parties is List) {
        for (var i = 0; i < parties.length; i++) {
          final principal = parties[i];
          final location = '$path/parties[$i]';
          if (principal is String) {
            if (principal.isEmpty) {
              findings.add(
                _finding(
                  'invalid_visibility_principal',
                  'A `visibility.fields.parties` string must be a non-empty '
                      'instance-data field name.',
                  location,
                ),
              );
            }
            checkField(principal, location);
            continue;
          }
          if (principal is Map &&
              principal.length == 1 &&
              principal.containsKey('role') &&
              principal['role'] is String &&
              (principal['role'] as String).isNotEmpty) {
            final roleId = principal['role'] as String;
            if (!declaredRoleIds.contains(roleId)) {
              findings.add(
                _finding(
                  'dangling_visibility_role',
                  'A role named in `visibility.fields.parties` is not declared '
                      'in `experience.roles[]`.',
                  location,
                ),
              );
            }
            continue;
          }
          findings.add(
            _finding(
              'invalid_visibility_principal',
              'A `visibility.fields.parties` entry must be a non-empty field '
                  'name or an object containing only a non-empty string role.',
              location,
            ),
          );
        }
      }
      if (fields.containsKey('parties') &&
          parties is List &&
          parties.length != 2) {
        findings.add(
          _finding(
            'invalid_parties_arity',
            '`visibility.fields.parties` does not name exactly two fields.',
            '$path/parties',
          ),
        );
      }
    }
    return findings;
  }

  /// Two transitions offered from the same state, landing on the same state,
  /// are two buttons that do the same thing.
  ///
  /// The archetype deliberately does not mandate where `withdraw_response`
  /// lands — communities own their own state vocabularies, and a community may
  /// route withdrawal to a `pendingStates` member, to a declared `withdrawn`
  /// state, or anywhere else that reads correctly to its members. What it may
  /// not do is duplicate a `respond` transition: Riverside's `cancel-rsvp`
  /// (`going|maybe|waitlisted -> declined`) is a strict subset of its own
  /// `respond-declined` (`pending|going|maybe|waitlisted -> declined`), so a
  /// member sees "Not going" and "Cancel RSVP" side by side, doing exactly the
  /// same thing.
  ///
  /// Scoped to one workflow on purpose. Different workflows may share a target
  /// state and label the button differently — that is not redundancy, because
  /// the two are never offered together.
  List<ValidationFinding> _validateRedundantTransitions(
    Map<Object?, Object?> raw,
  ) {
    final findings = <ValidationFinding>[];
    for (final entry in raw.entries) {
      final workflow = entry.value;
      if (workflow is! Map) continue;
      final transitions = workflow['transitions'];
      if (transitions is! List) continue;

      List<String> sourcesOf(Map<Object?, Object?> t) {
        final from = t['from'];
        if (from is List) return from.map((e) => e.toString()).toList();
        if (from is String) return [from];
        return const [];
      }

      for (var i = 0; i < transitions.length; i++) {
        for (var j = i + 1; j < transitions.length; j++) {
          final a = transitions[i];
          final b = transitions[j];
          if (a is! Map || b is! Map) continue;
          // A null `to` is a self-transition (data edit), never redundant with
          // a state move.
          final to = a['to'];
          if (to == null || to != b['to']) continue;

          final overlap = sourcesOf(a).toSet().intersection(
            sourcesOf(b).toSet(),
          );
          if (overlap.isEmpty) continue;

          // Same destination is not enough. Two transitions legitimately share
          // a target when they *do* different things on the way there
          // (`start-export` and `start-transfer` both reach `running`), or when
          // their guards mean they are never offered to the same person
          // (`cancel` vs `board-cancel`). Redundancy is only real when neither
          // is true: identical effects and identical guards, so the member sees
          // two controls with the same outcome.
          // Differing guards mean the two are never offered to the same person
          // (`cancel` vs `board-cancel`), so they cannot be redundant controls.
          //
          // Effects are deliberately NOT required to match. Riverside's
          // `cancel-rsvp` and `respond-declined` carry identical guards and
          // effects that differ only in an audit string ("cancelled" vs
          // "declined" appended to responseHistory) -- byte-comparing effects
          // lets a history label hide a genuine duplicate. What survives is a
          // question worth a human answering: these two are offered together
          // and land in the same state, so are they meaningfully different?
          if (jsonEncode(a['guard'] ?? const <String, Object?>{}) !=
              jsonEncode(b['guard'] ?? const <String, Object?>{})) {
            continue;
          }

          findings.add(
            _finding(
              'redundant_transition',
              'Transitions "${a['id']}" and "${b['id']}" on "${entry.key}" share '
                  'a guard and both move to "$to" from '
                  '${(overlap.toList()..sort()).map((s) => '"$s"').join(', ')}, '
                  'so the same member is offered both at once with the same '
                  'outcome. Confirm they are meaningfully different: two '
                  'distinct operations may legitimately share a target state '
                  '(an export and a transfer both reaching "running"), and that '
                  'is fine. What is not fine is two labels for one capability — '
                  'if they differ only in bookkeeping, give one a distinct '
                  'target or remove it.',
              'experience/workflowDefinitions/${entry.key}/transitions',
              warning: true,
            ),
          );
        }
      }
    }
    return findings;
  }

  /// A terminal transition on a workflow that owns response rows must sweep
  /// them, or it orphans rows that stay live.
  ///
  /// Cancelling an event leaves its response rows in whatever state they were
  /// in, still accepting `respond` — the row's own state machine has no
  /// visibility into its parent's. Measured across the corpus, **all six**
  /// communities with response rows have this hole today, so this is a
  /// pre-existing defect rather than one the row shape introduces. The array
  /// shape hid it only because the arrays lived on the event, so cancelling
  /// took them along.
  ///
  /// (A hand-count of the fixtures found five and missed Cedar Commons HOA's
  /// `hoa-meeting`, which lives in the calendar-slice file — the rule finding
  /// the sixth is the argument for having the rule.)
  ///
  /// **Severity is a ratchet (D3, approved 2026-08-14): warning now, error
  /// after Phase F.** Phase F regenerates all 11 fixtures through the Skill;
  /// once the corpus is clean this becomes an error so it cannot regress. Do
  /// not promote it before then — six shipped communities trip it today, and
  /// the guide's own rule is that a community failing the validator is not a
  /// deliverable. That the corpus *can* be made clean is demonstrated, not
  /// hoped: a Codex dispatch emitted the full per-state cascade unprompted,
  /// from these docs alone.
  ///
  /// A warning rather than an error, deliberately: six shipped communities
  /// trip it, and making the corpus un-validatable trains people to ignore
  /// warnings. It is satisfiable today — Cedar Commons HOA already cascades a
  /// parent's state change to child rows with `transitionRelated`, one effect
  /// per source state — which is the test a rule has to pass before it earns a
  /// place. A rule nobody can act on is worse than no rule.
  List<ValidationFinding> _validateResponseRowSweep(Map<Object?, Object?> raw) {
    final findings = <ValidationFinding>[];
    final definitions = <String, Object?>{
      for (final entry in raw.entries) entry.key.toString(): entry.value,
    };

    for (final entry in definitions.entries) {
      final workflow = entry.value;
      if (workflow is! Map) continue;

      // Which response types does this workflow own?
      final owned = <String>{};
      final bindings = workflow['renderBindings'];
      if (bindings is List) {
        for (final binding in bindings) {
          if (binding is! Map) continue;
          final table = binding['responseTable'];
          if (table is Map && table['workflowType'] is String) {
            owned.add(table['workflowType'] as String);
          }
        }
      }
      if (owned.isEmpty) continue;

      final states = workflow['states'];
      final transitions = workflow['transitions'];
      if (transitions is! List) continue;

      for (final transition in transitions) {
        if (transition is! Map) continue;
        final to = transition['to'];
        final terminal = (to is String &&
                states is Map &&
                states[to] is Map &&
                (states[to] as Map)['isTerminal'] == true) ||
            transition['tone'] == 'destructive';
        if (!terminal) continue;

        // Collect, per swept response type, which `$state` values the cascade
        // actually covers. A filter matches one state at a time, so covering a
        // type means one effect per non-terminal state it declares.
        final sweptStates = <String, Set<String>>{};
        final effects = transition['effects'];
        if (effects is List) {
          for (final effect in effects) {
            if (effect is! Map || effect['op'] != 'transitionRelated') continue;
            final query = effect['relatedQuery'];
            if (query is! Map || query['workflowType'] is! String) continue;
            final type = query['workflowType'] as String;
            final filter = query['filter'];
            final state = filter is Map ? filter[r'$state'] : null;
            (sweptStates[type] ??= <String>{}).add(
              state is String ? state : '*',
            );
          }
        }

        final id = transition['id'];
        for (final type in owned) {
          final covered = sweptStates[type] ?? const <String>{};
          // An unfiltered sweep covers everything by definition.
          if (covered.contains('*')) continue;

          final target = definitions[type];
          final targetStates = target is Map ? target['states'] : null;
          final live = <String>{};
          if (targetStates is Map) {
            for (final s in targetStates.entries) {
              final decl = s.value;
              if (decl is Map && decl['isTerminal'] == true) continue;
              live.add(s.key.toString());
            }
          }

          final missed = live.difference(covered);
          if (covered.isEmpty) {
            findings.add(
              _finding(
                'orphaned_response_rows',
                'Transition "${id ?? '?'}" ends "${entry.key}" but does not '
                    'sweep "$type". Those response rows stay in whatever state '
                    'they were in and keep accepting responses, because a row '
                    'cannot see its parent\'s state. Cascade with a '
                    '`transitionRelated` effect per source state.',
                'experience/workflowDefinitions/${entry.key}/transitions/'
                    '${id ?? '?'}/effects',
                warning: true,
              ),
            );
          } else if (missed.isNotEmpty) {
            findings.add(
              _finding(
                'orphaned_response_rows',
                'Transition "${id ?? '?'}" ends "${entry.key}" and sweeps '
                    '"$type", but misses '
                    '${(missed.toList()..sort()).map((s) => '"$s"').join(', ')}'
                    '. A `\$state` filter matches one state at a time, so the '
                    'cascade needs one effect for every non-terminal state '
                    '"$type" declares -- rows left in a missed state survive '
                    'the cancellation still claiming a live answer.',
                'experience/workflowDefinitions/${entry.key}/transitions/'
                    '${id ?? '?'}/effects',
                warning: true,
              ),
            );
          }
        }
      }
    }
    return findings;
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
                  'action$via. Without it the transition still runs without an '
                  'error, but the archetype\'s per-person bookkeeping for it is '
                  'silently skipped. Bespoke families use a closed action '
                  'vocabulary, so no permission can be derived and, unlike '
                  'generic families, nothing structural can supply the missing '
                  'action; the validator must catch the silent omission.',
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
