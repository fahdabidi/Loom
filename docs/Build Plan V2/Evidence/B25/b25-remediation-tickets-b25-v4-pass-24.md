# Remediation Tickets

| Field | Value |
| --- | --- |
| Tool | `production-ux-judge` |
| Status | `fail` |
| Open tickets | 9 |

## B25-RT-001-b25-c01-no-blocker-major

| Field | Value |
| --- | --- |
| Severity | major |
| Priority | P1 |
| Status | open |
| Review run | `b25-v4-pass-24` |
| Source criterion | `b25-c01-no-blocker-major` |
| Source findings | B25-WORKFLOW-PERSONA-UX-FAILED, B25-WORKFLOW-LIFECYCLE-INCOMPLETE, B25-HOLISTIC-UX-FAILED, LLM-UX-primary-ux-is-still-a-repeated-workflow-card-scaffold-across-the-evidence-set, LLM-UX-visible-copy-exposes-workflow-contract-language-instead-of-product-native-task-language, LLM-UX-several-workflow-persona-lifecycles-still-lack-concrete-object-context-or-persistent-result-state, LLM-UX-persona-picker-and-role-inventory-evidence-exposes-local-test-harness-ui-as-reviewed-product-surface |
| Title | No unresolved blocker or major findings |
| Direct question | Are there zero unresolved blocker or major findings in the current production UX evidence? |
| Why it failed | Unresolved blocker/major counts are blocker=1 major=6. |
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
| Search and result list pattern | Material Design 3 / design-system | https://m3.material.io/components/search/overview<br>Also: https://m3.material.io/components/lists/overview | Copy a search layout with query, filters, ranked results, citations/sources, empty/error states, and follow-up actions. |
| Material detail surface composition | Material Design 3 / design-system | https://m3.material.io/components/cards/overview | Build a domain detail page with primary content, metadata, status, and actions instead of a generic task card. |
| Inbox and message thread pattern | Material lists/text fields / pattern | https://m3.material.io/components/lists/overview<br>Also: https://m3.material.io/components/text-fields/overview | Copy an inbox/thread structure: sender, timestamp, message preview/body, reply field, invite/block state, and read/received state. |
| Task list and export wizard | GOV.UK Design System / design-system | https://design-system.service.gov.uk/components/task-list/<br>Also: https://design-system.service.gov.uk/patterns/check-answers/ | Copy a wizard with steps, preview, redaction choices, checksum evidence, transfer status, and rollback confirmation. |

### Reference Research Queries
- production mobile UX review screenshot critique examples
- open source Flutter mobile app UX patterns GitHub
- open source Flutter search-results mobile UI example GitHub
- search/AI answer surface with query, result, citation, source, and follow-up action mobile UX pattern
- Material Design search/AI answer surface with query, result, citation, source, and follow-up action mobile pattern
- open source Flutter domain-native-surface mobile UI example GitHub
- notification inbox/detail surface with sender, audience, timestamp, message body, and receiver state mobile UX pattern
- Material Design notification inbox/detail surface with sender, audience, timestamp, message body, and receiver state mobile pattern
- open source Flutter message-thread mobile UI example GitHub
- inbox, message thread, connection card, invite, or block-state surface mobile UX pattern
- Material Design inbox, message thread, connection card, invite, or block-state surface mobile pattern
- open source Flutter export-wizard mobile UI example GitHub
- export/import wizard with preview, redaction, checksum, transfer status, and rollback state mobile UX pattern
- Material Design export/import wizard with preview, redaction, checksum, transfer status, and rollback state mobile pattern

### Implementation Blocked By
- Open blocker/major B25 tickets remain.
- The scorecard cannot close until those tickets rerun clean.

### Affected Screen Rows

Showing 21 of 21 affected screen rows. Full detail is in the JSON ticket.

| Screen row | Community | Workflow | Persona | State | Screenshot | Hash | Visible text | Current surface | Exact UX failure | Target surface |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `b25-v4-row-037-book-search-ai-digest-0` | Neighborhood Book Club | `book-search-ai-digest` | member | B14_ext_book_club_book-search-ai-digest_start | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_book_club_book-search-ai-digest_start.png` | `084b20dbc594a...` | Reading guide answer \| Query: "What should we discuss before chapter 6?" \| Review the AI answer, quoted source snippets, citation list, and follow-up prompts before saving it to the club digest. \| Question asked \| AI summary \| 3 citations \| Save digest \| AI answer with citatio... | domain-native-reviewed / domain-native | No row-specific failure recorded. | search/AI answer surface with query, result, citation, source, and follow-up action |
| `b25-v4-row-038-book-search-ai-digest-1` | Neighborhood Book Club | `book-search-ai-digest` | member | B14_ext_book_club_book-search-ai-digest_action | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_book_club_book-search-ai-digest_action.png` | `ee8f007e32b4e...` | Reading guide answer \| Parable of the Sower reading guide with cited sources \| Check the query, answer summary, citation snippets, source titles, and follow-up action before saving the digest. \| AI answer with citations \| Query \| What should we discuss before chapter 6? \| Answ... | domain-native-reviewed / domain-native | No row-specific failure recorded. | search/AI answer surface with query, result, citation, source, and follow-up action |
| `b25-v4-row-039-book-search-ai-digest-2` | Neighborhood Book Club | `book-search-ai-digest` | member | B14_ext_book_club_book-search-ai-digest_complete | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_book_club_book-search-ai-digest_complete.png` | `a2a76009ad38d...` | Reading guide answer \| Query: "What should we discuss before chapter 6?" \| The reading guide now shows query, answer, citations, source visibility, save state, and follow-up prompts. \| Question asked \| AI summary \| 3 citations \| Save digest \| AI answer with citations \| Query \|... | domain-native-reviewed / domain-native | No row-specific failure recorded. | search/AI answer surface with query, result, citation, source, and follow-up action |
| `b25-v4-row-088-hoa-owner-notification-0` | Cedar Commons HOA | `hoa-owner-notification` | owner | B14_ext_hoa_hoa-owner-notification_start | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_hoa_hoa-owner-notification_start.png` | `76e3f623980ab...` | Owner decision notice \| Lot 42 fence request - approved with conditions. \| Send the owner notice with board sender, decision summary, required paint condition, delivery time, and owner inbox state. \| Lot 42 \| From HOA Board \| Today 4:15 PM \| Owner inbox \| Decide what to save, ... | domain-native-reviewed / domain-native | No row-specific failure recorded. | notification inbox/detail surface with sender, audience, timestamp, message body, and receiver state |
| `b25-v4-row-089-hoa-owner-notification-1` | Cedar Commons HOA | `hoa-owner-notification` | owner | B14_ext_hoa_hoa-owner-notification_action | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_hoa_hoa-owner-notification_action.png` | `fb1f41cd434a6...` | Owner decision notice \| Avery Brooks - architectural decision \| Review sender, recipient, decision body, condition, timestamp, and owner receiver state before sending. \| Decide what to save, what to change, and what status or next step should remain visible afterward. \| Edit r... | domain-native-reviewed / domain-native | No row-specific failure recorded. | notification inbox/detail surface with sender, audience, timestamp, message body, and receiver state |
| `b25-v4-row-090-hoa-owner-notification-2` | Cedar Commons HOA | `hoa-owner-notification` | owner | B14_ext_hoa_hoa-owner-notification_complete | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_hoa_hoa-owner-notification_complete.png` | `8c91c548ee250...` | Owner decision notice \| Lot 42 fence request - approved with conditions. \| Owner notice shows sender, recipient, body, timestamp, decision condition, inbox receipt, and follow-up path. \| Lot 42 \| From HOA Board \| Today 4:15 PM \| Owner inbox \| Decide what to save, what to chang... | domain-native-reviewed / domain-native | No row-specific failure recorded. | notification inbox/detail surface with sender, audience, timestamp, message body, and receiver state |
| `b25-v4-row-115-platform-messages-entry-0` | Member Social Space | `platform-messages-entry` | member | B16_ext_platform_social_platform-messages-entry_start | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B16/screenshots/B16_ext_platform_social_platform-messages-entry_start.png` | `8dc4aeef3213b...` | Community message thread \| Maya Chen to Jordan Lee - unread member thread. \| Read sender, recipient, timestamp, message preview, unread state, reply path, mute, and archive controls. \| Maya -> Jordan \| Unread \| Reply available \| Archive path \| Member conversation \| Maya Chen -... | domain-native-reviewed / domain-native | No row-specific failure recorded. | inbox, message thread, connection card, invite, or block-state surface |
| `b25-v4-row-116-platform-messages-entry-1` | Member Social Space | `platform-messages-entry` | member | B16_ext_platform_social_platform-messages-entry_action | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B16/screenshots/B16_ext_platform_social_platform-messages-entry_action.png` | `99ccbc020cc33...` | Community message thread \| Community message from Maya \| Open the thread, review sender and body, reply, mute, archive, or block if needed. \| Member conversation \| Maya Chen -> Jordan Lee \| Visible sender, recipient, Today 9:12 AM timestamp, and community relationship. \| Messa... | domain-native-reviewed / domain-native | No row-specific failure recorded. | inbox, message thread, connection card, invite, or block-state surface |
| `b25-v4-row-117-platform-messages-entry-2` | Member Social Space | `platform-messages-entry` | member | B16_ext_platform_social_platform-messages-entry_complete | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B16/screenshots/B16_ext_platform_social_platform-messages-entry_complete.png` | `87ae065ef3a38...` | Community message thread \| Maya Chen to Jordan Lee - unread member thread. \| The thread shows sender, body, timestamp, reply path, read state, and archive/block controls. \| Maya -> Jordan \| Unread \| Reply available \| Archive path \| Member conversation \| Maya Chen -> Jordan Lee... | domain-native-reviewed / domain-native | No row-specific failure recorded. | inbox, message thread, connection card, invite, or block-state surface |
| `b25-v4-row-130-export-import-replay-0` | Data Portability Community | `export-import-replay` | owner | B16_ext_export_migration_export-import-replay_start | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B16/screenshots/B16_ext_export_migration_export-import-replay_start.png` | `1f031f14addb2...` | Legacy import preview \| Preview rows, conflicts, replay checkpoint, and rollback marker. \| Inspect imported member, document, and receipt rows; resolve duplicates; and confirm replay checkpoint before importing. \| Scope selected \| 3 conflicts \| Audit receipt \| Owner artifact \|... | domain-native-reviewed / domain-native | No row-specific failure recorded. | export/import wizard with preview, redaction, checksum, transfer status, and rollback state |
| `b25-v4-row-131-export-import-replay-1` | Data Portability Community | `export-import-replay` | owner | B16_ext_export_migration_export-import-replay_action | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B16/screenshots/B16_ext_export_migration_export-import-replay_action.png` | `cfb3479724b6e...` | Legacy import preview \| Preview rows, conflicts, replay checkpoint, and rollback marker. \| Inspect imported member, document, and receipt rows; resolve duplicates; and confirm replay checkpoint before importing. \| Import rows \| Preview 48 member rows, 22 documents, and 12 rece... | domain-native-reviewed / domain-native | No row-specific failure recorded. | export/import wizard with preview, redaction, checksum, transfer status, and rollback state |
| `b25-v4-row-132-export-import-replay-2` | Data Portability Community | `export-import-replay` | owner | B16_ext_export_migration_export-import-replay_complete | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B16/screenshots/B16_ext_export_migration_export-import-replay_complete.png` | `09d3f1fdb9c14...` | Legacy import preview \| Preview rows, conflicts, replay checkpoint, and rollback marker. \| Import preview shows row counts, duplicate decisions, checkpoint, retry, and rollback state. \| Scope selected \| 3 conflicts \| Audit receipt \| Owner artifact \| Import rows \| Preview 48 me... | domain-native-reviewed / domain-native | No row-specific failure recorded. | export/import wizard with preview, redaction, checksum, transfer status, and rollback state |
| `b25-v4-row-142-platform-message-stream-0` | Member Social Space | `platform-message-stream` | member | B16_ext_platform_social_platform-message-stream_start | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B16/screenshots/B16_ext_platform_social_platform-message-stream_start.png` | `8dc4aeef3213b...` | Community message thread \| Maya Chen to Jordan Lee - unread member thread. \| Read sender, recipient, timestamp, message preview, unread state, reply path, mute, and archive controls. \| Maya -> Jordan \| Unread \| Reply available \| Archive path \| Member conversation \| Maya Chen -... | domain-native-reviewed / domain-native | No row-specific failure recorded. | inbox, message thread, connection card, invite, or block-state surface |
| `b25-v4-row-143-platform-message-stream-1` | Member Social Space | `platform-message-stream` | member | B16_ext_platform_social_platform-message-stream_action | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B16/screenshots/B16_ext_platform_social_platform-message-stream_action.png` | `99ccbc020cc33...` | Community message thread \| Community message from Maya \| Open the thread, review sender and body, reply, mute, archive, or block if needed. \| Member conversation \| Maya Chen -> Jordan Lee \| Visible sender, recipient, Today 9:12 AM timestamp, and community relationship. \| Messa... | domain-native-reviewed / domain-native | No row-specific failure recorded. | inbox, message thread, connection card, invite, or block-state surface |
| `b25-v4-row-144-platform-message-stream-2` | Member Social Space | `platform-message-stream` | member | B16_ext_platform_social_platform-message-stream_complete | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B16/screenshots/B16_ext_platform_social_platform-message-stream_complete.png` | `87ae065ef3a38...` | Community message thread \| Maya Chen to Jordan Lee - unread member thread. \| The thread shows sender, body, timestamp, reply path, read state, and archive/block controls. \| Maya -> Jordan \| Unread \| Reply available \| Archive path \| Member conversation \| Maya Chen -> Jordan Lee... | domain-native-reviewed / domain-native | No row-specific failure recorded. | inbox, message thread, connection card, invite, or block-state surface |
| `b25-v4-row-154-export-protected-redaction-0` | Data Portability Community | `export-protected-redaction` | owner | B16_ext_export_migration_export-protected-redaction_start | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B16/screenshots/B16_ext_export_migration_export-protected-redaction_start.png` | `c0fc01a627f15...` | Protected redaction preview \| Mask protected fields with policy reasons before export. \| Review masked phone, care, vault, and payment fields with policy reasons and reveal permissions. \| Scope selected \| Policy masks \| Audit receipt \| Owner artifact \| Protected-field redactio... | domain-native-reviewed / domain-native | No row-specific failure recorded. | export/import wizard with preview, redaction, checksum, transfer status, and rollback state |
| `b25-v4-row-155-export-protected-redaction-1` | Data Portability Community | `export-protected-redaction` | owner | B16_ext_export_migration_export-protected-redaction_action | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B16/screenshots/B16_ext_export_migration_export-protected-redaction_action.png` | `c978dd92bfeeb...` | Protected redaction preview \| Mask protected fields with policy reasons before export. \| Review masked phone, care, vault, and payment fields with policy reasons and reveal permissions. \| Protected-field redaction \| Protected fields \| Care notes, phone numbers, and private vau... | domain-native-reviewed / domain-native | No row-specific failure recorded. | export/import wizard with preview, redaction, checksum, transfer status, and rollback state |
| `b25-v4-row-156-export-protected-redaction-2` | Data Portability Community | `export-protected-redaction` | owner | B16_ext_export_migration_export-protected-redaction_complete | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B16/screenshots/B16_ext_export_migration_export-protected-redaction_complete.png` | `87a92a866735f...` | Protected redaction preview \| Mask protected fields with policy reasons before export. \| Protected redaction shows masked fields, policy reasons, before/after preview, and audit evidence. \| Scope selected \| Policy masks \| Audit receipt \| Owner artifact \| Protected-field redact... | domain-native-reviewed / domain-native | No row-specific failure recorded. | export/import wizard with preview, redaction, checksum, transfer status, and rollback state |
| `b25-v4-row-175-export-import-preview-0` | Data Portability Community | `export-import-preview` | owner | B16_ext_export_migration_export-import-preview_start | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B16/screenshots/B16_ext_export_migration_export-import-preview_start.png` | `1f031f14addb2...` | Legacy import preview \| Preview rows, conflicts, replay checkpoint, and rollback marker. \| Inspect imported member, document, and receipt rows; resolve duplicates; and confirm replay checkpoint before importing. \| Scope selected \| 3 conflicts \| Audit receipt \| Owner artifact \|... | domain-native-reviewed / domain-native | No row-specific failure recorded. | export/import wizard with preview, redaction, checksum, transfer status, and rollback state |
| `b25-v4-row-176-export-import-preview-1` | Data Portability Community | `export-import-preview` | owner | B16_ext_export_migration_export-import-preview_action | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B16/screenshots/B16_ext_export_migration_export-import-preview_action.png` | `cfb3479724b6e...` | Legacy import preview \| Preview rows, conflicts, replay checkpoint, and rollback marker. \| Inspect imported member, document, and receipt rows; resolve duplicates; and confirm replay checkpoint before importing. \| Import rows \| Preview 48 member rows, 22 documents, and 12 rece... | domain-native-reviewed / domain-native | No row-specific failure recorded. | export/import wizard with preview, redaction, checksum, transfer status, and rollback state |
| `b25-v4-row-177-export-import-preview-2` | Data Portability Community | `export-import-preview` | owner | B16_ext_export_migration_export-import-preview_complete | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B16/screenshots/B16_ext_export_migration_export-import-preview_complete.png` | `09d3f1fdb9c14...` | Legacy import preview \| Preview rows, conflicts, replay checkpoint, and rollback marker. \| Import preview shows row counts, duplicate decisions, checkpoint, retry, and rollback state. \| Scope selected \| 3 conflicts \| Audit receipt \| Owner artifact \| Import rows \| Preview 48 me... | domain-native-reviewed / domain-native | No row-specific failure recorded. | export/import wizard with preview, redaction, checksum, transfer status, and rollback state |

### Failing Workflow/Persona Scorecards

Showing 1 of 1 failing scorecards. Full detail is in the JSON ticket.

| Scorecard | Community | Workflow | Persona | Failed questions | Target surface |
| --- | --- | --- | --- | ---: | --- |
| `b25-wp-052-export-protected-redaction-community-export-migration-owner` | Data Portability Community | `export-protected-redaction` | owner | 2 | export/import wizard with preview, redaction, checksum, transfer status, and rollback state |

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
- Screen row `b25-v4-row-088-hoa-owner-notification-0` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-088-hoa-owner-notification-0` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-088-hoa-owner-notification-0` names visible UI elements, visible text, persona `owner`, workflow `hoa-owner-notification`, and the exact product UX issue.
- Primary surface for `hoa-owner-notification` is documented as `notification inbox/detail surface with sender, audience, timestamp, message body, and receiver state` or another explicit domain-native surface.
- After-screenshot visible text proves every required semantic surface group for `hoa-owner-notification`.
- Screen row `b25-v4-row-089-hoa-owner-notification-1` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-089-hoa-owner-notification-1` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-089-hoa-owner-notification-1` names visible UI elements, visible text, persona `owner`, workflow `hoa-owner-notification`, and the exact product UX issue.
- Screen row `b25-v4-row-090-hoa-owner-notification-2` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-090-hoa-owner-notification-2` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-090-hoa-owner-notification-2` names visible UI elements, visible text, persona `owner`, workflow `hoa-owner-notification`, and the exact product UX issue.
- Screen row `b25-v4-row-115-platform-messages-entry-0` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-115-platform-messages-entry-0` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-115-platform-messages-entry-0` names visible UI elements, visible text, persona `member`, workflow `platform-messages-entry`, and the exact product UX issue.
- Primary surface for `platform-messages-entry` is documented as `inbox, message thread, connection card, invite, or block-state surface` or another explicit domain-native surface.
- After-screenshot visible text proves every required semantic surface group for `platform-messages-entry`.
- Screen row `b25-v4-row-116-platform-messages-entry-1` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-116-platform-messages-entry-1` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-116-platform-messages-entry-1` names visible UI elements, visible text, persona `member`, workflow `platform-messages-entry`, and the exact product UX issue.
- Screen row `b25-v4-row-117-platform-messages-entry-2` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-117-platform-messages-entry-2` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-117-platform-messages-entry-2` names visible UI elements, visible text, persona `member`, workflow `platform-messages-entry`, and the exact product UX issue.
- Screen row `b25-v4-row-130-export-import-replay-0` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-130-export-import-replay-0` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-130-export-import-replay-0` names visible UI elements, visible text, persona `owner`, workflow `export-import-replay`, and the exact product UX issue.
- Primary surface for `export-import-replay` is documented as `export/import wizard with preview, redaction, checksum, transfer status, and rollback state` or another explicit domain-native surface.
- After-screenshot visible text proves every required semantic surface group for `export-import-replay`.
- Screen row `b25-v4-row-131-export-import-replay-1` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-131-export-import-replay-1` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-131-export-import-replay-1` names visible UI elements, visible text, persona `owner`, workflow `export-import-replay`, and the exact product UX issue.
- Screen row `b25-v4-row-132-export-import-replay-2` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-132-export-import-replay-2` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-132-export-import-replay-2` names visible UI elements, visible text, persona `owner`, workflow `export-import-replay`, and the exact product UX issue.

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

## B25-RT-002-b25-c03-production-grade-experience

| Field | Value |
| --- | --- |
| Severity | major |
| Priority | P1 |
| Status | open |
| Review run | `b25-v4-pass-24` |
| Source criterion | `b25-c03-production-grade-experience` |
| Source findings | B25-HOLISTIC-UX-FAILED |
| Title | Reviewer can state the experience feels production-grade |
| Direct question | Does the whole experience feel like a real production community app for the target users, not merely an implemented workflow harness? |
| Why it failed | holistic direct-question answers are missing, weak, partial, or blocking: b25-v4-pass-24-modern-easy-appealing, b25-v4-pass-24-community-ia, b25-v4-pass-24-copy-product-native, b25-v4-pass-24-visual-system, b25-v4-pass-24-repeated-card-fatigue, b25-v4-pass-24-concrete-content-lifecycle-actions. |
| Required outcome | Run the independent screenshot-first review and record a production-grade verdict grounded in screen evidence. |
| Remediation mode | `review-only` |
| Worker readiness | no concrete implementation work item was generated; planner must inspect the direct-question failure before assigning a worker |
| First required step | Review failing direct questions and add screen/workflow/persona-specific evidence before implementation. |

### Problem Statement

The evidence does not prove that target users experience the app as a real production community product rather than a workflow validation harness.

### Root Cause Hypothesis

The pass has evidence capture, but not a completed independent product-quality judgment grounded in screenshots.

### Target Experience

A target user should immediately understand the community, see relevant content, and complete meaningful tasks without recognizing the app as a test harness.

### UX Principles
- Judge what the visible product proves, not what the implementation intended.
- Prioritize target-user comprehension, task completion, and product credibility.

### Concrete Improvements
- Run a screenshot-first holistic review of the full community experience from the target-user perspective.
- Record direct yes/no answers that cite visible UI and explain whether the experience feels like a real production community app.
- Fix any whole-product issues where screens feel like validation harnesses, implementation summaries, or thin prototypes.

### Implementation Guidance
- Inspect `apps/loom_communities_demo/lib` for the primary community home, shell, card, detail, and workflow surface widgets.
- Compare every change against `docs/Build Plan V2/Evidence/B25/production-ux-blueprint.md` before coding.
- Update widget tests and B25 evidence expectations when user-facing hierarchy, copy, or surface structure changes.

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

### Reference Research Queries
- production mobile UX review screenshot critique examples
- open source Flutter mobile app UX patterns GitHub

### Implementation Blocked By
- The ticket lacks row-level implementation evidence.

### Failing Direct Questions

| Question | Scope | Score | Why | Required fix |
| --- | --- | ---: | --- | --- |
| Is the UI modern, easy to use, easy to navigate, and visually appealing for the target persona? | holistic | 0 | The screens are readable and mostly unclipped, but they do not feel like differentiated production product screens. The dominant experience is a uniform workflow-card scaffold rather than modern task-specific surfaces. | Replace the generic stacked-card renderer with screen-specific product surfaces such as feeds, inbox threads, event detail pages, payment receipts, export wizards, care request forms, and review queues. |
| Is information architecture centered on real community jobs and content? | holistic | 0 | The content has domain labels, but navigation and page structure are still organized around workflow state cards and validation concepts rather than natural community destinations and jobs. | Reframe home and workflow entry around community sections and objects: event calendars, inboxes, document libraries, donation history, request queues, rosters, and export/recovery workspaces. |
| Does copy sound product-native rather than workflow/spec/test language? | holistic | 0 | The copy often describes the workflow contract rather than speaking as a finished product to the user in the current task. | Rewrite user-facing copy as domain-native product language, using concrete object state and next steps; remove UX-contract phrases from visible screens. |
| Are hierarchy, spacing, typography, color, and component variety shippable? | holistic | 0 | The visual system is coherent but too monotonous and template-bound for a production UX bar across 68 workflow/persona paths. | Introduce task-appropriate layouts and component variety: compact lists, real forms, timelines, tables/checklists where appropriate, receipts, message bubbles, document rows, and richer status/history treatments. |
| Is repeated-card fatigue absent? | holistic | 0 | The repeated-card shell is the dominant user experience, so the app still reads as a generic workflow renderer with domain copy pasted into it. | Create domain-native primary surfaces for each workflow family and reserve cards for individual items, not the entire screen architecture. |
| Does each screen provide concrete content and lifecycle actions a real user needs? | holistic | 0 | The screenshots often include useful details, but B25 cannot pass while lifecycle scorecards and one workflow/persona scorecard still fail, and several result states remain generic. | Add screenshot-proven concrete object context and persistent result/receiver states for failed workflows, then rerun lifecycle and LLM review gates. |

### Likely Files / Widgets
- `app/apps/loom_communities_demo/lib/main.dart`
- `app/apps/loom_communities_demo/test/b21_b25_production_ux_test.dart`
- `docs/Build Plan V2/Evidence/B25/production-ux-blueprint.md`
- `docs/Build Plan V2/Evidence/B25/independent-production-ux-review.json`
- `docs/Build Plan V2/Evidence/B25/product-ux-screen-review-matrix.md`

### Concrete Acceptance Criteria
- Holistic direct-question answers are present, screenshot-backed, non-boilerplate, and pass.
- `production_ux_judge.dart` has no blocking failure for this criterion.
- `b25_iteration_scorecard.dart` records the ticket as resolved or no longer blocking.
- Screenshots are refreshed and hashes/timestamps/app commit SHA match the reviewed app version.

### Affected Evidence
- `independent-production-ux-review.json holisticQuestionAnswers`
- `independent-production-ux-review.md holistic review summary`
- `product-ux-screen-review-matrix.md relevant screen rows`
- `production-ux-criteria-scorecard.json/.md`

### Evidence To Collect
- Fresh holistic screenshots for primary homes, navigation, representative detail surfaces, and representative completion/result states.
- `holisticQuestionAnswers` with visible evidence, score, pass/fail answer, and specific rationale.
- `llmVisionReview` imported from a fresh LLM vision UX judge run against the after screenshots.
- Updated `production-ux-criteria-scorecard.json/.md` showing the criterion passes.

### Acceptance Checks
- Holistic direct-question answers are present, screenshot-backed, non-boilerplate, and pass.
- `production_ux_judge.dart` has no blocking failure for this criterion.
- `b25_iteration_scorecard.dart` records the ticket as resolved or no longer blocking.
- Screenshots are refreshed and hashes/timestamps/app commit SHA match the reviewed app version.

### Non-Goals
- Do not pass based on implementation intent or code structure.
- Do not treat a captured screenshot as proof of product quality without direct-question answers.
- Do not fix only labels while leaving generic scaffold structure unchanged.

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

## B25-RT-003-b25-c14-llm-vision-ux-review

| Field | Value |
| --- | --- |
| Severity | major |
| Priority | P1 |
| Status | open |
| Review run | `b25-v4-pass-24` |
| Source criterion | `b25-c14-llm-vision-ux-review` |
| Source findings | B25-WORKFLOW-PERSONA-UX-FAILED, B25-WORKFLOW-LIFECYCLE-INCOMPLETE, LLM-UX-primary-ux-is-still-a-repeated-workflow-card-scaffold-across-the-evidence-set, LLM-UX-visible-copy-exposes-workflow-contract-language-instead-of-product-native-task-language, LLM-UX-several-workflow-persona-lifecycles-still-lack-concrete-object-context-or-persistent-result-state, LLM-UX-persona-picker-and-role-inventory-evidence-exposes-local-test-harness-ui-as-reviewed-product-surface |
| Title | LLM vision UX judge has inspected screenshots semantically |
| Direct question | Has a fresh LLM vision UX Judge inspected the actual screenshots as product UI, answered direct UX questions from visible evidence, and found no blocker or major product-quality issues? |
| Why it failed | The LLM vision UX review failed from screenshot inspection. blockingFindings=LLM-UX-primary-ux-is-still-a-repeated-workflow-card-scaffold-across-the-evidence-set, LLM-UX-visible-copy-exposes-workflow-contract-language-instead-of-product-native-task-language, LLM-UX-several-workflow-persona-lifecycles-still-lack-concrete-object-context-or-persistent-result-state, LLM-UX-persona-picker-and-role-inventory-evidence-exposes-local-test-harness-ui-as-reviewed-product-surface blockingQuestions=b25-v4-pass-24-modern-easy-appealing, b25-v4-pass-24-community-ia, b25-v4-pass-24-copy-product-native, b25-v4-pass-24-visual-system, b25-v4-pass-24-repeated-card-fatigue, b25-v4-pass-24-concrete-content-lifecycle-actions blockingScreens=. |
| Required outcome | Run the B25 LLM Vision UX Judge Agent on the screenshot evidence, import its structured review, fix all blocker/major findings, and rerun B25. |
| Remediation mode | `evidence-repair-first` |
| Worker readiness | not ready for UI implementation until evidence repair work items are completed and the independent judge reruns |
| First required step | Complete the evidenceRepairWorkItems: concrete persona/personaId, screenshot-derived visible text, screen-specific critique, coverage row proof, and workflow/persona scorecards. |

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
| Task list and export wizard | GOV.UK Design System / design-system | https://design-system.service.gov.uk/components/task-list/<br>Also: https://design-system.service.gov.uk/patterns/check-answers/ | Copy a wizard with steps, preview, redaction choices, checksum evidence, transfer status, and rollback confirmation. |

### Reference Research Queries
- production mobile UX review screenshot critique examples
- open source Flutter mobile app UX patterns GitHub
- open source Flutter export-wizard mobile UI example GitHub
- export/import wizard with preview, redaction, checksum, transfer status, and rollback state mobile UX pattern
- Material Design export/import wizard with preview, redaction, checksum, transfer status, and rollback state mobile pattern

### Implementation Blocked By
- Affected rows still use generic or missing persona data.
- Visible text is not proven from screenshot OCR/manual extraction.
- Screen-specific critiques are incomplete or reusable.
- Primary surface classification is incomplete or unverified.

### Evidence Repair Work Items

Showing 1 of 1 work items. Full detail is in the JSON artifact.

| Work item | Stage | Community | Workflow | Persona | Screens | Coverage | Target surface | Blocked until |
| --- | --- | --- | --- | --- | ---: | ---: | --- | --- |
| `b25-wi-evidence-repair-community-export-migration-export-protected-redaction-community-export-migration-owner` | `evidence-repair` | Data Portability Community | `export-protected-redaction` | owner | 3 | 0 | export/import wizard with preview, redaction, checksum, transfer status, and rollback state |  |

### Evidence Repair Work Items Reference Patterns

| Reference | Source | URL | What to copy |
| --- | --- | --- | --- |
| Task list and export wizard | GOV.UK Design System / design-system | https://design-system.service.gov.uk/components/task-list/<br>Also: https://design-system.service.gov.uk/patterns/check-answers/ | Copy a wizard with steps, preview, redaction choices, checksum evidence, transfer status, and rollback confirmation. |
| Material Design cards and lists | Material Design 3 / design-system | https://m3.material.io/components/cards/overview<br>Also: https://m3.material.io/components/lists/overview | Use cards/lists only as scannable containers with clear hierarchy, content, metadata, and actions. Do not use repeated cards as the whole primary workflow. |
| Flutter sample app implementation patterns | flutter/samples / open-source | https://github.com/flutter/samples | Copy the separation between app shell, route state, domain widgets, and testable UI states rather than hardcoding a single generic renderer. |
| Material navigation and information architecture | Material Design 3 / design-system | https://m3.material.io/components/navigation-drawer/overview<br>Also: https://m3.material.io/components/navigation-bar/overview | Organize screens by user jobs and destinations; keep primary actions visible and avoid exposing implementation taxonomy. |
| Apple HIG navigation and content organization | Apple Human Interface Guidelines / design-system | https://developer.apple.com/design/human-interface-guidelines/navigation | Make navigation predictable, content-centered, and appropriate for the user’s current task. |

### Affected Screen Rows

Showing 3 of 3 affected screen rows. Full detail is in the JSON ticket.

| Screen row | Community | Workflow | Persona | State | Screenshot | Hash | Visible text | Current surface | Exact UX failure | Target surface |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `b25-v4-row-154-export-protected-redaction-0` | Data Portability Community | `export-protected-redaction` | owner | B16_ext_export_migration_export-protected-redaction_start | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B16/screenshots/B16_ext_export_migration_export-protected-redaction_start.png` | `c0fc01a627f15...` | Protected redaction preview \| Mask protected fields with policy reasons before export. \| Review masked phone, care, vault, and payment fields with policy reasons and reveal permissions. \| Scope selected \| Policy masks \| Audit receipt \| Owner artifact \| Protected-field redactio... | domain-native-reviewed / domain-native | No row-specific failure recorded. | export/import wizard with preview, redaction, checksum, transfer status, and rollback state |
| `b25-v4-row-155-export-protected-redaction-1` | Data Portability Community | `export-protected-redaction` | owner | B16_ext_export_migration_export-protected-redaction_action | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B16/screenshots/B16_ext_export_migration_export-protected-redaction_action.png` | `c978dd92bfeeb...` | Protected redaction preview \| Mask protected fields with policy reasons before export. \| Review masked phone, care, vault, and payment fields with policy reasons and reveal permissions. \| Protected-field redaction \| Protected fields \| Care notes, phone numbers, and private vau... | domain-native-reviewed / domain-native | No row-specific failure recorded. | export/import wizard with preview, redaction, checksum, transfer status, and rollback state |
| `b25-v4-row-156-export-protected-redaction-2` | Data Portability Community | `export-protected-redaction` | owner | B16_ext_export_migration_export-protected-redaction_complete | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B16/screenshots/B16_ext_export_migration_export-protected-redaction_complete.png` | `87a92a866735f...` | Protected redaction preview \| Mask protected fields with policy reasons before export. \| Protected redaction shows masked fields, policy reasons, before/after preview, and audit evidence. \| Scope selected \| Policy masks \| Audit receipt \| Owner artifact \| Protected-field redact... | domain-native-reviewed / domain-native | No row-specific failure recorded. | export/import wizard with preview, redaction, checksum, transfer status, and rollback state |

### Failing Workflow/Persona Scorecards

Showing 1 of 1 failing scorecards. Full detail is in the JSON ticket.

| Scorecard | Community | Workflow | Persona | Failed questions | Target surface |
| --- | --- | --- | --- | ---: | --- |
| `b25-wp-052-export-protected-redaction-community-export-migration-owner` | Data Portability Community | `export-protected-redaction` | owner | 2 | export/import wizard with preview, redaction, checksum, transfer status, and rollback state |

### Failing Direct Questions

| Question | Scope | Score | Why | Required fix |
| --- | --- | ---: | --- | --- |
| Is the UI modern, easy to use, easy to navigate, and visually appealing for the target persona? | holistic | 0 | The screens are readable and mostly unclipped, but they do not feel like differentiated production product screens. The dominant experience is a uniform workflow-card scaffold rather than modern task-specific surfaces. | Replace the generic stacked-card renderer with screen-specific product surfaces such as feeds, inbox threads, event detail pages, payment receipts, export wizards, care request forms, and review queues. |
| Is information architecture centered on real community jobs and content? | holistic | 0 | The content has domain labels, but navigation and page structure are still organized around workflow state cards and validation concepts rather than natural community destinations and jobs. | Reframe home and workflow entry around community sections and objects: event calendars, inboxes, document libraries, donation history, request queues, rosters, and export/recovery workspaces. |
| Does copy sound product-native rather than workflow/spec/test language? | holistic | 0 | The copy often describes the workflow contract rather than speaking as a finished product to the user in the current task. | Rewrite user-facing copy as domain-native product language, using concrete object state and next steps; remove UX-contract phrases from visible screens. |
| Are hierarchy, spacing, typography, color, and component variety shippable? | holistic | 0 | The visual system is coherent but too monotonous and template-bound for a production UX bar across 68 workflow/persona paths. | Introduce task-appropriate layouts and component variety: compact lists, real forms, timelines, tables/checklists where appropriate, receipts, message bubbles, document rows, and richer status/history treatments. |
| Is repeated-card fatigue absent? | holistic | 0 | The repeated-card shell is the dominant user experience, so the app still reads as a generic workflow renderer with domain copy pasted into it. | Create domain-native primary surfaces for each workflow family and reserve cards for individual items, not the entire screen architecture. |
| Does each screen provide concrete content and lifecycle actions a real user needs? | holistic | 0 | The screenshots often include useful details, but B25 cannot pass while lifecycle scorecards and one workflow/persona scorecard still fail, and several result states remain generic. | Add screenshot-proven concrete object context and persistent result/receiver states for failed workflows, then rerun lifecycle and LLM review gates. |

### Likely Files / Widgets
- `app/apps/loom_communities_demo/lib/main.dart`
- `app/apps/loom_communities_demo/test/b21_b25_production_ux_test.dart`
- `docs/Build Plan V2/Evidence/B25/production-ux-blueprint.md`
- `docs/Build Plan V2/Evidence/B25/independent-production-ux-review.json`
- `docs/Build Plan V2/Evidence/B25/product-ux-screen-review-matrix.md`
- `app/apps/loom_communities_demo/integration_test/workflow_ui_evidence_test.dart`
- `app/apps/loom_communities_demo/test/workflow_ui_test_harness.dart`

### Concrete Acceptance Criteria
- `production_ux_judge.dart` has no blocking failure for this criterion.
- `b25_iteration_scorecard.dart` records the ticket as resolved or no longer blocking.
- Screenshots are refreshed and hashes/timestamps/app commit SHA match the reviewed app version.
- Screen row `b25-v4-row-154-export-protected-redaction-0` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-154-export-protected-redaction-0` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-154-export-protected-redaction-0` names visible UI elements, visible text, persona `owner`, workflow `export-protected-redaction`, and the exact product UX issue.
- Primary surface for `export-protected-redaction` is documented as `export/import wizard with preview, redaction, checksum, transfer status, and rollback state` or another explicit domain-native surface.
- After-screenshot visible text proves every required semantic surface group for `export-protected-redaction`.
- Fresh screenshot path/hash/timestamp/app commit SHA are recorded after the fix.
- Screen row `b25-v4-row-155-export-protected-redaction-1` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-155-export-protected-redaction-1` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-155-export-protected-redaction-1` names visible UI elements, visible text, persona `owner`, workflow `export-protected-redaction`, and the exact product UX issue.
- Screen row `b25-v4-row-156-export-protected-redaction-2` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-156-export-protected-redaction-2` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-156-export-protected-redaction-2` names visible UI elements, visible text, persona `owner`, workflow `export-protected-redaction`, and the exact product UX issue.

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

## B25-RT-004-b25-c04-modern-intentional-ui

| Field | Value |
| --- | --- |
| Severity | major |
| Priority | P1 |
| Status | open |
| Review run | `b25-v4-pass-24` |
| Source criterion | `b25-c04-modern-intentional-ui` |
| Source findings | B25-HOLISTIC-UX-FAILED |
| Title | UI looks modern and intentionally designed |
| Direct question | Is the UI modern, easy to use, easy to navigate, and visually appealing for the target persona? |
| Why it failed | holistic direct-question answers are missing, weak, partial, or blocking: b25-v4-pass-24-modern-easy-appealing, b25-v4-pass-24-community-ia, b25-v4-pass-24-copy-product-native, b25-v4-pass-24-visual-system, b25-v4-pass-24-repeated-card-fatigue, b25-v4-pass-24-concrete-content-lifecycle-actions. |
| Required outcome | Remediate visual hierarchy, spacing, typography, component quality, and recapture screenshots. |
| Remediation mode | `review-only` |
| Worker readiness | no concrete implementation work item was generated; planner must inspect the direct-question failure before assigning a worker |
| First required step | Review failing direct questions and add screen/workflow/persona-specific evidence before implementation. |

### Problem Statement

The evidence does not prove that the UI is modern, visually intentional, easy to navigate, and appealing for the target personas.

### Root Cause Hypothesis

The pass lacks screenshot-backed judgment of hierarchy, spacing, navigation clarity, component polish, and visual identity.

### Target Experience

Screens should feel intentionally designed, polished, readable, well-spaced, navigable, and visually coherent on the reviewed device.

### UX Principles
- Clear visual hierarchy
- Predictable navigation
- Consistent spacing and component quality
- Modern mobile readability and touch targets

### Concrete Improvements
- Improve visual hierarchy, typography scale, spacing rhythm, component polish, and content grouping on primary screens.
- Ensure navigation and primary actions are obvious without reading implementation or workflow taxonomy.
- Recapture screenshots and cite visible evidence proving the UI is modern, easy to use, easy to navigate, and visually appealing.

### Implementation Guidance
- Inspect `apps/loom_communities_demo/lib` for the primary community home, shell, card, detail, and workflow surface widgets.
- Compare every change against `docs/Build Plan V2/Evidence/B25/production-ux-blueprint.md` before coding.
- Update widget tests and B25 evidence expectations when user-facing hierarchy, copy, or surface structure changes.

### Content Guidance
- Replace placeholder, framework, workflow, evidence, or metadata language with user-facing product copy.
- Use content that helps the target persona understand status, options, consequences, and next steps.

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

### Reference Research Queries
- modern mobile app information architecture visual hierarchy examples
- Material Design 3 mobile UI hierarchy navigation cards examples
- open source Flutter production app dashboard detail screen examples

### Implementation Blocked By
- The ticket lacks row-level implementation evidence.

### Failing Direct Questions

| Question | Scope | Score | Why | Required fix |
| --- | --- | ---: | --- | --- |
| Is the UI modern, easy to use, easy to navigate, and visually appealing for the target persona? | holistic | 0 | The screens are readable and mostly unclipped, but they do not feel like differentiated production product screens. The dominant experience is a uniform workflow-card scaffold rather than modern task-specific surfaces. | Replace the generic stacked-card renderer with screen-specific product surfaces such as feeds, inbox threads, event detail pages, payment receipts, export wizards, care request forms, and review queues. |
| Is information architecture centered on real community jobs and content? | holistic | 0 | The content has domain labels, but navigation and page structure are still organized around workflow state cards and validation concepts rather than natural community destinations and jobs. | Reframe home and workflow entry around community sections and objects: event calendars, inboxes, document libraries, donation history, request queues, rosters, and export/recovery workspaces. |
| Does copy sound product-native rather than workflow/spec/test language? | holistic | 0 | The copy often describes the workflow contract rather than speaking as a finished product to the user in the current task. | Rewrite user-facing copy as domain-native product language, using concrete object state and next steps; remove UX-contract phrases from visible screens. |
| Are hierarchy, spacing, typography, color, and component variety shippable? | holistic | 0 | The visual system is coherent but too monotonous and template-bound for a production UX bar across 68 workflow/persona paths. | Introduce task-appropriate layouts and component variety: compact lists, real forms, timelines, tables/checklists where appropriate, receipts, message bubbles, document rows, and richer status/history treatments. |
| Is repeated-card fatigue absent? | holistic | 0 | The repeated-card shell is the dominant user experience, so the app still reads as a generic workflow renderer with domain copy pasted into it. | Create domain-native primary surfaces for each workflow family and reserve cards for individual items, not the entire screen architecture. |
| Does each screen provide concrete content and lifecycle actions a real user needs? | holistic | 0 | The screenshots often include useful details, but B25 cannot pass while lifecycle scorecards and one workflow/persona scorecard still fail, and several result states remain generic. | Add screenshot-proven concrete object context and persistent result/receiver states for failed workflows, then rerun lifecycle and LLM review gates. |

### Likely Files / Widgets
- `app/apps/loom_communities_demo/lib/main.dart`
- `app/apps/loom_communities_demo/test/b21_b25_production_ux_test.dart`
- `docs/Build Plan V2/Evidence/B25/production-ux-blueprint.md`
- `docs/Build Plan V2/Evidence/B25/independent-production-ux-review.json`
- `docs/Build Plan V2/Evidence/B25/product-ux-screen-review-matrix.md`

### Concrete Acceptance Criteria
- Holistic direct-question answers are present, screenshot-backed, non-boilerplate, and pass.
- `production_ux_judge.dart` has no blocking failure for this criterion.
- `b25_iteration_scorecard.dart` records the ticket as resolved or no longer blocking.
- Screenshots are refreshed and hashes/timestamps/app commit SHA match the reviewed app version.

### Affected Evidence
- `independent-production-ux-review.json holisticQuestionAnswers`
- `independent-production-ux-review.md holistic review summary`
- `product-ux-screen-review-matrix.md relevant screen rows`
- `production-ux-criteria-scorecard.json/.md`

### Evidence To Collect
- Fresh holistic screenshots for primary homes, navigation, representative detail surfaces, and representative completion/result states.
- `holisticQuestionAnswers` with visible evidence, score, pass/fail answer, and specific rationale.
- `llmVisionReview` imported from a fresh LLM vision UX judge run against the after screenshots.
- Updated `production-ux-criteria-scorecard.json/.md` showing the criterion passes.

### Acceptance Checks
- Holistic direct-question answers are present, screenshot-backed, non-boilerplate, and pass.
- `production_ux_judge.dart` has no blocking failure for this criterion.
- `b25_iteration_scorecard.dart` records the ticket as resolved or no longer blocking.
- Screenshots are refreshed and hashes/timestamps/app commit SHA match the reviewed app version.

### Non-Goals
- Do not pass based on implementation intent or code structure.
- Do not treat a captured screenshot as proof of product quality without direct-question answers.
- Do not fix only labels while leaving generic scaffold structure unchanged.

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

## B25-RT-005-b25-c05-community-content-ia

| Field | Value |
| --- | --- |
| Severity | major |
| Priority | P1 |
| Status | open |
| Review run | `b25-v4-pass-24` |
| Source criterion | `b25-c05-community-content-ia` |
| Source findings | B25-HOLISTIC-UX-FAILED |
| Title | Screens are organized around community content and jobs-to-be-done |
| Direct question | Is the overall information architecture organized around community content and real jobs-to-be-done instead of workflow lists or validation surfaces? |
| Why it failed | holistic direct-question answers are missing, weak, partial, or blocking: b25-v4-pass-24-modern-easy-appealing, b25-v4-pass-24-community-ia, b25-v4-pass-24-copy-product-native, b25-v4-pass-24-visual-system, b25-v4-pass-24-repeated-card-fatigue, b25-v4-pass-24-concrete-content-lifecycle-actions. |
| Required outcome | Rebuild home and primary screens around community content and user jobs. |
| Remediation mode | `review-only` |
| Worker readiness | no concrete implementation work item was generated; planner must inspect the direct-question failure before assigning a worker |
| First required step | Review failing direct questions and add screen/workflow/persona-specific evidence before implementation. |

### Problem Statement

The evidence does not prove that primary screens are organized around community content and jobs-to-be-done instead of workflow lists or validation surfaces.

### Root Cause Hypothesis

The app may still be organized around implementation/workflow concepts instead of the mental model and daily jobs of community users.

### Target Experience

The home and primary flows should lead with community-specific sections, content, and jobs-to-be-done rather than implementation categories.

### UX Principles
- Community content first
- Jobs-to-be-done information architecture
- No global workflow-list primary UX

### Concrete Improvements
- Rework primary home/detail screens around community jobs-to-be-done and domain content.
- Replace any global workflow-list organization with sections such as announcements, events, dues, messages, documents, care requests, teams, or equivalent community-specific content.
- Update holistic answers and screen critiques to prove users see community tasks and content first.

### Implementation Guidance
- Inspect `apps/loom_communities_demo/lib` for the primary community home, shell, card, detail, and workflow surface widgets.
- Compare every change against `docs/Build Plan V2/Evidence/B25/production-ux-blueprint.md` before coding.
- Update widget tests and B25 evidence expectations when user-facing hierarchy, copy, or surface structure changes.

### Content Guidance
- Lead screens with community-specific content: announcements, events, requests, payments, documents, messages, teams, facilities, or equivalent domain sections.
- Remove or demote labels that describe workflow categories, evidence, local routes, or implementation mechanics.
- Use realistic names, dates, amounts, authors, locations, status, receipts, and next steps where the workflow requires them.

### Visual Guidance
- Group content into scannable community sections with clear visual hierarchy.
- Make the primary path visible without requiring users to scan a global workflow list.

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
- community app home screen announcements events messages design examples
- open source Flutter community app home feed events messages UI

### Implementation Blocked By
- The ticket lacks row-level implementation evidence.

### Failing Direct Questions

| Question | Scope | Score | Why | Required fix |
| --- | --- | ---: | --- | --- |
| Is the UI modern, easy to use, easy to navigate, and visually appealing for the target persona? | holistic | 0 | The screens are readable and mostly unclipped, but they do not feel like differentiated production product screens. The dominant experience is a uniform workflow-card scaffold rather than modern task-specific surfaces. | Replace the generic stacked-card renderer with screen-specific product surfaces such as feeds, inbox threads, event detail pages, payment receipts, export wizards, care request forms, and review queues. |
| Is information architecture centered on real community jobs and content? | holistic | 0 | The content has domain labels, but navigation and page structure are still organized around workflow state cards and validation concepts rather than natural community destinations and jobs. | Reframe home and workflow entry around community sections and objects: event calendars, inboxes, document libraries, donation history, request queues, rosters, and export/recovery workspaces. |
| Does copy sound product-native rather than workflow/spec/test language? | holistic | 0 | The copy often describes the workflow contract rather than speaking as a finished product to the user in the current task. | Rewrite user-facing copy as domain-native product language, using concrete object state and next steps; remove UX-contract phrases from visible screens. |
| Are hierarchy, spacing, typography, color, and component variety shippable? | holistic | 0 | The visual system is coherent but too monotonous and template-bound for a production UX bar across 68 workflow/persona paths. | Introduce task-appropriate layouts and component variety: compact lists, real forms, timelines, tables/checklists where appropriate, receipts, message bubbles, document rows, and richer status/history treatments. |
| Is repeated-card fatigue absent? | holistic | 0 | The repeated-card shell is the dominant user experience, so the app still reads as a generic workflow renderer with domain copy pasted into it. | Create domain-native primary surfaces for each workflow family and reserve cards for individual items, not the entire screen architecture. |
| Does each screen provide concrete content and lifecycle actions a real user needs? | holistic | 0 | The screenshots often include useful details, but B25 cannot pass while lifecycle scorecards and one workflow/persona scorecard still fail, and several result states remain generic. | Add screenshot-proven concrete object context and persistent result/receiver states for failed workflows, then rerun lifecycle and LLM review gates. |

### Likely Files / Widgets
- `app/apps/loom_communities_demo/lib/main.dart`
- `app/apps/loom_communities_demo/test/b21_b25_production_ux_test.dart`
- `docs/Build Plan V2/Evidence/B25/production-ux-blueprint.md`
- `docs/Build Plan V2/Evidence/B25/independent-production-ux-review.json`
- `docs/Build Plan V2/Evidence/B25/product-ux-screen-review-matrix.md`

### Concrete Acceptance Criteria
- Holistic direct-question answers are present, screenshot-backed, non-boilerplate, and pass.
- `production_ux_judge.dart` has no blocking failure for this criterion.
- `b25_iteration_scorecard.dart` records the ticket as resolved or no longer blocking.
- Screenshots are refreshed and hashes/timestamps/app commit SHA match the reviewed app version.

### Affected Evidence
- `independent-production-ux-review.json holisticQuestionAnswers`
- `independent-production-ux-review.md holistic review summary`
- `product-ux-screen-review-matrix.md relevant screen rows`
- `production-ux-criteria-scorecard.json/.md`

### Evidence To Collect
- Fresh holistic screenshots for primary homes, navigation, representative detail surfaces, and representative completion/result states.
- `holisticQuestionAnswers` with visible evidence, score, pass/fail answer, and specific rationale.
- `llmVisionReview` imported from a fresh LLM vision UX judge run against the after screenshots.
- Updated `production-ux-criteria-scorecard.json/.md` showing the criterion passes.

### Acceptance Checks
- Holistic direct-question answers are present, screenshot-backed, non-boilerplate, and pass.
- `production_ux_judge.dart` has no blocking failure for this criterion.
- `b25_iteration_scorecard.dart` records the ticket as resolved or no longer blocking.
- Screenshots are refreshed and hashes/timestamps/app commit SHA match the reviewed app version.

### Non-Goals
- Do not rename a generic workflow card and call it domain-native.
- Do not keep global workflow lists as the primary home or primary workflow UI.
- Do not use metadata/settings pages as substitutes for task-specific product surfaces.

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

## B25-RT-006-b25-c06-domain-native-primary-surfaces

| Field | Value |
| --- | --- |
| Severity | major |
| Priority | P1 |
| Status | open |
| Review run | `b25-v4-pass-24` |
| Source criterion | `b25-c06-domain-native-primary-surfaces` |
| Source findings | B25-WORKFLOW-PERSONA-UX-FAILED, B25-WORKFLOW-LIFECYCLE-INCOMPLETE, LLM-UX-primary-ux-is-still-a-repeated-workflow-card-scaffold-across-the-evidence-set, LLM-UX-visible-copy-exposes-workflow-contract-language-instead-of-product-native-task-language, LLM-UX-several-workflow-persona-lifecycles-still-lack-concrete-object-context-or-persistent-result-state, LLM-UX-persona-picker-and-role-inventory-evidence-exposes-local-test-harness-ui-as-reviewed-product-surface |
| Title | Primary workflows use domain-specific product surfaces |
| Direct question | For every workflow and persona, is the primary UI a domain-native product surface rather than a generic card, checklist modal, or metadata page? |
| Why it failed | Workflow/persona direct-question scorecards have missing or blocking answers: export-protected-redaction/owner. |
| Required outcome | Replace primary generic surfaces with domain-native product surfaces. |
| Remediation mode | `evidence-repair-before-ui-remediation` |
| Worker readiness | not ready for UI implementation until evidence repair work items are completed and the independent judge reruns |
| First required step | Complete the evidenceRepairWorkItems: concrete persona/personaId, screenshot-derived visible text, screen-specific critique, coverage row proof, and workflow/persona scorecards. |

### Problem Statement

The evidence does not prove that each primary workflow/persona UI is a domain-native product surface rather than a generic card, checklist modal, or metadata page.

### Root Cause Hypothesis

Primary workflow surfaces may still rely on generic repeated cards or validation-state UI instead of task-specific product screens.

### Target Experience

Each primary workflow should use the product surface a real app would use for that job, such as an event detail, feed item, donation flow, care form, review queue, thread, receipt, search result, export wizard, or transfer status screen.

### UX Principles
- Primary surfaces must match the domain task
- Generic cards are acceptable only as secondary support, not primary workflow UI

### Concrete Improvements
- Review every primary workflow/persona row and classify the visible UI as domain-native, secondary-supporting, or generic.
- Replace primary generic cards, checklist modals, metadata pages, or repeated card shells with domain-specific product surfaces.
- Create workflow/persona scorecards proving each primary workflow surface is domain-native for its target persona.

### Implementation Guidance
- Inspect workflow surface builders and replace primary generic card/checklist/modal renderers with task-specific widgets.
- Use B21 production UX contracts to choose the target surface type for each workflow/persona pair.
- Update screenshot evidence manifests so each replaced surface is captured at entry, action, and result states.

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
| Material detail surface composition | Material Design 3 / design-system | https://m3.material.io/components/cards/overview | Build a domain detail page with primary content, metadata, status, and actions instead of a generic task card. |
| Material Design cards and lists | Material Design 3 / design-system | https://m3.material.io/components/cards/overview<br>Also: https://m3.material.io/components/lists/overview | Use cards/lists only as scannable containers with clear hierarchy, content, metadata, and actions. Do not use repeated cards as the whole primary workflow. |
| Flutter sample app implementation patterns | flutter/samples / open-source | https://github.com/flutter/samples | Copy the separation between app shell, route state, domain widgets, and testable UI states rather than hardcoding a single generic renderer. |
| Task list and export wizard | GOV.UK Design System / design-system | https://design-system.service.gov.uk/components/task-list/<br>Also: https://design-system.service.gov.uk/patterns/check-answers/ | Copy a wizard with steps, preview, redaction choices, checksum evidence, transfer status, and rollback confirmation. |
| Material navigation and information architecture | Material Design 3 / design-system | https://m3.material.io/components/navigation-drawer/overview<br>Also: https://m3.material.io/components/navigation-bar/overview | Organize screens by user jobs and destinations; keep primary actions visible and avoid exposing implementation taxonomy. |
| Apple HIG navigation and content organization | Apple Human Interface Guidelines / design-system | https://developer.apple.com/design/human-interface-guidelines/navigation | Make navigation predictable, content-centered, and appropriate for the user’s current task. |

### Reference Research Queries
- domain specific mobile workflow UI event RSVP donation message export examples
- open source Flutter event RSVP donation messaging workflow UI examples
- open source Flutter export-wizard mobile UI example GitHub
- export/import wizard with preview, redaction, checksum, transfer status, and rollback state mobile UX pattern
- Material Design export/import wizard with preview, redaction, checksum, transfer status, and rollback state mobile pattern

### Implementation Blocked By
- Affected rows still use generic or missing persona data.
- Visible text is not proven from screenshot OCR/manual extraction.
- Screen-specific critiques are incomplete or reusable.
- Primary surface classification is incomplete or unverified.

### Evidence Repair Work Items

Showing 1 of 1 work items. Full detail is in the JSON artifact.

| Work item | Stage | Community | Workflow | Persona | Screens | Coverage | Target surface | Blocked until |
| --- | --- | --- | --- | --- | ---: | ---: | --- | --- |
| `b25-wi-evidence-repair-community-export-migration-export-protected-redaction-community-export-migration-owner` | `evidence-repair` | Data Portability Community | `export-protected-redaction` | owner | 3 | 1 | export/import wizard with preview, redaction, checksum, transfer status, and rollback state |  |

### Evidence Repair Work Items Reference Patterns

| Reference | Source | URL | What to copy |
| --- | --- | --- | --- |
| Task list and export wizard | GOV.UK Design System / design-system | https://design-system.service.gov.uk/components/task-list/<br>Also: https://design-system.service.gov.uk/patterns/check-answers/ | Copy a wizard with steps, preview, redaction choices, checksum evidence, transfer status, and rollback confirmation. |
| Material Design cards and lists | Material Design 3 / design-system | https://m3.material.io/components/cards/overview<br>Also: https://m3.material.io/components/lists/overview | Use cards/lists only as scannable containers with clear hierarchy, content, metadata, and actions. Do not use repeated cards as the whole primary workflow. |
| Flutter sample app implementation patterns | flutter/samples / open-source | https://github.com/flutter/samples | Copy the separation between app shell, route state, domain widgets, and testable UI states rather than hardcoding a single generic renderer. |
| Material navigation and information architecture | Material Design 3 / design-system | https://m3.material.io/components/navigation-drawer/overview<br>Also: https://m3.material.io/components/navigation-bar/overview | Organize screens by user jobs and destinations; keep primary actions visible and avoid exposing implementation taxonomy. |
| Apple HIG navigation and content organization | Apple Human Interface Guidelines / design-system | https://developer.apple.com/design/human-interface-guidelines/navigation | Make navigation predictable, content-centered, and appropriate for the user’s current task. |

### UI Remediation Work Items

Showing 1 of 1 work items. Full detail is in the JSON artifact.

| Work item | Stage | Community | Workflow | Persona | Screens | Coverage | Target surface | Blocked until |
| --- | --- | --- | --- | --- | ---: | ---: | --- | --- |
| `b25-wi-ui-remediation-community-export-migration-export-protected-redaction-community-export-migration-owner` | `ui-remediation` | Data Portability Community | `export-protected-redaction` | owner | 3 | 1 | export/import wizard with preview, redaction, checksum, transfer status, and rollback state | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |

### UI Remediation Work Items Reference Patterns

| Reference | Source | URL | What to copy |
| --- | --- | --- | --- |
| Task list and export wizard | GOV.UK Design System / design-system | https://design-system.service.gov.uk/components/task-list/<br>Also: https://design-system.service.gov.uk/patterns/check-answers/ | Copy a wizard with steps, preview, redaction choices, checksum evidence, transfer status, and rollback confirmation. |
| Material Design cards and lists | Material Design 3 / design-system | https://m3.material.io/components/cards/overview<br>Also: https://m3.material.io/components/lists/overview | Use cards/lists only as scannable containers with clear hierarchy, content, metadata, and actions. Do not use repeated cards as the whole primary workflow. |
| Flutter sample app implementation patterns | flutter/samples / open-source | https://github.com/flutter/samples | Copy the separation between app shell, route state, domain widgets, and testable UI states rather than hardcoding a single generic renderer. |
| Material navigation and information architecture | Material Design 3 / design-system | https://m3.material.io/components/navigation-drawer/overview<br>Also: https://m3.material.io/components/navigation-bar/overview | Organize screens by user jobs and destinations; keep primary actions visible and avoid exposing implementation taxonomy. |
| Apple HIG navigation and content organization | Apple Human Interface Guidelines / design-system | https://developer.apple.com/design/human-interface-guidelines/navigation | Make navigation predictable, content-centered, and appropriate for the user’s current task. |

### Affected Workflow/Persona Coverage

Showing 1 of 1 affected coverage rows. Full detail is in the JSON ticket.

| Coverage row | Status | Community | Workflow | Persona | Missing evidence | Screen rows | Target surface |
| --- | --- | --- | --- | --- | --- | ---: | --- |
| `b25-wp-052-export-protected-redaction-community-export-migration-owner` | `pass` | Data Portability Community | `export-protected-redaction` | owner |  | 3 | export/import wizard with preview, redaction, checksum, transfer status, and rollback state |

### Affected Screen Rows

Showing 3 of 3 affected screen rows. Full detail is in the JSON ticket.

| Screen row | Community | Workflow | Persona | State | Screenshot | Hash | Visible text | Current surface | Exact UX failure | Target surface |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `b25-v4-row-154-export-protected-redaction-0` | Data Portability Community | `export-protected-redaction` | owner | B16_ext_export_migration_export-protected-redaction_start | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B16/screenshots/B16_ext_export_migration_export-protected-redaction_start.png` | `c0fc01a627f15...` | Protected redaction preview \| Mask protected fields with policy reasons before export. \| Review masked phone, care, vault, and payment fields with policy reasons and reveal permissions. \| Scope selected \| Policy masks \| Audit receipt \| Owner artifact \| Protected-field redactio... | domain-native-reviewed / domain-native | Ticket must prove the primary screen is a domain-native surface, not a generic card/checklist/metadata surface. | export/import wizard with preview, redaction, checksum, transfer status, and rollback state |
| `b25-v4-row-155-export-protected-redaction-1` | Data Portability Community | `export-protected-redaction` | owner | B16_ext_export_migration_export-protected-redaction_action | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B16/screenshots/B16_ext_export_migration_export-protected-redaction_action.png` | `c978dd92bfeeb...` | Protected redaction preview \| Mask protected fields with policy reasons before export. \| Review masked phone, care, vault, and payment fields with policy reasons and reveal permissions. \| Protected-field redaction \| Protected fields \| Care notes, phone numbers, and private vau... | domain-native-reviewed / domain-native | Ticket must prove the primary screen is a domain-native surface, not a generic card/checklist/metadata surface. | export/import wizard with preview, redaction, checksum, transfer status, and rollback state |
| `b25-v4-row-156-export-protected-redaction-2` | Data Portability Community | `export-protected-redaction` | owner | B16_ext_export_migration_export-protected-redaction_complete | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B16/screenshots/B16_ext_export_migration_export-protected-redaction_complete.png` | `87a92a866735f...` | Protected redaction preview \| Mask protected fields with policy reasons before export. \| Protected redaction shows masked fields, policy reasons, before/after preview, and audit evidence. \| Scope selected \| Policy masks \| Audit receipt \| Owner artifact \| Protected-field redact... | domain-native-reviewed / domain-native | Ticket must prove the primary screen is a domain-native surface, not a generic card/checklist/metadata surface. | export/import wizard with preview, redaction, checksum, transfer status, and rollback state |

### Failing Workflow/Persona Scorecards

Showing 1 of 1 failing scorecards. Full detail is in the JSON ticket.

| Scorecard | Community | Workflow | Persona | Failed questions | Target surface |
| --- | --- | --- | --- | ---: | --- |
| `b25-wp-052-export-protected-redaction-community-export-migration-owner` | Data Portability Community | `export-protected-redaction` | owner | 2 | export/import wizard with preview, redaction, checksum, transfer status, and rollback state |

### Likely Files / Widgets
- `app/apps/loom_communities_demo/lib/main.dart`
- `app/apps/loom_communities_demo/test/b21_b25_production_ux_test.dart`
- `docs/Build Plan V2/Evidence/B25/production-ux-blueprint.md`
- `docs/Build Plan V2/Evidence/B25/independent-production-ux-review.json`
- `docs/Build Plan V2/Evidence/B25/product-ux-screen-review-matrix.md`
- `app/apps/loom_communities_demo/integration_test/workflow_ui_evidence_test.dart`
- `app/apps/loom_communities_demo/test/workflow_ui_test_harness.dart`

### Concrete Acceptance Criteria
- Every workflow/persona scorecard is present, screenshot-backed, non-boilerplate, and pass.
- `production_ux_judge.dart` has no blocking failure for this criterion.
- `b25_iteration_scorecard.dart` records the ticket as resolved or no longer blocking.
- Screenshots are refreshed and hashes/timestamps/app commit SHA match the reviewed app version.
- Screen row `b25-v4-row-154-export-protected-redaction-0` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-154-export-protected-redaction-0` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-154-export-protected-redaction-0` names visible UI elements, visible text, persona `owner`, workflow `export-protected-redaction`, and the exact product UX issue.
- Primary surface for `export-protected-redaction` is documented as `export/import wizard with preview, redaction, checksum, transfer status, and rollback state` or another explicit domain-native surface.
- After-screenshot visible text proves every required semantic surface group for `export-protected-redaction`.
- Fresh screenshot path/hash/timestamp/app commit SHA are recorded after the fix.
- The workflow/persona direct-question scorecard passes the domain-native primary surface question.
- Screen row `b25-v4-row-155-export-protected-redaction-1` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-155-export-protected-redaction-1` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-155-export-protected-redaction-1` names visible UI elements, visible text, persona `owner`, workflow `export-protected-redaction`, and the exact product UX issue.
- Screen row `b25-v4-row-156-export-protected-redaction-2` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-156-export-protected-redaction-2` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-156-export-protected-redaction-2` names visible UI elements, visible text, persona `owner`, workflow `export-protected-redaction`, and the exact product UX issue.
- Coverage row has a specific persona and personaId.
- Coverage row has entry, action/review, and result/receiver screenshots.
- Every listed screenshot path exists and has a fresh hash/timestamp/app commit SHA.
- The workflow/persona scorecard passes after rerun.

### Affected Evidence
- `independent-production-ux-review.json workflowPersonaScorecards`
- `independent-production-ux-review.json screenRows`
- `product-ux-screen-review-matrix.md every workflow/persona row`
- `production-ux-criteria-scorecard.json/.md`

### Evidence To Collect
- Fresh screenshots for every primary workflow/persona surface that was replaced or reviewed.
- `workflowPersonaScorecards` with task-specific domain-native surface judgments.
- Screen matrix rows showing `primarySurfaceType` or classification is not generic for primary workflows.

### Acceptance Checks
- Every workflow/persona scorecard is present, screenshot-backed, non-boilerplate, and pass.
- `production_ux_judge.dart` has no blocking failure for this criterion.
- `b25_iteration_scorecard.dart` records the ticket as resolved or no longer blocking.
- Screenshots are refreshed and hashes/timestamps/app commit SHA match the reviewed app version.

### Non-Goals
- Do not rename a generic workflow card and call it domain-native.
- Do not keep global workflow lists as the primary home or primary workflow UI.
- Do not use metadata/settings pages as substitutes for task-specific product surfaces.

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

## B25-RT-007-b25-c13-workflow-lifecycle-complete

| Field | Value |
| --- | --- |
| Severity | major |
| Priority | P1 |
| Status | open |
| Review run | `b25-v4-pass-24` |
| Source criterion | `b25-c13-workflow-lifecycle-complete` |
| Source findings | B25-WORKFLOW-PERSONA-UX-FAILED, B25-WORKFLOW-LIFECYCLE-INCOMPLETE, LLM-UX-primary-ux-is-still-a-repeated-workflow-card-scaffold-across-the-evidence-set, LLM-UX-visible-copy-exposes-workflow-contract-language-instead-of-product-native-task-language, LLM-UX-several-workflow-persona-lifecycles-still-lack-concrete-object-context-or-persistent-result-state, LLM-UX-persona-picker-and-role-inventory-evidence-exposes-local-test-harness-ui-as-reviewed-product-surface |
| Title | Every primary workflow has complete lifecycle UX |
| Direct question | For every workflow and persona, does the UI prove the full production interaction model: concrete object/context, decision information, semantically correct primary and alternate actions, persistent result state, and receiver/continuation state? |
| Why it failed | Workflow lifecycle scorecards are incomplete for b25-wp-013-book-search-ai-digest-community-book-club-member-lifecycle, b25-wp-030-hoa-owner-notification-community-hoa-owner-lifecycle, b25-wp-039-platform-messages-entry-community-platform-social-member-lifecycle, b25-wp-044-export-import-replay-community-export-migration-owner-lifecycle, b25-wp-048-platform-message-stream-community-platform-social-member-lifecycle, b25-wp-052-export-protected-redaction-community-export-migration-owner-lifecycle, b25-wp-059-export-import-preview-community-export-migration-owner-lifecycle. Missing lifecycle groups: concrete object/context, persistent result state. |
| Required outcome | Update product docs and UI so each affected workflow/persona has a semantic interaction contract, visible decision context, correct primary and alternate actions, result state, receiver/continuation state, fresh screenshots, and passing interaction-model scorecards. |
| Remediation mode | `product-spec-update-before-ui-remediation` |
| Worker readiness | ready for product documentation update; UI remediation is blocked until the community product experience spec is complete |
| First required step | Complete productDocRepairWorkItems so each affected community has a review-ready Product Docs V2 experience spec with domain-native surfaces and workflow-to-surface mapping. |

### Problem Statement

The evidence does not prove that each workflow/persona UI implements the full production lifecycle. Cards may expose a single accept/cancel action without the decision context, alternate choices, result state, or receiver/continuation state real users need.

### Root Cause Hypothesis

The product experience was modeled as completed workflows rather than lifecycle-complete user tasks, so the UI can appear polished while still missing required fields, negative/change actions, and durable post-action states.

### Target Experience

Each workflow/persona surface should show the concrete object, decision information, natural primary and alternate actions, persistent result/receipt/status, and receiver/continuation state expected in a production app.

### UX Principles
- Workflows are product lifecycles, not one-shot checklist actions
- Users need enough information to decide before acting
- Production affordances include alternate choices, change/revoke paths, and clear result states when the domain requires them
- Receiver and continuation states are first-class UX, not hidden backend assertions

### Concrete Improvements
- For every failed lifecycle scorecard, add the missing lifecycle groups named in the ticket.
- Update the community product doc workflow section first when the correct lifecycle is ambiguous.
- Replace accept/cancel-only cards with product surfaces that include decision data, primary action, alternate/change/reject path, persistent result, and receiver/continuation state.
- Recapture entry/action/result/receiver screenshots and rerun the lifecycle judge.

### Implementation Guidance
- Inspect workflow surface builders and identify where current UI collapses lifecycle into a single action card.
- For each failed lifecycle scorecard, implement missing object/context, decision data, primary and alternate actions, result/receipt/status, and receiver/continuation state.
- Update product docs, seed data, widget tests, and B25 evidence expectations so the lifecycle is documented and screenshot-proven.

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
| Material detail surface composition | Material Design 3 / design-system | https://m3.material.io/components/cards/overview | Build a domain detail page with primary content, metadata, status, and actions instead of a generic task card. |
| Material Design cards and lists | Material Design 3 / design-system | https://m3.material.io/components/cards/overview<br>Also: https://m3.material.io/components/lists/overview | Use cards/lists only as scannable containers with clear hierarchy, content, metadata, and actions. Do not use repeated cards as the whole primary workflow. |
| Flutter sample app implementation patterns | flutter/samples / open-source | https://github.com/flutter/samples | Copy the separation between app shell, route state, domain widgets, and testable UI states rather than hardcoding a single generic renderer. |
| Search and result list pattern | Material Design 3 / design-system | https://m3.material.io/components/search/overview<br>Also: https://m3.material.io/components/lists/overview | Copy a search layout with query, filters, ranked results, citations/sources, empty/error states, and follow-up actions. |
| Material navigation and information architecture | Material Design 3 / design-system | https://m3.material.io/components/navigation-drawer/overview<br>Also: https://m3.material.io/components/navigation-bar/overview | Organize screens by user jobs and destinations; keep primary actions visible and avoid exposing implementation taxonomy. |
| Apple HIG navigation and content organization | Apple Human Interface Guidelines / design-system | https://developer.apple.com/design/human-interface-guidelines/navigation | Make navigation predictable, content-centered, and appropriate for the user’s current task. |
| Inbox and message thread pattern | Material lists/text fields / pattern | https://m3.material.io/components/lists/overview<br>Also: https://m3.material.io/components/text-fields/overview | Copy an inbox/thread structure: sender, timestamp, message preview/body, reply field, invite/block state, and read/received state. |
| Task list and export wizard | GOV.UK Design System / design-system | https://design-system.service.gov.uk/components/task-list/<br>Also: https://design-system.service.gov.uk/patterns/check-answers/ | Copy a wizard with steps, preview, redaction choices, checksum evidence, transfer status, and rollback confirmation. |

### Reference Research Queries
- mobile app workflow lifecycle UI states primary secondary actions examples
- event RSVP decline change response mobile UI pattern
- mobile form review confirmation receipt receiver state UX examples
- open source Flutter search-results mobile UI example GitHub
- search/AI answer surface with query, result, citation, source, and follow-up action mobile UX pattern
- Material Design search/AI answer surface with query, result, citation, source, and follow-up action mobile pattern
- open source Flutter domain-native-surface mobile UI example GitHub
- notification inbox/detail surface with sender, audience, timestamp, message body, and receiver state mobile UX pattern
- Material Design notification inbox/detail surface with sender, audience, timestamp, message body, and receiver state mobile pattern
- open source Flutter message-thread mobile UI example GitHub
- inbox, message thread, connection card, invite, or block-state surface mobile UX pattern
- Material Design inbox, message thread, connection card, invite, or block-state surface mobile pattern
- open source Flutter export-wizard mobile UI example GitHub
- export/import wizard with preview, redaction, checksum, transfer status, and rollback state mobile UX pattern
- Material Design export/import wizard with preview, redaction, checksum, transfer status, and rollback state mobile pattern

### Implementation Blocked By
- The judge cannot verify production-grade UX without a community-specific product experience spec.
- UI workers need the spec to know the rich product surface they are supposed to build.

### Product Spec Repair Work Items

Showing 4 of 4 work items. Full detail is in the JSON artifact.

| Work item | Stage | Community | Workflow | Persona | Screens | Coverage | Target surface | Blocked until |
| --- | --- | --- | --- | --- | ---: | ---: | --- | --- |
| `b25-wi-product-spec-interaction-model-neighborhood-book-club` | `product-spec-update` | Neighborhood Book Club | `book-search-ai-digest` | product-experience-steward | 3 | 1 | community product experience spec with semantic interaction models | the product doc defines expected decision, required actions, result state, and receiver/continuation state for each failing workflow |
| `b25-wi-product-spec-interaction-model-cedar-commons-hoa` | `product-spec-update` | Cedar Commons HOA | `hoa-owner-notification` | product-experience-steward | 3 | 1 | community product experience spec with semantic interaction models | the product doc defines expected decision, required actions, result state, and receiver/continuation state for each failing workflow |
| `b25-wi-product-spec-interaction-model-platform-social` | `product-spec-update` | Member Social Space | `platform-messages-entry, platform-message-stream` | product-experience-steward | 6 | 2 | community product experience spec with semantic interaction models | the product doc defines expected decision, required actions, result state, and receiver/continuation state for each failing workflow |
| `b25-wi-product-spec-interaction-model-export-and-migration` | `product-spec-update` | Data Portability Community | `export-import-replay, export-protected-redaction, export-import-preview` | product-experience-steward | 9 | 3 | community product experience spec with semantic interaction models | the product doc defines expected decision, required actions, result state, and receiver/continuation state for each failing workflow |

### Evidence Repair Work Items

Showing 7 of 7 work items. Full detail is in the JSON artifact.

| Work item | Stage | Community | Workflow | Persona | Screens | Coverage | Target surface | Blocked until |
| --- | --- | --- | --- | --- | ---: | ---: | --- | --- |
| `b25-wi-evidence-repair-community-book-club-book-search-ai-digest-community-book-club-member` | `evidence-repair` | Neighborhood Book Club | `book-search-ai-digest` | member | 3 | 1 | search/AI answer surface with query, result, citation, source, and follow-up action |  |
| `b25-wi-evidence-repair-community-hoa-hoa-owner-notification-community-hoa-owner` | `evidence-repair` | Cedar Commons HOA | `hoa-owner-notification` | owner | 3 | 1 | notification inbox/detail surface with sender, audience, timestamp, message body, and receiver state |  |
| `b25-wi-evidence-repair-community-platform-social-platform-messages-entry-community-platform-social-member` | `evidence-repair` | Member Social Space | `platform-messages-entry` | member | 3 | 1 | inbox, message thread, connection card, invite, or block-state surface |  |
| `b25-wi-evidence-repair-community-export-migration-export-import-replay-community-export-migration-owner` | `evidence-repair` | Data Portability Community | `export-import-replay` | owner | 3 | 1 | export/import wizard with preview, redaction, checksum, transfer status, and rollback state |  |
| `b25-wi-evidence-repair-community-platform-social-platform-message-stream-community-platform-social-member` | `evidence-repair` | Member Social Space | `platform-message-stream` | member | 3 | 1 | inbox, message thread, connection card, invite, or block-state surface |  |
| `b25-wi-evidence-repair-community-export-migration-export-protected-redaction-community-export-migration-owner` | `evidence-repair` | Data Portability Community | `export-protected-redaction` | owner | 3 | 1 | export/import wizard with preview, redaction, checksum, transfer status, and rollback state |  |
| `b25-wi-evidence-repair-community-export-migration-export-import-preview-community-export-migration-owner` | `evidence-repair` | Data Portability Community | `export-import-preview` | owner | 3 | 1 | export/import wizard with preview, redaction, checksum, transfer status, and rollback state |  |

### Evidence Repair Work Items Reference Patterns

| Reference | Source | URL | What to copy |
| --- | --- | --- | --- |
| Search and result list pattern | Material Design 3 / design-system | https://m3.material.io/components/search/overview<br>Also: https://m3.material.io/components/lists/overview | Copy a search layout with query, filters, ranked results, citations/sources, empty/error states, and follow-up actions. |
| Material Design cards and lists | Material Design 3 / design-system | https://m3.material.io/components/cards/overview<br>Also: https://m3.material.io/components/lists/overview | Use cards/lists only as scannable containers with clear hierarchy, content, metadata, and actions. Do not use repeated cards as the whole primary workflow. |
| Flutter sample app implementation patterns | flutter/samples / open-source | https://github.com/flutter/samples | Copy the separation between app shell, route state, domain widgets, and testable UI states rather than hardcoding a single generic renderer. |
| Material navigation and information architecture | Material Design 3 / design-system | https://m3.material.io/components/navigation-drawer/overview<br>Also: https://m3.material.io/components/navigation-bar/overview | Organize screens by user jobs and destinations; keep primary actions visible and avoid exposing implementation taxonomy. |
| Apple HIG navigation and content organization | Apple Human Interface Guidelines / design-system | https://developer.apple.com/design/human-interface-guidelines/navigation | Make navigation predictable, content-centered, and appropriate for the user’s current task. |
| Material detail surface composition | Material Design 3 / design-system | https://m3.material.io/components/cards/overview | Build a domain detail page with primary content, metadata, status, and actions instead of a generic task card. |
| Inbox and message thread pattern | Material lists/text fields / pattern | https://m3.material.io/components/lists/overview<br>Also: https://m3.material.io/components/text-fields/overview | Copy an inbox/thread structure: sender, timestamp, message preview/body, reply field, invite/block state, and read/received state. |
| Task list and export wizard | GOV.UK Design System / design-system | https://design-system.service.gov.uk/components/task-list/<br>Also: https://design-system.service.gov.uk/patterns/check-answers/ | Copy a wizard with steps, preview, redaction choices, checksum evidence, transfer status, and rollback confirmation. |

### UI Remediation Work Items

Showing 7 of 7 work items. Full detail is in the JSON artifact.

| Work item | Stage | Community | Workflow | Persona | Screens | Coverage | Target surface | Blocked until |
| --- | --- | --- | --- | --- | ---: | ---: | --- | --- |
| `b25-wi-ui-remediation-community-book-club-book-search-ai-digest-community-book-club-member` | `ui-remediation` | Neighborhood Book Club | `book-search-ai-digest` | member | 3 | 1 | search/AI answer surface with query, result, citation, source, and follow-up action | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-hoa-hoa-owner-notification-community-hoa-owner` | `ui-remediation` | Cedar Commons HOA | `hoa-owner-notification` | owner | 3 | 1 | notification inbox/detail surface with sender, audience, timestamp, message body, and receiver state | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-platform-social-platform-messages-entry-community-platform-social-member` | `ui-remediation` | Member Social Space | `platform-messages-entry` | member | 3 | 1 | inbox, message thread, connection card, invite, or block-state surface | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-export-migration-export-import-replay-community-export-migration-owner` | `ui-remediation` | Data Portability Community | `export-import-replay` | owner | 3 | 1 | export/import wizard with preview, redaction, checksum, transfer status, and rollback state | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-platform-social-platform-message-stream-community-platform-social-member` | `ui-remediation` | Member Social Space | `platform-message-stream` | member | 3 | 1 | inbox, message thread, connection card, invite, or block-state surface | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-export-migration-export-protected-redaction-community-export-migration-owner` | `ui-remediation` | Data Portability Community | `export-protected-redaction` | owner | 3 | 1 | export/import wizard with preview, redaction, checksum, transfer status, and rollback state | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-export-migration-export-import-preview-community-export-migration-owner` | `ui-remediation` | Data Portability Community | `export-import-preview` | owner | 3 | 1 | export/import wizard with preview, redaction, checksum, transfer status, and rollback state | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |

### UI Remediation Work Items Reference Patterns

| Reference | Source | URL | What to copy |
| --- | --- | --- | --- |
| Search and result list pattern | Material Design 3 / design-system | https://m3.material.io/components/search/overview<br>Also: https://m3.material.io/components/lists/overview | Copy a search layout with query, filters, ranked results, citations/sources, empty/error states, and follow-up actions. |
| Material Design cards and lists | Material Design 3 / design-system | https://m3.material.io/components/cards/overview<br>Also: https://m3.material.io/components/lists/overview | Use cards/lists only as scannable containers with clear hierarchy, content, metadata, and actions. Do not use repeated cards as the whole primary workflow. |
| Flutter sample app implementation patterns | flutter/samples / open-source | https://github.com/flutter/samples | Copy the separation between app shell, route state, domain widgets, and testable UI states rather than hardcoding a single generic renderer. |
| Material navigation and information architecture | Material Design 3 / design-system | https://m3.material.io/components/navigation-drawer/overview<br>Also: https://m3.material.io/components/navigation-bar/overview | Organize screens by user jobs and destinations; keep primary actions visible and avoid exposing implementation taxonomy. |
| Apple HIG navigation and content organization | Apple Human Interface Guidelines / design-system | https://developer.apple.com/design/human-interface-guidelines/navigation | Make navigation predictable, content-centered, and appropriate for the user’s current task. |
| Material detail surface composition | Material Design 3 / design-system | https://m3.material.io/components/cards/overview | Build a domain detail page with primary content, metadata, status, and actions instead of a generic task card. |
| Inbox and message thread pattern | Material lists/text fields / pattern | https://m3.material.io/components/lists/overview<br>Also: https://m3.material.io/components/text-fields/overview | Copy an inbox/thread structure: sender, timestamp, message preview/body, reply field, invite/block state, and read/received state. |
| Task list and export wizard | GOV.UK Design System / design-system | https://design-system.service.gov.uk/components/task-list/<br>Also: https://design-system.service.gov.uk/patterns/check-answers/ | Copy a wizard with steps, preview, redaction choices, checksum evidence, transfer status, and rollback confirmation. |

### Affected Workflow/Persona Coverage

Showing 7 of 7 affected coverage rows. Full detail is in the JSON ticket.

| Coverage row | Status | Community | Workflow | Persona | Missing evidence | Screen rows | Target surface |
| --- | --- | --- | --- | --- | --- | ---: | --- |
| `b25-wp-013-book-search-ai-digest-community-book-club-member` | `pass` | Neighborhood Book Club | `book-search-ai-digest` | member |  | 3 | search/AI answer surface with query, result, citation, source, and follow-up action |
| `b25-wp-030-hoa-owner-notification-community-hoa-owner` | `pass` | Cedar Commons HOA | `hoa-owner-notification` | owner |  | 3 | notification inbox/detail surface with sender, audience, timestamp, message body, and receiver state |
| `b25-wp-039-platform-messages-entry-community-platform-social-member` | `pass` | Member Social Space | `platform-messages-entry` | member |  | 3 | inbox, message thread, connection card, invite, or block-state surface |
| `b25-wp-044-export-import-replay-community-export-migration-owner` | `pass` | Data Portability Community | `export-import-replay` | owner |  | 3 | export/import wizard with preview, redaction, checksum, transfer status, and rollback state |
| `b25-wp-048-platform-message-stream-community-platform-social-member` | `pass` | Member Social Space | `platform-message-stream` | member |  | 3 | inbox, message thread, connection card, invite, or block-state surface |
| `b25-wp-052-export-protected-redaction-community-export-migration-owner` | `pass` | Data Portability Community | `export-protected-redaction` | owner |  | 3 | export/import wizard with preview, redaction, checksum, transfer status, and rollback state |
| `b25-wp-059-export-import-preview-community-export-migration-owner` | `pass` | Data Portability Community | `export-import-preview` | owner |  | 3 | export/import wizard with preview, redaction, checksum, transfer status, and rollback state |

### Affected Screen Rows

Showing 21 of 21 affected screen rows. Full detail is in the JSON ticket.

| Screen row | Community | Workflow | Persona | State | Screenshot | Hash | Visible text | Current surface | Exact UX failure | Target surface |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `b25-v4-row-037-book-search-ai-digest-0` | Neighborhood Book Club | `book-search-ai-digest` | member | B14_ext_book_club_book-search-ai-digest_start | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_book_club_book-search-ai-digest_start.png` | `084b20dbc594a...` | Reading guide answer \| Query: "What should we discuss before chapter 6?" \| Review the AI answer, quoted source snippets, citation list, and follow-up prompts before saving it to the club digest. \| Question asked \| AI summary \| 3 citations \| Save digest \| AI answer with citatio... | domain-native-reviewed / domain-native | No row-specific failure recorded. | search/AI answer surface with query, result, citation, source, and follow-up action |
| `b25-v4-row-038-book-search-ai-digest-1` | Neighborhood Book Club | `book-search-ai-digest` | member | B14_ext_book_club_book-search-ai-digest_action | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_book_club_book-search-ai-digest_action.png` | `ee8f007e32b4e...` | Reading guide answer \| Parable of the Sower reading guide with cited sources \| Check the query, answer summary, citation snippets, source titles, and follow-up action before saving the digest. \| AI answer with citations \| Query \| What should we discuss before chapter 6? \| Answ... | domain-native-reviewed / domain-native | No row-specific failure recorded. | search/AI answer surface with query, result, citation, source, and follow-up action |
| `b25-v4-row-039-book-search-ai-digest-2` | Neighborhood Book Club | `book-search-ai-digest` | member | B14_ext_book_club_book-search-ai-digest_complete | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_book_club_book-search-ai-digest_complete.png` | `a2a76009ad38d...` | Reading guide answer \| Query: "What should we discuss before chapter 6?" \| The reading guide now shows query, answer, citations, source visibility, save state, and follow-up prompts. \| Question asked \| AI summary \| 3 citations \| Save digest \| AI answer with citations \| Query \|... | domain-native-reviewed / domain-native | No row-specific failure recorded. | search/AI answer surface with query, result, citation, source, and follow-up action |
| `b25-v4-row-088-hoa-owner-notification-0` | Cedar Commons HOA | `hoa-owner-notification` | owner | B14_ext_hoa_hoa-owner-notification_start | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_hoa_hoa-owner-notification_start.png` | `76e3f623980ab...` | Owner decision notice \| Lot 42 fence request - approved with conditions. \| Send the owner notice with board sender, decision summary, required paint condition, delivery time, and owner inbox state. \| Lot 42 \| From HOA Board \| Today 4:15 PM \| Owner inbox \| Decide what to save, ... | domain-native-reviewed / domain-native | No row-specific failure recorded. | notification inbox/detail surface with sender, audience, timestamp, message body, and receiver state |
| `b25-v4-row-089-hoa-owner-notification-1` | Cedar Commons HOA | `hoa-owner-notification` | owner | B14_ext_hoa_hoa-owner-notification_action | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_hoa_hoa-owner-notification_action.png` | `fb1f41cd434a6...` | Owner decision notice \| Avery Brooks - architectural decision \| Review sender, recipient, decision body, condition, timestamp, and owner receiver state before sending. \| Decide what to save, what to change, and what status or next step should remain visible afterward. \| Edit r... | domain-native-reviewed / domain-native | No row-specific failure recorded. | notification inbox/detail surface with sender, audience, timestamp, message body, and receiver state |
| `b25-v4-row-090-hoa-owner-notification-2` | Cedar Commons HOA | `hoa-owner-notification` | owner | B14_ext_hoa_hoa-owner-notification_complete | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_hoa_hoa-owner-notification_complete.png` | `8c91c548ee250...` | Owner decision notice \| Lot 42 fence request - approved with conditions. \| Owner notice shows sender, recipient, body, timestamp, decision condition, inbox receipt, and follow-up path. \| Lot 42 \| From HOA Board \| Today 4:15 PM \| Owner inbox \| Decide what to save, what to chang... | domain-native-reviewed / domain-native | No row-specific failure recorded. | notification inbox/detail surface with sender, audience, timestamp, message body, and receiver state |
| `b25-v4-row-115-platform-messages-entry-0` | Member Social Space | `platform-messages-entry` | member | B16_ext_platform_social_platform-messages-entry_start | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B16/screenshots/B16_ext_platform_social_platform-messages-entry_start.png` | `8dc4aeef3213b...` | Community message thread \| Maya Chen to Jordan Lee - unread member thread. \| Read sender, recipient, timestamp, message preview, unread state, reply path, mute, and archive controls. \| Maya -> Jordan \| Unread \| Reply available \| Archive path \| Member conversation \| Maya Chen -... | domain-native-reviewed / domain-native | No row-specific failure recorded. | inbox, message thread, connection card, invite, or block-state surface |
| `b25-v4-row-116-platform-messages-entry-1` | Member Social Space | `platform-messages-entry` | member | B16_ext_platform_social_platform-messages-entry_action | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B16/screenshots/B16_ext_platform_social_platform-messages-entry_action.png` | `99ccbc020cc33...` | Community message thread \| Community message from Maya \| Open the thread, review sender and body, reply, mute, archive, or block if needed. \| Member conversation \| Maya Chen -> Jordan Lee \| Visible sender, recipient, Today 9:12 AM timestamp, and community relationship. \| Messa... | domain-native-reviewed / domain-native | No row-specific failure recorded. | inbox, message thread, connection card, invite, or block-state surface |
| `b25-v4-row-117-platform-messages-entry-2` | Member Social Space | `platform-messages-entry` | member | B16_ext_platform_social_platform-messages-entry_complete | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B16/screenshots/B16_ext_platform_social_platform-messages-entry_complete.png` | `87ae065ef3a38...` | Community message thread \| Maya Chen to Jordan Lee - unread member thread. \| The thread shows sender, body, timestamp, reply path, read state, and archive/block controls. \| Maya -> Jordan \| Unread \| Reply available \| Archive path \| Member conversation \| Maya Chen -> Jordan Lee... | domain-native-reviewed / domain-native | No row-specific failure recorded. | inbox, message thread, connection card, invite, or block-state surface |
| `b25-v4-row-130-export-import-replay-0` | Data Portability Community | `export-import-replay` | owner | B16_ext_export_migration_export-import-replay_start | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B16/screenshots/B16_ext_export_migration_export-import-replay_start.png` | `1f031f14addb2...` | Legacy import preview \| Preview rows, conflicts, replay checkpoint, and rollback marker. \| Inspect imported member, document, and receipt rows; resolve duplicates; and confirm replay checkpoint before importing. \| Scope selected \| 3 conflicts \| Audit receipt \| Owner artifact \|... | domain-native-reviewed / domain-native | No row-specific failure recorded. | export/import wizard with preview, redaction, checksum, transfer status, and rollback state |
| `b25-v4-row-131-export-import-replay-1` | Data Portability Community | `export-import-replay` | owner | B16_ext_export_migration_export-import-replay_action | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B16/screenshots/B16_ext_export_migration_export-import-replay_action.png` | `cfb3479724b6e...` | Legacy import preview \| Preview rows, conflicts, replay checkpoint, and rollback marker. \| Inspect imported member, document, and receipt rows; resolve duplicates; and confirm replay checkpoint before importing. \| Import rows \| Preview 48 member rows, 22 documents, and 12 rece... | domain-native-reviewed / domain-native | No row-specific failure recorded. | export/import wizard with preview, redaction, checksum, transfer status, and rollback state |
| `b25-v4-row-132-export-import-replay-2` | Data Portability Community | `export-import-replay` | owner | B16_ext_export_migration_export-import-replay_complete | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B16/screenshots/B16_ext_export_migration_export-import-replay_complete.png` | `09d3f1fdb9c14...` | Legacy import preview \| Preview rows, conflicts, replay checkpoint, and rollback marker. \| Import preview shows row counts, duplicate decisions, checkpoint, retry, and rollback state. \| Scope selected \| 3 conflicts \| Audit receipt \| Owner artifact \| Import rows \| Preview 48 me... | domain-native-reviewed / domain-native | No row-specific failure recorded. | export/import wizard with preview, redaction, checksum, transfer status, and rollback state |
| `b25-v4-row-142-platform-message-stream-0` | Member Social Space | `platform-message-stream` | member | B16_ext_platform_social_platform-message-stream_start | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B16/screenshots/B16_ext_platform_social_platform-message-stream_start.png` | `8dc4aeef3213b...` | Community message thread \| Maya Chen to Jordan Lee - unread member thread. \| Read sender, recipient, timestamp, message preview, unread state, reply path, mute, and archive controls. \| Maya -> Jordan \| Unread \| Reply available \| Archive path \| Member conversation \| Maya Chen -... | domain-native-reviewed / domain-native | No row-specific failure recorded. | inbox, message thread, connection card, invite, or block-state surface |
| `b25-v4-row-143-platform-message-stream-1` | Member Social Space | `platform-message-stream` | member | B16_ext_platform_social_platform-message-stream_action | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B16/screenshots/B16_ext_platform_social_platform-message-stream_action.png` | `99ccbc020cc33...` | Community message thread \| Community message from Maya \| Open the thread, review sender and body, reply, mute, archive, or block if needed. \| Member conversation \| Maya Chen -> Jordan Lee \| Visible sender, recipient, Today 9:12 AM timestamp, and community relationship. \| Messa... | domain-native-reviewed / domain-native | No row-specific failure recorded. | inbox, message thread, connection card, invite, or block-state surface |
| `b25-v4-row-144-platform-message-stream-2` | Member Social Space | `platform-message-stream` | member | B16_ext_platform_social_platform-message-stream_complete | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B16/screenshots/B16_ext_platform_social_platform-message-stream_complete.png` | `87ae065ef3a38...` | Community message thread \| Maya Chen to Jordan Lee - unread member thread. \| The thread shows sender, body, timestamp, reply path, read state, and archive/block controls. \| Maya -> Jordan \| Unread \| Reply available \| Archive path \| Member conversation \| Maya Chen -> Jordan Lee... | domain-native-reviewed / domain-native | No row-specific failure recorded. | inbox, message thread, connection card, invite, or block-state surface |
| `b25-v4-row-154-export-protected-redaction-0` | Data Portability Community | `export-protected-redaction` | owner | B16_ext_export_migration_export-protected-redaction_start | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B16/screenshots/B16_ext_export_migration_export-protected-redaction_start.png` | `c0fc01a627f15...` | Protected redaction preview \| Mask protected fields with policy reasons before export. \| Review masked phone, care, vault, and payment fields with policy reasons and reveal permissions. \| Scope selected \| Policy masks \| Audit receipt \| Owner artifact \| Protected-field redactio... | domain-native-reviewed / domain-native | No row-specific failure recorded. | export/import wizard with preview, redaction, checksum, transfer status, and rollback state |
| `b25-v4-row-155-export-protected-redaction-1` | Data Portability Community | `export-protected-redaction` | owner | B16_ext_export_migration_export-protected-redaction_action | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B16/screenshots/B16_ext_export_migration_export-protected-redaction_action.png` | `c978dd92bfeeb...` | Protected redaction preview \| Mask protected fields with policy reasons before export. \| Review masked phone, care, vault, and payment fields with policy reasons and reveal permissions. \| Protected-field redaction \| Protected fields \| Care notes, phone numbers, and private vau... | domain-native-reviewed / domain-native | No row-specific failure recorded. | export/import wizard with preview, redaction, checksum, transfer status, and rollback state |
| `b25-v4-row-156-export-protected-redaction-2` | Data Portability Community | `export-protected-redaction` | owner | B16_ext_export_migration_export-protected-redaction_complete | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B16/screenshots/B16_ext_export_migration_export-protected-redaction_complete.png` | `87a92a866735f...` | Protected redaction preview \| Mask protected fields with policy reasons before export. \| Protected redaction shows masked fields, policy reasons, before/after preview, and audit evidence. \| Scope selected \| Policy masks \| Audit receipt \| Owner artifact \| Protected-field redact... | domain-native-reviewed / domain-native | No row-specific failure recorded. | export/import wizard with preview, redaction, checksum, transfer status, and rollback state |
| `b25-v4-row-175-export-import-preview-0` | Data Portability Community | `export-import-preview` | owner | B16_ext_export_migration_export-import-preview_start | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B16/screenshots/B16_ext_export_migration_export-import-preview_start.png` | `1f031f14addb2...` | Legacy import preview \| Preview rows, conflicts, replay checkpoint, and rollback marker. \| Inspect imported member, document, and receipt rows; resolve duplicates; and confirm replay checkpoint before importing. \| Scope selected \| 3 conflicts \| Audit receipt \| Owner artifact \|... | domain-native-reviewed / domain-native | No row-specific failure recorded. | export/import wizard with preview, redaction, checksum, transfer status, and rollback state |
| `b25-v4-row-176-export-import-preview-1` | Data Portability Community | `export-import-preview` | owner | B16_ext_export_migration_export-import-preview_action | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B16/screenshots/B16_ext_export_migration_export-import-preview_action.png` | `cfb3479724b6e...` | Legacy import preview \| Preview rows, conflicts, replay checkpoint, and rollback marker. \| Inspect imported member, document, and receipt rows; resolve duplicates; and confirm replay checkpoint before importing. \| Import rows \| Preview 48 member rows, 22 documents, and 12 rece... | domain-native-reviewed / domain-native | No row-specific failure recorded. | export/import wizard with preview, redaction, checksum, transfer status, and rollback state |
| `b25-v4-row-177-export-import-preview-2` | Data Portability Community | `export-import-preview` | owner | B16_ext_export_migration_export-import-preview_complete | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B16/screenshots/B16_ext_export_migration_export-import-preview_complete.png` | `09d3f1fdb9c14...` | Legacy import preview \| Preview rows, conflicts, replay checkpoint, and rollback marker. \| Import preview shows row counts, duplicate decisions, checkpoint, retry, and rollback state. \| Scope selected \| 3 conflicts \| Audit receipt \| Owner artifact \| Import rows \| Preview 48 me... | domain-native-reviewed / domain-native | No row-specific failure recorded. | export/import wizard with preview, redaction, checksum, transfer status, and rollback state |

### Failing Workflow/Persona Scorecards

Showing 1 of 1 failing scorecards. Full detail is in the JSON ticket.

| Scorecard | Community | Workflow | Persona | Failed questions | Target surface |
| --- | --- | --- | --- | ---: | --- |
| `b25-wp-052-export-protected-redaction-community-export-migration-owner` | Data Portability Community | `export-protected-redaction` | owner | 2 | export/import wizard with preview, redaction, checksum, transfer status, and rollback state |

### Failing Workflow Lifecycle / Interaction Model Scorecards

Showing 7 of 7 failing lifecycle scorecards. Full semantic interaction-model detail is in the JSON ticket.

| Scorecard | Community | Workflow | Persona | Expected decision | Missing lifecycle groups | Missing actions | Wrong generic substitutes | Target surface |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `b25-wp-013-book-search-ai-digest-community-book-club-member-lifecycle` | Neighborhood Book Club | `book-search-ai-digest` | member | User decides a concrete community task with enough context, a semantic primary action, a meaningful alternative, and a durable result. | concrete object/context |  |  | search/AI answer surface with query, result, citation, source, and follow-up action |
| `b25-wp-030-hoa-owner-notification-community-hoa-owner-lifecycle` | Cedar Commons HOA | `hoa-owner-notification` | owner | User decides a concrete community task with enough context, a semantic primary action, a meaningful alternative, and a durable result. | concrete object/context |  |  | notification inbox/detail surface with sender, audience, timestamp, message body, and receiver state |
| `b25-wp-039-platform-messages-entry-community-platform-social-member-lifecycle` | Member Social Space | `platform-messages-entry` | member | Member evaluates a concrete message, connection, or invite with sender/recipient context and accept/decline/block paths. | persistent result state |  |  | inbox, message thread, connection card, invite, or block-state surface |
| `b25-wp-044-export-import-replay-community-export-migration-owner-lifecycle` | Data Portability Community | `export-import-replay` | owner | Admin selects export/import/transfer scope, reviews redaction/checksum/status, and can cancel, retry, or roll back. | persistent result state |  |  | export/import wizard with preview, redaction, checksum, transfer status, and rollback state |
| `b25-wp-048-platform-message-stream-community-platform-social-member-lifecycle` | Member Social Space | `platform-message-stream` | member | Member evaluates a concrete message, connection, or invite with sender/recipient context and accept/decline/block paths. | persistent result state |  |  | inbox, message thread, connection card, invite, or block-state surface |
| `b25-wp-052-export-protected-redaction-community-export-migration-owner-lifecycle` | Data Portability Community | `export-protected-redaction` | owner | Admin selects export/import/transfer scope, reviews redaction/checksum/status, and can cancel, retry, or roll back. | persistent result state |  |  | export/import wizard with preview, redaction, checksum, transfer status, and rollback state |
| `b25-wp-059-export-import-preview-community-export-migration-owner-lifecycle` | Data Portability Community | `export-import-preview` | owner | Admin selects export/import/transfer scope, reviews redaction/checksum/status, and can cancel, retry, or roll back. | persistent result state |  |  | export/import wizard with preview, redaction, checksum, transfer status, and rollback state |

### Likely Files / Widgets
- `app/apps/loom_communities_demo/lib/main.dart`
- `app/apps/loom_communities_demo/test/b21_b25_production_ux_test.dart`
- `docs/Build Plan V2/Evidence/B25/production-ux-blueprint.md`
- `docs/Build Plan V2/Evidence/B25/independent-production-ux-review.json`
- `docs/Build Plan V2/Evidence/B25/product-ux-screen-review-matrix.md`
- `app/apps/loom_communities_demo/integration_test/workflow_ui_evidence_test.dart`
- `app/apps/loom_communities_demo/test/workflow_ui_test_harness.dart`

### Concrete Acceptance Criteria
- Every workflow/persona scorecard is present, screenshot-backed, non-boilerplate, and pass.
- Every workflow lifecycle scorecard is present, screenshot-backed, and pass with no missing lifecycle groups.
- `production_ux_judge.dart` has no blocking failure for this criterion.
- `b25_iteration_scorecard.dart` records the ticket as resolved or no longer blocking.
- Screenshots are refreshed and hashes/timestamps/app commit SHA match the reviewed app version.
- Screen row `b25-v4-row-037-book-search-ai-digest-0` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-037-book-search-ai-digest-0` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-037-book-search-ai-digest-0` names visible UI elements, visible text, persona `member`, workflow `book-search-ai-digest`, and the exact product UX issue.
- Primary surface for `book-search-ai-digest` is documented as `search/AI answer surface with query, result, citation, source, and follow-up action` or another explicit domain-native surface.
- After-screenshot visible text proves every required semantic surface group for `book-search-ai-digest`.
- Fresh screenshot path/hash/timestamp/app commit SHA are recorded after the fix.
- The workflow lifecycle scorecard passes with no missing object/context, decision information, action affordance, result state, or receiver/continuation groups.
- Screen row `b25-v4-row-038-book-search-ai-digest-1` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-038-book-search-ai-digest-1` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-038-book-search-ai-digest-1` names visible UI elements, visible text, persona `member`, workflow `book-search-ai-digest`, and the exact product UX issue.
- Screen row `b25-v4-row-039-book-search-ai-digest-2` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-039-book-search-ai-digest-2` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-039-book-search-ai-digest-2` names visible UI elements, visible text, persona `member`, workflow `book-search-ai-digest`, and the exact product UX issue.
- Screen row `b25-v4-row-088-hoa-owner-notification-0` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-088-hoa-owner-notification-0` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-088-hoa-owner-notification-0` names visible UI elements, visible text, persona `owner`, workflow `hoa-owner-notification`, and the exact product UX issue.
- Primary surface for `hoa-owner-notification` is documented as `notification inbox/detail surface with sender, audience, timestamp, message body, and receiver state` or another explicit domain-native surface.
- After-screenshot visible text proves every required semantic surface group for `hoa-owner-notification`.
- Screen row `b25-v4-row-089-hoa-owner-notification-1` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-089-hoa-owner-notification-1` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-089-hoa-owner-notification-1` names visible UI elements, visible text, persona `owner`, workflow `hoa-owner-notification`, and the exact product UX issue.
- Screen row `b25-v4-row-090-hoa-owner-notification-2` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-090-hoa-owner-notification-2` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-090-hoa-owner-notification-2` names visible UI elements, visible text, persona `owner`, workflow `hoa-owner-notification`, and the exact product UX issue.
- Screen row `b25-v4-row-115-platform-messages-entry-0` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-115-platform-messages-entry-0` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-115-platform-messages-entry-0` names visible UI elements, visible text, persona `member`, workflow `platform-messages-entry`, and the exact product UX issue.
- Primary surface for `platform-messages-entry` is documented as `inbox, message thread, connection card, invite, or block-state surface` or another explicit domain-native surface.
- After-screenshot visible text proves every required semantic surface group for `platform-messages-entry`.
- Screen row `b25-v4-row-116-platform-messages-entry-1` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-116-platform-messages-entry-1` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-116-platform-messages-entry-1` names visible UI elements, visible text, persona `member`, workflow `platform-messages-entry`, and the exact product UX issue.
- Screen row `b25-v4-row-117-platform-messages-entry-2` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-117-platform-messages-entry-2` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-117-platform-messages-entry-2` names visible UI elements, visible text, persona `member`, workflow `platform-messages-entry`, and the exact product UX issue.
- Screen row `b25-v4-row-130-export-import-replay-0` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-130-export-import-replay-0` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-130-export-import-replay-0` names visible UI elements, visible text, persona `owner`, workflow `export-import-replay`, and the exact product UX issue.
- Primary surface for `export-import-replay` is documented as `export/import wizard with preview, redaction, checksum, transfer status, and rollback state` or another explicit domain-native surface.
- After-screenshot visible text proves every required semantic surface group for `export-import-replay`.
- Screen row `b25-v4-row-131-export-import-replay-1` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-131-export-import-replay-1` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-131-export-import-replay-1` names visible UI elements, visible text, persona `owner`, workflow `export-import-replay`, and the exact product UX issue.
- Screen row `b25-v4-row-132-export-import-replay-2` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-132-export-import-replay-2` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-132-export-import-replay-2` names visible UI elements, visible text, persona `owner`, workflow `export-import-replay`, and the exact product UX issue.
- Coverage row has a specific persona and personaId.
- Coverage row has entry, action/review, and result/receiver screenshots.
- Every listed screenshot path exists and has a fresh hash/timestamp/app commit SHA.
- The workflow/persona scorecard passes after rerun.
- All lifecycle direct questions in this workflow/persona scorecard pass.
- The UI visibly proves the concrete object/context, decision information, primary action, alternate/change/reject affordance, persistent result state, and receiver/continuation state.
- The semantic interaction model passes: expected decision, required primary actions, and required alternate/change/reject actions are visible in fresh after screenshots.
- Missing lifecycle groups are resolved: concrete object/context.
- Fresh after screenshots prove the lifecycle and interaction model; implementation notes, code diffs, or ticket responses alone cannot close this ticket.
- The `book-search-ai-digest` screenshots show the concrete domain object/context for `member`.
- The user can see enough domain-specific decision information before acting.
- The UI provides semantic primary action and the needed alternate/change/reject/defer path; `Cancel` alone cannot stand in for a real decline/reject/change response.
- The semantic interaction model names the correct user decision and the right domain actions for `book-search-ai-digest`; generic accept/cancel or submit/cancel actions do not satisfy this criterion.
- The post-action screen shows a persistent result/receipt/status state that can be understood later.
- The receiver/read-only/continuation state is visible where another persona or later state is part of the workflow.
- The workflow lifecycle scorecard passes with no missing lifecycle groups.
- Screen row `b25-wp-013-book-search-ai-digest-community-book-club-member` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-wp-013-book-search-ai-digest-community-book-club-member` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-wp-013-book-search-ai-digest-community-book-club-member` names visible UI elements, visible text, persona `member`, workflow `book-search-ai-digest`, and the exact product UX issue.
- The `hoa-owner-notification` screenshots show the concrete domain object/context for `owner`.
- The semantic interaction model names the correct user decision and the right domain actions for `hoa-owner-notification`; generic accept/cancel or submit/cancel actions do not satisfy this criterion.
- Screen row `b25-wp-030-hoa-owner-notification-community-hoa-owner` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-wp-030-hoa-owner-notification-community-hoa-owner` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-wp-030-hoa-owner-notification-community-hoa-owner` names visible UI elements, visible text, persona `owner`, workflow `hoa-owner-notification`, and the exact product UX issue.
- Missing lifecycle groups are resolved: persistent result state.
- The `platform-messages-entry` screenshots show the concrete domain object/context for `member`.
- The semantic interaction model names the correct user decision and the right domain actions for `platform-messages-entry`; generic accept/cancel or submit/cancel actions do not satisfy this criterion.
- Screen row `b25-wp-039-platform-messages-entry-community-platform-social-member` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-wp-039-platform-messages-entry-community-platform-social-member` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-wp-039-platform-messages-entry-community-platform-social-member` names visible UI elements, visible text, persona `member`, workflow `platform-messages-entry`, and the exact product UX issue.
- The `export-import-replay` screenshots show the concrete domain object/context for `owner`.
- The semantic interaction model names the correct user decision and the right domain actions for `export-import-replay`; generic accept/cancel or submit/cancel actions do not satisfy this criterion.
- Screen row `b25-wp-044-export-import-replay-community-export-migration-owner` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-wp-044-export-import-replay-community-export-migration-owner` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-wp-044-export-import-replay-community-export-migration-owner` names visible UI elements, visible text, persona `owner`, workflow `export-import-replay`, and the exact product UX issue.
- The `platform-message-stream` screenshots show the concrete domain object/context for `member`.
- The semantic interaction model names the correct user decision and the right domain actions for `platform-message-stream`; generic accept/cancel or submit/cancel actions do not satisfy this criterion.
- Screen row `b25-wp-048-platform-message-stream-community-platform-social-member` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-wp-048-platform-message-stream-community-platform-social-member` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-wp-048-platform-message-stream-community-platform-social-member` names visible UI elements, visible text, persona `member`, workflow `platform-message-stream`, and the exact product UX issue.
- Primary surface for `platform-message-stream` is documented as `inbox, message thread, connection card, invite, or block-state surface` or another explicit domain-native surface.
- After-screenshot visible text proves every required semantic surface group for `platform-message-stream`.
- The `export-protected-redaction` screenshots show the concrete domain object/context for `owner`.
- The semantic interaction model names the correct user decision and the right domain actions for `export-protected-redaction`; generic accept/cancel or submit/cancel actions do not satisfy this criterion.
- Screen row `b25-wp-052-export-protected-redaction-community-export-migration-owner` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-wp-052-export-protected-redaction-community-export-migration-owner` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-wp-052-export-protected-redaction-community-export-migration-owner` names visible UI elements, visible text, persona `owner`, workflow `export-protected-redaction`, and the exact product UX issue.
- Primary surface for `export-protected-redaction` is documented as `export/import wizard with preview, redaction, checksum, transfer status, and rollback state` or another explicit domain-native surface.
- After-screenshot visible text proves every required semantic surface group for `export-protected-redaction`.
- The `export-import-preview` screenshots show the concrete domain object/context for `owner`.
- The semantic interaction model names the correct user decision and the right domain actions for `export-import-preview`; generic accept/cancel or submit/cancel actions do not satisfy this criterion.
- Screen row `b25-wp-059-export-import-preview-community-export-migration-owner` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-wp-059-export-import-preview-community-export-migration-owner` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-wp-059-export-import-preview-community-export-migration-owner` names visible UI elements, visible text, persona `owner`, workflow `export-import-preview`, and the exact product UX issue.
- Primary surface for `export-import-preview` is documented as `export/import wizard with preview, redaction, checksum, transfer status, and rollback state` or another explicit domain-native surface.
- After-screenshot visible text proves every required semantic surface group for `export-import-preview`.

### Affected Evidence
- `independent-production-ux-review.json workflowLifecycleScorecards`
- `independent-production-ux-review.json screenRows`
- `b25-workflow-lifecycle-scorecards.md`
- `production-ux-criteria-scorecard.json/.md`

### Evidence To Collect
- Fresh entry/action/result/receiver screenshots for every remediated workflow/persona lifecycle.
- `workflowLifecycleScorecards` showing every required lifecycle group passes.
- Visible text excerpts proving object/context, decision information, primary action, alternate/change/reject affordance, persistent result state, and receiver/continuation state.

### Acceptance Checks
- Every workflow/persona scorecard is present, screenshot-backed, non-boilerplate, and pass.
- Every workflow lifecycle scorecard is present, screenshot-backed, and pass with no missing lifecycle groups.
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

## B25-RT-008-b25-c08-visible-text-specific-critique

| Field | Value |
| --- | --- |
| Severity | major |
| Priority | P1 |
| Status | open |
| Review run | `b25-v4-pass-24` |
| Source criterion | `b25-c08-visible-text-specific-critique` |
| Source findings | B25-WORKFLOW-PERSONA-UX-FAILED, B25-WORKFLOW-LIFECYCLE-INCOMPLETE, LLM-UX-primary-ux-is-still-a-repeated-workflow-card-scaffold-across-the-evidence-set, LLM-UX-visible-copy-exposes-workflow-contract-language-instead-of-product-native-task-language, LLM-UX-several-workflow-persona-lifecycles-still-lack-concrete-object-context-or-persistent-result-state, LLM-UX-persona-picker-and-role-inventory-evidence-exposes-local-test-harness-ui-as-reviewed-product-surface |
| Title | Every row has visible text and screen-specific critique |
| Direct question | Does every holistic and workflow/persona review answer cite visible UI/text and provide a critique specific to that screenshot and user task? |
| Why it failed | Workflow/persona direct-question scorecards have missing or blocking answers: export-protected-redaction/owner. |
| Required outcome | Extract visible text and write a specific critique for each screenshot row. |
| Remediation mode | `evidence-repair-first` |
| Worker readiness | not ready for UI implementation until evidence repair work items are completed and the independent judge reruns |
| First required step | Complete the evidenceRepairWorkItems: concrete persona/personaId, screenshot-derived visible text, screen-specific critique, coverage row proof, and workflow/persona scorecards. |

### Problem Statement

The review rows and direct-question answers do not include enough visible text and screen-specific critique to guide implementation.

### Root Cause Hypothesis

The judge output is not detailed enough; rows may be boilerplate or missing actual visible UI/text references.

### Target Experience

Every row should tell a worker exactly what was visible, why it did or did not work for the persona/task, and what must change.

### UX Principles
- Evidence must cite visible UI and text
- Critique must be screen-specific and non-boilerplate

### Concrete Improvements
- Extract visible text for every reviewed screenshot row.
- Write a non-boilerplate critique for every row that names visible UI elements, visible text, the persona, and the user task.
- Remove duplicated or reusable critiques; each critique must be specific enough that it cannot apply unchanged to an unrelated screen.

### Implementation Guidance
- Update the B25 judge/review artifact, not only app UI code.
- Fill `screenRows[].visibleTextExtract`, `screenRows[].screenSpecificCritique`, `holisticQuestionAnswers`, and `workflowPersonaScorecards` with screenshot-specific content.
- Regenerate markdown review and matrix files from the updated schema v4 JSON.

### Content Guidance
- Quote or summarize visible labels, headings, section names, action text, and result copy in the critique.
- Explain why that visible content does or does not support the persona and task.

### Visual Guidance
- Use screenshot evidence to judge visual hierarchy, density, navigation clarity, and polish on the reviewed device.

### Source Research Requirement

The independent UX review must attach internet or open-source pattern references before UI remediation. If live research is unavailable, use the bundled catalog entries and keep the research queries in the ticket so a reviewer can refresh them.

### UX Reference Patterns To Copy

| Reference | Source | URL | What to copy |
| --- | --- | --- | --- |
| Screenshot-first critique method | B25 production UX gate / methodology | docs/Build Plan V2/Tools/b25-remediation-ticket-template.md | Critique must quote visible UI/text, name the persona and task, compare against the chosen reference pattern, and state the exact fix. |
| Material Design cards and lists | Material Design 3 / design-system | https://m3.material.io/components/cards/overview<br>Also: https://m3.material.io/components/lists/overview | Use cards/lists only as scannable containers with clear hierarchy, content, metadata, and actions. Do not use repeated cards as the whole primary workflow. |
| Flutter sample app implementation patterns | flutter/samples / open-source | https://github.com/flutter/samples | Copy the separation between app shell, route state, domain widgets, and testable UI states rather than hardcoding a single generic renderer. |
| Task list and export wizard | GOV.UK Design System / design-system | https://design-system.service.gov.uk/components/task-list/<br>Also: https://design-system.service.gov.uk/patterns/check-answers/ | Copy a wizard with steps, preview, redaction choices, checksum evidence, transfer status, and rollback confirmation. |
| Material navigation and information architecture | Material Design 3 / design-system | https://m3.material.io/components/navigation-drawer/overview<br>Also: https://m3.material.io/components/navigation-bar/overview | Organize screens by user jobs and destinations; keep primary actions visible and avoid exposing implementation taxonomy. |
| Apple HIG navigation and content organization | Apple Human Interface Guidelines / design-system | https://developer.apple.com/design/human-interface-guidelines/navigation | Make navigation predictable, content-centered, and appropriate for the user’s current task. |

### Reference Research Queries
- production mobile UX review screenshot critique examples
- open source Flutter mobile app UX patterns GitHub
- open source Flutter export-wizard mobile UI example GitHub
- export/import wizard with preview, redaction, checksum, transfer status, and rollback state mobile UX pattern
- Material Design export/import wizard with preview, redaction, checksum, transfer status, and rollback state mobile pattern

### Implementation Blocked By
- Affected rows still use generic or missing persona data.
- Visible text is not proven from screenshot OCR/manual extraction.
- Screen-specific critiques are incomplete or reusable.
- Primary surface classification is incomplete or unverified.

### Evidence Repair Work Items

Showing 1 of 1 work items. Full detail is in the JSON artifact.

| Work item | Stage | Community | Workflow | Persona | Screens | Coverage | Target surface | Blocked until |
| --- | --- | --- | --- | --- | ---: | ---: | --- | --- |
| `b25-wi-evidence-repair-community-export-migration-export-protected-redaction-community-export-migration-owner` | `evidence-repair` | Data Portability Community | `export-protected-redaction` | owner | 3 | 1 | export/import wizard with preview, redaction, checksum, transfer status, and rollback state |  |

### Evidence Repair Work Items Reference Patterns

| Reference | Source | URL | What to copy |
| --- | --- | --- | --- |
| Task list and export wizard | GOV.UK Design System / design-system | https://design-system.service.gov.uk/components/task-list/<br>Also: https://design-system.service.gov.uk/patterns/check-answers/ | Copy a wizard with steps, preview, redaction choices, checksum evidence, transfer status, and rollback confirmation. |
| Material Design cards and lists | Material Design 3 / design-system | https://m3.material.io/components/cards/overview<br>Also: https://m3.material.io/components/lists/overview | Use cards/lists only as scannable containers with clear hierarchy, content, metadata, and actions. Do not use repeated cards as the whole primary workflow. |
| Flutter sample app implementation patterns | flutter/samples / open-source | https://github.com/flutter/samples | Copy the separation between app shell, route state, domain widgets, and testable UI states rather than hardcoding a single generic renderer. |
| Material navigation and information architecture | Material Design 3 / design-system | https://m3.material.io/components/navigation-drawer/overview<br>Also: https://m3.material.io/components/navigation-bar/overview | Organize screens by user jobs and destinations; keep primary actions visible and avoid exposing implementation taxonomy. |
| Apple HIG navigation and content organization | Apple Human Interface Guidelines / design-system | https://developer.apple.com/design/human-interface-guidelines/navigation | Make navigation predictable, content-centered, and appropriate for the user’s current task. |

### Affected Workflow/Persona Coverage

Showing 1 of 1 affected coverage rows. Full detail is in the JSON ticket.

| Coverage row | Status | Community | Workflow | Persona | Missing evidence | Screen rows | Target surface |
| --- | --- | --- | --- | --- | --- | ---: | --- |
| `b25-wp-052-export-protected-redaction-community-export-migration-owner` | `pass` | Data Portability Community | `export-protected-redaction` | owner |  | 3 | export/import wizard with preview, redaction, checksum, transfer status, and rollback state |

### Affected Screen Rows

Showing 3 of 3 affected screen rows. Full detail is in the JSON ticket.

| Screen row | Community | Workflow | Persona | State | Screenshot | Hash | Visible text | Current surface | Exact UX failure | Target surface |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `b25-v4-row-154-export-protected-redaction-0` | Data Portability Community | `export-protected-redaction` | owner | B16_ext_export_migration_export-protected-redaction_start | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B16/screenshots/B16_ext_export_migration_export-protected-redaction_start.png` | `c0fc01a627f15...` | Protected redaction preview \| Mask protected fields with policy reasons before export. \| Review masked phone, care, vault, and payment fields with policy reasons and reveal permissions. \| Scope selected \| Policy masks \| Audit receipt \| Owner artifact \| Protected-field redactio... | domain-native-reviewed / domain-native | Ticket must add screenshot-backed visible text and a non-reusable critique for this exact screen. | export/import wizard with preview, redaction, checksum, transfer status, and rollback state |
| `b25-v4-row-155-export-protected-redaction-1` | Data Portability Community | `export-protected-redaction` | owner | B16_ext_export_migration_export-protected-redaction_action | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B16/screenshots/B16_ext_export_migration_export-protected-redaction_action.png` | `c978dd92bfeeb...` | Protected redaction preview \| Mask protected fields with policy reasons before export. \| Review masked phone, care, vault, and payment fields with policy reasons and reveal permissions. \| Protected-field redaction \| Protected fields \| Care notes, phone numbers, and private vau... | domain-native-reviewed / domain-native | Ticket must add screenshot-backed visible text and a non-reusable critique for this exact screen. | export/import wizard with preview, redaction, checksum, transfer status, and rollback state |
| `b25-v4-row-156-export-protected-redaction-2` | Data Portability Community | `export-protected-redaction` | owner | B16_ext_export_migration_export-protected-redaction_complete | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B16/screenshots/B16_ext_export_migration_export-protected-redaction_complete.png` | `87a92a866735f...` | Protected redaction preview \| Mask protected fields with policy reasons before export. \| Protected redaction shows masked fields, policy reasons, before/after preview, and audit evidence. \| Scope selected \| Policy masks \| Audit receipt \| Owner artifact \| Protected-field redact... | domain-native-reviewed / domain-native | Ticket must add screenshot-backed visible text and a non-reusable critique for this exact screen. | export/import wizard with preview, redaction, checksum, transfer status, and rollback state |

### Failing Workflow/Persona Scorecards

Showing 1 of 1 failing scorecards. Full detail is in the JSON ticket.

| Scorecard | Community | Workflow | Persona | Failed questions | Target surface |
| --- | --- | --- | --- | ---: | --- |
| `b25-wp-052-export-protected-redaction-community-export-migration-owner` | Data Portability Community | `export-protected-redaction` | owner | 2 | export/import wizard with preview, redaction, checksum, transfer status, and rollback state |

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

### Concrete Acceptance Criteria
- Every workflow/persona scorecard is present, screenshot-backed, non-boilerplate, and pass.
- `production_ux_judge.dart` has no blocking failure for this criterion.
- `b25_iteration_scorecard.dart` records the ticket as resolved or no longer blocking.
- Screenshots are refreshed and hashes/timestamps/app commit SHA match the reviewed app version.
- Screen row `b25-v4-row-154-export-protected-redaction-0` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-154-export-protected-redaction-0` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-154-export-protected-redaction-0` names visible UI elements, visible text, persona `owner`, workflow `export-protected-redaction`, and the exact product UX issue.
- Primary surface for `export-protected-redaction` is documented as `export/import wizard with preview, redaction, checksum, transfer status, and rollback state` or another explicit domain-native surface.
- After-screenshot visible text proves every required semantic surface group for `export-protected-redaction`.
- Fresh screenshot path/hash/timestamp/app commit SHA are recorded after the fix.
- The workflow/persona direct-question scorecard passes the visible-text and task-specific critique question.
- Screen row `b25-v4-row-155-export-protected-redaction-1` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-155-export-protected-redaction-1` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-155-export-protected-redaction-1` names visible UI elements, visible text, persona `owner`, workflow `export-protected-redaction`, and the exact product UX issue.
- Screen row `b25-v4-row-156-export-protected-redaction-2` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-156-export-protected-redaction-2` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-156-export-protected-redaction-2` names visible UI elements, visible text, persona `owner`, workflow `export-protected-redaction`, and the exact product UX issue.
- Coverage row has a specific persona and personaId.
- Coverage row has entry, action/review, and result/receiver screenshots.
- Every listed screenshot path exists and has a fresh hash/timestamp/app commit SHA.
- The workflow/persona scorecard passes after rerun.

### Affected Evidence
- `independent-production-ux-review.json workflowPersonaScorecards`
- `independent-production-ux-review.json screenRows`
- `product-ux-screen-review-matrix.md every workflow/persona row`
- `production-ux-criteria-scorecard.json/.md`

### Evidence To Collect
- Visible text extracts for every reviewed row.
- Non-boilerplate screen-specific critique for every reviewed row.
- Updated markdown matrix matching the JSON evidence.

### Acceptance Checks
- Every workflow/persona scorecard is present, screenshot-backed, non-boilerplate, and pass.
- `production_ux_judge.dart` has no blocking failure for this criterion.
- `b25_iteration_scorecard.dart` records the ticket as resolved or no longer blocking.
- Screenshots are refreshed and hashes/timestamps/app commit SHA match the reviewed app version.

### Non-Goals
- Do not reuse the same critique across unrelated screens.
- Do not write critique that could apply without seeing the screenshot.

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

## B25-RT-009-b25-c09-no-layout-production-defects

| Field | Value |
| --- | --- |
| Severity | major |
| Priority | P1 |
| Status | open |
| Review run | `b25-v4-pass-24` |
| Source criterion | `b25-c09-no-layout-production-defects` |
| Source findings | B25-HOLISTIC-UX-FAILED |
| Title | No blocking or major layout/content defects remain |
| Direct question | Does the visible UI avoid blocking or major overlap, clipping, crowding, default-scaffold, repeated-card, checklist-modal, and thin-content defects? |
| Why it failed | holistic direct-question answers are missing, weak, partial, or blocking: b25-v4-pass-24-modern-easy-appealing, b25-v4-pass-24-community-ia, b25-v4-pass-24-copy-product-native, b25-v4-pass-24-visual-system, b25-v4-pass-24-repeated-card-fatigue, b25-v4-pass-24-concrete-content-lifecycle-actions. |
| Required outcome | Fix layout/content defects and rerun the review. |
| Remediation mode | `review-only` |
| Worker readiness | no concrete implementation work item was generated; planner must inspect the direct-question failure before assigning a worker |
| First required step | Review failing direct questions and add screen/workflow/persona-specific evidence before implementation. |

### Problem Statement

The evidence does not prove that the visible UI is free of major overlap, clipping, crowding, repeated-card, checklist-modal, or thin-content defects.

### Root Cause Hypothesis

The pass has not performed a screenshot-grounded defect audit for mobile layout, density, component quality, and content depth.

### Target Experience

The reviewed UI should have no major overlap, clipping, crowding, default scaffold feel, repeated-card primary UX, checklist-modal primary UX, or thin placeholder content.

### UX Principles
- No major layout defects
- No thin placeholder content
- No checklist or scaffold feel on primary screens

### Concrete Improvements
- Audit screenshots for overlap, clipping, crowding, default scaffold appearance, repeated-card primary UX, checklist-modal UX, and thin placeholder content.
- Fix any blocking or major layout/content defects and document before/after screenshot references.
- Update holistic direct-question answers with screenshot-backed proof that no major layout/content defects remain.

### Implementation Guidance
- Inspect `apps/loom_communities_demo/lib` for the primary community home, shell, card, detail, and workflow surface widgets.
- Compare every change against `docs/Build Plan V2/Evidence/B25/production-ux-blueprint.md` before coding.
- Update widget tests and B25 evidence expectations when user-facing hierarchy, copy, or surface structure changes.

### Content Guidance
- Replace placeholder, framework, workflow, evidence, or metadata language with user-facing product copy.
- Use content that helps the target persona understand status, options, consequences, and next steps.

### Visual Guidance
- Audit screenshots for overlap, clipping, crowding, bottom control collisions, dense repeated cards, and modals that hide primary workflow context.
- Prefer stable responsive dimensions and scroll-safe spacing for cards, lists, dialogs, and floating actions.

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

### Failing Direct Questions

| Question | Scope | Score | Why | Required fix |
| --- | --- | ---: | --- | --- |
| Is the UI modern, easy to use, easy to navigate, and visually appealing for the target persona? | holistic | 0 | The screens are readable and mostly unclipped, but they do not feel like differentiated production product screens. The dominant experience is a uniform workflow-card scaffold rather than modern task-specific surfaces. | Replace the generic stacked-card renderer with screen-specific product surfaces such as feeds, inbox threads, event detail pages, payment receipts, export wizards, care request forms, and review queues. |
| Is information architecture centered on real community jobs and content? | holistic | 0 | The content has domain labels, but navigation and page structure are still organized around workflow state cards and validation concepts rather than natural community destinations and jobs. | Reframe home and workflow entry around community sections and objects: event calendars, inboxes, document libraries, donation history, request queues, rosters, and export/recovery workspaces. |
| Does copy sound product-native rather than workflow/spec/test language? | holistic | 0 | The copy often describes the workflow contract rather than speaking as a finished product to the user in the current task. | Rewrite user-facing copy as domain-native product language, using concrete object state and next steps; remove UX-contract phrases from visible screens. |
| Are hierarchy, spacing, typography, color, and component variety shippable? | holistic | 0 | The visual system is coherent but too monotonous and template-bound for a production UX bar across 68 workflow/persona paths. | Introduce task-appropriate layouts and component variety: compact lists, real forms, timelines, tables/checklists where appropriate, receipts, message bubbles, document rows, and richer status/history treatments. |
| Is repeated-card fatigue absent? | holistic | 0 | The repeated-card shell is the dominant user experience, so the app still reads as a generic workflow renderer with domain copy pasted into it. | Create domain-native primary surfaces for each workflow family and reserve cards for individual items, not the entire screen architecture. |
| Does each screen provide concrete content and lifecycle actions a real user needs? | holistic | 0 | The screenshots often include useful details, but B25 cannot pass while lifecycle scorecards and one workflow/persona scorecard still fail, and several result states remain generic. | Add screenshot-proven concrete object context and persistent result/receiver states for failed workflows, then rerun lifecycle and LLM review gates. |

### Likely Files / Widgets
- `app/apps/loom_communities_demo/lib/main.dart`
- `app/apps/loom_communities_demo/test/b21_b25_production_ux_test.dart`
- `docs/Build Plan V2/Evidence/B25/production-ux-blueprint.md`
- `docs/Build Plan V2/Evidence/B25/independent-production-ux-review.json`
- `docs/Build Plan V2/Evidence/B25/product-ux-screen-review-matrix.md`

### Concrete Acceptance Criteria
- Holistic direct-question answers are present, screenshot-backed, non-boilerplate, and pass.
- `production_ux_judge.dart` has no blocking failure for this criterion.
- `b25_iteration_scorecard.dart` records the ticket as resolved or no longer blocking.
- Screenshots are refreshed and hashes/timestamps/app commit SHA match the reviewed app version.

### Affected Evidence
- `independent-production-ux-review.json holisticQuestionAnswers`
- `independent-production-ux-review.md holistic review summary`
- `product-ux-screen-review-matrix.md relevant screen rows`
- `production-ux-criteria-scorecard.json/.md`

### Evidence To Collect
- Fresh holistic screenshots for primary homes, navigation, representative detail surfaces, and representative completion/result states.
- `holisticQuestionAnswers` with visible evidence, score, pass/fail answer, and specific rationale.
- `llmVisionReview` imported from a fresh LLM vision UX judge run against the after screenshots.
- Updated `production-ux-criteria-scorecard.json/.md` showing the criterion passes.

### Acceptance Checks
- Holistic direct-question answers are present, screenshot-backed, non-boilerplate, and pass.
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
