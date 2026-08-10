# B25 Independent Production UX Review

Review run: `phaseA-legacy-riverside-youth-soccer-1`

Status: `llm-vision-review-fail`

Final decision: `fail`

Screen rows collected: 27

Holistic direct-question answers: 5

Workflow/persona scorecards: 0 (0 blocking)

Workflow lifecycle scorecards: 0 (0 blocking)

## Current Findings

| Finding | Severity | Status | Required fix |
| --- | --- | --- | --- |
| `wrong-workflow-substituted` | critical-blocker | open | Route each workflow to its own surface and recapture. The waiver action/complete must show the waiver document, the covered player (Leo Rivera), the signing guardian (Mia Rivera), the Saturday deadline and a signed confirmation. The discussion action/complete must show a real U10 Falcons thread with authored posts, timestamps and a posted-message confirmation. |
| `reminder-sheet-shows-rsvp-body` | critical-blocker | open | Give the reminder workflow its own surface: a composer showing the draft message body, the guardian recipient count and inbox channel with a 'Send reminder' action, and a completion state showing the sent message, timestamp and recipient count — visibly different from the start state. |
| `duplicated-content-blocks-in-sheets` | major | open | De-duplicate the sheet composition so each context row renders once per screen; the second card should carry only content the first does not, or be removed. |
| `start-states-are-mid-scroll-feed-frames` | major | open | Capture each start state at the top of that workflow's own surface, with its title, its not-yet-started status and its primary action all in frame, and no unrelated workflow card occupying the majority of the viewport. |
| `generic-shared-completion-banner` | major | open | Give each workflow a completion banner that names its own outcome and the resulting artifact (RSVP response and attendance count; reminder sent time and recipient count; fields redacted; waiver signed by and when; export file, size and checksum), and pad it clear of the bottom nav. |
| `spec-language-in-user-facing-copy` | major | open | Rewrite all '… are visible' scaffolding lines as product copy that states the content itself, and replace the shared 'Member form captures labeled details, privacy c…' subtitle with per-feature descriptions. |
| `described-actions-not-present` | major | open | Render the actual controls each sheet describes (RSVP buttons, Approve/Reject, Pay), and drop the 'Minimized' chip and the duplicate 'Tap for expanded view' / 'Expand' pairing in favour of one clear expand affordance. |
| `off-palette-blue-on-roster` | minor | open | Apply the community's green accent to the roster app bar and the 'Roster opened' banner, or document the colour-by-category scheme and apply it consistently across all eight workflows. |
| `truncated-titles-and-nav-clipping` | minor | open | Allow card titles to wrap to two lines, add bottom padding equal to the nav bar height so no content is occluded, and fix the horizontal overflow that clips the 'Team' tab and the flush-left hero on the export complete screen. |

## Community Product Experience Docs

| Product doc | Community | Status | Path | Missing sections | Required fix |
| --- | --- | --- | --- | --- | --- |
| Missing | all reviewed communities | fail | n/a | all | Run the evidence collector with Product Docs V2 community experience specs present. |

## Holistic Direct Questions

| Question | Verdict | Score | Why | Required fix |
| --- | --- | ---: | --- | --- |
| Across this community's workflows, is it always clear what workflow and what state (start/in-progress/complete) the user is looking at? | `fail` | 34 |  |  |
| Does the displayed text read like real product copy about Riverside Youth Soccer, or like generic/spec placeholder text? | `fail` | 45 |  |  |
| Do the screens avoid repeated generic card shells, duplicated content and clipping? | `fail` | 30 |  |  |
| Are the available actions clear, and is it clear why disabled or hidden ones are unavailable? | `fail` | 52 |  |  |
| Does what is shown make sense for the workflow being demonstrated in each capture? | `fail` | 40 |  |  |

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
