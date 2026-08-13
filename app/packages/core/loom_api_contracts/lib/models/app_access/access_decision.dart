/// The outcome of a runtime authorization check.
///
/// Carries the roles that produced the outcome so a denial is explainable
/// rather than opaque.
///
/// Maps to the `AccessDecision` schema in
/// `docs/API/OpenAPI/identity/app-access-api.openapi.yaml`.
class AccessDecision {
  const AccessDecision({
    required this.fanId,
    required this.appId,
    required this.permissionId,
    required this.allowed,
    this.groupId,
    this.grantingRoleIds = const [],
    this.reasons = const [],
    this.policyVersion,
  });

  final String fanId;
  final String appId;
  final String? groupId;
  final String permissionId;
  final bool allowed;

  /// Roles that granted the permission. Empty when [allowed] is false.
  final List<String> grantingRoleIds;

  /// Human-readable reasons behind the decision, for diagnostics and audit.
  final List<String> reasons;
  final String? policyVersion;
}

/// Every permission a fan effectively holds, resolved in one call.
///
/// Lets a client render a whole surface without issuing one decision request
/// per control.
///
/// Maps to the `EffectivePermissions` schema in
/// `docs/API/OpenAPI/identity/app-access-api.openapi.yaml`.
class EffectivePermissions {
  const EffectivePermissions({
    required this.fanId,
    required this.appId,
    required this.permissionIds,
    required this.roleIds,
    this.groupId,
    this.catalogVersion,
    this.resolvedAt,
  });

  final String fanId;
  final String appId;
  final String? groupId;

  /// Union of every permission granted by the fan's app-level and
  /// group-scoped roles.
  final List<String> permissionIds;
  final List<String> roleIds;
  final String? catalogVersion;
  final DateTime? resolvedAt;

  /// Whether this resolved set includes [permissionId].
  bool allows(String permissionId) => permissionIds.contains(permissionId);
}
