# Fraud Signal Service

Use `CommunityFraudApi` for payment, dispute, and settlement risk signals.

## Extension Use

- Create signals against the subject record; do not change payment or dispute records directly.
- Use `adjustment` severity only when settlement should apply an explicit adjustment.
- Feed dispute workflows with signal ids and severity.

## Validation

- `vt_fraud_create-signal` proves signal creation.
- `ct_fraud__dispute_resolution-path` proves dispute linkage.
