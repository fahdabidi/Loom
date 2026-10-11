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

## VERIFIED ENUMERATION 2026-10-10 — this ticket originally named FOUR namespaces and there are at least NINE, in seven files

**I undercounted my own population, which is the exact failure this project records** ("an
undercounted population is how a fix lands on some instances of a class and not the rest"). Swept by
grepping every `ValueKey` in the shell's `lib/` whose template carries an instance id at card or row
level. Verified templates, each read from its own line:

| Surface / card | Key template | Site |
|---|---|---|
| engine-native list | `engine-native-list-item-${tabId}-${instanceId}-${bindingIndex}` | `part32:179` |
| workflow table detail | `workflow-table-detail-card-${instanceId}` | `part32:445` |
| generic instance card | `generic-instance-card-${instanceId}` | `part26:471` |
| calendar / event-rsvp | `event-rsvp-card-${instanceId}` | `part28:2690` |
| marketplace listing | `marketplace-listing-${instanceId}` | `part36:357` |
| marketplace detail | `marketplace-detail-card-${instanceId}` | `part36:216` |
| vote poll | `votepoll-card-${instanceId}` | `part35:324` |
| vote poll attendance | `votepoll-attendance-card-${instanceId}` | `part35:243` |
| notification rows (×3) | `notification-{bell,dedicated,fixed}-row-${instanceId}` | `notification_bell.dart:237`, `notification_dedicated_tab.dart:266`, `notification_fixed_card.dart:234` |

## AND THE CONSTRAINT THAT CHANGES THE FIX: only ONE of those nine carries the tab id

`engineNativeInstanceIdsForTab(tester, {required String tabId})` filters on
`'engine-native-list-item-$tabId-'`. **Every other namespace above is keyed by `instanceId` alone —
the tab is simply not in the key.** So a "renderer-aware" reader *cannot* keep its per-tab filter for
eight of the nine surfaces, and an implementation that tries to will find nothing and look exactly
like today's bug.

**Decide this deliberately and say which you chose, with the reason:**

- **Rely on one tab being on screen at a time** and drop the tab filter for the non-list namespaces.
  This is probably correct, because the walkthrough navigates to a tab before reading — but it is an
  assumption about the harness's own navigation, so **assert it** rather than leaving it implicit: if
  two tabs' cards are ever simultaneously mounted, this silently reads the wrong instance, which is
  the "evidence wrong in the one field nobody re-reads" shape.
- **Or scope the search to the rendered tab's subtree** (`find.descendant` from the tab surface),
  which keeps the per-tab guarantee and does not depend on that assumption. Prefer this if the tab
  surface has a stable key.

**Do not widen the prefix match into something that could match a sub-element.** Several of these
files also emit `*-detail-name-`, `*-list-field-`, `*-detail-close-`, `*-attendees-`, `*-capacity-bar-`
and `*-action-borrow-` keys carrying the same instance id, so a loose `contains`-style match would
count one card many times, or match a control rather than a card. This project's rule against
substring matching of product vocabulary applies to widget keys too: match a **template**, anchored,
not a fragment.

**The list namespace's trailing binding index is load-bearing and must be preserved.** Its decoder
strips the final `-N` component precisely so instance ids may contain dashes (see the existing
doc comment). The eight instance-id-only namespaces have **no** trailing component, so they must not
go through that same stripping — doing so would silently truncate every id at its last dash. **That
is the single most likely way to get this fix subtly wrong**, and it fails in a way that still
returns a plausible-looking id.

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



## PROVENANCE OF THE EVIDENCE IN THIS TICKET — checked 2026-10-10, and the two halves are NOT equally solid

Everything on the bar now waits on this ticket, so I checked which of its claims can be re-derived
and which cannot. **They split cleanly, and the split is worth knowing before anyone acts.**

**VERIFIED, re-derivable at any time from the code:** the reader recognises exactly one widget-key
namespace (`engine-native-list-item-$tabId-`, `b25_created_instance_identity.dart:15`), while **nine**
namespaces across seven files emit an instance-identifying card key — enumerated with their line
numbers in the section above. Both call sites use the reader symmetrically, and the uniqueness guard
already exists. **That is the defect, and it stands on its own.**

**NOT independently verifiable — session-reported, with no committed source:** the run figures
*"died at 5 of 83 workflows, `exit=1`, `b25Communities=0/14`"*. I searched the committed evidence for
them and found **nothing**: zero files under `docs/Build Plan V2/Evidence` record 83 workflows.
**Controlled, so that zero is real** — evidence files do carry `workflows=` lines, four of them saying
`workflows=1` and one `workflows=0`, so the pattern matches and the corpus simply has no 83. The
newest file in `Evidence/B25` by modification time is a **2026-08-25** `b25-capture-progress.json`
from `targeted-precheck`, whose `evidenceRoot` points at `C:\LoomWin` — a checkout path not in use
here — so it is 46 days stale and describes a different run entirely.

**Why this does not weaken the ticket, and what it does change.** The fix is justified by the code
claim alone, which is why the two are separated above. What the missing provenance costs is the
*expected measurement*: nobody can confirm afterwards that the run moved from 5 to 83, because
there is no committed before-figure to compare against. **So the first `full-b25` after this fix must
commit its own run record** — the manifest and the workflow count — or the next person will be in
exactly this position again. This project already records that `*.png` is gitignored and only a
committed manifest is durable; the run-level counters decay the same way, and that is the half the
rule does not currently name.

## THE CALLERS, READ 2026-10-10 — the fix is NARROWER and SAFER than it looks, and one message needs updating

Swept every reference before dispatch, because widening a reader can break a caller that depended on
its narrowness. **It cannot here, and the reason is worth knowing rather than assuming.**

**Six references, of which two are real call sites** — `integration_test/workflow_ui_evidence_test.dart:5422`
and `:5734` — plus the declaration, its internal use at `b25_created_instance_identity.dart:56`, and
its own test file.

**Both call sites use the reader SYMMETRICALLY**, in a before/after diff: snapshot
`existingInstanceIds`, tap submit, then `waitForCreatedEngineNativeInstanceId(..., existingInstanceIds: …)`,
which polls the **same** function and takes the set difference. So widening one function widens both
sides of the comparison at once — there is no way for the snapshot and the poll to disagree about
which namespaces count. **That is what makes this a single-function change.**

**And the ambiguity risk I went looking for is already handled — do NOT rebuild it.** With 8 of the 9
namespaces carrying no tab id, the diff can in principle span any mounted surface, so I expected to
have to ask for a uniqueness assertion. `b25_created_instance_identity.dart:60-78` already has one,
and a good one: it returns only when `candidateIds.length == 1`, keeps polling so a transient
two-candidate state resolves rather than failing instantly, and on expiry throws naming the **count
and every candidate, sorted**. Its own doc comment states the contract — *"accepts exactly one new
identity. Zero or multiple candidates remain loud result-verification failures"*. **So a widened
reader cannot silently attribute the wrong instance id; it can only fail loudly when genuinely
ambiguous.**

**The one thing that DOES need changing, and it is easy to miss:** that failure message currently
reads *"exactly one newly rendered engine-native **list** key on tab \"$tabId\""*. After this fix it
will fire for nine namespaces, eight of which are not the list surface and carry no tab at all, so
the message would misdescribe its own failure — a stale specific in a diagnostic, which this project
records as worse than a vague one. **Update the wording along with the reader**, and keep it naming
the candidates.

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


## CAPTURE READINESS, MEASURED 2026-10-10 — three gaps to close BEFORE the verifying run

This ticket's measurement step is a capture run, so I audited the five Windows prerequisites now
rather than discovering them mid-run. **Two are fine, three are not**, and each of the three has
cost a run before.

| # | Prerequisite | State |
|---|---|---|
| 1 | `cd <repo>/app` | ✅ present |
| 2 | `flutter` on PATH (`C:\Android\flutter\bin`) | ✅ binary present |
| 3 | `adb` on PATH (`C:\Android\Sdk\platform-tools`) | ✅ binary present |
| 4 | **`ANDROID_SDK_ROOT=C:\Android\Sdk`** | ⛔ **UNSET** — the directory exists, the variable does not |
| 5 | instrumented APK installed `-r -g` | ⛔ **no instrumented APK, and nothing installed** |
| — | emulator alive | ✅ `emulator-5554 device` |

**Gap 4 is the documented killer.** `b25_device_dialog_guard.dart` reads `ANDROID_SDK_ROOT` then
`ANDROID_HOME` then bare `adb`; with `flutter` and `adb` on PATH but neither variable set, a run
binds remote, launches, emits real telemetry, reaches the first screenshot and **then** throws
`Bad state: Unable to start Android Debug Bridge` having written nothing. Export it before running.

**Gap 5 is two problems, not one.** The newest APK in the tree is **2026-08-11** — 60 days old — and
it is the **plain debug** build, not an instrumented one; this project records that those are
different builds with different entrypoints, so there is effectively **no instrumented APK at all**.
And `pm list packages` returns **0** matches for `com.example.loom_communities_demo`, so **nothing is
installed on the device**. That means `POST_NOTIFICATIONS` cannot even be queried yet, and
`adb install -r -g` is mandatory rather than a precaution — the permission will be granted fresh by
that install, which is the state the capture needs.

**So "the emulator is ready" would have been wrong**: it is running and empty. Build the instrumented
APK at HEAD on the VM (~5 minutes there; Windows cannot build it without Developer Mode), transfer,
`install -r -g`, then **verify on the device** with `dumpsys package … | grep POST_NOTIFICATIONS`
showing `granted=true` rather than trusting the installer's `Success`. And point `--evidence-root`
at a scratch path.



### THE DISPATCH HOST'S CHECKOUT — a sixth prerequisite, and the readiness audit above MISSED it

Found 2026-10-10, the tick after I declared no unknown prerequisites remained. The audit above covers
the **Windows** capture prerequisites; the **dispatch** prerequisite is that the VM holds the ticket
you are dispatching. It did not: the VM was **15 commits behind**, clean tree, so every rescoped
ticket on it was the **pre-retraction** version — including a copy of
`HARNESS-one-row-stall-…` missing its entire `⛔ RESCOPED` section, whose body therefore still
prescribed implementing behaviour that already exists in the code.

**This is not the usual wrong-checkout failure.** There is no false green: the agent reads a
withdrawn instruction and correctly carries it out. And the suites were never at risk — those 15
commits touched **zero `.dart` files** (6 `.md`, 2 `.txt`, 1 `.sh`), so totals would have matched
exactly. What was stale was everything the agent reads as an **instruction**, plus
`check_ticket_baselines.sh` (the VM held the version my own prose had broken) and both baseline
records.

**Before any dispatch, two lines:**

    ssh loom-vm 'cd ~/Loom && git log --oneline -1 && git status --short | wc -l'   # vs local HEAD
    ssh loom-vm 'cd ~/Loom && git pull --ff-only'                                   # if behind and CLEAN

Done for this ticket: the VM is at `ae8e6bad`, tree clean, the `⛔ RESCOPED` section present, and the
gate's md5 now matches HEAD. **Re-check it anyway if any commit lands between now and the dispatch**
— the gap reopens every time I commit on Windows, which during this work is constantly.

### Backend reachability FROM THE DEVICE — verified 2026-10-10 with a control

The remaining unknown in the readiness audit was whether the emulator can route to the cluster at
all; the capture must bind remote, and this project records a whole class of misdiagnosis when it
cannot ("a failed call is not evidence that a service is unreachable"). **All four NodePorts answer
from the device**, probed with `toybox nc` over `adb shell`:

| service | port | from the device |
|---|---|---|
| app-access | 30080 | REACHABLE |
| fan-passport | 30081 | REACHABLE |
| keycloak | 30082 | REACHABLE |
| workflow-service | 30083 | REACHABLE |

**Controlled, so "reachable" is a measurement rather than a probe that always succeeds:** port
**30999** on the same host came back **refused**. Without that, four reachable results would prove
only that the probe returns success.

**And from Windows the services are not merely accepting TCP but serving:** app-access returns
**HTTP 401** and workflow-service **404** — an auth demand and a wrong-path answer respectively, both
of which require a running service, unlike a bare connect.

**So the readiness position is now complete:** emulator alive, all four services reachable and
answering, `flutter` and `adb` present; `ANDROID_SDK_ROOT` to export at run time; and the
instrumented APK deliberately left unbuilt until after the dispatch batch, per the note above. **No
unknown prerequisites remain** — which matters because this project records two consecutive
walkthroughs lost to infrastructure that one cheap check beforehand would have caught.

### DO NOT PRE-BUILD THE APK — and do not rebuild between tickets. Measured 2026-10-10.

I could have closed gap 5 before auth returned: `ssh` and `flutter` work, and only the Claude CLI
auth is down, so a VM build is available right now. **It would have been wasted, and the reason
generalises to the whole dispatch batch.**

`integration_test/workflow_ui_evidence_test.dart` pulls **10 files from `../test/`** into the
instrumented build:
`b25_visible_postcondition`, `b25_actor_audience_resolution`, **`b25_created_instance_identity`**,
`b25_formula_guard_reachability`, `b25_product_doc_role_resolution`, **`b25_remote_arrangement`**,
`b25_shipped_state_postcondition`, **`b25_workflow_row_selection`**, `workflow_ui_test_harness`,
`walkthrough_wait`.

**Every one of the five queued tickets invalidates that binary**, which is the part worth knowing
before sequencing any of them:

| ticket | touches | effect on the APK |
|---|---|---|
| this one | `b25_created_instance_identity.dart` | **imported** — invalidates |
| direction test | `b25_remote_arrangement.dart` | **imported** — invalidates |
| one-row stall (test-only) | `b25_workflow_row_selection.dart` | **imported** — invalidates |
| precheck manifests | `test_driver/workflow_ui_evidence_writer.dart` | driver half of the same build |
| `reminderAt` | `loom_workflow_engine` | app half of the same build |

**So build the instrumented APK ONCE, after the whole batch lands — not before it, and not between
tickets.** Each build is ~5 minutes on the VM plus a ~157 MB transfer, so rebuilding per ticket costs
five of each for no gain, and pre-building costs one that the first dispatch throws away.

**One nuance about the standing loop prompt:** it says to rebuild the APK immediately after
committing a fix. That was correct when there was **one** fix in flight; with five queued it becomes
the per-ticket rebuild this note argues against. The instruction is not wrong, it is scoped to a
single-fix cadence.

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

## RECORD THE RUN, NOT JUST ITS TOTAL — four fields, and three of them have never been written down

Audited 2026-10-10 across all nine recorded device runs. **Every one of them used a scratch
`--evidence-root`, which is correct, and not one committed a manifest** — `git show --stat` for
`e0536500`, `28224656`, `b11a27c6` and `9deba3ed` each touch **zero** files under `Evidence/`. The
run logs lived in the VM's `/tmp`, which a reboot cleared. So every per-row composition this
project has ever measured on a device is **gone**, and only scalar totals survive, in ticket prose.

**The concrete cost, which lands on this ticket's own verifying run.** `row_execution_failed` went
**14 → 10** across `9deba3ed`. Nobody can say whether the remaining 10 are a subset of the 14, or
ten different rows with the first set fixed and new ones broken — so a run that comes back at 10
again is indistinguishable from no progress *and* from a complete swap. The three Garden
`No element` rows and the picker stall that the loop brief names as the next targets were measured
over **17** workflows; traversal is now **83**, and whether those four are still among the failures
has never been re-measured.

**And the denominators were never comparable.** `b25Proven` appears in the tickets as 0/0, 0/1,
0/3, 0/5, 0/7, 0/16 and 1/82 — seven distinct denominators, differing partly by improved reach and partly by
run scope (Garden-only versus Garden/Book, different `--phases`), **which was never recorded for any
run**. The sharpest instance: `workflows` fell 8 (`61a2e01b`) → 4 (`c88b9b67`), and those two runs
are presented in a ticket as a before/after on `b25RowExecutionFailed` (6 → 0). That may well be
right; it cannot be *checked*, because neither run's scope was written down. Unverifiable, not wrong.

**So this run records four fields, in a tracked file, in the same sitting:**

1. **COMMIT** — the HEAD the instrumented APK was *built* from, not the tree it ran against. This
   project has already attributed one run's log lines to a different binary; two builds of the same
   app can differ in the one way that matters.
2. **SCOPE** — verbatim `--mode`, `--phases`, `--communities`, `--evidence-root`. Without it the
   totals are not comparable to anything, including themselves on a later run.
3. **COMPOSITION** — every non-proven row by `workflowId` **and** outcome. Not a bucket count. A
   count tells you a number moved; only the row list tells you which, and this project's own rule is
   that a total that moves needs its reason named.
4. **TOTALS** — each with its denominator as part of the figure (`1/82`, never `1`), because
   `b25Proven` is a per-run ratio and a bare numerator is malformed.

`docs/Build Plan V2/Tools/code/device_run_baselines.txt` holds this frame with every surviving
figure already in it and the unrecorded columns marked `unrecorded` rather than left blank. Fill
your run's row there.

**Keep the scratch evidence root.** The mode is `commitEligible: false` and the default root
destroys canonical manifests for phases it never ran — that part is right and must not change. What
changes is that the *result* stops living only there. The one composition that did survive — the
45-row `blocked_by_arrangement` decomposition at `e0536500` — survived for exactly one reason: it
was written into a ticket as a table instead of left in a run log.
