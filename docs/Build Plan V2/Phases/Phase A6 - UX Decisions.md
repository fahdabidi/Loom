# Phase A6 - UX Decisions

Status: Template

## Reference Sources Reviewed

Record App Shell, navigation, stream, ad slot, payment, data dashboard, and accessibility references.

## UX Patterns Extracted

Record patterns that preserve required Loom structure while allowing extension customization.

## Key UX Decisions

- Required Messages and Connections navigation.
- Top banner and in-stream ad behavior.
- Shell-owned payment and consent surfaces.
- Extension route boundaries.

## Workflow Walkthrough

Show how the UX micro-components support later workflow phases.

## Open Questions

Record design risks for Set B.

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
