/// Lifecycle state of a registered app.
enum AppStatus { active, suspended, retired }

/// An app registered with the App Access API — the tenancy root that owns a
/// permission catalog, groups, and roles.
///
/// Maps to the `App` schema in
/// `docs/API/OpenAPI/identity/app-access-api.openapi.yaml`. Named
/// `RegisteredApp` in Dart because `App` collides too easily inside consuming
/// Flutter applications.
class RegisteredApp {
  const RegisteredApp({
    required this.appId,
    required this.displayName,
    required this.status,
    required this.createdAt,
    this.description,
    this.permissionCatalogVersion,
  });

  /// Stable app id, for example `loom_communities`.
  final String appId;
  final String displayName;
  final String? description;
  final AppStatus status;

  /// Version of the currently published permission catalog, or null when the
  /// app has not published one yet.
  final String? permissionCatalogVersion;
  final DateTime createdAt;
}
