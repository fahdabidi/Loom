# B25 Remediation Plan

| Field | Value |
| --- | --- |
| Review run | `b25-v4-pass-39` |
| Status | `open` |
| Source tickets | `../docs/Build Plan V2/Evidence/B25/b25-remediation-tickets-b25-v4-pass-40.json` |
| Ticket count | 8 |
| Scorecard status | `fail` |
| Remaining blocker/major | 0 |
| Blocking criteria failures | 2 |
| Product spec work items | 0 |
| Evidence repair work items | 0 |
| UI remediation work items | 0 |
| Work item sequencing | Product-spec work items must close first, then evidence repair work items, then matching UI remediation work items. |

## Source Tickets

| Ticket | Source criterion | Severity | Status | Title |
| --- | --- | --- | --- | --- |
| `B25-RT-001-b25-c14-llm-vision-ux-review` | `b25-c14-llm-vision-ux-review` | major | open | LLM vision UX judge has inspected screenshots semantically |
| `B25-RT-002-app-shell-tab-renderer-contract-gap` | `b25-c16-app-shell-capability-utilization` | major | open | CalendarTabSurface is not proven by screenshot-backed review |
| `B25-RT-003-app-shell-tab-renderer-contract-gap` | `b25-c16-app-shell-capability-utilization` | major | open | MessagesTabSurface is not proven by screenshot-backed review |
| `B25-RT-004-app-shell-tab-renderer-contract-gap` | `b25-c16-app-shell-capability-utilization` | major | open | MarketplaceTabSurface is not proven by screenshot-backed review |
| `B25-RT-005-app-shell-tab-renderer-contract-gap` | `b25-c16-app-shell-capability-utilization` | major | open | DocumentsTabSurface is not proven by screenshot-backed review |
| `B25-RT-006-app-shell-tab-renderer-contract-gap` | `b25-c16-app-shell-capability-utilization` | major | open | WorkflowStatusSurface is not proven by screenshot-backed review |
| `B25-RT-007-app-shell-interaction-transition-gap` | `b25-c16-app-shell-capability-utilization` | major | open | Interaction transitions are not fully screenshot-proven |
| `B25-RT-008-app-shell-review-depth-gap` | `b25-c16-app-shell-capability-utilization` | major | open | App Shell capability review lacks visible screenshot critique |

## B25-RB-003-recapture-rerun-closeout: Recapture evidence, rerun judges, and close resolved tickets

Prove the remediation with fresh screenshots, scorecards, and a committed iteration boundary.

| Field | Value |
| --- | --- |
| Status | open |
| Ticket IDs | B25-RT-001-b25-c14-llm-vision-ux-review, B25-RT-002-app-shell-tab-renderer-contract-gap, B25-RT-003-app-shell-tab-renderer-contract-gap, B25-RT-004-app-shell-tab-renderer-contract-gap, B25-RT-005-app-shell-tab-renderer-contract-gap, B25-RT-006-app-shell-tab-renderer-contract-gap, B25-RT-007-app-shell-interaction-transition-gap, B25-RT-008-app-shell-review-depth-gap |

### Worker Actions
- Rebuild and relaunch the Demo App on the reviewed emulator/device.
- Recapture affected screenshots with hashes, timestamps, device metadata, and app commit SHA.
- Regenerate B25 schema v4 review JSON, markdown review, screen matrix, remediation tickets, and iteration scorecard.
- Commit the full iteration before starting the next UX feedback loop.

### Implementation Guidance
- Treat the imported LLM vision review as the independent semantic critique.
- Prioritize screen rows and workflows named in `llmVisionReview.findings` and `llmVisionReview.screenReviews`.
- Do not close the ticket until a fresh LLM vision review over after-screenshots passes.
- Use `CommunityAppShellCustomizationSpec`, `LoomAppShellTabSpec`, and `LoomThemeCustomizationTokens` in `apps/loom_communities_demo/lib/main.dart`.
- Implement the capability centrally in the App Shell model, not as a one-off workflow widget hack.
- Recapture screenshots after implementation; source code alone cannot close this ticket.
- Represent tab-native renderer proof as data in `appShellCapabilityReview.tabRendererResults[]` so the production judge can validate it without trusting prose.
- Use the renderer contracts in `docs/CardSurfaces/tab-renderer-contracts.md` and the mirrored Skill doc when choosing the target UI.
- Update workflow capture helpers so important buttons are actually tapped and the resulting UI state is captured.
- Do not make UI conform to old test keys; update the evidence automation to follow the production interaction model.
- Regenerate the App Shell review from screenshots and visible text, not from implementation declarations.
- Make weak LLM reviews fail by leaving `status=fail` until visual critique is screen-specific.

### Likely Files / Widgets
- `app/apps/loom_communities_demo/lib/main.dart`
- `app/apps/loom_communities_demo/test/b21_b25_production_ux_test.dart`
- `docs/Build Plan V2/Evidence/B25/production-ux-blueprint.md`
- `docs/Build Plan V2/Evidence/B25/independent-production-ux-review.json`
- `docs/Build Plan V2/Evidence/B25/product-ux-screen-review-matrix.md`

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

### Evidence To Update
- independent-production-ux-review.json llmVisionReview
- independent-production-ux-review.json findings from source=llm-vision-ux-judge
- product-ux-screen-review-matrix.md affected screen rows
- production-ux-criteria-scorecard.json/.md
- independent-production-ux-review.json appShellCapabilityReview
- llm-product-doc-workflow-reconciliation-<run-id>.json appShellCapabilityReview
- docs/Product Docs V2/Community Examples/<community>-product-experience.md Section 3.1
- docs/Build Plan V2/Skill/components/card-surfaces/app-shell-navigation-theming.md
- product-ux-screen-review-matrix.md affected screen rows and screenshots
- Fresh holistic screenshots for primary homes, navigation, representative detail surfaces, and representative completion/result states.
- `holisticQuestionAnswers` with visible evidence, score, pass/fail answer, and specific rationale.
- `llmVisionReview` imported from a fresh LLM vision UX judge run against the after screenshots.
- Updated `production-ux-criteria-scorecard.json/.md` showing the criterion passes.
- Updated review JSON, scorecards, screenshots, remediation log, and tracker evidence for the fixed criterion.

### Acceptance Checks
- `production_ux_judge.dart` has no blocking failure for this criterion.
- `b25_iteration_scorecard.dart` records the ticket as resolved or no longer blocking.
- Screenshots are refreshed and hashes/timestamps/app commit SHA match the reviewed app version.
- `appShellCapabilityReview.tabRendererResults[]` contains passing rows for CalendarTabSurface, MessagesTabSurface, MarketplaceTabSurface, DocumentsTabSurface, and WorkflowStatusSurface.
- Each renderer row has screenshot row IDs, screenshot hashes, visible text, direct-question answers, and a screen-specific critique.
- The screenshots visibly match the renderer contract and do not rely on generic workflow-card fallback UI.
- `appShellCapabilityReview.status` is `pass`.
- `appShellCapabilityReview.missingCapabilities` is empty.
- Every `appShellCapabilityReview.communityResults[]` row has passing tabs, explicit and appropriate pinning policy, presentation states, community-list states, theme customization, and renderer-selection checks where applicable.
- After-screenshots prove the shell capability in the affected community/persona/workflow, not only source-code declarations.
- Every important primary/alternate action has before/tap/after or entry/action/result screenshots with distinct hashes.
- The after screenshot visibly proves a changed state, status, receipt, result, undo/change path, or receiver state.
- `appShellCapabilityReview.interactionTransitionResults[]` or lifecycle scorecards pass without missing transition evidence.
- Every App Shell review row includes visible text excerpts and screenshot hashes.
- Every App Shell review row has non-boilerplate critique naming the tab, renderer, visible UI, and product-quality decision.
- A pass verdict is not based only on feature flags, source-code declarations, or absence of deterministic pixel findings.

### Concrete Acceptance Criteria
- `production_ux_judge.dart` has no blocking failure for this criterion.
- `b25_iteration_scorecard.dart` records the ticket as resolved or no longer blocking.
- Screenshots are refreshed and hashes/timestamps/app commit SHA match the reviewed app version.
- `appShellCapabilityReview.tabRendererResults[]` contains passing rows for CalendarTabSurface, MessagesTabSurface, MarketplaceTabSurface, DocumentsTabSurface, and WorkflowStatusSurface.
- Each renderer row has screenshot row IDs, screenshot hashes, visible text, direct-question answers, and a screen-specific critique.
- The screenshots visibly match the renderer contract and do not rely on generic workflow-card fallback UI.
- `appShellCapabilityReview.status` is `pass`.
- `appShellCapabilityReview.missingCapabilities` is empty.
- Every `appShellCapabilityReview.communityResults[]` row has passing tabs, explicit and appropriate pinning policy, presentation states, community-list states, theme customization, and renderer-selection checks where applicable.
- After-screenshots prove the shell capability in the affected community/persona/workflow, not only source-code declarations.
- Every important primary/alternate action has before/tap/after or entry/action/result screenshots with distinct hashes.
- The after screenshot visibly proves a changed state, status, receipt, result, undo/change path, or receiver state.
- `appShellCapabilityReview.interactionTransitionResults[]` or lifecycle scorecards pass without missing transition evidence.
- Every App Shell review row includes visible text excerpts and screenshot hashes.
- Every App Shell review row has non-boilerplate critique naming the tab, renderer, visible UI, and product-quality decision.
- A pass verdict is not based only on feature flags, source-code declarations, or absence of deterministic pixel findings.

### Rerun Commands
- `dart run packages/tooling/loom_ux_judges/bin/b25_capture_workflow_screenshots.dart --mode full-b25 --device emulator-5554 --evidence-root ../docs/Build\ Plan\ V2/Evidence`
- `dart run packages/tooling/loom_ux_judges/bin/b25_capture_coverage_gate.dart --evidence-root ../docs/Build\ Plan\ V2/Evidence --output ../docs/Build\ Plan\ V2/Evidence/B25/b25-capture-coverage-report.json`
- `dart run packages/tooling/loom_ux_judges/bin/b25_evidence_collector.dart --evidence-root ../docs/Build\ Plan\ V2/Evidence --repo-root .. --run-id <next-run-id> --prior-review ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --output ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.md --matrix-output ../docs/Build\ Plan\ V2/Evidence/B25/product-ux-screen-review-matrix.md`
- `dart run packages/tooling/loom_ux_judges/bin/b25_workflow_persona_coverage_collector.dart --input ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --output ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/workflow-persona-coverage-matrix.md`
- `dart run packages/tooling/loom_ux_judges/bin/b25_independent_ux_judge.dart --input ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --output ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.md --matrix-output ../docs/Build\ Plan\ V2/Evidence/B25/product-ux-screen-review-matrix.md`
- `dart run packages/tooling/loom_ux_judges/bin/production_ux_judge.dart --input ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --base .. --output ../docs/Build\ Plan\ V2/Evidence/B25/production-ux-criteria-scorecard.json --markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/production-ux-criteria-scorecard.md --tickets-output ../docs/Build\ Plan\ V2/Evidence/B25/b25-remediation-tickets-<next-run-id>.json --tickets-markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/b25-remediation-tickets-<next-run-id>.md`
- `dart run packages/tooling/loom_ux_judges/bin/b25_iteration_scorecard.dart --review ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --judge ../docs/Build\ Plan\ V2/Evidence/B25/production-ux-criteria-scorecard.json --previous ../docs/Build\ Plan\ V2/Evidence/B25/b25-iteration-scorecard-latest.json --output ../docs/Build\ Plan\ V2/Evidence/B25/b25-iteration-scorecard-latest.json --markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/b25-iteration-scorecard-latest.md`

### Commit Boundary

Commit this remediation batch, refreshed evidence, judge outputs, scorecards, and tracker updates before the next UX feedback loop. If the committed pass still fails, the following pass starts by sending its tickets to the Remediation Planner.

## Planner Rules

- Worker agents implement from remediation batches, not from optimistic summaries.
- Product-spec work items must be completed and rerun before evidence repair or UI remediation work items for the same community are assigned.
- Evidence repair work items must be completed and rerun before UI remediation work items for the same community/workflow/persona are assigned.
- UI remediation work must be scoped by community/workflow/persona and target production surface, not by a broad global ticket summary.
- The independent judge must rerun after each batch that changes UI, evidence, or critique.
- No next UX feedback loop starts until the current remediation iteration is committed.
