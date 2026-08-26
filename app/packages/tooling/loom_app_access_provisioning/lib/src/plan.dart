import 'dart:convert';

typedef JsonMap = Map<String, Object?>;

/// A deterministic, serializable App Access reconciliation plan.
class AppAccessProvisioningPlan {
  const AppAccessProvisioningPlan({
    required this.communities,
    required this.communityGroupIds,
  });

  static const schemaVersion = 1;

  final List<CommunityProvisioningEntry> communities;
  final Map<String, String> communityGroupIds;

  JsonMap toJson() => <String, Object?>{
    'schemaVersion': schemaVersion,
    'communities': [for (final community in communities) community.toJson()],
    'communityGroupIds': communityGroupIds,
  };

  String encode({bool pretty = true}) => pretty
      ? const JsonEncoder.withIndent('  ').convert(toJson())
      : jsonEncode(toJson());

  List<WorkflowProvisioningEntry> get unstatedCreationWorkflows => [
    for (final community in communities)
      ...community.workflows.where(
        (workflow) => workflow.creationAuthority == 'unstated',
      ),
  ];

  factory AppAccessProvisioningPlan.fromJsonString(String encoded) {
    final Object? decoded;
    try {
      decoded = jsonDecode(encoded);
    } on FormatException {
      throw const FormatException('Provisioning plan must be valid JSON.');
    }
    if (decoded is! Map) {
      throw const FormatException('Provisioning plan must be a JSON object.');
    }
    return AppAccessProvisioningPlan.fromJson(
      Map<String, Object?>.from(decoded),
    );
  }

  factory AppAccessProvisioningPlan.fromJson(JsonMap json) {
    if (json['schemaVersion'] != schemaVersion) {
      throw FormatException(
        'Unsupported provisioning plan schemaVersion "${json['schemaVersion']}".',
      );
    }
    final rawCommunities = json['communities'];
    if (rawCommunities is! List) {
      throw const FormatException(
        'Provisioning plan communities must be a list.',
      );
    }
    final rawGroupIds = json['communityGroupIds'];
    if (rawGroupIds is! Map) {
      throw const FormatException(
        'Provisioning plan communityGroupIds must be an object.',
      );
    }
    final communities = <CommunityProvisioningEntry>[];
    for (final entry in rawCommunities) {
      if (entry is! Map) {
        throw const FormatException('Each plan community must be an object.');
      }
      communities.add(
        CommunityProvisioningEntry.fromJson(Map<String, Object?>.from(entry)),
      );
    }
    final groupIds = <String, String>{};
    for (final entry in rawGroupIds.entries) {
      if (entry.key is! String || entry.value is! String) {
        throw const FormatException(
          'communityGroupIds must map strings to strings.',
        );
      }
      groupIds[entry.key as String] = entry.value as String;
    }
    return AppAccessProvisioningPlan(
      communities: List.unmodifiable(communities),
      communityGroupIds: Map.unmodifiable(groupIds),
    );
  }
}

class CommunityProvisioningEntry {
  const CommunityProvisioningEntry({
    required this.communityId,
    required this.groupId,
    required this.displayName,
    required this.roles,
    required this.workflows,
  });

  final String communityId;
  final String groupId;
  final String displayName;
  final List<RoleProvisioningEntry> roles;
  final List<WorkflowProvisioningEntry> workflows;

  JsonMap toJson() => <String, Object?>{
    'communityId': communityId,
    'groupId': groupId,
    'displayName': displayName,
    'roles': [for (final role in roles) role.toJson()],
    'workflows': [for (final workflow in workflows) workflow.toJson()],
  };

  factory CommunityProvisioningEntry.fromJson(JsonMap json) {
    final roles = _listOfMaps(
      json['roles'],
      'roles',
    ).map(RoleProvisioningEntry.fromJson).toList(growable: false);
    final communityId = _requiredString(json, 'communityId');
    final workflows = _listOfMaps(json['workflows'], 'workflows')
        .map(WorkflowProvisioningEntry.fromJson)
        .map((workflow) => workflow.withCommunityId(communityId))
        .toList(growable: false);
    return CommunityProvisioningEntry(
      communityId: communityId,
      groupId: _requiredString(json, 'groupId'),
      displayName: _requiredString(json, 'displayName'),
      roles: roles,
      workflows: workflows,
    );
  }
}

class RoleProvisioningEntry {
  const RoleProvisioningEntry({
    required this.roleId,
    required this.displayName,
    required this.permissionIds,
  });

  final String roleId;
  final String displayName;
  final List<String> permissionIds;

  JsonMap toJson() => <String, Object?>{
    'roleId': roleId,
    'displayName': displayName,
    'permissionIds': permissionIds,
  };

  factory RoleProvisioningEntry.fromJson(JsonMap json) => RoleProvisioningEntry(
    roleId: _requiredString(json, 'roleId'),
    displayName: _requiredString(json, 'displayName'),
    permissionIds: _stringList(json['permissionIds'], 'permissionIds'),
  );
}

class WorkflowProvisioningEntry {
  const WorkflowProvisioningEntry({
    required this.communityId,
    required this.workflowType,
    required this.family,
    required this.permissionPrefix,
    required this.creationAuthority,
    required this.createRoleIds,
  });

  final String communityId;
  final String workflowType;

  /// Null only for an unrendered, system-created workflow. The existing
  /// resolver intentionally returns no family for that shape, so it derives no
  /// App Access permission.
  final String? family;
  final String? permissionPrefix;

  /// `initial-state-transition`, `system-created`, or the temporary
  /// `unstated` stopgap described by the package derivation requirements.
  final String creationAuthority;
  final List<String> createRoleIds;

  JsonMap toJson() => <String, Object?>{
    'workflowType': workflowType,
    'family': family,
    'permissionPrefix': permissionPrefix,
    'creationAuthority': creationAuthority,
    'createRoleIds': createRoleIds,
  };

  factory WorkflowProvisioningEntry.fromJson(
    JsonMap json,
  ) => WorkflowProvisioningEntry(
    // The enclosing community owns this field. It is retained only in the
    // in-memory model so status reporting can render package/workflow pairs.
    communityId: '',
    workflowType: _requiredString(json, 'workflowType'),
    family: _nullableString(json['family'], 'family'),
    permissionPrefix: _nullableString(
      json['permissionPrefix'],
      'permissionPrefix',
    ),
    creationAuthority: _requiredString(json, 'creationAuthority'),
    createRoleIds: _stringList(json['createRoleIds'], 'createRoleIds'),
  );

  WorkflowProvisioningEntry withCommunityId(String value) =>
      WorkflowProvisioningEntry(
        communityId: value,
        workflowType: workflowType,
        family: family,
        permissionPrefix: permissionPrefix,
        creationAuthority: creationAuthority,
        createRoleIds: createRoleIds,
      );
}

List<JsonMap> _listOfMaps(Object? value, String field) {
  if (value is! List) throw FormatException('$field must be a list.');
  final maps = <JsonMap>[];
  for (final item in value) {
    if (item is! Map) throw FormatException('$field must contain objects.');
    maps.add(Map<String, Object?>.from(item));
  }
  return maps;
}

String _requiredString(JsonMap json, String field) {
  final value = json[field];
  if (value is! String || value.trim().isEmpty) {
    throw FormatException('$field must be a non-empty string.');
  }
  return value;
}

List<String> _stringList(Object? value, String field) {
  if (value is! List || value.any((item) => item is! String)) {
    throw FormatException('$field must be a list of strings.');
  }
  return List.unmodifiable(value.cast<String>());
}

String? _nullableString(Object? value, String field) {
  if (value == null) return null;
  if (value is! String || value.trim().isEmpty) {
    throw FormatException('$field must be a non-empty string or null.');
  }
  return value;
}
