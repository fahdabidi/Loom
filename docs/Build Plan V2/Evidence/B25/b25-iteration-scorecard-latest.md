# B25 Iteration Scorecard

| Field | Value |
| --- | --- |
| Review run | `b25-v4-pass-24` |
| Status | `fail` |
| Final decision | `fail` |
| B25 can pass | `false` |
| Remaining critical/blocker + major | 7 |
| Resolved critical/blocker + major this pass | 0 |
| New critical/blocker + major this pass | 4 |

## Finding Counts

| Severity | Total | Unresolved | Resolved |
| --- | ---: | ---: | ---: |
| Critical/blocker | 1 | 1 | 0 |
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
| `B25-WORKFLOW-PERSONA-UX-FAILED` | major | open | Use the failed scorecards to remediate exact workflow/persona screens and recapture evidence. |
| `B25-WORKFLOW-LIFECYCLE-INCOMPLETE` | major | open | Use the failed lifecycle scorecards to add concrete objects, decision information, semantic primary and alternate actions, persistent result state, and receiver/continuation state before recapturing evidence. |
| `B25-HOLISTIC-UX-FAILED` | major | open | Resolve coverage, screen critique, IA, and visual quality issues before rerunning holistic review. |
| `LLM-UX-primary-ux-is-still-a-repeated-workflow-card-scaffold-across-the-evidence-set` | critical-blocker | open | Replace the universal card scaffold with domain-native screens by workflow family: event detail/RSVP, marketplace offer form/detail, payment checkout and receipt, care request form and status, admin review queue, inbox/thread, document library, export wizard, transfer status, and role-aware home surfaces. |
| `LLM-UX-visible-copy-exposes-workflow-contract-language-instead-of-product-native-task-language` | major | open | Remove Decide..., Ready to..., Receiver state, Member state, and similar contract phrasing from user-visible screens. Replace it with concrete task copy, object status, next action, and consequence language. |
| `LLM-UX-several-workflow-persona-lifecycles-still-lack-concrete-object-context-or-persistent-result-state` | major | open | For each failed workflow, add after screenshots that visibly show the named object, final status, actor/receiver context, audit/receipt where relevant, and a durable continuation path. Rerun the workflow lifecycle judge and the LLM vision review. |
| `LLM-UX-persona-picker-and-role-inventory-evidence-exposes-local-test-harness-ui-as-reviewed-product-surface` | major | open | Keep persona switching in test harness evidence only, or replace these rows with production role-aware states that show the signed-in persona, permissions, and unavailable actions without exposing a Choose persona dialog. |

## Required Next Action

Create a remediation batch for unresolved blocker/major findings or failed judge criteria, then rebuild, recapture, regenerate evidence, rerun judge tools, and create the next iteration scorecard.
