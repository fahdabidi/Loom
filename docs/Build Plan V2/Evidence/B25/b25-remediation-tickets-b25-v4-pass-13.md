# Remediation Tickets

| Field | Value |
| --- | --- |
| Tool | `production-ux-judge` |
| Status | `fail` |
| Open tickets | 6 |

## B25-RT-001-b25-c01-no-blocker-major

| Field | Value |
| --- | --- |
| Severity | major |
| Priority | P1 |
| Status | open |
| Review run | `b25-v4-pass-13` |
| Source criterion | `b25-c01-no-blocker-major` |
| Source findings | LLM-UX-001, LLM-UX-002, LLM-UX-003 |
| Title | No unresolved blocker or major findings |
| Direct question | Are there zero unresolved blocker or major findings in the current production UX evidence? |
| Why it failed | Unresolved blocker/major counts are blocker=1 major=2. |
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
| Event detail and RSVP flow | Material cards/lists/buttons / pattern | https://m3.material.io/components/cards/overview<br>Also: https://m3.material.io/components/buttons/overview<br>https://m3.material.io/components/chips/overview | Copy an event detail layout: title, date/time, location, host, capacity/status chip, attendee context, RSVP action, and confirmation state. |
| Material detail surface composition | Material Design 3 / design-system | https://m3.material.io/components/cards/overview | Build a domain detail page with primary content, metadata, status, and actions instead of a generic task card. |

### Reference Research Queries
- production mobile UX review screenshot critique examples
- open source Flutter mobile app UX patterns GitHub
- open source Flutter event-rsvp mobile UI example GitHub
- event detail with schedule, location, capacity/status, RSVP action, and result state mobile UX pattern
- Material Design event detail with schedule, location, capacity/status, RSVP action, and result state mobile pattern
- open source Flutter domain-native-surface mobile UI example GitHub
- plant exchange offer form and member marketplace surface with plant details, pickup timing, owner contact, and submitted offer state mobile UX pattern
- Material Design plant exchange offer form and member marketplace surface with plant details, pickup timing, owner contact, and submitted offer state mobile pattern

### Implementation Blocked By
- Open blocker/major B25 tickets remain.
- The scorecard cannot close until those tickets rerun clean.

### Affected Screen Rows

Showing 4 of 4 affected screen rows. Full detail is in the JSON ticket.

| Screen row | Community | Workflow | Persona | State | Screenshot | Hash | Visible text | Current surface | Exact UX failure | Target surface |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `b25-v4-row-001-garden-event-rsvp-0` | Garden Club | `garden-event-rsvp` | member | B13_ext_garden_club_garden-event-rsvp_start | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B13/screenshots/B13_ext_garden_club_garden-event-rsvp_start.png` | `77fdf1ed2004f...` | Garden event RSVP \| Event details include date, location, capacity, RSVP action, and attendance result. \| This week \| Community venue \| Capacity tracked \| RSVP available \| Decide if you are going, maybe, or not attending after checking date, time, location, and capacity. \| Cha... | domain-native-reviewed / domain-native | LLM vision critique: The RSVP screen is framed as a validated workflow summary, not a real event page. It lacks event-specific richness such as event title, date/time prominence, venue details, attendee counts, host, and RSVP state. LLM required fix: Redesign as a domain-native event RSVP surface with event identity, schedule, location, capacity/attendee state, member response controls, and contextual community navigation. Current row verdict is `fail` with severity `major`. | event detail with schedule, location, capacity/status, RSVP action, and result state |
| `b25-v4-row-002-garden-event-rsvp-1` | Garden Club | `garden-event-rsvp` | member | B13_ext_garden_club_garden-event-rsvp_action | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B13/screenshots/B13_ext_garden_club_garden-event-rsvp_action.png` | `36693ddb1c880...` | Coordinate attendance \| Use this surface to publish event details, capacity, and attendance state. \| This week \| Community venue \| Capacity tracked \| RSVP available \| Decision \| Decide if you are going, maybe, or not attending after checking date, time, location, and capacity.... | domain-native-reviewed / domain-native | LLM vision critique: This is visibly a workflow action harness. The language is internal and generic, and the user cannot understand the plant being offered or exchanged from the screen. LLM required fix: Replace generic action summary with a plant offer submission/review surface including plant name, variety, condition, photo, pickup/contact preferences, privacy choices in natural language, and clear submit/edit/cancel actions. Current row verdict is `fail` with severity `major`. | event detail with schedule, location, capacity/status, RSVP action, and result state |
| `b25-v4-row-004-plant-exchange-submission-0` | Garden Club | `plant-exchange-submission` | member | B13_ext_garden_club_plant-exchange-submission_start | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B13/screenshots/B13_ext_garden_club_plant-exchange-submission_start.png` | `9ebec9fb5b790...` | Plant exchange submission \| Member form captures labeled details, privacy choices, and reviewer handoff. \| Labeled fields \| Privacy checked \| Review handoff \| Decide whether to claim, offer, edit, or cancel the plant exchange after checking variety, pickup, and contact details... | domain-native-reviewed / domain-native | LLM vision critique: The screen exposes system validation and admin/export concepts in a member-facing community flow. It does not present a rich plant exchange marketplace or member offer experience. LLM required fix: Create a plant exchange product surface showing available/requested plants, offer details, pickup logistics, member trust/privacy affordances, and natural next actions. Current row verdict is `fail` with severity `major`. | plant exchange offer form and member marketplace surface with plant details, pickup timing, owner contact, and submitted offer state |
| `b25-v4-row-005-plant-exchange-submission-1` | Garden Club | `plant-exchange-submission` | member | B13_ext_garden_club_plant-exchange-submission_action | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B13/screenshots/B13_ext_garden_club_plant-exchange-submission_action.png` | `f879cde026f70...` | Submit member form \| Use this surface to submit structured member details. \| Labeled fields \| Privacy checked \| Review handoff \| Decision \| Decide whether to claim, offer, edit, or cancel the plant exchange after checking variety, pickup, and contact details. \| Details \| Requi... | domain-native-reviewed / domain-native | LLM vision critique: The primary action is plausible, but the rest of the screen is not production-grade. It reads like proof that requirements were satisfied rather than a member-facing submission UI. LLM required fix: Convert the page into a real offer creation/review experience with form fields, preview, privacy/contact settings, reviewer status only if relevant, and human-readable confirmation copy. Current row verdict is `fail` with severity `major`. | plant exchange offer form and member marketplace surface with plant details, pickup timing, owner contact, and submitted offer state |

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
- Screen row `b25-v4-row-001-garden-event-rsvp-0` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-001-garden-event-rsvp-0` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-001-garden-event-rsvp-0` names visible UI elements, visible text, persona `member`, workflow `garden-event-rsvp`, and the exact product UX issue.
- Primary surface for `garden-event-rsvp` is documented as `event detail with schedule, location, capacity/status, RSVP action, and result state` or another explicit domain-native surface.
- After-screenshot visible text proves every required semantic surface group for `garden-event-rsvp`.
- Fresh screenshot path/hash/timestamp/app commit SHA are recorded after the fix.
- Screen row `b25-v4-row-002-garden-event-rsvp-1` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-002-garden-event-rsvp-1` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-002-garden-event-rsvp-1` names visible UI elements, visible text, persona `member`, workflow `garden-event-rsvp`, and the exact product UX issue.
- Screen row `b25-v4-row-004-plant-exchange-submission-0` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-004-plant-exchange-submission-0` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-004-plant-exchange-submission-0` names visible UI elements, visible text, persona `member`, workflow `plant-exchange-submission`, and the exact product UX issue.
- Primary surface for `plant-exchange-submission` is documented as `plant exchange offer form and member marketplace surface with plant details, pickup timing, owner contact, and submitted offer state` or another explicit domain-native surface.
- After-screenshot visible text proves every required semantic surface group for `plant-exchange-submission`.
- Screen row `b25-v4-row-005-plant-exchange-submission-1` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-005-plant-exchange-submission-1` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-005-plant-exchange-submission-1` names visible UI elements, visible text, persona `member`, workflow `plant-exchange-submission`, and the exact product UX issue.

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
| Review run | `b25-v4-pass-13` |
| Source criterion | `b25-c03-production-grade-experience` |
| Source findings | LLM-UX-001, LLM-UX-002, LLM-UX-003 |
| Title | Reviewer can state the experience feels production-grade |
| Direct question | Does the whole experience feel like a real production community app for the target users, not merely an implemented workflow harness? |
| Why it failed | holistic direct-question answers are missing, weak, partial, or blocking: llm-holistic-production-grade, llm-holistic-modern-ui. |
| Required outcome | Run the independent screenshot-first review and record a production-grade verdict grounded in screen evidence. |
| Remediation mode | `ui-remediation-ready` |
| Worker readiness | ready for worker implementation using the uiRemediationWorkItems |
| First required step | Implement the target production surfaces and content specified in uiRemediationWorkItems, then recapture screenshots. |

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
| Event detail and RSVP flow | Material cards/lists/buttons / pattern | https://m3.material.io/components/cards/overview<br>Also: https://m3.material.io/components/buttons/overview<br>https://m3.material.io/components/chips/overview | Copy an event detail layout: title, date/time, location, host, capacity/status chip, attendee context, RSVP action, and confirmation state. |
| Material detail surface composition | Material Design 3 / design-system | https://m3.material.io/components/cards/overview | Build a domain detail page with primary content, metadata, status, and actions instead of a generic task card. |

### Reference Research Queries
- production mobile UX review screenshot critique examples
- open source Flutter mobile app UX patterns GitHub
- open source Flutter event-rsvp mobile UI example GitHub
- event detail with schedule, location, capacity/status, RSVP action, and result state mobile UX pattern
- Material Design event detail with schedule, location, capacity/status, RSVP action, and result state mobile pattern
- open source Flutter domain-native-surface mobile UI example GitHub
- plant exchange offer form and member marketplace surface with plant details, pickup timing, owner contact, and submitted offer state mobile UX pattern
- Material Design plant exchange offer form and member marketplace surface with plant details, pickup timing, owner contact, and submitted offer state mobile pattern

### UI Remediation Work Items

Showing 2 of 2 work items. Full detail is in the JSON artifact.

| Work item | Stage | Community | Workflow | Persona | Screens | Coverage | Target surface | Blocked until |
| --- | --- | --- | --- | --- | ---: | ---: | --- | --- |
| `b25-wi-ui-remediation-community-garden-club-garden-event-rsvp-community-garden-club-member` | `ui-remediation` | Garden Club | `garden-event-rsvp` | member | 2 | 0 | event detail with schedule, location, capacity/status, RSVP action, and result state | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-garden-club-plant-exchange-submission-community-garden-club-member` | `ui-remediation` | Garden Club | `plant-exchange-submission` | member | 2 | 0 | plant exchange offer form and member marketplace surface with plant details, pickup timing, owner contact, and submitted offer state | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |

### UI Remediation Work Items Reference Patterns

| Reference | Source | URL | What to copy |
| --- | --- | --- | --- |
| Event detail and RSVP flow | Material cards/lists/buttons / pattern | https://m3.material.io/components/cards/overview<br>Also: https://m3.material.io/components/buttons/overview<br>https://m3.material.io/components/chips/overview | Copy an event detail layout: title, date/time, location, host, capacity/status chip, attendee context, RSVP action, and confirmation state. |
| Material Design cards and lists | Material Design 3 / design-system | https://m3.material.io/components/cards/overview<br>Also: https://m3.material.io/components/lists/overview | Use cards/lists only as scannable containers with clear hierarchy, content, metadata, and actions. Do not use repeated cards as the whole primary workflow. |
| Flutter sample app implementation patterns | flutter/samples / open-source | https://github.com/flutter/samples | Copy the separation between app shell, route state, domain widgets, and testable UI states rather than hardcoding a single generic renderer. |
| Material navigation and information architecture | Material Design 3 / design-system | https://m3.material.io/components/navigation-drawer/overview<br>Also: https://m3.material.io/components/navigation-bar/overview | Organize screens by user jobs and destinations; keep primary actions visible and avoid exposing implementation taxonomy. |
| Apple HIG navigation and content organization | Apple Human Interface Guidelines / design-system | https://developer.apple.com/design/human-interface-guidelines/navigation | Make navigation predictable, content-centered, and appropriate for the user’s current task. |
| Material detail surface composition | Material Design 3 / design-system | https://m3.material.io/components/cards/overview | Build a domain detail page with primary content, metadata, status, and actions instead of a generic task card. |

### Affected Screen Rows

Showing 4 of 4 affected screen rows. Full detail is in the JSON ticket.

| Screen row | Community | Workflow | Persona | State | Screenshot | Hash | Visible text | Current surface | Exact UX failure | Target surface |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `b25-v4-row-001-garden-event-rsvp-0` | Garden Club | `garden-event-rsvp` | member | B13_ext_garden_club_garden-event-rsvp_start | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B13/screenshots/B13_ext_garden_club_garden-event-rsvp_start.png` | `77fdf1ed2004f...` | Garden event RSVP \| Event details include date, location, capacity, RSVP action, and attendance result. \| This week \| Community venue \| Capacity tracked \| RSVP available \| Decide if you are going, maybe, or not attending after checking date, time, location, and capacity. \| Cha... | domain-native-reviewed / domain-native | LLM vision critique: The RSVP screen is framed as a validated workflow summary, not a real event page. It lacks event-specific richness such as event title, date/time prominence, venue details, attendee counts, host, and RSVP state. LLM required fix: Redesign as a domain-native event RSVP surface with event identity, schedule, location, capacity/attendee state, member response controls, and contextual community navigation. Current row verdict is `fail` with severity `major`. | event detail with schedule, location, capacity/status, RSVP action, and result state |
| `b25-v4-row-002-garden-event-rsvp-1` | Garden Club | `garden-event-rsvp` | member | B13_ext_garden_club_garden-event-rsvp_action | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B13/screenshots/B13_ext_garden_club_garden-event-rsvp_action.png` | `36693ddb1c880...` | Coordinate attendance \| Use this surface to publish event details, capacity, and attendance state. \| This week \| Community venue \| Capacity tracked \| RSVP available \| Decision \| Decide if you are going, maybe, or not attending after checking date, time, location, and capacity.... | domain-native-reviewed / domain-native | LLM vision critique: This is visibly a workflow action harness. The language is internal and generic, and the user cannot understand the plant being offered or exchanged from the screen. LLM required fix: Replace generic action summary with a plant offer submission/review surface including plant name, variety, condition, photo, pickup/contact preferences, privacy choices in natural language, and clear submit/edit/cancel actions. Current row verdict is `fail` with severity `major`. | event detail with schedule, location, capacity/status, RSVP action, and result state |
| `b25-v4-row-004-plant-exchange-submission-0` | Garden Club | `plant-exchange-submission` | member | B13_ext_garden_club_plant-exchange-submission_start | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B13/screenshots/B13_ext_garden_club_plant-exchange-submission_start.png` | `9ebec9fb5b790...` | Plant exchange submission \| Member form captures labeled details, privacy choices, and reviewer handoff. \| Labeled fields \| Privacy checked \| Review handoff \| Decide whether to claim, offer, edit, or cancel the plant exchange after checking variety, pickup, and contact details... | domain-native-reviewed / domain-native | LLM vision critique: The screen exposes system validation and admin/export concepts in a member-facing community flow. It does not present a rich plant exchange marketplace or member offer experience. LLM required fix: Create a plant exchange product surface showing available/requested plants, offer details, pickup logistics, member trust/privacy affordances, and natural next actions. Current row verdict is `fail` with severity `major`. | plant exchange offer form and member marketplace surface with plant details, pickup timing, owner contact, and submitted offer state |
| `b25-v4-row-005-plant-exchange-submission-1` | Garden Club | `plant-exchange-submission` | member | B13_ext_garden_club_plant-exchange-submission_action | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B13/screenshots/B13_ext_garden_club_plant-exchange-submission_action.png` | `f879cde026f70...` | Submit member form \| Use this surface to submit structured member details. \| Labeled fields \| Privacy checked \| Review handoff \| Decision \| Decide whether to claim, offer, edit, or cancel the plant exchange after checking variety, pickup, and contact details. \| Details \| Requi... | domain-native-reviewed / domain-native | LLM vision critique: The primary action is plausible, but the rest of the screen is not production-grade. It reads like proof that requirements were satisfied rather than a member-facing submission UI. LLM required fix: Convert the page into a real offer creation/review experience with form fields, preview, privacy/contact settings, reviewer status only if relevant, and human-readable confirmation copy. Current row verdict is `fail` with severity `major`. | plant exchange offer form and member marketplace surface with plant details, pickup timing, owner contact, and submitted offer state |

### Failing Direct Questions

| Question | Scope | Score | Why | Required fix |
| --- | --- | ---: | --- | --- |
| Does the whole experience feel like a real production community app, not merely an implemented workflow harness? | llm-vision-holistic | 35 |  | Replace harness/checklist cards with domain-native product views: plant offer details, photos, variety, pickup/contact preferences, requester/member context, RSVP attendee state, event schedule/location/capacity, and production action flows. |
| Is the UI modern, easy to use, easy to navigate, and visually appealing for the target persona? | llm-vision-holistic | 48 |  | Introduce clearer information architecture, less repetitive card stacking, stronger domain-specific content, better action hierarchy, and ensure floating controls do not obscure list content. |

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
- Screen row `b25-v4-row-001-garden-event-rsvp-0` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-001-garden-event-rsvp-0` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-001-garden-event-rsvp-0` names visible UI elements, visible text, persona `member`, workflow `garden-event-rsvp`, and the exact product UX issue.
- Primary surface for `garden-event-rsvp` is documented as `event detail with schedule, location, capacity/status, RSVP action, and result state` or another explicit domain-native surface.
- After-screenshot visible text proves every required semantic surface group for `garden-event-rsvp`.
- Fresh screenshot path/hash/timestamp/app commit SHA are recorded after the fix.
- Screen row `b25-v4-row-002-garden-event-rsvp-1` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-002-garden-event-rsvp-1` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-002-garden-event-rsvp-1` names visible UI elements, visible text, persona `member`, workflow `garden-event-rsvp`, and the exact product UX issue.
- Screen row `b25-v4-row-004-plant-exchange-submission-0` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-004-plant-exchange-submission-0` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-004-plant-exchange-submission-0` names visible UI elements, visible text, persona `member`, workflow `plant-exchange-submission`, and the exact product UX issue.
- Primary surface for `plant-exchange-submission` is documented as `plant exchange offer form and member marketplace surface with plant details, pickup timing, owner contact, and submitted offer state` or another explicit domain-native surface.
- After-screenshot visible text proves every required semantic surface group for `plant-exchange-submission`.
- Screen row `b25-v4-row-005-plant-exchange-submission-1` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-005-plant-exchange-submission-1` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-005-plant-exchange-submission-1` names visible UI elements, visible text, persona `member`, workflow `plant-exchange-submission`, and the exact product UX issue.

### Affected Evidence
- `independent-production-ux-review.json holisticQuestionAnswers`
- `independent-production-ux-review.md holistic review summary`
- `product-ux-screen-review-matrix.md relevant screen rows`
- `production-ux-criteria-scorecard.json/.md`

### Evidence To Collect
- Fresh holistic screenshots for primary homes, navigation, representative detail surfaces, and representative completion/result states.
- `holisticQuestionAnswers` with visible evidence, score, pass/fail answer, and specific rationale.
- `llmVisionReview` imported from a fresh LLM vision UX judge run against the after screenshots.
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

## B25-RT-003-b25-c14-llm-vision-ux-review

| Field | Value |
| --- | --- |
| Severity | major |
| Priority | P1 |
| Status | open |
| Review run | `b25-v4-pass-13` |
| Source criterion | `b25-c14-llm-vision-ux-review` |
| Source findings | LLM-UX-001, LLM-UX-002, LLM-UX-003 |
| Title | LLM vision UX judge has inspected screenshots semantically |
| Direct question | Has a fresh LLM vision UX Judge inspected the actual screenshots as product UI, answered direct UX questions from visible evidence, and found no blocker or major product-quality issues? |
| Why it failed | The LLM vision UX review failed from screenshot inspection. blockingFindings=LLM-UX-001, LLM-UX-002, LLM-UX-003 blockingQuestions=llm-holistic-production-grade, llm-holistic-modern-ui blockingScreens=b25-v4-row-001-garden-event-rsvp-0, b25-v4-row-002-garden-event-rsvp-1, b25-v4-row-004-plant-exchange-submission-0, b25-v4-row-005-plant-exchange-submission-1. |
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
| Event detail and RSVP flow | Material cards/lists/buttons / pattern | https://m3.material.io/components/cards/overview<br>Also: https://m3.material.io/components/buttons/overview<br>https://m3.material.io/components/chips/overview | Copy an event detail layout: title, date/time, location, host, capacity/status chip, attendee context, RSVP action, and confirmation state. |
| Material detail surface composition | Material Design 3 / design-system | https://m3.material.io/components/cards/overview | Build a domain detail page with primary content, metadata, status, and actions instead of a generic task card. |

### Reference Research Queries
- production mobile UX review screenshot critique examples
- open source Flutter mobile app UX patterns GitHub
- open source Flutter event-rsvp mobile UI example GitHub
- event detail with schedule, location, capacity/status, RSVP action, and result state mobile UX pattern
- Material Design event detail with schedule, location, capacity/status, RSVP action, and result state mobile pattern
- open source Flutter domain-native-surface mobile UI example GitHub
- plant exchange offer form and member marketplace surface with plant details, pickup timing, owner contact, and submitted offer state mobile UX pattern
- Material Design plant exchange offer form and member marketplace surface with plant details, pickup timing, owner contact, and submitted offer state mobile pattern

### Implementation Blocked By
- The ticket lacks row-level implementation evidence.

### Affected Screen Rows

Showing 4 of 4 affected screen rows. Full detail is in the JSON ticket.

| Screen row | Community | Workflow | Persona | State | Screenshot | Hash | Visible text | Current surface | Exact UX failure | Target surface |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `b25-v4-row-001-garden-event-rsvp-0` | Garden Club | `garden-event-rsvp` | member | B13_ext_garden_club_garden-event-rsvp_start | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B13/screenshots/B13_ext_garden_club_garden-event-rsvp_start.png` | `77fdf1ed2004f...` | Garden event RSVP \| Event details include date, location, capacity, RSVP action, and attendance result. \| This week \| Community venue \| Capacity tracked \| RSVP available \| Decide if you are going, maybe, or not attending after checking date, time, location, and capacity. \| Cha... | domain-native-reviewed / domain-native | LLM vision critique: The RSVP screen is framed as a validated workflow summary, not a real event page. It lacks event-specific richness such as event title, date/time prominence, venue details, attendee counts, host, and RSVP state. LLM required fix: Redesign as a domain-native event RSVP surface with event identity, schedule, location, capacity/attendee state, member response controls, and contextual community navigation. Current row verdict is `fail` with severity `major`. | event detail with schedule, location, capacity/status, RSVP action, and result state |
| `b25-v4-row-002-garden-event-rsvp-1` | Garden Club | `garden-event-rsvp` | member | B13_ext_garden_club_garden-event-rsvp_action | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B13/screenshots/B13_ext_garden_club_garden-event-rsvp_action.png` | `36693ddb1c880...` | Coordinate attendance \| Use this surface to publish event details, capacity, and attendance state. \| This week \| Community venue \| Capacity tracked \| RSVP available \| Decision \| Decide if you are going, maybe, or not attending after checking date, time, location, and capacity.... | domain-native-reviewed / domain-native | LLM vision critique: This is visibly a workflow action harness. The language is internal and generic, and the user cannot understand the plant being offered or exchanged from the screen. LLM required fix: Replace generic action summary with a plant offer submission/review surface including plant name, variety, condition, photo, pickup/contact preferences, privacy choices in natural language, and clear submit/edit/cancel actions. Current row verdict is `fail` with severity `major`. | event detail with schedule, location, capacity/status, RSVP action, and result state |
| `b25-v4-row-004-plant-exchange-submission-0` | Garden Club | `plant-exchange-submission` | member | B13_ext_garden_club_plant-exchange-submission_start | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B13/screenshots/B13_ext_garden_club_plant-exchange-submission_start.png` | `9ebec9fb5b790...` | Plant exchange submission \| Member form captures labeled details, privacy choices, and reviewer handoff. \| Labeled fields \| Privacy checked \| Review handoff \| Decide whether to claim, offer, edit, or cancel the plant exchange after checking variety, pickup, and contact details... | domain-native-reviewed / domain-native | LLM vision critique: The screen exposes system validation and admin/export concepts in a member-facing community flow. It does not present a rich plant exchange marketplace or member offer experience. LLM required fix: Create a plant exchange product surface showing available/requested plants, offer details, pickup logistics, member trust/privacy affordances, and natural next actions. Current row verdict is `fail` with severity `major`. | plant exchange offer form and member marketplace surface with plant details, pickup timing, owner contact, and submitted offer state |
| `b25-v4-row-005-plant-exchange-submission-1` | Garden Club | `plant-exchange-submission` | member | B13_ext_garden_club_plant-exchange-submission_action | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B13/screenshots/B13_ext_garden_club_plant-exchange-submission_action.png` | `f879cde026f70...` | Submit member form \| Use this surface to submit structured member details. \| Labeled fields \| Privacy checked \| Review handoff \| Decision \| Decide whether to claim, offer, edit, or cancel the plant exchange after checking variety, pickup, and contact details. \| Details \| Requi... | domain-native-reviewed / domain-native | LLM vision critique: The primary action is plausible, but the rest of the screen is not production-grade. It reads like proof that requirements were satisfied rather than a member-facing submission UI. LLM required fix: Convert the page into a real offer creation/review experience with form fields, preview, privacy/contact settings, reviewer status only if relevant, and human-readable confirmation copy. Current row verdict is `fail` with severity `major`. | plant exchange offer form and member marketplace surface with plant details, pickup timing, owner contact, and submitted offer state |

### Failing Direct Questions

| Question | Scope | Score | Why | Required fix |
| --- | --- | ---: | --- | --- |
| Does the whole experience feel like a real production community app, not merely an implemented workflow harness? | llm-vision-holistic | 35 |  | Replace harness/checklist cards with domain-native product views: plant offer details, photos, variety, pickup/contact preferences, requester/member context, RSVP attendee state, event schedule/location/capacity, and production action flows. |
| Is the UI modern, easy to use, easy to navigate, and visually appealing for the target persona? | llm-vision-holistic | 48 |  | Introduce clearer information architecture, less repetitive card stacking, stronger domain-specific content, better action hierarchy, and ensure floating controls do not obscure list content. |

### Likely Files / Widgets
- `app/apps/loom_communities_demo/lib/main.dart`
- `app/apps/loom_communities_demo/test/b21_b25_production_ux_test.dart`
- `docs/Build Plan V2/Evidence/B25/production-ux-blueprint.md`
- `docs/Build Plan V2/Evidence/B25/independent-production-ux-review.json`
- `docs/Build Plan V2/Evidence/B25/product-ux-screen-review-matrix.md`
- `app/apps/loom_communities_demo/integration_test/workflow_ui_evidence_test.dart`
- `app/apps/loom_communities_demo/test/workflow_ui_test_harness.dart`

### Concrete Acceptance Criteria
- `production_ux_judge.dart` has no blocking failure for this criterion.
- `b25_iteration_scorecard.dart` records the ticket as resolved or no longer blocking.
- Screenshots are refreshed and hashes/timestamps/app commit SHA match the reviewed app version.
- Screen row `b25-v4-row-001-garden-event-rsvp-0` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-001-garden-event-rsvp-0` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-001-garden-event-rsvp-0` names visible UI elements, visible text, persona `member`, workflow `garden-event-rsvp`, and the exact product UX issue.
- Primary surface for `garden-event-rsvp` is documented as `event detail with schedule, location, capacity/status, RSVP action, and result state` or another explicit domain-native surface.
- After-screenshot visible text proves every required semantic surface group for `garden-event-rsvp`.
- Fresh screenshot path/hash/timestamp/app commit SHA are recorded after the fix.
- Screen row `b25-v4-row-002-garden-event-rsvp-1` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-002-garden-event-rsvp-1` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-002-garden-event-rsvp-1` names visible UI elements, visible text, persona `member`, workflow `garden-event-rsvp`, and the exact product UX issue.
- Screen row `b25-v4-row-004-plant-exchange-submission-0` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-004-plant-exchange-submission-0` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-004-plant-exchange-submission-0` names visible UI elements, visible text, persona `member`, workflow `plant-exchange-submission`, and the exact product UX issue.
- Primary surface for `plant-exchange-submission` is documented as `plant exchange offer form and member marketplace surface with plant details, pickup timing, owner contact, and submitted offer state` or another explicit domain-native surface.
- After-screenshot visible text proves every required semantic surface group for `plant-exchange-submission`.
- Screen row `b25-v4-row-005-plant-exchange-submission-1` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-005-plant-exchange-submission-1` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-005-plant-exchange-submission-1` names visible UI elements, visible text, persona `member`, workflow `plant-exchange-submission`, and the exact product UX issue.

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
- `dart run packages/tooling/loom_ux_judges/bin/b25_evidence_collector.dart --evidence-root ../docs/Build\ Plan\ V2/Evidence --repo-root .. --run-id <next-run-id> --prior-review ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --output ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.md --matrix-output ../docs/Build\ Plan\ V2/Evidence/B25/product-ux-screen-review-matrix.md`
- `dart run packages/tooling/loom_ux_judges/bin/b25_workflow_persona_coverage_collector.dart --input ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --output ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/workflow-persona-coverage-matrix.md`
- `dart run packages/tooling/loom_ux_judges/bin/b25_independent_ux_judge.dart --input ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --output ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.md --matrix-output ../docs/Build\ Plan\ V2/Evidence/B25/product-ux-screen-review-matrix.md`
- `dart run packages/tooling/loom_ux_judges/bin/production_ux_judge.dart --input ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --base .. --output ../docs/Build\ Plan\ V2/Evidence/B25/production-ux-criteria-scorecard.json --markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/production-ux-criteria-scorecard.md --tickets-output ../docs/Build\ Plan\ V2/Evidence/B25/b25-remediation-tickets-<next-run-id>.json --tickets-markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/b25-remediation-tickets-<next-run-id>.md`
- `dart run packages/tooling/loom_ux_judges/bin/b25_iteration_scorecard.dart --review ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --judge ../docs/Build\ Plan\ V2/Evidence/B25/production-ux-criteria-scorecard.json --previous ../docs/Build\ Plan\ V2/Evidence/B25/b25-iteration-scorecard-latest.json --output ../docs/Build\ Plan\ V2/Evidence/B25/b25-iteration-scorecard-latest.json --markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/b25-iteration-scorecard-latest.md`

## B25-RT-004-b25-c04-modern-intentional-ui

| Field | Value |
| --- | --- |
| Severity | major |
| Priority | P1 |
| Status | open |
| Review run | `b25-v4-pass-13` |
| Source criterion | `b25-c04-modern-intentional-ui` |
| Source findings | LLM-UX-001, LLM-UX-002, LLM-UX-003 |
| Title | UI looks modern and intentionally designed |
| Direct question | Is the UI modern, easy to use, easy to navigate, and visually appealing for the target persona? |
| Why it failed | holistic direct-question answers are missing, weak, partial, or blocking: llm-holistic-production-grade, llm-holistic-modern-ui. |
| Required outcome | Remediate visual hierarchy, spacing, typography, component quality, and recapture screenshots. |
| Remediation mode | `ui-remediation-ready` |
| Worker readiness | ready for worker implementation using the uiRemediationWorkItems |
| First required step | Implement the target production surfaces and content specified in uiRemediationWorkItems, then recapture screenshots. |

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
| Event detail and RSVP flow | Material cards/lists/buttons / pattern | https://m3.material.io/components/cards/overview<br>Also: https://m3.material.io/components/buttons/overview<br>https://m3.material.io/components/chips/overview | Copy an event detail layout: title, date/time, location, host, capacity/status chip, attendee context, RSVP action, and confirmation state. |
| Material detail surface composition | Material Design 3 / design-system | https://m3.material.io/components/cards/overview | Build a domain detail page with primary content, metadata, status, and actions instead of a generic task card. |

### Reference Research Queries
- modern mobile app information architecture visual hierarchy examples
- Material Design 3 mobile UI hierarchy navigation cards examples
- open source Flutter production app dashboard detail screen examples
- open source Flutter event-rsvp mobile UI example GitHub
- event detail with schedule, location, capacity/status, RSVP action, and result state mobile UX pattern
- Material Design event detail with schedule, location, capacity/status, RSVP action, and result state mobile pattern
- open source Flutter domain-native-surface mobile UI example GitHub
- plant exchange offer form and member marketplace surface with plant details, pickup timing, owner contact, and submitted offer state mobile UX pattern
- Material Design plant exchange offer form and member marketplace surface with plant details, pickup timing, owner contact, and submitted offer state mobile pattern

### UI Remediation Work Items

Showing 2 of 2 work items. Full detail is in the JSON artifact.

| Work item | Stage | Community | Workflow | Persona | Screens | Coverage | Target surface | Blocked until |
| --- | --- | --- | --- | --- | ---: | ---: | --- | --- |
| `b25-wi-ui-remediation-community-garden-club-garden-event-rsvp-community-garden-club-member` | `ui-remediation` | Garden Club | `garden-event-rsvp` | member | 2 | 0 | event detail with schedule, location, capacity/status, RSVP action, and result state | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-garden-club-plant-exchange-submission-community-garden-club-member` | `ui-remediation` | Garden Club | `plant-exchange-submission` | member | 2 | 0 | plant exchange offer form and member marketplace surface with plant details, pickup timing, owner contact, and submitted offer state | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |

### UI Remediation Work Items Reference Patterns

| Reference | Source | URL | What to copy |
| --- | --- | --- | --- |
| Event detail and RSVP flow | Material cards/lists/buttons / pattern | https://m3.material.io/components/cards/overview<br>Also: https://m3.material.io/components/buttons/overview<br>https://m3.material.io/components/chips/overview | Copy an event detail layout: title, date/time, location, host, capacity/status chip, attendee context, RSVP action, and confirmation state. |
| Material Design cards and lists | Material Design 3 / design-system | https://m3.material.io/components/cards/overview<br>Also: https://m3.material.io/components/lists/overview | Use cards/lists only as scannable containers with clear hierarchy, content, metadata, and actions. Do not use repeated cards as the whole primary workflow. |
| Flutter sample app implementation patterns | flutter/samples / open-source | https://github.com/flutter/samples | Copy the separation between app shell, route state, domain widgets, and testable UI states rather than hardcoding a single generic renderer. |
| Material navigation and information architecture | Material Design 3 / design-system | https://m3.material.io/components/navigation-drawer/overview<br>Also: https://m3.material.io/components/navigation-bar/overview | Organize screens by user jobs and destinations; keep primary actions visible and avoid exposing implementation taxonomy. |
| Apple HIG navigation and content organization | Apple Human Interface Guidelines / design-system | https://developer.apple.com/design/human-interface-guidelines/navigation | Make navigation predictable, content-centered, and appropriate for the user’s current task. |
| Material detail surface composition | Material Design 3 / design-system | https://m3.material.io/components/cards/overview | Build a domain detail page with primary content, metadata, status, and actions instead of a generic task card. |

### Affected Screen Rows

Showing 4 of 4 affected screen rows. Full detail is in the JSON ticket.

| Screen row | Community | Workflow | Persona | State | Screenshot | Hash | Visible text | Current surface | Exact UX failure | Target surface |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `b25-v4-row-001-garden-event-rsvp-0` | Garden Club | `garden-event-rsvp` | member | B13_ext_garden_club_garden-event-rsvp_start | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B13/screenshots/B13_ext_garden_club_garden-event-rsvp_start.png` | `77fdf1ed2004f...` | Garden event RSVP \| Event details include date, location, capacity, RSVP action, and attendance result. \| This week \| Community venue \| Capacity tracked \| RSVP available \| Decide if you are going, maybe, or not attending after checking date, time, location, and capacity. \| Cha... | domain-native-reviewed / domain-native | LLM vision critique: The RSVP screen is framed as a validated workflow summary, not a real event page. It lacks event-specific richness such as event title, date/time prominence, venue details, attendee counts, host, and RSVP state. LLM required fix: Redesign as a domain-native event RSVP surface with event identity, schedule, location, capacity/attendee state, member response controls, and contextual community navigation. Current row verdict is `fail` with severity `major`. | event detail with schedule, location, capacity/status, RSVP action, and result state |
| `b25-v4-row-002-garden-event-rsvp-1` | Garden Club | `garden-event-rsvp` | member | B13_ext_garden_club_garden-event-rsvp_action | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B13/screenshots/B13_ext_garden_club_garden-event-rsvp_action.png` | `36693ddb1c880...` | Coordinate attendance \| Use this surface to publish event details, capacity, and attendance state. \| This week \| Community venue \| Capacity tracked \| RSVP available \| Decision \| Decide if you are going, maybe, or not attending after checking date, time, location, and capacity.... | domain-native-reviewed / domain-native | LLM vision critique: This is visibly a workflow action harness. The language is internal and generic, and the user cannot understand the plant being offered or exchanged from the screen. LLM required fix: Replace generic action summary with a plant offer submission/review surface including plant name, variety, condition, photo, pickup/contact preferences, privacy choices in natural language, and clear submit/edit/cancel actions. Current row verdict is `fail` with severity `major`. | event detail with schedule, location, capacity/status, RSVP action, and result state |
| `b25-v4-row-004-plant-exchange-submission-0` | Garden Club | `plant-exchange-submission` | member | B13_ext_garden_club_plant-exchange-submission_start | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B13/screenshots/B13_ext_garden_club_plant-exchange-submission_start.png` | `9ebec9fb5b790...` | Plant exchange submission \| Member form captures labeled details, privacy choices, and reviewer handoff. \| Labeled fields \| Privacy checked \| Review handoff \| Decide whether to claim, offer, edit, or cancel the plant exchange after checking variety, pickup, and contact details... | domain-native-reviewed / domain-native | LLM vision critique: The screen exposes system validation and admin/export concepts in a member-facing community flow. It does not present a rich plant exchange marketplace or member offer experience. LLM required fix: Create a plant exchange product surface showing available/requested plants, offer details, pickup logistics, member trust/privacy affordances, and natural next actions. Current row verdict is `fail` with severity `major`. | plant exchange offer form and member marketplace surface with plant details, pickup timing, owner contact, and submitted offer state |
| `b25-v4-row-005-plant-exchange-submission-1` | Garden Club | `plant-exchange-submission` | member | B13_ext_garden_club_plant-exchange-submission_action | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B13/screenshots/B13_ext_garden_club_plant-exchange-submission_action.png` | `f879cde026f70...` | Submit member form \| Use this surface to submit structured member details. \| Labeled fields \| Privacy checked \| Review handoff \| Decision \| Decide whether to claim, offer, edit, or cancel the plant exchange after checking variety, pickup, and contact details. \| Details \| Requi... | domain-native-reviewed / domain-native | LLM vision critique: The primary action is plausible, but the rest of the screen is not production-grade. It reads like proof that requirements were satisfied rather than a member-facing submission UI. LLM required fix: Convert the page into a real offer creation/review experience with form fields, preview, privacy/contact settings, reviewer status only if relevant, and human-readable confirmation copy. Current row verdict is `fail` with severity `major`. | plant exchange offer form and member marketplace surface with plant details, pickup timing, owner contact, and submitted offer state |

### Failing Direct Questions

| Question | Scope | Score | Why | Required fix |
| --- | --- | ---: | --- | --- |
| Does the whole experience feel like a real production community app, not merely an implemented workflow harness? | llm-vision-holistic | 35 |  | Replace harness/checklist cards with domain-native product views: plant offer details, photos, variety, pickup/contact preferences, requester/member context, RSVP attendee state, event schedule/location/capacity, and production action flows. |
| Is the UI modern, easy to use, easy to navigate, and visually appealing for the target persona? | llm-vision-holistic | 48 |  | Introduce clearer information architecture, less repetitive card stacking, stronger domain-specific content, better action hierarchy, and ensure floating controls do not obscure list content. |

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
- Screen row `b25-v4-row-001-garden-event-rsvp-0` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-001-garden-event-rsvp-0` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-001-garden-event-rsvp-0` names visible UI elements, visible text, persona `member`, workflow `garden-event-rsvp`, and the exact product UX issue.
- Primary surface for `garden-event-rsvp` is documented as `event detail with schedule, location, capacity/status, RSVP action, and result state` or another explicit domain-native surface.
- After-screenshot visible text proves every required semantic surface group for `garden-event-rsvp`.
- Fresh screenshot path/hash/timestamp/app commit SHA are recorded after the fix.
- Screen row `b25-v4-row-002-garden-event-rsvp-1` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-002-garden-event-rsvp-1` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-002-garden-event-rsvp-1` names visible UI elements, visible text, persona `member`, workflow `garden-event-rsvp`, and the exact product UX issue.
- Screen row `b25-v4-row-004-plant-exchange-submission-0` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-004-plant-exchange-submission-0` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-004-plant-exchange-submission-0` names visible UI elements, visible text, persona `member`, workflow `plant-exchange-submission`, and the exact product UX issue.
- Primary surface for `plant-exchange-submission` is documented as `plant exchange offer form and member marketplace surface with plant details, pickup timing, owner contact, and submitted offer state` or another explicit domain-native surface.
- After-screenshot visible text proves every required semantic surface group for `plant-exchange-submission`.
- Screen row `b25-v4-row-005-plant-exchange-submission-1` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-005-plant-exchange-submission-1` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-005-plant-exchange-submission-1` names visible UI elements, visible text, persona `member`, workflow `plant-exchange-submission`, and the exact product UX issue.

### Affected Evidence
- `independent-production-ux-review.json holisticQuestionAnswers`
- `independent-production-ux-review.md holistic review summary`
- `product-ux-screen-review-matrix.md relevant screen rows`
- `production-ux-criteria-scorecard.json/.md`

### Evidence To Collect
- Fresh holistic screenshots for primary homes, navigation, representative detail surfaces, and representative completion/result states.
- `holisticQuestionAnswers` with visible evidence, score, pass/fail answer, and specific rationale.
- `llmVisionReview` imported from a fresh LLM vision UX judge run against the after screenshots.
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

## B25-RT-005-b25-c05-community-content-ia

| Field | Value |
| --- | --- |
| Severity | major |
| Priority | P1 |
| Status | open |
| Review run | `b25-v4-pass-13` |
| Source criterion | `b25-c05-community-content-ia` |
| Source findings | LLM-UX-001, LLM-UX-002, LLM-UX-003 |
| Title | Screens are organized around community content and jobs-to-be-done |
| Direct question | Is the overall information architecture organized around community content and real jobs-to-be-done instead of workflow lists or validation surfaces? |
| Why it failed | holistic direct-question answers are missing, weak, partial, or blocking: llm-holistic-production-grade, llm-holistic-modern-ui. |
| Required outcome | Rebuild home and primary screens around community content and user jobs. |
| Remediation mode | `ui-remediation-ready` |
| Worker readiness | ready for worker implementation using the uiRemediationWorkItems |
| First required step | Implement the target production surfaces and content specified in uiRemediationWorkItems, then recapture screenshots. |

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
| Event detail and RSVP flow | Material cards/lists/buttons / pattern | https://m3.material.io/components/cards/overview<br>Also: https://m3.material.io/components/buttons/overview<br>https://m3.material.io/components/chips/overview | Copy an event detail layout: title, date/time, location, host, capacity/status chip, attendee context, RSVP action, and confirmation state. |
| Material detail surface composition | Material Design 3 / design-system | https://m3.material.io/components/cards/overview | Build a domain detail page with primary content, metadata, status, and actions instead of a generic task card. |

### Reference Research Queries
- community app home screen announcements events messages design examples
- open source Flutter community app home feed events messages UI
- open source Flutter event-rsvp mobile UI example GitHub
- event detail with schedule, location, capacity/status, RSVP action, and result state mobile UX pattern
- Material Design event detail with schedule, location, capacity/status, RSVP action, and result state mobile pattern
- open source Flutter domain-native-surface mobile UI example GitHub
- plant exchange offer form and member marketplace surface with plant details, pickup timing, owner contact, and submitted offer state mobile UX pattern
- Material Design plant exchange offer form and member marketplace surface with plant details, pickup timing, owner contact, and submitted offer state mobile pattern

### UI Remediation Work Items

Showing 2 of 2 work items. Full detail is in the JSON artifact.

| Work item | Stage | Community | Workflow | Persona | Screens | Coverage | Target surface | Blocked until |
| --- | --- | --- | --- | --- | ---: | ---: | --- | --- |
| `b25-wi-ui-remediation-community-garden-club-garden-event-rsvp-community-garden-club-member` | `ui-remediation` | Garden Club | `garden-event-rsvp` | member | 2 | 0 | event detail with schedule, location, capacity/status, RSVP action, and result state | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-garden-club-plant-exchange-submission-community-garden-club-member` | `ui-remediation` | Garden Club | `plant-exchange-submission` | member | 2 | 0 | plant exchange offer form and member marketplace surface with plant details, pickup timing, owner contact, and submitted offer state | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |

### UI Remediation Work Items Reference Patterns

| Reference | Source | URL | What to copy |
| --- | --- | --- | --- |
| Event detail and RSVP flow | Material cards/lists/buttons / pattern | https://m3.material.io/components/cards/overview<br>Also: https://m3.material.io/components/buttons/overview<br>https://m3.material.io/components/chips/overview | Copy an event detail layout: title, date/time, location, host, capacity/status chip, attendee context, RSVP action, and confirmation state. |
| Material Design cards and lists | Material Design 3 / design-system | https://m3.material.io/components/cards/overview<br>Also: https://m3.material.io/components/lists/overview | Use cards/lists only as scannable containers with clear hierarchy, content, metadata, and actions. Do not use repeated cards as the whole primary workflow. |
| Flutter sample app implementation patterns | flutter/samples / open-source | https://github.com/flutter/samples | Copy the separation between app shell, route state, domain widgets, and testable UI states rather than hardcoding a single generic renderer. |
| Material navigation and information architecture | Material Design 3 / design-system | https://m3.material.io/components/navigation-drawer/overview<br>Also: https://m3.material.io/components/navigation-bar/overview | Organize screens by user jobs and destinations; keep primary actions visible and avoid exposing implementation taxonomy. |
| Apple HIG navigation and content organization | Apple Human Interface Guidelines / design-system | https://developer.apple.com/design/human-interface-guidelines/navigation | Make navigation predictable, content-centered, and appropriate for the user’s current task. |
| Material detail surface composition | Material Design 3 / design-system | https://m3.material.io/components/cards/overview | Build a domain detail page with primary content, metadata, status, and actions instead of a generic task card. |

### Affected Screen Rows

Showing 4 of 4 affected screen rows. Full detail is in the JSON ticket.

| Screen row | Community | Workflow | Persona | State | Screenshot | Hash | Visible text | Current surface | Exact UX failure | Target surface |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `b25-v4-row-001-garden-event-rsvp-0` | Garden Club | `garden-event-rsvp` | member | B13_ext_garden_club_garden-event-rsvp_start | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B13/screenshots/B13_ext_garden_club_garden-event-rsvp_start.png` | `77fdf1ed2004f...` | Garden event RSVP \| Event details include date, location, capacity, RSVP action, and attendance result. \| This week \| Community venue \| Capacity tracked \| RSVP available \| Decide if you are going, maybe, or not attending after checking date, time, location, and capacity. \| Cha... | domain-native-reviewed / domain-native | LLM vision critique: The RSVP screen is framed as a validated workflow summary, not a real event page. It lacks event-specific richness such as event title, date/time prominence, venue details, attendee counts, host, and RSVP state. LLM required fix: Redesign as a domain-native event RSVP surface with event identity, schedule, location, capacity/attendee state, member response controls, and contextual community navigation. Current row verdict is `fail` with severity `major`. | event detail with schedule, location, capacity/status, RSVP action, and result state |
| `b25-v4-row-002-garden-event-rsvp-1` | Garden Club | `garden-event-rsvp` | member | B13_ext_garden_club_garden-event-rsvp_action | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B13/screenshots/B13_ext_garden_club_garden-event-rsvp_action.png` | `36693ddb1c880...` | Coordinate attendance \| Use this surface to publish event details, capacity, and attendance state. \| This week \| Community venue \| Capacity tracked \| RSVP available \| Decision \| Decide if you are going, maybe, or not attending after checking date, time, location, and capacity.... | domain-native-reviewed / domain-native | LLM vision critique: This is visibly a workflow action harness. The language is internal and generic, and the user cannot understand the plant being offered or exchanged from the screen. LLM required fix: Replace generic action summary with a plant offer submission/review surface including plant name, variety, condition, photo, pickup/contact preferences, privacy choices in natural language, and clear submit/edit/cancel actions. Current row verdict is `fail` with severity `major`. | event detail with schedule, location, capacity/status, RSVP action, and result state |
| `b25-v4-row-004-plant-exchange-submission-0` | Garden Club | `plant-exchange-submission` | member | B13_ext_garden_club_plant-exchange-submission_start | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B13/screenshots/B13_ext_garden_club_plant-exchange-submission_start.png` | `9ebec9fb5b790...` | Plant exchange submission \| Member form captures labeled details, privacy choices, and reviewer handoff. \| Labeled fields \| Privacy checked \| Review handoff \| Decide whether to claim, offer, edit, or cancel the plant exchange after checking variety, pickup, and contact details... | domain-native-reviewed / domain-native | LLM vision critique: The screen exposes system validation and admin/export concepts in a member-facing community flow. It does not present a rich plant exchange marketplace or member offer experience. LLM required fix: Create a plant exchange product surface showing available/requested plants, offer details, pickup logistics, member trust/privacy affordances, and natural next actions. Current row verdict is `fail` with severity `major`. | plant exchange offer form and member marketplace surface with plant details, pickup timing, owner contact, and submitted offer state |
| `b25-v4-row-005-plant-exchange-submission-1` | Garden Club | `plant-exchange-submission` | member | B13_ext_garden_club_plant-exchange-submission_action | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B13/screenshots/B13_ext_garden_club_plant-exchange-submission_action.png` | `f879cde026f70...` | Submit member form \| Use this surface to submit structured member details. \| Labeled fields \| Privacy checked \| Review handoff \| Decision \| Decide whether to claim, offer, edit, or cancel the plant exchange after checking variety, pickup, and contact details. \| Details \| Requi... | domain-native-reviewed / domain-native | LLM vision critique: The primary action is plausible, but the rest of the screen is not production-grade. It reads like proof that requirements were satisfied rather than a member-facing submission UI. LLM required fix: Convert the page into a real offer creation/review experience with form fields, preview, privacy/contact settings, reviewer status only if relevant, and human-readable confirmation copy. Current row verdict is `fail` with severity `major`. | plant exchange offer form and member marketplace surface with plant details, pickup timing, owner contact, and submitted offer state |

### Failing Direct Questions

| Question | Scope | Score | Why | Required fix |
| --- | --- | ---: | --- | --- |
| Does the whole experience feel like a real production community app, not merely an implemented workflow harness? | llm-vision-holistic | 35 |  | Replace harness/checklist cards with domain-native product views: plant offer details, photos, variety, pickup/contact preferences, requester/member context, RSVP attendee state, event schedule/location/capacity, and production action flows. |
| Is the UI modern, easy to use, easy to navigate, and visually appealing for the target persona? | llm-vision-holistic | 48 |  | Introduce clearer information architecture, less repetitive card stacking, stronger domain-specific content, better action hierarchy, and ensure floating controls do not obscure list content. |

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
- Screen row `b25-v4-row-001-garden-event-rsvp-0` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-001-garden-event-rsvp-0` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-001-garden-event-rsvp-0` names visible UI elements, visible text, persona `member`, workflow `garden-event-rsvp`, and the exact product UX issue.
- Primary surface for `garden-event-rsvp` is documented as `event detail with schedule, location, capacity/status, RSVP action, and result state` or another explicit domain-native surface.
- After-screenshot visible text proves every required semantic surface group for `garden-event-rsvp`.
- Fresh screenshot path/hash/timestamp/app commit SHA are recorded after the fix.
- Screen row `b25-v4-row-002-garden-event-rsvp-1` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-002-garden-event-rsvp-1` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-002-garden-event-rsvp-1` names visible UI elements, visible text, persona `member`, workflow `garden-event-rsvp`, and the exact product UX issue.
- Screen row `b25-v4-row-004-plant-exchange-submission-0` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-004-plant-exchange-submission-0` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-004-plant-exchange-submission-0` names visible UI elements, visible text, persona `member`, workflow `plant-exchange-submission`, and the exact product UX issue.
- Primary surface for `plant-exchange-submission` is documented as `plant exchange offer form and member marketplace surface with plant details, pickup timing, owner contact, and submitted offer state` or another explicit domain-native surface.
- After-screenshot visible text proves every required semantic surface group for `plant-exchange-submission`.
- Screen row `b25-v4-row-005-plant-exchange-submission-1` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-005-plant-exchange-submission-1` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-005-plant-exchange-submission-1` names visible UI elements, visible text, persona `member`, workflow `plant-exchange-submission`, and the exact product UX issue.

### Affected Evidence
- `independent-production-ux-review.json holisticQuestionAnswers`
- `independent-production-ux-review.md holistic review summary`
- `product-ux-screen-review-matrix.md relevant screen rows`
- `production-ux-criteria-scorecard.json/.md`

### Evidence To Collect
- Fresh holistic screenshots for primary homes, navigation, representative detail surfaces, and representative completion/result states.
- `holisticQuestionAnswers` with visible evidence, score, pass/fail answer, and specific rationale.
- `llmVisionReview` imported from a fresh LLM vision UX judge run against the after screenshots.
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

## B25-RT-006-b25-c09-no-layout-production-defects

| Field | Value |
| --- | --- |
| Severity | major |
| Priority | P1 |
| Status | open |
| Review run | `b25-v4-pass-13` |
| Source criterion | `b25-c09-no-layout-production-defects` |
| Source findings | LLM-UX-001, LLM-UX-002, LLM-UX-003 |
| Title | No blocking or major layout/content defects remain |
| Direct question | Does the visible UI avoid blocking or major overlap, clipping, crowding, default-scaffold, repeated-card, checklist-modal, and thin-content defects? |
| Why it failed | holistic direct-question answers are missing, weak, partial, or blocking: llm-holistic-production-grade, llm-holistic-modern-ui. |
| Required outcome | Fix layout/content defects and rerun the review. |
| Remediation mode | `ui-remediation-ready` |
| Worker readiness | ready for worker implementation using the uiRemediationWorkItems |
| First required step | Implement the target production surfaces and content specified in uiRemediationWorkItems, then recapture screenshots. |

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
| Event detail and RSVP flow | Material cards/lists/buttons / pattern | https://m3.material.io/components/cards/overview<br>Also: https://m3.material.io/components/buttons/overview<br>https://m3.material.io/components/chips/overview | Copy an event detail layout: title, date/time, location, host, capacity/status chip, attendee context, RSVP action, and confirmation state. |
| Material detail surface composition | Material Design 3 / design-system | https://m3.material.io/components/cards/overview | Build a domain detail page with primary content, metadata, status, and actions instead of a generic task card. |

### Reference Research Queries
- production mobile UX review screenshot critique examples
- open source Flutter mobile app UX patterns GitHub
- open source Flutter event-rsvp mobile UI example GitHub
- event detail with schedule, location, capacity/status, RSVP action, and result state mobile UX pattern
- Material Design event detail with schedule, location, capacity/status, RSVP action, and result state mobile pattern
- open source Flutter domain-native-surface mobile UI example GitHub
- plant exchange offer form and member marketplace surface with plant details, pickup timing, owner contact, and submitted offer state mobile UX pattern
- Material Design plant exchange offer form and member marketplace surface with plant details, pickup timing, owner contact, and submitted offer state mobile pattern

### UI Remediation Work Items

Showing 2 of 2 work items. Full detail is in the JSON artifact.

| Work item | Stage | Community | Workflow | Persona | Screens | Coverage | Target surface | Blocked until |
| --- | --- | --- | --- | --- | ---: | ---: | --- | --- |
| `b25-wi-ui-remediation-community-garden-club-garden-event-rsvp-community-garden-club-member` | `ui-remediation` | Garden Club | `garden-event-rsvp` | member | 2 | 0 | event detail with schedule, location, capacity/status, RSVP action, and result state | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-garden-club-plant-exchange-submission-community-garden-club-member` | `ui-remediation` | Garden Club | `plant-exchange-submission` | member | 2 | 0 | plant exchange offer form and member marketplace surface with plant details, pickup timing, owner contact, and submitted offer state | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |

### UI Remediation Work Items Reference Patterns

| Reference | Source | URL | What to copy |
| --- | --- | --- | --- |
| Event detail and RSVP flow | Material cards/lists/buttons / pattern | https://m3.material.io/components/cards/overview<br>Also: https://m3.material.io/components/buttons/overview<br>https://m3.material.io/components/chips/overview | Copy an event detail layout: title, date/time, location, host, capacity/status chip, attendee context, RSVP action, and confirmation state. |
| Material Design cards and lists | Material Design 3 / design-system | https://m3.material.io/components/cards/overview<br>Also: https://m3.material.io/components/lists/overview | Use cards/lists only as scannable containers with clear hierarchy, content, metadata, and actions. Do not use repeated cards as the whole primary workflow. |
| Flutter sample app implementation patterns | flutter/samples / open-source | https://github.com/flutter/samples | Copy the separation between app shell, route state, domain widgets, and testable UI states rather than hardcoding a single generic renderer. |
| Material navigation and information architecture | Material Design 3 / design-system | https://m3.material.io/components/navigation-drawer/overview<br>Also: https://m3.material.io/components/navigation-bar/overview | Organize screens by user jobs and destinations; keep primary actions visible and avoid exposing implementation taxonomy. |
| Apple HIG navigation and content organization | Apple Human Interface Guidelines / design-system | https://developer.apple.com/design/human-interface-guidelines/navigation | Make navigation predictable, content-centered, and appropriate for the user’s current task. |
| Material detail surface composition | Material Design 3 / design-system | https://m3.material.io/components/cards/overview | Build a domain detail page with primary content, metadata, status, and actions instead of a generic task card. |

### Affected Screen Rows

Showing 4 of 4 affected screen rows. Full detail is in the JSON ticket.

| Screen row | Community | Workflow | Persona | State | Screenshot | Hash | Visible text | Current surface | Exact UX failure | Target surface |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `b25-v4-row-001-garden-event-rsvp-0` | Garden Club | `garden-event-rsvp` | member | B13_ext_garden_club_garden-event-rsvp_start | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B13/screenshots/B13_ext_garden_club_garden-event-rsvp_start.png` | `77fdf1ed2004f...` | Garden event RSVP \| Event details include date, location, capacity, RSVP action, and attendance result. \| This week \| Community venue \| Capacity tracked \| RSVP available \| Decide if you are going, maybe, or not attending after checking date, time, location, and capacity. \| Cha... | domain-native-reviewed / domain-native | LLM vision critique: The RSVP screen is framed as a validated workflow summary, not a real event page. It lacks event-specific richness such as event title, date/time prominence, venue details, attendee counts, host, and RSVP state. LLM required fix: Redesign as a domain-native event RSVP surface with event identity, schedule, location, capacity/attendee state, member response controls, and contextual community navigation. Current row verdict is `fail` with severity `major`. | event detail with schedule, location, capacity/status, RSVP action, and result state |
| `b25-v4-row-002-garden-event-rsvp-1` | Garden Club | `garden-event-rsvp` | member | B13_ext_garden_club_garden-event-rsvp_action | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B13/screenshots/B13_ext_garden_club_garden-event-rsvp_action.png` | `36693ddb1c880...` | Coordinate attendance \| Use this surface to publish event details, capacity, and attendance state. \| This week \| Community venue \| Capacity tracked \| RSVP available \| Decision \| Decide if you are going, maybe, or not attending after checking date, time, location, and capacity.... | domain-native-reviewed / domain-native | LLM vision critique: This is visibly a workflow action harness. The language is internal and generic, and the user cannot understand the plant being offered or exchanged from the screen. LLM required fix: Replace generic action summary with a plant offer submission/review surface including plant name, variety, condition, photo, pickup/contact preferences, privacy choices in natural language, and clear submit/edit/cancel actions. Current row verdict is `fail` with severity `major`. | event detail with schedule, location, capacity/status, RSVP action, and result state |
| `b25-v4-row-004-plant-exchange-submission-0` | Garden Club | `plant-exchange-submission` | member | B13_ext_garden_club_plant-exchange-submission_start | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B13/screenshots/B13_ext_garden_club_plant-exchange-submission_start.png` | `9ebec9fb5b790...` | Plant exchange submission \| Member form captures labeled details, privacy choices, and reviewer handoff. \| Labeled fields \| Privacy checked \| Review handoff \| Decide whether to claim, offer, edit, or cancel the plant exchange after checking variety, pickup, and contact details... | domain-native-reviewed / domain-native | LLM vision critique: The screen exposes system validation and admin/export concepts in a member-facing community flow. It does not present a rich plant exchange marketplace or member offer experience. LLM required fix: Create a plant exchange product surface showing available/requested plants, offer details, pickup logistics, member trust/privacy affordances, and natural next actions. Current row verdict is `fail` with severity `major`. | plant exchange offer form and member marketplace surface with plant details, pickup timing, owner contact, and submitted offer state |
| `b25-v4-row-005-plant-exchange-submission-1` | Garden Club | `plant-exchange-submission` | member | B13_ext_garden_club_plant-exchange-submission_action | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B13/screenshots/B13_ext_garden_club_plant-exchange-submission_action.png` | `f879cde026f70...` | Submit member form \| Use this surface to submit structured member details. \| Labeled fields \| Privacy checked \| Review handoff \| Decision \| Decide whether to claim, offer, edit, or cancel the plant exchange after checking variety, pickup, and contact details. \| Details \| Requi... | domain-native-reviewed / domain-native | LLM vision critique: The primary action is plausible, but the rest of the screen is not production-grade. It reads like proof that requirements were satisfied rather than a member-facing submission UI. LLM required fix: Convert the page into a real offer creation/review experience with form fields, preview, privacy/contact settings, reviewer status only if relevant, and human-readable confirmation copy. Current row verdict is `fail` with severity `major`. | plant exchange offer form and member marketplace surface with plant details, pickup timing, owner contact, and submitted offer state |

### Failing Direct Questions

| Question | Scope | Score | Why | Required fix |
| --- | --- | ---: | --- | --- |
| Does the whole experience feel like a real production community app, not merely an implemented workflow harness? | llm-vision-holistic | 35 |  | Replace harness/checklist cards with domain-native product views: plant offer details, photos, variety, pickup/contact preferences, requester/member context, RSVP attendee state, event schedule/location/capacity, and production action flows. |
| Is the UI modern, easy to use, easy to navigate, and visually appealing for the target persona? | llm-vision-holistic | 48 |  | Introduce clearer information architecture, less repetitive card stacking, stronger domain-specific content, better action hierarchy, and ensure floating controls do not obscure list content. |

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
- Screen row `b25-v4-row-001-garden-event-rsvp-0` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-001-garden-event-rsvp-0` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-001-garden-event-rsvp-0` names visible UI elements, visible text, persona `member`, workflow `garden-event-rsvp`, and the exact product UX issue.
- Primary surface for `garden-event-rsvp` is documented as `event detail with schedule, location, capacity/status, RSVP action, and result state` or another explicit domain-native surface.
- After-screenshot visible text proves every required semantic surface group for `garden-event-rsvp`.
- Fresh screenshot path/hash/timestamp/app commit SHA are recorded after the fix.
- Screen row `b25-v4-row-002-garden-event-rsvp-1` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-002-garden-event-rsvp-1` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-002-garden-event-rsvp-1` names visible UI elements, visible text, persona `member`, workflow `garden-event-rsvp`, and the exact product UX issue.
- Screen row `b25-v4-row-004-plant-exchange-submission-0` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-004-plant-exchange-submission-0` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-004-plant-exchange-submission-0` names visible UI elements, visible text, persona `member`, workflow `plant-exchange-submission`, and the exact product UX issue.
- Primary surface for `plant-exchange-submission` is documented as `plant exchange offer form and member marketplace surface with plant details, pickup timing, owner contact, and submitted offer state` or another explicit domain-native surface.
- After-screenshot visible text proves every required semantic surface group for `plant-exchange-submission`.
- Screen row `b25-v4-row-005-plant-exchange-submission-1` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-005-plant-exchange-submission-1` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-005-plant-exchange-submission-1` names visible UI elements, visible text, persona `member`, workflow `plant-exchange-submission`, and the exact product UX issue.

### Affected Evidence
- `independent-production-ux-review.json holisticQuestionAnswers`
- `independent-production-ux-review.md holistic review summary`
- `product-ux-screen-review-matrix.md relevant screen rows`
- `production-ux-criteria-scorecard.json/.md`

### Evidence To Collect
- Fresh holistic screenshots for primary homes, navigation, representative detail surfaces, and representative completion/result states.
- `holisticQuestionAnswers` with visible evidence, score, pass/fail answer, and specific rationale.
- `llmVisionReview` imported from a fresh LLM vision UX judge run against the after screenshots.
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
