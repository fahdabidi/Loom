# HARNESS — the created-instance reader must be renderer-aware

**Status:** written 2026-10-10, **NOT dispatched**.
**Route:** `data/call_implementation_agent.sh --fresh`. Confirm the `Mode: fresh session` line.
**Scoped by** `data/call_root_cause_agent.sh` (session key `b25-instance-does-not-render`). It
attacked and destroyed my framing — I had committed "instances persist and never render" as a
remote read-path defect; it is a harness checker defect. I then verified every load-bearing claim
below myself, including the key formats and the exclusions.

## Why this is the top priority

`--mode full-b25` is the **only bar-eligible capture mode** (it refuses `--communities` and
`--shards` by design). It has never completed against the live engine. The attempt on 2026-10-06
died at **5 of 83 workflows**, `exit=1`, `b25Communities=0/14`. So **no bar-eligible evidence can
be produced at all** until this is fixed, regardless of how many other walls are cleared. The bar
is 73 real rows; `CONFIRMED` is 0 and `b25Proven` is 0.

## The defect

`engineNativeInstanceIdsForTab` (`test/b25_created_instance_identity.dart:15`) builds
`prefix = 'engine-native-list-item-$tabId-'` and filters on `startsWith(prefix)` at `:19`. That key
shape has **exactly one emitter in the entire shell** — `part32_engine_native_list_surface.dart:179`
— and the file's own doc comment at `:9` says so: *"`EngineNativeListSurface` owns this key shape."*

But a tab's surface is chosen by archetype reconciliation. `_derivedRendererContractIdForTab`
(`part12_actor_identity_and_tabs.dart`, used at `:228`, `:242`, `:331`) gives a tab a **dedicated**
surface when it binds exactly one family present in
`appShellTabNativeRendererContractIdsByArchetype` (`app_shell_capabilities.dart:59-66`), which has
exactly three entries — `calendar` and `event-rsvp` → `calendar-agenda-event-detail`,
`equipment-loan` → `marketplace-browse-listing-detail` — and otherwise falls back to
`defaultAppShellTabRendererContractId` (`:69`) and the generic list.

So in Garden: `calendar` binds only `event-rsvp` → calendar surface; `marketplace` binds only
`equipment-loan` → marketplace surface; `home` binds six families → generic list. **For the first
two the wait is unsatisfiable by construction** — the instance is created, persisted and almost
certainly on screen while the harness polls 2m45s for a key that surface cannot emit. Three rows
recorded `action_succeeded_result_unverified`; `garden-tool-giveaway` stalled on the identical
condition and its watchdog **aborted `flutter drive` and all nine phases**.

Nothing caught it because the helper's only green witnesses run on list-surface tabs
(`b25_workflow_row_scope_test.dart:510` uses tab `"admin"`), the planner test has no widget tree,
and local runs use seeds rather than creation.

## The change

Make the reader compute the creation tab's reconciled renderer **the same way the shell does** —
single bound family in that three-entry map → dedicated surface, else generic list — then diff the
**matching** namespace before and after creation.

**Verified key formats, with the exclusions, which are load-bearing.** The checker demands
*exactly one* new key, so an over-broad prefix double-counts and fails just as hard as zero:

| surface | match | MUST EXCLUDE |
|---|---|---|
| calendar | `engine-native-calendar-agenda-<instanceId>-<bindingIndex>` (`part28:1308`) | `engine-native-calendar-agenda-facts-<instanceId>-<bindingIndex>` (`part28:1336`), and the `$day`-keyed `-group-` (`:1234`), `-date-` (`:1251`), `-date-entry-` (`:1276`), `-today-` (`:1283`) |
| marketplace | `marketplace-listing-<instanceId>` (`part36:357`) | `marketplace-listing-tap-<instanceId>` (`part36:351`) |
| generic list | `engine-native-list-item-<tabId>-<instanceId>-<bindingIndex>` (`part32:179`) | — |
| table family | `workflow-table-row-<groupId>-<instanceId>-<bindingIndex>` (`part32:551`, `:564`) | — **currently missed entirely**; add it |

**Do not match these by substring.** Parse the instance id out of the key positionally, the way the
current helper does with `substring(prefix.length)`, and reject any key whose segment after the
prefix is a `$day` or begins `facts-`/`tap-`. This project has a standing rule against substring
matching on product vocabulary and this is the same hazard in widget keys.

**Add a conformance test asserting parity with the map**, so the harness's copy of the
reconciliation rule cannot drift from `appShellTabNativeRendererContractIdsByArchetype`. A
hand-copied rule that silently diverges is how this class recurs; the test should fail if an entry
is added, removed or re-pointed.

## Honesty tests — each must be able to FAIL

- **A widget test per surface**: render a tab whose single bound family is `event-rsvp`, create an
  instance, and require the reader to find exactly one new id. Same for `equipment-loan`
  (marketplace), for a multi-family tab (generic list), and for a `table`-family binding.
- **Run each against the current reader first and record the verbatim failure** — the calendar and
  marketplace cases must fail today with 0 candidates. A test that passes before and after proves
  nothing.
- **Assert the exclusions explicitly**: a calendar instance that also renders a `facts-` row must
  still yield exactly **one** id, not two; a marketplace instance must not be double-counted by its
  `-tap-` key.
- **Keep the conformance test honest**: temporarily add a fourth entry to the archetype map and
  confirm the parity test goes red, then revert.

## Scope limit

Only the created-instance reader, its renderer resolution, and their tests. Do **not** change the
shell's key formats, the reconciliation function, the arrangement planner, the readGuard
disjunction, or any product code — **this is a test-side fix**. If another row fails while you
work, record its outcome and continue rather than aborting the batch.

**Separable and NOT in scope:** one row's stall still aborts the whole `full-b25` batch. That is the
"fail fast must not take the batch down with it" shape and deserves its own ticket; fixing the
reader removes today's trigger but not the fragility.

**Also NOT in scope, and deliberately so:** the `plant-exchange-submission` row on `home` fails
despite `home` emitting the right namespace. The scoping proposed a role-alias prefill mismatch and
asked for one query to confirm; **the query refutes it** — that row's `ownerFanId` and
`created_by_fan_id` are both `fan-garden-member-1`, and the event row's `coordinatorFanId` likewise
equals its creator. So do not write the 7-site `resolveEngineFanId` change: it would fix something a
measurement says is not broken. That row needs instrumentation, separately.

## Expected measurement

Rebuild the APK, install with `adb install -r -g`, verify `POST_NOTIFICATIONS granted=true` **on the
device**, then run `--mode full-b25` with `--evidence-root` at a **scratch** path — never canonical
on a first attempt, because a partial run overwrites committed manifests. Success is `full-b25`
getting past Garden's creation rows: `workflows` well above 5, and the three
`action_succeeded_result_unverified` rows plus the `garden-tool-giveaway` stall resolving. **Do not
quote a completion figure** — `targeted-precheck` and scratch-root output are
`commitEligible: false`, `CONFIRMED` is 0 and `b25Proven` is 0.

## Verification

- All five suites, **sequentially** (judges beside engine gives a false timeout), skip counts before
  pass counts: demo **312** (0 failed, 0 skipped), app shell **448** (+2), judges **525**, engine
  **345** (+1, BOTH Postgres credential sets), service **168** (+1, the one skip being App Access and
  **not** PostgreSQL). `b25_capture_prebuilt_binary_test.dart` is flaky about 1 run in 3 with a
  rotating test name; confirm a `TimeoutException` and an isolated pass before believing it.
- Account for every total that moves: the declared-count delta plus an offset of **8** has predicted
  the demo total exactly eleven times.
- `flutter analyze` on the demo app: **3** pre-existing issues, from the tool's own
  `N issues found` line, with the working directory stated.
- **Emit `<<<SUITES_RUN: ...>>>`.** The dispatcher refuses a reply without it and exits 2;
  `NOT_RUN(reason)` is a correct entry for anything you genuinely could not run.
