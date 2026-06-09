# Phase B1a - Local Build, Download, Sideload, Install

Workflow bundle: Skill generates downloadable extension package + initialization package with bundled
branding assets -> Demo App starts empty -> Add Community -> local file load from emulator file system
-> fake backend import -> branded community card appears -> open latest local extension in App Shell.
Components involved: Skill, Skill Prereq Setup, Workflow Validation Harness, Extension Package
Validator, Initialization Package Schema, Loom Communities Demo App, Local In-App Backend, Local
Store, App Shell, Community Card, Extension Runtime.
UX gate: high
Gate: `wf_local-build-download-sideload-install` plus affected component regressions pass.

## WSL Ubuntu Tooling Requirement

Run all phase tooling from WSL Ubuntu, not Windows PowerShell. Use this command shape from the Windows host:

```powershell
wsl.exe -d Ubuntu -- bash -lc 'cd "/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app" && <command>'
```

Inside WSL Ubuntu, `dart`, `flutter`, and `melos` must resolve from the Ubuntu toolchain. Do not run Dart, Flutter, Melos, package validation, manifest gates, phase gates, or workflow tests from Windows-native shells.

## 0. Prerequisite Gate

- A6 complete and committed.
- All Set A required tests pass and are not stale.
- Package and initialization schemas from A5 validate.
- Demo App and local in-app backend from A6 are available in the emulator test harness.
- Workflow validation target is the Demo Loom Communities App with the Local Backend.
- Skill setup supports the selected execution target: Codex or Claude Code.
- `Skill/setup/prereq-manifest.json` parses and the setup component produces a current
  `Skill/setup/validation-environment.lock.json`.
- `wf_local-demo-prereq-to-validation-ready` passes before package generation or sideload validation.
- No hosted publish, marketplace, QR, or remote backend is required for this phase.

## 1. Workflows and End States

| Workflow | End state |
| --- | --- |
| `wf_local-demo-prereq-to-validation-ready` | Skill prereq setup detects the local execution target, verifies required tools, writes the environment lock, and proves the Demo App validation harness is reachable. |
| `wf_local-build-download-sideload-install` | A user starts with zero communities, uses `Add Community`, selects a local extension package, imports the initialization package into the fake backend/local DB, sees the new branded community card, and opens the latest local extension in App Shell. |

User stories:

| Story | End state | Required tests |
| --- | --- | --- |
| B1a-US0 Validation environment | Codex or Claude Code environment is detected, required tools are verified, environment lock is written, and Demo App smoke check passes. | `vt_skill-prereq_manifest-complete`, `vt_skill-prereq_host-detection`, `vt_skill-prereq_install-plan`, `vt_skill-prereq_environment-lock`, `vt_skill-prereq_demo-app-smoke`, `ct_skill-prereq-setup__workflow-validation-harness_environment-ready`, `wf_local-demo-prereq-to-validation-ready` |
| B1a-US1 Empty app | Fresh Demo App install shows no community cards and exposes `Add Community`. | `vt_demo-app_empty-community-state`, `vt_demo-app_add-community-button` |
| B1a-US2 Skill local package | Skill generates a downloadable extension package, downloadable initialization package, and bundled branding assets from a golden prompt. | `vt_skill_generate-downloadable-extension`, `vt_skill_generate-initialization-package`, `vt_skill_generate-brand-assets`, `vt_skill_debug_golden-flow` |
| B1a-US3 Local load | Demo App loads package files from the emulator file system and validates them before install. | `vt_demo-app_local-file-load-extension`, `ct_extension-package__demo-loader_validate-load` |
| B1a-US4 Fake backend seed | Initialization package imports branding through fake backend APIs, persists to local DB, and is idempotent. | `vt_fake-backend_import-init-package`, `vt_fake-backend_import-idempotent`, `vt_local-store_persist-reload`, `vt_initialization-package_community-branding`, `ct_initialization-package__fake-backend_import`, `ct_initialization-package__fake-backend_branding-import` |
| B1a-US5 Open local community | Imported community appears as a branded card and opens in App Shell through the local runtime session. | `vt_demo-app_cards-after-load`, `vt_demo-app_card-image-after-load`, `vt_community-card_branding-priority`, `vt_demo-app_open-local-extension`, `ct_local-backend__community-card_branding-props`, `ct_extension-runtime__app-shell_local-session` |

## 2. Workflow Tests Mapped to Owning Components

| Step | Owning component | Supporting tests |
| --- | --- | --- |
| Prepare validation environment | skill-prereq-setup | `vt_skill-prereq_manifest-complete`, `vt_skill-prereq_host-detection`, `vt_skill-prereq_install-plan`, `vt_skill-prereq_environment-lock`, `vt_skill-prereq_demo-app-smoke`, `wf_local-demo-prereq-to-validation-ready` |
| Consume validation-ready signal | workflow-validation-harness | `ct_skill-prereq-setup__workflow-validation-harness_environment-ready` |
| Generate extension package | ai-skill-extension-builder | `vt_skill_generate-downloadable-extension`, `vt_skill_generate-brand-assets`, `vt_skill_debug_golden-flow` |
| Generate initialization package | ai-skill-extension-builder | `vt_skill_generate-initialization-package` |
| Validate package shape | extension-package-validator | `vt_extension-package_downloadable-shape`, `vt_extension-package_asset-manifest`, `vt_extension-package_asset-policy`, `ct_extension-package__demo-loader_validate-load` |
| Validate init schema | initialization-package-schema | `vt_initialization-package_schema`, `vt_initialization-package_idempotency`, `vt_initialization-package_community-branding` |
| Start empty app | loom-communities-demo-app | `vt_demo-app_empty-community-state`, `vt_demo-app_add-community-button` |
| Load local file | loom-communities-demo-app | `vt_demo-app_local-file-load-extension` |
| Import fake backend data | local-in-app-backend | `vt_fake-backend_import-init-package`, `vt_fake-backend_import-idempotent` |
| Persist and reload | loom-local-store | `vt_local-store_persist-reload` |
| Render card | community-card | `vt_demo-app_cards-after-load`, `vt_demo-app_card-image-after-load`, `vt_community-card_render-bind`, `vt_community-card_branding-priority`, `ct_local-backend__community-card_branding-props` |
| Open latest local package | app-shell-runtime | `vt_demo-app_open-local-extension`, `ct_extension-runtime__app-shell_local-session` |

## 3. UX Research and Decisions

Create `Phase B1a - UX Decisions.md`. Review empty-state app launch, local file picker behavior,
package validation errors, branding asset validation errors, initialization import progress, import
rollback, duplicate import handling, branded community-card fallback states, and the card-to-App-Shell
open path.

## 4. Execution and Issue-Triage Loop

Run `wf_local-build-download-sideload-install`. On failure:

1. Add or strengthen the owning component's `vt_` or `ct_` test first.
2. Route fix to the owning component agent.
3. Update downstream tests and package fixtures.
4. Rerun the workflow and affected component regressions.
5. If the failure is Skill-generated, add the prompt, transcript, package diff, and validator output to
   the Skill debug harness before changing Skill instructions.
6. If the failure is toolchain, emulator, or setup-related, update the prereq manifest, install plan,
   environment lock test, or Demo App smoke test before changing package or runtime code.

## 5. Per-Component Regression Gate

If any involved component changes, run all validation tests and every workflow test in which it
participates per manifest lookup. At minimum, re-run Skill golden tests, brand asset generation tests,
package validators, asset validators, Demo App empty/load/open/card-image tests, fake-backend import
tests, local store persistence tests, Skill prereq setup tests, environment-ready contract test, and
App Shell local session tests.

## 6. Skill Contribution

Add:

- `Skill/workflows/local-build-download-sideload-install.md`
- `Skill/setup/system-prereqs.md`
- `Skill/setup/prereq-manifest.json`
- `Skill/setup/validation-environment.lock.json`
- `Skill/setup/execution-targets/codex.md`
- `Skill/setup/execution-targets/claude-code.md`
- `Skill/setup/troubleshooting.md`
- Local package and initialization package example under `Skill/examples/book-club/phase-b1a-local/`
- Skill debug fixture and golden output notes under the same example directory
- Example logo, card image, hero image, and fallback cases under the same example directory

Update the master walkthrough with local download, sideload, fake-backend import, bundled asset
validation, card branding fallback, and Skill debugging steps. The walkthrough must state that Codex
and Claude Code are the only supported execution targets for now and that online-only support waits for
a hosted Loom build/validation backend.

## 7. Manifest Update

Stamp `wf_local-demo-prereq-to-validation-ready`, `wf_local-build-download-sideload-install`, and all
affected validation/contract tests with latest component and test hashes. Any package fixture, prereq
manifest, or environment-lock schema change updates `testHash`.

## 8. API Review

Create `Phase B1a - API Review.md`. Record local package, initialization package, Demo App loader,
fake backend import/reset/reload, local DB persistence, community branding import, local asset cache,
Skill prereq manifest, validation environment lock schema, and stubbed API gaps.

## 9. Definition of Done

Workflow test passes, component regressions pass, UX Decisions and API Review filed, Skill local-mode
and debug docs updated, validation environment lock current, manifest current, tracker and commit SHA
recorded. The phase is not done if the execution target is unsupported, the prereq setup cannot prove
validation readiness, or the Demo App cannot start empty, load a local package, import initialization
data and branding assets, render a branded community card with fallback behavior, and open the
extension without a hosted backend.

## Commit Gate

Before starting the next phase:

- Stage only this phase's intended changes.
- Run `git diff --staged` and confirm the staged scope matches this phase.
- Commit the phase changes.
- Record the resulting commit SHA in [../Build Tracker.md](../Build%20Tracker.md).
- Do not begin the next phase until the commit exists and the tracker points to it.

## 10. Next Phase

Proceed to [Phase B1b - Publish Discover Certify Install.md](./Phase%20B1b%20-%20Publish%20Discover%20Certify%20Install.md).
