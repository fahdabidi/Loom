# B25 Independent Production UX Review

Review run: `phaseA-legacy-masjid-nur-1`

Status: `llm-vision-review-fail`

Final decision: `fail`

Screen rows collected: 27

Holistic direct-question answers: 5

Workflow/persona scorecards: 0 (0 blocking)

Workflow lifecycle scorecards: 0 (0 blocking)

## Current Findings

| Finding | Severity | Status | Required fix |
| --- | --- | --- | --- |
| `spec-prose-rendered-as-product-copy` | critical-blocker | open | Replace every field-list/criteria sentence with the actual community value it describes — the amount, the private note, the assignee, the status, the query, the message body. Where no value exists for a slot, render a real empty state rather than a description of the slot. |
| `payment-surface-without-amount` | critical-blocker | open | Render the real transaction on all three states: amount and currency, fund/recipient, payment method, donor visibility choice, receipt destination on start/action; and on complete, a paid badge with amount, paid-at timestamp, receipt number and a view-receipt link. |
| `cross-workflow-content-bleed` | critical-blocker | open | Bind each workflow row to its own surface and re-capture: RSVP start must show the event and Going/Maybe/Not going; discussion-thread must show the thread, posts and composer across all three states; neutral-notification must show a message, sender and delivery status. Replace the shared "Masjid preference confirmed" completion string with a per-workflow confirmation. |
| `ad-preference-card-in-mosque-community` | major | open | Remove the ad-preference/sponsored-message card from these surfaces entirely, and give any remaining minimized cards titles short enough to render without truncation. |
| `clipping-and-chip-overlap` | major | open | Add bottom padding equal to the nav bar height on all scroll views, restore vertical spacing between the chip wrap and the following list rows, scroll start states to the top of their content so titles are visible, and widen or wrap card titles so they do not ellipsize. |
| `rsvp-off-palette-and-missing-response-selector` | major | open | Re-theme the RSVP surfaces to the community green accent, render three selectable Going / Maybe / Not going controls on the action state, show the chosen response on the complete state, and decrement the remaining-spots count after a Going response. |
| `duplicated-sentences-and-repeated-card-shells` | major | open | Show each fact once, in the highest-level card that owns it, and give secondary cards distinct content (history, related records, next steps) rather than restating the headline sentence. |
| `complete-states-lack-status-markers` | major | open | Give every complete state an explicit status badge with a timestamp and the resulting value (published at, saved as anonymous, paid, going, request #, delivered to N members), and swap pre-action CTAs for post-action ones. |
| `ambiguous-disabled-secondary-actions` | minor | open | Render each secondary once at an accessible contrast ratio, use the platform disabled style with an adjacent reason when a control genuinely is disabled, and give start-state primary CTAs the same filled treatment they have on the action screens. |

## Community Product Experience Docs

| Product doc | Community | Status | Path | Missing sections | Required fix |
| --- | --- | --- | --- | --- | --- |
| Missing | all reviewed communities | fail | n/a | all | Run the evidence collector with Product Docs V2 community experience specs present. |

## Holistic Direct Questions

| Question | Verdict | Score | Why | Required fix |
| --- | --- | ---: | --- | --- |
| Across this community's workflows, is it always clear what workflow and what state (start/in-progress/complete) the user is looking at? | `fail` | 34 |  |  |
| Does the displayed text sound like real product copy describing actual Masjid Nur content, or like generic/placeholder scaffolding? | `fail` | 28 |  |  |
| Is the visual execution production-grade — no repeated generic shells, no clipping or crowding, consistent theming? | `fail` | 31 |  |  |
| Are the available actions clear, and is it clear why disabled or ghosted ones are in that state? | `fail` | 52 |  |  |
| Does what is shown make sense for the workflow being demonstrated? | `fail` | 22 |  |  |

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
