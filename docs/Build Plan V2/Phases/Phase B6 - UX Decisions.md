# Phase B6 - UX Decisions

Status: Template

## Reference Sources Reviewed

Messaging, connection graph, invite/block, stream ads, and shell ad patterns.

## UX Patterns Extracted

Record required navigation and ad-disclosure patterns.

## Key UX Decisions

Record Messages, Connections, stream renderer, and ad slot UI decisions.

## Workflow Walkthrough

Walk through `wf_messaging-ads-connections`.

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
