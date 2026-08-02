# Ticket status: CAL.Notify2.9 fix5

## Change applied
Status: done

## Design notes
Temporary CALQ instrumentation was fully removed. `part28_engine_native_calendar_surface.dart`,
`local_workflow_engine_api.dart`, and `database.dart` have no remaining CALQ helpers, calls, or
trace-only identity plumbing; `git diff e9b706b --` for each of those files is empty. The two
engine-package files are therefore restored exactly to their `e9b706b` state.

The controlled reminder harness now retains the first successfully delegated Calendar page,
completes the held freshness completer synchronously with that page, and clears the held field.
Both controlled tests ensure the action is visible before tapping and poll the foreground completer's
`isCompleted` flag with bounded real-async yields and widget-test pumps, including queue/transition
state in the timeout failure.

The A8 `_tapAction` and A11 `_tapRsvpAction` helpers now poll the expected selected/result UI state.
A8 `_settleMutation` polls the persisted instance location or cancellation state; the inline edit,
recurring-event, and scroll-action settling tails poll their expected engine/UI result. A11 event
creation polls for the created event row. Every polling loop is bounded, alternates a short
`tester.runAsync` real-async yield with `tester.pump()`, and reports its last observed state instead
of asserting on stale data.

## Verification
Scenario 1 (isolated controlled test): blocked before test execution; Flutter's test runner could
not create its localhost server socket (`Operation not permitted`, `127.0.0.1`, port `0`).
Scenario 2 (isolated real-engine test): blocked by the same localhost server-socket restriction.
Full reminder test file: not run after the isolated runner blocker.
Full a8 test file: not run after the isolated runner blocker.
Full a11 test file: not run after the isolated runner blocker.
Full loom_communities_app_shell suite: before 157/167 (10 failures diagnosed by STATUS4); after not
run because the Flutter test runner was blocked.
Full loom_workflow_engine suite: not run; expected unaffected baseline is 192/192.
flutter analyze (both packages): App Shell clean (`No issues found`); Workflow Engine clean relative
to baseline with 21 pre-existing info hints and 0 errors. The direct Flutter analyze invocation used
`--no-pub` through a writable temporary SDK mirror because the installed SDK cache is read-only.

## Commit
Commit hash: pending until the one requested commit is created; the verification blocker is the
Flutter test runner's inability to bind localhost in this sandbox.
