# Community Registry

Use `CommunityRegistryApi` to create and resolve communities by handle, QR payload, or ID. Extensions
reference communities through this registry and never create independent community identifiers.

## Extension Use

- Register community metadata through initialization packages.
- Keep branding fields current for App Shell community cards.
- Resolve by handle or QR before installing or opening an extension.

## Validation

- `vt_community-registry_discovery` proves handle/QR resolution.
- `vt_community-registry_branding` proves card branding updates and versioning.
- `ct_community-registry__extension-registry_installed-pointers` passes in A2.
