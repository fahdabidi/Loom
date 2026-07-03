---
name: using-loom-to-build-an-extension
description: Build, validate, locally download, sideload, certify, and maintain Loom Communities extensions using the reference Loom source, APIs, component guides, workflow guides, examples, community product experience docs, validator feedback, production-ready persona-aware workflow UX, independent product UX review, and required full workflow UI testing evidence.
---

# Using Loom To Build An Extension

Use this Skill when an owner, builder, or agent needs to create or modify a Loom Communities extension.
The Skill is provider-neutral: it can be followed by any LLM or developer tool that can load the Skill
references, fetch or discover the Loom source tree, read API contracts and architecture docs, generate
extension artifacts, and run validation output.

The first supported execution targets are Codex and Claude Code running locally over the Loom source
tree. Online-only chat surfaces are deferred until Loom has a hosted build and validation backend.

## Operating Rules

1. Loom owns identity, membership, roles, consent, payments, protected data, ads, receipts, audit,
   certification, and export.
2. The extension owns experience, domain UI, schema declarations, rules, workflows, jobs, and optional
   sandboxed functions.
3. Use fixed Loom APIs. Do not invent backend storage or bypass App Shell, wallet, vault, ad, or audit
   invariants.
4. Declare the minimum permissions and surfaces needed.
5. Write fixtures and tests before local sideload or certification.
6. Keep custom data exportable.
7. In local mode, produce both a downloadable extension package and a downloadable initialization
   package for the fake backend.
8. Preserve the required shell structure: top ad banner, Messages, Connections, Loom payment surface,
   and ad-off behavior.
9. Keep prompt fixtures, golden outputs, and validator failure transcripts current so the Skill itself
   can be debugged.
10. Run system prereq setup before validation; do not claim an extension is validated unless
    `Skill/setup/validation-environment.lock.json` is current and the Demo App smoke check passes.
11. Bundle local icons/images for local-demo, declare their hashes/metadata, and preserve App
    Shell-owned community-card rendering and fallback priority.
12. Do not report an arbitrary extension complete until the prompt-build-validate loop emits a
    completion report with every requested workflow implemented and validated.
13. Learn from Loom reference implementations before building: explain existing workflow patterns,
    why Loom implemented them that way, and how those patterns map to the new extension.
14. Produce research, a community product experience doc, product workflow docs, workflow-to-API/rules/
    events maps, UX docs, an extension build tracker, and phase docs before executing. Stop for owner
    approval before code/package output. In standalone Skill execution, treat fetched Loom Product Docs
    V2 as read-only reference material and create/update local product docs under the extension
    workspace, starting with `docs/product/community-product-experience.md`; do not mutate the upstream
    Loom repo's canonical Product Docs V2.
15. Select production card surfaces from the Skill component catalog before designing screens. Use
    [components/card-surfaces/README.md](./components/card-surfaces/README.md) to choose the surface
    family, persona permissions, supported interactions, customization points, API contracts, and fake
    backend evidence required for each workflow. Map every selected interaction to the executable
    [Community Card Surfaces OpenAPI](../../API/OpenAPI/community-surfaces/community-card-surfaces-api.openapi.yaml)
    and the Product Docs V2
    [Card Surface Workflow and User Story Coverage](../../Product%20Docs%20V2/Card%20Surface%20Workflow%20and%20User%20Story%20Coverage.md).
    When the community needs schedule, document, case/status, external resource, tab/navigation, or
    shared-item behavior, prefer the dedicated `calendar`, `documents`, `workflow-status`,
    `external-document-link`, `app-shell-navigation-theming`, and expanded `equipment-loan`
    marketplace/loan/giveaway surfaces instead of folding those workflows into generic cards. Also
    select a per-tab renderer contract from
    [components/card-surfaces/tab-renderer-contracts.md](./components/card-surfaces/tab-renderer-contracts.md)
    for each tab: Calendar must render calendar/agenda/event detail, Messages must render
    inbox/thread/composer, Marketplace must render browse/listing/detail/current-holder/queue,
    Documents must render library/detail/embedded/external open, and arbitrary request flows must use
    workflow-status timeline/action surfaces when their steps vary by community. The extension product
    doc must also declare the persona-specific app-shell navigation model: required
    Home and Messages/Communication tabs, custom tabs, tab labels/icons/order, persona visibility,
    surface-to-tab assignments, per-tab pinning policy, minimized/medium/expanded defaults, and safe
    theme/customization knobs for community cards, tabs, typography, buttons, edit fields, badges,
    density, spacing, and colors. For any
    book/DVD/game/tool/gear/library/giveaway sharing use case, require browse/search, list/modify/
    delist, queue or hold state, current-holder or privacy-safe unavailable state, custody history,
    due/return/overdue/damage/lost state, and giveaway ownership transfer where applicable.
16. Do not claim any community extension is complete when a requested, declared, seeded, or route-linked
    workflow is missing, unreachable, unimplemented, only stubbed, only metadata-rendered, or only
    validated through direct service calls.
17. Fully test every community workflow through the visible Demo App UI with the Local Backend before
    local-demo delivery. Opening `local:<extension-id>@latest` or rendering a settings/metadata page is
    not sufficient workflow validation.
18. Capture screenshot evidence for every workflow's start state, critical user action, and completion
    state, and write a machine-readable evidence manifest that links workflow IDs to screenshots,
    command output, emulator/device details, assertions, and pass/fail status.
19. If any workflow lacks passing backend assertions, visible UI test coverage, screenshot evidence, or
    evidence-manifest entries, report the extension as incomplete and list the exact missing evidence
    instead of delivering or certifying the package.
20. Define every community persona/user role before building the UI. Map each workflow to the persona
    that can initiate it, personas that can approve/receive/read/continue it, required permissions, and
    unauthorized persona behavior.
21. Treat the Demo App people-icon persona picker as a local testing harness only. In production, persona
    and role come from the logged-in identity, memberships, grants, and policy engine.
22. Do not expose a workflow as generally executable when it is role-specific. For unauthorized personas,
    explicitly choose hidden, disabled-with-reason, read-only, or receiving-state UX and test that choice.
23. Multi-persona workflows must be tested by switching persona in the visible Demo App UI. Evidence must
    prove the actor persona creates/approves/sends the state and the receiver persona receives, reads,
    pays, searches, reviews, or continues it as designed.
24. Per-persona workflow completeness is required. Every declared persona must have positive tests for
    workflows they can perform or receive, and negative/visibility tests for workflows they must not
    perform.
25. If a workflow depends on another persona doing something first, test the full dependency chain in UI:
    prerequisite persona action, persisted backend state, persona switch, receiving persona state, and
    denial or hiding for unrelated personas.
26. Define production workflow UX contracts before building. For every workflow/persona row, specify the
    real user goal, workflow type, required inputs, validation, semantic actions, success/receipt state,
    receiver state, unauthorized behavior, and screenshot evidence IDs.
27. Do not treat a generic workflow card, metadata/settings page, test checklist, or `Complete workflow`
    dialog as a production community experience.
28. Use semantic user action labels, not harness labels. Buttons should name the action, such as
    `Publish announcement`, `RSVP to event`, `Submit care request`, `Approve request`, `Pay dues`,
    `Send invite`, `Export data`, or `Start transfer`.
29. Production workflow surfaces must include the states a real user needs: entry, inputs, validation,
    loading/empty/error, review or preview when appropriate, action, success/result, receipt or audit
    evidence when applicable, and receiver/read-only/disabled states per persona.
30. Tests and audits must fail if user-facing production workflow screens contain implementation copy
    such as `Can perform this workflow`, `workflow evidence`, `local route`, `Complete workflow`, or
    equivalent generic harness text.
31. Do not claim a workflow is complete when the evidence proves only that a test harness can mark it
    done. Completion requires production UX screenshots and backend assertions for the user-visible
    task and persona handoff.
32. After implementation and evidence capture, run two separate gates: a workflow compliance gate and an
    independent product UX review gate. The workflow compliance gate proves coverage, state, roles, and
    backend behavior; the product UX review gate judges whether the visible app feels like a modern
    production product for the target community and persona.
33. The independent product UX review must start from the visible Android emulator and final screenshots,
    not from the implementation plan. It must ask what a real member, admin, organizer, donor, guardian,
    or other target persona sees, understands, and can naturally do.
34. Do not pass the product UX review when user-facing screens expose implementation taxonomy or test
    harness language, including labels such as `Community workflows`, `[category] surface`, `workflow`,
    `evidence`, role-state rationale, or any equivalent copy that describes the framework instead of the
    community task.
35. Production community UX must be organized around domain-native information architecture and content:
    announcements, upcoming events, donations, volunteer needs, care requests, documents, messages,
    teams, facilities, or other sections that match the community. A global workflow list is not a
    production home screen.
36. Production workflow surfaces must contain realistic domain content and expected affordances, such as
    announcement body, author, audience, timestamp, event date/time/location/capacity, donation amount,
    receipt, privacy/protected-data indicators, and next steps. A card that only describes workflow
    mechanics is incomplete.
37. Treat exposed workflow machinery, metadata-only screens, generic checklist cards, missing domain
    content, unclear information architecture, or visibly test-harness layouts as major or blocker UX
    findings, even when automated workflow tests pass.
38. Do not equate removal of forbidden workflow copy with production-ready UX. Treat generic demo
    scaffold styling, repeated workflow-card primary UX, checklist/review dialogs, weak visual
    hierarchy, thin placeholder content, missing community identity, clipped text, overlapping floating
    controls, and awkward technical labels as major or blocker UX findings when they materially lower
    the product below a modern shippable bar.
39. Primary workflows must be represented by real domain product surfaces where appropriate: community
    feeds, inbox items, detail pages, compose screens, event detail/RSVP flows, donation/payment flows,
    volunteer signup forms, care request forms, admin review screens, receipts/history, and receiver
    states. A generic card with improved labels is not enough when a real product would use a richer
    domain surface.
40. Before building or remediating production UX, create or update the community product experience doc
    using [references/community-product-experience-template.md](./references/community-product-experience-template.md).
    The doc must define community identity, product promise, personas, jobs-to-be-done, home IA,
    domain-native product surfaces, workflow-to-surface mapping, persona/state matrix, required visible
    content, API/rules/events mapping, visual/interaction standard, and acceptance criteria.
41. Before the independent product UX review can pass, create a per-community production UX blueprint
    derived from the community product experience doc. It must define target personas, community
    identity, home information architecture, required product surfaces, workflow-to-surface mapping,
    realistic content requirements, visual/interaction standard, and concrete pass examples for every
    community/test app.
42. The independent product UX review must produce schema version 4 machine-readable evidence with
    review standard version, superseded prior run IDs, blueprint coverage, unique screen row IDs,
    screen-specific critiques, screenshot hashes/timestamps, app commit SHA, visible-text extracts,
    UI-pattern classification, stable finding/remediation IDs, before/after screenshot references,
    unresolved severity counts, rerun requirements, and final pass/fail decision.
43. The independent product UX review must inventory every implemented user-facing screen, state,
    dialog, card, feed item, form, confirmation, error, empty state, persona variant, and action result.
    Every inventory row must have a screenshot reference, product-UX verdict, severity assessment,
    screen-specific findings, required fix or acceptance rationale, and retest result. Boilerplate
    matrix rows with the same generic pass rationale across unrelated screens are invalid evidence.
44. Do not pass the independent product UX review with unresolved blocker or major UX issues. Minor
    issues must be fixed, explicitly owner-accepted, or tracked with rationale before delivery.
45. B25 is an iterative remediation gate, not a terminal review. If the product UX review finds any
    blocker or major issue, group findings into remediation themes, implement fixes, rebuild and relaunch
    the visible Demo App, recapture screenshots, regenerate the screen review matrix, rerun the product
    UX review, and repeat until blocker and major counts are zero.
46. Every B25 remediation loop iteration must record the review result, fixes applied, tests run,
    screenshots refreshed, remaining findings, and pass/fail decision. Do not stop after producing a
    failed review unless the owner explicitly asks for review-only planning or pauses implementation.
47. Commit every B25 loop iteration before starting the next UX feedback or remediation loop. Each
    iteration commit must include the review/remediation evidence, refreshed screenshots or explicit
    screenshot references, tests run, remaining findings, and tracker update for that iteration.
48. Treat all B25 v3 or older passes as historical when the v4 standard applies. B25 cannot be marked
    complete again until v4 evidence passes and explicitly supersedes the prior run IDs.
49. Enforce screenshot freshness. Every B25 v4 screen row must include screenshot path, screenshot hash,
    captured-at timestamp, emulator/device metadata, and app commit SHA. The evidence is invalid if a
    screenshot predates the remediation it claims to prove or if a resolved finding points to a stale
    before-state screenshot.
50. Enforce screen-specific critique integrity. Every review row must describe visible UI elements and
    visible text from its screenshot. Boilerplate critique, duplicated rationale across unrelated rows,
    or a pass verdict without visible screen details is invalid evidence.
51. Classify every user-facing primary surface as domain-native, secondary-supporting, or generic
    workflow-card. A primary workflow may not pass when represented only by a generic workflow-card,
    checklist modal, metadata page, or improved copy over the same repeated card shell.
52. Require domain-native replacement plans for primary generic surfaces. The plan must name the target
    product surface, such as event detail/RSVP, feed, inbox/thread, donation/payment, care request,
    volunteer signup, admin review queue, receipt/history, search result, export wizard, or transfer
    status screen.
53. Separate implementer and reviewer roles during B25. The reviewer prompt must be screenshot-first
    and adversarial: it must judge the visible product as a real user experience, not as the author of
    the implementation or the workflow checklist.
54. Do not allow B25 to pass on schema shape alone. Tests must validate screenshot freshness, non-empty
    visible-text extracts, unique row IDs, non-boilerplate critiques, domain-native primary surfaces,
    zero unresolved blocker/major findings, and internal consistency between markdown review, JSON
    evidence, remediation log, screenshots, and tracker.
55. Use separate judge tools for UX gates so worker agents do not grade their own implementation. B11
    must run the workflow-completeness judge; B21 the UX-contract judge; B22 the domain-surface
    classifier; B23 the persona-UX judge; B24 the evidence-integrity auditor; and B25 must run the
    evidence collector, workflow/persona coverage collector, visual inspection auditor, independent UX
    judge, workflow interaction-model judge, production UX judge, remediation-ticket generator, iteration
    scorecard, and remediation planner in sequence.
56. The Independent UX Judge Agent receives only artifacts, screenshots, pass criteria, evidence
    metadata, blueprint/contracts, and remediation logs. Do not give it worker implementation notes,
    intended behavior explanations, or optimistic completion summaries. It must write holistic direct
    answers, workflow/persona scorecards, screen-specific critiques, exact findings, and remediation
    ticket inputs from visible evidence only. It must inspect screenshot pixels and layout, not only row
    existence, metadata, or expected assertions.
57. B25 cannot pass until `b25_independent_ux_judge.dart` has produced the deterministic schema v4
    review scaffold, a fresh LLM Product Docs to Evidence Workflow Reconciliation Agent has compared
    each community product doc's `## 6. Workflow-To-Surface Mapping` and companion state/content/
    semantic/card-surface sections to the current screenshot/review evidence and produced
    `llm-product-doc-workflow-reconciliation-<run-id>.json` and `.md` with no unresolved blocker or
    major findings, a fresh LLM Vision UX Judge Agent has inspected the actual screenshots and
    produced `llm-vision-ux-review-<run-id>.json`, `b25_llm_review_freshness_gate.dart` has verified
    that artifact is fresh for the current run/app commit/screenshot hashes,
    `b25_llm_ux_review_importer.dart` has imported that artifact into `llmVisionReview`,
    `b25_workflow_interaction_model_judge.dart` has produced passing semantic interaction-model
    `workflowLifecycleScorecards`, and
    `production_ux_judge.dart` emits
    `production-ux-criteria-scorecard.json` and `.md` with score/verdict/blocksPass/why/requiredFix for
    every B25 pass criterion, `b25-remediation-tickets-<run-id>.json` and `.md` for every failed
    blocking criterion, and no blocking criterion failures.
    A carried-forward, copied, or prior-run LLM vision review can never close B25, even when app code
    did not intentionally change. The imported LLM artifact must declare `freshReview=true`,
    `currentReviewRunId=<run-id>`, `appCommitSha`, `reviewedScreenRowIds`, and
    `reviewedScreenshotHashes`, and must not include `sourceReviewRunId`, `carriedForward=true`, or
    `reusedPriorReview=true`.
58. B25 production UX criteria must be asked as direct questions. Avoid vague prompts such as "looks
    modern"; ask concrete questions such as "Is the UI modern, easy to use, easy to navigate, and
    visually appealing for the target persona?" and require screenshot-backed yes/no/partial answers.
    Keep the questions community-agnostic so they catch the same class of issue in any community:
    "Does this screen feel like a modern production app for this community and persona?", "Is the
    information architecture centered on real user jobs and community content?", "Does the copy sound
    like product language rather than workflow/spec/test language?", "Are the visual hierarchy,
    spacing, typography, color, and component variety shippable?", "Are title truncation, clipping,
    crowding, repeated-card fatigue, over-prominent platform banners, and one-note palettes absent?",
    "Does the screen provide the concrete content and lifecycle actions a real user needs?", and "What
    exact visible changes are required before this screen can pass?"
59. B25 requires three independent direct-question passes: one holistic product UX pass for the whole
    app or community experience, one workflow/persona pass for every reviewed workflow/persona pair,
    and one semantic workflow interaction-model pass for every reviewed workflow/persona pair. All three must be green
    before B25 can close.
60. The holistic product UX pass judges coherence, navigation, visual identity, community-centered
    information architecture, production feel, and major layout/content defects across the whole
    experience.
61. The workflow/persona pass judges task clarity, domain-native primary surface, natural actions,
    input/validation/result states, receiver states, unauthorized/read-only/disabled behavior, and
    whether that workflow UI feels production-grade on its own.
62. Do not batch all workflow/persona UX review into one broad answer. Use batches small enough that
    every answer cites visible text, screenshot evidence, the target persona, and the real user task.
63. `production_ux_judge.dart` must fail B25 when `llmVisionReview` is missing, failing, not
    screenshot-grounded, or contains unresolved blocker/major findings; when `holisticQuestionAnswers`,
    `workflowPersonaScorecards` are missing, partial, unsupported by visible evidence, below threshold,
    contradicted by screenshots, missing passing `semanticSurfaceProof` for any primary
    workflow/persona row, missing passing semantic interaction-model `workflowLifecycleScorecards`, or
    missing/failing `appShellCapabilityReview` proof for documented App Shell capabilities.
    `appShellCapabilityReview` must include screenshot-backed `tabRendererResults[]` rows for
    `CalendarTabSurface`, `MessagesTabSurface`, `MarketplaceTabSurface`, `DocumentsTabSurface`, and
    `WorkflowStatusSurface`, plus `interactionTransitionResults[]` rows proving important controls
    changed visible state from before/action/after screenshots. A pass cannot be based only on absence
    of known defects or on prose that says a renderer/control exists.
64. After every B25 review/remediation pass, run `b25_iteration_scorecard.dart` and commit the JSON and
    Markdown scorecard with the pass evidence. The scorecard must show pass/fail, current
    critical/blocker and major counts, unresolved blocker/major counts, blocker/major findings resolved
    in that pass, newly introduced blocker/major findings, judge failures, direct-question pass status,
    and required next action. Do not start the next UX feedback/remediation loop without this committed
    scorecard.
65. B25 screenshot evidence must be produced through the deterministic B25 evidence collector before
    the judges run. The collector owns screenshot paths, hashes, timestamps, visible text source,
    emulator/device metadata, app commit SHA, and schema v4 screen-row scaffolding. Then
    `b25_workflow_persona_coverage_collector.dart` must prove every workflow/persona combination has
    explicit entry/action/result evidence before independent review. Canonical B25 evidence must first
    pass `b25_capture_coverage_gate.dart` from a `--mode full-b25` B12-B20 capture. Targeted captures
    are allowed only as non-committable remediation diagnostics and cannot overwrite or substitute for
    `B20/all-workflow-ui-evidence.json`. The collector tools cannot mark production UX pass.
    B25 evidence must also carry advisory card-surface registry context: `workflow ->
    cardSurfaceFamily -> API contract -> required interactions/actions -> renderer/fake-backend
    support`. In native Loom repo runs, keep that mapping in the community Product Docs V2 file. In
    standalone Skill runs, keep the same mapping in the local extension product doc. This registry is
    required review context for remediation, but it is not yet a standalone card-surface/API coverage
    gate. App Shell capability utilization is a hard B25 gate: the evidence must include a passing
    `appShellCapabilityReview` proving persona tabs, explicit and appropriate per-tab pinning policy,
    minimized/medium/expanded states,
    tap-to-expand behavior, community-list card states, renderer selection, and theme/customization
    tokens where the product doc or App Shell component guide requires them. A tab may declare
    `pinnedSurfaces: none` when the product doc gives a job-to-be-done rationale; screenshots are
    required only for surfaces declared as pinned. Full B25 capture must include
    `wf_app-shell-capability-evidence` screenshots for the main community list, workflow presentation
    states, any declared pinned surface, and renderer-selection proof. The LLM Product Docs
    reconciliation artifact must turn that evidence into structured `tabRendererResults[]` and
    `interactionTransitionResults[]`; missing or weak rows must become remediation tickets.
66. B25 must run a distinct LLM Product Docs to Evidence Workflow Reconciliation gate before the final
    product-quality judgment. Use
    [../Tools/b25-product-doc-workflow-reconciliation-llm-gate.md](../Tools/b25-product-doc-workflow-reconciliation-llm-gate.md).
    The reviewer compares Product Docs V2 community examples, or the standalone Skill's local
    `docs/product/community-product-experience.md`, to current screenshot evidence. It must inspect
    `## 6. Workflow-To-Surface Mapping`, `## 7. Persona And State Matrix`, `## 8. Content And Seed
    Data Requirements`, `## 9. Visual And Interaction Standard`, `### B25 Semantic Interaction
    Models`, `### B25 Card Surface Registry Mapping`, and `## 3.1 Persona Tabs, Pins, And
    Customization`. Before judging, it must load and cite the component docs that define the selected
    surfaces and App Shell capabilities: `components/card-surfaces/README.md`,
    `components/card-surfaces/app-shell-navigation-theming.md`,
    `components/card-surfaces/tab-renderer-contracts.md`, and every
    `components/card-surfaces/<surface>.md` file referenced by the product doc's card-surface
    registry. In native Loom repo runs, load these from `docs/Build Plan V2/Skill/components`; in
    standalone Skill runs, load the bundled local Skill equivalents. The output JSON must include
    `reviewedComponentDocPaths`, per-community `componentDocsReviewed`, and per-tab renderer
    `componentDocPaths`; missing component-doc review is a major finding. The reviewer must reread
    these component docs on every B25 run, not only when a file appears changed. Before calling the
    LLM reviewer, run `b25_component_doc_context.dart` and provide
    `b25-component-doc-context-<run-id>.json`; the LLM output must include
    `componentDocReview.docs[]` with each required doc's `path`, `sha256`, `gitLastCommitSha`,
    `gitStatus`, `reviewedThisRun=true`, `reviewRunId`, `semanticSummary`, and
    `semanticImplicationsForCommunities`. If the hash or git last-commit changed since the prior pass,
    the LLM must explain the semantic delta and identify required Product Docs, tab, card-surface,
    theme/customization, evidence, or implementation updates. `production_ux_judge.dart` cross-checks
    those hashes and commit fields against the current repo. It must find documented
    workflows missing from screenshots, screenshot-visible
    workflows/interactions missing from product docs, missing required visible proof, persona/state
    drift, incomplete lifecycle actions, generic or wrong surface mappings, and missing App Shell
    capability utilization. It must specifically ask whether the selected card surface fits the
    community job-to-be-done better than available alternatives, whether Calendar, Messages, Marketplace,
    Documents, and Workflow Status tabs look and behave like their tab-native product surfaces rather
    than generic workflow lists, whether community theme/typography/pinning/presentation states follow
    the App Shell guide, and whether important controls prove before/action/after state changes.
    Unresolved blocker/major findings, weak tab-renderer proof, weak interaction-transition proof, or a
    failing `appShellCapabilityReview` become remediation tickets and block B25.
67. The B25 semantic product-quality review is a distinct LLM Vision UX Judge Agent step. It consumes
    only the community product experience doc, evidence artifacts, screenshots, blueprint,
    workflow/persona coverage matrix, and pass criteria, then writes
    `llm-vision-ux-review-<run-id>.json` with holistic direct-question answers, screen-specific
    critiques, exact findings tied to screen rows/screenshots/personas/workflows, and remediation
    ticket inputs. The deterministic `b25_independent_ux_judge.dart` may normalize evidence and carry
    deterministic visual signals, but it is not allowed to be the final semantic reviewer. The LLM
    vision judge must fail when workflow/persona coverage is generic, missing, or not
    screenshot-backed. It must also fail when `visualInspection` is missing or reports checklist-modal,
    repeated-card shell, thin-content, weak visual identity, default-scaffold, or missing-image signals.
    It must fail when a Calendar tab does not look like calendar/agenda/event UI, a Messages tab does
    not look like inbox/thread/chat/composer UI, a Marketplace tab does not look like browse/search/
    listing/detail UI, a Documents tab does not look like document library/detail/open UI, or a
    workflow/status surface does not look like a multi-step status/timeline/action UI.
    It must also perform positive semantic closure for every workflow/persona and every remediated
    ticket: compare the requested target product surface to the after screenshots and fail unless the
    visible UI proves the required domain content and affordances are present. For example, a Masjid
    announcement cannot close unless the after screenshots visibly prove audience/recipient group,
    author or sender attribution, message body, timestamp or delivery timing, receiver inbox/feed
    state, and a natural publish/send/read action.
68. Every failed B25 judge pass must produce remediation tickets. Each ticket must name the failed
    criterion, related finding IDs, concrete improvements, affected evidence, acceptance checks, and
    rerun commands. Each ticket must follow
    [../Tools/b25-remediation-ticket-template.md](../Tools/b25-remediation-ticket-template.md) and
    include user-facing problem statement, root-cause hypothesis, target experience, UX principles,
    implementation guidance, content guidance, visual guidance, evidence to collect, non-goals, commit
    boundary, remediation mode, worker readiness, implementation blockers, evidence-repair work items,
    UI-remediation work items, tab ID, renderer contract, target card-surface family,
    missing tab-native evidence, interaction evidence required, required screenshots to recapture, UX
    reference patterns to copy, and reference research queries. The
    Independent UX Judge must search the internet or open-source projects for comparable patterns when
    network access is available, or use the built-in B25 reference catalog with refresh queries when
    it is not. The next Worker Agent iteration must use those tickets as its fix backlog.
    Tickets must classify the failure as `product-spec-gap`, `implementation-gap`, `evidence-gap`, or
    `mixed-gap`. Product-spec gaps update the community product doc first; implementation gaps update
    UI/content/code/seed data/tests; evidence gaps repair screenshots, visible text, hashes, or
    coverage; mixed gaps sequence those fixes in that order.
    Ticket closure requires before/after screenshot evidence and a passing semantic-surface proof; the
    Remediation Planner and Worker Agent may not close tickets from implementation notes or code diffs
    alone. Workflow interaction-model tickets additionally require fresh after screenshots proving the
    expected decision, required domain actions, non-happy-path affordance, result state, and receiver/
    continuation state.
69. The Remediation Planner does not implement fixes. It starts the next B25 remediation pass by
    consuming the prior pass's tickets and scorecard, then emits `b25-remediation-plan-<run-id>.json`
    and `.md` with ordered remediation batches, ticket IDs, worker actions, implementation guidance,
    evidence updates, acceptance checks, rerun commands, work-item summaries, evidence-repair work
    items, UI-remediation work items, and the commit boundary for that next iteration. Planner output
    must keep evidence repair separate from UI implementation; UI remediation for a community/workflow/
    persona may not start until its matching evidence-repair item has rerun clean.

## Delivery Modes

- `local-demo`: create a downloadable extension package and initialization package for the Demo Loom
  Communities App with the Local Backend.
- `real-backend-publish`: create the package and backend initialization payloads required for a real
  Loom Communities backend publish flow.

All workflow validation uses the Demo App with the Local Backend. Real-backend publish behavior is
proved through local stubs/contracts before any external backend is used. A workflow is not validated
until it passes both API/backend assertions and visible UI workflow execution in the Demo App.

## Required Workflow Validation Gate

Before building code or package output:

1. Enumerate every workflow from the owner prompt, requirements docs, route manifest, seed files,
   workflow docs, examples, and generated package artifacts.
2. Create or update `docs/product/community-product-experience.md` in the extension workspace using
   [references/community-product-experience-template.md](./references/community-product-experience-template.md).
   This doc is the local source of truth for the extension's rich product experience. It must define
   the community promise, personas, jobs-to-be-done, information architecture, home screen,
   domain-native product surfaces, workflow-to-surface mapping, persona/state matrix, required visible
   content, visual standard, and acceptance criteria before implementation starts.
3. Map each workflow to Loom APIs, extension-owned UI routes, rules/events, seed data, expected end
   state, test IDs, and screenshot evidence IDs.
4. Enumerate community personas/user roles, role grants, actor IDs, workflow initiators, workflow
   receivers, unauthorized personas, and expected hidden/disabled/read-only/receiving UI states.
5. Add or update tests before sideload/certification so each workflow can be exercised through the
   visible Demo App UI with the Local Backend.
6. Define evidence paths under the build plan evidence folder, using one screenshot bundle and one
   `workflow-ui-evidence.json` manifest per community or test app.
7. For any workflow involving more than one role, define multi-persona evidence IDs for the actor state,
   persona switch, and receiver/continuation state.
8. Build a workflow dependency graph that names prerequisite persona actions, generated records,
   receiving personas, and reset/idempotency requirements for every dependent workflow.
9. Create a per-persona test matrix with one row for every persona/workflow combination: authorized
   action, unauthorized action, hidden state, disabled state, read-only state, or receiving state.
10. Create a production workflow UX contract matrix with one row for every workflow/persona state. Include
   workflow category, real user goal, production screen sections, inputs, validation, semantic action
   labels, success/result state, receiver state, and screenshot evidence IDs.
11. Select the domain pattern for every workflow: event/RSVP, payment/donation/dues/ad-off,
    form/protected data, announcement/publishing/notification, approval/review, search/AI, export/import
    migration, messages/connections, ads, or shell/platform invariant.
12. Reject any planned workflow surface that is only a generic checklist, metadata view, global workflow
    list, or completion dialog. Produce a gap report instead of building from an incomplete UX contract.
13. Define the production information architecture for each community before implementation. The first
    user-facing screen must be organized around the community's real content and jobs-to-be-done, not
    around extension workflow categories or testing states.

Before reporting completion:

1. Run system prereq setup and the Demo App smoke check.
2. Install the local extension/init package pair into the Demo App with the Local Backend.
3. Open the installed community card and verify it reaches the actual community experience, not only a
   generic metadata/settings screen.
4. Use the people-icon persona picker to verify each declared persona/user role. Confirm the active
   persona changes visible capabilities and workflow states.
5. Complete every authorized workflow through UI interactions on the Android emulator, using the
   correct initiating persona.
6. Verify unauthorized personas cannot complete role-specific workflows and see the documented hidden,
   disabled, read-only, or receiving-state UX.
7. For multi-persona workflows, switch personas in the UI and prove the receiving persona can observe or
   continue the state created by the initiating persona.
8. For dependent workflows, execute the full prerequisite chain in order. For example, an organizer or
   leader creates an announcement/event, then a member persona receives, searches, RSVPs, pays, reviews,
   or continues from that created state.
9. Capture at least three screenshots per workflow: start/entry, critical action, and completion/result.
   For multi-persona workflows, also capture the persona switch and receiving state.
10. Verify backend state, receipts, protected-data redaction, exports, notifications, ads, payments, and
   App Shell invariants that apply to the workflow.
11. Write and audit `workflow-ui-evidence.json` so every workflow has screenshot paths, persona IDs,
    role labels, assertions, command output, emulator/device metadata, and pass/fail status.
12. Write and audit a per-persona workflow matrix proving every persona/workflow row was tested or
    explicitly marked not applicable with rationale.
13. Capture production UX evidence for every workflow: entry, input, validation or review, semantic
    action, success/result, backend parity, and receiver state for multi-persona workflows.
14. Run a generic-copy failure gate or equivalent audit that fails when user-facing production workflow
    screens contain harness labels or implementation copy.
15. Confirm that each persona sees production-appropriate actor, receiver, read-only, disabled, hidden,
    or unauthorized UX and that dependent workflows show state created by the prerequisite persona.
16. Run the workflow compliance gate and record whether workflows, personas, prerequisite chains,
    backend assertions, screenshots, and evidence manifests are complete.
17. Confirm the local community product experience doc is current, linked in the evidence, and reflects
    any product-spec remediation from the current pass. Then create or update the per-community
    production UX blueprint for every community/test app and persona. The blueprint must be derived
    from the product doc and must define the target production experience before any B25 pass verdict is
    allowed.
18. Run the independent product UX review against the actual visible app and final screenshots. First
    create a complete screen inventory for every community, persona, workflow, screen, state, dialog,
    card, feed item, form, confirmation, error, empty state, and action result.
19. For every inventory row, perform a screen-by-screen critique that asks whether the surface feels like
    a real product screen, exposes implementation/test/workflow language, uses domain-native
    information architecture, contains realistic useful content, has natural labels/actions, is modern,
    scannable, accessible, and mobile-appropriate, has clear hierarchy/spacing/typography/component
    quality, avoids overlap/clipping/crowding, avoids repetitive generic cards and checklist dialogs,
    and supports what the target user is trying to do.
20. Rank findings by severity, document recommended fixes, resolve or owner-accept minor issues, and
    require a final production UX pass decision before delivery.
21. During product UX review, fail any experience that still looks like a workflow harness: global
    workflow lists, surface/category chips exposed to users, implementation rationale copy, missing
    realistic domain content, missing section-level IA, or action/result states that would not make sense
    to a real community member.
22. During product UX review, also fail any experience that still looks like a generic demo scaffold:
    repeated same-shape cards as the primary UI, letter-avatar-only community identity where richer
    brand treatment is expected, checklist modals instead of real domain detail/forms, chips that expose
    status without useful context, overlapping FAB/sticky controls, clipped text, thin placeholder
    content, or weak visual hierarchy that would not meet a modern production app standard.
23. Produce schema version 4 machine-readable review evidence with blueprint coverage, unique
    screen-row IDs, screenshot hashes, captured-at timestamps, app commit SHA, visible-text extracts,
    UI-pattern classification, non-boilerplate critiques, stable finding/remediation IDs, screenshot
    references, unresolved severity counts, rerun requirements, and the final pass/fail decision.
24. If the product UX review fails with any blocker or major finding, start the B25 remediation loop:
    cluster findings by root cause, create a remediation batch, apply UX/content/code fixes, rebuild and
    relaunch the Demo App, recapture affected screenshots, rerun workflow and product UX evidence, and
    regenerate the screen review matrix. Commit that full iteration before starting the next UX
    feedback or correction loop.
25. Run the B25 evidence collector to generate or refresh schema v4 screenshot evidence before any
    judge pass. Treat collector output as evidence capture only, not UX approval.
26. Run `b25_visual_inspection_auditor.dart` so every screen row has screenshot pixel/layout metrics,
    signals, status, summary, and visual finding IDs. A failed or missing visual inspection blocks B25.
    If the auditor exits nonzero, continue the same pass through the independent and production judges
    so tickets and the iteration scorecard are still produced.
27. Run the B25 direct-question judge in two passes: one holistic product UX pass for the whole app, and
    workflow/persona passes for every reviewed workflow/persona pair. Record `holisticQuestionAnswers`
    and `workflowPersonaScorecards` in the evidence and require both to be green.
28. Run `b25_workflow_interaction_model_judge.dart` so every workflow/persona pair proves the correct
    semantic interaction model from screenshots: concrete object/context, decision information, primary
    semantic action, required alternate/change/reject affordance, persistent result state, and receiver/
    continuation state. Record `workflowLifecycleScorecards` in the evidence and require every primary
    workflow/persona scorecard to be green. If a prior ticket claimed a correction, the judge must
    inspect the new after screenshots and cannot accept source changes or worker statements as proof.
29. Generate the B25 iteration scorecard for the pass and record whether blocker/major findings are
    increasing, decreasing, or resolved. Use it as the convergence record for the remediation loop.
30. Generate B25 remediation tickets for every failed blocking criterion and attach them to the pass
    evidence.
31. Commit the current B25 pass after the evidence, judge scorecard, remediation tickets, iteration
    scorecard, remediation log, and tracker all reflect the judge findings. This finishes pass N.
32. If pass N failed, start pass N+1 by sending the committed tickets and scorecard to the Remediation
    Planner. Use the remediation plan, not a general scorecard summary, as the next iteration's fix
    backlog.
33. Reject any product UX review that relies on stale screenshots, rows with repeated generic rationale,
    primary workflow rows classified as generic workflow-card/checklist/modal/metadata-only, missing
    visible-text extracts, missing/failed visual inspection, or pass verdicts that do not describe the
    actual visible UI.
34. Repeat the B25 remediation loop until the product UX review reports zero unresolved blocker or major
    findings and every screen matrix row passes, has an owner-accepted minor issue, or has tracked polish
    only.
35. Run affected widget/integration tests, workflow tests, manifest gate, phase gate, analysis, boundary
    lint, and diff check.
36. Run the required judge tools for the applicable phase. Treat a judge failure as a phase-blocking
    finding, not as optional review feedback.

Do not mark `complete=true`, close a phase, certify, publish, or deliver local packages when any
workflow or persona/workflow row is untested, has missing screenshots, lacks prerequisite-chain
coverage, lacks backend parity checks, lacks persona/role capability evidence, lacks production UX
contract coverage, uses generic harness copy or exposed workflow machinery as the user experience, has
any implemented screen/state missing from the product UX screen review matrix, has unresolved blocker or
major independent product UX review findings, still looks like a generic demo scaffold rather than a
modern production product, has unresolved overlap/clipping/repetitive-card/checklist-modal/thin-content
issues ranked major or blocker, lacks a current local community product experience doc, lacks a
complete per-community production UX blueprint derived from that product doc, lacks schema version 4
machine-readable B25 review evidence, lacks a fresh LLM Product Docs to Evidence Workflow
Reconciliation artifact proving Product Docs V2 or local Skill product docs match the current
screenshots/review evidence, has stale screenshot evidence, has boilerplate screen critiques,
classifies any primary workflow surface as a generic workflow-card/checklist/modal/metadata page, has
any primary workflow/persona lifecycle scorecard missing or failing, has action cards that lack the
concrete object, decision data, alternate/change/reject path, result state, or receiver/continuation
state a real product interaction model requires, or lacks fresh after screenshots proving the corrected
interaction model,
not completed the B25 remediation loop after a failed product UX review, lacks a final independent
product UX pass decision, or is only represented by metadata. Return a gap report and keep the package
incomplete until all workflow, persona, local community product doc, production UX blueprint,
production UX evidence, B25 remediation-loop evidence, holistic direct-question evidence,
workflow/persona direct-question evidence, B25 remediation ticket evidence, B25 remediation plan
evidence, B25 iteration scorecard evidence, and independent product UX review evidence is green.

## UX Judge Tools

For UX gates, use [../Tools/ux-gate-judge-tools.md](../Tools/ux-gate-judge-tools.md). The required
judge tools and artifacts are:

- B11: `dart run packages/tooling/loom_ux_judges/bin/workflow_completeness_judge.dart`
- B21: `dart run packages/tooling/loom_ux_judges/bin/ux_contract_judge.dart`
- B22: `dart run packages/tooling/loom_ux_judges/bin/domain_surface_classifier.dart`
- B23: `dart run packages/tooling/loom_ux_judges/bin/persona_ux_judge.dart`
- B24: `dart run packages/tooling/loom_ux_judges/bin/evidence_integrity_auditor.dart`
- B25 capture: `dart run packages/tooling/loom_ux_judges/bin/b25_capture_workflow_screenshots.dart`
- B25 capture coverage gate: `dart run packages/tooling/loom_ux_judges/bin/b25_capture_coverage_gate.dart`
- B25 visual audit: `dart run packages/tooling/loom_ux_judges/bin/b25_visual_inspection_auditor.dart`
- B25 review scaffold: `dart run packages/tooling/loom_ux_judges/bin/b25_independent_ux_judge.dart`
- B25 component-doc context: `dart run packages/tooling/loom_ux_judges/bin/b25_component_doc_context.dart`
- B25 Product Docs to Evidence Workflow Reconciliation: LLM artifact using `docs/Build Plan V2/Tools/b25-product-doc-workflow-reconciliation-llm-gate.md`
- B25 LLM freshness gate: `dart run packages/tooling/loom_ux_judges/bin/b25_llm_review_freshness_gate.dart`
- B25 LLM review import: `dart run packages/tooling/loom_ux_judges/bin/b25_llm_ux_review_importer.dart`
- B25 workflow interaction-model judge: `dart run packages/tooling/loom_ux_judges/bin/b25_workflow_interaction_model_judge.dart`
- B25: `dart run packages/tooling/loom_ux_judges/bin/production_ux_judge.dart`
- B25 planner: `dart run packages/tooling/loom_ux_judges/bin/b25_remediation_planner.dart`

The agent split is mandatory: Worker Agent implements, Evidence Collector captures, Judge Agent scores
artifacts only, and Remediation Planner converts failures into fix batches. If the artifact does not
prove the criterion, the criterion fails.

For B25, the judge must also produce a holistic product UX direct-question pass, per-workflow/persona
direct-question passes, and semantic workflow interaction-model scorecards. The deterministic scorecard must include
criterion `scope` and `question`, and the machine-readable evidence must include
`holisticQuestionAnswers`, `workflowPersonaScorecards`, and `workflowLifecycleScorecards`.
Every failed blocking criterion must also produce a remediation ticket with concrete improvements,
affected evidence, acceptance checks, and rerun commands.
Before the LLM Vision UX Judge runs, produce
`llm-product-doc-workflow-reconciliation-<run-id>.json/.md`. The LLM reviewer must compare every
community product doc's `## 6. Workflow-To-Surface Mapping` and companion Sections 7-9, B25 semantic
interaction rows, and card-surface registry rows to the current screenshots, visible text, screen
matrix, workflow/persona coverage, review JSON, and the loaded component docs for tab renderer
contracts, App Shell navigation/theming, and every referenced card surface. First run
`b25_component_doc_context.dart` to capture component-doc hashes, git last-commit SHAs, and dirty
status for the current repo. The LLM must review the docs every run and record
`reviewedComponentDocPaths`, `componentDocReview.docs[]`, semantic summaries, and semantic
implications. `production_ux_judge.dart` validates those hashes/commit fields against the current
files and fails stale or pass-shaped component-doc review. Route component-doc mismatches, missing
component docs, weak tab-native renderer usage, or unsupported card-surface/customization choices into
blocker/major remediation tickets. Its blocker/major product-doc, implementation, evidence,
component-contract, or mapping findings must be converted into remediation tickets.
For visible manual review or dual-emulator B25 runs, launch emulators with the hardened launcher rather
than ad hoc `flutter emulators --launch` commands. The reliable concurrent-emulator path starts from a
clean emulator state and launches both AVDs read-only:

```powershell
wsl.exe -d Ubuntu -- bash -lc 'cd "/mnt/c/Users/fahd_/OneDrive/Documents/Loom" && bash app/packages/tooling/launch_loom_demo_emulators.sh --restart --mode both --run-app --app-target manual'
```

Use `--dry-run` on the same script to verify paths and the selected command without stopping or
starting emulator instances.
Before the judge runs, collect evidence with:

```powershell
wsl.exe -d Ubuntu -- bash -lc 'cd "/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app" && dart run packages/tooling/loom_ux_judges/bin/b25_capture_workflow_screenshots.dart --mode full-b25 --device emulator-5554 --evidence-root ../docs/Build\ Plan\ V2/Evidence'
wsl.exe -d Ubuntu -- bash -lc 'cd "/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app" && dart run packages/tooling/loom_ux_judges/bin/b25_capture_coverage_gate.dart --evidence-root ../docs/Build\ Plan\ V2/Evidence --output ../docs/Build\ Plan\ V2/Evidence/B25/b25-capture-coverage-report.json'
wsl.exe -d Ubuntu -- bash -lc 'cd "/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app" && dart run packages/tooling/loom_ux_judges/bin/b25_evidence_collector.dart --evidence-root ../docs/Build\ Plan\ V2/Evidence --repo-root .. --run-id b25-v4-pass-1 --prior-review ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --output ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.md --matrix-output ../docs/Build\ Plan\ V2/Evidence/B25/product-ux-screen-review-matrix.md'
wsl.exe -d Ubuntu -- bash -lc 'cd "/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app" && dart run packages/tooling/loom_ux_judges/bin/b25_workflow_persona_coverage_collector.dart --input ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --output ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/workflow-persona-coverage-matrix.md'
wsl.exe -d Ubuntu -- bash -lc 'cd "/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app" && dart run packages/tooling/loom_ux_judges/bin/b25_visual_inspection_auditor.dart --input ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --output ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/b25-visual-inspection-audit.md'
```

Use the B25 capture CLI, not a raw `flutter test integration_test/...` command. The CLI invokes the
host-side `flutter drive` screenshot writer, persists PNGs into the Evidence folders, rewrites
`workflow-ui-evidence.json`, and fails if screenshots were not written. The default `--mode full-b25`
is the only commit-eligible capture. A remediation pass may run `--mode targeted-precheck --phases
<phase>` for quick diagnostics, but the iteration commit must rerun full capture plus
`b25_capture_coverage_gate.dart` before the collector and judges.
While capture is running, monitor `docs/Build Plan V2/Evidence/B25/b25-capture-progress.json`. The
capture CLI updates it with `status`, `currentPhase`, `currentWorkflowId`,
`completedWorkflowsInCurrentPhase`, `totalWorkflowsInCurrentPhase`, `completedPhases`, `phaseCount`,
and the latest screenshot/progress event. The CLI also streams `B25_CAPTURE_PROGRESS` lines to stdout
so a stalled run can be distinguished from a long-running workflow.

Every B25 pass must also run the LLM Product Docs to Evidence Workflow Reconciliation gate, the judge,
and the iteration scorecard before that pass is committed. After the deterministic scaffold command
below, produce `llm-product-doc-workflow-reconciliation-<run-id>.json/.md` from
[../Tools/b25-product-doc-workflow-reconciliation-llm-gate.md](../Tools/b25-product-doc-workflow-reconciliation-llm-gate.md);
then continue with the fresh LLM Vision UX review, importer, interaction-model judge, production
judge, tickets, and scorecard:

```powershell
wsl.exe -d Ubuntu -- bash -lc 'cd "/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app" && dart run packages/tooling/loom_ux_judges/bin/b25_independent_ux_judge.dart --input ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --output ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.md --matrix-output ../docs/Build\ Plan\ V2/Evidence/B25/product-ux-screen-review-matrix.md'
wsl.exe -d Ubuntu -- bash -lc 'cd "/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app" && dart run packages/tooling/loom_ux_judges/bin/b25_llm_review_freshness_gate.dart --input ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --llm-review ../docs/Build\ Plan\ V2/Evidence/B25/llm-vision-ux-review-<run-id>.json --run-id <run-id> --output ../docs/Build\ Plan\ V2/Evidence/B25/b25-llm-review-freshness-gate-<run-id>.json --markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/b25-llm-review-freshness-gate-<run-id>.md'
wsl.exe -d Ubuntu -- bash -lc 'cd "/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app" && dart run packages/tooling/loom_ux_judges/bin/b25_llm_ux_review_importer.dart --input ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --llm-review ../docs/Build\ Plan\ V2/Evidence/B25/llm-vision-ux-review-<run-id>.json --run-id <run-id> --output ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.md --matrix-output ../docs/Build\ Plan\ V2/Evidence/B25/product-ux-screen-review-matrix.md'
wsl.exe -d Ubuntu -- bash -lc 'cd "/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app" && dart run packages/tooling/loom_ux_judges/bin/b25_workflow_interaction_model_judge.dart --input ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --output ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/b25-workflow-lifecycle-scorecards.md'
wsl.exe -d Ubuntu -- bash -lc 'cd "/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app" && dart run packages/tooling/loom_ux_judges/bin/production_ux_judge.dart --input ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --base .. --output ../docs/Build\ Plan\ V2/Evidence/B25/production-ux-criteria-scorecard.json --markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/production-ux-criteria-scorecard.md --tickets-output ../docs/Build\ Plan\ V2/Evidence/B25/b25-remediation-tickets-b25-v4-pass-1.json --tickets-markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/b25-remediation-tickets-b25-v4-pass-1.md'
wsl.exe -d Ubuntu -- bash -lc 'cd "/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app" && dart run packages/tooling/loom_ux_judges/bin/b25_iteration_scorecard.dart --review ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --judge ../docs/Build\ Plan\ V2/Evidence/B25/production-ux-criteria-scorecard.json --output ../docs/Build\ Plan\ V2/Evidence/B25/b25-iteration-scorecard-latest.json --markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/b25-iteration-scorecard-latest.md'
```

If the committed pass failed, the next B25 pass starts by running:

```powershell
wsl.exe -d Ubuntu -- bash -lc 'cd "/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app" && dart run packages/tooling/loom_ux_judges/bin/b25_remediation_planner.dart --tickets ../docs/Build\ Plan\ V2/Evidence/B25/b25-remediation-tickets-b25-v4-pass-1.json --review ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --scorecard ../docs/Build\ Plan\ V2/Evidence/B25/b25-iteration-scorecard-latest.json --output ../docs/Build\ Plan\ V2/Evidence/B25/b25-remediation-plan-b25-v4-pass-2.json --markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/b25-remediation-plan-b25-v4-pass-2.md'
```

## System Prereq Setup

Before generating or validating packages, read [setup/system-prereqs.md](./setup/system-prereqs.md)
and [setup/prereq-manifest.json](./setup/prereq-manifest.json). The Skill must detect whether it is
running under Codex or Claude Code, prepare the required validation tools, and write
[setup/validation-environment.lock.json](./setup/validation-environment.lock.json).

## Primary Walkthrough

Start with [using-loom-to-build-an-extension.md](./using-loom-to-build-an-extension.md).

## Reference Methodology

- Learn from Loom reference implementations with
  [references/loom-reference-implementation-methodology.md](./references/loom-reference-implementation-methodology.md).
- Follow the extension creation process in
  [references/extension-creation-process.md](./references/extension-creation-process.md).
- Define the local community product experience with
  [references/community-product-experience-template.md](./references/community-product-experience-template.md).
- Map workflows with
  [references/workflow-api-mapping-template.md](./references/workflow-api-mapping-template.md).
- Apply UX methodology with
  [references/ux-methodology-template.md](./references/ux-methodology-template.md).
- Bootstrap or fetch source dependencies with
  [references/source-dependency-model.md](./references/source-dependency-model.md).

## Phase-Enriched Guides

- Component guides live under [components](./components).
- Card surface component guides live under
  [components/card-surfaces](./components/card-surfaces).
- Workflow guides live under [workflows](./workflows).
- Worked examples live under [examples](./examples).
- Setup guides live under [setup](./setup).

This skeleton is created in Phase 0. Every later phase must enrich it before that phase can complete.
