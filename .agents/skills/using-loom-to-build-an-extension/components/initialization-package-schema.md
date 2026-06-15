# Initialization Package Schema

Use `CommunityInitializationPackageApi` to validate `.loom-init.zip` fake-backend seed packages.

## Extension Use

- Include community handle, display name, logo, card image, hero image, accent color, and idempotency key.
- Seed through Loom APIs instead of writing fake-backend tables directly.
- Keep initialization packages idempotent for rebuild/reinstall loops.

## Validation

- `vt_initialization-package_schema`, `vt_initialization-package_idempotency`, and `vt_initialization-package_community-branding` prove initialization package behavior.
- Fake-backend import contracts remain pending until A6/B1a.
