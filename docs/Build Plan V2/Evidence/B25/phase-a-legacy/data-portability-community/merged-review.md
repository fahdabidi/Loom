# B25 Independent Production UX Review

Review run: `phaseA-legacy-data-portability-community-1`

Status: `llm-vision-review-fail`

Final decision: `fail`

Screen rows collected: 27

Holistic direct-question answers: 4

Workflow/persona scorecards: 0 (0 blocking)

Workflow lifecycle scorecards: 0 (0 blocking)

## Current Findings

| Finding | Severity | Status | Required fix |
| --- | --- | --- | --- |
| `redacted-bundle-shows-full-bundle` | critical-blocker | open | Navigate to and capture the actual redacted-bundle surface. Each frame must self-identify as the redacted bundle and show what distinguishes it from the full bundle: which fields were stripped, the redaction count, and the resulting reduced artifact size and checksum. |
| `import-replay-shows-import-preview` | critical-blocker | open | Capture the distinct replay surface for the action and complete states: replay progress against checkpoint I-118 while running, and afterwards the rows applied vs skipped, the resolved duplicate decisions, and a completion timestamp. The preview workflow's complete banner should also say the preview was completed rather than announcing replay readiness. |
| `action-state-shows-static-explainer` | critical-blocker | open | Capture the actual in-progress surface for each workflow after the primary action is invoked -- packaging progress, hash comparison in flight, redaction being applied, rollback restoring, scope being toggled -- each with a visible progress or status indicator and at least one control (cancel/abort). Retain the community app bar or an equivalent context label inside the modal, and remove the duplicated step-1 row from the 'Export workspace' block. |
| `cross-community-copy-leak` | major | open | Replace the borrowed fixture copy with this community's own domain terms: a data-portability destination provider name, protected field examples drawn from this community's schema (member contact, payment, audit fields), and a visibility-policy description that does not reference guardians, coaches, or personas. |
| `results-described-not-rendered` | major | open | Render the actual result values on each completion screen -- artifact name, byte size, checksum, redaction count, matched hash pair, saved table scope, per-duplicate decisions -- following the pattern the checksum and rollback screens already establish, and offer the appropriate follow-on action (download, view receipt). |
| `completion-banners-clipped-by-tab-bar` | major | open | Add bottom padding equal to the tab bar height to the scroll container so terminal banners and the 'Package progress' card render fully, and scroll captures so the state-carrying element is entirely within the viewport. |
| `truncated-card-titles-and-repeated-shells` | major | open | Let card titles wrap to two lines or shrink the 'Minimized' chip so full titles render, and give each card a summary describing its own content rather than a shared boilerplate string. |
| `empty-lower-region-and-orphaned-chip` | major | open | Fill the lower region with the transfer/rollback status panel (or expand 'Local package details' by default), and anchor the 'Waiting' chip inside the card whose state it describes with an accompanying label explaining what is being waited on. |
| `harness-chrome-and-inconsistent-nav` | minor | open | Remove the 'In-focus product surface' harness strip from captured screens, make the tab set consistent across all workflows in this community, and size the tab bar so no label is clipped at the right edge. |
| `ambiguous-repeated-generate-export` | minor | open | Scope-label each export action (e.g. 'Generate full bundle', 'Generate this package') or collapse them to a single primary action, and either disable the post-completion 'Rollback' button with a reason or relabel the status chip to a completed state consistent with the body copy. |

## Community Product Experience Docs

| Product doc | Community | Status | Path | Missing sections | Required fix |
| --- | --- | --- | --- | --- | --- |
| Missing | all reviewed communities | fail | n/a | all | Run the evidence collector with Product Docs V2 community experience specs present. |

## Holistic Direct Questions

| Question | Verdict | Score | Why | Required fix |
| --- | --- | ---: | --- | --- |
| Across this community's workflows, is it always clear what workflow and what state (start/in-progress/complete) the user is looking at? | `fail` | 34 |  |  |
| Does the displayed text read as real product copy about this community's actual export content, or as generic/placeholder or borrowed-from-elsewhere copy? | `fail` | 48 |  |  |
| Are the available actions clear on each screen, and is it clear why disabled or waiting affordances are in that state? | `fail` | 45 |  |  |
| Is the visual execution production-grade -- no repeated generic card shells, no clipping or crowding, no thin/empty regions where content is expected? | `fail` | 38 |  |  |

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
