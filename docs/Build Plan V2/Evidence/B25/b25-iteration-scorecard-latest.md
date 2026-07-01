# B25 Iteration Scorecard

| Field | Value |
| --- | --- |
| Review run | `b25-v4-pass-25` |
| Status | `fail` |
| Final decision | `fail` |
| B25 can pass | `false` |
| Remaining critical/blocker + major | 6 |
| Resolved critical/blocker + major this pass | 0 |
| New critical/blocker + major this pass | 6 |

## Finding Counts

| Severity | Total | Unresolved | Resolved |
| --- | ---: | ---: | ---: |
| Critical/blocker | 1 | 1 | 0 |
| Major | 5 | 5 | 0 |
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
| `LLM-UX-primary-experience-still-uses-one-repeated-workflow-card-renderer-across-unrelated-communities` | critical-blocker | open | Replace the generic workflow-card renderer as the primary UX. Build domain-native surfaces per community/job: event detail and RSVP, donation/payment checkout and receipt, inbox/thread, facility calendar, approval queue, export wizard with real step navigation, roster table/detail, marketplace listing, and critique/media detail. |
| `LLM-UX-user-facing-copy-still-exposes-review-evidence-platform-and-harness-language` | major | open | Rewrite screens in domain user language and remove evidence/test/framework copy. Move persona switching, local package details, no-fill diagnostics, workflow IDs, and generic review scaffolding out of production surfaces or behind explicit developer-only evidence tooling. |
| `LLM-UX-distinct-workflow-rows-reuse-identical-screenshot-pixels-and-do-not-prove-distinct-production-states` | major | open | Recapture or redesign distinct workflow states so each workflow/persona row proves its own object, action, result, and continuation state. |
| `LLM-UX-workflow-lifecycles-are-not-visually-complete-enough-for-production-handoff-receipt-and-recovery-states` | major | open | For each failing lifecycle, add the missing production state: concrete object/context, decision information, primary semantic action, alternate/change/reject path, durable result/receipt, and receiver or continuation surface. |
| `LLM-UX-visual-polish-is-below-the-production-bar-because-of-title-truncation-dense-card-stacks-and-one-note-per-community-palettes` | major | open | Polish the shell and information hierarchy: avoid clipped primary titles, reduce chip density, use tabs/sections/lists/forms where appropriate, add community-specific identity/content treatment, and vary surface composition by task while preserving accessibility. |

## Required Next Action

Create a remediation batch for unresolved blocker/major findings or failed judge criteria, then rebuild, recapture, regenerate evidence, rerun judge tools, and create the next iteration scorecard.
