# B25 Independent Production UX Review

Review run: `phaseA-legacy-chess-club-1`

Status: `llm-vision-review-fail`

Final decision: `fail`

Screen rows collected: 24

Holistic direct-question answers: 5

Workflow/persona scorecards: 0 (0 blocking)

Workflow lifecycle scorecards: 0 (0 blocking)

## Current Findings

| Finding | Severity | Status | Required fix |
| --- | --- | --- | --- |
| `six-workflows-share-match-result-screens` | critical-blocker | open | Each workflow must render and be captured showing its own subject matter: a ranked ladder for rankings-table, dated club-night entries for club-night, an ordered waiting list for pairing-queue, a named export artifact for export-package, a document list/body for rules-documents, and authored posts for discussion-thread — each with a workflow-specific title rather than 'Chess Club home'. |
| `meetup-reuses-result-captures` | critical-blocker | open | Build and capture a real meetup surface: proposed opponent, date/time, board and venue, with propose/accept/reschedule actions and a completion that confirms the scheduled game rather than a saved score. |
| `wrong-completion-banner-every-workflow` | critical-blocker | open | Derive the completion banner from the workflow that completed and name the concrete object — e.g. 'Rankings published', 'Club night scheduled for Thu 14 Aug', 'chess-club-results.csv ready', 'Club rules v3 saved', 'Reply posted' — and drop the 'this community task' placeholder. |
| `record-match-result-cta-on-every-card` | major | open | Give each card the action that belongs to its own content type ('Open rules', 'Reply', 'RSVP', 'Export', 'View queue') and make the button icon match its label everywhere. |
| `spec-restating-and-mismatched-copy` | major | open | Replace criteria-restating and cross-domain copy with sentences describing the actual chess content on each card, and remove internal strings like 'In-focus product surface' and 'Local package details' from user-visible surfaces. |
| `clipping-truncation-and-duplicate-headings` | major | open | Add bottom padding so sheet actions clear the navigation bar, capture start states from the top of the scroll, allow card titles to wrap to two lines instead of ellipsizing, deduplicate the sibling 'Club board' headings, and raise card-versus-sheet contrast in the brown theme. |
| `unexplained-not-available-state` | major | open | Name the managing role concretely (e.g. 'Managed by the club organizer') and either hide or visibly disable the secondary buttons on cards marked 'Not available' so the affordances agree with the state. |
| `nav-tab-never-reflects-workflow` | minor | open | Select the nav tab that corresponds to the surface being shown, and size the tab row so the fourth pill is not clipped at the right edge. |

## Community Product Experience Docs

| Product doc | Community | Status | Path | Missing sections | Required fix |
| --- | --- | --- | --- | --- | --- |
| Missing | all reviewed communities | fail | n/a | all | Run the evidence collector with Product Docs V2 community experience specs present. |

## Holistic Direct Questions

| Question | Verdict | Score | Why | Required fix |
| --- | --- | ---: | --- | --- |
| Across this community's workflows, is it always clear what workflow and what state (start/in-progress/complete) the user is looking at? | `fail` | 18 |  |  |
| Does the displayed text read like real product copy about actual Chess Club content, or like generic/spec-restating placeholder? | `fail` | 30 |  |  |
| Are the available actions clear, and is it clear why disabled or unavailable ones are unavailable? | `fail` | 25 |  |  |
| Is the visual presentation free of repeated generic card shells, clipping, crowding and empty content where real content is expected? | `fail` | 28 |  |  |
| Does what is shown make sense for the specific workflow being demonstrated on each row? | `fail` | 12 |  |  |

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
