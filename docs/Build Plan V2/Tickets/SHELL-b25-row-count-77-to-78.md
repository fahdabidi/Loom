# SHELL — the B25 product-doc row count moves 77 → 78

**Status:** written 2026-10-01, **NOT dispatched**.
**Route:** `data/call_implementation_agent.sh --fresh`. Confirm the `Mode: fresh session` line.
**Size:** one constant, one comment, one test name. Deliberately tiny — read "Do not" before widening it.

## Why the number changed

Garden Club's product doc gained a B25 addendum row for `garden-volunteer-shift` (commit on
`docs/references/communities/garden-club-product-experience.md`, same change regenerated
`app/packages/core/loom_communities_app_shell/assets/b25_semantic_interaction_models.json` to 78 rows).

The workflow is real, shipped and implemented, and **the doc's own coverage table already demanded B25
evidence for it** — its row there ends in a `B25` column — while the B25 Semantic Interaction Models
table omitted it. A note in that doc dated 2026-08-10 explains how: the workflow "was missing from this
doc entirely", two rows were added to close the gap, and the semantic-interaction row was not one of
them. So this is an internal inconsistency being repaired, not a new requirement.

**Consequence, stated plainly because it is the point:** the production bar's denominator moves from
**72 to 73** real rows (78 present − 5 Masjid `wf_` test-harness ids the doc disclaims). The
completion fraction gets worse while becoming true, and the new row starts unproven.
`check_b25_status.sh` already recomputes this correctly — verified, it prints 78 / −5 / 73 — so no
tooling change is needed for the bar itself.

## What to change

`kB25ProductDocInteractionRowCount` is the single source of truth and **every consumer already reads
it**, which is why this ticket is three lines rather than five files:

| File | Line | Change |
|---|---|---|
| `app/packages/tooling/loom_ux_judges/lib/b25_product_doc_interaction_models.dart` | 25 | `const kB25ProductDocInteractionRowCount = 77;` → `78` |
| same file | 24 | the comment `/// 77 - 5 = 72 rows. This constant is the asset row count, not that bar.` → `78 - 5 = 73`, keeping the second sentence exactly as it is |
| `app/packages/tooling/loom_ux_judges/test/b25_product_doc_interaction_models_test.dart` | 14 | the test name `'loads all 77 B25 rows from the ten owning product docs'` → `78` |

**The five consumers of the constant, enumerated so nobody has to guess whether the sweep was
complete** — all of them assert against the constant, so none needs editing:

    app/apps/loom_communities_demo/integration_test/workflow_ui_evidence_test.dart
    app/apps/loom_communities_demo/test/b25_product_doc_action_vocabulary_test.dart
    app/packages/core/loom_communities_app_shell/test/b25_interaction_model_asset_conformance_test.dart
    app/packages/tooling/loom_ux_judges/lib/b25_product_doc_interaction_models.dart
    app/packages/tooling/loom_ux_judges/test/b25_product_doc_interaction_models_test.dart

## The failure this fixes

`b25_interaction_model_asset_conformance_test.dart` — *"bundled B25 interaction rows are generated
exactly from product docs"* — fails with `Expected: an object with length of <77> / Actual: [78 …]`.
It reads `hasLength(kB25ProductDocInteractionRowCount)`, so the constant is the whole fix.

## Do not

- **Do not change the generated asset by hand.** It is produced by
  `loom_ux_judges/bin/generate_b25_interaction_model_asset.dart` and has already been regenerated;
  if it ever disagrees with the docs, regenerate rather than edit.
- **Do not touch any product doc.** `docs/references/**` is hard-locked from dispatches. The doc row
  is already committed; if you believe it is wrong, say so in your reply and stop.
- **Do not "fix" the count by removing the row**, and do not relax any assertion to `greaterThan`.
  A hardcoded count that must be updated deliberately is the point of this guard: it refuses to let
  the bar's size change silently. Updating the number because the corpus genuinely differs is correct;
  loosening the comparison is not.
- **Do not change `fullB25MinimumScreenshotRows`** or any capture threshold. This ticket is about the
  product-doc row count only; those are separate constants with their own coupled call sites.

## Measured blast radius, before the fix

Three suites each fail by exactly one test, and all three report the identical cause
(`Expected: an object with length of <77>`, actual 78). This is the A/B: these are the numbers now,
and the Verification section's numbers are what they must become.

| Suite | Now (pre-fix) | After | The one failing test |
|---|---|---|---|
| App shell | 447 (+2) −1 | 448 (+2) | `b25_interaction_model_asset_conformance_test.dart` |
| Demo app | 263 −1 | 264 | `b25_product_doc_action_vocabulary_test.dart` |
| UX judges | 524 −1 | 525 | `b25_product_doc_interaction_models_test.dart` |

Engine and service are unaffected — neither reads the constant.

**Three failures, one cause, one line.** If changing the constant does not turn all three green
together, something else is wrong and you should stop and say so rather than editing three tests.

## Verification

- All five suites, skip counts read before pass counts. Expected: app shell **448 (+2)**, demo **264**,
  judges **525**, engine **345 (+1)**, service **168 (+1)** with both credential sets. Note the demo
  and judges totals should be **unchanged** — their tests assert against the constant, not a literal.
- `flutter analyze` on the two touched packages. The demo app carries **3** pre-existing issues
  (`flutter_lints` include, an `unnecessary_import` in `load_all_communities_test.dart`, and an unused
  `_availableIdentitiesDiagnostic`); take the count from flutter's own `N issues found` line, not from
  a grep. A fourth is yours.
