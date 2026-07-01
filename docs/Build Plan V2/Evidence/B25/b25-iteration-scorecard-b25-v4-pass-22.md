# B25 Iteration Scorecard

| Field | Value |
| --- | --- |
| Review run | `b25-v4-pass-22` |
| Status | `fail` |
| Final decision | `fail` |
| B25 can pass | `false` |
| Remaining critical/blocker + major | 6 |
| Resolved critical/blocker + major this pass | 3 |
| New critical/blocker + major this pass | 5 |

## Finding Counts

| Severity | Total | Unresolved | Resolved |
| --- | ---: | ---: | ---: |
| Critical/blocker | 0 | 0 | 0 |
| Major | 6 | 6 | 0 |
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
| `B25-WORKFLOW-LIFECYCLE-INCOMPLETE` | major | open | Use the failed lifecycle scorecards to add concrete objects, decision information, semantic primary and alternate actions, persistent result state, and receiver/continuation state before recapturing evidence. |
| `B25-VISION-UX-P22-001-B20-CTA-WRAPPING` | major | open | Remediate the visible product UX issue, recapture screenshots, and rerun the LLM vision UX review. |
| `B25-VISION-UX-P22-002-FAILED-WORKFLOW-PERSONA-SCORECARDS` | major | open | Remediate the visible product UX issue, recapture screenshots, and rerun the LLM vision UX review. |
| `B25-VISION-UX-P22-003-FAILED-LIFECYCLE-SCORECARDS` | major | open | Remediate the visible product UX issue, recapture screenshots, and rerun the LLM vision UX review. |
| `B25-VISION-UX-P22-004-ADFREE-REPEATED-CHECKOUT-PANELS` | major | open | Remediate the visible product UX issue, recapture screenshots, and rerun the LLM vision UX review. |
| `B25-VISION-UX-P22-005-VISIBLE-SURFACE-COPY-LEAKAGE` | major | open | Remediate the visible product UX issue, recapture screenshots, and rerun the LLM vision UX review. |

## Required Next Action

Create a remediation batch for unresolved blocker/major findings or failed judge criteria, then rebuild, recapture, regenerate evidence, rerun judge tools, and create the next iteration scorecard.
