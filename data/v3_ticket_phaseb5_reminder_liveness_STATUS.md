# Ticket status: Phase B.5 reminder liveness

## Change applied
Status: blocked

## How liveness was proven
Added an engine-level test at
`app/packages/core/loom_workflow_engine/test/v3_milestone_phaseb5_ballot_reminder_liveness_test.dart`.
It registers a `tournament-ballot`-shaped state machine with the frozen JSON's
`subtractHours(deadline, ...)` and `isPast(dueAt)` formulas, constructs
`LocalWorkflowEngineApi` with a mutable injected `clock`, and seeds one ballot
with a fixed deadline and the real `one-day` (24-hour) reminder offset. The
first query, before `dueAt`, asserts `isExpiringSoon == false`; after advancing
only the clock just past the same computed `dueAt`, the second query asserts
`isExpiringSoon == true` and the same `dueAt`/instance remain intact.

## Verification
dart analyze: unavailable in this sandbox. `dart analyze packages/core/loom_workflow_engine`
exited before analysis with `WSL ... UtilBindVsockAnyPort:309: socket failed 1`.
Test suite: pass count unavailable. The direct test and full `dart test` suite
both exited before test discovery with the same WSL vsock socket error; no test
assertions ran and no `X/Y` result was produced. Flutter also fails immediately
with the same socket error, so the required independent verification must be
run outside this sandbox.

## Commit
Commit hash: pending until the controlled commit completes.
