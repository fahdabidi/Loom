# Receipt Ledger

Use `CommunityReceiptLedgerApi` when an extension causes or displays auditable economic or activity
events. Receipts are Loom-owned records and should be append-only.

## Extension Use

- Append receipts through Loom APIs for dues, donations, ad-off, settlement inputs, or workflow events.
- Reuse idempotency keys for retries so duplicate receipts are not created.
- Display receipts from `listReceipts` instead of caching local copies.

## Validation

- `vt_receipt-ledger_append` proves append-only idempotent receipt creation.
- `ct_receipt-ledger__wallet_append-payment` is pending until wallet services exist.
