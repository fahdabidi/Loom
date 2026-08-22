# Protected Visibility Vault

Use `CommunityProtectedVaultApi` for sensitive member data whose visibility must be controlled by
Loom policy. Extensions receive redacted views only after Loom authorizes access.

## Extension Use

- Declare the protected field, purpose, and retention.
- Treat a `null` protected-vault read as a denied access decision.
- Do not duplicate sensitive values into extension-owned tables.

## Validation

- `vt_protected-vault_read-gated` proves denied reads stay hidden and granted reads return redacted data.
- `ct_protected-vault__ads_no-fill-sensitive` is pending until ad decision services exist.
