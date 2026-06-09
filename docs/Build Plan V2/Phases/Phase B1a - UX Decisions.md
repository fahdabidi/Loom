# Phase B1a - UX Decisions

Status: Template

## Reference Sources Reviewed

Empty-state app launch, emulator file loading, local package validation, branding asset validation,
import progress, duplicate import behavior, branded community-card fallback behavior, and local
developer app flows.

## UX Patterns Extracted

Record patterns for first community install, local file picker affordances, package trust warnings,
validation error recovery, asset error recovery, import progress, import rollback, branded card
preview, and card launch.

## Key UX Decisions

Record the exact empty state, `Add Community` placement, accepted local file types, package validation
error display, branding asset error display, card image fallback order, initialization import
confirmation, and card-to-App-Shell transition.

## Workflow Walkthrough

Walk through `wf_local-build-download-sideload-install`.

## Open Questions

Record unresolved local install UX risks.

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
