# Phase B7 - API Review

Status: Template

## Scope

Ad-off workflow: checkout, entitlement, ad suppression, receipts, settlement, utility allocation.

## Review Checklist

- Ad-off entitlement scope.
- Member vs community ad-off.
- Sensitive no-fill still enforced.
- Receipt and settlement fields.
- Utility funding allocation fields.

## OpenAPI Outputs

Record workflow-driven spec gaps.

## Commit Gate

Before starting the next phase:

- Stage only this phase's intended changes.
- Run `git diff --staged` and confirm the staged scope matches this phase.
- Commit the phase changes.
- Record the resulting commit SHA in [../Build Tracker.md](../Build%20Tracker.md).
- Do not begin the next phase until the commit exists and the tracker points to it.
