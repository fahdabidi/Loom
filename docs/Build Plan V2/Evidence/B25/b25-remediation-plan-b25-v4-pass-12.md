# B25 Remediation Plan

| Field | Value |
| --- | --- |
| Review run | `b25-v4-pass-11` |
| Status | `open` |
| Source tickets | `../docs/Build Plan V2/Evidence/B25/b25-remediation-tickets-b25-v4-pass-11.json` |
| Ticket count | 6 |
| Scorecard status | `fail` |
| Remaining blocker/major | 0 |
| Blocking criteria failures | 6 |
| Product spec work items | 0 |
| Evidence repair work items | 10 |
| UI remediation work items | 10 |
| Work item sequencing | Product-spec work items must close first, then evidence repair work items, then matching UI remediation work items. |

## Source Tickets

| Ticket | Source criterion | Severity | Status | Title |
| --- | --- | --- | --- | --- |
| `B25-RT-001-b25-c03-production-grade-experience` | `b25-c03-production-grade-experience` | major | open | Reviewer can state the experience feels production-grade |
| `B25-RT-002-b25-c04-modern-intentional-ui` | `b25-c04-modern-intentional-ui` | major | open | UI looks modern and intentionally designed |
| `B25-RT-003-b25-c05-community-content-ia` | `b25-c05-community-content-ia` | major | open | Screens are organized around community content and jobs-to-be-done |
| `B25-RT-004-b25-c06-domain-native-primary-surfaces` | `b25-c06-domain-native-primary-surfaces` | major | open | Primary workflows use domain-specific product surfaces |
| `B25-RT-005-b25-c08-visible-text-specific-critique` | `b25-c08-visible-text-specific-critique` | major | open | Every row has visible text and screen-specific critique |
| `B25-RT-006-b25-c09-no-layout-production-defects` | `b25-c09-no-layout-production-defects` | major | open | No blocking or major layout/content defects remain |

## B25-RB-001-independent-review-evidence: Complete independent review evidence and critique

Turn captured screenshots into complete independent UX review evidence before attempting UI remediation.

| Field | Value |
| --- | --- |
| Status | open |
| Ticket IDs | B25-RT-001-b25-c03-production-grade-experience, B25-RT-002-b25-c04-modern-intentional-ui, B25-RT-005-b25-c08-visible-text-specific-critique, B25-RT-006-b25-c09-no-layout-production-defects |

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
| Feed item and composer pattern | Material cards/lists/text fields / pattern | https://m3.material.io/components/text-fields/overview<br>Also: https://m3.material.io/components/cards/overview<br>https://m3.material.io/components/lists/overview | Copy a feed/composer structure: audience, author, timestamp, body, attachments/status, publish action, and receiver read state. |
| Material detail surface composition | Material Design 3 / design-system | https://m3.material.io/components/cards/overview | Build a domain detail page with primary content, metadata, status, and actions instead of a generic task card. |
| Event detail and RSVP flow | Material cards/lists/buttons / pattern | https://m3.material.io/components/cards/overview<br>Also: https://m3.material.io/components/buttons/overview<br>https://m3.material.io/components/chips/overview | Copy an event detail layout: title, date/time, location, host, capacity/status chip, attendee context, RSVP action, and confirmation state. |
| Document list/detail pattern | Material lists/cards / pattern | https://m3.material.io/components/lists/overview | Copy a document library with title, category, audience, file metadata, access state, download/view action, and empty/error states. |

### Reference Research Queries
- production mobile UX review screenshot critique examples
- open source Flutter mobile app UX patterns GitHub
- modern mobile app information architecture visual hierarchy examples
- Material Design 3 mobile UI hierarchy navigation cards examples
- open source Flutter production app dashboard detail screen examples
- open source Flutter announcement-feed mobile UI example GitHub
- announcement feed/composer with audience, author, timestamp, body, and receiver state mobile UX pattern
- Material Design announcement feed/composer with audience, author, timestamp, body, and receiver state mobile pattern
- open source Flutter domain-native-surface mobile UI example GitHub
- protected youth roster/profile surface with minor-data redaction, guardian visibility, and coach-only detail state mobile UX pattern
- Material Design protected youth roster/profile surface with minor-data redaction, guardian visibility, and coach-only detail state mobile pattern
- open source Flutter event-rsvp mobile UI example GitHub
- event detail with schedule, location, capacity/status, RSVP action, and result state mobile UX pattern
- Material Design event detail with schedule, location, capacity/status, RSVP action, and result state mobile pattern
- notification inbox/detail surface with sender, audience, timestamp, message body, and receiver state mobile UX pattern
- Material Design notification inbox/detail surface with sender, audience, timestamp, message body, and receiver state mobile pattern
- open source Flutter document-library mobile UI example GitHub
- document library/detail surface with title, audience, file metadata, and access state mobile UX pattern
- Material Design document library/detail surface with title, audience, file metadata, and access state mobile pattern
- App Shell top banner ad slot no-fill surface with preserved layout, disclosure/reserved space, and no content overlap mobile UX pattern

### Evidence Repair Work Items

Showing 10 of 10 work items. Full detail is in the JSON artifact.

| Work item | Stage | Community | Workflow | Persona | Screens | Coverage | Target surface | Blocked until |
| --- | --- | --- | --- | --- | ---: | ---: | --- | --- |
| `b25-wi-evidence-repair-community-book-club-book-selection-publish-community-book-club-owner` | `evidence-repair` | Neighborhood Book Club | `book-selection-publish` | owner | 3 | 1 | announcement feed/composer with audience, author, timestamp, body, and receiver state |  |
| `b25-wi-evidence-repair-community-youth-soccer-soccer-minor-redaction-community-youth-soccer-guardian` | `evidence-repair` | Riverside Youth Soccer | `soccer-minor-redaction` | guardian | 3 | 1 | protected youth roster/profile surface with minor-data redaction, guardian visibility, and coach-only detail state |  |
| `b25-wi-evidence-repair-community-youth-soccer-soccer-practice-schedule-community-youth-soccer-guardian` | `evidence-repair` | Riverside Youth Soccer | `soccer-practice-schedule` | guardian | 3 | 1 | event detail with schedule, location, capacity/status, RSVP action, and result state |  |
| `b25-wi-evidence-repair-community-youth-soccer-soccer-reminder-notification-community-youth-soccer-guardian` | `evidence-repair` | Riverside Youth Soccer | `soccer-reminder-notification` | guardian | 3 | 1 | notification inbox/detail surface with sender, audience, timestamp, message body, and receiver state |  |
| `b25-wi-evidence-repair-community-hoa-hoa-member-document-community-hoa-member` | `evidence-repair` | Cedar Commons HOA | `hoa-member-document` | member | 3 | 1 | document library/detail surface with title, audience, file metadata, and access state |  |
| `b25-wi-evidence-repair-community-hoa-hoa-owner-notification-community-hoa-owner` | `evidence-repair` | Cedar Commons HOA | `hoa-owner-notification` | owner | 3 | 1 | notification inbox/detail surface with sender, audience, timestamp, message body, and receiver state |  |
| `b25-wi-evidence-repair-community-mosque-mosque-announcement-community-mosque-owner` | `evidence-repair` | Masjid Nur | `mosque-announcement` | owner | 3 | 1 | announcement feed/composer with audience, author, timestamp, body, and receiver state |  |
| `b25-wi-evidence-repair-community-mosque-mosque-neutral-notification-community-mosque-member` | `evidence-repair` | Masjid Nur | `mosque-neutral-notification` | member | 3 | 1 | notification inbox/detail surface with sender, audience, timestamp, message body, and receiver state |  |
| `b25-wi-evidence-repair-community-platform-social-platform-top-banner-no-fill-community-platform-social-member` | `evidence-repair` | Member Social Space | `platform-top-banner-no-fill` | member | 3 | 1 | App Shell top banner ad slot no-fill surface with preserved layout, disclosure/reserved space, and no content overlap |  |
| `b25-wi-evidence-repair-community-platform-social-platform-sensitive-no-fill-community-platform-social-member` | `evidence-repair` | Member Social Space | `platform-sensitive-no-fill` | member | 3 | 1 | sensitive-context ad suppression surface with protected content visible and ad slot safely no-filled |  |

### Evidence Repair Work Items Reference Patterns

| Reference | Source | URL | What to copy |
| --- | --- | --- | --- |
| Feed item and composer pattern | Material cards/lists/text fields / pattern | https://m3.material.io/components/text-fields/overview<br>Also: https://m3.material.io/components/cards/overview<br>https://m3.material.io/components/lists/overview | Copy a feed/composer structure: audience, author, timestamp, body, attachments/status, publish action, and receiver read state. |
| Material Design cards and lists | Material Design 3 / design-system | https://m3.material.io/components/cards/overview<br>Also: https://m3.material.io/components/lists/overview | Use cards/lists only as scannable containers with clear hierarchy, content, metadata, and actions. Do not use repeated cards as the whole primary workflow. |
| Flutter sample app implementation patterns | flutter/samples / open-source | https://github.com/flutter/samples | Copy the separation between app shell, route state, domain widgets, and testable UI states rather than hardcoding a single generic renderer. |
| Material navigation and information architecture | Material Design 3 / design-system | https://m3.material.io/components/navigation-drawer/overview<br>Also: https://m3.material.io/components/navigation-bar/overview | Organize screens by user jobs and destinations; keep primary actions visible and avoid exposing implementation taxonomy. |
| Apple HIG navigation and content organization | Apple Human Interface Guidelines / design-system | https://developer.apple.com/design/human-interface-guidelines/navigation | Make navigation predictable, content-centered, and appropriate for the user’s current task. |
| Material detail surface composition | Material Design 3 / design-system | https://m3.material.io/components/cards/overview | Build a domain detail page with primary content, metadata, status, and actions instead of a generic task card. |
| Event detail and RSVP flow | Material cards/lists/buttons / pattern | https://m3.material.io/components/cards/overview<br>Also: https://m3.material.io/components/buttons/overview<br>https://m3.material.io/components/chips/overview | Copy an event detail layout: title, date/time, location, host, capacity/status chip, attendee context, RSVP action, and confirmation state. |
| Document list/detail pattern | Material lists/cards / pattern | https://m3.material.io/components/lists/overview | Copy a document library with title, category, audience, file metadata, access state, download/view action, and empty/error states. |

### Affected Coverage Rows

Showing 10 of 10 affected coverage rows.

| Coverage row | Community | Workflow | Persona | Missing evidence |
| --- | --- | --- | --- | --- |
| `b25-wp-008-book-selection-publish-community-book-club-owner` | Neighborhood Book Club | `book-selection-publish` | owner |  |
| `b25-wp-013-soccer-minor-redaction-community-youth-soccer-guardian` | Riverside Youth Soccer | `soccer-minor-redaction` | guardian |  |
| `b25-wp-015-soccer-practice-schedule-community-youth-soccer-guardian` | Riverside Youth Soccer | `soccer-practice-schedule` | guardian |  |
| `b25-wp-016-soccer-reminder-notification-community-youth-soccer-guardian` | Riverside Youth Soccer | `soccer-reminder-notification` | guardian |  |
| `b25-wp-019-hoa-member-document-community-hoa-member` | Cedar Commons HOA | `hoa-member-document` | member |  |
| `b25-wp-023-hoa-owner-notification-community-hoa-owner` | Cedar Commons HOA | `hoa-owner-notification` | owner |  |
| `b25-wp-025-mosque-announcement-community-mosque-owner` | Masjid Nur | `mosque-announcement` | owner |  |
| `b25-wp-031-mosque-neutral-notification-community-mosque-member` | Masjid Nur | `mosque-neutral-notification` | member |  |
| `b25-wp-045-platform-top-banner-no-fill-community-platform-social-member` | Member Social Space | `platform-top-banner-no-fill` | member |  |
| `b25-wp-046-platform-sensitive-no-fill-community-platform-social-member` | Member Social Space | `platform-sensitive-no-fill` | member |  |

### Affected Screen Rows

Showing 30 of 30 affected screen rows.

| Screen row | Community | Workflow | Persona | State | Exact UX failure |
| --- | --- | --- | --- | --- | --- |
| `b25-v4-row-022-book-selection-publish-0` | Neighborhood Book Club | `book-selection-publish` | owner | B14_ext_book_club_book-selection-publish_start | Ticket must add screenshot-backed visible text and a non-reusable critique for this exact screen. |
| `b25-v4-row-023-book-selection-publish-1` | Neighborhood Book Club | `book-selection-publish` | owner | B14_ext_book_club_book-selection-publish_action | Ticket must add screenshot-backed visible text and a non-reusable critique for this exact screen. |
| `b25-v4-row-024-book-selection-publish-2` | Neighborhood Book Club | `book-selection-publish` | owner | B14_ext_book_club_book-selection-publish_complete | Ticket must add screenshot-backed visible text and a non-reusable critique for this exact screen. |
| `b25-v4-row-037-soccer-minor-redaction-0` | Riverside Youth Soccer | `soccer-minor-redaction` | guardian | B14_ext_youth_soccer_soccer-minor-redaction_start | Ticket must add screenshot-backed visible text and a non-reusable critique for this exact screen. |
| `b25-v4-row-038-soccer-minor-redaction-1` | Riverside Youth Soccer | `soccer-minor-redaction` | guardian | B14_ext_youth_soccer_soccer-minor-redaction_action | Ticket must add screenshot-backed visible text and a non-reusable critique for this exact screen. |
| `b25-v4-row-039-soccer-minor-redaction-2` | Riverside Youth Soccer | `soccer-minor-redaction` | guardian | B14_ext_youth_soccer_soccer-minor-redaction_complete | Ticket must add screenshot-backed visible text and a non-reusable critique for this exact screen. |
| `b25-v4-row-043-soccer-practice-schedule-0` | Riverside Youth Soccer | `soccer-practice-schedule` | guardian | B14_ext_youth_soccer_soccer-practice-schedule_start | Ticket must add screenshot-backed visible text and a non-reusable critique for this exact screen. |
| `b25-v4-row-044-soccer-practice-schedule-1` | Riverside Youth Soccer | `soccer-practice-schedule` | guardian | B14_ext_youth_soccer_soccer-practice-schedule_action | Ticket must add screenshot-backed visible text and a non-reusable critique for this exact screen. |
| `b25-v4-row-045-soccer-practice-schedule-2` | Riverside Youth Soccer | `soccer-practice-schedule` | guardian | B14_ext_youth_soccer_soccer-practice-schedule_complete | Ticket must add screenshot-backed visible text and a non-reusable critique for this exact screen. |
| `b25-v4-row-046-soccer-reminder-notification-0` | Riverside Youth Soccer | `soccer-reminder-notification` | guardian | B14_ext_youth_soccer_soccer-reminder-notification_start | Ticket must add screenshot-backed visible text and a non-reusable critique for this exact screen. |
| `b25-v4-row-047-soccer-reminder-notification-1` | Riverside Youth Soccer | `soccer-reminder-notification` | guardian | B14_ext_youth_soccer_soccer-reminder-notification_action | Ticket must add screenshot-backed visible text and a non-reusable critique for this exact screen. |
| `b25-v4-row-048-soccer-reminder-notification-2` | Riverside Youth Soccer | `soccer-reminder-notification` | guardian | B14_ext_youth_soccer_soccer-reminder-notification_complete | Ticket must add screenshot-backed visible text and a non-reusable critique for this exact screen. |
| `b25-v4-row-055-hoa-member-document-0` | Cedar Commons HOA | `hoa-member-document` | member | B14_ext_hoa_hoa-member-document_start | Ticket must add screenshot-backed visible text and a non-reusable critique for this exact screen. |
| `b25-v4-row-056-hoa-member-document-1` | Cedar Commons HOA | `hoa-member-document` | member | B14_ext_hoa_hoa-member-document_action | Ticket must add screenshot-backed visible text and a non-reusable critique for this exact screen. |
| `b25-v4-row-057-hoa-member-document-2` | Cedar Commons HOA | `hoa-member-document` | member | B14_ext_hoa_hoa-member-document_complete | Ticket must add screenshot-backed visible text and a non-reusable critique for this exact screen. |
| `b25-v4-row-067-hoa-owner-notification-0` | Cedar Commons HOA | `hoa-owner-notification` | owner | B14_ext_hoa_hoa-owner-notification_start | Ticket must add screenshot-backed visible text and a non-reusable critique for this exact screen. |
| `b25-v4-row-068-hoa-owner-notification-1` | Cedar Commons HOA | `hoa-owner-notification` | owner | B14_ext_hoa_hoa-owner-notification_action | Ticket must add screenshot-backed visible text and a non-reusable critique for this exact screen. |
| `b25-v4-row-069-hoa-owner-notification-2` | Cedar Commons HOA | `hoa-owner-notification` | owner | B14_ext_hoa_hoa-owner-notification_complete | Ticket must add screenshot-backed visible text and a non-reusable critique for this exact screen. |
| `b25-v4-row-073-mosque-announcement-0` | Masjid Nur | `mosque-announcement` | owner | B14_ext_mosque_mosque-announcement_start | Ticket must add screenshot-backed visible text and a non-reusable critique for this exact screen. |
| `b25-v4-row-074-mosque-announcement-1` | Masjid Nur | `mosque-announcement` | owner | B14_ext_mosque_mosque-announcement_action | Ticket must add screenshot-backed visible text and a non-reusable critique for this exact screen. |
| `b25-v4-row-075-mosque-announcement-2` | Masjid Nur | `mosque-announcement` | owner | B14_ext_mosque_mosque-announcement_complete | Ticket must add screenshot-backed visible text and a non-reusable critique for this exact screen. |
| `b25-v4-row-091-mosque-neutral-notification-0` | Masjid Nur | `mosque-neutral-notification` | member | B14_ext_mosque_mosque-neutral-notification_start | Ticket must add screenshot-backed visible text and a non-reusable critique for this exact screen. |
| `b25-v4-row-092-mosque-neutral-notification-1` | Masjid Nur | `mosque-neutral-notification` | member | B14_ext_mosque_mosque-neutral-notification_action | Ticket must add screenshot-backed visible text and a non-reusable critique for this exact screen. |
| `b25-v4-row-093-mosque-neutral-notification-2` | Masjid Nur | `mosque-neutral-notification` | member | B14_ext_mosque_mosque-neutral-notification_complete | Ticket must add screenshot-backed visible text and a non-reusable critique for this exact screen. |
| `b25-v4-row-133-platform-top-banner-no-fill-0` | Member Social Space | `platform-top-banner-no-fill` | member | B16_ext_platform_social_platform-top-banner-no-fill_start | Ticket must add screenshot-backed visible text and a non-reusable critique for this exact screen. |
| `b25-v4-row-134-platform-top-banner-no-fill-1` | Member Social Space | `platform-top-banner-no-fill` | member | B16_ext_platform_social_platform-top-banner-no-fill_action | Ticket must add screenshot-backed visible text and a non-reusable critique for this exact screen. |
| `b25-v4-row-135-platform-top-banner-no-fill-2` | Member Social Space | `platform-top-banner-no-fill` | member | B16_ext_platform_social_platform-top-banner-no-fill_complete | Ticket must add screenshot-backed visible text and a non-reusable critique for this exact screen. |
| `b25-v4-row-136-platform-sensitive-no-fill-0` | Member Social Space | `platform-sensitive-no-fill` | member | B16_ext_platform_social_platform-sensitive-no-fill_start | Ticket must add screenshot-backed visible text and a non-reusable critique for this exact screen. |
| `b25-v4-row-137-platform-sensitive-no-fill-1` | Member Social Space | `platform-sensitive-no-fill` | member | B16_ext_platform_social_platform-sensitive-no-fill_action | Ticket must add screenshot-backed visible text and a non-reusable critique for this exact screen. |
| `b25-v4-row-138-platform-sensitive-no-fill-2` | Member Social Space | `platform-sensitive-no-fill` | member | B16_ext_platform_social_platform-sensitive-no-fill_complete | Ticket must add screenshot-backed visible text and a non-reusable critique for this exact screen. |

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
- Screen row `b25-v4-row-022-book-selection-publish-0` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-022-book-selection-publish-0` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-022-book-selection-publish-0` names visible UI elements, visible text, persona `owner`, workflow `book-selection-publish`, and the exact product UX issue.
- Primary surface for `book-selection-publish` is documented as `announcement feed/composer with audience, author, timestamp, body, and receiver state` or another explicit domain-native surface.
- After-screenshot visible text proves every required semantic surface group for `book-selection-publish`.
- Fresh screenshot path/hash/timestamp/app commit SHA are recorded after the fix.
- The workflow/persona direct-question scorecard passes the visible-text and task-specific critique question.
- Screen row `b25-v4-row-023-book-selection-publish-1` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-023-book-selection-publish-1` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-023-book-selection-publish-1` names visible UI elements, visible text, persona `owner`, workflow `book-selection-publish`, and the exact product UX issue.
- Screen row `b25-v4-row-024-book-selection-publish-2` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-024-book-selection-publish-2` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-024-book-selection-publish-2` names visible UI elements, visible text, persona `owner`, workflow `book-selection-publish`, and the exact product UX issue.
- Screen row `b25-v4-row-037-soccer-minor-redaction-0` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-037-soccer-minor-redaction-0` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-037-soccer-minor-redaction-0` names visible UI elements, visible text, persona `guardian`, workflow `soccer-minor-redaction`, and the exact product UX issue.
- Primary surface for `soccer-minor-redaction` is documented as `protected youth roster/profile surface with minor-data redaction, guardian visibility, and coach-only detail state` or another explicit domain-native surface.
- After-screenshot visible text proves every required semantic surface group for `soccer-minor-redaction`.
- Screen row `b25-v4-row-038-soccer-minor-redaction-1` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-038-soccer-minor-redaction-1` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-038-soccer-minor-redaction-1` names visible UI elements, visible text, persona `guardian`, workflow `soccer-minor-redaction`, and the exact product UX issue.
- Screen row `b25-v4-row-039-soccer-minor-redaction-2` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-039-soccer-minor-redaction-2` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-039-soccer-minor-redaction-2` names visible UI elements, visible text, persona `guardian`, workflow `soccer-minor-redaction`, and the exact product UX issue.
- Screen row `b25-v4-row-043-soccer-practice-schedule-0` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-043-soccer-practice-schedule-0` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-043-soccer-practice-schedule-0` names visible UI elements, visible text, persona `guardian`, workflow `soccer-practice-schedule`, and the exact product UX issue.
- Primary surface for `soccer-practice-schedule` is documented as `event detail with schedule, location, capacity/status, RSVP action, and result state` or another explicit domain-native surface.
- After-screenshot visible text proves every required semantic surface group for `soccer-practice-schedule`.
- Screen row `b25-v4-row-044-soccer-practice-schedule-1` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-044-soccer-practice-schedule-1` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-044-soccer-practice-schedule-1` names visible UI elements, visible text, persona `guardian`, workflow `soccer-practice-schedule`, and the exact product UX issue.
- Screen row `b25-v4-row-045-soccer-practice-schedule-2` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-045-soccer-practice-schedule-2` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-045-soccer-practice-schedule-2` names visible UI elements, visible text, persona `guardian`, workflow `soccer-practice-schedule`, and the exact product UX issue.

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
| Ticket IDs | B25-RT-002-b25-c04-modern-intentional-ui, B25-RT-003-b25-c05-community-content-ia, B25-RT-004-b25-c06-domain-native-primary-surfaces, B25-RT-006-b25-c09-no-layout-production-defects |

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
| Feed item and composer pattern | Material cards/lists/text fields / pattern | https://m3.material.io/components/text-fields/overview<br>Also: https://m3.material.io/components/cards/overview<br>https://m3.material.io/components/lists/overview | Copy a feed/composer structure: audience, author, timestamp, body, attachments/status, publish action, and receiver read state. |
| Event detail and RSVP flow | Material cards/lists/buttons / pattern | https://m3.material.io/components/cards/overview<br>Also: https://m3.material.io/components/buttons/overview<br>https://m3.material.io/components/chips/overview | Copy an event detail layout: title, date/time, location, host, capacity/status chip, attendee context, RSVP action, and confirmation state. |
| Document list/detail pattern | Material lists/cards / pattern | https://m3.material.io/components/lists/overview | Copy a document library with title, category, audience, file metadata, access state, download/view action, and empty/error states. |

### Reference Research Queries
- modern mobile app information architecture visual hierarchy examples
- Material Design 3 mobile UI hierarchy navigation cards examples
- open source Flutter production app dashboard detail screen examples
- community app home screen announcements events messages design examples
- open source Flutter community app home feed events messages UI
- domain specific mobile workflow UI event RSVP donation message export examples
- open source Flutter event RSVP donation messaging workflow UI examples
- open source Flutter announcement-feed mobile UI example GitHub
- announcement feed/composer with audience, author, timestamp, body, and receiver state mobile UX pattern
- Material Design announcement feed/composer with audience, author, timestamp, body, and receiver state mobile pattern
- open source Flutter domain-native-surface mobile UI example GitHub
- protected youth roster/profile surface with minor-data redaction, guardian visibility, and coach-only detail state mobile UX pattern
- Material Design protected youth roster/profile surface with minor-data redaction, guardian visibility, and coach-only detail state mobile pattern
- open source Flutter event-rsvp mobile UI example GitHub
- event detail with schedule, location, capacity/status, RSVP action, and result state mobile UX pattern
- Material Design event detail with schedule, location, capacity/status, RSVP action, and result state mobile pattern
- notification inbox/detail surface with sender, audience, timestamp, message body, and receiver state mobile UX pattern
- Material Design notification inbox/detail surface with sender, audience, timestamp, message body, and receiver state mobile pattern
- open source Flutter document-library mobile UI example GitHub
- document library/detail surface with title, audience, file metadata, and access state mobile UX pattern

### UI Remediation Work Items

Showing 10 of 10 work items. Full detail is in the JSON artifact.

| Work item | Stage | Community | Workflow | Persona | Screens | Coverage | Target surface | Blocked until |
| --- | --- | --- | --- | --- | ---: | ---: | --- | --- |
| `b25-wi-ui-remediation-community-book-club-book-selection-publish-community-book-club-owner` | `ui-remediation` | Neighborhood Book Club | `book-selection-publish` | owner | 3 | 1 | announcement feed/composer with audience, author, timestamp, body, and receiver state | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-youth-soccer-soccer-minor-redaction-community-youth-soccer-guardian` | `ui-remediation` | Riverside Youth Soccer | `soccer-minor-redaction` | guardian | 3 | 1 | protected youth roster/profile surface with minor-data redaction, guardian visibility, and coach-only detail state | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-youth-soccer-soccer-practice-schedule-community-youth-soccer-guardian` | `ui-remediation` | Riverside Youth Soccer | `soccer-practice-schedule` | guardian | 3 | 1 | event detail with schedule, location, capacity/status, RSVP action, and result state | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-youth-soccer-soccer-reminder-notification-community-youth-soccer-guardian` | `ui-remediation` | Riverside Youth Soccer | `soccer-reminder-notification` | guardian | 3 | 1 | notification inbox/detail surface with sender, audience, timestamp, message body, and receiver state | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-hoa-hoa-member-document-community-hoa-member` | `ui-remediation` | Cedar Commons HOA | `hoa-member-document` | member | 3 | 1 | document library/detail surface with title, audience, file metadata, and access state | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-hoa-hoa-owner-notification-community-hoa-owner` | `ui-remediation` | Cedar Commons HOA | `hoa-owner-notification` | owner | 3 | 1 | notification inbox/detail surface with sender, audience, timestamp, message body, and receiver state | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-mosque-mosque-announcement-community-mosque-owner` | `ui-remediation` | Masjid Nur | `mosque-announcement` | owner | 3 | 1 | announcement feed/composer with audience, author, timestamp, body, and receiver state | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-mosque-mosque-neutral-notification-community-mosque-member` | `ui-remediation` | Masjid Nur | `mosque-neutral-notification` | member | 3 | 1 | notification inbox/detail surface with sender, audience, timestamp, message body, and receiver state | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-platform-social-platform-top-banner-no-fill-community-platform-social-member` | `ui-remediation` | Member Social Space | `platform-top-banner-no-fill` | member | 3 | 1 | App Shell top banner ad slot no-fill surface with preserved layout, disclosure/reserved space, and no content overlap | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-platform-social-platform-sensitive-no-fill-community-platform-social-member` | `ui-remediation` | Member Social Space | `platform-sensitive-no-fill` | member | 3 | 1 | sensitive-context ad suppression surface with protected content visible and ad slot safely no-filled | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |

### UI Remediation Work Items Reference Patterns

| Reference | Source | URL | What to copy |
| --- | --- | --- | --- |
| Feed item and composer pattern | Material cards/lists/text fields / pattern | https://m3.material.io/components/text-fields/overview<br>Also: https://m3.material.io/components/cards/overview<br>https://m3.material.io/components/lists/overview | Copy a feed/composer structure: audience, author, timestamp, body, attachments/status, publish action, and receiver read state. |
| Material Design cards and lists | Material Design 3 / design-system | https://m3.material.io/components/cards/overview<br>Also: https://m3.material.io/components/lists/overview | Use cards/lists only as scannable containers with clear hierarchy, content, metadata, and actions. Do not use repeated cards as the whole primary workflow. |
| Flutter sample app implementation patterns | flutter/samples / open-source | https://github.com/flutter/samples | Copy the separation between app shell, route state, domain widgets, and testable UI states rather than hardcoding a single generic renderer. |
| Material navigation and information architecture | Material Design 3 / design-system | https://m3.material.io/components/navigation-drawer/overview<br>Also: https://m3.material.io/components/navigation-bar/overview | Organize screens by user jobs and destinations; keep primary actions visible and avoid exposing implementation taxonomy. |
| Apple HIG navigation and content organization | Apple Human Interface Guidelines / design-system | https://developer.apple.com/design/human-interface-guidelines/navigation | Make navigation predictable, content-centered, and appropriate for the user’s current task. |
| Material detail surface composition | Material Design 3 / design-system | https://m3.material.io/components/cards/overview | Build a domain detail page with primary content, metadata, status, and actions instead of a generic task card. |
| Event detail and RSVP flow | Material cards/lists/buttons / pattern | https://m3.material.io/components/cards/overview<br>Also: https://m3.material.io/components/buttons/overview<br>https://m3.material.io/components/chips/overview | Copy an event detail layout: title, date/time, location, host, capacity/status chip, attendee context, RSVP action, and confirmation state. |
| Document list/detail pattern | Material lists/cards / pattern | https://m3.material.io/components/lists/overview | Copy a document library with title, category, audience, file metadata, access state, download/view action, and empty/error states. |

### Affected Coverage Rows

Showing 10 of 10 affected coverage rows.

| Coverage row | Community | Workflow | Persona | Missing evidence |
| --- | --- | --- | --- | --- |
| `b25-wp-008-book-selection-publish-community-book-club-owner` | Neighborhood Book Club | `book-selection-publish` | owner |  |
| `b25-wp-013-soccer-minor-redaction-community-youth-soccer-guardian` | Riverside Youth Soccer | `soccer-minor-redaction` | guardian |  |
| `b25-wp-015-soccer-practice-schedule-community-youth-soccer-guardian` | Riverside Youth Soccer | `soccer-practice-schedule` | guardian |  |
| `b25-wp-016-soccer-reminder-notification-community-youth-soccer-guardian` | Riverside Youth Soccer | `soccer-reminder-notification` | guardian |  |
| `b25-wp-019-hoa-member-document-community-hoa-member` | Cedar Commons HOA | `hoa-member-document` | member |  |
| `b25-wp-023-hoa-owner-notification-community-hoa-owner` | Cedar Commons HOA | `hoa-owner-notification` | owner |  |
| `b25-wp-025-mosque-announcement-community-mosque-owner` | Masjid Nur | `mosque-announcement` | owner |  |
| `b25-wp-031-mosque-neutral-notification-community-mosque-member` | Masjid Nur | `mosque-neutral-notification` | member |  |
| `b25-wp-045-platform-top-banner-no-fill-community-platform-social-member` | Member Social Space | `platform-top-banner-no-fill` | member |  |
| `b25-wp-046-platform-sensitive-no-fill-community-platform-social-member` | Member Social Space | `platform-sensitive-no-fill` | member |  |

### Affected Screen Rows

Showing 30 of 30 affected screen rows.

| Screen row | Community | Workflow | Persona | State | Exact UX failure |
| --- | --- | --- | --- | --- | --- |
| `b25-v4-row-022-book-selection-publish-0` | Neighborhood Book Club | `book-selection-publish` | owner | B14_ext_book_club_book-selection-publish_start | Ticket must prove the primary screen is a domain-native surface, not a generic card/checklist/metadata surface. |
| `b25-v4-row-023-book-selection-publish-1` | Neighborhood Book Club | `book-selection-publish` | owner | B14_ext_book_club_book-selection-publish_action | Ticket must prove the primary screen is a domain-native surface, not a generic card/checklist/metadata surface. |
| `b25-v4-row-024-book-selection-publish-2` | Neighborhood Book Club | `book-selection-publish` | owner | B14_ext_book_club_book-selection-publish_complete | Ticket must prove the primary screen is a domain-native surface, not a generic card/checklist/metadata surface. |
| `b25-v4-row-037-soccer-minor-redaction-0` | Riverside Youth Soccer | `soccer-minor-redaction` | guardian | B14_ext_youth_soccer_soccer-minor-redaction_start | Ticket must prove the primary screen is a domain-native surface, not a generic card/checklist/metadata surface. |
| `b25-v4-row-038-soccer-minor-redaction-1` | Riverside Youth Soccer | `soccer-minor-redaction` | guardian | B14_ext_youth_soccer_soccer-minor-redaction_action | Ticket must prove the primary screen is a domain-native surface, not a generic card/checklist/metadata surface. |
| `b25-v4-row-039-soccer-minor-redaction-2` | Riverside Youth Soccer | `soccer-minor-redaction` | guardian | B14_ext_youth_soccer_soccer-minor-redaction_complete | Ticket must prove the primary screen is a domain-native surface, not a generic card/checklist/metadata surface. |
| `b25-v4-row-043-soccer-practice-schedule-0` | Riverside Youth Soccer | `soccer-practice-schedule` | guardian | B14_ext_youth_soccer_soccer-practice-schedule_start | Ticket must prove the primary screen is a domain-native surface, not a generic card/checklist/metadata surface. |
| `b25-v4-row-044-soccer-practice-schedule-1` | Riverside Youth Soccer | `soccer-practice-schedule` | guardian | B14_ext_youth_soccer_soccer-practice-schedule_action | Ticket must prove the primary screen is a domain-native surface, not a generic card/checklist/metadata surface. |
| `b25-v4-row-045-soccer-practice-schedule-2` | Riverside Youth Soccer | `soccer-practice-schedule` | guardian | B14_ext_youth_soccer_soccer-practice-schedule_complete | Ticket must prove the primary screen is a domain-native surface, not a generic card/checklist/metadata surface. |
| `b25-v4-row-046-soccer-reminder-notification-0` | Riverside Youth Soccer | `soccer-reminder-notification` | guardian | B14_ext_youth_soccer_soccer-reminder-notification_start | Ticket must prove the primary screen is a domain-native surface, not a generic card/checklist/metadata surface. |
| `b25-v4-row-047-soccer-reminder-notification-1` | Riverside Youth Soccer | `soccer-reminder-notification` | guardian | B14_ext_youth_soccer_soccer-reminder-notification_action | Ticket must prove the primary screen is a domain-native surface, not a generic card/checklist/metadata surface. |
| `b25-v4-row-048-soccer-reminder-notification-2` | Riverside Youth Soccer | `soccer-reminder-notification` | guardian | B14_ext_youth_soccer_soccer-reminder-notification_complete | Ticket must prove the primary screen is a domain-native surface, not a generic card/checklist/metadata surface. |
| `b25-v4-row-055-hoa-member-document-0` | Cedar Commons HOA | `hoa-member-document` | member | B14_ext_hoa_hoa-member-document_start | Ticket must prove the primary screen is a domain-native surface, not a generic card/checklist/metadata surface. |
| `b25-v4-row-056-hoa-member-document-1` | Cedar Commons HOA | `hoa-member-document` | member | B14_ext_hoa_hoa-member-document_action | Ticket must prove the primary screen is a domain-native surface, not a generic card/checklist/metadata surface. |
| `b25-v4-row-057-hoa-member-document-2` | Cedar Commons HOA | `hoa-member-document` | member | B14_ext_hoa_hoa-member-document_complete | Ticket must prove the primary screen is a domain-native surface, not a generic card/checklist/metadata surface. |
| `b25-v4-row-067-hoa-owner-notification-0` | Cedar Commons HOA | `hoa-owner-notification` | owner | B14_ext_hoa_hoa-owner-notification_start | Ticket must prove the primary screen is a domain-native surface, not a generic card/checklist/metadata surface. |
| `b25-v4-row-068-hoa-owner-notification-1` | Cedar Commons HOA | `hoa-owner-notification` | owner | B14_ext_hoa_hoa-owner-notification_action | Ticket must prove the primary screen is a domain-native surface, not a generic card/checklist/metadata surface. |
| `b25-v4-row-069-hoa-owner-notification-2` | Cedar Commons HOA | `hoa-owner-notification` | owner | B14_ext_hoa_hoa-owner-notification_complete | Ticket must prove the primary screen is a domain-native surface, not a generic card/checklist/metadata surface. |
| `b25-v4-row-073-mosque-announcement-0` | Masjid Nur | `mosque-announcement` | owner | B14_ext_mosque_mosque-announcement_start | Ticket must prove the primary screen is a domain-native surface, not a generic card/checklist/metadata surface. |
| `b25-v4-row-074-mosque-announcement-1` | Masjid Nur | `mosque-announcement` | owner | B14_ext_mosque_mosque-announcement_action | Ticket must prove the primary screen is a domain-native surface, not a generic card/checklist/metadata surface. |
| `b25-v4-row-075-mosque-announcement-2` | Masjid Nur | `mosque-announcement` | owner | B14_ext_mosque_mosque-announcement_complete | Ticket must prove the primary screen is a domain-native surface, not a generic card/checklist/metadata surface. |
| `b25-v4-row-091-mosque-neutral-notification-0` | Masjid Nur | `mosque-neutral-notification` | member | B14_ext_mosque_mosque-neutral-notification_start | Ticket must prove the primary screen is a domain-native surface, not a generic card/checklist/metadata surface. |
| `b25-v4-row-092-mosque-neutral-notification-1` | Masjid Nur | `mosque-neutral-notification` | member | B14_ext_mosque_mosque-neutral-notification_action | Ticket must prove the primary screen is a domain-native surface, not a generic card/checklist/metadata surface. |
| `b25-v4-row-093-mosque-neutral-notification-2` | Masjid Nur | `mosque-neutral-notification` | member | B14_ext_mosque_mosque-neutral-notification_complete | Ticket must prove the primary screen is a domain-native surface, not a generic card/checklist/metadata surface. |
| `b25-v4-row-133-platform-top-banner-no-fill-0` | Member Social Space | `platform-top-banner-no-fill` | member | B16_ext_platform_social_platform-top-banner-no-fill_start | Ticket must prove the primary screen is a domain-native surface, not a generic card/checklist/metadata surface. |
| `b25-v4-row-134-platform-top-banner-no-fill-1` | Member Social Space | `platform-top-banner-no-fill` | member | B16_ext_platform_social_platform-top-banner-no-fill_action | Ticket must prove the primary screen is a domain-native surface, not a generic card/checklist/metadata surface. |
| `b25-v4-row-135-platform-top-banner-no-fill-2` | Member Social Space | `platform-top-banner-no-fill` | member | B16_ext_platform_social_platform-top-banner-no-fill_complete | Ticket must prove the primary screen is a domain-native surface, not a generic card/checklist/metadata surface. |
| `b25-v4-row-136-platform-sensitive-no-fill-0` | Member Social Space | `platform-sensitive-no-fill` | member | B16_ext_platform_social_platform-sensitive-no-fill_start | Ticket must prove the primary screen is a domain-native surface, not a generic card/checklist/metadata surface. |
| `b25-v4-row-137-platform-sensitive-no-fill-1` | Member Social Space | `platform-sensitive-no-fill` | member | B16_ext_platform_social_platform-sensitive-no-fill_action | Ticket must prove the primary screen is a domain-native surface, not a generic card/checklist/metadata surface. |
| `b25-v4-row-138-platform-sensitive-no-fill-2` | Member Social Space | `platform-sensitive-no-fill` | member | B16_ext_platform_social_platform-sensitive-no-fill_complete | Ticket must prove the primary screen is a domain-native surface, not a generic card/checklist/metadata surface. |

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
- Screen row `b25-v4-row-022-book-selection-publish-0` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-022-book-selection-publish-0` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-022-book-selection-publish-0` names visible UI elements, visible text, persona `owner`, workflow `book-selection-publish`, and the exact product UX issue.
- Primary surface for `book-selection-publish` is documented as `announcement feed/composer with audience, author, timestamp, body, and receiver state` or another explicit domain-native surface.
- After-screenshot visible text proves every required semantic surface group for `book-selection-publish`.
- Fresh screenshot path/hash/timestamp/app commit SHA are recorded after the fix.
- The workflow/persona direct-question scorecard passes the domain-native primary surface question.
- Screen row `b25-v4-row-023-book-selection-publish-1` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-023-book-selection-publish-1` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-023-book-selection-publish-1` names visible UI elements, visible text, persona `owner`, workflow `book-selection-publish`, and the exact product UX issue.
- Screen row `b25-v4-row-024-book-selection-publish-2` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-024-book-selection-publish-2` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-024-book-selection-publish-2` names visible UI elements, visible text, persona `owner`, workflow `book-selection-publish`, and the exact product UX issue.
- Screen row `b25-v4-row-037-soccer-minor-redaction-0` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-037-soccer-minor-redaction-0` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-037-soccer-minor-redaction-0` names visible UI elements, visible text, persona `guardian`, workflow `soccer-minor-redaction`, and the exact product UX issue.
- Primary surface for `soccer-minor-redaction` is documented as `protected youth roster/profile surface with minor-data redaction, guardian visibility, and coach-only detail state` or another explicit domain-native surface.
- After-screenshot visible text proves every required semantic surface group for `soccer-minor-redaction`.
- Screen row `b25-v4-row-038-soccer-minor-redaction-1` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-038-soccer-minor-redaction-1` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-038-soccer-minor-redaction-1` names visible UI elements, visible text, persona `guardian`, workflow `soccer-minor-redaction`, and the exact product UX issue.
- Screen row `b25-v4-row-039-soccer-minor-redaction-2` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-039-soccer-minor-redaction-2` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-039-soccer-minor-redaction-2` names visible UI elements, visible text, persona `guardian`, workflow `soccer-minor-redaction`, and the exact product UX issue.
- Screen row `b25-v4-row-043-soccer-practice-schedule-0` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-043-soccer-practice-schedule-0` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-043-soccer-practice-schedule-0` names visible UI elements, visible text, persona `guardian`, workflow `soccer-practice-schedule`, and the exact product UX issue.
- Primary surface for `soccer-practice-schedule` is documented as `event detail with schedule, location, capacity/status, RSVP action, and result state` or another explicit domain-native surface.
- After-screenshot visible text proves every required semantic surface group for `soccer-practice-schedule`.
- Screen row `b25-v4-row-044-soccer-practice-schedule-1` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-044-soccer-practice-schedule-1` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-044-soccer-practice-schedule-1` names visible UI elements, visible text, persona `guardian`, workflow `soccer-practice-schedule`, and the exact product UX issue.
- Screen row `b25-v4-row-045-soccer-practice-schedule-2` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-045-soccer-practice-schedule-2` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-045-soccer-practice-schedule-2` names visible UI elements, visible text, persona `guardian`, workflow `soccer-practice-schedule`, and the exact product UX issue.

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
| Ticket IDs | B25-RT-001-b25-c03-production-grade-experience, B25-RT-002-b25-c04-modern-intentional-ui, B25-RT-003-b25-c05-community-content-ia, B25-RT-004-b25-c06-domain-native-primary-surfaces, B25-RT-005-b25-c08-visible-text-specific-critique, B25-RT-006-b25-c09-no-layout-production-defects |

### Worker Actions
- Rebuild and relaunch the Demo App on the reviewed emulator/device.
- Recapture affected screenshots with hashes, timestamps, device metadata, and app commit SHA.
- Regenerate B25 schema v4 review JSON, markdown review, screen matrix, remediation tickets, and iteration scorecard.
- Commit the full iteration before starting the next UX feedback loop.

### Implementation Guidance
- Inspect `apps/loom_communities_demo/lib` for the primary community home, shell, card, detail, and workflow surface widgets.
- Compare every change against `docs/Build Plan V2/Evidence/B25/production-ux-blueprint.md` before coding.
- Update widget tests and B25 evidence expectations when user-facing hierarchy, copy, or surface structure changes.
- Inspect workflow surface builders and replace primary generic card/checklist/modal renderers with task-specific widgets.
- Use B21 production UX contracts to choose the target surface type for each workflow/persona pair.
- Update screenshot evidence manifests so each replaced surface is captured at entry, action, and result states.
- Update the B25 judge/review artifact, not only app UI code.
- Fill `screenRows[].visibleTextExtract`, `screenRows[].screenSpecificCritique`, `holisticQuestionAnswers`, and `workflowPersonaScorecards` with screenshot-specific content.
- Regenerate markdown review and matrix files from the updated schema v4 JSON.

### Likely Files / Widgets
- `app/apps/loom_communities_demo/lib/main.dart`
- `app/apps/loom_communities_demo/test/b21_b25_production_ux_test.dart`
- `docs/Build Plan V2/Evidence/B25/production-ux-blueprint.md`
- `docs/Build Plan V2/Evidence/B25/independent-production-ux-review.json`
- `docs/Build Plan V2/Evidence/B25/product-ux-screen-review-matrix.md`
- `app/apps/loom_communities_demo/integration_test/workflow_ui_evidence_test.dart`
- `app/apps/loom_communities_demo/test/workflow_ui_test_harness.dart`
- `app/packages/tooling/loom_ux_judges/lib/loom_ux_judges.dart`
- `docs/Build Plan V2/Evidence/B25/independent-production-ux-review.md`

### UX Reference Patterns To Copy

| Reference | Source | URL | What to copy |
| --- | --- | --- | --- |
| Material navigation and information architecture | Material Design 3 / design-system | https://m3.material.io/components/navigation-drawer/overview<br>Also: https://m3.material.io/components/navigation-bar/overview | Organize screens by user jobs and destinations; keep primary actions visible and avoid exposing implementation taxonomy. |
| Apple HIG navigation and content organization | Apple Human Interface Guidelines / design-system | https://developer.apple.com/design/human-interface-guidelines/navigation | Make navigation predictable, content-centered, and appropriate for the user’s current task. |
| Material Design cards and lists | Material Design 3 / design-system | https://m3.material.io/components/cards/overview<br>Also: https://m3.material.io/components/lists/overview | Use cards/lists only as scannable containers with clear hierarchy, content, metadata, and actions. Do not use repeated cards as the whole primary workflow. |
| Flutter sample app implementation patterns | flutter/samples / open-source | https://github.com/flutter/samples | Copy the separation between app shell, route state, domain widgets, and testable UI states rather than hardcoding a single generic renderer. |
| Material detail surface composition | Material Design 3 / design-system | https://m3.material.io/components/cards/overview | Build a domain detail page with primary content, metadata, status, and actions instead of a generic task card. |
| Feed item and composer pattern | Material cards/lists/text fields / pattern | https://m3.material.io/components/text-fields/overview<br>Also: https://m3.material.io/components/cards/overview<br>https://m3.material.io/components/lists/overview | Copy a feed/composer structure: audience, author, timestamp, body, attachments/status, publish action, and receiver read state. |
| Event detail and RSVP flow | Material cards/lists/buttons / pattern | https://m3.material.io/components/cards/overview<br>Also: https://m3.material.io/components/buttons/overview<br>https://m3.material.io/components/chips/overview | Copy an event detail layout: title, date/time, location, host, capacity/status chip, attendee context, RSVP action, and confirmation state. |
| Document list/detail pattern | Material lists/cards / pattern | https://m3.material.io/components/lists/overview | Copy a document library with title, category, audience, file metadata, access state, download/view action, and empty/error states. |
| Screenshot-first critique method | B25 production UX gate / methodology | docs/Build Plan V2/Tools/b25-remediation-ticket-template.md | Critique must quote visible UI/text, name the persona and task, compare against the chosen reference pattern, and state the exact fix. |

### Reference Research Queries
- production mobile UX review screenshot critique examples
- open source Flutter mobile app UX patterns GitHub
- modern mobile app information architecture visual hierarchy examples
- Material Design 3 mobile UI hierarchy navigation cards examples
- open source Flutter production app dashboard detail screen examples
- community app home screen announcements events messages design examples
- open source Flutter community app home feed events messages UI
- domain specific mobile workflow UI event RSVP donation message export examples
- open source Flutter event RSVP donation messaging workflow UI examples
- open source Flutter announcement-feed mobile UI example GitHub
- announcement feed/composer with audience, author, timestamp, body, and receiver state mobile UX pattern
- Material Design announcement feed/composer with audience, author, timestamp, body, and receiver state mobile pattern
- open source Flutter domain-native-surface mobile UI example GitHub
- protected youth roster/profile surface with minor-data redaction, guardian visibility, and coach-only detail state mobile UX pattern
- Material Design protected youth roster/profile surface with minor-data redaction, guardian visibility, and coach-only detail state mobile pattern
- open source Flutter event-rsvp mobile UI example GitHub
- event detail with schedule, location, capacity/status, RSVP action, and result state mobile UX pattern
- Material Design event detail with schedule, location, capacity/status, RSVP action, and result state mobile pattern
- notification inbox/detail surface with sender, audience, timestamp, message body, and receiver state mobile UX pattern
- Material Design notification inbox/detail surface with sender, audience, timestamp, message body, and receiver state mobile pattern

### Evidence Repair Work Items

Showing 10 of 10 work items. Full detail is in the JSON artifact.

| Work item | Stage | Community | Workflow | Persona | Screens | Coverage | Target surface | Blocked until |
| --- | --- | --- | --- | --- | ---: | ---: | --- | --- |
| `b25-wi-evidence-repair-community-book-club-book-selection-publish-community-book-club-owner` | `evidence-repair` | Neighborhood Book Club | `book-selection-publish` | owner | 3 | 1 | announcement feed/composer with audience, author, timestamp, body, and receiver state |  |
| `b25-wi-evidence-repair-community-youth-soccer-soccer-minor-redaction-community-youth-soccer-guardian` | `evidence-repair` | Riverside Youth Soccer | `soccer-minor-redaction` | guardian | 3 | 1 | protected youth roster/profile surface with minor-data redaction, guardian visibility, and coach-only detail state |  |
| `b25-wi-evidence-repair-community-youth-soccer-soccer-practice-schedule-community-youth-soccer-guardian` | `evidence-repair` | Riverside Youth Soccer | `soccer-practice-schedule` | guardian | 3 | 1 | event detail with schedule, location, capacity/status, RSVP action, and result state |  |
| `b25-wi-evidence-repair-community-youth-soccer-soccer-reminder-notification-community-youth-soccer-guardian` | `evidence-repair` | Riverside Youth Soccer | `soccer-reminder-notification` | guardian | 3 | 1 | notification inbox/detail surface with sender, audience, timestamp, message body, and receiver state |  |
| `b25-wi-evidence-repair-community-hoa-hoa-member-document-community-hoa-member` | `evidence-repair` | Cedar Commons HOA | `hoa-member-document` | member | 3 | 1 | document library/detail surface with title, audience, file metadata, and access state |  |
| `b25-wi-evidence-repair-community-hoa-hoa-owner-notification-community-hoa-owner` | `evidence-repair` | Cedar Commons HOA | `hoa-owner-notification` | owner | 3 | 1 | notification inbox/detail surface with sender, audience, timestamp, message body, and receiver state |  |
| `b25-wi-evidence-repair-community-mosque-mosque-announcement-community-mosque-owner` | `evidence-repair` | Masjid Nur | `mosque-announcement` | owner | 3 | 1 | announcement feed/composer with audience, author, timestamp, body, and receiver state |  |
| `b25-wi-evidence-repair-community-mosque-mosque-neutral-notification-community-mosque-member` | `evidence-repair` | Masjid Nur | `mosque-neutral-notification` | member | 3 | 1 | notification inbox/detail surface with sender, audience, timestamp, message body, and receiver state |  |
| `b25-wi-evidence-repair-community-platform-social-platform-top-banner-no-fill-community-platform-social-member` | `evidence-repair` | Member Social Space | `platform-top-banner-no-fill` | member | 3 | 1 | App Shell top banner ad slot no-fill surface with preserved layout, disclosure/reserved space, and no content overlap |  |
| `b25-wi-evidence-repair-community-platform-social-platform-sensitive-no-fill-community-platform-social-member` | `evidence-repair` | Member Social Space | `platform-sensitive-no-fill` | member | 3 | 1 | sensitive-context ad suppression surface with protected content visible and ad slot safely no-filled |  |

### Evidence Repair Work Items Reference Patterns

| Reference | Source | URL | What to copy |
| --- | --- | --- | --- |
| Feed item and composer pattern | Material cards/lists/text fields / pattern | https://m3.material.io/components/text-fields/overview<br>Also: https://m3.material.io/components/cards/overview<br>https://m3.material.io/components/lists/overview | Copy a feed/composer structure: audience, author, timestamp, body, attachments/status, publish action, and receiver read state. |
| Material Design cards and lists | Material Design 3 / design-system | https://m3.material.io/components/cards/overview<br>Also: https://m3.material.io/components/lists/overview | Use cards/lists only as scannable containers with clear hierarchy, content, metadata, and actions. Do not use repeated cards as the whole primary workflow. |
| Flutter sample app implementation patterns | flutter/samples / open-source | https://github.com/flutter/samples | Copy the separation between app shell, route state, domain widgets, and testable UI states rather than hardcoding a single generic renderer. |
| Material navigation and information architecture | Material Design 3 / design-system | https://m3.material.io/components/navigation-drawer/overview<br>Also: https://m3.material.io/components/navigation-bar/overview | Organize screens by user jobs and destinations; keep primary actions visible and avoid exposing implementation taxonomy. |
| Apple HIG navigation and content organization | Apple Human Interface Guidelines / design-system | https://developer.apple.com/design/human-interface-guidelines/navigation | Make navigation predictable, content-centered, and appropriate for the user’s current task. |
| Material detail surface composition | Material Design 3 / design-system | https://m3.material.io/components/cards/overview | Build a domain detail page with primary content, metadata, status, and actions instead of a generic task card. |
| Event detail and RSVP flow | Material cards/lists/buttons / pattern | https://m3.material.io/components/cards/overview<br>Also: https://m3.material.io/components/buttons/overview<br>https://m3.material.io/components/chips/overview | Copy an event detail layout: title, date/time, location, host, capacity/status chip, attendee context, RSVP action, and confirmation state. |
| Document list/detail pattern | Material lists/cards / pattern | https://m3.material.io/components/lists/overview | Copy a document library with title, category, audience, file metadata, access state, download/view action, and empty/error states. |

### UI Remediation Work Items

Showing 10 of 10 work items. Full detail is in the JSON artifact.

| Work item | Stage | Community | Workflow | Persona | Screens | Coverage | Target surface | Blocked until |
| --- | --- | --- | --- | --- | ---: | ---: | --- | --- |
| `b25-wi-ui-remediation-community-book-club-book-selection-publish-community-book-club-owner` | `ui-remediation` | Neighborhood Book Club | `book-selection-publish` | owner | 3 | 1 | announcement feed/composer with audience, author, timestamp, body, and receiver state | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-youth-soccer-soccer-minor-redaction-community-youth-soccer-guardian` | `ui-remediation` | Riverside Youth Soccer | `soccer-minor-redaction` | guardian | 3 | 1 | protected youth roster/profile surface with minor-data redaction, guardian visibility, and coach-only detail state | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-youth-soccer-soccer-practice-schedule-community-youth-soccer-guardian` | `ui-remediation` | Riverside Youth Soccer | `soccer-practice-schedule` | guardian | 3 | 1 | event detail with schedule, location, capacity/status, RSVP action, and result state | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-youth-soccer-soccer-reminder-notification-community-youth-soccer-guardian` | `ui-remediation` | Riverside Youth Soccer | `soccer-reminder-notification` | guardian | 3 | 1 | notification inbox/detail surface with sender, audience, timestamp, message body, and receiver state | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-hoa-hoa-member-document-community-hoa-member` | `ui-remediation` | Cedar Commons HOA | `hoa-member-document` | member | 3 | 1 | document library/detail surface with title, audience, file metadata, and access state | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-hoa-hoa-owner-notification-community-hoa-owner` | `ui-remediation` | Cedar Commons HOA | `hoa-owner-notification` | owner | 3 | 1 | notification inbox/detail surface with sender, audience, timestamp, message body, and receiver state | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-mosque-mosque-announcement-community-mosque-owner` | `ui-remediation` | Masjid Nur | `mosque-announcement` | owner | 3 | 1 | announcement feed/composer with audience, author, timestamp, body, and receiver state | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-mosque-mosque-neutral-notification-community-mosque-member` | `ui-remediation` | Masjid Nur | `mosque-neutral-notification` | member | 3 | 1 | notification inbox/detail surface with sender, audience, timestamp, message body, and receiver state | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-platform-social-platform-top-banner-no-fill-community-platform-social-member` | `ui-remediation` | Member Social Space | `platform-top-banner-no-fill` | member | 3 | 1 | App Shell top banner ad slot no-fill surface with preserved layout, disclosure/reserved space, and no content overlap | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-platform-social-platform-sensitive-no-fill-community-platform-social-member` | `ui-remediation` | Member Social Space | `platform-sensitive-no-fill` | member | 3 | 1 | sensitive-context ad suppression surface with protected content visible and ad slot safely no-filled | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |

### UI Remediation Work Items Reference Patterns

| Reference | Source | URL | What to copy |
| --- | --- | --- | --- |
| Feed item and composer pattern | Material cards/lists/text fields / pattern | https://m3.material.io/components/text-fields/overview<br>Also: https://m3.material.io/components/cards/overview<br>https://m3.material.io/components/lists/overview | Copy a feed/composer structure: audience, author, timestamp, body, attachments/status, publish action, and receiver read state. |
| Material Design cards and lists | Material Design 3 / design-system | https://m3.material.io/components/cards/overview<br>Also: https://m3.material.io/components/lists/overview | Use cards/lists only as scannable containers with clear hierarchy, content, metadata, and actions. Do not use repeated cards as the whole primary workflow. |
| Flutter sample app implementation patterns | flutter/samples / open-source | https://github.com/flutter/samples | Copy the separation between app shell, route state, domain widgets, and testable UI states rather than hardcoding a single generic renderer. |
| Material navigation and information architecture | Material Design 3 / design-system | https://m3.material.io/components/navigation-drawer/overview<br>Also: https://m3.material.io/components/navigation-bar/overview | Organize screens by user jobs and destinations; keep primary actions visible and avoid exposing implementation taxonomy. |
| Apple HIG navigation and content organization | Apple Human Interface Guidelines / design-system | https://developer.apple.com/design/human-interface-guidelines/navigation | Make navigation predictable, content-centered, and appropriate for the user’s current task. |
| Material detail surface composition | Material Design 3 / design-system | https://m3.material.io/components/cards/overview | Build a domain detail page with primary content, metadata, status, and actions instead of a generic task card. |
| Event detail and RSVP flow | Material cards/lists/buttons / pattern | https://m3.material.io/components/cards/overview<br>Also: https://m3.material.io/components/buttons/overview<br>https://m3.material.io/components/chips/overview | Copy an event detail layout: title, date/time, location, host, capacity/status chip, attendee context, RSVP action, and confirmation state. |
| Document list/detail pattern | Material lists/cards / pattern | https://m3.material.io/components/lists/overview | Copy a document library with title, category, audience, file metadata, access state, download/view action, and empty/error states. |

### Affected Coverage Rows

Showing 10 of 10 affected coverage rows.

| Coverage row | Community | Workflow | Persona | Missing evidence |
| --- | --- | --- | --- | --- |
| `b25-wp-008-book-selection-publish-community-book-club-owner` | Neighborhood Book Club | `book-selection-publish` | owner |  |
| `b25-wp-013-soccer-minor-redaction-community-youth-soccer-guardian` | Riverside Youth Soccer | `soccer-minor-redaction` | guardian |  |
| `b25-wp-015-soccer-practice-schedule-community-youth-soccer-guardian` | Riverside Youth Soccer | `soccer-practice-schedule` | guardian |  |
| `b25-wp-016-soccer-reminder-notification-community-youth-soccer-guardian` | Riverside Youth Soccer | `soccer-reminder-notification` | guardian |  |
| `b25-wp-019-hoa-member-document-community-hoa-member` | Cedar Commons HOA | `hoa-member-document` | member |  |
| `b25-wp-023-hoa-owner-notification-community-hoa-owner` | Cedar Commons HOA | `hoa-owner-notification` | owner |  |
| `b25-wp-025-mosque-announcement-community-mosque-owner` | Masjid Nur | `mosque-announcement` | owner |  |
| `b25-wp-031-mosque-neutral-notification-community-mosque-member` | Masjid Nur | `mosque-neutral-notification` | member |  |
| `b25-wp-045-platform-top-banner-no-fill-community-platform-social-member` | Member Social Space | `platform-top-banner-no-fill` | member |  |
| `b25-wp-046-platform-sensitive-no-fill-community-platform-social-member` | Member Social Space | `platform-sensitive-no-fill` | member |  |

### Affected Screen Rows

Showing 30 of 30 affected screen rows.

| Screen row | Community | Workflow | Persona | State | Exact UX failure |
| --- | --- | --- | --- | --- | --- |
| `b25-v4-row-022-book-selection-publish-0` | Neighborhood Book Club | `book-selection-publish` | owner | B14_ext_book_club_book-selection-publish_start | Ticket must add screenshot-backed visible text and a non-reusable critique for this exact screen. |
| `b25-v4-row-023-book-selection-publish-1` | Neighborhood Book Club | `book-selection-publish` | owner | B14_ext_book_club_book-selection-publish_action | Ticket must add screenshot-backed visible text and a non-reusable critique for this exact screen. |
| `b25-v4-row-024-book-selection-publish-2` | Neighborhood Book Club | `book-selection-publish` | owner | B14_ext_book_club_book-selection-publish_complete | Ticket must add screenshot-backed visible text and a non-reusable critique for this exact screen. |
| `b25-v4-row-037-soccer-minor-redaction-0` | Riverside Youth Soccer | `soccer-minor-redaction` | guardian | B14_ext_youth_soccer_soccer-minor-redaction_start | Ticket must add screenshot-backed visible text and a non-reusable critique for this exact screen. |
| `b25-v4-row-038-soccer-minor-redaction-1` | Riverside Youth Soccer | `soccer-minor-redaction` | guardian | B14_ext_youth_soccer_soccer-minor-redaction_action | Ticket must add screenshot-backed visible text and a non-reusable critique for this exact screen. |
| `b25-v4-row-039-soccer-minor-redaction-2` | Riverside Youth Soccer | `soccer-minor-redaction` | guardian | B14_ext_youth_soccer_soccer-minor-redaction_complete | Ticket must add screenshot-backed visible text and a non-reusable critique for this exact screen. |
| `b25-v4-row-043-soccer-practice-schedule-0` | Riverside Youth Soccer | `soccer-practice-schedule` | guardian | B14_ext_youth_soccer_soccer-practice-schedule_start | Ticket must add screenshot-backed visible text and a non-reusable critique for this exact screen. |
| `b25-v4-row-044-soccer-practice-schedule-1` | Riverside Youth Soccer | `soccer-practice-schedule` | guardian | B14_ext_youth_soccer_soccer-practice-schedule_action | Ticket must add screenshot-backed visible text and a non-reusable critique for this exact screen. |
| `b25-v4-row-045-soccer-practice-schedule-2` | Riverside Youth Soccer | `soccer-practice-schedule` | guardian | B14_ext_youth_soccer_soccer-practice-schedule_complete | Ticket must add screenshot-backed visible text and a non-reusable critique for this exact screen. |
| `b25-v4-row-046-soccer-reminder-notification-0` | Riverside Youth Soccer | `soccer-reminder-notification` | guardian | B14_ext_youth_soccer_soccer-reminder-notification_start | Ticket must add screenshot-backed visible text and a non-reusable critique for this exact screen. |
| `b25-v4-row-047-soccer-reminder-notification-1` | Riverside Youth Soccer | `soccer-reminder-notification` | guardian | B14_ext_youth_soccer_soccer-reminder-notification_action | Ticket must add screenshot-backed visible text and a non-reusable critique for this exact screen. |
| `b25-v4-row-048-soccer-reminder-notification-2` | Riverside Youth Soccer | `soccer-reminder-notification` | guardian | B14_ext_youth_soccer_soccer-reminder-notification_complete | Ticket must add screenshot-backed visible text and a non-reusable critique for this exact screen. |
| `b25-v4-row-055-hoa-member-document-0` | Cedar Commons HOA | `hoa-member-document` | member | B14_ext_hoa_hoa-member-document_start | Ticket must add screenshot-backed visible text and a non-reusable critique for this exact screen. |
| `b25-v4-row-056-hoa-member-document-1` | Cedar Commons HOA | `hoa-member-document` | member | B14_ext_hoa_hoa-member-document_action | Ticket must add screenshot-backed visible text and a non-reusable critique for this exact screen. |
| `b25-v4-row-057-hoa-member-document-2` | Cedar Commons HOA | `hoa-member-document` | member | B14_ext_hoa_hoa-member-document_complete | Ticket must add screenshot-backed visible text and a non-reusable critique for this exact screen. |
| `b25-v4-row-067-hoa-owner-notification-0` | Cedar Commons HOA | `hoa-owner-notification` | owner | B14_ext_hoa_hoa-owner-notification_start | Ticket must add screenshot-backed visible text and a non-reusable critique for this exact screen. |
| `b25-v4-row-068-hoa-owner-notification-1` | Cedar Commons HOA | `hoa-owner-notification` | owner | B14_ext_hoa_hoa-owner-notification_action | Ticket must add screenshot-backed visible text and a non-reusable critique for this exact screen. |
| `b25-v4-row-069-hoa-owner-notification-2` | Cedar Commons HOA | `hoa-owner-notification` | owner | B14_ext_hoa_hoa-owner-notification_complete | Ticket must add screenshot-backed visible text and a non-reusable critique for this exact screen. |
| `b25-v4-row-073-mosque-announcement-0` | Masjid Nur | `mosque-announcement` | owner | B14_ext_mosque_mosque-announcement_start | Ticket must add screenshot-backed visible text and a non-reusable critique for this exact screen. |
| `b25-v4-row-074-mosque-announcement-1` | Masjid Nur | `mosque-announcement` | owner | B14_ext_mosque_mosque-announcement_action | Ticket must add screenshot-backed visible text and a non-reusable critique for this exact screen. |
| `b25-v4-row-075-mosque-announcement-2` | Masjid Nur | `mosque-announcement` | owner | B14_ext_mosque_mosque-announcement_complete | Ticket must add screenshot-backed visible text and a non-reusable critique for this exact screen. |
| `b25-v4-row-091-mosque-neutral-notification-0` | Masjid Nur | `mosque-neutral-notification` | member | B14_ext_mosque_mosque-neutral-notification_start | Ticket must add screenshot-backed visible text and a non-reusable critique for this exact screen. |
| `b25-v4-row-092-mosque-neutral-notification-1` | Masjid Nur | `mosque-neutral-notification` | member | B14_ext_mosque_mosque-neutral-notification_action | Ticket must add screenshot-backed visible text and a non-reusable critique for this exact screen. |
| `b25-v4-row-093-mosque-neutral-notification-2` | Masjid Nur | `mosque-neutral-notification` | member | B14_ext_mosque_mosque-neutral-notification_complete | Ticket must add screenshot-backed visible text and a non-reusable critique for this exact screen. |
| `b25-v4-row-133-platform-top-banner-no-fill-0` | Member Social Space | `platform-top-banner-no-fill` | member | B16_ext_platform_social_platform-top-banner-no-fill_start | Ticket must add screenshot-backed visible text and a non-reusable critique for this exact screen. |
| `b25-v4-row-134-platform-top-banner-no-fill-1` | Member Social Space | `platform-top-banner-no-fill` | member | B16_ext_platform_social_platform-top-banner-no-fill_action | Ticket must add screenshot-backed visible text and a non-reusable critique for this exact screen. |
| `b25-v4-row-135-platform-top-banner-no-fill-2` | Member Social Space | `platform-top-banner-no-fill` | member | B16_ext_platform_social_platform-top-banner-no-fill_complete | Ticket must add screenshot-backed visible text and a non-reusable critique for this exact screen. |
| `b25-v4-row-136-platform-sensitive-no-fill-0` | Member Social Space | `platform-sensitive-no-fill` | member | B16_ext_platform_social_platform-sensitive-no-fill_start | Ticket must add screenshot-backed visible text and a non-reusable critique for this exact screen. |
| `b25-v4-row-137-platform-sensitive-no-fill-1` | Member Social Space | `platform-sensitive-no-fill` | member | B16_ext_platform_social_platform-sensitive-no-fill_action | Ticket must add screenshot-backed visible text and a non-reusable critique for this exact screen. |
| `b25-v4-row-138-platform-sensitive-no-fill-2` | Member Social Space | `platform-sensitive-no-fill` | member | B16_ext_platform_social_platform-sensitive-no-fill_complete | Ticket must add screenshot-backed visible text and a non-reusable critique for this exact screen. |

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
- Screen row `b25-v4-row-022-book-selection-publish-0` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-022-book-selection-publish-0` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-022-book-selection-publish-0` names visible UI elements, visible text, persona `owner`, workflow `book-selection-publish`, and the exact product UX issue.
- Primary surface for `book-selection-publish` is documented as `announcement feed/composer with audience, author, timestamp, body, and receiver state` or another explicit domain-native surface.
- After-screenshot visible text proves every required semantic surface group for `book-selection-publish`.
- Fresh screenshot path/hash/timestamp/app commit SHA are recorded after the fix.
- The workflow/persona direct-question scorecard passes the domain-native primary surface question.
- Screen row `b25-v4-row-023-book-selection-publish-1` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-023-book-selection-publish-1` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-023-book-selection-publish-1` names visible UI elements, visible text, persona `owner`, workflow `book-selection-publish`, and the exact product UX issue.
- Screen row `b25-v4-row-024-book-selection-publish-2` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-024-book-selection-publish-2` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-024-book-selection-publish-2` names visible UI elements, visible text, persona `owner`, workflow `book-selection-publish`, and the exact product UX issue.
- Screen row `b25-v4-row-037-soccer-minor-redaction-0` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-037-soccer-minor-redaction-0` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-037-soccer-minor-redaction-0` names visible UI elements, visible text, persona `guardian`, workflow `soccer-minor-redaction`, and the exact product UX issue.
- Primary surface for `soccer-minor-redaction` is documented as `protected youth roster/profile surface with minor-data redaction, guardian visibility, and coach-only detail state` or another explicit domain-native surface.
- After-screenshot visible text proves every required semantic surface group for `soccer-minor-redaction`.
- Screen row `b25-v4-row-038-soccer-minor-redaction-1` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-038-soccer-minor-redaction-1` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-038-soccer-minor-redaction-1` names visible UI elements, visible text, persona `guardian`, workflow `soccer-minor-redaction`, and the exact product UX issue.
- Screen row `b25-v4-row-039-soccer-minor-redaction-2` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-039-soccer-minor-redaction-2` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-039-soccer-minor-redaction-2` names visible UI elements, visible text, persona `guardian`, workflow `soccer-minor-redaction`, and the exact product UX issue.
- Screen row `b25-v4-row-043-soccer-practice-schedule-0` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-043-soccer-practice-schedule-0` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-043-soccer-practice-schedule-0` names visible UI elements, visible text, persona `guardian`, workflow `soccer-practice-schedule`, and the exact product UX issue.
- Primary surface for `soccer-practice-schedule` is documented as `event detail with schedule, location, capacity/status, RSVP action, and result state` or another explicit domain-native surface.
- After-screenshot visible text proves every required semantic surface group for `soccer-practice-schedule`.
- Screen row `b25-v4-row-044-soccer-practice-schedule-1` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-044-soccer-practice-schedule-1` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-044-soccer-practice-schedule-1` names visible UI elements, visible text, persona `guardian`, workflow `soccer-practice-schedule`, and the exact product UX issue.
- Screen row `b25-v4-row-045-soccer-practice-schedule-2` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-045-soccer-practice-schedule-2` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-045-soccer-practice-schedule-2` names visible UI elements, visible text, persona `guardian`, workflow `soccer-practice-schedule`, and the exact product UX issue.

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
