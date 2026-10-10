# HARNESS — the fanId filler taps without scrolling, with the miss suppressed

**Status:** written 2026-10-05. **DISPATCHED AND SHIPPED as `9deba3ed`** -- verified by my own five-suite run and A/B, not on the agent's word. Device-measured effect: fanId tap failures 3 to 0; row_execution_failed 14 to 10. Kept for its reasoning; do NOT re-dispatch. One-line fix plus a regression test.
**Route:** `data/call_implementation_agent.sh --fresh`. Confirm the `Mode: fresh session` line.
**Scoped by** `data/call_root_cause_agent.sh` (session key `b25-fanid-picker-tap`). It reached a
confident diagnosis, said plainly that **none of my four candidates was right**, and I then
verified every load-bearing claim myself by reading the code. **This ticket SUPERSEDES
`HARNESS-fanId-picker-tap-does-not-flip-the-checkbox.md`** — delete that one; its four candidate
hypotheses are all dead and leaving them would send the next reader down four wrong paths.

## The mechanism

`fillB25FanIdField` (`test/workflow_ui_test_harness.dart:450-485`) taps the member checkbox with
**no `ensureVisible` and no hit test**, and silences the only signal that would report the miss:

    await tester.tap(checkbox, warnIfMissed: false);   // :469
    await tester.pumpAndSettle();

The tile is enabled, correctly keyed, and belongs to an active member. It is simply **below the
fold** of the creation dialog, so the pointer event lands at clipped coordinates, `onChanged` never
runs, and the postcondition then correctly reports the unchanged `false`.

**Three facts make the off-screen tile invisible to every check before the assert**, each verified:

| fact | where |
|---|---|
| the dialog content is a `SingleChildScrollView`, which builds **all** children regardless of viewport — so an off-screen checkbox exists and satisfies an existence wait | `part33_generic_creation_card.dart:163-165` |
| the sibling filler **does** prepare visibility: `fillB25BoolField` calls `await tester.ensureVisible(editor)` before its tap | `workflow_ui_test_harness.dart:409,414` |
| `tapWhenVisible` already exists and is already used at two other call sites | `workflow_ui_test_harness.dart:182`, used at `:708` and `:1016` |

**This is the asymmetric-sibling shape this project records** — the preparation exists in the
filler written earlier and is missing from the one added next to it. Which rows fail is purely
positional (field order, the height of preceding fields, the member's index in the directory),
which is why it looks workflow-specific and is not.

## The fix

Replace the raw tap with the harness's own prepared-tap helper. **Do not hand-roll a second copy of
the visibility logic** — two call sites implementing "tap a prepared target" independently is how
this asymmetry arose.

    final current = tester.widget<CheckboxListTile>(checkbox).value;
    if (current != true) {
    -  await tester.tap(checkbox, warnIfMissed: false);
    +  await tapWhenVisible(
    +    tester,
    +    checkbox,
    +    description: 'member checkbox "$fanId" in the FanIdFormPicker at $editor',
    +  );
       await tester.pumpAndSettle();
    }

`tapWhenVisible` supplies what this call site lacks: `ensureVisible`, re-applied after a bounded
pump, a real hit test, and a loud failure **at the tap** naming off-screen versus obscured. That
last part matters as much as the fix: it converts any recurrence from "checkbox still reads false"
— a message that sent me to four wrong hypotheses — into one that names the actual geometry.

**The scroll must stay inside the per-fanId loop** (it already is a loop): selecting an earlier
member can grow the chip `Wrap` and shift later tiles, so visibility has to be re-established per
member rather than once up front.

**Keep the postcondition assert exactly as it is.** It did its job — it caught a tap that never
landed instead of banking three instances with an unset identity field. Do not weaken or remove it.

## Scalar and list are ONE ticket

The mechanism lives entirely in `fillB25FanIdField`, which handles both shapes through the same
per-fanId loop; scalar versus `multiple` only changes `_setSelected`'s set arithmetic, which is
never reached. The soccer list row (`authorizedGuardianFanIds`) fails identically because its one
target checkbox is equally off-screen.

## Honesty test — it must fail against today's code

- **A widget test that renders the creation dialog with enough preceding fields and members that
  the target checkbox starts off-screen**, then calls `fillB25FanIdField` and requires the member to
  be selected. Constrain the surface size / `MediaQuery` so the geometry is deterministic rather
  than incidental.
- **Run it against the unfixed filler first and record the verbatim failure** — it must fail with
  the current "checkbox still reads false" message. A test that passes both before and after proves
  nothing. Then A/B the fix: neutralise only the `tapWhenVisible` call, confirm the test fails,
  restore and `cmp`-verify byte-identical.
- Keep every currently-green test green, including the planner's 24.

## The three rows this should clear

| community | workflow | field |
|---|---|---|
| Garden Club | `garden-tool-giveaway` | `coordinatorFanId` |
| Garden Club | `garden-tool-loan` | `coordinatorFanId` |
| Riverside Youth Soccer | `soccer-waiver-document` | `authorizedGuardianFanIds` |

## Scope limit

Only `fillB25FanIdField`. Do **not** touch the readGuard disjunction, `url`/`list` arrangement, the
direction derivation, the postcondition assert, or any other arrangement class. If another row
fails while you work, record its outcome and continue rather than aborting the batch.

## Verification

- All five suites, **sequentially**, skip counts before pass counts: demo **310** (0 failed,
  0 skipped), app shell **448** (+2), judges **525**, engine **345** (+1, BOTH Postgres credential
  sets), service **168** (+1, the one skip being App Access and **not** PostgreSQL).
  `b25_capture_prebuilt_binary_test.dart` is flaky about 1 run in 3 with a rotating test name;
  confirm a `TimeoutException` and an isolated pass before believing it.
- `flutter analyze` on the demo app: **3** pre-existing issues, from the tool's own
  `N issues found` line, with the working directory stated.
- **The device is the real check**, because the planner's unit tests pass today while the device
  fails. Re-run `--mode targeted-precheck --phases B12,B13` with a **scratch `--evidence-root`**
  and confirm those three rows no longer report this message, with no rise in
  `row_execution_failed`.
- **Emit `<<<SUITES_RUN: ...>>>`.** The dispatcher refuses a reply without it and exits 2;
  `NOT_RUN(reason)` is a correct entry for anything you genuinely could not run.
