# B25 Independent Production UX Review

Review run: `phaseA-legacy-garden-club-1`

Status: `llm-vision-review-fail`

Final decision: `fail`

Screen rows collected: 15

Holistic direct-question answers: 5

Workflow/persona scorecards: 0 (0 blocking)

Workflow lifecycle scorecards: 0 (0 blocking)

## Current Findings

| Finding | Severity | Status | Required fix |
| --- | --- | --- | --- |
| `tool-loan-shift-generic-shell` | major | open | Give both workflows domain content and a domain icon. Tool loan: tool name, availability, current holder, due-back date, queue depth and the user's position, with a 'Borrow' / 'Join queue' action. Volunteer shift: shift date, time window, location, slots filled out of total, task description, with a 'Sign up' action. Replace the 'Details ready / Editable / State saved' chips with these facts, and replace 'This view shows editable details...' with copy about the loan or shift. |
| `tautological-completion-copy` | major | open | Write completion copy that states the resulting fact and the next step, in the style already achieved by the RSVP complete screen ('You are going to Spring Planting Workshop. Calendar, attendee count, and reminder status stay visible.') and the plant exchange complete screen ('Basil seedlings are listed with pickup details and contact sharing limited until a member claims them.'). Collapse the triple 'Saved details' / 'Saved' / 'Saved' chip redundancy into one confirmation. |
| `stale-prestate-chips-and-helper-text` | major | open | Make the chip row and helper text state-dependent: on start show availability/openness, on action show what is being edited, on complete show the saved result. Remove 'State saved' from un-started screens and remove the 'before saving' helper from saved screens. |
| `export-complete-missing-download` | major | open | Add a primary Download (or Share/Save to Documents) action to the completed export, and give the 'Transfer record' section real audit content -- timestamp, destination, per-schema record counts, file size -- rather than duplicating the summary sentence. |
| `captures-clipped-mid-card` | major | open | Anchor start-state captures so the subject card's title and description are fully visible, and ensure preceding cards scroll cleanly under the app bar rather than being sliced mid-glyph. |
| `low-contrast-secondary-actions` | minor | open | Raise secondary/text-button contrast to meet accessibility minimums against the dark card surfaces, and if a control genuinely is disabled, show the reason. De-duplicate the two differently styled 'Change scope' controls on the export sheet. |
| `instrumentation-chrome-and-crowding` | minor | open | Remove or hide the 'In-focus product surface' / 'Minimized' instrumentation banners in product captures, add bottom padding so card stacks clear the nav bar instead of being sliced, and let the bottom nav scroll or shrink so the 'Documents' tab label is not clipped at the screen edge. |
| `rsvp-count-not-incremented` | minor | open | Increment the attendee count on the complete state (e.g. '19 of 24 spots' / '5 spots left') so it agrees with the confirmed RSVP and with the action sheet's stated behaviour. |
| `tool-loan-description-conflict` | minor | open | Use one consistent description of the tool-loan workflow across its minimized card and its full screen, reflecting whichever framing is correct (borrow/queue, or member-form submission). |

## Community Product Experience Docs

| Product doc | Community | Status | Path | Missing sections | Required fix |
| --- | --- | --- | --- | --- | --- |
| Missing | all reviewed communities | fail | n/a | all | Run the evidence collector with Product Docs V2 community experience specs present. |

## Holistic Direct Questions

| Question | Verdict | Score | Why | Required fix |
| --- | --- | ---: | --- | --- |
| Across this community's workflows, is it always clear what workflow and what state (start/in-progress/complete) the user is looking at? | `fail` | 58 |  |  |
| Does the displayed text read like real product copy about actual Garden Club content, or like generic scaffolding? | `fail` | 52 |  |  |
| Is there repeated generic card shell, thin content, clipping, or crowding? | `fail` | 55 |  |  |
| Are the available actions clear, and is it clear why disabled or de-emphasised ones are in that state? | `fail` | 63 |  |  |
| Does what is shown make sense for the workflow being demonstrated in this legacy flat-schema community? | `fail` | 78 |  |  |

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
