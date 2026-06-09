# Phase A4a - API Review

Status: Template

## Scope

Ops/community service APIs: case/task, documents, facilities, import, export, provider transfer,
abuse reports, moderation, incidents, disputes.

## Review Checklist

- Case/task transition shape.
- Document permission and export behavior.
- Facility reservation and payment coupling.
- Import dry-run and commit semantics.
- Export redaction and checksums.
- Incident/dispute policy-versioned decisions.

## OpenAPI Outputs

Record ops/community-service spec additions and gaps.

## Commit Gate

Before starting the next phase:

- Stage only this phase's intended changes.
- Run `git diff --staged` and confirm the staged scope matches this phase.
- Commit the phase changes.
- Record the resulting commit SHA in [../Build Tracker.md](../Build%20Tracker.md).
- Do not begin the next phase until the commit exists and the tracker points to it.
