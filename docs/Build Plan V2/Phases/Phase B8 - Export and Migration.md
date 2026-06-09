# Phase B8 - Export and Migration

Workflow bundle: community export, member export/delete, extension custom-data export, protected
redaction, provider transfer, import replay.
Components involved: Export, Import, Provider Transfer, Registry, Membership, Protected Vault, Data
Schema Store, Receipt Ledger, Wallet, Documents, Case/Task.
UX gate: final workflow validation
Gate: `wf_export-migration`, `vt_api_specs_complete`, and affected component regressions pass.

## WSL Ubuntu Tooling Requirement

Run all phase tooling from WSL Ubuntu, not Windows PowerShell. Use this command shape from the Windows host:

```powershell
wsl.exe -d Ubuntu -- bash -lc 'cd "/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app" && <command>'
```

Inside WSL Ubuntu, `dart`, `flutter`, and `melos` must resolve from the Ubuntu toolchain. Do not run Dart, Flutter, Melos, package validation, manifest gates, phase gates, or workflow tests from Windows-native shells.

## 0. Prerequisite Gate

- B7 complete and committed.
- All prior workflow tests are current and not stale.
- Export/import/provider transfer tests are current.
- API spec inventory is current for every component and workflow touched by V2.
- Workflow validation target is the Demo Loom Communities App with the Local Backend.

## 1. Workflows and End States

| Workflow | End state |
| --- | --- |
| `wf_export-migration` | Owner exports community, protected data is redacted/split, extension records are included, checksums/receipts are produced, provider transfer verifies or rolls back. |

## 2. Workflow Tests Mapped to Owning Components

| Step | Owning component | Supporting tests |
| --- | --- | --- |
| Request export scope | export-service | `vt_export_assemble` |
| Enumerate component data | export-service, data-schema-store | `ct_export__components_enumerate`, `ct_data-schema-store__import-export_schema-enumeration` |
| Redact protected data | protected-visibility-vault | `ct_protected-vault__import-export_redaction` |
| Include receipts/economic state | receipt-ledger, wallet-dues-donations | `vt_receipt-ledger_append`, `vt_wallet_payment` |
| Verify transfer | provider-transfer-service | `vt_provider-transfer_execute-verify` |
| Rollback or complete | provider-transfer-service, community-registry | `vt_provider-transfer_rollback` |
| Verify final API coverage | api-spec-inventory | `vt_api_specs_complete` |

## 3. UX Research and Decisions

Complete `Phase B8 - UX Decisions.md` before implementation work that affects UI, interaction, user-visible state, or workflow copy. The UX Decisions file is a gate artifact and must follow this required format:

1. **Reference Sources Reviewed** - find several reference implementations of export, migration, redaction explanation, checksums, provider transfer, rollback, retained-record disclosure, full regression summary, and final readiness UX; record each source, surface/flow reviewed, why it applies, patterns observed, applicability/gaps, and review date.
2. **UX Patterns Extracted** - learn from the reference implementations and extract concrete patterns for task flow, entry points, state handling, trust/privacy/payment cues, layout density, accessibility, and error recovery.
3. **Key UX Decisions** - list the UX decisions made for Loom, with rationale, affected surfaces, and the acceptance signal or covering test.
4. **Key Implementation Decisions** - record implementation choices that materially alter UX, including component ownership, state model, layout behavior, validation behavior, copy source, and test coverage.
5. **Workflow Walkthrough** - walk through the workflow step by step, mapping each user goal/action to the screen or state, owning component, UX decision applied, and covering test.
6. **Open Questions / Tradeoffs** - capture unresolved questions, options considered, recommendation, owner, and when resolution is required.

The phase cannot be marked done if the UX Decisions file only contains generic notes or unreviewed placeholders. If no external references are available, record the internal reference surfaces reviewed and the reason external reference research was not possible.

## 4. Execution and Issue-Triage Loop

Run `wf_export-migration`. Export omissions first add a failing validation/contract test to the
component that owns the missing data or to Export if orchestration is wrong.

## 5. Per-Component Regression Gate

Run all tests for altered components plus every workflow involving those components. This is the final
workflow phase, so also run the full Set B workflow suite and the API spec inventory/conformance gate.

## 6. Skill Contribution

Add:

- `Skill/workflows/export-migration.md`

Update all example extensions with export metadata and custom schema export behavior.

## 7. Manifest Update

Stamp `wf_export-migration`, `vt_api_specs_complete`, all affected tests, and final Set B workflow test
runs.

## 8. API Review

Create `Phase B8 - API Review.md`. Record export, import, provider transfer, protected redaction,
receipt, schema portability gaps, and the final API inventory result proving every required API spec is
present and validates.

## 9. Definition of Done

Export/migration workflow passes, full workflow suite passes, API specs are complete and validated,
regressions pass, Skill/examples updated, manifest current, UX/API docs filed, tracker and commit SHA
recorded.

## Commit Gate

Before starting the next phase:

- Stage only this phase's intended changes.
- Run `git diff --staged` and confirm the staged scope matches this phase.
- Commit the phase changes.
- Record the resulting commit SHA in [../Build Tracker.md](../Build%20Tracker.md).
- Do not begin the next phase until the commit exists and the tracker points to it.

## 10. Next Phase

End of Build Plan V2 workflow validation. Next step is review against the implementation roadmap and
convert approved phases into execution tasks.
