/// One permission declared by an app's catalog.
///
/// Maps to the `Permission` schema in
/// `docs/API/OpenAPI/identity/app-access-api.openapi.yaml`.
class AppPermission {
  const AppPermission({
    required this.permissionId,
    required this.displayName,
    this.description,
    this.category,
  });

  /// App-unique permission id, for example `event_rsvp.create`.
  final String permissionId;
  final String displayName;
  final String? description;

  /// Optional catalog grouping. Loom Communities uses the archetype's
  /// `cardSurfaceFamily`, for example `event-rsvp` or `documentLibrary`.
  final String? category;
}

/// A role grant left dangling by a catalog replacement that removed the
/// permission it referenced.
///
/// Reported rather than auto-revoked, so removing a permission from a role is
/// always a deliberate act.
class OrphanedRoleGrant {
  const OrphanedRoleGrant({required this.roleId, required this.permissionId});

  final String roleId;
  final String permissionId;
}

/// A published, versioned permission catalog for one app.
class AppPermissionCatalog {
  const AppPermissionCatalog({
    required this.appId,
    required this.catalogVersion,
    required this.permissions,
    required this.publishedAt,
    this.orphanedRoleGrants = const [],
  });

  final String appId;
  final String catalogVersion;
  final List<AppPermission> permissions;

  /// Grants that referenced a permission no longer present in this catalog.
  final List<OrphanedRoleGrant> orphanedRoleGrants;
  final DateTime publishedAt;
}
