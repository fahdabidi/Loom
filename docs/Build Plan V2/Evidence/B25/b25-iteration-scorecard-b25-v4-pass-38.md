# B25 Iteration Scorecard

| Field | Value |
| --- | --- |
| Review run | `b25-v4-pass-38` |
| Status | `fail` |
| Final decision | `fail` |
| B25 can pass | `false` |
| Remaining critical/blocker + major | 8 |
| Resolved critical/blocker + major this pass | 0 |
| New critical/blocker + major this pass | 8 |

## Finding Counts

| Severity | Total | Unresolved | Resolved |
| --- | ---: | ---: | ---: |
| Critical/blocker | 0 | 0 | 0 |
| Major | 8 | 8 | 0 |
| Minor | 0 | n/a | n/a |
| Polish | 0 | n/a | n/a |

## Judge Summary

| Field | Value |
| --- | --- |
| Judge status | `fail` |
| Criteria passed | 8 / 17 |
| Blocking criterion failures | 9 |
| Holistic direct-question pass | `false` |
| Workflow/persona direct-question pass | `false` |

## Blocking Findings

| Finding | Severity | Status | Required fix |
| --- | --- | --- | --- |
| `LLM-B25-UX-001` | major | open | Add visible product UI for alternate/change/reject affordance, persistent result state, receiver/continuation state, semantic interaction model; include concrete object/context, primary and alternate/change action where applicable, durable result state, and receiver/continuation state, then recapture fresh screenshots. |
| `LLM-B25-UX-002` | major | open | Add visible product UI for persistent result state; include concrete object/context, primary and alternate/change action where applicable, durable result state, and receiver/continuation state, then recapture fresh screenshots. |
| `LLM-B25-UX-003` | major | open | Add visible product UI for semantic interaction model; include concrete object/context, primary and alternate/change action where applicable, durable result state, and receiver/continuation state, then recapture fresh screenshots. |
| `LLM-B25-UX-004` | major | open | Add visible product UI for alternate/change/reject affordance, semantic interaction model; include concrete object/context, primary and alternate/change action where applicable, durable result state, and receiver/continuation state, then recapture fresh screenshots. |
| `LLM-B25-UX-005` | major | open | Add visible product UI for alternate/change/reject affordance, semantic interaction model; include concrete object/context, primary and alternate/change action where applicable, durable result state, and receiver/continuation state, then recapture fresh screenshots. |
| `LLM-B25-UX-006` | major | open | Add visible product UI for alternate/change/reject affordance, semantic interaction model; include concrete object/context, primary and alternate/change action where applicable, durable result state, and receiver/continuation state, then recapture fresh screenshots. |
| `LLM-B25-UX-007` | major | open | Add visible product UI for alternate/change/reject affordance, semantic interaction model; include concrete object/context, primary and alternate/change action where applicable, durable result state, and receiver/continuation state, then recapture fresh screenshots. |
| `B25-WORKFLOW-LIFECYCLE-INCOMPLETE` | major | open | Use the failed lifecycle scorecards to add concrete objects, decision information, semantic primary and alternate actions, persistent result state, and receiver/continuation state before recapturing evidence. |

## Required Next Action

Create a remediation batch for unresolved blocker/major findings or failed judge criteria, then rebuild, recapture, regenerate evidence, rerun judge tools, and create the next iteration scorecard.
