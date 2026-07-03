# Remediation Tickets

| Field | Value |
| --- | --- |
| Tool | `production-ux-judge` |
| Status | `fail` |
| Open tickets | 14 |

## B25-RT-001-b25-c14-llm-vision-ux-review

| Field | Value |
| --- | --- |
| Severity | major |
| Priority | P1 |
| Status | open |
| Review run | `b25-v4-pass-42` |
| Source criterion | `b25-c14-llm-vision-ux-review` |
| Source findings |  |
| Title | LLM vision UX judge has inspected screenshots semantically |
| Direct question | Has a fresh LLM vision UX Judge inspected the actual screenshots as product UI, answered direct UX questions from visible evidence, and found no blocker or major product-quality issues? |
| Why it failed | The LLM vision UX review is missing holistic answers or screen reviews. |
| Required outcome | Run the B25 LLM Vision UX Judge Agent on the screenshot evidence, import its structured review, fix all blocker/major findings, and rerun B25. |
| Remediation mode | `review-only` |
| Worker readiness | no concrete implementation work item was generated; planner must inspect the direct-question failure before assigning a worker |
| First required step | Review failing direct questions and add screen/workflow/persona-specific evidence before implementation. |

### Problem Statement

The current B25 pass lacks a passing fresh-context LLM vision UX judgment, or that judgment found major product-quality issues in the screenshots.

### Root Cause Hypothesis

The previous B25 gate let deterministic absence-of-known-defects stand in for semantic visual/product review. The visible screenshots still need a fresh LLM judge to inspect pixels, layout, content, and product fit.

### Target Experience

A fresh LLM vision UX judge should be able to inspect the screenshots and state, from visible UI evidence, that the experience is modern, domain-native, and production-grade with no unresolved blocker or major findings.

### UX Principles
- Semantic product-quality judgment must come from screenshot inspection, not deterministic keyword absence
- A production UX pass needs visible proof that screens feel modern, domain-native, and useful to the target persona
- LLM reviewer findings are blocking inputs to the normal B25 ticket and remediation loop

### Concrete Improvements
- Use the LLM vision judge screen reviews as the source of truth for what visually failed.
- Replace any screenshot-identified workflow/test-harness surfaces with domain-native product surfaces.
- Fix all LLM-UX blocker/major findings, recapture screenshots, import a new LLM review artifact, and rerun the production judge.

### Implementation Guidance
- Treat the imported LLM vision review as the independent semantic critique.
- Prioritize screen rows and workflows named in `llmVisionReview.findings` and `llmVisionReview.screenReviews`.
- Do not close the ticket until a fresh LLM vision review over after-screenshots passes.

### Content Guidance
- Write copy that matches the task: RSVP, donate, publish, approve, submit, review, search, export, transfer, invite, or reply.
- Each primary surface should include the domain data a user needs to decide and act.
- Use explicit alternate action copy such as Decline, Request changes, Change response, Edit, Withdraw, Cancel RSVP, Archive, Retry, Roll back, or Manage where the lifecycle requires it.
- Use result copy that persists: Sent, Posted, Confirmed, Paid, Receipt ready, Submitted, Approved, Rejected, Claimed, Returned, Read, or equivalent domain state.

### Visual Guidance
- Check hierarchy: page title, section headings, primary actions, secondary metadata, and result states should be visually distinct.
- Check spacing and density on mobile: avoid crowded repeated cards, clipped text, overlapping controls, and weak touch targets.
- Use consistent component styling and avoid default scaffold or test-harness appearance.

### Source Research Requirement

The independent UX review must attach internet or open-source pattern references before UI remediation. If live research is unavailable, use the bundled catalog entries and keep the research queries in the ticket so a reviewer can refresh them.

### UX Reference Patterns To Copy

| Reference | Source | URL | What to copy |
| --- | --- | --- | --- |
| Material navigation and information architecture | Material Design 3 / design-system | https://m3.material.io/components/navigation-drawer/overview<br>Also: https://m3.material.io/components/navigation-bar/overview | Organize screens by user jobs and destinations; keep primary actions visible and avoid exposing implementation taxonomy. |
| Apple HIG navigation and content organization | Apple Human Interface Guidelines / design-system | https://developer.apple.com/design/human-interface-guidelines/navigation | Make navigation predictable, content-centered, and appropriate for the user’s current task. |
| Material Design cards and lists | Material Design 3 / design-system | https://m3.material.io/components/cards/overview<br>Also: https://m3.material.io/components/lists/overview | Use cards/lists only as scannable containers with clear hierarchy, content, metadata, and actions. Do not use repeated cards as the whole primary workflow. |
| Flutter sample app implementation patterns | flutter/samples / open-source | https://github.com/flutter/samples | Copy the separation between app shell, route state, domain widgets, and testable UI states rather than hardcoding a single generic renderer. |

### Reference Research Queries
- production mobile UX review screenshot critique examples
- open source Flutter mobile app UX patterns GitHub

### Implementation Blocked By
- The ticket lacks row-level implementation evidence.

### Likely Files / Widgets
- `app/apps/loom_communities_demo/lib/main.dart`
- `app/apps/loom_communities_demo/test/b21_b25_production_ux_test.dart`
- `docs/Build Plan V2/Evidence/B25/production-ux-blueprint.md`
- `docs/Build Plan V2/Evidence/B25/independent-production-ux-review.json`
- `docs/Build Plan V2/Evidence/B25/product-ux-screen-review-matrix.md`

### Concrete Acceptance Criteria
- `production_ux_judge.dart` has no blocking failure for this criterion.
- `b25_iteration_scorecard.dart` records the ticket as resolved or no longer blocking.
- Screenshots are refreshed and hashes/timestamps/app commit SHA match the reviewed app version.

### Affected Evidence
- `independent-production-ux-review.json llmVisionReview`
- `independent-production-ux-review.json findings from source=llm-vision-ux-judge`
- `product-ux-screen-review-matrix.md affected screen rows`
- `production-ux-criteria-scorecard.json/.md`

### Evidence To Collect
- Fresh holistic screenshots for primary homes, navigation, representative detail surfaces, and representative completion/result states.
- `holisticQuestionAnswers` with visible evidence, score, pass/fail answer, and specific rationale.
- `llmVisionReview` imported from a fresh LLM vision UX judge run against the after screenshots.
- Updated `production-ux-criteria-scorecard.json/.md` showing the criterion passes.

### Acceptance Checks
- `production_ux_judge.dart` has no blocking failure for this criterion.
- `b25_iteration_scorecard.dart` records the ticket as resolved or no longer blocking.
- Screenshots are refreshed and hashes/timestamps/app commit SHA match the reviewed app version.

### Non-Goals
- Do not close the ticket without fresh evidence and a passing judge rerun.

### Commit Boundary

Commit this remediation iteration, refreshed evidence, scorecards, tickets, and tracker updates before starting the next UX feedback loop.

### Rerun Commands
- `dart run packages/tooling/loom_ux_judges/bin/b25_capture_workflow_screenshots.dart --mode full-b25 --device emulator-5554 --evidence-root ../docs/Build\ Plan\ V2/Evidence`
- `dart run packages/tooling/loom_ux_judges/bin/b25_capture_coverage_gate.dart --evidence-root ../docs/Build\ Plan\ V2/Evidence --output ../docs/Build\ Plan\ V2/Evidence/B25/b25-capture-coverage-report.json`
- `dart run packages/tooling/loom_ux_judges/bin/b25_evidence_collector.dart --evidence-root ../docs/Build\ Plan\ V2/Evidence --repo-root .. --run-id <next-run-id> --prior-review ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --output ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.md --matrix-output ../docs/Build\ Plan\ V2/Evidence/B25/product-ux-screen-review-matrix.md`
- `dart run packages/tooling/loom_ux_judges/bin/b25_workflow_persona_coverage_collector.dart --input ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --output ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/workflow-persona-coverage-matrix.md`
- `dart run packages/tooling/loom_ux_judges/bin/b25_independent_ux_judge.dart --input ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --output ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.md --matrix-output ../docs/Build\ Plan\ V2/Evidence/B25/product-ux-screen-review-matrix.md`
- `dart run packages/tooling/loom_ux_judges/bin/b25_component_doc_context.dart --repo-root .. --output ../docs/Build\ Plan\ V2/Evidence/B25/b25-component-doc-context-<next-run-id>.json --markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/b25-component-doc-context-<next-run-id>.md`
- `dart run packages/tooling/loom_ux_judges/bin/production_ux_judge.dart --input ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --base .. --output ../docs/Build\ Plan\ V2/Evidence/B25/production-ux-criteria-scorecard.json --markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/production-ux-criteria-scorecard.md --tickets-output ../docs/Build\ Plan\ V2/Evidence/B25/b25-remediation-tickets-<next-run-id>.json --tickets-markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/b25-remediation-tickets-<next-run-id>.md`
- `dart run packages/tooling/loom_ux_judges/bin/b25_iteration_scorecard.dart --review ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --judge ../docs/Build\ Plan\ V2/Evidence/B25/production-ux-criteria-scorecard.json --previous ../docs/Build\ Plan\ V2/Evidence/B25/b25-iteration-scorecard-latest.json --output ../docs/Build\ Plan\ V2/Evidence/B25/b25-iteration-scorecard-latest.json --markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/b25-iteration-scorecard-latest.md`

## B25-RT-002-app-shell-tabs-gap

| Field | Value |
| --- | --- |
| Severity | major |
| Priority | P1 |
| Status | open |
| Review run | `b25-v4-pass-42` |
| Source criterion | `b25-c16-app-shell-capability-utilization` |
| Source findings | B25-APP-SHELL-loom-communities-shell-persona-tabspass |
| Title | App Shell capability failed: tabsPass |
| Direct question | Do screenshots prove the persona sees the right Home, Messages/Communication, and custom tabs for their job-to-be-done? |
| Why it failed | Community `Loom Communities shell` persona `persona` does not prove `tabsPass` from screenshot evidence. |
| Required outcome | Update the product doc or UI, recapture after-screenshots, and regenerate appShellCapabilityReview so `tabsPass` passes from visible evidence. |
| Remediation mode | `review-only` |
| Worker readiness | no concrete implementation work item was generated; planner must inspect the direct-question failure before assigning a worker |
| First required step | Review failing direct questions and add screen/workflow/persona-specific evidence before implementation. |

### Problem Statement

Community `Loom Communities shell` persona `persona` does not prove `tabsPass` from screenshot evidence.

### Root Cause Hypothesis

The evidence does not yet satisfy the B25 production UX standard.

### Target Experience

Each persona sees a tab model that matches their community jobs. Home and Messages/Communication are always available, and optional tabs are named, ordered, and scoped to the persona.

### UX Principles
- Resolve blocking UX evidence before closing B25

### Concrete Improvements
- Declare persona-specific tabs in the community product experience doc.
- Keep Home and Messages/Communication available for every persona.
- Recapture screenshots showing tab labels, order, persona visibility, selected state, and destination content.

### Implementation Guidance
- Use `CommunityAppShellCustomizationSpec`, `LoomAppShellTabSpec`, and `LoomThemeCustomizationTokens` in `apps/loom_communities_demo/lib/main.dart`.
- Implement the capability centrally in the App Shell model, not as a one-off workflow widget hack.
- Recapture screenshots after implementation; source code alone cannot close this ticket.
- Inspect `apps/loom_communities_demo/lib/main.dart` for `CommunityAppShellCustomizationSpec`, persona tab specs, pinned surface specs, presentation-state routing, renderer selection, and theme/typography/density tokens.
- Update the community product experience doc Section 3.1 when the intended tab/pinning/presentation/customization model is missing or vague.
- Implement the missing App Shell capability in the central shell model, not as a one-off workflow hack.
- Recapture screenshots proving Home and Messages/Communication tabs, custom persona tabs, declared pinned surfaces, minimized/medium/expanded states, tap-to-expand, community-list states, renderer selection, and theme/customization tokens where required.

### Content Guidance
- Write copy that matches the task: RSVP, donate, publish, approve, submit, review, search, export, transfer, invite, or reply.
- Each primary surface should include the domain data a user needs to decide and act.
- Use explicit alternate action copy such as Decline, Request changes, Change response, Edit, Withdraw, Cancel RSVP, Archive, Retry, Roll back, or Manage where the lifecycle requires it.
- Use result copy that persists: Sent, Posted, Confirmed, Paid, Receipt ready, Submitted, Approved, Rejected, Claimed, Returned, Read, or equivalent domain state.

### Visual Guidance
- Use screenshot evidence to judge visual hierarchy, density, navigation clarity, and polish on the reviewed device.

### Source Research Requirement

The independent UX review must attach internet or open-source pattern references before UI remediation. If live research is unavailable, use the bundled catalog entries and keep the research queries in the ticket so a reviewer can refresh them.

### UX Reference Patterns To Copy

| Reference | Source | URL | What to copy |
| --- | --- | --- | --- |
| Material navigation and information architecture | Material Design 3 / design-system | https://m3.material.io/components/navigation-drawer/overview<br>Also: https://m3.material.io/components/navigation-bar/overview | Organize screens by user jobs and destinations; keep primary actions visible and avoid exposing implementation taxonomy. |
| Apple HIG navigation and content organization | Apple Human Interface Guidelines / design-system | https://developer.apple.com/design/human-interface-guidelines/navigation | Make navigation predictable, content-centered, and appropriate for the user’s current task. |
| Material Design cards and lists | Material Design 3 / design-system | https://m3.material.io/components/cards/overview<br>Also: https://m3.material.io/components/lists/overview | Use cards/lists only as scannable containers with clear hierarchy, content, metadata, and actions. Do not use repeated cards as the whole primary workflow. |
| Flutter sample app implementation patterns | flutter/samples / open-source | https://github.com/flutter/samples | Copy the separation between app shell, route state, domain widgets, and testable UI states rather than hardcoding a single generic renderer. |

### Reference Research Queries
- production mobile UX review screenshot critique examples
- open source Flutter mobile app UX patterns GitHub

### Implementation Blocked By
- The ticket lacks row-level implementation evidence.

### Likely Files / Widgets
- `app/apps/loom_communities_demo/lib/main.dart`
- `app/apps/loom_communities_demo/test/b21_b25_production_ux_test.dart`
- `docs/Build Plan V2/Evidence/B25/production-ux-blueprint.md`
- `docs/Build Plan V2/Evidence/B25/independent-production-ux-review.json`
- `docs/Build Plan V2/Evidence/B25/product-ux-screen-review-matrix.md`

### Concrete Acceptance Criteria
- Screenshots prove Home and Messages/Communication tabs are available.
- Custom persona tabs are visible only where appropriate and route to relevant content.
- `appShellCapabilityReview.communityResults[]` has `tabsPass=true`.
- `appShellCapabilityReview.status` is `pass`.
- `appShellCapabilityReview.missingCapabilities` is empty.
- Every `appShellCapabilityReview.communityResults[]` row has passing tabs, explicit and appropriate pinning policy, presentation states, community-list states, theme customization, and renderer-selection checks where applicable.
- After-screenshots prove the shell capability in the affected community/persona/workflow, not only source-code declarations.
- `production_ux_judge.dart` has no blocking failure for this criterion.
- `b25_iteration_scorecard.dart` records the ticket as resolved or no longer blocking.
- Screenshots are refreshed and hashes/timestamps/app commit SHA match the reviewed app version.

### Affected Evidence
- `independent-production-ux-review.json appShellCapabilityReview`
- `llm-product-doc-workflow-reconciliation-<run-id>.json appShellCapabilityReview`
- `llm-product-doc-workflow-reconciliation-<run-id>.json reviewedComponentDocPaths and componentDocReview.docs`
- `docs/Product Docs V2/Community Examples/<community>-product-experience.md Section 3.1`
- `docs/Build Plan V2/Skill/components/card-surfaces/app-shell-navigation-theming.md`
- `docs/Build Plan V2/Skill/components/card-surfaces/tab-renderer-contracts.md`
- `product-ux-screen-review-matrix.md affected screen rows and screenshots`
- `production-ux-criteria-scorecard.json/.md`

### Evidence To Collect
- Updated review JSON, scorecards, screenshots, remediation log, and tracker evidence for the fixed criterion.

### Acceptance Checks
- Screenshots prove Home and Messages/Communication tabs are available.
- Custom persona tabs are visible only where appropriate and route to relevant content.
- `appShellCapabilityReview.communityResults[]` has `tabsPass=true`.
- `appShellCapabilityReview.status` is `pass`.
- `appShellCapabilityReview.missingCapabilities` is empty.
- Every `appShellCapabilityReview.communityResults[]` row has passing tabs, explicit and appropriate pinning policy, presentation states, community-list states, theme customization, and renderer-selection checks where applicable.
- After-screenshots prove the shell capability in the affected community/persona/workflow, not only source-code declarations.
- `production_ux_judge.dart` has no blocking failure for this criterion.
- `b25_iteration_scorecard.dart` records the ticket as resolved or no longer blocking.
- Screenshots are refreshed and hashes/timestamps/app commit SHA match the reviewed app version.

### Non-Goals
- Do not close the ticket without fresh evidence and a passing judge rerun.

### Commit Boundary

Commit this remediation iteration, refreshed evidence, scorecards, tickets, and tracker updates before starting the next UX feedback loop.

### Rerun Commands
- `dart run packages/tooling/loom_ux_judges/bin/b25_capture_workflow_screenshots.dart --mode full-b25 --device emulator-5554 --evidence-root ../docs/Build\ Plan\ V2/Evidence`
- `dart run packages/tooling/loom_ux_judges/bin/b25_capture_coverage_gate.dart --evidence-root ../docs/Build\ Plan\ V2/Evidence --output ../docs/Build\ Plan\ V2/Evidence/B25/b25-capture-coverage-report.json`
- `dart run packages/tooling/loom_ux_judges/bin/b25_evidence_collector.dart --evidence-root ../docs/Build\ Plan\ V2/Evidence --repo-root .. --run-id <next-run-id> --prior-review ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --output ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.md --matrix-output ../docs/Build\ Plan\ V2/Evidence/B25/product-ux-screen-review-matrix.md`
- `dart run packages/tooling/loom_ux_judges/bin/b25_workflow_persona_coverage_collector.dart --input ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --output ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/workflow-persona-coverage-matrix.md`
- `dart run packages/tooling/loom_ux_judges/bin/b25_independent_ux_judge.dart --input ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --output ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.md --matrix-output ../docs/Build\ Plan\ V2/Evidence/B25/product-ux-screen-review-matrix.md`
- `dart run packages/tooling/loom_ux_judges/bin/b25_component_doc_context.dart --repo-root .. --output ../docs/Build\ Plan\ V2/Evidence/B25/b25-component-doc-context-<next-run-id>.json --markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/b25-component-doc-context-<next-run-id>.md`
- `dart run packages/tooling/loom_ux_judges/bin/production_ux_judge.dart --input ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --base .. --output ../docs/Build\ Plan\ V2/Evidence/B25/production-ux-criteria-scorecard.json --markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/production-ux-criteria-scorecard.md --tickets-output ../docs/Build\ Plan\ V2/Evidence/B25/b25-remediation-tickets-<next-run-id>.json --tickets-markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/b25-remediation-tickets-<next-run-id>.md`
- `dart run packages/tooling/loom_ux_judges/bin/b25_iteration_scorecard.dart --review ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --judge ../docs/Build\ Plan\ V2/Evidence/B25/production-ux-criteria-scorecard.json --previous ../docs/Build\ Plan\ V2/Evidence/B25/b25-iteration-scorecard-latest.json --output ../docs/Build\ Plan\ V2/Evidence/B25/b25-iteration-scorecard-latest.json --markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/b25-iteration-scorecard-latest.md`

## B25-RT-003-app-shell-presentation-state-gap

| Field | Value |
| --- | --- |
| Severity | major |
| Priority | P1 |
| Status | open |
| Review run | `b25-v4-pass-42` |
| Source criterion | `b25-c16-app-shell-capability-utilization` |
| Source findings | B25-APP-SHELL-loom-communities-shell-persona-presentationstatespass |
| Title | App Shell capability failed: presentationStatesPass |
| Direct question | Do screenshots prove minimized off-focus surfaces, the medium in-focus surface, and tap-to-expand behavior for the same workflow/persona? |
| Why it failed | Community `Loom Communities shell` persona `persona` does not prove `presentationStatesPass` from screenshot evidence. |
| Required outcome | Update the product doc or UI, recapture after-screenshots, and regenerate appShellCapabilityReview so `presentationStatesPass` passes from visible evidence. |
| Remediation mode | `review-only` |
| Worker readiness | no concrete implementation work item was generated; planner must inspect the direct-question failure before assigning a worker |
| First required step | Review failing direct questions and add screen/workflow/persona-specific evidence before implementation. |

### Problem Statement

Community `Loom Communities shell` persona `persona` does not prove `presentationStatesPass` from screenshot evidence.

### Root Cause Hypothesis

The evidence does not yet satisfy the B25 production UX standard.

### Target Experience

Cards behave like a modern focused surface stack: the first visible item is medium, off-focus items are minimized, and tapping expands the selected product surface.

### UX Principles
- Resolve blocking UX evidence before closing B25

### Concrete Improvements
- Implement or expose minimized, medium/in-focus, and expanded states for the affected surface.
- Capture before/after screenshots that show the same workflow/persona in minimized, medium, and expanded states.
- Ensure the expanded state is a richer product surface, not only a larger copy of the same generic card.

### Implementation Guidance
- Use `CommunityAppShellCustomizationSpec`, `LoomAppShellTabSpec`, and `LoomThemeCustomizationTokens` in `apps/loom_communities_demo/lib/main.dart`.
- Implement the capability centrally in the App Shell model, not as a one-off workflow widget hack.
- Recapture screenshots after implementation; source code alone cannot close this ticket.
- Verify scroll-driven focus sets the active surface to medium and off-focus surfaces to minimized.
- Verify tapping a medium or minimized surface expands it and tapping collapse returns it to the focused stack.

### Content Guidance
- Write copy that matches the task: RSVP, donate, publish, approve, submit, review, search, export, transfer, invite, or reply.
- Each primary surface should include the domain data a user needs to decide and act.
- Use explicit alternate action copy such as Decline, Request changes, Change response, Edit, Withdraw, Cancel RSVP, Archive, Retry, Roll back, or Manage where the lifecycle requires it.
- Use result copy that persists: Sent, Posted, Confirmed, Paid, Receipt ready, Submitted, Approved, Rejected, Claimed, Returned, Read, or equivalent domain state.

### Visual Guidance
- Use screenshot evidence to judge visual hierarchy, density, navigation clarity, and polish on the reviewed device.

### Source Research Requirement

The independent UX review must attach internet or open-source pattern references before UI remediation. If live research is unavailable, use the bundled catalog entries and keep the research queries in the ticket so a reviewer can refresh them.

### UX Reference Patterns To Copy

| Reference | Source | URL | What to copy |
| --- | --- | --- | --- |
| Material navigation and information architecture | Material Design 3 / design-system | https://m3.material.io/components/navigation-drawer/overview<br>Also: https://m3.material.io/components/navigation-bar/overview | Organize screens by user jobs and destinations; keep primary actions visible and avoid exposing implementation taxonomy. |
| Apple HIG navigation and content organization | Apple Human Interface Guidelines / design-system | https://developer.apple.com/design/human-interface-guidelines/navigation | Make navigation predictable, content-centered, and appropriate for the user’s current task. |
| Material Design cards and lists | Material Design 3 / design-system | https://m3.material.io/components/cards/overview<br>Also: https://m3.material.io/components/lists/overview | Use cards/lists only as scannable containers with clear hierarchy, content, metadata, and actions. Do not use repeated cards as the whole primary workflow. |
| Flutter sample app implementation patterns | flutter/samples / open-source | https://github.com/flutter/samples | Copy the separation between app shell, route state, domain widgets, and testable UI states rather than hardcoding a single generic renderer. |

### Reference Research Queries
- production mobile UX review screenshot critique examples
- open source Flutter mobile app UX patterns GitHub

### Implementation Blocked By
- The ticket lacks row-level implementation evidence.

### Likely Files / Widgets
- `app/apps/loom_communities_demo/lib/main.dart`
- `app/apps/loom_communities_demo/test/b21_b25_production_ux_test.dart`
- `docs/Build Plan V2/Evidence/B25/production-ux-blueprint.md`
- `docs/Build Plan V2/Evidence/B25/independent-production-ux-review.json`
- `docs/Build Plan V2/Evidence/B25/product-ux-screen-review-matrix.md`

### Concrete Acceptance Criteria
- After-screenshots show minimized, medium/in-focus, and expanded states for the affected workflow/persona.
- The expanded screenshot shows a richer product surface or action detail than the minimized state.
- The affected `appShellCapabilityReview.communityResults[]` row has `presentationStatesPass=true`.
- `appShellCapabilityReview.status` is `pass`.
- `appShellCapabilityReview.missingCapabilities` is empty.
- Every `appShellCapabilityReview.communityResults[]` row has passing tabs, explicit and appropriate pinning policy, presentation states, community-list states, theme customization, and renderer-selection checks where applicable.
- After-screenshots prove the shell capability in the affected community/persona/workflow, not only source-code declarations.
- `production_ux_judge.dart` has no blocking failure for this criterion.
- `b25_iteration_scorecard.dart` records the ticket as resolved or no longer blocking.
- Screenshots are refreshed and hashes/timestamps/app commit SHA match the reviewed app version.

### Affected Evidence
- `independent-production-ux-review.json appShellCapabilityReview`
- `llm-product-doc-workflow-reconciliation-<run-id>.json appShellCapabilityReview`
- `llm-product-doc-workflow-reconciliation-<run-id>.json reviewedComponentDocPaths and componentDocReview.docs`
- `docs/Product Docs V2/Community Examples/<community>-product-experience.md Section 3.1`
- `docs/Build Plan V2/Skill/components/card-surfaces/app-shell-navigation-theming.md`
- `docs/Build Plan V2/Skill/components/card-surfaces/tab-renderer-contracts.md`
- `product-ux-screen-review-matrix.md affected screen rows and screenshots`
- `production-ux-criteria-scorecard.json/.md`

### Evidence To Collect
- Updated review JSON, scorecards, screenshots, remediation log, and tracker evidence for the fixed criterion.

### Acceptance Checks
- After-screenshots show minimized, medium/in-focus, and expanded states for the affected workflow/persona.
- The expanded screenshot shows a richer product surface or action detail than the minimized state.
- The affected `appShellCapabilityReview.communityResults[]` row has `presentationStatesPass=true`.
- `appShellCapabilityReview.status` is `pass`.
- `appShellCapabilityReview.missingCapabilities` is empty.
- Every `appShellCapabilityReview.communityResults[]` row has passing tabs, explicit and appropriate pinning policy, presentation states, community-list states, theme customization, and renderer-selection checks where applicable.
- After-screenshots prove the shell capability in the affected community/persona/workflow, not only source-code declarations.
- `production_ux_judge.dart` has no blocking failure for this criterion.
- `b25_iteration_scorecard.dart` records the ticket as resolved or no longer blocking.
- Screenshots are refreshed and hashes/timestamps/app commit SHA match the reviewed app version.

### Non-Goals
- Do not close the ticket without fresh evidence and a passing judge rerun.

### Commit Boundary

Commit this remediation iteration, refreshed evidence, scorecards, tickets, and tracker updates before starting the next UX feedback loop.

### Rerun Commands
- `dart run packages/tooling/loom_ux_judges/bin/b25_capture_workflow_screenshots.dart --mode full-b25 --device emulator-5554 --evidence-root ../docs/Build\ Plan\ V2/Evidence`
- `dart run packages/tooling/loom_ux_judges/bin/b25_capture_coverage_gate.dart --evidence-root ../docs/Build\ Plan\ V2/Evidence --output ../docs/Build\ Plan\ V2/Evidence/B25/b25-capture-coverage-report.json`
- `dart run packages/tooling/loom_ux_judges/bin/b25_evidence_collector.dart --evidence-root ../docs/Build\ Plan\ V2/Evidence --repo-root .. --run-id <next-run-id> --prior-review ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --output ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.md --matrix-output ../docs/Build\ Plan\ V2/Evidence/B25/product-ux-screen-review-matrix.md`
- `dart run packages/tooling/loom_ux_judges/bin/b25_workflow_persona_coverage_collector.dart --input ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --output ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/workflow-persona-coverage-matrix.md`
- `dart run packages/tooling/loom_ux_judges/bin/b25_independent_ux_judge.dart --input ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --output ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.md --matrix-output ../docs/Build\ Plan\ V2/Evidence/B25/product-ux-screen-review-matrix.md`
- `dart run packages/tooling/loom_ux_judges/bin/b25_component_doc_context.dart --repo-root .. --output ../docs/Build\ Plan\ V2/Evidence/B25/b25-component-doc-context-<next-run-id>.json --markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/b25-component-doc-context-<next-run-id>.md`
- `dart run packages/tooling/loom_ux_judges/bin/production_ux_judge.dart --input ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --base .. --output ../docs/Build\ Plan\ V2/Evidence/B25/production-ux-criteria-scorecard.json --markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/production-ux-criteria-scorecard.md --tickets-output ../docs/Build\ Plan\ V2/Evidence/B25/b25-remediation-tickets-<next-run-id>.json --tickets-markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/b25-remediation-tickets-<next-run-id>.md`
- `dart run packages/tooling/loom_ux_judges/bin/b25_iteration_scorecard.dart --review ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --judge ../docs/Build\ Plan\ V2/Evidence/B25/production-ux-criteria-scorecard.json --previous ../docs/Build\ Plan\ V2/Evidence/B25/b25-iteration-scorecard-latest.json --output ../docs/Build\ Plan\ V2/Evidence/B25/b25-iteration-scorecard-latest.json --markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/b25-iteration-scorecard-latest.md`

## B25-RT-004-app-shell-community-card-state-gap

| Field | Value |
| --- | --- |
| Severity | major |
| Priority | P1 |
| Status | open |
| Review run | `b25-v4-pass-42` |
| Source criterion | `b25-c16-app-shell-capability-utilization` |
| Source findings | B25-APP-SHELL-loom-communities-shell-persona-maincommunitycardstatespass |
| Title | App Shell capability failed: mainCommunityCardStatesPass |
| Direct question | Does the main Loom Communities list show modern community launch cards with minimized/medium states, theme customization, and tap-to-open behavior? |
| Why it failed | Community `Loom Communities shell` persona `persona` does not prove `mainCommunityCardStatesPass` from screenshot evidence. |
| Required outcome | Update the product doc or UI, recapture after-screenshots, and regenerate appShellCapabilityReview so `mainCommunityCardStatesPass` passes from visible evidence. |
| Remediation mode | `review-only` |
| Worker readiness | no concrete implementation work item was generated; planner must inspect the direct-question failure before assigning a worker |
| First required step | Review failing direct questions and add screen/workflow/persona-specific evidence before implementation. |

### Problem Statement

Community `Loom Communities shell` persona `persona` does not prove `mainCommunityCardStatesPass` from screenshot evidence.

### Root Cause Hypothesis

The evidence does not yet satisfy the B25 production UX standard.

### Target Experience

The main community picker uses branded launch cards with clear hierarchy, minimized/medium focus states, and tap-to-open behavior instead of a flat generic list.

### UX Principles
- Resolve blocking UX evidence before closing B25

### Concrete Improvements
- Add main community selection evidence to B25 coverage.
- Show one in-focus medium community launch card and off-focus minimized community cards.
- Apply community-specific theme/typography tokens to launch cards while preserving readability and tap targets.

### Implementation Guidance
- Use `CommunityAppShellCustomizationSpec`, `LoomAppShellTabSpec`, and `LoomThemeCustomizationTokens` in `apps/loom_communities_demo/lib/main.dart`.
- Implement the capability centrally in the App Shell model, not as a one-off workflow widget hack.
- Recapture screenshots after implementation; source code alone cannot close this ticket.
- Extend B25 evidence to include the main Loom Communities selection screen.
- Prove community card focus states and tap-to-open behavior from screenshots, not only widget tests.

### Content Guidance
- Write copy that matches the task: RSVP, donate, publish, approve, submit, review, search, export, transfer, invite, or reply.
- Each primary surface should include the domain data a user needs to decide and act.
- Use explicit alternate action copy such as Decline, Request changes, Change response, Edit, Withdraw, Cancel RSVP, Archive, Retry, Roll back, or Manage where the lifecycle requires it.
- Use result copy that persists: Sent, Posted, Confirmed, Paid, Receipt ready, Submitted, Approved, Rejected, Claimed, Returned, Read, or equivalent domain state.

### Visual Guidance
- Use screenshot evidence to judge visual hierarchy, density, navigation clarity, and polish on the reviewed device.

### Source Research Requirement

The independent UX review must attach internet or open-source pattern references before UI remediation. If live research is unavailable, use the bundled catalog entries and keep the research queries in the ticket so a reviewer can refresh them.

### UX Reference Patterns To Copy

| Reference | Source | URL | What to copy |
| --- | --- | --- | --- |
| Material navigation and information architecture | Material Design 3 / design-system | https://m3.material.io/components/navigation-drawer/overview<br>Also: https://m3.material.io/components/navigation-bar/overview | Organize screens by user jobs and destinations; keep primary actions visible and avoid exposing implementation taxonomy. |
| Apple HIG navigation and content organization | Apple Human Interface Guidelines / design-system | https://developer.apple.com/design/human-interface-guidelines/navigation | Make navigation predictable, content-centered, and appropriate for the user’s current task. |
| Material Design cards and lists | Material Design 3 / design-system | https://m3.material.io/components/cards/overview<br>Also: https://m3.material.io/components/lists/overview | Use cards/lists only as scannable containers with clear hierarchy, content, metadata, and actions. Do not use repeated cards as the whole primary workflow. |
| Flutter sample app implementation patterns | flutter/samples / open-source | https://github.com/flutter/samples | Copy the separation between app shell, route state, domain widgets, and testable UI states rather than hardcoding a single generic renderer. |

### Reference Research Queries
- production mobile UX review screenshot critique examples
- open source Flutter mobile app UX patterns GitHub

### Implementation Blocked By
- The ticket lacks row-level implementation evidence.

### Likely Files / Widgets
- `app/apps/loom_communities_demo/lib/main.dart`
- `app/apps/loom_communities_demo/test/b21_b25_production_ux_test.dart`
- `docs/Build Plan V2/Evidence/B25/production-ux-blueprint.md`
- `docs/Build Plan V2/Evidence/B25/independent-production-ux-review.json`
- `docs/Build Plan V2/Evidence/B25/product-ux-screen-review-matrix.md`

### Concrete Acceptance Criteria
- B25 evidence includes the main Loom Communities selection screen.
- Screenshots prove a medium in-focus launch card, minimized off-focus cards, and tap-to-open behavior.
- Community launch cards visibly use community theme/typography tokens.
- `appShellCapabilityReview.status` is `pass`.
- `appShellCapabilityReview.missingCapabilities` is empty.
- Every `appShellCapabilityReview.communityResults[]` row has passing tabs, explicit and appropriate pinning policy, presentation states, community-list states, theme customization, and renderer-selection checks where applicable.
- After-screenshots prove the shell capability in the affected community/persona/workflow, not only source-code declarations.
- `production_ux_judge.dart` has no blocking failure for this criterion.
- `b25_iteration_scorecard.dart` records the ticket as resolved or no longer blocking.
- Screenshots are refreshed and hashes/timestamps/app commit SHA match the reviewed app version.

### Affected Evidence
- `independent-production-ux-review.json appShellCapabilityReview`
- `llm-product-doc-workflow-reconciliation-<run-id>.json appShellCapabilityReview`
- `llm-product-doc-workflow-reconciliation-<run-id>.json reviewedComponentDocPaths and componentDocReview.docs`
- `docs/Product Docs V2/Community Examples/<community>-product-experience.md Section 3.1`
- `docs/Build Plan V2/Skill/components/card-surfaces/app-shell-navigation-theming.md`
- `docs/Build Plan V2/Skill/components/card-surfaces/tab-renderer-contracts.md`
- `product-ux-screen-review-matrix.md affected screen rows and screenshots`
- `production-ux-criteria-scorecard.json/.md`

### Evidence To Collect
- Updated review JSON, scorecards, screenshots, remediation log, and tracker evidence for the fixed criterion.

### Acceptance Checks
- B25 evidence includes the main Loom Communities selection screen.
- Screenshots prove a medium in-focus launch card, minimized off-focus cards, and tap-to-open behavior.
- Community launch cards visibly use community theme/typography tokens.
- `appShellCapabilityReview.status` is `pass`.
- `appShellCapabilityReview.missingCapabilities` is empty.
- Every `appShellCapabilityReview.communityResults[]` row has passing tabs, explicit and appropriate pinning policy, presentation states, community-list states, theme customization, and renderer-selection checks where applicable.
- After-screenshots prove the shell capability in the affected community/persona/workflow, not only source-code declarations.
- `production_ux_judge.dart` has no blocking failure for this criterion.
- `b25_iteration_scorecard.dart` records the ticket as resolved or no longer blocking.
- Screenshots are refreshed and hashes/timestamps/app commit SHA match the reviewed app version.

### Non-Goals
- Do not close the ticket without fresh evidence and a passing judge rerun.

### Commit Boundary

Commit this remediation iteration, refreshed evidence, scorecards, tickets, and tracker updates before starting the next UX feedback loop.

### Rerun Commands
- `dart run packages/tooling/loom_ux_judges/bin/b25_capture_workflow_screenshots.dart --mode full-b25 --device emulator-5554 --evidence-root ../docs/Build\ Plan\ V2/Evidence`
- `dart run packages/tooling/loom_ux_judges/bin/b25_capture_coverage_gate.dart --evidence-root ../docs/Build\ Plan\ V2/Evidence --output ../docs/Build\ Plan\ V2/Evidence/B25/b25-capture-coverage-report.json`
- `dart run packages/tooling/loom_ux_judges/bin/b25_evidence_collector.dart --evidence-root ../docs/Build\ Plan\ V2/Evidence --repo-root .. --run-id <next-run-id> --prior-review ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --output ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.md --matrix-output ../docs/Build\ Plan\ V2/Evidence/B25/product-ux-screen-review-matrix.md`
- `dart run packages/tooling/loom_ux_judges/bin/b25_workflow_persona_coverage_collector.dart --input ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --output ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/workflow-persona-coverage-matrix.md`
- `dart run packages/tooling/loom_ux_judges/bin/b25_independent_ux_judge.dart --input ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --output ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.md --matrix-output ../docs/Build\ Plan\ V2/Evidence/B25/product-ux-screen-review-matrix.md`
- `dart run packages/tooling/loom_ux_judges/bin/b25_component_doc_context.dart --repo-root .. --output ../docs/Build\ Plan\ V2/Evidence/B25/b25-component-doc-context-<next-run-id>.json --markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/b25-component-doc-context-<next-run-id>.md`
- `dart run packages/tooling/loom_ux_judges/bin/production_ux_judge.dart --input ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --base .. --output ../docs/Build\ Plan\ V2/Evidence/B25/production-ux-criteria-scorecard.json --markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/production-ux-criteria-scorecard.md --tickets-output ../docs/Build\ Plan\ V2/Evidence/B25/b25-remediation-tickets-<next-run-id>.json --tickets-markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/b25-remediation-tickets-<next-run-id>.md`
- `dart run packages/tooling/loom_ux_judges/bin/b25_iteration_scorecard.dart --review ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --judge ../docs/Build\ Plan\ V2/Evidence/B25/production-ux-criteria-scorecard.json --previous ../docs/Build\ Plan\ V2/Evidence/B25/b25-iteration-scorecard-latest.json --output ../docs/Build\ Plan\ V2/Evidence/B25/b25-iteration-scorecard-latest.json --markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/b25-iteration-scorecard-latest.md`

## B25-RT-005-app-shell-customization-gap

| Field | Value |
| --- | --- |
| Severity | major |
| Priority | P1 |
| Status | open |
| Review run | `b25-v4-pass-42` |
| Source criterion | `b25-c16-app-shell-capability-utilization` |
| Source findings | B25-APP-SHELL-loom-communities-shell-persona-themecustomizationpass |
| Title | App Shell capability failed: themeCustomizationPass |
| Direct question | Do screenshots prove the community theme, typography, color, density, and component customization tokens are applied consistently? |
| Why it failed | Community `Loom Communities shell` persona `persona` does not prove `themeCustomizationPass` from screenshot evidence. |
| Required outcome | Update the product doc or UI, recapture after-screenshots, and regenerate appShellCapabilityReview so `themeCustomizationPass` passes from visible evidence. |
| Remediation mode | `review-only` |
| Worker readiness | no concrete implementation work item was generated; planner must inspect the direct-question failure before assigning a worker |
| First required step | Review failing direct questions and add screen/workflow/persona-specific evidence before implementation. |

### Problem Statement

Community `Loom Communities shell` persona `persona` does not prove `themeCustomizationPass` from screenshot evidence.

### Root Cause Hypothesis

The evidence does not yet satisfy the B25 production UX standard.

### Target Experience

Community theme, typography, density, colors, and component treatments are applied consistently without sacrificing readability or touch targets.

### UX Principles
- Resolve blocking UX evidence before closing B25

### Concrete Improvements
- Declare theme, typography, density, color, button, badge, and field customization tokens.
- Apply those tokens through the central App Shell model instead of one-off widget styling.
- Recapture screenshots proving the community-specific styling is visible and usable.

### Implementation Guidance
- Use `CommunityAppShellCustomizationSpec`, `LoomAppShellTabSpec`, and `LoomThemeCustomizationTokens` in `apps/loom_communities_demo/lib/main.dart`.
- Implement the capability centrally in the App Shell model, not as a one-off workflow widget hack.
- Recapture screenshots after implementation; source code alone cannot close this ticket.
- Inspect `apps/loom_communities_demo/lib/main.dart` for `CommunityAppShellCustomizationSpec`, persona tab specs, pinned surface specs, presentation-state routing, renderer selection, and theme/typography/density tokens.
- Update the community product experience doc Section 3.1 when the intended tab/pinning/presentation/customization model is missing or vague.
- Implement the missing App Shell capability in the central shell model, not as a one-off workflow hack.
- Recapture screenshots proving Home and Messages/Communication tabs, custom persona tabs, declared pinned surfaces, minimized/medium/expanded states, tap-to-expand, community-list states, renderer selection, and theme/customization tokens where required.

### Content Guidance
- Write copy that matches the task: RSVP, donate, publish, approve, submit, review, search, export, transfer, invite, or reply.
- Each primary surface should include the domain data a user needs to decide and act.
- Use explicit alternate action copy such as Decline, Request changes, Change response, Edit, Withdraw, Cancel RSVP, Archive, Retry, Roll back, or Manage where the lifecycle requires it.
- Use result copy that persists: Sent, Posted, Confirmed, Paid, Receipt ready, Submitted, Approved, Rejected, Claimed, Returned, Read, or equivalent domain state.

### Visual Guidance
- Use screenshot evidence to judge visual hierarchy, density, navigation clarity, and polish on the reviewed device.

### Source Research Requirement

The independent UX review must attach internet or open-source pattern references before UI remediation. If live research is unavailable, use the bundled catalog entries and keep the research queries in the ticket so a reviewer can refresh them.

### UX Reference Patterns To Copy

| Reference | Source | URL | What to copy |
| --- | --- | --- | --- |
| Material navigation and information architecture | Material Design 3 / design-system | https://m3.material.io/components/navigation-drawer/overview<br>Also: https://m3.material.io/components/navigation-bar/overview | Organize screens by user jobs and destinations; keep primary actions visible and avoid exposing implementation taxonomy. |
| Apple HIG navigation and content organization | Apple Human Interface Guidelines / design-system | https://developer.apple.com/design/human-interface-guidelines/navigation | Make navigation predictable, content-centered, and appropriate for the user’s current task. |
| Material Design cards and lists | Material Design 3 / design-system | https://m3.material.io/components/cards/overview<br>Also: https://m3.material.io/components/lists/overview | Use cards/lists only as scannable containers with clear hierarchy, content, metadata, and actions. Do not use repeated cards as the whole primary workflow. |
| Flutter sample app implementation patterns | flutter/samples / open-source | https://github.com/flutter/samples | Copy the separation between app shell, route state, domain widgets, and testable UI states rather than hardcoding a single generic renderer. |

### Reference Research Queries
- production mobile UX review screenshot critique examples
- open source Flutter mobile app UX patterns GitHub

### Implementation Blocked By
- The ticket lacks row-level implementation evidence.

### Likely Files / Widgets
- `app/apps/loom_communities_demo/lib/main.dart`
- `app/apps/loom_communities_demo/test/b21_b25_production_ux_test.dart`
- `docs/Build Plan V2/Evidence/B25/production-ux-blueprint.md`
- `docs/Build Plan V2/Evidence/B25/independent-production-ux-review.json`
- `docs/Build Plan V2/Evidence/B25/product-ux-screen-review-matrix.md`

### Concrete Acceptance Criteria
- Screenshots prove community color, typography, density, and component tokens are applied consistently.
- Customization does not introduce clipping, low contrast, crowding, or touch-target regressions.
- `appShellCapabilityReview.communityResults[]` has `themeCustomizationPass=true`.
- `appShellCapabilityReview.status` is `pass`.
- `appShellCapabilityReview.missingCapabilities` is empty.
- Every `appShellCapabilityReview.communityResults[]` row has passing tabs, explicit and appropriate pinning policy, presentation states, community-list states, theme customization, and renderer-selection checks where applicable.
- After-screenshots prove the shell capability in the affected community/persona/workflow, not only source-code declarations.
- `production_ux_judge.dart` has no blocking failure for this criterion.
- `b25_iteration_scorecard.dart` records the ticket as resolved or no longer blocking.
- Screenshots are refreshed and hashes/timestamps/app commit SHA match the reviewed app version.

### Affected Evidence
- `independent-production-ux-review.json appShellCapabilityReview`
- `llm-product-doc-workflow-reconciliation-<run-id>.json appShellCapabilityReview`
- `llm-product-doc-workflow-reconciliation-<run-id>.json reviewedComponentDocPaths and componentDocReview.docs`
- `docs/Product Docs V2/Community Examples/<community>-product-experience.md Section 3.1`
- `docs/Build Plan V2/Skill/components/card-surfaces/app-shell-navigation-theming.md`
- `docs/Build Plan V2/Skill/components/card-surfaces/tab-renderer-contracts.md`
- `product-ux-screen-review-matrix.md affected screen rows and screenshots`
- `production-ux-criteria-scorecard.json/.md`

### Evidence To Collect
- Updated review JSON, scorecards, screenshots, remediation log, and tracker evidence for the fixed criterion.

### Acceptance Checks
- Screenshots prove community color, typography, density, and component tokens are applied consistently.
- Customization does not introduce clipping, low contrast, crowding, or touch-target regressions.
- `appShellCapabilityReview.communityResults[]` has `themeCustomizationPass=true`.
- `appShellCapabilityReview.status` is `pass`.
- `appShellCapabilityReview.missingCapabilities` is empty.
- Every `appShellCapabilityReview.communityResults[]` row has passing tabs, explicit and appropriate pinning policy, presentation states, community-list states, theme customization, and renderer-selection checks where applicable.
- After-screenshots prove the shell capability in the affected community/persona/workflow, not only source-code declarations.
- `production_ux_judge.dart` has no blocking failure for this criterion.
- `b25_iteration_scorecard.dart` records the ticket as resolved or no longer blocking.
- Screenshots are refreshed and hashes/timestamps/app commit SHA match the reviewed app version.

### Non-Goals
- Do not close the ticket without fresh evidence and a passing judge rerun.

### Commit Boundary

Commit this remediation iteration, refreshed evidence, scorecards, tickets, and tracker updates before starting the next UX feedback loop.

### Rerun Commands
- `dart run packages/tooling/loom_ux_judges/bin/b25_capture_workflow_screenshots.dart --mode full-b25 --device emulator-5554 --evidence-root ../docs/Build\ Plan\ V2/Evidence`
- `dart run packages/tooling/loom_ux_judges/bin/b25_capture_coverage_gate.dart --evidence-root ../docs/Build\ Plan\ V2/Evidence --output ../docs/Build\ Plan\ V2/Evidence/B25/b25-capture-coverage-report.json`
- `dart run packages/tooling/loom_ux_judges/bin/b25_evidence_collector.dart --evidence-root ../docs/Build\ Plan\ V2/Evidence --repo-root .. --run-id <next-run-id> --prior-review ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --output ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.md --matrix-output ../docs/Build\ Plan\ V2/Evidence/B25/product-ux-screen-review-matrix.md`
- `dart run packages/tooling/loom_ux_judges/bin/b25_workflow_persona_coverage_collector.dart --input ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --output ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/workflow-persona-coverage-matrix.md`
- `dart run packages/tooling/loom_ux_judges/bin/b25_independent_ux_judge.dart --input ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --output ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.md --matrix-output ../docs/Build\ Plan\ V2/Evidence/B25/product-ux-screen-review-matrix.md`
- `dart run packages/tooling/loom_ux_judges/bin/b25_component_doc_context.dart --repo-root .. --output ../docs/Build\ Plan\ V2/Evidence/B25/b25-component-doc-context-<next-run-id>.json --markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/b25-component-doc-context-<next-run-id>.md`
- `dart run packages/tooling/loom_ux_judges/bin/production_ux_judge.dart --input ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --base .. --output ../docs/Build\ Plan\ V2/Evidence/B25/production-ux-criteria-scorecard.json --markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/production-ux-criteria-scorecard.md --tickets-output ../docs/Build\ Plan\ V2/Evidence/B25/b25-remediation-tickets-<next-run-id>.json --tickets-markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/b25-remediation-tickets-<next-run-id>.md`
- `dart run packages/tooling/loom_ux_judges/bin/b25_iteration_scorecard.dart --review ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --judge ../docs/Build\ Plan\ V2/Evidence/B25/production-ux-criteria-scorecard.json --previous ../docs/Build\ Plan\ V2/Evidence/B25/b25-iteration-scorecard-latest.json --output ../docs/Build\ Plan\ V2/Evidence/B25/b25-iteration-scorecard-latest.json --markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/b25-iteration-scorecard-latest.md`

## B25-RT-006-app-shell-renderer-selection-gap

| Field | Value |
| --- | --- |
| Severity | major |
| Priority | P1 |
| Status | open |
| Review run | `b25-v4-pass-42` |
| Source criterion | `b25-c16-app-shell-capability-utilization` |
| Source findings | B25-APP-SHELL-loom-communities-shell-persona-rendererselectionpass |
| Title | App Shell capability failed: rendererSelectionPass |
| Direct question | Does the visible screen prove the App Shell selected the correct domain renderer for the card-surface family instead of a generic fallback? |
| Why it failed | Community `Loom Communities shell` persona `persona` does not prove `rendererSelectionPass` from screenshot evidence. |
| Required outcome | Update the product doc or UI, recapture after-screenshots, and regenerate appShellCapabilityReview so `rendererSelectionPass` passes from visible evidence. |
| Remediation mode | `review-only` |
| Worker readiness | no concrete implementation work item was generated; planner must inspect the direct-question failure before assigning a worker |
| First required step | Review failing direct questions and add screen/workflow/persona-specific evidence before implementation. |

### Problem Statement

Community `Loom Communities shell` persona `persona` does not prove `rendererSelectionPass` from screenshot evidence.

### Root Cause Hypothesis

The evidence does not yet satisfy the B25 production UX standard.

### Target Experience

Each workflow uses the renderer that matches its card-surface family and product task, with visible UI differences that prove it is not a generic fallback.

### UX Principles
- Resolve blocking UX evidence before closing B25

### Concrete Improvements
- Map the workflow to the correct card-surface family and renderer target.
- Replace any generic fallback renderer with the domain renderer or screenshot-visible renderer evidence.
- Update the product doc and B25 evidence so the reviewer can see why the renderer matches the task.

### Implementation Guidance
- Use `CommunityAppShellCustomizationSpec`, `LoomAppShellTabSpec`, and `LoomThemeCustomizationTokens` in `apps/loom_communities_demo/lib/main.dart`.
- Implement the capability centrally in the App Shell model, not as a one-off workflow widget hack.
- Recapture screenshots after implementation; source code alone cannot close this ticket.
- Make renderer selection inspectable through card-surface family, renderer target, visible domain layout, and B25 evidence rows.
- If a renderer is intentionally shared, the screenshot must still prove the domain-specific content and layout for that card-surface family.

### Content Guidance
- Write copy that matches the task: RSVP, donate, publish, approve, submit, review, search, export, transfer, invite, or reply.
- Each primary surface should include the domain data a user needs to decide and act.
- Use explicit alternate action copy such as Decline, Request changes, Change response, Edit, Withdraw, Cancel RSVP, Archive, Retry, Roll back, or Manage where the lifecycle requires it.
- Use result copy that persists: Sent, Posted, Confirmed, Paid, Receipt ready, Submitted, Approved, Rejected, Claimed, Returned, Read, or equivalent domain state.

### Visual Guidance
- Use screenshot evidence to judge visual hierarchy, density, navigation clarity, and polish on the reviewed device.

### Source Research Requirement

The independent UX review must attach internet or open-source pattern references before UI remediation. If live research is unavailable, use the bundled catalog entries and keep the research queries in the ticket so a reviewer can refresh them.

### UX Reference Patterns To Copy

| Reference | Source | URL | What to copy |
| --- | --- | --- | --- |
| Material navigation and information architecture | Material Design 3 / design-system | https://m3.material.io/components/navigation-drawer/overview<br>Also: https://m3.material.io/components/navigation-bar/overview | Organize screens by user jobs and destinations; keep primary actions visible and avoid exposing implementation taxonomy. |
| Apple HIG navigation and content organization | Apple Human Interface Guidelines / design-system | https://developer.apple.com/design/human-interface-guidelines/navigation | Make navigation predictable, content-centered, and appropriate for the user’s current task. |
| Material Design cards and lists | Material Design 3 / design-system | https://m3.material.io/components/cards/overview<br>Also: https://m3.material.io/components/lists/overview | Use cards/lists only as scannable containers with clear hierarchy, content, metadata, and actions. Do not use repeated cards as the whole primary workflow. |
| Flutter sample app implementation patterns | flutter/samples / open-source | https://github.com/flutter/samples | Copy the separation between app shell, route state, domain widgets, and testable UI states rather than hardcoding a single generic renderer. |

### Reference Research Queries
- production mobile UX review screenshot critique examples
- open source Flutter mobile app UX patterns GitHub

### Implementation Blocked By
- The ticket lacks row-level implementation evidence.

### Likely Files / Widgets
- `app/apps/loom_communities_demo/lib/main.dart`
- `app/apps/loom_communities_demo/test/b21_b25_production_ux_test.dart`
- `docs/Build Plan V2/Evidence/B25/production-ux-blueprint.md`
- `docs/Build Plan V2/Evidence/B25/independent-production-ux-review.json`
- `docs/Build Plan V2/Evidence/B25/product-ux-screen-review-matrix.md`

### Concrete Acceptance Criteria
- The affected workflow has a documented card-surface family and renderer target.
- After-screenshots show the domain renderer output, not a generic fallback card.
- `appShellCapabilityReview.communityResults[]` has `rendererSelectionPass=true` for the affected row.
- `appShellCapabilityReview.status` is `pass`.
- `appShellCapabilityReview.missingCapabilities` is empty.
- Every `appShellCapabilityReview.communityResults[]` row has passing tabs, explicit and appropriate pinning policy, presentation states, community-list states, theme customization, and renderer-selection checks where applicable.
- After-screenshots prove the shell capability in the affected community/persona/workflow, not only source-code declarations.
- `production_ux_judge.dart` has no blocking failure for this criterion.
- `b25_iteration_scorecard.dart` records the ticket as resolved or no longer blocking.
- Screenshots are refreshed and hashes/timestamps/app commit SHA match the reviewed app version.

### Affected Evidence
- `independent-production-ux-review.json appShellCapabilityReview`
- `llm-product-doc-workflow-reconciliation-<run-id>.json appShellCapabilityReview`
- `llm-product-doc-workflow-reconciliation-<run-id>.json reviewedComponentDocPaths and componentDocReview.docs`
- `docs/Product Docs V2/Community Examples/<community>-product-experience.md Section 3.1`
- `docs/Build Plan V2/Skill/components/card-surfaces/app-shell-navigation-theming.md`
- `docs/Build Plan V2/Skill/components/card-surfaces/tab-renderer-contracts.md`
- `product-ux-screen-review-matrix.md affected screen rows and screenshots`
- `production-ux-criteria-scorecard.json/.md`

### Evidence To Collect
- Updated review JSON, scorecards, screenshots, remediation log, and tracker evidence for the fixed criterion.

### Acceptance Checks
- The affected workflow has a documented card-surface family and renderer target.
- After-screenshots show the domain renderer output, not a generic fallback card.
- `appShellCapabilityReview.communityResults[]` has `rendererSelectionPass=true` for the affected row.
- `appShellCapabilityReview.status` is `pass`.
- `appShellCapabilityReview.missingCapabilities` is empty.
- Every `appShellCapabilityReview.communityResults[]` row has passing tabs, explicit and appropriate pinning policy, presentation states, community-list states, theme customization, and renderer-selection checks where applicable.
- After-screenshots prove the shell capability in the affected community/persona/workflow, not only source-code declarations.
- `production_ux_judge.dart` has no blocking failure for this criterion.
- `b25_iteration_scorecard.dart` records the ticket as resolved or no longer blocking.
- Screenshots are refreshed and hashes/timestamps/app commit SHA match the reviewed app version.

### Non-Goals
- Do not close the ticket without fresh evidence and a passing judge rerun.

### Commit Boundary

Commit this remediation iteration, refreshed evidence, scorecards, tickets, and tracker updates before starting the next UX feedback loop.

### Rerun Commands
- `dart run packages/tooling/loom_ux_judges/bin/b25_capture_workflow_screenshots.dart --mode full-b25 --device emulator-5554 --evidence-root ../docs/Build\ Plan\ V2/Evidence`
- `dart run packages/tooling/loom_ux_judges/bin/b25_capture_coverage_gate.dart --evidence-root ../docs/Build\ Plan\ V2/Evidence --output ../docs/Build\ Plan\ V2/Evidence/B25/b25-capture-coverage-report.json`
- `dart run packages/tooling/loom_ux_judges/bin/b25_evidence_collector.dart --evidence-root ../docs/Build\ Plan\ V2/Evidence --repo-root .. --run-id <next-run-id> --prior-review ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --output ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.md --matrix-output ../docs/Build\ Plan\ V2/Evidence/B25/product-ux-screen-review-matrix.md`
- `dart run packages/tooling/loom_ux_judges/bin/b25_workflow_persona_coverage_collector.dart --input ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --output ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/workflow-persona-coverage-matrix.md`
- `dart run packages/tooling/loom_ux_judges/bin/b25_independent_ux_judge.dart --input ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --output ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.md --matrix-output ../docs/Build\ Plan\ V2/Evidence/B25/product-ux-screen-review-matrix.md`
- `dart run packages/tooling/loom_ux_judges/bin/b25_component_doc_context.dart --repo-root .. --output ../docs/Build\ Plan\ V2/Evidence/B25/b25-component-doc-context-<next-run-id>.json --markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/b25-component-doc-context-<next-run-id>.md`
- `dart run packages/tooling/loom_ux_judges/bin/production_ux_judge.dart --input ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --base .. --output ../docs/Build\ Plan\ V2/Evidence/B25/production-ux-criteria-scorecard.json --markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/production-ux-criteria-scorecard.md --tickets-output ../docs/Build\ Plan\ V2/Evidence/B25/b25-remediation-tickets-<next-run-id>.json --tickets-markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/b25-remediation-tickets-<next-run-id>.md`
- `dart run packages/tooling/loom_ux_judges/bin/b25_iteration_scorecard.dart --review ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --judge ../docs/Build\ Plan\ V2/Evidence/B25/production-ux-criteria-scorecard.json --previous ../docs/Build\ Plan\ V2/Evidence/B25/b25-iteration-scorecard-latest.json --output ../docs/Build\ Plan\ V2/Evidence/B25/b25-iteration-scorecard-latest.json --markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/b25-iteration-scorecard-latest.md`

## B25-RT-007-app-shell-tab-renderer-contract-gap

| Field | Value |
| --- | --- |
| Severity | major |
| Priority | P1 |
| Status | open |
| Review run | `b25-v4-pass-42` |
| Source criterion | `b25-c16-app-shell-capability-utilization` |
| Source findings | B25-APP-SHELL-calendartabsurface-MISSING-PROOF |
| Title | CalendarTabSurface is not proven by screenshot-backed review |
| Direct question | Does each dedicated tab visibly use its tab-native renderer contract, such as calendar/agenda, inbox/thread, marketplace browse/listing, documents library/detail, or workflow-status timeline? |
| Why it failed | CalendarTabSurface must be reviewed as a tab-native renderer from current screenshots. The review must answer whether the tab looks and behaves like the expected product surface, not a generic workflow-card list. |
| Required outcome | Add a tabRendererResults row for `CalendarTabSurface` with status=pass only after screenshots prove the tab-native UI, visible content, interaction states, and direct-question critique. If it fails, keep this as an implementation ticket. |
| Remediation mode | `review-only` |
| Worker readiness | no concrete implementation work item was generated; planner must inspect the direct-question failure before assigning a worker |
| First required step | Review failing direct questions and add screen/workflow/persona-specific evidence before implementation. |

### Problem Statement

CalendarTabSurface must be reviewed as a tab-native renderer from current screenshots. The review must answer whether the tab looks and behaves like the expected product surface, not a generic workflow-card list.

### Root Cause Hypothesis

The evidence does not yet satisfy the B25 production UX standard.

### Target Experience

Calendar, Messages, Marketplace, Documents, and Workflow Status tabs each render a recognizably native product interface for their category instead of reusing a generic card stack.

### UX Principles
- Resolve blocking UX evidence before closing B25

### Concrete Improvements
- Create or update `tabRendererResults[]` in the B25 review for each required renderer contract: CalendarTabSurface, MessagesTabSurface, MarketplaceTabSurface, DocumentsTabSurface, and WorkflowStatusSurface.
- For Calendar, show a date strip/week/month or agenda plus event detail and RSVP/change-response state.
- For Messages, show inbox/thread/composer/unread or invite state, not an informational card.
- For Marketplace, show browse/search/filter/listing/detail/current-holder/queue or list-item actions.
- For Documents, show library/category/detail plus embedded or external-open state.
- For Workflow Status, show a timeline/current step/reviewer/comment/document/payment/action surface.

### Implementation Guidance
- Use `CommunityAppShellCustomizationSpec`, `LoomAppShellTabSpec`, and `LoomThemeCustomizationTokens` in `apps/loom_communities_demo/lib/main.dart`.
- Implement the capability centrally in the App Shell model, not as a one-off workflow widget hack.
- Recapture screenshots after implementation; source code alone cannot close this ticket.
- Represent tab-native renderer proof as data in `appShellCapabilityReview.tabRendererResults[]` so the production judge can validate it without trusting prose.
- Use the renderer contracts in `docs/CardSurfaces/tab-renderer-contracts.md` and the mirrored Skill doc when choosing the target UI.

### Content Guidance
- Write copy that matches the task: RSVP, donate, publish, approve, submit, review, search, export, transfer, invite, or reply.
- Each primary surface should include the domain data a user needs to decide and act.
- Use explicit alternate action copy such as Decline, Request changes, Change response, Edit, Withdraw, Cancel RSVP, Archive, Retry, Roll back, or Manage where the lifecycle requires it.
- Use result copy that persists: Sent, Posted, Confirmed, Paid, Receipt ready, Submitted, Approved, Rejected, Claimed, Returned, Read, or equivalent domain state.

### Visual Guidance
- Use screenshot evidence to judge visual hierarchy, density, navigation clarity, and polish on the reviewed device.

### Source Research Requirement

The independent UX review must attach internet or open-source pattern references before UI remediation. If live research is unavailable, use the bundled catalog entries and keep the research queries in the ticket so a reviewer can refresh them.

### UX Reference Patterns To Copy

| Reference | Source | URL | What to copy |
| --- | --- | --- | --- |
| Material navigation and information architecture | Material Design 3 / design-system | https://m3.material.io/components/navigation-drawer/overview<br>Also: https://m3.material.io/components/navigation-bar/overview | Organize screens by user jobs and destinations; keep primary actions visible and avoid exposing implementation taxonomy. |
| Apple HIG navigation and content organization | Apple Human Interface Guidelines / design-system | https://developer.apple.com/design/human-interface-guidelines/navigation | Make navigation predictable, content-centered, and appropriate for the user’s current task. |
| Material Design cards and lists | Material Design 3 / design-system | https://m3.material.io/components/cards/overview<br>Also: https://m3.material.io/components/lists/overview | Use cards/lists only as scannable containers with clear hierarchy, content, metadata, and actions. Do not use repeated cards as the whole primary workflow. |
| Flutter sample app implementation patterns | flutter/samples / open-source | https://github.com/flutter/samples | Copy the separation between app shell, route state, domain widgets, and testable UI states rather than hardcoding a single generic renderer. |

### Reference Research Queries
- production mobile UX review screenshot critique examples
- open source Flutter mobile app UX patterns GitHub

### Implementation Blocked By
- The ticket lacks row-level implementation evidence.

### Likely Files / Widgets
- `app/apps/loom_communities_demo/lib/main.dart`
- `app/apps/loom_communities_demo/test/b21_b25_production_ux_test.dart`
- `docs/Build Plan V2/Evidence/B25/production-ux-blueprint.md`
- `docs/Build Plan V2/Evidence/B25/independent-production-ux-review.json`
- `docs/Build Plan V2/Evidence/B25/product-ux-screen-review-matrix.md`

### Concrete Acceptance Criteria
- `appShellCapabilityReview.tabRendererResults[]` contains passing rows for CalendarTabSurface, MessagesTabSurface, MarketplaceTabSurface, DocumentsTabSurface, and WorkflowStatusSurface.
- Each renderer row has screenshot row IDs, screenshot hashes, visible text, direct-question answers, and a screen-specific critique.
- The screenshots visibly match the renderer contract and do not rely on generic workflow-card fallback UI.
- `appShellCapabilityReview.status` is `pass`.
- `appShellCapabilityReview.missingCapabilities` is empty.
- Every `appShellCapabilityReview.communityResults[]` row has passing tabs, explicit and appropriate pinning policy, presentation states, community-list states, theme customization, and renderer-selection checks where applicable.
- After-screenshots prove the shell capability in the affected community/persona/workflow, not only source-code declarations.
- `production_ux_judge.dart` has no blocking failure for this criterion.
- `b25_iteration_scorecard.dart` records the ticket as resolved or no longer blocking.
- Screenshots are refreshed and hashes/timestamps/app commit SHA match the reviewed app version.

### Affected Evidence
- `independent-production-ux-review.json appShellCapabilityReview`
- `llm-product-doc-workflow-reconciliation-<run-id>.json appShellCapabilityReview`
- `llm-product-doc-workflow-reconciliation-<run-id>.json reviewedComponentDocPaths and componentDocReview.docs`
- `docs/Product Docs V2/Community Examples/<community>-product-experience.md Section 3.1`
- `docs/Build Plan V2/Skill/components/card-surfaces/app-shell-navigation-theming.md`
- `docs/Build Plan V2/Skill/components/card-surfaces/tab-renderer-contracts.md`
- `product-ux-screen-review-matrix.md affected screen rows and screenshots`
- `production-ux-criteria-scorecard.json/.md`

### Evidence To Collect
- Updated review JSON, scorecards, screenshots, remediation log, and tracker evidence for the fixed criterion.

### Acceptance Checks
- `appShellCapabilityReview.tabRendererResults[]` contains passing rows for CalendarTabSurface, MessagesTabSurface, MarketplaceTabSurface, DocumentsTabSurface, and WorkflowStatusSurface.
- Each renderer row has screenshot row IDs, screenshot hashes, visible text, direct-question answers, and a screen-specific critique.
- The screenshots visibly match the renderer contract and do not rely on generic workflow-card fallback UI.
- `appShellCapabilityReview.status` is `pass`.
- `appShellCapabilityReview.missingCapabilities` is empty.
- Every `appShellCapabilityReview.communityResults[]` row has passing tabs, explicit and appropriate pinning policy, presentation states, community-list states, theme customization, and renderer-selection checks where applicable.
- After-screenshots prove the shell capability in the affected community/persona/workflow, not only source-code declarations.
- `production_ux_judge.dart` has no blocking failure for this criterion.
- `b25_iteration_scorecard.dart` records the ticket as resolved or no longer blocking.
- Screenshots are refreshed and hashes/timestamps/app commit SHA match the reviewed app version.

### Non-Goals
- Do not close the ticket without fresh evidence and a passing judge rerun.

### Commit Boundary

Commit this remediation iteration, refreshed evidence, scorecards, tickets, and tracker updates before starting the next UX feedback loop.

### Rerun Commands
- `dart run packages/tooling/loom_ux_judges/bin/b25_capture_workflow_screenshots.dart --mode full-b25 --device emulator-5554 --evidence-root ../docs/Build\ Plan\ V2/Evidence`
- `dart run packages/tooling/loom_ux_judges/bin/b25_capture_coverage_gate.dart --evidence-root ../docs/Build\ Plan\ V2/Evidence --output ../docs/Build\ Plan\ V2/Evidence/B25/b25-capture-coverage-report.json`
- `dart run packages/tooling/loom_ux_judges/bin/b25_evidence_collector.dart --evidence-root ../docs/Build\ Plan\ V2/Evidence --repo-root .. --run-id <next-run-id> --prior-review ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --output ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.md --matrix-output ../docs/Build\ Plan\ V2/Evidence/B25/product-ux-screen-review-matrix.md`
- `dart run packages/tooling/loom_ux_judges/bin/b25_workflow_persona_coverage_collector.dart --input ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --output ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/workflow-persona-coverage-matrix.md`
- `dart run packages/tooling/loom_ux_judges/bin/b25_independent_ux_judge.dart --input ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --output ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.md --matrix-output ../docs/Build\ Plan\ V2/Evidence/B25/product-ux-screen-review-matrix.md`
- `dart run packages/tooling/loom_ux_judges/bin/b25_component_doc_context.dart --repo-root .. --output ../docs/Build\ Plan\ V2/Evidence/B25/b25-component-doc-context-<next-run-id>.json --markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/b25-component-doc-context-<next-run-id>.md`
- `dart run packages/tooling/loom_ux_judges/bin/production_ux_judge.dart --input ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --base .. --output ../docs/Build\ Plan\ V2/Evidence/B25/production-ux-criteria-scorecard.json --markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/production-ux-criteria-scorecard.md --tickets-output ../docs/Build\ Plan\ V2/Evidence/B25/b25-remediation-tickets-<next-run-id>.json --tickets-markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/b25-remediation-tickets-<next-run-id>.md`
- `dart run packages/tooling/loom_ux_judges/bin/b25_iteration_scorecard.dart --review ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --judge ../docs/Build\ Plan\ V2/Evidence/B25/production-ux-criteria-scorecard.json --previous ../docs/Build\ Plan\ V2/Evidence/B25/b25-iteration-scorecard-latest.json --output ../docs/Build\ Plan\ V2/Evidence/B25/b25-iteration-scorecard-latest.json --markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/b25-iteration-scorecard-latest.md`

## B25-RT-008-app-shell-tab-renderer-contract-gap

| Field | Value |
| --- | --- |
| Severity | major |
| Priority | P1 |
| Status | open |
| Review run | `b25-v4-pass-42` |
| Source criterion | `b25-c16-app-shell-capability-utilization` |
| Source findings | B25-APP-SHELL-messagestabsurface-MISSING-PROOF |
| Title | MessagesTabSurface is not proven by screenshot-backed review |
| Direct question | Does each dedicated tab visibly use its tab-native renderer contract, such as calendar/agenda, inbox/thread, marketplace browse/listing, documents library/detail, or workflow-status timeline? |
| Why it failed | MessagesTabSurface must be reviewed as a tab-native renderer from current screenshots. The review must answer whether the tab looks and behaves like the expected product surface, not a generic workflow-card list. |
| Required outcome | Add a tabRendererResults row for `MessagesTabSurface` with status=pass only after screenshots prove the tab-native UI, visible content, interaction states, and direct-question critique. If it fails, keep this as an implementation ticket. |
| Remediation mode | `review-only` |
| Worker readiness | no concrete implementation work item was generated; planner must inspect the direct-question failure before assigning a worker |
| First required step | Review failing direct questions and add screen/workflow/persona-specific evidence before implementation. |

### Problem Statement

MessagesTabSurface must be reviewed as a tab-native renderer from current screenshots. The review must answer whether the tab looks and behaves like the expected product surface, not a generic workflow-card list.

### Root Cause Hypothesis

The evidence does not yet satisfy the B25 production UX standard.

### Target Experience

Calendar, Messages, Marketplace, Documents, and Workflow Status tabs each render a recognizably native product interface for their category instead of reusing a generic card stack.

### UX Principles
- Resolve blocking UX evidence before closing B25

### Concrete Improvements
- Create or update `tabRendererResults[]` in the B25 review for each required renderer contract: CalendarTabSurface, MessagesTabSurface, MarketplaceTabSurface, DocumentsTabSurface, and WorkflowStatusSurface.
- For Calendar, show a date strip/week/month or agenda plus event detail and RSVP/change-response state.
- For Messages, show inbox/thread/composer/unread or invite state, not an informational card.
- For Marketplace, show browse/search/filter/listing/detail/current-holder/queue or list-item actions.
- For Documents, show library/category/detail plus embedded or external-open state.
- For Workflow Status, show a timeline/current step/reviewer/comment/document/payment/action surface.

### Implementation Guidance
- Use `CommunityAppShellCustomizationSpec`, `LoomAppShellTabSpec`, and `LoomThemeCustomizationTokens` in `apps/loom_communities_demo/lib/main.dart`.
- Implement the capability centrally in the App Shell model, not as a one-off workflow widget hack.
- Recapture screenshots after implementation; source code alone cannot close this ticket.
- Represent tab-native renderer proof as data in `appShellCapabilityReview.tabRendererResults[]` so the production judge can validate it without trusting prose.
- Use the renderer contracts in `docs/CardSurfaces/tab-renderer-contracts.md` and the mirrored Skill doc when choosing the target UI.

### Content Guidance
- Write copy that matches the task: RSVP, donate, publish, approve, submit, review, search, export, transfer, invite, or reply.
- Each primary surface should include the domain data a user needs to decide and act.
- Use explicit alternate action copy such as Decline, Request changes, Change response, Edit, Withdraw, Cancel RSVP, Archive, Retry, Roll back, or Manage where the lifecycle requires it.
- Use result copy that persists: Sent, Posted, Confirmed, Paid, Receipt ready, Submitted, Approved, Rejected, Claimed, Returned, Read, or equivalent domain state.

### Visual Guidance
- Use screenshot evidence to judge visual hierarchy, density, navigation clarity, and polish on the reviewed device.

### Source Research Requirement

The independent UX review must attach internet or open-source pattern references before UI remediation. If live research is unavailable, use the bundled catalog entries and keep the research queries in the ticket so a reviewer can refresh them.

### UX Reference Patterns To Copy

| Reference | Source | URL | What to copy |
| --- | --- | --- | --- |
| Material navigation and information architecture | Material Design 3 / design-system | https://m3.material.io/components/navigation-drawer/overview<br>Also: https://m3.material.io/components/navigation-bar/overview | Organize screens by user jobs and destinations; keep primary actions visible and avoid exposing implementation taxonomy. |
| Apple HIG navigation and content organization | Apple Human Interface Guidelines / design-system | https://developer.apple.com/design/human-interface-guidelines/navigation | Make navigation predictable, content-centered, and appropriate for the user’s current task. |
| Material Design cards and lists | Material Design 3 / design-system | https://m3.material.io/components/cards/overview<br>Also: https://m3.material.io/components/lists/overview | Use cards/lists only as scannable containers with clear hierarchy, content, metadata, and actions. Do not use repeated cards as the whole primary workflow. |
| Flutter sample app implementation patterns | flutter/samples / open-source | https://github.com/flutter/samples | Copy the separation between app shell, route state, domain widgets, and testable UI states rather than hardcoding a single generic renderer. |

### Reference Research Queries
- production mobile UX review screenshot critique examples
- open source Flutter mobile app UX patterns GitHub

### Implementation Blocked By
- The ticket lacks row-level implementation evidence.

### Likely Files / Widgets
- `app/apps/loom_communities_demo/lib/main.dart`
- `app/apps/loom_communities_demo/test/b21_b25_production_ux_test.dart`
- `docs/Build Plan V2/Evidence/B25/production-ux-blueprint.md`
- `docs/Build Plan V2/Evidence/B25/independent-production-ux-review.json`
- `docs/Build Plan V2/Evidence/B25/product-ux-screen-review-matrix.md`

### Concrete Acceptance Criteria
- `appShellCapabilityReview.tabRendererResults[]` contains passing rows for CalendarTabSurface, MessagesTabSurface, MarketplaceTabSurface, DocumentsTabSurface, and WorkflowStatusSurface.
- Each renderer row has screenshot row IDs, screenshot hashes, visible text, direct-question answers, and a screen-specific critique.
- The screenshots visibly match the renderer contract and do not rely on generic workflow-card fallback UI.
- `appShellCapabilityReview.status` is `pass`.
- `appShellCapabilityReview.missingCapabilities` is empty.
- Every `appShellCapabilityReview.communityResults[]` row has passing tabs, explicit and appropriate pinning policy, presentation states, community-list states, theme customization, and renderer-selection checks where applicable.
- After-screenshots prove the shell capability in the affected community/persona/workflow, not only source-code declarations.
- `production_ux_judge.dart` has no blocking failure for this criterion.
- `b25_iteration_scorecard.dart` records the ticket as resolved or no longer blocking.
- Screenshots are refreshed and hashes/timestamps/app commit SHA match the reviewed app version.

### Affected Evidence
- `independent-production-ux-review.json appShellCapabilityReview`
- `llm-product-doc-workflow-reconciliation-<run-id>.json appShellCapabilityReview`
- `llm-product-doc-workflow-reconciliation-<run-id>.json reviewedComponentDocPaths and componentDocReview.docs`
- `docs/Product Docs V2/Community Examples/<community>-product-experience.md Section 3.1`
- `docs/Build Plan V2/Skill/components/card-surfaces/app-shell-navigation-theming.md`
- `docs/Build Plan V2/Skill/components/card-surfaces/tab-renderer-contracts.md`
- `product-ux-screen-review-matrix.md affected screen rows and screenshots`
- `production-ux-criteria-scorecard.json/.md`

### Evidence To Collect
- Updated review JSON, scorecards, screenshots, remediation log, and tracker evidence for the fixed criterion.

### Acceptance Checks
- `appShellCapabilityReview.tabRendererResults[]` contains passing rows for CalendarTabSurface, MessagesTabSurface, MarketplaceTabSurface, DocumentsTabSurface, and WorkflowStatusSurface.
- Each renderer row has screenshot row IDs, screenshot hashes, visible text, direct-question answers, and a screen-specific critique.
- The screenshots visibly match the renderer contract and do not rely on generic workflow-card fallback UI.
- `appShellCapabilityReview.status` is `pass`.
- `appShellCapabilityReview.missingCapabilities` is empty.
- Every `appShellCapabilityReview.communityResults[]` row has passing tabs, explicit and appropriate pinning policy, presentation states, community-list states, theme customization, and renderer-selection checks where applicable.
- After-screenshots prove the shell capability in the affected community/persona/workflow, not only source-code declarations.
- `production_ux_judge.dart` has no blocking failure for this criterion.
- `b25_iteration_scorecard.dart` records the ticket as resolved or no longer blocking.
- Screenshots are refreshed and hashes/timestamps/app commit SHA match the reviewed app version.

### Non-Goals
- Do not close the ticket without fresh evidence and a passing judge rerun.

### Commit Boundary

Commit this remediation iteration, refreshed evidence, scorecards, tickets, and tracker updates before starting the next UX feedback loop.

### Rerun Commands
- `dart run packages/tooling/loom_ux_judges/bin/b25_capture_workflow_screenshots.dart --mode full-b25 --device emulator-5554 --evidence-root ../docs/Build\ Plan\ V2/Evidence`
- `dart run packages/tooling/loom_ux_judges/bin/b25_capture_coverage_gate.dart --evidence-root ../docs/Build\ Plan\ V2/Evidence --output ../docs/Build\ Plan\ V2/Evidence/B25/b25-capture-coverage-report.json`
- `dart run packages/tooling/loom_ux_judges/bin/b25_evidence_collector.dart --evidence-root ../docs/Build\ Plan\ V2/Evidence --repo-root .. --run-id <next-run-id> --prior-review ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --output ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.md --matrix-output ../docs/Build\ Plan\ V2/Evidence/B25/product-ux-screen-review-matrix.md`
- `dart run packages/tooling/loom_ux_judges/bin/b25_workflow_persona_coverage_collector.dart --input ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --output ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/workflow-persona-coverage-matrix.md`
- `dart run packages/tooling/loom_ux_judges/bin/b25_independent_ux_judge.dart --input ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --output ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.md --matrix-output ../docs/Build\ Plan\ V2/Evidence/B25/product-ux-screen-review-matrix.md`
- `dart run packages/tooling/loom_ux_judges/bin/b25_component_doc_context.dart --repo-root .. --output ../docs/Build\ Plan\ V2/Evidence/B25/b25-component-doc-context-<next-run-id>.json --markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/b25-component-doc-context-<next-run-id>.md`
- `dart run packages/tooling/loom_ux_judges/bin/production_ux_judge.dart --input ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --base .. --output ../docs/Build\ Plan\ V2/Evidence/B25/production-ux-criteria-scorecard.json --markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/production-ux-criteria-scorecard.md --tickets-output ../docs/Build\ Plan\ V2/Evidence/B25/b25-remediation-tickets-<next-run-id>.json --tickets-markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/b25-remediation-tickets-<next-run-id>.md`
- `dart run packages/tooling/loom_ux_judges/bin/b25_iteration_scorecard.dart --review ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --judge ../docs/Build\ Plan\ V2/Evidence/B25/production-ux-criteria-scorecard.json --previous ../docs/Build\ Plan\ V2/Evidence/B25/b25-iteration-scorecard-latest.json --output ../docs/Build\ Plan\ V2/Evidence/B25/b25-iteration-scorecard-latest.json --markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/b25-iteration-scorecard-latest.md`

## B25-RT-009-app-shell-tab-renderer-contract-gap

| Field | Value |
| --- | --- |
| Severity | major |
| Priority | P1 |
| Status | open |
| Review run | `b25-v4-pass-42` |
| Source criterion | `b25-c16-app-shell-capability-utilization` |
| Source findings | B25-APP-SHELL-marketplacetabsurface-MISSING-PROOF |
| Title | MarketplaceTabSurface is not proven by screenshot-backed review |
| Direct question | Does each dedicated tab visibly use its tab-native renderer contract, such as calendar/agenda, inbox/thread, marketplace browse/listing, documents library/detail, or workflow-status timeline? |
| Why it failed | MarketplaceTabSurface must be reviewed as a tab-native renderer from current screenshots. The review must answer whether the tab looks and behaves like the expected product surface, not a generic workflow-card list. |
| Required outcome | Add a tabRendererResults row for `MarketplaceTabSurface` with status=pass only after screenshots prove the tab-native UI, visible content, interaction states, and direct-question critique. If it fails, keep this as an implementation ticket. |
| Remediation mode | `review-only` |
| Worker readiness | no concrete implementation work item was generated; planner must inspect the direct-question failure before assigning a worker |
| First required step | Review failing direct questions and add screen/workflow/persona-specific evidence before implementation. |

### Problem Statement

MarketplaceTabSurface must be reviewed as a tab-native renderer from current screenshots. The review must answer whether the tab looks and behaves like the expected product surface, not a generic workflow-card list.

### Root Cause Hypothesis

The evidence does not yet satisfy the B25 production UX standard.

### Target Experience

Calendar, Messages, Marketplace, Documents, and Workflow Status tabs each render a recognizably native product interface for their category instead of reusing a generic card stack.

### UX Principles
- Resolve blocking UX evidence before closing B25

### Concrete Improvements
- Create or update `tabRendererResults[]` in the B25 review for each required renderer contract: CalendarTabSurface, MessagesTabSurface, MarketplaceTabSurface, DocumentsTabSurface, and WorkflowStatusSurface.
- For Calendar, show a date strip/week/month or agenda plus event detail and RSVP/change-response state.
- For Messages, show inbox/thread/composer/unread or invite state, not an informational card.
- For Marketplace, show browse/search/filter/listing/detail/current-holder/queue or list-item actions.
- For Documents, show library/category/detail plus embedded or external-open state.
- For Workflow Status, show a timeline/current step/reviewer/comment/document/payment/action surface.

### Implementation Guidance
- Use `CommunityAppShellCustomizationSpec`, `LoomAppShellTabSpec`, and `LoomThemeCustomizationTokens` in `apps/loom_communities_demo/lib/main.dart`.
- Implement the capability centrally in the App Shell model, not as a one-off workflow widget hack.
- Recapture screenshots after implementation; source code alone cannot close this ticket.
- Represent tab-native renderer proof as data in `appShellCapabilityReview.tabRendererResults[]` so the production judge can validate it without trusting prose.
- Use the renderer contracts in `docs/CardSurfaces/tab-renderer-contracts.md` and the mirrored Skill doc when choosing the target UI.

### Content Guidance
- Write copy that matches the task: RSVP, donate, publish, approve, submit, review, search, export, transfer, invite, or reply.
- Each primary surface should include the domain data a user needs to decide and act.
- Use explicit alternate action copy such as Decline, Request changes, Change response, Edit, Withdraw, Cancel RSVP, Archive, Retry, Roll back, or Manage where the lifecycle requires it.
- Use result copy that persists: Sent, Posted, Confirmed, Paid, Receipt ready, Submitted, Approved, Rejected, Claimed, Returned, Read, or equivalent domain state.

### Visual Guidance
- Use screenshot evidence to judge visual hierarchy, density, navigation clarity, and polish on the reviewed device.

### Source Research Requirement

The independent UX review must attach internet or open-source pattern references before UI remediation. If live research is unavailable, use the bundled catalog entries and keep the research queries in the ticket so a reviewer can refresh them.

### UX Reference Patterns To Copy

| Reference | Source | URL | What to copy |
| --- | --- | --- | --- |
| Material navigation and information architecture | Material Design 3 / design-system | https://m3.material.io/components/navigation-drawer/overview<br>Also: https://m3.material.io/components/navigation-bar/overview | Organize screens by user jobs and destinations; keep primary actions visible and avoid exposing implementation taxonomy. |
| Apple HIG navigation and content organization | Apple Human Interface Guidelines / design-system | https://developer.apple.com/design/human-interface-guidelines/navigation | Make navigation predictable, content-centered, and appropriate for the user’s current task. |
| Material Design cards and lists | Material Design 3 / design-system | https://m3.material.io/components/cards/overview<br>Also: https://m3.material.io/components/lists/overview | Use cards/lists only as scannable containers with clear hierarchy, content, metadata, and actions. Do not use repeated cards as the whole primary workflow. |
| Flutter sample app implementation patterns | flutter/samples / open-source | https://github.com/flutter/samples | Copy the separation between app shell, route state, domain widgets, and testable UI states rather than hardcoding a single generic renderer. |

### Reference Research Queries
- production mobile UX review screenshot critique examples
- open source Flutter mobile app UX patterns GitHub

### Implementation Blocked By
- The ticket lacks row-level implementation evidence.

### Likely Files / Widgets
- `app/apps/loom_communities_demo/lib/main.dart`
- `app/apps/loom_communities_demo/test/b21_b25_production_ux_test.dart`
- `docs/Build Plan V2/Evidence/B25/production-ux-blueprint.md`
- `docs/Build Plan V2/Evidence/B25/independent-production-ux-review.json`
- `docs/Build Plan V2/Evidence/B25/product-ux-screen-review-matrix.md`

### Concrete Acceptance Criteria
- `appShellCapabilityReview.tabRendererResults[]` contains passing rows for CalendarTabSurface, MessagesTabSurface, MarketplaceTabSurface, DocumentsTabSurface, and WorkflowStatusSurface.
- Each renderer row has screenshot row IDs, screenshot hashes, visible text, direct-question answers, and a screen-specific critique.
- The screenshots visibly match the renderer contract and do not rely on generic workflow-card fallback UI.
- `appShellCapabilityReview.status` is `pass`.
- `appShellCapabilityReview.missingCapabilities` is empty.
- Every `appShellCapabilityReview.communityResults[]` row has passing tabs, explicit and appropriate pinning policy, presentation states, community-list states, theme customization, and renderer-selection checks where applicable.
- After-screenshots prove the shell capability in the affected community/persona/workflow, not only source-code declarations.
- `production_ux_judge.dart` has no blocking failure for this criterion.
- `b25_iteration_scorecard.dart` records the ticket as resolved or no longer blocking.
- Screenshots are refreshed and hashes/timestamps/app commit SHA match the reviewed app version.

### Affected Evidence
- `independent-production-ux-review.json appShellCapabilityReview`
- `llm-product-doc-workflow-reconciliation-<run-id>.json appShellCapabilityReview`
- `llm-product-doc-workflow-reconciliation-<run-id>.json reviewedComponentDocPaths and componentDocReview.docs`
- `docs/Product Docs V2/Community Examples/<community>-product-experience.md Section 3.1`
- `docs/Build Plan V2/Skill/components/card-surfaces/app-shell-navigation-theming.md`
- `docs/Build Plan V2/Skill/components/card-surfaces/tab-renderer-contracts.md`
- `product-ux-screen-review-matrix.md affected screen rows and screenshots`
- `production-ux-criteria-scorecard.json/.md`

### Evidence To Collect
- Updated review JSON, scorecards, screenshots, remediation log, and tracker evidence for the fixed criterion.

### Acceptance Checks
- `appShellCapabilityReview.tabRendererResults[]` contains passing rows for CalendarTabSurface, MessagesTabSurface, MarketplaceTabSurface, DocumentsTabSurface, and WorkflowStatusSurface.
- Each renderer row has screenshot row IDs, screenshot hashes, visible text, direct-question answers, and a screen-specific critique.
- The screenshots visibly match the renderer contract and do not rely on generic workflow-card fallback UI.
- `appShellCapabilityReview.status` is `pass`.
- `appShellCapabilityReview.missingCapabilities` is empty.
- Every `appShellCapabilityReview.communityResults[]` row has passing tabs, explicit and appropriate pinning policy, presentation states, community-list states, theme customization, and renderer-selection checks where applicable.
- After-screenshots prove the shell capability in the affected community/persona/workflow, not only source-code declarations.
- `production_ux_judge.dart` has no blocking failure for this criterion.
- `b25_iteration_scorecard.dart` records the ticket as resolved or no longer blocking.
- Screenshots are refreshed and hashes/timestamps/app commit SHA match the reviewed app version.

### Non-Goals
- Do not close the ticket without fresh evidence and a passing judge rerun.

### Commit Boundary

Commit this remediation iteration, refreshed evidence, scorecards, tickets, and tracker updates before starting the next UX feedback loop.

### Rerun Commands
- `dart run packages/tooling/loom_ux_judges/bin/b25_capture_workflow_screenshots.dart --mode full-b25 --device emulator-5554 --evidence-root ../docs/Build\ Plan\ V2/Evidence`
- `dart run packages/tooling/loom_ux_judges/bin/b25_capture_coverage_gate.dart --evidence-root ../docs/Build\ Plan\ V2/Evidence --output ../docs/Build\ Plan\ V2/Evidence/B25/b25-capture-coverage-report.json`
- `dart run packages/tooling/loom_ux_judges/bin/b25_evidence_collector.dart --evidence-root ../docs/Build\ Plan\ V2/Evidence --repo-root .. --run-id <next-run-id> --prior-review ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --output ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.md --matrix-output ../docs/Build\ Plan\ V2/Evidence/B25/product-ux-screen-review-matrix.md`
- `dart run packages/tooling/loom_ux_judges/bin/b25_workflow_persona_coverage_collector.dart --input ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --output ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/workflow-persona-coverage-matrix.md`
- `dart run packages/tooling/loom_ux_judges/bin/b25_independent_ux_judge.dart --input ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --output ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.md --matrix-output ../docs/Build\ Plan\ V2/Evidence/B25/product-ux-screen-review-matrix.md`
- `dart run packages/tooling/loom_ux_judges/bin/b25_component_doc_context.dart --repo-root .. --output ../docs/Build\ Plan\ V2/Evidence/B25/b25-component-doc-context-<next-run-id>.json --markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/b25-component-doc-context-<next-run-id>.md`
- `dart run packages/tooling/loom_ux_judges/bin/production_ux_judge.dart --input ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --base .. --output ../docs/Build\ Plan\ V2/Evidence/B25/production-ux-criteria-scorecard.json --markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/production-ux-criteria-scorecard.md --tickets-output ../docs/Build\ Plan\ V2/Evidence/B25/b25-remediation-tickets-<next-run-id>.json --tickets-markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/b25-remediation-tickets-<next-run-id>.md`
- `dart run packages/tooling/loom_ux_judges/bin/b25_iteration_scorecard.dart --review ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --judge ../docs/Build\ Plan\ V2/Evidence/B25/production-ux-criteria-scorecard.json --previous ../docs/Build\ Plan\ V2/Evidence/B25/b25-iteration-scorecard-latest.json --output ../docs/Build\ Plan\ V2/Evidence/B25/b25-iteration-scorecard-latest.json --markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/b25-iteration-scorecard-latest.md`

## B25-RT-010-app-shell-tab-renderer-contract-gap

| Field | Value |
| --- | --- |
| Severity | major |
| Priority | P1 |
| Status | open |
| Review run | `b25-v4-pass-42` |
| Source criterion | `b25-c16-app-shell-capability-utilization` |
| Source findings | B25-APP-SHELL-documentstabsurface-MISSING-PROOF |
| Title | DocumentsTabSurface is not proven by screenshot-backed review |
| Direct question | Does each dedicated tab visibly use its tab-native renderer contract, such as calendar/agenda, inbox/thread, marketplace browse/listing, documents library/detail, or workflow-status timeline? |
| Why it failed | DocumentsTabSurface must be reviewed as a tab-native renderer from current screenshots. The review must answer whether the tab looks and behaves like the expected product surface, not a generic workflow-card list. |
| Required outcome | Add a tabRendererResults row for `DocumentsTabSurface` with status=pass only after screenshots prove the tab-native UI, visible content, interaction states, and direct-question critique. If it fails, keep this as an implementation ticket. |
| Remediation mode | `review-only` |
| Worker readiness | no concrete implementation work item was generated; planner must inspect the direct-question failure before assigning a worker |
| First required step | Review failing direct questions and add screen/workflow/persona-specific evidence before implementation. |

### Problem Statement

DocumentsTabSurface must be reviewed as a tab-native renderer from current screenshots. The review must answer whether the tab looks and behaves like the expected product surface, not a generic workflow-card list.

### Root Cause Hypothesis

The evidence does not yet satisfy the B25 production UX standard.

### Target Experience

Calendar, Messages, Marketplace, Documents, and Workflow Status tabs each render a recognizably native product interface for their category instead of reusing a generic card stack.

### UX Principles
- Resolve blocking UX evidence before closing B25

### Concrete Improvements
- Create or update `tabRendererResults[]` in the B25 review for each required renderer contract: CalendarTabSurface, MessagesTabSurface, MarketplaceTabSurface, DocumentsTabSurface, and WorkflowStatusSurface.
- For Calendar, show a date strip/week/month or agenda plus event detail and RSVP/change-response state.
- For Messages, show inbox/thread/composer/unread or invite state, not an informational card.
- For Marketplace, show browse/search/filter/listing/detail/current-holder/queue or list-item actions.
- For Documents, show library/category/detail plus embedded or external-open state.
- For Workflow Status, show a timeline/current step/reviewer/comment/document/payment/action surface.

### Implementation Guidance
- Use `CommunityAppShellCustomizationSpec`, `LoomAppShellTabSpec`, and `LoomThemeCustomizationTokens` in `apps/loom_communities_demo/lib/main.dart`.
- Implement the capability centrally in the App Shell model, not as a one-off workflow widget hack.
- Recapture screenshots after implementation; source code alone cannot close this ticket.
- Represent tab-native renderer proof as data in `appShellCapabilityReview.tabRendererResults[]` so the production judge can validate it without trusting prose.
- Use the renderer contracts in `docs/CardSurfaces/tab-renderer-contracts.md` and the mirrored Skill doc when choosing the target UI.

### Content Guidance
- Write copy that matches the task: RSVP, donate, publish, approve, submit, review, search, export, transfer, invite, or reply.
- Each primary surface should include the domain data a user needs to decide and act.
- Use explicit alternate action copy such as Decline, Request changes, Change response, Edit, Withdraw, Cancel RSVP, Archive, Retry, Roll back, or Manage where the lifecycle requires it.
- Use result copy that persists: Sent, Posted, Confirmed, Paid, Receipt ready, Submitted, Approved, Rejected, Claimed, Returned, Read, or equivalent domain state.

### Visual Guidance
- Use screenshot evidence to judge visual hierarchy, density, navigation clarity, and polish on the reviewed device.

### Source Research Requirement

The independent UX review must attach internet or open-source pattern references before UI remediation. If live research is unavailable, use the bundled catalog entries and keep the research queries in the ticket so a reviewer can refresh them.

### UX Reference Patterns To Copy

| Reference | Source | URL | What to copy |
| --- | --- | --- | --- |
| Material navigation and information architecture | Material Design 3 / design-system | https://m3.material.io/components/navigation-drawer/overview<br>Also: https://m3.material.io/components/navigation-bar/overview | Organize screens by user jobs and destinations; keep primary actions visible and avoid exposing implementation taxonomy. |
| Apple HIG navigation and content organization | Apple Human Interface Guidelines / design-system | https://developer.apple.com/design/human-interface-guidelines/navigation | Make navigation predictable, content-centered, and appropriate for the user’s current task. |
| Material Design cards and lists | Material Design 3 / design-system | https://m3.material.io/components/cards/overview<br>Also: https://m3.material.io/components/lists/overview | Use cards/lists only as scannable containers with clear hierarchy, content, metadata, and actions. Do not use repeated cards as the whole primary workflow. |
| Flutter sample app implementation patterns | flutter/samples / open-source | https://github.com/flutter/samples | Copy the separation between app shell, route state, domain widgets, and testable UI states rather than hardcoding a single generic renderer. |

### Reference Research Queries
- production mobile UX review screenshot critique examples
- open source Flutter mobile app UX patterns GitHub

### Implementation Blocked By
- The ticket lacks row-level implementation evidence.

### Likely Files / Widgets
- `app/apps/loom_communities_demo/lib/main.dart`
- `app/apps/loom_communities_demo/test/b21_b25_production_ux_test.dart`
- `docs/Build Plan V2/Evidence/B25/production-ux-blueprint.md`
- `docs/Build Plan V2/Evidence/B25/independent-production-ux-review.json`
- `docs/Build Plan V2/Evidence/B25/product-ux-screen-review-matrix.md`

### Concrete Acceptance Criteria
- `appShellCapabilityReview.tabRendererResults[]` contains passing rows for CalendarTabSurface, MessagesTabSurface, MarketplaceTabSurface, DocumentsTabSurface, and WorkflowStatusSurface.
- Each renderer row has screenshot row IDs, screenshot hashes, visible text, direct-question answers, and a screen-specific critique.
- The screenshots visibly match the renderer contract and do not rely on generic workflow-card fallback UI.
- `appShellCapabilityReview.status` is `pass`.
- `appShellCapabilityReview.missingCapabilities` is empty.
- Every `appShellCapabilityReview.communityResults[]` row has passing tabs, explicit and appropriate pinning policy, presentation states, community-list states, theme customization, and renderer-selection checks where applicable.
- After-screenshots prove the shell capability in the affected community/persona/workflow, not only source-code declarations.
- `production_ux_judge.dart` has no blocking failure for this criterion.
- `b25_iteration_scorecard.dart` records the ticket as resolved or no longer blocking.
- Screenshots are refreshed and hashes/timestamps/app commit SHA match the reviewed app version.

### Affected Evidence
- `independent-production-ux-review.json appShellCapabilityReview`
- `llm-product-doc-workflow-reconciliation-<run-id>.json appShellCapabilityReview`
- `llm-product-doc-workflow-reconciliation-<run-id>.json reviewedComponentDocPaths and componentDocReview.docs`
- `docs/Product Docs V2/Community Examples/<community>-product-experience.md Section 3.1`
- `docs/Build Plan V2/Skill/components/card-surfaces/app-shell-navigation-theming.md`
- `docs/Build Plan V2/Skill/components/card-surfaces/tab-renderer-contracts.md`
- `product-ux-screen-review-matrix.md affected screen rows and screenshots`
- `production-ux-criteria-scorecard.json/.md`

### Evidence To Collect
- Updated review JSON, scorecards, screenshots, remediation log, and tracker evidence for the fixed criterion.

### Acceptance Checks
- `appShellCapabilityReview.tabRendererResults[]` contains passing rows for CalendarTabSurface, MessagesTabSurface, MarketplaceTabSurface, DocumentsTabSurface, and WorkflowStatusSurface.
- Each renderer row has screenshot row IDs, screenshot hashes, visible text, direct-question answers, and a screen-specific critique.
- The screenshots visibly match the renderer contract and do not rely on generic workflow-card fallback UI.
- `appShellCapabilityReview.status` is `pass`.
- `appShellCapabilityReview.missingCapabilities` is empty.
- Every `appShellCapabilityReview.communityResults[]` row has passing tabs, explicit and appropriate pinning policy, presentation states, community-list states, theme customization, and renderer-selection checks where applicable.
- After-screenshots prove the shell capability in the affected community/persona/workflow, not only source-code declarations.
- `production_ux_judge.dart` has no blocking failure for this criterion.
- `b25_iteration_scorecard.dart` records the ticket as resolved or no longer blocking.
- Screenshots are refreshed and hashes/timestamps/app commit SHA match the reviewed app version.

### Non-Goals
- Do not close the ticket without fresh evidence and a passing judge rerun.

### Commit Boundary

Commit this remediation iteration, refreshed evidence, scorecards, tickets, and tracker updates before starting the next UX feedback loop.

### Rerun Commands
- `dart run packages/tooling/loom_ux_judges/bin/b25_capture_workflow_screenshots.dart --mode full-b25 --device emulator-5554 --evidence-root ../docs/Build\ Plan\ V2/Evidence`
- `dart run packages/tooling/loom_ux_judges/bin/b25_capture_coverage_gate.dart --evidence-root ../docs/Build\ Plan\ V2/Evidence --output ../docs/Build\ Plan\ V2/Evidence/B25/b25-capture-coverage-report.json`
- `dart run packages/tooling/loom_ux_judges/bin/b25_evidence_collector.dart --evidence-root ../docs/Build\ Plan\ V2/Evidence --repo-root .. --run-id <next-run-id> --prior-review ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --output ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.md --matrix-output ../docs/Build\ Plan\ V2/Evidence/B25/product-ux-screen-review-matrix.md`
- `dart run packages/tooling/loom_ux_judges/bin/b25_workflow_persona_coverage_collector.dart --input ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --output ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/workflow-persona-coverage-matrix.md`
- `dart run packages/tooling/loom_ux_judges/bin/b25_independent_ux_judge.dart --input ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --output ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.md --matrix-output ../docs/Build\ Plan\ V2/Evidence/B25/product-ux-screen-review-matrix.md`
- `dart run packages/tooling/loom_ux_judges/bin/b25_component_doc_context.dart --repo-root .. --output ../docs/Build\ Plan\ V2/Evidence/B25/b25-component-doc-context-<next-run-id>.json --markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/b25-component-doc-context-<next-run-id>.md`
- `dart run packages/tooling/loom_ux_judges/bin/production_ux_judge.dart --input ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --base .. --output ../docs/Build\ Plan\ V2/Evidence/B25/production-ux-criteria-scorecard.json --markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/production-ux-criteria-scorecard.md --tickets-output ../docs/Build\ Plan\ V2/Evidence/B25/b25-remediation-tickets-<next-run-id>.json --tickets-markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/b25-remediation-tickets-<next-run-id>.md`
- `dart run packages/tooling/loom_ux_judges/bin/b25_iteration_scorecard.dart --review ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --judge ../docs/Build\ Plan\ V2/Evidence/B25/production-ux-criteria-scorecard.json --previous ../docs/Build\ Plan\ V2/Evidence/B25/b25-iteration-scorecard-latest.json --output ../docs/Build\ Plan\ V2/Evidence/B25/b25-iteration-scorecard-latest.json --markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/b25-iteration-scorecard-latest.md`

## B25-RT-011-app-shell-tab-renderer-contract-gap

| Field | Value |
| --- | --- |
| Severity | major |
| Priority | P1 |
| Status | open |
| Review run | `b25-v4-pass-42` |
| Source criterion | `b25-c16-app-shell-capability-utilization` |
| Source findings | B25-APP-SHELL-workflowstatussurface-MISSING-PROOF |
| Title | WorkflowStatusSurface is not proven by screenshot-backed review |
| Direct question | Does each dedicated tab visibly use its tab-native renderer contract, such as calendar/agenda, inbox/thread, marketplace browse/listing, documents library/detail, or workflow-status timeline? |
| Why it failed | WorkflowStatusSurface must be reviewed as a tab-native renderer from current screenshots. The review must answer whether the tab looks and behaves like the expected product surface, not a generic workflow-card list. |
| Required outcome | Add a tabRendererResults row for `WorkflowStatusSurface` with status=pass only after screenshots prove the tab-native UI, visible content, interaction states, and direct-question critique. If it fails, keep this as an implementation ticket. |
| Remediation mode | `review-only` |
| Worker readiness | no concrete implementation work item was generated; planner must inspect the direct-question failure before assigning a worker |
| First required step | Review failing direct questions and add screen/workflow/persona-specific evidence before implementation. |

### Problem Statement

WorkflowStatusSurface must be reviewed as a tab-native renderer from current screenshots. The review must answer whether the tab looks and behaves like the expected product surface, not a generic workflow-card list.

### Root Cause Hypothesis

The evidence does not yet satisfy the B25 production UX standard.

### Target Experience

Calendar, Messages, Marketplace, Documents, and Workflow Status tabs each render a recognizably native product interface for their category instead of reusing a generic card stack.

### UX Principles
- Resolve blocking UX evidence before closing B25

### Concrete Improvements
- Create or update `tabRendererResults[]` in the B25 review for each required renderer contract: CalendarTabSurface, MessagesTabSurface, MarketplaceTabSurface, DocumentsTabSurface, and WorkflowStatusSurface.
- For Calendar, show a date strip/week/month or agenda plus event detail and RSVP/change-response state.
- For Messages, show inbox/thread/composer/unread or invite state, not an informational card.
- For Marketplace, show browse/search/filter/listing/detail/current-holder/queue or list-item actions.
- For Documents, show library/category/detail plus embedded or external-open state.
- For Workflow Status, show a timeline/current step/reviewer/comment/document/payment/action surface.

### Implementation Guidance
- Use `CommunityAppShellCustomizationSpec`, `LoomAppShellTabSpec`, and `LoomThemeCustomizationTokens` in `apps/loom_communities_demo/lib/main.dart`.
- Implement the capability centrally in the App Shell model, not as a one-off workflow widget hack.
- Recapture screenshots after implementation; source code alone cannot close this ticket.
- Represent tab-native renderer proof as data in `appShellCapabilityReview.tabRendererResults[]` so the production judge can validate it without trusting prose.
- Use the renderer contracts in `docs/CardSurfaces/tab-renderer-contracts.md` and the mirrored Skill doc when choosing the target UI.

### Content Guidance
- Write copy that matches the task: RSVP, donate, publish, approve, submit, review, search, export, transfer, invite, or reply.
- Each primary surface should include the domain data a user needs to decide and act.
- Use explicit alternate action copy such as Decline, Request changes, Change response, Edit, Withdraw, Cancel RSVP, Archive, Retry, Roll back, or Manage where the lifecycle requires it.
- Use result copy that persists: Sent, Posted, Confirmed, Paid, Receipt ready, Submitted, Approved, Rejected, Claimed, Returned, Read, or equivalent domain state.

### Visual Guidance
- Use screenshot evidence to judge visual hierarchy, density, navigation clarity, and polish on the reviewed device.

### Source Research Requirement

The independent UX review must attach internet or open-source pattern references before UI remediation. If live research is unavailable, use the bundled catalog entries and keep the research queries in the ticket so a reviewer can refresh them.

### UX Reference Patterns To Copy

| Reference | Source | URL | What to copy |
| --- | --- | --- | --- |
| Material navigation and information architecture | Material Design 3 / design-system | https://m3.material.io/components/navigation-drawer/overview<br>Also: https://m3.material.io/components/navigation-bar/overview | Organize screens by user jobs and destinations; keep primary actions visible and avoid exposing implementation taxonomy. |
| Apple HIG navigation and content organization | Apple Human Interface Guidelines / design-system | https://developer.apple.com/design/human-interface-guidelines/navigation | Make navigation predictable, content-centered, and appropriate for the user’s current task. |
| Material Design cards and lists | Material Design 3 / design-system | https://m3.material.io/components/cards/overview<br>Also: https://m3.material.io/components/lists/overview | Use cards/lists only as scannable containers with clear hierarchy, content, metadata, and actions. Do not use repeated cards as the whole primary workflow. |
| Flutter sample app implementation patterns | flutter/samples / open-source | https://github.com/flutter/samples | Copy the separation between app shell, route state, domain widgets, and testable UI states rather than hardcoding a single generic renderer. |

### Reference Research Queries
- production mobile UX review screenshot critique examples
- open source Flutter mobile app UX patterns GitHub

### Implementation Blocked By
- The ticket lacks row-level implementation evidence.

### Likely Files / Widgets
- `app/apps/loom_communities_demo/lib/main.dart`
- `app/apps/loom_communities_demo/test/b21_b25_production_ux_test.dart`
- `docs/Build Plan V2/Evidence/B25/production-ux-blueprint.md`
- `docs/Build Plan V2/Evidence/B25/independent-production-ux-review.json`
- `docs/Build Plan V2/Evidence/B25/product-ux-screen-review-matrix.md`

### Concrete Acceptance Criteria
- `appShellCapabilityReview.tabRendererResults[]` contains passing rows for CalendarTabSurface, MessagesTabSurface, MarketplaceTabSurface, DocumentsTabSurface, and WorkflowStatusSurface.
- Each renderer row has screenshot row IDs, screenshot hashes, visible text, direct-question answers, and a screen-specific critique.
- The screenshots visibly match the renderer contract and do not rely on generic workflow-card fallback UI.
- `appShellCapabilityReview.status` is `pass`.
- `appShellCapabilityReview.missingCapabilities` is empty.
- Every `appShellCapabilityReview.communityResults[]` row has passing tabs, explicit and appropriate pinning policy, presentation states, community-list states, theme customization, and renderer-selection checks where applicable.
- After-screenshots prove the shell capability in the affected community/persona/workflow, not only source-code declarations.
- `production_ux_judge.dart` has no blocking failure for this criterion.
- `b25_iteration_scorecard.dart` records the ticket as resolved or no longer blocking.
- Screenshots are refreshed and hashes/timestamps/app commit SHA match the reviewed app version.

### Affected Evidence
- `independent-production-ux-review.json appShellCapabilityReview`
- `llm-product-doc-workflow-reconciliation-<run-id>.json appShellCapabilityReview`
- `llm-product-doc-workflow-reconciliation-<run-id>.json reviewedComponentDocPaths and componentDocReview.docs`
- `docs/Product Docs V2/Community Examples/<community>-product-experience.md Section 3.1`
- `docs/Build Plan V2/Skill/components/card-surfaces/app-shell-navigation-theming.md`
- `docs/Build Plan V2/Skill/components/card-surfaces/tab-renderer-contracts.md`
- `product-ux-screen-review-matrix.md affected screen rows and screenshots`
- `production-ux-criteria-scorecard.json/.md`

### Evidence To Collect
- Updated review JSON, scorecards, screenshots, remediation log, and tracker evidence for the fixed criterion.

### Acceptance Checks
- `appShellCapabilityReview.tabRendererResults[]` contains passing rows for CalendarTabSurface, MessagesTabSurface, MarketplaceTabSurface, DocumentsTabSurface, and WorkflowStatusSurface.
- Each renderer row has screenshot row IDs, screenshot hashes, visible text, direct-question answers, and a screen-specific critique.
- The screenshots visibly match the renderer contract and do not rely on generic workflow-card fallback UI.
- `appShellCapabilityReview.status` is `pass`.
- `appShellCapabilityReview.missingCapabilities` is empty.
- Every `appShellCapabilityReview.communityResults[]` row has passing tabs, explicit and appropriate pinning policy, presentation states, community-list states, theme customization, and renderer-selection checks where applicable.
- After-screenshots prove the shell capability in the affected community/persona/workflow, not only source-code declarations.
- `production_ux_judge.dart` has no blocking failure for this criterion.
- `b25_iteration_scorecard.dart` records the ticket as resolved or no longer blocking.
- Screenshots are refreshed and hashes/timestamps/app commit SHA match the reviewed app version.

### Non-Goals
- Do not close the ticket without fresh evidence and a passing judge rerun.

### Commit Boundary

Commit this remediation iteration, refreshed evidence, scorecards, tickets, and tracker updates before starting the next UX feedback loop.

### Rerun Commands
- `dart run packages/tooling/loom_ux_judges/bin/b25_capture_workflow_screenshots.dart --mode full-b25 --device emulator-5554 --evidence-root ../docs/Build\ Plan\ V2/Evidence`
- `dart run packages/tooling/loom_ux_judges/bin/b25_capture_coverage_gate.dart --evidence-root ../docs/Build\ Plan\ V2/Evidence --output ../docs/Build\ Plan\ V2/Evidence/B25/b25-capture-coverage-report.json`
- `dart run packages/tooling/loom_ux_judges/bin/b25_evidence_collector.dart --evidence-root ../docs/Build\ Plan\ V2/Evidence --repo-root .. --run-id <next-run-id> --prior-review ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --output ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.md --matrix-output ../docs/Build\ Plan\ V2/Evidence/B25/product-ux-screen-review-matrix.md`
- `dart run packages/tooling/loom_ux_judges/bin/b25_workflow_persona_coverage_collector.dart --input ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --output ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/workflow-persona-coverage-matrix.md`
- `dart run packages/tooling/loom_ux_judges/bin/b25_independent_ux_judge.dart --input ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --output ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.md --matrix-output ../docs/Build\ Plan\ V2/Evidence/B25/product-ux-screen-review-matrix.md`
- `dart run packages/tooling/loom_ux_judges/bin/b25_component_doc_context.dart --repo-root .. --output ../docs/Build\ Plan\ V2/Evidence/B25/b25-component-doc-context-<next-run-id>.json --markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/b25-component-doc-context-<next-run-id>.md`
- `dart run packages/tooling/loom_ux_judges/bin/production_ux_judge.dart --input ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --base .. --output ../docs/Build\ Plan\ V2/Evidence/B25/production-ux-criteria-scorecard.json --markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/production-ux-criteria-scorecard.md --tickets-output ../docs/Build\ Plan\ V2/Evidence/B25/b25-remediation-tickets-<next-run-id>.json --tickets-markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/b25-remediation-tickets-<next-run-id>.md`
- `dart run packages/tooling/loom_ux_judges/bin/b25_iteration_scorecard.dart --review ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --judge ../docs/Build\ Plan\ V2/Evidence/B25/production-ux-criteria-scorecard.json --previous ../docs/Build\ Plan\ V2/Evidence/B25/b25-iteration-scorecard-latest.json --output ../docs/Build\ Plan\ V2/Evidence/B25/b25-iteration-scorecard-latest.json --markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/b25-iteration-scorecard-latest.md`

## B25-RT-012-app-shell-interaction-transition-gap

| Field | Value |
| --- | --- |
| Severity | major |
| Priority | P1 |
| Status | open |
| Review run | `b25-v4-pass-42` |
| Source criterion | `b25-c16-app-shell-capability-utilization` |
| Source findings | B25-APP-SHELL-INTERACTION-unknown-row |
| Title | Interaction transition evidence failed |
| Direct question | Do screenshots prove actionable controls were tapped and caused the correct visible state transition, including change/undo/result states where the workflow requires them? |
| Why it failed | Interaction `unknown-row` does not prove a tapped control caused the expected visible state transition. |
| Required outcome | Capture before/tap/after screenshots for this interaction and record the visible state change, including the user-facing result and undo/change path when applicable. |
| Remediation mode | `review-only` |
| Worker readiness | no concrete implementation work item was generated; planner must inspect the direct-question failure before assigning a worker |
| First required step | Review failing direct questions and add screen/workflow/persona-specific evidence before implementation. |

### Problem Statement

Interaction `unknown-row` does not prove a tapped control caused the expected visible state transition.

### Root Cause Hypothesis

The evidence does not yet satisfy the B25 production UX standard.

### Target Experience

Every important button and action proves a real interaction: the before screenshot, tapped/review state, and after screenshot show a changed status, result, receipt, or editable/undoable continuation.

### UX Principles
- Resolve blocking UX evidence before closing B25

### Concrete Improvements
- Extend capture automation to tap every important primary and alternate action in the reviewed workflows.
- Record before, action/review, and after screenshots with distinct hashes and visible state changes.
- For change/undo/edit paths, capture the later state proving the user can revise the prior response.

### Implementation Guidance
- Use `CommunityAppShellCustomizationSpec`, `LoomAppShellTabSpec`, and `LoomThemeCustomizationTokens` in `apps/loom_communities_demo/lib/main.dart`.
- Implement the capability centrally in the App Shell model, not as a one-off workflow widget hack.
- Recapture screenshots after implementation; source code alone cannot close this ticket.
- Update workflow capture helpers so important buttons are actually tapped and the resulting UI state is captured.
- Do not make UI conform to old test keys; update the evidence automation to follow the production interaction model.

### Content Guidance
- Write copy that matches the task: RSVP, donate, publish, approve, submit, review, search, export, transfer, invite, or reply.
- Each primary surface should include the domain data a user needs to decide and act.
- Use explicit alternate action copy such as Decline, Request changes, Change response, Edit, Withdraw, Cancel RSVP, Archive, Retry, Roll back, or Manage where the lifecycle requires it.
- Use result copy that persists: Sent, Posted, Confirmed, Paid, Receipt ready, Submitted, Approved, Rejected, Claimed, Returned, Read, or equivalent domain state.

### Visual Guidance
- Use screenshot evidence to judge visual hierarchy, density, navigation clarity, and polish on the reviewed device.

### Source Research Requirement

The independent UX review must attach internet or open-source pattern references before UI remediation. If live research is unavailable, use the bundled catalog entries and keep the research queries in the ticket so a reviewer can refresh them.

### UX Reference Patterns To Copy

| Reference | Source | URL | What to copy |
| --- | --- | --- | --- |
| Material navigation and information architecture | Material Design 3 / design-system | https://m3.material.io/components/navigation-drawer/overview<br>Also: https://m3.material.io/components/navigation-bar/overview | Organize screens by user jobs and destinations; keep primary actions visible and avoid exposing implementation taxonomy. |
| Apple HIG navigation and content organization | Apple Human Interface Guidelines / design-system | https://developer.apple.com/design/human-interface-guidelines/navigation | Make navigation predictable, content-centered, and appropriate for the user’s current task. |
| Material Design cards and lists | Material Design 3 / design-system | https://m3.material.io/components/cards/overview<br>Also: https://m3.material.io/components/lists/overview | Use cards/lists only as scannable containers with clear hierarchy, content, metadata, and actions. Do not use repeated cards as the whole primary workflow. |
| Flutter sample app implementation patterns | flutter/samples / open-source | https://github.com/flutter/samples | Copy the separation between app shell, route state, domain widgets, and testable UI states rather than hardcoding a single generic renderer. |

### Reference Research Queries
- production mobile UX review screenshot critique examples
- open source Flutter mobile app UX patterns GitHub

### Implementation Blocked By
- The ticket lacks row-level implementation evidence.

### Likely Files / Widgets
- `app/apps/loom_communities_demo/lib/main.dart`
- `app/apps/loom_communities_demo/test/b21_b25_production_ux_test.dart`
- `docs/Build Plan V2/Evidence/B25/production-ux-blueprint.md`
- `docs/Build Plan V2/Evidence/B25/independent-production-ux-review.json`
- `docs/Build Plan V2/Evidence/B25/product-ux-screen-review-matrix.md`

### Concrete Acceptance Criteria
- Every important primary/alternate action has before/tap/after or entry/action/result screenshots with distinct hashes.
- The after screenshot visibly proves a changed state, status, receipt, result, undo/change path, or receiver state.
- `appShellCapabilityReview.interactionTransitionResults[]` or lifecycle scorecards pass without missing transition evidence.
- `appShellCapabilityReview.status` is `pass`.
- `appShellCapabilityReview.missingCapabilities` is empty.
- Every `appShellCapabilityReview.communityResults[]` row has passing tabs, explicit and appropriate pinning policy, presentation states, community-list states, theme customization, and renderer-selection checks where applicable.
- After-screenshots prove the shell capability in the affected community/persona/workflow, not only source-code declarations.
- `production_ux_judge.dart` has no blocking failure for this criterion.
- `b25_iteration_scorecard.dart` records the ticket as resolved or no longer blocking.
- Screenshots are refreshed and hashes/timestamps/app commit SHA match the reviewed app version.

### Affected Evidence
- `independent-production-ux-review.json appShellCapabilityReview`
- `llm-product-doc-workflow-reconciliation-<run-id>.json appShellCapabilityReview`
- `llm-product-doc-workflow-reconciliation-<run-id>.json reviewedComponentDocPaths and componentDocReview.docs`
- `docs/Product Docs V2/Community Examples/<community>-product-experience.md Section 3.1`
- `docs/Build Plan V2/Skill/components/card-surfaces/app-shell-navigation-theming.md`
- `docs/Build Plan V2/Skill/components/card-surfaces/tab-renderer-contracts.md`
- `product-ux-screen-review-matrix.md affected screen rows and screenshots`
- `production-ux-criteria-scorecard.json/.md`

### Evidence To Collect
- Updated review JSON, scorecards, screenshots, remediation log, and tracker evidence for the fixed criterion.

### Acceptance Checks
- Every important primary/alternate action has before/tap/after or entry/action/result screenshots with distinct hashes.
- The after screenshot visibly proves a changed state, status, receipt, result, undo/change path, or receiver state.
- `appShellCapabilityReview.interactionTransitionResults[]` or lifecycle scorecards pass without missing transition evidence.
- `appShellCapabilityReview.status` is `pass`.
- `appShellCapabilityReview.missingCapabilities` is empty.
- Every `appShellCapabilityReview.communityResults[]` row has passing tabs, explicit and appropriate pinning policy, presentation states, community-list states, theme customization, and renderer-selection checks where applicable.
- After-screenshots prove the shell capability in the affected community/persona/workflow, not only source-code declarations.
- `production_ux_judge.dart` has no blocking failure for this criterion.
- `b25_iteration_scorecard.dart` records the ticket as resolved or no longer blocking.
- Screenshots are refreshed and hashes/timestamps/app commit SHA match the reviewed app version.

### Non-Goals
- Do not close the ticket without fresh evidence and a passing judge rerun.

### Commit Boundary

Commit this remediation iteration, refreshed evidence, scorecards, tickets, and tracker updates before starting the next UX feedback loop.

### Rerun Commands
- `dart run packages/tooling/loom_ux_judges/bin/b25_capture_workflow_screenshots.dart --mode full-b25 --device emulator-5554 --evidence-root ../docs/Build\ Plan\ V2/Evidence`
- `dart run packages/tooling/loom_ux_judges/bin/b25_capture_coverage_gate.dart --evidence-root ../docs/Build\ Plan\ V2/Evidence --output ../docs/Build\ Plan\ V2/Evidence/B25/b25-capture-coverage-report.json`
- `dart run packages/tooling/loom_ux_judges/bin/b25_evidence_collector.dart --evidence-root ../docs/Build\ Plan\ V2/Evidence --repo-root .. --run-id <next-run-id> --prior-review ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --output ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.md --matrix-output ../docs/Build\ Plan\ V2/Evidence/B25/product-ux-screen-review-matrix.md`
- `dart run packages/tooling/loom_ux_judges/bin/b25_workflow_persona_coverage_collector.dart --input ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --output ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/workflow-persona-coverage-matrix.md`
- `dart run packages/tooling/loom_ux_judges/bin/b25_independent_ux_judge.dart --input ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --output ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.md --matrix-output ../docs/Build\ Plan\ V2/Evidence/B25/product-ux-screen-review-matrix.md`
- `dart run packages/tooling/loom_ux_judges/bin/b25_component_doc_context.dart --repo-root .. --output ../docs/Build\ Plan\ V2/Evidence/B25/b25-component-doc-context-<next-run-id>.json --markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/b25-component-doc-context-<next-run-id>.md`
- `dart run packages/tooling/loom_ux_judges/bin/production_ux_judge.dart --input ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --base .. --output ../docs/Build\ Plan\ V2/Evidence/B25/production-ux-criteria-scorecard.json --markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/production-ux-criteria-scorecard.md --tickets-output ../docs/Build\ Plan\ V2/Evidence/B25/b25-remediation-tickets-<next-run-id>.json --tickets-markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/b25-remediation-tickets-<next-run-id>.md`
- `dart run packages/tooling/loom_ux_judges/bin/b25_iteration_scorecard.dart --review ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --judge ../docs/Build\ Plan\ V2/Evidence/B25/production-ux-criteria-scorecard.json --previous ../docs/Build\ Plan\ V2/Evidence/B25/b25-iteration-scorecard-latest.json --output ../docs/Build\ Plan\ V2/Evidence/B25/b25-iteration-scorecard-latest.json --markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/b25-iteration-scorecard-latest.md`

## B25-RT-013-app-shell-interaction-transition-gap

| Field | Value |
| --- | --- |
| Severity | major |
| Priority | P1 |
| Status | open |
| Review run | `b25-v4-pass-42` |
| Source criterion | `b25-c16-app-shell-capability-utilization` |
| Source findings | B25-APP-SHELL-INTERACTION-unknown-row |
| Title | Interaction transition evidence failed |
| Direct question | Do screenshots prove actionable controls were tapped and caused the correct visible state transition, including change/undo/result states where the workflow requires them? |
| Why it failed | Interaction `unknown-row` does not prove a tapped control caused the expected visible state transition. |
| Required outcome | Capture before/tap/after screenshots for this interaction and record the visible state change, including the user-facing result and undo/change path when applicable. |
| Remediation mode | `review-only` |
| Worker readiness | no concrete implementation work item was generated; planner must inspect the direct-question failure before assigning a worker |
| First required step | Review failing direct questions and add screen/workflow/persona-specific evidence before implementation. |

### Problem Statement

Interaction `unknown-row` does not prove a tapped control caused the expected visible state transition.

### Root Cause Hypothesis

The evidence does not yet satisfy the B25 production UX standard.

### Target Experience

Every important button and action proves a real interaction: the before screenshot, tapped/review state, and after screenshot show a changed status, result, receipt, or editable/undoable continuation.

### UX Principles
- Resolve blocking UX evidence before closing B25

### Concrete Improvements
- Extend capture automation to tap every important primary and alternate action in the reviewed workflows.
- Record before, action/review, and after screenshots with distinct hashes and visible state changes.
- For change/undo/edit paths, capture the later state proving the user can revise the prior response.

### Implementation Guidance
- Use `CommunityAppShellCustomizationSpec`, `LoomAppShellTabSpec`, and `LoomThemeCustomizationTokens` in `apps/loom_communities_demo/lib/main.dart`.
- Implement the capability centrally in the App Shell model, not as a one-off workflow widget hack.
- Recapture screenshots after implementation; source code alone cannot close this ticket.
- Update workflow capture helpers so important buttons are actually tapped and the resulting UI state is captured.
- Do not make UI conform to old test keys; update the evidence automation to follow the production interaction model.

### Content Guidance
- Write copy that matches the task: RSVP, donate, publish, approve, submit, review, search, export, transfer, invite, or reply.
- Each primary surface should include the domain data a user needs to decide and act.
- Use explicit alternate action copy such as Decline, Request changes, Change response, Edit, Withdraw, Cancel RSVP, Archive, Retry, Roll back, or Manage where the lifecycle requires it.
- Use result copy that persists: Sent, Posted, Confirmed, Paid, Receipt ready, Submitted, Approved, Rejected, Claimed, Returned, Read, or equivalent domain state.

### Visual Guidance
- Use screenshot evidence to judge visual hierarchy, density, navigation clarity, and polish on the reviewed device.

### Source Research Requirement

The independent UX review must attach internet or open-source pattern references before UI remediation. If live research is unavailable, use the bundled catalog entries and keep the research queries in the ticket so a reviewer can refresh them.

### UX Reference Patterns To Copy

| Reference | Source | URL | What to copy |
| --- | --- | --- | --- |
| Material navigation and information architecture | Material Design 3 / design-system | https://m3.material.io/components/navigation-drawer/overview<br>Also: https://m3.material.io/components/navigation-bar/overview | Organize screens by user jobs and destinations; keep primary actions visible and avoid exposing implementation taxonomy. |
| Apple HIG navigation and content organization | Apple Human Interface Guidelines / design-system | https://developer.apple.com/design/human-interface-guidelines/navigation | Make navigation predictable, content-centered, and appropriate for the user’s current task. |
| Material Design cards and lists | Material Design 3 / design-system | https://m3.material.io/components/cards/overview<br>Also: https://m3.material.io/components/lists/overview | Use cards/lists only as scannable containers with clear hierarchy, content, metadata, and actions. Do not use repeated cards as the whole primary workflow. |
| Flutter sample app implementation patterns | flutter/samples / open-source | https://github.com/flutter/samples | Copy the separation between app shell, route state, domain widgets, and testable UI states rather than hardcoding a single generic renderer. |

### Reference Research Queries
- production mobile UX review screenshot critique examples
- open source Flutter mobile app UX patterns GitHub

### Implementation Blocked By
- The ticket lacks row-level implementation evidence.

### Likely Files / Widgets
- `app/apps/loom_communities_demo/lib/main.dart`
- `app/apps/loom_communities_demo/test/b21_b25_production_ux_test.dart`
- `docs/Build Plan V2/Evidence/B25/production-ux-blueprint.md`
- `docs/Build Plan V2/Evidence/B25/independent-production-ux-review.json`
- `docs/Build Plan V2/Evidence/B25/product-ux-screen-review-matrix.md`

### Concrete Acceptance Criteria
- Every important primary/alternate action has before/tap/after or entry/action/result screenshots with distinct hashes.
- The after screenshot visibly proves a changed state, status, receipt, result, undo/change path, or receiver state.
- `appShellCapabilityReview.interactionTransitionResults[]` or lifecycle scorecards pass without missing transition evidence.
- `appShellCapabilityReview.status` is `pass`.
- `appShellCapabilityReview.missingCapabilities` is empty.
- Every `appShellCapabilityReview.communityResults[]` row has passing tabs, explicit and appropriate pinning policy, presentation states, community-list states, theme customization, and renderer-selection checks where applicable.
- After-screenshots prove the shell capability in the affected community/persona/workflow, not only source-code declarations.
- `production_ux_judge.dart` has no blocking failure for this criterion.
- `b25_iteration_scorecard.dart` records the ticket as resolved or no longer blocking.
- Screenshots are refreshed and hashes/timestamps/app commit SHA match the reviewed app version.

### Affected Evidence
- `independent-production-ux-review.json appShellCapabilityReview`
- `llm-product-doc-workflow-reconciliation-<run-id>.json appShellCapabilityReview`
- `llm-product-doc-workflow-reconciliation-<run-id>.json reviewedComponentDocPaths and componentDocReview.docs`
- `docs/Product Docs V2/Community Examples/<community>-product-experience.md Section 3.1`
- `docs/Build Plan V2/Skill/components/card-surfaces/app-shell-navigation-theming.md`
- `docs/Build Plan V2/Skill/components/card-surfaces/tab-renderer-contracts.md`
- `product-ux-screen-review-matrix.md affected screen rows and screenshots`
- `production-ux-criteria-scorecard.json/.md`

### Evidence To Collect
- Updated review JSON, scorecards, screenshots, remediation log, and tracker evidence for the fixed criterion.

### Acceptance Checks
- Every important primary/alternate action has before/tap/after or entry/action/result screenshots with distinct hashes.
- The after screenshot visibly proves a changed state, status, receipt, result, undo/change path, or receiver state.
- `appShellCapabilityReview.interactionTransitionResults[]` or lifecycle scorecards pass without missing transition evidence.
- `appShellCapabilityReview.status` is `pass`.
- `appShellCapabilityReview.missingCapabilities` is empty.
- Every `appShellCapabilityReview.communityResults[]` row has passing tabs, explicit and appropriate pinning policy, presentation states, community-list states, theme customization, and renderer-selection checks where applicable.
- After-screenshots prove the shell capability in the affected community/persona/workflow, not only source-code declarations.
- `production_ux_judge.dart` has no blocking failure for this criterion.
- `b25_iteration_scorecard.dart` records the ticket as resolved or no longer blocking.
- Screenshots are refreshed and hashes/timestamps/app commit SHA match the reviewed app version.

### Non-Goals
- Do not close the ticket without fresh evidence and a passing judge rerun.

### Commit Boundary

Commit this remediation iteration, refreshed evidence, scorecards, tickets, and tracker updates before starting the next UX feedback loop.

### Rerun Commands
- `dart run packages/tooling/loom_ux_judges/bin/b25_capture_workflow_screenshots.dart --mode full-b25 --device emulator-5554 --evidence-root ../docs/Build\ Plan\ V2/Evidence`
- `dart run packages/tooling/loom_ux_judges/bin/b25_capture_coverage_gate.dart --evidence-root ../docs/Build\ Plan\ V2/Evidence --output ../docs/Build\ Plan\ V2/Evidence/B25/b25-capture-coverage-report.json`
- `dart run packages/tooling/loom_ux_judges/bin/b25_evidence_collector.dart --evidence-root ../docs/Build\ Plan\ V2/Evidence --repo-root .. --run-id <next-run-id> --prior-review ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --output ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.md --matrix-output ../docs/Build\ Plan\ V2/Evidence/B25/product-ux-screen-review-matrix.md`
- `dart run packages/tooling/loom_ux_judges/bin/b25_workflow_persona_coverage_collector.dart --input ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --output ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/workflow-persona-coverage-matrix.md`
- `dart run packages/tooling/loom_ux_judges/bin/b25_independent_ux_judge.dart --input ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --output ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.md --matrix-output ../docs/Build\ Plan\ V2/Evidence/B25/product-ux-screen-review-matrix.md`
- `dart run packages/tooling/loom_ux_judges/bin/b25_component_doc_context.dart --repo-root .. --output ../docs/Build\ Plan\ V2/Evidence/B25/b25-component-doc-context-<next-run-id>.json --markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/b25-component-doc-context-<next-run-id>.md`
- `dart run packages/tooling/loom_ux_judges/bin/production_ux_judge.dart --input ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --base .. --output ../docs/Build\ Plan\ V2/Evidence/B25/production-ux-criteria-scorecard.json --markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/production-ux-criteria-scorecard.md --tickets-output ../docs/Build\ Plan\ V2/Evidence/B25/b25-remediation-tickets-<next-run-id>.json --tickets-markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/b25-remediation-tickets-<next-run-id>.md`
- `dart run packages/tooling/loom_ux_judges/bin/b25_iteration_scorecard.dart --review ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --judge ../docs/Build\ Plan\ V2/Evidence/B25/production-ux-criteria-scorecard.json --previous ../docs/Build\ Plan\ V2/Evidence/B25/b25-iteration-scorecard-latest.json --output ../docs/Build\ Plan\ V2/Evidence/B25/b25-iteration-scorecard-latest.json --markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/b25-iteration-scorecard-latest.md`

## B25-RT-014-app-shell-review-depth-gap

| Field | Value |
| --- | --- |
| Severity | major |
| Priority | P1 |
| Status | open |
| Review run | `b25-v4-pass-42` |
| Source criterion | `b25-c16-app-shell-capability-utilization` |
| Source findings | B25-APP-SHELL-REVIEW-DEPTH-loom-communities-shell-persona |
| Title | App Shell capability review lacks visible screenshot critique |
| Direct question | Does the App Shell capability review cite visible screenshot text, screenshot hashes, tab/renderer-specific critique, and direct answers rather than pass flags alone? |
| Why it failed | The App Shell review row has pass flags, but lacks enough visible text, screenshot hashes, or screen-specific critique to prove the shell capabilities were visually inspected. |
| Required outcome | Regenerate the App Shell capability review with visible text excerpts, screenshot hashes, tab/renderer-specific critiques, and direct answers for the reviewed community/persona. |
| Remediation mode | `review-only` |
| Worker readiness | no concrete implementation work item was generated; planner must inspect the direct-question failure before assigning a worker |
| First required step | Review failing direct questions and add screen/workflow/persona-specific evidence before implementation. |

### Problem Statement

The App Shell review row has pass flags, but lacks enough visible text, screenshot hashes, or screen-specific critique to prove the shell capabilities were visually inspected.

### Root Cause Hypothesis

The evidence does not yet satisfy the B25 production UX standard.

### Target Experience

The App Shell review is a real visual critique: it cites screenshot-visible evidence, answers direct questions per tab/renderer, and fails weak or generic UI even when source flags say a feature exists.

### UX Principles
- Resolve blocking UX evidence before closing B25

### Concrete Improvements
- Replace pass-flag-only App Shell review rows with screenshot-specific critique.
- Each row must quote visible text, cite screenshot hashes, name the tab/renderer contract, and answer whether the UI behaves like that product surface.
- Do not reuse a generic rationale across unrelated tabs or communities.

### Implementation Guidance
- Use `CommunityAppShellCustomizationSpec`, `LoomAppShellTabSpec`, and `LoomThemeCustomizationTokens` in `apps/loom_communities_demo/lib/main.dart`.
- Implement the capability centrally in the App Shell model, not as a one-off workflow widget hack.
- Recapture screenshots after implementation; source code alone cannot close this ticket.
- Regenerate the App Shell review from screenshots and visible text, not from implementation declarations.
- Make weak LLM reviews fail by leaving `status=fail` until visual critique is screen-specific.

### Content Guidance
- Write copy that matches the task: RSVP, donate, publish, approve, submit, review, search, export, transfer, invite, or reply.
- Each primary surface should include the domain data a user needs to decide and act.
- Use explicit alternate action copy such as Decline, Request changes, Change response, Edit, Withdraw, Cancel RSVP, Archive, Retry, Roll back, or Manage where the lifecycle requires it.
- Use result copy that persists: Sent, Posted, Confirmed, Paid, Receipt ready, Submitted, Approved, Rejected, Claimed, Returned, Read, or equivalent domain state.

### Visual Guidance
- Use screenshot evidence to judge visual hierarchy, density, navigation clarity, and polish on the reviewed device.

### Source Research Requirement

The independent UX review must attach internet or open-source pattern references before UI remediation. If live research is unavailable, use the bundled catalog entries and keep the research queries in the ticket so a reviewer can refresh them.

### UX Reference Patterns To Copy

| Reference | Source | URL | What to copy |
| --- | --- | --- | --- |
| Material navigation and information architecture | Material Design 3 / design-system | https://m3.material.io/components/navigation-drawer/overview<br>Also: https://m3.material.io/components/navigation-bar/overview | Organize screens by user jobs and destinations; keep primary actions visible and avoid exposing implementation taxonomy. |
| Apple HIG navigation and content organization | Apple Human Interface Guidelines / design-system | https://developer.apple.com/design/human-interface-guidelines/navigation | Make navigation predictable, content-centered, and appropriate for the user’s current task. |
| Material Design cards and lists | Material Design 3 / design-system | https://m3.material.io/components/cards/overview<br>Also: https://m3.material.io/components/lists/overview | Use cards/lists only as scannable containers with clear hierarchy, content, metadata, and actions. Do not use repeated cards as the whole primary workflow. |
| Flutter sample app implementation patterns | flutter/samples / open-source | https://github.com/flutter/samples | Copy the separation between app shell, route state, domain widgets, and testable UI states rather than hardcoding a single generic renderer. |

### Reference Research Queries
- production mobile UX review screenshot critique examples
- open source Flutter mobile app UX patterns GitHub

### Implementation Blocked By
- The ticket lacks row-level implementation evidence.

### Likely Files / Widgets
- `app/apps/loom_communities_demo/lib/main.dart`
- `app/apps/loom_communities_demo/test/b21_b25_production_ux_test.dart`
- `docs/Build Plan V2/Evidence/B25/production-ux-blueprint.md`
- `docs/Build Plan V2/Evidence/B25/independent-production-ux-review.json`
- `docs/Build Plan V2/Evidence/B25/product-ux-screen-review-matrix.md`

### Concrete Acceptance Criteria
- Every App Shell review row includes visible text excerpts and screenshot hashes.
- Every App Shell review row has non-boilerplate critique naming the tab, renderer, visible UI, and product-quality decision.
- A pass verdict is not based only on feature flags, source-code declarations, or absence of deterministic pixel findings.
- `appShellCapabilityReview.status` is `pass`.
- `appShellCapabilityReview.missingCapabilities` is empty.
- Every `appShellCapabilityReview.communityResults[]` row has passing tabs, explicit and appropriate pinning policy, presentation states, community-list states, theme customization, and renderer-selection checks where applicable.
- After-screenshots prove the shell capability in the affected community/persona/workflow, not only source-code declarations.
- `production_ux_judge.dart` has no blocking failure for this criterion.
- `b25_iteration_scorecard.dart` records the ticket as resolved or no longer blocking.
- Screenshots are refreshed and hashes/timestamps/app commit SHA match the reviewed app version.

### Affected Evidence
- `independent-production-ux-review.json appShellCapabilityReview`
- `llm-product-doc-workflow-reconciliation-<run-id>.json appShellCapabilityReview`
- `llm-product-doc-workflow-reconciliation-<run-id>.json reviewedComponentDocPaths and componentDocReview.docs`
- `docs/Product Docs V2/Community Examples/<community>-product-experience.md Section 3.1`
- `docs/Build Plan V2/Skill/components/card-surfaces/app-shell-navigation-theming.md`
- `docs/Build Plan V2/Skill/components/card-surfaces/tab-renderer-contracts.md`
- `product-ux-screen-review-matrix.md affected screen rows and screenshots`
- `production-ux-criteria-scorecard.json/.md`

### Evidence To Collect
- Updated review JSON, scorecards, screenshots, remediation log, and tracker evidence for the fixed criterion.

### Acceptance Checks
- Every App Shell review row includes visible text excerpts and screenshot hashes.
- Every App Shell review row has non-boilerplate critique naming the tab, renderer, visible UI, and product-quality decision.
- A pass verdict is not based only on feature flags, source-code declarations, or absence of deterministic pixel findings.
- `appShellCapabilityReview.status` is `pass`.
- `appShellCapabilityReview.missingCapabilities` is empty.
- Every `appShellCapabilityReview.communityResults[]` row has passing tabs, explicit and appropriate pinning policy, presentation states, community-list states, theme customization, and renderer-selection checks where applicable.
- After-screenshots prove the shell capability in the affected community/persona/workflow, not only source-code declarations.
- `production_ux_judge.dart` has no blocking failure for this criterion.
- `b25_iteration_scorecard.dart` records the ticket as resolved or no longer blocking.
- Screenshots are refreshed and hashes/timestamps/app commit SHA match the reviewed app version.

### Non-Goals
- Do not close the ticket without fresh evidence and a passing judge rerun.

### Commit Boundary

Commit this remediation iteration, refreshed evidence, scorecards, tickets, and tracker updates before starting the next UX feedback loop.

### Rerun Commands
- `dart run packages/tooling/loom_ux_judges/bin/b25_capture_workflow_screenshots.dart --mode full-b25 --device emulator-5554 --evidence-root ../docs/Build\ Plan\ V2/Evidence`
- `dart run packages/tooling/loom_ux_judges/bin/b25_capture_coverage_gate.dart --evidence-root ../docs/Build\ Plan\ V2/Evidence --output ../docs/Build\ Plan\ V2/Evidence/B25/b25-capture-coverage-report.json`
- `dart run packages/tooling/loom_ux_judges/bin/b25_evidence_collector.dart --evidence-root ../docs/Build\ Plan\ V2/Evidence --repo-root .. --run-id <next-run-id> --prior-review ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --output ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.md --matrix-output ../docs/Build\ Plan\ V2/Evidence/B25/product-ux-screen-review-matrix.md`
- `dart run packages/tooling/loom_ux_judges/bin/b25_workflow_persona_coverage_collector.dart --input ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --output ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/workflow-persona-coverage-matrix.md`
- `dart run packages/tooling/loom_ux_judges/bin/b25_independent_ux_judge.dart --input ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --output ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.md --matrix-output ../docs/Build\ Plan\ V2/Evidence/B25/product-ux-screen-review-matrix.md`
- `dart run packages/tooling/loom_ux_judges/bin/b25_component_doc_context.dart --repo-root .. --output ../docs/Build\ Plan\ V2/Evidence/B25/b25-component-doc-context-<next-run-id>.json --markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/b25-component-doc-context-<next-run-id>.md`
- `dart run packages/tooling/loom_ux_judges/bin/production_ux_judge.dart --input ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --base .. --output ../docs/Build\ Plan\ V2/Evidence/B25/production-ux-criteria-scorecard.json --markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/production-ux-criteria-scorecard.md --tickets-output ../docs/Build\ Plan\ V2/Evidence/B25/b25-remediation-tickets-<next-run-id>.json --tickets-markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/b25-remediation-tickets-<next-run-id>.md`
- `dart run packages/tooling/loom_ux_judges/bin/b25_iteration_scorecard.dart --review ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --judge ../docs/Build\ Plan\ V2/Evidence/B25/production-ux-criteria-scorecard.json --previous ../docs/Build\ Plan\ V2/Evidence/B25/b25-iteration-scorecard-latest.json --output ../docs/Build\ Plan\ V2/Evidence/B25/b25-iteration-scorecard-latest.json --markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/b25-iteration-scorecard-latest.md`
