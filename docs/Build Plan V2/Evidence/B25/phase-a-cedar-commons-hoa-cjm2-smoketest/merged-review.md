# B25 Independent Production UX Review

Review run: `phaseA-cedar-commons-hoa-cjm2-smoketest-1`

Status: `llm-vision-review-fail`

Final decision: `fail`

Screen rows collected: 5

Holistic direct-question answers: 2

Workflow/persona scorecards: 0 (0 blocking)

Workflow lifecycle scorecards: 0 (0 blocking)

## Current Findings

| Finding | Severity | Status | Required fix |
| --- | --- | --- | --- |
| `giving-tab-blank-no-state` | critical-blocker | open | Either declare role: "any" on the dues-payment render binding (with a corresponding read-visibility scope) or wire a custom rolesForInstance for the Giving tab that checks payerPersonaId rather than createdByPersonaId. Additionally render a real empty state when a persona genuinely has no dues due. |
| `calendar-raw-parse-error-uncontained` | critical-blocker | open | Either rename the field to eventDate (or add a computed formula field aliasing it), or make the calendar surface honor a configurable date-field name. Separately, replace the raw error text with a contained error card and remove Retry for non-transient failures. |
| `open-fact-pill-illegible-degraded-state` | major | open | Either land openMode:"external" for this specific field now (avoiding the unsupported state entirely) as a JSON-only change, or improve the unsupported-state visual treatment (stronger dimming, no raw 'choice:' prefix, human label) when CJM.2's embedded/choice follow-on lands. |
| `raw-schema-keys-in-fact-pills` | major | open | Route fact-pill labels and enum values through the same humanization used for form field labels; wrap/ellipsize long URL values. |
| `readonly-persona-shown-editable-fields-and-dead-save` | major | open | Render read-only for personas without edit rights (no input underlines, no Save). Confirm via a focused-field capture whether inputs actually accept input. |
| `ghosted-local-package-details-row` | major | open | Gate this row behind a developer/authoring mode so it never renders for member personas. |
| `identity-lost-on-scroll` | minor | open | Add a persistent identity affordance to the app bar that survives scrolling and tab changes; label the '2 roles' control explicitly. |
| `internal-vocabulary-in-user-copy` | minor | open | Replace platform taxonomy with resident language; hide the sponsored-message slot entirely when empty. |
| `giving-tab-clipped-in-bottom-nav` | minor | open | Size the tab bar so all tabs fit, or make it horizontally scrollable with a visible edge fade. |

## Community Product Experience Docs

| Product doc | Community | Status | Path | Missing sections | Required fix |
| --- | --- | --- | --- | --- | --- |
| Missing | all reviewed communities | fail | n/a | all | Run the evidence collector with Product Docs V2 community experience specs present. |

## Holistic Direct Questions

| Question | Verdict | Score | Why | Required fix |
| --- | --- | ---: | --- | --- |
| Across this flow, can the signed-in user always tell who they are (by name), not just which role they are using? | `fail` | 72 |  |  |
| For the Calendar and Giving tabs specifically, does the screen communicate that this is a genuine empty/error state (as opposed to looking incomplete or broken with no explanation)? | `fail` | 18 |  |  |

## Workflow/Persona Scorecards

| Scorecard | Status | Screens | Summary |
| --- | --- | ---: | --- |
| Missing | fail | 0 | Run the independent UX judge. |

## Workflow Lifecycle Scorecards

| Lifecycle scorecard | Status | Missing lifecycle groups | Summary |
| --- | --- | --- | --- |
| Missing | fail | all | Run the workflow lifecycle judge. |

## Review Note

This file is generated from B25 evidence plus the independent UX judge output. The deterministic production UX judge validates this output and emits remediation tickets; the worker agent does not grade its own UI.
