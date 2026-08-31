import 'dart:convert';

import 'package:loom_ux_judges/src/validator/generated_capability_baseline.dart';
import 'package:loom_ux_judges/src/validator/workflow_validator.dart';
import 'package:loom_workflow_engine/loom_workflow_engine.dart'
    show
        FormulaEvaluationException,
        analyzeFormula,
        currentCommunitySpecVersion,
        supportsCommunityCapability;
import 'package:loom_workflow_engine/src/archetypes/archetype_resolver.dart';
import 'package:loom_workflow_engine/src/evaluator/recurrence_evaluator.dart';
import 'package:loom_workflow_engine/src/models/workflow_models.dart';

class CommunityPackageValidator {
  CommunityPackageValidator({Set<String>? capabilityBaseline})
    : _capabilityBaseline = Set<String>.unmodifiable(
        capabilityBaseline ?? communityCapabilityBaseline,
      );

  /// The current single-number specification version.
  ///
  /// One number versions the whole package.
  static const supportedSpecVersions = <int>{currentCommunitySpecVersion};

  final Set<String> _capabilityBaseline;

  ValidationReport validate(Map<String, dynamic> package) {
    final findings = <ValidationFinding>[];

    final specVersion = package['specVersion'];
    const legacyVersionStamps = [
      ['schemaVersion', 'schemaVersion'],
      ['experience.experienceSchemaVersion', 'experienceSchemaVersion'],
      ['experience.workflowGrammarVersion', 'workflowGrammarVersion'],
    ];
    var hasLegacyVersionStamp = false;
    for (final legacy in legacyVersionStamps) {
      final present = legacy[0].startsWith('experience.')
          ? (package['experience'] is Map &&
                (package['experience'] as Map).containsKey(legacy[1]))
          : package.containsKey(legacy[1]);
      if (!present) continue;
      hasLegacyVersionStamp = true;
      findings.add(
        _finding(
          'legacy_version_stamp',
          'Pre-specVersion-4 packages are unsupported. Remove '
              '"${legacy[1]}" and re-author the package with '
              'specVersion: $currentCommunitySpecVersion. See '
              'docs/references/reference/identity-types.md.',
          legacy[0].replaceAll('.', '/'),
        ),
      );
    }
    if (hasLegacyVersionStamp) {
      return ValidationReport(findings);
    }
    if (specVersion is! int) {
      findings.add(
        _finding(
          'missing_schema_version',
          'Package must declare specVersion: '
              '$currentCommunitySpecVersion. Pre-v4 packages are unsupported. '
              'See docs/references/reference/identity-types.md.',
          'specVersion',
        ),
      );
      return ValidationReport(findings);
    }
    if (!supportedSpecVersions.contains(specVersion)) {
      findings.add(
        _finding(
          'unsupported_schema_version',
          'Unsupported specVersion "$specVersion". Only specVersion: '
              '$currentCommunitySpecVersion is supported; re-author pre-v4 '
              'packages using docs/references/reference/identity-types.md.',
          'specVersion',
        ),
      );
      return ValidationReport(findings);
    }
    final unsupportedCapabilities = _validateSupportedCapabilities(package);
    if (unsupportedCapabilities.isNotEmpty) {
      return ValidationReport(unsupportedCapabilities);
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

    findings.addAll(_validateIdentityKeys(package, experience));
    findings.addAll(_validateNotifications(experience));
    findings.addAll(_validateTabPermissionDeclarations(package));
    return _validateBody(package, experience, findings);
  }

  List<ValidationFinding> _validateNotifications(
    Map<String, dynamic> experience,
  ) {
    if (!experience.containsKey('notifications')) return const [];
    final rawNotifications = experience['notifications'];
    if (rawNotifications is! Map) {
      return <ValidationFinding>[
        _finding(
          'unknown_notification_key',
          'experience.notifications must be an object with only '
              '`allowedChannels`, `default`, and `muted` keys.',
          'experience/notifications',
        ),
      ];
    }

    const allowedKeys = <String>{'allowedChannels', 'default', 'muted'};
    const supportedChannels = <String>{'inbox', 'push'};
    final findings = <ValidationFinding>[];
    for (final rawKey in rawNotifications.keys) {
      final key = rawKey.toString();
      if (rawKey is String && allowedKeys.contains(key)) continue;
      findings.add(
        _finding(
          'unknown_notification_key',
          'Unknown key `$key` in experience.notifications. Legal keys: '
              '`allowedChannels`, `default`, `muted`.',
          'experience/notifications/$key',
        ),
      );
    }

    List<Object?>? channelsFor(String key, List<Object?> omittedValue) {
      if (!rawNotifications.containsKey(key)) return omittedValue;
      final value = rawNotifications[key];
      if (value is List) return List<Object?>.from(value);
      findings.add(
        _finding(
          'unknown_notification_channel',
          'experience.notifications.$key must be a list of the supported '
              'channels `inbox` and `push`.',
          'experience/notifications/$key',
        ),
      );
      return null;
    }

    final allowedChannels = channelsFor('allowedChannels', const ['inbox']);
    final defaultChannels = channelsFor('default', const ['inbox']);

    void validateChannels(String key, List<Object?>? channels) {
      if (channels == null) return;
      if (rawNotifications.containsKey(key) && channels.isEmpty) {
        findings.add(
          _finding(
            'empty_notification_channels',
            'experience.notifications.$key must not be empty. Omit it to use '
                'the default `inbox` channel.',
            'experience/notifications/$key',
          ),
        );
      }
      for (var index = 0; index < channels.length; index++) {
        final channel = channels[index];
        if (channel is String && supportedChannels.contains(channel)) continue;
        findings.add(
          _finding(
            'unknown_notification_channel',
            'Notification channel `${channel ?? '<null>'}` is not supported. '
                'Use `inbox` or `push`.',
            'experience/notifications/$key[$index]',
          ),
        );
      }
    }

    validateChannels('allowedChannels', allowedChannels);
    validateChannels('default', defaultChannels);

    if (allowedChannels != null &&
        defaultChannels != null &&
        allowedChannels.isNotEmpty &&
        defaultChannels.isNotEmpty) {
      final offeredChannels = allowedChannels.whereType<String>().toSet();
      for (var index = 0; index < defaultChannels.length; index++) {
        final channel = defaultChannels[index];
        if (channel is! String ||
            !supportedChannels.contains(channel) ||
            offeredChannels.contains(channel)) {
          continue;
        }
        findings.add(
          _finding(
            'notification_default_not_offered',
            'Default notification channel `$channel` is not offered by '
                'experience.notifications.allowedChannels.',
            'experience/notifications/default[$index]',
          ),
        );
      }
    }

    if (rawNotifications['muted'] == true &&
        defaultChannels != null &&
        !defaultChannels.contains('inbox')) {
      findings.add(
        _finding(
          'notification_muted_without_inbox',
          'A muted community must still default to `inbox` so members can '
              'read the notification record.',
          'experience/notifications/muted',
        ),
      );
    }
    return findings;
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
    findings.addAll(_validateUnknownWorkflowKeys(rawDefinitions));
    final roleIds = _roleIds(experience['roles']);
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
    final usedCapabilities = _usedCapabilities(package, workflows);
    findings.addAll(_validateUnusedCapabilities(package, usedCapabilities));
    findings.addAll(_validateUndeclaredCapabilities(package, usedCapabilities));
    findings.addAll(
      WorkflowValidator(
        knownRoleIds: roleIds,
        declaredTabIds: declaredTabIds,
      ).validate(workflows).findings,
    );
    findings.addAll(_validateComputedFieldsAreNotRequired(workflows));
    findings.addAll(
      _validateVisibilityFields(
        rawDefinitions,
        declaredRoles: experience['roles'],
      ),
    );
    findings.addAll(_validateTransitionActions(rawDefinitions));
    findings.addAll(_validateResponseRowSweep(rawDefinitions));
    findings.addAll(_validateRedundantTransitions(rawDefinitions));
    findings.addAll(_validateDocumentContentSource(rawDefinitions));
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
      final seedCreator = _seedCreator(instance);
      if (seedCreator == null) {
        final instanceLabel = instance.containsKey('instanceId')
            ? ' "${instance['instanceId']}"'
            : '';
        findings.add(
          _finding(
            'seed_instance_missing_creator',
            'Seed instance$instanceLabel must declare a non-empty creator '
                'using createdByFanId. Without that creator, the community fails '
                'to install. The field identifies a person (fanId), not a '
                'role.',
            '$path/createdByFanId',
          ),
        );
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

  List<ValidationFinding> _validateComputedFieldsAreNotRequired(
    Map<String, LoomWorkflowStateMachine> workflows,
  ) {
    final findings = <ValidationFinding>[];
    for (final workflowEntry in workflows.entries) {
      for (final fieldEntry in workflowEntry.value.instanceDataSchema.entries) {
        final field = fieldEntry.value;
        if (!field.required ||
            (field.formula == null && field.source == null)) {
          continue;
        }
        final remediation = field.formula != null
            ? 'declares a formula and is also marked required. A '
                  'formula-computed field is derived by the engine, so '
                  'requiring it makes instance creation fail with "Required '
                  'field is missing or null". Remove \'required: true\' -- the '
                  'formula supplies the value.'
            : 'declares a source and is also marked required. A query-backed '
                  "field is populated on read from another workflow's rows, "
                  'so requiring it makes instance creation fail with "Required '
                  'field is missing or null". Remove \'required: true\' -- the '
                  'query supplies the value.';
        findings.add(
          _finding(
            'computed_field_cannot_be_required',
            "Field '${fieldEntry.key}' in workflow '${workflowEntry.key}' "
                '$remediation',
            'experience/workflowDefinitions/${workflowEntry.key}/'
                'instanceDataSchema/${fieldEntry.key}/required',
          ),
        );
      }
    }
    return findings;
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

  Set<String> _roleIds(dynamic raw) {
    if (raw is! List) return {};
    return raw
        .whereType<Object>()
        .map(
          (p) => p is String
              ? p
              : p is Map
              ? p['roleId'] as String?
              : null,
        )
        .whereType<String>()
        .toSet();
  }

  String? _seedCreator(Map<String, dynamic> instance) {
    final value = instance['createdByFanId'];
    if (value is String && value.trim().isNotEmpty) return value;
    return null;
  }

  List<ValidationFinding> _validateTabPermissionDeclarations(
    Map<String, dynamic> package,
  ) {
    final findings = <ValidationFinding>[];

    void validateTab(Object? rawTab, String path) {
      if (rawTab is! Map) return;
      for (final key in const ['requiredPermission', 'permission']) {
        if (!rawTab.containsKey(key)) continue;
        findings.add(
          _finding(
            'tab_declares_permission',
            'Tabs are surfaces, not capabilities, so a tab cannot grant or '
                'require a permission. permissions.md §1 defines permissions '
                'solely from role/action statements and says community JSON '
                'never contains a permission. Remove "$key"; tab visibility '
                'is derived from the role guards on workflows bound to the '
                'tab, so there is nothing to replace. See '
                'docs/references/reference/render-bindings.md, "Tab visibility '
                'is derived, never declared".',
            '$path/$key',
          ),
        );
      }
    }

    void validateAppShell(Object? rawAppShell, String path) {
      if (rawAppShell is! Map) return;

      final tabs = rawAppShell['tabs'];
      if (tabs is List) {
        for (var i = 0; i < tabs.length; i++) {
          validateTab(tabs[i], '$path/tabs[$i]');
        }
      }

      final roleTabs = rawAppShell['roleTabs'];
      if (roleTabs is! Map) return;
      for (final entry in roleTabs.entries) {
        final tabsForRole = entry.value;
        if (tabsForRole is! List) continue;
        for (var i = 0; i < tabsForRole.length; i++) {
          validateTab(tabsForRole[i], '$path/roleTabs/${entry.key}[$i]');
        }
      }
    }

    validateAppShell(package['appShell'], 'appShell');
    validateAppShell(package['appShellCustomization'], 'appShellCustomization');
    final extension = package['extension'];
    if (extension is Map) {
      validateAppShell(extension['appShell'], 'extension/appShell');
    }

    return findings;
  }

  Set<String> _declaredTabIds(Map<String, dynamic> package) {
    final appShell =
        _objectMap(package['appShell']) ??
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

    final roleTabs = _objectMap(appShell['roleTabs']);
    if (roleTabs == null) return declared;

    for (final rawRoleTabs in roleTabs.values) {
      if (rawRoleTabs is! List) continue;
      for (final rawTab in rawRoleTabs) {
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

  /// Reports keys that the workflow parser would otherwise ignore.
  ///
  /// The legal sets live on the parser-side model classes, beside their
  /// `fromJson` factories. Dynamic maps whose keys are authored data rather
  /// than grammar (`fields`, `filter`, `prefill`, and action inputs) are
  /// deliberately not traversed.
  List<ValidationFinding> _validateUnknownWorkflowKeys(
    Map<Object?, Object?> rawDefinitions,
  ) {
    const resolver = ArchetypeResolver();
    final findings = <ValidationFinding>[];
    final definitions = <String, Object?>{
      for (final entry in rawDefinitions.entries)
        entry.key.toString(): entry.value,
    };
    final archetypes = resolver.resolveAll(definitions);

    for (final entry in definitions.entries) {
      final workflow = entry.value;
      if (workflow is! Map) continue;
      final workflowPath = 'experience/workflowDefinitions/${entry.key}';
      _addUnknownKeyFindings(
        workflow,
        legalKeys: LoomWorkflowStateMachine.jsonKeys,
        position: 'workflow definition',
        path: workflowPath,
        findings: findings,
      );

      final visibility = workflow['visibility'];
      if (visibility is Map) {
        final visibilityPath = '$workflowPath/visibility';
        _addUnknownKeyFindings(
          visibility,
          legalKeys: WorkflowVisibility.jsonKeys,
          position: 'visibility',
          path: visibilityPath,
          findings: findings,
          keyExplanation: (key) {
            if (WorkflowVisibilityDefault.values.any(
              (value) => value.name == key,
            )) {
              return '`$key` is a `visibility.default` value, not a key.';
            }
            return null;
          },
        );
        _validateGuardUnknownKeys(
          visibility['readGuard'],
          '$visibilityPath/readGuard',
          findings,
        );

        final fields = visibility['fields'];
        if (fields is Map) {
          final model = ArchetypeResolver
              .contracts[archetypes[entry.key]?.family]
              ?.visibility;
          final requiredKey = switch (model) {
            VisibilityModel.ownerAndShared => 'sharedWith',
            VisibilityModel.participants => 'participants',
            VisibilityModel.parties => 'parties',
            VisibilityModel.roles ||
            VisibilityModel.owner ||
            VisibilityModel.recipient ||
            null => null,
          };
          _addUnknownKeyFindings(
            fields,
            legalKeys: WorkflowVisibilityFields.jsonKeys,
            position: 'visibility.fields',
            path: '$visibilityPath/fields',
            findings: findings,
            keyExplanation: (key) {
              final explanations = <String>[];
              if (VisibilityModel.values.any(
                (value) => _visibilityModelJsonValue(value) == key,
              )) {
                explanations.add(
                  '`$key` is a visibility model value, not a '
                  '`visibility.fields` key.',
                );
              }
              if (requiredKey != null) {
                explanations.add(
                  "This workflow's archetype requires the `$requiredKey` key "
                  'for its visibility model.',
                );
              }
              return explanations.isEmpty ? null : explanations.join(' ');
            },
          );
        }
      }

      final states = workflow['states'];
      if (states is Map) {
        for (final stateEntry in states.entries) {
          final state = stateEntry.value;
          if (state is! Map) continue;
          final statePath = '$workflowPath/states/${stateEntry.key}';
          _addUnknownKeyFindings(
            state,
            legalKeys: LoomWorkflowState.jsonKeys,
            position: 'state',
            path: statePath,
            findings: findings,
          );
          for (final guardKey in const [
            'editGuard',
            'creationGuard',
            'readGuard',
          ]) {
            _validateGuardUnknownKeys(
              state[guardKey],
              '$statePath/$guardKey',
              findings,
            );
          }
        }
      }

      final transitions = workflow['transitions'];
      if (transitions is List) {
        for (var i = 0; i < transitions.length; i++) {
          final transition = transitions[i];
          if (transition is! Map) continue;
          final transitionPath = '$workflowPath/transitions[$i]';
          _addUnknownKeyFindings(
            transition,
            legalKeys: LoomWorkflowTransition.jsonKeys,
            position: 'transition',
            path: transitionPath,
            findings: findings,
          );
          _validateGuardUnknownKeys(
            transition['guard'],
            '$transitionPath/guard',
            findings,
          );

          final inputs = transition['inputs'];
          if (inputs is Map) {
            for (final inputEntry in inputs.entries) {
              final input = inputEntry.value;
              if (input is! Map) continue;
              _addUnknownKeyFindings(
                input,
                legalKeys: TransitionInputSpec.jsonKeys,
                position: 'transition input',
                path: '$transitionPath/inputs/${inputEntry.key}',
                findings: findings,
              );
            }
          }
          _validateEffectListUnknownKeys(
            transition['effects'],
            '$transitionPath/effects',
            findings,
          );
        }
      }

      final renderBindings = workflow['renderBindings'];
      if (renderBindings is List) {
        for (var i = 0; i < renderBindings.length; i++) {
          final binding = renderBindings[i];
          if (binding is! Map) continue;
          final bindingPath = '$workflowPath/renderBindings[$i]';
          _addUnknownKeyFindings(
            binding,
            legalKeys: RenderBinding.jsonKeys,
            position: 'render binding',
            path: bindingPath,
            findings: findings,
            keyExplanation: (key) =>
                RenderBinding.bindingKindValues.contains(key)
                ? '`$key` is a `bindingKind` value, not a render-binding key.'
                : null,
          );

          final actions = binding['actions'];
          if (actions is List) {
            for (
              var actionIndex = 0;
              actionIndex < actions.length;
              actionIndex++
            ) {
              final action = actions[actionIndex];
              if (action is! Map) continue;
              _addUnknownKeyFindings(
                action,
                legalKeys: WorkflowAction.jsonKeys,
                position: 'render-binding action',
                path: '$bindingPath/actions[$actionIndex]',
                findings: findings,
              );
            }
          }

          final responseTable = binding['responseTable'];
          if (responseTable is Map) {
            _addUnknownKeyFindings(
              responseTable,
              legalKeys: ResponseTableSpec.jsonKeys,
              position: 'responseTable',
              path: '$bindingPath/responseTable',
              findings: findings,
            );
          }

          final repeater = binding['repeater'];
          if (repeater is Map) {
            final repeaterPath = '$bindingPath/repeater';
            _addUnknownKeyFindings(
              repeater,
              legalKeys: RepeaterSpec.jsonKeys,
              position: 'repeater',
              path: repeaterPath,
              findings: findings,
            );
            final itemActions = repeater['itemActions'];
            if (itemActions is List) {
              for (
                var actionIndex = 0;
                actionIndex < itemActions.length;
                actionIndex++
              ) {
                final action = itemActions[actionIndex];
                if (action is! Map) continue;
                _addUnknownKeyFindings(
                  action,
                  legalKeys: RepeaterItemAction.jsonKeys,
                  position: 'repeater item action',
                  path: '$repeaterPath/itemActions[$actionIndex]',
                  findings: findings,
                );
              }
            }
          }

          final facets = binding['filterableFacets'];
          if (facets is List) {
            for (var facetIndex = 0; facetIndex < facets.length; facetIndex++) {
              final facet = facets[facetIndex];
              if (facet is! Map) continue;
              _addUnknownKeyFindings(
                facet,
                legalKeys: FilterableFacetSpec.jsonKeys,
                position: 'filterable facet',
                path: '$bindingPath/filterableFacets[$facetIndex]',
                findings: findings,
              );
            }
          }
        }
      }

      final schema = workflow['instanceDataSchema'];
      if (schema is Map) {
        for (final fieldEntry in schema.entries) {
          _validateInstanceDataFieldUnknownKeys(
            fieldEntry.value,
            '$workflowPath/instanceDataSchema/${fieldEntry.key}',
            findings,
          );
        }
      }
    }
    return findings;
  }

  void _validateGuardUnknownKeys(
    Object? rawGuard,
    String path,
    List<ValidationFinding> findings,
  ) {
    if (rawGuard is! Map) return;
    _addUnknownKeyFindings(
      rawGuard,
      legalKeys: WorkflowGuard.jsonKeys,
      position: 'guard',
      path: path,
      findings: findings,
    );

    void checkNested(String key, Set<String> legalKeys, String position) {
      final value = rawGuard[key];
      if (value is! Map) return;
      _addUnknownKeyFindings(
        value,
        legalKeys: legalKeys,
        position: position,
        path: '$path/$key',
        findings: findings,
      );
    }

    checkNested(
      'actorInList',
      ListMembershipGuard.jsonKeys,
      'actorInList guard',
    );
    checkNested(
      'actorEqualsField',
      ActorEqualsFieldGuard.jsonKeys,
      'actorEqualsField guard',
    );
    checkNested(
      'instanceDataEquals',
      KeyValueGuard.jsonKeys,
      'instanceDataEquals guard',
    );
    checkNested(
      'cancellationDeadline',
      CancellationDeadlineGuard.jsonKeys,
      'cancellationDeadline guard',
    );
    checkNested(
      'locationOverlap',
      LocationOverlapGuard.jsonKeys,
      'locationOverlap guard',
    );

    final relatedAggregate = rawGuard['relatedAggregate'];
    if (relatedAggregate is Map) {
      final aggregatePath = '$path/relatedAggregate';
      _addUnknownKeyFindings(
        relatedAggregate,
        legalKeys: RelatedAggregateGuard.jsonKeys,
        position: 'relatedAggregate guard',
        path: aggregatePath,
        findings: findings,
      );
      final compareTo = relatedAggregate['compareTo'];
      if (compareTo is Map) {
        _addUnknownKeyFindings(
          compareTo,
          legalKeys: RelatedAggregateGuard.compareToJsonKeys,
          position: 'relatedAggregate compareTo reference',
          path: '$aggregatePath/compareTo',
          findings: findings,
        );
      }
    }
  }

  void _validateEffectListUnknownKeys(
    Object? rawEffects,
    String path,
    List<ValidationFinding> findings,
  ) {
    if (rawEffects is! List) return;
    for (var i = 0; i < rawEffects.length; i++) {
      final effect = rawEffects[i];
      if (effect is! Map) continue;
      final effectPath = '$path[$i]';
      _addUnknownKeyFindings(
        effect,
        legalKeys: WorkflowEffect.jsonKeys,
        position: 'effect',
        path: effectPath,
        findings: findings,
      );

      final relatedQuery = effect['relatedQuery'];
      if (relatedQuery is Map) {
        _addUnknownKeyFindings(
          relatedQuery,
          legalKeys: RelatedTransitionQuery.jsonKeys,
          position: 'related transition query',
          path: '$effectPath/relatedQuery',
          findings: findings,
        );
      }

      final recurrenceRule = effect['recurrenceRule'];
      if (recurrenceRule is Map) {
        _addUnknownKeyFindings(
          recurrenceRule,
          legalKeys: RecurrenceRule.jsonKeys,
          position: 'recurrence rule',
          path: '$effectPath/recurrenceRule',
          findings: findings,
        );
      }

      for (final branchKey in const ['then', 'else', 'onSuccessEffects']) {
        _validateEffectListUnknownKeys(
          effect[branchKey],
          '$effectPath/$branchKey',
          findings,
        );
      }
    }
  }

  void _validateInstanceDataFieldUnknownKeys(
    Object? rawField,
    String path,
    List<ValidationFinding> findings,
  ) {
    if (rawField is! Map) return;
    _addUnknownKeyFindings(
      rawField,
      legalKeys: InstanceDataField.jsonKeys,
      position: 'instance-data field schema',
      path: path,
      findings: findings,
    );
    final itemSchema = rawField['itemSchema'];
    if (itemSchema is! Map) return;
    for (final itemEntry in itemSchema.entries) {
      _validateInstanceDataFieldUnknownKeys(
        itemEntry.value,
        '$path/itemSchema/${itemEntry.key}',
        findings,
      );
    }
  }

  void _addUnknownKeyFindings(
    Map<Object?, Object?> object, {
    required Set<String> legalKeys,
    required String position,
    required String path,
    required List<ValidationFinding> findings,
    String? Function(String key)? keyExplanation,
  }) {
    final legalList = legalKeys.map((key) => '`$key`').join(', ');
    for (final rawKey in object.keys) {
      final key = rawKey.toString();
      if (rawKey is String && legalKeys.contains(key)) continue;
      final explanation = keyExplanation?.call(key);
      findings.add(
        _finding(
          'unknown_key',
          'Unknown key `$key` in $position. The parser ignores it. '
              'Legal keys for this position: $legalList.'
              '${explanation == null ? '' : ' $explanation'}',
          '$path/$key',
        ),
      );
    }
  }

  String _visibilityModelJsonValue(VisibilityModel model) => switch (model) {
    VisibilityModel.ownerAndShared => 'owner_and_shared',
    _ => model.name,
  };

  /// identity-types.md — the `roleId` / `fanId` split, enforced from
  /// specVersion 4.
  ///
  /// Comparing `$viewer` to a declared role is a type error rather than a
  /// silent false.
  List<ValidationFinding> _validateIdentityKeys(
    Map<String, dynamic> package,
    Map<String, dynamic> experience,
  ) {
    final findings = <ValidationFinding>[];

    // Renamed keys. Their continued presence means a package was hand-edited
    // to the new version without being regenerated.
    const renamed = {
      'allowedPer'
              'sonaIds':
          'allowedRoleIds',
      'byPer'
              'sonaIds':
          'byRoleIds',
      'visiblePer'
              'sonaIds':
          'visibleRoleIds',
      'per'
              'sonaTabs':
          'roleTabs',
      'per'
              'sonas':
          'roles',
      'createdByPer'
              'sonaId':
          'createdByFanId',
    };
    String? replacementFor(String key) {
      final accessControlReplacement = renamed[key];
      if (accessControlReplacement != null) return accessControlReplacement;
      if (key ==
          'per'
              'sonaId')
        return 'fanId';
      if (key.endsWith(
        'Per'
        'sonaIds',
      )) {
        return '${key.substring(0, key.length - ('Per'
                'sonaIds').length)}FanIds';
      }
      if (key.endsWith(
        'Per'
        'sonaId',
      )) {
        return '${key.substring(0, key.length - ('Per'
                'sonaId').length)}FanId';
      }
      return null;
    }

    void walk(Object? node, String path) {
      if (node is Map) {
        for (final entry in node.entries) {
          final key = entry.key.toString();
          final replacement = replacementFor(key);
          if (replacement != null) {
            findings.add(
              _finding(
                'legacy_identity_key',
                'specVersion 4 renamed "$key" to "$replacement". '
                    'See docs/references/reference/identity-types.md.',
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
          if (key == 'type' &&
              entry.value is String &&
              (entry.value ==
                      'per'
                          'sonaId' ||
                  (entry.value as String).startsWith(
                    'per'
                    'sonaId[',
                  ) ||
                  (entry.value as String).startsWith(
                    'per'
                    'sonaId?',
                  ))) {
            findings.add(
              _finding(
                'legacy_identity_type',
                'Pre-specVersion-4 identity type "${entry.value}" is '
                    'unsupported. Use the corresponding fanId type in a '
                    'specVersion: $currentCommunitySpecVersion package. See '
                    'docs/references/reference/identity-types.md.',
                '$path/type',
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
        VisibilityModel.recipient ||
        null => null,
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
      final schemaFields = schema is Map ? schema : const <Object?, Object?>{};
      final declaredFields = schemaFields.keys
          .map((key) => key.toString())
          .toSet();

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

      void checkFieldType(
        Object? value,
        String visibilityKey,
        Set<String> requiredTypes,
        String requiredTypeDescription,
        String location,
      ) {
        if (value is! String || !declaredFields.contains(value)) return;
        final declaration = schemaFields[value];
        final declaredType = declaration is Map ? declaration['type'] : null;
        if (declaredType is String && requiredTypes.contains(declaredType)) {
          return;
        }
        findings.add(
          _finding(
            'invalid_visibility_field_type',
            '`visibility.fields.$visibilityKey` names field `$value`, whose '
                'declared type is `${declaredType ?? '<missing>'}`; the '
                'required type is $requiredTypeDescription.',
            location,
          ),
        );
      }

      checkField(fields['sharedWith'], '$path/sharedWith');
      checkFieldType(
        fields['sharedWith'],
        'sharedWith',
        const {'fanId[]'},
        '`fanId[]`',
        '$path/sharedWith',
      );
      final participants = fields['participants'];
      if (participants is List) {
        for (var i = 0; i < participants.length; i++) {
          checkField(participants[i], '$path/participants[$i]');
          checkFieldType(
            participants[i],
            'participants',
            const {'fanId', 'fanId[]'},
            '`fanId` or `fanId[]`',
            '$path/participants[$i]',
          );
        }
      }
      checkField(fields['recipient'], '$path/recipient');
      checkFieldType(
        fields['recipient'],
        'recipient',
        const {'fanId'},
        '`fanId`',
        '$path/recipient',
      );

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
            checkFieldType(
              principal,
              'parties',
              const {'fanId'},
              '`fanId`',
              location,
            );
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

          final overlap = sourcesOf(
            a,
          ).toSet().intersection(sourcesOf(b).toSet());
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
  /// visibility into its parent's.
  ///
  /// **Severity is a ratchet (D3, approved 2026-08-14): error after Phase F.**
  /// Phase F regenerated all 11 fixtures through the Skill, and the corpus was
  /// confirmed clean on 2026-08-20. Keeping this as an error prevents a
  /// shipped community from reintroducing orphaned response rows.
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
        final terminal =
            (to is String &&
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
                warning: false,
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
                warning: false,
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
  List<ValidationFinding> _validateTransitionActions(
    Map<Object?, Object?> raw,
  ) {
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
          final via =
              archetype.origin == ArchetypeOrigin.inheritedFromResponseTable
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

  /// Where a `documentLibrary` workflow's document content comes from.
  ///
  /// Ported here from the workflow service's install-time validator, which was
  /// the wrong home for it. This is the validator the Skill runs while
  /// authoring; an author who only learns at install time that their upload
  /// action publishes a link has already shipped the package.
  ///
  /// A library holds stored documents or links to documents hosted elsewhere.
  /// Both are legitimate — four of the five shipped libraries are deliberately
  /// link libraries — so only the incoherent case is an error.
  List<ValidationFinding> _validateDocumentContentSource(
    Map<Object?, Object?> rawDefinitions,
  ) {
    final findings = <ValidationFinding>[];
    for (final entry in rawDefinitions.entries) {
      final workflow = entry.value;
      if (workflow is! Map) continue;
      final workflowType = '${entry.key}';

      final bindings = workflow['renderBindings'];
      if (bindings is! List) continue;
      final isDocumentLibrary = bindings.any(
        (binding) =>
            binding is Map && binding['cardSurfaceFamily'] == 'documentLibrary',
      );
      if (!isDocumentLibrary) continue;

      // The content field is the one a link library lets a member type into.
      // Matched on its declared type, never on its name: `documentUrl` is what
      // Cedar happens to call it, and reading meaning from an identifier's
      // spelling is a mistake this repo has made before.
      final schema = workflow['instanceDataSchema'];
      final linkFields = <String>{};
      if (schema is Map) {
        for (final field in schema.entries) {
          final declared = field.value;
          if (declared is Map && declared['type'] == 'url') {
            linkFields.add('${field.key}');
          }
        }
      }

      final transitions = workflow['transitions'];
      if (transitions is! List) continue;

      var declaresUpload = false;
      for (final transition in transitions) {
        if (transition is! Map) continue;
        if (transition['action'] != 'upload') continue;
        declaresUpload = true;

        final memberSupplied = <String>[];
        final effects = transition['effects'];
        if (effects is List) {
          for (final effect in effects) {
            if (effect is! Map || effect['op'] != 'set') continue;
            final key = '${effect['key']}';
            if (!linkFields.contains(key)) continue;
            final value = effect['value'];
            if (value is String && value.contains('{input.')) {
              memberSupplied.add(key);
            }
          }
        }
        if (memberSupplied.isEmpty) continue;

        final transitionId = transition['id'] ?? '<unknown>';
        final fieldList = memberSupplied.join(', ');
        findings.add(
          _finding(
            'document_upload_stores_no_content',
            'Transition "$transitionId" in workflow "$workflowType" declares '
                'the "upload" action but sets $fieldList from a '
                'member-supplied input, so it publishes a link rather than '
                'storing a document. Declaring "upload" also grants permission '
                'to store files through the Document Library API, so this '
                'hands out file-storage authority for a paste. For a stored '
                'library, drop the input and let the API write the field; for '
                'a link library, use "edit" or a community-defined transition.',
            'experience/workflowDefinitions/$workflowType/transitions',
          ),
        );
      }

      if (!declaresUpload && linkFields.isNotEmpty) {
        final fieldList = linkFields.join(', ');
        findings.add(
          _finding(
            'document_library_is_link_only',
            'Workflow "$workflowType" holds links rather than stored '
                'documents: its content lives in $fieldList and no transition '
                'declares the "upload" action, so nothing can be stored '
                'through the Document Library API. This is correct for a '
                'library of external resources — say so in Gaps/assumptions '
                'naming this finding. Only add an "upload" transition if the '
                'product doc says members add files.',
            'experience/workflowDefinitions/$workflowType',
            warning: true,
          ),
        );
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

  List<ValidationFinding> _validateSupportedCapabilities(
    Map<String, dynamic> package,
  ) {
    if (!package.containsKey('requiresCapabilities')) return const [];
    final declarations = package['requiresCapabilities'];
    if (declarations is! List) {
      return [
        _finding(
          'unsupported_capability',
          'requiresCapabilities must be an array of implemented, '
              'namespaced capability names; found "$declarations".',
          'requiresCapabilities',
        ),
      ];
    }

    final findings = <ValidationFinding>[];
    for (var i = 0; i < declarations.length; i++) {
      final declaration = declarations[i];
      if (declaration is String && supportsCommunityCapability(declaration)) {
        continue;
      }
      findings.add(
        _finding(
          'unsupported_capability',
          'This build does not implement or recognise capability '
              '"$declaration".',
          'requiresCapabilities[$i]',
        ),
      );
    }
    return findings;
  }

  List<ValidationFinding> _validateUnusedCapabilities(
    Map<String, dynamic> package,
    Set<String> used,
  ) {
    final declarations = package['requiresCapabilities'];
    if (declarations is! List) return const [];
    final findings = <ValidationFinding>[];
    for (var i = 0; i < declarations.length; i++) {
      final declaration = declarations[i];
      if (declaration is! String) continue;
      final isBaseline = _capabilityBaseline.contains(declaration);
      if (!isBaseline && used.contains(declaration)) continue;
      findings.add(
        _finding(
          'unused_capability',
          isBaseline
              ? 'Capability "$declaration" is implied by specVersion: '
                    '$currentCommunitySpecVersion and must not be declared.'
              : 'Package declares capability "$declaration" but never uses it.',
          'requiresCapabilities[$i]',
        ),
      );
    }
    return findings;
  }

  List<ValidationFinding> _validateUndeclaredCapabilities(
    Map<String, dynamic> package,
    Set<String> used,
  ) {
    final declarations = package['requiresCapabilities'];
    final declared = declarations is List
        ? declarations.whereType<String>().toSet()
        : const <String>{};
    final undeclared =
        used
            .where(supportsCommunityCapability)
            .where(
              (capability) =>
                  !_capabilityBaseline.contains(capability) &&
                  !declared.contains(capability),
            )
            .toList()
          ..sort();

    return <ValidationFinding>[
      for (final capability in undeclared)
        _finding(
          'undeclared_capability',
          'Package uses post-baseline capability "$capability" but does not '
              'declare it in requiresCapabilities.',
          'requiresCapabilities',
        ),
    ];
  }

  Set<String> _usedCapabilities(
    Map<String, dynamic> package,
    Map<String, LoomWorkflowStateMachine> workflows,
  ) {
    final used = <String>{};
    _collectRawFormulaCapabilities(package, used);
    for (final machine in workflows.values) {
      for (final binding in machine.renderBindings) {
        used.add('archetype.${binding.cardSurfaceFamily}');
      }
      for (final field in machine.instanceDataSchema.values) {
        _collectFieldCapabilities(field, used);
      }
      _collectGuardCapabilities(machine.visibility.readGuard, used);
      for (final state in machine.states.values) {
        _collectGuardCapabilities(state.editGuard, used);
        _collectGuardCapabilities(state.creationGuard, used);
        _collectGuardCapabilities(state.readGuard, used);
      }
      for (final transition in machine.transitions) {
        _collectGuardCapabilities(transition.guard, used);
        final inputs = transition.inputs;
        if (inputs != null) {
          for (final input in inputs.values) {
            _collectFormulaCapabilities(input.visibleWhen, used);
          }
        }
        for (final effect in transition.effects) {
          _collectEffectCapabilities(effect, used);
        }
      }
    }
    return used;
  }

  void _collectRawFormulaCapabilities(Object? node, Set<String> used) {
    if (node is List) {
      for (final value in node) {
        _collectRawFormulaCapabilities(value, used);
      }
      return;
    }
    if (node is! Map) return;
    for (final entry in node.entries) {
      if (const <String>{
            'formula',
            'visibleWhen',
            'visibleWhenEditing',
            'if',
          }.contains(entry.key) &&
          entry.value is String) {
        _collectFormulaCapabilities(entry.value as String, used);
      }
      _collectRawFormulaCapabilities(entry.value, used);
    }
  }

  void _collectFieldCapabilities(InstanceDataField field, Set<String> used) {
    final type = field.type.endsWith('?')
        ? field.type.substring(0, field.type.length - 1)
        : field.type;
    used.add('field.$type');
    _collectFormulaCapabilities(field.formula, used);
    _collectFormulaCapabilities(field.visibleWhenEditing, used);
    final itemSchema = field.itemSchema;
    if (itemSchema != null) {
      for (final nested in itemSchema.values) {
        _collectFieldCapabilities(nested, used);
      }
    }
  }

  void _collectGuardCapabilities(WorkflowGuard? guard, Set<String> used) {
    if (guard == null) return;
    if (guard.allowedRoleIds != null) used.add('guard.allowedRoleIds');
    if (guard.actorInList != null) used.add('guard.actorInList');
    if (guard.instanceDataEquals != null) {
      used.add('guard.instanceDataEquals');
    }
    if (guard.formula != null) used.add('guard.formula');
    if (guard.relatedListMembership != null) {
      used.add('guard.relatedListMembership');
    }
    if (guard.relatedAggregate != null) used.add('guard.relatedAggregate');
    if (guard.requiresWorkflowsComplete != null) {
      used.add('guard.requiresWorkflowsComplete');
    }
    if (guard.cancellationDeadline != null) {
      used.add('guard.cancellationDeadline');
    }
    if (guard.locationOverlap != null) used.add('guard.locationOverlap');
    if (guard.actorEqualsField != null) used.add('guard.actorEqualsField');
    _collectFormulaCapabilities(guard.formula, used);
  }

  void _collectEffectCapabilities(WorkflowEffect effect, Set<String> used) {
    used.add('effect.${effect.op}');
    _collectFormulaCapabilities(effect.condition, used);
    for (final nested in <WorkflowEffect>[
      ...effect.thenEffects,
      ...effect.elseEffects,
      ...?effect.onSuccessEffects,
    ]) {
      _collectEffectCapabilities(nested, used);
    }
  }

  void _collectFormulaCapabilities(String? formula, Set<String> used) {
    if (formula == null) return;
    try {
      for (final function in analyzeFormula(formula).functionNames) {
        used.add('formula.$function');
      }
    } on FormulaEvaluationException {
      // Formula syntax has its own validator finding. An invalid expression
      // cannot establish that a declared capability is actually used.
    }
  }
}
