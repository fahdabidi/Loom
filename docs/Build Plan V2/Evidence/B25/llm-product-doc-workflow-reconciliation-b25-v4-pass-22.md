# B25 Product Docs To Screenshot Evidence Reconciliation - Pass 22

| Field | Value |
| --- | --- |
| Run ID | `b25-v4-pass-22` |
| Fresh review | `true` |
| Decision | `fail` |
| App commit | `108db17` |
| Product docs reviewed | 12 |
| B25 screen rows reviewed | 195 |
| B25 workflow/persona rows | 68 |
| B25 lifecycle failures | 7 |
| Major reconciliation findings | 6 |

## Summary

Pass 22 is a fresh reconciliation against the current Product Docs V2 community examples,
`independent-production-ux-review.json`, and `b25-workflow-lifecycle-scorecards.md`.

Several pass-21 gaps improved: Camera no longer declares the stale `skill-prompt-build-validate-complete`
workflow; Masjid now documents the B18-B20 persona picker, persona-aware UX, and multi-persona handoff
workflows; Platform Social now includes semantic rows for ad/no-fill workflows; and lifecycle failures
dropped from 22 to 7.

The reconciliation still fails because product docs and B25 evidence ownership do not fully match.
Garden Club, Neighborhood Book Club, and Chess Club still have stale Section 7 persona/state rows
instead of exact canonical workflow IDs. The Shell doc declares a B25 shell workflow without B25
screen/productDocCoverage evidence or a B25 semantic model. The persona-role-inventory doc still
declares support workflows now owned by Masjid, and its own capability-matrix semantic rows have empty
decision/action cells.

The remaining lifecycle failures are separate B25 implementation/evidence context, not the reason for
this product-doc verdict.

## Counts

| Metric | Count |
| --- | ---: |
| Product docs reviewed | 12 |
| Evidence-owned product docs | 11 |
| Section 6 rows reviewed | 74 |
| Unique Section 6 workflow IDs | 66 |
| Unique implemented B25 workflow IDs | 65 |
| B25 screen rows | 195 |
| Workflow/persona rows | 68 |
| Lifecycle scorecards | 68 |
| Lifecycle failures | 7 |
| Product docs passing reconciliation | 6 |
| Product docs passing with lifecycle context | 3 |
| Product docs failing reconciliation | 6 |

## Findings

| Finding | Severity | Status | Product doc | Workflow(s) | Required fix |
| --- | --- | --- | --- | --- | --- |
| `LLM-B25-WR-001` | major | open | `garden-club-product-experience.md` | `garden-event-rsvp`, `plant-exchange-submission`, `garden-export-custom-schemas` | Replace stale Section 7 rows `event RSVP` and `plant exchange` with exact canonical workflow rows, including actor, receiver, read-only, disabled/hidden, unauthorized behavior, and B25 evidence IDs. |
| `LLM-B25-WR-002` | major | open | `neighborhood-book-club-product-experience.md` | all seven `book-*` workflows | Replace stale Section 7 rows `selection publish` and `discussion` with one canonical state row per Section 6 workflow. |
| `LLM-B25-WR-003` | major | open | `chess-club-product-experience.md` | `chess-local-install-open`, `chess-route-home`, `chess-match-result` | Replace Section 7 umbrella row `package open` with exact canonical workflow rows. |
| `LLM-B25-WR-004` | major | open | `loom-communities-shell-product-experience.md` | `local-build-download-sideload-install` | Either add B25 evidence ownership/screenshots/semantic model for this shell workflow or explicitly scope it out of B25 community screenshot reconciliation. |
| `LLM-B25-WR-005` | major | open | `persona-role-inventory-product-experience.md` | `wf_community-persona-aware-ux`, `wf_multi-persona-workflow-evidence`, `wf_demo-app-persona-picker` | Remove these Masjid-owned support workflows from persona-role-inventory or reassign/duplicate B25 coverage and semantic rows under persona-role ownership. |
| `LLM-B25-WR-006` | major | open | `persona-role-inventory-product-experience.md` | `wf_persona-role-inventory-capability-matrix` | Fill the empty B25 semantic interaction model cells for admin and member rows. |

## Per-Doc Results

| Product doc | Result | Notes |
| --- | --- | --- |
| `ad-off-product-experience.md` | pass with context | Sections 6/7/semantic/registry reconcile; five ad-off workflows still fail the separate lifecycle judge. |
| `camera-club-product-experience.md` | pass with context | Product-doc rows align; `gear-loan-request` still fails the separate lifecycle judge for decision information. |
| `cedar-commons-hoa-product-experience.md` | pass | Section 6/7/semantic/registry rows align with B25 evidence. |
| `chess-club-product-experience.md` | fail | Section 7 still uses stale umbrella row `package open`. |
| `export-and-migration-product-experience.md` | pass | Section 6/7/semantic/registry rows align with B25 evidence. |
| `garden-club-product-experience.md` | fail | Section 7 omits exact canonical workflow rows and omits `garden-export-custom-schemas`. |
| `loom-communities-shell-product-experience.md` | fail | Declares `local-build-download-sideload-install` with B25 shell evidence claims but no B25 evidence ownership or semantic model. |
| `masjid-nur-product-experience.md` | pass | Masjid domain and B18-B20 support workflow rows now align with B25 evidence. |
| `neighborhood-book-club-product-experience.md` | fail | Section 7 has stale non-canonical rows and omits canonical `book-*` workflows. |
| `persona-role-inventory-product-experience.md` | fail | Duplicate support workflow ownership with Masjid and incomplete capability-matrix semantic rows. |
| `platform-social-product-experience.md` | pass with context | Product-doc rows align; `platform-blocked-target` still fails the separate lifecycle judge. |
| `riverside-youth-soccer-product-experience.md` | pass | Section 6/7/semantic/registry rows align with B25 evidence. |

## Context Dependencies

`b25-workflow-lifecycle-scorecards.md` currently reports 7 failing scorecards:
`gear-loan-request`, `platform-blocked-target`, `ad-off-member-checkout`,
`ad-off-community-checkout`, `ad-off-entitlement-status`, `ad-off-receipt-evidence`, and
`ad-off-ad-suppression`.

Those failures still block broader B25 closure, but they are tracked as implementation/evidence
dependencies rather than product-doc drift in this reconciliation.

## Next Actions

1. Update Garden, Book Club, and Chess Section 7 matrices to use exact canonical workflow IDs.
2. Decide whether the Shell product doc is in B25 screenshot scope; either add evidence and semantic rows or mark it out of scope.
3. Resolve persona-role-inventory ownership for the Masjid support workflows and complete its semantic model rows.
4. After product-doc fixes, rerun the product-doc reconciliation gate before treating lifecycle-only failures as the remaining B25 blocker.
