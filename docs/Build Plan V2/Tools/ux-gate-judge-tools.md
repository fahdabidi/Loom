# UX Gate Judge Tools

These tools separate implementation from pass/fail judgment. Worker agents may implement UI and tests,
but they do not grade their own work. Evidence collectors gather artifacts. Judge agents and deterministic
judge CLIs evaluate only those artifacts against the relevant phase standard. Remediation planners turn
judge failures into fix batches for the next worker iteration.

## Agent Split

| Role | Responsibility | Context allowed | Output |
| --- | --- | --- | --- |
| Worker Agent | Implements UX/code/test fixes. | Phase docs, code, failing judge reports, remediation plan. | Code, tests, screenshots, updated artifacts. |
| Product Experience Doc Steward | Creates or updates the community product experience doc before capture/remediation. | Loom Product Docs V2, Skill references, prior judge tickets, owner prompt, community examples. | Canonical Product Docs V2 community docs for native Loom runs, or local `docs/product/community-product-experience.md` for standalone Skill runs. |
| Evidence Collector Tool | Captures screenshots, hashes, visible text, app commit SHA, device metadata, command output. | Running app, emulator, artifact paths. No implementation rationale. | Evidence JSON and screenshot bundle. |
| Visual Inspection Auditor Tool | Deterministically inspects screenshot pixels/layout for repeated-card shells, checklist modals, weak visual identity, thin content, and missing image evidence. | Screenshot-backed evidence rows only. No implementation rationale. | `visualInspection` per screen row plus visual audit markdown. |
| Deterministic Review Scaffold | Normalizes schema v4 review evidence and carries deterministic visual audit results into rows. | Evidence artifacts, screenshots, pass criteria, blueprint/contracts. No worker implementation notes. | Review JSON scaffold, matrix, deterministic critiques. |
| LLM Vision UX Judge Agent | Reviews screenshots and artifacts with fresh context, answers direct UX questions from actual visible UI, and writes screen-specific critique. | Evidence artifacts, screenshots, pass criteria, blueprint/contracts. No worker implementation notes or source-code claims. | `llm-vision-ux-review-<run-id>.json` with holistic answers, screen reviews, and findings. |
| LLM Review Importer Tool | Imports the LLM judge output into schema v4 evidence and resolves affected screen row IDs. | LLM review JSON plus current B25 evidence. | `llmVisionReview` in `independent-production-ux-review.json`. |
| Workflow Interaction-Model Judge Tool | Scores whether each workflow/persona UI proves the correct semantic interaction model. | Screenshot-backed evidence rows, product docs, coverage rows, independent judge output. No worker implementation notes. | `workflowLifecycleScorecards`, `semanticInteractionModel`, interaction-model findings, lifecycle markdown. |
| Production UX Judge CLI | Deterministically validates the independent judge output against B25 pass criteria. | Machine-readable review JSON, scorecard schema, ticket template, screenshot metadata. | Criteria scorecard, pass/fail, remediation tickets. |
| Remediation Planner | Converts judge failures into right-sized fix batches. | Judge scorecard, findings, phase docs. | Remediation plan for Worker Agent. |

## Deterministic CLIs

Run from `app/` with WSL Ubuntu:

Before running the CLIs, complete the product-doc gate:

- Native Loom repo B25: create or update
  `docs/Product Docs V2/Community Examples/<community>-product-experience.md` for every reviewed
  community/test app.
- Standalone Skill B25-style validation: create or update
  `<extension-workspace>/docs/product/community-product-experience.md` and companion local UX/workflow/
  API-map docs. Do not mutate the fetched Loom repo's Product Docs V2.
- Use `docs/Build Plan V2/Skill/references/community-product-experience-template.md` for both flows.
- Record whether each remediation item is a `product-spec-gap`, `implementation-gap`, `evidence-gap`,
  or `mixed-gap`.

```powershell
wsl.exe -d Ubuntu -- bash -lc 'cd "/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app" && dart run packages/tooling/loom_ux_judges/bin/b25_capture_workflow_screenshots.dart --mode full-b25 --device emulator-5554 --evidence-root ../docs/Build\ Plan\ V2/Evidence'
wsl.exe -d Ubuntu -- bash -lc 'cd "/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app" && dart run packages/tooling/loom_ux_judges/bin/b25_capture_coverage_gate.dart --evidence-root ../docs/Build\ Plan\ V2/Evidence --output ../docs/Build\ Plan\ V2/Evidence/B25/b25-capture-coverage-report.json'
wsl.exe -d Ubuntu -- bash -lc 'cd "/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app" && dart run packages/tooling/loom_ux_judges/bin/b25_evidence_collector.dart --evidence-root ../docs/Build\ Plan\ V2/Evidence --repo-root .. --run-id b25-v4-pass-1 --prior-review ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --output ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.md --matrix-output ../docs/Build\ Plan\ V2/Evidence/B25/product-ux-screen-review-matrix.md'
wsl.exe -d Ubuntu -- bash -lc 'cd "/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app" && dart run packages/tooling/loom_ux_judges/bin/b25_workflow_persona_coverage_collector.dart --input ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --output ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/workflow-persona-coverage-matrix.md'
wsl.exe -d Ubuntu -- bash -lc 'cd "/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app" && dart run packages/tooling/loom_ux_judges/bin/b25_visual_inspection_auditor.dart --input ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --output ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/b25-visual-inspection-audit.md'
wsl.exe -d Ubuntu -- bash -lc 'cd "/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app" && dart run packages/tooling/loom_ux_judges/bin/b25_independent_ux_judge.dart --input ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --output ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.md --matrix-output ../docs/Build\ Plan\ V2/Evidence/B25/product-ux-screen-review-matrix.md'
wsl.exe -d Ubuntu -- bash -lc 'cd "/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app" && dart run packages/tooling/loom_ux_judges/bin/b25_llm_ux_review_importer.dart --input ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --llm-review ../docs/Build\ Plan\ V2/Evidence/B25/llm-vision-ux-review-<run-id>.json --run-id <run-id> --output ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.md --matrix-output ../docs/Build\ Plan\ V2/Evidence/B25/product-ux-screen-review-matrix.md'
wsl.exe -d Ubuntu -- bash -lc 'cd "/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app" && dart run packages/tooling/loom_ux_judges/bin/b25_workflow_interaction_model_judge.dart --input ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --output ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/b25-workflow-lifecycle-scorecards.md'
wsl.exe -d Ubuntu -- bash -lc 'cd "/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app" && dart run packages/tooling/loom_ux_judges/bin/production_ux_judge.dart --input ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --base .. --output ../docs/Build\ Plan\ V2/Evidence/B25/production-ux-criteria-scorecard.json --markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/production-ux-criteria-scorecard.md --tickets-output ../docs/Build\ Plan\ V2/Evidence/B25/b25-remediation-tickets-b25-v4-pass-1.json --tickets-markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/b25-remediation-tickets-b25-v4-pass-1.md'
wsl.exe -d Ubuntu -- bash -lc 'cd "/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app" && dart run packages/tooling/loom_ux_judges/bin/b25_iteration_scorecard.dart --review ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --judge ../docs/Build\ Plan\ V2/Evidence/B25/production-ux-criteria-scorecard.json --output ../docs/Build\ Plan\ V2/Evidence/B25/b25-iteration-scorecard-latest.json --markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/b25-iteration-scorecard-latest.md'
```

That sequence finishes the current pass. If the committed pass fails, the next pass starts by consuming
the prior pass's tickets:

```powershell
wsl.exe -d Ubuntu -- bash -lc 'cd "/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app" && dart run packages/tooling/loom_ux_judges/bin/b25_remediation_planner.dart --tickets ../docs/Build\ Plan\ V2/Evidence/B25/b25-remediation-tickets-b25-v4-pass-1.json --review ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --scorecard ../docs/Build\ Plan\ V2/Evidence/B25/b25-iteration-scorecard-latest.json --output ../docs/Build\ Plan\ V2/Evidence/B25/b25-remediation-plan-b25-v4-pass-2.json --markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/b25-remediation-plan-b25-v4-pass-2.md'
```

| Tool | Phase | Purpose |
| --- | --- | --- |
| `workflow_completeness_judge.dart` | B11 | Compare owner prompt, requested workflows, generated packages, Demo App validation, and completion report. |
| `ux_contract_judge.dart` | B21 | Validate production UX contract rows before implementation. |
| `domain_surface_classifier.dart` | B22 | Fail primary generic workflow cards/checklist/metadata surfaces. |
| `persona_ux_judge.dart` | B23 | Verify actor, receiver, read-only, disabled, hidden, and unauthorized persona evidence. |
| `evidence_integrity_auditor.dart` | B24 | Check screenshot path/hash/timestamp/app commit/device/visible text and generic-copy evidence. |
| `b25_capture_workflow_screenshots.dart` | B25 | Run the host-side `flutter drive` screenshot writer so fresh Android screenshots and workflow evidence manifests are persisted into `docs/Build Plan V2/Evidence`. Default `--mode full-b25` is the only commit-eligible canonical capture; `--mode targeted-precheck --phases <phase>` is diagnostic only. |
| `b25_capture_coverage_gate.dart` | B25 | Fail when canonical B25 evidence is not full B12-B20 coverage, not commit-eligible, missing workflow manifests, or below the screenshot threshold. |
| `b25_evidence_collector.dart` | B25 | Convert workflow UI evidence manifests into B25 schema v4 screenshot evidence with hashes, timestamps, device metadata, visible text source, and app commit SHA. |
| `b25_workflow_persona_coverage_collector.dart` | B25 | Verify the collected evidence has explicit entry/action/result screenshots for every workflow/persona combination before independent review. |
| `b25_visual_inspection_auditor.dart` | B25 | Decode screenshots and attach deterministic pixel/layout inspection results for checklist modals, repeated-card shells, weak identity, thin content, and missing images. |
| `b25_independent_ux_judge.dart` | B25 | Build the deterministic review scaffold and carry visual-inspection outputs into schema v4. It is not the final semantic product-quality judge. |
| `b25_llm_ux_review_importer.dart` | B25 | Import the fresh LLM Vision UX Judge artifact into `llmVisionReview` and fail/ticket when the LLM review finds blocker or major product UX issues. |
| `b25_workflow_interaction_model_judge.dart` | B25 | Fail workflow/persona UI that does not prove the right semantic interaction model: concrete object/context, decision information, domain-correct primary action, domain-required alternate/change/reject action, persistent result state, and receiver/continuation state. |
| `b25_workflow_lifecycle_judge.dart` | B25 | Compatibility alias for the interaction-model judge. Prefer `b25_workflow_interaction_model_judge.dart` in new B25 runs. |
| `production_ux_judge.dart` | B25 | Deterministically validate the independent judge output against every B25 production UX pass criterion and generate tickets for failed blocking criteria. |
| `b25_iteration_scorecard.dart` | B25 | Summarize each B25 review/remediation pass with current blocker/major counts, resolved counts, new counts, judge failures, and convergence status. |
| `b25_remediation_planner.dart` | B25 | Convert judge-generated remediation tickets into ordered worker-agent remediation batches. |

If `b25_visual_inspection_auditor.dart` exits nonzero, keep its output and continue the same B25 pass
through the independent UX judge and production UX judge so findings, tickets, and the iteration
scorecard are still produced. The nonzero visual-audit result blocks B25 closeout; it should not
truncate evidence generation.

## Required B25 Scorecard

`production_ux_judge.dart` emits:

- `production-ux-criteria-scorecard.json`
- `production-ux-criteria-scorecard.md`
- `b25-remediation-tickets-<run-id>.json`
- `b25-remediation-tickets-<run-id>.md`

Each remediation ticket includes:

- `ticketId`
- `ticketSchemaVersion`
- `phase`
- `reviewRunId`
- `status`
- `severity`
- `priority`
- failed source criterion
- related finding IDs
- direct question
- why it failed
- remediation mode
- worker readiness
- first required step
- implementation blockers
- affected scope: communities, personas, workflows, screen rows, and screenshots
- evidence-repair work items scoped by community/workflow/persona
- UI-remediation work items scoped by community/workflow/persona
- failing workflow interaction-model scorecards with expected decision, missing actions, wrong generic substitutes, missing lifecycle groups, and required screenshot proof
- user-facing problem statement
- root-cause hypothesis
- target experience
- UX principles
- concrete improvements
- implementation guidance
- content guidance
- visual guidance
- UX reference patterns to copy, including source name/type, URL, and what the implementer should copy
- reference research queries used or required to refresh internet/open-source examples
- affected evidence
- evidence to collect
- acceptance checks
- rerun commands
- non-goals
- commit boundary

The detailed schema and markdown shape live in
[b25-remediation-ticket-template.md](./b25-remediation-ticket-template.md). A ticket that only repeats
the failed criterion is invalid; it must give the remediation agent enough UI, content, evidence, and
acceptance context to implement the next pass.

`b25_iteration_scorecard.dart` emits after every B25 pass:

- `b25-iteration-scorecard-<run-id>.json`
- `b25-iteration-scorecard-<run-id>.md`
- `b25-iteration-scorecard-latest.json`
- `b25-iteration-scorecard-latest.md`

`b25_remediation_planner.dart` emits at the start of the next B25 remediation pass, using the prior
failed pass's tickets:

- `b25-remediation-plan-<run-id>.json`
- `b25-remediation-plan-<run-id>.md`

B25 uses direct questions rather than only declarative pass criteria. The production judge must validate:

1. **One holistic product UX pass** over the entire app/community experience.
2. **One workflow/persona pass for every reviewed workflow and persona pair.**
3. **One semantic workflow interaction-model pass for every reviewed workflow and persona pair.**
4. **One imported LLM vision UX review** that inspected screenshots as product UI and found no
   unresolved blocker or major issue.

All four passes must be green before B25 can close. A holistic pass cannot excuse a weak workflow, a
workflow/persona pass cannot excuse an incomplete or wrong interaction model, and a set of workflow
passes cannot excuse a visually incoherent or non-production overall experience. A deterministic pass
cannot substitute for the imported LLM vision review.

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
- `workflowLifecycleScorecards`: semantic interaction-model scorecards for each workflow/persona pair,
  including expected user decision, required primary actions, required alternate/change/reject actions,
  disallowed generic substitutes, visible primary/alternate actions, concrete object/context, decision
  information, persistent result state, receiver/continuation state, missing lifecycle groups, and
  screenshot evidence. These scorecards prevent accept/cancel action cards from passing as complete
  workflows.
- `semanticSurfaceProof`: one object on every workflow/persona scorecard proving the after screenshots
  visibly contain the requested target product surface elements. A scorecard cannot pass only because no
  known defect was detected. For example, an announcement surface must show audience or recipient group,
  author/sender attribution, message body, timestamp or delivery timing, receiver state, and natural
  publish/send/read action.
- `visualInspection`: one object on every screen row, produced from the screenshot pixels/layout, with
  metrics, signals, status, summary, and finding IDs. A missing or failed `visualInspection` blocks B25.
- `llmVisionReview`: the imported LLM Vision UX Judge artifact, including status, summary,
  holistic answers, screen reviews, findings, screenshot-backed visible evidence, and affected row IDs.
  A missing or failing `llmVisionReview` blocks B25.
- `productDocCoverage`: links each community/test app to the product experience doc used for review,
  records the doc commit or local artifact hash, and states whether the ticket is a product-spec gap or
  an implementation/evidence gap.
- `reviewInputEvidence.captureCoverage`: records `captureMode`, `fullB25Coverage`, `commitEligible`,
  expected/captured/missing phases, workflow manifest count, and screenshot count. Criterion
  `b25-c15-full-b25-capture-coverage` fails if this proves anything other than a full B12-B20 capture.

B25 cannot pass from an average score. One unresolved blocker/major criterion failure blocks the phase.
The judge also fails if either direct-question evidence block is missing, weak, partial, or contradicted
by screenshot evidence. A row with only `manual-visible-text-review` is not enough for B25 pass; visible
text must come from screenshot-derived OCR/extraction, not prior expected assertions.

The iteration scorecard does not replace the judge. It records whether the loop is converging:

- current critical/blocker, major, minor, and polish counts
- unresolved critical/blocker and major counts
- resolved critical/blocker and major findings in this pass
- new critical/blocker and major findings in this pass
- production judge status and blocking criterion failures
- holistic direct-question pass status
- workflow/persona direct-question pass status
- semantic workflow interaction-model scorecard pass status
- required next action before the next UX feedback/remediation loop

The remediation tickets do not replace the judge or scorecard either. They are committed with the failed
pass. At the start of the next pass, the tickets are sent to the Remediation Planner, and the planner
output becomes that next Worker Agent's fix backlog. A failed B25 pass without remediation tickets is
incomplete evidence; a remediation pass that begins without a planner output is also incomplete.
The planner must preserve sequencing: evidence-repair work items come first, then UI-remediation work
items for the same community/workflow/persona, then recapture/rerun/closeout. A Worker Agent should not
start broad UI changes from a ticket whose `workerReadiness` says evidence repair is still required.
The planner and worker cannot close tickets. Closure happens only after fresh after screenshots are
captured and the independent judge, interaction-model judge, production judge, and iteration scorecard
all show the ticket's target surface and semantic actions now pass.

For schema v4 tickets, the Independent UX Judge must also attach UX reference patterns. It should search
the internet or open-source projects for comparable production patterns when network access is
available, then record the selected references in `uxReferencePatterns` and the exact search terms in
`referenceResearchQueries`. The deterministic production judge carries those references into the
remediation tickets and remediation planner. If live research is unavailable, the generator falls back
to its built-in reference catalog, but the ticket must still list queries for the next reviewer to
refresh before UI remediation.

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
- Does the after screenshot prove the requested target product surface is actually present, with the
  required domain content and affordances, instead of merely avoiding known bad patterns?

Workflow interaction-model pass, repeated for every workflow/persona pair:

- Does the screen show the concrete object or record the user is acting on?
- Does the screen show enough domain information for the user to make a real decision?
- Is the primary action semantically correct and specific to the domain task?
- Does the workflow provide the domain-required alternate/change/reject/defer/undo path instead of only
  accept/cancel or submit/cancel?
- Does the expected interaction model name the decision being made and the actions that should exist?
- Are generic substitutes like `Accept`, `Cancel`, `Confirm`, `Continue`, or `Complete` rejected when
  they stand in for missing domain actions?
- After action, does the UI show a persistent result, receipt, status, history, or confirmation state?
- If another persona receives or continues the workflow, is the receiver/read-only/continuation state
  visible in the screenshots?
- Does the interaction-model proof pass from fresh after-screenshot visual evidence, not from
  implementation notes, source diffs, or ticket responses?

Do not batch all workflow/persona questions into one giant answer. The UX Judge Agent may perform the
holistic pass once, then process workflow/persona groups in batches small enough to preserve fresh,
screen-specific critique. Each answer must cite visible evidence and explain why it passes or what must
change.

## Judge Agent Prompt Contract

Use this prompt shape for the UX Judge Agent:

```text
You are a UX Judge Agent. You did not implement the UI.

Use only the supplied artifacts:
- community product experience docs
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

Inspect the actual screenshots as pixels and layout, not just JSON rows. Fail rows that visibly resemble
checklist/review modals, repeated generic card shells, thin-content surfaces, weak visual identity,
default-scaffold screens, or missing/undecodable screenshots. Treat `visualInspection.status=fail` as
direct evidence that the row cannot pass until the UI is redesigned and recaptured.
Before judging a screen, compare it to the relevant community product experience doc. If the product
doc does not define the surface, persona, required content, or acceptance criteria clearly enough to
judge the screenshot, mark a `product-spec-gap` and require the product doc to be updated before UI
remediation. If the product doc is clear and the screenshot fails to implement it, mark an
`implementation-gap`. If screenshots or visible text are missing/stale, mark an `evidence-gap`.
For remediated tickets, compare the before finding, target product surface, and after screenshots. Do
not close a ticket from implementation notes, code diffs, or absence of detected defects. Close it only
when the after screenshots visibly prove the requested domain surface and the scorecard's
`semanticSurfaceProof.status` is `pass`.

First answer the holistic direct questions for the entire app. Then answer the workflow/persona direct
questions for each reviewed workflow/persona pair. Score each criterion independently. Return pass only
when every blocking criterion passes, both direct-question passes are green, screenshots are fresh,
critiques are screen-specific, visual inspection passes, and primary workflow surfaces are domain-native.
```

## Remediation Planner Contract

The remediation planner does not implement remediations. It receives only committed judge failures,
remediation tickets, scorecards, and phase docs from the prior pass. It must output:

- root-cause cluster
- affected communities/screens/personas/workflows
- target production surface
- evidence-repair work items with concrete persona, screenshot, visible-text, and critique requirements
- UI-remediation work items with target production surface, likely files/widgets, worker actions, and
  concrete acceptance criteria
- files likely needing changes
- tests/evidence to rerun
- commit boundary for the iteration
- ticket IDs from `b25-remediation-tickets-<run-id>.json/.md`
- ordered remediation batch IDs from `b25-remediation-plan-<run-id>.json/.md`

The Worker Agent receives the remediation plan, not a softened pass/fail summary.
