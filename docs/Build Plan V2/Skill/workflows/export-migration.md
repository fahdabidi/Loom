# Export and Migration

Use this workflow when building extension or admin experiences that need Loom community export,
protected redaction, import replay, extension custom-data export, provider transfer, rollback, and final
readiness validation.

## Process

1. Start with an explicit export scope and explain which components are included.
2. Mark extension custom schemas as exportable only when the data is portable and safe to transfer.
3. Route sensitive imported fields through protected vault records.
4. Use redacted exports for provider transfer by default.
5. Preserve receipt IDs and economic component coverage without exposing payment details beyond the
   caller's export scope.
6. Verify the target provider before marking a transfer complete.
7. Expose rollback when verification fails or target checksums do not match.
8. Run the API inventory validator and the full Set B workflow suite before declaring readiness.

## Covering Tests

- `wf_export-migration`
- `vt_provider-transfer_rollback`
- `vt_api_specs_complete`

## Gotchas

- Import replay must be idempotent. Reusing an import idempotency key must not duplicate protected
  records.
- `redacted=true` is not enough; the bundle must also expose the protected-vault redaction marker.
- Local B8 checksums are deterministic fake values. Hosted exports need archive-level SHA-256
  checksums and signed manifests.
