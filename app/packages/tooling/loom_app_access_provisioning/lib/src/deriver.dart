import 'package:loom_ux_judges/community_remote_migration.dart';
import 'package:loom_workflow_engine/loom_workflow_engine.dart';

import 'plan.dart';

/// Pure conversion from already-parsed shipped packages to App Access state.
class AppAccessProvisioningDeriver {
  const AppAccessProvisioningDeriver({
    this.archetypeResolver = const ArchetypeResolver(),
  });

  final ArchetypeResolver archetypeResolver;

  AppAccessProvisioningPlan deriveAll(
    Iterable<ParsedCommunityPackage> packages,
  ) {
    final entries = <CommunityProvisioningEntry>[];
    final groupIds = <String, String>{};
    final roleIds = <String>{};

    for (final package in packages) {
      final entry = _derivePackage(package);
      if (groupIds.containsKey(entry.communityId)) {
        throw FormatException('Duplicate communityId ${entry.communityId}.');
      }
      groupIds[entry.communityId] = entry.groupId;
      for (final role in entry.roles) {
        if (!roleIds.add(role.roleId)) {
          throw FormatException(
            'Role id ${role.roleId} appears in more than one package.',
          );
        }
      }
      entries.add(entry);
    }
    if (entries.isEmpty) {
      throw const FormatException(
        'At least one community package is required.',
      );
    }
    return AppAccessProvisioningPlan(
      communities: List.unmodifiable(entries),
      communityGroupIds: Map.unmodifiable(groupIds),
    );
  }

  CommunityProvisioningEntry _derivePackage(ParsedCommunityPackage package) {
    final declaredRoleIds = package.roles.map((role) => role.roleId).toSet();
    if (declaredRoleIds.length != package.roles.length) {
      throw FormatException(
        '${package.sourcePath} declares duplicate role ids.',
      );
    }
    final resolved = archetypeResolver.resolveAll(
      package.rawWorkflowDefinitions,
    );
    final producedByEffect = _workflowTypesProducedByCreateInstanceEffects(
      package.rawWorkflowDefinitions,
    );
    final rolePermissions = <String, Set<String>>{
      for (final role in package.roles) role.roleId: <String>{},
    };
    final workflowEntries = <WorkflowProvisioningEntry>[];

    for (final definitionEntry in package.rawWorkflowDefinitions.entries) {
      final workflowType = definitionEntry.key;
      if (definitionEntry.value is! Map) {
        throw FormatException(
          '$workflowType must be a workflow-definition object.',
        );
      }
      final definition = Map<Object?, Object?>.from(
        definitionEntry.value as Map,
      );
      final initialState = _requiredString(
        definition['initialState'],
        '$workflowType.initialState',
      );
      final transitions = _transitions(definition, workflowType);
      final initialRoleIds = <String>{};
      for (final transition in transitions) {
        if (_fromStates(transition, workflowType).contains(initialState)) {
          initialRoleIds.addAll(_allowedRoleIds(transition, workflowType));
        }
      }
      _verifyDeclaredRoles(
        initialRoleIds,
        declaredRoleIds,
        '$workflowType initial-state transition',
      );

      late final String creationAuthority;
      late final Set<String> createRoleIds;
      if (initialRoleIds.isNotEmpty) {
        creationAuthority = 'initial-state-transition';
        createRoleIds = initialRoleIds;
      } else if (producedByEffect.contains(workflowType)) {
        creationAuthority = 'system-created';
        createRoleIds = <String>{};
      } else {
        creationAuthority = 'unstated';
        createRoleIds = provisionalCreateRoleIdsForUnstatedAuthority(
          declaredRoleIds,
        );
      }
      final family = resolved[workflowType]?.family;
      if (family == null) {
        if (creationAuthority != 'system-created') {
          throw FormatException(
            '$workflowType has no resolvable archetype family; refusing to '
            'invent App Access permissions.',
          );
        }
        // The existing resolver deliberately returns no family for an
        // unrendered system-only workflow. With no person-facing creation
        // authority, it correctly derives no App Access grant or prefix.
        workflowEntries.add(
          WorkflowProvisioningEntry(
            communityId: package.communityId,
            workflowType: workflowType,
            family: null,
            permissionPrefix: null,
            creationAuthority: creationAuthority,
            createRoleIds: const <String>[],
          ),
        );
        continue;
      }
      final createPermissionId = archetypeResolver.permissionId(
        family,
        'create',
      );
      if (createPermissionId == null) {
        throw FormatException('$workflowType resolved unknown family $family.');
      }
      final permissionPrefix = createPermissionId.substring(
        0,
        createPermissionId.length - '.create'.length,
      );
      for (final roleId in createRoleIds) {
        rolePermissions[roleId]!.add(createPermissionId);
      }

      for (final transition in transitions) {
        final action = transition['action'];
        if (action == null) continue;
        if (action is! String || action.isEmpty) {
          throw FormatException(
            '$workflowType transition action must be a string.',
          );
        }
        // Creation is handled above by the three explicit creation-authority
        // cases, not by ordinary action grants.
        if (action == 'create') continue;
        final permissionId = archetypeResolver.permissionId(family, action);
        if (permissionId == null) {
          throw FormatException(
            '$workflowType action $action has no permission prefix.',
          );
        }
        final allowedRoleIds = _allowedRoleIds(transition, workflowType);
        _verifyDeclaredRoles(
          allowedRoleIds,
          declaredRoleIds,
          '$workflowType action $action',
        );
        for (final roleId in allowedRoleIds) {
          rolePermissions[roleId]!.add(permissionId);
        }
      }

      workflowEntries.add(
        WorkflowProvisioningEntry(
          communityId: package.communityId,
          workflowType: workflowType,
          family: family,
          permissionPrefix: permissionPrefix,
          creationAuthority: creationAuthority,
          createRoleIds: _sorted(createRoleIds),
        ),
      );
    }

    final suffix = _underscoredCommunitySuffix(package.communityId);
    return CommunityProvisioningEntry(
      communityId: package.communityId,
      groupId: 'loom_communities_$suffix',
      displayName: package.displayName,
      roles: List.unmodifiable([
        for (final role in package.roles)
          RoleProvisioningEntry(
            roleId: role.roleId,
            displayName: role.label,
            permissionIds: _sorted(rolePermissions[role.roleId]!),
          ),
      ]),
      workflows: List.unmodifiable(workflowEntries),
    );
  }
}

/// Provisional policy pending a product decision: a person creates these
/// workflows, but their packages state no creator role. Keeping this stopgap
/// in one named function makes it removable without disturbing derivation.
Set<String> provisionalCreateRoleIdsForUnstatedAuthority(
  Set<String> declaredRoleIds,
) => Set<String>.of(declaredRoleIds);

Set<String> _workflowTypesProducedByCreateInstanceEffects(
  Map<String, Object?> definitions,
) {
  final produced = <String>{};
  for (final definition in definitions.values) {
    _collectCreatedWorkflowTypes(definition, produced);
  }
  return produced;
}

void _collectCreatedWorkflowTypes(Object? value, Set<String> produced) {
  if (value is Map) {
    if (value['op'] == 'createInstance' && value['workflowType'] is String) {
      produced.add(value['workflowType'] as String);
    }
    for (final child in value.values) {
      _collectCreatedWorkflowTypes(child, produced);
    }
  } else if (value is List) {
    for (final child in value) {
      _collectCreatedWorkflowTypes(child, produced);
    }
  }
}

List<Map<Object?, Object?>> _transitions(
  Map<Object?, Object?> definition,
  String workflowType,
) {
  final raw = definition['transitions'];
  if (raw is! List) {
    throw FormatException('$workflowType.transitions must be a list.');
  }
  final transitions = <Map<Object?, Object?>>[];
  for (final transition in raw) {
    if (transition is! Map) {
      throw FormatException('$workflowType.transitions must contain objects.');
    }
    transitions.add(Map<Object?, Object?>.from(transition));
  }
  return transitions;
}

Set<String> _fromStates(Map<Object?, Object?> transition, String workflowType) {
  final from = transition['from'];
  if (from is! List || from.any((state) => state is! String)) {
    throw FormatException(
      '$workflowType transition from must be a list of strings.',
    );
  }
  return from.cast<String>().toSet();
}

Set<String> _allowedRoleIds(
  Map<Object?, Object?> transition,
  String workflowType,
) {
  final guard = transition['guard'];
  if (guard == null) return <String>{};
  if (guard is! Map) {
    throw FormatException('$workflowType transition guard must be an object.');
  }
  final rawRoleIds = guard['allowedRoleIds'];
  if (rawRoleIds == null) return <String>{};
  if (rawRoleIds is! List || rawRoleIds.any((roleId) => roleId is! String)) {
    throw FormatException(
      '$workflowType guard.allowedRoleIds must be a list of strings.',
    );
  }
  return rawRoleIds.cast<String>().toSet();
}

void _verifyDeclaredRoles(
  Iterable<String> usedRoleIds,
  Set<String> declaredRoleIds,
  String location,
) {
  for (final roleId in usedRoleIds) {
    if (!declaredRoleIds.contains(roleId)) {
      throw FormatException('$location names undeclared role $roleId.');
    }
  }
}

String _requiredString(Object? value, String location) {
  if (value is! String || value.isEmpty) {
    throw FormatException('$location must be a non-empty string.');
  }
  return value;
}

String _underscoredCommunitySuffix(String communityId) {
  const prefix = 'community_';
  if (!communityId.startsWith(prefix) || communityId.length == prefix.length) {
    throw FormatException(
      'Community id $communityId must start with $prefix for group derivation.',
    );
  }
  return communityId.substring(prefix.length).replaceAll('-', '_');
}

List<String> _sorted(Iterable<String> values) =>
    values.toSet().toList()..sort();
