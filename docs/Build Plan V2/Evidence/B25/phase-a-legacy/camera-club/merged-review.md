# B25 Independent Production UX Review

Review run: `phaseA-legacy-camera-club-1`

Status: `llm-vision-review-fail`

Final decision: `fail`

Screen rows collected: 12

Holistic direct-question answers: 1

Workflow/persona scorecards: 0 (0 blocking)

Workflow lifecycle scorecards: 0 (0 blocking)

## Current Findings

| Finding | Severity | Status | Required fix |
| --- | --- | --- | --- |
| `primary-actions-never-visible` | critical-blocker | open | Render each workflow's state-appropriate actions as real, visible, tappable controls positioned clear of the bottom nav bar, and delete the prose that merely enumerates action names. |
| `content-clipped-by-nav-bar` | major | open | Add bottom padding equal to the tab bar height to the scroll view (and top padding for the app bar) so no card, banner, or button is ever bisected by system chrome. |
| `detail-rows-duplicated-in-action-sheets` | major | open | Render each detail row exactly once per screen; use the freed space for the action controls the sheet is supposed to provide. |
| `self-describing-meta-copy` | major | open | Replace field-inventory sentences with outcome copy tied to the data ('You're going -- Sat 4:30 PM at Dock 4', 'Sent to Avery, awaiting critique', 'Awaiting Sam's approval, 1st in queue') and show the referenced values rather than naming them. |
| `complete-states-show-no-state-change` | major | open | Have the complete state mutate the visible data: show the selected RSVP as a status chip and an updated attendance count, and make state chips differ between start, in-progress, and complete. |
| `validation-report-is-scaffolding-not-content` | critical-blocker | open | Either give this workflow real subject matter (what is being validated, by whom, which checks pass or fail, with a photography-appropriate icon) or remove it from the member-facing catalogue; fix the 'Edit details' contrast, expand or drop the empty 'Local package details' section, and state the saved fact once. |
| `cross-workflow-boilerplate-reuse` | major | open | Write per-workflow copy for the submitted-request card and show only the actions valid for the current state instead of a shared catalogue of every possible transition. |
| `debug-scaffolding-strip-visible` | minor | open | Remove the 'In-focus product surface' strip from member-facing builds, or replace it with a real content heading. |
| `missing-photo-thumbnail-in-critique` | major | open | Render the submitted photograph as a thumbnail (or an explicit image placeholder with its dimensions/filename) alongside the title on all three critique states. |
| `sheet-accent-colors-diverge-from-community-theme` | minor | open | Derive workflow accents from the community's slate-blue palette (varying tint or using a single semantic success colour) so all four workflows read as one product. |
| `state-inappropriate-actions-listed` | minor | open | Gate action descriptions and state chips on the current lifecycle stage so start states show only the actions actually reachable from a start state. |

## Community Product Experience Docs

| Product doc | Community | Status | Path | Missing sections | Required fix |
| --- | --- | --- | --- | --- | --- |
| Missing | all reviewed communities | fail | n/a | all | Run the evidence collector with Product Docs V2 community experience specs present. |

## Holistic Direct Questions

| Question | Verdict | Score | Why | Required fix |
| --- | --- | ---: | --- | --- |
| Across this community's workflows, is it always clear what workflow and what state (start/in-progress/complete) the user is looking at? | `fail` | 46 |  |  |

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
