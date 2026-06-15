# Import Service

Use `CommunityImportApi` for local-demo setup packages, migration imports, and source-tool onboarding.

## Extension Use

- Always run `dryRun` before `commit`.
- Declare sensitive fields so imported data routes through the protected vault.
- Keep source-specific parsing outside Loom-owned storage contracts.

## Validation

- `vt_import_dry-run` proves preview counts and warnings.
- `vt_import_commit` proves committed records and protected-field routing.
- `ct_import__protected-vault_write` proves sensitive imports use the protected vault.
