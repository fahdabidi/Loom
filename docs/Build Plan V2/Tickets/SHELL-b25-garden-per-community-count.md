# SHELL — Garden's per-community B25 count moves 5 → 6

**Status:** written 2026-10-01, **NOT dispatched**.
**Route:** `data/call_implementation_agent.sh --fresh`. Confirm the `Mode: fresh session` line.
**Size:** one number. Follows [SHELL-b25-row-count-77-to-78.md](SHELL-b25-row-count-77-to-78.md), which was correct but incomplete — see below.

## The change

`app/packages/tooling/loom_ux_judges/test/b25_product_doc_interaction_models_test.dart:32`

    'community_garden_club': 5,   →   'community_garden_club': 6,

That is the whole ticket.

## Why, and why the previous ticket missed it

Garden's product doc gained a `garden-volunteer-shift` B25 row. The predecessor ticket updated
`kB25ProductDocInteractionRowCount` from 77 to 78, which turned app shell and demo green — but this
same test *also* asserts a **per-community breakdown**, and Garden's entry there is a literal `5`.

**I scoped that ticket by searching for the number that changed (`77`) and a per-community `5` could
never match it.** The population of a count change is not only the literal total; it is every place
that **partitions** that total. The map is the only such place in the repo — verified by grepping for
`community_garden_club.: *[0-9]+` across all Dart, which returns this line alone.

**The map is a complete partition, which is how you can be sure this is the only edit:**
15 + 8 + 9 + 9 + 8 + 6 + 8 + 6 + **5** + 3 = **77** today. With Garden at 6 it sums to **78**, matching
the constant. If your change does not make those two agree, stop and say so.

## Do not

- **Do not alter any other community's entry.** Only Garden's doc gained a row; the other nine are
  correct and their sum is the proof.
- **Do not replace the map with a computed value or loosen the assertion.** It is a deliberate guard:
  it catches a row appearing in the wrong community's doc, which a bare total cannot. Updating a
  number because the corpus genuinely differs is correct; replacing the check is not.
- **Do not touch the product doc or the generated asset.** Both are already correct at 78.

## Verification

- UX judges returns to **525**, exit 0, 0 skipped. That is the only suite this touches.
- The other four stay at their current green values — app shell **448 (+2)**, demo **264**, engine
  **345 (+1)**, service **168 (+1)** with both credential sets — all four measured green already, so
  any movement there is yours.
- `flutter analyze` on `loom_ux_judges`: unchanged. Take the count from flutter's own `N issues found`
  line, not from a grep over its output.
