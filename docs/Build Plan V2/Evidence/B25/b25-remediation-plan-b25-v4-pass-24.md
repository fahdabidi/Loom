# B25 Remediation Plan

| Field | Value |
| --- | --- |
| Review run | `b25-v4-pass-23` |
| Status | `open` |
| Source tickets | `../docs/Build Plan V2/Evidence/B25/b25-remediation-tickets-b25-v4-pass-23.json` |
| Ticket count | 8 |
| Scorecard status | `fail` |
| Remaining blocker/major | 4 |
| Blocking criteria failures | 8 |
| Product spec work items | 0 |
| Evidence repair work items | 4 |
| UI remediation work items | 18 |
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
| Search and result list pattern | Material Design 3 / design-system | https://m3.material.io/components/search/overview<br>Also: https://m3.material.io/components/lists/overview | Copy a search layout with query, filters, ranked results, citations/sources, empty/error states, and follow-up actions. |
| Task list and export wizard | GOV.UK Design System / design-system | https://design-system.service.gov.uk/components/task-list/<br>Also: https://design-system.service.gov.uk/patterns/check-answers/ | Copy a wizard with steps, preview, redaction choices, checksum evidence, transfer status, and rollback confirmation. |
| Match schedule and result pattern | Material lists/cards / pattern | https://m3.material.io/components/lists/overview | Copy a match surface with players, schedule/round, result entry, result state, and next action. |
| Screenshot-first critique method | B25 production UX gate / methodology | docs/Build Plan V2/Tools/b25-remediation-ticket-template.md | Critique must quote visible UI/text, name the persona and task, compare against the chosen reference pattern, and state the exact fix. |
| Material detail surface composition | Material Design 3 / design-system | https://m3.material.io/components/cards/overview | Build a domain detail page with primary content, metadata, status, and actions instead of a generic task card. |
| Inbox and message thread pattern | Material lists/text fields / pattern | https://m3.material.io/components/lists/overview<br>Also: https://m3.material.io/components/text-fields/overview | Copy an inbox/thread structure: sender, timestamp, message preview/body, reply field, invite/block state, and read/received state. |

### Reference Research Queries
- production mobile UX review screenshot critique examples
- open source Flutter mobile app UX patterns GitHub
- open source Flutter search-results mobile UI example GitHub
- search/AI answer surface with query, result, citation, source, and follow-up action mobile UX pattern
- Material Design search/AI answer surface with query, result, citation, source, and follow-up action mobile pattern
- open source Flutter export-wizard mobile UI example GitHub
- export/import wizard with preview, redaction, checksum, transfer status, and rollback state mobile UX pattern
- Material Design export/import wizard with preview, redaction, checksum, transfer status, and rollback state mobile pattern
- open source Flutter match-result mobile UI example GitHub
- match schedule/result surface with players, round, outcome, and next action mobile UX pattern
- Material Design match schedule/result surface with players, round, outcome, and next action mobile pattern
- modern mobile app information architecture visual hierarchy examples
- Material Design 3 mobile UI hierarchy navigation cards examples
- open source Flutter production app dashboard detail screen examples
- open source Flutter domain-native-surface mobile UI example GitHub
- notification inbox/detail surface with sender, audience, timestamp, message body, and receiver state mobile UX pattern
- Material Design notification inbox/detail surface with sender, audience, timestamp, message body, and receiver state mobile pattern
- open source Flutter message-thread mobile UI example GitHub
- inbox, message thread, connection card, invite, or block-state surface mobile UX pattern
- Material Design inbox, message thread, connection card, invite, or block-state surface mobile pattern

### Evidence Repair Work Items

Showing 4 of 4 work items. Full detail is in the JSON artifact.

| Work item | Stage | Community | Workflow | Persona | Screens | Coverage | Target surface | Blocked until |
| --- | --- | --- | --- | --- | ---: | ---: | --- | --- |
| `b25-wi-evidence-repair-community-hoa-hoa-owner-notification-community-hoa-owner` | `evidence-repair` | Cedar Commons HOA | `hoa-owner-notification` | owner | 3 | 1 | notification inbox/detail surface with sender, audience, timestamp, message body, and receiver state |  |
| `b25-wi-evidence-repair-community-platform-social-platform-blocked-target-community-platform-social-member` | `evidence-repair` | Member Social Space | `platform-blocked-target` | member | 3 | 1 | inbox, message thread, connection card, invite, or block-state surface |  |
| `b25-wi-evidence-repair-community-platform-social-platform-connections-entry-community-platform-social-member` | `evidence-repair` | Member Social Space | `platform-connections-entry` | member | 3 | 1 | inbox, message thread, connection card, invite, or block-state surface |  |
| `b25-wi-evidence-repair-community-platform-social-platform-connection-invite-community-platform-social-member` | `evidence-repair` | Member Social Space | `platform-connection-invite` | member | 3 | 1 | inbox, message thread, connection card, invite, or block-state surface |  |

### Evidence Repair Work Items Reference Patterns

| Reference | Source | URL | What to copy |
| --- | --- | --- | --- |
| Material detail surface composition | Material Design 3 / design-system | https://m3.material.io/components/cards/overview | Build a domain detail page with primary content, metadata, status, and actions instead of a generic task card. |
| Material Design cards and lists | Material Design 3 / design-system | https://m3.material.io/components/cards/overview<br>Also: https://m3.material.io/components/lists/overview | Use cards/lists only as scannable containers with clear hierarchy, content, metadata, and actions. Do not use repeated cards as the whole primary workflow. |
| Flutter sample app implementation patterns | flutter/samples / open-source | https://github.com/flutter/samples | Copy the separation between app shell, route state, domain widgets, and testable UI states rather than hardcoding a single generic renderer. |
| Material navigation and information architecture | Material Design 3 / design-system | https://m3.material.io/components/navigation-drawer/overview<br>Also: https://m3.material.io/components/navigation-bar/overview | Organize screens by user jobs and destinations; keep primary actions visible and avoid exposing implementation taxonomy. |
| Apple HIG navigation and content organization | Apple Human Interface Guidelines / design-system | https://developer.apple.com/design/human-interface-guidelines/navigation | Make navigation predictable, content-centered, and appropriate for the user’s current task. |
| Inbox and message thread pattern | Material lists/text fields / pattern | https://m3.material.io/components/lists/overview<br>Also: https://m3.material.io/components/text-fields/overview | Copy an inbox/thread structure: sender, timestamp, message preview/body, reply field, invite/block state, and read/received state. |

### Affected Coverage Rows

Showing 4 of 4 affected coverage rows.

| Coverage row | Community | Workflow | Persona | Missing evidence |
| --- | --- | --- | --- | --- |
| `b25-wp-030-hoa-owner-notification-community-hoa-owner` | Cedar Commons HOA | `hoa-owner-notification` | owner |  |
| `b25-wp-040-platform-blocked-target-community-platform-social-member` | Member Social Space | `platform-blocked-target` | member |  |
| `b25-wp-047-platform-connections-entry-community-platform-social-member` | Member Social Space | `platform-connections-entry` | member |  |
| `b25-wp-055-platform-connection-invite-community-platform-social-member` | Member Social Space | `platform-connection-invite` | member |  |

### Affected Screen Rows

Showing 30 of 54 affected screen rows.

| Screen row | Community | Workflow | Persona | State | Exact UX failure |
| --- | --- | --- | --- | --- | --- |
| `b25-v4-row-037-book-search-ai-digest-0` | Neighborhood Book Club | `book-search-ai-digest` | member | B14_ext_book_club_book-search-ai-digest_start | No row-specific failure recorded. |
| `b25-v4-row-038-book-search-ai-digest-1` | Neighborhood Book Club | `book-search-ai-digest` | member | B14_ext_book_club_book-search-ai-digest_action | No row-specific failure recorded. |
| `b25-v4-row-039-book-search-ai-digest-2` | Neighborhood Book Club | `book-search-ai-digest` | member | B14_ext_book_club_book-search-ai-digest_complete | No row-specific failure recorded. |
| `b25-v4-row-058-book-export-metadata-0` | Neighborhood Book Club | `book-export-metadata` | owner | B14_ext_book_club_book-export-metadata_start | No row-specific failure recorded. |
| `b25-v4-row-059-book-export-metadata-1` | Neighborhood Book Club | `book-export-metadata` | owner | B14_ext_book_club_book-export-metadata_action | No row-specific failure recorded. |
| `b25-v4-row-060-book-export-metadata-2` | Neighborhood Book Club | `book-export-metadata` | owner | B14_ext_book_club_book-export-metadata_complete | No row-specific failure recorded. |
| `b25-v4-row-097-chess-local-install-open-0` | Chess Club | `chess-local-install-open` | member | B15_ext_chess_club_chess-local-install-open_start | No row-specific failure recorded. |
| `b25-v4-row-098-chess-local-install-open-1` | Chess Club | `chess-local-install-open` | member | B15_ext_chess_club_chess-local-install-open_action | No row-specific failure recorded. |
| `b25-v4-row-099-chess-local-install-open-2` | Chess Club | `chess-local-install-open` | member | B15_ext_chess_club_chess-local-install-open_complete | No row-specific failure recorded. |
| `b25-v4-row-100-chess-route-home-0` | Chess Club | `chess-route-home` | member | B15_ext_chess_club_chess-route-home_start | No row-specific failure recorded. |
| `b25-v4-row-101-chess-route-home-1` | Chess Club | `chess-route-home` | member | B15_ext_chess_club_chess-route-home_action | No row-specific failure recorded. |
| `b25-v4-row-102-chess-route-home-2` | Chess Club | `chess-route-home` | member | B15_ext_chess_club_chess-route-home_complete | No row-specific failure recorded. |
| `b25-v4-row-103-chess-match-result-0` | Chess Club | `chess-match-result` | member | B15_ext_chess_club_chess-match-result_start | No row-specific failure recorded. |
| `b25-v4-row-104-chess-match-result-1` | Chess Club | `chess-match-result` | member | B15_ext_chess_club_chess-match-result_action | No row-specific failure recorded. |
| `b25-v4-row-105-chess-match-result-2` | Chess Club | `chess-match-result` | member | B15_ext_chess_club_chess-match-result_complete | No row-specific failure recorded. |
| `b25-v4-row-130-export-import-replay-0` | Data Portability Community | `export-import-replay` | owner | B16_ext_export_migration_export-import-replay_start | No row-specific failure recorded. |
| `b25-v4-row-131-export-import-replay-1` | Data Portability Community | `export-import-replay` | owner | B16_ext_export_migration_export-import-replay_action | No row-specific failure recorded. |
| `b25-v4-row-132-export-import-replay-2` | Data Portability Community | `export-import-replay` | owner | B16_ext_export_migration_export-import-replay_complete | No row-specific failure recorded. |
| `b25-v4-row-133-export-full-bundle-0` | Data Portability Community | `export-full-bundle` | owner | B16_ext_export_migration_export-full-bundle_start | No row-specific failure recorded. |
| `b25-v4-row-134-export-full-bundle-1` | Data Portability Community | `export-full-bundle` | owner | B16_ext_export_migration_export-full-bundle_action | No row-specific failure recorded. |
| `b25-v4-row-135-export-full-bundle-2` | Data Portability Community | `export-full-bundle` | owner | B16_ext_export_migration_export-full-bundle_complete | No row-specific failure recorded. |
| `b25-v4-row-136-export-transfer-verification-0` | Data Portability Community | `export-transfer-verification` | owner | B16_ext_export_migration_export-transfer-verification_start | No row-specific failure recorded. |
| `b25-v4-row-137-export-transfer-verification-1` | Data Portability Community | `export-transfer-verification` | owner | B16_ext_export_migration_export-transfer-verification_action | No row-specific failure recorded. |
| `b25-v4-row-138-export-transfer-verification-2` | Data Portability Community | `export-transfer-verification` | owner | B16_ext_export_migration_export-transfer-verification_complete | No row-specific failure recorded. |
| `b25-v4-row-154-export-protected-redaction-0` | Data Portability Community | `export-protected-redaction` | owner | B16_ext_export_migration_export-protected-redaction_start | No row-specific failure recorded. |
| `b25-v4-row-155-export-protected-redaction-1` | Data Portability Community | `export-protected-redaction` | owner | B16_ext_export_migration_export-protected-redaction_action | No row-specific failure recorded. |
| `b25-v4-row-156-export-protected-redaction-2` | Data Portability Community | `export-protected-redaction` | owner | B16_ext_export_migration_export-protected-redaction_complete | No row-specific failure recorded. |
| `b25-v4-row-157-export-redacted-bundle-0` | Data Portability Community | `export-redacted-bundle` | owner | B16_ext_export_migration_export-redacted-bundle_start | No row-specific failure recorded. |
| `b25-v4-row-158-export-redacted-bundle-1` | Data Portability Community | `export-redacted-bundle` | owner | B16_ext_export_migration_export-redacted-bundle_action | No row-specific failure recorded. |
| `b25-v4-row-159-export-redacted-bundle-2` | Data Portability Community | `export-redacted-bundle` | owner | B16_ext_export_migration_export-redacted-bundle_complete | No row-specific failure recorded. |

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
- Screen row `b25-v4-row-037-book-search-ai-digest-0` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-037-book-search-ai-digest-0` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-037-book-search-ai-digest-0` names visible UI elements, visible text, persona `member`, workflow `book-search-ai-digest`, and the exact product UX issue.
- Primary surface for `book-search-ai-digest` is documented as `search/AI answer surface with query, result, citation, source, and follow-up action` or another explicit domain-native surface.
- After-screenshot visible text proves every required semantic surface group for `book-search-ai-digest`.
- Fresh screenshot path/hash/timestamp/app commit SHA are recorded after the fix.
- Screen row `b25-v4-row-038-book-search-ai-digest-1` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-038-book-search-ai-digest-1` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-038-book-search-ai-digest-1` names visible UI elements, visible text, persona `member`, workflow `book-search-ai-digest`, and the exact product UX issue.
- Screen row `b25-v4-row-039-book-search-ai-digest-2` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-039-book-search-ai-digest-2` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-039-book-search-ai-digest-2` names visible UI elements, visible text, persona `member`, workflow `book-search-ai-digest`, and the exact product UX issue.
- Screen row `b25-v4-row-058-book-export-metadata-0` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-058-book-export-metadata-0` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-058-book-export-metadata-0` names visible UI elements, visible text, persona `owner`, workflow `book-export-metadata`, and the exact product UX issue.
- Primary surface for `book-export-metadata` is documented as `export/import wizard with preview, redaction, checksum, transfer status, and rollback state` or another explicit domain-native surface.
- After-screenshot visible text proves every required semantic surface group for `book-export-metadata`.
- Screen row `b25-v4-row-059-book-export-metadata-1` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-059-book-export-metadata-1` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-059-book-export-metadata-1` names visible UI elements, visible text, persona `owner`, workflow `book-export-metadata`, and the exact product UX issue.
- Screen row `b25-v4-row-060-book-export-metadata-2` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-060-book-export-metadata-2` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-060-book-export-metadata-2` names visible UI elements, visible text, persona `owner`, workflow `book-export-metadata`, and the exact product UX issue.
- Screen row `b25-v4-row-097-chess-local-install-open-0` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-097-chess-local-install-open-0` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-097-chess-local-install-open-0` names visible UI elements, visible text, persona `member`, workflow `chess-local-install-open`, and the exact product UX issue.
- Primary surface for `chess-local-install-open` is documented as `match schedule/result surface with players, round, outcome, and next action` or another explicit domain-native surface.
- After-screenshot visible text proves every required semantic surface group for `chess-local-install-open`.
- Screen row `b25-v4-row-098-chess-local-install-open-1` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-098-chess-local-install-open-1` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-098-chess-local-install-open-1` names visible UI elements, visible text, persona `member`, workflow `chess-local-install-open`, and the exact product UX issue.
- Screen row `b25-v4-row-099-chess-local-install-open-2` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-099-chess-local-install-open-2` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-099-chess-local-install-open-2` names visible UI elements, visible text, persona `member`, workflow `chess-local-install-open`, and the exact product UX issue.
- Screen row `b25-v4-row-100-chess-route-home-0` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-100-chess-route-home-0` is extracted from the screenshot or manually transcribed from the screenshot.

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
| Search and result list pattern | Material Design 3 / design-system | https://m3.material.io/components/search/overview<br>Also: https://m3.material.io/components/lists/overview | Copy a search layout with query, filters, ranked results, citations/sources, empty/error states, and follow-up actions. |
| Task list and export wizard | GOV.UK Design System / design-system | https://design-system.service.gov.uk/components/task-list/<br>Also: https://design-system.service.gov.uk/patterns/check-answers/ | Copy a wizard with steps, preview, redaction choices, checksum evidence, transfer status, and rollback confirmation. |
| Match schedule and result pattern | Material lists/cards / pattern | https://m3.material.io/components/lists/overview | Copy a match surface with players, schedule/round, result entry, result state, and next action. |
| Material detail surface composition | Material Design 3 / design-system | https://m3.material.io/components/cards/overview | Build a domain detail page with primary content, metadata, status, and actions instead of a generic task card. |
| Inbox and message thread pattern | Material lists/text fields / pattern | https://m3.material.io/components/lists/overview<br>Also: https://m3.material.io/components/text-fields/overview | Copy an inbox/thread structure: sender, timestamp, message preview/body, reply field, invite/block state, and read/received state. |

### Reference Research Queries
- modern mobile app information architecture visual hierarchy examples
- Material Design 3 mobile UI hierarchy navigation cards examples
- open source Flutter production app dashboard detail screen examples
- open source Flutter search-results mobile UI example GitHub
- search/AI answer surface with query, result, citation, source, and follow-up action mobile UX pattern
- Material Design search/AI answer surface with query, result, citation, source, and follow-up action mobile pattern
- open source Flutter export-wizard mobile UI example GitHub
- export/import wizard with preview, redaction, checksum, transfer status, and rollback state mobile UX pattern
- Material Design export/import wizard with preview, redaction, checksum, transfer status, and rollback state mobile pattern
- open source Flutter match-result mobile UI example GitHub
- match schedule/result surface with players, round, outcome, and next action mobile UX pattern
- Material Design match schedule/result surface with players, round, outcome, and next action mobile pattern
- community app home screen announcements events messages design examples
- open source Flutter community app home feed events messages UI
- domain specific mobile workflow UI event RSVP donation message export examples
- open source Flutter event RSVP donation messaging workflow UI examples
- open source Flutter domain-native-surface mobile UI example GitHub
- notification inbox/detail surface with sender, audience, timestamp, message body, and receiver state mobile UX pattern
- Material Design notification inbox/detail surface with sender, audience, timestamp, message body, and receiver state mobile pattern
- open source Flutter message-thread mobile UI example GitHub

### UI Remediation Work Items

Showing 18 of 18 work items. Full detail is in the JSON artifact.

| Work item | Stage | Community | Workflow | Persona | Screens | Coverage | Target surface | Blocked until |
| --- | --- | --- | --- | --- | ---: | ---: | --- | --- |
| `b25-wi-ui-remediation-community-book-club-book-search-ai-digest-community-book-club-member` | `ui-remediation` | Neighborhood Book Club | `book-search-ai-digest` | member | 3 | 0 | search/AI answer surface with query, result, citation, source, and follow-up action | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-book-club-book-export-metadata-community-book-club-owner` | `ui-remediation` | Neighborhood Book Club | `book-export-metadata` | owner | 3 | 0 | export/import wizard with preview, redaction, checksum, transfer status, and rollback state | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-chess-club-chess-local-install-open-community-chess-club-member` | `ui-remediation` | Chess Club | `chess-local-install-open` | member | 3 | 0 | match schedule/result surface with players, round, outcome, and next action | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-chess-club-chess-route-home-community-chess-club-member` | `ui-remediation` | Chess Club | `chess-route-home` | member | 3 | 0 | match schedule/result surface with players, round, outcome, and next action | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-chess-club-chess-match-result-community-chess-club-member` | `ui-remediation` | Chess Club | `chess-match-result` | member | 3 | 0 | match schedule/result surface with players, round, outcome, and next action | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-export-migration-export-import-replay-community-export-migration-owner` | `ui-remediation` | Data Portability Community | `export-import-replay` | owner | 3 | 0 | export/import wizard with preview, redaction, checksum, transfer status, and rollback state | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-export-migration-export-full-bundle-community-export-migration-owner` | `ui-remediation` | Data Portability Community | `export-full-bundle` | owner | 3 | 0 | export/import wizard with preview, redaction, checksum, transfer status, and rollback state | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-export-migration-export-transfer-verification-community-export-migration-owner` | `ui-remediation` | Data Portability Community | `export-transfer-verification` | owner | 3 | 0 | export/import wizard with preview, redaction, checksum, transfer status, and rollback state | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-export-migration-export-protected-redaction-community-export-migration-owner` | `ui-remediation` | Data Portability Community | `export-protected-redaction` | owner | 3 | 0 | export/import wizard with preview, redaction, checksum, transfer status, and rollback state | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-export-migration-export-redacted-bundle-community-export-migration-owner` | `ui-remediation` | Data Portability Community | `export-redacted-bundle` | owner | 3 | 0 | export/import wizard with preview, redaction, checksum, transfer status, and rollback state | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-export-migration-export-transfer-rollback-community-export-migration-owner` | `ui-remediation` | Data Portability Community | `export-transfer-rollback` | owner | 3 | 0 | export/import wizard with preview, redaction, checksum, transfer status, and rollback state | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-export-migration-export-import-preview-community-export-migration-owner` | `ui-remediation` | Data Portability Community | `export-import-preview` | owner | 3 | 0 | export/import wizard with preview, redaction, checksum, transfer status, and rollback state | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-export-migration-export-schema-listing-community-export-migration-owner` | `ui-remediation` | Data Portability Community | `export-schema-listing` | owner | 3 | 0 | export/import wizard with preview, redaction, checksum, transfer status, and rollback state | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-export-migration-export-checksum-evidence-community-export-migration-owner` | `ui-remediation` | Data Portability Community | `export-checksum-evidence` | owner | 3 | 0 | export/import wizard with preview, redaction, checksum, transfer status, and rollback state | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-hoa-hoa-owner-notification-community-hoa-owner` | `ui-remediation` | Cedar Commons HOA | `hoa-owner-notification` | owner | 3 | 1 | notification inbox/detail surface with sender, audience, timestamp, message body, and receiver state | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-platform-social-platform-blocked-target-community-platform-social-member` | `ui-remediation` | Member Social Space | `platform-blocked-target` | member | 3 | 1 | inbox, message thread, connection card, invite, or block-state surface | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-platform-social-platform-connections-entry-community-platform-social-member` | `ui-remediation` | Member Social Space | `platform-connections-entry` | member | 3 | 1 | inbox, message thread, connection card, invite, or block-state surface | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-platform-social-platform-connection-invite-community-platform-social-member` | `ui-remediation` | Member Social Space | `platform-connection-invite` | member | 3 | 1 | inbox, message thread, connection card, invite, or block-state surface | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |

### UI Remediation Work Items Reference Patterns

| Reference | Source | URL | What to copy |
| --- | --- | --- | --- |
| Search and result list pattern | Material Design 3 / design-system | https://m3.material.io/components/search/overview<br>Also: https://m3.material.io/components/lists/overview | Copy a search layout with query, filters, ranked results, citations/sources, empty/error states, and follow-up actions. |
| Material Design cards and lists | Material Design 3 / design-system | https://m3.material.io/components/cards/overview<br>Also: https://m3.material.io/components/lists/overview | Use cards/lists only as scannable containers with clear hierarchy, content, metadata, and actions. Do not use repeated cards as the whole primary workflow. |
| Flutter sample app implementation patterns | flutter/samples / open-source | https://github.com/flutter/samples | Copy the separation between app shell, route state, domain widgets, and testable UI states rather than hardcoding a single generic renderer. |
| Material navigation and information architecture | Material Design 3 / design-system | https://m3.material.io/components/navigation-drawer/overview<br>Also: https://m3.material.io/components/navigation-bar/overview | Organize screens by user jobs and destinations; keep primary actions visible and avoid exposing implementation taxonomy. |
| Apple HIG navigation and content organization | Apple Human Interface Guidelines / design-system | https://developer.apple.com/design/human-interface-guidelines/navigation | Make navigation predictable, content-centered, and appropriate for the user’s current task. |
| Task list and export wizard | GOV.UK Design System / design-system | https://design-system.service.gov.uk/components/task-list/<br>Also: https://design-system.service.gov.uk/patterns/check-answers/ | Copy a wizard with steps, preview, redaction choices, checksum evidence, transfer status, and rollback confirmation. |
| Match schedule and result pattern | Material lists/cards / pattern | https://m3.material.io/components/lists/overview | Copy a match surface with players, schedule/round, result entry, result state, and next action. |
| Material detail surface composition | Material Design 3 / design-system | https://m3.material.io/components/cards/overview | Build a domain detail page with primary content, metadata, status, and actions instead of a generic task card. |
| Inbox and message thread pattern | Material lists/text fields / pattern | https://m3.material.io/components/lists/overview<br>Also: https://m3.material.io/components/text-fields/overview | Copy an inbox/thread structure: sender, timestamp, message preview/body, reply field, invite/block state, and read/received state. |

### Affected Coverage Rows

Showing 4 of 4 affected coverage rows.

| Coverage row | Community | Workflow | Persona | Missing evidence |
| --- | --- | --- | --- | --- |
| `b25-wp-030-hoa-owner-notification-community-hoa-owner` | Cedar Commons HOA | `hoa-owner-notification` | owner |  |
| `b25-wp-040-platform-blocked-target-community-platform-social-member` | Member Social Space | `platform-blocked-target` | member |  |
| `b25-wp-047-platform-connections-entry-community-platform-social-member` | Member Social Space | `platform-connections-entry` | member |  |
| `b25-wp-055-platform-connection-invite-community-platform-social-member` | Member Social Space | `platform-connection-invite` | member |  |

### Affected Screen Rows

Showing 30 of 54 affected screen rows.

| Screen row | Community | Workflow | Persona | State | Exact UX failure |
| --- | --- | --- | --- | --- | --- |
| `b25-v4-row-037-book-search-ai-digest-0` | Neighborhood Book Club | `book-search-ai-digest` | member | B14_ext_book_club_book-search-ai-digest_start | No row-specific failure recorded. |
| `b25-v4-row-038-book-search-ai-digest-1` | Neighborhood Book Club | `book-search-ai-digest` | member | B14_ext_book_club_book-search-ai-digest_action | No row-specific failure recorded. |
| `b25-v4-row-039-book-search-ai-digest-2` | Neighborhood Book Club | `book-search-ai-digest` | member | B14_ext_book_club_book-search-ai-digest_complete | No row-specific failure recorded. |
| `b25-v4-row-058-book-export-metadata-0` | Neighborhood Book Club | `book-export-metadata` | owner | B14_ext_book_club_book-export-metadata_start | No row-specific failure recorded. |
| `b25-v4-row-059-book-export-metadata-1` | Neighborhood Book Club | `book-export-metadata` | owner | B14_ext_book_club_book-export-metadata_action | No row-specific failure recorded. |
| `b25-v4-row-060-book-export-metadata-2` | Neighborhood Book Club | `book-export-metadata` | owner | B14_ext_book_club_book-export-metadata_complete | No row-specific failure recorded. |
| `b25-v4-row-097-chess-local-install-open-0` | Chess Club | `chess-local-install-open` | member | B15_ext_chess_club_chess-local-install-open_start | No row-specific failure recorded. |
| `b25-v4-row-098-chess-local-install-open-1` | Chess Club | `chess-local-install-open` | member | B15_ext_chess_club_chess-local-install-open_action | No row-specific failure recorded. |
| `b25-v4-row-099-chess-local-install-open-2` | Chess Club | `chess-local-install-open` | member | B15_ext_chess_club_chess-local-install-open_complete | No row-specific failure recorded. |
| `b25-v4-row-100-chess-route-home-0` | Chess Club | `chess-route-home` | member | B15_ext_chess_club_chess-route-home_start | No row-specific failure recorded. |
| `b25-v4-row-101-chess-route-home-1` | Chess Club | `chess-route-home` | member | B15_ext_chess_club_chess-route-home_action | No row-specific failure recorded. |
| `b25-v4-row-102-chess-route-home-2` | Chess Club | `chess-route-home` | member | B15_ext_chess_club_chess-route-home_complete | No row-specific failure recorded. |
| `b25-v4-row-103-chess-match-result-0` | Chess Club | `chess-match-result` | member | B15_ext_chess_club_chess-match-result_start | No row-specific failure recorded. |
| `b25-v4-row-104-chess-match-result-1` | Chess Club | `chess-match-result` | member | B15_ext_chess_club_chess-match-result_action | No row-specific failure recorded. |
| `b25-v4-row-105-chess-match-result-2` | Chess Club | `chess-match-result` | member | B15_ext_chess_club_chess-match-result_complete | No row-specific failure recorded. |
| `b25-v4-row-130-export-import-replay-0` | Data Portability Community | `export-import-replay` | owner | B16_ext_export_migration_export-import-replay_start | No row-specific failure recorded. |
| `b25-v4-row-131-export-import-replay-1` | Data Portability Community | `export-import-replay` | owner | B16_ext_export_migration_export-import-replay_action | No row-specific failure recorded. |
| `b25-v4-row-132-export-import-replay-2` | Data Portability Community | `export-import-replay` | owner | B16_ext_export_migration_export-import-replay_complete | No row-specific failure recorded. |
| `b25-v4-row-133-export-full-bundle-0` | Data Portability Community | `export-full-bundle` | owner | B16_ext_export_migration_export-full-bundle_start | No row-specific failure recorded. |
| `b25-v4-row-134-export-full-bundle-1` | Data Portability Community | `export-full-bundle` | owner | B16_ext_export_migration_export-full-bundle_action | No row-specific failure recorded. |
| `b25-v4-row-135-export-full-bundle-2` | Data Portability Community | `export-full-bundle` | owner | B16_ext_export_migration_export-full-bundle_complete | No row-specific failure recorded. |
| `b25-v4-row-136-export-transfer-verification-0` | Data Portability Community | `export-transfer-verification` | owner | B16_ext_export_migration_export-transfer-verification_start | No row-specific failure recorded. |
| `b25-v4-row-137-export-transfer-verification-1` | Data Portability Community | `export-transfer-verification` | owner | B16_ext_export_migration_export-transfer-verification_action | No row-specific failure recorded. |
| `b25-v4-row-138-export-transfer-verification-2` | Data Portability Community | `export-transfer-verification` | owner | B16_ext_export_migration_export-transfer-verification_complete | No row-specific failure recorded. |
| `b25-v4-row-154-export-protected-redaction-0` | Data Portability Community | `export-protected-redaction` | owner | B16_ext_export_migration_export-protected-redaction_start | No row-specific failure recorded. |
| `b25-v4-row-155-export-protected-redaction-1` | Data Portability Community | `export-protected-redaction` | owner | B16_ext_export_migration_export-protected-redaction_action | No row-specific failure recorded. |
| `b25-v4-row-156-export-protected-redaction-2` | Data Portability Community | `export-protected-redaction` | owner | B16_ext_export_migration_export-protected-redaction_complete | No row-specific failure recorded. |
| `b25-v4-row-157-export-redacted-bundle-0` | Data Portability Community | `export-redacted-bundle` | owner | B16_ext_export_migration_export-redacted-bundle_start | No row-specific failure recorded. |
| `b25-v4-row-158-export-redacted-bundle-1` | Data Portability Community | `export-redacted-bundle` | owner | B16_ext_export_migration_export-redacted-bundle_action | No row-specific failure recorded. |
| `b25-v4-row-159-export-redacted-bundle-2` | Data Portability Community | `export-redacted-bundle` | owner | B16_ext_export_migration_export-redacted-bundle_complete | No row-specific failure recorded. |

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
- Screen row `b25-v4-row-037-book-search-ai-digest-0` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-037-book-search-ai-digest-0` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-037-book-search-ai-digest-0` names visible UI elements, visible text, persona `member`, workflow `book-search-ai-digest`, and the exact product UX issue.
- Primary surface for `book-search-ai-digest` is documented as `search/AI answer surface with query, result, citation, source, and follow-up action` or another explicit domain-native surface.
- After-screenshot visible text proves every required semantic surface group for `book-search-ai-digest`.
- Fresh screenshot path/hash/timestamp/app commit SHA are recorded after the fix.
- Screen row `b25-v4-row-038-book-search-ai-digest-1` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-038-book-search-ai-digest-1` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-038-book-search-ai-digest-1` names visible UI elements, visible text, persona `member`, workflow `book-search-ai-digest`, and the exact product UX issue.
- Screen row `b25-v4-row-039-book-search-ai-digest-2` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-039-book-search-ai-digest-2` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-039-book-search-ai-digest-2` names visible UI elements, visible text, persona `member`, workflow `book-search-ai-digest`, and the exact product UX issue.
- Screen row `b25-v4-row-058-book-export-metadata-0` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-058-book-export-metadata-0` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-058-book-export-metadata-0` names visible UI elements, visible text, persona `owner`, workflow `book-export-metadata`, and the exact product UX issue.
- Primary surface for `book-export-metadata` is documented as `export/import wizard with preview, redaction, checksum, transfer status, and rollback state` or another explicit domain-native surface.
- After-screenshot visible text proves every required semantic surface group for `book-export-metadata`.
- Screen row `b25-v4-row-059-book-export-metadata-1` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-059-book-export-metadata-1` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-059-book-export-metadata-1` names visible UI elements, visible text, persona `owner`, workflow `book-export-metadata`, and the exact product UX issue.
- Screen row `b25-v4-row-060-book-export-metadata-2` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-060-book-export-metadata-2` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-060-book-export-metadata-2` names visible UI elements, visible text, persona `owner`, workflow `book-export-metadata`, and the exact product UX issue.
- Screen row `b25-v4-row-097-chess-local-install-open-0` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-097-chess-local-install-open-0` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-097-chess-local-install-open-0` names visible UI elements, visible text, persona `member`, workflow `chess-local-install-open`, and the exact product UX issue.
- Primary surface for `chess-local-install-open` is documented as `match schedule/result surface with players, round, outcome, and next action` or another explicit domain-native surface.
- After-screenshot visible text proves every required semantic surface group for `chess-local-install-open`.
- Screen row `b25-v4-row-098-chess-local-install-open-1` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-098-chess-local-install-open-1` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-098-chess-local-install-open-1` names visible UI elements, visible text, persona `member`, workflow `chess-local-install-open`, and the exact product UX issue.
- Screen row `b25-v4-row-099-chess-local-install-open-2` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-099-chess-local-install-open-2` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-099-chess-local-install-open-2` names visible UI elements, visible text, persona `member`, workflow `chess-local-install-open`, and the exact product UX issue.
- Screen row `b25-v4-row-100-chess-route-home-0` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-100-chess-route-home-0` is extracted from the screenshot or manually transcribed from the screenshot.

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
| Search and result list pattern | Material Design 3 / design-system | https://m3.material.io/components/search/overview<br>Also: https://m3.material.io/components/lists/overview | Copy a search layout with query, filters, ranked results, citations/sources, empty/error states, and follow-up actions. |
| Task list and export wizard | GOV.UK Design System / design-system | https://design-system.service.gov.uk/components/task-list/<br>Also: https://design-system.service.gov.uk/patterns/check-answers/ | Copy a wizard with steps, preview, redaction choices, checksum evidence, transfer status, and rollback confirmation. |
| Match schedule and result pattern | Material lists/cards / pattern | https://m3.material.io/components/lists/overview | Copy a match surface with players, schedule/round, result entry, result state, and next action. |
| Material detail surface composition | Material Design 3 / design-system | https://m3.material.io/components/cards/overview | Build a domain detail page with primary content, metadata, status, and actions instead of a generic task card. |
| Inbox and message thread pattern | Material lists/text fields / pattern | https://m3.material.io/components/lists/overview<br>Also: https://m3.material.io/components/text-fields/overview | Copy an inbox/thread structure: sender, timestamp, message preview/body, reply field, invite/block state, and read/received state. |
| Screenshot-first critique method | B25 production UX gate / methodology | docs/Build Plan V2/Tools/b25-remediation-ticket-template.md | Critique must quote visible UI/text, name the persona and task, compare against the chosen reference pattern, and state the exact fix. |

### Reference Research Queries
- production mobile UX review screenshot critique examples
- open source Flutter mobile app UX patterns GitHub
- open source Flutter search-results mobile UI example GitHub
- search/AI answer surface with query, result, citation, source, and follow-up action mobile UX pattern
- Material Design search/AI answer surface with query, result, citation, source, and follow-up action mobile pattern
- open source Flutter export-wizard mobile UI example GitHub
- export/import wizard with preview, redaction, checksum, transfer status, and rollback state mobile UX pattern
- Material Design export/import wizard with preview, redaction, checksum, transfer status, and rollback state mobile pattern
- open source Flutter match-result mobile UI example GitHub
- match schedule/result surface with players, round, outcome, and next action mobile UX pattern
- Material Design match schedule/result surface with players, round, outcome, and next action mobile pattern
- open source Flutter domain-native-surface mobile UI example GitHub
- persona capability matrix surface with roles, allowed actions, receiver states, and denied/hidden behavior mobile UX pattern
- Material Design persona capability matrix surface with roles, allowed actions, receiver states, and denied/hidden behavior mobile pattern
- test-only persona switcher surface with active persona, role description, and return-to-workflow state mobile UX pattern
- Material Design test-only persona switcher surface with active persona, role description, and return-to-workflow state mobile pattern
- modern mobile app information architecture visual hierarchy examples
- Material Design 3 mobile UI hierarchy navigation cards examples
- open source Flutter production app dashboard detail screen examples
- community app home screen announcements events messages design examples

### Evidence Repair Work Items

Showing 4 of 4 work items. Full detail is in the JSON artifact.

| Work item | Stage | Community | Workflow | Persona | Screens | Coverage | Target surface | Blocked until |
| --- | --- | --- | --- | --- | ---: | ---: | --- | --- |
| `b25-wi-evidence-repair-community-hoa-hoa-owner-notification-community-hoa-owner` | `evidence-repair` | Cedar Commons HOA | `hoa-owner-notification` | owner | 3 | 1 | notification inbox/detail surface with sender, audience, timestamp, message body, and receiver state |  |
| `b25-wi-evidence-repair-community-platform-social-platform-blocked-target-community-platform-social-member` | `evidence-repair` | Member Social Space | `platform-blocked-target` | member | 3 | 1 | inbox, message thread, connection card, invite, or block-state surface |  |
| `b25-wi-evidence-repair-community-platform-social-platform-connections-entry-community-platform-social-member` | `evidence-repair` | Member Social Space | `platform-connections-entry` | member | 3 | 1 | inbox, message thread, connection card, invite, or block-state surface |  |
| `b25-wi-evidence-repair-community-platform-social-platform-connection-invite-community-platform-social-member` | `evidence-repair` | Member Social Space | `platform-connection-invite` | member | 3 | 1 | inbox, message thread, connection card, invite, or block-state surface |  |

### Evidence Repair Work Items Reference Patterns

| Reference | Source | URL | What to copy |
| --- | --- | --- | --- |
| Material detail surface composition | Material Design 3 / design-system | https://m3.material.io/components/cards/overview | Build a domain detail page with primary content, metadata, status, and actions instead of a generic task card. |
| Material Design cards and lists | Material Design 3 / design-system | https://m3.material.io/components/cards/overview<br>Also: https://m3.material.io/components/lists/overview | Use cards/lists only as scannable containers with clear hierarchy, content, metadata, and actions. Do not use repeated cards as the whole primary workflow. |
| Flutter sample app implementation patterns | flutter/samples / open-source | https://github.com/flutter/samples | Copy the separation between app shell, route state, domain widgets, and testable UI states rather than hardcoding a single generic renderer. |
| Material navigation and information architecture | Material Design 3 / design-system | https://m3.material.io/components/navigation-drawer/overview<br>Also: https://m3.material.io/components/navigation-bar/overview | Organize screens by user jobs and destinations; keep primary actions visible and avoid exposing implementation taxonomy. |
| Apple HIG navigation and content organization | Apple Human Interface Guidelines / design-system | https://developer.apple.com/design/human-interface-guidelines/navigation | Make navigation predictable, content-centered, and appropriate for the user’s current task. |
| Inbox and message thread pattern | Material lists/text fields / pattern | https://m3.material.io/components/lists/overview<br>Also: https://m3.material.io/components/text-fields/overview | Copy an inbox/thread structure: sender, timestamp, message preview/body, reply field, invite/block state, and read/received state. |

### UI Remediation Work Items

Showing 18 of 18 work items. Full detail is in the JSON artifact.

| Work item | Stage | Community | Workflow | Persona | Screens | Coverage | Target surface | Blocked until |
| --- | --- | --- | --- | --- | ---: | ---: | --- | --- |
| `b25-wi-ui-remediation-community-book-club-book-search-ai-digest-community-book-club-member` | `ui-remediation` | Neighborhood Book Club | `book-search-ai-digest` | member | 3 | 0 | search/AI answer surface with query, result, citation, source, and follow-up action | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-book-club-book-export-metadata-community-book-club-owner` | `ui-remediation` | Neighborhood Book Club | `book-export-metadata` | owner | 3 | 0 | export/import wizard with preview, redaction, checksum, transfer status, and rollback state | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-chess-club-chess-local-install-open-community-chess-club-member` | `ui-remediation` | Chess Club | `chess-local-install-open` | member | 3 | 0 | match schedule/result surface with players, round, outcome, and next action | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-chess-club-chess-route-home-community-chess-club-member` | `ui-remediation` | Chess Club | `chess-route-home` | member | 3 | 0 | match schedule/result surface with players, round, outcome, and next action | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-chess-club-chess-match-result-community-chess-club-member` | `ui-remediation` | Chess Club | `chess-match-result` | member | 3 | 0 | match schedule/result surface with players, round, outcome, and next action | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-export-migration-export-import-replay-community-export-migration-owner` | `ui-remediation` | Data Portability Community | `export-import-replay` | owner | 3 | 0 | export/import wizard with preview, redaction, checksum, transfer status, and rollback state | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-export-migration-export-full-bundle-community-export-migration-owner` | `ui-remediation` | Data Portability Community | `export-full-bundle` | owner | 3 | 0 | export/import wizard with preview, redaction, checksum, transfer status, and rollback state | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-export-migration-export-transfer-verification-community-export-migration-owner` | `ui-remediation` | Data Portability Community | `export-transfer-verification` | owner | 3 | 0 | export/import wizard with preview, redaction, checksum, transfer status, and rollback state | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-export-migration-export-protected-redaction-community-export-migration-owner` | `ui-remediation` | Data Portability Community | `export-protected-redaction` | owner | 3 | 0 | export/import wizard with preview, redaction, checksum, transfer status, and rollback state | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-export-migration-export-redacted-bundle-community-export-migration-owner` | `ui-remediation` | Data Portability Community | `export-redacted-bundle` | owner | 3 | 0 | export/import wizard with preview, redaction, checksum, transfer status, and rollback state | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-export-migration-export-transfer-rollback-community-export-migration-owner` | `ui-remediation` | Data Portability Community | `export-transfer-rollback` | owner | 3 | 0 | export/import wizard with preview, redaction, checksum, transfer status, and rollback state | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-export-migration-export-import-preview-community-export-migration-owner` | `ui-remediation` | Data Portability Community | `export-import-preview` | owner | 3 | 0 | export/import wizard with preview, redaction, checksum, transfer status, and rollback state | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-export-migration-export-schema-listing-community-export-migration-owner` | `ui-remediation` | Data Portability Community | `export-schema-listing` | owner | 3 | 0 | export/import wizard with preview, redaction, checksum, transfer status, and rollback state | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-export-migration-export-checksum-evidence-community-export-migration-owner` | `ui-remediation` | Data Portability Community | `export-checksum-evidence` | owner | 3 | 0 | export/import wizard with preview, redaction, checksum, transfer status, and rollback state | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-hoa-hoa-owner-notification-community-hoa-owner` | `ui-remediation` | Cedar Commons HOA | `hoa-owner-notification` | owner | 3 | 1 | notification inbox/detail surface with sender, audience, timestamp, message body, and receiver state | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-platform-social-platform-blocked-target-community-platform-social-member` | `ui-remediation` | Member Social Space | `platform-blocked-target` | member | 3 | 1 | inbox, message thread, connection card, invite, or block-state surface | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-platform-social-platform-connections-entry-community-platform-social-member` | `ui-remediation` | Member Social Space | `platform-connections-entry` | member | 3 | 1 | inbox, message thread, connection card, invite, or block-state surface | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-platform-social-platform-connection-invite-community-platform-social-member` | `ui-remediation` | Member Social Space | `platform-connection-invite` | member | 3 | 1 | inbox, message thread, connection card, invite, or block-state surface | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |

### UI Remediation Work Items Reference Patterns

| Reference | Source | URL | What to copy |
| --- | --- | --- | --- |
| Search and result list pattern | Material Design 3 / design-system | https://m3.material.io/components/search/overview<br>Also: https://m3.material.io/components/lists/overview | Copy a search layout with query, filters, ranked results, citations/sources, empty/error states, and follow-up actions. |
| Material Design cards and lists | Material Design 3 / design-system | https://m3.material.io/components/cards/overview<br>Also: https://m3.material.io/components/lists/overview | Use cards/lists only as scannable containers with clear hierarchy, content, metadata, and actions. Do not use repeated cards as the whole primary workflow. |
| Flutter sample app implementation patterns | flutter/samples / open-source | https://github.com/flutter/samples | Copy the separation between app shell, route state, domain widgets, and testable UI states rather than hardcoding a single generic renderer. |
| Material navigation and information architecture | Material Design 3 / design-system | https://m3.material.io/components/navigation-drawer/overview<br>Also: https://m3.material.io/components/navigation-bar/overview | Organize screens by user jobs and destinations; keep primary actions visible and avoid exposing implementation taxonomy. |
| Apple HIG navigation and content organization | Apple Human Interface Guidelines / design-system | https://developer.apple.com/design/human-interface-guidelines/navigation | Make navigation predictable, content-centered, and appropriate for the user’s current task. |
| Task list and export wizard | GOV.UK Design System / design-system | https://design-system.service.gov.uk/components/task-list/<br>Also: https://design-system.service.gov.uk/patterns/check-answers/ | Copy a wizard with steps, preview, redaction choices, checksum evidence, transfer status, and rollback confirmation. |
| Match schedule and result pattern | Material lists/cards / pattern | https://m3.material.io/components/lists/overview | Copy a match surface with players, schedule/round, result entry, result state, and next action. |
| Material detail surface composition | Material Design 3 / design-system | https://m3.material.io/components/cards/overview | Build a domain detail page with primary content, metadata, status, and actions instead of a generic task card. |
| Inbox and message thread pattern | Material lists/text fields / pattern | https://m3.material.io/components/lists/overview<br>Also: https://m3.material.io/components/text-fields/overview | Copy an inbox/thread structure: sender, timestamp, message preview/body, reply field, invite/block state, and read/received state. |

### Affected Coverage Rows

Showing 4 of 4 affected coverage rows.

| Coverage row | Community | Workflow | Persona | Missing evidence |
| --- | --- | --- | --- | --- |
| `b25-wp-030-hoa-owner-notification-community-hoa-owner` | Cedar Commons HOA | `hoa-owner-notification` | owner |  |
| `b25-wp-040-platform-blocked-target-community-platform-social-member` | Member Social Space | `platform-blocked-target` | member |  |
| `b25-wp-047-platform-connections-entry-community-platform-social-member` | Member Social Space | `platform-connections-entry` | member |  |
| `b25-wp-055-platform-connection-invite-community-platform-social-member` | Member Social Space | `platform-connection-invite` | member |  |

### Affected Screen Rows

Showing 30 of 58 affected screen rows.

| Screen row | Community | Workflow | Persona | State | Exact UX failure |
| --- | --- | --- | --- | --- | --- |
| `b25-v4-row-037-book-search-ai-digest-0` | Neighborhood Book Club | `book-search-ai-digest` | member | B14_ext_book_club_book-search-ai-digest_start | No row-specific failure recorded. |
| `b25-v4-row-038-book-search-ai-digest-1` | Neighborhood Book Club | `book-search-ai-digest` | member | B14_ext_book_club_book-search-ai-digest_action | No row-specific failure recorded. |
| `b25-v4-row-039-book-search-ai-digest-2` | Neighborhood Book Club | `book-search-ai-digest` | member | B14_ext_book_club_book-search-ai-digest_complete | No row-specific failure recorded. |
| `b25-v4-row-058-book-export-metadata-0` | Neighborhood Book Club | `book-export-metadata` | owner | B14_ext_book_club_book-export-metadata_start | No row-specific failure recorded. |
| `b25-v4-row-059-book-export-metadata-1` | Neighborhood Book Club | `book-export-metadata` | owner | B14_ext_book_club_book-export-metadata_action | No row-specific failure recorded. |
| `b25-v4-row-060-book-export-metadata-2` | Neighborhood Book Club | `book-export-metadata` | owner | B14_ext_book_club_book-export-metadata_complete | No row-specific failure recorded. |
| `b25-v4-row-097-chess-local-install-open-0` | Chess Club | `chess-local-install-open` | member | B15_ext_chess_club_chess-local-install-open_start | No row-specific failure recorded. |
| `b25-v4-row-098-chess-local-install-open-1` | Chess Club | `chess-local-install-open` | member | B15_ext_chess_club_chess-local-install-open_action | No row-specific failure recorded. |
| `b25-v4-row-099-chess-local-install-open-2` | Chess Club | `chess-local-install-open` | member | B15_ext_chess_club_chess-local-install-open_complete | No row-specific failure recorded. |
| `b25-v4-row-100-chess-route-home-0` | Chess Club | `chess-route-home` | member | B15_ext_chess_club_chess-route-home_start | No row-specific failure recorded. |
| `b25-v4-row-101-chess-route-home-1` | Chess Club | `chess-route-home` | member | B15_ext_chess_club_chess-route-home_action | No row-specific failure recorded. |
| `b25-v4-row-102-chess-route-home-2` | Chess Club | `chess-route-home` | member | B15_ext_chess_club_chess-route-home_complete | No row-specific failure recorded. |
| `b25-v4-row-103-chess-match-result-0` | Chess Club | `chess-match-result` | member | B15_ext_chess_club_chess-match-result_start | No row-specific failure recorded. |
| `b25-v4-row-104-chess-match-result-1` | Chess Club | `chess-match-result` | member | B15_ext_chess_club_chess-match-result_action | No row-specific failure recorded. |
| `b25-v4-row-105-chess-match-result-2` | Chess Club | `chess-match-result` | member | B15_ext_chess_club_chess-match-result_complete | No row-specific failure recorded. |
| `b25-v4-row-130-export-import-replay-0` | Data Portability Community | `export-import-replay` | owner | B16_ext_export_migration_export-import-replay_start | No row-specific failure recorded. |
| `b25-v4-row-131-export-import-replay-1` | Data Portability Community | `export-import-replay` | owner | B16_ext_export_migration_export-import-replay_action | No row-specific failure recorded. |
| `b25-v4-row-132-export-import-replay-2` | Data Portability Community | `export-import-replay` | owner | B16_ext_export_migration_export-import-replay_complete | No row-specific failure recorded. |
| `b25-v4-row-133-export-full-bundle-0` | Data Portability Community | `export-full-bundle` | owner | B16_ext_export_migration_export-full-bundle_start | No row-specific failure recorded. |
| `b25-v4-row-134-export-full-bundle-1` | Data Portability Community | `export-full-bundle` | owner | B16_ext_export_migration_export-full-bundle_action | No row-specific failure recorded. |
| `b25-v4-row-135-export-full-bundle-2` | Data Portability Community | `export-full-bundle` | owner | B16_ext_export_migration_export-full-bundle_complete | No row-specific failure recorded. |
| `b25-v4-row-136-export-transfer-verification-0` | Data Portability Community | `export-transfer-verification` | owner | B16_ext_export_migration_export-transfer-verification_start | No row-specific failure recorded. |
| `b25-v4-row-137-export-transfer-verification-1` | Data Portability Community | `export-transfer-verification` | owner | B16_ext_export_migration_export-transfer-verification_action | No row-specific failure recorded. |
| `b25-v4-row-138-export-transfer-verification-2` | Data Portability Community | `export-transfer-verification` | owner | B16_ext_export_migration_export-transfer-verification_complete | No row-specific failure recorded. |
| `b25-v4-row-154-export-protected-redaction-0` | Data Portability Community | `export-protected-redaction` | owner | B16_ext_export_migration_export-protected-redaction_start | No row-specific failure recorded. |
| `b25-v4-row-155-export-protected-redaction-1` | Data Portability Community | `export-protected-redaction` | owner | B16_ext_export_migration_export-protected-redaction_action | No row-specific failure recorded. |
| `b25-v4-row-156-export-protected-redaction-2` | Data Portability Community | `export-protected-redaction` | owner | B16_ext_export_migration_export-protected-redaction_complete | No row-specific failure recorded. |
| `b25-v4-row-157-export-redacted-bundle-0` | Data Portability Community | `export-redacted-bundle` | owner | B16_ext_export_migration_export-redacted-bundle_start | No row-specific failure recorded. |
| `b25-v4-row-158-export-redacted-bundle-1` | Data Portability Community | `export-redacted-bundle` | owner | B16_ext_export_migration_export-redacted-bundle_action | No row-specific failure recorded. |
| `b25-v4-row-159-export-redacted-bundle-2` | Data Portability Community | `export-redacted-bundle` | owner | B16_ext_export_migration_export-redacted-bundle_complete | No row-specific failure recorded. |

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
- Screen row `b25-v4-row-037-book-search-ai-digest-0` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-037-book-search-ai-digest-0` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-037-book-search-ai-digest-0` names visible UI elements, visible text, persona `member`, workflow `book-search-ai-digest`, and the exact product UX issue.
- Primary surface for `book-search-ai-digest` is documented as `search/AI answer surface with query, result, citation, source, and follow-up action` or another explicit domain-native surface.
- After-screenshot visible text proves every required semantic surface group for `book-search-ai-digest`.
- Fresh screenshot path/hash/timestamp/app commit SHA are recorded after the fix.
- Screen row `b25-v4-row-038-book-search-ai-digest-1` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-038-book-search-ai-digest-1` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-038-book-search-ai-digest-1` names visible UI elements, visible text, persona `member`, workflow `book-search-ai-digest`, and the exact product UX issue.
- Screen row `b25-v4-row-039-book-search-ai-digest-2` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-039-book-search-ai-digest-2` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-039-book-search-ai-digest-2` names visible UI elements, visible text, persona `member`, workflow `book-search-ai-digest`, and the exact product UX issue.
- Screen row `b25-v4-row-058-book-export-metadata-0` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-058-book-export-metadata-0` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-058-book-export-metadata-0` names visible UI elements, visible text, persona `owner`, workflow `book-export-metadata`, and the exact product UX issue.
- Primary surface for `book-export-metadata` is documented as `export/import wizard with preview, redaction, checksum, transfer status, and rollback state` or another explicit domain-native surface.
- After-screenshot visible text proves every required semantic surface group for `book-export-metadata`.
- Screen row `b25-v4-row-059-book-export-metadata-1` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-059-book-export-metadata-1` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-059-book-export-metadata-1` names visible UI elements, visible text, persona `owner`, workflow `book-export-metadata`, and the exact product UX issue.
- Screen row `b25-v4-row-060-book-export-metadata-2` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-060-book-export-metadata-2` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-060-book-export-metadata-2` names visible UI elements, visible text, persona `owner`, workflow `book-export-metadata`, and the exact product UX issue.
- Screen row `b25-v4-row-097-chess-local-install-open-0` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-097-chess-local-install-open-0` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-097-chess-local-install-open-0` names visible UI elements, visible text, persona `member`, workflow `chess-local-install-open`, and the exact product UX issue.
- Primary surface for `chess-local-install-open` is documented as `match schedule/result surface with players, round, outcome, and next action` or another explicit domain-native surface.
- After-screenshot visible text proves every required semantic surface group for `chess-local-install-open`.
- Screen row `b25-v4-row-098-chess-local-install-open-1` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-098-chess-local-install-open-1` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-098-chess-local-install-open-1` names visible UI elements, visible text, persona `member`, workflow `chess-local-install-open`, and the exact product UX issue.
- Screen row `b25-v4-row-099-chess-local-install-open-2` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-099-chess-local-install-open-2` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-099-chess-local-install-open-2` names visible UI elements, visible text, persona `member`, workflow `chess-local-install-open`, and the exact product UX issue.
- Screen row `b25-v4-row-100-chess-route-home-0` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-100-chess-route-home-0` is extracted from the screenshot or manually transcribed from the screenshot.

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
