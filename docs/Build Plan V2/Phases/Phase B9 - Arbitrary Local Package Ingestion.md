# Phase B9 - Arbitrary Local Package Ingestion

Workflow bundle: Skill or developer produces any valid local-demo extension package and initialization
package -> Demo App loader reads the selected files -> Local In-App Backend parses package metadata and
branding -> fake backend imports the community -> App Shell renders and opens the arbitrary extension.
Components involved: Loom Communities Demo App, Local In-App Backend, Extension Package Validator,
Initialization Package Schema, Community Card, App Shell Runtime, Skill workflow docs.
UX gate: high
Gate: `wf_arbitrary-local-package-ingestion` plus affected A6/B1a/B8 regressions pass.

## WSL Ubuntu Tooling Requirement

Run all phase tooling from WSL Ubuntu, not Windows PowerShell. Use this command shape from the Windows host:

```powershell
wsl.exe -d Ubuntu -- bash -lc 'cd "/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app" && <command>'
```

Inside WSL Ubuntu, `dart`, `flutter`, and `melos` must resolve from the Ubuntu toolchain. Do not run
Dart, Flutter, Melos, package validation, manifest gates, phase gates, or workflow tests from
Windows-native shells.

## 0. Prerequisite Gate

- B8 complete and committed.
- B1a local-demo package/load/install workflow remains green.
- Demo App local loader is available and starts from an empty app state.
- Extension and initialization package schemas exist and are referenced by the Skill.
- Manifest has B9 validation and workflow tests registered before implementation closes.

## 1. Workflows and End States

| Workflow | End state |
| --- | --- |
| `wf_arbitrary-local-package-ingestion` | A non-Book-Club package pair selected by file path installs the community whose IDs, name, seed files, and branding are declared inside those files. |

User stories:

| Story | End state | Required tests |
| --- | --- | --- |
| B9-US1 Parse arbitrary pair | Local backend parses extension/init package contents from selected files, not from fixture defaults. | `vt_fake-backend_parse-arbitrary-local-package-pair` |
| B9-US2 Import arbitrary pair | Local backend loads the extension, imports initialization seed references, and preserves card/logo/hero/accent branding. | `vt_fake-backend_import-arbitrary-package-pair` |
| B9-US3 Render arbitrary card | Demo App installs a community card using parsed package values and no hardcoded Book Club fields. | `vt_demo-app_arbitrary-local-extension-loads-card` |
| B9-US4 Open arbitrary latest | App Shell opens `local:<parsed-extension-id>@latest` for the imported arbitrary community. | `wf_arbitrary-local-package-ingestion` |

## 2. Workflow Tests Mapped to Owning Components

| Step | Owning component | Supporting tests |
| --- | --- | --- |
| Select package files | loom-communities-demo-app | `vt_demo-app_local-loader-opens`, `vt_demo-app_arbitrary-local-extension-loads-card` |
| Validate file suffix and readability | local-in-app-backend | `vt_fake-backend_local-package-pair-validation` |
| Parse extension manifest | local-in-app-backend, extension-package-validator | `vt_fake-backend_parse-arbitrary-local-package-pair` |
| Parse initialization manifest | local-in-app-backend, initialization-package-schema | `vt_fake-backend_parse-arbitrary-local-package-pair` |
| Import fake backend data | local-in-app-backend | `vt_fake-backend_import-arbitrary-package-pair` |
| Render card from parsed branding | community-card | `vt_demo-app_arbitrary-local-extension-loads-card` |
| Open latest local extension | app-shell-runtime | `wf_arbitrary-local-package-ingestion` |

## 3. UX Research and Decisions

Complete `Phase B9 - UX Decisions.md` before implementation work that affects UI, interaction,
user-visible state, or workflow copy. The UX Decisions file is a gate artifact and must follow R20:
reference sources reviewed, UX patterns extracted, key UX decisions, key implementation decisions,
workflow walkthrough, and open questions / tradeoffs.

## 4. Execution and Issue-Triage Loop

Run `wf_arbitrary-local-package-ingestion`. On failure:

1. Add or strengthen the owning component's `vt_` or `ct_` test first.
2. If parsed metadata is wrong, fix Local In-App Backend parsing and update package-schema tests.
3. If the UI still shows fixture values, fix Demo App loader state and update widget tests.
4. Rerun B9 plus A6/B1a/B8 regressions that touch Demo App, Local Backend, Community Card, or App Shell.

## 5. Per-Component Regression Gate

If Demo App or Local Backend changes, run:

- `dart test packages/core/loom_demo_local_backend/test/a6_local_backend_test.dart`
- `flutter test apps/loom_communities_demo/test/a6_loom_communities_demo_test.dart`
- `flutter test apps/loom_communities_demo/test/b1a_local_workflow_test.dart apps/loom_communities_demo/test/b8_export_migration_workflow_test.dart apps/loom_communities_demo/test/b9_arbitrary_local_package_ingestion_test.dart`
- `dart analyze packages/core/loom_demo_local_backend`
- `flutter analyze apps/loom_communities_demo`

## 6. Skill Contribution

Add `Skill/workflows/arbitrary-local-package-ingestion.md` and update the master walkthrough to state
that the local loader must consume arbitrary generated package contents. The Skill must not rely on
Book Club fixture IDs when validating a new extension.

## 7. Manifest Update

Stamp B9 validation and workflow tests with current component/test hashes. Any change to package JSON
fixtures, local backend parsing, Demo App loader behavior, or Skill workflow instructions updates the
test hash or component version.

## 8. API Review

Create `Phase B9 - API Review.md`. Record local file readability, package JSON parsing, required
extension/init fields, extensionId match validation, branding import, seed reference handling, and
archive-format gaps.

## 9. Definition of Done

B9 is complete only when an arbitrary package pair installs without Book Club fixture substitution,
the imported community card reflects parsed metadata, the local latest extension opens, affected
regressions pass, UX/API/Skill docs are updated, manifest stamps are current, and the commit SHA is
recorded in the tracker.

## Commit Gate

Before starting the next phase:

- Stage only this phase's intended changes.
- Run `git diff --staged` and confirm the staged scope matches this phase.
- Commit the phase changes.
- Record the resulting commit SHA in [../Build Tracker.md](../Build%20Tracker.md).
- Do not begin the next phase until the commit exists and the tracker points to it.

## 10. Next Phase

Proceed to [Phase B10 - Skill Arbitrary Extension Test Run.md](./Phase%20B10%20-%20Skill%20Arbitrary%20Extension%20Test%20Run.md).
