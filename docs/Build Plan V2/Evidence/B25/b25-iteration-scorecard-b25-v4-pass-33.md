# B25 Iteration Scorecard

| Field | Value |
| --- | --- |
| Review run | `b25-v4-pass-33` |
| Status | `fail` |
| Final decision | `fail` |
| B25 can pass | `false` |
| Remaining critical/blocker + major | 5 |
| Resolved critical/blocker + major this pass | 0 |
| New critical/blocker + major this pass | 5 |

## Finding Counts

| Severity | Total | Unresolved | Resolved |
| --- | ---: | ---: | ---: |
| Critical/blocker | 0 | 0 | 0 |
| Major | 5 | 5 | 0 |
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
| `LLM-B25-VISION-001` | major | open | Replace dimmed action modals with durable full-bright product action surfaces and recapture all action rows. |
| `LLM-B25-VISION-002` | major | open | Replace generic status/checklist utility panels with surface-specific product layouts. |
| `LLM-B25-VISION-003` | major | open | Capture and, if needed, implement persona-specific tabs, pinned surfaces, and card size states as first-class product navigation. |
| `LLM-B25-VISION-004` | major | open | Make lifecycle actions domain-specific and visible in screenshots for every primary workflow. |
| `B25-WORKFLOW-LIFECYCLE-INCOMPLETE` | major | open | Use the failed lifecycle scorecards to add concrete objects, decision information, semantic primary and alternate actions, persistent result state, and receiver/continuation state before recapturing evidence. |

## Required Next Action

Create a remediation batch for unresolved blocker/major findings or failed judge criteria, then rebuild, recapture, regenerate evidence, rerun judge tools, and create the next iteration scorecard.
