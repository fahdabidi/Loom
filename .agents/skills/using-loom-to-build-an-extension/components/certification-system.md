# Certification System

Use `CommunityCertificationApi` to validate extension package metadata, permissions, and asset
evidence before publication. Certification owns decisions; registries consume those decisions.

## Extension Use

- Include asset evidence for logos, card images, alt text, and bundled package assets.
- Keep requested permissions small enough to avoid unnecessary risk escalation.
- Do not publish rejected packages.

## Validation

- `vt_certification_validate-package` proves certified package decisions.
- `vt_certification_asset-evidence` proves missing asset evidence is rejected.
- `ct_certification__extension-registry_certify-package` passes in A2.
