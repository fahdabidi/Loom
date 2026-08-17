import 'package:loom_workflow_engine/loom_workflow_engine.dart';

import 'package_parser.dart';

typedef JsonMap = Map<String, Object?>;

/// Deterministic output of the community-to-remote derivation.
class CommunityMigrationPlan {
  const CommunityMigrationPlan({
    required this.installCommunityPackagePayload,
    required this.replaceWorkflowDefinitionsPayload,
    required this.guardAudits,
    required this.createActionAudits,
  });

  final JsonMap installCommunityPackagePayload;
  final JsonMap replaceWorkflowDefinitionsPayload;
  final List<RoleTranslationAudit> guardAudits;
  final List<RoleTranslationAudit> createActionAudits;

  List<RoleTranslationFinding> get findings => List.unmodifiable([
    for (final audit in guardAudits)
      if (audit.finding case final finding?) finding,
    for (final audit in createActionAudits)
      if (audit.finding case final finding?) finding,
  ]);

  int get cleanGuardCount => guardAudits.where((audit) => audit.isClean).length;
  int get flaggedGuardCount => guardAudits.length - cleanGuardCount;
  int get cleanCreateActionCount =>
      createActionAudits.where((audit) => audit.isClean).length;
  int get flaggedCreateActionCount =>
      createActionAudits.length - cleanCreateActionCount;

  JsonMap findingsReport({required int networkCallsMade}) => {
    'summary': {
      'guardsTranslatedCleanly': cleanGuardCount,
      'guardsFlagged': flaggedGuardCount,
      'createActionsTranslatedCleanly': cleanCreateActionCount,
      'createActionsFlagged': flaggedCreateActionCount,
      'networkCallsMade': networkCallsMade,
    },
    'findings': [for (final finding in findings) finding.toJson()],
  };
}

class CommunityMigrationDeriver {
  const CommunityMigrationDeriver({
    this.archetypeResolver = const ArchetypeResolver(),
  });

  final ArchetypeResolver archetypeResolver;

  CommunityMigrationPlan derive(ParsedCommunityPackage package) {
    final translator = PersonaRoleTranslator(package.personas);
    final guardAudits = <RoleTranslationAudit>[];
    final guardAuditsByLocation = <String, RoleTranslationAudit>{};
    _auditLegacyGuards(
      package.root,
      r'$',
      translator,
      guardAudits,
      guardAuditsByLocation,
    );
    final translatedWorkflowDefinitions =
        _translateLegacyGuardsForRemoteDefinitions(
              package.rawWorkflowDefinitions,
              r'$.experience.workflowDefinitions',
              guardAuditsByLocation,
            )
            as Map<String, Object?>;

    final resolvedArchetypes = archetypeResolver.resolveAll(
      package.rawWorkflowDefinitions,
    );
    final createActionAudits = <RoleTranslationAudit>[];
    final workflows = <JsonMap>[];

    for (final entry in package.workflowDefinitions.entries) {
      final workflowType = entry.key;
      final definition = entry.value;
      final rawDefinition = package.rawWorkflowDefinitions[workflowType] as Map;
      final rawTransitions = rawDefinition['transitions'] as List;

      final transitions = <JsonMap>[];
      for (var index = 0; index < definition.transitions.length; index++) {
        final transition = definition.transitions[index];
        final rawTransition = Map<String, dynamic>.from(
          rawTransitions[index] as Map,
        );
        if (rawTransition['id'] != transition.id) {
          throw StateError(
            'Parsed transition order drifted for $workflowType at index $index.',
          );
        }
        final transitionPath = _listItemPath(
          r'$.experience.workflowDefinitions.'
          '$workflowType.transitions',
          index,
          rawTransition,
        );
        final derived = <String, Object?>{
          'transitionId': transition.id,
          'action': transition.action,
          'tone': transition.tone,
          'isTerminal':
              transition.to != null &&
              (definition.states[transition.to]?.isTerminal ?? false),
        };

        final rawGuard = rawTransition['guard'];
        if (rawGuard is Map && rawGuard.containsKey('allowedPersonaIds')) {
          final location = '$transitionPath.guard.allowedPersonaIds';
          final audit = guardAuditsByLocation[location];
          if (audit == null) {
            throw StateError('Missing guard audit for $location.');
          }
          if (audit.roleIds case final roleIds?) {
            derived['allowedRoleIds'] = roleIds;
          }
        } else if (rawGuard is Map && rawGuard.containsKey('allowedRoleIds')) {
          derived['allowedRoleIds'] = _stringList(
            rawGuard['allowedRoleIds'],
            '$transitionPath.guard.allowedRoleIds',
          );
        } else {
          // App Access explicitly defines an empty list as an instance-gated
          // transition that derives no role grant.
          derived['allowedRoleIds'] = const <String>[];
        }
        transitions.add(derived);
      }

      final createRoleIds = <String>{};
      for (
        var bindingIndex = 0;
        bindingIndex < definition.renderBindings.length;
        bindingIndex++
      ) {
        final binding = definition.renderBindings[bindingIndex];
        for (
          var actionIndex = 0;
          actionIndex < binding.actions.length;
          actionIndex++
        ) {
          final action = binding.actions[actionIndex];
          if (action.kind != 'create') continue;
          final personaIds = action.byPersonaIds;
          if (personaIds == null || personaIds.isEmpty) continue;
          final location =
              r'$.experience.workflowDefinitions.'
              '$workflowType.renderBindings[$bindingIndex].actions'
              '[$actionIndex].byPersonaIds';
          final audit = translator.translate(
            personaIds,
            location: location,
            source: RoleTranslationSource.createAction,
          );
          createActionAudits.add(audit);
          if (audit.roleIds case final roleIds?) {
            createRoleIds.addAll(roleIds);
          }
        }
      }

      workflows.add({
        'workflowType': workflowType,
        'cardSurfaceFamily': resolvedArchetypes[workflowType]?.family,
        'transitions': transitions,
        'createRoleIds': createRoleIds.toList()..sort(),
      });
    }

    return CommunityMigrationPlan(
      installCommunityPackagePayload: {
        'communityHandle': package.communityHandle,
        'displayName': package.displayName,
        'grammarVersion': package.workflowGrammarVersion,
        'roles': translator.roles,
        'workflows': workflows,
      },
      replaceWorkflowDefinitionsPayload: {
        'specVersion': 4,
        'definitions': translatedWorkflowDefinitions,
      },
      guardAudits: List.unmodifiable(guardAudits),
      createActionAudits: List.unmodifiable(createActionAudits),
    );
  }
}

enum RoleTranslationSource { guard, createAction }

class RoleTranslationAudit {
  const RoleTranslationAudit._({
    required this.location,
    required this.source,
    required this.personaIds,
    required this.roleLabels,
    this.roleIds,
    this.finding,
  });

  final String location;
  final RoleTranslationSource source;
  final List<String> personaIds;
  final List<String> roleLabels;
  final List<String>? roleIds;
  final RoleTranslationFinding? finding;

  bool get isClean => roleIds != null;
}

class RoleTranslationFinding {
  const RoleTranslationFinding({
    required this.code,
    required this.location,
    required this.source,
    required this.personaIds,
    required this.roleLabels,
    required this.message,
  });

  final String code;
  final String location;
  final RoleTranslationSource source;
  final List<String> personaIds;
  final List<String> roleLabels;
  final String message;

  JsonMap toJson() => {
    'code': code,
    'location': location,
    'source': source.name,
    'personaIds': personaIds,
    'roleLabels': roleLabels,
    'message': message,
  };
}

/// Converts legacy individually-named personas into stable package role ids.
///
/// A role label is slugged by trimming it, lowercasing ASCII, replacing every
/// run of non `[a-z0-9]` characters with `-`, and trimming leading/trailing
/// hyphens. Slug collisions fail parsing instead of merging distinct roles.
class PersonaRoleTranslator {
  PersonaRoleTranslator(List<MigrationPersona> personas)
    : _personasById = _indexPersonas(personas),
      _personaIdsByRoleLabel = _indexRoleMembers(personas),
      _roleIdsByLabel = _indexRoleIds(personas) {
    final seenRoleIds = <String, String>{};
    for (final entry in _roleIdsByLabel.entries) {
      final previousLabel = seenRoleIds[entry.value];
      if (previousLabel != null && previousLabel != entry.key) {
        throw FormatException(
          'Role labels "$previousLabel" and "${entry.key}" both slug to '
          '"${entry.value}".',
        );
      }
      seenRoleIds[entry.value] = entry.key;
    }
  }

  final Map<String, MigrationPersona> _personasById;
  final Map<String, Set<String>> _personaIdsByRoleLabel;
  final Map<String, String> _roleIdsByLabel;

  List<JsonMap> get roles => [
    for (final entry in _roleIdsByLabel.entries)
      {'roleId': entry.value, 'label': entry.key},
  ];

  RoleTranslationAudit translate(
    Object? rawPersonaIds, {
    required String location,
    required RoleTranslationSource source,
  }) {
    if (rawPersonaIds is! List ||
        rawPersonaIds.any((value) => value is! String)) {
      return _failed(
        code: 'invalid_persona_list',
        location: location,
        source: source,
        personaIds: const [],
        roleLabels: const [],
        message: '$location must be a list of persona ids.',
      );
    }
    final personaIds = rawPersonaIds.cast<String>().toList();
    final uniquePersonaIds = personaIds.toSet();
    final unknown =
        uniquePersonaIds
            .where((personaId) => !_personasById.containsKey(personaId))
            .toList()
          ..sort();
    final roleLabels = <String>{
      for (final personaId in uniquePersonaIds)
        if (_personasById[personaId] case final persona?) persona.roleLabel,
    }.toList()..sort();

    if (unknown.isNotEmpty) {
      return _failed(
        code: 'unknown_persona_ids',
        location: location,
        source: source,
        personaIds: personaIds,
        roleLabels: roleLabels,
        message: '$location names undeclared personas: ${unknown.join(', ')}.',
      );
    }
    if (roleLabels.length > 1) {
      return _failed(
        code: 'mixed_role_labels',
        location: location,
        source: source,
        personaIds: personaIds,
        roleLabels: roleLabels,
        message:
            '$location mixes personas from role labels '
            '${roleLabels.join(', ')}; the target role-only grammar cannot '
            'express this per-persona rule without a human decision.',
      );
    }
    if (roleLabels.isEmpty) {
      return _failed(
        code: 'empty_persona_set',
        location: location,
        source: source,
        personaIds: personaIds,
        roleLabels: const [],
        message: '$location names no personas and cannot identify a role.',
      );
    }

    final roleLabel = roleLabels.single;
    final fullRoleSet = _personaIdsByRoleLabel[roleLabel]!;
    if (!_sameSet(uniquePersonaIds, fullRoleSet)) {
      final missing = fullRoleSet.difference(uniquePersonaIds).toList()..sort();
      return _failed(
        code: 'partial_role_persona_set',
        location: location,
        source: source,
        personaIds: personaIds,
        roleLabels: roleLabels,
        message:
            '$location names only part of role "$roleLabel"; missing '
            '${missing.join(', ')}. Widening it to the full role requires a '
            'human authorization decision.',
      );
    }

    return RoleTranslationAudit._(
      location: location,
      source: source,
      personaIds: List.unmodifiable(personaIds),
      roleLabels: List.unmodifiable(roleLabels),
      roleIds: List.unmodifiable([_roleIdsByLabel[roleLabel]!]),
    );
  }

  static String slugRoleLabel(String roleLabel) {
    final slug = roleLabel
        .trim()
        .toLowerCase()
        .replaceAll(RegExp('[^a-z0-9]+'), '-')
        .replaceAll(RegExp('^-+|-+\$'), '');
    if (slug.isEmpty) {
      throw FormatException('Role label "$roleLabel" has an empty slug.');
    }
    return slug;
  }

  static Map<String, MigrationPersona> _indexPersonas(
    List<MigrationPersona> personas,
  ) {
    final result = <String, MigrationPersona>{};
    for (final persona in personas) {
      if (result.containsKey(persona.personaId)) {
        throw FormatException('Duplicate personaId "${persona.personaId}".');
      }
      result[persona.personaId] = persona;
    }
    return Map.unmodifiable(result);
  }

  static Map<String, Set<String>> _indexRoleMembers(
    List<MigrationPersona> personas,
  ) {
    final result = <String, Set<String>>{};
    for (final persona in personas) {
      result
          .putIfAbsent(persona.roleLabel, () => <String>{})
          .add(persona.personaId);
    }
    return Map.unmodifiable({
      for (final entry in result.entries)
        entry.key: Set.unmodifiable(entry.value),
    });
  }

  static Map<String, String> _indexRoleIds(List<MigrationPersona> personas) {
    final result = <String, String>{};
    for (final persona in personas) {
      result.putIfAbsent(
        persona.roleLabel,
        () => slugRoleLabel(persona.roleLabel),
      );
    }
    return Map.unmodifiable(result);
  }

  RoleTranslationAudit _failed({
    required String code,
    required String location,
    required RoleTranslationSource source,
    required List<String> personaIds,
    required List<String> roleLabels,
    required String message,
  }) {
    final finding = RoleTranslationFinding(
      code: code,
      location: location,
      source: source,
      personaIds: List.unmodifiable(personaIds),
      roleLabels: List.unmodifiable(roleLabels),
      message: message,
    );
    return RoleTranslationAudit._(
      location: location,
      source: source,
      personaIds: finding.personaIds,
      roleLabels: finding.roleLabels,
      finding: finding,
    );
  }
}

void _auditLegacyGuards(
  Object? node,
  String path,
  PersonaRoleTranslator translator,
  List<RoleTranslationAudit> audits,
  Map<String, RoleTranslationAudit> auditsByLocation,
) {
  if (node is Map) {
    for (final entry in node.entries) {
      final key = entry.key.toString();
      final childPath = '$path.$key';
      if (key == 'allowedPersonaIds') {
        final audit = translator.translate(
          entry.value,
          location: childPath,
          source: RoleTranslationSource.guard,
        );
        audits.add(audit);
        auditsByLocation[childPath] = audit;
      } else {
        _auditLegacyGuards(
          entry.value,
          childPath,
          translator,
          audits,
          auditsByLocation,
        );
      }
    }
    return;
  }
  if (node is List) {
    for (var index = 0; index < node.length; index++) {
      _auditLegacyGuards(
        node[index],
        _listItemPath(path, index, node[index]),
        translator,
        audits,
        auditsByLocation,
      );
    }
  }
}

String _listItemPath(String path, int index, Object? item) {
  if (path.endsWith('.transitions') && item is Map) {
    final id = item['id'];
    if (id is String && id.isNotEmpty) return '$path[id=$id]';
  }
  return '$path[$index]';
}

List<String> _stringList(Object? value, String location) {
  if (value is! List || value.any((item) => item is! String)) {
    throw FormatException('$location must be a list of strings.');
  }
  return List.unmodifiable(value.cast<String>());
}

bool _sameSet(Set<String> left, Set<String> right) =>
    left.length == right.length && left.containsAll(right);

Object? _translateLegacyGuardsForRemoteDefinitions(
  Object? node,
  String path,
  Map<String, RoleTranslationAudit> auditsByLocation,
) {
  if (node is Map) {
    final translated = <String, Object?>{};
    for (final entry in node.entries) {
      final key = entry.key.toString();
      final childPath = '$path.$key';
      if (key == 'allowedPersonaIds') {
        final audit = auditsByLocation[childPath];
        if (audit == null) {
          throw StateError('Missing guard audit for $childPath.');
        }
        if (audit.roleIds case final roleIds?) {
          translated['allowedRoleIds'] = roleIds;
        } else {
          // Keep the original rule visible in dry-run output. Execution is
          // refused while this finding remains, so an incomplete target
          // definition can never be sent.
          translated[key] = _translateLegacyGuardsForRemoteDefinitions(
            entry.value,
            childPath,
            auditsByLocation,
          );
        }
      } else {
        translated[key] = _translateLegacyGuardsForRemoteDefinitions(
          entry.value,
          childPath,
          auditsByLocation,
        );
      }
    }
    return translated;
  }
  if (node is List) {
    return <Object?>[
      for (var index = 0; index < node.length; index++)
        _translateLegacyGuardsForRemoteDefinitions(
          node[index],
          _listItemPath(path, index, node[index]),
          auditsByLocation,
        ),
    ];
  }
  return node;
}
