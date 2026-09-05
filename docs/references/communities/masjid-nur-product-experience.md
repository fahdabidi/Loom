# Masjid Nur Product Experience

> **Correction, 2026-08-10 (Community JSON Migration effort, `docs/Build Plan V2/Community JSON Migration
> Tracker.md` §3):** two bidirectional reconciliation gaps, confirmed by direct source read of the real
> implementation (`app/packages/core/loom_communities_app_shell/assets/
> Loom_Communities_Workflow_Engine_Mosque_Example.jsonc`, the actual JSON this community currently loads):
> - `mosque-document-resource` (documented below in §3/§5/§6/§7/card-surface-registry) **does not exist**
>   in the real implementation — none of its 9 real `workflowDefinitions` keys is `mosque-document-resource`.
>   This is a genuine product-spec gap, not an implementation bug: build it fresh from this doc's own
>   requirements when authoring the engine-native JSON (there is no legacy Dart/JSON version to reconcile
>   against for this one).
> - `mosque-discussion-thread` **is real and implemented** (`open ⇄ replied` reply cycle, admin-only
>   `archive-thread`, `tabId: "messages"`, `cardSurfaceFamily: "discussionThread"` — both already real) but
>   was never documented anywhere in this doc. Added as real rows to every table below.
>
> Total real, documented workflow count after this correction: **10** (8 already covered +
> `mosque-document-resource` as new product-spec work + `mosque-discussion-thread` newly documented).
>
> **Separately confirmed:** `wf_demo-app-persona-picker`, `wf_community-persona-aware-ux`, and
> `wf_multi-persona-workflow-evidence` (5 row instances across §6/§7/§9/card-surface-registry below) are
> **not real workflows at all** — they are literal Dart `testWidgets` names for this repo's B18/B19/B20
> integration tests (`app/apps/loom_communities_demo/test/b18_persona_picker_test.dart`,
> `b19_persona_aware_ux_test.dart`, `b20_multi_persona_workflow_evidence_test.dart`), which happen to use
> Masjid Nur (`ext_mosque`) as their test-subject community. No `LoomWorkflowDefinition` with any of these
> ids exists anywhere in the codebase. **Do not author engine-native JSON for any of these three** — the
> same category of mistake already found and corrected in Chess Club's doc (`chess-local-install-open`/
> `chess-route-home`). Left in place below per this tracker's standing "expand-only, never remove" rule, but
> should be read as test-infrastructure labels, not real workflow requirements.

## 1. Community Identity And Promise

| Field | Value |
| --- | --- |
| Community name | Masjid Nur |
| Community type | Mosque community |
| Product promise | Help admins and members coordinate announcements, events, donations, volunteers, and protected care requests. |
| Brand cues | Respectful mosque/community-care tone, green palette, giving/care/announcement cues. |
| What this must not feel like | A list of publish/receive workflows with generic cards and confirmation checklists. |

## 2. Personas, Roles, And Jobs

| Persona | Role/capabilities | Primary jobs-to-be-done | Sensitive constraints | Success state |
| --- | --- | --- | --- | --- |
| Masjid Admin | Publish announcements, coordinate events/volunteers, review care | Send trustworthy community updates and manage support. | Care requests and donations need privacy controls. | Update is sent; care/volunteer/donation state is accountable. |
| Community Member | Receive announcements, RSVP, donate, volunteer, request care | Know what is happening and participate safely. | Protected care details should be visible only to approved recipients. | Member sees relevant update, receipt, signup, or care status. |

## 3. Information Architecture

| Surface | Purpose | Primary persona | Required content | Primary action |
| --- | --- | --- | --- | --- |
| Masjid home | Current community life. | Member/admin | announcements, upcoming events/prayer/community updates, giving, volunteers, care. | Read update / donate / volunteer |
| Announcement compose/feed | Publish and receive updates. | Admin/member | body, sender, audience, timing, delivery/read state. | Publish / read |
| Masjid calendar | Coordinate events, classes, volunteer shifts, and reminders. | Admin/member | event/class title, date/time, location, recurrence, capacity, reminder state. | RSVP / add reminder |
| Documents and links | Open khutbah notes, forms, policies, or external resources. | Member/admin | document title, source, version/date, embedded/external open choice, access state. | Open document |
| Donation | Give with visibility controls. | Member | amount, fund, privacy, receipt. | Donate |
| Care request | Protected support request. | Member/admin | public summary, private fields, recipient state. | Submit / review |
| Volunteer signup | Coordinate help. | Member/admin | need, shift, capacity, signup state. | Volunteer |

## 3.1 Persona Tabs, Pins, And Customization

| Persona | Required tabs | Pinned surfaces | Customization notes |
| --- | --- | --- | --- |
| Community member | Home, Calendar, Giving, Resources, Messages | Friday service/iftar, donation receipt, care request status on Home, khutbah notes and cited answers in Resources | Calm green palette, prayer/community language, clear charitable and care privacy cues. Care remains a protected Home status surface rather than a separate tab. |
| Masjid admin | Home, Calendar, Giving, Resources, Admin, Messages | announcement composer, volunteer roster, donation status, care review | Admin exposes compose/review and protected care handoff state; Resources holds documents and curated answers. |

## 4. Home Screen Requirements

The first Masjid screen must feel like a community hub with announcements, events/updates, giving,
volunteer needs, and care. It must not be a global workflow list or generic repeated cards.

## 5. Domain-Native Product Surfaces

| Surface | Required visible content | Required states | Natural actions | Anti-patterns |
| --- | --- | --- | --- | --- |
| Announcement/feed | title/body, sender, audience, timing, channel, read state | draft/sent/read | publish, read | publish workflow card |
| Calendar | event/class title, date/time, location, recurrence, capacity, reminder | upcoming/RSVPed/full/cancelled | RSVP, change RSVP, add reminder, open linked volunteer shift | generic event chip |
| Documents/external links | title, source, version/date, access, open mode | available/read/acknowledged/access-requested | open embedded, launch external, download, acknowledge | hidden document link |
| Donation | amount, fund/purpose, privacy, receipt | pending/paid/failed | donate, view receipt | abstract payment chip |
| Care request | public summary, private details, recipient, privacy label | draft/submitted/assigned | submit, review | exposing protected details |
| Volunteer | role, shift, capacity, signup status | open/full/signed-up | volunteer, cancel | generic task card |

## 6. Workflow-To-Surface Mapping

| Workflow | Persona | Product surface | Required visible proof | Loom APIs/rules/events | Test/evidence IDs |
| --- | --- | --- | --- | --- | --- |
| mosque-announcement | Masjid admin / community member | Admin announcement composer; Home and Messages feed | title, body, sender, audience, channel, schedule/sent time, delivery/read counts and histories | `save-announcement-draft`, `preview-announcement`, `return-to-announcement-draft`, `schedule-announcement`, `publish-announcement`, `mark-announcement-read`, `archive-announcement`, `cancel-announcement`; members-only reads | B14/B20/B25 |
| mosque-event-rsvp | Community member / Masjid admin | Calendar event detail; Home summary; Admin draft | event/class title, literal eventDate/eventTime, location, recurrence, capacity, attendance counts, waitlist, reminder history | `save-event-draft`, `publish-event`, `rsvp-going`, `rsvp-maybe`, `rsvp-not-going`, `join-event-waitlist`, `cancel-rsvp`, `add-event-reminder`, `open-linked-volunteer-shift`, `cancel-event`; automatic 24-hour reminder | B14/B25 |
| mosque-document-resource | Community member / Masjid admin | Resources document and external-link detail | title, source, version/date, access label, embedded/external controls, acknowledgement/access/download/follow-up audit | link library using `resourceUrl` with `openMode: choice`; `record-resource-open`, `acknowledge-resource`, `mark-resource-unread`, `request-resource-access`, `save-resource`, `request-resource-follow-up`, `record-resource-download`, `archive-resource` | B14/B25 |
| mosque-volunteer-signup | Community member / Masjid admin | Home shift card; Admin coordination | role, shift date/time, location, capacity/open spots, signup/contact-consent and follow-up histories | `sign-up-volunteer`, `update-volunteer-availability`, `cancel-volunteer-signup`, `record-coordinator-follow-up`, `close-volunteer-shift` | B14/B25 |
| mosque-donor-visibility | Community member acting as donor | Giving donor-privacy preference | donor, amount/fund context, receipt visibility, preference history | donation-created row; `set-donor-public`, `set-donor-anonymous`, `set-donor-restricted`; donor-only guard | B14/B25 |
| mosque-donation-payment | Community member acting as payer / Masjid admin | Giving donation intent and receipt; Admin recording/refund queue; Home paid summary | amount, fund, privacy, recurring preference, payer, payment/receipt status and history | `submit-donation-intent`, `save-donation-changes`, `record-payment-failure`, `retry-donation`, `confirm-offline-donation`, `open-donation-receipt`, `manage-recurring-preference`, `request-donation-refund`, `record-donation-refund`, `decline-donation-refund`, `cancel-donation`; payment gateway remains a declared platform gap | B14/B25 |
| mosque-care-request | Community member / Masjid admin | Protected Home request/status; Admin review queue | public summary, protected details, privacy/contact preference, requester/reviewer, review/response fields and status history | `submit-care-request`, `request-care-changes`, `revise-care-request`, `approve-and-assign-care-request`, `reject-care-request`, `send-private-care-response`, `resolve-care-request`, `withdraw-care-request`; requester/owner parties visibility | B14/B25 |
| mosque-neutral-notification | Community member recipient | Messages inbox/detail; unread Home summary | sender, recipient/audience, privacy-safe body, created/read/kept-unread/follow-up time | `mark-notification-read`, `keep-notification-unread`, `mark-notification-unread`, `request-notification-follow-up`, `archive-notification`; recipient-scoped reads | B14/B25 |
| mosque-search-ai-citation | Community member / Masjid admin | Resources question, curated answer and citations | query/asker, curated or future AI answer, answer source/time, citation list/status, moderation/report history | `provide-curated-answer`, `refine-search-query`, `save-search-answer`, `hide-search-source`, `report-stale-citation`, `reopen-reported-question`; external AI answer and per-citation redaction remain typed gaps | B14/B25 |
| mosque-discussion-thread | Community member / Masjid admin | Messages discussion thread | title, initial/latest message, reply list/count/time, open/replied/archive state | `reply-thread`, `continue-thread`, `mute-thread`, `unmute-thread`, `archive-thread`; mute persistence remains a declared messaging-service gap | B25 |
| wf_demo-app-persona-picker | member | Persona switch support surface | available personas, current role, capability preview, disabled/hidden implications | App Shell/persona test harness | B18/B25 |
| wf_community-persona-aware-ux | admin | Persona-aware admin view | admin-capable workflow list, disabled/read-only member rows, role explanation | App Shell/role policy | B19/B25 |
| wf_community-persona-aware-ux | member | Persona-aware member view | member-capable workflow list, read-only/hidden admin rows, role explanation | App Shell/role policy | B19/B25 |
| wf_multi-persona-workflow-evidence | admin | Actor-to-receiver handoff | admin-created announcement state, persona switch path, receiver target | App Shell/events/persona test harness | B20/B25 |
| wf_multi-persona-workflow-evidence | member | Receiver handoff evidence | received announcement, sender/body/timestamp, read state, continuation action | App Shell/events/persona test harness | B20/B25 |

## 7. Persona And State Matrix

| Workflow | Actor state | Receiver state | Read-only state | Disabled/hidden state | Unauthorized behavior |
| --- | --- | --- | --- | --- | --- |
| mosque-announcement | Admin saves, previews, edits, schedules, publishes, archives or cancels | Member marks a sent announcement read on Home or Messages | Sent/read history and archived/cancelled Admin summary remain readable | Admin create/edit actions are guarded; publish requires a populated form | Community member cannot create, schedule, publish, archive or cancel |
| mosque-event-rsvp | Member chooses Going, Maybe, Not attending, Waitlist, Cancel RSVP, Add reminder, or Open volunteer shift; admin saves/publishes/cancels | Attendance/waitlist data and Home summary update; reminder sweep uses eventDate/eventTime | Open and cancelled event details remain readable | Going is blocked at capacity; waitlist is offered only at capacity; cancel RSVP requires an existing response | Non-member cannot respond; community member cannot cancel the event |
| mosque-document-resource | Member opens embedded/externally, records open/download, acknowledges, marks unread, saves, requests access/follow-up; admin archives | Admin can inspect audit-safe history | Source, version/date, access label and link remain readable while available | Restricted open/download/acknowledge require membership in allowedFanIds; request access is shown only when restricted | Non-member cannot use member actions; community member cannot archive |
| mosque-volunteer-signup | Member volunteers, edits availability or cancels; admin records follow-up or closes signup | Coordinator sees roster/count, contact-consent and history | Closed status and signup facts remain readable | Signup blocks at capacity; edit/cancel require an existing signup | Non-member cannot sign up; member cannot see a separate unrestricted contact directory or close the shift |
| mosque-donor-visibility | Donor changes among Public, Anonymous and Restricted | Receipt/public-roll treatment follows the saved state | Amount/fund and visibility history remain donor-readable | The currently selected option has no redundant transition | Anyone other than the donor cannot change or read the preference |
| mosque-donation-payment | Member creates/edits/submits intent, retries, views receipt, manages recurring preference, requests refund or cancels; admin records failure/offline payment/refund decision | Admin sees pending/refund queue; donor receives paid/refunded status and receipt summary | Paid Home summary and terminal Giving history remain readable to the parties | Retry is only from Failed; receipt/recurring/refund only after paid; online processor and opaque receipt remain unavailable | Non-payer cannot manage a donation; community member cannot record settlement/refund |
| mosque-care-request | Requester drafts, submits, revises, withdraws; reviewer requests changes, assigns, rejects, responds and resolves | Requester sees neutral status and private response; Admin sees the protected queue | Resolved/rejected/withdrawn status history remains readable only to requester/owner parties | General members cannot see protected rows; revise requires Changes requested | Non-requester cannot edit/withdraw; non-owner cannot review/assign/reject/respond/resolve |
| mosque-neutral-notification | Recipient marks read/unread, keeps unread, requests follow-up or archives | Sender-side delivery evidence is represented by the source care/announcement histories | Read and archived notice remains recipient-readable | Read-only actions vary by unread/read state | Non-recipient cannot read or act on an addressed notice |
| mosque-search-ai-citation | Member asks/refines/saves/reports; admin curates, hides a source or reopens | Members see curated answer/source and status; admin sees reported questions | Answered/report state remains members-readable | Curated answer is the honest live completion path; AI generation is not fabricated | Non-owner cannot curate/moderate; source-level redaction is not claimed as implemented |
| mosque-discussion-thread | Member/admin starts, replies or continues; admin archives; member/admin may request mute/unmute | Members see replies and latest-message state | Archived thread remains summary-only | Replies stop after archive; mute/unmute are visible placeholders pending the messaging service | Non-member cannot read/post; community member cannot archive |
| wf_demo-app-persona-picker | member chooses role | selected persona drives visible capabilities | role inventory readable | unavailable roles disabled | non-test builds hide test picker |
| wf_community-persona-aware-ux | admin sees owner/admin actions | member receives only permitted outputs | role policy readable | member-only rows hidden where required | unauthorized role cannot act |
| wf_community-persona-aware-ux | member sees member actions | admin receives submitted state where applicable | read-only admin rows explained | admin actions disabled/hidden | unauthorized role cannot act |
| wf_multi-persona-workflow-evidence | admin publishes handoff state | member receives announcement/read state | prior handoff state readable | publish disabled without body/audience | non-admin cannot create handoff |
| wf_multi-persona-workflow-evidence | member opens received state | admin sees delivery/read state | received announcement remains readable | receive action disabled after read | non-recipient hidden |

## 8. Content And Seed Data Requirements

Use realistic announcement body, sender/role, audience, delivery timing, event/class dates, document
titles/sources, donation amount/fund, receipt, volunteer shift/capacity, care privacy indicators, and
receiver state.

## 9. Visual And Interaction Standard

Use a respectful community hub with strong content hierarchy, clear privacy/giving treatment, and
domain surfaces for announcements/donations/care. Avoid checklist modals and repeated task cards.


### Notification Delivery

Both channels are offered and both are on by default. Announcements and care requests are the reason:
a community that gathers on a schedule needs its members reached before the gathering, and a care
request seen late is help that did not arrive.

A member who mutes stops the interruption and keeps the record: the notification still arrives in
the inbox and is there when they look. Muting is not unsubscribing.

### B25 Semantic Interaction Models

This B25 addendum defines the production interaction model the UI must prove from fresh after-screenshot evidence. A workflow cannot pass with only a happy-path action; it must show the expected decision, required primary action, alternate/change/reject path, durable result state, and receiver or continuation state.

| Workflow | Persona | Expected decision | Required primary actions | Required alternate/change/reject actions | Result and receiver state |
| --- | --- | --- | --- | --- | --- |
| mosque-announcement | Masjid admin / community member | Admin decides whether an announcement is ready for a named audience and time; members decide when to mark it read. | New announcement, Publish announcement, Schedule announcement, Mark read | Save draft, Preview announcement, Edit announcement, Archive announcement, Cancel announcement | Sent status, sent time, delivery/read counts and histories appear on Home/Messages; terminal summaries remain on Admin. |
| mosque-event-rsvp | Community member / Masjid admin | Member chooses attendance for a named event with date/time/location/capacity and can later change it; admin decides whether to publish or cancel. | Going, Maybe, Not attending, Join waitlist, Add reminder, Publish event | Cancel RSVP, Open volunteer shift, Save draft, Cancel event | Attendance/waitlist counts change, reminder choice/history is durable, and cancelled events remain visible as summaries. |
| mosque-document-resource | Community member / Masjid admin | Member chooses embedded or external open and any needed acknowledgement/access follow-up; admin may retire the resource. | Open embedded, Open externally, Record as opened, Acknowledge, Record download | Request access, Mark unread, Save resource, Ask follow-up, Archive resource | Title/source/version/access controls remain visible and auditHistory records auditable member actions without claiming Loom stores the linked bytes. |
| mosque-volunteer-signup | Community member / Masjid admin | Member decides whether to take an iftar shift after reviewing role/time/location/capacity/contact policy; admin coordinates follow-up. | Volunteer, Record coordinator follow-up | Edit availability, Cancel signup, Close signup | Roster/count, open spots, contact-consent, availability and coordinator histories show member and receiver state. |
| mosque-donor-visibility | Community member acting as donor | Donor chooses Public, Anonymous or Restricted after reviewing amount/fund and receipt treatment. | Reveal name, Keep anonymous, Restrict name | Change to either of the other two visibility choices | Preference state, receiptVisibility and visibilityHistory show the durable choice and change path. |
| mosque-donation-payment | Community member acting as payer / Masjid admin | Payer decides amount/fund/privacy and whether to submit; admin may honestly record an offline payment while online processing is unavailable. | Donate, Submit donation, Record offline payment, View receipt | Save changes, Retry payment, Manage recurring preference, Request refund, Decline refund, Record refund, Cancel donation | Payment/receipt status and history show intent, manual settlement or terminal outcome; donor visibility row is created on confirmed offline payment. |
| mosque-care-request | Community member / Masjid admin | Requester decides what protected care request to submit; reviewer decides assignment, changes, rejection, response and resolution. | Request care, Submit request, Approve and assign, Send private response, Resolve request | Request changes, Revise and resubmit, Reject request, Withdraw request | Requester sees a protected status timeline and neutral notification; owner sees the review queue and full protected fields. |
| mosque-neutral-notification | Community member recipient | Recipient decides whether to read, retain unread, request follow-up, return to unread, or archive a privacy-safe notice. | Mark read, Open inbox notice | Keep unread, Mark unread, Request follow-up, Archive notice | Sender/recipient/audience/body/time remain visible; readAt, keptUnreadAt and followUpRequestedAt provide durable state without protected care details. |
| mosque-search-ai-citation | Community member / Masjid admin | Member asks/refines and verifies an answer against citations; admin may provide an honest curated answer and moderate reported sources. | Ask Masjid Nur, Provide curated answer, Refine query, Save answer | Report stale citation, Hide source, Reopen for new answer | Query, curated answer, answer source/time and citation status are durable; AI generation and item-level citation redaction remain explicit gaps. |
| mosque-discussion-thread | Community member / Masjid admin | Member evaluates a thread and replies; admin may archive; members may request mute/unmute pending messaging support. | New discussion, Reply, Continue discussion | Mute thread, Unmute thread, Archive thread | Messages/latest-message/count update through replies; archived is durable; mute/unmute remain visible and explicitly not persisted until the messaging service exists. |
| wf_demo-app-persona-picker | member | Tester selects the correct Masjid persona and sees how role selection changes available workflows before reviewing the community. | choose persona, switch role, inspect capabilities | change persona, cancel picker, return to default | Fresh screenshots must show selected persona, role capability explanation, and the resulting available/disabled workflow state. |
| wf_community-persona-aware-ux | member | Member confirms their view contains member-safe workflows and hides/disables admin-only actions with a clear reason. | view member workflow, receive update, inspect read-only state | change persona, request access, leave unchanged | Fresh screenshots must show member role, allowed workflows, disabled/hidden admin rows, and explanation. |
| wf_community-persona-aware-ux | admin | Admin confirms their view contains publishing/coordination workflows and shows how member receiver state will be created. | open admin workflow, publish/update, inspect receiver target | preview, save draft, switch persona | Fresh screenshots must show admin role, admin-capable workflows, preview/receiver state, and switch path. |
| wf_multi-persona-workflow-evidence | admin | Admin creates a real announcement handoff and verifies which member persona will receive it. | publish announcement, preview receiver, switch persona | edit announcement, save draft, change audience | Fresh screenshots must show actor-created announcement state, body/audience/timestamp, persona switch, and receiver target. |
| wf_multi-persona-workflow-evidence | member | Member receives the admin-created announcement and can read or continue from the receiver state. | receive announcement, mark read, open inbox | archive, request follow-up, keep unread | Fresh screenshots must show sender/body/timestamp, received/read state, and continuation action. |


### B25 Card Surface Registry Mapping

This B25 advisory registry maps each documented community workflow to the canonical card surface family, OpenAPI contract, required interactions/actions, and Demo App renderer/fake-backend support expected by remediation. It is used as implementation context only; B25 does not yet enforce this as a standalone card-surface/API coverage gate.

| Workflow | Card surface family | API contract | Required interactions/actions | Renderer/fake-backend support |
| --- | --- | --- | --- | --- |
| `mosque-announcement` | `notificationInbox` primary feed plus `formEntry` Admin composition and `statusTimeline` summary | Workflow engine / notification configuration | draft/edit/preview, schedule/publish/cancel, read and archive | Generic live cards show composer/feed fields and actions; notification channels offer inbox and on-device push by default. |
| `mosque-event-rsvp` | `event-rsvp` with `formEntry` Admin draft | Workflow engine / reminder sweep | named event detail, RSVP choices/waitlist/withdraw, reminder, linked shift, publish/cancel | Real event-RSVP renderer uses literal eventDate/eventTime and the declared 24-hour reminder. |
| `mosque-document-resource` | `documentLibrary` | Document Library link handling | embedded/external open, acknowledge, request access, save, download record, follow-up, archive | Real document renderer opens `resourceUrl`; this is intentionally link-only and grants no upload/storage capability. |
| `mosque-volunteer-signup` | `formEntry` plus `statusTimeline` summary | Workflow engine | signup, availability edit, cancel, coordinator follow-up, close | Generic live cards render shift/capacity/roster/contact policy and transitions. |
| `mosque-donor-visibility` | `formEntry` | Workflow engine | three-way donor visibility and change path | Generic live card renders amount/fund/receipt visibility and history. |
| `mosque-donation-payment` | `paymentCheckout` plus `approvalQueueItem`/`statusTimeline` summaries | Workflow engine; payment gateway gap | intent/edit/retry/manual record/receipt/refund/cancel | Generic live payment card is honest about offline recording; no fake gateway success or receipt id. |
| `mosque-care-request` | `formEntry`, `approvalQueueItem`, `statusTimeline` | Workflow engine visibility/effects | submit/revise/withdraw, request changes/assign/reject/respond/resolve | Generic live cards enforce requester/owner parties and create a neutral recipient notification. |
| `mosque-neutral-notification` | `notificationInbox` | Workflow engine / notification delivery | read/unread/keep unread/follow-up/archive | Generic live inbox card enforces recipient visibility and durable timestamps. |
| `mosque-search-ai-citation` | `searchAiAnswer` | Workflow engine; external AI service gap | ask/refine, curate, save, report, moderate/reopen | Real answer renderer shows curated content and openable citations; AI generation is not fabricated. |
| `mosque-discussion-thread` | `discussionThread` | Workflow engine; messaging mute-service gap | create/reply/continue/archive; mute/unmute placeholders | Generic structured-list rendering shows messages; per-member mute persistence is explicitly unavailable. |
| `wf_demo-app-persona-picker` | [app-shell](../15-main-loom-app-app-shell-and-required-structure.md) | `CommunityAppShellApi` | persona switch, active role, capability preview, hidden/disabled state | Demo renderer must show persona options, selected role, capability impact, and current community state. |
| `wf_community-persona-aware-ux` | [app-shell](../15-main-loom-app-app-shell-and-required-structure.md) | `CommunityAppShellApi` | actor/receiver/read-only/disabled/hidden role rendering | Demo renderer must show admin/member differences, disabled/hidden explanations, and role-driven workflow availability. |
| `wf_multi-persona-workflow-evidence` | [announcement](../../CardSurfaces/announcement-publish.md) | `CommunityAnnouncementApi` | actor-created announcement, persona switch, receiver inbox/read state | Demo renderer must show admin-created sender/body/audience/timestamp and member receiver/read continuation. |

## 10. Review And Remediation Log

| Review run | Product-spec gap? | Implementation gap? | Product doc changes | UI changes required | Status |
| --- | --- | --- | --- | --- | --- |
| B25 next pass | no | pending review | Added semantic interaction model addendum. | Use documented primary and alternate actions in the UI, then recapture screenshots. | open |
| Skill-authoring judge pass 1 (2026-08-10) | no | yes | None. | `mosque-donor-visibility` had no creation path at all — fixed by wiring `mosque-donation-payment`'s `pay` transition to create a real donor-visibility row per donation, rather than relying on seed data standing in for a missing create affordance. | fixed |
| B25 pass 17 | yes | yes | Tightened Masjid announcement, iftar RSVP, and volunteer signup surfaces with message body, sender, audience, delivery time, event details, shift role, protected contact, and receiver state. | Render Masjid-specific tiles/action surfaces and recapture full B25 evidence. | in progress |
| Skill-authoring regeneration pass 2 (2026-09-05) | no | no | Migrated the leadership role from bespoke `masjid-admin` to the reserved `owner` role id (label/roleLabel unchanged); removed the `Care` persona-tab requirement from §3.1/§6/§7/§9 — care remains a protected status surface on Home/Admin, never a standalone tab, matching the package that has shipped since 2026-08-10 and the committed test contract; stamped `skillVersion` from `3.3.0` to `3.6.0`. | None — this was a doc/package reconciliation and role-id migration, not a UI change. Re-run the full verification suite set before treating this as closed. | fixed |
