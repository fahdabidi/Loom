# Phase B11 - API Review

## Scope

B11 validates the full local Skill loop rather than a saved package replay. It introduces a deterministic
Skill Debug Harness API that starts from an owner prompt, captures target workflows, generates artifacts,
loads them locally, validates workflow implementation, and writes a completion report.

## APIs Reviewed

| API or contract | Owner | B11 decision |
| --- | --- | --- |
| `LoomSkillLocalBuildHarness.buildAndValidate` | skill-debug-harness | Single local validation entry point for prompt -> generated artifacts -> local install/open -> workflow validation report. |
| `SkillPromptPlan.fromPrompt` | ai-skill-extension-builder | Deterministic prompt capture for B11; extracts community identity, category, tagline, accent color, and target workflows. |
| `SkillGeneratedArtifacts` | ai-skill-extension-builder | Records generated package paths and review-doc paths for requirements, workflows, screens, features, and UI guidelines. |
| `SkillWorkflowValidationResult` | workflow-validation-harness | Records each requested workflow's expected end state, implementation status, validation status, and completion flag. |
| `SkillBuildValidationReport` | skill-debug-harness | Machine-readable report with `complete`, imported community name, open extension route, workflow results, and artifact paths. |
| `LocalInAppBackend.installLocalPackagePairFromFiles` | local-in-app-backend | Loads generated zip packages through the same local path used by B9/B10. |

## Completion Report Schema

Required fields:

- `schemaVersion`
- `mode`
- `communityId`
- `extensionId`
- `importedCommunityName`
- `openExtensionId`
- `complete`
- `workflowResults[]`
- `generatedArtifacts`

Each `workflowResults[]` entry includes:

- `workflowId`
- `expectedEndState`
- `implemented`
- `validated`
- `complete`

## Validation Decisions

| Decision | Rationale | Covering test |
| --- | --- | --- |
| B11 starts from a prompt fixture, not a golden package. | Proves the Skill captures requirements and generates artifacts before validation. | `wf_skill-prompt-build-validate-complete` |
| Generated review docs are required artifacts. | Prevents the Skill from skipping owner-review materials and jumping directly to code/package output. | `wf_skill-prompt-build-validate-complete` |
| Package load uses the Demo App Local Backend. | Keeps validation aligned with the actual local-demo install path. | `wf_skill-prompt-build-validate-complete` |
| Completion requires every requested workflow. | Prevents partial implementations from reporting success. | `wf_skill-prompt-build-validate-complete` |

## Open API Gaps

- Replace deterministic keyword prompt parsing with an LLM-run transcript capture once the local Skill
  is installed as an executable Codex/Claude Code Skill.
- Add richer generated UI artifact validation after the extension runtime supports rendering generated
  screens, not just manifest-driven local install/open.
- Add negative tests for missing workflow validation and incomplete report status.
