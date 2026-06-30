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
| Review run | `b25-v4-pass-16` |
| Source criterion | `b25-c01-no-blocker-major` |
| Source findings | LLM-B25-P16-001, LLM-B25-P16-002, LLM-B25-P16-003 |
| Title | No unresolved blocker or major findings |
| Direct question | Are there zero unresolved blocker or major findings in the current production UX evidence? |
| Why it failed | Unresolved blocker/major counts are blocker=1 major=2. |
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
| Task list and export wizard | GOV.UK Design System / design-system | https://design-system.service.gov.uk/components/task-list/<br>Also: https://design-system.service.gov.uk/patterns/check-answers/ | Copy a wizard with steps, preview, redaction choices, checksum evidence, transfer status, and rollback confirmation. |
| Selection and voting pattern | Material chips/cards/buttons / pattern | https://m3.material.io/components/chips/overview<br>Also: https://m3.material.io/components/cards/overview | Copy a nomination/voting surface with choices, current vote state, deadline, selected result, and meeting/discussion context. |
| Event detail and RSVP flow | Material cards/lists/buttons / pattern | https://m3.material.io/components/cards/overview<br>Also: https://m3.material.io/components/buttons/overview<br>https://m3.material.io/components/chips/overview | Copy an event detail layout: title, date/time, location, host, capacity/status chip, attendee context, RSVP action, and confirmation state. |
| Inbox and message thread pattern | Material lists/text fields / pattern | https://m3.material.io/components/lists/overview<br>Also: https://m3.material.io/components/text-fields/overview | Copy an inbox/thread structure: sender, timestamp, message preview/body, reply field, invite/block state, and read/received state. |
| Feed item and composer pattern | Material cards/lists/text fields / pattern | https://m3.material.io/components/text-fields/overview<br>Also: https://m3.material.io/components/cards/overview<br>https://m3.material.io/components/lists/overview | Copy a feed/composer structure: audience, author, timestamp, body, attachments/status, publish action, and receiver read state. |
| Form validation and review pattern | U.S. Web Design System / design-system | https://designsystem.digital.gov/components/form/<br>Also: https://designsystem.digital.gov/components/alert/<br>https://design-system.service.gov.uk/components/error-summary/ | Copy a form flow with field labels, helper text, validation errors, review state, submit action, status, and protected-data treatment. |
| Material detail surface composition | Material Design 3 / design-system | https://m3.material.io/components/cards/overview | Build a domain detail page with primary content, metadata, status, and actions instead of a generic task card. |

### Reference Research Queries
- production mobile UX review screenshot critique examples
- open source Flutter mobile app UX patterns GitHub
- open source Flutter export-wizard mobile UI example GitHub
- export/import wizard with preview, redaction, checksum, transfer status, and rollback state mobile UX pattern
- Material Design export/import wizard with preview, redaction, checksum, transfer status, and rollback state mobile pattern
- open source Flutter voting-selection mobile UI example GitHub
- book club reading/voting surface with nominations, vote state, selected book, meeting context, and discussion mobile UX pattern
- Material Design book club reading/voting surface with nominations, vote state, selected book, meeting context, and discussion mobile pattern
- open source Flutter event-rsvp mobile UI example GitHub
- event detail with schedule, location, capacity/status, RSVP action, and result state mobile UX pattern
- Material Design event detail with schedule, location, capacity/status, RSVP action, and result state mobile pattern
- open source Flutter message-thread mobile UI example GitHub
- inbox, message thread, connection card, invite, or block-state surface mobile UX pattern
- Material Design inbox, message thread, connection card, invite, or block-state surface mobile pattern
- open source Flutter announcement-feed mobile UI example GitHub
- announcement feed/composer with audience, author, timestamp, body, and receiver state mobile UX pattern
- Material Design announcement feed/composer with audience, author, timestamp, body, and receiver state mobile pattern
- open source Flutter form-review mobile UI example GitHub
- volunteer signup surface with role, time, protected contact fields, and confirmation mobile UX pattern
- Material Design volunteer signup surface with role, time, protected contact fields, and confirmation mobile pattern

### Implementation Blocked By
- Open blocker/major B25 tickets remain.
- The scorecard cannot close until those tickets rerun clean.

### Affected Screen Rows

Showing 11 of 11 affected screen rows. Full detail is in the JSON ticket.

| Screen row | Community | Workflow | Persona | State | Screenshot | Hash | Visible text | Current surface | Exact UX failure | Target surface |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `b25-v4-row-008-garden-export-custom-schemas-1` | Garden Club | `garden-export-custom-schemas` | owner | B13_ext_garden_club_garden-export-custom-schemas_action | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B13/screenshots/B13_ext_garden_club_garden-export-custom-schemas_action.png` | `1105b28624553...` | Prepare export handoff \| Use this surface to package export scope, redaction, and handoff status. \| Redacted copy \| Checksum ready \| Exportable \| Decision \| Decide the scope, redaction, checksum, destination, and whether to retry, roll back, or change scope. \| Details \| Data s... | domain-native-reviewed / domain-native | LLM vision critique: This remains a generic workflow/action template. Even if export is a supporting/admin flow, the surface is not production-grade because it exposes implementation taxonomy. LLM required fix: Redesign as an export package review screen with file/package identity, included data types, redaction summary, checksum, destination, audit trail, rollback/change-scope controls, and final generate/download action. Current row verdict is `fail` with severity `major`. | export/import wizard with preview, redaction, checksum, transfer status, and rollback state |
| `b25-v4-row-011-book-nomination-1` | Neighborhood Book Club | `book-nomination` | member | B14_ext_book_club_book-nomination_action | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_book_club_book-nomination_action.png` | `d971530b07e27...` | Submit member form \| Use this surface to submit structured member details. \| Labeled fields \| Privacy checked \| Review handoff \| Decision \| Decide what to save, what to change, and what status or next step should remain visible afterward. \| Details \| Required details are ready... | domain-native-reviewed / domain-native | LLM vision critique: This is not a book nomination product surface. It does not show a title, author, member rationale, genre, meeting context, voting/nomination state, or a natural review/submit form. LLM required fix: Replace with a real book nomination form/review screen including book title, author, reason for nomination, meeting cycle, visibility/privacy settings if needed, edit/cancel, and submit nomination result. Current row verdict is `fail` with severity `blocker`. | book club reading/voting surface with nominations, vote state, selected book, meeting context, and discussion |
| `b25-v4-row-014-book-vote-1` | Neighborhood Book Club | `book-vote` | member | B14_ext_book_club_book-vote_action | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_book_club_book-vote_action.png` | `7b2761d92193b...` | Submit member form \| Use this surface to submit structured member details. \| Labeled fields \| Privacy checked \| Review handoff \| Decision \| Decide what to save, what to change, and what status or next step should remain visible afterward. \| Details \| Required details are ready... | domain-native-reviewed / domain-native | No row-specific failure recorded. | book club reading/voting surface with nominations, vote state, selected book, meeting context, and discussion |
| `b25-v4-row-017-book-meeting-rsvp-1` | Neighborhood Book Club | `book-meeting-rsvp` | member | B14_ext_book_club_book-meeting-rsvp_action | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_book_club_book-meeting-rsvp_action.png` | `2e978d0902300...` | Coordinate attendance \| Use this surface to publish event details, capacity, and attendance state. \| This week \| Community venue \| Capacity tracked \| RSVP available \| Decision \| Decide if you are going, maybe, or not attending after checking date, time, location, and capacity.... | domain-native-reviewed / domain-native | LLM vision critique: Unlike the improved Garden RSVP, this event screen remains a template. It does not feel like a book club meeting page because it lacks the book, venue, time, discussion host, attendee state, and concrete RSVP controls. LLM required fix: Create a book meeting RSVP detail screen with meeting title, selected book, date/time, venue, host, capacity, current RSVP, attendee/reminder state, and natural RSVP/change-response controls. Current row verdict is `fail` with severity `major`. | event detail with schedule, location, capacity/status, RSVP action, and result state |
| `b25-v4-row-020-book-discussion-message-1` | Neighborhood Book Club | `book-discussion-message` | member | B14_ext_book_club_book-discussion-message_action | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_book_club_book-discussion-message_action.png` | `b7942f903d0d1...` | Update member channel \| Use this surface to change a member communication or relationship setting. \| Private by default \| Membership scoped \| Ready \| Decision \| Decide whether to reply, send, accept, decline, mute, archive, or block this member communication. \| Details \| Membe... | domain-native-reviewed / domain-native | No row-specific failure recorded. | inbox, message thread, connection card, invite, or block-state surface |
| `b25-v4-row-023-book-selection-publish-1` | Neighborhood Book Club | `book-selection-publish` | owner | B14_ext_book_club_book-selection-publish_action | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_book_club_book-selection-publish_action.png` | `48516b6175aef...` | Send community notice \| Use this surface to send a scoped announcement to the selected audience. \| Members \| Today \| From admin \| Inbox + push \| Decision \| Decide whether this message is ready for members, who receives it, and whether to preview or save a draft first. \| Detail... | domain-native-reviewed / domain-native | No row-specific failure recorded. | announcement feed/composer with audience, author, timestamp, body, and receiver state |
| `b25-v4-row-074-mosque-announcement-1` | Masjid Nur | `mosque-announcement` | owner | B14_ext_mosque_mosque-announcement_action | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_mosque_mosque-announcement_action.png` | `4f9beca474852...` | Send community notice \| Use this surface to send a scoped announcement to the selected audience. \| Members \| Today \| From admin \| Inbox + push \| Decision \| Decide whether this message is ready for members, who receives it, and whether to preview or save a draft first. \| Detail... | domain-native-reviewed / domain-native | LLM vision critique: This is not yet a production announcement authoring or preview experience. It documents that an announcement can be sent, but does not look like a real admin composing and publishing a message to members. LLM required fix: Replace with a true announcement composer/review screen including subject, body, audience, schedule/channel, preview, save draft, publish, and sent/receiver state. Current row verdict is `fail` with severity `major`. | announcement feed/composer with audience, author, timestamp, body, and receiver state |
| `b25-v4-row-077-mosque-event-rsvp-1` | Masjid Nur | `mosque-event-rsvp` | member | B14_ext_mosque_mosque-event-rsvp_action | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_mosque_mosque-event-rsvp_action.png` | `2e978d0902300...` | Coordinate attendance \| Use this surface to publish event details, capacity, and attendance state. \| This week \| Community venue \| Capacity tracked \| RSVP available \| Decision \| Decide if you are going, maybe, or not attending after checking date, time, location, and capacity.... | domain-native-reviewed / domain-native | No row-specific failure recorded. | event detail with schedule, location, capacity/status, RSVP action, and result state |
| `b25-v4-row-080-mosque-volunteer-signup-1` | Masjid Nur | `mosque-volunteer-signup` | member | B14_ext_mosque_mosque-volunteer-signup_action | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_mosque_mosque-volunteer-signup_action.png` | `295f52a21ab9b...` | Submit member form \| Use this surface to submit structured member details. \| Open shift \| Contact protected \| Coordinator notified \| Decision \| Decide what to save, what to change, and what status or next step should remain visible afterward. \| Details \| Required details are r... | domain-native-reviewed / domain-native | LLM vision critique: This does not feel like a volunteer signup flow. A member should see a specific shift, time, role, requirements, contact preference, confirmation, and coordinator follow-up. LLM required fix: Build a volunteer shift signup surface with shift details, time/location, role requirements, contact/privacy controls, cancel/change option, signup confirmation, and coordinator receiver state. Current row verdict is `fail` with severity `major`. | volunteer signup surface with role, time, protected contact fields, and confirmation |
| `b25-v4-row-185-wf-persona-role-inventory-capability-matrix-1` | persona-role-inventory | `wf_persona-role-inventory-capability-matrix` | member | B17_persona_inventory_picker | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B17/screenshots/B17_persona_inventory_picker.png` | `d0bbd8a16d686...` | No sponsored message right now. \| Masjid Nur \| Coordinate announcements, events, volunteers, giving, and care. \| Masjid Admin \| Admin - Publishes announcements and sends neutral notifications. \| 2 personas \| Announcements \| Updates, reminders, and member notices for Masjid Nur... | domain-native-reviewed / domain-native | No row-specific failure recorded. | persona capability matrix surface with roles, allowed actions, receiver states, and denied/hidden behavior |
| `b25-v4-row-186-wf-demo-app-persona-picker-0` | Masjid Nur | `wf_demo-app-persona-picker` | member | B18_persona_picker_dialog | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B18/screenshots/B18_persona_picker_dialog.png` | `d0bbd8a16d686...` | No sponsored message right now. \| Masjid Nur \| Coordinate announcements, events, volunteers, giving, and care. \| Masjid Admin \| Admin - Publishes announcements and sends neutral notifications. \| 2 personas \| Announcements \| Updates, reminders, and member notices for Masjid Nur... | domain-native-reviewed / domain-native | No row-specific failure recorded. | test-only persona switcher surface with active persona, role description, and return-to-workflow state |

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
- Screen row `b25-v4-row-008-garden-export-custom-schemas-1` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-008-garden-export-custom-schemas-1` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-008-garden-export-custom-schemas-1` names visible UI elements, visible text, persona `owner`, workflow `garden-export-custom-schemas`, and the exact product UX issue.
- Primary surface for `garden-export-custom-schemas` is documented as `export/import wizard with preview, redaction, checksum, transfer status, and rollback state` or another explicit domain-native surface.
- After-screenshot visible text proves every required semantic surface group for `garden-export-custom-schemas`.
- Fresh screenshot path/hash/timestamp/app commit SHA are recorded after the fix.
- Screen row `b25-v4-row-011-book-nomination-1` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-011-book-nomination-1` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-011-book-nomination-1` names visible UI elements, visible text, persona `member`, workflow `book-nomination`, and the exact product UX issue.
- Primary surface for `book-nomination` is documented as `book club reading/voting surface with nominations, vote state, selected book, meeting context, and discussion` or another explicit domain-native surface.
- After-screenshot visible text proves every required semantic surface group for `book-nomination`.
- Screen row `b25-v4-row-014-book-vote-1` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-014-book-vote-1` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-014-book-vote-1` names visible UI elements, visible text, persona `member`, workflow `book-vote`, and the exact product UX issue.
- Primary surface for `book-vote` is documented as `book club reading/voting surface with nominations, vote state, selected book, meeting context, and discussion` or another explicit domain-native surface.
- After-screenshot visible text proves every required semantic surface group for `book-vote`.
- Screen row `b25-v4-row-017-book-meeting-rsvp-1` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-017-book-meeting-rsvp-1` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-017-book-meeting-rsvp-1` names visible UI elements, visible text, persona `member`, workflow `book-meeting-rsvp`, and the exact product UX issue.
- Primary surface for `book-meeting-rsvp` is documented as `event detail with schedule, location, capacity/status, RSVP action, and result state` or another explicit domain-native surface.
- After-screenshot visible text proves every required semantic surface group for `book-meeting-rsvp`.
- Screen row `b25-v4-row-020-book-discussion-message-1` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-020-book-discussion-message-1` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-020-book-discussion-message-1` names visible UI elements, visible text, persona `member`, workflow `book-discussion-message`, and the exact product UX issue.
- Primary surface for `book-discussion-message` is documented as `inbox, message thread, connection card, invite, or block-state surface` or another explicit domain-native surface.
- After-screenshot visible text proves every required semantic surface group for `book-discussion-message`.
- Screen row `b25-v4-row-023-book-selection-publish-1` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-023-book-selection-publish-1` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-023-book-selection-publish-1` names visible UI elements, visible text, persona `owner`, workflow `book-selection-publish`, and the exact product UX issue.
- Primary surface for `book-selection-publish` is documented as `announcement feed/composer with audience, author, timestamp, body, and receiver state` or another explicit domain-native surface.
- After-screenshot visible text proves every required semantic surface group for `book-selection-publish`.
- Screen row `b25-v4-row-074-mosque-announcement-1` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-074-mosque-announcement-1` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-074-mosque-announcement-1` names visible UI elements, visible text, persona `owner`, workflow `mosque-announcement`, and the exact product UX issue.
- Primary surface for `mosque-announcement` is documented as `announcement feed/composer with audience, author, timestamp, body, and receiver state` or another explicit domain-native surface.
- After-screenshot visible text proves every required semantic surface group for `mosque-announcement`.
- Screen row `b25-v4-row-077-mosque-event-rsvp-1` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-077-mosque-event-rsvp-1` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-077-mosque-event-rsvp-1` names visible UI elements, visible text, persona `member`, workflow `mosque-event-rsvp`, and the exact product UX issue.
- Primary surface for `mosque-event-rsvp` is documented as `event detail with schedule, location, capacity/status, RSVP action, and result state` or another explicit domain-native surface.
- After-screenshot visible text proves every required semantic surface group for `mosque-event-rsvp`.
- Screen row `b25-v4-row-080-mosque-volunteer-signup-1` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-080-mosque-volunteer-signup-1` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-080-mosque-volunteer-signup-1` names visible UI elements, visible text, persona `member`, workflow `mosque-volunteer-signup`, and the exact product UX issue.
- Primary surface for `mosque-volunteer-signup` is documented as `volunteer signup surface with role, time, protected contact fields, and confirmation` or another explicit domain-native surface.
- After-screenshot visible text proves every required semantic surface group for `mosque-volunteer-signup`.
- Screen row `b25-v4-row-185-wf-persona-role-inventory-capability-matrix-1` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-185-wf-persona-role-inventory-capability-matrix-1` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-185-wf-persona-role-inventory-capability-matrix-1` names visible UI elements, visible text, persona `member`, workflow `wf_persona-role-inventory-capability-matrix`, and the exact product UX issue.
- Primary surface for `wf_persona-role-inventory-capability-matrix` is documented as `persona capability matrix surface with roles, allowed actions, receiver states, and denied/hidden behavior` or another explicit domain-native surface.
- After-screenshot visible text proves every required semantic surface group for `wf_persona-role-inventory-capability-matrix`.
- Screen row `b25-v4-row-186-wf-demo-app-persona-picker-0` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-186-wf-demo-app-persona-picker-0` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-186-wf-demo-app-persona-picker-0` names visible UI elements, visible text, persona `member`, workflow `wf_demo-app-persona-picker`, and the exact product UX issue.
- Primary surface for `wf_demo-app-persona-picker` is documented as `test-only persona switcher surface with active persona, role description, and return-to-workflow state` or another explicit domain-native surface.
- After-screenshot visible text proves every required semantic surface group for `wf_demo-app-persona-picker`.

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
| Review run | `b25-v4-pass-16` |
| Source criterion | `b25-c03-production-grade-experience` |
| Source findings | LLM-B25-P16-001, LLM-B25-P16-002, LLM-B25-P16-003 |
| Title | Reviewer can state the experience feels production-grade |
| Direct question | Does the whole experience feel like a real production community app for the target users, not merely an implemented workflow harness? |
| Why it failed | holistic direct-question answers are missing, weak, partial, or blocking: llm-holistic-production-grade, llm-holistic-modern-easy-navigation, llm-holistic-community-centered, llm-primary-workflow-surfaces. |
| Required outcome | Run the independent screenshot-first review and record a production-grade verdict grounded in screen evidence. |
| Remediation mode | `ui-remediation-ready` |
| Worker readiness | ready for worker implementation using the uiRemediationWorkItems |
| First required step | Implement the target production surfaces and content specified in uiRemediationWorkItems, then recapture screenshots. |

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
| Task list and export wizard | GOV.UK Design System / design-system | https://design-system.service.gov.uk/components/task-list/<br>Also: https://design-system.service.gov.uk/patterns/check-answers/ | Copy a wizard with steps, preview, redaction choices, checksum evidence, transfer status, and rollback confirmation. |
| Selection and voting pattern | Material chips/cards/buttons / pattern | https://m3.material.io/components/chips/overview<br>Also: https://m3.material.io/components/cards/overview | Copy a nomination/voting surface with choices, current vote state, deadline, selected result, and meeting/discussion context. |
| Event detail and RSVP flow | Material cards/lists/buttons / pattern | https://m3.material.io/components/cards/overview<br>Also: https://m3.material.io/components/buttons/overview<br>https://m3.material.io/components/chips/overview | Copy an event detail layout: title, date/time, location, host, capacity/status chip, attendee context, RSVP action, and confirmation state. |
| Inbox and message thread pattern | Material lists/text fields / pattern | https://m3.material.io/components/lists/overview<br>Also: https://m3.material.io/components/text-fields/overview | Copy an inbox/thread structure: sender, timestamp, message preview/body, reply field, invite/block state, and read/received state. |
| Feed item and composer pattern | Material cards/lists/text fields / pattern | https://m3.material.io/components/text-fields/overview<br>Also: https://m3.material.io/components/cards/overview<br>https://m3.material.io/components/lists/overview | Copy a feed/composer structure: audience, author, timestamp, body, attachments/status, publish action, and receiver read state. |
| Form validation and review pattern | U.S. Web Design System / design-system | https://designsystem.digital.gov/components/form/<br>Also: https://designsystem.digital.gov/components/alert/<br>https://design-system.service.gov.uk/components/error-summary/ | Copy a form flow with field labels, helper text, validation errors, review state, submit action, status, and protected-data treatment. |

### Reference Research Queries
- production mobile UX review screenshot critique examples
- open source Flutter mobile app UX patterns GitHub
- open source Flutter export-wizard mobile UI example GitHub
- export/import wizard with preview, redaction, checksum, transfer status, and rollback state mobile UX pattern
- Material Design export/import wizard with preview, redaction, checksum, transfer status, and rollback state mobile pattern
- open source Flutter voting-selection mobile UI example GitHub
- book club reading/voting surface with nominations, vote state, selected book, meeting context, and discussion mobile UX pattern
- Material Design book club reading/voting surface with nominations, vote state, selected book, meeting context, and discussion mobile pattern
- open source Flutter event-rsvp mobile UI example GitHub
- event detail with schedule, location, capacity/status, RSVP action, and result state mobile UX pattern
- Material Design event detail with schedule, location, capacity/status, RSVP action, and result state mobile pattern
- open source Flutter message-thread mobile UI example GitHub
- inbox, message thread, connection card, invite, or block-state surface mobile UX pattern
- Material Design inbox, message thread, connection card, invite, or block-state surface mobile pattern
- open source Flutter announcement-feed mobile UI example GitHub
- announcement feed/composer with audience, author, timestamp, body, and receiver state mobile UX pattern
- Material Design announcement feed/composer with audience, author, timestamp, body, and receiver state mobile pattern
- open source Flutter form-review mobile UI example GitHub
- volunteer signup surface with role, time, protected contact fields, and confirmation mobile UX pattern
- Material Design volunteer signup surface with role, time, protected contact fields, and confirmation mobile pattern

### UI Remediation Work Items

Showing 9 of 9 work items. Full detail is in the JSON artifact.

| Work item | Stage | Community | Workflow | Persona | Screens | Coverage | Target surface | Blocked until |
| --- | --- | --- | --- | --- | ---: | ---: | --- | --- |
| `b25-wi-ui-remediation-community-garden-club-garden-export-custom-schemas-community-garden-club-owner` | `ui-remediation` | Garden Club | `garden-export-custom-schemas` | owner | 1 | 0 | export/import wizard with preview, redaction, checksum, transfer status, and rollback state | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-book-club-book-nomination-community-book-club-member` | `ui-remediation` | Neighborhood Book Club | `book-nomination` | member | 1 | 0 | book club reading/voting surface with nominations, vote state, selected book, meeting context, and discussion | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-book-club-book-vote-community-book-club-member` | `ui-remediation` | Neighborhood Book Club | `book-vote` | member | 1 | 0 | book club reading/voting surface with nominations, vote state, selected book, meeting context, and discussion | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-book-club-book-meeting-rsvp-community-book-club-member` | `ui-remediation` | Neighborhood Book Club | `book-meeting-rsvp` | member | 1 | 0 | event detail with schedule, location, capacity/status, RSVP action, and result state | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-book-club-book-discussion-message-community-book-club-member` | `ui-remediation` | Neighborhood Book Club | `book-discussion-message` | member | 1 | 0 | inbox, message thread, connection card, invite, or block-state surface | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-book-club-book-selection-publish-community-book-club-owner` | `ui-remediation` | Neighborhood Book Club | `book-selection-publish` | owner | 1 | 0 | announcement feed/composer with audience, author, timestamp, body, and receiver state | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-mosque-mosque-announcement-community-mosque-owner` | `ui-remediation` | Masjid Nur | `mosque-announcement` | owner | 1 | 0 | announcement feed/composer with audience, author, timestamp, body, and receiver state | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-mosque-mosque-event-rsvp-community-mosque-member` | `ui-remediation` | Masjid Nur | `mosque-event-rsvp` | member | 1 | 0 | event detail with schedule, location, capacity/status, RSVP action, and result state | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-mosque-mosque-volunteer-signup-community-mosque-member` | `ui-remediation` | Masjid Nur | `mosque-volunteer-signup` | member | 1 | 0 | volunteer signup surface with role, time, protected contact fields, and confirmation | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |

### UI Remediation Work Items Reference Patterns

| Reference | Source | URL | What to copy |
| --- | --- | --- | --- |
| Task list and export wizard | GOV.UK Design System / design-system | https://design-system.service.gov.uk/components/task-list/<br>Also: https://design-system.service.gov.uk/patterns/check-answers/ | Copy a wizard with steps, preview, redaction choices, checksum evidence, transfer status, and rollback confirmation. |
| Material Design cards and lists | Material Design 3 / design-system | https://m3.material.io/components/cards/overview<br>Also: https://m3.material.io/components/lists/overview | Use cards/lists only as scannable containers with clear hierarchy, content, metadata, and actions. Do not use repeated cards as the whole primary workflow. |
| Flutter sample app implementation patterns | flutter/samples / open-source | https://github.com/flutter/samples | Copy the separation between app shell, route state, domain widgets, and testable UI states rather than hardcoding a single generic renderer. |
| Material navigation and information architecture | Material Design 3 / design-system | https://m3.material.io/components/navigation-drawer/overview<br>Also: https://m3.material.io/components/navigation-bar/overview | Organize screens by user jobs and destinations; keep primary actions visible and avoid exposing implementation taxonomy. |
| Apple HIG navigation and content organization | Apple Human Interface Guidelines / design-system | https://developer.apple.com/design/human-interface-guidelines/navigation | Make navigation predictable, content-centered, and appropriate for the user’s current task. |
| Selection and voting pattern | Material chips/cards/buttons / pattern | https://m3.material.io/components/chips/overview<br>Also: https://m3.material.io/components/cards/overview | Copy a nomination/voting surface with choices, current vote state, deadline, selected result, and meeting/discussion context. |
| Event detail and RSVP flow | Material cards/lists/buttons / pattern | https://m3.material.io/components/cards/overview<br>Also: https://m3.material.io/components/buttons/overview<br>https://m3.material.io/components/chips/overview | Copy an event detail layout: title, date/time, location, host, capacity/status chip, attendee context, RSVP action, and confirmation state. |
| Inbox and message thread pattern | Material lists/text fields / pattern | https://m3.material.io/components/lists/overview<br>Also: https://m3.material.io/components/text-fields/overview | Copy an inbox/thread structure: sender, timestamp, message preview/body, reply field, invite/block state, and read/received state. |
| Feed item and composer pattern | Material cards/lists/text fields / pattern | https://m3.material.io/components/text-fields/overview<br>Also: https://m3.material.io/components/cards/overview<br>https://m3.material.io/components/lists/overview | Copy a feed/composer structure: audience, author, timestamp, body, attachments/status, publish action, and receiver read state. |
| Form validation and review pattern | U.S. Web Design System / design-system | https://designsystem.digital.gov/components/form/<br>Also: https://designsystem.digital.gov/components/alert/<br>https://design-system.service.gov.uk/components/error-summary/ | Copy a form flow with field labels, helper text, validation errors, review state, submit action, status, and protected-data treatment. |

### Affected Screen Rows

Showing 9 of 9 affected screen rows. Full detail is in the JSON ticket.

| Screen row | Community | Workflow | Persona | State | Screenshot | Hash | Visible text | Current surface | Exact UX failure | Target surface |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `b25-v4-row-008-garden-export-custom-schemas-1` | Garden Club | `garden-export-custom-schemas` | owner | B13_ext_garden_club_garden-export-custom-schemas_action | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B13/screenshots/B13_ext_garden_club_garden-export-custom-schemas_action.png` | `1105b28624553...` | Prepare export handoff \| Use this surface to package export scope, redaction, and handoff status. \| Redacted copy \| Checksum ready \| Exportable \| Decision \| Decide the scope, redaction, checksum, destination, and whether to retry, roll back, or change scope. \| Details \| Data s... | domain-native-reviewed / domain-native | LLM vision critique: This remains a generic workflow/action template. Even if export is a supporting/admin flow, the surface is not production-grade because it exposes implementation taxonomy. LLM required fix: Redesign as an export package review screen with file/package identity, included data types, redaction summary, checksum, destination, audit trail, rollback/change-scope controls, and final generate/download action. Current row verdict is `fail` with severity `major`. | export/import wizard with preview, redaction, checksum, transfer status, and rollback state |
| `b25-v4-row-011-book-nomination-1` | Neighborhood Book Club | `book-nomination` | member | B14_ext_book_club_book-nomination_action | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_book_club_book-nomination_action.png` | `d971530b07e27...` | Submit member form \| Use this surface to submit structured member details. \| Labeled fields \| Privacy checked \| Review handoff \| Decision \| Decide what to save, what to change, and what status or next step should remain visible afterward. \| Details \| Required details are ready... | domain-native-reviewed / domain-native | LLM vision critique: This is not a book nomination product surface. It does not show a title, author, member rationale, genre, meeting context, voting/nomination state, or a natural review/submit form. LLM required fix: Replace with a real book nomination form/review screen including book title, author, reason for nomination, meeting cycle, visibility/privacy settings if needed, edit/cancel, and submit nomination result. Current row verdict is `fail` with severity `blocker`. | book club reading/voting surface with nominations, vote state, selected book, meeting context, and discussion |
| `b25-v4-row-014-book-vote-1` | Neighborhood Book Club | `book-vote` | member | B14_ext_book_club_book-vote_action | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_book_club_book-vote_action.png` | `7b2761d92193b...` | Submit member form \| Use this surface to submit structured member details. \| Labeled fields \| Privacy checked \| Review handoff \| Decision \| Decide what to save, what to change, and what status or next step should remain visible afterward. \| Details \| Required details are ready... | domain-native-reviewed / domain-native | No row-specific failure recorded. | book club reading/voting surface with nominations, vote state, selected book, meeting context, and discussion |
| `b25-v4-row-017-book-meeting-rsvp-1` | Neighborhood Book Club | `book-meeting-rsvp` | member | B14_ext_book_club_book-meeting-rsvp_action | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_book_club_book-meeting-rsvp_action.png` | `2e978d0902300...` | Coordinate attendance \| Use this surface to publish event details, capacity, and attendance state. \| This week \| Community venue \| Capacity tracked \| RSVP available \| Decision \| Decide if you are going, maybe, or not attending after checking date, time, location, and capacity.... | domain-native-reviewed / domain-native | LLM vision critique: Unlike the improved Garden RSVP, this event screen remains a template. It does not feel like a book club meeting page because it lacks the book, venue, time, discussion host, attendee state, and concrete RSVP controls. LLM required fix: Create a book meeting RSVP detail screen with meeting title, selected book, date/time, venue, host, capacity, current RSVP, attendee/reminder state, and natural RSVP/change-response controls. Current row verdict is `fail` with severity `major`. | event detail with schedule, location, capacity/status, RSVP action, and result state |
| `b25-v4-row-020-book-discussion-message-1` | Neighborhood Book Club | `book-discussion-message` | member | B14_ext_book_club_book-discussion-message_action | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_book_club_book-discussion-message_action.png` | `b7942f903d0d1...` | Update member channel \| Use this surface to change a member communication or relationship setting. \| Private by default \| Membership scoped \| Ready \| Decision \| Decide whether to reply, send, accept, decline, mute, archive, or block this member communication. \| Details \| Membe... | domain-native-reviewed / domain-native | No row-specific failure recorded. | inbox, message thread, connection card, invite, or block-state surface |
| `b25-v4-row-023-book-selection-publish-1` | Neighborhood Book Club | `book-selection-publish` | owner | B14_ext_book_club_book-selection-publish_action | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_book_club_book-selection-publish_action.png` | `48516b6175aef...` | Send community notice \| Use this surface to send a scoped announcement to the selected audience. \| Members \| Today \| From admin \| Inbox + push \| Decision \| Decide whether this message is ready for members, who receives it, and whether to preview or save a draft first. \| Detail... | domain-native-reviewed / domain-native | No row-specific failure recorded. | announcement feed/composer with audience, author, timestamp, body, and receiver state |
| `b25-v4-row-074-mosque-announcement-1` | Masjid Nur | `mosque-announcement` | owner | B14_ext_mosque_mosque-announcement_action | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_mosque_mosque-announcement_action.png` | `4f9beca474852...` | Send community notice \| Use this surface to send a scoped announcement to the selected audience. \| Members \| Today \| From admin \| Inbox + push \| Decision \| Decide whether this message is ready for members, who receives it, and whether to preview or save a draft first. \| Detail... | domain-native-reviewed / domain-native | LLM vision critique: This is not yet a production announcement authoring or preview experience. It documents that an announcement can be sent, but does not look like a real admin composing and publishing a message to members. LLM required fix: Replace with a true announcement composer/review screen including subject, body, audience, schedule/channel, preview, save draft, publish, and sent/receiver state. Current row verdict is `fail` with severity `major`. | announcement feed/composer with audience, author, timestamp, body, and receiver state |
| `b25-v4-row-077-mosque-event-rsvp-1` | Masjid Nur | `mosque-event-rsvp` | member | B14_ext_mosque_mosque-event-rsvp_action | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_mosque_mosque-event-rsvp_action.png` | `2e978d0902300...` | Coordinate attendance \| Use this surface to publish event details, capacity, and attendance state. \| This week \| Community venue \| Capacity tracked \| RSVP available \| Decision \| Decide if you are going, maybe, or not attending after checking date, time, location, and capacity.... | domain-native-reviewed / domain-native | No row-specific failure recorded. | event detail with schedule, location, capacity/status, RSVP action, and result state |
| `b25-v4-row-080-mosque-volunteer-signup-1` | Masjid Nur | `mosque-volunteer-signup` | member | B14_ext_mosque_mosque-volunteer-signup_action | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_mosque_mosque-volunteer-signup_action.png` | `295f52a21ab9b...` | Submit member form \| Use this surface to submit structured member details. \| Open shift \| Contact protected \| Coordinator notified \| Decision \| Decide what to save, what to change, and what status or next step should remain visible afterward. \| Details \| Required details are r... | domain-native-reviewed / domain-native | LLM vision critique: This does not feel like a volunteer signup flow. A member should see a specific shift, time, role, requirements, contact preference, confirmation, and coordinator follow-up. LLM required fix: Build a volunteer shift signup surface with shift details, time/location, role requirements, contact/privacy controls, cancel/change option, signup confirmation, and coordinator receiver state. Current row verdict is `fail` with severity `major`. | volunteer signup surface with role, time, protected contact fields, and confirmation |

### Failing Direct Questions

| Question | Scope | Score | Why | Required fix |
| --- | --- | ---: | --- | --- |
| Does the whole experience feel like a real production community app, not merely an implemented workflow harness? | llm-vision-holistic | 58 |  | Replace all remaining generic action templates with domain-native product screens for each community workflow, with real object details, task-specific controls, natural alternate actions, and contextual result states. |
| Is the UI modern, easy to use, easy to navigate, and visually appealing for the target personas? | llm-vision-holistic | 66 |  | Vary layouts by workflow type: event detail pages, book nomination forms, announcement composers, donation receipts, volunteer shift signup, export package review, and inbox/detail screens should each have task-specific IA and content hierarchy. |
| Is the experience community/product-centered rather than framework-centered? | llm-vision-holistic | 62 |  | Audit every screen row for framework-centered language and replace it with community-specific nouns, details, relationships, and outcomes. |
| Do primary workflow/persona screens show domain-native product surfaces and complete interaction models? | llm-vision-holistic | 55 |  | For every primary workflow/persona pair, build the actual task surface rather than a generic decision template, then recapture screenshots and rerun B25. |

### Likely Files / Widgets
- `app/apps/loom_communities_demo/lib/main.dart`
- `app/apps/loom_communities_demo/test/b21_b25_production_ux_test.dart`
- `docs/Build Plan V2/Evidence/B25/production-ux-blueprint.md`
- `docs/Build Plan V2/Evidence/B25/independent-production-ux-review.json`
- `docs/Build Plan V2/Evidence/B25/product-ux-screen-review-matrix.md`
- `app/apps/loom_communities_demo/integration_test/workflow_ui_evidence_test.dart`
- `app/apps/loom_communities_demo/test/workflow_ui_test_harness.dart`

### Concrete Acceptance Criteria
- Holistic direct-question answers are present, screenshot-backed, non-boilerplate, and pass.
- `production_ux_judge.dart` has no blocking failure for this criterion.
- `b25_iteration_scorecard.dart` records the ticket as resolved or no longer blocking.
- Screenshots are refreshed and hashes/timestamps/app commit SHA match the reviewed app version.
- Screen row `b25-v4-row-008-garden-export-custom-schemas-1` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-008-garden-export-custom-schemas-1` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-008-garden-export-custom-schemas-1` names visible UI elements, visible text, persona `owner`, workflow `garden-export-custom-schemas`, and the exact product UX issue.
- Primary surface for `garden-export-custom-schemas` is documented as `export/import wizard with preview, redaction, checksum, transfer status, and rollback state` or another explicit domain-native surface.
- After-screenshot visible text proves every required semantic surface group for `garden-export-custom-schemas`.
- Fresh screenshot path/hash/timestamp/app commit SHA are recorded after the fix.
- Screen row `b25-v4-row-011-book-nomination-1` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-011-book-nomination-1` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-011-book-nomination-1` names visible UI elements, visible text, persona `member`, workflow `book-nomination`, and the exact product UX issue.
- Primary surface for `book-nomination` is documented as `book club reading/voting surface with nominations, vote state, selected book, meeting context, and discussion` or another explicit domain-native surface.
- After-screenshot visible text proves every required semantic surface group for `book-nomination`.
- Screen row `b25-v4-row-014-book-vote-1` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-014-book-vote-1` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-014-book-vote-1` names visible UI elements, visible text, persona `member`, workflow `book-vote`, and the exact product UX issue.
- Primary surface for `book-vote` is documented as `book club reading/voting surface with nominations, vote state, selected book, meeting context, and discussion` or another explicit domain-native surface.
- After-screenshot visible text proves every required semantic surface group for `book-vote`.
- Screen row `b25-v4-row-017-book-meeting-rsvp-1` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-017-book-meeting-rsvp-1` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-017-book-meeting-rsvp-1` names visible UI elements, visible text, persona `member`, workflow `book-meeting-rsvp`, and the exact product UX issue.
- Primary surface for `book-meeting-rsvp` is documented as `event detail with schedule, location, capacity/status, RSVP action, and result state` or another explicit domain-native surface.
- After-screenshot visible text proves every required semantic surface group for `book-meeting-rsvp`.
- Screen row `b25-v4-row-020-book-discussion-message-1` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-020-book-discussion-message-1` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-020-book-discussion-message-1` names visible UI elements, visible text, persona `member`, workflow `book-discussion-message`, and the exact product UX issue.
- Primary surface for `book-discussion-message` is documented as `inbox, message thread, connection card, invite, or block-state surface` or another explicit domain-native surface.
- After-screenshot visible text proves every required semantic surface group for `book-discussion-message`.
- Screen row `b25-v4-row-023-book-selection-publish-1` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-023-book-selection-publish-1` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-023-book-selection-publish-1` names visible UI elements, visible text, persona `owner`, workflow `book-selection-publish`, and the exact product UX issue.
- Primary surface for `book-selection-publish` is documented as `announcement feed/composer with audience, author, timestamp, body, and receiver state` or another explicit domain-native surface.
- After-screenshot visible text proves every required semantic surface group for `book-selection-publish`.
- Screen row `b25-v4-row-074-mosque-announcement-1` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-074-mosque-announcement-1` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-074-mosque-announcement-1` names visible UI elements, visible text, persona `owner`, workflow `mosque-announcement`, and the exact product UX issue.
- Primary surface for `mosque-announcement` is documented as `announcement feed/composer with audience, author, timestamp, body, and receiver state` or another explicit domain-native surface.
- After-screenshot visible text proves every required semantic surface group for `mosque-announcement`.
- Screen row `b25-v4-row-077-mosque-event-rsvp-1` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-077-mosque-event-rsvp-1` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-077-mosque-event-rsvp-1` names visible UI elements, visible text, persona `member`, workflow `mosque-event-rsvp`, and the exact product UX issue.
- Primary surface for `mosque-event-rsvp` is documented as `event detail with schedule, location, capacity/status, RSVP action, and result state` or another explicit domain-native surface.
- After-screenshot visible text proves every required semantic surface group for `mosque-event-rsvp`.
- Screen row `b25-v4-row-080-mosque-volunteer-signup-1` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-080-mosque-volunteer-signup-1` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-080-mosque-volunteer-signup-1` names visible UI elements, visible text, persona `member`, workflow `mosque-volunteer-signup`, and the exact product UX issue.
- Primary surface for `mosque-volunteer-signup` is documented as `volunteer signup surface with role, time, protected contact fields, and confirmation` or another explicit domain-native surface.
- After-screenshot visible text proves every required semantic surface group for `mosque-volunteer-signup`.

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
| Review run | `b25-v4-pass-16` |
| Source criterion | `b25-c14-llm-vision-ux-review` |
| Source findings | LLM-B25-P16-001, LLM-B25-P16-002, LLM-B25-P16-003 |
| Title | LLM vision UX judge has inspected screenshots semantically |
| Direct question | Has a fresh LLM vision UX Judge inspected the actual screenshots as product UI, answered direct UX questions from visible evidence, and found no blocker or major product-quality issues? |
| Why it failed | The LLM vision UX review failed from screenshot inspection. blockingFindings=LLM-B25-P16-001, LLM-B25-P16-002, LLM-B25-P16-003 blockingQuestions=llm-holistic-production-grade, llm-holistic-modern-easy-navigation, llm-holistic-community-centered, llm-primary-workflow-surfaces blockingScreens=b25-v4-row-008-garden-export-custom-schemas-1, b25-v4-row-011-book-nomination-1, b25-v4-row-017-book-meeting-rsvp-1, b25-v4-row-074-mosque-announcement-1, b25-v4-row-080-mosque-volunteer-signup-1. |
| Required outcome | Run the B25 LLM Vision UX Judge Agent on the screenshot evidence, import its structured review, fix all blocker/major findings, and rerun B25. |
| Remediation mode | `review-only` |
| Worker readiness | no concrete implementation work item was generated; planner must inspect the direct-question failure before assigning a worker |
| First required step | Review failing direct questions and add screen/workflow/persona-specific evidence before implementation. |

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
| Selection and voting pattern | Material chips/cards/buttons / pattern | https://m3.material.io/components/chips/overview<br>Also: https://m3.material.io/components/cards/overview | Copy a nomination/voting surface with choices, current vote state, deadline, selected result, and meeting/discussion context. |
| Event detail and RSVP flow | Material cards/lists/buttons / pattern | https://m3.material.io/components/cards/overview<br>Also: https://m3.material.io/components/buttons/overview<br>https://m3.material.io/components/chips/overview | Copy an event detail layout: title, date/time, location, host, capacity/status chip, attendee context, RSVP action, and confirmation state. |
| Inbox and message thread pattern | Material lists/text fields / pattern | https://m3.material.io/components/lists/overview<br>Also: https://m3.material.io/components/text-fields/overview | Copy an inbox/thread structure: sender, timestamp, message preview/body, reply field, invite/block state, and read/received state. |
| Feed item and composer pattern | Material cards/lists/text fields / pattern | https://m3.material.io/components/text-fields/overview<br>Also: https://m3.material.io/components/cards/overview<br>https://m3.material.io/components/lists/overview | Copy a feed/composer structure: audience, author, timestamp, body, attachments/status, publish action, and receiver read state. |
| Form validation and review pattern | U.S. Web Design System / design-system | https://designsystem.digital.gov/components/form/<br>Also: https://designsystem.digital.gov/components/alert/<br>https://design-system.service.gov.uk/components/error-summary/ | Copy a form flow with field labels, helper text, validation errors, review state, submit action, status, and protected-data treatment. |

### Reference Research Queries
- production mobile UX review screenshot critique examples
- open source Flutter mobile app UX patterns GitHub
- open source Flutter export-wizard mobile UI example GitHub
- export/import wizard with preview, redaction, checksum, transfer status, and rollback state mobile UX pattern
- Material Design export/import wizard with preview, redaction, checksum, transfer status, and rollback state mobile pattern
- open source Flutter voting-selection mobile UI example GitHub
- book club reading/voting surface with nominations, vote state, selected book, meeting context, and discussion mobile UX pattern
- Material Design book club reading/voting surface with nominations, vote state, selected book, meeting context, and discussion mobile pattern
- open source Flutter event-rsvp mobile UI example GitHub
- event detail with schedule, location, capacity/status, RSVP action, and result state mobile UX pattern
- Material Design event detail with schedule, location, capacity/status, RSVP action, and result state mobile pattern
- open source Flutter message-thread mobile UI example GitHub
- inbox, message thread, connection card, invite, or block-state surface mobile UX pattern
- Material Design inbox, message thread, connection card, invite, or block-state surface mobile pattern
- open source Flutter announcement-feed mobile UI example GitHub
- announcement feed/composer with audience, author, timestamp, body, and receiver state mobile UX pattern
- Material Design announcement feed/composer with audience, author, timestamp, body, and receiver state mobile pattern
- open source Flutter form-review mobile UI example GitHub
- volunteer signup surface with role, time, protected contact fields, and confirmation mobile UX pattern
- Material Design volunteer signup surface with role, time, protected contact fields, and confirmation mobile pattern

### Implementation Blocked By
- The ticket lacks row-level implementation evidence.

### Affected Screen Rows

Showing 9 of 9 affected screen rows. Full detail is in the JSON ticket.

| Screen row | Community | Workflow | Persona | State | Screenshot | Hash | Visible text | Current surface | Exact UX failure | Target surface |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `b25-v4-row-008-garden-export-custom-schemas-1` | Garden Club | `garden-export-custom-schemas` | owner | B13_ext_garden_club_garden-export-custom-schemas_action | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B13/screenshots/B13_ext_garden_club_garden-export-custom-schemas_action.png` | `1105b28624553...` | Prepare export handoff \| Use this surface to package export scope, redaction, and handoff status. \| Redacted copy \| Checksum ready \| Exportable \| Decision \| Decide the scope, redaction, checksum, destination, and whether to retry, roll back, or change scope. \| Details \| Data s... | domain-native-reviewed / domain-native | LLM vision critique: This remains a generic workflow/action template. Even if export is a supporting/admin flow, the surface is not production-grade because it exposes implementation taxonomy. LLM required fix: Redesign as an export package review screen with file/package identity, included data types, redaction summary, checksum, destination, audit trail, rollback/change-scope controls, and final generate/download action. Current row verdict is `fail` with severity `major`. | export/import wizard with preview, redaction, checksum, transfer status, and rollback state |
| `b25-v4-row-011-book-nomination-1` | Neighborhood Book Club | `book-nomination` | member | B14_ext_book_club_book-nomination_action | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_book_club_book-nomination_action.png` | `d971530b07e27...` | Submit member form \| Use this surface to submit structured member details. \| Labeled fields \| Privacy checked \| Review handoff \| Decision \| Decide what to save, what to change, and what status or next step should remain visible afterward. \| Details \| Required details are ready... | domain-native-reviewed / domain-native | LLM vision critique: This is not a book nomination product surface. It does not show a title, author, member rationale, genre, meeting context, voting/nomination state, or a natural review/submit form. LLM required fix: Replace with a real book nomination form/review screen including book title, author, reason for nomination, meeting cycle, visibility/privacy settings if needed, edit/cancel, and submit nomination result. Current row verdict is `fail` with severity `blocker`. | book club reading/voting surface with nominations, vote state, selected book, meeting context, and discussion |
| `b25-v4-row-014-book-vote-1` | Neighborhood Book Club | `book-vote` | member | B14_ext_book_club_book-vote_action | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_book_club_book-vote_action.png` | `7b2761d92193b...` | Submit member form \| Use this surface to submit structured member details. \| Labeled fields \| Privacy checked \| Review handoff \| Decision \| Decide what to save, what to change, and what status or next step should remain visible afterward. \| Details \| Required details are ready... | domain-native-reviewed / domain-native | No row-specific failure recorded. | book club reading/voting surface with nominations, vote state, selected book, meeting context, and discussion |
| `b25-v4-row-017-book-meeting-rsvp-1` | Neighborhood Book Club | `book-meeting-rsvp` | member | B14_ext_book_club_book-meeting-rsvp_action | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_book_club_book-meeting-rsvp_action.png` | `2e978d0902300...` | Coordinate attendance \| Use this surface to publish event details, capacity, and attendance state. \| This week \| Community venue \| Capacity tracked \| RSVP available \| Decision \| Decide if you are going, maybe, or not attending after checking date, time, location, and capacity.... | domain-native-reviewed / domain-native | LLM vision critique: Unlike the improved Garden RSVP, this event screen remains a template. It does not feel like a book club meeting page because it lacks the book, venue, time, discussion host, attendee state, and concrete RSVP controls. LLM required fix: Create a book meeting RSVP detail screen with meeting title, selected book, date/time, venue, host, capacity, current RSVP, attendee/reminder state, and natural RSVP/change-response controls. Current row verdict is `fail` with severity `major`. | event detail with schedule, location, capacity/status, RSVP action, and result state |
| `b25-v4-row-020-book-discussion-message-1` | Neighborhood Book Club | `book-discussion-message` | member | B14_ext_book_club_book-discussion-message_action | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_book_club_book-discussion-message_action.png` | `b7942f903d0d1...` | Update member channel \| Use this surface to change a member communication or relationship setting. \| Private by default \| Membership scoped \| Ready \| Decision \| Decide whether to reply, send, accept, decline, mute, archive, or block this member communication. \| Details \| Membe... | domain-native-reviewed / domain-native | No row-specific failure recorded. | inbox, message thread, connection card, invite, or block-state surface |
| `b25-v4-row-023-book-selection-publish-1` | Neighborhood Book Club | `book-selection-publish` | owner | B14_ext_book_club_book-selection-publish_action | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_book_club_book-selection-publish_action.png` | `48516b6175aef...` | Send community notice \| Use this surface to send a scoped announcement to the selected audience. \| Members \| Today \| From admin \| Inbox + push \| Decision \| Decide whether this message is ready for members, who receives it, and whether to preview or save a draft first. \| Detail... | domain-native-reviewed / domain-native | No row-specific failure recorded. | announcement feed/composer with audience, author, timestamp, body, and receiver state |
| `b25-v4-row-074-mosque-announcement-1` | Masjid Nur | `mosque-announcement` | owner | B14_ext_mosque_mosque-announcement_action | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_mosque_mosque-announcement_action.png` | `4f9beca474852...` | Send community notice \| Use this surface to send a scoped announcement to the selected audience. \| Members \| Today \| From admin \| Inbox + push \| Decision \| Decide whether this message is ready for members, who receives it, and whether to preview or save a draft first. \| Detail... | domain-native-reviewed / domain-native | LLM vision critique: This is not yet a production announcement authoring or preview experience. It documents that an announcement can be sent, but does not look like a real admin composing and publishing a message to members. LLM required fix: Replace with a true announcement composer/review screen including subject, body, audience, schedule/channel, preview, save draft, publish, and sent/receiver state. Current row verdict is `fail` with severity `major`. | announcement feed/composer with audience, author, timestamp, body, and receiver state |
| `b25-v4-row-077-mosque-event-rsvp-1` | Masjid Nur | `mosque-event-rsvp` | member | B14_ext_mosque_mosque-event-rsvp_action | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_mosque_mosque-event-rsvp_action.png` | `2e978d0902300...` | Coordinate attendance \| Use this surface to publish event details, capacity, and attendance state. \| This week \| Community venue \| Capacity tracked \| RSVP available \| Decision \| Decide if you are going, maybe, or not attending after checking date, time, location, and capacity.... | domain-native-reviewed / domain-native | No row-specific failure recorded. | event detail with schedule, location, capacity/status, RSVP action, and result state |
| `b25-v4-row-080-mosque-volunteer-signup-1` | Masjid Nur | `mosque-volunteer-signup` | member | B14_ext_mosque_mosque-volunteer-signup_action | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_mosque_mosque-volunteer-signup_action.png` | `295f52a21ab9b...` | Submit member form \| Use this surface to submit structured member details. \| Open shift \| Contact protected \| Coordinator notified \| Decision \| Decide what to save, what to change, and what status or next step should remain visible afterward. \| Details \| Required details are r... | domain-native-reviewed / domain-native | LLM vision critique: This does not feel like a volunteer signup flow. A member should see a specific shift, time, role, requirements, contact preference, confirmation, and coordinator follow-up. LLM required fix: Build a volunteer shift signup surface with shift details, time/location, role requirements, contact/privacy controls, cancel/change option, signup confirmation, and coordinator receiver state. Current row verdict is `fail` with severity `major`. | volunteer signup surface with role, time, protected contact fields, and confirmation |

### Failing Direct Questions

| Question | Scope | Score | Why | Required fix |
| --- | --- | ---: | --- | --- |
| Does the whole experience feel like a real production community app, not merely an implemented workflow harness? | llm-vision-holistic | 58 |  | Replace all remaining generic action templates with domain-native product screens for each community workflow, with real object details, task-specific controls, natural alternate actions, and contextual result states. |
| Is the UI modern, easy to use, easy to navigate, and visually appealing for the target personas? | llm-vision-holistic | 66 |  | Vary layouts by workflow type: event detail pages, book nomination forms, announcement composers, donation receipts, volunteer shift signup, export package review, and inbox/detail screens should each have task-specific IA and content hierarchy. |
| Is the experience community/product-centered rather than framework-centered? | llm-vision-holistic | 62 |  | Audit every screen row for framework-centered language and replace it with community-specific nouns, details, relationships, and outcomes. |
| Do primary workflow/persona screens show domain-native product surfaces and complete interaction models? | llm-vision-holistic | 55 |  | For every primary workflow/persona pair, build the actual task surface rather than a generic decision template, then recapture screenshots and rerun B25. |

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
- Screen row `b25-v4-row-008-garden-export-custom-schemas-1` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-008-garden-export-custom-schemas-1` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-008-garden-export-custom-schemas-1` names visible UI elements, visible text, persona `owner`, workflow `garden-export-custom-schemas`, and the exact product UX issue.
- Primary surface for `garden-export-custom-schemas` is documented as `export/import wizard with preview, redaction, checksum, transfer status, and rollback state` or another explicit domain-native surface.
- After-screenshot visible text proves every required semantic surface group for `garden-export-custom-schemas`.
- Fresh screenshot path/hash/timestamp/app commit SHA are recorded after the fix.
- Screen row `b25-v4-row-011-book-nomination-1` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-011-book-nomination-1` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-011-book-nomination-1` names visible UI elements, visible text, persona `member`, workflow `book-nomination`, and the exact product UX issue.
- Primary surface for `book-nomination` is documented as `book club reading/voting surface with nominations, vote state, selected book, meeting context, and discussion` or another explicit domain-native surface.
- After-screenshot visible text proves every required semantic surface group for `book-nomination`.
- Screen row `b25-v4-row-014-book-vote-1` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-014-book-vote-1` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-014-book-vote-1` names visible UI elements, visible text, persona `member`, workflow `book-vote`, and the exact product UX issue.
- Primary surface for `book-vote` is documented as `book club reading/voting surface with nominations, vote state, selected book, meeting context, and discussion` or another explicit domain-native surface.
- After-screenshot visible text proves every required semantic surface group for `book-vote`.
- Screen row `b25-v4-row-017-book-meeting-rsvp-1` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-017-book-meeting-rsvp-1` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-017-book-meeting-rsvp-1` names visible UI elements, visible text, persona `member`, workflow `book-meeting-rsvp`, and the exact product UX issue.
- Primary surface for `book-meeting-rsvp` is documented as `event detail with schedule, location, capacity/status, RSVP action, and result state` or another explicit domain-native surface.
- After-screenshot visible text proves every required semantic surface group for `book-meeting-rsvp`.
- Screen row `b25-v4-row-020-book-discussion-message-1` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-020-book-discussion-message-1` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-020-book-discussion-message-1` names visible UI elements, visible text, persona `member`, workflow `book-discussion-message`, and the exact product UX issue.
- Primary surface for `book-discussion-message` is documented as `inbox, message thread, connection card, invite, or block-state surface` or another explicit domain-native surface.
- After-screenshot visible text proves every required semantic surface group for `book-discussion-message`.
- Screen row `b25-v4-row-023-book-selection-publish-1` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-023-book-selection-publish-1` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-023-book-selection-publish-1` names visible UI elements, visible text, persona `owner`, workflow `book-selection-publish`, and the exact product UX issue.
- Primary surface for `book-selection-publish` is documented as `announcement feed/composer with audience, author, timestamp, body, and receiver state` or another explicit domain-native surface.
- After-screenshot visible text proves every required semantic surface group for `book-selection-publish`.
- Screen row `b25-v4-row-074-mosque-announcement-1` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-074-mosque-announcement-1` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-074-mosque-announcement-1` names visible UI elements, visible text, persona `owner`, workflow `mosque-announcement`, and the exact product UX issue.
- Primary surface for `mosque-announcement` is documented as `announcement feed/composer with audience, author, timestamp, body, and receiver state` or another explicit domain-native surface.
- After-screenshot visible text proves every required semantic surface group for `mosque-announcement`.
- Screen row `b25-v4-row-077-mosque-event-rsvp-1` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-077-mosque-event-rsvp-1` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-077-mosque-event-rsvp-1` names visible UI elements, visible text, persona `member`, workflow `mosque-event-rsvp`, and the exact product UX issue.
- Primary surface for `mosque-event-rsvp` is documented as `event detail with schedule, location, capacity/status, RSVP action, and result state` or another explicit domain-native surface.
- After-screenshot visible text proves every required semantic surface group for `mosque-event-rsvp`.
- Screen row `b25-v4-row-080-mosque-volunteer-signup-1` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-080-mosque-volunteer-signup-1` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-080-mosque-volunteer-signup-1` names visible UI elements, visible text, persona `member`, workflow `mosque-volunteer-signup`, and the exact product UX issue.
- Primary surface for `mosque-volunteer-signup` is documented as `volunteer signup surface with role, time, protected contact fields, and confirmation` or another explicit domain-native surface.
- After-screenshot visible text proves every required semantic surface group for `mosque-volunteer-signup`.

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
| Review run | `b25-v4-pass-16` |
| Source criterion | `b25-c04-modern-intentional-ui` |
| Source findings | LLM-B25-P16-001, LLM-B25-P16-002, LLM-B25-P16-003 |
| Title | UI looks modern and intentionally designed |
| Direct question | Is the UI modern, easy to use, easy to navigate, and visually appealing for the target persona? |
| Why it failed | holistic direct-question answers are missing, weak, partial, or blocking: llm-holistic-production-grade, llm-holistic-modern-easy-navigation, llm-holistic-community-centered, llm-primary-workflow-surfaces. |
| Required outcome | Remediate visual hierarchy, spacing, typography, component quality, and recapture screenshots. |
| Remediation mode | `ui-remediation-ready` |
| Worker readiness | ready for worker implementation using the uiRemediationWorkItems |
| First required step | Implement the target production surfaces and content specified in uiRemediationWorkItems, then recapture screenshots. |

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
| Task list and export wizard | GOV.UK Design System / design-system | https://design-system.service.gov.uk/components/task-list/<br>Also: https://design-system.service.gov.uk/patterns/check-answers/ | Copy a wizard with steps, preview, redaction choices, checksum evidence, transfer status, and rollback confirmation. |
| Selection and voting pattern | Material chips/cards/buttons / pattern | https://m3.material.io/components/chips/overview<br>Also: https://m3.material.io/components/cards/overview | Copy a nomination/voting surface with choices, current vote state, deadline, selected result, and meeting/discussion context. |
| Event detail and RSVP flow | Material cards/lists/buttons / pattern | https://m3.material.io/components/cards/overview<br>Also: https://m3.material.io/components/buttons/overview<br>https://m3.material.io/components/chips/overview | Copy an event detail layout: title, date/time, location, host, capacity/status chip, attendee context, RSVP action, and confirmation state. |
| Inbox and message thread pattern | Material lists/text fields / pattern | https://m3.material.io/components/lists/overview<br>Also: https://m3.material.io/components/text-fields/overview | Copy an inbox/thread structure: sender, timestamp, message preview/body, reply field, invite/block state, and read/received state. |
| Feed item and composer pattern | Material cards/lists/text fields / pattern | https://m3.material.io/components/text-fields/overview<br>Also: https://m3.material.io/components/cards/overview<br>https://m3.material.io/components/lists/overview | Copy a feed/composer structure: audience, author, timestamp, body, attachments/status, publish action, and receiver read state. |
| Form validation and review pattern | U.S. Web Design System / design-system | https://designsystem.digital.gov/components/form/<br>Also: https://designsystem.digital.gov/components/alert/<br>https://design-system.service.gov.uk/components/error-summary/ | Copy a form flow with field labels, helper text, validation errors, review state, submit action, status, and protected-data treatment. |

### Reference Research Queries
- modern mobile app information architecture visual hierarchy examples
- Material Design 3 mobile UI hierarchy navigation cards examples
- open source Flutter production app dashboard detail screen examples
- open source Flutter export-wizard mobile UI example GitHub
- export/import wizard with preview, redaction, checksum, transfer status, and rollback state mobile UX pattern
- Material Design export/import wizard with preview, redaction, checksum, transfer status, and rollback state mobile pattern
- open source Flutter voting-selection mobile UI example GitHub
- book club reading/voting surface with nominations, vote state, selected book, meeting context, and discussion mobile UX pattern
- Material Design book club reading/voting surface with nominations, vote state, selected book, meeting context, and discussion mobile pattern
- open source Flutter event-rsvp mobile UI example GitHub
- event detail with schedule, location, capacity/status, RSVP action, and result state mobile UX pattern
- Material Design event detail with schedule, location, capacity/status, RSVP action, and result state mobile pattern
- open source Flutter message-thread mobile UI example GitHub
- inbox, message thread, connection card, invite, or block-state surface mobile UX pattern
- Material Design inbox, message thread, connection card, invite, or block-state surface mobile pattern
- open source Flutter announcement-feed mobile UI example GitHub
- announcement feed/composer with audience, author, timestamp, body, and receiver state mobile UX pattern
- Material Design announcement feed/composer with audience, author, timestamp, body, and receiver state mobile pattern
- open source Flutter form-review mobile UI example GitHub
- volunteer signup surface with role, time, protected contact fields, and confirmation mobile UX pattern

### UI Remediation Work Items

Showing 9 of 9 work items. Full detail is in the JSON artifact.

| Work item | Stage | Community | Workflow | Persona | Screens | Coverage | Target surface | Blocked until |
| --- | --- | --- | --- | --- | ---: | ---: | --- | --- |
| `b25-wi-ui-remediation-community-garden-club-garden-export-custom-schemas-community-garden-club-owner` | `ui-remediation` | Garden Club | `garden-export-custom-schemas` | owner | 1 | 0 | export/import wizard with preview, redaction, checksum, transfer status, and rollback state | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-book-club-book-nomination-community-book-club-member` | `ui-remediation` | Neighborhood Book Club | `book-nomination` | member | 1 | 0 | book club reading/voting surface with nominations, vote state, selected book, meeting context, and discussion | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-book-club-book-vote-community-book-club-member` | `ui-remediation` | Neighborhood Book Club | `book-vote` | member | 1 | 0 | book club reading/voting surface with nominations, vote state, selected book, meeting context, and discussion | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-book-club-book-meeting-rsvp-community-book-club-member` | `ui-remediation` | Neighborhood Book Club | `book-meeting-rsvp` | member | 1 | 0 | event detail with schedule, location, capacity/status, RSVP action, and result state | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-book-club-book-discussion-message-community-book-club-member` | `ui-remediation` | Neighborhood Book Club | `book-discussion-message` | member | 1 | 0 | inbox, message thread, connection card, invite, or block-state surface | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-book-club-book-selection-publish-community-book-club-owner` | `ui-remediation` | Neighborhood Book Club | `book-selection-publish` | owner | 1 | 0 | announcement feed/composer with audience, author, timestamp, body, and receiver state | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-mosque-mosque-announcement-community-mosque-owner` | `ui-remediation` | Masjid Nur | `mosque-announcement` | owner | 1 | 0 | announcement feed/composer with audience, author, timestamp, body, and receiver state | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-mosque-mosque-event-rsvp-community-mosque-member` | `ui-remediation` | Masjid Nur | `mosque-event-rsvp` | member | 1 | 0 | event detail with schedule, location, capacity/status, RSVP action, and result state | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-mosque-mosque-volunteer-signup-community-mosque-member` | `ui-remediation` | Masjid Nur | `mosque-volunteer-signup` | member | 1 | 0 | volunteer signup surface with role, time, protected contact fields, and confirmation | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |

### UI Remediation Work Items Reference Patterns

| Reference | Source | URL | What to copy |
| --- | --- | --- | --- |
| Task list and export wizard | GOV.UK Design System / design-system | https://design-system.service.gov.uk/components/task-list/<br>Also: https://design-system.service.gov.uk/patterns/check-answers/ | Copy a wizard with steps, preview, redaction choices, checksum evidence, transfer status, and rollback confirmation. |
| Material Design cards and lists | Material Design 3 / design-system | https://m3.material.io/components/cards/overview<br>Also: https://m3.material.io/components/lists/overview | Use cards/lists only as scannable containers with clear hierarchy, content, metadata, and actions. Do not use repeated cards as the whole primary workflow. |
| Flutter sample app implementation patterns | flutter/samples / open-source | https://github.com/flutter/samples | Copy the separation between app shell, route state, domain widgets, and testable UI states rather than hardcoding a single generic renderer. |
| Material navigation and information architecture | Material Design 3 / design-system | https://m3.material.io/components/navigation-drawer/overview<br>Also: https://m3.material.io/components/navigation-bar/overview | Organize screens by user jobs and destinations; keep primary actions visible and avoid exposing implementation taxonomy. |
| Apple HIG navigation and content organization | Apple Human Interface Guidelines / design-system | https://developer.apple.com/design/human-interface-guidelines/navigation | Make navigation predictable, content-centered, and appropriate for the user’s current task. |
| Selection and voting pattern | Material chips/cards/buttons / pattern | https://m3.material.io/components/chips/overview<br>Also: https://m3.material.io/components/cards/overview | Copy a nomination/voting surface with choices, current vote state, deadline, selected result, and meeting/discussion context. |
| Event detail and RSVP flow | Material cards/lists/buttons / pattern | https://m3.material.io/components/cards/overview<br>Also: https://m3.material.io/components/buttons/overview<br>https://m3.material.io/components/chips/overview | Copy an event detail layout: title, date/time, location, host, capacity/status chip, attendee context, RSVP action, and confirmation state. |
| Inbox and message thread pattern | Material lists/text fields / pattern | https://m3.material.io/components/lists/overview<br>Also: https://m3.material.io/components/text-fields/overview | Copy an inbox/thread structure: sender, timestamp, message preview/body, reply field, invite/block state, and read/received state. |
| Feed item and composer pattern | Material cards/lists/text fields / pattern | https://m3.material.io/components/text-fields/overview<br>Also: https://m3.material.io/components/cards/overview<br>https://m3.material.io/components/lists/overview | Copy a feed/composer structure: audience, author, timestamp, body, attachments/status, publish action, and receiver read state. |
| Form validation and review pattern | U.S. Web Design System / design-system | https://designsystem.digital.gov/components/form/<br>Also: https://designsystem.digital.gov/components/alert/<br>https://design-system.service.gov.uk/components/error-summary/ | Copy a form flow with field labels, helper text, validation errors, review state, submit action, status, and protected-data treatment. |

### Affected Screen Rows

Showing 9 of 9 affected screen rows. Full detail is in the JSON ticket.

| Screen row | Community | Workflow | Persona | State | Screenshot | Hash | Visible text | Current surface | Exact UX failure | Target surface |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `b25-v4-row-008-garden-export-custom-schemas-1` | Garden Club | `garden-export-custom-schemas` | owner | B13_ext_garden_club_garden-export-custom-schemas_action | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B13/screenshots/B13_ext_garden_club_garden-export-custom-schemas_action.png` | `1105b28624553...` | Prepare export handoff \| Use this surface to package export scope, redaction, and handoff status. \| Redacted copy \| Checksum ready \| Exportable \| Decision \| Decide the scope, redaction, checksum, destination, and whether to retry, roll back, or change scope. \| Details \| Data s... | domain-native-reviewed / domain-native | LLM vision critique: This remains a generic workflow/action template. Even if export is a supporting/admin flow, the surface is not production-grade because it exposes implementation taxonomy. LLM required fix: Redesign as an export package review screen with file/package identity, included data types, redaction summary, checksum, destination, audit trail, rollback/change-scope controls, and final generate/download action. Current row verdict is `fail` with severity `major`. | export/import wizard with preview, redaction, checksum, transfer status, and rollback state |
| `b25-v4-row-011-book-nomination-1` | Neighborhood Book Club | `book-nomination` | member | B14_ext_book_club_book-nomination_action | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_book_club_book-nomination_action.png` | `d971530b07e27...` | Submit member form \| Use this surface to submit structured member details. \| Labeled fields \| Privacy checked \| Review handoff \| Decision \| Decide what to save, what to change, and what status or next step should remain visible afterward. \| Details \| Required details are ready... | domain-native-reviewed / domain-native | LLM vision critique: This is not a book nomination product surface. It does not show a title, author, member rationale, genre, meeting context, voting/nomination state, or a natural review/submit form. LLM required fix: Replace with a real book nomination form/review screen including book title, author, reason for nomination, meeting cycle, visibility/privacy settings if needed, edit/cancel, and submit nomination result. Current row verdict is `fail` with severity `blocker`. | book club reading/voting surface with nominations, vote state, selected book, meeting context, and discussion |
| `b25-v4-row-014-book-vote-1` | Neighborhood Book Club | `book-vote` | member | B14_ext_book_club_book-vote_action | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_book_club_book-vote_action.png` | `7b2761d92193b...` | Submit member form \| Use this surface to submit structured member details. \| Labeled fields \| Privacy checked \| Review handoff \| Decision \| Decide what to save, what to change, and what status or next step should remain visible afterward. \| Details \| Required details are ready... | domain-native-reviewed / domain-native | No row-specific failure recorded. | book club reading/voting surface with nominations, vote state, selected book, meeting context, and discussion |
| `b25-v4-row-017-book-meeting-rsvp-1` | Neighborhood Book Club | `book-meeting-rsvp` | member | B14_ext_book_club_book-meeting-rsvp_action | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_book_club_book-meeting-rsvp_action.png` | `2e978d0902300...` | Coordinate attendance \| Use this surface to publish event details, capacity, and attendance state. \| This week \| Community venue \| Capacity tracked \| RSVP available \| Decision \| Decide if you are going, maybe, or not attending after checking date, time, location, and capacity.... | domain-native-reviewed / domain-native | LLM vision critique: Unlike the improved Garden RSVP, this event screen remains a template. It does not feel like a book club meeting page because it lacks the book, venue, time, discussion host, attendee state, and concrete RSVP controls. LLM required fix: Create a book meeting RSVP detail screen with meeting title, selected book, date/time, venue, host, capacity, current RSVP, attendee/reminder state, and natural RSVP/change-response controls. Current row verdict is `fail` with severity `major`. | event detail with schedule, location, capacity/status, RSVP action, and result state |
| `b25-v4-row-020-book-discussion-message-1` | Neighborhood Book Club | `book-discussion-message` | member | B14_ext_book_club_book-discussion-message_action | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_book_club_book-discussion-message_action.png` | `b7942f903d0d1...` | Update member channel \| Use this surface to change a member communication or relationship setting. \| Private by default \| Membership scoped \| Ready \| Decision \| Decide whether to reply, send, accept, decline, mute, archive, or block this member communication. \| Details \| Membe... | domain-native-reviewed / domain-native | No row-specific failure recorded. | inbox, message thread, connection card, invite, or block-state surface |
| `b25-v4-row-023-book-selection-publish-1` | Neighborhood Book Club | `book-selection-publish` | owner | B14_ext_book_club_book-selection-publish_action | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_book_club_book-selection-publish_action.png` | `48516b6175aef...` | Send community notice \| Use this surface to send a scoped announcement to the selected audience. \| Members \| Today \| From admin \| Inbox + push \| Decision \| Decide whether this message is ready for members, who receives it, and whether to preview or save a draft first. \| Detail... | domain-native-reviewed / domain-native | No row-specific failure recorded. | announcement feed/composer with audience, author, timestamp, body, and receiver state |
| `b25-v4-row-074-mosque-announcement-1` | Masjid Nur | `mosque-announcement` | owner | B14_ext_mosque_mosque-announcement_action | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_mosque_mosque-announcement_action.png` | `4f9beca474852...` | Send community notice \| Use this surface to send a scoped announcement to the selected audience. \| Members \| Today \| From admin \| Inbox + push \| Decision \| Decide whether this message is ready for members, who receives it, and whether to preview or save a draft first. \| Detail... | domain-native-reviewed / domain-native | LLM vision critique: This is not yet a production announcement authoring or preview experience. It documents that an announcement can be sent, but does not look like a real admin composing and publishing a message to members. LLM required fix: Replace with a true announcement composer/review screen including subject, body, audience, schedule/channel, preview, save draft, publish, and sent/receiver state. Current row verdict is `fail` with severity `major`. | announcement feed/composer with audience, author, timestamp, body, and receiver state |
| `b25-v4-row-077-mosque-event-rsvp-1` | Masjid Nur | `mosque-event-rsvp` | member | B14_ext_mosque_mosque-event-rsvp_action | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_mosque_mosque-event-rsvp_action.png` | `2e978d0902300...` | Coordinate attendance \| Use this surface to publish event details, capacity, and attendance state. \| This week \| Community venue \| Capacity tracked \| RSVP available \| Decision \| Decide if you are going, maybe, or not attending after checking date, time, location, and capacity.... | domain-native-reviewed / domain-native | No row-specific failure recorded. | event detail with schedule, location, capacity/status, RSVP action, and result state |
| `b25-v4-row-080-mosque-volunteer-signup-1` | Masjid Nur | `mosque-volunteer-signup` | member | B14_ext_mosque_mosque-volunteer-signup_action | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_mosque_mosque-volunteer-signup_action.png` | `295f52a21ab9b...` | Submit member form \| Use this surface to submit structured member details. \| Open shift \| Contact protected \| Coordinator notified \| Decision \| Decide what to save, what to change, and what status or next step should remain visible afterward. \| Details \| Required details are r... | domain-native-reviewed / domain-native | LLM vision critique: This does not feel like a volunteer signup flow. A member should see a specific shift, time, role, requirements, contact preference, confirmation, and coordinator follow-up. LLM required fix: Build a volunteer shift signup surface with shift details, time/location, role requirements, contact/privacy controls, cancel/change option, signup confirmation, and coordinator receiver state. Current row verdict is `fail` with severity `major`. | volunteer signup surface with role, time, protected contact fields, and confirmation |

### Failing Direct Questions

| Question | Scope | Score | Why | Required fix |
| --- | --- | ---: | --- | --- |
| Does the whole experience feel like a real production community app, not merely an implemented workflow harness? | llm-vision-holistic | 58 |  | Replace all remaining generic action templates with domain-native product screens for each community workflow, with real object details, task-specific controls, natural alternate actions, and contextual result states. |
| Is the UI modern, easy to use, easy to navigate, and visually appealing for the target personas? | llm-vision-holistic | 66 |  | Vary layouts by workflow type: event detail pages, book nomination forms, announcement composers, donation receipts, volunteer shift signup, export package review, and inbox/detail screens should each have task-specific IA and content hierarchy. |
| Is the experience community/product-centered rather than framework-centered? | llm-vision-holistic | 62 |  | Audit every screen row for framework-centered language and replace it with community-specific nouns, details, relationships, and outcomes. |
| Do primary workflow/persona screens show domain-native product surfaces and complete interaction models? | llm-vision-holistic | 55 |  | For every primary workflow/persona pair, build the actual task surface rather than a generic decision template, then recapture screenshots and rerun B25. |

### Likely Files / Widgets
- `app/apps/loom_communities_demo/lib/main.dart`
- `app/apps/loom_communities_demo/test/b21_b25_production_ux_test.dart`
- `docs/Build Plan V2/Evidence/B25/production-ux-blueprint.md`
- `docs/Build Plan V2/Evidence/B25/independent-production-ux-review.json`
- `docs/Build Plan V2/Evidence/B25/product-ux-screen-review-matrix.md`
- `app/apps/loom_communities_demo/integration_test/workflow_ui_evidence_test.dart`
- `app/apps/loom_communities_demo/test/workflow_ui_test_harness.dart`

### Concrete Acceptance Criteria
- Holistic direct-question answers are present, screenshot-backed, non-boilerplate, and pass.
- `production_ux_judge.dart` has no blocking failure for this criterion.
- `b25_iteration_scorecard.dart` records the ticket as resolved or no longer blocking.
- Screenshots are refreshed and hashes/timestamps/app commit SHA match the reviewed app version.
- Screen row `b25-v4-row-008-garden-export-custom-schemas-1` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-008-garden-export-custom-schemas-1` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-008-garden-export-custom-schemas-1` names visible UI elements, visible text, persona `owner`, workflow `garden-export-custom-schemas`, and the exact product UX issue.
- Primary surface for `garden-export-custom-schemas` is documented as `export/import wizard with preview, redaction, checksum, transfer status, and rollback state` or another explicit domain-native surface.
- After-screenshot visible text proves every required semantic surface group for `garden-export-custom-schemas`.
- Fresh screenshot path/hash/timestamp/app commit SHA are recorded after the fix.
- Screen row `b25-v4-row-011-book-nomination-1` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-011-book-nomination-1` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-011-book-nomination-1` names visible UI elements, visible text, persona `member`, workflow `book-nomination`, and the exact product UX issue.
- Primary surface for `book-nomination` is documented as `book club reading/voting surface with nominations, vote state, selected book, meeting context, and discussion` or another explicit domain-native surface.
- After-screenshot visible text proves every required semantic surface group for `book-nomination`.
- Screen row `b25-v4-row-014-book-vote-1` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-014-book-vote-1` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-014-book-vote-1` names visible UI elements, visible text, persona `member`, workflow `book-vote`, and the exact product UX issue.
- Primary surface for `book-vote` is documented as `book club reading/voting surface with nominations, vote state, selected book, meeting context, and discussion` or another explicit domain-native surface.
- After-screenshot visible text proves every required semantic surface group for `book-vote`.
- Screen row `b25-v4-row-017-book-meeting-rsvp-1` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-017-book-meeting-rsvp-1` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-017-book-meeting-rsvp-1` names visible UI elements, visible text, persona `member`, workflow `book-meeting-rsvp`, and the exact product UX issue.
- Primary surface for `book-meeting-rsvp` is documented as `event detail with schedule, location, capacity/status, RSVP action, and result state` or another explicit domain-native surface.
- After-screenshot visible text proves every required semantic surface group for `book-meeting-rsvp`.
- Screen row `b25-v4-row-020-book-discussion-message-1` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-020-book-discussion-message-1` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-020-book-discussion-message-1` names visible UI elements, visible text, persona `member`, workflow `book-discussion-message`, and the exact product UX issue.
- Primary surface for `book-discussion-message` is documented as `inbox, message thread, connection card, invite, or block-state surface` or another explicit domain-native surface.
- After-screenshot visible text proves every required semantic surface group for `book-discussion-message`.
- Screen row `b25-v4-row-023-book-selection-publish-1` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-023-book-selection-publish-1` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-023-book-selection-publish-1` names visible UI elements, visible text, persona `owner`, workflow `book-selection-publish`, and the exact product UX issue.
- Primary surface for `book-selection-publish` is documented as `announcement feed/composer with audience, author, timestamp, body, and receiver state` or another explicit domain-native surface.
- After-screenshot visible text proves every required semantic surface group for `book-selection-publish`.
- Screen row `b25-v4-row-074-mosque-announcement-1` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-074-mosque-announcement-1` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-074-mosque-announcement-1` names visible UI elements, visible text, persona `owner`, workflow `mosque-announcement`, and the exact product UX issue.
- Primary surface for `mosque-announcement` is documented as `announcement feed/composer with audience, author, timestamp, body, and receiver state` or another explicit domain-native surface.
- After-screenshot visible text proves every required semantic surface group for `mosque-announcement`.
- Screen row `b25-v4-row-077-mosque-event-rsvp-1` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-077-mosque-event-rsvp-1` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-077-mosque-event-rsvp-1` names visible UI elements, visible text, persona `member`, workflow `mosque-event-rsvp`, and the exact product UX issue.
- Primary surface for `mosque-event-rsvp` is documented as `event detail with schedule, location, capacity/status, RSVP action, and result state` or another explicit domain-native surface.
- After-screenshot visible text proves every required semantic surface group for `mosque-event-rsvp`.
- Screen row `b25-v4-row-080-mosque-volunteer-signup-1` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-080-mosque-volunteer-signup-1` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-080-mosque-volunteer-signup-1` names visible UI elements, visible text, persona `member`, workflow `mosque-volunteer-signup`, and the exact product UX issue.
- Primary surface for `mosque-volunteer-signup` is documented as `volunteer signup surface with role, time, protected contact fields, and confirmation` or another explicit domain-native surface.
- After-screenshot visible text proves every required semantic surface group for `mosque-volunteer-signup`.

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
| Review run | `b25-v4-pass-16` |
| Source criterion | `b25-c05-community-content-ia` |
| Source findings | LLM-B25-P16-001, LLM-B25-P16-002, LLM-B25-P16-003 |
| Title | Screens are organized around community content and jobs-to-be-done |
| Direct question | Is the overall information architecture organized around community content and real jobs-to-be-done instead of workflow lists or validation surfaces? |
| Why it failed | holistic direct-question answers are missing, weak, partial, or blocking: llm-holistic-production-grade, llm-holistic-modern-easy-navigation, llm-holistic-community-centered, llm-primary-workflow-surfaces. |
| Required outcome | Rebuild home and primary screens around community content and user jobs. |
| Remediation mode | `ui-remediation-ready` |
| Worker readiness | ready for worker implementation using the uiRemediationWorkItems |
| First required step | Implement the target production surfaces and content specified in uiRemediationWorkItems, then recapture screenshots. |

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
| Task list and export wizard | GOV.UK Design System / design-system | https://design-system.service.gov.uk/components/task-list/<br>Also: https://design-system.service.gov.uk/patterns/check-answers/ | Copy a wizard with steps, preview, redaction choices, checksum evidence, transfer status, and rollback confirmation. |
| Selection and voting pattern | Material chips/cards/buttons / pattern | https://m3.material.io/components/chips/overview<br>Also: https://m3.material.io/components/cards/overview | Copy a nomination/voting surface with choices, current vote state, deadline, selected result, and meeting/discussion context. |
| Event detail and RSVP flow | Material cards/lists/buttons / pattern | https://m3.material.io/components/cards/overview<br>Also: https://m3.material.io/components/buttons/overview<br>https://m3.material.io/components/chips/overview | Copy an event detail layout: title, date/time, location, host, capacity/status chip, attendee context, RSVP action, and confirmation state. |
| Inbox and message thread pattern | Material lists/text fields / pattern | https://m3.material.io/components/lists/overview<br>Also: https://m3.material.io/components/text-fields/overview | Copy an inbox/thread structure: sender, timestamp, message preview/body, reply field, invite/block state, and read/received state. |
| Feed item and composer pattern | Material cards/lists/text fields / pattern | https://m3.material.io/components/text-fields/overview<br>Also: https://m3.material.io/components/cards/overview<br>https://m3.material.io/components/lists/overview | Copy a feed/composer structure: audience, author, timestamp, body, attachments/status, publish action, and receiver read state. |
| Form validation and review pattern | U.S. Web Design System / design-system | https://designsystem.digital.gov/components/form/<br>Also: https://designsystem.digital.gov/components/alert/<br>https://design-system.service.gov.uk/components/error-summary/ | Copy a form flow with field labels, helper text, validation errors, review state, submit action, status, and protected-data treatment. |

### Reference Research Queries
- community app home screen announcements events messages design examples
- open source Flutter community app home feed events messages UI
- open source Flutter export-wizard mobile UI example GitHub
- export/import wizard with preview, redaction, checksum, transfer status, and rollback state mobile UX pattern
- Material Design export/import wizard with preview, redaction, checksum, transfer status, and rollback state mobile pattern
- open source Flutter voting-selection mobile UI example GitHub
- book club reading/voting surface with nominations, vote state, selected book, meeting context, and discussion mobile UX pattern
- Material Design book club reading/voting surface with nominations, vote state, selected book, meeting context, and discussion mobile pattern
- open source Flutter event-rsvp mobile UI example GitHub
- event detail with schedule, location, capacity/status, RSVP action, and result state mobile UX pattern
- Material Design event detail with schedule, location, capacity/status, RSVP action, and result state mobile pattern
- open source Flutter message-thread mobile UI example GitHub
- inbox, message thread, connection card, invite, or block-state surface mobile UX pattern
- Material Design inbox, message thread, connection card, invite, or block-state surface mobile pattern
- open source Flutter announcement-feed mobile UI example GitHub
- announcement feed/composer with audience, author, timestamp, body, and receiver state mobile UX pattern
- Material Design announcement feed/composer with audience, author, timestamp, body, and receiver state mobile pattern
- open source Flutter form-review mobile UI example GitHub
- volunteer signup surface with role, time, protected contact fields, and confirmation mobile UX pattern
- Material Design volunteer signup surface with role, time, protected contact fields, and confirmation mobile pattern

### UI Remediation Work Items

Showing 9 of 9 work items. Full detail is in the JSON artifact.

| Work item | Stage | Community | Workflow | Persona | Screens | Coverage | Target surface | Blocked until |
| --- | --- | --- | --- | --- | ---: | ---: | --- | --- |
| `b25-wi-ui-remediation-community-garden-club-garden-export-custom-schemas-community-garden-club-owner` | `ui-remediation` | Garden Club | `garden-export-custom-schemas` | owner | 1 | 0 | export/import wizard with preview, redaction, checksum, transfer status, and rollback state | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-book-club-book-nomination-community-book-club-member` | `ui-remediation` | Neighborhood Book Club | `book-nomination` | member | 1 | 0 | book club reading/voting surface with nominations, vote state, selected book, meeting context, and discussion | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-book-club-book-vote-community-book-club-member` | `ui-remediation` | Neighborhood Book Club | `book-vote` | member | 1 | 0 | book club reading/voting surface with nominations, vote state, selected book, meeting context, and discussion | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-book-club-book-meeting-rsvp-community-book-club-member` | `ui-remediation` | Neighborhood Book Club | `book-meeting-rsvp` | member | 1 | 0 | event detail with schedule, location, capacity/status, RSVP action, and result state | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-book-club-book-discussion-message-community-book-club-member` | `ui-remediation` | Neighborhood Book Club | `book-discussion-message` | member | 1 | 0 | inbox, message thread, connection card, invite, or block-state surface | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-book-club-book-selection-publish-community-book-club-owner` | `ui-remediation` | Neighborhood Book Club | `book-selection-publish` | owner | 1 | 0 | announcement feed/composer with audience, author, timestamp, body, and receiver state | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-mosque-mosque-announcement-community-mosque-owner` | `ui-remediation` | Masjid Nur | `mosque-announcement` | owner | 1 | 0 | announcement feed/composer with audience, author, timestamp, body, and receiver state | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-mosque-mosque-event-rsvp-community-mosque-member` | `ui-remediation` | Masjid Nur | `mosque-event-rsvp` | member | 1 | 0 | event detail with schedule, location, capacity/status, RSVP action, and result state | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-mosque-mosque-volunteer-signup-community-mosque-member` | `ui-remediation` | Masjid Nur | `mosque-volunteer-signup` | member | 1 | 0 | volunteer signup surface with role, time, protected contact fields, and confirmation | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |

### UI Remediation Work Items Reference Patterns

| Reference | Source | URL | What to copy |
| --- | --- | --- | --- |
| Task list and export wizard | GOV.UK Design System / design-system | https://design-system.service.gov.uk/components/task-list/<br>Also: https://design-system.service.gov.uk/patterns/check-answers/ | Copy a wizard with steps, preview, redaction choices, checksum evidence, transfer status, and rollback confirmation. |
| Material Design cards and lists | Material Design 3 / design-system | https://m3.material.io/components/cards/overview<br>Also: https://m3.material.io/components/lists/overview | Use cards/lists only as scannable containers with clear hierarchy, content, metadata, and actions. Do not use repeated cards as the whole primary workflow. |
| Flutter sample app implementation patterns | flutter/samples / open-source | https://github.com/flutter/samples | Copy the separation between app shell, route state, domain widgets, and testable UI states rather than hardcoding a single generic renderer. |
| Material navigation and information architecture | Material Design 3 / design-system | https://m3.material.io/components/navigation-drawer/overview<br>Also: https://m3.material.io/components/navigation-bar/overview | Organize screens by user jobs and destinations; keep primary actions visible and avoid exposing implementation taxonomy. |
| Apple HIG navigation and content organization | Apple Human Interface Guidelines / design-system | https://developer.apple.com/design/human-interface-guidelines/navigation | Make navigation predictable, content-centered, and appropriate for the user’s current task. |
| Selection and voting pattern | Material chips/cards/buttons / pattern | https://m3.material.io/components/chips/overview<br>Also: https://m3.material.io/components/cards/overview | Copy a nomination/voting surface with choices, current vote state, deadline, selected result, and meeting/discussion context. |
| Event detail and RSVP flow | Material cards/lists/buttons / pattern | https://m3.material.io/components/cards/overview<br>Also: https://m3.material.io/components/buttons/overview<br>https://m3.material.io/components/chips/overview | Copy an event detail layout: title, date/time, location, host, capacity/status chip, attendee context, RSVP action, and confirmation state. |
| Inbox and message thread pattern | Material lists/text fields / pattern | https://m3.material.io/components/lists/overview<br>Also: https://m3.material.io/components/text-fields/overview | Copy an inbox/thread structure: sender, timestamp, message preview/body, reply field, invite/block state, and read/received state. |
| Feed item and composer pattern | Material cards/lists/text fields / pattern | https://m3.material.io/components/text-fields/overview<br>Also: https://m3.material.io/components/cards/overview<br>https://m3.material.io/components/lists/overview | Copy a feed/composer structure: audience, author, timestamp, body, attachments/status, publish action, and receiver read state. |
| Form validation and review pattern | U.S. Web Design System / design-system | https://designsystem.digital.gov/components/form/<br>Also: https://designsystem.digital.gov/components/alert/<br>https://design-system.service.gov.uk/components/error-summary/ | Copy a form flow with field labels, helper text, validation errors, review state, submit action, status, and protected-data treatment. |

### Affected Screen Rows

Showing 9 of 9 affected screen rows. Full detail is in the JSON ticket.

| Screen row | Community | Workflow | Persona | State | Screenshot | Hash | Visible text | Current surface | Exact UX failure | Target surface |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `b25-v4-row-008-garden-export-custom-schemas-1` | Garden Club | `garden-export-custom-schemas` | owner | B13_ext_garden_club_garden-export-custom-schemas_action | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B13/screenshots/B13_ext_garden_club_garden-export-custom-schemas_action.png` | `1105b28624553...` | Prepare export handoff \| Use this surface to package export scope, redaction, and handoff status. \| Redacted copy \| Checksum ready \| Exportable \| Decision \| Decide the scope, redaction, checksum, destination, and whether to retry, roll back, or change scope. \| Details \| Data s... | domain-native-reviewed / domain-native | LLM vision critique: This remains a generic workflow/action template. Even if export is a supporting/admin flow, the surface is not production-grade because it exposes implementation taxonomy. LLM required fix: Redesign as an export package review screen with file/package identity, included data types, redaction summary, checksum, destination, audit trail, rollback/change-scope controls, and final generate/download action. Current row verdict is `fail` with severity `major`. | export/import wizard with preview, redaction, checksum, transfer status, and rollback state |
| `b25-v4-row-011-book-nomination-1` | Neighborhood Book Club | `book-nomination` | member | B14_ext_book_club_book-nomination_action | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_book_club_book-nomination_action.png` | `d971530b07e27...` | Submit member form \| Use this surface to submit structured member details. \| Labeled fields \| Privacy checked \| Review handoff \| Decision \| Decide what to save, what to change, and what status or next step should remain visible afterward. \| Details \| Required details are ready... | domain-native-reviewed / domain-native | LLM vision critique: This is not a book nomination product surface. It does not show a title, author, member rationale, genre, meeting context, voting/nomination state, or a natural review/submit form. LLM required fix: Replace with a real book nomination form/review screen including book title, author, reason for nomination, meeting cycle, visibility/privacy settings if needed, edit/cancel, and submit nomination result. Current row verdict is `fail` with severity `blocker`. | book club reading/voting surface with nominations, vote state, selected book, meeting context, and discussion |
| `b25-v4-row-014-book-vote-1` | Neighborhood Book Club | `book-vote` | member | B14_ext_book_club_book-vote_action | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_book_club_book-vote_action.png` | `7b2761d92193b...` | Submit member form \| Use this surface to submit structured member details. \| Labeled fields \| Privacy checked \| Review handoff \| Decision \| Decide what to save, what to change, and what status or next step should remain visible afterward. \| Details \| Required details are ready... | domain-native-reviewed / domain-native | No row-specific failure recorded. | book club reading/voting surface with nominations, vote state, selected book, meeting context, and discussion |
| `b25-v4-row-017-book-meeting-rsvp-1` | Neighborhood Book Club | `book-meeting-rsvp` | member | B14_ext_book_club_book-meeting-rsvp_action | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_book_club_book-meeting-rsvp_action.png` | `2e978d0902300...` | Coordinate attendance \| Use this surface to publish event details, capacity, and attendance state. \| This week \| Community venue \| Capacity tracked \| RSVP available \| Decision \| Decide if you are going, maybe, or not attending after checking date, time, location, and capacity.... | domain-native-reviewed / domain-native | LLM vision critique: Unlike the improved Garden RSVP, this event screen remains a template. It does not feel like a book club meeting page because it lacks the book, venue, time, discussion host, attendee state, and concrete RSVP controls. LLM required fix: Create a book meeting RSVP detail screen with meeting title, selected book, date/time, venue, host, capacity, current RSVP, attendee/reminder state, and natural RSVP/change-response controls. Current row verdict is `fail` with severity `major`. | event detail with schedule, location, capacity/status, RSVP action, and result state |
| `b25-v4-row-020-book-discussion-message-1` | Neighborhood Book Club | `book-discussion-message` | member | B14_ext_book_club_book-discussion-message_action | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_book_club_book-discussion-message_action.png` | `b7942f903d0d1...` | Update member channel \| Use this surface to change a member communication or relationship setting. \| Private by default \| Membership scoped \| Ready \| Decision \| Decide whether to reply, send, accept, decline, mute, archive, or block this member communication. \| Details \| Membe... | domain-native-reviewed / domain-native | No row-specific failure recorded. | inbox, message thread, connection card, invite, or block-state surface |
| `b25-v4-row-023-book-selection-publish-1` | Neighborhood Book Club | `book-selection-publish` | owner | B14_ext_book_club_book-selection-publish_action | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_book_club_book-selection-publish_action.png` | `48516b6175aef...` | Send community notice \| Use this surface to send a scoped announcement to the selected audience. \| Members \| Today \| From admin \| Inbox + push \| Decision \| Decide whether this message is ready for members, who receives it, and whether to preview or save a draft first. \| Detail... | domain-native-reviewed / domain-native | No row-specific failure recorded. | announcement feed/composer with audience, author, timestamp, body, and receiver state |
| `b25-v4-row-074-mosque-announcement-1` | Masjid Nur | `mosque-announcement` | owner | B14_ext_mosque_mosque-announcement_action | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_mosque_mosque-announcement_action.png` | `4f9beca474852...` | Send community notice \| Use this surface to send a scoped announcement to the selected audience. \| Members \| Today \| From admin \| Inbox + push \| Decision \| Decide whether this message is ready for members, who receives it, and whether to preview or save a draft first. \| Detail... | domain-native-reviewed / domain-native | LLM vision critique: This is not yet a production announcement authoring or preview experience. It documents that an announcement can be sent, but does not look like a real admin composing and publishing a message to members. LLM required fix: Replace with a true announcement composer/review screen including subject, body, audience, schedule/channel, preview, save draft, publish, and sent/receiver state. Current row verdict is `fail` with severity `major`. | announcement feed/composer with audience, author, timestamp, body, and receiver state |
| `b25-v4-row-077-mosque-event-rsvp-1` | Masjid Nur | `mosque-event-rsvp` | member | B14_ext_mosque_mosque-event-rsvp_action | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_mosque_mosque-event-rsvp_action.png` | `2e978d0902300...` | Coordinate attendance \| Use this surface to publish event details, capacity, and attendance state. \| This week \| Community venue \| Capacity tracked \| RSVP available \| Decision \| Decide if you are going, maybe, or not attending after checking date, time, location, and capacity.... | domain-native-reviewed / domain-native | No row-specific failure recorded. | event detail with schedule, location, capacity/status, RSVP action, and result state |
| `b25-v4-row-080-mosque-volunteer-signup-1` | Masjid Nur | `mosque-volunteer-signup` | member | B14_ext_mosque_mosque-volunteer-signup_action | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_mosque_mosque-volunteer-signup_action.png` | `295f52a21ab9b...` | Submit member form \| Use this surface to submit structured member details. \| Open shift \| Contact protected \| Coordinator notified \| Decision \| Decide what to save, what to change, and what status or next step should remain visible afterward. \| Details \| Required details are r... | domain-native-reviewed / domain-native | LLM vision critique: This does not feel like a volunteer signup flow. A member should see a specific shift, time, role, requirements, contact preference, confirmation, and coordinator follow-up. LLM required fix: Build a volunteer shift signup surface with shift details, time/location, role requirements, contact/privacy controls, cancel/change option, signup confirmation, and coordinator receiver state. Current row verdict is `fail` with severity `major`. | volunteer signup surface with role, time, protected contact fields, and confirmation |

### Failing Direct Questions

| Question | Scope | Score | Why | Required fix |
| --- | --- | ---: | --- | --- |
| Does the whole experience feel like a real production community app, not merely an implemented workflow harness? | llm-vision-holistic | 58 |  | Replace all remaining generic action templates with domain-native product screens for each community workflow, with real object details, task-specific controls, natural alternate actions, and contextual result states. |
| Is the UI modern, easy to use, easy to navigate, and visually appealing for the target personas? | llm-vision-holistic | 66 |  | Vary layouts by workflow type: event detail pages, book nomination forms, announcement composers, donation receipts, volunteer shift signup, export package review, and inbox/detail screens should each have task-specific IA and content hierarchy. |
| Is the experience community/product-centered rather than framework-centered? | llm-vision-holistic | 62 |  | Audit every screen row for framework-centered language and replace it with community-specific nouns, details, relationships, and outcomes. |
| Do primary workflow/persona screens show domain-native product surfaces and complete interaction models? | llm-vision-holistic | 55 |  | For every primary workflow/persona pair, build the actual task surface rather than a generic decision template, then recapture screenshots and rerun B25. |

### Likely Files / Widgets
- `app/apps/loom_communities_demo/lib/main.dart`
- `app/apps/loom_communities_demo/test/b21_b25_production_ux_test.dart`
- `docs/Build Plan V2/Evidence/B25/production-ux-blueprint.md`
- `docs/Build Plan V2/Evidence/B25/independent-production-ux-review.json`
- `docs/Build Plan V2/Evidence/B25/product-ux-screen-review-matrix.md`
- `app/apps/loom_communities_demo/integration_test/workflow_ui_evidence_test.dart`
- `app/apps/loom_communities_demo/test/workflow_ui_test_harness.dart`

### Concrete Acceptance Criteria
- Holistic direct-question answers are present, screenshot-backed, non-boilerplate, and pass.
- `production_ux_judge.dart` has no blocking failure for this criterion.
- `b25_iteration_scorecard.dart` records the ticket as resolved or no longer blocking.
- Screenshots are refreshed and hashes/timestamps/app commit SHA match the reviewed app version.
- Screen row `b25-v4-row-008-garden-export-custom-schemas-1` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-008-garden-export-custom-schemas-1` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-008-garden-export-custom-schemas-1` names visible UI elements, visible text, persona `owner`, workflow `garden-export-custom-schemas`, and the exact product UX issue.
- Primary surface for `garden-export-custom-schemas` is documented as `export/import wizard with preview, redaction, checksum, transfer status, and rollback state` or another explicit domain-native surface.
- After-screenshot visible text proves every required semantic surface group for `garden-export-custom-schemas`.
- Fresh screenshot path/hash/timestamp/app commit SHA are recorded after the fix.
- Screen row `b25-v4-row-011-book-nomination-1` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-011-book-nomination-1` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-011-book-nomination-1` names visible UI elements, visible text, persona `member`, workflow `book-nomination`, and the exact product UX issue.
- Primary surface for `book-nomination` is documented as `book club reading/voting surface with nominations, vote state, selected book, meeting context, and discussion` or another explicit domain-native surface.
- After-screenshot visible text proves every required semantic surface group for `book-nomination`.
- Screen row `b25-v4-row-014-book-vote-1` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-014-book-vote-1` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-014-book-vote-1` names visible UI elements, visible text, persona `member`, workflow `book-vote`, and the exact product UX issue.
- Primary surface for `book-vote` is documented as `book club reading/voting surface with nominations, vote state, selected book, meeting context, and discussion` or another explicit domain-native surface.
- After-screenshot visible text proves every required semantic surface group for `book-vote`.
- Screen row `b25-v4-row-017-book-meeting-rsvp-1` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-017-book-meeting-rsvp-1` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-017-book-meeting-rsvp-1` names visible UI elements, visible text, persona `member`, workflow `book-meeting-rsvp`, and the exact product UX issue.
- Primary surface for `book-meeting-rsvp` is documented as `event detail with schedule, location, capacity/status, RSVP action, and result state` or another explicit domain-native surface.
- After-screenshot visible text proves every required semantic surface group for `book-meeting-rsvp`.
- Screen row `b25-v4-row-020-book-discussion-message-1` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-020-book-discussion-message-1` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-020-book-discussion-message-1` names visible UI elements, visible text, persona `member`, workflow `book-discussion-message`, and the exact product UX issue.
- Primary surface for `book-discussion-message` is documented as `inbox, message thread, connection card, invite, or block-state surface` or another explicit domain-native surface.
- After-screenshot visible text proves every required semantic surface group for `book-discussion-message`.
- Screen row `b25-v4-row-023-book-selection-publish-1` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-023-book-selection-publish-1` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-023-book-selection-publish-1` names visible UI elements, visible text, persona `owner`, workflow `book-selection-publish`, and the exact product UX issue.
- Primary surface for `book-selection-publish` is documented as `announcement feed/composer with audience, author, timestamp, body, and receiver state` or another explicit domain-native surface.
- After-screenshot visible text proves every required semantic surface group for `book-selection-publish`.
- Screen row `b25-v4-row-074-mosque-announcement-1` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-074-mosque-announcement-1` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-074-mosque-announcement-1` names visible UI elements, visible text, persona `owner`, workflow `mosque-announcement`, and the exact product UX issue.
- Primary surface for `mosque-announcement` is documented as `announcement feed/composer with audience, author, timestamp, body, and receiver state` or another explicit domain-native surface.
- After-screenshot visible text proves every required semantic surface group for `mosque-announcement`.
- Screen row `b25-v4-row-077-mosque-event-rsvp-1` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-077-mosque-event-rsvp-1` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-077-mosque-event-rsvp-1` names visible UI elements, visible text, persona `member`, workflow `mosque-event-rsvp`, and the exact product UX issue.
- Primary surface for `mosque-event-rsvp` is documented as `event detail with schedule, location, capacity/status, RSVP action, and result state` or another explicit domain-native surface.
- After-screenshot visible text proves every required semantic surface group for `mosque-event-rsvp`.
- Screen row `b25-v4-row-080-mosque-volunteer-signup-1` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-080-mosque-volunteer-signup-1` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-080-mosque-volunteer-signup-1` names visible UI elements, visible text, persona `member`, workflow `mosque-volunteer-signup`, and the exact product UX issue.
- Primary surface for `mosque-volunteer-signup` is documented as `volunteer signup surface with role, time, protected contact fields, and confirmation` or another explicit domain-native surface.
- After-screenshot visible text proves every required semantic surface group for `mosque-volunteer-signup`.

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
- `dart run packages/tooling/loom_ux_judges/bin/b25_evidence_collector.dart --evidence-root ../docs/Build\ Plan\ V2/Evidence --repo-root .. --run-id <next-run-id> --prior-review ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --output ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.md --matrix-output ../docs/Build\ Plan\ V2/Evidence/B25/product-ux-screen-review-matrix.md`
- `dart run packages/tooling/loom_ux_judges/bin/b25_workflow_persona_coverage_collector.dart --input ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --output ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/workflow-persona-coverage-matrix.md`
- `dart run packages/tooling/loom_ux_judges/bin/b25_independent_ux_judge.dart --input ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --output ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.md --matrix-output ../docs/Build\ Plan\ V2/Evidence/B25/product-ux-screen-review-matrix.md`
- `dart run packages/tooling/loom_ux_judges/bin/production_ux_judge.dart --input ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --base .. --output ../docs/Build\ Plan\ V2/Evidence/B25/production-ux-criteria-scorecard.json --markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/production-ux-criteria-scorecard.md --tickets-output ../docs/Build\ Plan\ V2/Evidence/B25/b25-remediation-tickets-<next-run-id>.json --tickets-markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/b25-remediation-tickets-<next-run-id>.md`
- `dart run packages/tooling/loom_ux_judges/bin/b25_iteration_scorecard.dart --review ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --judge ../docs/Build\ Plan\ V2/Evidence/B25/production-ux-criteria-scorecard.json --previous ../docs/Build\ Plan\ V2/Evidence/B25/b25-iteration-scorecard-latest.json --output ../docs/Build\ Plan\ V2/Evidence/B25/b25-iteration-scorecard-latest.json --markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/b25-iteration-scorecard-latest.md`

## B25-RT-006-b25-c09-no-layout-production-defects

| Field | Value |
| --- | --- |
| Severity | major |
| Priority | P1 |
| Status | open |
| Review run | `b25-v4-pass-16` |
| Source criterion | `b25-c09-no-layout-production-defects` |
| Source findings | LLM-B25-P16-001, LLM-B25-P16-002, LLM-B25-P16-003 |
| Title | No blocking or major layout/content defects remain |
| Direct question | Does the visible UI avoid blocking or major overlap, clipping, crowding, default-scaffold, repeated-card, checklist-modal, and thin-content defects? |
| Why it failed | holistic direct-question answers are missing, weak, partial, or blocking: llm-holistic-production-grade, llm-holistic-modern-easy-navigation, llm-holistic-community-centered, llm-primary-workflow-surfaces. |
| Required outcome | Fix layout/content defects and rerun the review. |
| Remediation mode | `ui-remediation-ready` |
| Worker readiness | ready for worker implementation using the uiRemediationWorkItems |
| First required step | Implement the target production surfaces and content specified in uiRemediationWorkItems, then recapture screenshots. |

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
| Task list and export wizard | GOV.UK Design System / design-system | https://design-system.service.gov.uk/components/task-list/<br>Also: https://design-system.service.gov.uk/patterns/check-answers/ | Copy a wizard with steps, preview, redaction choices, checksum evidence, transfer status, and rollback confirmation. |
| Selection and voting pattern | Material chips/cards/buttons / pattern | https://m3.material.io/components/chips/overview<br>Also: https://m3.material.io/components/cards/overview | Copy a nomination/voting surface with choices, current vote state, deadline, selected result, and meeting/discussion context. |
| Event detail and RSVP flow | Material cards/lists/buttons / pattern | https://m3.material.io/components/cards/overview<br>Also: https://m3.material.io/components/buttons/overview<br>https://m3.material.io/components/chips/overview | Copy an event detail layout: title, date/time, location, host, capacity/status chip, attendee context, RSVP action, and confirmation state. |
| Inbox and message thread pattern | Material lists/text fields / pattern | https://m3.material.io/components/lists/overview<br>Also: https://m3.material.io/components/text-fields/overview | Copy an inbox/thread structure: sender, timestamp, message preview/body, reply field, invite/block state, and read/received state. |
| Feed item and composer pattern | Material cards/lists/text fields / pattern | https://m3.material.io/components/text-fields/overview<br>Also: https://m3.material.io/components/cards/overview<br>https://m3.material.io/components/lists/overview | Copy a feed/composer structure: audience, author, timestamp, body, attachments/status, publish action, and receiver read state. |
| Form validation and review pattern | U.S. Web Design System / design-system | https://designsystem.digital.gov/components/form/<br>Also: https://designsystem.digital.gov/components/alert/<br>https://design-system.service.gov.uk/components/error-summary/ | Copy a form flow with field labels, helper text, validation errors, review state, submit action, status, and protected-data treatment. |

### Reference Research Queries
- production mobile UX review screenshot critique examples
- open source Flutter mobile app UX patterns GitHub
- open source Flutter export-wizard mobile UI example GitHub
- export/import wizard with preview, redaction, checksum, transfer status, and rollback state mobile UX pattern
- Material Design export/import wizard with preview, redaction, checksum, transfer status, and rollback state mobile pattern
- open source Flutter voting-selection mobile UI example GitHub
- book club reading/voting surface with nominations, vote state, selected book, meeting context, and discussion mobile UX pattern
- Material Design book club reading/voting surface with nominations, vote state, selected book, meeting context, and discussion mobile pattern
- open source Flutter event-rsvp mobile UI example GitHub
- event detail with schedule, location, capacity/status, RSVP action, and result state mobile UX pattern
- Material Design event detail with schedule, location, capacity/status, RSVP action, and result state mobile pattern
- open source Flutter message-thread mobile UI example GitHub
- inbox, message thread, connection card, invite, or block-state surface mobile UX pattern
- Material Design inbox, message thread, connection card, invite, or block-state surface mobile pattern
- open source Flutter announcement-feed mobile UI example GitHub
- announcement feed/composer with audience, author, timestamp, body, and receiver state mobile UX pattern
- Material Design announcement feed/composer with audience, author, timestamp, body, and receiver state mobile pattern
- open source Flutter form-review mobile UI example GitHub
- volunteer signup surface with role, time, protected contact fields, and confirmation mobile UX pattern
- Material Design volunteer signup surface with role, time, protected contact fields, and confirmation mobile pattern

### UI Remediation Work Items

Showing 9 of 9 work items. Full detail is in the JSON artifact.

| Work item | Stage | Community | Workflow | Persona | Screens | Coverage | Target surface | Blocked until |
| --- | --- | --- | --- | --- | ---: | ---: | --- | --- |
| `b25-wi-ui-remediation-community-garden-club-garden-export-custom-schemas-community-garden-club-owner` | `ui-remediation` | Garden Club | `garden-export-custom-schemas` | owner | 1 | 0 | export/import wizard with preview, redaction, checksum, transfer status, and rollback state | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-book-club-book-nomination-community-book-club-member` | `ui-remediation` | Neighborhood Book Club | `book-nomination` | member | 1 | 0 | book club reading/voting surface with nominations, vote state, selected book, meeting context, and discussion | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-book-club-book-vote-community-book-club-member` | `ui-remediation` | Neighborhood Book Club | `book-vote` | member | 1 | 0 | book club reading/voting surface with nominations, vote state, selected book, meeting context, and discussion | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-book-club-book-meeting-rsvp-community-book-club-member` | `ui-remediation` | Neighborhood Book Club | `book-meeting-rsvp` | member | 1 | 0 | event detail with schedule, location, capacity/status, RSVP action, and result state | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-book-club-book-discussion-message-community-book-club-member` | `ui-remediation` | Neighborhood Book Club | `book-discussion-message` | member | 1 | 0 | inbox, message thread, connection card, invite, or block-state surface | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-book-club-book-selection-publish-community-book-club-owner` | `ui-remediation` | Neighborhood Book Club | `book-selection-publish` | owner | 1 | 0 | announcement feed/composer with audience, author, timestamp, body, and receiver state | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-mosque-mosque-announcement-community-mosque-owner` | `ui-remediation` | Masjid Nur | `mosque-announcement` | owner | 1 | 0 | announcement feed/composer with audience, author, timestamp, body, and receiver state | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-mosque-mosque-event-rsvp-community-mosque-member` | `ui-remediation` | Masjid Nur | `mosque-event-rsvp` | member | 1 | 0 | event detail with schedule, location, capacity/status, RSVP action, and result state | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-mosque-mosque-volunteer-signup-community-mosque-member` | `ui-remediation` | Masjid Nur | `mosque-volunteer-signup` | member | 1 | 0 | volunteer signup surface with role, time, protected contact fields, and confirmation | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |

### UI Remediation Work Items Reference Patterns

| Reference | Source | URL | What to copy |
| --- | --- | --- | --- |
| Task list and export wizard | GOV.UK Design System / design-system | https://design-system.service.gov.uk/components/task-list/<br>Also: https://design-system.service.gov.uk/patterns/check-answers/ | Copy a wizard with steps, preview, redaction choices, checksum evidence, transfer status, and rollback confirmation. |
| Material Design cards and lists | Material Design 3 / design-system | https://m3.material.io/components/cards/overview<br>Also: https://m3.material.io/components/lists/overview | Use cards/lists only as scannable containers with clear hierarchy, content, metadata, and actions. Do not use repeated cards as the whole primary workflow. |
| Flutter sample app implementation patterns | flutter/samples / open-source | https://github.com/flutter/samples | Copy the separation between app shell, route state, domain widgets, and testable UI states rather than hardcoding a single generic renderer. |
| Material navigation and information architecture | Material Design 3 / design-system | https://m3.material.io/components/navigation-drawer/overview<br>Also: https://m3.material.io/components/navigation-bar/overview | Organize screens by user jobs and destinations; keep primary actions visible and avoid exposing implementation taxonomy. |
| Apple HIG navigation and content organization | Apple Human Interface Guidelines / design-system | https://developer.apple.com/design/human-interface-guidelines/navigation | Make navigation predictable, content-centered, and appropriate for the user’s current task. |
| Selection and voting pattern | Material chips/cards/buttons / pattern | https://m3.material.io/components/chips/overview<br>Also: https://m3.material.io/components/cards/overview | Copy a nomination/voting surface with choices, current vote state, deadline, selected result, and meeting/discussion context. |
| Event detail and RSVP flow | Material cards/lists/buttons / pattern | https://m3.material.io/components/cards/overview<br>Also: https://m3.material.io/components/buttons/overview<br>https://m3.material.io/components/chips/overview | Copy an event detail layout: title, date/time, location, host, capacity/status chip, attendee context, RSVP action, and confirmation state. |
| Inbox and message thread pattern | Material lists/text fields / pattern | https://m3.material.io/components/lists/overview<br>Also: https://m3.material.io/components/text-fields/overview | Copy an inbox/thread structure: sender, timestamp, message preview/body, reply field, invite/block state, and read/received state. |
| Feed item and composer pattern | Material cards/lists/text fields / pattern | https://m3.material.io/components/text-fields/overview<br>Also: https://m3.material.io/components/cards/overview<br>https://m3.material.io/components/lists/overview | Copy a feed/composer structure: audience, author, timestamp, body, attachments/status, publish action, and receiver read state. |
| Form validation and review pattern | U.S. Web Design System / design-system | https://designsystem.digital.gov/components/form/<br>Also: https://designsystem.digital.gov/components/alert/<br>https://design-system.service.gov.uk/components/error-summary/ | Copy a form flow with field labels, helper text, validation errors, review state, submit action, status, and protected-data treatment. |

### Affected Screen Rows

Showing 9 of 9 affected screen rows. Full detail is in the JSON ticket.

| Screen row | Community | Workflow | Persona | State | Screenshot | Hash | Visible text | Current surface | Exact UX failure | Target surface |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `b25-v4-row-008-garden-export-custom-schemas-1` | Garden Club | `garden-export-custom-schemas` | owner | B13_ext_garden_club_garden-export-custom-schemas_action | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B13/screenshots/B13_ext_garden_club_garden-export-custom-schemas_action.png` | `1105b28624553...` | Prepare export handoff \| Use this surface to package export scope, redaction, and handoff status. \| Redacted copy \| Checksum ready \| Exportable \| Decision \| Decide the scope, redaction, checksum, destination, and whether to retry, roll back, or change scope. \| Details \| Data s... | domain-native-reviewed / domain-native | LLM vision critique: This remains a generic workflow/action template. Even if export is a supporting/admin flow, the surface is not production-grade because it exposes implementation taxonomy. LLM required fix: Redesign as an export package review screen with file/package identity, included data types, redaction summary, checksum, destination, audit trail, rollback/change-scope controls, and final generate/download action. Current row verdict is `fail` with severity `major`. | export/import wizard with preview, redaction, checksum, transfer status, and rollback state |
| `b25-v4-row-011-book-nomination-1` | Neighborhood Book Club | `book-nomination` | member | B14_ext_book_club_book-nomination_action | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_book_club_book-nomination_action.png` | `d971530b07e27...` | Submit member form \| Use this surface to submit structured member details. \| Labeled fields \| Privacy checked \| Review handoff \| Decision \| Decide what to save, what to change, and what status or next step should remain visible afterward. \| Details \| Required details are ready... | domain-native-reviewed / domain-native | LLM vision critique: This is not a book nomination product surface. It does not show a title, author, member rationale, genre, meeting context, voting/nomination state, or a natural review/submit form. LLM required fix: Replace with a real book nomination form/review screen including book title, author, reason for nomination, meeting cycle, visibility/privacy settings if needed, edit/cancel, and submit nomination result. Current row verdict is `fail` with severity `blocker`. | book club reading/voting surface with nominations, vote state, selected book, meeting context, and discussion |
| `b25-v4-row-014-book-vote-1` | Neighborhood Book Club | `book-vote` | member | B14_ext_book_club_book-vote_action | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_book_club_book-vote_action.png` | `7b2761d92193b...` | Submit member form \| Use this surface to submit structured member details. \| Labeled fields \| Privacy checked \| Review handoff \| Decision \| Decide what to save, what to change, and what status or next step should remain visible afterward. \| Details \| Required details are ready... | domain-native-reviewed / domain-native | No row-specific failure recorded. | book club reading/voting surface with nominations, vote state, selected book, meeting context, and discussion |
| `b25-v4-row-017-book-meeting-rsvp-1` | Neighborhood Book Club | `book-meeting-rsvp` | member | B14_ext_book_club_book-meeting-rsvp_action | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_book_club_book-meeting-rsvp_action.png` | `2e978d0902300...` | Coordinate attendance \| Use this surface to publish event details, capacity, and attendance state. \| This week \| Community venue \| Capacity tracked \| RSVP available \| Decision \| Decide if you are going, maybe, or not attending after checking date, time, location, and capacity.... | domain-native-reviewed / domain-native | LLM vision critique: Unlike the improved Garden RSVP, this event screen remains a template. It does not feel like a book club meeting page because it lacks the book, venue, time, discussion host, attendee state, and concrete RSVP controls. LLM required fix: Create a book meeting RSVP detail screen with meeting title, selected book, date/time, venue, host, capacity, current RSVP, attendee/reminder state, and natural RSVP/change-response controls. Current row verdict is `fail` with severity `major`. | event detail with schedule, location, capacity/status, RSVP action, and result state |
| `b25-v4-row-020-book-discussion-message-1` | Neighborhood Book Club | `book-discussion-message` | member | B14_ext_book_club_book-discussion-message_action | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_book_club_book-discussion-message_action.png` | `b7942f903d0d1...` | Update member channel \| Use this surface to change a member communication or relationship setting. \| Private by default \| Membership scoped \| Ready \| Decision \| Decide whether to reply, send, accept, decline, mute, archive, or block this member communication. \| Details \| Membe... | domain-native-reviewed / domain-native | No row-specific failure recorded. | inbox, message thread, connection card, invite, or block-state surface |
| `b25-v4-row-023-book-selection-publish-1` | Neighborhood Book Club | `book-selection-publish` | owner | B14_ext_book_club_book-selection-publish_action | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_book_club_book-selection-publish_action.png` | `48516b6175aef...` | Send community notice \| Use this surface to send a scoped announcement to the selected audience. \| Members \| Today \| From admin \| Inbox + push \| Decision \| Decide whether this message is ready for members, who receives it, and whether to preview or save a draft first. \| Detail... | domain-native-reviewed / domain-native | No row-specific failure recorded. | announcement feed/composer with audience, author, timestamp, body, and receiver state |
| `b25-v4-row-074-mosque-announcement-1` | Masjid Nur | `mosque-announcement` | owner | B14_ext_mosque_mosque-announcement_action | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_mosque_mosque-announcement_action.png` | `4f9beca474852...` | Send community notice \| Use this surface to send a scoped announcement to the selected audience. \| Members \| Today \| From admin \| Inbox + push \| Decision \| Decide whether this message is ready for members, who receives it, and whether to preview or save a draft first. \| Detail... | domain-native-reviewed / domain-native | LLM vision critique: This is not yet a production announcement authoring or preview experience. It documents that an announcement can be sent, but does not look like a real admin composing and publishing a message to members. LLM required fix: Replace with a true announcement composer/review screen including subject, body, audience, schedule/channel, preview, save draft, publish, and sent/receiver state. Current row verdict is `fail` with severity `major`. | announcement feed/composer with audience, author, timestamp, body, and receiver state |
| `b25-v4-row-077-mosque-event-rsvp-1` | Masjid Nur | `mosque-event-rsvp` | member | B14_ext_mosque_mosque-event-rsvp_action | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_mosque_mosque-event-rsvp_action.png` | `2e978d0902300...` | Coordinate attendance \| Use this surface to publish event details, capacity, and attendance state. \| This week \| Community venue \| Capacity tracked \| RSVP available \| Decision \| Decide if you are going, maybe, or not attending after checking date, time, location, and capacity.... | domain-native-reviewed / domain-native | No row-specific failure recorded. | event detail with schedule, location, capacity/status, RSVP action, and result state |
| `b25-v4-row-080-mosque-volunteer-signup-1` | Masjid Nur | `mosque-volunteer-signup` | member | B14_ext_mosque_mosque-volunteer-signup_action | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_mosque_mosque-volunteer-signup_action.png` | `295f52a21ab9b...` | Submit member form \| Use this surface to submit structured member details. \| Open shift \| Contact protected \| Coordinator notified \| Decision \| Decide what to save, what to change, and what status or next step should remain visible afterward. \| Details \| Required details are r... | domain-native-reviewed / domain-native | LLM vision critique: This does not feel like a volunteer signup flow. A member should see a specific shift, time, role, requirements, contact preference, confirmation, and coordinator follow-up. LLM required fix: Build a volunteer shift signup surface with shift details, time/location, role requirements, contact/privacy controls, cancel/change option, signup confirmation, and coordinator receiver state. Current row verdict is `fail` with severity `major`. | volunteer signup surface with role, time, protected contact fields, and confirmation |

### Failing Direct Questions

| Question | Scope | Score | Why | Required fix |
| --- | --- | ---: | --- | --- |
| Does the whole experience feel like a real production community app, not merely an implemented workflow harness? | llm-vision-holistic | 58 |  | Replace all remaining generic action templates with domain-native product screens for each community workflow, with real object details, task-specific controls, natural alternate actions, and contextual result states. |
| Is the UI modern, easy to use, easy to navigate, and visually appealing for the target personas? | llm-vision-holistic | 66 |  | Vary layouts by workflow type: event detail pages, book nomination forms, announcement composers, donation receipts, volunteer shift signup, export package review, and inbox/detail screens should each have task-specific IA and content hierarchy. |
| Is the experience community/product-centered rather than framework-centered? | llm-vision-holistic | 62 |  | Audit every screen row for framework-centered language and replace it with community-specific nouns, details, relationships, and outcomes. |
| Do primary workflow/persona screens show domain-native product surfaces and complete interaction models? | llm-vision-holistic | 55 |  | For every primary workflow/persona pair, build the actual task surface rather than a generic decision template, then recapture screenshots and rerun B25. |

### Likely Files / Widgets
- `app/apps/loom_communities_demo/lib/main.dart`
- `app/apps/loom_communities_demo/test/b21_b25_production_ux_test.dart`
- `docs/Build Plan V2/Evidence/B25/production-ux-blueprint.md`
- `docs/Build Plan V2/Evidence/B25/independent-production-ux-review.json`
- `docs/Build Plan V2/Evidence/B25/product-ux-screen-review-matrix.md`
- `app/apps/loom_communities_demo/integration_test/workflow_ui_evidence_test.dart`
- `app/apps/loom_communities_demo/test/workflow_ui_test_harness.dart`

### Concrete Acceptance Criteria
- Holistic direct-question answers are present, screenshot-backed, non-boilerplate, and pass.
- `production_ux_judge.dart` has no blocking failure for this criterion.
- `b25_iteration_scorecard.dart` records the ticket as resolved or no longer blocking.
- Screenshots are refreshed and hashes/timestamps/app commit SHA match the reviewed app version.
- Screen row `b25-v4-row-008-garden-export-custom-schemas-1` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-008-garden-export-custom-schemas-1` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-008-garden-export-custom-schemas-1` names visible UI elements, visible text, persona `owner`, workflow `garden-export-custom-schemas`, and the exact product UX issue.
- Primary surface for `garden-export-custom-schemas` is documented as `export/import wizard with preview, redaction, checksum, transfer status, and rollback state` or another explicit domain-native surface.
- After-screenshot visible text proves every required semantic surface group for `garden-export-custom-schemas`.
- Fresh screenshot path/hash/timestamp/app commit SHA are recorded after the fix.
- Screen row `b25-v4-row-011-book-nomination-1` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-011-book-nomination-1` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-011-book-nomination-1` names visible UI elements, visible text, persona `member`, workflow `book-nomination`, and the exact product UX issue.
- Primary surface for `book-nomination` is documented as `book club reading/voting surface with nominations, vote state, selected book, meeting context, and discussion` or another explicit domain-native surface.
- After-screenshot visible text proves every required semantic surface group for `book-nomination`.
- Screen row `b25-v4-row-014-book-vote-1` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-014-book-vote-1` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-014-book-vote-1` names visible UI elements, visible text, persona `member`, workflow `book-vote`, and the exact product UX issue.
- Primary surface for `book-vote` is documented as `book club reading/voting surface with nominations, vote state, selected book, meeting context, and discussion` or another explicit domain-native surface.
- After-screenshot visible text proves every required semantic surface group for `book-vote`.
- Screen row `b25-v4-row-017-book-meeting-rsvp-1` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-017-book-meeting-rsvp-1` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-017-book-meeting-rsvp-1` names visible UI elements, visible text, persona `member`, workflow `book-meeting-rsvp`, and the exact product UX issue.
- Primary surface for `book-meeting-rsvp` is documented as `event detail with schedule, location, capacity/status, RSVP action, and result state` or another explicit domain-native surface.
- After-screenshot visible text proves every required semantic surface group for `book-meeting-rsvp`.
- Screen row `b25-v4-row-020-book-discussion-message-1` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-020-book-discussion-message-1` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-020-book-discussion-message-1` names visible UI elements, visible text, persona `member`, workflow `book-discussion-message`, and the exact product UX issue.
- Primary surface for `book-discussion-message` is documented as `inbox, message thread, connection card, invite, or block-state surface` or another explicit domain-native surface.
- After-screenshot visible text proves every required semantic surface group for `book-discussion-message`.
- Screen row `b25-v4-row-023-book-selection-publish-1` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-023-book-selection-publish-1` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-023-book-selection-publish-1` names visible UI elements, visible text, persona `owner`, workflow `book-selection-publish`, and the exact product UX issue.
- Primary surface for `book-selection-publish` is documented as `announcement feed/composer with audience, author, timestamp, body, and receiver state` or another explicit domain-native surface.
- After-screenshot visible text proves every required semantic surface group for `book-selection-publish`.
- Screen row `b25-v4-row-074-mosque-announcement-1` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-074-mosque-announcement-1` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-074-mosque-announcement-1` names visible UI elements, visible text, persona `owner`, workflow `mosque-announcement`, and the exact product UX issue.
- Primary surface for `mosque-announcement` is documented as `announcement feed/composer with audience, author, timestamp, body, and receiver state` or another explicit domain-native surface.
- After-screenshot visible text proves every required semantic surface group for `mosque-announcement`.
- Screen row `b25-v4-row-077-mosque-event-rsvp-1` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-077-mosque-event-rsvp-1` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-077-mosque-event-rsvp-1` names visible UI elements, visible text, persona `member`, workflow `mosque-event-rsvp`, and the exact product UX issue.
- Primary surface for `mosque-event-rsvp` is documented as `event detail with schedule, location, capacity/status, RSVP action, and result state` or another explicit domain-native surface.
- After-screenshot visible text proves every required semantic surface group for `mosque-event-rsvp`.
- Screen row `b25-v4-row-080-mosque-volunteer-signup-1` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-080-mosque-volunteer-signup-1` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-080-mosque-volunteer-signup-1` names visible UI elements, visible text, persona `member`, workflow `mosque-volunteer-signup`, and the exact product UX issue.
- Primary surface for `mosque-volunteer-signup` is documented as `volunteer signup surface with role, time, protected contact fields, and confirmation` or another explicit domain-native surface.
- After-screenshot visible text proves every required semantic surface group for `mosque-volunteer-signup`.

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
- `dart run packages/tooling/loom_ux_judges/bin/b25_evidence_collector.dart --evidence-root ../docs/Build\ Plan\ V2/Evidence --repo-root .. --run-id <next-run-id> --prior-review ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --output ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.md --matrix-output ../docs/Build\ Plan\ V2/Evidence/B25/product-ux-screen-review-matrix.md`
- `dart run packages/tooling/loom_ux_judges/bin/b25_workflow_persona_coverage_collector.dart --input ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --output ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/workflow-persona-coverage-matrix.md`
- `dart run packages/tooling/loom_ux_judges/bin/b25_independent_ux_judge.dart --input ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --output ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.md --matrix-output ../docs/Build\ Plan\ V2/Evidence/B25/product-ux-screen-review-matrix.md`
- `dart run packages/tooling/loom_ux_judges/bin/production_ux_judge.dart --input ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --base .. --output ../docs/Build\ Plan\ V2/Evidence/B25/production-ux-criteria-scorecard.json --markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/production-ux-criteria-scorecard.md --tickets-output ../docs/Build\ Plan\ V2/Evidence/B25/b25-remediation-tickets-<next-run-id>.json --tickets-markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/b25-remediation-tickets-<next-run-id>.md`
- `dart run packages/tooling/loom_ux_judges/bin/b25_iteration_scorecard.dart --review ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --judge ../docs/Build\ Plan\ V2/Evidence/B25/production-ux-criteria-scorecard.json --previous ../docs/Build\ Plan\ V2/Evidence/B25/b25-iteration-scorecard-latest.json --output ../docs/Build\ Plan\ V2/Evidence/B25/b25-iteration-scorecard-latest.json --markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/b25-iteration-scorecard-latest.md`
