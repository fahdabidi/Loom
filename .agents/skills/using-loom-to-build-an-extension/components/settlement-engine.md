# Settlement Engine

Use `CommunitySettlementApi` to calculate settlement windows from immutable receipt records.

## Extension Use

- Never mutate receipts during settlement.
- Apply fraud adjustments as explicit signed inputs.
- Pass settlement output to utility funding rather than recalculating allocations in the extension.

## Validation

- `vt_settlement_run` proves receipt-window settlement.
- `ct_receipt-ledger__settlement_read-window` proves receipts remain the source of truth.
- `ct_fraud__settlement_apply-adjustment` proves adjustment application.
