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
wsl.exe -d Ubuntu -- bash -lc 'cd "/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app" && dart run packages/tooling/loom_ux_judges/bin/b25_iteration_scorecard.dart --review ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --judge ../docs/Build\ Plan\ V2/Evidence/B25/production-ux-criteria-scorecard.json --output ../docs/Build\ Plan\ V2/Evidence/B25/b25-iteration-scorecard-latest.json --markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/b25-iteration-scorecard-latest.md'
```

| Tool | Phase | Purpose |
| --- | --- | --- |
| `workflow_completeness_judge.dart` | B11 | Compare owner prompt, requested workflows, generated packages, Demo App validation, and completion report. |
| `ux_contract_judge.dart` | B21 | Validate production UX contract rows before implementation. |
| `domain_surface_classifier.dart` | B22 | Fail primary generic workflow cards/checklist/metadata surfaces. |
| `persona_ux_judge.dart` | B23 | Verify actor, receiver, read-only, disabled, hidden, and unauthorized persona evidence. |
| `evidence_integrity_auditor.dart` | B24 | Check screenshot path/hash/timestamp/app commit/device/visible text and generic-copy evidence. |
| `production_ux_judge.dart` | B25 | Score every B25 production UX pass criterion and fail any missing or weak evidence. |
| `b25_iteration_scorecard.dart` | B25 | Summarize each B25 review/remediation pass with current blocker/major counts, resolved counts, new counts, judge failures, and convergence status. |

## Required B25 Scorecard

`production_ux_judge.dart` emits:

- `production-ux-criteria-scorecard.json`
- `production-ux-criteria-scorecard.md`

`b25_iteration_scorecard.dart` emits after every B25 pass:

- `b25-iteration-scorecard-<run-id>.json`
- `b25-iteration-scorecard-<run-id>.md`
- `b25-iteration-scorecard-latest.json`
- `b25-iteration-scorecard-latest.md`

B25 uses direct questions rather than only declarative pass criteria. The production judge must run:

1. **One holistic product UX pass** over the entire app/community experience.
2. **One workflow/persona pass for every reviewed workflow and persona pair.**

Both passes must be green before B25 can close. A holistic pass cannot excuse a weak workflow, and a set
of workflow passes cannot excuse a visually incoherent or non-production overall experience.

Each criterion row includes:

- `criterionId`
- `scope`
- `question`
- `score`
- `verdict`
- `blocksPass`
- `evidenceUsed`
- `why`
- `requiredFix`

B25 evidence must include:

- `holisticQuestionAnswers`: direct answers to whole-product questions about production feel, modern
  visual design, navigation, community-centered information architecture, and layout/content defects.
- `workflowPersonaScorecards`: direct-question scorecards for each workflow/persona pair, including
  task clarity, domain-native primary surface, natural actions, validation/error/result states,
  receiver/unauthorized states, and whether that workflow UI feels production-grade on its own.

B25 cannot pass from an average score. One unresolved blocker/major criterion failure blocks the phase.
The judge also fails if either direct-question evidence block is missing, weak, partial, or contradicted
by screenshot evidence.

The iteration scorecard does not replace the judge. It records whether the loop is converging:

- current critical/blocker, major, minor, and polish counts
- unresolved critical/blocker and major counts
- resolved critical/blocker and major findings in this pass
- new critical/blocker and major findings in this pass
- production judge status and blocking criterion failures
- holistic direct-question pass status
- workflow/persona direct-question pass status
- required next action before the next UX feedback/remediation loop

## B25 Direct Questions

Use direct questions because they force concrete judgment from the artifacts.

Holistic product UX pass:

- Does the whole experience feel like a real production community app for the target users, not merely
  an implemented workflow harness?
- Is the UI modern, easy to use, easy to navigate, and visually appealing for the target persona?
- Is the overall information architecture organized around community content and real jobs-to-be-done
  instead of workflow lists or validation surfaces?
- Does the visible UI avoid blocking or major overlap, clipping, crowding, default-scaffold,
  repeated-card, checklist-modal, and thin-content defects?

Workflow/persona pass, repeated for every workflow/persona pair:

- Can this persona immediately understand what they are supposed to do?
- Is the primary UI designed around the real community task rather than workflow mechanics?
- Is the primary surface domain-native, not a generic card, checklist modal, or metadata page?
- Are action labels natural and specific to the user job?
- Are required inputs, validation, empty/error/review states, and success/result states clear?
- If another persona receives or acts on the state, is that receiver UX clear?
- Are unauthorized, read-only, hidden, or disabled states appropriate for this persona?
- Does this workflow UI feel production-grade on its own?

Do not batch all workflow/persona questions into one giant answer. The UX Judge Agent may perform the
holistic pass once, then process workflow/persona groups in batches small enough to preserve fresh,
screen-specific critique. Each answer must cite visible evidence and explain why it passes or what must
change.

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

First answer the holistic direct questions for the entire app. Then answer the workflow/persona direct
questions for each reviewed workflow/persona pair. Score each criterion independently. Return pass only
when every blocking criterion passes, both direct-question passes are green, screenshots are fresh,
critiques are screen-specific, and primary workflow surfaces are domain-native.
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
