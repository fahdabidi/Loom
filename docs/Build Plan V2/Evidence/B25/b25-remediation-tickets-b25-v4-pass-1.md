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
| Review run | `b25-v4-pass-9` |
| Source criterion | `b25-c01-no-blocker-major` |
| Source findings | B25-WORKFLOW-LIFECYCLE-INCOMPLETE |
| Title | No unresolved blocker or major findings |
| Direct question | Are there zero unresolved blocker or major findings in the current production UX evidence? |
| Why it failed | Unresolved blocker/major counts are blocker=0 major=1. |
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

### Implementation Blocked By
- Open blocker/major B25 tickets remain.
- The scorecard cannot close until those tickets rerun clean.

### Affected Screen Rows

Showing 40 of 177 affected screen rows. Full detail is in the JSON ticket.

| Screen row | Community | Workflow | Persona | State | Screenshot | Hash | Visible text | Current surface | Exact UX failure | Target surface |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `b25-v4-row-001-garden-event-rsvp-0` | Garden Club | `garden-event-rsvp` | member | B13_ext_garden_club_garden-event-rsvp_start | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B13/screenshots/B13_ext_garden_club_garden-event-rsvp_start.png` | `a22c40c22110b...` | Garden event RSVP \| Event details include date, location, capacity, and attendance. \| This week \| Community venue \| Capacity tracked \| RSVP to event \| Care and volunteers \| Private requests, volunteer shifts, and member support. \| Plant exchange submission \| Member form captur... | domain-native-reviewed / domain-native | No row-specific failure recorded. | event detail with schedule, location, capacity/status, RSVP action, and result state |
| `b25-v4-row-002-garden-event-rsvp-1` | Garden Club | `garden-event-rsvp` | member | B13_ext_garden_club_garden-event-rsvp_action | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B13/screenshots/B13_ext_garden_club_garden-event-rsvp_action.png` | `8752032410567...` | Coordinate attendance \| Use this surface to publish event details, capacity, and attendance state. \| This week \| Community venue \| Capacity tracked \| Details \| Date, location, capacity, and attendee state are included. \| Member outcome \| Attendance, capacity, and reminders upd... | domain-native-reviewed / domain-native | No row-specific failure recorded. | event detail with schedule, location, capacity/status, RSVP action, and result state |
| `b25-v4-row-003-garden-event-rsvp-2` | Garden Club | `garden-event-rsvp` | member | B13_ext_garden_club_garden-event-rsvp_complete | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B13/screenshots/B13_ext_garden_club_garden-event-rsvp_complete.png` | `a58aad43b14dd...` | Garden event RSVP \| Event details include date, location, capacity, and attendance. \| This week \| Community venue \| Capacity tracked \| RSVP confirmed \| Attendance, capacity, and confirmation details are up to date. \| Going \| Care and volunteers \| Private requests, volunteer sh... | domain-native-reviewed / domain-native | No row-specific failure recorded. | event detail with schedule, location, capacity/status, RSVP action, and result state |
| `b25-v4-row-004-plant-exchange-submission-0` | Garden Club | `plant-exchange-submission` | member | B13_ext_garden_club_plant-exchange-submission_start | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B13/screenshots/B13_ext_garden_club_plant-exchange-submission_start.png` | `7e5e418252089...` | Care and volunteers \| Private requests, volunteer shifts, and member support. \| Plant exchange submission \| Member form captures labeled details, privacy choices, and reviewer handoff. \| Labeled fields \| Privacy checked \| Review handoff \| Submit entry \| Documents and data \| Do... | domain-native-reviewed / domain-native | No row-specific failure recorded. | plant exchange offer form and member marketplace surface with plant details, pickup timing, owner contact, and submitted offer state |
| `b25-v4-row-005-plant-exchange-submission-1` | Garden Club | `plant-exchange-submission` | member | B13_ext_garden_club_plant-exchange-submission_action | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B13/screenshots/B13_ext_garden_club_plant-exchange-submission_action.png` | `ccd68c48ee915...` | Submit member form \| Use this surface to submit structured member details. \| Labeled fields \| Privacy checked \| Review handoff \| Details \| Required fields, privacy choices, and reviewer handoff are included. \| Member outcome \| The submission is routed to the reviewer with prot... | domain-native-reviewed / domain-native | No row-specific failure recorded. | plant exchange offer form and member marketplace surface with plant details, pickup timing, owner contact, and submitted offer state |
| `b25-v4-row-006-plant-exchange-submission-2` | Garden Club | `plant-exchange-submission` | member | B13_ext_garden_club_plant-exchange-submission_complete | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B13/screenshots/B13_ext_garden_club_plant-exchange-submission_complete.png` | `9155c4d4d2beb...` | Plant exchange submission \| Member form captures labeled details, privacy choices, and reviewer handoff. \| Labeled fields \| Privacy checked \| Review handoff \| Record saved \| The community record is saved. \| Saved \| Documents and data \| Documents, exports, imports, and transfer... | domain-native-reviewed / domain-native | No row-specific failure recorded. | plant exchange offer form and member marketplace surface with plant details, pickup timing, owner contact, and submitted offer state |
| `b25-v4-row-007-garden-export-custom-schemas-0` | Garden Club | `garden-export-custom-schemas` | owner | B13_ext_garden_club_garden-export-custom-schemas_start | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B13/screenshots/B13_ext_garden_club_garden-export-custom-schemas_start.png` | `ec5fff8f7944b...` | Plant exchange submission \| A submitted member form is ready for review and follow-up. \| Labeled fields \| Privacy checked \| Review handoff \| Review plant exchange submission \| Documents and data \| Documents, exports, imports, and transfer records. \| Garden export custom schema... | domain-native-reviewed / domain-native | No row-specific failure recorded. | export/import wizard with preview, redaction, checksum, transfer status, and rollback state |
| `b25-v4-row-008-garden-export-custom-schemas-1` | Garden Club | `garden-export-custom-schemas` | owner | B13_ext_garden_club_garden-export-custom-schemas_action | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B13/screenshots/B13_ext_garden_club_garden-export-custom-schemas_action.png` | `88121490c3198...` | Prepare export handoff \| Use this surface to package export scope, redaction, and handoff status. \| Redacted copy \| Checksum ready \| Exportable \| Details \| Scope, redaction, checksum, and handoff destination are included. \| Member outcome \| The export package can be inspected ... | domain-native-reviewed / domain-native | No row-specific failure recorded. | export/import wizard with preview, redaction, checksum, transfer status, and rollback state |
| `b25-v4-row-009-garden-export-custom-schemas-2` | Garden Club | `garden-export-custom-schemas` | owner | B13_ext_garden_club_garden-export-custom-schemas_complete | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B13/screenshots/B13_ext_garden_club_garden-export-custom-schemas_complete.png` | `cd83b521e0ea7...` | Plant exchange submission \| A submitted member form is ready for review and follow-up. \| Labeled fields \| Privacy checked \| Review handoff \| Review plant exchange submission \| Documents and data \| Documents, exports, imports, and transfer records. \| Garden export custom schema... | domain-native-reviewed / domain-native | No row-specific failure recorded. | export/import wizard with preview, redaction, checksum, transfer status, and rollback state |
| `b25-v4-row-010-book-nomination-0` | Neighborhood Book Club | `book-nomination` | member | B14_ext_book_club_book-nomination_start | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_book_club_book-nomination_start.png` | `4e4e9b1d35b93...` | Discussion message \| Member communication stays scoped to the community relationship. \| Private by default \| Membership scoped \| Ready \| Post message \| Member tools \| Useful actions for this community. \| Book nomination \| Member form captures labeled details, privacy choices, ... | domain-native-reviewed / domain-native | No row-specific failure recorded. | book club reading/voting surface with nominations, vote state, selected book, meeting context, and discussion |
| `b25-v4-row-011-book-nomination-1` | Neighborhood Book Club | `book-nomination` | member | B14_ext_book_club_book-nomination_action | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_book_club_book-nomination_action.png` | `0644e15ad1c93...` | Submit member form \| Use this surface to submit structured member details. \| Labeled fields \| Privacy checked \| Review handoff \| Details \| Required fields, privacy choices, and reviewer handoff are included. \| Member outcome \| The submission is routed to the reviewer with prot... | domain-native-reviewed / domain-native | No row-specific failure recorded. | book club reading/voting surface with nominations, vote state, selected book, meeting context, and discussion |
| `b25-v4-row-012-book-nomination-2` | Neighborhood Book Club | `book-nomination` | member | B14_ext_book_club_book-nomination_complete | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_book_club_book-nomination_complete.png` | `b9a2aaf99400e...` | Member tools \| Useful actions for this community. \| Book nomination \| Member form captures labeled details, privacy choices, and reviewer handoff. \| Labeled fields \| Privacy checked \| Review handoff \| Record saved \| The community record is saved. \| Saved \| Book vote \| Record v... | domain-native-reviewed / domain-native | No row-specific failure recorded. | book club reading/voting surface with nominations, vote state, selected book, meeting context, and discussion |
| `b25-v4-row-013-book-vote-0` | Neighborhood Book Club | `book-vote` | member | B14_ext_book_club_book-vote_start | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_book_club_book-vote_start.png` | `b9a2aaf99400e...` | Member tools \| Useful actions for this community. \| Book nomination \| Member form captures labeled details, privacy choices, and reviewer handoff. \| Labeled fields \| Privacy checked \| Review handoff \| Record saved \| The community record is saved. \| Saved \| Book vote \| Record v... | domain-native-reviewed / domain-native | No row-specific failure recorded. | book club reading/voting surface with nominations, vote state, selected book, meeting context, and discussion |
| `b25-v4-row-014-book-vote-1` | Neighborhood Book Club | `book-vote` | member | B14_ext_book_club_book-vote_action | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_book_club_book-vote_action.png` | `6c3961b9a5aa6...` | Submit member form \| Use this surface to submit structured member details. \| Labeled fields \| Privacy checked \| Review handoff \| Details \| Required fields, privacy choices, and reviewer handoff are included. \| Member outcome \| The submission is routed to the reviewer with prot... | domain-native-reviewed / domain-native | No row-specific failure recorded. | book club reading/voting surface with nominations, vote state, selected book, meeting context, and discussion |
| `b25-v4-row-015-book-vote-2` | Neighborhood Book Club | `book-vote` | member | B14_ext_book_club_book-vote_complete | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_book_club_book-vote_complete.png` | `d13f4363cc2a3...` | Member tools \| Useful actions for this community. \| Book nomination \| Member form captures labeled details, privacy choices, and reviewer handoff. \| Labeled fields \| Privacy checked \| Review handoff \| Record saved \| The community record is saved. \| Saved \| Book vote \| Local pa... | domain-native-reviewed / domain-native | No row-specific failure recorded. | book club reading/voting surface with nominations, vote state, selected book, meeting context, and discussion |
| `b25-v4-row-016-book-meeting-rsvp-0` | Neighborhood Book Club | `book-meeting-rsvp` | member | B14_ext_book_club_book-meeting-rsvp_start | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_book_club_book-meeting-rsvp_start.png` | `ce2cee7a160eb...` | Meeting event RSVP \| Event details include date, location, capacity, and attendance. \| This week \| Community venue \| Capacity tracked \| RSVP to event \| Documents and data \| Documents, exports, imports, and transfer records. \| Book export metadata \| You can review the current d... | domain-native-reviewed / domain-native | No row-specific failure recorded. | event detail with schedule, location, capacity/status, RSVP action, and result state |
| `b25-v4-row-017-book-meeting-rsvp-1` | Neighborhood Book Club | `book-meeting-rsvp` | member | B14_ext_book_club_book-meeting-rsvp_action | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_book_club_book-meeting-rsvp_action.png` | `8752032410567...` | Coordinate attendance \| Use this surface to publish event details, capacity, and attendance state. \| This week \| Community venue \| Capacity tracked \| Details \| Date, location, capacity, and attendee state are included. \| Member outcome \| Attendance, capacity, and reminders upd... | domain-native-reviewed / domain-native | No row-specific failure recorded. | event detail with schedule, location, capacity/status, RSVP action, and result state |
| `b25-v4-row-018-book-meeting-rsvp-2` | Neighborhood Book Club | `book-meeting-rsvp` | member | B14_ext_book_club_book-meeting-rsvp_complete | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_book_club_book-meeting-rsvp_complete.png` | `f2ba338c55a85...` | Meeting event RSVP \| Event details include date, location, capacity, and attendance. \| This week \| Community venue \| Capacity tracked \| RSVP confirmed \| Attendance, capacity, and confirmation details are up to date. \| Going \| Documents and data \| Documents, exports, imports, a... | domain-native-reviewed / domain-native | No row-specific failure recorded. | event detail with schedule, location, capacity/status, RSVP action, and result state |
| `b25-v4-row-019-book-discussion-message-0` | Neighborhood Book Club | `book-discussion-message` | member | B14_ext_book_club_book-discussion-message_start | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_book_club_book-discussion-message_start.png` | `e459e2823b4f0...` | Discussion message \| Member communication stays scoped to the community relationship. \| Private by default \| Membership scoped \| Ready \| Post message \| Member tools \| Useful actions for this community. \| Book nomination \| Member form captures labeled details, privacy choices, ... | domain-native-reviewed / domain-native | No row-specific failure recorded. | inbox, message thread, connection card, invite, or block-state surface |
| `b25-v4-row-020-book-discussion-message-1` | Neighborhood Book Club | `book-discussion-message` | member | B14_ext_book_club_book-discussion-message_action | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_book_club_book-discussion-message_action.png` | `5e078b9e62bee...` | Update member channel \| Use this surface to change a member communication or relationship setting. \| Private by default \| Membership scoped \| Ready \| Details \| Member channel, relationship, and preference details are included. \| Member outcome \| The communication or relationsh... | domain-native-reviewed / domain-native | No row-specific failure recorded. | inbox, message thread, connection card, invite, or block-state surface |
| `b25-v4-row-021-book-discussion-message-2` | Neighborhood Book Club | `book-discussion-message` | member | B14_ext_book_club_book-discussion-message_complete | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_book_club_book-discussion-message_complete.png` | `2ee96485431c1...` | Discussion message \| Member communication stays scoped to the community relationship. \| Private by default \| Membership scoped \| Ready \| Setting saved \| The member setting is up to date. \| Verified \| Member tools \| Useful actions for this community. \| Book nomination \| Member ... | domain-native-reviewed / domain-native | No row-specific failure recorded. | inbox, message thread, connection card, invite, or block-state surface |
| `b25-v4-row-022-book-selection-publish-0` | Neighborhood Book Club | `book-selection-publish` | owner | B14_ext_book_club_book-selection-publish_start | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_book_club_book-selection-publish_start.png` | `39bd49476089b...` | Selected-book publishing \| Member form captures labeled details, privacy choices, and reviewer handoff. \| Members \| Today \| Inbox + push \| Publish selection \| Search, AI answer, and digest \| Generate cited answer \| Upcoming events \| Dates, capacity, and attendance actions. \| M... | domain-native-reviewed / domain-native | No row-specific failure recorded. | announcement feed/composer with audience, author, timestamp, body, and receiver state |
| `b25-v4-row-023-book-selection-publish-1` | Neighborhood Book Club | `book-selection-publish` | owner | B14_ext_book_club_book-selection-publish_action | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_book_club_book-selection-publish_action.png` | `a5f772a45aa20...` | Send community notice \| Use this surface to send a scoped announcement to the selected audience. \| Members \| Today \| Inbox + push \| Details \| Message, audience, preview, and delivery channel are included. \| Member outcome \| The announcement appears in the member inbox and noti... | domain-native-reviewed / domain-native | No row-specific failure recorded. | announcement feed/composer with audience, author, timestamp, body, and receiver state |
| `b25-v4-row-024-book-selection-publish-2` | Neighborhood Book Club | `book-selection-publish` | owner | B14_ext_book_club_book-selection-publish_complete | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_book_club_book-selection-publish_complete.png` | `cac0c576c5fca...` | Selected-book publishing \| Member form captures labeled details, privacy choices, and reviewer handoff. \| Members \| Today \| Inbox + push \| Update sent \| The update is available to the selected audience. \| Sent \| Search, AI answer, and digest \| Generate cited answer \| Upcoming ... | domain-native-reviewed / domain-native | No row-specific failure recorded. | announcement feed/composer with audience, author, timestamp, body, and receiver state |
| `b25-v4-row-025-book-search-ai-digest-0` | Neighborhood Book Club | `book-search-ai-digest` | member | B14_ext_book_club_book-search-ai-digest_start | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_book_club_book-search-ai-digest_start.png` | `fb4577aec43a6...` | Search, AI answer, and digest \| Member form captures labeled details, privacy choices, and reviewer handoff. \| Members \| Today \| Inbox + push \| Generate cited answer \| Upcoming events \| Dates, capacity, and attendance actions. \| Meeting event RSVP \| Event details include date,... | domain-native-reviewed / domain-native | No row-specific failure recorded. | search/AI answer surface with query, result, citation, source, and follow-up action |
| `b25-v4-row-026-book-search-ai-digest-1` | Neighborhood Book Club | `book-search-ai-digest` | member | B14_ext_book_club_book-search-ai-digest_action | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_book_club_book-search-ai-digest_action.png` | `4a6922846596d...` | Send community notice \| Use this surface to send a scoped announcement to the selected audience. \| Members \| Today \| Inbox + push \| Details \| Message, audience, preview, and delivery channel are included. \| Member outcome \| The announcement appears in the member inbox and noti... | domain-native-reviewed / domain-native | No row-specific failure recorded. | search/AI answer surface with query, result, citation, source, and follow-up action |
| `b25-v4-row-027-book-search-ai-digest-2` | Neighborhood Book Club | `book-search-ai-digest` | member | B14_ext_book_club_book-search-ai-digest_complete | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_book_club_book-search-ai-digest_complete.png` | `d554a18d65b96...` | Search, AI answer, and digest \| Member form captures labeled details, privacy choices, and reviewer handoff. \| Members \| Today \| Inbox + push \| Update sent \| The update is available to the selected audience. \| Sent \| Upcoming events \| Dates, capacity, and attendance actions. \|... | domain-native-reviewed / domain-native | No row-specific failure recorded. | search/AI answer surface with query, result, citation, source, and follow-up action |
| `b25-v4-row-028-book-export-metadata-0` | Neighborhood Book Club | `book-export-metadata` | owner | B14_ext_book_club_book-export-metadata_start | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_book_club_book-export-metadata_start.png` | `7ed4ac4dbc60a...` | Book export metadata \| Data package includes scope, protected fields, and handoff status. \| No ad shown \| Preference saved \| Receipt ready \| Generate export \| Messages and connections \| Member communication and relationship controls. \| Discussion message \| A member communicati... | domain-native-reviewed / domain-native | No row-specific failure recorded. | export/import wizard with preview, redaction, checksum, transfer status, and rollback state |
| `b25-v4-row-029-book-export-metadata-1` | Neighborhood Book Club | `book-export-metadata` | owner | B14_ext_book_club_book-export-metadata_action | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_book_club_book-export-metadata_action.png` | `30b2056311a24...` | Prepare export handoff \| Use this surface to package export scope, redaction, and handoff status. \| No ad shown \| Preference saved \| Receipt ready \| Details \| Scope, redaction, checksum, and handoff destination are included. \| Member outcome \| The export package can be inspect... | domain-native-reviewed / domain-native | No row-specific failure recorded. | export/import wizard with preview, redaction, checksum, transfer status, and rollback state |
| `b25-v4-row-030-book-export-metadata-2` | Neighborhood Book Club | `book-export-metadata` | owner | B14_ext_book_club_book-export-metadata_complete | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_book_club_book-export-metadata_complete.png` | `3842109f13c4e...` | Book export metadata \| Data package includes scope, protected fields, and handoff status. \| No ad shown \| Preference saved \| Receipt ready \| Data package ready \| The data package is ready with protected fields handled. \| Ready \| Messages and connections \| Member communication ... | domain-native-reviewed / domain-native | No row-specific failure recorded. | export/import wizard with preview, redaction, checksum, transfer status, and rollback state |
| `b25-v4-row-031-soccer-guardian-join-approval-0` | Riverside Youth Soccer | `soccer-guardian-join-approval` | guardian | B14_ext_youth_soccer_soccer-guardian-join-approval_start | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_youth_soccer_soccer-guardian-join-approval_start.png` | `d274220e13633...` | Guardian join and approval \| Submitted details are ready for a decision and member follow-up. \| Needs decision \| Private notes \| Member notified \| Approve request \| Documents and data \| Documents, exports, imports, and transfer records. \| Protected minor-data redaction \| You c... | domain-native-reviewed / domain-native | No row-specific failure recorded. | request detail and admin review queue with submitted data, decision action, status, and notification |
| `b25-v4-row-032-soccer-guardian-join-approval-1` | Riverside Youth Soccer | `soccer-guardian-join-approval` | guardian | B14_ext_youth_soccer_soccer-guardian-join-approval_action | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_youth_soccer_soccer-guardian-join-approval_action.png` | `f9c421ee71cf9...` | Resolve member request \| Use this surface to record the decision and member follow-up. \| Needs decision \| Private notes \| Member notified \| Details \| Request details, decision, and follow-up note are included. \| Member outcome \| The decision is saved with the next step visible... | domain-native-reviewed / domain-native | No row-specific failure recorded. | request detail and admin review queue with submitted data, decision action, status, and notification |
| `b25-v4-row-033-soccer-guardian-join-approval-2` | Riverside Youth Soccer | `soccer-guardian-join-approval` | guardian | B14_ext_youth_soccer_soccer-guardian-join-approval_complete | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_youth_soccer_soccer-guardian-join-approval_complete.png` | `2f84927eab8c9...` | Guardian join and approval \| Submitted details are ready for a decision and member follow-up. \| Needs decision \| Private notes \| Member notified \| Decision saved \| The decision is saved and ready for member follow-up. \| Decided \| Documents and data \| Documents, exports, import... | domain-native-reviewed / domain-native | No row-specific failure recorded. | request detail and admin review queue with submitted data, decision action, status, and notification |
| `b25-v4-row-034-soccer-team-roster-0` | Riverside Youth Soccer | `soccer-team-roster` | coach | B14_ext_youth_soccer_soccer-team-roster_start | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_youth_soccer_soccer-team-roster_start.png` | `8230bbf0e2c8e...` | Protected minor-data redaction \| You can review the current details without changing them. \| Redacted copy \| Checksum ready \| Exportable \| Read only \| Youth soccer export metadata \| Data package includes scope, protected fields, and handoff status. \| No ad shown \| Preference s... | domain-native-reviewed / domain-native | No row-specific failure recorded. | team roster/schedule surface with role-filtered member details and protected-data treatment |
| `b25-v4-row-035-soccer-team-roster-1` | Riverside Youth Soccer | `soccer-team-roster` | coach | B14_ext_youth_soccer_soccer-team-roster_action | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_youth_soccer_soccer-team-roster_action.png` | `4bc6451869607...` | Submit member form \| Use this surface to submit structured member details. \| Labeled fields \| Privacy checked \| Review handoff \| Details \| Required fields, privacy choices, and reviewer handoff are included. \| Member outcome \| The submission is routed to the reviewer with prot... | domain-native-reviewed / domain-native | No row-specific failure recorded. | team roster/schedule surface with role-filtered member details and protected-data treatment |
| `b25-v4-row-036-soccer-team-roster-2` | Riverside Youth Soccer | `soccer-team-roster` | coach | B14_ext_youth_soccer_soccer-team-roster_complete | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_youth_soccer_soccer-team-roster_complete.png` | `939ac73d9bc07...` | Youth soccer export metadata \| Data package includes scope, protected fields, and handoff status. \| No ad shown \| Preference saved \| Receipt ready \| Generate export \| Member tools \| Useful actions for this community. \| Team and roster view \| Member form captures labeled detail... | domain-native-reviewed / domain-native | No row-specific failure recorded. | team roster/schedule surface with role-filtered member details and protected-data treatment |
| `b25-v4-row-037-soccer-minor-redaction-0` | Riverside Youth Soccer | `soccer-minor-redaction` | guardian | B14_ext_youth_soccer_soccer-minor-redaction_start | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_youth_soccer_soccer-minor-redaction_start.png` | `6174e481c985e...` | Protected minor-data redaction \| Data package includes scope, protected fields, and handoff status. \| Redacted copy \| Checksum ready \| Exportable \| Preview redaction \| Youth soccer export metadata \| You can review the current details without changing them. \| No ad shown \| Pref... | domain-native-reviewed / domain-native | No row-specific failure recorded. | protected youth roster/profile surface with minor-data redaction, guardian visibility, and coach-only detail state |
| `b25-v4-row-038-soccer-minor-redaction-1` | Riverside Youth Soccer | `soccer-minor-redaction` | guardian | B14_ext_youth_soccer_soccer-minor-redaction_action | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_youth_soccer_soccer-minor-redaction_action.png` | `4f66cd7b27c38...` | Prepare export handoff \| Use this surface to package export scope, redaction, and handoff status. \| Redacted copy \| Checksum ready \| Exportable \| Details \| Scope, redaction, checksum, and handoff destination are included. \| Member outcome \| The export package can be inspected ... | domain-native-reviewed / domain-native | No row-specific failure recorded. | protected youth roster/profile surface with minor-data redaction, guardian visibility, and coach-only detail state |
| `b25-v4-row-039-soccer-minor-redaction-2` | Riverside Youth Soccer | `soccer-minor-redaction` | guardian | B14_ext_youth_soccer_soccer-minor-redaction_complete | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_youth_soccer_soccer-minor-redaction_complete.png` | `38727c8b383cb...` | Protected minor-data redaction \| Data package includes scope, protected fields, and handoff status. \| Redacted copy \| Checksum ready \| Exportable \| Data package ready \| The data package is ready with protected fields handled. \| Ready \| Youth soccer export metadata \| You can re... | domain-native-reviewed / domain-native | No row-specific failure recorded. | protected youth roster/profile surface with minor-data redaction, guardian visibility, and coach-only detail state |
| `b25-v4-row-040-soccer-registration-payment-0` | Riverside Youth Soccer | `soccer-registration-payment` | guardian | B14_ext_youth_soccer_soccer-registration-payment_start | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_youth_soccer_soccer-registration-payment_start.png` | `2f1f6e7e7c291...` | Registration payment \| Payment details include amount, payer, and receipt destination. \| Amount ready \| Receipt saved \| Member-owned \| Pay and save receipt \| Requests and approvals \| Requests that need a decision or member follow-up. \| Guardian join and approval \| A decision u... | domain-native-reviewed / domain-native | No row-specific failure recorded. | payment or donation flow with amount, payer context, receipt, entitlement/status, and audit trail |

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
- Critique for `b25-v4-row-010-book-nomination-0` names visible UI elements, visible text, persona `member`, workflow `book-nomination`, and the exact product UX issue.
- Primary surface for `book-nomination` is documented as `book club reading/voting surface with nominations, vote state, selected book, meeting context, and discussion` or another explicit domain-native surface.
- After-screenshot visible text proves every required semantic surface group for `book-nomination`.
- Screen row `b25-v4-row-011-book-nomination-1` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-011-book-nomination-1` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-011-book-nomination-1` names visible UI elements, visible text, persona `member`, workflow `book-nomination`, and the exact product UX issue.
- Screen row `b25-v4-row-012-book-nomination-2` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-012-book-nomination-2` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-012-book-nomination-2` names visible UI elements, visible text, persona `member`, workflow `book-nomination`, and the exact product UX issue.

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

## B25-RT-002-b25-c02-community-product-docs-complete

| Field | Value |
| --- | --- |
| Severity | major |
| Priority | P1 |
| Status | open |
| Review run | `b25-v4-pass-9` |
| Source criterion | `b25-c02-community-product-docs-complete` |
| Source findings | B25-WORKFLOW-LIFECYCLE-INCOMPLETE |
| Title | Every community has a review-ready product experience doc |
| Direct question | Does every reviewed community/test app have a current, community-specific Product Docs V2 experience spec that defines the rich product experience before UX remediation is judged? |
| Why it failed | Community-specific Product Docs V2 experience specs are missing, thin, placeholder-filled, or not linked to the reviewed screens. Missing evidence fields: productDocCoverage. |
| Required outcome | Create or update Product Docs V2 community experience specs before remediation continues, then judge screens against those specs. |
| Remediation mode | `product-spec-update-before-ui-remediation` |
| Worker readiness | ready for product documentation update; UI remediation is blocked until the community product experience spec is complete |
| First required step | Complete productDocRepairWorkItems so each affected community has a review-ready Product Docs V2 experience spec with domain-native surfaces and workflow-to-surface mapping. |

### Problem Statement

B25 is trying to judge production UX without a complete community-specific product experience spec for every reviewed community/test app.

### Root Cause Hypothesis

The desired product experience was described only through workflows/screenshots after implementation, so the UI worker lacked a rich community product target to build against.

### Target Experience

Each reviewed community should have a Product Docs V2 experience spec that defines the product promise, personas/jobs, IA, home experience, domain-native surfaces, workflow mappings, persona states, seed content, visual standard, and B25 review log before UI remediation starts.

### UX Principles
- Define the target product before judging screenshots.
- Make UI remediation traceable to community-specific personas, jobs-to-be-done, and domain-native surfaces.
- Do not let workflow implementation evidence substitute for product experience requirements.

### Concrete Improvements
- Create or update one community product experience doc per reviewed community/test app under `docs/Product Docs V2/Community Examples/`.
- Use all ten B25 community product experience sections and remove placeholders or thin generic copy.
- Map each workflow/persona to a domain-native product surface and B25 acceptance evidence before assigning UI remediation.

### Implementation Guidance
- Product doc coverage rows for every reviewed community/test app.
- Updated Product Docs V2 community experience docs with hashes, paths, required sections, and no placeholders.
- B25 review/remediation log entries showing the current screenshots will be judged against each product spec.

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
- community app product requirements personas jobs to be done template
- mobile community app information architecture announcements events messages examples
- product experience specification domain native surfaces workflow mapping examples

### Implementation Blocked By
- The judge cannot verify production-grade UX without a community-specific product experience spec.
- UI workers need the spec to know the rich product surface they are supposed to build.

### Likely Files / Widgets
- `app/apps/loom_communities_demo/lib/main.dart`
- `app/apps/loom_communities_demo/test/b21_b25_production_ux_test.dart`
- `docs/Build Plan V2/Evidence/B25/production-ux-blueprint.md`
- `docs/Build Plan V2/Evidence/B25/independent-production-ux-review.json`
- `docs/Build Plan V2/Evidence/B25/product-ux-screen-review-matrix.md`
- `docs/Product Docs V2/Community Examples/`
- `docs/Build Plan V2/Skill/references/community-product-experience-template.md`
- `app/packages/tooling/loom_ux_judges/lib/loom_ux_judges.dart`

### Concrete Acceptance Criteria
- Do not use screenshots alone as the source of truth for desired product experience.
- Do not proceed to UI remediation when a reviewed community has no product experience spec.
- Do not satisfy this criterion with a generic template that could apply unchanged to another community.

### Affected Evidence
- `docs/Product Docs V2/Community Examples/<community>-product-experience.md`
- `independent-production-ux-review.json productDocCoverage`
- `independent-production-ux-review.md community product experience docs table`
- `production-ux-criteria-scorecard.json/.md`

### Evidence To Collect
- Product doc coverage rows for every reviewed community/test app.
- Updated Product Docs V2 community experience docs with hashes, paths, required sections, and no placeholders.
- B25 review/remediation log entries showing the current screenshots will be judged against each product spec.

### Acceptance Checks
- Do not use screenshots alone as the source of truth for desired product experience.
- Do not proceed to UI remediation when a reviewed community has no product experience spec.
- Do not satisfy this criterion with a generic template that could apply unchanged to another community.

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

## B25-RT-003-b25-c03-production-grade-experience

| Field | Value |
| --- | --- |
| Severity | major |
| Priority | P1 |
| Status | open |
| Review run | `b25-v4-pass-9` |
| Source criterion | `b25-c03-production-grade-experience` |
| Source findings | B25-WORKFLOW-LIFECYCLE-INCOMPLETE |
| Title | Reviewer can state the experience feels production-grade |
| Direct question | Does the whole experience feel like a real production community app for the target users, not merely an implemented workflow harness? |
| Why it failed | holistic direct-question answers are missing, weak, partial, or blocking: b25-holistic-production-grade, b25-holistic-modern-intentional, b25-holistic-community-ia, b25-holistic-layout-defects. |
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
| Does the whole experience feel like a real production community app for the target users, not merely an implemented workflow harness? | holistic | 35 | The review cannot claim production-grade UX while workflow/persona lifecycle evidence, direct-question evidence, or screenshot visual inspection is incomplete/failing. | Complete workflow/persona coverage, lifecycle scorecards, and remediate visual/layout failures before claiming production-grade UX. |
| Is the UI modern, easy to use, easy to navigate, and visually appealing for the target persona? | holistic | 40 | 0 rows use non-screen visible text sources, 62 lifecycle scorecards fail, and 0 rows have visual/layout blockers, so the judge cannot make a reliable modern-UI claim. | Use screenshot-derived visible text, fix incomplete workflow lifecycles, and fix detected checklist, repeated-card, thin-content, or weak-identity visual blockers before rerunning the judge. |
| Is the overall information architecture organized around community content and real jobs-to-be-done instead of workflow lists or validation surfaces? | holistic | 45 | Failing workflow/persona lifecycle scorecards or visual blockers prevent a holistic community IA pass. | Replace incomplete workflow-card UX with lifecycle-complete domain-native community sections and rerun scorecards. |
| Does the visible UI avoid blocking or major overlap, clipping, crowding, default-scaffold, repeated-card, checklist-modal, and thin-content defects? | holistic | 45 | The judge cannot clear layout/content defects while row-level evidence remains incomplete, unsupported, or visually failing. | Complete screenshot-backed review rows, fix incomplete workflow lifecycles, and remediate any row-level layout/content defects. |

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

## B25-RT-004-b25-c04-modern-intentional-ui

| Field | Value |
| --- | --- |
| Severity | major |
| Priority | P1 |
| Status | open |
| Review run | `b25-v4-pass-9` |
| Source criterion | `b25-c04-modern-intentional-ui` |
| Source findings | B25-WORKFLOW-LIFECYCLE-INCOMPLETE |
| Title | UI looks modern and intentionally designed |
| Direct question | Is the UI modern, easy to use, easy to navigate, and visually appealing for the target persona? |
| Why it failed | holistic direct-question answers are missing, weak, partial, or blocking: b25-holistic-production-grade, b25-holistic-modern-intentional, b25-holistic-community-ia, b25-holistic-layout-defects. |
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
| Does the whole experience feel like a real production community app for the target users, not merely an implemented workflow harness? | holistic | 35 | The review cannot claim production-grade UX while workflow/persona lifecycle evidence, direct-question evidence, or screenshot visual inspection is incomplete/failing. | Complete workflow/persona coverage, lifecycle scorecards, and remediate visual/layout failures before claiming production-grade UX. |
| Is the UI modern, easy to use, easy to navigate, and visually appealing for the target persona? | holistic | 40 | 0 rows use non-screen visible text sources, 62 lifecycle scorecards fail, and 0 rows have visual/layout blockers, so the judge cannot make a reliable modern-UI claim. | Use screenshot-derived visible text, fix incomplete workflow lifecycles, and fix detected checklist, repeated-card, thin-content, or weak-identity visual blockers before rerunning the judge. |
| Is the overall information architecture organized around community content and real jobs-to-be-done instead of workflow lists or validation surfaces? | holistic | 45 | Failing workflow/persona lifecycle scorecards or visual blockers prevent a holistic community IA pass. | Replace incomplete workflow-card UX with lifecycle-complete domain-native community sections and rerun scorecards. |
| Does the visible UI avoid blocking or major overlap, clipping, crowding, default-scaffold, repeated-card, checklist-modal, and thin-content defects? | holistic | 45 | The judge cannot clear layout/content defects while row-level evidence remains incomplete, unsupported, or visually failing. | Complete screenshot-backed review rows, fix incomplete workflow lifecycles, and remediate any row-level layout/content defects. |

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
| Review run | `b25-v4-pass-9` |
| Source criterion | `b25-c05-community-content-ia` |
| Source findings | B25-WORKFLOW-LIFECYCLE-INCOMPLETE |
| Title | Screens are organized around community content and jobs-to-be-done |
| Direct question | Is the overall information architecture organized around community content and real jobs-to-be-done instead of workflow lists or validation surfaces? |
| Why it failed | holistic direct-question answers are missing, weak, partial, or blocking: b25-holistic-production-grade, b25-holistic-modern-intentional, b25-holistic-community-ia, b25-holistic-layout-defects. |
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
| Does the whole experience feel like a real production community app for the target users, not merely an implemented workflow harness? | holistic | 35 | The review cannot claim production-grade UX while workflow/persona lifecycle evidence, direct-question evidence, or screenshot visual inspection is incomplete/failing. | Complete workflow/persona coverage, lifecycle scorecards, and remediate visual/layout failures before claiming production-grade UX. |
| Is the UI modern, easy to use, easy to navigate, and visually appealing for the target persona? | holistic | 40 | 0 rows use non-screen visible text sources, 62 lifecycle scorecards fail, and 0 rows have visual/layout blockers, so the judge cannot make a reliable modern-UI claim. | Use screenshot-derived visible text, fix incomplete workflow lifecycles, and fix detected checklist, repeated-card, thin-content, or weak-identity visual blockers before rerunning the judge. |
| Is the overall information architecture organized around community content and real jobs-to-be-done instead of workflow lists or validation surfaces? | holistic | 45 | Failing workflow/persona lifecycle scorecards or visual blockers prevent a holistic community IA pass. | Replace incomplete workflow-card UX with lifecycle-complete domain-native community sections and rerun scorecards. |
| Does the visible UI avoid blocking or major overlap, clipping, crowding, default-scaffold, repeated-card, checklist-modal, and thin-content defects? | holistic | 45 | The judge cannot clear layout/content defects while row-level evidence remains incomplete, unsupported, or visually failing. | Complete screenshot-backed review rows, fix incomplete workflow lifecycles, and remediate any row-level layout/content defects. |

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

## B25-RT-006-b25-c06-domain-native-primary-surfaces

| Field | Value |
| --- | --- |
| Severity | major |
| Priority | P1 |
| Status | open |
| Review run | `b25-v4-pass-9` |
| Source criterion | `b25-c06-domain-native-primary-surfaces` |
| Source findings | B25-WORKFLOW-LIFECYCLE-INCOMPLETE |
| Title | Primary workflows use domain-specific product surfaces |
| Direct question | For every workflow and persona, is the primary UI a domain-native product surface rather than a generic card, checklist modal, or metadata page? |
| Why it failed | Workflow/persona direct-question scorecards have missing or blocking answers: plant-exchange-submission/member, book-discussion-message/member, book-selection-publish/owner, soccer-minor-redaction/guardian, soccer-reminder-notification/guardian, hoa-member-document/member, hoa-architectural-request/owner, hoa-owner-notification/owner, mosque-announcement/owner, mosque-donor-visibility/donor, mosque-neutral-notification/member, chess-local-install-open/member, chess-route-home/member, chess-match-result/member, critique-submission/member, gear-loan-request/member, platform-message-stream/member. |
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
| Material navigation and information architecture | Material Design 3 / design-system | https://m3.material.io/components/navigation-drawer/overview<br>Also: https://m3.material.io/components/navigation-bar/overview | Organize screens by user jobs and destinations; keep primary actions visible and avoid exposing implementation taxonomy. |
| Apple HIG navigation and content organization | Apple Human Interface Guidelines / design-system | https://developer.apple.com/design/human-interface-guidelines/navigation | Make navigation predictable, content-centered, and appropriate for the user’s current task. |
| Inbox and message thread pattern | Material lists/text fields / pattern | https://m3.material.io/components/lists/overview<br>Also: https://m3.material.io/components/text-fields/overview | Copy an inbox/thread structure: sender, timestamp, message preview/body, reply field, invite/block state, and read/received state. |
| Feed item and composer pattern | Material cards/lists/text fields / pattern | https://m3.material.io/components/text-fields/overview<br>Also: https://m3.material.io/components/cards/overview<br>https://m3.material.io/components/lists/overview | Copy a feed/composer structure: audience, author, timestamp, body, attachments/status, publish action, and receiver read state. |
| Document list/detail pattern | Material lists/cards / pattern | https://m3.material.io/components/lists/overview | Copy a document library with title, category, audience, file metadata, access state, download/view action, and empty/error states. |
| Form validation and review pattern | U.S. Web Design System / design-system | https://designsystem.digital.gov/components/form/<br>Also: https://designsystem.digital.gov/components/alert/<br>https://design-system.service.gov.uk/components/error-summary/ | Copy a form flow with field labels, helper text, validation errors, review state, submit action, status, and protected-data treatment. |
| Match schedule and result pattern | Material lists/cards / pattern | https://m3.material.io/components/lists/overview | Copy a match surface with players, schedule/round, result entry, result state, and next action. |

### Reference Research Queries
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
- open source Flutter document-library mobile UI example GitHub
- document library/detail surface with title, audience, file metadata, and access state mobile UX pattern
- Material Design document library/detail surface with title, audience, file metadata, and access state mobile pattern
- open source Flutter form-review mobile UI example GitHub
- request detail and admin review queue with submitted data, decision action, status, and notification mobile UX pattern

### Implementation Blocked By
- Affected rows still use generic or missing persona data.
- Visible text is not proven from screenshot OCR/manual extraction.
- Screen-specific critiques are incomplete or reusable.
- Primary surface classification is incomplete or unverified.

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

### Affected Workflow/Persona Coverage

Showing 17 of 17 affected coverage rows. Full detail is in the JSON ticket.

| Coverage row | Status | Community | Workflow | Persona | Missing evidence | Screen rows | Target surface |
| --- | --- | --- | --- | --- | --- | ---: | --- |
| `b25-wp-002-plant-exchange-submission-community-garden-club-member` | `pass` | Garden Club | `plant-exchange-submission` | member |  | 3 | plant exchange offer form and member marketplace surface with plant details, pickup timing, owner contact, and submitted offer state |
| `b25-wp-007-book-discussion-message-community-book-club-member` | `pass` | Neighborhood Book Club | `book-discussion-message` | member |  | 3 | inbox, message thread, connection card, invite, or block-state surface |
| `b25-wp-008-book-selection-publish-community-book-club-owner` | `pass` | Neighborhood Book Club | `book-selection-publish` | owner |  | 3 | announcement feed/composer with audience, author, timestamp, body, and receiver state |
| `b25-wp-013-soccer-minor-redaction-community-youth-soccer-guardian` | `pass` | Riverside Youth Soccer | `soccer-minor-redaction` | guardian |  | 3 | protected youth roster/profile surface with minor-data redaction, guardian visibility, and coach-only detail state |
| `b25-wp-016-soccer-reminder-notification-community-youth-soccer-guardian` | `pass` | Riverside Youth Soccer | `soccer-reminder-notification` | guardian |  | 3 | notification inbox/detail surface with sender, audience, timestamp, message body, and receiver state |
| `b25-wp-019-hoa-member-document-community-hoa-member` | `pass` | Cedar Commons HOA | `hoa-member-document` | member |  | 3 | document library/detail surface with title, audience, file metadata, and access state |
| `b25-wp-021-hoa-architectural-request-community-hoa-owner` | `pass` | Cedar Commons HOA | `hoa-architectural-request` | owner |  | 3 | request detail and admin review queue with submitted data, decision action, status, and notification |
| `b25-wp-023-hoa-owner-notification-community-hoa-owner` | `pass` | Cedar Commons HOA | `hoa-owner-notification` | owner |  | 3 | notification inbox/detail surface with sender, audience, timestamp, message body, and receiver state |
| `b25-wp-025-mosque-announcement-community-mosque-owner` | `pass` | Masjid Nur | `mosque-announcement` | owner |  | 3 | announcement feed/composer with audience, author, timestamp, body, and receiver state |
| `b25-wp-028-mosque-donor-visibility-community-mosque-donor` | `pass` | Masjid Nur | `mosque-donor-visibility` | donor |  | 3 | donor privacy preference surface with visibility choice, donation context, confirmation, and receipt visibility state |
| `b25-wp-031-mosque-neutral-notification-community-mosque-member` | `pass` | Masjid Nur | `mosque-neutral-notification` | member |  | 3 | notification inbox/detail surface with sender, audience, timestamp, message body, and receiver state |
| `b25-wp-033-chess-local-install-open-community-chess-club-member` | `pass` | Chess Club | `chess-local-install-open` | member |  | 3 | match schedule/result surface with players, round, outcome, and next action |
| `b25-wp-034-chess-route-home-community-chess-club-member` | `pass` | Chess Club | `chess-route-home` | member |  | 3 | match schedule/result surface with players, round, outcome, and next action |
| `b25-wp-035-chess-match-result-community-chess-club-member` | `pass` | Chess Club | `chess-match-result` | member |  | 3 | match schedule/result surface with players, round, outcome, and next action |
| `b25-wp-037-critique-submission-community-camera-club-member` | `pass` | Camera Club | `critique-submission` | member |  | 3 | critique submission/review surface with image/work title, comments, reviewer state, and result |
| `b25-wp-038-gear-loan-request-community-camera-club-member` | `pass` | Camera Club | `gear-loan-request` | member |  | 3 | request detail and admin review queue with submitted data, decision action, status, and notification |
| `b25-wp-043-platform-message-stream-community-platform-social-member` | `pass` | Member Social Space | `platform-message-stream` | member |  | 3 | inbox, message thread, connection card, invite, or block-state surface |

### Affected Screen Rows

Showing 40 of 51 affected screen rows. Full detail is in the JSON ticket.

| Screen row | Community | Workflow | Persona | State | Screenshot | Hash | Visible text | Current surface | Exact UX failure | Target surface |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `b25-v4-row-004-plant-exchange-submission-0` | Garden Club | `plant-exchange-submission` | member | B13_ext_garden_club_plant-exchange-submission_start | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B13/screenshots/B13_ext_garden_club_plant-exchange-submission_start.png` | `7e5e418252089...` | Care and volunteers \| Private requests, volunteer shifts, and member support. \| Plant exchange submission \| Member form captures labeled details, privacy choices, and reviewer handoff. \| Labeled fields \| Privacy checked \| Review handoff \| Submit entry \| Documents and data \| Do... | domain-native-reviewed / domain-native | Ticket must prove the primary screen is a domain-native surface, not a generic card/checklist/metadata surface. | plant exchange offer form and member marketplace surface with plant details, pickup timing, owner contact, and submitted offer state |
| `b25-v4-row-005-plant-exchange-submission-1` | Garden Club | `plant-exchange-submission` | member | B13_ext_garden_club_plant-exchange-submission_action | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B13/screenshots/B13_ext_garden_club_plant-exchange-submission_action.png` | `ccd68c48ee915...` | Submit member form \| Use this surface to submit structured member details. \| Labeled fields \| Privacy checked \| Review handoff \| Details \| Required fields, privacy choices, and reviewer handoff are included. \| Member outcome \| The submission is routed to the reviewer with prot... | domain-native-reviewed / domain-native | Ticket must prove the primary screen is a domain-native surface, not a generic card/checklist/metadata surface. | plant exchange offer form and member marketplace surface with plant details, pickup timing, owner contact, and submitted offer state |
| `b25-v4-row-006-plant-exchange-submission-2` | Garden Club | `plant-exchange-submission` | member | B13_ext_garden_club_plant-exchange-submission_complete | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B13/screenshots/B13_ext_garden_club_plant-exchange-submission_complete.png` | `9155c4d4d2beb...` | Plant exchange submission \| Member form captures labeled details, privacy choices, and reviewer handoff. \| Labeled fields \| Privacy checked \| Review handoff \| Record saved \| The community record is saved. \| Saved \| Documents and data \| Documents, exports, imports, and transfer... | domain-native-reviewed / domain-native | Ticket must prove the primary screen is a domain-native surface, not a generic card/checklist/metadata surface. | plant exchange offer form and member marketplace surface with plant details, pickup timing, owner contact, and submitted offer state |
| `b25-v4-row-019-book-discussion-message-0` | Neighborhood Book Club | `book-discussion-message` | member | B14_ext_book_club_book-discussion-message_start | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_book_club_book-discussion-message_start.png` | `e459e2823b4f0...` | Discussion message \| Member communication stays scoped to the community relationship. \| Private by default \| Membership scoped \| Ready \| Post message \| Member tools \| Useful actions for this community. \| Book nomination \| Member form captures labeled details, privacy choices, ... | domain-native-reviewed / domain-native | Ticket must prove the primary screen is a domain-native surface, not a generic card/checklist/metadata surface. | inbox, message thread, connection card, invite, or block-state surface |
| `b25-v4-row-020-book-discussion-message-1` | Neighborhood Book Club | `book-discussion-message` | member | B14_ext_book_club_book-discussion-message_action | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_book_club_book-discussion-message_action.png` | `5e078b9e62bee...` | Update member channel \| Use this surface to change a member communication or relationship setting. \| Private by default \| Membership scoped \| Ready \| Details \| Member channel, relationship, and preference details are included. \| Member outcome \| The communication or relationsh... | domain-native-reviewed / domain-native | Ticket must prove the primary screen is a domain-native surface, not a generic card/checklist/metadata surface. | inbox, message thread, connection card, invite, or block-state surface |
| `b25-v4-row-021-book-discussion-message-2` | Neighborhood Book Club | `book-discussion-message` | member | B14_ext_book_club_book-discussion-message_complete | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_book_club_book-discussion-message_complete.png` | `2ee96485431c1...` | Discussion message \| Member communication stays scoped to the community relationship. \| Private by default \| Membership scoped \| Ready \| Setting saved \| The member setting is up to date. \| Verified \| Member tools \| Useful actions for this community. \| Book nomination \| Member ... | domain-native-reviewed / domain-native | Ticket must prove the primary screen is a domain-native surface, not a generic card/checklist/metadata surface. | inbox, message thread, connection card, invite, or block-state surface |
| `b25-v4-row-022-book-selection-publish-0` | Neighborhood Book Club | `book-selection-publish` | owner | B14_ext_book_club_book-selection-publish_start | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_book_club_book-selection-publish_start.png` | `39bd49476089b...` | Selected-book publishing \| Member form captures labeled details, privacy choices, and reviewer handoff. \| Members \| Today \| Inbox + push \| Publish selection \| Search, AI answer, and digest \| Generate cited answer \| Upcoming events \| Dates, capacity, and attendance actions. \| M... | domain-native-reviewed / domain-native | Ticket must prove the primary screen is a domain-native surface, not a generic card/checklist/metadata surface. | announcement feed/composer with audience, author, timestamp, body, and receiver state |
| `b25-v4-row-023-book-selection-publish-1` | Neighborhood Book Club | `book-selection-publish` | owner | B14_ext_book_club_book-selection-publish_action | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_book_club_book-selection-publish_action.png` | `a5f772a45aa20...` | Send community notice \| Use this surface to send a scoped announcement to the selected audience. \| Members \| Today \| Inbox + push \| Details \| Message, audience, preview, and delivery channel are included. \| Member outcome \| The announcement appears in the member inbox and noti... | domain-native-reviewed / domain-native | Ticket must prove the primary screen is a domain-native surface, not a generic card/checklist/metadata surface. | announcement feed/composer with audience, author, timestamp, body, and receiver state |
| `b25-v4-row-024-book-selection-publish-2` | Neighborhood Book Club | `book-selection-publish` | owner | B14_ext_book_club_book-selection-publish_complete | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_book_club_book-selection-publish_complete.png` | `cac0c576c5fca...` | Selected-book publishing \| Member form captures labeled details, privacy choices, and reviewer handoff. \| Members \| Today \| Inbox + push \| Update sent \| The update is available to the selected audience. \| Sent \| Search, AI answer, and digest \| Generate cited answer \| Upcoming ... | domain-native-reviewed / domain-native | Ticket must prove the primary screen is a domain-native surface, not a generic card/checklist/metadata surface. | announcement feed/composer with audience, author, timestamp, body, and receiver state |
| `b25-v4-row-037-soccer-minor-redaction-0` | Riverside Youth Soccer | `soccer-minor-redaction` | guardian | B14_ext_youth_soccer_soccer-minor-redaction_start | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_youth_soccer_soccer-minor-redaction_start.png` | `6174e481c985e...` | Protected minor-data redaction \| Data package includes scope, protected fields, and handoff status. \| Redacted copy \| Checksum ready \| Exportable \| Preview redaction \| Youth soccer export metadata \| You can review the current details without changing them. \| No ad shown \| Pref... | domain-native-reviewed / domain-native | Ticket must prove the primary screen is a domain-native surface, not a generic card/checklist/metadata surface. | protected youth roster/profile surface with minor-data redaction, guardian visibility, and coach-only detail state |
| `b25-v4-row-038-soccer-minor-redaction-1` | Riverside Youth Soccer | `soccer-minor-redaction` | guardian | B14_ext_youth_soccer_soccer-minor-redaction_action | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_youth_soccer_soccer-minor-redaction_action.png` | `4f66cd7b27c38...` | Prepare export handoff \| Use this surface to package export scope, redaction, and handoff status. \| Redacted copy \| Checksum ready \| Exportable \| Details \| Scope, redaction, checksum, and handoff destination are included. \| Member outcome \| The export package can be inspected ... | domain-native-reviewed / domain-native | Ticket must prove the primary screen is a domain-native surface, not a generic card/checklist/metadata surface. | protected youth roster/profile surface with minor-data redaction, guardian visibility, and coach-only detail state |
| `b25-v4-row-039-soccer-minor-redaction-2` | Riverside Youth Soccer | `soccer-minor-redaction` | guardian | B14_ext_youth_soccer_soccer-minor-redaction_complete | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_youth_soccer_soccer-minor-redaction_complete.png` | `38727c8b383cb...` | Protected minor-data redaction \| Data package includes scope, protected fields, and handoff status. \| Redacted copy \| Checksum ready \| Exportable \| Data package ready \| The data package is ready with protected fields handled. \| Ready \| Youth soccer export metadata \| You can re... | domain-native-reviewed / domain-native | Ticket must prove the primary screen is a domain-native surface, not a generic card/checklist/metadata surface. | protected youth roster/profile surface with minor-data redaction, guardian visibility, and coach-only detail state |
| `b25-v4-row-046-soccer-reminder-notification-0` | Riverside Youth Soccer | `soccer-reminder-notification` | guardian | B14_ext_youth_soccer_soccer-reminder-notification_start | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_youth_soccer_soccer-reminder-notification_start.png` | `331a9c02796bf...` | Reminder notification \| Member form captures labeled details, privacy choices, and reviewer handoff. \| Members \| Today \| Inbox + push \| Send reminder \| Upcoming events \| Dates, capacity, and attendance actions. \| Practice schedule \| This week \| Community venue \| Capacity track... | domain-native-reviewed / domain-native | Ticket must prove the primary screen is a domain-native surface, not a generic card/checklist/metadata surface. | notification inbox/detail surface with sender, audience, timestamp, message body, and receiver state |
| `b25-v4-row-047-soccer-reminder-notification-1` | Riverside Youth Soccer | `soccer-reminder-notification` | guardian | B14_ext_youth_soccer_soccer-reminder-notification_action | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_youth_soccer_soccer-reminder-notification_action.png` | `2a13662598256...` | Send community notice \| Use this surface to send a scoped announcement to the selected audience. \| Members \| Today \| Inbox + push \| Details \| Message, audience, preview, and delivery channel are included. \| Member outcome \| The announcement appears in the member inbox and noti... | domain-native-reviewed / domain-native | Ticket must prove the primary screen is a domain-native surface, not a generic card/checklist/metadata surface. | notification inbox/detail surface with sender, audience, timestamp, message body, and receiver state |
| `b25-v4-row-048-soccer-reminder-notification-2` | Riverside Youth Soccer | `soccer-reminder-notification` | guardian | B14_ext_youth_soccer_soccer-reminder-notification_complete | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_youth_soccer_soccer-reminder-notification_complete.png` | `4bea2d955fc4d...` | Reminder notification \| Member form captures labeled details, privacy choices, and reviewer handoff. \| Members \| Today \| Inbox + push \| Update sent \| The update is available to the selected audience. \| Sent \| Upcoming events \| Dates, capacity, and attendance actions. \| Practic... | domain-native-reviewed / domain-native | Ticket must prove the primary screen is a domain-native surface, not a generic card/checklist/metadata surface. | notification inbox/detail surface with sender, audience, timestamp, message body, and receiver state |
| `b25-v4-row-055-hoa-member-document-0` | Cedar Commons HOA | `hoa-member-document` | member | B14_ext_hoa_hoa-member-document_start | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_hoa_hoa-member-document_start.png` | `869e4870b741e...` | Committee decision \| Waiting for the request to be submitted first. \| Needs decision \| Private notes \| Member notified \| Waiting \| Documents and data \| Documents, exports, imports, and transfer records. \| Member-visible document \| Member form captures labeled details, privacy ... | domain-native-reviewed / domain-native | Ticket must prove the primary screen is a domain-native surface, not a generic card/checklist/metadata surface. | document library/detail surface with title, audience, file metadata, and access state |
| `b25-v4-row-056-hoa-member-document-1` | Cedar Commons HOA | `hoa-member-document` | member | B14_ext_hoa_hoa-member-document_action | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_hoa_hoa-member-document_action.png` | `764adb8f3c8c1...` | Submit member form \| Use this surface to submit structured member details. \| Labeled fields \| Privacy checked \| Review handoff \| Details \| Required fields, privacy choices, and reviewer handoff are included. \| Member outcome \| The submission is routed to the reviewer with prot... | domain-native-reviewed / domain-native | Ticket must prove the primary screen is a domain-native surface, not a generic card/checklist/metadata surface. | document library/detail surface with title, audience, file metadata, and access state |
| `b25-v4-row-057-hoa-member-document-2` | Cedar Commons HOA | `hoa-member-document` | member | B14_ext_hoa_hoa-member-document_complete | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_hoa_hoa-member-document_complete.png` | `2c36cfa02073e...` | Documents and data \| Documents, exports, imports, and transfer records. \| Member-visible document \| Member form captures labeled details, privacy choices, and reviewer handoff. \| Labeled fields \| Privacy checked \| Review handoff \| Record saved \| The community record is saved. ... | domain-native-reviewed / domain-native | Ticket must prove the primary screen is a domain-native surface, not a generic card/checklist/metadata surface. | document library/detail surface with title, audience, file metadata, and access state |
| `b25-v4-row-061-hoa-architectural-request-0` | Cedar Commons HOA | `hoa-architectural-request` | owner | B14_ext_hoa_hoa-architectural-request_start | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_hoa_hoa-architectural-request_start.png` | `1ef0e613dda2b...` | Architectural request \| Submitted details are ready for a decision and member follow-up. \| Labeled fields \| Privacy checked \| Review handoff \| Submit request \| Committee decision \| Waiting for the request to be submitted first. \| Needs decision \| Private notes \| Member notifie... | domain-native-reviewed / domain-native | Ticket must prove the primary screen is a domain-native surface, not a generic card/checklist/metadata surface. | request detail and admin review queue with submitted data, decision action, status, and notification |
| `b25-v4-row-062-hoa-architectural-request-1` | Cedar Commons HOA | `hoa-architectural-request` | owner | B14_ext_hoa_hoa-architectural-request_action | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_hoa_hoa-architectural-request_action.png` | `4312b28845953...` | Submit member form \| Use this surface to submit structured member details. \| Labeled fields \| Privacy checked \| Review handoff \| Details \| Required fields, privacy choices, and reviewer handoff are included. \| Member outcome \| The submission is routed to the reviewer with prot... | domain-native-reviewed / domain-native | Ticket must prove the primary screen is a domain-native surface, not a generic card/checklist/metadata surface. | request detail and admin review queue with submitted data, decision action, status, and notification |
| `b25-v4-row-063-hoa-architectural-request-2` | Cedar Commons HOA | `hoa-architectural-request` | owner | B14_ext_hoa_hoa-architectural-request_complete | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_hoa_hoa-architectural-request_complete.png` | `abe40d9d4df67...` | Architectural request \| Submitted details are ready for a decision and member follow-up. \| Labeled fields \| Privacy checked \| Review handoff \| Record saved \| The community record is saved. \| Saved \| Committee decision \| A decision update is ready with next steps. \| Needs decis... | domain-native-reviewed / domain-native | Ticket must prove the primary screen is a domain-native surface, not a generic card/checklist/metadata surface. | request detail and admin review queue with submitted data, decision action, status, and notification |
| `b25-v4-row-067-hoa-owner-notification-0` | Cedar Commons HOA | `hoa-owner-notification` | owner | B14_ext_hoa_hoa-owner-notification_start | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_hoa_hoa-owner-notification_start.png` | `f4a44ec8128eb...` | Owner notification \| Member form captures labeled details, privacy choices, and reviewer handoff. \| Members \| Today \| Inbox + push \| Send notification \| Giving \| Payments, donations, receipts, and member preferences. \| Dues payment \| A receipt or giving preference is ready to ... | domain-native-reviewed / domain-native | Ticket must prove the primary screen is a domain-native surface, not a generic card/checklist/metadata surface. | notification inbox/detail surface with sender, audience, timestamp, message body, and receiver state |
| `b25-v4-row-068-hoa-owner-notification-1` | Cedar Commons HOA | `hoa-owner-notification` | owner | B14_ext_hoa_hoa-owner-notification_action | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_hoa_hoa-owner-notification_action.png` | `e42577cde046f...` | Send community notice \| Use this surface to send a scoped announcement to the selected audience. \| Members \| Today \| Inbox + push \| Details \| Message, audience, preview, and delivery channel are included. \| Member outcome \| The announcement appears in the member inbox and noti... | domain-native-reviewed / domain-native | Ticket must prove the primary screen is a domain-native surface, not a generic card/checklist/metadata surface. | notification inbox/detail surface with sender, audience, timestamp, message body, and receiver state |
| `b25-v4-row-069-hoa-owner-notification-2` | Cedar Commons HOA | `hoa-owner-notification` | owner | B14_ext_hoa_hoa-owner-notification_complete | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_hoa_hoa-owner-notification_complete.png` | `077b830957cd1...` | Owner notification \| Member form captures labeled details, privacy choices, and reviewer handoff. \| Members \| Today \| Inbox + push \| Update sent \| The update is available to the selected audience. \| Sent \| Giving \| Payments, donations, receipts, and member preferences. \| Dues ... | domain-native-reviewed / domain-native | Ticket must prove the primary screen is a domain-native surface, not a generic card/checklist/metadata surface. | notification inbox/detail surface with sender, audience, timestamp, message body, and receiver state |
| `b25-v4-row-073-mosque-announcement-0` | Masjid Nur | `mosque-announcement` | owner | B14_ext_mosque_mosque-announcement_start | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_mosque_mosque-announcement_start.png` | `49ade4d070ee4...` | Public announcement \| Draft message includes audience, timing, and delivery details. \| Members \| Today \| Inbox + push \| Publish announcement \| Neutral care notification \| Waiting for the announcement to be sent. \| Waiting \| Announcement search and AI citation \| Upcoming events... | domain-native-reviewed / domain-native | Ticket must prove the primary screen is a domain-native surface, not a generic card/checklist/metadata surface. | announcement feed/composer with audience, author, timestamp, body, and receiver state |
| `b25-v4-row-074-mosque-announcement-1` | Masjid Nur | `mosque-announcement` | owner | B14_ext_mosque_mosque-announcement_action | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_mosque_mosque-announcement_action.png` | `839d0029c3b3c...` | Send community notice \| Use this surface to send a scoped announcement to the selected audience. \| Members \| Today \| Inbox + push \| Details \| Message, audience, preview, and delivery channel are included. \| Member outcome \| The announcement appears in the member inbox and noti... | domain-native-reviewed / domain-native | Ticket must prove the primary screen is a domain-native surface, not a generic card/checklist/metadata surface. | announcement feed/composer with audience, author, timestamp, body, and receiver state |
| `b25-v4-row-075-mosque-announcement-2` | Masjid Nur | `mosque-announcement` | owner | B14_ext_mosque_mosque-announcement_complete | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_mosque_mosque-announcement_complete.png` | `abc6198effb4f...` | Public announcement \| Draft message includes audience, timing, and delivery details. \| Members \| Today \| Inbox + push \| Announcement posted \| Members can now read the announcement in their community inbox. \| Sent \| Neutral care notification \| Waiting for the announcement to be... | domain-native-reviewed / domain-native | Ticket must prove the primary screen is a domain-native surface, not a generic card/checklist/metadata surface. | announcement feed/composer with audience, author, timestamp, body, and receiver state |
| `b25-v4-row-082-mosque-donor-visibility-0` | Masjid Nur | `mosque-donor-visibility` | donor | B14_ext_mosque_mosque-donor-visibility_start | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_mosque_mosque-donor-visibility_start.png` | `95a7103852c32...` | Volunteer signup \| Volunteer details include shift, availability, and protected contact. \| Open shift \| Contact protected \| Coordinator notified \| Signup saved \| The coordinator can review the signup and protected contact details. \| Saved \| Protected care request \| Care reques... | domain-native-reviewed / domain-native | Ticket must prove the primary screen is a domain-native surface, not a generic card/checklist/metadata surface. | donor privacy preference surface with visibility choice, donation context, confirmation, and receipt visibility state |
| `b25-v4-row-083-mosque-donor-visibility-1` | Masjid Nur | `mosque-donor-visibility` | donor | B14_ext_mosque_mosque-donor-visibility_action | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_mosque_mosque-donor-visibility_action.png` | `f91b89ad6006f...` | Submit member form \| Use this surface to submit structured member details. \| Labeled fields \| Privacy checked \| Review handoff \| Details \| Required fields, privacy choices, and reviewer handoff are included. \| Member outcome \| The submission is routed to the reviewer with prot... | domain-native-reviewed / domain-native | Ticket must prove the primary screen is a domain-native surface, not a generic card/checklist/metadata surface. | donor privacy preference surface with visibility choice, donation context, confirmation, and receipt visibility state |
| `b25-v4-row-084-mosque-donor-visibility-2` | Masjid Nur | `mosque-donor-visibility` | donor | B14_ext_mosque_mosque-donor-visibility_complete | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_mosque_mosque-donor-visibility_complete.png` | `a124717d4146f...` | Protected care request \| Care request keeps private details protected for the care team. \| Private details \| Care team \| Consent checked \| Submit request \| Member tools \| Useful actions for this community. \| Anonymous donor visibility \| Member form captures labeled details, pr... | domain-native-reviewed / domain-native | Ticket must prove the primary screen is a domain-native surface, not a generic card/checklist/metadata surface. | donor privacy preference surface with visibility choice, donation context, confirmation, and receipt visibility state |
| `b25-v4-row-091-mosque-neutral-notification-0` | Masjid Nur | `mosque-neutral-notification` | member | B14_ext_mosque_mosque-neutral-notification_start | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_mosque_mosque-neutral-notification_start.png` | `c30d324ad6bbb...` | Neutral care notification \| Member form captures labeled details, privacy choices, and reviewer handoff. \| Members \| Today \| Inbox + push \| Send notification \| Announcement search and AI citation \| Generate cited answer \| Upcoming events \| Dates, capacity, and attendance actio... | domain-native-reviewed / domain-native | Ticket must prove the primary screen is a domain-native surface, not a generic card/checklist/metadata surface. | notification inbox/detail surface with sender, audience, timestamp, message body, and receiver state |
| `b25-v4-row-092-mosque-neutral-notification-1` | Masjid Nur | `mosque-neutral-notification` | member | B14_ext_mosque_mosque-neutral-notification_action | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_mosque_mosque-neutral-notification_action.png` | `e42577cde046f...` | Send community notice \| Use this surface to send a scoped announcement to the selected audience. \| Members \| Today \| Inbox + push \| Details \| Message, audience, preview, and delivery channel are included. \| Member outcome \| The announcement appears in the member inbox and noti... | domain-native-reviewed / domain-native | Ticket must prove the primary screen is a domain-native surface, not a generic card/checklist/metadata surface. | notification inbox/detail surface with sender, audience, timestamp, message body, and receiver state |
| `b25-v4-row-093-mosque-neutral-notification-2` | Masjid Nur | `mosque-neutral-notification` | member | B14_ext_mosque_mosque-neutral-notification_complete | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_mosque_mosque-neutral-notification_complete.png` | `e4bc0bb7a7ec6...` | Neutral care notification \| Member form captures labeled details, privacy choices, and reviewer handoff. \| Members \| Today \| Inbox + push \| Update sent \| The update is available to the selected audience. \| Sent \| Announcement search and AI citation \| Generate cited answer \| Up... | domain-native-reviewed / domain-native | Ticket must prove the primary screen is a domain-native surface, not a generic card/checklist/metadata surface. | notification inbox/detail surface with sender, audience, timestamp, message body, and receiver state |
| `b25-v4-row-097-chess-local-install-open-0` | Chess Club | `chess-local-install-open` | member | B15_ext_chess_club_chess-local-install-open_start | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B15/screenshots/B15_ext_chess_club_chess-local-install-open_start.png` | `6ce055e8dc096...` | Arbitrary install and open \| Member form captures labeled details, privacy choices, and reviewer handoff. \| Labeled fields \| Privacy checked \| Review handoff \| Open community home \| Chess Club home \| Match result record \| Waiting for the member form to be submitted. \| Waiting ... | domain-native-reviewed / domain-native | Ticket must prove the primary screen is a domain-native surface, not a generic card/checklist/metadata surface. | match schedule/result surface with players, round, outcome, and next action |
| `b25-v4-row-098-chess-local-install-open-1` | Chess Club | `chess-local-install-open` | member | B15_ext_chess_club_chess-local-install-open_action | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B15/screenshots/B15_ext_chess_club_chess-local-install-open_action.png` | `9f9a333c2e240...` | Submit member form \| Use this surface to submit structured member details. \| Labeled fields \| Privacy checked \| Review handoff \| Details \| Required fields, privacy choices, and reviewer handoff are included. \| Member outcome \| The submission is routed to the reviewer with prot... | domain-native-reviewed / domain-native | Ticket must prove the primary screen is a domain-native surface, not a generic card/checklist/metadata surface. | match schedule/result surface with players, round, outcome, and next action |
| `b25-v4-row-099-chess-local-install-open-2` | Chess Club | `chess-local-install-open` | member | B15_ext_chess_club_chess-local-install-open_complete | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B15/screenshots/B15_ext_chess_club_chess-local-install-open_complete.png` | `a36bee30f0436...` | Arbitrary install and open \| Member form captures labeled details, privacy choices, and reviewer handoff. \| Labeled fields \| Privacy checked \| Review handoff \| Record saved \| The community record is saved. \| Saved \| Chess Club home \| Open community home \| Match result record \|... | domain-native-reviewed / domain-native | Ticket must prove the primary screen is a domain-native surface, not a generic card/checklist/metadata surface. | match schedule/result surface with players, round, outcome, and next action |
| `b25-v4-row-100-chess-route-home-0` | Chess Club | `chess-route-home` | member | B15_ext_chess_club_chess-route-home_start | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B15/screenshots/B15_ext_chess_club_chess-route-home_start.png` | `823c92dd81cce...` | Arbitrary install and open \| Member form captures labeled details, privacy choices, and reviewer handoff. \| Labeled fields \| Privacy checked \| Review handoff \| Record saved \| The community record is saved. \| Saved \| Chess Club home \| Open community home \| Match result record \|... | domain-native-reviewed / domain-native | Ticket must prove the primary screen is a domain-native surface, not a generic card/checklist/metadata surface. | match schedule/result surface with players, round, outcome, and next action |
| `b25-v4-row-101-chess-route-home-1` | Chess Club | `chess-route-home` | member | B15_ext_chess_club_chess-route-home_action | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B15/screenshots/B15_ext_chess_club_chess-route-home_action.png` | `0cb201660b15b...` | Submit member form \| Use this surface to submit structured member details. \| Labeled fields \| Privacy checked \| Review handoff \| Details \| Required fields, privacy choices, and reviewer handoff are included. \| Member outcome \| The submission is routed to the reviewer with prot... | domain-native-reviewed / domain-native | Ticket must prove the primary screen is a domain-native surface, not a generic card/checklist/metadata surface. | match schedule/result surface with players, round, outcome, and next action |
| `b25-v4-row-102-chess-route-home-2` | Chess Club | `chess-route-home` | member | B15_ext_chess_club_chess-route-home_complete | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B15/screenshots/B15_ext_chess_club_chess-route-home_complete.png` | `1ab0333e57acc...` | Arbitrary install and open \| Member form captures labeled details, privacy choices, and reviewer handoff. \| Labeled fields \| Privacy checked \| Review handoff \| Record saved \| The community record is saved. \| Saved \| Chess Club home \| Match result record \| Waiting for the membe... | domain-native-reviewed / domain-native | Ticket must prove the primary screen is a domain-native surface, not a generic card/checklist/metadata surface. | match schedule/result surface with players, round, outcome, and next action |
| `b25-v4-row-103-chess-match-result-0` | Chess Club | `chess-match-result` | member | B15_ext_chess_club_chess-match-result_start | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B15/screenshots/B15_ext_chess_club_chess-match-result_start.png` | `20c61a167b4bf...` | Arbitrary install and open \| Member form captures labeled details, privacy choices, and reviewer handoff. \| Labeled fields \| Privacy checked \| Review handoff \| Record saved \| The community record is saved. \| Saved \| Chess Club home \| Match result record \| Record match result \|... | domain-native-reviewed / domain-native | Ticket must prove the primary screen is a domain-native surface, not a generic card/checklist/metadata surface. | match schedule/result surface with players, round, outcome, and next action |

### Failing Workflow/Persona Scorecards

Showing 17 of 17 failing scorecards. Full detail is in the JSON ticket.

| Scorecard | Community | Workflow | Persona | Failed questions | Target surface |
| --- | --- | --- | --- | ---: | --- |
| `b25-wp-002-plant-exchange-submission-community-garden-club-member` | Garden Club | `plant-exchange-submission` | member | 2 | plant exchange offer form and member marketplace surface with plant details, pickup timing, owner contact, and submitted offer state |
| `b25-wp-007-book-discussion-message-community-book-club-member` | Neighborhood Book Club | `book-discussion-message` | member | 2 | inbox, message thread, connection card, invite, or block-state surface |
| `b25-wp-008-book-selection-publish-community-book-club-owner` | Neighborhood Book Club | `book-selection-publish` | owner | 2 | announcement feed/composer with audience, author, timestamp, body, and receiver state |
| `b25-wp-013-soccer-minor-redaction-community-youth-soccer-guardian` | Riverside Youth Soccer | `soccer-minor-redaction` | guardian | 2 | protected youth roster/profile surface with minor-data redaction, guardian visibility, and coach-only detail state |
| `b25-wp-016-soccer-reminder-notification-community-youth-soccer-guardian` | Riverside Youth Soccer | `soccer-reminder-notification` | guardian | 2 | notification inbox/detail surface with sender, audience, timestamp, message body, and receiver state |
| `b25-wp-019-hoa-member-document-community-hoa-member` | Cedar Commons HOA | `hoa-member-document` | member | 2 | document library/detail surface with title, audience, file metadata, and access state |
| `b25-wp-021-hoa-architectural-request-community-hoa-owner` | Cedar Commons HOA | `hoa-architectural-request` | owner | 2 | request detail and admin review queue with submitted data, decision action, status, and notification |
| `b25-wp-023-hoa-owner-notification-community-hoa-owner` | Cedar Commons HOA | `hoa-owner-notification` | owner | 2 | notification inbox/detail surface with sender, audience, timestamp, message body, and receiver state |
| `b25-wp-025-mosque-announcement-community-mosque-owner` | Masjid Nur | `mosque-announcement` | owner | 2 | announcement feed/composer with audience, author, timestamp, body, and receiver state |
| `b25-wp-028-mosque-donor-visibility-community-mosque-donor` | Masjid Nur | `mosque-donor-visibility` | donor | 2 | donor privacy preference surface with visibility choice, donation context, confirmation, and receipt visibility state |
| `b25-wp-031-mosque-neutral-notification-community-mosque-member` | Masjid Nur | `mosque-neutral-notification` | member | 2 | notification inbox/detail surface with sender, audience, timestamp, message body, and receiver state |
| `b25-wp-033-chess-local-install-open-community-chess-club-member` | Chess Club | `chess-local-install-open` | member | 2 | match schedule/result surface with players, round, outcome, and next action |
| `b25-wp-034-chess-route-home-community-chess-club-member` | Chess Club | `chess-route-home` | member | 2 | match schedule/result surface with players, round, outcome, and next action |
| `b25-wp-035-chess-match-result-community-chess-club-member` | Chess Club | `chess-match-result` | member | 2 | match schedule/result surface with players, round, outcome, and next action |
| `b25-wp-037-critique-submission-community-camera-club-member` | Camera Club | `critique-submission` | member | 2 | critique submission/review surface with image/work title, comments, reviewer state, and result |
| `b25-wp-038-gear-loan-request-community-camera-club-member` | Camera Club | `gear-loan-request` | member | 2 | request detail and admin review queue with submitted data, decision action, status, and notification |
| `b25-wp-043-platform-message-stream-community-platform-social-member` | Member Social Space | `platform-message-stream` | member | 2 | inbox, message thread, connection card, invite, or block-state surface |

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
| Review run | `b25-v4-pass-9` |
| Source criterion | `b25-c13-workflow-lifecycle-complete` |
| Source findings | B25-WORKFLOW-LIFECYCLE-INCOMPLETE |
| Title | Every primary workflow has complete lifecycle UX |
| Direct question | For every workflow and persona, does the UI prove the full production interaction model: concrete object/context, decision information, semantically correct primary and alternate actions, persistent result state, and receiver/continuation state? |
| Why it failed | Workflow lifecycle scorecards are incomplete for b25-wp-001-garden-event-rsvp-community-garden-club-member-lifecycle, b25-wp-002-plant-exchange-submission-community-garden-club-member-lifecycle, b25-wp-003-garden-export-custom-schemas-community-garden-club-owner-lifecycle, b25-wp-004-book-nomination-community-book-club-member-lifecycle, b25-wp-005-book-vote-community-book-club-member-lifecycle, b25-wp-006-book-meeting-rsvp-community-book-club-member-lifecycle, b25-wp-007-book-discussion-message-community-book-club-member-lifecycle, b25-wp-008-book-selection-publish-community-book-club-owner-lifecycle, b25-wp-009-book-search-ai-digest-community-book-club-member-lifecycle, b25-wp-010-book-export-metadata-community-book-club-owner-lifecycle, b25-wp-011-soccer-guardian-join-approval-community-youth-soccer-guardian-lifecycle, b25-wp-012-soccer-team-roster-community-youth-soccer-coach-lifecycle, b25-wp-013-soccer-minor-redaction-community-youth-soccer-guardian-lifecycle, b25-wp-014-soccer-registration-payment-community-youth-soccer-guardian-lifecycle, b25-wp-015-soccer-practice-schedule-community-youth-soccer-guardian-lifecycle, b25-wp-016-soccer-reminder-notification-community-youth-soccer-guardian-lifecycle, b25-wp-017-soccer-export-metadata-community-youth-soccer-owner-lifecycle, b25-wp-018-hoa-dues-payment-community-hoa-member-lifecycle, b25-wp-019-hoa-member-document-community-hoa-member-lifecycle, b25-wp-020-hoa-facility-reservation-community-hoa-member-lifecycle, b25-wp-021-hoa-architectural-request-community-hoa-owner-lifecycle, b25-wp-022-hoa-committee-decision-community-hoa-owner-lifecycle, b25-wp-023-hoa-owner-notification-community-hoa-owner-lifecycle, b25-wp-024-hoa-export-evidence-community-hoa-owner-lifecycle, b25-wp-025-mosque-announcement-community-mosque-owner-lifecycle, b25-wp-026-mosque-event-rsvp-community-mosque-member-lifecycle, b25-wp-027-mosque-volunteer-signup-community-mosque-member-lifecycle, b25-wp-028-mosque-donor-visibility-community-mosque-donor-lifecycle, b25-wp-029-mosque-donation-payment-community-mosque-donor-lifecycle, b25-wp-030-mosque-care-request-community-mosque-member-lifecycle, b25-wp-031-mosque-neutral-notification-community-mosque-member-lifecycle, b25-wp-032-mosque-search-ai-citation-community-mosque-member-lifecycle, b25-wp-033-chess-local-install-open-community-chess-club-member-lifecycle, b25-wp-034-chess-route-home-community-chess-club-member-lifecycle, b25-wp-035-chess-match-result-community-chess-club-member-lifecycle, b25-wp-036-photo-walk-rsvp-community-camera-club-member-lifecycle, b25-wp-037-critique-submission-community-camera-club-member-lifecycle, b25-wp-038-gear-loan-request-community-camera-club-member-lifecycle, b25-wp-039-platform-messages-entry-community-platform-social-member-lifecycle, b25-wp-040-platform-connections-entry-community-platform-social-member-lifecycle, b25-wp-041-platform-connection-invite-community-platform-social-member-lifecycle, b25-wp-042-platform-blocked-target-community-platform-social-member-lifecycle, b25-wp-043-platform-message-stream-community-platform-social-member-lifecycle, b25-wp-046-platform-sensitive-no-fill-community-platform-social-member-lifecycle, b25-wp-047-ad-off-member-checkout-community-ad-off-member-lifecycle, b25-wp-048-ad-off-community-checkout-community-ad-off-member-lifecycle, b25-wp-049-ad-off-entitlement-status-community-ad-off-member-lifecycle, b25-wp-050-ad-off-receipt-evidence-community-ad-off-member-lifecycle, b25-wp-051-ad-off-ad-suppression-community-ad-off-member-lifecycle, b25-wp-052-ad-off-settlement-utility-community-ad-off-member-lifecycle, b25-wp-053-export-import-preview-community-export-migration-owner-lifecycle, b25-wp-054-export-import-replay-community-export-migration-owner-lifecycle, b25-wp-055-export-protected-redaction-community-export-migration-owner-lifecycle, b25-wp-056-export-schema-listing-community-export-migration-owner-lifecycle, b25-wp-057-export-full-bundle-community-export-migration-owner-lifecycle, b25-wp-062-wf-persona-role-inventory-capability-matrix-persona-role-inventory-admin-lifecycle, b25-wp-063-wf-persona-role-inventory-capability-matrix-persona-role-inventory-member-lifecycle, b25-wp-064-wf-demo-app-persona-picker-community-mosque-member-lifecycle, b25-wp-065-wf-community-persona-aware-ux-community-mosque-member-lifecycle, b25-wp-066-wf-community-persona-aware-ux-community-mosque-admin-lifecycle, b25-wp-067-wf-multi-persona-workflow-evidence-community-mosque-admin-lifecycle, b25-wp-068-wf-multi-persona-workflow-evidence-community-mosque-member-lifecycle. Missing lifecycle groups: alternate/change/reject affordance, semantic interaction model, decision information, persistent result state, receiver/continuation state, primary semantic action. |
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
| Event detail and RSVP flow | Material cards/lists/buttons / pattern | https://m3.material.io/components/cards/overview<br>Also: https://m3.material.io/components/buttons/overview<br>https://m3.material.io/components/chips/overview | Copy an event detail layout: title, date/time, location, host, capacity/status chip, attendee context, RSVP action, and confirmation state. |
| Material navigation and information architecture | Material Design 3 / design-system | https://m3.material.io/components/navigation-drawer/overview<br>Also: https://m3.material.io/components/navigation-bar/overview | Organize screens by user jobs and destinations; keep primary actions visible and avoid exposing implementation taxonomy. |
| Apple HIG navigation and content organization | Apple Human Interface Guidelines / design-system | https://developer.apple.com/design/human-interface-guidelines/navigation | Make navigation predictable, content-centered, and appropriate for the user’s current task. |
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

### Reference Research Queries
- mobile app workflow lifecycle UI states primary secondary actions examples
- event RSVP decline change response mobile UI pattern
- mobile form review confirmation receipt receiver state UX examples
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

### Implementation Blocked By
- The judge cannot verify production-grade UX without a community-specific product experience spec.
- UI workers need the spec to know the rich product surface they are supposed to build.

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
| `b25-wi-evidence-repair-community-garden-club-garden-event-rsvp-community-garden-club-member` | `evidence-repair` | Garden Club | `garden-event-rsvp` | member | 3 | 1 | event detail with schedule, location, capacity/status, RSVP action, and result state |  |
| `b25-wi-evidence-repair-community-garden-club-plant-exchange-submission-community-garden-club-member` | `evidence-repair` | Garden Club | `plant-exchange-submission` | member | 3 | 1 | plant exchange offer form and member marketplace surface with plant details, pickup timing, owner contact, and submitted offer state |  |
| `b25-wi-evidence-repair-community-garden-club-garden-export-custom-schemas-community-garden-club-owner` | `evidence-repair` | Garden Club | `garden-export-custom-schemas` | owner | 3 | 1 | export/import wizard with preview, redaction, checksum, transfer status, and rollback state |  |
| `b25-wi-evidence-repair-community-book-club-book-nomination-community-book-club-member` | `evidence-repair` | Neighborhood Book Club | `book-nomination` | member | 3 | 1 | book club reading/voting surface with nominations, vote state, selected book, meeting context, and discussion |  |
| `b25-wi-evidence-repair-community-book-club-book-vote-community-book-club-member` | `evidence-repair` | Neighborhood Book Club | `book-vote` | member | 3 | 1 | book club reading/voting surface with nominations, vote state, selected book, meeting context, and discussion |  |
| `b25-wi-evidence-repair-community-book-club-book-meeting-rsvp-community-book-club-member` | `evidence-repair` | Neighborhood Book Club | `book-meeting-rsvp` | member | 3 | 1 | event detail with schedule, location, capacity/status, RSVP action, and result state |  |
| `b25-wi-evidence-repair-community-book-club-book-discussion-message-community-book-club-member` | `evidence-repair` | Neighborhood Book Club | `book-discussion-message` | member | 3 | 1 | inbox, message thread, connection card, invite, or block-state surface |  |
| `b25-wi-evidence-repair-community-book-club-book-selection-publish-community-book-club-owner` | `evidence-repair` | Neighborhood Book Club | `book-selection-publish` | owner | 3 | 1 | announcement feed/composer with audience, author, timestamp, body, and receiver state |  |
| `b25-wi-evidence-repair-community-book-club-book-search-ai-digest-community-book-club-member` | `evidence-repair` | Neighborhood Book Club | `book-search-ai-digest` | member | 3 | 1 | search/AI answer surface with query, result, citation, source, and follow-up action |  |
| `b25-wi-evidence-repair-community-book-club-book-export-metadata-community-book-club-owner` | `evidence-repair` | Neighborhood Book Club | `book-export-metadata` | owner | 3 | 1 | export/import wizard with preview, redaction, checksum, transfer status, and rollback state |  |
| `b25-wi-evidence-repair-community-youth-soccer-soccer-guardian-join-approval-community-youth-soccer-guardian` | `evidence-repair` | Riverside Youth Soccer | `soccer-guardian-join-approval` | guardian | 3 | 1 | request detail and admin review queue with submitted data, decision action, status, and notification |  |
| `b25-wi-evidence-repair-community-youth-soccer-soccer-team-roster-community-youth-soccer-coach` | `evidence-repair` | Riverside Youth Soccer | `soccer-team-roster` | coach | 3 | 1 | team roster/schedule surface with role-filtered member details and protected-data treatment |  |
| `b25-wi-evidence-repair-community-youth-soccer-soccer-minor-redaction-community-youth-soccer-guardian` | `evidence-repair` | Riverside Youth Soccer | `soccer-minor-redaction` | guardian | 3 | 1 | protected youth roster/profile surface with minor-data redaction, guardian visibility, and coach-only detail state |  |
| `b25-wi-evidence-repair-community-youth-soccer-soccer-registration-payment-community-youth-soccer-guardian` | `evidence-repair` | Riverside Youth Soccer | `soccer-registration-payment` | guardian | 3 | 1 | payment or donation flow with amount, payer context, receipt, entitlement/status, and audit trail |  |
| `b25-wi-evidence-repair-community-youth-soccer-soccer-practice-schedule-community-youth-soccer-guardian` | `evidence-repair` | Riverside Youth Soccer | `soccer-practice-schedule` | guardian | 3 | 1 | event detail with schedule, location, capacity/status, RSVP action, and result state |  |
| `b25-wi-evidence-repair-community-youth-soccer-soccer-reminder-notification-community-youth-soccer-guardian` | `evidence-repair` | Riverside Youth Soccer | `soccer-reminder-notification` | guardian | 3 | 1 | notification inbox/detail surface with sender, audience, timestamp, message body, and receiver state |  |
| `b25-wi-evidence-repair-community-youth-soccer-soccer-export-metadata-community-youth-soccer-owner` | `evidence-repair` | Riverside Youth Soccer | `soccer-export-metadata` | owner | 3 | 1 | export/import wizard with preview, redaction, checksum, transfer status, and rollback state |  |
| `b25-wi-evidence-repair-community-hoa-hoa-dues-payment-community-hoa-member` | `evidence-repair` | Cedar Commons HOA | `hoa-dues-payment` | member | 3 | 1 | payment or donation flow with amount, payer context, receipt, entitlement/status, and audit trail |  |
| `b25-wi-evidence-repair-community-hoa-hoa-member-document-community-hoa-member` | `evidence-repair` | Cedar Commons HOA | `hoa-member-document` | member | 3 | 1 | document library/detail surface with title, audience, file metadata, and access state |  |
| `b25-wi-evidence-repair-community-hoa-hoa-facility-reservation-community-hoa-member` | `evidence-repair` | Cedar Commons HOA | `hoa-facility-reservation` | member | 3 | 1 | facility detail/reservation flow with availability, payment/status, and confirmation |  |
| `b25-wi-evidence-repair-community-hoa-hoa-architectural-request-community-hoa-owner` | `evidence-repair` | Cedar Commons HOA | `hoa-architectural-request` | owner | 3 | 1 | request detail and admin review queue with submitted data, decision action, status, and notification |  |
| `b25-wi-evidence-repair-community-hoa-hoa-committee-decision-community-hoa-owner` | `evidence-repair` | Cedar Commons HOA | `hoa-committee-decision` | owner | 3 | 1 | request detail and admin review queue with submitted data, decision action, status, and notification |  |
| `b25-wi-evidence-repair-community-hoa-hoa-owner-notification-community-hoa-owner` | `evidence-repair` | Cedar Commons HOA | `hoa-owner-notification` | owner | 3 | 1 | notification inbox/detail surface with sender, audience, timestamp, message body, and receiver state |  |
| `b25-wi-evidence-repair-community-hoa-hoa-export-evidence-community-hoa-owner` | `evidence-repair` | Cedar Commons HOA | `hoa-export-evidence` | owner | 3 | 1 | export/import wizard with preview, redaction, checksum, transfer status, and rollback state |  |
| `b25-wi-evidence-repair-community-mosque-mosque-announcement-community-mosque-owner` | `evidence-repair` | Masjid Nur | `mosque-announcement` | owner | 3 | 1 | announcement feed/composer with audience, author, timestamp, body, and receiver state |  |
| `b25-wi-evidence-repair-community-mosque-mosque-event-rsvp-community-mosque-member` | `evidence-repair` | Masjid Nur | `mosque-event-rsvp` | member | 3 | 1 | event detail with schedule, location, capacity/status, RSVP action, and result state |  |
| `b25-wi-evidence-repair-community-mosque-mosque-volunteer-signup-community-mosque-member` | `evidence-repair` | Masjid Nur | `mosque-volunteer-signup` | member | 3 | 1 | volunteer signup surface with role, time, protected contact fields, and confirmation |  |
| `b25-wi-evidence-repair-community-mosque-mosque-donor-visibility-community-mosque-donor` | `evidence-repair` | Masjid Nur | `mosque-donor-visibility` | donor | 3 | 1 | donor privacy preference surface with visibility choice, donation context, confirmation, and receipt visibility state |  |
| `b25-wi-evidence-repair-community-mosque-mosque-donation-payment-community-mosque-donor` | `evidence-repair` | Masjid Nur | `mosque-donation-payment` | donor | 3 | 1 | payment or donation flow with amount, payer context, receipt, entitlement/status, and audit trail |  |
| `b25-wi-evidence-repair-community-mosque-mosque-care-request-community-mosque-member` | `evidence-repair` | Masjid Nur | `mosque-care-request` | member | 3 | 1 | protected care request form and private response/status surface |  |

### Evidence Repair Work Items Reference Patterns

| Reference | Source | URL | What to copy |
| --- | --- | --- | --- |
| Event detail and RSVP flow | Material cards/lists/buttons / pattern | https://m3.material.io/components/cards/overview<br>Also: https://m3.material.io/components/buttons/overview<br>https://m3.material.io/components/chips/overview | Copy an event detail layout: title, date/time, location, host, capacity/status chip, attendee context, RSVP action, and confirmation state. |
| Material Design cards and lists | Material Design 3 / design-system | https://m3.material.io/components/cards/overview<br>Also: https://m3.material.io/components/lists/overview | Use cards/lists only as scannable containers with clear hierarchy, content, metadata, and actions. Do not use repeated cards as the whole primary workflow. |
| Flutter sample app implementation patterns | flutter/samples / open-source | https://github.com/flutter/samples | Copy the separation between app shell, route state, domain widgets, and testable UI states rather than hardcoding a single generic renderer. |
| Material navigation and information architecture | Material Design 3 / design-system | https://m3.material.io/components/navigation-drawer/overview<br>Also: https://m3.material.io/components/navigation-bar/overview | Organize screens by user jobs and destinations; keep primary actions visible and avoid exposing implementation taxonomy. |
| Apple HIG navigation and content organization | Apple Human Interface Guidelines / design-system | https://developer.apple.com/design/human-interface-guidelines/navigation | Make navigation predictable, content-centered, and appropriate for the user’s current task. |
| Material detail surface composition | Material Design 3 / design-system | https://m3.material.io/components/cards/overview | Build a domain detail page with primary content, metadata, status, and actions instead of a generic task card. |
| Task list and export wizard | GOV.UK Design System / design-system | https://design-system.service.gov.uk/components/task-list/<br>Also: https://design-system.service.gov.uk/patterns/check-answers/ | Copy a wizard with steps, preview, redaction choices, checksum evidence, transfer status, and rollback confirmation. |
| Selection and voting pattern | Material chips/cards/buttons / pattern | https://m3.material.io/components/chips/overview<br>Also: https://m3.material.io/components/cards/overview | Copy a nomination/voting surface with choices, current vote state, deadline, selected result, and meeting/discussion context. |
| Inbox and message thread pattern | Material lists/text fields / pattern | https://m3.material.io/components/lists/overview<br>Also: https://m3.material.io/components/text-fields/overview | Copy an inbox/thread structure: sender, timestamp, message preview/body, reply field, invite/block state, and read/received state. |
| Feed item and composer pattern | Material cards/lists/text fields / pattern | https://m3.material.io/components/text-fields/overview<br>Also: https://m3.material.io/components/cards/overview<br>https://m3.material.io/components/lists/overview | Copy a feed/composer structure: audience, author, timestamp, body, attachments/status, publish action, and receiver read state. |
| Search and result list pattern | Material Design 3 / design-system | https://m3.material.io/components/search/overview<br>Also: https://m3.material.io/components/lists/overview | Copy a search layout with query, filters, ranked results, citations/sources, empty/error states, and follow-up actions. |
| Form validation and review pattern | U.S. Web Design System / design-system | https://designsystem.digital.gov/components/form/<br>Also: https://designsystem.digital.gov/components/alert/<br>https://design-system.service.gov.uk/components/error-summary/ | Copy a form flow with field labels, helper text, validation errors, review state, submit action, status, and protected-data treatment. |

### UI Remediation Work Items

Showing 30 of 62 work items. Full detail is in the JSON artifact.

| Work item | Stage | Community | Workflow | Persona | Screens | Coverage | Target surface | Blocked until |
| --- | --- | --- | --- | --- | ---: | ---: | --- | --- |
| `b25-wi-ui-remediation-community-garden-club-garden-event-rsvp-community-garden-club-member` | `ui-remediation` | Garden Club | `garden-event-rsvp` | member | 3 | 1 | event detail with schedule, location, capacity/status, RSVP action, and result state | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-garden-club-plant-exchange-submission-community-garden-club-member` | `ui-remediation` | Garden Club | `plant-exchange-submission` | member | 3 | 1 | plant exchange offer form and member marketplace surface with plant details, pickup timing, owner contact, and submitted offer state | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-garden-club-garden-export-custom-schemas-community-garden-club-owner` | `ui-remediation` | Garden Club | `garden-export-custom-schemas` | owner | 3 | 1 | export/import wizard with preview, redaction, checksum, transfer status, and rollback state | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-book-club-book-nomination-community-book-club-member` | `ui-remediation` | Neighborhood Book Club | `book-nomination` | member | 3 | 1 | book club reading/voting surface with nominations, vote state, selected book, meeting context, and discussion | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-book-club-book-vote-community-book-club-member` | `ui-remediation` | Neighborhood Book Club | `book-vote` | member | 3 | 1 | book club reading/voting surface with nominations, vote state, selected book, meeting context, and discussion | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-book-club-book-meeting-rsvp-community-book-club-member` | `ui-remediation` | Neighborhood Book Club | `book-meeting-rsvp` | member | 3 | 1 | event detail with schedule, location, capacity/status, RSVP action, and result state | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-book-club-book-discussion-message-community-book-club-member` | `ui-remediation` | Neighborhood Book Club | `book-discussion-message` | member | 3 | 1 | inbox, message thread, connection card, invite, or block-state surface | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-book-club-book-selection-publish-community-book-club-owner` | `ui-remediation` | Neighborhood Book Club | `book-selection-publish` | owner | 3 | 1 | announcement feed/composer with audience, author, timestamp, body, and receiver state | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-book-club-book-search-ai-digest-community-book-club-member` | `ui-remediation` | Neighborhood Book Club | `book-search-ai-digest` | member | 3 | 1 | search/AI answer surface with query, result, citation, source, and follow-up action | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-book-club-book-export-metadata-community-book-club-owner` | `ui-remediation` | Neighborhood Book Club | `book-export-metadata` | owner | 3 | 1 | export/import wizard with preview, redaction, checksum, transfer status, and rollback state | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-youth-soccer-soccer-guardian-join-approval-community-youth-soccer-guardian` | `ui-remediation` | Riverside Youth Soccer | `soccer-guardian-join-approval` | guardian | 3 | 1 | request detail and admin review queue with submitted data, decision action, status, and notification | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-youth-soccer-soccer-team-roster-community-youth-soccer-coach` | `ui-remediation` | Riverside Youth Soccer | `soccer-team-roster` | coach | 3 | 1 | team roster/schedule surface with role-filtered member details and protected-data treatment | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-youth-soccer-soccer-minor-redaction-community-youth-soccer-guardian` | `ui-remediation` | Riverside Youth Soccer | `soccer-minor-redaction` | guardian | 3 | 1 | protected youth roster/profile surface with minor-data redaction, guardian visibility, and coach-only detail state | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-youth-soccer-soccer-registration-payment-community-youth-soccer-guardian` | `ui-remediation` | Riverside Youth Soccer | `soccer-registration-payment` | guardian | 3 | 1 | payment or donation flow with amount, payer context, receipt, entitlement/status, and audit trail | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-youth-soccer-soccer-practice-schedule-community-youth-soccer-guardian` | `ui-remediation` | Riverside Youth Soccer | `soccer-practice-schedule` | guardian | 3 | 1 | event detail with schedule, location, capacity/status, RSVP action, and result state | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-youth-soccer-soccer-reminder-notification-community-youth-soccer-guardian` | `ui-remediation` | Riverside Youth Soccer | `soccer-reminder-notification` | guardian | 3 | 1 | notification inbox/detail surface with sender, audience, timestamp, message body, and receiver state | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-youth-soccer-soccer-export-metadata-community-youth-soccer-owner` | `ui-remediation` | Riverside Youth Soccer | `soccer-export-metadata` | owner | 3 | 1 | export/import wizard with preview, redaction, checksum, transfer status, and rollback state | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-hoa-hoa-dues-payment-community-hoa-member` | `ui-remediation` | Cedar Commons HOA | `hoa-dues-payment` | member | 3 | 1 | payment or donation flow with amount, payer context, receipt, entitlement/status, and audit trail | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-hoa-hoa-member-document-community-hoa-member` | `ui-remediation` | Cedar Commons HOA | `hoa-member-document` | member | 3 | 1 | document library/detail surface with title, audience, file metadata, and access state | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-hoa-hoa-facility-reservation-community-hoa-member` | `ui-remediation` | Cedar Commons HOA | `hoa-facility-reservation` | member | 3 | 1 | facility detail/reservation flow with availability, payment/status, and confirmation | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-hoa-hoa-architectural-request-community-hoa-owner` | `ui-remediation` | Cedar Commons HOA | `hoa-architectural-request` | owner | 3 | 1 | request detail and admin review queue with submitted data, decision action, status, and notification | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-hoa-hoa-committee-decision-community-hoa-owner` | `ui-remediation` | Cedar Commons HOA | `hoa-committee-decision` | owner | 3 | 1 | request detail and admin review queue with submitted data, decision action, status, and notification | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-hoa-hoa-owner-notification-community-hoa-owner` | `ui-remediation` | Cedar Commons HOA | `hoa-owner-notification` | owner | 3 | 1 | notification inbox/detail surface with sender, audience, timestamp, message body, and receiver state | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-hoa-hoa-export-evidence-community-hoa-owner` | `ui-remediation` | Cedar Commons HOA | `hoa-export-evidence` | owner | 3 | 1 | export/import wizard with preview, redaction, checksum, transfer status, and rollback state | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-mosque-mosque-announcement-community-mosque-owner` | `ui-remediation` | Masjid Nur | `mosque-announcement` | owner | 3 | 1 | announcement feed/composer with audience, author, timestamp, body, and receiver state | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-mosque-mosque-event-rsvp-community-mosque-member` | `ui-remediation` | Masjid Nur | `mosque-event-rsvp` | member | 3 | 1 | event detail with schedule, location, capacity/status, RSVP action, and result state | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-mosque-mosque-volunteer-signup-community-mosque-member` | `ui-remediation` | Masjid Nur | `mosque-volunteer-signup` | member | 3 | 1 | volunteer signup surface with role, time, protected contact fields, and confirmation | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-mosque-mosque-donor-visibility-community-mosque-donor` | `ui-remediation` | Masjid Nur | `mosque-donor-visibility` | donor | 3 | 1 | donor privacy preference surface with visibility choice, donation context, confirmation, and receipt visibility state | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-mosque-mosque-donation-payment-community-mosque-donor` | `ui-remediation` | Masjid Nur | `mosque-donation-payment` | donor | 3 | 1 | payment or donation flow with amount, payer context, receipt, entitlement/status, and audit trail | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-mosque-mosque-care-request-community-mosque-member` | `ui-remediation` | Masjid Nur | `mosque-care-request` | member | 3 | 1 | protected care request form and private response/status surface | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |

### UI Remediation Work Items Reference Patterns

| Reference | Source | URL | What to copy |
| --- | --- | --- | --- |
| Event detail and RSVP flow | Material cards/lists/buttons / pattern | https://m3.material.io/components/cards/overview<br>Also: https://m3.material.io/components/buttons/overview<br>https://m3.material.io/components/chips/overview | Copy an event detail layout: title, date/time, location, host, capacity/status chip, attendee context, RSVP action, and confirmation state. |
| Material Design cards and lists | Material Design 3 / design-system | https://m3.material.io/components/cards/overview<br>Also: https://m3.material.io/components/lists/overview | Use cards/lists only as scannable containers with clear hierarchy, content, metadata, and actions. Do not use repeated cards as the whole primary workflow. |
| Flutter sample app implementation patterns | flutter/samples / open-source | https://github.com/flutter/samples | Copy the separation between app shell, route state, domain widgets, and testable UI states rather than hardcoding a single generic renderer. |
| Material navigation and information architecture | Material Design 3 / design-system | https://m3.material.io/components/navigation-drawer/overview<br>Also: https://m3.material.io/components/navigation-bar/overview | Organize screens by user jobs and destinations; keep primary actions visible and avoid exposing implementation taxonomy. |
| Apple HIG navigation and content organization | Apple Human Interface Guidelines / design-system | https://developer.apple.com/design/human-interface-guidelines/navigation | Make navigation predictable, content-centered, and appropriate for the user’s current task. |
| Material detail surface composition | Material Design 3 / design-system | https://m3.material.io/components/cards/overview | Build a domain detail page with primary content, metadata, status, and actions instead of a generic task card. |
| Task list and export wizard | GOV.UK Design System / design-system | https://design-system.service.gov.uk/components/task-list/<br>Also: https://design-system.service.gov.uk/patterns/check-answers/ | Copy a wizard with steps, preview, redaction choices, checksum evidence, transfer status, and rollback confirmation. |
| Selection and voting pattern | Material chips/cards/buttons / pattern | https://m3.material.io/components/chips/overview<br>Also: https://m3.material.io/components/cards/overview | Copy a nomination/voting surface with choices, current vote state, deadline, selected result, and meeting/discussion context. |
| Inbox and message thread pattern | Material lists/text fields / pattern | https://m3.material.io/components/lists/overview<br>Also: https://m3.material.io/components/text-fields/overview | Copy an inbox/thread structure: sender, timestamp, message preview/body, reply field, invite/block state, and read/received state. |
| Feed item and composer pattern | Material cards/lists/text fields / pattern | https://m3.material.io/components/text-fields/overview<br>Also: https://m3.material.io/components/cards/overview<br>https://m3.material.io/components/lists/overview | Copy a feed/composer structure: audience, author, timestamp, body, attachments/status, publish action, and receiver read state. |
| Search and result list pattern | Material Design 3 / design-system | https://m3.material.io/components/search/overview<br>Also: https://m3.material.io/components/lists/overview | Copy a search layout with query, filters, ranked results, citations/sources, empty/error states, and follow-up actions. |
| Form validation and review pattern | U.S. Web Design System / design-system | https://designsystem.digital.gov/components/form/<br>Also: https://designsystem.digital.gov/components/alert/<br>https://design-system.service.gov.uk/components/error-summary/ | Copy a form flow with field labels, helper text, validation errors, review state, submit action, status, and protected-data treatment. |

### Affected Workflow/Persona Coverage

Showing 40 of 62 affected coverage rows. Full detail is in the JSON ticket.

| Coverage row | Status | Community | Workflow | Persona | Missing evidence | Screen rows | Target surface |
| --- | --- | --- | --- | --- | --- | ---: | --- |
| `b25-wp-001-garden-event-rsvp-community-garden-club-member` | `pass` | Garden Club | `garden-event-rsvp` | member |  | 3 | event detail with schedule, location, capacity/status, RSVP action, and result state |
| `b25-wp-002-plant-exchange-submission-community-garden-club-member` | `pass` | Garden Club | `plant-exchange-submission` | member |  | 3 | plant exchange offer form and member marketplace surface with plant details, pickup timing, owner contact, and submitted offer state |
| `b25-wp-003-garden-export-custom-schemas-community-garden-club-owner` | `pass` | Garden Club | `garden-export-custom-schemas` | owner |  | 3 | export/import wizard with preview, redaction, checksum, transfer status, and rollback state |
| `b25-wp-004-book-nomination-community-book-club-member` | `pass` | Neighborhood Book Club | `book-nomination` | member |  | 3 | book club reading/voting surface with nominations, vote state, selected book, meeting context, and discussion |
| `b25-wp-005-book-vote-community-book-club-member` | `pass` | Neighborhood Book Club | `book-vote` | member |  | 3 | book club reading/voting surface with nominations, vote state, selected book, meeting context, and discussion |
| `b25-wp-006-book-meeting-rsvp-community-book-club-member` | `pass` | Neighborhood Book Club | `book-meeting-rsvp` | member |  | 3 | event detail with schedule, location, capacity/status, RSVP action, and result state |
| `b25-wp-007-book-discussion-message-community-book-club-member` | `pass` | Neighborhood Book Club | `book-discussion-message` | member |  | 3 | inbox, message thread, connection card, invite, or block-state surface |
| `b25-wp-008-book-selection-publish-community-book-club-owner` | `pass` | Neighborhood Book Club | `book-selection-publish` | owner |  | 3 | announcement feed/composer with audience, author, timestamp, body, and receiver state |
| `b25-wp-009-book-search-ai-digest-community-book-club-member` | `pass` | Neighborhood Book Club | `book-search-ai-digest` | member |  | 3 | search/AI answer surface with query, result, citation, source, and follow-up action |
| `b25-wp-010-book-export-metadata-community-book-club-owner` | `pass` | Neighborhood Book Club | `book-export-metadata` | owner |  | 3 | export/import wizard with preview, redaction, checksum, transfer status, and rollback state |
| `b25-wp-011-soccer-guardian-join-approval-community-youth-soccer-guardian` | `pass` | Riverside Youth Soccer | `soccer-guardian-join-approval` | guardian |  | 3 | request detail and admin review queue with submitted data, decision action, status, and notification |
| `b25-wp-012-soccer-team-roster-community-youth-soccer-coach` | `pass` | Riverside Youth Soccer | `soccer-team-roster` | coach |  | 3 | team roster/schedule surface with role-filtered member details and protected-data treatment |
| `b25-wp-013-soccer-minor-redaction-community-youth-soccer-guardian` | `pass` | Riverside Youth Soccer | `soccer-minor-redaction` | guardian |  | 3 | protected youth roster/profile surface with minor-data redaction, guardian visibility, and coach-only detail state |
| `b25-wp-014-soccer-registration-payment-community-youth-soccer-guardian` | `pass` | Riverside Youth Soccer | `soccer-registration-payment` | guardian |  | 3 | payment or donation flow with amount, payer context, receipt, entitlement/status, and audit trail |
| `b25-wp-015-soccer-practice-schedule-community-youth-soccer-guardian` | `pass` | Riverside Youth Soccer | `soccer-practice-schedule` | guardian |  | 3 | event detail with schedule, location, capacity/status, RSVP action, and result state |
| `b25-wp-016-soccer-reminder-notification-community-youth-soccer-guardian` | `pass` | Riverside Youth Soccer | `soccer-reminder-notification` | guardian |  | 3 | notification inbox/detail surface with sender, audience, timestamp, message body, and receiver state |
| `b25-wp-017-soccer-export-metadata-community-youth-soccer-owner` | `pass` | Riverside Youth Soccer | `soccer-export-metadata` | owner |  | 3 | export/import wizard with preview, redaction, checksum, transfer status, and rollback state |
| `b25-wp-018-hoa-dues-payment-community-hoa-member` | `pass` | Cedar Commons HOA | `hoa-dues-payment` | member |  | 3 | payment or donation flow with amount, payer context, receipt, entitlement/status, and audit trail |
| `b25-wp-019-hoa-member-document-community-hoa-member` | `pass` | Cedar Commons HOA | `hoa-member-document` | member |  | 3 | document library/detail surface with title, audience, file metadata, and access state |
| `b25-wp-020-hoa-facility-reservation-community-hoa-member` | `pass` | Cedar Commons HOA | `hoa-facility-reservation` | member |  | 3 | facility detail/reservation flow with availability, payment/status, and confirmation |
| `b25-wp-021-hoa-architectural-request-community-hoa-owner` | `pass` | Cedar Commons HOA | `hoa-architectural-request` | owner |  | 3 | request detail and admin review queue with submitted data, decision action, status, and notification |
| `b25-wp-022-hoa-committee-decision-community-hoa-owner` | `pass` | Cedar Commons HOA | `hoa-committee-decision` | owner |  | 3 | request detail and admin review queue with submitted data, decision action, status, and notification |
| `b25-wp-023-hoa-owner-notification-community-hoa-owner` | `pass` | Cedar Commons HOA | `hoa-owner-notification` | owner |  | 3 | notification inbox/detail surface with sender, audience, timestamp, message body, and receiver state |
| `b25-wp-024-hoa-export-evidence-community-hoa-owner` | `pass` | Cedar Commons HOA | `hoa-export-evidence` | owner |  | 3 | export/import wizard with preview, redaction, checksum, transfer status, and rollback state |
| `b25-wp-025-mosque-announcement-community-mosque-owner` | `pass` | Masjid Nur | `mosque-announcement` | owner |  | 3 | announcement feed/composer with audience, author, timestamp, body, and receiver state |
| `b25-wp-026-mosque-event-rsvp-community-mosque-member` | `pass` | Masjid Nur | `mosque-event-rsvp` | member |  | 3 | event detail with schedule, location, capacity/status, RSVP action, and result state |
| `b25-wp-027-mosque-volunteer-signup-community-mosque-member` | `pass` | Masjid Nur | `mosque-volunteer-signup` | member |  | 3 | volunteer signup surface with role, time, protected contact fields, and confirmation |
| `b25-wp-028-mosque-donor-visibility-community-mosque-donor` | `pass` | Masjid Nur | `mosque-donor-visibility` | donor |  | 3 | donor privacy preference surface with visibility choice, donation context, confirmation, and receipt visibility state |
| `b25-wp-029-mosque-donation-payment-community-mosque-donor` | `pass` | Masjid Nur | `mosque-donation-payment` | donor |  | 3 | payment or donation flow with amount, payer context, receipt, entitlement/status, and audit trail |
| `b25-wp-030-mosque-care-request-community-mosque-member` | `pass` | Masjid Nur | `mosque-care-request` | member |  | 3 | protected care request form and private response/status surface |
| `b25-wp-031-mosque-neutral-notification-community-mosque-member` | `pass` | Masjid Nur | `mosque-neutral-notification` | member |  | 3 | notification inbox/detail surface with sender, audience, timestamp, message body, and receiver state |
| `b25-wp-032-mosque-search-ai-citation-community-mosque-member` | `pass` | Masjid Nur | `mosque-search-ai-citation` | member |  | 3 | search/AI answer surface with query, result, citation, source, and follow-up action |
| `b25-wp-033-chess-local-install-open-community-chess-club-member` | `pass` | Chess Club | `chess-local-install-open` | member |  | 3 | match schedule/result surface with players, round, outcome, and next action |
| `b25-wp-034-chess-route-home-community-chess-club-member` | `pass` | Chess Club | `chess-route-home` | member |  | 3 | match schedule/result surface with players, round, outcome, and next action |
| `b25-wp-035-chess-match-result-community-chess-club-member` | `pass` | Chess Club | `chess-match-result` | member |  | 3 | match schedule/result surface with players, round, outcome, and next action |
| `b25-wp-036-photo-walk-rsvp-community-camera-club-member` | `pass` | Camera Club | `photo-walk-rsvp` | member |  | 3 | event detail with schedule, location, capacity/status, RSVP action, and result state |
| `b25-wp-037-critique-submission-community-camera-club-member` | `pass` | Camera Club | `critique-submission` | member |  | 3 | critique submission/review surface with image/work title, comments, reviewer state, and result |
| `b25-wp-038-gear-loan-request-community-camera-club-member` | `pass` | Camera Club | `gear-loan-request` | member |  | 3 | request detail and admin review queue with submitted data, decision action, status, and notification |
| `b25-wp-039-platform-messages-entry-community-platform-social-member` | `pass` | Member Social Space | `platform-messages-entry` | member |  | 3 | inbox, message thread, connection card, invite, or block-state surface |
| `b25-wp-040-platform-connections-entry-community-platform-social-member` | `pass` | Member Social Space | `platform-connections-entry` | member |  | 3 | inbox, message thread, connection card, invite, or block-state surface |

### Affected Screen Rows

Showing 40 of 177 affected screen rows. Full detail is in the JSON ticket.

| Screen row | Community | Workflow | Persona | State | Screenshot | Hash | Visible text | Current surface | Exact UX failure | Target surface |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `b25-v4-row-001-garden-event-rsvp-0` | Garden Club | `garden-event-rsvp` | member | B13_ext_garden_club_garden-event-rsvp_start | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B13/screenshots/B13_ext_garden_club_garden-event-rsvp_start.png` | `a22c40c22110b...` | Garden event RSVP \| Event details include date, location, capacity, and attendance. \| This week \| Community venue \| Capacity tracked \| RSVP to event \| Care and volunteers \| Private requests, volunteer shifts, and member support. \| Plant exchange submission \| Member form captur... | domain-native-reviewed / domain-native | No row-specific failure recorded. | event detail with schedule, location, capacity/status, RSVP action, and result state |
| `b25-v4-row-002-garden-event-rsvp-1` | Garden Club | `garden-event-rsvp` | member | B13_ext_garden_club_garden-event-rsvp_action | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B13/screenshots/B13_ext_garden_club_garden-event-rsvp_action.png` | `8752032410567...` | Coordinate attendance \| Use this surface to publish event details, capacity, and attendance state. \| This week \| Community venue \| Capacity tracked \| Details \| Date, location, capacity, and attendee state are included. \| Member outcome \| Attendance, capacity, and reminders upd... | domain-native-reviewed / domain-native | No row-specific failure recorded. | event detail with schedule, location, capacity/status, RSVP action, and result state |
| `b25-v4-row-003-garden-event-rsvp-2` | Garden Club | `garden-event-rsvp` | member | B13_ext_garden_club_garden-event-rsvp_complete | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B13/screenshots/B13_ext_garden_club_garden-event-rsvp_complete.png` | `a58aad43b14dd...` | Garden event RSVP \| Event details include date, location, capacity, and attendance. \| This week \| Community venue \| Capacity tracked \| RSVP confirmed \| Attendance, capacity, and confirmation details are up to date. \| Going \| Care and volunteers \| Private requests, volunteer sh... | domain-native-reviewed / domain-native | No row-specific failure recorded. | event detail with schedule, location, capacity/status, RSVP action, and result state |
| `b25-v4-row-004-plant-exchange-submission-0` | Garden Club | `plant-exchange-submission` | member | B13_ext_garden_club_plant-exchange-submission_start | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B13/screenshots/B13_ext_garden_club_plant-exchange-submission_start.png` | `7e5e418252089...` | Care and volunteers \| Private requests, volunteer shifts, and member support. \| Plant exchange submission \| Member form captures labeled details, privacy choices, and reviewer handoff. \| Labeled fields \| Privacy checked \| Review handoff \| Submit entry \| Documents and data \| Do... | domain-native-reviewed / domain-native | No row-specific failure recorded. | plant exchange offer form and member marketplace surface with plant details, pickup timing, owner contact, and submitted offer state |
| `b25-v4-row-005-plant-exchange-submission-1` | Garden Club | `plant-exchange-submission` | member | B13_ext_garden_club_plant-exchange-submission_action | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B13/screenshots/B13_ext_garden_club_plant-exchange-submission_action.png` | `ccd68c48ee915...` | Submit member form \| Use this surface to submit structured member details. \| Labeled fields \| Privacy checked \| Review handoff \| Details \| Required fields, privacy choices, and reviewer handoff are included. \| Member outcome \| The submission is routed to the reviewer with prot... | domain-native-reviewed / domain-native | No row-specific failure recorded. | plant exchange offer form and member marketplace surface with plant details, pickup timing, owner contact, and submitted offer state |
| `b25-v4-row-006-plant-exchange-submission-2` | Garden Club | `plant-exchange-submission` | member | B13_ext_garden_club_plant-exchange-submission_complete | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B13/screenshots/B13_ext_garden_club_plant-exchange-submission_complete.png` | `9155c4d4d2beb...` | Plant exchange submission \| Member form captures labeled details, privacy choices, and reviewer handoff. \| Labeled fields \| Privacy checked \| Review handoff \| Record saved \| The community record is saved. \| Saved \| Documents and data \| Documents, exports, imports, and transfer... | domain-native-reviewed / domain-native | No row-specific failure recorded. | plant exchange offer form and member marketplace surface with plant details, pickup timing, owner contact, and submitted offer state |
| `b25-v4-row-007-garden-export-custom-schemas-0` | Garden Club | `garden-export-custom-schemas` | owner | B13_ext_garden_club_garden-export-custom-schemas_start | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B13/screenshots/B13_ext_garden_club_garden-export-custom-schemas_start.png` | `ec5fff8f7944b...` | Plant exchange submission \| A submitted member form is ready for review and follow-up. \| Labeled fields \| Privacy checked \| Review handoff \| Review plant exchange submission \| Documents and data \| Documents, exports, imports, and transfer records. \| Garden export custom schema... | domain-native-reviewed / domain-native | No row-specific failure recorded. | export/import wizard with preview, redaction, checksum, transfer status, and rollback state |
| `b25-v4-row-008-garden-export-custom-schemas-1` | Garden Club | `garden-export-custom-schemas` | owner | B13_ext_garden_club_garden-export-custom-schemas_action | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B13/screenshots/B13_ext_garden_club_garden-export-custom-schemas_action.png` | `88121490c3198...` | Prepare export handoff \| Use this surface to package export scope, redaction, and handoff status. \| Redacted copy \| Checksum ready \| Exportable \| Details \| Scope, redaction, checksum, and handoff destination are included. \| Member outcome \| The export package can be inspected ... | domain-native-reviewed / domain-native | No row-specific failure recorded. | export/import wizard with preview, redaction, checksum, transfer status, and rollback state |
| `b25-v4-row-009-garden-export-custom-schemas-2` | Garden Club | `garden-export-custom-schemas` | owner | B13_ext_garden_club_garden-export-custom-schemas_complete | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B13/screenshots/B13_ext_garden_club_garden-export-custom-schemas_complete.png` | `cd83b521e0ea7...` | Plant exchange submission \| A submitted member form is ready for review and follow-up. \| Labeled fields \| Privacy checked \| Review handoff \| Review plant exchange submission \| Documents and data \| Documents, exports, imports, and transfer records. \| Garden export custom schema... | domain-native-reviewed / domain-native | No row-specific failure recorded. | export/import wizard with preview, redaction, checksum, transfer status, and rollback state |
| `b25-v4-row-010-book-nomination-0` | Neighborhood Book Club | `book-nomination` | member | B14_ext_book_club_book-nomination_start | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_book_club_book-nomination_start.png` | `4e4e9b1d35b93...` | Discussion message \| Member communication stays scoped to the community relationship. \| Private by default \| Membership scoped \| Ready \| Post message \| Member tools \| Useful actions for this community. \| Book nomination \| Member form captures labeled details, privacy choices, ... | domain-native-reviewed / domain-native | No row-specific failure recorded. | book club reading/voting surface with nominations, vote state, selected book, meeting context, and discussion |
| `b25-v4-row-011-book-nomination-1` | Neighborhood Book Club | `book-nomination` | member | B14_ext_book_club_book-nomination_action | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_book_club_book-nomination_action.png` | `0644e15ad1c93...` | Submit member form \| Use this surface to submit structured member details. \| Labeled fields \| Privacy checked \| Review handoff \| Details \| Required fields, privacy choices, and reviewer handoff are included. \| Member outcome \| The submission is routed to the reviewer with prot... | domain-native-reviewed / domain-native | No row-specific failure recorded. | book club reading/voting surface with nominations, vote state, selected book, meeting context, and discussion |
| `b25-v4-row-012-book-nomination-2` | Neighborhood Book Club | `book-nomination` | member | B14_ext_book_club_book-nomination_complete | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_book_club_book-nomination_complete.png` | `b9a2aaf99400e...` | Member tools \| Useful actions for this community. \| Book nomination \| Member form captures labeled details, privacy choices, and reviewer handoff. \| Labeled fields \| Privacy checked \| Review handoff \| Record saved \| The community record is saved. \| Saved \| Book vote \| Record v... | domain-native-reviewed / domain-native | No row-specific failure recorded. | book club reading/voting surface with nominations, vote state, selected book, meeting context, and discussion |
| `b25-v4-row-013-book-vote-0` | Neighborhood Book Club | `book-vote` | member | B14_ext_book_club_book-vote_start | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_book_club_book-vote_start.png` | `b9a2aaf99400e...` | Member tools \| Useful actions for this community. \| Book nomination \| Member form captures labeled details, privacy choices, and reviewer handoff. \| Labeled fields \| Privacy checked \| Review handoff \| Record saved \| The community record is saved. \| Saved \| Book vote \| Record v... | domain-native-reviewed / domain-native | No row-specific failure recorded. | book club reading/voting surface with nominations, vote state, selected book, meeting context, and discussion |
| `b25-v4-row-014-book-vote-1` | Neighborhood Book Club | `book-vote` | member | B14_ext_book_club_book-vote_action | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_book_club_book-vote_action.png` | `6c3961b9a5aa6...` | Submit member form \| Use this surface to submit structured member details. \| Labeled fields \| Privacy checked \| Review handoff \| Details \| Required fields, privacy choices, and reviewer handoff are included. \| Member outcome \| The submission is routed to the reviewer with prot... | domain-native-reviewed / domain-native | No row-specific failure recorded. | book club reading/voting surface with nominations, vote state, selected book, meeting context, and discussion |
| `b25-v4-row-015-book-vote-2` | Neighborhood Book Club | `book-vote` | member | B14_ext_book_club_book-vote_complete | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_book_club_book-vote_complete.png` | `d13f4363cc2a3...` | Member tools \| Useful actions for this community. \| Book nomination \| Member form captures labeled details, privacy choices, and reviewer handoff. \| Labeled fields \| Privacy checked \| Review handoff \| Record saved \| The community record is saved. \| Saved \| Book vote \| Local pa... | domain-native-reviewed / domain-native | No row-specific failure recorded. | book club reading/voting surface with nominations, vote state, selected book, meeting context, and discussion |
| `b25-v4-row-016-book-meeting-rsvp-0` | Neighborhood Book Club | `book-meeting-rsvp` | member | B14_ext_book_club_book-meeting-rsvp_start | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_book_club_book-meeting-rsvp_start.png` | `ce2cee7a160eb...` | Meeting event RSVP \| Event details include date, location, capacity, and attendance. \| This week \| Community venue \| Capacity tracked \| RSVP to event \| Documents and data \| Documents, exports, imports, and transfer records. \| Book export metadata \| You can review the current d... | domain-native-reviewed / domain-native | No row-specific failure recorded. | event detail with schedule, location, capacity/status, RSVP action, and result state |
| `b25-v4-row-017-book-meeting-rsvp-1` | Neighborhood Book Club | `book-meeting-rsvp` | member | B14_ext_book_club_book-meeting-rsvp_action | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_book_club_book-meeting-rsvp_action.png` | `8752032410567...` | Coordinate attendance \| Use this surface to publish event details, capacity, and attendance state. \| This week \| Community venue \| Capacity tracked \| Details \| Date, location, capacity, and attendee state are included. \| Member outcome \| Attendance, capacity, and reminders upd... | domain-native-reviewed / domain-native | No row-specific failure recorded. | event detail with schedule, location, capacity/status, RSVP action, and result state |
| `b25-v4-row-018-book-meeting-rsvp-2` | Neighborhood Book Club | `book-meeting-rsvp` | member | B14_ext_book_club_book-meeting-rsvp_complete | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_book_club_book-meeting-rsvp_complete.png` | `f2ba338c55a85...` | Meeting event RSVP \| Event details include date, location, capacity, and attendance. \| This week \| Community venue \| Capacity tracked \| RSVP confirmed \| Attendance, capacity, and confirmation details are up to date. \| Going \| Documents and data \| Documents, exports, imports, a... | domain-native-reviewed / domain-native | No row-specific failure recorded. | event detail with schedule, location, capacity/status, RSVP action, and result state |
| `b25-v4-row-019-book-discussion-message-0` | Neighborhood Book Club | `book-discussion-message` | member | B14_ext_book_club_book-discussion-message_start | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_book_club_book-discussion-message_start.png` | `e459e2823b4f0...` | Discussion message \| Member communication stays scoped to the community relationship. \| Private by default \| Membership scoped \| Ready \| Post message \| Member tools \| Useful actions for this community. \| Book nomination \| Member form captures labeled details, privacy choices, ... | domain-native-reviewed / domain-native | No row-specific failure recorded. | inbox, message thread, connection card, invite, or block-state surface |
| `b25-v4-row-020-book-discussion-message-1` | Neighborhood Book Club | `book-discussion-message` | member | B14_ext_book_club_book-discussion-message_action | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_book_club_book-discussion-message_action.png` | `5e078b9e62bee...` | Update member channel \| Use this surface to change a member communication or relationship setting. \| Private by default \| Membership scoped \| Ready \| Details \| Member channel, relationship, and preference details are included. \| Member outcome \| The communication or relationsh... | domain-native-reviewed / domain-native | No row-specific failure recorded. | inbox, message thread, connection card, invite, or block-state surface |
| `b25-v4-row-021-book-discussion-message-2` | Neighborhood Book Club | `book-discussion-message` | member | B14_ext_book_club_book-discussion-message_complete | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_book_club_book-discussion-message_complete.png` | `2ee96485431c1...` | Discussion message \| Member communication stays scoped to the community relationship. \| Private by default \| Membership scoped \| Ready \| Setting saved \| The member setting is up to date. \| Verified \| Member tools \| Useful actions for this community. \| Book nomination \| Member ... | domain-native-reviewed / domain-native | No row-specific failure recorded. | inbox, message thread, connection card, invite, or block-state surface |
| `b25-v4-row-022-book-selection-publish-0` | Neighborhood Book Club | `book-selection-publish` | owner | B14_ext_book_club_book-selection-publish_start | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_book_club_book-selection-publish_start.png` | `39bd49476089b...` | Selected-book publishing \| Member form captures labeled details, privacy choices, and reviewer handoff. \| Members \| Today \| Inbox + push \| Publish selection \| Search, AI answer, and digest \| Generate cited answer \| Upcoming events \| Dates, capacity, and attendance actions. \| M... | domain-native-reviewed / domain-native | No row-specific failure recorded. | announcement feed/composer with audience, author, timestamp, body, and receiver state |
| `b25-v4-row-023-book-selection-publish-1` | Neighborhood Book Club | `book-selection-publish` | owner | B14_ext_book_club_book-selection-publish_action | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_book_club_book-selection-publish_action.png` | `a5f772a45aa20...` | Send community notice \| Use this surface to send a scoped announcement to the selected audience. \| Members \| Today \| Inbox + push \| Details \| Message, audience, preview, and delivery channel are included. \| Member outcome \| The announcement appears in the member inbox and noti... | domain-native-reviewed / domain-native | No row-specific failure recorded. | announcement feed/composer with audience, author, timestamp, body, and receiver state |
| `b25-v4-row-024-book-selection-publish-2` | Neighborhood Book Club | `book-selection-publish` | owner | B14_ext_book_club_book-selection-publish_complete | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_book_club_book-selection-publish_complete.png` | `cac0c576c5fca...` | Selected-book publishing \| Member form captures labeled details, privacy choices, and reviewer handoff. \| Members \| Today \| Inbox + push \| Update sent \| The update is available to the selected audience. \| Sent \| Search, AI answer, and digest \| Generate cited answer \| Upcoming ... | domain-native-reviewed / domain-native | No row-specific failure recorded. | announcement feed/composer with audience, author, timestamp, body, and receiver state |
| `b25-v4-row-025-book-search-ai-digest-0` | Neighborhood Book Club | `book-search-ai-digest` | member | B14_ext_book_club_book-search-ai-digest_start | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_book_club_book-search-ai-digest_start.png` | `fb4577aec43a6...` | Search, AI answer, and digest \| Member form captures labeled details, privacy choices, and reviewer handoff. \| Members \| Today \| Inbox + push \| Generate cited answer \| Upcoming events \| Dates, capacity, and attendance actions. \| Meeting event RSVP \| Event details include date,... | domain-native-reviewed / domain-native | No row-specific failure recorded. | search/AI answer surface with query, result, citation, source, and follow-up action |
| `b25-v4-row-026-book-search-ai-digest-1` | Neighborhood Book Club | `book-search-ai-digest` | member | B14_ext_book_club_book-search-ai-digest_action | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_book_club_book-search-ai-digest_action.png` | `4a6922846596d...` | Send community notice \| Use this surface to send a scoped announcement to the selected audience. \| Members \| Today \| Inbox + push \| Details \| Message, audience, preview, and delivery channel are included. \| Member outcome \| The announcement appears in the member inbox and noti... | domain-native-reviewed / domain-native | No row-specific failure recorded. | search/AI answer surface with query, result, citation, source, and follow-up action |
| `b25-v4-row-027-book-search-ai-digest-2` | Neighborhood Book Club | `book-search-ai-digest` | member | B14_ext_book_club_book-search-ai-digest_complete | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_book_club_book-search-ai-digest_complete.png` | `d554a18d65b96...` | Search, AI answer, and digest \| Member form captures labeled details, privacy choices, and reviewer handoff. \| Members \| Today \| Inbox + push \| Update sent \| The update is available to the selected audience. \| Sent \| Upcoming events \| Dates, capacity, and attendance actions. \|... | domain-native-reviewed / domain-native | No row-specific failure recorded. | search/AI answer surface with query, result, citation, source, and follow-up action |
| `b25-v4-row-028-book-export-metadata-0` | Neighborhood Book Club | `book-export-metadata` | owner | B14_ext_book_club_book-export-metadata_start | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_book_club_book-export-metadata_start.png` | `7ed4ac4dbc60a...` | Book export metadata \| Data package includes scope, protected fields, and handoff status. \| No ad shown \| Preference saved \| Receipt ready \| Generate export \| Messages and connections \| Member communication and relationship controls. \| Discussion message \| A member communicati... | domain-native-reviewed / domain-native | No row-specific failure recorded. | export/import wizard with preview, redaction, checksum, transfer status, and rollback state |
| `b25-v4-row-029-book-export-metadata-1` | Neighborhood Book Club | `book-export-metadata` | owner | B14_ext_book_club_book-export-metadata_action | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_book_club_book-export-metadata_action.png` | `30b2056311a24...` | Prepare export handoff \| Use this surface to package export scope, redaction, and handoff status. \| No ad shown \| Preference saved \| Receipt ready \| Details \| Scope, redaction, checksum, and handoff destination are included. \| Member outcome \| The export package can be inspect... | domain-native-reviewed / domain-native | No row-specific failure recorded. | export/import wizard with preview, redaction, checksum, transfer status, and rollback state |
| `b25-v4-row-030-book-export-metadata-2` | Neighborhood Book Club | `book-export-metadata` | owner | B14_ext_book_club_book-export-metadata_complete | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_book_club_book-export-metadata_complete.png` | `3842109f13c4e...` | Book export metadata \| Data package includes scope, protected fields, and handoff status. \| No ad shown \| Preference saved \| Receipt ready \| Data package ready \| The data package is ready with protected fields handled. \| Ready \| Messages and connections \| Member communication ... | domain-native-reviewed / domain-native | No row-specific failure recorded. | export/import wizard with preview, redaction, checksum, transfer status, and rollback state |
| `b25-v4-row-031-soccer-guardian-join-approval-0` | Riverside Youth Soccer | `soccer-guardian-join-approval` | guardian | B14_ext_youth_soccer_soccer-guardian-join-approval_start | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_youth_soccer_soccer-guardian-join-approval_start.png` | `d274220e13633...` | Guardian join and approval \| Submitted details are ready for a decision and member follow-up. \| Needs decision \| Private notes \| Member notified \| Approve request \| Documents and data \| Documents, exports, imports, and transfer records. \| Protected minor-data redaction \| You c... | domain-native-reviewed / domain-native | No row-specific failure recorded. | request detail and admin review queue with submitted data, decision action, status, and notification |
| `b25-v4-row-032-soccer-guardian-join-approval-1` | Riverside Youth Soccer | `soccer-guardian-join-approval` | guardian | B14_ext_youth_soccer_soccer-guardian-join-approval_action | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_youth_soccer_soccer-guardian-join-approval_action.png` | `f9c421ee71cf9...` | Resolve member request \| Use this surface to record the decision and member follow-up. \| Needs decision \| Private notes \| Member notified \| Details \| Request details, decision, and follow-up note are included. \| Member outcome \| The decision is saved with the next step visible... | domain-native-reviewed / domain-native | No row-specific failure recorded. | request detail and admin review queue with submitted data, decision action, status, and notification |
| `b25-v4-row-033-soccer-guardian-join-approval-2` | Riverside Youth Soccer | `soccer-guardian-join-approval` | guardian | B14_ext_youth_soccer_soccer-guardian-join-approval_complete | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_youth_soccer_soccer-guardian-join-approval_complete.png` | `2f84927eab8c9...` | Guardian join and approval \| Submitted details are ready for a decision and member follow-up. \| Needs decision \| Private notes \| Member notified \| Decision saved \| The decision is saved and ready for member follow-up. \| Decided \| Documents and data \| Documents, exports, import... | domain-native-reviewed / domain-native | No row-specific failure recorded. | request detail and admin review queue with submitted data, decision action, status, and notification |
| `b25-v4-row-034-soccer-team-roster-0` | Riverside Youth Soccer | `soccer-team-roster` | coach | B14_ext_youth_soccer_soccer-team-roster_start | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_youth_soccer_soccer-team-roster_start.png` | `8230bbf0e2c8e...` | Protected minor-data redaction \| You can review the current details without changing them. \| Redacted copy \| Checksum ready \| Exportable \| Read only \| Youth soccer export metadata \| Data package includes scope, protected fields, and handoff status. \| No ad shown \| Preference s... | domain-native-reviewed / domain-native | No row-specific failure recorded. | team roster/schedule surface with role-filtered member details and protected-data treatment |
| `b25-v4-row-035-soccer-team-roster-1` | Riverside Youth Soccer | `soccer-team-roster` | coach | B14_ext_youth_soccer_soccer-team-roster_action | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_youth_soccer_soccer-team-roster_action.png` | `4bc6451869607...` | Submit member form \| Use this surface to submit structured member details. \| Labeled fields \| Privacy checked \| Review handoff \| Details \| Required fields, privacy choices, and reviewer handoff are included. \| Member outcome \| The submission is routed to the reviewer with prot... | domain-native-reviewed / domain-native | No row-specific failure recorded. | team roster/schedule surface with role-filtered member details and protected-data treatment |
| `b25-v4-row-036-soccer-team-roster-2` | Riverside Youth Soccer | `soccer-team-roster` | coach | B14_ext_youth_soccer_soccer-team-roster_complete | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_youth_soccer_soccer-team-roster_complete.png` | `939ac73d9bc07...` | Youth soccer export metadata \| Data package includes scope, protected fields, and handoff status. \| No ad shown \| Preference saved \| Receipt ready \| Generate export \| Member tools \| Useful actions for this community. \| Team and roster view \| Member form captures labeled detail... | domain-native-reviewed / domain-native | No row-specific failure recorded. | team roster/schedule surface with role-filtered member details and protected-data treatment |
| `b25-v4-row-037-soccer-minor-redaction-0` | Riverside Youth Soccer | `soccer-minor-redaction` | guardian | B14_ext_youth_soccer_soccer-minor-redaction_start | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_youth_soccer_soccer-minor-redaction_start.png` | `6174e481c985e...` | Protected minor-data redaction \| Data package includes scope, protected fields, and handoff status. \| Redacted copy \| Checksum ready \| Exportable \| Preview redaction \| Youth soccer export metadata \| You can review the current details without changing them. \| No ad shown \| Pref... | domain-native-reviewed / domain-native | No row-specific failure recorded. | protected youth roster/profile surface with minor-data redaction, guardian visibility, and coach-only detail state |
| `b25-v4-row-038-soccer-minor-redaction-1` | Riverside Youth Soccer | `soccer-minor-redaction` | guardian | B14_ext_youth_soccer_soccer-minor-redaction_action | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_youth_soccer_soccer-minor-redaction_action.png` | `4f66cd7b27c38...` | Prepare export handoff \| Use this surface to package export scope, redaction, and handoff status. \| Redacted copy \| Checksum ready \| Exportable \| Details \| Scope, redaction, checksum, and handoff destination are included. \| Member outcome \| The export package can be inspected ... | domain-native-reviewed / domain-native | No row-specific failure recorded. | protected youth roster/profile surface with minor-data redaction, guardian visibility, and coach-only detail state |
| `b25-v4-row-039-soccer-minor-redaction-2` | Riverside Youth Soccer | `soccer-minor-redaction` | guardian | B14_ext_youth_soccer_soccer-minor-redaction_complete | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_youth_soccer_soccer-minor-redaction_complete.png` | `38727c8b383cb...` | Protected minor-data redaction \| Data package includes scope, protected fields, and handoff status. \| Redacted copy \| Checksum ready \| Exportable \| Data package ready \| The data package is ready with protected fields handled. \| Ready \| Youth soccer export metadata \| You can re... | domain-native-reviewed / domain-native | No row-specific failure recorded. | protected youth roster/profile surface with minor-data redaction, guardian visibility, and coach-only detail state |
| `b25-v4-row-040-soccer-registration-payment-0` | Riverside Youth Soccer | `soccer-registration-payment` | guardian | B14_ext_youth_soccer_soccer-registration-payment_start | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_youth_soccer_soccer-registration-payment_start.png` | `2f1f6e7e7c291...` | Registration payment \| Payment details include amount, payer, and receipt destination. \| Amount ready \| Receipt saved \| Member-owned \| Pay and save receipt \| Requests and approvals \| Requests that need a decision or member follow-up. \| Guardian join and approval \| A decision u... | domain-native-reviewed / domain-native | No row-specific failure recorded. | payment or donation flow with amount, payer context, receipt, entitlement/status, and audit trail |

### Failing Workflow/Persona Scorecards

Showing 17 of 17 failing scorecards. Full detail is in the JSON ticket.

| Scorecard | Community | Workflow | Persona | Failed questions | Target surface |
| --- | --- | --- | --- | ---: | --- |
| `b25-wp-002-plant-exchange-submission-community-garden-club-member` | Garden Club | `plant-exchange-submission` | member | 2 | plant exchange offer form and member marketplace surface with plant details, pickup timing, owner contact, and submitted offer state |
| `b25-wp-007-book-discussion-message-community-book-club-member` | Neighborhood Book Club | `book-discussion-message` | member | 2 | inbox, message thread, connection card, invite, or block-state surface |
| `b25-wp-008-book-selection-publish-community-book-club-owner` | Neighborhood Book Club | `book-selection-publish` | owner | 2 | announcement feed/composer with audience, author, timestamp, body, and receiver state |
| `b25-wp-013-soccer-minor-redaction-community-youth-soccer-guardian` | Riverside Youth Soccer | `soccer-minor-redaction` | guardian | 2 | protected youth roster/profile surface with minor-data redaction, guardian visibility, and coach-only detail state |
| `b25-wp-016-soccer-reminder-notification-community-youth-soccer-guardian` | Riverside Youth Soccer | `soccer-reminder-notification` | guardian | 2 | notification inbox/detail surface with sender, audience, timestamp, message body, and receiver state |
| `b25-wp-019-hoa-member-document-community-hoa-member` | Cedar Commons HOA | `hoa-member-document` | member | 2 | document library/detail surface with title, audience, file metadata, and access state |
| `b25-wp-021-hoa-architectural-request-community-hoa-owner` | Cedar Commons HOA | `hoa-architectural-request` | owner | 2 | request detail and admin review queue with submitted data, decision action, status, and notification |
| `b25-wp-023-hoa-owner-notification-community-hoa-owner` | Cedar Commons HOA | `hoa-owner-notification` | owner | 2 | notification inbox/detail surface with sender, audience, timestamp, message body, and receiver state |
| `b25-wp-025-mosque-announcement-community-mosque-owner` | Masjid Nur | `mosque-announcement` | owner | 2 | announcement feed/composer with audience, author, timestamp, body, and receiver state |
| `b25-wp-028-mosque-donor-visibility-community-mosque-donor` | Masjid Nur | `mosque-donor-visibility` | donor | 2 | donor privacy preference surface with visibility choice, donation context, confirmation, and receipt visibility state |
| `b25-wp-031-mosque-neutral-notification-community-mosque-member` | Masjid Nur | `mosque-neutral-notification` | member | 2 | notification inbox/detail surface with sender, audience, timestamp, message body, and receiver state |
| `b25-wp-033-chess-local-install-open-community-chess-club-member` | Chess Club | `chess-local-install-open` | member | 2 | match schedule/result surface with players, round, outcome, and next action |
| `b25-wp-034-chess-route-home-community-chess-club-member` | Chess Club | `chess-route-home` | member | 2 | match schedule/result surface with players, round, outcome, and next action |
| `b25-wp-035-chess-match-result-community-chess-club-member` | Chess Club | `chess-match-result` | member | 2 | match schedule/result surface with players, round, outcome, and next action |
| `b25-wp-037-critique-submission-community-camera-club-member` | Camera Club | `critique-submission` | member | 2 | critique submission/review surface with image/work title, comments, reviewer state, and result |
| `b25-wp-038-gear-loan-request-community-camera-club-member` | Camera Club | `gear-loan-request` | member | 2 | request detail and admin review queue with submitted data, decision action, status, and notification |
| `b25-wp-043-platform-message-stream-community-platform-social-member` | Member Social Space | `platform-message-stream` | member | 2 | inbox, message thread, connection card, invite, or block-state surface |

### Failing Workflow Lifecycle / Interaction Model Scorecards

Showing 40 of 62 failing lifecycle scorecards. Full semantic interaction-model detail is in the JSON ticket.

| Scorecard | Community | Workflow | Persona | Expected decision | Missing lifecycle groups | Missing actions | Wrong generic substitutes | Target surface |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `b25-wp-001-garden-event-rsvp-community-garden-club-member-lifecycle` | Garden Club | `garden-event-rsvp` | member | Member decides attendance for a named dated event with time, location, capacity/status, and a later change path. | alternate/change/reject affordance; semantic interaction model | domain-specific alternate/change/reject action | cancel; confirm | event detail with schedule, location, capacity/status, RSVP action, and result state |
| `b25-wp-002-plant-exchange-submission-community-garden-club-member-lifecycle` | Garden Club | `plant-exchange-submission` | member | Member evaluates a concrete plant exchange item with owner, pickup details, availability, and claim/cancel paths. | decision information; semantic interaction model | domain-specific primary action; domain-specific alternate/change/reject action | cancel | plant exchange offer form and member marketplace surface with plant details, pickup timing, owner contact, and submitted offer state |
| `b25-wp-003-garden-export-custom-schemas-community-garden-club-owner-lifecycle` | Garden Club | `garden-export-custom-schemas` | owner | Admin selects export/import/transfer scope, reviews redaction/checksum/status, and can cancel, retry, or roll back. | semantic interaction model | domain-specific alternate/change/reject action | cancel | export/import wizard with preview, redaction, checksum, transfer status, and rollback state |
| `b25-wp-004-book-nomination-community-book-club-member-lifecycle` | Neighborhood Book Club | `book-nomination` | member | User decides a concrete community task with enough context, a semantic primary action, a meaningful alternative, and a durable result. | persistent result state; receiver/continuation state; semantic interaction model | domain-specific alternate/change/reject action | cancel; ok | book club reading/voting surface with nominations, vote state, selected book, meeting context, and discussion |
| `b25-wp-005-book-vote-community-book-club-member-lifecycle` | Neighborhood Book Club | `book-vote` | member | User decides a concrete community task with enough context, a semantic primary action, a meaningful alternative, and a durable result. | persistent result state; receiver/continuation state; semantic interaction model | domain-specific alternate/change/reject action | cancel; ok | book club reading/voting surface with nominations, vote state, selected book, meeting context, and discussion |
| `b25-wp-006-book-meeting-rsvp-community-book-club-member-lifecycle` | Neighborhood Book Club | `book-meeting-rsvp` | member | Member decides attendance for a named dated event with time, location, capacity/status, and a later change path. | alternate/change/reject affordance; semantic interaction model | domain-specific alternate/change/reject action | cancel; confirm; ok | event detail with schedule, location, capacity/status, RSVP action, and result state |
| `b25-wp-007-book-discussion-message-community-book-club-member-lifecycle` | Neighborhood Book Club | `book-discussion-message` | member | Member evaluates a concrete message, connection, or invite with sender/recipient context and accept/decline/block paths. | primary semantic action; persistent result state; receiver/continuation state; semantic interaction model | domain-specific primary action; domain-specific alternate/change/reject action | cancel; ok | inbox, message thread, connection card, invite, or block-state surface |
| `b25-wp-008-book-selection-publish-community-book-club-owner-lifecycle` | Neighborhood Book Club | `book-selection-publish` | owner | Admin decides whether a concrete announcement is ready for a named audience and delivery timing; members can later read the delivered update. | semantic interaction model | domain-specific primary action; domain-specific alternate/change/reject action | cancel; ok | announcement feed/composer with audience, author, timestamp, body, and receiver state |
| `b25-wp-009-book-search-ai-digest-community-book-club-member-lifecycle` | Neighborhood Book Club | `book-search-ai-digest` | member | User decides a concrete community task with enough context, a semantic primary action, a meaningful alternative, and a durable result. | receiver/continuation state; semantic interaction model | domain-specific alternate/change/reject action | cancel; confirm; ok | search/AI answer surface with query, result, citation, source, and follow-up action |
| `b25-wp-010-book-export-metadata-community-book-club-owner-lifecycle` | Neighborhood Book Club | `book-export-metadata` | owner | Admin selects export/import/transfer scope, reviews redaction/checksum/status, and can cancel, retry, or roll back. | semantic interaction model | domain-specific alternate/change/reject action | cancel; ok | export/import wizard with preview, redaction, checksum, transfer status, and rollback state |
| `b25-wp-011-soccer-guardian-join-approval-community-youth-soccer-guardian-lifecycle` | Riverside Youth Soccer | `soccer-guardian-join-approval` | guardian | Reviewer or requester evaluates a concrete request with requester, details, status, and approve/reject/change paths. | alternate/change/reject affordance; semantic interaction model | domain-specific alternate/change/reject action | cancel | request detail and admin review queue with submitted data, decision action, status, and notification |
| `b25-wp-012-soccer-team-roster-community-youth-soccer-coach-lifecycle` | Riverside Youth Soccer | `soccer-team-roster` | coach | User decides a concrete community task with enough context, a semantic primary action, a meaningful alternative, and a durable result. | semantic interaction model | domain-specific alternate/change/reject action | cancel | team roster/schedule surface with role-filtered member details and protected-data treatment |
| `b25-wp-013-soccer-minor-redaction-community-youth-soccer-guardian-lifecycle` | Riverside Youth Soccer | `soccer-minor-redaction` | guardian | User decides a concrete community task with enough context, a semantic primary action, a meaningful alternative, and a durable result. | semantic interaction model | domain-specific alternate/change/reject action | cancel | protected youth roster/profile surface with minor-data redaction, guardian visibility, and coach-only detail state |
| `b25-wp-014-soccer-registration-payment-community-youth-soccer-guardian-lifecycle` | Riverside Youth Soccer | `soccer-registration-payment` | guardian | Payer decides what amount or entitlement to pay for, sees cost/recipient/visibility, and can change or manage the payment. | semantic interaction model | domain-specific alternate/change/reject action | cancel | payment or donation flow with amount, payer context, receipt, entitlement/status, and audit trail |
| `b25-wp-015-soccer-practice-schedule-community-youth-soccer-guardian-lifecycle` | Riverside Youth Soccer | `soccer-practice-schedule` | guardian | Member decides attendance for a named dated event with time, location, capacity/status, and a later change path. | alternate/change/reject affordance; persistent result state; semantic interaction model | domain-specific alternate/change/reject action | cancel | event detail with schedule, location, capacity/status, RSVP action, and result state |
| `b25-wp-016-soccer-reminder-notification-community-youth-soccer-guardian-lifecycle` | Riverside Youth Soccer | `soccer-reminder-notification` | guardian | User decides a concrete community task with enough context, a semantic primary action, a meaningful alternative, and a durable result. | persistent result state; receiver/continuation state; semantic interaction model | domain-specific alternate/change/reject action | cancel | notification inbox/detail surface with sender, audience, timestamp, message body, and receiver state |
| `b25-wp-017-soccer-export-metadata-community-youth-soccer-owner-lifecycle` | Riverside Youth Soccer | `soccer-export-metadata` | owner | Admin selects export/import/transfer scope, reviews redaction/checksum/status, and can cancel, retry, or roll back. | semantic interaction model | domain-specific alternate/change/reject action | cancel | export/import wizard with preview, redaction, checksum, transfer status, and rollback state |
| `b25-wp-018-hoa-dues-payment-community-hoa-member-lifecycle` | Cedar Commons HOA | `hoa-dues-payment` | member | Payer decides what amount or entitlement to pay for, sees cost/recipient/visibility, and can change or manage the payment. | semantic interaction model | domain-specific alternate/change/reject action | cancel | payment or donation flow with amount, payer context, receipt, entitlement/status, and audit trail |
| `b25-wp-019-hoa-member-document-community-hoa-member-lifecycle` | Cedar Commons HOA | `hoa-member-document` | member | Member decides whether to open, acknowledge, save, or share a concrete document with title, date, owner, and status. | decision information |  |  | document library/detail surface with title, audience, file metadata, and access state |
| `b25-wp-020-hoa-facility-reservation-community-hoa-member-lifecycle` | Cedar Commons HOA | `hoa-facility-reservation` | member | User decides a concrete community task with enough context, a semantic primary action, a meaningful alternative, and a durable result. | semantic interaction model | domain-specific alternate/change/reject action | cancel | facility detail/reservation flow with availability, payment/status, and confirmation |
| `b25-wp-021-hoa-architectural-request-community-hoa-owner-lifecycle` | Cedar Commons HOA | `hoa-architectural-request` | owner | Reviewer or requester evaluates a concrete request with requester, details, status, and approve/reject/change paths. | alternate/change/reject affordance; semantic interaction model | domain-specific alternate/change/reject action | cancel | request detail and admin review queue with submitted data, decision action, status, and notification |
| `b25-wp-022-hoa-committee-decision-community-hoa-owner-lifecycle` | Cedar Commons HOA | `hoa-committee-decision` | owner | User decides a concrete community task with enough context, a semantic primary action, a meaningful alternative, and a durable result. | semantic interaction model | domain-specific alternate/change/reject action | cancel | request detail and admin review queue with submitted data, decision action, status, and notification |
| `b25-wp-023-hoa-owner-notification-community-hoa-owner-lifecycle` | Cedar Commons HOA | `hoa-owner-notification` | owner | User decides a concrete community task with enough context, a semantic primary action, a meaningful alternative, and a durable result. | persistent result state; receiver/continuation state; semantic interaction model | domain-specific alternate/change/reject action | cancel | notification inbox/detail surface with sender, audience, timestamp, message body, and receiver state |
| `b25-wp-024-hoa-export-evidence-community-hoa-owner-lifecycle` | Cedar Commons HOA | `hoa-export-evidence` | owner | Admin selects export/import/transfer scope, reviews redaction/checksum/status, and can cancel, retry, or roll back. | semantic interaction model | domain-specific alternate/change/reject action | cancel | export/import wizard with preview, redaction, checksum, transfer status, and rollback state |
| `b25-wp-025-mosque-announcement-community-mosque-owner-lifecycle` | Masjid Nur | `mosque-announcement` | owner | Admin decides whether a concrete announcement is ready for a named audience and delivery timing; members can later read the delivered update. | semantic interaction model | domain-specific alternate/change/reject action | cancel | announcement feed/composer with audience, author, timestamp, body, and receiver state |
| `b25-wp-026-mosque-event-rsvp-community-mosque-member-lifecycle` | Masjid Nur | `mosque-event-rsvp` | member | Member decides attendance for a named dated event with time, location, capacity/status, and a later change path. | alternate/change/reject affordance; semantic interaction model | domain-specific alternate/change/reject action | cancel; confirm | event detail with schedule, location, capacity/status, RSVP action, and result state |
| `b25-wp-027-mosque-volunteer-signup-community-mosque-member-lifecycle` | Masjid Nur | `mosque-volunteer-signup` | member | User decides a concrete community task with enough context, a semantic primary action, a meaningful alternative, and a durable result. | persistent result state; receiver/continuation state; semantic interaction model | domain-specific alternate/change/reject action | cancel | volunteer signup surface with role, time, protected contact fields, and confirmation |
| `b25-wp-028-mosque-donor-visibility-community-mosque-donor-lifecycle` | Masjid Nur | `mosque-donor-visibility` | donor | User decides a concrete community task with enough context, a semantic primary action, a meaningful alternative, and a durable result. | persistent result state; receiver/continuation state; semantic interaction model | domain-specific alternate/change/reject action | cancel | donor privacy preference surface with visibility choice, donation context, confirmation, and receipt visibility state |
| `b25-wp-029-mosque-donation-payment-community-mosque-donor-lifecycle` | Masjid Nur | `mosque-donation-payment` | donor | Payer decides what amount or entitlement to pay for, sees cost/recipient/visibility, and can change or manage the payment. | semantic interaction model | domain-specific alternate/change/reject action | cancel | payment or donation flow with amount, payer context, receipt, entitlement/status, and audit trail |
| `b25-wp-030-mosque-care-request-community-mosque-member-lifecycle` | Masjid Nur | `mosque-care-request` | member | Reviewer or requester evaluates a concrete request with requester, details, status, and approve/reject/change paths. | alternate/change/reject affordance; persistent result state; semantic interaction model | domain-specific alternate/change/reject action | cancel | protected care request form and private response/status surface |
| `b25-wp-031-mosque-neutral-notification-community-mosque-member-lifecycle` | Masjid Nur | `mosque-neutral-notification` | member | User decides a concrete community task with enough context, a semantic primary action, a meaningful alternative, and a durable result. | semantic interaction model | domain-specific alternate/change/reject action | cancel | notification inbox/detail surface with sender, audience, timestamp, message body, and receiver state |
| `b25-wp-032-mosque-search-ai-citation-community-mosque-member-lifecycle` | Masjid Nur | `mosque-search-ai-citation` | member | User decides a concrete community task with enough context, a semantic primary action, a meaningful alternative, and a durable result. | semantic interaction model | domain-specific alternate/change/reject action | cancel | search/AI answer surface with query, result, citation, source, and follow-up action |
| `b25-wp-033-chess-local-install-open-community-chess-club-member-lifecycle` | Chess Club | `chess-local-install-open` | member | Participant records or reviews a concrete match with opponent, score/result, and correction/dispute paths. | alternate/change/reject affordance; receiver/continuation state; semantic interaction model | domain-specific primary action; domain-specific alternate/change/reject action | cancel | match schedule/result surface with players, round, outcome, and next action |
| `b25-wp-034-chess-route-home-community-chess-club-member-lifecycle` | Chess Club | `chess-route-home` | member | Participant records or reviews a concrete match with opponent, score/result, and correction/dispute paths. | alternate/change/reject affordance; receiver/continuation state; semantic interaction model | domain-specific primary action; domain-specific alternate/change/reject action | cancel | match schedule/result surface with players, round, outcome, and next action |
| `b25-wp-035-chess-match-result-community-chess-club-member-lifecycle` | Chess Club | `chess-match-result` | member | Participant records or reviews a concrete match with opponent, score/result, and correction/dispute paths. | alternate/change/reject affordance; receiver/continuation state; semantic interaction model | domain-specific alternate/change/reject action | cancel | match schedule/result surface with players, round, outcome, and next action |
| `b25-wp-036-photo-walk-rsvp-community-camera-club-member-lifecycle` | Camera Club | `photo-walk-rsvp` | member | Member decides attendance for a named dated event with time, location, capacity/status, and a later change path. | alternate/change/reject affordance; semantic interaction model | domain-specific alternate/change/reject action | cancel; confirm | event detail with schedule, location, capacity/status, RSVP action, and result state |
| `b25-wp-037-critique-submission-community-camera-club-member-lifecycle` | Camera Club | `critique-submission` | member | Participant reviews or submits a concrete critique item with content, author, feedback, and edit/withdraw paths. | alternate/change/reject affordance; semantic interaction model | domain-specific primary action; domain-specific alternate/change/reject action | cancel | critique submission/review surface with image/work title, comments, reviewer state, and result |
| `b25-wp-038-gear-loan-request-community-camera-club-member-lifecycle` | Camera Club | `gear-loan-request` | member | Reviewer or requester evaluates a concrete request with requester, details, status, and approve/reject/change paths. | alternate/change/reject affordance; semantic interaction model | domain-specific alternate/change/reject action | cancel | request detail and admin review queue with submitted data, decision action, status, and notification |
| `b25-wp-039-platform-messages-entry-community-platform-social-member-lifecycle` | Member Social Space | `platform-messages-entry` | member | Member evaluates a concrete message, connection, or invite with sender/recipient context and accept/decline/block paths. | persistent result state; semantic interaction model | domain-specific alternate/change/reject action | cancel | inbox, message thread, connection card, invite, or block-state surface |
| `b25-wp-040-platform-connections-entry-community-platform-social-member-lifecycle` | Member Social Space | `platform-connections-entry` | member | Member evaluates a concrete message, connection, or invite with sender/recipient context and accept/decline/block paths. | persistent result state; semantic interaction model | domain-specific alternate/change/reject action | cancel | inbox, message thread, connection card, invite, or block-state surface |

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
- Screen row `b25-v4-row-001-garden-event-rsvp-0` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-001-garden-event-rsvp-0` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-001-garden-event-rsvp-0` names visible UI elements, visible text, persona `member`, workflow `garden-event-rsvp`, and the exact product UX issue.
- Primary surface for `garden-event-rsvp` is documented as `event detail with schedule, location, capacity/status, RSVP action, and result state` or another explicit domain-native surface.
- After-screenshot visible text proves every required semantic surface group for `garden-event-rsvp`.
- Fresh screenshot path/hash/timestamp/app commit SHA are recorded after the fix.
- The workflow lifecycle scorecard passes with no missing object/context, decision information, action affordance, result state, or receiver/continuation groups.
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
- Critique for `b25-v4-row-010-book-nomination-0` names visible UI elements, visible text, persona `member`, workflow `book-nomination`, and the exact product UX issue.
- Primary surface for `book-nomination` is documented as `book club reading/voting surface with nominations, vote state, selected book, meeting context, and discussion` or another explicit domain-native surface.
- After-screenshot visible text proves every required semantic surface group for `book-nomination`.
- Screen row `b25-v4-row-011-book-nomination-1` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-011-book-nomination-1` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-011-book-nomination-1` names visible UI elements, visible text, persona `member`, workflow `book-nomination`, and the exact product UX issue.
- Screen row `b25-v4-row-012-book-nomination-2` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-012-book-nomination-2` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-012-book-nomination-2` names visible UI elements, visible text, persona `member`, workflow `book-nomination`, and the exact product UX issue.
- Coverage row has a specific persona and personaId.
- Coverage row has entry, action/review, and result/receiver screenshots.
- Every listed screenshot path exists and has a fresh hash/timestamp/app commit SHA.
- The workflow/persona scorecard passes after rerun.
- All lifecycle direct questions in this workflow/persona scorecard pass.
- The UI visibly proves the concrete object/context, decision information, primary action, alternate/change/reject affordance, persistent result state, and receiver/continuation state.
- The semantic interaction model passes: expected decision, required primary actions, and required alternate/change/reject actions are visible in fresh after screenshots.
- Missing lifecycle groups are resolved: alternate/change/reject affordance, semantic interaction model.
- Fresh after screenshots prove the lifecycle and interaction model; implementation notes, code diffs, or ticket responses alone cannot close this ticket.
- The `garden-event-rsvp` screenshots show the concrete domain object/context for `member`.
- The user can see enough domain-specific decision information before acting.
- The UI provides semantic primary action and the needed alternate/change/reject/defer path; `Cancel` alone cannot stand in for a real decline/reject/change response.
- The semantic interaction model names the correct user decision and the right domain actions for `garden-event-rsvp`; generic accept/cancel or submit/cancel actions do not satisfy this criterion.
- The post-action screen shows a persistent result/receipt/status state that can be understood later.
- The receiver/read-only/continuation state is visible where another persona or later state is part of the workflow.
- The workflow lifecycle scorecard passes with no missing lifecycle groups.
- Screen row `b25-wp-001-garden-event-rsvp-community-garden-club-member` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-wp-001-garden-event-rsvp-community-garden-club-member` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-wp-001-garden-event-rsvp-community-garden-club-member` names visible UI elements, visible text, persona `member`, workflow `garden-event-rsvp`, and the exact product UX issue.
- Missing lifecycle groups are resolved: decision information, semantic interaction model.
- The `plant-exchange-submission` screenshots show the concrete domain object/context for `member`.
- The semantic interaction model names the correct user decision and the right domain actions for `plant-exchange-submission`; generic accept/cancel or submit/cancel actions do not satisfy this criterion.
- Screen row `b25-wp-002-plant-exchange-submission-community-garden-club-member` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-wp-002-plant-exchange-submission-community-garden-club-member` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-wp-002-plant-exchange-submission-community-garden-club-member` names visible UI elements, visible text, persona `member`, workflow `plant-exchange-submission`, and the exact product UX issue.
- Missing lifecycle groups are resolved: semantic interaction model.
- The `garden-export-custom-schemas` screenshots show the concrete domain object/context for `owner`.
- The semantic interaction model names the correct user decision and the right domain actions for `garden-export-custom-schemas`; generic accept/cancel or submit/cancel actions do not satisfy this criterion.
- Screen row `b25-wp-003-garden-export-custom-schemas-community-garden-club-owner` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-wp-003-garden-export-custom-schemas-community-garden-club-owner` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-wp-003-garden-export-custom-schemas-community-garden-club-owner` names visible UI elements, visible text, persona `owner`, workflow `garden-export-custom-schemas`, and the exact product UX issue.
- Missing lifecycle groups are resolved: persistent result state, receiver/continuation state, semantic interaction model.
- The `book-nomination` screenshots show the concrete domain object/context for `member`.
- The semantic interaction model names the correct user decision and the right domain actions for `book-nomination`; generic accept/cancel or submit/cancel actions do not satisfy this criterion.
- Screen row `b25-wp-004-book-nomination-community-book-club-member` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-wp-004-book-nomination-community-book-club-member` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-wp-004-book-nomination-community-book-club-member` names visible UI elements, visible text, persona `member`, workflow `book-nomination`, and the exact product UX issue.
- The `book-vote` screenshots show the concrete domain object/context for `member`.
- The semantic interaction model names the correct user decision and the right domain actions for `book-vote`; generic accept/cancel or submit/cancel actions do not satisfy this criterion.
- Screen row `b25-wp-005-book-vote-community-book-club-member` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-wp-005-book-vote-community-book-club-member` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-wp-005-book-vote-community-book-club-member` names visible UI elements, visible text, persona `member`, workflow `book-vote`, and the exact product UX issue.
- Primary surface for `book-vote` is documented as `book club reading/voting surface with nominations, vote state, selected book, meeting context, and discussion` or another explicit domain-native surface.
- After-screenshot visible text proves every required semantic surface group for `book-vote`.
- The `book-meeting-rsvp` screenshots show the concrete domain object/context for `member`.
- The semantic interaction model names the correct user decision and the right domain actions for `book-meeting-rsvp`; generic accept/cancel or submit/cancel actions do not satisfy this criterion.
- Screen row `b25-wp-006-book-meeting-rsvp-community-book-club-member` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-wp-006-book-meeting-rsvp-community-book-club-member` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-wp-006-book-meeting-rsvp-community-book-club-member` names visible UI elements, visible text, persona `member`, workflow `book-meeting-rsvp`, and the exact product UX issue.
- Primary surface for `book-meeting-rsvp` is documented as `event detail with schedule, location, capacity/status, RSVP action, and result state` or another explicit domain-native surface.
- After-screenshot visible text proves every required semantic surface group for `book-meeting-rsvp`.
- Missing lifecycle groups are resolved: primary semantic action, persistent result state, receiver/continuation state, semantic interaction model.
- The `book-discussion-message` screenshots show the concrete domain object/context for `member`.
- The semantic interaction model names the correct user decision and the right domain actions for `book-discussion-message`; generic accept/cancel or submit/cancel actions do not satisfy this criterion.
- Screen row `b25-wp-007-book-discussion-message-community-book-club-member` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-wp-007-book-discussion-message-community-book-club-member` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-wp-007-book-discussion-message-community-book-club-member` names visible UI elements, visible text, persona `member`, workflow `book-discussion-message`, and the exact product UX issue.
- Primary surface for `book-discussion-message` is documented as `inbox, message thread, connection card, invite, or block-state surface` or another explicit domain-native surface.
- After-screenshot visible text proves every required semantic surface group for `book-discussion-message`.
- The `book-selection-publish` screenshots show the concrete domain object/context for `owner`.
- The semantic interaction model names the correct user decision and the right domain actions for `book-selection-publish`; generic accept/cancel or submit/cancel actions do not satisfy this criterion.
- Screen row `b25-wp-008-book-selection-publish-community-book-club-owner` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-wp-008-book-selection-publish-community-book-club-owner` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-wp-008-book-selection-publish-community-book-club-owner` names visible UI elements, visible text, persona `owner`, workflow `book-selection-publish`, and the exact product UX issue.
- Primary surface for `book-selection-publish` is documented as `announcement feed/composer with audience, author, timestamp, body, and receiver state` or another explicit domain-native surface.
- After-screenshot visible text proves every required semantic surface group for `book-selection-publish`.
- Missing lifecycle groups are resolved: receiver/continuation state, semantic interaction model.
- The `book-search-ai-digest` screenshots show the concrete domain object/context for `member`.
- The semantic interaction model names the correct user decision and the right domain actions for `book-search-ai-digest`; generic accept/cancel or submit/cancel actions do not satisfy this criterion.
- Screen row `b25-wp-009-book-search-ai-digest-community-book-club-member` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-wp-009-book-search-ai-digest-community-book-club-member` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-wp-009-book-search-ai-digest-community-book-club-member` names visible UI elements, visible text, persona `member`, workflow `book-search-ai-digest`, and the exact product UX issue.
- Primary surface for `book-search-ai-digest` is documented as `search/AI answer surface with query, result, citation, source, and follow-up action` or another explicit domain-native surface.
- After-screenshot visible text proves every required semantic surface group for `book-search-ai-digest`.
- The `book-export-metadata` screenshots show the concrete domain object/context for `owner`.
- The semantic interaction model names the correct user decision and the right domain actions for `book-export-metadata`; generic accept/cancel or submit/cancel actions do not satisfy this criterion.
- Screen row `b25-wp-010-book-export-metadata-community-book-club-owner` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-wp-010-book-export-metadata-community-book-club-owner` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-wp-010-book-export-metadata-community-book-club-owner` names visible UI elements, visible text, persona `owner`, workflow `book-export-metadata`, and the exact product UX issue.
- Primary surface for `book-export-metadata` is documented as `export/import wizard with preview, redaction, checksum, transfer status, and rollback state` or another explicit domain-native surface.
- After-screenshot visible text proves every required semantic surface group for `book-export-metadata`.
- The `soccer-guardian-join-approval` screenshots show the concrete domain object/context for `guardian`.
- The semantic interaction model names the correct user decision and the right domain actions for `soccer-guardian-join-approval`; generic accept/cancel or submit/cancel actions do not satisfy this criterion.
- Screen row `b25-wp-011-soccer-guardian-join-approval-community-youth-soccer-guardian` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-wp-011-soccer-guardian-join-approval-community-youth-soccer-guardian` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-wp-011-soccer-guardian-join-approval-community-youth-soccer-guardian` names visible UI elements, visible text, persona `guardian`, workflow `soccer-guardian-join-approval`, and the exact product UX issue.
- Primary surface for `soccer-guardian-join-approval` is documented as `request detail and admin review queue with submitted data, decision action, status, and notification` or another explicit domain-native surface.
- After-screenshot visible text proves every required semantic surface group for `soccer-guardian-join-approval`.
- The `soccer-team-roster` screenshots show the concrete domain object/context for `coach`.
- The semantic interaction model names the correct user decision and the right domain actions for `soccer-team-roster`; generic accept/cancel or submit/cancel actions do not satisfy this criterion.
- Screen row `b25-wp-012-soccer-team-roster-community-youth-soccer-coach` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-wp-012-soccer-team-roster-community-youth-soccer-coach` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-wp-012-soccer-team-roster-community-youth-soccer-coach` names visible UI elements, visible text, persona `coach`, workflow `soccer-team-roster`, and the exact product UX issue.
- Primary surface for `soccer-team-roster` is documented as `team roster/schedule surface with role-filtered member details and protected-data treatment` or another explicit domain-native surface.
- After-screenshot visible text proves every required semantic surface group for `soccer-team-roster`.

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
| Review run | `b25-v4-pass-9` |
| Source criterion | `b25-c08-visible-text-specific-critique` |
| Source findings | B25-WORKFLOW-LIFECYCLE-INCOMPLETE |
| Title | Every row has visible text and screen-specific critique |
| Direct question | Does every holistic and workflow/persona review answer cite visible UI/text and provide a critique specific to that screenshot and user task? |
| Why it failed | Workflow/persona direct-question scorecards have missing or blocking answers: plant-exchange-submission/member, book-discussion-message/member, book-selection-publish/owner, soccer-minor-redaction/guardian, soccer-reminder-notification/guardian, hoa-member-document/member, hoa-architectural-request/owner, hoa-owner-notification/owner, mosque-announcement/owner, mosque-donor-visibility/donor, mosque-neutral-notification/member, chess-local-install-open/member, chess-route-home/member, chess-match-result/member, critique-submission/member, gear-loan-request/member, platform-message-stream/member. |
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
| Material detail surface composition | Material Design 3 / design-system | https://m3.material.io/components/cards/overview | Build a domain detail page with primary content, metadata, status, and actions instead of a generic task card. |
| Material navigation and information architecture | Material Design 3 / design-system | https://m3.material.io/components/navigation-drawer/overview<br>Also: https://m3.material.io/components/navigation-bar/overview | Organize screens by user jobs and destinations; keep primary actions visible and avoid exposing implementation taxonomy. |
| Apple HIG navigation and content organization | Apple Human Interface Guidelines / design-system | https://developer.apple.com/design/human-interface-guidelines/navigation | Make navigation predictable, content-centered, and appropriate for the user’s current task. |
| Inbox and message thread pattern | Material lists/text fields / pattern | https://m3.material.io/components/lists/overview<br>Also: https://m3.material.io/components/text-fields/overview | Copy an inbox/thread structure: sender, timestamp, message preview/body, reply field, invite/block state, and read/received state. |
| Feed item and composer pattern | Material cards/lists/text fields / pattern | https://m3.material.io/components/text-fields/overview<br>Also: https://m3.material.io/components/cards/overview<br>https://m3.material.io/components/lists/overview | Copy a feed/composer structure: audience, author, timestamp, body, attachments/status, publish action, and receiver read state. |
| Document list/detail pattern | Material lists/cards / pattern | https://m3.material.io/components/lists/overview | Copy a document library with title, category, audience, file metadata, access state, download/view action, and empty/error states. |
| Form validation and review pattern | U.S. Web Design System / design-system | https://designsystem.digital.gov/components/form/<br>Also: https://designsystem.digital.gov/components/alert/<br>https://design-system.service.gov.uk/components/error-summary/ | Copy a form flow with field labels, helper text, validation errors, review state, submit action, status, and protected-data treatment. |
| Match schedule and result pattern | Material lists/cards / pattern | https://m3.material.io/components/lists/overview | Copy a match surface with players, schedule/round, result entry, result state, and next action. |

### Reference Research Queries
- production mobile UX review screenshot critique examples
- open source Flutter mobile app UX patterns GitHub
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
- Material Design document library/detail surface with title, audience, file metadata, and access state mobile pattern
- open source Flutter form-review mobile UI example GitHub
- request detail and admin review queue with submitted data, decision action, status, and notification mobile UX pattern

### Implementation Blocked By
- Affected rows still use generic or missing persona data.
- Visible text is not proven from screenshot OCR/manual extraction.
- Screen-specific critiques are incomplete or reusable.
- Primary surface classification is incomplete or unverified.

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

### Affected Workflow/Persona Coverage

Showing 17 of 17 affected coverage rows. Full detail is in the JSON ticket.

| Coverage row | Status | Community | Workflow | Persona | Missing evidence | Screen rows | Target surface |
| --- | --- | --- | --- | --- | --- | ---: | --- |
| `b25-wp-002-plant-exchange-submission-community-garden-club-member` | `pass` | Garden Club | `plant-exchange-submission` | member |  | 3 | plant exchange offer form and member marketplace surface with plant details, pickup timing, owner contact, and submitted offer state |
| `b25-wp-007-book-discussion-message-community-book-club-member` | `pass` | Neighborhood Book Club | `book-discussion-message` | member |  | 3 | inbox, message thread, connection card, invite, or block-state surface |
| `b25-wp-008-book-selection-publish-community-book-club-owner` | `pass` | Neighborhood Book Club | `book-selection-publish` | owner |  | 3 | announcement feed/composer with audience, author, timestamp, body, and receiver state |
| `b25-wp-013-soccer-minor-redaction-community-youth-soccer-guardian` | `pass` | Riverside Youth Soccer | `soccer-minor-redaction` | guardian |  | 3 | protected youth roster/profile surface with minor-data redaction, guardian visibility, and coach-only detail state |
| `b25-wp-016-soccer-reminder-notification-community-youth-soccer-guardian` | `pass` | Riverside Youth Soccer | `soccer-reminder-notification` | guardian |  | 3 | notification inbox/detail surface with sender, audience, timestamp, message body, and receiver state |
| `b25-wp-019-hoa-member-document-community-hoa-member` | `pass` | Cedar Commons HOA | `hoa-member-document` | member |  | 3 | document library/detail surface with title, audience, file metadata, and access state |
| `b25-wp-021-hoa-architectural-request-community-hoa-owner` | `pass` | Cedar Commons HOA | `hoa-architectural-request` | owner |  | 3 | request detail and admin review queue with submitted data, decision action, status, and notification |
| `b25-wp-023-hoa-owner-notification-community-hoa-owner` | `pass` | Cedar Commons HOA | `hoa-owner-notification` | owner |  | 3 | notification inbox/detail surface with sender, audience, timestamp, message body, and receiver state |
| `b25-wp-025-mosque-announcement-community-mosque-owner` | `pass` | Masjid Nur | `mosque-announcement` | owner |  | 3 | announcement feed/composer with audience, author, timestamp, body, and receiver state |
| `b25-wp-028-mosque-donor-visibility-community-mosque-donor` | `pass` | Masjid Nur | `mosque-donor-visibility` | donor |  | 3 | donor privacy preference surface with visibility choice, donation context, confirmation, and receipt visibility state |
| `b25-wp-031-mosque-neutral-notification-community-mosque-member` | `pass` | Masjid Nur | `mosque-neutral-notification` | member |  | 3 | notification inbox/detail surface with sender, audience, timestamp, message body, and receiver state |
| `b25-wp-033-chess-local-install-open-community-chess-club-member` | `pass` | Chess Club | `chess-local-install-open` | member |  | 3 | match schedule/result surface with players, round, outcome, and next action |
| `b25-wp-034-chess-route-home-community-chess-club-member` | `pass` | Chess Club | `chess-route-home` | member |  | 3 | match schedule/result surface with players, round, outcome, and next action |
| `b25-wp-035-chess-match-result-community-chess-club-member` | `pass` | Chess Club | `chess-match-result` | member |  | 3 | match schedule/result surface with players, round, outcome, and next action |
| `b25-wp-037-critique-submission-community-camera-club-member` | `pass` | Camera Club | `critique-submission` | member |  | 3 | critique submission/review surface with image/work title, comments, reviewer state, and result |
| `b25-wp-038-gear-loan-request-community-camera-club-member` | `pass` | Camera Club | `gear-loan-request` | member |  | 3 | request detail and admin review queue with submitted data, decision action, status, and notification |
| `b25-wp-043-platform-message-stream-community-platform-social-member` | `pass` | Member Social Space | `platform-message-stream` | member |  | 3 | inbox, message thread, connection card, invite, or block-state surface |

### Affected Screen Rows

Showing 40 of 51 affected screen rows. Full detail is in the JSON ticket.

| Screen row | Community | Workflow | Persona | State | Screenshot | Hash | Visible text | Current surface | Exact UX failure | Target surface |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `b25-v4-row-004-plant-exchange-submission-0` | Garden Club | `plant-exchange-submission` | member | B13_ext_garden_club_plant-exchange-submission_start | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B13/screenshots/B13_ext_garden_club_plant-exchange-submission_start.png` | `7e5e418252089...` | Care and volunteers \| Private requests, volunteer shifts, and member support. \| Plant exchange submission \| Member form captures labeled details, privacy choices, and reviewer handoff. \| Labeled fields \| Privacy checked \| Review handoff \| Submit entry \| Documents and data \| Do... | domain-native-reviewed / domain-native | Ticket must add screenshot-backed visible text and a non-reusable critique for this exact screen. | plant exchange offer form and member marketplace surface with plant details, pickup timing, owner contact, and submitted offer state |
| `b25-v4-row-005-plant-exchange-submission-1` | Garden Club | `plant-exchange-submission` | member | B13_ext_garden_club_plant-exchange-submission_action | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B13/screenshots/B13_ext_garden_club_plant-exchange-submission_action.png` | `ccd68c48ee915...` | Submit member form \| Use this surface to submit structured member details. \| Labeled fields \| Privacy checked \| Review handoff \| Details \| Required fields, privacy choices, and reviewer handoff are included. \| Member outcome \| The submission is routed to the reviewer with prot... | domain-native-reviewed / domain-native | Ticket must add screenshot-backed visible text and a non-reusable critique for this exact screen. | plant exchange offer form and member marketplace surface with plant details, pickup timing, owner contact, and submitted offer state |
| `b25-v4-row-006-plant-exchange-submission-2` | Garden Club | `plant-exchange-submission` | member | B13_ext_garden_club_plant-exchange-submission_complete | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B13/screenshots/B13_ext_garden_club_plant-exchange-submission_complete.png` | `9155c4d4d2beb...` | Plant exchange submission \| Member form captures labeled details, privacy choices, and reviewer handoff. \| Labeled fields \| Privacy checked \| Review handoff \| Record saved \| The community record is saved. \| Saved \| Documents and data \| Documents, exports, imports, and transfer... | domain-native-reviewed / domain-native | Ticket must add screenshot-backed visible text and a non-reusable critique for this exact screen. | plant exchange offer form and member marketplace surface with plant details, pickup timing, owner contact, and submitted offer state |
| `b25-v4-row-019-book-discussion-message-0` | Neighborhood Book Club | `book-discussion-message` | member | B14_ext_book_club_book-discussion-message_start | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_book_club_book-discussion-message_start.png` | `e459e2823b4f0...` | Discussion message \| Member communication stays scoped to the community relationship. \| Private by default \| Membership scoped \| Ready \| Post message \| Member tools \| Useful actions for this community. \| Book nomination \| Member form captures labeled details, privacy choices, ... | domain-native-reviewed / domain-native | Ticket must add screenshot-backed visible text and a non-reusable critique for this exact screen. | inbox, message thread, connection card, invite, or block-state surface |
| `b25-v4-row-020-book-discussion-message-1` | Neighborhood Book Club | `book-discussion-message` | member | B14_ext_book_club_book-discussion-message_action | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_book_club_book-discussion-message_action.png` | `5e078b9e62bee...` | Update member channel \| Use this surface to change a member communication or relationship setting. \| Private by default \| Membership scoped \| Ready \| Details \| Member channel, relationship, and preference details are included. \| Member outcome \| The communication or relationsh... | domain-native-reviewed / domain-native | Ticket must add screenshot-backed visible text and a non-reusable critique for this exact screen. | inbox, message thread, connection card, invite, or block-state surface |
| `b25-v4-row-021-book-discussion-message-2` | Neighborhood Book Club | `book-discussion-message` | member | B14_ext_book_club_book-discussion-message_complete | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_book_club_book-discussion-message_complete.png` | `2ee96485431c1...` | Discussion message \| Member communication stays scoped to the community relationship. \| Private by default \| Membership scoped \| Ready \| Setting saved \| The member setting is up to date. \| Verified \| Member tools \| Useful actions for this community. \| Book nomination \| Member ... | domain-native-reviewed / domain-native | Ticket must add screenshot-backed visible text and a non-reusable critique for this exact screen. | inbox, message thread, connection card, invite, or block-state surface |
| `b25-v4-row-022-book-selection-publish-0` | Neighborhood Book Club | `book-selection-publish` | owner | B14_ext_book_club_book-selection-publish_start | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_book_club_book-selection-publish_start.png` | `39bd49476089b...` | Selected-book publishing \| Member form captures labeled details, privacy choices, and reviewer handoff. \| Members \| Today \| Inbox + push \| Publish selection \| Search, AI answer, and digest \| Generate cited answer \| Upcoming events \| Dates, capacity, and attendance actions. \| M... | domain-native-reviewed / domain-native | Ticket must add screenshot-backed visible text and a non-reusable critique for this exact screen. | announcement feed/composer with audience, author, timestamp, body, and receiver state |
| `b25-v4-row-023-book-selection-publish-1` | Neighborhood Book Club | `book-selection-publish` | owner | B14_ext_book_club_book-selection-publish_action | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_book_club_book-selection-publish_action.png` | `a5f772a45aa20...` | Send community notice \| Use this surface to send a scoped announcement to the selected audience. \| Members \| Today \| Inbox + push \| Details \| Message, audience, preview, and delivery channel are included. \| Member outcome \| The announcement appears in the member inbox and noti... | domain-native-reviewed / domain-native | Ticket must add screenshot-backed visible text and a non-reusable critique for this exact screen. | announcement feed/composer with audience, author, timestamp, body, and receiver state |
| `b25-v4-row-024-book-selection-publish-2` | Neighborhood Book Club | `book-selection-publish` | owner | B14_ext_book_club_book-selection-publish_complete | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_book_club_book-selection-publish_complete.png` | `cac0c576c5fca...` | Selected-book publishing \| Member form captures labeled details, privacy choices, and reviewer handoff. \| Members \| Today \| Inbox + push \| Update sent \| The update is available to the selected audience. \| Sent \| Search, AI answer, and digest \| Generate cited answer \| Upcoming ... | domain-native-reviewed / domain-native | Ticket must add screenshot-backed visible text and a non-reusable critique for this exact screen. | announcement feed/composer with audience, author, timestamp, body, and receiver state |
| `b25-v4-row-037-soccer-minor-redaction-0` | Riverside Youth Soccer | `soccer-minor-redaction` | guardian | B14_ext_youth_soccer_soccer-minor-redaction_start | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_youth_soccer_soccer-minor-redaction_start.png` | `6174e481c985e...` | Protected minor-data redaction \| Data package includes scope, protected fields, and handoff status. \| Redacted copy \| Checksum ready \| Exportable \| Preview redaction \| Youth soccer export metadata \| You can review the current details without changing them. \| No ad shown \| Pref... | domain-native-reviewed / domain-native | Ticket must add screenshot-backed visible text and a non-reusable critique for this exact screen. | protected youth roster/profile surface with minor-data redaction, guardian visibility, and coach-only detail state |
| `b25-v4-row-038-soccer-minor-redaction-1` | Riverside Youth Soccer | `soccer-minor-redaction` | guardian | B14_ext_youth_soccer_soccer-minor-redaction_action | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_youth_soccer_soccer-minor-redaction_action.png` | `4f66cd7b27c38...` | Prepare export handoff \| Use this surface to package export scope, redaction, and handoff status. \| Redacted copy \| Checksum ready \| Exportable \| Details \| Scope, redaction, checksum, and handoff destination are included. \| Member outcome \| The export package can be inspected ... | domain-native-reviewed / domain-native | Ticket must add screenshot-backed visible text and a non-reusable critique for this exact screen. | protected youth roster/profile surface with minor-data redaction, guardian visibility, and coach-only detail state |
| `b25-v4-row-039-soccer-minor-redaction-2` | Riverside Youth Soccer | `soccer-minor-redaction` | guardian | B14_ext_youth_soccer_soccer-minor-redaction_complete | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_youth_soccer_soccer-minor-redaction_complete.png` | `38727c8b383cb...` | Protected minor-data redaction \| Data package includes scope, protected fields, and handoff status. \| Redacted copy \| Checksum ready \| Exportable \| Data package ready \| The data package is ready with protected fields handled. \| Ready \| Youth soccer export metadata \| You can re... | domain-native-reviewed / domain-native | Ticket must add screenshot-backed visible text and a non-reusable critique for this exact screen. | protected youth roster/profile surface with minor-data redaction, guardian visibility, and coach-only detail state |
| `b25-v4-row-046-soccer-reminder-notification-0` | Riverside Youth Soccer | `soccer-reminder-notification` | guardian | B14_ext_youth_soccer_soccer-reminder-notification_start | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_youth_soccer_soccer-reminder-notification_start.png` | `331a9c02796bf...` | Reminder notification \| Member form captures labeled details, privacy choices, and reviewer handoff. \| Members \| Today \| Inbox + push \| Send reminder \| Upcoming events \| Dates, capacity, and attendance actions. \| Practice schedule \| This week \| Community venue \| Capacity track... | domain-native-reviewed / domain-native | Ticket must add screenshot-backed visible text and a non-reusable critique for this exact screen. | notification inbox/detail surface with sender, audience, timestamp, message body, and receiver state |
| `b25-v4-row-047-soccer-reminder-notification-1` | Riverside Youth Soccer | `soccer-reminder-notification` | guardian | B14_ext_youth_soccer_soccer-reminder-notification_action | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_youth_soccer_soccer-reminder-notification_action.png` | `2a13662598256...` | Send community notice \| Use this surface to send a scoped announcement to the selected audience. \| Members \| Today \| Inbox + push \| Details \| Message, audience, preview, and delivery channel are included. \| Member outcome \| The announcement appears in the member inbox and noti... | domain-native-reviewed / domain-native | Ticket must add screenshot-backed visible text and a non-reusable critique for this exact screen. | notification inbox/detail surface with sender, audience, timestamp, message body, and receiver state |
| `b25-v4-row-048-soccer-reminder-notification-2` | Riverside Youth Soccer | `soccer-reminder-notification` | guardian | B14_ext_youth_soccer_soccer-reminder-notification_complete | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_youth_soccer_soccer-reminder-notification_complete.png` | `4bea2d955fc4d...` | Reminder notification \| Member form captures labeled details, privacy choices, and reviewer handoff. \| Members \| Today \| Inbox + push \| Update sent \| The update is available to the selected audience. \| Sent \| Upcoming events \| Dates, capacity, and attendance actions. \| Practic... | domain-native-reviewed / domain-native | Ticket must add screenshot-backed visible text and a non-reusable critique for this exact screen. | notification inbox/detail surface with sender, audience, timestamp, message body, and receiver state |
| `b25-v4-row-055-hoa-member-document-0` | Cedar Commons HOA | `hoa-member-document` | member | B14_ext_hoa_hoa-member-document_start | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_hoa_hoa-member-document_start.png` | `869e4870b741e...` | Committee decision \| Waiting for the request to be submitted first. \| Needs decision \| Private notes \| Member notified \| Waiting \| Documents and data \| Documents, exports, imports, and transfer records. \| Member-visible document \| Member form captures labeled details, privacy ... | domain-native-reviewed / domain-native | Ticket must add screenshot-backed visible text and a non-reusable critique for this exact screen. | document library/detail surface with title, audience, file metadata, and access state |
| `b25-v4-row-056-hoa-member-document-1` | Cedar Commons HOA | `hoa-member-document` | member | B14_ext_hoa_hoa-member-document_action | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_hoa_hoa-member-document_action.png` | `764adb8f3c8c1...` | Submit member form \| Use this surface to submit structured member details. \| Labeled fields \| Privacy checked \| Review handoff \| Details \| Required fields, privacy choices, and reviewer handoff are included. \| Member outcome \| The submission is routed to the reviewer with prot... | domain-native-reviewed / domain-native | Ticket must add screenshot-backed visible text and a non-reusable critique for this exact screen. | document library/detail surface with title, audience, file metadata, and access state |
| `b25-v4-row-057-hoa-member-document-2` | Cedar Commons HOA | `hoa-member-document` | member | B14_ext_hoa_hoa-member-document_complete | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_hoa_hoa-member-document_complete.png` | `2c36cfa02073e...` | Documents and data \| Documents, exports, imports, and transfer records. \| Member-visible document \| Member form captures labeled details, privacy choices, and reviewer handoff. \| Labeled fields \| Privacy checked \| Review handoff \| Record saved \| The community record is saved. ... | domain-native-reviewed / domain-native | Ticket must add screenshot-backed visible text and a non-reusable critique for this exact screen. | document library/detail surface with title, audience, file metadata, and access state |
| `b25-v4-row-061-hoa-architectural-request-0` | Cedar Commons HOA | `hoa-architectural-request` | owner | B14_ext_hoa_hoa-architectural-request_start | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_hoa_hoa-architectural-request_start.png` | `1ef0e613dda2b...` | Architectural request \| Submitted details are ready for a decision and member follow-up. \| Labeled fields \| Privacy checked \| Review handoff \| Submit request \| Committee decision \| Waiting for the request to be submitted first. \| Needs decision \| Private notes \| Member notifie... | domain-native-reviewed / domain-native | Ticket must add screenshot-backed visible text and a non-reusable critique for this exact screen. | request detail and admin review queue with submitted data, decision action, status, and notification |
| `b25-v4-row-062-hoa-architectural-request-1` | Cedar Commons HOA | `hoa-architectural-request` | owner | B14_ext_hoa_hoa-architectural-request_action | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_hoa_hoa-architectural-request_action.png` | `4312b28845953...` | Submit member form \| Use this surface to submit structured member details. \| Labeled fields \| Privacy checked \| Review handoff \| Details \| Required fields, privacy choices, and reviewer handoff are included. \| Member outcome \| The submission is routed to the reviewer with prot... | domain-native-reviewed / domain-native | Ticket must add screenshot-backed visible text and a non-reusable critique for this exact screen. | request detail and admin review queue with submitted data, decision action, status, and notification |
| `b25-v4-row-063-hoa-architectural-request-2` | Cedar Commons HOA | `hoa-architectural-request` | owner | B14_ext_hoa_hoa-architectural-request_complete | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_hoa_hoa-architectural-request_complete.png` | `abe40d9d4df67...` | Architectural request \| Submitted details are ready for a decision and member follow-up. \| Labeled fields \| Privacy checked \| Review handoff \| Record saved \| The community record is saved. \| Saved \| Committee decision \| A decision update is ready with next steps. \| Needs decis... | domain-native-reviewed / domain-native | Ticket must add screenshot-backed visible text and a non-reusable critique for this exact screen. | request detail and admin review queue with submitted data, decision action, status, and notification |
| `b25-v4-row-067-hoa-owner-notification-0` | Cedar Commons HOA | `hoa-owner-notification` | owner | B14_ext_hoa_hoa-owner-notification_start | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_hoa_hoa-owner-notification_start.png` | `f4a44ec8128eb...` | Owner notification \| Member form captures labeled details, privacy choices, and reviewer handoff. \| Members \| Today \| Inbox + push \| Send notification \| Giving \| Payments, donations, receipts, and member preferences. \| Dues payment \| A receipt or giving preference is ready to ... | domain-native-reviewed / domain-native | Ticket must add screenshot-backed visible text and a non-reusable critique for this exact screen. | notification inbox/detail surface with sender, audience, timestamp, message body, and receiver state |
| `b25-v4-row-068-hoa-owner-notification-1` | Cedar Commons HOA | `hoa-owner-notification` | owner | B14_ext_hoa_hoa-owner-notification_action | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_hoa_hoa-owner-notification_action.png` | `e42577cde046f...` | Send community notice \| Use this surface to send a scoped announcement to the selected audience. \| Members \| Today \| Inbox + push \| Details \| Message, audience, preview, and delivery channel are included. \| Member outcome \| The announcement appears in the member inbox and noti... | domain-native-reviewed / domain-native | Ticket must add screenshot-backed visible text and a non-reusable critique for this exact screen. | notification inbox/detail surface with sender, audience, timestamp, message body, and receiver state |
| `b25-v4-row-069-hoa-owner-notification-2` | Cedar Commons HOA | `hoa-owner-notification` | owner | B14_ext_hoa_hoa-owner-notification_complete | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_hoa_hoa-owner-notification_complete.png` | `077b830957cd1...` | Owner notification \| Member form captures labeled details, privacy choices, and reviewer handoff. \| Members \| Today \| Inbox + push \| Update sent \| The update is available to the selected audience. \| Sent \| Giving \| Payments, donations, receipts, and member preferences. \| Dues ... | domain-native-reviewed / domain-native | Ticket must add screenshot-backed visible text and a non-reusable critique for this exact screen. | notification inbox/detail surface with sender, audience, timestamp, message body, and receiver state |
| `b25-v4-row-073-mosque-announcement-0` | Masjid Nur | `mosque-announcement` | owner | B14_ext_mosque_mosque-announcement_start | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_mosque_mosque-announcement_start.png` | `49ade4d070ee4...` | Public announcement \| Draft message includes audience, timing, and delivery details. \| Members \| Today \| Inbox + push \| Publish announcement \| Neutral care notification \| Waiting for the announcement to be sent. \| Waiting \| Announcement search and AI citation \| Upcoming events... | domain-native-reviewed / domain-native | Ticket must add screenshot-backed visible text and a non-reusable critique for this exact screen. | announcement feed/composer with audience, author, timestamp, body, and receiver state |
| `b25-v4-row-074-mosque-announcement-1` | Masjid Nur | `mosque-announcement` | owner | B14_ext_mosque_mosque-announcement_action | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_mosque_mosque-announcement_action.png` | `839d0029c3b3c...` | Send community notice \| Use this surface to send a scoped announcement to the selected audience. \| Members \| Today \| Inbox + push \| Details \| Message, audience, preview, and delivery channel are included. \| Member outcome \| The announcement appears in the member inbox and noti... | domain-native-reviewed / domain-native | Ticket must add screenshot-backed visible text and a non-reusable critique for this exact screen. | announcement feed/composer with audience, author, timestamp, body, and receiver state |
| `b25-v4-row-075-mosque-announcement-2` | Masjid Nur | `mosque-announcement` | owner | B14_ext_mosque_mosque-announcement_complete | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_mosque_mosque-announcement_complete.png` | `abc6198effb4f...` | Public announcement \| Draft message includes audience, timing, and delivery details. \| Members \| Today \| Inbox + push \| Announcement posted \| Members can now read the announcement in their community inbox. \| Sent \| Neutral care notification \| Waiting for the announcement to be... | domain-native-reviewed / domain-native | Ticket must add screenshot-backed visible text and a non-reusable critique for this exact screen. | announcement feed/composer with audience, author, timestamp, body, and receiver state |
| `b25-v4-row-082-mosque-donor-visibility-0` | Masjid Nur | `mosque-donor-visibility` | donor | B14_ext_mosque_mosque-donor-visibility_start | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_mosque_mosque-donor-visibility_start.png` | `95a7103852c32...` | Volunteer signup \| Volunteer details include shift, availability, and protected contact. \| Open shift \| Contact protected \| Coordinator notified \| Signup saved \| The coordinator can review the signup and protected contact details. \| Saved \| Protected care request \| Care reques... | domain-native-reviewed / domain-native | Ticket must add screenshot-backed visible text and a non-reusable critique for this exact screen. | donor privacy preference surface with visibility choice, donation context, confirmation, and receipt visibility state |
| `b25-v4-row-083-mosque-donor-visibility-1` | Masjid Nur | `mosque-donor-visibility` | donor | B14_ext_mosque_mosque-donor-visibility_action | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_mosque_mosque-donor-visibility_action.png` | `f91b89ad6006f...` | Submit member form \| Use this surface to submit structured member details. \| Labeled fields \| Privacy checked \| Review handoff \| Details \| Required fields, privacy choices, and reviewer handoff are included. \| Member outcome \| The submission is routed to the reviewer with prot... | domain-native-reviewed / domain-native | Ticket must add screenshot-backed visible text and a non-reusable critique for this exact screen. | donor privacy preference surface with visibility choice, donation context, confirmation, and receipt visibility state |
| `b25-v4-row-084-mosque-donor-visibility-2` | Masjid Nur | `mosque-donor-visibility` | donor | B14_ext_mosque_mosque-donor-visibility_complete | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_mosque_mosque-donor-visibility_complete.png` | `a124717d4146f...` | Protected care request \| Care request keeps private details protected for the care team. \| Private details \| Care team \| Consent checked \| Submit request \| Member tools \| Useful actions for this community. \| Anonymous donor visibility \| Member form captures labeled details, pr... | domain-native-reviewed / domain-native | Ticket must add screenshot-backed visible text and a non-reusable critique for this exact screen. | donor privacy preference surface with visibility choice, donation context, confirmation, and receipt visibility state |
| `b25-v4-row-091-mosque-neutral-notification-0` | Masjid Nur | `mosque-neutral-notification` | member | B14_ext_mosque_mosque-neutral-notification_start | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_mosque_mosque-neutral-notification_start.png` | `c30d324ad6bbb...` | Neutral care notification \| Member form captures labeled details, privacy choices, and reviewer handoff. \| Members \| Today \| Inbox + push \| Send notification \| Announcement search and AI citation \| Generate cited answer \| Upcoming events \| Dates, capacity, and attendance actio... | domain-native-reviewed / domain-native | Ticket must add screenshot-backed visible text and a non-reusable critique for this exact screen. | notification inbox/detail surface with sender, audience, timestamp, message body, and receiver state |
| `b25-v4-row-092-mosque-neutral-notification-1` | Masjid Nur | `mosque-neutral-notification` | member | B14_ext_mosque_mosque-neutral-notification_action | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_mosque_mosque-neutral-notification_action.png` | `e42577cde046f...` | Send community notice \| Use this surface to send a scoped announcement to the selected audience. \| Members \| Today \| Inbox + push \| Details \| Message, audience, preview, and delivery channel are included. \| Member outcome \| The announcement appears in the member inbox and noti... | domain-native-reviewed / domain-native | Ticket must add screenshot-backed visible text and a non-reusable critique for this exact screen. | notification inbox/detail surface with sender, audience, timestamp, message body, and receiver state |
| `b25-v4-row-093-mosque-neutral-notification-2` | Masjid Nur | `mosque-neutral-notification` | member | B14_ext_mosque_mosque-neutral-notification_complete | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_mosque_mosque-neutral-notification_complete.png` | `e4bc0bb7a7ec6...` | Neutral care notification \| Member form captures labeled details, privacy choices, and reviewer handoff. \| Members \| Today \| Inbox + push \| Update sent \| The update is available to the selected audience. \| Sent \| Announcement search and AI citation \| Generate cited answer \| Up... | domain-native-reviewed / domain-native | Ticket must add screenshot-backed visible text and a non-reusable critique for this exact screen. | notification inbox/detail surface with sender, audience, timestamp, message body, and receiver state |
| `b25-v4-row-097-chess-local-install-open-0` | Chess Club | `chess-local-install-open` | member | B15_ext_chess_club_chess-local-install-open_start | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B15/screenshots/B15_ext_chess_club_chess-local-install-open_start.png` | `6ce055e8dc096...` | Arbitrary install and open \| Member form captures labeled details, privacy choices, and reviewer handoff. \| Labeled fields \| Privacy checked \| Review handoff \| Open community home \| Chess Club home \| Match result record \| Waiting for the member form to be submitted. \| Waiting ... | domain-native-reviewed / domain-native | Ticket must add screenshot-backed visible text and a non-reusable critique for this exact screen. | match schedule/result surface with players, round, outcome, and next action |
| `b25-v4-row-098-chess-local-install-open-1` | Chess Club | `chess-local-install-open` | member | B15_ext_chess_club_chess-local-install-open_action | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B15/screenshots/B15_ext_chess_club_chess-local-install-open_action.png` | `9f9a333c2e240...` | Submit member form \| Use this surface to submit structured member details. \| Labeled fields \| Privacy checked \| Review handoff \| Details \| Required fields, privacy choices, and reviewer handoff are included. \| Member outcome \| The submission is routed to the reviewer with prot... | domain-native-reviewed / domain-native | Ticket must add screenshot-backed visible text and a non-reusable critique for this exact screen. | match schedule/result surface with players, round, outcome, and next action |
| `b25-v4-row-099-chess-local-install-open-2` | Chess Club | `chess-local-install-open` | member | B15_ext_chess_club_chess-local-install-open_complete | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B15/screenshots/B15_ext_chess_club_chess-local-install-open_complete.png` | `a36bee30f0436...` | Arbitrary install and open \| Member form captures labeled details, privacy choices, and reviewer handoff. \| Labeled fields \| Privacy checked \| Review handoff \| Record saved \| The community record is saved. \| Saved \| Chess Club home \| Open community home \| Match result record \|... | domain-native-reviewed / domain-native | Ticket must add screenshot-backed visible text and a non-reusable critique for this exact screen. | match schedule/result surface with players, round, outcome, and next action |
| `b25-v4-row-100-chess-route-home-0` | Chess Club | `chess-route-home` | member | B15_ext_chess_club_chess-route-home_start | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B15/screenshots/B15_ext_chess_club_chess-route-home_start.png` | `823c92dd81cce...` | Arbitrary install and open \| Member form captures labeled details, privacy choices, and reviewer handoff. \| Labeled fields \| Privacy checked \| Review handoff \| Record saved \| The community record is saved. \| Saved \| Chess Club home \| Open community home \| Match result record \|... | domain-native-reviewed / domain-native | Ticket must add screenshot-backed visible text and a non-reusable critique for this exact screen. | match schedule/result surface with players, round, outcome, and next action |
| `b25-v4-row-101-chess-route-home-1` | Chess Club | `chess-route-home` | member | B15_ext_chess_club_chess-route-home_action | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B15/screenshots/B15_ext_chess_club_chess-route-home_action.png` | `0cb201660b15b...` | Submit member form \| Use this surface to submit structured member details. \| Labeled fields \| Privacy checked \| Review handoff \| Details \| Required fields, privacy choices, and reviewer handoff are included. \| Member outcome \| The submission is routed to the reviewer with prot... | domain-native-reviewed / domain-native | Ticket must add screenshot-backed visible text and a non-reusable critique for this exact screen. | match schedule/result surface with players, round, outcome, and next action |
| `b25-v4-row-102-chess-route-home-2` | Chess Club | `chess-route-home` | member | B15_ext_chess_club_chess-route-home_complete | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B15/screenshots/B15_ext_chess_club_chess-route-home_complete.png` | `1ab0333e57acc...` | Arbitrary install and open \| Member form captures labeled details, privacy choices, and reviewer handoff. \| Labeled fields \| Privacy checked \| Review handoff \| Record saved \| The community record is saved. \| Saved \| Chess Club home \| Match result record \| Waiting for the membe... | domain-native-reviewed / domain-native | Ticket must add screenshot-backed visible text and a non-reusable critique for this exact screen. | match schedule/result surface with players, round, outcome, and next action |
| `b25-v4-row-103-chess-match-result-0` | Chess Club | `chess-match-result` | member | B15_ext_chess_club_chess-match-result_start | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B15/screenshots/B15_ext_chess_club_chess-match-result_start.png` | `20c61a167b4bf...` | Arbitrary install and open \| Member form captures labeled details, privacy choices, and reviewer handoff. \| Labeled fields \| Privacy checked \| Review handoff \| Record saved \| The community record is saved. \| Saved \| Chess Club home \| Match result record \| Record match result \|... | domain-native-reviewed / domain-native | Ticket must add screenshot-backed visible text and a non-reusable critique for this exact screen. | match schedule/result surface with players, round, outcome, and next action |

### Failing Workflow/Persona Scorecards

Showing 17 of 17 failing scorecards. Full detail is in the JSON ticket.

| Scorecard | Community | Workflow | Persona | Failed questions | Target surface |
| --- | --- | --- | --- | ---: | --- |
| `b25-wp-002-plant-exchange-submission-community-garden-club-member` | Garden Club | `plant-exchange-submission` | member | 2 | plant exchange offer form and member marketplace surface with plant details, pickup timing, owner contact, and submitted offer state |
| `b25-wp-007-book-discussion-message-community-book-club-member` | Neighborhood Book Club | `book-discussion-message` | member | 2 | inbox, message thread, connection card, invite, or block-state surface |
| `b25-wp-008-book-selection-publish-community-book-club-owner` | Neighborhood Book Club | `book-selection-publish` | owner | 2 | announcement feed/composer with audience, author, timestamp, body, and receiver state |
| `b25-wp-013-soccer-minor-redaction-community-youth-soccer-guardian` | Riverside Youth Soccer | `soccer-minor-redaction` | guardian | 2 | protected youth roster/profile surface with minor-data redaction, guardian visibility, and coach-only detail state |
| `b25-wp-016-soccer-reminder-notification-community-youth-soccer-guardian` | Riverside Youth Soccer | `soccer-reminder-notification` | guardian | 2 | notification inbox/detail surface with sender, audience, timestamp, message body, and receiver state |
| `b25-wp-019-hoa-member-document-community-hoa-member` | Cedar Commons HOA | `hoa-member-document` | member | 2 | document library/detail surface with title, audience, file metadata, and access state |
| `b25-wp-021-hoa-architectural-request-community-hoa-owner` | Cedar Commons HOA | `hoa-architectural-request` | owner | 2 | request detail and admin review queue with submitted data, decision action, status, and notification |
| `b25-wp-023-hoa-owner-notification-community-hoa-owner` | Cedar Commons HOA | `hoa-owner-notification` | owner | 2 | notification inbox/detail surface with sender, audience, timestamp, message body, and receiver state |
| `b25-wp-025-mosque-announcement-community-mosque-owner` | Masjid Nur | `mosque-announcement` | owner | 2 | announcement feed/composer with audience, author, timestamp, body, and receiver state |
| `b25-wp-028-mosque-donor-visibility-community-mosque-donor` | Masjid Nur | `mosque-donor-visibility` | donor | 2 | donor privacy preference surface with visibility choice, donation context, confirmation, and receipt visibility state |
| `b25-wp-031-mosque-neutral-notification-community-mosque-member` | Masjid Nur | `mosque-neutral-notification` | member | 2 | notification inbox/detail surface with sender, audience, timestamp, message body, and receiver state |
| `b25-wp-033-chess-local-install-open-community-chess-club-member` | Chess Club | `chess-local-install-open` | member | 2 | match schedule/result surface with players, round, outcome, and next action |
| `b25-wp-034-chess-route-home-community-chess-club-member` | Chess Club | `chess-route-home` | member | 2 | match schedule/result surface with players, round, outcome, and next action |
| `b25-wp-035-chess-match-result-community-chess-club-member` | Chess Club | `chess-match-result` | member | 2 | match schedule/result surface with players, round, outcome, and next action |
| `b25-wp-037-critique-submission-community-camera-club-member` | Camera Club | `critique-submission` | member | 2 | critique submission/review surface with image/work title, comments, reviewer state, and result |
| `b25-wp-038-gear-loan-request-community-camera-club-member` | Camera Club | `gear-loan-request` | member | 2 | request detail and admin review queue with submitted data, decision action, status, and notification |
| `b25-wp-043-platform-message-stream-community-platform-social-member` | Member Social Space | `platform-message-stream` | member | 2 | inbox, message thread, connection card, invite, or block-state surface |

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
| Review run | `b25-v4-pass-9` |
| Source criterion | `b25-c09-no-layout-production-defects` |
| Source findings | B25-WORKFLOW-LIFECYCLE-INCOMPLETE |
| Title | No blocking or major layout/content defects remain |
| Direct question | Does the visible UI avoid blocking or major overlap, clipping, crowding, default-scaffold, repeated-card, checklist-modal, and thin-content defects? |
| Why it failed | holistic direct-question answers are missing, weak, partial, or blocking: b25-holistic-production-grade, b25-holistic-modern-intentional, b25-holistic-community-ia, b25-holistic-layout-defects. |
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
| Does the whole experience feel like a real production community app for the target users, not merely an implemented workflow harness? | holistic | 35 | The review cannot claim production-grade UX while workflow/persona lifecycle evidence, direct-question evidence, or screenshot visual inspection is incomplete/failing. | Complete workflow/persona coverage, lifecycle scorecards, and remediate visual/layout failures before claiming production-grade UX. |
| Is the UI modern, easy to use, easy to navigate, and visually appealing for the target persona? | holistic | 40 | 0 rows use non-screen visible text sources, 62 lifecycle scorecards fail, and 0 rows have visual/layout blockers, so the judge cannot make a reliable modern-UI claim. | Use screenshot-derived visible text, fix incomplete workflow lifecycles, and fix detected checklist, repeated-card, thin-content, or weak-identity visual blockers before rerunning the judge. |
| Is the overall information architecture organized around community content and real jobs-to-be-done instead of workflow lists or validation surfaces? | holistic | 45 | Failing workflow/persona lifecycle scorecards or visual blockers prevent a holistic community IA pass. | Replace incomplete workflow-card UX with lifecycle-complete domain-native community sections and rerun scorecards. |
| Does the visible UI avoid blocking or major overlap, clipping, crowding, default-scaffold, repeated-card, checklist-modal, and thin-content defects? | holistic | 45 | The judge cannot clear layout/content defects while row-level evidence remains incomplete, unsupported, or visually failing. | Complete screenshot-backed review rows, fix incomplete workflow lifecycles, and remediate any row-level layout/content defects. |

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
