---
name: using-loom-to-build-an-extension
description: Build, validate, locally download, sideload, certify, and maintain Loom Communities extensions using the reference Loom source, APIs, component guides, workflow guides, examples, validator feedback, production-ready persona-aware workflow UX, independent product UX review, and required full workflow UI testing evidence.
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
14. Produce research, product workflow docs, workflow-to-API/rules/events maps, UX docs, an extension
    build tracker, and phase docs before executing. Stop for owner approval before code/package output.
15. Do not claim any community extension is complete when a requested, declared, seeded, or route-linked
    workflow is missing, unreachable, unimplemented, only stubbed, only metadata-rendered, or only
    validated through direct service calls.
16. Fully test every community workflow through the visible Demo App UI with the Local Backend before
    local-demo delivery. Opening `local:<extension-id>@latest` or rendering a settings/metadata page is
    not sufficient workflow validation.
17. Capture screenshot evidence for every workflow's start state, critical user action, and completion
    state, and write a machine-readable evidence manifest that links workflow IDs to screenshots,
    command output, emulator/device details, assertions, and pass/fail status.
18. If any workflow lacks passing backend assertions, visible UI test coverage, screenshot evidence, or
    evidence-manifest entries, report the extension as incomplete and list the exact missing evidence
    instead of delivering or certifying the package.
19. Define every community persona/user role before building the UI. Map each workflow to the persona
    that can initiate it, personas that can approve/receive/read/continue it, required permissions, and
    unauthorized persona behavior.
20. Treat the Demo App people-icon persona picker as a local testing harness only. In production, persona
    and role come from the logged-in identity, memberships, grants, and policy engine.
21. Do not expose a workflow as generally executable when it is role-specific. For unauthorized personas,
    explicitly choose hidden, disabled-with-reason, read-only, or receiving-state UX and test that choice.
22. Multi-persona workflows must be tested by switching persona in the visible Demo App UI. Evidence must
    prove the actor persona creates/approves/sends the state and the receiver persona receives, reads,
    pays, searches, reviews, or continues it as designed.
23. Per-persona workflow completeness is required. Every declared persona must have positive tests for
    workflows they can perform or receive, and negative/visibility tests for workflows they must not
    perform.
24. If a workflow depends on another persona doing something first, test the full dependency chain in UI:
    prerequisite persona action, persisted backend state, persona switch, receiving persona state, and
    denial or hiding for unrelated personas.
25. Define production workflow UX contracts before building. For every workflow/persona row, specify the
    real user goal, workflow type, required inputs, validation, semantic actions, success/receipt state,
    receiver state, unauthorized behavior, and screenshot evidence IDs.
26. Do not treat a generic workflow card, metadata/settings page, test checklist, or `Complete workflow`
    dialog as a production community experience.
27. Use semantic user action labels, not harness labels. Buttons should name the action, such as
    `Publish announcement`, `RSVP to event`, `Submit care request`, `Approve request`, `Pay dues`,
    `Send invite`, `Export data`, or `Start transfer`.
28. Production workflow surfaces must include the states a real user needs: entry, inputs, validation,
    loading/empty/error, review or preview when appropriate, action, success/result, receipt or audit
    evidence when applicable, and receiver/read-only/disabled states per persona.
29. Tests and audits must fail if user-facing production workflow screens contain implementation copy
    such as `Can perform this workflow`, `workflow evidence`, `local route`, `Complete workflow`, or
    equivalent generic harness text.
30. Do not claim a workflow is complete when the evidence proves only that a test harness can mark it
    done. Completion requires production UX screenshots and backend assertions for the user-visible
    task and persona handoff.
31. After implementation and evidence capture, run two separate gates: a workflow compliance gate and an
    independent product UX review gate. The workflow compliance gate proves coverage, state, roles, and
    backend behavior; the product UX review gate judges whether the visible app feels like a modern
    production product for the target community and persona.
32. The independent product UX review must start from the visible Android emulator and final screenshots,
    not from the implementation plan. It must ask what a real member, admin, organizer, donor, guardian,
    or other target persona sees, understands, and can naturally do.
33. Do not pass the product UX review when user-facing screens expose implementation taxonomy or test
    harness language, including labels such as `Community workflows`, `[category] surface`, `workflow`,
    `evidence`, role-state rationale, or any equivalent copy that describes the framework instead of the
    community task.
34. Production community UX must be organized around domain-native information architecture and content:
    announcements, upcoming events, donations, volunteer needs, care requests, documents, messages,
    teams, facilities, or other sections that match the community. A global workflow list is not a
    production home screen.
35. Production workflow surfaces must contain realistic domain content and expected affordances, such as
    announcement body, author, audience, timestamp, event date/time/location/capacity, donation amount,
    receipt, privacy/protected-data indicators, and next steps. A card that only describes workflow
    mechanics is incomplete.
36. Treat exposed workflow machinery, metadata-only screens, generic checklist cards, missing domain
    content, unclear information architecture, or visibly test-harness layouts as major or blocker UX
    findings, even when automated workflow tests pass.
37. Do not equate removal of forbidden workflow copy with production-ready UX. Treat generic demo
    scaffold styling, repeated workflow-card primary UX, checklist/review dialogs, weak visual
    hierarchy, thin placeholder content, missing community identity, clipped text, overlapping floating
    controls, and awkward technical labels as major or blocker UX findings when they materially lower
    the product below a modern shippable bar.
38. Primary workflows must be represented by real domain product surfaces where appropriate: community
    feeds, inbox items, detail pages, compose screens, event detail/RSVP flows, donation/payment flows,
    volunteer signup forms, care request forms, admin review screens, receipts/history, and receiver
    states. A generic card with improved labels is not enough when a real product would use a richer
    domain surface.
39. Before the independent product UX review can pass, create a per-community production UX blueprint
    that defines target personas, community identity, home information architecture, required product
    surfaces, workflow-to-surface mapping, realistic content requirements, visual/interaction standard,
    and concrete pass examples for every community/test app.
40. The independent product UX review must produce schema version 3 machine-readable evidence with
    review standard version, superseded prior run IDs, blueprint coverage, unique screen row IDs,
    screen-specific critiques, stable finding/remediation IDs, before/after screenshot references,
    unresolved severity counts, rerun requirements, and final pass/fail decision.
41. The independent product UX review must inventory every implemented user-facing screen, state,
    dialog, card, feed item, form, confirmation, error, empty state, persona variant, and action result.
    Every inventory row must have a screenshot reference, product-UX verdict, severity assessment,
    screen-specific findings, required fix or acceptance rationale, and retest result. Boilerplate
    matrix rows with the same generic pass rationale across unrelated screens are invalid evidence.
42. Do not pass the independent product UX review with unresolved blocker or major UX issues. Minor
    issues must be fixed, explicitly owner-accepted, or tracked with rationale before delivery.
43. B25 is an iterative remediation gate, not a terminal review. If the product UX review finds any
    blocker or major issue, group findings into remediation themes, implement fixes, rebuild and relaunch
    the visible Demo App, recapture screenshots, regenerate the screen review matrix, rerun the product
    UX review, and repeat until blocker and major counts are zero.
44. Every B25 remediation loop iteration must record the review result, fixes applied, tests run,
    screenshots refreshed, remaining findings, and pass/fail decision. Do not stop after producing a
    failed review unless the owner explicitly asks for review-only planning or pauses implementation.
45. Commit every B25 loop iteration before starting the next UX feedback or remediation loop. Each
    iteration commit must include the review/remediation evidence, refreshed screenshots or explicit
    screenshot references, tests run, remaining findings, and tracker update for that iteration.

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
2. Map each workflow to Loom APIs, extension-owned UI routes, rules/events, seed data, expected end
   state, test IDs, and screenshot evidence IDs.
3. Enumerate community personas/user roles, role grants, actor IDs, workflow initiators, workflow
   receivers, unauthorized personas, and expected hidden/disabled/read-only/receiving UI states.
4. Add or update tests before sideload/certification so each workflow can be exercised through the
   visible Demo App UI with the Local Backend.
5. Define evidence paths under the build plan evidence folder, using one screenshot bundle and one
   `workflow-ui-evidence.json` manifest per community or test app.
6. For any workflow involving more than one role, define multi-persona evidence IDs for the actor state,
   persona switch, and receiver/continuation state.
7. Build a workflow dependency graph that names prerequisite persona actions, generated records,
   receiving personas, and reset/idempotency requirements for every dependent workflow.
8. Create a per-persona test matrix with one row for every persona/workflow combination: authorized
   action, unauthorized action, hidden state, disabled state, read-only state, or receiving state.
9. Create a production workflow UX contract matrix with one row for every workflow/persona state. Include
   workflow category, real user goal, production screen sections, inputs, validation, semantic action
   labels, success/result state, receiver state, and screenshot evidence IDs.
10. Select the domain pattern for every workflow: event/RSVP, payment/donation/dues/ad-off,
    form/protected data, announcement/publishing/notification, approval/review, search/AI, export/import
    migration, messages/connections, ads, or shell/platform invariant.
11. Reject any planned workflow surface that is only a generic checklist, metadata view, global workflow
    list, or completion dialog. Produce a gap report instead of building from an incomplete UX contract.
12. Define the production information architecture for each community before implementation. The first
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
17. Create or update the per-community production UX blueprint for every community/test app and persona.
    The blueprint must define the target production experience before any B25 pass verdict is allowed.
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
23. Produce schema version 3 machine-readable review evidence with blueprint coverage, unique
    screen-row IDs, non-boilerplate critiques, stable finding/remediation IDs, screenshot references,
    unresolved severity counts, rerun requirements, and the final pass/fail decision.
24. If the product UX review fails with any blocker or major finding, start the B25 remediation loop:
    cluster findings by root cause, create a remediation batch, apply UX/content/code fixes, rebuild and
    relaunch the Demo App, recapture affected screenshots, rerun workflow and product UX evidence, and
    regenerate the screen review matrix. Commit that full iteration before starting the next UX
    feedback or correction loop.
25. Repeat the B25 remediation loop until the product UX review reports zero unresolved blocker or major
    findings and every screen matrix row passes, has an owner-accepted minor issue, or has tracked polish
    only.
26. Run affected widget/integration tests, workflow tests, manifest gate, phase gate, analysis, boundary
    lint, and diff check.

Do not mark `complete=true`, close a phase, certify, publish, or deliver local packages when any
workflow or persona/workflow row is untested, has missing screenshots, lacks prerequisite-chain
coverage, lacks backend parity checks, lacks persona/role capability evidence, lacks production UX
contract coverage, uses generic harness copy or exposed workflow machinery as the user experience, has
any implemented screen/state missing from the product UX screen review matrix, has unresolved blocker or
major independent product UX review findings, still looks like a generic demo scaffold rather than a
modern production product, has unresolved overlap/clipping/repetitive-card/checklist-modal/thin-content
issues ranked major or blocker, lacks a complete per-community production UX blueprint, lacks schema
version 3 machine-readable B25 review evidence, has not completed the B25 remediation loop after a
failed product UX review, lacks a final independent product UX pass decision, or is only represented by
metadata. Return a gap report and keep the package incomplete until all workflow, persona, production UX
blueprint, production UX evidence, B25 remediation-loop evidence, and independent product UX review
evidence is green.

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
- Map workflows with
  [references/workflow-api-mapping-template.md](./references/workflow-api-mapping-template.md).
- Apply UX methodology with
  [references/ux-methodology-template.md](./references/ux-methodology-template.md).
- Bootstrap or fetch source dependencies with
  [references/source-dependency-model.md](./references/source-dependency-model.md).

## Phase-Enriched Guides

- Component guides live under [components](./components).
- Workflow guides live under [workflows](./workflows).
- Worked examples live under [examples](./examples).
- Setup guides live under [setup](./setup).

This skeleton is created in Phase 0. Every later phase must enrich it before that phase can complete.
