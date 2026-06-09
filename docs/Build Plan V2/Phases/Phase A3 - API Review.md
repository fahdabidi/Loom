# Phase A3 - API Review

Status: Template

## Scope

Experience service APIs: publishing, messaging/stream, notifications, events, forms, polls, voting.

## Review Checklist

- Pagination and bounded reads.
- Stream item taxonomy.
- Event/RSVP state transitions.
- Protected field routing for forms.
- Notification delivery and dedupe.
- Provider-authored contract tests for search, stream renderer, workflow engine, and App Shell consumers.

## OpenAPI Outputs

Record experience-service spec additions and gaps.

## Commit Gate

Before starting the next phase:

- Stage only this phase's intended changes.
- Run `git diff --staged` and confirm the staged scope matches this phase.
- Commit the phase changes.
- Record the resulting commit SHA in [../Build Tracker.md](../Build%20Tracker.md).
- Do not begin the next phase until the commit exists and the tracker points to it.
