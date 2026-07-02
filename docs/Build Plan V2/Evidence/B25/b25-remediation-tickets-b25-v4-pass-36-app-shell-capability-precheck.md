# Remediation Tickets

| Field | Value |
| --- | --- |
| Tool | `production-ux-judge` |
| Status | `fail` |
| Open tickets | 3 |

## B25-RT-001-b25-c01-no-blocker-major

| Field | Value |
| --- | --- |
| Severity | major |
| Priority | P1 |
| Status | open |
| Review run | `b25-v4-pass-36-app-shell-capability-precheck` |
| Source criterion | `b25-c01-no-blocker-major` |
| Source findings | LLM-B25-APP-SHELL-001, LLM-B25-APP-SHELL-002, LLM-B25-APP-SHELL-003, LLM-B25-APP-SHELL-004 |
| Title | No unresolved blocker or major findings |
| Direct question | Are there zero unresolved blocker or major findings in the current production UX evidence? |
| Why it failed | Unresolved blocker/major counts are blocker=0 major=4. |
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
| Roster/list with protected details | Material Design 3 / design-system | https://m3.material.io/components/data-tables/overview<br>Also: https://m3.material.io/components/lists/overview | Copy a roster with member names, roles, status, role-filtered fields, and clear protected-data redaction. |
| Reservation detail and availability flow | Material cards/forms / pattern | https://m3.material.io/components/date-pickers/overview<br>Also: https://m3.material.io/components/cards/overview | Copy an availability/reservation flow with facility details, date/time, capacity/rules, payment/status when needed, and confirmation. |

### Reference Research Queries
- production mobile UX review screenshot critique examples
- open source Flutter mobile app UX patterns GitHub
- open source Flutter event-rsvp mobile UI example GitHub
- event detail with schedule, location, capacity/status, RSVP action, and result state mobile UX pattern
- Material Design event detail with schedule, location, capacity/status, RSVP action, and result state mobile pattern
- open source Flutter roster-list mobile UI example GitHub
- team roster/schedule surface with role-filtered member details and protected-data treatment mobile UX pattern
- Material Design team roster/schedule surface with role-filtered member details and protected-data treatment mobile pattern
- open source Flutter facility-reservation mobile UI example GitHub
- facility detail/reservation flow with availability, payment/status, and confirmation mobile UX pattern
- Material Design facility detail/reservation flow with availability, payment/status, and confirmation mobile pattern

### Implementation Blocked By
- Open blocker/major B25 tickets remain.
- The scorecard cannot close until those tickets rerun clean.

### Product Spec Repair Work Items

Showing 3 of 3 work items. Full detail is in the JSON artifact.

| Work item | Stage | Community | Workflow | Persona | Screens | Coverage | Target surface | Blocked until |
| --- | --- | --- | --- | --- | ---: | ---: | --- | --- |
| `b25-wi-product-spec-cedar-commons-hoa` | `product-spec-update` | Cedar Commons HOA | `community-product-experience` | product-experience-steward | 21 | 0 | review-ready community product experience spec | productDocCoverage status is pass |
| `b25-wi-product-spec-garden-club` | `product-spec-update` | Garden Club | `community-product-experience` | product-experience-steward | 9 | 0 | review-ready community product experience spec | productDocCoverage status is pass |
| `b25-wi-product-spec-riverside-youth-soccer` | `product-spec-update` | Riverside Youth Soccer | `community-product-experience` | product-experience-steward | 21 | 0 | review-ready community product experience spec | productDocCoverage status is pass |

### Affected Product Experience Docs

| Product doc | Status | Community | Path | Missing sections | Required fix |
| --- | --- | --- | --- | --- | --- |
| `product-doc-cedar-commons-hoa` | `pass` | Cedar Commons HOA | `docs/Product Docs V2/Community Examples/cedar-commons-hoa-product-experience.md` |  | Use this product experience doc as the source of truth for B25 screenshot review. |
| `product-doc-garden-club` | `pass` | Garden Club | `docs/Product Docs V2/Community Examples/garden-club-product-experience.md` |  | Use this product experience doc as the source of truth for B25 screenshot review. |
| `product-doc-riverside-youth-soccer` | `pass` | Riverside Youth Soccer | `docs/Product Docs V2/Community Examples/riverside-youth-soccer-product-experience.md` |  | Use this product experience doc as the source of truth for B25 screenshot review. |

### Affected Screen Rows

Showing 4 of 4 affected screen rows. Full detail is in the JSON ticket.

| Screen row | Community | Workflow | Persona | State | Screenshot | Hash | Visible text | Current surface | Exact UX failure | Target surface |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `b25-v4-row-001-garden-event-rsvp-0` | Garden Club | `garden-event-rsvp` | member | B13_ext_garden_club_garden-event-rsvp_start | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B13/screenshots/B13_ext_garden_club_garden-event-rsvp_start.png` | `7cbf124dd4448...` | Spring Planting Workshop \| Hands-on bed prep, seedling swap, and seasonal planning with Garden Club members. \| Sat, Apr 18 \| 10:00 AM \| Riverside Greenhouse \| 18 of 24 spots \| Your RSVP \| Choose Going, Maybe, or Not going after checking the schedule, location, host, and capaci... | domain-native-reviewed / domain-native | LLM vision critique: Fresh pass-35 screenshot review of B13_ext_garden_club_garden-event-rsvp_start for Garden Club, workflow garden-event-rsvp, persona member: the visible UI presents a event detail with schedule, location, capacity/status, RSVP action, and result state with domain content instead of a generic workflow checklist. Visible text includes: Spring Planting Workshop \| Hands-on bed prep, seedling swap, and seasonal planning with Garden Club members. \| Sat, Apr 18 \| 10:00 AM \| Riverside Greenhouse \| 18 of 24 spots \| Your RSVP \| Choose Going, Maybe, or Not going after checking the schedule, location.... Layout review finds no blocking overlap, modal checklist, stale evidence, or repeated-card shell issue in the current screenshot. LLM required fix: None for this pass; continue tracking normal polish outside blocker/major B25 gates. | event detail with schedule, location, capacity/status, RSVP action, and result state |
| `b25-v4-row-002-garden-event-rsvp-1` | Garden Club | `garden-event-rsvp` | member | B13_ext_garden_club_garden-event-rsvp_action | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B13/screenshots/B13_ext_garden_club_garden-event-rsvp_action.png` | `eb733e502da3c...` | Spring Planting Workshop \| Saturday, Apr 18 at 10:00 AM - Riverside Greenhouse \| Join the club for bed prep, seedling setup, and a shared planning session before the spring exchange opens. \| Choose your response \| Your RSVP updates the attendee count and leaves a reminder in y... | domain-native-reviewed / domain-native | LLM vision critique: Fresh pass-35 screenshot review of B13_ext_garden_club_garden-event-rsvp_action for Garden Club, workflow garden-event-rsvp, persona member: the visible UI presents a event detail with schedule, location, capacity/status, RSVP action, and result state with domain content instead of a generic workflow checklist. Visible text includes: Spring Planting Workshop \| Saturday, Apr 18 at 10:00 AM - Riverside Greenhouse \| Join the club for bed prep, seedling setup, and a shared planning session before the spring exchange opens. \| Choose your response \| Your RSVP updates the attendee count and leav.... Layout review finds no blocking overlap, modal checklist, stale evidence, or repeated-card shell issue in the current screenshot. LLM required fix: None for this pass; continue tracking normal polish outside blocker/major B25 gates. | event detail with schedule, location, capacity/status, RSVP action, and result state |
| `b25-v4-row-016-soccer-team-roster-0` | Riverside Youth Soccer | `soccer-team-roster` | coach | B14_ext_youth_soccer_soccer-team-roster_start | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_youth_soccer_soccer-team-roster_start.png` | `e7424808b826b...` | U10 Falcons roster \| Open player names, guardian visibility, protected minor fields, and coach notes without exposing sensitive details. \| Roster and visibility \| Featured player \| Leo Rivera, jersey 14, guardian Mia Rivera, waiver due before Saturday. \| Protected fields \| Bir... | domain-native-reviewed / domain-native | LLM vision critique: Fresh pass-35 screenshot review of B14_ext_youth_soccer_soccer-team-roster_start for Riverside Youth Soccer, workflow soccer-team-roster, persona coach: the visible UI presents a team roster/schedule surface with role-filtered member details and protected-data treatment with domain content instead of a generic workflow checklist. Visible text includes: U10 Falcons roster \| Open player names, guardian visibility, protected minor fields, and coach notes without exposing sensitive details. \| Roster and visibility \| Featured player \| Leo Rivera, jersey 14, guardian Mia Rivera, waiver due before Saturday. \| Prot.... Layout review finds no blocking overlap, modal checklist, stale evidence, or repeated-card shell issue in the current screenshot. LLM required fix: None for this pass; continue tracking normal polish outside blocker/major B25 gates. | team roster/schedule surface with role-filtered member details and protected-data treatment |
| `b25-v4-row-024-hoa-facility-reservation-2` | Cedar Commons HOA | `hoa-facility-reservation` | member | B14_ext_hoa_hoa-facility-reservation_complete | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_hoa_hoa-facility-reservation_complete.png` | `db216dec83e61...` | Clubhouse Room A reservation \| The homeowner record now shows owner, amount or decision, status history, and member next steps. \| Event details \| Property \| Lot 42, homeowner Avery Brooks, Cedar Commons HOA; sender is the HOA board. \| Record \| Community Rules, Room A reservati... | domain-native-reviewed / domain-native | LLM vision critique: Fresh pass-35 screenshot review of B14_ext_hoa_hoa-facility-reservation_complete for Cedar Commons HOA, workflow hoa-facility-reservation, persona member: the visible UI presents a facility detail/reservation flow with availability, payment/status, and confirmation with domain content instead of a generic workflow checklist. Visible text includes: Clubhouse Room A reservation \| The homeowner record now shows owner, amount or decision, status history, and member next steps. \| Event details \| Property \| Lot 42, homeowner Avery Brooks, Cedar Commons HOA; sender is the HOA board. \| Record \| Community Rules.... Layout review finds no blocking overlap, modal checklist, stale evidence, or repeated-card shell issue in the current screenshot. LLM required fix: None for this pass; continue tracking normal polish outside blocker/major B25 gates. | facility detail/reservation flow with availability, payment/status, and confirmation |

### Likely Files / Widgets
- `app/apps/loom_communities_demo/lib/main.dart`
- `app/apps/loom_communities_demo/test/b21_b25_production_ux_test.dart`
- `docs/Build Plan V2/Evidence/B25/production-ux-blueprint.md`
- `docs/Build Plan V2/Evidence/B25/independent-production-ux-review.json`
- `docs/Build Plan V2/Evidence/B25/product-ux-screen-review-matrix.md`
- `docs/Build Plan V2/Evidence/B25/product-ux-remediation-loop.md`
- `docs/Build Plan V2/Build Tracker.md`
- `docs/Product Docs V2/Community Examples/cedar-commons-hoa-product-experience.md`
- `docs/Product Docs V2/Community Examples/garden-club-product-experience.md`
- `docs/Product Docs V2/Community Examples/riverside-youth-soccer-product-experience.md`
- `app/apps/loom_communities_demo/integration_test/workflow_ui_evidence_test.dart`
- `app/apps/loom_communities_demo/test/workflow_ui_test_harness.dart`

### Concrete Acceptance Criteria
- Unresolved blocker and major finding counts are both zero.
- `production_ux_judge.dart` has no blocking failure for this criterion.
- `b25_iteration_scorecard.dart` records the ticket as resolved or no longer blocking.
- Screenshots are refreshed and hashes/timestamps/app commit SHA match the reviewed app version.
- `docs/Product Docs V2/Community Examples/cedar-commons-hoa-product-experience.md` exists, has all ten B25 community product experience sections, contains no placeholders, and maps workflows to domain-native surfaces.
- `docs/Product Docs V2/Community Examples/garden-club-product-experience.md` exists, has all ten B25 community product experience sections, contains no placeholders, and maps workflows to domain-native surfaces.
- `docs/Product Docs V2/Community Examples/riverside-youth-soccer-product-experience.md` exists, has all ten B25 community product experience sections, contains no placeholders, and maps workflows to domain-native surfaces.
- Screen row `b25-v4-row-001-garden-event-rsvp-0` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-001-garden-event-rsvp-0` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-001-garden-event-rsvp-0` names visible UI elements, visible text, persona `member`, workflow `garden-event-rsvp`, and the exact product UX issue.
- Primary surface for `garden-event-rsvp` is documented as `event detail with schedule, location, capacity/status, RSVP action, and result state` or another explicit domain-native surface.
- After-screenshot visible text proves every required semantic surface group for `garden-event-rsvp`.
- Fresh screenshot path/hash/timestamp/app commit SHA are recorded after the fix.
- Screen row `b25-v4-row-002-garden-event-rsvp-1` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-002-garden-event-rsvp-1` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-002-garden-event-rsvp-1` names visible UI elements, visible text, persona `member`, workflow `garden-event-rsvp`, and the exact product UX issue.
- Screen row `b25-v4-row-016-soccer-team-roster-0` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-016-soccer-team-roster-0` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-016-soccer-team-roster-0` names visible UI elements, visible text, persona `coach`, workflow `soccer-team-roster`, and the exact product UX issue.
- Primary surface for `soccer-team-roster` is documented as `team roster/schedule surface with role-filtered member details and protected-data treatment` or another explicit domain-native surface.
- After-screenshot visible text proves every required semantic surface group for `soccer-team-roster`.
- Screen row `b25-v4-row-024-hoa-facility-reservation-2` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-024-hoa-facility-reservation-2` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-024-hoa-facility-reservation-2` names visible UI elements, visible text, persona `member`, workflow `hoa-facility-reservation`, and the exact product UX issue.
- Primary surface for `hoa-facility-reservation` is documented as `facility detail/reservation flow with availability, payment/status, and confirmation` or another explicit domain-native surface.
- After-screenshot visible text proves every required semantic surface group for `hoa-facility-reservation`.

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
- `dart run packages/tooling/loom_ux_judges/bin/b25_capture_workflow_screenshots.dart --mode full-b25 --device emulator-5554 --evidence-root ../docs/Build\ Plan\ V2/Evidence`
- `dart run packages/tooling/loom_ux_judges/bin/b25_capture_coverage_gate.dart --evidence-root ../docs/Build\ Plan\ V2/Evidence --output ../docs/Build\ Plan\ V2/Evidence/B25/b25-capture-coverage-report.json`
- `dart run packages/tooling/loom_ux_judges/bin/b25_evidence_collector.dart --evidence-root ../docs/Build\ Plan\ V2/Evidence --repo-root .. --run-id <next-run-id> --prior-review ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --output ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.md --matrix-output ../docs/Build\ Plan\ V2/Evidence/B25/product-ux-screen-review-matrix.md`
- `dart run packages/tooling/loom_ux_judges/bin/b25_workflow_persona_coverage_collector.dart --input ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --output ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/workflow-persona-coverage-matrix.md`
- `dart run packages/tooling/loom_ux_judges/bin/b25_independent_ux_judge.dart --input ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --output ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.md --matrix-output ../docs/Build\ Plan\ V2/Evidence/B25/product-ux-screen-review-matrix.md`
- `dart run packages/tooling/loom_ux_judges/bin/production_ux_judge.dart --input ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --base .. --output ../docs/Build\ Plan\ V2/Evidence/B25/production-ux-criteria-scorecard.json --markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/production-ux-criteria-scorecard.md --tickets-output ../docs/Build\ Plan\ V2/Evidence/B25/b25-remediation-tickets-<next-run-id>.json --tickets-markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/b25-remediation-tickets-<next-run-id>.md`
- `dart run packages/tooling/loom_ux_judges/bin/b25_iteration_scorecard.dart --review ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --judge ../docs/Build\ Plan\ V2/Evidence/B25/production-ux-criteria-scorecard.json --previous ../docs/Build\ Plan\ V2/Evidence/B25/b25-iteration-scorecard-latest.json --output ../docs/Build\ Plan\ V2/Evidence/B25/b25-iteration-scorecard-latest.json --markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/b25-iteration-scorecard-latest.md`

## B25-RT-002-b25-c14-llm-vision-ux-review

| Field | Value |
| --- | --- |
| Severity | major |
| Priority | P1 |
| Status | open |
| Review run | `b25-v4-pass-36-app-shell-capability-precheck` |
| Source criterion | `b25-c14-llm-vision-ux-review` |
| Source findings | LLM-B25-APP-SHELL-001, LLM-B25-APP-SHELL-002, LLM-B25-APP-SHELL-003, LLM-B25-APP-SHELL-004 |
| Title | LLM vision UX judge has inspected screenshots semantically |
| Direct question | Has a fresh LLM vision UX Judge inspected the actual screenshots as product UI, answered direct UX questions from visible evidence, and found no blocker or major product-quality issues? |
| Why it failed | The LLM vision UX review is not fresh for this B25 pass: currentReviewRunId must match the current B25 run (b25-v4-pass-36-app-shell-capability-precheck), found `b25-v4-pass-35`. |
| Required outcome | Run the B25 LLM Vision UX Judge Agent on the screenshot evidence, import its structured review, fix all blocker/major findings, and rerun B25. |
| Remediation mode | `product-spec-update-before-ui-remediation` |
| Worker readiness | ready for product documentation update; UI remediation is blocked until the community product experience spec is complete |
| First required step | Complete productDocRepairWorkItems so each affected community has a review-ready Product Docs V2 experience spec with domain-native surfaces and workflow-to-surface mapping. |

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
| Roster/list with protected details | Material Design 3 / design-system | https://m3.material.io/components/data-tables/overview<br>Also: https://m3.material.io/components/lists/overview | Copy a roster with member names, roles, status, role-filtered fields, and clear protected-data redaction. |
| Reservation detail and availability flow | Material cards/forms / pattern | https://m3.material.io/components/date-pickers/overview<br>Also: https://m3.material.io/components/cards/overview | Copy an availability/reservation flow with facility details, date/time, capacity/rules, payment/status when needed, and confirmation. |

### Reference Research Queries
- production mobile UX review screenshot critique examples
- open source Flutter mobile app UX patterns GitHub
- open source Flutter event-rsvp mobile UI example GitHub
- event detail with schedule, location, capacity/status, RSVP action, and result state mobile UX pattern
- Material Design event detail with schedule, location, capacity/status, RSVP action, and result state mobile pattern
- open source Flutter roster-list mobile UI example GitHub
- team roster/schedule surface with role-filtered member details and protected-data treatment mobile UX pattern
- Material Design team roster/schedule surface with role-filtered member details and protected-data treatment mobile pattern
- open source Flutter facility-reservation mobile UI example GitHub
- facility detail/reservation flow with availability, payment/status, and confirmation mobile UX pattern
- Material Design facility detail/reservation flow with availability, payment/status, and confirmation mobile pattern

### Implementation Blocked By
- The judge cannot verify production-grade UX without a community-specific product experience spec.
- UI workers need the spec to know the rich product surface they are supposed to build.

### Product Spec Repair Work Items

Showing 3 of 3 work items. Full detail is in the JSON artifact.

| Work item | Stage | Community | Workflow | Persona | Screens | Coverage | Target surface | Blocked until |
| --- | --- | --- | --- | --- | ---: | ---: | --- | --- |
| `b25-wi-product-spec-cedar-commons-hoa` | `product-spec-update` | Cedar Commons HOA | `community-product-experience` | product-experience-steward | 21 | 0 | review-ready community product experience spec | productDocCoverage status is pass |
| `b25-wi-product-spec-garden-club` | `product-spec-update` | Garden Club | `community-product-experience` | product-experience-steward | 9 | 0 | review-ready community product experience spec | productDocCoverage status is pass |
| `b25-wi-product-spec-riverside-youth-soccer` | `product-spec-update` | Riverside Youth Soccer | `community-product-experience` | product-experience-steward | 21 | 0 | review-ready community product experience spec | productDocCoverage status is pass |

### Affected Product Experience Docs

| Product doc | Status | Community | Path | Missing sections | Required fix |
| --- | --- | --- | --- | --- | --- |
| `product-doc-cedar-commons-hoa` | `pass` | Cedar Commons HOA | `docs/Product Docs V2/Community Examples/cedar-commons-hoa-product-experience.md` |  | Use this product experience doc as the source of truth for B25 screenshot review. |
| `product-doc-garden-club` | `pass` | Garden Club | `docs/Product Docs V2/Community Examples/garden-club-product-experience.md` |  | Use this product experience doc as the source of truth for B25 screenshot review. |
| `product-doc-riverside-youth-soccer` | `pass` | Riverside Youth Soccer | `docs/Product Docs V2/Community Examples/riverside-youth-soccer-product-experience.md` |  | Use this product experience doc as the source of truth for B25 screenshot review. |

### Affected Screen Rows

Showing 4 of 4 affected screen rows. Full detail is in the JSON ticket.

| Screen row | Community | Workflow | Persona | State | Screenshot | Hash | Visible text | Current surface | Exact UX failure | Target surface |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `b25-v4-row-001-garden-event-rsvp-0` | Garden Club | `garden-event-rsvp` | member | B13_ext_garden_club_garden-event-rsvp_start | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B13/screenshots/B13_ext_garden_club_garden-event-rsvp_start.png` | `7cbf124dd4448...` | Spring Planting Workshop \| Hands-on bed prep, seedling swap, and seasonal planning with Garden Club members. \| Sat, Apr 18 \| 10:00 AM \| Riverside Greenhouse \| 18 of 24 spots \| Your RSVP \| Choose Going, Maybe, or Not going after checking the schedule, location, host, and capaci... | domain-native-reviewed / domain-native | LLM vision critique: Fresh pass-35 screenshot review of B13_ext_garden_club_garden-event-rsvp_start for Garden Club, workflow garden-event-rsvp, persona member: the visible UI presents a event detail with schedule, location, capacity/status, RSVP action, and result state with domain content instead of a generic workflow checklist. Visible text includes: Spring Planting Workshop \| Hands-on bed prep, seedling swap, and seasonal planning with Garden Club members. \| Sat, Apr 18 \| 10:00 AM \| Riverside Greenhouse \| 18 of 24 spots \| Your RSVP \| Choose Going, Maybe, or Not going after checking the schedule, location.... Layout review finds no blocking overlap, modal checklist, stale evidence, or repeated-card shell issue in the current screenshot. LLM required fix: None for this pass; continue tracking normal polish outside blocker/major B25 gates. | event detail with schedule, location, capacity/status, RSVP action, and result state |
| `b25-v4-row-002-garden-event-rsvp-1` | Garden Club | `garden-event-rsvp` | member | B13_ext_garden_club_garden-event-rsvp_action | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B13/screenshots/B13_ext_garden_club_garden-event-rsvp_action.png` | `eb733e502da3c...` | Spring Planting Workshop \| Saturday, Apr 18 at 10:00 AM - Riverside Greenhouse \| Join the club for bed prep, seedling setup, and a shared planning session before the spring exchange opens. \| Choose your response \| Your RSVP updates the attendee count and leaves a reminder in y... | domain-native-reviewed / domain-native | LLM vision critique: Fresh pass-35 screenshot review of B13_ext_garden_club_garden-event-rsvp_action for Garden Club, workflow garden-event-rsvp, persona member: the visible UI presents a event detail with schedule, location, capacity/status, RSVP action, and result state with domain content instead of a generic workflow checklist. Visible text includes: Spring Planting Workshop \| Saturday, Apr 18 at 10:00 AM - Riverside Greenhouse \| Join the club for bed prep, seedling setup, and a shared planning session before the spring exchange opens. \| Choose your response \| Your RSVP updates the attendee count and leav.... Layout review finds no blocking overlap, modal checklist, stale evidence, or repeated-card shell issue in the current screenshot. LLM required fix: None for this pass; continue tracking normal polish outside blocker/major B25 gates. | event detail with schedule, location, capacity/status, RSVP action, and result state |
| `b25-v4-row-016-soccer-team-roster-0` | Riverside Youth Soccer | `soccer-team-roster` | coach | B14_ext_youth_soccer_soccer-team-roster_start | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_youth_soccer_soccer-team-roster_start.png` | `e7424808b826b...` | U10 Falcons roster \| Open player names, guardian visibility, protected minor fields, and coach notes without exposing sensitive details. \| Roster and visibility \| Featured player \| Leo Rivera, jersey 14, guardian Mia Rivera, waiver due before Saturday. \| Protected fields \| Bir... | domain-native-reviewed / domain-native | LLM vision critique: Fresh pass-35 screenshot review of B14_ext_youth_soccer_soccer-team-roster_start for Riverside Youth Soccer, workflow soccer-team-roster, persona coach: the visible UI presents a team roster/schedule surface with role-filtered member details and protected-data treatment with domain content instead of a generic workflow checklist. Visible text includes: U10 Falcons roster \| Open player names, guardian visibility, protected minor fields, and coach notes without exposing sensitive details. \| Roster and visibility \| Featured player \| Leo Rivera, jersey 14, guardian Mia Rivera, waiver due before Saturday. \| Prot.... Layout review finds no blocking overlap, modal checklist, stale evidence, or repeated-card shell issue in the current screenshot. LLM required fix: None for this pass; continue tracking normal polish outside blocker/major B25 gates. | team roster/schedule surface with role-filtered member details and protected-data treatment |
| `b25-v4-row-024-hoa-facility-reservation-2` | Cedar Commons HOA | `hoa-facility-reservation` | member | B14_ext_hoa_hoa-facility-reservation_complete | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_hoa_hoa-facility-reservation_complete.png` | `db216dec83e61...` | Clubhouse Room A reservation \| The homeowner record now shows owner, amount or decision, status history, and member next steps. \| Event details \| Property \| Lot 42, homeowner Avery Brooks, Cedar Commons HOA; sender is the HOA board. \| Record \| Community Rules, Room A reservati... | domain-native-reviewed / domain-native | LLM vision critique: Fresh pass-35 screenshot review of B14_ext_hoa_hoa-facility-reservation_complete for Cedar Commons HOA, workflow hoa-facility-reservation, persona member: the visible UI presents a facility detail/reservation flow with availability, payment/status, and confirmation with domain content instead of a generic workflow checklist. Visible text includes: Clubhouse Room A reservation \| The homeowner record now shows owner, amount or decision, status history, and member next steps. \| Event details \| Property \| Lot 42, homeowner Avery Brooks, Cedar Commons HOA; sender is the HOA board. \| Record \| Community Rules.... Layout review finds no blocking overlap, modal checklist, stale evidence, or repeated-card shell issue in the current screenshot. LLM required fix: None for this pass; continue tracking normal polish outside blocker/major B25 gates. | facility detail/reservation flow with availability, payment/status, and confirmation |

### Likely Files / Widgets
- `app/apps/loom_communities_demo/lib/main.dart`
- `app/apps/loom_communities_demo/test/b21_b25_production_ux_test.dart`
- `docs/Build Plan V2/Evidence/B25/production-ux-blueprint.md`
- `docs/Build Plan V2/Evidence/B25/independent-production-ux-review.json`
- `docs/Build Plan V2/Evidence/B25/product-ux-screen-review-matrix.md`
- `docs/Product Docs V2/Community Examples/cedar-commons-hoa-product-experience.md`
- `docs/Product Docs V2/Community Examples/garden-club-product-experience.md`
- `docs/Product Docs V2/Community Examples/riverside-youth-soccer-product-experience.md`
- `app/apps/loom_communities_demo/integration_test/workflow_ui_evidence_test.dart`
- `app/apps/loom_communities_demo/test/workflow_ui_test_harness.dart`

### Concrete Acceptance Criteria
- `production_ux_judge.dart` has no blocking failure for this criterion.
- `b25_iteration_scorecard.dart` records the ticket as resolved or no longer blocking.
- Screenshots are refreshed and hashes/timestamps/app commit SHA match the reviewed app version.
- `docs/Product Docs V2/Community Examples/cedar-commons-hoa-product-experience.md` exists, has all ten B25 community product experience sections, contains no placeholders, and maps workflows to domain-native surfaces.
- `docs/Product Docs V2/Community Examples/garden-club-product-experience.md` exists, has all ten B25 community product experience sections, contains no placeholders, and maps workflows to domain-native surfaces.
- `docs/Product Docs V2/Community Examples/riverside-youth-soccer-product-experience.md` exists, has all ten B25 community product experience sections, contains no placeholders, and maps workflows to domain-native surfaces.
- Screen row `b25-v4-row-001-garden-event-rsvp-0` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-001-garden-event-rsvp-0` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-001-garden-event-rsvp-0` names visible UI elements, visible text, persona `member`, workflow `garden-event-rsvp`, and the exact product UX issue.
- Primary surface for `garden-event-rsvp` is documented as `event detail with schedule, location, capacity/status, RSVP action, and result state` or another explicit domain-native surface.
- After-screenshot visible text proves every required semantic surface group for `garden-event-rsvp`.
- Fresh screenshot path/hash/timestamp/app commit SHA are recorded after the fix.
- Screen row `b25-v4-row-002-garden-event-rsvp-1` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-002-garden-event-rsvp-1` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-002-garden-event-rsvp-1` names visible UI elements, visible text, persona `member`, workflow `garden-event-rsvp`, and the exact product UX issue.
- Screen row `b25-v4-row-016-soccer-team-roster-0` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-016-soccer-team-roster-0` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-016-soccer-team-roster-0` names visible UI elements, visible text, persona `coach`, workflow `soccer-team-roster`, and the exact product UX issue.
- Primary surface for `soccer-team-roster` is documented as `team roster/schedule surface with role-filtered member details and protected-data treatment` or another explicit domain-native surface.
- After-screenshot visible text proves every required semantic surface group for `soccer-team-roster`.
- Screen row `b25-v4-row-024-hoa-facility-reservation-2` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-024-hoa-facility-reservation-2` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-024-hoa-facility-reservation-2` names visible UI elements, visible text, persona `member`, workflow `hoa-facility-reservation`, and the exact product UX issue.
- Primary surface for `hoa-facility-reservation` is documented as `facility detail/reservation flow with availability, payment/status, and confirmation` or another explicit domain-native surface.
- After-screenshot visible text proves every required semantic surface group for `hoa-facility-reservation`.

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
- `dart run packages/tooling/loom_ux_judges/bin/production_ux_judge.dart --input ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --base .. --output ../docs/Build\ Plan\ V2/Evidence/B25/production-ux-criteria-scorecard.json --markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/production-ux-criteria-scorecard.md --tickets-output ../docs/Build\ Plan\ V2/Evidence/B25/b25-remediation-tickets-<next-run-id>.json --tickets-markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/b25-remediation-tickets-<next-run-id>.md`
- `dart run packages/tooling/loom_ux_judges/bin/b25_iteration_scorecard.dart --review ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --judge ../docs/Build\ Plan\ V2/Evidence/B25/production-ux-criteria-scorecard.json --previous ../docs/Build\ Plan\ V2/Evidence/B25/b25-iteration-scorecard-latest.json --output ../docs/Build\ Plan\ V2/Evidence/B25/b25-iteration-scorecard-latest.json --markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/b25-iteration-scorecard-latest.md`

## B25-RT-003-b25-c16-app-shell-capability-utilization

| Field | Value |
| --- | --- |
| Severity | major |
| Priority | P1 |
| Status | open |
| Review run | `b25-v4-pass-36-app-shell-capability-precheck` |
| Source criterion | `b25-c16-app-shell-capability-utilization` |
| Source findings | LLM-B25-APP-SHELL-001, LLM-B25-APP-SHELL-002, LLM-B25-APP-SHELL-003, LLM-B25-APP-SHELL-004 |
| Title | App Shell capabilities are used where documented |
| Direct question | Do current screenshots prove persona tabs, pinned surfaces, minimized/medium/expanded states, tap-to-expand behavior, community-list presentation states, renderer selection, and theme/customization tokens are used correctly where Product Docs or App Shell component docs require them? |
| Why it failed | App Shell capability utilization review failed. missingCapabilities=screenshot-proven minimized/medium/expanded state transitions, screenshot-proven pinned surfaces, main community-list card presentation states, explicit renderer-selection proof failingCommunities=Garden Club/member (pinnedSurfacesPass,presentationStatesPass,mainCommunityCardStatesPass); Cedar Commons HOA/member (pinnedSurfacesPass,presentationStatesPass,mainCommunityCardStatesPass); Riverside Youth Soccer/coach (pinnedSurfacesPass,presentationStatesPass,mainCommunityCardStatesPass,rendererSelectionPass) blockingFindings=LLM-B25-APP-SHELL-001, LLM-B25-APP-SHELL-002, LLM-B25-APP-SHELL-003, LLM-B25-APP-SHELL-004. |
| Required outcome | Update Product Docs and UI so app shell tabs, pins, presentation states, tap-to-expand behavior, community-list states, renderer selection, and theme/typography/density customization are screenshot-proven; rerun B25 and regenerate tickets. |
| Remediation mode | `product-spec-update-before-ui-remediation` |
| Worker readiness | ready for product documentation update; UI remediation is blocked until the community product experience spec is complete |
| First required step | Complete productDocRepairWorkItems so each affected community has a review-ready Product Docs V2 experience spec with domain-native surfaces and workflow-to-surface mapping. |

### Problem Statement

The B25 production UX criterion failed and requires a concrete remediation plan.

### Root Cause Hypothesis

The evidence does not yet satisfy the B25 production UX standard.

### Target Experience

The next B25 pass should show zero unresolved blocker/major findings and a scorecard that can close the phase.

### UX Principles
- Resolve blocking UX evidence before closing B25

### Concrete Improvements
- Do not close the ticket from source-code intent alone; require after-screenshots proving the App Shell capability is actually visible and usable.
- Do not treat bottom tabs, pins, or minimized cards as present unless the relevant persona/workflow screenshot shows them.
- Do not accept a generic card list when Product Docs or the App Shell component doc require tabs, pinned surfaces, presentation states, renderer selection, or theme/customization proof.

### Implementation Guidance
- Inspect `apps/loom_communities_demo/lib/main.dart` for `CommunityAppShellCustomizationSpec`, persona tab specs, pinned surface specs, presentation-state routing, renderer selection, and theme/typography/density tokens.
- Update the community product experience doc Section 3.1 when the intended tab/pin/presentation/customization model is missing or vague.
- Implement the missing App Shell capability in the central shell model, not as a one-off workflow hack.
- Recapture screenshots proving Home and Messages/Communication tabs, custom persona tabs, pinned surfaces, minimized/medium/expanded states, tap-to-expand, community-list states, renderer selection, and theme/customization tokens where required.

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
| Event detail and RSVP flow | Material cards/lists/buttons / pattern | https://m3.material.io/components/cards/overview<br>Also: https://m3.material.io/components/buttons/overview<br>https://m3.material.io/components/chips/overview | Copy an event detail layout: title, date/time, location, host, capacity/status chip, attendee context, RSVP action, and confirmation state. |
| Roster/list with protected details | Material Design 3 / design-system | https://m3.material.io/components/data-tables/overview<br>Also: https://m3.material.io/components/lists/overview | Copy a roster with member names, roles, status, role-filtered fields, and clear protected-data redaction. |
| Reservation detail and availability flow | Material cards/forms / pattern | https://m3.material.io/components/date-pickers/overview<br>Also: https://m3.material.io/components/cards/overview | Copy an availability/reservation flow with facility details, date/time, capacity/rules, payment/status when needed, and confirmation. |

### Reference Research Queries
- production mobile UX review screenshot critique examples
- open source Flutter mobile app UX patterns GitHub
- open source Flutter event-rsvp mobile UI example GitHub
- event detail with schedule, location, capacity/status, RSVP action, and result state mobile UX pattern
- Material Design event detail with schedule, location, capacity/status, RSVP action, and result state mobile pattern
- open source Flutter roster-list mobile UI example GitHub
- team roster/schedule surface with role-filtered member details and protected-data treatment mobile UX pattern
- Material Design team roster/schedule surface with role-filtered member details and protected-data treatment mobile pattern
- open source Flutter facility-reservation mobile UI example GitHub
- facility detail/reservation flow with availability, payment/status, and confirmation mobile UX pattern
- Material Design facility detail/reservation flow with availability, payment/status, and confirmation mobile pattern

### Implementation Blocked By
- The judge cannot verify production-grade UX without a community-specific product experience spec.
- UI workers need the spec to know the rich product surface they are supposed to build.

### Product Spec Repair Work Items

Showing 3 of 3 work items. Full detail is in the JSON artifact.

| Work item | Stage | Community | Workflow | Persona | Screens | Coverage | Target surface | Blocked until |
| --- | --- | --- | --- | --- | ---: | ---: | --- | --- |
| `b25-wi-product-spec-cedar-commons-hoa` | `product-spec-update` | Cedar Commons HOA | `community-product-experience` | product-experience-steward | 21 | 0 | review-ready community product experience spec | productDocCoverage status is pass |
| `b25-wi-product-spec-garden-club` | `product-spec-update` | Garden Club | `community-product-experience` | product-experience-steward | 9 | 0 | review-ready community product experience spec | productDocCoverage status is pass |
| `b25-wi-product-spec-riverside-youth-soccer` | `product-spec-update` | Riverside Youth Soccer | `community-product-experience` | product-experience-steward | 21 | 0 | review-ready community product experience spec | productDocCoverage status is pass |

### Affected Product Experience Docs

| Product doc | Status | Community | Path | Missing sections | Required fix |
| --- | --- | --- | --- | --- | --- |
| `product-doc-cedar-commons-hoa` | `pass` | Cedar Commons HOA | `docs/Product Docs V2/Community Examples/cedar-commons-hoa-product-experience.md` |  | Use this product experience doc as the source of truth for B25 screenshot review. |
| `product-doc-garden-club` | `pass` | Garden Club | `docs/Product Docs V2/Community Examples/garden-club-product-experience.md` |  | Use this product experience doc as the source of truth for B25 screenshot review. |
| `product-doc-riverside-youth-soccer` | `pass` | Riverside Youth Soccer | `docs/Product Docs V2/Community Examples/riverside-youth-soccer-product-experience.md` |  | Use this product experience doc as the source of truth for B25 screenshot review. |

### Affected Screen Rows

Showing 4 of 4 affected screen rows. Full detail is in the JSON ticket.

| Screen row | Community | Workflow | Persona | State | Screenshot | Hash | Visible text | Current surface | Exact UX failure | Target surface |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `b25-v4-row-001-garden-event-rsvp-0` | Garden Club | `garden-event-rsvp` | member | B13_ext_garden_club_garden-event-rsvp_start | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B13/screenshots/B13_ext_garden_club_garden-event-rsvp_start.png` | `7cbf124dd4448...` | Spring Planting Workshop \| Hands-on bed prep, seedling swap, and seasonal planning with Garden Club members. \| Sat, Apr 18 \| 10:00 AM \| Riverside Greenhouse \| 18 of 24 spots \| Your RSVP \| Choose Going, Maybe, or Not going after checking the schedule, location, host, and capaci... | domain-native-reviewed / domain-native | LLM vision critique: Fresh pass-35 screenshot review of B13_ext_garden_club_garden-event-rsvp_start for Garden Club, workflow garden-event-rsvp, persona member: the visible UI presents a event detail with schedule, location, capacity/status, RSVP action, and result state with domain content instead of a generic workflow checklist. Visible text includes: Spring Planting Workshop \| Hands-on bed prep, seedling swap, and seasonal planning with Garden Club members. \| Sat, Apr 18 \| 10:00 AM \| Riverside Greenhouse \| 18 of 24 spots \| Your RSVP \| Choose Going, Maybe, or Not going after checking the schedule, location.... Layout review finds no blocking overlap, modal checklist, stale evidence, or repeated-card shell issue in the current screenshot. LLM required fix: None for this pass; continue tracking normal polish outside blocker/major B25 gates. | event detail with schedule, location, capacity/status, RSVP action, and result state |
| `b25-v4-row-002-garden-event-rsvp-1` | Garden Club | `garden-event-rsvp` | member | B13_ext_garden_club_garden-event-rsvp_action | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B13/screenshots/B13_ext_garden_club_garden-event-rsvp_action.png` | `eb733e502da3c...` | Spring Planting Workshop \| Saturday, Apr 18 at 10:00 AM - Riverside Greenhouse \| Join the club for bed prep, seedling setup, and a shared planning session before the spring exchange opens. \| Choose your response \| Your RSVP updates the attendee count and leaves a reminder in y... | domain-native-reviewed / domain-native | LLM vision critique: Fresh pass-35 screenshot review of B13_ext_garden_club_garden-event-rsvp_action for Garden Club, workflow garden-event-rsvp, persona member: the visible UI presents a event detail with schedule, location, capacity/status, RSVP action, and result state with domain content instead of a generic workflow checklist. Visible text includes: Spring Planting Workshop \| Saturday, Apr 18 at 10:00 AM - Riverside Greenhouse \| Join the club for bed prep, seedling setup, and a shared planning session before the spring exchange opens. \| Choose your response \| Your RSVP updates the attendee count and leav.... Layout review finds no blocking overlap, modal checklist, stale evidence, or repeated-card shell issue in the current screenshot. LLM required fix: None for this pass; continue tracking normal polish outside blocker/major B25 gates. | event detail with schedule, location, capacity/status, RSVP action, and result state |
| `b25-v4-row-016-soccer-team-roster-0` | Riverside Youth Soccer | `soccer-team-roster` | coach | B14_ext_youth_soccer_soccer-team-roster_start | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_youth_soccer_soccer-team-roster_start.png` | `e7424808b826b...` | U10 Falcons roster \| Open player names, guardian visibility, protected minor fields, and coach notes without exposing sensitive details. \| Roster and visibility \| Featured player \| Leo Rivera, jersey 14, guardian Mia Rivera, waiver due before Saturday. \| Protected fields \| Bir... | domain-native-reviewed / domain-native | LLM vision critique: Fresh pass-35 screenshot review of B14_ext_youth_soccer_soccer-team-roster_start for Riverside Youth Soccer, workflow soccer-team-roster, persona coach: the visible UI presents a team roster/schedule surface with role-filtered member details and protected-data treatment with domain content instead of a generic workflow checklist. Visible text includes: U10 Falcons roster \| Open player names, guardian visibility, protected minor fields, and coach notes without exposing sensitive details. \| Roster and visibility \| Featured player \| Leo Rivera, jersey 14, guardian Mia Rivera, waiver due before Saturday. \| Prot.... Layout review finds no blocking overlap, modal checklist, stale evidence, or repeated-card shell issue in the current screenshot. LLM required fix: None for this pass; continue tracking normal polish outside blocker/major B25 gates. | team roster/schedule surface with role-filtered member details and protected-data treatment |
| `b25-v4-row-024-hoa-facility-reservation-2` | Cedar Commons HOA | `hoa-facility-reservation` | member | B14_ext_hoa_hoa-facility-reservation_complete | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_hoa_hoa-facility-reservation_complete.png` | `db216dec83e61...` | Clubhouse Room A reservation \| The homeowner record now shows owner, amount or decision, status history, and member next steps. \| Event details \| Property \| Lot 42, homeowner Avery Brooks, Cedar Commons HOA; sender is the HOA board. \| Record \| Community Rules, Room A reservati... | domain-native-reviewed / domain-native | LLM vision critique: Fresh pass-35 screenshot review of B14_ext_hoa_hoa-facility-reservation_complete for Cedar Commons HOA, workflow hoa-facility-reservation, persona member: the visible UI presents a facility detail/reservation flow with availability, payment/status, and confirmation with domain content instead of a generic workflow checklist. Visible text includes: Clubhouse Room A reservation \| The homeowner record now shows owner, amount or decision, status history, and member next steps. \| Event details \| Property \| Lot 42, homeowner Avery Brooks, Cedar Commons HOA; sender is the HOA board. \| Record \| Community Rules.... Layout review finds no blocking overlap, modal checklist, stale evidence, or repeated-card shell issue in the current screenshot. LLM required fix: None for this pass; continue tracking normal polish outside blocker/major B25 gates. | facility detail/reservation flow with availability, payment/status, and confirmation |

### Likely Files / Widgets
- `app/apps/loom_communities_demo/lib/main.dart`
- `app/apps/loom_communities_demo/test/b21_b25_production_ux_test.dart`
- `docs/Build Plan V2/Evidence/B25/production-ux-blueprint.md`
- `docs/Build Plan V2/Evidence/B25/independent-production-ux-review.json`
- `docs/Build Plan V2/Evidence/B25/product-ux-screen-review-matrix.md`
- `docs/Product Docs V2/Community Examples/cedar-commons-hoa-product-experience.md`
- `docs/Product Docs V2/Community Examples/garden-club-product-experience.md`
- `docs/Product Docs V2/Community Examples/riverside-youth-soccer-product-experience.md`
- `app/apps/loom_communities_demo/integration_test/workflow_ui_evidence_test.dart`
- `app/apps/loom_communities_demo/test/workflow_ui_test_harness.dart`

### Concrete Acceptance Criteria
- `appShellCapabilityReview.status` is `pass`.
- `appShellCapabilityReview.missingCapabilities` is empty.
- Every `appShellCapabilityReview.communityResults[]` row has passing tabs, pinned surfaces, presentation states, community-list states, theme customization, and renderer-selection checks where applicable.
- After-screenshots prove the shell capability in the affected community/persona/workflow, not only source-code declarations.
- `production_ux_judge.dart` has no blocking failure for this criterion.
- `b25_iteration_scorecard.dart` records the ticket as resolved or no longer blocking.
- Screenshots are refreshed and hashes/timestamps/app commit SHA match the reviewed app version.
- `docs/Product Docs V2/Community Examples/cedar-commons-hoa-product-experience.md` exists, has all ten B25 community product experience sections, contains no placeholders, and maps workflows to domain-native surfaces.
- `docs/Product Docs V2/Community Examples/garden-club-product-experience.md` exists, has all ten B25 community product experience sections, contains no placeholders, and maps workflows to domain-native surfaces.
- `docs/Product Docs V2/Community Examples/riverside-youth-soccer-product-experience.md` exists, has all ten B25 community product experience sections, contains no placeholders, and maps workflows to domain-native surfaces.
- Screen row `b25-v4-row-001-garden-event-rsvp-0` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-001-garden-event-rsvp-0` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-001-garden-event-rsvp-0` names visible UI elements, visible text, persona `member`, workflow `garden-event-rsvp`, and the exact product UX issue.
- Primary surface for `garden-event-rsvp` is documented as `event detail with schedule, location, capacity/status, RSVP action, and result state` or another explicit domain-native surface.
- After-screenshot visible text proves every required semantic surface group for `garden-event-rsvp`.
- Fresh screenshot path/hash/timestamp/app commit SHA are recorded after the fix.
- Screen row `b25-v4-row-002-garden-event-rsvp-1` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-002-garden-event-rsvp-1` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-002-garden-event-rsvp-1` names visible UI elements, visible text, persona `member`, workflow `garden-event-rsvp`, and the exact product UX issue.
- Screen row `b25-v4-row-016-soccer-team-roster-0` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-016-soccer-team-roster-0` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-016-soccer-team-roster-0` names visible UI elements, visible text, persona `coach`, workflow `soccer-team-roster`, and the exact product UX issue.
- Primary surface for `soccer-team-roster` is documented as `team roster/schedule surface with role-filtered member details and protected-data treatment` or another explicit domain-native surface.
- After-screenshot visible text proves every required semantic surface group for `soccer-team-roster`.
- Screen row `b25-v4-row-024-hoa-facility-reservation-2` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-024-hoa-facility-reservation-2` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-024-hoa-facility-reservation-2` names visible UI elements, visible text, persona `member`, workflow `hoa-facility-reservation`, and the exact product UX issue.
- Primary surface for `hoa-facility-reservation` is documented as `facility detail/reservation flow with availability, payment/status, and confirmation` or another explicit domain-native surface.
- After-screenshot visible text proves every required semantic surface group for `hoa-facility-reservation`.

### Affected Evidence
- `independent-production-ux-review.json appShellCapabilityReview`
- `llm-product-doc-workflow-reconciliation-<run-id>.json appShellCapabilityReview`
- `docs/Product Docs V2/Community Examples/<community>-product-experience.md Section 3.1`
- `docs/Build Plan V2/Skill/components/card-surfaces/app-shell-navigation-theming.md`
- `product-ux-screen-review-matrix.md affected screen rows and screenshots`
- `production-ux-criteria-scorecard.json/.md`

### Evidence To Collect
- Updated review JSON, scorecards, screenshots, remediation log, and tracker evidence for the fixed criterion.

### Acceptance Checks
- `appShellCapabilityReview.status` is `pass`.
- `appShellCapabilityReview.missingCapabilities` is empty.
- Every `appShellCapabilityReview.communityResults[]` row has passing tabs, pinned surfaces, presentation states, community-list states, theme customization, and renderer-selection checks where applicable.
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
- `dart run packages/tooling/loom_ux_judges/bin/production_ux_judge.dart --input ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --base .. --output ../docs/Build\ Plan\ V2/Evidence/B25/production-ux-criteria-scorecard.json --markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/production-ux-criteria-scorecard.md --tickets-output ../docs/Build\ Plan\ V2/Evidence/B25/b25-remediation-tickets-<next-run-id>.json --tickets-markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/b25-remediation-tickets-<next-run-id>.md`
- `dart run packages/tooling/loom_ux_judges/bin/b25_iteration_scorecard.dart --review ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --judge ../docs/Build\ Plan\ V2/Evidence/B25/production-ux-criteria-scorecard.json --previous ../docs/Build\ Plan\ V2/Evidence/B25/b25-iteration-scorecard-latest.json --output ../docs/Build\ Plan\ V2/Evidence/B25/b25-iteration-scorecard-latest.json --markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/b25-iteration-scorecard-latest.md`
