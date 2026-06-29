# B25 Iteration Scorecard

| Field | Value |
| --- | --- |
| Review run | `b25-v4-pass-8` |
| Status | `fail` |
| Final decision | `fail` |
| B25 can pass | `false` |
| Remaining critical/blocker + major | 3 |
| Resolved critical/blocker + major this pass | 1 |
| New critical/blocker + major this pass | 0 |

## Finding Counts

| Severity | Total | Unresolved | Resolved |
| --- | ---: | ---: | ---: |
| Critical/blocker | 0 | 0 | 0 |
| Major | 3 | 3 | 0 |
| Minor | 0 | n/a | n/a |
| Polish | 0 | n/a | n/a |

## Judge Summary

| Field | Value |
| --- | --- |
| Judge status | `fail` |
| Criteria passed | 5 / 12 |
| Blocking criterion failures | 7 |
| Holistic direct-question pass | `false` |
| Workflow/persona direct-question pass | `false` |

## Blocking Findings

| Finding | Severity | Status | Required fix |
| --- | --- | --- | --- |
| `B25-VISUAL-UX-INSPECTION-FAILED` | major | open | Replace the affected screens with screenshot-proven domain-native surfaces and rerun the independent visual UX judge. |
| `B25-WORKFLOW-PERSONA-UX-FAILED` | major | open | Use the failed scorecards to remediate exact workflow/persona screens and recapture evidence. |
| `B25-HOLISTIC-UX-FAILED` | major | open | Resolve coverage, screen critique, IA, and visual quality issues before rerunning holistic review. |

## Required Next Action

Create a remediation batch for unresolved blocker/major findings or failed judge criteria, then rebuild, recapture, regenerate evidence, rerun judge tools, and create the next iteration scorecard.
