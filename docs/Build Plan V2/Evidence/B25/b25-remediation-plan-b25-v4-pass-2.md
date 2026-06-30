# B25 Remediation Plan

| Field | Value |
| --- | --- |
| Review run | `b25-v4-pass-9` |
| Status | `open` |
| Source tickets | `../docs/Build Plan V2/Evidence/B25/b25-remediation-tickets-b25-v4-pass-1.json` |
| Ticket count | 9 |
| Scorecard status | `fail` |
| Remaining blocker/major | 1 |
| Blocking criteria failures | 9 |
| Product spec work items | 11 |
| Evidence repair work items | 62 |
| UI remediation work items | 62 |
| Work item sequencing | Product-spec work items must close first, then evidence repair work items, then matching UI remediation work items. |

## Source Tickets

| Ticket | Source criterion | Severity | Status | Title |
| --- | --- | --- | --- | --- |
| `B25-RT-001-b25-c01-no-blocker-major` | `b25-c01-no-blocker-major` | major | open | No unresolved blocker or major findings |
| `B25-RT-002-b25-c02-community-product-docs-complete` | `b25-c02-community-product-docs-complete` | major | open | Every community has a review-ready product experience doc |
| `B25-RT-003-b25-c03-production-grade-experience` | `b25-c03-production-grade-experience` | major | open | Reviewer can state the experience feels production-grade |
| `B25-RT-004-b25-c04-modern-intentional-ui` | `b25-c04-modern-intentional-ui` | major | open | UI looks modern and intentionally designed |
| `B25-RT-005-b25-c05-community-content-ia` | `b25-c05-community-content-ia` | major | open | Screens are organized around community content and jobs-to-be-done |
| `B25-RT-006-b25-c06-domain-native-primary-surfaces` | `b25-c06-domain-native-primary-surfaces` | major | open | Primary workflows use domain-specific product surfaces |
| `B25-RT-007-b25-c13-workflow-lifecycle-complete` | `b25-c13-workflow-lifecycle-complete` | major | open | Every primary workflow has complete lifecycle UX |
| `B25-RT-008-b25-c08-visible-text-specific-critique` | `b25-c08-visible-text-specific-critique` | major | open | Every row has visible text and screen-specific critique |
| `B25-RT-009-b25-c09-no-layout-production-defects` | `b25-c09-no-layout-production-defects` | major | open | No blocking or major layout/content defects remain |

## B25-RB-000-product-experience-specs: Complete community product experience specs

Backfill or update Product Docs V2 community-specific experience specs before UI remediation continues.

| Field | Value |
| --- | --- |
| Status | open |
| Ticket IDs | B25-RT-002-b25-c02-community-product-docs-complete |

### Worker Actions
- Create or update the affected community product experience docs.
- Define the product promise, personas/jobs, information architecture, home requirements, domain-native surfaces, workflow-to-surface mapping, persona/state matrix, seed content, visual standard, and B25 review/remediation log.
- Do not assign UI implementation until productDocCoverage passes for the affected community.
- Rerun the evidence collector so B25 tickets and judge output reference the updated specs.

### Implementation Guidance
- Product doc coverage rows for every reviewed community/test app.
- Updated Product Docs V2 community experience docs with hashes, paths, required sections, and no placeholders.
- B25 review/remediation log entries showing the current screenshots will be judged against each product spec.

### Likely Files / Widgets
- `app/apps/loom_communities_demo/lib/main.dart`
- `app/apps/loom_communities_demo/test/b21_b25_production_ux_test.dart`
- `docs/Build Plan V2/Evidence/B25/production-ux-blueprint.md`
- `docs/Build Plan V2/Evidence/B25/independent-production-ux-review.json`
- `docs/Build Plan V2/Evidence/B25/product-ux-screen-review-matrix.md`
- `docs/Product Docs V2/Community Examples/`
- `docs/Build Plan V2/Skill/references/community-product-experience-template.md`
- `app/packages/tooling/loom_ux_judges/lib/loom_ux_judges.dart`

### UX Reference Patterns To Copy

| Reference | Source | URL | What to copy |
| --- | --- | --- | --- |
| Material navigation and information architecture | Material Design 3 / design-system | https://m3.material.io/components/navigation-drawer/overview<br>Also: https://m3.material.io/components/navigation-bar/overview | Organize screens by user jobs and destinations; keep primary actions visible and avoid exposing implementation taxonomy. |
| Apple HIG navigation and content organization | Apple Human Interface Guidelines / design-system | https://developer.apple.com/design/human-interface-guidelines/navigation | Make navigation predictable, content-centered, and appropriate for the user’s current task. |
| Material Design cards and lists | Material Design 3 / design-system | https://m3.material.io/components/cards/overview<br>Also: https://m3.material.io/components/lists/overview | Use cards/lists only as scannable containers with clear hierarchy, content, metadata, and actions. Do not use repeated cards as the whole primary workflow. |
| Flutter sample app implementation patterns | flutter/samples / open-source | https://github.com/flutter/samples | Copy the separation between app shell, route state, domain widgets, and testable UI states rather than hardcoding a single generic renderer. |

### Reference Research Queries
- community app product requirements personas jobs to be done template
- mobile community app information architecture announcements events messages examples
- product experience specification domain native surfaces workflow mapping examples

### Evidence To Update
- docs/Product Docs V2/Community Examples/<community>-product-experience.md
- independent-production-ux-review.json productDocCoverage
- independent-production-ux-review.md community product experience docs table
- production-ux-criteria-scorecard.json/.md
- Product doc coverage rows for every reviewed community/test app.
- Updated Product Docs V2 community experience docs with hashes, paths, required sections, and no placeholders.
- B25 review/remediation log entries showing the current screenshots will be judged against each product spec.

### Acceptance Checks
- Do not use screenshots alone as the source of truth for desired product experience.
- Do not proceed to UI remediation when a reviewed community has no product experience spec.
- Do not satisfy this criterion with a generic template that could apply unchanged to another community.

### Concrete Acceptance Criteria
- Do not use screenshots alone as the source of truth for desired product experience.
- Do not proceed to UI remediation when a reviewed community has no product experience spec.
- Do not satisfy this criterion with a generic template that could apply unchanged to another community.

### Rerun Commands
- `dart run packages/tooling/loom_ux_judges/bin/b25_evidence_collector.dart --evidence-root ../docs/Build\ Plan\ V2/Evidence --repo-root .. --run-id <next-run-id> --prior-review ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --output ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.md --matrix-output ../docs/Build\ Plan\ V2/Evidence/B25/product-ux-screen-review-matrix.md`
- `dart run packages/tooling/loom_ux_judges/bin/b25_workflow_persona_coverage_collector.dart --input ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --output ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/workflow-persona-coverage-matrix.md`
- `dart run packages/tooling/loom_ux_judges/bin/b25_independent_ux_judge.dart --input ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --output ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.md --matrix-output ../docs/Build\ Plan\ V2/Evidence/B25/product-ux-screen-review-matrix.md`
- `dart run packages/tooling/loom_ux_judges/bin/production_ux_judge.dart --input ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --base .. --output ../docs/Build\ Plan\ V2/Evidence/B25/production-ux-criteria-scorecard.json --markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/production-ux-criteria-scorecard.md --tickets-output ../docs/Build\ Plan\ V2/Evidence/B25/b25-remediation-tickets-<next-run-id>.json --tickets-markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/b25-remediation-tickets-<next-run-id>.md`
- `dart run packages/tooling/loom_ux_judges/bin/b25_iteration_scorecard.dart --review ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --judge ../docs/Build\ Plan\ V2/Evidence/B25/production-ux-criteria-scorecard.json --previous ../docs/Build\ Plan\ V2/Evidence/B25/b25-iteration-scorecard-latest.json --output ../docs/Build\ Plan\ V2/Evidence/B25/b25-iteration-scorecard-latest.json --markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/b25-iteration-scorecard-latest.md`

### Commit Boundary

Commit this remediation batch, refreshed evidence, judge outputs, scorecards, and tracker updates before the next UX feedback loop. If the committed pass still fails, the following pass starts by sending its tickets to the Remediation Planner.

## B25-RB-001-independent-review-evidence: Complete independent review evidence and critique

Turn captured screenshots into complete independent UX review evidence before attempting UI remediation.

| Field | Value |
| --- | --- |
| Status | open |
| Ticket IDs | B25-RT-003-b25-c03-production-grade-experience, B25-RT-004-b25-c04-modern-intentional-ui, B25-RT-008-b25-c08-visible-text-specific-critique, B25-RT-009-b25-c09-no-layout-production-defects |

### Worker Actions
- Fill holistic direct-question answers with screenshot-grounded yes/no/partial judgments.
- Fill every screen row with visible text and screen-specific critique.
- Fill workflow/persona scorecards for every reviewed workflow/persona pair.
- Resolve every evidenceRepairWorkItem before assigning UI implementation work for that same community/workflow/persona.
- Keep reviewer context limited to screenshots, blueprint, evidence, and pass criteria.

### Implementation Guidance
- Inspect `apps/loom_communities_demo/lib` for the primary community home, shell, card, detail, and workflow surface widgets.
- Compare every change against `docs/Build Plan V2/Evidence/B25/production-ux-blueprint.md` before coding.
- Update widget tests and B25 evidence expectations when user-facing hierarchy, copy, or surface structure changes.
- Update the B25 judge/review artifact, not only app UI code.
- Fill `screenRows[].visibleTextExtract`, `screenRows[].screenSpecificCritique`, `holisticQuestionAnswers`, and `workflowPersonaScorecards` with screenshot-specific content.
- Regenerate markdown review and matrix files from the updated schema v4 JSON.

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

### UX Reference Patterns To Copy

| Reference | Source | URL | What to copy |
| --- | --- | --- | --- |
| Material navigation and information architecture | Material Design 3 / design-system | https://m3.material.io/components/navigation-drawer/overview<br>Also: https://m3.material.io/components/navigation-bar/overview | Organize screens by user jobs and destinations; keep primary actions visible and avoid exposing implementation taxonomy. |
| Apple HIG navigation and content organization | Apple Human Interface Guidelines / design-system | https://developer.apple.com/design/human-interface-guidelines/navigation | Make navigation predictable, content-centered, and appropriate for the user’s current task. |
| Material Design cards and lists | Material Design 3 / design-system | https://m3.material.io/components/cards/overview<br>Also: https://m3.material.io/components/lists/overview | Use cards/lists only as scannable containers with clear hierarchy, content, metadata, and actions. Do not use repeated cards as the whole primary workflow. |
| Flutter sample app implementation patterns | flutter/samples / open-source | https://github.com/flutter/samples | Copy the separation between app shell, route state, domain widgets, and testable UI states rather than hardcoding a single generic renderer. |
| Screenshot-first critique method | B25 production UX gate / methodology | docs/Build Plan V2/Tools/b25-remediation-ticket-template.md | Critique must quote visible UI/text, name the persona and task, compare against the chosen reference pattern, and state the exact fix. |
| Material detail surface composition | Material Design 3 / design-system | https://m3.material.io/components/cards/overview | Build a domain detail page with primary content, metadata, status, and actions instead of a generic task card. |
| Inbox and message thread pattern | Material lists/text fields / pattern | https://m3.material.io/components/lists/overview<br>Also: https://m3.material.io/components/text-fields/overview | Copy an inbox/thread structure: sender, timestamp, message preview/body, reply field, invite/block state, and read/received state. |
| Feed item and composer pattern | Material cards/lists/text fields / pattern | https://m3.material.io/components/text-fields/overview<br>Also: https://m3.material.io/components/cards/overview<br>https://m3.material.io/components/lists/overview | Copy a feed/composer structure: audience, author, timestamp, body, attachments/status, publish action, and receiver read state. |
| Document list/detail pattern | Material lists/cards / pattern | https://m3.material.io/components/lists/overview | Copy a document library with title, category, audience, file metadata, access state, download/view action, and empty/error states. |
| Form validation and review pattern | U.S. Web Design System / design-system | https://designsystem.digital.gov/components/form/<br>Also: https://designsystem.digital.gov/components/alert/<br>https://design-system.service.gov.uk/components/error-summary/ | Copy a form flow with field labels, helper text, validation errors, review state, submit action, status, and protected-data treatment. |
| Match schedule and result pattern | Material lists/cards / pattern | https://m3.material.io/components/lists/overview | Copy a match surface with players, schedule/round, result entry, result state, and next action. |

### Reference Research Queries
- production mobile UX review screenshot critique examples
- open source Flutter mobile app UX patterns GitHub
- modern mobile app information architecture visual hierarchy examples
- Material Design 3 mobile UI hierarchy navigation cards examples
- open source Flutter production app dashboard detail screen examples
- open source Flutter domain-native-surface mobile UI example GitHub
- plant exchange offer form and member marketplace surface with plant details, pickup timing, owner contact, and submitted offer state mobile UX pattern
- Material Design plant exchange offer form and member marketplace surface with plant details, pickup timing, owner contact, and submitted offer state mobile pattern
- open source Flutter message-thread mobile UI example GitHub
- inbox, message thread, connection card, invite, or block-state surface mobile UX pattern
- Material Design inbox, message thread, connection card, invite, or block-state surface mobile pattern
- open source Flutter announcement-feed mobile UI example GitHub
- announcement feed/composer with audience, author, timestamp, body, and receiver state mobile UX pattern
- Material Design announcement feed/composer with audience, author, timestamp, body, and receiver state mobile pattern
- protected youth roster/profile surface with minor-data redaction, guardian visibility, and coach-only detail state mobile UX pattern
- Material Design protected youth roster/profile surface with minor-data redaction, guardian visibility, and coach-only detail state mobile pattern
- notification inbox/detail surface with sender, audience, timestamp, message body, and receiver state mobile UX pattern
- Material Design notification inbox/detail surface with sender, audience, timestamp, message body, and receiver state mobile pattern
- open source Flutter document-library mobile UI example GitHub
- document library/detail surface with title, audience, file metadata, and access state mobile UX pattern

### Evidence Repair Work Items

Showing 17 of 17 work items. Full detail is in the JSON artifact.

| Work item | Stage | Community | Workflow | Persona | Screens | Coverage | Target surface | Blocked until |
| --- | --- | --- | --- | --- | ---: | ---: | --- | --- |
| `b25-wi-evidence-repair-community-garden-club-plant-exchange-submission-community-garden-club-member` | `evidence-repair` | Garden Club | `plant-exchange-submission` | member | 3 | 1 | plant exchange offer form and member marketplace surface with plant details, pickup timing, owner contact, and submitted offer state |  |
| `b25-wi-evidence-repair-community-book-club-book-discussion-message-community-book-club-member` | `evidence-repair` | Neighborhood Book Club | `book-discussion-message` | member | 3 | 1 | inbox, message thread, connection card, invite, or block-state surface |  |
| `b25-wi-evidence-repair-community-book-club-book-selection-publish-community-book-club-owner` | `evidence-repair` | Neighborhood Book Club | `book-selection-publish` | owner | 3 | 1 | announcement feed/composer with audience, author, timestamp, body, and receiver state |  |
| `b25-wi-evidence-repair-community-youth-soccer-soccer-minor-redaction-community-youth-soccer-guardian` | `evidence-repair` | Riverside Youth Soccer | `soccer-minor-redaction` | guardian | 3 | 1 | protected youth roster/profile surface with minor-data redaction, guardian visibility, and coach-only detail state |  |
| `b25-wi-evidence-repair-community-youth-soccer-soccer-reminder-notification-community-youth-soccer-guardian` | `evidence-repair` | Riverside Youth Soccer | `soccer-reminder-notification` | guardian | 3 | 1 | notification inbox/detail surface with sender, audience, timestamp, message body, and receiver state |  |
| `b25-wi-evidence-repair-community-hoa-hoa-member-document-community-hoa-member` | `evidence-repair` | Cedar Commons HOA | `hoa-member-document` | member | 3 | 1 | document library/detail surface with title, audience, file metadata, and access state |  |
| `b25-wi-evidence-repair-community-hoa-hoa-architectural-request-community-hoa-owner` | `evidence-repair` | Cedar Commons HOA | `hoa-architectural-request` | owner | 3 | 1 | request detail and admin review queue with submitted data, decision action, status, and notification |  |
| `b25-wi-evidence-repair-community-hoa-hoa-owner-notification-community-hoa-owner` | `evidence-repair` | Cedar Commons HOA | `hoa-owner-notification` | owner | 3 | 1 | notification inbox/detail surface with sender, audience, timestamp, message body, and receiver state |  |
| `b25-wi-evidence-repair-community-mosque-mosque-announcement-community-mosque-owner` | `evidence-repair` | Masjid Nur | `mosque-announcement` | owner | 3 | 1 | announcement feed/composer with audience, author, timestamp, body, and receiver state |  |
| `b25-wi-evidence-repair-community-mosque-mosque-donor-visibility-community-mosque-donor` | `evidence-repair` | Masjid Nur | `mosque-donor-visibility` | donor | 3 | 1 | donor privacy preference surface with visibility choice, donation context, confirmation, and receipt visibility state |  |
| `b25-wi-evidence-repair-community-mosque-mosque-neutral-notification-community-mosque-member` | `evidence-repair` | Masjid Nur | `mosque-neutral-notification` | member | 3 | 1 | notification inbox/detail surface with sender, audience, timestamp, message body, and receiver state |  |
| `b25-wi-evidence-repair-community-chess-club-chess-local-install-open-community-chess-club-member` | `evidence-repair` | Chess Club | `chess-local-install-open` | member | 3 | 1 | match schedule/result surface with players, round, outcome, and next action |  |
| `b25-wi-evidence-repair-community-chess-club-chess-route-home-community-chess-club-member` | `evidence-repair` | Chess Club | `chess-route-home` | member | 3 | 1 | match schedule/result surface with players, round, outcome, and next action |  |
| `b25-wi-evidence-repair-community-chess-club-chess-match-result-community-chess-club-member` | `evidence-repair` | Chess Club | `chess-match-result` | member | 3 | 1 | match schedule/result surface with players, round, outcome, and next action |  |
| `b25-wi-evidence-repair-community-camera-club-critique-submission-community-camera-club-member` | `evidence-repair` | Camera Club | `critique-submission` | member | 3 | 1 | critique submission/review surface with image/work title, comments, reviewer state, and result |  |
| `b25-wi-evidence-repair-community-camera-club-gear-loan-request-community-camera-club-member` | `evidence-repair` | Camera Club | `gear-loan-request` | member | 3 | 1 | request detail and admin review queue with submitted data, decision action, status, and notification |  |
| `b25-wi-evidence-repair-community-platform-social-platform-message-stream-community-platform-social-member` | `evidence-repair` | Member Social Space | `platform-message-stream` | member | 3 | 1 | inbox, message thread, connection card, invite, or block-state surface |  |

### Evidence Repair Work Items Reference Patterns

| Reference | Source | URL | What to copy |
| --- | --- | --- | --- |
| Material detail surface composition | Material Design 3 / design-system | https://m3.material.io/components/cards/overview | Build a domain detail page with primary content, metadata, status, and actions instead of a generic task card. |
| Material Design cards and lists | Material Design 3 / design-system | https://m3.material.io/components/cards/overview<br>Also: https://m3.material.io/components/lists/overview | Use cards/lists only as scannable containers with clear hierarchy, content, metadata, and actions. Do not use repeated cards as the whole primary workflow. |
| Flutter sample app implementation patterns | flutter/samples / open-source | https://github.com/flutter/samples | Copy the separation between app shell, route state, domain widgets, and testable UI states rather than hardcoding a single generic renderer. |
| Material navigation and information architecture | Material Design 3 / design-system | https://m3.material.io/components/navigation-drawer/overview<br>Also: https://m3.material.io/components/navigation-bar/overview | Organize screens by user jobs and destinations; keep primary actions visible and avoid exposing implementation taxonomy. |
| Apple HIG navigation and content organization | Apple Human Interface Guidelines / design-system | https://developer.apple.com/design/human-interface-guidelines/navigation | Make navigation predictable, content-centered, and appropriate for the user’s current task. |
| Inbox and message thread pattern | Material lists/text fields / pattern | https://m3.material.io/components/lists/overview<br>Also: https://m3.material.io/components/text-fields/overview | Copy an inbox/thread structure: sender, timestamp, message preview/body, reply field, invite/block state, and read/received state. |
| Feed item and composer pattern | Material cards/lists/text fields / pattern | https://m3.material.io/components/text-fields/overview<br>Also: https://m3.material.io/components/cards/overview<br>https://m3.material.io/components/lists/overview | Copy a feed/composer structure: audience, author, timestamp, body, attachments/status, publish action, and receiver read state. |
| Document list/detail pattern | Material lists/cards / pattern | https://m3.material.io/components/lists/overview | Copy a document library with title, category, audience, file metadata, access state, download/view action, and empty/error states. |
| Form validation and review pattern | U.S. Web Design System / design-system | https://designsystem.digital.gov/components/form/<br>Also: https://designsystem.digital.gov/components/alert/<br>https://design-system.service.gov.uk/components/error-summary/ | Copy a form flow with field labels, helper text, validation errors, review state, submit action, status, and protected-data treatment. |
| Match schedule and result pattern | Material lists/cards / pattern | https://m3.material.io/components/lists/overview | Copy a match surface with players, schedule/round, result entry, result state, and next action. |

### Affected Coverage Rows

Showing 17 of 17 affected coverage rows.

| Coverage row | Community | Workflow | Persona | Missing evidence |
| --- | --- | --- | --- | --- |
| `b25-wp-002-plant-exchange-submission-community-garden-club-member` | Garden Club | `plant-exchange-submission` | member |  |
| `b25-wp-007-book-discussion-message-community-book-club-member` | Neighborhood Book Club | `book-discussion-message` | member |  |
| `b25-wp-008-book-selection-publish-community-book-club-owner` | Neighborhood Book Club | `book-selection-publish` | owner |  |
| `b25-wp-013-soccer-minor-redaction-community-youth-soccer-guardian` | Riverside Youth Soccer | `soccer-minor-redaction` | guardian |  |
| `b25-wp-016-soccer-reminder-notification-community-youth-soccer-guardian` | Riverside Youth Soccer | `soccer-reminder-notification` | guardian |  |
| `b25-wp-019-hoa-member-document-community-hoa-member` | Cedar Commons HOA | `hoa-member-document` | member |  |
| `b25-wp-021-hoa-architectural-request-community-hoa-owner` | Cedar Commons HOA | `hoa-architectural-request` | owner |  |
| `b25-wp-023-hoa-owner-notification-community-hoa-owner` | Cedar Commons HOA | `hoa-owner-notification` | owner |  |
| `b25-wp-025-mosque-announcement-community-mosque-owner` | Masjid Nur | `mosque-announcement` | owner |  |
| `b25-wp-028-mosque-donor-visibility-community-mosque-donor` | Masjid Nur | `mosque-donor-visibility` | donor |  |
| `b25-wp-031-mosque-neutral-notification-community-mosque-member` | Masjid Nur | `mosque-neutral-notification` | member |  |
| `b25-wp-033-chess-local-install-open-community-chess-club-member` | Chess Club | `chess-local-install-open` | member |  |
| `b25-wp-034-chess-route-home-community-chess-club-member` | Chess Club | `chess-route-home` | member |  |
| `b25-wp-035-chess-match-result-community-chess-club-member` | Chess Club | `chess-match-result` | member |  |
| `b25-wp-037-critique-submission-community-camera-club-member` | Camera Club | `critique-submission` | member |  |
| `b25-wp-038-gear-loan-request-community-camera-club-member` | Camera Club | `gear-loan-request` | member |  |
| `b25-wp-043-platform-message-stream-community-platform-social-member` | Member Social Space | `platform-message-stream` | member |  |

### Affected Screen Rows

Showing 30 of 51 affected screen rows.

| Screen row | Community | Workflow | Persona | State | Exact UX failure |
| --- | --- | --- | --- | --- | --- |
| `b25-v4-row-004-plant-exchange-submission-0` | Garden Club | `plant-exchange-submission` | member | B13_ext_garden_club_plant-exchange-submission_start | Ticket must add screenshot-backed visible text and a non-reusable critique for this exact screen. |
| `b25-v4-row-005-plant-exchange-submission-1` | Garden Club | `plant-exchange-submission` | member | B13_ext_garden_club_plant-exchange-submission_action | Ticket must add screenshot-backed visible text and a non-reusable critique for this exact screen. |
| `b25-v4-row-006-plant-exchange-submission-2` | Garden Club | `plant-exchange-submission` | member | B13_ext_garden_club_plant-exchange-submission_complete | Ticket must add screenshot-backed visible text and a non-reusable critique for this exact screen. |
| `b25-v4-row-019-book-discussion-message-0` | Neighborhood Book Club | `book-discussion-message` | member | B14_ext_book_club_book-discussion-message_start | Ticket must add screenshot-backed visible text and a non-reusable critique for this exact screen. |
| `b25-v4-row-020-book-discussion-message-1` | Neighborhood Book Club | `book-discussion-message` | member | B14_ext_book_club_book-discussion-message_action | Ticket must add screenshot-backed visible text and a non-reusable critique for this exact screen. |
| `b25-v4-row-021-book-discussion-message-2` | Neighborhood Book Club | `book-discussion-message` | member | B14_ext_book_club_book-discussion-message_complete | Ticket must add screenshot-backed visible text and a non-reusable critique for this exact screen. |
| `b25-v4-row-022-book-selection-publish-0` | Neighborhood Book Club | `book-selection-publish` | owner | B14_ext_book_club_book-selection-publish_start | Ticket must add screenshot-backed visible text and a non-reusable critique for this exact screen. |
| `b25-v4-row-023-book-selection-publish-1` | Neighborhood Book Club | `book-selection-publish` | owner | B14_ext_book_club_book-selection-publish_action | Ticket must add screenshot-backed visible text and a non-reusable critique for this exact screen. |
| `b25-v4-row-024-book-selection-publish-2` | Neighborhood Book Club | `book-selection-publish` | owner | B14_ext_book_club_book-selection-publish_complete | Ticket must add screenshot-backed visible text and a non-reusable critique for this exact screen. |
| `b25-v4-row-037-soccer-minor-redaction-0` | Riverside Youth Soccer | `soccer-minor-redaction` | guardian | B14_ext_youth_soccer_soccer-minor-redaction_start | Ticket must add screenshot-backed visible text and a non-reusable critique for this exact screen. |
| `b25-v4-row-038-soccer-minor-redaction-1` | Riverside Youth Soccer | `soccer-minor-redaction` | guardian | B14_ext_youth_soccer_soccer-minor-redaction_action | Ticket must add screenshot-backed visible text and a non-reusable critique for this exact screen. |
| `b25-v4-row-039-soccer-minor-redaction-2` | Riverside Youth Soccer | `soccer-minor-redaction` | guardian | B14_ext_youth_soccer_soccer-minor-redaction_complete | Ticket must add screenshot-backed visible text and a non-reusable critique for this exact screen. |
| `b25-v4-row-046-soccer-reminder-notification-0` | Riverside Youth Soccer | `soccer-reminder-notification` | guardian | B14_ext_youth_soccer_soccer-reminder-notification_start | Ticket must add screenshot-backed visible text and a non-reusable critique for this exact screen. |
| `b25-v4-row-047-soccer-reminder-notification-1` | Riverside Youth Soccer | `soccer-reminder-notification` | guardian | B14_ext_youth_soccer_soccer-reminder-notification_action | Ticket must add screenshot-backed visible text and a non-reusable critique for this exact screen. |
| `b25-v4-row-048-soccer-reminder-notification-2` | Riverside Youth Soccer | `soccer-reminder-notification` | guardian | B14_ext_youth_soccer_soccer-reminder-notification_complete | Ticket must add screenshot-backed visible text and a non-reusable critique for this exact screen. |
| `b25-v4-row-055-hoa-member-document-0` | Cedar Commons HOA | `hoa-member-document` | member | B14_ext_hoa_hoa-member-document_start | Ticket must add screenshot-backed visible text and a non-reusable critique for this exact screen. |
| `b25-v4-row-056-hoa-member-document-1` | Cedar Commons HOA | `hoa-member-document` | member | B14_ext_hoa_hoa-member-document_action | Ticket must add screenshot-backed visible text and a non-reusable critique for this exact screen. |
| `b25-v4-row-057-hoa-member-document-2` | Cedar Commons HOA | `hoa-member-document` | member | B14_ext_hoa_hoa-member-document_complete | Ticket must add screenshot-backed visible text and a non-reusable critique for this exact screen. |
| `b25-v4-row-061-hoa-architectural-request-0` | Cedar Commons HOA | `hoa-architectural-request` | owner | B14_ext_hoa_hoa-architectural-request_start | Ticket must add screenshot-backed visible text and a non-reusable critique for this exact screen. |
| `b25-v4-row-062-hoa-architectural-request-1` | Cedar Commons HOA | `hoa-architectural-request` | owner | B14_ext_hoa_hoa-architectural-request_action | Ticket must add screenshot-backed visible text and a non-reusable critique for this exact screen. |
| `b25-v4-row-063-hoa-architectural-request-2` | Cedar Commons HOA | `hoa-architectural-request` | owner | B14_ext_hoa_hoa-architectural-request_complete | Ticket must add screenshot-backed visible text and a non-reusable critique for this exact screen. |
| `b25-v4-row-067-hoa-owner-notification-0` | Cedar Commons HOA | `hoa-owner-notification` | owner | B14_ext_hoa_hoa-owner-notification_start | Ticket must add screenshot-backed visible text and a non-reusable critique for this exact screen. |
| `b25-v4-row-068-hoa-owner-notification-1` | Cedar Commons HOA | `hoa-owner-notification` | owner | B14_ext_hoa_hoa-owner-notification_action | Ticket must add screenshot-backed visible text and a non-reusable critique for this exact screen. |
| `b25-v4-row-069-hoa-owner-notification-2` | Cedar Commons HOA | `hoa-owner-notification` | owner | B14_ext_hoa_hoa-owner-notification_complete | Ticket must add screenshot-backed visible text and a non-reusable critique for this exact screen. |
| `b25-v4-row-073-mosque-announcement-0` | Masjid Nur | `mosque-announcement` | owner | B14_ext_mosque_mosque-announcement_start | Ticket must add screenshot-backed visible text and a non-reusable critique for this exact screen. |
| `b25-v4-row-074-mosque-announcement-1` | Masjid Nur | `mosque-announcement` | owner | B14_ext_mosque_mosque-announcement_action | Ticket must add screenshot-backed visible text and a non-reusable critique for this exact screen. |
| `b25-v4-row-075-mosque-announcement-2` | Masjid Nur | `mosque-announcement` | owner | B14_ext_mosque_mosque-announcement_complete | Ticket must add screenshot-backed visible text and a non-reusable critique for this exact screen. |
| `b25-v4-row-082-mosque-donor-visibility-0` | Masjid Nur | `mosque-donor-visibility` | donor | B14_ext_mosque_mosque-donor-visibility_start | Ticket must add screenshot-backed visible text and a non-reusable critique for this exact screen. |
| `b25-v4-row-083-mosque-donor-visibility-1` | Masjid Nur | `mosque-donor-visibility` | donor | B14_ext_mosque_mosque-donor-visibility_action | Ticket must add screenshot-backed visible text and a non-reusable critique for this exact screen. |
| `b25-v4-row-084-mosque-donor-visibility-2` | Masjid Nur | `mosque-donor-visibility` | donor | B14_ext_mosque_mosque-donor-visibility_complete | Ticket must add screenshot-backed visible text and a non-reusable critique for this exact screen. |

### Evidence To Update
- independent-production-ux-review.json holisticQuestionAnswers
- independent-production-ux-review.md holistic review summary
- product-ux-screen-review-matrix.md relevant screen rows
- production-ux-criteria-scorecard.json/.md
- independent-production-ux-review.json workflowPersonaScorecards
- independent-production-ux-review.json screenRows
- product-ux-screen-review-matrix.md every workflow/persona row
- Fresh holistic screenshots for primary homes, navigation, representative detail surfaces, and representative completion/result states.
- `holisticQuestionAnswers` with visible evidence, score, pass/fail answer, and specific rationale.
- Updated `production-ux-criteria-scorecard.json/.md` showing the criterion passes.
- Visible text extracts for every reviewed row.
- Non-boilerplate screen-specific critique for every reviewed row.
- Updated markdown matrix matching the JSON evidence.

### Acceptance Checks
- Holistic direct-question answers are present, screenshot-backed, non-boilerplate, and pass.
- `production_ux_judge.dart` has no blocking failure for this criterion.
- `b25_iteration_scorecard.dart` records the ticket as resolved or no longer blocking.
- Screenshots are refreshed and hashes/timestamps/app commit SHA match the reviewed app version.
- Every workflow/persona scorecard is present, screenshot-backed, non-boilerplate, and pass.

### Concrete Acceptance Criteria
- Holistic direct-question answers are present, screenshot-backed, non-boilerplate, and pass.
- `production_ux_judge.dart` has no blocking failure for this criterion.
- `b25_iteration_scorecard.dart` records the ticket as resolved or no longer blocking.
- Screenshots are refreshed and hashes/timestamps/app commit SHA match the reviewed app version.
- Every workflow/persona scorecard is present, screenshot-backed, non-boilerplate, and pass.
- Screen row `b25-v4-row-004-plant-exchange-submission-0` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-004-plant-exchange-submission-0` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-004-plant-exchange-submission-0` names visible UI elements, visible text, persona `member`, workflow `plant-exchange-submission`, and the exact product UX issue.
- Primary surface for `plant-exchange-submission` is documented as `plant exchange offer form and member marketplace surface with plant details, pickup timing, owner contact, and submitted offer state` or another explicit domain-native surface.
- After-screenshot visible text proves every required semantic surface group for `plant-exchange-submission`.
- Fresh screenshot path/hash/timestamp/app commit SHA are recorded after the fix.
- The workflow/persona direct-question scorecard passes the visible-text and task-specific critique question.
- Screen row `b25-v4-row-005-plant-exchange-submission-1` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-005-plant-exchange-submission-1` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-005-plant-exchange-submission-1` names visible UI elements, visible text, persona `member`, workflow `plant-exchange-submission`, and the exact product UX issue.
- Screen row `b25-v4-row-006-plant-exchange-submission-2` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-006-plant-exchange-submission-2` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-006-plant-exchange-submission-2` names visible UI elements, visible text, persona `member`, workflow `plant-exchange-submission`, and the exact product UX issue.
- Screen row `b25-v4-row-019-book-discussion-message-0` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-019-book-discussion-message-0` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-019-book-discussion-message-0` names visible UI elements, visible text, persona `member`, workflow `book-discussion-message`, and the exact product UX issue.
- Primary surface for `book-discussion-message` is documented as `inbox, message thread, connection card, invite, or block-state surface` or another explicit domain-native surface.
- After-screenshot visible text proves every required semantic surface group for `book-discussion-message`.
- Screen row `b25-v4-row-020-book-discussion-message-1` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-020-book-discussion-message-1` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-020-book-discussion-message-1` names visible UI elements, visible text, persona `member`, workflow `book-discussion-message`, and the exact product UX issue.
- Screen row `b25-v4-row-021-book-discussion-message-2` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-021-book-discussion-message-2` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-021-book-discussion-message-2` names visible UI elements, visible text, persona `member`, workflow `book-discussion-message`, and the exact product UX issue.
- Screen row `b25-v4-row-022-book-selection-publish-0` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-022-book-selection-publish-0` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-022-book-selection-publish-0` names visible UI elements, visible text, persona `owner`, workflow `book-selection-publish`, and the exact product UX issue.
- Primary surface for `book-selection-publish` is documented as `announcement feed/composer with audience, author, timestamp, body, and receiver state` or another explicit domain-native surface.
- After-screenshot visible text proves every required semantic surface group for `book-selection-publish`.
- Screen row `b25-v4-row-023-book-selection-publish-1` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-023-book-selection-publish-1` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-023-book-selection-publish-1` names visible UI elements, visible text, persona `owner`, workflow `book-selection-publish`, and the exact product UX issue.
- Screen row `b25-v4-row-024-book-selection-publish-2` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-024-book-selection-publish-2` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-024-book-selection-publish-2` names visible UI elements, visible text, persona `owner`, workflow `book-selection-publish`, and the exact product UX issue.

### Rerun Commands
- `dart run packages/tooling/loom_ux_judges/bin/b25_evidence_collector.dart --evidence-root ../docs/Build\ Plan\ V2/Evidence --repo-root .. --run-id <next-run-id> --prior-review ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --output ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.md --matrix-output ../docs/Build\ Plan\ V2/Evidence/B25/product-ux-screen-review-matrix.md`
- `dart run packages/tooling/loom_ux_judges/bin/b25_workflow_persona_coverage_collector.dart --input ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --output ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/workflow-persona-coverage-matrix.md`
- `dart run packages/tooling/loom_ux_judges/bin/b25_independent_ux_judge.dart --input ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --output ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.md --matrix-output ../docs/Build\ Plan\ V2/Evidence/B25/product-ux-screen-review-matrix.md`
- `dart run packages/tooling/loom_ux_judges/bin/production_ux_judge.dart --input ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --base .. --output ../docs/Build\ Plan\ V2/Evidence/B25/production-ux-criteria-scorecard.json --markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/production-ux-criteria-scorecard.md --tickets-output ../docs/Build\ Plan\ V2/Evidence/B25/b25-remediation-tickets-<next-run-id>.json --tickets-markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/b25-remediation-tickets-<next-run-id>.md`
- `dart run packages/tooling/loom_ux_judges/bin/b25_iteration_scorecard.dart --review ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --judge ../docs/Build\ Plan\ V2/Evidence/B25/production-ux-criteria-scorecard.json --previous ../docs/Build\ Plan\ V2/Evidence/B25/b25-iteration-scorecard-latest.json --output ../docs/Build\ Plan\ V2/Evidence/B25/b25-iteration-scorecard-latest.json --markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/b25-iteration-scorecard-latest.md`

### Commit Boundary

Commit this remediation batch, refreshed evidence, judge outputs, scorecards, and tracker updates before the next UX feedback loop. If the committed pass still fails, the following pass starts by sending its tickets to the Remediation Planner.

## B25-RB-002-domain-native-ux-remediation: Remediate domain-native IA and primary workflow surfaces

Apply product UX fixes found by the independent critique so primary screens feel like production community surfaces.

| Field | Value |
| --- | --- |
| Status | open |
| Ticket IDs | B25-RT-004-b25-c04-modern-intentional-ui, B25-RT-005-b25-c05-community-content-ia, B25-RT-006-b25-c06-domain-native-primary-surfaces, B25-RT-009-b25-c09-no-layout-production-defects |

### Worker Actions
- Start only after the matching evidenceRepairWorkItems have concrete personas, screenshot-derived visible text, and screen-specific critiques.
- Replace any primary global workflow lists, metadata pages, checklist modals, or repeated generic cards with domain-native surfaces.
- Rebuild primary homes and flows around community content and jobs-to-be-done.
- Improve hierarchy, spacing, typography, component quality, navigation clarity, and mobile layout.
- Update copy/content so visible UI speaks to the target persona and task, not to validation mechanics.

### Implementation Guidance
- Inspect `apps/loom_communities_demo/lib` for the primary community home, shell, card, detail, and workflow surface widgets.
- Compare every change against `docs/Build Plan V2/Evidence/B25/production-ux-blueprint.md` before coding.
- Update widget tests and B25 evidence expectations when user-facing hierarchy, copy, or surface structure changes.
- Inspect workflow surface builders and replace primary generic card/checklist/modal renderers with task-specific widgets.
- Use B21 production UX contracts to choose the target surface type for each workflow/persona pair.
- Update screenshot evidence manifests so each replaced surface is captured at entry, action, and result states.

### Likely Files / Widgets
- `app/apps/loom_communities_demo/lib/main.dart`
- `app/apps/loom_communities_demo/test/b21_b25_production_ux_test.dart`
- `docs/Build Plan V2/Evidence/B25/production-ux-blueprint.md`
- `docs/Build Plan V2/Evidence/B25/independent-production-ux-review.json`
- `docs/Build Plan V2/Evidence/B25/product-ux-screen-review-matrix.md`
- `app/apps/loom_communities_demo/integration_test/workflow_ui_evidence_test.dart`
- `app/apps/loom_communities_demo/test/workflow_ui_test_harness.dart`

### UX Reference Patterns To Copy

| Reference | Source | URL | What to copy |
| --- | --- | --- | --- |
| Material navigation and information architecture | Material Design 3 / design-system | https://m3.material.io/components/navigation-drawer/overview<br>Also: https://m3.material.io/components/navigation-bar/overview | Organize screens by user jobs and destinations; keep primary actions visible and avoid exposing implementation taxonomy. |
| Apple HIG navigation and content organization | Apple Human Interface Guidelines / design-system | https://developer.apple.com/design/human-interface-guidelines/navigation | Make navigation predictable, content-centered, and appropriate for the user’s current task. |
| Material Design cards and lists | Material Design 3 / design-system | https://m3.material.io/components/cards/overview<br>Also: https://m3.material.io/components/lists/overview | Use cards/lists only as scannable containers with clear hierarchy, content, metadata, and actions. Do not use repeated cards as the whole primary workflow. |
| Flutter sample app implementation patterns | flutter/samples / open-source | https://github.com/flutter/samples | Copy the separation between app shell, route state, domain widgets, and testable UI states rather than hardcoding a single generic renderer. |
| Material detail surface composition | Material Design 3 / design-system | https://m3.material.io/components/cards/overview | Build a domain detail page with primary content, metadata, status, and actions instead of a generic task card. |
| Inbox and message thread pattern | Material lists/text fields / pattern | https://m3.material.io/components/lists/overview<br>Also: https://m3.material.io/components/text-fields/overview | Copy an inbox/thread structure: sender, timestamp, message preview/body, reply field, invite/block state, and read/received state. |
| Feed item and composer pattern | Material cards/lists/text fields / pattern | https://m3.material.io/components/text-fields/overview<br>Also: https://m3.material.io/components/cards/overview<br>https://m3.material.io/components/lists/overview | Copy a feed/composer structure: audience, author, timestamp, body, attachments/status, publish action, and receiver read state. |
| Document list/detail pattern | Material lists/cards / pattern | https://m3.material.io/components/lists/overview | Copy a document library with title, category, audience, file metadata, access state, download/view action, and empty/error states. |
| Form validation and review pattern | U.S. Web Design System / design-system | https://designsystem.digital.gov/components/form/<br>Also: https://designsystem.digital.gov/components/alert/<br>https://design-system.service.gov.uk/components/error-summary/ | Copy a form flow with field labels, helper text, validation errors, review state, submit action, status, and protected-data treatment. |
| Match schedule and result pattern | Material lists/cards / pattern | https://m3.material.io/components/lists/overview | Copy a match surface with players, schedule/round, result entry, result state, and next action. |

### Reference Research Queries
- modern mobile app information architecture visual hierarchy examples
- Material Design 3 mobile UI hierarchy navigation cards examples
- open source Flutter production app dashboard detail screen examples
- community app home screen announcements events messages design examples
- open source Flutter community app home feed events messages UI
- domain specific mobile workflow UI event RSVP donation message export examples
- open source Flutter event RSVP donation messaging workflow UI examples
- open source Flutter domain-native-surface mobile UI example GitHub
- plant exchange offer form and member marketplace surface with plant details, pickup timing, owner contact, and submitted offer state mobile UX pattern
- Material Design plant exchange offer form and member marketplace surface with plant details, pickup timing, owner contact, and submitted offer state mobile pattern
- open source Flutter message-thread mobile UI example GitHub
- inbox, message thread, connection card, invite, or block-state surface mobile UX pattern
- Material Design inbox, message thread, connection card, invite, or block-state surface mobile pattern
- open source Flutter announcement-feed mobile UI example GitHub
- announcement feed/composer with audience, author, timestamp, body, and receiver state mobile UX pattern
- Material Design announcement feed/composer with audience, author, timestamp, body, and receiver state mobile pattern
- protected youth roster/profile surface with minor-data redaction, guardian visibility, and coach-only detail state mobile UX pattern
- Material Design protected youth roster/profile surface with minor-data redaction, guardian visibility, and coach-only detail state mobile pattern
- notification inbox/detail surface with sender, audience, timestamp, message body, and receiver state mobile UX pattern
- Material Design notification inbox/detail surface with sender, audience, timestamp, message body, and receiver state mobile pattern

### UI Remediation Work Items

Showing 17 of 17 work items. Full detail is in the JSON artifact.

| Work item | Stage | Community | Workflow | Persona | Screens | Coverage | Target surface | Blocked until |
| --- | --- | --- | --- | --- | ---: | ---: | --- | --- |
| `b25-wi-ui-remediation-community-garden-club-plant-exchange-submission-community-garden-club-member` | `ui-remediation` | Garden Club | `plant-exchange-submission` | member | 3 | 1 | plant exchange offer form and member marketplace surface with plant details, pickup timing, owner contact, and submitted offer state | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-book-club-book-discussion-message-community-book-club-member` | `ui-remediation` | Neighborhood Book Club | `book-discussion-message` | member | 3 | 1 | inbox, message thread, connection card, invite, or block-state surface | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-book-club-book-selection-publish-community-book-club-owner` | `ui-remediation` | Neighborhood Book Club | `book-selection-publish` | owner | 3 | 1 | announcement feed/composer with audience, author, timestamp, body, and receiver state | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-youth-soccer-soccer-minor-redaction-community-youth-soccer-guardian` | `ui-remediation` | Riverside Youth Soccer | `soccer-minor-redaction` | guardian | 3 | 1 | protected youth roster/profile surface with minor-data redaction, guardian visibility, and coach-only detail state | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-youth-soccer-soccer-reminder-notification-community-youth-soccer-guardian` | `ui-remediation` | Riverside Youth Soccer | `soccer-reminder-notification` | guardian | 3 | 1 | notification inbox/detail surface with sender, audience, timestamp, message body, and receiver state | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-hoa-hoa-member-document-community-hoa-member` | `ui-remediation` | Cedar Commons HOA | `hoa-member-document` | member | 3 | 1 | document library/detail surface with title, audience, file metadata, and access state | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-hoa-hoa-architectural-request-community-hoa-owner` | `ui-remediation` | Cedar Commons HOA | `hoa-architectural-request` | owner | 3 | 1 | request detail and admin review queue with submitted data, decision action, status, and notification | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-hoa-hoa-owner-notification-community-hoa-owner` | `ui-remediation` | Cedar Commons HOA | `hoa-owner-notification` | owner | 3 | 1 | notification inbox/detail surface with sender, audience, timestamp, message body, and receiver state | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-mosque-mosque-announcement-community-mosque-owner` | `ui-remediation` | Masjid Nur | `mosque-announcement` | owner | 3 | 1 | announcement feed/composer with audience, author, timestamp, body, and receiver state | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-mosque-mosque-donor-visibility-community-mosque-donor` | `ui-remediation` | Masjid Nur | `mosque-donor-visibility` | donor | 3 | 1 | donor privacy preference surface with visibility choice, donation context, confirmation, and receipt visibility state | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-mosque-mosque-neutral-notification-community-mosque-member` | `ui-remediation` | Masjid Nur | `mosque-neutral-notification` | member | 3 | 1 | notification inbox/detail surface with sender, audience, timestamp, message body, and receiver state | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-chess-club-chess-local-install-open-community-chess-club-member` | `ui-remediation` | Chess Club | `chess-local-install-open` | member | 3 | 1 | match schedule/result surface with players, round, outcome, and next action | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-chess-club-chess-route-home-community-chess-club-member` | `ui-remediation` | Chess Club | `chess-route-home` | member | 3 | 1 | match schedule/result surface with players, round, outcome, and next action | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-chess-club-chess-match-result-community-chess-club-member` | `ui-remediation` | Chess Club | `chess-match-result` | member | 3 | 1 | match schedule/result surface with players, round, outcome, and next action | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-camera-club-critique-submission-community-camera-club-member` | `ui-remediation` | Camera Club | `critique-submission` | member | 3 | 1 | critique submission/review surface with image/work title, comments, reviewer state, and result | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-camera-club-gear-loan-request-community-camera-club-member` | `ui-remediation` | Camera Club | `gear-loan-request` | member | 3 | 1 | request detail and admin review queue with submitted data, decision action, status, and notification | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-platform-social-platform-message-stream-community-platform-social-member` | `ui-remediation` | Member Social Space | `platform-message-stream` | member | 3 | 1 | inbox, message thread, connection card, invite, or block-state surface | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |

### UI Remediation Work Items Reference Patterns

| Reference | Source | URL | What to copy |
| --- | --- | --- | --- |
| Material detail surface composition | Material Design 3 / design-system | https://m3.material.io/components/cards/overview | Build a domain detail page with primary content, metadata, status, and actions instead of a generic task card. |
| Material Design cards and lists | Material Design 3 / design-system | https://m3.material.io/components/cards/overview<br>Also: https://m3.material.io/components/lists/overview | Use cards/lists only as scannable containers with clear hierarchy, content, metadata, and actions. Do not use repeated cards as the whole primary workflow. |
| Flutter sample app implementation patterns | flutter/samples / open-source | https://github.com/flutter/samples | Copy the separation between app shell, route state, domain widgets, and testable UI states rather than hardcoding a single generic renderer. |
| Material navigation and information architecture | Material Design 3 / design-system | https://m3.material.io/components/navigation-drawer/overview<br>Also: https://m3.material.io/components/navigation-bar/overview | Organize screens by user jobs and destinations; keep primary actions visible and avoid exposing implementation taxonomy. |
| Apple HIG navigation and content organization | Apple Human Interface Guidelines / design-system | https://developer.apple.com/design/human-interface-guidelines/navigation | Make navigation predictable, content-centered, and appropriate for the user’s current task. |
| Inbox and message thread pattern | Material lists/text fields / pattern | https://m3.material.io/components/lists/overview<br>Also: https://m3.material.io/components/text-fields/overview | Copy an inbox/thread structure: sender, timestamp, message preview/body, reply field, invite/block state, and read/received state. |
| Feed item and composer pattern | Material cards/lists/text fields / pattern | https://m3.material.io/components/text-fields/overview<br>Also: https://m3.material.io/components/cards/overview<br>https://m3.material.io/components/lists/overview | Copy a feed/composer structure: audience, author, timestamp, body, attachments/status, publish action, and receiver read state. |
| Document list/detail pattern | Material lists/cards / pattern | https://m3.material.io/components/lists/overview | Copy a document library with title, category, audience, file metadata, access state, download/view action, and empty/error states. |
| Form validation and review pattern | U.S. Web Design System / design-system | https://designsystem.digital.gov/components/form/<br>Also: https://designsystem.digital.gov/components/alert/<br>https://design-system.service.gov.uk/components/error-summary/ | Copy a form flow with field labels, helper text, validation errors, review state, submit action, status, and protected-data treatment. |
| Match schedule and result pattern | Material lists/cards / pattern | https://m3.material.io/components/lists/overview | Copy a match surface with players, schedule/round, result entry, result state, and next action. |

### Affected Coverage Rows

Showing 17 of 17 affected coverage rows.

| Coverage row | Community | Workflow | Persona | Missing evidence |
| --- | --- | --- | --- | --- |
| `b25-wp-002-plant-exchange-submission-community-garden-club-member` | Garden Club | `plant-exchange-submission` | member |  |
| `b25-wp-007-book-discussion-message-community-book-club-member` | Neighborhood Book Club | `book-discussion-message` | member |  |
| `b25-wp-008-book-selection-publish-community-book-club-owner` | Neighborhood Book Club | `book-selection-publish` | owner |  |
| `b25-wp-013-soccer-minor-redaction-community-youth-soccer-guardian` | Riverside Youth Soccer | `soccer-minor-redaction` | guardian |  |
| `b25-wp-016-soccer-reminder-notification-community-youth-soccer-guardian` | Riverside Youth Soccer | `soccer-reminder-notification` | guardian |  |
| `b25-wp-019-hoa-member-document-community-hoa-member` | Cedar Commons HOA | `hoa-member-document` | member |  |
| `b25-wp-021-hoa-architectural-request-community-hoa-owner` | Cedar Commons HOA | `hoa-architectural-request` | owner |  |
| `b25-wp-023-hoa-owner-notification-community-hoa-owner` | Cedar Commons HOA | `hoa-owner-notification` | owner |  |
| `b25-wp-025-mosque-announcement-community-mosque-owner` | Masjid Nur | `mosque-announcement` | owner |  |
| `b25-wp-028-mosque-donor-visibility-community-mosque-donor` | Masjid Nur | `mosque-donor-visibility` | donor |  |
| `b25-wp-031-mosque-neutral-notification-community-mosque-member` | Masjid Nur | `mosque-neutral-notification` | member |  |
| `b25-wp-033-chess-local-install-open-community-chess-club-member` | Chess Club | `chess-local-install-open` | member |  |
| `b25-wp-034-chess-route-home-community-chess-club-member` | Chess Club | `chess-route-home` | member |  |
| `b25-wp-035-chess-match-result-community-chess-club-member` | Chess Club | `chess-match-result` | member |  |
| `b25-wp-037-critique-submission-community-camera-club-member` | Camera Club | `critique-submission` | member |  |
| `b25-wp-038-gear-loan-request-community-camera-club-member` | Camera Club | `gear-loan-request` | member |  |
| `b25-wp-043-platform-message-stream-community-platform-social-member` | Member Social Space | `platform-message-stream` | member |  |

### Affected Screen Rows

Showing 30 of 51 affected screen rows.

| Screen row | Community | Workflow | Persona | State | Exact UX failure |
| --- | --- | --- | --- | --- | --- |
| `b25-v4-row-004-plant-exchange-submission-0` | Garden Club | `plant-exchange-submission` | member | B13_ext_garden_club_plant-exchange-submission_start | Ticket must prove the primary screen is a domain-native surface, not a generic card/checklist/metadata surface. |
| `b25-v4-row-005-plant-exchange-submission-1` | Garden Club | `plant-exchange-submission` | member | B13_ext_garden_club_plant-exchange-submission_action | Ticket must prove the primary screen is a domain-native surface, not a generic card/checklist/metadata surface. |
| `b25-v4-row-006-plant-exchange-submission-2` | Garden Club | `plant-exchange-submission` | member | B13_ext_garden_club_plant-exchange-submission_complete | Ticket must prove the primary screen is a domain-native surface, not a generic card/checklist/metadata surface. |
| `b25-v4-row-019-book-discussion-message-0` | Neighborhood Book Club | `book-discussion-message` | member | B14_ext_book_club_book-discussion-message_start | Ticket must prove the primary screen is a domain-native surface, not a generic card/checklist/metadata surface. |
| `b25-v4-row-020-book-discussion-message-1` | Neighborhood Book Club | `book-discussion-message` | member | B14_ext_book_club_book-discussion-message_action | Ticket must prove the primary screen is a domain-native surface, not a generic card/checklist/metadata surface. |
| `b25-v4-row-021-book-discussion-message-2` | Neighborhood Book Club | `book-discussion-message` | member | B14_ext_book_club_book-discussion-message_complete | Ticket must prove the primary screen is a domain-native surface, not a generic card/checklist/metadata surface. |
| `b25-v4-row-022-book-selection-publish-0` | Neighborhood Book Club | `book-selection-publish` | owner | B14_ext_book_club_book-selection-publish_start | Ticket must prove the primary screen is a domain-native surface, not a generic card/checklist/metadata surface. |
| `b25-v4-row-023-book-selection-publish-1` | Neighborhood Book Club | `book-selection-publish` | owner | B14_ext_book_club_book-selection-publish_action | Ticket must prove the primary screen is a domain-native surface, not a generic card/checklist/metadata surface. |
| `b25-v4-row-024-book-selection-publish-2` | Neighborhood Book Club | `book-selection-publish` | owner | B14_ext_book_club_book-selection-publish_complete | Ticket must prove the primary screen is a domain-native surface, not a generic card/checklist/metadata surface. |
| `b25-v4-row-037-soccer-minor-redaction-0` | Riverside Youth Soccer | `soccer-minor-redaction` | guardian | B14_ext_youth_soccer_soccer-minor-redaction_start | Ticket must prove the primary screen is a domain-native surface, not a generic card/checklist/metadata surface. |
| `b25-v4-row-038-soccer-minor-redaction-1` | Riverside Youth Soccer | `soccer-minor-redaction` | guardian | B14_ext_youth_soccer_soccer-minor-redaction_action | Ticket must prove the primary screen is a domain-native surface, not a generic card/checklist/metadata surface. |
| `b25-v4-row-039-soccer-minor-redaction-2` | Riverside Youth Soccer | `soccer-minor-redaction` | guardian | B14_ext_youth_soccer_soccer-minor-redaction_complete | Ticket must prove the primary screen is a domain-native surface, not a generic card/checklist/metadata surface. |
| `b25-v4-row-046-soccer-reminder-notification-0` | Riverside Youth Soccer | `soccer-reminder-notification` | guardian | B14_ext_youth_soccer_soccer-reminder-notification_start | Ticket must prove the primary screen is a domain-native surface, not a generic card/checklist/metadata surface. |
| `b25-v4-row-047-soccer-reminder-notification-1` | Riverside Youth Soccer | `soccer-reminder-notification` | guardian | B14_ext_youth_soccer_soccer-reminder-notification_action | Ticket must prove the primary screen is a domain-native surface, not a generic card/checklist/metadata surface. |
| `b25-v4-row-048-soccer-reminder-notification-2` | Riverside Youth Soccer | `soccer-reminder-notification` | guardian | B14_ext_youth_soccer_soccer-reminder-notification_complete | Ticket must prove the primary screen is a domain-native surface, not a generic card/checklist/metadata surface. |
| `b25-v4-row-055-hoa-member-document-0` | Cedar Commons HOA | `hoa-member-document` | member | B14_ext_hoa_hoa-member-document_start | Ticket must prove the primary screen is a domain-native surface, not a generic card/checklist/metadata surface. |
| `b25-v4-row-056-hoa-member-document-1` | Cedar Commons HOA | `hoa-member-document` | member | B14_ext_hoa_hoa-member-document_action | Ticket must prove the primary screen is a domain-native surface, not a generic card/checklist/metadata surface. |
| `b25-v4-row-057-hoa-member-document-2` | Cedar Commons HOA | `hoa-member-document` | member | B14_ext_hoa_hoa-member-document_complete | Ticket must prove the primary screen is a domain-native surface, not a generic card/checklist/metadata surface. |
| `b25-v4-row-061-hoa-architectural-request-0` | Cedar Commons HOA | `hoa-architectural-request` | owner | B14_ext_hoa_hoa-architectural-request_start | Ticket must prove the primary screen is a domain-native surface, not a generic card/checklist/metadata surface. |
| `b25-v4-row-062-hoa-architectural-request-1` | Cedar Commons HOA | `hoa-architectural-request` | owner | B14_ext_hoa_hoa-architectural-request_action | Ticket must prove the primary screen is a domain-native surface, not a generic card/checklist/metadata surface. |
| `b25-v4-row-063-hoa-architectural-request-2` | Cedar Commons HOA | `hoa-architectural-request` | owner | B14_ext_hoa_hoa-architectural-request_complete | Ticket must prove the primary screen is a domain-native surface, not a generic card/checklist/metadata surface. |
| `b25-v4-row-067-hoa-owner-notification-0` | Cedar Commons HOA | `hoa-owner-notification` | owner | B14_ext_hoa_hoa-owner-notification_start | Ticket must prove the primary screen is a domain-native surface, not a generic card/checklist/metadata surface. |
| `b25-v4-row-068-hoa-owner-notification-1` | Cedar Commons HOA | `hoa-owner-notification` | owner | B14_ext_hoa_hoa-owner-notification_action | Ticket must prove the primary screen is a domain-native surface, not a generic card/checklist/metadata surface. |
| `b25-v4-row-069-hoa-owner-notification-2` | Cedar Commons HOA | `hoa-owner-notification` | owner | B14_ext_hoa_hoa-owner-notification_complete | Ticket must prove the primary screen is a domain-native surface, not a generic card/checklist/metadata surface. |
| `b25-v4-row-073-mosque-announcement-0` | Masjid Nur | `mosque-announcement` | owner | B14_ext_mosque_mosque-announcement_start | Ticket must prove the primary screen is a domain-native surface, not a generic card/checklist/metadata surface. |
| `b25-v4-row-074-mosque-announcement-1` | Masjid Nur | `mosque-announcement` | owner | B14_ext_mosque_mosque-announcement_action | Ticket must prove the primary screen is a domain-native surface, not a generic card/checklist/metadata surface. |
| `b25-v4-row-075-mosque-announcement-2` | Masjid Nur | `mosque-announcement` | owner | B14_ext_mosque_mosque-announcement_complete | Ticket must prove the primary screen is a domain-native surface, not a generic card/checklist/metadata surface. |
| `b25-v4-row-082-mosque-donor-visibility-0` | Masjid Nur | `mosque-donor-visibility` | donor | B14_ext_mosque_mosque-donor-visibility_start | Ticket must prove the primary screen is a domain-native surface, not a generic card/checklist/metadata surface. |
| `b25-v4-row-083-mosque-donor-visibility-1` | Masjid Nur | `mosque-donor-visibility` | donor | B14_ext_mosque_mosque-donor-visibility_action | Ticket must prove the primary screen is a domain-native surface, not a generic card/checklist/metadata surface. |
| `b25-v4-row-084-mosque-donor-visibility-2` | Masjid Nur | `mosque-donor-visibility` | donor | B14_ext_mosque_mosque-donor-visibility_complete | Ticket must prove the primary screen is a domain-native surface, not a generic card/checklist/metadata surface. |

### Evidence To Update
- independent-production-ux-review.json holisticQuestionAnswers
- independent-production-ux-review.md holistic review summary
- product-ux-screen-review-matrix.md relevant screen rows
- production-ux-criteria-scorecard.json/.md
- independent-production-ux-review.json workflowPersonaScorecards
- independent-production-ux-review.json screenRows
- product-ux-screen-review-matrix.md every workflow/persona row
- Fresh holistic screenshots for primary homes, navigation, representative detail surfaces, and representative completion/result states.
- `holisticQuestionAnswers` with visible evidence, score, pass/fail answer, and specific rationale.
- Updated `production-ux-criteria-scorecard.json/.md` showing the criterion passes.
- Fresh screenshots for every primary workflow/persona surface that was replaced or reviewed.
- `workflowPersonaScorecards` with task-specific domain-native surface judgments.
- Screen matrix rows showing `primarySurfaceType` or classification is not generic for primary workflows.

### Acceptance Checks
- Holistic direct-question answers are present, screenshot-backed, non-boilerplate, and pass.
- `production_ux_judge.dart` has no blocking failure for this criterion.
- `b25_iteration_scorecard.dart` records the ticket as resolved or no longer blocking.
- Screenshots are refreshed and hashes/timestamps/app commit SHA match the reviewed app version.
- Every workflow/persona scorecard is present, screenshot-backed, non-boilerplate, and pass.

### Concrete Acceptance Criteria
- Holistic direct-question answers are present, screenshot-backed, non-boilerplate, and pass.
- `production_ux_judge.dart` has no blocking failure for this criterion.
- `b25_iteration_scorecard.dart` records the ticket as resolved or no longer blocking.
- Screenshots are refreshed and hashes/timestamps/app commit SHA match the reviewed app version.
- Every workflow/persona scorecard is present, screenshot-backed, non-boilerplate, and pass.
- Screen row `b25-v4-row-004-plant-exchange-submission-0` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-004-plant-exchange-submission-0` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-004-plant-exchange-submission-0` names visible UI elements, visible text, persona `member`, workflow `plant-exchange-submission`, and the exact product UX issue.
- Primary surface for `plant-exchange-submission` is documented as `plant exchange offer form and member marketplace surface with plant details, pickup timing, owner contact, and submitted offer state` or another explicit domain-native surface.
- After-screenshot visible text proves every required semantic surface group for `plant-exchange-submission`.
- Fresh screenshot path/hash/timestamp/app commit SHA are recorded after the fix.
- The workflow/persona direct-question scorecard passes the domain-native primary surface question.
- Screen row `b25-v4-row-005-plant-exchange-submission-1` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-005-plant-exchange-submission-1` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-005-plant-exchange-submission-1` names visible UI elements, visible text, persona `member`, workflow `plant-exchange-submission`, and the exact product UX issue.
- Screen row `b25-v4-row-006-plant-exchange-submission-2` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-006-plant-exchange-submission-2` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-006-plant-exchange-submission-2` names visible UI elements, visible text, persona `member`, workflow `plant-exchange-submission`, and the exact product UX issue.
- Screen row `b25-v4-row-019-book-discussion-message-0` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-019-book-discussion-message-0` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-019-book-discussion-message-0` names visible UI elements, visible text, persona `member`, workflow `book-discussion-message`, and the exact product UX issue.
- Primary surface for `book-discussion-message` is documented as `inbox, message thread, connection card, invite, or block-state surface` or another explicit domain-native surface.
- After-screenshot visible text proves every required semantic surface group for `book-discussion-message`.
- Screen row `b25-v4-row-020-book-discussion-message-1` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-020-book-discussion-message-1` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-020-book-discussion-message-1` names visible UI elements, visible text, persona `member`, workflow `book-discussion-message`, and the exact product UX issue.
- Screen row `b25-v4-row-021-book-discussion-message-2` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-021-book-discussion-message-2` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-021-book-discussion-message-2` names visible UI elements, visible text, persona `member`, workflow `book-discussion-message`, and the exact product UX issue.
- Screen row `b25-v4-row-022-book-selection-publish-0` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-022-book-selection-publish-0` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-022-book-selection-publish-0` names visible UI elements, visible text, persona `owner`, workflow `book-selection-publish`, and the exact product UX issue.
- Primary surface for `book-selection-publish` is documented as `announcement feed/composer with audience, author, timestamp, body, and receiver state` or another explicit domain-native surface.
- After-screenshot visible text proves every required semantic surface group for `book-selection-publish`.
- Screen row `b25-v4-row-023-book-selection-publish-1` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-023-book-selection-publish-1` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-023-book-selection-publish-1` names visible UI elements, visible text, persona `owner`, workflow `book-selection-publish`, and the exact product UX issue.
- Screen row `b25-v4-row-024-book-selection-publish-2` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-024-book-selection-publish-2` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-024-book-selection-publish-2` names visible UI elements, visible text, persona `owner`, workflow `book-selection-publish`, and the exact product UX issue.

### Rerun Commands
- `dart run packages/tooling/loom_ux_judges/bin/b25_evidence_collector.dart --evidence-root ../docs/Build\ Plan\ V2/Evidence --repo-root .. --run-id <next-run-id> --prior-review ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --output ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.md --matrix-output ../docs/Build\ Plan\ V2/Evidence/B25/product-ux-screen-review-matrix.md`
- `dart run packages/tooling/loom_ux_judges/bin/b25_workflow_persona_coverage_collector.dart --input ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --output ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/workflow-persona-coverage-matrix.md`
- `dart run packages/tooling/loom_ux_judges/bin/b25_independent_ux_judge.dart --input ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --output ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.md --matrix-output ../docs/Build\ Plan\ V2/Evidence/B25/product-ux-screen-review-matrix.md`
- `dart run packages/tooling/loom_ux_judges/bin/production_ux_judge.dart --input ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --base .. --output ../docs/Build\ Plan\ V2/Evidence/B25/production-ux-criteria-scorecard.json --markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/production-ux-criteria-scorecard.md --tickets-output ../docs/Build\ Plan\ V2/Evidence/B25/b25-remediation-tickets-<next-run-id>.json --tickets-markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/b25-remediation-tickets-<next-run-id>.md`
- `dart run packages/tooling/loom_ux_judges/bin/b25_iteration_scorecard.dart --review ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --judge ../docs/Build\ Plan\ V2/Evidence/B25/production-ux-criteria-scorecard.json --previous ../docs/Build\ Plan\ V2/Evidence/B25/b25-iteration-scorecard-latest.json --output ../docs/Build\ Plan\ V2/Evidence/B25/b25-iteration-scorecard-latest.json --markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/b25-iteration-scorecard-latest.md`

### Commit Boundary

Commit this remediation batch, refreshed evidence, judge outputs, scorecards, and tracker updates before the next UX feedback loop. If the committed pass still fails, the following pass starts by sending its tickets to the Remediation Planner.

## B25-RB-003-recapture-rerun-closeout: Recapture evidence, rerun judges, and close resolved tickets

Prove the remediation with fresh screenshots, scorecards, and a committed iteration boundary.

| Field | Value |
| --- | --- |
| Status | open |
| Ticket IDs | B25-RT-001-b25-c01-no-blocker-major, B25-RT-002-b25-c02-community-product-docs-complete, B25-RT-003-b25-c03-production-grade-experience, B25-RT-004-b25-c04-modern-intentional-ui, B25-RT-005-b25-c05-community-content-ia, B25-RT-006-b25-c06-domain-native-primary-surfaces, B25-RT-007-b25-c13-workflow-lifecycle-complete, B25-RT-008-b25-c08-visible-text-specific-critique, B25-RT-009-b25-c09-no-layout-production-defects |

### Worker Actions
- Rebuild and relaunch the Demo App on the reviewed emulator/device.
- Recapture affected screenshots with hashes, timestamps, device metadata, and app commit SHA.
- Regenerate B25 schema v4 review JSON, markdown review, screen matrix, remediation tickets, and iteration scorecard.
- Commit the full iteration before starting the next UX feedback loop.

### Implementation Guidance
- Use each open remediation ticket as the implementation backlog.
- Update review JSON, remediation log, scorecards, tracker, and screenshots together.
- Product doc coverage rows for every reviewed community/test app.
- Updated Product Docs V2 community experience docs with hashes, paths, required sections, and no placeholders.
- B25 review/remediation log entries showing the current screenshots will be judged against each product spec.
- Inspect `apps/loom_communities_demo/lib` for the primary community home, shell, card, detail, and workflow surface widgets.
- Compare every change against `docs/Build Plan V2/Evidence/B25/production-ux-blueprint.md` before coding.
- Update widget tests and B25 evidence expectations when user-facing hierarchy, copy, or surface structure changes.
- Inspect workflow surface builders and replace primary generic card/checklist/modal renderers with task-specific widgets.
- Use B21 production UX contracts to choose the target surface type for each workflow/persona pair.
- Update screenshot evidence manifests so each replaced surface is captured at entry, action, and result states.
- Inspect workflow surface builders and identify where current UI collapses lifecycle into a single action card.
- For each failed lifecycle scorecard, implement missing object/context, decision data, primary and alternate actions, result/receipt/status, and receiver/continuation state.
- Update product docs, seed data, widget tests, and B25 evidence expectations so the lifecycle is documented and screenshot-proven.
- Update the B25 judge/review artifact, not only app UI code.
- Fill `screenRows[].visibleTextExtract`, `screenRows[].screenSpecificCritique`, `holisticQuestionAnswers`, and `workflowPersonaScorecards` with screenshot-specific content.
- Regenerate markdown review and matrix files from the updated schema v4 JSON.

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
- `docs/Product Docs V2/Community Examples/`
- `docs/Build Plan V2/Skill/references/community-product-experience-template.md`
- `app/packages/tooling/loom_ux_judges/lib/loom_ux_judges.dart`
- `docs/Build Plan V2/Evidence/B25/independent-production-ux-review.md`

### UX Reference Patterns To Copy

| Reference | Source | URL | What to copy |
| --- | --- | --- | --- |
| Material navigation and information architecture | Material Design 3 / design-system | https://m3.material.io/components/navigation-drawer/overview<br>Also: https://m3.material.io/components/navigation-bar/overview | Organize screens by user jobs and destinations; keep primary actions visible and avoid exposing implementation taxonomy. |
| Apple HIG navigation and content organization | Apple Human Interface Guidelines / design-system | https://developer.apple.com/design/human-interface-guidelines/navigation | Make navigation predictable, content-centered, and appropriate for the user’s current task. |
| Material Design cards and lists | Material Design 3 / design-system | https://m3.material.io/components/cards/overview<br>Also: https://m3.material.io/components/lists/overview | Use cards/lists only as scannable containers with clear hierarchy, content, metadata, and actions. Do not use repeated cards as the whole primary workflow. |
| Flutter sample app implementation patterns | flutter/samples / open-source | https://github.com/flutter/samples | Copy the separation between app shell, route state, domain widgets, and testable UI states rather than hardcoding a single generic renderer. |
| Event detail and RSVP flow | Material cards/lists/buttons / pattern | https://m3.material.io/components/cards/overview<br>Also: https://m3.material.io/components/buttons/overview<br>https://m3.material.io/components/chips/overview | Copy an event detail layout: title, date/time, location, host, capacity/status chip, attendee context, RSVP action, and confirmation state. |
| Material detail surface composition | Material Design 3 / design-system | https://m3.material.io/components/cards/overview | Build a domain detail page with primary content, metadata, status, and actions instead of a generic task card. |
| Task list and export wizard | GOV.UK Design System / design-system | https://design-system.service.gov.uk/components/task-list/<br>Also: https://design-system.service.gov.uk/patterns/check-answers/ | Copy a wizard with steps, preview, redaction choices, checksum evidence, transfer status, and rollback confirmation. |
| Selection and voting pattern | Material chips/cards/buttons / pattern | https://m3.material.io/components/chips/overview<br>Also: https://m3.material.io/components/cards/overview | Copy a nomination/voting surface with choices, current vote state, deadline, selected result, and meeting/discussion context. |
| Inbox and message thread pattern | Material lists/text fields / pattern | https://m3.material.io/components/lists/overview<br>Also: https://m3.material.io/components/text-fields/overview | Copy an inbox/thread structure: sender, timestamp, message preview/body, reply field, invite/block state, and read/received state. |
| Feed item and composer pattern | Material cards/lists/text fields / pattern | https://m3.material.io/components/text-fields/overview<br>Also: https://m3.material.io/components/cards/overview<br>https://m3.material.io/components/lists/overview | Copy a feed/composer structure: audience, author, timestamp, body, attachments/status, publish action, and receiver read state. |
| Search and result list pattern | Material Design 3 / design-system | https://m3.material.io/components/search/overview<br>Also: https://m3.material.io/components/lists/overview | Copy a search layout with query, filters, ranked results, citations/sources, empty/error states, and follow-up actions. |
| Form validation and review pattern | U.S. Web Design System / design-system | https://designsystem.digital.gov/components/form/<br>Also: https://designsystem.digital.gov/components/alert/<br>https://design-system.service.gov.uk/components/error-summary/ | Copy a form flow with field labels, helper text, validation errors, review state, submit action, status, and protected-data treatment. |
| Roster/list with protected details | Material Design 3 / design-system | https://m3.material.io/components/data-tables/overview<br>Also: https://m3.material.io/components/lists/overview | Copy a roster with member names, roles, status, role-filtered fields, and clear protected-data redaction. |
| Review-and-confirm payment flow | GOV.UK Design System / design-system | https://design-system.service.gov.uk/patterns/check-answers/ | Use a review/confirmation step with amount, payer context, recipient, fees or entitlement, receipt, and audit trail. |
| Multi-step payment/progress flow | U.S. Web Design System / design-system | https://designsystem.digital.gov/components/step-indicator/ | Use explicit progress states for checkout, review, confirmation, receipt, and entitlement/status. |
| Document list/detail pattern | Material lists/cards / pattern | https://m3.material.io/components/lists/overview | Copy a document library with title, category, audience, file metadata, access state, download/view action, and empty/error states. |
| Reservation detail and availability flow | Material cards/forms / pattern | https://m3.material.io/components/date-pickers/overview<br>Also: https://m3.material.io/components/cards/overview | Copy an availability/reservation flow with facility details, date/time, capacity/rules, payment/status when needed, and confirmation. |
| Match schedule and result pattern | Material lists/cards / pattern | https://m3.material.io/components/lists/overview | Copy a match surface with players, schedule/round, result entry, result state, and next action. |
| Screenshot-first critique method | B25 production UX gate / methodology | docs/Build Plan V2/Tools/b25-remediation-ticket-template.md | Critique must quote visible UI/text, name the persona and task, compare against the chosen reference pattern, and state the exact fix. |

### Reference Research Queries
- production mobile UX review screenshot critique examples
- open source Flutter mobile app UX patterns GitHub
- open source Flutter event-rsvp mobile UI example GitHub
- event detail with schedule, location, capacity/status, RSVP action, and result state mobile UX pattern
- Material Design event detail with schedule, location, capacity/status, RSVP action, and result state mobile pattern
- open source Flutter domain-native-surface mobile UI example GitHub
- plant exchange offer form and member marketplace surface with plant details, pickup timing, owner contact, and submitted offer state mobile UX pattern
- Material Design plant exchange offer form and member marketplace surface with plant details, pickup timing, owner contact, and submitted offer state mobile pattern
- open source Flutter export-wizard mobile UI example GitHub
- export/import wizard with preview, redaction, checksum, transfer status, and rollback state mobile UX pattern
- Material Design export/import wizard with preview, redaction, checksum, transfer status, and rollback state mobile pattern
- open source Flutter voting-selection mobile UI example GitHub
- book club reading/voting surface with nominations, vote state, selected book, meeting context, and discussion mobile UX pattern
- Material Design book club reading/voting surface with nominations, vote state, selected book, meeting context, and discussion mobile pattern
- open source Flutter message-thread mobile UI example GitHub
- inbox, message thread, connection card, invite, or block-state surface mobile UX pattern
- Material Design inbox, message thread, connection card, invite, or block-state surface mobile pattern
- open source Flutter announcement-feed mobile UI example GitHub
- announcement feed/composer with audience, author, timestamp, body, and receiver state mobile UX pattern
- Material Design announcement feed/composer with audience, author, timestamp, body, and receiver state mobile pattern

### Product Spec Repair Work Items

Showing 11 of 11 work items. Full detail is in the JSON artifact.

| Work item | Stage | Community | Workflow | Persona | Screens | Coverage | Target surface | Blocked until |
| --- | --- | --- | --- | --- | ---: | ---: | --- | --- |
| `b25-wi-product-spec-interaction-model-garden-club` | `product-spec-update` | Garden Club | `garden-event-rsvp, plant-exchange-submission, garden-export-custom-schemas` | product-experience-steward | 9 | 3 | community product experience spec with semantic interaction models | the product doc defines expected decision, required actions, result state, and receiver/continuation state for each failing workflow |
| `b25-wi-product-spec-interaction-model-neighborhood-book-club` | `product-spec-update` | Neighborhood Book Club | `book-nomination, book-vote, book-meeting-rsvp, book-discussion-message, book-selection-publish, book-search-ai-digest, book-export-metadata` | product-experience-steward | 21 | 7 | community product experience spec with semantic interaction models | the product doc defines expected decision, required actions, result state, and receiver/continuation state for each failing workflow |
| `b25-wi-product-spec-interaction-model-riverside-youth-soccer` | `product-spec-update` | Riverside Youth Soccer | `soccer-guardian-join-approval, soccer-team-roster, soccer-minor-redaction, soccer-registration-payment, soccer-practice-schedule, soccer-reminder-notification, soccer-export-metadata` | product-experience-steward | 21 | 7 | community product experience spec with semantic interaction models | the product doc defines expected decision, required actions, result state, and receiver/continuation state for each failing workflow |
| `b25-wi-product-spec-interaction-model-cedar-commons-hoa` | `product-spec-update` | Cedar Commons HOA | `hoa-dues-payment, hoa-member-document, hoa-facility-reservation, hoa-architectural-request, hoa-committee-decision, hoa-owner-notification, hoa-export-evidence` | product-experience-steward | 21 | 7 | community product experience spec with semantic interaction models | the product doc defines expected decision, required actions, result state, and receiver/continuation state for each failing workflow |
| `b25-wi-product-spec-interaction-model-masjid-nur` | `product-spec-update` | Masjid Nur | `mosque-announcement, mosque-event-rsvp, mosque-volunteer-signup, mosque-donor-visibility, mosque-donation-payment, mosque-care-request, mosque-neutral-notification, mosque-search-ai-citation` | product-experience-steward | 34 | 13 | community product experience spec with semantic interaction models | the product doc defines expected decision, required actions, result state, and receiver/continuation state for each failing workflow |
| `b25-wi-product-spec-interaction-model-chess-club` | `product-spec-update` | Chess Club | `chess-local-install-open, chess-route-home, chess-match-result` | product-experience-steward | 9 | 3 | community product experience spec with semantic interaction models | the product doc defines expected decision, required actions, result state, and receiver/continuation state for each failing workflow |
| `b25-wi-product-spec-interaction-model-camera-club` | `product-spec-update` | Camera Club | `photo-walk-rsvp, critique-submission, gear-loan-request` | product-experience-steward | 9 | 3 | community product experience spec with semantic interaction models | the product doc defines expected decision, required actions, result state, and receiver/continuation state for each failing workflow |
| `b25-wi-product-spec-interaction-model-platform-social` | `product-spec-update` | Member Social Space | `platform-messages-entry, platform-connections-entry, platform-connection-invite, platform-blocked-target, platform-message-stream, platform-sensitive-no-fill` | product-experience-steward | 18 | 6 | community product experience spec with semantic interaction models | the product doc defines expected decision, required actions, result state, and receiver/continuation state for each failing workflow |
| `b25-wi-product-spec-interaction-model-ad-off` | `product-spec-update` | Ad-Free Community | `ad-off-member-checkout, ad-off-community-checkout, ad-off-entitlement-status, ad-off-receipt-evidence, ad-off-ad-suppression, ad-off-settlement-utility` | product-experience-steward | 18 | 6 | community product experience spec with semantic interaction models | the product doc defines expected decision, required actions, result state, and receiver/continuation state for each failing workflow |
| `b25-wi-product-spec-interaction-model-export-and-migration` | `product-spec-update` | Data Portability Community | `export-import-preview, export-import-replay, export-protected-redaction, export-schema-listing, export-full-bundle` | product-experience-steward | 15 | 5 | community product experience spec with semantic interaction models | the product doc defines expected decision, required actions, result state, and receiver/continuation state for each failing workflow |
| `b25-wi-product-spec-interaction-model-persona-role-inventory` | `product-spec-update` | persona-role-inventory | `wf_persona-role-inventory-capability-matrix` | product-experience-steward | 2 | 2 | community product experience spec with semantic interaction models | the product doc defines expected decision, required actions, result state, and receiver/continuation state for each failing workflow |

### Evidence Repair Work Items

Showing 30 of 62 work items. Full detail is in the JSON artifact.

| Work item | Stage | Community | Workflow | Persona | Screens | Coverage | Target surface | Blocked until |
| --- | --- | --- | --- | --- | ---: | ---: | --- | --- |
| `b25-wi-evidence-repair-community-garden-club-plant-exchange-submission-community-garden-club-member` | `evidence-repair` | Garden Club | `plant-exchange-submission` | member | 3 | 1 | plant exchange offer form and member marketplace surface with plant details, pickup timing, owner contact, and submitted offer state |  |
| `b25-wi-evidence-repair-community-book-club-book-discussion-message-community-book-club-member` | `evidence-repair` | Neighborhood Book Club | `book-discussion-message` | member | 3 | 1 | inbox, message thread, connection card, invite, or block-state surface |  |
| `b25-wi-evidence-repair-community-book-club-book-selection-publish-community-book-club-owner` | `evidence-repair` | Neighborhood Book Club | `book-selection-publish` | owner | 3 | 1 | announcement feed/composer with audience, author, timestamp, body, and receiver state |  |
| `b25-wi-evidence-repair-community-youth-soccer-soccer-minor-redaction-community-youth-soccer-guardian` | `evidence-repair` | Riverside Youth Soccer | `soccer-minor-redaction` | guardian | 3 | 1 | protected youth roster/profile surface with minor-data redaction, guardian visibility, and coach-only detail state |  |
| `b25-wi-evidence-repair-community-youth-soccer-soccer-reminder-notification-community-youth-soccer-guardian` | `evidence-repair` | Riverside Youth Soccer | `soccer-reminder-notification` | guardian | 3 | 1 | notification inbox/detail surface with sender, audience, timestamp, message body, and receiver state |  |
| `b25-wi-evidence-repair-community-hoa-hoa-member-document-community-hoa-member` | `evidence-repair` | Cedar Commons HOA | `hoa-member-document` | member | 3 | 1 | document library/detail surface with title, audience, file metadata, and access state |  |
| `b25-wi-evidence-repair-community-hoa-hoa-architectural-request-community-hoa-owner` | `evidence-repair` | Cedar Commons HOA | `hoa-architectural-request` | owner | 3 | 1 | request detail and admin review queue with submitted data, decision action, status, and notification |  |
| `b25-wi-evidence-repair-community-hoa-hoa-owner-notification-community-hoa-owner` | `evidence-repair` | Cedar Commons HOA | `hoa-owner-notification` | owner | 3 | 1 | notification inbox/detail surface with sender, audience, timestamp, message body, and receiver state |  |
| `b25-wi-evidence-repair-community-mosque-mosque-announcement-community-mosque-owner` | `evidence-repair` | Masjid Nur | `mosque-announcement` | owner | 3 | 1 | announcement feed/composer with audience, author, timestamp, body, and receiver state |  |
| `b25-wi-evidence-repair-community-mosque-mosque-donor-visibility-community-mosque-donor` | `evidence-repair` | Masjid Nur | `mosque-donor-visibility` | donor | 3 | 1 | donor privacy preference surface with visibility choice, donation context, confirmation, and receipt visibility state |  |
| `b25-wi-evidence-repair-community-mosque-mosque-neutral-notification-community-mosque-member` | `evidence-repair` | Masjid Nur | `mosque-neutral-notification` | member | 3 | 1 | notification inbox/detail surface with sender, audience, timestamp, message body, and receiver state |  |
| `b25-wi-evidence-repair-community-chess-club-chess-local-install-open-community-chess-club-member` | `evidence-repair` | Chess Club | `chess-local-install-open` | member | 3 | 1 | match schedule/result surface with players, round, outcome, and next action |  |
| `b25-wi-evidence-repair-community-chess-club-chess-route-home-community-chess-club-member` | `evidence-repair` | Chess Club | `chess-route-home` | member | 3 | 1 | match schedule/result surface with players, round, outcome, and next action |  |
| `b25-wi-evidence-repair-community-chess-club-chess-match-result-community-chess-club-member` | `evidence-repair` | Chess Club | `chess-match-result` | member | 3 | 1 | match schedule/result surface with players, round, outcome, and next action |  |
| `b25-wi-evidence-repair-community-camera-club-critique-submission-community-camera-club-member` | `evidence-repair` | Camera Club | `critique-submission` | member | 3 | 1 | critique submission/review surface with image/work title, comments, reviewer state, and result |  |
| `b25-wi-evidence-repair-community-camera-club-gear-loan-request-community-camera-club-member` | `evidence-repair` | Camera Club | `gear-loan-request` | member | 3 | 1 | request detail and admin review queue with submitted data, decision action, status, and notification |  |
| `b25-wi-evidence-repair-community-platform-social-platform-message-stream-community-platform-social-member` | `evidence-repair` | Member Social Space | `platform-message-stream` | member | 3 | 1 | inbox, message thread, connection card, invite, or block-state surface |  |
| `b25-wi-evidence-repair-community-garden-club-garden-event-rsvp-community-garden-club-member` | `evidence-repair` | Garden Club | `garden-event-rsvp` | member | 3 | 1 | event detail with schedule, location, capacity/status, RSVP action, and result state |  |
| `b25-wi-evidence-repair-community-garden-club-garden-export-custom-schemas-community-garden-club-owner` | `evidence-repair` | Garden Club | `garden-export-custom-schemas` | owner | 3 | 1 | export/import wizard with preview, redaction, checksum, transfer status, and rollback state |  |
| `b25-wi-evidence-repair-community-book-club-book-nomination-community-book-club-member` | `evidence-repair` | Neighborhood Book Club | `book-nomination` | member | 3 | 1 | book club reading/voting surface with nominations, vote state, selected book, meeting context, and discussion |  |
| `b25-wi-evidence-repair-community-book-club-book-vote-community-book-club-member` | `evidence-repair` | Neighborhood Book Club | `book-vote` | member | 3 | 1 | book club reading/voting surface with nominations, vote state, selected book, meeting context, and discussion |  |
| `b25-wi-evidence-repair-community-book-club-book-meeting-rsvp-community-book-club-member` | `evidence-repair` | Neighborhood Book Club | `book-meeting-rsvp` | member | 3 | 1 | event detail with schedule, location, capacity/status, RSVP action, and result state |  |
| `b25-wi-evidence-repair-community-book-club-book-search-ai-digest-community-book-club-member` | `evidence-repair` | Neighborhood Book Club | `book-search-ai-digest` | member | 3 | 1 | search/AI answer surface with query, result, citation, source, and follow-up action |  |
| `b25-wi-evidence-repair-community-book-club-book-export-metadata-community-book-club-owner` | `evidence-repair` | Neighborhood Book Club | `book-export-metadata` | owner | 3 | 1 | export/import wizard with preview, redaction, checksum, transfer status, and rollback state |  |
| `b25-wi-evidence-repair-community-youth-soccer-soccer-guardian-join-approval-community-youth-soccer-guardian` | `evidence-repair` | Riverside Youth Soccer | `soccer-guardian-join-approval` | guardian | 3 | 1 | request detail and admin review queue with submitted data, decision action, status, and notification |  |
| `b25-wi-evidence-repair-community-youth-soccer-soccer-team-roster-community-youth-soccer-coach` | `evidence-repair` | Riverside Youth Soccer | `soccer-team-roster` | coach | 3 | 1 | team roster/schedule surface with role-filtered member details and protected-data treatment |  |
| `b25-wi-evidence-repair-community-youth-soccer-soccer-registration-payment-community-youth-soccer-guardian` | `evidence-repair` | Riverside Youth Soccer | `soccer-registration-payment` | guardian | 3 | 1 | payment or donation flow with amount, payer context, receipt, entitlement/status, and audit trail |  |
| `b25-wi-evidence-repair-community-youth-soccer-soccer-practice-schedule-community-youth-soccer-guardian` | `evidence-repair` | Riverside Youth Soccer | `soccer-practice-schedule` | guardian | 3 | 1 | event detail with schedule, location, capacity/status, RSVP action, and result state |  |
| `b25-wi-evidence-repair-community-youth-soccer-soccer-export-metadata-community-youth-soccer-owner` | `evidence-repair` | Riverside Youth Soccer | `soccer-export-metadata` | owner | 3 | 1 | export/import wizard with preview, redaction, checksum, transfer status, and rollback state |  |
| `b25-wi-evidence-repair-community-hoa-hoa-dues-payment-community-hoa-member` | `evidence-repair` | Cedar Commons HOA | `hoa-dues-payment` | member | 3 | 1 | payment or donation flow with amount, payer context, receipt, entitlement/status, and audit trail |  |

### Evidence Repair Work Items Reference Patterns

| Reference | Source | URL | What to copy |
| --- | --- | --- | --- |
| Material detail surface composition | Material Design 3 / design-system | https://m3.material.io/components/cards/overview | Build a domain detail page with primary content, metadata, status, and actions instead of a generic task card. |
| Material Design cards and lists | Material Design 3 / design-system | https://m3.material.io/components/cards/overview<br>Also: https://m3.material.io/components/lists/overview | Use cards/lists only as scannable containers with clear hierarchy, content, metadata, and actions. Do not use repeated cards as the whole primary workflow. |
| Flutter sample app implementation patterns | flutter/samples / open-source | https://github.com/flutter/samples | Copy the separation between app shell, route state, domain widgets, and testable UI states rather than hardcoding a single generic renderer. |
| Material navigation and information architecture | Material Design 3 / design-system | https://m3.material.io/components/navigation-drawer/overview<br>Also: https://m3.material.io/components/navigation-bar/overview | Organize screens by user jobs and destinations; keep primary actions visible and avoid exposing implementation taxonomy. |
| Apple HIG navigation and content organization | Apple Human Interface Guidelines / design-system | https://developer.apple.com/design/human-interface-guidelines/navigation | Make navigation predictable, content-centered, and appropriate for the user’s current task. |
| Inbox and message thread pattern | Material lists/text fields / pattern | https://m3.material.io/components/lists/overview<br>Also: https://m3.material.io/components/text-fields/overview | Copy an inbox/thread structure: sender, timestamp, message preview/body, reply field, invite/block state, and read/received state. |
| Feed item and composer pattern | Material cards/lists/text fields / pattern | https://m3.material.io/components/text-fields/overview<br>Also: https://m3.material.io/components/cards/overview<br>https://m3.material.io/components/lists/overview | Copy a feed/composer structure: audience, author, timestamp, body, attachments/status, publish action, and receiver read state. |
| Document list/detail pattern | Material lists/cards / pattern | https://m3.material.io/components/lists/overview | Copy a document library with title, category, audience, file metadata, access state, download/view action, and empty/error states. |
| Form validation and review pattern | U.S. Web Design System / design-system | https://designsystem.digital.gov/components/form/<br>Also: https://designsystem.digital.gov/components/alert/<br>https://design-system.service.gov.uk/components/error-summary/ | Copy a form flow with field labels, helper text, validation errors, review state, submit action, status, and protected-data treatment. |
| Match schedule and result pattern | Material lists/cards / pattern | https://m3.material.io/components/lists/overview | Copy a match surface with players, schedule/round, result entry, result state, and next action. |
| Event detail and RSVP flow | Material cards/lists/buttons / pattern | https://m3.material.io/components/cards/overview<br>Also: https://m3.material.io/components/buttons/overview<br>https://m3.material.io/components/chips/overview | Copy an event detail layout: title, date/time, location, host, capacity/status chip, attendee context, RSVP action, and confirmation state. |
| Task list and export wizard | GOV.UK Design System / design-system | https://design-system.service.gov.uk/components/task-list/<br>Also: https://design-system.service.gov.uk/patterns/check-answers/ | Copy a wizard with steps, preview, redaction choices, checksum evidence, transfer status, and rollback confirmation. |

### UI Remediation Work Items

Showing 30 of 62 work items. Full detail is in the JSON artifact.

| Work item | Stage | Community | Workflow | Persona | Screens | Coverage | Target surface | Blocked until |
| --- | --- | --- | --- | --- | ---: | ---: | --- | --- |
| `b25-wi-ui-remediation-community-garden-club-plant-exchange-submission-community-garden-club-member` | `ui-remediation` | Garden Club | `plant-exchange-submission` | member | 3 | 1 | plant exchange offer form and member marketplace surface with plant details, pickup timing, owner contact, and submitted offer state | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-book-club-book-discussion-message-community-book-club-member` | `ui-remediation` | Neighborhood Book Club | `book-discussion-message` | member | 3 | 1 | inbox, message thread, connection card, invite, or block-state surface | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-book-club-book-selection-publish-community-book-club-owner` | `ui-remediation` | Neighborhood Book Club | `book-selection-publish` | owner | 3 | 1 | announcement feed/composer with audience, author, timestamp, body, and receiver state | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-youth-soccer-soccer-minor-redaction-community-youth-soccer-guardian` | `ui-remediation` | Riverside Youth Soccer | `soccer-minor-redaction` | guardian | 3 | 1 | protected youth roster/profile surface with minor-data redaction, guardian visibility, and coach-only detail state | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-youth-soccer-soccer-reminder-notification-community-youth-soccer-guardian` | `ui-remediation` | Riverside Youth Soccer | `soccer-reminder-notification` | guardian | 3 | 1 | notification inbox/detail surface with sender, audience, timestamp, message body, and receiver state | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-hoa-hoa-member-document-community-hoa-member` | `ui-remediation` | Cedar Commons HOA | `hoa-member-document` | member | 3 | 1 | document library/detail surface with title, audience, file metadata, and access state | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-hoa-hoa-architectural-request-community-hoa-owner` | `ui-remediation` | Cedar Commons HOA | `hoa-architectural-request` | owner | 3 | 1 | request detail and admin review queue with submitted data, decision action, status, and notification | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-hoa-hoa-owner-notification-community-hoa-owner` | `ui-remediation` | Cedar Commons HOA | `hoa-owner-notification` | owner | 3 | 1 | notification inbox/detail surface with sender, audience, timestamp, message body, and receiver state | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-mosque-mosque-announcement-community-mosque-owner` | `ui-remediation` | Masjid Nur | `mosque-announcement` | owner | 3 | 1 | announcement feed/composer with audience, author, timestamp, body, and receiver state | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-mosque-mosque-donor-visibility-community-mosque-donor` | `ui-remediation` | Masjid Nur | `mosque-donor-visibility` | donor | 3 | 1 | donor privacy preference surface with visibility choice, donation context, confirmation, and receipt visibility state | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-mosque-mosque-neutral-notification-community-mosque-member` | `ui-remediation` | Masjid Nur | `mosque-neutral-notification` | member | 3 | 1 | notification inbox/detail surface with sender, audience, timestamp, message body, and receiver state | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-chess-club-chess-local-install-open-community-chess-club-member` | `ui-remediation` | Chess Club | `chess-local-install-open` | member | 3 | 1 | match schedule/result surface with players, round, outcome, and next action | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-chess-club-chess-route-home-community-chess-club-member` | `ui-remediation` | Chess Club | `chess-route-home` | member | 3 | 1 | match schedule/result surface with players, round, outcome, and next action | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-chess-club-chess-match-result-community-chess-club-member` | `ui-remediation` | Chess Club | `chess-match-result` | member | 3 | 1 | match schedule/result surface with players, round, outcome, and next action | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-camera-club-critique-submission-community-camera-club-member` | `ui-remediation` | Camera Club | `critique-submission` | member | 3 | 1 | critique submission/review surface with image/work title, comments, reviewer state, and result | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-camera-club-gear-loan-request-community-camera-club-member` | `ui-remediation` | Camera Club | `gear-loan-request` | member | 3 | 1 | request detail and admin review queue with submitted data, decision action, status, and notification | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-platform-social-platform-message-stream-community-platform-social-member` | `ui-remediation` | Member Social Space | `platform-message-stream` | member | 3 | 1 | inbox, message thread, connection card, invite, or block-state surface | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-garden-club-garden-event-rsvp-community-garden-club-member` | `ui-remediation` | Garden Club | `garden-event-rsvp` | member | 3 | 1 | event detail with schedule, location, capacity/status, RSVP action, and result state | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-garden-club-garden-export-custom-schemas-community-garden-club-owner` | `ui-remediation` | Garden Club | `garden-export-custom-schemas` | owner | 3 | 1 | export/import wizard with preview, redaction, checksum, transfer status, and rollback state | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-book-club-book-nomination-community-book-club-member` | `ui-remediation` | Neighborhood Book Club | `book-nomination` | member | 3 | 1 | book club reading/voting surface with nominations, vote state, selected book, meeting context, and discussion | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-book-club-book-vote-community-book-club-member` | `ui-remediation` | Neighborhood Book Club | `book-vote` | member | 3 | 1 | book club reading/voting surface with nominations, vote state, selected book, meeting context, and discussion | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-book-club-book-meeting-rsvp-community-book-club-member` | `ui-remediation` | Neighborhood Book Club | `book-meeting-rsvp` | member | 3 | 1 | event detail with schedule, location, capacity/status, RSVP action, and result state | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-book-club-book-search-ai-digest-community-book-club-member` | `ui-remediation` | Neighborhood Book Club | `book-search-ai-digest` | member | 3 | 1 | search/AI answer surface with query, result, citation, source, and follow-up action | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-book-club-book-export-metadata-community-book-club-owner` | `ui-remediation` | Neighborhood Book Club | `book-export-metadata` | owner | 3 | 1 | export/import wizard with preview, redaction, checksum, transfer status, and rollback state | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-youth-soccer-soccer-guardian-join-approval-community-youth-soccer-guardian` | `ui-remediation` | Riverside Youth Soccer | `soccer-guardian-join-approval` | guardian | 3 | 1 | request detail and admin review queue with submitted data, decision action, status, and notification | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-youth-soccer-soccer-team-roster-community-youth-soccer-coach` | `ui-remediation` | Riverside Youth Soccer | `soccer-team-roster` | coach | 3 | 1 | team roster/schedule surface with role-filtered member details and protected-data treatment | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-youth-soccer-soccer-registration-payment-community-youth-soccer-guardian` | `ui-remediation` | Riverside Youth Soccer | `soccer-registration-payment` | guardian | 3 | 1 | payment or donation flow with amount, payer context, receipt, entitlement/status, and audit trail | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-youth-soccer-soccer-practice-schedule-community-youth-soccer-guardian` | `ui-remediation` | Riverside Youth Soccer | `soccer-practice-schedule` | guardian | 3 | 1 | event detail with schedule, location, capacity/status, RSVP action, and result state | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-youth-soccer-soccer-export-metadata-community-youth-soccer-owner` | `ui-remediation` | Riverside Youth Soccer | `soccer-export-metadata` | owner | 3 | 1 | export/import wizard with preview, redaction, checksum, transfer status, and rollback state | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-hoa-hoa-dues-payment-community-hoa-member` | `ui-remediation` | Cedar Commons HOA | `hoa-dues-payment` | member | 3 | 1 | payment or donation flow with amount, payer context, receipt, entitlement/status, and audit trail | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |

### UI Remediation Work Items Reference Patterns

| Reference | Source | URL | What to copy |
| --- | --- | --- | --- |
| Material detail surface composition | Material Design 3 / design-system | https://m3.material.io/components/cards/overview | Build a domain detail page with primary content, metadata, status, and actions instead of a generic task card. |
| Material Design cards and lists | Material Design 3 / design-system | https://m3.material.io/components/cards/overview<br>Also: https://m3.material.io/components/lists/overview | Use cards/lists only as scannable containers with clear hierarchy, content, metadata, and actions. Do not use repeated cards as the whole primary workflow. |
| Flutter sample app implementation patterns | flutter/samples / open-source | https://github.com/flutter/samples | Copy the separation between app shell, route state, domain widgets, and testable UI states rather than hardcoding a single generic renderer. |
| Material navigation and information architecture | Material Design 3 / design-system | https://m3.material.io/components/navigation-drawer/overview<br>Also: https://m3.material.io/components/navigation-bar/overview | Organize screens by user jobs and destinations; keep primary actions visible and avoid exposing implementation taxonomy. |
| Apple HIG navigation and content organization | Apple Human Interface Guidelines / design-system | https://developer.apple.com/design/human-interface-guidelines/navigation | Make navigation predictable, content-centered, and appropriate for the user’s current task. |
| Inbox and message thread pattern | Material lists/text fields / pattern | https://m3.material.io/components/lists/overview<br>Also: https://m3.material.io/components/text-fields/overview | Copy an inbox/thread structure: sender, timestamp, message preview/body, reply field, invite/block state, and read/received state. |
| Feed item and composer pattern | Material cards/lists/text fields / pattern | https://m3.material.io/components/text-fields/overview<br>Also: https://m3.material.io/components/cards/overview<br>https://m3.material.io/components/lists/overview | Copy a feed/composer structure: audience, author, timestamp, body, attachments/status, publish action, and receiver read state. |
| Document list/detail pattern | Material lists/cards / pattern | https://m3.material.io/components/lists/overview | Copy a document library with title, category, audience, file metadata, access state, download/view action, and empty/error states. |
| Form validation and review pattern | U.S. Web Design System / design-system | https://designsystem.digital.gov/components/form/<br>Also: https://designsystem.digital.gov/components/alert/<br>https://design-system.service.gov.uk/components/error-summary/ | Copy a form flow with field labels, helper text, validation errors, review state, submit action, status, and protected-data treatment. |
| Match schedule and result pattern | Material lists/cards / pattern | https://m3.material.io/components/lists/overview | Copy a match surface with players, schedule/round, result entry, result state, and next action. |
| Event detail and RSVP flow | Material cards/lists/buttons / pattern | https://m3.material.io/components/cards/overview<br>Also: https://m3.material.io/components/buttons/overview<br>https://m3.material.io/components/chips/overview | Copy an event detail layout: title, date/time, location, host, capacity/status chip, attendee context, RSVP action, and confirmation state. |
| Task list and export wizard | GOV.UK Design System / design-system | https://design-system.service.gov.uk/components/task-list/<br>Also: https://design-system.service.gov.uk/patterns/check-answers/ | Copy a wizard with steps, preview, redaction choices, checksum evidence, transfer status, and rollback confirmation. |

### Affected Coverage Rows

Showing 30 of 62 affected coverage rows.

| Coverage row | Community | Workflow | Persona | Missing evidence |
| --- | --- | --- | --- | --- |
| `b25-wp-002-plant-exchange-submission-community-garden-club-member` | Garden Club | `plant-exchange-submission` | member |  |
| `b25-wp-007-book-discussion-message-community-book-club-member` | Neighborhood Book Club | `book-discussion-message` | member |  |
| `b25-wp-008-book-selection-publish-community-book-club-owner` | Neighborhood Book Club | `book-selection-publish` | owner |  |
| `b25-wp-013-soccer-minor-redaction-community-youth-soccer-guardian` | Riverside Youth Soccer | `soccer-minor-redaction` | guardian |  |
| `b25-wp-016-soccer-reminder-notification-community-youth-soccer-guardian` | Riverside Youth Soccer | `soccer-reminder-notification` | guardian |  |
| `b25-wp-019-hoa-member-document-community-hoa-member` | Cedar Commons HOA | `hoa-member-document` | member |  |
| `b25-wp-021-hoa-architectural-request-community-hoa-owner` | Cedar Commons HOA | `hoa-architectural-request` | owner |  |
| `b25-wp-023-hoa-owner-notification-community-hoa-owner` | Cedar Commons HOA | `hoa-owner-notification` | owner |  |
| `b25-wp-025-mosque-announcement-community-mosque-owner` | Masjid Nur | `mosque-announcement` | owner |  |
| `b25-wp-028-mosque-donor-visibility-community-mosque-donor` | Masjid Nur | `mosque-donor-visibility` | donor |  |
| `b25-wp-031-mosque-neutral-notification-community-mosque-member` | Masjid Nur | `mosque-neutral-notification` | member |  |
| `b25-wp-033-chess-local-install-open-community-chess-club-member` | Chess Club | `chess-local-install-open` | member |  |
| `b25-wp-034-chess-route-home-community-chess-club-member` | Chess Club | `chess-route-home` | member |  |
| `b25-wp-035-chess-match-result-community-chess-club-member` | Chess Club | `chess-match-result` | member |  |
| `b25-wp-037-critique-submission-community-camera-club-member` | Camera Club | `critique-submission` | member |  |
| `b25-wp-038-gear-loan-request-community-camera-club-member` | Camera Club | `gear-loan-request` | member |  |
| `b25-wp-043-platform-message-stream-community-platform-social-member` | Member Social Space | `platform-message-stream` | member |  |
| `b25-wp-001-garden-event-rsvp-community-garden-club-member` | Garden Club | `garden-event-rsvp` | member |  |
| `b25-wp-003-garden-export-custom-schemas-community-garden-club-owner` | Garden Club | `garden-export-custom-schemas` | owner |  |
| `b25-wp-004-book-nomination-community-book-club-member` | Neighborhood Book Club | `book-nomination` | member |  |
| `b25-wp-005-book-vote-community-book-club-member` | Neighborhood Book Club | `book-vote` | member |  |
| `b25-wp-006-book-meeting-rsvp-community-book-club-member` | Neighborhood Book Club | `book-meeting-rsvp` | member |  |
| `b25-wp-009-book-search-ai-digest-community-book-club-member` | Neighborhood Book Club | `book-search-ai-digest` | member |  |
| `b25-wp-010-book-export-metadata-community-book-club-owner` | Neighborhood Book Club | `book-export-metadata` | owner |  |
| `b25-wp-011-soccer-guardian-join-approval-community-youth-soccer-guardian` | Riverside Youth Soccer | `soccer-guardian-join-approval` | guardian |  |
| `b25-wp-012-soccer-team-roster-community-youth-soccer-coach` | Riverside Youth Soccer | `soccer-team-roster` | coach |  |
| `b25-wp-014-soccer-registration-payment-community-youth-soccer-guardian` | Riverside Youth Soccer | `soccer-registration-payment` | guardian |  |
| `b25-wp-015-soccer-practice-schedule-community-youth-soccer-guardian` | Riverside Youth Soccer | `soccer-practice-schedule` | guardian |  |
| `b25-wp-017-soccer-export-metadata-community-youth-soccer-owner` | Riverside Youth Soccer | `soccer-export-metadata` | owner |  |
| `b25-wp-018-hoa-dues-payment-community-hoa-member` | Cedar Commons HOA | `hoa-dues-payment` | member |  |

### Affected Screen Rows

Showing 30 of 177 affected screen rows.

| Screen row | Community | Workflow | Persona | State | Exact UX failure |
| --- | --- | --- | --- | --- | --- |
| `b25-v4-row-001-garden-event-rsvp-0` | Garden Club | `garden-event-rsvp` | member | B13_ext_garden_club_garden-event-rsvp_start | No row-specific failure recorded. |
| `b25-v4-row-002-garden-event-rsvp-1` | Garden Club | `garden-event-rsvp` | member | B13_ext_garden_club_garden-event-rsvp_action | No row-specific failure recorded. |
| `b25-v4-row-003-garden-event-rsvp-2` | Garden Club | `garden-event-rsvp` | member | B13_ext_garden_club_garden-event-rsvp_complete | No row-specific failure recorded. |
| `b25-v4-row-004-plant-exchange-submission-0` | Garden Club | `plant-exchange-submission` | member | B13_ext_garden_club_plant-exchange-submission_start | Ticket must add screenshot-backed visible text and a non-reusable critique for this exact screen. |
| `b25-v4-row-005-plant-exchange-submission-1` | Garden Club | `plant-exchange-submission` | member | B13_ext_garden_club_plant-exchange-submission_action | Ticket must add screenshot-backed visible text and a non-reusable critique for this exact screen. |
| `b25-v4-row-006-plant-exchange-submission-2` | Garden Club | `plant-exchange-submission` | member | B13_ext_garden_club_plant-exchange-submission_complete | Ticket must add screenshot-backed visible text and a non-reusable critique for this exact screen. |
| `b25-v4-row-007-garden-export-custom-schemas-0` | Garden Club | `garden-export-custom-schemas` | owner | B13_ext_garden_club_garden-export-custom-schemas_start | No row-specific failure recorded. |
| `b25-v4-row-008-garden-export-custom-schemas-1` | Garden Club | `garden-export-custom-schemas` | owner | B13_ext_garden_club_garden-export-custom-schemas_action | No row-specific failure recorded. |
| `b25-v4-row-009-garden-export-custom-schemas-2` | Garden Club | `garden-export-custom-schemas` | owner | B13_ext_garden_club_garden-export-custom-schemas_complete | No row-specific failure recorded. |
| `b25-v4-row-010-book-nomination-0` | Neighborhood Book Club | `book-nomination` | member | B14_ext_book_club_book-nomination_start | No row-specific failure recorded. |
| `b25-v4-row-011-book-nomination-1` | Neighborhood Book Club | `book-nomination` | member | B14_ext_book_club_book-nomination_action | No row-specific failure recorded. |
| `b25-v4-row-012-book-nomination-2` | Neighborhood Book Club | `book-nomination` | member | B14_ext_book_club_book-nomination_complete | No row-specific failure recorded. |
| `b25-v4-row-013-book-vote-0` | Neighborhood Book Club | `book-vote` | member | B14_ext_book_club_book-vote_start | No row-specific failure recorded. |
| `b25-v4-row-014-book-vote-1` | Neighborhood Book Club | `book-vote` | member | B14_ext_book_club_book-vote_action | No row-specific failure recorded. |
| `b25-v4-row-015-book-vote-2` | Neighborhood Book Club | `book-vote` | member | B14_ext_book_club_book-vote_complete | No row-specific failure recorded. |
| `b25-v4-row-016-book-meeting-rsvp-0` | Neighborhood Book Club | `book-meeting-rsvp` | member | B14_ext_book_club_book-meeting-rsvp_start | No row-specific failure recorded. |
| `b25-v4-row-017-book-meeting-rsvp-1` | Neighborhood Book Club | `book-meeting-rsvp` | member | B14_ext_book_club_book-meeting-rsvp_action | No row-specific failure recorded. |
| `b25-v4-row-018-book-meeting-rsvp-2` | Neighborhood Book Club | `book-meeting-rsvp` | member | B14_ext_book_club_book-meeting-rsvp_complete | No row-specific failure recorded. |
| `b25-v4-row-019-book-discussion-message-0` | Neighborhood Book Club | `book-discussion-message` | member | B14_ext_book_club_book-discussion-message_start | Ticket must add screenshot-backed visible text and a non-reusable critique for this exact screen. |
| `b25-v4-row-020-book-discussion-message-1` | Neighborhood Book Club | `book-discussion-message` | member | B14_ext_book_club_book-discussion-message_action | Ticket must add screenshot-backed visible text and a non-reusable critique for this exact screen. |
| `b25-v4-row-021-book-discussion-message-2` | Neighborhood Book Club | `book-discussion-message` | member | B14_ext_book_club_book-discussion-message_complete | Ticket must add screenshot-backed visible text and a non-reusable critique for this exact screen. |
| `b25-v4-row-022-book-selection-publish-0` | Neighborhood Book Club | `book-selection-publish` | owner | B14_ext_book_club_book-selection-publish_start | Ticket must add screenshot-backed visible text and a non-reusable critique for this exact screen. |
| `b25-v4-row-023-book-selection-publish-1` | Neighborhood Book Club | `book-selection-publish` | owner | B14_ext_book_club_book-selection-publish_action | Ticket must add screenshot-backed visible text and a non-reusable critique for this exact screen. |
| `b25-v4-row-024-book-selection-publish-2` | Neighborhood Book Club | `book-selection-publish` | owner | B14_ext_book_club_book-selection-publish_complete | Ticket must add screenshot-backed visible text and a non-reusable critique for this exact screen. |
| `b25-v4-row-025-book-search-ai-digest-0` | Neighborhood Book Club | `book-search-ai-digest` | member | B14_ext_book_club_book-search-ai-digest_start | No row-specific failure recorded. |
| `b25-v4-row-026-book-search-ai-digest-1` | Neighborhood Book Club | `book-search-ai-digest` | member | B14_ext_book_club_book-search-ai-digest_action | No row-specific failure recorded. |
| `b25-v4-row-027-book-search-ai-digest-2` | Neighborhood Book Club | `book-search-ai-digest` | member | B14_ext_book_club_book-search-ai-digest_complete | No row-specific failure recorded. |
| `b25-v4-row-028-book-export-metadata-0` | Neighborhood Book Club | `book-export-metadata` | owner | B14_ext_book_club_book-export-metadata_start | No row-specific failure recorded. |
| `b25-v4-row-029-book-export-metadata-1` | Neighborhood Book Club | `book-export-metadata` | owner | B14_ext_book_club_book-export-metadata_action | No row-specific failure recorded. |
| `b25-v4-row-030-book-export-metadata-2` | Neighborhood Book Club | `book-export-metadata` | owner | B14_ext_book_club_book-export-metadata_complete | No row-specific failure recorded. |

### Evidence To Update
- independent-production-ux-review.json findings
- product-ux-remediation-loop.md
- b25-iteration-scorecard-latest.json/.md
- Build Tracker.md B25 row and execution ledger
- docs/Product Docs V2/Community Examples/<community>-product-experience.md
- independent-production-ux-review.json productDocCoverage
- independent-production-ux-review.md community product experience docs table
- production-ux-criteria-scorecard.json/.md
- independent-production-ux-review.json holisticQuestionAnswers
- independent-production-ux-review.md holistic review summary
- product-ux-screen-review-matrix.md relevant screen rows
- independent-production-ux-review.json workflowPersonaScorecards
- independent-production-ux-review.json screenRows
- product-ux-screen-review-matrix.md every workflow/persona row
- independent-production-ux-review.json workflowLifecycleScorecards
- b25-workflow-lifecycle-scorecards.md
- Updated review JSON, scorecards, screenshots, remediation log, and tracker evidence for the fixed criterion.
- Product doc coverage rows for every reviewed community/test app.
- Updated Product Docs V2 community experience docs with hashes, paths, required sections, and no placeholders.
- B25 review/remediation log entries showing the current screenshots will be judged against each product spec.
- Fresh holistic screenshots for primary homes, navigation, representative detail surfaces, and representative completion/result states.
- `holisticQuestionAnswers` with visible evidence, score, pass/fail answer, and specific rationale.
- Updated `production-ux-criteria-scorecard.json/.md` showing the criterion passes.
- Fresh screenshots for every primary workflow/persona surface that was replaced or reviewed.
- `workflowPersonaScorecards` with task-specific domain-native surface judgments.
- Screen matrix rows showing `primarySurfaceType` or classification is not generic for primary workflows.
- Fresh entry/action/result/receiver screenshots for every remediated workflow/persona lifecycle.
- `workflowLifecycleScorecards` showing every required lifecycle group passes.
- Visible text excerpts proving object/context, decision information, primary action, alternate/change/reject affordance, persistent result state, and receiver/continuation state.
- Visible text extracts for every reviewed row.
- Non-boilerplate screen-specific critique for every reviewed row.
- Updated markdown matrix matching the JSON evidence.

### Acceptance Checks
- Unresolved blocker and major finding counts are both zero.
- `production_ux_judge.dart` has no blocking failure for this criterion.
- `b25_iteration_scorecard.dart` records the ticket as resolved or no longer blocking.
- Screenshots are refreshed and hashes/timestamps/app commit SHA match the reviewed app version.
- Do not use screenshots alone as the source of truth for desired product experience.
- Do not proceed to UI remediation when a reviewed community has no product experience spec.
- Do not satisfy this criterion with a generic template that could apply unchanged to another community.
- Holistic direct-question answers are present, screenshot-backed, non-boilerplate, and pass.
- Every workflow/persona scorecard is present, screenshot-backed, non-boilerplate, and pass.
- Every workflow lifecycle scorecard is present, screenshot-backed, and pass with no missing lifecycle groups.

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
- Screen row `b25-v4-row-003-garden-event-rsvp-2` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-003-garden-event-rsvp-2` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-003-garden-event-rsvp-2` names visible UI elements, visible text, persona `member`, workflow `garden-event-rsvp`, and the exact product UX issue.
- Screen row `b25-v4-row-004-plant-exchange-submission-0` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-004-plant-exchange-submission-0` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-004-plant-exchange-submission-0` names visible UI elements, visible text, persona `member`, workflow `plant-exchange-submission`, and the exact product UX issue.
- Primary surface for `plant-exchange-submission` is documented as `plant exchange offer form and member marketplace surface with plant details, pickup timing, owner contact, and submitted offer state` or another explicit domain-native surface.
- After-screenshot visible text proves every required semantic surface group for `plant-exchange-submission`.
- Screen row `b25-v4-row-005-plant-exchange-submission-1` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-005-plant-exchange-submission-1` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-005-plant-exchange-submission-1` names visible UI elements, visible text, persona `member`, workflow `plant-exchange-submission`, and the exact product UX issue.
- Screen row `b25-v4-row-006-plant-exchange-submission-2` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-006-plant-exchange-submission-2` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-006-plant-exchange-submission-2` names visible UI elements, visible text, persona `member`, workflow `plant-exchange-submission`, and the exact product UX issue.
- Screen row `b25-v4-row-007-garden-export-custom-schemas-0` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-007-garden-export-custom-schemas-0` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-007-garden-export-custom-schemas-0` names visible UI elements, visible text, persona `owner`, workflow `garden-export-custom-schemas`, and the exact product UX issue.
- Primary surface for `garden-export-custom-schemas` is documented as `export/import wizard with preview, redaction, checksum, transfer status, and rollback state` or another explicit domain-native surface.
- After-screenshot visible text proves every required semantic surface group for `garden-export-custom-schemas`.
- Screen row `b25-v4-row-008-garden-export-custom-schemas-1` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-008-garden-export-custom-schemas-1` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-008-garden-export-custom-schemas-1` names visible UI elements, visible text, persona `owner`, workflow `garden-export-custom-schemas`, and the exact product UX issue.
- Screen row `b25-v4-row-009-garden-export-custom-schemas-2` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-009-garden-export-custom-schemas-2` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-009-garden-export-custom-schemas-2` names visible UI elements, visible text, persona `owner`, workflow `garden-export-custom-schemas`, and the exact product UX issue.
- Screen row `b25-v4-row-010-book-nomination-0` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-010-book-nomination-0` is extracted from the screenshot or manually transcribed from the screenshot.

### Rerun Commands
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
