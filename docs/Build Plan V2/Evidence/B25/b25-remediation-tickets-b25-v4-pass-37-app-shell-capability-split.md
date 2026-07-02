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
| Review run | `b25-v4-pass-37-app-shell-capability-split` |
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
| Review run | `b25-v4-pass-37-app-shell-capability-split` |
| Source criterion | `b25-c14-llm-vision-ux-review` |
| Source findings | LLM-B25-APP-SHELL-001, LLM-B25-APP-SHELL-002, LLM-B25-APP-SHELL-003, LLM-B25-APP-SHELL-004 |
| Title | LLM vision UX judge has inspected screenshots semantically |
| Direct question | Has a fresh LLM vision UX Judge inspected the actual screenshots as product UI, answered direct UX questions from visible evidence, and found no blocker or major product-quality issues? |
| Why it failed | The LLM vision UX review is not fresh for this B25 pass: currentReviewRunId must match the current B25 run (b25-v4-pass-37-app-shell-capability-split), found `b25-v4-pass-35`. |
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

## B25-RT-003-app-shell-presentation-state-gap

| Field | Value |
| --- | --- |
| Severity | major |
| Priority | P1 |
| Status | open |
| Review run | `b25-v4-pass-37-app-shell-capability-split` |
| Source criterion | `b25-c16-app-shell-capability-utilization` |
| Source findings | LLM-B25-APP-SHELL-001 |
| Title | App Shell presentation states are not screenshot-proven |
| Direct question | Do screenshots prove minimized off-focus surfaces, the medium in-focus surface, and tap-to-expand behavior for the same workflow/persona? |
| Why it failed | Existing screenshots show tabbed community screens, but they do not prove minimized off-focus, medium in-focus, and expanded/maximized states or tap-to-expand transition for the same workflow/persona surface. |
| Required outcome | Recapture and, if needed, implement the App Shell so Garden Club workflow surfaces visibly demonstrate minimized off-focus cards, a medium in-focus card, and a tap-expanded product surface for the same workflow/persona. |
| Remediation mode | `product-spec-update-before-ui-remediation` |
| Worker readiness | ready for product documentation update; UI remediation is blocked until the community product experience spec is complete |
| First required step | Complete productDocRepairWorkItems so each affected community has a review-ready Product Docs V2 experience spec with domain-native surfaces and workflow-to-surface mapping. |

### Problem Statement

Existing screenshots show tabbed community screens, but they do not prove minimized off-focus, medium in-focus, and expanded/maximized states or tap-to-expand transition for the same workflow/persona surface.

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
| Event detail and RSVP flow | Material cards/lists/buttons / pattern | https://m3.material.io/components/cards/overview<br>Also: https://m3.material.io/components/buttons/overview<br>https://m3.material.io/components/chips/overview | Copy an event detail layout: title, date/time, location, host, capacity/status chip, attendee context, RSVP action, and confirmation state. |

### Reference Research Queries
- production mobile UX review screenshot critique examples
- open source Flutter mobile app UX patterns GitHub
- open source Flutter event-rsvp mobile UI example GitHub
- event detail with schedule, location, capacity/status, RSVP action, and result state mobile UX pattern
- Material Design event detail with schedule, location, capacity/status, RSVP action, and result state mobile pattern

### Implementation Blocked By
- The judge cannot verify production-grade UX without a community-specific product experience spec.
- UI workers need the spec to know the rich product surface they are supposed to build.

### Product Spec Repair Work Items

Showing 1 of 1 work items. Full detail is in the JSON artifact.

| Work item | Stage | Community | Workflow | Persona | Screens | Coverage | Target surface | Blocked until |
| --- | --- | --- | --- | --- | ---: | ---: | --- | --- |
| `b25-wi-product-spec-garden-club` | `product-spec-update` | Garden Club | `community-product-experience` | product-experience-steward | 9 | 0 | review-ready community product experience spec | productDocCoverage status is pass |

### Affected Product Experience Docs

| Product doc | Status | Community | Path | Missing sections | Required fix |
| --- | --- | --- | --- | --- | --- |
| `product-doc-garden-club` | `pass` | Garden Club | `docs/Product Docs V2/Community Examples/garden-club-product-experience.md` |  | Use this product experience doc as the source of truth for B25 screenshot review. |

### Affected Screen Rows

Showing 2 of 2 affected screen rows. Full detail is in the JSON ticket.

| Screen row | Community | Workflow | Persona | State | Screenshot | Hash | Visible text | Current surface | Exact UX failure | Target surface |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `b25-v4-row-001-garden-event-rsvp-0` | Garden Club | `garden-event-rsvp` | member | B13_ext_garden_club_garden-event-rsvp_start | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B13/screenshots/B13_ext_garden_club_garden-event-rsvp_start.png` | `7cbf124dd4448...` | Spring Planting Workshop \| Hands-on bed prep, seedling swap, and seasonal planning with Garden Club members. \| Sat, Apr 18 \| 10:00 AM \| Riverside Greenhouse \| 18 of 24 spots \| Your RSVP \| Choose Going, Maybe, or Not going after checking the schedule, location, host, and capaci... | domain-native-reviewed / domain-native | LLM vision critique: Fresh pass-35 screenshot review of B13_ext_garden_club_garden-event-rsvp_start for Garden Club, workflow garden-event-rsvp, persona member: the visible UI presents a event detail with schedule, location, capacity/status, RSVP action, and result state with domain content instead of a generic workflow checklist. Visible text includes: Spring Planting Workshop \| Hands-on bed prep, seedling swap, and seasonal planning with Garden Club members. \| Sat, Apr 18 \| 10:00 AM \| Riverside Greenhouse \| 18 of 24 spots \| Your RSVP \| Choose Going, Maybe, or Not going after checking the schedule, location.... Layout review finds no blocking overlap, modal checklist, stale evidence, or repeated-card shell issue in the current screenshot. LLM required fix: None for this pass; continue tracking normal polish outside blocker/major B25 gates. | event detail with schedule, location, capacity/status, RSVP action, and result state |
| `b25-v4-row-002-garden-event-rsvp-1` | Garden Club | `garden-event-rsvp` | member | B13_ext_garden_club_garden-event-rsvp_action | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B13/screenshots/B13_ext_garden_club_garden-event-rsvp_action.png` | `eb733e502da3c...` | Spring Planting Workshop \| Saturday, Apr 18 at 10:00 AM - Riverside Greenhouse \| Join the club for bed prep, seedling setup, and a shared planning session before the spring exchange opens. \| Choose your response \| Your RSVP updates the attendee count and leaves a reminder in y... | domain-native-reviewed / domain-native | LLM vision critique: Fresh pass-35 screenshot review of B13_ext_garden_club_garden-event-rsvp_action for Garden Club, workflow garden-event-rsvp, persona member: the visible UI presents a event detail with schedule, location, capacity/status, RSVP action, and result state with domain content instead of a generic workflow checklist. Visible text includes: Spring Planting Workshop \| Saturday, Apr 18 at 10:00 AM - Riverside Greenhouse \| Join the club for bed prep, seedling setup, and a shared planning session before the spring exchange opens. \| Choose your response \| Your RSVP updates the attendee count and leav.... Layout review finds no blocking overlap, modal checklist, stale evidence, or repeated-card shell issue in the current screenshot. LLM required fix: None for this pass; continue tracking normal polish outside blocker/major B25 gates. | event detail with schedule, location, capacity/status, RSVP action, and result state |

### Likely Files / Widgets
- `app/apps/loom_communities_demo/lib/main.dart`
- `app/apps/loom_communities_demo/test/b21_b25_production_ux_test.dart`
- `docs/Build Plan V2/Evidence/B25/production-ux-blueprint.md`
- `docs/Build Plan V2/Evidence/B25/independent-production-ux-review.json`
- `docs/Build Plan V2/Evidence/B25/product-ux-screen-review-matrix.md`
- `docs/Product Docs V2/Community Examples/garden-club-product-experience.md`
- `app/apps/loom_communities_demo/integration_test/workflow_ui_evidence_test.dart`
- `app/apps/loom_communities_demo/test/workflow_ui_test_harness.dart`

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
- `docs/Product Docs V2/Community Examples/garden-club-product-experience.md` exists, has all ten B25 community product experience sections, contains no placeholders, and maps workflows to domain-native surfaces.
- Screen row `b25-v4-row-001-garden-event-rsvp-0` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-001-garden-event-rsvp-0` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-001-garden-event-rsvp-0` names visible UI elements, visible text, persona `member`, workflow `garden-event-rsvp`, and the exact product UX issue.
- Primary surface for `garden-event-rsvp` is documented as `event detail with schedule, location, capacity/status, RSVP action, and result state` or another explicit domain-native surface.
- After-screenshot visible text proves every required semantic surface group for `garden-event-rsvp`.
- Fresh screenshot path/hash/timestamp/app commit SHA are recorded after the fix.
- Screen row `b25-v4-row-002-garden-event-rsvp-1` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-002-garden-event-rsvp-1` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-002-garden-event-rsvp-1` names visible UI elements, visible text, persona `member`, workflow `garden-event-rsvp`, and the exact product UX issue.

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
- `dart run packages/tooling/loom_ux_judges/bin/production_ux_judge.dart --input ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --base .. --output ../docs/Build\ Plan\ V2/Evidence/B25/production-ux-criteria-scorecard.json --markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/production-ux-criteria-scorecard.md --tickets-output ../docs/Build\ Plan\ V2/Evidence/B25/b25-remediation-tickets-<next-run-id>.json --tickets-markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/b25-remediation-tickets-<next-run-id>.md`
- `dart run packages/tooling/loom_ux_judges/bin/b25_iteration_scorecard.dart --review ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --judge ../docs/Build\ Plan\ V2/Evidence/B25/production-ux-criteria-scorecard.json --previous ../docs/Build\ Plan\ V2/Evidence/B25/b25-iteration-scorecard-latest.json --output ../docs/Build\ Plan\ V2/Evidence/B25/b25-iteration-scorecard-latest.json --markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/b25-iteration-scorecard-latest.md`

## B25-RT-004-app-shell-pinning-gap

| Field | Value |
| --- | --- |
| Severity | major |
| Priority | P1 |
| Status | open |
| Review run | `b25-v4-pass-37-app-shell-capability-split` |
| Source criterion | `b25-c16-app-shell-capability-utilization` |
| Source findings | LLM-B25-APP-SHELL-002 |
| Title | Persona/tab pinning policy is ambiguous for HOA evidence |
| Direct question | Is the pinning policy explicit and appropriate for this persona/tab, with screenshots proving pinned surfaces only where the spec declares them? |
| Why it failed | The current evidence does not prove whether the HOA member tab intentionally has no pinned surface or whether a document, board, dues, or facility-status surface should remain pinned. Pinning should not be required everywhere, but the policy must be explicit and appropriate per persona/tab. |
| Required outcome | Update Section 3.1 of the HOA product experience doc with a persona/tab pinning policy. If the reviewed tab should have no pinned surface, declare pinnedSurfaces: none with rationale. If it should have a pinned surface, implement and screenshot-proof that surface in the correct tab. |
| Remediation mode | `product-spec-update-before-ui-remediation` |
| Worker readiness | ready for product documentation update; UI remediation is blocked until the community product experience spec is complete |
| First required step | Complete productDocRepairWorkItems so each affected community has a review-ready Product Docs V2 experience spec with domain-native surfaces and workflow-to-surface mapping. |

### Problem Statement

The current evidence does not prove whether the HOA member tab intentionally has no pinned surface or whether a document, board, dues, or facility-status surface should remain pinned. Pinning should not be required everywhere, but the policy must be explicit and appropriate per persona/tab.

### Root Cause Hypothesis

The evidence does not yet satisfy the B25 production UX standard.

### Target Experience

Every persona/tab has an explicit pinning policy. Tabs that need persistent context keep the declared surface visible; tabs that do not need pins explicitly declare none with rationale.

### UX Principles
- Resolve blocking UX evidence before closing B25

### Concrete Improvements
- Update the community product experience doc Section 3.1 with a per-persona/per-tab pinning policy.
- Use `pinnedSurfaces: none` with a rationale where no pinned surface makes sense; do not add pins just to satisfy the gate.
- When a tab declares pinned surfaces, implement and screenshot-proof that the declared surface remains visible while other tab surfaces scroll or change focus.
- Remove or revise any pin that is irrelevant to the tab job-to-be-done.

### Implementation Guidance
- Use `CommunityAppShellCustomizationSpec`, `LoomAppShellTabSpec`, and `LoomThemeCustomizationTokens` in `apps/loom_communities_demo/lib/main.dart`.
- Implement the capability centrally in the App Shell model, not as a one-off workflow widget hack.
- Recapture screenshots after implementation; source code alone cannot close this ticket.
- Treat pinning as policy-driven: require proof only for persona/tabs that declare pinned surfaces.
- For tabs with no useful pinned surface, document `pinnedSurfaces: none` and the rationale in the community product doc.
- Do not fail a Home tab simply because it has no pinned surface when the product spec explains that Home is a broad overview.

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
| Reservation detail and availability flow | Material cards/forms / pattern | https://m3.material.io/components/date-pickers/overview<br>Also: https://m3.material.io/components/cards/overview | Copy an availability/reservation flow with facility details, date/time, capacity/rules, payment/status when needed, and confirmation. |

### Reference Research Queries
- production mobile UX review screenshot critique examples
- open source Flutter mobile app UX patterns GitHub
- open source Flutter facility-reservation mobile UI example GitHub
- facility detail/reservation flow with availability, payment/status, and confirmation mobile UX pattern
- Material Design facility detail/reservation flow with availability, payment/status, and confirmation mobile pattern

### Implementation Blocked By
- The judge cannot verify production-grade UX without a community-specific product experience spec.
- UI workers need the spec to know the rich product surface they are supposed to build.

### Product Spec Repair Work Items

Showing 1 of 1 work items. Full detail is in the JSON artifact.

| Work item | Stage | Community | Workflow | Persona | Screens | Coverage | Target surface | Blocked until |
| --- | --- | --- | --- | --- | ---: | ---: | --- | --- |
| `b25-wi-product-spec-cedar-commons-hoa` | `product-spec-update` | Cedar Commons HOA | `community-product-experience` | product-experience-steward | 21 | 0 | review-ready community product experience spec | productDocCoverage status is pass |

### Affected Product Experience Docs

| Product doc | Status | Community | Path | Missing sections | Required fix |
| --- | --- | --- | --- | --- | --- |
| `product-doc-cedar-commons-hoa` | `pass` | Cedar Commons HOA | `docs/Product Docs V2/Community Examples/cedar-commons-hoa-product-experience.md` |  | Use this product experience doc as the source of truth for B25 screenshot review. |

### Affected Screen Rows

Showing 1 of 1 affected screen rows. Full detail is in the JSON ticket.

| Screen row | Community | Workflow | Persona | State | Screenshot | Hash | Visible text | Current surface | Exact UX failure | Target surface |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `b25-v4-row-024-hoa-facility-reservation-2` | Cedar Commons HOA | `hoa-facility-reservation` | member | B14_ext_hoa_hoa-facility-reservation_complete | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_hoa_hoa-facility-reservation_complete.png` | `db216dec83e61...` | Clubhouse Room A reservation \| The homeowner record now shows owner, amount or decision, status history, and member next steps. \| Event details \| Property \| Lot 42, homeowner Avery Brooks, Cedar Commons HOA; sender is the HOA board. \| Record \| Community Rules, Room A reservati... | domain-native-reviewed / domain-native | LLM vision critique: Fresh pass-35 screenshot review of B14_ext_hoa_hoa-facility-reservation_complete for Cedar Commons HOA, workflow hoa-facility-reservation, persona member: the visible UI presents a facility detail/reservation flow with availability, payment/status, and confirmation with domain content instead of a generic workflow checklist. Visible text includes: Clubhouse Room A reservation \| The homeowner record now shows owner, amount or decision, status history, and member next steps. \| Event details \| Property \| Lot 42, homeowner Avery Brooks, Cedar Commons HOA; sender is the HOA board. \| Record \| Community Rules.... Layout review finds no blocking overlap, modal checklist, stale evidence, or repeated-card shell issue in the current screenshot. LLM required fix: None for this pass; continue tracking normal polish outside blocker/major B25 gates. | facility detail/reservation flow with availability, payment/status, and confirmation |

### Likely Files / Widgets
- `app/apps/loom_communities_demo/lib/main.dart`
- `app/apps/loom_communities_demo/test/b21_b25_production_ux_test.dart`
- `docs/Build Plan V2/Evidence/B25/production-ux-blueprint.md`
- `docs/Build Plan V2/Evidence/B25/independent-production-ux-review.json`
- `docs/Build Plan V2/Evidence/B25/product-ux-screen-review-matrix.md`
- `docs/Product Docs V2/Community Examples/cedar-commons-hoa-product-experience.md`
- `app/apps/loom_communities_demo/integration_test/workflow_ui_evidence_test.dart`
- `app/apps/loom_communities_demo/test/workflow_ui_test_harness.dart`

### Concrete Acceptance Criteria
- Every reviewed persona/tab has `pinningPolicy` recorded as either `none` with rationale or a concrete list of pinned surface IDs.
- Tabs with `pinningPolicy=none` pass without pinned screenshots when the rationale matches the tab job-to-be-done.
- Tabs with declared pinned surfaces have after-screenshots proving the pinned surface remains visible and relevant.
- `appShellCapabilityReview.communityResults[]` does not fail pinning merely because a tab appropriately declares no pinned surface.
- `appShellCapabilityReview.status` is `pass`.
- `appShellCapabilityReview.missingCapabilities` is empty.
- Every `appShellCapabilityReview.communityResults[]` row has passing tabs, explicit and appropriate pinning policy, presentation states, community-list states, theme customization, and renderer-selection checks where applicable.
- After-screenshots prove the shell capability in the affected community/persona/workflow, not only source-code declarations.
- `production_ux_judge.dart` has no blocking failure for this criterion.
- `b25_iteration_scorecard.dart` records the ticket as resolved or no longer blocking.
- Screenshots are refreshed and hashes/timestamps/app commit SHA match the reviewed app version.
- `docs/Product Docs V2/Community Examples/cedar-commons-hoa-product-experience.md` exists, has all ten B25 community product experience sections, contains no placeholders, and maps workflows to domain-native surfaces.
- Screen row `b25-v4-row-024-hoa-facility-reservation-2` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-024-hoa-facility-reservation-2` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-024-hoa-facility-reservation-2` names visible UI elements, visible text, persona `member`, workflow `hoa-facility-reservation`, and the exact product UX issue.
- Primary surface for `hoa-facility-reservation` is documented as `facility detail/reservation flow with availability, payment/status, and confirmation` or another explicit domain-native surface.
- After-screenshot visible text proves every required semantic surface group for `hoa-facility-reservation`.
- Fresh screenshot path/hash/timestamp/app commit SHA are recorded after the fix.

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
- Every reviewed persona/tab has `pinningPolicy` recorded as either `none` with rationale or a concrete list of pinned surface IDs.
- Tabs with `pinningPolicy=none` pass without pinned screenshots when the rationale matches the tab job-to-be-done.
- Tabs with declared pinned surfaces have after-screenshots proving the pinned surface remains visible and relevant.
- `appShellCapabilityReview.communityResults[]` does not fail pinning merely because a tab appropriately declares no pinned surface.
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
- `dart run packages/tooling/loom_ux_judges/bin/production_ux_judge.dart --input ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --base .. --output ../docs/Build\ Plan\ V2/Evidence/B25/production-ux-criteria-scorecard.json --markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/production-ux-criteria-scorecard.md --tickets-output ../docs/Build\ Plan\ V2/Evidence/B25/b25-remediation-tickets-<next-run-id>.json --tickets-markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/b25-remediation-tickets-<next-run-id>.md`
- `dart run packages/tooling/loom_ux_judges/bin/b25_iteration_scorecard.dart --review ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --judge ../docs/Build\ Plan\ V2/Evidence/B25/production-ux-criteria-scorecard.json --previous ../docs/Build\ Plan\ V2/Evidence/B25/b25-iteration-scorecard-latest.json --output ../docs/Build\ Plan\ V2/Evidence/B25/b25-iteration-scorecard-latest.json --markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/b25-iteration-scorecard-latest.md`

## B25-RT-005-app-shell-community-card-state-gap

| Field | Value |
| --- | --- |
| Severity | major |
| Priority | P1 |
| Status | open |
| Review run | `b25-v4-pass-37-app-shell-capability-split` |
| Source criterion | `b25-c16-app-shell-capability-utilization` |
| Source findings | LLM-B25-APP-SHELL-003 |
| Title | Main community selection card presentation states are missing from evidence |
| Direct question | Does the main Loom Communities list show modern community launch cards with minimized/medium states, theme customization, and tap-to-open behavior? |
| Why it failed | B25 does not include screenshot-backed proof that the Loom Communities main selection page uses minimized/medium presentation states, scroll-driven focus, theme tokens, or tap-to-open behavior for community cards. |
| Required outcome | Add main community selection coverage to B25 evidence. Capture the list with a medium in-focus community card and minimized off-focus cards, including community-specific theme/typography/customization tokens and tap-to-open behavior. |
| Remediation mode | `review-only` |
| Worker readiness | no concrete implementation work item was generated; planner must inspect the direct-question failure before assigning a worker |
| First required step | Review failing direct questions and add screen/workflow/persona-specific evidence before implementation. |

### Problem Statement

B25 does not include screenshot-backed proof that the Loom Communities main selection page uses minimized/medium presentation states, scroll-driven focus, theme tokens, or tap-to-open behavior for community cards.

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
- `docs/Product Docs V2/Community Examples/<community>-product-experience.md Section 3.1`
- `docs/Build Plan V2/Skill/components/card-surfaces/app-shell-navigation-theming.md`
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
- `dart run packages/tooling/loom_ux_judges/bin/production_ux_judge.dart --input ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --base .. --output ../docs/Build\ Plan\ V2/Evidence/B25/production-ux-criteria-scorecard.json --markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/production-ux-criteria-scorecard.md --tickets-output ../docs/Build\ Plan\ V2/Evidence/B25/b25-remediation-tickets-<next-run-id>.json --tickets-markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/b25-remediation-tickets-<next-run-id>.md`
- `dart run packages/tooling/loom_ux_judges/bin/b25_iteration_scorecard.dart --review ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --judge ../docs/Build\ Plan\ V2/Evidence/B25/production-ux-criteria-scorecard.json --previous ../docs/Build\ Plan\ V2/Evidence/B25/b25-iteration-scorecard-latest.json --output ../docs/Build\ Plan\ V2/Evidence/B25/b25-iteration-scorecard-latest.json --markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/b25-iteration-scorecard-latest.md`

## B25-RT-006-app-shell-renderer-selection-gap

| Field | Value |
| --- | --- |
| Severity | major |
| Priority | P1 |
| Status | open |
| Review run | `b25-v4-pass-37-app-shell-capability-split` |
| Source criterion | `b25-c16-app-shell-capability-utilization` |
| Source findings | LLM-B25-APP-SHELL-004 |
| Title | Renderer selection by card-surface family is not explicitly proven |
| Direct question | Does the visible screen prove the App Shell selected the correct domain renderer for the card-surface family instead of a generic fallback? |
| Why it failed | The screenshots show domain content, but the B25 evidence does not explicitly prove that App Shell renderer selection follows the card-surface family registry rather than a generic fallback for affected workflows. |
| Required outcome | Add screenshot/review evidence that the soccer roster workflow is rendered by the roster/profile card-surface family with documented App Shell presentation state and not by a generic fallback renderer. |
| Remediation mode | `product-spec-update-before-ui-remediation` |
| Worker readiness | ready for product documentation update; UI remediation is blocked until the community product experience spec is complete |
| First required step | Complete productDocRepairWorkItems so each affected community has a review-ready Product Docs V2 experience spec with domain-native surfaces and workflow-to-surface mapping. |

### Problem Statement

The screenshots show domain content, but the B25 evidence does not explicitly prove that App Shell renderer selection follows the card-surface family registry rather than a generic fallback for affected workflows.

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
| Roster/list with protected details | Material Design 3 / design-system | https://m3.material.io/components/data-tables/overview<br>Also: https://m3.material.io/components/lists/overview | Copy a roster with member names, roles, status, role-filtered fields, and clear protected-data redaction. |

### Reference Research Queries
- production mobile UX review screenshot critique examples
- open source Flutter mobile app UX patterns GitHub
- open source Flutter roster-list mobile UI example GitHub
- team roster/schedule surface with role-filtered member details and protected-data treatment mobile UX pattern
- Material Design team roster/schedule surface with role-filtered member details and protected-data treatment mobile pattern

### Implementation Blocked By
- The judge cannot verify production-grade UX without a community-specific product experience spec.
- UI workers need the spec to know the rich product surface they are supposed to build.

### Product Spec Repair Work Items

Showing 1 of 1 work items. Full detail is in the JSON artifact.

| Work item | Stage | Community | Workflow | Persona | Screens | Coverage | Target surface | Blocked until |
| --- | --- | --- | --- | --- | ---: | ---: | --- | --- |
| `b25-wi-product-spec-riverside-youth-soccer` | `product-spec-update` | Riverside Youth Soccer | `community-product-experience` | product-experience-steward | 21 | 0 | review-ready community product experience spec | productDocCoverage status is pass |

### Affected Product Experience Docs

| Product doc | Status | Community | Path | Missing sections | Required fix |
| --- | --- | --- | --- | --- | --- |
| `product-doc-riverside-youth-soccer` | `pass` | Riverside Youth Soccer | `docs/Product Docs V2/Community Examples/riverside-youth-soccer-product-experience.md` |  | Use this product experience doc as the source of truth for B25 screenshot review. |

### Affected Screen Rows

Showing 1 of 1 affected screen rows. Full detail is in the JSON ticket.

| Screen row | Community | Workflow | Persona | State | Screenshot | Hash | Visible text | Current surface | Exact UX failure | Target surface |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `b25-v4-row-016-soccer-team-roster-0` | Riverside Youth Soccer | `soccer-team-roster` | coach | B14_ext_youth_soccer_soccer-team-roster_start | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_youth_soccer_soccer-team-roster_start.png` | `e7424808b826b...` | U10 Falcons roster \| Open player names, guardian visibility, protected minor fields, and coach notes without exposing sensitive details. \| Roster and visibility \| Featured player \| Leo Rivera, jersey 14, guardian Mia Rivera, waiver due before Saturday. \| Protected fields \| Bir... | domain-native-reviewed / domain-native | LLM vision critique: Fresh pass-35 screenshot review of B14_ext_youth_soccer_soccer-team-roster_start for Riverside Youth Soccer, workflow soccer-team-roster, persona coach: the visible UI presents a team roster/schedule surface with role-filtered member details and protected-data treatment with domain content instead of a generic workflow checklist. Visible text includes: U10 Falcons roster \| Open player names, guardian visibility, protected minor fields, and coach notes without exposing sensitive details. \| Roster and visibility \| Featured player \| Leo Rivera, jersey 14, guardian Mia Rivera, waiver due before Saturday. \| Prot.... Layout review finds no blocking overlap, modal checklist, stale evidence, or repeated-card shell issue in the current screenshot. LLM required fix: None for this pass; continue tracking normal polish outside blocker/major B25 gates. | team roster/schedule surface with role-filtered member details and protected-data treatment |

### Likely Files / Widgets
- `app/apps/loom_communities_demo/lib/main.dart`
- `app/apps/loom_communities_demo/test/b21_b25_production_ux_test.dart`
- `docs/Build Plan V2/Evidence/B25/production-ux-blueprint.md`
- `docs/Build Plan V2/Evidence/B25/independent-production-ux-review.json`
- `docs/Build Plan V2/Evidence/B25/product-ux-screen-review-matrix.md`
- `docs/Product Docs V2/Community Examples/riverside-youth-soccer-product-experience.md`
- `app/apps/loom_communities_demo/integration_test/workflow_ui_evidence_test.dart`
- `app/apps/loom_communities_demo/test/workflow_ui_test_harness.dart`

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
- `docs/Product Docs V2/Community Examples/riverside-youth-soccer-product-experience.md` exists, has all ten B25 community product experience sections, contains no placeholders, and maps workflows to domain-native surfaces.
- Screen row `b25-v4-row-016-soccer-team-roster-0` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-016-soccer-team-roster-0` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-016-soccer-team-roster-0` names visible UI elements, visible text, persona `coach`, workflow `soccer-team-roster`, and the exact product UX issue.
- Primary surface for `soccer-team-roster` is documented as `team roster/schedule surface with role-filtered member details and protected-data treatment` or another explicit domain-native surface.
- After-screenshot visible text proves every required semantic surface group for `soccer-team-roster`.
- Fresh screenshot path/hash/timestamp/app commit SHA are recorded after the fix.

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
- `dart run packages/tooling/loom_ux_judges/bin/production_ux_judge.dart --input ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --base .. --output ../docs/Build\ Plan\ V2/Evidence/B25/production-ux-criteria-scorecard.json --markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/production-ux-criteria-scorecard.md --tickets-output ../docs/Build\ Plan\ V2/Evidence/B25/b25-remediation-tickets-<next-run-id>.json --tickets-markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/b25-remediation-tickets-<next-run-id>.md`
- `dart run packages/tooling/loom_ux_judges/bin/b25_iteration_scorecard.dart --review ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --judge ../docs/Build\ Plan\ V2/Evidence/B25/production-ux-criteria-scorecard.json --previous ../docs/Build\ Plan\ V2/Evidence/B25/b25-iteration-scorecard-latest.json --output ../docs/Build\ Plan\ V2/Evidence/B25/b25-iteration-scorecard-latest.json --markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/b25-iteration-scorecard-latest.md`
