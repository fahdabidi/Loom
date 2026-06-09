# Phase A4a - API Review

Status: Template

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
