# B25 Iteration Scorecard

| Field | Value |
| --- | --- |
| Review run | `b25-v4-pass-34` |
| Status | `fail` |
| Final decision | `fail` |
| B25 can pass | `false` |
| Remaining critical/blocker + major | 4 |
| Resolved critical/blocker + major this pass | 0 |
| New critical/blocker + major this pass | 4 |

## Finding Counts

| Severity | Total | Unresolved | Resolved |
| --- | ---: | ---: | ---: |
| Critical/blocker | 0 | 0 | 0 |
| Major | 4 | 4 | 0 |
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
| `LLM-B25-VISION-034-001` | major | open | Create readable, domain-native action/detail surfaces for the affected workflows. Use opaque surface colors with accessible contrast, screen-specific layout, real domain objects and inputs, explicit primary/secondary/lifecycle actions, and visible result/receiver states; then full recapture B12-B20 evidence. |
| `LLM-B25-VISION-034-002` | major | open | For each blocking workflow/persona pair, implement a surface that makes the target persona real job obvious: object context, user inputs/decision data, primary action, alternative/change/reject/cancel path, result/receipt/history, and receiver/continuation state. |
| `LLM-B25-VISION-034-003` | major | open | Add visible post-action result/receipt/status/history/receiver states to the affected workflows and recapture start/action/result rows proving those states. |
| `B25-WORKFLOW-LIFECYCLE-INCOMPLETE` | major | open | Use the failed lifecycle scorecards to add concrete objects, decision information, semantic primary and alternate actions, persistent result state, and receiver/continuation state before recapturing evidence. |

## Required Next Action

Create a remediation batch for unresolved blocker/major findings or failed judge criteria, then rebuild, recapture, regenerate evidence, rerun judge tools, and create the next iteration scorecard.
