# Extension Package Validator

Use `CommunityExtensionPackageApi` to validate `.loom-extension.zip` structure before local sideload or publish.

## Extension Use

- Include `loom.extension.json`, UI, assets, schemas, rules, workflows, jobs, fixtures/tests, docs, and signatures.
- Bundle default icon, card image, and hero image assets locally.
- Enforce asset kind, dimensions, hashes, and alt/decorative metadata.

## Validation

- `vt_extension-package_downloadable-shape`, `vt_extension-package_asset-manifest`, and `vt_extension-package_asset-policy` prove package shape and asset policy.
- `ct_extension-package__demo-loader_validate-load` remains pending until A6/B1a.
