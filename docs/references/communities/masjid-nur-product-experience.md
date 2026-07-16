# Masjid Nur Product Experience

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
| Community member | Home, Calendar, Giving, Care, Messages | Friday service/iftar, donation receipt, care request status | Calm green palette, prayer/community language, clear charitable and care privacy cues. |
| Masjid admin | Home, Calendar, Giving, Care, Admin, Messages | announcement composer, volunteer roster, donation status, care review | Admin tabs expose compose/review surfaces and protected care handoff state. |

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
| mosque-announcement | owner | Announcement compose/feed | sender, audience, body, timing, sent state, receiver/read state | Publishing/notifications/events | B14/B20/B25 |
| mosque-event-rsvp | member | Masjid calendar event detail | event/class title, date/time, location, recurrence, capacity, RSVP choice/result, reminder state | Calendar/events/notifications | B14/B25 |
| mosque-document-resource | member | Documents and external resource detail | document title, source, embedded/external open option, access/acknowledgement state | Documents/external documents/audit | B14/B25 |
| mosque-volunteer-signup | member | Volunteer shift detail | shift role/time, open spots, volunteer roster/count, signup/edit/cancel state | Forms/events | B14/B25 |
| mosque-donor-visibility | donor | Donor privacy preference | visibility choice, amount context, receipt visibility, change path | Wallet/receipts/vault | B14/B25 |
| mosque-donation-payment | donor | Donation/payment | amount, privacy, receipt, payer, retry/manage path | Wallet/receipts | B14/B25 |
| mosque-care-request | member | Protected care form/review | private/public split, recipient state, status history | Vault/cases/audit | B14/B25 |
| mosque-neutral-notification | member | Notification inbox/detail | sender, audience, message body, timestamp, read/received state | Notifications/events | B14/B25 |
| mosque-search-ai-citation | member | Search/AI answer | query, answer, citation/source visibility, follow-up action | Search/AI/digest | B14/B25 |
| wf_demo-app-persona-picker | member | Persona switch support surface | available personas, current role, capability preview, disabled/hidden implications | App Shell/persona test harness | B18/B25 |
| wf_community-persona-aware-ux | admin | Persona-aware admin view | admin-capable workflow list, disabled/read-only member rows, role explanation | App Shell/role policy | B19/B25 |
| wf_community-persona-aware-ux | member | Persona-aware member view | member-capable workflow list, read-only/hidden admin rows, role explanation | App Shell/role policy | B19/B25 |
| wf_multi-persona-workflow-evidence | admin | Actor-to-receiver handoff | admin-created announcement state, persona switch path, receiver target | App Shell/events/persona test harness | B20/B25 |
| wf_multi-persona-workflow-evidence | member | Receiver handoff evidence | received announcement, sender/body/timestamp, read state, continuation action | App Shell/events/persona test harness | B20/B25 |

## 7. Persona And State Matrix

| Workflow | Actor state | Receiver state | Read-only state | Disabled/hidden state | Unauthorized behavior |
| --- | --- | --- | --- | --- | --- |
| mosque-announcement | owner sends | member reads/receives announcement | prior announcements archived | send disabled without audience/body | non-owner cannot publish |
| mosque-event-rsvp | member chooses RSVP | capacity/attendee state updates | confirmed RSVP remains readable | RSVP disabled when full/closed | non-member cannot RSVP |
| mosque-document-resource | member opens a khutbah note, form, or policy | admin sees access/acknowledgement audit where needed | document version/source readable | acknowledge/download disabled without access | protected resources require permission |
| mosque-volunteer-signup | member signs up or edits availability | coordinator sees volunteer roster/count | signup status readable | signup disabled when shift full | non-member cannot see protected contact |
| mosque-donor-visibility | donor chooses visibility | donation/receipt respects visibility | visibility history readable | public display disabled when anonymous | non-donor cannot edit visibility |
| mosque-donation-payment | donor pays | receipt/settlement records donation | receipt readable/exportable | pay disabled after completed unless retry/manage | non-donor cannot view private receipt |
| mosque-care-request | member requests | care team receives neutral protected state | requester sees status | private fields hidden from general members | unauthorized denied |
| mosque-neutral-notification | member receives neutral notice | sender sees delivery status | notice readable | action disabled after read if no reply allowed | non-recipient hidden |
| mosque-search-ai-citation | member asks/searches | cited source visibility obeys permission | digest readable | citation hidden when source unauthorized | unauthorized source redacted |
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

### B25 Semantic Interaction Models

This B25 addendum defines the production interaction model the UI must prove from fresh after-screenshot evidence. A workflow cannot pass with only a happy-path action; it must show the expected decision, required primary action, alternate/change/reject path, durable result state, and receiver or continuation state.

| Workflow | Persona | Expected decision | Required primary actions | Required alternate/change/reject actions | Result and receiver state |
| --- | --- | --- | --- | --- | --- |
| mosque-announcement | owner | Admin decides whether a concrete announcement is ready for a named audience and delivery timing; members can later read the delivered update. | publish announcement, send announcement, post announcement, schedule announcement | edit announcement, preview announcement, save draft, schedule later, change audience | Fresh screenshots must show status, receipt/history/confirmation, and any receiver or continuation state for this persona. |
| mosque-event-rsvp | member | Member decides attendance for a named dated event with time, location, capacity/status, and a later change path. | rsvp, attend, going, reserve spot, confirm attendance | decline, not attending, maybe, change response, edit response, cancel rsvp | Fresh screenshots must show status, receipt/history/confirmation, and any receiver or continuation state for this persona. |
| mosque-document-resource | member | Member opens a concrete Masjid document/resource, reviews source/version/access, chooses embedded or external open, and acknowledges if required. | open document, launch external, download, acknowledge | request access, save, mark unread, ask follow-up | Fresh screenshots must show title/source/version, embedded/external open choices, access/acknowledgement state, and audit-safe receiver state. |
| mosque-volunteer-signup | member | Member chooses whether to volunteer for a concrete iftar shift after reviewing role, time, location, capacity, protected contact sharing, and coordinator follow-up. | sign up, submit signup, volunteer, confirm shift | edit availability, cancel signup, change shift, withdraw | Fresh screenshots must show role, shift time/location, protected contact, signup confirmation, edit/cancel path, and coordinator receiver state for this persona. |
| mosque-donor-visibility | donor | Donor decides whether their name is public, anonymous, or restricted after seeing donation amount, fund, receipt visibility, and change path. | save visibility, set anonymous, update donor preference | change visibility, edit preference, reveal name, keep anonymous | Fresh screenshots must show amount/fund context, visibility choice, receipt visibility, saved preference, and change path. |
| mosque-donation-payment | donor | Payer decides what amount or entitlement to pay for, sees cost/recipient/visibility, and can change or manage the payment. | pay, donate, give, checkout, subscribe | change amount, edit payment, manage, cancel subscription, refund, retry payment | Fresh screenshots must show status, receipt/history/confirmation, and any receiver or continuation state for this persona. |
| mosque-care-request | member | Reviewer or requester evaluates a concrete request with requester, details, status, and approve/reject/change paths. | submit request, approve request, send request, review request | reject, request changes, revise, withdraw, edit request | Fresh screenshots must show status, receipt/history/confirmation, and any receiver or continuation state for this persona. |
| mosque-neutral-notification | member | Member reviews a privacy-safe care notification with sender, message body, timestamp, read state, and no protected details leaked. | receive notification, mark read, open inbox notice | archive notice, request follow-up, keep unread | Fresh screenshots must show sender, audience, timestamp, message body, read/received state, and protected-detail absence. |
| mosque-search-ai-citation | member | Member asks a question and verifies the answer against visible public citation/source context without seeing unauthorized protected data. | search, ask question, open citation, save answer | refine query, hide source, report stale citation | Fresh screenshots must show query, answer, citation/source visibility, follow-up action, and permission guard. |
| wf_demo-app-persona-picker | member | Tester selects the correct Masjid persona and sees how role selection changes available workflows before reviewing the community. | choose persona, switch role, inspect capabilities | change persona, cancel picker, return to default | Fresh screenshots must show selected persona, role capability explanation, and the resulting available/disabled workflow state. |
| wf_community-persona-aware-ux | member | Member confirms their view contains member-safe workflows and hides/disables admin-only actions with a clear reason. | view member workflow, receive update, inspect read-only state | change persona, request access, leave unchanged | Fresh screenshots must show member role, allowed workflows, disabled/hidden admin rows, and explanation. |
| wf_community-persona-aware-ux | admin | Admin confirms their view contains publishing/coordination workflows and shows how member receiver state will be created. | open admin workflow, publish/update, inspect receiver target | preview, save draft, switch persona | Fresh screenshots must show admin role, admin-capable workflows, preview/receiver state, and switch path. |
| wf_multi-persona-workflow-evidence | admin | Admin creates a real announcement handoff and verifies which member persona will receive it. | publish announcement, preview receiver, switch persona | edit announcement, save draft, change audience | Fresh screenshots must show actor-created announcement state, body/audience/timestamp, persona switch, and receiver target. |
| wf_multi-persona-workflow-evidence | member | Member receives the admin-created announcement and can read or continue from the receiver state. | receive announcement, mark read, open inbox | archive, request follow-up, keep unread | Fresh screenshots must show sender/body/timestamp, received/read state, and continuation action. |


### B25 Card Surface Registry Mapping

This B25 advisory registry maps each documented community workflow to the canonical card surface family, OpenAPI contract, required interactions/actions, and Demo App renderer/fake-backend support expected by remediation. It is used as implementation context only; B25 does not yet enforce this as a standalone card-surface/API coverage gate.

| Workflow | Card surface family | API contract | Required interactions/actions | Renderer/fake-backend support |
| --- | --- | --- | --- | --- |
| `mosque-announcement` | [announcement](../../CardSurfaces/announcement-publish.md) | `CommunityAnnouncementApi` | draft/edit/preview, schedule/publish/cancel, delivery/read receipts/revisions | Demo renderer must show announcement composer/feed, sender, audience, body, timing, sent state, and receiver/read state. |
| `mosque-event-rsvp` | [calendar](../../CardSurfaces/calendar.md) and [event-rsvp](../../CardSurfaces/event-rsvp.md) | `CommunityCalendarSurfaceApi` / `CommunityEventRsvpApi` | named event/class detail, recurrence/reminder, going/maybe/not-going, change/cancel RSVP, capacity/attendee state | Demo renderer must show event title, date/time, location, recurrence/reminder, capacity, RSVP choice, change path, and result. |
| `mosque-document-resource` | [documents](../../CardSurfaces/documents.md) and [external-document-link](../../CardSurfaces/external-document-link.md) | `CommunityDocumentSurfaceApi` / `CommunityExternalDocumentApi` | list/open/download/acknowledge/request access, embedded browser open, external app launch, version/audit trail | Demo renderer must show document title/source/version, embedded/external open choices, acknowledgement/access state, and audit-safe history. |
| `mosque-volunteer-signup` | [volunteer-signup](../../CardSurfaces/volunteer-signup.md) | `CommunityVolunteerApi` | shift slots, count/roster, availability, cancel/edit, check-in/no-show | Demo renderer must show role, time, open spots, volunteer count/roster, signup/edit/cancel, and protected contact handling. |
| `mosque-donor-visibility` | [payment](../../CardSurfaces/payment-donation-dues-ad-off.md) | `CommunityPaymentSurfaceApi` | donor visibility, receipt visibility, change/manage preference | Demo renderer must show visibility choice, donation context, receipt visibility, and change path. |
| `mosque-donation-payment` | [payment](../../CardSurfaces/payment-donation-dues-ad-off.md) | `CommunityPaymentSurfaceApi` | intent/confirm/retry, receipt/refund, recurring/entitlement, settlement state | Demo renderer must show amount, payer, privacy, receipt, retry/manage path, and status. |
| `mosque-care-request` | [protected-request](../../CardSurfaces/care-protected-request.md) | `CommunityProtectedRequestApi` | submit/update/withdraw, protected/public split, admin review, neutral notification | Demo renderer must show private/public split, recipient state, status history, and protected audit treatment. |
| `mosque-neutral-notification` | [announcement](../../CardSurfaces/announcement-publish.md) | `CommunityAnnouncementApi` | sender, audience, timestamp, message body, receiver read state | Demo renderer must show sender, audience, body, timestamp, and read/received state. |
| `mosque-search-ai-citation` | [search-ai](../../CardSurfaces/search-ai-digest.md) | `CommunitySearchAiSurfaceApi` | query/history, answer, citation detail, source visibility, save/share | Demo renderer must show query, answer, citation/source visibility, and follow-up action. |
| `wf_demo-app-persona-picker` | [app-shell](../15-main-loom-app-app-shell-and-required-structure.md) | `CommunityAppShellApi` | persona switch, active role, capability preview, hidden/disabled state | Demo renderer must show persona options, selected role, capability impact, and current community state. |
| `wf_community-persona-aware-ux` | [app-shell](../15-main-loom-app-app-shell-and-required-structure.md) | `CommunityAppShellApi` | actor/receiver/read-only/disabled/hidden role rendering | Demo renderer must show admin/member differences, disabled/hidden explanations, and role-driven workflow availability. |
| `wf_multi-persona-workflow-evidence` | [announcement](../../CardSurfaces/announcement-publish.md) | `CommunityAnnouncementApi` | actor-created announcement, persona switch, receiver inbox/read state | Demo renderer must show admin-created sender/body/audience/timestamp and member receiver/read continuation. |

## 10. Review And Remediation Log

| Review run | Product-spec gap? | Implementation gap? | Product doc changes | UI changes required | Status |
| --- | --- | --- | --- | --- | --- |
| B25 next pass | no | pending review | Added semantic interaction model addendum. | Use documented primary and alternate actions in the UI, then recapture screenshots. | open |
| B25 pass 17 | yes | yes | Tightened Masjid announcement, iftar RSVP, and volunteer signup surfaces with message body, sender, audience, delivery time, event details, shift role, protected contact, and receiver state. | Render Masjid-specific tiles/action surfaces and recapture full B25 evidence. | in progress |
