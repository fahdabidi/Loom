# Phase B1b - API Review

Status: Template

## Scope

Hosted build, publish, discover, certify, and install workflow.

## Review Checklist

- Package manifest fields.
- App ID signing and artifact attestation.
- Certification result and remediation shape.
- QR/handle payload.
- Latest certified version resolution.
- Install grant and permission review.
- Compatibility with B1a local package and initialization package contracts.

## OpenAPI Outputs

Record workflow-driven spec gaps for hosted publish, registry, certification, discovery, install, and
latest-open APIs. Every hosted API behavior must have a local backend stub or contract fake for Set B
validation.

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
