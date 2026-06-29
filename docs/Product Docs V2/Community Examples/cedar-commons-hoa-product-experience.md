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

## 10. Review And Remediation Log

| Review run | Product-spec gap? | Implementation gap? | Product doc changes | UI changes required | Status |
| --- | --- | --- | --- | --- | --- |
| B25 next pass | no | pending review | Created canonical HOA product experience. | Judge current screenshots against homeowner/board surfaces. | open |
