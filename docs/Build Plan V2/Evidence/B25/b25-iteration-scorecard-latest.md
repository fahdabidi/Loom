# B25 Iteration Scorecard

| Field | Value |
| --- | --- |
| Review run | `b25-v4-pass-1` |
| Status | `fail` |
| Final decision | `fail` |
| B25 can pass | `false` |
| Remaining critical/blocker + major | 3 |
| Resolved critical/blocker + major this pass | 0 |
| New critical/blocker + major this pass | 3 |

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
| `B25-V4-REVIEW-PENDING` | major | open | Run Production UX Judge Agent against screenshots and fill holisticQuestionAnswers, workflowPersonaScorecards, screen-specific critiques, findings, and remediation links. |
| `B25-HOLISTIC-UNPROVEN` | major | open | Complete screenshot-grounded holistic direct-question answers and remediate any failed whole-product UI issues before rerunning the judge. |
| `B25-WORKFLOW-PERSONA-UNPROVEN` | major | open | Add per-workflow/persona scorecards with visible evidence, domain-native surface judgment, task-specific critique, pass/fail result, and finding/remediation links. |

## Required Next Action

Create a remediation batch for unresolved blocker/major findings or failed judge criteria, then rebuild, recapture, regenerate evidence, rerun judge tools, and create the next iteration scorecard.
