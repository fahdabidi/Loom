# Extension Registry

Use `CommunityExtensionRegistryApi` to publish certified extension versions and resolve the latest
version for install/open flows. It consumes certification and builder App ID contracts.

## Extension Use

- Certify package artifacts before publishing a version.
- Verify builder signing scope before sending publish payloads.
- Resolve latest for local stubs and real backend publish mode.

## Validation

- `vt_extension-registry_resolve-latest` proves latest certified version resolution.
- `ct_builder-app-id__extension-registry_signing-scope` is unblocked and passes in A2.
- `ct_certification__extension-registry_certify-package` passes in A2.
