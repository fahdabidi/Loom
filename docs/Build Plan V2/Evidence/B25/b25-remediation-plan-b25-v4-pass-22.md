# B25 Remediation Plan

| Field | Value |
| --- | --- |
| Review run | `b25-v4-pass-21` |
| Status | `open` |
| Source tickets | `../docs/Build Plan V2/Evidence/B25/b25-remediation-tickets-b25-v4-pass-21.json` |
| Ticket count | 9 |
| Scorecard status | `fail` |
| Remaining blocker/major | 4 |
| Blocking criteria failures | 9 |
| Product spec work items | 6 |
| Evidence repair work items | 24 |
| UI remediation work items | 24 |
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
| `B25-RT-007-b25-c13-workflow-lifecycle-complete` | `b25-c13-workflow-lifecycle-complete` | major | open | Every primary workflow has complete lifecycle UX |
| `B25-RT-008-b25-c08-visible-text-specific-critique` | `b25-c08-visible-text-specific-critique` | major | open | Every row has visible text and screen-specific critique |
| `B25-RT-009-b25-c09-no-layout-production-defects` | `b25-c09-no-layout-production-defects` | major | open | No blocking or major layout/content defects remain |

## B25-RB-001-independent-review-evidence: Complete independent review evidence and critique

Turn captured screenshots into complete independent UX review evidence before attempting UI remediation.

| Field | Value |
| --- | --- |
| Status | open |
| Ticket IDs | B25-RT-002-b25-c03-production-grade-experience, B25-RT-004-b25-c04-modern-intentional-ui, B25-RT-008-b25-c08-visible-text-specific-critique, B25-RT-009-b25-c09-no-layout-production-defects |

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
| Roster/list with protected details | Material Design 3 / design-system | https://m3.material.io/components/data-tables/overview<br>Also: https://m3.material.io/components/lists/overview | Copy a roster with member names, roles, status, role-filtered fields, and clear protected-data redaction. |
| Review-and-confirm payment flow | GOV.UK Design System / design-system | https://design-system.service.gov.uk/patterns/check-answers/ | Use a review/confirmation step with amount, payer context, recipient, fees or entitlement, receipt, and audit trail. |
| Multi-step payment/progress flow | U.S. Web Design System / design-system | https://designsystem.digital.gov/components/step-indicator/ | Use explicit progress states for checkout, review, confirmation, receipt, and entitlement/status. |
| Event detail and RSVP flow | Material cards/lists/buttons / pattern | https://m3.material.io/components/cards/overview<br>Also: https://m3.material.io/components/buttons/overview<br>https://m3.material.io/components/chips/overview | Copy an event detail layout: title, date/time, location, host, capacity/status chip, attendee context, RSVP action, and confirmation state. |
| Task list and export wizard | GOV.UK Design System / design-system | https://design-system.service.gov.uk/components/task-list/<br>Also: https://design-system.service.gov.uk/patterns/check-answers/ | Copy a wizard with steps, preview, redaction choices, checksum evidence, transfer status, and rollback confirmation. |
| Material detail surface composition | Material Design 3 / design-system | https://m3.material.io/components/cards/overview | Build a domain detail page with primary content, metadata, status, and actions instead of a generic task card. |
| Form validation and review pattern | U.S. Web Design System / design-system | https://designsystem.digital.gov/components/form/<br>Also: https://designsystem.digital.gov/components/alert/<br>https://design-system.service.gov.uk/components/error-summary/ | Copy a form flow with field labels, helper text, validation errors, review state, submit action, status, and protected-data treatment. |
| Inbox and message thread pattern | Material lists/text fields / pattern | https://m3.material.io/components/lists/overview<br>Also: https://m3.material.io/components/text-fields/overview | Copy an inbox/thread structure: sender, timestamp, message preview/body, reply field, invite/block state, and read/received state. |
| Screenshot-first critique method | B25 production UX gate / methodology | docs/Build Plan V2/Tools/b25-remediation-ticket-template.md | Critique must quote visible UI/text, name the persona and task, compare against the chosen reference pattern, and state the exact fix. |

### Reference Research Queries
- production mobile UX review screenshot critique examples
- open source Flutter mobile app UX patterns GitHub
- open source Flutter roster-list mobile UI example GitHub
- team roster/schedule surface with role-filtered member details and protected-data treatment mobile UX pattern
- Material Design team roster/schedule surface with role-filtered member details and protected-data treatment mobile pattern
- open source Flutter payment-donation mobile UI example GitHub
- payment or donation flow with amount, payer context, receipt, entitlement/status, and audit trail mobile UX pattern
- Material Design payment or donation flow with amount, payer context, receipt, entitlement/status, and audit trail mobile pattern
- government design system payment or donation flow with amount, payer context, receipt, entitlement/status, and audit trail form review confirmation pattern
- open source Flutter event-rsvp mobile UI example GitHub
- event detail with schedule, location, capacity/status, RSVP action, and result state mobile UX pattern
- Material Design event detail with schedule, location, capacity/status, RSVP action, and result state mobile pattern
- open source Flutter export-wizard mobile UI example GitHub
- export/import wizard with preview, redaction, checksum, transfer status, and rollback state mobile UX pattern
- Material Design export/import wizard with preview, redaction, checksum, transfer status, and rollback state mobile pattern
- open source Flutter domain-native-surface mobile UI example GitHub
- donor privacy preference surface with visibility choice, donation context, confirmation, and receipt visibility state mobile UX pattern
- Material Design donor privacy preference surface with visibility choice, donation context, confirmation, and receipt visibility state mobile pattern
- open source Flutter form-review mobile UI example GitHub
- protected care request form and private response/status surface mobile UX pattern

### Evidence Repair Work Items

Showing 11 of 11 work items. Full detail is in the JSON artifact.

| Work item | Stage | Community | Workflow | Persona | Screens | Coverage | Target surface | Blocked until |
| --- | --- | --- | --- | --- | ---: | ---: | --- | --- |
| `b25-wi-evidence-repair-community-camera-club-photo-walk-rsvp-community-camera-club-member` | `evidence-repair` | Camera Club | `photo-walk-rsvp` | member | 3 | 1 | event detail with schedule, location, capacity/status, RSVP action, and result state |  |
| `b25-wi-evidence-repair-community-camera-club-critique-submission-community-camera-club-member` | `evidence-repair` | Camera Club | `critique-submission` | member | 3 | 1 | critique submission/review surface with image/work title, comments, reviewer state, and result |  |
| `b25-wi-evidence-repair-community-camera-club-gear-loan-request-community-camera-club-member` | `evidence-repair` | Camera Club | `gear-loan-request` | member | 3 | 1 | request detail and admin review queue with submitted data, decision action, status, and notification |  |
| `b25-wi-evidence-repair-community-ad-off-ad-off-member-checkout-community-ad-off-member` | `evidence-repair` | Ad-Free Community | `ad-off-member-checkout` | member | 3 | 1 | payment or donation flow with amount, payer context, receipt, entitlement/status, and audit trail |  |
| `b25-wi-evidence-repair-community-ad-off-ad-off-community-checkout-community-ad-off-member` | `evidence-repair` | Ad-Free Community | `ad-off-community-checkout` | member | 3 | 1 | payment or donation flow with amount, payer context, receipt, entitlement/status, and audit trail |  |
| `b25-wi-evidence-repair-community-ad-off-ad-off-entitlement-status-community-ad-off-member` | `evidence-repair` | Ad-Free Community | `ad-off-entitlement-status` | member | 3 | 1 | payment or donation flow with amount, payer context, receipt, entitlement/status, and audit trail |  |
| `b25-wi-evidence-repair-community-ad-off-ad-off-receipt-evidence-community-ad-off-member` | `evidence-repair` | Ad-Free Community | `ad-off-receipt-evidence` | member | 3 | 1 | payment or donation flow with amount, payer context, receipt, entitlement/status, and audit trail |  |
| `b25-wi-evidence-repair-community-ad-off-ad-off-ad-suppression-community-ad-off-member` | `evidence-repair` | Ad-Free Community | `ad-off-ad-suppression` | member | 3 | 1 | payment or donation flow with amount, payer context, receipt, entitlement/status, and audit trail |  |
| `b25-wi-evidence-repair-community-ad-off-ad-off-settlement-utility-community-ad-off-member` | `evidence-repair` | Ad-Free Community | `ad-off-settlement-utility` | member | 3 | 1 | payment or donation flow with amount, payer context, receipt, entitlement/status, and audit trail |  |
| `b25-wi-evidence-repair-community-mosque-wf-multi-persona-workflow-evidence-community-mosque-admin` | `evidence-repair` | Masjid Nur | `wf_multi-persona-workflow-evidence` | admin | 3 | 1 | multi-persona handoff evidence surface with actor-created state, persona switch, receiver state, and continuation action |  |
| `b25-wi-evidence-repair-community-mosque-wf-multi-persona-workflow-evidence-community-mosque-member` | `evidence-repair` | Masjid Nur | `wf_multi-persona-workflow-evidence` | member | 3 | 1 | multi-persona handoff evidence surface with actor-created state, persona switch, receiver state, and continuation action |  |

### Evidence Repair Work Items Reference Patterns

| Reference | Source | URL | What to copy |
| --- | --- | --- | --- |
| Event detail and RSVP flow | Material cards/lists/buttons / pattern | https://m3.material.io/components/cards/overview<br>Also: https://m3.material.io/components/buttons/overview<br>https://m3.material.io/components/chips/overview | Copy an event detail layout: title, date/time, location, host, capacity/status chip, attendee context, RSVP action, and confirmation state. |
| Material Design cards and lists | Material Design 3 / design-system | https://m3.material.io/components/cards/overview<br>Also: https://m3.material.io/components/lists/overview | Use cards/lists only as scannable containers with clear hierarchy, content, metadata, and actions. Do not use repeated cards as the whole primary workflow. |
| Flutter sample app implementation patterns | flutter/samples / open-source | https://github.com/flutter/samples | Copy the separation between app shell, route state, domain widgets, and testable UI states rather than hardcoding a single generic renderer. |
| Material navigation and information architecture | Material Design 3 / design-system | https://m3.material.io/components/navigation-drawer/overview<br>Also: https://m3.material.io/components/navigation-bar/overview | Organize screens by user jobs and destinations; keep primary actions visible and avoid exposing implementation taxonomy. |
| Apple HIG navigation and content organization | Apple Human Interface Guidelines / design-system | https://developer.apple.com/design/human-interface-guidelines/navigation | Make navigation predictable, content-centered, and appropriate for the user’s current task. |
| Form validation and review pattern | U.S. Web Design System / design-system | https://designsystem.digital.gov/components/form/<br>Also: https://designsystem.digital.gov/components/alert/<br>https://design-system.service.gov.uk/components/error-summary/ | Copy a form flow with field labels, helper text, validation errors, review state, submit action, status, and protected-data treatment. |
| Review-and-confirm payment flow | GOV.UK Design System / design-system | https://design-system.service.gov.uk/patterns/check-answers/ | Use a review/confirmation step with amount, payer context, recipient, fees or entitlement, receipt, and audit trail. |
| Multi-step payment/progress flow | U.S. Web Design System / design-system | https://designsystem.digital.gov/components/step-indicator/ | Use explicit progress states for checkout, review, confirmation, receipt, and entitlement/status. |
| Material detail surface composition | Material Design 3 / design-system | https://m3.material.io/components/cards/overview | Build a domain detail page with primary content, metadata, status, and actions instead of a generic task card. |

### Affected Coverage Rows

Showing 11 of 11 affected coverage rows.

| Coverage row | Community | Workflow | Persona | Missing evidence |
| --- | --- | --- | --- | --- |
| `b25-wp-036-photo-walk-rsvp-community-camera-club-member` | Camera Club | `photo-walk-rsvp` | member |  |
| `b25-wp-037-critique-submission-community-camera-club-member` | Camera Club | `critique-submission` | member |  |
| `b25-wp-038-gear-loan-request-community-camera-club-member` | Camera Club | `gear-loan-request` | member |  |
| `b25-wp-047-ad-off-member-checkout-community-ad-off-member` | Ad-Free Community | `ad-off-member-checkout` | member |  |
| `b25-wp-048-ad-off-community-checkout-community-ad-off-member` | Ad-Free Community | `ad-off-community-checkout` | member |  |
| `b25-wp-049-ad-off-entitlement-status-community-ad-off-member` | Ad-Free Community | `ad-off-entitlement-status` | member |  |
| `b25-wp-050-ad-off-receipt-evidence-community-ad-off-member` | Ad-Free Community | `ad-off-receipt-evidence` | member |  |
| `b25-wp-051-ad-off-ad-suppression-community-ad-off-member` | Ad-Free Community | `ad-off-ad-suppression` | member |  |
| `b25-wp-052-ad-off-settlement-utility-community-ad-off-member` | Ad-Free Community | `ad-off-settlement-utility` | member |  |
| `b25-wp-067-wf-multi-persona-workflow-evidence-community-mosque-admin` | Masjid Nur | `wf_multi-persona-workflow-evidence` | admin |  |
| `b25-wp-068-wf-multi-persona-workflow-evidence-community-mosque-member` | Masjid Nur | `wf_multi-persona-workflow-evidence` | member |  |

### Affected Screen Rows

Showing 30 of 72 affected screen rows.

| Screen row | Community | Workflow | Persona | State | Exact UX failure |
| --- | --- | --- | --- | --- | --- |
| `b25-v4-row-034-soccer-team-roster-0` | Riverside Youth Soccer | `soccer-team-roster` | coach | B14_ext_youth_soccer_soccer-team-roster_start | No row-specific failure recorded. |
| `b25-v4-row-035-soccer-team-roster-1` | Riverside Youth Soccer | `soccer-team-roster` | coach | B14_ext_youth_soccer_soccer-team-roster_action | No row-specific failure recorded. |
| `b25-v4-row-036-soccer-team-roster-2` | Riverside Youth Soccer | `soccer-team-roster` | coach | B14_ext_youth_soccer_soccer-team-roster_complete | No row-specific failure recorded. |
| `b25-v4-row-040-soccer-registration-payment-0` | Riverside Youth Soccer | `soccer-registration-payment` | guardian | B14_ext_youth_soccer_soccer-registration-payment_start | No row-specific failure recorded. |
| `b25-v4-row-041-soccer-registration-payment-1` | Riverside Youth Soccer | `soccer-registration-payment` | guardian | B14_ext_youth_soccer_soccer-registration-payment_action | No row-specific failure recorded. |
| `b25-v4-row-042-soccer-registration-payment-2` | Riverside Youth Soccer | `soccer-registration-payment` | guardian | B14_ext_youth_soccer_soccer-registration-payment_complete | No row-specific failure recorded. |
| `b25-v4-row-043-soccer-practice-schedule-0` | Riverside Youth Soccer | `soccer-practice-schedule` | guardian | B14_ext_youth_soccer_soccer-practice-schedule_start | No row-specific failure recorded. |
| `b25-v4-row-044-soccer-practice-schedule-1` | Riverside Youth Soccer | `soccer-practice-schedule` | guardian | B14_ext_youth_soccer_soccer-practice-schedule_action | No row-specific failure recorded. |
| `b25-v4-row-045-soccer-practice-schedule-2` | Riverside Youth Soccer | `soccer-practice-schedule` | guardian | B14_ext_youth_soccer_soccer-practice-schedule_complete | No row-specific failure recorded. |
| `b25-v4-row-049-soccer-export-metadata-0` | Riverside Youth Soccer | `soccer-export-metadata` | owner | B14_ext_youth_soccer_soccer-export-metadata_start | No row-specific failure recorded. |
| `b25-v4-row-050-soccer-export-metadata-1` | Riverside Youth Soccer | `soccer-export-metadata` | owner | B14_ext_youth_soccer_soccer-export-metadata_action | No row-specific failure recorded. |
| `b25-v4-row-051-soccer-export-metadata-2` | Riverside Youth Soccer | `soccer-export-metadata` | owner | B14_ext_youth_soccer_soccer-export-metadata_complete | No row-specific failure recorded. |
| `b25-v4-row-052-hoa-dues-payment-0` | Cedar Commons HOA | `hoa-dues-payment` | member | B14_ext_hoa_hoa-dues-payment_start | No row-specific failure recorded. |
| `b25-v4-row-053-hoa-dues-payment-1` | Cedar Commons HOA | `hoa-dues-payment` | member | B14_ext_hoa_hoa-dues-payment_action | No row-specific failure recorded. |
| `b25-v4-row-054-hoa-dues-payment-2` | Cedar Commons HOA | `hoa-dues-payment` | member | B14_ext_hoa_hoa-dues-payment_complete | No row-specific failure recorded. |
| `b25-v4-row-082-mosque-donor-visibility-0` | Masjid Nur | `mosque-donor-visibility` | donor | B14_ext_mosque_mosque-donor-visibility_start | No row-specific failure recorded. |
| `b25-v4-row-083-mosque-donor-visibility-1` | Masjid Nur | `mosque-donor-visibility` | donor | B14_ext_mosque_mosque-donor-visibility_action | No row-specific failure recorded. |
| `b25-v4-row-084-mosque-donor-visibility-2` | Masjid Nur | `mosque-donor-visibility` | donor | B14_ext_mosque_mosque-donor-visibility_complete | No row-specific failure recorded. |
| `b25-v4-row-085-mosque-donation-payment-0` | Masjid Nur | `mosque-donation-payment` | donor | B14_ext_mosque_mosque-donation-payment_start | No row-specific failure recorded. |
| `b25-v4-row-086-mosque-donation-payment-1` | Masjid Nur | `mosque-donation-payment` | donor | B14_ext_mosque_mosque-donation-payment_action | No row-specific failure recorded. |
| `b25-v4-row-087-mosque-donation-payment-2` | Masjid Nur | `mosque-donation-payment` | donor | B14_ext_mosque_mosque-donation-payment_complete | No row-specific failure recorded. |
| `b25-v4-row-088-mosque-care-request-0` | Masjid Nur | `mosque-care-request` | member | B14_ext_mosque_mosque-care-request_start | No row-specific failure recorded. |
| `b25-v4-row-089-mosque-care-request-1` | Masjid Nur | `mosque-care-request` | member | B14_ext_mosque_mosque-care-request_action | No row-specific failure recorded. |
| `b25-v4-row-090-mosque-care-request-2` | Masjid Nur | `mosque-care-request` | member | B14_ext_mosque_mosque-care-request_complete | No row-specific failure recorded. |
| `b25-v4-row-091-mosque-neutral-notification-0` | Masjid Nur | `mosque-neutral-notification` | member | B14_ext_mosque_mosque-neutral-notification_start | No row-specific failure recorded. |
| `b25-v4-row-092-mosque-neutral-notification-1` | Masjid Nur | `mosque-neutral-notification` | member | B14_ext_mosque_mosque-neutral-notification_action | No row-specific failure recorded. |
| `b25-v4-row-093-mosque-neutral-notification-2` | Masjid Nur | `mosque-neutral-notification` | member | B14_ext_mosque_mosque-neutral-notification_complete | No row-specific failure recorded. |
| `b25-v4-row-106-photo-walk-rsvp-0` | Camera Club | `photo-walk-rsvp` | member | B15_ext_camera_club_photo-walk-rsvp_start | LLM vision critique: The Camera Club experience is partially domain-native, but member-facing copy still exposes renderer/status language and the rows share one repeated action-panel structure instead of distinct event, critique, and gear-loan surfaces. Current row verdict is `fail` with severity `major`. |
| `b25-v4-row-107-photo-walk-rsvp-1` | Camera Club | `photo-walk-rsvp` | member | B15_ext_camera_club_photo-walk-rsvp_action | LLM vision critique: The Camera Club experience is partially domain-native, but member-facing copy still exposes renderer/status language and the rows share one repeated action-panel structure instead of distinct event, critique, and gear-loan surfaces. Current row verdict is `fail` with severity `major`. |
| `b25-v4-row-108-photo-walk-rsvp-2` | Camera Club | `photo-walk-rsvp` | member | B15_ext_camera_club_photo-walk-rsvp_complete | LLM vision critique: The Camera Club experience is partially domain-native, but member-facing copy still exposes renderer/status language and the rows share one repeated action-panel structure instead of distinct event, critique, and gear-loan surfaces. Current row verdict is `fail` with severity `major`. |

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
- Screen row `b25-v4-row-034-soccer-team-roster-0` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-034-soccer-team-roster-0` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-034-soccer-team-roster-0` names visible UI elements, visible text, persona `coach`, workflow `soccer-team-roster`, and the exact product UX issue.
- Primary surface for `soccer-team-roster` is documented as `team roster/schedule surface with role-filtered member details and protected-data treatment` or another explicit domain-native surface.
- After-screenshot visible text proves every required semantic surface group for `soccer-team-roster`.
- Fresh screenshot path/hash/timestamp/app commit SHA are recorded after the fix.
- Screen row `b25-v4-row-035-soccer-team-roster-1` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-035-soccer-team-roster-1` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-035-soccer-team-roster-1` names visible UI elements, visible text, persona `coach`, workflow `soccer-team-roster`, and the exact product UX issue.
- Screen row `b25-v4-row-036-soccer-team-roster-2` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-036-soccer-team-roster-2` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-036-soccer-team-roster-2` names visible UI elements, visible text, persona `coach`, workflow `soccer-team-roster`, and the exact product UX issue.
- Screen row `b25-v4-row-040-soccer-registration-payment-0` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-040-soccer-registration-payment-0` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-040-soccer-registration-payment-0` names visible UI elements, visible text, persona `guardian`, workflow `soccer-registration-payment`, and the exact product UX issue.
- Primary surface for `soccer-registration-payment` is documented as `payment or donation flow with amount, payer context, receipt, entitlement/status, and audit trail` or another explicit domain-native surface.
- After-screenshot visible text proves every required semantic surface group for `soccer-registration-payment`.
- Screen row `b25-v4-row-041-soccer-registration-payment-1` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-041-soccer-registration-payment-1` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-041-soccer-registration-payment-1` names visible UI elements, visible text, persona `guardian`, workflow `soccer-registration-payment`, and the exact product UX issue.
- Screen row `b25-v4-row-042-soccer-registration-payment-2` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-042-soccer-registration-payment-2` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-042-soccer-registration-payment-2` names visible UI elements, visible text, persona `guardian`, workflow `soccer-registration-payment`, and the exact product UX issue.
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
- Screen row `b25-v4-row-049-soccer-export-metadata-0` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-049-soccer-export-metadata-0` is extracted from the screenshot or manually transcribed from the screenshot.

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
| Roster/list with protected details | Material Design 3 / design-system | https://m3.material.io/components/data-tables/overview<br>Also: https://m3.material.io/components/lists/overview | Copy a roster with member names, roles, status, role-filtered fields, and clear protected-data redaction. |
| Review-and-confirm payment flow | GOV.UK Design System / design-system | https://design-system.service.gov.uk/patterns/check-answers/ | Use a review/confirmation step with amount, payer context, recipient, fees or entitlement, receipt, and audit trail. |
| Multi-step payment/progress flow | U.S. Web Design System / design-system | https://designsystem.digital.gov/components/step-indicator/ | Use explicit progress states for checkout, review, confirmation, receipt, and entitlement/status. |
| Event detail and RSVP flow | Material cards/lists/buttons / pattern | https://m3.material.io/components/cards/overview<br>Also: https://m3.material.io/components/buttons/overview<br>https://m3.material.io/components/chips/overview | Copy an event detail layout: title, date/time, location, host, capacity/status chip, attendee context, RSVP action, and confirmation state. |
| Task list and export wizard | GOV.UK Design System / design-system | https://design-system.service.gov.uk/components/task-list/<br>Also: https://design-system.service.gov.uk/patterns/check-answers/ | Copy a wizard with steps, preview, redaction choices, checksum evidence, transfer status, and rollback confirmation. |
| Material detail surface composition | Material Design 3 / design-system | https://m3.material.io/components/cards/overview | Build a domain detail page with primary content, metadata, status, and actions instead of a generic task card. |
| Form validation and review pattern | U.S. Web Design System / design-system | https://designsystem.digital.gov/components/form/<br>Also: https://designsystem.digital.gov/components/alert/<br>https://design-system.service.gov.uk/components/error-summary/ | Copy a form flow with field labels, helper text, validation errors, review state, submit action, status, and protected-data treatment. |
| Inbox and message thread pattern | Material lists/text fields / pattern | https://m3.material.io/components/lists/overview<br>Also: https://m3.material.io/components/text-fields/overview | Copy an inbox/thread structure: sender, timestamp, message preview/body, reply field, invite/block state, and read/received state. |

### Reference Research Queries
- modern mobile app information architecture visual hierarchy examples
- Material Design 3 mobile UI hierarchy navigation cards examples
- open source Flutter production app dashboard detail screen examples
- open source Flutter roster-list mobile UI example GitHub
- team roster/schedule surface with role-filtered member details and protected-data treatment mobile UX pattern
- Material Design team roster/schedule surface with role-filtered member details and protected-data treatment mobile pattern
- open source Flutter payment-donation mobile UI example GitHub
- payment or donation flow with amount, payer context, receipt, entitlement/status, and audit trail mobile UX pattern
- Material Design payment or donation flow with amount, payer context, receipt, entitlement/status, and audit trail mobile pattern
- government design system payment or donation flow with amount, payer context, receipt, entitlement/status, and audit trail form review confirmation pattern
- open source Flutter event-rsvp mobile UI example GitHub
- event detail with schedule, location, capacity/status, RSVP action, and result state mobile UX pattern
- Material Design event detail with schedule, location, capacity/status, RSVP action, and result state mobile pattern
- open source Flutter export-wizard mobile UI example GitHub
- export/import wizard with preview, redaction, checksum, transfer status, and rollback state mobile UX pattern
- Material Design export/import wizard with preview, redaction, checksum, transfer status, and rollback state mobile pattern
- open source Flutter domain-native-surface mobile UI example GitHub
- donor privacy preference surface with visibility choice, donation context, confirmation, and receipt visibility state mobile UX pattern
- Material Design donor privacy preference surface with visibility choice, donation context, confirmation, and receipt visibility state mobile pattern
- open source Flutter form-review mobile UI example GitHub

### UI Remediation Work Items

Showing 24 of 24 work items. Full detail is in the JSON artifact.

| Work item | Stage | Community | Workflow | Persona | Screens | Coverage | Target surface | Blocked until |
| --- | --- | --- | --- | --- | ---: | ---: | --- | --- |
| `b25-wi-ui-remediation-community-youth-soccer-soccer-team-roster-community-youth-soccer-coach` | `ui-remediation` | Riverside Youth Soccer | `soccer-team-roster` | coach | 3 | 0 | team roster/schedule surface with role-filtered member details and protected-data treatment | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-youth-soccer-soccer-registration-payment-community-youth-soccer-guardian` | `ui-remediation` | Riverside Youth Soccer | `soccer-registration-payment` | guardian | 3 | 0 | payment or donation flow with amount, payer context, receipt, entitlement/status, and audit trail | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-youth-soccer-soccer-practice-schedule-community-youth-soccer-guardian` | `ui-remediation` | Riverside Youth Soccer | `soccer-practice-schedule` | guardian | 3 | 0 | event detail with schedule, location, capacity/status, RSVP action, and result state | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-youth-soccer-soccer-export-metadata-community-youth-soccer-owner` | `ui-remediation` | Riverside Youth Soccer | `soccer-export-metadata` | owner | 3 | 0 | export/import wizard with preview, redaction, checksum, transfer status, and rollback state | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-hoa-hoa-dues-payment-community-hoa-member` | `ui-remediation` | Cedar Commons HOA | `hoa-dues-payment` | member | 3 | 0 | payment or donation flow with amount, payer context, receipt, entitlement/status, and audit trail | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-mosque-mosque-donor-visibility-community-mosque-donor` | `ui-remediation` | Masjid Nur | `mosque-donor-visibility` | donor | 3 | 0 | donor privacy preference surface with visibility choice, donation context, confirmation, and receipt visibility state | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-mosque-mosque-donation-payment-community-mosque-donor` | `ui-remediation` | Masjid Nur | `mosque-donation-payment` | donor | 3 | 0 | payment or donation flow with amount, payer context, receipt, entitlement/status, and audit trail | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-mosque-mosque-care-request-community-mosque-member` | `ui-remediation` | Masjid Nur | `mosque-care-request` | member | 3 | 0 | protected care request form and private response/status surface | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-mosque-mosque-neutral-notification-community-mosque-member` | `ui-remediation` | Masjid Nur | `mosque-neutral-notification` | member | 3 | 0 | notification inbox/detail surface with sender, audience, timestamp, message body, and receiver state | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-camera-club-photo-walk-rsvp-community-camera-club-member` | `ui-remediation` | Camera Club | `photo-walk-rsvp` | member | 3 | 1 | event detail with schedule, location, capacity/status, RSVP action, and result state | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-camera-club-critique-submission-community-camera-club-member` | `ui-remediation` | Camera Club | `critique-submission` | member | 3 | 1 | critique submission/review surface with image/work title, comments, reviewer state, and result | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-camera-club-gear-loan-request-community-camera-club-member` | `ui-remediation` | Camera Club | `gear-loan-request` | member | 3 | 1 | request detail and admin review queue with submitted data, decision action, status, and notification | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-platform-social-platform-blocked-target-community-platform-social-member` | `ui-remediation` | Member Social Space | `platform-blocked-target` | member | 3 | 0 | inbox, message thread, connection card, invite, or block-state surface | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-platform-social-platform-in-stream-ad-community-platform-social-member` | `ui-remediation` | Member Social Space | `platform-in-stream-ad` | member | 3 | 0 | community feed surface with clearly labeled in-stream ad placement, disclosure, content context, and no-blocking interaction state | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-platform-social-platform-top-banner-no-fill-community-platform-social-member` | `ui-remediation` | Member Social Space | `platform-top-banner-no-fill` | member | 3 | 0 | App Shell top banner ad slot no-fill surface with preserved layout, disclosure/reserved space, and no content overlap | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-platform-social-platform-sensitive-no-fill-community-platform-social-member` | `ui-remediation` | Member Social Space | `platform-sensitive-no-fill` | member | 3 | 0 | sensitive-context ad suppression surface with protected content visible and ad slot safely no-filled | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-ad-off-ad-off-member-checkout-community-ad-off-member` | `ui-remediation` | Ad-Free Community | `ad-off-member-checkout` | member | 3 | 1 | payment or donation flow with amount, payer context, receipt, entitlement/status, and audit trail | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-ad-off-ad-off-community-checkout-community-ad-off-member` | `ui-remediation` | Ad-Free Community | `ad-off-community-checkout` | member | 3 | 1 | payment or donation flow with amount, payer context, receipt, entitlement/status, and audit trail | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-ad-off-ad-off-entitlement-status-community-ad-off-member` | `ui-remediation` | Ad-Free Community | `ad-off-entitlement-status` | member | 3 | 1 | payment or donation flow with amount, payer context, receipt, entitlement/status, and audit trail | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-ad-off-ad-off-receipt-evidence-community-ad-off-member` | `ui-remediation` | Ad-Free Community | `ad-off-receipt-evidence` | member | 3 | 1 | payment or donation flow with amount, payer context, receipt, entitlement/status, and audit trail | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-ad-off-ad-off-ad-suppression-community-ad-off-member` | `ui-remediation` | Ad-Free Community | `ad-off-ad-suppression` | member | 3 | 1 | payment or donation flow with amount, payer context, receipt, entitlement/status, and audit trail | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-ad-off-ad-off-settlement-utility-community-ad-off-member` | `ui-remediation` | Ad-Free Community | `ad-off-settlement-utility` | member | 3 | 1 | payment or donation flow with amount, payer context, receipt, entitlement/status, and audit trail | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-mosque-wf-multi-persona-workflow-evidence-community-mosque-admin` | `ui-remediation` | Masjid Nur | `wf_multi-persona-workflow-evidence` | admin | 3 | 1 | multi-persona handoff evidence surface with actor-created state, persona switch, receiver state, and continuation action | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-mosque-wf-multi-persona-workflow-evidence-community-mosque-member` | `ui-remediation` | Masjid Nur | `wf_multi-persona-workflow-evidence` | member | 3 | 1 | multi-persona handoff evidence surface with actor-created state, persona switch, receiver state, and continuation action | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |

### UI Remediation Work Items Reference Patterns

| Reference | Source | URL | What to copy |
| --- | --- | --- | --- |
| Roster/list with protected details | Material Design 3 / design-system | https://m3.material.io/components/data-tables/overview<br>Also: https://m3.material.io/components/lists/overview | Copy a roster with member names, roles, status, role-filtered fields, and clear protected-data redaction. |
| Material Design cards and lists | Material Design 3 / design-system | https://m3.material.io/components/cards/overview<br>Also: https://m3.material.io/components/lists/overview | Use cards/lists only as scannable containers with clear hierarchy, content, metadata, and actions. Do not use repeated cards as the whole primary workflow. |
| Flutter sample app implementation patterns | flutter/samples / open-source | https://github.com/flutter/samples | Copy the separation between app shell, route state, domain widgets, and testable UI states rather than hardcoding a single generic renderer. |
| Material navigation and information architecture | Material Design 3 / design-system | https://m3.material.io/components/navigation-drawer/overview<br>Also: https://m3.material.io/components/navigation-bar/overview | Organize screens by user jobs and destinations; keep primary actions visible and avoid exposing implementation taxonomy. |
| Apple HIG navigation and content organization | Apple Human Interface Guidelines / design-system | https://developer.apple.com/design/human-interface-guidelines/navigation | Make navigation predictable, content-centered, and appropriate for the user’s current task. |
| Review-and-confirm payment flow | GOV.UK Design System / design-system | https://design-system.service.gov.uk/patterns/check-answers/ | Use a review/confirmation step with amount, payer context, recipient, fees or entitlement, receipt, and audit trail. |
| Multi-step payment/progress flow | U.S. Web Design System / design-system | https://designsystem.digital.gov/components/step-indicator/ | Use explicit progress states for checkout, review, confirmation, receipt, and entitlement/status. |
| Event detail and RSVP flow | Material cards/lists/buttons / pattern | https://m3.material.io/components/cards/overview<br>Also: https://m3.material.io/components/buttons/overview<br>https://m3.material.io/components/chips/overview | Copy an event detail layout: title, date/time, location, host, capacity/status chip, attendee context, RSVP action, and confirmation state. |
| Task list and export wizard | GOV.UK Design System / design-system | https://design-system.service.gov.uk/components/task-list/<br>Also: https://design-system.service.gov.uk/patterns/check-answers/ | Copy a wizard with steps, preview, redaction choices, checksum evidence, transfer status, and rollback confirmation. |
| Material detail surface composition | Material Design 3 / design-system | https://m3.material.io/components/cards/overview | Build a domain detail page with primary content, metadata, status, and actions instead of a generic task card. |
| Form validation and review pattern | U.S. Web Design System / design-system | https://designsystem.digital.gov/components/form/<br>Also: https://designsystem.digital.gov/components/alert/<br>https://design-system.service.gov.uk/components/error-summary/ | Copy a form flow with field labels, helper text, validation errors, review state, submit action, status, and protected-data treatment. |
| Inbox and message thread pattern | Material lists/text fields / pattern | https://m3.material.io/components/lists/overview<br>Also: https://m3.material.io/components/text-fields/overview | Copy an inbox/thread structure: sender, timestamp, message preview/body, reply field, invite/block state, and read/received state. |

### Affected Coverage Rows

Showing 11 of 11 affected coverage rows.

| Coverage row | Community | Workflow | Persona | Missing evidence |
| --- | --- | --- | --- | --- |
| `b25-wp-036-photo-walk-rsvp-community-camera-club-member` | Camera Club | `photo-walk-rsvp` | member |  |
| `b25-wp-037-critique-submission-community-camera-club-member` | Camera Club | `critique-submission` | member |  |
| `b25-wp-038-gear-loan-request-community-camera-club-member` | Camera Club | `gear-loan-request` | member |  |
| `b25-wp-047-ad-off-member-checkout-community-ad-off-member` | Ad-Free Community | `ad-off-member-checkout` | member |  |
| `b25-wp-048-ad-off-community-checkout-community-ad-off-member` | Ad-Free Community | `ad-off-community-checkout` | member |  |
| `b25-wp-049-ad-off-entitlement-status-community-ad-off-member` | Ad-Free Community | `ad-off-entitlement-status` | member |  |
| `b25-wp-050-ad-off-receipt-evidence-community-ad-off-member` | Ad-Free Community | `ad-off-receipt-evidence` | member |  |
| `b25-wp-051-ad-off-ad-suppression-community-ad-off-member` | Ad-Free Community | `ad-off-ad-suppression` | member |  |
| `b25-wp-052-ad-off-settlement-utility-community-ad-off-member` | Ad-Free Community | `ad-off-settlement-utility` | member |  |
| `b25-wp-067-wf-multi-persona-workflow-evidence-community-mosque-admin` | Masjid Nur | `wf_multi-persona-workflow-evidence` | admin |  |
| `b25-wp-068-wf-multi-persona-workflow-evidence-community-mosque-member` | Masjid Nur | `wf_multi-persona-workflow-evidence` | member |  |

### Affected Screen Rows

Showing 30 of 72 affected screen rows.

| Screen row | Community | Workflow | Persona | State | Exact UX failure |
| --- | --- | --- | --- | --- | --- |
| `b25-v4-row-034-soccer-team-roster-0` | Riverside Youth Soccer | `soccer-team-roster` | coach | B14_ext_youth_soccer_soccer-team-roster_start | No row-specific failure recorded. |
| `b25-v4-row-035-soccer-team-roster-1` | Riverside Youth Soccer | `soccer-team-roster` | coach | B14_ext_youth_soccer_soccer-team-roster_action | No row-specific failure recorded. |
| `b25-v4-row-036-soccer-team-roster-2` | Riverside Youth Soccer | `soccer-team-roster` | coach | B14_ext_youth_soccer_soccer-team-roster_complete | No row-specific failure recorded. |
| `b25-v4-row-040-soccer-registration-payment-0` | Riverside Youth Soccer | `soccer-registration-payment` | guardian | B14_ext_youth_soccer_soccer-registration-payment_start | No row-specific failure recorded. |
| `b25-v4-row-041-soccer-registration-payment-1` | Riverside Youth Soccer | `soccer-registration-payment` | guardian | B14_ext_youth_soccer_soccer-registration-payment_action | No row-specific failure recorded. |
| `b25-v4-row-042-soccer-registration-payment-2` | Riverside Youth Soccer | `soccer-registration-payment` | guardian | B14_ext_youth_soccer_soccer-registration-payment_complete | No row-specific failure recorded. |
| `b25-v4-row-043-soccer-practice-schedule-0` | Riverside Youth Soccer | `soccer-practice-schedule` | guardian | B14_ext_youth_soccer_soccer-practice-schedule_start | No row-specific failure recorded. |
| `b25-v4-row-044-soccer-practice-schedule-1` | Riverside Youth Soccer | `soccer-practice-schedule` | guardian | B14_ext_youth_soccer_soccer-practice-schedule_action | No row-specific failure recorded. |
| `b25-v4-row-045-soccer-practice-schedule-2` | Riverside Youth Soccer | `soccer-practice-schedule` | guardian | B14_ext_youth_soccer_soccer-practice-schedule_complete | No row-specific failure recorded. |
| `b25-v4-row-049-soccer-export-metadata-0` | Riverside Youth Soccer | `soccer-export-metadata` | owner | B14_ext_youth_soccer_soccer-export-metadata_start | No row-specific failure recorded. |
| `b25-v4-row-050-soccer-export-metadata-1` | Riverside Youth Soccer | `soccer-export-metadata` | owner | B14_ext_youth_soccer_soccer-export-metadata_action | No row-specific failure recorded. |
| `b25-v4-row-051-soccer-export-metadata-2` | Riverside Youth Soccer | `soccer-export-metadata` | owner | B14_ext_youth_soccer_soccer-export-metadata_complete | No row-specific failure recorded. |
| `b25-v4-row-052-hoa-dues-payment-0` | Cedar Commons HOA | `hoa-dues-payment` | member | B14_ext_hoa_hoa-dues-payment_start | No row-specific failure recorded. |
| `b25-v4-row-053-hoa-dues-payment-1` | Cedar Commons HOA | `hoa-dues-payment` | member | B14_ext_hoa_hoa-dues-payment_action | No row-specific failure recorded. |
| `b25-v4-row-054-hoa-dues-payment-2` | Cedar Commons HOA | `hoa-dues-payment` | member | B14_ext_hoa_hoa-dues-payment_complete | No row-specific failure recorded. |
| `b25-v4-row-082-mosque-donor-visibility-0` | Masjid Nur | `mosque-donor-visibility` | donor | B14_ext_mosque_mosque-donor-visibility_start | No row-specific failure recorded. |
| `b25-v4-row-083-mosque-donor-visibility-1` | Masjid Nur | `mosque-donor-visibility` | donor | B14_ext_mosque_mosque-donor-visibility_action | No row-specific failure recorded. |
| `b25-v4-row-084-mosque-donor-visibility-2` | Masjid Nur | `mosque-donor-visibility` | donor | B14_ext_mosque_mosque-donor-visibility_complete | No row-specific failure recorded. |
| `b25-v4-row-085-mosque-donation-payment-0` | Masjid Nur | `mosque-donation-payment` | donor | B14_ext_mosque_mosque-donation-payment_start | No row-specific failure recorded. |
| `b25-v4-row-086-mosque-donation-payment-1` | Masjid Nur | `mosque-donation-payment` | donor | B14_ext_mosque_mosque-donation-payment_action | No row-specific failure recorded. |
| `b25-v4-row-087-mosque-donation-payment-2` | Masjid Nur | `mosque-donation-payment` | donor | B14_ext_mosque_mosque-donation-payment_complete | No row-specific failure recorded. |
| `b25-v4-row-088-mosque-care-request-0` | Masjid Nur | `mosque-care-request` | member | B14_ext_mosque_mosque-care-request_start | No row-specific failure recorded. |
| `b25-v4-row-089-mosque-care-request-1` | Masjid Nur | `mosque-care-request` | member | B14_ext_mosque_mosque-care-request_action | No row-specific failure recorded. |
| `b25-v4-row-090-mosque-care-request-2` | Masjid Nur | `mosque-care-request` | member | B14_ext_mosque_mosque-care-request_complete | No row-specific failure recorded. |
| `b25-v4-row-091-mosque-neutral-notification-0` | Masjid Nur | `mosque-neutral-notification` | member | B14_ext_mosque_mosque-neutral-notification_start | No row-specific failure recorded. |
| `b25-v4-row-092-mosque-neutral-notification-1` | Masjid Nur | `mosque-neutral-notification` | member | B14_ext_mosque_mosque-neutral-notification_action | No row-specific failure recorded. |
| `b25-v4-row-093-mosque-neutral-notification-2` | Masjid Nur | `mosque-neutral-notification` | member | B14_ext_mosque_mosque-neutral-notification_complete | No row-specific failure recorded. |
| `b25-v4-row-106-photo-walk-rsvp-0` | Camera Club | `photo-walk-rsvp` | member | B15_ext_camera_club_photo-walk-rsvp_start | LLM vision critique: The Camera Club experience is partially domain-native, but member-facing copy still exposes renderer/status language and the rows share one repeated action-panel structure instead of distinct event, critique, and gear-loan surfaces. Current row verdict is `fail` with severity `major`. |
| `b25-v4-row-107-photo-walk-rsvp-1` | Camera Club | `photo-walk-rsvp` | member | B15_ext_camera_club_photo-walk-rsvp_action | LLM vision critique: The Camera Club experience is partially domain-native, but member-facing copy still exposes renderer/status language and the rows share one repeated action-panel structure instead of distinct event, critique, and gear-loan surfaces. Current row verdict is `fail` with severity `major`. |
| `b25-v4-row-108-photo-walk-rsvp-2` | Camera Club | `photo-walk-rsvp` | member | B15_ext_camera_club_photo-walk-rsvp_complete | LLM vision critique: The Camera Club experience is partially domain-native, but member-facing copy still exposes renderer/status language and the rows share one repeated action-panel structure instead of distinct event, critique, and gear-loan surfaces. Current row verdict is `fail` with severity `major`. |

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
- Screen row `b25-v4-row-034-soccer-team-roster-0` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-034-soccer-team-roster-0` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-034-soccer-team-roster-0` names visible UI elements, visible text, persona `coach`, workflow `soccer-team-roster`, and the exact product UX issue.
- Primary surface for `soccer-team-roster` is documented as `team roster/schedule surface with role-filtered member details and protected-data treatment` or another explicit domain-native surface.
- After-screenshot visible text proves every required semantic surface group for `soccer-team-roster`.
- Fresh screenshot path/hash/timestamp/app commit SHA are recorded after the fix.
- Screen row `b25-v4-row-035-soccer-team-roster-1` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-035-soccer-team-roster-1` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-035-soccer-team-roster-1` names visible UI elements, visible text, persona `coach`, workflow `soccer-team-roster`, and the exact product UX issue.
- Screen row `b25-v4-row-036-soccer-team-roster-2` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-036-soccer-team-roster-2` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-036-soccer-team-roster-2` names visible UI elements, visible text, persona `coach`, workflow `soccer-team-roster`, and the exact product UX issue.
- Screen row `b25-v4-row-040-soccer-registration-payment-0` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-040-soccer-registration-payment-0` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-040-soccer-registration-payment-0` names visible UI elements, visible text, persona `guardian`, workflow `soccer-registration-payment`, and the exact product UX issue.
- Primary surface for `soccer-registration-payment` is documented as `payment or donation flow with amount, payer context, receipt, entitlement/status, and audit trail` or another explicit domain-native surface.
- After-screenshot visible text proves every required semantic surface group for `soccer-registration-payment`.
- Screen row `b25-v4-row-041-soccer-registration-payment-1` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-041-soccer-registration-payment-1` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-041-soccer-registration-payment-1` names visible UI elements, visible text, persona `guardian`, workflow `soccer-registration-payment`, and the exact product UX issue.
- Screen row `b25-v4-row-042-soccer-registration-payment-2` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-042-soccer-registration-payment-2` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-042-soccer-registration-payment-2` names visible UI elements, visible text, persona `guardian`, workflow `soccer-registration-payment`, and the exact product UX issue.
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
- Screen row `b25-v4-row-049-soccer-export-metadata-0` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-049-soccer-export-metadata-0` is extracted from the screenshot or manually transcribed from the screenshot.

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
| Ticket IDs | B25-RT-001-b25-c01-no-blocker-major, B25-RT-002-b25-c03-production-grade-experience, B25-RT-003-b25-c14-llm-vision-ux-review, B25-RT-004-b25-c04-modern-intentional-ui, B25-RT-005-b25-c05-community-content-ia, B25-RT-006-b25-c06-domain-native-primary-surfaces, B25-RT-007-b25-c13-workflow-lifecycle-complete, B25-RT-008-b25-c08-visible-text-specific-critique, B25-RT-009-b25-c09-no-layout-production-defects |

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
- `app/packages/tooling/loom_ux_judges/lib/loom_ux_judges.dart`
- `docs/Build Plan V2/Evidence/B25/independent-production-ux-review.md`

### UX Reference Patterns To Copy

| Reference | Source | URL | What to copy |
| --- | --- | --- | --- |
| Material navigation and information architecture | Material Design 3 / design-system | https://m3.material.io/components/navigation-drawer/overview<br>Also: https://m3.material.io/components/navigation-bar/overview | Organize screens by user jobs and destinations; keep primary actions visible and avoid exposing implementation taxonomy. |
| Apple HIG navigation and content organization | Apple Human Interface Guidelines / design-system | https://developer.apple.com/design/human-interface-guidelines/navigation | Make navigation predictable, content-centered, and appropriate for the user’s current task. |
| Material Design cards and lists | Material Design 3 / design-system | https://m3.material.io/components/cards/overview<br>Also: https://m3.material.io/components/lists/overview | Use cards/lists only as scannable containers with clear hierarchy, content, metadata, and actions. Do not use repeated cards as the whole primary workflow. |
| Flutter sample app implementation patterns | flutter/samples / open-source | https://github.com/flutter/samples | Copy the separation between app shell, route state, domain widgets, and testable UI states rather than hardcoding a single generic renderer. |
| Roster/list with protected details | Material Design 3 / design-system | https://m3.material.io/components/data-tables/overview<br>Also: https://m3.material.io/components/lists/overview | Copy a roster with member names, roles, status, role-filtered fields, and clear protected-data redaction. |
| Review-and-confirm payment flow | GOV.UK Design System / design-system | https://design-system.service.gov.uk/patterns/check-answers/ | Use a review/confirmation step with amount, payer context, recipient, fees or entitlement, receipt, and audit trail. |
| Multi-step payment/progress flow | U.S. Web Design System / design-system | https://designsystem.digital.gov/components/step-indicator/ | Use explicit progress states for checkout, review, confirmation, receipt, and entitlement/status. |
| Event detail and RSVP flow | Material cards/lists/buttons / pattern | https://m3.material.io/components/cards/overview<br>Also: https://m3.material.io/components/buttons/overview<br>https://m3.material.io/components/chips/overview | Copy an event detail layout: title, date/time, location, host, capacity/status chip, attendee context, RSVP action, and confirmation state. |
| Task list and export wizard | GOV.UK Design System / design-system | https://design-system.service.gov.uk/components/task-list/<br>Also: https://design-system.service.gov.uk/patterns/check-answers/ | Copy a wizard with steps, preview, redaction choices, checksum evidence, transfer status, and rollback confirmation. |
| Material detail surface composition | Material Design 3 / design-system | https://m3.material.io/components/cards/overview | Build a domain detail page with primary content, metadata, status, and actions instead of a generic task card. |
| Form validation and review pattern | U.S. Web Design System / design-system | https://designsystem.digital.gov/components/form/<br>Also: https://designsystem.digital.gov/components/alert/<br>https://design-system.service.gov.uk/components/error-summary/ | Copy a form flow with field labels, helper text, validation errors, review state, submit action, status, and protected-data treatment. |
| Inbox and message thread pattern | Material lists/text fields / pattern | https://m3.material.io/components/lists/overview<br>Also: https://m3.material.io/components/text-fields/overview | Copy an inbox/thread structure: sender, timestamp, message preview/body, reply field, invite/block state, and read/received state. |
| Screenshot-first critique method | B25 production UX gate / methodology | docs/Build Plan V2/Tools/b25-remediation-ticket-template.md | Critique must quote visible UI/text, name the persona and task, compare against the chosen reference pattern, and state the exact fix. |

### Reference Research Queries
- production mobile UX review screenshot critique examples
- open source Flutter mobile app UX patterns GitHub
- open source Flutter roster-list mobile UI example GitHub
- team roster/schedule surface with role-filtered member details and protected-data treatment mobile UX pattern
- Material Design team roster/schedule surface with role-filtered member details and protected-data treatment mobile pattern
- open source Flutter payment-donation mobile UI example GitHub
- payment or donation flow with amount, payer context, receipt, entitlement/status, and audit trail mobile UX pattern
- Material Design payment or donation flow with amount, payer context, receipt, entitlement/status, and audit trail mobile pattern
- government design system payment or donation flow with amount, payer context, receipt, entitlement/status, and audit trail form review confirmation pattern
- open source Flutter event-rsvp mobile UI example GitHub
- event detail with schedule, location, capacity/status, RSVP action, and result state mobile UX pattern
- Material Design event detail with schedule, location, capacity/status, RSVP action, and result state mobile pattern
- open source Flutter export-wizard mobile UI example GitHub
- export/import wizard with preview, redaction, checksum, transfer status, and rollback state mobile UX pattern
- Material Design export/import wizard with preview, redaction, checksum, transfer status, and rollback state mobile pattern
- open source Flutter domain-native-surface mobile UI example GitHub
- donor privacy preference surface with visibility choice, donation context, confirmation, and receipt visibility state mobile UX pattern
- Material Design donor privacy preference surface with visibility choice, donation context, confirmation, and receipt visibility state mobile pattern
- open source Flutter form-review mobile UI example GitHub
- protected care request form and private response/status surface mobile UX pattern

### Product Spec Repair Work Items

Showing 6 of 6 work items. Full detail is in the JSON artifact.

| Work item | Stage | Community | Workflow | Persona | Screens | Coverage | Target surface | Blocked until |
| --- | --- | --- | --- | --- | ---: | ---: | --- | --- |
| `b25-wi-product-spec-interaction-model-riverside-youth-soccer` | `product-spec-update` | Riverside Youth Soccer | `soccer-team-roster, soccer-registration-payment, soccer-practice-schedule, soccer-export-metadata` | product-experience-steward | 12 | 4 | community product experience spec with semantic interaction models | the product doc defines expected decision, required actions, result state, and receiver/continuation state for each failing workflow |
| `b25-wi-product-spec-interaction-model-cedar-commons-hoa` | `product-spec-update` | Cedar Commons HOA | `hoa-dues-payment` | product-experience-steward | 3 | 1 | community product experience spec with semantic interaction models | the product doc defines expected decision, required actions, result state, and receiver/continuation state for each failing workflow |
| `b25-wi-product-spec-interaction-model-masjid-nur` | `product-spec-update` | Masjid Nur | `mosque-donor-visibility, mosque-donation-payment, mosque-care-request, mosque-neutral-notification` | product-experience-steward | 12 | 4 | community product experience spec with semantic interaction models | the product doc defines expected decision, required actions, result state, and receiver/continuation state for each failing workflow |
| `b25-wi-product-spec-interaction-model-camera-club` | `product-spec-update` | Camera Club | `photo-walk-rsvp, critique-submission, gear-loan-request` | product-experience-steward | 9 | 3 | community product experience spec with semantic interaction models | the product doc defines expected decision, required actions, result state, and receiver/continuation state for each failing workflow |
| `b25-wi-product-spec-interaction-model-platform-social` | `product-spec-update` | Member Social Space | `platform-blocked-target, platform-in-stream-ad, platform-top-banner-no-fill, platform-sensitive-no-fill` | product-experience-steward | 12 | 4 | community product experience spec with semantic interaction models | the product doc defines expected decision, required actions, result state, and receiver/continuation state for each failing workflow |
| `b25-wi-product-spec-interaction-model-ad-off` | `product-spec-update` | Ad-Free Community | `ad-off-member-checkout, ad-off-community-checkout, ad-off-entitlement-status, ad-off-receipt-evidence, ad-off-ad-suppression, ad-off-settlement-utility` | product-experience-steward | 18 | 6 | community product experience spec with semantic interaction models | the product doc defines expected decision, required actions, result state, and receiver/continuation state for each failing workflow |

### Evidence Repair Work Items

Showing 24 of 24 work items. Full detail is in the JSON artifact.

| Work item | Stage | Community | Workflow | Persona | Screens | Coverage | Target surface | Blocked until |
| --- | --- | --- | --- | --- | ---: | ---: | --- | --- |
| `b25-wi-evidence-repair-community-camera-club-photo-walk-rsvp-community-camera-club-member` | `evidence-repair` | Camera Club | `photo-walk-rsvp` | member | 3 | 1 | event detail with schedule, location, capacity/status, RSVP action, and result state |  |
| `b25-wi-evidence-repair-community-camera-club-critique-submission-community-camera-club-member` | `evidence-repair` | Camera Club | `critique-submission` | member | 3 | 1 | critique submission/review surface with image/work title, comments, reviewer state, and result |  |
| `b25-wi-evidence-repair-community-camera-club-gear-loan-request-community-camera-club-member` | `evidence-repair` | Camera Club | `gear-loan-request` | member | 3 | 1 | request detail and admin review queue with submitted data, decision action, status, and notification |  |
| `b25-wi-evidence-repair-community-ad-off-ad-off-member-checkout-community-ad-off-member` | `evidence-repair` | Ad-Free Community | `ad-off-member-checkout` | member | 3 | 1 | payment or donation flow with amount, payer context, receipt, entitlement/status, and audit trail |  |
| `b25-wi-evidence-repair-community-ad-off-ad-off-community-checkout-community-ad-off-member` | `evidence-repair` | Ad-Free Community | `ad-off-community-checkout` | member | 3 | 1 | payment or donation flow with amount, payer context, receipt, entitlement/status, and audit trail |  |
| `b25-wi-evidence-repair-community-ad-off-ad-off-entitlement-status-community-ad-off-member` | `evidence-repair` | Ad-Free Community | `ad-off-entitlement-status` | member | 3 | 1 | payment or donation flow with amount, payer context, receipt, entitlement/status, and audit trail |  |
| `b25-wi-evidence-repair-community-ad-off-ad-off-receipt-evidence-community-ad-off-member` | `evidence-repair` | Ad-Free Community | `ad-off-receipt-evidence` | member | 3 | 1 | payment or donation flow with amount, payer context, receipt, entitlement/status, and audit trail |  |
| `b25-wi-evidence-repair-community-ad-off-ad-off-ad-suppression-community-ad-off-member` | `evidence-repair` | Ad-Free Community | `ad-off-ad-suppression` | member | 3 | 1 | payment or donation flow with amount, payer context, receipt, entitlement/status, and audit trail |  |
| `b25-wi-evidence-repair-community-ad-off-ad-off-settlement-utility-community-ad-off-member` | `evidence-repair` | Ad-Free Community | `ad-off-settlement-utility` | member | 3 | 1 | payment or donation flow with amount, payer context, receipt, entitlement/status, and audit trail |  |
| `b25-wi-evidence-repair-community-mosque-wf-multi-persona-workflow-evidence-community-mosque-admin` | `evidence-repair` | Masjid Nur | `wf_multi-persona-workflow-evidence` | admin | 3 | 1 | multi-persona handoff evidence surface with actor-created state, persona switch, receiver state, and continuation action |  |
| `b25-wi-evidence-repair-community-mosque-wf-multi-persona-workflow-evidence-community-mosque-member` | `evidence-repair` | Masjid Nur | `wf_multi-persona-workflow-evidence` | member | 3 | 1 | multi-persona handoff evidence surface with actor-created state, persona switch, receiver state, and continuation action |  |
| `b25-wi-evidence-repair-community-youth-soccer-soccer-team-roster-community-youth-soccer-coach` | `evidence-repair` | Riverside Youth Soccer | `soccer-team-roster` | coach | 3 | 1 | team roster/schedule surface with role-filtered member details and protected-data treatment |  |
| `b25-wi-evidence-repair-community-youth-soccer-soccer-registration-payment-community-youth-soccer-guardian` | `evidence-repair` | Riverside Youth Soccer | `soccer-registration-payment` | guardian | 3 | 1 | payment or donation flow with amount, payer context, receipt, entitlement/status, and audit trail |  |
| `b25-wi-evidence-repair-community-youth-soccer-soccer-practice-schedule-community-youth-soccer-guardian` | `evidence-repair` | Riverside Youth Soccer | `soccer-practice-schedule` | guardian | 3 | 1 | event detail with schedule, location, capacity/status, RSVP action, and result state |  |
| `b25-wi-evidence-repair-community-youth-soccer-soccer-export-metadata-community-youth-soccer-owner` | `evidence-repair` | Riverside Youth Soccer | `soccer-export-metadata` | owner | 3 | 1 | export/import wizard with preview, redaction, checksum, transfer status, and rollback state |  |
| `b25-wi-evidence-repair-community-hoa-hoa-dues-payment-community-hoa-member` | `evidence-repair` | Cedar Commons HOA | `hoa-dues-payment` | member | 3 | 1 | payment or donation flow with amount, payer context, receipt, entitlement/status, and audit trail |  |
| `b25-wi-evidence-repair-community-mosque-mosque-donor-visibility-community-mosque-donor` | `evidence-repair` | Masjid Nur | `mosque-donor-visibility` | donor | 3 | 1 | donor privacy preference surface with visibility choice, donation context, confirmation, and receipt visibility state |  |
| `b25-wi-evidence-repair-community-mosque-mosque-donation-payment-community-mosque-donor` | `evidence-repair` | Masjid Nur | `mosque-donation-payment` | donor | 3 | 1 | payment or donation flow with amount, payer context, receipt, entitlement/status, and audit trail |  |
| `b25-wi-evidence-repair-community-mosque-mosque-care-request-community-mosque-member` | `evidence-repair` | Masjid Nur | `mosque-care-request` | member | 3 | 1 | protected care request form and private response/status surface |  |
| `b25-wi-evidence-repair-community-mosque-mosque-neutral-notification-community-mosque-member` | `evidence-repair` | Masjid Nur | `mosque-neutral-notification` | member | 3 | 1 | notification inbox/detail surface with sender, audience, timestamp, message body, and receiver state |  |
| `b25-wi-evidence-repair-community-platform-social-platform-blocked-target-community-platform-social-member` | `evidence-repair` | Member Social Space | `platform-blocked-target` | member | 3 | 1 | inbox, message thread, connection card, invite, or block-state surface |  |
| `b25-wi-evidence-repair-community-platform-social-platform-in-stream-ad-community-platform-social-member` | `evidence-repair` | Member Social Space | `platform-in-stream-ad` | member | 3 | 1 | community feed surface with clearly labeled in-stream ad placement, disclosure, content context, and no-blocking interaction state |  |
| `b25-wi-evidence-repair-community-platform-social-platform-top-banner-no-fill-community-platform-social-member` | `evidence-repair` | Member Social Space | `platform-top-banner-no-fill` | member | 3 | 1 | App Shell top banner ad slot no-fill surface with preserved layout, disclosure/reserved space, and no content overlap |  |
| `b25-wi-evidence-repair-community-platform-social-platform-sensitive-no-fill-community-platform-social-member` | `evidence-repair` | Member Social Space | `platform-sensitive-no-fill` | member | 3 | 1 | sensitive-context ad suppression surface with protected content visible and ad slot safely no-filled |  |

### Evidence Repair Work Items Reference Patterns

| Reference | Source | URL | What to copy |
| --- | --- | --- | --- |
| Event detail and RSVP flow | Material cards/lists/buttons / pattern | https://m3.material.io/components/cards/overview<br>Also: https://m3.material.io/components/buttons/overview<br>https://m3.material.io/components/chips/overview | Copy an event detail layout: title, date/time, location, host, capacity/status chip, attendee context, RSVP action, and confirmation state. |
| Material Design cards and lists | Material Design 3 / design-system | https://m3.material.io/components/cards/overview<br>Also: https://m3.material.io/components/lists/overview | Use cards/lists only as scannable containers with clear hierarchy, content, metadata, and actions. Do not use repeated cards as the whole primary workflow. |
| Flutter sample app implementation patterns | flutter/samples / open-source | https://github.com/flutter/samples | Copy the separation between app shell, route state, domain widgets, and testable UI states rather than hardcoding a single generic renderer. |
| Material navigation and information architecture | Material Design 3 / design-system | https://m3.material.io/components/navigation-drawer/overview<br>Also: https://m3.material.io/components/navigation-bar/overview | Organize screens by user jobs and destinations; keep primary actions visible and avoid exposing implementation taxonomy. |
| Apple HIG navigation and content organization | Apple Human Interface Guidelines / design-system | https://developer.apple.com/design/human-interface-guidelines/navigation | Make navigation predictable, content-centered, and appropriate for the user’s current task. |
| Form validation and review pattern | U.S. Web Design System / design-system | https://designsystem.digital.gov/components/form/<br>Also: https://designsystem.digital.gov/components/alert/<br>https://design-system.service.gov.uk/components/error-summary/ | Copy a form flow with field labels, helper text, validation errors, review state, submit action, status, and protected-data treatment. |
| Review-and-confirm payment flow | GOV.UK Design System / design-system | https://design-system.service.gov.uk/patterns/check-answers/ | Use a review/confirmation step with amount, payer context, recipient, fees or entitlement, receipt, and audit trail. |
| Multi-step payment/progress flow | U.S. Web Design System / design-system | https://designsystem.digital.gov/components/step-indicator/ | Use explicit progress states for checkout, review, confirmation, receipt, and entitlement/status. |
| Material detail surface composition | Material Design 3 / design-system | https://m3.material.io/components/cards/overview | Build a domain detail page with primary content, metadata, status, and actions instead of a generic task card. |
| Roster/list with protected details | Material Design 3 / design-system | https://m3.material.io/components/data-tables/overview<br>Also: https://m3.material.io/components/lists/overview | Copy a roster with member names, roles, status, role-filtered fields, and clear protected-data redaction. |
| Task list and export wizard | GOV.UK Design System / design-system | https://design-system.service.gov.uk/components/task-list/<br>Also: https://design-system.service.gov.uk/patterns/check-answers/ | Copy a wizard with steps, preview, redaction choices, checksum evidence, transfer status, and rollback confirmation. |
| Inbox and message thread pattern | Material lists/text fields / pattern | https://m3.material.io/components/lists/overview<br>Also: https://m3.material.io/components/text-fields/overview | Copy an inbox/thread structure: sender, timestamp, message preview/body, reply field, invite/block state, and read/received state. |

### UI Remediation Work Items

Showing 24 of 24 work items. Full detail is in the JSON artifact.

| Work item | Stage | Community | Workflow | Persona | Screens | Coverage | Target surface | Blocked until |
| --- | --- | --- | --- | --- | ---: | ---: | --- | --- |
| `b25-wi-ui-remediation-community-youth-soccer-soccer-team-roster-community-youth-soccer-coach` | `ui-remediation` | Riverside Youth Soccer | `soccer-team-roster` | coach | 3 | 1 | team roster/schedule surface with role-filtered member details and protected-data treatment | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-youth-soccer-soccer-registration-payment-community-youth-soccer-guardian` | `ui-remediation` | Riverside Youth Soccer | `soccer-registration-payment` | guardian | 3 | 1 | payment or donation flow with amount, payer context, receipt, entitlement/status, and audit trail | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-youth-soccer-soccer-practice-schedule-community-youth-soccer-guardian` | `ui-remediation` | Riverside Youth Soccer | `soccer-practice-schedule` | guardian | 3 | 1 | event detail with schedule, location, capacity/status, RSVP action, and result state | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-youth-soccer-soccer-export-metadata-community-youth-soccer-owner` | `ui-remediation` | Riverside Youth Soccer | `soccer-export-metadata` | owner | 3 | 1 | export/import wizard with preview, redaction, checksum, transfer status, and rollback state | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-hoa-hoa-dues-payment-community-hoa-member` | `ui-remediation` | Cedar Commons HOA | `hoa-dues-payment` | member | 3 | 1 | payment or donation flow with amount, payer context, receipt, entitlement/status, and audit trail | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-mosque-mosque-donor-visibility-community-mosque-donor` | `ui-remediation` | Masjid Nur | `mosque-donor-visibility` | donor | 3 | 1 | donor privacy preference surface with visibility choice, donation context, confirmation, and receipt visibility state | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-mosque-mosque-donation-payment-community-mosque-donor` | `ui-remediation` | Masjid Nur | `mosque-donation-payment` | donor | 3 | 1 | payment or donation flow with amount, payer context, receipt, entitlement/status, and audit trail | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-mosque-mosque-care-request-community-mosque-member` | `ui-remediation` | Masjid Nur | `mosque-care-request` | member | 3 | 1 | protected care request form and private response/status surface | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-mosque-mosque-neutral-notification-community-mosque-member` | `ui-remediation` | Masjid Nur | `mosque-neutral-notification` | member | 3 | 1 | notification inbox/detail surface with sender, audience, timestamp, message body, and receiver state | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-camera-club-photo-walk-rsvp-community-camera-club-member` | `ui-remediation` | Camera Club | `photo-walk-rsvp` | member | 3 | 1 | event detail with schedule, location, capacity/status, RSVP action, and result state | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-camera-club-critique-submission-community-camera-club-member` | `ui-remediation` | Camera Club | `critique-submission` | member | 3 | 1 | critique submission/review surface with image/work title, comments, reviewer state, and result | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-camera-club-gear-loan-request-community-camera-club-member` | `ui-remediation` | Camera Club | `gear-loan-request` | member | 3 | 1 | request detail and admin review queue with submitted data, decision action, status, and notification | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-platform-social-platform-blocked-target-community-platform-social-member` | `ui-remediation` | Member Social Space | `platform-blocked-target` | member | 3 | 1 | inbox, message thread, connection card, invite, or block-state surface | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-platform-social-platform-in-stream-ad-community-platform-social-member` | `ui-remediation` | Member Social Space | `platform-in-stream-ad` | member | 3 | 1 | community feed surface with clearly labeled in-stream ad placement, disclosure, content context, and no-blocking interaction state | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-platform-social-platform-top-banner-no-fill-community-platform-social-member` | `ui-remediation` | Member Social Space | `platform-top-banner-no-fill` | member | 3 | 1 | App Shell top banner ad slot no-fill surface with preserved layout, disclosure/reserved space, and no content overlap | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-platform-social-platform-sensitive-no-fill-community-platform-social-member` | `ui-remediation` | Member Social Space | `platform-sensitive-no-fill` | member | 3 | 1 | sensitive-context ad suppression surface with protected content visible and ad slot safely no-filled | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-ad-off-ad-off-member-checkout-community-ad-off-member` | `ui-remediation` | Ad-Free Community | `ad-off-member-checkout` | member | 3 | 1 | payment or donation flow with amount, payer context, receipt, entitlement/status, and audit trail | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-ad-off-ad-off-community-checkout-community-ad-off-member` | `ui-remediation` | Ad-Free Community | `ad-off-community-checkout` | member | 3 | 1 | payment or donation flow with amount, payer context, receipt, entitlement/status, and audit trail | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-ad-off-ad-off-entitlement-status-community-ad-off-member` | `ui-remediation` | Ad-Free Community | `ad-off-entitlement-status` | member | 3 | 1 | payment or donation flow with amount, payer context, receipt, entitlement/status, and audit trail | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-ad-off-ad-off-receipt-evidence-community-ad-off-member` | `ui-remediation` | Ad-Free Community | `ad-off-receipt-evidence` | member | 3 | 1 | payment or donation flow with amount, payer context, receipt, entitlement/status, and audit trail | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-ad-off-ad-off-ad-suppression-community-ad-off-member` | `ui-remediation` | Ad-Free Community | `ad-off-ad-suppression` | member | 3 | 1 | payment or donation flow with amount, payer context, receipt, entitlement/status, and audit trail | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-ad-off-ad-off-settlement-utility-community-ad-off-member` | `ui-remediation` | Ad-Free Community | `ad-off-settlement-utility` | member | 3 | 1 | payment or donation flow with amount, payer context, receipt, entitlement/status, and audit trail | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-mosque-wf-multi-persona-workflow-evidence-community-mosque-admin` | `ui-remediation` | Masjid Nur | `wf_multi-persona-workflow-evidence` | admin | 3 | 1 | multi-persona handoff evidence surface with actor-created state, persona switch, receiver state, and continuation action | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-mosque-wf-multi-persona-workflow-evidence-community-mosque-member` | `ui-remediation` | Masjid Nur | `wf_multi-persona-workflow-evidence` | member | 3 | 1 | multi-persona handoff evidence surface with actor-created state, persona switch, receiver state, and continuation action | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |

### UI Remediation Work Items Reference Patterns

| Reference | Source | URL | What to copy |
| --- | --- | --- | --- |
| Roster/list with protected details | Material Design 3 / design-system | https://m3.material.io/components/data-tables/overview<br>Also: https://m3.material.io/components/lists/overview | Copy a roster with member names, roles, status, role-filtered fields, and clear protected-data redaction. |
| Material Design cards and lists | Material Design 3 / design-system | https://m3.material.io/components/cards/overview<br>Also: https://m3.material.io/components/lists/overview | Use cards/lists only as scannable containers with clear hierarchy, content, metadata, and actions. Do not use repeated cards as the whole primary workflow. |
| Flutter sample app implementation patterns | flutter/samples / open-source | https://github.com/flutter/samples | Copy the separation between app shell, route state, domain widgets, and testable UI states rather than hardcoding a single generic renderer. |
| Material navigation and information architecture | Material Design 3 / design-system | https://m3.material.io/components/navigation-drawer/overview<br>Also: https://m3.material.io/components/navigation-bar/overview | Organize screens by user jobs and destinations; keep primary actions visible and avoid exposing implementation taxonomy. |
| Apple HIG navigation and content organization | Apple Human Interface Guidelines / design-system | https://developer.apple.com/design/human-interface-guidelines/navigation | Make navigation predictable, content-centered, and appropriate for the user’s current task. |
| Review-and-confirm payment flow | GOV.UK Design System / design-system | https://design-system.service.gov.uk/patterns/check-answers/ | Use a review/confirmation step with amount, payer context, recipient, fees or entitlement, receipt, and audit trail. |
| Multi-step payment/progress flow | U.S. Web Design System / design-system | https://designsystem.digital.gov/components/step-indicator/ | Use explicit progress states for checkout, review, confirmation, receipt, and entitlement/status. |
| Event detail and RSVP flow | Material cards/lists/buttons / pattern | https://m3.material.io/components/cards/overview<br>Also: https://m3.material.io/components/buttons/overview<br>https://m3.material.io/components/chips/overview | Copy an event detail layout: title, date/time, location, host, capacity/status chip, attendee context, RSVP action, and confirmation state. |
| Task list and export wizard | GOV.UK Design System / design-system | https://design-system.service.gov.uk/components/task-list/<br>Also: https://design-system.service.gov.uk/patterns/check-answers/ | Copy a wizard with steps, preview, redaction choices, checksum evidence, transfer status, and rollback confirmation. |
| Material detail surface composition | Material Design 3 / design-system | https://m3.material.io/components/cards/overview | Build a domain detail page with primary content, metadata, status, and actions instead of a generic task card. |
| Form validation and review pattern | U.S. Web Design System / design-system | https://designsystem.digital.gov/components/form/<br>Also: https://designsystem.digital.gov/components/alert/<br>https://design-system.service.gov.uk/components/error-summary/ | Copy a form flow with field labels, helper text, validation errors, review state, submit action, status, and protected-data treatment. |
| Inbox and message thread pattern | Material lists/text fields / pattern | https://m3.material.io/components/lists/overview<br>Also: https://m3.material.io/components/text-fields/overview | Copy an inbox/thread structure: sender, timestamp, message preview/body, reply field, invite/block state, and read/received state. |

### Affected Coverage Rows

Showing 24 of 24 affected coverage rows.

| Coverage row | Community | Workflow | Persona | Missing evidence |
| --- | --- | --- | --- | --- |
| `b25-wp-036-photo-walk-rsvp-community-camera-club-member` | Camera Club | `photo-walk-rsvp` | member |  |
| `b25-wp-037-critique-submission-community-camera-club-member` | Camera Club | `critique-submission` | member |  |
| `b25-wp-038-gear-loan-request-community-camera-club-member` | Camera Club | `gear-loan-request` | member |  |
| `b25-wp-047-ad-off-member-checkout-community-ad-off-member` | Ad-Free Community | `ad-off-member-checkout` | member |  |
| `b25-wp-048-ad-off-community-checkout-community-ad-off-member` | Ad-Free Community | `ad-off-community-checkout` | member |  |
| `b25-wp-049-ad-off-entitlement-status-community-ad-off-member` | Ad-Free Community | `ad-off-entitlement-status` | member |  |
| `b25-wp-050-ad-off-receipt-evidence-community-ad-off-member` | Ad-Free Community | `ad-off-receipt-evidence` | member |  |
| `b25-wp-051-ad-off-ad-suppression-community-ad-off-member` | Ad-Free Community | `ad-off-ad-suppression` | member |  |
| `b25-wp-052-ad-off-settlement-utility-community-ad-off-member` | Ad-Free Community | `ad-off-settlement-utility` | member |  |
| `b25-wp-067-wf-multi-persona-workflow-evidence-community-mosque-admin` | Masjid Nur | `wf_multi-persona-workflow-evidence` | admin |  |
| `b25-wp-068-wf-multi-persona-workflow-evidence-community-mosque-member` | Masjid Nur | `wf_multi-persona-workflow-evidence` | member |  |
| `b25-wp-012-soccer-team-roster-community-youth-soccer-coach` | Riverside Youth Soccer | `soccer-team-roster` | coach |  |
| `b25-wp-014-soccer-registration-payment-community-youth-soccer-guardian` | Riverside Youth Soccer | `soccer-registration-payment` | guardian |  |
| `b25-wp-015-soccer-practice-schedule-community-youth-soccer-guardian` | Riverside Youth Soccer | `soccer-practice-schedule` | guardian |  |
| `b25-wp-017-soccer-export-metadata-community-youth-soccer-owner` | Riverside Youth Soccer | `soccer-export-metadata` | owner |  |
| `b25-wp-018-hoa-dues-payment-community-hoa-member` | Cedar Commons HOA | `hoa-dues-payment` | member |  |
| `b25-wp-028-mosque-donor-visibility-community-mosque-donor` | Masjid Nur | `mosque-donor-visibility` | donor |  |
| `b25-wp-029-mosque-donation-payment-community-mosque-donor` | Masjid Nur | `mosque-donation-payment` | donor |  |
| `b25-wp-030-mosque-care-request-community-mosque-member` | Masjid Nur | `mosque-care-request` | member |  |
| `b25-wp-031-mosque-neutral-notification-community-mosque-member` | Masjid Nur | `mosque-neutral-notification` | member |  |
| `b25-wp-042-platform-blocked-target-community-platform-social-member` | Member Social Space | `platform-blocked-target` | member |  |
| `b25-wp-044-platform-in-stream-ad-community-platform-social-member` | Member Social Space | `platform-in-stream-ad` | member |  |
| `b25-wp-045-platform-top-banner-no-fill-community-platform-social-member` | Member Social Space | `platform-top-banner-no-fill` | member |  |
| `b25-wp-046-platform-sensitive-no-fill-community-platform-social-member` | Member Social Space | `platform-sensitive-no-fill` | member |  |

### Affected Screen Rows

Showing 30 of 72 affected screen rows.

| Screen row | Community | Workflow | Persona | State | Exact UX failure |
| --- | --- | --- | --- | --- | --- |
| `b25-v4-row-034-soccer-team-roster-0` | Riverside Youth Soccer | `soccer-team-roster` | coach | B14_ext_youth_soccer_soccer-team-roster_start | No row-specific failure recorded. |
| `b25-v4-row-035-soccer-team-roster-1` | Riverside Youth Soccer | `soccer-team-roster` | coach | B14_ext_youth_soccer_soccer-team-roster_action | No row-specific failure recorded. |
| `b25-v4-row-036-soccer-team-roster-2` | Riverside Youth Soccer | `soccer-team-roster` | coach | B14_ext_youth_soccer_soccer-team-roster_complete | No row-specific failure recorded. |
| `b25-v4-row-040-soccer-registration-payment-0` | Riverside Youth Soccer | `soccer-registration-payment` | guardian | B14_ext_youth_soccer_soccer-registration-payment_start | No row-specific failure recorded. |
| `b25-v4-row-041-soccer-registration-payment-1` | Riverside Youth Soccer | `soccer-registration-payment` | guardian | B14_ext_youth_soccer_soccer-registration-payment_action | No row-specific failure recorded. |
| `b25-v4-row-042-soccer-registration-payment-2` | Riverside Youth Soccer | `soccer-registration-payment` | guardian | B14_ext_youth_soccer_soccer-registration-payment_complete | No row-specific failure recorded. |
| `b25-v4-row-043-soccer-practice-schedule-0` | Riverside Youth Soccer | `soccer-practice-schedule` | guardian | B14_ext_youth_soccer_soccer-practice-schedule_start | No row-specific failure recorded. |
| `b25-v4-row-044-soccer-practice-schedule-1` | Riverside Youth Soccer | `soccer-practice-schedule` | guardian | B14_ext_youth_soccer_soccer-practice-schedule_action | No row-specific failure recorded. |
| `b25-v4-row-045-soccer-practice-schedule-2` | Riverside Youth Soccer | `soccer-practice-schedule` | guardian | B14_ext_youth_soccer_soccer-practice-schedule_complete | No row-specific failure recorded. |
| `b25-v4-row-049-soccer-export-metadata-0` | Riverside Youth Soccer | `soccer-export-metadata` | owner | B14_ext_youth_soccer_soccer-export-metadata_start | No row-specific failure recorded. |
| `b25-v4-row-050-soccer-export-metadata-1` | Riverside Youth Soccer | `soccer-export-metadata` | owner | B14_ext_youth_soccer_soccer-export-metadata_action | No row-specific failure recorded. |
| `b25-v4-row-051-soccer-export-metadata-2` | Riverside Youth Soccer | `soccer-export-metadata` | owner | B14_ext_youth_soccer_soccer-export-metadata_complete | No row-specific failure recorded. |
| `b25-v4-row-052-hoa-dues-payment-0` | Cedar Commons HOA | `hoa-dues-payment` | member | B14_ext_hoa_hoa-dues-payment_start | No row-specific failure recorded. |
| `b25-v4-row-053-hoa-dues-payment-1` | Cedar Commons HOA | `hoa-dues-payment` | member | B14_ext_hoa_hoa-dues-payment_action | No row-specific failure recorded. |
| `b25-v4-row-054-hoa-dues-payment-2` | Cedar Commons HOA | `hoa-dues-payment` | member | B14_ext_hoa_hoa-dues-payment_complete | No row-specific failure recorded. |
| `b25-v4-row-082-mosque-donor-visibility-0` | Masjid Nur | `mosque-donor-visibility` | donor | B14_ext_mosque_mosque-donor-visibility_start | No row-specific failure recorded. |
| `b25-v4-row-083-mosque-donor-visibility-1` | Masjid Nur | `mosque-donor-visibility` | donor | B14_ext_mosque_mosque-donor-visibility_action | No row-specific failure recorded. |
| `b25-v4-row-084-mosque-donor-visibility-2` | Masjid Nur | `mosque-donor-visibility` | donor | B14_ext_mosque_mosque-donor-visibility_complete | No row-specific failure recorded. |
| `b25-v4-row-085-mosque-donation-payment-0` | Masjid Nur | `mosque-donation-payment` | donor | B14_ext_mosque_mosque-donation-payment_start | No row-specific failure recorded. |
| `b25-v4-row-086-mosque-donation-payment-1` | Masjid Nur | `mosque-donation-payment` | donor | B14_ext_mosque_mosque-donation-payment_action | No row-specific failure recorded. |
| `b25-v4-row-087-mosque-donation-payment-2` | Masjid Nur | `mosque-donation-payment` | donor | B14_ext_mosque_mosque-donation-payment_complete | No row-specific failure recorded. |
| `b25-v4-row-088-mosque-care-request-0` | Masjid Nur | `mosque-care-request` | member | B14_ext_mosque_mosque-care-request_start | No row-specific failure recorded. |
| `b25-v4-row-089-mosque-care-request-1` | Masjid Nur | `mosque-care-request` | member | B14_ext_mosque_mosque-care-request_action | No row-specific failure recorded. |
| `b25-v4-row-090-mosque-care-request-2` | Masjid Nur | `mosque-care-request` | member | B14_ext_mosque_mosque-care-request_complete | No row-specific failure recorded. |
| `b25-v4-row-091-mosque-neutral-notification-0` | Masjid Nur | `mosque-neutral-notification` | member | B14_ext_mosque_mosque-neutral-notification_start | No row-specific failure recorded. |
| `b25-v4-row-092-mosque-neutral-notification-1` | Masjid Nur | `mosque-neutral-notification` | member | B14_ext_mosque_mosque-neutral-notification_action | No row-specific failure recorded. |
| `b25-v4-row-093-mosque-neutral-notification-2` | Masjid Nur | `mosque-neutral-notification` | member | B14_ext_mosque_mosque-neutral-notification_complete | No row-specific failure recorded. |
| `b25-v4-row-106-photo-walk-rsvp-0` | Camera Club | `photo-walk-rsvp` | member | B15_ext_camera_club_photo-walk-rsvp_start | LLM vision critique: The Camera Club experience is partially domain-native, but member-facing copy still exposes renderer/status language and the rows share one repeated action-panel structure instead of distinct event, critique, and gear-loan surfaces. Current row verdict is `fail` with severity `major`. |
| `b25-v4-row-107-photo-walk-rsvp-1` | Camera Club | `photo-walk-rsvp` | member | B15_ext_camera_club_photo-walk-rsvp_action | LLM vision critique: The Camera Club experience is partially domain-native, but member-facing copy still exposes renderer/status language and the rows share one repeated action-panel structure instead of distinct event, critique, and gear-loan surfaces. Current row verdict is `fail` with severity `major`. |
| `b25-v4-row-108-photo-walk-rsvp-2` | Camera Club | `photo-walk-rsvp` | member | B15_ext_camera_club_photo-walk-rsvp_complete | LLM vision critique: The Camera Club experience is partially domain-native, but member-facing copy still exposes renderer/status language and the rows share one repeated action-panel structure instead of distinct event, critique, and gear-loan surfaces. Current row verdict is `fail` with severity `major`. |

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
- independent-production-ux-review.json workflowLifecycleScorecards
- b25-workflow-lifecycle-scorecards.md
- Updated review JSON, scorecards, screenshots, remediation log, and tracker evidence for the fixed criterion.
- Fresh holistic screenshots for primary homes, navigation, representative detail surfaces, and representative completion/result states.
- `holisticQuestionAnswers` with visible evidence, score, pass/fail answer, and specific rationale.
- `llmVisionReview` imported from a fresh LLM vision UX judge run against the after screenshots.
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
- Holistic direct-question answers are present, screenshot-backed, non-boilerplate, and pass.
- Every workflow/persona scorecard is present, screenshot-backed, non-boilerplate, and pass.
- Every workflow lifecycle scorecard is present, screenshot-backed, and pass with no missing lifecycle groups.

### Concrete Acceptance Criteria
- Unresolved blocker and major finding counts are both zero.
- `production_ux_judge.dart` has no blocking failure for this criterion.
- `b25_iteration_scorecard.dart` records the ticket as resolved or no longer blocking.
- Screenshots are refreshed and hashes/timestamps/app commit SHA match the reviewed app version.
- Screen row `b25-v4-row-034-soccer-team-roster-0` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-034-soccer-team-roster-0` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-034-soccer-team-roster-0` names visible UI elements, visible text, persona `coach`, workflow `soccer-team-roster`, and the exact product UX issue.
- Primary surface for `soccer-team-roster` is documented as `team roster/schedule surface with role-filtered member details and protected-data treatment` or another explicit domain-native surface.
- After-screenshot visible text proves every required semantic surface group for `soccer-team-roster`.
- Fresh screenshot path/hash/timestamp/app commit SHA are recorded after the fix.
- Screen row `b25-v4-row-035-soccer-team-roster-1` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-035-soccer-team-roster-1` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-035-soccer-team-roster-1` names visible UI elements, visible text, persona `coach`, workflow `soccer-team-roster`, and the exact product UX issue.
- Screen row `b25-v4-row-036-soccer-team-roster-2` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-036-soccer-team-roster-2` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-036-soccer-team-roster-2` names visible UI elements, visible text, persona `coach`, workflow `soccer-team-roster`, and the exact product UX issue.
- Screen row `b25-v4-row-040-soccer-registration-payment-0` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-040-soccer-registration-payment-0` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-040-soccer-registration-payment-0` names visible UI elements, visible text, persona `guardian`, workflow `soccer-registration-payment`, and the exact product UX issue.
- Primary surface for `soccer-registration-payment` is documented as `payment or donation flow with amount, payer context, receipt, entitlement/status, and audit trail` or another explicit domain-native surface.
- After-screenshot visible text proves every required semantic surface group for `soccer-registration-payment`.
- Screen row `b25-v4-row-041-soccer-registration-payment-1` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-041-soccer-registration-payment-1` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-041-soccer-registration-payment-1` names visible UI elements, visible text, persona `guardian`, workflow `soccer-registration-payment`, and the exact product UX issue.
- Screen row `b25-v4-row-042-soccer-registration-payment-2` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-042-soccer-registration-payment-2` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-042-soccer-registration-payment-2` names visible UI elements, visible text, persona `guardian`, workflow `soccer-registration-payment`, and the exact product UX issue.
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
- Screen row `b25-v4-row-049-soccer-export-metadata-0` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-049-soccer-export-metadata-0` is extracted from the screenshot or manually transcribed from the screenshot.

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
