# Community Card Surface API Specifications

Status: Draft normative contract
Scope: Loom Communities V2 card and surface APIs

This folder defines the backend API support required by production-grade Loom Communities card
surfaces. These specifications complement the existing `Community*Api` Dart contracts and OpenAPI
inventory. They are organized by product surface because a generated extension chooses surfaces first,
then composes Loom-owned APIs, rules, events, workflows, jobs, and optional functions.

Executable OpenAPI coverage for every operation in this matrix lives in
[../OpenAPI/community-surfaces/community-card-surfaces-api.openapi.yaml](../OpenAPI/community-surfaces/community-card-surfaces-api.openapi.yaml).
The matching Product Docs V2 workflow/user-story coverage lives in
[../../Product Docs V2/Card Surface Workflow and User Story Coverage.md](../../Product%20Docs%20V2/Card%20Surface%20Workflow%20and%20User%20Story%20Coverage.md).

## Contract Rules

- Every surface must be usable without direct extension database access.
- Every mutation must support idempotency, audit, permission checks, and versioned state.
- Every sensitive field must route through the protected vault and redact audit payloads.
- Every workflow surface must expose actor, receiver, read-only, disabled, hidden, and unauthorized
  states where applicable.
- Every surface must have fake/local-backend parity before B25 can claim production UX coverage.
- Extension packages may configure copy, layout variants, labels, icons, and domain fields, but Loom
  APIs own state transitions, receipts, consent, ads, payments, audit, and export.

## API Surface Matrix

| Surface family | Required API contract | Required operations |
| --- | --- | --- |
| Community card/home | `CommunityHomeSurfaceApi` | `getHomeSummary`, `listPinnedItems`, `getInstallState`, `getUnreadCounts`, `getNextEvent`, `getMembershipBadge`, `resolveBranding`, `syncInstallStatus` |
| App Shell navigation/theming | `CommunityAppShellNavigationApi` | `getTabConfiguration`, `updateTabConfiguration`, `assignSurfaceToTab`, `pinSurface`, `unpinSurface`, `setSurfacePresentationState`, `persistSurfaceFocusState`, `resolveCommunityTheme`, `updateCommunityTheme`, `validateThemeContrast`, `getMessagesTabState`, `openMessagesTab`, `getPersonaTabConfiguration`, `updatePersonaTabConfiguration`, `resolvePersonaTabs`, `assignSurfaceToPersonaTab`, `pinSurfaceForPersona`, `unpinSurfaceForPersona`, `getCustomizationKnobs`, `updateCustomizationKnobs`, `previewNavigationConfiguration`, `validatePersonaNavigation`, `getPersonaSurfacePresentationState`, `updatePersonaSurfacePresentationState`, `listTabRendererContracts`, `resolveTabRendererContract`, `validateTabRendererContract`, `previewTabRendererContract`, `recordTabRendererEvidence` |
| Announcement / publish | `CommunityAnnouncementApi` | `createDraft`, `updateDraft`, `previewAnnouncement`, `scheduleAnnouncement`, `publishAnnouncement`, `cancelScheduledAnnouncement`, `updatePublishedAnnouncement`, `unpublishAnnouncement`, `deliveryStatus`, `readReceipts`, `revisionHistory` |
| Calendar | `CommunityCalendarSurfaceApi` | `listCalendarItems`, `getCalendarItem`, `createCalendarItem`, `updateCalendarItem`, `cancelCalendarItem`, `rescheduleCalendarItem`, `createRecurringSchedule`, `subscribeCalendarFeed`, `importIcsFeed`, `exportCalendarFeed`, `syncExternalCalendar`, `detectCalendarConflicts`, `setReminder`, `openLinkedSurface` |
| Event / RSVP | `CommunityEventRsvpApi` | `createEvent`, `updateEvent`, `cancelEvent`, `rescheduleEvent`, `getEventDetail`, `respondGoingMaybeNo`, `changeRsvp`, `cancelRsvp`, `joinWaitlist`, `listAttendees`, `deliveryReminders`, `calendarState` |
| Member meetup scheduling | `CommunityMeetupApi` | `proposeMeetup`, `suggestSlots`, `counterPropose`, `acceptMeetup`, `declineMeetup`, `cancelMeetup`, `rescheduleMeetup`, `listParticipants`, `setVisibility`, `sendReminder` |
| Volunteer signup | `CommunityVolunteerApi` | `createShift`, `updateShift`, `listShifts`, `signup`, `updateAvailability`, `cancelSignup`, `listVolunteers`, `volunteerSummary`, `protectedContactReveal`, `assignCoordinator`, `checkIn`, `markNoShow` |
| Shared item marketplace / loan / giveaway | `CommunityEquipmentLoanApi` | `browseEquipment`, `searchEquipment`, `getEquipmentDetail`, `listEquipmentListing`, `createEquipmentListing`, `updateEquipmentListing`, `removeEquipmentListing`, `pauseEquipmentListing`, `reactivateEquipmentListing`, `updateAvailability`, `offerEquipment`, `offerGiveaway`, `claimGiveaway`, `requestLoan`, `reserveLoan`, `approveLoan`, `declineLoan`, `joinLoanQueue`, `leaveLoanQueue`, `listLoanQueue`, `advanceLoanQueue`, `schedulePickup`, `checkOut`, `getCurrentHolder`, `transferCustody`, `listCustodyHistory`, `recordConditionCheck`, `extendLoan`, `returnItem`, `sendReturnReminder`, `reportOverdue`, `markDamaged`, `reportLostItem`, `resolveLoanDispute`, `cancelLoan`, `listAvailability`, `listBorrowers`, `privacyScopedContact`, `transferGiveawayOwnership` |
| Marketplace state machine | `CommunityMarketplaceApi` | `listListings`, `getListing`, `listTransitions`, `applyTransition`, `listCustodyHistory` — persona-filtered transitions and effect flags per the declared per-listing state-machine engine. |
| Plant exchange | `CommunityExchangeApi` | `createOffer`, `updateOffer`, `cancelOffer`, `claimOffer`, `cancelClaim`, `markUnavailable`, `schedulePickup`, `handoffComplete`, `listClaims`, `privacyScopedContact` |
| Book nomination | `CommunityNominationApi` | `createNomination`, `updateNomination`, `withdrawNomination`, `listNominations`, `detectDuplicate`, `checkEligibility`, `linkToBallot`, `nominationStatus` |
| Vote / poll | `CommunityVoteApi` | `openBallot`, `closeBallot`, `castVote`, `changeVote`, `clearVote`, `getVoteState`, `getResults`, `resolveTie`, `publishSelection`, `auditVote` |
| Discussion / message | `CommunityThreadApi` | `createThread`, `reply`, `editMessage`, `deleteMessage`, `markRead`, `listUnread`, `muteThread`, `archiveThread`, `moderateMessage`, `attachMedia`, `mentionMember` |
| Payments / dues / donations / ad-off | `CommunityPaymentSurfaceApi` | `createPaymentIntent`, `confirmPayment`, `recordFailure`, `retryPayment`, `refund`, `createRecurringPlan`, `manageRecurringPlan`, `setDonorVisibility`, `getReceipt`, `getEntitlement`, `settlementStatus` |
| Care / protected request | `CommunityCareRequestApi` | `createRequest`, `updateRequest`, `withdrawRequest`, `assignCareTeam`, `reviewRequest`, `requestChanges`, `resolveRequest`, `neutralNotification`, `readPublicSummary`, `readProtectedDetails`, `redactedAudit` |
| Approval / request cards | `CommunityApprovalApi` | `submitRequest`, `assignReviewer`, `approve`, `reject`, `requestChanges`, `comment`, `statusHistory`, `reopen`, `appeal`, `notifyRequester` |
| Workflow status / case | `CommunityWorkflowStatusApi` | `createWorkflowInstance`, `getWorkflowStatus`, `listWorkflowSteps`, `transitionWorkflowStep`, `assignWorkflowReviewer`, `requestWorkflowChanges`, `approveWorkflowStep`, `rejectWorkflowStep`, `addWorkflowComment`, `attachWorkflowDocument`, `recordWorkflowPaymentNeeded`, `notifyWorkflowParticipants`, `reopenWorkflow`, `cancelWorkflow`, `workflowAuditTrail` |
| Documents | `CommunityDocumentSurfaceApi` | `listDocuments`, `getDocumentDetail`, `openEmbeddedDocument`, `openExternalDocument`, `downloadDocument`, `acknowledgeDocument`, `requestDocumentAccess`, `listDocumentVersions`, `linkExternalDocument`, `refreshExternalPreview`, `setDocumentPermissions`, `retireDocument`, `documentAuditTrail` |
| External document links | `CommunityExternalDocumentApi` | `registerExternalDocument`, `getExternalDocumentPreview`, `openEmbeddedExternalDocument`, `launchExternalDocument`, `copyExternalDocumentLink`, `refreshExternalDocumentMetadata`, `recordExternalDocumentOpen`, `requestExternalDocumentAccess`, `revokeExternalDocument`, `externalDocumentAuditTrail` |
| Documents / facilities / roster | `CommunityOperationsSurfaceApi` | `listDocuments`, `openDocument`, `downloadDocument`, `acknowledgeDocument`, `requestAccess`, `documentVersions`, `reserveFacility`, `updateReservation`, `cancelReservation`, `resolveConflict`, `getRoster`, `updateRosterMember`, `rosterHistory` |
| Search / AI digest | `CommunityKnowledgeSurfaceApi` | `search`, `answerQuestion`, `listCitations`, `openCitation`, `saveDigest`, `shareDigest`, `refreshIndex`, `staleCitationCheck`, `visibilityDecision` |
| Export / import / transfer | `CommunityPortabilitySurfaceApi` | `createExportPlan`, `previewRedaction`, `generateExport`, `downloadExport`, `verifyChecksum`, `cancelExport`, `retryExport`, `startTransfer`, `verifyTransfer`, `rollbackTransfer`, `auditTrail` |
| Messaging / connections | `CommunitySocialSurfaceApi` | `sendInvite`, `acceptInvite`, `declineInvite`, `cancelInvite`, `block`, `unblock`, `mute`, `archive`, `connectionStatus`, `createThread`, `reply`, `markRead` |
| Ads / no-fill / ad-off | `CommunityAdSurfaceApi` | `requestAdDecision`, `recordImpression`, `recordClick`, `recordNoFill`, `getNoFillReason`, `getDisclosure`, `getAdOffEntitlement`, `suppressAds`, `restoreAds`, `receiptEvidence` |
| Custom form submission | `CommunityFormSurfaceApi` | `loadForm`, `validateDraft`, `saveDraft`, `submitForm`, `updateSubmission`, `withdrawSubmission`, `routeProtectedFields`, `reviewSubmission`, `exportSubmission` |
| Notification inbox | `CommunityInboxSurfaceApi` | `listInboxItems`, `markRead`, `markUnread`, `archiveItem`, `muteSource`, `openSource`, `deliveryStatus`, `notificationPreferences`, `retryDelivery` |

## Common Surface State Model

Every API above must expose a state envelope with these fields or equivalents:

| Field | Purpose |
| --- | --- |
| `surfaceId` | Stable surface instance identifier. |
| `communityId` | Owning community. |
| `extensionId` | Extension requesting/rendering the surface. |
| `personaId` / `roleId` | Actor or viewer role context. |
| `state` | Domain state, such as `draft`, `open`, `submitted`, `approved`, `paid`, `sent`, `read`, `failed`, `cancelled`. |
| `allowedActions` | Permission-filtered actions the current persona can take. |
| `disabledActions` | Actions visible but unavailable with reasons. |
| `hiddenActions` | Actions suppressed for this persona. |
| `receiverStates` | Downstream persona states created by actor actions. |
| `receiptRefs` | Payment, audit, notification, export, or migration receipts. |
| `events` | Typed events emitted or consumed. |
| `version` | Optimistic concurrency/version stamp. |

## Permission Naming

Use scoped capability names so extension manifests can request only what each surface needs:

```text
community.surface.<family>.read
community.surface.<family>.write
community.surface.<family>.review
community.surface.<family>.admin
community.surface.<family>.protected.read
community.surface.<family>.payment
community.surface.<family>.export
```

Examples:

- `community.surface.announcement.write`
- `community.surface.event.rsvp`
- `community.surface.volunteer.roster.read`
- `community.surface.care.protected.read`
- `community.surface.payment.refund`
- `community.surface.portability.rollback`

## Events

Each API must emit a typed event for state transitions that other rules, workflows, jobs, and UI
receiver states consume. Event names use the format:

```text
community.<surface-family>.<domain-object>.<past-tense-state>
```

Examples:

- `community.announcement.message.published`
- `community.event.rsvp.changed`
- `community.volunteer.signup.cancelled`
- `community.payment.receipt.issued`
- `community.care.request.assigned`
- `community.export.bundle.generated`

## Fake Backend Parity

The Demo App Local Backend must support these operations at least as deterministic fakes before a
surface is considered production-UX complete:

- Create/read/update the surface domain object.
- Execute primary and alternate actions.
- Persist result state across persona switches.
- Expose receiver/read-only/disabled/unauthorized states.
- Emit fake events and receipt/audit references.
- Export/import the surface data through the initialization/export package path.

## Relationship To Card Surface Catalog

Builder-facing usage guidance lives in [../../CardSurfaces/README.md](../../CardSurfaces/README.md).
That catalog explains how a Skill or developer chooses, customizes, and validates each surface while
this document defines the backend contracts those surfaces require.