# B25 Independent Production UX Review

Review run: `phaseA-legacy-cedar-commons-hoa-1`

Status: `llm-vision-review-fail`

Final decision: `fail`

Screen rows collected: 21

Holistic direct-question answers: 5

Workflow/persona scorecards: 0 (0 blocking)

Workflow lifecycle scorecards: 0 (0 blocking)

## Current Findings

| Finding | Severity | Status | Required fix |
| --- | --- | --- | --- |
| `unresolved-record-disjunction` | critical-blocker | open | Bind the Record and Change-option rows to the instance in context so each screen names one record ('Clubhouse Room A booking, Sat Aug 15') and offers only the change actions that apply to that record's current state. |
| `rsvp-model-on-room-reservation` | critical-blocker | open | Replace the attendance card with reservation controls: date and time-slot selection, capacity/conflict check against existing bookings, deposit amount, and Confirm reservation / Change slot / Cancel actions. |
| `cross-workflow-card-bleed` | critical-blocker | open | Scope each start screen's foreground card to its own workflow, and open the screen at the top so the workflow title is the first thing rendered rather than a mid-scroll fragment. |
| `approve-without-subject` | critical-blocker | open | Render the case under review above the decision controls — case title, homeowner, lot, requested change, attachments, and applicable rule — and disable the approve action until a case is in context. |
| `spec-prose-instead-of-values` | critical-blocker | open | Replace every '… are visible' / '… remain visible' / '… match the state' sentence with the actual values: amounts, dates, file sizes, checksums, assignee names, and status chips rendered as data. |
| `identical-five-row-block-reused` | major | open | Give each workflow a purpose-built body — booking slots for reservations, line items for dues, a record picker for exports, vote and conditions for committee decisions — and remove the duplicate render of the identity block within a single scroll view. |
| `completion-banners-do-not-state-outcome` | major | open | Write outcome-specific confirmations that lead with the result and its key facts — amount paid and method, room/date booked with confirmation number, file generated with size and destination, decision reached with conditions — rather than a shared 'record saved' sentence. |
| `bottom-nav-clipping` | major | open | Add bottom-inset padding equal to the nav bar height to all scroll containers so no content or control renders beneath it, and make the nav bar's item set fit the viewport width. |
| `unexplained-state-chips` | major | open | Style state indicators distinctly from controls, give each pending state a subject ('Waiting on board review since Aug 4'), state why an item is read-only, collapse the three expand affordances to one, and raise disabled/enabled contrast so the two are distinguishable. |
| `empty-canvas-on-start-screens` | major | open | Fill the lower region with the substantive content these workflows own — record list with sizes for the export, version history and acknowledgement state for the document — and expand the truncated card bodies rather than ellipsising them. |
| `notice-content-duplicated-in-send-sheet` | major | open | Show the notice once, replace the capability sentences with the notice's actual channel and scheduled time as editable values, and surface Send now / Schedule / Save draft controls in the sheet. |
| `debug-chrome-on-notification-start` | minor | open | Remove the in-focus/minimized harness chrome from the product surface and place the 'Owner decision notice' heading above the notice preview card. |
| `low-contrast-secondary-actions` | minor | open | Raise secondary-action contrast to meet accessible minimums against both the navy and blue card backgrounds, and reserve the translucent style exclusively for genuinely disabled controls. |
| `unlabeled-card-shell` | minor | open | Merge the unlabeled card into the titled 'Document access' section so save, download, share, and access-request controls appear once under one heading. |

## Community Product Experience Docs

| Product doc | Community | Status | Path | Missing sections | Required fix |
| --- | --- | --- | --- | --- | --- |
| Missing | all reviewed communities | fail | n/a | all | Run the evidence collector with Product Docs V2 community experience specs present. |

## Holistic Direct Questions

| Question | Verdict | Score | Why | Required fix |
| --- | --- | ---: | --- | --- |
| Across this community's workflows, is it always clear what workflow and what state (start/in-progress/complete) the user is looking at? | `fail` | 48 |  |  |
| Does the displayed text read as real product copy describing actual Cedar Commons HOA content, or as generic template/spec filler? | `fail` | 30 |  |  |
| Do the screens avoid repeated generic card shells and thin/empty content where real content is expected? | `fail` | 27 |  |  |
| Are the available actions clear, and is it clear why disabled or minimized affordances are in that state? | `fail` | 45 |  |  |
| Does the content shown on each screen make sense for the workflow being demonstrated? | `fail` | 33 |  |  |

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
