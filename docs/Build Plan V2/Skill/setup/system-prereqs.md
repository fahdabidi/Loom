# Skill System Prereq Setup

Status: Phase 0 skeleton

This setup guide defines the local tools the Loom Skill must prepare before it can claim that an
extension has been validated. The first supported execution targets are Codex and Claude Code. Online
chat-only surfaces are out of scope until Loom provides a hosted build and validation backend.

## Responsibilities

The Skill prereq setup component must:

- Detect host OS, shell, repo path, execution target, and available package managers.
- Read [prereq-manifest.json](./prereq-manifest.json).
- Produce an install/configuration plan before changing the environment.
- Install or configure only approved tools.
- Verify tool versions and command availability.
- Boot or smoke-check the Demo Loom Communities App validation target.
- Write [validation-environment.lock.json](./validation-environment.lock.json).

## Required Tool Classes

| Tool class | Purpose | Required for |
| --- | --- | --- |
| Flutter and Dart | Build and test the Loom Communities Demo App. | `local-demo`, `real-backend-publish` local validation |
| Melos | Bootstrap and orchestrate the monorepo. | all validation |
| Git | Version, diff, fixture, and artifact hash tracking. | all validation |
| Java/JDK and Android SDK | Android emulator and integration test support. | Demo App validation |
| Android emulator, platform tools, and adb | Run the local Demo App workflow. | Demo App validation |
| Archive tools | Create and inspect downloadable extension and initialization packages. | package generation |
| JSON/YAML/schema validators | Validate extension manifests, initialization payloads, and prereq manifests. | package validation |
| Node/package manager | Optional package-builder or UI-validator support when required by the repo. | conditional |
| Loom tooling | `manifest_gate`, `phase_gate`, extension validator, initialization validator, and local workflow tests. | all phase gates |

## Setup Flow

1. Select execution target: Codex or Claude Code.
2. Detect host capabilities and unsupported gaps.
3. Load the prereq manifest and choose required tools for the selected Skill mode.
4. Produce an install plan and wait for explicit approval where the execution environment requires it.
5. Install/configure tools.
6. Run verification commands.
7. Run the Demo App smoke check.
8. Write the environment lock.
9. Expose `validationReady=true` to the workflow validation harness.

## Phase Gate

B1a cannot start workflow validation until:

- `vt_skill-prereq_manifest-complete` passes.
- `vt_skill-prereq_host-detection` passes.
- `vt_skill-prereq_install-plan` passes.
- `vt_skill-prereq_environment-lock` passes.
- `vt_skill-prereq_demo-app-smoke` passes.
- `ct_skill-prereq-setup__workflow-validation-harness_environment-ready` passes.
- `wf_local-demo-prereq-to-validation-ready` is stamped in the manifest.
