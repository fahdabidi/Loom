# Phase B1a - UX Decisions

Status: Complete - R20 second-pass UX decisions applied

Purpose: document the UX research, extracted patterns, decisions, implementation impacts, workflow walkthrough, and open tradeoffs for local-demo extension build, download, sideload, Add Community, local file selection, fake backend initialization import, branded community card, and local latest-open behavior. This file is a phase gate artifact, not a placeholder.

## Reference Sources Reviewed

| Reference | Surface / Flow Reviewed | Why It Applies | Patterns Observed | Applicability / Gaps | Date Reviewed |
| --- | --- | --- | --- | --- | --- |
| [Android Studio Device Explorer](https://developer.android.com/studio/debug/device-file-explorer) | Upload/select files on an emulator or device. | Local-demo users need to place extension/init packages where the Demo App can load them. | Developer tooling makes the local file location explicit and treats upload/open/delete as separate actions. | Loom should show local-demo as a debug/local flow, not hosted publish. | 2026-06-09 |
| [Android Debug Bridge](https://developer.android.com/tools/adb) | Device communication, install/debug shell, and local workflow setup. | Skill prereq setup must verify the validation target and local device tooling. | Tool readiness is a prerequisite before install validation. | B1a uses smoke checks and environment lock instead of requiring a real device every time. | 2026-06-09 |
| [file_picker package](https://pub.dev/packages/file_picker) | Native local file selection with extension filtering. | Add Community needs a package-pair selection surface. | File selection can filter extensions and return path/file metadata. | Initial implementation uses emulator path fields in tests; later UI can swap in native picker. | 2026-06-09 |
| [file_picker FAQ](https://github.com/miguelpruivo/flutter_file_picker/wiki/FAQ) | Validate selected file after broad picker selection. | Local package extensions may be unavailable or unreliable on some platforms. | Let the user select, then validate and show a warning when the file does not match requirements. | Loom validates both package suffixes before import. | 2026-06-09 |
| [Material Design 3 progress indicators](https://m3.material.io/components/progress-indicators/overview) | Import/progress state during package validation and fake backend import. | Users need feedback while a local package is being validated/imported. | Progress indicators communicate ongoing process state. | B1a adds explicit validation/import status copy; richer progress can follow when real file IO exists. | 2026-06-09 |
| [NN/g empty-state design](https://www.nngroup.com/articles/empty-state-interface-design/) | First-community empty state and direct path to first install. | The app starts with no communities. | Empty states should communicate status and provide direct next steps. | A6 fixed the dead empty-state CTA; B1a makes the next step a local package loader. | 2026-06-09 |
| [Material Design 3 cards](https://m3.material.io/components/cards/guidelines) | Installed community card after import. | Successful local install must result in a clear, scannable card. | Cards represent one topic and should be easy to scan for action. | Loom cards remain shell-rendered from imported branding. | 2026-06-09 |

## UX Patterns Extracted

| Pattern | Source References | User Problem Solved | Loom Application | Risk / Constraint |
| --- | --- | --- | --- | --- |
| Environment readiness before local validation | ADB, Device Explorer | Users cannot distinguish package failure from missing tooling. | Skill prereq setup writes an environment lock before local validation starts. | The lock can become stale if tooling changes outside the repo. |
| Explicit package-pair selection | file_picker, Device Explorer | A local extension requires two artifacts, not one. | Add Community opens a local package loader with extension package path and initialization package path. | Native picker integration is deferred; path fields must stay testable. |
| Validate before import | file_picker FAQ | Wrong files can seed the fake backend incorrectly. | Loader validates `.loom-extension.zip` and `.loom-init.zip` before importing. | Suffix validation is not a security boundary; package validators still own deep validation. |
| Status and recovery copy | Material progress indicators | Users need feedback for validation, import, duplicate, and retry states. | Loader shows validation errors and a post-import installed/updated status. | Full determinate progress waits for real file IO. |
| Idempotent duplicate import | Internal local backend tests | Reinstalling the same local package should not duplicate a community card. | Local backend reports `created=false` and the app shows an updated/imported status. | Need future rollback if import has multiple partial steps. |
| Shell-rendered result card | Material cards | Install success needs a concrete visual confirmation. | Imported branding becomes a card in the installed communities list. | Missing assets must use deterministic fallbacks. |

## Key UX Decisions

List the UX decisions that must be reflected in implementation. Each decision must trace to either a reference pattern, a Loom platform invariant, or a workflow requirement.

| Decision | Rationale | Applies To | Acceptance Signal / Test |
| --- | --- | --- | --- |
| Add Community opens a local package loader rather than immediately installing the sample. | The product requirement is manual local-demo sideloading from emulator/local files. | Demo App Add Community, empty-state CTA. | `vt_demo-app_local-loader-opens`, `wf_local-build-download-sideload-install` |
| The loader requires both extension and initialization package paths. | A community install needs code/UI package plus fake-backend seed package. | Demo App local loader, Local In-App Backend. | `vt_demo-app_local-loader-validates-package-pair`, `vt_fake-backend_local-package-pair-validation` |
| Package suffix validation happens before fake backend import. | Prevents obvious wrong-file imports and creates a clear red-bar catch point. | Demo App local loader, Extension Package Validator, Initialization Package Schema. | `vt_demo-app_local-loader-invalid-extension-error`, `ct_extension-package__demo-loader_validate-load` |
| A successful local install closes the loader, renders the branded card, and exposes open-latest behavior. | The user should have an unambiguous install end state. | Demo App, Community Card, App Shell Runtime. | `vt_demo-app_cards-after-load`, `vt_demo-app_open-local-extension`, `wf_local-build-download-sideload-install` |
| Duplicate imports remain idempotent and user-visible as an update state. | Iterating on a Skill-generated package should not create duplicate cards. | Local In-App Backend, Demo App import status. | `vt_fake-backend_import-idempotent`, `vt_demo-app_duplicate-local-import-status` |
| The Skill debug loop stores prompt, generated manifests, validator output, and artifact hashes. | Skill iteration needs reproducible evidence, not only chat transcript notes. | AI Skill / Extension Builder, Skill Debug Harness. | `vt_skill_debug_golden-flow`, `wf_local-demo-prereq-to-validation-ready` |

## Key Implementation Decisions

Record implementation decisions that materially alter the UX, including component ownership, state model, copy source, layout behavior, validation behavior, and test coverage.

| Implementation Decision | UX Impact | Owning Component | Tests / Gates |
| --- | --- | --- | --- |
| Add a testable local package loader dialog with extension/init path fields. | Users can point to local artifacts and understand that both are required. | Loom Communities Demo App. | `vt_demo-app_local-loader-opens`, `vt_demo-app_local-loader-validates-package-pair` |
| Add local package path validation in the local backend. | Validation rules are reusable by UI tests and workflow tests. | Local In-App Backend Adapter. | `vt_fake-backend_local-package-pair-validation` |
| Update existing A6 Add Community tests to complete the loader flow. | A6 still validates that Add Community leads to an installed card, but now through the local loader. | Loom Communities Demo App. | `vt_demo-app_empty-state-cta-loads-community`, `vt_demo-app_cards-after-load` |
| Keep native file picker as a replaceable adapter behind the dialog surface. | Current tests stay deterministic while the UI shape supports later native picker wiring. | Demo App / future picker adapter. | B1a phase gate; future native picker test |
| Preserve deterministic sample summaries behind valid local paths. | The preliminary local backend can validate UX without a hosted package service. | Local In-App Backend, Extension Package Validator. | `wf_local-build-download-sideload-install` |

## Workflow Walkthrough

Workflow under review: `wf_local-build-download-sideload-install`. Walk through the experience step by step after the UX decisions are made. Include the screen or state shown, the user action, the owning component, and the covering test.

| Step | User Goal / Action | Screen or State | Owning Component | UX Decision Applied | Covering Test |
| --- | --- | --- | --- | --- | --- |
| 1 | Validate execution environment. | Skill prereq setup verifies WSL Ubuntu, Flutter, Melos, Android tooling, and writes lock. | Skill Prereq Setup. | Environment readiness before local validation. | `wf_local-demo-prereq-to-validation-ready` |
| 2 | Generate downloadable package pair. | Skill creates `.loom-extension.zip`, `.loom-init.zip`, branding assets, and debug evidence. | AI Skill / Extension Builder. | Skill debug evidence. | `vt_skill_generate-downloadable-extension`, `vt_skill_generate-initialization-package` |
| 3 | Show empty Demo App. | Empty state explains no communities installed and provides Add Community. | Loom Communities Demo App. | Empty state direct path. | `vt_demo-app_empty-community-state`, `vt_demo-app_add-community-button` |
| 4 | Add Community from local files. | Local loader asks for extension package path and initialization package path. | Loom Communities Demo App. | Explicit package-pair selection. | `vt_demo-app_local-loader-opens` |
| 5 | Validate and import initialization package. | Loader validates suffixes, then local backend imports seed data and branding. | Demo App, Local In-App Backend. | Validate before import; status and recovery copy. | `vt_demo-app_local-loader-validates-package-pair`, `vt_fake-backend_import-init-package` |
| 6 | Render branded card. | Community card appears with imported display name and deterministic image fallback. | Community Card, Local In-App Backend. | Shell-rendered result card. | `vt_demo-app_cards-after-load`, `vt_demo-app_card-image-after-load` |
| 7 | Open local latest extension. | User taps card and App Shell opens `local:<extension-id>@latest`. | App Shell Runtime. | Shell-owned open-latest behavior. | `vt_demo-app_open-local-extension`, `wf_local-build-download-sideload-install` |

## Open Questions / Tradeoffs

Capture unresolved UX questions and tradeoffs before implementation starts. A phase can proceed only when blockers are resolved or explicitly accepted.

| Question / Tradeoff | Options Considered | Recommendation | Owner | Resolution Required Before |
| --- | --- | --- | --- | --- |
| Native picker now or deterministic path fields first? | Add `file_picker` immediately, or implement testable path fields and adapter later. | Use path fields now; add native picker adapter when visual emulator tests are ready. | Demo App. | Before mobile UX polish |
| Should invalid files be blocked by suffix only or full package validation? | Fast suffix check, full package schema validation, both. | Do both: UI blocks obvious suffix mismatch; package validators own schema/security checks. | Demo App, Extension Package Validator. | B1a implementation |
| Should local import support rollback now? | Rollback now, reset-only now, transactional rollback later. | Keep reset/idempotency now; add rollback when import spans multiple stores. | Local In-App Backend. | B8 migration/export closeout |
| Where should generated artifact hashes be shown? | In app loader, Skill debug output, both. | Keep hashes in Skill debug evidence first; app can show import status only. | Skill Debug Harness. | B1a closeout |

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
