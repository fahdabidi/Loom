# Phase B12 - UX Decisions

Purpose: document the UX research, extracted patterns, decisions, implementation impacts, workflow
walkthrough, and open tradeoffs for the Skill's reference methodology and owner-review process.

## Reference Sources Reviewed

| Source | Surface reviewed | Why it applies | Patterns observed | Applicability / gaps | Review date |
| --- | --- | --- | --- | --- | --- |
| Codex Agent Skills manual | Skill structure, progressive disclosure, references, scripts, plugin packaging | B12 restructures the Loom Skill for portable use. | Keep `SKILL.md` concise; move large references to reference files; use scripts for repeatable fragile operations. | Packaging as a plugin remains a later step. | 2026-06-10 |
| Codex `skill-creator` guidance | Skill creation, validation, examples, references/assets/scripts | B12 defines what belongs in the Skill versus the repo. | Concrete examples, reusable references, deterministic scripts, and validation prompts improve skill reliability. | Current phase adds references; B13 adds stronger multi-prompt validation. | 2026-06-10 |
| Loom R20 UX methodology | Reference sources, patterns, decisions, implementation decisions, walkthrough, open tradeoffs | The Skill must teach extension builders to create UX docs with the same rigor Loom uses. | Research before UI; decisions tied to workflow steps and tests. | Generated extension runtime UI validation is still manifest/local-open level. | 2026-06-10 |
| Existing Loom workflow phase docs | B1a-B11 workflow execution and gates | The Skill needs phase templates and validation discipline for generated extension builds. | Right-sized phases, tests before completion, commit gates, tracker updates. | Generated extension phases are extension-scoped, not platform-scoped. | 2026-06-10 |

## UX Patterns Extracted

| Pattern | What B12 applies |
| --- | --- |
| Owner-visible research before implementation. | The Skill must produce community research and high-level workflow/persona/policy docs before execution. |
| Workflow docs organized by functionality area. | Generated product docs should group by owner/member/admin workflows rather than by platform component. |
| Explain why, not just how. | Reference implementation docs must include Loom's architecture/UX rationale and decision history. |
| Approval gate before code. | The Skill stops after research, workflow docs, API maps, UX docs, tracker, and phase docs for user review. |
| Validation is part of UX quality. | Every generated workflow doc must name its validation criteria and local Demo App evidence. |

## Key UX Decisions

| Decision | Rationale | Affected surface | Covering test |
| --- | --- | --- | --- |
| Replace "learn from phase guides" with "learn from reference implementations." | The Skill consumes Loom patterns to build extensions; it does not continue platform implementation. | Skill walkthrough | `wf_skill-reference-methodology-planning` |
| Require detailed product workflow docs before API mapping. | Builders need human workflow intent before implementation mapping. | Generated extension docs | `wf_skill-reference-methodology-planning` |
| Require matching API/rules/events mapping docs. | Makes implementation choices reviewable and testable. | Generated extension docs | `wf_skill-reference-methodology-planning` |
| Require extension-scoped phase docs and tracker. | Keeps execution bounded and auditable. | Build tracker/phase docs | `wf_skill-reference-methodology-planning` |

## Key Implementation Decisions

| Decision | Impact | Owner | Covering test |
| --- | --- | --- | --- |
| Add Skill references instead of expanding `SKILL.md`. | Preserves progressive disclosure and keeps triggering metadata concise. | ai-skill-extension-builder | `wf_skill-reference-methodology-planning` |
| Add a source-dependency model reference. | Makes portable Codex environments fetch the repo for executable validation rather than assuming local paths. | skill-prereq-setup | `wf_skill-reference-methodology-planning` |
| Add templates for workflow/API mapping and UX decisions. | Gives generated extension docs repeatable structure. | ai-skill-extension-builder | `wf_skill-reference-methodology-planning` |

## Workflow Walkthrough

| Step | User goal / action | Screen or state | Owner | UX decision applied | Covering test |
| --- | --- | --- | --- | --- | --- |
| 1 | Ask Skill to build a new extension. | Skill loads concise process and relevant references. | ai-skill-extension-builder | Progressive disclosure. | `wf_skill-reference-methodology-planning` |
| 2 | Research the community. | `community-research.md` captures personas, workflows, policies, and UX patterns. | ai-skill-extension-builder | Research before implementation. | `wf_skill-reference-methodology-planning` |
| 3 | Draft product workflow docs. | Workflows are grouped by functionality area. | ai-skill-extension-builder | Human intent before APIs. | `wf_skill-reference-methodology-planning` |
| 4 | Map implementation. | Workflow API/rules/events docs tie each step to Loom contracts. | ai-skill-extension-builder | Decisions are auditable. | `wf_skill-reference-methodology-planning` |
| 5 | Plan execution. | Extension tracker and phase docs define tests and commit gates. | skill-debug-harness | Right-sized phases. | `wf_skill-reference-methodology-planning` |
| 6 | Ask for approval. | No packages are generated until owner approves the plan. | ai-skill-extension-builder | Approval gate before code. | `wf_skill-reference-methodology-planning` |

## Open Questions / Tradeoffs

| Question | Options | Recommendation | Owner | Resolution phase |
| --- | --- | --- | --- | --- |
| How much Loom reference material should be bundled? | Bundle all docs, bundle compact indexes, fetch all from repo. | Bundle compact indexes/templates; fetch full docs/source from repo. | Skill owner | Plugin packaging |
| Should the Skill require live web research? | Always research, optional research, user-supplied research only. | Require research when network is available; otherwise ask user for comparable examples. | Skill owner | B13/manual runs |
| How deep should generated phase docs be? | One phase per workflow, bundled workflow clusters, single build phase. | Bundle related workflows into right-sized phases with explicit validation gates. | Skill owner | B13 |
