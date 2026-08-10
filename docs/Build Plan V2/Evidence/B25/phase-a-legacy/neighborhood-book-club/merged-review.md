# B25 Independent Production UX Review

Review run: `phaseA-legacy-neighborhood-book-club-1`

Status: `llm-vision-review-fail`

Final decision: `fail`

Screen rows collected: 27

Holistic direct-question answers: 5

Workflow/persona scorecards: 0 (0 blocking)

Workflow lifecycle scorecards: 0 (0 blocking)

## Current Findings

| Finding | Severity | Status | Required fix |
| --- | --- | --- | --- |
| `export-start-shows-discussion-thread` | critical-blocker | open | Capture each start state with that workflow's own card scrolled fully into frame — the export package card with its scope/redaction/destination controls, and the RSVP card with 'Parable discussion night', Thu Feb 15, 7:00 PM, Maya's living room and 10 of 14 spots visible. |
| `ad-copy-in-book-club-reading-material` | major | open | Replace the ad-preference copy and 'Open ad details' action with reading-guide content — the guide's book and chapter range, author links, discussion prompts — and an 'Open reading guide' primary action. |
| `library-and-reading-workflows-are-scaffolding` | major | open | Author real content for both workflows to the standard the vote and RSVP screens already meet: name the item and its custody ('Maya has the club copy until Feb 22, 2 members queued') and the guide and its scope, and replace 'Start shared library item' with 'Borrow', 'Join queue', or 'Return'. |
| `complete-states-triplicate-confirmation` | major | open | State the outcome once and let subsequent cards add new information (timestamp, resulting record, next step). Render each secondary action once, at a contrast ratio readable against the card background. |
| `publish-complete-offers-save-draft` | major | open | Remove draft controls and pre-publish instructional copy from the published state; show delivery timestamp and reach, with post-send actions such as 'View in inbox' or 'Resend'. |
| `top-clipping-and-nav-overflow` | major | open | Anchor each capture so the focused card's title is fully visible below the app bar, add bottom padding so trailing confirmation strips clear the nav, and fix the bottom nav so all four tabs fit within the screen width. |
| `unexplained-not-available-and-repeated-shells` | major | open | Give each background card its own real summary content, replace 'Not available' with a reason naming the responsible role and any available next step, and remove the 'In-focus product surface' debug strip from production surfaces. |
| `cards-describe-controls-instead-of-rendering-them` | major | open | Render the described controls as real controls — distinct Going/Maybe/Not going options, citation rows that open sources, export scope and redaction toggles — and delete spec-voice bullets that narrate what 'the user sees'. |
| `counts-unchanged-after-completion` | major | open | Recompute chips and counters for the completed state — increment the vote tally and seat count, clear or decrement unread, and mark completed export steps — so the data corroborates the confirmation copy. |
| `internal-instructional-copy-in-ui` | minor | open | Remove the pre-save instructional band from completed states, and replace status-report chips with the values they refer to (the entered title, the confirmed author, the saved timestamp). |

## Community Product Experience Docs

| Product doc | Community | Status | Path | Missing sections | Required fix |
| --- | --- | --- | --- | --- | --- |
| Missing | all reviewed communities | fail | n/a | all | Run the evidence collector with Product Docs V2 community experience specs present. |

## Holistic Direct Questions

| Question | Verdict | Score | Why | Required fix |
| --- | --- | ---: | --- | --- |
| Across this community's workflows, is it always clear what workflow and what state (start/in-progress/complete) the user is looking at? | `fail` | 52 |  |  |
| Does displayed text read like real Neighborhood Book Club product copy, or like placeholder scaffolding? | `fail` | 45 |  |  |
| Is the visual execution production-grade — no repeated shells, thin content, clipping or crowding? | `fail` | 38 |  |  |
| Are available actions clear, and is it clear why disabled or hidden ones are unavailable? | `fail` | 55 |  |  |
| Does what each screen shows make sense for the workflow being demonstrated? | `fail` | 62 |  |  |

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
