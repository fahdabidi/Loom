# Phase B8 - UX Decisions

Status: Completed

Purpose: document UX research, extracted patterns, decisions, implementation impacts, workflow
walkthrough, and tradeoffs for export, migration, redaction explanation, checksums, provider transfer,
rollback, retained-record disclosure, full regression summary, and final readiness UX.

## Reference Sources Reviewed

| Reference | Surface / Flow Reviewed | Why It Applies | Patterns Observed | Applicability / Gaps | Date Reviewed |
| --- | --- | --- | --- | --- | --- |
| [Google Takeout data export](https://support.google.com/accounts/answer/3024190) | Select data, export archive, download package | Mature user-facing data export reference. | Users select included products/data, choose export options, and receive archive delivery. | Loom is community-scoped and admin-owned rather than personal-account only. | 2026-06-09 |
| [Slack workspace data export](https://slack.com/help/articles/201658943-Export-your-workspace-data) | Admin export scope, date range, export readiness notification | Community owners need scoped exports and readiness status. | Export type/scope/date range are selected before the export starts; export availability is communicated later. | Loom B8 local fake produces immediate bundle, not async hosted job. | 2026-06-09 |
| [Slack import/export guide](https://slack.com/help/articles/204897248-Guide-to-Slack-import-and-export-tools) | Plan-dependent import/export behavior and access limits | Loom must explain what export includes/excludes and who can access it. | Export capabilities vary by plan/permissions; admins need eligibility explanation. | Loom policy/plan matrix is not final. | 2026-06-09 |
| [Slack retention settings](https://slack.com/help/articles/203457187-Customize-data-retention-in-Slack) | Retained/deleted data explanation | Export UX must disclose retained records and limitations. | Settings changes are reviewed and confirmed; retention affects export availability. | Loom B8 validates redaction/retention metadata, not complete legal retention policy. | 2026-06-09 |
| [GitHub Enterprise Importer overview](https://docs.github.com/en/migrations/using-github-enterprise-importer/migrating-between-github-products/about-migrations-between-github-products) | Provider migration planning and migration scope | Provider transfer needs target verification and migration status. | Migration is scoped by source/target and supports structured migration paths. | Loom provider transfer is a local fake in B8. | 2026-06-09 |
| [GitHub Enterprise Importer repository migration](https://docs.github.com/en/migrations/using-github-enterprise-importer/migrating-between-github-products/migrating-repositories-from-github-enterprise-server-to-github-enterprise-cloud) | CLI/API migration flow and verification | Good reference for migration commands and target verification. | Migration can be driven through API/CLI and requires source/target identity. | Rollback semantics differ by domain. | 2026-06-09 |
| [Apple iCloud data archive/export](https://support.apple.com/en-us/108306) | File/category export and save location | Useful pattern for explaining export formats and destination. | Users choose data/file categories and save exported files. | Apple export is personal; Loom export is owner/member/community scoped. | 2026-06-09 |

## UX Patterns Extracted

| Pattern | Source References | User Problem Solved | Loom Application | Risk / Constraint |
| --- | --- | --- | --- | --- |
| Export starts with explicit scope selection and preview | Google Takeout, Slack export | Owners need to know what will be included before creating an archive. | B8 validates component enumeration and import preview counts. | Local fake has immediate output; hosted backend needs async progress. |
| Redaction and retained-record disclosures are first-class | Slack retention, Slack import/export guide | Sensitive data and retained records can surprise users. | B8 uses redacted export component marker and protected-vault records. | Future UI must explain retained audit/legal records separately. |
| Verification/checksum is part of the trust loop | Google Takeout archive patterns, migration docs | Owners need confidence the export package is complete and uncorrupted. | B8 asserts non-empty checksum and target transfer verification. | Actual SHA-256 package files are later hosted/local package work. |
| Migration requires target identity, verify, and rollback path | GitHub Enterprise Importer docs | Provider transfer should not be a blind one-way action. | B8 validates execute, verify, and rollback states. | Hosted provider transfer needs background job and retry semantics. |
| Final readiness summary should include regression status | Migration readiness references | Phase completion needs evidence that existing flows still work. | B8 runs the full Set B workflow suite and records final manifest stamps. | Tracker is the human summary; visual readiness dashboard can come later. |

## Key UX Decisions

| Decision | Rationale | Applies To | Acceptance Signal / Test |
| --- | --- | --- | --- |
| Export preview must show included components and redaction state. | Owners need confidence before transferring or downloading. | Export Service, Provider Transfer. | `wf_export-migration`, `vt_export_assemble`, `vt_export_redaction`. |
| Protected data is redacted/split by default for provider transfer. | Sensitive data must not silently move to a target provider. | Protected Vault, Export Service. | `wf_export-migration`, `ct_protected-vault__import-export_redaction`. |
| Import replay must be idempotent. | Migration retries should not duplicate sensitive records. | Import Service, Protected Vault. | `wf_export-migration`, `vt_import_commit`. |
| Provider transfer exposes verify and rollback outcomes. | Owners need a recovery path when target validation fails. | Provider Transfer Service. | `wf_export-migration`, `vt_provider-transfer_rollback`. |
| Final readiness requires API inventory and full workflow regression evidence. | B8 is the phase-plan closeout gate. | API Spec Inventory, Test Manifest, Build Tracker. | `vt_api_specs_complete`, full Set B workflow run. |

## Key Implementation Decisions

| Implementation Decision | UX Impact | Owning Component | Tests / Gates |
| --- | --- | --- | --- |
| Add `rolledBack` state and `rollbackTransfer` to the local provider-transfer contract. | Allows rollback to be tested and surfaced distinctly from unverified transfers. | provider-transfer-service, API contracts | `vt_provider-transfer_rollback`, `wf_export-migration`. |
| Use `CommunityDataSchemaApi.exportableSchemas` for extension custom-data export evidence. | Gives extension builders a clear path to mark custom data exportable. | data-schema-store | `wf_export-migration`. |
| Add a no-dependency API inventory validator. | Makes `vt_api_specs_complete` runnable from WSL in Phase B8. | api-spec-inventory | `vt_api_specs_complete`. |
| Treat redacted export checksum as required evidence. | Owners can compare package readiness without inspecting raw sensitive data. | export-service | `wf_export-migration`. |

## Workflow Walkthrough

| Step | User Goal / Action | Screen or State | Owning Component | UX Decision Applied | Covering Test |
| --- | --- | --- | --- | --- | --- |
| 1 | Start export | Owner starts community export from local validation flow. | export-service | Explicit export scope. | `wf_export-migration` |
| 2 | Preview included components | Bundle lists documents, wallet, receipt, export/import, and registry coverage. | export-service, data-schema-store | Component preview. | `wf_export-migration` |
| 3 | Explain protected-data redaction | Redacted export includes protected-vault redaction marker. | protected-visibility-vault, export-service | Redaction first-class. | `wf_export-migration` |
| 4 | Generate checksum | Bundle exposes checksum for full and redacted exports. | export-service | Verification evidence. | `wf_export-migration` |
| 5 | Transfer provider package | Transfer targets provider ID with redacted bundle. | provider-transfer-service | Target identity required. | `wf_export-migration` |
| 6 | Verify target state | Transfer is explicitly verified. | provider-transfer-service | Verify before complete. | `wf_export-migration` |
| 7 | Handle rollback | Separate transfer can roll back and records `rolledBack=true`. | provider-transfer-service | Rollback is visible. | `wf_export-migration` |
| 8 | Display final readiness/regression summary | Tracker and manifest show full B1a-B8 workflow pass and API inventory pass. | phase-test-manifest-bridge, api-spec-inventory | Final readiness gate. | `vt_api_specs_complete`, full Set B run |

## Open Questions / Tradeoffs

| Question / Tradeoff | Options Considered | Recommendation | Owner | Resolution Required Before |
| --- | --- | --- | --- | --- |
| Should checksums be package-level SHA-256 now? | Deterministic fake checksum now; real archive SHA-256 later. | Keep fake checksum for B8; add real archive digest in package builder. | Export/API owner | Hosted/export package implementation |
| How much retained/audit data should export include? | Include all audit data; include redacted audit; separate legal export. | Keep redacted audit policy separate from member/community portability export. | Trust/Safety + Legal | Compliance export features |
| Should rollback undo verified transfers? | Allow rollback only before verify; allow post-verify rollback; require new transfer. | B8 validates rollback on a transfer that has not verified. Hosted behavior should require policy decision. | Provider Transfer owner | Hosted provider transfer |

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
