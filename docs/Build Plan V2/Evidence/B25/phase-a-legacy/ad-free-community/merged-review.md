# B25 Independent Production UX Review

Review run: `phaseA-legacy-ad-free-community-1`

Status: `llm-vision-review-fail`

Final decision: `fail`

Screen rows collected: 18

Holistic direct-question answers: 1

Workflow/persona scorecards: 0 (0 blocking)

Workflow lifecycle scorecards: 0 (0 blocking)

## Current Findings

| Finding | Severity | Status | Required fix |
| --- | --- | --- | --- |
| `complete-state-not-evidenced-on-checkouts` | critical-blocker | open | Render a distinct post-purchase state for both checkouts showing the confirmed charge (120.00 USD / 4.99 USD), the receipt reference, entitlement activation and renewal date, and update the hero subtitle so it no longer says 'before checkout'. |
| `completion-banners-clipped-by-bottom-nav` | major | open | Scroll or inset the complete states so the confirmation banner and its detail line render fully above the bottom navigation, and include the outcome specifics (ID, amount, timestamp) in the banner body. |
| `requirement-prose-instead-of-product-copy` | major | open | Replace the 'X, Y and Z are shown' rows with the actual values (payment instrument, renewal date, fee breakdown) and rewrite the status chip caption as user-facing copy about the entitlement, not about screen composition. |
| `duplicated-card-shells-and-truncated-subtitles` | major | open | Give each card its own summary line drawn from its own data (latest receipt, suppressed slot count, settlement period), stop truncating card titles, and remove or heavily condense the duplicated 'Ad-free account controls' block on the modals. |
| `start-frames-open-mid-scroll` | major | open | Anchor each start state at the top of its workflow so the hero title and full description are visible, and ensure the workflow's own primary action is the prominent control on its start screen. |
| `empty-lower-half-on-suppression-and-settlement-start` | major | open | Populate the lower area with the real suppression slot list and settlement summary (period, gross, allocated amount, status) instead of leaving dead space under a collapsed row. |
| `prohibition-glyph-on-primary-ctas` | minor | open | Give enabled primary actions filled accent styling and drop the slashed-circle glyph from actionable buttons; reserve it for genuinely suppressed or disabled states, which should carry a reason. |
| `inconsistent-modal-palettes-and-low-contrast-heroes` | minor | open | Standardise modal chrome on the community accent and raise hero title/subtitle contrast against the navy background to match the legibility of the card body text. |
| `instrumentation-strip-visible-in-product` | minor | open | Remove the 'In-focus product surface' strip from rendered product screens, or hide it outside capture/debug builds. |
| `unexplained-read-only-state` | minor | open | State the reason the settlement card is read-only in this context and point to where the editable view lives, rather than showing an unqualified 'Read only' pill with truncated explanatory text. |

## Community Product Experience Docs

| Product doc | Community | Status | Path | Missing sections | Required fix |
| --- | --- | --- | --- | --- | --- |
| Missing | all reviewed communities | fail | n/a | all | Run the evidence collector with Product Docs V2 community experience specs present. |

## Holistic Direct Questions

| Question | Verdict | Score | Why | Required fix |
| --- | --- | ---: | --- | --- |
| Across this community's workflows, is it always clear what workflow and what state (start/in-progress/complete) the user is looking at? | `fail` | 34 |  |  |

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
