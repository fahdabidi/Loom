# B25 Iteration Scorecard

| Field | Value |
| --- | --- |
| Review run | `b25-v4-pass-16` |
| Status | `fail` |
| Final decision | `fail` |
| B25 can pass | `false` |
| Remaining critical/blocker + major | 3 |
| Resolved critical/blocker + major this pass | 3 |
| New critical/blocker + major this pass | 3 |

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
| `LLM-B25-P16-001` | critical-blocker | open | Remove the generic action-template copy and replace each affected screen with a domain-native product surface tailored to the community workflow. |
| `LLM-B25-P16-002` | major | open | Bring the non-Garden primary workflows up to the same standard as the improved Garden RSVP and plant offer screens: concrete object details, task-specific inputs/actions, alternate paths, result state, and receiver/member context. |
| `LLM-B25-P16-003` | major | open | Use workflow-specific layouts and components: event pages, form pages, composer pages, receipt/history pages, inbox/detail pages, export review pages, and signup sheets should not all share the same decision-card scaffold. |

## Required Next Action

Create a remediation batch for unresolved blocker/major findings or failed judge criteria, then rebuild, recapture, regenerate evidence, rerun judge tools, and create the next iteration scorecard.
