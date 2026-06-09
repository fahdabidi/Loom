# Phase B4 - UX Decisions

Status: Complete - R20 UX decisions applied

Purpose: document the UX research, extracted patterns, decisions, implementation impacts, workflow walkthrough, and open tradeoffs for HOA dues, documents, facility reservation, architectural request, committee decision, case/task state, export, and local card/open flow. This file is a phase gate artifact, not a placeholder.

## Reference Sources Reviewed

| Reference | Surface / Flow Reviewed | Why It Applies | Patterns Observed | Applicability / Gaps | Date Reviewed |
| --- | --- | --- | --- | --- | --- |
| [AppFolio Homeowners Online Portal](https://www.appfolio.com/help/owner-portal) | Owner portal for dues, payment history, and architectural reviews. | B4 combines dues, docs, architectural request, and status review. | HOA owner portals make payment, history, documents, and review requests self-service. | Loom validates contracts locally and defers a full HOA visual portal. | 2026-06-09 |
| [AppFolio HOA management](https://www.appfolio.com/markets/hoa/management) | Violations, architectural reviews, maintenance requests, mobile access. | B4's case/task and committee decision behavior aligns with architectural review queues. | Review tasks need clear state and mobile access for committee/manager users. | Loom uses generic Case/Task and Workflow Engine components. | 2026-06-09 |
| [TownSq amenity management](https://www.townsq.io/blog/tips-for-managing-your-amenity-reservations) | Amenity reservations, payments, architectural requests, communications. | Facility reservations are a headline HOA use case. | Amenity reservations benefit from accountability, transparency, and integrated payment. | B4 validates reservation/payment coupling, not calendar conflict UI. | 2026-06-09 |
| [TownSq architectural request FAQ](https://aliv.sites.townsq.io/5) | Architectural request form, supporting documents/photos, association review. | B4's architectural request needs document attachments and committee review. | Requests should capture supporting files and communicate process requirements. | Loom stores documents and case status but does not model photo uploads yet. | 2026-06-09 |
| [Clubhaus HOA software](https://clubhaus.io/) | Invoicing, payments, documents, announcements, architectural requests. | Shows the compact resident/admin portal shape for small communities. | Common HOA work is organized around dashboard, documents, invoicing, events, and requests. | Loom should stay dense and operational rather than marketing-style. | 2026-06-09 |
| [Vantaca HOA software guidance](https://www.vantaca.com/blog/how-to-evaluate-hoa-software-2026) | Integrated accounting, operations, payments, communication, migration. | B4 export and operational traceability need to anticipate migration/portability. | HOA buyers value operational systems that connect payments, communication, and records. | Export completeness needs better record-level IDs in later architecture. | 2026-06-09 |

## UX Patterns Extracted

| Pattern | Source References | User Problem Solved | Loom Application | Risk / Constraint |
| --- | --- | --- | --- | --- |
| Self-service owner dashboard | AppFolio, Clubhaus | Owners need repeated HOA tasks without contacting a manager. | B4 composes dues, docs, reservations, requests, and export through stable service contracts. | Visual dashboard is deferred. |
| Payment state is tied to operational rights | AppFolio, TownSq | Reservations and dues often depend on payment state. | Wallet records dues and reservation payment; facility reservation carries amount. | Complex delinquency rules are later. |
| Documents and requests are permissioned | AppFolio, TownSq FAQ | HOA documents and architectural attachments may be member-only/restricted. | Documents use visibility and permission tests. | Fine-grained document folders are not modeled yet. |
| Architectural request is a case with review state | AppFolio, TownSq FAQ | Owners need status visibility and boards need review workflow. | Case/Task opens request and Workflow Engine advances committee review. | Current export bundle lacks record-level case IDs. |
| Export must prove operational completeness | Vantaca guidance | HOA data portability requires docs, cases, payments, reservations, and decisions. | B4 asserts export component coverage and document inclusion. | Export API needs richer record inventories later. |

## Key UX Decisions

List the UX decisions that must be reflected in implementation. Each decision must trace to either a reference pattern, a Loom platform invariant, or a workflow requirement.

| Decision | Rationale | Applies To | Acceptance Signal / Test |
| --- | --- | --- | --- |
| Treat dues payment as the first HOA readiness event. | Dues establish the member's financial standing before higher-risk actions. | Wallet/Dues/Donations, Receipt Ledger. | `wf_hoa-headline`, `vt_wallet_payment` |
| Facility reservation must be paired with a reservation payment. | Amenity use often carries a fee/deposit and needs auditability. | Facilities Service, Wallet. | `ct_facilities__wallet_reservation-payment`, `wf_hoa-headline` |
| Governing documents are member-visible by default, restricted docs require permission. | Owners need access to rules while sensitive docs stay gated. | Documents Service, Search. | `vt_documents_permissions`, `wf_hoa-headline` |
| Architectural request is a case/task plus workflow transition. | Review status should be explicit and auditable. | Case/Task Service, Workflow Engine. | `vt_case-task_transition`, `vt_workflow-engine_transition`, `wf_hoa-headline` |
| Committee decision sends a notification. | Owners need closure when a request is approved/denied. | Notification Service. | `vt_notification_deliver`, `wf_hoa-headline` |
| Export must include documents and operational component coverage. | HOA portability requires confidence that records can move. | Export Service, Data Schema Store. | `vt_export_assemble`, `wf_hoa-headline` |

## Key Implementation Decisions

Record implementation decisions that materially alter the UX, including component ownership, state model, copy source, layout behavior, validation behavior, and test coverage.

| Implementation Decision | UX Impact | Owning Component | Tests / Gates |
| --- | --- | --- | --- |
| Implement B4 as a workflow test over existing services. | Keeps HOA workflow evidence contract-first before building a full portal UI. | Workflow Validation Harness. | `wf_hoa-headline` |
| Extend workflow harness with Engine services. | Committee review can use the real Workflow Engine fake. | Workflow Validation Harness. | `wf_hoa-headline` |
| Expand export component coverage to include case/task, facilities, wallet, and receipt surfaces. | Export evidence better matches the HOA completeness requirement. | Export Service. | `wf_hoa-headline`, A4a/A5 regressions |
| Add Skill workflow/example docs for HOA. | The Skill can explain how to compose dues, docs, facilities, cases, workflow, and export. | Skill. | B4 closeout |

## Workflow Walkthrough

Workflow under review: `wf_hoa-headline`. Walk through the experience step by step after the UX decisions are made. Include the screen or state shown, the user action, the owning component, and the covering test.

| Step | User Goal / Action | Screen or State | Owning Component | UX Decision Applied | Covering Test |
| --- | --- | --- | --- | --- | --- |
| 1 | Pay dues. | Member payment record is created. | Wallet/Dues/Donations. | Dues as readiness event. | `wf_hoa-headline` |
| 2 | Upload/view documents. | Member-visible governing document is uploaded and visible. | Documents Service. | Permissioned documents. | `wf_hoa-headline` |
| 3 | Reserve facility. | Clubhouse reservation is held with a fee. | Facilities Service. | Reservation/payment coupling. | `wf_hoa-headline` |
| 4 | Open architectural request case. | Request case is opened and assigned to committee/owner. | Case/Task Service. | Request as case/task. | `wf_hoa-headline` |
| 5 | Move through committee review. | Workflow run advances to decision step. | Workflow Engine. | Auditable review state. | `wf_hoa-headline` |
| 6 | Resolve case. | Case moves to resolved and notification is delivered. | Case/Task, Notification. | Decision notification. | `wf_hoa-headline` |
| 7 | Assemble export. | Export bundle includes document and operational components. | Export Service. | Export completeness. | `wf_hoa-headline` |
| 8 | Open local HOA extension. | App Shell opens `local:ext_hoa@latest`. | App Shell Runtime. | Shell-owned local open. | `wf_hoa-headline` |

## Open Questions / Tradeoffs

Capture unresolved UX questions and tradeoffs before implementation starts. A phase can proceed only when blockers are resolved or explicitly accepted.

| Question / Tradeoff | Options Considered | Recommendation | Owner | Resolution Required Before |
| --- | --- | --- | --- | --- |
| Should export include record-level IDs for cases/payments/reservations now? | Add fields now, assert component coverage now. | Assert component coverage in B4; add record-level export schema in B8. | Export Service. | B8 closeout |
| Should architectural requests require attachment uploads in B4? | Require documents/photos now, model request without attachments now. | Upload a governing doc and keep request attachment schema for later. | Documents / Case/Task. | Portal UI polish |
| Should facility reservations check schedule conflicts? | Conflict engine now, held reservation now. | Hold reservation now; add conflict/calendar policy later. | Facilities Service. | Facilities enhancement |
| Should unpaid dues block reservations automatically? | Hard block now, explicit payment prerequisite in workflow now. | Keep explicit workflow order now; policy automation later. | Wallet / Rule Engine. | Rule automation phase |

## WSL Ubuntu Tooling Requirement

Run all phase tooling from WSL Ubuntu, not Windows PowerShell. Use this command shape from the Windows host:

```powershell
wsl.exe -d Ubuntu -- bash -lc 'cd "/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app" && <command>'
```

Inside WSL Ubuntu, `dart`, `flutter`, and `melos` must resolve from the Ubuntu toolchain. Do not run Dart, Flutter, Melos, package validation, manifest gates, phase gates, or workflow tests from Windows-native shells.

## Commit Gate

Before starting the next phase:

- Stage only this phase's intended changes.
- Run `git diff --staged` and confirm the staged scope matches this phase.
- Commit the phase changes.
- Record the resulting commit SHA in [../Build Tracker.md](../Build%20Tracker.md).
- Do not begin the next phase until the commit exists and the tracker points to it.
