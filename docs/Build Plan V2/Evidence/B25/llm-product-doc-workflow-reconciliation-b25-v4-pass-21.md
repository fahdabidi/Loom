# B25 Product Docs To Screenshot Evidence Reconciliation - Pass 21

| Field | Value |
| --- | --- |
| Run ID | `b25-v4-pass-21` |
| Decision | `fail` |
| App commit | `9d26c73` |
| Product docs reviewed | 12 |
| B25 screen rows reviewed | 195 |
| B25 workflow/persona rows | 68 |
| B25 lifecycle failures | 22 |

## Summary

The Product Docs V2 community examples do not yet reconcile with current pass-21 screenshot evidence.
Section 6 now covers most domain workflow IDs, but the docs still fail the stricter screenshot-backed
gate because several Section 7 matrices are sparse or stale, Masjid B17-B20 persona evidence is
captured under Masjid but not listed in Masjid Section 6/7, stale umbrella workflow IDs remain without
B25 screen rows, Platform Social semantic interaction rows are incomplete for ad/no-fill workflows,
and B25 lifecycle scorecards show 22 workflow/persona pairs whose screenshots do not prove the
documented production workflow lifecycle.

Do not mark B25 pass from structural product-doc coverage alone. `independent-production-ux-review.json`
still has `finalDecision=fail` and the open major finding `B25-WORKFLOW-LIFECYCLE-INCOMPLETE`.

## Exact Fixes

1. Update sparse Section 7 matrices to use canonical workflow IDs.
   - `docs/Product Docs V2/Community Examples/garden-club-product-experience.md`: replace `event RSVP` and `plant exchange` with rows for `garden-event-rsvp`, `plant-exchange-submission`, and `garden-export-custom-schemas`.
   - `docs/Product Docs V2/Community Examples/riverside-youth-soccer-product-experience.md`: add canonical rows for all seven soccer workflows, not only `registration payment` and `roster`.
   - `docs/Product Docs V2/Community Examples/neighborhood-book-club-product-experience.md`: add canonical rows for all seven book club workflows, not only `selection publish` and `discussion`.
   - `docs/Product Docs V2/Community Examples/chess-club-product-experience.md`: replace `package open` with rows for `chess-local-install-open`, `chess-route-home`, and `chess-match-result`.

2. Resolve Masjid/persona workflow ownership drift.
   - B25 rows `b25-v4-row-186` through `b25-v4-row-195` capture `wf_demo-app-persona-picker`, `wf_community-persona-aware-ux`, and `wf_multi-persona-workflow-evidence` as Masjid Nur screenshots.
   - Masjid Section 6/7 lists only the `mosque-*` workflows, while `persona-role-inventory-product-experience.md` declares some of these support workflows but B25 productDocCoverage maps only `wf_persona-role-inventory-capability-matrix` to that doc.
   - Fix by either documenting those support workflows in Masjid Section 6/7 or reclassifying the B25 productDocCoverage/screen rows so the persona-role doc owns them. Remove duplicate/conflicting rows from the other doc.

3. Remove or prove stale umbrella workflow IDs.
   - `camera-club-product-experience.md` still declares `skill-prompt-build-validate-complete`, but no B25 screen rows exist for it.
   - `loom-communities-shell-product-experience.md` declares `local-build-download-sideload-install`, but the shell doc is missing from B25 productDocCoverage and has no B25 screen rows.
   - `persona-role-inventory-product-experience.md` declares `wf_community-persona-aware-ux`, `wf_multi-persona-workflow-evidence`, and `wf_demo-app-persona-picker`, but current B25 rows for those workflows are assigned to Masjid.
   - Either remove these stale rows or add fresh B25 workflow/persona rows, screenshots, semantic rows, and card registry rows under the same doc ownership.

4. Complete Platform Social semantic interaction rows.
   - Section 6 lists `platform-in-stream-ad`, `platform-top-banner-no-fill`, and `platform-sensitive-no-fill`.
   - The B25 semantic interaction table omits `platform-in-stream-ad` and `platform-top-banner-no-fill`.
   - Add semantic rows for every platform ad/no-fill/block workflow with concrete object, decision data, primary action, alternate/safety action, persistent result state, receiver/continuation state, and card-surface interactions.

5. Fix screenshot-proof lifecycle failures before passing reconciliation.
   - Current failing workflows: `soccer-team-roster`, `soccer-registration-payment`, `soccer-practice-schedule`, `soccer-export-metadata`, `hoa-dues-payment`, `mosque-donor-visibility`, `mosque-donation-payment`, `mosque-care-request`, `mosque-neutral-notification`, `photo-walk-rsvp`, `critique-submission`, `gear-loan-request`, `platform-blocked-target`, `platform-in-stream-ad`, `platform-top-banner-no-fill`, `platform-sensitive-no-fill`, `ad-off-member-checkout`, `ad-off-community-checkout`, `ad-off-entitlement-status`, `ad-off-receipt-evidence`, `ad-off-ad-suppression`, and `ad-off-settlement-utility`.
   - Do not weaken product docs to match incomplete screenshots. Clarify ambiguous semantic/card rows first, then update UI/content/seed data/tests so screenshots prove concrete object, decision information, domain-specific primary action, alternate/change/reject path, durable result, and receiver/continuation state.

6. Scope B12 harness evidence explicitly.
   - `docs/Build Plan V2/Evidence/B12/workflow-ui-evidence.json` includes `workflow-ui-evidence-harness`, and `B20/all-workflow-ui-evidence.json` counts it in the 66 workflow manifests.
   - B25 screenRows exclude it. Mark it as out-of-scope harness evidence or exclude it from product-doc reconciliation inputs.

## Screenshot-Backed Evidence

| Finding | Evidence |
| --- | --- |
| Sparse Section 7 matrices | B25 workflow/persona coverage passes for `b25-wp-001` through `b25-wp-017` and `b25-wp-033` through `b25-wp-035`, but the matching product docs do not enumerate those canonical state rows. |
| Masjid missing support workflows | `docs/Build Plan V2/Evidence/B18/screenshots/B18_persona_picker_dialog.png`, `docs/Build Plan V2/Evidence/B19/screenshots/B19_member_care_request_actor.png`, `docs/Build Plan V2/Evidence/B19/screenshots/B19_admin_announcement_actor.png`, and `docs/Build Plan V2/Evidence/B20/screenshots/B20_announcement_member_received.png`. |
| Lifecycle proof failure | `docs/Build Plan V2/Evidence/B25/b25-workflow-lifecycle-scorecards.md` reports 22 failing scorecards. Representative rows include `b25-v4-row-034-soccer-team-roster-0`, `b25-v4-row-052-hoa-dues-payment-0`, `b25-v4-row-088-mosque-care-request-0`, `b25-v4-row-106-photo-walk-rsvp-0`, `b25-v4-row-130-platform-in-stream-ad-0`, and `b25-v4-row-139-ad-off-member-checkout-0`. |
| Stale product-doc rows | No B25 screen rows exist for `skill-prompt-build-validate-complete` or `local-build-download-sideload-install`; persona support workflows are captured under Masjid rows rather than persona-role-inventory coverage. |

## Product Doc Coverage Rows

| Product doc | Reconciliation | Main gaps |
| --- | --- | --- |
| `ad-off-product-experience.md` | fail | Section 6/7 IDs align, but all six ad-off workflows fail B25 lifecycle proof for persistent result and receiver/continuation state. |
| `camera-club-product-experience.md` | fail | Stale `skill-prompt-build-validate-complete` row; all three implemented camera workflows have lifecycle failures. |
| `cedar-commons-hoa-product-experience.md` | fail | Section 6/7 IDs align, but `hoa-dues-payment` fails lifecycle proof. |
| `chess-club-product-experience.md` | fail | Section 7 uses only `package open` and omits all three canonical chess workflows. |
| `export-and-migration-product-experience.md` | pass | Section 6/7, semantic rows, registry rows, and lifecycle evidence align. |
| `garden-club-product-experience.md` | fail | Section 7 uses vague `event RSVP` and `plant exchange` rows and omits all canonical garden workflow IDs. |
| `loom-communities-shell-product-experience.md` | fail | Declares `local-build-download-sideload-install`, but B25 productDocCoverage and screenRows do not include it. |
| `masjid-nur-product-experience.md` | fail | Missing B17-B20 support workflows from Section 6/7; registry incomplete for those workflows; four mosque workflows fail lifecycle proof. |
| `neighborhood-book-club-product-experience.md` | fail | Section 7 uses only `selection publish` and `discussion`, omitting all seven canonical book workflows. |
| `persona-role-inventory-product-experience.md` | fail | Declares support workflows that current B25 coverage assigns to Masjid; duplicated rows need ownership cleanup. |
| `platform-social-product-experience.md` | fail | Section 6/7 align, but semantic rows are missing for `platform-in-stream-ad` and `platform-top-banner-no-fill`; four platform workflows fail lifecycle proof. |
| `riverside-youth-soccer-product-experience.md` | fail | Section 7 omits all seven canonical soccer workflows; four soccer workflows fail lifecycle proof. |

## Decision

Fail. The current artifacts do not yet prove that Product Docs V2 enumerate and specify the workflows,
personas, states, and product surfaces actually implemented and reviewed by B25. The next pass must
update product docs where ownership/state/semantic rows are missing, remediate the 22 lifecycle proof
failures in UI/evidence, recapture B12-B20 evidence, and rerun B25 reconciliation.
