# Provider Transfer Service

Use `CommunityProviderTransferApi` for transferring a community from one hosting provider to another.

## Extension Use

- Execute transfers from an export bundle, then verify the destination before marking the move complete.
- Keep provider credentials outside the extension package and use Loom connector/secrets contracts later.
- Surface rollback state in workflow UIs.

## Validation

- `vt_provider-transfer_execute-verify` proves transfer creation and verification.
