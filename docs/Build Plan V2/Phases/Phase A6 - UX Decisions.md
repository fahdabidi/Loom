# Phase A6 - UX Decisions

Status: Completed in A6

## Reference Sources Reviewed

- Architecture V2/00 UX micro-component rules.
- Product Docs V2/15 Main Loom App, App Shell, and Required Structure.
- A5 package and initialization package contracts.
- A6 App Shell and local backend tests.

## UX Patterns Extracted

- Shell-owned navigation, top ad slot, payment surface, and data dashboard.
- Extension-owned content routes mounted inside the shell.
- Community-card branding priority: community card image, community logo, extension default card image,
  generated fallback.
- Local-demo empty state with a single Add Community action.

## Key UX Decisions

- Required Messages and Connections navigation.
- Top banner and in-stream ad behavior.
- Shell-owned payment and consent surfaces.
- Extension route boundaries.
- Demo App starts empty and does not preload communities.
- The first A6 Add Community action uses a deterministic sample local package while B1a replaces it
  with emulator local-file selection.
- Community cards are rendered by shell/local-backend props, not arbitrary extension card UI.

## Workflow Walkthrough

1. User opens the Demo App and sees no installed communities.
2. User selects Add Community.
3. Local backend loads an extension package summary and initialization package summary.
4. Local backend imports branding and seed metadata idempotently.
5. App renders a community card from typed branding props.
6. User opens the card and the App Shell records the local extension route.

## Open Questions

- B1a should replace the sample Add Community handler with emulator-safe local file picking.
- B1a should add screenshot evidence for empty state, loaded card, and opened local extension.
- B1a should decide whether generated initials fallback uses category text or a deterministic icon.

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
