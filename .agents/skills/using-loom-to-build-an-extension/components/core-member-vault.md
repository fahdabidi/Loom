# Core Member Vault

Use `CommunityCoreVaultApi` for non-sensitive member preferences that Loom owns and exposes by
contract. Extensions may read or set preferences only through Loom APIs.

## Extension Use

- Store display and experience preferences such as theme, digest cadence, or default landing surface.
- Keep domain-specific extension data in extension schemas instead of the core vault.
- Use idempotency keys when setting preferences from jobs or initialization packages.

## Validation

- `vt_core-vault_preferences` proves preference write/read and version behavior.
