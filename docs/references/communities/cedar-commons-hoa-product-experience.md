# Cedar Commons HOA Product Experience

## 1. Community Identity And Promise

| Field | Value |
| --- | --- |
| Community name | Cedar Commons HOA |
| Community type | Homeowners association |
| Product promise | Help homeowners pay dues, access documents, reserve facilities, submit requests, and export HOA records. |
| Brand cues | Civic/residential tone, document and facility cues, clear audit/approval language. |
| What this must not feel like | A generic admin task list with dues and document chips. |

## 2. Personas, Roles, And Jobs

| Persona | Role/capabilities | Primary jobs-to-be-done | Sensitive constraints | Success state |
| --- | --- | --- | --- | --- |
| Homeowner/member | Pay dues, read documents, reserve facilities, submit requests | Handle HOA obligations and property needs quickly. | Payment receipts and requests need audit clarity. | Member sees paid/reserved/submitted state. |
| HOA Board | Review requests, manage documents/export | Decide requests and keep records portable. | Board decisions need audit trail. | Board sees queue, decision, export state. |

## 3. Information Architecture

| Surface | Purpose | Primary persona | Required content | Primary action |
| --- | --- | --- | --- | --- |
| HOA home | Current obligations and requests. | Member/board | dues, documents, reservations, requests, board notices. | Pay dues / submit request |
| Dues payment | Pay and view receipt. | Member | amount, due date, payer, receipt. | Pay dues |
| Document center | Read the HOA's own governing documents, held by Cedar. | Member | doc title, version/date, access state, uploaded file name and size. | Open document |
| HOA calendar | See meetings, reservation windows, dues deadlines, and review dates. | Member/board | date, location, conflict/status, reminder. | Reserve / add reminder |
| Workflow status center | Track multi-step HOA cases. | Member/board | submitted details, current step, reviewer, requested changes, payment/document checkpoints, status history. | Continue case |
| Review queue | Board decision. | Board | requester, change, comments, approve/reject/request changes. | Approve request |

## 3.1 Persona Tabs, Pins, And Customization

| Persona | Required tabs | Pinned surfaces | Customization notes |
| --- | --- | --- | --- |
| Homeowner | Home, Documents, Payments, Requests, Messages | dues receipt, active request status, governing docs | Civic/blue palette, property/lot context, readable status and receipt hierarchy. |
| Board reviewer | Home, Board, Documents, Payments, Requests, Messages | architectural decision queue, owner notifications, facility requests | Board tabs expose decision/comment/reopen actions with history and owner notification state. |

## 4. Home Screen Requirements

The home must be organized around homeowner jobs: payments, documents, facilities, requests, and board
actions.

## 5. Domain-Native Product Surfaces

| Surface | Required visible content | Required states | Natural actions | Anti-patterns |
| --- | --- | --- | --- | --- |
| Dues | amount, due date, payer, receipt | due/paid/failed | pay, view receipt | generic payment chip |
| Documents | title, version/date, access, uploaded file name and size, embedded/external open choices | draft/published/read/acknowledged/access-requested/archived | board: **upload**, edit, publish, delete, archive, restore · member: open embedded, open external, download, acknowledge, request access | metadata card only; drafts visible to members; **asking the Board to paste a link to a file they are holding** |
| Facility reservation | facility, date, time, status | open/reserved/conflict | reserve, cancel | checklist modal |
| Workflow status / review queue | request, requester, current step, reviewer, payment/document checkpoints, comments, audit | submitted/under-review/changes-needed/approved/denied/reopened | approve, reject, request changes, attach document, reopen | single rigid approval card |

**Documents are uploaded, not linked.** The Board holds the HOA's governing documents as files —
the CC&Rs, the architectural guidelines, the minutes of the meeting where a rule changed. A Board
member adds one by choosing the file, and Cedar keeps it. They are not asked for a URL, and the
document does not live in somebody's personal drive where it can be moved, renamed, or lost when
that person leaves the Board.

This matters more here than in a reading list. A homeowner who is told a rule exists needs to be able
to read the rule, and an HOA that cannot produce its own governing documents has a governance problem
rather than a filing problem. A link to a document is a promise that someone else will keep it; an
uploaded document is one the HOA keeps itself.

Cedar is the only community that stores documents this way. Chess Club, Masjid Nur, the Book Club and
Youth Soccer keep libraries of external resources, and should — a khutbah note or a rules PDF that
already lives somewhere authoritative is better linked than copied.

**Document lifecycle.** A governing document is drafted before it is published. A Board member
uploads the file, the Board revises it privately, publishes it when it is ready, and may delete a
draft that was never published or archive a published one that has been superseded. Uploading a new
file to a published document is how a revision is issued: the version changes, and members who had
acknowledged the previous version have acknowledged a document that no longer says what it said.

Only the Board may upload, edit, publish, delete, archive or restore. **An unpublished document is visible to
the Board alone** — a draft policy circulating before the Board has agreed it is worse than no policy,
because members act on what they read. Once published, every member may open, download and acknowledge
it.

Archiving and deleting are different and both are needed. Archiving retires a superseded document that
still exists and can be restored — the HOA keeps a record of what its rules used to be. Deleting removes
a draft that should never have existed. The Board should not have to keep a mistaken draft forever in
order to keep its real history.

## 6. Workflow-To-Surface Mapping

| Workflow | Persona | Product surface | Required visible proof | Loom APIs/rules/events | Test/evidence IDs |
| --- | --- | --- | --- | --- | --- |
| hoa-dues-payment | member | Dues payment | amount and receipt | Wallet/receipts | B14/B25 |
| hoa-member-document | member | Document center | document title, version, access state, uploaded file name/size, embedded/external open choices, acknowledgement/download state | Documents/external documents/audit | B14/B25 |
| hoa-facility-reservation | member | Calendar reservation detail | facility/date/time, conflict status, reservation window, reminder state | Calendar/facilities/events | B14/B25 |
| hoa-architectural-request | owner | Workflow status case | change details, current step, reviewer, requested-changes path, document/payment checkpoint, submitted state | Workflow status/cases/tasks/documents | B14/B25 |
| hoa-committee-decision | owner | Workflow status review queue | requester, decision actions, status history, request-changes path, comments, owner receiver state | Workflow status/cases/tasks/audit | B14/B25 |
| hoa-owner-notification | owner | Owner notification | sender, audience, body, sent/received state | Notifications/events | B14/B25 |
| hoa-export-evidence | owner | Export status | scope/checksum/rollback | Export/provider transfer | B14/B25 |

## 7. Persona And State Matrix

| Workflow | Actor state | Receiver state | Read-only state | Disabled/hidden state | Unauthorized behavior |
| --- | --- | --- | --- | --- | --- |
| hoa-dues-payment | member pays quarterly dues | HOA ledger records paid/receipt state | receipt read-only after pay | pay disabled after paid; retry shown on failure | non-member hidden |
| hoa-member-document | board uploads, drafts, publishes and retires; member opens published document | board/admin sees access audit | document metadata/read state visible | download disabled without permission; publish/delete hidden from members; drafts hidden entirely from members | non-member denied |
| hoa-facility-reservation | member reserves facility | owner/board sees reservation status | confirmed reservation readable | reserve disabled on conflict | non-member denied |
| hoa-architectural-request | owner submits exterior request | committee sees requester/details | owner sees status history | approve hidden for owner | non-owner denied |
| hoa-committee-decision | owner/committee reviews request | homeowner receives approved/rejected/changes state | decision history readable | duplicate decision disabled | non-committee denied |
| hoa-owner-notification | owner sends notice | members receive message/read state | sent notice readable | send disabled until audience/body ready | non-owner denied |
| hoa-export-evidence | owner generates export | board/member notices if applicable | checksum/scope readable | transfer disabled until checksum passes | non-owner hidden |

## 8. Content And Seed Data Requirements

Use realistic dues amounts, due dates, document names, facility names/times, property request text,
board comments, receipts, audit labels, and export checksums.

Seeded documents must carry a real uploaded file, not a URL standing in for one. A seed row whose
document is a link is indistinguishable from the linked libraries the other communities ship, so it
would demonstrate nothing about Cedar and would hide a broken upload path behind a working-looking
card.

## 9. Visual And Interaction Standard

Use civic dashboard hierarchy, clear payment/document/request sections, and distinct board review
surfaces. Avoid uniform cards across unrelated homeowner jobs.

### B25 Semantic Interaction Models

This B25 addendum defines the production interaction model the UI must prove from fresh after-screenshot evidence. A workflow cannot pass with only a happy-path action; it must show the expected decision, required primary action, alternate/change/reject path, durable result state, and receiver or continuation state.

| Workflow | Persona | Expected decision | Required primary actions | Required alternate/change/reject actions | Result and receiver state |
| --- | --- | --- | --- | --- | --- |
| hoa-dues-payment | member | Payer decides what amount or entitlement to pay for, sees cost/recipient/visibility, and can change or manage the payment. | pay, donate, give, checkout, subscribe | change amount, edit payment, manage, cancel subscription, refund, retry payment | Fresh screenshots must show status, receipt/history/confirmation, and any receiver or continuation state for this persona. |
| hoa-member-document | member | Member decides whether to open, acknowledge, save, or share a concrete document with title, date, owner, and status. | open document, download document, read document, acknowledge | save, share, close document, mark unread, request access | Fresh screenshots must show status, receipt/history/confirmation, and any receiver or continuation state for this persona. |
| hoa-facility-reservation | member | User decides a concrete community task with enough context, a semantic primary action, a meaningful alternative, and a durable result. | submit, save, send | edit, change, undo, reject, withdraw | Fresh screenshots must show status, receipt/history/confirmation, and any receiver or continuation state for this persona. |
| hoa-architectural-request | owner | Reviewer or requester evaluates a concrete request with requester, details, status, and approve/reject/change paths. | submit request, approve request, send request, review request | reject, request changes, revise, withdraw, edit request | Fresh screenshots must show status, receipt/history/confirmation, and any receiver or continuation state for this persona. |
| hoa-committee-decision | owner | User decides a concrete community task with enough context, a semantic primary action, a meaningful alternative, and a durable result. | submit, save, send | edit, change, undo, reject, withdraw | Fresh screenshots must show status, receipt/history/confirmation, and any receiver or continuation state for this persona. |
| hoa-owner-notification | owner | User decides a concrete community task with enough context, a semantic primary action, a meaningful alternative, and a durable result. | submit, save, send | edit, change, undo, reject, withdraw | Fresh screenshots must show status, receipt/history/confirmation, and any receiver or continuation state for this persona. |
| hoa-export-evidence | owner | Admin selects export/import/transfer scope, reviews redaction/checksum/status, and can cancel, retry, or roll back. | export, download export, start transfer, import data | change scope, cancel transfer, rollback, retry, redaction preview | Fresh screenshots must show status, receipt/history/confirmation, and any receiver or continuation state for this persona. |


### B25 Card Surface Registry Mapping

This B25 advisory registry maps each documented community workflow to the canonical card surface family, OpenAPI contract, required interactions/actions, and Demo App renderer/fake-backend support expected by remediation. It is used as implementation context only; B25 does not yet enforce this as a standalone card-surface/API coverage gate.

| Workflow | Card surface family | API contract | Required interactions/actions | Renderer/fake-backend support |
| --- | --- | --- | --- | --- |
| `hoa-dues-payment` | [payment](../../CardSurfaces/payment-donation-dues-ad-off.md) | `CommunityPaymentSurfaceApi` | intent/confirm/retry, receipt/refund, recurring/entitlement, settlement state | Demo renderer must select a domain-native surface for `payment` and LocalInAppBackend must expose/import the state for these interactions. |
| `hoa-member-document` | [documents](../../CardSurfaces/documents.md) | Document Library API (`uploadDocument`, `downloadDocumentContent`, `getDocumentAccess`) | upload, list/open/download/acknowledge/request access, version/audit trail | Demo renderer must show HOA document title/version, the uploaded file's name and size, acknowledgement/access state, and audit. A document with nothing to open is a failed capture, not a rendering choice. |
| `hoa-facility-reservation` | [calendar](../../CardSurfaces/calendar.md) | `CommunityCalendarSurfaceApi` | list/create/update/cancel/reschedule reservation item, conflict detection, reminders, linked facility status | Demo renderer must show facility/date/time/conflict state, reserve/change/cancel actions, and reminder state. |
| `hoa-architectural-request` | [workflow-status](../../CardSurfaces/workflow-status.md) | `CommunityWorkflowStatusApi` | create case, current step, reviewer, request changes, attach documents, payment checkpoint, reopen/cancel, audit | Demo renderer must show current step, submitted details, reviewer, request-changes path, document/payment checkpoint, and owner receiver state. |
| `hoa-committee-decision` | [workflow-status](../../CardSurfaces/workflow-status.md) | `CommunityWorkflowStatusApi` | approve/reject/request changes, comments/history, reviewer/committee state, appeal/reopen, owner notification | Demo renderer must show requester, decision actions, request-changes path, comments/history, and resulting owner notification state. |
| `hoa-owner-notification` | [notification-inbox](../../CardSurfaces/notification-inbox.md) | `CommunityNotificationSurfaceApi` | sender, audience, body, timing, delivery/read state | Demo renderer must show sender, audience, message body, timestamp, sent/read state, and receiver state. |
| `hoa-export-evidence` | [portability](../../CardSurfaces/export-import-transfer.md) | `CommunityPortabilitySurfaceApi` | scope/redaction preview, generate/download/checksum, transfer/rollback, audit trail | Demo renderer must select a domain-native surface for `portability` and LocalInAppBackend must expose/import the state for these interactions. |

## 10. Review And Remediation Log

**2026-08-26 (b) — residual link language removed.** The first pass at this rewrite left two rows
still describing an external-link library: the information-architecture row still promised "linked
external records", and the card-surface registry row still mapped to `external-document-link` /
`CommunityExternalDocumentApi` and asked the renderer to show a `source`. A package derived from a doc
that contradicts itself can satisfy either half. Caught by the Skill on a later regeneration, which
reported the doc as self-contradictory rather than picking a side.

**2026-08-26 — documents become uploads.** This document previously described the document centre in
terms of `provider/source` and `embedded/external open choices`, because when it was written the
platform could not store a file and a link was the only thing a community could offer. Loom now has
document storage, and Cedar is the community where owning the bytes matters, so the experience is
restated around uploading. The four other document libraries are deliberately left as link libraries.

Derivation note for the package: the Board's upload capability is the `documentLibrary` archetype's
`upload` action — see
[`document-library.md` §3a](../archetypes/document-library.md). The content field must be
`writableBy: "effect"` and must not be `required`, or a member would still have to type an address
before the upload could happen.

| Review run | Product-spec gap? | Implementation gap? | Product doc changes | UI changes required | Status |
| --- | --- | --- | --- | --- | --- |
| B25 next pass | no | pending review | Added semantic interaction model addendum. | Use documented primary and alternate actions in the UI, then recapture screenshots. | open |
