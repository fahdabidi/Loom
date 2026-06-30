# B25 Iteration Scorecard

| Field | Value |
| --- | --- |
| Review run | `b25-v4-pass-13` |
| Status | `fail` |
| Final decision | `fail` |
| B25 can pass | `false` |
| Remaining critical/blocker + major | 3 |
| Resolved critical/blocker + major this pass | 0 |
| New critical/blocker + major this pass | 0 |

## Finding Counts

| Severity | Total | Unresolved | Resolved |
| --- | ---: | ---: | ---: |
| Critical/blocker | 1 | 1 | 0 |
| Major | 2 | 2 | 0 |
| Minor | 1 | n/a | n/a |
| Polish | 0 | n/a | n/a |

## Judge Summary

| Field | Value |
| --- | --- |
| Judge status | `fail` |
| Criteria passed | 9 / 15 |
| Blocking criterion failures | 6 |
| Holistic direct-question pass | `false` |
| Workflow/persona direct-question pass | `true` |

## Blocking Findings

| Finding | Severity | Status | Required fix |
| --- | --- | --- | --- |
| `LLM-UX-001` | critical-blocker | open | Remove internal validation/checklist wording and replace with natural member-facing domain copy and controls. |
| `LLM-UX-002` | major | open | Build a real plant exchange experience centered on plant offers/requests, member logistics, and clear offer/edit/submit actions. |
| `LLM-UX-003` | major | open | Vary layouts by task type, reduce checklist chips, and create product-specific hierarchy for lists, details, actions, and confirmations. |

## Required Next Action

Create a remediation batch for unresolved blocker/major findings or failed judge criteria, then rebuild, recapture, regenerate evidence, rerun judge tools, and create the next iteration scorecard.
