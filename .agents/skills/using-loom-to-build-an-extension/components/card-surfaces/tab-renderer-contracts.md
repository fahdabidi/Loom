# Per-Tab Renderer Contracts

Status: Draft normative component guide
Audience: Skill authors, extension builders, product designers, App Shell implementers

Per-tab renderer contracts define how render bindings select the product surface for a tab. A card
surface defines the domain interaction model; the complete set of bound `cardSurfaceFamily` values
derives the whole-tab renderer and the screenshot evidence needed for that surface to feel like a
modern app instead of a metadata view.

Use these contracts before designing screens. A generated extension should map every workflow to:

```text
workflow -> cardSurfaceFamily -> derived tab renderer -> fake backend evidence
```

## Contract Rules

- Home and Messages are required App Shell destinations.
- Omit `rendererContractId`; an explicit value overrides derivation and can pin the wrong renderer.
- A tab whose bindings all use `event-rsvp` derives `CalendarTabSurface`.
- A tab whose bindings all use `equipment-loan` derives `MarketplaceTabSurface`.
- Any mixed tab, or a tab bound to any other archetype, derives the engine-native generic list. This
  is the correct surface: it runs the live query and dispatches each instance to its own
  `cardSurfaceFamily` widget.
- Pinning policy is explicit and job-based. A tab can declare no pinned surface when the product doc
  explains why pinning would not help that role.
- Evidence must prove the derived renderer and per-instance dispatch. Screenshots should include the
  tab state, the surface detail, and the action/result state.

## Renderer Contract Matrix

| Derived renderer | Binding condition | Required product shape |
| --- | --- | --- | --- |
| `CalendarTabSurface` | Every binding uses `event-rsvp` | Month/week/date strip, agenda grouped by date, event detail, RSVP state, reminders. |
| `MarketplaceTabSurface` | Every binding uses `equipment-loan` | Browse/search/filter, listing cards, listing detail, current holder/queue, loan/giveaway actions. |
| Engine-native generic list | Mixed families or any other family | Live query plus per-instance dispatch to each binding's `cardSurfaceFamily` widget. |

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

## `discussionThread` On The Generic List

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
  [equipment-loan.md](./equipment-loan.md#marketplace-state-machine-model)) — role-gated via
  `allowedRoleIds` on each transition;
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

## `documentLibrary` On The Generic List

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

## `statusTimeline` On The Generic List

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

The derived renderer governs a tab's information architecture (anatomy, states, required
interactions); it does not govern color. Regardless of which renderer a tab derives, its card
surfaces resolve their visual style (fill, border, heading/body color, button styling) from the
same community -> tab -> workflow card theme cascade, so a `CalendarTabSurface` tab and a generic-list
tab can each declare a distinct accent (via `tabThemes`) while both stay
visually coherent with the community default. See
[Card Theme Cascade](./app-shell-navigation-theming.md#card-theme-cascade) for the JSON contract.

## Renderer Selection Guidance

1. Start with the user job and persona.
2. Pick the card-surface family that owns the domain interaction.
3. Bind the workflow to its tab and omit `rendererContractId`.
4. Let the complete set of bindings derive the calendar, marketplace, or generic-list renderer.
5. Treat the generic list as the correct mixed-archetype surface, not a fallback to avoid.
6. Add screenshot evidence for both the derived renderer and the workflow-specific action/result.

## Missing Renderer Signal

These are **hard product-spec failures** for any package-declared community — they must not ship:

- A tab declares `rendererContractId` instead of letting its bindings decide.
- A tab whose bindings are all `event-rsvp` does not derive calendar/agenda/event detail.
- A tab whose bindings are all `equipment-loan` does not derive browse/listing/detail.
- A mixed or other-archetype tab does not run the live query and dispatch each instance by
  `cardSurfaceFamily`.
- A binding omits or misstates the archetype that owns its instance UI.
