# Phase B1a - UX Decisions

Status: Completed in B1a

## Reference Sources Reviewed

Empty-state app launch, emulator file loading, local package validation, branding asset validation,
import progress, duplicate import behavior, branded community-card fallback behavior, and local
developer app flows.

## UX Patterns Extracted

- First launch is an empty state with one primary Add Community action.
- A deterministic sample local package is used in this phase while B1a establishes workflow tests.
- Branded card preview uses imported local backend branding props.
- Card launch opens a local latest extension route in App Shell.

## Key UX Decisions

- Empty state text: `No communities installed`.
- Add Community is exposed as a floating action and in the empty state.
- Accepted local file types remain `.loom-extension.zip` and `.loom-init.zip`.
- Card image fallback follows A6 priority rules.
- B1a validates the route as `local:<extension-id>@latest`.

## Workflow Walkthrough

1. Skill prereq manifest and environment lock validate Codex local-demo readiness.
2. Skill generates the book-club package pair.
3. Demo App starts empty.
4. Local backend loads the extension package summary.
5. Local backend imports the initialization package summary and branding props.
6. App Shell renders a card and opens `local:ext_book_club@latest`.

## Open Questions

- B1a still uses a deterministic sample action; emulator file picking and validation-error UI become
  B1a/B2 hardening work if needed before real user testing.

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
