# Phase B4 - UX Decisions

Status: Template

## Reference Sources Reviewed

HOA portals, dues, document libraries, facility reservations, request approval queues.

## UX Patterns Extracted

Record patterns for owner/admin/member HOA workflows.

## Key UX Decisions

Record dues, documents, facility, case/task, and export UI decisions.

## Workflow Walkthrough

Walk through `wf_hoa-headline`.

## Open Questions

Record unresolved workflow UX risks.

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
