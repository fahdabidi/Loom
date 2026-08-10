# B25 Independent Production UX Review

Review run: `phaseA-legacy-member-social-space-1`

Status: `llm-vision-review-fail`

Final decision: `fail`

Screen rows collected: 24

Holistic direct-question answers: 5

Workflow/persona scorecards: 0 (0 blocking)

Workflow lifecycle scorecards: 0 (0 blocking)

## Current Findings

| Finding | Severity | Status | Required fix |
| --- | --- | --- | --- |
| `message-stream-evidence-duplicated` | critical-blocker | open | Capture distinct message-stream screenshots showing an actual multi-message stream (several senders, timestamps, read markers) for start, action and complete, and fix the start capture so it opens on stream content rather than the connection-invite surface. |
| `complete-state-confirmation-clipped` | major | open | Add bottom padding equal to the nav bar height (or auto-scroll the confirmation into view) so the completion card is fully readable above the navigation bar in every complete state. |
| `acceptance-criteria-as-ui-copy` | major | open | Replace every field-enumeration sentence with the actual data or with short member-facing copy, e.g. render the entitlement status and a receipt link instead of stating that they 'are visible'. |
| `described-but-missing-controls` | major | open | Render each named control as a real element in its correct state — a visibly disabled Send with inline reason plus a working Appeal/Unblock on the block guard, and Dismiss/Report/Manage ad on the sponsored surfaces. |
| `reused-generic-thread-actions-block` | major | open | Give each workflow an action block scoped to its own verbs (accept/decline for invites, appeal/report for blocks) and remove the duplicated sender/body restatement from the lower card. |
| `repeated-minimized-card-shells` | major | open | Give each card a distinct, complete subtitle describing its own content, widen or wrap the title so it is not truncated mid-word, and replace the stacked shells with real content rows (conversations, connections, pending requests). |
| `low-contrast-workflow-hero-titles` | minor | open | Lighten the accent tints used for hero titles and subtitles on dark panels so they meet normal on-dark contrast, keeping the accent hue for identity. |
| `wrong-nav-tab-highlighted` | major | open | Keep the navigation selection in sync with the displayed surface so the messaging/safety guard does not render with the Calendar tab active. |
| `contradictory-state-pairs` | major | open | Update the conversation card to reflect the post-action state (read/sent, or sent-and-pending) so the confirmation and the card above it agree. |
| `start-screens-open-mid-scroll` | major | open | Ensure start states render scrolled to the top of the workflow surface with its title and primary content in view. |
| `empty-region-on-invite-start` | minor | open | Fill the invite start state with the composer (recipient picker, message field, mutual-community context) so no large dead region remains above the nav bar. |
| `messages-nav-pill-clipped` | minor | open | Constrain the navigation row to the viewport width (or make it explicitly scrollable) so no pill is clipped by the screen edge. |

## Community Product Experience Docs

| Product doc | Community | Status | Path | Missing sections | Required fix |
| --- | --- | --- | --- | --- | --- |
| Missing | all reviewed communities | fail | n/a | all | Run the evidence collector with Product Docs V2 community experience specs present. |

## Holistic Direct Questions

| Question | Verdict | Score | Why | Required fix |
| --- | --- | ---: | --- | --- |
| Across this community's workflows, is it always clear what workflow and what state (start/in-progress/complete) the user is looking at? | `fail` | 42 |  |  |
| Does the displayed text read as real product copy about actual community content, or as generic/spec-derived placeholder prose? | `fail` | 35 |  |  |
| Are the available actions clear, and is it clear why disabled or hidden ones are unavailable? | `fail` | 38 |  |  |
| Is the visual execution production-grade — no repeated generic shells, no clipping, no thin content, no contrast problems? | `fail` | 33 |  |  |
| Does the content shown on each screen make sense for the workflow it is labelled with? | `fail` | 30 |  |  |

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
