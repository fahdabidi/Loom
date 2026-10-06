# HARNESS — make the `actorEqualsField` direction test able to fail

**Status:** written 2026-10-05, **NOT dispatched**. Small and self-contained.
**Route:** `data/call_implementation_agent.sh --fresh`. Confirm the `Mode: fresh session` line.

## The finding — a test that passes against an implementation ignoring guards

Found by A/B after `b11a27c6`, not by reading. `b25FanIdFieldValues`
(`b25_remote_arrangement.dart`) resolves a `fanId` field through three branches:

| branch | condition | value |
|---|---|---|
| 1 | an `actorEqualsField` guard names the scalar field, or `actorInList(present: true)` names the list field | `{actorFanId}` |
| 2 | a `formula` guard names the field alongside `$actor` | **throws** `fanIdFieldRequiresDifferentMember` |
| 3 | nothing names the field | `{actorFanId}` |

**Branches 1 and 3 return the identical value.** So the test
*"a scalar fanId field guarded by `actorEqualsField` resolves to the acting fan"* cannot tell the
two apart: it passes whether the guard was honoured or the resolver never looked at guards at all.

**Measured, not inferred.** Mutating branch 1's condition so it can never match
(`guard.actorEqualsField?.key == "__never__"`) left **all 24 tests passing**, exit 0. The mutation
was confirmed applied, and the source was restored and `cmp`-verified byte-identical afterwards.

**The behaviour is correct and is NOT what this ticket changes.** The doc comment states the
unconstrained case deliberately uses the acting fan "as a safe, already-real value rather than
guessing a third identity nobody asked for", and the shipped Garden package agrees — its create
action carries `"prefill": { "coordinatorFanId": "$actor" }`. **Do not change the resolution
logic.** The defect is that a correct implementation and a guard-blind one are indistinguishable to
the suite.

## The change — make branch 1 observable, without changing what it returns

Two options; **prefer the first** and say which you chose and why.

1. **Return the provenance alongside the value.** Have the resolver record, per field, *which*
   branch decided it — e.g. a parallel map of field to an enum (`selfGuarded`, `unconstrained`), or
   a small result record. Then the direction test asserts the **provenance** as well as the value,
   and the mutation above fails it immediately. This also makes the planner's own reason strings
   able to say *why* a field was filled, which is useful on a device run.
2. **Assert the distinguishing consequence instead.** If provenance is genuinely unwanted in the
   model, find an observable the two branches differ on and assert that. If there is none, say so
   plainly and fall back to option 1 rather than leaving the test as it is.

## Honesty test — this ticket is only done when the mutation FAILS

- **Re-run the exact A/B.** Change branch 1's condition so it can never match; the direction test
  **must now fail**. Restore and `cmp`-verify byte-identical. Record the verbatim before/after
  counts in your reply — "24 passed" before the fix and a named failure after it.
- **Do the same for the list branch**: mutate `actorInList(present: true)` so it cannot match, and
  confirm the `fanId[]` direction test fails.
- **Keep every currently-green test green**, in particular the two refusals (`a required field with
  no seed value is out of scope`, and the unsupported-type refusal that keeps `image` out) and the
  formula-throw test.
- **Do not weaken any assertion to achieve this.** The point is a strictly stronger test.

## Scope limit

Touch only the fanId direction resolution and its tests. Do **not** change the three resolution
outcomes, the readGuard disjunction, `url`/`list` arrangement, or any other arrangement class. If
something else fails while you work, record it and continue rather than aborting.

## Verification

- All five suites, **sequentially**, skip counts before pass counts: demo **310** (0 failed,
  0 skipped), app shell **448** (+2), judges **525**, engine **345** (+1, BOTH Postgres credential
  sets), service **168** (+1, the one skip being App Access and **not** PostgreSQL).
  `b25_capture_prebuilt_binary_test.dart` is flaky about 1 run in 3 with a rotating test name;
  confirm a `TimeoutException` and an isolated pass before believing it.
- `flutter analyze` on the demo app: **3** pre-existing issues, from the tool's own
  `N issues found` line, with the working directory stated.
- **Emit `<<<SUITES_RUN: ...>>>`.** The dispatcher refuses a reply without it and exits 2;
  `NOT_RUN(reason)` is a correct and expected entry for anything you genuinely could not run.
