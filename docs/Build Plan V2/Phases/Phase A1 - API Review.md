# Phase A1 - API Review

Status: Template

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
