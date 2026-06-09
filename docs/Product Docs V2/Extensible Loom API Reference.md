# Extensible Loom — API Reference

Status: Draft for review
Companion to: [Extensible Loom Product Definition](./Extensible%20Loom%20Product%20Definition.md)

This is the exhaustive catalog behind the [product definition](./Extensible%20Loom%20Product%20Definition.md).
The product doc states each concept once and links here for detail. This reference covers:

1. [Core community API families](#1-core-community-api-families) — the durable primitives every community uses (incl. ads, protected-visibility vault, connections).
2. [Extension platform APIs](#2-extension-platform-apis) — registry, runtime, schema, rules, workflows, jobs, functions, secrets, certification/validation.
3. [Domain APIs](#3-domain-apis) — sports, religious.
4. [Stable surfaces](#4-stable-surfaces)
5. [Capability permission catalog](#5-capability-permission-catalog)
6. [Event families](#6-event-families)
7. [Extension package file format](#7-extension-package-file-format)
8. [Worked vertical examples](#8-worked-vertical-examples)
9. [Proposed Dart API file layout](#9-proposed-dart-api-file-layout)
10. [Community taxonomy and per-vertical user stories](#10-community-taxonomy-and-per-vertical-user-stories)
11. [How verticals map back to common APIs](#11-how-verticals-map-back-to-common-apis)

Naming follows the V1 conventions (see [Core Thesis §2.2](../Product%20Docs/01-core-thesis-and-platform-principles.md)):
APIs end in `Api`, ledgers in `Ledger`, registries in `Registry`, policies in `Policy`, receipts in `Receipt`.

---

## 1. Core community API families

Stable primitives every community uses, regardless of vertical.

### 1.1 Community Registry API

`CommunityRegistryApi` — create, configure, archive, transfer, and discover communities. The top-level
owner container. A **Community is a peer of the V1 Creator Channel**, not a replacement: it reuses the
shared identity/wallet/receipt/audit/extension-runtime layers, and the existing channel APIs keep
working unchanged for backward compatibility.

```ts
createCommunity(input)                         // assigns a communityId + sets a friendly, unique handle
getCommunity(communityId)
updateCommunityProfile(communityId, patch)
setCommunityVisibility(communityId, visibility)
configureCommunityModules(communityId, modules)
setCommunityType(communityId, type)
archiveCommunity(communityId)
transferCommunityProvider(communityId, targetProviderId)
listMyCommunities(passportId)

// discovery & local add (Main Loom app "Add a community")
findCommunityByHandle(handle)                  // friendly unique name, e.g. @sunset-ridge-hoa
generateCommunityQr(communityId)               // QR encoding the handle / communityId + deep link
resolveCommunityQr(qrPayload)                  // returns the Community for a scanned code
addCommunityToApp(passportId, communityId)     // adds the community locally; triggers extension download
```

The **`handle`** is the friendly, unique name people search by; the **`communityId`** is the stable
machine ID. `generateCommunityQr` / `resolveCommunityQr` back the QR add-flow. Extension download and
version resolution are in [§2.1](#21-community-extension-registry-api).

```ts
Community {
  communityId
  name
  handle
  type
  description
  visibility           // public | private | secret
  locationScope
  ownerProviderId
  governanceModel
  installedExtensionIds
  enabledModules
  createdAt
  updatedAt
}
```

### 1.2 Community Membership API

`CommunityMembershipApi` — join requests, invitations, approvals, households, guardian/minor
relationships, and member lifecycle. Following a creator (V1) is not the same as joining a community:
communities need members, households, families, minors, teams, residents, vendors, volunteers,
donors, and guests.

```ts
requestJoinCommunity(communityId, applicant)
inviteMember(communityId, invite)
approveJoinRequest(communityId, requestId)
rejectJoinRequest(communityId, requestId)
removeMember(communityId, memberId)
suspendMember(communityId, memberId, reason)
restoreMember(communityId, memberId)
listMembers(communityId, filters)
getMemberProfile(communityId, memberId)
updateMemberProfile(communityId, memberId, patch)
createHousehold(communityId, input)
addHouseholdMember(communityId, householdId, memberId)
linkGuardianMinor(communityId, guardianMemberId, minorMemberId)
verifyMember(communityId, memberId, verificationType)
```

```ts
CommunityMember {
  memberId
  communityId
  passportId           // reuses the V1 Fan Passport identity
  displayName
  status
  roles
  householdId
  guardianFor
  minorOf
  joinedAt
  verificationState
  directoryVisibility
}
```

Extensibility hook: extensions can add onboarding forms and custom member-profile fields, but Loom
owns the canonical member record. Example extension-owned profile:

```ts
SoccerPlayerProfile {
  playerId
  memberId
  dateOfBirth
  jerseySize
  preferredPosition
  medicalNotesRef
  guardianIds
}
```

### 1.3 Role, Permission, Policy & Consent API

`CommunityRolePolicyApi` — define roles, permissions, role inheritance, member permissions, extension
permissions, and consent gates. The most important trust boundary.

```ts
createRole(communityId, role)
updateRole(communityId, roleId, patch)
assignRole(communityId, memberId, roleId)
revokeRole(communityId, memberId, roleId)
setPermissionPolicy(communityId, policy)
getEffectivePermissions(communityId, memberId, context)
canPerformAction(communityId, memberId, action, resourceRef)
createConsentRequest(communityId, memberId, purpose)
grantConsent(communityId, memberId, consentGrant)
revokeConsent(communityId, memberId, consentGrantId)
```

Effective permission is always the intersection:

```text
Extension requested permissions
∩ Admin-approved extension permissions
∩ Member role permissions
∩ Member consent grants
∩ Loom platform safety policy
```

Roles seen across verticals: owner, admin, moderator, board member, coach, imam/priest/rabbi/pastor,
treasurer, captain, parent, player, volunteer, guest, vendor, facility manager, registrar, care-team
member.

### 1.4 Community Spaces API

`CommunitySpacesApi` — create and manage sub-communities: teams, committees, classrooms, ministries,
book rooms, league divisions, facilities, marketplaces, board spaces, volunteer spaces.

```ts
createSpace(communityId, input)
updateSpace(communityId, spaceId, patch)
archiveSpace(communityId, spaceId)
listSpaces(communityId, filters)
joinSpace(communityId, spaceId, memberId)
leaveSpace(communityId, spaceId, memberId)
addSpaceMember(communityId, spaceId, memberId)
removeSpaceMember(communityId, spaceId, memberId)
setSpaceVisibility(communityId, spaceId, visibility)
setSpacePolicy(communityId, spaceId, policy)
registerSpaceType(communityId, extensionId, spaceTypeDefinition)   // user-extensible custom types
listSpaceTypes(communityId)
```

```ts
CommunitySpace {
  spaceId
  communityId
  type                 // a built-in type OR a registered custom type
  name
  description
  visibility
  parentSpaceId        // arbitrary-depth nesting: club → league → division → team → subgroup
  defaultPermissions
  extensionId
}
```

**Nesting is arbitrary-depth** via `parentSpaceId` — the model is not limited to two levels, so a
hierarchy like club → league → division → team → subgroup is expressible.

**Space types are user-extensible.** Built-in types: `announcements`, `chat`, `forum`, `team`,
`league`, `division`, `committee`, `board`, `class`, `ministry`, `facility`, `marketplace`,
`documents`, `volunteers`, `care`, `youth`, `book_discussion`. A community or extension can
`registerSpaceType(...)` to add its own types beyond this set (the list is open, not a closed enum).

### 1.5 App Shell / Cards / Routes / Navigation API

`CommunityAppShellApi` — let extensions define cards, routes, tabs, entrypoints, surfaces, and
shell-safe navigation. This is what lets Loom load AI-generated community experiences.

```ts
registerCommunityCard(communityId, extensionId, cardDefinition)
listCommunityCards(passportId)
resolveCardData(communityId, cardId, memberId)
registerRoutes(communityId, extensionId, routes)
createLaunchContext(communityId, memberId, surface, route)
openExtensionRoute(communityId, extensionId, route, launchContext)
registerNavigationPanel(communityId, extensionId, panel)   // required; placement + buttons
registerMessagingShell(communityId, extensionId, shell)    // customizable, but always reachable
registerConnectionsShell(communityId, extensionId, shell)  // customizable, but always reachable
```

### Required shell structure

Every extension loads into a shell with a fixed contract (see
[Product Definition §5](./Extensible%20Loom%20Product%20Definition.md#5-platform-architecture)):
a Loom-rendered **thin top ad banner** (always), and a **navigation panel the extension supplies**.

```ts
NavigationPanel {
  placement              // top | left | right | bottom | floating
  buttons[]              // MUST include a "messages" button and a "connections" button
}

NavButton {
  key                    // built-in: "messages" | "connections" | custom keys
  label                  // renamable per community (e.g. "Chat", "Members")
  targetSurface          // e.g. interactions.home | connections.home | <custom route>
}
```

- The **Messages** button targets the interaction surfaces (chat / messaging / forums / feeds) where
  in-stream ads are injected ([§1.7](#17-messaging--notification-api), [§1.18](#118-ads--ad-off-api)).
- The **Connections** button targets the connections surface ([§1.20](#120-connections-api)).
- The **Messaging shell** and **Connections shell** are customizable per community via
  `registerMessagingShell` / `registerConnectionsShell`, but both must stay reachable from the panel.
- Presence of the panel and the two required buttons is **enforced by the Skill's generation pattern**
  (and lintable at certification, [§2.11](#211-extension-certification--validation-api)), not a hard
  runtime backend check — the **ad banner**, by contrast, is structurally enforced.

```ts
CommunityCard {
  cardId
  communityId
  extensionId
  surface
  titleTemplate
  subtitleTemplate
  badgeTemplates
  dataSources
  primaryActionRoute
}

ExtensionRoute {
  routeId
  communityId
  extensionId
  path
  surface
  requiredPermissions
  requiredRoles
  dataSources
}
```

The extension owns what the card says; the Loom shell owns safe rendering, identity, notifications,
and the entrypoint. Example card definition:

```json
{
  "cardId": "soccer-club-home-card",
  "surface": "community.card",
  "dataSources": [
    "community.events.upcoming",
    "community.notifications.unread",
    "extension.state.teamSummary"
  ],
  "layout": {
    "title": "{{community.name}}",
    "subtitle": "{{nextEvent.title}} at {{nextEvent.startsAt}}",
    "badges": ["{{unreadCount}} unread", "{{memberRole}}"],
    "primaryAction": { "label": "Open", "route": "/home" }
  }
}
```

### 1.6 Posts, Threads, Comments & Publishing API

- `CommunityPublishingApi` — announcements, posts, long-form updates, blogs, sermons, newsletters,
  match recaps, meeting summaries.
- `CommunityThreadApi` — durable topic discussions.
- `CommunityCommentApi` — comments across posts, events, cases, documents, listings, matches.

```ts
createPost(communityId, spaceId, post)
publishAnnouncement(communityId, target, announcement)
editPost(communityId, postId, patch)
pinPost(communityId, postId)
listFeed(communityId, filters)
createThread(communityId, spaceId, thread)
replyToThread(communityId, threadId, reply)
lockThread(communityId, threadId)
markAnswer(communityId, threadId, replyId)
addComment(resourceRef, comment)
react(resourceRef, reaction)
moderateComment(commentId, action)
```

Stored: `Post`, `Thread`, `Comment`, `Reaction`, `AttachmentRef`, `VisibilityPolicy`, `ModerationState`.

### 1.7 Messaging & Notification API

- `CommunityMessagingApi` — DMs, group chats, team chats, committee chats, admin replies.
- `CommunityNotificationApi` — push, email, SMS, in-app inbox, digests, emergency alerts.

```ts
createConversation(communityId, participants, context)
sendMessage(conversationId, message)
listMessages(conversationId, cursor)
markRead(conversationId, memberId)
muteConversation(conversationId, memberId)
sendNotification(communityId, target, template, payload)
scheduleNotification(communityId, target, sendAt, template)
setNotificationPreference(memberId, communityId, preferences)
generateDigest(memberId, communityId, timeRange)
```

Controls: rate limits, emergency-alert permission, minor-messaging restrictions, admin-broadcast
approval, unsubscribe/digest settings, audit for sensitive messages.

#### Rich stream-item content model

Messages, forum posts, and feed entries are all **stream items** that share one content model, so the
extension's stream renderer can display any of them — including **in-stream ads** ([§1.18](#118-ads--ad-off-api)) —
faithfully. The API text stream carries inline **formatting** and one or more **attachments**
(image / link / file), plus an explicit `kind` so the renderer can label ads.

```ts
StreamItem {
  itemId
  streamRef             // conversationId | spaceId (forum/feed)
  authorRef             // memberId, or "system" / "ad" for injected items
  kind                  // message | post | feed_entry | ad
  content: RichContent
  createdAt
  adDisclosure?         // present when kind == ad: sponsor label, "Ad" badge, report/mute affordance
}

RichContent {
  text                  // formatted text stream (marks: bold/italic/link/mention/code/list)
  attachments: Attachment[]
}

Attachment {
  type                  // image | link | file | video
  url
  title?
  thumbnailUrl?
  mimeType?
  sizeBytes?
}
```

`sendMessage` / `createPost` / feed writes accept `RichContent`; `listMessages` and feed reads return
`StreamItem`s with any injected ad items already interleaved by Loom (the renderer must display them).

### 1.8 Events, Calendar, RSVP, Registration & Ticketing APIs

- `CommunityEventsApi` — meetings, services, practices, matches, classes, fundraisers, shifts.
- `CommunityRegistrationApi` — structured registration for classes, seasons, camps, events.
- `CommunityTicketingApi` — paid/free ticketing, QR check-in, refunds.
- `AvailabilityPollApi` — scheduling consensus.

```ts
createEvent(communityId, event)
updateEvent(eventId, patch)
cancelEvent(eventId, reason)
listEvents(communityId, filters)
rsvp(eventId, memberId, response)
waitlist(eventId, memberId)
checkIn(eventId, memberId)
publishCalendarFeed(communityId, filters)
createRegistrationForm(communityId, targetRef, form)
submitRegistration(formId, memberId, answers)
approveRegistration(registrationId)
rejectRegistration(registrationId)
createTicketType(eventId, ticketType)
purchaseTicket(eventId, memberId, ticketTypeId)
scanTicket(ticketId)
refundTicket(ticketId, reason)
```

### 1.9 Forms, Polls, Voting & Surveys APIs

- `CommunityFormsApi` — applications, waivers, architectural reviews, youth consent, complaints.
- `CommunityPollsApi` — lightweight decisions.
- `CommunityVotingApi` — formal governance voting, elections, quorum, secret ballots.

```ts
createForm(communityId, schema)
publishForm(formId)
submitForm(formId, memberId, answers, attachments)
reviewSubmission(submissionId, decision)
createPoll(communityId, poll)
castPollVote(pollId, memberId, choice)
closePoll(pollId)
createElection(communityId, election)
castSecureVote(electionId, memberId, ballot)
verifyQuorum(electionId)
publishVoteResult(electionId)
```

### 1.10 Case, Task & Approval APIs

- `CommunityCaseApi` — maintenance, violations, care requests, complaints, safety incidents, disputes.
- `CommunityTaskApi` — assignable work items.
- `CommunityApprovalApi` — approvals tied to workflows.

```ts
createCase(communityId, caseType, input)
assignCase(caseId, assignee)
commentOnCase(caseId, comment)
attachEvidence(caseId, fileRef)
changeCaseStatus(caseId, status)
closeCase(caseId, resolution)
createTask(communityId, task)
assignTask(taskId, assignee)
completeTask(taskId)
requestApproval(resourceRef, approvalPolicy)
submitApprovalDecision(approvalId, decision)
```

### 1.11 Documents, Files, Notes, Wiki & Sheets APIs

- `CommunityDocumentApi` — documents, bylaws, handbooks, minutes, sermons, notes, practice plans.
- `CommunityFilesApi` — file upload, storage, permissions, retention.
- `CommunityListSheetApi` — simple structured lists and spreadsheet-like tables.
- `CommunityWikiApi` — shared knowledge base.

```ts
uploadFile(communityId, file, visibility)
createDocument(communityId, document)
updateDocument(documentId, patch)
versionDocument(documentId)
setRetentionPolicy(resourceRef, policy)
createList(communityId, schema)
addListRow(listId, row)
updateListRow(listId, rowId, patch)
createWikiPage(communityId, page)
searchDocuments(communityId, query)
```

### 1.12 Facility, Resource, Inventory & Reservation APIs

- `CommunityFacilitiesApi` — fields, courts, rooms, halls, gyms, kitchens, classrooms.
- `CommunityReservationsApi` — conflict-free booking and approval.
- `CommunityInventoryApi` — equipment, uniforms, books, tools, keys, chairs.

```ts
createFacility(communityId, facility)
setFacilitySchedule(facilityId, schedule)
setBlackoutWindow(facilityId, blackout)
listFacilityAvailability(facilityId, dateRange)
requestReservation(facilityId, reservation)
approveReservation(reservationId)
rejectReservation(reservationId)
cancelReservation(reservationId)
detectReservationConflict(facilityId, timeRange)
createInventoryItem(communityId, item)
checkoutItem(itemId, memberId)
returnItem(itemId)
scheduleMaintenance(resourceRef, maintenanceWindow)
```

### 1.13 Payments, Dues, Donations, Invoices & Receipts APIs

Reuses the V1 Fan Wallet, Receipt Ledger, and Settlement Engine.

- `CommunityWalletApi` — community payments.
- `CommunityDuesApi` — dues plans, invoices, late fees.
- `CommunityDonationApi` — funds, campaigns, giving receipts.
- `CommunityInvoiceApi` — invoices, balances, waivers, refunds.
- `CommunityReceiptApi` — receipts and audit records.

```ts
createCommunityWallet(communityId, config)
createPaymentIntent(communityId, payerMemberId, purpose, amount, relatedResource)
confirmPayment(paymentIntentId)
issueRefund(paymentId, amount, reason)
createDuesPlan(communityId, duesPlan)
generateInvoices(communityId, duesPlanId)
sendInvoiceReminder(invoiceId)
markInvoiceWaived(invoiceId, reason)
createDonationFund(communityId, fund)
makeDonation(communityId, fundId, donorMemberId, amount)
createRecurringGift(communityId, fundId, donorMemberId, schedule)
issueReceipt(paymentId)
listOpenBalances(communityId, filters)
```

Payment purposes: `dues`, `donation`, `ticket`, `event_registration`, `season_registration`,
`class_registration`, `facility_fee`, `marketplace_purchase`, `fine`, `deposit`, `refund`,
`scholarship_adjustment`.

### 1.14 Marketplace, Trading, Borrowing & Handoff APIs

- `CommunityMarketplaceApi` — local offers, requests, sales, swaps, lending, borrowing.
- `CommunityHandoffApi` — pickup coordination.
- `CommunityMarketplaceSafetyApi` — no-shows, disputes, trust, moderation.

```ts
createListing(communityId, listing)
updateListing(listingId, patch)
claimListing(listingId, memberId)
withdrawClaim(listingId, memberId)
selectRecipient(listingId, memberId)
proposePickupWindow(listingId, window)
sharePickupDetails(listingId, recipientId)
confirmHandoff(listingId)
reportNoShow(listingId, memberId)
rateHandoff(listingId, rating)
moderateListing(listingId, action)
```

### 1.15 Search, AI, Recommendation & Digest APIs

Reuses the V1 AI Gateway and neutral-search principles.

- `CommunitySearchApi` — permission-aware search.
- `CommunityRecommendationApi` — recommend events, spaces, posts, volunteer needs, listings.
- `CommunityAiApi` — summaries, Q&A, minutes, drafts, scheduling suggestions.
- `CommunityDigestApi` — daily/weekly digests.

```ts
searchCommunity(communityId, memberId, query, filters)
searchMyCommunities(passportId, query)
indexCommunityResource(resourceRef)
explainSearchVisibility(resourceRef, memberId)
getCommunityFeed(communityId, memberId, filters)
getRecommendedActions(communityId, memberId)
explainRecommendation(recommendationId)
summarizeThread(threadId)
generateMeetingMinutes(eventId, transcriptRef)
draftAnnouncement(communityId, input)
answerFromCommunityArchive(communityId, memberId, question)
suggestSchedule(communityId, participants, constraints)
generateDigest(communityId, memberId, timeRange)
```

### 1.16 Trust, Safety, Moderation & Audit APIs

Reuses the V1 Receipt/Audit ledgers.

- `CommunityTrustSafetyApi` — reports, moderation queues, member restrictions, safety incidents.
- `CommunityAuditApi` — immutable audit trail.
- `CommunityReceiptLedgerApi` — receipts for payments, votes, approvals, data access, exports.

```ts
reportResource(resourceRef, reporterMemberId, reason)
createModerationCase(communityId, resourceRef)
takeModerationAction(caseId, action)
restrictMember(communityId, memberId, restriction)
appealModerationAction(caseId, appeal)
recordAuditEvent(communityId, event)
getAuditTrail(communityId, filters)
createReceipt(communityId, receipt)
exportEvidenceBundle(communityId, resourceRef)
```

### 1.17 Import, Export, Migration & Provider Portability APIs

Reuses the V1 migration/export machinery.

- `CommunityImportExportApi` — port community data in and out.
- `CommunityProviderTransferApi` — move a community to another backend provider.
- `ExtensionExportApi` — export extension state and schemas.

```ts
importMembersCsv(communityId, fileRef)
importCalendarIcs(communityId, fileRef)
importDocumentsZip(communityId, fileRef)
exportCommunityArchive(communityId, exportScope)
exportMemberData(communityId, memberId)
exportExtensionState(communityId, extensionId)
validateImportPackage(packageRef)
transferCommunityProvider(communityId, targetProviderId)
```

---

### 1.18 Ads & ad-off API

`CommunityAdsApi` — the free-backend revenue model (see
[Product Definition §10](./Extensible%20Loom%20Product%20Definition.md#10-monetization--business-model)).
Ads reach members two ways, **neither removable by an extension or AI-generated package** (enforced at
certification, [§2.11](#211-extension-certification--validation-api)). Reuses the V1 `AdDecisionApi` /
`PremiumNoAdApi` concepts.

1. **Shell-rendered ad surfaces** — the thin top banner and video pre/mid-roll, filled by `fillAdSlot`
   and rendered by the App Shell (not the extension).
2. **In-stream native ad items** — for interaction streams (chat / messaging / forums / feeds), Loom
   injects the ad as a `StreamItem` of `kind: ad` ([§1.7](#17-messaging--notification-api)) via
   `injectStreamAd`; the extension's renderer displays it like any other stream item.

```ts
fillAdSlot(communityId, surface, slotContext, memberId)   // shell surfaces only (ad.shell_banner, ad.playback_*)
injectStreamAd(communityId, streamRef, memberId)          // returns a StreamItem{kind:ad} interleaved into the stream
recordAdImpression(adReceiptInput)                        // emits an EconomicReceipt
recordAdInteraction(adReceiptInput)
getAdSettings(communityId, memberId)                      // resolves whether ads are on for this member here
purchaseAdFreeSubscription(memberId, plan)                // end-user: turns off ads everywhere
purchaseCommunityAdFree(communityId, plan)                // owner: turns off ads across this community's surface
setAdPolicy(communityId, policy)                          // density/placement/category rules; sensitive-context exclusions
```

```ts
AdSettings {
  memberId
  communityId
  adsEnabled            // false if member has an ad-free subscription OR the community is ad-free
  source                // none | member_subscription | community_owner_payment
}
```

Shell ad surfaces are addressed by the `ad.*` surfaces in [§4](#4-stable-surfaces); in-stream ads are
addressed by `streamRef`. Sensitive contexts (care requests, minor data, donation receipts) can be
excluded from both ad fill and stream injection via `setAdPolicy`.

### 1.19 Protected-Visibility Vault API

`CommunityVaultApi` — dedicated protected storage for sensitive data (pastoral/medical care requests,
minor/youth records, donor-identifiable detail), reusing V1's vault model rather than relying only on
role + visibility policy. Access requires explicit permission, every read is audited, and audit
payloads are redacted.

```ts
putVaultRecord(communityId, vaultClass, data, accessPolicy)
getVaultRecord(communityId, vaultClass, recordId, memberId)   // permission-gated + audited
listVaultRecords(communityId, vaultClass, memberId, filters)
setVaultRetentionPolicy(communityId, vaultClass, policy)
exportVaultRecord(communityId, vaultClass, recordId)          // owner export; portability preserved
```

Vault classes: `care` (pastoral/medical/counseling), `minor` (youth/guardian records), `donor`
(donor-identifiable giving detail). General admins may see aggregates; identifiable records require
the relevant role (care-team, registrar, treasurer) and explicit policy.

### 1.20 Connections API

`CommunityConnectionsApi` — the people a member is connected with (a Passport-level social graph),
surfaced behind the required **Connections** nav button ([§1.5](#15-app-shell--cards--routes--navigation-api)).
From the Connections view a member can **invite their connections to join the community** — allowed
**unless the other person has blocked them**.

```ts
listConnections(passportId, filters)                            // your connections across Loom
listConnectionsInCommunity(communityId, memberId)               // connections who are also members here
sendConnectionRequest(fromPassportId, toPassportId)
acceptConnectionRequest(requestId)
removeConnection(passportId, otherPassportId)
blockConnection(passportId, otherPassportId)                    // prevents future invites/requests
inviteConnectionToCommunity(communityId, fromMemberId, connectionPassportId)   // blocked → rejected
```

```ts
Connection {
  passportId
  connectedPassportId
  state                 // pending | connected | blocked
  createdAt
}
```

Reuses the V1 portable Passport identity. Default visibility of a member's connection list and the
invite/block defaults are open product questions (see
[Product Definition §13](./Extensible%20Loom%20Product%20Definition.md#13-open-questions--decisions-needed)).

---

## 2. Extension platform APIs

The extensibility layer: how an AI Skill (or a hand author) produces a Loom-compatible extension and
how it runs safely without bypassing Loom's trust boundary.

### 2.1 Community Extension Registry API

`CommunityExtensionRegistryApi` — register a builder, publish (→ QR), certify, install, configure,
suspend, update, uninstall, download, and export community extensions. Generalizes the V1
channel-based `ExtensionManifest`/`ExtensionInstall`.

This backs the Skill's authoring/publish loop and the Main Loom app's download/update loop (see
[Product Definition §6](./Extensible%20Loom%20Product%20Definition.md#6-extension-package--lifecycle)):
the builder **registers** (gets an `appId`), the Skill **publishes** the package and receives a QR
code, and the Main app **downloads the bundle** and **fetches the latest version** when a member opens
the community.

```dart
abstract class CommunityExtensionRegistryApi {
  // builder registration (the "App ID" created in the Skill)
  Future<BuilderAppRegistration> registerBuilderApp({
    required String passportId,            // the builder/owner's Loom Identity
    required String displayName,
  });                                       // returns { appId, ... }

  Future<List<ExtensionManifest>> listCommunityExtensions({
    String? category, String? communityType, bool certifiedOnly = true,
  });
  Future<ExtensionManifest> getExtension({ required String extensionId, String? version });
  Future<String> getLatestExtensionVersion({ required String extensionId });
  Future<ExtensionBundle> downloadExtensionBundle({ required String extensionId, required String version });

  // publish: upload package → validate → certify → returns a QR code + deep link
  Future<ExtensionPublishResult> publishExtension({
    required String appId, required String communityId,
    required ExtensionManifest manifest, required ExtensionPackageRef packageRef,
    required String idempotencyKey,
  });

  Future<CommunityExtensionInstall> installCommunityExtension({
    required String communityId, required String extensionId, required String version,
    required List<String> approvedPermissions, required List<String> approvedSurfaces,
    required Map<String, dynamic> config, required String idempotencyKey,
  });
  Future<CommunityExtensionInstall> updateCommunityExtensionConfig({
    required String communityId, required String extensionId,
    required Map<String, dynamic> configPatch, required String idempotencyKey,
  });
  Future<CommunityExtensionInstall> suspendCommunityExtension({
    required String communityId, required String extensionId, required String reason,
    required String idempotencyKey,
  });
  Future<void> uninstallCommunityExtension({
    required String communityId, required String extensionId,
    required ExtensionUninstallMode mode, required String idempotencyKey,
  });
}
```

```ts
CommunityExtensionManifest {
  extensionId, name, version, category, communityTypes, surfaces, routes, permissions,
  eventSubscriptions, schemas, workflows, rules, jobs, riskTier, certificationState, exportBehavior
}

CommunityExtensionInstall {
  installId, communityId, extensionId, version, approvedPermissions, approvedSurfaces,
  config, state, installedBy, installedAt
}

BuilderAppRegistration { appId, passportId, displayName, createdAt }

ExtensionPublishResult {
  extensionId
  version
  certificationState
  communityHandle        // friendly unique name members search by
  qrCode                 // image/payload encoding the handle / communityId + deep link
  deepLink               // loom://community/<handle> style add link
}

ExtensionBundle { extensionId, version, manifest, uiBundleRef, cards, routes, schemas, checksum }
```

The Main app calls `getLatestExtensionVersion` on open and `downloadExtensionBundle` when the local
copy is stale, so members always run the latest certified version without a manual reinstall.

### 2.2 Community Extension Runtime API

`CommunityExtensionRuntimeApi` — the bridge between the App Shell and extension UI. Redesigns the V1
runtime: `channelId → communityId`, `fanId → memberId`, adds `spaceId`/`route`/`launchContext`, and
upgrades event payloads from `Map<String,String>` to typed `Map<String,dynamic>`.

```dart
abstract class CommunityExtensionRuntimeApi {
  Future<CommunityExtensionSession> createSession({
    required String communityId, String? spaceId, required String extensionId,
    required String surface, required String memberId, String? route,
    Map<String, dynamic>? launchContext, required String idempotencyKey,
  });
  Future<ExtensionActionResult> invokeAction({
    required String sessionId, required String action,
    required Map<String, dynamic> input, required String idempotencyKey,
  });
  Future<ExtensionEventAck> submitEvent({
    required String sessionId, required String type,
    required Map<String, dynamic> payload, required String idempotencyKey,
  });
  Future<ExtensionStateExport> exportState({
    required String communityId, required String extensionId, String? memberId, String? spaceId,
  });
}
```

```ts
CommunityExtensionSession {
  sessionId, communityId, spaceId, extensionId, version, surface, route, memberId,
  allowedPermissions, launchContext, createdAt, expiresAt
}
```

Example session payload:

```json
{
  "sessionId": "sess_123",
  "communityId": "comm_soccer",
  "spaceId": "team_u12",
  "extensionId": "com.loom.community.soccer-club",
  "memberId": "mem_parent_1",
  "surface": "community.onboarding",
  "route": "/registration",
  "allowedPermissions": [
    "community.events.read", "community.forms.submit",
    "community.payments.create_intent", "community.notifications.read"
  ],
  "launchContext": { "source": "invite", "inviteId": "inv_123" }
}
```

### 2.3 Extension Data Schema API

`ExtensionDataSchemaApi` — let extensions define custom portable entity types without bypassing Loom
storage, permissions, audit, or export. Even extension-specific data must be exportable, or Loom
recreates app lock-in.

```dart
abstract class ExtensionDataSchemaApi {
  Future<ExtensionEntitySchema> registerSchema({
    required String communityId, required String extensionId,
    required ExtensionEntitySchema schema, required String idempotencyKey,
  });
  Future<ExtensionEntityRecord> createRecord({
    required String communityId, required String extensionId, required String entityType,
    required Map<String, dynamic> data, required String idempotencyKey,
  });
  Future<ExtensionEntityRecord> updateRecord({
    required String communityId, required String extensionId, required String recordId,
    required Map<String, dynamic> patch, required String idempotencyKey,
  });
  Future<List<ExtensionEntityRecord>> queryRecords({
    required String communityId, required String extensionId,
    required String entityType, required Map<String, dynamic> query,
  });
}
```

Example extension records: `SoccerPlayer`, `SoccerTeam`, `MatchLineup`, `HOAProperty`,
`ArchitecturalRequest`, `PrayerRequest`, `RamadanIftarSlot`, `TennisLadderChallenge`,
`BookSelectionCycle`, `TradingListing`, `VolunteerShift`.

### 2.4 Event Bus API

`CommunityEventBusApi` — publish, subscribe, replay, inspect, and audit community events. Every
meaningful action emits a typed event. (Event families are listed in [§6](#6-event-families).)

```ts
publishEvent(communityId, event)
subscribeExtension(communityId, extensionId, eventTypes)
listEvents(communityId, filters)
getEvent(eventId)
replayEvents(communityId, fromCursor, toCursor)
getEventSchema(eventType)
```

Example event:

```json
{
  "eventId": "evt_456",
  "type": "payment.succeeded",
  "communityId": "comm_soccer",
  "memberId": "mem_parent_1",
  "occurredAt": "2026-06-08T18:15:00Z",
  "payload": {
    "paymentIntentId": "pi_123",
    "purpose": "season_registration",
    "amountCents": 25000,
    "relatedResource": { "type": "registration", "id": "reg_789" }
  }
}
```

### 2.5 Extension Rules API

`ExtensionRulesApi` — install, enable, disable, inspect, and execute declarative event/time-based
automations (Level 2 of backend extensibility).

```dart
abstract class ExtensionRulesApi {
  Future<RuleDefinition> installRule({
    required String communityId, required String extensionId,
    required RuleDefinition rule, required String idempotencyKey,
  });
  Future<List<RuleDefinition>> listRules({
    required String communityId, String? extensionId, String? triggerEventType,
  });
  Future<RuleDefinition> enableRule({
    required String communityId, required String ruleId, required String idempotencyKey,
  });
  Future<RuleDefinition> disableRule({
    required String communityId, required String ruleId, required String reason,
    required String idempotencyKey,
  });
  Future<RuleExecutionLog> getRuleExecutionLog({
    required String communityId, required String ruleExecutionId,
  });
}
```

Rule shape (event-condition-action):

```yaml
ruleId: payment-unlocks-registration
trigger:
  event: payment.succeeded
condition:
  all:
    - equals: ["event.payload.purpose", "season_registration"]
actions:
  - type: workflow.transition
    workflowInstanceId: "{{event.payload.relatedResource.workflowInstanceId}}"
    transition: "payment_received"
  - type: notification.send
    to: "{{event.memberId}}"
    template: "registration-paid"
```

### 2.6 Extension Workflow API

`ExtensionWorkflowApi` — install and run stateful state machines (Level 3): registration,
architectural review, score disputes, care requests, volunteer onboarding.

```dart
abstract class ExtensionWorkflowApi {
  Future<WorkflowDefinition> installWorkflow({
    required String communityId, required String extensionId,
    required WorkflowDefinition workflow, required String idempotencyKey,
  });
  Future<WorkflowInstance> startWorkflow({
    required String communityId, required String workflowId,
    required Map<String, dynamic> input, required String idempotencyKey,
  });
  Future<WorkflowInstance> transitionWorkflow({
    required String communityId, required String workflowInstanceId,
    required String transition, required Map<String, dynamic> input, required String idempotencyKey,
  });
  Future<List<WorkflowInstance>> listWorkflowInstances({
    required String communityId, String? workflowId, String? state,
  });
}
```

```ts
WorkflowInstance {
  workflowInstanceId, communityId, extensionId, workflowId, entityRef, state,
  assignedMemberIds, assignedRoleIds, dueAt, timeline, createdAt, updatedAt
}
```

### 2.7 Extension Jobs API

`ExtensionJobsApi` — time-based jobs (Level 3.5): reminders, recurring invoices, daily prayer/service
posts, league updates, digest generation.

```dart
abstract class ExtensionJobsApi {
  Future<ScheduledJob> createScheduledJob({
    required String communityId, required String extensionId, required String schedule,
    required String action, required Map<String, dynamic> input, required String idempotencyKey,
  });
  Future<ScheduledJob> pauseJob({ required String communityId, required String jobId, required String reason });
  Future<ScheduledJob> resumeJob({ required String communityId, required String jobId });
  Future<void> deleteJob({ required String communityId, required String jobId });
  Future<List<ScheduledJobRun>> listJobRuns({ required String communityId, required String jobId });
}
```

Examples: daily 9 AM remind HOA committee about overdue cases; every 15 min find events starting in
2 h and send reminders; weekly Sunday 7 PM generate book-club digest; daily Ramadan 4 PM send iftar
reminder; monthly day 1 generate HOA dues invoices.

### 2.8 Sandboxed Functions API

`ExtensionFunctionsApi` — run certified, sandboxed functions (Level 4) for calculations, ranking,
scheduling, eligibility, dispute scoring, custom reports — only when declarative logic is insufficient.

```ts
publishFunction(communityId, extensionId, functionBundle)
invokeFunction(communityId, extensionId, functionName, input)
listFunctionRuns(communityId, extensionId, filters)
getFunctionRunLog(communityId, functionRunId)
disableFunction(communityId, extensionId, functionName, reason)
```

Examples: `calculateSoccerStandings()`, `calculateTennisLadderRankings()`, `optimizeFieldSchedule()`,
`calculateHOALateFees()`, `assignVolunteerShifts()`, `scoreMarketplaceTrustRisk()`,
`generateBookReadingSchedule()`.

Sandbox rules: no raw database access; no unrestricted network access; all mutations through Loom
APIs; time/memory/CPU limits; secrets only through the Secrets API; all runs logged; all outputs
exportable; versioned and deterministic where possible.

Example:

```ts
export async function calculateStandings(input, loom) {
  const matches = await loom.sports.matches.list({ seasonId: input.seasonId, status: "final" });
  const table = computeSoccerTable(matches, {
    winPoints: 3, drawPoints: 1, lossPoints: 0,
    tieBreakers: ["goalDifference", "goalsFor", "headToHead"]
  });
  return { standings: table };
}
```

### 2.9 Extension Secrets / Connector API

`ExtensionSecretsApi` — store and rotate credentials for external connectors.

```dart
abstract class ExtensionSecretsApi {
  Future<SecretRef> createSecret({
    required String communityId, required String extensionId,
    required String name, required SecretPurpose purpose,
  });
  Future<void> rotateSecret({ required String communityId, required String extensionId, required String secretId });
  Future<List<SecretRef>> listSecrets({ required String communityId, required String extensionId });
}
```

| Use case | Secret |
| --- | --- |
| Livestream integration | YouTube/Vimeo/RTMP token |
| Email provider | SendGrid/Mailgun key |
| Payments provider | Stripe connected account |
| Sports federation sync | External league API credential |
| HOA accounting sync | QuickBooks/Xero token |

### 2.10 Extension certification tiers

Not every extension has the same trust level. Generalizes the V1 `riskTier`/`certificationState`.

| Tier | Capabilities | Example |
| --- | --- | --- |
| **0: Theme/template** | No backend mutations. | Book-club home layout. |
| **1: Read-only** | Read posts/events/docs/members. | Custom dashboard. |
| **2: Member actions** | Create RSVPs, posts, comments, listings. | Book voting, trading listings. |
| **3: Admin workflows** | Forms, approvals, roles, rules, notifications. | HOA architectural review. |
| **4: Payments/youth/sensitive** | Payments, donations, minors, private care cases. | Soccer registration, mosque giving, church care. |
| **5: External connectors/functions** | Webhooks, secrets, sandboxed code. | Accounting sync, federation sync. |

### 2.11 Extension Certification & Validation API

`CommunityExtensionCertificationApi` — validate and certify an extension package before install.
**Required in the MVP** because the AI Skill auto-generates packages (see
[Product Definition §7.2](./Extensible%20Loom%20Product%20Definition.md#72-ai-builder--the-skill-is-in-the-mvp));
you cannot safely install an AI-authored package without it.

```ts
validatePackage(packageRef)                 // returns ValidationReport (pass/fail per check)
certifyPackage(packageRef, validationId)    // assigns a riskTier + CertificationState
getCertification(extensionId, version)
revokeCertification(extensionId, version, reason)
```

```ts
ValidationReport {
  packageRef
  passed
  checks                // one result per area below
}
```

Validation areas (each must pass; see also the package-format checks in [§7](#validation-checks-loom-runs-on-a-package)):
schema correctness, permission minimization, data portability, UI safety (no spoofed payment/security
screens), rule safety (no spam / over-broad mutation), workflow safety (no bypassed approvals),
payment safety (no charges without explicit consent), minor safety, secrets safety (no hardcoded
keys), **ad integrity** (the package neither removes/hides/restyles shell ad surfaces nor drops
injected in-stream `StreamItem{kind:ad}` items — see [§1.18](#118-ads--ad-off-api)), and bounded
performance. **Soft lint** (warning, not a hard gate — the pattern is primarily Skill-enforced): the
extension declares a navigation panel exposing Messages + Connections and keeps both core shells
reachable ([§1.5](#15-app-shell--cards--routes--navigation-api)).

---

## 3. Domain APIs

Built mostly from the core primitives, but Loom provides first-class templates because these verticals
share strong common patterns.

### 3.1 Sports, Team, League, Match, Stats & Officials APIs

- `SportsClubApi` — programs, seasons, age groups, eligibility.
- `TeamRosterApi` — teams, rosters, guardians, coaches.
- `LeagueApi` — divisions, fixtures, standings, rules.
- `MatchGameApi` — matches, scoring, status, disputes.
- `SportsStatsApi` — player/team stats.
- `OfficialsApi` — referee/umpire assignment.

```ts
createSportsProgram(communityId, program)
createSeason(communityId, season)
createAgeGroup(seasonId, ageGroup)
setEligibilityRules(seasonId, rules)
createTeam(seasonId, team)
assignCoach(teamId, memberId)
addRosterMember(teamId, memberId, rosterProfile)
removeRosterMember(teamId, memberId)
setGuardianContact(playerMemberId, guardianMemberId)
createLeague(communityId, league)
createDivision(leagueId, division)
generateFixtures(divisionId, constraints)
publishSchedule(leagueId)
calculateStandings(leagueId)
overrideStandings(leagueId, reason)
createMatch(divisionId, match)
assignOfficial(matchId, officialMemberId)
startMatch(matchId)
recordScoreEvent(matchId, scoreEvent)
submitFinalScore(matchId, score)
confirmScore(matchId, memberId)
disputeScore(matchId, dispute)
finalizeMatch(matchId)
defineStatSchema(sport, schema)
recordStat(matchId, stat)
getPlayerStats(memberId, filters)
getTeamStats(teamId, filters)
```

### 3.2 Religious community APIs

- `ReligiousServiceApi` — services, prayers, liturgy, classes.
- `TeachingArchiveApi` — sermons, khutbahs, lectures, transcripts, series.
- `ReligiousGivingApi` — funds, zakat/sadaqah/tithes/donations.
- `CareRequestApi` — sensitive pastoral/spiritual/community care.
- `VolunteerMinistryApi` — volunteer roles and rotations.

```ts
createServiceSchedule(communityId, schedule)
publishServiceEvent(communityId, service)
attachTeachingContent(serviceId, contentRef)
createTeachingSeries(communityId, series)
publishTeaching(communityId, teaching)
createGivingFund(communityId, fund)
submitCareRequest(communityId, request)
assignCareTeam(careCaseId, memberIds)
scheduleCareFollowUp(careCaseId, event)
createVolunteerRole(communityId, role)
publishVolunteerShift(communityId, shift)
signUpForVolunteerShift(shiftId, memberId)
checkInVolunteer(shiftId, memberId)
```

Sensitive-data rule: care requests, youth data, donor details, counseling notes, and safety issues
are stored in protected visibility classes with explicit permission boundaries. General admins may
see aggregate fund totals; donor-identifiable records require a treasurer/finance role and explicit
policy.

---

## 4. Stable surfaces

Loom defines stable surfaces that extensions mount into; this gives extensions flexibility while
keeping the shell navigable.

```text
community.card        community.home        community.onboarding
community.admin       community.settings

space.home   space.feed   space.chat   space.members   space.documents

event.detail   event.registration   event.check_in

member.profile   member.directory

facility.detail   facility.booking

payment.dues   payment.donation   payment.ticket

interactions.home   interactions.chat   interactions.forum   interactions.feed
connections.home

ad.shell_banner   ad.playback_preroll   ad.playback_midroll
# interaction-stream ads are not surfaces — they are injected as StreamItem{kind:ad} (§1.18)

case.detail   workflow.task

sports.team   sports.roster   sports.match   sports.standings   sports.league

marketplace.listing   marketplace.checkout

document.viewer   document.editor
```

---

## 5. Capability permission catalog

Permissions are scoped capabilities, never generic (`read_all`/`write_all`/`admin`). The extension
receives the [effective intersection](#13-role-permission-policy--consent-api) of requested,
admin-approved, role, consent, and platform-safety permissions. This is what prevents a soccer
extension from reading donor details, a marketplace extension from reading youth rosters, or a
book-club extension from sending global emergency alerts.

```text
community.profile.read              community.profile.write

community.members.read              community.members.invite
community.members.approve           community.members.assign_role

community.spaces.read               community.spaces.write

community.posts.read                community.posts.write           community.posts.moderate

community.events.read               community.events.write
community.events.rsvp               community.events.check_in

community.forms.submit              community.forms.review

community.payments.create_intent    community.payments.read_summary  community.payments.refund

community.donations.create          community.donations.read_aggregate
community.donations.read_donor_detail

community.facilities.read           community.facilities.reserve     community.facilities.approve_reservation

community.rules.install             community.rules.execute          community.rules.read_logs
community.workflows.install         community.workflows.transition

community.notifications.send_member community.notifications.send_space  community.notifications.send_all

community.sensitive_cases.read      community.minors.read
community.audit.read                community.export.create
```

---

## 6. Event families

```text
community.*   member.*    space.*       post.*        thread.*      message.*
event.*       rsvp.*      form.*        poll.*        vote.*
payment.*     dues.*      donation.*    facility.*    reservation.*
document.*    case.*      task.*        marketplace.*
sports.*      league.*    match.*
notification.* moderation.* audit.*     extension.*
```

---

## 7. Extension package file format

A Loom community extension is a package, not just a prompt.

```text
my-soccer-club-extension/
  loom.extension.json
  ui/
    index.html
    bundle.js
    assets/
  routes/        home.route.json  team.route.json  match.route.json  standings.route.json
  cards/         community-card.json  upcoming-match-card.json
  rules/         welcome-new-player.rule.yaml  payment-unlocks-roster.rule.yaml  game-reminder.rule.yaml
  workflows/     player-registration.workflow.yaml  field-reservation.workflow.yaml  score-dispute.workflow.yaml
  schemas/       player.schema.json  team.schema.json  match.schema.json  facility.schema.json
  permissions/   permission-manifest.json
  fixtures/      youth-soccer.json
  tests/         extension.test.yaml
  docs/          README.md
```

### `loom.extension.json`

```json
{
  "extensionId": "com.loom.community.soccer-club",
  "name": "Soccer Club OS",
  "version": "1.0.0",
  "category": "sports_club",
  "description": "Custom soccer club experience for teams, leagues, parents, coaches, matches, facilities, dues, and announcements.",
  "runtime": { "uiType": "webview", "entrypoint": "ui/index.html", "minShellVersion": "1.0.0" },
  "surfaces": [
    "community.home", "community.card", "space.team", "event.match",
    "facility.booking", "member.profile", "admin.dashboard"
  ],
  "permissions": [
    "community.members.read", "community.members.write", "community.events.read",
    "community.events.write", "community.payments.read", "community.facilities.reserve",
    "community.notifications.send", "community.rules.install"
  ],
  "eventSubscriptions": [
    "community.member.joined", "payment.succeeded", "event.rsvp.updated",
    "match.score.finalized", "facility.reservation.requested"
  ],
  "exportBehavior": { "portable": true, "exportsState": true, "exportsSchemas": true },
  "riskTier": "medium",
  "certification": { "requiresReview": true, "requiresSecurityScan": true }
}
```

### Generated-artifact table (what an AI Skill outputs)

| Artifact | Contains |
| --- | --- |
| `loom.extension.json` | Name, category, version, surfaces, routes, permissions, event subscriptions, schemas, rules, workflows, export behavior. |
| `cards/*.json` | Community home cards and mini status cards. |
| `routes/*.json` | App routes and required permissions. |
| `ui/` | WebView app, declarative UI, or generated frontend bundle. |
| `schemas/*.json` | Custom data models. |
| `rules/*.yaml` | Event/time automations. |
| `workflows/*.yaml` | Stateful processes. |
| `jobs/*.yaml` | Scheduled jobs. |
| `functions/*.ts` | Optional sandboxed calculations. |
| `permissions/*.json` | Required capabilities and risk explanation. |
| `fixtures/*.json` | Sample data for simulation. |
| `tests/*.yaml` | Validation tests. |
| `export-policy.json` | What data is portable, private, sensitive, or retained. |

### Validation checks Loom runs on a package

| Area | Examples |
| --- | --- |
| Schema correctness | Manifest matches the extension spec. |
| Permission minimization | Not asking for too much. |
| Data portability | All extension data exportable. |
| UI safety | No spoofing of payment/security screens. |
| Rule safety | No member spam, no over-broad mutation. |
| Workflow safety | No bypassing approvals. |
| Payment safety | No charges without explicit consent. |
| Minor safety | No incorrect exposure of youth data. |
| Secrets safety | No hardcoded API keys. |
| Performance | Jobs/rules are bounded. |

### The Skill & extension builder SDK

The **AI Skill that emits these packages is an MVP deliverable** (see
[Product Definition §7.2 / §9](./Extensible%20Loom%20Product%20Definition.md#72-ai-builder--the-skill-is-in-the-mvp)).
The fuller `loom-community-extension-sdk` / `loomx` CLI tooling below is a fast-follow — the Skill
ships first, the polished local CLI later.

OpenAPI specs, TypeScript client, optional Dart client, JSON schemas (manifest/rules/workflows/cards/
routes), component library, local simulator, test runner, certification CLI, example extensions.

```bash
loomx create soccer-club
loomx validate
loomx simulate --community fixtures/youth-soccer.json
loomx certify
loomx package
loomx publish
```

---

## 8. Worked vertical examples

Each example lists the headline routes, schemas, and a representative rule/workflow. These illustrate
how the same primitives compose into very different experiences.

### 8.1 Youth soccer club

Routes: `/home /onboarding /registration /registration/:id /waivers /dues /teams /team/:id
/team/:id/chat /team/:id/roster /team/:id/schedule /players/:id /coaches /schedule /practices/:id
/matches/:id /matches/:id/live /matches/:id/score /standings /fields /fields/:id
/field-reservations/:id /referees /volunteers /documents /admin /admin/season /admin/teams
/admin/registration /admin/fields`

Schemas: `SoccerSeason SoccerProgram AgeGroup PlayerProfile GuardianConsent PlayerRegistration
MedicalDisclosure WaiverSignature Team RosterAssignment CoachProfile PracticePlan Match MatchScore
ScoreDispute LeagueDivision StandingRow FieldReservation RefereeAssignment VolunteerShift
ScholarshipRequest`

Player-registration workflow:

```yaml
workflowId: player-registration
entity: PlayerRegistration
startWhen: { event: form.submitted, formType: player_registration }
states:
  started:
    transitions:
      - { to: guardian_link_required, when: guardian.notLinked }
      - { to: waiver_pending, when: guardian.linked }
  guardian_link_required:
    transitions: [{ to: waiver_pending, when: guardian.linked }]
  waiver_pending:
    transitions: [{ to: payment_pending, when: waiver.signed }]
  payment_pending:
    transitions:
      - { to: scholarship_review, when: scholarship.requested }
      - { to: eligibility_review, when: payment.succeeded }
  scholarship_review:
    assignedRole: registrar
    transitions:
      - { to: eligibility_review, when: scholarship.approved }
      - { to: payment_pending, when: scholarship.denied }
  eligibility_review:
    assignedRole: registrar
    transitions:
      - { to: ready_for_team_assignment, when: registrar.approved }
      - { to: needs_correction, when: registrar.needs_info }
  ready_for_team_assignment:
    assignedRole: registrar
    transitions: [{ to: assigned, when: team.assigned }]
  assigned:
    onEnter:
      - { type: community.space.addMember, spaceId: "{{team.spaceId}}", memberId: "{{guardian.memberId}}" }
      - { type: notification.send, to: "{{guardian.memberId}}", template: player_assigned }
      - { type: audit.record, category: sports.registration.assigned }
```

Match-day standings rule + function:

```yaml
ruleId: score-finalized-updates-standings
trigger: { event: match.score.finalized }
actions:
  - { type: function.invoke, function: calculateSoccerStandings, input: { leagueId: "{{event.payload.leagueId}}" } }
  - { type: post.create, spaceId: "{{event.payload.teamSpaceId}}", template: match_recap }
  - { type: notification.send, toSpace: "{{event.payload.teamSpaceId}}", template: final_score_posted }
```

```ts
calculateSoccerStandings({
  leagueId, winPoints: 3, drawPoints: 1, lossPoints: 0,
  tieBreakers: ["points", "goalDifference", "goalsFor", "headToHead"]
})
```

Field-reservation workflow:

```yaml
workflowId: field-reservation
states:
  requested:
    onEnter:
      - { type: reservation.detectConflict }
      - { type: notification.send, toRole: facility_manager }
    transitions:
      - { to: approved, when: facility_manager.approved }
      - { to: denied, when: facility_manager.denied }
      - { to: alternative_requested, when: conflict.detected }
  alternative_requested:
    transitions: [{ to: requested, when: coach.submitted_alternative }]
  approved:
    onEnter:
      - { type: event.create, eventType: practice }
      - { type: notification.send, toSpace: "{{team.spaceId}}" }
```

### 8.2 HOA / condo / neighborhood association

Routes: `/home /onboarding /property /dues /invoices/:id /announcements /documents /board
/board/meetings /board/minutes/:id /architectural-review /architectural-review/new
/architectural-review/:caseId /maintenance /maintenance/new /maintenance/:caseId /violations
/violations/:caseId /votes /vendors /reservations /admin /admin/properties /admin/dues
/admin/committees /admin/workflows`

Schemas: `HOAProperty HouseholdOccupancy BoardSeat CommitteeAssignment DuesPlan ArchitecturalRequest
MaintenanceRequest ViolationNotice ViolationAppeal VendorProfile BoardMeetingAgenda
BoardMeetingMinutes ReserveProject AmenityReservation`

Dues jobs + rule:

```yaml
jobId: generate-quarterly-dues
schedule: "quarterly on day 1 at 08:00"
action: { type: dues.generateInvoices, duesPlanId: quarterly_hoa_dues }
---
jobId: overdue-dues-reminder
schedule: "daily at 09:00"
action: { type: dues.sendOverdueReminders, olderThan: P15D }
---
ruleId: payment-updates-dues-status
trigger: { event: payment.succeeded }
condition: { all: [ { equals: ["event.payload.purpose", "hoa_dues"] } ] }
actions:
  - { type: invoice.markPaid, invoiceId: "{{event.payload.relatedResource.id}}" }
  - { type: receipt.issue, paymentId: "{{event.payload.paymentIntentId}}" }
  - { type: notification.send, to: "{{event.memberId}}", template: hoa_dues_receipt }
```

Architectural-review workflow:

```yaml
workflowId: hoa-architectural-review
entity: ArchitecturalRequest
startWhen: { event: form.submitted, formType: architectural_request }
states:
  submitted:
    onEnter:
      - { type: case.create, caseType: architectural_review, visibility: committee }
      - { type: task.create, assigneeRole: architectural_committee, dueIn: P14D }
      - { type: notification.send, toRole: architectural_committee, template: new_architectural_request }
    transitions: [{ to: under_review, when: committee.accepted }]
  under_review:
    timeout: P14D
    onTimeout: [{ type: notification.send, toRole: board, template: architectural_review_overdue }]
    transitions:
      - { to: needs_info, when: committee.requested_info }
      - { to: approved, when: vote.result == approved }
      - { to: denied, when: vote.result == denied }
  needs_info:
    onEnter: [{ type: notification.send, to: requester, template: additional_info_needed }]
    transitions: [{ to: under_review, when: requester.resubmitted }]
  approved:
    onEnter:
      - { type: document.generate, template: architectural_approval_letter }
      - { type: notification.send, to: requester, template: architectural_approved }
      - { type: audit.record, category: hoa.architectural.approved }
  denied:
    onEnter:
      - { type: document.generate, template: architectural_denial_letter }
      - { type: notification.send, to: requester, template: architectural_denied }
      - { type: audit.record, category: hoa.architectural.denied }
```

Maintenance-ticket workflow: `submitted → triage → vendor_assigned → work_completed → closed`
(also covers the building/apartment maintenance case — see 8.9).

### 8.3 Mosque

Routes: `/home /prayer-times /jumuah /events /ramadan /ramadan/iftar /ramadan/volunteers /donations
/donations/:fundId /classes /classes/:classId /youth /announcements /khutbahs /khutbahs/:teachingId
/care-requests /care-requests/new /volunteers /volunteers/:shiftId /admin /admin/schedule /admin/funds
/admin/classes /admin/volunteers`

Schemas: `PrayerSchedule JumuahSchedule KhutbahTeaching RamadanProgram IftarSignup DonationFund
ZakatRequest ClassEnrollment YouthGuardianConsent VolunteerRole VolunteerShift CareRequest
CareFollowUp BoardAnnouncement`

Ramadan iftar rule + donation receipt rule:

```yaml
ruleId: ramadan-iftar-reminder
trigger: { schedule: "daily at 16:00" }
condition: { all: [ { extensionCalendarContains: { calendar: ramadan, date: today } } ] }
actions:
  - { type: notification.send, to: volunteers.assignedToday, template: iftar_shift_reminder }
  - { type: notification.send, toSpace: ramadan, template: iftar_public_reminder }
---
ruleId: donation-receipt
trigger: { event: payment.succeeded }
condition: { all: [ { equals: ["event.payload.purpose", "donation"] } ] }
actions:
  - { type: receipt.issue, paymentId: "{{event.payload.paymentIntentId}}" }
  - { type: notification.send, to: "{{event.memberId}}", template: donation_receipt_private }
```

Funds: General, Masjid operations, Zakat, Sadaqah, Ramadan meals, Youth programs, Building, Emergency relief.

Private care-request workflow (sensitive — care-team-only visibility, redacted audit):

```yaml
workflowId: private-care-request
startWhen: { event: form.submitted, formType: care_request }
states:
  submitted:
    onEnter:
      - { type: case.create, caseType: care_request, visibility: care_team_only, sensitive: true }
      - { type: notification.send, toRole: care_team_lead, template: new_private_care_request }
    transitions: [{ to: assigned, when: care_team_lead.assigned }]
  assigned:
    transitions: [{ to: follow_up_scheduled, when: follow_up.created }]
  follow_up_scheduled:
    transitions: [{ to: closed, when: care_team.closed }]
  closed:
    onEnter: [{ type: audit.record, category: religious.care_request.closed, redactSensitivePayload: true }]
```

### 8.4 Book club

Routes: `/home /current-book /current-book/chapters /current-book/chapter/:id /nominations /vote
/reading-schedule /events /notes /archive /members /admin`

Schemas: `Book BookNomination ReadingCycle ReadingSchedule ChapterDiscussion ReadingProgress
SpoilerTag MeetingNotes AuthorVisit`

Book-selection workflow + spoiler rule:

```yaml
workflowId: book-selection-cycle
states:
  nominations_open:
    transitions: [{ to: voting_open, when: nomination.deadline_reached }]
  voting_open:
    transitions: [{ to: selected, when: poll.closed }]
  selected:
    onEnter:
      - { type: function.invoke, function: generateReadingSchedule }
      - { type: post.create, template: selected_book_announcement }
      - { type: event.create, eventType: book_meeting }
---
ruleId: hide-spoiler-content
trigger: { event: thread.reply.created }
condition: { all: [ { resourceHasField: { field: spoilerChapter } } ] }
actions: [{ type: policy.applyVisibility, policy: chapter_progress_required }]
```

Meeting AI summary: `CommunityEventsApi.checkIn` → `CommunityAiApi.generateMeetingMinutes` →
`CommunityPublishingApi.createPost` → `CommunityNotificationApi.sendNotification`.

### 8.5 Tennis club + ladder

Routes: `/home /courts /courts/:id /reserve /reservations/:id /ladder /ladder/challenge /matches/:id
/score/:id /classes /classes/:id /coaches /guest-passes /admin`

Schemas: `Court CourtReservation MemberRating Ladder LadderChallenge TennisMatch TennisScore GuestPass
CoachClass CoachingPackage`

Ladder-challenge workflow (24h dispute window, auto-finalize on timeout):

```yaml
workflowId: tennis-ladder-challenge
states:
  challenge_sent:
    transitions:
      - { to: scheduled, when: challenged_player.accepted }
      - { to: declined, when: challenged_player.declined }
  scheduled:
    transitions: [{ to: score_pending, when: match.completed }]
  score_pending:
    transitions: [{ to: confirmation_pending, when: score.submitted }]
  confirmation_pending:
    timeout: P1D
    onTimeout: [{ type: match.finalizeScore }]
    transitions:
      - { to: finalized, when: opponent.confirmed }
      - { to: disputed, when: opponent.disputed }
  finalized:
    onEnter:
      - { type: function.invoke, function: calculateTennisLadderRanking }
      - { type: notification.send, toSpace: ladder, template: ladder_updated }
```

### 8.6 Local trading / Buy Nothing

Routes: `/home /listings /listings/new /listings/:id /requests /offers /borrow /lend /pickups
/pickups/:handoffId /rules /moderation /admin`

Schemas: `TradingListing ListingClaim PickupWindow Handoff NoShowReport TrustSignal
NeighborhoodVerification BorrowAgreement`

Listing-handoff workflow:

```yaml
workflowId: listing-handoff
states:
  open:
    transitions: [{ to: claimed, when: giver.selected_recipient }]
  claimed:
    onEnter: [{ type: conversation.create, participants: ["giver", "recipient"] }]
    transitions: [{ to: pickup_scheduled, when: pickup.window_confirmed }]
  pickup_scheduled:
    transitions:
      - { to: completed, when: handoff.confirmed }
      - { to: no_show_reported, when: no_show.reported }
  no_show_reported:
    transitions:
      - { to: moderator_review, when: moderator.required }
      - { to: open, when: giver.reopens_listing }
  completed:
    onEnter:
      - { type: marketplace.closeListing }
      - { type: audit.record, category: marketplace.handoff.completed }
```

Hyperlocal verification: `requestJoinCommunity` → `submitForm` (neighborhood verification) →
`verifyMember` → `assignRole`.

### 8.7 Nonprofit / volunteer organization

Routes: `/home /campaigns /campaigns/:id /volunteer /volunteer/shifts /volunteer/shifts/:id /donate
/items-needed /impact /announcements /admin`

Schemas: `Campaign VolunteerRole VolunteerShift ItemNeed ItemCommitment DonationFund BeneficiaryGroup
ImpactMetric CheckInRecord`

Food-drive flow: create campaign → event page → volunteer shifts → needed-items list → sign-ups →
reminders → check-in → impact report. Volunteer reminder:

```yaml
ruleId: volunteer-shift-reminder
trigger: { schedule: "every 15 minutes" }
condition: { all: [ { shiftStartsWithin: PT4H } ] }
actions: [{ type: notification.send, to: shift.assignedMembers, template: volunteer_shift_reminder }]
```

### 8.8 Parish / church

Routes: `/home /services /services/:id /sermons /sermons/:id /ministries /ministries/:spaceId
/volunteer /giving /classes /youth /care /care/new /documents /admin`

Schemas: `ServiceSchedule Sermon Ministry VolunteerRotation GivingFund PastoralCareRequest
ClassEnrollment YouthConsent SacramentalRecordRef`

Ministry volunteer-rotation (shift swap) workflow:

```yaml
workflowId: volunteer-shift-swap
states:
  assigned:
    transitions: [{ to: swap_requested, when: volunteer.requested_swap }]
  swap_requested:
    transitions:
      - { to: swap_approved, when: replacement.accepted }
      - { to: assigned, when: ministry_lead.denied }
  swap_approved:
    onEnter:
      - { type: volunteer.updateAssignment }
      - { type: notification.send, to: ministry_lead, template: shift_swap_complete }
```

### 8.9 Apartment / building community

Routes: `/home /announcements /maintenance /maintenance/new /maintenance/:caseId /amenities
/amenities/:facilityId /reserve /packages /move-in-out /documents /admin`

Schemas: `Unit ResidentProfile AmenityReservation MaintenanceTicket PackageNotification MoveInRequest
MoveOutRequest BuildingNotice VendorWorkOrder`

Building-maintenance workflow: `submitted → scheduled → completed → (closed | reopened)`.

---

## 9. Proposed Dart API file layout

Inside `loom_api_contracts`, split community support like this (clients shaped exactly like the
OpenAPI specs, consistent with the V1 contract-first demo):

```text
clients/community_registry_api.dart
clients/community_membership_api.dart
clients/community_role_policy_api.dart
clients/community_spaces_api.dart
clients/community_app_shell_api.dart

clients/community_extension_registry_api.dart
clients/community_extension_runtime_api.dart
clients/community_extension_data_schema_api.dart
clients/community_event_bus_api.dart
clients/community_rules_api.dart
clients/community_workflow_api.dart
clients/community_jobs_api.dart
clients/community_functions_api.dart
clients/community_secrets_api.dart
clients/community_certification_api.dart

clients/community_publishing_api.dart
clients/community_thread_api.dart
clients/community_messaging_api.dart
clients/community_notification_api.dart

clients/community_events_api.dart
clients/community_registration_api.dart
clients/community_ticketing_api.dart
clients/community_availability_poll_api.dart

clients/community_forms_api.dart
clients/community_polls_api.dart
clients/community_voting_api.dart

clients/community_case_api.dart
clients/community_task_api.dart
clients/community_approval_api.dart

clients/community_document_api.dart
clients/community_files_api.dart
clients/community_list_sheet_api.dart
clients/community_wiki_api.dart

clients/community_facilities_api.dart
clients/community_reservations_api.dart
clients/community_inventory_api.dart

clients/community_wallet_api.dart
clients/community_dues_api.dart
clients/community_donation_api.dart
clients/community_invoice_api.dart
clients/community_receipt_api.dart
clients/community_ads_api.dart
clients/community_vault_api.dart
clients/community_connections_api.dart

clients/community_marketplace_api.dart
clients/community_handoff_api.dart
clients/community_marketplace_safety_api.dart

clients/sports_club_api.dart
clients/team_roster_api.dart
clients/league_api.dart
clients/match_game_api.dart
clients/sports_stats_api.dart
clients/officials_api.dart

clients/religious_service_api.dart
clients/teaching_archive_api.dart
clients/religious_giving_api.dart
clients/care_request_api.dart
clients/volunteer_ministry_api.dart

clients/community_search_api.dart
clients/community_recommendation_api.dart
clients/community_ai_api.dart
clients/community_digest_api.dart

clients/community_trust_safety_api.dart
clients/community_audit_api.dart
clients/community_import_export_api.dart
clients/community_provider_transfer_api.dart

models/community_extensions/community_extension_manifest.dart
models/community_extensions/community_extension_install.dart
models/community_extensions/community_extension_session.dart
models/community_extensions/community_extension_card.dart
models/community_extensions/community_extension_route.dart
models/community_extensions/community_extension_rule.dart
models/community_extensions/community_extension_workflow.dart
models/community_extensions/community_extension_event.dart
models/community_extensions/community_extension_permission.dart
models/community_extensions/community_extension_schema.dart
models/community_extensions/community_extension_certification.dart
```

Update the central export file (which today exports the channel-based extension registry/runtime and
the creator/fan APIs) to include these new community extension APIs.

---

## 10. Community taxonomy and per-vertical user stories

The full category overview lives in the [product definition](./Extensible%20Loom%20Product%20Definition.md#8-community-taxonomy);
the detailed per-vertical user-story/workflow tables are retained here.

### Social, learning, and hobby communities

| Category | Examples |
| --- | --- |
| Book clubs | Neighborhood, online, religious reading group, children's, author-led. |
| Hobby clubs | Gardening, cooking, photography, hiking, sewing, maker, board games, gaming, robotics, language exchange. |
| Cultural communities | Diaspora groups, language/culture associations, ethnic groups, festival committees. |
| Learning communities | Study groups, tutoring circles, homeschool co-ops, parent education, professional learning groups. |
| Support communities | Caregiver, grief, health, recovery, new-parent groups. |

### Local civic and neighborhood communities

| Category | Examples |
| --- | --- |
| Neighborhood groups | Block group, neighborhood watch, emergency prep, local mutual aid (Nextdoor/Ring Neighbors style). |
| Local trading/gifting | Buy Nothing, tool libraries, swap groups, local resale, freecycling, borrowing/lending circles. |
| HOA / condo / co-op | HOA board, architectural review committee, maintenance committee, neighborhood/condo association. |
| Apartment/building | Resident groups, amenities booking, maintenance announcements, move-in/out coordination. |
| Local business associations | Chamber-like groups, merchant associations, business improvement groups. |

### Religious and nonprofit communities

| Category | Examples |
| --- | --- |
| Churches / parishes | Parish community, Sunday school, youth group, choir, Bible study, volunteer ministries. |
| Mosques | Jummah announcements, halaqa groups, youth programs, Ramadan calendar, zakat/sadaqah, volunteers. |
| Temples / synagogues / centers | Service schedules, religious school, study circles, donations, volunteer rotations, events. |
| Nonprofits | Volunteer groups, donor communities, campaign teams, local advocacy (CiviCRM-style member/event/giving). |

### Sports and facility communities

| Category | Examples |
| --- | --- |
| Sports clubs | Tennis, soccer, pickleball, cricket, basketball, running, martial-arts dojo. |
| Teams | Youth soccer, adult rec, school, travel, tournament teams. |
| Leagues | Tennis ladder, soccer/basketball/pickleball league, esports league. |
| Facilities | Courts, fields, gyms, clubhouses, training grounds, batting cages, multipurpose halls. |
| Camps/classes | Sports camps, religious classes, skill clinics, referee/coaching training. |

### Event-centered communities

| Category | Examples |
| --- | --- |
| Event collectives | Local meetup, speaker series, lecture group, festival/conference committee. |
| Volunteer/event crews | Food drives, charity tournaments, local cleanups, school events, fundraising dinners. |
| Hybrid/remote | Distributed book club, remote alumni group, global faith study group, online hobby circle. |

### Representative user stories (full set)

**Book club** — start a private club with monthly book voting and meetings; chapter-specific
spoiler-safe discussion; AI meeting summary for absentees.

**Hobby club** — seasonal meetups + resource sharing (spaces, posts, events, lists); Q&A threads with
pinned best answers feeding a knowledge base.

**Local trading/gifting** — give away an item with photo/condition/pickup, claim queue, recipient
selection, handoff confirmation; hyperlocal admin verification and moderation.

**HOA** — submit an architectural request with status tracking and committee comments; run a board
meeting with agenda/quorum/board-only votes/public minutes; collect dues with reminders and a
delinquency dashboard; report a maintenance issue with a ticket state machine and vendor role.

**Parish/church** — publish weekly service info with readings and calendar subscription; schedule
volunteers with shift swaps and no-show tracking; give and receive a tax receipt; confidential
pastoral-care requests with strict permissions and redacted audit.

**Mosque** — coordinate Ramadan programs (calendar, iftar signups, volunteers, reminders, donations);
manage youth classes with guardian consent and attendance.

**Temple/synagogue/center** — one hub for services/classes/giving/announcements with multi-program
structure; festival volunteer signup with capacity/waitlist/shift swaps.

**Tennis club** — reserve a court with conflict detection and cancellation policy; run a ladder with
ranking rules and disputes; organize paid group lessons with capacity/waitlist/refunds.

**Soccer club + teams + leagues + facilities** — register players for a season with waivers/payment/
scholarships and guardian model; manage practices/games with availability and reminders; run fixtures/
referees/scores/standings; live game updates and video; prevent field conflicts with blackout windows.

**Nonprofit/volunteer** — mobilize volunteers for a food drive with shifts/item commitments/check-in/
impact report; support a campaign and receive purpose-bound donor updates.

**Distributed online community** — hybrid events with replay and threaded follow-up; per-member
digest instead of constant notifications.

---

## 11. How verticals map back to common APIs

The same underlying APIs support many vertical experiences.

| API family | Soccer | HOA | Mosque | Book club | Tennis | Trading | Nonprofit |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Community registry | Yes | Yes | Yes | Yes | Yes | Yes | Yes |
| Membership/roles | Parent/player/coach | Homeowner/board/vendor | Member/imam/volunteer | Organizer/member | Player/coach | Giver/receiver | Volunteer/donor |
| Spaces | Teams/leagues | Board/committee | Youth/Ramadan/classes | Chapters/books | Ladder/courts | Listings | Campaigns |
| Events | Practices/games | Meetings | Services/classes | Meetings | Matches/classes | Pickups | Drives/shifts |
| Forms | Registration/waivers | Requests | Classes/care | Nominations | Classes | Join verification | Volunteer signup |
| Payments | Season fees | Dues | Donations | Event fees opt. | Court fees | Optional sales | Donations |
| Workflows | Registration, dispute | Review, maintenance | Care, volunteers | Selection cycle | Ladder challenge | Handoff | Campaign |
| Rules/jobs | Reminders | Dues/overdue | Ramadan reminders | Meeting digests | Ranking updates | No-show handling | Shift reminders |
| Facilities | Fields | Clubhouse | Rooms | Meeting room opt. | Courts | Pickup zones | Event spaces |
| AI | Recaps | Minutes | Khutbah summary | Book summaries | Match recap | Listing moderation | Impact reports |
| Audit | Waivers/payments | Votes/approvals | Donations/care access | Vote history | Scores/payments | Moderation | Donations |

---

## References

External benchmarks cited across the verticals: WhatsApp Communities, Discord forum channels,
Google Groups, Meetup/Mobilizon, EventMobi/Eventbrite, Google Workspace, CiviCRM, StoryGraph,
youth-sports automation platforms, Sportdata, GameChanger, ArbiterSports, Asoriba, Freecycle/Buy
Nothing, Nextdoor/Ring Neighbors. Builder-platform references for the AI Skill: OpenAI GPT Actions
& Apps SDK, Google Gems, Claude Skills.
