# Phase A1 - API Review

Status: Completed in A1

## Scope

Foundation APIs: Passport, role/policy/consent, core vault, protected vault, connections, receipts,
audit, event bus, key management, builder App ID.

## Review Checklist

- Contract-first request/response shapes.
- Idempotency keys on mutations.
- Version fields.
- Redacted audit fields for sensitive data.
- Fake dependency coverage.
- Consumer-contract test kits for dependents.

## OpenAPI Outputs

Record new or updated specs under `docs/API/OpenAPI/**`.

## A1 Contract Additions

- `CommunityPassportApi`
- `CommunityRolePolicyApi`
- `CommunityCoreVaultApi`
- `CommunityProtectedVaultApi`
- `CommunityConnectionsApi`
- `CommunityReceiptLedgerApi`
- `CommunityAuditApi`
- `CommunityEventBusApi`
- `CommunityKeyManagementApi`
- `CommunityBuilderAppIdApi`

These contracts are currently implemented as typed Dart contracts in
`app/packages/core/loom_api_contracts/lib/clients/community_foundation_apis.dart` and in-memory fakes
in `app/packages/core/loom_fake_backend/lib/community_foundation_fake.dart`.

## OpenAPI Follow-Ups

- Add public OpenAPI specs for the Foundation APIs when the HTTP boundary is introduced.
- Keep the A1 fake contracts as the source for package-level validation until API transport is built.
- Mark higher-layer consumer-contract tests as `pending-counterpart` until their consumers exist.

## Validation Evidence

- `vt_passport-ledger_create-resolve`
- `vt_role-policy_effective-permission`
- `vt_core-vault_preferences`
- `vt_protected-vault_read-gated`
- `vt_connections_invite-permission`
- `vt_receipt-ledger_append`
- `vt_event-bus_publish`
- `vt_builder-app-id_signing-scope`

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
