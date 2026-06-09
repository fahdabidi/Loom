# Phase A4b - API Review

Status: Template

## Scope

Economic/search/ad service APIs: wallet, ad decision, ad campaign, search, indexing, AI gateway,
digest, settlement, utility funding, fraud signals.

## Review Checklist

- Payment/ad-off idempotency.
- Sensitive ad no-fill reason shape.
- No paid search ranking fields.
- AI citation/source policy fields.
- Receipt and settlement allocation fields.
- Fraud hold/adjustment shape.

## OpenAPI Outputs

Record economic/search/ad-service spec additions and gaps.

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
