# Phase A3 - API Review

Status: Template

## Scope

Experience service APIs: publishing, messaging/stream, notifications, events, forms, polls, voting.

## Review Checklist

- Pagination and bounded reads.
- Stream item taxonomy.
- Event/RSVP state transitions.
- Protected field routing for forms.
- Notification delivery and dedupe.
- Provider-authored contract tests for search, stream renderer, workflow engine, and App Shell consumers.

## OpenAPI Outputs

Record experience-service spec additions and gaps.

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
