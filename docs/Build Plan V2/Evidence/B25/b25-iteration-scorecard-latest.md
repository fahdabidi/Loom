# B25 Iteration Scorecard

| Field | Value |
| --- | --- |
| Review run | `b25-v4-pass-26` |
| Status | `fail` |
| Final decision | `fail` |
| B25 can pass | `false` |
| Remaining critical/blocker + major | 6 |
| Resolved critical/blocker + major this pass | 5 |
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
| `B25-VISION-P26-MAJ-001-repeated-workflow-card-renderer` | major | open | Replace the repeated card renderer with domain-native product surfaces per community: event detail/RSVP, feed/inbox/thread, donation/payment checkout, receipt/history, protected care request form, admin review queue, social connection guard, export/import wizard, and transfer status screens with visibly distinct layouts and content density. |
| `B25-VISION-P26-MAJ-002-product-copy-still-sounds-like-review-spec-or-harness-language` | major | open | Rewrite user-facing copy as domain product language. Remove review/spec/test phrasing and local package or persona-preview copy from production-facing screens. Put implementation metadata behind diagnostics, not in the primary community experience. |
| `B25-VISION-P26-MAJ-003-distinct-workflow-rows-reuse-identical-screenshot-pixels` | major | open | Recapture or redesign the affected workflows so every distinct workflow/persona/state has visibly distinct content, state, and lifecycle proof. If two rows intentionally share a surface, merge the evidence rather than claiming separate production states. |
| `B25-VISION-P26-MAJ-004-workflow-lifecycles-remain-incomplete-or-wrong-for-production` | major | open | For each affected workflow/persona pair, capture entry, decision, primary action, alternate/change/reject path, persistent result, receipt/history/status, and receiver/continuation states in visible UI. The member/receiver state must not reuse actor/composer copy. |
| `B25-VISION-P26-MAJ-005-visual-polish-below-production-bar` | major | open | Improve production visual hierarchy: shorter responsive app-bar titles or branded headers, more varied domain components, less oversized card stacking, clearer section density, and layouts that make primary decisions visible without excessive scroll. |
| `B25-WORKFLOW-LIFECYCLE-INCOMPLETE` | major | open | Use the failed lifecycle scorecards to add concrete objects, decision information, semantic primary and alternate actions, persistent result state, and receiver/continuation state before recapturing evidence. |

## Required Next Action

Create a remediation batch for unresolved blocker/major findings or failed judge criteria, then rebuild, recapture, regenerate evidence, rerun judge tools, and create the next iteration scorecard.
