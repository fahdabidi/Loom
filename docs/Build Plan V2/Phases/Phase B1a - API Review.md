# Phase B1a - API Review

Status: Template

## Scope

Local build, download, sideload, fake-backend import, local DB persistence, and App Shell open flow.

## Review Checklist

- Extension package manifest fields and local artifact metadata.
- Extension package asset manifest, local asset paths, hashes, dimensions, allowed formats, file size
  limits, and alt/decorative metadata.
- Initialization package schema, idempotency key, import report, and rollback behavior.
- Initialization package community branding payload and seed asset paths.
- Demo App local loader API.
- Fake backend import/reset/reload APIs.
- Local asset cache and community-card branding props.
- Local DB persistence and reload contract.
- Stubbed API behavior when no hosted backend is present.
- Validator diagnostics returned to the Skill.
- Skill prereq manifest schema and environment-lock schema.
- Validation-ready signal consumed by the workflow validation harness.
- Execution target notes for Codex and Claude Code.

## OpenAPI Outputs

Record local package, initialization package, fake backend, local DB, Demo App loader, and App Shell
local-session spec gaps. Specs may be local-contract files rather than public hosted OpenAPI endpoints,
but they must validate before B1a completes.

## Skill Prereq Contracts

The API review must record the local tooling contracts that are not public OpenAPI specs:

- `LoomSkillPrereqSetupApi`
- `LoomValidationEnvironmentApi`
- `prereq-manifest.json`
- `validation-environment.lock.json`

The review must confirm that online-only execution targets are documented as deferred until a hosted
Loom build and validation backend exists.

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
