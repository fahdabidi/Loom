# B25 Remediation Plan

| Field | Value |
| --- | --- |
| Review run | `b25-v4-pass-12` |
| Status | `no-open-tickets` |
| Source tickets | `../docs/Build Plan V2/Evidence/B25/b25-remediation-tickets-b25-v4-pass-12.json` |
| Ticket count | 0 |
| Scorecard status | `pass` |
| Remaining blocker/major | 0 |
| Blocking criteria failures | 0 |
| Product spec work items | 0 |
| Evidence repair work items | 0 |
| UI remediation work items | 0 |
| Work item sequencing | Product-spec work items must close first, then evidence repair work items, then matching UI remediation work items. |

## Source Tickets

| Ticket | Source criterion | Severity | Status | Title |
| --- | --- | --- | --- | --- |
| None | n/a | n/a | n/a | n/a |

## Planner Rules

- Worker agents implement from remediation batches, not from optimistic summaries.
- Product-spec work items must be completed and rerun before evidence repair or UI remediation work items for the same community are assigned.
- Evidence repair work items must be completed and rerun before UI remediation work items for the same community/workflow/persona are assigned.
- UI remediation work must be scoped by community/workflow/persona and target production surface, not by a broad global ticket summary.
- The independent judge must rerun after each batch that changes UI, evidence, or critique.
- No next UX feedback loop starts until the current remediation iteration is committed.
