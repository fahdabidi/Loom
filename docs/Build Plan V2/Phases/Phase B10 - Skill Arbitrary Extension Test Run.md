# Phase B10 - Skill Arbitrary Extension Test Run

Workflow bundle: Skill emits an arbitrary local-demo extension/init pair -> artifacts are saved as a
replayable example -> Demo App Local Backend loads those generated artifacts -> imported community
renders and opens locally -> failures feed the Skill iteration loop.
Components involved: AI Skill / Extension Builder, Skill Debug Harness, Extension Package Validator,
Initialization Package Schema, Local In-App Backend, Loom Communities Demo App, Community Card, App
Shell Runtime.
UX gate: high
Gate: `wf_skill-arbitrary-extension-test-run` plus affected B9/B1a/A6 regressions pass.

## WSL Ubuntu Tooling Requirement

Run all phase tooling from WSL Ubuntu, not Windows PowerShell. Use this command shape from the Windows host:

```powershell
wsl.exe -d Ubuntu -- bash -lc 'cd "/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app" && <command>'
```

Inside WSL Ubuntu, `dart`, `flutter`, and `melos` must resolve from the Ubuntu toolchain. Do not run
Dart, Flutter, Melos, package validation, manifest gates, phase gates, or workflow tests from
Windows-native shells.

## 0. Prerequisite Gate

- B9 complete and committed.
- Arbitrary local package ingestion is green.
- Skill walkthrough explains local-demo and arbitrary package ingestion.
- The B10 example contains package manifests that are not Book Club or another anchor vertical.

## 1. Workflows and End States

| Workflow | End state |
| --- | --- |
| `wf_skill-arbitrary-extension-test-run` | A Skill-produced arbitrary Garden Club example is replayed into the Demo App Local Backend and opens as `local:ext_garden_club@latest`. |

User stories:

| Story | End state | Required tests |
| --- | --- | --- |
| B10-US1 Save arbitrary Skill output | Skill example folder contains generated extension and initialization manifests for an arbitrary non-anchor extension. | `wf_skill-arbitrary-extension-test-run` |
| B10-US2 Replay artifacts locally | The generated manifests are copied into local-demo package paths and parsed by the Local In-App Backend. | `wf_skill-arbitrary-extension-test-run` |
| B10-US3 Validate installed result | Imported card uses generated community name, branding asset references, seed data list, and local latest route. | `wf_skill-arbitrary-extension-test-run` |

## 2. Workflow Tests Mapped to Owning Components

| Step | Owning component | Supporting tests |
| --- | --- | --- |
| Read Skill example artifacts | ai-skill-extension-builder, skill-debug-harness | `wf_skill-arbitrary-extension-test-run` |
| Validate local-demo package shape | extension-package-validator, initialization-package-schema | `wf_skill-arbitrary-extension-test-run` |
| Load generated artifacts | local-in-app-backend | `wf_skill-arbitrary-extension-test-run` |
| Render generated card | community-card, loom-communities-demo-app | `wf_skill-arbitrary-extension-test-run` |
| Open local latest extension | app-shell-runtime | `wf_skill-arbitrary-extension-test-run` |

## 3. UX Research and Decisions

Complete `Phase B10 - UX Decisions.md` before implementation work that affects UI, interaction,
user-visible state, workflow copy, or Skill iteration behavior. The UX Decisions file is a gate
artifact and must follow R20.

## 4. Execution and Issue-Triage Loop

Run `wf_skill-arbitrary-extension-test-run`. On failure:

1. If the generated artifact is missing required data, update the Skill artifact/review docs before
   changing app code.
2. If the parser rejects a documented Skill field, update the Local In-App Backend validation test first.
3. If the Demo App renders fixture data, update B9/B10 widget or workflow coverage first.
4. Rebuild or replay the arbitrary example, then rerun B10 plus B9/B1a/A6 regressions.

## 5. Per-Component Regression Gate

If any involved component changes, run:

- `dart test packages/core/loom_demo_local_backend/test/a6_local_backend_test.dart`
- `flutter test apps/loom_communities_demo/test/a6_loom_communities_demo_test.dart apps/loom_communities_demo/test/b1a_local_workflow_test.dart apps/loom_communities_demo/test/b9_arbitrary_local_package_ingestion_test.dart apps/loom_communities_demo/test/b10_skill_arbitrary_extension_test.dart`
- `dart analyze packages/core/loom_demo_local_backend`
- `flutter analyze apps/loom_communities_demo`

## 6. Skill Contribution

Add:

- `Skill/workflows/skill-arbitrary-extension-test-run.md`
- `Skill/examples/arbitrary-garden-club/README.md`
- `Skill/examples/arbitrary-garden-club/loom.extension.json`
- `Skill/examples/arbitrary-garden-club/loom.initialization.json`

Update the master Skill walkthrough to require replaying arbitrary generated output before approving a
new local-demo extension.

## 7. Manifest Update

Stamp `wf_skill-arbitrary-extension-test-run` and affected component/test hashes. Any change to the
arbitrary example manifests updates the workflow test hash.

## 8. API Review

Create `Phase B10 - API Review.md`. Record Skill example payload shape, alias fields supported by the
local parser, and remaining archive/package-builder gaps.

## 9. Definition of Done

B10 is complete only when the arbitrary Skill example replays through the Demo App Local Backend,
renders the generated card, opens local latest, regressions pass, UX/API/Skill docs are updated,
manifest stamps are current, and the commit SHA is recorded in the tracker.

## Commit Gate

Before starting the next phase:

- Stage only this phase's intended changes.
- Run `git diff --staged` and confirm the staged scope matches this phase.
- Commit the phase changes.
- Record the resulting commit SHA in [../Build Tracker.md](../Build%20Tracker.md).
- Do not begin any follow-on phase until the commit exists and the tracker points to it.

## 10. Next Phase

Proceed to [Phase B11 - Skill Prompt Build Validate Complete.md](./Phase%20B11%20-%20Skill%20Prompt%20Build%20Validate%20Complete.md).
