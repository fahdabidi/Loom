# Phase 0 - Initialize Build

Surface: tooling/docs/workspace
UX gate: low
On green: proceed to A1
Rules: [Rules.md](../Rules.md)

## WSL Ubuntu Tooling Requirement

Run all phase tooling from WSL Ubuntu, not Windows PowerShell. Use this command shape from the Windows host:

```powershell
wsl.exe -d Ubuntu -- bash -lc 'cd "/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app" && <command>'
```

Inside WSL Ubuntu, `dart`, `flutter`, and `melos` must resolve from the Ubuntu toolchain. Do not run Dart, Flutter, Melos, package validation, manifest gates, phase gates, or workflow tests from Windows-native shells.

## 0. Prerequisite Gate

No prior phase. Verify local execution environment only:

- `app/` exists or is created as the V2 melos workspace root.
- WSL Ubuntu is available and `dart`, `flutter`, and `melos` resolve inside Ubuntu.
- Flutter/Dart/melos/tooling prerequisites are documented through the Skill setup manifest.
- Git worktree status is recorded before generation begins.

## 1. Build the Test Manifest

Create and validate:

- [../test-manifest.json](../test-manifest.json)
- [../Test Manifest.md](../Test%20Manifest.md)

The manifest must enumerate:

- Every planned validation test `vt_<component>_<capability>` for Set A.
- Every planned consumer-contract test `ct_<provider>__<consumer>_<scenario>`.
- Every planned workflow test `wf_<workflow-id>` for Set B.
- Owning component, covered components, dependents, first implementation phase, status, component
  version stamps, and `testHash`.

Initial statuses:

- `planned` for tests with no built component yet.
- `pending-counterpart` for consumer-contract tests whose counterpart is not built.

## 2. Establish the Rules

Publish:

- [../Rules.md](../Rules.md)
- [../README.md](../README.md)

Rules R1-R20 are binding. Phase docs may add checks but cannot weaken the rules.

Phase 0 also establishes the required UX Decisions standard used by every UI or workflow phase. Each
`Phase X - UX Decisions.md` must require reference implementations, extracted UX patterns, key UX
decisions, key implementation decisions, a workflow walkthrough, and open questions/tradeoffs before
implementation starts.

## 3. Scaffold the Skill

Create:

- [../Skill/SKILL.md](../Skill/SKILL.md)
- [../Skill/using-loom-to-build-an-extension.md](../Skill/using-loom-to-build-an-extension.md)
- `Skill/components/`
- `Skill/workflows/`
- `Skill/examples/book-club/`
- `Skill/examples/youth-soccer/`
- `Skill/examples/hoa/`
- `Skill/examples/mosque/`
- `Skill/setup/system-prereqs.md`
- `Skill/setup/prereq-manifest.json`
- `Skill/setup/execution-targets/codex.md`
- `Skill/setup/execution-targets/claude-code.md`
- `Skill/setup/validation-environment.lock.json`
- `Skill/setup/troubleshooting.md`

The initial Skill must explain the Loom trust boundary, required App Shell structure, permission model,
extension package shape, initialization package shape, validation loop, local download/sideload loop,
locked asset/branding format, Skill debug loop, system prereq setup, canonical Codex/Claude Code
execution targets, deferred online-only support, certification path, and publish -> QR/handle ->
install -> latest loop.

## 4. Scaffold the V2 Workspace

Create or confirm package namespaces for:

- `loom_api_contracts`
- `loom_fake_backend`
- `loom_local_store`
- `loom_seed_data`
- `loom_app_shell`
- `loom_design_system`
- `loom_extension_package`
- `loom_demo_local_backend`
- `apps/loom_communities_demo`
- `loom_lints`
- `loom_skill_prereq_setup`
- `loom_skill_debug_harness`
- `api_spec_inventory`
- `packages/tooling/manifest_gate.dart`
- `packages/tooling/phase_gate.dart`
- `packages/tooling/skill_prereq_setup.dart`
- `packages/tooling/skill_prereq_check.dart`

No domain implementation is required in Phase 0 beyond enough scaffolding for the gates to exist.
The demo app scaffold must include placeholders for the empty community state, local file loader,
local DB adapter, fake backend import endpoint, and reset/reload test hooks.
The Skill prereq scaffold must include enough placeholders to parse the prereq manifest, detect the
execution target, produce an install plan, and write a placeholder validation environment lock.

## 5. Build Tracker

Create and initialize [../Build Tracker.md](../Build%20Tracker.md).

The tracker must have all phases from 0 through B8, including the pre-split A4a/A4b service phases.

## 6. API Review

Create `Phase 0 - API Review.md`.

Record:

- Which Architecture V2 components imply OpenAPI specs.
- Which V1 specs can be reused or renamed.
- Which V2 contracts are new.
- Which specs are deferred to component phases.
- Which local-only package, initialization, and fake-backend APIs are required before B1a.
- Which Skill prereq setup APIs and environment-lock schema are required before local workflow
  validation can run.

## 7. Definition of Done

Phase 0 is complete when:

- Manifest parses as valid JSON.
- Manifest gate can run and report expected `planned` / `pending-counterpart` states.
- Rules, README, tracker, and Skill skeleton exist.
- Workspace scaffold and gate script placeholders exist.
- Loom Communities Demo App, local fake-backend adapter, extension package schema, initialization
  package schema, Skill prereq setup, Skill debug harness, and API spec inventory placeholders exist.
- Skill setup docs exist and `prereq-manifest.json` plus placeholder
  `validation-environment.lock.json` parse as valid JSON.
- API Review filed.
- Build Tracker records Phase 0 gate evidence and commit SHA.

## Commit Gate

Before starting the next phase:

- Stage only this phase's intended changes.
- Run `git diff --staged` and confirm the staged scope matches this phase.
- Commit the phase changes.
- Record the resulting commit SHA in [../Build Tracker.md](../Build%20Tracker.md).
- Do not begin the next phase until the commit exists and the tracker points to it.

## 8. Next Phase

Proceed to [Phase A1 - Foundation Components.md](./Phase%20A1%20-%20Foundation%20Components.md).
