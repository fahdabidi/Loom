# Phase B8 - API Review

Status: Completed

## Scope

Export and migration workflow: export scope, protected redaction, extension custom-data schema export,
import replay, checksum evidence, provider transfer verification, rollback, receipt inclusion, and
final API inventory validation.

## Review Checklist

- Export scope and package manifest: covered by `CommunityExportApi.assemble`.
- Protected redaction/splitting: covered by redacted export component marker and
  `CommunityProtectedVaultApi`.
- Extension data schema export: covered by `CommunityDataSchemaApi.registerSchema` and
  `exportableSchemas`.
- Import replay/idempotency: covered by `CommunityImportApi.dryRun` and `commit`.
- Checksums and receipt fields: export bundle exposes checksum; receipt ledger exposes payment receipts.
- Provider transfer verification: covered by `CommunityProviderTransferApi.executeTransfer` and
  `verifyTransfer`.
- Provider transfer rollback: added `CommunityProviderTransferApi.rollbackTransfer` and
  `CommunityProviderTransfer.rolledBack`.
- Final API inventory: covered by
  `dart run packages/tooling/api_spec_inventory/bin/validate_api_specs.dart --manifest ../docs/Build\ Plan\ V2/test-manifest.json`.

## OpenAPI Outputs

- Hosted Export OpenAPI should add explicit archive format, SHA-256 checksum, signed manifest,
  export scope, included component list, omitted component list, retained-record disclosure, and
  redaction policy fields.
- Hosted Import OpenAPI should add preview warnings, resumable job IDs, conflict handling, duplicate
  detection, idempotent replay IDs, and protected-field routing.
- Provider Transfer OpenAPI should expose states beyond `verified`/`rolledBack`: pending, verifying,
  failed, rolled_back, complete, and cancellation policy.
- Data Schema OpenAPI should document exportable custom schemas and non-exportable runtime caches.
- Receipt/OpenAPI export should include receipt linkage without exposing private payment details beyond
  the actor's allowed export scope.
- API inventory validator confirms every V2 manifest component has a contract name, implementation
  phase, local fake/backend contract, and workflow tests target the Demo App with Local Backend.

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
