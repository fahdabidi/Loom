# Phase B8 - API Review

Status: Template

## Scope

Export and migration workflow.

## Review Checklist

- Export scope and package manifest.
- Protected redaction/splitting.
- Extension data schema export.
- Checksums and receipt fields.
- Provider transfer verification and rollback.
- Final API inventory: every V2 component has a spec or an explicit local-only contract.
- OpenAPI/contract validation output is linked.

## OpenAPI Outputs

Record workflow-driven spec gaps and the final API inventory result.

## Commit Gate

Before starting the next phase:

- Stage only this phase's intended changes.
- Run `git diff --staged` and confirm the staged scope matches this phase.
- Commit the phase changes.
- Record the resulting commit SHA in [../Build Tracker.md](../Build%20Tracker.md).
- Do not begin the next phase until the commit exists and the tracker points to it.
