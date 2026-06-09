# Phase B7 - API Review

Status: Template

## Scope

Ad-off workflow: checkout, entitlement, ad suppression, receipts, settlement, utility allocation.

## Review Checklist

- Ad-off entitlement scope.
- Member vs community ad-off.
- Sensitive no-fill still enforced.
- Receipt and settlement fields.
- Utility funding allocation fields.

## OpenAPI Outputs

Record workflow-driven spec gaps.

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
