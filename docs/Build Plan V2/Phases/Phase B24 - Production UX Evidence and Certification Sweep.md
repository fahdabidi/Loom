# Phase B24 - Production UX Evidence and Certification Sweep

## Achieves

Certify the full example suite against the production UX standard and update the Skill completion
rules so future communities cannot be delivered with generic, incomplete, or untested workflows.

## Deliverables

- Full B12-B24 production workflow screenshot evidence manifest.
- Generic-copy failure gate for user-facing production workflow screens.
- Per-workflow production UX audit for entry, input, validation/review, action, success/result, and
  backend parity.
- Per-persona production UX audit for actor, receiver, read-only, disabled, hidden, unauthorized, and
  dependency-chain states.
- Skill completion-rule update requiring production UX contracts, semantic labels, persona-specific
  workflow evidence, and screenshot-backed receiver evidence.
- B24 API Review and B24 UX Decisions.

## Completed When

All example/test apps pass production UX workflow tests, every workflow has production evidence, every
multi-persona workflow has receiver evidence, and automated gates fail if user-facing workflow surfaces
contain generic harness copy or omit required user actions.

## Evidence Integrity Auditor Gate

Run `evidence_integrity_auditor.dart` against the B24 evidence:

```powershell
wsl.exe -d Ubuntu -- bash -lc 'cd "/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app" && dart run packages/tooling/loom_ux_judges/bin/evidence_integrity_auditor.dart --input ../docs/Build\ Plan\ V2/Evidence/B24/production-ux-evidence-integrity.json --base .. --output ../docs/Build\ Plan\ V2/Evidence/B24/evidence-integrity-scorecard.json --markdown-output ../docs/Build\ Plan\ V2/Evidence/B24/evidence-integrity-scorecard.md'
```

The auditor is deterministic. It must fail missing screenshot paths, hashes, timestamps, app commit SHA,
device metadata, visible-text extracts, stale references, or generic harness copy. B25 may not start
from un-audited B24 evidence.

## Prompt To Use

Use this prompt when executing B24:

```text
You are implementing Phase B24: Production UX Evidence and Certification Sweep.

Run the full example suite through the visible Android emulator with the Local Backend. Load every
example/test community and complete every workflow using the production surfaces built in B22 and the
persona behavior built in B23.

For each workflow, capture screenshots for entry, input, validation or review, semantic action,
success/result, and backend parity. For multi-persona workflows, also capture actor action, persona
switch, receiver state, continuation state if applicable, and unauthorized persona behavior.

Run a generic-copy failure gate that scans production workflow surfaces and screenshot/evidence
metadata for generic harness labels such as Complete workflow, Can perform this workflow, workflow
evidence, local route, or equivalent implementation-oriented copy. The gate must fail the phase when
such copy appears in user-facing production workflow UX.

Audit the Skill instructions so new communities require production UX contracts, domain-specific
workflow surfaces, semantic labels, persona-specific behavior, receiver evidence, and screenshot-backed
workflow completion before any package can be marked complete.

Run the full workflow sweep, manifest gate, B24 phase gate, analyze, boundary lint, diff check, and
record B24 API Review and B24 UX Decisions.
```

## Evidence To Record

Final B12-B24 evidence manifest, production UX audit, evidence integrity scorecard, generic-copy gate
output, screenshot bundle paths, full workflow/emulator output, Skill diff, manifest rows, phase gate,
analyzer, boundary lint, diff check, and commit SHA.
