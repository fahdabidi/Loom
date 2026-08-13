import '../shared/resource_ref.dart';

/// A tenancy unit inside an app.
///
/// Loom Communities creates one group per community, for example
/// `loom_communities_cedar_commons_hoa`.
///
/// Maps to the `Group` schema in
/// `docs/API/OpenAPI/identity/app-access-api.openapi.yaml`.
class AppGroup {
  const AppGroup({
    required this.appId,
    required this.groupId,
    required this.displayName,
    required this.createdAt,
    this.parentGroupId,
    this.externalRef,
  });

  final String appId;
  final String groupId;
  final String displayName;

  /// Optional parent, for nested group hierarchies.
  final String? parentGroupId;

  /// Optional pointer back to the app's own record for this group — for Loom
  /// Communities, the community it represents.
  final ResourceRef? externalRef;
  final DateTime createdAt;
}
