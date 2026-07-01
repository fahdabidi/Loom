# B25 Iteration Scorecard

| Field | Value |
| --- | --- |
| Review run | `b25-v4-pass-32` |
| Status | `fail` |
| Final decision | `fail` |
| B25 can pass | `false` |
| Remaining critical/blocker + major | 9 |
| Resolved critical/blocker + major this pass | 0 |
| New critical/blocker + major this pass | 9 |

## Finding Counts

| Severity | Total | Unresolved | Resolved |
| --- | ---: | ---: | ---: |
| Critical/blocker | 0 | 0 | 0 |
| Major | 9 | 9 | 0 |
| Minor | 0 | n/a | n/a |
| Polish | 0 | n/a | n/a |

## Judge Summary

| Field | Value |
| --- | --- |
| Judge status | `fail` |
| Criteria passed | 7 / 16 |
| Blocking criterion failures | 9 |
| Holistic direct-question pass | `false` |
| Workflow/persona direct-question pass | `false` |

## Blocking Findings

| Finding | Severity | Status | Required fix |
| --- | --- | --- | --- |
| `LLM-B25-WR-001` | major | open | Capture and/or implement the documented persona tab model, Home/Messages tabs, custom tabs, pinned surfaces, and minimized/medium/expanded navigation states for each community. |
| `LLM-B25-WR-002` | major | open | Remediate the UI so each documented card surface is rendered as a visibly distinct product surface with the documented interactions/actions. |
| `LLM-B25-WR-003` | major | open | Update product docs if needed, then implement and recapture lifecycle states so the screenshots visibly prove the semantic interaction model. |
| `LLM-B25-VISION-001` | major | open | Create distinct product frames for the highest-volume surfaces: event/calendar, documents, approval/status, marketplace/loan, messages, export/data, payments, and community home. Each frame needs its own layout, hierarchy, content model, and action/result region. |
| `LLM-B25-VISION-002` | major | open | Capture or implement action/result states as normal full-bright product screens with persistent status, history, receipt, or receiver state; avoid relying on dimmed transitional overlays as B25 proof. |
| `LLM-B25-VISION-003` | major | open | Replace utility/status cards with task-specific product surfaces: export wizard with data previews and files, ad-free billing/account settings, social inbox/thread UI, chess board/match UI, and document viewer/link handling. |
| `LLM-B25-VISION-004` | major | open | Add screenshot coverage for community home tab, Messages/Communication tab, custom persona tabs, pinned surfaces, and minimized/medium/expanded card states; update UI where the tab model is not visible or not useful. |
| `LLM-B25-VISION-005` | major | open | For each primary workflow, add visible lifecycle controls and state: edit/change/cancel/reject/defer where required, durable result/history/receipt state, and receiver or continuation screens. Recapture after screenshots proving those states. |
| `B25-WORKFLOW-LIFECYCLE-INCOMPLETE` | major | open | Use the failed lifecycle scorecards to add concrete objects, decision information, semantic primary and alternate actions, persistent result state, and receiver/continuation state before recapturing evidence. |

## Required Next Action

Create a remediation batch for unresolved blocker/major findings or failed judge criteria, then rebuild, recapture, regenerate evidence, rerun judge tools, and create the next iteration scorecard.
