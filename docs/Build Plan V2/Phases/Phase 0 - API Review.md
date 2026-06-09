# Phase 0 - API Review

Status: Template

## Scope

Initialization artifacts, manifest schema, gate scripts, Skill skeleton, Skill prereq setup, and V2
workspace contracts.

## API / Contract Questions

- Which V2 contracts already exist in V1 form?
- Which contracts require new OpenAPI specs?
- Which contracts are scaffolded only and completed in Set A?
- Which prereq setup contracts are local tooling contracts rather than public OpenAPI specs?
- What fields belong in the validation environment lock schema?

## Required Output

- OpenAPI inventory delta.
- Manifest schema review.
- Gate script contract review.
- Skill prereq manifest and environment-lock schema review.
- Execution target support notes for Codex and Claude Code.
- Spec gaps filed for component phases.

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
