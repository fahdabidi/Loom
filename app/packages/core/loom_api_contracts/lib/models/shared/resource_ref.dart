/// A typed pointer to a resource owned by another API surface.
///
/// Maps to the shared `ResourceRef` schema in
/// `docs/API/OpenAPI/_shared/components.yaml`.
class ResourceRef {
  const ResourceRef({
    required this.resourceType,
    required this.resourceId,
    this.version,
  });

  final String resourceType;
  final String resourceId;
  final String? version;
}
