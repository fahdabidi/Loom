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
| Document center | Read HOA docs. | Member | doc title, status, date. | Open document |
| Review queue | Board decision. | Board | requester, change, comments, approve/reject. | Approve request |

## 4. Home Screen Requirements

The home must be organized around homeowner jobs: payments, documents, facilities, requests, and board
actions.

## 5. Domain-Native Product Surfaces

| Surface | Required visible content | Required states | Natural actions | Anti-patterns |
| --- | --- | --- | --- | --- |
| Dues | amount, due date, payer, receipt | due/paid/failed | pay, view receipt | generic payment chip |
| Documents | title, version/date, access | available/read | open, export | metadata card only |
| Facility reservation | facility, date, time, status | open/reserved/conflict | reserve, cancel | checklist modal |
| Review queue | request, requester, decision, audit | pending/approved/denied | approve, reject, comment | unlabeled task |

## 6. Workflow-To-Surface Mapping

| Workflow | Persona | Product surface | Required visible proof | Loom APIs/rules/events | Test/evidence IDs |
| --- | --- | --- | --- | --- | --- |
| hoa-dues-payment | member | Dues payment | amount and receipt | Wallet/receipts | B14/B25 |
| hoa-member-document | member | Document center | document title/access | Documents/audit | B14/B25 |
| hoa-facility-reservation | member | Reservation detail | facility/date/status | Facilities/events | B14/B25 |
| hoa-architectural-request | member | Request form | change details/submitted state | Cases/tasks/documents | B14/B25 |
| hoa-board-review | board | Review queue | requester, decision actions | Cases/tasks/audit | B14/B25 |
| hoa-export-evidence | owner | Export status | scope/checksum/rollback | Export/provider transfer | B14/B25 |

## 7. Persona And State Matrix

| Workflow | Actor state | Receiver state | Read-only state | Disabled/hidden state | Unauthorized behavior |
| --- | --- | --- | --- | --- | --- |
| architectural request | member submits | board reviews | member sees status | approve hidden for member | non-board denied |
| dues payment | member pays | board sees ledger | receipt read-only after pay | pay disabled after paid | non-member hidden |

## 8. Content And Seed Data Requirements

Use realistic dues amounts, due dates, document names, facility names/times, property request text,
board comments, receipts, audit labels, and export checksums.

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


## 10. Card Surface Registry Mapping

This B25 advisory registry maps each documented community workflow to the canonical card surface family, OpenAPI contract, required interactions/actions, and Demo App renderer/fake-backend support expected by remediation. It is used as implementation context only; B25 does not yet enforce this as a standalone card-surface/API coverage gate.

| Workflow | Card surface family | API contract | Required interactions/actions | Renderer/fake-backend support |
| --- | --- | --- | --- | --- |
| `hoa-dues-payment` | [payment](../../CardSurfaces/payment-donation-dues-ad-off.md) | `CommunityPaymentSurfaceApi` | intent/confirm/retry, receipt/refund, recurring/entitlement, settlement state | Demo renderer must select a domain-native surface for `payment` and LocalInAppBackend must expose/import the state for these interactions. |
| `hoa-member-document` | [operations](../../CardSurfaces/documents-facilities-roster.md) | `CommunityOperationsSurfaceApi` | document/version/access, facility reserve/edit/cancel, conflict handling, roster history | Demo renderer must select a domain-native surface for `operations` and LocalInAppBackend must expose/import the state for these interactions. |
| `hoa-facility-reservation` | [operations](../../CardSurfaces/documents-facilities-roster.md) | `CommunityOperationsSurfaceApi` | document/version/access, facility reserve/edit/cancel, conflict handling, roster history | Demo renderer must select a domain-native surface for `operations` and LocalInAppBackend must expose/import the state for these interactions. |
| `hoa-architectural-request` | [approval](../../CardSurfaces/approval-request.md) | `CommunityApprovalApi` | approve/reject/request changes, comments/history, assignee/committee state, appeal/reopen | Demo renderer must select a domain-native surface for `approval` and LocalInAppBackend must expose/import the state for these interactions. |
| `hoa-board-review` | [form](../../CardSurfaces/custom-form-submission.md) | `CommunityFormSurfaceApi` | load/validate/save draft, submit/update/withdraw, protected field routing, review/export | Demo renderer must select a domain-native surface for `form` and LocalInAppBackend must expose/import the state for these interactions. |
| `hoa-export-evidence` | [portability](../../CardSurfaces/export-import-transfer.md) | `CommunityPortabilitySurfaceApi` | scope/redaction preview, generate/download/checksum, transfer/rollback, audit trail | Demo renderer must select a domain-native surface for `portability` and LocalInAppBackend must expose/import the state for these interactions. |

## 11. Review And Remediation Log

| Review run | Product-spec gap? | Implementation gap? | Product doc changes | UI changes required | Status |
| --- | --- | --- | --- | --- | --- |
| B25 next pass | no | pending review | Added semantic interaction model addendum. | Use documented primary and alternate actions in the UI, then recapture screenshots. | open |
