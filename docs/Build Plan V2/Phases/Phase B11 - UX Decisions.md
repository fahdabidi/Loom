# Phase B11 - UX Decisions

Purpose: document the UX research, extracted patterns, decisions, implementation impacts, workflow
walkthrough, and open tradeoffs for the full prompt-driven Skill build/validate/complete loop.

## Reference Sources Reviewed

| Source | Surface reviewed | Why it applies | Patterns observed | Applicability / gaps | Review date |
| --- | --- | --- | --- | --- | --- |
| B10 Skill arbitrary extension replay | Saved artifacts, local replay, completion gate | B11 strengthens B10 by generating artifacts from a prompt before replay. | Artifacts must be replayable, and fixture leakage is a validation failure. | B10 did not validate prompt capture or generated review docs. | 2026-06-09 |
| Skill requirements-gathering plan | Workflows, major screens, features, permissions, schemas, rules, jobs, UI guidelines | B11 must prove the Skill creates owner-review artifacts before build. | Review docs should precede package generation and be part of the validation evidence. | Current harness generates deterministic docs, not an interactive owner approval loop. | 2026-06-09 |
| Demo App arbitrary package loader | Add Community/local backend path, card render, local latest open | B11 must prove generated packages load through the same local path users run. | Success is visible as imported card plus local latest route. | Widget-level file picker remains outside the harness. | 2026-06-09 |
| Workflow validation harness convention | Workflow IDs, end states, completion report | B11 needs a machine-readable success/failure artifact. | A workflow is complete only when implemented and validated. | Future runtime should validate generated UI screens directly. | 2026-06-09 |

## UX Patterns Extracted

| Pattern | What B11 applies |
| --- | --- |
| Prompt capture needs reviewable outputs. | The harness writes requirements, workflows, screens, features, and UI guidelines docs. |
| Local validation is evidence, not assertion. | The harness writes `validation-report.json` and `validation-report.md`. |
| Workflow completion must be per-workflow. | Every requested workflow gets an explicit complete flag. |
| The owner should see concrete artifacts. | Package paths and review-doc paths are included in the report. |
| Do not report success on partial work. | `complete=true` requires local install/open plus every workflow result complete. |

## Key UX Decisions

| Decision | Rationale | Affected surface | Covering test |
| --- | --- | --- | --- |
| B11 uses a Camera Club owner prompt fixture. | It is arbitrary, workflow-rich, and outside prior examples. | Skill examples | `wf_skill-prompt-build-validate-complete` |
| The harness generates review docs before packages. | Mirrors the owner-review flow requested for the Skill. | Skill Debug Harness | `wf_skill-prompt-build-validate-complete` |
| Completion report is machine and human readable. | Owners and agents need both auditability and scanability. | Validation report | `wf_skill-prompt-build-validate-complete` |
| Workflow validation is explicit per target workflow. | Prevents vague "done" claims. | Workflow validation report | `wf_skill-prompt-build-validate-complete` |

## Key Implementation Decisions

| Decision | Impact | Owner | Covering test |
| --- | --- | --- | --- |
| Extend `loom_skill_debug_harness` into a deterministic local build harness. | Makes the full Skill loop runnable in CI/local tests. | skill-debug-harness | `wf_skill-prompt-build-validate-complete` |
| Generate zip packages from the prompt plan. | Exercises actual local package loading instead of replaying existing fixtures. | extension-package-validator | `wf_skill-prompt-build-validate-complete` |
| Install through Local In-App Backend and App Shell runtime. | Validates the same local-demo runtime path the Demo App uses. | local-in-app-backend, app-shell-runtime | `wf_skill-prompt-build-validate-complete` |

## Workflow Walkthrough

| Step | User goal / action | Screen or state | Owner | UX decision applied | Covering test |
| --- | --- | --- | --- | --- | --- |
| 1 | Provide owner prompt. | Prompt fixture defines community, personalization, and workflows. | ai-skill-extension-builder | Prompt capture needs reviewable outputs. | `wf_skill-prompt-build-validate-complete` |
| 2 | Capture workflows. | Workflow IDs and end states are derived. | skill-debug-harness | Workflow completion must be per-workflow. | `wf_skill-prompt-build-validate-complete` |
| 3 | Generate review docs. | Requirements, workflows, screens, features, and UI guidelines files exist. | ai-skill-extension-builder | Owner sees concrete artifacts. | `wf_skill-prompt-build-validate-complete` |
| 4 | Generate packages. | `.loom-extension.zip` and `.loom-init.zip` exist. | extension-package-validator | Local validation is evidence. | `wf_skill-prompt-build-validate-complete` |
| 5 | Load and open locally. | Imported card and `local:ext_camera_club@latest` are present. | local-in-app-backend, app-shell-runtime | Use actual local-demo path. | `wf_skill-prompt-build-validate-complete` |
| 6 | Report completion. | JSON/Markdown report says every workflow is complete. | workflow-validation-harness | No partial success. | `wf_skill-prompt-build-validate-complete` |

## Open Questions / Tradeoffs

| Question | Options | Recommendation | Owner | Resolution phase |
| --- | --- | --- | --- | --- |
| Should B11 use a live LLM Skill invocation? | Deterministic harness now, live Codex Skill session now, both. | Keep deterministic harness for repeatable gate; run live Codex session as next manual validation. | Skill owner | Next iteration |
| How deep should workflow validation go before runtime UI exists? | Manifest-level now, fake backend state now, generated UI runtime later. | Validate manifest/package/local open now; add runtime UI checks when generated screens mount. | App Shell/extension runtime | Runtime phase |
| Should incomplete workflow cases be added now? | Add negative tests now, defer until report consumers exist. | Add negative tests when completion report is consumed by phase gates. | skill-debug-harness | Gate hardening |
