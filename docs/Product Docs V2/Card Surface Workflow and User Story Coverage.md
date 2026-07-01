# Card Surface Workflow and User Story Coverage

Status: Draft normative coverage map
Product area: Product Docs V2 supplement for Product 10 and Product 15
API spec: [Community Card Surfaces OpenAPI](../API/OpenAPI/community-surfaces/community-card-surfaces-api.openapi.yaml)

This document closes the product/API coverage gap for production card surfaces. Every interaction in the card-surface catalog is treated as a product workflow checkpoint, not merely as a backend operation. Generated extensions and native Loom surfaces must map selected card surfaces to these user stories, workflow stages, personas, permissions, fake backend fixtures, and B25 evidence before claiming production UX readiness.

## Coverage Rules

- Every selected card surface must have a concrete product story, not just a workflow label.
- Every OpenAPI operation listed below must be represented in the extension workflow map as an entry, action, alternate path, result, receiver state, recovery path, or audit/export state.
- The UI must expose the domain object, current state, available next actions, alternate/reversal actions, disabled/unauthorized behavior, and receiver/read-only state that correspond to the selected operations.
- Product Docs V2 is the native Loom source of truth. A standalone Skill run must create the same style of local community product doc in its working extension repository.
- B25 review cannot pass if a selected surface uses these APIs but lacks matching user-story/workflow evidence.

## Surface Story Summary

| Surface | API contract | Product user story | Required workflow coverage |
| --- | --- | --- | --- |
| Community card/home | `CommunityHomeSurfaceApi` | As a member, I can recognize, enter, and understand the current state of an installed community from a shell-owned home/card surface. | 8 interactions mapped below. |
| App Shell navigation/theming | `CommunityAppShellNavigationApi` | As a member or role-specific persona, I can use persona-specific tabs, pinned surfaces, card expansion, theme/customization knobs, and shell-owned Messages while Home remains available. | 24 interactions mapped below. |
| Announcement / publish | `CommunityAnnouncementApi` | As an admin, I can draft, preview, schedule, publish, revise, and inspect delivery/read state for a community announcement; as a member, I can receive and read it. | 11 interactions mapped below. |
| Calendar | `CommunityCalendarSurfaceApi` | As a member, I can browse schedule/agenda items, subscribe or import feeds, set reminders, and open the right linked workflow from calendar context. | 14 interactions mapped below. |
| Event / RSVP | `CommunityEventRsvpApi` | As an organizer, I can create and maintain a named event; as a member, I can respond going/maybe/no, change my response, join a waitlist, and see capacity/attendee state. | 12 interactions mapped below. |
| Member meetup scheduling | `CommunityMeetupApi` | As a member, I can propose, negotiate, accept, reschedule, or cancel a small-group meetup with visibility and reminder controls. | 10 interactions mapped below. |
| Volunteer signup | `CommunityVolunteerApi` | As a coordinator, I can publish shifts and manage rosters; as a member, I can sign up, update availability, cancel, and see appropriate volunteer count/roster state. | 12 interactions mapped below. |
| Shared item marketplace / loan / giveaway | `CommunityEquipmentLoanApi` | As a member, I can browse available community or member-owned items, list/modify/delist my item, request or reserve a loan, join a queue, see current holder/custody state where policy allows, return or report issues, or claim a giveaway with pickup, contact, return, and ownership state. | 39 interactions mapped below. |
| Plant exchange | `CommunityExchangeApi` | As a member, I can offer or claim an item, coordinate pickup, complete handoff, and protect contact details. | 10 interactions mapped below. |
| Book nomination | `CommunityNominationApi` | As a member, I can nominate, edit, withdraw, and track eligibility/ballot handoff for books or other candidates. | 8 interactions mapped below. |
| Vote / poll | `CommunityVoteApi` | As an organizer, I can open/close a ballot and publish results; as a member, I can cast, change, or clear a vote with privacy and audit protections. | 10 interactions mapped below. |
| Discussion / message | `CommunityThreadApi` | As a member, I can start, reply to, read, mute/archive, and manage a discussion while moderators can act on unsafe content. | 11 interactions mapped below. |
| Payments / dues / donations / ad-off | `CommunityPaymentSurfaceApi` | As a member, I can pay, retry, refund/manage recurring payments, and retrieve receipts/entitlements; as finance/admin, I can inspect settlement state. | 11 interactions mapped below. |
| Care / protected request | `CommunityCareRequestApi` | As a member, I can submit and track a protected care request; as care team/admin, I can review, assign, resolve, and audit with redaction. | 11 interactions mapped below. |
| Approval / request cards | `CommunityApprovalApi` | As a requester, I can submit, comment, reopen, or appeal; as a reviewer, I can approve, reject, request changes, and track status history. | 10 interactions mapped below. |
| Workflow status / case | `CommunityWorkflowStatusApi` | As a participant, I can follow and act on arbitrary multi-step workflows with status, reviewer, payment/document, feedback, and audit steps. | 15 interactions mapped below. |
| Documents | `CommunityDocumentSurfaceApi` | As a member, I can browse, open embedded or external documents, request access, acknowledge, inspect versions, and see document audit state. | 13 interactions mapped below. |
| External document links | `CommunityExternalDocumentApi` | As a member, I can safely open external documents in embedded or external-app mode with preview, access, fallback, and audit behavior. | 10 interactions mapped below. |
| Documents / facilities / roster | `CommunityOperationsSurfaceApi` | As a member/admin, I can access documents, acknowledge/download, request access, reserve facilities, resolve conflicts, and manage roster history. | 13 interactions mapped below. |
| Search / AI digest | `CommunityKnowledgeSurfaceApi` | As a member, I can search or ask questions over permitted community data, inspect citations, save/share digests, and see freshness/visibility decisions. | 9 interactions mapped below. |
| Export / import / transfer | `CommunityPortabilitySurfaceApi` | As an owner/admin, I can plan, redact, generate, download, verify, transfer, retry/cancel, rollback, and audit portability workflows. | 11 interactions mapped below. |
| Messaging / connections | `CommunitySocialSurfaceApi` | As a member, I can invite, accept/decline/cancel, block/unblock, mute/archive, and continue social threads with visible connection state. | 12 interactions mapped below. |
| Ads / no-fill / ad-off | `CommunityAdSurfaceApi` | As the shell/ad system, I can request and record ad decisions, explain no-fill, honor ad-off entitlements, and preserve receipt evidence. | 10 interactions mapped below. |
| Custom form submission | `CommunityFormSurfaceApi` | As a member, I can draft, validate, submit, update, withdraw, and export a custom form while protected fields route correctly. | 9 interactions mapped below. |
| Notification inbox | `CommunityInboxSurfaceApi` | As a member, I can inspect delivered items, mark read/unread, archive, mute sources, open source objects, manage preferences, and retry delivery when allowed. | 9 interactions mapped below. |

## Interaction Workflow Coverage

| Surface | Interaction | Workflow/user-story checkpoint | API operation |
| --- | --- | --- | --- |
| Community card/home | `getHomeSummary` | Inspect current state and decide next action. | `CommunityHomeSurfaceApi.getHomeSummary` |
| Community card/home | `listPinnedItems` | Inspect current state and decide next action. | `CommunityHomeSurfaceApi.listPinnedItems` |
| Community card/home | `getInstallState` | Inspect current state and decide next action. | `CommunityHomeSurfaceApi.getInstallState` |
| Community card/home | `getUnreadCounts` | Inspect current state and decide next action. | `CommunityHomeSurfaceApi.getUnreadCounts` |
| Community card/home | `getNextEvent` | Inspect current state and decide next action. | `CommunityHomeSurfaceApi.getNextEvent` |
| Community card/home | `getMembershipBadge` | Inspect current state and decide next action. | `CommunityHomeSurfaceApi.getMembershipBadge` |
| Community card/home | `resolveBranding` | Commit the action and expose result/receiver state. | `CommunityHomeSurfaceApi.resolveBranding` |
| Community card/home | `syncInstallStatus` | Workflow-specific state transition. | `CommunityHomeSurfaceApi.syncInstallStatus` |
| App Shell navigation/theming | `getTabConfiguration` | Inspect current community tabs and required Home/Messages destinations. | `CommunityAppShellNavigationApi.getTabConfiguration` |
| App Shell navigation/theming | `updateTabConfiguration` | Owner configures tab labels, order, icons, and visibility. | `CommunityAppShellNavigationApi.updateTabConfiguration` |
| App Shell navigation/theming | `assignSurfaceToTab` | Place a card surface in the right community tab. | `CommunityAppShellNavigationApi.assignSurfaceToTab` |
| App Shell navigation/theming | `pinSurface` | Keep an important card surface visible in a tab. | `CommunityAppShellNavigationApi.pinSurface` |
| App Shell navigation/theming | `unpinSurface` | Remove a pinned surface when it is no longer critical. | `CommunityAppShellNavigationApi.unpinSurface` |
| App Shell navigation/theming | `setSurfacePresentationState` | Move a surface between minimized, medium/in-focus, and expanded states. | `CommunityAppShellNavigationApi.setSurfacePresentationState` |
| App Shell navigation/theming | `persistSurfaceFocusState` | Preserve scroll/focus state across app resumes and tab switches. | `CommunityAppShellNavigationApi.persistSurfaceFocusState` |
| App Shell navigation/theming | `resolveCommunityTheme` | Apply community title/detail/surface/edit/button typography and colors. | `CommunityAppShellNavigationApi.resolveCommunityTheme` |
| App Shell navigation/theming | `updateCommunityTheme` | Owner updates theme tokens within shell/accessibility constraints. | `CommunityAppShellNavigationApi.updateCommunityTheme` |
| App Shell navigation/theming | `validateThemeContrast` | Prevent inaccessible or unreadable theme combinations. | `CommunityAppShellNavigationApi.validateThemeContrast` |
| App Shell navigation/theming | `getMessagesTabState` | Inspect required communication tab unread/thread state. | `CommunityAppShellNavigationApi.getMessagesTabState` |
| App Shell navigation/theming | `openMessagesTab` | Open the shell-owned communication experience from bottom navigation. | `CommunityAppShellNavigationApi.openMessagesTab` |
| App Shell navigation/theming | `getPersonaTabConfiguration` | Inspect a persona-specific tab configuration, including labels, order, visibility, pins, and assigned surfaces. | `CommunityAppShellNavigationApi.getPersonaTabConfiguration` |
| App Shell navigation/theming | `updatePersonaTabConfiguration` | Owner/admin configures tabs for a role, persona, or persona group. | `CommunityAppShellNavigationApi.updatePersonaTabConfiguration` |
| App Shell navigation/theming | `resolvePersonaTabs` | Resolve effective tabs after permissions, hidden/disabled policy, Home defaults, and Messages requirements. | `CommunityAppShellNavigationApi.resolvePersonaTabs` |
| App Shell navigation/theming | `assignSurfaceToPersonaTab` | Place a card surface in a persona-specific tab without leaking restricted content to other personas. | `CommunityAppShellNavigationApi.assignSurfaceToPersonaTab` |
| App Shell navigation/theming | `pinSurfaceForPersona` | Keep an important surface visible for the persona and tab where that task is critical. | `CommunityAppShellNavigationApi.pinSurfaceForPersona` |
| App Shell navigation/theming | `unpinSurfaceForPersona` | Remove persona-specific pinned state when priorities change. | `CommunityAppShellNavigationApi.unpinSurfaceForPersona` |
| App Shell navigation/theming | `getCustomizationKnobs` | Inspect theme, typography, spacing, density, card, tab, and surface presentation knobs. | `CommunityAppShellNavigationApi.getCustomizationKnobs` |
| App Shell navigation/theming | `updateCustomizationKnobs` | Update safe customization knobs within shell accessibility and required-control bounds. | `CommunityAppShellNavigationApi.updateCustomizationKnobs` |
| App Shell navigation/theming | `previewNavigationConfiguration` | Preview a persona's tabs, pins, theme, typography, and presentation before publishing. | `CommunityAppShellNavigationApi.previewNavigationConfiguration` |
| App Shell navigation/theming | `validatePersonaNavigation` | Validate persona tabs against required Home/Messages, permissions, accessibility, and hidden/disabled rules. | `CommunityAppShellNavigationApi.validatePersonaNavigation` |
| App Shell navigation/theming | `getPersonaSurfacePresentationState` | Inspect minimized, medium/in-focus, expanded, pinned, and scroll-focus state for a persona. | `CommunityAppShellNavigationApi.getPersonaSurfacePresentationState` |
| App Shell navigation/theming | `updatePersonaSurfacePresentationState` | Persist persona-specific minimized, medium/in-focus, expanded, pinned, and scroll-focus state. | `CommunityAppShellNavigationApi.updatePersonaSurfacePresentationState` |
| Announcement / publish | `createDraft` | Start or draft the workflow. | `CommunityAnnouncementApi.createDraft` |
| Announcement / publish | `updateDraft` | Modify, configure, or continue the workflow. | `CommunityAnnouncementApi.updateDraft` |
| Announcement / publish | `previewAnnouncement` | Workflow-specific state transition. | `CommunityAnnouncementApi.previewAnnouncement` |
| Announcement / publish | `scheduleAnnouncement` | Workflow-specific state transition. | `CommunityAnnouncementApi.scheduleAnnouncement` |
| Announcement / publish | `publishAnnouncement` | Commit the action and expose result/receiver state. | `CommunityAnnouncementApi.publishAnnouncement` |
| Announcement / publish | `cancelScheduledAnnouncement` | Alternate, reversal, or safety branch. | `CommunityAnnouncementApi.cancelScheduledAnnouncement` |
| Announcement / publish | `updatePublishedAnnouncement` | Modify, configure, or continue the workflow. | `CommunityAnnouncementApi.updatePublishedAnnouncement` |
| Announcement / publish | `unpublishAnnouncement` | Alternate, reversal, or safety branch. | `CommunityAnnouncementApi.unpublishAnnouncement` |
| Announcement / publish | `deliveryStatus` | Inspect current state and decide next action. | `CommunityAnnouncementApi.deliveryStatus` |
| Announcement / publish | `readReceipts` | Inspect current state and decide next action. | `CommunityAnnouncementApi.readReceipts` |
| Announcement / publish | `revisionHistory` | Workflow-specific state transition. | `CommunityAnnouncementApi.revisionHistory` |
| Calendar | `listCalendarItems` | Browse agenda/month/list schedule items. | `CommunityCalendarSurfaceApi.listCalendarItems` |
| Calendar | `getCalendarItem` | Inspect a specific calendar item and linked workflow. | `CommunityCalendarSurfaceApi.getCalendarItem` |
| Calendar | `createCalendarItem` | Organizer creates a dated item. | `CommunityCalendarSurfaceApi.createCalendarItem` |
| Calendar | `updateCalendarItem` | Organizer edits title/time/location/visibility. | `CommunityCalendarSurfaceApi.updateCalendarItem` |
| Calendar | `cancelCalendarItem` | Organizer cancels an item and notifies receivers. | `CommunityCalendarSurfaceApi.cancelCalendarItem` |
| Calendar | `rescheduleCalendarItem` | Organizer moves an item and preserves history/reminders. | `CommunityCalendarSurfaceApi.rescheduleCalendarItem` |
| Calendar | `createRecurringSchedule` | Create recurring practices, meetings, services, classes, or deadlines. | `CommunityCalendarSurfaceApi.createRecurringSchedule` |
| Calendar | `subscribeCalendarFeed` | Member subscribes to filtered community calendar feed. | `CommunityCalendarSurfaceApi.subscribeCalendarFeed` |
| Calendar | `importIcsFeed` | Owner imports existing calendar data. | `CommunityCalendarSurfaceApi.importIcsFeed` |
| Calendar | `exportCalendarFeed` | Owner/member exports allowed calendar data. | `CommunityCalendarSurfaceApi.exportCalendarFeed` |
| Calendar | `syncExternalCalendar` | Sync external calendar source and report conflicts/errors. | `CommunityCalendarSurfaceApi.syncExternalCalendar` |
| Calendar | `detectCalendarConflicts` | Show scheduling conflicts before commit. | `CommunityCalendarSurfaceApi.detectCalendarConflicts` |
| Calendar | `setReminder` | Member sets or changes reminder state. | `CommunityCalendarSurfaceApi.setReminder` |
| Calendar | `openLinkedSurface` | Continue into RSVP, reservation, payment, document, or workflow status. | `CommunityCalendarSurfaceApi.openLinkedSurface` |
| Event / RSVP | `createEvent` | Start or draft the workflow. | `CommunityEventRsvpApi.createEvent` |
| Event / RSVP | `updateEvent` | Modify, configure, or continue the workflow. | `CommunityEventRsvpApi.updateEvent` |
| Event / RSVP | `cancelEvent` | Alternate, reversal, or safety branch. | `CommunityEventRsvpApi.cancelEvent` |
| Event / RSVP | `rescheduleEvent` | Modify, configure, or continue the workflow. | `CommunityEventRsvpApi.rescheduleEvent` |
| Event / RSVP | `getEventDetail` | Inspect current state and decide next action. | `CommunityEventRsvpApi.getEventDetail` |
| Event / RSVP | `respondGoingMaybeNo` | Workflow-specific state transition. | `CommunityEventRsvpApi.respondGoingMaybeNo` |
| Event / RSVP | `changeRsvp` | Modify, configure, or continue the workflow. | `CommunityEventRsvpApi.changeRsvp` |
| Event / RSVP | `cancelRsvp` | Alternate, reversal, or safety branch. | `CommunityEventRsvpApi.cancelRsvp` |
| Event / RSVP | `joinWaitlist` | Commit the action and expose result/receiver state. | `CommunityEventRsvpApi.joinWaitlist` |
| Event / RSVP | `listAttendees` | Inspect current state and decide next action. | `CommunityEventRsvpApi.listAttendees` |
| Event / RSVP | `deliveryReminders` | Inspect current state and decide next action. | `CommunityEventRsvpApi.deliveryReminders` |
| Event / RSVP | `calendarState` | Inspect current state and decide next action. | `CommunityEventRsvpApi.calendarState` |
| Member meetup scheduling | `proposeMeetup` | Start or draft the workflow. | `CommunityMeetupApi.proposeMeetup` |
| Member meetup scheduling | `suggestSlots` | Workflow-specific state transition. | `CommunityMeetupApi.suggestSlots` |
| Member meetup scheduling | `counterPropose` | Modify, configure, or continue the workflow. | `CommunityMeetupApi.counterPropose` |
| Member meetup scheduling | `acceptMeetup` | Workflow-specific state transition. | `CommunityMeetupApi.acceptMeetup` |
| Member meetup scheduling | `declineMeetup` | Alternate, reversal, or safety branch. | `CommunityMeetupApi.declineMeetup` |
| Member meetup scheduling | `cancelMeetup` | Alternate, reversal, or safety branch. | `CommunityMeetupApi.cancelMeetup` |
| Member meetup scheduling | `rescheduleMeetup` | Modify, configure, or continue the workflow. | `CommunityMeetupApi.rescheduleMeetup` |
| Member meetup scheduling | `listParticipants` | Inspect current state and decide next action. | `CommunityMeetupApi.listParticipants` |
| Member meetup scheduling | `setVisibility` | Modify, configure, or continue the workflow. | `CommunityMeetupApi.setVisibility` |
| Member meetup scheduling | `sendReminder` | Workflow-specific state transition. | `CommunityMeetupApi.sendReminder` |
| Volunteer signup | `createShift` | Start or draft the workflow. | `CommunityVolunteerApi.createShift` |
| Volunteer signup | `updateShift` | Modify, configure, or continue the workflow. | `CommunityVolunteerApi.updateShift` |
| Volunteer signup | `listShifts` | Inspect current state and decide next action. | `CommunityVolunteerApi.listShifts` |
| Volunteer signup | `signup` | Commit the action and expose result/receiver state. | `CommunityVolunteerApi.signup` |
| Volunteer signup | `updateAvailability` | Modify, configure, or continue the workflow. | `CommunityVolunteerApi.updateAvailability` |
| Volunteer signup | `cancelSignup` | Alternate, reversal, or safety branch. | `CommunityVolunteerApi.cancelSignup` |
| Volunteer signup | `listVolunteers` | Inspect current state and decide next action. | `CommunityVolunteerApi.listVolunteers` |
| Volunteer signup | `volunteerSummary` | Inspect current state and decide next action. | `CommunityVolunteerApi.volunteerSummary` |
| Volunteer signup | `protectedContactReveal` | Workflow-specific state transition. | `CommunityVolunteerApi.protectedContactReveal` |
| Volunteer signup | `assignCoordinator` | Commit the action and expose result/receiver state. | `CommunityVolunteerApi.assignCoordinator` |
| Volunteer signup | `checkIn` | Inspect current state and decide next action. | `CommunityVolunteerApi.checkIn` |
| Volunteer signup | `markNoShow` | Commit the action and expose result/receiver state. | `CommunityVolunteerApi.markNoShow` |
| Shared item marketplace / loan / giveaway | `browseEquipment` | Browse available lendable, reservable, queued, or giveaway items by category, availability, owner, condition, and location. | `CommunityEquipmentLoanApi.browseEquipment` |
| Shared item marketplace / loan / giveaway | `searchEquipment` | Search/filter community-owned and member-owned item libraries. | `CommunityEquipmentLoanApi.searchEquipment` |
| Shared item marketplace / loan / giveaway | `getEquipmentDetail` | Inspect item photos, condition, owner/steward, pickup, use policy, current holder, queue, and availability. | `CommunityEquipmentLoanApi.getEquipmentDetail` |
| Shared item marketplace / loan / giveaway | `listEquipmentListing` | Inspect listings owned, borrowed, held, queued for, or moderated by the current persona. | `CommunityEquipmentLoanApi.listEquipmentListing` |
| Shared item marketplace / loan / giveaway | `createEquipmentListing` | Member/steward lists an item for loan, reservation, queue, or giveaway. | `CommunityEquipmentLoanApi.createEquipmentListing` |
| Shared item marketplace / loan / giveaway | `updateEquipmentListing` | Edit item details, photos, availability, rules, condition, owner notes, or giveaway mode. | `CommunityEquipmentLoanApi.updateEquipmentListing` |
| Shared item marketplace / loan / giveaway | `removeEquipmentListing` | Delist or retire an item from browse/search when policy allows. | `CommunityEquipmentLoanApi.removeEquipmentListing` |
| Shared item marketplace / loan / giveaway | `pauseEquipmentListing` | Temporarily hide or pause an item without deleting custody/history. | `CommunityEquipmentLoanApi.pauseEquipmentListing` |
| Shared item marketplace / loan / giveaway | `reactivateEquipmentListing` | Restore a paused item to discovery and availability. | `CommunityEquipmentLoanApi.reactivateEquipmentListing` |
| Shared item marketplace / loan / giveaway | `updateAvailability` | Update availability calendar, loan windows, blocked dates, queue policy, or pickup constraints. | `CommunityEquipmentLoanApi.updateAvailability` |
| Shared item marketplace / loan / giveaway | `offerEquipment` | Publish or renew an item available for loan. | `CommunityEquipmentLoanApi.offerEquipment` |
| Shared item marketplace / loan / giveaway | `offerGiveaway` | Publish an item that can be permanently claimed. | `CommunityEquipmentLoanApi.offerGiveaway` |
| Shared item marketplace / loan / giveaway | `claimGiveaway` | Claim a free/giveaway item and expose pickup/ownership-transfer state. | `CommunityEquipmentLoanApi.claimGiveaway` |
| Shared item marketplace / loan / giveaway | `requestLoan` | Borrower requests a specific item and pickup/return window. | `CommunityEquipmentLoanApi.requestLoan` |
| Shared item marketplace / loan / giveaway | `reserveLoan` | Reserve an available loan slot before approval/check-out. | `CommunityEquipmentLoanApi.reserveLoan` |
| Shared item marketplace / loan / giveaway | `approveLoan` | Lender/steward approves request and notifies borrower. | `CommunityEquipmentLoanApi.approveLoan` |
| Shared item marketplace / loan / giveaway | `declineLoan` | Lender/steward rejects request with reason/alternate path. | `CommunityEquipmentLoanApi.declineLoan` |
| Shared item marketplace / loan / giveaway | `joinLoanQueue` | Borrower joins a waitlist/hold queue for an unavailable item. | `CommunityEquipmentLoanApi.joinLoanQueue` |
| Shared item marketplace / loan / giveaway | `leaveLoanQueue` | Borrower leaves the queue or cancels their hold. | `CommunityEquipmentLoanApi.leaveLoanQueue` |
| Shared item marketplace / loan / giveaway | `listLoanQueue` | Owner/steward or eligible member inspects queue position and next borrower. | `CommunityEquipmentLoanApi.listLoanQueue` |
| Shared item marketplace / loan / giveaway | `advanceLoanQueue` | Steward advances the queue when an item is returned, declined, or expires. | `CommunityEquipmentLoanApi.advanceLoanQueue` |
| Shared item marketplace / loan / giveaway | `schedulePickup` | Coordinate pickup/return timing and safe contact handoff. | `CommunityEquipmentLoanApi.schedulePickup` |
| Shared item marketplace / loan / giveaway | `checkOut` | Mark loaned item checked out to borrower/current holder. | `CommunityEquipmentLoanApi.checkOut` |
| Shared item marketplace / loan / giveaway | `getCurrentHolder` | Show who currently has the item where policy allows, or show a privacy-safe held/unavailable state. | `CommunityEquipmentLoanApi.getCurrentHolder` |
| Shared item marketplace / loan / giveaway | `transferCustody` | Transfer custody between steward, lender, borrower, or next queue participant. | `CommunityEquipmentLoanApi.transferCustody` |
| Shared item marketplace / loan / giveaway | `listCustodyHistory` | Inspect checkout, transfer, return, damage, loss, and ownership history. | `CommunityEquipmentLoanApi.listCustodyHistory` |
| Shared item marketplace / loan / giveaway | `recordConditionCheck` | Record condition/photos/checklist at listing, checkout, return, damage, or dispute. | `CommunityEquipmentLoanApi.recordConditionCheck` |
| Shared item marketplace / loan / giveaway | `extendLoan` | Borrower requests or receives extended due date. | `CommunityEquipmentLoanApi.extendLoan` |
| Shared item marketplace / loan / giveaway | `returnItem` | Mark item returned and close loan or advance queue. | `CommunityEquipmentLoanApi.returnItem` |
| Shared item marketplace / loan / giveaway | `sendReturnReminder` | Notify borrower/current holder about due or overdue return. | `CommunityEquipmentLoanApi.sendReturnReminder` |
| Shared item marketplace / loan / giveaway | `reportOverdue` | Mark a loan overdue and expose next steps/escalation. | `CommunityEquipmentLoanApi.reportOverdue` |
| Shared item marketplace / loan / giveaway | `markDamaged` | Report damage, dispute, maintenance, or replacement need. | `CommunityEquipmentLoanApi.markDamaged` |
| Shared item marketplace / loan / giveaway | `reportLostItem` | Report item lost and route replacement/dispute/closure. | `CommunityEquipmentLoanApi.reportLostItem` |
| Shared item marketplace / loan / giveaway | `resolveLoanDispute` | Resolve damage/loss/overdue/dispute with audit and notifications. | `CommunityEquipmentLoanApi.resolveLoanDispute` |
| Shared item marketplace / loan / giveaway | `cancelLoan` | Cancel request/reservation/loan where policy allows. | `CommunityEquipmentLoanApi.cancelLoan` |
| Shared item marketplace / loan / giveaway | `listAvailability` | Inspect availability calendar and waitlist. | `CommunityEquipmentLoanApi.listAvailability` |
| Shared item marketplace / loan / giveaway | `listBorrowers` | Show borrower/claim roster subject to privacy policy. | `CommunityEquipmentLoanApi.listBorrowers` |
| Shared item marketplace / loan / giveaway | `privacyScopedContact` | Reveal contact only after policy-approved claim/loan step. | `CommunityEquipmentLoanApi.privacyScopedContact` |
| Shared item marketplace / loan / giveaway | `transferGiveawayOwnership` | Mark giveaway as transferred and close listing. | `CommunityEquipmentLoanApi.transferGiveawayOwnership` |
| Plant exchange | `createOffer` | Start or draft the workflow. | `CommunityExchangeApi.createOffer` |
| Plant exchange | `updateOffer` | Modify, configure, or continue the workflow. | `CommunityExchangeApi.updateOffer` |
| Plant exchange | `cancelOffer` | Alternate, reversal, or safety branch. | `CommunityExchangeApi.cancelOffer` |
| Plant exchange | `claimOffer` | Workflow-specific state transition. | `CommunityExchangeApi.claimOffer` |
| Plant exchange | `cancelClaim` | Alternate, reversal, or safety branch. | `CommunityExchangeApi.cancelClaim` |
| Plant exchange | `markUnavailable` | Commit the action and expose result/receiver state. | `CommunityExchangeApi.markUnavailable` |
| Plant exchange | `schedulePickup` | Workflow-specific state transition. | `CommunityExchangeApi.schedulePickup` |
| Plant exchange | `handoffComplete` | Commit the action and expose result/receiver state. | `CommunityExchangeApi.handoffComplete` |
| Plant exchange | `listClaims` | Inspect current state and decide next action. | `CommunityExchangeApi.listClaims` |
| Plant exchange | `privacyScopedContact` | Workflow-specific state transition. | `CommunityExchangeApi.privacyScopedContact` |
| Book nomination | `createNomination` | Start or draft the workflow. | `CommunityNominationApi.createNomination` |
| Book nomination | `updateNomination` | Modify, configure, or continue the workflow. | `CommunityNominationApi.updateNomination` |
| Book nomination | `withdrawNomination` | Alternate, reversal, or safety branch. | `CommunityNominationApi.withdrawNomination` |
| Book nomination | `listNominations` | Inspect current state and decide next action. | `CommunityNominationApi.listNominations` |
| Book nomination | `detectDuplicate` | Inspect current state and decide next action. | `CommunityNominationApi.detectDuplicate` |
| Book nomination | `checkEligibility` | Inspect current state and decide next action. | `CommunityNominationApi.checkEligibility` |
| Book nomination | `linkToBallot` | Workflow-specific state transition. | `CommunityNominationApi.linkToBallot` |
| Book nomination | `nominationStatus` | Inspect current state and decide next action. | `CommunityNominationApi.nominationStatus` |
| Vote / poll | `openBallot` | Inspect current state and decide next action. | `CommunityVoteApi.openBallot` |
| Vote / poll | `closeBallot` | Workflow-specific state transition. | `CommunityVoteApi.closeBallot` |
| Vote / poll | `castVote` | Commit the action and expose result/receiver state. | `CommunityVoteApi.castVote` |
| Vote / poll | `changeVote` | Modify, configure, or continue the workflow. | `CommunityVoteApi.changeVote` |
| Vote / poll | `clearVote` | Alternate, reversal, or safety branch. | `CommunityVoteApi.clearVote` |
| Vote / poll | `getVoteState` | Inspect current state and decide next action. | `CommunityVoteApi.getVoteState` |
| Vote / poll | `getResults` | Inspect current state and decide next action. | `CommunityVoteApi.getResults` |
| Vote / poll | `resolveTie` | Commit the action and expose result/receiver state. | `CommunityVoteApi.resolveTie` |
| Vote / poll | `publishSelection` | Commit the action and expose result/receiver state. | `CommunityVoteApi.publishSelection` |
| Vote / poll | `auditVote` | Inspect current state and decide next action. | `CommunityVoteApi.auditVote` |
| Discussion / message | `createThread` | Start or draft the workflow. | `CommunityThreadApi.createThread` |
| Discussion / message | `reply` | Workflow-specific state transition. | `CommunityThreadApi.reply` |
| Discussion / message | `editMessage` | Workflow-specific state transition. | `CommunityThreadApi.editMessage` |
| Discussion / message | `deleteMessage` | Workflow-specific state transition. | `CommunityThreadApi.deleteMessage` |
| Discussion / message | `markRead` | Commit the action and expose result/receiver state. | `CommunityThreadApi.markRead` |
| Discussion / message | `listUnread` | Inspect current state and decide next action. | `CommunityThreadApi.listUnread` |
| Discussion / message | `muteThread` | Alternate, reversal, or safety branch. | `CommunityThreadApi.muteThread` |
| Discussion / message | `archiveThread` | Alternate, reversal, or safety branch. | `CommunityThreadApi.archiveThread` |
| Discussion / message | `moderateMessage` | Workflow-specific state transition. | `CommunityThreadApi.moderateMessage` |
| Discussion / message | `attachMedia` | Workflow-specific state transition. | `CommunityThreadApi.attachMedia` |
| Discussion / message | `mentionMember` | Workflow-specific state transition. | `CommunityThreadApi.mentionMember` |
| Payments / dues / donations / ad-off | `createPaymentIntent` | Start or draft the workflow. | `CommunityPaymentSurfaceApi.createPaymentIntent` |
| Payments / dues / donations / ad-off | `confirmPayment` | Commit the action and expose result/receiver state. | `CommunityPaymentSurfaceApi.confirmPayment` |
| Payments / dues / donations / ad-off | `recordFailure` | Commit the action and expose result/receiver state. | `CommunityPaymentSurfaceApi.recordFailure` |
| Payments / dues / donations / ad-off | `retryPayment` | Commit the action and expose result/receiver state. | `CommunityPaymentSurfaceApi.retryPayment` |
| Payments / dues / donations / ad-off | `refund` | Commit the action and expose result/receiver state. | `CommunityPaymentSurfaceApi.refund` |
| Payments / dues / donations / ad-off | `createRecurringPlan` | Start or draft the workflow. | `CommunityPaymentSurfaceApi.createRecurringPlan` |
| Payments / dues / donations / ad-off | `manageRecurringPlan` | Modify, configure, or continue the workflow. | `CommunityPaymentSurfaceApi.manageRecurringPlan` |
| Payments / dues / donations / ad-off | `setDonorVisibility` | Modify, configure, or continue the workflow. | `CommunityPaymentSurfaceApi.setDonorVisibility` |
| Payments / dues / donations / ad-off | `getReceipt` | Inspect current state and decide next action. | `CommunityPaymentSurfaceApi.getReceipt` |
| Payments / dues / donations / ad-off | `getEntitlement` | Inspect current state and decide next action. | `CommunityPaymentSurfaceApi.getEntitlement` |
| Payments / dues / donations / ad-off | `settlementStatus` | Modify, configure, or continue the workflow. | `CommunityPaymentSurfaceApi.settlementStatus` |
| Care / protected request | `createRequest` | Start or draft the workflow. | `CommunityCareRequestApi.createRequest` |
| Care / protected request | `updateRequest` | Modify, configure, or continue the workflow. | `CommunityCareRequestApi.updateRequest` |
| Care / protected request | `withdrawRequest` | Alternate, reversal, or safety branch. | `CommunityCareRequestApi.withdrawRequest` |
| Care / protected request | `assignCareTeam` | Commit the action and expose result/receiver state. | `CommunityCareRequestApi.assignCareTeam` |
| Care / protected request | `reviewRequest` | Commit the action and expose result/receiver state. | `CommunityCareRequestApi.reviewRequest` |
| Care / protected request | `requestChanges` | Start or draft the workflow. | `CommunityCareRequestApi.requestChanges` |
| Care / protected request | `resolveRequest` | Commit the action and expose result/receiver state. | `CommunityCareRequestApi.resolveRequest` |
| Care / protected request | `neutralNotification` | Workflow-specific state transition. | `CommunityCareRequestApi.neutralNotification` |
| Care / protected request | `readPublicSummary` | Inspect current state and decide next action. | `CommunityCareRequestApi.readPublicSummary` |
| Care / protected request | `readProtectedDetails` | Inspect current state and decide next action. | `CommunityCareRequestApi.readProtectedDetails` |
| Care / protected request | `redactedAudit` | Workflow-specific state transition. | `CommunityCareRequestApi.redactedAudit` |
| Approval / request cards | `submitRequest` | Start or draft the workflow. | `CommunityApprovalApi.submitRequest` |
| Approval / request cards | `assignReviewer` | Commit the action and expose result/receiver state. | `CommunityApprovalApi.assignReviewer` |
| Approval / request cards | `approve` | Commit the action and expose result/receiver state. | `CommunityApprovalApi.approve` |
| Approval / request cards | `reject` | Alternate, reversal, or safety branch. | `CommunityApprovalApi.reject` |
| Approval / request cards | `requestChanges` | Start or draft the workflow. | `CommunityApprovalApi.requestChanges` |
| Approval / request cards | `comment` | Workflow-specific state transition. | `CommunityApprovalApi.comment` |
| Approval / request cards | `statusHistory` | Inspect current state and decide next action. | `CommunityApprovalApi.statusHistory` |
| Approval / request cards | `reopen` | Workflow-specific state transition. | `CommunityApprovalApi.reopen` |
| Approval / request cards | `appeal` | Workflow-specific state transition. | `CommunityApprovalApi.appeal` |
| Approval / request cards | `notifyRequester` | Workflow-specific state transition. | `CommunityApprovalApi.notifyRequester` |
| Workflow status / case | `createWorkflowInstance` | Start a configured multi-step workflow/case. | `CommunityWorkflowStatusApi.createWorkflowInstance` |
| Workflow status / case | `getWorkflowStatus` | Show current status, current step, due dates, and next action. | `CommunityWorkflowStatusApi.getWorkflowStatus` |
| Workflow status / case | `listWorkflowSteps` | Inspect full submitted/under-review/feedback/approval/payment/completed timeline. | `CommunityWorkflowStatusApi.listWorkflowSteps` |
| Workflow status / case | `transitionWorkflowStep` | Move workflow to next/alternate status. | `CommunityWorkflowStatusApi.transitionWorkflowStep` |
| Workflow status / case | `assignWorkflowReviewer` | Assign reviewer/committee/care team/coordinator. | `CommunityWorkflowStatusApi.assignWorkflowReviewer` |
| Workflow status / case | `requestWorkflowChanges` | Ask requester for feedback or corrections. | `CommunityWorkflowStatusApi.requestWorkflowChanges` |
| Workflow status / case | `approveWorkflowStep` | Approve a step and expose receiver state. | `CommunityWorkflowStatusApi.approveWorkflowStep` |
| Workflow status / case | `rejectWorkflowStep` | Reject/deny with reason, appeal, or reopen path. | `CommunityWorkflowStatusApi.rejectWorkflowStep` |
| Workflow status / case | `addWorkflowComment` | Add threaded comment or reviewer note. | `CommunityWorkflowStatusApi.addWorkflowComment` |
| Workflow status / case | `attachWorkflowDocument` | Attach or link supporting document. | `CommunityWorkflowStatusApi.attachWorkflowDocument` |
| Workflow status / case | `recordWorkflowPaymentNeeded` | Add payment-needed checkpoint and handoff to payment surface. | `CommunityWorkflowStatusApi.recordWorkflowPaymentNeeded` |
| Workflow status / case | `notifyWorkflowParticipants` | Notify actor/receiver/reviewer about status change. | `CommunityWorkflowStatusApi.notifyWorkflowParticipants` |
| Workflow status / case | `reopenWorkflow` | Reopen a completed/rejected case where policy allows. | `CommunityWorkflowStatusApi.reopenWorkflow` |
| Workflow status / case | `cancelWorkflow` | Cancel request/case and preserve audit/history. | `CommunityWorkflowStatusApi.cancelWorkflow` |
| Workflow status / case | `workflowAuditTrail` | Inspect immutable workflow history and receipts. | `CommunityWorkflowStatusApi.workflowAuditTrail` |
| Documents | `listDocuments` | Browse document library by category/access/state. | `CommunityDocumentSurfaceApi.listDocuments` |
| Documents | `getDocumentDetail` | Inspect title, type, owner, version, access, and required acknowledgement. | `CommunityDocumentSurfaceApi.getDocumentDetail` |
| Documents | `openEmbeddedDocument` | Open allowed document in embedded Chrome-tab/WebView style. | `CommunityDocumentSurfaceApi.openEmbeddedDocument` |
| Documents | `openExternalDocument` | Launch document in external app/browser/provider. | `CommunityDocumentSurfaceApi.openExternalDocument` |
| Documents | `downloadDocument` | Download/copy permitted document file. | `CommunityDocumentSurfaceApi.downloadDocument` |
| Documents | `acknowledgeDocument` | Record read/acknowledged state. | `CommunityDocumentSurfaceApi.acknowledgeDocument` |
| Documents | `requestDocumentAccess` | Request access to restricted document. | `CommunityDocumentSurfaceApi.requestDocumentAccess` |
| Documents | `listDocumentVersions` | Inspect document version history. | `CommunityDocumentSurfaceApi.listDocumentVersions` |
| Documents | `linkExternalDocument` | Add external Google Doc/PDF/HTML/provider link. | `CommunityDocumentSurfaceApi.linkExternalDocument` |
| Documents | `refreshExternalPreview` | Refresh metadata/thumbnail/access status for external link. | `CommunityDocumentSurfaceApi.refreshExternalPreview` |
| Documents | `setDocumentPermissions` | Owner/admin changes document access policy. | `CommunityDocumentSurfaceApi.setDocumentPermissions` |
| Documents | `retireDocument` | Hide/retire a document while preserving history. | `CommunityDocumentSurfaceApi.retireDocument` |
| Documents | `documentAuditTrail` | Inspect opens, downloads, acknowledgements, versions, and access requests. | `CommunityDocumentSurfaceApi.documentAuditTrail` |
| External document links | `registerExternalDocument` | Register provider-hosted document/link as workflow content. | `CommunityExternalDocumentApi.registerExternalDocument` |
| External document links | `getExternalDocumentPreview` | Show title/provider/type/access preview before opening. | `CommunityExternalDocumentApi.getExternalDocumentPreview` |
| External document links | `openEmbeddedExternalDocument` | Open link in embedded tab where allowed. | `CommunityExternalDocumentApi.openEmbeddedExternalDocument` |
| External document links | `launchExternalDocument` | Open link in external app/browser/provider. | `CommunityExternalDocumentApi.launchExternalDocument` |
| External document links | `copyExternalDocumentLink` | Copy/share link when policy allows. | `CommunityExternalDocumentApi.copyExternalDocumentLink` |
| External document links | `refreshExternalDocumentMetadata` | Refresh metadata/access preview. | `CommunityExternalDocumentApi.refreshExternalDocumentMetadata` |
| External document links | `recordExternalDocumentOpen` | Audit open/download/launch result. | `CommunityExternalDocumentApi.recordExternalDocumentOpen` |
| External document links | `requestExternalDocumentAccess` | Request or explain missing external-provider access. | `CommunityExternalDocumentApi.requestExternalDocumentAccess` |
| External document links | `revokeExternalDocument` | Retire/revoke unsafe or stale external link. | `CommunityExternalDocumentApi.revokeExternalDocument` |
| External document links | `externalDocumentAuditTrail` | Inspect access/open/metadata history. | `CommunityExternalDocumentApi.externalDocumentAuditTrail` |
| Documents / facilities / roster | `listDocuments` | Inspect current state and decide next action. | `CommunityOperationsSurfaceApi.listDocuments` |
| Documents / facilities / roster | `openDocument` | Inspect current state and decide next action. | `CommunityOperationsSurfaceApi.openDocument` |
| Documents / facilities / roster | `downloadDocument` | Inspect current state and decide next action. | `CommunityOperationsSurfaceApi.downloadDocument` |
| Documents / facilities / roster | `acknowledgeDocument` | Commit the action and expose result/receiver state. | `CommunityOperationsSurfaceApi.acknowledgeDocument` |
| Documents / facilities / roster | `requestAccess` | Start or draft the workflow. | `CommunityOperationsSurfaceApi.requestAccess` |
| Documents / facilities / roster | `documentVersions` | Inspect current state and decide next action. | `CommunityOperationsSurfaceApi.documentVersions` |
| Documents / facilities / roster | `reserveFacility` | Commit the action and expose result/receiver state. | `CommunityOperationsSurfaceApi.reserveFacility` |
| Documents / facilities / roster | `updateReservation` | Modify, configure, or continue the workflow. | `CommunityOperationsSurfaceApi.updateReservation` |
| Documents / facilities / roster | `cancelReservation` | Alternate, reversal, or safety branch. | `CommunityOperationsSurfaceApi.cancelReservation` |
| Documents / facilities / roster | `resolveConflict` | Commit the action and expose result/receiver state. | `CommunityOperationsSurfaceApi.resolveConflict` |
| Documents / facilities / roster | `getRoster` | Inspect current state and decide next action. | `CommunityOperationsSurfaceApi.getRoster` |
| Documents / facilities / roster | `updateRosterMember` | Modify, configure, or continue the workflow. | `CommunityOperationsSurfaceApi.updateRosterMember` |
| Documents / facilities / roster | `rosterHistory` | Workflow-specific state transition. | `CommunityOperationsSurfaceApi.rosterHistory` |
| Search / AI digest | `search` | Inspect current state and decide next action. | `CommunityKnowledgeSurfaceApi.search` |
| Search / AI digest | `answerQuestion` | Inspect current state and decide next action. | `CommunityKnowledgeSurfaceApi.answerQuestion` |
| Search / AI digest | `listCitations` | Inspect current state and decide next action. | `CommunityKnowledgeSurfaceApi.listCitations` |
| Search / AI digest | `openCitation` | Inspect current state and decide next action. | `CommunityKnowledgeSurfaceApi.openCitation` |
| Search / AI digest | `saveDigest` | Modify, configure, or continue the workflow. | `CommunityKnowledgeSurfaceApi.saveDigest` |
| Search / AI digest | `shareDigest` | Modify, configure, or continue the workflow. | `CommunityKnowledgeSurfaceApi.shareDigest` |
| Search / AI digest | `refreshIndex` | Modify, configure, or continue the workflow. | `CommunityKnowledgeSurfaceApi.refreshIndex` |
| Search / AI digest | `staleCitationCheck` | Inspect current state and decide next action. | `CommunityKnowledgeSurfaceApi.staleCitationCheck` |
| Search / AI digest | `visibilityDecision` | Inspect current state and decide next action. | `CommunityKnowledgeSurfaceApi.visibilityDecision` |
| Export / import / transfer | `createExportPlan` | Start or draft the workflow. | `CommunityPortabilitySurfaceApi.createExportPlan` |
| Export / import / transfer | `previewRedaction` | Workflow-specific state transition. | `CommunityPortabilitySurfaceApi.previewRedaction` |
| Export / import / transfer | `generateExport` | Commit the action and expose result/receiver state. | `CommunityPortabilitySurfaceApi.generateExport` |
| Export / import / transfer | `downloadExport` | Inspect current state and decide next action. | `CommunityPortabilitySurfaceApi.downloadExport` |
| Export / import / transfer | `verifyChecksum` | Inspect current state and decide next action. | `CommunityPortabilitySurfaceApi.verifyChecksum` |
| Export / import / transfer | `cancelExport` | Alternate, reversal, or safety branch. | `CommunityPortabilitySurfaceApi.cancelExport` |
| Export / import / transfer | `retryExport` | Commit the action and expose result/receiver state. | `CommunityPortabilitySurfaceApi.retryExport` |
| Export / import / transfer | `startTransfer` | Commit the action and expose result/receiver state. | `CommunityPortabilitySurfaceApi.startTransfer` |
| Export / import / transfer | `verifyTransfer` | Inspect current state and decide next action. | `CommunityPortabilitySurfaceApi.verifyTransfer` |
| Export / import / transfer | `rollbackTransfer` | Alternate, reversal, or safety branch. | `CommunityPortabilitySurfaceApi.rollbackTransfer` |
| Export / import / transfer | `auditTrail` | Inspect current state and decide next action. | `CommunityPortabilitySurfaceApi.auditTrail` |
| Messaging / connections | `sendInvite` | Start or draft the workflow. | `CommunitySocialSurfaceApi.sendInvite` |
| Messaging / connections | `acceptInvite` | Workflow-specific state transition. | `CommunitySocialSurfaceApi.acceptInvite` |
| Messaging / connections | `declineInvite` | Alternate, reversal, or safety branch. | `CommunitySocialSurfaceApi.declineInvite` |
| Messaging / connections | `cancelInvite` | Alternate, reversal, or safety branch. | `CommunitySocialSurfaceApi.cancelInvite` |
| Messaging / connections | `block` | Alternate, reversal, or safety branch. | `CommunitySocialSurfaceApi.block` |
| Messaging / connections | `unblock` | Workflow-specific state transition. | `CommunitySocialSurfaceApi.unblock` |
| Messaging / connections | `mute` | Alternate, reversal, or safety branch. | `CommunitySocialSurfaceApi.mute` |
| Messaging / connections | `archive` | Alternate, reversal, or safety branch. | `CommunitySocialSurfaceApi.archive` |
| Messaging / connections | `connectionStatus` | Inspect current state and decide next action. | `CommunitySocialSurfaceApi.connectionStatus` |
| Messaging / connections | `createThread` | Start or draft the workflow. | `CommunitySocialSurfaceApi.createThread` |
| Messaging / connections | `reply` | Workflow-specific state transition. | `CommunitySocialSurfaceApi.reply` |
| Messaging / connections | `markRead` | Commit the action and expose result/receiver state. | `CommunitySocialSurfaceApi.markRead` |
| Ads / no-fill / ad-off | `requestAdDecision` | Start or draft the workflow. | `CommunityAdSurfaceApi.requestAdDecision` |
| Ads / no-fill / ad-off | `recordImpression` | Commit the action and expose result/receiver state. | `CommunityAdSurfaceApi.recordImpression` |
| Ads / no-fill / ad-off | `recordClick` | Commit the action and expose result/receiver state. | `CommunityAdSurfaceApi.recordClick` |
| Ads / no-fill / ad-off | `recordNoFill` | Commit the action and expose result/receiver state. | `CommunityAdSurfaceApi.recordNoFill` |
| Ads / no-fill / ad-off | `getNoFillReason` | Inspect current state and decide next action. | `CommunityAdSurfaceApi.getNoFillReason` |
| Ads / no-fill / ad-off | `getDisclosure` | Inspect current state and decide next action. | `CommunityAdSurfaceApi.getDisclosure` |
| Ads / no-fill / ad-off | `getAdOffEntitlement` | Inspect current state and decide next action. | `CommunityAdSurfaceApi.getAdOffEntitlement` |
| Ads / no-fill / ad-off | `suppressAds` | Alternate, reversal, or safety branch. | `CommunityAdSurfaceApi.suppressAds` |
| Ads / no-fill / ad-off | `restoreAds` | Alternate, reversal, or safety branch. | `CommunityAdSurfaceApi.restoreAds` |
| Ads / no-fill / ad-off | `receiptEvidence` | Inspect current state and decide next action. | `CommunityAdSurfaceApi.receiptEvidence` |
| Custom form submission | `loadForm` | Inspect current state and decide next action. | `CommunityFormSurfaceApi.loadForm` |
| Custom form submission | `validateDraft` | Start or draft the workflow. | `CommunityFormSurfaceApi.validateDraft` |
| Custom form submission | `saveDraft` | Start or draft the workflow. | `CommunityFormSurfaceApi.saveDraft` |
| Custom form submission | `submitForm` | Start or draft the workflow. | `CommunityFormSurfaceApi.submitForm` |
| Custom form submission | `updateSubmission` | Modify, configure, or continue the workflow. | `CommunityFormSurfaceApi.updateSubmission` |
| Custom form submission | `withdrawSubmission` | Alternate, reversal, or safety branch. | `CommunityFormSurfaceApi.withdrawSubmission` |
| Custom form submission | `routeProtectedFields` | Modify, configure, or continue the workflow. | `CommunityFormSurfaceApi.routeProtectedFields` |
| Custom form submission | `reviewSubmission` | Commit the action and expose result/receiver state. | `CommunityFormSurfaceApi.reviewSubmission` |
| Custom form submission | `exportSubmission` | Workflow-specific state transition. | `CommunityFormSurfaceApi.exportSubmission` |
| Notification inbox | `listInboxItems` | Inspect current state and decide next action. | `CommunityInboxSurfaceApi.listInboxItems` |
| Notification inbox | `markRead` | Commit the action and expose result/receiver state. | `CommunityInboxSurfaceApi.markRead` |
| Notification inbox | `markUnread` | Commit the action and expose result/receiver state. | `CommunityInboxSurfaceApi.markUnread` |
| Notification inbox | `archiveItem` | Alternate, reversal, or safety branch. | `CommunityInboxSurfaceApi.archiveItem` |
| Notification inbox | `muteSource` | Alternate, reversal, or safety branch. | `CommunityInboxSurfaceApi.muteSource` |
| Notification inbox | `openSource` | Inspect current state and decide next action. | `CommunityInboxSurfaceApi.openSource` |
| Notification inbox | `deliveryStatus` | Inspect current state and decide next action. | `CommunityInboxSurfaceApi.deliveryStatus` |
| Notification inbox | `notificationPreferences` | Inspect current state and decide next action. | `CommunityInboxSurfaceApi.notificationPreferences` |
| Notification inbox | `retryDelivery` | Commit the action and expose result/receiver state. | `CommunityInboxSurfaceApi.retryDelivery` |

## Required Product Evidence Per Selected Surface

- Product workflow doc names the surface family, personas, domain objects, roles, permissions, and data classes.
- Workflow/API map links each step to the OpenAPI operation in `community-card-surfaces-api.openapi.yaml`.
- UX doc explains how the screen becomes a domain-native product surface instead of a generic workflow card.
- Fake backend fixtures cover entry, draft/edit, commit/result, alternate/reversal, receiver, read-only, disabled, unauthorized, audit, export, and recovery states where applicable.
- B25 evidence includes screenshots for every implemented state and persona, plus tickets when visible UI does not express the product story above.
