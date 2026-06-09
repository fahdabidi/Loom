# Phase A4b - API Review

Status: Template

## Scope

Economic/search/ad service APIs: wallet, ad decision, ad campaign, search, indexing, AI gateway,
digest, settlement, utility funding, fraud signals.

## Review Checklist

- Payment/ad-off idempotency.
- Sensitive ad no-fill reason shape.
- No paid search ranking fields.
- AI citation/source policy fields.
- Receipt and settlement allocation fields.
- Fraud hold/adjustment shape.

## OpenAPI Outputs

Record economic/search/ad-service spec additions and gaps.

## Commit Gate

Before starting the next phase:

- Stage only this phase's intended changes.
- Run `git diff --staged` and confirm the staged scope matches this phase.
- Commit the phase changes.
- Record the resulting commit SHA in [../Build Tracker.md](../Build%20Tracker.md).
- Do not begin the next phase until the commit exists and the tracker points to it.
