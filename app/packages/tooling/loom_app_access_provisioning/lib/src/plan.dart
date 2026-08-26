import 'dart:convert';

typedef JsonMap = Map<String, Object?>;

/// A deterministic list of App Access community-installation requests.
///
/// It deliberately contains only the inputs that App Access needs to derive
/// groups, roles, and permissions. The service, not this client, owns that
/// derivation. Group ids therefore do not exist until an installation result
/// supplies them.
class AppAccessProvisioningPlan {
  const AppAccessProvisioningPlan({required this.communities});

  static const schemaVersion = 3;

  final List<CommunityInstallationPlanEntry> communities;

  JsonMap toJson() => <String, Object?>{
    'schemaVersion': schemaVersion,
    'communities': [for (final community in communities) community.toJson()],
  };

  String encode({bool pretty = true}) => pretty
      ? const JsonEncoder.withIndent('  ').convert(toJson())
      : jsonEncode(toJson());

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
    final communities = _listOfMaps(
      json['communities'],
      'communities',
    ).map(CommunityInstallationPlanEntry.fromJson).toList(growable: false);
    if (communities.isEmpty) {
      throw const FormatException(
        'Provisioning plan communities must not be empty.',
      );
    }
    final communityIds = communities.map((community) => community.communityId);
    if (communityIds.toSet().length != communities.length) {
      throw const FormatException(
        'Provisioning plan communityIds must be unique.',
      );
    }
    return AppAccessProvisioningPlan(
      communities: List.unmodifiable(communities),
    );
  }
}

/// One local community identity paired with the exact App Access request.
///
/// [communityId] is not sent to App Access. It associates the returned group
/// id with the workflow service's `LOOM_COMMUNITY_GROUP_IDS` map.
class CommunityInstallationPlanEntry {
  const CommunityInstallationPlanEntry({
    required this.communityId,
    required this.request,
  });

  final String communityId;
  final InstallCommunityPackageRequest request;

  JsonMap toJson() => <String, Object?>{
    'communityId': communityId,
    'request': request.toJson(),
  };

  factory CommunityInstallationPlanEntry.fromJson(JsonMap json) {
    final rawRequest = json['request'];
    if (rawRequest is! Map) {
      throw const FormatException('community request must be an object.');
    }
    return CommunityInstallationPlanEntry(
      communityId: _requiredString(json, 'communityId'),
      request: InstallCommunityPackageRequest.fromJson(
        Map<String, Object?>.from(rawRequest),
      ),
    );
  }
}

/// The generated-model contract for `POST /community-installations`.
class InstallCommunityPackageRequest {
  const InstallCommunityPackageRequest({
    required this.communityHandle,
    required this.displayName,
    required this.grammarVersion,
    required this.roles,
    required this.workflows,
  });

  final String communityHandle;
  final String displayName;
  final int grammarVersion;
  final List<DerivedRoleInput> roles;
  final List<DerivedWorkflowInput> workflows;

  JsonMap toJson() => <String, Object?>{
    'communityHandle': communityHandle,
    'displayName': displayName,
    'grammarVersion': grammarVersion,
    'roles': [for (final role in roles) role.toJson()],
    'workflows': [for (final workflow in workflows) workflow.toJson()],
  };

  factory InstallCommunityPackageRequest.fromJson(JsonMap json) {
    final grammarVersion = json['grammarVersion'];
    if (grammarVersion is! int) {
      throw const FormatException('grammarVersion must be an integer.');
    }
    return InstallCommunityPackageRequest(
      communityHandle: _requiredString(json, 'communityHandle'),
      displayName: _requiredString(json, 'displayName'),
      grammarVersion: grammarVersion,
      roles: List.unmodifiable(
        _listOfMaps(json['roles'], 'roles').map(DerivedRoleInput.fromJson),
      ),
      workflows: List.unmodifiable(
        _listOfMaps(
          json['workflows'],
          'workflows',
        ).map(DerivedWorkflowInput.fromJson),
      ),
    );
  }
}

class DerivedRoleInput {
  const DerivedRoleInput({required this.roleId, required this.label});

  final String roleId;
  final String label;

  JsonMap toJson() => <String, Object?>{'roleId': roleId, 'label': label};

  factory DerivedRoleInput.fromJson(JsonMap json) => DerivedRoleInput(
    roleId: _requiredString(json, 'roleId'),
    label: _requiredString(json, 'label'),
  );
}

class DerivedWorkflowInput {
  const DerivedWorkflowInput({
    required this.workflowType,
    required this.cardSurfaceFamily,
    required this.createRoleIds,
    required this.transitions,
  });

  final String workflowType;
  final String? cardSurfaceFamily;
  final List<String> createRoleIds;
  final List<DerivedTransitionInput> transitions;

  JsonMap toJson() => <String, Object?>{
    'workflowType': workflowType,
    'cardSurfaceFamily': cardSurfaceFamily,
    'createRoleIds': createRoleIds,
    'transitions': [for (final transition in transitions) transition.toJson()],
  };

  factory DerivedWorkflowInput.fromJson(JsonMap json) => DerivedWorkflowInput(
    workflowType: _requiredString(json, 'workflowType'),
    cardSurfaceFamily: _nullableString(
      json['cardSurfaceFamily'],
      'cardSurfaceFamily',
    ),
    createRoleIds: _stringList(json['createRoleIds'], 'createRoleIds'),
    transitions: List.unmodifiable(
      _listOfMaps(
        json['transitions'],
        'transitions',
      ).map(DerivedTransitionInput.fromJson),
    ),
  );
}

class DerivedTransitionInput {
  const DerivedTransitionInput({
    required this.transitionId,
    required this.action,
    required this.tone,
    required this.isTerminal,
    required this.allowedRoleIds,
  });

  final String transitionId;

  /// Null is serialized as an absent key, because an absent action tells App
  /// Access to use the generic-archetype structural rule.
  final String? action;
  final String? tone;
  final bool isTerminal;
  final List<String> allowedRoleIds;

  JsonMap toJson() => <String, Object?>{
    'transitionId': transitionId,
    if (action != null) 'action': action,
    'tone': tone,
    'isTerminal': isTerminal,
    'allowedRoleIds': allowedRoleIds,
  };

  factory DerivedTransitionInput.fromJson(JsonMap json) {
    final isTerminal = json['isTerminal'];
    if (isTerminal is! bool) {
      throw const FormatException('isTerminal must be a boolean.');
    }
    return DerivedTransitionInput(
      transitionId: _requiredString(json, 'transitionId'),
      action: _nullableString(json['action'], 'action'),
      tone: _nullableString(json['tone'], 'tone'),
      isTerminal: isTerminal,
      allowedRoleIds: _stringList(json['allowedRoleIds'], 'allowedRoleIds'),
    );
  }
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
