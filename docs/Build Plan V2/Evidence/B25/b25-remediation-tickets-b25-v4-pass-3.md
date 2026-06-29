# Remediation Tickets

| Field | Value |
| --- | --- |
| Tool | `production-ux-judge` |
| Status | `fail` |
| Open tickets | 7 |

## B25-RT-001-b25-c01-no-blocker-major

| Field | Value |
| --- | --- |
| Severity | major |
| Priority | P1 |
| Status | open |
| Review run | `b25-v4-pass-3` |
| Source criterion | `b25-c01-no-blocker-major` |
| Source findings | B25-WORKFLOW-PERSONA-COVERAGE-INCOMPLETE, B25-WORKFLOW-PERSONA-UX-FAILED, B25-HOLISTIC-UX-FAILED |
| Title | No unresolved blocker or major findings |
| Direct question | Are there zero unresolved blocker or major findings in the current production UX evidence? |
| Why it failed | Unresolved blocker/major counts are blocker=0 major=3. |
| Required outcome | Resolve blockers/majors, rerun review, and record zero unresolved blocker/major findings. |
| Remediation mode | `closeout-after-all-remediation` |
| Worker readiness | blocked until the evidence and UI remediation tickets are resolved |
| First required step | Do not implement from this summary ticket directly; resolve the referenced evidence and UI tickets, then rerun the production UX judge. |

### Problem Statement

B25 still has unresolved major production UX findings, so the app cannot be considered production-grade.

### Root Cause Hypothesis

The review loop has not yet converted all blocking judge failures into completed, evidence-backed fixes.

### Target Experience

The next B25 pass should show zero unresolved blocker/major findings and a scorecard that can close the phase.

### UX Principles
- Resolve blocking UX evidence before closing B25

### Concrete Improvements
- Resolve every open blocker/major remediation ticket or downgrade only with owner acceptance and evidence.
- Update `findings`, unresolved finding arrays, remediation log, and iteration scorecard after fixes.
- Rerun the production UX judge and verify unresolved blocker/major counts are zero.

### Implementation Guidance
- Use each open remediation ticket as the implementation backlog.
- Update review JSON, remediation log, scorecards, tracker, and screenshots together.

### Content Guidance
- Replace placeholder, framework, workflow, evidence, or metadata language with user-facing product copy.
- Use content that helps the target persona understand status, options, consequences, and next steps.

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
| Material detail surface composition | Material Design 3 / design-system | https://m3.material.io/components/cards/overview | Build a domain detail page with primary content, metadata, status, and actions instead of a generic task card. |

### Reference Research Queries
- production mobile UX review screenshot critique examples
- open source Flutter mobile app UX patterns GitHub
- open source Flutter domain-native-surface mobile UI example GitHub
- persona capability matrix surface with roles, allowed actions, receiver states, and denied/hidden behavior mobile UX pattern
- Material Design persona capability matrix surface with roles, allowed actions, receiver states, and denied/hidden behavior mobile pattern

### Implementation Blocked By
- Open blocker/major B25 tickets remain.
- The scorecard cannot close until those tickets rerun clean.

### Affected Workflow/Persona Coverage

Showing 2 of 2 affected coverage rows. Full detail is in the JSON ticket.

| Coverage row | Status | Community | Workflow | Persona | Missing evidence | Screen rows | Target surface |
| --- | --- | --- | --- | --- | --- | ---: | --- |
| `b25-wp-062-wf-persona-role-inventory-capability-matrix-persona-role-inventory-admin` | `fail` | persona-role-inventory | `wf_persona-role-inventory-capability-matrix` | admin | action/review screenshot | 1 | persona capability matrix surface with roles, allowed actions, receiver states, and denied/hidden behavior |
| `b25-wp-063-wf-persona-role-inventory-capability-matrix-persona-role-inventory-member` | `fail` | persona-role-inventory | `wf_persona-role-inventory-capability-matrix` | member | result/receiver screenshot | 1 | persona capability matrix surface with roles, allowed actions, receiver states, and denied/hidden behavior |

### Affected Screen Rows

Showing 2 of 2 affected screen rows. Full detail is in the JSON ticket.

| Screen row | Community | Workflow | Persona | State | Screenshot | Hash | Visible text | Current surface | Exact UX failure | Target surface |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `b25-v4-row-184-wf-persona-role-inventory-capability-matrix-0` | persona-role-inventory | `wf_persona-role-inventory-capability-matrix` | admin | B17_persona_inventory_active_admin | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/docs/Build Plan V2/Evidence/B17/screenshots/B17_persona_inventory_active_admin.png` | `8be6fe33f9324...` | all demo communities define two or more personas \| all workflow/persona matrix rows have actor, receiver, read-only, or disabled state \| receiver rows declare dependency evidence \| matrix rows: 145 | coverage-or-review-incomplete / unverified-primary-surface | Primary surface classification is incomplete or unverified. Current row verdict is `fail` with severity `major`. | persona capability matrix surface with roles, allowed actions, receiver states, and denied/hidden behavior |
| `b25-v4-row-185-wf-persona-role-inventory-capability-matrix-1` | persona-role-inventory | `wf_persona-role-inventory-capability-matrix` | member | B17_persona_inventory_picker | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/docs/Build Plan V2/Evidence/B17/screenshots/B17_persona_inventory_picker.png` | `3b02a3887b3aa...` | all demo communities define two or more personas \| all workflow/persona matrix rows have actor, receiver, read-only, or disabled state \| receiver rows declare dependency evidence \| matrix rows: 145 | coverage-or-review-incomplete / unverified-primary-surface | Primary surface classification is incomplete or unverified. Current row verdict is `fail` with severity `major`. | persona capability matrix surface with roles, allowed actions, receiver states, and denied/hidden behavior |

### Failing Workflow/Persona Scorecards

Showing 2 of 2 failing scorecards. Full detail is in the JSON ticket.

| Scorecard | Community | Workflow | Persona | Failed questions | Target surface |
| --- | --- | --- | --- | ---: | --- |
| `b25-wp-062-wf-persona-role-inventory-capability-matrix-persona-role-inventory-admin` | persona-role-inventory | `wf_persona-role-inventory-capability-matrix` | admin | 3 | persona capability matrix surface with roles, allowed actions, receiver states, and denied/hidden behavior |
| `b25-wp-063-wf-persona-role-inventory-capability-matrix-persona-role-inventory-member` | persona-role-inventory | `wf_persona-role-inventory-capability-matrix` | member | 3 | persona capability matrix surface with roles, allowed actions, receiver states, and denied/hidden behavior |

### Failing Direct Questions

| Question | Scope | Score | Why | Required fix |
| --- | --- | ---: | --- | --- |
| Does the whole experience feel like a real production community app for the target users, not merely an implemented workflow harness? | holistic | 35 | The review cannot claim production-grade UX while workflow/persona evidence is incomplete or failing. | Complete workflow/persona coverage and remediate failing scorecards before claiming production-grade UX. |
| Is the UI modern, easy to use, easy to navigate, and visually appealing for the target persona? | holistic | 40 | Visible UI/text evidence is suitable for judging modern UI quality. | None. |
| Is the overall information architecture organized around community content and real jobs-to-be-done instead of workflow lists or validation surfaces? | holistic | 45 | Failing workflow/persona scorecards prevent a holistic community IA pass. | Replace generic workflow-list or validation surfaces with domain-native community sections and rerun scorecards. |
| Does the visible UI avoid blocking or major overlap, clipping, crowding, default-scaffold, repeated-card, checklist-modal, and thin-content defects? | holistic | 45 | The judge cannot clear layout/content defects while row-level evidence remains incomplete or unsupported. | Complete screenshot-backed review rows and remediate any row-level layout/content defects. |

### Likely Files / Widgets
- `app/apps/loom_communities_demo/lib/main.dart`
- `app/apps/loom_communities_demo/test/b21_b25_production_ux_test.dart`
- `docs/Build Plan V2/Evidence/B25/production-ux-blueprint.md`
- `docs/Build Plan V2/Evidence/B25/independent-production-ux-review.json`
- `docs/Build Plan V2/Evidence/B25/product-ux-screen-review-matrix.md`
- `docs/Build Plan V2/Evidence/B25/product-ux-remediation-loop.md`
- `docs/Build Plan V2/Build Tracker.md`
- `app/apps/loom_communities_demo/integration_test/workflow_ui_evidence_test.dart`
- `app/apps/loom_communities_demo/test/workflow_ui_test_harness.dart`

### Concrete Acceptance Criteria
- Unresolved blocker and major finding counts are both zero.
- `production_ux_judge.dart` has no blocking failure for this criterion.
- `b25_iteration_scorecard.dart` records the ticket as resolved or no longer blocking.
- Screenshots are refreshed and hashes/timestamps/app commit SHA match the reviewed app version.
- Screen row `b25-v4-row-184-wf-persona-role-inventory-capability-matrix-0` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-184-wf-persona-role-inventory-capability-matrix-0` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-184-wf-persona-role-inventory-capability-matrix-0` names visible UI elements, visible text, persona `admin`, workflow `wf_persona-role-inventory-capability-matrix`, and the exact product UX issue.
- Primary surface for `wf_persona-role-inventory-capability-matrix` is documented as `persona capability matrix surface with roles, allowed actions, receiver states, and denied/hidden behavior` or another explicit domain-native surface.
- Fresh screenshot path/hash/timestamp/app commit SHA are recorded after the fix.
- Screen row `b25-v4-row-185-wf-persona-role-inventory-capability-matrix-1` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-185-wf-persona-role-inventory-capability-matrix-1` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-185-wf-persona-role-inventory-capability-matrix-1` names visible UI elements, visible text, persona `member`, workflow `wf_persona-role-inventory-capability-matrix`, and the exact product UX issue.
- Coverage row has a specific persona and personaId.
- Coverage row has entry, action/review, and result/receiver screenshots.
- Every listed screenshot path exists and has a fresh hash/timestamp/app commit SHA.
- The workflow/persona scorecard passes after rerun.

### Affected Evidence
- `independent-production-ux-review.json findings`
- `product-ux-remediation-loop.md`
- `b25-iteration-scorecard-latest.json/.md`
- `Build Tracker.md B25 row and execution ledger`

### Evidence To Collect
- Updated review JSON, scorecards, screenshots, remediation log, and tracker evidence for the fixed criterion.

### Acceptance Checks
- Unresolved blocker and major finding counts are both zero.
- `production_ux_judge.dart` has no blocking failure for this criterion.
- `b25_iteration_scorecard.dart` records the ticket as resolved or no longer blocking.
- Screenshots are refreshed and hashes/timestamps/app commit SHA match the reviewed app version.

### Non-Goals
- Do not close the ticket without fresh evidence and a passing judge rerun.

### Commit Boundary

Commit this remediation iteration, refreshed evidence, scorecards, tickets, and tracker updates before starting the next UX feedback loop.

### Rerun Commands
- `dart run packages/tooling/loom_ux_judges/bin/b25_evidence_collector.dart --evidence-root ../docs/Build\ Plan\ V2/Evidence --repo-root .. --run-id <next-run-id> --prior-review ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --output ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.md --matrix-output ../docs/Build\ Plan\ V2/Evidence/B25/product-ux-screen-review-matrix.md`
- `dart run packages/tooling/loom_ux_judges/bin/b25_workflow_persona_coverage_collector.dart --input ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --output ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/workflow-persona-coverage-matrix.md`
- `dart run packages/tooling/loom_ux_judges/bin/b25_independent_ux_judge.dart --input ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --output ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.md --matrix-output ../docs/Build\ Plan\ V2/Evidence/B25/product-ux-screen-review-matrix.md`
- `dart run packages/tooling/loom_ux_judges/bin/production_ux_judge.dart --input ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --base .. --output ../docs/Build\ Plan\ V2/Evidence/B25/production-ux-criteria-scorecard.json --markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/production-ux-criteria-scorecard.md --tickets-output ../docs/Build\ Plan\ V2/Evidence/B25/b25-remediation-tickets-<next-run-id>.json --tickets-markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/b25-remediation-tickets-<next-run-id>.md`
- `dart run packages/tooling/loom_ux_judges/bin/b25_iteration_scorecard.dart --review ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --judge ../docs/Build\ Plan\ V2/Evidence/B25/production-ux-criteria-scorecard.json --previous ../docs/Build\ Plan\ V2/Evidence/B25/b25-iteration-scorecard-latest.json --output ../docs/Build\ Plan\ V2/Evidence/B25/b25-iteration-scorecard-latest.json --markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/b25-iteration-scorecard-latest.md`

## B25-RT-002-b25-c03-production-grade-experience

| Field | Value |
| --- | --- |
| Severity | major |
| Priority | P1 |
| Status | open |
| Review run | `b25-v4-pass-3` |
| Source criterion | `b25-c03-production-grade-experience` |
| Source findings | B25-WORKFLOW-PERSONA-COVERAGE-INCOMPLETE, B25-HOLISTIC-UX-FAILED |
| Title | Reviewer can state the experience feels production-grade |
| Direct question | Does the whole experience feel like a real production community app for the target users, not merely an implemented workflow harness? |
| Why it failed | holistic direct-question answers are missing, weak, partial, or blocking: b25-holistic-production-grade, b25-holistic-modern-intentional, b25-holistic-community-ia, b25-holistic-layout-defects. |
| Required outcome | Run the independent screenshot-first review and record a production-grade verdict grounded in screen evidence. |
| Remediation mode | `evidence-repair-before-ui-remediation` |
| Worker readiness | not ready for UI implementation until evidence repair work items are completed and the independent judge reruns |
| First required step | Complete the evidenceRepairWorkItems: concrete persona/personaId, screenshot-derived visible text, screen-specific critique, coverage row proof, and workflow/persona scorecards. |

### Problem Statement

The evidence does not prove that target users experience the app as a real production community product rather than a workflow validation harness.

### Root Cause Hypothesis

The pass has evidence capture, but not a completed independent product-quality judgment grounded in screenshots.

### Target Experience

A target user should immediately understand the community, see relevant content, and complete meaningful tasks without recognizing the app as a test harness.

### UX Principles
- Judge what the visible product proves, not what the implementation intended.
- Prioritize target-user comprehension, task completion, and product credibility.

### Concrete Improvements
- Run a screenshot-first holistic review of the full community experience from the target-user perspective.
- Record direct yes/no answers that cite visible UI and explain whether the experience feels like a real production community app.
- Fix any whole-product issues where screens feel like validation harnesses, implementation summaries, or thin prototypes.

### Implementation Guidance
- Inspect `apps/loom_communities_demo/lib` for the primary community home, shell, card, detail, and workflow surface widgets.
- Compare every change against `docs/Build Plan V2/Evidence/B25/production-ux-blueprint.md` before coding.
- Update widget tests and B25 evidence expectations when user-facing hierarchy, copy, or surface structure changes.

### Content Guidance
- Replace placeholder, framework, workflow, evidence, or metadata language with user-facing product copy.
- Use content that helps the target persona understand status, options, consequences, and next steps.

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
| Material detail surface composition | Material Design 3 / design-system | https://m3.material.io/components/cards/overview | Build a domain detail page with primary content, metadata, status, and actions instead of a generic task card. |

### Reference Research Queries
- production mobile UX review screenshot critique examples
- open source Flutter mobile app UX patterns GitHub
- open source Flutter domain-native-surface mobile UI example GitHub
- persona capability matrix surface with roles, allowed actions, receiver states, and denied/hidden behavior mobile UX pattern
- Material Design persona capability matrix surface with roles, allowed actions, receiver states, and denied/hidden behavior mobile pattern

### Implementation Blocked By
- Affected rows still use generic or missing persona data.
- Visible text is not proven from screenshot OCR/manual extraction.
- Screen-specific critiques are incomplete or reusable.
- Primary surface classification is incomplete or unverified.

### Evidence Repair Work Items

Showing 2 of 2 work items. Full detail is in the JSON artifact.

| Work item | Stage | Community | Workflow | Persona | Screens | Coverage | Target surface | Blocked until |
| --- | --- | --- | --- | --- | ---: | ---: | --- | --- |
| `b25-wi-evidence-repair-persona-role-inventory-wf-persona-role-inventory-capability-matrix-persona-role-inventory-admin` | `evidence-repair` | persona-role-inventory | `wf_persona-role-inventory-capability-matrix` | admin | 1 | 1 | persona capability matrix surface with roles, allowed actions, receiver states, and denied/hidden behavior |  |
| `b25-wi-evidence-repair-persona-role-inventory-wf-persona-role-inventory-capability-matrix-persona-role-inventory-member` | `evidence-repair` | persona-role-inventory | `wf_persona-role-inventory-capability-matrix` | member | 1 | 1 | persona capability matrix surface with roles, allowed actions, receiver states, and denied/hidden behavior |  |

### Evidence Repair Work Items Reference Patterns

| Reference | Source | URL | What to copy |
| --- | --- | --- | --- |
| Material detail surface composition | Material Design 3 / design-system | https://m3.material.io/components/cards/overview | Build a domain detail page with primary content, metadata, status, and actions instead of a generic task card. |
| Material Design cards and lists | Material Design 3 / design-system | https://m3.material.io/components/cards/overview<br>Also: https://m3.material.io/components/lists/overview | Use cards/lists only as scannable containers with clear hierarchy, content, metadata, and actions. Do not use repeated cards as the whole primary workflow. |
| Flutter sample app implementation patterns | flutter/samples / open-source | https://github.com/flutter/samples | Copy the separation between app shell, route state, domain widgets, and testable UI states rather than hardcoding a single generic renderer. |
| Material navigation and information architecture | Material Design 3 / design-system | https://m3.material.io/components/navigation-drawer/overview<br>Also: https://m3.material.io/components/navigation-bar/overview | Organize screens by user jobs and destinations; keep primary actions visible and avoid exposing implementation taxonomy. |
| Apple HIG navigation and content organization | Apple Human Interface Guidelines / design-system | https://developer.apple.com/design/human-interface-guidelines/navigation | Make navigation predictable, content-centered, and appropriate for the user’s current task. |

### UI Remediation Work Items

Showing 2 of 2 work items. Full detail is in the JSON artifact.

| Work item | Stage | Community | Workflow | Persona | Screens | Coverage | Target surface | Blocked until |
| --- | --- | --- | --- | --- | ---: | ---: | --- | --- |
| `b25-wi-ui-remediation-persona-role-inventory-wf-persona-role-inventory-capability-matrix-persona-role-inventory-admin` | `ui-remediation` | persona-role-inventory | `wf_persona-role-inventory-capability-matrix` | admin | 1 | 1 | persona capability matrix surface with roles, allowed actions, receiver states, and denied/hidden behavior | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-persona-role-inventory-wf-persona-role-inventory-capability-matrix-persona-role-inventory-member` | `ui-remediation` | persona-role-inventory | `wf_persona-role-inventory-capability-matrix` | member | 1 | 1 | persona capability matrix surface with roles, allowed actions, receiver states, and denied/hidden behavior | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |

### UI Remediation Work Items Reference Patterns

| Reference | Source | URL | What to copy |
| --- | --- | --- | --- |
| Material detail surface composition | Material Design 3 / design-system | https://m3.material.io/components/cards/overview | Build a domain detail page with primary content, metadata, status, and actions instead of a generic task card. |
| Material Design cards and lists | Material Design 3 / design-system | https://m3.material.io/components/cards/overview<br>Also: https://m3.material.io/components/lists/overview | Use cards/lists only as scannable containers with clear hierarchy, content, metadata, and actions. Do not use repeated cards as the whole primary workflow. |
| Flutter sample app implementation patterns | flutter/samples / open-source | https://github.com/flutter/samples | Copy the separation between app shell, route state, domain widgets, and testable UI states rather than hardcoding a single generic renderer. |
| Material navigation and information architecture | Material Design 3 / design-system | https://m3.material.io/components/navigation-drawer/overview<br>Also: https://m3.material.io/components/navigation-bar/overview | Organize screens by user jobs and destinations; keep primary actions visible and avoid exposing implementation taxonomy. |
| Apple HIG navigation and content organization | Apple Human Interface Guidelines / design-system | https://developer.apple.com/design/human-interface-guidelines/navigation | Make navigation predictable, content-centered, and appropriate for the user’s current task. |

### Affected Workflow/Persona Coverage

Showing 2 of 2 affected coverage rows. Full detail is in the JSON ticket.

| Coverage row | Status | Community | Workflow | Persona | Missing evidence | Screen rows | Target surface |
| --- | --- | --- | --- | --- | --- | ---: | --- |
| `b25-wp-062-wf-persona-role-inventory-capability-matrix-persona-role-inventory-admin` | `fail` | persona-role-inventory | `wf_persona-role-inventory-capability-matrix` | admin | action/review screenshot | 1 | persona capability matrix surface with roles, allowed actions, receiver states, and denied/hidden behavior |
| `b25-wp-063-wf-persona-role-inventory-capability-matrix-persona-role-inventory-member` | `fail` | persona-role-inventory | `wf_persona-role-inventory-capability-matrix` | member | result/receiver screenshot | 1 | persona capability matrix surface with roles, allowed actions, receiver states, and denied/hidden behavior |

### Affected Screen Rows

Showing 2 of 2 affected screen rows. Full detail is in the JSON ticket.

| Screen row | Community | Workflow | Persona | State | Screenshot | Hash | Visible text | Current surface | Exact UX failure | Target surface |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `b25-v4-row-184-wf-persona-role-inventory-capability-matrix-0` | persona-role-inventory | `wf_persona-role-inventory-capability-matrix` | admin | B17_persona_inventory_active_admin | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/docs/Build Plan V2/Evidence/B17/screenshots/B17_persona_inventory_active_admin.png` | `8be6fe33f9324...` | all demo communities define two or more personas \| all workflow/persona matrix rows have actor, receiver, read-only, or disabled state \| receiver rows declare dependency evidence \| matrix rows: 145 | coverage-or-review-incomplete / unverified-primary-surface | Primary surface classification is incomplete or unverified. Current row verdict is `fail` with severity `major`. | persona capability matrix surface with roles, allowed actions, receiver states, and denied/hidden behavior |
| `b25-v4-row-185-wf-persona-role-inventory-capability-matrix-1` | persona-role-inventory | `wf_persona-role-inventory-capability-matrix` | member | B17_persona_inventory_picker | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/docs/Build Plan V2/Evidence/B17/screenshots/B17_persona_inventory_picker.png` | `3b02a3887b3aa...` | all demo communities define two or more personas \| all workflow/persona matrix rows have actor, receiver, read-only, or disabled state \| receiver rows declare dependency evidence \| matrix rows: 145 | coverage-or-review-incomplete / unverified-primary-surface | Primary surface classification is incomplete or unverified. Current row verdict is `fail` with severity `major`. | persona capability matrix surface with roles, allowed actions, receiver states, and denied/hidden behavior |

### Failing Direct Questions

| Question | Scope | Score | Why | Required fix |
| --- | --- | ---: | --- | --- |
| Does the whole experience feel like a real production community app for the target users, not merely an implemented workflow harness? | holistic | 35 | The review cannot claim production-grade UX while workflow/persona evidence is incomplete or failing. | Complete workflow/persona coverage and remediate failing scorecards before claiming production-grade UX. |
| Is the UI modern, easy to use, easy to navigate, and visually appealing for the target persona? | holistic | 40 | Visible UI/text evidence is suitable for judging modern UI quality. | None. |
| Is the overall information architecture organized around community content and real jobs-to-be-done instead of workflow lists or validation surfaces? | holistic | 45 | Failing workflow/persona scorecards prevent a holistic community IA pass. | Replace generic workflow-list or validation surfaces with domain-native community sections and rerun scorecards. |
| Does the visible UI avoid blocking or major overlap, clipping, crowding, default-scaffold, repeated-card, checklist-modal, and thin-content defects? | holistic | 45 | The judge cannot clear layout/content defects while row-level evidence remains incomplete or unsupported. | Complete screenshot-backed review rows and remediate any row-level layout/content defects. |

### Likely Files / Widgets
- `app/apps/loom_communities_demo/lib/main.dart`
- `app/apps/loom_communities_demo/test/b21_b25_production_ux_test.dart`
- `docs/Build Plan V2/Evidence/B25/production-ux-blueprint.md`
- `docs/Build Plan V2/Evidence/B25/independent-production-ux-review.json`
- `docs/Build Plan V2/Evidence/B25/product-ux-screen-review-matrix.md`
- `app/apps/loom_communities_demo/integration_test/workflow_ui_evidence_test.dart`
- `app/apps/loom_communities_demo/test/workflow_ui_test_harness.dart`

### Concrete Acceptance Criteria
- Holistic direct-question answers are present, screenshot-backed, non-boilerplate, and pass.
- `production_ux_judge.dart` has no blocking failure for this criterion.
- `b25_iteration_scorecard.dart` records the ticket as resolved or no longer blocking.
- Screenshots are refreshed and hashes/timestamps/app commit SHA match the reviewed app version.
- Screen row `b25-v4-row-184-wf-persona-role-inventory-capability-matrix-0` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-184-wf-persona-role-inventory-capability-matrix-0` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-184-wf-persona-role-inventory-capability-matrix-0` names visible UI elements, visible text, persona `admin`, workflow `wf_persona-role-inventory-capability-matrix`, and the exact product UX issue.
- Primary surface for `wf_persona-role-inventory-capability-matrix` is documented as `persona capability matrix surface with roles, allowed actions, receiver states, and denied/hidden behavior` or another explicit domain-native surface.
- Fresh screenshot path/hash/timestamp/app commit SHA are recorded after the fix.
- Screen row `b25-v4-row-185-wf-persona-role-inventory-capability-matrix-1` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-185-wf-persona-role-inventory-capability-matrix-1` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-185-wf-persona-role-inventory-capability-matrix-1` names visible UI elements, visible text, persona `member`, workflow `wf_persona-role-inventory-capability-matrix`, and the exact product UX issue.
- Coverage row has a specific persona and personaId.
- Coverage row has entry, action/review, and result/receiver screenshots.
- Every listed screenshot path exists and has a fresh hash/timestamp/app commit SHA.
- The workflow/persona scorecard passes after rerun.

### Affected Evidence
- `independent-production-ux-review.json holisticQuestionAnswers`
- `independent-production-ux-review.md holistic review summary`
- `product-ux-screen-review-matrix.md relevant screen rows`
- `production-ux-criteria-scorecard.json/.md`

### Evidence To Collect
- Fresh holistic screenshots for primary homes, navigation, representative detail surfaces, and representative completion/result states.
- `holisticQuestionAnswers` with visible evidence, score, pass/fail answer, and specific rationale.
- Updated `production-ux-criteria-scorecard.json/.md` showing the criterion passes.

### Acceptance Checks
- Holistic direct-question answers are present, screenshot-backed, non-boilerplate, and pass.
- `production_ux_judge.dart` has no blocking failure for this criterion.
- `b25_iteration_scorecard.dart` records the ticket as resolved or no longer blocking.
- Screenshots are refreshed and hashes/timestamps/app commit SHA match the reviewed app version.

### Non-Goals
- Do not pass based on implementation intent or code structure.
- Do not treat a captured screenshot as proof of product quality without direct-question answers.
- Do not fix only labels while leaving generic scaffold structure unchanged.

### Commit Boundary

Commit this remediation iteration, refreshed evidence, scorecards, tickets, and tracker updates before starting the next UX feedback loop.

### Rerun Commands
- `dart run packages/tooling/loom_ux_judges/bin/b25_evidence_collector.dart --evidence-root ../docs/Build\ Plan\ V2/Evidence --repo-root .. --run-id <next-run-id> --prior-review ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --output ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.md --matrix-output ../docs/Build\ Plan\ V2/Evidence/B25/product-ux-screen-review-matrix.md`
- `dart run packages/tooling/loom_ux_judges/bin/b25_workflow_persona_coverage_collector.dart --input ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --output ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/workflow-persona-coverage-matrix.md`
- `dart run packages/tooling/loom_ux_judges/bin/b25_independent_ux_judge.dart --input ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --output ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.md --matrix-output ../docs/Build\ Plan\ V2/Evidence/B25/product-ux-screen-review-matrix.md`
- `dart run packages/tooling/loom_ux_judges/bin/production_ux_judge.dart --input ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --base .. --output ../docs/Build\ Plan\ V2/Evidence/B25/production-ux-criteria-scorecard.json --markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/production-ux-criteria-scorecard.md --tickets-output ../docs/Build\ Plan\ V2/Evidence/B25/b25-remediation-tickets-<next-run-id>.json --tickets-markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/b25-remediation-tickets-<next-run-id>.md`
- `dart run packages/tooling/loom_ux_judges/bin/b25_iteration_scorecard.dart --review ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --judge ../docs/Build\ Plan\ V2/Evidence/B25/production-ux-criteria-scorecard.json --previous ../docs/Build\ Plan\ V2/Evidence/B25/b25-iteration-scorecard-latest.json --output ../docs/Build\ Plan\ V2/Evidence/B25/b25-iteration-scorecard-latest.json --markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/b25-iteration-scorecard-latest.md`

## B25-RT-003-b25-c04-modern-intentional-ui

| Field | Value |
| --- | --- |
| Severity | major |
| Priority | P1 |
| Status | open |
| Review run | `b25-v4-pass-3` |
| Source criterion | `b25-c04-modern-intentional-ui` |
| Source findings | B25-WORKFLOW-PERSONA-COVERAGE-INCOMPLETE, B25-HOLISTIC-UX-FAILED |
| Title | UI looks modern and intentionally designed |
| Direct question | Is the UI modern, easy to use, easy to navigate, and visually appealing for the target persona? |
| Why it failed | holistic direct-question answers are missing, weak, partial, or blocking: b25-holistic-production-grade, b25-holistic-modern-intentional, b25-holistic-community-ia, b25-holistic-layout-defects. |
| Required outcome | Remediate visual hierarchy, spacing, typography, component quality, and recapture screenshots. |
| Remediation mode | `evidence-repair-before-ui-remediation` |
| Worker readiness | not ready for UI implementation until evidence repair work items are completed and the independent judge reruns |
| First required step | Complete the evidenceRepairWorkItems: concrete persona/personaId, screenshot-derived visible text, screen-specific critique, coverage row proof, and workflow/persona scorecards. |

### Problem Statement

The evidence does not prove that the UI is modern, visually intentional, easy to navigate, and appealing for the target personas.

### Root Cause Hypothesis

The pass lacks screenshot-backed judgment of hierarchy, spacing, navigation clarity, component polish, and visual identity.

### Target Experience

Screens should feel intentionally designed, polished, readable, well-spaced, navigable, and visually coherent on the reviewed device.

### UX Principles
- Clear visual hierarchy
- Predictable navigation
- Consistent spacing and component quality
- Modern mobile readability and touch targets

### Concrete Improvements
- Improve visual hierarchy, typography scale, spacing rhythm, component polish, and content grouping on primary screens.
- Ensure navigation and primary actions are obvious without reading implementation or workflow taxonomy.
- Recapture screenshots and cite visible evidence proving the UI is modern, easy to use, easy to navigate, and visually appealing.

### Implementation Guidance
- Inspect `apps/loom_communities_demo/lib` for the primary community home, shell, card, detail, and workflow surface widgets.
- Compare every change against `docs/Build Plan V2/Evidence/B25/production-ux-blueprint.md` before coding.
- Update widget tests and B25 evidence expectations when user-facing hierarchy, copy, or surface structure changes.

### Content Guidance
- Replace placeholder, framework, workflow, evidence, or metadata language with user-facing product copy.
- Use content that helps the target persona understand status, options, consequences, and next steps.

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
| Material detail surface composition | Material Design 3 / design-system | https://m3.material.io/components/cards/overview | Build a domain detail page with primary content, metadata, status, and actions instead of a generic task card. |

### Reference Research Queries
- modern mobile app information architecture visual hierarchy examples
- Material Design 3 mobile UI hierarchy navigation cards examples
- open source Flutter production app dashboard detail screen examples
- open source Flutter domain-native-surface mobile UI example GitHub
- persona capability matrix surface with roles, allowed actions, receiver states, and denied/hidden behavior mobile UX pattern
- Material Design persona capability matrix surface with roles, allowed actions, receiver states, and denied/hidden behavior mobile pattern

### Implementation Blocked By
- Affected rows still use generic or missing persona data.
- Visible text is not proven from screenshot OCR/manual extraction.
- Screen-specific critiques are incomplete or reusable.
- Primary surface classification is incomplete or unverified.

### Evidence Repair Work Items

Showing 2 of 2 work items. Full detail is in the JSON artifact.

| Work item | Stage | Community | Workflow | Persona | Screens | Coverage | Target surface | Blocked until |
| --- | --- | --- | --- | --- | ---: | ---: | --- | --- |
| `b25-wi-evidence-repair-persona-role-inventory-wf-persona-role-inventory-capability-matrix-persona-role-inventory-admin` | `evidence-repair` | persona-role-inventory | `wf_persona-role-inventory-capability-matrix` | admin | 1 | 1 | persona capability matrix surface with roles, allowed actions, receiver states, and denied/hidden behavior |  |
| `b25-wi-evidence-repair-persona-role-inventory-wf-persona-role-inventory-capability-matrix-persona-role-inventory-member` | `evidence-repair` | persona-role-inventory | `wf_persona-role-inventory-capability-matrix` | member | 1 | 1 | persona capability matrix surface with roles, allowed actions, receiver states, and denied/hidden behavior |  |

### Evidence Repair Work Items Reference Patterns

| Reference | Source | URL | What to copy |
| --- | --- | --- | --- |
| Material detail surface composition | Material Design 3 / design-system | https://m3.material.io/components/cards/overview | Build a domain detail page with primary content, metadata, status, and actions instead of a generic task card. |
| Material Design cards and lists | Material Design 3 / design-system | https://m3.material.io/components/cards/overview<br>Also: https://m3.material.io/components/lists/overview | Use cards/lists only as scannable containers with clear hierarchy, content, metadata, and actions. Do not use repeated cards as the whole primary workflow. |
| Flutter sample app implementation patterns | flutter/samples / open-source | https://github.com/flutter/samples | Copy the separation between app shell, route state, domain widgets, and testable UI states rather than hardcoding a single generic renderer. |
| Material navigation and information architecture | Material Design 3 / design-system | https://m3.material.io/components/navigation-drawer/overview<br>Also: https://m3.material.io/components/navigation-bar/overview | Organize screens by user jobs and destinations; keep primary actions visible and avoid exposing implementation taxonomy. |
| Apple HIG navigation and content organization | Apple Human Interface Guidelines / design-system | https://developer.apple.com/design/human-interface-guidelines/navigation | Make navigation predictable, content-centered, and appropriate for the user’s current task. |

### UI Remediation Work Items

Showing 2 of 2 work items. Full detail is in the JSON artifact.

| Work item | Stage | Community | Workflow | Persona | Screens | Coverage | Target surface | Blocked until |
| --- | --- | --- | --- | --- | ---: | ---: | --- | --- |
| `b25-wi-ui-remediation-persona-role-inventory-wf-persona-role-inventory-capability-matrix-persona-role-inventory-admin` | `ui-remediation` | persona-role-inventory | `wf_persona-role-inventory-capability-matrix` | admin | 1 | 1 | persona capability matrix surface with roles, allowed actions, receiver states, and denied/hidden behavior | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-persona-role-inventory-wf-persona-role-inventory-capability-matrix-persona-role-inventory-member` | `ui-remediation` | persona-role-inventory | `wf_persona-role-inventory-capability-matrix` | member | 1 | 1 | persona capability matrix surface with roles, allowed actions, receiver states, and denied/hidden behavior | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |

### UI Remediation Work Items Reference Patterns

| Reference | Source | URL | What to copy |
| --- | --- | --- | --- |
| Material detail surface composition | Material Design 3 / design-system | https://m3.material.io/components/cards/overview | Build a domain detail page with primary content, metadata, status, and actions instead of a generic task card. |
| Material Design cards and lists | Material Design 3 / design-system | https://m3.material.io/components/cards/overview<br>Also: https://m3.material.io/components/lists/overview | Use cards/lists only as scannable containers with clear hierarchy, content, metadata, and actions. Do not use repeated cards as the whole primary workflow. |
| Flutter sample app implementation patterns | flutter/samples / open-source | https://github.com/flutter/samples | Copy the separation between app shell, route state, domain widgets, and testable UI states rather than hardcoding a single generic renderer. |
| Material navigation and information architecture | Material Design 3 / design-system | https://m3.material.io/components/navigation-drawer/overview<br>Also: https://m3.material.io/components/navigation-bar/overview | Organize screens by user jobs and destinations; keep primary actions visible and avoid exposing implementation taxonomy. |
| Apple HIG navigation and content organization | Apple Human Interface Guidelines / design-system | https://developer.apple.com/design/human-interface-guidelines/navigation | Make navigation predictable, content-centered, and appropriate for the user’s current task. |

### Affected Workflow/Persona Coverage

Showing 2 of 2 affected coverage rows. Full detail is in the JSON ticket.

| Coverage row | Status | Community | Workflow | Persona | Missing evidence | Screen rows | Target surface |
| --- | --- | --- | --- | --- | --- | ---: | --- |
| `b25-wp-062-wf-persona-role-inventory-capability-matrix-persona-role-inventory-admin` | `fail` | persona-role-inventory | `wf_persona-role-inventory-capability-matrix` | admin | action/review screenshot | 1 | persona capability matrix surface with roles, allowed actions, receiver states, and denied/hidden behavior |
| `b25-wp-063-wf-persona-role-inventory-capability-matrix-persona-role-inventory-member` | `fail` | persona-role-inventory | `wf_persona-role-inventory-capability-matrix` | member | result/receiver screenshot | 1 | persona capability matrix surface with roles, allowed actions, receiver states, and denied/hidden behavior |

### Affected Screen Rows

Showing 2 of 2 affected screen rows. Full detail is in the JSON ticket.

| Screen row | Community | Workflow | Persona | State | Screenshot | Hash | Visible text | Current surface | Exact UX failure | Target surface |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `b25-v4-row-184-wf-persona-role-inventory-capability-matrix-0` | persona-role-inventory | `wf_persona-role-inventory-capability-matrix` | admin | B17_persona_inventory_active_admin | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/docs/Build Plan V2/Evidence/B17/screenshots/B17_persona_inventory_active_admin.png` | `8be6fe33f9324...` | all demo communities define two or more personas \| all workflow/persona matrix rows have actor, receiver, read-only, or disabled state \| receiver rows declare dependency evidence \| matrix rows: 145 | coverage-or-review-incomplete / unverified-primary-surface | Primary surface classification is incomplete or unverified. Current row verdict is `fail` with severity `major`. | persona capability matrix surface with roles, allowed actions, receiver states, and denied/hidden behavior |
| `b25-v4-row-185-wf-persona-role-inventory-capability-matrix-1` | persona-role-inventory | `wf_persona-role-inventory-capability-matrix` | member | B17_persona_inventory_picker | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/docs/Build Plan V2/Evidence/B17/screenshots/B17_persona_inventory_picker.png` | `3b02a3887b3aa...` | all demo communities define two or more personas \| all workflow/persona matrix rows have actor, receiver, read-only, or disabled state \| receiver rows declare dependency evidence \| matrix rows: 145 | coverage-or-review-incomplete / unverified-primary-surface | Primary surface classification is incomplete or unverified. Current row verdict is `fail` with severity `major`. | persona capability matrix surface with roles, allowed actions, receiver states, and denied/hidden behavior |

### Failing Direct Questions

| Question | Scope | Score | Why | Required fix |
| --- | --- | ---: | --- | --- |
| Does the whole experience feel like a real production community app for the target users, not merely an implemented workflow harness? | holistic | 35 | The review cannot claim production-grade UX while workflow/persona evidence is incomplete or failing. | Complete workflow/persona coverage and remediate failing scorecards before claiming production-grade UX. |
| Is the UI modern, easy to use, easy to navigate, and visually appealing for the target persona? | holistic | 40 | Visible UI/text evidence is suitable for judging modern UI quality. | None. |
| Is the overall information architecture organized around community content and real jobs-to-be-done instead of workflow lists or validation surfaces? | holistic | 45 | Failing workflow/persona scorecards prevent a holistic community IA pass. | Replace generic workflow-list or validation surfaces with domain-native community sections and rerun scorecards. |
| Does the visible UI avoid blocking or major overlap, clipping, crowding, default-scaffold, repeated-card, checklist-modal, and thin-content defects? | holistic | 45 | The judge cannot clear layout/content defects while row-level evidence remains incomplete or unsupported. | Complete screenshot-backed review rows and remediate any row-level layout/content defects. |

### Likely Files / Widgets
- `app/apps/loom_communities_demo/lib/main.dart`
- `app/apps/loom_communities_demo/test/b21_b25_production_ux_test.dart`
- `docs/Build Plan V2/Evidence/B25/production-ux-blueprint.md`
- `docs/Build Plan V2/Evidence/B25/independent-production-ux-review.json`
- `docs/Build Plan V2/Evidence/B25/product-ux-screen-review-matrix.md`
- `app/apps/loom_communities_demo/integration_test/workflow_ui_evidence_test.dart`
- `app/apps/loom_communities_demo/test/workflow_ui_test_harness.dart`

### Concrete Acceptance Criteria
- Holistic direct-question answers are present, screenshot-backed, non-boilerplate, and pass.
- `production_ux_judge.dart` has no blocking failure for this criterion.
- `b25_iteration_scorecard.dart` records the ticket as resolved or no longer blocking.
- Screenshots are refreshed and hashes/timestamps/app commit SHA match the reviewed app version.
- Screen row `b25-v4-row-184-wf-persona-role-inventory-capability-matrix-0` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-184-wf-persona-role-inventory-capability-matrix-0` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-184-wf-persona-role-inventory-capability-matrix-0` names visible UI elements, visible text, persona `admin`, workflow `wf_persona-role-inventory-capability-matrix`, and the exact product UX issue.
- Primary surface for `wf_persona-role-inventory-capability-matrix` is documented as `persona capability matrix surface with roles, allowed actions, receiver states, and denied/hidden behavior` or another explicit domain-native surface.
- Fresh screenshot path/hash/timestamp/app commit SHA are recorded after the fix.
- Screen row `b25-v4-row-185-wf-persona-role-inventory-capability-matrix-1` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-185-wf-persona-role-inventory-capability-matrix-1` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-185-wf-persona-role-inventory-capability-matrix-1` names visible UI elements, visible text, persona `member`, workflow `wf_persona-role-inventory-capability-matrix`, and the exact product UX issue.
- Coverage row has a specific persona and personaId.
- Coverage row has entry, action/review, and result/receiver screenshots.
- Every listed screenshot path exists and has a fresh hash/timestamp/app commit SHA.
- The workflow/persona scorecard passes after rerun.

### Affected Evidence
- `independent-production-ux-review.json holisticQuestionAnswers`
- `independent-production-ux-review.md holistic review summary`
- `product-ux-screen-review-matrix.md relevant screen rows`
- `production-ux-criteria-scorecard.json/.md`

### Evidence To Collect
- Fresh holistic screenshots for primary homes, navigation, representative detail surfaces, and representative completion/result states.
- `holisticQuestionAnswers` with visible evidence, score, pass/fail answer, and specific rationale.
- Updated `production-ux-criteria-scorecard.json/.md` showing the criterion passes.

### Acceptance Checks
- Holistic direct-question answers are present, screenshot-backed, non-boilerplate, and pass.
- `production_ux_judge.dart` has no blocking failure for this criterion.
- `b25_iteration_scorecard.dart` records the ticket as resolved or no longer blocking.
- Screenshots are refreshed and hashes/timestamps/app commit SHA match the reviewed app version.

### Non-Goals
- Do not pass based on implementation intent or code structure.
- Do not treat a captured screenshot as proof of product quality without direct-question answers.
- Do not fix only labels while leaving generic scaffold structure unchanged.

### Commit Boundary

Commit this remediation iteration, refreshed evidence, scorecards, tickets, and tracker updates before starting the next UX feedback loop.

### Rerun Commands
- `dart run packages/tooling/loom_ux_judges/bin/b25_evidence_collector.dart --evidence-root ../docs/Build\ Plan\ V2/Evidence --repo-root .. --run-id <next-run-id> --prior-review ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --output ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.md --matrix-output ../docs/Build\ Plan\ V2/Evidence/B25/product-ux-screen-review-matrix.md`
- `dart run packages/tooling/loom_ux_judges/bin/b25_workflow_persona_coverage_collector.dart --input ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --output ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/workflow-persona-coverage-matrix.md`
- `dart run packages/tooling/loom_ux_judges/bin/b25_independent_ux_judge.dart --input ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --output ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.md --matrix-output ../docs/Build\ Plan\ V2/Evidence/B25/product-ux-screen-review-matrix.md`
- `dart run packages/tooling/loom_ux_judges/bin/production_ux_judge.dart --input ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --base .. --output ../docs/Build\ Plan\ V2/Evidence/B25/production-ux-criteria-scorecard.json --markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/production-ux-criteria-scorecard.md --tickets-output ../docs/Build\ Plan\ V2/Evidence/B25/b25-remediation-tickets-<next-run-id>.json --tickets-markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/b25-remediation-tickets-<next-run-id>.md`
- `dart run packages/tooling/loom_ux_judges/bin/b25_iteration_scorecard.dart --review ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --judge ../docs/Build\ Plan\ V2/Evidence/B25/production-ux-criteria-scorecard.json --previous ../docs/Build\ Plan\ V2/Evidence/B25/b25-iteration-scorecard-latest.json --output ../docs/Build\ Plan\ V2/Evidence/B25/b25-iteration-scorecard-latest.json --markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/b25-iteration-scorecard-latest.md`

## B25-RT-004-b25-c05-community-content-ia

| Field | Value |
| --- | --- |
| Severity | major |
| Priority | P1 |
| Status | open |
| Review run | `b25-v4-pass-3` |
| Source criterion | `b25-c05-community-content-ia` |
| Source findings | B25-WORKFLOW-PERSONA-COVERAGE-INCOMPLETE, B25-HOLISTIC-UX-FAILED |
| Title | Screens are organized around community content and jobs-to-be-done |
| Direct question | Is the overall information architecture organized around community content and real jobs-to-be-done instead of workflow lists or validation surfaces? |
| Why it failed | holistic direct-question answers are missing, weak, partial, or blocking: b25-holistic-production-grade, b25-holistic-modern-intentional, b25-holistic-community-ia, b25-holistic-layout-defects. |
| Required outcome | Rebuild home and primary screens around community content and user jobs. |
| Remediation mode | `evidence-repair-before-ui-remediation` |
| Worker readiness | not ready for UI implementation until evidence repair work items are completed and the independent judge reruns |
| First required step | Complete the evidenceRepairWorkItems: concrete persona/personaId, screenshot-derived visible text, screen-specific critique, coverage row proof, and workflow/persona scorecards. |

### Problem Statement

The evidence does not prove that primary screens are organized around community content and jobs-to-be-done instead of workflow lists or validation surfaces.

### Root Cause Hypothesis

The app may still be organized around implementation/workflow concepts instead of the mental model and daily jobs of community users.

### Target Experience

The home and primary flows should lead with community-specific sections, content, and jobs-to-be-done rather than implementation categories.

### UX Principles
- Community content first
- Jobs-to-be-done information architecture
- No global workflow-list primary UX

### Concrete Improvements
- Rework primary home/detail screens around community jobs-to-be-done and domain content.
- Replace any global workflow-list organization with sections such as announcements, events, dues, messages, documents, care requests, teams, or equivalent community-specific content.
- Update holistic answers and screen critiques to prove users see community tasks and content first.

### Implementation Guidance
- Inspect `apps/loom_communities_demo/lib` for the primary community home, shell, card, detail, and workflow surface widgets.
- Compare every change against `docs/Build Plan V2/Evidence/B25/production-ux-blueprint.md` before coding.
- Update widget tests and B25 evidence expectations when user-facing hierarchy, copy, or surface structure changes.

### Content Guidance
- Lead screens with community-specific content: announcements, events, requests, payments, documents, messages, teams, facilities, or equivalent domain sections.
- Remove or demote labels that describe workflow categories, evidence, local routes, or implementation mechanics.
- Use realistic names, dates, amounts, authors, locations, status, receipts, and next steps where the workflow requires them.

### Visual Guidance
- Group content into scannable community sections with clear visual hierarchy.
- Make the primary path visible without requiring users to scan a global workflow list.

### Source Research Requirement

The independent UX review must attach internet or open-source pattern references before UI remediation. If live research is unavailable, use the bundled catalog entries and keep the research queries in the ticket so a reviewer can refresh them.

### UX Reference Patterns To Copy

| Reference | Source | URL | What to copy |
| --- | --- | --- | --- |
| Material navigation and information architecture | Material Design 3 / design-system | https://m3.material.io/components/navigation-drawer/overview<br>Also: https://m3.material.io/components/navigation-bar/overview | Organize screens by user jobs and destinations; keep primary actions visible and avoid exposing implementation taxonomy. |
| Apple HIG navigation and content organization | Apple Human Interface Guidelines / design-system | https://developer.apple.com/design/human-interface-guidelines/navigation | Make navigation predictable, content-centered, and appropriate for the user’s current task. |
| Material Design cards and lists | Material Design 3 / design-system | https://m3.material.io/components/cards/overview<br>Also: https://m3.material.io/components/lists/overview | Use cards/lists only as scannable containers with clear hierarchy, content, metadata, and actions. Do not use repeated cards as the whole primary workflow. |
| Flutter sample app implementation patterns | flutter/samples / open-source | https://github.com/flutter/samples | Copy the separation between app shell, route state, domain widgets, and testable UI states rather than hardcoding a single generic renderer. |
| Material detail surface composition | Material Design 3 / design-system | https://m3.material.io/components/cards/overview | Build a domain detail page with primary content, metadata, status, and actions instead of a generic task card. |

### Reference Research Queries
- community app home screen announcements events messages design examples
- open source Flutter community app home feed events messages UI
- open source Flutter domain-native-surface mobile UI example GitHub
- persona capability matrix surface with roles, allowed actions, receiver states, and denied/hidden behavior mobile UX pattern
- Material Design persona capability matrix surface with roles, allowed actions, receiver states, and denied/hidden behavior mobile pattern

### Implementation Blocked By
- Affected rows still use generic or missing persona data.
- Visible text is not proven from screenshot OCR/manual extraction.
- Screen-specific critiques are incomplete or reusable.
- Primary surface classification is incomplete or unverified.

### Evidence Repair Work Items

Showing 2 of 2 work items. Full detail is in the JSON artifact.

| Work item | Stage | Community | Workflow | Persona | Screens | Coverage | Target surface | Blocked until |
| --- | --- | --- | --- | --- | ---: | ---: | --- | --- |
| `b25-wi-evidence-repair-persona-role-inventory-wf-persona-role-inventory-capability-matrix-persona-role-inventory-admin` | `evidence-repair` | persona-role-inventory | `wf_persona-role-inventory-capability-matrix` | admin | 1 | 1 | persona capability matrix surface with roles, allowed actions, receiver states, and denied/hidden behavior |  |
| `b25-wi-evidence-repair-persona-role-inventory-wf-persona-role-inventory-capability-matrix-persona-role-inventory-member` | `evidence-repair` | persona-role-inventory | `wf_persona-role-inventory-capability-matrix` | member | 1 | 1 | persona capability matrix surface with roles, allowed actions, receiver states, and denied/hidden behavior |  |

### Evidence Repair Work Items Reference Patterns

| Reference | Source | URL | What to copy |
| --- | --- | --- | --- |
| Material detail surface composition | Material Design 3 / design-system | https://m3.material.io/components/cards/overview | Build a domain detail page with primary content, metadata, status, and actions instead of a generic task card. |
| Material Design cards and lists | Material Design 3 / design-system | https://m3.material.io/components/cards/overview<br>Also: https://m3.material.io/components/lists/overview | Use cards/lists only as scannable containers with clear hierarchy, content, metadata, and actions. Do not use repeated cards as the whole primary workflow. |
| Flutter sample app implementation patterns | flutter/samples / open-source | https://github.com/flutter/samples | Copy the separation between app shell, route state, domain widgets, and testable UI states rather than hardcoding a single generic renderer. |
| Material navigation and information architecture | Material Design 3 / design-system | https://m3.material.io/components/navigation-drawer/overview<br>Also: https://m3.material.io/components/navigation-bar/overview | Organize screens by user jobs and destinations; keep primary actions visible and avoid exposing implementation taxonomy. |
| Apple HIG navigation and content organization | Apple Human Interface Guidelines / design-system | https://developer.apple.com/design/human-interface-guidelines/navigation | Make navigation predictable, content-centered, and appropriate for the user’s current task. |

### UI Remediation Work Items

Showing 2 of 2 work items. Full detail is in the JSON artifact.

| Work item | Stage | Community | Workflow | Persona | Screens | Coverage | Target surface | Blocked until |
| --- | --- | --- | --- | --- | ---: | ---: | --- | --- |
| `b25-wi-ui-remediation-persona-role-inventory-wf-persona-role-inventory-capability-matrix-persona-role-inventory-admin` | `ui-remediation` | persona-role-inventory | `wf_persona-role-inventory-capability-matrix` | admin | 1 | 1 | persona capability matrix surface with roles, allowed actions, receiver states, and denied/hidden behavior | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-persona-role-inventory-wf-persona-role-inventory-capability-matrix-persona-role-inventory-member` | `ui-remediation` | persona-role-inventory | `wf_persona-role-inventory-capability-matrix` | member | 1 | 1 | persona capability matrix surface with roles, allowed actions, receiver states, and denied/hidden behavior | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |

### UI Remediation Work Items Reference Patterns

| Reference | Source | URL | What to copy |
| --- | --- | --- | --- |
| Material detail surface composition | Material Design 3 / design-system | https://m3.material.io/components/cards/overview | Build a domain detail page with primary content, metadata, status, and actions instead of a generic task card. |
| Material Design cards and lists | Material Design 3 / design-system | https://m3.material.io/components/cards/overview<br>Also: https://m3.material.io/components/lists/overview | Use cards/lists only as scannable containers with clear hierarchy, content, metadata, and actions. Do not use repeated cards as the whole primary workflow. |
| Flutter sample app implementation patterns | flutter/samples / open-source | https://github.com/flutter/samples | Copy the separation between app shell, route state, domain widgets, and testable UI states rather than hardcoding a single generic renderer. |
| Material navigation and information architecture | Material Design 3 / design-system | https://m3.material.io/components/navigation-drawer/overview<br>Also: https://m3.material.io/components/navigation-bar/overview | Organize screens by user jobs and destinations; keep primary actions visible and avoid exposing implementation taxonomy. |
| Apple HIG navigation and content organization | Apple Human Interface Guidelines / design-system | https://developer.apple.com/design/human-interface-guidelines/navigation | Make navigation predictable, content-centered, and appropriate for the user’s current task. |

### Affected Workflow/Persona Coverage

Showing 2 of 2 affected coverage rows. Full detail is in the JSON ticket.

| Coverage row | Status | Community | Workflow | Persona | Missing evidence | Screen rows | Target surface |
| --- | --- | --- | --- | --- | --- | ---: | --- |
| `b25-wp-062-wf-persona-role-inventory-capability-matrix-persona-role-inventory-admin` | `fail` | persona-role-inventory | `wf_persona-role-inventory-capability-matrix` | admin | action/review screenshot | 1 | persona capability matrix surface with roles, allowed actions, receiver states, and denied/hidden behavior |
| `b25-wp-063-wf-persona-role-inventory-capability-matrix-persona-role-inventory-member` | `fail` | persona-role-inventory | `wf_persona-role-inventory-capability-matrix` | member | result/receiver screenshot | 1 | persona capability matrix surface with roles, allowed actions, receiver states, and denied/hidden behavior |

### Affected Screen Rows

Showing 2 of 2 affected screen rows. Full detail is in the JSON ticket.

| Screen row | Community | Workflow | Persona | State | Screenshot | Hash | Visible text | Current surface | Exact UX failure | Target surface |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `b25-v4-row-184-wf-persona-role-inventory-capability-matrix-0` | persona-role-inventory | `wf_persona-role-inventory-capability-matrix` | admin | B17_persona_inventory_active_admin | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/docs/Build Plan V2/Evidence/B17/screenshots/B17_persona_inventory_active_admin.png` | `8be6fe33f9324...` | all demo communities define two or more personas \| all workflow/persona matrix rows have actor, receiver, read-only, or disabled state \| receiver rows declare dependency evidence \| matrix rows: 145 | coverage-or-review-incomplete / unverified-primary-surface | Primary surface classification is incomplete or unverified. Current row verdict is `fail` with severity `major`. | persona capability matrix surface with roles, allowed actions, receiver states, and denied/hidden behavior |
| `b25-v4-row-185-wf-persona-role-inventory-capability-matrix-1` | persona-role-inventory | `wf_persona-role-inventory-capability-matrix` | member | B17_persona_inventory_picker | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/docs/Build Plan V2/Evidence/B17/screenshots/B17_persona_inventory_picker.png` | `3b02a3887b3aa...` | all demo communities define two or more personas \| all workflow/persona matrix rows have actor, receiver, read-only, or disabled state \| receiver rows declare dependency evidence \| matrix rows: 145 | coverage-or-review-incomplete / unverified-primary-surface | Primary surface classification is incomplete or unverified. Current row verdict is `fail` with severity `major`. | persona capability matrix surface with roles, allowed actions, receiver states, and denied/hidden behavior |

### Failing Direct Questions

| Question | Scope | Score | Why | Required fix |
| --- | --- | ---: | --- | --- |
| Does the whole experience feel like a real production community app for the target users, not merely an implemented workflow harness? | holistic | 35 | The review cannot claim production-grade UX while workflow/persona evidence is incomplete or failing. | Complete workflow/persona coverage and remediate failing scorecards before claiming production-grade UX. |
| Is the UI modern, easy to use, easy to navigate, and visually appealing for the target persona? | holistic | 40 | Visible UI/text evidence is suitable for judging modern UI quality. | None. |
| Is the overall information architecture organized around community content and real jobs-to-be-done instead of workflow lists or validation surfaces? | holistic | 45 | Failing workflow/persona scorecards prevent a holistic community IA pass. | Replace generic workflow-list or validation surfaces with domain-native community sections and rerun scorecards. |
| Does the visible UI avoid blocking or major overlap, clipping, crowding, default-scaffold, repeated-card, checklist-modal, and thin-content defects? | holistic | 45 | The judge cannot clear layout/content defects while row-level evidence remains incomplete or unsupported. | Complete screenshot-backed review rows and remediate any row-level layout/content defects. |

### Likely Files / Widgets
- `app/apps/loom_communities_demo/lib/main.dart`
- `app/apps/loom_communities_demo/test/b21_b25_production_ux_test.dart`
- `docs/Build Plan V2/Evidence/B25/production-ux-blueprint.md`
- `docs/Build Plan V2/Evidence/B25/independent-production-ux-review.json`
- `docs/Build Plan V2/Evidence/B25/product-ux-screen-review-matrix.md`
- `app/apps/loom_communities_demo/integration_test/workflow_ui_evidence_test.dart`
- `app/apps/loom_communities_demo/test/workflow_ui_test_harness.dart`

### Concrete Acceptance Criteria
- Holistic direct-question answers are present, screenshot-backed, non-boilerplate, and pass.
- `production_ux_judge.dart` has no blocking failure for this criterion.
- `b25_iteration_scorecard.dart` records the ticket as resolved or no longer blocking.
- Screenshots are refreshed and hashes/timestamps/app commit SHA match the reviewed app version.
- Screen row `b25-v4-row-184-wf-persona-role-inventory-capability-matrix-0` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-184-wf-persona-role-inventory-capability-matrix-0` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-184-wf-persona-role-inventory-capability-matrix-0` names visible UI elements, visible text, persona `admin`, workflow `wf_persona-role-inventory-capability-matrix`, and the exact product UX issue.
- Primary surface for `wf_persona-role-inventory-capability-matrix` is documented as `persona capability matrix surface with roles, allowed actions, receiver states, and denied/hidden behavior` or another explicit domain-native surface.
- Fresh screenshot path/hash/timestamp/app commit SHA are recorded after the fix.
- Screen row `b25-v4-row-185-wf-persona-role-inventory-capability-matrix-1` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-185-wf-persona-role-inventory-capability-matrix-1` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-185-wf-persona-role-inventory-capability-matrix-1` names visible UI elements, visible text, persona `member`, workflow `wf_persona-role-inventory-capability-matrix`, and the exact product UX issue.
- Coverage row has a specific persona and personaId.
- Coverage row has entry, action/review, and result/receiver screenshots.
- Every listed screenshot path exists and has a fresh hash/timestamp/app commit SHA.
- The workflow/persona scorecard passes after rerun.

### Affected Evidence
- `independent-production-ux-review.json holisticQuestionAnswers`
- `independent-production-ux-review.md holistic review summary`
- `product-ux-screen-review-matrix.md relevant screen rows`
- `production-ux-criteria-scorecard.json/.md`

### Evidence To Collect
- Fresh holistic screenshots for primary homes, navigation, representative detail surfaces, and representative completion/result states.
- `holisticQuestionAnswers` with visible evidence, score, pass/fail answer, and specific rationale.
- Updated `production-ux-criteria-scorecard.json/.md` showing the criterion passes.

### Acceptance Checks
- Holistic direct-question answers are present, screenshot-backed, non-boilerplate, and pass.
- `production_ux_judge.dart` has no blocking failure for this criterion.
- `b25_iteration_scorecard.dart` records the ticket as resolved or no longer blocking.
- Screenshots are refreshed and hashes/timestamps/app commit SHA match the reviewed app version.

### Non-Goals
- Do not rename a generic workflow card and call it domain-native.
- Do not keep global workflow lists as the primary home or primary workflow UI.
- Do not use metadata/settings pages as substitutes for task-specific product surfaces.

### Commit Boundary

Commit this remediation iteration, refreshed evidence, scorecards, tickets, and tracker updates before starting the next UX feedback loop.

### Rerun Commands
- `dart run packages/tooling/loom_ux_judges/bin/b25_evidence_collector.dart --evidence-root ../docs/Build\ Plan\ V2/Evidence --repo-root .. --run-id <next-run-id> --prior-review ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --output ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.md --matrix-output ../docs/Build\ Plan\ V2/Evidence/B25/product-ux-screen-review-matrix.md`
- `dart run packages/tooling/loom_ux_judges/bin/b25_workflow_persona_coverage_collector.dart --input ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --output ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/workflow-persona-coverage-matrix.md`
- `dart run packages/tooling/loom_ux_judges/bin/b25_independent_ux_judge.dart --input ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --output ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.md --matrix-output ../docs/Build\ Plan\ V2/Evidence/B25/product-ux-screen-review-matrix.md`
- `dart run packages/tooling/loom_ux_judges/bin/production_ux_judge.dart --input ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --base .. --output ../docs/Build\ Plan\ V2/Evidence/B25/production-ux-criteria-scorecard.json --markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/production-ux-criteria-scorecard.md --tickets-output ../docs/Build\ Plan\ V2/Evidence/B25/b25-remediation-tickets-<next-run-id>.json --tickets-markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/b25-remediation-tickets-<next-run-id>.md`
- `dart run packages/tooling/loom_ux_judges/bin/b25_iteration_scorecard.dart --review ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --judge ../docs/Build\ Plan\ V2/Evidence/B25/production-ux-criteria-scorecard.json --previous ../docs/Build\ Plan\ V2/Evidence/B25/b25-iteration-scorecard-latest.json --output ../docs/Build\ Plan\ V2/Evidence/B25/b25-iteration-scorecard-latest.json --markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/b25-iteration-scorecard-latest.md`

## B25-RT-005-b25-c06-domain-native-primary-surfaces

| Field | Value |
| --- | --- |
| Severity | major |
| Priority | P1 |
| Status | open |
| Review run | `b25-v4-pass-3` |
| Source criterion | `b25-c06-domain-native-primary-surfaces` |
| Source findings | B25-WORKFLOW-PERSONA-COVERAGE-INCOMPLETE, B25-WORKFLOW-PERSONA-UX-FAILED |
| Title | Primary workflows use domain-specific product surfaces |
| Direct question | For every workflow and persona, is the primary UI a domain-native product surface rather than a generic card, checklist modal, or metadata page? |
| Why it failed | Workflow/persona direct-question scorecards have missing or blocking answers: wf_persona-role-inventory-capability-matrix/admin, wf_persona-role-inventory-capability-matrix/member. |
| Required outcome | Replace primary generic surfaces with domain-native product surfaces. |
| Remediation mode | `evidence-repair-before-ui-remediation` |
| Worker readiness | not ready for UI implementation until evidence repair work items are completed and the independent judge reruns |
| First required step | Complete the evidenceRepairWorkItems: concrete persona/personaId, screenshot-derived visible text, screen-specific critique, coverage row proof, and workflow/persona scorecards. |

### Problem Statement

The evidence does not prove that each primary workflow/persona UI is a domain-native product surface rather than a generic card, checklist modal, or metadata page.

### Root Cause Hypothesis

Primary workflow surfaces may still rely on generic repeated cards or validation-state UI instead of task-specific product screens.

### Target Experience

Each primary workflow should use the product surface a real app would use for that job, such as an event detail, feed item, donation flow, care form, review queue, thread, receipt, search result, export wizard, or transfer status screen.

### UX Principles
- Primary surfaces must match the domain task
- Generic cards are acceptable only as secondary support, not primary workflow UI

### Concrete Improvements
- Review every primary workflow/persona row and classify the visible UI as domain-native, secondary-supporting, or generic.
- Replace primary generic cards, checklist modals, metadata pages, or repeated card shells with domain-specific product surfaces.
- Create workflow/persona scorecards proving each primary workflow surface is domain-native for its target persona.

### Implementation Guidance
- Inspect workflow surface builders and replace primary generic card/checklist/modal renderers with task-specific widgets.
- Use B21 production UX contracts to choose the target surface type for each workflow/persona pair.
- Update screenshot evidence manifests so each replaced surface is captured at entry, action, and result states.

### Content Guidance
- Write copy that matches the task: RSVP, donate, publish, approve, submit, review, search, export, transfer, invite, or reply.
- Each primary surface should include the domain data a user needs to decide and act.

### Visual Guidance
- Use screenshot evidence to judge visual hierarchy, density, navigation clarity, and polish on the reviewed device.

### Source Research Requirement

The independent UX review must attach internet or open-source pattern references before UI remediation. If live research is unavailable, use the bundled catalog entries and keep the research queries in the ticket so a reviewer can refresh them.

### UX Reference Patterns To Copy

| Reference | Source | URL | What to copy |
| --- | --- | --- | --- |
| Material detail surface composition | Material Design 3 / design-system | https://m3.material.io/components/cards/overview | Build a domain detail page with primary content, metadata, status, and actions instead of a generic task card. |
| Material Design cards and lists | Material Design 3 / design-system | https://m3.material.io/components/cards/overview<br>Also: https://m3.material.io/components/lists/overview | Use cards/lists only as scannable containers with clear hierarchy, content, metadata, and actions. Do not use repeated cards as the whole primary workflow. |
| Flutter sample app implementation patterns | flutter/samples / open-source | https://github.com/flutter/samples | Copy the separation between app shell, route state, domain widgets, and testable UI states rather than hardcoding a single generic renderer. |
| Material navigation and information architecture | Material Design 3 / design-system | https://m3.material.io/components/navigation-drawer/overview<br>Also: https://m3.material.io/components/navigation-bar/overview | Organize screens by user jobs and destinations; keep primary actions visible and avoid exposing implementation taxonomy. |
| Apple HIG navigation and content organization | Apple Human Interface Guidelines / design-system | https://developer.apple.com/design/human-interface-guidelines/navigation | Make navigation predictable, content-centered, and appropriate for the user’s current task. |

### Reference Research Queries
- domain specific mobile workflow UI event RSVP donation message export examples
- open source Flutter event RSVP donation messaging workflow UI examples
- open source Flutter domain-native-surface mobile UI example GitHub
- persona capability matrix surface with roles, allowed actions, receiver states, and denied/hidden behavior mobile UX pattern
- Material Design persona capability matrix surface with roles, allowed actions, receiver states, and denied/hidden behavior mobile pattern

### Implementation Blocked By
- Affected rows still use generic or missing persona data.
- Visible text is not proven from screenshot OCR/manual extraction.
- Screen-specific critiques are incomplete or reusable.
- Primary surface classification is incomplete or unverified.

### Evidence Repair Work Items

Showing 2 of 2 work items. Full detail is in the JSON artifact.

| Work item | Stage | Community | Workflow | Persona | Screens | Coverage | Target surface | Blocked until |
| --- | --- | --- | --- | --- | ---: | ---: | --- | --- |
| `b25-wi-evidence-repair-persona-role-inventory-wf-persona-role-inventory-capability-matrix-persona-role-inventory-admin` | `evidence-repair` | persona-role-inventory | `wf_persona-role-inventory-capability-matrix` | admin | 1 | 1 | persona capability matrix surface with roles, allowed actions, receiver states, and denied/hidden behavior |  |
| `b25-wi-evidence-repair-persona-role-inventory-wf-persona-role-inventory-capability-matrix-persona-role-inventory-member` | `evidence-repair` | persona-role-inventory | `wf_persona-role-inventory-capability-matrix` | member | 1 | 1 | persona capability matrix surface with roles, allowed actions, receiver states, and denied/hidden behavior |  |

### Evidence Repair Work Items Reference Patterns

| Reference | Source | URL | What to copy |
| --- | --- | --- | --- |
| Material detail surface composition | Material Design 3 / design-system | https://m3.material.io/components/cards/overview | Build a domain detail page with primary content, metadata, status, and actions instead of a generic task card. |
| Material Design cards and lists | Material Design 3 / design-system | https://m3.material.io/components/cards/overview<br>Also: https://m3.material.io/components/lists/overview | Use cards/lists only as scannable containers with clear hierarchy, content, metadata, and actions. Do not use repeated cards as the whole primary workflow. |
| Flutter sample app implementation patterns | flutter/samples / open-source | https://github.com/flutter/samples | Copy the separation between app shell, route state, domain widgets, and testable UI states rather than hardcoding a single generic renderer. |
| Material navigation and information architecture | Material Design 3 / design-system | https://m3.material.io/components/navigation-drawer/overview<br>Also: https://m3.material.io/components/navigation-bar/overview | Organize screens by user jobs and destinations; keep primary actions visible and avoid exposing implementation taxonomy. |
| Apple HIG navigation and content organization | Apple Human Interface Guidelines / design-system | https://developer.apple.com/design/human-interface-guidelines/navigation | Make navigation predictable, content-centered, and appropriate for the user’s current task. |

### UI Remediation Work Items

Showing 2 of 2 work items. Full detail is in the JSON artifact.

| Work item | Stage | Community | Workflow | Persona | Screens | Coverage | Target surface | Blocked until |
| --- | --- | --- | --- | --- | ---: | ---: | --- | --- |
| `b25-wi-ui-remediation-persona-role-inventory-wf-persona-role-inventory-capability-matrix-persona-role-inventory-admin` | `ui-remediation` | persona-role-inventory | `wf_persona-role-inventory-capability-matrix` | admin | 1 | 1 | persona capability matrix surface with roles, allowed actions, receiver states, and denied/hidden behavior | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-persona-role-inventory-wf-persona-role-inventory-capability-matrix-persona-role-inventory-member` | `ui-remediation` | persona-role-inventory | `wf_persona-role-inventory-capability-matrix` | member | 1 | 1 | persona capability matrix surface with roles, allowed actions, receiver states, and denied/hidden behavior | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |

### UI Remediation Work Items Reference Patterns

| Reference | Source | URL | What to copy |
| --- | --- | --- | --- |
| Material detail surface composition | Material Design 3 / design-system | https://m3.material.io/components/cards/overview | Build a domain detail page with primary content, metadata, status, and actions instead of a generic task card. |
| Material Design cards and lists | Material Design 3 / design-system | https://m3.material.io/components/cards/overview<br>Also: https://m3.material.io/components/lists/overview | Use cards/lists only as scannable containers with clear hierarchy, content, metadata, and actions. Do not use repeated cards as the whole primary workflow. |
| Flutter sample app implementation patterns | flutter/samples / open-source | https://github.com/flutter/samples | Copy the separation between app shell, route state, domain widgets, and testable UI states rather than hardcoding a single generic renderer. |
| Material navigation and information architecture | Material Design 3 / design-system | https://m3.material.io/components/navigation-drawer/overview<br>Also: https://m3.material.io/components/navigation-bar/overview | Organize screens by user jobs and destinations; keep primary actions visible and avoid exposing implementation taxonomy. |
| Apple HIG navigation and content organization | Apple Human Interface Guidelines / design-system | https://developer.apple.com/design/human-interface-guidelines/navigation | Make navigation predictable, content-centered, and appropriate for the user’s current task. |

### Affected Workflow/Persona Coverage

Showing 2 of 2 affected coverage rows. Full detail is in the JSON ticket.

| Coverage row | Status | Community | Workflow | Persona | Missing evidence | Screen rows | Target surface |
| --- | --- | --- | --- | --- | --- | ---: | --- |
| `b25-wp-062-wf-persona-role-inventory-capability-matrix-persona-role-inventory-admin` | `fail` | persona-role-inventory | `wf_persona-role-inventory-capability-matrix` | admin | action/review screenshot | 1 | persona capability matrix surface with roles, allowed actions, receiver states, and denied/hidden behavior |
| `b25-wp-063-wf-persona-role-inventory-capability-matrix-persona-role-inventory-member` | `fail` | persona-role-inventory | `wf_persona-role-inventory-capability-matrix` | member | result/receiver screenshot | 1 | persona capability matrix surface with roles, allowed actions, receiver states, and denied/hidden behavior |

### Affected Screen Rows

Showing 2 of 2 affected screen rows. Full detail is in the JSON ticket.

| Screen row | Community | Workflow | Persona | State | Screenshot | Hash | Visible text | Current surface | Exact UX failure | Target surface |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `b25-v4-row-184-wf-persona-role-inventory-capability-matrix-0` | persona-role-inventory | `wf_persona-role-inventory-capability-matrix` | admin | B17_persona_inventory_active_admin | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/docs/Build Plan V2/Evidence/B17/screenshots/B17_persona_inventory_active_admin.png` | `8be6fe33f9324...` | all demo communities define two or more personas \| all workflow/persona matrix rows have actor, receiver, read-only, or disabled state \| receiver rows declare dependency evidence \| matrix rows: 145 | coverage-or-review-incomplete / unverified-primary-surface | Primary surface classification is incomplete or unverified. Current row verdict is `fail` with severity `major`. Ticket must prove the primary screen is a domain-native surface, not a generic card/checklist/metadata surface. | persona capability matrix surface with roles, allowed actions, receiver states, and denied/hidden behavior |
| `b25-v4-row-185-wf-persona-role-inventory-capability-matrix-1` | persona-role-inventory | `wf_persona-role-inventory-capability-matrix` | member | B17_persona_inventory_picker | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/docs/Build Plan V2/Evidence/B17/screenshots/B17_persona_inventory_picker.png` | `3b02a3887b3aa...` | all demo communities define two or more personas \| all workflow/persona matrix rows have actor, receiver, read-only, or disabled state \| receiver rows declare dependency evidence \| matrix rows: 145 | coverage-or-review-incomplete / unverified-primary-surface | Primary surface classification is incomplete or unverified. Current row verdict is `fail` with severity `major`. Ticket must prove the primary screen is a domain-native surface, not a generic card/checklist/metadata surface. | persona capability matrix surface with roles, allowed actions, receiver states, and denied/hidden behavior |

### Failing Workflow/Persona Scorecards

Showing 2 of 2 failing scorecards. Full detail is in the JSON ticket.

| Scorecard | Community | Workflow | Persona | Failed questions | Target surface |
| --- | --- | --- | --- | ---: | --- |
| `b25-wp-062-wf-persona-role-inventory-capability-matrix-persona-role-inventory-admin` | persona-role-inventory | `wf_persona-role-inventory-capability-matrix` | admin | 3 | persona capability matrix surface with roles, allowed actions, receiver states, and denied/hidden behavior |
| `b25-wp-063-wf-persona-role-inventory-capability-matrix-persona-role-inventory-member` | persona-role-inventory | `wf_persona-role-inventory-capability-matrix` | member | 3 | persona capability matrix surface with roles, allowed actions, receiver states, and denied/hidden behavior |

### Likely Files / Widgets
- `app/apps/loom_communities_demo/lib/main.dart`
- `app/apps/loom_communities_demo/test/b21_b25_production_ux_test.dart`
- `docs/Build Plan V2/Evidence/B25/production-ux-blueprint.md`
- `docs/Build Plan V2/Evidence/B25/independent-production-ux-review.json`
- `docs/Build Plan V2/Evidence/B25/product-ux-screen-review-matrix.md`
- `app/apps/loom_communities_demo/integration_test/workflow_ui_evidence_test.dart`
- `app/apps/loom_communities_demo/test/workflow_ui_test_harness.dart`

### Concrete Acceptance Criteria
- Every workflow/persona scorecard is present, screenshot-backed, non-boilerplate, and pass.
- `production_ux_judge.dart` has no blocking failure for this criterion.
- `b25_iteration_scorecard.dart` records the ticket as resolved or no longer blocking.
- Screenshots are refreshed and hashes/timestamps/app commit SHA match the reviewed app version.
- Screen row `b25-v4-row-184-wf-persona-role-inventory-capability-matrix-0` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-184-wf-persona-role-inventory-capability-matrix-0` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-184-wf-persona-role-inventory-capability-matrix-0` names visible UI elements, visible text, persona `admin`, workflow `wf_persona-role-inventory-capability-matrix`, and the exact product UX issue.
- Primary surface for `wf_persona-role-inventory-capability-matrix` is documented as `persona capability matrix surface with roles, allowed actions, receiver states, and denied/hidden behavior` or another explicit domain-native surface.
- Fresh screenshot path/hash/timestamp/app commit SHA are recorded after the fix.
- The workflow/persona direct-question scorecard passes the domain-native primary surface question.
- Screen row `b25-v4-row-185-wf-persona-role-inventory-capability-matrix-1` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-185-wf-persona-role-inventory-capability-matrix-1` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-185-wf-persona-role-inventory-capability-matrix-1` names visible UI elements, visible text, persona `member`, workflow `wf_persona-role-inventory-capability-matrix`, and the exact product UX issue.
- Coverage row has a specific persona and personaId.
- Coverage row has entry, action/review, and result/receiver screenshots.
- Every listed screenshot path exists and has a fresh hash/timestamp/app commit SHA.
- The workflow/persona scorecard passes after rerun.

### Affected Evidence
- `independent-production-ux-review.json workflowPersonaScorecards`
- `independent-production-ux-review.json screenRows`
- `product-ux-screen-review-matrix.md every workflow/persona row`
- `production-ux-criteria-scorecard.json/.md`

### Evidence To Collect
- Fresh screenshots for every primary workflow/persona surface that was replaced or reviewed.
- `workflowPersonaScorecards` with task-specific domain-native surface judgments.
- Screen matrix rows showing `primarySurfaceType` or classification is not generic for primary workflows.

### Acceptance Checks
- Every workflow/persona scorecard is present, screenshot-backed, non-boilerplate, and pass.
- `production_ux_judge.dart` has no blocking failure for this criterion.
- `b25_iteration_scorecard.dart` records the ticket as resolved or no longer blocking.
- Screenshots are refreshed and hashes/timestamps/app commit SHA match the reviewed app version.

### Non-Goals
- Do not rename a generic workflow card and call it domain-native.
- Do not keep global workflow lists as the primary home or primary workflow UI.
- Do not use metadata/settings pages as substitutes for task-specific product surfaces.

### Commit Boundary

Commit this remediation iteration, refreshed evidence, scorecards, tickets, and tracker updates before starting the next UX feedback loop.

### Rerun Commands
- `dart run packages/tooling/loom_ux_judges/bin/b25_evidence_collector.dart --evidence-root ../docs/Build\ Plan\ V2/Evidence --repo-root .. --run-id <next-run-id> --prior-review ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --output ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.md --matrix-output ../docs/Build\ Plan\ V2/Evidence/B25/product-ux-screen-review-matrix.md`
- `dart run packages/tooling/loom_ux_judges/bin/b25_workflow_persona_coverage_collector.dart --input ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --output ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/workflow-persona-coverage-matrix.md`
- `dart run packages/tooling/loom_ux_judges/bin/b25_independent_ux_judge.dart --input ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --output ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.md --matrix-output ../docs/Build\ Plan\ V2/Evidence/B25/product-ux-screen-review-matrix.md`
- `dart run packages/tooling/loom_ux_judges/bin/production_ux_judge.dart --input ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --base .. --output ../docs/Build\ Plan\ V2/Evidence/B25/production-ux-criteria-scorecard.json --markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/production-ux-criteria-scorecard.md --tickets-output ../docs/Build\ Plan\ V2/Evidence/B25/b25-remediation-tickets-<next-run-id>.json --tickets-markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/b25-remediation-tickets-<next-run-id>.md`
- `dart run packages/tooling/loom_ux_judges/bin/b25_iteration_scorecard.dart --review ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --judge ../docs/Build\ Plan\ V2/Evidence/B25/production-ux-criteria-scorecard.json --previous ../docs/Build\ Plan\ V2/Evidence/B25/b25-iteration-scorecard-latest.json --output ../docs/Build\ Plan\ V2/Evidence/B25/b25-iteration-scorecard-latest.json --markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/b25-iteration-scorecard-latest.md`

## B25-RT-006-b25-c08-visible-text-specific-critique

| Field | Value |
| --- | --- |
| Severity | major |
| Priority | P1 |
| Status | open |
| Review run | `b25-v4-pass-3` |
| Source criterion | `b25-c08-visible-text-specific-critique` |
| Source findings | B25-WORKFLOW-PERSONA-COVERAGE-INCOMPLETE, B25-WORKFLOW-PERSONA-UX-FAILED |
| Title | Every row has visible text and screen-specific critique |
| Direct question | Does every holistic and workflow/persona review answer cite visible UI/text and provide a critique specific to that screenshot and user task? |
| Why it failed | Workflow/persona direct-question scorecards have missing or blocking answers: wf_persona-role-inventory-capability-matrix/admin, wf_persona-role-inventory-capability-matrix/member. |
| Required outcome | Extract visible text and write a specific critique for each screenshot row. |
| Remediation mode | `evidence-repair-first` |
| Worker readiness | not ready for UI implementation until evidence repair work items are completed and the independent judge reruns |
| First required step | Complete the evidenceRepairWorkItems: concrete persona/personaId, screenshot-derived visible text, screen-specific critique, coverage row proof, and workflow/persona scorecards. |

### Problem Statement

The review rows and direct-question answers do not include enough visible text and screen-specific critique to guide implementation.

### Root Cause Hypothesis

The judge output is not detailed enough; rows may be boilerplate or missing actual visible UI/text references.

### Target Experience

Every row should tell a worker exactly what was visible, why it did or did not work for the persona/task, and what must change.

### UX Principles
- Evidence must cite visible UI and text
- Critique must be screen-specific and non-boilerplate

### Concrete Improvements
- Extract visible text for every reviewed screenshot row.
- Write a non-boilerplate critique for every row that names visible UI elements, visible text, the persona, and the user task.
- Remove duplicated or reusable critiques; each critique must be specific enough that it cannot apply unchanged to an unrelated screen.

### Implementation Guidance
- Update the B25 judge/review artifact, not only app UI code.
- Fill `screenRows[].visibleTextExtract`, `screenRows[].screenSpecificCritique`, `holisticQuestionAnswers`, and `workflowPersonaScorecards` with screenshot-specific content.
- Regenerate markdown review and matrix files from the updated schema v4 JSON.

### Content Guidance
- Quote or summarize visible labels, headings, section names, action text, and result copy in the critique.
- Explain why that visible content does or does not support the persona and task.

### Visual Guidance
- Use screenshot evidence to judge visual hierarchy, density, navigation clarity, and polish on the reviewed device.

### Source Research Requirement

The independent UX review must attach internet or open-source pattern references before UI remediation. If live research is unavailable, use the bundled catalog entries and keep the research queries in the ticket so a reviewer can refresh them.

### UX Reference Patterns To Copy

| Reference | Source | URL | What to copy |
| --- | --- | --- | --- |
| Screenshot-first critique method | B25 production UX gate / methodology | docs/Build Plan V2/Tools/b25-remediation-ticket-template.md | Critique must quote visible UI/text, name the persona and task, compare against the chosen reference pattern, and state the exact fix. |
| Material Design cards and lists | Material Design 3 / design-system | https://m3.material.io/components/cards/overview<br>Also: https://m3.material.io/components/lists/overview | Use cards/lists only as scannable containers with clear hierarchy, content, metadata, and actions. Do not use repeated cards as the whole primary workflow. |
| Flutter sample app implementation patterns | flutter/samples / open-source | https://github.com/flutter/samples | Copy the separation between app shell, route state, domain widgets, and testable UI states rather than hardcoding a single generic renderer. |
| Material detail surface composition | Material Design 3 / design-system | https://m3.material.io/components/cards/overview | Build a domain detail page with primary content, metadata, status, and actions instead of a generic task card. |
| Material navigation and information architecture | Material Design 3 / design-system | https://m3.material.io/components/navigation-drawer/overview<br>Also: https://m3.material.io/components/navigation-bar/overview | Organize screens by user jobs and destinations; keep primary actions visible and avoid exposing implementation taxonomy. |
| Apple HIG navigation and content organization | Apple Human Interface Guidelines / design-system | https://developer.apple.com/design/human-interface-guidelines/navigation | Make navigation predictable, content-centered, and appropriate for the user’s current task. |

### Reference Research Queries
- production mobile UX review screenshot critique examples
- open source Flutter mobile app UX patterns GitHub
- open source Flutter domain-native-surface mobile UI example GitHub
- persona capability matrix surface with roles, allowed actions, receiver states, and denied/hidden behavior mobile UX pattern
- Material Design persona capability matrix surface with roles, allowed actions, receiver states, and denied/hidden behavior mobile pattern

### Implementation Blocked By
- Affected rows still use generic or missing persona data.
- Visible text is not proven from screenshot OCR/manual extraction.
- Screen-specific critiques are incomplete or reusable.
- Primary surface classification is incomplete or unverified.

### Evidence Repair Work Items

Showing 2 of 2 work items. Full detail is in the JSON artifact.

| Work item | Stage | Community | Workflow | Persona | Screens | Coverage | Target surface | Blocked until |
| --- | --- | --- | --- | --- | ---: | ---: | --- | --- |
| `b25-wi-evidence-repair-persona-role-inventory-wf-persona-role-inventory-capability-matrix-persona-role-inventory-admin` | `evidence-repair` | persona-role-inventory | `wf_persona-role-inventory-capability-matrix` | admin | 1 | 1 | persona capability matrix surface with roles, allowed actions, receiver states, and denied/hidden behavior |  |
| `b25-wi-evidence-repair-persona-role-inventory-wf-persona-role-inventory-capability-matrix-persona-role-inventory-member` | `evidence-repair` | persona-role-inventory | `wf_persona-role-inventory-capability-matrix` | member | 1 | 1 | persona capability matrix surface with roles, allowed actions, receiver states, and denied/hidden behavior |  |

### Evidence Repair Work Items Reference Patterns

| Reference | Source | URL | What to copy |
| --- | --- | --- | --- |
| Material detail surface composition | Material Design 3 / design-system | https://m3.material.io/components/cards/overview | Build a domain detail page with primary content, metadata, status, and actions instead of a generic task card. |
| Material Design cards and lists | Material Design 3 / design-system | https://m3.material.io/components/cards/overview<br>Also: https://m3.material.io/components/lists/overview | Use cards/lists only as scannable containers with clear hierarchy, content, metadata, and actions. Do not use repeated cards as the whole primary workflow. |
| Flutter sample app implementation patterns | flutter/samples / open-source | https://github.com/flutter/samples | Copy the separation between app shell, route state, domain widgets, and testable UI states rather than hardcoding a single generic renderer. |
| Material navigation and information architecture | Material Design 3 / design-system | https://m3.material.io/components/navigation-drawer/overview<br>Also: https://m3.material.io/components/navigation-bar/overview | Organize screens by user jobs and destinations; keep primary actions visible and avoid exposing implementation taxonomy. |
| Apple HIG navigation and content organization | Apple Human Interface Guidelines / design-system | https://developer.apple.com/design/human-interface-guidelines/navigation | Make navigation predictable, content-centered, and appropriate for the user’s current task. |

### Affected Workflow/Persona Coverage

Showing 2 of 2 affected coverage rows. Full detail is in the JSON ticket.

| Coverage row | Status | Community | Workflow | Persona | Missing evidence | Screen rows | Target surface |
| --- | --- | --- | --- | --- | --- | ---: | --- |
| `b25-wp-062-wf-persona-role-inventory-capability-matrix-persona-role-inventory-admin` | `fail` | persona-role-inventory | `wf_persona-role-inventory-capability-matrix` | admin | action/review screenshot | 1 | persona capability matrix surface with roles, allowed actions, receiver states, and denied/hidden behavior |
| `b25-wp-063-wf-persona-role-inventory-capability-matrix-persona-role-inventory-member` | `fail` | persona-role-inventory | `wf_persona-role-inventory-capability-matrix` | member | result/receiver screenshot | 1 | persona capability matrix surface with roles, allowed actions, receiver states, and denied/hidden behavior |

### Affected Screen Rows

Showing 2 of 2 affected screen rows. Full detail is in the JSON ticket.

| Screen row | Community | Workflow | Persona | State | Screenshot | Hash | Visible text | Current surface | Exact UX failure | Target surface |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `b25-v4-row-184-wf-persona-role-inventory-capability-matrix-0` | persona-role-inventory | `wf_persona-role-inventory-capability-matrix` | admin | B17_persona_inventory_active_admin | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/docs/Build Plan V2/Evidence/B17/screenshots/B17_persona_inventory_active_admin.png` | `8be6fe33f9324...` | all demo communities define two or more personas \| all workflow/persona matrix rows have actor, receiver, read-only, or disabled state \| receiver rows declare dependency evidence \| matrix rows: 145 | coverage-or-review-incomplete / unverified-primary-surface | Primary surface classification is incomplete or unverified. Current row verdict is `fail` with severity `major`. Ticket must add screenshot-backed visible text and a non-reusable critique for this exact screen. | persona capability matrix surface with roles, allowed actions, receiver states, and denied/hidden behavior |
| `b25-v4-row-185-wf-persona-role-inventory-capability-matrix-1` | persona-role-inventory | `wf_persona-role-inventory-capability-matrix` | member | B17_persona_inventory_picker | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/docs/Build Plan V2/Evidence/B17/screenshots/B17_persona_inventory_picker.png` | `3b02a3887b3aa...` | all demo communities define two or more personas \| all workflow/persona matrix rows have actor, receiver, read-only, or disabled state \| receiver rows declare dependency evidence \| matrix rows: 145 | coverage-or-review-incomplete / unverified-primary-surface | Primary surface classification is incomplete or unverified. Current row verdict is `fail` with severity `major`. Ticket must add screenshot-backed visible text and a non-reusable critique for this exact screen. | persona capability matrix surface with roles, allowed actions, receiver states, and denied/hidden behavior |

### Failing Workflow/Persona Scorecards

Showing 2 of 2 failing scorecards. Full detail is in the JSON ticket.

| Scorecard | Community | Workflow | Persona | Failed questions | Target surface |
| --- | --- | --- | --- | ---: | --- |
| `b25-wp-062-wf-persona-role-inventory-capability-matrix-persona-role-inventory-admin` | persona-role-inventory | `wf_persona-role-inventory-capability-matrix` | admin | 3 | persona capability matrix surface with roles, allowed actions, receiver states, and denied/hidden behavior |
| `b25-wp-063-wf-persona-role-inventory-capability-matrix-persona-role-inventory-member` | persona-role-inventory | `wf_persona-role-inventory-capability-matrix` | member | 3 | persona capability matrix surface with roles, allowed actions, receiver states, and denied/hidden behavior |

### Likely Files / Widgets
- `app/apps/loom_communities_demo/lib/main.dart`
- `app/apps/loom_communities_demo/test/b21_b25_production_ux_test.dart`
- `docs/Build Plan V2/Evidence/B25/production-ux-blueprint.md`
- `docs/Build Plan V2/Evidence/B25/independent-production-ux-review.json`
- `docs/Build Plan V2/Evidence/B25/product-ux-screen-review-matrix.md`
- `app/packages/tooling/loom_ux_judges/lib/loom_ux_judges.dart`
- `docs/Build Plan V2/Evidence/B25/independent-production-ux-review.md`
- `app/apps/loom_communities_demo/integration_test/workflow_ui_evidence_test.dart`
- `app/apps/loom_communities_demo/test/workflow_ui_test_harness.dart`

### Concrete Acceptance Criteria
- Every workflow/persona scorecard is present, screenshot-backed, non-boilerplate, and pass.
- `production_ux_judge.dart` has no blocking failure for this criterion.
- `b25_iteration_scorecard.dart` records the ticket as resolved or no longer blocking.
- Screenshots are refreshed and hashes/timestamps/app commit SHA match the reviewed app version.
- Screen row `b25-v4-row-184-wf-persona-role-inventory-capability-matrix-0` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-184-wf-persona-role-inventory-capability-matrix-0` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-184-wf-persona-role-inventory-capability-matrix-0` names visible UI elements, visible text, persona `admin`, workflow `wf_persona-role-inventory-capability-matrix`, and the exact product UX issue.
- Primary surface for `wf_persona-role-inventory-capability-matrix` is documented as `persona capability matrix surface with roles, allowed actions, receiver states, and denied/hidden behavior` or another explicit domain-native surface.
- Fresh screenshot path/hash/timestamp/app commit SHA are recorded after the fix.
- The workflow/persona direct-question scorecard passes the visible-text and task-specific critique question.
- Screen row `b25-v4-row-185-wf-persona-role-inventory-capability-matrix-1` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-185-wf-persona-role-inventory-capability-matrix-1` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-185-wf-persona-role-inventory-capability-matrix-1` names visible UI elements, visible text, persona `member`, workflow `wf_persona-role-inventory-capability-matrix`, and the exact product UX issue.
- Coverage row has a specific persona and personaId.
- Coverage row has entry, action/review, and result/receiver screenshots.
- Every listed screenshot path exists and has a fresh hash/timestamp/app commit SHA.
- The workflow/persona scorecard passes after rerun.

### Affected Evidence
- `independent-production-ux-review.json workflowPersonaScorecards`
- `independent-production-ux-review.json screenRows`
- `product-ux-screen-review-matrix.md every workflow/persona row`
- `production-ux-criteria-scorecard.json/.md`

### Evidence To Collect
- Visible text extracts for every reviewed row.
- Non-boilerplate screen-specific critique for every reviewed row.
- Updated markdown matrix matching the JSON evidence.

### Acceptance Checks
- Every workflow/persona scorecard is present, screenshot-backed, non-boilerplate, and pass.
- `production_ux_judge.dart` has no blocking failure for this criterion.
- `b25_iteration_scorecard.dart` records the ticket as resolved or no longer blocking.
- Screenshots are refreshed and hashes/timestamps/app commit SHA match the reviewed app version.

### Non-Goals
- Do not reuse the same critique across unrelated screens.
- Do not write critique that could apply without seeing the screenshot.

### Commit Boundary

Commit this remediation iteration, refreshed evidence, scorecards, tickets, and tracker updates before starting the next UX feedback loop.

### Rerun Commands
- `dart run packages/tooling/loom_ux_judges/bin/b25_evidence_collector.dart --evidence-root ../docs/Build\ Plan\ V2/Evidence --repo-root .. --run-id <next-run-id> --prior-review ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --output ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.md --matrix-output ../docs/Build\ Plan\ V2/Evidence/B25/product-ux-screen-review-matrix.md`
- `dart run packages/tooling/loom_ux_judges/bin/b25_workflow_persona_coverage_collector.dart --input ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --output ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/workflow-persona-coverage-matrix.md`
- `dart run packages/tooling/loom_ux_judges/bin/b25_independent_ux_judge.dart --input ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --output ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.md --matrix-output ../docs/Build\ Plan\ V2/Evidence/B25/product-ux-screen-review-matrix.md`
- `dart run packages/tooling/loom_ux_judges/bin/production_ux_judge.dart --input ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --base .. --output ../docs/Build\ Plan\ V2/Evidence/B25/production-ux-criteria-scorecard.json --markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/production-ux-criteria-scorecard.md --tickets-output ../docs/Build\ Plan\ V2/Evidence/B25/b25-remediation-tickets-<next-run-id>.json --tickets-markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/b25-remediation-tickets-<next-run-id>.md`
- `dart run packages/tooling/loom_ux_judges/bin/b25_iteration_scorecard.dart --review ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --judge ../docs/Build\ Plan\ V2/Evidence/B25/production-ux-criteria-scorecard.json --previous ../docs/Build\ Plan\ V2/Evidence/B25/b25-iteration-scorecard-latest.json --output ../docs/Build\ Plan\ V2/Evidence/B25/b25-iteration-scorecard-latest.json --markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/b25-iteration-scorecard-latest.md`

## B25-RT-007-b25-c09-no-layout-production-defects

| Field | Value |
| --- | --- |
| Severity | major |
| Priority | P1 |
| Status | open |
| Review run | `b25-v4-pass-3` |
| Source criterion | `b25-c09-no-layout-production-defects` |
| Source findings | B25-WORKFLOW-PERSONA-COVERAGE-INCOMPLETE, B25-HOLISTIC-UX-FAILED |
| Title | No blocking or major layout/content defects remain |
| Direct question | Does the visible UI avoid blocking or major overlap, clipping, crowding, default-scaffold, repeated-card, checklist-modal, and thin-content defects? |
| Why it failed | holistic direct-question answers are missing, weak, partial, or blocking: b25-holistic-production-grade, b25-holistic-modern-intentional, b25-holistic-community-ia, b25-holistic-layout-defects. |
| Required outcome | Fix layout/content defects and rerun the review. |
| Remediation mode | `evidence-repair-before-ui-remediation` |
| Worker readiness | not ready for UI implementation until evidence repair work items are completed and the independent judge reruns |
| First required step | Complete the evidenceRepairWorkItems: concrete persona/personaId, screenshot-derived visible text, screen-specific critique, coverage row proof, and workflow/persona scorecards. |

### Problem Statement

The evidence does not prove that the visible UI is free of major overlap, clipping, crowding, repeated-card, checklist-modal, or thin-content defects.

### Root Cause Hypothesis

The pass has not performed a screenshot-grounded defect audit for mobile layout, density, component quality, and content depth.

### Target Experience

The reviewed UI should have no major overlap, clipping, crowding, default scaffold feel, repeated-card primary UX, checklist-modal primary UX, or thin placeholder content.

### UX Principles
- No major layout defects
- No thin placeholder content
- No checklist or scaffold feel on primary screens

### Concrete Improvements
- Audit screenshots for overlap, clipping, crowding, default scaffold appearance, repeated-card primary UX, checklist-modal UX, and thin placeholder content.
- Fix any blocking or major layout/content defects and document before/after screenshot references.
- Update holistic direct-question answers with screenshot-backed proof that no major layout/content defects remain.

### Implementation Guidance
- Inspect `apps/loom_communities_demo/lib` for the primary community home, shell, card, detail, and workflow surface widgets.
- Compare every change against `docs/Build Plan V2/Evidence/B25/production-ux-blueprint.md` before coding.
- Update widget tests and B25 evidence expectations when user-facing hierarchy, copy, or surface structure changes.

### Content Guidance
- Replace placeholder, framework, workflow, evidence, or metadata language with user-facing product copy.
- Use content that helps the target persona understand status, options, consequences, and next steps.

### Visual Guidance
- Audit screenshots for overlap, clipping, crowding, bottom control collisions, dense repeated cards, and modals that hide primary workflow context.
- Prefer stable responsive dimensions and scroll-safe spacing for cards, lists, dialogs, and floating actions.

### Source Research Requirement

The independent UX review must attach internet or open-source pattern references before UI remediation. If live research is unavailable, use the bundled catalog entries and keep the research queries in the ticket so a reviewer can refresh them.

### UX Reference Patterns To Copy

| Reference | Source | URL | What to copy |
| --- | --- | --- | --- |
| Material navigation and information architecture | Material Design 3 / design-system | https://m3.material.io/components/navigation-drawer/overview<br>Also: https://m3.material.io/components/navigation-bar/overview | Organize screens by user jobs and destinations; keep primary actions visible and avoid exposing implementation taxonomy. |
| Apple HIG navigation and content organization | Apple Human Interface Guidelines / design-system | https://developer.apple.com/design/human-interface-guidelines/navigation | Make navigation predictable, content-centered, and appropriate for the user’s current task. |
| Material Design cards and lists | Material Design 3 / design-system | https://m3.material.io/components/cards/overview<br>Also: https://m3.material.io/components/lists/overview | Use cards/lists only as scannable containers with clear hierarchy, content, metadata, and actions. Do not use repeated cards as the whole primary workflow. |
| Flutter sample app implementation patterns | flutter/samples / open-source | https://github.com/flutter/samples | Copy the separation between app shell, route state, domain widgets, and testable UI states rather than hardcoding a single generic renderer. |
| Material detail surface composition | Material Design 3 / design-system | https://m3.material.io/components/cards/overview | Build a domain detail page with primary content, metadata, status, and actions instead of a generic task card. |

### Reference Research Queries
- production mobile UX review screenshot critique examples
- open source Flutter mobile app UX patterns GitHub
- open source Flutter domain-native-surface mobile UI example GitHub
- persona capability matrix surface with roles, allowed actions, receiver states, and denied/hidden behavior mobile UX pattern
- Material Design persona capability matrix surface with roles, allowed actions, receiver states, and denied/hidden behavior mobile pattern

### Implementation Blocked By
- Affected rows still use generic or missing persona data.
- Visible text is not proven from screenshot OCR/manual extraction.
- Screen-specific critiques are incomplete or reusable.
- Primary surface classification is incomplete or unverified.

### Evidence Repair Work Items

Showing 2 of 2 work items. Full detail is in the JSON artifact.

| Work item | Stage | Community | Workflow | Persona | Screens | Coverage | Target surface | Blocked until |
| --- | --- | --- | --- | --- | ---: | ---: | --- | --- |
| `b25-wi-evidence-repair-persona-role-inventory-wf-persona-role-inventory-capability-matrix-persona-role-inventory-admin` | `evidence-repair` | persona-role-inventory | `wf_persona-role-inventory-capability-matrix` | admin | 1 | 1 | persona capability matrix surface with roles, allowed actions, receiver states, and denied/hidden behavior |  |
| `b25-wi-evidence-repair-persona-role-inventory-wf-persona-role-inventory-capability-matrix-persona-role-inventory-member` | `evidence-repair` | persona-role-inventory | `wf_persona-role-inventory-capability-matrix` | member | 1 | 1 | persona capability matrix surface with roles, allowed actions, receiver states, and denied/hidden behavior |  |

### Evidence Repair Work Items Reference Patterns

| Reference | Source | URL | What to copy |
| --- | --- | --- | --- |
| Material detail surface composition | Material Design 3 / design-system | https://m3.material.io/components/cards/overview | Build a domain detail page with primary content, metadata, status, and actions instead of a generic task card. |
| Material Design cards and lists | Material Design 3 / design-system | https://m3.material.io/components/cards/overview<br>Also: https://m3.material.io/components/lists/overview | Use cards/lists only as scannable containers with clear hierarchy, content, metadata, and actions. Do not use repeated cards as the whole primary workflow. |
| Flutter sample app implementation patterns | flutter/samples / open-source | https://github.com/flutter/samples | Copy the separation between app shell, route state, domain widgets, and testable UI states rather than hardcoding a single generic renderer. |
| Material navigation and information architecture | Material Design 3 / design-system | https://m3.material.io/components/navigation-drawer/overview<br>Also: https://m3.material.io/components/navigation-bar/overview | Organize screens by user jobs and destinations; keep primary actions visible and avoid exposing implementation taxonomy. |
| Apple HIG navigation and content organization | Apple Human Interface Guidelines / design-system | https://developer.apple.com/design/human-interface-guidelines/navigation | Make navigation predictable, content-centered, and appropriate for the user’s current task. |

### UI Remediation Work Items

Showing 2 of 2 work items. Full detail is in the JSON artifact.

| Work item | Stage | Community | Workflow | Persona | Screens | Coverage | Target surface | Blocked until |
| --- | --- | --- | --- | --- | ---: | ---: | --- | --- |
| `b25-wi-ui-remediation-persona-role-inventory-wf-persona-role-inventory-capability-matrix-persona-role-inventory-admin` | `ui-remediation` | persona-role-inventory | `wf_persona-role-inventory-capability-matrix` | admin | 1 | 1 | persona capability matrix surface with roles, allowed actions, receiver states, and denied/hidden behavior | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-persona-role-inventory-wf-persona-role-inventory-capability-matrix-persona-role-inventory-member` | `ui-remediation` | persona-role-inventory | `wf_persona-role-inventory-capability-matrix` | member | 1 | 1 | persona capability matrix surface with roles, allowed actions, receiver states, and denied/hidden behavior | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |

### UI Remediation Work Items Reference Patterns

| Reference | Source | URL | What to copy |
| --- | --- | --- | --- |
| Material detail surface composition | Material Design 3 / design-system | https://m3.material.io/components/cards/overview | Build a domain detail page with primary content, metadata, status, and actions instead of a generic task card. |
| Material Design cards and lists | Material Design 3 / design-system | https://m3.material.io/components/cards/overview<br>Also: https://m3.material.io/components/lists/overview | Use cards/lists only as scannable containers with clear hierarchy, content, metadata, and actions. Do not use repeated cards as the whole primary workflow. |
| Flutter sample app implementation patterns | flutter/samples / open-source | https://github.com/flutter/samples | Copy the separation between app shell, route state, domain widgets, and testable UI states rather than hardcoding a single generic renderer. |
| Material navigation and information architecture | Material Design 3 / design-system | https://m3.material.io/components/navigation-drawer/overview<br>Also: https://m3.material.io/components/navigation-bar/overview | Organize screens by user jobs and destinations; keep primary actions visible and avoid exposing implementation taxonomy. |
| Apple HIG navigation and content organization | Apple Human Interface Guidelines / design-system | https://developer.apple.com/design/human-interface-guidelines/navigation | Make navigation predictable, content-centered, and appropriate for the user’s current task. |

### Affected Workflow/Persona Coverage

Showing 2 of 2 affected coverage rows. Full detail is in the JSON ticket.

| Coverage row | Status | Community | Workflow | Persona | Missing evidence | Screen rows | Target surface |
| --- | --- | --- | --- | --- | --- | ---: | --- |
| `b25-wp-062-wf-persona-role-inventory-capability-matrix-persona-role-inventory-admin` | `fail` | persona-role-inventory | `wf_persona-role-inventory-capability-matrix` | admin | action/review screenshot | 1 | persona capability matrix surface with roles, allowed actions, receiver states, and denied/hidden behavior |
| `b25-wp-063-wf-persona-role-inventory-capability-matrix-persona-role-inventory-member` | `fail` | persona-role-inventory | `wf_persona-role-inventory-capability-matrix` | member | result/receiver screenshot | 1 | persona capability matrix surface with roles, allowed actions, receiver states, and denied/hidden behavior |

### Affected Screen Rows

Showing 2 of 2 affected screen rows. Full detail is in the JSON ticket.

| Screen row | Community | Workflow | Persona | State | Screenshot | Hash | Visible text | Current surface | Exact UX failure | Target surface |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `b25-v4-row-184-wf-persona-role-inventory-capability-matrix-0` | persona-role-inventory | `wf_persona-role-inventory-capability-matrix` | admin | B17_persona_inventory_active_admin | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/docs/Build Plan V2/Evidence/B17/screenshots/B17_persona_inventory_active_admin.png` | `8be6fe33f9324...` | all demo communities define two or more personas \| all workflow/persona matrix rows have actor, receiver, read-only, or disabled state \| receiver rows declare dependency evidence \| matrix rows: 145 | coverage-or-review-incomplete / unverified-primary-surface | Primary surface classification is incomplete or unverified. Current row verdict is `fail` with severity `major`. | persona capability matrix surface with roles, allowed actions, receiver states, and denied/hidden behavior |
| `b25-v4-row-185-wf-persona-role-inventory-capability-matrix-1` | persona-role-inventory | `wf_persona-role-inventory-capability-matrix` | member | B17_persona_inventory_picker | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/docs/Build Plan V2/Evidence/B17/screenshots/B17_persona_inventory_picker.png` | `3b02a3887b3aa...` | all demo communities define two or more personas \| all workflow/persona matrix rows have actor, receiver, read-only, or disabled state \| receiver rows declare dependency evidence \| matrix rows: 145 | coverage-or-review-incomplete / unverified-primary-surface | Primary surface classification is incomplete or unverified. Current row verdict is `fail` with severity `major`. | persona capability matrix surface with roles, allowed actions, receiver states, and denied/hidden behavior |

### Failing Direct Questions

| Question | Scope | Score | Why | Required fix |
| --- | --- | ---: | --- | --- |
| Does the whole experience feel like a real production community app for the target users, not merely an implemented workflow harness? | holistic | 35 | The review cannot claim production-grade UX while workflow/persona evidence is incomplete or failing. | Complete workflow/persona coverage and remediate failing scorecards before claiming production-grade UX. |
| Is the UI modern, easy to use, easy to navigate, and visually appealing for the target persona? | holistic | 40 | Visible UI/text evidence is suitable for judging modern UI quality. | None. |
| Is the overall information architecture organized around community content and real jobs-to-be-done instead of workflow lists or validation surfaces? | holistic | 45 | Failing workflow/persona scorecards prevent a holistic community IA pass. | Replace generic workflow-list or validation surfaces with domain-native community sections and rerun scorecards. |
| Does the visible UI avoid blocking or major overlap, clipping, crowding, default-scaffold, repeated-card, checklist-modal, and thin-content defects? | holistic | 45 | The judge cannot clear layout/content defects while row-level evidence remains incomplete or unsupported. | Complete screenshot-backed review rows and remediate any row-level layout/content defects. |

### Likely Files / Widgets
- `app/apps/loom_communities_demo/lib/main.dart`
- `app/apps/loom_communities_demo/test/b21_b25_production_ux_test.dart`
- `docs/Build Plan V2/Evidence/B25/production-ux-blueprint.md`
- `docs/Build Plan V2/Evidence/B25/independent-production-ux-review.json`
- `docs/Build Plan V2/Evidence/B25/product-ux-screen-review-matrix.md`
- `app/apps/loom_communities_demo/integration_test/workflow_ui_evidence_test.dart`
- `app/apps/loom_communities_demo/test/workflow_ui_test_harness.dart`

### Concrete Acceptance Criteria
- Holistic direct-question answers are present, screenshot-backed, non-boilerplate, and pass.
- `production_ux_judge.dart` has no blocking failure for this criterion.
- `b25_iteration_scorecard.dart` records the ticket as resolved or no longer blocking.
- Screenshots are refreshed and hashes/timestamps/app commit SHA match the reviewed app version.
- Screen row `b25-v4-row-184-wf-persona-role-inventory-capability-matrix-0` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-184-wf-persona-role-inventory-capability-matrix-0` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-184-wf-persona-role-inventory-capability-matrix-0` names visible UI elements, visible text, persona `admin`, workflow `wf_persona-role-inventory-capability-matrix`, and the exact product UX issue.
- Primary surface for `wf_persona-role-inventory-capability-matrix` is documented as `persona capability matrix surface with roles, allowed actions, receiver states, and denied/hidden behavior` or another explicit domain-native surface.
- Fresh screenshot path/hash/timestamp/app commit SHA are recorded after the fix.
- Screen row `b25-v4-row-185-wf-persona-role-inventory-capability-matrix-1` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-185-wf-persona-role-inventory-capability-matrix-1` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-185-wf-persona-role-inventory-capability-matrix-1` names visible UI elements, visible text, persona `member`, workflow `wf_persona-role-inventory-capability-matrix`, and the exact product UX issue.
- Coverage row has a specific persona and personaId.
- Coverage row has entry, action/review, and result/receiver screenshots.
- Every listed screenshot path exists and has a fresh hash/timestamp/app commit SHA.
- The workflow/persona scorecard passes after rerun.

### Affected Evidence
- `independent-production-ux-review.json holisticQuestionAnswers`
- `independent-production-ux-review.md holistic review summary`
- `product-ux-screen-review-matrix.md relevant screen rows`
- `production-ux-criteria-scorecard.json/.md`

### Evidence To Collect
- Fresh holistic screenshots for primary homes, navigation, representative detail surfaces, and representative completion/result states.
- `holisticQuestionAnswers` with visible evidence, score, pass/fail answer, and specific rationale.
- Updated `production-ux-criteria-scorecard.json/.md` showing the criterion passes.

### Acceptance Checks
- Holistic direct-question answers are present, screenshot-backed, non-boilerplate, and pass.
- `production_ux_judge.dart` has no blocking failure for this criterion.
- `b25_iteration_scorecard.dart` records the ticket as resolved or no longer blocking.
- Screenshots are refreshed and hashes/timestamps/app commit SHA match the reviewed app version.

### Non-Goals
- Do not close the ticket without fresh evidence and a passing judge rerun.

### Commit Boundary

Commit this remediation iteration, refreshed evidence, scorecards, tickets, and tracker updates before starting the next UX feedback loop.

### Rerun Commands
- `dart run packages/tooling/loom_ux_judges/bin/b25_evidence_collector.dart --evidence-root ../docs/Build\ Plan\ V2/Evidence --repo-root .. --run-id <next-run-id> --prior-review ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --output ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.md --matrix-output ../docs/Build\ Plan\ V2/Evidence/B25/product-ux-screen-review-matrix.md`
- `dart run packages/tooling/loom_ux_judges/bin/b25_workflow_persona_coverage_collector.dart --input ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --output ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/workflow-persona-coverage-matrix.md`
- `dart run packages/tooling/loom_ux_judges/bin/b25_independent_ux_judge.dart --input ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --output ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.md --matrix-output ../docs/Build\ Plan\ V2/Evidence/B25/product-ux-screen-review-matrix.md`
- `dart run packages/tooling/loom_ux_judges/bin/production_ux_judge.dart --input ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --base .. --output ../docs/Build\ Plan\ V2/Evidence/B25/production-ux-criteria-scorecard.json --markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/production-ux-criteria-scorecard.md --tickets-output ../docs/Build\ Plan\ V2/Evidence/B25/b25-remediation-tickets-<next-run-id>.json --tickets-markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/b25-remediation-tickets-<next-run-id>.md`
- `dart run packages/tooling/loom_ux_judges/bin/b25_iteration_scorecard.dart --review ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --judge ../docs/Build\ Plan\ V2/Evidence/B25/production-ux-criteria-scorecard.json --previous ../docs/Build\ Plan\ V2/Evidence/B25/b25-iteration-scorecard-latest.json --output ../docs/Build\ Plan\ V2/Evidence/B25/b25-iteration-scorecard-latest.json --markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/b25-iteration-scorecard-latest.md`
