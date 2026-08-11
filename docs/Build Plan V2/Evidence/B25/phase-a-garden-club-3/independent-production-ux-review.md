# B25 Independent Production UX Review

Review run: `phaseA-garden-club-3`

Status: `llm-vision-review-fail`

Final decision: `fail`

Screen rows collected: 5

Holistic direct-question answers: 2

Workflow/persona scorecards: 0 (0 blocking)

Workflow lifecycle scorecards: 0 (0 blocking)

## Current Findings

| Finding | Severity | Status | Required fix |
| --- | --- | --- | --- |
| `raw-schema-ids-in-member-ui` | major | open | Give the card a real record title, map schema IDs to human labels ('Garden events', 'Plant exchange') without bracket syntax, and show the selection count once instead of three times. |
| `unexplained-disabled-save` | major | open | Either enable the action or pair the disabled button with an explicit reason such as 'No changes to save' or a named missing field. |
| `exchange-truncation-hides-owners` | major | open | Let item and owner text wrap to full length in a single-column or taller card layout, surface the pickup window and handoff state as labelled fields, and add a per-card claim/request action. |
| `calendar-missing-weekday-header` | major | open | Add a persistent weekday header row, visually mark today, raise day-cell contrast, and format the selected date as human copy such as 'Saturday, August 15'. |
| `raw-enum-state-labels` | minor | open | Map state values to display copy ('On loan', 'Available') with consistent casing and, ideally, distinct color treatment per state. |
| `fab-occludes-content` | major | open | Add bottom content inset equal to the FAB and nav height so scrollable lists can clear them, and keep the FAB's descriptive label consistent across tabs. |
| `identity-absent-off-scroll` | minor | open | Persist a compact identity affordance (avatar or name plus role) in the app bar across all tabs and scroll positions. |
| `empty-sponsorship-banner` | minor | open | Suppress the sponsorship slot entirely when there is no message to show. |
| `install-banner-developer-copy` | minor | open | Rewrite the confirmation in product terms with a version and an import summary, let the card description render in full, and differentiate status chips from action buttons. |

## Community Product Experience Docs

| Product doc | Community | Status | Path | Missing sections | Required fix |
| --- | --- | --- | --- | --- | --- |
| Missing | all reviewed communities | fail | n/a | all | Run the evidence collector with Product Docs V2 community experience specs present. |

## Holistic Direct Questions

| Question | Verdict | Score | Why | Required fix |
| --- | --- | ---: | --- | --- |
| Across this flow, does the UI show specific, sideloaded-package-derived content (not generic/legacy placeholder content) on the Home, Exchange, and Calendar surfaces? | `pass` | 82 |  |  |
| Across this flow, can the signed-in user always tell who they are (by name), not just which role they are using? | `fail` | 66 |  |  |

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
