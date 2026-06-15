# Builder App ID Service

Use `CommunityBuilderAppIdApi` when a generated extension needs a Loom-recognized builder identity and
signing scope. This links package signatures to the builder who produced them.

## Extension Use

- Register a builder app before signing package artifacts.
- Keep the signing scope narrow, for example `community.extension.sign`.
- Verify the app signing scope before publishing or sideloading packages.

## Validation

- `vt_builder-app-id_signing-scope` proves app registration, key issuance, audit linkage, and scope
  verification.
- `ct_builder-app-id__extension-registry_signing-scope` is pending until the Extension Registry exists.
