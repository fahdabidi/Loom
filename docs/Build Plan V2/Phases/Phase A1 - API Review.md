# Phase A1 - API Review

Status: Template

## Scope

Foundation APIs: Passport, role/policy/consent, core vault, protected vault, connections, receipts,
audit, event bus, key management, builder App ID.

## Review Checklist

- Contract-first request/response shapes.
- Idempotency keys on mutations.
- Version fields.
- Redacted audit fields for sensitive data.
- Fake dependency coverage.
- Consumer-contract test kits for dependents.

## OpenAPI Outputs

Record new or updated specs under `docs/API/OpenAPI/**`.
