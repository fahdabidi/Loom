# Per-Tab Renderer Contracts

Status: Draft normative component guide
Audience: Skill authors, extension builders, product designers, App Shell implementers

Per-tab renderer contracts define the product surface that a tab must render. They sit above card
surface families. A card surface defines the domain interaction model; a tab renderer defines the
navigation context, layout anatomy, state model, and screenshot evidence needed for that surface to
feel like a modern app instead of a workflow list.

Use these contracts before designing screens. A generated extension should map every workflow to:

```text
workflow -> cardSurfaceFamily -> tabRendererContract -> renderer target -> fake backend evidence
```

## Contract Rules

- Home and Messages are required App Shell destinations.
- A tab must declare one renderer contract. The contract may render multiple card-surface families.
- Dedicated tabs must use tab-native information architecture: Calendar looks like calendar/agenda,
  Messages looks like inbox/thread/composer, Marketplace looks like browse/listing/detail, and
  Documents looks like a document library/detail/open surface.
- **Default vs. data-driven tabs:** Messages and Home render by default. Calendar gate-checks its
  own `calendarItem` data per workflow. Every other domain tab (Marketplace, Documents, Giving,
  Care, Admin, Payment, Volunteer) renders its full tab-native UI **only when its data is declared**
  under `experience` (e.g. `threads`, `marketplaceListings`, `givingPayment` fields on workflows).
  When no data is declared for that tab, it shows an explicit themed placeholder — "‹Tab› is coming
  to ‹community›" — never a generic mock. This replaces the earlier implicit assumption that a
  matching tab always fills with a generic renderer.
- Pinning policy is explicit and job-based. A tab can declare no pinned surface when the product doc
  explains why pinning would not help that persona.
- A workflow summary may appear on Home, but the primary task must route to the tab-native renderer
  when a dedicated tab exists.
- Evidence must prove the tab renderer, not just the card-surface family. Screenshots should include
  the tab state, the surface detail, and the action/result state.

## Renderer Contract Matrix

| Renderer contract | Tabs | Card-surface families | Required product shape |
| --- | --- | --- | --- |
| `HomeTabSurfaceStack` | Home | Community home, unassigned summaries, pinned or in-focus surfaces | Community identity, prioritized content, minimized/medium/expanded cards, tap-to-expanded detail. |
| `CalendarTabSurface` | Calendar | Calendar, Event RSVP, Member Meetup | Month/week/date strip, agenda grouped by date, event detail, RSVP/meetup state, reminders. |
| `MessagesTabSurface` | Messages | Discussion/message, Messaging/connections, Notification inbox | Inbox/thread list, unread state, conversation detail, composer, connection invites. |
| `MarketplaceTabSurface` | Marketplace | Equipment loan, Plant/item exchange | Browse/search/filter, listing cards, listing detail, current holder/queue, list item, loan/giveaway actions. |
| `DocumentsTabSurface` | Documents | Documents, external document links, operations, portability, workflow status | Library categories, document detail, embedded open, external open, versions/access/acknowledgement. |
| `WorkflowStatusSurface` | Home, Admin, Documents | Workflow status, approval, custom form, operations | Multi-step timeline, current step, owner/reviewer, feedback/payment/document actions, audit. |
| `PaymentGivingTabSurface` | Giving | Payment, dues, donations, ad-off | Amount/purpose, checkout, receipt, failure/retry, recurring plan, entitlement. |
| `CareVolunteerTabSurface` | Care | Care request, volunteer signup | Request/shift queue, protected/public data split, volunteer count/roster, assignment/check-in. |
| `AdminReviewComposeTabSurface` | Admin | Announcement, approval, ads, workflow status | Role task queue, composer/reviewer detail, preview/status/audit, approve/reject/request changes. |

## CalendarTabSurface

Use for dated community experiences: practices, services, photo walks, meetings, matches, deadlines,
reservations, recurring schedules, and reminders.

Required anatomy:

- month, week, or date strip;
- agenda list grouped by date;
- event/detail panel with title, date, time, location, host, capacity, and reminder state;
- linked workflow action area for RSVP, waitlist, meetup negotiation, reservation, or payment;
- empty and conflict states.

Required interactions:

- `CommunityCalendarSurfaceApi.listCalendarItems`
- `CommunityCalendarSurfaceApi.getCalendarItem`
- `CommunityCalendarSurfaceApi.openLinkedSurface`
- `CommunityEventRsvpApi.respondGoingMaybeNo`
- `CommunityEventRsvpApi.changeRsvp`
- `CommunityEventRsvpApi.cancelRsvp`
- `CommunityEventRsvpApi.joinWaitlist`
- `CommunityCalendarSurfaceApi.setReminder`

Evidence:

- calendar tab overview;
- selected event detail;
- response/change response state;
- reminder, waitlist, full, cancelled, or rescheduled state when applicable.

## MessagesTabSurface

Use for shell-owned communication and community-specific conversation experiences.

Required anatomy:

- inbox or thread list with sender, subject/body preview, timestamp, and unread state;
- thread detail with participants and chronological messages;
- composer with send/attachment affordances when permitted;
- connection invites, accept/decline/cancel, mute/archive/block state;
- empty inbox and unauthorized/read-only states.

Required interactions:

- `CommunityThreadApi.createThread`
- `CommunityThreadApi.reply`
- `CommunityThreadApi.markRead`
- `CommunityThreadApi.listUnread`
- `CommunityThreadApi.muteThread`
- `CommunityThreadApi.archiveThread`
- `CommunitySocialSurfaceApi.sendInvite`
- `CommunitySocialSurfaceApi.acceptInvite`
- `CommunitySocialSurfaceApi.declineInvite`
- `CommunitySocialSurfaceApi.connectionStatus`

Evidence:

- inbox/thread list;
- opened thread;
- composer/action;
- connection invite or muted/archived state.

## MarketplaceTabSurface

Use for any shareable object marketplace: cameras, lenses, sports gear, tools, books, DVDs, games,
garden plants, wine glasses, neighborhood library items, and giveaways.

Required anatomy:

- browse/search/filter header;
- **responsive listing grid** (LayoutBuilder-based: 2-up narrow, 3-up wide) with item image/icon,
  owner or policy-safe owner label, availability, and category;
- listing detail with description, condition, current holder or privacy-safe unavailable state, queue,
  due/return rules, pickup handoff, and custody history;
- list-your-item flow for create/modify/delist/pause/reactivate;
- **engine-derived action buttons** driven by the per-listing state machine (see
  [equipment-loan.md](./equipment-loan.md#marketplace-state-machine-model)) — persona-gated via
  `allowedPersonaIds` on each transition;
- loan, reserve, join queue, return, report issue, claim giveaway, buy, trade, or claim actions.

Required interactions:

- `CommunityEquipmentLoanApi.browseEquipment`
- `CommunityEquipmentLoanApi.searchEquipment`
- `CommunityEquipmentLoanApi.listEquipmentListing`
- `CommunityEquipmentLoanApi.updateEquipmentListing`
- `CommunityEquipmentLoanApi.removeEquipmentListing`
- `CommunityEquipmentLoanApi.requestLoan`
- `CommunityEquipmentLoanApi.joinLoanQueue`
- `CommunityEquipmentLoanApi.getCurrentHolder`
- `CommunityEquipmentLoanApi.listCustodyHistory`
- `CommunityEquipmentLoanApi.returnItem`
- `CommunityEquipmentLoanApi.claimGiveaway`
- `CommunityEquipmentLoanApi.transferGiveawayOwnership`

**Per-listing state-machine API:**

- `CommunityMarketplaceApi.listListings` — list with current state, persona-filtered.
- `CommunityMarketplaceApi.getListing` — single listing detail.
- `CommunityMarketplaceApi.listTransitions` — available transitions from the current persona.
- `CommunityMarketplaceApi.applyTransition` — apply a transition with effect flags, return updated state.
- `CommunityMarketplaceApi.listCustodyHistory` — existing custody/claim history.

Evidence:

- marketplace browse/search state;
- listing detail with engine-derived action buttons;
- persona-gating: organizer sees shared actions but member-only transitions are hidden;
- loan/giveaway/sale/trade action and result state;
- current holder, queue, return, or delisted state.

## DocumentsTabSurface

Use for document libraries, external links, PDFs, Google Docs, HTML pages, bylaws, receipts, exports,
facility policies, and audit records.

Required anatomy:

- library categories or folders;
- document detail with title, source, version, permissions, updated date, and audit/receipt state;
- embedded open action for in-app viewing where supported;
- external app/link action for Google Docs, browser, PDF viewer, or HTML pages;
- access request, acknowledgement, versions, retired/replaced, and offline/error states.

Required interactions:

- `CommunityDocumentSurfaceApi.listDocuments`
- `CommunityDocumentSurfaceApi.getDocumentDetail`
- `CommunityDocumentSurfaceApi.openEmbeddedDocument`
- `CommunityDocumentSurfaceApi.openExternalDocument`
- `CommunityDocumentSurfaceApi.downloadDocument`
- `CommunityDocumentSurfaceApi.acknowledgeDocument`
- `CommunityDocumentSurfaceApi.requestDocumentAccess`
- `CommunityDocumentSurfaceApi.listDocumentVersions`
- `CommunityDocumentSurfaceApi.documentAuditTrail`

Evidence:

- document library;
- document detail;
- embedded open or preview;
- external open or handoff proof;
- permission/request/acknowledgement state.

## WorkflowStatusSurface

Use for arbitrary or long-running workflows where the sequence of states can differ by community:
submitted, under review, feedback needed, payment needed, approval needed, scheduled, completed,
rejected, reopened, or cancelled.

Required anatomy:

- status timeline with current step, previous steps, and next expected step;
- owner/reviewer/receiver context;
- submitted details and attached documents;
- comments, payment needed, feedback needed, or approval decision modules;
- next actions and alternate paths such as request changes, cancel, reopen, appeal, retry payment.

Required interactions:

- `CommunityWorkflowStatusApi.createWorkflowInstance`
- `CommunityWorkflowStatusApi.getWorkflowStatus`
- `CommunityWorkflowStatusApi.listWorkflowSteps`
- `CommunityWorkflowStatusApi.transitionWorkflowStep`
- `CommunityWorkflowStatusApi.requestWorkflowChanges`
- `CommunityWorkflowStatusApi.approveWorkflowStep`
- `CommunityWorkflowStatusApi.rejectWorkflowStep`
- `CommunityWorkflowStatusApi.addWorkflowComment`
- `CommunityWorkflowStatusApi.attachWorkflowDocument`
- `CommunityWorkflowStatusApi.reopenWorkflow`

Evidence:

- submitted timeline;
- in-review or feedback-needed state;
- action/result state;
- receiver/notification state.

## Card Theme Cascade

A renderer contract governs a tab's information architecture (anatomy, states, required
interactions); it does not govern color. Regardless of which renderer contract a tab uses, its card
surfaces resolve their visual style (fill, border, heading/body color, button styling) from the
same community -> tab -> workflow card theme cascade, so a `CalendarTabSurface` tab and a
`PaymentGivingTabSurface` tab can each declare a distinct accent (via `tabThemes`) while both stay
visually coherent with the community default. See
[Card Theme Cascade](./app-shell-navigation-theming.md#card-theme-cascade) for the JSON contract.

## Renderer Selection Guidance

1. Start with the user job and persona.
2. Pick the card-surface family that owns the domain interaction.
3. Pick the tab renderer contract that owns the information architecture.
4. If a workflow can appear in multiple tabs, choose one primary renderer and use Home only for
   summary/pinned exposure.
5. If no renderer contract can represent the workflow without generic cards, create a new renderer
   contract before implementing UI.
6. Add screenshot evidence for both the tab-native renderer and the workflow-specific action/result.

## Missing Renderer Signal

These are **hard product-spec failures** for any package-declared community — they must not ship:

- Calendar tab renders only a workflow-card list instead of month/week/date strip + agenda + detail.
- Messages tab renders only an informational card instead of inbox/thread/composer.
- Marketplace tab renders only a workflow list instead of browse/search/filter + listing grid + detail.
- Documents tab has no library/detail/open affordance.
- Multi-step requests use a fixed approve/reject card when a status timeline is needed.
- Home is the only place a primary workflow can be completed despite a dedicated tab existing.
- A domain tab renders mock content (fake inbox, read-only search, hardcoded timeline) instead of either its declared data or an explicit themed placeholder.
