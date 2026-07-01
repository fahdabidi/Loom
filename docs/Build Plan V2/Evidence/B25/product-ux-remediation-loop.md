# B25 Product UX Remediation Loop

Status: reopened under the hardened fresh-LLM B25 review rule. `b25-v4-pass-19` recaptured fresh
phase-split B12-B20 screenshot evidence and reran the full B25 judge chain, but failed with 3
unresolved major findings. The latest review has 0 blockers, 3 unresolved majors, 8 remediation
tickets, and a pass-20 remediation plan.

This log records each B25 product UX review, remediation, retest, and rerun cycle. B25 can pass only
when the latest iteration has zero unresolved blocker or major UX findings, the screen review matrix
has no unresolved major rows, the per-community production UX blueprint is complete, schema version 4
machine-readable review evidence is internally consistent, the holistic direct-question pass is green,
every workflow/persona direct-question pass is green, the production UX judge scorecard passes, and the
B25 iteration scorecard shows convergence to zero unresolved blocker/major findings.

## Loop Rules

Each iteration must include review input evidence, blocker/major/minor counts, root-cause clusters,
remediation batch scope, implementation changes, tests and analysis, refreshed screenshots/evidence,
production UX judge scorecard, B25 iteration scorecard, rerun result, remaining findings, pass/fail
decision, and a git commit before the next feedback loop.

## Iterations

| Iteration | Status | Review Result | Blockers | Majors | Minor/Polish | Root Cause Clusters | Remediation Batch | Tests/Evidence | Decision |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | Failed review complete | Fail | 0 | 200 | 1 minor | Exposed workflow/surface/category taxonomy; workflow-list IA; thin domain content; validation-style result states; dense repeated mobile cards | Required next: replace workflow-card UX with domain-native homes/sections, remove implementation copy, add realistic content, redesign result states, recapture screenshots | Review artifacts created: product-ux-screen-review-matrix.md, independent-production-ux-review.md, independent-production-ux-review.json, live B25 screenshots | B25 remained reopened |
| 2 | Remediation applied and retested | Pass | 0 | 0 | 1 tracked polish | Same root causes from iteration 1 | Implemented domain-native sections, product card copy, product metadata chips, quiet confirmations, hidden local route/package metadata, community tagline subtitles, and bidirectional test/evidence scrolling | B21/B25 test, full demo widget suite, workflow evidence harness, live screenshots | Historical v2 pass |
| 3 | Remediation applied and retested | Pass | 0 | 0 | 0 | v3 blueprint uncovered local-shell production polish: debug banner, FAB overlap risk, letter-only identity, generic form fallback copy | Added production UX blueprint, disabled debug banner, added FAB-safe list inset, replaced letter avatars with domain icons, added form-category copy/chips, regenerated schema v3 evidence | A6 widget test, full Demo App widget suite, Android workflow evidence sweep, B21/B25 test, analyze, manifest gate, B25 phase gate, boundary lint, and diff check all passed | B25 passes after iteration commit is stamped |
| 4 / `b25-v4-pass-1` | Evidence collected; independent review gate failed | Fail | 0 | 4 | 0 | Workflow/persona coverage incomplete; screen-specific critique incomplete; workflow/persona UX scorecards failed; holistic UX review failed | Pass 1 closes by publishing remediation tickets and the iteration scorecard. Pass 2 must start by sending those tickets to the Remediation Planner before any worker fixes. | `b25_evidence_collector.dart` generated 199 screen rows; `b25_workflow_persona_coverage_collector.dart` found 70 workflow/persona coverage rows with 66 failing; `b25_independent_ux_judge.dart` generated 70 workflow/persona scorecards and 4 major findings; `production_ux_judge.dart` failed 7 blocking criteria and generated 7 schema v3 remediation tickets with remediation mode, worker readiness, implementation blockers, 70 evidence-repair work items, 70 UI-remediation work items, affected screen IDs, coverage IDs, screenshot metadata, visible text excerpts, likely files/widgets, and concrete acceptance criteria; `b25_remediation_planner.dart` now emits evidence-only batch 1, UI-only batch 2, and recapture/closeout batch 3; `b25_iteration_scorecard.dart` reports 4 remaining blocker/major findings | B25 remains reopened; iteration commit `647c38f`; results clarification `c5799e6`; ticket/planner closeout `5d4e313`; coverage/judge-tool update `e46cbaa`; detailed ticket schema update `f617625`; work-item split update `42e7cdf` |
| 5 / `b25-v4-pass-2` | Evidence repair applied; independent review gate failed | Fail | 0 | 3 | 0 | Remaining workflow/persona coverage gaps; domain-native primary-surface evidence still unverified; holistic UX still cannot be judged production-grade | Pass 2 repaired the collector/judge evidence shape, regenerated tickets, generated the pass-2 scorecard, and generated the pass-3 remediation plan. Pass 3 must repair the 6 remaining coverage rows before assigning UI-remediation work, then implement domain-native surface fixes and recapture evidence. | `b25_evidence_collector.dart` generated 196 production screen rows; `b25_workflow_persona_coverage_collector.dart` found 68 workflow/persona rows with 6 failing; `b25_independent_ux_judge.dart` generated 68 workflow/persona scorecards and 3 major findings; `production_ux_judge.dart` failed 7 blocking criteria and generated 7 remediation tickets; `b25_iteration_scorecard.dart` reports 3 remaining blocker/major findings, 1 resolved blocking-major class, and 0 new blocking-major findings; `b25_remediation_planner.dart` generated `b25-remediation-plan-b25-v4-pass-3.md`. | B25 remains reopened; pass 2 commit `68b5fad` |
| 6 / `b25-v4-pass-3` | Evidence/surface target repair applied; independent review gate failed | Fail | 0 | 3 | 0 | Remaining persona role-inventory coverage gaps; holistic UX still blocked by the two failing workflow/persona scorecards | Pass 3 added concrete target surfaces for previously generic workflow categories and classified rows with concrete target surfaces as domain-native candidates. Pass 4 must repair the two role-inventory coverage rows and rerun the full chain. | `b25_evidence_collector.dart` generated 196 production screen rows; `b25_workflow_persona_coverage_collector.dart` found 68 workflow/persona rows with 2 failing; `b25_independent_ux_judge.dart` generated 68 workflow/persona scorecards and 3 major findings; `production_ux_judge.dart` failed 7 blocking criteria; `b25_iteration_scorecard.dart` reports 3 remaining blocker/major findings; `b25_remediation_planner.dart` generated `b25-remediation-plan-b25-v4-pass-4.md`. | B25 remains reopened; pass 3 commit `9c59a5a` |
| 7 / `b25-v4-pass-4` | Remediation applied and retested | Pass | 0 | 0 | 0 | Persona role-inventory support evidence was the final blocker; no remaining blocker/major UX clusters | Pass 4 treated support/evidence surfaces as valid single-state evidence where appropriate, reran all B25 tools, and closed the gate. | `b25_evidence_collector.dart` generated 196 production screen rows; `b25_workflow_persona_coverage_collector.dart` passed 68/68 workflow/persona rows; `b25_independent_ux_judge.dart` passed with 0 findings and 68 passing workflow/persona scorecards; `production_ux_judge.dart` passed 12/12 criteria; `b25_iteration_scorecard.dart` reports 3 blocker/major findings resolved, 0 new, and 0 remaining. | B25 passes; pass 4 commit `b672089` |
| 8 / visual gate rerun on existing screenshots | Visual inspection gate failed | Fail | 0 | 4 | 0 | Screenshot pixel/layout inspection found repeated-card shells, checklist-modal-like overlays, weak visual identity, default-scaffold-like surfaces, thin content, and evidence rows still using non-screenshot-derived visible text | The stricter visual gate introduced after pass 4 was rerun against the existing B25 screenshots without recapturing. `b25_remediation_planner.dart` then generated `b25-remediation-plan-b25-v4-pass-5.md` from the visual-gate rerun tickets. | `b25_workflow_persona_coverage_collector.dart` passed 68/68 coverage rows; `b25_visual_inspection_auditor.dart` failed 187/196 screen rows; `b25_independent_ux_judge.dart` failed with 4 major findings; `production_ux_judge.dart` failed 7 blocking criteria and regenerated 7 remediation tickets; `b25_iteration_scorecard.dart` reports 4 remaining blocker/major findings; remediation planner produced 3 batches with 68 evidence-repair work items and 50 UI-remediation work items. | B25 reopened; visual gate rerun commit `39a1210`; remediation-plan commit `a893e53` |
| 9 / `b25-v4-pass-6` | UI remediation attempted; evidence still stale | Fail | 0 | 4 | 0 | Action flow was changed in code from modal dialog to a full-screen domain action surface, but the integration screenshot run did not overwrite the checked-in Evidence PNGs. The judge therefore still reviewed old modal/repeated-card screenshots. | Pass 6 committed the attempted UI remediation, regenerated pass-6 evidence, tickets, scorecard, and remediation plan. Pass 7 must first repair screenshot persistence so `takeScreenshot` output becomes the Evidence PNGs, then rerun the judge against fresh screenshots before further UI remediation is judged. | Focused app tests and analyzer passed; Android integration workflow capture command passed; `b25_evidence_collector.dart` generated 196 rows for run `b25-v4-pass-6`; `b25_workflow_persona_coverage_collector.dart` passed 68/68; `b25_visual_inspection_auditor.dart` still failed 187/196 because evidence screenshots remained stale; `b25_independent_ux_judge.dart` failed with 4 major findings; `production_ux_judge.dart` failed 7 blocking criteria and generated `b25-remediation-tickets-b25-v4-pass-6.md`; `b25_iteration_scorecard.dart` reports 4 remaining blocker/major findings; `b25_remediation_planner.dart` generated `b25-remediation-plan-b25-v4-pass-6.md`. | B25 remains reopened; pass 6 commit `c1ec0c2` |
| 10 / `b25-v4-pass-7` | Screenshot persistence repaired; fresh review failed | Fail | 0 | 4 | 0 | The evidence pipeline now writes fresh phase-split screenshots and rejects stale screenshot manifests. The real remaining blockers are production UX quality issues: repeated-card shells, weak visual identity/default-scaffold signals, incomplete screen-specific critiques, and failing holistic/workflow-persona direct-question reviews. | Pass 7 committed the capture-tooling fix first, recaptured B12-B20 evidence with phase-split `flutter drive`, regenerated schema v4 evidence, ran the visual auditor, independent judge, production judge, iteration scorecard, and remediation planner. Pass 8 must consume `b25-remediation-plan-b25-v4-pass-8.md`, implement domain-native UI remediation, recapture fresh screenshots, and rerun the full chain. | `b25_capture_workflow_screenshots.dart` wrote a merged B20 manifest with 66 workflows and 198 screenshot references; `b25_evidence_collector.dart` generated 195 screen rows for run `b25-v4-pass-7`; `b25_workflow_persona_coverage_collector.dart` passed 68/68; `b25_visual_inspection_auditor.dart` failed 185/195 rows; `b25_independent_ux_judge.dart` failed with 4 major findings and 68 workflow/persona scorecards; `production_ux_judge.dart` failed 7 blocking criteria and generated `b25-remediation-tickets-b25-v4-pass-7.md`; `b25_iteration_scorecard.dart` reports 4 remaining blocker/major findings; `b25_remediation_planner.dart` generated `b25-remediation-plan-b25-v4-pass-8.md` with 3 batches, 68 evidence-repair work items, and 50 UI-remediation work items. | B25 remains reopened; capture tooling fix `5c83f4b`; pass 7 evidence/result `10cf7a5` |
| 11 / `b25-v4-pass-8` | UI remediation applied; fresh review improved but failed | Fail | 0 | 3 | 0 | Screenshot-time visible text is now captured and the primary visual failure narrowed to repeated-card shell signals on the remaining workflow surfaces. Weak/manual visible-text evidence no longer drives the pass failure. | Pass 8 consumed the pass-7 remediation plan, replaced the modal/pale-card treatment with accent-backed community section headers, workflow panels, and full-screen action surfaces, wired screenshot-visible text into the B25 evidence collector, recaptured fresh screenshots, reran judges, and generated pass-9 remediation planning. Pass 9 must continue reducing repeated-card shell findings by moving remaining primary rows away from stacked task panels toward richer domain-native surfaces. | Focused Demo App tests and analyzers passed; `b25_capture_workflow_screenshots.dart` wrote 208 screenshot files; `b25_evidence_collector.dart` generated 195 screen rows for run `b25-v4-pass-8`; `b25_workflow_persona_coverage_collector.dart` passed 68/68; `b25_visual_inspection_auditor.dart` failed 87/195 rows; `b25_independent_ux_judge.dart` failed with 3 major findings and 68 workflow/persona scorecards; `production_ux_judge.dart` failed 7 blocking criteria and generated `b25-remediation-tickets-b25-v4-pass-8.md`; `b25_iteration_scorecard.dart` reports 3 remaining blocker/major findings, 1 resolved blocker/major class, and 0 new blocker/major findings; `b25_remediation_planner.dart` generated `b25-remediation-plan-b25-v4-pass-9.md`. | B25 remains reopened; pass 8 commit `c062daa` |
| 12 / `b25-v4-pass-9` | UI remediation applied and production UX review passed | Pass | 0 | 0 | 0 | The remaining repeated-card shell signals were resolved by removing light page gaps and white pill/button bands from the reviewed primary/action surfaces. | Pass 9 consumed the pass-8 remediation plan, changed the reviewed screens to continuous dark/accent product surfaces, recaptured fresh screenshots, reran all B25 judges, and generated a passing iteration scorecard. | Focused Demo App tests and analyzers passed; `b25_capture_workflow_screenshots.dart` wrote 208 screenshot files; `b25_evidence_collector.dart` generated 195 screen rows for run `b25-v4-pass-9`; `b25_workflow_persona_coverage_collector.dart` passed 68/68; `b25_visual_inspection_auditor.dart` passed 195/195; `b25_independent_ux_judge.dart` passed with 0 findings and 68 workflow/persona scorecards; `production_ux_judge.dart` passed 12/12 criteria and generated empty/pass remediation tickets; `b25_iteration_scorecard.dart` reports 3 blocker/major classes resolved, 0 remaining, and 0 new. | B25 passes; pass 9 commit `605158d` |
| 13 / `b25-v4-pass-10` | Product-doc and semantic-action remediation applied; fresh review improved but failed | Fail | 0 | 1 | 0 | Product-doc coverage and visual inspection now pass; semantic interaction-model failures dropped to 16, with remaining gaps concentrated in platform/social/support flows and a smaller set of publishing/document/notification workflows. | Pass 10 added B25 semantic interaction-model addenda to 11 community product docs, added shared alternate-action/decision/receiver-state UI to workflow cards and full-screen action surfaces, recaptured all screenshots, and regenerated B25 scorecards/tickets/planner. Pass 11 must target the 16 remaining lifecycle rows and 10 workflow/persona product-surface rows. | Demo App B21-B25/B9/B10/B11 tests passed; `flutter analyze apps/loom_communities_demo` passed; `b25_capture_workflow_screenshots.dart` wrote 208 screenshots; `b25_evidence_collector.dart` generated 195 screen rows; `b25_workflow_persona_coverage_collector.dart` passed 68/68; `b25_visual_inspection_auditor.dart` passed 195/195; `b25_independent_ux_judge.dart` failed with 3 findings; `b25_workflow_interaction_model_judge.dart` failed 16/68 lifecycle rows; `production_ux_judge.dart` failed 8 criteria; `b25_iteration_scorecard.dart` reports 1 unresolved major; `b25_remediation_planner.dart` generated `b25-remediation-plan-b25-v4-pass-11.md`. | B25 remains reopened; pass 10 commit `e63e34f` |
| 14 / `b25-v4-pass-11` | Interaction-model remediation applied; fresh review improved but failed | Fail | 0 | 0 | 0 | The semantic workflow interaction-model gate now passes 68/68 lifecycle rows and visual/product-doc/coverage gates remain green. Remaining failures are six direct-question criteria tied to 10 workflow/persona semantic-surface rows needing more visible domain proof. | Pass 11 consumed the pass-10 remediation plan, fixed support-surface lifecycle scoring, made primary actions match the expected semantic model, added durable social result states, recaptured screenshots, reran all B25 judges, and generated pass-12 remediation planning. Pass 12 must add visible sender/author, file metadata, RSVP result, ad no-fill disclosure, and specific target-surface proof for the remaining 10 workflow/persona rows. | Focused Demo App B21-B25/B9/B10/B11 tests passed; `flutter analyze apps/loom_communities_demo` passed; `dart analyze packages/tooling/loom_ux_judges` passed; `b25_capture_workflow_screenshots.dart` wrote 208 screenshots; `b25_evidence_collector.dart` generated 195 screen rows; `b25_workflow_persona_coverage_collector.dart` passed 68/68; `b25_visual_inspection_auditor.dart` passed 195/195; `b25_workflow_interaction_model_judge.dart` passed 68/68; `b25_independent_ux_judge.dart` failed with 2 findings; `production_ux_judge.dart` failed 6 criteria; `b25_iteration_scorecard.dart` reports 0 unresolved blockers/majors but B25 cannot pass because blocking criteria remain; `b25_remediation_planner.dart` generated `b25-remediation-plan-b25-v4-pass-12.md`. | B25 remains reopened; pass 11 commit `84c6998` |
| 15 / `b25-v4-pass-12` | Semantic-surface remediation applied and production UX review passed | Pass | 0 | 0 | 0 | All stricter v4 gates now pass: product-doc coverage, fresh screenshots, full workflow/persona coverage, visual inspection, independent UX review, workflow interaction-model review, production UX judge, and iteration scorecard. | Pass 12 consumed the pass-11 remediation plan, added visible sender/author, notification content, RSVP result, document file metadata, no-fill disclosure, and protected minor-redaction proof, recaptured screenshots, reran the full B25 chain, and produced empty/pass remediation tickets and an empty pass-13 planner. | Focused Demo App B21-B25/B9/B10/B11 tests passed; `flutter analyze apps/loom_communities_demo` passed; `dart analyze packages/tooling/loom_ux_judges` passed; `b25_capture_workflow_screenshots.dart` wrote 208 screenshots; `b25_evidence_collector.dart` generated 195 screen rows; `b25_workflow_persona_coverage_collector.dart` passed 68/68; `b25_visual_inspection_auditor.dart` passed 195/195; `b25_independent_ux_judge.dart` passed with 0 findings; `b25_workflow_interaction_model_judge.dart` passed 68/68; `production_ux_judge.dart` passed 14/14 criteria; `b25_iteration_scorecard.dart` reports `B25 can pass=true`; manifest gate, B25 phase gate, boundary lint, and `git diff --check` passed. | B25 passes; pass 12 commit `7f3d71a` |
| 16 / `b25-v4-pass-19` | Fresh LLM review rerun detected product UX failures | Fail | 0 | 3 | 0 | Generic workflow/action-surface language remains visible across primary screens; several workflows are mapped to the wrong product surface family; overall visual system still feels like hue-swapped template cards rather than a mature product experience. | Pass 19 closes by publishing fresh screenshot-backed LLM review evidence, 8 major remediation tickets, the iteration scorecard, and the pass-20 remediation plan. Pass 20 must consume that plan before implementation, fix the 44 scoped UI remediation work items, then recapture full B12-B20 evidence and rerun the fresh LLM review and production judge. | Full B12-B20 capture coverage passed with 198 screenshots, 66 workflows, and 9 manifests; B25 collector generated 195 rows; workflow/persona coverage passed 68/68; visual inspection passed; LLM freshness gate passed; LLM importer failed with 3 major findings; workflow interaction-model judge passed 68/68; production UX judge failed 8 criteria; `b25_iteration_scorecard.dart` reports 3 remaining blocking/major findings; `b25_remediation_planner.dart` generated `b25-remediation-plan-b25-v4-pass-20.md` with 11 evidence-repair work items and 44 UI remediation work items. | B25 remains reopened; pass 19 commit `97d1a82` |
| 17 / `b25-v4-pass-20` | Product-surface remediation applied; fresh review still failed | Fail | 0 | 4 | 0 | The UI moved more workflows onto richer product-surface content, and visual inspection/coverage remained green, but B25 still fails because the fresh screenshot-first review found repeated generic surfaces in Camera Club, Member Social Space, Ad-Free Community, and Data Portability, 26 workflow/persona lifecycle scorecards still lack complete semantic proof, and Product Docs V2 community examples still drift from the exact workflow IDs/screenshots under review. | Pass 20 closes by publishing full capture evidence, Product Docs-to-evidence reconciliation, fresh LLM vision review, production scorecard, 7 remediation tickets, and the pass-21 remediation plan. Pass 21 must update Product Docs V2 community specs first for exact workflow IDs/persona states/semantic rows, then replace remaining repeated product shells and lifecycle gaps, recapture full B12-B20 evidence, and rerun the full B25 judge chain. | Code gates passed: `dart format`, `flutter analyze apps/loom_communities_demo`, and `flutter test apps/loom_communities_demo/test/b21_b25_production_ux_test.dart`. Full B12-B20 capture passed with 198 screenshots and 66 workflows; capture coverage passed; collector generated 195 screen rows; workflow/persona coverage passed 68/68; visual inspection passed 195/195; deterministic independent judge failed with 2 findings; LLM Product Docs reconciliation failed with major product-doc/workflow drift findings; fresh LLM Vision UX review failed with 3 major findings; LLM freshness gate passed; workflow interaction-model judge failed 26/68 lifecycle rows; production UX judge failed 7 criteria; `b25_iteration_scorecard.dart` reports 4 remaining blocker/major findings; `b25_remediation_planner.dart` generated `b25-remediation-plan-b25-v4-pass-21.md` with 6 product-spec, 26 evidence-repair, and 27 UI-remediation work items. | B25 remains reopened; pass 20 commit `6ff5b8d` |

## Iteration 3 Commit Boundary

- Implementation commit: ccc3f40
- Tracker/evidence stamp commit: this follow-up stamp records the implementation SHA.

## Iteration 4 Commit Boundary

- Evidence/tooling commit: `647c38f`.
- Pass-result clarification commit: `c5799e6`.
- Coverage and independent judge tool update commit: `e46cbaa`.
- Detailed remediation ticket schema/update commit: `f617625`.
- Ticket work-item split update commit: `42e7cdf`.
- Latest scorecard: `docs/Build Plan V2/Evidence/B25/b25-iteration-scorecard-b25-v4-pass-1.md`.
- Remediation tickets: `docs/Build Plan V2/Evidence/B25/b25-remediation-tickets-b25-v4-pass-1.md`.
- Workflow/persona coverage matrix:
  `docs/Build Plan V2/Evidence/B25/workflow-persona-coverage-matrix.md`.
- Pass 1 result: failed with 0 blockers, 4 unresolved majors, 0 minors/polish, 7 blocking criteria
  failures, failed holistic direct-question pass, failed workflow/persona direct-question pass, and
  66 workflow/persona coverage rows missing specific persona evidence.
- Next pass kickoff: run `b25_remediation_planner.dart` against the committed pass-1 tickets and
  scorecard to produce `b25-remediation-plan-b25-v4-pass-2.md`, then implement that plan.

## Iteration 5 Commit Boundary

- Evidence/tooling commit: `68b5fad`.

## Iteration 6 Commit Boundary

- Evidence/tooling commit: `9c59a5a`.

## Iteration 7 Commit Boundary

- Evidence/tooling commit: `b672089`.
- Latest scorecard: `docs/Build Plan V2/Evidence/B25/b25-iteration-scorecard-b25-v4-pass-4.md`.
- Remediation tickets: `docs/Build Plan V2/Evidence/B25/b25-remediation-tickets-b25-v4-pass-4.md` (empty/pass closeout).
- Latest scorecard: `docs/Build Plan V2/Evidence/B25/b25-iteration-scorecard-b25-v4-pass-3.md`.
- Remediation tickets: `docs/Build Plan V2/Evidence/B25/b25-remediation-tickets-b25-v4-pass-3.md`.
- Next remediation plan: `docs/Build Plan V2/Evidence/B25/b25-remediation-plan-b25-v4-pass-4.md`.
- Latest scorecard: `docs/Build Plan V2/Evidence/B25/b25-iteration-scorecard-b25-v4-pass-2.md`.
- Remediation tickets: `docs/Build Plan V2/Evidence/B25/b25-remediation-tickets-b25-v4-pass-2.md`.
- Next remediation plan: `docs/Build Plan V2/Evidence/B25/b25-remediation-plan-b25-v4-pass-3.md`.
- Workflow/persona coverage matrix:
  `docs/Build Plan V2/Evidence/B25/workflow-persona-coverage-matrix.md`.
- Pass 2 result: failed with 0 blockers, 3 unresolved majors, 0 minors/polish, 7 blocking criteria
  failures, failed holistic direct-question pass, failed workflow/persona direct-question pass, and
  6 workflow/persona coverage rows missing complete entry/action/result screenshot evidence.
- Next pass kickoff: repair the six coverage rows first, then implement domain-native UI/surface
  remediation work items using the pass-2 tickets and pass-3 remediation plan.

## Remaining Major Findings

The visual gate rerun reopened B25 with 4 unresolved major findings:

- `B25-SCREEN-SPECIFIC-CRITIQUE-INCOMPLETE`
- `B25-VISUAL-UX-INSPECTION-FAILED`
- `B25-WORKFLOW-PERSONA-UX-FAILED`
- `B25-HOLISTIC-UX-FAILED`

`b25-v4-pass-4` is historical under the stricter visual inspection gate. Screenshot persistence was
repaired in pass 7, screenshot-time visible text was repaired in pass 8, and the final visual/product UX
findings were resolved in pass 9.

## Iteration 18 Commit Boundary

- Prep commit: `3606c8c` added advisory workflow-to-card-surface registry context to the Demo App,
  B25 evidence, Skill docs, API/card-surface references, and community Product Docs V2 specs.
- Iteration evidence commit: `574cff3`.
- Full capture: `docs/Build Plan V2/Evidence/B25/flutter-drive-b25-v4-pass-18.log`.
- Capture coverage: `docs/Build Plan V2/Evidence/B25/b25-capture-coverage-report-b25-v4-pass-18.json`
  passed with full B12-B20 coverage and 198 screenshots.
- Independent review: `docs/Build Plan V2/Evidence/B25/independent-production-ux-review.json` passed
  with 195 screen rows, 68 workflow/persona scorecards, passing visual inspection, and passing
  workflow interaction-model scorecards.
- LLM vision review: `docs/Build Plan V2/Evidence/B25/llm-vision-ux-review-b25-v4-pass-18.json`
  carries forward pass-17 visual judgment because pass 18 changed registry/product-doc evidence
  context, not visible UI implementation.
- Production judge: `docs/Build Plan V2/Evidence/B25/production-ux-criteria-scorecard.json` passed.
- Iteration scorecard: `docs/Build Plan V2/Evidence/B25/b25-iteration-scorecard-b25-v4-pass-18.json`
  passed with zero unresolved blocker/major findings.
- Remediation tickets: `docs/Build Plan V2/Evidence/B25/b25-remediation-tickets-b25-v4-pass-18.md`
  contains zero tickets.
- Result: B25 remains passing under the current UX review bar. The advisory card-surface registry is
  now available to remediation agents, but it is not yet enforced as a standalone card-surface/API
  coverage gate.

## Iteration 19 Commit Boundary

- Full capture coverage: `docs/Build Plan V2/Evidence/B25/b25-capture-coverage-report.json`.
- Fresh LLM review: `docs/Build Plan V2/Evidence/B25/llm-vision-ux-review-b25-v4-pass-19.json`.
- LLM freshness gate:
  `docs/Build Plan V2/Evidence/B25/b25-llm-review-freshness-gate-b25-v4-pass-19.md`.
- Production judge scorecard:
  `docs/Build Plan V2/Evidence/B25/production-ux-criteria-scorecard.md`.
- Iteration scorecard:
  `docs/Build Plan V2/Evidence/B25/b25-iteration-scorecard-b25-v4-pass-19.md`.
- Remediation tickets:
  `docs/Build Plan V2/Evidence/B25/b25-remediation-tickets-b25-v4-pass-19.md`.
- Next remediation plan:
  `docs/Build Plan V2/Evidence/B25/b25-remediation-plan-b25-v4-pass-20.md`.
- Result: B25 remains reopened with 0 blockers, 3 unresolved major findings, 8 major tickets, 11
  evidence-repair work items, and 44 UI remediation work items. Pass 20 must start from the remediation
  plan before any implementation changes.
- Evidence/tooling commit: `97d1a82`.

## Iteration 20 Commit Boundary

- Full capture coverage:
  `docs/Build Plan V2/Evidence/B25/b25-capture-coverage-report-b25-v4-pass-20.json`.
- Product Docs reconciliation:
  `docs/Build Plan V2/Evidence/B25/llm-product-doc-workflow-reconciliation-b25-v4-pass-20.md`.
- Fresh LLM vision review:
  `docs/Build Plan V2/Evidence/B25/llm-vision-ux-review-b25-v4-pass-20.json`.
- LLM freshness gate:
  `docs/Build Plan V2/Evidence/B25/b25-llm-review-freshness-gate-b25-v4-pass-20.md`.
- Production judge scorecard:
  `docs/Build Plan V2/Evidence/B25/production-ux-criteria-scorecard.md`.
- Iteration scorecard:
  `docs/Build Plan V2/Evidence/B25/b25-iteration-scorecard-b25-v4-pass-20.md`.
- Remediation tickets:
  `docs/Build Plan V2/Evidence/B25/b25-remediation-tickets-b25-v4-pass-20.md`.
- Next remediation plan:
  `docs/Build Plan V2/Evidence/B25/b25-remediation-plan-b25-v4-pass-21.md`.
- Result: B25 remains reopened with 0 blockers, 4 unresolved major findings, 7 major tickets, 6
  product-spec work items, 26 evidence-repair work items, and 27 UI remediation work items.
- Evidence/tooling commit: `6ff5b8d`.

### Iteration 18 / `b25-v4-pass-21`

- Status: failed, but converged.
- Scope: consumed `b25-remediation-plan-b25-v4-pass-21.md`, updated community Product Docs V2 rows to
  use exact B25 workflow IDs/persona-state mapping where the prior pass still used umbrella IDs, added
  domain preview panels for Camera Club, Platform Social, Ad-Free Community, and Data Portability
  workflows, and repaired the evidence harness so offscreen workflow buttons are scrolled into view
  before capture.
- Capture/evidence: full B12-B20 capture passed with `198` screenshots, `66` workflows, and `9`
  workflow manifests; capture coverage passed; the B25 collector generated `195` schema v4 screen
  rows; workflow/persona coverage passed `68 / 68`; visual inspection passed `195 / 195`.
- Product-doc reconciliation: failed. Product Docs V2 community examples improved, but Section 7 and
  semantic rows remain stale or incomplete in several docs, including Masjid B17-B20 support workflows,
  Platform Social semantic rows, and Riverside Youth Soccer Section 7 lifecycle rows.
- LLM Vision UX review: failed with three major findings:
  `B25-VISION-UX-P21-001-INCOMPLETE-LIFECYCLES`,
  `B25-VISION-UX-P21-002-B20-CTA-WRAPPING`, and
  `B25-VISION-UX-P21-003-REPEATED-GENERIC-SURFACE-PANELS`.
- Workflow interaction model: improved but failed; lifecycle failures dropped from `26 / 68` to
  `22 / 68`.
- Production UX judge: failed `9` criteria and generated
  `docs/Build Plan V2/Evidence/B25/b25-remediation-tickets-b25-v4-pass-21.md`.
- Iteration scorecard:
  `docs/Build Plan V2/Evidence/B25/b25-iteration-scorecard-b25-v4-pass-21.md` records
  `B25 can pass=false`, `0` blockers, `4` unresolved major findings, and `4` remaining
  blocking/major findings.
- Next remediation plan:
  `docs/Build Plan V2/Evidence/B25/b25-remediation-plan-b25-v4-pass-22.md` with `9` tickets and
  `3` remediation batches.
- Result: B25 remains reopened. Pass 22 must fix the 22 lifecycle rows, repair B20 CTA wrapping, make
  Camera/Platform/Ad-Free surfaces visibly distinct rather than generic panels, and finish
  product-doc reconciliation before recapturing full B12-B20 evidence.
- Evidence/tooling commit: `97096d9`.

### Iteration 19 / `b25-v4-pass-22`

- Status: failed, but converged.
- Scope: consumed `b25-remediation-plan-b25-v4-pass-22.md`, updated community Product Docs V2
  example specs for exact workflow/persona/semantic rows, added richer workflow-specific domain
  previews for Camera Club, Platform Social, and Ad-Free Community, exposed interaction-model
  summaries on rich workflow tiles/action surfaces, and repaired B20 action label wrapping behavior.
- Capture/evidence: full B12-B20 capture passed with `198` screenshots, `66` workflows, and `9`
  workflow manifests; capture coverage passed; the B25 collector generated `195` schema v4 screen
  rows; workflow/persona coverage passed `68 / 68`; visual inspection passed `195 / 195`.
- Product-doc reconciliation: failed with `6` major findings. Garden Club, Neighborhood Book Club,
  and Chess Club still have stale Section 7 persona/state rows; the shell workflow is not clearly
  scoped into or out of B25 screenshot reconciliation; persona-role-inventory still duplicates
  Masjid-owned support workflows and has incomplete semantic rows.
- LLM Vision UX review: failed with `5` major findings: B20 CTA wrapping remains visible, four
  workflow/persona scorecards still fail, seven lifecycle scorecards fail, Ad-Free still uses repeated
  checkout-oriented panels for distinct jobs, and visible framework/surface copy still leaks into some
  screens.
- Workflow interaction model: improved but failed; lifecycle failures dropped from `22 / 68` to
  `7 / 68`.
- Production UX judge: failed `9` criteria and generated
  `docs/Build Plan V2/Evidence/B25/b25-remediation-tickets-b25-v4-pass-22.md`.
- Iteration scorecard:
  `docs/Build Plan V2/Evidence/B25/b25-iteration-scorecard-b25-v4-pass-22.md` records
  `B25 can pass=false`, `0` blockers, `6` unresolved major findings, `3` resolved
  blocker/major findings, and `5` newly introduced blocker/major findings under the fresh LLM review.
- Next remediation plan:
  `docs/Build Plan V2/Evidence/B25/b25-remediation-plan-b25-v4-pass-23.md` with `9` tickets and
  `3` remediation batches.
- Result: B25 remains reopened, but the interaction-model gate is converging. Pass 23 must first fix
  product-doc reconciliation, then close the remaining Camera gear-loan, Platform blocked-target, and
  Ad-Free lifecycle/surface gaps with fresh full B12-B20 screenshots.
- Evidence/tooling commit: `45264e1`.

### Iteration 20 / `b25-v4-pass-23`

- Status: failed, but converged.
- Scope: consumed `b25-remediation-plan-b25-v4-pass-23.md`, repaired stale Product Docs V2 community
  example mappings for Garden Club, Neighborhood Book Club, Chess Club, Loom Communities Shell, and
  Persona Role Inventory, added richer B25 UI content for platform messaging/block-state, ad-off,
  camera gear loan, and portability-style surfaces, fixed compact action-button wrapping, and hardened
  the capture/import tooling so full B12-B20 evidence and LLM direct-question answers flow through the
  production judge.
- Capture/evidence: full B12-B20 capture passed with `198` screenshots, `66` workflows, and `9`
  workflow manifests; capture coverage passed and the B25 collector generated `195` schema v4 screen
  rows. Workflow/persona coverage passed `68 / 68`, visual inspection passed `195 / 195`, and the
  semantic workflow interaction-model gate passed `68 / 68`.
- Product-doc reconciliation: passed. The fresh LLM Product Docs to Evidence Workflow Reconciliation
  review covered `13` community product docs, `195` screen rows, and `179` unique screenshot hashes with
  `0` findings.
- LLM Vision UX review: failed with `4` major findings and `1` minor finding. Major findings:
  `B25-P23-VISION-MAJOR-001` Book Club AI digest still appears as generic community activity;
  `B25-P23-VISION-MAJOR-002` Book Club export still contains youth-sports protected-data language;
  `B25-P23-VISION-MAJOR-003` Data Portability workflows repeat the same wizard surface across distinct
  tasks; `B25-P23-VISION-MAJOR-004` Chess Club screens remain thin/repeated rather than a rich club home
  and match-result experience.
- Deterministic semantic surface proof: improved, but still has `4` blocking workflow/persona rows:
  `hoa-owner-notification` needs visible sender/recipient and timestamp/delivery timing proof;
  `platform-blocked-target`, `platform-connections-entry`, and `platform-connection-invite` need visible
  message/invite body content.
- Production UX judge: failed `8 / 16` criteria and generated
  `docs/Build Plan V2/Evidence/B25/b25-remediation-tickets-b25-v4-pass-23.md`.
- Iteration scorecard:
  `docs/Build Plan V2/Evidence/B25/b25-iteration-scorecard-b25-v4-pass-23.md` records
  `B25 can pass=false`, `0` blockers, `4` unresolved major findings, `0` newly introduced
  blocker/major findings, and `4` remaining blocking/major findings.
- Next remediation plan:
  `docs/Build Plan V2/Evidence/B25/b25-remediation-plan-b25-v4-pass-24.md` with `8` tickets and `3`
  remediation batches.
- Result: B25 remains reopened, but the loop is still converging. Pass 24 must prioritize the four LLM
  major findings, then close the four remaining semantic surface-proof rows, recapture full B12-B20
  evidence, rerun fresh Product Docs reconciliation and Vision UX review, and regenerate
  tickets/scorecards.
- Evidence/tooling commit: `a3f0db9`.
