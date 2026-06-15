# Phase B12 - API Review

## Scope

B12 changes the Skill's reference methodology. It does not alter Loom runtime APIs, local backend
contracts, extension package schemas, or initialization package schemas.

## APIs Reviewed

| API or contract | Owner | B12 decision |
| --- | --- | --- |
| Skill reference index | ai-skill-extension-builder | The Skill must load methodology references before execution when a user asks it to create an extension. |
| Loom source bootstrap contract | skill-prereq-setup | A portable Skill run must discover or fetch the Loom repo before full executable validation. |
| Workflow API mapping artifact | ai-skill-extension-builder | Every generated extension workflow must map steps to Loom APIs, rules, events, functions/jobs, UI surfaces, and tests. |
| UX Decisions artifact | ai-skill-extension-builder | Every generated extension phase with UX changes must use the R20 UX research and decisions structure. |
| Extension phase tracker artifact | ai-skill-extension-builder | Generated extension work must be split into right-sized phases with commit and validation gates. |

## Decisions

| Decision | Rationale | Covering test |
| --- | --- | --- |
| Keep Loom API contracts as references, not mutation targets. | The Skill builds extensions; it should consume Loom APIs and patterns rather than edit the platform. | `wf_skill-reference-methodology-planning` |
| Require research and owner-review artifacts before package generation. | Prevents the Skill from jumping directly to code without aligning workflows, UX, permissions, and data policy. | `wf_skill-reference-methodology-planning` |
| Require workflow-to-API/rules/events maps. | Makes generated implementation choices auditable and testable. | `wf_skill-reference-methodology-planning` |
| Keep full Demo App validation repo-fetched. | The Demo App, local backend, App Shell, and tests are too large and fast-changing to duplicate inside the Skill. | `wf_skill-reference-methodology-planning` |

## Open API Gaps

- Publish the Skill as an installable plugin with bootstrap scripts after B13 proves multi-prompt
  validation.
- Add a machine-readable reference index that lists every bundled reference, source repo path, and
  source commit.
