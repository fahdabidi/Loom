# Phase B1b - UX Decisions

Status: Template

## Reference Sources Reviewed

QR install, app install, permission review, certification, and package publish flows.

## UX Patterns Extracted

Record patterns for install trust, certification status, permission clarity, latest-version updates,
and the difference between local sideload and hosted install.

## Key UX Decisions

Record publish, QR/handle, install, and latest-open UI decisions.

## Workflow Walkthrough

Walk through `wf_build-publish-discover-install`.

## Open Questions

Record unresolved hosted workflow UX risks.

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
