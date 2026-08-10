# Single-pass tooling smoke test — mini report

date: 2026-08-09
scope: prove the full Community JSON Migration Tracker chain (ticket dispatch mechanics + JSON authoring/
validation/install + mandatory live UX Judge walkthrough) works end to end, once, before running it for real
across all 10 communities.

**Result: the chain works, wired correctly at every step.** It also did its job as a smoke test in the best
possible way — it surfaced 4 genuine bugs (1 already fixed, 3 documented as open findings) rather than a
sanitized "everything passed" run, which is the actual value of making the live walkthrough mandatory.

## Timeline — what was called, when, with what result

| # | Tool / action | Input | Output | Result |
|---|---|---|---|---|
| 1 | `data/wsl_dispatch_tracker.sh baseline cjm2` | — | `.codex-logs/.dispatch_wsl_tracker.log` | baseline: 17 WSL processes |
| 2 | `data/call_implementation_agent.sh data/v3_ticket_cjm2_url_field_rendering.md --fresh` (backgrounded via `setsid nohup … & disown` inside `wsl.exe -e bash -lc`) | Ticket CJM.2 (`type:"url"` external rendering) | `.codex-logs/cjm2_dispatch.out.log` | Codex (GPT-5.3-Codex-Spark @ xhigh) made correct, on-scope edits to all 5 named files + 1 test. Hit the known WSL vsock bug on its own verification/commit attempts (documented failure mode in the script's own header) — real edits left uncommitted, self-reported `blocked` in STATUS.md. |
| 3 | `data/wsl_dispatch_tracker.sh capture cjm2` | — | tracker log | WINPIDS recorded |
| 4 | Monitor → `data/watch_dispatch_log.sh cjm2` | dispatch log | — | Self-terminated cleanly on `codex exec exited with status 0`, after echoing several transient vsock alert lines (non-fatal, per the script's own documented behavior) |
| 5 | `data/wsl_dispatch_tracker.sh cleanup cjm2` | — | tracker log | Dispatch's own WSL session already closed; a separate zombie sweep found and killed ~11 orphaned sessions from the *prior day's* work (unrelated to this dispatch) |
| 6 | **Manual review + independent verification** (me, not Codex) | the diff | — | Confirmed all 5 scope items correct and minimal. Found a **6th, real regression** the diff exposed: `_rendersAsParagraph` only recognized `type: "text"`, not `"textarea"` — previously masked because the generic card never passed a field's real `type` through at all. Fixed directly (1-line change), since it's exactly what CJM.2's own necessary fix (passing `type:` through) surfaced. |
| 7 | `flutter analyze` (both touched packages) | — | — | Clean, both before and after the textarea fix |
| 8 | `flutter test` — `loom_workflow_engine` | — | — | 206/206 passed |
| 9 | `flutter test` — `loom_communities_app_shell` (full suite, twice — before/after the textarea fix) | — | — | Before fix: 2 failures. After fix: 1 failure remained (`v3_milestone_a11_event_rsvp_archetype_test.dart`) — confirmed via `git stash` against the clean baseline to be **pre-existing, unrelated to CJM.2** |
| 10 | `git commit` | 6 files | commit `51d81e8c` | `feat: implement type:"url" field rendering, external open mode (CJM.2)` |
| 11 | `data/handoff_gate.sh cjm2` | — | — | Reported NOT READY — working tree has *other* legitimate uncommitted session work (tracker doc, HOA JSON, spec docs). The gate is designed for one-ticket-at-a-time sessions; treated as informational here, not blocking, since CJM.2's own commit and verification were already independently confirmed above. |
| 12 | `dart run community_package_validator.dart --package Loom_Communities_Workflow_Engine_CedarCommonsHOA_Example.jsonc` | Cedar Commons HOA fixture | validation report | First run: `pass`, 0 errors, 18 warnings, incl. 2 `unknown_instance_persona` — found a real bug (`hoa-owner-01` used instead of the declared `hoa-homeowner`), fixed in the JSON. |
| 13 | `tool/generate_cedar_commons_hoa_package.dart` (new file, written this pass, mirrors the existing Tabletop Club generator) | the fixture | `.loom-init.zip` / `.loom-extension.zip` (plain JSON despite the name, per the app's real convention) | Generated cleanly |
| 14 | `adb push` + `adb shell run-as … cp` | package files | files in `/data/user/0/<pkg>/files/` | Installed onto the on-device app-private storage |
| 15 | Real UI drive (`adb shell input tap/text`, `uiautomator dump` for exact bounds) via the "Add local community" dialog | the two file paths | — | **Installed for real** — "Installed Cedar Commons HOA from local packages" |
| 16 | Live sign-in as Homeowner + navigate Home/Calendar/Marketplace/Giving, `adb shell screencap` | — | 26 real screenshots | Confirmed: entry gate correctly resolves personas from JSON; identity-legibility fix (from earlier this session) works for this new community too; `type:"url"` field renders exactly per CJM.2's contract (disabled/unsupported pill for `openMode:"choice"`, since only `external` is implemented). **Also found 3 more real bugs** — see Findings below. |
| 17 | (mid-pass) machine reboot | — | — | All WSL/emulator state lost; on-disk file edits survived. Resumed cleanly: re-verified analyze/tests, re-validated JSON, relaunched emulator, reinstalled the package (app-private storage does not survive a full app reinstall, confirmed empirically — had to re-push files once). |
| 18 | `dart run community_package_validator.dart` (re-run after actor-id fix) | corrected fixture | — | `pass`, 0 errors, 16 warnings, 0 `unknown_instance_persona` |
| 19 | Real Agent-tool dispatch, `subagent_type: general-purpose`, `model: opus` | canonical judge-prompt.txt (rubric + exact schema, adapted from the proven Apartment Events template) + 5 real screenshots (Read tool) | `llm-vision-ux-review-phaseA-cedar-commons-hoa-cjm2-smoketest-1.json` | Genuine, specific, evidence-grounded review — `status: fail`, 9 findings (2 critical-blocker, 4 major, 3 minor), independently corroborated my own manually-found bugs and found more. |
| 20 | `dart run b25_llm_review_freshness_gate.dart` | review-input.json + the judge's JSON | freshness-gate-output.json/.md | `status=pass problems=0` |
| 21 | `dart run b25_llm_ux_review_importer.dart` | same | independent-production-ux-review.json | `status=fail findings=9 screenReviews=5` — **exit 1 is correct**, propagating the judge's genuine fail, not a tooling error |
| 22 | `dart run production_ux_judge.dart` | imported review | — | `production-ux-judge: fail` — correctly cites the real blocker/major findings via `b25-c14-llm-vision-ux-review`, plus (expected, not a bug) failures on every criterion that needs a full canonical B25 pass this ad-hoc smoke test never ran (`productDocCoverage`, `blueprintCoverage`, visual-inspection rows, workflow/persona scorecards, schema v4 markers) — same shape as the Apartment Events Phase A precedent earlier this session. |

## Findings surfaced by this one pass (the actual point of the mandatory live-walkthrough gate)

1. **Fixed, code:** `_rendersAsParagraph` didn't recognize `type: "textarea"` — masked until CJM.2 made the
   generic card pass a field's real type through at all. One-line fix, verified by the existing Tabletop
   Club announcement test now passing.
2. **Fixed, JSON:** stray `hoa-owner-01` identifier used instead of the declared `hoa-homeowner` persona id
   in several `instanceData` fields — the validator only catches this for `createdByPersonaId`, not plain
   `personaId`-typed data fields.
3. **Open, documented (Community JSON Migration Tracker §1a #2):** the Calendar tab hardcodes
   `instanceData['eventDate']` — no other field name is recognized regardless of `instanceDataSchema`. Every
   calendar-bound workflow across every remaining community needs a literal `eventDate` field until/unless
   this is generalized.
4. **Open, documented (Tracker §1a #4):** `role: "actor"` in a render binding means "I am
   `createdByPersonaId`" by default (`_engineNativeActorRolesForInstance`), not "a `personaId`-typed field on
   this instance names me." Board-issues/member-acts workflows (dues invoices, this HOA's architectural
   requests) don't fit that model — real design decision needed, not a JSON typo.
5. **Open, from the judge (not previously noticed by me):** raw JSON schema keys (`version`, `accessLevel`)
   and an unmapped enum (`open`) leak into fact pills; editable-looking form fields + an unexplained disabled
   "Save changes" shown to a read-only persona; a ~15%-opacity "Local package details" row visible on
   Calendar/Giving; internal vocabulary ("unassigned community surfaces", "ad-off state") in resident-facing
   copy; identity card scrolls out of view with no persistent replacement; bottom nav clips the 4th tab.

None of items 3-5 were fixed in this pass — deliberately, to prove the gate surfaces real gaps rather than
being silently patched mid-test. They're now real, tracked findings for the next round of work.

## What this proves about the tracker's mechanics

- The Codex dispatch recipe (baseline → background dispatch → capture → Monitor watch → cleanup → commit →
  handoff_gate) works exactly as documented, **including its documented failure mode** (the WSL vsock bug
  leaving real edits uncommitted) — and the prescribed recovery (review and finish committing yourself
  rather than discarding) worked correctly.
- The validator catches real bugs but has real, documented blind spots (persona ids in plain data fields) —
  confirming why the live walkthrough is a separate, non-optional gate rather than "the validator is enough."
- The install mechanism (standalone `.jsonc` → generator script → `adb push`/`run-as` → real UI drive) works
  for a community with **zero existing catalog wiring**, matching the Tabletop Club/Apartment Events
  precedent — no code changes needed to make a new community's JSON installable and live-testable.
- The Agent-tool LLM Vision UX Judge dispatch produces genuinely independent, specific, non-boilerplate
  findings (not just structurally valid JSON) and the full gate/importer/production-judge chain correctly
  propagates a real fail all the way through — proven on a **second** community (Apartment Events was the
  first, earlier this session), confirming the mechanism generalizes.

## Not yet done (intentionally out of scope for a single smoke-test pass)

- No findings from this run have been turned into `data/v3_ticket_*.md` tickets or dispatched yet.
- CJM.1 (equipment-loan generalization) and CJM.3 (citation-list rendering) haven't been dispatched — only
  CJM.2 was run, as the one ticket needed to prove the mechanism plus unblock this specific community.
- The Cedar Commons HOA JSON fixes and the Community JSON Migration Tracker's findings sections are
  uncommitted, pending your review.
- Only 5 of Cedar Commons HOA's screens were captured/judged (not a full canonical B25 pass) — sufficient to
  prove the chain, not sufficient to mark this community complete in the tracker.

## Appendix: coverage against `docs/Build Plan V2/Tools/` — every tool, used or not, and why

Cross-checked against all 3 files: `ux-gate-judge-tools.md` (Agent Split roles + Deterministic CLIs table),
`b25-product-doc-workflow-reconciliation-llm-gate.md`, `b25-remediation-ticket-template.md`.

**Bottom line: not every tool ran, and that's correct, not a gap in this pass.** This was a deliberate
"Phase A" ad-hoc smoke test — the exact lighter-weight path this doc itself names as legitimate and
distinct from a full B25 pass ("For ad hoc/manual Phase A runs (not a full committed B25 pass), findings
can be bridged directly... a simpler, faster path than the full Remediation Planner/schema-v4 ticket
flow"). The full canonical B25 pipeline requires (a) the community wired into `loomEvidenceTargets` for
automated `flutter drive` capture, and (b) a full B12-B20, ≥180-screenshot pass across all 9 phases —
neither applies to a brand-new, not-yet-catalogued community JSON being smoke-tested for the first time.
`production_ux_judge.dart`'s own failure output named every missing piece by exact field name
(`productDocCoverage`, `blueprintCoverage`, `visualInspection`, `workflowPersonaScorecards`,
`workflowLifecycleScorecards`, `appShellCapabilityReview`, `productDocWorkflowReconciliation`,
`schemaVersion`/`reviewStandardVersion`, `remediationIterations`) — confirming this reading is exact, not
a guess.

### Roles (Agent Split table)

| Role | Used this pass? | Why / why not |
|---|---|---|
| Worker Agent | **Yes** | Codex CLI dispatch for CJM.2, via `data/call_implementation_agent.sh` |
| Product Experience Doc Steward | No | Cedar Commons HOA's product doc already existed and matched (authored/locked earlier this session); nothing to create or update this pass |
| Evidence Collector Tool (`b25_evidence_collector.dart`) | No | Requires canonical automated capture output; this community isn't in `loomEvidenceTargets`. Hand-built `review-input.json` instead, matching the Apartment Events Phase A precedent exactly |
| Visual Inspection Auditor Tool (`b25_visual_inspection_auditor.dart`) | No | Same reason — needs the canonical evidence structure the automated capture produces. This is exactly why `production_ux_judge` reported `missing-visual-inspection` on all 5 rows |
| Deterministic Review Scaffold (`b25_independent_ux_judge.dart`) | No | Same reason — hand-authored the scaffold (`review-input.json`) instead of generating it |
| LLM Product Docs To Evidence Reconciliation Agent | **No — genuine gap, not infra-blocked** | This is a real, dispatchable LLM gate role (compares Product Docs V2 §6/7/8/9 + card-surface registry against evidence) that I could have run — I didn't. Worth doing before this community is marked complete, since the doc already exists |
| LLM Vision UX Judge Agent | **Yes** | Dispatched via the `Agent` tool per the exact documented Phase A pattern, real screenshots, real rubric |
| LLM Freshness Gate Tool | **Yes** | `b25_llm_review_freshness_gate.dart` — real pass, 0 problems |
| LLM Review Importer Tool | **Yes** | `b25_llm_ux_review_importer.dart` — real import, correctly propagated `fail` |
| Workflow Interaction-Model Judge Tool | No | Needs `workflowPersonaScorecards`/coverage rows from the collectors above, which weren't run |
| Production UX Judge CLI | **Yes** | `production_ux_judge.dart` — ran for real, correctly failed on both real findings and missing-pipeline criteria |
| Remediation Planner | No | Only runs once a failed pass has generated tickets via `production_ux_judge.dart --tickets-output`, which I didn't request this pass |

### Deterministic CLIs table

| Tool | Phase | Used? | Why not |
|---|---|---|---|
| `workflow_completeness_judge.dart` | B11 | No | Wrong phase — validates owner-prompt/generated-package completeness, not applicable here |
| `ux_contract_judge.dart` | B21 | No | Wrong phase — pre-implementation UX contract validation |
| `domain_surface_classifier.dart` | B22 | No | Wrong phase |
| `persona_ux_judge.dart` | B23 | No | Wrong phase |
| `evidence_integrity_auditor.dart` | B24 | No | Wrong phase |
| `b25_capture_workflow_screenshots.dart` | B25 | No | Automated `flutter drive` capture only works for communities in `loomEvidenceTargets`; used manual `adb screencap` instead (same as Apartment Events precedent) |
| `b25_capture_coverage_gate.dart` | B25 | No | Consumes the above tool's output; N/A for manual capture |
| `b25_evidence_collector.dart` | B25 | No | See Evidence Collector Tool above |
| `b25_workflow_persona_coverage_collector.dart` | B25 | No | Needs the full automated evidence set to verify entry/action/result coverage per workflow/persona |
| `b25_visual_inspection_auditor.dart` | B25 | No | See above |
| `b25_independent_ux_judge.dart` | B25 | No | See Deterministic Review Scaffold above |
| `b25_component_doc_context.dart` | B25 | No | Feeds the product-doc reconciliation gate, which wasn't run this pass — no consumer |
| LLM Product Docs to Evidence Reconciliation Agent | B25 | No | See above — genuine gap |
| `b25_llm_review_freshness_gate.dart` | B25 | **Yes** | |
| `b25_llm_ux_review_importer.dart` | B25 | **Yes** | |
| `b25_workflow_interaction_model_judge.dart` | B25 | No | Needs coverage rows not generated this pass |
| `b25_workflow_lifecycle_judge.dart` (deprecated alias) | B25 | No | Superseded by the above; correctly not used |
| `production_ux_judge.dart` | B25 | **Yes** | |
| `b25_iteration_scorecard.dart` | B25 | No | Summarizes convergence across passes; this was a single first pass, no loop to score yet |
| `b25_remediation_planner.dart` | B25 | No | Only used at the start of a remediation pass consuming tickets from a prior failed pass — none generated yet |

### Used this pass but not documented in these 3 files (legitimately out of scope for them)

- `community_package_validator.dart` — a JSON-grammar validator from `loom_ux_judges/bin/`, a pre-capture
  stage tool, not part of the B25 UX-gate pipeline these docs describe.
- The emulator launcher (`launch_loom_demo_emulators.sh`) — referenced in `ux-gate-judge-tools.md` (not the
  table) as the required pre-step; used exactly as documented.
- Codex dispatch mechanics (`data/call_implementation_agent.sh` + `wsl_dispatch_tracker.sh` +
  `watch_dispatch_log.sh` + `handoff_gate.sh`) — the concrete implementation of the "Worker Agent" role,
  documented in the Community JSON Migration Tracker rather than here.

### What this means for the next run

Before Cedar Commons HOA (or any community) is marked complete in the tracker, a real pass needs: the
LLM Product Docs Reconciliation gate (genuinely skipped, no blocker to running it now), and — once the
community is added to `loomEvidenceTargets` — the full automated capture→coverage→visual-inspection→
scaffold chain so `production_ux_judge` can evaluate the criteria that are structurally impossible to
satisfy from a 5-screenshot hand-built evidence set.

## Ready to commit (awaiting confirmation)

- `docs/references/communities/Loom_Communities_Workflow_Engine_CedarCommonsHOA_Example.jsonc` (persona-id
  fix)
- `docs/Build Plan V2/Community JSON Migration Tracker.md` (§1a findings + §4 status update)
- `app/packages/core/loom_communities_app_shell/tool/generate_cedar_commons_hoa_package.dart` (new, reusable
  for every future community)
- This report + its evidence directory
