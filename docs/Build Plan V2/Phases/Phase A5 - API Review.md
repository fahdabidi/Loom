# Phase A5 - API Review

Status: Template

## Scope

Extension engine APIs: runtime bridge, event bus use, rules, workflows, jobs, functions, data schemas,
secrets/connectors, extension package manifests, and initialization packages.

## Review Checklist

- Runtime session scope.
- Permission enforcement.
- Rule/action and workflow state-machine versioning.
- Job idempotency.
- Function sandbox limits.
- Schema export/index policy.
- Downloadable extension package shape.
- Locked package directory layout for `.loom-extension.zip`.
- Asset manifest fields, asset hashes, dimensions, allowed formats, file size limits, and alt/decorative metadata.
- Initialization package schema, idempotency key, import report, and rollback behavior.
- Locked package directory layout for `.loom-init.zip`.
- Community branding seed schema: logo, card image, hero image, accent color, fallback behavior.

## OpenAPI Outputs

Record extension-engine spec additions and gaps, including local package and initialization package
contracts used by B1a. Include package asset validation and initialization branding contracts.

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
