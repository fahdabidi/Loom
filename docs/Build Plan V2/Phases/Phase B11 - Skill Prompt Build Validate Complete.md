# Phase B11 - Skill Prompt, Build, Validate, Complete

Workflow bundle: owner prompt -> Skill captures requested workflows -> Skill generates review docs,
extension package, initialization package, and validation fixtures -> Demo App Local Backend loads the
generated package pair -> App Shell opens the generated extension -> Skill validates every requested
workflow and emits a completion report.
Components involved: AI Skill / Extension Builder, Skill Debug Harness, Extension Package Validator,
Initialization Package Schema, Workflow Validation Harness, Local In-App Backend, Loom Communities
Demo App, Community Card, App Shell Runtime.
UX gate: high
Gate: `wf_skill-prompt-build-validate-complete` plus B9/B10 regressions pass.

## WSL Ubuntu Tooling Requirement

Run all phase tooling from WSL Ubuntu, not Windows PowerShell. Use this command shape from the Windows host:

```powershell
wsl.exe -d Ubuntu -- bash -lc 'cd "/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app" && <command>'
```

Inside WSL Ubuntu, `dart`, `flutter`, and `melos` must resolve from the Ubuntu toolchain. Do not run
Dart, Flutter, Melos, package validation, manifest gates, phase gates, or workflow tests from
Windows-native shells.

## 0. Prerequisite Gate

- B10 complete and committed.
- Demo App can load arbitrary zip package manifests.
- Skill example prompt fixture exists under `Skill/examples/arbitrary-camera-club/`.
- Skill Debug Harness can access the Demo App Local Backend and App Shell test APIs.

## 1. Workflows and End States

| Workflow | End state |
| --- | --- |
| `wf_skill-prompt-build-validate-complete` | A prompt for an arbitrary Camera Club extension produces docs, zip packages, local install/open behavior, workflow validation, and a `complete=true` report. |

User stories:

| Story | End state | Required tests |
| --- | --- | --- |
| B11-US1 Prompt capture | The Skill reads the owner prompt and extracts community identity, personalization, and target workflows. | `wf_skill-prompt-build-validate-complete` |
| B11-US2 Review docs generated | Requirements, workflows, major screens, major features, and UI guidelines docs are generated before package validation. | `wf_skill-prompt-build-validate-complete` |
| B11-US3 Artifacts generated | Skill emits `.loom-extension.zip` and `.loom-init.zip` files with manifest data matching the prompt. | `wf_skill-prompt-build-validate-complete` |
| B11-US4 Local install/open | Generated packages install through the Demo App Local Backend and open as `local:<extension-id>@latest`. | `wf_skill-prompt-build-validate-complete` |
| B11-US5 Workflow validation report | Every requested workflow is implemented, validated, and reported complete. | `wf_skill-prompt-build-validate-complete` |

## 2. Workflow Tests Mapped to Owning Components

| Step | Owning component | Supporting tests |
| --- | --- | --- |
| Read owner prompt | ai-skill-extension-builder | `wf_skill-prompt-build-validate-complete` |
| Capture target workflows | skill-debug-harness | `wf_skill-prompt-build-validate-complete` |
| Generate review docs | ai-skill-extension-builder | `wf_skill-prompt-build-validate-complete` |
| Generate package pair | extension-package-validator, initialization-package-schema | `wf_skill-prompt-build-validate-complete` |
| Load generated artifacts | local-in-app-backend | `wf_skill-prompt-build-validate-complete` |
| Render/open generated extension | loom-communities-demo-app, community-card, app-shell-runtime | `wf_skill-prompt-build-validate-complete` |
| Validate requested workflows | workflow-validation-harness, skill-debug-harness | `wf_skill-prompt-build-validate-complete` |

## 3. UX Research and Decisions

Complete `Phase B11 - UX Decisions.md` before implementation work that changes Skill iteration,
review docs, validation reporting, or visible Demo App state. The file must follow R20.

## 4. Execution and Issue-Triage Loop

Run `wf_skill-prompt-build-validate-complete`. On failure:

1. If prompt parsing misses a requested workflow, update Skill Debug Harness parsing tests first.
2. If docs are missing, update Skill review-doc generation before changing package generation.
3. If artifacts fail to load, route the fix to Local In-App Backend or package schema tests.
4. If workflow validation is incomplete, add the missing workflow validation assertion before updating
   the generator.
5. Rerun B11 plus B9/B10 regressions.

## 5. Per-Component Regression Gate

Run:

- `flutter test apps/loom_communities_demo/test/b11_skill_prompt_build_validate_test.dart`
- `flutter test apps/loom_communities_demo/test/b9_arbitrary_local_package_ingestion_test.dart apps/loom_communities_demo/test/b10_skill_arbitrary_extension_test.dart`
- `dart analyze packages/tooling/loom_skill_debug_harness`
- `flutter analyze apps/loom_communities_demo`

## 6. Workflow Completeness Judge Gate

Run the B11 judge tool against the prompt-build validation evidence before claiming the Skill completed
the requested extension:

```powershell
wsl.exe -d Ubuntu -- bash -lc 'cd "/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app" && dart run packages/tooling/loom_ux_judges/bin/workflow_completeness_judge.dart --input ../docs/Build\ Plan\ V2/Evidence/B11/workflow-completeness-evidence.json --base .. --output ../docs/Build\ Plan\ V2/Evidence/B11/workflow-completeness-scorecard.json --markdown-output ../docs/Build\ Plan\ V2/Evidence/B11/workflow-completeness-scorecard.md'
```

The judge sees only the owner prompt, requested workflow list, generated docs/packages, Demo App
validation report, and completion report. It must fail if the Skill quietly drops a requested workflow,
does not generate both package artifacts, or reports completion without local Demo App validation.

## 7. Skill Contribution

Add:

- `Skill/workflows/prompt-build-validate-complete.md`
- `Skill/examples/arbitrary-camera-club/README.md`
- `Skill/examples/arbitrary-camera-club/owner-prompt.txt`

Update the master Skill walkthrough to require the B11 completion report before claiming a generated
extension is implemented.

## 8. Manifest Update

Stamp `wf_skill-prompt-build-validate-complete`, `skill-debug-harness`, and affected Demo App test
hashes. Any change to the prompt fixture or generated artifact contract updates the workflow test hash.

## 9. API Review

Create `Phase B11 - API Review.md`. Record the Skill harness API, prompt capture fields, generated
artifact paths, workflow validation result schema, and completion report schema.

## 10. Definition of Done

B11 is complete only when the prompt-driven Skill harness generates review docs and package artifacts,
loads them into the Demo App Local Backend, validates every requested workflow, emits
`complete=true`, passes the workflow-completeness judge, passes regressions, updates
docs/manifest/tracker, and records the commit SHA.

## Commit Gate

Before starting any follow-on phase:

- Stage only this phase's intended changes.
- Run `git diff --staged` and confirm the staged scope matches this phase.
- Commit the phase changes.
- Record the resulting commit SHA in [../Build Tracker.md](../Build%20Tracker.md).

## 11. Next Phase

End of current local Skill validation. Next step is a manual Codex Skill session using a new owner
prompt, then compare its emitted artifacts against the B11 harness report.
