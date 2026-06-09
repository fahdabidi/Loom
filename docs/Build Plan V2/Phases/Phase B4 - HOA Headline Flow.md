# Phase B4 - HOA Headline Flow

Workflow bundle: dues, documents, facility reservation, architectural request, committee review,
decision, export.
Components involved: Wallet, Documents, Facilities, Case/Task, Workflow Engine, Notification, Export,
Role/Policy, App Shell.
UX gate: high
Gate: `wf_hoa-headline` plus affected component regressions pass.

## WSL Ubuntu Tooling Requirement

Run all phase tooling from WSL Ubuntu, not Windows PowerShell. Use this command shape from the Windows host:

```powershell
wsl.exe -d Ubuntu -- bash -lc 'cd "/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app" && <command>'
```

Inside WSL Ubuntu, `dart`, `flutter`, and `melos` must resolve from the Ubuntu toolchain. Do not run Dart, Flutter, Melos, package validation, manifest gates, phase gates, or workflow tests from Windows-native shells.

## 0. Prerequisite Gate

- B3 complete and committed.
- Case/task, documents, facilities, wallet, and export tests are current.
- HOA example package exists.
- Workflow validation target is the Demo Loom Communities App with the Local Backend.

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

Complete `Phase B4 - UX Decisions.md` before implementation work that affects UI, interaction, user-visible state, or workflow copy. The UX Decisions file is a gate artifact and must follow this required format:

1. **Reference Sources Reviewed** - find several reference implementations of HOA dues, documents, facility reservation, architectural request, committee decision, case/task state, export, and local card/open flow; record each source, surface/flow reviewed, why it applies, patterns observed, applicability/gaps, and review date.
2. **UX Patterns Extracted** - learn from the reference implementations and extract concrete patterns for task flow, entry points, state handling, trust/privacy/payment cues, layout density, accessibility, and error recovery.
3. **Key UX Decisions** - list the UX decisions made for Loom, with rationale, affected surfaces, and the acceptance signal or covering test.
4. **Key Implementation Decisions** - record implementation choices that materially alter UX, including component ownership, state model, layout behavior, validation behavior, copy source, and test coverage.
5. **Workflow Walkthrough** - walk through the workflow step by step, mapping each user goal/action to the screen or state, owning component, UX decision applied, and covering test.
6. **Open Questions / Tradeoffs** - capture unresolved questions, options considered, recommendation, owner, and when resolution is required.

The phase cannot be marked done if the UX Decisions file only contains generic notes or unreviewed placeholders. If no external references are available, record the internal reference surfaces reviewed and the reason external reference research was not possible.

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

## Commit Gate

Before starting the next phase:

- Stage only this phase's intended changes.
- Run `git diff --staged` and confirm the staged scope matches this phase.
- Commit the phase changes.
- Record the resulting commit SHA in [../Build Tracker.md](../Build%20Tracker.md).
- Do not begin the next phase until the commit exists and the tracker points to it.

## 10. Next Phase

Proceed to [Phase B5 - Mosque Headline Flow.md](./Phase%20B5%20-%20Mosque%20Headline%20Flow.md).
