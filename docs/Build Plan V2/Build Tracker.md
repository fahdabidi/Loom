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
The B25 tool sequence is product experience doc steward -> advisory card-surface/app-shell navigation
registry refresh ->
full B12-B20 screenshot capture -> `b25_capture_coverage_gate.dart` -> evidence collector -> workflow/persona coverage collector ->
visual inspection auditor -> deterministic review scaffold -> `b25_component_doc_context.dart` -> LLM Product Docs to Evidence Workflow
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
The app-shell navigation registry records `persona -> tabs -> pinning policy -> customization knobs`
in the community product docs and B25 evidence. Home and Messages/Communication are mandatory;
custom tabs, tab labels/icons/order, persona visibility, surface assignment, explicit pinning policy,
minimized/medium/expanded defaults, and theme/typography/color/density customization are now a hard
App Shell capability utilization gate. B25 cannot close unless `appShellCapabilityReview` passes from
fresh screenshots and proves the documented tabs, appropriate per-tab pinning policy,
minimized/medium/expanded states,
tap-to-expand behavior, community-list card states, renderer selection, and customization tokens where
the product docs or App Shell component guide require them. A tab may explicitly declare no pinned
surfaces when the product doc explains why pinning would not help that tab's job-to-be-done.
B25 full capture must include `wf_app-shell-capability-evidence` screenshots for the main community
list, workflow presentation states, any declared pinned surface, and renderer-selection proof.
Native Loom repo runs write community product experience docs under
`docs/Product Docs V2/Community Examples/<community>-product-experience.md`. Standalone Skill runs treat
the fetched Loom Product Docs V2 as read-only and write the same product contract locally under
`<extension-workspace>/docs/product/community-product-experience.md`. The B25 blueprint is a review
summary derived from those product docs, not a substitute for them. Tickets must classify failures as
`product-spec-gap`, `implementation-gap`, `evidence-gap`, or `mixed-gap`; product-spec gaps update the
product doc before UI remediation begins.
The LLM Product Docs to Evidence Workflow Reconciliation Agent must inspect each community product
doc's `## 3.1 Persona Tabs, Pins, And Customization`, `## 6. Workflow-To-Surface Mapping`, Sections
7-9, B25 semantic interaction model, card-surface registry, and app-shell navigation registry against
the current screenshots/review evidence and the loaded component docs. The required component docs are
`docs/Build Plan V2/Skill/components/card-surfaces/README.md`,
`docs/Build Plan V2/Skill/components/card-surfaces/app-shell-navigation-theming.md`,
`docs/Build Plan V2/Skill/components/card-surfaces/tab-renderer-contracts.md`, and every
`docs/Build Plan V2/Skill/components/card-surfaces/<surface>.md` referenced by the product doc's
card-surface registry. The reconciliation artifact must list those paths in
`reviewedComponentDocPaths` and must include `componentDocReview.docs[]` copied from the current
`b25-component-doc-context-<run-id>.json` plus semantic summaries and community implications for each
required doc. The LLM reviewer must reread these docs every pass, not only when a file changed.
`production_ux_judge.dart` cross-checks each reviewed doc's SHA-256, git last-commit SHA, and git
status against the current repo; missing, stale, or semantically empty component-doc review is a major
finding. It opens tickets when product docs omit screenshot-visible workflows/interactions/tabs/
customization, when documented workflows or persona tabs lack screenshot-backed implementation, when
required visible proof is absent, when app-shell capabilities are not screenshot-proven, when the
chosen card surface or tab renderer contradicts the loaded component docs, when customization/theme
choices do not follow the App Shell guide, or when product docs/evidence map a primary job to a
generic surface.
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
| B25 | In progress - pass 42 failed with missing evidence cross-references | B24 | [Independent Production UX Review](./Phases/Phase%20B25%20-%20Independent%20Production%20UX%20Review.md) | Independent production UX review closes only when fresh full B12-B20 screenshot evidence, Product Docs reconciliation, LLM vision review, workflow lifecycle scorecards, production judge, tickets, and scorecard all pass. | Pass 42 completed a fresh full B12-B20 recapture with `207` screenshots and `67` workflows; all deterministic gates passed (coverage, collector `204` rows, workflow/persona coverage `69`, visual inspection `204`, independent judge `69` scorecards, interaction-model `69`, freshness gate); LLM reconciliation and vision review artifacts generated and freshness-gated; production judge found cross-reference evidence gaps in `appShellCapabilityReview` (`tabRendererResults`, `interactionTransitionResults`) and `productDocWorkflowReconciliation` (`componentDocReview.docs[]`). Open tickets: `0` major findings but `b25CanPass=false` due to criterion failures. Next pass starts from `b25-remediation-plan-b25-v4-pass-43`. | Historical v3 `ccc3f40`; pass 35 `940bc2a`; pass 38 `f6c2aa4`; pass 39 `891de95`; pass 40 `9b63069`; pass 41 `915a35a`; pass 42 `fc3f5ef`. |

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
| B25 | Reviews and certifies the finished UX independently against explicit product experience specs. | Community-specific product experience docs, advisory workflow-to-card-surface registry context, hard App Shell capability utilization review, LLM Product Docs to Evidence Reconciliation JSON/Markdown, full B12-B20 screenshot capture, `b25_capture_coverage_gate.dart` report, outside-in product UX review, schema v4 evidence, screenshot freshness audit, non-boilerplate screen critique, domain-native primary-surface gate, holistic direct-question scorecard, workflow/persona direct-question scorecards, `b25_llm_review_freshness_gate.dart` report, semantic surface proof, production UX judge scorecard, detailed remediation tickets with gap classification, before/after closure evidence, iteration scorecards, remediation evidence, final pass/fail decision; failed-pass tickets feed the next pass's remediation planner. | The UX passes only when every reviewed community/test app has a current product experience doc, the B25 blueprint is derived from those docs, the LLM Product Docs to Evidence Reconciliation pass has no unresolved blocker/major product-doc, implementation, evidence, mapping, or App Shell capability gaps, `appShellCapabilityReview` passes from fresh screenshots, the canonical screenshot evidence is a commit-eligible full B12-B20 capture, an independent screenshot-first review and the production UX judge find no unresolved blocker or major design issues, the LLM Vision UX Judge artifact is fresh for the current run/app commit/screenshots and is not carried forward from a prior pass, every screenshot is fresh and traceable, every primary workflow is domain-native, the holistic and workflow/persona direct-question passes are green, every primary workflow/persona row proves the requested target surface from after-screenshot visible evidence, every failed pass has template-complete remediation tickets and a convergence scorecard, every remediated ticket closes from before/after screenshot proof rather than implementation claims, and any minor issues are accepted or tracked. The card-surface/API registry is required context but not yet a standalone coverage gate. A remediation pass may not begin implementation until the prior pass's tickets have been converted into a remediation plan, and any product-spec-gap must update the product experience doc before UI remediation. |

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
Use the repeatable WSL launcher for visible/manual emulator review instead of ad hoc emulator commands:
`bash app/packages/tooling/launch_loom_demo_emulators.sh --restart --mode both --run-app --app-target manual`.
The `--restart` mode stops attached emulator instances before launching both AVDs with `-read-only`,
which avoids Android's concurrent-emulator failure when a prior window was started writable.
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
| B25 | Product Experience Doc Steward; advisory Card-Surface Registry Refresh; `b25_evidence_collector.dart`; `b25_component_doc_context.dart`; LLM Product Docs to Evidence Workflow Reconciliation Agent; LLM Vision UX Judge Agent; `b25_llm_review_freshness_gate.dart`; `b25_llm_ux_review_importer.dart`; `b25_workflow_interaction_model_judge.dart`; `production_ux_judge.dart`; `b25_iteration_scorecard.dart`; next-pass `b25_remediation_planner.dart` | Current pass: community product experience docs with advisory card-surface registry sections, derived `production-ux-blueprint.md`, `b25-component-doc-context-<run-id>.json/.md`, `llm-product-doc-workflow-reconciliation-<run-id>.json/.md` with `componentDocReview.docs[]` and `appShellCapabilityReview`, `llm-vision-ux-review-<run-id>.json`, `b25-llm-review-freshness-gate-<run-id>.json/.md`, `independent-production-ux-review.json/.md` with `llmVisionReview`, `product-ux-screen-review-matrix.md`, `b25-workflow-lifecycle-scorecards.md`, `production-ux-criteria-scorecard.json/.md`, `b25-remediation-tickets-<run-id>.json/.md`, `b25-iteration-scorecard-*.json/.md`, plus `productDocCoverage`, `cardSurfaceRegistry`, `productDocWorkflowReconciliation`, `appShellCapabilityReview`, `holisticQuestionAnswers`, `workflowPersonaScorecards`, `workflowLifecycleScorecards`, and `llmVisionReview` in review JSON. Next pass kickoff: `b25-remediation-plan-<prior-run-id>.json/.md`. | Product docs are missing or stale, advisory registry context is absent from B25 evidence, no fresh LLM product-doc reconciliation exists, `componentDocReview.docs[]` is missing/stale/semantically empty or fails current hash/git metadata cross-checks, `appShellCapabilityReview` is missing or failing, the reconciliation has unresolved blocker/major product-doc/implementation/evidence/mapping/app-shell gaps, evidence was not collected by the deterministic collector, no fresh LLM vision review passed the freshness gate and importer, any LLM vision finding blocks pass, any B25 pass criterion has a blocking failure without a template-complete remediation ticket, any direct-question or interaction-model pass is missing/partial/unsupported, any primary workflow surface is not domain-native, any primary workflow interaction model lacks expected decision, concrete object/context, decision information, primary action, alternate/change/reject path, result state, receiver/continuation state, or fresh screenshot proof, or the iteration scorecard is missing for the pass. A remediation pass fails before implementation if the prior pass's tickets were not sent to the planner; a product-spec-gap fails if the product doc was not updated before UI remediation. Advisory card-surface/API gaps should be recorded for remediation context, but they are not yet a standalone card-surface/API coverage gate. |

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
| B25 | pending | In progress - pass 40 failed hardening gate | Pass 40 hardened the B25 LLM/App Shell gate, reran `production_ux_judge.dart` against current pass-39 evidence, generated `8` major remediation tickets, and produced `b25-remediation-plan-b25-v4-pass-41`. Pass 39 is historical under the hardened rules. |

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
  `docs/Build Plan V2/Evidence/B25/independent-production-ux-review.json`. These artifacts were
  superseded by the current `b25-v4-pass-39` run before B25 closeout.
- **Gate evidence:** `b25-v4-pass-39` passed the required v4 gate chain: full B12-B20 capture
  (`207` screenshots, `67` workflows, `9` manifests), `b25_capture_coverage_gate.dart`,
  `b25_evidence_collector.dart` (`204` schema v4 rows), workflow/persona coverage (`69 / 69`),
  visual inspection (`204 / 204`), fresh Product Docs to Evidence reconciliation with
  `appShellCapabilityReview.status=pass`, fresh LLM Vision review freshness/import, workflow
  interaction-model judge (`69 / 69`), production UX judge (`17 / 17` criteria), and iteration
  scorecard with `B25 can pass=true` and `0` remaining blocker/major findings.
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
- **Prior v4 pass:** `b25-v4-pass-20` consumed the pass-19 remediation plan and added richer
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
  v4 pass-16 `3ad49ea`; v4 pass-17 `bc99df3`; v4 pass-19 `97d1a82`; v4 pass-20
  `6ff5b8d`.

- **Execution record, v4 pass 21:** Consumed
  `docs/Build Plan V2/Evidence/B25/b25-remediation-plan-b25-v4-pass-21.md`, updated community
  Product Docs V2 exact workflow/persona mapping rows, added domain preview panels for Camera Club,
  Platform Social, Ad-Free Community, and Data Portability surfaces, and updated the screenshot
  capture harness to scroll offscreen workflow buttons into view before tapping them. Focused
  production UX tests, `flutter analyze apps/loom_communities_demo`, and formatting passed. Full
  B12-B20 screenshot capture passed with `198` screenshots, `66` workflows, and `9` workflow
  manifests; capture coverage passed; the B25 collector generated `195` schema v4 screen rows;
  workflow/persona coverage passed `68 / 68`; visual inspection passed `195 / 195`. Fresh LLM Product
  Docs reconciliation failed with remaining Product Docs drift in several Section 7/semantic rows.
  Fresh LLM Vision UX review failed with three major findings: incomplete lifecycle proof across 22
  workflow/persona rows, B20 CTA wrapping, and repeated generic panels in Camera/Platform/Ad-Free
  flows. `b25_workflow_interaction_model_judge.dart` improved from `26 / 68` failing lifecycle rows
  to `22 / 68`, but still failed. `production_ux_judge.dart` failed `9` criteria and generated
  `docs/Build Plan V2/Evidence/B25/b25-remediation-tickets-b25-v4-pass-21.md`. The iteration
  scorecard `docs/Build Plan V2/Evidence/B25/b25-iteration-scorecard-b25-v4-pass-21.md` records
  `B25 can pass=false`, `0` blockers, `4` unresolved major findings, and `4` remaining
  blocking/major findings. The next-pass remediation planner generated
  `docs/Build Plan V2/Evidence/B25/b25-remediation-plan-b25-v4-pass-22.md` with `9` tickets and
  `3` remediation batches.
- **Commit, v4 pass 21:** `97096d9`.
- **Execution record, v4 pass 22:** Consumed
  `docs/Build Plan V2/Evidence/B25/b25-remediation-plan-b25-v4-pass-22.md`, updated Product Docs V2
  community example rows for exact workflow/persona/semantic mappings, added richer domain previews
  for Camera Club, Platform Social, and Ad-Free Community workflows, exposed interaction-model
  summaries on rich workflow surfaces, and adjusted B20 action label wrapping. Focused production UX
  tests, `flutter analyze apps/loom_communities_demo`, and formatting passed before full capture. Full
  B12-B20 screenshot capture passed with `198` screenshots, `66` workflows, and `9` workflow
  manifests; capture coverage passed; the B25 collector generated `195` schema v4 screen rows;
  workflow/persona coverage passed `68 / 68`; visual inspection passed `195 / 195`. Fresh LLM Product
  Docs reconciliation failed with `6` major product-doc/scope findings. Fresh LLM Vision UX review
  failed with `5` major findings: B20 CTA wrapping, failed workflow/persona scorecards, seven
  lifecycle failures, repeated Ad-Free checkout panels, and visible framework/surface copy leakage.
  `b25_workflow_interaction_model_judge.dart` improved from `22 / 68` failing lifecycle rows to
  `7 / 68`, but still failed. `production_ux_judge.dart` failed `9` criteria and generated
  `docs/Build Plan V2/Evidence/B25/b25-remediation-tickets-b25-v4-pass-22.md`. The iteration
  scorecard `docs/Build Plan V2/Evidence/B25/b25-iteration-scorecard-b25-v4-pass-22.md` records
  `B25 can pass=false`, `0` blockers, `6` unresolved major findings, `3` resolved
  blocker/major findings, and `5` newly introduced blocker/major findings under the fresh LLM review.
  The next-pass remediation planner generated
  `docs/Build Plan V2/Evidence/B25/b25-remediation-plan-b25-v4-pass-23.md` with `9` tickets and
  `3` remediation batches.
- **Commit, v4 pass 22:** `45264e1`.
- **Execution record, v4 pass 23:** Consumed
  `docs/Build Plan V2/Evidence/B25/b25-remediation-plan-b25-v4-pass-23.md`, repaired Product Docs V2
  community example mappings for Garden Club, Neighborhood Book Club, Chess Club, Loom Communities
  Shell, and Persona Role Inventory, added richer platform messaging/block-state, ad-off, camera gear
  loan, and portability-style surfaces, fixed compact action-button wrapping, and hardened the
  capture/import tooling so full B12-B20 evidence and LLM direct-question answers flow through the
  production judge. Focused production UX tests, `flutter analyze apps/loom_communities_demo`, and
  formatting passed before full capture. Full B12-B20 screenshot capture passed with `198`
  screenshots, `66` workflows, and `9` workflow manifests; capture coverage passed; the B25 collector
  generated `195` schema v4 screen rows; workflow/persona coverage passed `68 / 68`; visual inspection
  passed `195 / 195`; and the semantic workflow interaction-model gate passed `68 / 68`. Fresh LLM
  Product Docs reconciliation passed with `0` findings. Fresh LLM Vision UX review failed with `4`
  major findings and `1` minor finding around Book Club digest/export, Data Portability repetition, and
  Chess Club thin/repeated screens. The production UX judge failed `8 / 16` criteria and generated
  `docs/Build Plan V2/Evidence/B25/b25-remediation-tickets-b25-v4-pass-23.md`. The next-pass
  remediation planner generated `docs/Build Plan V2/Evidence/B25/b25-remediation-plan-b25-v4-pass-24.md`
  with `8` tickets and `3` remediation batches.
- **Commit, v4 pass 23:** `a3f0db9`.
- **Execution record, v4 pass 24:** Consumed
  `docs/Build Plan V2/Evidence/B25/b25-remediation-plan-b25-v4-pass-24.md`, added richer Book Club AI
  digest and export metadata surfaces, diversified Data Portability import/export/redaction/checksum/
  rollback surfaces, added HOA owner-notification sender/recipient/timing proof, and strengthened
  Member Social Space message/invite/block-state content in the Demo App. Full B12-B20 screenshot
  capture passed with `198` screenshots and `66` workflows; capture coverage passed; the B25 collector
  generated `195` schema v4 screen rows; workflow/persona coverage passed `68 / 68`; visual inspection
  passed `195 / 195`. Fresh LLM Product Docs reconciliation failed with `8` major findings. Fresh LLM
  Vision UX review failed with `1` critical/blocker and `3` major findings: repeated workflow-card
  scaffold, visible contract-style copy, missing object/result/continuation proof, and harness persona
  surfaces in reviewed product evidence. The production UX judge failed `9 / 16` criteria and generated
  `docs/Build Plan V2/Evidence/B25/b25-remediation-tickets-b25-v4-pass-24.md`. The next-pass
  remediation planner generated `docs/Build Plan V2/Evidence/B25/b25-remediation-plan-b25-v4-pass-25.md`
  with `9` tickets and `3` remediation batches.
- **Commit, v4 pass 24:** `99ed5f3`.
- **Execution record, v4 pass 25:** Consumed
  `docs/Build Plan V2/Evidence/B25/b25-remediation-plan-b25-v4-pass-25.md`, added richer non-standard
  product-surface layouts for search answers, export wizards, message threads, notice details, and
  club scoreboards, removed visible workflow-contract strings such as "Ready to", "Decide", "Receiver
  state", and "Member state" from the primary renderer, and scoped the Loom Communities shell product
  doc out of B25 community screenshot reconciliation unless a future pass adds dedicated shell rows.
  The first capture attempt wrote off-path evidence because of shell quoting and was rejected; the
  accepted direct WSL capture passed full B12-B20 coverage with `198` screenshots, `66` workflows, and
  `9` workflow manifests. Capture coverage passed; the B25 collector generated `195` schema v4 screen
  rows; workflow/persona coverage passed `68 / 68`; visual inspection passed `195 / 195`. Fresh LLM
  Product Docs reconciliation failed with `16` major findings. Fresh LLM Vision UX review failed with
  `1` blocker and `4` major findings: one repeated workflow-card renderer across unrelated
  communities, visible review/evidence/platform/harness language, duplicated screenshot states that do
  not prove distinct production states, incomplete handoff/receipt/recovery lifecycle proof, and visual
  polish gaps. `b25_workflow_interaction_model_judge.dart` failed `13 / 68` lifecycle scorecards. The
  production UX judge failed `9 / 16` criteria and generated
  `docs/Build Plan V2/Evidence/B25/b25-remediation-tickets-b25-v4-pass-25.md`. The iteration
  scorecard `docs/Build Plan V2/Evidence/B25/b25-iteration-scorecard-b25-v4-pass-25.md` records
  `B25 can pass=false` with `6` remaining blocker/major findings. The next-pass remediation planner
  generated `docs/Build Plan V2/Evidence/B25/b25-remediation-plan-b25-v4-pass-26.md` with `9` tickets
  and `3` remediation batches.
- **Commit, v4 pass 25:** `b151e8c`.
- **Execution record, v4 pass 26:** Consumed
  `docs/Build Plan V2/Evidence/B25/b25-remediation-plan-b25-v4-pass-26.md`, expanded the Demo App's
  rich workflow surface families for event detail, form submission, payment receipt, roster/profile,
  request review, media review, and ad entitlement layouts, and removed additional review/spec/harness
  copy from the primary product renderer. Focused production UX tests, `flutter analyze
  apps/loom_communities_demo`, and formatting passed before full capture. Full B12-B20 screenshot
  capture passed with `198` screenshots, `66` workflows, and `9` workflow manifests; capture coverage
  passed; the B25 collector generated `195` schema v4 screen rows; workflow/persona coverage passed
  `68 / 68`; visual inspection passed `195 / 195`. Fresh LLM Product Docs reconciliation failed with
  `6` major findings: all workflow IDs were covered, but product docs/evidence still disagreed on
  surface quality, copy, lifecycle proof, duplicate states, and visual standard. Fresh LLM Vision UX
  review failed with `5` major findings: repeated workflow-card renderer, review/spec/harness copy,
  duplicate screenshots for distinct rows, incomplete lifecycle proof, and visual polish gaps.
  `b25_workflow_interaction_model_judge.dart` failed `22 / 68` lifecycle scorecards. The production UX
  judge failed `9 / 16` criteria and generated
  `docs/Build Plan V2/Evidence/B25/b25-remediation-tickets-b25-v4-pass-26.md`. The iteration scorecard
  `docs/Build Plan V2/Evidence/B25/b25-iteration-scorecard-b25-v4-pass-26.md` records
  `B25 can pass=false`, `0` blockers, `6` unresolved major findings, `5` resolved blocker/major
  findings, and `5` newly introduced blocker/major findings under the fresh LLM review. The next-pass
  remediation planner generated
  `docs/Build Plan V2/Evidence/B25/b25-remediation-plan-b25-v4-pass-27.md` with `9` tickets and `3`
  remediation batches.
- **Commit, v4 pass 26:** `83efed7`.
- **Execution record, v4 pass 27:** Consumed
  `docs/Build Plan V2/Evidence/B25/b25-remediation-plan-b25-v4-pass-27.md`, refactored the Demo
  App's rich workflow renderer so product surfaces render a distinct header, product preview, status
  panel, and action/result section instead of one monolithic generic card, and removed additional
  visible review/spec/lifecycle phrasing from primary surfaces. Focused production UX tests,
  `flutter analyze apps/loom_communities_demo`, and formatting passed before full capture. Full
  B12-B20 screenshot capture passed with `198` screenshots, `66` workflows, and `9` workflow
  manifests; capture coverage passed; the B25 collector generated `195` schema v4 screen rows;
  workflow/persona coverage passed `68 / 68`; visual inspection passed `195 / 195`. Fresh LLM Product
  Docs reconciliation failed with `32` major findings, mostly visible-proof and semantic lifecycle
  mismatches across the documented community product experience rows. Fresh LLM Vision UX review
  failed with `6` major findings: systemic repeated card rendering, remaining review/spec/lifecycle
  copy, duplicate screenshots for distinct workflow rows, result states that still look like status
  panels, visual identity/navigation polish below the production bar, and persona-picker/wf_* harness
  surfaces remaining in reviewed product evidence. `b25_workflow_interaction_model_judge.dart` failed
  `22 / 68` lifecycle scorecards. The production UX judge failed `9 / 16` criteria and generated
  `docs/Build Plan V2/Evidence/B25/b25-remediation-tickets-b25-v4-pass-27.md`. The iteration
  scorecard `docs/Build Plan V2/Evidence/B25/b25-iteration-scorecard-b25-v4-pass-27.md` records
  `B25 can pass=false`, `0` blockers, `7` unresolved major finding groups, `5` resolved
  blocker/major findings, and `6` newly introduced blocker/major findings under the fresh LLM review.
  The next-pass remediation planner generated
  `docs/Build Plan V2/Evidence/B25/b25-remediation-plan-b25-v4-pass-28.md` with `9` tickets and `3`
  remediation batches.
- **Commit, v4 pass 27:** `176e15f`.
- **Execution record, v4 pass 28:** Consumed
  `docs/Build Plan V2/Evidence/B25/b25-remediation-plan-b25-v4-pass-28.md`, refactored the Demo
  App product-surface renderer into specialized event, form, receipt, wizard, feed, roster,
  scoreboard, and default frames, removed visible surface-family taxonomy from primary UI, cleaned
  additional workflow/review phrasing, and improved long-title app bar behavior. Focused production UX
  tests and `flutter analyze apps/loom_communities_demo` passed before full capture. Full B12-B20
  screenshot capture passed with `198` screenshots, `66` workflows, and `9` workflow manifests;
  capture coverage passed; the B25 collector generated `195` schema v4 screen rows;
  workflow/persona coverage passed `68 / 68`; visual inspection passed `195 / 195`; and the LLM
  review freshness gate passed for `b25-v4-pass-28`. Fresh LLM Product Docs reconciliation failed with
  `32` major findings: screenshots are current and screenshot-backed, but many product-doc workflow
  rows still lack visible proof for required content, lifecycle state, persona state, or semantic
  interaction-model elements. Fresh LLM Vision UX review failed with `5` major findings and `60 / 195`
  failed screen rows, mostly around repeated workflow evidence surfaces, platform/harness rows in
  product review scope, and screens whose visible content still does not prove a modern
  community-specific product experience. `b25_workflow_interaction_model_judge.dart` failed `28 / 68`
  lifecycle scorecards. The production UX judge failed `9 / 16` criteria and generated
  `docs/Build Plan V2/Evidence/B25/b25-remediation-tickets-b25-v4-pass-28.md`. The iteration
  scorecard `docs/Build Plan V2/Evidence/B25/b25-iteration-scorecard-b25-v4-pass-28.md` records
  `B25 can pass=false`, `0` blockers, `38` unresolved major finding IDs, `0` resolved
  blocker/major findings, and `38` new blocker/major finding IDs after the Product Docs
  reconciliation findings were attached to the main review evidence. The next-pass remediation planner
  generated `docs/Build Plan V2/Evidence/B25/b25-remediation-plan-b25-v4-pass-29.md` with `9`
  tickets and `3` remediation batches.
- **Commit, v4 pass 28:** `562a424`.

- **Execution record, v4 pass 29:** Consumed
  `docs/Build Plan V2/Evidence/B25/b25-remediation-plan-b25-v4-pass-29.md`, added distinct action
  consoles for event, form, payment, export, communication, roster, club, media-review, ad/no-fill,
  and fallback flows, reduced persona-picker testing language, and added concrete photo critique and
  ad/no-fill preview evidence. Focused production UX tests, formatting, and `flutter analyze
  apps/loom_communities_demo` passed before full capture. Full B12-B20 screenshot capture passed with
  `198` screenshots, `66` workflows, and `9` workflow manifests; capture coverage passed; the B25
  collector generated `195` schema v4 screen rows; workflow/persona coverage passed `68 / 68`; visual
  inspection passed `195 / 195`; and the LLM freshness gate passed for `b25-v4-pass-29`. Fresh LLM
  Product Docs reconciliation failed with `5` major findings. Fresh LLM Vision UX review failed with
  `1` blocker and `4` major findings: shared action/review checklist surfaces, non-payment workflows
  in payment-style summary panels, generic export surfaces, non-production persona handoff, and
  repeated-card visual fatigue. `b25_workflow_interaction_model_judge.dart` failed `4 / 68` lifecycle
  scorecards. The production UX judge failed `9 / 16` criteria and generated
  `docs/Build Plan V2/Evidence/B25/b25-remediation-tickets-b25-v4-pass-29.md`. The iteration
  scorecard `docs/Build Plan V2/Evidence/B25/b25-iteration-scorecard-b25-v4-pass-29.md` records
  `B25 can pass=false`, `1` blocker, `10` unresolved major findings, `0` resolved blocker/major
  findings, and `11` new blocker/major findings under the fresh LLM review. The next-pass remediation
  planner generated `docs/Build Plan V2/Evidence/B25/b25-remediation-plan-b25-v4-pass-30.md` with
  `9` tickets and `3` remediation batches.
- **Commit, v4 pass 29:** `00b0339`.

- **Execution record, v4 pass 30:** Consumed
  `docs/Build Plan V2/Evidence/B25/b25-remediation-plan-b25-v4-pass-30.md`, removed generic action
  console rows from the shared renderer, split ad/no-fill actions away from payment checkout actions,
  routed facility/reservation language away from generic payment inference, and replaced additional
  framework-like `confirm/review/surface` copy with product-state language. Focused production UX
  tests and `flutter analyze apps/loom_communities_demo` passed before full capture. Full B12-B20
  screenshot capture passed with `198` screenshots, `66` workflows, and `9` workflow manifests after
  rerunning a timed-out first attempt; capture coverage passed; the B25 collector generated `195`
  schema v4 screen rows; workflow/persona coverage passed `68 / 68`; visual inspection passed
  `195 / 195`; and the LLM freshness gate passed for `b25-v4-pass-30`. Fresh LLM Product Docs
  reconciliation failed with `9` major findings and `1` minor finding. Fresh LLM Vision UX review
  failed with `6` major findings and no blockers: global repeated-card scaffold, ad-off checkout using
  sponsored-message context, protected redaction proof gap, persona-picker harness language, remaining
  lifecycle gaps, and low-contrast dimmed action content. `b25_workflow_interaction_model_judge.dart`
  failed `11 / 68` lifecycle scorecards. The production UX judge failed `9 / 16` criteria and
  generated `docs/Build Plan V2/Evidence/B25/b25-remediation-tickets-b25-v4-pass-30.md`. The
  iteration scorecard `docs/Build Plan V2/Evidence/B25/b25-iteration-scorecard-b25-v4-pass-30.md`
  records `B25 can pass=false`, `0` blockers, `16` unresolved major findings, `0` resolved
  blocker/major findings, and `16` new blocker/major findings under the fresh LLM review. The next-pass
  remediation planner generated `docs/Build Plan V2/Evidence/B25/b25-remediation-plan-b25-v4-pass-31.md`
  with `9` tickets and `3` remediation batches.
- **Commit, v4 pass 30:** `0dd2c6c`.

- **Execution record, v4 pass 31:** Consumed
  `docs/Build Plan V2/Evidence/B25/b25-remediation-plan-b25-v4-pass-31.md`, separated knowledge/search,
  sponsored-placement, and ad-free account sections, routed ad-off entitlement/settlement flows away
  from generic payment and sponsored-message language, reduced persona-picker harness copy, and added
  account-specific ad-free controls. Focused production UX tests and
  `flutter analyze apps/loom_communities_demo` passed before full capture. Full B12-B20 screenshot
  capture passed with `198` screenshots, `66` workflows, and `9` workflow manifests; capture coverage
  passed; the B25 collector generated `195` schema v4 screen rows; workflow/persona coverage passed
  `68 / 68`; visual inspection passed `195 / 195`; and the LLM freshness gate passed for
  `b25-v4-pass-31`. Fresh LLM Product Docs reconciliation failed with `15` major findings. Fresh LLM
  Vision UX review failed with `4` major findings: repeated-card fatigue, weak product-surface
  differentiation, utility/evidence-style screens, and dimmed action states. The semantic interaction
  model judge failed `12 / 68` lifecycle scorecards. The production UX judge failed `9 / 16` criteria
  and generated `docs/Build Plan V2/Evidence/B25/b25-remediation-tickets-b25-v4-pass-31.md`. The
  iteration scorecard `docs/Build Plan V2/Evidence/B25/b25-iteration-scorecard-b25-v4-pass-31.md`
  records `B25 can pass=false`, `0` blockers, `20` unresolved major findings, `0` resolved
  blocker/major findings, and `20` new blocker/major findings under the fresh LLM review. The next-pass
  remediation planner generated `docs/Build Plan V2/Evidence/B25/b25-remediation-plan-b25-v4-pass-32.md`
  with `9` tickets and `3` remediation batches.
- **Commit, v4 pass 31:** `af3ce6e`.
- **Execution record, v4 pass 32:** Consumed
  `docs/Build Plan V2/Evidence/B25/b25-remediation-plan-b25-v4-pass-32.md`, committed the app-shell
  navigation/card-surface registry remediation in `613fde3`, and then ran a fresh full B25 review
  against that committed app SHA. Full B12-B20 screenshot capture passed with `198` screenshots,
  `66` workflows, and `9` workflow manifests on `emulator-5554`; capture coverage passed; the B25
  collector generated `195` schema v4 screen rows for `b25-v4-pass-32`; workflow/persona coverage
  passed `68 / 68`; visual inspection passed `195 / 195`; and the LLM freshness gate passed for
  `b25-v4-pass-32`. Fresh LLM Product Docs reconciliation failed with `3` major finding groups:
  screenshots do not yet prove persona tabs/pins/customization, distinct documented card-surface
  implementations, or lifecycle states across all communities. Fresh LLM Vision UX review failed with
  `5` major finding groups: repeated card/product-panel treatment, dimmed action-state evidence,
  utility/export/ad/social/chess status panels, missing tab/pinned-surface evidence, and incomplete
  lifecycle proof. The semantic interaction model judge failed `12 / 68` lifecycle scorecards. The
  production UX judge failed `9 / 16` criteria and generated
  `docs/Build Plan V2/Evidence/B25/b25-remediation-tickets-b25-v4-pass-32.md`. The iteration
  scorecard `docs/Build Plan V2/Evidence/B25/b25-iteration-scorecard-b25-v4-pass-32.md` records
  `B25 can pass=false`, `0` blockers, `9` unresolved major finding groups, `0` resolved
  blocker/major findings, and `9` new blocker/major finding groups. The next-pass remediation planner
  generated `docs/Build Plan V2/Evidence/B25/b25-remediation-plan-b25-v4-pass-33.md` with `9`
  tickets and `3` remediation batches. The loop is still converging because the unresolved major count
  dropped from pass 31's `20` groups to `9`, but B25 remains reopened.
- **Implementation commit, v4 pass 32:** `613fde3`.
- **Evidence/tooling commit, v4 pass 32:** `9ffb789`.

- **Execution record, v4 pass 33:** Consumed
  `docs/Build Plan V2/Evidence/B25/b25-remediation-plan-b25-v4-pass-33.md`, added visible lifecycle
  follow-up actions to completed/received workflow states, and hardened the B25 capture harness so
  horizontal app-shell tabs no longer confuse vertical screenshot capture and B20 action buttons are
  scrolled into view before tapping. Capture-harness fixes landed in `76c0f90` and `441e2ae`. Full
  B12-B20 screenshot capture then passed with `198` screenshots, `66` workflows, and `9` workflow
  manifests on `emulator-5554`; capture coverage passed; the B25 collector generated `195` schema v4
  screen rows for `b25-v4-pass-33`; workflow/persona coverage passed `68 / 68`; visual inspection
  passed `195 / 195`; and the LLM freshness gate passed for `b25-v4-pass-33`. Fresh LLM Product Docs
  reconciliation failed with `3` major finding groups: persona-tab/pin/customization proof gaps,
  surface mismatch for several documented card-surface families, and semantic lifecycle proof gaps.
  Fresh LLM Vision UX review failed with `4` major findings: dimmed/modal action-state screenshots,
  generic utility/status panels for export/ad/social/chess/data flows, incomplete evidence for
  persona-specific tabs/pinned/minimized-medium-expanded navigation, and lifecycle controls that are
  not yet domain-specific enough. The semantic interaction model judge failed `6 / 68` lifecycle
  scorecards, down from `12 / 68` in pass 32. The production UX judge failed `9 / 16` criteria and
  generated `docs/Build Plan V2/Evidence/B25/b25-remediation-tickets-b25-v4-pass-33.md`. The
  iteration scorecard `docs/Build Plan V2/Evidence/B25/b25-iteration-scorecard-b25-v4-pass-33.md`
  records `B25 can pass=false`, `0` blockers, `5` unresolved major finding groups, `0` resolved
  blocker/major findings, and `5` new blocker/major finding groups. The next-pass remediation planner
  generated `docs/Build Plan V2/Evidence/B25/b25-remediation-plan-b25-v4-pass-34.md` with `9`
  tickets and `3` remediation batches. The loop is still converging because remaining major groups
  dropped from pass 32's `9` to pass 33's `5`.
- **Evidence/tooling commit, v4 pass 33:** `a2f0628`.

- **Execution record, v4 pass 34:** Consumed
  `docs/Build Plan V2/Evidence/B25/b25-remediation-plan-b25-v4-pass-34.md`. Implementation commits
  `690e8f4` and `963b0ab` replaced dimmed modal action states with full-screen action surfaces, added
  B20 tab/pinned-surface screenshots, and fixed the horizontal-tab evidence capture helper. Full
  B12-B20 screenshot capture then passed with `201` screenshots, `66` workflows, and `9` workflow
  manifests on `emulator-5554`; capture coverage passed; the B25 collector generated `198` schema v4
  screen rows for `b25-v4-pass-34`; workflow/persona coverage passed `68 / 68`; visual inspection
  failed `13 / 198` rows for `B25-REPEATED-CARD-SHELL-LIKELY`; and the LLM freshness gate passed for
  `b25-v4-pass-34`. Fresh LLM Product Docs reconciliation failed with `22` implementation-visible-proof
  findings where product docs define domain-native surfaces but screenshots still fail the production
  bar. Fresh LLM Vision UX review failed with `3` major findings: low-contrast/repeated action shells,
  insufficient workflow/persona product depth on `16` workflows, and missing persistent lifecycle
  result proof on `6` workflows. The semantic interaction model judge failed `6 / 68` lifecycle
  scorecards. The production UX judge failed with `0` blockers and `4` unresolved major finding groups
  and generated `docs/Build Plan V2/Evidence/B25/b25-remediation-tickets-b25-v4-pass-34.md`. The
  iteration scorecard `docs/Build Plan V2/Evidence/B25/b25-iteration-scorecard-b25-v4-pass-34.md`
  records `B25 can pass=false` and `4` remaining blocking/major groups. The next-pass remediation
  planner generated `docs/Build Plan V2/Evidence/B25/b25-remediation-plan-b25-v4-pass-35.md` with
  `9` tickets and `3` remediation batches. The loop is still converging because remaining major groups
  dropped from pass 33's `5` to pass 34's `4`, but pass 35 must fix the remaining contrast/action-shell
  and lifecycle-result issues.
- **Evidence/tooling commit, v4 pass 34:** `2289ee3`.

- **Execution record, v4 pass 35:** Consumed
  `docs/Build Plan V2/Evidence/B25/b25-remediation-plan-b25-v4-pass-35.md`. Implementation commits
  `44f581b` and `39250b4` replaced the remaining repeated light action shells with darker
  full-screen domain action surfaces, repaired action text contrast, added persistent result-state copy
  for the six failing lifecycle workflows, added ad-off price/amount proof, and added protected
  youth/guardian/coach proof to the export redaction surfaces. Full B12-B20 screenshot capture passed
  with `201` screenshots, `66` workflows, and `9` workflow manifests on `emulator-5554`; capture
  coverage passed; the B25 collector generated `198` schema v4 screen rows for `b25-v4-pass-35`;
  workflow/persona coverage passed `68 / 68`; visual inspection passed `198 / 198`; the deterministic
  independent UX scaffold passed with `0` findings and `68 / 68` workflow/persona scorecards; fresh
  LLM Product Docs reconciliation passed; fresh LLM Vision UX review passed freshness and imported
  `198` screen reviews; the semantic interaction model judge passed `68 / 68` lifecycle scorecards;
  the production UX judge passed; and
  `docs/Build Plan V2/Evidence/B25/b25-iteration-scorecard-b25-v4-pass-35.md` records
  `B25 can pass=true` with `0` blockers, `0` unresolved major findings, and `0` remaining
  blocking/major tickets. Closeout gates
  passed: `flutter analyze apps/loom_communities_demo`, `manifest_gate`, `phase_gate --phase B25
  --check-env`, boundary lint, and scoped `git diff --check` on staged B25 files.
- **Evidence/tooling commit, v4 pass 35:** `940bc2a`.

- **Execution record, v4 pass 41:** Consumed
  `docs/Build Plan V2/Evidence/B25/b25-remediation-plan-b25-v4-pass-41.md` and first repaired the
  B25 capture harness so offscreen action buttons are scrolled into the viewport before tapping.
  Targeted B20 precheck passed, then the commit-eligible full B12-B20 capture passed on
  `emulator-5554` with `207` screenshots, `67` workflows, `9` workflow manifests, and
  `fullB25Coverage=true`. `b25_capture_coverage_gate.dart` passed; the B25 collector generated
  `204` schema v4 screen rows for `b25-v4-pass-41`; workflow/persona coverage passed `69 / 69`;
  visual inspection passed `204 / 204`; the deterministic independent UX scaffold passed with `0`
  findings and `69 / 69` workflow/persona scorecards; and
  `b25_workflow_interaction_model_judge.dart` passed `69 / 69` lifecycle scorecards. The production
  UX judge correctly failed the hardened B25 bar because pass 41 did not reuse stale or shallow LLM
  artifacts and therefore lacked a fresh `llmVisionReview` and a fresh `appShellCapabilityReview`.
  It generated `docs/Build Plan V2/Evidence/B25/b25-remediation-tickets-b25-v4-pass-41.md` with
  `2` open major tickets, and
  `docs/Build Plan V2/Evidence/B25/b25-remediation-plan-b25-v4-pass-42.md` is the next-pass backlog.
  The loop made evidence/tooling progress but B25 remains open until fresh LLM screenshot review and
  app-shell capability review artifacts inspect the current screenshots and pass.
- **Evidence/tooling commit, v4 pass 41:** `915a35a`.


## 8. Live TODO / Next Steps Queue

Added 2026-08-31. This tracker owns the production bar — phase status, the UX evidence matrices, the
judge gates and the per-phase ledger — and had no §8, so items belonging to it had nowhere to live and
accumulated as prose in `TODO.md` instead. That is the mechanism by which the index became a memory.

Flat table, newest-relevant first. Full context for each item belongs in the body of this tracker or
its linked evidence; this section is the queue, and `TODO.md` carries only a one-line rollup pointing
here.

| Status | Tag | Item | Source | Date |
|---|---|---|---|---|
| ⬜ Open | `needs-verification` | **Proving the reminder chain is blocked at instance creation — `checkAccess` refuses a fan who holds the role.** Attempted 2026-08-31 to run create → enable → sweep and prove `deliver_reminder` end to end. `POST /v1/communities/community_cedar_commons_hoa/instances` returns **403 `workflow_create_refused`** for `fan-hoa-member-1`, who **does** hold `hoa-member` in `loom_communities_cedar-commons-hoa` (verified in `group_membership_role`). The path is `_communityGroupIdResolver.resolveGroupId(communityId)` → `_appAccessClient.checkAccess(fanId, appId, permissionId, groupId)`; a mapping failure would return **503**, so the group resolved and it is the permission check that says no. **Two corrections to existing records fell out of this**: the deployed catalog **does** hold create permissions — **13 of 127** — so item 1h's "the catalog holds none of the `.create` ids" is stale; and `app_role` has **no** permissions column and there is no role↔permission join table, because permissions are **derived at runtime** by `ArchetypeResolver` in the App Access service rather than stored per role. So the question is why the derivation does not grant this fan the create permission for `hoa-facility-reservation`. **Also found**: the `reminderEnabled: false` prefill lives in a **renderBindings create action**, i.e. it is applied **app-side** when a member taps the FAB — so every server-side creation path produces an instance the reminder can never be enabled on. That is why the 3 probe instances lack the field. | traced live | 2026-08-31 |
| ⬜ Open | `needs-live-validation` | **The `deliver_reminder` chain is UNPROVEN but every piece is correct — traced end to end 2026-08-31.** I first recorded this as a defect twice and was wrong both times; the trace is worth keeping because each layer checked out. **Package**: `hoa-facility-reservation` declares `reminder: {anchorDateField: eventDate, anchorTimeField: eventTime, leadHours: 24, enabledField: reminderEnabled}`, and its create transition **prefills `reminderEnabled: false`** (line 1238), so the enable path is reachable. **Engine**: `enable-reservation-reminder` (`action: set_reminder`, `from: [reserved]`) is guarded on `reminderEnabled == false`; `guard_evaluator.dart:57` reads the raw key, so absent ≠ false — correct given the prefill exists. `dueNotifications` deliberately handles both computed and stored `dueAt` shapes. **Service**: the endpoint answers 200 and rejects a bad `asOf` with `400 invalid_as_of`. **Stored definitions**: current — 6 carry a reminder key, matching the 6 shipped packages. **Why nothing is ever due**: the only 3 instances in the service are probe artifacts ("Gate probe", "live chain probe") created by direct calls that **bypassed the create prefill**, so they have no `reminderEnabled` at all and the formula yields null. **To prove the chain**: create a reservation through the real create transition, advance it to `reserved`, apply `enable-reservation-reminder`, then sweep. No code change expected. | traced live, no defect found | 2026-08-31 |
| ⬜ Open | `new-ticket` | **DECIDED 2026-08-31 — support BOTH reminder paths; `event-rsvp` gains a third action, `send_reminder`.** User rejected all three options I offered, correctly: I had framed it as a contest over which reading wins, when automatic *and* manual sending are both real product capabilities and the archetype must expose hooks for each. **The vocabulary is now a trio**: `set_reminder` (a member asks to be reminded about their own row), **`send_reminder`** (an organiser or coach sends one *now* — role-guarded, renders a button), `deliver_reminder` (the platform sends on the declared schedule — names no role, renders nothing). **Ids separate them, so the mapping stays unconditional**: `send-reminder`/`send-next-reminder` → `send_reminder`; `deliver-reminder` → `deliver_reminder`. Chess (`chess-organizer`) and Youth Soccer (`soccer-coach`) keep their primary buttons, which the old id-mapping would have deleted. **The automatic hook already exists** and needed nothing: the declarative `reminder` block (`anchorDateField`/`anchorTimeField`/`leadHours`), swept by `dueNotifications({asOf})` — 6 of 10 shipped packages already declare one, which is itself evidence both paths were always in use. `permissions.md` §4 and its prose updated, mirror synced. **Follow-on**: register `send_reminder` in the generated permissions vocabulary and the deployed catalog, and confirm Chess/Soccer resolve to it. | user decision | 2026-08-31 |
| ✅ Closed | `new-ticket` | **`platformSource` rule enforced end to end — docs, Skill and validator (`e9c59e5b`).** Grammar stated in `platform-services.md`; Skill taught by worked example in `solved-patterns.md` §21 (plausible-but-wrong JSON, verified-correct JSON, and the renaming test: *could the platform still write this field if it were renamed?*); §20's overclaim that without a source "nothing can run" corrected, since leaving it would teach the Skill to add markers everywhere. Both `chatgpt-upload` mirrors synced in-commit. Validator narrowed. **Verified independently, not from the agent's report**: judges **484 passed, 0 skipped** by exit status; the finding fires **0 times across all 10 shipped packages**, down from ~55, counted by running the validator over each — with a control confirming the same run still reports Garden Club at `warningCount: 6` and other finding types, so the zero is a real absence and not a broken query. Finding code untouched, so `05-validation.md` needs no edit and the conformance test still passes both ways. **One thing left deliberately visible**: the retained branch is now unreachable — `_requiresGenericPlatformDispatch` is true only when the source *is* `opaqueId`, while the branch also requires it to be null. The implementation documented that rather than hiding it. It is kept so the registered code exists and an explicit dispatch marker has a home; **if none is ever added it should be deleted, not quietly left.** | dispatched, verified independently | 2026-08-31 |
| ⬜ Open | `new-ticket` | **DECIDED 2026-08-31 — `platformSource` is required iff a generic dispatcher resolves the value; today that is `opaqueId` alone.** The question was filed as "what `platformSource` should `checksumVerified` declare", and measuring showed both halves of the framing were wrong. **The field already works**: `workflow_service.dart` writes `false` at bundle creation, then on download recomputes sha256 and compares against the stored checksum **and** byte size before writing the result — the comment records that comparing the hash alone *"would make a replacement or truncation verify unconditionally."* **And it was never one field**: 55 shipped fields are `writableBy: platform` with no source, almost all engine bookkeeping. **What settled it**: `platformSource` has exactly **one** runtime consumer in the entire codebase — `workflow_service.dart:4133`, a generic loop that mints an id for any field declaring `opaqueId` and still empty. That is real and load-bearing: it lets a new community declare an id field and have it minted with zero code change. But **`platformSource: "checksum"` is inert** — the export handler writes `checksum`/`checksumAlgorithm` by literal key name and never reads the marker. So the benefit exists only where a dispatcher must act without knowing field names. **Work**: narrow `platform_writable_field_missing_platform_source` to fire only for dispatched values (the code stays registered, so no `05-validation.md` code-list change); document the rule in `platform-services.md`; **keep `checksum`** as descriptive — it truthfully names the writer, unlike a field claiming a writer it lacks — and say plainly in the docs that it does not dispatch. No package regeneration. | user decision, grounded in runtime measurement | 2026-08-31 |
| ⬜ Open | `new-ticket` | **DECIDED 2026-08-31 — fan-passport is the identity authority; seeding creates the passport first.** User confirmed option (a): call `createFanPassport`, take the **minted `fan_<uuid>`**, and use that id everywhere — Keycloak user attribute, app-access membership, everything downstream. This resolves the 40-vs-8 mismatch at its source rather than back-filling, which the API cannot do anyway since `CreateFanPassportRequest` accepts no `fanId`. **Migration required**, because 40 app-access memberships already reference the old `fan-<community>-<role>` ids and must be re-keyed, not merely supplemented. | user decision | 2026-08-31 |
| ⬜ Open | `new-ticket` | **DECIDED 2026-08-31 — the group↔community mapping moves server-side, returned alongside each group.** User chose option (a). `app_group.external_resource_type`/`external_resource_id` are populated (`community` / `<communityId>`), added to the app-access spec **in both repos** (they are byte-identical twins and nothing else compares them), returned with each group, and the app's compile-time `communityGroupIds` constant in `part40_service_environments.dart` is retired. **Why it was a real question**: the columns exist in `V1__init.sql` and are mapped on `AppGroupEntity` but are read by nothing and appear in **none** of the 50 OpenAPI specs, while the mapping that actually works is compiled into the app — so adding a community needed an app release, and server/app disagreement had no detector. | user decision | 2026-08-31 |
| ⬜ Open | `needs-spec-decision` | **SHARPENED 2026-08-31 — the two services disagree about who owns fan identity, and the documented API cannot reconcile them.** I checked whether this was merely an unrun step, as the workflow-definition publisher once was. It is not. `createFanPassport` exists, but `CreateFanPassportRequest` requires **only `displayName` and does not accept a `fanId`** — fan-passport **mints** the id, which is why its 8 records are `fan_<uuid>` (the lone `fan-test-alice` was inserted by hand). App-access, meanwhile, accepts whatever fan id its caller supplies, which is how 40 memberships came to reference `fan-garden-admin`-style ids. **So the 40 app-access fans cannot be given passports through the documented API at all**, and no amount of back-filling fixes it. The decision is which service is the identity authority: **(a)** seeding creates the passport first and uses the minted `fan_<uuid>` as the app-access fan id everywhere — the reading most consistent with fan-passport being "portable" identity, and my recommendation; **(b)** `createFanPassport` accepts a caller-supplied id, making app-access the authority; **(c)** an explicit mapping table. This blocks the walkthrough: the device signs in successfully and then cannot render community content. | measured against the spec | 2026-08-31 |
| ✅ Closed | `new-ticket` | **`b25-c16` now says "absent", not "failed" — the judge fix landed and is verified (`ab8720f0`).** `_failedAppShellCapabilityChecks` reports three states (passed / explicitly `false` / absent-or-wrong-typed), and the renderer lookup separates "no matching row" from "matched but unproven" — previously both were `MISSING-PROOF`, which is why Messages and Documents reported missing while carrying `screenRowIds`. **Deliberately not made permissive**: accepting `tabs: "pass"` as a fallback was forbidden in the ticket and refused in the implementation, verified by reading the diff, because a judge that accepts two schemas cannot tell a conforming review from a malformed one. Verified against the real pass-42 bundle, not the agent's report: `c16` still fails — correctly, the evidence *is* malformed — but now states *"explicitly reports failed capabilities: none … did not report these capabilities in the documented shape: (tabsPass); (presentationStatesPass) …"*, plus *"Matched renderer rows that remain unproven: none"*. Judges **482 passed, 0 skipped, 0 failures** by exit status (baseline 464; +18 new tests); diff grepped for weakened assertions, none found. | dispatched, verified independently | 2026-08-31 |
| ⬜ Open | `needs-verification` | **`c16`'s remaining work is regenerating the evidence, and it is now legible.** With the judge fixed, the scorecard states plainly that **zero** capabilities failed and that all ten findings are evidence-shape problems: five `ABSENT-OR-WRONG-TYPED` sub-checks and five `NO-MATCHING-ROW` renderer contracts. The producing agent must emit the documented schema — boolean `tabsPass`/`presentationStatesPass`/`mainCommunityCardStatesPass`/`themeCustomizationPass`/`rendererSelectionPass`, and `rendererContractId` with `affectedScreenRowIds`. Passes 36–39 did. **Do not hand-edit the artifact** — that is fabricating evidence; regenerate it. | follows the judge fix | 2026-08-31 |
| ⬜ Open | `new-ticket` | **NEXT BLOCKER, and it is a real integration gap: app-access and fan-passport hold different identity populations.** With auth working, the device now gets past app-access and fails at *"App Access membership for fan `fan-garden-admin` in community `community_garden_club` has no Fan Passport record."* Measured: **app-access has 40 distinct fans** with memberships, named `fan-<community>-<role>` (`fan-garden-admin`, `fan-book-admin`, …); **fan-passport has 8 records**, named `fan_<uuid>` plus the hand-made `fan-test-alice`. The two do not share a naming convention, so the overlap is effectively nil. Keycloak is a third population again — 40 users named `loom-<community>-<role>-<n>`. **The account seeding created Keycloak users and app-access memberships and never created passports**, which nothing checked because no surface had ever read both in one request until now. Fixing it means deciding whether fan-passport records are minted by the membership flow, back-filled, or derived — that is a spec decision, not a script. | measured on device and in the databases | 2026-08-31 |
| ✅ Closed | `new-ticket` | **The post-sign-in 401 was my own `KC_HOSTNAME` fix, and is now closed.** Changing Keycloak's advertised host also changed the `iss` claim on every token, and all three resource servers still validated `JWT_ISSUER=http://localhost:30082/realms/loom` — so every token from a real sign-in was rejected. **Diagnosed in the right order**: the suspicious group id `loom_communities_garden-club` was ruled out first by querying `app_group` (it exists — and the query incidentally confirmed the 24-groups duplication, both hyphenated *and* underscored variants of nearly every community), then the 401 was reproduced **outside the app** with a direct-grant token, which proved it was not an app defect. Fixed all three manifests to `http://192.168.56.10:30082/realms/loom`, rolled out, committed (`79919b2`). `JWT_JWKS_URI` deliberately untouched — it resolves in-cluster DNS and is a fetch, not a claim comparison. **Verified**: app-access returns **200** with real membership (`fan-garden-admin`/`garden-admin`, `fan-garden-coordinator-1`/`garden-coordinator`), workflow-service **200**, fan-passport **403** — which is correct, being the spec-mandated refusal of another fan's data, and is distinguishable from the 401 precisely because it is not one. | reproduced and fixed | 2026-08-31 |
| ✅ Closed | `needs-live-validation` | **ANDROID AUTHENTICATION WORKS END TO END — proven on `emulator-5554` 2026-08-31, after fixing `KC_HOSTNAME`.** Full path driven by hand: Garden Club → entry gate → "Continue to secure sign-in" → `LoomProductionLoginScreen` → Chrome custom tab → the real Keycloak page (LOOM branding, Google and Facebook providers) at `192.168.56.10:30082` → credentials for `loom-garden-member-1` → redirect back to `MainActivity`. **Proof the token was obtained and stored:** logcat shows `FlutterSecureStorage` fsync'ing shared_prefs, and the gate's error changed from `LoomAuthNotLoggedInException: No Loom authentication session is stored` to a **different** failure that only an authenticated caller can reach. This closes "Android cannot obtain a bearer token", which stood for two days and was never true — it was `KC_HOSTNAME` plus a missing build define. | driven on device | 2026-08-31 |
| ⬜ Open | `new-ticket` | **NEXT BLOCKER, newly reachable: app-access returns 401 to the signed-in member.** After a successful sign-in the gate reports *"Bad state: Remote auth request GET `http://192.168.56.10:30080/v1/apps/loom_communities/groups/loom_communities_garden-club/members?limit=100` returned HTTP 401."* Note the group id is **`loom_communities_garden-club`** — an underscored prefix with a hyphenated handle, exactly the mixed spelling CLAUDE.md warns never to derive one form from the other. Three candidate causes, none yet tested: the token's audience/client is not accepted by app-access, the group id does not exist in that spelling, or the member genuinely lacks `community.view`. Distinguish by presenting the same token to app-access directly and by listing the real group ids. | driven on device | 2026-08-31 |
| ⬜ Open | `new-ticket` | **ROOT CAUSE, why no authenticated walkthrough has ever succeeded: Keycloak advertises `localhost` in its discovery document.** `loom-backend/deploy/k8s/keycloak.yaml:97` sets `KC_HOSTNAME: "http://localhost:30082"`, so `GET http://192.168.56.10:30082/realms/loom/.well-known/openid-configuration` returns `"authorization_endpoint":"http://localhost:30082/realms/loom/protocol/openid-connect/auth"`. The app uses `openid_client`'s `Flow.authorizationCodeWithPKCE`, which builds the browser URL from the **discovered** endpoint rather than the configured base — so it correctly reaches Keycloak to discover, then sends Chrome to `localhost:30082`, which on the device is the device. **Observed end to end on `emulator-5554`**: Garden Club → entry gate (`LoomAuthNotLoggedInException`, as designed) → "Continue to secure sign-in" → `LoomProductionLoginScreen` → Chrome custom tab showing **`localhost:30082`** and a blank page. Every step of the app's own flow worked; only the advertised hostname is wrong. Fix is `KC_HOSTNAME: "http://192.168.56.10:30082"`, then re-apply and **commit the manifest** — an uncommitted bump has drifted twice. | driven on device | 2026-08-31 |
| ⬜ Open | `new-ticket` | **UX: the community entry gate shows a raw exception class to members.** Garden Club's gate renders *"LoomAuthNotLoggedInException: No Loom authentication session is stored; login is required."* in red. The state is correct and expected — nobody is signed in — but a member should see "Sign in to continue", not a Dart class name. | driven on device | 2026-08-31 |
| ⬜ Open | `needs-live-validation` | **ROOT CAUSE of the walkthrough blocker: the documented APK build command omits `--dart-define=LOOM_PRELOAD_EXAMPLE_COMMUNITIES=true`.** `main.dart:8` reads it via `bool.fromEnvironment`, which defaults to **false**, so every APK built by CLAUDE.md's command installs clean and then shows *"No communities installed"* permanently. Because both routes to sign-in require an already-open community, that empty state has no login either — which is why it was recorded for two days as "Android cannot obtain a bearer token". `launch_loom_demo_emulators.sh:282` passes the define for `flutter run`, so the app is correct there and only the installed APK is empty. **FIXED AND VERIFIED ON DEVICE 2026-08-31.** CLAUDE.md's command corrected; rebuilt with the flag (294.7s, 193,629,874 bytes vs the previous 166,844,907 — the difference is the bundled packages), transferred byte-identical, installed. The device now shows *"Loaded 10 example communities"* and renders Garden Club, Neighborhood Book Club, Riverside Youth Soccer, Cedar Commons HOA, Masjid Nur and Chess Club, each with its own icon and theme; Garden Club carries "Open community" and "Theme applied" chips. No `FATAL EXCEPTION` in logcat. **The splash screen lasts >12s while preloading — a capture taken too early shows only the Flutter logo**, which invalidated an earlier manual test. Sign-in itself is still unproven; it is now reachable. | root-caused on device | 2026-08-31 |
| ⬜ Open | `new-ticket` | **The walkthrough blocker is that no community is installed on the device — sign-in is only reachable from inside one.** Driven directly on `emulator-5554` 2026-08-31. The app launches to the local-extension home: *"No communities installed — Use Add Community to load a local extension package"*. Traced every route to `LoomProductionLoginScreen` in code and **both require an already-open community**: the `actor-identity-picker-button` that opens the dialog carrying "Sign in securely with Loom…" lives in a community screen's `AppBar` (title `community.displayName`), and `_communityEntryGate` takes `community.extensionId`. So with zero communities installed there is no sign-in path in the UI at all. **This supersedes "Android cannot obtain a bearer token"** — auth is configured and the endpoints are right: `LOOM_ENV` defaults to `dev`, and `dev` points at `192.168.56.10:30082/30083/30080/30081`, the exact endpoints proven reachable from inside the emulator. The walkthrough sequence is therefore: install a package → open it → entry gate → sign in. A tap on "Add Community" produced no visible change and nothing in logcat; **whether the tap missed or the handler no-ops is not yet established** and is the next thing to determine. | driven on device | 2026-08-31 |
| ⬜ Open | `needs-verification` | **The dispatch pipeline was silently broken and is now restored — check this before planning any dispatch.** Five scripts were absent from `data/`: `call_implementation_agent.sh`, `call_live_verification_agent.sh`, `call_skill_authoring_agent.sh`, `call_ux_judge_agent.sh` and `check_spec_parity.sh`. Only `call_root_cause_agent.sh` survived, so **every** agent channel except root-cause was unavailable, and nothing surfaced it: `data/` is gitignored, so `git status` is clean whether the scripts are there or not. Restored byte-identically from the adoption kit `Tools/code/`, which is the documented source, after confirming the kit copies are current rather than the DeepSeek-reverted ones — `call_ux_judge_agent.sh` defaults `MODEL` to `sonnet` and `call_live_verification_agent.sh` to `opus`, both invoking `claude -p`, matching CLAUDE.md's requirement that the UX judge run on a model that accepts images. All five pass `bash -n`. **The general lesson: a missing gitignored tool looks identical to a working one until you invoke it**, and a plan that assumes a dispatch channel exists should verify the script is present first. | direct measurement | 2026-08-31 |
| ⬜ Open | `needs-live-validation` | **The auth path is reachable from inside `emulator-5554`, proven 2026-08-31 with controls.** Keycloak `192.168.56.10:30082/realms/loom` answers **`HTTP/1.1 200 OK`**; app-access `:30080` answers **`401` with `WWW-Authenticate: Bearer`**. Backend healthy at the same moment: k3s active, all six pods `1/1`, load 1.10, and every service returning a live status rather than a connection error. **Method matters here — the first attempt proved nothing.** `adb shell curl` returned "no response" for all three endpoints and the reason was `curl: inaccessible or not found`; the emulator image has `nc` and `ping`, not `curl`. A second attempt then read Keycloak as dead because a bare HTTP/1.0 `GET /` without a `Host` header gets no reply from it. Both were fixed by running a control — a port nothing listens on (`:39999`) returns `Connection refused`, which is distinguishable from a real answer. **What is still unproven: that the app's login flow completes and yields a token.** Network reachability is not a successful sign-in; that needs the UI driven. | direct measurement | 2026-08-31 |
| ⬜ Open | `needs-live-validation` | **Capture-campaign readiness, measured 2026-08-31 — the device half is ready.** `adb devices` reports `emulator-5554` as `device` (the bracketed `pgrep` count of 0 is the known 15-char `comm` truncation, not absence). The installed APK's `lastUpdateTime` is **12:59:07** and the last commit touching `app/` is **`c969a991` at 12:41:23**, so the device carries current code; everything after is docs-only. Android interactive login is **built** (`7a69f845`) but **has never been exercised against the live realm on device** — built is not reachable, and an authenticated capture is the first thing that would prove it. | direct measurement | 2026-08-31 |
| ⬜ Open | `needs-skill-dispatch` | **The 12 "unshippable" B25 rows decomposed 2026-08-31 — only 3 are renames; 9 are not community workflows at all.** Re-derived independently by joining all 79 rows to the 10 shipped packages on `extensionId` (67 matched, 12 did not; the package side parsed to 82 workflow definitions, matching the 82 published). They are four different problems wearing one label: **(a) 5 `wf_`-prefixed evidence rows** — `wf_community-persona-aware-ux` ×2, `wf_demo-app-persona-picker`, `wf_multi-persona-workflow-evidence` ×2 — all carrying Masjid Nur's `extensionId` and product-doc path while describing demo-app persona behaviour, which is why an earlier sweep missed them and reported 7. **(b) 2 Chess app-shell rows**, `chess-local-install-open` and `chess-route-home`, which are shell/routing concerns, not community workflows. **(c) 2 MemberSocialSpace navigation rows**, `platform-connections-entry` and `platform-messages-entry`. **(d) 3 genuine renames where the capability ships under another name**: `garden-tool-loan-giveaway` ships as `garden-tool-loan` + `garden-tool-giveaway`; `platform-message-stream` ships as `platform-message-thread`; `platform-connection-invite` is the `invited` state of `platform-connection`. Only (d) is fixable by renaming rows. (a)–(c) mean the table's unit is not "a community workflow" — the same finding as the ≥15 rows that duplicate another row's decision text. | independent re-derivation | 2026-08-31 |
| ⬜ Open | `needs-verification` | **STALENESS SWEEP OWED on the migrated blocks.** §9's production-readiness and resequencing blocks arrived from TODO.md on 2026-08-31 with **38 open checkboxes intact and unadjudicated**. Several are already known false — the checksum service *was* proven live 2026-08-30, the five rows "blocked on a missing owner/admin identity" were unblocked when eleven admin roles were created, and the "7 rows name a workflow their package does not ship" count was superseded by the 12-row finding. Sweep each against the repo with a control before treating any as current. | TODO.md, migrated | 2026-08-31 |
| ⬜ Open | `needs-spec-decision` | **`permissions.md` §4 and §6 contradict each other and §4 is hard-locked** — blocks item 1l (the generated permissions vocabulary is missing `.create` for four bespoke archetypes). Chess and Soccer expose the contradiction. One of the four spec decisions still open. | TODO.md, migrated | 2026-08-31 |
| ⬜ Open | `new-ticket` | **The live cluster holds state that exists nowhere in git** — `test-fan-alice`/`test-fan-bob` and their `fanId` attributes were created by hand. A cluster rebuild loses them silently and every walkthrough that depends on them fails for a reason nothing records. | TODO.md, migrated | 2026-08-31 |
| ⬜ Open | `new-ticket` | **Pre-GA credential debt, in one place**: test credentials committed in plaintext (`loom_auth_session_live_test.dart`), a JWT crossing the dev link in cleartext under an Android cleartext exemption that must not ship, and 35 seeded accounts sharing `LoomTest123!`. | TODO.md, migrated | 2026-08-31 |
| ⬜ Open | `needs-decision` | **Six fakes back 53 distinct platform APIs and the cluster runs five services.** Retiring `LocalWorkflowEngineApi`/`LocalAuthApi` is *building* a remote auth API, not wiring one — the scope was corrected twice and still needs a decision on which of the 53 are in scope. | TODO.md, migrated | 2026-08-31 |
| ⬜ Open | `needs-debug-agent` | **Garden walkthrough stall** — unfixed, reproducing on both hosts, fails in ~4 min with a diagnostic. | TODO.md, migrated | 2026-08-31 |
| ⬜ Open | `new-milestone` | **Platform phases A, A.1, B, C, D, E, G.4 remain**, with Phase E gated on the two permission vocabularies that do not meet (`community.surface.navigation.*` vs `community.manage_settings`). | TODO.md, migrated | 2026-08-31 |
| ⬜ Open | `new-ticket` | **`b25-c16` — fully root-caused 2026-08-31: all 10 blocking findings are key-name deviations, and the documented schema is correct.** `Tools/b25-product-doc-workflow-reconciliation-llm-gate.md` specifies the shape exactly; the pass-42 artifact deviates from it in three places. **(1)** `communityResults[]` supplies strings `tabs`/`presentationStates`/`communityListStates`/`themeCustomization`/`rendererSelection` where the judge reads booleans `tabsPass`/`presentationStatesPass`/`mainCommunityCardStatesPass`/`themeCustomizationPass`/`rendererSelectionPass` → 5 false sub-check failures. **(2)** `tabRendererResults[]` supplies `rendererContract` where the judge keys on `rendererContractId ?? contractId ?? renderer`; nothing matches, the empty keys are dropped by `..remove()`, the lookup map is **empty**, and all 5 required contracts report MISSING-PROOF *regardless of content* — which is why Messages and Documents reported missing while carrying `screenRowIds`. **(3)** rows use `screenRowIds` where the proof check reads `affectedScreenRowIds`/`screenshotHashes`/`affectedScreenshotHashes`. **Not one of the 10 findings is evidence of an app defect.** After correcting key names, 3 genuine gaps remain: Calendar, Marketplace and WorkflowStatus carry no screenshot ids at all. Passes 36–39 emitted the documented schema; only the canonical pass-42 bundle does not. | judge contract vs pass-42 artifact | 2026-08-31 |
| ⬜ Open | `needs-live-validation` | **`b25-c14` — measured 2026-08-31, and the artifact is ~97% scaffold.** `llm-vision-ux-review-b25-v4-pass-42.json` exists (53 KB, `status: pass`, 204 `screenReviews`), so "the judge was never run" is wrong as stated — but of those 204 entries only **7** carry `visibleEvidence` and **7** carry `critique`; **zero** carry per-screen direct-question answers. The rest are `{rowId, verdict: pass, findings: []}`. No real vision judge inspected 197 of the 204 screens. | pass-42 scorecard, re-measured | 2026-08-31 |
| ⬜ Open | `needs-decision` | Data Portability's **9** rows share one identical expected decision; decides whether the 79 denominator is honest | row-duplication analysis | 2026-08-31 |
| ⬜ Open | `needs-decision` | Masjid's 3 `wf_*` persona/UX rows are not workflows — are they B25 rows at all? | row-duplication analysis | 2026-08-31 |
| ⬜ Open | `needs-skill-dispatch` | Chess: strike the 2 duplicate rows (`chess-local-install-open`, `chess-route-home`); keep `chess-match-result` | row-duplication analysis | 2026-08-31 |
| ⬜ Open | `needs-skill-dispatch` | Social Space: re-point 4 rows at `platform-message-thread` / `platform-connection` with decisions that differ | row-duplication analysis | 2026-08-31 |
| ⬜ Open | `needs-skill-dispatch` | Garden: split `garden-tool-loan-giveaway` into the two shipped workflows | row-duplication analysis | 2026-08-31 |
| ⬜ Open | `needs-verification` | The 3 proven Camera Club rows carry no package identity and classify as `unknown`; re-prove or accept deliberately | evidence-provenance model | 2026-08-31 |
| ⬜ Open | `needs-live-validation` | Five rows unblocked by account seeding are runnable and unrun — the natural first walkthrough target | account seeding | 2026-08-31 |

**Tag taxonomy** is the fixed set in `Tools/reference-tracker-template.md` §8. Do not invent tags here.

---

## 9. Production bar and device history — 2026-08-30 → 2026-08-31

*Migrated from `TODO.md` on 2026-08-31, when TODO.md was restored to being an index rather than a
memory. Twelve dated entries recording how the production bar actually stands: the membership
blocker, getting the app onto a device and reaching the live backend, the legacy-fallback render,
the Android sign-in dead end, and the three ways the B25 measurement itself turned out to be
unreliable — an overstated denominator, a numerator that records no package identity, and a row
unit that duplicates decision text across communities.*

*Entries are never rewritten after the day they were written; the §8 queue carries current state.*

### 2026-08-30 — BLOCKER FOR THE PRODUCTION BAR: ten of eleven communities have no members

Measured against the live cluster while trying to exercise B1's item queue end to end.

**Of the 11 groups the live mapping targets, exactly ONE has a member:**

| Group | Mapped? | Members |
|---|---|---|
| `loom_communities_cedar-commons-hoa` | **yes** | `fan-test-alice` |
| `loom_communities_cedar_commons_hoa` | no | `fan_alice`, `fan_bob` |
| 2 × `loom_communities_b3-e2e-*` | no | 1 each (my own test residue) |
| **the other 10 mapped groups** | yes | **none** |

**This blocks the stated production bar**, which is every product-doc workflow verified by live
walkthrough and UX judge across the B25 addendum's 79 rows. You cannot walk through a community
nobody can join. Nine of the ten communities are unreachable by any identity that exists.

It also makes several shipped features unexercisable rather than unproven. The item queue is the
clearest case: `join_queue` is declared only in Book Club, Camera Club and Garden, and no fan has
membership in any of them. B1 is wired, deployed and reachable **in code**, and cannot be
demonstrated by a member today.

**I under-called this earlier.** On 2026-08-29 I looked at Cedar's split membership, found five test
fixtures, and recorded it as cleanup — "not a blocker, and I over-escalated it". The narrow claim was
right: no real user data is at risk. The conclusion was wrong. The split is the visible edge of
membership data barely existing at all, and that is a blocker for the completion gate rather than
tidying.

- [x] `RESOLVED 2026-08-31` — **who creates community membership, and for whom.** Seeding test identities
  into the ten empty mapped groups is a data operation against App Access, and it decides what a
  "member" is for every future walkthrough and capture. Options: seed a per-community test fan set;
  put one identity in every community; or drive membership through the real join flow if one exists.
  I did not pick one, because it determines what every subsequent live verification actually proves.

- [ ] `new-ticket` — delete the two `loom_communities_b3-e2e-*` groups and the unmapped duplicate
  spellings once the above is decided; they will otherwise be read as product data.


### 2026-08-30 — the emulator reaches the live backend; the APK build is blocked on a Windows setting

**Reachability is proven, and that is the half that was in doubt.** From inside `emulator-5554`:

    ping 192.168.56.10          -> 2/2 packets, 0% loss
    nc  192.168.56.10 30083     -> HTTP/1.0 200 OK, "x-powered-by: Dart with package:shelf"
    nc  192.168.56.10 30082     -> open (keycloak)

So an Android build on this host can reach the k3s services over the host-only network.

**And the three backend dart-defines are no longer needed.** `LOOM_ENV` defaults to `dev`, and the
`dev` environment already carries every endpoint — auth `:30082`, workflow service `:30083`,
app-access `:30080`, fan-passport `:30081` — plus the full community-to-group map. A plain debug
build targets the deployed stack. Only `LOOM_OFFLINE_REPLICA_DIRECTORY` still needs one, to switch
offline browse on.

- [x] `CLOSED 2026-08-31 — the restriction is Windows-only and the VM builds it; NOT a user action` — ~~`needs-user-action`~~ **`flutter build apk` fails: "Building with plugins requires symlink
  support. Please enable Developer Mode in your system settings."** This needs Windows Developer Mode
  (`start ms-settings:developers`), which this session cannot set.

  **Do not fall back to the APKs already in `build/app/outputs/flutter-apk/`.** They are dated
  **Aug 11 and Aug 9** and predate the entire backend build-out: the probes, the row locking, the
  minting, the change feed, the document versioning and both of today's fixes. Installing one and
  exercising it would reproduce this project's most expensive recurring mistake — verifying against a
  proxy rather than the artifact that actually executes, which has already happened four times.

  Until it builds, the app-side chain is verified only as far as: the code wires it, the emulator can
  reach the services, and the services answer correctly to direct calls.


### 2026-08-30 — the app runs on device from today's build; no backend call yet

Built on the **VM** to sidestep the Windows Developer Mode blocker (Linux has no symlink
restriction), copied over, installed on `emulator-5554`. Everything below is a **fresh artifact from
current `main`** -- deliberately not the Aug 11 APK sitting in the output directory, which predates
the entire backend build-out and would have made a device test look successful while proving nothing.

**What is proven:**

- the APK builds (VM, Flutter 3.41.7, Java 21 -- 194 MB with communities bundled)
- it installs and launches; Flutter loads, no crash, no cleartext rejection
- `LOOM_PRELOAD_EXAMPLE_COMMUNITIES=true` loads **10 example communities**, themes applied
- Cedar Commons HOA opens with its theme, `HOA Board` and its 2 roles, Home/Messages, and the home
  surface's 4 sections -- all rendered from the local package
- the emulator can reach the deployed services: `ping` 2/2, and raw `nc` to `192.168.56.10:30083`
  returns `HTTP/1.0 200 OK`, `x-powered-by: Dart with package:shelf`
- the build **is** configured for the real backend. `configureLoomRemoteServicesFromEnvironment`
  falls back to the named environment when no define is present -- "When no define is present the
  environment is used" -- and `LOOM_ENV` defaults to `dev`. The three backend dart-defines are
  genuinely unnecessary; only `LOOM_OFFLINE_REPLICA_DIRECTORY` is.

**What is NOT proven, and must not be claimed:** the app has made **zero** calls to
`192.168.56.10`. Everything on screen is package content. Two reasons, and they are separable:

1. no authenticated session exists, so `RemoteWorkflowEngineApi` has no bearer token
2. nothing navigated to a surface that lists workflow *instances*, which is what would fetch

- [ ] `new-ticket` — **drive the app to an authenticated instance fetch on device.** The path exists
  in code; I could not drive it blind through the UI. Entry points, for whoever does the walkthrough:

  | Where | What |
  |---|---|
  | `part38_production_login_screen.dart` | `LoomProductionLoginScreen` — the real Keycloak login |
  | `part01_local_extension_screen.dart:1088` | menu item `_production-login`, **gated on `productionAuthSession != null`** |
  | `part01_local_extension_screen.dart:1090` | menu item `_sign-in-specific-person` → `LoomAuthScreen` |
  | `part01_local_extension_screen.dart:347` | the `community-entry-gate` Scaffold, which embeds `LoomAuthScreen` |

  Auth resolves to the **remote** implementation: `configureLoomRemoteServicesFromEnvironment` sets
  `_loomRemoteServiceConfiguration` (part37:181), and `resolveLoomAuthApiForCommunity` returns
  `RemoteLoomAuthApi` whenever that is non-null. So a sign-in on device would hit Keycloak at
  `192.168.56.10:30082` rather than the local fake.

  What I could not establish: why opening Cedar bypassed the entry gate, and which control opens the
  identity menu — tapping the header identity icon and the roles card both did nothing. That is UI
  archaeology better done by someone who can see the widget tree, not by tapping coordinates.

  Original note follows: tapping the identity icon on the community screen changed nothing, and no
  login prompt appeared at any point in this build. Until a member session exists on the device, the app-side link
  is verified only as far as "configured correctly and able to reach the services", which is short of
  the walkthrough the production bar asks for.


### 2026-08-30 — the device run rendered a LEGACY FALLBACK, and Android cannot sign in at all

Root-cause investigation of "the entry gate never appeared". Both findings are defects, both cited.

**1. What I saw on the emulator was not Cedar's real package.** `LOOM_PRELOAD_EXAMPLE_COMMUNITIES`
creates the ten cards as **metadata-only** `LocalInstalledCommunity` objects with an empty
`experienceConfiguration`. `_experienceFromConfiguration` therefore returns null, the community is
classified **legacy** (`part01_local_extension_screen.dart:243-246`), and
`_refreshCommunityEntryGate` sets `_communityEntryAllowed = true` and returns **before**
synchronising authorization or listing accounts (`:274-290`). `build` then renders community content
whenever the schema is legacy, independently of the gate (`:1188-1209`).

So the theme, the "HOA Board / 2 roles" card and the four home sections came from a **shallow
fallback**, not the engine-native package — which is also why there were zero network calls: the
legacy return happens before `_ensureEngineAuthorizationSync`.

**My report two ticks ago that "Cedar opens with its theme, roles and surfaces" was therefore
describing a fallback rendering.** It looked exactly like success. This is the verify-against-the-
artifact-that-executes trap in a new costume: the artifact was fresh and correct, and the *fixture
path* was the fake.

**2. There is no Android production login.** `LoomProductionLoginScreen` calls
`completeInteractiveLogin` / `loginInteractively` (`part38_production_login_screen.dart:33-75`), and
the non-web `InteractiveLoginPlatform` throws
`UnsupportedError("Interactive Loom login is currently supported only on Flutter Web.")`
(`loom_auth_session/lib/src/interactive_login_stub.dart:5-24`). The screen catches it and shows an
unsupported state.

**A member cannot obtain a bearer token on Android at all.** The navigation path exists; the
implementation does not.

**Independently verified, because this claim invalidates a plan rather than blocking a step.** The
selection is a Dart conditional import — `loom_auth_session.dart:8` reads
`if (dart.library.js_interop) 'interactive_login_web.dart'`, so the **stub is the default** and the
web implementation is chosen only where `js_interop` exists. Android has none, so it gets the stub,
where `start()` and `complete()` both return `Future.error(UnsupportedError(...))`. The package
contains exactly three files — `interactive_authorization.dart`, `interactive_login_stub.dart`,
`interactive_login_web.dart` — and **no Android implementation**. That conditional was the one thing
that could have made the report wrong, which is why it was worth checking rather than accepting.

- [ ] `new-ticket` — **preload must install the full bundled packages**, so a preloaded community
  carries its canonical `communityId`, `specVersion`, `appShellConfiguration` and non-empty
  `workflowDefinitions`, and the existing gate runs.
- [ ] `new-ticket` — **fail closed**: when remote services are configured and a preloaded community
  reaches `LocalExtensionScreen` with an empty or legacy experience, error naming the community
  rather than silently rendering non-authoritative content.
- [x] `RESOLVED 2026-08-31` — **Android interactive login is unimplemented.** An Authorization Code +
  PKCE flow is required before any Android live walkthrough is possible. Until then the B25
  completion gate cannot be met on Android by any means, regardless of membership.


### 2026-08-30 — NO authenticated walkthrough is possible on ANY platform today

Both targets are blocked, for unrelated reasons, and neither was known before today.

| Platform | Blocker |
|---|---|
| **Android** | Interactive login is unimplemented. `loom_auth_session.dart:8` selects `interactive_login_web.dart` only `if (dart.library.js_interop)`, so Android gets the stub, whose `start()` and `complete()` both return `UnsupportedError`. No Android implementation exists in the package. |
| **Web** | The app **does not compile**. `loom_workflow_engine/lib/src/store/database.dart:3` imports `dart:ffi` unconditionally (and `dart:io` beside it) for sqlite3, reached via `main.dart -> loom_communities_demo -> loom_communities_app_shell -> loom_workflow_engine`. `flutter build web --release` fails. |

**I proposed web as the way around Android and was wrong.** `interactive_login_web.dart` is a real
203-line implementation, the demo app has a `web/` directory, and it looked like a clean path. It
does not build, and nothing in the repo suggests a web build has ever been attempted — the `web/`
directory is Flutter scaffolding. Building it rather than recommending it is the only reason this
was caught in one tick instead of becoming a plan.

**Consequence for the production bar.** The completion gate is every product-doc workflow verified by
live walkthrough and UX judge. That requires an authenticated member session, and there is currently
**no platform on which one can be obtained**. This is upstream of the membership blocker: even with
all ten communities populated, nobody could sign in to walk them.

- [x] `RESOLVED 2026-08-31` — **pick the platform to unblock.** Scoped 2026-08-30, and **Android is
  smaller than "implement OAuth" suggests** — my earlier "neither is small" overstated it.

  **The protocol is already done and platform-neutral.** `interactive_authorization.dart` is 80
  lines importing only `dart:convert`, `dart:math`, `crypto` and `openid_client`: PKCE verifier
  generation, the RFC 7636 `S256` challenge, the authorization URI, and callback-state validation.
  The token exchange in the web implementation is ordinary `http` and reusable as-is.

  What the web layer adds that is genuinely platform-specific is only six things
  (`interactive_login_web.dart`): store the transaction in `sessionStorage`, set
  `window.location.href`, read the callback from the URL, clear storage, and `history.replaceState`
  to tidy the address bar.

  **Android equivalents:** persist the transaction (the app already uses `FlutterSecureStorage` for
  tokens), launch the authorization URI in a Custom Tab or browser, and **capture the redirect** via
  an app link or custom scheme — that last one is the only genuinely new piece, and it needs an
  `AndroidManifest` intent filter plus the redirect URI registered on the `loom-test-client` Keycloak
  client. Roughly a mirror of the ~200-line web file with the storage and redirect halves swapped.

  **Web, by contrast, needs the engine restructured**: `dart:ffi` and `dart:io` are unconditional in
  `store/database.dart`, so it needs conditional imports and a web-compatible drift backend
  (sqlite3 wasm/IndexedDB) — a change to the engine every platform shares, to reach a target nothing
  in this repo has ever built.

  On this evidence Android is both the smaller job and the one the capture apparatus already targets.
  Recorded as a recommendation, not a decision taken.


### 2026-08-30 — both findings confirmed ON DEVICE, with the fix in place

Rebuilt with the preload fix (`60c94aa7`), clean-installed, and driven by hand. Two predictions were
stated before the run and both held.

**1. The preload fix works.** The community descriptions changed on the home screen — Garden Club
went from "Coordinate garden events and plant exchange requests" (the stale alias catalogue) to
"RSVP to seasonal garden events, share plants and tools…" (the real package). Cedar, Youth Soccer,
Masjid Nur and Chess changed too.

Opening Cedar now shows the **entry gate** instead of silently rendering content:

> Welcome to Loom — Choose an account below or create a new one.
> `LoomAuthNotLoggedInException: No Loom authentication session is stored; login is required.`
> Choose an active account or create one to continue to **Cedar Commons HOA**.

Cedar resolves as engine-native, the gate runs, and authentication is demanded. Exactly the
behaviour the fallback was hiding.

**2. Android sign-in is unimplemented, in the app's own words.** "Continue to secure sign-in" leads
to:

> **Secure sign-in is not supported on this platform yet**
> Interactive identity-provider sign-in is currently available only in Loom on the web.

The static finding is now demonstrated on the artifact that executes. Zero backend calls throughout,
as expected: no session can be obtained, so nothing can be fetched.

**An ANR appeared mid-run** — "Digital Wellbeing isn't responding" — a system dialog unrelated to the
app, overlaying the frame. Detected via `dumpsys window` on the device rather than by anything
Flutter-side, which is why that rule exists: a Flutter text guard cannot see a system window, and a
capture taken during it would have been silently corrupt.


### 2026-08-31 — walkthrough evidence records no package identity, so nothing can tell when it goes stale

Noticed while asking whether today's eleven package edits invalidated the three proven Camera Club
rows. The answer is "probably not", and the more useful finding is that **nothing in the evidence
model could tell us either way**.

`Evidence/B25/phase-a-legacy/manifest.json` records `communityName`, `slug`, `phase`, `runId`, `dir`
and `screenshotCount`. It records **no package hash, no `specVersion`, no provenance entry** — nothing
that identifies *which build of the package* the walkthrough proved.

**Why that matters more than today's specific change.** `docs/references/_meta/community-provenance.json`
exists and is regenerated on every package install, so the project already tracks package identity —
it simply is not carried into the evidence a walkthrough produces. The consequence is that a row
proven in August and a row proven against a package regenerated afterwards look identical in the
record, and the standing rule that "only a committed manifest is durable" quietly assumes the
manifest is still *about* the current package.

**For today specifically:** the change was an additive `experience.notifications` block. It touches no
state, transition, binding, guard or seed, so the three Camera Club rows are very unlikely to have
been invalidated. But "very unlikely" is a judgement I made by reading the diff, not something the
evidence records or any check enforces — which is exactly the kind of gap that turns into a false
"proven" later.


**Applied to the existing evidence 2026-08-31, and it changes the numerator too.** The B25 manifest
contains **0** occurrences of `packageProvenance` against **10** for `screenshotCount` — the control
confirms the field is genuinely absent rather than the query being wrong.

So under the model just shipped (`f809e9a4`), the three "proven" Camera Club rows classify as
**`unknown`** — not current, not stale. Nobody can say whether they were proven against the packages
now shipped, and "probably fine because the change was additive" is a judgement from reading a diff,
not a record.

**Both halves of "3 of 79" are therefore soft:**

- the **denominator** overstates: 12 rows name workflows their package does not ship, and the
  act-ability blind spot means the true unprovable count is ≥ 12
- the **numerator** is unverifiable: the 3 proven rows carry no package identity, so their status is
  `unknown` rather than `proven-current`

Neither is a reason to re-run them blindly — the additive `experience.notifications` block touches no
state, transition, binding, guard or seed. It is a reason to stop quoting **3 of 79** as though both
numbers were solid. Every capture from now carries its package identity, so this becomes a comparison
rather than an argument.
- [ ] `new-ticket` — carry package provenance into the walkthrough manifest: at minimum the
      `community-provenance.json` entry (or its hash) for each community captured, written at capture
      time. Then a manifest can be compared against the current package and reported as stale rather
      than silently believed
- [ ] until then, treat any row proven before 2026-08-31 as proven against a **different** package
      build than the one now shipped, and say so rather than assuming either way

### 2026-08-31 — the unshippable-row sweep undercounted: 12 rows, not 7

Re-ran the check while the device work was blocked. The recorded finding says **7 rows name a
workflow their package does not ship**. Measured against the shipped packages: it is **12**.

**Method, and the two things that made my first two attempts wrong.** The B25 asset
(`assets/b25_semantic_interaction_models.json`, 79 rows) joins to packages on **`extensionId`, not
`communityId`** — the two id spaces genuinely differ (`community_ad_off` in B25 vs
`community_ad_free_community` in the package), and joining on `communityId` silently drops six of ten
communities. The row's workflow field is **`workflowId`**, not `workflow`. My first run reported "0
rows checked" and my second "32 not shipped"; both were artifacts of those mistakes, not findings.
The run below carries a control — a row known to be shipped (`photo-walk-rsvp`) resolves `True` — so a
zero would mean absent rather than broken.

**The 7 already recorded, all confirmed:**

| Community | Workflow |
| --- | --- |
| Chess Club | `chess-local-install-open`, `chess-route-home` |
| Garden Club | `garden-tool-loan-giveaway` |
| Member Social Space | `platform-messages-entry`, `platform-connections-entry`, `platform-connection-invite`, `platform-message-stream` |

**Five more that were missed, all Masjid Nur:**

| Rows | Workflow id |
| ---: | --- |
| 1 | `wf_demo-app-persona-picker` |
| 2 | `wf_community-persona-aware-ux` |
| 2 | `wf_multi-persona-workflow-evidence` |

Three distinct ids across five rows. **No package anywhere uses a `wf_` prefixed `workflowType`** —
Masjid ships only `mosque-*` — and these ids appear nowhere in the repo except old
`.codex-logs` dispatch prompts. So they are not a second id space that needs mapping; they are rows
naming workflows that do not exist, the same class as the seven.

**Consequence.** 12 of 79 rows cannot be walked as written, so the production bar's denominator is
questionable until they are either corrected in the product docs or struck. That is a larger share
than the recorded 7 implied, and it is worth knowing before anyone measures progress against 79.

- [ ] `needs-skill-dispatch` — the five Masjid rows: correct the product doc's B25 table, or remove
      them if they were never real workflows
- [ ] the original 7 remain as recorded




### 2026-08-31 — the 12 unshippable rows diagnosed, and a worse problem behind them

Analysed the 12 rather than just counting them. **They are not typos, and striking them would delete
real coverage.** Most carry valid content with a wrong workflow id pasted on.

**Chess — 2 rows are duplicates.** `chess-local-install-open`, `chess-route-home` and
`chess-match-result` share **identical** expected-decision text, role and primary actions
(`record match`, `submit score`, `save result`). Only `chess-match-result` is shipped. The other two
are the same row three times with two invented ids.

**Member Social Space — 4 rows, one description, no valid id.** All four share one decision text
("evaluates a concrete message, connection, or invite…") and none names a shipped workflow. The
package ships `platform-message-thread` and `platform-connection`; the rows want re-pointing at them,
not deleting.

**Garden — 1 conflation.** `garden-tool-loan-giveaway` names two shipped workflows joined by a hyphen:
`garden-tool-loan` and `garden-tool-giveaway`.

**Masjid — 3 are not workflows.** `wf_demo-app-persona-picker`, `wf_community-persona-aware-ux`,
`wf_multi-persona-workflow-evidence` describe cross-cutting persona/UX checks ("member confirms their
view hides admin-only actions"), not community workflows. They belong to a different kind of check.

#### The worse problem: rows that are distinct in name only

The same analysis surfaced something not previously recorded. **Data Portability has NINE rows sharing
one identical expected decision and action list** — every `export-*` workflow. All nine are shipped, so
no sweep flags them, but nine rows with the same expected decision are not nine proofs. Cedar has two.

That matters for what "79 rows" means:

| | |
| --- | --- |
| Rows naming a workflow the package does not ship | 12 |
| Rows that duplicate another row's decision text verbatim | at least **15** across 4 groups |
| Rows whose role cannot act on the workflow | unknown — only walkthroughs reveal it |

**79 is a count of table rows, not of distinct provable behaviours.** A bar measured against it can be
satisfied without the coverage it implies.

- [ ] `needs-skill-dispatch` — Chess: strike the 2 duplicate rows, keep `chess-match-result`
- [ ] `needs-skill-dispatch` — Social Space: re-point the 4 rows at `platform-message-thread` and
      `platform-connection`, with decisions that actually differ
- [ ] `needs-skill-dispatch` — Garden: split the conflated row into loan and giveaway
- [ ] `needs-decision` — Masjid's 3 persona/UX rows: are they B25 rows at all, or a separate check?
- [ ] `needs-decision` — Data Portability's 9 identical rows: nine real proofs, or one generic row
      copied nine times? This decides whether the denominator is honest

### 2026-08-31 — what pass-42 actually failed on, and how old it is

The B25 iteration scorecard is the closest thing to a production-readiness verdict, and two things
about it were not being said.

**It is from 2026-07-03.** `b25-iteration-scorecard-b25-v4-pass-42.json` carries
`generatedAt: 2026-07-03T02:23:51Z` — nearly two months old. The B25 judge cycle stopped in early
July. Anyone reading "latest scorecard" was reading a July verdict against an August codebase.

**Its findings table is empty, but the failures are recorded elsewhere.** The iteration scorecard
reports `blockingCriterionFailures: 2` with `blockingFindings: []`, which reads as "2 failures,
unknown". The detail lives in `production-ux-criteria-scorecard.json`, keyed on **`verdict`** (not
`status`, which is what I first filtered on and got a misleading zero):

| Criterion | `blocksPass` | Why |
| --- | --- | --- |
| `b25-c14-llm-vision-ux-review` | true | "The LLM vision UX review is missing holistic answers or screen reviews." **Re-measured 2026-08-31:** the bundle on disk carried `holisticQuestionAnswers: []` and `screenReviews: []` while the review file had them populated, so re-running `b25_llm_ux_review_importer.dart` changes the score from **0 to 20** and the message to "too shallow to prove production UX quality". The import gap is real but it is not the blocker — the review itself is a scaffold, so c14 fails either way. |
| `b25-c16-app-shell-capability-utilization` | true | **Two distinct causes, separated 2026-08-31.** (1) A false failure: the five sub-checks are keyed `tabsPass` etc. as booleans by the judge and supplied as `tabs: "pass"` strings by pass-42, so all five fail regardless of the app. (2) A real gap: 3 of 6 `tabRendererResults[]` (Calendar, Marketplace, WorkflowStatus) carry **empty** `screenRowIds` and `screenshotHashes`, and 5 of 6 fail the documented proof requirement of row ids, hashes, visible text, answers and critique. |

16 of 18 criteria pass; `holisticPass` and `workflowPersonaPass` are both true.

**So the two blockers are different in kind**, and that matters for sequencing:

- **c14 is unrun work**, not a defect. The remedy is to run the UX judge over the screenshot evidence.
  It cannot be run against July screenshots and mean anything — it needs a fresh capture from the
  current build.
- **c16 is a real gap** between what the product docs say the shell does and what the shell does,
  across five capability areas. That is a genuine remediation batch, and the largest single named
  obstacle to the production bar found so far.

- [ ] `new-ticket` — c16: fix the producing agent's schema (boolean `*Pass` keys, not string `"pass"` values), then capture real proof for the Calendar, Marketplace and WorkflowStatus renderer contracts
- [ ] after a fresh capture: rerun the vision judge for c14
- [ ] treat any scorecard without checking `generatedAt` as suspect — this one was two months stale
      and nothing said so

### 2026-08-31 — the production bar is unblocked: device carries current code

The Developer Mode blocker was **incidental, not intrinsic** — see `CLAUDE.md`, "Build the APK on the
VM". Windows restricts plugin symlinks; Linux does not; the VM has a full Android toolchain. Building
there and installing over adb sidesteps the setting entirely.

**State now:**

| | |
| --- | --- |
| APK built at | `c969a991` — includes sync settings, notification gate, mounted replica, acknowledgements view, auth fixes |
| Installed on | `emulator-5554`, replacing the 2026-08-11 build |
| Launch | clean, no `FATAL EXCEPTION` in logcat |
| Accounts | 35 across 11 communities, all seeded through the real approve flow |
| Backends | all live and verified end-to-end |
| Evidence | now records which package build a walkthrough proved |

**Two cautions carried forward into the walkthrough phase:**

- **Rebuild before every capture.** The APK I installed at 15:00 was already stale by 17:00 — it predated
  the settings screen by one commit. The VM build takes ~2–5 minutes with a warm Gradle cache, so
  there is no excuse for walking through code the device does not have.
- **The denominator is not 79.** 12 rows name workflows their package does not ship, and the
  act-ability blind spot means the true unprovable count is ≥ 12. The numerator is also soft: the 3
  proven rows carry no package identity and classify as `unknown` under the model shipped today.

- [x] Developer Mode blocker dissolved
- [ ] first walkthroughs: the five B25 rows the account seeding unblocked are the natural target

### 2026-08-31 — the production bar is blocked on one Windows setting, and the installed APK is three weeks stale

With the backend complete, the next step is proving it on a device. That is blocked, and the two
reasons compound.

**The emulator is fine.** `emulator-5554` is attached and `qemu-system-x86_64` is running on Windows,
so the host half works.

**The installed build is from 2026-08-11.** `com.example.loom_communities_demo` on the emulator
predates essentially all of this effort — no notification gate, no replica mount, no acknowledgements
view, none of the authorization fixes. The only APKs on disk are `app-debug.apk` (2026-08-11) and
`app-release.apk` (2026-08-09).

**A walkthrough against that would prove nothing and look like proof.** It would exercise three-week-
old code while appearing to validate today's integration, which is the same failure family as a
capture that quietly ran against a local engine — the reason `LOOM_ENV` throws on a typo rather than
falling back.

**The rebuild is blocked**, reproducing the 2026-08-30 finding:

    Please enable Developer Mode in your system settings. Run
      start ms-settings:developers

Flutter needs Developer Mode for the symlink support plugins require. It is a system setting, not
something a dispatch or an elevated shell here can set.

- [x] `CLOSED 2026-08-31 — Developer Mode is NOT required; the APK builds on the Linux VM (193,629,874 bytes today) and installs to emulator-5554` — ~~NEEDS THE USER~~: enable Developer Mode on Windows (`start ms-settings:developers`), then the
      APK rebuilds and walkthroughs become possible
- [ ] then rebuild and install before any walkthrough, because the on-device build must not predate
      the code being verified
- [ ] the five newly-runnable B25 rows are the natural first target, since they are the ones today's
      seeding unblocked

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

---

### Production readiness, resequencing, and the bar itself

*Migrated from `TODO.md` on 2026-08-31. The 2026-08-29 production-readiness measurement (probes,
what was actually shipped versus assumed), the 2026-08-25 resequencing decision that put the backend
migration ahead of the production bar, the bar's own definition, and the platform-phase state.*

### PRODUCTION READINESS — measured 2026-08-29, not assumed

- [x] `DONE 2026-08-29` — **liveness and readiness probes**, shipped in `0.9.0` (`c0ce568d`,
  backend `cb7dce7`). `/healthz` returns `{"status":"live"}` and `/readyz` `{"status":"ready"}`,
  both unauthenticated, both registered on the deployment. Liveness deliberately does **not** check
  Postgres: a liveness probe that tracks dependencies makes Kubernetes kill healthy pods during a
  blip, turning a brief outage into a crash loop that outlasts it. Readiness tolerates 300s of cold
  start so it cannot kill the pod mid-migration. Image and probes applied together -- probes against
  `0.8.0`, where `/readyz` was a 404, would have failed readiness permanently. Original note follows.
  **workflow-service has no liveness or readiness probe, and no health endpoint.** `/health`,
  `/healthz`, `/readyz` all `404`. It is the **only** application service without them; app-access,
  fan-passport and keycloak have both, postgres has `pg_isready`. **Four rollouts happened today and
  every one put the pod into service before it had connected to Postgres** — they looked clean only
  because the service wins that race when starting fast. Dispatched.
- [x] `DONE 2026-08-29` — **`LOOM_POSTGRES_DATABASE` default corrected** to `loom_workflow_service`,
  now a single named constant resolved in one place rather than two duplicated literals. Original
  note follows. **`LOOM_POSTGRES_DATABASE` defaults to `loom_app_access`** in both the service entrypoint and
  the publisher CLI, while definitions live in `loom_workflow_service`. Production is correct only
  because the manifest overrides it; a manual publisher run without it hits the wrong database.
  Dispatched with the probes.
- [x] `FIXED 2026-08-29 (`112bec2d`)` — **row-level locking landed; N replicas are now SAFE.**
  `readInstanceForUpdate()` takes `SELECT ... FOR UPDATE` on PostgreSQL; SQLite keeps `BEGIN
  IMMEDIATE` untouched. Proven by a two-connection test that was **demonstrated failing first** (lock
  removed → integration file exits 1, detects the lost update; restored → 4/4, 0 skipped), and
  confirmed to have actually run against real Postgres by watching the pass counter increment across
  it rather than trusting a summary.

  **Scaling is still a separate decision.** This makes replicas safe; it does not run them. Deciding
  `replicas: 2` also wants PodDisruptionBudgets and a rollout strategy.

  **A latent fragility surfaced and is NOT fixed:** the first attempt regressed
  `v3_milestone_phasee_purchase_proposal_test.dart`, and the cause was not semantics. Both
  resolutions chose the same target; the extra resolution simply added latency, and the test's
  **direct read raced the transition's commit** and observed the still-uncommitted row. Resolving
  once removed the added latency, so the window is narrow again — but the race in that test is real
  and a slower machine or a loaded VM can reopen it. If it flakes, it is this, not the locking.

  Original note follows. **Every service runs a single replica, and for workflow-service that is
  currently REQUIRED for correctness — not an oversight.** Measured 2026-08-29.

  The service serialises transitions with an **in-process** `_SerialExecutor`, and says why in its
  own comment: "WorkflowDatabase's transaction boundary uses one externally-owned PostgreSQL
  connection. Keep whole transitions sequential so statements from two HTTP requests cannot
  interleave between BEGIN and COMMIT."

  **That lock does not span pods.** And there is no database-level protection behind it: a grep for
  `FOR UPDATE`, optimistic version checks or row versions returns nothing across both the engine and
  the service (control: the same grep shape finds `BEGIN`, so the query works). `mergeInstanceFields`
  is a read-modify-write inside a transaction —

      final row = await readInstance(instanceId);   // plain SELECT, no FOR UPDATE
      data.addAll(fieldUpdates);
      await updateInstanceState(...);               // writes the whole JSON back

  At Postgres's default READ COMMITTED, two pods doing this concurrently on one instance both read
  the pre-state and the second write **silently clobbers the first**. A lost transition, with no
  error anywhere.

  So `replicas: 2` would trade deploy downtime for silent data loss. **Do not scale this service
  until one of these lands:**

  1. `SELECT ... FOR UPDATE` on the instance row inside the transition transaction — smallest,
     standard, and contained to the engine's write path. **Recommended.**
  2. optimistic concurrency: a version column plus a conditional update that fails and retries
  3. keep one replica deliberately, and accept downtime on every rollout — which is what happens
     today, only by accident rather than decision

  The other services (app-access, fan-passport, keycloak) are Spring Boot with pooled connections
  and are not implicated by this finding; their replica counts are a separate, ordinary question.
- [x] `WRONG, CORRECTED 2026-08-29` — **minio has no liveness probe.** It has both, and always did:
  httpGet `/minio/health/live` (15s delay, 20s period) and `/minio/health/ready` (5s/5s). My audit
  queried `livenessProbe.exec.command`, which only matches exec-style probes, so an httpGet probe
  read as absent. Nothing to do.
- [ ] TLS: a JWT crosses the dev link in plaintext, with an Android cleartext exemption that must not
  outlive it. Already on the pre-GA list; restated here because "production ready" now includes it.




### RESEQUENCED 2026-08-25 — backend migration comes BEFORE the production bar

**User decision.** The live walkthrough and UX judge now run only **after** the app is fully migrated
to the real backends. Every B25 row proven so far was proven against `LocalWorkflowEngineApi`
in-process; switching the app to remote authority afterwards would change the thing those rows were
proven against, so proving them first is wasted work.

Order: **bring k3s up → verify the deployed services → wire the app to the real backends → retire the
fakes in that path → THEN capture and judge.**

- [x] `new-milestone` — **1. Cluster up and verified 2026-08-25. Phases C and D are DONE, not "specified".** `sudo systemctl start k3s` was the entire gap. All five services returned `1/1`: app-access, fan-passport, keycloak, postgres, workflow-service, deployed 6–12 days ago. **Proven end to end**, not inferred: a real fan JWT from Keycloak's `loom-test-client` carrying `fanId: fan-test-alice`, validated by the workflow service, authorised through App Access, reaching Postgres — `GET /v1/communities/{id}/instances` returns `HTTP 200 {"items":[],"pageInfo":{...}}` for camera/chess/ad-off. The service also correctly rejects a missing `X-Loom-Correlation-Id` with `400 invalid_correlation_id`, so its contract is enforced, not permissive
- [x] `new-milestone` — **1c. BLOCKS STEP 2: the deployed workflow service cannot pass any `allowedRoleIds` guard.** Root-caused 2026-08-25, report at [Evidence/backend/publish-guard-root-cause.md](Evidence/backend/publish-guard-root-cause.md). The service authenticates a `fanId` but never resolves and registers that fan's real community role before role-guarded engine calls. Verified directly, not taken on report: `WorkflowRequestIdentity` carries only `fanId` (`identity.dart:11`), and `workflow_service.dart:27` defines `_unresolvedRoleId = 'loom-role-resolution-pending'` — a sentinel that cannot match any package role. The apply-transition route registers no role at all. `AppAccessDecisionClient` returns only a boolean while App Access **already exposes** the answer as `EffectivePermissions.roleIds`; it simply is not plumbed through. **Wire this BEFORE step 2** — otherwise the app gets pointed at a service where no guarded transition can ever succeed, and it would surface much later looking like a product bug. Note the service is `app/packages/core/loom_workflow_service` in THIS repo, not in `loom-backend` **CLOSED 2026-08-25 in `56dd4bce`.** Fixed as specified: one shared resolver at all three sites, `resolveRoleIds` against the deployed `effective-permissions` endpoint, and an EMPTY role set registered on every failure path so a cached engine cannot authorize a later request after a failed resolution. Verified independently rather than from the agent report — the diff removes zero assertions, all three test files are purely additive, and engine went 281 -> 284 passed, exactly the three required tests. App shell held at 273.
- [x] `new-milestone` — **1d. BLOCKS STEP 2 AND 1b: the deployed service's community-to-group map is empty, so it cannot create any instance at all.** Read live from the `workflow-service-config` secret 2026-08-25: `community-group-ids` is literally `{}`. `MapCommunityGroupIdResolver.resolveGroupId` therefore returns null for every community, and `workflow_service.dart:398-415` turns that into a **503 `authorization_service_unavailable` before App Access is ever consulted**. This is the concrete reason every live community holds `"items":[]`, and why 1b could not be run — not missing test data, but a service that cannot create. App Access has exactly **one real community group provisioned** (`loom_communities_cedar_commons_hoa`) plus two throwaway `b3-e2e-*` test groups; the other nine communities have no group at all. **CLOSED 2026-08-26.** All 11 communities installed via `POST /v1/apps/{appId}/community-installations` (`"failures": []`); the map was written from the **server-returned** groupIds — handle-derived and hyphenated, e.g. `loom_communities_cedar-commons-hoa`, NOT the community id — then the deployment was RESTARTED so it re-reads `LOOM_COMMUNITY_GROUP_IDS`, which a secret edit alone does not do to a running pod
- [x] `new-milestone` — **1e. BLOCKS STEP 2: App Access role ids and package role ids are different id spaces, so fixing 1c alone would still deny every guard.** Measured live against the deployed App Access: it holds `cedar_commons_hoa_admin` and `cedar_commons_hoa_member`, while Cedar's shipped package guards name `hoa-board` and `hoa-member`. `board` vs `admin` is not a naming convention, so no normalisation rule can bridge it. **The chosen fix is to provision App Access with the package `roleId` verbatim**, which was checked before being chosen: role ids across all 11 shipped packages contain **zero duplicates**, so package ids are already globally unique and App Access can adopt them as-is with no translation layer to drift. Derive provisioning from the shipped packages — the same script that fills 1d's mapping — rather than hand-creating groups. Had 1c landed alone, roles would have resolved correctly and every guard would still have failed, with a different wrong value. **CLOSED 2026-08-26.** Live roles now carry package-verbatim ids with permissions derived by App Access itself: `hoa-board` 34, `hoa-member` 20, Book Club 57, Soccer 46, Tabletop 37. Chain proven end to end — granting `hoa-board` to `fan-test-alice` moved effective-permissions from `roleIds:[] permissionIds:[]` to `roleIds:['hoa-board'] permissionIds:34`. Note the fix was NOT the client-side provisioner this row anticipated; App Access derives it server-side from submitted inputs (see 1j)
- [x] `needs-verification` — **1f. The engine can hold only ONE role per fan.** `_roleIdByFanId` is a `Map<String,String>` (`local_workflow_engine_api.dart:159`) and `evaluateGuard` compares a single `roleId`, but `EffectivePermissions.roleIds` is a list and a Cedar board member is also a homeowner. Registering resolved roles without widening this would silently drop all but one and deny legitimate actions. Folded into the 1c dispatch as Part 1: `setRolesForFan` with any-match guard semantics, replacing rather than accumulating so a revoked role stops passing **CLOSED 2026-08-25 in `56dd4bce`** as Part 1. `setRolesForFan` replaces the whole set and stores a defensive unmodifiable copy; `evaluateGuard` passes when ANY held role matches, and `.any()` on an empty set is false, so an empty set still fails closed.
- [x] `needs-skill-dispatch` — **1g. Four workflows never say who may create them — a spec gap, not a code gap.** Provisioning needs a `.create` permission per workflow and the packages never state creation authority directly, so the rule was measured across all 95 workflows in all 11 packages 2026-08-25 rather than inferred from one: **84** grant it implicitly (a role-guarded transition leaves `initialState`, and whoever may act on a fresh instance is whoever may create it), **7** need no create permission at all (nothing but a `createInstance` effect produces them — the engine creates them server-side mid-transition, so no App Access create check ever runs), and **4 are genuinely unstated**: CameraClub `critique-submission`, GardenClub `plant-exchange-submission`, MasjidNur `mosque-donation-payment` and `mosque-care-request`. A person creates each of those four, but no package says who may. Provisioning grants all declared roles for them as a stopgap marked `"creationAuthority": "unstated"` so it cannot be mistaken for a decision. **Needs a spec decision first, then a Skill dispatch** — community JSON is authored only by the Skill. Worth noting `critique-submission` is one of the three Camera Club rows already counted as proven: the local engine never consulted App Access, so creation authority was never asked for, which is exactly how this stayed invisible **RETRACTED 2026-08-25 — this finding was wrong.** Packages DO declare creation authority: `permissions.md` step 6 is "For each `create` action's `byRoleIds`, add the archetype's `create` permission", and every shipped package declares `byRoleIds` (2-11 each, 70 corpus-wide) including all four workflows named above. The claim came from measuring transition guards instead of create actions. Note the sweep behind it WAS validated across all 11 packages and all 95 workflows — breadth did not save it, because every reading looked at the same wrong field. Validating a sweep against many cases does not validate its premise; only the spec does. No Skill dispatch needed
- [ ] `new-milestone` — **1h. BLOCKS STEP 2: the App Access permission catalog holds none of the `.create` ids the workflow service enforces.** Found by applying the plan for real 2026-08-25, not by inspection. Groups applied cleanly (**11 created**, Cedar matched rather than duplicated — idempotency held under a live run), then the first role POST returned `400 unknown_permission_id`: "All permission ids must already exist in the app catalog". Measured: catalog **69**, plan needs **65**, overlap only **31**, so **34 are missing** — and those 34 include **every `.create` id** (`payment_checkout.create`, `document_library.create`, `equipment_loan.create`, `export_wizard.create`, `approval_queue_item.create`, `notification_inbox.create`, `search_ai_answer.create`, `status_timeline.create`, `table.create`). `workflow_service.dart:385-415` gates creation on exactly `<prefix>.create`, so **creation could never have been authorised even once roles existed**. Same shape as 1e one layer down — two independently-authored vocabularies (the catalog is `payment_checkout.pay`/`.view`/`.refund`, authored 2026-08-13 apart from the packages) — and resolved the same way, by extending the store to hold what the packages need. The 38 catalog entries the plan never uses are left untouched. Fix dispatched: permissions phase before groups and roles, plus surfacing the HTTP response body, which the applier was discarding and which is why this needed a live probe to diagnose **SUPERSEDED 2026-08-25 by 1j.** The catalog is not writable the way this assumed: `/v1/apps/{appId}/permissions` is GET and PUT only (PUT replaces the WHOLE catalog), and the deployed service answers POST with a 500. More importantly the whole approach was wrong — see 1j
- [ ] `needs-verification` — **1i. Only 55% of transitions declare an `action`, and two packages declare none.** Measured across all 11 packages 2026-08-25 (611 transitions, 337 with an `action`): AdFreeCommunity **0 of 53**, MemberSocialSpace **0 of 27**, ChessClub 26%, MasjidNur 34%, Soccer 44%, Cedar 54%, up to DataPortability at 100%. No functional impact today because the workflow service enforces only `<prefix>.create` and never a per-transition permission — recorded because it is a live trap: if enforcement is ever extended to transitions, those two communities have no derivable permissions at all and would fail closed on every action, reading as a product bug rather than a missing field. Also the reason `ad-off-member` derives a single permission, which looked like a deriver bug and is not
- [x] `new-milestone` — **1j. CLOSES 1d AND 1e THE RIGHT WAY: provision via App Access's own `POST /v1/apps/{appId}/community-installations`, not a client-side reimplementation.** `docs/references/reference/permissions.md` states where the derivation runs: "In the **App Access service**... **Not in the client, and not in the authoring toolchain.**" That endpoint exists and is implemented (`AppAccessController.installCommunityPackage`); one call per community creates the group, registers the roles, derives the permissions and grants them. The caller submits only derivation inputs — `roles[{roleId,label}]` and per workflow `{workflowType, cardSurfaceFamily, createRoleIds, transitions[{transitionId, action, tone, isTerminal, allowedRoleIds}]}` — and gets back `{groupId, rolesRegistered, removedRoleIds, permissionsGranted, rolesWithNoPermissions, findings}`, 422 when findings are non-empty. `groupId` from each result is what fills `LOOM_COMMUNITY_GROUP_IDS`, closing 1d; package-verbatim `roleId`s close 1e. **The lesson worth keeping**: the applier failed three times, each diagnosed correctly and each fix locally reasonable, before I asked whether the work belonged on the other side of the service boundary — the spec had said so all along, in a file already in the repo. When a component keeps hitting walls a service-side API would not have, check the boundary before writing the next fix. Rework dispatched **CLOSED 2026-08-26** — all 11 installed, no failures
- [ ] `needs-verification` — **1k. The deployed permission catalog is out of sync with the generated vocabulary, and is deliberately being left alone.** `docs/references/generated/permissions-vocabulary.json` is authoritative at **97** ids, GENERATED from `archetype_resolver.dart` by `loom_ux_judges/bin/generate_permissions_vocabulary.dart` so the permissions.md rules "exist in exactly one place", and consumed by both the Dart validator and the Java installer. The deployed catalog holds **69**: 26 not in the vocabulary, and **54 vocabulary ids missing**. The backend's own copy of the vocabulary differs from the Loom repo's by exactly one id (`event_rsvp.deliver_reminder`), so a stale file is not the cause — the catalog was seeded from something older than either. Not touched, for a concrete reason: the only write is `PUT` = replace-whole-catalog, so a partial write silently deletes the 26 entries the packages do not use. Needs a decision — reconcile by regenerating and PUTting the full 97, or leave until installations report what they actually need. Watch `rolesWithNoPermissions` and `findings` from 1j's install calls: they are the evidence for which it is **ANSWERED 2026-08-25: reconciled by UNION, not replace.** PUT carried 69 existing preserved byte-for-byte plus 54 vocabulary ids added, **0 deleted** — because replacing with the vocabulary's 97 would have deleted 26 ids the packages do not use, including `community.manage_members`/`invite`/`manage_roles`/`manage_settings`, app-level permissions no archetype derives and one of which an existing role holds. Verified after the write: 127 present, `payment_checkout.create` present, `community.manage_members` still there
- [ ] `new-ticket` — **1l. The generated permissions vocabulary is missing `.create` for four bespoke archetypes that the derivation rule requires.** `permissions.md` step 6 is "For each `create` action's `byRoleIds`, add the archetype's **create** permission", and App Access's own deriver does exactly that — but `docs/references/generated/permissions-vocabulary.json` defines `.create` for all 7 generic archetypes and for bespoke `event-rsvp` and `votePoll`, while **`documentLibrary`, `equipment-loan`, `exportWizard` and `searchAiAnswer` have none**. The shipped packages declare create actions for those families, so the live install failed on `equipment_loan.create` until the id was added to the catalog by hand. These are the same four ids earlier recorded as "invented by the client-side rule" — they were **not** invented; the rule genuinely requires them and the vocabulary omits them. Since the vocabulary is GENERATED from `archetype_resolver.dart` by `loom_ux_judges/bin/generate_permissions_vocabulary.dart` precisely so these rules "exist in exactly one place", the real fix is in the resolver's bespoke action lists, then regenerate. Added to the live catalog as a stopgap (127 ids) so installation could proceed; that stopgap is exactly the kind of second source of truth the generator exists to prevent, so it should not outlive the fix
- [ ] `needs-skill-dispatch` — **1l is BLOCKED ON A SPEC DECISION: `permissions.md` §4 and §6 contradict each other, and §4 is hard-locked.** The dispatch correctly refused to make the change and reported instead of editing a locked document or weakening a test — verified independently rather than taken on its word. **§4** gives `equipment-loan` twelve actions (`view`, `list_item`, `pause_listing`, `delist`, `request`, `decide_request`, `withdraw_request`, `claim`, `join_queue`, `leave_queue`, `take_custody`, `return`) and **no `create`**; same for `documentLibrary` (§4 from line 200), `exportWizard` (224) and `searchAiAnswer` (283). **§6** says "For each `create` action's `byRoleIds`, add the archetype's **create** permission." Both cannot hold: the shipped packages declare create actions with `byRoleIds` for those families, and App Access's own deriver demands `<prefix>.create` — which is why the live install failed until four ids were hand-added to the catalog. **The lock is real and deliberate**: `loom_ux_judges/test/archetype_resolver_spec_sync_test.dart` parses each §4 table and asserts set equality against `ArchetypeResolver.bespokeVocabularies`, so the resolver cannot gain `create` while the document lacks it — the test exists precisely to stop the machine-readable and human-readable definitions drifting. **The decision**: either §4 gains `create` for those four families (making the doc match what the packages and the deployed deriver already do), or §6 / the packages / the deriver are wrong and the four hand-added catalog ids should be removed instead. §4 looks like the incomplete one, but that is a spec judgement, not a dispatch's call. Until it is resolved the four catalog entries stay as a **marked stopgap and a known second source of truth**. Note this is the one blocker of the session that is genuinely a specification question rather than a code or configuration gap
- [ ] `new-ticket` — **1m. CORRECTED 2026-08-29: those App Access groups are NOT orphaned or inert, and members are split across them.** This row said they were leftovers from the superseded client-side applier, inert, worth deleting. Measured in the live database: `loom_communities_cedar-commons-hoa` has **1 member** and `loom_communities_cedar_commons_hoa` has **2** — two group ids for one community, both in use. Deleting either loses real memberships. **So "who belongs to this community" has no correct answer today**, because no query returns both and nothing says they are the same community
- [x] `new-milestone` — **1n. BLOCKS 1b: a column rename shipped without a migration, so no instance can be created against the deployed database.** `POST /instances` returns `500 workflow_service_error` and the service logs **nothing at all**. Root-caused to commit `7449587a`, which renamed the persisted creator column from `created_by_persona_id` to `created_by_fan_id` across the table declaration, inserts, fan queries and row decoding, but added **no forward migration** — and `WorkflowDatabase._migrate` issues only `CREATE TABLE IF NOT EXISTS`, which does nothing to an existing table. Verified directly against the live database rather than from the report: `workflow_instances` still ends in `created_by_persona_id` with no `created_by_fan_id`, so PostgreSQL raises SQLSTATE `42703` at statement preparation. **Why every test missed it**: `WorkflowDatabase.memory()` builds the table fresh from the current declaration so there is nothing to upgrade, and the PostgreSQL integration tests create a fresh temporary schema — so the whole suite exercises the new schema and never an upgrade from the old one. A green suite against a fresh schema says nothing about a database that already exists. Fix dispatched: an idempotent rename guarded on schema metadata, failing startup if BOTH columns exist rather than guessing which holds real data **CLOSED 2026-08-26 in `d97f8bd5`.** Idempotent rename guarded on schema metadata, applied before any instance read or write, failing startup when BOTH columns exist rather than guessing which holds real data. Verified against REAL PostgreSQL in an isolated schema, not only SQLite — and the regression pre-creates the LEGACY table with a row, asserting the pre-existing value survives the rename. Confirmed live: the column renamed itself on first database access after rollout.
- [x] `new-ticket` — **1o. The workflow service cannot report its own failures.** A handled 500 writes no exception, no stack trace and no request line to stdout or stderr: the terminal branch is `catch (_)`, which discards both; `_error` only builds the JSON response; and `bin/loom_workflow_service.dart` passes the handler straight to `shelf_io.serve` with no logging middleware. The correlation id survives only in the response body, so there is nothing to correlate it *to*. This is why 1n needed a live database probe to diagnose at all. Being fixed alongside 1n: log one structured stderr record at the catch boundary — correlation id, method, path, error type, message, stack — while the client-facing response stays byte-identical, and never logging JWTs, request bodies, instance data or credentials. **The client response is not the bug; the silence is.** Worth generalising at GA review: any service that fails closed also has to say why, or a fail-closed path is indistinguishable from an outage **CLOSED 2026-08-26 in `d97f8bd5`.** Each unexpected-500 branch now writes one structured record — correlation id, method, path, error type, message, stack — while the client response stays byte-identical; the test asserts BOTH halves, and that authorization-header and instance-data sentinels are absent. **It paid for itself within the hour**: the very next defect (1b's query failure) was traced from a pod stack trace that, before this, would have gone nowhere.
- [x] `needs-verification` — **1a. Two gate tests now RUN; one fails for real.** Postgres keyset-query test **passes** against live Postgres. Postgres upsert/transition test **fails**: `Bad state: Transition publish is not available for member` at `local_workflow_engine_api.dart:937`, where the fixture declares `publish` `from:["draft"] to:"published"` guarded `allowedRoleIds:["member"]` and the actor IS `member`. **This test may never have passed** — it only runs when `LOOM_POSTGRES_PASSWORD` is set and the cluster has been down. Needs root-cause, not inspection **ROOT-CAUSED 2026-08-25 — the test is wrong, not the engine.** `postgres_database_integration_test.dart` passes `member` as a **fanId** to `applyTransition`, while the fixture guards on `allowedRoleIds: ["member"]` — a **roleId** — and the file never calls `setRoleForFan` or `setRolesForFan` at all. The engine is correct to refuse: `guard_evaluator.dart` states an individual fan id is never treated as a role id, and a role-gated check fails closed when no role is registered. **It cannot ever have passed**: the fixture guard and the fail-closed rule that refuses it landed in the SAME commit `13fb5f49` (2026-08-22), and it went unnoticed for three days because it only runs with `LOOM_POSTGRES_PASSWORD` against a live cluster that was down — so it SKIPPED rather than failed, exactly the trap CLAUDE.md names. Fix is to register the role the engine legitimately requires, never to relax the guard or the fixture. Ticket written, queued behind the provisioning dispatch
- [x] `needs-verification` — **1b. The remote-API live test is unblocked but not yet run.** It needs a creatable workflow type and valid initial instance data in addition to the JWT and community id, and every live community currently holds `"items":[]`. Create an instance via `POST /v1/communities/{id}/instances`, then confirm `queryInstances` returns it — which is exactly what the test asserts **CLOSED 2026-08-26.** The round-trip works end to end against the real stack: `POST /instances` → HTTP 201, `GET /instances` → `items: 2`. Real Keycloak fan JWT → App Access authorization → workflow service → engine → Postgres → back out through visibility filtering. Authorization proven correct in BOTH directions — `hoa-architectural-request` correctly refused (403) for a board member since its `createRoleIds` is `['hoa-member']`, while `hoa-facility-reservation` was permitted. It took four blockers to get here, each invisible until the previous cleared: the empty group map (1d), the stale app-access image, the missing column migration (1n), and a package formula that threw on an absent optional flag (485a092c). Note the second returned instance is one created BEFORE the formula fix — republishing repaired the already-persisted row with no data backfill.
- [ ] `new-ticket` — **the live cluster holds state that exists nowhere in git.** `test-fan-alice`/`test-fan-bob`, their `fanId` attributes, and the realm's `loom-test-client` were created against the running Keycloak — `loom-backend` contains no provisioning script, realm import, or even a mention (`deploy/keycloak/` holds only a Dockerfile). Rebuild the cluster and every live test silently reverts to skipping. Same class as `k3s` being `disabled`: infrastructure that works today and cannot be reconstructed tomorrow
- [ ] `new-ticket` — **test credentials are committed in plaintext**: `loom_auth_session_live_test.dart` carries `test-fan-alice` / `LoomTest123!`. Acceptable for a dev fixture, but it belongs on the pre-GA rotation list alongside the Google, Facebook and DeepSeek secrets
- [x] `new-milestone` — **2. Wire the app to the real backends.** `RemoteWorkflowEngineApi` exists (613 lines, tested) and is **not wired in** — only `part37_remote_auth_session.dart` references it outside tests. Fan Passport and App Access Dart clients already exist in `loom_api_contracts`. This is the largest genuinely-unstarted piece **SEAM LANDED 2026-08-26 in `3527c408`** (+ reset-test restoration `099240d9`). Production selection seam kept SEPARATE from the `@visibleForTesting` override; default stays local so all app-shell tests pass untouched, and the suite moves 273 -> 274. See 2a: this is a seam, not a switch — the app is capable of remote, not yet using it.
- [x] `needs-verification` — **2a. Step 2 landed a SEAM, not a switch: the app uses the real backend only when built with `--dart-define`, and defaults to local otherwise.** `main.dart` calls `configureLoomRemoteServicesFromEnvironment()` and installs the remote factory only when it returns non-null; `part37_remote_auth_session.dart:47-58` reads `LOOM_AUTH_TOKEN_ENDPOINT`, `LOOM_AUTH_CLIENT_ID` and `LOOM_WORKFLOW_SERVICE_BASE_URI` via **`String.fromEnvironment`**, which is **compile-time**, not runtime — so enabling remote means building with `--dart-define=...`, and an unconfigured build silently stays local. That default is deliberate and correct (it is why all 274 app-shell tests pass untouched), but it means **"the app is fully migrated" is not yet true** — it is *capable* of remote, not *using* it. Two consequences: **(1) step 3 is premature** — retiring the local backends would break every unconfigured build, including the whole test suite, so the app must first be proven working against the real backend with the defines supplied; **(2) the B25 captures build the demo APK**, so they must pass the same three defines or they will capture a locally-backed app while believing it is remote — which would silently reproduce exactly the problem the resequencing exists to prevent, since rows would again be proven against the local engine. Also unverified: whether the Android emulator on Windows can reach the workflow service on the VM (`192.168.56.10:30083` host-only, or via a forward) — that is a hard precondition for capture and has never been exercised
- [x] `needs-verification` — **2b. Emulator-to-VM networking WORKS; only the Keycloak leg is unsettled.** Measured 2026-08-26 from the running `emulator-5554` on Windows against the VM's host-only address, which had never been exercised and was 2a's hard precondition for capture. Established: the emulator **pings 192.168.56.10** (2/2 packets, ~42ms); **workflow service :30083 answers `HTTP/1.0 400 Bad Request`** and **app-access :30080 answers `HTTP/1.1 401`** — both real service responses, so TCP and HTTP both traverse. Keycloak **:30082 accepts the TCP connection** (port probe returns OPEN) but returns no HTTP response to `nc`, even at a 30s timeout, while the same endpoint returns `HTTP 200` to Windows `curl`. Since two other JVM services on the same host respond through the identical path, this reads as an `nc` half-close artifact rather than a connectivity failure — **but that is a hypothesis, not a result**, and the emulator image has no `curl` or `wget` to settle it. The decisive test is the real client: build the demo APK with the three `--dart-define`s and see whether it can obtain a token. Do not record capture as unblocked until that happens, and do not record Keycloak as broken on the strength of a `nc` quirk
- [x] `needs-verification` — **2d. The remote-backed APK builds, installs and launches — but the app has NOT been observed using the backend, and that gap is the whole of what remains in step 2.** Measured 2026-08-26. **Proven**: `flutter build apk --debug` succeeds with all three `--dart-define`s; the network security config reaches the **merged** manifest (`android:networkSecurityConfig="@xml/network_security_config"`, verified in `build/app/intermediates/merged_manifest/debug/...`, with no blanket `usesCleartextTraffic`); the APK installs and launches on `emulator-5554` with **zero** cleartext errors, socket exceptions or Flutter exceptions in logcat. **Not proven**: that the app talks to the real backend. Keycloak and workflow-service logs show **no activity at all** in the launch window, which is consistent with the app authenticating only on a user action rather than at startup — so absence of errors here is absence of evidence, not evidence of success. **A failed verification worth recording**: I tried to confirm the defines were baked in by scanning the APK for `192.168.56.10` and got 0 — then ran a control for strings that MUST be present (`cedar`, `loom_communities`, `LOOM_AUTH_CLIENT_ID`) and got 0 for those too. The method is broken (Dart's `kernel_blob.bin` does not yield to `strings` that way), so the original 0 was meaningless. Had the control not been run it would have read as proof the defines never took. **The remaining step is a runtime one**: drive the app to a screen that actually calls the backend — a targeted `flutter drive` with the same three defines — and confirm the request arrives by watching Keycloak and workflow-service logs from the service side, not the app side. Until that lands, step 3 stays blocked and captures must not run. **CLOSED 2026-08-26 — it landed.** Proven on device and cross-checked against Postgres rather than accepted from the client: the app returned `instanceId=community_cedar_commons_hoa_hoa-facility-reservation_3pbmhxf5srqh` with `instanceCount=3`, and both match live `workflow_instances` rows exactly — an in-memory engine cannot fabricate an id created earlier by a direct `POST` to the deployed service. The engine was asserted to be `RemoteWorkflowEngineApi` through the **production** factory, not the `@visibleForTesting` override. Note Keycloak logged nothing in the window and the workflow service has no request-level logging, so the **database cross-check is what carries this**, not a log line. Evidence: [Evidence/backend/step2-proven-on-device.md](Evidence/backend/step2-proven-on-device.md)
- [ ] `new-milestone` — **3. Retire the local backends in that path — SCOPE RESOLVED 2026-08-25.** `LocalWorkflowEngineApi`, `LocalAuthApi`, `LocalInAppBackend`, plus only the six `Community*` fakes the communities app actually touches: `CommunityFoundationFake`, `CommunityRegistryControlPlaneFake`, `CommunityEconomicServicesFake`, `CommunityEngineServicesFake`, `CommunityExperienceServicesFake`, `CommunityOpsServicesFake` — referenced from exactly two files, `test/b1b_publish_discover_install_test.dart` and `test/workflow_test_harness.dart`. **The other ~31 fakes are LEFT ALONE — not ported, not deleted.** They back `loom_demo`, a different app that is not part of the production bar; `FanWalletFake` for instance appears only in `apps/loom_demo/`. Porting 37 Dart fakes into real services was never the plan and is not required by this goal. Revisit only if `loom_demo` itself heads for production **SCOPE CORRECTED 2026-08-25:** read literally this row would break the backend. `LocalWorkflowEngineApi` is constructed in exactly four non-test places, and one is `loom_workflow_service/lib/src/workflow_service.dart` — the deployed service uses it as its own in-process engine, and it is what `RemoteWorkflowEngineApi` ultimately talks to. So retire the APP's two constructions (`part02_tab_shell.dart`, `part25_engine_native_community_store.dart`); the class itself STAYS, because the workflow service is its legitimate remaining consumer.
- [ ] `needs-verification` — **3a. Step 3's scope as written is wrong in three ways, measured 2026-08-26 before dispatching it.** The row claims the six `Community*` fakes are "referenced from exactly two files". They are referenced from **14**: six are the fakes' own definitions in `packages/core/loom_fake_backend/lib/` (one per fake, not consumers), and **eight are test files** — `b1b_publish_discover_install_test` and `workflow_test_harness` as claimed, plus `a1_foundation_components_test`, `a2_registry_control_plane_test`, `a3_experience_services_test`, `a4a_ops_services_test`, `a4b_economic_services_test` and `a5_engine_services_test`, which are **the fakes' own test suites**. Retiring the fakes means retiring those suites too, which is four times the stated blast radius. **Second**: `LocalAuthApi` is not test-only — it is constructed in production at `part01_local_extension_screen.dart:195`, and as a **fallback**: `widget.authApi ?? LocalAuthApi(...)`. That is the same seam shape as the engine factory, so retiring it means **supplying a real auth API as the default**, a migration step, not a deletion. Deleting it outright breaks the local extension screen. **Third**: `LocalInAppBackend` is not in the communities app at all — `class LocalInAppBackend` lives in `packages/core/loom_demo_local_backend/`, and this same row already carves `loom_demo` out of scope ("the other ~31 fakes back `loom_demo` and are LEFT ALONE"). Its only appearance in the app shell is a **documentation string** in `part13_workflow_copy_catalog.dart:456` describing it — copy, not a code dependency. So it is either out of scope by the row's own carve-out, or its retirement is a product-copy change, and those two readings need different work. **Rewrite this row before dispatching it.** The pattern is the same one that made step 2 look like "two construction sites" when one was a private in-memory Messages store: a tracker row written from a plausible reading rather than a measurement, and taken literally it would have deleted production code and six test suites
- [ ] `new-ticket` — **3b. NEEDS A USER DECISION: the six fakes back **53 distinct platform APIs**, and the cluster runs **five** services — so "retire the local backends" is not achievable as written, and the fake-backed share of the production bar is much larger than the four services already agreed.** Measured 2026-08-26 by enumerating every `implements *Api` across the six `Community*Fake` files: 53 distinct APIs including `CommunityWalletApi`, `CommunityMessagingApi`, `CommunityDocumentsApi`, `CommunityModerationApi`, `CommunityNotificationApi`, `CommunitySearchApi`, `CommunityExportApi`, `CommunityAuditApi`, `CommunityRuleEngineApi`, `CommunitySettlementApi`, `CommunityFraudApi`, `CommunityKeyManagementApi` and forty more. Deployed: **app-access, fan-passport, keycloak, postgres, workflow-service**. Only a handful have any plausible counterpart — `CommunityPassportApi` to fan-passport, `CommunityWorkflowApi` to workflow-service, `CommunityMembershipApi`/`CommunityRolePolicyApi` to app-access — leaving roughly **forty-something APIs with no real service to migrate to**. **Why this matters beyond step 3**: item 4 records that four platform services stay fake by user decision (payment, id generation, external search/AI, checksum) and that roughly 22 of the 79 B25 rows must therefore be recorded as proven-against-fakes rather than fully real. That accounting was built on four fakes. With 53 fake-backed APIs the real figure is materially higher, and **the honest number needs recomputing before any row is called production-proven** — otherwise the bar certifies rows against fakes while reading as real, which is the same class of error as capturing with a locally-backed build. **What IS retirable** is what has a real replacement: the app's workflow engine (done in step 2) and `LocalAuthApi` (Keycloak and fan-passport both exist, so it is a migration to a real default rather than a deletion). The rest is not a retirement task at all — it is a decision about how much of the platform stays fake for GA, and it belongs to the user, not to a dispatch
- [ ] `new-ticket` — **3c. CORRECTION to my own 3a note: retiring `LocalAuthApi` is BUILDING a remote auth API, not wiring one — so step 3 has no unblocked sub-item left.** 3a said Keycloak and fan-passport both exist so this was "a migration to a real default rather than a deletion". True in principle, understated in practice: `LocalAuthApi` is the **only** production implementation of `LoomAuthApi` (`part30_local_auth_api.dart:10`); the only other implementation anywhere is `TestActiveAuthApi` in a test helper. There is no remote or HTTP-backed `LoomAuthApi`. So the work is writing one against Keycloak and fan-passport, wiring it as the default behind the same seam pattern the engine now uses, and keeping `LocalAuthApi` available for tests — a substantial build touching authentication, not the wiring job step 2 turned out to be. **Step 3 is therefore fully blocked pending decisions**: the six `Community*` fakes on 3b (53 fake-backed APIs against 5 real services), `LocalInAppBackend` out of scope by the row's own `loom_demo` carve-out or else a product-copy change, and `LocalAuthApi` on whether building a real auth API is in GA scope at all — which is the same question 3b asks, since it is one more of the 53. Recorded rather than scoped into a dispatch, because inventing a large auth build to keep the loop busy would be the wrong call while the underlying question of how much platform stays fake is still open
- [x] `CLOSED 2026-08-31 — the A1 migration restored the index; TODO.md went 2,633 lines to ~280` — ~~`new-ticket`~~ **DEBT I INTRODUCED: this file's own convention says index, and I wrote essays into it.** The header states "This is an index, not a memory. One line per open item... Never write item detail directly here — if you're about to write more than one line for an item, that content belongs in the tracker, not here." Across 2026-08-25/26 I added roughly fifteen backend-migration rows carrying full context, measurements, verbatim service responses and reasoning. The longest is **2,607 characters** against a **~361** median for older rows. The detail belongs in `Access Control and Workflow Service Tracker.md` §8, with one-line pointers here. **Why it was left rather than fixed on the spot**: migrating fifteen dense rows is a mechanical edit with real information-loss risk, and this same file has already absorbed three shell-quoting accidents this session — a NUL byte that made git treat it as binary, and twice backticks expanded as commands, eating an instance id and a class name out of closure text. Doing that migration deliberately, with the file read back afterwards, is worth more than doing it fast at the end of a long session. **Nothing is lost meanwhile** — every row's evidence also exists in `Evidence/backend/*.md`, which is where the durable record actually lives; the cost is a bloated index, not missing information
- [ ] `new-ticket` — **4. THREE platform services stay fake — checksum was pulled out of this list by user decision 2026-08-27** ("we need checksum service built and fully integrated into the app", superseding the 2026-08-25 decision that had grouped it with the others). Still fake: payment processing, ID generation, external search/AI answer. None exist in any form. They back `paymentCheckout` (5 communities), `exportWizard` (6) and `searchAiAnswer` (2), and ~22 of the 79 rows name export/payment/checkout/receipt/search/digest workflows. Those rows will be proven against fakes and must be recorded as such rather than counted as fully real
- [x] `new-milestone` — **4a. THE EXPORT CHECKSUM SERVICE IS BUILT AND INTEGRATED. Closed 2026-08-27.** Five commits: spec `33ecde09`, service `79da87b1`, app client `79784c13`, spec auth fix `2aed5d25`, trigger fix `af77cb29`. What existed before: a contract field, a fake at `community_ops_fake.dart:349` returning `'checksum_<id>_<count>_<r|full>'` that hashed nothing and was reachable only from tests, a `'Verify checksum'` const string in a hardcoded affordance list, no checksum concept in `migration-export-api`, no checksum code in `loom-backend`, and no `crypto` import or `sha256` computation anywhere in the app. Now: `export-bundle-api.openapi.yaml` (4 operations), real SHA-256 over the bytes actually served, MinIO-backed storage reusing `DocumentObjectStore`, and an app client wired to the export surface. **7 of 8 checksum-bearing workflows generate end to end.** Verified from my own shell, not from agent reports: workflow service 75 → 84, app shell 308 → 317, engine 312 and judges 440 unmoved
- [x] `needs-verification` — **the verifier genuinely recomputes.** The failure mode this had to avoid is invisible: a verifier comparing a stored value to itself passes for truncated, replaced or missing bytes and looks identical to a working one in every log. Confirmed by reading the handler — it fetches from object storage, runs `sha256.convert(bytes)` fresh, and compares against both the recorded digest and byte length. The test that would catch the broken version exists: overwrite the stored object with `'tampered bytes'`, assert `verified: false`, `observedChecksum != recorded`, and that the instance still holds the original checksum ("mismatch must preserve evidence")
- [x] `new-ticket` — **the `run`-based authorization model was wrong and is fixed.** I specified `run` for generation by analogy with document `upload`. `run` is generic — Garden uses it for `start-export`, `start-transfer` and `start-import` alike; Book Club only for transfer — and in 6 of 8 workflows the completing transition is `record_outcome` into a state with no `run` available, so the rule would have returned 403 across most of the corpus while looking well specified. The implementation agent refused to build against it rather than shipping a path that reports "unavailable" while appearing integrated. All four export routes now gate on `download`, and generation triggers on entering a download-capable state derived from the machine's own transitions — no state name hardcoded
- [ ] `new-ticket` — **Data Portability `export-checksum-evidence` declares no `download` transition**, so it does not generate a bundle and intentionally was not coded around. It is a verification evidence record for a bundle another workflow produced. If it should instead record a digest from a sibling export, that is a product-doc question for the Skill, not an app change
- [x] `CLOSED — superseded 2026-08-30: "the checksum half proven live too, and one inconsistency found", recorded in ACWS §9` — ~~`needs-verification`~~ **the checksum service has never run against the live cluster.** All proof so far is in-process tests. It needs deploying with the workflow service and exercising against real Postgres + MinIO before any B25 row that names an export counts as proven
- [ ] `new-ticket` — **`CommunityExportFake` still returns its fabricated checksum string.** Nothing in the app reaches it, but it backs `loom_fake_backend` tests. Retiring it belongs with the wider fake-retirement work in step 3, not here
- [ ] `needs-verification` — **5. Only then** capture and judge the 79 rows against the real stack

**Standing rule, user instruction 2026-08-25:** after each implementation cycle, commit and push to
GitHub, then sync the Windows repo. Applies to `loom-backend` as well as `Loom` — backend work lives
in a separate repository this tracker cannot see.

### The production bar — deferred until the migration above completes

- [x] `CLOSED 2026-08-30 — eleven community-scoped admin roles exist (garden-admin, chess-admin, camera-club-admin, …), verified in app_role today` — ~~`needs-skill-dispatch`~~ **5 rows blocked on a missing owner/admin identity: Chess (`chess-export-package`, `chess-pairing-queue`, `chess-rankings-table`) and Book Club (`book-selection-publish`, `book-export-metadata`).** Both ship only Organizer + Member. **CORRECTED 2026-08-24 — the earlier "11 rows" in this row was wrong**: the walkthrough's `_roleIdsForB25Role` already maps `owner` → any identity containing owner/admin/board/coordinator, and `donor` → member, so Cedar (`hoa-board`), Garden (`garden-coordinator`) and Masjid (`mosque-admin`) resolve today and were never blocked. The original cross-check used a naive regex that did not model that mapper — it validated against three *workflow*-missing ground truths and none for roles, so the role half was never checked. `owner` is ratified by the user as a standard platform persona: sets up the community, approves who has access. Note its approval authority is App Access's to enforce, not something package JSON may declare (hard rule 13)
- [ ] `needs-skill-dispatch` — **Ad-Free `ad-off-community-checkout` names the wrong persona.** Its B25 row says `member`, but the doc's own persona table assigns "Fund/sponsor community ad-off" to **Owner**, and the package ships `ad-off-owner`. The walkthrough fails with "could not derive an actionable instance, actorIdentity, and tab ... for B25 product-doc role `member`" — the role exists, it simply cannot act on that workflow. Doc-internal contradiction, same class as Chess; converge through the Skill

**RESOLVED 2026-08-31 — this was fixed and the entry is stale.** The contradiction described no
longer exists anywhere:

| Source | Says |
| --- | --- |
| Product doc B25 table (3 rows, lines 83, 94, 127) | `owner` |
| Generated asset `b25_semantic_interaction_models.json` | `role: owner` |
| Persona table, line 46 | Owner — "Fund community-wide ad-off" |
| Package | ships `ad-off-owner` |

Fixed by `ccdd4136`, *"fix(ad-free): community funding is Owner work — converge the doc's
contradiction in the doc's favour"*. The entry above says the row "says `member`"; it does not, and
has not since that commit. No Skill dispatch is owed.

Worth noting the row is still **not proven** — converging the doc removed the contradiction, it did
not run the walkthrough. It moves from contradictory to runnable, like the five identity-blocked rows.
- [ ] `needs-verification` — **the reachability sweep has a third blind spot, wider than the role half already corrected.** It checks whether a row's workflow and role *exist*, not whether that role can *act* on that workflow. Ad-Free above passes both existence checks and still fails live. So the real unprovable-row count is ≥ the 7 + 5 already recorded, and is only discoverable by running walkthroughs. Do not quote a total from the sweep as if it were complete

**Arithmetic update 2026-08-31.** That entry's "7 + 5 already recorded" no longer holds, in both
directions:

- the **7** unshippable-workflow rows are **12** — five Masjid Nur rows were missed by the sweep,
  verified above with a control
- the **5** rows blocked on a missing owner/admin identity are **0** — every live community now holds
  an identity whose role id matches `owner|admin|board|coordinator`, so the mapper resolves

So the floor is **12 rows that cannot be walked as written**, not 12 from a different pair of causes.
The entry's actual warning is unaffected and still the important part: the sweep checks that a row's
workflow and role *exist*, never that the role can *act* on that workflow, and Ad-Free passes both
existence checks while failing live. **The true unprovable count is ≥ 12 and is only discoverable by
running walkthroughs**, which are themselves blocked on Developer Mode.

Do not quote 79, and do not quote 79 − 12. The first ignores rows that cannot be walked; the second
implies the remainder is provable, which the act-ability blind spot means nobody has established.
- [x] `SUPERSEDED 2026-08-31 — the count is 12, not 7, re-derived independently by joining all 79 rows to the 10 shipped packages on extensionId (67 matched)` — ~~`needs-verification`~~ **7 rows name a workflow their package does not ship**: Chess `chess-local-install-open`/`chess-route-home`, Garden `garden-tool-loan-giveaway`, and Member Social Space's four `platform-*` rows. This half of the reachability sweep stands — it was validated against the Chess walkthrough failure, the B15 manifest's own `productFindings`, and the known Garden mismatch. Method and full list: [Evidence/B25/b25-row-reachability-2026-08-24.md](Evidence/B25/b25-row-reachability-2026-08-24.md)
- [ ] `new-ticket` — **A COMPLETED ACTION CAN LEAVE NO VISIBLE RESULT. Root-caused 2026-08-24** — full report at [Evidence/B25/alternate-action-root-cause.md](Evidence/B25/alternate-action-root-cause.md), read it rather than re-deriving. **CORRECTION: an earlier version of this row called it a harness defect. It is a product rendering defect.** Both alternate transitions land, dispatch and apply; the engine is correct. `critique-submission` binds to `statusTimeline`, which `EngineNativeArchetypeCard` has no case for, so it falls through to `GenericWorkflowInstanceCard` — which never renders `currentState`, so withdrawing only removes buttons. `gear-loan-request` appends to `issueLog`, declared `detail`-context-only, while the walkthrough captures the marketplace tile that filters it out. Two suspects were investigated and **ruled out**: `warnIfMissed: false` hiding a missed tap, and the unchecked third classification path — both still worth hardening, neither causal. Product-rendering fix dispatched; caps what every community can prove, since every row needs an alternate leg
- [ ] `new-ticket` — **the alternate leg proves an ENGINE postcondition, never a VISIBLE one.** `_expectShippedInstanceState` / `_expectShippedInstanceDataChanged` both ran and genuinely passed for the two rows above, so `b25ActionProofStatus: pass` was emitted while nothing a person could see had changed. This is the gap that let a false pass through, and it is deliberately a SEPARATE ticket from the rendering fix — the product and the definition of proof-of-the-product must not move in one dispatch. Require a visible postcondition after the engine one: for `stateChanging`, the target state's declared label visible on the source instance; for `sourceInstanceEffect`, a changed key's rendered value or an explicit acknowledgement, failing loudly with the changed keys and their display contexts if every one is excluded by the active context
- [ ] `needs-live-validation` — **3 of 79 B25 rows proven — Camera Club is COMPLETE** (`photo-walk-rsvp`, `critique-submission`, `gear-loan-request`), walkthrough + UX judge, 2026-08-25, verdict at [Evidence/B25/verdicts/camera-club-b15-ux-verdict-2026-08-25-pass4-PASS.md](Evidence/B25/verdicts/camera-club-b15-ux-verdict-2026-08-25-pass4-PASS.md). It took four judging passes and two fixes — a product one so completed actions render a result, and a capture one so result frames are scrolled to their subject. The judge was told to discard its prior verdicts and re-examined the row it had already passed three times. Soccer's `soccer-team-roster` passes the walkthrough but is **not** judged, so it does not count. Next reachable: Ad-Free (6 rows, B16, persona contradiction now converged), Data Portability (9, B16), Soccer (8, B14) — see [Access Control and Workflow Service Tracker.md §8](Access%20Control%20and%20Workflow%20Service%20Tracker.md)
- [ ] `new-ticket` — **`Borrower/claim count: 0` never increments** even once a gear loan reaches `Status: Requested`. The Camera product doc names borrower/claim count as required visible proof, so an owner scanning that count alone would miss a pending request. Found by the UX judge, non-blocking for the row
- [ ] `new-ticket` — **`critique-submission`'s comment attribution drops the evidence-run identity prefix**, so a comment reads as though a different member wrote it than the one who acted. Found by the UX judge, non-blocking for the row
- [ ] `needs-verification` — **the flagship alternate affordance is displayed but never exercised** on two rows: `Cancel RSVP` for `photo-walk-rsvp` and `Cancel request` for `gear-loan-request`. Both rows pass on a different valid term from their synonym set, which the bar permits — but the most prominent control in each case is unverified by any capture. Worth deciding whether the bar should prefer the flagship path when one exists
- [ ] `needs-debug-agent` — **Garden walkthrough stall**, unfixed and reproducing on both hosts; fails in ~4 min with a diagnostic. The `garden-tool-loan-giveaway` doc/package id mismatch was the trigger; the stall behaviour still needs closing — see [Access Control and Workflow Service Tracker.md §8](Access%20Control%20and%20Workflow%20Service%20Tracker.md)
- [ ] `new-milestone` — 3 of the 6 product defects found by walking real shipped packages remain open — see [Access Control and Workflow Service Tracker.md §8](Access%20Control%20and%20Workflow%20Service%20Tracker.md)

### Platform phases — no backend is in the loop yet

- [ ] `new-milestone` — **Phase A**: engine implements per-person bookkeeping and response-row fan-out. Scope is smaller than the §8 entry's original text: the 6 visibility models **are** now enforced (`local_workflow_engine_api.dart`, `authz_p4a_visibility_filtering_test`), so bookkeeping and fan-out are what remain. Blocks B and F — see [Access Control and Workflow Service Tracker.md §8](Access%20Control%20and%20Workflow%20Service%20Tracker.md)
- [ ] `new-milestone` — **Phase A.1**: `event-rsvp` response rows become canonical; migrates Masjid Nur's `mosque-event-rsvp` and Tabletop's `tournament-event` — see [Access Control and Workflow Service Tracker.md §8](Access%20Control%20and%20Workflow%20Service%20Tracker.md)
- [ ] `new-milestone` — **Phase B**: all 5 workflow-service operations implemented, App Access-authorized and verified live; only k3s deployment remains — see [Access Control and Workflow Service Tracker.md §8](Access%20Control%20and%20Workflow%20Service%20Tracker.md)
- [ ] `new-milestone` — **Phase C**: auth — Keycloak-as-broker (Google/Apple/Facebook), all 3 services as resource servers. Zero JWT/OAuth2 code exists in either Java service today — see [Access Control and Workflow Service Tracker.md §8](Access%20Control%20and%20Workflow%20Service%20Tracker.md) **PARTIAL 2026-08-31:** all three services now validate JWTs against `http://192.168.56.10:30082/realms/loom` — verified live (app-access 200, workflow-service 200, fan-passport 403 on another fan's data, which is the spec-mandated refusal). A real member sign-in completes on device. **Still unproven: the broker half** — Google/Apple/Facebook buttons render on the Keycloak page but no federated login has been exercised.
- [ ] `new-milestone` — **Phase D**: deploy — App Access derivation endpoint, and redeploy both Java services (running images predate their V2 migrations) — see [Access Control and Workflow Service Tracker.md §8](Access%20Control%20and%20Workflow%20Service%20Tracker.md)
- [ ] `new-milestone` — **Phase E**: app shell asks the access authority instead of deriving locally; hide `tabId`s the caller lacks access to — see [Access Control and Workflow Service Tracker.md §8](Access%20Control%20and%20Workflow%20Service%20Tracker.md)
- [ ] `new-milestone` — **Phase G.4**: Ad-Free revert, the last open piece of Phase G (G.1–G.3 done 2026-08-20) — see [Tab Visibility Derivation Spec Proposal.md](Tab%20Visibility%20Derivation%20Spec%20Proposal.md)
- [ ] `needs-verification` — 3 engine tests skip for want of a deployed backend: 2 need `LOOM_POSTGRES_PASSWORD` (k3s PostgreSQL port-forward), 1 needs a real fan JWT plus a live community id. These are the concrete acceptance gate for Phases B/C/D — un-skipping them is how those phases get proven rather than asserted


---

### Decision backlog triaged, 2026-08-31

*Migrated from `TODO.md` on 2026-08-31. Kept because the shape of the finding outlives the specific
questions: twelve of thirteen `needs-decision` items were already answered and had never been struck,
one question was recorded in four separate places, and one was never a decision at all.*

#### Decision backlog triaged 2026-08-31 — 12 of 13 were already answered

Pulled the `needs-decision` list to run through with the user and found most of it stale. Closing
with what resolved each, rather than asking questions that already have answers:

| Item | Resolved by |
| --- | --- |
| who creates community membership | 35 accounts seeded through `requestGroupMembership` → `decideGroupMembership` |
| Android interactive login unimplemented | **built** — `7a69f845` |
| pick the platform to unblock | user chose Android; login built, APK installs, app runs |
| the fix creates a bootstrap problem | **retracted** — `setGroupMembership` never required an existing admin |
| who holds `admin` for each community | eleven `<prefix>-admin` roles + eleven admin accounts |
| who holds `admin` | same |
| which fan id holds `admin` | same |
| who holds `admin` (step 2) | same — this question was recorded **four times** in four places |
| background sync policy | all four policies shipped, member-chosen — `c969a991` |
| OpenAPI twin parity | parity script in both repos + rules — `95192515`, `0561007` |
| the stray app-level `admin` role | deleted through the `deleteRole` endpoint built for it |
| canonical group spelling | **not a decision** — `LOOM_COMMUNITY_GROUP_IDS` already determines it (hyphenated) |

Two things worth keeping from this:

- **The same question was open four times** in four locations, each phrased slightly differently. A
  decision recorded wherever it was encountered, rather than once, inflates the backlog and makes the
  remaining count meaningless.
- **One was never a decision at all.** Canonical group spelling was already determined by deployed
  configuration; asking the user would have been asking them to choose something the system had
  chosen. That is the third time this session I framed a determined fact as a question.


---

### Decision analysis: `platformSource` for `checksumVerified` — and the 55 fields behind it

*Researched 2026-08-31, before putting options to the user. Recorded here so the reasoning survives
the decision.*

**The question is wider than the field it was filed under.** The open item read "what `platformSource`
should `checksumVerified` declare — neither `checksum` nor `opaqueId` fits". Measuring first:

- `_knownPlatformSources` is the closed set `{'checksum', 'opaqueId'}`.
- The validator rule `platform_writable_field_missing_platform_source` is **`isWarning: true`**, and
  says so deliberately: *"intentionally non-fatal while shipped packages use the old grammar;
  regeneration is what closes it."* So nothing is red today.
- **55 fields** across the shipped packages are `writableBy: "platform"` with **no** `platformSource`.
  This is not one field's problem.
- `checksumVerified` **already has a real mechanism**, contrary to how the item was framed.
  `workflow_service.dart` writes `false` when the bundle is created, then on download recomputes
  `sha256` over the bytes and compares against **both** the stored checksum and the byte size before
  writing the result. The inline comment records why both: comparing the hash alone *"would make a
  replacement or truncation verify unconditionally."* A guard consumes it
  (`instanceDataEquals: {key: checksumVerified, value: true}`).

**What the 55 actually are**, sampled: `reminderHistory`, `readFanIds`, `messages`, `waitlistFanIds`,
`signedUpFanIds`, `statusHistory`, `revisionHistory`, `scheduleHistory`, `signupHistory`,
`saveAnswerHistory`, `reportedByFanIds`, `unreadForA`/`unreadForB`, `syncState`, `senderFanId`,
`requesterFanId`, `redactionConfirmed`, `receiptId`.

Overwhelmingly **engine bookkeeping** — collections and counters the archetype maintains as a side
effect of transitions. `platformSource` as designed names *which external service supplies a value*
(`checksum` → the hashing service; `opaqueId` → the id minter). Bookkeeping has no external supplier;
the engine computes it. `receiptId` is the exception and is correctly unwritten, because payment
processing is deferred and a receipt id for a payment that never happened is fabrication.

**So the real question: does `platformSource` mean "which external service owes this value", or
"who writes this field"?** Today's closed set answers the first. The warning's wording assumes the
second, which is why it fires on 55 fields that are behaving correctly.

**Options put to the user** (each production-grade; no option that stubs, fabricates, or defers a
value it claims to have):

1. **Reuse `checksum`, disambiguated by field type.** `text?` → the hash, `bool` → the verification
   outcome. *For:* no grammar growth; the source already names the service, and a service owing two
   values of different types is unambiguous. *Against:* one source owes two things; a reader must
   consult the type; strains if the service ever owes a third value. Leaves all 55 bookkeeping fields
   still warned about.
2. **Add `checksumVerification`, and a bookkeeping source for the rest.** One source, one value.
   *For:* explicit and self-describing; matches the discriminator's stated purpose; closes all 55.
   *Against:* grows a closed set; touches the hard-locked `05-validation.md` (doc-first, and the
   conformance test runs both ways), the grammar docs, the validator, and needs package regeneration.
3. **Narrow the rule: `platformSource` is only for externally-supplied values.** Engine bookkeeping
   declares `writableBy: "platform"` and needs no source; the warning fires only where an external
   service genuinely owes a value. *For:* no package regeneration; matches what the code already does;
   removes a warning that is wrong on 55 of its ~56 targets. *Against:* needs a principled, testable
   definition of "externally supplied" or the exemption becomes a loophole; `checksumVerified` sits on
   the boundary, since the service does compute it.

