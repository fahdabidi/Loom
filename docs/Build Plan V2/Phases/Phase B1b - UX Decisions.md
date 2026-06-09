# Phase B1b - UX Decisions

Status: Completed

## Reference Sources Reviewed

QR install, app install, permission review, certification, package publish, and B1a local sideload
flows.

## UX Patterns Extracted

- Hosted install should show certification state before install.
- Permission review should display package permissions before the local backend import/install step.
- QR and handle discovery resolve the same community profile.
- Latest-version open is a routing behavior, not a separate user choice in the preliminary Demo App.
- Local sideload remains visibly separate from publish-ready mode because B1b still uses fakes.

## Key UX Decisions

- Publish-ready packages carry `real-backend-publish` metadata but remain locally downloadable.
- The Demo App can validate hosted publish semantics without showing hosted backend screens.
- The community card continues to be the post-install entry point.
- Certification and trust state are represented in test output and package metadata for now; richer UI
  treatment can wait for hosted backend screens.

## Workflow Walkthrough

`wf_build-publish-discover-install` registers a builder App ID, certifies the package, publishes the
certified version, resolves the community by handle/QR, imports the initialization package locally,
renders the community card, and opens `local:<extension-id>@latest`.

## Open Questions

- Whether hosted install should expose a separate "review certification evidence" screen.
- Whether QR install should land on a pre-install preview or directly on permission review.

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
