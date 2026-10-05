# HARNESS — the readGuard predictor must reproduce the whole read decision, not one branch of it

**Status:** written 2026-10-05, **NOT dispatched**.
**Route:** `data/call_implementation_agent.sh --fresh`. Confirm the `Mode: fresh session` line.
**Scoped by** `data/call_root_cause_agent.sh` (session key `b25-arrangement-classes`). Its diagnosis
corrected my premise — I expected these rows to be *correct* refusals — and I then verified every
load-bearing claim below myself by reading the code. Nothing here is quoted on trust.

## Evidence

Device capture at `e0536500`, instrumented APK, live backend, scratch `--evidence-root`: `exit=0`,
`screenshotStatus=complete`, **`workflows=83`** (full traversal, was 17), `b25Communities=11/14`,
`screenshots=29/29`, canonical `Evidence/` 0 files modified. `b25Proven=1/82`.

`blocked_by_arrangement` is the dominant blocker at **45 of 82**, and it decomposes into exactly
five classes summing to 45 with nothing unclassified:

| class | rows |
|---|---|
| `visibility.readGuard` — actor "cannot read the instance this plan would create" | **15** |
| instance in a later state, not its initial state | 11 |
| no create action — created only by a sibling workflow's effect | 10 |
| unsupported creation field type (`fanId` 2, `url` 2, `fanId[]` 1, `image` 1, `list` 1) | 7 |
| formula guard the dispatch cannot satisfy | 2 |

**This ticket is the 15 only.** The other four classes are scoped and deliberately out of scope
below.

## The defect: the planner reproduces ONE branch of a three-way OR, and cripples even that one

The engine's read decision (`local_workflow_engine_api.dart:596-626`, `_isVisibleToFan`) is a
disjunction of three admitting branches, and its own comment says *"an author can always read their
own draft"*:

    1. creator always reads   if (instance.createdByFanId.isNotEmpty &&
                                  instance.createdByFanId == fanId) return true;
    2. archetype identity     if (_isVisibleThroughArchetype(instance, machine, fanId)) return true;
    3. the readGuard          workflowReadVisibilityAllows(... roleIds: _roleIdsByFanId[fanId] ...)

The planner (`b25_remote_arrangement.dart:430-441`) evaluates **branch 3 only**, and calls it
without roles:

    if (readGuard != null &&
        readGuard.relatedAggregate == null &&
        !evaluateGuard(readGuard, actorFanId, syntheticInstanceData)) {   // <- no roleId

**`evaluateGuard` fails closed on `allowedRoleIds` when roles are omitted.** Its own doc says so at
`guard_evaluator.dart:56` — *"A role-gated check fails closed when they are omitted or empty"* — and
`:79-81` implements it. So **every `allowedRoleIds`-shaped readGuard refuses unconditionally, even
when the acting role is literally in the list.**

**And the planner already holds everything it needs.** `roleId` and `creatorFanId` are *required
parameters of the very same function* (`planB25RemoteArrangement`, `:317-321`), and `roleId` is
interpolated into the refusal message two lines below the call. This is the project's own recorded
rule — *failing closed on a clause you cannot compute converts "I don't know" into "no"* — violated
on a clause it **can** compute.

## The change

Make the refusal fire only when **all three** branches deny:

    final readGuard = machine.visibility.readGuard;
    final guardApplies = readGuard != null &&
        readGuard.relatedAggregate == null &&
        machine.visibility.defaultValue == WorkflowVisibilityDefault.guarded;
    if (guardApplies &&
        creatorFanId != actorFanId &&
        !_archetypeFieldsAdmit(machine, syntheticInstanceData, actorFanId, roleId) &&
        !evaluateGuard(readGuard, actorFanId, syntheticInstanceData, roleId: roleId)) {
      throw ...  // message and category unchanged
    }

Three constraints on it:

- **`_archetypeFieldsAdmit` reproduces only the reproducible principals.** A field principal passes
  when `syntheticInstanceData[fieldName] == actorFanId`; a role principal when
  `principal.roleId == roleId`. Anything else stays **unknown, not denied** — do not fail closed on
  a principal shape you cannot compute offline. This is the same discipline as the existing
  `relatedAggregate` carve-out immediately above the call site.
- **Confirm the `visibility.defaultValue == guarded` precondition against the engine before relying
  on it.** The scoping says runtime consults `visibility.readGuard` only in that case. I did not
  verify that specific clause myself; verify it and say so, and if it is wrong, drop that conjunct
  rather than guessing.
- **Keep `relatedAggregate != null` unresolved exactly as today.** It is correct and this ticket does
  not touch it.

## Honesty test — it must be able to FAIL, and must not become permissive

A fix that admits everything would "unblock" all 15 rows and bank false evidence. So:

- **Keep a refusing case green.** In `b25_remote_arrangement_test.dart` (13 tests today): a guarded
  machine whose `allowedRoleIds` **excludes** the acting role, with `creatorFanId != actorFanId` and
  no matching identity field, **must still throw** `readGuardDenied`. If that test cannot be made to
  fail by the fix, the fix is not discriminating.
- **Add the admitting cases, one per branch:** creator-is-actor admits; an identity field holding the
  actor admits; `allowedRoleIds` containing `roleId` admits.
- **A/B it.** Neutralise only the new conjuncts and confirm the admitting tests fail; restore and
  `cmp`-verify byte-identical. A test that passes against both the fixed and unfixed planner proves
  nothing.
- **In the executor, assert the actor can really see it.** After creation, as the actor, assert the
  instance card renders. If it does not, record an **arrangement failure naming the readGuard** —
  never `primary_action_unavailable`. Those are different facts, and collapsing them would let a
  wrongly-admitted plan bank a designed-outcome row as evidence.

## Scope limit — what this must NOT take down

Do **not** attempt the other four classes. If a row in one of them fails while you work, record its
outcome and continue to the next row; do not abort the batch. Specifically out of scope:

- **The 10 sibling-effect rows — never create them directly.** Every one is written by a sibling's
  effect, and direct creation would fabricate provenance the product never produces. One of them
  (`hoa-committee-decision`) is a cascade pair this project has already recorded as a trap.
- **The 7 field-type rows and the 2 formula-guard rows** — a separate increment, already scoped.
- **The 11 later-state rows** — the cheap `initialState` fix is already in the planner
  (`:333-352`); what remains is genuine multi-step chain driving.

## Expected measurement

Re-run `--mode targeted-precheck --phases B12,B13` with a **scratch `--evidence-root`** (the default
overwrites canonical manifests for phases it never ran). Success is `blocked_by_arrangement` falling
from 45 toward ~30, with the readGuard sub-count dropping from 15 and **no** increase in
`action_succeeded_result_unverified` or `row_execution_failed`. A row that moves from `readGuard` to
a *different* honest refusal is a success for this ticket.

**Do not quote a bar figure.** `targeted-precheck` output is `commitEligible: false` by the tool's
own aggregate; `b25Proven` on the bar is 0 and `CONFIRMED` is 0.

## Verification

- All five suites, **sequentially**, skip counts before pass counts: demo **299** (0 failed,
  0 skipped), app shell **448** (+2), judges **525**, engine **345** (+1, BOTH Postgres credential
  sets), service **168** (+1, the one skip being App Access and **not** PostgreSQL).
  `b25_capture_prebuilt_binary_test.dart` is flaky about 1 run in 3 with a rotating test name;
  confirm a `TimeoutException` and an isolated pass before believing it, and note its assertions are
  about a **spawned subprocess exit code**, so a starved child yields a failed `expect` rather than a
  timeout.
- `flutter analyze` on the demo app: **3** pre-existing issues, from the tool's own
  `N issues found` line, with the working directory stated.
- **Emit `<<<SUITES_RUN: ...>>>`.** The dispatcher refuses a reply without it and exits 2;
  `NOT_RUN(reason)` is a correct and expected entry for anything you genuinely could not run.
