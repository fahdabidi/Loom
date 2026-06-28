# UX Gate Judge Tools

These tools separate implementation from pass/fail judgment. Worker agents may implement UI and tests,
but they do not grade their own work. Evidence collectors gather artifacts. Judge agents and deterministic
judge CLIs evaluate only those artifacts against the relevant phase standard. Remediation planners turn
judge failures into fix batches for the next worker iteration.

## Agent Split

| Role | Responsibility | Context allowed | Output |
| --- | --- | --- | --- |
| Worker Agent | Implements UX/code/test fixes. | Phase docs, code, failing judge reports, remediation plan. | Code, tests, screenshots, updated artifacts. |
| Evidence Collector Tool | Captures screenshots, hashes, visible text, app commit SHA, device metadata, command output. | Running app, emulator, artifact paths. No implementation rationale. | Evidence JSON and screenshot bundle. |
| UX Judge Agent | Scores artifacts against phase criteria. | Evidence artifacts, screenshots, pass criteria, blueprint/contracts. No worker implementation notes. | Scorecard, findings, pass/fail. |
| Remediation Planner | Converts judge failures into right-sized fix batches. | Judge scorecard, findings, phase docs. | Remediation plan for Worker Agent. |

## Deterministic CLIs

Run from `app/` with WSL Ubuntu:

```powershell
wsl.exe -d Ubuntu -- bash -lc 'cd "/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app" && dart run packages/tooling/loom_ux_judges/bin/production_ux_judge.dart --input ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --base .. --output ../docs/Build\ Plan\ V2/Evidence/B25/production-ux-criteria-scorecard.json --markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/production-ux-criteria-scorecard.md'
```

| Tool | Phase | Purpose |
| --- | --- | --- |
| `workflow_completeness_judge.dart` | B11 | Compare owner prompt, requested workflows, generated packages, Demo App validation, and completion report. |
| `ux_contract_judge.dart` | B21 | Validate production UX contract rows before implementation. |
| `domain_surface_classifier.dart` | B22 | Fail primary generic workflow cards/checklist/metadata surfaces. |
| `persona_ux_judge.dart` | B23 | Verify actor, receiver, read-only, disabled, hidden, and unauthorized persona evidence. |
| `evidence_integrity_auditor.dart` | B24 | Check screenshot path/hash/timestamp/app commit/device/visible text and generic-copy evidence. |
| `production_ux_judge.dart` | B25 | Score every B25 production UX pass criterion and fail any missing or weak evidence. |

## Required B25 Scorecard

`production_ux_judge.dart` emits:

- `production-ux-criteria-scorecard.json`
- `production-ux-criteria-scorecard.md`

Each criterion row includes:

- `criterionId`
- `score`
- `verdict`
- `blocksPass`
- `evidenceUsed`
- `why`
- `requiredFix`

B25 cannot pass from an average score. One unresolved blocker/major criterion failure blocks the phase.

## Judge Agent Prompt Contract

Use this prompt shape for the UX Judge Agent:

```text
You are a UX Judge Agent. You did not implement the UI.

Use only the supplied artifacts:
- production UX blueprint
- workflow/persona contracts
- screenshot inventory
- screenshots and hashes
- visible-text extracts
- app commit SHA and emulator metadata
- workflow evidence manifest
- current review JSON
- remediation loop log

Do not use worker implementation notes or intended behavior. If the artifact does not prove it, mark it
missing. If the screenshot does not show it, the UX did not pass.

Score each criterion independently. Return pass only when every blocking criterion passes, screenshots
are fresh, critiques are screen-specific, and primary workflow surfaces are domain-native.
```

## Remediation Planner Contract

The remediation planner receives only judge failures and phase docs. It must output:

- root-cause cluster
- affected communities/screens/personas/workflows
- target production surface
- files likely needing changes
- tests/evidence to rerun
- commit boundary for the iteration

The Worker Agent receives the remediation plan, not a softened pass/fail summary.

