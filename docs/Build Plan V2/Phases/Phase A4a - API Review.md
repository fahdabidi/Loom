# Phase A4a - API Review

Status: Completed in A4a

## Scope

Ops/community service APIs: case/task, documents, facilities, import, export, provider transfer,
abuse reports, moderation, incidents, disputes.

## Review Checklist

- Case/task transition shape.
- Document permission and export behavior.
- Facility reservation and payment coupling.
- Import dry-run and commit semantics.
- Export redaction and checksums.
- Incident/dispute policy-versioned decisions.

## OpenAPI Outputs

Record ops/community-service spec additions and gaps.

## A4a Contract Additions

- `CommunityCaseTaskApi`
- `CommunityDocumentsApi`
- `CommunityFacilitiesApi`
- `CommunityImportApi`
- `CommunityExportApi`
- `CommunityProviderTransferApi`
- `CommunityAbuseReportApi`
- `CommunityModerationApi`
- `CommunityIncidentApi`
- `CommunityDisputeApi`

These contracts are currently implemented as typed Dart contracts in
`app/packages/core/loom_api_contracts/lib/clients/community_ops_apis.dart` and in-memory fakes in
`app/packages/core/loom_fake_backend/lib/community_ops_fake.dart`.

## OpenAPI Follow-Ups

- Add public specs for case transitions, document visibility, facility reservations, import dry-run and
  commit, export redaction, provider transfer verification, abuse reports, moderation lifecycle,
  incidents, and disputes.
- Keep wallet, search, workflow-engine, data-schema-store, and fraud consumer contracts pending until
  A4b/A5 components exist.

## Validation Evidence

- `vt_case-task_transition`
- `vt_documents_permissions`
- `vt_facilities_reservation`
- `vt_import_dry-run`
- `vt_import_commit`
- `vt_export_assemble`
- `vt_export_redaction`
- `vt_provider-transfer_execute-verify`
- `vt_abuse-report_submit`
- `vt_moderation_case-lifecycle`
- `vt_incident_create`
- `vt_dispute_open-case`
- `ct_documents__export_include-documents`
- `ct_import__protected-vault_write`
- `ct_protected-vault__import-export_redaction`
- `ct_incident__certification_revoke`

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
