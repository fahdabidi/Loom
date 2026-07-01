# B25 Remediation Plan

| Field | Value |
| --- | --- |
| Review run | `b25-v4-pass-30` |
| Status | `open` |
| Source tickets | `../docs/Build Plan V2/Evidence/B25/b25-remediation-tickets-b25-v4-pass-30.json` |
| Ticket count | 9 |
| Scorecard status | `fail` |
| Remaining blocker/major | 16 |
| Blocking criteria failures | 9 |
| Product spec work items | 6 |
| Evidence repair work items | 14 |
| UI remediation work items | 14 |
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
| Material detail surface composition | Material Design 3 / design-system | https://m3.material.io/components/cards/overview | Build a domain detail page with primary content, metadata, status, and actions instead of a generic task card. |
| Selection and voting pattern | Material chips/cards/buttons / pattern | https://m3.material.io/components/chips/overview<br>Also: https://m3.material.io/components/cards/overview | Copy a nomination/voting surface with choices, current vote state, deadline, selected result, and meeting/discussion context. |
| Search and result list pattern | Material Design 3 / design-system | https://m3.material.io/components/search/overview<br>Also: https://m3.material.io/components/lists/overview | Copy a search layout with query, filters, ranked results, citations/sources, empty/error states, and follow-up actions. |
| Review-and-confirm payment flow | GOV.UK Design System / design-system | https://design-system.service.gov.uk/patterns/check-answers/ | Use a review/confirmation step with amount, payer context, recipient, fees or entitlement, receipt, and audit trail. |
| Multi-step payment/progress flow | U.S. Web Design System / design-system | https://designsystem.digital.gov/components/step-indicator/ | Use explicit progress states for checkout, review, confirmation, receipt, and entitlement/status. |
| Task list and export wizard | GOV.UK Design System / design-system | https://design-system.service.gov.uk/components/task-list/<br>Also: https://design-system.service.gov.uk/patterns/check-answers/ | Copy a wizard with steps, preview, redaction choices, checksum evidence, transfer status, and rollback confirmation. |
| Screenshot-first critique method | B25 production UX gate / methodology | docs/Build Plan V2/Tools/b25-remediation-ticket-template.md | Critique must quote visible UI/text, name the persona and task, compare against the chosen reference pattern, and state the exact fix. |

### Reference Research Queries
- production mobile UX review screenshot critique examples
- open source Flutter mobile app UX patterns GitHub
- open source Flutter roster-list mobile UI example GitHub
- team roster/schedule surface with role-filtered member details and protected-data treatment mobile UX pattern
- Material Design team roster/schedule surface with role-filtered member details and protected-data treatment mobile pattern
- open source Flutter domain-native-surface mobile UI example GitHub
- donor privacy preference surface with visibility choice, donation context, confirmation, and receipt visibility state mobile UX pattern
- Material Design donor privacy preference surface with visibility choice, donation context, confirmation, and receipt visibility state mobile pattern
- open source Flutter voting-selection mobile UI example GitHub
- book club reading/voting surface with nominations, vote state, selected book, meeting context, and discussion mobile UX pattern
- Material Design book club reading/voting surface with nominations, vote state, selected book, meeting context, and discussion mobile pattern
- open source Flutter search-results mobile UI example GitHub
- search/AI answer surface with query, result, citation, source, and follow-up action mobile UX pattern
- Material Design search/AI answer surface with query, result, citation, source, and follow-up action mobile pattern
- notification inbox/detail surface with sender, audience, timestamp, message body, and receiver state mobile UX pattern
- Material Design notification inbox/detail surface with sender, audience, timestamp, message body, and receiver state mobile pattern
- App Shell top banner ad slot no-fill surface with preserved layout, disclosure/reserved space, and no content overlap mobile UX pattern
- Material Design App Shell top banner ad slot no-fill surface with preserved layout, disclosure/reserved space, and no content overlap mobile pattern
- sensitive-context ad suppression surface with protected content visible and ad slot safely no-filled mobile UX pattern
- Material Design sensitive-context ad suppression surface with protected content visible and ad slot safely no-filled mobile pattern

### Evidence Repair Work Items

Showing 3 of 3 work items. Full detail is in the JSON artifact.

| Work item | Stage | Community | Workflow | Persona | Screens | Coverage | Target surface | Blocked until |
| --- | --- | --- | --- | --- | ---: | ---: | --- | --- |
| `b25-wi-evidence-repair-community-ad-off-ad-off-entitlement-status-community-ad-off-member` | `evidence-repair` | Ad-Free Community | `ad-off-entitlement-status` | member | 3 | 1 | payment or donation flow with amount, payer context, receipt, entitlement/status, and audit trail |  |
| `b25-wi-evidence-repair-community-ad-off-ad-off-settlement-utility-community-ad-off-member` | `evidence-repair` | Ad-Free Community | `ad-off-settlement-utility` | member | 3 | 1 | payment or donation flow with amount, payer context, receipt, entitlement/status, and audit trail |  |
| `b25-wi-evidence-repair-community-export-migration-export-protected-redaction-community-export-migration-owner` | `evidence-repair` | Data Portability Community | `export-protected-redaction` | owner | 3 | 1 | export/import wizard with preview, redaction, checksum, transfer status, and rollback state |  |

### Evidence Repair Work Items Reference Patterns

| Reference | Source | URL | What to copy |
| --- | --- | --- | --- |
| Review-and-confirm payment flow | GOV.UK Design System / design-system | https://design-system.service.gov.uk/patterns/check-answers/ | Use a review/confirmation step with amount, payer context, recipient, fees or entitlement, receipt, and audit trail. |
| Multi-step payment/progress flow | U.S. Web Design System / design-system | https://designsystem.digital.gov/components/step-indicator/ | Use explicit progress states for checkout, review, confirmation, receipt, and entitlement/status. |
| Material Design cards and lists | Material Design 3 / design-system | https://m3.material.io/components/cards/overview<br>Also: https://m3.material.io/components/lists/overview | Use cards/lists only as scannable containers with clear hierarchy, content, metadata, and actions. Do not use repeated cards as the whole primary workflow. |
| Flutter sample app implementation patterns | flutter/samples / open-source | https://github.com/flutter/samples | Copy the separation between app shell, route state, domain widgets, and testable UI states rather than hardcoding a single generic renderer. |
| Material navigation and information architecture | Material Design 3 / design-system | https://m3.material.io/components/navigation-drawer/overview<br>Also: https://m3.material.io/components/navigation-bar/overview | Organize screens by user jobs and destinations; keep primary actions visible and avoid exposing implementation taxonomy. |
| Apple HIG navigation and content organization | Apple Human Interface Guidelines / design-system | https://developer.apple.com/design/human-interface-guidelines/navigation | Make navigation predictable, content-centered, and appropriate for the user’s current task. |
| Task list and export wizard | GOV.UK Design System / design-system | https://design-system.service.gov.uk/components/task-list/<br>Also: https://design-system.service.gov.uk/patterns/check-answers/ | Copy a wizard with steps, preview, redaction choices, checksum evidence, transfer status, and rollback confirmation. |

### Affected Coverage Rows

Showing 3 of 3 affected coverage rows.

| Coverage row | Community | Workflow | Persona | Missing evidence |
| --- | --- | --- | --- | --- |
| `b25-wp-050-ad-off-entitlement-status-community-ad-off-member` | Ad-Free Community | `ad-off-entitlement-status` | member |  |
| `b25-wp-051-ad-off-settlement-utility-community-ad-off-member` | Ad-Free Community | `ad-off-settlement-utility` | member |  |
| `b25-wp-052-export-protected-redaction-community-export-migration-owner` | Data Portability Community | `export-protected-redaction` | owner |  |

### Affected Screen Rows

Showing 30 of 33 affected screen rows.

| Screen row | Community | Workflow | Persona | State | Exact UX failure |
| --- | --- | --- | --- | --- | --- |
| `b25-v4-row-016-soccer-team-roster-0` | Riverside Youth Soccer | `soccer-team-roster` | coach | B14_ext_youth_soccer_soccer-team-roster_start | No row-specific failure recorded. |
| `b25-v4-row-017-soccer-team-roster-1` | Riverside Youth Soccer | `soccer-team-roster` | coach | B14_ext_youth_soccer_soccer-team-roster_action | No row-specific failure recorded. |
| `b25-v4-row-018-soccer-team-roster-2` | Riverside Youth Soccer | `soccer-team-roster` | coach | B14_ext_youth_soccer_soccer-team-roster_complete | No row-specific failure recorded. |
| `b25-v4-row-028-mosque-donor-visibility-0` | Masjid Nur | `mosque-donor-visibility` | donor | B14_ext_mosque_mosque-donor-visibility_start | No row-specific failure recorded. |
| `b25-v4-row-029-mosque-donor-visibility-1` | Masjid Nur | `mosque-donor-visibility` | donor | B14_ext_mosque_mosque-donor-visibility_action | No row-specific failure recorded. |
| `b25-v4-row-030-mosque-donor-visibility-2` | Masjid Nur | `mosque-donor-visibility` | donor | B14_ext_mosque_mosque-donor-visibility_complete | No row-specific failure recorded. |
| `b25-v4-row-034-book-vote-0` | Neighborhood Book Club | `book-vote` | member | B14_ext_book_club_book-vote_start | No row-specific failure recorded. |
| `b25-v4-row-035-book-vote-1` | Neighborhood Book Club | `book-vote` | member | B14_ext_book_club_book-vote_action | No row-specific failure recorded. |
| `b25-v4-row-036-book-vote-2` | Neighborhood Book Club | `book-vote` | member | B14_ext_book_club_book-vote_complete | No row-specific failure recorded. |
| `b25-v4-row-037-book-search-ai-digest-0` | Neighborhood Book Club | `book-search-ai-digest` | member | B14_ext_book_club_book-search-ai-digest_start | No row-specific failure recorded. |
| `b25-v4-row-038-book-search-ai-digest-1` | Neighborhood Book Club | `book-search-ai-digest` | member | B14_ext_book_club_book-search-ai-digest_action | No row-specific failure recorded. |
| `b25-v4-row-039-book-search-ai-digest-2` | Neighborhood Book Club | `book-search-ai-digest` | member | B14_ext_book_club_book-search-ai-digest_complete | No row-specific failure recorded. |
| `b25-v4-row-088-hoa-owner-notification-0` | Cedar Commons HOA | `hoa-owner-notification` | owner | B14_ext_hoa_hoa-owner-notification_start | No row-specific failure recorded. |
| `b25-v4-row-089-hoa-owner-notification-1` | Cedar Commons HOA | `hoa-owner-notification` | owner | B14_ext_hoa_hoa-owner-notification_action | No row-specific failure recorded. |
| `b25-v4-row-090-hoa-owner-notification-2` | Cedar Commons HOA | `hoa-owner-notification` | owner | B14_ext_hoa_hoa-owner-notification_complete | No row-specific failure recorded. |
| `b25-v4-row-121-platform-top-banner-no-fill-0` | Member Social Space | `platform-top-banner-no-fill` | member | B16_ext_platform_social_platform-top-banner-no-fill_start | No row-specific failure recorded. |
| `b25-v4-row-122-platform-top-banner-no-fill-1` | Member Social Space | `platform-top-banner-no-fill` | member | B16_ext_platform_social_platform-top-banner-no-fill_action | No row-specific failure recorded. |
| `b25-v4-row-123-platform-top-banner-no-fill-2` | Member Social Space | `platform-top-banner-no-fill` | member | B16_ext_platform_social_platform-top-banner-no-fill_complete | No row-specific failure recorded. |
| `b25-v4-row-145-platform-sensitive-no-fill-0` | Member Social Space | `platform-sensitive-no-fill` | member | B16_ext_platform_social_platform-sensitive-no-fill_start | No row-specific failure recorded. |
| `b25-v4-row-146-platform-sensitive-no-fill-1` | Member Social Space | `platform-sensitive-no-fill` | member | B16_ext_platform_social_platform-sensitive-no-fill_action | No row-specific failure recorded. |
| `b25-v4-row-147-platform-sensitive-no-fill-2` | Member Social Space | `platform-sensitive-no-fill` | member | B16_ext_platform_social_platform-sensitive-no-fill_complete | No row-specific failure recorded. |
| `b25-v4-row-148-ad-off-entitlement-status-0` | Ad-Free Community | `ad-off-entitlement-status` | member | B16_ext_ad_off_ad-off-entitlement-status_start | No row-specific failure recorded. |
| `b25-v4-row-149-ad-off-entitlement-status-1` | Ad-Free Community | `ad-off-entitlement-status` | member | B16_ext_ad_off_ad-off-entitlement-status_action | No row-specific failure recorded. |
| `b25-v4-row-150-ad-off-entitlement-status-2` | Ad-Free Community | `ad-off-entitlement-status` | member | B16_ext_ad_off_ad-off-entitlement-status_complete | No row-specific failure recorded. |
| `b25-v4-row-151-ad-off-settlement-utility-0` | Ad-Free Community | `ad-off-settlement-utility` | member | B16_ext_ad_off_ad-off-settlement-utility_start | No row-specific failure recorded. |
| `b25-v4-row-152-ad-off-settlement-utility-1` | Ad-Free Community | `ad-off-settlement-utility` | member | B16_ext_ad_off_ad-off-settlement-utility_action | No row-specific failure recorded. |
| `b25-v4-row-153-ad-off-settlement-utility-2` | Ad-Free Community | `ad-off-settlement-utility` | member | B16_ext_ad_off_ad-off-settlement-utility_complete | No row-specific failure recorded. |
| `b25-v4-row-154-export-protected-redaction-0` | Data Portability Community | `export-protected-redaction` | owner | B16_ext_export_migration_export-protected-redaction_start | No row-specific failure recorded. |
| `b25-v4-row-155-export-protected-redaction-1` | Data Portability Community | `export-protected-redaction` | owner | B16_ext_export_migration_export-protected-redaction_action | No row-specific failure recorded. |
| `b25-v4-row-156-export-protected-redaction-2` | Data Portability Community | `export-protected-redaction` | owner | B16_ext_export_migration_export-protected-redaction_complete | No row-specific failure recorded. |

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
- Screen row `b25-v4-row-016-soccer-team-roster-0` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-016-soccer-team-roster-0` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-016-soccer-team-roster-0` names visible UI elements, visible text, persona `coach`, workflow `soccer-team-roster`, and the exact product UX issue.
- Primary surface for `soccer-team-roster` is documented as `team roster/schedule surface with role-filtered member details and protected-data treatment` or another explicit domain-native surface.
- After-screenshot visible text proves every required semantic surface group for `soccer-team-roster`.
- Fresh screenshot path/hash/timestamp/app commit SHA are recorded after the fix.
- Screen row `b25-v4-row-017-soccer-team-roster-1` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-017-soccer-team-roster-1` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-017-soccer-team-roster-1` names visible UI elements, visible text, persona `coach`, workflow `soccer-team-roster`, and the exact product UX issue.
- Screen row `b25-v4-row-018-soccer-team-roster-2` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-018-soccer-team-roster-2` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-018-soccer-team-roster-2` names visible UI elements, visible text, persona `coach`, workflow `soccer-team-roster`, and the exact product UX issue.
- Screen row `b25-v4-row-028-mosque-donor-visibility-0` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-028-mosque-donor-visibility-0` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-028-mosque-donor-visibility-0` names visible UI elements, visible text, persona `donor`, workflow `mosque-donor-visibility`, and the exact product UX issue.
- Primary surface for `mosque-donor-visibility` is documented as `donor privacy preference surface with visibility choice, donation context, confirmation, and receipt visibility state` or another explicit domain-native surface.
- After-screenshot visible text proves every required semantic surface group for `mosque-donor-visibility`.
- Screen row `b25-v4-row-029-mosque-donor-visibility-1` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-029-mosque-donor-visibility-1` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-029-mosque-donor-visibility-1` names visible UI elements, visible text, persona `donor`, workflow `mosque-donor-visibility`, and the exact product UX issue.
- Screen row `b25-v4-row-030-mosque-donor-visibility-2` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-030-mosque-donor-visibility-2` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-030-mosque-donor-visibility-2` names visible UI elements, visible text, persona `donor`, workflow `mosque-donor-visibility`, and the exact product UX issue.
- Screen row `b25-v4-row-034-book-vote-0` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-034-book-vote-0` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-034-book-vote-0` names visible UI elements, visible text, persona `member`, workflow `book-vote`, and the exact product UX issue.
- Primary surface for `book-vote` is documented as `book club reading/voting surface with nominations, vote state, selected book, meeting context, and discussion` or another explicit domain-native surface.
- After-screenshot visible text proves every required semantic surface group for `book-vote`.
- Screen row `b25-v4-row-035-book-vote-1` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-035-book-vote-1` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-035-book-vote-1` names visible UI elements, visible text, persona `member`, workflow `book-vote`, and the exact product UX issue.
- Screen row `b25-v4-row-036-book-vote-2` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-036-book-vote-2` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-036-book-vote-2` names visible UI elements, visible text, persona `member`, workflow `book-vote`, and the exact product UX issue.
- Screen row `b25-v4-row-037-book-search-ai-digest-0` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-037-book-search-ai-digest-0` is extracted from the screenshot or manually transcribed from the screenshot.

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
| Material detail surface composition | Material Design 3 / design-system | https://m3.material.io/components/cards/overview | Build a domain detail page with primary content, metadata, status, and actions instead of a generic task card. |
| Selection and voting pattern | Material chips/cards/buttons / pattern | https://m3.material.io/components/chips/overview<br>Also: https://m3.material.io/components/cards/overview | Copy a nomination/voting surface with choices, current vote state, deadline, selected result, and meeting/discussion context. |
| Search and result list pattern | Material Design 3 / design-system | https://m3.material.io/components/search/overview<br>Also: https://m3.material.io/components/lists/overview | Copy a search layout with query, filters, ranked results, citations/sources, empty/error states, and follow-up actions. |
| Review-and-confirm payment flow | GOV.UK Design System / design-system | https://design-system.service.gov.uk/patterns/check-answers/ | Use a review/confirmation step with amount, payer context, recipient, fees or entitlement, receipt, and audit trail. |
| Multi-step payment/progress flow | U.S. Web Design System / design-system | https://designsystem.digital.gov/components/step-indicator/ | Use explicit progress states for checkout, review, confirmation, receipt, and entitlement/status. |
| Task list and export wizard | GOV.UK Design System / design-system | https://design-system.service.gov.uk/components/task-list/<br>Also: https://design-system.service.gov.uk/patterns/check-answers/ | Copy a wizard with steps, preview, redaction choices, checksum evidence, transfer status, and rollback confirmation. |

### Reference Research Queries
- modern mobile app information architecture visual hierarchy examples
- Material Design 3 mobile UI hierarchy navigation cards examples
- open source Flutter production app dashboard detail screen examples
- open source Flutter roster-list mobile UI example GitHub
- team roster/schedule surface with role-filtered member details and protected-data treatment mobile UX pattern
- Material Design team roster/schedule surface with role-filtered member details and protected-data treatment mobile pattern
- open source Flutter domain-native-surface mobile UI example GitHub
- donor privacy preference surface with visibility choice, donation context, confirmation, and receipt visibility state mobile UX pattern
- Material Design donor privacy preference surface with visibility choice, donation context, confirmation, and receipt visibility state mobile pattern
- open source Flutter voting-selection mobile UI example GitHub
- book club reading/voting surface with nominations, vote state, selected book, meeting context, and discussion mobile UX pattern
- Material Design book club reading/voting surface with nominations, vote state, selected book, meeting context, and discussion mobile pattern
- open source Flutter search-results mobile UI example GitHub
- search/AI answer surface with query, result, citation, source, and follow-up action mobile UX pattern
- Material Design search/AI answer surface with query, result, citation, source, and follow-up action mobile pattern
- notification inbox/detail surface with sender, audience, timestamp, message body, and receiver state mobile UX pattern
- Material Design notification inbox/detail surface with sender, audience, timestamp, message body, and receiver state mobile pattern
- App Shell top banner ad slot no-fill surface with preserved layout, disclosure/reserved space, and no content overlap mobile UX pattern
- Material Design App Shell top banner ad slot no-fill surface with preserved layout, disclosure/reserved space, and no content overlap mobile pattern
- sensitive-context ad suppression surface with protected content visible and ad slot safely no-filled mobile UX pattern

### UI Remediation Work Items

Showing 11 of 11 work items. Full detail is in the JSON artifact.

| Work item | Stage | Community | Workflow | Persona | Screens | Coverage | Target surface | Blocked until |
| --- | --- | --- | --- | --- | ---: | ---: | --- | --- |
| `b25-wi-ui-remediation-community-youth-soccer-soccer-team-roster-community-youth-soccer-coach` | `ui-remediation` | Riverside Youth Soccer | `soccer-team-roster` | coach | 3 | 0 | team roster/schedule surface with role-filtered member details and protected-data treatment | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-mosque-mosque-donor-visibility-community-mosque-donor` | `ui-remediation` | Masjid Nur | `mosque-donor-visibility` | donor | 3 | 0 | donor privacy preference surface with visibility choice, donation context, confirmation, and receipt visibility state | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-book-club-book-vote-community-book-club-member` | `ui-remediation` | Neighborhood Book Club | `book-vote` | member | 3 | 0 | book club reading/voting surface with nominations, vote state, selected book, meeting context, and discussion | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-book-club-book-search-ai-digest-community-book-club-member` | `ui-remediation` | Neighborhood Book Club | `book-search-ai-digest` | member | 3 | 0 | search/AI answer surface with query, result, citation, source, and follow-up action | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-hoa-hoa-owner-notification-community-hoa-owner` | `ui-remediation` | Cedar Commons HOA | `hoa-owner-notification` | owner | 3 | 0 | notification inbox/detail surface with sender, audience, timestamp, message body, and receiver state | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-platform-social-platform-top-banner-no-fill-community-platform-social-member` | `ui-remediation` | Member Social Space | `platform-top-banner-no-fill` | member | 3 | 0 | App Shell top banner ad slot no-fill surface with preserved layout, disclosure/reserved space, and no content overlap | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-platform-social-platform-sensitive-no-fill-community-platform-social-member` | `ui-remediation` | Member Social Space | `platform-sensitive-no-fill` | member | 3 | 0 | sensitive-context ad suppression surface with protected content visible and ad slot safely no-filled | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-ad-off-ad-off-entitlement-status-community-ad-off-member` | `ui-remediation` | Ad-Free Community | `ad-off-entitlement-status` | member | 3 | 1 | payment or donation flow with amount, payer context, receipt, entitlement/status, and audit trail | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-ad-off-ad-off-settlement-utility-community-ad-off-member` | `ui-remediation` | Ad-Free Community | `ad-off-settlement-utility` | member | 3 | 1 | payment or donation flow with amount, payer context, receipt, entitlement/status, and audit trail | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-export-migration-export-protected-redaction-community-export-migration-owner` | `ui-remediation` | Data Portability Community | `export-protected-redaction` | owner | 3 | 1 | export/import wizard with preview, redaction, checksum, transfer status, and rollback state | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-platform-social-platform-in-stream-ad-community-platform-social-member` | `ui-remediation` | Member Social Space | `platform-in-stream-ad` | member | 3 | 0 | community feed surface with clearly labeled in-stream ad placement, disclosure, content context, and no-blocking interaction state | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |

### UI Remediation Work Items Reference Patterns

| Reference | Source | URL | What to copy |
| --- | --- | --- | --- |
| Roster/list with protected details | Material Design 3 / design-system | https://m3.material.io/components/data-tables/overview<br>Also: https://m3.material.io/components/lists/overview | Copy a roster with member names, roles, status, role-filtered fields, and clear protected-data redaction. |
| Material Design cards and lists | Material Design 3 / design-system | https://m3.material.io/components/cards/overview<br>Also: https://m3.material.io/components/lists/overview | Use cards/lists only as scannable containers with clear hierarchy, content, metadata, and actions. Do not use repeated cards as the whole primary workflow. |
| Flutter sample app implementation patterns | flutter/samples / open-source | https://github.com/flutter/samples | Copy the separation between app shell, route state, domain widgets, and testable UI states rather than hardcoding a single generic renderer. |
| Material navigation and information architecture | Material Design 3 / design-system | https://m3.material.io/components/navigation-drawer/overview<br>Also: https://m3.material.io/components/navigation-bar/overview | Organize screens by user jobs and destinations; keep primary actions visible and avoid exposing implementation taxonomy. |
| Apple HIG navigation and content organization | Apple Human Interface Guidelines / design-system | https://developer.apple.com/design/human-interface-guidelines/navigation | Make navigation predictable, content-centered, and appropriate for the user’s current task. |
| Material detail surface composition | Material Design 3 / design-system | https://m3.material.io/components/cards/overview | Build a domain detail page with primary content, metadata, status, and actions instead of a generic task card. |
| Selection and voting pattern | Material chips/cards/buttons / pattern | https://m3.material.io/components/chips/overview<br>Also: https://m3.material.io/components/cards/overview | Copy a nomination/voting surface with choices, current vote state, deadline, selected result, and meeting/discussion context. |
| Search and result list pattern | Material Design 3 / design-system | https://m3.material.io/components/search/overview<br>Also: https://m3.material.io/components/lists/overview | Copy a search layout with query, filters, ranked results, citations/sources, empty/error states, and follow-up actions. |
| Review-and-confirm payment flow | GOV.UK Design System / design-system | https://design-system.service.gov.uk/patterns/check-answers/ | Use a review/confirmation step with amount, payer context, recipient, fees or entitlement, receipt, and audit trail. |
| Multi-step payment/progress flow | U.S. Web Design System / design-system | https://designsystem.digital.gov/components/step-indicator/ | Use explicit progress states for checkout, review, confirmation, receipt, and entitlement/status. |
| Task list and export wizard | GOV.UK Design System / design-system | https://design-system.service.gov.uk/components/task-list/<br>Also: https://design-system.service.gov.uk/patterns/check-answers/ | Copy a wizard with steps, preview, redaction choices, checksum evidence, transfer status, and rollback confirmation. |

### Affected Coverage Rows

Showing 3 of 3 affected coverage rows.

| Coverage row | Community | Workflow | Persona | Missing evidence |
| --- | --- | --- | --- | --- |
| `b25-wp-050-ad-off-entitlement-status-community-ad-off-member` | Ad-Free Community | `ad-off-entitlement-status` | member |  |
| `b25-wp-051-ad-off-settlement-utility-community-ad-off-member` | Ad-Free Community | `ad-off-settlement-utility` | member |  |
| `b25-wp-052-export-protected-redaction-community-export-migration-owner` | Data Portability Community | `export-protected-redaction` | owner |  |

### Affected Screen Rows

Showing 30 of 33 affected screen rows.

| Screen row | Community | Workflow | Persona | State | Exact UX failure |
| --- | --- | --- | --- | --- | --- |
| `b25-v4-row-016-soccer-team-roster-0` | Riverside Youth Soccer | `soccer-team-roster` | coach | B14_ext_youth_soccer_soccer-team-roster_start | No row-specific failure recorded. |
| `b25-v4-row-017-soccer-team-roster-1` | Riverside Youth Soccer | `soccer-team-roster` | coach | B14_ext_youth_soccer_soccer-team-roster_action | No row-specific failure recorded. |
| `b25-v4-row-018-soccer-team-roster-2` | Riverside Youth Soccer | `soccer-team-roster` | coach | B14_ext_youth_soccer_soccer-team-roster_complete | No row-specific failure recorded. |
| `b25-v4-row-028-mosque-donor-visibility-0` | Masjid Nur | `mosque-donor-visibility` | donor | B14_ext_mosque_mosque-donor-visibility_start | No row-specific failure recorded. |
| `b25-v4-row-029-mosque-donor-visibility-1` | Masjid Nur | `mosque-donor-visibility` | donor | B14_ext_mosque_mosque-donor-visibility_action | No row-specific failure recorded. |
| `b25-v4-row-030-mosque-donor-visibility-2` | Masjid Nur | `mosque-donor-visibility` | donor | B14_ext_mosque_mosque-donor-visibility_complete | No row-specific failure recorded. |
| `b25-v4-row-034-book-vote-0` | Neighborhood Book Club | `book-vote` | member | B14_ext_book_club_book-vote_start | No row-specific failure recorded. |
| `b25-v4-row-035-book-vote-1` | Neighborhood Book Club | `book-vote` | member | B14_ext_book_club_book-vote_action | No row-specific failure recorded. |
| `b25-v4-row-036-book-vote-2` | Neighborhood Book Club | `book-vote` | member | B14_ext_book_club_book-vote_complete | No row-specific failure recorded. |
| `b25-v4-row-037-book-search-ai-digest-0` | Neighborhood Book Club | `book-search-ai-digest` | member | B14_ext_book_club_book-search-ai-digest_start | No row-specific failure recorded. |
| `b25-v4-row-038-book-search-ai-digest-1` | Neighborhood Book Club | `book-search-ai-digest` | member | B14_ext_book_club_book-search-ai-digest_action | No row-specific failure recorded. |
| `b25-v4-row-039-book-search-ai-digest-2` | Neighborhood Book Club | `book-search-ai-digest` | member | B14_ext_book_club_book-search-ai-digest_complete | No row-specific failure recorded. |
| `b25-v4-row-088-hoa-owner-notification-0` | Cedar Commons HOA | `hoa-owner-notification` | owner | B14_ext_hoa_hoa-owner-notification_start | No row-specific failure recorded. |
| `b25-v4-row-089-hoa-owner-notification-1` | Cedar Commons HOA | `hoa-owner-notification` | owner | B14_ext_hoa_hoa-owner-notification_action | No row-specific failure recorded. |
| `b25-v4-row-090-hoa-owner-notification-2` | Cedar Commons HOA | `hoa-owner-notification` | owner | B14_ext_hoa_hoa-owner-notification_complete | No row-specific failure recorded. |
| `b25-v4-row-121-platform-top-banner-no-fill-0` | Member Social Space | `platform-top-banner-no-fill` | member | B16_ext_platform_social_platform-top-banner-no-fill_start | No row-specific failure recorded. |
| `b25-v4-row-122-platform-top-banner-no-fill-1` | Member Social Space | `platform-top-banner-no-fill` | member | B16_ext_platform_social_platform-top-banner-no-fill_action | No row-specific failure recorded. |
| `b25-v4-row-123-platform-top-banner-no-fill-2` | Member Social Space | `platform-top-banner-no-fill` | member | B16_ext_platform_social_platform-top-banner-no-fill_complete | No row-specific failure recorded. |
| `b25-v4-row-145-platform-sensitive-no-fill-0` | Member Social Space | `platform-sensitive-no-fill` | member | B16_ext_platform_social_platform-sensitive-no-fill_start | No row-specific failure recorded. |
| `b25-v4-row-146-platform-sensitive-no-fill-1` | Member Social Space | `platform-sensitive-no-fill` | member | B16_ext_platform_social_platform-sensitive-no-fill_action | No row-specific failure recorded. |
| `b25-v4-row-147-platform-sensitive-no-fill-2` | Member Social Space | `platform-sensitive-no-fill` | member | B16_ext_platform_social_platform-sensitive-no-fill_complete | No row-specific failure recorded. |
| `b25-v4-row-148-ad-off-entitlement-status-0` | Ad-Free Community | `ad-off-entitlement-status` | member | B16_ext_ad_off_ad-off-entitlement-status_start | No row-specific failure recorded. |
| `b25-v4-row-149-ad-off-entitlement-status-1` | Ad-Free Community | `ad-off-entitlement-status` | member | B16_ext_ad_off_ad-off-entitlement-status_action | No row-specific failure recorded. |
| `b25-v4-row-150-ad-off-entitlement-status-2` | Ad-Free Community | `ad-off-entitlement-status` | member | B16_ext_ad_off_ad-off-entitlement-status_complete | No row-specific failure recorded. |
| `b25-v4-row-151-ad-off-settlement-utility-0` | Ad-Free Community | `ad-off-settlement-utility` | member | B16_ext_ad_off_ad-off-settlement-utility_start | No row-specific failure recorded. |
| `b25-v4-row-152-ad-off-settlement-utility-1` | Ad-Free Community | `ad-off-settlement-utility` | member | B16_ext_ad_off_ad-off-settlement-utility_action | No row-specific failure recorded. |
| `b25-v4-row-153-ad-off-settlement-utility-2` | Ad-Free Community | `ad-off-settlement-utility` | member | B16_ext_ad_off_ad-off-settlement-utility_complete | No row-specific failure recorded. |
| `b25-v4-row-154-export-protected-redaction-0` | Data Portability Community | `export-protected-redaction` | owner | B16_ext_export_migration_export-protected-redaction_start | No row-specific failure recorded. |
| `b25-v4-row-155-export-protected-redaction-1` | Data Portability Community | `export-protected-redaction` | owner | B16_ext_export_migration_export-protected-redaction_action | No row-specific failure recorded. |
| `b25-v4-row-156-export-protected-redaction-2` | Data Portability Community | `export-protected-redaction` | owner | B16_ext_export_migration_export-protected-redaction_complete | No row-specific failure recorded. |

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
- Screen row `b25-v4-row-016-soccer-team-roster-0` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-016-soccer-team-roster-0` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-016-soccer-team-roster-0` names visible UI elements, visible text, persona `coach`, workflow `soccer-team-roster`, and the exact product UX issue.
- Primary surface for `soccer-team-roster` is documented as `team roster/schedule surface with role-filtered member details and protected-data treatment` or another explicit domain-native surface.
- After-screenshot visible text proves every required semantic surface group for `soccer-team-roster`.
- Fresh screenshot path/hash/timestamp/app commit SHA are recorded after the fix.
- Screen row `b25-v4-row-017-soccer-team-roster-1` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-017-soccer-team-roster-1` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-017-soccer-team-roster-1` names visible UI elements, visible text, persona `coach`, workflow `soccer-team-roster`, and the exact product UX issue.
- Screen row `b25-v4-row-018-soccer-team-roster-2` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-018-soccer-team-roster-2` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-018-soccer-team-roster-2` names visible UI elements, visible text, persona `coach`, workflow `soccer-team-roster`, and the exact product UX issue.
- Screen row `b25-v4-row-028-mosque-donor-visibility-0` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-028-mosque-donor-visibility-0` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-028-mosque-donor-visibility-0` names visible UI elements, visible text, persona `donor`, workflow `mosque-donor-visibility`, and the exact product UX issue.
- Primary surface for `mosque-donor-visibility` is documented as `donor privacy preference surface with visibility choice, donation context, confirmation, and receipt visibility state` or another explicit domain-native surface.
- After-screenshot visible text proves every required semantic surface group for `mosque-donor-visibility`.
- Screen row `b25-v4-row-029-mosque-donor-visibility-1` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-029-mosque-donor-visibility-1` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-029-mosque-donor-visibility-1` names visible UI elements, visible text, persona `donor`, workflow `mosque-donor-visibility`, and the exact product UX issue.
- Screen row `b25-v4-row-030-mosque-donor-visibility-2` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-030-mosque-donor-visibility-2` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-030-mosque-donor-visibility-2` names visible UI elements, visible text, persona `donor`, workflow `mosque-donor-visibility`, and the exact product UX issue.
- Screen row `b25-v4-row-034-book-vote-0` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-034-book-vote-0` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-034-book-vote-0` names visible UI elements, visible text, persona `member`, workflow `book-vote`, and the exact product UX issue.
- Primary surface for `book-vote` is documented as `book club reading/voting surface with nominations, vote state, selected book, meeting context, and discussion` or another explicit domain-native surface.
- After-screenshot visible text proves every required semantic surface group for `book-vote`.
- Screen row `b25-v4-row-035-book-vote-1` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-035-book-vote-1` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-035-book-vote-1` names visible UI elements, visible text, persona `member`, workflow `book-vote`, and the exact product UX issue.
- Screen row `b25-v4-row-036-book-vote-2` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-036-book-vote-2` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-036-book-vote-2` names visible UI elements, visible text, persona `member`, workflow `book-vote`, and the exact product UX issue.
- Screen row `b25-v4-row-037-book-search-ai-digest-0` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-037-book-search-ai-digest-0` is extracted from the screenshot or manually transcribed from the screenshot.

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
| Material detail surface composition | Material Design 3 / design-system | https://m3.material.io/components/cards/overview | Build a domain detail page with primary content, metadata, status, and actions instead of a generic task card. |
| Selection and voting pattern | Material chips/cards/buttons / pattern | https://m3.material.io/components/chips/overview<br>Also: https://m3.material.io/components/cards/overview | Copy a nomination/voting surface with choices, current vote state, deadline, selected result, and meeting/discussion context. |
| Search and result list pattern | Material Design 3 / design-system | https://m3.material.io/components/search/overview<br>Also: https://m3.material.io/components/lists/overview | Copy a search layout with query, filters, ranked results, citations/sources, empty/error states, and follow-up actions. |
| Event detail and RSVP flow | Material cards/lists/buttons / pattern | https://m3.material.io/components/cards/overview<br>Also: https://m3.material.io/components/buttons/overview<br>https://m3.material.io/components/chips/overview | Copy an event detail layout: title, date/time, location, host, capacity/status chip, attendee context, RSVP action, and confirmation state. |
| Inbox and message thread pattern | Material lists/text fields / pattern | https://m3.material.io/components/lists/overview<br>Also: https://m3.material.io/components/text-fields/overview | Copy an inbox/thread structure: sender, timestamp, message preview/body, reply field, invite/block state, and read/received state. |
| Review-and-confirm payment flow | GOV.UK Design System / design-system | https://design-system.service.gov.uk/patterns/check-answers/ | Use a review/confirmation step with amount, payer context, recipient, fees or entitlement, receipt, and audit trail. |
| Multi-step payment/progress flow | U.S. Web Design System / design-system | https://designsystem.digital.gov/components/step-indicator/ | Use explicit progress states for checkout, review, confirmation, receipt, and entitlement/status. |
| Task list and export wizard | GOV.UK Design System / design-system | https://design-system.service.gov.uk/components/task-list/<br>Also: https://design-system.service.gov.uk/patterns/check-answers/ | Copy a wizard with steps, preview, redaction choices, checksum evidence, transfer status, and rollback confirmation. |
| Screenshot-first critique method | B25 production UX gate / methodology | docs/Build Plan V2/Tools/b25-remediation-ticket-template.md | Critique must quote visible UI/text, name the persona and task, compare against the chosen reference pattern, and state the exact fix. |

### Reference Research Queries
- production mobile UX review screenshot critique examples
- open source Flutter mobile app UX patterns GitHub
- open source Flutter roster-list mobile UI example GitHub
- team roster/schedule surface with role-filtered member details and protected-data treatment mobile UX pattern
- Material Design team roster/schedule surface with role-filtered member details and protected-data treatment mobile pattern
- open source Flutter domain-native-surface mobile UI example GitHub
- donor privacy preference surface with visibility choice, donation context, confirmation, and receipt visibility state mobile UX pattern
- Material Design donor privacy preference surface with visibility choice, donation context, confirmation, and receipt visibility state mobile pattern
- open source Flutter voting-selection mobile UI example GitHub
- book club reading/voting surface with nominations, vote state, selected book, meeting context, and discussion mobile UX pattern
- Material Design book club reading/voting surface with nominations, vote state, selected book, meeting context, and discussion mobile pattern
- open source Flutter search-results mobile UI example GitHub
- search/AI answer surface with query, result, citation, source, and follow-up action mobile UX pattern
- Material Design search/AI answer surface with query, result, citation, source, and follow-up action mobile pattern
- notification inbox/detail surface with sender, audience, timestamp, message body, and receiver state mobile UX pattern
- Material Design notification inbox/detail surface with sender, audience, timestamp, message body, and receiver state mobile pattern
- open source Flutter event-rsvp mobile UI example GitHub
- event detail with schedule, location, capacity/status, RSVP action, and result state mobile UX pattern
- Material Design event detail with schedule, location, capacity/status, RSVP action, and result state mobile pattern
- open source Flutter message-thread mobile UI example GitHub

### Product Spec Repair Work Items

Showing 6 of 6 work items. Full detail is in the JSON artifact.

| Work item | Stage | Community | Workflow | Persona | Screens | Coverage | Target surface | Blocked until |
| --- | --- | --- | --- | --- | ---: | ---: | --- | --- |
| `b25-wi-product-spec-interaction-model-riverside-youth-soccer` | `product-spec-update` | Riverside Youth Soccer | `soccer-team-roster` | product-experience-steward | 3 | 1 | community product experience spec with semantic interaction models | the product doc defines expected decision, required actions, result state, and receiver/continuation state for each failing workflow |
| `b25-wi-product-spec-interaction-model-masjid-nur` | `product-spec-update` | Masjid Nur | `mosque-donor-visibility` | product-experience-steward | 3 | 1 | community product experience spec with semantic interaction models | the product doc defines expected decision, required actions, result state, and receiver/continuation state for each failing workflow |
| `b25-wi-product-spec-interaction-model-neighborhood-book-club` | `product-spec-update` | Neighborhood Book Club | `book-vote, book-search-ai-digest` | product-experience-steward | 6 | 2 | community product experience spec with semantic interaction models | the product doc defines expected decision, required actions, result state, and receiver/continuation state for each failing workflow |
| `b25-wi-product-spec-interaction-model-cedar-commons-hoa` | `product-spec-update` | Cedar Commons HOA | `hoa-owner-notification` | product-experience-steward | 3 | 1 | community product experience spec with semantic interaction models | the product doc defines expected decision, required actions, result state, and receiver/continuation state for each failing workflow |
| `b25-wi-product-spec-interaction-model-camera-club` | `product-spec-update` | Camera Club | `photo-walk-rsvp` | product-experience-steward | 3 | 1 | community product experience spec with semantic interaction models | the product doc defines expected decision, required actions, result state, and receiver/continuation state for each failing workflow |
| `b25-wi-product-spec-interaction-model-platform-social` | `product-spec-update` | Member Social Space | `platform-blocked-target, platform-top-banner-no-fill, platform-message-stream, platform-sensitive-no-fill, platform-in-stream-ad` | product-experience-steward | 15 | 5 | community product experience spec with semantic interaction models | the product doc defines expected decision, required actions, result state, and receiver/continuation state for each failing workflow |

### Evidence Repair Work Items

Showing 14 of 14 work items. Full detail is in the JSON artifact.

| Work item | Stage | Community | Workflow | Persona | Screens | Coverage | Target surface | Blocked until |
| --- | --- | --- | --- | --- | ---: | ---: | --- | --- |
| `b25-wi-evidence-repair-community-ad-off-ad-off-entitlement-status-community-ad-off-member` | `evidence-repair` | Ad-Free Community | `ad-off-entitlement-status` | member | 3 | 1 | payment or donation flow with amount, payer context, receipt, entitlement/status, and audit trail |  |
| `b25-wi-evidence-repair-community-ad-off-ad-off-settlement-utility-community-ad-off-member` | `evidence-repair` | Ad-Free Community | `ad-off-settlement-utility` | member | 3 | 1 | payment or donation flow with amount, payer context, receipt, entitlement/status, and audit trail |  |
| `b25-wi-evidence-repair-community-export-migration-export-protected-redaction-community-export-migration-owner` | `evidence-repair` | Data Portability Community | `export-protected-redaction` | owner | 3 | 1 | export/import wizard with preview, redaction, checksum, transfer status, and rollback state |  |
| `b25-wi-evidence-repair-community-youth-soccer-soccer-team-roster-community-youth-soccer-coach` | `evidence-repair` | Riverside Youth Soccer | `soccer-team-roster` | coach | 3 | 1 | team roster/schedule surface with role-filtered member details and protected-data treatment |  |
| `b25-wi-evidence-repair-community-mosque-mosque-donor-visibility-community-mosque-donor` | `evidence-repair` | Masjid Nur | `mosque-donor-visibility` | donor | 3 | 1 | donor privacy preference surface with visibility choice, donation context, confirmation, and receipt visibility state |  |
| `b25-wi-evidence-repair-community-book-club-book-vote-community-book-club-member` | `evidence-repair` | Neighborhood Book Club | `book-vote` | member | 3 | 1 | book club reading/voting surface with nominations, vote state, selected book, meeting context, and discussion |  |
| `b25-wi-evidence-repair-community-book-club-book-search-ai-digest-community-book-club-member` | `evidence-repair` | Neighborhood Book Club | `book-search-ai-digest` | member | 3 | 1 | search/AI answer surface with query, result, citation, source, and follow-up action |  |
| `b25-wi-evidence-repair-community-hoa-hoa-owner-notification-community-hoa-owner` | `evidence-repair` | Cedar Commons HOA | `hoa-owner-notification` | owner | 3 | 1 | notification inbox/detail surface with sender, audience, timestamp, message body, and receiver state |  |
| `b25-wi-evidence-repair-community-camera-club-photo-walk-rsvp-community-camera-club-member` | `evidence-repair` | Camera Club | `photo-walk-rsvp` | member | 3 | 1 | event detail with schedule, location, capacity/status, RSVP action, and result state |  |
| `b25-wi-evidence-repair-community-platform-social-platform-blocked-target-community-platform-social-member` | `evidence-repair` | Member Social Space | `platform-blocked-target` | member | 3 | 1 | inbox, message thread, connection card, invite, or block-state surface |  |
| `b25-wi-evidence-repair-community-platform-social-platform-top-banner-no-fill-community-platform-social-member` | `evidence-repair` | Member Social Space | `platform-top-banner-no-fill` | member | 3 | 1 | App Shell top banner ad slot no-fill surface with preserved layout, disclosure/reserved space, and no content overlap |  |
| `b25-wi-evidence-repair-community-platform-social-platform-message-stream-community-platform-social-member` | `evidence-repair` | Member Social Space | `platform-message-stream` | member | 3 | 1 | inbox, message thread, connection card, invite, or block-state surface |  |
| `b25-wi-evidence-repair-community-platform-social-platform-sensitive-no-fill-community-platform-social-member` | `evidence-repair` | Member Social Space | `platform-sensitive-no-fill` | member | 3 | 1 | sensitive-context ad suppression surface with protected content visible and ad slot safely no-filled |  |
| `b25-wi-evidence-repair-community-platform-social-platform-in-stream-ad-community-platform-social-member` | `evidence-repair` | Member Social Space | `platform-in-stream-ad` | member | 3 | 1 | community feed surface with clearly labeled in-stream ad placement, disclosure, content context, and no-blocking interaction state |  |

### Evidence Repair Work Items Reference Patterns

| Reference | Source | URL | What to copy |
| --- | --- | --- | --- |
| Review-and-confirm payment flow | GOV.UK Design System / design-system | https://design-system.service.gov.uk/patterns/check-answers/ | Use a review/confirmation step with amount, payer context, recipient, fees or entitlement, receipt, and audit trail. |
| Multi-step payment/progress flow | U.S. Web Design System / design-system | https://designsystem.digital.gov/components/step-indicator/ | Use explicit progress states for checkout, review, confirmation, receipt, and entitlement/status. |
| Material Design cards and lists | Material Design 3 / design-system | https://m3.material.io/components/cards/overview<br>Also: https://m3.material.io/components/lists/overview | Use cards/lists only as scannable containers with clear hierarchy, content, metadata, and actions. Do not use repeated cards as the whole primary workflow. |
| Flutter sample app implementation patterns | flutter/samples / open-source | https://github.com/flutter/samples | Copy the separation between app shell, route state, domain widgets, and testable UI states rather than hardcoding a single generic renderer. |
| Material navigation and information architecture | Material Design 3 / design-system | https://m3.material.io/components/navigation-drawer/overview<br>Also: https://m3.material.io/components/navigation-bar/overview | Organize screens by user jobs and destinations; keep primary actions visible and avoid exposing implementation taxonomy. |
| Apple HIG navigation and content organization | Apple Human Interface Guidelines / design-system | https://developer.apple.com/design/human-interface-guidelines/navigation | Make navigation predictable, content-centered, and appropriate for the user’s current task. |
| Task list and export wizard | GOV.UK Design System / design-system | https://design-system.service.gov.uk/components/task-list/<br>Also: https://design-system.service.gov.uk/patterns/check-answers/ | Copy a wizard with steps, preview, redaction choices, checksum evidence, transfer status, and rollback confirmation. |
| Roster/list with protected details | Material Design 3 / design-system | https://m3.material.io/components/data-tables/overview<br>Also: https://m3.material.io/components/lists/overview | Copy a roster with member names, roles, status, role-filtered fields, and clear protected-data redaction. |
| Material detail surface composition | Material Design 3 / design-system | https://m3.material.io/components/cards/overview | Build a domain detail page with primary content, metadata, status, and actions instead of a generic task card. |
| Selection and voting pattern | Material chips/cards/buttons / pattern | https://m3.material.io/components/chips/overview<br>Also: https://m3.material.io/components/cards/overview | Copy a nomination/voting surface with choices, current vote state, deadline, selected result, and meeting/discussion context. |
| Search and result list pattern | Material Design 3 / design-system | https://m3.material.io/components/search/overview<br>Also: https://m3.material.io/components/lists/overview | Copy a search layout with query, filters, ranked results, citations/sources, empty/error states, and follow-up actions. |
| Event detail and RSVP flow | Material cards/lists/buttons / pattern | https://m3.material.io/components/cards/overview<br>Also: https://m3.material.io/components/buttons/overview<br>https://m3.material.io/components/chips/overview | Copy an event detail layout: title, date/time, location, host, capacity/status chip, attendee context, RSVP action, and confirmation state. |

### UI Remediation Work Items

Showing 14 of 14 work items. Full detail is in the JSON artifact.

| Work item | Stage | Community | Workflow | Persona | Screens | Coverage | Target surface | Blocked until |
| --- | --- | --- | --- | --- | ---: | ---: | --- | --- |
| `b25-wi-ui-remediation-community-youth-soccer-soccer-team-roster-community-youth-soccer-coach` | `ui-remediation` | Riverside Youth Soccer | `soccer-team-roster` | coach | 3 | 1 | team roster/schedule surface with role-filtered member details and protected-data treatment | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-mosque-mosque-donor-visibility-community-mosque-donor` | `ui-remediation` | Masjid Nur | `mosque-donor-visibility` | donor | 3 | 1 | donor privacy preference surface with visibility choice, donation context, confirmation, and receipt visibility state | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-book-club-book-vote-community-book-club-member` | `ui-remediation` | Neighborhood Book Club | `book-vote` | member | 3 | 1 | book club reading/voting surface with nominations, vote state, selected book, meeting context, and discussion | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-book-club-book-search-ai-digest-community-book-club-member` | `ui-remediation` | Neighborhood Book Club | `book-search-ai-digest` | member | 3 | 1 | search/AI answer surface with query, result, citation, source, and follow-up action | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-hoa-hoa-owner-notification-community-hoa-owner` | `ui-remediation` | Cedar Commons HOA | `hoa-owner-notification` | owner | 3 | 1 | notification inbox/detail surface with sender, audience, timestamp, message body, and receiver state | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-platform-social-platform-top-banner-no-fill-community-platform-social-member` | `ui-remediation` | Member Social Space | `platform-top-banner-no-fill` | member | 3 | 1 | App Shell top banner ad slot no-fill surface with preserved layout, disclosure/reserved space, and no content overlap | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-platform-social-platform-sensitive-no-fill-community-platform-social-member` | `ui-remediation` | Member Social Space | `platform-sensitive-no-fill` | member | 3 | 1 | sensitive-context ad suppression surface with protected content visible and ad slot safely no-filled | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-ad-off-ad-off-entitlement-status-community-ad-off-member` | `ui-remediation` | Ad-Free Community | `ad-off-entitlement-status` | member | 3 | 1 | payment or donation flow with amount, payer context, receipt, entitlement/status, and audit trail | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-ad-off-ad-off-settlement-utility-community-ad-off-member` | `ui-remediation` | Ad-Free Community | `ad-off-settlement-utility` | member | 3 | 1 | payment or donation flow with amount, payer context, receipt, entitlement/status, and audit trail | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-export-migration-export-protected-redaction-community-export-migration-owner` | `ui-remediation` | Data Portability Community | `export-protected-redaction` | owner | 3 | 1 | export/import wizard with preview, redaction, checksum, transfer status, and rollback state | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-platform-social-platform-in-stream-ad-community-platform-social-member` | `ui-remediation` | Member Social Space | `platform-in-stream-ad` | member | 3 | 1 | community feed surface with clearly labeled in-stream ad placement, disclosure, content context, and no-blocking interaction state | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-camera-club-photo-walk-rsvp-community-camera-club-member` | `ui-remediation` | Camera Club | `photo-walk-rsvp` | member | 3 | 1 | event detail with schedule, location, capacity/status, RSVP action, and result state | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-platform-social-platform-blocked-target-community-platform-social-member` | `ui-remediation` | Member Social Space | `platform-blocked-target` | member | 3 | 1 | inbox, message thread, connection card, invite, or block-state surface | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-platform-social-platform-message-stream-community-platform-social-member` | `ui-remediation` | Member Social Space | `platform-message-stream` | member | 3 | 1 | inbox, message thread, connection card, invite, or block-state surface | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |

### UI Remediation Work Items Reference Patterns

| Reference | Source | URL | What to copy |
| --- | --- | --- | --- |
| Roster/list with protected details | Material Design 3 / design-system | https://m3.material.io/components/data-tables/overview<br>Also: https://m3.material.io/components/lists/overview | Copy a roster with member names, roles, status, role-filtered fields, and clear protected-data redaction. |
| Material Design cards and lists | Material Design 3 / design-system | https://m3.material.io/components/cards/overview<br>Also: https://m3.material.io/components/lists/overview | Use cards/lists only as scannable containers with clear hierarchy, content, metadata, and actions. Do not use repeated cards as the whole primary workflow. |
| Flutter sample app implementation patterns | flutter/samples / open-source | https://github.com/flutter/samples | Copy the separation between app shell, route state, domain widgets, and testable UI states rather than hardcoding a single generic renderer. |
| Material navigation and information architecture | Material Design 3 / design-system | https://m3.material.io/components/navigation-drawer/overview<br>Also: https://m3.material.io/components/navigation-bar/overview | Organize screens by user jobs and destinations; keep primary actions visible and avoid exposing implementation taxonomy. |
| Apple HIG navigation and content organization | Apple Human Interface Guidelines / design-system | https://developer.apple.com/design/human-interface-guidelines/navigation | Make navigation predictable, content-centered, and appropriate for the user’s current task. |
| Material detail surface composition | Material Design 3 / design-system | https://m3.material.io/components/cards/overview | Build a domain detail page with primary content, metadata, status, and actions instead of a generic task card. |
| Selection and voting pattern | Material chips/cards/buttons / pattern | https://m3.material.io/components/chips/overview<br>Also: https://m3.material.io/components/cards/overview | Copy a nomination/voting surface with choices, current vote state, deadline, selected result, and meeting/discussion context. |
| Search and result list pattern | Material Design 3 / design-system | https://m3.material.io/components/search/overview<br>Also: https://m3.material.io/components/lists/overview | Copy a search layout with query, filters, ranked results, citations/sources, empty/error states, and follow-up actions. |
| Review-and-confirm payment flow | GOV.UK Design System / design-system | https://design-system.service.gov.uk/patterns/check-answers/ | Use a review/confirmation step with amount, payer context, recipient, fees or entitlement, receipt, and audit trail. |
| Multi-step payment/progress flow | U.S. Web Design System / design-system | https://designsystem.digital.gov/components/step-indicator/ | Use explicit progress states for checkout, review, confirmation, receipt, and entitlement/status. |
| Task list and export wizard | GOV.UK Design System / design-system | https://design-system.service.gov.uk/components/task-list/<br>Also: https://design-system.service.gov.uk/patterns/check-answers/ | Copy a wizard with steps, preview, redaction choices, checksum evidence, transfer status, and rollback confirmation. |
| Event detail and RSVP flow | Material cards/lists/buttons / pattern | https://m3.material.io/components/cards/overview<br>Also: https://m3.material.io/components/buttons/overview<br>https://m3.material.io/components/chips/overview | Copy an event detail layout: title, date/time, location, host, capacity/status chip, attendee context, RSVP action, and confirmation state. |

### Affected Coverage Rows

Showing 14 of 14 affected coverage rows.

| Coverage row | Community | Workflow | Persona | Missing evidence |
| --- | --- | --- | --- | --- |
| `b25-wp-050-ad-off-entitlement-status-community-ad-off-member` | Ad-Free Community | `ad-off-entitlement-status` | member |  |
| `b25-wp-051-ad-off-settlement-utility-community-ad-off-member` | Ad-Free Community | `ad-off-settlement-utility` | member |  |
| `b25-wp-052-export-protected-redaction-community-export-migration-owner` | Data Portability Community | `export-protected-redaction` | owner |  |
| `b25-wp-006-soccer-team-roster-community-youth-soccer-coach` | Riverside Youth Soccer | `soccer-team-roster` | coach |  |
| `b25-wp-010-mosque-donor-visibility-community-mosque-donor` | Masjid Nur | `mosque-donor-visibility` | donor |  |
| `b25-wp-012-book-vote-community-book-club-member` | Neighborhood Book Club | `book-vote` | member |  |
| `b25-wp-013-book-search-ai-digest-community-book-club-member` | Neighborhood Book Club | `book-search-ai-digest` | member |  |
| `b25-wp-030-hoa-owner-notification-community-hoa-owner` | Cedar Commons HOA | `hoa-owner-notification` | owner |  |
| `b25-wp-036-photo-walk-rsvp-community-camera-club-member` | Camera Club | `photo-walk-rsvp` | member |  |
| `b25-wp-040-platform-blocked-target-community-platform-social-member` | Member Social Space | `platform-blocked-target` | member |  |
| `b25-wp-041-platform-top-banner-no-fill-community-platform-social-member` | Member Social Space | `platform-top-banner-no-fill` | member |  |
| `b25-wp-048-platform-message-stream-community-platform-social-member` | Member Social Space | `platform-message-stream` | member |  |
| `b25-wp-049-platform-sensitive-no-fill-community-platform-social-member` | Member Social Space | `platform-sensitive-no-fill` | member |  |
| `b25-wp-056-platform-in-stream-ad-community-platform-social-member` | Member Social Space | `platform-in-stream-ad` | member |  |

### Affected Screen Rows

Showing 30 of 42 affected screen rows.

| Screen row | Community | Workflow | Persona | State | Exact UX failure |
| --- | --- | --- | --- | --- | --- |
| `b25-v4-row-016-soccer-team-roster-0` | Riverside Youth Soccer | `soccer-team-roster` | coach | B14_ext_youth_soccer_soccer-team-roster_start | No row-specific failure recorded. |
| `b25-v4-row-017-soccer-team-roster-1` | Riverside Youth Soccer | `soccer-team-roster` | coach | B14_ext_youth_soccer_soccer-team-roster_action | No row-specific failure recorded. |
| `b25-v4-row-018-soccer-team-roster-2` | Riverside Youth Soccer | `soccer-team-roster` | coach | B14_ext_youth_soccer_soccer-team-roster_complete | No row-specific failure recorded. |
| `b25-v4-row-028-mosque-donor-visibility-0` | Masjid Nur | `mosque-donor-visibility` | donor | B14_ext_mosque_mosque-donor-visibility_start | No row-specific failure recorded. |
| `b25-v4-row-029-mosque-donor-visibility-1` | Masjid Nur | `mosque-donor-visibility` | donor | B14_ext_mosque_mosque-donor-visibility_action | No row-specific failure recorded. |
| `b25-v4-row-030-mosque-donor-visibility-2` | Masjid Nur | `mosque-donor-visibility` | donor | B14_ext_mosque_mosque-donor-visibility_complete | No row-specific failure recorded. |
| `b25-v4-row-034-book-vote-0` | Neighborhood Book Club | `book-vote` | member | B14_ext_book_club_book-vote_start | No row-specific failure recorded. |
| `b25-v4-row-035-book-vote-1` | Neighborhood Book Club | `book-vote` | member | B14_ext_book_club_book-vote_action | No row-specific failure recorded. |
| `b25-v4-row-036-book-vote-2` | Neighborhood Book Club | `book-vote` | member | B14_ext_book_club_book-vote_complete | No row-specific failure recorded. |
| `b25-v4-row-037-book-search-ai-digest-0` | Neighborhood Book Club | `book-search-ai-digest` | member | B14_ext_book_club_book-search-ai-digest_start | No row-specific failure recorded. |
| `b25-v4-row-038-book-search-ai-digest-1` | Neighborhood Book Club | `book-search-ai-digest` | member | B14_ext_book_club_book-search-ai-digest_action | No row-specific failure recorded. |
| `b25-v4-row-039-book-search-ai-digest-2` | Neighborhood Book Club | `book-search-ai-digest` | member | B14_ext_book_club_book-search-ai-digest_complete | No row-specific failure recorded. |
| `b25-v4-row-088-hoa-owner-notification-0` | Cedar Commons HOA | `hoa-owner-notification` | owner | B14_ext_hoa_hoa-owner-notification_start | No row-specific failure recorded. |
| `b25-v4-row-089-hoa-owner-notification-1` | Cedar Commons HOA | `hoa-owner-notification` | owner | B14_ext_hoa_hoa-owner-notification_action | No row-specific failure recorded. |
| `b25-v4-row-090-hoa-owner-notification-2` | Cedar Commons HOA | `hoa-owner-notification` | owner | B14_ext_hoa_hoa-owner-notification_complete | No row-specific failure recorded. |
| `b25-v4-row-106-photo-walk-rsvp-0` | Camera Club | `photo-walk-rsvp` | member | B15_ext_camera_club_photo-walk-rsvp_start | No row-specific failure recorded. |
| `b25-v4-row-107-photo-walk-rsvp-1` | Camera Club | `photo-walk-rsvp` | member | B15_ext_camera_club_photo-walk-rsvp_action | No row-specific failure recorded. |
| `b25-v4-row-108-photo-walk-rsvp-2` | Camera Club | `photo-walk-rsvp` | member | B15_ext_camera_club_photo-walk-rsvp_complete | No row-specific failure recorded. |
| `b25-v4-row-118-platform-blocked-target-0` | Member Social Space | `platform-blocked-target` | member | B16_ext_platform_social_platform-blocked-target_start | No row-specific failure recorded. |
| `b25-v4-row-119-platform-blocked-target-1` | Member Social Space | `platform-blocked-target` | member | B16_ext_platform_social_platform-blocked-target_action | No row-specific failure recorded. |
| `b25-v4-row-120-platform-blocked-target-2` | Member Social Space | `platform-blocked-target` | member | B16_ext_platform_social_platform-blocked-target_complete | No row-specific failure recorded. |
| `b25-v4-row-121-platform-top-banner-no-fill-0` | Member Social Space | `platform-top-banner-no-fill` | member | B16_ext_platform_social_platform-top-banner-no-fill_start | No row-specific failure recorded. |
| `b25-v4-row-122-platform-top-banner-no-fill-1` | Member Social Space | `platform-top-banner-no-fill` | member | B16_ext_platform_social_platform-top-banner-no-fill_action | No row-specific failure recorded. |
| `b25-v4-row-123-platform-top-banner-no-fill-2` | Member Social Space | `platform-top-banner-no-fill` | member | B16_ext_platform_social_platform-top-banner-no-fill_complete | No row-specific failure recorded. |
| `b25-v4-row-142-platform-message-stream-0` | Member Social Space | `platform-message-stream` | member | B16_ext_platform_social_platform-message-stream_start | No row-specific failure recorded. |
| `b25-v4-row-143-platform-message-stream-1` | Member Social Space | `platform-message-stream` | member | B16_ext_platform_social_platform-message-stream_action | No row-specific failure recorded. |
| `b25-v4-row-144-platform-message-stream-2` | Member Social Space | `platform-message-stream` | member | B16_ext_platform_social_platform-message-stream_complete | No row-specific failure recorded. |
| `b25-v4-row-145-platform-sensitive-no-fill-0` | Member Social Space | `platform-sensitive-no-fill` | member | B16_ext_platform_social_platform-sensitive-no-fill_start | No row-specific failure recorded. |
| `b25-v4-row-146-platform-sensitive-no-fill-1` | Member Social Space | `platform-sensitive-no-fill` | member | B16_ext_platform_social_platform-sensitive-no-fill_action | No row-specific failure recorded. |
| `b25-v4-row-147-platform-sensitive-no-fill-2` | Member Social Space | `platform-sensitive-no-fill` | member | B16_ext_platform_social_platform-sensitive-no-fill_complete | No row-specific failure recorded. |

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
- Screen row `b25-v4-row-016-soccer-team-roster-0` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-016-soccer-team-roster-0` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-016-soccer-team-roster-0` names visible UI elements, visible text, persona `coach`, workflow `soccer-team-roster`, and the exact product UX issue.
- Primary surface for `soccer-team-roster` is documented as `team roster/schedule surface with role-filtered member details and protected-data treatment` or another explicit domain-native surface.
- After-screenshot visible text proves every required semantic surface group for `soccer-team-roster`.
- Fresh screenshot path/hash/timestamp/app commit SHA are recorded after the fix.
- Screen row `b25-v4-row-017-soccer-team-roster-1` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-017-soccer-team-roster-1` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-017-soccer-team-roster-1` names visible UI elements, visible text, persona `coach`, workflow `soccer-team-roster`, and the exact product UX issue.
- Screen row `b25-v4-row-018-soccer-team-roster-2` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-018-soccer-team-roster-2` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-018-soccer-team-roster-2` names visible UI elements, visible text, persona `coach`, workflow `soccer-team-roster`, and the exact product UX issue.
- Screen row `b25-v4-row-028-mosque-donor-visibility-0` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-028-mosque-donor-visibility-0` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-028-mosque-donor-visibility-0` names visible UI elements, visible text, persona `donor`, workflow `mosque-donor-visibility`, and the exact product UX issue.
- Primary surface for `mosque-donor-visibility` is documented as `donor privacy preference surface with visibility choice, donation context, confirmation, and receipt visibility state` or another explicit domain-native surface.
- After-screenshot visible text proves every required semantic surface group for `mosque-donor-visibility`.
- Screen row `b25-v4-row-029-mosque-donor-visibility-1` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-029-mosque-donor-visibility-1` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-029-mosque-donor-visibility-1` names visible UI elements, visible text, persona `donor`, workflow `mosque-donor-visibility`, and the exact product UX issue.
- Screen row `b25-v4-row-030-mosque-donor-visibility-2` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-030-mosque-donor-visibility-2` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-030-mosque-donor-visibility-2` names visible UI elements, visible text, persona `donor`, workflow `mosque-donor-visibility`, and the exact product UX issue.
- Screen row `b25-v4-row-034-book-vote-0` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-034-book-vote-0` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-034-book-vote-0` names visible UI elements, visible text, persona `member`, workflow `book-vote`, and the exact product UX issue.
- Primary surface for `book-vote` is documented as `book club reading/voting surface with nominations, vote state, selected book, meeting context, and discussion` or another explicit domain-native surface.
- After-screenshot visible text proves every required semantic surface group for `book-vote`.
- Screen row `b25-v4-row-035-book-vote-1` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-035-book-vote-1` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-035-book-vote-1` names visible UI elements, visible text, persona `member`, workflow `book-vote`, and the exact product UX issue.
- Screen row `b25-v4-row-036-book-vote-2` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-036-book-vote-2` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-036-book-vote-2` names visible UI elements, visible text, persona `member`, workflow `book-vote`, and the exact product UX issue.
- Screen row `b25-v4-row-037-book-search-ai-digest-0` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-037-book-search-ai-digest-0` is extracted from the screenshot or manually transcribed from the screenshot.

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
