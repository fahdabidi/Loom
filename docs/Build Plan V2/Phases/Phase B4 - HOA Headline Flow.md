# Phase B4 - HOA Headline Flow

Workflow bundle: dues, documents, facility reservation, architectural request, committee review,
decision, export.
Components involved: Wallet, Documents, Facilities, Case/Task, Workflow Engine, Notification, Export,
Role/Policy, App Shell.
UX gate: high
Gate: `wf_hoa-headline` plus affected component regressions pass.

## 0. Prerequisite Gate

- B3 complete and committed.
- Case/task, documents, facilities, wallet, and export tests are current.
- HOA example package exists.

## 1. Workflows and End States

| Workflow | End state |
| --- | --- |
| `wf_hoa-headline` | Member pays dues, views documents, reserves facility, submits architectural request, committee decides, export includes request, decision, docs, and receipts. |

## 2. Workflow Tests Mapped to Owning Components

| Step | Owning component | Supporting tests |
| --- | --- | --- |
| Pay dues | wallet-dues-donations | `vt_wallet_payment`, `vt_wallet_ad-off` |
| View rules/documents | documents-service, search-service | `vt_documents_permissions`, `ct_documents__search_index-visible-documents` |
| Reserve facility | facilities-service, wallet-dues-donations | `vt_facilities_reservation`, `ct_facilities__wallet_reservation-payment` |
| Submit request | case-task-service, documents-service | `vt_case-task_transition`, `vt_documents_permissions` |
| Committee workflow decides | workflow-engine, notification-service | `vt_workflow-engine_transition`, `vt_notification_deliver` |
| Export records | export-service, data-schema-store, receipt-ledger | `vt_export_assemble`, `ct_data-schema-store__import-export_schema-enumeration` |

## 3. UX Research and Decisions

Create `Phase B4 - UX Decisions.md`. Review HOA portals, request/approval queues, document libraries,
facility booking, and dues UX. Record compact admin/member flows.

## 4. Execution and Issue-Triage Loop

Run `wf_hoa-headline`. Fixes must start with owner component tests, especially for case transitions,
document permissioning, facility payment/reservation coupling, and export inclusion.

## 5. Per-Component Regression Gate

Run all tests for altered components plus workflows involving Wallet, Documents, Facilities, Case/Task,
Workflow Engine, or Export.

## 6. Skill Contribution

Add:

- `Skill/workflows/hoa-headline.md`
- HOA example extension under `Skill/examples/hoa/`

Update component guides for documents, facilities, case/task, workflow, wallet, and export.

## 7. Manifest Update

Stamp `wf_hoa-headline` and affected tests.

## 8. API Review

Create `Phase B4 - API Review.md`. Record dues, facility, document, case/task, workflow, and export API
gaps.

## 9. Definition of Done

HOA workflow passes, regressions pass, Skill/example updated, manifest current, UX/API docs filed,
tracker and commit SHA recorded.

## 10. Next Phase

Proceed to [Phase B5 - Mosque Headline Flow.md](./Phase%20B5%20-%20Mosque%20Headline%20Flow.md).
