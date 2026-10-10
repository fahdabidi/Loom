# HARNESS — one row's stall must not abort the whole `full-b25` batch

**Status:** written 2026-10-10, **NOT dispatched**. Separable from, and lower priority than,
`HARNESS-created-instance-reader-must-be-renderer-aware.md` — **dispatch that one first.**
**Route:** `data/call_implementation_agent.sh --fresh`. Confirm the `Mode: fresh session` line.

## The evidence

The `full-b25` run on 2026-10-06 (commit `9deba3ed`, live backend, instrumented APK) ended:

    exit=1, workflows=5, b25Communities=0/14, b25IncompletelyTraversed=14

One row — Garden's `garden-tool-giveaway` — waited on a condition it could not satisfy, its 3m
stall watchdog expired at **3m 51s**, and that **aborted `flutter drive`, taking all nine phases
with it**. The same build in `--mode targeted-precheck` traverses **83** workflows. So 78 rows went
unattempted because of one.

Three sibling rows hit the *identical* condition and recorded
`action_succeeded_result_unverified` instead of stalling, which is the designed behaviour — the row
is marked unproven and the run continues. **Only the fourth escalated to a watchdog abort.** Why
that one differed was not traced; it becomes moot once the wait condition is correct, but the
fragility it exposed does not.

## Why this is worth a ticket even after the reader fix

Fixing the reader removes **today's** trigger, not the class. `full-b25` is the only bar-eligible
capture mode and it refuses to narrow by community or shard, so **any** single row that can stall
to the watchdog costs the entire canonical run — all nine phases, every other community. With 73
rows to prove and a run measured in tens of minutes, a one-row abort is the difference between a
usable artifact and nothing.

This is the shape this project already records: *"a defect that belongs to one item in a batch must
change that item's recorded outcome, not the batch's control flow."* The earlier instance was a
`StateError` thrown with a perfectly accurate diagnostic that still aborted all eighty workflows.

## The change

**A stall watchdog expiry for one row must record that row's outcome and continue to the next
row.** It must not propagate out of the per-row scope and kill the driver.

Three constraints:

- **Give it its own outcome name.** Do not reuse `action_succeeded_result_unverified` or
  `row_stalled_inconclusive` if either already means something narrower. *"The row ran and its
  action was not offered"*, *"the row ran and its result was not observed"*, and *"the row could
  not be attempted at all"* are three different facts, and the third must never be counted as
  evidence about the first two.
- **Say explicitly that a skipped-over row is not proven**, in its own bucket with its own total, so
  no completion figure can quietly absorb it.
- **Keep the watchdog.** The point is not to wait longer or to stop detecting stalls; it is that
  detecting a stall in row N must not prevent rows N+1..73 from being attempted.

## Honesty test — the property is invisible in a single-row fixture

- **A test asserting CONTINUATION**: a batch of at least three rows where the middle one stalls to
  its watchdog; the run must record that row's outcome and still attempt and report the third.
  "It kept going" is exactly the property a one-row fixture cannot show.
- **Run it against the current code first** and record the verbatim abort, so the test is proven
  able to fail.
- **Assert the bucket totals add up**: attempted = proven + each non-proven bucket, with the
  stalled-and-skipped row in its own column. A test that only checks "no exception escaped" would
  pass against code that silently dropped the row.

## Scope limit

Only the per-row stall boundary and its outcome recording, plus tests. Do **not** change the
watchdog's duration, the inner wait budgets, the created-instance reader (separate ticket), the
arrangement planner, or any product code. If a row fails while you work, record it and continue —
which is, fittingly, the behaviour this ticket is about.

## Verification

- All five suites, **sequentially** (judges beside engine gives a false timeout), skip counts before
  pass counts: demo **312** (0 failed, 0 skipped), app shell **448** (+2), judges **525**, engine
  **345** (+1, BOTH Postgres credential sets), service **168** (+1, the one skip being App Access
  and **not** PostgreSQL). `b25_capture_prebuilt_binary_test.dart` is flaky about 1 run in 3 with a
  rotating test name; confirm a `TimeoutException` and an isolated pass before believing it.
- Account for every total that moves: declared-count delta plus an offset of **8** has predicted the
  demo total exactly eleven times.
- `flutter analyze` on the demo app: **3** pre-existing issues, from the tool's own total, with the
  working directory stated.
- **Emit `<<<SUITES_RUN: ...>>>`.** The dispatcher refuses a reply without it; it exits 2 for a
  missing report and 3 for an infrastructure failure where the agent never ran.
- **Do not quote a completion figure.** The bar is 73 real rows; `CONFIRMED` is 0 and `b25Proven`
  is 0.
