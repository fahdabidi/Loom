# HARNESS — the arrangement seam must beat its own steps (stop fixing this one site at a time)

**Status:** written 2026-10-02, **NOT dispatched**.
**Route:** `data/call_implementation_agent.sh --fresh`. Confirm the `Mode: fresh session` line.
**Follows:** `1efdfd30`, measured on-device by me immediately after.
**Evidence:** Garden precheck at `1efdfd30`, scratch evidence root. `exit=1`, `workflows=2`,
`b25Proven=0/1`, `b25RowExecutionFailed=0`, zero `found modal-barrier`, `screenshots=3/3`,
canonical `Evidence/` untouched.

## The pattern to stop repeating

**This is the third watchdog stall in three consecutive increments, and I have fixed it twice by
adding a beat at whichever site happened to fail.** That is treating instances of a class as
individual defects. The population, not the site, is the scope.

| Increment | Stall site | My fix |
|---|---|---|
| `7e263a94` | `signing in as garden-member` | 8 beats at call sites (`61a2e01b`) |
| `1efdfd30` | `resolving the creator identity` | 3 more beats |
| now | `opening the creation tab` | — |

Each time, the *new* work landed inside an un-beaten stretch and the next run died one step later.
**And reach is now going backwards as a direct result: `workflows` 8 → 4 → 2.** Every increment makes
arrangement do more work per row, so more rows die to a watchdog that is measuring a sum nobody
reports progress on.

## The structural cause, measured

    Last completed step: authenticated creator fan-garden-coordinator-1 for garden-event-rsvp
    Attempted step:      opening the creation tab for garden-event-rsvp as garden-coordinator
    Waiting for:         the shipped creation form to become available
    (3m 0s elapsed, limit 3m 0s)

- **13** `beat()` calls now exist in `integration_test/workflow_ui_evidence_test.dart`.
- **ZERO** references to `bodyWatch`/`BodyWatch` exist in `test/b25_remote_arrangement.dart`.

So the arrangement seam **cannot beat, because it never receives the watch**. Authenticate creator →
open tab → open form → fill each field → submit → identify the created instance is, to the watchdog,
a *single* no-progress gap — however many real steps it contains. `3m 0s / limit 3m 0s` is the
watchdog, exactly as in the two previous increments.

**Note what the stall message already proves:** it names "authenticated creator … " as the last
completed step and "opening the creation tab" as the attempted one. **The seam already knows its own
step boundaries** — it simply has no way to tell the watchdog about them.

## The change

**Pass the watch into the arrangement seam and beat at every internal step boundary**, naming the
step that just completed. The boundaries are already enumerated by the seam's own progress strings —
use those, so the beat text and the stall text cannot drift apart.

This is what the watchdog's own doc comment prescribes: *"call `beat` whenever the body completes a
step or crosses a phase boundary."* The arrangement seam completes many steps and crosses none of
them as far as the watchdog can see.

**Do not:**

- **Do not widen `defaultTimeout`.** Three increments have now been misdiagnosed as slowness; each
  was legitimate work in an un-beaten stretch. Widening would degrade stall detection for every row
  to accommodate a reporting gap.
- **Do not add more call-site beats.** That is the fix that has already failed twice. If a beat lives
  outside the work it is meant to bound, the next increment will outgrow it again.
- **Do not make the seam depend on the evidence test.** Take an optional callback or a small
  interface so `b25_remote_arrangement.dart` stays unit-testable without a live watch.

## Also fix: two gaps carried from `1efdfd30`

1. **The `bool` setter has no postcondition.** It calls `ensureVisible`, reads the real
   `SwitchListTile.value`, taps with `warnIfMissed: false`, and **never re-reads the value**. A missed
   tap leaves the bool wrong, the form submits anyway, and nothing notices. Re-read after tapping and
   assert it equals the required value. This matters because a consent bool may need to be **true**
   for the row's action to be reachable, so a silently-unset value presents as a legitimate product
   block rather than a harness fault.
2. **`1efdfd30` shipped four behavioural changes with no unit tests** (the demo total stayed at 292).
   That was a gap in my ticket, not in the work — so this ticket says it explicitly: **each change
   below needs a test that fails before it and passes after**, run against the un-fixed code first.

## Verification

- A test that **fails before and passes after**: an arrangement whose internal steps take longer than
  the watchdog's budget must survive, because each step beats. Drive it with a short watchdog and a
  slow stub rather than by waiting three real minutes.
- A test for the `bool` postcondition: a setter whose tap does not land must **fail loudly**, not
  submit a wrong value.
- All five suites, skip counts before pass counts: demo **292** (0 failed, 0 skipped), app shell
  **448** (+2), judges **525**, engine **345** (+1, both credential sets), service **168** (+1, the
  one skip being App Access and **not** PostgreSQL). Run them **sequentially**.
- **`b25_capture_prebuilt_binary_test.dart` is known flaky** (~1 run in 3, a different test each
  time, each spawning a real subprocess against a 30s budget). Confirm any single failure there is a
  `TimeoutException` and that the file passes isolated, then treat it as environmental.
- `flutter analyze` on the demo app: **3** pre-existing issues; take the count from flutter's own
  `N issues found` line.
- **Success criterion in the run's own units:** `workflows` back to **7+** with all six Garden rows
  attempted, `b25RowExecutionFailed` still 0, zero `found modal-barrier`. `b25Proven` may still be 0 —
  say so plainly.
- **Report what you actually ran.** Eight consecutive dispatches here have exited status 0 reporting
  only their intent. Name anything you skipped.
