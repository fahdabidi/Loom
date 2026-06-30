# B25 Remediation Plan

| Field | Value |
| --- | --- |
| Review run | `b25-v4-pass-19` |
| Status | `open` |
| Source tickets | `../docs/Build Plan V2/Evidence/B25/b25-remediation-tickets-b25-v4-pass-19.json` |
| Ticket count | 8 |
| Scorecard status | `fail` |
| Remaining blocker/major | 3 |
| Blocking criteria failures | 8 |
| Product spec work items | 0 |
| Evidence repair work items | 11 |
| UI remediation work items | 44 |
| Work item sequencing | Product-spec work items must close first, then evidence repair work items, then matching UI remediation work items. |

## Source Tickets

| Ticket | Source criterion | Severity | Status | Title |
| --- | --- | --- | --- | --- |
| `B25-RT-001-b25-c01-no-blocker-major` | `b25-c01-no-blocker-major` | major | open | No unresolved blocker or major findings |
| `B25-RT-002-b25-c03-production-grade-experience` | `b25-c03-production-grade-experience` | major | open | Reviewer can state the experience feels production-grade |
| `B25-RT-003-b25-c14-llm-vision-ux-review` | `b25-c14-llm-vision-ux-review` | major | open | LLM vision UX judge has inspected screenshots semantically |
| `B25-RT-004-b25-c04-modern-intentional-ui` | `b25-c04-modern-intentional-ui` | major | open | UI looks modern and intentionally designed |
| `B25-RT-005-b25-c05-community-content-ia` | `b25-c05-community-content-ia` | major | open | Screens are organized around community content and jobs-to-be-done |
| `B25-RT-006-b25-c06-domain-native-primary-surfaces` | `b25-c06-domain-native-primary-surfaces` | major | open | Primary workflows use domain-specific product surfaces |
| `B25-RT-007-b25-c08-visible-text-specific-critique` | `b25-c08-visible-text-specific-critique` | major | open | Every row has visible text and screen-specific critique |
| `B25-RT-008-b25-c09-no-layout-production-defects` | `b25-c09-no-layout-production-defects` | major | open | No blocking or major layout/content defects remain |

## B25-RB-001-independent-review-evidence: Complete independent review evidence and critique

Turn captured screenshots into complete independent UX review evidence before attempting UI remediation.

| Field | Value |
| --- | --- |
| Status | open |
| Ticket IDs | B25-RT-002-b25-c03-production-grade-experience, B25-RT-004-b25-c04-modern-intentional-ui, B25-RT-007-b25-c08-visible-text-specific-critique, B25-RT-008-b25-c09-no-layout-production-defects |

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
| Event detail and RSVP flow | Material cards/lists/buttons / pattern | https://m3.material.io/components/cards/overview<br>Also: https://m3.material.io/components/buttons/overview<br>https://m3.material.io/components/chips/overview | Copy an event detail layout: title, date/time, location, host, capacity/status chip, attendee context, RSVP action, and confirmation state. |
| Feed item and composer pattern | Material cards/lists/text fields / pattern | https://m3.material.io/components/text-fields/overview<br>Also: https://m3.material.io/components/cards/overview<br>https://m3.material.io/components/lists/overview | Copy a feed/composer structure: audience, author, timestamp, body, attachments/status, publish action, and receiver read state. |
| Search and result list pattern | Material Design 3 / design-system | https://m3.material.io/components/search/overview<br>Also: https://m3.material.io/components/lists/overview | Copy a search layout with query, filters, ranked results, citations/sources, empty/error states, and follow-up actions. |
| Task list and export wizard | GOV.UK Design System / design-system | https://design-system.service.gov.uk/components/task-list/<br>Also: https://design-system.service.gov.uk/patterns/check-answers/ | Copy a wizard with steps, preview, redaction choices, checksum evidence, transfer status, and rollback confirmation. |
| Form validation and review pattern | U.S. Web Design System / design-system | https://designsystem.digital.gov/components/form/<br>Also: https://designsystem.digital.gov/components/alert/<br>https://design-system.service.gov.uk/components/error-summary/ | Copy a form flow with field labels, helper text, validation errors, review state, submit action, status, and protected-data treatment. |
| Roster/list with protected details | Material Design 3 / design-system | https://m3.material.io/components/data-tables/overview<br>Also: https://m3.material.io/components/lists/overview | Copy a roster with member names, roles, status, role-filtered fields, and clear protected-data redaction. |
| Material detail surface composition | Material Design 3 / design-system | https://m3.material.io/components/cards/overview | Build a domain detail page with primary content, metadata, status, and actions instead of a generic task card. |
| Review-and-confirm payment flow | GOV.UK Design System / design-system | https://design-system.service.gov.uk/patterns/check-answers/ | Use a review/confirmation step with amount, payer context, recipient, fees or entitlement, receipt, and audit trail. |
| Multi-step payment/progress flow | U.S. Web Design System / design-system | https://designsystem.digital.gov/components/step-indicator/ | Use explicit progress states for checkout, review, confirmation, receipt, and entitlement/status. |
| Document list/detail pattern | Material lists/cards / pattern | https://m3.material.io/components/lists/overview | Copy a document library with title, category, audience, file metadata, access state, download/view action, and empty/error states. |
| Reservation detail and availability flow | Material cards/forms / pattern | https://m3.material.io/components/date-pickers/overview<br>Also: https://m3.material.io/components/cards/overview | Copy an availability/reservation flow with facility details, date/time, capacity/rules, payment/status when needed, and confirmation. |
| Match schedule and result pattern | Material lists/cards / pattern | https://m3.material.io/components/lists/overview | Copy a match surface with players, schedule/round, result entry, result state, and next action. |
| Inbox and message thread pattern | Material lists/text fields / pattern | https://m3.material.io/components/lists/overview<br>Also: https://m3.material.io/components/text-fields/overview | Copy an inbox/thread structure: sender, timestamp, message preview/body, reply field, invite/block state, and read/received state. |
| Screenshot-first critique method | B25 production UX gate / methodology | docs/Build Plan V2/Tools/b25-remediation-ticket-template.md | Critique must quote visible UI/text, name the persona and task, compare against the chosen reference pattern, and state the exact fix. |

### Reference Research Queries
- production mobile UX review screenshot critique examples
- open source Flutter mobile app UX patterns GitHub
- open source Flutter event-rsvp mobile UI example GitHub
- event detail with schedule, location, capacity/status, RSVP action, and result state mobile UX pattern
- Material Design event detail with schedule, location, capacity/status, RSVP action, and result state mobile pattern
- open source Flutter announcement-feed mobile UI example GitHub
- announcement feed/composer with audience, author, timestamp, body, and receiver state mobile UX pattern
- Material Design announcement feed/composer with audience, author, timestamp, body, and receiver state mobile pattern
- open source Flutter search-results mobile UI example GitHub
- search/AI answer surface with query, result, citation, source, and follow-up action mobile UX pattern
- Material Design search/AI answer surface with query, result, citation, source, and follow-up action mobile pattern
- open source Flutter export-wizard mobile UI example GitHub
- export/import wizard with preview, redaction, checksum, transfer status, and rollback state mobile UX pattern
- Material Design export/import wizard with preview, redaction, checksum, transfer status, and rollback state mobile pattern
- open source Flutter form-review mobile UI example GitHub
- request detail and admin review queue with submitted data, decision action, status, and notification mobile UX pattern
- Material Design request detail and admin review queue with submitted data, decision action, status, and notification mobile pattern
- government design system request detail and admin review queue with submitted data, decision action, status, and notification form review confirmation pattern
- open source Flutter roster-list mobile UI example GitHub
- team roster/schedule surface with role-filtered member details and protected-data treatment mobile UX pattern

### Evidence Repair Work Items

Showing 11 of 11 work items. Full detail is in the JSON artifact.

| Work item | Stage | Community | Workflow | Persona | Screens | Coverage | Target surface | Blocked until |
| --- | --- | --- | --- | --- | ---: | ---: | --- | --- |
| `b25-wi-evidence-repair-community-book-club-book-search-ai-digest-community-book-club-member` | `evidence-repair` | Neighborhood Book Club | `book-search-ai-digest` | member | 3 | 1 | search/AI answer surface with query, result, citation, source, and follow-up action |  |
| `b25-wi-evidence-repair-community-youth-soccer-soccer-guardian-join-approval-community-youth-soccer-guardian` | `evidence-repair` | Riverside Youth Soccer | `soccer-guardian-join-approval` | guardian | 3 | 1 | request detail and admin review queue with submitted data, decision action, status, and notification |  |
| `b25-wi-evidence-repair-community-youth-soccer-soccer-team-roster-community-youth-soccer-coach` | `evidence-repair` | Riverside Youth Soccer | `soccer-team-roster` | coach | 3 | 1 | team roster/schedule surface with role-filtered member details and protected-data treatment |  |
| `b25-wi-evidence-repair-community-hoa-hoa-dues-payment-community-hoa-member` | `evidence-repair` | Cedar Commons HOA | `hoa-dues-payment` | member | 3 | 1 | payment or donation flow with amount, payer context, receipt, entitlement/status, and audit trail |  |
| `b25-wi-evidence-repair-community-hoa-hoa-member-document-community-hoa-member` | `evidence-repair` | Cedar Commons HOA | `hoa-member-document` | member | 3 | 1 | document library/detail surface with title, audience, file metadata, and access state |  |
| `b25-wi-evidence-repair-community-hoa-hoa-facility-reservation-community-hoa-member` | `evidence-repair` | Cedar Commons HOA | `hoa-facility-reservation` | member | 3 | 1 | facility detail/reservation flow with availability, payment/status, and confirmation |  |
| `b25-wi-evidence-repair-community-hoa-hoa-architectural-request-community-hoa-owner` | `evidence-repair` | Cedar Commons HOA | `hoa-architectural-request` | owner | 3 | 1 | request detail and admin review queue with submitted data, decision action, status, and notification |  |
| `b25-wi-evidence-repair-community-platform-social-platform-in-stream-ad-community-platform-social-member` | `evidence-repair` | Member Social Space | `platform-in-stream-ad` | member | 3 | 1 | community feed surface with clearly labeled in-stream ad placement, disclosure, content context, and no-blocking interaction state |  |
| `b25-wi-evidence-repair-community-export-migration-export-import-preview-community-export-migration-owner` | `evidence-repair` | Data Portability Community | `export-import-preview` | owner | 3 | 1 | export/import wizard with preview, redaction, checksum, transfer status, and rollback state |  |
| `b25-wi-evidence-repair-community-export-migration-export-full-bundle-community-export-migration-owner` | `evidence-repair` | Data Portability Community | `export-full-bundle` | owner | 3 | 1 | export/import wizard with preview, redaction, checksum, transfer status, and rollback state |  |
| `b25-wi-evidence-repair-persona-role-inventory-wf-persona-role-inventory-capability-matrix-persona-role-inventory-admin` | `evidence-repair` | persona-role-inventory | `wf_persona-role-inventory-capability-matrix` | admin | 1 | 1 | persona capability matrix surface with roles, allowed actions, receiver states, and denied/hidden behavior |  |

### Evidence Repair Work Items Reference Patterns

| Reference | Source | URL | What to copy |
| --- | --- | --- | --- |
| Search and result list pattern | Material Design 3 / design-system | https://m3.material.io/components/search/overview<br>Also: https://m3.material.io/components/lists/overview | Copy a search layout with query, filters, ranked results, citations/sources, empty/error states, and follow-up actions. |
| Material Design cards and lists | Material Design 3 / design-system | https://m3.material.io/components/cards/overview<br>Also: https://m3.material.io/components/lists/overview | Use cards/lists only as scannable containers with clear hierarchy, content, metadata, and actions. Do not use repeated cards as the whole primary workflow. |
| Flutter sample app implementation patterns | flutter/samples / open-source | https://github.com/flutter/samples | Copy the separation between app shell, route state, domain widgets, and testable UI states rather than hardcoding a single generic renderer. |
| Material navigation and information architecture | Material Design 3 / design-system | https://m3.material.io/components/navigation-drawer/overview<br>Also: https://m3.material.io/components/navigation-bar/overview | Organize screens by user jobs and destinations; keep primary actions visible and avoid exposing implementation taxonomy. |
| Apple HIG navigation and content organization | Apple Human Interface Guidelines / design-system | https://developer.apple.com/design/human-interface-guidelines/navigation | Make navigation predictable, content-centered, and appropriate for the user’s current task. |
| Form validation and review pattern | U.S. Web Design System / design-system | https://designsystem.digital.gov/components/form/<br>Also: https://designsystem.digital.gov/components/alert/<br>https://design-system.service.gov.uk/components/error-summary/ | Copy a form flow with field labels, helper text, validation errors, review state, submit action, status, and protected-data treatment. |
| Roster/list with protected details | Material Design 3 / design-system | https://m3.material.io/components/data-tables/overview<br>Also: https://m3.material.io/components/lists/overview | Copy a roster with member names, roles, status, role-filtered fields, and clear protected-data redaction. |
| Review-and-confirm payment flow | GOV.UK Design System / design-system | https://design-system.service.gov.uk/patterns/check-answers/ | Use a review/confirmation step with amount, payer context, recipient, fees or entitlement, receipt, and audit trail. |
| Multi-step payment/progress flow | U.S. Web Design System / design-system | https://designsystem.digital.gov/components/step-indicator/ | Use explicit progress states for checkout, review, confirmation, receipt, and entitlement/status. |
| Document list/detail pattern | Material lists/cards / pattern | https://m3.material.io/components/lists/overview | Copy a document library with title, category, audience, file metadata, access state, download/view action, and empty/error states. |
| Reservation detail and availability flow | Material cards/forms / pattern | https://m3.material.io/components/date-pickers/overview<br>Also: https://m3.material.io/components/cards/overview | Copy an availability/reservation flow with facility details, date/time, capacity/rules, payment/status when needed, and confirmation. |
| Material detail surface composition | Material Design 3 / design-system | https://m3.material.io/components/cards/overview | Build a domain detail page with primary content, metadata, status, and actions instead of a generic task card. |

### Affected Coverage Rows

Showing 11 of 11 affected coverage rows.

| Coverage row | Community | Workflow | Persona | Missing evidence |
| --- | --- | --- | --- | --- |
| `b25-wp-009-book-search-ai-digest-community-book-club-member` | Neighborhood Book Club | `book-search-ai-digest` | member |  |
| `b25-wp-011-soccer-guardian-join-approval-community-youth-soccer-guardian` | Riverside Youth Soccer | `soccer-guardian-join-approval` | guardian |  |
| `b25-wp-012-soccer-team-roster-community-youth-soccer-coach` | Riverside Youth Soccer | `soccer-team-roster` | coach |  |
| `b25-wp-018-hoa-dues-payment-community-hoa-member` | Cedar Commons HOA | `hoa-dues-payment` | member |  |
| `b25-wp-019-hoa-member-document-community-hoa-member` | Cedar Commons HOA | `hoa-member-document` | member |  |
| `b25-wp-020-hoa-facility-reservation-community-hoa-member` | Cedar Commons HOA | `hoa-facility-reservation` | member |  |
| `b25-wp-021-hoa-architectural-request-community-hoa-owner` | Cedar Commons HOA | `hoa-architectural-request` | owner |  |
| `b25-wp-044-platform-in-stream-ad-community-platform-social-member` | Member Social Space | `platform-in-stream-ad` | member |  |
| `b25-wp-053-export-import-preview-community-export-migration-owner` | Data Portability Community | `export-import-preview` | owner |  |
| `b25-wp-057-export-full-bundle-community-export-migration-owner` | Data Portability Community | `export-full-bundle` | owner |  |
| `b25-wp-062-wf-persona-role-inventory-capability-matrix-persona-role-inventory-admin` | persona-role-inventory | `wf_persona-role-inventory-capability-matrix` | admin |  |

### Affected Screen Rows

Showing 30 of 92 affected screen rows.

| Screen row | Community | Workflow | Persona | State | Exact UX failure |
| --- | --- | --- | --- | --- | --- |
| `b25-v4-row-002-garden-event-rsvp-1` | Garden Club | `garden-event-rsvp` | member | B13_ext_garden_club_garden-event-rsvp_action | LLM vision critique: This row is materially closer to a production product surface than the generic action templates because the user can understand the specific event, shift, or announcement context from visible content. |
| `b25-v4-row-022-book-selection-publish-0` | Neighborhood Book Club | `book-selection-publish` | owner | B14_ext_book_club_book-selection-publish_start | No row-specific failure recorded. |
| `b25-v4-row-024-book-selection-publish-2` | Neighborhood Book Club | `book-selection-publish` | owner | B14_ext_book_club_book-selection-publish_complete | No row-specific failure recorded. |
| `b25-v4-row-025-book-search-ai-digest-0` | Neighborhood Book Club | `book-search-ai-digest` | member | B14_ext_book_club_book-search-ai-digest_start | No row-specific failure recorded. |
| `b25-v4-row-026-book-search-ai-digest-1` | Neighborhood Book Club | `book-search-ai-digest` | member | B14_ext_book_club_book-search-ai-digest_action | LLM vision critique: The screen still reads as a reusable workflow/action template rather than a finished community-specific product surface. The visible copy explains the framework or a generic decision state instead of showing the concrete object, domain data, and natural next actions for this workflow. LLM required fix: Replace generic surface copy and repeated decision/details blocks with a domain-specific layout for this workflow: concrete title/object, real fields/content, primary and alternate actions, persistent result state, and receiver/next-step state visible in the screenshot. Current row verdict is `fail` with severity `major`. |
| `b25-v4-row-027-book-search-ai-digest-2` | Neighborhood Book Club | `book-search-ai-digest` | member | B14_ext_book_club_book-search-ai-digest_complete | No row-specific failure recorded. |
| `b25-v4-row-029-book-export-metadata-1` | Neighborhood Book Club | `book-export-metadata` | owner | B14_ext_book_club_book-export-metadata_action | No row-specific failure recorded. |
| `b25-v4-row-031-soccer-guardian-join-approval-0` | Riverside Youth Soccer | `soccer-guardian-join-approval` | guardian | B14_ext_youth_soccer_soccer-guardian-join-approval_start | No row-specific failure recorded. |
| `b25-v4-row-032-soccer-guardian-join-approval-1` | Riverside Youth Soccer | `soccer-guardian-join-approval` | guardian | B14_ext_youth_soccer_soccer-guardian-join-approval_action | LLM vision critique: The screen still reads as a reusable workflow/action template rather than a finished community-specific product surface. The visible copy explains the framework or a generic decision state instead of showing the concrete object, domain data, and natural next actions for this workflow. LLM required fix: Replace generic surface copy and repeated decision/details blocks with a domain-specific layout for this workflow: concrete title/object, real fields/content, primary and alternate actions, persistent result state, and receiver/next-step state visible in the screenshot. Current row verdict is `fail` with severity `major`. |
| `b25-v4-row-033-soccer-guardian-join-approval-2` | Riverside Youth Soccer | `soccer-guardian-join-approval` | guardian | B14_ext_youth_soccer_soccer-guardian-join-approval_complete | No row-specific failure recorded. |
| `b25-v4-row-034-soccer-team-roster-0` | Riverside Youth Soccer | `soccer-team-roster` | coach | B14_ext_youth_soccer_soccer-team-roster_start | No row-specific failure recorded. |
| `b25-v4-row-035-soccer-team-roster-1` | Riverside Youth Soccer | `soccer-team-roster` | coach | B14_ext_youth_soccer_soccer-team-roster_action | LLM vision critique: The screen still reads as a reusable workflow/action template rather than a finished community-specific product surface. The visible copy explains the framework or a generic decision state instead of showing the concrete object, domain data, and natural next actions for this workflow. LLM required fix: Replace generic surface copy and repeated decision/details blocks with a domain-specific layout for this workflow: concrete title/object, real fields/content, primary and alternate actions, persistent result state, and receiver/next-step state visible in the screenshot. Current row verdict is `fail` with severity `major`. |
| `b25-v4-row-036-soccer-team-roster-2` | Riverside Youth Soccer | `soccer-team-roster` | coach | B14_ext_youth_soccer_soccer-team-roster_complete | No row-specific failure recorded. |
| `b25-v4-row-037-soccer-minor-redaction-0` | Riverside Youth Soccer | `soccer-minor-redaction` | guardian | B14_ext_youth_soccer_soccer-minor-redaction_start | No row-specific failure recorded. |
| `b25-v4-row-038-soccer-minor-redaction-1` | Riverside Youth Soccer | `soccer-minor-redaction` | guardian | B14_ext_youth_soccer_soccer-minor-redaction_action | No row-specific failure recorded. |
| `b25-v4-row-039-soccer-minor-redaction-2` | Riverside Youth Soccer | `soccer-minor-redaction` | guardian | B14_ext_youth_soccer_soccer-minor-redaction_complete | No row-specific failure recorded. |
| `b25-v4-row-041-soccer-registration-payment-1` | Riverside Youth Soccer | `soccer-registration-payment` | guardian | B14_ext_youth_soccer_soccer-registration-payment_action | No row-specific failure recorded. |
| `b25-v4-row-044-soccer-practice-schedule-1` | Riverside Youth Soccer | `soccer-practice-schedule` | guardian | B14_ext_youth_soccer_soccer-practice-schedule_action | No row-specific failure recorded. |
| `b25-v4-row-046-soccer-reminder-notification-0` | Riverside Youth Soccer | `soccer-reminder-notification` | guardian | B14_ext_youth_soccer_soccer-reminder-notification_start | No row-specific failure recorded. |
| `b25-v4-row-047-soccer-reminder-notification-1` | Riverside Youth Soccer | `soccer-reminder-notification` | guardian | B14_ext_youth_soccer_soccer-reminder-notification_action | No row-specific failure recorded. |
| `b25-v4-row-048-soccer-reminder-notification-2` | Riverside Youth Soccer | `soccer-reminder-notification` | guardian | B14_ext_youth_soccer_soccer-reminder-notification_complete | No row-specific failure recorded. |
| `b25-v4-row-049-soccer-export-metadata-0` | Riverside Youth Soccer | `soccer-export-metadata` | owner | B14_ext_youth_soccer_soccer-export-metadata_start | No row-specific failure recorded. |
| `b25-v4-row-050-soccer-export-metadata-1` | Riverside Youth Soccer | `soccer-export-metadata` | owner | B14_ext_youth_soccer_soccer-export-metadata_action | No row-specific failure recorded. |
| `b25-v4-row-051-soccer-export-metadata-2` | Riverside Youth Soccer | `soccer-export-metadata` | owner | B14_ext_youth_soccer_soccer-export-metadata_complete | No row-specific failure recorded. |
| `b25-v4-row-052-hoa-dues-payment-0` | Cedar Commons HOA | `hoa-dues-payment` | member | B14_ext_hoa_hoa-dues-payment_start | No row-specific failure recorded. |
| `b25-v4-row-053-hoa-dues-payment-1` | Cedar Commons HOA | `hoa-dues-payment` | member | B14_ext_hoa_hoa-dues-payment_action | LLM vision critique: The screen still reads as a reusable workflow/action template rather than a finished community-specific product surface. The visible copy explains the framework or a generic decision state instead of showing the concrete object, domain data, and natural next actions for this workflow. LLM required fix: Replace generic surface copy and repeated decision/details blocks with a domain-specific layout for this workflow: concrete title/object, real fields/content, primary and alternate actions, persistent result state, and receiver/next-step state visible in the screenshot. Current row verdict is `fail` with severity `major`. |
| `b25-v4-row-054-hoa-dues-payment-2` | Cedar Commons HOA | `hoa-dues-payment` | member | B14_ext_hoa_hoa-dues-payment_complete | No row-specific failure recorded. |
| `b25-v4-row-056-hoa-member-document-1` | Cedar Commons HOA | `hoa-member-document` | member | B14_ext_hoa_hoa-member-document_action | LLM vision critique: The screen still reads as a reusable workflow/action template rather than a finished community-specific product surface. The visible copy explains the framework or a generic decision state instead of showing the concrete object, domain data, and natural next actions for this workflow. LLM required fix: Replace generic surface copy and repeated decision/details blocks with a domain-specific layout for this workflow: concrete title/object, real fields/content, primary and alternate actions, persistent result state, and receiver/next-step state visible in the screenshot. Current row verdict is `fail` with severity `major`. |
| `b25-v4-row-058-hoa-facility-reservation-0` | Cedar Commons HOA | `hoa-facility-reservation` | member | B14_ext_hoa_hoa-facility-reservation_start | No row-specific failure recorded. |
| `b25-v4-row-059-hoa-facility-reservation-1` | Cedar Commons HOA | `hoa-facility-reservation` | member | B14_ext_hoa_hoa-facility-reservation_action | LLM vision critique: The screen still reads as a reusable workflow/action template rather than a finished community-specific product surface. The visible copy explains the framework or a generic decision state instead of showing the concrete object, domain data, and natural next actions for this workflow. LLM required fix: Replace generic surface copy and repeated decision/details blocks with a domain-specific layout for this workflow: concrete title/object, real fields/content, primary and alternate actions, persistent result state, and receiver/next-step state visible in the screenshot. Current row verdict is `fail` with severity `major`. |

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
- `llmVisionReview` imported from a fresh LLM vision UX judge run against the after screenshots.
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
- Screen row `b25-v4-row-002-garden-event-rsvp-1` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-002-garden-event-rsvp-1` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-002-garden-event-rsvp-1` names visible UI elements, visible text, persona `member`, workflow `garden-event-rsvp`, and the exact product UX issue.
- Primary surface for `garden-event-rsvp` is documented as `event detail with schedule, location, capacity/status, RSVP action, and result state` or another explicit domain-native surface.
- After-screenshot visible text proves every required semantic surface group for `garden-event-rsvp`.
- Fresh screenshot path/hash/timestamp/app commit SHA are recorded after the fix.
- Screen row `b25-v4-row-022-book-selection-publish-0` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-022-book-selection-publish-0` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-022-book-selection-publish-0` names visible UI elements, visible text, persona `owner`, workflow `book-selection-publish`, and the exact product UX issue.
- Primary surface for `book-selection-publish` is documented as `announcement feed/composer with audience, author, timestamp, body, and receiver state` or another explicit domain-native surface.
- After-screenshot visible text proves every required semantic surface group for `book-selection-publish`.
- Screen row `b25-v4-row-024-book-selection-publish-2` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-024-book-selection-publish-2` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-024-book-selection-publish-2` names visible UI elements, visible text, persona `owner`, workflow `book-selection-publish`, and the exact product UX issue.
- Screen row `b25-v4-row-025-book-search-ai-digest-0` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-025-book-search-ai-digest-0` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-025-book-search-ai-digest-0` names visible UI elements, visible text, persona `member`, workflow `book-search-ai-digest`, and the exact product UX issue.
- Primary surface for `book-search-ai-digest` is documented as `search/AI answer surface with query, result, citation, source, and follow-up action` or another explicit domain-native surface.
- After-screenshot visible text proves every required semantic surface group for `book-search-ai-digest`.
- Screen row `b25-v4-row-026-book-search-ai-digest-1` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-026-book-search-ai-digest-1` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-026-book-search-ai-digest-1` names visible UI elements, visible text, persona `member`, workflow `book-search-ai-digest`, and the exact product UX issue.
- Screen row `b25-v4-row-027-book-search-ai-digest-2` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-027-book-search-ai-digest-2` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-027-book-search-ai-digest-2` names visible UI elements, visible text, persona `member`, workflow `book-search-ai-digest`, and the exact product UX issue.
- Screen row `b25-v4-row-029-book-export-metadata-1` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-029-book-export-metadata-1` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-029-book-export-metadata-1` names visible UI elements, visible text, persona `owner`, workflow `book-export-metadata`, and the exact product UX issue.
- Primary surface for `book-export-metadata` is documented as `export/import wizard with preview, redaction, checksum, transfer status, and rollback state` or another explicit domain-native surface.
- After-screenshot visible text proves every required semantic surface group for `book-export-metadata`.
- Screen row `b25-v4-row-031-soccer-guardian-join-approval-0` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-031-soccer-guardian-join-approval-0` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-031-soccer-guardian-join-approval-0` names visible UI elements, visible text, persona `guardian`, workflow `soccer-guardian-join-approval`, and the exact product UX issue.
- Primary surface for `soccer-guardian-join-approval` is documented as `request detail and admin review queue with submitted data, decision action, status, and notification` or another explicit domain-native surface.
- After-screenshot visible text proves every required semantic surface group for `soccer-guardian-join-approval`.
- Screen row `b25-v4-row-032-soccer-guardian-join-approval-1` has a specific persona/personaId, not `persona-under-review`.

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

## B25-RB-002-domain-native-ux-remediation: Remediate domain-native IA and primary workflow surfaces

Apply product UX fixes found by the independent critique so primary screens feel like production community surfaces.

| Field | Value |
| --- | --- |
| Status | open |
| Ticket IDs | B25-RT-004-b25-c04-modern-intentional-ui, B25-RT-005-b25-c05-community-content-ia, B25-RT-006-b25-c06-domain-native-primary-surfaces, B25-RT-008-b25-c09-no-layout-production-defects |

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
| Event detail and RSVP flow | Material cards/lists/buttons / pattern | https://m3.material.io/components/cards/overview<br>Also: https://m3.material.io/components/buttons/overview<br>https://m3.material.io/components/chips/overview | Copy an event detail layout: title, date/time, location, host, capacity/status chip, attendee context, RSVP action, and confirmation state. |
| Feed item and composer pattern | Material cards/lists/text fields / pattern | https://m3.material.io/components/text-fields/overview<br>Also: https://m3.material.io/components/cards/overview<br>https://m3.material.io/components/lists/overview | Copy a feed/composer structure: audience, author, timestamp, body, attachments/status, publish action, and receiver read state. |
| Search and result list pattern | Material Design 3 / design-system | https://m3.material.io/components/search/overview<br>Also: https://m3.material.io/components/lists/overview | Copy a search layout with query, filters, ranked results, citations/sources, empty/error states, and follow-up actions. |
| Task list and export wizard | GOV.UK Design System / design-system | https://design-system.service.gov.uk/components/task-list/<br>Also: https://design-system.service.gov.uk/patterns/check-answers/ | Copy a wizard with steps, preview, redaction choices, checksum evidence, transfer status, and rollback confirmation. |
| Form validation and review pattern | U.S. Web Design System / design-system | https://designsystem.digital.gov/components/form/<br>Also: https://designsystem.digital.gov/components/alert/<br>https://design-system.service.gov.uk/components/error-summary/ | Copy a form flow with field labels, helper text, validation errors, review state, submit action, status, and protected-data treatment. |
| Roster/list with protected details | Material Design 3 / design-system | https://m3.material.io/components/data-tables/overview<br>Also: https://m3.material.io/components/lists/overview | Copy a roster with member names, roles, status, role-filtered fields, and clear protected-data redaction. |
| Material detail surface composition | Material Design 3 / design-system | https://m3.material.io/components/cards/overview | Build a domain detail page with primary content, metadata, status, and actions instead of a generic task card. |
| Review-and-confirm payment flow | GOV.UK Design System / design-system | https://design-system.service.gov.uk/patterns/check-answers/ | Use a review/confirmation step with amount, payer context, recipient, fees or entitlement, receipt, and audit trail. |
| Multi-step payment/progress flow | U.S. Web Design System / design-system | https://designsystem.digital.gov/components/step-indicator/ | Use explicit progress states for checkout, review, confirmation, receipt, and entitlement/status. |
| Document list/detail pattern | Material lists/cards / pattern | https://m3.material.io/components/lists/overview | Copy a document library with title, category, audience, file metadata, access state, download/view action, and empty/error states. |
| Reservation detail and availability flow | Material cards/forms / pattern | https://m3.material.io/components/date-pickers/overview<br>Also: https://m3.material.io/components/cards/overview | Copy an availability/reservation flow with facility details, date/time, capacity/rules, payment/status when needed, and confirmation. |
| Match schedule and result pattern | Material lists/cards / pattern | https://m3.material.io/components/lists/overview | Copy a match surface with players, schedule/round, result entry, result state, and next action. |
| Inbox and message thread pattern | Material lists/text fields / pattern | https://m3.material.io/components/lists/overview<br>Also: https://m3.material.io/components/text-fields/overview | Copy an inbox/thread structure: sender, timestamp, message preview/body, reply field, invite/block state, and read/received state. |

### Reference Research Queries
- modern mobile app information architecture visual hierarchy examples
- Material Design 3 mobile UI hierarchy navigation cards examples
- open source Flutter production app dashboard detail screen examples
- open source Flutter event-rsvp mobile UI example GitHub
- event detail with schedule, location, capacity/status, RSVP action, and result state mobile UX pattern
- Material Design event detail with schedule, location, capacity/status, RSVP action, and result state mobile pattern
- open source Flutter announcement-feed mobile UI example GitHub
- announcement feed/composer with audience, author, timestamp, body, and receiver state mobile UX pattern
- Material Design announcement feed/composer with audience, author, timestamp, body, and receiver state mobile pattern
- open source Flutter search-results mobile UI example GitHub
- search/AI answer surface with query, result, citation, source, and follow-up action mobile UX pattern
- Material Design search/AI answer surface with query, result, citation, source, and follow-up action mobile pattern
- open source Flutter export-wizard mobile UI example GitHub
- export/import wizard with preview, redaction, checksum, transfer status, and rollback state mobile UX pattern
- Material Design export/import wizard with preview, redaction, checksum, transfer status, and rollback state mobile pattern
- open source Flutter form-review mobile UI example GitHub
- request detail and admin review queue with submitted data, decision action, status, and notification mobile UX pattern
- Material Design request detail and admin review queue with submitted data, decision action, status, and notification mobile pattern
- government design system request detail and admin review queue with submitted data, decision action, status, and notification form review confirmation pattern
- open source Flutter roster-list mobile UI example GitHub

### UI Remediation Work Items

Showing 30 of 44 work items. Full detail is in the JSON artifact.

| Work item | Stage | Community | Workflow | Persona | Screens | Coverage | Target surface | Blocked until |
| --- | --- | --- | --- | --- | ---: | ---: | --- | --- |
| `b25-wi-ui-remediation-community-garden-club-garden-event-rsvp-community-garden-club-member` | `ui-remediation` | Garden Club | `garden-event-rsvp` | member | 1 | 0 | event detail with schedule, location, capacity/status, RSVP action, and result state | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-book-club-book-selection-publish-community-book-club-owner` | `ui-remediation` | Neighborhood Book Club | `book-selection-publish` | owner | 2 | 0 | announcement feed/composer with audience, author, timestamp, body, and receiver state | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-book-club-book-search-ai-digest-community-book-club-member` | `ui-remediation` | Neighborhood Book Club | `book-search-ai-digest` | member | 3 | 1 | search/AI answer surface with query, result, citation, source, and follow-up action | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-book-club-book-export-metadata-community-book-club-owner` | `ui-remediation` | Neighborhood Book Club | `book-export-metadata` | owner | 1 | 0 | export/import wizard with preview, redaction, checksum, transfer status, and rollback state | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-youth-soccer-soccer-guardian-join-approval-community-youth-soccer-guardian` | `ui-remediation` | Riverside Youth Soccer | `soccer-guardian-join-approval` | guardian | 3 | 1 | request detail and admin review queue with submitted data, decision action, status, and notification | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-youth-soccer-soccer-team-roster-community-youth-soccer-coach` | `ui-remediation` | Riverside Youth Soccer | `soccer-team-roster` | coach | 3 | 1 | team roster/schedule surface with role-filtered member details and protected-data treatment | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-youth-soccer-soccer-minor-redaction-community-youth-soccer-guardian` | `ui-remediation` | Riverside Youth Soccer | `soccer-minor-redaction` | guardian | 3 | 0 | protected youth roster/profile surface with minor-data redaction, guardian visibility, and coach-only detail state | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-youth-soccer-soccer-registration-payment-community-youth-soccer-guardian` | `ui-remediation` | Riverside Youth Soccer | `soccer-registration-payment` | guardian | 1 | 0 | payment or donation flow with amount, payer context, receipt, entitlement/status, and audit trail | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-youth-soccer-soccer-practice-schedule-community-youth-soccer-guardian` | `ui-remediation` | Riverside Youth Soccer | `soccer-practice-schedule` | guardian | 1 | 0 | event detail with schedule, location, capacity/status, RSVP action, and result state | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-youth-soccer-soccer-reminder-notification-community-youth-soccer-guardian` | `ui-remediation` | Riverside Youth Soccer | `soccer-reminder-notification` | guardian | 3 | 0 | notification inbox/detail surface with sender, audience, timestamp, message body, and receiver state | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-youth-soccer-soccer-export-metadata-community-youth-soccer-owner` | `ui-remediation` | Riverside Youth Soccer | `soccer-export-metadata` | owner | 3 | 0 | export/import wizard with preview, redaction, checksum, transfer status, and rollback state | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-hoa-hoa-dues-payment-community-hoa-member` | `ui-remediation` | Cedar Commons HOA | `hoa-dues-payment` | member | 3 | 1 | payment or donation flow with amount, payer context, receipt, entitlement/status, and audit trail | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-hoa-hoa-member-document-community-hoa-member` | `ui-remediation` | Cedar Commons HOA | `hoa-member-document` | member | 3 | 1 | document library/detail surface with title, audience, file metadata, and access state | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-hoa-hoa-facility-reservation-community-hoa-member` | `ui-remediation` | Cedar Commons HOA | `hoa-facility-reservation` | member | 3 | 1 | facility detail/reservation flow with availability, payment/status, and confirmation | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-hoa-hoa-architectural-request-community-hoa-owner` | `ui-remediation` | Cedar Commons HOA | `hoa-architectural-request` | owner | 3 | 1 | request detail and admin review queue with submitted data, decision action, status, and notification | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-hoa-hoa-committee-decision-community-hoa-owner` | `ui-remediation` | Cedar Commons HOA | `hoa-committee-decision` | owner | 3 | 0 | request detail and admin review queue with submitted data, decision action, status, and notification | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-hoa-hoa-owner-notification-community-hoa-owner` | `ui-remediation` | Cedar Commons HOA | `hoa-owner-notification` | owner | 3 | 0 | notification inbox/detail surface with sender, audience, timestamp, message body, and receiver state | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-hoa-hoa-export-evidence-community-hoa-owner` | `ui-remediation` | Cedar Commons HOA | `hoa-export-evidence` | owner | 1 | 0 | export/import wizard with preview, redaction, checksum, transfer status, and rollback state | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-mosque-mosque-announcement-community-mosque-owner` | `ui-remediation` | Masjid Nur | `mosque-announcement` | owner | 2 | 0 | announcement feed/composer with audience, author, timestamp, body, and receiver state | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-mosque-mosque-volunteer-signup-community-mosque-member` | `ui-remediation` | Masjid Nur | `mosque-volunteer-signup` | member | 1 | 0 | volunteer signup surface with role, time, protected contact fields, and confirmation | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-mosque-mosque-donor-visibility-community-mosque-donor` | `ui-remediation` | Masjid Nur | `mosque-donor-visibility` | donor | 3 | 0 | donor privacy preference surface with visibility choice, donation context, confirmation, and receipt visibility state | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-mosque-mosque-donation-payment-community-mosque-donor` | `ui-remediation` | Masjid Nur | `mosque-donation-payment` | donor | 1 | 0 | payment or donation flow with amount, payer context, receipt, entitlement/status, and audit trail | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-mosque-mosque-care-request-community-mosque-member` | `ui-remediation` | Masjid Nur | `mosque-care-request` | member | 3 | 0 | protected care request form and private response/status surface | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-mosque-mosque-neutral-notification-community-mosque-member` | `ui-remediation` | Masjid Nur | `mosque-neutral-notification` | member | 3 | 0 | notification inbox/detail surface with sender, audience, timestamp, message body, and receiver state | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-mosque-mosque-search-ai-citation-community-mosque-member` | `ui-remediation` | Masjid Nur | `mosque-search-ai-citation` | member | 3 | 0 | search/AI answer surface with query, result, citation, source, and follow-up action | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-chess-club-chess-local-install-open-community-chess-club-member` | `ui-remediation` | Chess Club | `chess-local-install-open` | member | 1 | 0 | match schedule/result surface with players, round, outcome, and next action | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-chess-club-chess-route-home-community-chess-club-member` | `ui-remediation` | Chess Club | `chess-route-home` | member | 1 | 0 | match schedule/result surface with players, round, outcome, and next action | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-chess-club-chess-match-result-community-chess-club-member` | `ui-remediation` | Chess Club | `chess-match-result` | member | 1 | 0 | match schedule/result surface with players, round, outcome, and next action | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-camera-club-photo-walk-rsvp-community-camera-club-member` | `ui-remediation` | Camera Club | `photo-walk-rsvp` | member | 1 | 0 | event detail with schedule, location, capacity/status, RSVP action, and result state | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-camera-club-critique-submission-community-camera-club-member` | `ui-remediation` | Camera Club | `critique-submission` | member | 1 | 0 | critique submission/review surface with image/work title, comments, reviewer state, and result | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |

### UI Remediation Work Items Reference Patterns

| Reference | Source | URL | What to copy |
| --- | --- | --- | --- |
| Event detail and RSVP flow | Material cards/lists/buttons / pattern | https://m3.material.io/components/cards/overview<br>Also: https://m3.material.io/components/buttons/overview<br>https://m3.material.io/components/chips/overview | Copy an event detail layout: title, date/time, location, host, capacity/status chip, attendee context, RSVP action, and confirmation state. |
| Material Design cards and lists | Material Design 3 / design-system | https://m3.material.io/components/cards/overview<br>Also: https://m3.material.io/components/lists/overview | Use cards/lists only as scannable containers with clear hierarchy, content, metadata, and actions. Do not use repeated cards as the whole primary workflow. |
| Flutter sample app implementation patterns | flutter/samples / open-source | https://github.com/flutter/samples | Copy the separation between app shell, route state, domain widgets, and testable UI states rather than hardcoding a single generic renderer. |
| Material navigation and information architecture | Material Design 3 / design-system | https://m3.material.io/components/navigation-drawer/overview<br>Also: https://m3.material.io/components/navigation-bar/overview | Organize screens by user jobs and destinations; keep primary actions visible and avoid exposing implementation taxonomy. |
| Apple HIG navigation and content organization | Apple Human Interface Guidelines / design-system | https://developer.apple.com/design/human-interface-guidelines/navigation | Make navigation predictable, content-centered, and appropriate for the user’s current task. |
| Feed item and composer pattern | Material cards/lists/text fields / pattern | https://m3.material.io/components/text-fields/overview<br>Also: https://m3.material.io/components/cards/overview<br>https://m3.material.io/components/lists/overview | Copy a feed/composer structure: audience, author, timestamp, body, attachments/status, publish action, and receiver read state. |
| Search and result list pattern | Material Design 3 / design-system | https://m3.material.io/components/search/overview<br>Also: https://m3.material.io/components/lists/overview | Copy a search layout with query, filters, ranked results, citations/sources, empty/error states, and follow-up actions. |
| Task list and export wizard | GOV.UK Design System / design-system | https://design-system.service.gov.uk/components/task-list/<br>Also: https://design-system.service.gov.uk/patterns/check-answers/ | Copy a wizard with steps, preview, redaction choices, checksum evidence, transfer status, and rollback confirmation. |
| Form validation and review pattern | U.S. Web Design System / design-system | https://designsystem.digital.gov/components/form/<br>Also: https://designsystem.digital.gov/components/alert/<br>https://design-system.service.gov.uk/components/error-summary/ | Copy a form flow with field labels, helper text, validation errors, review state, submit action, status, and protected-data treatment. |
| Roster/list with protected details | Material Design 3 / design-system | https://m3.material.io/components/data-tables/overview<br>Also: https://m3.material.io/components/lists/overview | Copy a roster with member names, roles, status, role-filtered fields, and clear protected-data redaction. |
| Material detail surface composition | Material Design 3 / design-system | https://m3.material.io/components/cards/overview | Build a domain detail page with primary content, metadata, status, and actions instead of a generic task card. |
| Review-and-confirm payment flow | GOV.UK Design System / design-system | https://design-system.service.gov.uk/patterns/check-answers/ | Use a review/confirmation step with amount, payer context, recipient, fees or entitlement, receipt, and audit trail. |

### Affected Coverage Rows

Showing 11 of 11 affected coverage rows.

| Coverage row | Community | Workflow | Persona | Missing evidence |
| --- | --- | --- | --- | --- |
| `b25-wp-009-book-search-ai-digest-community-book-club-member` | Neighborhood Book Club | `book-search-ai-digest` | member |  |
| `b25-wp-011-soccer-guardian-join-approval-community-youth-soccer-guardian` | Riverside Youth Soccer | `soccer-guardian-join-approval` | guardian |  |
| `b25-wp-012-soccer-team-roster-community-youth-soccer-coach` | Riverside Youth Soccer | `soccer-team-roster` | coach |  |
| `b25-wp-018-hoa-dues-payment-community-hoa-member` | Cedar Commons HOA | `hoa-dues-payment` | member |  |
| `b25-wp-019-hoa-member-document-community-hoa-member` | Cedar Commons HOA | `hoa-member-document` | member |  |
| `b25-wp-020-hoa-facility-reservation-community-hoa-member` | Cedar Commons HOA | `hoa-facility-reservation` | member |  |
| `b25-wp-021-hoa-architectural-request-community-hoa-owner` | Cedar Commons HOA | `hoa-architectural-request` | owner |  |
| `b25-wp-044-platform-in-stream-ad-community-platform-social-member` | Member Social Space | `platform-in-stream-ad` | member |  |
| `b25-wp-053-export-import-preview-community-export-migration-owner` | Data Portability Community | `export-import-preview` | owner |  |
| `b25-wp-057-export-full-bundle-community-export-migration-owner` | Data Portability Community | `export-full-bundle` | owner |  |
| `b25-wp-062-wf-persona-role-inventory-capability-matrix-persona-role-inventory-admin` | persona-role-inventory | `wf_persona-role-inventory-capability-matrix` | admin |  |

### Affected Screen Rows

Showing 30 of 92 affected screen rows.

| Screen row | Community | Workflow | Persona | State | Exact UX failure |
| --- | --- | --- | --- | --- | --- |
| `b25-v4-row-002-garden-event-rsvp-1` | Garden Club | `garden-event-rsvp` | member | B13_ext_garden_club_garden-event-rsvp_action | LLM vision critique: This row is materially closer to a production product surface than the generic action templates because the user can understand the specific event, shift, or announcement context from visible content. |
| `b25-v4-row-022-book-selection-publish-0` | Neighborhood Book Club | `book-selection-publish` | owner | B14_ext_book_club_book-selection-publish_start | No row-specific failure recorded. |
| `b25-v4-row-024-book-selection-publish-2` | Neighborhood Book Club | `book-selection-publish` | owner | B14_ext_book_club_book-selection-publish_complete | No row-specific failure recorded. |
| `b25-v4-row-025-book-search-ai-digest-0` | Neighborhood Book Club | `book-search-ai-digest` | member | B14_ext_book_club_book-search-ai-digest_start | No row-specific failure recorded. |
| `b25-v4-row-026-book-search-ai-digest-1` | Neighborhood Book Club | `book-search-ai-digest` | member | B14_ext_book_club_book-search-ai-digest_action | LLM vision critique: The screen still reads as a reusable workflow/action template rather than a finished community-specific product surface. The visible copy explains the framework or a generic decision state instead of showing the concrete object, domain data, and natural next actions for this workflow. LLM required fix: Replace generic surface copy and repeated decision/details blocks with a domain-specific layout for this workflow: concrete title/object, real fields/content, primary and alternate actions, persistent result state, and receiver/next-step state visible in the screenshot. Current row verdict is `fail` with severity `major`. |
| `b25-v4-row-027-book-search-ai-digest-2` | Neighborhood Book Club | `book-search-ai-digest` | member | B14_ext_book_club_book-search-ai-digest_complete | No row-specific failure recorded. |
| `b25-v4-row-029-book-export-metadata-1` | Neighborhood Book Club | `book-export-metadata` | owner | B14_ext_book_club_book-export-metadata_action | No row-specific failure recorded. |
| `b25-v4-row-031-soccer-guardian-join-approval-0` | Riverside Youth Soccer | `soccer-guardian-join-approval` | guardian | B14_ext_youth_soccer_soccer-guardian-join-approval_start | No row-specific failure recorded. |
| `b25-v4-row-032-soccer-guardian-join-approval-1` | Riverside Youth Soccer | `soccer-guardian-join-approval` | guardian | B14_ext_youth_soccer_soccer-guardian-join-approval_action | LLM vision critique: The screen still reads as a reusable workflow/action template rather than a finished community-specific product surface. The visible copy explains the framework or a generic decision state instead of showing the concrete object, domain data, and natural next actions for this workflow. LLM required fix: Replace generic surface copy and repeated decision/details blocks with a domain-specific layout for this workflow: concrete title/object, real fields/content, primary and alternate actions, persistent result state, and receiver/next-step state visible in the screenshot. Current row verdict is `fail` with severity `major`. |
| `b25-v4-row-033-soccer-guardian-join-approval-2` | Riverside Youth Soccer | `soccer-guardian-join-approval` | guardian | B14_ext_youth_soccer_soccer-guardian-join-approval_complete | No row-specific failure recorded. |
| `b25-v4-row-034-soccer-team-roster-0` | Riverside Youth Soccer | `soccer-team-roster` | coach | B14_ext_youth_soccer_soccer-team-roster_start | No row-specific failure recorded. |
| `b25-v4-row-035-soccer-team-roster-1` | Riverside Youth Soccer | `soccer-team-roster` | coach | B14_ext_youth_soccer_soccer-team-roster_action | LLM vision critique: The screen still reads as a reusable workflow/action template rather than a finished community-specific product surface. The visible copy explains the framework or a generic decision state instead of showing the concrete object, domain data, and natural next actions for this workflow. LLM required fix: Replace generic surface copy and repeated decision/details blocks with a domain-specific layout for this workflow: concrete title/object, real fields/content, primary and alternate actions, persistent result state, and receiver/next-step state visible in the screenshot. Current row verdict is `fail` with severity `major`. |
| `b25-v4-row-036-soccer-team-roster-2` | Riverside Youth Soccer | `soccer-team-roster` | coach | B14_ext_youth_soccer_soccer-team-roster_complete | No row-specific failure recorded. |
| `b25-v4-row-037-soccer-minor-redaction-0` | Riverside Youth Soccer | `soccer-minor-redaction` | guardian | B14_ext_youth_soccer_soccer-minor-redaction_start | No row-specific failure recorded. |
| `b25-v4-row-038-soccer-minor-redaction-1` | Riverside Youth Soccer | `soccer-minor-redaction` | guardian | B14_ext_youth_soccer_soccer-minor-redaction_action | No row-specific failure recorded. |
| `b25-v4-row-039-soccer-minor-redaction-2` | Riverside Youth Soccer | `soccer-minor-redaction` | guardian | B14_ext_youth_soccer_soccer-minor-redaction_complete | No row-specific failure recorded. |
| `b25-v4-row-041-soccer-registration-payment-1` | Riverside Youth Soccer | `soccer-registration-payment` | guardian | B14_ext_youth_soccer_soccer-registration-payment_action | No row-specific failure recorded. |
| `b25-v4-row-044-soccer-practice-schedule-1` | Riverside Youth Soccer | `soccer-practice-schedule` | guardian | B14_ext_youth_soccer_soccer-practice-schedule_action | No row-specific failure recorded. |
| `b25-v4-row-046-soccer-reminder-notification-0` | Riverside Youth Soccer | `soccer-reminder-notification` | guardian | B14_ext_youth_soccer_soccer-reminder-notification_start | No row-specific failure recorded. |
| `b25-v4-row-047-soccer-reminder-notification-1` | Riverside Youth Soccer | `soccer-reminder-notification` | guardian | B14_ext_youth_soccer_soccer-reminder-notification_action | No row-specific failure recorded. |
| `b25-v4-row-048-soccer-reminder-notification-2` | Riverside Youth Soccer | `soccer-reminder-notification` | guardian | B14_ext_youth_soccer_soccer-reminder-notification_complete | No row-specific failure recorded. |
| `b25-v4-row-049-soccer-export-metadata-0` | Riverside Youth Soccer | `soccer-export-metadata` | owner | B14_ext_youth_soccer_soccer-export-metadata_start | No row-specific failure recorded. |
| `b25-v4-row-050-soccer-export-metadata-1` | Riverside Youth Soccer | `soccer-export-metadata` | owner | B14_ext_youth_soccer_soccer-export-metadata_action | No row-specific failure recorded. |
| `b25-v4-row-051-soccer-export-metadata-2` | Riverside Youth Soccer | `soccer-export-metadata` | owner | B14_ext_youth_soccer_soccer-export-metadata_complete | No row-specific failure recorded. |
| `b25-v4-row-052-hoa-dues-payment-0` | Cedar Commons HOA | `hoa-dues-payment` | member | B14_ext_hoa_hoa-dues-payment_start | No row-specific failure recorded. |
| `b25-v4-row-053-hoa-dues-payment-1` | Cedar Commons HOA | `hoa-dues-payment` | member | B14_ext_hoa_hoa-dues-payment_action | LLM vision critique: The screen still reads as a reusable workflow/action template rather than a finished community-specific product surface. The visible copy explains the framework or a generic decision state instead of showing the concrete object, domain data, and natural next actions for this workflow. LLM required fix: Replace generic surface copy and repeated decision/details blocks with a domain-specific layout for this workflow: concrete title/object, real fields/content, primary and alternate actions, persistent result state, and receiver/next-step state visible in the screenshot. Current row verdict is `fail` with severity `major`. |
| `b25-v4-row-054-hoa-dues-payment-2` | Cedar Commons HOA | `hoa-dues-payment` | member | B14_ext_hoa_hoa-dues-payment_complete | No row-specific failure recorded. |
| `b25-v4-row-056-hoa-member-document-1` | Cedar Commons HOA | `hoa-member-document` | member | B14_ext_hoa_hoa-member-document_action | LLM vision critique: The screen still reads as a reusable workflow/action template rather than a finished community-specific product surface. The visible copy explains the framework or a generic decision state instead of showing the concrete object, domain data, and natural next actions for this workflow. LLM required fix: Replace generic surface copy and repeated decision/details blocks with a domain-specific layout for this workflow: concrete title/object, real fields/content, primary and alternate actions, persistent result state, and receiver/next-step state visible in the screenshot. Current row verdict is `fail` with severity `major`. |
| `b25-v4-row-058-hoa-facility-reservation-0` | Cedar Commons HOA | `hoa-facility-reservation` | member | B14_ext_hoa_hoa-facility-reservation_start | No row-specific failure recorded. |
| `b25-v4-row-059-hoa-facility-reservation-1` | Cedar Commons HOA | `hoa-facility-reservation` | member | B14_ext_hoa_hoa-facility-reservation_action | LLM vision critique: The screen still reads as a reusable workflow/action template rather than a finished community-specific product surface. The visible copy explains the framework or a generic decision state instead of showing the concrete object, domain data, and natural next actions for this workflow. LLM required fix: Replace generic surface copy and repeated decision/details blocks with a domain-specific layout for this workflow: concrete title/object, real fields/content, primary and alternate actions, persistent result state, and receiver/next-step state visible in the screenshot. Current row verdict is `fail` with severity `major`. |

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
- `llmVisionReview` imported from a fresh LLM vision UX judge run against the after screenshots.
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
- Screen row `b25-v4-row-002-garden-event-rsvp-1` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-002-garden-event-rsvp-1` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-002-garden-event-rsvp-1` names visible UI elements, visible text, persona `member`, workflow `garden-event-rsvp`, and the exact product UX issue.
- Primary surface for `garden-event-rsvp` is documented as `event detail with schedule, location, capacity/status, RSVP action, and result state` or another explicit domain-native surface.
- After-screenshot visible text proves every required semantic surface group for `garden-event-rsvp`.
- Fresh screenshot path/hash/timestamp/app commit SHA are recorded after the fix.
- Screen row `b25-v4-row-022-book-selection-publish-0` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-022-book-selection-publish-0` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-022-book-selection-publish-0` names visible UI elements, visible text, persona `owner`, workflow `book-selection-publish`, and the exact product UX issue.
- Primary surface for `book-selection-publish` is documented as `announcement feed/composer with audience, author, timestamp, body, and receiver state` or another explicit domain-native surface.
- After-screenshot visible text proves every required semantic surface group for `book-selection-publish`.
- Screen row `b25-v4-row-024-book-selection-publish-2` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-024-book-selection-publish-2` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-024-book-selection-publish-2` names visible UI elements, visible text, persona `owner`, workflow `book-selection-publish`, and the exact product UX issue.
- Screen row `b25-v4-row-025-book-search-ai-digest-0` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-025-book-search-ai-digest-0` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-025-book-search-ai-digest-0` names visible UI elements, visible text, persona `member`, workflow `book-search-ai-digest`, and the exact product UX issue.
- Primary surface for `book-search-ai-digest` is documented as `search/AI answer surface with query, result, citation, source, and follow-up action` or another explicit domain-native surface.
- After-screenshot visible text proves every required semantic surface group for `book-search-ai-digest`.
- Screen row `b25-v4-row-026-book-search-ai-digest-1` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-026-book-search-ai-digest-1` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-026-book-search-ai-digest-1` names visible UI elements, visible text, persona `member`, workflow `book-search-ai-digest`, and the exact product UX issue.
- Screen row `b25-v4-row-027-book-search-ai-digest-2` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-027-book-search-ai-digest-2` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-027-book-search-ai-digest-2` names visible UI elements, visible text, persona `member`, workflow `book-search-ai-digest`, and the exact product UX issue.
- Screen row `b25-v4-row-029-book-export-metadata-1` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-029-book-export-metadata-1` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-029-book-export-metadata-1` names visible UI elements, visible text, persona `owner`, workflow `book-export-metadata`, and the exact product UX issue.
- Primary surface for `book-export-metadata` is documented as `export/import wizard with preview, redaction, checksum, transfer status, and rollback state` or another explicit domain-native surface.
- After-screenshot visible text proves every required semantic surface group for `book-export-metadata`.
- Screen row `b25-v4-row-031-soccer-guardian-join-approval-0` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-031-soccer-guardian-join-approval-0` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-031-soccer-guardian-join-approval-0` names visible UI elements, visible text, persona `guardian`, workflow `soccer-guardian-join-approval`, and the exact product UX issue.
- Primary surface for `soccer-guardian-join-approval` is documented as `request detail and admin review queue with submitted data, decision action, status, and notification` or another explicit domain-native surface.
- After-screenshot visible text proves every required semantic surface group for `soccer-guardian-join-approval`.
- Screen row `b25-v4-row-032-soccer-guardian-join-approval-1` has a specific persona/personaId, not `persona-under-review`.

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

## B25-RB-003-recapture-rerun-closeout: Recapture evidence, rerun judges, and close resolved tickets

Prove the remediation with fresh screenshots, scorecards, and a committed iteration boundary.

| Field | Value |
| --- | --- |
| Status | open |
| Ticket IDs | B25-RT-001-b25-c01-no-blocker-major, B25-RT-002-b25-c03-production-grade-experience, B25-RT-003-b25-c14-llm-vision-ux-review, B25-RT-004-b25-c04-modern-intentional-ui, B25-RT-005-b25-c05-community-content-ia, B25-RT-006-b25-c06-domain-native-primary-surfaces, B25-RT-007-b25-c08-visible-text-specific-critique, B25-RT-008-b25-c09-no-layout-production-defects |

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
- Treat the imported LLM vision review as the independent semantic critique.
- Prioritize screen rows and workflows named in `llmVisionReview.findings` and `llmVisionReview.screenReviews`.
- Do not close the ticket until a fresh LLM vision review over after-screenshots passes.
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
| Event detail and RSVP flow | Material cards/lists/buttons / pattern | https://m3.material.io/components/cards/overview<br>Also: https://m3.material.io/components/buttons/overview<br>https://m3.material.io/components/chips/overview | Copy an event detail layout: title, date/time, location, host, capacity/status chip, attendee context, RSVP action, and confirmation state. |
| Feed item and composer pattern | Material cards/lists/text fields / pattern | https://m3.material.io/components/text-fields/overview<br>Also: https://m3.material.io/components/cards/overview<br>https://m3.material.io/components/lists/overview | Copy a feed/composer structure: audience, author, timestamp, body, attachments/status, publish action, and receiver read state. |
| Search and result list pattern | Material Design 3 / design-system | https://m3.material.io/components/search/overview<br>Also: https://m3.material.io/components/lists/overview | Copy a search layout with query, filters, ranked results, citations/sources, empty/error states, and follow-up actions. |
| Task list and export wizard | GOV.UK Design System / design-system | https://design-system.service.gov.uk/components/task-list/<br>Also: https://design-system.service.gov.uk/patterns/check-answers/ | Copy a wizard with steps, preview, redaction choices, checksum evidence, transfer status, and rollback confirmation. |
| Form validation and review pattern | U.S. Web Design System / design-system | https://designsystem.digital.gov/components/form/<br>Also: https://designsystem.digital.gov/components/alert/<br>https://design-system.service.gov.uk/components/error-summary/ | Copy a form flow with field labels, helper text, validation errors, review state, submit action, status, and protected-data treatment. |
| Roster/list with protected details | Material Design 3 / design-system | https://m3.material.io/components/data-tables/overview<br>Also: https://m3.material.io/components/lists/overview | Copy a roster with member names, roles, status, role-filtered fields, and clear protected-data redaction. |
| Material detail surface composition | Material Design 3 / design-system | https://m3.material.io/components/cards/overview | Build a domain detail page with primary content, metadata, status, and actions instead of a generic task card. |
| Review-and-confirm payment flow | GOV.UK Design System / design-system | https://design-system.service.gov.uk/patterns/check-answers/ | Use a review/confirmation step with amount, payer context, recipient, fees or entitlement, receipt, and audit trail. |
| Multi-step payment/progress flow | U.S. Web Design System / design-system | https://designsystem.digital.gov/components/step-indicator/ | Use explicit progress states for checkout, review, confirmation, receipt, and entitlement/status. |
| Document list/detail pattern | Material lists/cards / pattern | https://m3.material.io/components/lists/overview | Copy a document library with title, category, audience, file metadata, access state, download/view action, and empty/error states. |
| Reservation detail and availability flow | Material cards/forms / pattern | https://m3.material.io/components/date-pickers/overview<br>Also: https://m3.material.io/components/cards/overview | Copy an availability/reservation flow with facility details, date/time, capacity/rules, payment/status when needed, and confirmation. |
| Match schedule and result pattern | Material lists/cards / pattern | https://m3.material.io/components/lists/overview | Copy a match surface with players, schedule/round, result entry, result state, and next action. |
| Inbox and message thread pattern | Material lists/text fields / pattern | https://m3.material.io/components/lists/overview<br>Also: https://m3.material.io/components/text-fields/overview | Copy an inbox/thread structure: sender, timestamp, message preview/body, reply field, invite/block state, and read/received state. |
| Screenshot-first critique method | B25 production UX gate / methodology | docs/Build Plan V2/Tools/b25-remediation-ticket-template.md | Critique must quote visible UI/text, name the persona and task, compare against the chosen reference pattern, and state the exact fix. |

### Reference Research Queries
- production mobile UX review screenshot critique examples
- open source Flutter mobile app UX patterns GitHub
- open source Flutter event-rsvp mobile UI example GitHub
- event detail with schedule, location, capacity/status, RSVP action, and result state mobile UX pattern
- Material Design event detail with schedule, location, capacity/status, RSVP action, and result state mobile pattern
- open source Flutter announcement-feed mobile UI example GitHub
- announcement feed/composer with audience, author, timestamp, body, and receiver state mobile UX pattern
- Material Design announcement feed/composer with audience, author, timestamp, body, and receiver state mobile pattern
- open source Flutter search-results mobile UI example GitHub
- search/AI answer surface with query, result, citation, source, and follow-up action mobile UX pattern
- Material Design search/AI answer surface with query, result, citation, source, and follow-up action mobile pattern
- open source Flutter export-wizard mobile UI example GitHub
- export/import wizard with preview, redaction, checksum, transfer status, and rollback state mobile UX pattern
- Material Design export/import wizard with preview, redaction, checksum, transfer status, and rollback state mobile pattern
- open source Flutter form-review mobile UI example GitHub
- request detail and admin review queue with submitted data, decision action, status, and notification mobile UX pattern
- Material Design request detail and admin review queue with submitted data, decision action, status, and notification mobile pattern
- government design system request detail and admin review queue with submitted data, decision action, status, and notification form review confirmation pattern
- open source Flutter roster-list mobile UI example GitHub
- team roster/schedule surface with role-filtered member details and protected-data treatment mobile UX pattern

### Evidence Repair Work Items

Showing 11 of 11 work items. Full detail is in the JSON artifact.

| Work item | Stage | Community | Workflow | Persona | Screens | Coverage | Target surface | Blocked until |
| --- | --- | --- | --- | --- | ---: | ---: | --- | --- |
| `b25-wi-evidence-repair-community-book-club-book-search-ai-digest-community-book-club-member` | `evidence-repair` | Neighborhood Book Club | `book-search-ai-digest` | member | 3 | 1 | search/AI answer surface with query, result, citation, source, and follow-up action |  |
| `b25-wi-evidence-repair-community-youth-soccer-soccer-guardian-join-approval-community-youth-soccer-guardian` | `evidence-repair` | Riverside Youth Soccer | `soccer-guardian-join-approval` | guardian | 3 | 1 | request detail and admin review queue with submitted data, decision action, status, and notification |  |
| `b25-wi-evidence-repair-community-youth-soccer-soccer-team-roster-community-youth-soccer-coach` | `evidence-repair` | Riverside Youth Soccer | `soccer-team-roster` | coach | 3 | 1 | team roster/schedule surface with role-filtered member details and protected-data treatment |  |
| `b25-wi-evidence-repair-community-hoa-hoa-dues-payment-community-hoa-member` | `evidence-repair` | Cedar Commons HOA | `hoa-dues-payment` | member | 3 | 1 | payment or donation flow with amount, payer context, receipt, entitlement/status, and audit trail |  |
| `b25-wi-evidence-repair-community-hoa-hoa-member-document-community-hoa-member` | `evidence-repair` | Cedar Commons HOA | `hoa-member-document` | member | 3 | 1 | document library/detail surface with title, audience, file metadata, and access state |  |
| `b25-wi-evidence-repair-community-hoa-hoa-facility-reservation-community-hoa-member` | `evidence-repair` | Cedar Commons HOA | `hoa-facility-reservation` | member | 3 | 1 | facility detail/reservation flow with availability, payment/status, and confirmation |  |
| `b25-wi-evidence-repair-community-hoa-hoa-architectural-request-community-hoa-owner` | `evidence-repair` | Cedar Commons HOA | `hoa-architectural-request` | owner | 3 | 1 | request detail and admin review queue with submitted data, decision action, status, and notification |  |
| `b25-wi-evidence-repair-community-platform-social-platform-in-stream-ad-community-platform-social-member` | `evidence-repair` | Member Social Space | `platform-in-stream-ad` | member | 3 | 1 | community feed surface with clearly labeled in-stream ad placement, disclosure, content context, and no-blocking interaction state |  |
| `b25-wi-evidence-repair-community-export-migration-export-import-preview-community-export-migration-owner` | `evidence-repair` | Data Portability Community | `export-import-preview` | owner | 3 | 1 | export/import wizard with preview, redaction, checksum, transfer status, and rollback state |  |
| `b25-wi-evidence-repair-community-export-migration-export-full-bundle-community-export-migration-owner` | `evidence-repair` | Data Portability Community | `export-full-bundle` | owner | 3 | 1 | export/import wizard with preview, redaction, checksum, transfer status, and rollback state |  |
| `b25-wi-evidence-repair-persona-role-inventory-wf-persona-role-inventory-capability-matrix-persona-role-inventory-admin` | `evidence-repair` | persona-role-inventory | `wf_persona-role-inventory-capability-matrix` | admin | 1 | 1 | persona capability matrix surface with roles, allowed actions, receiver states, and denied/hidden behavior |  |

### Evidence Repair Work Items Reference Patterns

| Reference | Source | URL | What to copy |
| --- | --- | --- | --- |
| Search and result list pattern | Material Design 3 / design-system | https://m3.material.io/components/search/overview<br>Also: https://m3.material.io/components/lists/overview | Copy a search layout with query, filters, ranked results, citations/sources, empty/error states, and follow-up actions. |
| Material Design cards and lists | Material Design 3 / design-system | https://m3.material.io/components/cards/overview<br>Also: https://m3.material.io/components/lists/overview | Use cards/lists only as scannable containers with clear hierarchy, content, metadata, and actions. Do not use repeated cards as the whole primary workflow. |
| Flutter sample app implementation patterns | flutter/samples / open-source | https://github.com/flutter/samples | Copy the separation between app shell, route state, domain widgets, and testable UI states rather than hardcoding a single generic renderer. |
| Material navigation and information architecture | Material Design 3 / design-system | https://m3.material.io/components/navigation-drawer/overview<br>Also: https://m3.material.io/components/navigation-bar/overview | Organize screens by user jobs and destinations; keep primary actions visible and avoid exposing implementation taxonomy. |
| Apple HIG navigation and content organization | Apple Human Interface Guidelines / design-system | https://developer.apple.com/design/human-interface-guidelines/navigation | Make navigation predictable, content-centered, and appropriate for the user’s current task. |
| Form validation and review pattern | U.S. Web Design System / design-system | https://designsystem.digital.gov/components/form/<br>Also: https://designsystem.digital.gov/components/alert/<br>https://design-system.service.gov.uk/components/error-summary/ | Copy a form flow with field labels, helper text, validation errors, review state, submit action, status, and protected-data treatment. |
| Roster/list with protected details | Material Design 3 / design-system | https://m3.material.io/components/data-tables/overview<br>Also: https://m3.material.io/components/lists/overview | Copy a roster with member names, roles, status, role-filtered fields, and clear protected-data redaction. |
| Review-and-confirm payment flow | GOV.UK Design System / design-system | https://design-system.service.gov.uk/patterns/check-answers/ | Use a review/confirmation step with amount, payer context, recipient, fees or entitlement, receipt, and audit trail. |
| Multi-step payment/progress flow | U.S. Web Design System / design-system | https://designsystem.digital.gov/components/step-indicator/ | Use explicit progress states for checkout, review, confirmation, receipt, and entitlement/status. |
| Document list/detail pattern | Material lists/cards / pattern | https://m3.material.io/components/lists/overview | Copy a document library with title, category, audience, file metadata, access state, download/view action, and empty/error states. |
| Reservation detail and availability flow | Material cards/forms / pattern | https://m3.material.io/components/date-pickers/overview<br>Also: https://m3.material.io/components/cards/overview | Copy an availability/reservation flow with facility details, date/time, capacity/rules, payment/status when needed, and confirmation. |
| Material detail surface composition | Material Design 3 / design-system | https://m3.material.io/components/cards/overview | Build a domain detail page with primary content, metadata, status, and actions instead of a generic task card. |

### UI Remediation Work Items

Showing 30 of 44 work items. Full detail is in the JSON artifact.

| Work item | Stage | Community | Workflow | Persona | Screens | Coverage | Target surface | Blocked until |
| --- | --- | --- | --- | --- | ---: | ---: | --- | --- |
| `b25-wi-ui-remediation-community-garden-club-garden-event-rsvp-community-garden-club-member` | `ui-remediation` | Garden Club | `garden-event-rsvp` | member | 1 | 0 | event detail with schedule, location, capacity/status, RSVP action, and result state | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-book-club-book-selection-publish-community-book-club-owner` | `ui-remediation` | Neighborhood Book Club | `book-selection-publish` | owner | 2 | 0 | announcement feed/composer with audience, author, timestamp, body, and receiver state | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-book-club-book-search-ai-digest-community-book-club-member` | `ui-remediation` | Neighborhood Book Club | `book-search-ai-digest` | member | 3 | 1 | search/AI answer surface with query, result, citation, source, and follow-up action | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-book-club-book-export-metadata-community-book-club-owner` | `ui-remediation` | Neighborhood Book Club | `book-export-metadata` | owner | 1 | 0 | export/import wizard with preview, redaction, checksum, transfer status, and rollback state | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-youth-soccer-soccer-guardian-join-approval-community-youth-soccer-guardian` | `ui-remediation` | Riverside Youth Soccer | `soccer-guardian-join-approval` | guardian | 3 | 1 | request detail and admin review queue with submitted data, decision action, status, and notification | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-youth-soccer-soccer-team-roster-community-youth-soccer-coach` | `ui-remediation` | Riverside Youth Soccer | `soccer-team-roster` | coach | 3 | 1 | team roster/schedule surface with role-filtered member details and protected-data treatment | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-youth-soccer-soccer-minor-redaction-community-youth-soccer-guardian` | `ui-remediation` | Riverside Youth Soccer | `soccer-minor-redaction` | guardian | 3 | 0 | protected youth roster/profile surface with minor-data redaction, guardian visibility, and coach-only detail state | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-youth-soccer-soccer-registration-payment-community-youth-soccer-guardian` | `ui-remediation` | Riverside Youth Soccer | `soccer-registration-payment` | guardian | 1 | 0 | payment or donation flow with amount, payer context, receipt, entitlement/status, and audit trail | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-youth-soccer-soccer-practice-schedule-community-youth-soccer-guardian` | `ui-remediation` | Riverside Youth Soccer | `soccer-practice-schedule` | guardian | 1 | 0 | event detail with schedule, location, capacity/status, RSVP action, and result state | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-youth-soccer-soccer-reminder-notification-community-youth-soccer-guardian` | `ui-remediation` | Riverside Youth Soccer | `soccer-reminder-notification` | guardian | 3 | 0 | notification inbox/detail surface with sender, audience, timestamp, message body, and receiver state | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-youth-soccer-soccer-export-metadata-community-youth-soccer-owner` | `ui-remediation` | Riverside Youth Soccer | `soccer-export-metadata` | owner | 3 | 0 | export/import wizard with preview, redaction, checksum, transfer status, and rollback state | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-hoa-hoa-dues-payment-community-hoa-member` | `ui-remediation` | Cedar Commons HOA | `hoa-dues-payment` | member | 3 | 1 | payment or donation flow with amount, payer context, receipt, entitlement/status, and audit trail | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-hoa-hoa-member-document-community-hoa-member` | `ui-remediation` | Cedar Commons HOA | `hoa-member-document` | member | 3 | 1 | document library/detail surface with title, audience, file metadata, and access state | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-hoa-hoa-facility-reservation-community-hoa-member` | `ui-remediation` | Cedar Commons HOA | `hoa-facility-reservation` | member | 3 | 1 | facility detail/reservation flow with availability, payment/status, and confirmation | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-hoa-hoa-architectural-request-community-hoa-owner` | `ui-remediation` | Cedar Commons HOA | `hoa-architectural-request` | owner | 3 | 1 | request detail and admin review queue with submitted data, decision action, status, and notification | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-hoa-hoa-committee-decision-community-hoa-owner` | `ui-remediation` | Cedar Commons HOA | `hoa-committee-decision` | owner | 3 | 0 | request detail and admin review queue with submitted data, decision action, status, and notification | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-hoa-hoa-owner-notification-community-hoa-owner` | `ui-remediation` | Cedar Commons HOA | `hoa-owner-notification` | owner | 3 | 0 | notification inbox/detail surface with sender, audience, timestamp, message body, and receiver state | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-hoa-hoa-export-evidence-community-hoa-owner` | `ui-remediation` | Cedar Commons HOA | `hoa-export-evidence` | owner | 1 | 0 | export/import wizard with preview, redaction, checksum, transfer status, and rollback state | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-mosque-mosque-announcement-community-mosque-owner` | `ui-remediation` | Masjid Nur | `mosque-announcement` | owner | 2 | 0 | announcement feed/composer with audience, author, timestamp, body, and receiver state | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-mosque-mosque-volunteer-signup-community-mosque-member` | `ui-remediation` | Masjid Nur | `mosque-volunteer-signup` | member | 1 | 0 | volunteer signup surface with role, time, protected contact fields, and confirmation | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-mosque-mosque-donor-visibility-community-mosque-donor` | `ui-remediation` | Masjid Nur | `mosque-donor-visibility` | donor | 3 | 0 | donor privacy preference surface with visibility choice, donation context, confirmation, and receipt visibility state | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-mosque-mosque-donation-payment-community-mosque-donor` | `ui-remediation` | Masjid Nur | `mosque-donation-payment` | donor | 1 | 0 | payment or donation flow with amount, payer context, receipt, entitlement/status, and audit trail | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-mosque-mosque-care-request-community-mosque-member` | `ui-remediation` | Masjid Nur | `mosque-care-request` | member | 3 | 0 | protected care request form and private response/status surface | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-mosque-mosque-neutral-notification-community-mosque-member` | `ui-remediation` | Masjid Nur | `mosque-neutral-notification` | member | 3 | 0 | notification inbox/detail surface with sender, audience, timestamp, message body, and receiver state | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-mosque-mosque-search-ai-citation-community-mosque-member` | `ui-remediation` | Masjid Nur | `mosque-search-ai-citation` | member | 3 | 0 | search/AI answer surface with query, result, citation, source, and follow-up action | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-chess-club-chess-local-install-open-community-chess-club-member` | `ui-remediation` | Chess Club | `chess-local-install-open` | member | 1 | 0 | match schedule/result surface with players, round, outcome, and next action | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-chess-club-chess-route-home-community-chess-club-member` | `ui-remediation` | Chess Club | `chess-route-home` | member | 1 | 0 | match schedule/result surface with players, round, outcome, and next action | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-chess-club-chess-match-result-community-chess-club-member` | `ui-remediation` | Chess Club | `chess-match-result` | member | 1 | 0 | match schedule/result surface with players, round, outcome, and next action | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-camera-club-photo-walk-rsvp-community-camera-club-member` | `ui-remediation` | Camera Club | `photo-walk-rsvp` | member | 1 | 0 | event detail with schedule, location, capacity/status, RSVP action, and result state | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-camera-club-critique-submission-community-camera-club-member` | `ui-remediation` | Camera Club | `critique-submission` | member | 1 | 0 | critique submission/review surface with image/work title, comments, reviewer state, and result | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |

### UI Remediation Work Items Reference Patterns

| Reference | Source | URL | What to copy |
| --- | --- | --- | --- |
| Event detail and RSVP flow | Material cards/lists/buttons / pattern | https://m3.material.io/components/cards/overview<br>Also: https://m3.material.io/components/buttons/overview<br>https://m3.material.io/components/chips/overview | Copy an event detail layout: title, date/time, location, host, capacity/status chip, attendee context, RSVP action, and confirmation state. |
| Material Design cards and lists | Material Design 3 / design-system | https://m3.material.io/components/cards/overview<br>Also: https://m3.material.io/components/lists/overview | Use cards/lists only as scannable containers with clear hierarchy, content, metadata, and actions. Do not use repeated cards as the whole primary workflow. |
| Flutter sample app implementation patterns | flutter/samples / open-source | https://github.com/flutter/samples | Copy the separation between app shell, route state, domain widgets, and testable UI states rather than hardcoding a single generic renderer. |
| Material navigation and information architecture | Material Design 3 / design-system | https://m3.material.io/components/navigation-drawer/overview<br>Also: https://m3.material.io/components/navigation-bar/overview | Organize screens by user jobs and destinations; keep primary actions visible and avoid exposing implementation taxonomy. |
| Apple HIG navigation and content organization | Apple Human Interface Guidelines / design-system | https://developer.apple.com/design/human-interface-guidelines/navigation | Make navigation predictable, content-centered, and appropriate for the user’s current task. |
| Feed item and composer pattern | Material cards/lists/text fields / pattern | https://m3.material.io/components/text-fields/overview<br>Also: https://m3.material.io/components/cards/overview<br>https://m3.material.io/components/lists/overview | Copy a feed/composer structure: audience, author, timestamp, body, attachments/status, publish action, and receiver read state. |
| Search and result list pattern | Material Design 3 / design-system | https://m3.material.io/components/search/overview<br>Also: https://m3.material.io/components/lists/overview | Copy a search layout with query, filters, ranked results, citations/sources, empty/error states, and follow-up actions. |
| Task list and export wizard | GOV.UK Design System / design-system | https://design-system.service.gov.uk/components/task-list/<br>Also: https://design-system.service.gov.uk/patterns/check-answers/ | Copy a wizard with steps, preview, redaction choices, checksum evidence, transfer status, and rollback confirmation. |
| Form validation and review pattern | U.S. Web Design System / design-system | https://designsystem.digital.gov/components/form/<br>Also: https://designsystem.digital.gov/components/alert/<br>https://design-system.service.gov.uk/components/error-summary/ | Copy a form flow with field labels, helper text, validation errors, review state, submit action, status, and protected-data treatment. |
| Roster/list with protected details | Material Design 3 / design-system | https://m3.material.io/components/data-tables/overview<br>Also: https://m3.material.io/components/lists/overview | Copy a roster with member names, roles, status, role-filtered fields, and clear protected-data redaction. |
| Material detail surface composition | Material Design 3 / design-system | https://m3.material.io/components/cards/overview | Build a domain detail page with primary content, metadata, status, and actions instead of a generic task card. |
| Review-and-confirm payment flow | GOV.UK Design System / design-system | https://design-system.service.gov.uk/patterns/check-answers/ | Use a review/confirmation step with amount, payer context, recipient, fees or entitlement, receipt, and audit trail. |

### Affected Coverage Rows

Showing 11 of 11 affected coverage rows.

| Coverage row | Community | Workflow | Persona | Missing evidence |
| --- | --- | --- | --- | --- |
| `b25-wp-009-book-search-ai-digest-community-book-club-member` | Neighborhood Book Club | `book-search-ai-digest` | member |  |
| `b25-wp-011-soccer-guardian-join-approval-community-youth-soccer-guardian` | Riverside Youth Soccer | `soccer-guardian-join-approval` | guardian |  |
| `b25-wp-012-soccer-team-roster-community-youth-soccer-coach` | Riverside Youth Soccer | `soccer-team-roster` | coach |  |
| `b25-wp-018-hoa-dues-payment-community-hoa-member` | Cedar Commons HOA | `hoa-dues-payment` | member |  |
| `b25-wp-019-hoa-member-document-community-hoa-member` | Cedar Commons HOA | `hoa-member-document` | member |  |
| `b25-wp-020-hoa-facility-reservation-community-hoa-member` | Cedar Commons HOA | `hoa-facility-reservation` | member |  |
| `b25-wp-021-hoa-architectural-request-community-hoa-owner` | Cedar Commons HOA | `hoa-architectural-request` | owner |  |
| `b25-wp-044-platform-in-stream-ad-community-platform-social-member` | Member Social Space | `platform-in-stream-ad` | member |  |
| `b25-wp-053-export-import-preview-community-export-migration-owner` | Data Portability Community | `export-import-preview` | owner |  |
| `b25-wp-057-export-full-bundle-community-export-migration-owner` | Data Portability Community | `export-full-bundle` | owner |  |
| `b25-wp-062-wf-persona-role-inventory-capability-matrix-persona-role-inventory-admin` | persona-role-inventory | `wf_persona-role-inventory-capability-matrix` | admin |  |

### Affected Screen Rows

Showing 30 of 92 affected screen rows.

| Screen row | Community | Workflow | Persona | State | Exact UX failure |
| --- | --- | --- | --- | --- | --- |
| `b25-v4-row-002-garden-event-rsvp-1` | Garden Club | `garden-event-rsvp` | member | B13_ext_garden_club_garden-event-rsvp_action | LLM vision critique: This row is materially closer to a production product surface than the generic action templates because the user can understand the specific event, shift, or announcement context from visible content. |
| `b25-v4-row-022-book-selection-publish-0` | Neighborhood Book Club | `book-selection-publish` | owner | B14_ext_book_club_book-selection-publish_start | No row-specific failure recorded. |
| `b25-v4-row-024-book-selection-publish-2` | Neighborhood Book Club | `book-selection-publish` | owner | B14_ext_book_club_book-selection-publish_complete | No row-specific failure recorded. |
| `b25-v4-row-025-book-search-ai-digest-0` | Neighborhood Book Club | `book-search-ai-digest` | member | B14_ext_book_club_book-search-ai-digest_start | No row-specific failure recorded. |
| `b25-v4-row-026-book-search-ai-digest-1` | Neighborhood Book Club | `book-search-ai-digest` | member | B14_ext_book_club_book-search-ai-digest_action | LLM vision critique: The screen still reads as a reusable workflow/action template rather than a finished community-specific product surface. The visible copy explains the framework or a generic decision state instead of showing the concrete object, domain data, and natural next actions for this workflow. LLM required fix: Replace generic surface copy and repeated decision/details blocks with a domain-specific layout for this workflow: concrete title/object, real fields/content, primary and alternate actions, persistent result state, and receiver/next-step state visible in the screenshot. Current row verdict is `fail` with severity `major`. |
| `b25-v4-row-027-book-search-ai-digest-2` | Neighborhood Book Club | `book-search-ai-digest` | member | B14_ext_book_club_book-search-ai-digest_complete | No row-specific failure recorded. |
| `b25-v4-row-029-book-export-metadata-1` | Neighborhood Book Club | `book-export-metadata` | owner | B14_ext_book_club_book-export-metadata_action | No row-specific failure recorded. |
| `b25-v4-row-031-soccer-guardian-join-approval-0` | Riverside Youth Soccer | `soccer-guardian-join-approval` | guardian | B14_ext_youth_soccer_soccer-guardian-join-approval_start | No row-specific failure recorded. |
| `b25-v4-row-032-soccer-guardian-join-approval-1` | Riverside Youth Soccer | `soccer-guardian-join-approval` | guardian | B14_ext_youth_soccer_soccer-guardian-join-approval_action | LLM vision critique: The screen still reads as a reusable workflow/action template rather than a finished community-specific product surface. The visible copy explains the framework or a generic decision state instead of showing the concrete object, domain data, and natural next actions for this workflow. LLM required fix: Replace generic surface copy and repeated decision/details blocks with a domain-specific layout for this workflow: concrete title/object, real fields/content, primary and alternate actions, persistent result state, and receiver/next-step state visible in the screenshot. Current row verdict is `fail` with severity `major`. |
| `b25-v4-row-033-soccer-guardian-join-approval-2` | Riverside Youth Soccer | `soccer-guardian-join-approval` | guardian | B14_ext_youth_soccer_soccer-guardian-join-approval_complete | No row-specific failure recorded. |
| `b25-v4-row-034-soccer-team-roster-0` | Riverside Youth Soccer | `soccer-team-roster` | coach | B14_ext_youth_soccer_soccer-team-roster_start | No row-specific failure recorded. |
| `b25-v4-row-035-soccer-team-roster-1` | Riverside Youth Soccer | `soccer-team-roster` | coach | B14_ext_youth_soccer_soccer-team-roster_action | LLM vision critique: The screen still reads as a reusable workflow/action template rather than a finished community-specific product surface. The visible copy explains the framework or a generic decision state instead of showing the concrete object, domain data, and natural next actions for this workflow. LLM required fix: Replace generic surface copy and repeated decision/details blocks with a domain-specific layout for this workflow: concrete title/object, real fields/content, primary and alternate actions, persistent result state, and receiver/next-step state visible in the screenshot. Current row verdict is `fail` with severity `major`. |
| `b25-v4-row-036-soccer-team-roster-2` | Riverside Youth Soccer | `soccer-team-roster` | coach | B14_ext_youth_soccer_soccer-team-roster_complete | No row-specific failure recorded. |
| `b25-v4-row-037-soccer-minor-redaction-0` | Riverside Youth Soccer | `soccer-minor-redaction` | guardian | B14_ext_youth_soccer_soccer-minor-redaction_start | No row-specific failure recorded. |
| `b25-v4-row-038-soccer-minor-redaction-1` | Riverside Youth Soccer | `soccer-minor-redaction` | guardian | B14_ext_youth_soccer_soccer-minor-redaction_action | No row-specific failure recorded. |
| `b25-v4-row-039-soccer-minor-redaction-2` | Riverside Youth Soccer | `soccer-minor-redaction` | guardian | B14_ext_youth_soccer_soccer-minor-redaction_complete | No row-specific failure recorded. |
| `b25-v4-row-041-soccer-registration-payment-1` | Riverside Youth Soccer | `soccer-registration-payment` | guardian | B14_ext_youth_soccer_soccer-registration-payment_action | No row-specific failure recorded. |
| `b25-v4-row-044-soccer-practice-schedule-1` | Riverside Youth Soccer | `soccer-practice-schedule` | guardian | B14_ext_youth_soccer_soccer-practice-schedule_action | No row-specific failure recorded. |
| `b25-v4-row-046-soccer-reminder-notification-0` | Riverside Youth Soccer | `soccer-reminder-notification` | guardian | B14_ext_youth_soccer_soccer-reminder-notification_start | No row-specific failure recorded. |
| `b25-v4-row-047-soccer-reminder-notification-1` | Riverside Youth Soccer | `soccer-reminder-notification` | guardian | B14_ext_youth_soccer_soccer-reminder-notification_action | No row-specific failure recorded. |
| `b25-v4-row-048-soccer-reminder-notification-2` | Riverside Youth Soccer | `soccer-reminder-notification` | guardian | B14_ext_youth_soccer_soccer-reminder-notification_complete | No row-specific failure recorded. |
| `b25-v4-row-049-soccer-export-metadata-0` | Riverside Youth Soccer | `soccer-export-metadata` | owner | B14_ext_youth_soccer_soccer-export-metadata_start | No row-specific failure recorded. |
| `b25-v4-row-050-soccer-export-metadata-1` | Riverside Youth Soccer | `soccer-export-metadata` | owner | B14_ext_youth_soccer_soccer-export-metadata_action | No row-specific failure recorded. |
| `b25-v4-row-051-soccer-export-metadata-2` | Riverside Youth Soccer | `soccer-export-metadata` | owner | B14_ext_youth_soccer_soccer-export-metadata_complete | No row-specific failure recorded. |
| `b25-v4-row-052-hoa-dues-payment-0` | Cedar Commons HOA | `hoa-dues-payment` | member | B14_ext_hoa_hoa-dues-payment_start | No row-specific failure recorded. |
| `b25-v4-row-053-hoa-dues-payment-1` | Cedar Commons HOA | `hoa-dues-payment` | member | B14_ext_hoa_hoa-dues-payment_action | LLM vision critique: The screen still reads as a reusable workflow/action template rather than a finished community-specific product surface. The visible copy explains the framework or a generic decision state instead of showing the concrete object, domain data, and natural next actions for this workflow. LLM required fix: Replace generic surface copy and repeated decision/details blocks with a domain-specific layout for this workflow: concrete title/object, real fields/content, primary and alternate actions, persistent result state, and receiver/next-step state visible in the screenshot. Current row verdict is `fail` with severity `major`. |
| `b25-v4-row-054-hoa-dues-payment-2` | Cedar Commons HOA | `hoa-dues-payment` | member | B14_ext_hoa_hoa-dues-payment_complete | No row-specific failure recorded. |
| `b25-v4-row-056-hoa-member-document-1` | Cedar Commons HOA | `hoa-member-document` | member | B14_ext_hoa_hoa-member-document_action | LLM vision critique: The screen still reads as a reusable workflow/action template rather than a finished community-specific product surface. The visible copy explains the framework or a generic decision state instead of showing the concrete object, domain data, and natural next actions for this workflow. LLM required fix: Replace generic surface copy and repeated decision/details blocks with a domain-specific layout for this workflow: concrete title/object, real fields/content, primary and alternate actions, persistent result state, and receiver/next-step state visible in the screenshot. Current row verdict is `fail` with severity `major`. |
| `b25-v4-row-058-hoa-facility-reservation-0` | Cedar Commons HOA | `hoa-facility-reservation` | member | B14_ext_hoa_hoa-facility-reservation_start | No row-specific failure recorded. |
| `b25-v4-row-059-hoa-facility-reservation-1` | Cedar Commons HOA | `hoa-facility-reservation` | member | B14_ext_hoa_hoa-facility-reservation_action | LLM vision critique: The screen still reads as a reusable workflow/action template rather than a finished community-specific product surface. The visible copy explains the framework or a generic decision state instead of showing the concrete object, domain data, and natural next actions for this workflow. LLM required fix: Replace generic surface copy and repeated decision/details blocks with a domain-specific layout for this workflow: concrete title/object, real fields/content, primary and alternate actions, persistent result state, and receiver/next-step state visible in the screenshot. Current row verdict is `fail` with severity `major`. |

### Evidence To Update
- independent-production-ux-review.json findings
- product-ux-remediation-loop.md
- b25-iteration-scorecard-latest.json/.md
- Build Tracker.md B25 row and execution ledger
- independent-production-ux-review.json holisticQuestionAnswers
- independent-production-ux-review.md holistic review summary
- product-ux-screen-review-matrix.md relevant screen rows
- production-ux-criteria-scorecard.json/.md
- independent-production-ux-review.json llmVisionReview
- independent-production-ux-review.json findings from source=llm-vision-ux-judge
- product-ux-screen-review-matrix.md affected screen rows
- independent-production-ux-review.json workflowPersonaScorecards
- independent-production-ux-review.json screenRows
- product-ux-screen-review-matrix.md every workflow/persona row
- Updated review JSON, scorecards, screenshots, remediation log, and tracker evidence for the fixed criterion.
- Fresh holistic screenshots for primary homes, navigation, representative detail surfaces, and representative completion/result states.
- `holisticQuestionAnswers` with visible evidence, score, pass/fail answer, and specific rationale.
- `llmVisionReview` imported from a fresh LLM vision UX judge run against the after screenshots.
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
- Screen row `b25-v4-row-002-garden-event-rsvp-1` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-002-garden-event-rsvp-1` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-002-garden-event-rsvp-1` names visible UI elements, visible text, persona `member`, workflow `garden-event-rsvp`, and the exact product UX issue.
- Primary surface for `garden-event-rsvp` is documented as `event detail with schedule, location, capacity/status, RSVP action, and result state` or another explicit domain-native surface.
- After-screenshot visible text proves every required semantic surface group for `garden-event-rsvp`.
- Fresh screenshot path/hash/timestamp/app commit SHA are recorded after the fix.
- Screen row `b25-v4-row-022-book-selection-publish-0` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-022-book-selection-publish-0` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-022-book-selection-publish-0` names visible UI elements, visible text, persona `owner`, workflow `book-selection-publish`, and the exact product UX issue.
- Primary surface for `book-selection-publish` is documented as `announcement feed/composer with audience, author, timestamp, body, and receiver state` or another explicit domain-native surface.
- After-screenshot visible text proves every required semantic surface group for `book-selection-publish`.
- Screen row `b25-v4-row-024-book-selection-publish-2` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-024-book-selection-publish-2` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-024-book-selection-publish-2` names visible UI elements, visible text, persona `owner`, workflow `book-selection-publish`, and the exact product UX issue.
- Screen row `b25-v4-row-025-book-search-ai-digest-0` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-025-book-search-ai-digest-0` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-025-book-search-ai-digest-0` names visible UI elements, visible text, persona `member`, workflow `book-search-ai-digest`, and the exact product UX issue.
- Primary surface for `book-search-ai-digest` is documented as `search/AI answer surface with query, result, citation, source, and follow-up action` or another explicit domain-native surface.
- After-screenshot visible text proves every required semantic surface group for `book-search-ai-digest`.
- Screen row `b25-v4-row-026-book-search-ai-digest-1` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-026-book-search-ai-digest-1` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-026-book-search-ai-digest-1` names visible UI elements, visible text, persona `member`, workflow `book-search-ai-digest`, and the exact product UX issue.
- Screen row `b25-v4-row-027-book-search-ai-digest-2` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-027-book-search-ai-digest-2` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-027-book-search-ai-digest-2` names visible UI elements, visible text, persona `member`, workflow `book-search-ai-digest`, and the exact product UX issue.
- Screen row `b25-v4-row-029-book-export-metadata-1` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-029-book-export-metadata-1` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-029-book-export-metadata-1` names visible UI elements, visible text, persona `owner`, workflow `book-export-metadata`, and the exact product UX issue.
- Primary surface for `book-export-metadata` is documented as `export/import wizard with preview, redaction, checksum, transfer status, and rollback state` or another explicit domain-native surface.
- After-screenshot visible text proves every required semantic surface group for `book-export-metadata`.
- Screen row `b25-v4-row-031-soccer-guardian-join-approval-0` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-031-soccer-guardian-join-approval-0` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-031-soccer-guardian-join-approval-0` names visible UI elements, visible text, persona `guardian`, workflow `soccer-guardian-join-approval`, and the exact product UX issue.
- Primary surface for `soccer-guardian-join-approval` is documented as `request detail and admin review queue with submitted data, decision action, status, and notification` or another explicit domain-native surface.
- After-screenshot visible text proves every required semantic surface group for `soccer-guardian-join-approval`.
- Screen row `b25-v4-row-032-soccer-guardian-join-approval-1` has a specific persona/personaId, not `persona-under-review`.

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
