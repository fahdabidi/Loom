# B25 Iteration Scorecard

| Field | Value |
| --- | --- |
| Review run | `b25-v4-pass-19` |
| Status | `fail` |
| Final decision | `fail` |
| B25 can pass | `false` |
| Remaining critical/blocker + major | 3 |
| Resolved critical/blocker + major this pass | 0 |
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
| Criteria passed | 8 / 16 |
| Blocking criterion failures | 8 |
| Holistic direct-question pass | `false` |
| Workflow/persona direct-question pass | `false` |

## Blocking Findings

| Finding | Severity | Status | Required fix |
| --- | --- | --- | --- |
| `LLM-B25-P19-001` | major | open | Audit every affected screen and replace generic framework copy with community-specific product language. Each row must show the concrete object, relevant domain data, primary and alternate lifecycle actions, and result/receiver state in visible screenshots. |
| `LLM-B25-P19-002` | major | open | For each affected workflow, select the correct card-surface family and renderer: search/AI result with citations, roster table/list detail, document detail/download/access surface, reservation calendar/payment surface, ad disclosure/preference surface, and export/import preview wizard. Recapture screenshots proving the right surface is visible. |
| `LLM-B25-P19-003` | major | open | Introduce richer typed layouts for primary surfaces while keeping shared shell code: compact home sections, domain-specific detail pages/forms, tables/lists where appropriate, differentiated status/receipt panels, and more balanced typography/spacing/color. Recapture after screenshots and rerun the LLM review. |

## Required Next Action

Create a remediation batch for unresolved blocker/major findings or failed judge criteria, then rebuild, recapture, regenerate evidence, rerun judge tools, and create the next iteration scorecard.
