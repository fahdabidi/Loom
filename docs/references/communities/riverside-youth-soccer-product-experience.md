# Riverside Youth Soccer Product Experience

## 1. Community Identity And Promise

| Field | Value |
| --- | --- |
| Community name | Riverside Youth Soccer |
| Community type | Youth sports team/league |
| Product promise | Help guardians and coaches manage roster, registration, schedule, reminders, and protected minor data. |
| Brand cues | Team/schedule/field cues, confident family-friendly tone, privacy-forward labels. |
| What this must not feel like | Generic payment/form/notification workflow tiles. |

## 2. Personas, Roles, And Jobs

| Persona | Role/capabilities | Primary jobs-to-be-done | Sensitive constraints | Success state |
| --- | --- | --- | --- | --- |
| Guardian | Join approval, register/pay, view schedule/reminders | Keep child registered and know practice/game logistics. | Minor data must be redacted and consented. | Guardian sees registration, payment receipt, and next schedule. |
| Coach | Manage roster and schedule | Know who is registered and communicate reminders. | Coach sees only appropriate minor info. | Roster/schedule/reminder state is current. |
| Owner | Export metadata | Keep league data portable. | Export must respect minor redaction. | Export evidence is redacted and verifiable. |

## 3. Information Architecture

| Surface | Purpose | Primary persona | Required content | Primary action |
| --- | --- | --- | --- | --- |
| Team home | Current team status. | Guardian/coach | next practice, roster status, registration/payment, reminders. | Register / view roster |
| Registration/payment | Register player and pay. | Guardian | player summary, fee, consent, receipt. | Pay registration |
| Roster | View team membership. | Coach | player names or redacted minors, roles, approval state. | Review roster |
| Team calendar | Practice/game logistics. | Guardian/coach | date, time, location, field, opponent, reminder channel, sync state. | Confirm / send reminder |
| Waiver and team documents | Open policies, waivers, and season documents. | Guardian/coach | document title, version, access, acknowledgement, embedded/external open option. | Open / acknowledge |
| Registration status case | Track guardian/player registration through approval, waiver, payment, and roster steps. | Guardian/coach | current step, missing items, reviewer, payment/waiver checkpoints, history. | Continue registration |

## 3.1 Persona Tabs, Pins, And Customization

| Persona | Required tabs | Pinned surfaces | Customization notes |
| --- | --- | --- | --- |
| Guardian | Home, Schedule, Team, Payments, Messages | next practice, registration receipt, team announcements | Sport palette, team badge, guardian-friendly labels, minor-data redaction indicators. |
| Coach | Home, Schedule, Team, Coach, Documents, Messages | roster, guardian approval queue, reminder composer | Coach tabs expose team operations and protected roster actions not shown to guardians. |

## 4. Home Screen Requirements

The home must answer what is next for the team, whether the child is registered, and what action the
guardian or coach needs to take.

## 5. Domain-Native Product Surfaces

| Surface | Required visible content | Required states | Natural actions | Anti-patterns |
| --- | --- | --- | --- | --- |
| Registration/payment | fee, player context, consent, receipt | unpaid/paid/failed | pay, retry, view receipt | abstract payment row |
| Roster | player/guardian/coach state, redaction | pending/approved/redacted | approve, view | exposed minor details |
| Calendar/schedule | event title, date, location, reminder, sync state | upcoming/sent/cancelled/rescheduled | remind, RSVP, add to calendar | generic notification card |
| Documents/waivers | document title, version, acknowledgement, access | unread/read/acknowledged/access-requested | open embedded, open external, acknowledge, request access | hidden waiver link |
| Workflow status | registration/approval step, waiver/payment checkpoint, reviewer, history | submitted/under-review/missing-info/approved | continue, request changes, attach document, reopen | rigid one-step approval card |

## 6. Workflow-To-Surface Mapping

| Workflow | Persona | Product surface | Required visible proof | Loom APIs/rules/events | Test/evidence IDs |
| --- | --- | --- | --- | --- | --- |
| soccer-guardian-join-approval | guardian | Registration status case | guardian request, current step, coach reviewer, waiver/payment checkpoints, approval state | Workflow status/membership/roles/events | B14/B25 |
| soccer-team-roster | coach | Roster | team list and approved/redacted state | Membership/vault | B14/B25 |
| soccer-minor-redaction | guardian | Protected profile | redacted minor fields | Vault/consent/audit | B14/B25 |
| soccer-registration-payment | guardian | Payment surface | amount, receipt, status | Wallet/receipts/settlement | B14/B25 |
| soccer-practice-schedule | guardian | Team calendar detail | date/time/location/field/opponent, reminder, calendar sync state | Calendar/events/notifications | B14/B25 |
| soccer-waiver-document | guardian | Waiver document detail | waiver title/version, embedded/external open, acknowledgement, access state | Documents/external documents/audit | B14/B25 |
| soccer-reminder-notification | guardian | Reminder center | audience/channel/sent state | Notifications/events | B14/B25 |
| soccer-export-metadata | owner | Export status | redaction/checksum/scope | Export/documents | B14/B25 |

## 7. Persona And State Matrix

| Workflow | Actor state | Receiver state | Read-only state | Disabled/hidden state | Unauthorized behavior |
| --- | --- | --- | --- | --- | --- |
| soccer-guardian-join-approval | guardian submits approval request | coach sees pending/approved guardian state | guardian can review request history | approval disabled after accepted | non-guardian cannot submit child approval |
| soccer-team-roster | coach manages roster and redactions | guardian sees child/team status | team list readable with protected fields hidden | edit disabled for non-coaches | minor profile details are redacted for unauthorized roles |
| soccer-minor-redaction | guardian reviews protected profile fields | coach sees only allowed roster metadata | redaction policy readable | private fields hidden | unauthorized role cannot reveal minor data |
| soccer-registration-payment | guardian pays registration fee | coach sees registered/payment-complete state | guardian can view receipt | pay disabled after completed unless retry/manage applies | non-guardian cannot view private receipt |
| soccer-practice-schedule | guardian RSVPs or reviews practice | coach sees attendance/reminder state | schedule remains readable | RSVP disabled when closed/cancelled | non-member cannot access team schedule |
| soccer-waiver-document | guardian opens and acknowledges a waiver/policy | coach sees acknowledgement status without protected details | waiver version and acknowledgement history readable | acknowledge disabled after latest version accepted | unauthorized role cannot open protected player documents |
| soccer-reminder-notification | coach/admin sends reminder | guardian receives reminder in inbox | reminder history readable | send disabled without audience/body | non-coach cannot send team reminder |
| soccer-export-metadata | owner exports team metadata | receiving provider sees transfer status | export summary readable | export disabled without scope/redaction preview | protected youth fields remain redacted |

## 8. Content And Seed Data Requirements

Use team names, practice dates, field locations, registration fees, receipts, waiver names/versions,
guardian/player labels, redaction markers, and reminder channels.

## 9. Visual And Interaction Standard

Use schedule-first mobile hierarchy, strong privacy/receipt indicators, and role-specific coach vs
guardian surfaces. Avoid repeated cards that hide team logistics.

### B25 Semantic Interaction Models

This B25 addendum defines the production interaction model the UI must prove from fresh after-screenshot evidence. A workflow cannot pass with only a happy-path action; it must show the expected decision, required primary action, alternate/change/reject path, durable result state, and receiver or continuation state.

| Workflow | Persona | Expected decision | Required primary actions | Required alternate/change/reject actions | Result and receiver state |
| --- | --- | --- | --- | --- | --- |
| soccer-guardian-join-approval | guardian | Reviewer or requester evaluates a concrete request with requester, details, status, and approve/reject/change paths. | submit request, approve request, send request, review request | reject, request changes, revise, withdraw, edit request | Fresh screenshots must show status, receipt/history/confirmation, and any receiver or continuation state for this persona. |
| soccer-team-roster | coach | Coach reviews a concrete team roster with player names, guardian/waiver status, protected minor fields, and edit/history paths. | open roster, update roster, save roster, mark waiver | edit player, request guardian update, redact field, undo change | Fresh screenshots must show roster rows, role-filtered/redacted fields, waiver/status history, and guardian receiver state. |
| soccer-minor-redaction | guardian | Guardian reviews which minor fields are protected/redacted, why, and what can be shared with coaches or export packages. | review redaction, confirm privacy, save consent | change consent, hide field, request correction | Fresh screenshots must show protected field labels, redaction preview, consent state, and unauthorized-hidden behavior. |
| soccer-registration-payment | guardian | Payer decides what amount or entitlement to pay for, sees cost/recipient/visibility, and can change or manage the payment. | pay, donate, give, checkout, subscribe | change amount, edit payment, manage, cancel subscription, refund, retry payment | Fresh screenshots must show status, receipt/history/confirmation, and any receiver or continuation state for this persona. |
| soccer-practice-schedule | guardian | Member decides attendance for a named dated event with time, location, capacity/status, and a later change path. | rsvp, attend, going, reserve spot, confirm attendance | decline, not attending, maybe, change response, edit response, cancel rsvp | Fresh screenshots must show status, receipt/history/confirmation, and any receiver or continuation state for this persona. |
| soccer-waiver-document | guardian | Guardian opens a concrete waiver or policy, reviews version/source, chooses embedded or external open, acknowledges it, and sees season registration impact. | open document, acknowledge waiver, download document | request access, open external, mark unread, ask coach | Fresh screenshots must show title/version/source, embedded/external open options, acknowledgement state, access guard, and registration-status linkage. |
| soccer-reminder-notification | guardian | Guardian receives a team reminder with sender, audience, practice/event context, delivery channel, timestamp, and read state. | receive reminder, mark read, open schedule | mute reminders, keep unread, request change | Fresh screenshots must show sender, message body, audience/channel, timestamp, related schedule, and receiver/read state. |
| soccer-export-metadata | owner | Admin selects export/import/transfer scope, reviews redaction/checksum/status, and can cancel, retry, or roll back. | export, download export, start transfer, import data | change scope, cancel transfer, rollback, retry, redaction preview | Fresh screenshots must show status, receipt/history/confirmation, and any receiver or continuation state for this persona. |


### B25 Card Surface Registry Mapping

This B25 advisory registry maps each documented community workflow to the canonical card surface family, OpenAPI contract, required interactions/actions, and Demo App renderer/fake-backend support expected by remediation. It is used as implementation context only; B25 does not yet enforce this as a standalone card-surface/API coverage gate.

| Workflow | Card surface family | API contract | Required interactions/actions | Renderer/fake-backend support |
| --- | --- | --- | --- | --- |
| `soccer-guardian-join-approval` | [workflow-status](../../CardSurfaces/workflow-status.md) | `CommunityWorkflowStatusApi` | create registration case, current step, coach reviewer, waiver/payment checkpoints, request changes, approve/reject, comments/history | Demo renderer must show guardian/player registration status, missing items, reviewer, approval state, and receiver state. |
| `soccer-team-roster` | [operations](../../CardSurfaces/documents-facilities-roster.md) | `CommunityOperationsSurfaceApi` | document/version/access, facility reserve/edit/cancel, conflict handling, roster history | Demo renderer must select a domain-native surface for `operations` and LocalInAppBackend must expose/import the state for these interactions. |
| `soccer-minor-redaction` | [portability](../../CardSurfaces/export-import-transfer.md) | `CommunityPortabilitySurfaceApi` | scope/redaction preview, generate/download/checksum, transfer/rollback, audit trail | Demo renderer must select a domain-native surface for `portability` and LocalInAppBackend must expose/import the state for these interactions. |
| `soccer-registration-payment` | [payment](../../CardSurfaces/payment-donation-dues-ad-off.md) | `CommunityPaymentSurfaceApi` | intent/confirm/retry, receipt/refund, recurring/entitlement, settlement state | Demo renderer must select a domain-native surface for `payment` and LocalInAppBackend must expose/import the state for these interactions. |
| `soccer-practice-schedule` | [calendar](../../CardSurfaces/calendar.md) and [event-rsvp](../../CardSurfaces/event-rsvp.md) | `CommunityCalendarSurfaceApi` / `CommunityEventRsvpApi` | named practice/game detail, recurrence/reminder, calendar sync, going/maybe/not-going, change/cancel RSVP, capacity/attendance state | Demo renderer must show team calendar details with field/opponent, reminder/sync state, RSVP result, and change path. |
| `soccer-waiver-document` | [documents](../../CardSurfaces/documents.md) and [external-document-link](../../CardSurfaces/external-document-link.md) | `CommunityDocumentSurfaceApi` / `CommunityExternalDocumentApi` | list/open/download/acknowledge/request access, embedded browser open, external app launch, version/audit trail | Demo renderer must show waiver title/version, embedded/external open choices, acknowledgement state, and access/audit. |
| `soccer-reminder-notification` | [announcement](../../CardSurfaces/announcement-publish.md) | `CommunityAnnouncementApi` | draft/edit/preview, schedule/publish/cancel, delivery/read receipts/revisions | Demo renderer must select a domain-native surface for `announcement` and LocalInAppBackend must expose/import the state for these interactions. |
| `soccer-export-metadata` | [portability](../../CardSurfaces/export-import-transfer.md) | `CommunityPortabilitySurfaceApi` | scope/redaction preview, generate/download/checksum, transfer/rollback, audit trail | Demo renderer must select a domain-native surface for `portability` and LocalInAppBackend must expose/import the state for these interactions. |

## 10. Review And Remediation Log

| Review run | Product-spec gap? | Implementation gap? | Product doc changes | UI changes required | Status |
| --- | --- | --- | --- | --- | --- |
| B25 next pass | no | pending review | Added semantic interaction model addendum. | Use documented primary and alternate actions in the UI, then recapture screenshots. | open |
