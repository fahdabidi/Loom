# Loom Communities V2 Build Tracker

Status: Draft execution ledger

This tracker records what each phase is intended to achieve, what it must deliver, what counts as
completed, and the evidence captured when the phase is closed. Update it at the end of every phase
before starting the next phase.

Source rules: [Rules.md](./Rules.md)
Source manifest: [test-manifest.json](./test-manifest.json)

## How To Use This Tracker

For each phase:

1. Confirm the predecessor phase is complete.
2. Run the prerequisite gate in the phase file from WSL Ubuntu.
3. If the phase has UI, interaction, workflow UX, or user-facing copy, complete the R20 UX Decisions
   gate before implementation: reference sources reviewed, UX patterns extracted, key UX decisions,
   key implementation decisions, workflow walkthrough, and open questions / tradeoffs.
4. Execute the phase deliverables.
5. Run all required validation, contract, workflow, manifest, and staleness gates.
6. Stage only the phase's intended changes and review `git diff --staged`.
7. Commit the phase changes to git.
8. Record component version hashes, API/UX/Skill artifacts, gate evidence, and the resulting commit SHA.
9. Start the next phase only after the commit exists and this tracker points to that SHA.

For B25, treat each independent UX review/remediation iteration as its own commit boundary. Before
starting the next UX feedback loop or correction batch, commit the current iteration's product-doc
updates, review evidence, remediation changes, refreshed screenshots or screenshot references, tests,
remaining findings, and tracker/remediation-loop updates. Record the iteration commit SHA in the B25
remediation loop log and in this tracker. Under the B25 v4 standard, the iteration cannot close without
community-specific product experience docs, fresh screenshot hashes and timestamps, app commit SHA,
visible-text extraction, UI-pattern classification, non-boilerplate screen-specific critiques, a
domain-native primary-surface audit, a green holistic product UX direct-question pass, and green
workflow/persona direct-question passes for every reviewed workflow/persona pair. Each screen row must
also include passing `visualInspection` evidence generated from the screenshot pixels/layout, not only
row metadata or expected assertions. Each primary workflow/persona row must also include passing
semantic surface proof: the after screenshots must visibly demonstrate the requested target product
surface and its required domain content and affordances, not merely show that no known visual defect was
detected. Each pass must also emit and commit a B25 iteration scorecard showing pass/fail, current
critical/blocker and major counts, blocker/major findings resolved in that pass, newly introduced
blocker/major findings, judge failures, and the next action.
The B25 tool sequence is product experience doc steward -> advisory card-surface registry refresh ->
full B12-B20 screenshot capture -> `b25_capture_coverage_gate.dart` -> evidence collector -> workflow/persona coverage collector ->
visual inspection auditor -> deterministic review scaffold -> LLM Product Docs to Evidence Workflow
Reconciliation Agent -> LLM Vision UX Judge Agent -> LLM review freshness gate -> LLM review importer
-> workflow interaction-model judge -> deterministic production UX judge -> remediation tickets ->
iteration scorecard -> commit. Targeted recaptures may be used only as
non-committable remediation diagnostics; the iteration commit must always use a full B12-B20 capture
and passing coverage gate.
A carried-forward, copied, or prior-run LLM Vision UX review is stale by definition. The imported LLM
artifact must be produced for the current B25 run and app commit, declare `freshReview=true`,
`currentReviewRunId`, `appCommitSha`, `reviewedScreenRowIds`, and `reviewedScreenshotHashes`, and omit
`sourceReviewRunId`, `carriedForward=true`, and `reusedPriorReview=true`. The direct questions must be
community-agnostic so they catch weak workflow-surface UI in any community, not only the current
example under review.
The advisory card-surface registry records `workflow -> cardSurfaceFamily -> API contract -> required
interactions/actions -> renderer/fake-backend support` in the community product docs and B25 evidence
JSON. B25 uses this as remediation context only; do not treat it as a standalone card-surface/API
coverage gate until a later phase explicitly enables that gate.
Native Loom repo runs write community product experience docs under
`docs/Product Docs V2/Community Examples/<community>-product-experience.md`. Standalone Skill runs treat
the fetched Loom Product Docs V2 as read-only and write the same product contract locally under
`<extension-workspace>/docs/product/community-product-experience.md`. The B25 blueprint is a review
summary derived from those product docs, not a substitute for them. Tickets must classify failures as
`product-spec-gap`, `implementation-gap`, `evidence-gap`, or `mixed-gap`; product-spec gaps update the
product doc before UI remediation begins.
The LLM Product Docs to Evidence Workflow Reconciliation Agent must inspect each community product
doc's `## 6. Workflow-To-Surface Mapping`, Sections 7-9, B25 semantic interaction model, and
card-surface registry against the current screenshots/review evidence. It opens tickets when product
docs omit screenshot-visible workflows/interactions, when documented workflows lack screenshot-backed
implementation, when required visible proof is absent, or when product docs/evidence map a primary job
to a generic surface.
The next remediation pass starts by feeding the committed tickets and scorecard to the remediation
planner before any worker implements fixes.

Set B workflow tests must run against the Demo Loom Communities App with the Local Backend. The Skill
supports both `local-demo` and `real-backend-publish` modes, but no Set B gate may depend on an
external backend. The first supported Skill execution targets are Codex and Claude Code; online-only
support is deferred until a hosted Loom build and validation backend exists. All Dart, Flutter, Melos,
package-validation, phase-gate, manifest-gate, and workflow-test commands run from WSL Ubuntu using:

```powershell
wsl.exe -d Ubuntu -- bash -lc 'cd "/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app" && <command>'
```

## Phase Status Tracker

| Phase | Status | Required predecessor | Phase doc | Primary completion checkpoint | Gate evidence | Commit SHA |
| --- | --- | --- | --- | --- | --- | --- |
| 0 | Complete | None | [Initialize Build](./Phases/Phase%200%20-%20Initialize%20Build.md) | Rules, manifest, tracker, Skill skeleton, Skill setup manifest, workspace scaffold, and gates exist. | R20 UX methodology, phase instructions, tracker reset, manifest gate, Phase 0 gate, Skill prereq check, boundary lint, and diff check passed in WSL Ubuntu. | `17b4b81` prior scaffold commit; R20 closeout `b838fa8` |
| A1 | Complete | 0 | [Foundation Components](./Phases/Phase%20A1%20-%20Foundation%20Components.md) | Foundation contracts, fakes, stores, validation tests, and provider test kits pass. | A1 contracts/fakes/schema/seed/test suite added; validation tests pass; consumer-contract kits are pending only for unbuilt counterparts; manifest and phase gates pass in WSL Ubuntu. | `e3c0357` |
| A2 | Complete | A1 | [Registry and Control-Plane Components](./Phases/Phase%20A2%20-%20Registry%20and%20Control-Plane%20Components.md) | Registry/control-plane components pass tests to and from built providers. | A2 contracts/fakes/schema/seed/test suite added; A1 unblocked contract tests pass; App Shell counterpart tests remain pending; manifest and phase gates pass in WSL Ubuntu. | `3d6a388` |
| A3 | Complete | A2 | [Service Components I](./Phases/Phase%20A3%20-%20Service%20Components%20I%20%28Experience%20Core%29.md) | Experience service components pass validation and unblocked contract tests. | A3 contracts/fakes/schema/seed/test suite added; forms/protected-vault contract passes; A4b/A5/A6 consumer tests remain pending; manifest and phase gates pass in WSL Ubuntu. | `a4cc268` |
| A4a | Complete | A3 | [Service Components II](./Phases/Phase%20A4a%20-%20Service%20Components%20II%20%28Ops%20and%20Community%29.md) | Ops/community services pass validation and unblocked contract tests. | A4a contracts/fakes/schema/seed/test suite added; document/export, import/protected-vault, incident/certification contracts pass; A4b/A5 consumer tests remain pending; manifest and phase gates pass in WSL Ubuntu. | `c56f45b` |
| A4b | Complete | A4a | [Service Components III](./Phases/Phase%20A4b%20-%20Service%20Components%20III%20%28Economic%20Search%20and%20Ads%29.md) | Economic/search/ad services pass validation and unblocked contract tests. | A4b contracts/fakes/schema/seed/test suite added; wallet/ad decision, search/AI/digest, settlement/utility, receipt/settlement, fraud/dispute, and earlier unblocked provider contracts pass; A6 consumer tests remain pending; manifest and phase gates pass in WSL Ubuntu. | `4ab715d` |
| A5 | Complete | A4b | [Extension Engine Components](./Phases/Phase%20A5%20-%20Extension%20Engine%20Components.md) | Runtime, rules, workflows, package validator, and initialization package contracts pass. | A5 contracts/fakes/schema/seed/test suite added; runtime/rules/workflows/jobs/functions/schema/secrets/package/init validations pass; engine-unblocked provider contracts pass; A6/B1a consumer tests remain pending; manifest and phase gates pass in WSL Ubuntu. | `b4c8b25` |
| A6 | Complete | A5 + Phase 0 R20 closeout | [UX Components](./Phases/Phase%20A6%20-%20UX%20Components.md) | App Shell, UX micro-components, Demo App, and Local Backend Adapter pass. | R20 UX Decisions completed; empty-state CTA gap fixed; A6 tests, existing B1a-B3 workflow regressions, manifest gate, A6 phase gate, analyze, boundary lint, and diff check pass in WSL Ubuntu. | `0346c99` prior code commit; R20 closeout `39af637` |
| B1a | Complete | A6 R20 closeout | [Local Build Download Sideload Install](./Phases/Phase%20B1a%20-%20Local%20Build%20Download%20Sideload%20Install.md) | Skill prereq setup, local package/init package, fake backend import, card render, and local open pass. | R20 UX Decisions completed; local package loader, package-pair validation, invalid-file error, duplicate import status, B1a workflow, B1b-B3 regressions, manifest gate, B1a phase gate, analyze, boundary lint, and diff check pass in WSL Ubuntu. | `df6f543` prior code commit; R20 closeout `471677a` |
| B1b | Complete | B1a R20 closeout | [Publish Discover Certify Install](./Phases/Phase%20B1b%20-%20Publish%20Discover%20Certify%20Install.md) | Real-backend publish mode is validated through local stubs/contracts. | R20 UX Decisions completed; B1b workflow, B1a/A6 regressions, manifest gate, B1b phase gate, boundary lint, and diff check pass in WSL Ubuntu. | `7825b59` prior code commit; R20 closeout `105cb16` |
| B2 | Complete | B1b R20 closeout | [Book Club Headline Flow](./Phases/Phase%20B2%20-%20Book%20Club%20Headline%20Flow.md) | Book club workflow passes in the Demo App with Local Backend. | R20 UX Decisions completed; B2 workflow, B1b/B1a/A6 regressions, manifest gate, B2 phase gate, boundary lint, and diff check pass in WSL Ubuntu. | `e362090` prior code commit; R20 closeout `e97ba72` |
| B3 | Complete | B2 R20 closeout | [Youth Soccer Headline Flow](./Phases/Phase%20B3%20-%20Youth%20Soccer%20Headline%20Flow.md) | Youth soccer workflow passes in the Demo App with Local Backend. | R20 UX Decisions completed; B3 workflow, B2/B1b/B1a/A6 regressions, manifest gate, B3 phase gate, boundary lint, and diff check pass in WSL Ubuntu. | `36aee10` prior code commit; R20 closeout `23dd422` |
| B4 | Complete | B3 R20 closeout | [HOA Headline Flow](./Phases/Phase%20B4%20-%20HOA%20Headline%20Flow.md) | HOA workflow passes in the Demo App with Local Backend. | R20 UX Decisions completed; HOA workflow, affected fake backend regressions, manifest gate, B4 phase gate, analyze, boundary lint, and diff check pass in WSL Ubuntu. | `f3ffad3` |
| B5 | Complete | B4 | [Mosque Headline Flow](./Phases/Phase%20B5%20-%20Mosque%20Headline%20Flow.md) | Mosque workflow passes in the Demo App with Local Backend. | R20 UX Decisions completed; mosque workflow, affected component regressions, manifest gate, B5 phase gate, analyze, boundary lint, and diff check pass in WSL Ubuntu. | `163dad1` |
| B6 | Complete | B5 | [Messaging In-Stream Ads and Connections](./Phases/Phase%20B6%20-%20Messaging%20In-Stream%20Ads%20and%20Connections.md) | Messaging, connections, ad surfaces, and shell invariants pass. | R20 UX Decisions completed; messaging/ads/connections workflow, affected component regressions, manifest gate, B6 phase gate, analyze, boundary lint, and diff check pass in WSL Ubuntu. | `b8c348d` |
| B7 | Complete | B6 | [Ad-Off](./Phases/Phase%20B7%20-%20Ad-Off.md) | Ad-off purchase, ad suppression, receipts, settlement, and utility funding pass. | R20 UX Decisions completed; ad-off workflow, wallet community-ad-off validation, ad-decision validation, affected regressions, manifest gate, B7 phase gate, analyze, boundary lint, and diff check pass in WSL Ubuntu. | `b06d3c7` |
| B8 | Complete | B7 | [Export and Migration](./Phases/Phase%20B8%20-%20Export%20and%20Migration.md) | Export/migration, redaction, full workflow suite, and API spec inventory pass. | R20 UX Decisions completed; export/migration workflow, provider rollback validation, API inventory validation, full Set B regression, manifest gate, B8 phase gate, analyze, boundary lint, and diff check pass in WSL Ubuntu. | `762f556` |
| B9 | Complete | B8 | [Arbitrary Local Package Ingestion](./Phases/Phase%20B9%20-%20Arbitrary%20Local%20Package%20Ingestion.md) | Arbitrary local package pairs install from selected file contents without Book Club fixture substitution. | B9 backend/widget/workflow tests, B1a-B8 regressions, manifest gate, B9 phase gate, analyze, boundary lint, and diff check pass in WSL Ubuntu. | Implementation `db3c476`; tracker stamp `4a91980` |
| B10 | Complete | B9 | [Skill Arbitrary Extension Test Run](./Phases/Phase%20B10%20-%20Skill%20Arbitrary%20Extension%20Test%20Run.md) | Arbitrary Skill-generated artifacts replay through the Demo App Local Backend and open locally. | B10 replay test, zip package parsing validation, B1a-B10 regressions, manifest gate, B10 phase gate, analyze, boundary lint, and diff check pass in WSL Ubuntu. | Implementation `6bee137`; archive hardening `ce667b6` |
| B11 | Complete | B10 | [Skill Prompt Build Validate Complete](./Phases/Phase%20B11%20-%20Skill%20Prompt%20Build%20Validate%20Complete.md) | Owner prompt produces captured workflows, review docs, package artifacts, local install/open behavior, workflow validation, and a complete report. | B11 prompt-build validation, B9/B10 regressions, manifest gate, B11 phase gate, analyze, boundary lint, and diff check pass in WSL Ubuntu. | Implementation `21c89db`; tracker stamp `7ddb30d` |
| B12 | Complete | B11 | [Example Workflow UX Evidence Harness](./Phases/Phase%20B12%20-%20Example%20Workflow%20UX%20Evidence%20Harness.md) | Screenshot-backed emulator workflow evidence standard and capture harness exist for all example and test apps. | R20 UX Decisions completed; harness test, Android emulator screenshot capture, evidence manifest/audit, manifest gate, B12 phase gate, analyze, boundary lint, and diff check pass in WSL Ubuntu. | Consolidated in `4ae3b4a` |
| B13 | Complete | B12 | [Garden Club Full UX Workflow Evidence](./Phases/Phase%20B13%20-%20Garden%20Club%20Full%20UX%20Workflow%20Evidence.md) | Garden Club opens a real extension experience and every declared Garden Club workflow completes through visible UI. | R20 UX Decisions completed; Garden Club opens real workflow UI; 3 Garden Club workflows have 9 Android screenshots; manifest gate, B13 phase gate, analyze, boundary lint, and diff check pass in WSL Ubuntu. | Consolidated in `4ae3b4a` |
| B14 | Complete | B13 | [Anchor Example Full UX Workflow Evidence](./Phases/Phase%20B14%20-%20Anchor%20Example%20Full%20UX%20Workflow%20Evidence.md) | Book Club, Youth Soccer, HOA, and Mosque workflows complete through visible UI with screenshots. | R20 UX Decisions completed; 29 anchor workflows have 87 Android screenshots; full B1a-B16 regression sweep, manifest gate, B14 phase gate, analyze, boundary lint, and diff check pass in WSL Ubuntu. | Consolidated in `4ae3b4a` |
| B15 | Complete | B14 | [Arbitrary and Prompt Example Full UX Workflow Evidence](./Phases/Phase%20B15%20-%20Arbitrary%20and%20Prompt%20Example%20Full%20UX%20Workflow%20Evidence.md) | Chess Club arbitrary ingestion and Camera Club prompt-generated workflows render and complete through visible UI. | R20 UX Decisions completed; Chess and Camera workflows have 18 Android screenshots; full B1a-B16 workflow sweep, manifest gate, B15 phase gate, analyze, boundary lint, and diff check pass in WSL Ubuntu. | Consolidated in `4ae3b4a` |
| B16 | Complete | B15 | [Platform Workflow UX Evidence Sweep](./Phases/Phase%20B16%20-%20Platform%20Workflow%20UX%20Evidence%20Sweep.md) | Platform social, ad-off, and export/migration test apps complete required workflows through visible UI with screenshots. | R20 UX Decisions completed; 23 platform workflows have 69 Android screenshots; final B12-B16 manifest passes with 62 workflows and 186 screenshots; full workflow sweep, manifest gate, B16 phase gate, analyze, boundary lint, and diff check pass in WSL Ubuntu. | Consolidated in `4ae3b4a` |
| B17 | Complete | B16 | [Persona Role Inventory and Capability Matrix](./Phases/Phase%20B17%20-%20Persona%20Role%20Inventory%20and%20Capability%20Matrix.md) | Every example community has explicit test personas, role permissions, workflow ownership, recipient behavior, prerequisite chains, and hidden/disabled/read-only UX rules. | Persona model, capability matrix, dependency graph helpers, B17 widget test, B17 Android evidence manifest, analyze, full widget sweep, manifest gate, B17 phase gate, boundary lint, and diff check pass in WSL Ubuntu. | Consolidated in `4ae3b4a` |
| B18 | Complete | B17 | [Demo App Persona Picker](./Phases/Phase%20B18%20-%20Demo%20App%20Persona%20Picker.md) | The people icon opens a test-only persona picker and the selected persona is carried through each community experience. | People-icon picker, active persona card, local identity disclaimer, B18 widget test, B18 Android screenshots, analyze, manifest gate, B18 phase gate, boundary lint, and diff check pass in WSL Ubuntu. | Consolidated in `4ae3b4a` |
| B19 | Complete | B18 | [Community Persona-Aware UX](./Phases/Phase%20B19%20-%20Community%20Persona-Aware%20UX.md) | Community experiences hide, disable, or transform workflows based on the selected persona and role permissions. | Actor/receiver/read-only/disabled workflow rendering, Masjid Nur admin/member gating proof, B19 widget test, B19 Android screenshots, analyze, manifest gate, B19 phase gate, boundary lint, and diff check pass in WSL Ubuntu. | Consolidated in `4ae3b4a` |
| B20 | Complete | B19 | [Multi-Persona Workflow Evidence Sweep](./Phases/Phase%20B20%20-%20Multi-Persona%20Workflow%20Evidence%20Sweep.md) | Every per-persona workflow row passes, including prerequisite chains where one persona creates state another persona receives or continues. | Full per-persona workflow sweep, prerequisite producer/receiver tests, Masjid Nur announcement create/receive evidence, final B12-B20 manifest, full 39-test sweep, manifest gate, B20 phase gate, analyze, boundary lint, and diff check pass in WSL Ubuntu. | Consolidated in `4ae3b4a` |
| B21 | Complete | B20 | [Production Workflow UX Contract Matrix](./Phases/Phase%20B21%20-%20Production%20Workflow%20UX%20Contract%20Matrix.md) | Every workflow/persona row has a production UX contract that defines the real user task, domain screen, inputs, validation, semantic actions, success state, receiver state, and evidence IDs. | Evidence: production UX contract helper and matrix, generic-copy audit pass, `wf_production-workflow-ux-contract-matrix`, API/UX reviews, manifest/phase gates. | Consolidated in `4ae3b4a` |
| B22 | Complete | B21 | [Domain-Specific Workflow Surfaces](./Phases/Phase%20B22%20-%20Domain-Specific%20Workflow%20Surfaces.md) | Generic workflow cards/dialogs are replaced with domain-specific production surfaces for RSVP, payment, forms, announcements, approvals, search/AI, export/migration, social, ads, and portability workflows. | Evidence: domain-specific workflow cards, semantic actions, production review dialogs, result panels, `wf_domain-specific-workflow-surfaces`, manifest/phase gates. | Consolidated in `4ae3b4a` |
| B23 | Complete | B22 | [Persona Production UX and Cross-Persona State](./Phases/Phase%20B23%20-%20Persona%20Production%20UX%20and%20Cross-Persona%20State.md) | Each persona sees production-ready actor, receiver, read-only, disabled, or hidden UX, and multi-persona workflows prove the created state appears in the receiving persona's real surface. | Evidence: admin/member Masjid announcement handoff, receiver action states, persona-specific copy, `wf_persona-production-ux-cross-persona-state`, manifest/phase gates. | Consolidated in `4ae3b4a` |
| B24 | Complete | B23 | [Production UX Evidence and Certification Sweep](./Phases/Phase%20B24%20-%20Production%20UX%20Evidence%20and%20Certification%20Sweep.md) | The full example suite is certified against the production UX bar, and tests fail if generic workflow harness labels or test-only copy reach user-facing workflow surfaces. | Evidence: generic-copy failure gate, Android emulator screenshot sweep, `production-ux-certification.json`, `wf_production-ux-evidence-certification-sweep`, manifest/phase gates. | Consolidated in `4ae3b4a` |
| B25 | Reopened | B24 | [Independent Production UX Review](./Phases/Phase%20B25%20-%20Independent%20Production%20UX%20Review.md) | A post-implementation outside-in product UX review critiques the actual app experience against community-specific product experience docs, rejects exposed workflow machinery, requires fresh full-coverage screenshot-backed schema v4 evidence, and only passes when primary workflows use domain-native production surfaces with positive semantic surface proof, interaction-model proof, a passing fresh non-reused LLM vision UX review, and a passing full B12-B20 capture coverage gate. | Pass 20 consumed the pass-19 plan and improved rich product-surface fallback content, but failed the current B25 bar with 4 unresolved major findings: repeated generic surfaces in Camera Club, Member Social Space, Ad-Free Community, and Data Portability; 26 lifecycle scorecards missing full semantic proof; and Product Docs V2 community examples drifting from exact B25 workflow IDs/persona-state rows. Pass 21 must start from `b25-remediation-plan-b25-v4-pass-21.md`, update product docs first, then remediate UI/content and recapture full B12-B20 evidence. | Historical v3 implementation `ccc3f40`; v4 pass 1 evidence `647c38f`; pass-result clarification `c5799e6`; ticket/planner closeout `5d4e313`; coverage/judge-tool update `e46cbaa`; detailed ticket schema update `f617625`; work-item split update `42e7cdf`; reference-pattern ticket update `6d01a22`; v4 pass 2 `68b5fad`; v4 pass 3 `9c59a5a`; v4 pass 4 `b672089`; visual gate hardening `7217a1f`; visual gate rerun `39a1210`; visual-gate remediation plan `a893e53`; pass 6 `c1ec0c2`; capture tooling fix `5c83f4b`; pass 7 `10cf7a5`; pass 8 `c062daa`; pass 9 `605158d`; semantic-closure/product-doc/interaction-model gate update `4289b3d`; pass 10 `e63e34f`; pass 11 `84c6998`; pass 12 `7f3d71a`; pass 13 LLM vision gate/tickets `80146f7`; pass 16 iteration `3ad49ea`; pass 17 iteration `bc99df3`; card-surface registry prep `3606c8c`; pass 18 iteration `574cff3`; fresh-LLM hardening `bf7f393`; pass 19 fresh UX review `97d1a82`; pass 20 pending |

## Phase Outcome Summary

| Phase | What This Phase Achieves | Main Deliverables | Completed In This Phase |
| --- | --- | --- | --- |
| 0 | Establishes the execution system. | Rules, manifest, tracker, Skill skeleton, Skill setup/prereq manifest, workspace package placeholders, phase gates, API inventory scaffold. | The build system can identify every planned component/workflow test, supported local execution target, and manifest/staleness/setup gate. |
| A1 | Builds the foundation layer. | Identity/passport, roles/policy/consent, vaults, connections, receipts, audit, event bus, keys, builder App ID, local store baseline. | Foundational APIs, fakes, owned stores, seed fixtures, and provider-authored contract tests are available. |
| A2 | Builds registry and control-plane services. | Community registry, community branding, spaces, membership, invitations, extension registry, certification, certification asset evidence, public registry, workflow inventory. | Communities, spaces, membership, branding, extension versions, and certification status can be represented through contracts/fakes. |
| A3 | Builds experience-core services. | Publishing, messaging/stream, notifications, events, forms/polls/voting. | Core community interactions can be validated against foundation and registry fakes. |
| A4a | Builds ops/community services. | Cases/tasks, documents, facilities, import/export, provider transfer, abuse reports, moderation, incidents, disputes. | Operational and portability behaviors exist with validation and consumer-contract tests. |
| A4b | Builds economic/search/ad services. | Wallet/dues/donations, ad decision/campaigns, search, AI gateway, digest, settlement, utility funding, fraud signals. | Payments, ads, search/AI, receipts-adjacent settlement, and economic flows are contract-testable. |
| A5 | Builds extension engine components. | Runtime bridge, rules, workflows, jobs, functions, schemas, secrets/connectors, extension package validator, initialization package schema, asset manifest validation, initialization branding schema. | The Skill can target documented extension/package contracts, bundled asset contracts, and local initialization package contracts. |
| A6 | Builds UX and local demo runtime. | App Shell, branded community cards, nav panel, stream renderer, connections shell, ad slots, payment surface, data dashboard, Demo App, Local Backend Adapter. | The Demo App can start empty, expose Add Community, load local files, import fake-backend data and branding, persist locally, render branded cards, and host extensions. |
| B1a | Proves local extension creation and install. | Skill prereq setup, validation environment lock, Skill `local-demo` workflow, downloadable extension package, initialization package, bundled branding assets, local file load, fake backend import, branded community card, local latest open. | A user can validate the local toolchain, create/download an extension and initialization package, sideload them into the Demo App, see the branded community card, and run the community locally. |
| B1b | Proves real-backend publish mode locally. | Skill `real-backend-publish` workflow, publish/certify/discover/install contracts, local backend stubs/fakes for hosted APIs. | Hosted publish behavior is validated without requiring an external backend. |
| B2 | Validates the book club vertical. | Book nomination, voting, meeting event, discussion, search/digest, worked Skill example. | Book club extension works end to end in the Demo App with Local Backend. |
| B3 | Validates the youth soccer vertical. | Guardian/minor protected data, registration payment, roster, schedule, notifications, worked Skill example. | Youth soccer extension works end to end with protected-data and payment assertions. |
| B4 | Validates the HOA vertical. | Dues, documents, facility reservations, architectural request, workflow review, export coverage, worked Skill example. | HOA extension works end to end with docs, facilities, payments, case workflow, and export coverage. |
| B5 | Validates the mosque vertical. | Announcements, events, volunteer signup, donations with visibility controls, protected care requests, worked Skill example. | Mosque extension works end to end with sensitive-data and donation behavior. |
| B6 | Validates required social and ad surfaces. | Messages, Connections, invite/block behavior, stream rendering, in-stream ads, top banner behavior. | Platform invariants are proven: Messages and Connections are reachable, ads render or no-fill correctly, extensions cannot suppress required surfaces. |
| B7 | Validates ad-off economics. | Member/community ad-off purchase, entitlement checks, ad decision behavior, receipts, settlement, utility allocation. | Ad-off works end to end and economic records stay auditable. |
| B8 | Closes portability and API inventory readiness. | Export/migration, redaction, transfer verification/rollback, full workflow regression, API spec inventory, Skill/example updates. | Every B1a-B8 workflow remains green and every required API/local contract in that scope is present and validated before arbitrary-ingestion hardening. |
| B9 | Closes arbitrary local package ingestion. | File-backed package parsing, arbitrary init import, parsed branding/card rendering, local latest open, API/UX/Skill docs, manifest rows. | The Demo App can install an arbitrary Skill/developer-generated local package pair and display the parsed community instead of a built-in fixture. |
| B10 | Closes arbitrary Skill output replay. | Skill arbitrary Garden Club example, alias-field parser support, replay workflow test, API/UX/Skill docs, manifest rows. | A Skill-generated arbitrary extension/init pair can be reviewed as docs artifacts, replayed through the local backend, rendered as a card, and opened locally. |
| B11 | Closes prompt-to-complete Skill validation. | Skill prompt parser/build harness, arbitrary Camera Club prompt fixture, generated docs/package validation workflow, completion report schema, API/UX/Skill docs, manifest rows. | An arbitrary owner prompt can be converted into workflows, review docs, extension/init zip packages, local Demo App installation, workflow validation evidence, and a `complete=true` report before the Skill claims completion. |
| B12 | Establishes the full UI evidence gate. | Workflow evidence matrix, screenshot manifest schema, emulator capture harness, evidence folder conventions, failure artifact conventions, manifest rows. | Later phases cannot claim user-facing workflow completion without screenshot-backed Android emulator evidence for start, critical action, and completion states. |
| B13 | Closes the Garden Club UX gap. | Garden Club extension experience, declared Garden Club workflow tests, screenshot evidence bundle, Garden Club workflow docs/example updates. | Garden Club no longer opens only metadata/settings; it renders a domain experience and all declared Garden Club workflows complete through visible UI. |
| B14 | Closes full UX evidence for anchor vertical examples. | Book Club, Youth Soccer, HOA, and Mosque UI workflow tests, screenshot bundles, example docs updates, backend parity checks. | Each anchor example has visible UI evidence for every workflow previously proven only by direct service/harness calls. |
| B15 | Closes full UX evidence for arbitrary/generated examples. | Chess Club arbitrary-ingestion UI evidence, Camera Club prompt-generated UI workflow tests, screenshot bundles, completion report updates. | Arbitrary and prompt-generated examples prove not only package/card/open behavior, but visible workflow execution through the Demo App. |
| B16 | Closes full UX evidence for platform workflow test apps. | Platform Social, Ad-Off, and Export/Migration UI workflow tests, screenshot bundles, final evidence manifest, full workflow regression sweep. | Platform-required workflows are visibly exercised in the Demo App and the evidence package proves completion across all example and test apps. |
| B17 | Defines persona and role behavior before implementation. | Persona inventory, role/capability matrix, workflow actor/recipient mapping, workflow dependency graph, hidden/disabled/read-only UX policy, API/UX review. | The project knows which personas can create, approve, receive, search, export, pay, or only read each workflow, including prerequisites that another persona must perform first, before the UI changes. |
| B18 | Adds a test-only persona picker to the Demo App. | People-icon persona picker, active persona state, persona labels/descriptions, persona context passed into community screens, widget evidence. | Testers can switch persona from the people icon in each community without pretending this is production identity behavior. |
| B19 | Applies persona-aware UX to every example community. | Role-filtered workflow list, disabled/read-only workflow states, recipient surfaces, persona-specific copy, backend permission parity tests. | Community capabilities change when the selected persona changes, and admin-only workflows no longer appear as generally executable member actions. |
| B20 | Proves multi-persona workflows end to end. | Per-persona workflow matrix tests, persona-switch UI tests, prerequisite producer/receiver sequences, screenshot evidence manifests, cross-persona backend state assertions, full regression sweep. | Every persona/workflow row is either proven with UI evidence or explicitly marked not applicable; dependent workflows prove the prerequisite actor state before the receiving persona state. |
| B21 | Defines the production UX quality bar before implementation. | Production workflow UX contract matrix, workflow-type pattern selection, semantic action labels, copy/validation checklist, screenshot evidence plan, prompt set. | The team knows exactly what production-quality UX means for every workflow/persona row before any app code changes. |
| B22 | Replaces generic workflow harness UI with domain-specific production surfaces. | RSVP/event surfaces, payment/receipt surfaces, forms/protected-data surfaces, announcement/composer surfaces, approval surfaces, search/AI surfaces, export/migration surfaces, social/ad surfaces. | Users interact with real domain workflows instead of generic cards and "Complete workflow" dialogs. |
| B23 | Makes the production surfaces persona-aware and stateful across roles. | Actor views, receiver views, read-only views, disabled/hidden rules, dependency-chain state, persona-specific screenshot tests. | A role that creates a record and a role that receives it each see a coherent production experience for their part of the workflow. |
| B24 | Certifies the full suite against production UX evidence requirements. | Generic-copy failure tests, screenshot evidence audit, final B12-B24 evidence manifest, Skill completion-rule audit, regression sweep. | No example community can be marked complete while using generic workflow harness copy, missing inputs, missing success states, or untested persona handoffs. |
| B25 | Reviews and certifies the finished UX independently against explicit product experience specs. | Community-specific product experience docs, advisory workflow-to-card-surface registry context, LLM Product Docs to Evidence Workflow Reconciliation JSON/Markdown, full B12-B20 screenshot capture, `b25_capture_coverage_gate.dart` report, outside-in product UX review, schema v4 evidence, screenshot freshness audit, non-boilerplate screen critique, domain-native primary-surface gate, holistic direct-question scorecard, workflow/persona direct-question scorecards, `b25_llm_review_freshness_gate.dart` report, semantic surface proof, production UX judge scorecard, detailed remediation tickets with gap classification, before/after closure evidence, iteration scorecards, remediation evidence, final pass/fail decision; failed-pass tickets feed the next pass's remediation planner. | The UX passes only when every reviewed community/test app has a current product experience doc, the B25 blueprint is derived from those docs, the LLM Product Docs to Evidence Workflow Reconciliation pass has no unresolved blocker/major product-doc, implementation, evidence, or mapping gaps, the canonical screenshot evidence is a commit-eligible full B12-B20 capture, an independent screenshot-first review and the production UX judge find no unresolved blocker or major design issues, the LLM Vision UX Judge artifact is fresh for the current run/app commit/screenshots and is not carried forward from a prior pass, every screenshot is fresh and traceable, every primary workflow is domain-native, the holistic and workflow/persona direct-question passes are green, every primary workflow/persona row proves the requested target surface from after-screenshot visible evidence, every failed pass has template-complete remediation tickets and a convergence scorecard, every remediated ticket closes from before/after screenshot proof rather than implementation claims, and any minor issues are accepted or tracked. The card-surface registry is required context but not yet a standalone card-surface/API coverage gate. A remediation pass may not begin implementation until the prior pass's tickets have been converted into a remediation plan, and any product-spec-gap must update the product experience doc before UI remediation. |

## Planned Full UX Workflow Evidence Matrix

These phases extend the earlier Set B contract tests. Existing B1a-B11 completion evidence remains
valid for its original scope, but it does not satisfy this matrix unless the workflow is completed
through the visible Android emulator UI and recorded in screenshot evidence.

Every workflow evidence bundle must include:

- Start screenshot: installed card or workflow entry point visible in the Demo App.
- Critical-action screenshot: the user action that changes workflow state, such as submit, RSVP,
  pay, approve, export, or block.
- Completion screenshot: success state, resulting record, receipt, route, or redacted/exported result.
- Evidence manifest: `workflow-ui-evidence.json` with workflow ID, app/example ID, emulator name,
  screenshot paths, command output path, expected assertions, and pass/fail status.

| App or test target | Workflows that require visible UI completion evidence | Evidence phase |
| --- | --- | --- |
| Garden Club | Local package install/open into a real Garden Club home, required App Shell surfaces, garden event RSVP, plant exchange/form submission, Garden Club export/custom-schema evidence for `garden_event` and `plant_exchange`. | B13 |
| Book Club | Local install/open, book nomination, voting, meeting event RSVP, discussion message, selected-book publishing, search/AI answer, cited digest, export metadata. | B14 |
| Youth Soccer | Local install/open, guardian join and approval, team/roster view, protected minor-data redaction, registration payment through Loom payment surface, practice schedule, reminder notification, export metadata. | B14 |
| HOA | Local install/open, dues payment, member-visible document, facility reservation and payment, architectural request submission, committee workflow decision, owner notification, export evidence. | B14 |
| Mosque | Local install/open, public announcement, event RSVP, volunteer signup with protected contact field, anonymous donor visibility preference, donation payment and receipt, protected care request, neutral notification, public announcement search/AI citation. | B14 |
| Chess Club arbitrary package | Arbitrary package pair selection/import, parsed branding/card rendering, local latest open, route-defined home or workflow actions declared by the arbitrary package fixture. | B15 |
| Camera Club prompt-generated package | Prompt-generated local install/open, photo-walk RSVP, critique submission, gear-loan request, completion report with screenshot links for each workflow. | B15 |
| Platform Social test app | Messages entry, Connections entry, connection invite, blocked-target prevention, message stream rendering, in-stream ad disclosure, top-banner fill/no-fill, sensitive-context no-fill. | B16 |
| Ad-Off test app | Member ad-off checkout, community ad-off checkout, entitlement status, receipt evidence, ad suppression, settlement and utility allocation evidence. | B16 |
| Export/Migration test app | Import preview, import replay/idempotency, protected field routing/redaction, exportable custom-schema listing, full export, redacted export, checksum evidence, provider transfer verification, provider transfer rollback. | B16 |

## Planned Persona and Role Validation Matrix

The Demo App persona picker is a test harness only. In production, the active persona comes from the
logged-in user's identity, memberships, roles, and policy grants. The people icon in the Demo App lets
testers switch the simulated actor so each community can prove role-specific capability behavior.

Every B17-B20 persona evidence bundle must include:

- Persona inventory: community personas, role labels, actor IDs, grants, and relevant protected-data
  permissions.
- Workflow actor mapping: creator/initiator, approver/moderator, receiver/reader, payer, exporter, and
  blocked or unauthenticated states where applicable.
- Workflow dependency graph: prerequisite persona actions, records created, receiving personas, and
  ordering/idempotency requirements for dependent workflows.
- UX policy: whether each workflow is hidden, disabled with reason text, read-only, or transformed into
  a receiving surface for the selected persona.
- Multi-persona evidence: screenshots before persona switch, after persona switch, and at the receiving
  or continuation state.
- Per-persona workflow coverage: one test row for every persona/workflow combination, including
  authorized action, unauthorized action, hidden state, disabled state, read-only state, receiving state,
  or a documented not-applicable rationale.
- Backend parity: assertions that unauthorized personas cannot perform admin-only mutations and that
  receiving personas can observe only the records they should see.

| Community or test app | Personas and role-sensitive workflows to model | Phase |
| --- | --- | --- |
| Garden Club | Coordinator can create events, manage plant exchange, and export custom schemas; member can RSVP, submit exchange offers, and view relevant results. | B17-B20 |
| Book Club | Organizer can publish nominations, selected-book results, and digest prompts; member can nominate, vote, RSVP, discuss, search, and read digest output. | B17-B20 |
| Youth Soccer | Coach/admin can approve guardians, manage roster/schedule, and send reminders; guardian can register, pay, view permitted roster/schedule, and receive notifications; minor data remains protected. | B17-B20 |
| HOA | Board/committee can publish documents, decide architectural requests, and export records; homeowner can pay dues, reserve facilities, submit requests, and receive decisions. | B17-B20 |
| Mosque | Admin can publish public announcements, create events, coordinate volunteers, and send neutral care notifications; member can receive/search announcements, RSVP, volunteer, donate, choose donor visibility, and submit protected care requests. | B17-B20 |
| Chess Club arbitrary package | Organizer can schedule matches and export records; player can view schedule, join available matches, and receive updates. | B17-B20 |
| Camera Club prompt-generated package | Organizer can publish photo walks, review critique submissions, and manage gear loans; member can RSVP, submit critique, request gear, and receive status. | B17-B20 |
| Platform Social test app | Member, invited member, blocked user, and moderator/admin personas validate message, connection, block, stream, ad, and no-fill states. | B17-B20 |
| Ad-Off test app | Member purchaser, community admin purchaser, and ordinary member personas validate checkout, entitlement visibility, ad suppression, receipts, settlement, and utility allocation. | B17-B20 |
| Export/Migration test app | Provider admin, community owner, member, and receiving provider personas validate import preview/replay, protected redaction, exports, transfer verification, and rollback. | B17-B20 |

## Planned Production Workflow UX Quality Matrix

B21-B25 close the remaining gap between technically executable workflow evidence and production-level
workflow UX. A workflow is not production-ready when it is represented only by a generic workflow card,
metadata/settings page, test-harness text, or a dialog whose primary action is `Complete` or
`Complete workflow`.

Every B21-B24 production UX implementation bundle must include:

- Production workflow contract: real user goal, workflow type, actor persona, receiver persona,
  prerequisite state, Loom-owned services, extension-owned data, and expected end state.
- Domain surface: screen sections, real inputs, review/preview step when appropriate, validation
  errors, empty/loading states, destructive/secondary actions, and success or receipt state.
- Semantic actions: button labels must name the action a user is taking, such as `Publish announcement`,
  `RSVP to event`, `Submit care request`, `Approve request`, `Pay dues`, `Send invite`, `Export data`,
  or `Start transfer`.
- Persona behavior: actor, receiver, read-only, hidden, disabled-with-reason, and unrelated persona
  states must be specified and tested with production copy.
- Multi-persona continuity: when one persona creates, approves, or sends state, the receiving persona
  must see that state in a real recipient surface, not only in a test completion card.
- Evidence: screenshots for entry, input, validation or review, action, success/result, persona switch,
  receiver state, and unauthorized persona behavior where applicable.
- Failure gate: tests must fail if production workflow screens contain generic harness phrases such as
  `Complete workflow`, `Can perform this workflow`, `workflow evidence`, `local route`, or equivalent
  implementation-oriented copy.

B25 is a separate post-implementation product UX review. It must not be treated as a checklist that
simply confirms the planned workflow contract was implemented. The reviewer must inspect the visible
product experience from the user's perspective, identify improvements, and issue an explicit pass/fail
decision against production-grade UX standards. Passing workflow automation does not imply a B25 pass,
and removing obvious workflow-harness copy does not imply a B25 pass.
If B25 fails with any blocker or major finding, the phase enters a remediation loop: fix, rebuild,
relaunch, recapture evidence, regenerate the screen matrix, rerun the review, and repeat until blocker
and major counts are zero.
Each B25 loop iteration must be committed before the next UX feedback or remediation loop starts. The
iteration commit must include the current review/remediation evidence, screenshots or screenshot
references, tests run, remaining findings, and tracker/remediation-loop updates.

B25 must also run a fresh LLM Product Docs to Evidence Workflow Reconciliation Agent before the final
visual/product-quality judgment. This agent compares the Product Docs V2 community example docs, or the
standalone Skill's local community product doc, to the current screenshot-backed review evidence. It
must inspect `## 6. Workflow-To-Surface Mapping`, the persona/state matrix, content/seed requirements,
visual standard, B25 semantic interaction model, and card-surface registry. It fails when a doc row has
no screenshot-backed implementation, a screenshot-visible flow or UI interaction is missing from the
doc, required visible proof is absent, persona/lifecycle state is undocumented, or a primary user job is
mapped to a generic surface. Findings are routed as product-doc updates, implementation remediation,
evidence recapture, or mixed tickets.

B25 must also run a fresh LLM Vision UX Judge Agent before the deterministic Production UX Judge. The
LLM judge inspects screenshots as pixels/layout and answers the semantic product-quality questions; the
importer records that output as `llmVisionReview`. The Production UX Judge then validates five evidence
blocks: one LLM Product Docs to Evidence Workflow Reconciliation pass, one holistic product UX pass for
the whole app/community experience, one workflow/persona pass for every reviewed workflow/persona pair,
one semantic workflow interaction-model pass for every reviewed workflow/persona pair, and the imported
LLM vision review. All five must be green. The product-doc reconciliation pass guards against drift
between Product Docs V2 `## 6. Workflow-To-Surface Mapping` rows and screenshot evidence. The
holistic pass guards overall product coherence, navigation, modern visual quality, and
community-centered information architecture. The workflow/persona passes guard task clarity,
domain-native surfaces, natural actions, validation/result states, receiver states, and unauthorized/
read-only behavior. The interaction-model pass guards against incomplete action cards by requiring the
expected user decision, concrete object/context, decision information, semantically correct primary
action, domain-required alternate/change/reject affordance, persistent result state, and receiver/
continuation state from screenshots. The LLM vision review guards against the false-pass class where
deterministic keyword/pixel heuristics find no known defect while a fresh reviewer can still see a
workflow/test-harness or weak product experience.
Run `b25_llm_review_freshness_gate.dart` before the importer. The gate must pass on the raw LLM review
artifact, and it fails when the artifact carries a prior `sourceReviewRunId`, has `carriedForward` or
`reusedPriorReview` markers, omits `freshReview=true`, omits the current screenshot row/hash list, or
does not match the current app commit/run ID.

After every B25 review/remediation pass, generate a B25 iteration scorecard. It must record current
critical/blocker and major counts, unresolved blocker/major counts, resolved blocker/major counts for
that pass, newly introduced blocker/major counts, production judge failures, direct-question pass
status, and required next action. Use the scorecards to show the remediation loop is converging toward
zero unresolved blocker/major findings.

Before the judges run, use `b25_evidence_collector.dart` to produce the schema v4 evidence from live
workflow UI evidence. The collector is the deterministic Evidence Collector Tool for B25: it records
screenshot paths, hashes, captured-at timestamps, device metadata, visible text source, app commit SHA,
and screen-row scaffolding, but it cannot make the production UX pass/fail decision. Then run
`b25_workflow_persona_coverage_collector.dart` to prove that every reviewed workflow/persona
combination has explicit evidence before `b25_independent_ux_judge.dart` normalizes the deterministic
review scaffold. Then run the LLM Vision UX Judge Agent on screenshots and import its structured output
only after `b25_llm_review_freshness_gate.dart` proves it is fresh for the current run, app commit,
screen rows, and screenshot hashes. Then import with `b25_llm_ux_review_importer.dart`; this is the
semantic product-quality review. Then run `b25_workflow_interaction_model_judge.dart` to produce
semantic interaction-model scorecards from the same screenshots. `production_ux_judge.dart` is the
deterministic validator that scores the scaffold, product-doc reconciliation artifact, LLM vision
review, lifecycle outputs, and emits remediation tickets.

Every B25 independent UX review must include:

- Fresh walkthroughs of the actual app surfaces after B22-B24, using the visible Android emulator and
  screenshots from the final evidence bundle.
- A complete product UX screen review matrix with one row for every implemented screen, state, dialog,
  card, feed item, form, confirmation, error, empty state, persona variant, and action result. Sampling
  is not allowed.
- Findings ranked by severity: blocker, major, minor, or polish.
- Review dimensions covering information architecture, visual hierarchy, interaction clarity, semantic
  labels, mobile layout, accessibility, empty/loading/error states, trust/privacy/payment clarity,
  persona relevance, multi-persona handoffs, content tone, brand/community identity, modern visual
  quality, component variety, information density, and overall product fit.
- A product-readiness critique that fails user-facing global workflow lists, exposed category/surface
  taxonomy, implementation rationale copy, metadata-only cards, missing domain-native sections, or
  missing realistic task content.
- A modern-product critique that fails generic demo-scaffold styling, repeated workflow-card primary
  UX, checklist modals, overlapping floating controls, clipped text, weak visual hierarchy, thin
  placeholder content, and screens that look materially below a shippable mobile app.
- A per-community production UX blueprint before any pass verdict. The blueprint must define target
  personas, community identity, home information architecture, required product surfaces, workflow-to-
  surface mapping, realistic content requirements, visual/interaction standards, and concrete pass
  examples for every community/test app and persona.
- A screen-specific critique requirement: every matrix row must include findings grounded in that
  screenshot and persona. Repeated boilerplate rationale across unrelated rows is invalid B25 evidence.
- Holistic direct-question evidence answering whether the whole experience is production-grade, modern,
  easy to use and navigate, visually appealing, community-centered, and free of major layout/content
  defects.
- Workflow/persona direct-question evidence for every workflow/persona pair, with visible evidence and
  critique for task clarity, domain-native primary surface, natural actions, inputs/validation/results,
  receiver or unauthorized states, and workflow-level production feel.
- B25 iteration scorecards for every pass, including current counts, resolved blocker/major counts,
  new blocker/major counts, production judge failures, and next action.
- Schema version 4 machine-readable review evidence with review standard version, superseded prior run
  IDs, blueprint coverage, unique screen-row IDs, screenshot hash, screenshot captured-at timestamp, app
  commit SHA, emulator/device metadata, visible-text extract, UI-pattern classification, primary surface
  type, screen-specific critiques, stable finding/remediation IDs, before/after screenshot references,
  unresolved severity counts, rerun requirements, and final pass/fail decision.
- Screenshot freshness validation. A row is invalid if its screenshot predates the app commit or
  remediation it claims to prove, if a resolved finding points to a pre-fix screenshot, or if the JSON,
  markdown, and tracker disagree about the active review run.
- Domain-native primary-surface validation. Every primary workflow surface must be classified as
  domain-native or fail. Generic workflow cards, checklist/review modals, metadata/settings pages, and
  repeated-card shells may not pass as the primary UX for real community tasks.
- Boilerplate review validation. Every row must describe visible elements and visible text from the
  screenshot; repeated generic rationale across unrelated rows invalidates the review.
- Per-screen verdicts that answer whether the surface feels like a real product screen, exposes
  implementation/test/workflow language, uses domain-native IA, contains realistic content, has natural
  labels/actions, is visually modern and mobile-appropriate, and supports the target user's real task.
- Improvement recommendations that are not limited to missing workflow requirements.
- A pass/fail decision. Passing requires no unresolved blocker or major UX issues; minor issues must be
  resolved, explicitly accepted by the owner, or tracked with rationale.
- A remediation loop log for every failed B25 run, including root-cause clusters, fix batches, tests,
  refreshed screenshots, remaining blocker/major counts, and the next iteration decision.
- A git commit SHA for every B25 loop iteration before the next UX feedback or correction batch starts.
- A supersession rule: when the B25 review standard changes, any prior pass is historical only. The
  phase must be reopened, the prior evidence must be marked stale/superseded, and B25 cannot pass again
  until the latest standard is rerun successfully.

## Independent UX Judge Tool Gates

Use the judge tool contracts in [Tools/ux-gate-judge-tools.md](./Tools/ux-gate-judge-tools.md). These
tools keep the implementation worker separate from the pass/fail judge.

| Phase | Judge tool | Required output | Blocks phase when |
| --- | --- | --- | --- |
| B11 | `workflow_completeness_judge.dart` | `workflow-completeness-scorecard.json/.md` | The Skill drops a requested workflow, omits package artifacts, or lacks Demo App validation. |
| B21 | `ux_contract_judge.dart` | `ux-contract-scorecard.json/.md` | A workflow/persona contract lacks real user goal, domain surface, inputs, validation, semantic action, success state, receiver state, or screenshot plan. |
| B22 | `domain_surface_classifier.dart` | `domain-surface-scorecard.json/.md` | A primary workflow remains a generic workflow-card, checklist modal, metadata page, repeated card shell, or global workflow list. |
| B23 | `persona_ux_judge.dart` | `persona-ux-scorecard.json/.md` | Actor, receiver, read-only, disabled, hidden, or unauthorized persona evidence is missing or contradictory. |
| B24 | `evidence_integrity_auditor.dart` | `evidence-integrity-scorecard.json/.md` | Screenshots, hashes, timestamps, app commit SHA, device metadata, visible text, or generic-copy audit evidence is missing/stale. |
| B25 | Product Experience Doc Steward; advisory Card-Surface Registry Refresh; `b25_evidence_collector.dart`; LLM Product Docs to Evidence Workflow Reconciliation Agent; LLM Vision UX Judge Agent; `b25_llm_review_freshness_gate.dart`; `b25_llm_ux_review_importer.dart`; `b25_workflow_interaction_model_judge.dart`; `production_ux_judge.dart`; `b25_iteration_scorecard.dart`; next-pass `b25_remediation_planner.dart` | Current pass: community product experience docs with advisory card-surface registry sections, derived `production-ux-blueprint.md`, `llm-product-doc-workflow-reconciliation-<run-id>.json/.md`, `llm-vision-ux-review-<run-id>.json`, `b25-llm-review-freshness-gate-<run-id>.json/.md`, `independent-production-ux-review.json/.md` with `llmVisionReview`, `product-ux-screen-review-matrix.md`, `b25-workflow-lifecycle-scorecards.md`, `production-ux-criteria-scorecard.json/.md`, `b25-remediation-tickets-<run-id>.json/.md`, `b25-iteration-scorecard-*.json/.md`, plus `productDocCoverage`, `cardSurfaceRegistry`, `productDocWorkflowReconciliation`, `holisticQuestionAnswers`, `workflowPersonaScorecards`, `workflowLifecycleScorecards`, and `llmVisionReview` in review JSON. Next pass kickoff: `b25-remediation-plan-<prior-run-id>.json/.md`. | Product docs are missing or stale, advisory registry context is absent from B25 evidence, no fresh LLM product-doc reconciliation exists, the reconciliation has unresolved blocker/major product-doc/implementation/evidence/mapping gaps, evidence was not collected by the deterministic collector, no fresh LLM vision review passed the freshness gate and importer, any LLM vision finding blocks pass, any B25 pass criterion has a blocking failure without a template-complete remediation ticket, any direct-question or interaction-model pass is missing/partial/unsupported, any primary workflow surface is not domain-native, any primary workflow interaction model lacks expected decision, concrete object/context, decision information, primary action, alternate/change/reject path, result state, receiver/continuation state, or fresh screenshot proof, or the iteration scorecard is missing for the pass. A remediation pass fails before implementation if the prior pass's tickets were not sent to the planner; a product-spec-gap fails if the product doc was not updated before UI remediation. Advisory registry gaps should be recorded for remediation context, but they are not yet a standalone card-surface/API coverage gate. |

Judge agents may receive only artifacts, screenshots, blueprint/contracts, pass criteria, evidence
metadata, and remediation logs. They must not receive worker implementation notes or intended behavior
summaries. If the evidence does not prove a criterion, the criterion fails.

| Workflow category | Production UX requirements | Evidence phase |
| --- | --- | --- |
| Event and RSVP workflows | Event details, schedule/location/capacity when available, RSVP state, cancel/change action if supported, confirmation surface, receiver calendar/notification state. | B21-B25 |
| Payment, donation, dues, and ad-off workflows | Amount, payer, visibility or entitlement choice, Loom payment surface handoff, receipt, settlement/utility state when relevant, failure and retry state. | B21-B25 |
| Forms, protected care, volunteer, exchange, critique, and gear workflows | Labeled fields, protected/private data indicators, validation, submit/review, saved request state, recipient/admin review state. | B21-B25 |
| Announcement, publishing, notification, and digest workflows | Compose or source selection, audience, preview, publish/send action, recipient inbox/feed/search state, citation/source state for AI output. | B21-B25 |
| Approval, moderation, and decision workflows | Pending record details, approve/reject/comment actions, decision audit, requester notification/receiver state, unauthorized denial. | B21-B25 |
| Search, AI, and discovery workflows | Query input, scoped result list, cited answer/source, empty/error state, privacy/protected-data guardrails. | B21-B25 |
| Export, import, migration, and transfer workflows | Scope selection, redaction preview, checksum/status, transfer verification, rollback/failure path, downloadable/export evidence. | B21-B25 |
| Messages, connections, ads, and platform shell workflows | Real message/connection/ad surfaces, invite/block outcomes, ad disclosure or no-fill state, required App Shell navigation preserved. | B21-B25 |

## UX Methodology Reset - 2026-06-09

R20 was added after A6, B1a, B1b, B2, and B3 had already been marked complete. Those phases are now
reopened for UX methodology only. Their prior implementation commits remain useful technical evidence,
but the phases are not considered fully closed until their UX Decisions files are recreated with the
new method and the affected regressions pass again.

| Phase | Prior closeout commit | Current status | Required UX recreation |
| --- | --- | --- | --- |
| 0 | `17b4b81`; R20 closeout `b838fa8` | Complete | R20 rules, UX Decisions templates, phase instructions, and tracker reset are now the Phase 0 second-pass baseline. |
| A6 | `0346c99`; R20 closeout `39af637` | Complete | Recreated App Shell, UX micro-component, Demo App empty/load/import, branded card, local backend, ad slot, payment surface, data dashboard, and required shell-surface UX decisions using R20. |
| B1a | `df6f543`; R20 closeout `471677a` | Complete | Recreated local-demo build/download/sideload/install UX decisions using R20, including local file picker/path entry, validation errors, import progress/status, duplicate import, rollback tradeoff, card branding fallback, and local latest-open states. |
| B1b | `7825b59`; R20 closeout `105cb16` | Complete | Recreated real-backend-publish, certification, permission review, QR/handle discovery, install preview, and latest-certified open UX decisions using R20. |
| B2 | `e362090`; R20 closeout `e97ba72` | Complete | Recreated book club nomination, voting, event, RSVP, discussion, digest, citations, and local card/open UX decisions using R20. |
| B3 | `36aee10`; R20 closeout `23dd422` | Complete | Recreated youth soccer guardian join, protected minor data, roster, registration payment, schedule, notification, and local card/open UX decisions using R20. |
| B4 | None | Complete | Completed HOA dues, documents, facilities, architectural review, export, and local card/open UX decisions using R20. |
| B5 | None | Complete | Completed mosque announcement, event, volunteer, donation, donor visibility, protected care request, notification, and local card/open UX decisions using R20. |
| B6 | None | Complete | Completed Messages, Connections, stream rendering, in-stream ad disclosure, top banner, no-fill, and block/invite UX decisions using R20. |
| B7 | None | Complete | Completed ad-off checkout, entitlement, status, receipt, ad preference, ad suppression, sensitive no-fill, settlement, and utility allocation UX decisions using R20. |
| B8 | None | Complete | Completed export scope, redaction, checksums, transfer verify/rollback, retained-record disclosure, API inventory, and readiness-summary UX decisions using R20. |
| B12-B16 | None | Complete | Completed R20 UX Decisions for each UI evidence phase, including reference sources, extracted patterns, workflow walkthroughs, screenshot acceptance criteria, and open tradeoffs. |
| B17-B20 | None | Complete | Completed R20 UX Decisions for persona/role phases, including role inventory, persona picker UX, actor/receiver/read-only/disabled workflow policy, multi-persona walkthroughs, screenshot acceptance criteria, and open tradeoffs. |
| B21-B24 | None | Complete | Production workflow contracts, semantic workflow action coverage, persona-specific recipient states, screenshot evidence, and generic harness-copy rejection are complete. |
| B25 | None | Reopened | Product-UX v4 pass 19 failed under the fresh-LLM hardening rule with 3 unresolved major findings and 8 remediation tickets. Pass 20 must start from `b25-remediation-plan-b25-v4-pass-20.md`, then implement fixes, recapture full B12-B20 evidence, rerun the fresh LLM Vision UX review, and regenerate tickets/scorecard. |

Closeout rule for reopened phases:

1. Complete the phase's UX Decisions file with current reference sources, extracted patterns, key UX
   decisions, key implementation decisions, workflow walkthrough, and open tradeoffs.
2. Apply any UX-driven implementation/test changes.
3. Rerun the phase workflow and all affected regressions.
4. Update manifest/test stamps if tests or UX-owned component behavior changed.
5. Commit the phase closeout and replace the temporary closeout SHA in the status table.

## Per-Phase Completion Ledger

### Phase 0 - Initialize Build

- **Achieves:** Creates the build constitution and all control artifacts.
- **Deliverables:** `Rules.md`, `test-manifest.json`, `Test Manifest.md`, Build Tracker, Skill skeleton,
  Skill setup docs, prereq manifest, placeholder validation environment lock, workspace package
  placeholders, `manifest_gate`, `phase_gate`, API inventory placeholder.
- **Completed when:** Manifest parses; planned/pending tests are registered; Skill skeleton exists;
  Skill setup manifest and placeholder lock parse; workspace scaffolds and gate placeholders exist; API
  Review is filed; tracker records SHA.
- **Evidence to record:** Manifest parse output, prereq manifest parse output, placeholder lock parse
  output, gate placeholder output, created package paths, API Review path, Skill paths, commit SHA.

#### Execution Record - 2026-06-08

- **Created/confirmed scaffold:** `apps/loom_communities_demo`, `loom_extension_package`,
  `loom_demo_local_backend`, `api_spec_inventory`, `loom_skill_prereq_setup`,
  `loom_skill_debug_harness`, and top-level tooling scripts for manifest, phase, prereq setup, and
  prereq check gates.
- **Registered workspace entries:** Added the new V2 app/package namespaces to `app/pubspec.yaml`; added
  melos commands for `manifest:gate`, `phase:gate`, `skill:prereq:check`, and `skill:prereq:setup`.
- **Passed checks:** `test-manifest.json`, `prereq-manifest.json`, and
  `validation-environment.lock.json` parse; manifest component/test references validate; Skill prereq
  targets are `codex` and `claude-code`; required scaffold paths exist; melos gate scripts are present.
- **WSL toolchain:** Ubuntu 24.04 on WSL2; `dart` resolves to `/home/fahd_/flutter/bin/dart`,
  `flutter` resolves to `/home/fahd_/flutter/bin/flutter`, and `melos` resolves to
  `/home/fahd_/.pub-cache/bin/melos`.
- **Passed WSL checks:** `dart format` on Phase 0 scaffold files; `melos bootstrap` with 36 packages;
  `dart run packages/tooling/manifest_gate.dart --manifest ../docs/Build\ Plan\ V2/test-manifest.json`;
  `dart run packages/tooling/phase_gate.dart --phase 0 --check-env`; `dart run
  packages/tooling/skill_prereq_check.dart --mode local-demo`; `dart run
  packages/tooling/skill_prereq_setup.dart --target codex --mode local-demo`; `melos run
  manifest:gate`; `melos run phase:gate`; `melos run skill:prereq:check`; `melos run
  skill:prereq:setup`; `melos run lint:boundaries`; focused `flutter analyze` / `dart analyze` on the
  Phase 0 scaffold packages and tooling scripts.
- **Notes:** Full historical workspace `melos run analyze` exceeded the command timeout; focused analysis
  of the Phase 0 scaffold passed. No Set A phase has started.

#### Second-Pass Execution Record - 2026-06-09

- **R20 baseline:** Added R20 as the required UX research and decision gate; updated Phase 0, the Build
  Plan README, and every UX-bearing phase file so UX Decisions are completed before implementation.
- **UX Decisions standard:** Updated the UX Decisions siblings for A6 and B1a-B8 to require reference
  sources reviewed, UX patterns extracted, key UX decisions, key implementation decisions, workflow
  walkthrough, and open questions / tradeoffs.
- **Tracker reset:** Reopened A6, B1a, B1b, B2, and B3 for UX-methodology closeout; marked B4-B8 as
  R20-required-before-implementation; kept the prior technical closeout commits as historical evidence.
- **Passed WSL checks:** `dart run packages/tooling/manifest_gate.dart --manifest ../docs/Build\ Plan\ V2/test-manifest.json`;
  `dart run packages/tooling/phase_gate.dart --phase 0 --check-env`; `dart run
  packages/tooling/skill_prereq_check.dart --mode local-demo`; `melos run lint:boundaries`; `git diff --check`.
- **Commit:** R20 baseline closeout `b838fa8`.

### Phase A1 - Foundation Components

- **Achieves:** Builds the lowest layer used by every other component.
- **Deliverables:** Passport, role/policy/consent, core vault, protected vault, connections graph,
  receipt ledger, audit ledger, event bus, key management, builder App ID, local store baseline.
- **Completed when:** Each foundation component has contract, fake, owned data, validation tests,
  consumer-contract tests for dependents, Skill component guide, API Review entry, and current manifest
  version stamp.
- **Evidence to record:** A1 validation and contract test output, component hashes, API Review path,
  Skill component guide paths, commit SHA.

#### Execution Record - 2026-06-09

- **Contracts:** Added `CommunityPassportApi`, `CommunityRolePolicyApi`, `CommunityCoreVaultApi`,
  `CommunityProtectedVaultApi`, `CommunityConnectionsApi`, `CommunityReceiptLedgerApi`,
  `CommunityAuditApi`, `CommunityEventBusApi`, `CommunityKeyManagementApi`, and
  `CommunityBuilderAppIdApi`.
- **Fakes and harness:** Added `CommunityFoundationFakeBackend`, A1 owned-table schema metadata, A1 seed
  fixture, and `test/a1_foundation_components_test.dart`.
- **Skill/API docs:** Added ten Skill component guides and completed `Phase A1 - API Review.md`.
- **Manifest:** A1 validation tests are stamped `pass`; higher-layer consumer-contract tests remain
  `pending-counterpart`.
- **Passed WSL checks:** `dart test test/a1_foundation_components_test.dart`; `melos exec
  --scope=loom_fake_backend --dir-exists=test -- dart test`; `dart analyze` on touched A1 packages;
  `dart run packages/tooling/manifest_gate.dart --manifest ../docs/Build\ Plan\ V2/test-manifest.json`;
  `dart run packages/tooling/phase_gate.dart --phase A1 --check-env`; `melos run lint:boundaries`.

### Phase A2 - Registry and Control-Plane Components

- **Achieves:** Establishes community, branding, membership, extension, certification, and discovery
  control planes.
- **Deliverables:** Community registry, community branding fields, spaces, membership, invitations,
  extension registry, certification system with asset evidence checks, public registry read model,
  workflow inventory registry.
- **Completed when:** Registry components pass their own validation tests and all available contract tests
  to/from A1 providers; pending higher-layer consumer tests are registered.
- **Evidence to record:** A2 gate output, manifest staleness output, component hashes, API Review path,
  Skill guide paths, commit SHA.

#### Execution Record - 2026-06-09

- **Contracts:** Added `CommunityWorkflowInventoryApi`, `CommunityTestManifestApi`,
  `CommunityRegistryApi`, `CommunitySpacesApi`, `CommunityMembershipApi`, `CommunityInvitationApi`,
  `CommunityCertificationApi`, `CommunityExtensionRegistryApi`, and `CommunityPublicRegistryApi`.
- **Fakes and harness:** Added `CommunityRegistryControlPlaneFakeBackend`, A2 owned-table schema
  metadata, A2 seed fixture, and `test/a2_registry_control_plane_test.dart`.
- **Skill/API docs:** Added nine Skill component guides and completed `Phase A2 - API Review.md`.
- **Manifest:** A2 validation tests and built-counterpart contract tests are stamped `pass`; App Shell
  consumer-contract tests remain `pending-counterpart`; A1 connections and builder App ID contract
  tests are now unblocked and stamped `pass`.
- **Passed WSL checks:** `dart test test/a1_foundation_components_test.dart
  test/a2_registry_control_plane_test.dart`; `dart analyze` on touched A1/A2 packages; `dart run
  packages/tooling/manifest_gate.dart --manifest ../docs/Build\ Plan\ V2/test-manifest.json`; `dart run
  packages/tooling/phase_gate.dart --phase A2 --check-env`; `melos run lint:boundaries`.

### Phase A3 - Service Components I

- **Achieves:** Adds core community interaction services.
- **Deliverables:** Publishing, messaging/stream, notifications, events, forms/polls/voting.
- **Completed when:** Experience services pass validation, consume A1/A2 providers only through
  contracts/fakes, publish dependent test kits, and update Skill/API docs.
- **Evidence to record:** A3 component test output, dependency-fake evidence, manifest updates, API Review
  path, Skill guide paths, commit SHA.

#### Execution Record - 2026-06-09

- **Contracts:** Added `CommunityPublishingApi`, `CommunityMessagingApi`, `CommunityNotificationApi`,
  `CommunityEventsApi`, and `CommunityFormsVotingApi`.
- **Fakes and harness:** Added `CommunityExperienceServicesFakeBackend`, A3 owned-table schema metadata,
  A3 seed fixture, and `test/a3_experience_services_test.dart`.
- **Skill/API docs:** Added five Skill component guides and completed `Phase A3 - API Review.md`.
- **Manifest:** A3 validation tests are stamped `pass`; `ct_forms-voting__protected-vault_sensitive-fields`
  is stamped `pass`; A4b/A5/A6 consumer-contract tests remain `pending-counterpart`.
- **Passed WSL checks:** `dart test test/a1_foundation_components_test.dart
  test/a2_registry_control_plane_test.dart test/a3_experience_services_test.dart`; `dart analyze` on
  touched A1-A3 packages; `dart run packages/tooling/manifest_gate.dart --manifest
  ../docs/Build\ Plan\ V2/test-manifest.json`; `dart run packages/tooling/phase_gate.dart --phase A3
  --check-env`; `melos run lint:boundaries`.

### Phase A4a - Service Components II

- **Achieves:** Adds operational and community-management services.
- **Deliverables:** Case/task, documents, facilities, import, export, provider transfer, abuse report,
  moderation case, incident, dispute scaffolding.
- **Completed when:** Ops/community services pass validation and unblocked contract tests; export/import
  use contracts instead of reading sibling storage directly.
- **Evidence to record:** A4a gate output, component hashes, import/export contract evidence, API Review
  path, Skill guide paths, commit SHA.

#### Execution Record - 2026-06-09

- **Contracts:** Added `CommunityCaseTaskApi`, `CommunityDocumentsApi`, `CommunityFacilitiesApi`,
  `CommunityImportApi`, `CommunityExportApi`, `CommunityProviderTransferApi`,
  `CommunityAbuseReportApi`, `CommunityModerationApi`, `CommunityIncidentApi`, and
  `CommunityDisputeApi`.
- **Fakes and harness:** Added `CommunityOpsServicesFakeBackend`, A4a owned-table schema metadata, A4a
  seed fixture, and `test/a4a_ops_services_test.dart`.
- **Skill/API docs:** Added ten Skill component guides and completed `Phase A4a - API Review.md`.
- **Manifest:** A4a validation tests and built-counterpart contract tests are stamped `pass`;
  A4b/A5 consumer-contract tests remain `pending-counterpart`.
- **Component versions:** abuse-report-service `5c220d916543`; case-task-service `e8924d019980`;
  dispute-service `5f035552f46b`; documents-service `bc037ffdc17c`; export-service
  `9079b5ad7e37`; facilities-service `0c23efd3c350`; import-service `0a178c20caba`;
  incident-service `d6d2177db39e`; moderation-case-service `860c5e41ffe4`;
  provider-transfer-service `91de09a48370`.
- **Passed WSL checks:** `dart test test/a1_foundation_components_test.dart
  test/a2_registry_control_plane_test.dart test/a3_experience_services_test.dart
  test/a4a_ops_services_test.dart`; `dart analyze` on touched A1-A4a packages; manifest and phase
  gates; boundary lint.

### Phase A4b - Service Components III

- **Achieves:** Adds economic, search, AI, ad, and settlement services.
- **Deliverables:** Wallet/dues/donations, ad decision, ad campaign, search, AI gateway, digest,
  settlement, utility funding, fraud signals.
- **Completed when:** Economic/search/ad services pass validation and unblocked contract tests; ad-off,
  protected no-fill, receipts, settlement, and search permission checks are testable.
- **Evidence to record:** A4b gate output, component hashes, ad/search/payment test output, API Review
  path, Skill guide paths, commit SHA.

#### Execution Record - 2026-06-09

- **Contracts:** Added `CommunityWalletApi`, `CommunityAdCampaignApi`, `CommunityAdDecisionApi`,
  `CommunityIndexingApi`, `CommunitySearchApi`, `CommunityAiGatewayApi`, `CommunityDigestApi`,
  `CommunitySettlementApi`, `CommunityUtilityFundingApi`, and `CommunityFraudApi`.
- **Fakes and harness:** Added `CommunityEconomicServicesFakeBackend`, A4b owned-table schema metadata,
  A4b seed fixture, and `test/a4b_economic_services_test.dart`.
- **Skill/API docs:** Added ten Skill component guides and completed `Phase A4b - API Review.md`.
- **Manifest:** A4b validation and built-counterpart contract tests are stamped `pass`; A1/A3/A4a
  provider contracts unblocked by A4b are stamped `pass`; App Shell, stream renderer, and payment
  surface consumer tests remain `pending-counterpart`.
- **Component versions:** ad-campaign-service `7d781eea95a9`; ad-decision-service `e5a7593ee1ea`;
  ai-gateway `66fa617e8d1b`; digest-service `d6d8d601ba0a`; fraud-signal-service
  `e82f961e8a1d`; indexing-service `085147318d54`; search-service `00f0b4124434`;
  settlement-engine `12129ce8f929`; utility-funding-service `9e0362c7cc0f`;
  wallet-dues-donations `071871e00937`.
- **Passed WSL checks:** `dart test test/a1_foundation_components_test.dart
  test/a2_registry_control_plane_test.dart test/a3_experience_services_test.dart
  test/a4a_ops_services_test.dart test/a4b_economic_services_test.dart`; `dart analyze` on touched
  A1-A4b packages; manifest and phase gates; boundary lint.

### Phase A5 - Extension Engine Components

- **Achieves:** Builds the extension execution and packaging layer.
- **Deliverables:** Extension runtime bridge, rule engine, workflow engine, job scheduler, function
  runtime, data schema store, secrets/connector broker, extension package validator, initialization
  package schema, asset manifest validator, initialization branding schema.
- **Completed when:** Engine components pass validation and contract tests; extension package and
  initialization package contracts validate; asset manifest/policy checks pass; Skill guides explain
  local package generation, bundled assets, card defaults, and fake backend seeding.
- **Evidence to record:** A5 gate output, package validator output, asset validator output,
  initialization schema/branding validation, component hashes, API Review path, Skill guide paths,
  commit SHA.

#### Execution Record - 2026-06-09

- **Contracts:** Added `CommunityExtensionRuntimeApi`, `CommunityRuleEngineApi`,
  `CommunityWorkflowApi`, `CommunityJobSchedulerApi`, `CommunityFunctionRuntimeApi`,
  `CommunityDataSchemaApi`, `CommunitySecretsConnectorApi`, `CommunityExtensionPackageApi`, and
  `CommunityInitializationPackageApi`.
- **Fakes and harness:** Added `CommunityEngineServicesFakeBackend`, A5 owned-table schema metadata,
  A5 seed fixture, and `test/a5_engine_services_test.dart`.
- **Skill/API docs:** Added nine Skill component guides and completed `Phase A5 - API Review.md`.
- **Manifest:** A5 validation and built-counterpart contract tests are stamped `pass`; A1/A3/A4a
  provider contracts unblocked by A5 are stamped `pass`; App Shell, Demo loader, and local in-app
  backend consumer tests remain `pending-counterpart`.
- **Component versions:** extension-runtime-bridge `1aff2ed72457`; rule-engine `b5071a6c9402`;
  workflow-engine `15f4ac99a8db`; job-scheduler `1f5f4cd3da14`; function-runtime
  `875d131947fb`; data-schema-store `6a09d351f11f`; secrets-connector-broker
  `b008328af7af`; extension-package-validator `512380dc6848`; initialization-package-schema
  `1dd4a2b2ca52`.
- **Passed WSL checks:** `dart test test/a1_foundation_components_test.dart
  test/a2_registry_control_plane_test.dart test/a3_experience_services_test.dart
  test/a4a_ops_services_test.dart test/a4b_economic_services_test.dart test/a5_engine_services_test.dart`;
  `dart analyze` on touched A1-A5 packages; manifest and phase gates; boundary lint.

### Phase A6 - UX Components

- **Achieves:** Builds the UX micro-components and the local demo runtime.
- **Deliverables:** App Shell, community card, navigation panel, stream renderer, connections shell, ad
  slots, payment surface, data dashboard, Loom Communities Demo App, Local In-App Backend Adapter.
- **Completed when:** App starts empty, `Add Community` is reachable, local package files can be loaded,
  initialization data and branding import into fake backend/local DB, community cards render with image
  fallback priority, and App Shell invariants pass.
- **Evidence to record:** A6 visual/interaction output, Demo App local backend tests, local persistence
  tests, branded-card screenshot/output, API Review and UX Decisions paths, Skill guide paths, commit
  SHA.

#### Execution Record - 2026-06-09

- **Contracts:** Added App Shell and UX micro-component contracts in `loom_app_shell`, local backend
  contracts in `loom_demo_local_backend`, and an enabled Add Community local load flow in
  `loom_communities_demo`.
- **Tests:** Added `test/a6_app_shell_components_test.dart`, `test/a6_local_backend_test.dart`, and
  `test/a6_loom_communities_demo_test.dart`.
- **Skill/API/UX docs:** Added ten Skill component guides and completed `Phase A6 - API Review.md` and
  `Phase A6 - UX Decisions.md`.
- **Manifest:** A6 validation and contract tests are stamped `pass`; all Set A pending counterpart tests
  are resolved.
- **Component versions:** ad-slots `12d754c97f76`; app-shell-runtime `c7c0a602fdad`;
  community-card `690cea54a8d2`; connections-shell `212f751b3eb5`; data-dashboard-consent
  `917fd80d8266`; local-in-app-backend `332432d7b39d`; loom-communities-demo-app
  `fe03608c5230`; navigation-panel `ffc2aecac272`; payment-surface `637ca25646d9`;
  stream-renderer `07547f0370c6`.
- **Passed WSL checks:** `flutter test packages/core/loom_app_shell/test/a6_app_shell_components_test.dart`;
  `dart test test/a6_local_backend_test.dart`; `flutter test
  apps/loom_communities_demo/test/a6_loom_communities_demo_test.dart`; A1-A5 component regression tests;
  focused `flutter analyze`; manifest and phase gates; boundary lint.
- **R20 reopen note:** This technical closeout predates the R20 UX research/decision gate. Recreate
  `Phase A6 - UX Decisions.md` with the new method, apply any UX-driven changes, rerun affected
  regressions, and record a new closeout commit before A6 can be treated as complete again.

#### Second-Pass Execution Record - 2026-06-09

- **R20 UX decisions:** Completed `Phase A6 - UX Decisions.md` with current reference sources, extracted
  patterns, key UX decisions, implementation decisions, workflow walkthrough, and tradeoffs.
- **UX-driven fix:** The empty-state Add Community CTA now uses the same local-load handler as the
  shell floating Add Community action, so the first-run state provides a direct path to install.
- **Tests:** Added `vt_demo-app_empty-state-cta-loads-community` and registered it in the machine and
  human test manifests.
- **Component version update:** `loom-communities-demo-app` is now stamped `fe03608c5230`.
- **Passed WSL checks:** `dart format apps/loom_communities_demo/lib/main.dart
  apps/loom_communities_demo/test/a6_loom_communities_demo_test.dart`; `flutter test
  packages/core/loom_app_shell/test/a6_app_shell_components_test.dart`; `dart test
  packages/core/loom_demo_local_backend/test/a6_local_backend_test.dart`; `flutter test
  apps/loom_communities_demo/test/a6_loom_communities_demo_test.dart`; `flutter test
  apps/loom_communities_demo/test/b1a_local_workflow_test.dart
  apps/loom_communities_demo/test/b1b_publish_discover_install_test.dart
  apps/loom_communities_demo/test/b2_book_club_workflow_test.dart
  apps/loom_communities_demo/test/b3_youth_soccer_workflow_test.dart`; `flutter analyze
  apps/loom_communities_demo`; `dart run packages/tooling/manifest_gate.dart --manifest
  ../docs/Build\ Plan\ V2/test-manifest.json`; `dart run packages/tooling/phase_gate.dart --phase
  A6 --check-env`; `melos run lint:boundaries`; `git diff --check`.
- **Commit:** R20 closeout `39af637`.

### Phase B1a - Local Build, Download, Sideload, Install

- **Achieves:** Proves the preliminary product flow without a hosted backend.
- **Deliverables:** Skill prereq setup, validation environment lock, Skill `local-demo` workflow,
  downloadable extension package, downloadable initialization package, bundled brand assets, Skill
  debug golden fixture, Demo App local file load, fake backend import, branded community card render,
  local App Shell open.
- **Completed when:** `wf_local-demo-prereq-to-validation-ready` and
  `wf_local-build-download-sideload-install` pass against the Demo App with Local Backend; the selected
  execution target is Codex or Claude Code; the app starts with zero communities, loads the first
  community from local files, imports fake backend data and branding assets, persists them, renders the
  branded card, and opens the extension.
- **Evidence to record:** Environment lock hash, prereq setup output, workflow output, Skill
  prompt/transcript/golden package hashes, package validator output, asset validator output, fake
  backend import report, branded-card screenshot/output, API Review and UX Decisions paths, commit SHA.

#### Execution Record - 2026-06-09

- **Validated Skill setup:** `validation-environment.lock.json` is `validated` for Codex `local-demo`
  execution in WSL Ubuntu with Dart, Flutter, and Melos resolved from the Ubuntu toolchain.
- **Implemented workflow test:** Added
  `apps/loom_communities_demo/test/b1a_local_workflow_test.dart` covering
  `wf_local-demo-prereq-to-validation-ready` and `wf_local-build-download-sideload-install`.
- **Skill and examples:** Added the local build/download/sideload workflow guide and a book-club
  extension/init-package example under `Skill/examples/book-club/phase-b1a-local/`.
- **Manifest stamps:** Skill/prereq/tooling components now have concrete version hashes:
  ai-skill-extension-builder `b06a5c0bdc86`, skill-prereq-setup `8517e97898ef`,
  workflow-validation-harness `37f93fec7784`, and skill-debug-harness `809fc9cb1902`.
- **Passed WSL checks:** `melos bootstrap`; `flutter test
  apps/loom_communities_demo/test/b1a_local_workflow_test.dart
  apps/loom_communities_demo/test/a6_loom_communities_demo_test.dart`; `flutter analyze
  apps/loom_communities_demo`; `dart run packages/tooling/skill_prereq_check.dart --mode local-demo`;
  `dart run packages/tooling/skill_prereq_setup.dart --target codex --mode local-demo`; `dart run
  packages/tooling/manifest_gate.dart --manifest ../docs/Build\ Plan\ V2/test-manifest.json`; `dart run
  packages/tooling/phase_gate.dart --phase B1a --check-env`; `melos run lint:boundaries`.
- **R20 reopen note:** This technical closeout predates the R20 UX research/decision gate. Recreate
  `Phase B1a - UX Decisions.md` with the new method, apply any UX-driven changes, rerun B1a/A6
  regressions, and record a new closeout commit before B1a can be treated as complete again.

#### Second-Pass Execution Record - 2026-06-09

- **R20 UX decisions:** Completed `Phase B1a - UX Decisions.md` with current reference sources,
  extracted patterns, local-demo decisions, implementation decisions, workflow walkthrough, and
  tradeoffs.
- **UX-driven implementation:** `Add Community` now opens a local package loader with extension/init
  package path fields. The Demo App validates package suffixes before import, shows invalid-file
  errors, imports through the fake backend, renders the branded community card, and reports duplicate
  imports as updates.
- **Validation ownership:** Added reusable local package-pair validation to the Local In-App Backend.
- **Tests:** Added `vt_demo-app_local-loader-opens`,
  `vt_demo-app_local-loader-invalid-extension-error`,
  `vt_demo-app_local-loader-validates-package-pair`,
  `vt_demo-app_duplicate-local-import-status`, and
  `vt_fake-backend_local-package-pair-validation`.
- **Manifest:** Registered the new B1a validation tests and refreshed current component stamps:
  `loom-communities-demo-app` `fe03608c5230`; `local-in-app-backend` `332432d7b39d`.
- **Skill docs:** Updated `Skill/workflows/local-build-download-sideload-install.md` with the local
  package-pair selection and validation process.
- **Passed WSL checks:** `dart format` on changed Dart files; `dart test
  packages/core/loom_demo_local_backend/test/a6_local_backend_test.dart`; `flutter test
  packages/core/loom_app_shell/test/a6_app_shell_components_test.dart`; `flutter test
  apps/loom_communities_demo/test/a6_loom_communities_demo_test.dart
  apps/loom_communities_demo/test/b1a_local_workflow_test.dart
  apps/loom_communities_demo/test/b1b_publish_discover_install_test.dart
  apps/loom_communities_demo/test/b2_book_club_workflow_test.dart
  apps/loom_communities_demo/test/b3_youth_soccer_workflow_test.dart`; `flutter analyze
  apps/loom_communities_demo`; `dart analyze packages/core/loom_demo_local_backend`; `dart run
  packages/tooling/manifest_gate.dart --manifest ../docs/Build\ Plan\ V2/test-manifest.json`; `dart
  run packages/tooling/phase_gate.dart --phase B1a --check-env`; `melos run lint:boundaries`; `git
  diff --check`.
- **Commit:** R20 closeout `471677a`.

### Phase B1b - Publish, Discover, Certify, Install

- **Achieves:** Proves the real-backend publish mode through local stubs/contracts.
- **Deliverables:** Skill `real-backend-publish` workflow, hosted publish payloads, certification and
  registry stubs/fakes, QR/handle discovery contract, latest certified install/open behavior.
- **Completed when:** `wf_build-publish-discover-install` passes against the Demo App with Local Backend
  using local backend stubs/contracts for hosted behavior; B1a local package behavior remains green.
- **Evidence to record:** Workflow output, hosted API stub/contract output, package/certification test
  output, API Review and UX Decisions paths, Skill workflow guide path, commit SHA.

#### Execution Record - 2026-06-09

- **Implemented workflow test:** Added
  `apps/loom_communities_demo/test/b1b_publish_discover_install_test.dart` for
  `wf_build-publish-discover-install`.
- **Validated local hosted-publish stubs:** The workflow registers a builder App ID, verifies signing
  scope, certifies the package, publishes a certified extension version, resolves the community by
  handle and QR, imports the initialization package into the Local Backend, renders the card, and opens
  `local:ext_book_club@latest`.
- **Skill and examples:** Added `Skill/workflows/build-publish-discover-install.md` and the book-club
  `phase-b1b-publish` example package/init artifacts.
- **Manifest stamps:** ai-skill-extension-builder `29acc7de90fa`; workflow-validation-harness
  `44632537bded`; `wf_build-publish-discover-install` test hash `617a61fa0308`.
- **Passed WSL checks:** `dart format` on the B1b workflow test; `melos bootstrap`; `flutter test
  apps/loom_communities_demo/test/b1a_local_workflow_test.dart
  apps/loom_communities_demo/test/b1b_publish_discover_install_test.dart
  apps/loom_communities_demo/test/a6_loom_communities_demo_test.dart`; `flutter analyze
  apps/loom_communities_demo`.
- **R20 reopen note:** This technical closeout predates the R20 UX research/decision gate. Recreate
  `Phase B1b - UX Decisions.md` with the new method, apply any UX-driven changes, rerun B1b/B1a/A6
  regressions, and record a new closeout commit before B1b can be treated as complete again.

#### Second-Pass Execution Record - 2026-06-09

- **R20 UX decisions:** Completed `Phase B1b - UX Decisions.md` with current publish/review,
  certification, permission, QR/handle discovery, install preview, and latest-open references.
- **Implementation outcome:** No code change was required in B1b. The existing workflow already
  validates builder signing, certification, registry publication, handle/QR discovery, local import,
  and latest-open against local fakes and the Demo App with Local Backend.
- **Passed WSL checks:** `flutter test apps/loom_communities_demo/test/b1b_publish_discover_install_test.dart
  apps/loom_communities_demo/test/b1a_local_workflow_test.dart
  apps/loom_communities_demo/test/a6_loom_communities_demo_test.dart`; `dart run
  packages/tooling/manifest_gate.dart --manifest ../docs/Build\ Plan\ V2/test-manifest.json`; `dart
  run packages/tooling/phase_gate.dart --phase B1b --check-env`; `melos run lint:boundaries`; `git
  diff --check`.
- **Commit:** R20 closeout `105cb16`.

### Phase B2 - Book Club Headline Flow

- **Achieves:** Validates the first complete vertical extension.
- **Deliverables:** Book club package fragments, nomination schema, voting workflow, meeting event,
  discussion thread, permitted search/digest behavior, Skill workflow guide and example updates.
- **Completed when:** `wf_book-club-headline` passes in the Demo App with Local Backend and all altered
  component validation/regression tests pass.
- **Evidence to record:** Workflow output, package fixture hashes, component regression output, API Review
  and UX Decisions paths, Skill example paths, commit SHA.

#### Execution Record - 2026-06-09

- **Implemented workflow test:** Added `apps/loom_communities_demo/test/workflow_test_harness.dart` and
  `apps/loom_communities_demo/test/b2_book_club_workflow_test.dart`.
- **Validated end state:** The book club workflow installs a local community, submits a nomination,
  records a vote, creates and RSVPs to the meeting, publishes the winning selection, sends a discussion
  message, indexes the selection, generates a cited digest, and opens `local:ext_book_club@latest`.
- **Skill and examples:** Added `Skill/workflows/book-club-headline.md` and
  `Skill/examples/book-club/phase-b2-headline/`.
- **Manifest stamps:** ai-skill-extension-builder `1a5665e8b68d`; workflow-validation-harness
  `a5d952a0a466`; `wf_book-club-headline` test hash `ce5f487585dc`.
- **R20 reopen note:** This technical closeout predates the R20 UX research/decision gate. Recreate
  `Phase B2 - UX Decisions.md` with the new method, apply any UX-driven changes, rerun B2 and prior
  Set B regressions, and record a new closeout commit before B2 can be treated as complete again.

#### Second-Pass Execution Record - 2026-06-09

- **R20 UX decisions:** Completed `Phase B2 - UX Decisions.md` with current book club, poll, event,
  RSVP, discussion, thread, and digest references.
- **Implementation outcome:** No code change was required in B2. The existing workflow already
  validates nomination, vote, selected-book publishing, event/RSVP, discussion message, indexing,
  AI answer, cited digest, card render, and local latest-open behavior.
- **Passed WSL checks:** `flutter test apps/loom_communities_demo/test/b2_book_club_workflow_test.dart
  apps/loom_communities_demo/test/b1b_publish_discover_install_test.dart
  apps/loom_communities_demo/test/b1a_local_workflow_test.dart
  apps/loom_communities_demo/test/a6_loom_communities_demo_test.dart`; `dart run
  packages/tooling/manifest_gate.dart --manifest ../docs/Build\ Plan\ V2/test-manifest.json`; `dart
  run packages/tooling/phase_gate.dart --phase B2 --check-env`; `melos run lint:boundaries`; `git
  diff --check`.
- **Commit:** R20 closeout `e97ba72`.

### Phase B3 - Youth Soccer Headline Flow

- **Achieves:** Validates guardian/minor, schedule, payment, roster, and notification behavior.
- **Deliverables:** Youth soccer package, protected minor-data flow, registration payment, roster views,
  schedule/events, notifications, Skill workflow guide and example updates.
- **Completed when:** `wf_youth-soccer-headline` passes in the Demo App with Local Backend and protected
  data, permission, and payment regressions pass.
- **Evidence to record:** Workflow output, protected-data assertions, payment test output, API Review and
  UX Decisions paths, Skill example paths, commit SHA.

#### Execution Record - 2026-06-09

- **Implemented workflow test:** Added
  `apps/loom_communities_demo/test/b3_youth_soccer_workflow_test.dart`.
- **Validated end state:** The workflow approves guardian membership, creates a team space, writes and
  reads protected minor data with redaction, records registration payment, creates a practice event,
  delivers a deduped reminder, and opens `local:ext_youth_soccer@latest`.
- **Skill and examples:** Added `Skill/workflows/youth-soccer-headline.md` and
  `Skill/examples/youth-soccer/phase-b3-headline/`.
- **Manifest stamps:** ai-skill-extension-builder `ebb94a52333e`; workflow-validation-harness
  `09c26b466480`; `wf_youth-soccer-headline` test hash `e404d2433f01`.
- **R20 reopen note:** This technical closeout predates the R20 UX research/decision gate. Recreate
  `Phase B3 - UX Decisions.md` with the new method, apply any UX-driven changes, rerun B3 and prior
  Set B regressions, and record a new closeout commit before B3 can be treated as complete again.

#### Second-Pass Execution Record - 2026-06-09

- **R20 UX decisions:** Completed `Phase B3 - UX Decisions.md` with current youth sports
  registration, payments, roster, schedule, communication, and child-privacy references.
- **Implementation outcome:** No code change was required in B3. The existing workflow already
  validates guardian membership approval, team space creation, protected minor-data redaction,
  registration payment, schedule event, notification delivery, and local latest-open behavior.
- **Passed WSL checks:** `flutter test apps/loom_communities_demo/test/b3_youth_soccer_workflow_test.dart
  apps/loom_communities_demo/test/b2_book_club_workflow_test.dart
  apps/loom_communities_demo/test/b1b_publish_discover_install_test.dart
  apps/loom_communities_demo/test/b1a_local_workflow_test.dart
  apps/loom_communities_demo/test/a6_loom_communities_demo_test.dart`; `dart run
  packages/tooling/manifest_gate.dart --manifest ../docs/Build\ Plan\ V2/test-manifest.json`; `dart
  run packages/tooling/phase_gate.dart --phase B3 --check-env`; `melos run lint:boundaries`; `git
  diff --check`.
- **Commit:** R20 closeout `23dd422`.

### Phase B4 - HOA Headline Flow

- **Achieves:** Validates dues, documents, facilities, case workflow, and export behavior.
- **Deliverables:** HOA package, dues payment, document visibility, facility reservation, architectural
  request workflow, export metadata, Skill workflow guide and example updates.
- **Completed when:** `wf_hoa-headline` passes in the Demo App with Local Backend and documents,
  facilities, wallet, case/task, workflow, and export regressions pass.
- **Evidence to record:** Workflow output, export coverage output, component regression output, API Review
  and UX Decisions paths, Skill example paths, commit SHA.

#### Second-Pass Execution Record - 2026-06-09

- **R20 UX decisions:** Completed `Phase B4 - UX Decisions.md` with current HOA portal,
  homeowner payment, document, amenity reservation, architectural request, and case-status
  references.
- **Implementation outcome:** Added the HOA workflow test and example package. The workflow validates
  dues payment, document visibility, facility reservation with payment, architectural review case
  lifecycle, workflow transition, notification delivery, export component coverage, and local
  latest-open behavior in the Demo App with Local Backend.
- **Skill/API artifacts:** Added `Skill/workflows/hoa-headline.md`,
  `Skill/examples/hoa/README.md`, `Skill/examples/hoa/loom.extension.json`,
  `Skill/examples/hoa/loom.initialization.json`, and `Phase B4 - API Review.md`; updated the
  master Skill walkthrough.
- **Manifest stamps:** workflow-validation-harness `09c26b466480`; export-service `9079b5ad7e37`;
  `wf_hoa-headline` test hash `563319be521c`.
- **Passed WSL checks:** `flutter test apps/loom_communities_demo/test/b4_hoa_workflow_test.dart
  apps/loom_communities_demo/test/b3_youth_soccer_workflow_test.dart
  apps/loom_communities_demo/test/b2_book_club_workflow_test.dart
  apps/loom_communities_demo/test/b1b_publish_discover_install_test.dart
  apps/loom_communities_demo/test/b1a_local_workflow_test.dart
  apps/loom_communities_demo/test/a6_loom_communities_demo_test.dart`; fake backend A4a/A4b/A5
  regression tests; `flutter analyze apps/loom_communities_demo`; `dart analyze
  packages/core/loom_fake_backend`; manifest and B4 phase gates; boundary lint; `git diff --check`.
- **Commit:** B4 closeout `f3ffad3`.

### Phase B5 - Mosque Headline Flow

- **Achieves:** Validates donation, event, volunteer, announcement, and protected care-request behavior.
- **Deliverables:** Mosque package, announcements, event RSVP, volunteer signup, donor visibility,
  protected care request, notifications, Skill workflow guide and example updates.
- **Completed when:** `wf_mosque-headline` passes in the Demo App with Local Backend and sensitive data,
  donation, event, form, notification, search/AI, and App Shell regressions pass.
- **Evidence to record:** Workflow output, protected-vault assertions, donation receipt output, API Review
  and UX Decisions paths, Skill example paths, commit SHA.

#### Second-Pass Execution Record - 2026-06-09

- **R20 UX decisions:** Completed `Phase B5 - UX Decisions.md` with current mosque app,
  mosque-management, faith-community giving, event, volunteer, donor privacy, and private
  prayer/care-request references.
- **Implementation outcome:** Added the mosque workflow test and example package. The workflow validates
  public announcement publishing, event RSVP, volunteer signup with protected contact details,
  anonymous donor visibility, donation payment, protected care request, neutral notification,
  public announcement search/AI citation, and local latest-open behavior in the Demo App with Local
  Backend.
- **Skill/API artifacts:** Added `Skill/workflows/mosque-headline.md`,
  `Skill/examples/mosque/loom.extension.json`, `Skill/examples/mosque/loom.initialization.json`,
  updated `Skill/examples/mosque/README.md`, updated the master Skill walkthrough, and completed
  `Phase B5 - API Review.md`.
- **Manifest stamps:** `wf_mosque-headline` test hash `6887a1ff12ff`; workflow-validation-harness
  `09c26b466480`; publishing-service `0e31d279bf88`; wallet-dues-donations `071871e00937`;
  protected-visibility-vault `3795b6a09b20`; search-service `00f0b4124434`; ai-gateway
  `66fa617e8d1b`.
- **Passed WSL checks:** `flutter test apps/loom_communities_demo/test/b5_mosque_workflow_test.dart
  apps/loom_communities_demo/test/b4_hoa_workflow_test.dart
  apps/loom_communities_demo/test/b3_youth_soccer_workflow_test.dart
  apps/loom_communities_demo/test/b2_book_club_workflow_test.dart
  apps/loom_communities_demo/test/b1b_publish_discover_install_test.dart
  apps/loom_communities_demo/test/b1a_local_workflow_test.dart
  apps/loom_communities_demo/test/a6_loom_communities_demo_test.dart`; A1/A3/A4b component
  regression tests; `flutter analyze apps/loom_communities_demo`; manifest and B5 phase gates;
  boundary lint; `git diff --check`.
- **Commit:** B5 closeout `163dad1`.

### Phase B6 - Messaging, In-Stream Ads, and Connections

- **Achieves:** Validates required platform social and ad surfaces.
- **Deliverables:** Messages and Connections navigation, invite/block behavior, stream rendering,
  in-stream ad item behavior, top banner behavior, no-fill behavior, Skill workflow guide update.
- **Completed when:** `wf_messaging-ads-connections` passes in the Demo App with Local Backend; shell
  invariants prove extensions cannot hide Messages, Connections, or required ad surfaces.
- **Evidence to record:** Workflow output, shell invariant lint output, ad decision/no-fill output, API
  Review and UX Decisions paths, Skill workflow guide path, commit SHA.

#### Second-Pass Execution Record - 2026-06-09

- **R20 UX decisions:** Completed `Phase B6 - UX Decisions.md` with current navigation, messaging
  request/block, native ad disclosure, sponsored content, and native ad load/no-fill references.
- **Implementation outcome:** Added the messaging/ads/connections workflow test. The workflow validates
  shell-owned Messages and Connections, required top banner no-fill state, message stream rendering,
  connection invite and blocked-target prevention, in-stream/top-banner ad fills, sensitive-context
  no-fill, Sponsored disclosure, and local latest-open behavior.
- **Skill/API artifacts:** Added `Skill/workflows/messaging-ads-connections.md`, updated the master
  Skill walkthrough, and completed `Phase B6 - API Review.md`.
- **Manifest stamps:** `wf_messaging-ads-connections` test hash `15e89fb50365`; messaging-stream-service
  `709572cac272`; connections-graph `297b5d201b5f`; ad-campaign-service `7d781eea95a9`;
  ad-decision-service `e5a7593ee1ea`; app-shell-runtime `c7c0a602fdad`; stream-renderer
  `07547f0370c6`.
- **Passed WSL checks:** `flutter test
  apps/loom_communities_demo/test/b6_messaging_ads_connections_workflow_test.dart
  apps/loom_communities_demo/test/b5_mosque_workflow_test.dart
  apps/loom_communities_demo/test/b4_hoa_workflow_test.dart
  apps/loom_communities_demo/test/b3_youth_soccer_workflow_test.dart
  apps/loom_communities_demo/test/b2_book_club_workflow_test.dart
  apps/loom_communities_demo/test/b1b_publish_discover_install_test.dart
  apps/loom_communities_demo/test/b1a_local_workflow_test.dart
  apps/loom_communities_demo/test/a6_loom_communities_demo_test.dart`; A1/A3/A4b/A6 component
  regression tests; `flutter analyze apps/loom_communities_demo`; manifest and B6 phase gates;
  boundary lint; `git diff --check`.
- **Commit:** B6 closeout `b8c348d`.

### Phase B7 - Ad-Off

- **Achieves:** Validates ad-off purchase and economic side effects.
- **Deliverables:** Member/community ad-off purchase, entitlement checks, ad decision changes, receipts,
  settlement, utility funding allocation, Skill workflow guide update.
- **Completed when:** `wf_ad-off` passes in the Demo App with Local Backend and wallet, ad decision,
  receipt, settlement, utility funding, payment surface, and ad slot regressions pass.
- **Evidence to record:** Workflow output, payment/receipt output, settlement output, API Review and UX
  Decisions paths, Skill workflow guide path, commit SHA.

#### Second-Pass Execution Record - 2026-06-09

- **R20 UX decisions:** Completed `Phase B7 - UX Decisions.md` with current subscription/ad-off,
  purchase management, entitlement status, receipt, restore/recheck, and ad-removal expectation
  references.
- **Implementation outcome:** Added community-wide ad-off support to the local wallet fake, added
  `vt_wallet_community-ad-off` and `vt_ad-decision_ad-off`, and added the ad-off workflow test. The
  workflow validates shell-owned member/community checkout, pre-entitlement ad fill, member ad-off
  suppression, community ad-off suppression, sensitive-context no-fill, receipt linkage, settlement,
  utility allocation, and local latest-open behavior.
- **Skill/API artifacts:** Added `Skill/workflows/ad-off.md`, updated the master Skill walkthrough,
  and completed `Phase B7 - API Review.md`.
- **Manifest stamps:** wallet-dues-donations `f49eb0bac62d`; A4b economic test hash `842b87d3f51a`;
  `wf_ad-off` test hash `2e3f04bafe9d`.
- **Passed WSL checks:** `flutter test apps/loom_communities_demo/test/b7_ad_off_workflow_test.dart
  apps/loom_communities_demo/test/b6_messaging_ads_connections_workflow_test.dart
  apps/loom_communities_demo/test/b5_mosque_workflow_test.dart
  apps/loom_communities_demo/test/b4_hoa_workflow_test.dart
  apps/loom_communities_demo/test/b3_youth_soccer_workflow_test.dart
  apps/loom_communities_demo/test/b2_book_club_workflow_test.dart
  apps/loom_communities_demo/test/b1b_publish_discover_install_test.dart
  apps/loom_communities_demo/test/b1a_local_workflow_test.dart
  apps/loom_communities_demo/test/a6_loom_communities_demo_test.dart`; A4b/A6 component regression
  tests; `dart analyze packages/core/loom_fake_backend`; `flutter analyze apps/loom_communities_demo`;
  manifest and B7 phase gates; boundary lint; `git diff --check`.
- **Commit:** B7 closeout `b06d3c7`.

### Phase B8 - Export and Migration

- **Achieves:** Validates portability and closes the build-plan readiness gate.
- **Deliverables:** Community export, member export/delete behavior, extension custom-data export,
  protected redaction, provider transfer verify/rollback, full workflow regression, final API spec
  inventory, final Skill/example updates.
- **Completed when:** `wf_export-migration`, `vt_api_specs_complete`, the full Set B workflow suite, and
  all altered component regressions pass; every required API/local contract exists and validates.
- **Evidence to record:** Workflow output, full regression output, API inventory output, export package
  checksums, API Review and UX Decisions paths, Skill/example paths, commit SHA.

#### Second-Pass Execution Record - 2026-06-09

- **R20 UX decisions:** Completed `Phase B8 - UX Decisions.md` with current export, import/export,
  retention, provider migration, verification, and rollback/readiness references.
- **Implementation outcome:** Added provider-transfer rollback to the local API contract and fake,
  added `vt_provider-transfer_rollback`, added the export/migration workflow test, and added the
  `vt_api_specs_complete` validator. The workflow validates import preview/replay, protected-field
  routing, exportable custom schema enumeration, full/redacted export bundles, checksum evidence,
  receipt inclusion, provider transfer verification, provider transfer rollback, and local latest-open
  behavior.
- **Skill/API artifacts:** Added `Skill/workflows/export-migration.md`, updated the master Skill
  walkthrough, added export metadata to the book club, youth soccer, HOA, and mosque examples, and
  completed `Phase B8 - API Review.md`.
- **Manifest stamps:** api-spec-inventory `9d57761d8326`; provider-transfer-service
  `7a931f77c1e1`; A4a ops test hash `28947a0e1dd0`; `wf_export-migration` test hash
  `90ae5bef5a27`.
- **Passed WSL checks:** `flutter test apps/loom_communities_demo/test/b8_export_migration_workflow_test.dart
  apps/loom_communities_demo/test/b7_ad_off_workflow_test.dart
  apps/loom_communities_demo/test/b6_messaging_ads_connections_workflow_test.dart
  apps/loom_communities_demo/test/b5_mosque_workflow_test.dart
  apps/loom_communities_demo/test/b4_hoa_workflow_test.dart
  apps/loom_communities_demo/test/b3_youth_soccer_workflow_test.dart
  apps/loom_communities_demo/test/b2_book_club_workflow_test.dart
  apps/loom_communities_demo/test/b1b_publish_discover_install_test.dart
  apps/loom_communities_demo/test/b1a_local_workflow_test.dart
  apps/loom_communities_demo/test/a6_loom_communities_demo_test.dart`; A4a/A4b/A5/A6 component
  regression tests; API inventory validator; `dart analyze packages/core/loom_api_contracts`;
  `dart analyze packages/core/loom_fake_backend`; `flutter analyze apps/loom_communities_demo`;
  manifest and B8 phase gates; boundary lint; `git diff --check`.
- **Commit:** B8 closeout `762f556`.

### Phase B9 - Arbitrary Local Package Ingestion

- **Achieves:** Validates that local-demo install consumes arbitrary selected package contents instead
  of substituting a fixture.
- **Deliverables:** File-backed package pair parsing in Local In-App Backend, Demo App loader import via
  parsed files, arbitrary widget/backend/workflow tests, B9 API Review, B9 UX Decisions, Skill
  arbitrary-ingestion workflow guide, manifest rows.
- **Completed when:** `vt_fake-backend_parse-arbitrary-local-package-pair`,
  `vt_fake-backend_import-arbitrary-package-pair`, `vt_demo-app_arbitrary-local-extension-loads-card`,
  `wf_arbitrary-local-package-ingestion`, affected A6/B1a/B8 regressions, manifest gate, B9 phase
  gate, analyze, boundary lint, and diff check pass in WSL Ubuntu.
- **Evidence to record:** Focused backend/widget/workflow test output, Set B regression output, API
  Review and UX Decisions paths, Skill workflow guide path, component/test hashes, implementation
  commit SHA, tracker stamp SHA.

#### Execution Record - 2026-06-09

- **Implementation outcome:** Added file-backed local package parsing/import to
  `LocalInAppBackend`, routed the Demo App loader through the parsed package pair, and removed the
  hardcoded Book Club install path from the UI.
- **Tests added/updated:** Added arbitrary backend parsing/import assertions, updated Demo App widget
  tests to enter generated package paths, and added `wf_arbitrary-local-package-ingestion` for an
  arbitrary Chess Club package pair.
- **Skill/API/UX artifacts:** Added `Phase B9 - API Review.md`,
  `Phase B9 - UX Decisions.md`, `Phase B9 - Arbitrary Local Package Ingestion.md`,
  `Skill/workflows/arbitrary-local-package-ingestion.md`, and the master Skill walkthrough update.
- **Manifest stamps:** `local-in-app-backend` `f5a3e98e5595`; `loom-communities-demo-app`
  `42175a068b2a`; backend test hash `69045e9512a0`; widget test hash `d4401d6651a`;
  B9 workflow test hash `c63d67658e18`.
- **Passed WSL checks:** `dart test packages/core/loom_demo_local_backend/test/a6_local_backend_test.dart`;
  `flutter test apps/loom_communities_demo/test/a6_loom_communities_demo_test.dart
  apps/loom_communities_demo/test/b1a_local_workflow_test.dart
  apps/loom_communities_demo/test/b1b_publish_discover_install_test.dart
  apps/loom_communities_demo/test/b2_book_club_workflow_test.dart
  apps/loom_communities_demo/test/b3_youth_soccer_workflow_test.dart
  apps/loom_communities_demo/test/b4_hoa_workflow_test.dart
  apps/loom_communities_demo/test/b5_mosque_workflow_test.dart
  apps/loom_communities_demo/test/b6_messaging_ads_connections_workflow_test.dart
  apps/loom_communities_demo/test/b7_ad_off_workflow_test.dart
  apps/loom_communities_demo/test/b8_export_migration_workflow_test.dart
  apps/loom_communities_demo/test/b9_arbitrary_local_package_ingestion_test.dart`;
  `dart analyze packages/core/loom_demo_local_backend`; `flutter analyze apps/loom_communities_demo`;
  manifest and B9 phase gates; boundary lint; `git diff --check`.
- **Commit:** B9 implementation `db3c476`; tracker stamp `4a91980`.

### Phase B10 - Skill Arbitrary Extension Test Run

- **Achieves:** Validates arbitrary Skill-generated local-demo artifacts by replaying them through the
  Demo App Local Backend.
- **Deliverables:** Arbitrary Garden Club Skill example, B10 workflow replay guide, B10 API Review,
  B10 UX Decisions, Skill walkthrough update, parser alias support for Skill artifact fields,
  `wf_skill-arbitrary-extension-test-run`, manifest rows.
- **Completed when:** `wf_skill-arbitrary-extension-test-run`, B9/B1a/A6 regressions, affected backend
  tests, manifest gate, B10 phase gate, analyze, boundary lint, and diff check pass in WSL Ubuntu.
- **Evidence to record:** B10 workflow output, parser regression output, API Review and UX Decisions
  paths, Skill example paths, component/test hashes, implementation commit SHA, tracker stamp SHA.

#### Execution Record - 2026-06-09

- **Implementation outcome:** Added parser alias support for Skill example fields, added an arbitrary
  Garden Club Skill example, and added `wf_skill-arbitrary-extension-test-run` to replay those docs
  artifacts through the Demo App Local Backend.
- **Skill/API/UX artifacts:** Added `Phase B10 - Skill Arbitrary Extension Test Run.md`,
  `Phase B10 - API Review.md`, `Phase B10 - UX Decisions.md`,
  `Skill/workflows/skill-arbitrary-extension-test-run.md`, and
  `Skill/examples/arbitrary-garden-club/`.
- **Manifest stamps:** `local-in-app-backend` `86c66ae23974`; B10 workflow test hash
  `3831a8aa5a2b`. Archive hardening updates `local-in-app-backend` to `5d1deb013df1` and backend
  test hash to `44939abd80a8`.
- **Passed WSL checks:** `dart test packages/core/loom_demo_local_backend/test/a6_local_backend_test.dart`;
  `flutter test apps/loom_communities_demo/test/a6_loom_communities_demo_test.dart
  apps/loom_communities_demo/test/b1a_local_workflow_test.dart
  apps/loom_communities_demo/test/b9_arbitrary_local_package_ingestion_test.dart
  apps/loom_communities_demo/test/b10_skill_arbitrary_extension_test.dart`;
  `flutter test apps/loom_communities_demo/test/b1a_local_workflow_test.dart
  apps/loom_communities_demo/test/b1b_publish_discover_install_test.dart
  apps/loom_communities_demo/test/b2_book_club_workflow_test.dart
  apps/loom_communities_demo/test/b3_youth_soccer_workflow_test.dart
  apps/loom_communities_demo/test/b4_hoa_workflow_test.dart
  apps/loom_communities_demo/test/b5_mosque_workflow_test.dart
  apps/loom_communities_demo/test/b6_messaging_ads_connections_workflow_test.dart
  apps/loom_communities_demo/test/b7_ad_off_workflow_test.dart
  apps/loom_communities_demo/test/b8_export_migration_workflow_test.dart
  apps/loom_communities_demo/test/b9_arbitrary_local_package_ingestion_test.dart
  apps/loom_communities_demo/test/b10_skill_arbitrary_extension_test.dart`;
  `dart analyze packages/core/loom_demo_local_backend`; `flutter analyze apps/loom_communities_demo`;
  manifest and B10 phase gates; boundary lint; `git diff --check`.
- **Commit:** B10 implementation `6bee137`; tracker stamp `d5f0956`.

### Phase B11 - Skill Prompt Build Validate Complete

- **Achieves:** Validates the complete Skill execution loop from an arbitrary owner prompt through
  workflow capture, docs generation, extension/init package generation, Demo App local install/open,
  workflow validation, and completion reporting.
- **Deliverables:** `loom_skill_debug_harness` prompt build/validation API, B11 Camera Club prompt
  fixture, B11 workflow validation test, B11 phase/API/UX docs,
  `Skill/workflows/prompt-build-validate-complete.md`,
  `Skill/examples/arbitrary-camera-club/`, Skill completion-rule updates, and manifest rows.
- **Completed when:** `wf_skill-prompt-build-validate-complete`, B9/B10 regressions, manifest gate,
  B11 phase gate, analyze, boundary lint, and diff check pass in WSL Ubuntu.
- **Evidence to record:** Generated validation report output, generated package/docs paths, API Review
  and UX Decisions paths, Skill example paths, component/test hashes, implementation commit SHA,
  tracker stamp SHA.

#### Execution Record - 2026-06-10

- **Implementation outcome:** Added a deterministic Skill Debug Harness that accepts an arbitrary owner
  prompt, extracts community identity and requested workflows, creates review docs, emits
  `.loom-extension.zip` and `.loom-init.zip` artifacts, installs them through the Demo App Local
  Backend, opens the generated extension through App Shell Runtime, validates each captured workflow,
  and writes `validation-report.json` plus `validation-report.md`.
- **Skill/API/UX artifacts:** Added `Phase B11 - Skill Prompt Build Validate Complete.md`,
  `Phase B11 - API Review.md`, `Phase B11 - UX Decisions.md`,
  `Skill/workflows/prompt-build-validate-complete.md`, and
  `Skill/examples/arbitrary-camera-club/`.
- **Manifest stamps:** `ai-skill-extension-builder` `518c78e30a44`; `skill-debug-harness`
  `4e3ce721c363`; B11 workflow test hash `14cca9c94402`.
- **Passed WSL checks:** `flutter test
  apps/loom_communities_demo/test/b11_skill_prompt_build_validate_test.dart`; `flutter test
  apps/loom_communities_demo/test/b9_arbitrary_local_package_ingestion_test.dart
  apps/loom_communities_demo/test/b10_skill_arbitrary_extension_test.dart
  apps/loom_communities_demo/test/b11_skill_prompt_build_validate_test.dart`; `dart analyze
  packages/tooling/loom_skill_debug_harness`; `flutter analyze apps/loom_communities_demo`;
  manifest and B11 phase gates; boundary lint; `git diff --check`; full Demo App workflow sweep
  `flutter test apps/loom_communities_demo/test/b1a_local_workflow_test.dart
  apps/loom_communities_demo/test/b1b_publish_discover_install_test.dart
  apps/loom_communities_demo/test/b2_book_club_workflow_test.dart
  apps/loom_communities_demo/test/b3_youth_soccer_workflow_test.dart
  apps/loom_communities_demo/test/b4_hoa_workflow_test.dart
  apps/loom_communities_demo/test/b5_mosque_workflow_test.dart
  apps/loom_communities_demo/test/b6_messaging_ads_connections_workflow_test.dart
  apps/loom_communities_demo/test/b7_ad_off_workflow_test.dart
  apps/loom_communities_demo/test/b8_export_migration_workflow_test.dart
  apps/loom_communities_demo/test/b9_arbitrary_local_package_ingestion_test.dart
  apps/loom_communities_demo/test/b10_skill_arbitrary_extension_test.dart
  apps/loom_communities_demo/test/b11_skill_prompt_build_validate_test.dart`.
- **Commit:** B11 implementation `21c89db`; tracker stamp `7ddb30d`.

### Phase B12 - Example Workflow UX Evidence Harness

- **Achieves:** Creates the standard and tooling required to prove user-facing workflow completion with
  Android emulator screenshots.
- **Deliverables:** Full UX workflow evidence matrix, `workflow-ui-evidence.json` schema, screenshot
  naming/folder conventions, emulator capture harness, failure artifact capture, screenshot evidence
  audit, manifest rows, `Phase B12 - API Review.md`, and `Phase B12 - UX Decisions.md`.
- **Completed when:** The matrix covers every example/test target listed above; the capture harness can
  install or seed a local package, open the card, capture PNG screenshots for start, critical action,
  and completion states, write a machine-readable evidence manifest, and fail when any screenshot file
  or required assertion is missing.
- **Evidence to record:** Harness command output, emulator/device name and API level, sample passing
  screenshot bundle under `docs/Build Plan V2/Evidence/B12/`, sample failure artifact, evidence
  manifest schema path, manifest/test stamps, phase gate, analyze, boundary lint, diff check, and commit
  SHA.

#### Execution Record - 2026-06-27

- **Implementation outcome:** Added the shared workflow UI evidence harness, Android integration driver,
  screenshot writer, evidence manifest/audit generation, and a visible workflow checklist in the Demo
  App for every evidence target.
- **Evidence captured:** `docs/Build Plan V2/Evidence/B12/workflow-ui-evidence.json` records 1 harness
  workflow with 3 Android emulator screenshots under `docs/Build Plan V2/Evidence/B12/screenshots/`.
- **Skill/API/UX artifacts:** Added `Phase B12 - Example Workflow UX Evidence Harness.md`,
  `Phase B12 - API Review.md`, `Phase B12 - UX Decisions.md`, and updated the Skill rule that workflow
  completion requires full visible UI evidence.
- **Manifest stamps:** `loom-communities-demo-app` `cf7f1769af4a`; B12 workflow test hash
  `de0b06e7a2a5`; full screenshot evidence test hash `f8b3bf556309`.
- **Passed WSL checks:** `flutter test` full Demo App workflow sweep from A6/B1a through B16 passed
  with 34 tests; `bash apps/loom_communities_demo/tool/run_workflow_ui_evidence.sh`; `flutter analyze
  apps/loom_communities_demo`; `dart analyze packages/tooling/loom_lints`; manifest gate; B12 phase
  gate; boundary lint; `git -c core.whitespace=blank-at-eof,space-before-tab,cr-at-eol diff --check`.
- **Commit:** Consolidated in `4ae3b4a`.

### Phase B13 - Garden Club Full UX Workflow Evidence

- **Achieves:** Closes the current Garden Club gap by replacing metadata-only open behavior with a real
  Garden Club extension experience that completes visible workflows.
- **Deliverables:** Garden Club home route, local package/install/open UI flow, Garden Club event RSVP,
  plant exchange/form submission, Garden Club export/custom-schema evidence, screenshot bundle,
  `workflow-ui-evidence.json`, updated Garden Club example docs, updated Skill workflow guidance,
  `Phase B13 - API Review.md`, and `Phase B13 - UX Decisions.md`.
- **Completed when:** Tapping the Garden Club card opens the Garden Club experience instead of the
  generic settings/metadata screen; required App Shell surfaces remain visible; every declared Garden
  Club workflow is completed through UI interactions on the Android emulator; completion screenshots
  show the resulting RSVP, plant exchange/form record, and export/custom-schema evidence.
- **Evidence to record:** Garden Club install/open screenshots, Garden Club home screenshot, event RSVP
  start/action/completion screenshots, plant exchange/form start/action/completion screenshots, export
  evidence screenshot, evidence manifest, Flutter/emulator test output, manifest/test stamps, phase
  gate, analyze, boundary lint, diff check, and commit SHA.

#### Execution Record - 2026-06-27

- **Implementation outcome:** Garden Club now opens a domain workflow experience instead of only the
  extension metadata/settings view, while preserving the App Shell banner, Messages, Connections,
  payment surface, and seed-file evidence.
- **Evidence captured:** `docs/Build Plan V2/Evidence/B13/workflow-ui-evidence.json` records
  `garden-event-rsvp`, `plant-exchange-submission`, and `garden-export-custom-schemas` with 9 Android
  emulator screenshots.
- **Skill/API/UX artifacts:** Added `Phase B13 - Garden Club Full UX Workflow Evidence.md`,
  `Phase B13 - API Review.md`, and `Phase B13 - UX Decisions.md`.
- **Manifest stamps:** `loom-communities-demo-app` `cf7f1769af4a`; B13 workflow test hash
  `ad5240a0ffce`; full screenshot evidence test hash `f8b3bf556309`.
- **Passed WSL checks:** `flutter test` full Demo App workflow sweep from A6/B1a through B16 passed
  with 34 tests; `bash apps/loom_communities_demo/tool/run_workflow_ui_evidence.sh`; manifest gate;
  B13 phase gate; analyze; boundary lint; diff check.
- **Commit:** Consolidated in `4ae3b4a`.

### Phase B14 - Anchor Example Full UX Workflow Evidence

- **Achieves:** Proves the anchor vertical examples through visible UI, not only direct fake-backend API
  calls.
- **Deliverables:** Book Club, Youth Soccer, HOA, and Mosque UI workflow tests; screenshot bundles for
  every workflow in the matrix; one evidence manifest per app; backend parity assertions that the UI
  results match the existing service-level workflow expectations; updated example READMEs and Skill
  workflow docs; `Phase B14 - API Review.md`; and `Phase B14 - UX Decisions.md`.
- **Completed when:** Book Club nomination/vote/event/discussion/digest, Youth Soccer guardian/team/
  protected-data/payment/schedule/notification, HOA dues/documents/facility/architectural/export, and
  Mosque announcement/event/volunteer/donation/care/search workflows all complete through visible UI on
  the Android emulator and have start/action/completion screenshots.
- **Evidence to record:** Screenshot bundles under `docs/Build Plan V2/Evidence/B14/`, evidence
  manifests for Book Club, Youth Soccer, HOA, and Mosque, Flutter/emulator test output, backend parity
  output, full B1a-B14 regression output, manifest/test stamps, phase gate, analyze, boundary lint,
  diff check, and commit SHA.

#### Execution Record - 2026-06-27

- **Implementation outcome:** Added visible UI workflow evidence targets for Book Club, Youth Soccer,
  HOA, and Mosque so the anchor examples are validated through Demo App interactions instead of only
  backend/service calls.
- **Evidence captured:** `docs/Build Plan V2/Evidence/B14/workflow-ui-evidence.json` records 29
  workflows with 87 Android screenshots: Book Club 7, Youth Soccer 7, HOA 7, and Mosque 8.
- **Skill/API/UX artifacts:** Added `Phase B14 - Anchor Example Full UX Workflow Evidence.md`,
  `Phase B14 - API Review.md`, and `Phase B14 - UX Decisions.md`.
- **Manifest stamps:** `loom-communities-demo-app` `cf7f1769af4a`; B14 workflow test hash
  `36302c13f8cc`; full screenshot evidence test hash `f8b3bf556309`.
- **Passed WSL checks:** `flutter test` full Demo App workflow sweep from A6/B1a through B16 passed
  with 34 tests; `bash apps/loom_communities_demo/tool/run_workflow_ui_evidence.sh`; manifest gate;
  B14 phase gate; analyze; boundary lint; diff check.
- **Commit:** Consolidated in `4ae3b4a`.

### Phase B15 - Arbitrary and Prompt Example Full UX Workflow Evidence

- **Achieves:** Proves arbitrary and prompt-generated examples as visible extension experiences, not
  only package parsing, card rendering, local route opening, or manifest-based completion.
- **Deliverables:** Chess Club arbitrary-ingestion UI evidence, Camera Club prompt-generated UI
  workflows, photo-walk RSVP UI, critique submission UI, gear-loan request UI, screenshot bundles,
  completion report links to screenshot evidence, updated prompt-build validation report schema,
  updated example docs, `Phase B15 - API Review.md`, and `Phase B15 - UX Decisions.md`.
- **Completed when:** The Chess Club arbitrary package completes its declared install/open and
  route-defined UI behavior with screenshots, and the Camera Club generated package completes
  photo-walk RSVP, critique submission, and gear-loan request through visible UI with a completion
  report that links every workflow result to screenshot evidence.
- **Evidence to record:** Chess and Camera screenshot bundles under `docs/Build Plan V2/Evidence/B15/`,
  evidence manifests, generated validation report, Flutter/emulator test output, B9-B15 regression
  output, manifest/test stamps, phase gate, analyze, boundary lint, diff check, and commit SHA.

#### Execution Record - 2026-06-27

- **Implementation outcome:** Added visible UI workflow evidence for the arbitrary Chess Club package
  and prompt-generated Camera Club package, covering install/open behavior plus the declared domain
  actions.
- **Evidence captured:** `docs/Build Plan V2/Evidence/B15/workflow-ui-evidence.json` records 6
  workflows with 18 Android screenshots: Chess Club 3 and Camera Club 3.
- **Skill/API/UX artifacts:** Added `Phase B15 - Arbitrary and Prompt Example Full UX Workflow Evidence.md`,
  `Phase B15 - API Review.md`, and `Phase B15 - UX Decisions.md`.
- **Manifest stamps:** `loom-communities-demo-app` `cf7f1769af4a`; B15 workflow test hash
  `896bf2a7068b`; full screenshot evidence test hash `f8b3bf556309`.
- **Passed WSL checks:** `flutter test` full Demo App workflow sweep from A6/B1a through B16 passed
  with 34 tests; `bash apps/loom_communities_demo/tool/run_workflow_ui_evidence.sh`; manifest gate;
  B15 phase gate; analyze; boundary lint; diff check.
- **Commit:** Consolidated in `4ae3b4a`.

### Phase B16 - Platform Workflow UX Evidence Sweep

- **Achieves:** Proves platform-required workflows through visible UI and closes the full example/test
  app workflow evidence sweep.
- **Deliverables:** Platform Social UI evidence for Messages, Connections, stream, ads, and no-fill;
  Ad-Off UI evidence for checkout, entitlement, suppression, receipts, settlement, and utility
  allocation; Export/Migration UI evidence for import preview/replay, protected redaction, full and
  redacted exports, checksums, transfer verification, and rollback; final B12-B16 evidence manifest;
  `Phase B16 - API Review.md`; and `Phase B16 - UX Decisions.md`.
- **Completed when:** Platform Social, Ad-Off, and Export/Migration workflows complete through visible
  Android emulator UI; every required workflow has start/action/completion screenshots; the final
  evidence manifest confirms no missing screenshot paths; and the full B1a-B16 workflow suite passes.
- **Evidence to record:** Platform screenshot bundles under `docs/Build Plan V2/Evidence/B16/`, final
  B12-B16 evidence manifest, Flutter/emulator output, full workflow sweep output, manifest/test stamps,
  phase gate, analyze, boundary lint, diff check, and commit SHA.

#### Execution Record - 2026-06-27

- **Implementation outcome:** Added visible platform evidence targets for Platform Social, Ad-Off, and
  Export/Migration, and generated the final cross-phase evidence manifest for B12-B16.
- **Evidence captured:** `docs/Build Plan V2/Evidence/B16/workflow-ui-evidence.json` records 23
  workflows with 69 Android screenshots: Platform Social 8, Ad-Off 6, and Export/Migration 9. The final
  `docs/Build Plan V2/Evidence/B16/all-workflow-ui-evidence.json` reports `status=pass`, 62 workflows,
  and 186 screenshots across B12-B16.
- **Skill/API/UX artifacts:** Added `Phase B16 - Platform Workflow UX Evidence Sweep.md`,
  `Phase B16 - API Review.md`, and `Phase B16 - UX Decisions.md`.
- **Manifest stamps:** `loom-communities-demo-app` `cf7f1769af4a`; B16 workflow test hash
  `c3e4f0a7a438`; full screenshot evidence test hash `f8b3bf556309`.
- **Passed WSL checks:** `flutter test` full Demo App workflow sweep from A6/B1a through B16 passed
  with 34 tests; `bash apps/loom_communities_demo/tool/run_workflow_ui_evidence.sh`; manifest gate;
  B16 phase gate; `flutter analyze apps/loom_communities_demo`; `dart analyze
  packages/tooling/loom_lints`; boundary lint; diff check.
- **Commit:** Consolidated in `4ae3b4a`.

### Phase B17 - Persona Role Inventory and Capability Matrix

- **Achieves:** Converts each example community's implicit actors into explicit test personas, role
  grants, workflow actor/receiver mappings, and UX gating policy before code changes.
- **Deliverables:** Persona inventory for every example/test app, workflow-to-role capability matrix,
  workflow dependency graph, unauthorized-action matrix, per-persona workflow test matrix,
  multi-persona workflow list, persona evidence schema updates, B17 API Review, and B17 UX Decisions.
- **Completed when:** Every workflow lists which persona can initiate it, which persona receives or
  continues it, which permissions or role grants are required, whether non-authorized personas see it as
  hidden/disabled/read-only, which prerequisite workflow state is required, and which screenshot
  evidence IDs will prove every persona/workflow row.
- **Evidence to record:** Matrix path, dependency graph path, role/permission source review, Masjid Nur
  announcement admin-create/member-receive mapping, all other community role mappings, manifest/test
  stamps, B17 phase gate, analyze, boundary lint, diff check, and commit SHA.

#### Execution Record - 2026-06-27

- **Implementation outcome:** Added explicit personas for every example/test community and centralized
  workflow policies that classify each persona/workflow row as actor, receiver, read-only, or disabled.
  Masjid Nur public announcement is admin-created and member-received, not member-created.
- **Evidence captured:** `docs/Build Plan V2/Evidence/B17/workflow-ui-evidence.json` records the
  persona inventory evidence with 2 Android screenshots; the widget audit covers the full persona
  matrix across all 10 evidence targets.
- **Manifest stamps:** `loom-communities-demo-app` `ec9b8abeb4f1`; B17 test hash
  `32eae6f13b58`; full screenshot evidence test hash `b22ab1592317`.
- **Passed WSL checks:** `flutter test` full Demo App workflow sweep passed with 39 tests; `bash
  apps/loom_communities_demo/tool/run_workflow_ui_evidence.sh`; `flutter analyze
  apps/loom_communities_demo`; manifest gate; B17 phase gate; boundary lint; diff check.
- **Commit:** Consolidated in `4ae3b4a`.

### Phase B18 - Demo App Persona Picker

- **Achieves:** Adds a test-only persona picker behind the App Shell people icon so testers can switch
  simulated actor/role while reviewing a community.
- **Deliverables:** People-icon picker interaction, active persona model, community-scoped persona list,
  selected persona banner/chip, persona context passed into workflow rendering and backend test harnesses,
  widget tests, screenshot evidence, B18 API Review, and B18 UX Decisions.
- **Completed when:** Tapping the people icon opens a picker for the current community's declared
  personas, selecting a persona updates the visible actor state without restarting the app, and the app
  clearly marks the picker as a local testing harness rather than production identity.
- **Evidence to record:** Picker screenshots for at least Masjid Nur and one non-anchor example, widget
  test output, active persona state assertions, manifest/test stamps, B18 phase gate, analyze, boundary
  lint, diff check, and commit SHA.

#### Execution Record - 2026-06-27

- **Implementation outcome:** The people icon now opens a test-only persona picker, selecting a persona
  updates the active persona state in-place, and the picker states that production identity comes from
  the logged-in user.
- **Evidence captured:** `docs/Build Plan V2/Evidence/B18/workflow-ui-evidence.json` records 1 workflow
  with 2 Android screenshots showing the picker and Masjid Nur member selection.
- **Manifest stamps:** `loom-communities-demo-app` `ec9b8abeb4f1`; B18 test hash
  `b9d6f42b6184`; full screenshot evidence test hash `b22ab1592317`.
- **Passed WSL checks:** `flutter test` full Demo App workflow sweep passed with 39 tests; Android
  evidence sweep; analyze; manifest gate; B18 phase gate; boundary lint; diff check.
- **Commit:** Consolidated in `4ae3b4a`.

### Phase B19 - Community Persona-Aware UX

- **Achieves:** Applies the selected persona to every community experience so capabilities and workflow
  surfaces match the persona's role.
- **Deliverables:** Role-aware workflow rendering for every example/test app, disabled-state reason copy,
  receiving/read-only workflow surfaces, permission parity checks against fake backend role policy,
  updated example docs, screenshot evidence, B19 API Review, and B19 UX Decisions.
- **Completed when:** Admin-only actions such as Masjid Nur public announcement publishing are not
  generally executable by member personas; member personas instead see receiving/search/read workflows;
  each community has screenshots proving at least one authorized and one unauthorized persona state.
- **Evidence to record:** Role-aware screenshots for all examples, backend denial/assertion output for
  unauthorized mutation attempts, example docs, manifest/test stamps, B19 phase gate, analyze, boundary
  lint, diff check, and commit SHA.

#### Execution Record - 2026-06-27

- **Implementation outcome:** Workflow cards now render actor, receiver, waiting, read-only, and
  disabled states from the selected persona. Existing complete buttons remain available only to actor
  personas, preserving earlier workflow tests through explicit actor selection.
- **Evidence captured:** `docs/Build Plan V2/Evidence/B19/workflow-ui-evidence.json` records 1 workflow
  with 3 Android screenshots showing member-owned care request, member-blocked public announcement,
  and admin-enabled public announcement.
- **Manifest stamps:** `loom-communities-demo-app` `ec9b8abeb4f1`; B19 test hash
  `e76addf3dbfd`; full screenshot evidence test hash `b22ab1592317`.
- **Passed WSL checks:** `flutter test` full Demo App workflow sweep passed with 39 tests; Android
  evidence sweep; analyze; manifest gate; B19 phase gate; boundary lint; diff check.
- **Commit:** Consolidated in `4ae3b4a`.

### Phase B20 - Multi-Persona Workflow Evidence Sweep

- **Achieves:** Proves cross-persona workflows where one persona creates, approves, or sends something
  and another persona receives, reads, pays, reviews, or continues the workflow.
- **Deliverables:** Android emulator workflow tests that switch personas mid-flow, per-persona workflow
  matrix audit, prerequisite producer/receiver scenario tests, screenshot manifests with persona IDs,
  backend state assertions for cross-persona continuity, final B17-B20 evidence manifest, full B1a-B20
  regression sweep, B20 API Review, and B20 UX Decisions.
- **Completed when:** Every persona/workflow matrix row for every example community is either proven
  through visible UI evidence or marked not applicable with rationale. Masjid Nur can publish a public
  announcement as an admin persona and then switch to a member persona that receives/searches the
  announcement; equivalent prerequisite-driven cross-role flows pass for the other anchor and platform
  examples; all screenshot manifests include persona context and no workflow is marked complete using a
  single all-powerful test actor.
- **Evidence to record:** Multi-persona screenshot bundles under `docs/Build Plan V2/Evidence/B20/`,
  final B17-B20 evidence manifest, per-persona workflow matrix audit, Flutter/emulator output, full
  workflow sweep output, manifest/test stamps, phase gate, analyze, boundary lint, diff check, and commit
  SHA.

#### Execution Record - 2026-06-27

- **Implementation outcome:** Added a full sweep that installs every example/test community, completes
  every workflow with the declared actor persona, switches to every receiver persona, and asserts
  read-only/disabled states for all remaining personas.
- **Evidence captured:** `docs/Build Plan V2/Evidence/B20/workflow-ui-evidence.json` records the Masjid
  Nur admin-create/member-receive announcement flow with 6 Android screenshots. The final
  `docs/Build Plan V2/Evidence/B20/all-workflow-ui-evidence.json` reports `status=pass`, 66 workflows,
  and 198 screenshots across B12-B20.
- **Manifest stamps:** `loom-communities-demo-app` `ec9b8abeb4f1`; B20 test hash
  `40d23e274712`; full screenshot evidence test hash `b22ab1592317`.
- **Passed WSL checks:** `flutter test` full Demo App workflow sweep passed with 39 tests; `bash
  apps/loom_communities_demo/tool/run_workflow_ui_evidence.sh`; `flutter analyze
  apps/loom_communities_demo`; manifest gate; B20 phase gate; `dart analyze
  packages/tooling/loom_lints`; boundary lint; diff check.
- **Commit:** Consolidated in `4ae3b4a`.

### Phase B21 - Production Workflow UX Contract Matrix

- **Achieves:** Turns every example workflow/persona row into a production UX contract before app code
  changes. The contract must state the real user goal, workflow type, actor/receiver personas,
  prerequisite state, required inputs, validation, semantic actions, success/receipt state, and
  evidence IDs.
- **Deliverables:** Production UX contract matrix for every example/test app, workflow-type pattern
  assignment, generic-copy audit, persona-specific screen map, screenshot plan, B21 API Review, B21 UX
  Decisions, and prompt transcript used for the phase.
- **Completed when:** Every workflow/persona row has a reviewed production UX contract and no row is
  allowed to proceed with a generic workflow card, metadata-only page, `Complete workflow` dialog, or
  test-harness copy as its intended user experience.
- **Evidence to record:** Matrix path, generic-copy audit, prompt transcript, owner review notes,
  manifest/test stamps, B21 phase gate, boundary lint, diff check, and commit SHA.
- **Execution record:** Added the production workflow UX contract helper and matrix covering all example
  workflow/persona rows, plus the generic-copy rejection audit.
- **Evidence:** `docs/Build Plan V2/Evidence/B21/production-workflow-ux-contract-matrix.md`;
  `wf_production-workflow-ux-contract-matrix` passed with test hash `02bd693d382e`; demo app hash
  `20ba48fdc81a`.
- **Gate evidence:** `flutter test apps/loom_communities_demo/test/b21_b25_production_ux_test.dart`;
  `flutter test apps/loom_communities_demo/test`; Android workflow UI evidence sweep; manifest gate; B21
  phase gate.
- **Commit:** Consolidated in `4ae3b4a`.

### Phase B22 - Domain-Specific Workflow Surfaces

- **Achieves:** Replaces generic workflow harness UI with production surfaces that fit each workflow's
  domain: events/RSVP, payment, protected forms, announcements, approvals, search/AI, exports,
  migration, messages, connections, and ads.
- **Deliverables:** Domain-specific workflow screens/components, semantic labels, real input fields,
  validation/error states, loading/empty states, review/preview steps where needed, success/receipt
  surfaces, backend parity tests, B22 API Review, and B22 UX Decisions.
- **Completed when:** Every example/test workflow can be completed through a production-like surface
  with user-meaningful labels and state transitions. Tests fail when generic labels such as `Complete`
  or `Complete workflow` appear on production workflow screens.
- **Evidence to record:** Before/after screenshots for each workflow category, widget/integration test
  output, backend assertions, manifest/test stamps, B22 phase gate, analyze, boundary lint, diff check,
  and commit SHA.
- **Execution record:** Replaced the generic workflow checklist/card/dialog surface with production
  workflow rows, domain category and surface chips, semantic actor/receiver labels, structured review
  dialogs, and domain result states.
- **Evidence:** `docs/Build Plan V2/Phases/Phase B22 - UX Decisions.md`; `wf_domain-specific-workflow-surfaces`
  passed with test hash `02bd693d382e`; demo app hash `20ba48fdc81a`.
- **Gate evidence:** Focused B21-B25 production UX test passed; full demo widget suite passed 44 tests;
  Android workflow UI evidence sweep passed.
- **Commit:** Consolidated in `4ae3b4a`.

### Phase B23 - Persona Production UX and Cross-Persona State

- **Achieves:** Applies the production workflow surfaces per persona so actor, receiver, read-only,
  disabled, hidden, and unrelated personas each see a coherent product experience.
- **Deliverables:** Persona-specific production screens, receiving surfaces, disabled reason copy,
  unauthorized mutation denial tests, dependency-chain UI tests, cross-persona state assertions, B23
  API Review, and B23 UX Decisions.
- **Completed when:** Multi-persona workflows prove the producer persona creates or approves state,
  the receiving persona sees that state in a real recipient surface, and unrelated personas cannot act
  outside their role. The Masjid Nur announcement flow must prove admin publish and member receive as a
  representative dependency chain, with equivalent coverage for the other examples.
- **Evidence to record:** Actor screenshots, persona-switch screenshots, receiver screenshots,
  unauthorized persona screenshots, backend parity output, manifest/test stamps, B23 phase gate,
  analyze, boundary lint, diff check, and commit SHA.
- **Execution record:** Applied the production UX contract per persona so actors see submit/publish/pay
  actions, receivers see receive/review actions, read-only personas see non-mutating state, and waiting
  personas see prerequisite copy without admin-only actions.
- **Evidence:** `wf_persona-production-ux-cross-persona-state` proves the Masjid Nur admin publishes a
  public announcement and the member persona receives the published result; B20 screenshot evidence
  remains the full cross-community screenshot source.
- **Gate evidence:** Focused B21-B25 production UX test passed; Android workflow UI evidence sweep passed.
- **Commit:** Consolidated in `4ae3b4a`.

### Phase B24 - Production UX Evidence and Certification Sweep

- **Achieves:** Certifies the full example suite against the production UX standard and updates the Skill
  completion rules so future communities cannot be delivered with generic, incomplete, or untested
  workflows.
- **Deliverables:** Full B12-B24 screenshot evidence manifest, generic-copy failure gate, per-workflow
  production UX audit, per-persona production UX audit, Skill completion-rule update, B24 API Review,
  and B24 UX Decisions.
- **Completed when:** All example/test apps pass production UX workflow tests, every workflow has
  entry/input/review/action/result evidence, every multi-persona workflow has receiver evidence, and
  automated gates fail if user-facing workflow surfaces contain generic harness copy or omit required
  user actions.
- **Evidence to record:** Final B12-B24 evidence manifest, screenshot bundle paths, generic-copy gate
  output, full workflow/emulator sweep output, manifest/test stamps, B24 phase gate, analyze, boundary
  lint, diff check, and commit SHA.
- **Execution record:** Added automated generic-copy failure coverage and certified the refreshed Android
  emulator screenshot evidence against the production UX bar.
- **Evidence:** `docs/Build Plan V2/Evidence/B24/production-ux-certification.json` references
  `docs/Build Plan V2/Evidence/B20/all-workflow-ui-evidence.json` with 66 workflows and 198 screenshots;
  `productionUxGenericCopyViolations()` returned no violations.
- **Gate evidence:** `wf_production-ux-evidence-certification-sweep` passed with test hash
  `02bd693d382e`; `apps/loom_communities_demo/tool/run_workflow_ui_evidence.sh` passed on the Android
  emulator.
- **Commit:** Consolidated in `4ae3b4a`.

### Phase B25 - Independent Production UX Review

- **Achieves:** Runs an outside-in post-implementation product UX review after B22-B24. The review
  critiques the actual visible app experience, identifies design issues and improvement opportunities,
  rejects exposed workflow machinery, and makes a production-grade pass/fail decision independent of the
  implementation checklist.
- **Deliverables:** Community-specific product experience docs, product-doc coverage evidence,
  per-community production UX blueprint derived from those docs, full B12-B20 screenshot capture,
  `b25_capture_coverage_gate.dart` report, independent UX review report, complete product UX screen
  review matrix, schema version 4 machine-readable review evidence, screenshot freshness audit,
  visible-text extraction, UI-pattern classification, domain-native primary-surface audit,
  boilerplate critique audit, LLM Product Docs to Evidence Workflow Reconciliation JSON/Markdown,
  holistic product UX direct-question scorecard,
  workflow/persona direct-question scorecards, semantic workflow interaction-model scorecards, production UX judge scorecard, B25 iteration scorecards,
  B25 remediation tickets with product-spec/implementation/evidence gap classification, remediation
  loop log, severity-ranked findings, annotated screenshot references, resolved-finding evidence,
  owner-accepted minor issue list if any, final UX pass/fail decision, B25 API Review if any API issue
  is discovered, and B25 UX Decisions.
- **Completed when:** The reviewer has walked the actual app in the visible Android emulator across all
  example/test communities and personas, reviewed the final evidence screenshots, documented findings
  across design quality dimensions, and verified that no blocker or major UX issues remain unresolved.
  Minor issues must be fixed, accepted by the owner, or tracked with rationale before the phase can pass.
  A community-specific product experience doc must exist before evidence capture for every reviewed
  community/test app. Native Loom repo runs write those docs under
  `docs/Product Docs V2/Community Examples/<community>-product-experience.md`; standalone Skill runs
  write them under the extension workspace at `docs/product/community-product-experience.md` and treat
  the fetched Loom Product Docs V2 as read-only. A per-community production UX blueprint must then be
  derived from those product docs before any pass verdict and must define the target production
  experience for every community/test app and persona. Schema version 4 machine-readable evidence must
  prove product-doc coverage, LLM Product Docs to Evidence Workflow Reconciliation coverage, blueprint
  coverage, full B12-B20 capture coverage, unique
  screenshot-backed screen rows, screenshot hashes, captured-at timestamps, app commit SHA,
  emulator/device metadata, visible-text extracts,
  UI-pattern classification, primary-surface type, screen-specific critiques, stable
  finding/remediation IDs, unresolved severity counts, rerun requirements, and final decision.
  The review must fail if the primary user-facing experience still exposes workflow machinery, global
  workflow lists, surface/category labels, role-state rationale, metadata-only cards, or weak placeholder
  content instead of domain-native community IA and realistic task content.
  The review must also fail if the LLM Product Docs to Evidence Workflow Reconciliation finds
  unresolved blocker or major drift: Product Docs V2 Section 6 missing screenshot-visible workflows or
  interactions, documented workflows missing from evidence, missing required visible proof,
  undocumented actor/receiver/lifecycle states, or product-doc/evidence surface mappings that keep a
  primary job on a generic workflow card.
  The review must also fail if screens still look like a generic demo scaffold, rely on repeated
  workflow-card layouts as the primary experience, use checklist-style action dialogs, show clipped or
  overlapping controls, lack modern mobile hierarchy, or use placeholder content below a shippable
  product bar.
  The review must also fail if any implemented screen/state/dialog/card/feed/action result is missing
  from the product UX screen review matrix or lacks screenshot evidence and a row-level verdict.
  The review must also fail if screenshot evidence is stale, if rows use boilerplate critique, if the
  JSON/markdown/tracker disagree about the active run, or if any primary workflow surface remains a
  generic workflow-card, checklist/review modal, metadata/settings page, or repeated card shell.
  The review must also fail if the holistic product UX direct-question pass is missing or not green, if
  any workflow/persona direct-question pass is missing or not green, if any primary workflow/persona row
  lacks passing semantic surface proof from after screenshots, if any primary workflow/persona row lacks
  passing semantic interaction-model proof from after screenshots, if a remediated ticket lacks
  before/after evidence proving the target-surface elements are now visible, or if
  `production_ux_judge.dart` produces any blocking criterion failure. If the judge identifies a
  `product-spec-gap`, the next pass must update the relevant product experience doc before UI
  remediation starts. The review must also fail if `reviewInputEvidence` was generated from targeted,
  incomplete, stale, or non-commit-eligible screenshot evidence instead of a full B12-B20 capture.
  Each review/remediation pass must produce a B25 iteration scorecard before the pass is committed or
  the next remediation loop starts.
  If the B25 review standard changes, prior passes must be explicitly superseded and B25 must be
  reopened until the latest standard passes.
  When the review fails with any blocker or major finding, B25 must apply fixes and rerun the review
  loop. Each loop iteration must be committed before the next UX feedback or correction batch starts. A
  failed review-only report is not sufficient phase completion.
- **Evidence to record:** Community product experience docs, product-doc coverage table,
  `B20/all-workflow-ui-evidence.json` with `captureMode=full-b25`,
  `b25-capture-coverage-report.json`, independent review report, product UX screen review matrix,
  findings table, production UX blueprint derived from the product docs, schema version 4 JSON
  evidence, screenshot hashes/timestamps, app commit SHA,
  emulator/device metadata, visible-text extraction, UI-pattern classification, domain-native
  primary-surface audit, boilerplate critique audit, holistic direct-question answers,
  workflow/persona direct-question scorecards, semantic workflow interaction-model scorecards, semantic surface proof, production UX judge scorecard,
  B25 iteration scorecards, B25 remediation tickets with gap classification, annotated screenshots or
  screenshot paths, before/after ticket-closure screenshots, product-doc diffs for product-spec gaps,
  remediation diffs/evidence, retest output for fixed findings, final pass/fail statement,
  manifest/test stamps, B25 phase gate, analyze, boundary lint, diff check, per-iteration commit SHAs,
  and final closeout commit SHA.
- **Execution record:** B25 v3 iteration 3 is now historical and superseded by the v4 production UX
  standard. The historical iteration created
  `docs/Build Plan V2/Evidence/B25/production-ux-blueprint.md`, regenerated schema version 3
  machine-readable review evidence, inventoried 202 screen rows, and closed four major findings:
  debug banner removal, FAB-safe community list spacing, domain-icon community identity, and
  form-category copy/metadata replacement. It did not enforce v4 screenshot freshness, visible-text
  extraction, non-boilerplate critique, direct-question holistic/workflow-persona scorecards, or
  domain-native primary-surface replacement gates, and it did not produce per-pass iteration scorecards.
- **Evidence:** Historical v3 evidence is recorded in
  `docs/Build Plan V2/Evidence/B25/production-ux-blueprint.md`,
  `docs/Build Plan V2/Evidence/B25/product-ux-screen-review-matrix.md`,
  `docs/Build Plan V2/Evidence/B25/product-ux-remediation-loop.md`,
  `docs/Build Plan V2/Evidence/B25/independent-production-ux-review.md`, and
  `docs/Build Plan V2/Evidence/B25/independent-production-ux-review.json`. These artifacts must be
  superseded by a v4 run before B25 can close again.
- **Gate evidence:** Historical v3 checks passed:
  `flutter test apps/loom_communities_demo/test/b21_b25_production_ux_test.dart`;
  `flutter test apps/loom_communities_demo/test/a6_loom_communities_demo_test.dart`; full
  `flutter test apps/loom_communities_demo/test`; Android `flutter drive` workflow evidence sweep;
  `flutter analyze apps/loom_communities_demo`; manifest gate, B25 phase gate, boundary lint, and
  diff check passed. Required v4 direct-question, evidence freshness, and production UX judge checks are
  pending.
- **Prior v4 pass:** `b25-v4-pass-12` closed the semantic-closure, product-doc, and semantic
  interaction-model bar added after review of the Masjid Nur screens. It added visible sender/author,
  notification content, RSVP result, document file metadata, no-fill disclosure, and protected
  minor-redaction proof, then reran the B25 evidence and judge chain against fresh screenshots.
  `b25_capture_workflow_screenshots.dart` recaptured B12-B20 as phase-split `flutter drive` evidence
  and wrote 208 screenshot files. The B25 collector generated 195 schema v4 screen rows,
  workflow/persona coverage passed 68 of 68 rows, `b25_visual_inspection_auditor.dart` passed 195 of
  195 rows, `b25_independent_ux_judge.dart` passed with 0 findings, `b25_workflow_interaction_model_judge.dart`
  passed 68 of 68 lifecycle rows, and `production_ux_judge.dart` passed 14 of 14 criteria. The
  iteration scorecard `docs/Build Plan V2/Evidence/B25/b25-iteration-scorecard-b25-v4-pass-12.md`
  records `B25 can pass=true`, 0 blockers, 0 unresolved major findings, and 0 newly introduced
  blocker/major findings. Manifest gate, B25 phase gate, boundary lint, and `git diff --check` passed.
- **Current v4 pass:** `b25-v4-pass-20` consumed the pass-19 remediation plan and added richer
  product-surface fallback content for the communities that were still falling through to generic
  workflow surfaces. Code gates passed (`dart format`, `flutter analyze apps/loom_communities_demo`,
  and `flutter test apps/loom_communities_demo/test/b21_b25_production_ux_test.dart`). Full B12-B20
  screenshot capture passed with `198` screenshots, `66` workflows, and `9` workflow manifests; the
  capture coverage gate passed; the B25 collector generated `195` schema v4 screen rows;
  workflow/persona coverage passed `68 / 68`; and visual inspection passed. The fresh LLM Product Docs
  to Evidence Workflow Reconciliation failed with major product-doc/workflow drift: several community
  Product Docs V2 specs still use umbrella or old workflow IDs and sparse persona/state matrices while
  the screenshot evidence uses exact B25 workflow IDs. The fresh LLM Vision UX review passed freshness
  but failed with three major findings: repeated generic surfaces remain in Camera Club, Member Social
  Space, Ad-Free Community, and Data Portability; 26 workflow/persona paths still lack full lifecycle
  proof; and the holistic product-quality question still fails. `b25_workflow_interaction_model_judge.dart`
  failed `26 / 68` lifecycle rows. `production_ux_judge.dart` failed `7` criteria and generated
  `7` major remediation tickets in
  `docs/Build Plan V2/Evidence/B25/b25-remediation-tickets-b25-v4-pass-20.md`. The iteration
  scorecard `docs/Build Plan V2/Evidence/B25/b25-iteration-scorecard-b25-v4-pass-20.md` records
  `B25 can pass=false`, `0` blockers, `4` unresolved major findings, and `4` remaining blocking/major
  findings. The next-pass remediation planner generated
  `docs/Build Plan V2/Evidence/B25/b25-remediation-plan-b25-v4-pass-21.md` with `6` product-spec work
  items, `26` evidence-repair work items, and `27` UI remediation work items.
- **Commit:** Historical iteration 3 implementation `ccc3f40`; v4 pass-1 ticket/planner closeout
  `5d4e313`; detailed ticket schema update `f617625`; work-item split update `42e7cdf`;
  reference-pattern ticket update `6d01a22`; v4 pass-2 `68b5fad`; v4 pass-3 `9c59a5a`; v4 pass-4 `b672089`;
  v4 pass-16 `3ad49ea`; v4 pass-17 `bc99df3`; v4 pass-19 `97d1a82`.

## Gate Evidence Template

For each completed phase, paste or link:

- `melos bootstrap`
- `melos run analyze`
- `melos run lint:boundaries`
- `melos run test`
- `melos run test:integration` or focused phase command
- `melos run validate:extension`, when package behavior changed
- `melos run test:demo-local`, when Demo App/local backend behavior changed
- `melos run test:workflows:demo-local`, for every Set B workflow phase
- `manifest_gate`
- `phase_gate --phase <phase>`
- API Review path
- UX Decisions path, if applicable
- Skill files updated
- Component version hashes
- Test hash updates
- Screenshot evidence bundle path, for B12+ UI evidence phases
- `workflow-ui-evidence.json` path and audit output, for B12+ UI evidence phases
- Android emulator/device name, API level, screenshot capture command, and command output path, for
  B12+ UI evidence phases
- Failure screenshots, logs, or videos when any UI evidence step fails, for B12+ UI evidence phases
- Persona inventory, role/capability matrix, workflow dependency graph, per-persona workflow matrix,
  selected-persona screenshots, prerequisite-chain evidence, and cross-persona workflow evidence
  manifests, for B17+ persona phases
- Production workflow UX contract matrix, workflow-type pattern map, generic-copy failure gate,
  entry/input/review/action/result screenshots, persona receiver screenshots, and production UX audit,
  for B21+ production UX phases
- Independent post-implementation UX review report, severity-ranked findings, remediation evidence, and
  final pass/fail decision, for B25+ independent UX review phases
- Judge tool scorecards for B11 and B21-B25: workflow completeness, UX contract, domain surface,
  persona UX, evidence integrity, and production UX criteria, as applicable
- For B25 specifically, holistic product UX direct-question answers and workflow/persona
  direct-question scorecards, both green
- For B25 specifically, remediation ticket JSON/Markdown for every failed blocking criterion
- For failed B25 passes, remediation planner JSON/Markdown is the first artifact of the next
  remediation pass, converting the prior pass's tickets into ordered worker batches
- For B25 specifically, B25 iteration scorecard JSON/Markdown for the pass, including resolved and
  remaining blocker/major counts
- Commit SHA

Run each command above through WSL Ubuntu from `app/`, for example:

```powershell
wsl.exe -d Ubuntu -- bash -lc 'cd "/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app" && melos bootstrap'
```

## Component Version Template

Use the component hash generated by `manifest_gate`.

| Component | Phase built | Current version hash | Last phase verified |
| --- | --- | --- | --- |
| ai-skill-extension-builder | 0 | 518c78e30a44 | B11 |
| skill-debug-harness | 0 | 4e3ce721c363 | B11 |
| passport-ledger | A1 | f6e17f408e74 | A1 |
| role-policy-consent-engine | A1 | 01288a26926f | A1 |
| core-member-vault | A1 | 67421d04854e | A1 |
| protected-visibility-vault | A1 | 3795b6a09b20 | A1 |
| connections-graph | A1 | 297b5d201b5f | A1 |
| receipt-ledger | A1 | 9f9e82fd4a2f | A1 |
| audit-ledger | A1 | 0b57bac5ec69 | A1 |
| event-bus | A1 | 1f233230d7c9 | A1 |
| key-management | A1 | 16c1bdc8be88 | A1 |
| builder-app-id-service | A1 | 46dfcdb9934e | A1 |
| loom-local-store | A1 | 2d8dbc534574 | A1 |
| community-registry | A2 | 10643e91b879 | A2 |
| extension-registry | A2 | 845149fec120 | A2 |
| certification-system | A2 | 7d026e0c94bc | A2 |
| invitation-service | A2 | d762581a0d01 | A2 |
| membership-service | A2 | 743b4c1a71e2 | A2 |
| public-registry-read-model | A2 | 092951c163e1 | A2 |
| spaces-service | A2 | 669c7e405b9a | A2 |
| workflow-inventory-registry | A2 | 7ab9c7b379ee | A2 |
| api-spec-inventory | 0 | 9d57761d8326 | B8 |
| phase-test-manifest-bridge | 0/A2 | 89e620c5af33 | A2 |
| publishing-service | A3 | 0e31d279bf88 | A3 |
| messaging-stream-service | A3 | 709572cac272 | A3 |
| notification-service | A3 | b7c57774de42 | A3 |
| events-service | A3 | dee493ff7d53 | A3 |
| forms-voting-service | A3 | 72bf23f58102 | A3 |
| export-service | A4a | 9079b5ad7e37 | B4 |
| import-service | A4a | 0a178c20caba | B8 |
| provider-transfer-service | A4a | 7a931f77c1e1 | B8 |
| wallet-dues-donations | A4b | f49eb0bac62d | B7 |
| ad-decision-service | A4b | e5a7593ee1ea | A4b |
| search-service | A4b | 00f0b4124434 | A4b |
| extension-runtime-bridge | A5 | 1aff2ed72457 | A5 |
| extension-package-validator | A5 | 512380dc6848 | A5 |
| initialization-package-schema | A5 | 1dd4a2b2ca52 | A5 |
| data-schema-store | A5 | 6a09d351f11f | B8 |
| app-shell-runtime | A6 | c7c0a602fdad | A6 |
| loom-communities-demo-app | A6 | 54381f30f982 | B25 v4 pass 17 |
| loom-ux-judges | B21-B25 | 064ab5f4dcf4 | B25 v4 pass 17 LLM evidence reconciliation |
| local-in-app-backend | A6 | 5d1deb013df1 | B10 archive hardening |

## Artifact Completion Checklist

Use this checklist when closing a phase:

- Phase status changed from `Not started` to `Complete`.
- Gate evidence pasted or linked.
- Component hashes recorded.
- Test hashes and manifest stamps updated.
- API Review updated and linked.
- UX Decisions updated and linked where applicable.
- Skill component/workflow guides updated.
- Example packages or fixtures updated where applicable.
- Commit SHA recorded.
