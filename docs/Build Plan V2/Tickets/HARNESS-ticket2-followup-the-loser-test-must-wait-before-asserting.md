# HARNESS — follow-up: the "scope does not return while run() executes" test must be able to fail

**Status:** written 2026-10-18, **NOT dispatched**. A one-test follow-up to
`HARNESS-one-row-stall-must-not-abort-the-full-b25-batch.md`, whose work is **in the working tree
and NOT yet committed**. Leave every other uncommitted change exactly as it is. Do not revert,
reformat or "tidy" any of it.
**Route:** `data/call_implementation_agent.sh --fresh`. Confirm the `Mode: fresh session` line.

## The defect in one test

`app/apps/loom_communities_demo/test/b25_workflow_row_scope_test.dart`, group
`an abandoned row stops running before the batch continues`, test
`the scope does not return while its run() is still executing`.

Its `run()` waits 300 ms and then sets `ranAfterReturn` if `scopeReturned` is already true. The
test sets `scopeReturned = true` after the scope returns and then **immediately** asserts
`ranAfterReturn` is false. Against a scope that returns at the 50 ms deadline without waiting for
the loser, the loser has not woken yet at that moment, so the flag is still false and **the test
passes**.

**Measured, not inferred.** I removed the settle wait from `runB25WorkflowRowScope`
(`test/b25_workflow_row_selection.dart`, the line `await runFuture.timeout(grace);`) so the scope
returns as soon as the deadline fires. That is exactly the behaviour this test is named for, and
**the test stayed green**. Only `a never-settling loser returns after the grace period and says stop`
went red. The source was restored and checked byte-identical afterwards.

## The change

In that one test, after `scopeReturned = true;` and **before** the `ranAfterReturn` expectation,
wait long enough for the loser to have woken if it is still running: at least 400 ms, more than its
300 ms delay. Keep every existing expectation in the test, unchanged.

Do **not** change `runB25WorkflowRowScope`, `walkthrough_wait.dart`, the callers in
`integration_test/workflow_ui_evidence_test.dart`, or any other test. They are verified.

## Honesty test — this is done only when the mutation FAILS the test

1. Apply exactly that mutation (comment out `await runFuture.timeout(grace);`) and run
   `flutter test test/b25_workflow_row_scope_test.dart`. The test above **must now fail**, with
   `ranAfterReturn` reported as true. Put the verbatim failure in your reply.
2. Restore the line and confirm the source is byte-identical to before (`cmp` against a copy you
   took first). Then run the file again: all tests green.

## Scope limit

Only that one test in `test/b25_workflow_row_scope_test.dart`. No product code, no other test, no
community JSON, nothing under `docs/references/**`. Do not run `flutter drive`, the capture CLI,
`adb` or an emulator.

## Verification

- All five suites, **sequentially**, skip counts before pass counts. Recorded baselines: demo
  **319**, app shell **448** (+2), judges **525**, engine **345** (+1) and service **168** (+1),
  the last two with BOTH Postgres credential sets. The uncommitted ticket-2 work adds 5 demo tests
  and this change adds none, so expect the demo suite at 324 (0 failed, 0 skipped). Without those credentials, report engine and service with their
  skip counts and say the credentials were absent.
- `flutter analyze` in `app/apps/loom_communities_demo`: **3** pre-existing issues, from the tool's
  own `N issues found` line.
- **Emit `<<<SUITES_RUN: ...>>>`.** The dispatcher refuses a reply without it.
