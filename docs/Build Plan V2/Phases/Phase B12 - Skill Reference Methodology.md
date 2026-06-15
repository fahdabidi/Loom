# Phase B12 - Skill Reference Methodology

Workflow bundle: portable Skill bootstrap -> Loom reference implementation study -> research and
workflow-product docs -> API/rules/events mapping -> UX methodology -> extension phase planning ->
approval gate before execution.
Components involved: AI Skill / Extension Builder, Skill Guide Index, Skill Prereq Setup, Skill
Debug Harness, Workflow Validation Harness.
UX gate: high
Gate: `wf_skill-reference-methodology-planning` plus B11 regression pass.

## WSL Ubuntu Tooling Requirement

Run all phase tooling from WSL Ubuntu, not Windows PowerShell. Use this command shape from the Windows host:

```powershell
wsl.exe -d Ubuntu -- bash -lc 'cd "/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app" && <command>'
```

Inside WSL Ubuntu, `dart`, `flutter`, and `melos` must resolve from the Ubuntu toolchain.

## 0. Prerequisite Gate

- B11 complete and committed.
- Skill can produce a prompt-build validation report.
- Current Skill references can be loaded without assuming the user is already inside the Loom source
  tree.

## 1. Workflows and End States

| Workflow | End state |
| --- | --- |
| `wf_skill-reference-methodology-planning` | The Skill documents how to study Loom reference workflows, explain why Loom implemented them that way, create product/workflow docs, map workflows to APIs/rules/events/functions, create UX decisions, create an extension build tracker, and stop for approval before execution. |

## 2. Skill Reference Artifacts

Add the following Skill references:

| Reference | Purpose |
| --- | --- |
| `references/loom-reference-implementation-methodology.md` | Explains how to learn from existing Loom workflows, APIs, rules, events, UX decisions, and code. |
| `references/extension-creation-process.md` | Defines the full planning-to-execution process for arbitrary extension creation. |
| `references/workflow-api-mapping-template.md` | Template for mapping workflow steps to Loom APIs, backend functions, rules, events, and tests. |
| `references/ux-methodology-template.md` | Loom UX research and decisions template the Skill must apply to generated extension UX. |
| `references/source-dependency-model.md` | Defines which dependencies are bundled into the Skill and which are fetched from the Loom repo. |

## 3. API Review

Create `Phase B12 - API Review.md`. Record that B12 changes Skill methodology and reference loading,
not Loom API contracts.

## 4. UX Decisions

Create `Phase B12 - UX Decisions.md` using the R20 methodology. Focus on the builder/owner review UX:
research docs first, workflow docs second, API mapping third, phase plan fourth, approval before code.

## 5. Manifest Update

Register `wf_skill-reference-methodology-planning` and `vt_skill-reference-methodology-index`.
Stamp them against the current Skill reference hashes.

## 6. Definition of Done

B12 is complete when the Skill clearly separates learning Loom reference implementations from
modifying Loom APIs, the new references exist and are linked from `SKILL.md` and the master
walkthrough, B11 regression passes, manifest/phase gates pass, tracker is updated, and the phase is
committed.

## Commit Gate

Before starting B13:

- Stage only this phase's intended changes.
- Run `git diff --staged` and confirm the staged scope matches B12.
- Commit the phase changes.
- Record the resulting commit SHA in [../Build Tracker.md](../Build%20Tracker.md).

## 7. Next Phase

Proceed to [Phase B13 - Skill Multi Prompt Validation.md](./Phase%20B13%20-%20Skill%20Multi%20Prompt%20Validation.md).
