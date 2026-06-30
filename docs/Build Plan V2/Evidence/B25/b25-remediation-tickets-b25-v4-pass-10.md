# Remediation Tickets

| Field | Value |
| --- | --- |
| Tool | `production-ux-judge` |
| Status | `fail` |
| Open tickets | 8 |

## B25-RT-001-b25-c01-no-blocker-major

| Field | Value |
| --- | --- |
| Severity | major |
| Priority | P1 |
| Status | open |
| Review run | `b25-v4-pass-10` |
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
| Material detail surface composition | Material Design 3 / design-system | https://m3.material.io/components/cards/overview | Build a domain detail page with primary content, metadata, status, and actions instead of a generic task card. |
| Inbox and message thread pattern | Material lists/text fields / pattern | https://m3.material.io/components/lists/overview<br>Also: https://m3.material.io/components/text-fields/overview | Copy an inbox/thread structure: sender, timestamp, message preview/body, reply field, invite/block state, and read/received state. |
| Feed item and composer pattern | Material cards/lists/text fields / pattern | https://m3.material.io/components/text-fields/overview<br>Also: https://m3.material.io/components/cards/overview<br>https://m3.material.io/components/lists/overview | Copy a feed/composer structure: audience, author, timestamp, body, attachments/status, publish action, and receiver read state. |
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
- open source Flutter match-result mobile UI example GitHub
- match schedule/result surface with players, round, outcome, and next action mobile UX pattern
- Material Design match schedule/result surface with players, round, outcome, and next action mobile pattern
- persona capability matrix surface with roles, allowed actions, receiver states, and denied/hidden behavior mobile UX pattern
- Material Design persona capability matrix surface with roles, allowed actions, receiver states, and denied/hidden behavior mobile pattern
- test-only persona switcher surface with active persona, role description, and return-to-workflow state mobile UX pattern
- Material Design test-only persona switcher surface with active persona, role description, and return-to-workflow state mobile pattern
- persona-aware community surface showing actor, receiver, read-only, disabled, or hidden workflow states for the active role mobile UX pattern
- Material Design persona-aware community surface showing actor, receiver, read-only, disabled, or hidden workflow states for the active role mobile pattern

### Implementation Blocked By
- Open blocker/major B25 tickets remain.
- The scorecard cannot close until those tickets rerun clean.

### Affected Screen Rows

Showing 39 of 39 affected screen rows. Full detail is in the JSON ticket.

| Screen row | Community | Workflow | Persona | State | Screenshot | Hash | Visible text | Current surface | Exact UX failure | Target surface |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `b25-v4-row-004-plant-exchange-submission-0` | Garden Club | `plant-exchange-submission` | member | B13_ext_garden_club_plant-exchange-submission_start | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B13/screenshots/B13_ext_garden_club_plant-exchange-submission_start.png` | `a44f12ab98873...` | Plant exchange submission \| Member form captures labeled details, privacy choices, and reviewer handoff. \| Labeled fields \| Privacy checked \| Review handoff \| Decide whether to claim, offer, edit, or cancel the plant exchange after checking variety, pickup, and contact details... | domain-native-reviewed / domain-native | No row-specific failure recorded. | plant exchange offer form and member marketplace surface with plant details, pickup timing, owner contact, and submitted offer state |
| `b25-v4-row-005-plant-exchange-submission-1` | Garden Club | `plant-exchange-submission` | member | B13_ext_garden_club_plant-exchange-submission_action | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B13/screenshots/B13_ext_garden_club_plant-exchange-submission_action.png` | `8dfad1cb54ff3...` | Submit member form \| Use this surface to submit structured member details. \| Labeled fields \| Privacy checked \| Review handoff \| Decision \| Decide whether to claim, offer, edit, or cancel the plant exchange after checking variety, pickup, and contact details. \| Details \| Requi... | domain-native-reviewed / domain-native | No row-specific failure recorded. | plant exchange offer form and member marketplace surface with plant details, pickup timing, owner contact, and submitted offer state |
| `b25-v4-row-006-plant-exchange-submission-2` | Garden Club | `plant-exchange-submission` | member | B13_ext_garden_club_plant-exchange-submission_complete | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B13/screenshots/B13_ext_garden_club_plant-exchange-submission_complete.png` | `b4c58b75a5beb...` | Plant exchange submission \| Member form captures labeled details, privacy choices, and reviewer handoff. \| Labeled fields \| Privacy checked \| Review handoff \| Decide whether to claim, offer, edit, or cancel the plant exchange after checking variety, pickup, and contact details... | domain-native-reviewed / domain-native | No row-specific failure recorded. | plant exchange offer form and member marketplace surface with plant details, pickup timing, owner contact, and submitted offer state |
| `b25-v4-row-019-book-discussion-message-0` | Neighborhood Book Club | `book-discussion-message` | member | B14_ext_book_club_book-discussion-message_start | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_book_club_book-discussion-message_start.png` | `f8076171741e4...` | Discussion message \| Member communication stays scoped to the community relationship. \| Private by default \| Membership scoped \| Ready \| Decide whether to reply, send, accept, decline, mute, archive, or block this member communication. \| Archive thread \| Post message \| Member ... | domain-native-reviewed / domain-native | No row-specific failure recorded. | inbox, message thread, connection card, invite, or block-state surface |
| `b25-v4-row-020-book-discussion-message-1` | Neighborhood Book Club | `book-discussion-message` | member | B14_ext_book_club_book-discussion-message_action | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_book_club_book-discussion-message_action.png` | `a2957b1721778...` | Update member channel \| Use this surface to change a member communication or relationship setting. \| Private by default \| Membership scoped \| Ready \| Decision \| Decide whether to reply, send, accept, decline, mute, archive, or block this member communication. \| Details \| Membe... | domain-native-reviewed / domain-native | No row-specific failure recorded. | inbox, message thread, connection card, invite, or block-state surface |
| `b25-v4-row-021-book-discussion-message-2` | Neighborhood Book Club | `book-discussion-message` | member | B14_ext_book_club_book-discussion-message_complete | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_book_club_book-discussion-message_complete.png` | `f3bf61dfa2fc4...` | Discussion message \| Member communication stays scoped to the community relationship. \| Private by default \| Membership scoped \| Ready \| Decide whether to reply, send, accept, decline, mute, archive, or block this member communication. \| Archive thread \| Setting saved \| The me... | domain-native-reviewed / domain-native | No row-specific failure recorded. | inbox, message thread, connection card, invite, or block-state surface |
| `b25-v4-row-022-book-selection-publish-0` | Neighborhood Book Club | `book-selection-publish` | owner | B14_ext_book_club_book-selection-publish_start | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_book_club_book-selection-publish_start.png` | `199dc193ec1c1...` | Selected-book publishing \| Member form captures labeled details, privacy choices, and reviewer handoff. \| Members \| Today \| Inbox + push \| Decide whether this message is ready for members, who receives it, and whether to preview or save a draft first. \| Save draft \| Publish se... | domain-native-reviewed / domain-native | No row-specific failure recorded. | announcement feed/composer with audience, author, timestamp, body, and receiver state |
| `b25-v4-row-023-book-selection-publish-1` | Neighborhood Book Club | `book-selection-publish` | owner | B14_ext_book_club_book-selection-publish_action | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_book_club_book-selection-publish_action.png` | `c059d086991f4...` | Send community notice \| Use this surface to send a scoped announcement to the selected audience. \| Members \| Today \| Inbox + push \| Decision \| Decide whether this message is ready for members, who receives it, and whether to preview or save a draft first. \| Details \| Message, ... | domain-native-reviewed / domain-native | No row-specific failure recorded. | announcement feed/composer with audience, author, timestamp, body, and receiver state |
| `b25-v4-row-024-book-selection-publish-2` | Neighborhood Book Club | `book-selection-publish` | owner | B14_ext_book_club_book-selection-publish_complete | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_book_club_book-selection-publish_complete.png` | `d993e32ccf226...` | Selected-book publishing \| Member form captures labeled details, privacy choices, and reviewer handoff. \| Members \| Today \| Inbox + push \| Decide whether this message is ready for members, who receives it, and whether to preview or save a draft first. \| Save draft \| Update sen... | domain-native-reviewed / domain-native | No row-specific failure recorded. | announcement feed/composer with audience, author, timestamp, body, and receiver state |
| `b25-v4-row-097-chess-local-install-open-0` | Chess Club | `chess-local-install-open` | member | B15_ext_chess_club_chess-local-install-open_start | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B15/screenshots/B15_ext_chess_club_chess-local-install-open_start.png` | `29122689a8f4d...` | Arbitrary install and open \| Member form captures labeled details, privacy choices, and reviewer handoff. \| Labeled fields \| Privacy checked \| Review handoff \| Decide whether to save, edit, correct, or dispute the match result after checking opponent, round, and score. \| Edit ... | domain-native-reviewed / domain-native | No row-specific failure recorded. | match schedule/result surface with players, round, outcome, and next action |
| `b25-v4-row-098-chess-local-install-open-1` | Chess Club | `chess-local-install-open` | member | B15_ext_chess_club_chess-local-install-open_action | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B15/screenshots/B15_ext_chess_club_chess-local-install-open_action.png` | `5868ef9bcc788...` | Submit member form \| Use this surface to submit structured member details. \| Labeled fields \| Privacy checked \| Review handoff \| Decision \| Decide whether to save, edit, correct, or dispute the match result after checking opponent, round, and score. \| Details \| Required detail... | domain-native-reviewed / domain-native | No row-specific failure recorded. | match schedule/result surface with players, round, outcome, and next action |
| `b25-v4-row-099-chess-local-install-open-2` | Chess Club | `chess-local-install-open` | member | B15_ext_chess_club_chess-local-install-open_complete | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B15/screenshots/B15_ext_chess_club_chess-local-install-open_complete.png` | `9e6d12b27709f...` | Arbitrary install and open \| Member form captures labeled details, privacy choices, and reviewer handoff. \| Labeled fields \| Privacy checked \| Review handoff \| Decide whether to save, edit, correct, or dispute the match result after checking opponent, round, and score. \| Edit ... | domain-native-reviewed / domain-native | No row-specific failure recorded. | match schedule/result surface with players, round, outcome, and next action |
| `b25-v4-row-100-chess-route-home-0` | Chess Club | `chess-route-home` | member | B15_ext_chess_club_chess-route-home_start | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B15/screenshots/B15_ext_chess_club_chess-route-home_start.png` | `73c7268dd0043...` | Chess Club home \| Member form captures labeled details, privacy choices, and reviewer handoff. \| Labeled fields \| Privacy checked \| Review handoff \| Decide whether to save, edit, correct, or dispute the match result after checking opponent, round, and score. \| Edit score \| Ope... | domain-native-reviewed / domain-native | No row-specific failure recorded. | match schedule/result surface with players, round, outcome, and next action |
| `b25-v4-row-101-chess-route-home-1` | Chess Club | `chess-route-home` | member | B15_ext_chess_club_chess-route-home_action | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B15/screenshots/B15_ext_chess_club_chess-route-home_action.png` | `0b0f3da4cfdea...` | Submit member form \| Use this surface to submit structured member details. \| Labeled fields \| Privacy checked \| Review handoff \| Decision \| Decide whether to save, edit, correct, or dispute the match result after checking opponent, round, and score. \| Details \| Required detail... | domain-native-reviewed / domain-native | No row-specific failure recorded. | match schedule/result surface with players, round, outcome, and next action |
| `b25-v4-row-102-chess-route-home-2` | Chess Club | `chess-route-home` | member | B15_ext_chess_club_chess-route-home_complete | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B15/screenshots/B15_ext_chess_club_chess-route-home_complete.png` | `c517ab02e5b25...` | Chess Club home \| Member form captures labeled details, privacy choices, and reviewer handoff. \| Labeled fields \| Privacy checked \| Review handoff \| Decide whether to save, edit, correct, or dispute the match result after checking opponent, round, and score. \| Edit score \| Rec... | domain-native-reviewed / domain-native | No row-specific failure recorded. | match schedule/result surface with players, round, outcome, and next action |
| `b25-v4-row-115-platform-messages-entry-0` | Member Social Space | `platform-messages-entry` | member | B16_ext_platform_social_platform-messages-entry_start | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B16/screenshots/B16_ext_platform_social_platform-messages-entry_start.png` | `620fd48362aa6...` | Messages \| Member communication stays scoped to the community relationship. \| Private by default \| Membership scoped \| Ready \| Decide whether to reply, send, accept, decline, mute, archive, or block this member communication. \| Archive thread \| Open Messages \| Connections \| Op... | domain-native-reviewed / domain-native | No row-specific failure recorded. | inbox, message thread, connection card, invite, or block-state surface |
| `b25-v4-row-116-platform-messages-entry-1` | Member Social Space | `platform-messages-entry` | member | B16_ext_platform_social_platform-messages-entry_action | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B16/screenshots/B16_ext_platform_social_platform-messages-entry_action.png` | `d2adbae820bd8...` | Update member channel \| Use this surface to change a member communication or relationship setting. \| Private by default \| Membership scoped \| Ready \| Decision \| Decide whether to reply, send, accept, decline, mute, archive, or block this member communication. \| Details \| Membe... | domain-native-reviewed / domain-native | No row-specific failure recorded. | inbox, message thread, connection card, invite, or block-state surface |
| `b25-v4-row-117-platform-messages-entry-2` | Member Social Space | `platform-messages-entry` | member | B16_ext_platform_social_platform-messages-entry_complete | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B16/screenshots/B16_ext_platform_social_platform-messages-entry_complete.png` | `a44790c25ed4f...` | Messages \| Member communication stays scoped to the community relationship. \| Private by default \| Membership scoped \| Ready \| Decide whether to reply, send, accept, decline, mute, archive, or block this member communication. \| Archive thread \| Setting saved \| The member setti... | domain-native-reviewed / domain-native | No row-specific failure recorded. | inbox, message thread, connection card, invite, or block-state surface |
| `b25-v4-row-118-platform-connections-entry-0` | Member Social Space | `platform-connections-entry` | member | B16_ext_platform_social_platform-connections-entry_start | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B16/screenshots/B16_ext_platform_social_platform-connections-entry_start.png` | `42d6af642292e...` | Connections \| Member communication stays scoped to the community relationship. \| Private by default \| Membership scoped \| Ready \| Decide whether to reply, send, accept, decline, mute, archive, or block this member communication. \| Archive thread \| Open Connections \| Connection... | domain-native-reviewed / domain-native | No row-specific failure recorded. | inbox, message thread, connection card, invite, or block-state surface |
| `b25-v4-row-119-platform-connections-entry-1` | Member Social Space | `platform-connections-entry` | member | B16_ext_platform_social_platform-connections-entry_action | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B16/screenshots/B16_ext_platform_social_platform-connections-entry_action.png` | `c31f5d27ec211...` | Update member channel \| Use this surface to change a member communication or relationship setting. \| Private by default \| Membership scoped \| Ready \| Decision \| Decide whether to reply, send, accept, decline, mute, archive, or block this member communication. \| Details \| Membe... | domain-native-reviewed / domain-native | No row-specific failure recorded. | inbox, message thread, connection card, invite, or block-state surface |
| `b25-v4-row-120-platform-connections-entry-2` | Member Social Space | `platform-connections-entry` | member | B16_ext_platform_social_platform-connections-entry_complete | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B16/screenshots/B16_ext_platform_social_platform-connections-entry_complete.png` | `e013aa56d2422...` | Connections \| Member communication stays scoped to the community relationship. \| Private by default \| Membership scoped \| Ready \| Decide whether to reply, send, accept, decline, mute, archive, or block this member communication. \| Archive thread \| Setting saved \| The member se... | domain-native-reviewed / domain-native | No row-specific failure recorded. | inbox, message thread, connection card, invite, or block-state surface |
| `b25-v4-row-121-platform-connection-invite-0` | Member Social Space | `platform-connection-invite` | member | B16_ext_platform_social_platform-connection-invite_start | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B16/screenshots/B16_ext_platform_social_platform-connection-invite_start.png` | `2256be2b5f0cf...` | Connection invite \| Member communication stays scoped to the community relationship. \| Private by default \| Membership scoped \| Ready \| Decide whether to reply, send, accept, decline, mute, archive, or block this member communication. \| Decline invite \| Send invite \| Message s... | domain-native-reviewed / domain-native | No row-specific failure recorded. | inbox, message thread, connection card, invite, or block-state surface |
| `b25-v4-row-122-platform-connection-invite-1` | Member Social Space | `platform-connection-invite` | member | B16_ext_platform_social_platform-connection-invite_action | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B16/screenshots/B16_ext_platform_social_platform-connection-invite_action.png` | `275f92f732d67...` | Update member channel \| Use this surface to change a member communication or relationship setting. \| Private by default \| Membership scoped \| Ready \| Decision \| Decide whether to reply, send, accept, decline, mute, archive, or block this member communication. \| Details \| Membe... | domain-native-reviewed / domain-native | No row-specific failure recorded. | inbox, message thread, connection card, invite, or block-state surface |
| `b25-v4-row-123-platform-connection-invite-2` | Member Social Space | `platform-connection-invite` | member | B16_ext_platform_social_platform-connection-invite_complete | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B16/screenshots/B16_ext_platform_social_platform-connection-invite_complete.png` | `dc1067e8124ba...` | Connection invite \| Member communication stays scoped to the community relationship. \| Private by default \| Membership scoped \| Ready \| Decide whether to reply, send, accept, decline, mute, archive, or block this member communication. \| Decline invite \| Setting saved \| The mem... | domain-native-reviewed / domain-native | No row-specific failure recorded. | inbox, message thread, connection card, invite, or block-state surface |
| `b25-v4-row-127-platform-message-stream-0` | Member Social Space | `platform-message-stream` | member | B16_ext_platform_social_platform-message-stream_start | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B16/screenshots/B16_ext_platform_social_platform-message-stream_start.png` | `b9516ddf96808...` | Message stream rendering \| Member communication stays scoped to the community relationship. \| Private by default \| Membership scoped \| Ready \| Decide whether to reply, send, accept, decline, mute, archive, or block this member communication. \| Archive thread \| Post message \| M... | domain-native-reviewed / domain-native | No row-specific failure recorded. | inbox, message thread, connection card, invite, or block-state surface |
| `b25-v4-row-128-platform-message-stream-1` | Member Social Space | `platform-message-stream` | member | B16_ext_platform_social_platform-message-stream_action | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B16/screenshots/B16_ext_platform_social_platform-message-stream_action.png` | `a2957b1721778...` | Update member channel \| Use this surface to change a member communication or relationship setting. \| Private by default \| Membership scoped \| Ready \| Decision \| Decide whether to reply, send, accept, decline, mute, archive, or block this member communication. \| Details \| Membe... | domain-native-reviewed / domain-native | No row-specific failure recorded. | inbox, message thread, connection card, invite, or block-state surface |
| `b25-v4-row-129-platform-message-stream-2` | Member Social Space | `platform-message-stream` | member | B16_ext_platform_social_platform-message-stream_complete | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B16/screenshots/B16_ext_platform_social_platform-message-stream_complete.png` | `32ab376942215...` | Message stream rendering \| Member communication stays scoped to the community relationship. \| Private by default \| Membership scoped \| Ready \| Decide whether to reply, send, accept, decline, mute, archive, or block this member communication. \| Archive thread \| Setting saved \| ... | domain-native-reviewed / domain-native | No row-specific failure recorded. | inbox, message thread, connection card, invite, or block-state surface |
| `b25-v4-row-184-wf-persona-role-inventory-capability-matrix-0` | persona-role-inventory | `wf_persona-role-inventory-capability-matrix` | admin | B17_persona_inventory_active_admin | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B17/screenshots/B17_persona_inventory_active_admin.png` | `381787dbe4795...` | No sponsored message right now. \| Masjid Nur \| Coordinate announcements, events, volunteers, giving, and care. \| Masjid Admin \| Admin - Publishes announcements and sends neutral notifications. \| 2 personas \| Announcements \| Updates, reminders, and member notices for Masjid Nur... | domain-native-reviewed / domain-native | No row-specific failure recorded. | persona capability matrix surface with roles, allowed actions, receiver states, and denied/hidden behavior |
| `b25-v4-row-185-wf-persona-role-inventory-capability-matrix-1` | persona-role-inventory | `wf_persona-role-inventory-capability-matrix` | member | B17_persona_inventory_picker | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B17/screenshots/B17_persona_inventory_picker.png` | `2af9dd71e11d0...` | No sponsored message right now. \| Masjid Nur \| Coordinate announcements, events, volunteers, giving, and care. \| Masjid Admin \| Admin - Publishes announcements and sends neutral notifications. \| 2 personas \| Announcements \| Updates, reminders, and member notices for Masjid Nur... | domain-native-reviewed / domain-native | No row-specific failure recorded. | persona capability matrix surface with roles, allowed actions, receiver states, and denied/hidden behavior |
| `b25-v4-row-186-wf-demo-app-persona-picker-0` | Masjid Nur | `wf_demo-app-persona-picker` | member | B18_persona_picker_dialog | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B18/screenshots/B18_persona_picker_dialog.png` | `2af9dd71e11d0...` | No sponsored message right now. \| Masjid Nur \| Coordinate announcements, events, volunteers, giving, and care. \| Masjid Admin \| Admin - Publishes announcements and sends neutral notifications. \| 2 personas \| Announcements \| Updates, reminders, and member notices for Masjid Nur... | domain-native-reviewed / domain-native | No row-specific failure recorded. | test-only persona switcher surface with active persona, role description, and return-to-workflow state |
| `b25-v4-row-187-wf-demo-app-persona-picker-1` | Masjid Nur | `wf_demo-app-persona-picker` | member | B18_persona_picker_member_selected | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B18/screenshots/B18_persona_picker_member_selected.png` | `c41b4bb41011c...` | Public announcement \| Waiting for the announcement to be sent. \| Members \| Today \| Inbox + push \| Decide whether this message is ready for members, who receives it, and whether to preview or save a draft first. \| Preview announcement \| Waiting \| Neutral care notification \| Dec... | domain-native-reviewed / domain-native | No row-specific failure recorded. | test-only persona switcher surface with active persona, role description, and return-to-workflow state |
| `b25-v4-row-188-wf-community-persona-aware-ux-0` | Masjid Nur | `wf_community-persona-aware-ux` | member | B19_member_care_request_actor | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B19/screenshots/B19_member_care_request_actor.png` | `17cc067a45ab9...` | Protected care request \| Care request keeps private details protected for the care team. \| Private details \| Care team \| Consent checked \| Decide whether the request should be approved, rejected, revised, or sent back for changes. \| Update privacy \| Submit request \| Member too... | domain-native-reviewed / domain-native | No row-specific failure recorded. | persona-aware community surface showing actor, receiver, read-only, disabled, or hidden workflow states for the active role |
| `b25-v4-row-189-wf-community-persona-aware-ux-1` | Masjid Nur | `wf_community-persona-aware-ux` | admin | B19_admin_announcement_actor | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B19/screenshots/B19_admin_announcement_actor.png` | `4baff4e2a7ae5...` | Public announcement \| Draft message includes audience, timing, and delivery details. \| Members \| Today \| Inbox + push \| Decide whether this message is ready for members, who receives it, and whether to preview or save a draft first. \| Preview announcement \| Publish announcemen... | domain-native-reviewed / domain-native | No row-specific failure recorded. | persona-aware community surface showing actor, receiver, read-only, disabled, or hidden workflow states for the active role |
| `b25-v4-row-190-wf-multi-persona-workflow-evidence-0` | Masjid Nur | `wf_multi-persona-workflow-evidence` | admin | B20_announcement_admin_start | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B20/screenshots/B20_announcement_admin_start.png` | `4baff4e2a7ae5...` | Public announcement \| Draft message includes audience, timing, and delivery details. \| Members \| Today \| Inbox + push \| Decide whether this message is ready for members, who receives it, and whether to preview or save a draft first. \| Preview announcement \| Publish announcemen... | domain-native-reviewed / domain-native | No row-specific failure recorded. | multi-persona handoff evidence surface with actor-created state, persona switch, receiver state, and continuation action |
| `b25-v4-row-191-wf-multi-persona-workflow-evidence-1` | Masjid Nur | `wf_multi-persona-workflow-evidence` | admin | B20_announcement_admin_action | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B20/screenshots/B20_announcement_admin_action.png` | `8e79c188137ea...` | Send community notice \| Use this surface to send a scoped announcement to the selected audience. \| Members \| Today \| Inbox + push \| Decision \| Decide whether this message is ready for members, who receives it, and whether to preview or save a draft first. \| Details \| Message, ... | domain-native-reviewed / domain-native | No row-specific failure recorded. | multi-persona handoff evidence surface with actor-created state, persona switch, receiver state, and continuation action |
| `b25-v4-row-192-wf-multi-persona-workflow-evidence-2` | Masjid Nur | `wf_multi-persona-workflow-evidence` | admin | B20_announcement_admin_complete | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B20/screenshots/B20_announcement_admin_complete.png` | `5b4b0768918c1...` | Public announcement \| Draft message includes audience, timing, and delivery details. \| Members \| Today \| Inbox + push \| Decide whether this message is ready for members, who receives it, and whether to preview or save a draft first. \| Preview announcement \| Announcement posted... | domain-native-reviewed / domain-native | No row-specific failure recorded. | multi-persona handoff evidence surface with actor-created state, persona switch, receiver state, and continuation action |
| `b25-v4-row-193-wf-multi-persona-workflow-evidence-3` | Masjid Nur | `wf_multi-persona-workflow-evidence` | member | B20_announcement_member_ready | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B20/screenshots/B20_announcement_member_ready.png` | `70ccd50d9c912...` | Public announcement \| A community update is ready in your inbox. \| Members \| Today \| Inbox + push \| Decide whether this message is ready for members, who receives it, and whether to preview or save a draft first. \| Preview announcement \| Receive announcement \| Neutral care not... | domain-native-reviewed / domain-native | No row-specific failure recorded. | multi-persona handoff evidence surface with actor-created state, persona switch, receiver state, and continuation action |
| `b25-v4-row-194-wf-multi-persona-workflow-evidence-4` | Masjid Nur | `wf_multi-persona-workflow-evidence` | member | B20_announcement_member_action | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B20/screenshots/B20_announcement_member_action.png` | `39683f8f5718f...` | Send community notice \| The member sees the message, audience, and delivery channel. \| Members \| Today \| Inbox + push \| Decision \| Decide whether this message is ready for members, who receives it, and whether to preview or save a draft first. \| Details \| Message, audience, pr... | domain-native-reviewed / domain-native | No row-specific failure recorded. | multi-persona handoff evidence surface with actor-created state, persona switch, receiver state, and continuation action |
| `b25-v4-row-195-wf-multi-persona-workflow-evidence-5` | Masjid Nur | `wf_multi-persona-workflow-evidence` | member | B20_announcement_member_received | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B20/screenshots/B20_announcement_member_received.png` | `1f94834af1a27...` | Public announcement \| A community update is ready in your inbox. \| Members \| Today \| Inbox + push \| Decide whether this message is ready for members, who receives it, and whether to preview or save a draft first. \| Preview announcement \| Update ready \| The update is now availa... | domain-native-reviewed / domain-native | No row-specific failure recorded. | multi-persona handoff evidence surface with actor-created state, persona switch, receiver state, and continuation action |

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
- Screen row `b25-v4-row-004-plant-exchange-submission-0` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-004-plant-exchange-submission-0` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-004-plant-exchange-submission-0` names visible UI elements, visible text, persona `member`, workflow `plant-exchange-submission`, and the exact product UX issue.
- Primary surface for `plant-exchange-submission` is documented as `plant exchange offer form and member marketplace surface with plant details, pickup timing, owner contact, and submitted offer state` or another explicit domain-native surface.
- After-screenshot visible text proves every required semantic surface group for `plant-exchange-submission`.
- Fresh screenshot path/hash/timestamp/app commit SHA are recorded after the fix.
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
| Review run | `b25-v4-pass-10` |
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
| Is the UI modern, easy to use, easy to navigate, and visually appealing for the target persona? | holistic | 40 | 0 rows use non-screen visible text sources, 16 lifecycle scorecards fail, and 0 rows have visual/layout blockers, so the judge cannot make a reliable modern-UI claim. | Use screenshot-derived visible text, fix incomplete workflow lifecycles, and fix detected checklist, repeated-card, thin-content, or weak-identity visual blockers before rerunning the judge. |
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

## B25-RT-003-b25-c04-modern-intentional-ui

| Field | Value |
| --- | --- |
| Severity | major |
| Priority | P1 |
| Status | open |
| Review run | `b25-v4-pass-10` |
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
| Is the UI modern, easy to use, easy to navigate, and visually appealing for the target persona? | holistic | 40 | 0 rows use non-screen visible text sources, 16 lifecycle scorecards fail, and 0 rows have visual/layout blockers, so the judge cannot make a reliable modern-UI claim. | Use screenshot-derived visible text, fix incomplete workflow lifecycles, and fix detected checklist, repeated-card, thin-content, or weak-identity visual blockers before rerunning the judge. |
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

## B25-RT-004-b25-c05-community-content-ia

| Field | Value |
| --- | --- |
| Severity | major |
| Priority | P1 |
| Status | open |
| Review run | `b25-v4-pass-10` |
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
| Is the UI modern, easy to use, easy to navigate, and visually appealing for the target persona? | holistic | 40 | 0 rows use non-screen visible text sources, 16 lifecycle scorecards fail, and 0 rows have visual/layout blockers, so the judge cannot make a reliable modern-UI claim. | Use screenshot-derived visible text, fix incomplete workflow lifecycles, and fix detected checklist, repeated-card, thin-content, or weak-identity visual blockers before rerunning the judge. |
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

## B25-RT-005-b25-c06-domain-native-primary-surfaces

| Field | Value |
| --- | --- |
| Severity | major |
| Priority | P1 |
| Status | open |
| Review run | `b25-v4-pass-10` |
| Source criterion | `b25-c06-domain-native-primary-surfaces` |
| Source findings | B25-WORKFLOW-LIFECYCLE-INCOMPLETE |
| Title | Primary workflows use domain-specific product surfaces |
| Direct question | For every workflow and persona, is the primary UI a domain-native product surface rather than a generic card, checklist modal, or metadata page? |
| Why it failed | Workflow/persona direct-question scorecards have missing or blocking answers: book-selection-publish/owner, soccer-minor-redaction/guardian, soccer-practice-schedule/guardian, soccer-reminder-notification/guardian, hoa-member-document/member, hoa-owner-notification/owner, mosque-announcement/owner, mosque-neutral-notification/member, platform-top-banner-no-fill/member, platform-sensitive-no-fill/member. |
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
| Feed item and composer pattern | Material cards/lists/text fields / pattern | https://m3.material.io/components/text-fields/overview<br>Also: https://m3.material.io/components/cards/overview<br>https://m3.material.io/components/lists/overview | Copy a feed/composer structure: audience, author, timestamp, body, attachments/status, publish action, and receiver read state. |
| Material navigation and information architecture | Material Design 3 / design-system | https://m3.material.io/components/navigation-drawer/overview<br>Also: https://m3.material.io/components/navigation-bar/overview | Organize screens by user jobs and destinations; keep primary actions visible and avoid exposing implementation taxonomy. |
| Apple HIG navigation and content organization | Apple Human Interface Guidelines / design-system | https://developer.apple.com/design/human-interface-guidelines/navigation | Make navigation predictable, content-centered, and appropriate for the user’s current task. |
| Event detail and RSVP flow | Material cards/lists/buttons / pattern | https://m3.material.io/components/cards/overview<br>Also: https://m3.material.io/components/buttons/overview<br>https://m3.material.io/components/chips/overview | Copy an event detail layout: title, date/time, location, host, capacity/status chip, attendee context, RSVP action, and confirmation state. |
| Document list/detail pattern | Material lists/cards / pattern | https://m3.material.io/components/lists/overview | Copy a document library with title, category, audience, file metadata, access state, download/view action, and empty/error states. |

### Reference Research Queries
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
- Material Design document library/detail surface with title, audience, file metadata, and access state mobile pattern
- App Shell top banner ad slot no-fill surface with preserved layout, disclosure/reserved space, and no content overlap mobile UX pattern
- Material Design App Shell top banner ad slot no-fill surface with preserved layout, disclosure/reserved space, and no content overlap mobile pattern
- sensitive-context ad suppression surface with protected content visible and ad slot safely no-filled mobile UX pattern
- Material Design sensitive-context ad suppression surface with protected content visible and ad slot safely no-filled mobile pattern

### Implementation Blocked By
- Affected rows still use generic or missing persona data.
- Visible text is not proven from screenshot OCR/manual extraction.
- Screen-specific critiques are incomplete or reusable.
- Primary surface classification is incomplete or unverified.

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

### Affected Workflow/Persona Coverage

Showing 10 of 10 affected coverage rows. Full detail is in the JSON ticket.

| Coverage row | Status | Community | Workflow | Persona | Missing evidence | Screen rows | Target surface |
| --- | --- | --- | --- | --- | --- | ---: | --- |
| `b25-wp-008-book-selection-publish-community-book-club-owner` | `pass` | Neighborhood Book Club | `book-selection-publish` | owner |  | 3 | announcement feed/composer with audience, author, timestamp, body, and receiver state |
| `b25-wp-013-soccer-minor-redaction-community-youth-soccer-guardian` | `pass` | Riverside Youth Soccer | `soccer-minor-redaction` | guardian |  | 3 | protected youth roster/profile surface with minor-data redaction, guardian visibility, and coach-only detail state |
| `b25-wp-015-soccer-practice-schedule-community-youth-soccer-guardian` | `pass` | Riverside Youth Soccer | `soccer-practice-schedule` | guardian |  | 3 | event detail with schedule, location, capacity/status, RSVP action, and result state |
| `b25-wp-016-soccer-reminder-notification-community-youth-soccer-guardian` | `pass` | Riverside Youth Soccer | `soccer-reminder-notification` | guardian |  | 3 | notification inbox/detail surface with sender, audience, timestamp, message body, and receiver state |
| `b25-wp-019-hoa-member-document-community-hoa-member` | `pass` | Cedar Commons HOA | `hoa-member-document` | member |  | 3 | document library/detail surface with title, audience, file metadata, and access state |
| `b25-wp-023-hoa-owner-notification-community-hoa-owner` | `pass` | Cedar Commons HOA | `hoa-owner-notification` | owner |  | 3 | notification inbox/detail surface with sender, audience, timestamp, message body, and receiver state |
| `b25-wp-025-mosque-announcement-community-mosque-owner` | `pass` | Masjid Nur | `mosque-announcement` | owner |  | 3 | announcement feed/composer with audience, author, timestamp, body, and receiver state |
| `b25-wp-031-mosque-neutral-notification-community-mosque-member` | `pass` | Masjid Nur | `mosque-neutral-notification` | member |  | 3 | notification inbox/detail surface with sender, audience, timestamp, message body, and receiver state |
| `b25-wp-045-platform-top-banner-no-fill-community-platform-social-member` | `pass` | Member Social Space | `platform-top-banner-no-fill` | member |  | 3 | App Shell top banner ad slot no-fill surface with preserved layout, disclosure/reserved space, and no content overlap |
| `b25-wp-046-platform-sensitive-no-fill-community-platform-social-member` | `pass` | Member Social Space | `platform-sensitive-no-fill` | member |  | 3 | sensitive-context ad suppression surface with protected content visible and ad slot safely no-filled |

### Affected Screen Rows

Showing 30 of 30 affected screen rows. Full detail is in the JSON ticket.

| Screen row | Community | Workflow | Persona | State | Screenshot | Hash | Visible text | Current surface | Exact UX failure | Target surface |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `b25-v4-row-022-book-selection-publish-0` | Neighborhood Book Club | `book-selection-publish` | owner | B14_ext_book_club_book-selection-publish_start | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_book_club_book-selection-publish_start.png` | `199dc193ec1c1...` | Selected-book publishing \| Member form captures labeled details, privacy choices, and reviewer handoff. \| Members \| Today \| Inbox + push \| Decide whether this message is ready for members, who receives it, and whether to preview or save a draft first. \| Save draft \| Publish se... | domain-native-reviewed / domain-native | Ticket must prove the primary screen is a domain-native surface, not a generic card/checklist/metadata surface. | announcement feed/composer with audience, author, timestamp, body, and receiver state |
| `b25-v4-row-023-book-selection-publish-1` | Neighborhood Book Club | `book-selection-publish` | owner | B14_ext_book_club_book-selection-publish_action | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_book_club_book-selection-publish_action.png` | `c059d086991f4...` | Send community notice \| Use this surface to send a scoped announcement to the selected audience. \| Members \| Today \| Inbox + push \| Decision \| Decide whether this message is ready for members, who receives it, and whether to preview or save a draft first. \| Details \| Message, ... | domain-native-reviewed / domain-native | Ticket must prove the primary screen is a domain-native surface, not a generic card/checklist/metadata surface. | announcement feed/composer with audience, author, timestamp, body, and receiver state |
| `b25-v4-row-024-book-selection-publish-2` | Neighborhood Book Club | `book-selection-publish` | owner | B14_ext_book_club_book-selection-publish_complete | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_book_club_book-selection-publish_complete.png` | `d993e32ccf226...` | Selected-book publishing \| Member form captures labeled details, privacy choices, and reviewer handoff. \| Members \| Today \| Inbox + push \| Decide whether this message is ready for members, who receives it, and whether to preview or save a draft first. \| Save draft \| Update sen... | domain-native-reviewed / domain-native | Ticket must prove the primary screen is a domain-native surface, not a generic card/checklist/metadata surface. | announcement feed/composer with audience, author, timestamp, body, and receiver state |
| `b25-v4-row-037-soccer-minor-redaction-0` | Riverside Youth Soccer | `soccer-minor-redaction` | guardian | B14_ext_youth_soccer_soccer-minor-redaction_start | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_youth_soccer_soccer-minor-redaction_start.png` | `5ff37fc80ea61...` | Protected minor-data redaction \| Data package includes scope, protected fields, and handoff status. \| Redacted copy \| Checksum ready \| Exportable \| Decide what to save, what to change, and what status or next step should remain visible afterward. \| Edit response \| Preview reda... | domain-native-reviewed / domain-native | Ticket must prove the primary screen is a domain-native surface, not a generic card/checklist/metadata surface. | protected youth roster/profile surface with minor-data redaction, guardian visibility, and coach-only detail state |
| `b25-v4-row-038-soccer-minor-redaction-1` | Riverside Youth Soccer | `soccer-minor-redaction` | guardian | B14_ext_youth_soccer_soccer-minor-redaction_action | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_youth_soccer_soccer-minor-redaction_action.png` | `a34740353febe...` | Prepare export handoff \| Use this surface to package export scope, redaction, and handoff status. \| Redacted copy \| Checksum ready \| Exportable \| Decision \| Decide what to save, what to change, and what status or next step should remain visible afterward. \| Details \| Data scop... | domain-native-reviewed / domain-native | Ticket must prove the primary screen is a domain-native surface, not a generic card/checklist/metadata surface. | protected youth roster/profile surface with minor-data redaction, guardian visibility, and coach-only detail state |
| `b25-v4-row-039-soccer-minor-redaction-2` | Riverside Youth Soccer | `soccer-minor-redaction` | guardian | B14_ext_youth_soccer_soccer-minor-redaction_complete | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_youth_soccer_soccer-minor-redaction_complete.png` | `58d80584c59f6...` | Protected minor-data redaction \| Data package includes scope, protected fields, and handoff status. \| Redacted copy \| Checksum ready \| Exportable \| Decide what to save, what to change, and what status or next step should remain visible afterward. \| Edit response \| Data package... | domain-native-reviewed / domain-native | Ticket must prove the primary screen is a domain-native surface, not a generic card/checklist/metadata surface. | protected youth roster/profile surface with minor-data redaction, guardian visibility, and coach-only detail state |
| `b25-v4-row-043-soccer-practice-schedule-0` | Riverside Youth Soccer | `soccer-practice-schedule` | guardian | B14_ext_youth_soccer_soccer-practice-schedule_start | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_youth_soccer_soccer-practice-schedule_start.png` | `8537ce5e05a89...` | Practice schedule \| Member form captures labeled details, privacy choices, and reviewer handoff. \| This week \| Community venue \| Capacity tracked \| Decide if you are going, maybe, or not attending after checking date, time, location, and capacity. \| Change response \| Publish s... | domain-native-reviewed / domain-native | Ticket must prove the primary screen is a domain-native surface, not a generic card/checklist/metadata surface. | event detail with schedule, location, capacity/status, RSVP action, and result state |
| `b25-v4-row-044-soccer-practice-schedule-1` | Riverside Youth Soccer | `soccer-practice-schedule` | guardian | B14_ext_youth_soccer_soccer-practice-schedule_action | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_youth_soccer_soccer-practice-schedule_action.png` | `64e955fed1c75...` | Coordinate attendance \| Use this surface to publish event details, capacity, and attendance state. \| This week \| Community venue \| Capacity tracked \| Decision \| Decide if you are going, maybe, or not attending after checking date, time, location, and capacity. \| Details \| Date... | domain-native-reviewed / domain-native | Ticket must prove the primary screen is a domain-native surface, not a generic card/checklist/metadata surface. | event detail with schedule, location, capacity/status, RSVP action, and result state |
| `b25-v4-row-045-soccer-practice-schedule-2` | Riverside Youth Soccer | `soccer-practice-schedule` | guardian | B14_ext_youth_soccer_soccer-practice-schedule_complete | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_youth_soccer_soccer-practice-schedule_complete.png` | `25188d0d93a29...` | Practice schedule \| Member form captures labeled details, privacy choices, and reviewer handoff. \| This week \| Community venue \| Capacity tracked \| Decide if you are going, maybe, or not attending after checking date, time, location, and capacity. \| Change response \| Event upd... | domain-native-reviewed / domain-native | Ticket must prove the primary screen is a domain-native surface, not a generic card/checklist/metadata surface. | event detail with schedule, location, capacity/status, RSVP action, and result state |
| `b25-v4-row-046-soccer-reminder-notification-0` | Riverside Youth Soccer | `soccer-reminder-notification` | guardian | B14_ext_youth_soccer_soccer-reminder-notification_start | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_youth_soccer_soccer-reminder-notification_start.png` | `4d6ce7fd90b81...` | Reminder notification \| Member form captures labeled details, privacy choices, and reviewer handoff. \| Members \| Today \| Inbox + push \| Decide what to save, what to change, and what status or next step should remain visible afterward. \| Edit response \| Send reminder \| Upcoming... | domain-native-reviewed / domain-native | Ticket must prove the primary screen is a domain-native surface, not a generic card/checklist/metadata surface. | notification inbox/detail surface with sender, audience, timestamp, message body, and receiver state |
| `b25-v4-row-047-soccer-reminder-notification-1` | Riverside Youth Soccer | `soccer-reminder-notification` | guardian | B14_ext_youth_soccer_soccer-reminder-notification_action | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_youth_soccer_soccer-reminder-notification_action.png` | `0a8c55d3585af...` | Send community notice \| Use this surface to send a scoped announcement to the selected audience. \| Members \| Today \| Inbox + push \| Decision \| Decide what to save, what to change, and what status or next step should remain visible afterward. \| Details \| Message, audience, prev... | domain-native-reviewed / domain-native | Ticket must prove the primary screen is a domain-native surface, not a generic card/checklist/metadata surface. | notification inbox/detail surface with sender, audience, timestamp, message body, and receiver state |
| `b25-v4-row-048-soccer-reminder-notification-2` | Riverside Youth Soccer | `soccer-reminder-notification` | guardian | B14_ext_youth_soccer_soccer-reminder-notification_complete | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_youth_soccer_soccer-reminder-notification_complete.png` | `f2315a1a94f66...` | Reminder notification \| Member form captures labeled details, privacy choices, and reviewer handoff. \| Members \| Today \| Inbox + push \| Decide what to save, what to change, and what status or next step should remain visible afterward. \| Edit response \| Update sent \| The update... | domain-native-reviewed / domain-native | Ticket must prove the primary screen is a domain-native surface, not a generic card/checklist/metadata surface. | notification inbox/detail surface with sender, audience, timestamp, message body, and receiver state |
| `b25-v4-row-055-hoa-member-document-0` | Cedar Commons HOA | `hoa-member-document` | member | B14_ext_hoa_hoa-member-document_start | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_hoa_hoa-member-document_start.png` | `0de48bcf3bfeb...` | Member-visible document \| Member form captures labeled details, privacy choices, and reviewer handoff. \| Labeled fields \| Privacy checked \| Review handoff \| Decide whether to open, download, save, share, or request access to this document. \| Save document \| Open document \| HOA... | domain-native-reviewed / domain-native | Ticket must prove the primary screen is a domain-native surface, not a generic card/checklist/metadata surface. | document library/detail surface with title, audience, file metadata, and access state |
| `b25-v4-row-056-hoa-member-document-1` | Cedar Commons HOA | `hoa-member-document` | member | B14_ext_hoa_hoa-member-document_action | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_hoa_hoa-member-document_action.png` | `fd2c4a811a821...` | Submit member form \| Use this surface to submit structured member details. \| Labeled fields \| Privacy checked \| Review handoff \| Decision \| Decide whether to open, download, save, share, or request access to this document. \| Details \| Required details are ready. Required field... | domain-native-reviewed / domain-native | Ticket must prove the primary screen is a domain-native surface, not a generic card/checklist/metadata surface. | document library/detail surface with title, audience, file metadata, and access state |
| `b25-v4-row-057-hoa-member-document-2` | Cedar Commons HOA | `hoa-member-document` | member | B14_ext_hoa_hoa-member-document_complete | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_hoa_hoa-member-document_complete.png` | `6f70fa36707ff...` | Member-visible document \| Member form captures labeled details, privacy choices, and reviewer handoff. \| Labeled fields \| Privacy checked \| Review handoff \| Decide whether to open, download, save, share, or request access to this document. \| Save document \| Record saved \| The ... | domain-native-reviewed / domain-native | Ticket must prove the primary screen is a domain-native surface, not a generic card/checklist/metadata surface. | document library/detail surface with title, audience, file metadata, and access state |
| `b25-v4-row-067-hoa-owner-notification-0` | Cedar Commons HOA | `hoa-owner-notification` | owner | B14_ext_hoa_hoa-owner-notification_start | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_hoa_hoa-owner-notification_start.png` | `9464d29a05745...` | Owner notification \| Member form captures labeled details, privacy choices, and reviewer handoff. \| Members \| Today \| Inbox + push \| Decide what to save, what to change, and what status or next step should remain visible afterward. \| Edit response \| Send notification \| Giving ... | domain-native-reviewed / domain-native | Ticket must prove the primary screen is a domain-native surface, not a generic card/checklist/metadata surface. | notification inbox/detail surface with sender, audience, timestamp, message body, and receiver state |
| `b25-v4-row-068-hoa-owner-notification-1` | Cedar Commons HOA | `hoa-owner-notification` | owner | B14_ext_hoa_hoa-owner-notification_action | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_hoa_hoa-owner-notification_action.png` | `9c8815be457ad...` | Send community notice \| Use this surface to send a scoped announcement to the selected audience. \| Members \| Today \| Inbox + push \| Decision \| Decide what to save, what to change, and what status or next step should remain visible afterward. \| Details \| Message, audience, prev... | domain-native-reviewed / domain-native | Ticket must prove the primary screen is a domain-native surface, not a generic card/checklist/metadata surface. | notification inbox/detail surface with sender, audience, timestamp, message body, and receiver state |
| `b25-v4-row-069-hoa-owner-notification-2` | Cedar Commons HOA | `hoa-owner-notification` | owner | B14_ext_hoa_hoa-owner-notification_complete | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_hoa_hoa-owner-notification_complete.png` | `ed487cfc968f5...` | Owner notification \| Member form captures labeled details, privacy choices, and reviewer handoff. \| Members \| Today \| Inbox + push \| Decide what to save, what to change, and what status or next step should remain visible afterward. \| Edit response \| Update sent \| The update is... | domain-native-reviewed / domain-native | Ticket must prove the primary screen is a domain-native surface, not a generic card/checklist/metadata surface. | notification inbox/detail surface with sender, audience, timestamp, message body, and receiver state |
| `b25-v4-row-073-mosque-announcement-0` | Masjid Nur | `mosque-announcement` | owner | B14_ext_mosque_mosque-announcement_start | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_mosque_mosque-announcement_start.png` | `4baff4e2a7ae5...` | Public announcement \| Draft message includes audience, timing, and delivery details. \| Members \| Today \| Inbox + push \| Decide whether this message is ready for members, who receives it, and whether to preview or save a draft first. \| Preview announcement \| Publish announcemen... | domain-native-reviewed / domain-native | Ticket must prove the primary screen is a domain-native surface, not a generic card/checklist/metadata surface. | announcement feed/composer with audience, author, timestamp, body, and receiver state |
| `b25-v4-row-074-mosque-announcement-1` | Masjid Nur | `mosque-announcement` | owner | B14_ext_mosque_mosque-announcement_action | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_mosque_mosque-announcement_action.png` | `8e79c188137ea...` | Send community notice \| Use this surface to send a scoped announcement to the selected audience. \| Members \| Today \| Inbox + push \| Decision \| Decide whether this message is ready for members, who receives it, and whether to preview or save a draft first. \| Details \| Message, ... | domain-native-reviewed / domain-native | Ticket must prove the primary screen is a domain-native surface, not a generic card/checklist/metadata surface. | announcement feed/composer with audience, author, timestamp, body, and receiver state |
| `b25-v4-row-075-mosque-announcement-2` | Masjid Nur | `mosque-announcement` | owner | B14_ext_mosque_mosque-announcement_complete | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_mosque_mosque-announcement_complete.png` | `5b4b0768918c1...` | Public announcement \| Draft message includes audience, timing, and delivery details. \| Members \| Today \| Inbox + push \| Decide whether this message is ready for members, who receives it, and whether to preview or save a draft first. \| Preview announcement \| Announcement posted... | domain-native-reviewed / domain-native | Ticket must prove the primary screen is a domain-native surface, not a generic card/checklist/metadata surface. | announcement feed/composer with audience, author, timestamp, body, and receiver state |
| `b25-v4-row-091-mosque-neutral-notification-0` | Masjid Nur | `mosque-neutral-notification` | member | B14_ext_mosque_mosque-neutral-notification_start | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_mosque_mosque-neutral-notification_start.png` | `0310556ae513f...` | Neutral care notification \| Member form captures labeled details, privacy choices, and reviewer handoff. \| Members \| Today \| Inbox + push \| Decide what to save, what to change, and what status or next step should remain visible afterward. \| Edit response \| Send notification \| ... | domain-native-reviewed / domain-native | Ticket must prove the primary screen is a domain-native surface, not a generic card/checklist/metadata surface. | notification inbox/detail surface with sender, audience, timestamp, message body, and receiver state |
| `b25-v4-row-092-mosque-neutral-notification-1` | Masjid Nur | `mosque-neutral-notification` | member | B14_ext_mosque_mosque-neutral-notification_action | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_mosque_mosque-neutral-notification_action.png` | `9c8815be457ad...` | Send community notice \| Use this surface to send a scoped announcement to the selected audience. \| Members \| Today \| Inbox + push \| Decision \| Decide what to save, what to change, and what status or next step should remain visible afterward. \| Details \| Message, audience, prev... | domain-native-reviewed / domain-native | Ticket must prove the primary screen is a domain-native surface, not a generic card/checklist/metadata surface. | notification inbox/detail surface with sender, audience, timestamp, message body, and receiver state |
| `b25-v4-row-093-mosque-neutral-notification-2` | Masjid Nur | `mosque-neutral-notification` | member | B14_ext_mosque_mosque-neutral-notification_complete | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_mosque_mosque-neutral-notification_complete.png` | `56ee694ccf884...` | Neutral care notification \| Member form captures labeled details, privacy choices, and reviewer handoff. \| Members \| Today \| Inbox + push \| Decide what to save, what to change, and what status or next step should remain visible afterward. \| Edit response \| Update sent \| The up... | domain-native-reviewed / domain-native | Ticket must prove the primary screen is a domain-native surface, not a generic card/checklist/metadata surface. | notification inbox/detail surface with sender, audience, timestamp, message body, and receiver state |
| `b25-v4-row-133-platform-top-banner-no-fill-0` | Member Social Space | `platform-top-banner-no-fill` | member | B16_ext_platform_social_platform-top-banner-no-fill_start | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B16/screenshots/B16_ext_platform_social_platform-top-banner-no-fill_start.png` | `5c0d10aa1672f...` | Top banner status \| Member form captures labeled details, privacy choices, and reviewer handoff. \| Private by default \| Membership scoped \| Ready \| Decide what to save, what to change, and what status or next step should remain visible afterward. \| Edit response \| Review ad st... | domain-native-reviewed / domain-native | Ticket must prove the primary screen is a domain-native surface, not a generic card/checklist/metadata surface. | App Shell top banner ad slot no-fill surface with preserved layout, disclosure/reserved space, and no content overlap |
| `b25-v4-row-134-platform-top-banner-no-fill-1` | Member Social Space | `platform-top-banner-no-fill` | member | B16_ext_platform_social_platform-top-banner-no-fill_action | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B16/screenshots/B16_ext_platform_social_platform-top-banner-no-fill_action.png` | `824b83aea5aac...` | Update member channel \| Use this surface to change a member communication or relationship setting. \| Private by default \| Membership scoped \| Ready \| Decision \| Decide what to save, what to change, and what status or next step should remain visible afterward. \| Details \| Membe... | domain-native-reviewed / domain-native | Ticket must prove the primary screen is a domain-native surface, not a generic card/checklist/metadata surface. | App Shell top banner ad slot no-fill surface with preserved layout, disclosure/reserved space, and no content overlap |
| `b25-v4-row-135-platform-top-banner-no-fill-2` | Member Social Space | `platform-top-banner-no-fill` | member | B16_ext_platform_social_platform-top-banner-no-fill_complete | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B16/screenshots/B16_ext_platform_social_platform-top-banner-no-fill_complete.png` | `2a13a3cdc4395...` | Top banner status \| Member form captures labeled details, privacy choices, and reviewer handoff. \| Private by default \| Membership scoped \| Ready \| Decide what to save, what to change, and what status or next step should remain visible afterward. \| Edit response \| Setting save... | domain-native-reviewed / domain-native | Ticket must prove the primary screen is a domain-native surface, not a generic card/checklist/metadata surface. | App Shell top banner ad slot no-fill surface with preserved layout, disclosure/reserved space, and no content overlap |
| `b25-v4-row-136-platform-sensitive-no-fill-0` | Member Social Space | `platform-sensitive-no-fill` | member | B16_ext_platform_social_platform-sensitive-no-fill_start | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B16/screenshots/B16_ext_platform_social_platform-sensitive-no-fill_start.png` | `50ced353386b3...` | Top banner status \| Member form captures labeled details, privacy choices, and reviewer handoff. \| Private by default \| Membership scoped \| Ready \| Decide what to save, what to change, and what status or next step should remain visible afterward. \| Edit response \| Setting save... | domain-native-reviewed / domain-native | Ticket must prove the primary screen is a domain-native surface, not a generic card/checklist/metadata surface. | sensitive-context ad suppression surface with protected content visible and ad slot safely no-filled |
| `b25-v4-row-137-platform-sensitive-no-fill-1` | Member Social Space | `platform-sensitive-no-fill` | member | B16_ext_platform_social_platform-sensitive-no-fill_action | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B16/screenshots/B16_ext_platform_social_platform-sensitive-no-fill_action.png` | `205507b26eb8d...` | Submit member form \| Use this surface to submit structured member details. \| Labeled fields \| Privacy checked \| Review handoff \| Decision \| Decide what to save, what to change, and what status or next step should remain visible afterward. \| Details \| Required details are ready... | domain-native-reviewed / domain-native | Ticket must prove the primary screen is a domain-native surface, not a generic card/checklist/metadata surface. | sensitive-context ad suppression surface with protected content visible and ad slot safely no-filled |
| `b25-v4-row-138-platform-sensitive-no-fill-2` | Member Social Space | `platform-sensitive-no-fill` | member | B16_ext_platform_social_platform-sensitive-no-fill_complete | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B16/screenshots/B16_ext_platform_social_platform-sensitive-no-fill_complete.png` | `2095a654eb9ce...` | Top banner status \| Member form captures labeled details, privacy choices, and reviewer handoff. \| Private by default \| Membership scoped \| Ready \| Decide what to save, what to change, and what status or next step should remain visible afterward. \| Edit response \| Setting save... | domain-native-reviewed / domain-native | Ticket must prove the primary screen is a domain-native surface, not a generic card/checklist/metadata surface. | sensitive-context ad suppression surface with protected content visible and ad slot safely no-filled |

### Failing Workflow/Persona Scorecards

Showing 10 of 10 failing scorecards. Full detail is in the JSON ticket.

| Scorecard | Community | Workflow | Persona | Failed questions | Target surface |
| --- | --- | --- | --- | ---: | --- |
| `b25-wp-008-book-selection-publish-community-book-club-owner` | Neighborhood Book Club | `book-selection-publish` | owner | 2 | announcement feed/composer with audience, author, timestamp, body, and receiver state |
| `b25-wp-013-soccer-minor-redaction-community-youth-soccer-guardian` | Riverside Youth Soccer | `soccer-minor-redaction` | guardian | 2 | protected youth roster/profile surface with minor-data redaction, guardian visibility, and coach-only detail state |
| `b25-wp-015-soccer-practice-schedule-community-youth-soccer-guardian` | Riverside Youth Soccer | `soccer-practice-schedule` | guardian | 2 | event detail with schedule, location, capacity/status, RSVP action, and result state |
| `b25-wp-016-soccer-reminder-notification-community-youth-soccer-guardian` | Riverside Youth Soccer | `soccer-reminder-notification` | guardian | 2 | notification inbox/detail surface with sender, audience, timestamp, message body, and receiver state |
| `b25-wp-019-hoa-member-document-community-hoa-member` | Cedar Commons HOA | `hoa-member-document` | member | 2 | document library/detail surface with title, audience, file metadata, and access state |
| `b25-wp-023-hoa-owner-notification-community-hoa-owner` | Cedar Commons HOA | `hoa-owner-notification` | owner | 2 | notification inbox/detail surface with sender, audience, timestamp, message body, and receiver state |
| `b25-wp-025-mosque-announcement-community-mosque-owner` | Masjid Nur | `mosque-announcement` | owner | 2 | announcement feed/composer with audience, author, timestamp, body, and receiver state |
| `b25-wp-031-mosque-neutral-notification-community-mosque-member` | Masjid Nur | `mosque-neutral-notification` | member | 2 | notification inbox/detail surface with sender, audience, timestamp, message body, and receiver state |
| `b25-wp-045-platform-top-banner-no-fill-community-platform-social-member` | Member Social Space | `platform-top-banner-no-fill` | member | 2 | App Shell top banner ad slot no-fill surface with preserved layout, disclosure/reserved space, and no content overlap |
| `b25-wp-046-platform-sensitive-no-fill-community-platform-social-member` | Member Social Space | `platform-sensitive-no-fill` | member | 2 | sensitive-context ad suppression surface with protected content visible and ad slot safely no-filled |

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
- Screen row `b25-v4-row-046-soccer-reminder-notification-0` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-046-soccer-reminder-notification-0` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-046-soccer-reminder-notification-0` names visible UI elements, visible text, persona `guardian`, workflow `soccer-reminder-notification`, and the exact product UX issue.
- Primary surface for `soccer-reminder-notification` is documented as `notification inbox/detail surface with sender, audience, timestamp, message body, and receiver state` or another explicit domain-native surface.
- After-screenshot visible text proves every required semantic surface group for `soccer-reminder-notification`.
- Screen row `b25-v4-row-047-soccer-reminder-notification-1` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-047-soccer-reminder-notification-1` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-047-soccer-reminder-notification-1` names visible UI elements, visible text, persona `guardian`, workflow `soccer-reminder-notification`, and the exact product UX issue.
- Screen row `b25-v4-row-048-soccer-reminder-notification-2` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-048-soccer-reminder-notification-2` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-048-soccer-reminder-notification-2` names visible UI elements, visible text, persona `guardian`, workflow `soccer-reminder-notification`, and the exact product UX issue.
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

## B25-RT-006-b25-c13-workflow-lifecycle-complete

| Field | Value |
| --- | --- |
| Severity | major |
| Priority | P1 |
| Status | open |
| Review run | `b25-v4-pass-10` |
| Source criterion | `b25-c13-workflow-lifecycle-complete` |
| Source findings | B25-WORKFLOW-LIFECYCLE-INCOMPLETE |
| Title | Every primary workflow has complete lifecycle UX |
| Direct question | For every workflow and persona, does the UI prove the full production interaction model: concrete object/context, decision information, semantically correct primary and alternate actions, persistent result state, and receiver/continuation state? |
| Why it failed | Workflow lifecycle scorecards are incomplete for b25-wp-002-plant-exchange-submission-community-garden-club-member-lifecycle, b25-wp-007-book-discussion-message-community-book-club-member-lifecycle, b25-wp-008-book-selection-publish-community-book-club-owner-lifecycle, b25-wp-033-chess-local-install-open-community-chess-club-member-lifecycle, b25-wp-034-chess-route-home-community-chess-club-member-lifecycle, b25-wp-039-platform-messages-entry-community-platform-social-member-lifecycle, b25-wp-040-platform-connections-entry-community-platform-social-member-lifecycle, b25-wp-041-platform-connection-invite-community-platform-social-member-lifecycle, b25-wp-043-platform-message-stream-community-platform-social-member-lifecycle, b25-wp-062-wf-persona-role-inventory-capability-matrix-persona-role-inventory-admin-lifecycle, b25-wp-063-wf-persona-role-inventory-capability-matrix-persona-role-inventory-member-lifecycle, b25-wp-064-wf-demo-app-persona-picker-community-mosque-member-lifecycle, b25-wp-065-wf-community-persona-aware-ux-community-mosque-member-lifecycle, b25-wp-066-wf-community-persona-aware-ux-community-mosque-admin-lifecycle, b25-wp-067-wf-multi-persona-workflow-evidence-community-mosque-admin-lifecycle, b25-wp-068-wf-multi-persona-workflow-evidence-community-mosque-member-lifecycle. Missing lifecycle groups: semantic interaction model, persistent result state. |
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
| Material navigation and information architecture | Material Design 3 / design-system | https://m3.material.io/components/navigation-drawer/overview<br>Also: https://m3.material.io/components/navigation-bar/overview | Organize screens by user jobs and destinations; keep primary actions visible and avoid exposing implementation taxonomy. |
| Apple HIG navigation and content organization | Apple Human Interface Guidelines / design-system | https://developer.apple.com/design/human-interface-guidelines/navigation | Make navigation predictable, content-centered, and appropriate for the user’s current task. |
| Inbox and message thread pattern | Material lists/text fields / pattern | https://m3.material.io/components/lists/overview<br>Also: https://m3.material.io/components/text-fields/overview | Copy an inbox/thread structure: sender, timestamp, message preview/body, reply field, invite/block state, and read/received state. |
| Feed item and composer pattern | Material cards/lists/text fields / pattern | https://m3.material.io/components/text-fields/overview<br>Also: https://m3.material.io/components/cards/overview<br>https://m3.material.io/components/lists/overview | Copy a feed/composer structure: audience, author, timestamp, body, attachments/status, publish action, and receiver read state. |
| Event detail and RSVP flow | Material cards/lists/buttons / pattern | https://m3.material.io/components/cards/overview<br>Also: https://m3.material.io/components/buttons/overview<br>https://m3.material.io/components/chips/overview | Copy an event detail layout: title, date/time, location, host, capacity/status chip, attendee context, RSVP action, and confirmation state. |
| Document list/detail pattern | Material lists/cards / pattern | https://m3.material.io/components/lists/overview | Copy a document library with title, category, audience, file metadata, access state, download/view action, and empty/error states. |
| Match schedule and result pattern | Material lists/cards / pattern | https://m3.material.io/components/lists/overview | Copy a match surface with players, schedule/round, result entry, result state, and next action. |

### Reference Research Queries
- mobile app workflow lifecycle UI states primary secondary actions examples
- event RSVP decline change response mobile UI pattern
- mobile form review confirmation receipt receiver state UX examples
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
- open source Flutter event-rsvp mobile UI example GitHub
- event detail with schedule, location, capacity/status, RSVP action, and result state mobile UX pattern
- Material Design event detail with schedule, location, capacity/status, RSVP action, and result state mobile pattern
- notification inbox/detail surface with sender, audience, timestamp, message body, and receiver state mobile UX pattern
- Material Design notification inbox/detail surface with sender, audience, timestamp, message body, and receiver state mobile pattern
- open source Flutter document-library mobile UI example GitHub

### Implementation Blocked By
- The judge cannot verify production-grade UX without a community-specific product experience spec.
- UI workers need the spec to know the rich product surface they are supposed to build.

### Product Spec Repair Work Items

Showing 6 of 6 work items. Full detail is in the JSON artifact.

| Work item | Stage | Community | Workflow | Persona | Screens | Coverage | Target surface | Blocked until |
| --- | --- | --- | --- | --- | ---: | ---: | --- | --- |
| `b25-wi-product-spec-interaction-model-garden-club` | `product-spec-update` | Garden Club | `plant-exchange-submission` | product-experience-steward | 3 | 1 | community product experience spec with semantic interaction models | the product doc defines expected decision, required actions, result state, and receiver/continuation state for each failing workflow |
| `b25-wi-product-spec-interaction-model-neighborhood-book-club` | `product-spec-update` | Neighborhood Book Club | `book-discussion-message, book-selection-publish` | product-experience-steward | 6 | 2 | community product experience spec with semantic interaction models | the product doc defines expected decision, required actions, result state, and receiver/continuation state for each failing workflow |
| `b25-wi-product-spec-interaction-model-chess-club` | `product-spec-update` | Chess Club | `chess-local-install-open, chess-route-home` | product-experience-steward | 6 | 2 | community product experience spec with semantic interaction models | the product doc defines expected decision, required actions, result state, and receiver/continuation state for each failing workflow |
| `b25-wi-product-spec-interaction-model-platform-social` | `product-spec-update` | Member Social Space | `platform-messages-entry, platform-connections-entry, platform-connection-invite, platform-message-stream` | product-experience-steward | 12 | 4 | community product experience spec with semantic interaction models | the product doc defines expected decision, required actions, result state, and receiver/continuation state for each failing workflow |
| `b25-wi-product-spec-interaction-model-persona-role-inventory` | `product-spec-update` | persona-role-inventory | `wf_persona-role-inventory-capability-matrix` | product-experience-steward | 2 | 2 | community product experience spec with semantic interaction models | the product doc defines expected decision, required actions, result state, and receiver/continuation state for each failing workflow |
| `b25-wi-product-spec-interaction-model-masjid-nur` | `product-spec-update` | Masjid Nur | `wf_demo-app-persona-picker, wf_community-persona-aware-ux, wf_multi-persona-workflow-evidence` | product-experience-steward | 10 | 5 | community product experience spec with semantic interaction models | the product doc defines expected decision, required actions, result state, and receiver/continuation state for each failing workflow |

### Evidence Repair Work Items

Showing 25 of 25 work items. Full detail is in the JSON artifact.

| Work item | Stage | Community | Workflow | Persona | Screens | Coverage | Target surface | Blocked until |
| --- | --- | --- | --- | --- | ---: | ---: | --- | --- |
| `b25-wi-evidence-repair-community-garden-club-plant-exchange-submission-community-garden-club-member` | `evidence-repair` | Garden Club | `plant-exchange-submission` | member | 3 | 1 | plant exchange offer form and member marketplace surface with plant details, pickup timing, owner contact, and submitted offer state |  |
| `b25-wi-evidence-repair-community-book-club-book-discussion-message-community-book-club-member` | `evidence-repair` | Neighborhood Book Club | `book-discussion-message` | member | 3 | 1 | inbox, message thread, connection card, invite, or block-state surface |  |
| `b25-wi-evidence-repair-community-book-club-book-selection-publish-community-book-club-owner` | `evidence-repair` | Neighborhood Book Club | `book-selection-publish` | owner | 3 | 1 | announcement feed/composer with audience, author, timestamp, body, and receiver state |  |
| `b25-wi-evidence-repair-community-youth-soccer-soccer-minor-redaction-community-youth-soccer-guardian` | `evidence-repair` | Riverside Youth Soccer | `soccer-minor-redaction` | guardian | 3 | 1 | protected youth roster/profile surface with minor-data redaction, guardian visibility, and coach-only detail state |  |
| `b25-wi-evidence-repair-community-youth-soccer-soccer-practice-schedule-community-youth-soccer-guardian` | `evidence-repair` | Riverside Youth Soccer | `soccer-practice-schedule` | guardian | 3 | 1 | event detail with schedule, location, capacity/status, RSVP action, and result state |  |
| `b25-wi-evidence-repair-community-youth-soccer-soccer-reminder-notification-community-youth-soccer-guardian` | `evidence-repair` | Riverside Youth Soccer | `soccer-reminder-notification` | guardian | 3 | 1 | notification inbox/detail surface with sender, audience, timestamp, message body, and receiver state |  |
| `b25-wi-evidence-repair-community-hoa-hoa-member-document-community-hoa-member` | `evidence-repair` | Cedar Commons HOA | `hoa-member-document` | member | 3 | 1 | document library/detail surface with title, audience, file metadata, and access state |  |
| `b25-wi-evidence-repair-community-hoa-hoa-owner-notification-community-hoa-owner` | `evidence-repair` | Cedar Commons HOA | `hoa-owner-notification` | owner | 3 | 1 | notification inbox/detail surface with sender, audience, timestamp, message body, and receiver state |  |
| `b25-wi-evidence-repair-community-mosque-mosque-announcement-community-mosque-owner` | `evidence-repair` | Masjid Nur | `mosque-announcement` | owner | 3 | 1 | announcement feed/composer with audience, author, timestamp, body, and receiver state |  |
| `b25-wi-evidence-repair-community-mosque-mosque-neutral-notification-community-mosque-member` | `evidence-repair` | Masjid Nur | `mosque-neutral-notification` | member | 3 | 1 | notification inbox/detail surface with sender, audience, timestamp, message body, and receiver state |  |
| `b25-wi-evidence-repair-community-chess-club-chess-local-install-open-community-chess-club-member` | `evidence-repair` | Chess Club | `chess-local-install-open` | member | 3 | 1 | match schedule/result surface with players, round, outcome, and next action |  |
| `b25-wi-evidence-repair-community-chess-club-chess-route-home-community-chess-club-member` | `evidence-repair` | Chess Club | `chess-route-home` | member | 3 | 1 | match schedule/result surface with players, round, outcome, and next action |  |
| `b25-wi-evidence-repair-community-platform-social-platform-messages-entry-community-platform-social-member` | `evidence-repair` | Member Social Space | `platform-messages-entry` | member | 3 | 1 | inbox, message thread, connection card, invite, or block-state surface |  |
| `b25-wi-evidence-repair-community-platform-social-platform-connections-entry-community-platform-social-member` | `evidence-repair` | Member Social Space | `platform-connections-entry` | member | 3 | 1 | inbox, message thread, connection card, invite, or block-state surface |  |
| `b25-wi-evidence-repair-community-platform-social-platform-connection-invite-community-platform-social-member` | `evidence-repair` | Member Social Space | `platform-connection-invite` | member | 3 | 1 | inbox, message thread, connection card, invite, or block-state surface |  |
| `b25-wi-evidence-repair-community-platform-social-platform-message-stream-community-platform-social-member` | `evidence-repair` | Member Social Space | `platform-message-stream` | member | 3 | 1 | inbox, message thread, connection card, invite, or block-state surface |  |
| `b25-wi-evidence-repair-community-platform-social-platform-top-banner-no-fill-community-platform-social-member` | `evidence-repair` | Member Social Space | `platform-top-banner-no-fill` | member | 3 | 1 | App Shell top banner ad slot no-fill surface with preserved layout, disclosure/reserved space, and no content overlap |  |
| `b25-wi-evidence-repair-community-platform-social-platform-sensitive-no-fill-community-platform-social-member` | `evidence-repair` | Member Social Space | `platform-sensitive-no-fill` | member | 3 | 1 | sensitive-context ad suppression surface with protected content visible and ad slot safely no-filled |  |
| `b25-wi-evidence-repair-persona-role-inventory-wf-persona-role-inventory-capability-matrix-persona-role-inventory-admin` | `evidence-repair` | persona-role-inventory | `wf_persona-role-inventory-capability-matrix` | admin | 1 | 1 | persona capability matrix surface with roles, allowed actions, receiver states, and denied/hidden behavior |  |
| `b25-wi-evidence-repair-persona-role-inventory-wf-persona-role-inventory-capability-matrix-persona-role-inventory-member` | `evidence-repair` | persona-role-inventory | `wf_persona-role-inventory-capability-matrix` | member | 1 | 1 | persona capability matrix surface with roles, allowed actions, receiver states, and denied/hidden behavior |  |
| `b25-wi-evidence-repair-community-mosque-wf-demo-app-persona-picker-community-mosque-member` | `evidence-repair` | Masjid Nur | `wf_demo-app-persona-picker` | member | 2 | 1 | test-only persona switcher surface with active persona, role description, and return-to-workflow state |  |
| `b25-wi-evidence-repair-community-mosque-wf-community-persona-aware-ux-community-mosque-member` | `evidence-repair` | Masjid Nur | `wf_community-persona-aware-ux` | member | 1 | 1 | persona-aware community surface showing actor, receiver, read-only, disabled, or hidden workflow states for the active role |  |
| `b25-wi-evidence-repair-community-mosque-wf-community-persona-aware-ux-community-mosque-admin` | `evidence-repair` | Masjid Nur | `wf_community-persona-aware-ux` | admin | 1 | 1 | persona-aware community surface showing actor, receiver, read-only, disabled, or hidden workflow states for the active role |  |
| `b25-wi-evidence-repair-community-mosque-wf-multi-persona-workflow-evidence-community-mosque-admin` | `evidence-repair` | Masjid Nur | `wf_multi-persona-workflow-evidence` | admin | 3 | 1 | multi-persona handoff evidence surface with actor-created state, persona switch, receiver state, and continuation action |  |
| `b25-wi-evidence-repair-community-mosque-wf-multi-persona-workflow-evidence-community-mosque-member` | `evidence-repair` | Masjid Nur | `wf_multi-persona-workflow-evidence` | member | 3 | 1 | multi-persona handoff evidence surface with actor-created state, persona switch, receiver state, and continuation action |  |

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
| Event detail and RSVP flow | Material cards/lists/buttons / pattern | https://m3.material.io/components/cards/overview<br>Also: https://m3.material.io/components/buttons/overview<br>https://m3.material.io/components/chips/overview | Copy an event detail layout: title, date/time, location, host, capacity/status chip, attendee context, RSVP action, and confirmation state. |
| Document list/detail pattern | Material lists/cards / pattern | https://m3.material.io/components/lists/overview | Copy a document library with title, category, audience, file metadata, access state, download/view action, and empty/error states. |
| Match schedule and result pattern | Material lists/cards / pattern | https://m3.material.io/components/lists/overview | Copy a match surface with players, schedule/round, result entry, result state, and next action. |

### UI Remediation Work Items

Showing 25 of 25 work items. Full detail is in the JSON artifact.

| Work item | Stage | Community | Workflow | Persona | Screens | Coverage | Target surface | Blocked until |
| --- | --- | --- | --- | --- | ---: | ---: | --- | --- |
| `b25-wi-ui-remediation-community-garden-club-plant-exchange-submission-community-garden-club-member` | `ui-remediation` | Garden Club | `plant-exchange-submission` | member | 3 | 1 | plant exchange offer form and member marketplace surface with plant details, pickup timing, owner contact, and submitted offer state | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-book-club-book-discussion-message-community-book-club-member` | `ui-remediation` | Neighborhood Book Club | `book-discussion-message` | member | 3 | 1 | inbox, message thread, connection card, invite, or block-state surface | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-book-club-book-selection-publish-community-book-club-owner` | `ui-remediation` | Neighborhood Book Club | `book-selection-publish` | owner | 3 | 1 | announcement feed/composer with audience, author, timestamp, body, and receiver state | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-youth-soccer-soccer-minor-redaction-community-youth-soccer-guardian` | `ui-remediation` | Riverside Youth Soccer | `soccer-minor-redaction` | guardian | 3 | 1 | protected youth roster/profile surface with minor-data redaction, guardian visibility, and coach-only detail state | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-youth-soccer-soccer-practice-schedule-community-youth-soccer-guardian` | `ui-remediation` | Riverside Youth Soccer | `soccer-practice-schedule` | guardian | 3 | 1 | event detail with schedule, location, capacity/status, RSVP action, and result state | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-youth-soccer-soccer-reminder-notification-community-youth-soccer-guardian` | `ui-remediation` | Riverside Youth Soccer | `soccer-reminder-notification` | guardian | 3 | 1 | notification inbox/detail surface with sender, audience, timestamp, message body, and receiver state | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-hoa-hoa-member-document-community-hoa-member` | `ui-remediation` | Cedar Commons HOA | `hoa-member-document` | member | 3 | 1 | document library/detail surface with title, audience, file metadata, and access state | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-hoa-hoa-owner-notification-community-hoa-owner` | `ui-remediation` | Cedar Commons HOA | `hoa-owner-notification` | owner | 3 | 1 | notification inbox/detail surface with sender, audience, timestamp, message body, and receiver state | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-mosque-mosque-announcement-community-mosque-owner` | `ui-remediation` | Masjid Nur | `mosque-announcement` | owner | 3 | 1 | announcement feed/composer with audience, author, timestamp, body, and receiver state | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-mosque-mosque-neutral-notification-community-mosque-member` | `ui-remediation` | Masjid Nur | `mosque-neutral-notification` | member | 3 | 1 | notification inbox/detail surface with sender, audience, timestamp, message body, and receiver state | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-chess-club-chess-local-install-open-community-chess-club-member` | `ui-remediation` | Chess Club | `chess-local-install-open` | member | 3 | 1 | match schedule/result surface with players, round, outcome, and next action | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-chess-club-chess-route-home-community-chess-club-member` | `ui-remediation` | Chess Club | `chess-route-home` | member | 3 | 1 | match schedule/result surface with players, round, outcome, and next action | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-platform-social-platform-messages-entry-community-platform-social-member` | `ui-remediation` | Member Social Space | `platform-messages-entry` | member | 3 | 1 | inbox, message thread, connection card, invite, or block-state surface | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-platform-social-platform-connections-entry-community-platform-social-member` | `ui-remediation` | Member Social Space | `platform-connections-entry` | member | 3 | 1 | inbox, message thread, connection card, invite, or block-state surface | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-platform-social-platform-connection-invite-community-platform-social-member` | `ui-remediation` | Member Social Space | `platform-connection-invite` | member | 3 | 1 | inbox, message thread, connection card, invite, or block-state surface | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-platform-social-platform-message-stream-community-platform-social-member` | `ui-remediation` | Member Social Space | `platform-message-stream` | member | 3 | 1 | inbox, message thread, connection card, invite, or block-state surface | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-platform-social-platform-top-banner-no-fill-community-platform-social-member` | `ui-remediation` | Member Social Space | `platform-top-banner-no-fill` | member | 3 | 1 | App Shell top banner ad slot no-fill surface with preserved layout, disclosure/reserved space, and no content overlap | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-platform-social-platform-sensitive-no-fill-community-platform-social-member` | `ui-remediation` | Member Social Space | `platform-sensitive-no-fill` | member | 3 | 1 | sensitive-context ad suppression surface with protected content visible and ad slot safely no-filled | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-persona-role-inventory-wf-persona-role-inventory-capability-matrix-persona-role-inventory-admin` | `ui-remediation` | persona-role-inventory | `wf_persona-role-inventory-capability-matrix` | admin | 1 | 1 | persona capability matrix surface with roles, allowed actions, receiver states, and denied/hidden behavior | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-persona-role-inventory-wf-persona-role-inventory-capability-matrix-persona-role-inventory-member` | `ui-remediation` | persona-role-inventory | `wf_persona-role-inventory-capability-matrix` | member | 1 | 1 | persona capability matrix surface with roles, allowed actions, receiver states, and denied/hidden behavior | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-mosque-wf-demo-app-persona-picker-community-mosque-member` | `ui-remediation` | Masjid Nur | `wf_demo-app-persona-picker` | member | 2 | 1 | test-only persona switcher surface with active persona, role description, and return-to-workflow state | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-mosque-wf-community-persona-aware-ux-community-mosque-member` | `ui-remediation` | Masjid Nur | `wf_community-persona-aware-ux` | member | 1 | 1 | persona-aware community surface showing actor, receiver, read-only, disabled, or hidden workflow states for the active role | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-mosque-wf-community-persona-aware-ux-community-mosque-admin` | `ui-remediation` | Masjid Nur | `wf_community-persona-aware-ux` | admin | 1 | 1 | persona-aware community surface showing actor, receiver, read-only, disabled, or hidden workflow states for the active role | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-mosque-wf-multi-persona-workflow-evidence-community-mosque-admin` | `ui-remediation` | Masjid Nur | `wf_multi-persona-workflow-evidence` | admin | 3 | 1 | multi-persona handoff evidence surface with actor-created state, persona switch, receiver state, and continuation action | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-mosque-wf-multi-persona-workflow-evidence-community-mosque-member` | `ui-remediation` | Masjid Nur | `wf_multi-persona-workflow-evidence` | member | 3 | 1 | multi-persona handoff evidence surface with actor-created state, persona switch, receiver state, and continuation action | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |

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
| Event detail and RSVP flow | Material cards/lists/buttons / pattern | https://m3.material.io/components/cards/overview<br>Also: https://m3.material.io/components/buttons/overview<br>https://m3.material.io/components/chips/overview | Copy an event detail layout: title, date/time, location, host, capacity/status chip, attendee context, RSVP action, and confirmation state. |
| Document list/detail pattern | Material lists/cards / pattern | https://m3.material.io/components/lists/overview | Copy a document library with title, category, audience, file metadata, access state, download/view action, and empty/error states. |
| Match schedule and result pattern | Material lists/cards / pattern | https://m3.material.io/components/lists/overview | Copy a match surface with players, schedule/round, result entry, result state, and next action. |

### Affected Workflow/Persona Coverage

Showing 25 of 25 affected coverage rows. Full detail is in the JSON ticket.

| Coverage row | Status | Community | Workflow | Persona | Missing evidence | Screen rows | Target surface |
| --- | --- | --- | --- | --- | --- | ---: | --- |
| `b25-wp-002-plant-exchange-submission-community-garden-club-member` | `pass` | Garden Club | `plant-exchange-submission` | member |  | 3 | plant exchange offer form and member marketplace surface with plant details, pickup timing, owner contact, and submitted offer state |
| `b25-wp-007-book-discussion-message-community-book-club-member` | `pass` | Neighborhood Book Club | `book-discussion-message` | member |  | 3 | inbox, message thread, connection card, invite, or block-state surface |
| `b25-wp-008-book-selection-publish-community-book-club-owner` | `pass` | Neighborhood Book Club | `book-selection-publish` | owner |  | 3 | announcement feed/composer with audience, author, timestamp, body, and receiver state |
| `b25-wp-013-soccer-minor-redaction-community-youth-soccer-guardian` | `pass` | Riverside Youth Soccer | `soccer-minor-redaction` | guardian |  | 3 | protected youth roster/profile surface with minor-data redaction, guardian visibility, and coach-only detail state |
| `b25-wp-015-soccer-practice-schedule-community-youth-soccer-guardian` | `pass` | Riverside Youth Soccer | `soccer-practice-schedule` | guardian |  | 3 | event detail with schedule, location, capacity/status, RSVP action, and result state |
| `b25-wp-016-soccer-reminder-notification-community-youth-soccer-guardian` | `pass` | Riverside Youth Soccer | `soccer-reminder-notification` | guardian |  | 3 | notification inbox/detail surface with sender, audience, timestamp, message body, and receiver state |
| `b25-wp-019-hoa-member-document-community-hoa-member` | `pass` | Cedar Commons HOA | `hoa-member-document` | member |  | 3 | document library/detail surface with title, audience, file metadata, and access state |
| `b25-wp-023-hoa-owner-notification-community-hoa-owner` | `pass` | Cedar Commons HOA | `hoa-owner-notification` | owner |  | 3 | notification inbox/detail surface with sender, audience, timestamp, message body, and receiver state |
| `b25-wp-025-mosque-announcement-community-mosque-owner` | `pass` | Masjid Nur | `mosque-announcement` | owner |  | 3 | announcement feed/composer with audience, author, timestamp, body, and receiver state |
| `b25-wp-031-mosque-neutral-notification-community-mosque-member` | `pass` | Masjid Nur | `mosque-neutral-notification` | member |  | 3 | notification inbox/detail surface with sender, audience, timestamp, message body, and receiver state |
| `b25-wp-033-chess-local-install-open-community-chess-club-member` | `pass` | Chess Club | `chess-local-install-open` | member |  | 3 | match schedule/result surface with players, round, outcome, and next action |
| `b25-wp-034-chess-route-home-community-chess-club-member` | `pass` | Chess Club | `chess-route-home` | member |  | 3 | match schedule/result surface with players, round, outcome, and next action |
| `b25-wp-039-platform-messages-entry-community-platform-social-member` | `pass` | Member Social Space | `platform-messages-entry` | member |  | 3 | inbox, message thread, connection card, invite, or block-state surface |
| `b25-wp-040-platform-connections-entry-community-platform-social-member` | `pass` | Member Social Space | `platform-connections-entry` | member |  | 3 | inbox, message thread, connection card, invite, or block-state surface |
| `b25-wp-041-platform-connection-invite-community-platform-social-member` | `pass` | Member Social Space | `platform-connection-invite` | member |  | 3 | inbox, message thread, connection card, invite, or block-state surface |
| `b25-wp-043-platform-message-stream-community-platform-social-member` | `pass` | Member Social Space | `platform-message-stream` | member |  | 3 | inbox, message thread, connection card, invite, or block-state surface |
| `b25-wp-045-platform-top-banner-no-fill-community-platform-social-member` | `pass` | Member Social Space | `platform-top-banner-no-fill` | member |  | 3 | App Shell top banner ad slot no-fill surface with preserved layout, disclosure/reserved space, and no content overlap |
| `b25-wp-046-platform-sensitive-no-fill-community-platform-social-member` | `pass` | Member Social Space | `platform-sensitive-no-fill` | member |  | 3 | sensitive-context ad suppression surface with protected content visible and ad slot safely no-filled |
| `b25-wp-062-wf-persona-role-inventory-capability-matrix-persona-role-inventory-admin` | `pass` | persona-role-inventory | `wf_persona-role-inventory-capability-matrix` | admin |  | 1 | persona capability matrix surface with roles, allowed actions, receiver states, and denied/hidden behavior |
| `b25-wp-063-wf-persona-role-inventory-capability-matrix-persona-role-inventory-member` | `pass` | persona-role-inventory | `wf_persona-role-inventory-capability-matrix` | member |  | 1 | persona capability matrix surface with roles, allowed actions, receiver states, and denied/hidden behavior |
| `b25-wp-064-wf-demo-app-persona-picker-community-mosque-member` | `pass` | Masjid Nur | `wf_demo-app-persona-picker` | member |  | 2 | test-only persona switcher surface with active persona, role description, and return-to-workflow state |
| `b25-wp-065-wf-community-persona-aware-ux-community-mosque-member` | `pass` | Masjid Nur | `wf_community-persona-aware-ux` | member |  | 1 | persona-aware community surface showing actor, receiver, read-only, disabled, or hidden workflow states for the active role |
| `b25-wp-066-wf-community-persona-aware-ux-community-mosque-admin` | `pass` | Masjid Nur | `wf_community-persona-aware-ux` | admin |  | 1 | persona-aware community surface showing actor, receiver, read-only, disabled, or hidden workflow states for the active role |
| `b25-wp-067-wf-multi-persona-workflow-evidence-community-mosque-admin` | `pass` | Masjid Nur | `wf_multi-persona-workflow-evidence` | admin |  | 3 | multi-persona handoff evidence surface with actor-created state, persona switch, receiver state, and continuation action |
| `b25-wp-068-wf-multi-persona-workflow-evidence-community-mosque-member` | `pass` | Masjid Nur | `wf_multi-persona-workflow-evidence` | member |  | 3 | multi-persona handoff evidence surface with actor-created state, persona switch, receiver state, and continuation action |

### Affected Screen Rows

Showing 40 of 66 affected screen rows. Full detail is in the JSON ticket.

| Screen row | Community | Workflow | Persona | State | Screenshot | Hash | Visible text | Current surface | Exact UX failure | Target surface |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `b25-v4-row-004-plant-exchange-submission-0` | Garden Club | `plant-exchange-submission` | member | B13_ext_garden_club_plant-exchange-submission_start | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B13/screenshots/B13_ext_garden_club_plant-exchange-submission_start.png` | `a44f12ab98873...` | Plant exchange submission \| Member form captures labeled details, privacy choices, and reviewer handoff. \| Labeled fields \| Privacy checked \| Review handoff \| Decide whether to claim, offer, edit, or cancel the plant exchange after checking variety, pickup, and contact details... | domain-native-reviewed / domain-native | No row-specific failure recorded. | plant exchange offer form and member marketplace surface with plant details, pickup timing, owner contact, and submitted offer state |
| `b25-v4-row-005-plant-exchange-submission-1` | Garden Club | `plant-exchange-submission` | member | B13_ext_garden_club_plant-exchange-submission_action | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B13/screenshots/B13_ext_garden_club_plant-exchange-submission_action.png` | `8dfad1cb54ff3...` | Submit member form \| Use this surface to submit structured member details. \| Labeled fields \| Privacy checked \| Review handoff \| Decision \| Decide whether to claim, offer, edit, or cancel the plant exchange after checking variety, pickup, and contact details. \| Details \| Requi... | domain-native-reviewed / domain-native | No row-specific failure recorded. | plant exchange offer form and member marketplace surface with plant details, pickup timing, owner contact, and submitted offer state |
| `b25-v4-row-006-plant-exchange-submission-2` | Garden Club | `plant-exchange-submission` | member | B13_ext_garden_club_plant-exchange-submission_complete | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B13/screenshots/B13_ext_garden_club_plant-exchange-submission_complete.png` | `b4c58b75a5beb...` | Plant exchange submission \| Member form captures labeled details, privacy choices, and reviewer handoff. \| Labeled fields \| Privacy checked \| Review handoff \| Decide whether to claim, offer, edit, or cancel the plant exchange after checking variety, pickup, and contact details... | domain-native-reviewed / domain-native | No row-specific failure recorded. | plant exchange offer form and member marketplace surface with plant details, pickup timing, owner contact, and submitted offer state |
| `b25-v4-row-019-book-discussion-message-0` | Neighborhood Book Club | `book-discussion-message` | member | B14_ext_book_club_book-discussion-message_start | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_book_club_book-discussion-message_start.png` | `f8076171741e4...` | Discussion message \| Member communication stays scoped to the community relationship. \| Private by default \| Membership scoped \| Ready \| Decide whether to reply, send, accept, decline, mute, archive, or block this member communication. \| Archive thread \| Post message \| Member ... | domain-native-reviewed / domain-native | No row-specific failure recorded. | inbox, message thread, connection card, invite, or block-state surface |
| `b25-v4-row-020-book-discussion-message-1` | Neighborhood Book Club | `book-discussion-message` | member | B14_ext_book_club_book-discussion-message_action | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_book_club_book-discussion-message_action.png` | `a2957b1721778...` | Update member channel \| Use this surface to change a member communication or relationship setting. \| Private by default \| Membership scoped \| Ready \| Decision \| Decide whether to reply, send, accept, decline, mute, archive, or block this member communication. \| Details \| Membe... | domain-native-reviewed / domain-native | No row-specific failure recorded. | inbox, message thread, connection card, invite, or block-state surface |
| `b25-v4-row-021-book-discussion-message-2` | Neighborhood Book Club | `book-discussion-message` | member | B14_ext_book_club_book-discussion-message_complete | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_book_club_book-discussion-message_complete.png` | `f3bf61dfa2fc4...` | Discussion message \| Member communication stays scoped to the community relationship. \| Private by default \| Membership scoped \| Ready \| Decide whether to reply, send, accept, decline, mute, archive, or block this member communication. \| Archive thread \| Setting saved \| The me... | domain-native-reviewed / domain-native | No row-specific failure recorded. | inbox, message thread, connection card, invite, or block-state surface |
| `b25-v4-row-022-book-selection-publish-0` | Neighborhood Book Club | `book-selection-publish` | owner | B14_ext_book_club_book-selection-publish_start | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_book_club_book-selection-publish_start.png` | `199dc193ec1c1...` | Selected-book publishing \| Member form captures labeled details, privacy choices, and reviewer handoff. \| Members \| Today \| Inbox + push \| Decide whether this message is ready for members, who receives it, and whether to preview or save a draft first. \| Save draft \| Publish se... | domain-native-reviewed / domain-native | No row-specific failure recorded. | announcement feed/composer with audience, author, timestamp, body, and receiver state |
| `b25-v4-row-023-book-selection-publish-1` | Neighborhood Book Club | `book-selection-publish` | owner | B14_ext_book_club_book-selection-publish_action | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_book_club_book-selection-publish_action.png` | `c059d086991f4...` | Send community notice \| Use this surface to send a scoped announcement to the selected audience. \| Members \| Today \| Inbox + push \| Decision \| Decide whether this message is ready for members, who receives it, and whether to preview or save a draft first. \| Details \| Message, ... | domain-native-reviewed / domain-native | No row-specific failure recorded. | announcement feed/composer with audience, author, timestamp, body, and receiver state |
| `b25-v4-row-024-book-selection-publish-2` | Neighborhood Book Club | `book-selection-publish` | owner | B14_ext_book_club_book-selection-publish_complete | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_book_club_book-selection-publish_complete.png` | `d993e32ccf226...` | Selected-book publishing \| Member form captures labeled details, privacy choices, and reviewer handoff. \| Members \| Today \| Inbox + push \| Decide whether this message is ready for members, who receives it, and whether to preview or save a draft first. \| Save draft \| Update sen... | domain-native-reviewed / domain-native | No row-specific failure recorded. | announcement feed/composer with audience, author, timestamp, body, and receiver state |
| `b25-v4-row-037-soccer-minor-redaction-0` | Riverside Youth Soccer | `soccer-minor-redaction` | guardian | B14_ext_youth_soccer_soccer-minor-redaction_start | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_youth_soccer_soccer-minor-redaction_start.png` | `5ff37fc80ea61...` | Protected minor-data redaction \| Data package includes scope, protected fields, and handoff status. \| Redacted copy \| Checksum ready \| Exportable \| Decide what to save, what to change, and what status or next step should remain visible afterward. \| Edit response \| Preview reda... | domain-native-reviewed / domain-native | No row-specific failure recorded. | protected youth roster/profile surface with minor-data redaction, guardian visibility, and coach-only detail state |
| `b25-v4-row-038-soccer-minor-redaction-1` | Riverside Youth Soccer | `soccer-minor-redaction` | guardian | B14_ext_youth_soccer_soccer-minor-redaction_action | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_youth_soccer_soccer-minor-redaction_action.png` | `a34740353febe...` | Prepare export handoff \| Use this surface to package export scope, redaction, and handoff status. \| Redacted copy \| Checksum ready \| Exportable \| Decision \| Decide what to save, what to change, and what status or next step should remain visible afterward. \| Details \| Data scop... | domain-native-reviewed / domain-native | No row-specific failure recorded. | protected youth roster/profile surface with minor-data redaction, guardian visibility, and coach-only detail state |
| `b25-v4-row-039-soccer-minor-redaction-2` | Riverside Youth Soccer | `soccer-minor-redaction` | guardian | B14_ext_youth_soccer_soccer-minor-redaction_complete | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_youth_soccer_soccer-minor-redaction_complete.png` | `58d80584c59f6...` | Protected minor-data redaction \| Data package includes scope, protected fields, and handoff status. \| Redacted copy \| Checksum ready \| Exportable \| Decide what to save, what to change, and what status or next step should remain visible afterward. \| Edit response \| Data package... | domain-native-reviewed / domain-native | No row-specific failure recorded. | protected youth roster/profile surface with minor-data redaction, guardian visibility, and coach-only detail state |
| `b25-v4-row-043-soccer-practice-schedule-0` | Riverside Youth Soccer | `soccer-practice-schedule` | guardian | B14_ext_youth_soccer_soccer-practice-schedule_start | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_youth_soccer_soccer-practice-schedule_start.png` | `8537ce5e05a89...` | Practice schedule \| Member form captures labeled details, privacy choices, and reviewer handoff. \| This week \| Community venue \| Capacity tracked \| Decide if you are going, maybe, or not attending after checking date, time, location, and capacity. \| Change response \| Publish s... | domain-native-reviewed / domain-native | No row-specific failure recorded. | event detail with schedule, location, capacity/status, RSVP action, and result state |
| `b25-v4-row-044-soccer-practice-schedule-1` | Riverside Youth Soccer | `soccer-practice-schedule` | guardian | B14_ext_youth_soccer_soccer-practice-schedule_action | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_youth_soccer_soccer-practice-schedule_action.png` | `64e955fed1c75...` | Coordinate attendance \| Use this surface to publish event details, capacity, and attendance state. \| This week \| Community venue \| Capacity tracked \| Decision \| Decide if you are going, maybe, or not attending after checking date, time, location, and capacity. \| Details \| Date... | domain-native-reviewed / domain-native | No row-specific failure recorded. | event detail with schedule, location, capacity/status, RSVP action, and result state |
| `b25-v4-row-045-soccer-practice-schedule-2` | Riverside Youth Soccer | `soccer-practice-schedule` | guardian | B14_ext_youth_soccer_soccer-practice-schedule_complete | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_youth_soccer_soccer-practice-schedule_complete.png` | `25188d0d93a29...` | Practice schedule \| Member form captures labeled details, privacy choices, and reviewer handoff. \| This week \| Community venue \| Capacity tracked \| Decide if you are going, maybe, or not attending after checking date, time, location, and capacity. \| Change response \| Event upd... | domain-native-reviewed / domain-native | No row-specific failure recorded. | event detail with schedule, location, capacity/status, RSVP action, and result state |
| `b25-v4-row-046-soccer-reminder-notification-0` | Riverside Youth Soccer | `soccer-reminder-notification` | guardian | B14_ext_youth_soccer_soccer-reminder-notification_start | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_youth_soccer_soccer-reminder-notification_start.png` | `4d6ce7fd90b81...` | Reminder notification \| Member form captures labeled details, privacy choices, and reviewer handoff. \| Members \| Today \| Inbox + push \| Decide what to save, what to change, and what status or next step should remain visible afterward. \| Edit response \| Send reminder \| Upcoming... | domain-native-reviewed / domain-native | No row-specific failure recorded. | notification inbox/detail surface with sender, audience, timestamp, message body, and receiver state |
| `b25-v4-row-047-soccer-reminder-notification-1` | Riverside Youth Soccer | `soccer-reminder-notification` | guardian | B14_ext_youth_soccer_soccer-reminder-notification_action | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_youth_soccer_soccer-reminder-notification_action.png` | `0a8c55d3585af...` | Send community notice \| Use this surface to send a scoped announcement to the selected audience. \| Members \| Today \| Inbox + push \| Decision \| Decide what to save, what to change, and what status or next step should remain visible afterward. \| Details \| Message, audience, prev... | domain-native-reviewed / domain-native | No row-specific failure recorded. | notification inbox/detail surface with sender, audience, timestamp, message body, and receiver state |
| `b25-v4-row-048-soccer-reminder-notification-2` | Riverside Youth Soccer | `soccer-reminder-notification` | guardian | B14_ext_youth_soccer_soccer-reminder-notification_complete | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_youth_soccer_soccer-reminder-notification_complete.png` | `f2315a1a94f66...` | Reminder notification \| Member form captures labeled details, privacy choices, and reviewer handoff. \| Members \| Today \| Inbox + push \| Decide what to save, what to change, and what status or next step should remain visible afterward. \| Edit response \| Update sent \| The update... | domain-native-reviewed / domain-native | No row-specific failure recorded. | notification inbox/detail surface with sender, audience, timestamp, message body, and receiver state |
| `b25-v4-row-055-hoa-member-document-0` | Cedar Commons HOA | `hoa-member-document` | member | B14_ext_hoa_hoa-member-document_start | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_hoa_hoa-member-document_start.png` | `0de48bcf3bfeb...` | Member-visible document \| Member form captures labeled details, privacy choices, and reviewer handoff. \| Labeled fields \| Privacy checked \| Review handoff \| Decide whether to open, download, save, share, or request access to this document. \| Save document \| Open document \| HOA... | domain-native-reviewed / domain-native | No row-specific failure recorded. | document library/detail surface with title, audience, file metadata, and access state |
| `b25-v4-row-056-hoa-member-document-1` | Cedar Commons HOA | `hoa-member-document` | member | B14_ext_hoa_hoa-member-document_action | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_hoa_hoa-member-document_action.png` | `fd2c4a811a821...` | Submit member form \| Use this surface to submit structured member details. \| Labeled fields \| Privacy checked \| Review handoff \| Decision \| Decide whether to open, download, save, share, or request access to this document. \| Details \| Required details are ready. Required field... | domain-native-reviewed / domain-native | No row-specific failure recorded. | document library/detail surface with title, audience, file metadata, and access state |
| `b25-v4-row-057-hoa-member-document-2` | Cedar Commons HOA | `hoa-member-document` | member | B14_ext_hoa_hoa-member-document_complete | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_hoa_hoa-member-document_complete.png` | `6f70fa36707ff...` | Member-visible document \| Member form captures labeled details, privacy choices, and reviewer handoff. \| Labeled fields \| Privacy checked \| Review handoff \| Decide whether to open, download, save, share, or request access to this document. \| Save document \| Record saved \| The ... | domain-native-reviewed / domain-native | No row-specific failure recorded. | document library/detail surface with title, audience, file metadata, and access state |
| `b25-v4-row-067-hoa-owner-notification-0` | Cedar Commons HOA | `hoa-owner-notification` | owner | B14_ext_hoa_hoa-owner-notification_start | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_hoa_hoa-owner-notification_start.png` | `9464d29a05745...` | Owner notification \| Member form captures labeled details, privacy choices, and reviewer handoff. \| Members \| Today \| Inbox + push \| Decide what to save, what to change, and what status or next step should remain visible afterward. \| Edit response \| Send notification \| Giving ... | domain-native-reviewed / domain-native | No row-specific failure recorded. | notification inbox/detail surface with sender, audience, timestamp, message body, and receiver state |
| `b25-v4-row-068-hoa-owner-notification-1` | Cedar Commons HOA | `hoa-owner-notification` | owner | B14_ext_hoa_hoa-owner-notification_action | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_hoa_hoa-owner-notification_action.png` | `9c8815be457ad...` | Send community notice \| Use this surface to send a scoped announcement to the selected audience. \| Members \| Today \| Inbox + push \| Decision \| Decide what to save, what to change, and what status or next step should remain visible afterward. \| Details \| Message, audience, prev... | domain-native-reviewed / domain-native | No row-specific failure recorded. | notification inbox/detail surface with sender, audience, timestamp, message body, and receiver state |
| `b25-v4-row-069-hoa-owner-notification-2` | Cedar Commons HOA | `hoa-owner-notification` | owner | B14_ext_hoa_hoa-owner-notification_complete | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_hoa_hoa-owner-notification_complete.png` | `ed487cfc968f5...` | Owner notification \| Member form captures labeled details, privacy choices, and reviewer handoff. \| Members \| Today \| Inbox + push \| Decide what to save, what to change, and what status or next step should remain visible afterward. \| Edit response \| Update sent \| The update is... | domain-native-reviewed / domain-native | No row-specific failure recorded. | notification inbox/detail surface with sender, audience, timestamp, message body, and receiver state |
| `b25-v4-row-073-mosque-announcement-0` | Masjid Nur | `mosque-announcement` | owner | B14_ext_mosque_mosque-announcement_start | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_mosque_mosque-announcement_start.png` | `4baff4e2a7ae5...` | Public announcement \| Draft message includes audience, timing, and delivery details. \| Members \| Today \| Inbox + push \| Decide whether this message is ready for members, who receives it, and whether to preview or save a draft first. \| Preview announcement \| Publish announcemen... | domain-native-reviewed / domain-native | No row-specific failure recorded. | announcement feed/composer with audience, author, timestamp, body, and receiver state |
| `b25-v4-row-074-mosque-announcement-1` | Masjid Nur | `mosque-announcement` | owner | B14_ext_mosque_mosque-announcement_action | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_mosque_mosque-announcement_action.png` | `8e79c188137ea...` | Send community notice \| Use this surface to send a scoped announcement to the selected audience. \| Members \| Today \| Inbox + push \| Decision \| Decide whether this message is ready for members, who receives it, and whether to preview or save a draft first. \| Details \| Message, ... | domain-native-reviewed / domain-native | No row-specific failure recorded. | announcement feed/composer with audience, author, timestamp, body, and receiver state |
| `b25-v4-row-075-mosque-announcement-2` | Masjid Nur | `mosque-announcement` | owner | B14_ext_mosque_mosque-announcement_complete | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_mosque_mosque-announcement_complete.png` | `5b4b0768918c1...` | Public announcement \| Draft message includes audience, timing, and delivery details. \| Members \| Today \| Inbox + push \| Decide whether this message is ready for members, who receives it, and whether to preview or save a draft first. \| Preview announcement \| Announcement posted... | domain-native-reviewed / domain-native | No row-specific failure recorded. | announcement feed/composer with audience, author, timestamp, body, and receiver state |
| `b25-v4-row-091-mosque-neutral-notification-0` | Masjid Nur | `mosque-neutral-notification` | member | B14_ext_mosque_mosque-neutral-notification_start | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_mosque_mosque-neutral-notification_start.png` | `0310556ae513f...` | Neutral care notification \| Member form captures labeled details, privacy choices, and reviewer handoff. \| Members \| Today \| Inbox + push \| Decide what to save, what to change, and what status or next step should remain visible afterward. \| Edit response \| Send notification \| ... | domain-native-reviewed / domain-native | No row-specific failure recorded. | notification inbox/detail surface with sender, audience, timestamp, message body, and receiver state |
| `b25-v4-row-092-mosque-neutral-notification-1` | Masjid Nur | `mosque-neutral-notification` | member | B14_ext_mosque_mosque-neutral-notification_action | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_mosque_mosque-neutral-notification_action.png` | `9c8815be457ad...` | Send community notice \| Use this surface to send a scoped announcement to the selected audience. \| Members \| Today \| Inbox + push \| Decision \| Decide what to save, what to change, and what status or next step should remain visible afterward. \| Details \| Message, audience, prev... | domain-native-reviewed / domain-native | No row-specific failure recorded. | notification inbox/detail surface with sender, audience, timestamp, message body, and receiver state |
| `b25-v4-row-093-mosque-neutral-notification-2` | Masjid Nur | `mosque-neutral-notification` | member | B14_ext_mosque_mosque-neutral-notification_complete | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_mosque_mosque-neutral-notification_complete.png` | `56ee694ccf884...` | Neutral care notification \| Member form captures labeled details, privacy choices, and reviewer handoff. \| Members \| Today \| Inbox + push \| Decide what to save, what to change, and what status or next step should remain visible afterward. \| Edit response \| Update sent \| The up... | domain-native-reviewed / domain-native | No row-specific failure recorded. | notification inbox/detail surface with sender, audience, timestamp, message body, and receiver state |
| `b25-v4-row-097-chess-local-install-open-0` | Chess Club | `chess-local-install-open` | member | B15_ext_chess_club_chess-local-install-open_start | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B15/screenshots/B15_ext_chess_club_chess-local-install-open_start.png` | `29122689a8f4d...` | Arbitrary install and open \| Member form captures labeled details, privacy choices, and reviewer handoff. \| Labeled fields \| Privacy checked \| Review handoff \| Decide whether to save, edit, correct, or dispute the match result after checking opponent, round, and score. \| Edit ... | domain-native-reviewed / domain-native | No row-specific failure recorded. | match schedule/result surface with players, round, outcome, and next action |
| `b25-v4-row-098-chess-local-install-open-1` | Chess Club | `chess-local-install-open` | member | B15_ext_chess_club_chess-local-install-open_action | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B15/screenshots/B15_ext_chess_club_chess-local-install-open_action.png` | `5868ef9bcc788...` | Submit member form \| Use this surface to submit structured member details. \| Labeled fields \| Privacy checked \| Review handoff \| Decision \| Decide whether to save, edit, correct, or dispute the match result after checking opponent, round, and score. \| Details \| Required detail... | domain-native-reviewed / domain-native | No row-specific failure recorded. | match schedule/result surface with players, round, outcome, and next action |
| `b25-v4-row-099-chess-local-install-open-2` | Chess Club | `chess-local-install-open` | member | B15_ext_chess_club_chess-local-install-open_complete | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B15/screenshots/B15_ext_chess_club_chess-local-install-open_complete.png` | `9e6d12b27709f...` | Arbitrary install and open \| Member form captures labeled details, privacy choices, and reviewer handoff. \| Labeled fields \| Privacy checked \| Review handoff \| Decide whether to save, edit, correct, or dispute the match result after checking opponent, round, and score. \| Edit ... | domain-native-reviewed / domain-native | No row-specific failure recorded. | match schedule/result surface with players, round, outcome, and next action |
| `b25-v4-row-100-chess-route-home-0` | Chess Club | `chess-route-home` | member | B15_ext_chess_club_chess-route-home_start | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B15/screenshots/B15_ext_chess_club_chess-route-home_start.png` | `73c7268dd0043...` | Chess Club home \| Member form captures labeled details, privacy choices, and reviewer handoff. \| Labeled fields \| Privacy checked \| Review handoff \| Decide whether to save, edit, correct, or dispute the match result after checking opponent, round, and score. \| Edit score \| Ope... | domain-native-reviewed / domain-native | No row-specific failure recorded. | match schedule/result surface with players, round, outcome, and next action |
| `b25-v4-row-101-chess-route-home-1` | Chess Club | `chess-route-home` | member | B15_ext_chess_club_chess-route-home_action | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B15/screenshots/B15_ext_chess_club_chess-route-home_action.png` | `0b0f3da4cfdea...` | Submit member form \| Use this surface to submit structured member details. \| Labeled fields \| Privacy checked \| Review handoff \| Decision \| Decide whether to save, edit, correct, or dispute the match result after checking opponent, round, and score. \| Details \| Required detail... | domain-native-reviewed / domain-native | No row-specific failure recorded. | match schedule/result surface with players, round, outcome, and next action |
| `b25-v4-row-102-chess-route-home-2` | Chess Club | `chess-route-home` | member | B15_ext_chess_club_chess-route-home_complete | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B15/screenshots/B15_ext_chess_club_chess-route-home_complete.png` | `c517ab02e5b25...` | Chess Club home \| Member form captures labeled details, privacy choices, and reviewer handoff. \| Labeled fields \| Privacy checked \| Review handoff \| Decide whether to save, edit, correct, or dispute the match result after checking opponent, round, and score. \| Edit score \| Rec... | domain-native-reviewed / domain-native | No row-specific failure recorded. | match schedule/result surface with players, round, outcome, and next action |
| `b25-v4-row-115-platform-messages-entry-0` | Member Social Space | `platform-messages-entry` | member | B16_ext_platform_social_platform-messages-entry_start | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B16/screenshots/B16_ext_platform_social_platform-messages-entry_start.png` | `620fd48362aa6...` | Messages \| Member communication stays scoped to the community relationship. \| Private by default \| Membership scoped \| Ready \| Decide whether to reply, send, accept, decline, mute, archive, or block this member communication. \| Archive thread \| Open Messages \| Connections \| Op... | domain-native-reviewed / domain-native | No row-specific failure recorded. | inbox, message thread, connection card, invite, or block-state surface |
| `b25-v4-row-116-platform-messages-entry-1` | Member Social Space | `platform-messages-entry` | member | B16_ext_platform_social_platform-messages-entry_action | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B16/screenshots/B16_ext_platform_social_platform-messages-entry_action.png` | `d2adbae820bd8...` | Update member channel \| Use this surface to change a member communication or relationship setting. \| Private by default \| Membership scoped \| Ready \| Decision \| Decide whether to reply, send, accept, decline, mute, archive, or block this member communication. \| Details \| Membe... | domain-native-reviewed / domain-native | No row-specific failure recorded. | inbox, message thread, connection card, invite, or block-state surface |
| `b25-v4-row-117-platform-messages-entry-2` | Member Social Space | `platform-messages-entry` | member | B16_ext_platform_social_platform-messages-entry_complete | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B16/screenshots/B16_ext_platform_social_platform-messages-entry_complete.png` | `a44790c25ed4f...` | Messages \| Member communication stays scoped to the community relationship. \| Private by default \| Membership scoped \| Ready \| Decide whether to reply, send, accept, decline, mute, archive, or block this member communication. \| Archive thread \| Setting saved \| The member setti... | domain-native-reviewed / domain-native | No row-specific failure recorded. | inbox, message thread, connection card, invite, or block-state surface |
| `b25-v4-row-118-platform-connections-entry-0` | Member Social Space | `platform-connections-entry` | member | B16_ext_platform_social_platform-connections-entry_start | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B16/screenshots/B16_ext_platform_social_platform-connections-entry_start.png` | `42d6af642292e...` | Connections \| Member communication stays scoped to the community relationship. \| Private by default \| Membership scoped \| Ready \| Decide whether to reply, send, accept, decline, mute, archive, or block this member communication. \| Archive thread \| Open Connections \| Connection... | domain-native-reviewed / domain-native | No row-specific failure recorded. | inbox, message thread, connection card, invite, or block-state surface |

### Failing Workflow/Persona Scorecards

Showing 10 of 10 failing scorecards. Full detail is in the JSON ticket.

| Scorecard | Community | Workflow | Persona | Failed questions | Target surface |
| --- | --- | --- | --- | ---: | --- |
| `b25-wp-008-book-selection-publish-community-book-club-owner` | Neighborhood Book Club | `book-selection-publish` | owner | 2 | announcement feed/composer with audience, author, timestamp, body, and receiver state |
| `b25-wp-013-soccer-minor-redaction-community-youth-soccer-guardian` | Riverside Youth Soccer | `soccer-minor-redaction` | guardian | 2 | protected youth roster/profile surface with minor-data redaction, guardian visibility, and coach-only detail state |
| `b25-wp-015-soccer-practice-schedule-community-youth-soccer-guardian` | Riverside Youth Soccer | `soccer-practice-schedule` | guardian | 2 | event detail with schedule, location, capacity/status, RSVP action, and result state |
| `b25-wp-016-soccer-reminder-notification-community-youth-soccer-guardian` | Riverside Youth Soccer | `soccer-reminder-notification` | guardian | 2 | notification inbox/detail surface with sender, audience, timestamp, message body, and receiver state |
| `b25-wp-019-hoa-member-document-community-hoa-member` | Cedar Commons HOA | `hoa-member-document` | member | 2 | document library/detail surface with title, audience, file metadata, and access state |
| `b25-wp-023-hoa-owner-notification-community-hoa-owner` | Cedar Commons HOA | `hoa-owner-notification` | owner | 2 | notification inbox/detail surface with sender, audience, timestamp, message body, and receiver state |
| `b25-wp-025-mosque-announcement-community-mosque-owner` | Masjid Nur | `mosque-announcement` | owner | 2 | announcement feed/composer with audience, author, timestamp, body, and receiver state |
| `b25-wp-031-mosque-neutral-notification-community-mosque-member` | Masjid Nur | `mosque-neutral-notification` | member | 2 | notification inbox/detail surface with sender, audience, timestamp, message body, and receiver state |
| `b25-wp-045-platform-top-banner-no-fill-community-platform-social-member` | Member Social Space | `platform-top-banner-no-fill` | member | 2 | App Shell top banner ad slot no-fill surface with preserved layout, disclosure/reserved space, and no content overlap |
| `b25-wp-046-platform-sensitive-no-fill-community-platform-social-member` | Member Social Space | `platform-sensitive-no-fill` | member | 2 | sensitive-context ad suppression surface with protected content visible and ad slot safely no-filled |

### Failing Workflow Lifecycle / Interaction Model Scorecards

Showing 16 of 16 failing lifecycle scorecards. Full semantic interaction-model detail is in the JSON ticket.

| Scorecard | Community | Workflow | Persona | Expected decision | Missing lifecycle groups | Missing actions | Wrong generic substitutes | Target surface |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `b25-wp-002-plant-exchange-submission-community-garden-club-member-lifecycle` | Garden Club | `plant-exchange-submission` | member | Member evaluates a concrete plant exchange item with owner, pickup details, availability, and claim/cancel paths. | semantic interaction model | domain-specific primary action | cancel | plant exchange offer form and member marketplace surface with plant details, pickup timing, owner contact, and submitted offer state |
| `b25-wp-007-book-discussion-message-community-book-club-member-lifecycle` | Neighborhood Book Club | `book-discussion-message` | member | Member evaluates a concrete message, connection, or invite with sender/recipient context and accept/decline/block paths. | persistent result state |  |  | inbox, message thread, connection card, invite, or block-state surface |
| `b25-wp-008-book-selection-publish-community-book-club-owner-lifecycle` | Neighborhood Book Club | `book-selection-publish` | owner | Admin decides whether a concrete announcement is ready for a named audience and delivery timing; members can later read the delivered update. | semantic interaction model | domain-specific primary action | ok | announcement feed/composer with audience, author, timestamp, body, and receiver state |
| `b25-wp-033-chess-local-install-open-community-chess-club-member-lifecycle` | Chess Club | `chess-local-install-open` | member | Participant records or reviews a concrete match with opponent, score/result, and correction/dispute paths. | semantic interaction model | domain-specific primary action |  | match schedule/result surface with players, round, outcome, and next action |
| `b25-wp-034-chess-route-home-community-chess-club-member-lifecycle` | Chess Club | `chess-route-home` | member | Participant records or reviews a concrete match with opponent, score/result, and correction/dispute paths. | semantic interaction model | domain-specific primary action |  | match schedule/result surface with players, round, outcome, and next action |
| `b25-wp-039-platform-messages-entry-community-platform-social-member-lifecycle` | Member Social Space | `platform-messages-entry` | member | Member evaluates a concrete message, connection, or invite with sender/recipient context and accept/decline/block paths. | persistent result state |  |  | inbox, message thread, connection card, invite, or block-state surface |
| `b25-wp-040-platform-connections-entry-community-platform-social-member-lifecycle` | Member Social Space | `platform-connections-entry` | member | Member evaluates a concrete message, connection, or invite with sender/recipient context and accept/decline/block paths. | persistent result state |  |  | inbox, message thread, connection card, invite, or block-state surface |
| `b25-wp-041-platform-connection-invite-community-platform-social-member-lifecycle` | Member Social Space | `platform-connection-invite` | member | Member evaluates a concrete message, connection, or invite with sender/recipient context and accept/decline/block paths. | persistent result state |  |  | inbox, message thread, connection card, invite, or block-state surface |
| `b25-wp-043-platform-message-stream-community-platform-social-member-lifecycle` | Member Social Space | `platform-message-stream` | member | Member evaluates a concrete message, connection, or invite with sender/recipient context and accept/decline/block paths. | persistent result state |  |  | inbox, message thread, connection card, invite, or block-state surface |
| `b25-wp-062-wf-persona-role-inventory-capability-matrix-persona-role-inventory-admin-lifecycle` | persona-role-inventory | `wf_persona-role-inventory-capability-matrix` | admin |  |  |  |  | persona capability matrix surface with roles, allowed actions, receiver states, and denied/hidden behavior |
| `b25-wp-063-wf-persona-role-inventory-capability-matrix-persona-role-inventory-member-lifecycle` | persona-role-inventory | `wf_persona-role-inventory-capability-matrix` | member |  |  |  |  | persona capability matrix surface with roles, allowed actions, receiver states, and denied/hidden behavior |
| `b25-wp-064-wf-demo-app-persona-picker-community-mosque-member-lifecycle` | Masjid Nur | `wf_demo-app-persona-picker` | member |  |  |  |  | test-only persona switcher surface with active persona, role description, and return-to-workflow state |
| `b25-wp-065-wf-community-persona-aware-ux-community-mosque-member-lifecycle` | Masjid Nur | `wf_community-persona-aware-ux` | member |  |  |  |  | persona-aware community surface showing actor, receiver, read-only, disabled, or hidden workflow states for the active role |
| `b25-wp-066-wf-community-persona-aware-ux-community-mosque-admin-lifecycle` | Masjid Nur | `wf_community-persona-aware-ux` | admin |  |  |  |  | persona-aware community surface showing actor, receiver, read-only, disabled, or hidden workflow states for the active role |
| `b25-wp-067-wf-multi-persona-workflow-evidence-community-mosque-admin-lifecycle` | Masjid Nur | `wf_multi-persona-workflow-evidence` | admin |  |  |  |  | multi-persona handoff evidence surface with actor-created state, persona switch, receiver state, and continuation action |
| `b25-wp-068-wf-multi-persona-workflow-evidence-community-mosque-member-lifecycle` | Masjid Nur | `wf_multi-persona-workflow-evidence` | member |  |  |  |  | multi-persona handoff evidence surface with actor-created state, persona switch, receiver state, and continuation action |

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
- Screen row `b25-v4-row-004-plant-exchange-submission-0` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-004-plant-exchange-submission-0` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-004-plant-exchange-submission-0` names visible UI elements, visible text, persona `member`, workflow `plant-exchange-submission`, and the exact product UX issue.
- Primary surface for `plant-exchange-submission` is documented as `plant exchange offer form and member marketplace surface with plant details, pickup timing, owner contact, and submitted offer state` or another explicit domain-native surface.
- After-screenshot visible text proves every required semantic surface group for `plant-exchange-submission`.
- Fresh screenshot path/hash/timestamp/app commit SHA are recorded after the fix.
- The workflow lifecycle scorecard passes with no missing object/context, decision information, action affordance, result state, or receiver/continuation groups.
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
- All lifecycle direct questions in this workflow/persona scorecard pass.
- The UI visibly proves the concrete object/context, decision information, primary action, alternate/change/reject affordance, persistent result state, and receiver/continuation state.
- The semantic interaction model passes: expected decision, required primary actions, and required alternate/change/reject actions are visible in fresh after screenshots.
- Missing lifecycle groups are resolved: semantic interaction model.
- Fresh after screenshots prove the lifecycle and interaction model; implementation notes, code diffs, or ticket responses alone cannot close this ticket.
- The `plant-exchange-submission` screenshots show the concrete domain object/context for `member`.
- The user can see enough domain-specific decision information before acting.
- The UI provides semantic primary action and the needed alternate/change/reject/defer path; `Cancel` alone cannot stand in for a real decline/reject/change response.
- The semantic interaction model names the correct user decision and the right domain actions for `plant-exchange-submission`; generic accept/cancel or submit/cancel actions do not satisfy this criterion.
- The post-action screen shows a persistent result/receipt/status state that can be understood later.
- The receiver/read-only/continuation state is visible where another persona or later state is part of the workflow.
- The workflow lifecycle scorecard passes with no missing lifecycle groups.
- Screen row `b25-wp-002-plant-exchange-submission-community-garden-club-member` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-wp-002-plant-exchange-submission-community-garden-club-member` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-wp-002-plant-exchange-submission-community-garden-club-member` names visible UI elements, visible text, persona `member`, workflow `plant-exchange-submission`, and the exact product UX issue.
- Missing lifecycle groups are resolved: persistent result state.
- The `book-discussion-message` screenshots show the concrete domain object/context for `member`.
- The semantic interaction model names the correct user decision and the right domain actions for `book-discussion-message`; generic accept/cancel or submit/cancel actions do not satisfy this criterion.
- Screen row `b25-wp-007-book-discussion-message-community-book-club-member` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-wp-007-book-discussion-message-community-book-club-member` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-wp-007-book-discussion-message-community-book-club-member` names visible UI elements, visible text, persona `member`, workflow `book-discussion-message`, and the exact product UX issue.
- The `book-selection-publish` screenshots show the concrete domain object/context for `owner`.
- The semantic interaction model names the correct user decision and the right domain actions for `book-selection-publish`; generic accept/cancel or submit/cancel actions do not satisfy this criterion.
- Screen row `b25-wp-008-book-selection-publish-community-book-club-owner` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-wp-008-book-selection-publish-community-book-club-owner` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-wp-008-book-selection-publish-community-book-club-owner` names visible UI elements, visible text, persona `owner`, workflow `book-selection-publish`, and the exact product UX issue.
- The `chess-local-install-open` screenshots show the concrete domain object/context for `member`.
- The semantic interaction model names the correct user decision and the right domain actions for `chess-local-install-open`; generic accept/cancel or submit/cancel actions do not satisfy this criterion.
- Screen row `b25-wp-033-chess-local-install-open-community-chess-club-member` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-wp-033-chess-local-install-open-community-chess-club-member` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-wp-033-chess-local-install-open-community-chess-club-member` names visible UI elements, visible text, persona `member`, workflow `chess-local-install-open`, and the exact product UX issue.
- Primary surface for `chess-local-install-open` is documented as `match schedule/result surface with players, round, outcome, and next action` or another explicit domain-native surface.
- After-screenshot visible text proves every required semantic surface group for `chess-local-install-open`.
- The `chess-route-home` screenshots show the concrete domain object/context for `member`.
- The semantic interaction model names the correct user decision and the right domain actions for `chess-route-home`; generic accept/cancel or submit/cancel actions do not satisfy this criterion.
- Screen row `b25-wp-034-chess-route-home-community-chess-club-member` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-wp-034-chess-route-home-community-chess-club-member` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-wp-034-chess-route-home-community-chess-club-member` names visible UI elements, visible text, persona `member`, workflow `chess-route-home`, and the exact product UX issue.
- Primary surface for `chess-route-home` is documented as `match schedule/result surface with players, round, outcome, and next action` or another explicit domain-native surface.
- After-screenshot visible text proves every required semantic surface group for `chess-route-home`.
- The `platform-messages-entry` screenshots show the concrete domain object/context for `member`.
- The semantic interaction model names the correct user decision and the right domain actions for `platform-messages-entry`; generic accept/cancel or submit/cancel actions do not satisfy this criterion.
- Screen row `b25-wp-039-platform-messages-entry-community-platform-social-member` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-wp-039-platform-messages-entry-community-platform-social-member` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-wp-039-platform-messages-entry-community-platform-social-member` names visible UI elements, visible text, persona `member`, workflow `platform-messages-entry`, and the exact product UX issue.
- Primary surface for `platform-messages-entry` is documented as `inbox, message thread, connection card, invite, or block-state surface` or another explicit domain-native surface.
- After-screenshot visible text proves every required semantic surface group for `platform-messages-entry`.
- The `platform-connections-entry` screenshots show the concrete domain object/context for `member`.
- The semantic interaction model names the correct user decision and the right domain actions for `platform-connections-entry`; generic accept/cancel or submit/cancel actions do not satisfy this criterion.
- Screen row `b25-wp-040-platform-connections-entry-community-platform-social-member` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-wp-040-platform-connections-entry-community-platform-social-member` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-wp-040-platform-connections-entry-community-platform-social-member` names visible UI elements, visible text, persona `member`, workflow `platform-connections-entry`, and the exact product UX issue.
- Primary surface for `platform-connections-entry` is documented as `inbox, message thread, connection card, invite, or block-state surface` or another explicit domain-native surface.
- After-screenshot visible text proves every required semantic surface group for `platform-connections-entry`.
- The `platform-connection-invite` screenshots show the concrete domain object/context for `member`.
- The semantic interaction model names the correct user decision and the right domain actions for `platform-connection-invite`; generic accept/cancel or submit/cancel actions do not satisfy this criterion.
- Screen row `b25-wp-041-platform-connection-invite-community-platform-social-member` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-wp-041-platform-connection-invite-community-platform-social-member` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-wp-041-platform-connection-invite-community-platform-social-member` names visible UI elements, visible text, persona `member`, workflow `platform-connection-invite`, and the exact product UX issue.
- Primary surface for `platform-connection-invite` is documented as `inbox, message thread, connection card, invite, or block-state surface` or another explicit domain-native surface.
- After-screenshot visible text proves every required semantic surface group for `platform-connection-invite`.
- The `platform-message-stream` screenshots show the concrete domain object/context for `member`.
- The semantic interaction model names the correct user decision and the right domain actions for `platform-message-stream`; generic accept/cancel or submit/cancel actions do not satisfy this criterion.
- Screen row `b25-wp-043-platform-message-stream-community-platform-social-member` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-wp-043-platform-message-stream-community-platform-social-member` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-wp-043-platform-message-stream-community-platform-social-member` names visible UI elements, visible text, persona `member`, workflow `platform-message-stream`, and the exact product UX issue.
- Primary surface for `platform-message-stream` is documented as `inbox, message thread, connection card, invite, or block-state surface` or another explicit domain-native surface.
- After-screenshot visible text proves every required semantic surface group for `platform-message-stream`.
- Missing lifecycle groups are resolved: none.
- The `wf_persona-role-inventory-capability-matrix` screenshots show the concrete domain object/context for `admin`.
- The semantic interaction model names the correct user decision and the right domain actions for `wf_persona-role-inventory-capability-matrix`; generic accept/cancel or submit/cancel actions do not satisfy this criterion.
- Screen row `b25-wp-062-wf-persona-role-inventory-capability-matrix-persona-role-inventory-admin` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-wp-062-wf-persona-role-inventory-capability-matrix-persona-role-inventory-admin` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-wp-062-wf-persona-role-inventory-capability-matrix-persona-role-inventory-admin` names visible UI elements, visible text, persona `admin`, workflow `wf_persona-role-inventory-capability-matrix`, and the exact product UX issue.
- Primary surface for `wf_persona-role-inventory-capability-matrix` is documented as `persona capability matrix surface with roles, allowed actions, receiver states, and denied/hidden behavior` or another explicit domain-native surface.
- After-screenshot visible text proves every required semantic surface group for `wf_persona-role-inventory-capability-matrix`.
- The `wf_persona-role-inventory-capability-matrix` screenshots show the concrete domain object/context for `member`.
- Screen row `b25-wp-063-wf-persona-role-inventory-capability-matrix-persona-role-inventory-member` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-wp-063-wf-persona-role-inventory-capability-matrix-persona-role-inventory-member` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-wp-063-wf-persona-role-inventory-capability-matrix-persona-role-inventory-member` names visible UI elements, visible text, persona `member`, workflow `wf_persona-role-inventory-capability-matrix`, and the exact product UX issue.
- The `wf_demo-app-persona-picker` screenshots show the concrete domain object/context for `member`.
- The semantic interaction model names the correct user decision and the right domain actions for `wf_demo-app-persona-picker`; generic accept/cancel or submit/cancel actions do not satisfy this criterion.
- Screen row `b25-wp-064-wf-demo-app-persona-picker-community-mosque-member` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-wp-064-wf-demo-app-persona-picker-community-mosque-member` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-wp-064-wf-demo-app-persona-picker-community-mosque-member` names visible UI elements, visible text, persona `member`, workflow `wf_demo-app-persona-picker`, and the exact product UX issue.
- Primary surface for `wf_demo-app-persona-picker` is documented as `test-only persona switcher surface with active persona, role description, and return-to-workflow state` or another explicit domain-native surface.
- After-screenshot visible text proves every required semantic surface group for `wf_demo-app-persona-picker`.

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

## B25-RT-007-b25-c08-visible-text-specific-critique

| Field | Value |
| --- | --- |
| Severity | major |
| Priority | P1 |
| Status | open |
| Review run | `b25-v4-pass-10` |
| Source criterion | `b25-c08-visible-text-specific-critique` |
| Source findings | B25-WORKFLOW-LIFECYCLE-INCOMPLETE |
| Title | Every row has visible text and screen-specific critique |
| Direct question | Does every holistic and workflow/persona review answer cite visible UI/text and provide a critique specific to that screenshot and user task? |
| Why it failed | Workflow/persona direct-question scorecards have missing or blocking answers: book-selection-publish/owner, soccer-minor-redaction/guardian, soccer-practice-schedule/guardian, soccer-reminder-notification/guardian, hoa-member-document/member, hoa-owner-notification/owner, mosque-announcement/owner, mosque-neutral-notification/member, platform-top-banner-no-fill/member, platform-sensitive-no-fill/member. |
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
| Feed item and composer pattern | Material cards/lists/text fields / pattern | https://m3.material.io/components/text-fields/overview<br>Also: https://m3.material.io/components/cards/overview<br>https://m3.material.io/components/lists/overview | Copy a feed/composer structure: audience, author, timestamp, body, attachments/status, publish action, and receiver read state. |
| Material navigation and information architecture | Material Design 3 / design-system | https://m3.material.io/components/navigation-drawer/overview<br>Also: https://m3.material.io/components/navigation-bar/overview | Organize screens by user jobs and destinations; keep primary actions visible and avoid exposing implementation taxonomy. |
| Apple HIG navigation and content organization | Apple Human Interface Guidelines / design-system | https://developer.apple.com/design/human-interface-guidelines/navigation | Make navigation predictable, content-centered, and appropriate for the user’s current task. |
| Material detail surface composition | Material Design 3 / design-system | https://m3.material.io/components/cards/overview | Build a domain detail page with primary content, metadata, status, and actions instead of a generic task card. |
| Event detail and RSVP flow | Material cards/lists/buttons / pattern | https://m3.material.io/components/cards/overview<br>Also: https://m3.material.io/components/buttons/overview<br>https://m3.material.io/components/chips/overview | Copy an event detail layout: title, date/time, location, host, capacity/status chip, attendee context, RSVP action, and confirmation state. |
| Document list/detail pattern | Material lists/cards / pattern | https://m3.material.io/components/lists/overview | Copy a document library with title, category, audience, file metadata, access state, download/view action, and empty/error states. |

### Reference Research Queries
- production mobile UX review screenshot critique examples
- open source Flutter mobile app UX patterns GitHub
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
- Material Design App Shell top banner ad slot no-fill surface with preserved layout, disclosure/reserved space, and no content overlap mobile pattern
- sensitive-context ad suppression surface with protected content visible and ad slot safely no-filled mobile UX pattern
- Material Design sensitive-context ad suppression surface with protected content visible and ad slot safely no-filled mobile pattern

### Implementation Blocked By
- Affected rows still use generic or missing persona data.
- Visible text is not proven from screenshot OCR/manual extraction.
- Screen-specific critiques are incomplete or reusable.
- Primary surface classification is incomplete or unverified.

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

### Affected Workflow/Persona Coverage

Showing 10 of 10 affected coverage rows. Full detail is in the JSON ticket.

| Coverage row | Status | Community | Workflow | Persona | Missing evidence | Screen rows | Target surface |
| --- | --- | --- | --- | --- | --- | ---: | --- |
| `b25-wp-008-book-selection-publish-community-book-club-owner` | `pass` | Neighborhood Book Club | `book-selection-publish` | owner |  | 3 | announcement feed/composer with audience, author, timestamp, body, and receiver state |
| `b25-wp-013-soccer-minor-redaction-community-youth-soccer-guardian` | `pass` | Riverside Youth Soccer | `soccer-minor-redaction` | guardian |  | 3 | protected youth roster/profile surface with minor-data redaction, guardian visibility, and coach-only detail state |
| `b25-wp-015-soccer-practice-schedule-community-youth-soccer-guardian` | `pass` | Riverside Youth Soccer | `soccer-practice-schedule` | guardian |  | 3 | event detail with schedule, location, capacity/status, RSVP action, and result state |
| `b25-wp-016-soccer-reminder-notification-community-youth-soccer-guardian` | `pass` | Riverside Youth Soccer | `soccer-reminder-notification` | guardian |  | 3 | notification inbox/detail surface with sender, audience, timestamp, message body, and receiver state |
| `b25-wp-019-hoa-member-document-community-hoa-member` | `pass` | Cedar Commons HOA | `hoa-member-document` | member |  | 3 | document library/detail surface with title, audience, file metadata, and access state |
| `b25-wp-023-hoa-owner-notification-community-hoa-owner` | `pass` | Cedar Commons HOA | `hoa-owner-notification` | owner |  | 3 | notification inbox/detail surface with sender, audience, timestamp, message body, and receiver state |
| `b25-wp-025-mosque-announcement-community-mosque-owner` | `pass` | Masjid Nur | `mosque-announcement` | owner |  | 3 | announcement feed/composer with audience, author, timestamp, body, and receiver state |
| `b25-wp-031-mosque-neutral-notification-community-mosque-member` | `pass` | Masjid Nur | `mosque-neutral-notification` | member |  | 3 | notification inbox/detail surface with sender, audience, timestamp, message body, and receiver state |
| `b25-wp-045-platform-top-banner-no-fill-community-platform-social-member` | `pass` | Member Social Space | `platform-top-banner-no-fill` | member |  | 3 | App Shell top banner ad slot no-fill surface with preserved layout, disclosure/reserved space, and no content overlap |
| `b25-wp-046-platform-sensitive-no-fill-community-platform-social-member` | `pass` | Member Social Space | `platform-sensitive-no-fill` | member |  | 3 | sensitive-context ad suppression surface with protected content visible and ad slot safely no-filled |

### Affected Screen Rows

Showing 30 of 30 affected screen rows. Full detail is in the JSON ticket.

| Screen row | Community | Workflow | Persona | State | Screenshot | Hash | Visible text | Current surface | Exact UX failure | Target surface |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `b25-v4-row-022-book-selection-publish-0` | Neighborhood Book Club | `book-selection-publish` | owner | B14_ext_book_club_book-selection-publish_start | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_book_club_book-selection-publish_start.png` | `199dc193ec1c1...` | Selected-book publishing \| Member form captures labeled details, privacy choices, and reviewer handoff. \| Members \| Today \| Inbox + push \| Decide whether this message is ready for members, who receives it, and whether to preview or save a draft first. \| Save draft \| Publish se... | domain-native-reviewed / domain-native | Ticket must add screenshot-backed visible text and a non-reusable critique for this exact screen. | announcement feed/composer with audience, author, timestamp, body, and receiver state |
| `b25-v4-row-023-book-selection-publish-1` | Neighborhood Book Club | `book-selection-publish` | owner | B14_ext_book_club_book-selection-publish_action | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_book_club_book-selection-publish_action.png` | `c059d086991f4...` | Send community notice \| Use this surface to send a scoped announcement to the selected audience. \| Members \| Today \| Inbox + push \| Decision \| Decide whether this message is ready for members, who receives it, and whether to preview or save a draft first. \| Details \| Message, ... | domain-native-reviewed / domain-native | Ticket must add screenshot-backed visible text and a non-reusable critique for this exact screen. | announcement feed/composer with audience, author, timestamp, body, and receiver state |
| `b25-v4-row-024-book-selection-publish-2` | Neighborhood Book Club | `book-selection-publish` | owner | B14_ext_book_club_book-selection-publish_complete | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_book_club_book-selection-publish_complete.png` | `d993e32ccf226...` | Selected-book publishing \| Member form captures labeled details, privacy choices, and reviewer handoff. \| Members \| Today \| Inbox + push \| Decide whether this message is ready for members, who receives it, and whether to preview or save a draft first. \| Save draft \| Update sen... | domain-native-reviewed / domain-native | Ticket must add screenshot-backed visible text and a non-reusable critique for this exact screen. | announcement feed/composer with audience, author, timestamp, body, and receiver state |
| `b25-v4-row-037-soccer-minor-redaction-0` | Riverside Youth Soccer | `soccer-minor-redaction` | guardian | B14_ext_youth_soccer_soccer-minor-redaction_start | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_youth_soccer_soccer-minor-redaction_start.png` | `5ff37fc80ea61...` | Protected minor-data redaction \| Data package includes scope, protected fields, and handoff status. \| Redacted copy \| Checksum ready \| Exportable \| Decide what to save, what to change, and what status or next step should remain visible afterward. \| Edit response \| Preview reda... | domain-native-reviewed / domain-native | Ticket must add screenshot-backed visible text and a non-reusable critique for this exact screen. | protected youth roster/profile surface with minor-data redaction, guardian visibility, and coach-only detail state |
| `b25-v4-row-038-soccer-minor-redaction-1` | Riverside Youth Soccer | `soccer-minor-redaction` | guardian | B14_ext_youth_soccer_soccer-minor-redaction_action | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_youth_soccer_soccer-minor-redaction_action.png` | `a34740353febe...` | Prepare export handoff \| Use this surface to package export scope, redaction, and handoff status. \| Redacted copy \| Checksum ready \| Exportable \| Decision \| Decide what to save, what to change, and what status or next step should remain visible afterward. \| Details \| Data scop... | domain-native-reviewed / domain-native | Ticket must add screenshot-backed visible text and a non-reusable critique for this exact screen. | protected youth roster/profile surface with minor-data redaction, guardian visibility, and coach-only detail state |
| `b25-v4-row-039-soccer-minor-redaction-2` | Riverside Youth Soccer | `soccer-minor-redaction` | guardian | B14_ext_youth_soccer_soccer-minor-redaction_complete | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_youth_soccer_soccer-minor-redaction_complete.png` | `58d80584c59f6...` | Protected minor-data redaction \| Data package includes scope, protected fields, and handoff status. \| Redacted copy \| Checksum ready \| Exportable \| Decide what to save, what to change, and what status or next step should remain visible afterward. \| Edit response \| Data package... | domain-native-reviewed / domain-native | Ticket must add screenshot-backed visible text and a non-reusable critique for this exact screen. | protected youth roster/profile surface with minor-data redaction, guardian visibility, and coach-only detail state |
| `b25-v4-row-043-soccer-practice-schedule-0` | Riverside Youth Soccer | `soccer-practice-schedule` | guardian | B14_ext_youth_soccer_soccer-practice-schedule_start | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_youth_soccer_soccer-practice-schedule_start.png` | `8537ce5e05a89...` | Practice schedule \| Member form captures labeled details, privacy choices, and reviewer handoff. \| This week \| Community venue \| Capacity tracked \| Decide if you are going, maybe, or not attending after checking date, time, location, and capacity. \| Change response \| Publish s... | domain-native-reviewed / domain-native | Ticket must add screenshot-backed visible text and a non-reusable critique for this exact screen. | event detail with schedule, location, capacity/status, RSVP action, and result state |
| `b25-v4-row-044-soccer-practice-schedule-1` | Riverside Youth Soccer | `soccer-practice-schedule` | guardian | B14_ext_youth_soccer_soccer-practice-schedule_action | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_youth_soccer_soccer-practice-schedule_action.png` | `64e955fed1c75...` | Coordinate attendance \| Use this surface to publish event details, capacity, and attendance state. \| This week \| Community venue \| Capacity tracked \| Decision \| Decide if you are going, maybe, or not attending after checking date, time, location, and capacity. \| Details \| Date... | domain-native-reviewed / domain-native | Ticket must add screenshot-backed visible text and a non-reusable critique for this exact screen. | event detail with schedule, location, capacity/status, RSVP action, and result state |
| `b25-v4-row-045-soccer-practice-schedule-2` | Riverside Youth Soccer | `soccer-practice-schedule` | guardian | B14_ext_youth_soccer_soccer-practice-schedule_complete | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_youth_soccer_soccer-practice-schedule_complete.png` | `25188d0d93a29...` | Practice schedule \| Member form captures labeled details, privacy choices, and reviewer handoff. \| This week \| Community venue \| Capacity tracked \| Decide if you are going, maybe, or not attending after checking date, time, location, and capacity. \| Change response \| Event upd... | domain-native-reviewed / domain-native | Ticket must add screenshot-backed visible text and a non-reusable critique for this exact screen. | event detail with schedule, location, capacity/status, RSVP action, and result state |
| `b25-v4-row-046-soccer-reminder-notification-0` | Riverside Youth Soccer | `soccer-reminder-notification` | guardian | B14_ext_youth_soccer_soccer-reminder-notification_start | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_youth_soccer_soccer-reminder-notification_start.png` | `4d6ce7fd90b81...` | Reminder notification \| Member form captures labeled details, privacy choices, and reviewer handoff. \| Members \| Today \| Inbox + push \| Decide what to save, what to change, and what status or next step should remain visible afterward. \| Edit response \| Send reminder \| Upcoming... | domain-native-reviewed / domain-native | Ticket must add screenshot-backed visible text and a non-reusable critique for this exact screen. | notification inbox/detail surface with sender, audience, timestamp, message body, and receiver state |
| `b25-v4-row-047-soccer-reminder-notification-1` | Riverside Youth Soccer | `soccer-reminder-notification` | guardian | B14_ext_youth_soccer_soccer-reminder-notification_action | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_youth_soccer_soccer-reminder-notification_action.png` | `0a8c55d3585af...` | Send community notice \| Use this surface to send a scoped announcement to the selected audience. \| Members \| Today \| Inbox + push \| Decision \| Decide what to save, what to change, and what status or next step should remain visible afterward. \| Details \| Message, audience, prev... | domain-native-reviewed / domain-native | Ticket must add screenshot-backed visible text and a non-reusable critique for this exact screen. | notification inbox/detail surface with sender, audience, timestamp, message body, and receiver state |
| `b25-v4-row-048-soccer-reminder-notification-2` | Riverside Youth Soccer | `soccer-reminder-notification` | guardian | B14_ext_youth_soccer_soccer-reminder-notification_complete | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_youth_soccer_soccer-reminder-notification_complete.png` | `f2315a1a94f66...` | Reminder notification \| Member form captures labeled details, privacy choices, and reviewer handoff. \| Members \| Today \| Inbox + push \| Decide what to save, what to change, and what status or next step should remain visible afterward. \| Edit response \| Update sent \| The update... | domain-native-reviewed / domain-native | Ticket must add screenshot-backed visible text and a non-reusable critique for this exact screen. | notification inbox/detail surface with sender, audience, timestamp, message body, and receiver state |
| `b25-v4-row-055-hoa-member-document-0` | Cedar Commons HOA | `hoa-member-document` | member | B14_ext_hoa_hoa-member-document_start | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_hoa_hoa-member-document_start.png` | `0de48bcf3bfeb...` | Member-visible document \| Member form captures labeled details, privacy choices, and reviewer handoff. \| Labeled fields \| Privacy checked \| Review handoff \| Decide whether to open, download, save, share, or request access to this document. \| Save document \| Open document \| HOA... | domain-native-reviewed / domain-native | Ticket must add screenshot-backed visible text and a non-reusable critique for this exact screen. | document library/detail surface with title, audience, file metadata, and access state |
| `b25-v4-row-056-hoa-member-document-1` | Cedar Commons HOA | `hoa-member-document` | member | B14_ext_hoa_hoa-member-document_action | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_hoa_hoa-member-document_action.png` | `fd2c4a811a821...` | Submit member form \| Use this surface to submit structured member details. \| Labeled fields \| Privacy checked \| Review handoff \| Decision \| Decide whether to open, download, save, share, or request access to this document. \| Details \| Required details are ready. Required field... | domain-native-reviewed / domain-native | Ticket must add screenshot-backed visible text and a non-reusable critique for this exact screen. | document library/detail surface with title, audience, file metadata, and access state |
| `b25-v4-row-057-hoa-member-document-2` | Cedar Commons HOA | `hoa-member-document` | member | B14_ext_hoa_hoa-member-document_complete | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_hoa_hoa-member-document_complete.png` | `6f70fa36707ff...` | Member-visible document \| Member form captures labeled details, privacy choices, and reviewer handoff. \| Labeled fields \| Privacy checked \| Review handoff \| Decide whether to open, download, save, share, or request access to this document. \| Save document \| Record saved \| The ... | domain-native-reviewed / domain-native | Ticket must add screenshot-backed visible text and a non-reusable critique for this exact screen. | document library/detail surface with title, audience, file metadata, and access state |
| `b25-v4-row-067-hoa-owner-notification-0` | Cedar Commons HOA | `hoa-owner-notification` | owner | B14_ext_hoa_hoa-owner-notification_start | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_hoa_hoa-owner-notification_start.png` | `9464d29a05745...` | Owner notification \| Member form captures labeled details, privacy choices, and reviewer handoff. \| Members \| Today \| Inbox + push \| Decide what to save, what to change, and what status or next step should remain visible afterward. \| Edit response \| Send notification \| Giving ... | domain-native-reviewed / domain-native | Ticket must add screenshot-backed visible text and a non-reusable critique for this exact screen. | notification inbox/detail surface with sender, audience, timestamp, message body, and receiver state |
| `b25-v4-row-068-hoa-owner-notification-1` | Cedar Commons HOA | `hoa-owner-notification` | owner | B14_ext_hoa_hoa-owner-notification_action | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_hoa_hoa-owner-notification_action.png` | `9c8815be457ad...` | Send community notice \| Use this surface to send a scoped announcement to the selected audience. \| Members \| Today \| Inbox + push \| Decision \| Decide what to save, what to change, and what status or next step should remain visible afterward. \| Details \| Message, audience, prev... | domain-native-reviewed / domain-native | Ticket must add screenshot-backed visible text and a non-reusable critique for this exact screen. | notification inbox/detail surface with sender, audience, timestamp, message body, and receiver state |
| `b25-v4-row-069-hoa-owner-notification-2` | Cedar Commons HOA | `hoa-owner-notification` | owner | B14_ext_hoa_hoa-owner-notification_complete | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_hoa_hoa-owner-notification_complete.png` | `ed487cfc968f5...` | Owner notification \| Member form captures labeled details, privacy choices, and reviewer handoff. \| Members \| Today \| Inbox + push \| Decide what to save, what to change, and what status or next step should remain visible afterward. \| Edit response \| Update sent \| The update is... | domain-native-reviewed / domain-native | Ticket must add screenshot-backed visible text and a non-reusable critique for this exact screen. | notification inbox/detail surface with sender, audience, timestamp, message body, and receiver state |
| `b25-v4-row-073-mosque-announcement-0` | Masjid Nur | `mosque-announcement` | owner | B14_ext_mosque_mosque-announcement_start | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_mosque_mosque-announcement_start.png` | `4baff4e2a7ae5...` | Public announcement \| Draft message includes audience, timing, and delivery details. \| Members \| Today \| Inbox + push \| Decide whether this message is ready for members, who receives it, and whether to preview or save a draft first. \| Preview announcement \| Publish announcemen... | domain-native-reviewed / domain-native | Ticket must add screenshot-backed visible text and a non-reusable critique for this exact screen. | announcement feed/composer with audience, author, timestamp, body, and receiver state |
| `b25-v4-row-074-mosque-announcement-1` | Masjid Nur | `mosque-announcement` | owner | B14_ext_mosque_mosque-announcement_action | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_mosque_mosque-announcement_action.png` | `8e79c188137ea...` | Send community notice \| Use this surface to send a scoped announcement to the selected audience. \| Members \| Today \| Inbox + push \| Decision \| Decide whether this message is ready for members, who receives it, and whether to preview or save a draft first. \| Details \| Message, ... | domain-native-reviewed / domain-native | Ticket must add screenshot-backed visible text and a non-reusable critique for this exact screen. | announcement feed/composer with audience, author, timestamp, body, and receiver state |
| `b25-v4-row-075-mosque-announcement-2` | Masjid Nur | `mosque-announcement` | owner | B14_ext_mosque_mosque-announcement_complete | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_mosque_mosque-announcement_complete.png` | `5b4b0768918c1...` | Public announcement \| Draft message includes audience, timing, and delivery details. \| Members \| Today \| Inbox + push \| Decide whether this message is ready for members, who receives it, and whether to preview or save a draft first. \| Preview announcement \| Announcement posted... | domain-native-reviewed / domain-native | Ticket must add screenshot-backed visible text and a non-reusable critique for this exact screen. | announcement feed/composer with audience, author, timestamp, body, and receiver state |
| `b25-v4-row-091-mosque-neutral-notification-0` | Masjid Nur | `mosque-neutral-notification` | member | B14_ext_mosque_mosque-neutral-notification_start | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_mosque_mosque-neutral-notification_start.png` | `0310556ae513f...` | Neutral care notification \| Member form captures labeled details, privacy choices, and reviewer handoff. \| Members \| Today \| Inbox + push \| Decide what to save, what to change, and what status or next step should remain visible afterward. \| Edit response \| Send notification \| ... | domain-native-reviewed / domain-native | Ticket must add screenshot-backed visible text and a non-reusable critique for this exact screen. | notification inbox/detail surface with sender, audience, timestamp, message body, and receiver state |
| `b25-v4-row-092-mosque-neutral-notification-1` | Masjid Nur | `mosque-neutral-notification` | member | B14_ext_mosque_mosque-neutral-notification_action | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_mosque_mosque-neutral-notification_action.png` | `9c8815be457ad...` | Send community notice \| Use this surface to send a scoped announcement to the selected audience. \| Members \| Today \| Inbox + push \| Decision \| Decide what to save, what to change, and what status or next step should remain visible afterward. \| Details \| Message, audience, prev... | domain-native-reviewed / domain-native | Ticket must add screenshot-backed visible text and a non-reusable critique for this exact screen. | notification inbox/detail surface with sender, audience, timestamp, message body, and receiver state |
| `b25-v4-row-093-mosque-neutral-notification-2` | Masjid Nur | `mosque-neutral-notification` | member | B14_ext_mosque_mosque-neutral-notification_complete | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_mosque_mosque-neutral-notification_complete.png` | `56ee694ccf884...` | Neutral care notification \| Member form captures labeled details, privacy choices, and reviewer handoff. \| Members \| Today \| Inbox + push \| Decide what to save, what to change, and what status or next step should remain visible afterward. \| Edit response \| Update sent \| The up... | domain-native-reviewed / domain-native | Ticket must add screenshot-backed visible text and a non-reusable critique for this exact screen. | notification inbox/detail surface with sender, audience, timestamp, message body, and receiver state |
| `b25-v4-row-133-platform-top-banner-no-fill-0` | Member Social Space | `platform-top-banner-no-fill` | member | B16_ext_platform_social_platform-top-banner-no-fill_start | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B16/screenshots/B16_ext_platform_social_platform-top-banner-no-fill_start.png` | `5c0d10aa1672f...` | Top banner status \| Member form captures labeled details, privacy choices, and reviewer handoff. \| Private by default \| Membership scoped \| Ready \| Decide what to save, what to change, and what status or next step should remain visible afterward. \| Edit response \| Review ad st... | domain-native-reviewed / domain-native | Ticket must add screenshot-backed visible text and a non-reusable critique for this exact screen. | App Shell top banner ad slot no-fill surface with preserved layout, disclosure/reserved space, and no content overlap |
| `b25-v4-row-134-platform-top-banner-no-fill-1` | Member Social Space | `platform-top-banner-no-fill` | member | B16_ext_platform_social_platform-top-banner-no-fill_action | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B16/screenshots/B16_ext_platform_social_platform-top-banner-no-fill_action.png` | `824b83aea5aac...` | Update member channel \| Use this surface to change a member communication or relationship setting. \| Private by default \| Membership scoped \| Ready \| Decision \| Decide what to save, what to change, and what status or next step should remain visible afterward. \| Details \| Membe... | domain-native-reviewed / domain-native | Ticket must add screenshot-backed visible text and a non-reusable critique for this exact screen. | App Shell top banner ad slot no-fill surface with preserved layout, disclosure/reserved space, and no content overlap |
| `b25-v4-row-135-platform-top-banner-no-fill-2` | Member Social Space | `platform-top-banner-no-fill` | member | B16_ext_platform_social_platform-top-banner-no-fill_complete | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B16/screenshots/B16_ext_platform_social_platform-top-banner-no-fill_complete.png` | `2a13a3cdc4395...` | Top banner status \| Member form captures labeled details, privacy choices, and reviewer handoff. \| Private by default \| Membership scoped \| Ready \| Decide what to save, what to change, and what status or next step should remain visible afterward. \| Edit response \| Setting save... | domain-native-reviewed / domain-native | Ticket must add screenshot-backed visible text and a non-reusable critique for this exact screen. | App Shell top banner ad slot no-fill surface with preserved layout, disclosure/reserved space, and no content overlap |
| `b25-v4-row-136-platform-sensitive-no-fill-0` | Member Social Space | `platform-sensitive-no-fill` | member | B16_ext_platform_social_platform-sensitive-no-fill_start | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B16/screenshots/B16_ext_platform_social_platform-sensitive-no-fill_start.png` | `50ced353386b3...` | Top banner status \| Member form captures labeled details, privacy choices, and reviewer handoff. \| Private by default \| Membership scoped \| Ready \| Decide what to save, what to change, and what status or next step should remain visible afterward. \| Edit response \| Setting save... | domain-native-reviewed / domain-native | Ticket must add screenshot-backed visible text and a non-reusable critique for this exact screen. | sensitive-context ad suppression surface with protected content visible and ad slot safely no-filled |
| `b25-v4-row-137-platform-sensitive-no-fill-1` | Member Social Space | `platform-sensitive-no-fill` | member | B16_ext_platform_social_platform-sensitive-no-fill_action | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B16/screenshots/B16_ext_platform_social_platform-sensitive-no-fill_action.png` | `205507b26eb8d...` | Submit member form \| Use this surface to submit structured member details. \| Labeled fields \| Privacy checked \| Review handoff \| Decision \| Decide what to save, what to change, and what status or next step should remain visible afterward. \| Details \| Required details are ready... | domain-native-reviewed / domain-native | Ticket must add screenshot-backed visible text and a non-reusable critique for this exact screen. | sensitive-context ad suppression surface with protected content visible and ad slot safely no-filled |
| `b25-v4-row-138-platform-sensitive-no-fill-2` | Member Social Space | `platform-sensitive-no-fill` | member | B16_ext_platform_social_platform-sensitive-no-fill_complete | `/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B16/screenshots/B16_ext_platform_social_platform-sensitive-no-fill_complete.png` | `2095a654eb9ce...` | Top banner status \| Member form captures labeled details, privacy choices, and reviewer handoff. \| Private by default \| Membership scoped \| Ready \| Decide what to save, what to change, and what status or next step should remain visible afterward. \| Edit response \| Setting save... | domain-native-reviewed / domain-native | Ticket must add screenshot-backed visible text and a non-reusable critique for this exact screen. | sensitive-context ad suppression surface with protected content visible and ad slot safely no-filled |

### Failing Workflow/Persona Scorecards

Showing 10 of 10 failing scorecards. Full detail is in the JSON ticket.

| Scorecard | Community | Workflow | Persona | Failed questions | Target surface |
| --- | --- | --- | --- | ---: | --- |
| `b25-wp-008-book-selection-publish-community-book-club-owner` | Neighborhood Book Club | `book-selection-publish` | owner | 2 | announcement feed/composer with audience, author, timestamp, body, and receiver state |
| `b25-wp-013-soccer-minor-redaction-community-youth-soccer-guardian` | Riverside Youth Soccer | `soccer-minor-redaction` | guardian | 2 | protected youth roster/profile surface with minor-data redaction, guardian visibility, and coach-only detail state |
| `b25-wp-015-soccer-practice-schedule-community-youth-soccer-guardian` | Riverside Youth Soccer | `soccer-practice-schedule` | guardian | 2 | event detail with schedule, location, capacity/status, RSVP action, and result state |
| `b25-wp-016-soccer-reminder-notification-community-youth-soccer-guardian` | Riverside Youth Soccer | `soccer-reminder-notification` | guardian | 2 | notification inbox/detail surface with sender, audience, timestamp, message body, and receiver state |
| `b25-wp-019-hoa-member-document-community-hoa-member` | Cedar Commons HOA | `hoa-member-document` | member | 2 | document library/detail surface with title, audience, file metadata, and access state |
| `b25-wp-023-hoa-owner-notification-community-hoa-owner` | Cedar Commons HOA | `hoa-owner-notification` | owner | 2 | notification inbox/detail surface with sender, audience, timestamp, message body, and receiver state |
| `b25-wp-025-mosque-announcement-community-mosque-owner` | Masjid Nur | `mosque-announcement` | owner | 2 | announcement feed/composer with audience, author, timestamp, body, and receiver state |
| `b25-wp-031-mosque-neutral-notification-community-mosque-member` | Masjid Nur | `mosque-neutral-notification` | member | 2 | notification inbox/detail surface with sender, audience, timestamp, message body, and receiver state |
| `b25-wp-045-platform-top-banner-no-fill-community-platform-social-member` | Member Social Space | `platform-top-banner-no-fill` | member | 2 | App Shell top banner ad slot no-fill surface with preserved layout, disclosure/reserved space, and no content overlap |
| `b25-wp-046-platform-sensitive-no-fill-community-platform-social-member` | Member Social Space | `platform-sensitive-no-fill` | member | 2 | sensitive-context ad suppression surface with protected content visible and ad slot safely no-filled |

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
- Screen row `b25-v4-row-046-soccer-reminder-notification-0` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-046-soccer-reminder-notification-0` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-046-soccer-reminder-notification-0` names visible UI elements, visible text, persona `guardian`, workflow `soccer-reminder-notification`, and the exact product UX issue.
- Primary surface for `soccer-reminder-notification` is documented as `notification inbox/detail surface with sender, audience, timestamp, message body, and receiver state` or another explicit domain-native surface.
- After-screenshot visible text proves every required semantic surface group for `soccer-reminder-notification`.
- Screen row `b25-v4-row-047-soccer-reminder-notification-1` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-047-soccer-reminder-notification-1` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-047-soccer-reminder-notification-1` names visible UI elements, visible text, persona `guardian`, workflow `soccer-reminder-notification`, and the exact product UX issue.
- Screen row `b25-v4-row-048-soccer-reminder-notification-2` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-048-soccer-reminder-notification-2` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-048-soccer-reminder-notification-2` names visible UI elements, visible text, persona `guardian`, workflow `soccer-reminder-notification`, and the exact product UX issue.
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

## B25-RT-008-b25-c09-no-layout-production-defects

| Field | Value |
| --- | --- |
| Severity | major |
| Priority | P1 |
| Status | open |
| Review run | `b25-v4-pass-10` |
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
| Is the UI modern, easy to use, easy to navigate, and visually appealing for the target persona? | holistic | 40 | 0 rows use non-screen visible text sources, 16 lifecycle scorecards fail, and 0 rows have visual/layout blockers, so the judge cannot make a reliable modern-UI claim. | Use screenshot-derived visible text, fix incomplete workflow lifecycles, and fix detected checklist, repeated-card, thin-content, or weak-identity visual blockers before rerunning the judge. |
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
