# Dispute Service

Use `CommunityDisputeApi` for payment, moderation, or fraud-related dispute intake.

## Extension Use

- Open disputes with the underlying subject id and a clear reason.
- Keep fraud scoring in the fraud signal service; this service owns the dispute record.
- Use dispute events for downstream review workflows.

## Validation

- `vt_dispute_open-case` proves dispute creation and event emission.
- `ct_fraud__dispute_resolution-path` remains pending until A4b.
