# HARNESS — the fanId picker tap lands on the right tile and the checkbox stays false

**Status:** written 2026-10-05, **NOT dispatched**.
**Route:** `data/call_root_cause_agent.sh` FIRST (this is narrowed but not solved), then
`data/call_implementation_agent.sh --fresh` from its answer.

## The failure, verbatim from the device

Three rows, one cause, **new in this run** (count 0 in the previous run — controlled):

    B25 fanId field tap did not land: expected member "fan-garden-member-1" to be selected
    in the FanIdFormPicker at Found 1 widget with key
    [<'new-garden-tool-giveaway-editor-coordinatorFanId'>]: [
      KeyedSubtree-[<'new-garden-tool-giveaway-editor-coordinatorFanId'>],
    ], but its checkbox still reads false.

| community | workflow | field |
|---|---|---|
| Garden Club | `garden-tool-giveaway` | `coordinatorFanId` |
| Garden Club | `garden-tool-loan` | `coordinatorFanId` |
| Riverside Youth Soccer | `soccer-waiver-document` | `authorizedGuardianFanIds` |

**This is the new code failing honestly, not silently.** It asserts the postcondition — the
checkbox reads true — instead of assuming the tap worked, which is why we have a precise message
rather than three instances created with an unset identity field. Do not weaken that assertion.

## TWO HYPOTHESES ALREADY DISPROVEN — do not re-test these

1. **"The executor taps the field container instead of the member row."** False. The harness taps
   `find.byKey(ValueKey('fan-id-picker-member-$fanId'))` scoped inside the field
   (`workflow_ui_test_harness.dart:457`), which is exactly the `CheckboxListTile`'s own key
   (`part21_audience_multi_select_picker.dart:287`). The `KeyedSubtree` in the message is the
   *outer* `at` context, not the tap target.
2. **"The member is not an active membership, so `onChanged` is null and the tile is inert."**
   False, measured against the live backend: `group_membership` has `fan-garden-member-1` and
   `fan-soccer-guardian-1` both `state = active`, and a control shows **all 63 memberships in the
   database are `active`** — there is no non-active membership anywhere to hit.

So the tile exists, is keyed correctly, is tapped, belongs to an active member, and its value stays
`false`.

## The remaining candidates, in the order I would test them

`CheckboxListTile.onChanged` is
`enabled && member.status == MembershipStatus.active ? ... : null`
(`part21:289-293`). Membership status is ruled out, so:

1. **The picker's own `enabled` flag is false.** Find what supplies it from
   `part33_generic_creation_card.dart`'s `FanIdFormPicker(...)` call and whether anything in the
   creation-card state disables fields at the moment the harness taps (mid-load, saving, a
   read-only state). This is my leading candidate purely by elimination.
2. **`MembershipStatus` as parsed by the client differs from the `state` column.** The DB says
   `active`; the question is what `listCommunityMembers` maps it to on the remote path. A mapping
   that yields anything else would make `active` in Postgres and non-active in the widget — the
   identifier-space hazard this project records, one layer over.
3. **The tap flips state that the assertion does not read.** `_setSelected` may update a parent
   controller whose value reaches the widget only on rebuild, so a missing `pumpAndSettle` between
   tap and assert would read a stale `false`. Check whether the assertion pumps.
4. **The directory is empty or lacks that fan at tap time**, and the finder matched a preserved or
   unknown-fan row rather than a member row. The keys differ
   (`fan-id-picker-preserved-$fanId`, `fan-id-picker-unknown-$fanId`) so this should be
   distinguishable by asserting which key matched.

## What the root cause dispatch needs from the brief

It is read-only and cannot fetch live evidence, so paste in: the verbatim failure above, the two
disproven hypotheses with their evidence, the `group_membership` query result, and the
`part21:285-301` and `harness:450-485` excerpts. Ask it to attack candidate 1 first and to say
plainly if the answer is none of the four.

## Scope limit

Three rows. Do **not** touch the readGuard disjunction, `url`/`list` arrangement, the direction
derivation, or any other arrangement class. If a row fails while you work, record it and continue.

## Verification

- All five suites, **sequentially**, skip counts before pass counts: demo **310** (0 failed,
  0 skipped), app shell **448** (+2), judges **525**, engine **345** (+1, BOTH Postgres credential
  sets), service **168** (+1, the one skip being App Access and **not** PostgreSQL).
- `flutter analyze` on the demo app: **3** pre-existing issues, from the tool's own total.
- **The device is the only real check here**, because the planner's unit tests pass today while the
  device fails — re-run `--mode targeted-precheck --phases B12,B13` with a **scratch
  `--evidence-root`** and confirm the three rows no longer report this message.
- **Emit `<<<SUITES_RUN: ...>>>`.** The dispatcher refuses a reply without it and exits 2.
