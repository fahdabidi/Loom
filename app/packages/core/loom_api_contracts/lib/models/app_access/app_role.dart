/// A named set of permissions inside an app.
///
/// A role with [groupId] set belongs to that group — the group-to-roles
/// mapping, for example `cedar_commons_hoa_admin` in
/// `loom_communities_cedar_commons_hoa`. A role with [groupId] null is an
/// app-level template, assignable in any group of that app.
///
/// Maps to the `Role` schema in
/// `docs/API/OpenAPI/identity/app-access-api.openapi.yaml`.
class AppRole {
  const AppRole({
    required this.appId,
    required this.roleId,
    required this.displayName,
    required this.permissionIds,
    this.groupId,
    this.description,
    this.createdAt,
  });

  final String appId;
  final String roleId;

  /// The group this role belongs to, or null for an app-level template role.
  final String? groupId;
  final String displayName;
  final String? description;

  /// Ids from the app's own permission catalog.
  final List<String> permissionIds;
  final DateTime? createdAt;

  /// Whether this role is an app-level template rather than bound to one group.
  bool get isTemplate => groupId == null;
}
