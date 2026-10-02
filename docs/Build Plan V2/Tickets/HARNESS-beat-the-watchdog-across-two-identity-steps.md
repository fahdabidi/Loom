# HARNESS — beat the watchdog across the two-identity steps, and stop a stall aborting the batch

**Status:** written 2026-10-02, **NOT dispatched**.
**Route:** `data/call_implementation_agent.sh --fresh`. Confirm the `Mode: fresh session` line.
**Follows:** `7e263a94` (two-identity arrangement), measured on-device by me the same day.
**Evidence:** Garden precheck against a scratch evidence root. `exit=1`, `workflows=1`,
`b25Proven=0/0`, `b25NonProvenRows=[]`, `screenshots=3/3`.

## What happened, measured

The run reached Garden's first row and threw:

    WalkthroughStallFailure: a step could not proceed within its bounded wait
      (3m 0s elapsed, limit 3m 0s).
      Last completed step: phase B12, workflow workflow-ui-evidence-harness
      Attempted step:  signing in as garden-member (phase B13, Garden Club, garden-event-rsvp)
      Waiting for:     community content to load after signing in as garden-member

**The backend was healthy throughout** — the `LOOM_BINDING` lines immediately before the throw are
`service=workflow-engine mode=remote ... outcome=ok status=200`, four in the last second. Nothing
failed; a wait expired.

## Diagnosis — and it is NOT the equal-deadline race it resembles

`3m 0s elapsed, limit 3m 0s` is the signature of the documented equal-deadline race, and I read it
that way first. **Reading the code disproves that**, so do not repeat my error:

- `WalkthroughWaitBudget.defaultTimeout` = 3m, `innerWaitSafetyMargin` = 15s, and
  `defaultInnerWaitTimeout = defaultTimeout - margin` = 2m45s (`test/walkthrough_wait.dart:29-41`).
- Inner waits default to **2m45s** correctly (`:20`), and the three harness call sites all pass
  `defaultInnerWaitTimeout` (`workflow_ui_test_harness.dart:2251, :2322, :2362`).
- The one site using `defaultTimeout` is `WalkthroughBodyWatch` itself (`:132`) — **the watchdog**,
  where 3m is correct by definition.

So the budgets are right and the watchdog fired correctly. Its own doc comment states what it
measures: *"the timer restarts on each beat, so the bound measures a single no-progress gap rather
than the total runtime"*, and *"call `beat` whenever the body completes a step or crosses a phase
boundary"*.

**The actual cause: `7e263a94` added 306 lines to the evidence test and ZERO `beat()` calls.**
Verified: `git show 7e263a94 | grep -cE '^\+.*\.beat\('` returns **0**, against six pre-existing beat
sites (`:565, :1394, :2101, :3495, :4579, :4755`). The two-identity flow — resolve both fan ids,
authenticate A, create, re-authenticate B, act — is several live Keycloak round trips and a form
submission inside **one un-beaten stretch**. Each inner wait is individually under budget; their sum
is not, and the watchdog is measuring the sum because nothing told it progress was being made.

## Change 1 — beat at the new step boundaries

Add `bodyWatch.beat(...)` at each boundary the two-identity flow introduces, naming the step that
just completed: after resolving the fan ids, after authenticating the creator, after the instance is
created and its id captured, and after re-authenticating the actor. **Each is a completed step by the
watchdog's own definition**, so this is using the mechanism as designed rather than widening a bound.

**Do not raise `defaultTimeout` to make this go away.** The watchdog exists to catch a body that has
genuinely stopped; lengthening it degrades that for every row in order to accommodate work that
should simply be reporting progress.

## Change 2 — a stall must not abort the batch

`b25NonProvenRows=[]` and `workflows=1` show the throw took down all remaining rows. The previous
run recorded **six** rows' outcomes and completed. One slow row now costs every row behind it.

**Do:** catch the stall at the row boundary, record **that row's** outcome with the stall's full
diagnostic text, and **continue to the next row**. Give it its own outcome name — do not reuse
`primary_action_unavailable` (which means the action legitimately did not render) or
`blocked_by_arrangement` (which means the row could not be set up). A row that stalled was *attempted
and inconclusive*, which is a third fact, and it must never be counted as evidence about the product.

**Assert the continuation in a test.** "It kept going" is exactly the property a single-row fixture
cannot show, and this is the second time in this programme that a diagnostic improvement took the
batch down with it.

## Do not

- **Do not touch the budget constants.** They are correct; the defect is missing progress reporting.
- **Do not weaken or delete the stall instrumentation.** It is what produced this diagnosis in one
  run, naming the exact attempted step and what was awaited.
- **Do not run a capture against the canonical evidence root.** `--mode targeted-precheck` overwrites
  manifests for phases it did not run (a separate open defect). Pass `--evidence-root` at a scratch
  path — I did, and the canonical tree came back with **0** modified files, so this works.
- **Do not touch `docs/references/**`** — hard-locked. No package edits.

## Verification

- A test that **fails before and passes after** for Change 2: a row whose step stalls must record its
  own outcome and the run must proceed to the next row. Run it against the un-fixed code first.
- For Change 1, assert the beat happens at each new boundary — a test that drives the two-identity
  path with a short watchdog and a slow auth stub should now survive, and should fail without the
  beats.
- All five suites, skip counts before pass counts: demo **281** (0 failed, 0 skipped), app shell
  **448** (+2), judges **525** (0 failed), engine **345** (+1, both credential sets), service **168**
  (+1, the one skip being the App Access one and **not** PostgreSQL). All five measured green by me on
  2026-10-02 at `7e263a94`, **run sequentially** — running judges beside the engine produces a false
  timeout, so run them one at a time.
- `flutter analyze` on the demo app: **3** pre-existing issues; take the count from flutter's own
  `N issues found` line.
- **Report what you actually ran.** Five consecutive dispatches in this programme have exited status 0
  reporting only their intent and no suite total. If you cannot finish verification, say which parts
  you did not do.
