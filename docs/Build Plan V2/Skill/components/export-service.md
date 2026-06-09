# Export Service

Use `CommunityExportApi` for portability bundles, local-demo snapshots, and provider transfer packages.

## Extension Use

- Export through component contracts; never read another component's store directly.
- Request redaction for user-facing portability unless an admin workflow explicitly needs full data.
- Use checksums to prove the transfer artifact is the same one verified later.

## Validation

- `vt_export_assemble` proves document inclusion through the documents contract.
- `vt_export_redaction` proves protected data is marked redacted.
- `ct_export__components_enumerate` remains pending until A5 data schema support exists.
