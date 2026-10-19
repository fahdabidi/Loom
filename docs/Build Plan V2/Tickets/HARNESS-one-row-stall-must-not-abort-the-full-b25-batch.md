# HARNESS — a row the watchdog abandons must stop running before the batch continues

**Status:** written 2026-10-10, **REWRITTEN and SHIPPED 2026-10-18** — dispatched on Muse, plus the one-test follow-up `HARNESS-ticket2-followup-the-loser-test-must-wait-before-asserting.md`, and verified by the validation session's own oracle: a four-mutation A/B (seam ignores cancellation, no settle wait, stop decision always continue, no cancel signal) in which every mutation turned its intended test red; all five suites sequentially with both Postgres credential sets (demo **324** = 319 + 5 declared, the rest at baseline). Known gap, not fixed: frames the loser captures while unwinding are still attributed to the stalled row. That row is never proven, so the bar cannot be inflated by it. The device measurement is owed with the rest of the batch. The 2026-10-10 version
**DISPATCH RECORD (written by call_implementation_agent.sh -- do not hand-edit):** 2026-10-18T23:50Z verdict=`verified` agent-exit=0 -- the agent reported totals for every suite. This is NOT proof -- re-derive them yourself; the agent report is never the oracle.
said "the behaviour already exists, only its test is missing — dispatch as test-only". **That was
wrong and its instruction has been deleted.** A Root Cause Agent (session key
`b25-stall-abort-path`) attacked it, and I then re-derived the mechanism myself from the code at
`9deba3ed` and HEAD. Read "The defect" before anything else.
**Route:** `data/call_implementation_agent.sh --fresh`. Confirm the `Mode: fresh session` line.

## The defect — derivable from the code alone

`runB25WorkflowRowScope` (`test/b25_workflow_row_selection.dart:270-288`) races a row's work
against the stall watchdog:

    final value = bodyWatch == null
        ? await run()
        : await Future.any<T>([run(), bodyWatch.deadline]);

When the deadline wins, the scope catches the `WalkthroughStallFailure` and maps it to
`row_stalled_inconclusive` (`:390-401`). **That mapping is correct and is reached.** The defect is
what `Future.any` does to the loser: **nothing**. A Dart future cannot be cancelled, so `run()` keeps
executing — still awaiting, still calling `tester`, still tapping — after the scope has returned.

The harness already knows this and guards exactly one symptom of it.
`integration_test/workflow_ui_evidence_test.dart:1549-1556` says the race *"never cancels the loser
-- a row whose race the deadline wins keeps executing in the background"*, and `capture` (`:252-265`)
refuses a screenshot once `finish()` has run. Nothing guards the rest. After the scope returns, the
batch drives the tester again while the loser is still driving it:

| step after the scope returns | where |
|---|---|
| `recordEvidenceEntry` (the stall IS recorded) | `:490-492` |
| `await restoreB25SurfaceAfterRowFailure(tester: …)` | `:578` |
| `await tearDownB25CommunityWalkthrough(…)` | `:591` |
| the next community's `ensureTargetInstalled` / `openEvidenceTarget(tester, …)` | `:408-409` |

Two drivers on one `WidgetTester` is the failure. Each later community's first tester call can
collide with the abandoned row, and `runB25CommunityScope` (`:404`) then records a community failure
with no rows.

**There are THREE callers of the race, and all three need the fix**:
`workflow_ui_evidence_test.dart:422` (the main community loop), `:773` (the dedicated Mosque
B17-B20 rows) and `:1238` (the B20 segment). Do not fix only the first.

## The run evidence — session-reported, so corroboration only

The `full-b25` run of 2026-10-06 (commit recorded as `9deba3ed`; the APK's build commit was never
recorded) ended `exit=1, workflows=5, b25IncompletelyTraversed=14` after
`garden-tool-giveaway` stalled to its 3m watchdog at 3m 51s. Those figures live only in ticket prose;
the run log is gone. **They are consistent with the defect above, and here is the arithmetic, checked
at `9deba3ed`:** a full run records the B12 harness entry first (`:364`); Garden is the first target
(`part15_evidence_catalog.dart`, phase `B13`); Garden's rows run `garden-event-rsvp`,
`plant-exchange-submission`, `garden-tool-loan`, **`garden-tool-giveaway`**, … So the giveaway is
**entry 5**. `workflows=5` means its stall entry was written and **nothing after it** was, while all
14 traversals stayed incomplete. That is what an abandoned row colliding with everything after it
looks like.

**The alternative, stated rather than dropped:** the Root Cause Agent proposed that the loser was
parked inside one `tester` call and the scope never returned at all. It reached that by counting the
giveaway as entry 6. With the harness entry counted, the entry total favours "the scope returned and
the batch collided with the loser". Both readings agree that a test-only fix is wrong. **The change
below is correct under both**: it stops the loser where it can be stopped and fails loudly where it
cannot.

## The change

1. **The scope must not return while its `run()` is still executing.** When the deadline wins,
   signal cancellation to the loser, then await the loser's settlement for a bounded grace period.
   Name that period as a constant whose relationship to the watchdog is stated in code, the way
   `innerWaitSafetyMargin` is (`test/walkthrough_wait.dart:35`). The loser's own error is swallowed;
   the row's reported outcome stays `row_stalled_inconclusive`.
2. **Make a polling loser unwind promptly, through ONE shared mechanism.** Every harness poll loop
   notices expiry only through `WalkthroughWaitBudget.expired` (`walkthrough_wait.dart:32`). The loops
   I count, as a floor (re-grep `budget.expired` and `WalkthroughWaitBudget(` yourself):
   `test/b25_created_instance_identity.dart:262-267`; `test/workflow_ui_test_harness.dart:257,
   1210, 1322, 2564, 2638, 2678`; plus two budgets constructed in
   `integration_test/workflow_ui_evidence_test.dart`. Prefer one seam — for example, `expired` also
   reporting true once the current row has been cancelled — over editing each loop, because a rule
   copied into seven places gets missed in the eighth. Say which seam you chose.
3. **If the loser has NOT settled within the grace period, the batch must stop, loudly.** A
   genuinely parked `await` cannot be preempted in Dart. Driving the tester on top of it produces
   fourteen communities of misleading collision failures, which is worse than one honest stop. So the
   scope's result must carry whether the loser settled. When it did not, each of the three callers
   records that row's outcome first, then ends the traversal with a diagnostic that names the row and
   says the abandoned row never settled. Put the stop/continue decision in a pure function so it can
   be unit-tested.
4. **Keep, unchanged:** the watchdog and its timeout, `innerWaitSafetyMargin`, every outcome name
   (`check_b25_status.sh` and the judge read them), the `capture`-after-`finish` guard, and the
   created-instance reader. Do not raise any timeout.

## Honesty tests — each must FAIL against today's code

Run each new test against the unmodified code first and put the verbatim failure in your reply. A
test that passes before and after proves nothing. Use injected timers and short durations; no real
three-minute waits.

- **The loser must not run after the scope returns.** A `bodyWatch` with a 50 ms timeout; a `run()`
  that awaits 300 ms and then records whether the scope has already returned. Today the scope
  returns at 50 ms and the loser runs on, so asserting "no work after the scope returned" fails.
- **A polling loser is cancelled.** A `run()` polling through a `WalkthroughWaitBudget` loop is
  stopped within about one poll interval of the deadline. The scope returns `row_stalled_inconclusive`
  with the loser settled.
- **A never-settling loser** (awaiting a `Completer` that never completes) makes the scope return
  after the grace period. The outcome is still `row_stalled_inconclusive`, the result says the loser
  did not settle, and the decision function says stop.
- **A row that completes normally is unaffected**, and the existing stall tests
  (`b25_workflow_row_scope_test.dart`, around `:728-783`) stay green and unweakened.

## Scope limit

Only `test/b25_workflow_row_selection.dart`, `test/walkthrough_wait.dart`, the three callers in
`integration_test/workflow_ui_evidence_test.dart`, and their tests. No product code, no community
JSON, nothing under `docs/references/**`. The top-level `watchWalkthroughBodyWith` race
(`walkthrough_wait.dart:258`) ends the whole run when it fires, so leave it alone. **Do not run
`flutter drive`, the capture CLI, `adb` or an emulator.** Device runs are the orchestrating
session's job. If another row or test fails while you work, record it and continue.

## Verification

- All five suites, **sequentially** (judges beside engine gives a false timeout), skip counts before
  pass counts: demo **319** (0 failed, 0 skipped), app shell **448** (+2), judges **525**, engine
  **345** (+1, BOTH Postgres credential sets), service **168** (+1, the one skip being App Access
  and **not** PostgreSQL). Without the Postgres credentials, report engine and service with their
  skip counts and say the credentials were absent. `b25_capture_prebuilt_binary_test.dart` is flaky
  about 1 run in 3 with a rotating test name; confirm a `TimeoutException` and an isolated pass
  before believing it.
- Name every test you add and the file it is in, so the demo total's movement can be accounted for.
- `flutter analyze` in `app/apps/loom_communities_demo`: **3** pre-existing issues, from the tool's
  own `N issues found` line.
- **Emit `<<<SUITES_RUN: ...>>>`.** The dispatcher refuses a reply without it; it exits 2 for a
  missing report and 3 for an infrastructure failure where the agent never ran.
- **Do not quote a completion figure.** The bar is 73 real rows and `CONFIRMED` is 0.
