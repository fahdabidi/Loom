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
| Schedule/reminders | Practice/game logistics. | Guardian/coach | date, time, location, reminder channel. | Confirm / send reminder |

## 4. Home Screen Requirements

The home must answer what is next for the team, whether the child is registered, and what action the
guardian or coach needs to take.

## 5. Domain-Native Product Surfaces

| Surface | Required visible content | Required states | Natural actions | Anti-patterns |
| --- | --- | --- | --- | --- |
| Registration/payment | fee, player context, consent, receipt | unpaid/paid/failed | pay, retry, view receipt | abstract payment row |
| Roster | player/guardian/coach state, redaction | pending/approved/redacted | approve, view | exposed minor details |
| Schedule | event title, date, location, reminder | upcoming/sent/cancelled | remind, RSVP | generic notification card |

## 6. Workflow-To-Surface Mapping

| Workflow | Persona | Product surface | Required visible proof | Loom APIs/rules/events | Test/evidence IDs |
| --- | --- | --- | --- | --- | --- |
| soccer-guardian-join-approval | guardian | Join approval | guardian request and approval state | Membership/roles/events | B14/B25 |
| soccer-team-roster | coach | Roster | team list and approved/redacted state | Membership/vault | B14/B25 |
| soccer-minor-redaction | guardian | Protected profile | redacted minor fields | Vault/consent/audit | B14/B25 |
| soccer-registration-payment | guardian | Payment surface | amount, receipt, status | Wallet/receipts/settlement | B14/B25 |
| soccer-practice-schedule | guardian | Schedule detail | date/time/location | Events/notifications | B14/B25 |
| soccer-reminder-notification | guardian | Reminder center | audience/channel/sent state | Notifications/events | B14/B25 |
| soccer-export-metadata | owner | Export status | redaction/checksum/scope | Export/documents | B14/B25 |

## 7. Persona And State Matrix

| Workflow | Actor state | Receiver state | Read-only state | Disabled/hidden state | Unauthorized behavior |
| --- | --- | --- | --- | --- | --- |
| registration payment | guardian pays | coach sees registered state | guardian can view receipt | pay disabled after paid | non-guardian hidden |
| roster | coach manages | guardian sees child status | member reads schedule | roster admin hidden | minors redacted |

## 8. Content And Seed Data Requirements

Use team names, practice dates, field locations, registration fees, receipts, guardian/player labels,
redaction markers, and reminder channels.

## 9. Visual And Interaction Standard

Use schedule-first mobile hierarchy, strong privacy/receipt indicators, and role-specific coach vs
guardian surfaces. Avoid repeated cards that hide team logistics.

### B25 Semantic Interaction Models

This B25 addendum defines the production interaction model the UI must prove from fresh after-screenshot evidence. A workflow cannot pass with only a happy-path action; it must show the expected decision, required primary action, alternate/change/reject path, durable result state, and receiver or continuation state.

| Workflow | Persona | Expected decision | Required primary actions | Required alternate/change/reject actions | Result and receiver state |
| --- | --- | --- | --- | --- | --- |
| soccer-guardian-join-approval | guardian | Reviewer or requester evaluates a concrete request with requester, details, status, and approve/reject/change paths. | submit request, approve request, send request, review request | reject, request changes, revise, withdraw, edit request | Fresh screenshots must show status, receipt/history/confirmation, and any receiver or continuation state for this persona. |
| soccer-team-roster | coach | User decides a concrete community task with enough context, a semantic primary action, a meaningful alternative, and a durable result. | submit, save, send | edit, change, undo, reject, withdraw | Fresh screenshots must show status, receipt/history/confirmation, and any receiver or continuation state for this persona. |
| soccer-minor-redaction | guardian | User decides a concrete community task with enough context, a semantic primary action, a meaningful alternative, and a durable result. | submit, save, send | edit, change, undo, reject, withdraw | Fresh screenshots must show status, receipt/history/confirmation, and any receiver or continuation state for this persona. |
| soccer-registration-payment | guardian | Payer decides what amount or entitlement to pay for, sees cost/recipient/visibility, and can change or manage the payment. | pay, donate, give, checkout, subscribe | change amount, edit payment, manage, cancel subscription, refund, retry payment | Fresh screenshots must show status, receipt/history/confirmation, and any receiver or continuation state for this persona. |
| soccer-practice-schedule | guardian | Member decides attendance for a named dated event with time, location, capacity/status, and a later change path. | rsvp, attend, going, reserve spot, confirm attendance | decline, not attending, maybe, change response, edit response, cancel rsvp | Fresh screenshots must show status, receipt/history/confirmation, and any receiver or continuation state for this persona. |
| soccer-reminder-notification | guardian | User decides a concrete community task with enough context, a semantic primary action, a meaningful alternative, and a durable result. | submit, save, send | edit, change, undo, reject, withdraw | Fresh screenshots must show status, receipt/history/confirmation, and any receiver or continuation state for this persona. |
| soccer-export-metadata | owner | Admin selects export/import/transfer scope, reviews redaction/checksum/status, and can cancel, retry, or roll back. | export, download export, start transfer, import data | change scope, cancel transfer, rollback, retry, redaction preview | Fresh screenshots must show status, receipt/history/confirmation, and any receiver or continuation state for this persona. |


### B25 Card Surface Registry Mapping

This B25 advisory registry maps each documented community workflow to the canonical card surface family, OpenAPI contract, required interactions/actions, and Demo App renderer/fake-backend support expected by remediation. It is used as implementation context only; B25 does not yet enforce this as a standalone card-surface/API coverage gate.

| Workflow | Card surface family | API contract | Required interactions/actions | Renderer/fake-backend support |
| --- | --- | --- | --- | --- |
| `soccer-guardian-join-approval` | [approval](../../CardSurfaces/approval-request.md) | `CommunityApprovalApi` | approve/reject/request changes, comments/history, assignee/committee state, appeal/reopen | Demo renderer must select a domain-native surface for `approval` and LocalInAppBackend must expose/import the state for these interactions. |
| `soccer-team-roster` | [operations](../../CardSurfaces/documents-facilities-roster.md) | `CommunityOperationsSurfaceApi` | document/version/access, facility reserve/edit/cancel, conflict handling, roster history | Demo renderer must select a domain-native surface for `operations` and LocalInAppBackend must expose/import the state for these interactions. |
| `soccer-minor-redaction` | [portability](../../CardSurfaces/export-import-transfer.md) | `CommunityPortabilitySurfaceApi` | scope/redaction preview, generate/download/checksum, transfer/rollback, audit trail | Demo renderer must select a domain-native surface for `portability` and LocalInAppBackend must expose/import the state for these interactions. |
| `soccer-registration-payment` | [payment](../../CardSurfaces/payment-donation-dues-ad-off.md) | `CommunityPaymentSurfaceApi` | intent/confirm/retry, receipt/refund, recurring/entitlement, settlement state | Demo renderer must select a domain-native surface for `payment` and LocalInAppBackend must expose/import the state for these interactions. |
| `soccer-practice-schedule` | [event-rsvp](../../CardSurfaces/event-rsvp.md) | `CommunityEventRsvpApi` | named event detail, going/maybe/not-going, change/cancel RSVP, capacity/attendee state | Demo renderer must select a domain-native surface for `event-rsvp` and LocalInAppBackend must expose/import the state for these interactions. |
| `soccer-reminder-notification` | [announcement](../../CardSurfaces/announcement-publish.md) | `CommunityAnnouncementApi` | draft/edit/preview, schedule/publish/cancel, delivery/read receipts/revisions | Demo renderer must select a domain-native surface for `announcement` and LocalInAppBackend must expose/import the state for these interactions. |
| `soccer-export-metadata` | [portability](../../CardSurfaces/export-import-transfer.md) | `CommunityPortabilitySurfaceApi` | scope/redaction preview, generate/download/checksum, transfer/rollback, audit trail | Demo renderer must select a domain-native surface for `portability` and LocalInAppBackend must expose/import the state for these interactions. |

## 10. Review And Remediation Log

| Review run | Product-spec gap? | Implementation gap? | Product doc changes | UI changes required | Status |
| --- | --- | --- | --- | --- | --- |
| B25 next pass | no | pending review | Added semantic interaction model addendum. | Use documented primary and alternate actions in the UI, then recapture screenshots. | open |
