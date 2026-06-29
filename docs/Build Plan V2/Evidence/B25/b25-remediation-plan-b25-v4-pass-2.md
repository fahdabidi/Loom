# B25 Remediation Plan

| Field | Value |
| --- | --- |
| Review run | `b25-v4-pass-1` |
| Status | `open` |
| Source tickets | `../docs/Build Plan V2/Evidence/B25/b25-remediation-tickets-b25-v4-pass-1.json` |
| Ticket count | 7 |
| Scorecard status | `fail` |
| Remaining blocker/major | 4 |
| Blocking criteria failures | 7 |
| Evidence repair work items | 70 |
| UI remediation work items | 70 |
| Work item sequencing | Evidence repair work items must be completed and rerun before matching UI remediation work items are assigned. |

## Source Tickets

| Ticket | Source criterion | Severity | Status | Title |
| --- | --- | --- | --- | --- |
| `B25-RT-001-b25-c01-no-blocker-major` | `b25-c01-no-blocker-major` | major | open | No unresolved blocker or major findings |
| `B25-RT-002-b25-c03-production-grade-experience` | `b25-c03-production-grade-experience` | major | open | Reviewer can state the experience feels production-grade |
| `B25-RT-003-b25-c04-modern-intentional-ui` | `b25-c04-modern-intentional-ui` | major | open | UI looks modern and intentionally designed |
| `B25-RT-004-b25-c05-community-content-ia` | `b25-c05-community-content-ia` | major | open | Screens are organized around community content and jobs-to-be-done |
| `B25-RT-005-b25-c06-domain-native-primary-surfaces` | `b25-c06-domain-native-primary-surfaces` | major | open | Primary workflows use domain-specific product surfaces |
| `B25-RT-006-b25-c08-visible-text-specific-critique` | `b25-c08-visible-text-specific-critique` | major | open | Every row has visible text and screen-specific critique |
| `B25-RT-007-b25-c09-no-layout-production-defects` | `b25-c09-no-layout-production-defects` | major | open | No blocking or major layout/content defects remain |

## B25-RB-001-independent-review-evidence: Complete independent review evidence and critique

Turn captured screenshots into complete independent UX review evidence before attempting UI remediation.

| Field | Value |
| --- | --- |
| Status | open |
| Ticket IDs | B25-RT-002-b25-c03-production-grade-experience, B25-RT-003-b25-c04-modern-intentional-ui, B25-RT-006-b25-c08-visible-text-specific-critique, B25-RT-007-b25-c09-no-layout-production-defects |

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
| Event detail and RSVP flow | Material cards/lists/buttons / pattern | https://m3.material.io/components/cards/overview<br>Also: https://m3.material.io/components/buttons/overview<br>https://m3.material.io/components/chips/overview | Copy an event detail layout: title, date/time, location, host, capacity/status chip, attendee context, RSVP action, and confirmation state. |
| Task list and export wizard | GOV.UK Design System / design-system | https://design-system.service.gov.uk/components/task-list/<br>Also: https://design-system.service.gov.uk/patterns/check-answers/ | Copy a wizard with steps, preview, redaction choices, checksum evidence, transfer status, and rollback confirmation. |
| Selection and voting pattern | Material chips/cards/buttons / pattern | https://m3.material.io/components/chips/overview<br>Also: https://m3.material.io/components/cards/overview | Copy a nomination/voting surface with choices, current vote state, deadline, selected result, and meeting/discussion context. |
| Inbox and message thread pattern | Material lists/text fields / pattern | https://m3.material.io/components/lists/overview<br>Also: https://m3.material.io/components/text-fields/overview | Copy an inbox/thread structure: sender, timestamp, message preview/body, reply field, invite/block state, and read/received state. |
| Feed item and composer pattern | Material cards/lists/text fields / pattern | https://m3.material.io/components/text-fields/overview<br>Also: https://m3.material.io/components/cards/overview<br>https://m3.material.io/components/lists/overview | Copy a feed/composer structure: audience, author, timestamp, body, attachments/status, publish action, and receiver read state. |
| Search and result list pattern | Material Design 3 / design-system | https://m3.material.io/components/search/overview<br>Also: https://m3.material.io/components/lists/overview | Copy a search layout with query, filters, ranked results, citations/sources, empty/error states, and follow-up actions. |
| Form validation and review pattern | U.S. Web Design System / design-system | https://designsystem.digital.gov/components/form/<br>Also: https://designsystem.digital.gov/components/alert/<br>https://design-system.service.gov.uk/components/error-summary/ | Copy a form flow with field labels, helper text, validation errors, review state, submit action, status, and protected-data treatment. |
| Roster/list with protected details | Material Design 3 / design-system | https://m3.material.io/components/data-tables/overview<br>Also: https://m3.material.io/components/lists/overview | Copy a roster with member names, roles, status, role-filtered fields, and clear protected-data redaction. |
| Review-and-confirm payment flow | GOV.UK Design System / design-system | https://design-system.service.gov.uk/patterns/check-answers/ | Use a review/confirmation step with amount, payer context, recipient, fees or entitlement, receipt, and audit trail. |
| Multi-step payment/progress flow | U.S. Web Design System / design-system | https://designsystem.digital.gov/components/step-indicator/ | Use explicit progress states for checkout, review, confirmation, receipt, and entitlement/status. |
| Reservation detail and availability flow | Material cards/forms / pattern | https://m3.material.io/components/date-pickers/overview<br>Also: https://m3.material.io/components/cards/overview | Copy an availability/reservation flow with facility details, date/time, capacity/rules, payment/status when needed, and confirmation. |
| Match schedule and result pattern | Material lists/cards / pattern | https://m3.material.io/components/lists/overview | Copy a match surface with players, schedule/round, result entry, result state, and next action. |
| Screenshot-first critique method | B25 production UX gate / methodology | docs/Build Plan V2/Tools/b25-remediation-ticket-template.md | Critique must quote visible UI/text, name the persona and task, compare against the chosen reference pattern, and state the exact fix. |
| Document list/detail pattern | Material lists/cards / pattern | https://m3.material.io/components/lists/overview | Copy a document library with title, category, audience, file metadata, access state, download/view action, and empty/error states. |

### Reference Research Queries
- production mobile UX review screenshot critique examples
- open source Flutter mobile app UX patterns GitHub
- open source Flutter domain-native-surface mobile UI example GitHub
- explicit domain-native product surface selected from the B21 production UX contract mobile UX pattern
- Material Design explicit domain-native product surface selected from the B21 production UX contract mobile pattern
- open source Flutter event-rsvp mobile UI example GitHub
- event detail with schedule, location, capacity/status, RSVP action, and result state mobile UX pattern
- Material Design event detail with schedule, location, capacity/status, RSVP action, and result state mobile pattern
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

### Evidence Repair Work Items

Showing 30 of 70 work items. Full detail is in the JSON artifact.

| Work item | Stage | Community | Workflow | Persona | Screens | Coverage | Target surface | Blocked until |
| --- | --- | --- | --- | --- | ---: | ---: | --- | --- |
| `b25-wi-evidence-repair-workflow-ui-evidence-harness-workflow-ui-evidence-harness-persona-under-review` | `evidence-repair` | workflow-ui-evidence-harness | `workflow-ui-evidence-harness` | persona-under-review | 3 | 1 | explicit domain-native product surface selected from the B21 production UX contract |  |
| `b25-wi-evidence-repair-community-garden-club-garden-event-rsvp-persona-under-review` | `evidence-repair` | Garden Club | `garden-event-rsvp` | persona-under-review | 3 | 1 | event detail with schedule, location, capacity/status, RSVP action, and result state |  |
| `b25-wi-evidence-repair-community-garden-club-plant-exchange-submission-persona-under-review` | `evidence-repair` | Garden Club | `plant-exchange-submission` | persona-under-review | 3 | 1 | explicit domain-native product surface selected from the B21 production UX contract |  |
| `b25-wi-evidence-repair-community-garden-club-garden-export-custom-schemas-persona-under-review` | `evidence-repair` | Garden Club | `garden-export-custom-schemas` | persona-under-review | 3 | 1 | export/import wizard with preview, redaction, checksum, transfer status, and rollback state |  |
| `b25-wi-evidence-repair-community-book-club-book-nomination-persona-under-review` | `evidence-repair` | Neighborhood Book Club | `book-nomination` | persona-under-review | 3 | 1 | book club reading/voting surface with nominations, vote state, selected book, meeting context, and discussion |  |
| `b25-wi-evidence-repair-community-book-club-book-vote-persona-under-review` | `evidence-repair` | Neighborhood Book Club | `book-vote` | persona-under-review | 3 | 1 | book club reading/voting surface with nominations, vote state, selected book, meeting context, and discussion |  |
| `b25-wi-evidence-repair-community-book-club-book-meeting-rsvp-persona-under-review` | `evidence-repair` | Neighborhood Book Club | `book-meeting-rsvp` | persona-under-review | 3 | 1 | event detail with schedule, location, capacity/status, RSVP action, and result state |  |
| `b25-wi-evidence-repair-community-book-club-book-discussion-message-persona-under-review` | `evidence-repair` | Neighborhood Book Club | `book-discussion-message` | persona-under-review | 3 | 1 | inbox, message thread, connection card, invite, or block-state surface |  |
| `b25-wi-evidence-repair-community-book-club-book-selection-publish-persona-under-review` | `evidence-repair` | Neighborhood Book Club | `book-selection-publish` | persona-under-review | 3 | 1 | announcement feed/composer with audience, author, timestamp, body, and receiver state |  |
| `b25-wi-evidence-repair-community-book-club-book-search-ai-digest-persona-under-review` | `evidence-repair` | Neighborhood Book Club | `book-search-ai-digest` | persona-under-review | 3 | 1 | search/AI answer surface with query, result, citation, source, and follow-up action |  |
| `b25-wi-evidence-repair-community-book-club-book-export-metadata-persona-under-review` | `evidence-repair` | Neighborhood Book Club | `book-export-metadata` | persona-under-review | 3 | 1 | export/import wizard with preview, redaction, checksum, transfer status, and rollback state |  |
| `b25-wi-evidence-repair-community-youth-soccer-soccer-guardian-join-approval-persona-under-review` | `evidence-repair` | Riverside Youth Soccer | `soccer-guardian-join-approval` | persona-under-review | 3 | 1 | request detail and admin review queue with submitted data, decision action, status, and notification |  |
| `b25-wi-evidence-repair-community-youth-soccer-soccer-team-roster-persona-under-review` | `evidence-repair` | Riverside Youth Soccer | `soccer-team-roster` | persona-under-review | 3 | 1 | team roster/schedule surface with role-filtered member details and protected-data treatment |  |
| `b25-wi-evidence-repair-community-youth-soccer-soccer-minor-redaction-persona-under-review` | `evidence-repair` | Riverside Youth Soccer | `soccer-minor-redaction` | persona-under-review | 3 | 1 | explicit domain-native product surface selected from the B21 production UX contract |  |
| `b25-wi-evidence-repair-community-youth-soccer-soccer-registration-payment-persona-under-review` | `evidence-repair` | Riverside Youth Soccer | `soccer-registration-payment` | persona-under-review | 3 | 1 | payment or donation flow with amount, payer context, receipt, entitlement/status, and audit trail |  |
| `b25-wi-evidence-repair-community-youth-soccer-soccer-practice-schedule-persona-under-review` | `evidence-repair` | Riverside Youth Soccer | `soccer-practice-schedule` | persona-under-review | 3 | 1 | event detail with schedule, location, capacity/status, RSVP action, and result state |  |
| `b25-wi-evidence-repair-community-youth-soccer-soccer-reminder-notification-persona-under-review` | `evidence-repair` | Riverside Youth Soccer | `soccer-reminder-notification` | persona-under-review | 3 | 1 | explicit domain-native product surface selected from the B21 production UX contract |  |
| `b25-wi-evidence-repair-community-youth-soccer-soccer-export-metadata-persona-under-review` | `evidence-repair` | Riverside Youth Soccer | `soccer-export-metadata` | persona-under-review | 3 | 1 | export/import wizard with preview, redaction, checksum, transfer status, and rollback state |  |
| `b25-wi-evidence-repair-community-hoa-hoa-dues-payment-persona-under-review` | `evidence-repair` | Cedar Commons HOA | `hoa-dues-payment` | persona-under-review | 3 | 1 | payment or donation flow with amount, payer context, receipt, entitlement/status, and audit trail |  |
| `b25-wi-evidence-repair-community-hoa-hoa-facility-reservation-persona-under-review` | `evidence-repair` | Cedar Commons HOA | `hoa-facility-reservation` | persona-under-review | 3 | 1 | facility detail/reservation flow with availability, payment/status, and confirmation |  |
| `b25-wi-evidence-repair-community-hoa-hoa-architectural-request-persona-under-review` | `evidence-repair` | Cedar Commons HOA | `hoa-architectural-request` | persona-under-review | 3 | 1 | request detail and admin review queue with submitted data, decision action, status, and notification |  |
| `b25-wi-evidence-repair-community-hoa-hoa-committee-decision-persona-under-review` | `evidence-repair` | Cedar Commons HOA | `hoa-committee-decision` | persona-under-review | 3 | 1 | request detail and admin review queue with submitted data, decision action, status, and notification |  |
| `b25-wi-evidence-repair-community-hoa-hoa-export-evidence-persona-under-review` | `evidence-repair` | Cedar Commons HOA | `hoa-export-evidence` | persona-under-review | 3 | 1 | export/import wizard with preview, redaction, checksum, transfer status, and rollback state |  |
| `b25-wi-evidence-repair-community-mosque-mosque-announcement-persona-under-review` | `evidence-repair` | Masjid Nur | `mosque-announcement` | persona-under-review | 3 | 1 | announcement feed/composer with audience, author, timestamp, body, and receiver state |  |
| `b25-wi-evidence-repair-community-mosque-mosque-event-rsvp-persona-under-review` | `evidence-repair` | Masjid Nur | `mosque-event-rsvp` | persona-under-review | 3 | 1 | event detail with schedule, location, capacity/status, RSVP action, and result state |  |
| `b25-wi-evidence-repair-community-mosque-mosque-volunteer-signup-persona-under-review` | `evidence-repair` | Masjid Nur | `mosque-volunteer-signup` | persona-under-review | 3 | 1 | volunteer signup surface with role, time, protected contact fields, and confirmation |  |
| `b25-wi-evidence-repair-community-mosque-mosque-donor-visibility-persona-under-review` | `evidence-repair` | Masjid Nur | `mosque-donor-visibility` | persona-under-review | 3 | 1 | explicit domain-native product surface selected from the B21 production UX contract |  |
| `b25-wi-evidence-repair-community-mosque-mosque-donation-payment-persona-under-review` | `evidence-repair` | Masjid Nur | `mosque-donation-payment` | persona-under-review | 3 | 1 | payment or donation flow with amount, payer context, receipt, entitlement/status, and audit trail |  |
| `b25-wi-evidence-repair-community-mosque-mosque-care-request-persona-under-review` | `evidence-repair` | Masjid Nur | `mosque-care-request` | persona-under-review | 3 | 1 | protected care request form and private response/status surface |  |
| `b25-wi-evidence-repair-community-mosque-mosque-neutral-notification-persona-under-review` | `evidence-repair` | Masjid Nur | `mosque-neutral-notification` | persona-under-review | 3 | 1 | explicit domain-native product surface selected from the B21 production UX contract |  |

### Evidence Repair Work Items Reference Patterns

| Reference | Source | URL | What to copy |
| --- | --- | --- | --- |
| Material detail surface composition | Material Design 3 / design-system | https://m3.material.io/components/cards/overview | Build a domain detail page with primary content, metadata, status, and actions instead of a generic task card. |
| Material Design cards and lists | Material Design 3 / design-system | https://m3.material.io/components/cards/overview<br>Also: https://m3.material.io/components/lists/overview | Use cards/lists only as scannable containers with clear hierarchy, content, metadata, and actions. Do not use repeated cards as the whole primary workflow. |
| Flutter sample app implementation patterns | flutter/samples / open-source | https://github.com/flutter/samples | Copy the separation between app shell, route state, domain widgets, and testable UI states rather than hardcoding a single generic renderer. |
| Material navigation and information architecture | Material Design 3 / design-system | https://m3.material.io/components/navigation-drawer/overview<br>Also: https://m3.material.io/components/navigation-bar/overview | Organize screens by user jobs and destinations; keep primary actions visible and avoid exposing implementation taxonomy. |
| Apple HIG navigation and content organization | Apple Human Interface Guidelines / design-system | https://developer.apple.com/design/human-interface-guidelines/navigation | Make navigation predictable, content-centered, and appropriate for the user’s current task. |
| Event detail and RSVP flow | Material cards/lists/buttons / pattern | https://m3.material.io/components/cards/overview<br>Also: https://m3.material.io/components/buttons/overview<br>https://m3.material.io/components/chips/overview | Copy an event detail layout: title, date/time, location, host, capacity/status chip, attendee context, RSVP action, and confirmation state. |
| Task list and export wizard | GOV.UK Design System / design-system | https://design-system.service.gov.uk/components/task-list/<br>Also: https://design-system.service.gov.uk/patterns/check-answers/ | Copy a wizard with steps, preview, redaction choices, checksum evidence, transfer status, and rollback confirmation. |
| Selection and voting pattern | Material chips/cards/buttons / pattern | https://m3.material.io/components/chips/overview<br>Also: https://m3.material.io/components/cards/overview | Copy a nomination/voting surface with choices, current vote state, deadline, selected result, and meeting/discussion context. |
| Inbox and message thread pattern | Material lists/text fields / pattern | https://m3.material.io/components/lists/overview<br>Also: https://m3.material.io/components/text-fields/overview | Copy an inbox/thread structure: sender, timestamp, message preview/body, reply field, invite/block state, and read/received state. |
| Feed item and composer pattern | Material cards/lists/text fields / pattern | https://m3.material.io/components/text-fields/overview<br>Also: https://m3.material.io/components/cards/overview<br>https://m3.material.io/components/lists/overview | Copy a feed/composer structure: audience, author, timestamp, body, attachments/status, publish action, and receiver read state. |
| Search and result list pattern | Material Design 3 / design-system | https://m3.material.io/components/search/overview<br>Also: https://m3.material.io/components/lists/overview | Copy a search layout with query, filters, ranked results, citations/sources, empty/error states, and follow-up actions. |
| Form validation and review pattern | U.S. Web Design System / design-system | https://designsystem.digital.gov/components/form/<br>Also: https://designsystem.digital.gov/components/alert/<br>https://design-system.service.gov.uk/components/error-summary/ | Copy a form flow with field labels, helper text, validation errors, review state, submit action, status, and protected-data treatment. |

### Affected Coverage Rows

Showing 30 of 70 affected coverage rows.

| Coverage row | Community | Workflow | Persona | Missing evidence |
| --- | --- | --- | --- | --- |
| `b25-wp-001-workflow-ui-evidence-harness-persona-under-review` | workflow-ui-evidence-harness | `workflow-ui-evidence-harness` | persona-under-review | specific persona/personaId |
| `b25-wp-002-garden-event-rsvp-persona-under-review` | Garden Club | `garden-event-rsvp` | persona-under-review | specific persona/personaId |
| `b25-wp-003-plant-exchange-submission-persona-under-review` | Garden Club | `plant-exchange-submission` | persona-under-review | specific persona/personaId |
| `b25-wp-004-garden-export-custom-schemas-persona-under-review` | Garden Club | `garden-export-custom-schemas` | persona-under-review | specific persona/personaId |
| `b25-wp-005-book-nomination-persona-under-review` | Neighborhood Book Club | `book-nomination` | persona-under-review | specific persona/personaId |
| `b25-wp-006-book-vote-persona-under-review` | Neighborhood Book Club | `book-vote` | persona-under-review | specific persona/personaId |
| `b25-wp-007-book-meeting-rsvp-persona-under-review` | Neighborhood Book Club | `book-meeting-rsvp` | persona-under-review | specific persona/personaId |
| `b25-wp-008-book-discussion-message-persona-under-review` | Neighborhood Book Club | `book-discussion-message` | persona-under-review | specific persona/personaId |
| `b25-wp-009-book-selection-publish-persona-under-review` | Neighborhood Book Club | `book-selection-publish` | persona-under-review | specific persona/personaId |
| `b25-wp-010-book-search-ai-digest-persona-under-review` | Neighborhood Book Club | `book-search-ai-digest` | persona-under-review | specific persona/personaId |
| `b25-wp-011-book-export-metadata-persona-under-review` | Neighborhood Book Club | `book-export-metadata` | persona-under-review | specific persona/personaId |
| `b25-wp-012-soccer-guardian-join-approval-persona-under-review` | Riverside Youth Soccer | `soccer-guardian-join-approval` | persona-under-review | specific persona/personaId |
| `b25-wp-013-soccer-team-roster-persona-under-review` | Riverside Youth Soccer | `soccer-team-roster` | persona-under-review | specific persona/personaId |
| `b25-wp-014-soccer-minor-redaction-persona-under-review` | Riverside Youth Soccer | `soccer-minor-redaction` | persona-under-review | specific persona/personaId |
| `b25-wp-015-soccer-registration-payment-persona-under-review` | Riverside Youth Soccer | `soccer-registration-payment` | persona-under-review | specific persona/personaId |
| `b25-wp-016-soccer-practice-schedule-persona-under-review` | Riverside Youth Soccer | `soccer-practice-schedule` | persona-under-review | specific persona/personaId |
| `b25-wp-017-soccer-reminder-notification-persona-under-review` | Riverside Youth Soccer | `soccer-reminder-notification` | persona-under-review | specific persona/personaId |
| `b25-wp-018-soccer-export-metadata-persona-under-review` | Riverside Youth Soccer | `soccer-export-metadata` | persona-under-review | specific persona/personaId |
| `b25-wp-019-hoa-dues-payment-persona-under-review` | Cedar Commons HOA | `hoa-dues-payment` | persona-under-review | specific persona/personaId |
| `b25-wp-021-hoa-facility-reservation-persona-under-review` | Cedar Commons HOA | `hoa-facility-reservation` | persona-under-review | specific persona/personaId |
| `b25-wp-022-hoa-architectural-request-persona-under-review` | Cedar Commons HOA | `hoa-architectural-request` | persona-under-review | specific persona/personaId |
| `b25-wp-023-hoa-committee-decision-persona-under-review` | Cedar Commons HOA | `hoa-committee-decision` | persona-under-review | specific persona/personaId |
| `b25-wp-025-hoa-export-evidence-persona-under-review` | Cedar Commons HOA | `hoa-export-evidence` | persona-under-review | specific persona/personaId |
| `b25-wp-026-mosque-announcement-persona-under-review` | Masjid Nur | `mosque-announcement` | persona-under-review | specific persona/personaId |
| `b25-wp-027-mosque-event-rsvp-persona-under-review` | Masjid Nur | `mosque-event-rsvp` | persona-under-review | specific persona/personaId |
| `b25-wp-028-mosque-volunteer-signup-persona-under-review` | Masjid Nur | `mosque-volunteer-signup` | persona-under-review | specific persona/personaId |
| `b25-wp-029-mosque-donor-visibility-persona-under-review` | Masjid Nur | `mosque-donor-visibility` | persona-under-review | specific persona/personaId |
| `b25-wp-030-mosque-donation-payment-persona-under-review` | Masjid Nur | `mosque-donation-payment` | persona-under-review | specific persona/personaId |
| `b25-wp-031-mosque-care-request-persona-under-review` | Masjid Nur | `mosque-care-request` | persona-under-review | specific persona/personaId |
| `b25-wp-032-mosque-neutral-notification-persona-under-review` | Masjid Nur | `mosque-neutral-notification` | persona-under-review | specific persona/personaId |

### Affected Screen Rows

Showing 30 of 199 affected screen rows.

| Screen row | Community | Workflow | Persona | State | Exact UX failure |
| --- | --- | --- | --- | --- | --- |
| `b25-v4-row-001-workflow-ui-evidence-harness-0` | workflow-ui-evidence-harness | `workflow-ui-evidence-harness` | persona-under-review | B12_harness_start | Persona is generic or missing; the worker cannot know which role this screen serves. Visible text is not proven from screenshot OCR/manual extraction. Primary surface classification is incomplete or unverified. Screen-specific critique does not yet explain visible UI, persona, task, and remediation. Current row verdict is `fail` with severity `major`. |
| `b25-v4-row-002-workflow-ui-evidence-harness-1` | workflow-ui-evidence-harness | `workflow-ui-evidence-harness` | persona-under-review | B12_harness_action | Persona is generic or missing; the worker cannot know which role this screen serves. Visible text is not proven from screenshot OCR/manual extraction. Primary surface classification is incomplete or unverified. Screen-specific critique does not yet explain visible UI, persona, task, and remediation. Current row verdict is `fail` with severity `major`. |
| `b25-v4-row-003-workflow-ui-evidence-harness-2` | workflow-ui-evidence-harness | `workflow-ui-evidence-harness` | persona-under-review | B12_harness_complete | Persona is generic or missing; the worker cannot know which role this screen serves. Visible text is not proven from screenshot OCR/manual extraction. Primary surface classification is incomplete or unverified. Screen-specific critique does not yet explain visible UI, persona, task, and remediation. Current row verdict is `fail` with severity `major`. |
| `b25-v4-row-004-garden-event-rsvp-0` | Garden Club | `garden-event-rsvp` | persona-under-review | B13_ext_garden_club_garden-event-rsvp_start | Persona is generic or missing; the worker cannot know which role this screen serves. Visible text is not proven from screenshot OCR/manual extraction. Primary surface classification is incomplete or unverified. Screen-specific critique does not yet explain visible UI, persona, task, and remediation. Current row verdict is `fail` with severity `major`. |
| `b25-v4-row-005-garden-event-rsvp-1` | Garden Club | `garden-event-rsvp` | persona-under-review | B13_ext_garden_club_garden-event-rsvp_action | Persona is generic or missing; the worker cannot know which role this screen serves. Visible text is not proven from screenshot OCR/manual extraction. Primary surface classification is incomplete or unverified. Screen-specific critique does not yet explain visible UI, persona, task, and remediation. Current row verdict is `fail` with severity `major`. |
| `b25-v4-row-006-garden-event-rsvp-2` | Garden Club | `garden-event-rsvp` | persona-under-review | B13_ext_garden_club_garden-event-rsvp_complete | Persona is generic or missing; the worker cannot know which role this screen serves. Visible text is not proven from screenshot OCR/manual extraction. Primary surface classification is incomplete or unverified. Screen-specific critique does not yet explain visible UI, persona, task, and remediation. Current row verdict is `fail` with severity `major`. |
| `b25-v4-row-007-plant-exchange-submission-0` | Garden Club | `plant-exchange-submission` | persona-under-review | B13_ext_garden_club_plant-exchange-submission_start | Persona is generic or missing; the worker cannot know which role this screen serves. Visible text is not proven from screenshot OCR/manual extraction. Primary surface classification is incomplete or unverified. Screen-specific critique does not yet explain visible UI, persona, task, and remediation. Current row verdict is `fail` with severity `major`. |
| `b25-v4-row-008-plant-exchange-submission-1` | Garden Club | `plant-exchange-submission` | persona-under-review | B13_ext_garden_club_plant-exchange-submission_action | Persona is generic or missing; the worker cannot know which role this screen serves. Visible text is not proven from screenshot OCR/manual extraction. Primary surface classification is incomplete or unverified. Screen-specific critique does not yet explain visible UI, persona, task, and remediation. Current row verdict is `fail` with severity `major`. |
| `b25-v4-row-009-plant-exchange-submission-2` | Garden Club | `plant-exchange-submission` | persona-under-review | B13_ext_garden_club_plant-exchange-submission_complete | Persona is generic or missing; the worker cannot know which role this screen serves. Visible text is not proven from screenshot OCR/manual extraction. Primary surface classification is incomplete or unverified. Screen-specific critique does not yet explain visible UI, persona, task, and remediation. Current row verdict is `fail` with severity `major`. |
| `b25-v4-row-010-garden-export-custom-schemas-0` | Garden Club | `garden-export-custom-schemas` | persona-under-review | B13_ext_garden_club_garden-export-custom-schemas_start | Persona is generic or missing; the worker cannot know which role this screen serves. Visible text is not proven from screenshot OCR/manual extraction. Primary surface classification is incomplete or unverified. Screen-specific critique does not yet explain visible UI, persona, task, and remediation. Current row verdict is `fail` with severity `major`. |
| `b25-v4-row-011-garden-export-custom-schemas-1` | Garden Club | `garden-export-custom-schemas` | persona-under-review | B13_ext_garden_club_garden-export-custom-schemas_action | Persona is generic or missing; the worker cannot know which role this screen serves. Visible text is not proven from screenshot OCR/manual extraction. Primary surface classification is incomplete or unverified. Screen-specific critique does not yet explain visible UI, persona, task, and remediation. Current row verdict is `fail` with severity `major`. |
| `b25-v4-row-012-garden-export-custom-schemas-2` | Garden Club | `garden-export-custom-schemas` | persona-under-review | B13_ext_garden_club_garden-export-custom-schemas_complete | Persona is generic or missing; the worker cannot know which role this screen serves. Visible text is not proven from screenshot OCR/manual extraction. Primary surface classification is incomplete or unverified. Screen-specific critique does not yet explain visible UI, persona, task, and remediation. Current row verdict is `fail` with severity `major`. |
| `b25-v4-row-013-book-nomination-0` | Neighborhood Book Club | `book-nomination` | persona-under-review | B14_ext_book_club_book-nomination_start | Persona is generic or missing; the worker cannot know which role this screen serves. Visible text is not proven from screenshot OCR/manual extraction. Primary surface classification is incomplete or unverified. Screen-specific critique does not yet explain visible UI, persona, task, and remediation. Current row verdict is `fail` with severity `major`. |
| `b25-v4-row-014-book-nomination-1` | Neighborhood Book Club | `book-nomination` | persona-under-review | B14_ext_book_club_book-nomination_action | Persona is generic or missing; the worker cannot know which role this screen serves. Visible text is not proven from screenshot OCR/manual extraction. Primary surface classification is incomplete or unverified. Screen-specific critique does not yet explain visible UI, persona, task, and remediation. Current row verdict is `fail` with severity `major`. |
| `b25-v4-row-015-book-nomination-2` | Neighborhood Book Club | `book-nomination` | persona-under-review | B14_ext_book_club_book-nomination_complete | Persona is generic or missing; the worker cannot know which role this screen serves. Visible text is not proven from screenshot OCR/manual extraction. Primary surface classification is incomplete or unverified. Screen-specific critique does not yet explain visible UI, persona, task, and remediation. Current row verdict is `fail` with severity `major`. |
| `b25-v4-row-016-book-vote-0` | Neighborhood Book Club | `book-vote` | persona-under-review | B14_ext_book_club_book-vote_start | Persona is generic or missing; the worker cannot know which role this screen serves. Visible text is not proven from screenshot OCR/manual extraction. Primary surface classification is incomplete or unverified. Screen-specific critique does not yet explain visible UI, persona, task, and remediation. Current row verdict is `fail` with severity `major`. |
| `b25-v4-row-017-book-vote-1` | Neighborhood Book Club | `book-vote` | persona-under-review | B14_ext_book_club_book-vote_action | Persona is generic or missing; the worker cannot know which role this screen serves. Visible text is not proven from screenshot OCR/manual extraction. Primary surface classification is incomplete or unverified. Screen-specific critique does not yet explain visible UI, persona, task, and remediation. Current row verdict is `fail` with severity `major`. |
| `b25-v4-row-018-book-vote-2` | Neighborhood Book Club | `book-vote` | persona-under-review | B14_ext_book_club_book-vote_complete | Persona is generic or missing; the worker cannot know which role this screen serves. Visible text is not proven from screenshot OCR/manual extraction. Primary surface classification is incomplete or unverified. Screen-specific critique does not yet explain visible UI, persona, task, and remediation. Current row verdict is `fail` with severity `major`. |
| `b25-v4-row-019-book-meeting-rsvp-0` | Neighborhood Book Club | `book-meeting-rsvp` | persona-under-review | B14_ext_book_club_book-meeting-rsvp_start | Persona is generic or missing; the worker cannot know which role this screen serves. Visible text is not proven from screenshot OCR/manual extraction. Primary surface classification is incomplete or unverified. Screen-specific critique does not yet explain visible UI, persona, task, and remediation. Current row verdict is `fail` with severity `major`. |
| `b25-v4-row-020-book-meeting-rsvp-1` | Neighborhood Book Club | `book-meeting-rsvp` | persona-under-review | B14_ext_book_club_book-meeting-rsvp_action | Persona is generic or missing; the worker cannot know which role this screen serves. Visible text is not proven from screenshot OCR/manual extraction. Primary surface classification is incomplete or unverified. Screen-specific critique does not yet explain visible UI, persona, task, and remediation. Current row verdict is `fail` with severity `major`. |
| `b25-v4-row-021-book-meeting-rsvp-2` | Neighborhood Book Club | `book-meeting-rsvp` | persona-under-review | B14_ext_book_club_book-meeting-rsvp_complete | Persona is generic or missing; the worker cannot know which role this screen serves. Visible text is not proven from screenshot OCR/manual extraction. Primary surface classification is incomplete or unverified. Screen-specific critique does not yet explain visible UI, persona, task, and remediation. Current row verdict is `fail` with severity `major`. |
| `b25-v4-row-022-book-discussion-message-0` | Neighborhood Book Club | `book-discussion-message` | persona-under-review | B14_ext_book_club_book-discussion-message_start | Persona is generic or missing; the worker cannot know which role this screen serves. Visible text is not proven from screenshot OCR/manual extraction. Primary surface classification is incomplete or unverified. Screen-specific critique does not yet explain visible UI, persona, task, and remediation. Current row verdict is `fail` with severity `major`. |
| `b25-v4-row-023-book-discussion-message-1` | Neighborhood Book Club | `book-discussion-message` | persona-under-review | B14_ext_book_club_book-discussion-message_action | Persona is generic or missing; the worker cannot know which role this screen serves. Visible text is not proven from screenshot OCR/manual extraction. Primary surface classification is incomplete or unverified. Screen-specific critique does not yet explain visible UI, persona, task, and remediation. Current row verdict is `fail` with severity `major`. |
| `b25-v4-row-024-book-discussion-message-2` | Neighborhood Book Club | `book-discussion-message` | persona-under-review | B14_ext_book_club_book-discussion-message_complete | Persona is generic or missing; the worker cannot know which role this screen serves. Visible text is not proven from screenshot OCR/manual extraction. Primary surface classification is incomplete or unverified. Screen-specific critique does not yet explain visible UI, persona, task, and remediation. Current row verdict is `fail` with severity `major`. |
| `b25-v4-row-025-book-selection-publish-0` | Neighborhood Book Club | `book-selection-publish` | persona-under-review | B14_ext_book_club_book-selection-publish_start | Persona is generic or missing; the worker cannot know which role this screen serves. Visible text is not proven from screenshot OCR/manual extraction. Primary surface classification is incomplete or unverified. Screen-specific critique does not yet explain visible UI, persona, task, and remediation. Current row verdict is `fail` with severity `major`. |
| `b25-v4-row-026-book-selection-publish-1` | Neighborhood Book Club | `book-selection-publish` | persona-under-review | B14_ext_book_club_book-selection-publish_action | Persona is generic or missing; the worker cannot know which role this screen serves. Visible text is not proven from screenshot OCR/manual extraction. Primary surface classification is incomplete or unverified. Screen-specific critique does not yet explain visible UI, persona, task, and remediation. Current row verdict is `fail` with severity `major`. |
| `b25-v4-row-027-book-selection-publish-2` | Neighborhood Book Club | `book-selection-publish` | persona-under-review | B14_ext_book_club_book-selection-publish_complete | Persona is generic or missing; the worker cannot know which role this screen serves. Visible text is not proven from screenshot OCR/manual extraction. Primary surface classification is incomplete or unverified. Screen-specific critique does not yet explain visible UI, persona, task, and remediation. Current row verdict is `fail` with severity `major`. |
| `b25-v4-row-028-book-search-ai-digest-0` | Neighborhood Book Club | `book-search-ai-digest` | persona-under-review | B14_ext_book_club_book-search-ai-digest_start | Persona is generic or missing; the worker cannot know which role this screen serves. Visible text is not proven from screenshot OCR/manual extraction. Primary surface classification is incomplete or unverified. Screen-specific critique does not yet explain visible UI, persona, task, and remediation. Current row verdict is `fail` with severity `major`. |
| `b25-v4-row-029-book-search-ai-digest-1` | Neighborhood Book Club | `book-search-ai-digest` | persona-under-review | B14_ext_book_club_book-search-ai-digest_action | Persona is generic or missing; the worker cannot know which role this screen serves. Visible text is not proven from screenshot OCR/manual extraction. Primary surface classification is incomplete or unverified. Screen-specific critique does not yet explain visible UI, persona, task, and remediation. Current row verdict is `fail` with severity `major`. |
| `b25-v4-row-030-book-search-ai-digest-2` | Neighborhood Book Club | `book-search-ai-digest` | persona-under-review | B14_ext_book_club_book-search-ai-digest_complete | Persona is generic or missing; the worker cannot know which role this screen serves. Visible text is not proven from screenshot OCR/manual extraction. Primary surface classification is incomplete or unverified. Screen-specific critique does not yet explain visible UI, persona, task, and remediation. Current row verdict is `fail` with severity `major`. |

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
- Screen row `b25-v4-row-001-workflow-ui-evidence-harness-0` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-001-workflow-ui-evidence-harness-0` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-001-workflow-ui-evidence-harness-0` names visible UI elements, visible text, persona `persona-under-review`, workflow `workflow-ui-evidence-harness`, and the exact product UX issue.
- Primary surface for `workflow-ui-evidence-harness` is documented as `explicit domain-native product surface selected from the B21 production UX contract` or another explicit domain-native surface.
- Fresh screenshot path/hash/timestamp/app commit SHA are recorded after the fix.
- Screen row `b25-v4-row-002-workflow-ui-evidence-harness-1` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-002-workflow-ui-evidence-harness-1` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-002-workflow-ui-evidence-harness-1` names visible UI elements, visible text, persona `persona-under-review`, workflow `workflow-ui-evidence-harness`, and the exact product UX issue.
- Screen row `b25-v4-row-003-workflow-ui-evidence-harness-2` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-003-workflow-ui-evidence-harness-2` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-003-workflow-ui-evidence-harness-2` names visible UI elements, visible text, persona `persona-under-review`, workflow `workflow-ui-evidence-harness`, and the exact product UX issue.
- Screen row `b25-v4-row-004-garden-event-rsvp-0` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-004-garden-event-rsvp-0` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-004-garden-event-rsvp-0` names visible UI elements, visible text, persona `persona-under-review`, workflow `garden-event-rsvp`, and the exact product UX issue.
- Primary surface for `garden-event-rsvp` is documented as `event detail with schedule, location, capacity/status, RSVP action, and result state` or another explicit domain-native surface.
- Screen row `b25-v4-row-005-garden-event-rsvp-1` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-005-garden-event-rsvp-1` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-005-garden-event-rsvp-1` names visible UI elements, visible text, persona `persona-under-review`, workflow `garden-event-rsvp`, and the exact product UX issue.
- Screen row `b25-v4-row-006-garden-event-rsvp-2` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-006-garden-event-rsvp-2` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-006-garden-event-rsvp-2` names visible UI elements, visible text, persona `persona-under-review`, workflow `garden-event-rsvp`, and the exact product UX issue.
- Screen row `b25-v4-row-007-plant-exchange-submission-0` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-007-plant-exchange-submission-0` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-007-plant-exchange-submission-0` names visible UI elements, visible text, persona `persona-under-review`, workflow `plant-exchange-submission`, and the exact product UX issue.
- Primary surface for `plant-exchange-submission` is documented as `explicit domain-native product surface selected from the B21 production UX contract` or another explicit domain-native surface.
- Screen row `b25-v4-row-008-plant-exchange-submission-1` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-008-plant-exchange-submission-1` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-008-plant-exchange-submission-1` names visible UI elements, visible text, persona `persona-under-review`, workflow `plant-exchange-submission`, and the exact product UX issue.
- Screen row `b25-v4-row-009-plant-exchange-submission-2` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-009-plant-exchange-submission-2` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-009-plant-exchange-submission-2` names visible UI elements, visible text, persona `persona-under-review`, workflow `plant-exchange-submission`, and the exact product UX issue.
- Screen row `b25-v4-row-010-garden-export-custom-schemas-0` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-010-garden-export-custom-schemas-0` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-010-garden-export-custom-schemas-0` names visible UI elements, visible text, persona `persona-under-review`, workflow `garden-export-custom-schemas`, and the exact product UX issue.
- Primary surface for `garden-export-custom-schemas` is documented as `export/import wizard with preview, redaction, checksum, transfer status, and rollback state` or another explicit domain-native surface.
- Screen row `b25-v4-row-011-garden-export-custom-schemas-1` has a specific persona/personaId, not `persona-under-review`.

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
| Ticket IDs | B25-RT-003-b25-c04-modern-intentional-ui, B25-RT-004-b25-c05-community-content-ia, B25-RT-005-b25-c06-domain-native-primary-surfaces, B25-RT-007-b25-c09-no-layout-production-defects |

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
| Event detail and RSVP flow | Material cards/lists/buttons / pattern | https://m3.material.io/components/cards/overview<br>Also: https://m3.material.io/components/buttons/overview<br>https://m3.material.io/components/chips/overview | Copy an event detail layout: title, date/time, location, host, capacity/status chip, attendee context, RSVP action, and confirmation state. |
| Task list and export wizard | GOV.UK Design System / design-system | https://design-system.service.gov.uk/components/task-list/<br>Also: https://design-system.service.gov.uk/patterns/check-answers/ | Copy a wizard with steps, preview, redaction choices, checksum evidence, transfer status, and rollback confirmation. |
| Selection and voting pattern | Material chips/cards/buttons / pattern | https://m3.material.io/components/chips/overview<br>Also: https://m3.material.io/components/cards/overview | Copy a nomination/voting surface with choices, current vote state, deadline, selected result, and meeting/discussion context. |
| Inbox and message thread pattern | Material lists/text fields / pattern | https://m3.material.io/components/lists/overview<br>Also: https://m3.material.io/components/text-fields/overview | Copy an inbox/thread structure: sender, timestamp, message preview/body, reply field, invite/block state, and read/received state. |
| Feed item and composer pattern | Material cards/lists/text fields / pattern | https://m3.material.io/components/text-fields/overview<br>Also: https://m3.material.io/components/cards/overview<br>https://m3.material.io/components/lists/overview | Copy a feed/composer structure: audience, author, timestamp, body, attachments/status, publish action, and receiver read state. |
| Search and result list pattern | Material Design 3 / design-system | https://m3.material.io/components/search/overview<br>Also: https://m3.material.io/components/lists/overview | Copy a search layout with query, filters, ranked results, citations/sources, empty/error states, and follow-up actions. |
| Form validation and review pattern | U.S. Web Design System / design-system | https://designsystem.digital.gov/components/form/<br>Also: https://designsystem.digital.gov/components/alert/<br>https://design-system.service.gov.uk/components/error-summary/ | Copy a form flow with field labels, helper text, validation errors, review state, submit action, status, and protected-data treatment. |
| Roster/list with protected details | Material Design 3 / design-system | https://m3.material.io/components/data-tables/overview<br>Also: https://m3.material.io/components/lists/overview | Copy a roster with member names, roles, status, role-filtered fields, and clear protected-data redaction. |
| Review-and-confirm payment flow | GOV.UK Design System / design-system | https://design-system.service.gov.uk/patterns/check-answers/ | Use a review/confirmation step with amount, payer context, recipient, fees or entitlement, receipt, and audit trail. |
| Multi-step payment/progress flow | U.S. Web Design System / design-system | https://designsystem.digital.gov/components/step-indicator/ | Use explicit progress states for checkout, review, confirmation, receipt, and entitlement/status. |
| Reservation detail and availability flow | Material cards/forms / pattern | https://m3.material.io/components/date-pickers/overview<br>Also: https://m3.material.io/components/cards/overview | Copy an availability/reservation flow with facility details, date/time, capacity/rules, payment/status when needed, and confirmation. |
| Match schedule and result pattern | Material lists/cards / pattern | https://m3.material.io/components/lists/overview | Copy a match surface with players, schedule/round, result entry, result state, and next action. |
| Document list/detail pattern | Material lists/cards / pattern | https://m3.material.io/components/lists/overview | Copy a document library with title, category, audience, file metadata, access state, download/view action, and empty/error states. |

### Reference Research Queries
- modern mobile app information architecture visual hierarchy examples
- Material Design 3 mobile UI hierarchy navigation cards examples
- open source Flutter production app dashboard detail screen examples
- open source Flutter domain-native-surface mobile UI example GitHub
- explicit domain-native product surface selected from the B21 production UX contract mobile UX pattern
- Material Design explicit domain-native product surface selected from the B21 production UX contract mobile pattern
- open source Flutter event-rsvp mobile UI example GitHub
- event detail with schedule, location, capacity/status, RSVP action, and result state mobile UX pattern
- Material Design event detail with schedule, location, capacity/status, RSVP action, and result state mobile pattern
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

### UI Remediation Work Items

Showing 30 of 70 work items. Full detail is in the JSON artifact.

| Work item | Stage | Community | Workflow | Persona | Screens | Coverage | Target surface | Blocked until |
| --- | --- | --- | --- | --- | ---: | ---: | --- | --- |
| `b25-wi-ui-remediation-workflow-ui-evidence-harness-workflow-ui-evidence-harness-persona-under-review` | `ui-remediation` | workflow-ui-evidence-harness | `workflow-ui-evidence-harness` | persona-under-review | 3 | 1 | explicit domain-native product surface selected from the B21 production UX contract | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-garden-club-garden-event-rsvp-persona-under-review` | `ui-remediation` | Garden Club | `garden-event-rsvp` | persona-under-review | 3 | 1 | event detail with schedule, location, capacity/status, RSVP action, and result state | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-garden-club-plant-exchange-submission-persona-under-review` | `ui-remediation` | Garden Club | `plant-exchange-submission` | persona-under-review | 3 | 1 | explicit domain-native product surface selected from the B21 production UX contract | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-garden-club-garden-export-custom-schemas-persona-under-review` | `ui-remediation` | Garden Club | `garden-export-custom-schemas` | persona-under-review | 3 | 1 | export/import wizard with preview, redaction, checksum, transfer status, and rollback state | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-book-club-book-nomination-persona-under-review` | `ui-remediation` | Neighborhood Book Club | `book-nomination` | persona-under-review | 3 | 1 | book club reading/voting surface with nominations, vote state, selected book, meeting context, and discussion | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-book-club-book-vote-persona-under-review` | `ui-remediation` | Neighborhood Book Club | `book-vote` | persona-under-review | 3 | 1 | book club reading/voting surface with nominations, vote state, selected book, meeting context, and discussion | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-book-club-book-meeting-rsvp-persona-under-review` | `ui-remediation` | Neighborhood Book Club | `book-meeting-rsvp` | persona-under-review | 3 | 1 | event detail with schedule, location, capacity/status, RSVP action, and result state | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-book-club-book-discussion-message-persona-under-review` | `ui-remediation` | Neighborhood Book Club | `book-discussion-message` | persona-under-review | 3 | 1 | inbox, message thread, connection card, invite, or block-state surface | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-book-club-book-selection-publish-persona-under-review` | `ui-remediation` | Neighborhood Book Club | `book-selection-publish` | persona-under-review | 3 | 1 | announcement feed/composer with audience, author, timestamp, body, and receiver state | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-book-club-book-search-ai-digest-persona-under-review` | `ui-remediation` | Neighborhood Book Club | `book-search-ai-digest` | persona-under-review | 3 | 1 | search/AI answer surface with query, result, citation, source, and follow-up action | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-book-club-book-export-metadata-persona-under-review` | `ui-remediation` | Neighborhood Book Club | `book-export-metadata` | persona-under-review | 3 | 1 | export/import wizard with preview, redaction, checksum, transfer status, and rollback state | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-youth-soccer-soccer-guardian-join-approval-persona-under-review` | `ui-remediation` | Riverside Youth Soccer | `soccer-guardian-join-approval` | persona-under-review | 3 | 1 | request detail and admin review queue with submitted data, decision action, status, and notification | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-youth-soccer-soccer-team-roster-persona-under-review` | `ui-remediation` | Riverside Youth Soccer | `soccer-team-roster` | persona-under-review | 3 | 1 | team roster/schedule surface with role-filtered member details and protected-data treatment | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-youth-soccer-soccer-minor-redaction-persona-under-review` | `ui-remediation` | Riverside Youth Soccer | `soccer-minor-redaction` | persona-under-review | 3 | 1 | explicit domain-native product surface selected from the B21 production UX contract | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-youth-soccer-soccer-registration-payment-persona-under-review` | `ui-remediation` | Riverside Youth Soccer | `soccer-registration-payment` | persona-under-review | 3 | 1 | payment or donation flow with amount, payer context, receipt, entitlement/status, and audit trail | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-youth-soccer-soccer-practice-schedule-persona-under-review` | `ui-remediation` | Riverside Youth Soccer | `soccer-practice-schedule` | persona-under-review | 3 | 1 | event detail with schedule, location, capacity/status, RSVP action, and result state | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-youth-soccer-soccer-reminder-notification-persona-under-review` | `ui-remediation` | Riverside Youth Soccer | `soccer-reminder-notification` | persona-under-review | 3 | 1 | explicit domain-native product surface selected from the B21 production UX contract | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-youth-soccer-soccer-export-metadata-persona-under-review` | `ui-remediation` | Riverside Youth Soccer | `soccer-export-metadata` | persona-under-review | 3 | 1 | export/import wizard with preview, redaction, checksum, transfer status, and rollback state | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-hoa-hoa-dues-payment-persona-under-review` | `ui-remediation` | Cedar Commons HOA | `hoa-dues-payment` | persona-under-review | 3 | 1 | payment or donation flow with amount, payer context, receipt, entitlement/status, and audit trail | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-hoa-hoa-facility-reservation-persona-under-review` | `ui-remediation` | Cedar Commons HOA | `hoa-facility-reservation` | persona-under-review | 3 | 1 | facility detail/reservation flow with availability, payment/status, and confirmation | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-hoa-hoa-architectural-request-persona-under-review` | `ui-remediation` | Cedar Commons HOA | `hoa-architectural-request` | persona-under-review | 3 | 1 | request detail and admin review queue with submitted data, decision action, status, and notification | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-hoa-hoa-committee-decision-persona-under-review` | `ui-remediation` | Cedar Commons HOA | `hoa-committee-decision` | persona-under-review | 3 | 1 | request detail and admin review queue with submitted data, decision action, status, and notification | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-hoa-hoa-export-evidence-persona-under-review` | `ui-remediation` | Cedar Commons HOA | `hoa-export-evidence` | persona-under-review | 3 | 1 | export/import wizard with preview, redaction, checksum, transfer status, and rollback state | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-mosque-mosque-announcement-persona-under-review` | `ui-remediation` | Masjid Nur | `mosque-announcement` | persona-under-review | 3 | 1 | announcement feed/composer with audience, author, timestamp, body, and receiver state | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-mosque-mosque-event-rsvp-persona-under-review` | `ui-remediation` | Masjid Nur | `mosque-event-rsvp` | persona-under-review | 3 | 1 | event detail with schedule, location, capacity/status, RSVP action, and result state | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-mosque-mosque-volunteer-signup-persona-under-review` | `ui-remediation` | Masjid Nur | `mosque-volunteer-signup` | persona-under-review | 3 | 1 | volunteer signup surface with role, time, protected contact fields, and confirmation | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-mosque-mosque-donor-visibility-persona-under-review` | `ui-remediation` | Masjid Nur | `mosque-donor-visibility` | persona-under-review | 3 | 1 | explicit domain-native product surface selected from the B21 production UX contract | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-mosque-mosque-donation-payment-persona-under-review` | `ui-remediation` | Masjid Nur | `mosque-donation-payment` | persona-under-review | 3 | 1 | payment or donation flow with amount, payer context, receipt, entitlement/status, and audit trail | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-mosque-mosque-care-request-persona-under-review` | `ui-remediation` | Masjid Nur | `mosque-care-request` | persona-under-review | 3 | 1 | protected care request form and private response/status surface | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-mosque-mosque-neutral-notification-persona-under-review` | `ui-remediation` | Masjid Nur | `mosque-neutral-notification` | persona-under-review | 3 | 1 | explicit domain-native product surface selected from the B21 production UX contract | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |

### UI Remediation Work Items Reference Patterns

| Reference | Source | URL | What to copy |
| --- | --- | --- | --- |
| Material detail surface composition | Material Design 3 / design-system | https://m3.material.io/components/cards/overview | Build a domain detail page with primary content, metadata, status, and actions instead of a generic task card. |
| Material Design cards and lists | Material Design 3 / design-system | https://m3.material.io/components/cards/overview<br>Also: https://m3.material.io/components/lists/overview | Use cards/lists only as scannable containers with clear hierarchy, content, metadata, and actions. Do not use repeated cards as the whole primary workflow. |
| Flutter sample app implementation patterns | flutter/samples / open-source | https://github.com/flutter/samples | Copy the separation between app shell, route state, domain widgets, and testable UI states rather than hardcoding a single generic renderer. |
| Material navigation and information architecture | Material Design 3 / design-system | https://m3.material.io/components/navigation-drawer/overview<br>Also: https://m3.material.io/components/navigation-bar/overview | Organize screens by user jobs and destinations; keep primary actions visible and avoid exposing implementation taxonomy. |
| Apple HIG navigation and content organization | Apple Human Interface Guidelines / design-system | https://developer.apple.com/design/human-interface-guidelines/navigation | Make navigation predictable, content-centered, and appropriate for the user’s current task. |
| Event detail and RSVP flow | Material cards/lists/buttons / pattern | https://m3.material.io/components/cards/overview<br>Also: https://m3.material.io/components/buttons/overview<br>https://m3.material.io/components/chips/overview | Copy an event detail layout: title, date/time, location, host, capacity/status chip, attendee context, RSVP action, and confirmation state. |
| Task list and export wizard | GOV.UK Design System / design-system | https://design-system.service.gov.uk/components/task-list/<br>Also: https://design-system.service.gov.uk/patterns/check-answers/ | Copy a wizard with steps, preview, redaction choices, checksum evidence, transfer status, and rollback confirmation. |
| Selection and voting pattern | Material chips/cards/buttons / pattern | https://m3.material.io/components/chips/overview<br>Also: https://m3.material.io/components/cards/overview | Copy a nomination/voting surface with choices, current vote state, deadline, selected result, and meeting/discussion context. |
| Inbox and message thread pattern | Material lists/text fields / pattern | https://m3.material.io/components/lists/overview<br>Also: https://m3.material.io/components/text-fields/overview | Copy an inbox/thread structure: sender, timestamp, message preview/body, reply field, invite/block state, and read/received state. |
| Feed item and composer pattern | Material cards/lists/text fields / pattern | https://m3.material.io/components/text-fields/overview<br>Also: https://m3.material.io/components/cards/overview<br>https://m3.material.io/components/lists/overview | Copy a feed/composer structure: audience, author, timestamp, body, attachments/status, publish action, and receiver read state. |
| Search and result list pattern | Material Design 3 / design-system | https://m3.material.io/components/search/overview<br>Also: https://m3.material.io/components/lists/overview | Copy a search layout with query, filters, ranked results, citations/sources, empty/error states, and follow-up actions. |
| Form validation and review pattern | U.S. Web Design System / design-system | https://designsystem.digital.gov/components/form/<br>Also: https://designsystem.digital.gov/components/alert/<br>https://design-system.service.gov.uk/components/error-summary/ | Copy a form flow with field labels, helper text, validation errors, review state, submit action, status, and protected-data treatment. |

### Affected Coverage Rows

Showing 30 of 70 affected coverage rows.

| Coverage row | Community | Workflow | Persona | Missing evidence |
| --- | --- | --- | --- | --- |
| `b25-wp-001-workflow-ui-evidence-harness-persona-under-review` | workflow-ui-evidence-harness | `workflow-ui-evidence-harness` | persona-under-review | specific persona/personaId |
| `b25-wp-002-garden-event-rsvp-persona-under-review` | Garden Club | `garden-event-rsvp` | persona-under-review | specific persona/personaId |
| `b25-wp-003-plant-exchange-submission-persona-under-review` | Garden Club | `plant-exchange-submission` | persona-under-review | specific persona/personaId |
| `b25-wp-004-garden-export-custom-schemas-persona-under-review` | Garden Club | `garden-export-custom-schemas` | persona-under-review | specific persona/personaId |
| `b25-wp-005-book-nomination-persona-under-review` | Neighborhood Book Club | `book-nomination` | persona-under-review | specific persona/personaId |
| `b25-wp-006-book-vote-persona-under-review` | Neighborhood Book Club | `book-vote` | persona-under-review | specific persona/personaId |
| `b25-wp-007-book-meeting-rsvp-persona-under-review` | Neighborhood Book Club | `book-meeting-rsvp` | persona-under-review | specific persona/personaId |
| `b25-wp-008-book-discussion-message-persona-under-review` | Neighborhood Book Club | `book-discussion-message` | persona-under-review | specific persona/personaId |
| `b25-wp-009-book-selection-publish-persona-under-review` | Neighborhood Book Club | `book-selection-publish` | persona-under-review | specific persona/personaId |
| `b25-wp-010-book-search-ai-digest-persona-under-review` | Neighborhood Book Club | `book-search-ai-digest` | persona-under-review | specific persona/personaId |
| `b25-wp-011-book-export-metadata-persona-under-review` | Neighborhood Book Club | `book-export-metadata` | persona-under-review | specific persona/personaId |
| `b25-wp-012-soccer-guardian-join-approval-persona-under-review` | Riverside Youth Soccer | `soccer-guardian-join-approval` | persona-under-review | specific persona/personaId |
| `b25-wp-013-soccer-team-roster-persona-under-review` | Riverside Youth Soccer | `soccer-team-roster` | persona-under-review | specific persona/personaId |
| `b25-wp-014-soccer-minor-redaction-persona-under-review` | Riverside Youth Soccer | `soccer-minor-redaction` | persona-under-review | specific persona/personaId |
| `b25-wp-015-soccer-registration-payment-persona-under-review` | Riverside Youth Soccer | `soccer-registration-payment` | persona-under-review | specific persona/personaId |
| `b25-wp-016-soccer-practice-schedule-persona-under-review` | Riverside Youth Soccer | `soccer-practice-schedule` | persona-under-review | specific persona/personaId |
| `b25-wp-017-soccer-reminder-notification-persona-under-review` | Riverside Youth Soccer | `soccer-reminder-notification` | persona-under-review | specific persona/personaId |
| `b25-wp-018-soccer-export-metadata-persona-under-review` | Riverside Youth Soccer | `soccer-export-metadata` | persona-under-review | specific persona/personaId |
| `b25-wp-019-hoa-dues-payment-persona-under-review` | Cedar Commons HOA | `hoa-dues-payment` | persona-under-review | specific persona/personaId |
| `b25-wp-021-hoa-facility-reservation-persona-under-review` | Cedar Commons HOA | `hoa-facility-reservation` | persona-under-review | specific persona/personaId |
| `b25-wp-022-hoa-architectural-request-persona-under-review` | Cedar Commons HOA | `hoa-architectural-request` | persona-under-review | specific persona/personaId |
| `b25-wp-023-hoa-committee-decision-persona-under-review` | Cedar Commons HOA | `hoa-committee-decision` | persona-under-review | specific persona/personaId |
| `b25-wp-025-hoa-export-evidence-persona-under-review` | Cedar Commons HOA | `hoa-export-evidence` | persona-under-review | specific persona/personaId |
| `b25-wp-026-mosque-announcement-persona-under-review` | Masjid Nur | `mosque-announcement` | persona-under-review | specific persona/personaId |
| `b25-wp-027-mosque-event-rsvp-persona-under-review` | Masjid Nur | `mosque-event-rsvp` | persona-under-review | specific persona/personaId |
| `b25-wp-028-mosque-volunteer-signup-persona-under-review` | Masjid Nur | `mosque-volunteer-signup` | persona-under-review | specific persona/personaId |
| `b25-wp-029-mosque-donor-visibility-persona-under-review` | Masjid Nur | `mosque-donor-visibility` | persona-under-review | specific persona/personaId |
| `b25-wp-030-mosque-donation-payment-persona-under-review` | Masjid Nur | `mosque-donation-payment` | persona-under-review | specific persona/personaId |
| `b25-wp-031-mosque-care-request-persona-under-review` | Masjid Nur | `mosque-care-request` | persona-under-review | specific persona/personaId |
| `b25-wp-032-mosque-neutral-notification-persona-under-review` | Masjid Nur | `mosque-neutral-notification` | persona-under-review | specific persona/personaId |

### Affected Screen Rows

Showing 30 of 199 affected screen rows.

| Screen row | Community | Workflow | Persona | State | Exact UX failure |
| --- | --- | --- | --- | --- | --- |
| `b25-v4-row-001-workflow-ui-evidence-harness-0` | workflow-ui-evidence-harness | `workflow-ui-evidence-harness` | persona-under-review | B12_harness_start | Persona is generic or missing; the worker cannot know which role this screen serves. Visible text is not proven from screenshot OCR/manual extraction. Primary surface classification is incomplete or unverified. Screen-specific critique does not yet explain visible UI, persona, task, and remediation. Current row verdict is `fail` with severity `major`. |
| `b25-v4-row-002-workflow-ui-evidence-harness-1` | workflow-ui-evidence-harness | `workflow-ui-evidence-harness` | persona-under-review | B12_harness_action | Persona is generic or missing; the worker cannot know which role this screen serves. Visible text is not proven from screenshot OCR/manual extraction. Primary surface classification is incomplete or unverified. Screen-specific critique does not yet explain visible UI, persona, task, and remediation. Current row verdict is `fail` with severity `major`. |
| `b25-v4-row-003-workflow-ui-evidence-harness-2` | workflow-ui-evidence-harness | `workflow-ui-evidence-harness` | persona-under-review | B12_harness_complete | Persona is generic or missing; the worker cannot know which role this screen serves. Visible text is not proven from screenshot OCR/manual extraction. Primary surface classification is incomplete or unverified. Screen-specific critique does not yet explain visible UI, persona, task, and remediation. Current row verdict is `fail` with severity `major`. |
| `b25-v4-row-004-garden-event-rsvp-0` | Garden Club | `garden-event-rsvp` | persona-under-review | B13_ext_garden_club_garden-event-rsvp_start | Persona is generic or missing; the worker cannot know which role this screen serves. Visible text is not proven from screenshot OCR/manual extraction. Primary surface classification is incomplete or unverified. Screen-specific critique does not yet explain visible UI, persona, task, and remediation. Current row verdict is `fail` with severity `major`. |
| `b25-v4-row-005-garden-event-rsvp-1` | Garden Club | `garden-event-rsvp` | persona-under-review | B13_ext_garden_club_garden-event-rsvp_action | Persona is generic or missing; the worker cannot know which role this screen serves. Visible text is not proven from screenshot OCR/manual extraction. Primary surface classification is incomplete or unverified. Screen-specific critique does not yet explain visible UI, persona, task, and remediation. Current row verdict is `fail` with severity `major`. |
| `b25-v4-row-006-garden-event-rsvp-2` | Garden Club | `garden-event-rsvp` | persona-under-review | B13_ext_garden_club_garden-event-rsvp_complete | Persona is generic or missing; the worker cannot know which role this screen serves. Visible text is not proven from screenshot OCR/manual extraction. Primary surface classification is incomplete or unverified. Screen-specific critique does not yet explain visible UI, persona, task, and remediation. Current row verdict is `fail` with severity `major`. |
| `b25-v4-row-007-plant-exchange-submission-0` | Garden Club | `plant-exchange-submission` | persona-under-review | B13_ext_garden_club_plant-exchange-submission_start | Persona is generic or missing; the worker cannot know which role this screen serves. Visible text is not proven from screenshot OCR/manual extraction. Primary surface classification is incomplete or unverified. Screen-specific critique does not yet explain visible UI, persona, task, and remediation. Current row verdict is `fail` with severity `major`. |
| `b25-v4-row-008-plant-exchange-submission-1` | Garden Club | `plant-exchange-submission` | persona-under-review | B13_ext_garden_club_plant-exchange-submission_action | Persona is generic or missing; the worker cannot know which role this screen serves. Visible text is not proven from screenshot OCR/manual extraction. Primary surface classification is incomplete or unverified. Screen-specific critique does not yet explain visible UI, persona, task, and remediation. Current row verdict is `fail` with severity `major`. |
| `b25-v4-row-009-plant-exchange-submission-2` | Garden Club | `plant-exchange-submission` | persona-under-review | B13_ext_garden_club_plant-exchange-submission_complete | Persona is generic or missing; the worker cannot know which role this screen serves. Visible text is not proven from screenshot OCR/manual extraction. Primary surface classification is incomplete or unverified. Screen-specific critique does not yet explain visible UI, persona, task, and remediation. Current row verdict is `fail` with severity `major`. |
| `b25-v4-row-010-garden-export-custom-schemas-0` | Garden Club | `garden-export-custom-schemas` | persona-under-review | B13_ext_garden_club_garden-export-custom-schemas_start | Persona is generic or missing; the worker cannot know which role this screen serves. Visible text is not proven from screenshot OCR/manual extraction. Primary surface classification is incomplete or unverified. Screen-specific critique does not yet explain visible UI, persona, task, and remediation. Current row verdict is `fail` with severity `major`. |
| `b25-v4-row-011-garden-export-custom-schemas-1` | Garden Club | `garden-export-custom-schemas` | persona-under-review | B13_ext_garden_club_garden-export-custom-schemas_action | Persona is generic or missing; the worker cannot know which role this screen serves. Visible text is not proven from screenshot OCR/manual extraction. Primary surface classification is incomplete or unverified. Screen-specific critique does not yet explain visible UI, persona, task, and remediation. Current row verdict is `fail` with severity `major`. |
| `b25-v4-row-012-garden-export-custom-schemas-2` | Garden Club | `garden-export-custom-schemas` | persona-under-review | B13_ext_garden_club_garden-export-custom-schemas_complete | Persona is generic or missing; the worker cannot know which role this screen serves. Visible text is not proven from screenshot OCR/manual extraction. Primary surface classification is incomplete or unverified. Screen-specific critique does not yet explain visible UI, persona, task, and remediation. Current row verdict is `fail` with severity `major`. |
| `b25-v4-row-013-book-nomination-0` | Neighborhood Book Club | `book-nomination` | persona-under-review | B14_ext_book_club_book-nomination_start | Persona is generic or missing; the worker cannot know which role this screen serves. Visible text is not proven from screenshot OCR/manual extraction. Primary surface classification is incomplete or unverified. Screen-specific critique does not yet explain visible UI, persona, task, and remediation. Current row verdict is `fail` with severity `major`. |
| `b25-v4-row-014-book-nomination-1` | Neighborhood Book Club | `book-nomination` | persona-under-review | B14_ext_book_club_book-nomination_action | Persona is generic or missing; the worker cannot know which role this screen serves. Visible text is not proven from screenshot OCR/manual extraction. Primary surface classification is incomplete or unverified. Screen-specific critique does not yet explain visible UI, persona, task, and remediation. Current row verdict is `fail` with severity `major`. |
| `b25-v4-row-015-book-nomination-2` | Neighborhood Book Club | `book-nomination` | persona-under-review | B14_ext_book_club_book-nomination_complete | Persona is generic or missing; the worker cannot know which role this screen serves. Visible text is not proven from screenshot OCR/manual extraction. Primary surface classification is incomplete or unverified. Screen-specific critique does not yet explain visible UI, persona, task, and remediation. Current row verdict is `fail` with severity `major`. |
| `b25-v4-row-016-book-vote-0` | Neighborhood Book Club | `book-vote` | persona-under-review | B14_ext_book_club_book-vote_start | Persona is generic or missing; the worker cannot know which role this screen serves. Visible text is not proven from screenshot OCR/manual extraction. Primary surface classification is incomplete or unverified. Screen-specific critique does not yet explain visible UI, persona, task, and remediation. Current row verdict is `fail` with severity `major`. |
| `b25-v4-row-017-book-vote-1` | Neighborhood Book Club | `book-vote` | persona-under-review | B14_ext_book_club_book-vote_action | Persona is generic or missing; the worker cannot know which role this screen serves. Visible text is not proven from screenshot OCR/manual extraction. Primary surface classification is incomplete or unverified. Screen-specific critique does not yet explain visible UI, persona, task, and remediation. Current row verdict is `fail` with severity `major`. |
| `b25-v4-row-018-book-vote-2` | Neighborhood Book Club | `book-vote` | persona-under-review | B14_ext_book_club_book-vote_complete | Persona is generic or missing; the worker cannot know which role this screen serves. Visible text is not proven from screenshot OCR/manual extraction. Primary surface classification is incomplete or unverified. Screen-specific critique does not yet explain visible UI, persona, task, and remediation. Current row verdict is `fail` with severity `major`. |
| `b25-v4-row-019-book-meeting-rsvp-0` | Neighborhood Book Club | `book-meeting-rsvp` | persona-under-review | B14_ext_book_club_book-meeting-rsvp_start | Persona is generic or missing; the worker cannot know which role this screen serves. Visible text is not proven from screenshot OCR/manual extraction. Primary surface classification is incomplete or unverified. Screen-specific critique does not yet explain visible UI, persona, task, and remediation. Current row verdict is `fail` with severity `major`. |
| `b25-v4-row-020-book-meeting-rsvp-1` | Neighborhood Book Club | `book-meeting-rsvp` | persona-under-review | B14_ext_book_club_book-meeting-rsvp_action | Persona is generic or missing; the worker cannot know which role this screen serves. Visible text is not proven from screenshot OCR/manual extraction. Primary surface classification is incomplete or unverified. Screen-specific critique does not yet explain visible UI, persona, task, and remediation. Current row verdict is `fail` with severity `major`. |
| `b25-v4-row-021-book-meeting-rsvp-2` | Neighborhood Book Club | `book-meeting-rsvp` | persona-under-review | B14_ext_book_club_book-meeting-rsvp_complete | Persona is generic or missing; the worker cannot know which role this screen serves. Visible text is not proven from screenshot OCR/manual extraction. Primary surface classification is incomplete or unverified. Screen-specific critique does not yet explain visible UI, persona, task, and remediation. Current row verdict is `fail` with severity `major`. |
| `b25-v4-row-022-book-discussion-message-0` | Neighborhood Book Club | `book-discussion-message` | persona-under-review | B14_ext_book_club_book-discussion-message_start | Persona is generic or missing; the worker cannot know which role this screen serves. Visible text is not proven from screenshot OCR/manual extraction. Primary surface classification is incomplete or unverified. Screen-specific critique does not yet explain visible UI, persona, task, and remediation. Current row verdict is `fail` with severity `major`. |
| `b25-v4-row-023-book-discussion-message-1` | Neighborhood Book Club | `book-discussion-message` | persona-under-review | B14_ext_book_club_book-discussion-message_action | Persona is generic or missing; the worker cannot know which role this screen serves. Visible text is not proven from screenshot OCR/manual extraction. Primary surface classification is incomplete or unverified. Screen-specific critique does not yet explain visible UI, persona, task, and remediation. Current row verdict is `fail` with severity `major`. |
| `b25-v4-row-024-book-discussion-message-2` | Neighborhood Book Club | `book-discussion-message` | persona-under-review | B14_ext_book_club_book-discussion-message_complete | Persona is generic or missing; the worker cannot know which role this screen serves. Visible text is not proven from screenshot OCR/manual extraction. Primary surface classification is incomplete or unverified. Screen-specific critique does not yet explain visible UI, persona, task, and remediation. Current row verdict is `fail` with severity `major`. |
| `b25-v4-row-025-book-selection-publish-0` | Neighborhood Book Club | `book-selection-publish` | persona-under-review | B14_ext_book_club_book-selection-publish_start | Persona is generic or missing; the worker cannot know which role this screen serves. Visible text is not proven from screenshot OCR/manual extraction. Primary surface classification is incomplete or unverified. Screen-specific critique does not yet explain visible UI, persona, task, and remediation. Current row verdict is `fail` with severity `major`. |
| `b25-v4-row-026-book-selection-publish-1` | Neighborhood Book Club | `book-selection-publish` | persona-under-review | B14_ext_book_club_book-selection-publish_action | Persona is generic or missing; the worker cannot know which role this screen serves. Visible text is not proven from screenshot OCR/manual extraction. Primary surface classification is incomplete or unverified. Screen-specific critique does not yet explain visible UI, persona, task, and remediation. Current row verdict is `fail` with severity `major`. |
| `b25-v4-row-027-book-selection-publish-2` | Neighborhood Book Club | `book-selection-publish` | persona-under-review | B14_ext_book_club_book-selection-publish_complete | Persona is generic or missing; the worker cannot know which role this screen serves. Visible text is not proven from screenshot OCR/manual extraction. Primary surface classification is incomplete or unverified. Screen-specific critique does not yet explain visible UI, persona, task, and remediation. Current row verdict is `fail` with severity `major`. |
| `b25-v4-row-028-book-search-ai-digest-0` | Neighborhood Book Club | `book-search-ai-digest` | persona-under-review | B14_ext_book_club_book-search-ai-digest_start | Persona is generic or missing; the worker cannot know which role this screen serves. Visible text is not proven from screenshot OCR/manual extraction. Primary surface classification is incomplete or unverified. Screen-specific critique does not yet explain visible UI, persona, task, and remediation. Current row verdict is `fail` with severity `major`. |
| `b25-v4-row-029-book-search-ai-digest-1` | Neighborhood Book Club | `book-search-ai-digest` | persona-under-review | B14_ext_book_club_book-search-ai-digest_action | Persona is generic or missing; the worker cannot know which role this screen serves. Visible text is not proven from screenshot OCR/manual extraction. Primary surface classification is incomplete or unverified. Screen-specific critique does not yet explain visible UI, persona, task, and remediation. Current row verdict is `fail` with severity `major`. |
| `b25-v4-row-030-book-search-ai-digest-2` | Neighborhood Book Club | `book-search-ai-digest` | persona-under-review | B14_ext_book_club_book-search-ai-digest_complete | Persona is generic or missing; the worker cannot know which role this screen serves. Visible text is not proven from screenshot OCR/manual extraction. Primary surface classification is incomplete or unverified. Screen-specific critique does not yet explain visible UI, persona, task, and remediation. Current row verdict is `fail` with severity `major`. |

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
- Screen row `b25-v4-row-001-workflow-ui-evidence-harness-0` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-001-workflow-ui-evidence-harness-0` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-001-workflow-ui-evidence-harness-0` names visible UI elements, visible text, persona `persona-under-review`, workflow `workflow-ui-evidence-harness`, and the exact product UX issue.
- Primary surface for `workflow-ui-evidence-harness` is documented as `explicit domain-native product surface selected from the B21 production UX contract` or another explicit domain-native surface.
- Fresh screenshot path/hash/timestamp/app commit SHA are recorded after the fix.
- Screen row `b25-v4-row-002-workflow-ui-evidence-harness-1` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-002-workflow-ui-evidence-harness-1` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-002-workflow-ui-evidence-harness-1` names visible UI elements, visible text, persona `persona-under-review`, workflow `workflow-ui-evidence-harness`, and the exact product UX issue.
- Screen row `b25-v4-row-003-workflow-ui-evidence-harness-2` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-003-workflow-ui-evidence-harness-2` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-003-workflow-ui-evidence-harness-2` names visible UI elements, visible text, persona `persona-under-review`, workflow `workflow-ui-evidence-harness`, and the exact product UX issue.
- Screen row `b25-v4-row-004-garden-event-rsvp-0` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-004-garden-event-rsvp-0` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-004-garden-event-rsvp-0` names visible UI elements, visible text, persona `persona-under-review`, workflow `garden-event-rsvp`, and the exact product UX issue.
- Primary surface for `garden-event-rsvp` is documented as `event detail with schedule, location, capacity/status, RSVP action, and result state` or another explicit domain-native surface.
- Screen row `b25-v4-row-005-garden-event-rsvp-1` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-005-garden-event-rsvp-1` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-005-garden-event-rsvp-1` names visible UI elements, visible text, persona `persona-under-review`, workflow `garden-event-rsvp`, and the exact product UX issue.
- Screen row `b25-v4-row-006-garden-event-rsvp-2` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-006-garden-event-rsvp-2` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-006-garden-event-rsvp-2` names visible UI elements, visible text, persona `persona-under-review`, workflow `garden-event-rsvp`, and the exact product UX issue.
- Screen row `b25-v4-row-007-plant-exchange-submission-0` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-007-plant-exchange-submission-0` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-007-plant-exchange-submission-0` names visible UI elements, visible text, persona `persona-under-review`, workflow `plant-exchange-submission`, and the exact product UX issue.
- Primary surface for `plant-exchange-submission` is documented as `explicit domain-native product surface selected from the B21 production UX contract` or another explicit domain-native surface.
- Screen row `b25-v4-row-008-plant-exchange-submission-1` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-008-plant-exchange-submission-1` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-008-plant-exchange-submission-1` names visible UI elements, visible text, persona `persona-under-review`, workflow `plant-exchange-submission`, and the exact product UX issue.
- Screen row `b25-v4-row-009-plant-exchange-submission-2` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-009-plant-exchange-submission-2` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-009-plant-exchange-submission-2` names visible UI elements, visible text, persona `persona-under-review`, workflow `plant-exchange-submission`, and the exact product UX issue.
- Screen row `b25-v4-row-010-garden-export-custom-schemas-0` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-010-garden-export-custom-schemas-0` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-010-garden-export-custom-schemas-0` names visible UI elements, visible text, persona `persona-under-review`, workflow `garden-export-custom-schemas`, and the exact product UX issue.
- Primary surface for `garden-export-custom-schemas` is documented as `export/import wizard with preview, redaction, checksum, transfer status, and rollback state` or another explicit domain-native surface.
- Screen row `b25-v4-row-011-garden-export-custom-schemas-1` has a specific persona/personaId, not `persona-under-review`.

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
| Ticket IDs | B25-RT-001-b25-c01-no-blocker-major, B25-RT-002-b25-c03-production-grade-experience, B25-RT-003-b25-c04-modern-intentional-ui, B25-RT-004-b25-c05-community-content-ia, B25-RT-005-b25-c06-domain-native-primary-surfaces, B25-RT-006-b25-c08-visible-text-specific-critique, B25-RT-007-b25-c09-no-layout-production-defects |

### Worker Actions
- Rebuild and relaunch the Demo App on the reviewed emulator/device.
- Recapture affected screenshots with hashes, timestamps, device metadata, and app commit SHA.
- Regenerate B25 schema v4 review JSON, markdown review, screen matrix, remediation tickets, and iteration scorecard.
- Commit the full iteration before starting the next UX feedback loop.

### Implementation Guidance
- Use each open remediation ticket as the implementation backlog.
- Update review JSON, remediation log, scorecards, tracker, and screenshots together.
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
- `docs/Build Plan V2/Evidence/B25/product-ux-remediation-loop.md`
- `docs/Build Plan V2/Build Tracker.md`
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
| Event detail and RSVP flow | Material cards/lists/buttons / pattern | https://m3.material.io/components/cards/overview<br>Also: https://m3.material.io/components/buttons/overview<br>https://m3.material.io/components/chips/overview | Copy an event detail layout: title, date/time, location, host, capacity/status chip, attendee context, RSVP action, and confirmation state. |
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
- open source Flutter domain-native-surface mobile UI example GitHub
- explicit domain-native product surface selected from the B21 production UX contract mobile UX pattern
- Material Design explicit domain-native product surface selected from the B21 production UX contract mobile pattern
- open source Flutter event-rsvp mobile UI example GitHub
- event detail with schedule, location, capacity/status, RSVP action, and result state mobile UX pattern
- Material Design event detail with schedule, location, capacity/status, RSVP action, and result state mobile pattern
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

### Evidence Repair Work Items

Showing 30 of 70 work items. Full detail is in the JSON artifact.

| Work item | Stage | Community | Workflow | Persona | Screens | Coverage | Target surface | Blocked until |
| --- | --- | --- | --- | --- | ---: | ---: | --- | --- |
| `b25-wi-evidence-repair-workflow-ui-evidence-harness-workflow-ui-evidence-harness-persona-under-review` | `evidence-repair` | workflow-ui-evidence-harness | `workflow-ui-evidence-harness` | persona-under-review | 3 | 1 | explicit domain-native product surface selected from the B21 production UX contract |  |
| `b25-wi-evidence-repair-community-garden-club-garden-event-rsvp-persona-under-review` | `evidence-repair` | Garden Club | `garden-event-rsvp` | persona-under-review | 3 | 1 | event detail with schedule, location, capacity/status, RSVP action, and result state |  |
| `b25-wi-evidence-repair-community-garden-club-plant-exchange-submission-persona-under-review` | `evidence-repair` | Garden Club | `plant-exchange-submission` | persona-under-review | 3 | 1 | explicit domain-native product surface selected from the B21 production UX contract |  |
| `b25-wi-evidence-repair-community-garden-club-garden-export-custom-schemas-persona-under-review` | `evidence-repair` | Garden Club | `garden-export-custom-schemas` | persona-under-review | 3 | 1 | export/import wizard with preview, redaction, checksum, transfer status, and rollback state |  |
| `b25-wi-evidence-repair-community-book-club-book-nomination-persona-under-review` | `evidence-repair` | Neighborhood Book Club | `book-nomination` | persona-under-review | 3 | 1 | book club reading/voting surface with nominations, vote state, selected book, meeting context, and discussion |  |
| `b25-wi-evidence-repair-community-book-club-book-vote-persona-under-review` | `evidence-repair` | Neighborhood Book Club | `book-vote` | persona-under-review | 3 | 1 | book club reading/voting surface with nominations, vote state, selected book, meeting context, and discussion |  |
| `b25-wi-evidence-repair-community-book-club-book-meeting-rsvp-persona-under-review` | `evidence-repair` | Neighborhood Book Club | `book-meeting-rsvp` | persona-under-review | 3 | 1 | event detail with schedule, location, capacity/status, RSVP action, and result state |  |
| `b25-wi-evidence-repair-community-book-club-book-discussion-message-persona-under-review` | `evidence-repair` | Neighborhood Book Club | `book-discussion-message` | persona-under-review | 3 | 1 | inbox, message thread, connection card, invite, or block-state surface |  |
| `b25-wi-evidence-repair-community-book-club-book-selection-publish-persona-under-review` | `evidence-repair` | Neighborhood Book Club | `book-selection-publish` | persona-under-review | 3 | 1 | announcement feed/composer with audience, author, timestamp, body, and receiver state |  |
| `b25-wi-evidence-repair-community-book-club-book-search-ai-digest-persona-under-review` | `evidence-repair` | Neighborhood Book Club | `book-search-ai-digest` | persona-under-review | 3 | 1 | search/AI answer surface with query, result, citation, source, and follow-up action |  |
| `b25-wi-evidence-repair-community-book-club-book-export-metadata-persona-under-review` | `evidence-repair` | Neighborhood Book Club | `book-export-metadata` | persona-under-review | 3 | 1 | export/import wizard with preview, redaction, checksum, transfer status, and rollback state |  |
| `b25-wi-evidence-repair-community-youth-soccer-soccer-guardian-join-approval-persona-under-review` | `evidence-repair` | Riverside Youth Soccer | `soccer-guardian-join-approval` | persona-under-review | 3 | 1 | request detail and admin review queue with submitted data, decision action, status, and notification |  |
| `b25-wi-evidence-repair-community-youth-soccer-soccer-team-roster-persona-under-review` | `evidence-repair` | Riverside Youth Soccer | `soccer-team-roster` | persona-under-review | 3 | 1 | team roster/schedule surface with role-filtered member details and protected-data treatment |  |
| `b25-wi-evidence-repair-community-youth-soccer-soccer-minor-redaction-persona-under-review` | `evidence-repair` | Riverside Youth Soccer | `soccer-minor-redaction` | persona-under-review | 3 | 1 | explicit domain-native product surface selected from the B21 production UX contract |  |
| `b25-wi-evidence-repair-community-youth-soccer-soccer-registration-payment-persona-under-review` | `evidence-repair` | Riverside Youth Soccer | `soccer-registration-payment` | persona-under-review | 3 | 1 | payment or donation flow with amount, payer context, receipt, entitlement/status, and audit trail |  |
| `b25-wi-evidence-repair-community-youth-soccer-soccer-practice-schedule-persona-under-review` | `evidence-repair` | Riverside Youth Soccer | `soccer-practice-schedule` | persona-under-review | 3 | 1 | event detail with schedule, location, capacity/status, RSVP action, and result state |  |
| `b25-wi-evidence-repair-community-youth-soccer-soccer-reminder-notification-persona-under-review` | `evidence-repair` | Riverside Youth Soccer | `soccer-reminder-notification` | persona-under-review | 3 | 1 | explicit domain-native product surface selected from the B21 production UX contract |  |
| `b25-wi-evidence-repair-community-youth-soccer-soccer-export-metadata-persona-under-review` | `evidence-repair` | Riverside Youth Soccer | `soccer-export-metadata` | persona-under-review | 3 | 1 | export/import wizard with preview, redaction, checksum, transfer status, and rollback state |  |
| `b25-wi-evidence-repair-community-hoa-hoa-dues-payment-persona-under-review` | `evidence-repair` | Cedar Commons HOA | `hoa-dues-payment` | persona-under-review | 3 | 1 | payment or donation flow with amount, payer context, receipt, entitlement/status, and audit trail |  |
| `b25-wi-evidence-repair-community-hoa-hoa-facility-reservation-persona-under-review` | `evidence-repair` | Cedar Commons HOA | `hoa-facility-reservation` | persona-under-review | 3 | 1 | facility detail/reservation flow with availability, payment/status, and confirmation |  |
| `b25-wi-evidence-repair-community-hoa-hoa-architectural-request-persona-under-review` | `evidence-repair` | Cedar Commons HOA | `hoa-architectural-request` | persona-under-review | 3 | 1 | request detail and admin review queue with submitted data, decision action, status, and notification |  |
| `b25-wi-evidence-repair-community-hoa-hoa-committee-decision-persona-under-review` | `evidence-repair` | Cedar Commons HOA | `hoa-committee-decision` | persona-under-review | 3 | 1 | request detail and admin review queue with submitted data, decision action, status, and notification |  |
| `b25-wi-evidence-repair-community-hoa-hoa-export-evidence-persona-under-review` | `evidence-repair` | Cedar Commons HOA | `hoa-export-evidence` | persona-under-review | 3 | 1 | export/import wizard with preview, redaction, checksum, transfer status, and rollback state |  |
| `b25-wi-evidence-repair-community-mosque-mosque-announcement-persona-under-review` | `evidence-repair` | Masjid Nur | `mosque-announcement` | persona-under-review | 3 | 1 | announcement feed/composer with audience, author, timestamp, body, and receiver state |  |
| `b25-wi-evidence-repair-community-mosque-mosque-event-rsvp-persona-under-review` | `evidence-repair` | Masjid Nur | `mosque-event-rsvp` | persona-under-review | 3 | 1 | event detail with schedule, location, capacity/status, RSVP action, and result state |  |
| `b25-wi-evidence-repair-community-mosque-mosque-volunteer-signup-persona-under-review` | `evidence-repair` | Masjid Nur | `mosque-volunteer-signup` | persona-under-review | 3 | 1 | volunteer signup surface with role, time, protected contact fields, and confirmation |  |
| `b25-wi-evidence-repair-community-mosque-mosque-donor-visibility-persona-under-review` | `evidence-repair` | Masjid Nur | `mosque-donor-visibility` | persona-under-review | 3 | 1 | explicit domain-native product surface selected from the B21 production UX contract |  |
| `b25-wi-evidence-repair-community-mosque-mosque-donation-payment-persona-under-review` | `evidence-repair` | Masjid Nur | `mosque-donation-payment` | persona-under-review | 3 | 1 | payment or donation flow with amount, payer context, receipt, entitlement/status, and audit trail |  |
| `b25-wi-evidence-repair-community-mosque-mosque-care-request-persona-under-review` | `evidence-repair` | Masjid Nur | `mosque-care-request` | persona-under-review | 3 | 1 | protected care request form and private response/status surface |  |
| `b25-wi-evidence-repair-community-mosque-mosque-neutral-notification-persona-under-review` | `evidence-repair` | Masjid Nur | `mosque-neutral-notification` | persona-under-review | 3 | 1 | explicit domain-native product surface selected from the B21 production UX contract |  |

### Evidence Repair Work Items Reference Patterns

| Reference | Source | URL | What to copy |
| --- | --- | --- | --- |
| Material detail surface composition | Material Design 3 / design-system | https://m3.material.io/components/cards/overview | Build a domain detail page with primary content, metadata, status, and actions instead of a generic task card. |
| Material Design cards and lists | Material Design 3 / design-system | https://m3.material.io/components/cards/overview<br>Also: https://m3.material.io/components/lists/overview | Use cards/lists only as scannable containers with clear hierarchy, content, metadata, and actions. Do not use repeated cards as the whole primary workflow. |
| Flutter sample app implementation patterns | flutter/samples / open-source | https://github.com/flutter/samples | Copy the separation between app shell, route state, domain widgets, and testable UI states rather than hardcoding a single generic renderer. |
| Material navigation and information architecture | Material Design 3 / design-system | https://m3.material.io/components/navigation-drawer/overview<br>Also: https://m3.material.io/components/navigation-bar/overview | Organize screens by user jobs and destinations; keep primary actions visible and avoid exposing implementation taxonomy. |
| Apple HIG navigation and content organization | Apple Human Interface Guidelines / design-system | https://developer.apple.com/design/human-interface-guidelines/navigation | Make navigation predictable, content-centered, and appropriate for the user’s current task. |
| Event detail and RSVP flow | Material cards/lists/buttons / pattern | https://m3.material.io/components/cards/overview<br>Also: https://m3.material.io/components/buttons/overview<br>https://m3.material.io/components/chips/overview | Copy an event detail layout: title, date/time, location, host, capacity/status chip, attendee context, RSVP action, and confirmation state. |
| Task list and export wizard | GOV.UK Design System / design-system | https://design-system.service.gov.uk/components/task-list/<br>Also: https://design-system.service.gov.uk/patterns/check-answers/ | Copy a wizard with steps, preview, redaction choices, checksum evidence, transfer status, and rollback confirmation. |
| Selection and voting pattern | Material chips/cards/buttons / pattern | https://m3.material.io/components/chips/overview<br>Also: https://m3.material.io/components/cards/overview | Copy a nomination/voting surface with choices, current vote state, deadline, selected result, and meeting/discussion context. |
| Inbox and message thread pattern | Material lists/text fields / pattern | https://m3.material.io/components/lists/overview<br>Also: https://m3.material.io/components/text-fields/overview | Copy an inbox/thread structure: sender, timestamp, message preview/body, reply field, invite/block state, and read/received state. |
| Feed item and composer pattern | Material cards/lists/text fields / pattern | https://m3.material.io/components/text-fields/overview<br>Also: https://m3.material.io/components/cards/overview<br>https://m3.material.io/components/lists/overview | Copy a feed/composer structure: audience, author, timestamp, body, attachments/status, publish action, and receiver read state. |
| Search and result list pattern | Material Design 3 / design-system | https://m3.material.io/components/search/overview<br>Also: https://m3.material.io/components/lists/overview | Copy a search layout with query, filters, ranked results, citations/sources, empty/error states, and follow-up actions. |
| Form validation and review pattern | U.S. Web Design System / design-system | https://designsystem.digital.gov/components/form/<br>Also: https://designsystem.digital.gov/components/alert/<br>https://design-system.service.gov.uk/components/error-summary/ | Copy a form flow with field labels, helper text, validation errors, review state, submit action, status, and protected-data treatment. |

### UI Remediation Work Items

Showing 30 of 70 work items. Full detail is in the JSON artifact.

| Work item | Stage | Community | Workflow | Persona | Screens | Coverage | Target surface | Blocked until |
| --- | --- | --- | --- | --- | ---: | ---: | --- | --- |
| `b25-wi-ui-remediation-workflow-ui-evidence-harness-workflow-ui-evidence-harness-persona-under-review` | `ui-remediation` | workflow-ui-evidence-harness | `workflow-ui-evidence-harness` | persona-under-review | 3 | 1 | explicit domain-native product surface selected from the B21 production UX contract | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-garden-club-garden-event-rsvp-persona-under-review` | `ui-remediation` | Garden Club | `garden-event-rsvp` | persona-under-review | 3 | 1 | event detail with schedule, location, capacity/status, RSVP action, and result state | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-garden-club-plant-exchange-submission-persona-under-review` | `ui-remediation` | Garden Club | `plant-exchange-submission` | persona-under-review | 3 | 1 | explicit domain-native product surface selected from the B21 production UX contract | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-garden-club-garden-export-custom-schemas-persona-under-review` | `ui-remediation` | Garden Club | `garden-export-custom-schemas` | persona-under-review | 3 | 1 | export/import wizard with preview, redaction, checksum, transfer status, and rollback state | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-book-club-book-nomination-persona-under-review` | `ui-remediation` | Neighborhood Book Club | `book-nomination` | persona-under-review | 3 | 1 | book club reading/voting surface with nominations, vote state, selected book, meeting context, and discussion | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-book-club-book-vote-persona-under-review` | `ui-remediation` | Neighborhood Book Club | `book-vote` | persona-under-review | 3 | 1 | book club reading/voting surface with nominations, vote state, selected book, meeting context, and discussion | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-book-club-book-meeting-rsvp-persona-under-review` | `ui-remediation` | Neighborhood Book Club | `book-meeting-rsvp` | persona-under-review | 3 | 1 | event detail with schedule, location, capacity/status, RSVP action, and result state | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-book-club-book-discussion-message-persona-under-review` | `ui-remediation` | Neighborhood Book Club | `book-discussion-message` | persona-under-review | 3 | 1 | inbox, message thread, connection card, invite, or block-state surface | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-book-club-book-selection-publish-persona-under-review` | `ui-remediation` | Neighborhood Book Club | `book-selection-publish` | persona-under-review | 3 | 1 | announcement feed/composer with audience, author, timestamp, body, and receiver state | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-book-club-book-search-ai-digest-persona-under-review` | `ui-remediation` | Neighborhood Book Club | `book-search-ai-digest` | persona-under-review | 3 | 1 | search/AI answer surface with query, result, citation, source, and follow-up action | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-book-club-book-export-metadata-persona-under-review` | `ui-remediation` | Neighborhood Book Club | `book-export-metadata` | persona-under-review | 3 | 1 | export/import wizard with preview, redaction, checksum, transfer status, and rollback state | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-youth-soccer-soccer-guardian-join-approval-persona-under-review` | `ui-remediation` | Riverside Youth Soccer | `soccer-guardian-join-approval` | persona-under-review | 3 | 1 | request detail and admin review queue with submitted data, decision action, status, and notification | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-youth-soccer-soccer-team-roster-persona-under-review` | `ui-remediation` | Riverside Youth Soccer | `soccer-team-roster` | persona-under-review | 3 | 1 | team roster/schedule surface with role-filtered member details and protected-data treatment | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-youth-soccer-soccer-minor-redaction-persona-under-review` | `ui-remediation` | Riverside Youth Soccer | `soccer-minor-redaction` | persona-under-review | 3 | 1 | explicit domain-native product surface selected from the B21 production UX contract | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-youth-soccer-soccer-registration-payment-persona-under-review` | `ui-remediation` | Riverside Youth Soccer | `soccer-registration-payment` | persona-under-review | 3 | 1 | payment or donation flow with amount, payer context, receipt, entitlement/status, and audit trail | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-youth-soccer-soccer-practice-schedule-persona-under-review` | `ui-remediation` | Riverside Youth Soccer | `soccer-practice-schedule` | persona-under-review | 3 | 1 | event detail with schedule, location, capacity/status, RSVP action, and result state | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-youth-soccer-soccer-reminder-notification-persona-under-review` | `ui-remediation` | Riverside Youth Soccer | `soccer-reminder-notification` | persona-under-review | 3 | 1 | explicit domain-native product surface selected from the B21 production UX contract | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-youth-soccer-soccer-export-metadata-persona-under-review` | `ui-remediation` | Riverside Youth Soccer | `soccer-export-metadata` | persona-under-review | 3 | 1 | export/import wizard with preview, redaction, checksum, transfer status, and rollback state | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-hoa-hoa-dues-payment-persona-under-review` | `ui-remediation` | Cedar Commons HOA | `hoa-dues-payment` | persona-under-review | 3 | 1 | payment or donation flow with amount, payer context, receipt, entitlement/status, and audit trail | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-hoa-hoa-facility-reservation-persona-under-review` | `ui-remediation` | Cedar Commons HOA | `hoa-facility-reservation` | persona-under-review | 3 | 1 | facility detail/reservation flow with availability, payment/status, and confirmation | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-hoa-hoa-architectural-request-persona-under-review` | `ui-remediation` | Cedar Commons HOA | `hoa-architectural-request` | persona-under-review | 3 | 1 | request detail and admin review queue with submitted data, decision action, status, and notification | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-hoa-hoa-committee-decision-persona-under-review` | `ui-remediation` | Cedar Commons HOA | `hoa-committee-decision` | persona-under-review | 3 | 1 | request detail and admin review queue with submitted data, decision action, status, and notification | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-hoa-hoa-export-evidence-persona-under-review` | `ui-remediation` | Cedar Commons HOA | `hoa-export-evidence` | persona-under-review | 3 | 1 | export/import wizard with preview, redaction, checksum, transfer status, and rollback state | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-mosque-mosque-announcement-persona-under-review` | `ui-remediation` | Masjid Nur | `mosque-announcement` | persona-under-review | 3 | 1 | announcement feed/composer with audience, author, timestamp, body, and receiver state | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-mosque-mosque-event-rsvp-persona-under-review` | `ui-remediation` | Masjid Nur | `mosque-event-rsvp` | persona-under-review | 3 | 1 | event detail with schedule, location, capacity/status, RSVP action, and result state | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-mosque-mosque-volunteer-signup-persona-under-review` | `ui-remediation` | Masjid Nur | `mosque-volunteer-signup` | persona-under-review | 3 | 1 | volunteer signup surface with role, time, protected contact fields, and confirmation | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-mosque-mosque-donor-visibility-persona-under-review` | `ui-remediation` | Masjid Nur | `mosque-donor-visibility` | persona-under-review | 3 | 1 | explicit domain-native product surface selected from the B21 production UX contract | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-mosque-mosque-donation-payment-persona-under-review` | `ui-remediation` | Masjid Nur | `mosque-donation-payment` | persona-under-review | 3 | 1 | payment or donation flow with amount, payer context, receipt, entitlement/status, and audit trail | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-mosque-mosque-care-request-persona-under-review` | `ui-remediation` | Masjid Nur | `mosque-care-request` | persona-under-review | 3 | 1 | protected care request form and private response/status surface | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-mosque-mosque-neutral-notification-persona-under-review` | `ui-remediation` | Masjid Nur | `mosque-neutral-notification` | persona-under-review | 3 | 1 | explicit domain-native product surface selected from the B21 production UX contract | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |

### UI Remediation Work Items Reference Patterns

| Reference | Source | URL | What to copy |
| --- | --- | --- | --- |
| Material detail surface composition | Material Design 3 / design-system | https://m3.material.io/components/cards/overview | Build a domain detail page with primary content, metadata, status, and actions instead of a generic task card. |
| Material Design cards and lists | Material Design 3 / design-system | https://m3.material.io/components/cards/overview<br>Also: https://m3.material.io/components/lists/overview | Use cards/lists only as scannable containers with clear hierarchy, content, metadata, and actions. Do not use repeated cards as the whole primary workflow. |
| Flutter sample app implementation patterns | flutter/samples / open-source | https://github.com/flutter/samples | Copy the separation between app shell, route state, domain widgets, and testable UI states rather than hardcoding a single generic renderer. |
| Material navigation and information architecture | Material Design 3 / design-system | https://m3.material.io/components/navigation-drawer/overview<br>Also: https://m3.material.io/components/navigation-bar/overview | Organize screens by user jobs and destinations; keep primary actions visible and avoid exposing implementation taxonomy. |
| Apple HIG navigation and content organization | Apple Human Interface Guidelines / design-system | https://developer.apple.com/design/human-interface-guidelines/navigation | Make navigation predictable, content-centered, and appropriate for the user’s current task. |
| Event detail and RSVP flow | Material cards/lists/buttons / pattern | https://m3.material.io/components/cards/overview<br>Also: https://m3.material.io/components/buttons/overview<br>https://m3.material.io/components/chips/overview | Copy an event detail layout: title, date/time, location, host, capacity/status chip, attendee context, RSVP action, and confirmation state. |
| Task list and export wizard | GOV.UK Design System / design-system | https://design-system.service.gov.uk/components/task-list/<br>Also: https://design-system.service.gov.uk/patterns/check-answers/ | Copy a wizard with steps, preview, redaction choices, checksum evidence, transfer status, and rollback confirmation. |
| Selection and voting pattern | Material chips/cards/buttons / pattern | https://m3.material.io/components/chips/overview<br>Also: https://m3.material.io/components/cards/overview | Copy a nomination/voting surface with choices, current vote state, deadline, selected result, and meeting/discussion context. |
| Inbox and message thread pattern | Material lists/text fields / pattern | https://m3.material.io/components/lists/overview<br>Also: https://m3.material.io/components/text-fields/overview | Copy an inbox/thread structure: sender, timestamp, message preview/body, reply field, invite/block state, and read/received state. |
| Feed item and composer pattern | Material cards/lists/text fields / pattern | https://m3.material.io/components/text-fields/overview<br>Also: https://m3.material.io/components/cards/overview<br>https://m3.material.io/components/lists/overview | Copy a feed/composer structure: audience, author, timestamp, body, attachments/status, publish action, and receiver read state. |
| Search and result list pattern | Material Design 3 / design-system | https://m3.material.io/components/search/overview<br>Also: https://m3.material.io/components/lists/overview | Copy a search layout with query, filters, ranked results, citations/sources, empty/error states, and follow-up actions. |
| Form validation and review pattern | U.S. Web Design System / design-system | https://designsystem.digital.gov/components/form/<br>Also: https://designsystem.digital.gov/components/alert/<br>https://design-system.service.gov.uk/components/error-summary/ | Copy a form flow with field labels, helper text, validation errors, review state, submit action, status, and protected-data treatment. |

### Affected Coverage Rows

Showing 30 of 70 affected coverage rows.

| Coverage row | Community | Workflow | Persona | Missing evidence |
| --- | --- | --- | --- | --- |
| `b25-wp-001-workflow-ui-evidence-harness-persona-under-review` | workflow-ui-evidence-harness | `workflow-ui-evidence-harness` | persona-under-review | specific persona/personaId |
| `b25-wp-002-garden-event-rsvp-persona-under-review` | Garden Club | `garden-event-rsvp` | persona-under-review | specific persona/personaId |
| `b25-wp-003-plant-exchange-submission-persona-under-review` | Garden Club | `plant-exchange-submission` | persona-under-review | specific persona/personaId |
| `b25-wp-004-garden-export-custom-schemas-persona-under-review` | Garden Club | `garden-export-custom-schemas` | persona-under-review | specific persona/personaId |
| `b25-wp-005-book-nomination-persona-under-review` | Neighborhood Book Club | `book-nomination` | persona-under-review | specific persona/personaId |
| `b25-wp-006-book-vote-persona-under-review` | Neighborhood Book Club | `book-vote` | persona-under-review | specific persona/personaId |
| `b25-wp-007-book-meeting-rsvp-persona-under-review` | Neighborhood Book Club | `book-meeting-rsvp` | persona-under-review | specific persona/personaId |
| `b25-wp-008-book-discussion-message-persona-under-review` | Neighborhood Book Club | `book-discussion-message` | persona-under-review | specific persona/personaId |
| `b25-wp-009-book-selection-publish-persona-under-review` | Neighborhood Book Club | `book-selection-publish` | persona-under-review | specific persona/personaId |
| `b25-wp-010-book-search-ai-digest-persona-under-review` | Neighborhood Book Club | `book-search-ai-digest` | persona-under-review | specific persona/personaId |
| `b25-wp-011-book-export-metadata-persona-under-review` | Neighborhood Book Club | `book-export-metadata` | persona-under-review | specific persona/personaId |
| `b25-wp-012-soccer-guardian-join-approval-persona-under-review` | Riverside Youth Soccer | `soccer-guardian-join-approval` | persona-under-review | specific persona/personaId |
| `b25-wp-013-soccer-team-roster-persona-under-review` | Riverside Youth Soccer | `soccer-team-roster` | persona-under-review | specific persona/personaId |
| `b25-wp-014-soccer-minor-redaction-persona-under-review` | Riverside Youth Soccer | `soccer-minor-redaction` | persona-under-review | specific persona/personaId |
| `b25-wp-015-soccer-registration-payment-persona-under-review` | Riverside Youth Soccer | `soccer-registration-payment` | persona-under-review | specific persona/personaId |
| `b25-wp-016-soccer-practice-schedule-persona-under-review` | Riverside Youth Soccer | `soccer-practice-schedule` | persona-under-review | specific persona/personaId |
| `b25-wp-017-soccer-reminder-notification-persona-under-review` | Riverside Youth Soccer | `soccer-reminder-notification` | persona-under-review | specific persona/personaId |
| `b25-wp-018-soccer-export-metadata-persona-under-review` | Riverside Youth Soccer | `soccer-export-metadata` | persona-under-review | specific persona/personaId |
| `b25-wp-019-hoa-dues-payment-persona-under-review` | Cedar Commons HOA | `hoa-dues-payment` | persona-under-review | specific persona/personaId |
| `b25-wp-021-hoa-facility-reservation-persona-under-review` | Cedar Commons HOA | `hoa-facility-reservation` | persona-under-review | specific persona/personaId |
| `b25-wp-022-hoa-architectural-request-persona-under-review` | Cedar Commons HOA | `hoa-architectural-request` | persona-under-review | specific persona/personaId |
| `b25-wp-023-hoa-committee-decision-persona-under-review` | Cedar Commons HOA | `hoa-committee-decision` | persona-under-review | specific persona/personaId |
| `b25-wp-025-hoa-export-evidence-persona-under-review` | Cedar Commons HOA | `hoa-export-evidence` | persona-under-review | specific persona/personaId |
| `b25-wp-026-mosque-announcement-persona-under-review` | Masjid Nur | `mosque-announcement` | persona-under-review | specific persona/personaId |
| `b25-wp-027-mosque-event-rsvp-persona-under-review` | Masjid Nur | `mosque-event-rsvp` | persona-under-review | specific persona/personaId |
| `b25-wp-028-mosque-volunteer-signup-persona-under-review` | Masjid Nur | `mosque-volunteer-signup` | persona-under-review | specific persona/personaId |
| `b25-wp-029-mosque-donor-visibility-persona-under-review` | Masjid Nur | `mosque-donor-visibility` | persona-under-review | specific persona/personaId |
| `b25-wp-030-mosque-donation-payment-persona-under-review` | Masjid Nur | `mosque-donation-payment` | persona-under-review | specific persona/personaId |
| `b25-wp-031-mosque-care-request-persona-under-review` | Masjid Nur | `mosque-care-request` | persona-under-review | specific persona/personaId |
| `b25-wp-032-mosque-neutral-notification-persona-under-review` | Masjid Nur | `mosque-neutral-notification` | persona-under-review | specific persona/personaId |

### Affected Screen Rows

Showing 30 of 199 affected screen rows.

| Screen row | Community | Workflow | Persona | State | Exact UX failure |
| --- | --- | --- | --- | --- | --- |
| `b25-v4-row-001-workflow-ui-evidence-harness-0` | workflow-ui-evidence-harness | `workflow-ui-evidence-harness` | persona-under-review | B12_harness_start | Persona is generic or missing; the worker cannot know which role this screen serves. Visible text is not proven from screenshot OCR/manual extraction. Primary surface classification is incomplete or unverified. Screen-specific critique does not yet explain visible UI, persona, task, and remediation. Current row verdict is `fail` with severity `major`. |
| `b25-v4-row-002-workflow-ui-evidence-harness-1` | workflow-ui-evidence-harness | `workflow-ui-evidence-harness` | persona-under-review | B12_harness_action | Persona is generic or missing; the worker cannot know which role this screen serves. Visible text is not proven from screenshot OCR/manual extraction. Primary surface classification is incomplete or unverified. Screen-specific critique does not yet explain visible UI, persona, task, and remediation. Current row verdict is `fail` with severity `major`. |
| `b25-v4-row-003-workflow-ui-evidence-harness-2` | workflow-ui-evidence-harness | `workflow-ui-evidence-harness` | persona-under-review | B12_harness_complete | Persona is generic or missing; the worker cannot know which role this screen serves. Visible text is not proven from screenshot OCR/manual extraction. Primary surface classification is incomplete or unverified. Screen-specific critique does not yet explain visible UI, persona, task, and remediation. Current row verdict is `fail` with severity `major`. |
| `b25-v4-row-004-garden-event-rsvp-0` | Garden Club | `garden-event-rsvp` | persona-under-review | B13_ext_garden_club_garden-event-rsvp_start | Persona is generic or missing; the worker cannot know which role this screen serves. Visible text is not proven from screenshot OCR/manual extraction. Primary surface classification is incomplete or unverified. Screen-specific critique does not yet explain visible UI, persona, task, and remediation. Current row verdict is `fail` with severity `major`. |
| `b25-v4-row-005-garden-event-rsvp-1` | Garden Club | `garden-event-rsvp` | persona-under-review | B13_ext_garden_club_garden-event-rsvp_action | Persona is generic or missing; the worker cannot know which role this screen serves. Visible text is not proven from screenshot OCR/manual extraction. Primary surface classification is incomplete or unverified. Screen-specific critique does not yet explain visible UI, persona, task, and remediation. Current row verdict is `fail` with severity `major`. |
| `b25-v4-row-006-garden-event-rsvp-2` | Garden Club | `garden-event-rsvp` | persona-under-review | B13_ext_garden_club_garden-event-rsvp_complete | Persona is generic or missing; the worker cannot know which role this screen serves. Visible text is not proven from screenshot OCR/manual extraction. Primary surface classification is incomplete or unverified. Screen-specific critique does not yet explain visible UI, persona, task, and remediation. Current row verdict is `fail` with severity `major`. |
| `b25-v4-row-007-plant-exchange-submission-0` | Garden Club | `plant-exchange-submission` | persona-under-review | B13_ext_garden_club_plant-exchange-submission_start | Persona is generic or missing; the worker cannot know which role this screen serves. Visible text is not proven from screenshot OCR/manual extraction. Primary surface classification is incomplete or unverified. Screen-specific critique does not yet explain visible UI, persona, task, and remediation. Current row verdict is `fail` with severity `major`. |
| `b25-v4-row-008-plant-exchange-submission-1` | Garden Club | `plant-exchange-submission` | persona-under-review | B13_ext_garden_club_plant-exchange-submission_action | Persona is generic or missing; the worker cannot know which role this screen serves. Visible text is not proven from screenshot OCR/manual extraction. Primary surface classification is incomplete or unverified. Screen-specific critique does not yet explain visible UI, persona, task, and remediation. Current row verdict is `fail` with severity `major`. |
| `b25-v4-row-009-plant-exchange-submission-2` | Garden Club | `plant-exchange-submission` | persona-under-review | B13_ext_garden_club_plant-exchange-submission_complete | Persona is generic or missing; the worker cannot know which role this screen serves. Visible text is not proven from screenshot OCR/manual extraction. Primary surface classification is incomplete or unverified. Screen-specific critique does not yet explain visible UI, persona, task, and remediation. Current row verdict is `fail` with severity `major`. |
| `b25-v4-row-010-garden-export-custom-schemas-0` | Garden Club | `garden-export-custom-schemas` | persona-under-review | B13_ext_garden_club_garden-export-custom-schemas_start | Persona is generic or missing; the worker cannot know which role this screen serves. Visible text is not proven from screenshot OCR/manual extraction. Primary surface classification is incomplete or unverified. Screen-specific critique does not yet explain visible UI, persona, task, and remediation. Current row verdict is `fail` with severity `major`. |
| `b25-v4-row-011-garden-export-custom-schemas-1` | Garden Club | `garden-export-custom-schemas` | persona-under-review | B13_ext_garden_club_garden-export-custom-schemas_action | Persona is generic or missing; the worker cannot know which role this screen serves. Visible text is not proven from screenshot OCR/manual extraction. Primary surface classification is incomplete or unverified. Screen-specific critique does not yet explain visible UI, persona, task, and remediation. Current row verdict is `fail` with severity `major`. |
| `b25-v4-row-012-garden-export-custom-schemas-2` | Garden Club | `garden-export-custom-schemas` | persona-under-review | B13_ext_garden_club_garden-export-custom-schemas_complete | Persona is generic or missing; the worker cannot know which role this screen serves. Visible text is not proven from screenshot OCR/manual extraction. Primary surface classification is incomplete or unverified. Screen-specific critique does not yet explain visible UI, persona, task, and remediation. Current row verdict is `fail` with severity `major`. |
| `b25-v4-row-013-book-nomination-0` | Neighborhood Book Club | `book-nomination` | persona-under-review | B14_ext_book_club_book-nomination_start | Persona is generic or missing; the worker cannot know which role this screen serves. Visible text is not proven from screenshot OCR/manual extraction. Primary surface classification is incomplete or unverified. Screen-specific critique does not yet explain visible UI, persona, task, and remediation. Current row verdict is `fail` with severity `major`. |
| `b25-v4-row-014-book-nomination-1` | Neighborhood Book Club | `book-nomination` | persona-under-review | B14_ext_book_club_book-nomination_action | Persona is generic or missing; the worker cannot know which role this screen serves. Visible text is not proven from screenshot OCR/manual extraction. Primary surface classification is incomplete or unverified. Screen-specific critique does not yet explain visible UI, persona, task, and remediation. Current row verdict is `fail` with severity `major`. |
| `b25-v4-row-015-book-nomination-2` | Neighborhood Book Club | `book-nomination` | persona-under-review | B14_ext_book_club_book-nomination_complete | Persona is generic or missing; the worker cannot know which role this screen serves. Visible text is not proven from screenshot OCR/manual extraction. Primary surface classification is incomplete or unverified. Screen-specific critique does not yet explain visible UI, persona, task, and remediation. Current row verdict is `fail` with severity `major`. |
| `b25-v4-row-016-book-vote-0` | Neighborhood Book Club | `book-vote` | persona-under-review | B14_ext_book_club_book-vote_start | Persona is generic or missing; the worker cannot know which role this screen serves. Visible text is not proven from screenshot OCR/manual extraction. Primary surface classification is incomplete or unverified. Screen-specific critique does not yet explain visible UI, persona, task, and remediation. Current row verdict is `fail` with severity `major`. |
| `b25-v4-row-017-book-vote-1` | Neighborhood Book Club | `book-vote` | persona-under-review | B14_ext_book_club_book-vote_action | Persona is generic or missing; the worker cannot know which role this screen serves. Visible text is not proven from screenshot OCR/manual extraction. Primary surface classification is incomplete or unverified. Screen-specific critique does not yet explain visible UI, persona, task, and remediation. Current row verdict is `fail` with severity `major`. |
| `b25-v4-row-018-book-vote-2` | Neighborhood Book Club | `book-vote` | persona-under-review | B14_ext_book_club_book-vote_complete | Persona is generic or missing; the worker cannot know which role this screen serves. Visible text is not proven from screenshot OCR/manual extraction. Primary surface classification is incomplete or unverified. Screen-specific critique does not yet explain visible UI, persona, task, and remediation. Current row verdict is `fail` with severity `major`. |
| `b25-v4-row-019-book-meeting-rsvp-0` | Neighborhood Book Club | `book-meeting-rsvp` | persona-under-review | B14_ext_book_club_book-meeting-rsvp_start | Persona is generic or missing; the worker cannot know which role this screen serves. Visible text is not proven from screenshot OCR/manual extraction. Primary surface classification is incomplete or unverified. Screen-specific critique does not yet explain visible UI, persona, task, and remediation. Current row verdict is `fail` with severity `major`. |
| `b25-v4-row-020-book-meeting-rsvp-1` | Neighborhood Book Club | `book-meeting-rsvp` | persona-under-review | B14_ext_book_club_book-meeting-rsvp_action | Persona is generic or missing; the worker cannot know which role this screen serves. Visible text is not proven from screenshot OCR/manual extraction. Primary surface classification is incomplete or unverified. Screen-specific critique does not yet explain visible UI, persona, task, and remediation. Current row verdict is `fail` with severity `major`. |
| `b25-v4-row-021-book-meeting-rsvp-2` | Neighborhood Book Club | `book-meeting-rsvp` | persona-under-review | B14_ext_book_club_book-meeting-rsvp_complete | Persona is generic or missing; the worker cannot know which role this screen serves. Visible text is not proven from screenshot OCR/manual extraction. Primary surface classification is incomplete or unverified. Screen-specific critique does not yet explain visible UI, persona, task, and remediation. Current row verdict is `fail` with severity `major`. |
| `b25-v4-row-022-book-discussion-message-0` | Neighborhood Book Club | `book-discussion-message` | persona-under-review | B14_ext_book_club_book-discussion-message_start | Persona is generic or missing; the worker cannot know which role this screen serves. Visible text is not proven from screenshot OCR/manual extraction. Primary surface classification is incomplete or unverified. Screen-specific critique does not yet explain visible UI, persona, task, and remediation. Current row verdict is `fail` with severity `major`. |
| `b25-v4-row-023-book-discussion-message-1` | Neighborhood Book Club | `book-discussion-message` | persona-under-review | B14_ext_book_club_book-discussion-message_action | Persona is generic or missing; the worker cannot know which role this screen serves. Visible text is not proven from screenshot OCR/manual extraction. Primary surface classification is incomplete or unverified. Screen-specific critique does not yet explain visible UI, persona, task, and remediation. Current row verdict is `fail` with severity `major`. |
| `b25-v4-row-024-book-discussion-message-2` | Neighborhood Book Club | `book-discussion-message` | persona-under-review | B14_ext_book_club_book-discussion-message_complete | Persona is generic or missing; the worker cannot know which role this screen serves. Visible text is not proven from screenshot OCR/manual extraction. Primary surface classification is incomplete or unverified. Screen-specific critique does not yet explain visible UI, persona, task, and remediation. Current row verdict is `fail` with severity `major`. |
| `b25-v4-row-025-book-selection-publish-0` | Neighborhood Book Club | `book-selection-publish` | persona-under-review | B14_ext_book_club_book-selection-publish_start | Persona is generic or missing; the worker cannot know which role this screen serves. Visible text is not proven from screenshot OCR/manual extraction. Primary surface classification is incomplete or unverified. Screen-specific critique does not yet explain visible UI, persona, task, and remediation. Current row verdict is `fail` with severity `major`. |
| `b25-v4-row-026-book-selection-publish-1` | Neighborhood Book Club | `book-selection-publish` | persona-under-review | B14_ext_book_club_book-selection-publish_action | Persona is generic or missing; the worker cannot know which role this screen serves. Visible text is not proven from screenshot OCR/manual extraction. Primary surface classification is incomplete or unverified. Screen-specific critique does not yet explain visible UI, persona, task, and remediation. Current row verdict is `fail` with severity `major`. |
| `b25-v4-row-027-book-selection-publish-2` | Neighborhood Book Club | `book-selection-publish` | persona-under-review | B14_ext_book_club_book-selection-publish_complete | Persona is generic or missing; the worker cannot know which role this screen serves. Visible text is not proven from screenshot OCR/manual extraction. Primary surface classification is incomplete or unverified. Screen-specific critique does not yet explain visible UI, persona, task, and remediation. Current row verdict is `fail` with severity `major`. |
| `b25-v4-row-028-book-search-ai-digest-0` | Neighborhood Book Club | `book-search-ai-digest` | persona-under-review | B14_ext_book_club_book-search-ai-digest_start | Persona is generic or missing; the worker cannot know which role this screen serves. Visible text is not proven from screenshot OCR/manual extraction. Primary surface classification is incomplete or unverified. Screen-specific critique does not yet explain visible UI, persona, task, and remediation. Current row verdict is `fail` with severity `major`. |
| `b25-v4-row-029-book-search-ai-digest-1` | Neighborhood Book Club | `book-search-ai-digest` | persona-under-review | B14_ext_book_club_book-search-ai-digest_action | Persona is generic or missing; the worker cannot know which role this screen serves. Visible text is not proven from screenshot OCR/manual extraction. Primary surface classification is incomplete or unverified. Screen-specific critique does not yet explain visible UI, persona, task, and remediation. Current row verdict is `fail` with severity `major`. |
| `b25-v4-row-030-book-search-ai-digest-2` | Neighborhood Book Club | `book-search-ai-digest` | persona-under-review | B14_ext_book_club_book-search-ai-digest_complete | Persona is generic or missing; the worker cannot know which role this screen serves. Visible text is not proven from screenshot OCR/manual extraction. Primary surface classification is incomplete or unverified. Screen-specific critique does not yet explain visible UI, persona, task, and remediation. Current row verdict is `fail` with severity `major`. |

### Evidence To Update
- independent-production-ux-review.json findings
- product-ux-remediation-loop.md
- b25-iteration-scorecard-latest.json/.md
- Build Tracker.md B25 row and execution ledger
- independent-production-ux-review.json holisticQuestionAnswers
- independent-production-ux-review.md holistic review summary
- product-ux-screen-review-matrix.md relevant screen rows
- production-ux-criteria-scorecard.json/.md
- independent-production-ux-review.json workflowPersonaScorecards
- independent-production-ux-review.json screenRows
- product-ux-screen-review-matrix.md every workflow/persona row
- Updated review JSON, scorecards, screenshots, remediation log, and tracker evidence for the fixed criterion.
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
- Unresolved blocker and major finding counts are both zero.
- `production_ux_judge.dart` has no blocking failure for this criterion.
- `b25_iteration_scorecard.dart` records the ticket as resolved or no longer blocking.
- Screenshots are refreshed and hashes/timestamps/app commit SHA match the reviewed app version.
- Holistic direct-question answers are present, screenshot-backed, non-boilerplate, and pass.
- Every workflow/persona scorecard is present, screenshot-backed, non-boilerplate, and pass.

### Concrete Acceptance Criteria
- Unresolved blocker and major finding counts are both zero.
- `production_ux_judge.dart` has no blocking failure for this criterion.
- `b25_iteration_scorecard.dart` records the ticket as resolved or no longer blocking.
- Screenshots are refreshed and hashes/timestamps/app commit SHA match the reviewed app version.
- Screen row `b25-v4-row-001-workflow-ui-evidence-harness-0` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-001-workflow-ui-evidence-harness-0` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-001-workflow-ui-evidence-harness-0` names visible UI elements, visible text, persona `persona-under-review`, workflow `workflow-ui-evidence-harness`, and the exact product UX issue.
- Primary surface for `workflow-ui-evidence-harness` is documented as `explicit domain-native product surface selected from the B21 production UX contract` or another explicit domain-native surface.
- Fresh screenshot path/hash/timestamp/app commit SHA are recorded after the fix.
- Screen row `b25-v4-row-002-workflow-ui-evidence-harness-1` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-002-workflow-ui-evidence-harness-1` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-002-workflow-ui-evidence-harness-1` names visible UI elements, visible text, persona `persona-under-review`, workflow `workflow-ui-evidence-harness`, and the exact product UX issue.
- Screen row `b25-v4-row-003-workflow-ui-evidence-harness-2` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-003-workflow-ui-evidence-harness-2` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-003-workflow-ui-evidence-harness-2` names visible UI elements, visible text, persona `persona-under-review`, workflow `workflow-ui-evidence-harness`, and the exact product UX issue.
- Screen row `b25-v4-row-004-garden-event-rsvp-0` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-004-garden-event-rsvp-0` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-004-garden-event-rsvp-0` names visible UI elements, visible text, persona `persona-under-review`, workflow `garden-event-rsvp`, and the exact product UX issue.
- Primary surface for `garden-event-rsvp` is documented as `event detail with schedule, location, capacity/status, RSVP action, and result state` or another explicit domain-native surface.
- Screen row `b25-v4-row-005-garden-event-rsvp-1` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-005-garden-event-rsvp-1` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-005-garden-event-rsvp-1` names visible UI elements, visible text, persona `persona-under-review`, workflow `garden-event-rsvp`, and the exact product UX issue.
- Screen row `b25-v4-row-006-garden-event-rsvp-2` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-006-garden-event-rsvp-2` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-006-garden-event-rsvp-2` names visible UI elements, visible text, persona `persona-under-review`, workflow `garden-event-rsvp`, and the exact product UX issue.
- Screen row `b25-v4-row-007-plant-exchange-submission-0` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-007-plant-exchange-submission-0` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-007-plant-exchange-submission-0` names visible UI elements, visible text, persona `persona-under-review`, workflow `plant-exchange-submission`, and the exact product UX issue.
- Primary surface for `plant-exchange-submission` is documented as `explicit domain-native product surface selected from the B21 production UX contract` or another explicit domain-native surface.
- Screen row `b25-v4-row-008-plant-exchange-submission-1` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-008-plant-exchange-submission-1` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-008-plant-exchange-submission-1` names visible UI elements, visible text, persona `persona-under-review`, workflow `plant-exchange-submission`, and the exact product UX issue.
- Screen row `b25-v4-row-009-plant-exchange-submission-2` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-009-plant-exchange-submission-2` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-009-plant-exchange-submission-2` names visible UI elements, visible text, persona `persona-under-review`, workflow `plant-exchange-submission`, and the exact product UX issue.
- Screen row `b25-v4-row-010-garden-export-custom-schemas-0` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-010-garden-export-custom-schemas-0` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-010-garden-export-custom-schemas-0` names visible UI elements, visible text, persona `persona-under-review`, workflow `garden-export-custom-schemas`, and the exact product UX issue.
- Primary surface for `garden-export-custom-schemas` is documented as `export/import wizard with preview, redaction, checksum, transfer status, and rollback state` or another explicit domain-native surface.
- Screen row `b25-v4-row-011-garden-export-custom-schemas-1` has a specific persona/personaId, not `persona-under-review`.

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
- Evidence repair work items must be completed and rerun before UI remediation work items for the same community/workflow/persona are assigned.
- UI remediation work must be scoped by community/workflow/persona and target production surface, not by a broad global ticket summary.
- The independent judge must rerun after each batch that changes UI, evidence, or critique.
- No next UX feedback loop starts until the current remediation iteration is committed.
