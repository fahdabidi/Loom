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
- The independent judge must rerun after each batch that changes UI, evidence, or critique.
- No next UX feedback loop starts until the current remediation iteration is committed.
