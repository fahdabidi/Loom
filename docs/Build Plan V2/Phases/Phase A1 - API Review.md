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

## Commit Gate

Before starting the next phase:

- Stage only this phase's intended changes.
- Run `git diff --staged` and confirm the staged scope matches this phase.
- Commit the phase changes.
- Record the resulting commit SHA in [../Build Tracker.md](../Build%20Tracker.md).
- Do not begin the next phase until the commit exists and the tracker points to it.
