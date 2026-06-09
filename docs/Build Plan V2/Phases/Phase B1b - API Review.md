# Phase B1b - API Review

Status: Template

## Scope

Hosted build, publish, discover, certify, and install workflow.

## Review Checklist

- Package manifest fields.
- App ID signing and artifact attestation.
- Certification result and remediation shape.
- QR/handle payload.
- Latest certified version resolution.
- Install grant and permission review.
- Compatibility with B1a local package and initialization package contracts.

## OpenAPI Outputs

Record workflow-driven spec gaps for hosted publish, registry, certification, discovery, install, and
latest-open APIs. Every hosted API behavior must have a local backend stub or contract fake for Set B
validation.

## Commit Gate

Before starting the next phase:

- Stage only this phase's intended changes.
- Run `git diff --staged` and confirm the staged scope matches this phase.
- Commit the phase changes.
- Record the resulting commit SHA in [../Build Tracker.md](../Build%20Tracker.md).
- Do not begin the next phase until the commit exists and the tracker points to it.
