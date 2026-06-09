# Phase A2 - API Review

Status: Template

## Scope

Registry/control-plane APIs: community registry, spaces, membership, invitation, extension registry,
certification, public registry, workflow inventory, test manifest bridge.

## Review Checklist

- Handle/QR resolution shape.
- Community profile and branding shape used by App Shell cards.
- Space hierarchy and membership state transitions.
- Certification status and risk tier shape.
- Latest-version and revocation behavior.
- Manifest bridge fields for test status and staleness.

## OpenAPI Outputs

Record registry/control-plane spec additions and gaps, including community branding fields and asset
references consumed by App Shell card rendering.

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
