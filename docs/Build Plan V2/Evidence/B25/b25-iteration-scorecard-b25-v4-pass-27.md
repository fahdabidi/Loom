# B25 Iteration Scorecard

| Field | Value |
| --- | --- |
| Review run | `b25-v4-pass-27` |
| Status | `fail` |
| Final decision | `fail` |
| B25 can pass | `false` |
| Remaining critical/blocker + major | 7 |
| Resolved critical/blocker + major this pass | 5 |
| New critical/blocker + major this pass | 6 |

## Finding Counts

| Severity | Total | Unresolved | Resolved |
| --- | ---: | ---: | ---: |
| Critical/blocker | 0 | 0 | 0 |
| Major | 7 | 7 | 0 |
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
| `B25-VISION-P27-MAJ-001-repeated-card-renderer-remains-systemic` | major | open | Replace the reusable workflow-card shell with distinct domain-native product surfaces for each workflow family: event detail/RSVP, feed/composer, inbox/thread, payment/receipt, export wizard, document library, request review queue, roster, search results, and ad/entitlement surfaces. |
| `B25-VISION-P27-MAJ-002-copy-still-exposes-review-spec-and-lifecycle-language` | major | open | Rewrite visible copy as natural product language for the current user. Remove phrases like check the details, status, state, path, evidence, inspect, capability matrix, and review-style instructions unless they are truly user-facing domain terms. |
| `B25-VISION-P27-MAJ-003-distinct-workflow-rows-reuse-identical-screenshots` | major | open | Recapture or rebuild these rows so each workflow/persona/state has a distinct screenshot proving the intended UI. Duplicate hashes may only remain when the same product state is explicitly the same evidence row, which is not true for these distinct workflow IDs. |
| `B25-VISION-P27-MAJ-004-lifecycle-states-are-status-panels-not-production-results` | major | open | For every workflow, provide a real action/review state and a durable result or receiver state: receipt/history for payments, inbox/read state for messages, document detail/download state, export transfer status with rollback, RSVP/vote confirmation with change path, and request/approval state with owner/member visibility. |
| `B25-VISION-P27-MAJ-005-visual-identity-and-navigation-polish-below-production-bar` | major | open | Introduce stronger community identity, clearer navigation destinations, less dense repeated chips, better type scale, non-truncated top bars, and surface-specific layouts so the app feels like multiple real community products rather than one recolored scaffold. |
| `B25-VISION-P27-MAJ-006-persona-picker-and-wf-rows-remain-harness-visible` | major | open | Do not include demo persona-picker or wf_* capability-matrix surfaces as production UX evidence unless they are redesigned as user account/role management screens with production copy and non-test semantics. Replace ?Switch roles to inspect? and wf_* framing with real account/member role language or remove from production review scope. |
| `B25-WORKFLOW-LIFECYCLE-INCOMPLETE` | major | open | Use the failed lifecycle scorecards to add concrete objects, decision information, semantic primary and alternate actions, persistent result state, and receiver/continuation state before recapturing evidence. |

## Required Next Action

Create a remediation batch for unresolved blocker/major findings or failed judge criteria, then rebuild, recapture, regenerate evidence, rerun judge tools, and create the next iteration scorecard.
