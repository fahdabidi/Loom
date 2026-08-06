Ticket AuthZ.P4a — read-path row filtering by workflow visibility/readGuard

## Context

Fourth ticket in a larger data-safety hardening effort (AuthZ.P1-P3 all merged and independently verified:
commits `6113d194`/`eeb95b48` for the persona-picker fix and identity-state refactor, `9498ed77`/`a86ec086`
for the JSON grammar -- `LoomWorkflowStateMachine.visibility` and per-state `LoomWorkflowState.readGuard`,
both fully parsed and validator-supported, but not yet enforced anywhere).

This is the ticket that actually closes the original reported bug's full implication: a user could create an
account under an undeclared persona for a community and, while unable to *act* on anything (guards already
block writes), could still *read* 100% of that community's data -- every event, every RSVP, every record --
regardless of role. Confirmed directly from source: `LocalWorkflowEngineApi.queryInstances`
(`app/packages/core/loom_workflow_engine/lib/src/api/local_workflow_engine_api.dart:132-200`) does an
unscoped `SELECT * FROM workflow_instances WHERE community_id = ?` with no guard/role check at all. `aggregate`/
`_readAllInstancesOfType` (same file, ~221-275) take no `personaId` parameter whatsoever.

**Critical constraint, already identified -- verify it yourself before touching anything, do not assume it
still holds if the code has moved:** `aggregate`/`_readAllInstancesOfType` are also the internal primitive
used for guard math elsewhere in this same file -- `_passesRelatedAggregateGuard` and
`_passesLocationOverlapGuard` call them to compute capacity/overlap truth across *all* instances regardless
of viewer. Those internal call sites MUST keep reading unfiltered "system truth" -- filtering them by a
viewer's visibility would silently corrupt guard evaluation (e.g. a capacity guard would undercount when a
restricted viewer's read excludes some instances that should still count toward capacity). Only genuinely
viewer-facing call sites get scoped.

## Scope

**1. Row-level filtering in `queryInstances`:** after the existing hydration/computed-fields step (so
formula-based `readGuard`s can see computed data, consistent with how guards work everywhere else in this
engine), add a filter pass over the result rows using each instance's `machine.visibility` (the workflow
type's declared visibility) and its current state's `readGuard` (state-level override, if present, else the
workflow-level `visibility.readGuard`):
- `visibility` omitted or `default: "public"` -> unchanged, every row included (today's behavior, the vast
  majority of existing communities).
- `default: "membersOnly"` -> keep a row only if the calling `personaId`'s account has
  `MembershipStatus.active` for this community. (`LoomAccount.status`, added in AuthZ.P3 -- you will need to
  thread a way to look this up; check whether `LocalWorkflowEngineApi` already has any reference to
  `LoomAuthApi`/an account store, or whether this needs a new optional constructor parameter, similar in
  spirit to how AuthZ.P1 added an optional `personaResolver` to `LocalAuthApi`. If there is no existing
  account-lookup capability reachable from `LocalWorkflowEngineApi`, treat "membersOnly" filtering as
  requiring that lookup to be injected/available, and if it's not available, keep this ticket scoped to
  making the mechanism correct and testable via an injected account-status lookup, rather than wiring the
  real production `LocalAuthApi` instance through -- that wiring is acceptable to leave for AuthZ.P4b or a
  later ticket if it turns out to be non-trivial; say so explicitly in your STATUS response if you make that
  call.)
- `default: "guarded"` -> additionally evaluate the `readGuard` via the existing `evaluateGuard()`
  (`app/packages/core/loom_workflow_engine/lib/src/evaluator/guard_evaluator.dart`) against `(personaId,
  instanceData, personaTypeId)`, OR keep the row if `instance.createdByPersonaId == personaId` (an author can
  always read their own submission -- mirrors the `actorEqualsField` ownership pattern already used
  elsewhere in this engine for guards).

**2. Optional `personaId` on `aggregate`:** add an optional, backward-compatible named parameter to the
public `aggregate` method (`app/packages/core/loom_workflow_engine/lib/src/api/workflow_engine_api.dart` and
its `LocalWorkflowEngineApi` implementation). When supplied, apply the exact same visibility/readGuard row
filter described above before aggregating. When omitted (every internal guard-math call site --
`_passesRelatedAggregateGuard`, `_passesLocationOverlapGuard`, `_readAllInstancesOfType`, `dueNotifications`,
and any source-field hydration path -- must all continue omitting it, unchanged), behavior is byte-for-byte
identical to today. The two existing EXTERNAL call sites
(`app/packages/core/loom_communities_app_shell/lib/src/notification_inbox_controller.dart` around lines
23-28, and `part02_tab_shell.dart` around line 1402) already self-scope via an explicit `filter:
{'recipientPersonaId': personaId, ...}` equality match -- confirm whether adding the new optional
`personaId` parameter to these two call sites is additionally warranted (defense in depth) or genuinely
redundant given their existing explicit filter, and make a clear, stated decision either way.

**3. Pagination correctness:** filtering must not desynchronize `hasMore`/pagination cursors from what a
restricted viewer actually sees. For guard shapes expressible as a simple equality/list-membership check
(`allowedPersonaIds`, `actorEqualsField`), prefer pushing the predicate into the SQL/keyset query itself if
that's a reasonably contained change to `WorkflowDatabase.queryInstancesKeyset`
(`app/packages/core/loom_workflow_engine/lib/src/store/database.dart`) -- inspect it before deciding. For
formula-based guards that can't be pushed into SQL, over-fetch (`limit + 1` rows), filter in Dart, trim back
to `limit`, and recompute `hasMore`/`nextCursor` from the *filtered* result set, not the raw one.

## Do not do

- Do not touch `_readAllInstancesOfType`, `dueNotifications`, `_passesRelatedAggregateGuard`,
  `_passesLocationOverlapGuard`, or any other internal guard-math read path -- these must remain unfiltered
  "system truth" reads. State explicitly in your STATUS response that you verified each of these still
  reads unfiltered.
- Do not add the `personaHasPermission` helper, `requiredPermission` wiring, or any tab-visibility change --
  that is AuthZ.P4b, a separate follow-on ticket.
- Do not touch AuthZ.P1/P2/P3 code (persona picker, `ActiveIdentityScope`, JSON grammar parsing) -- all done,
  verified, must keep passing unchanged.
- Do not change any community's observed behavior when it declares no `visibility` (the overwhelming
  majority, including every existing fixture/test community) -- this must be provably a no-op for them.

## Required verification

1. `flutter analyze` on `packages/core/loom_workflow_engine` and `packages/core/loom_communities_app_shell`
   -- clean, zero new issues (this session has twice found the sandbox's own analyzer workaround missed real
   lints that a plain `flutter analyze` catches -- if you cannot run the real `flutter analyze`, say so
   plainly rather than reporting clean based on a substitute).
2. Full test suites, both packages. `loom_workflow_engine`: baseline 200 passing (confirm no regression).
   `loom_communities_app_shell`: baseline 185 passing / 1 known a11 flake failing (confirm this exact
   outcome).
3. **This is the critical new-behavior test for this ticket:** a workflow type with `visibility: {default:
   "guarded", readGuard: {allowedPersonaIds: [...]}}` (or `membersOnly`), seeded with instances, queried via
   `queryInstances` as a persona NOT in the guard's allowlist -- confirm those rows are excluded, while a
   persona that IS allowed (or the instance's own `createdByPersonaId`) still sees them. Also test the
   `public`/omitted-visibility no-op case explicitly (existing behavior unchanged).
4. A pagination test: with filtering active and more filtered-out rows than filtered-in ones within a page,
   confirm `hasMore`/cursor correctness is driven by the filtered result, not the raw one.
5. If your sandbox cannot run `flutter analyze`/`dart test`/`flutter test`, say so plainly -- independent
   verification will be re-run outside the sandbox regardless (necessary for every ticket in this effort so
   far due to sandbox network/filesystem restrictions).

## Git safety reminder

This repository lives on a OneDrive-synced path. OneDrive's background sync occasionally races with git's own
atomic index writes, producing errors like `fatal: unable to write new index file` or a stale/stuck
`.git/index.lock`. This is a known, transient environment quirk, not a sign anything is broken, and requires
no creative recovery. On an index-lock error: `rm -f .git/index.lock`, wait ~2 seconds, retry the same
command once. If it fails again, STOP -- do not run `git reset --hard`, any broad `--cached` unstage, or
recreate `.git/index` by hand. Report the exact error in your STATUS response and leave the working tree
as-is.

## Commit

One commit, once verified: `feat: enforce workflow visibility/readGuard on queryInstances and aggregate
reads (AuthZ.P4a)`.

## Required response format (write to `data/v3_ticket_authz_p4a_read_filtering_STATUS.md`)

```
# Ticket status: AuthZ.P4a

## Change applied
Status: done | blocked
Exact file:line for the filtering logic, the aggregate parameter addition, and the pagination fix. State
explicitly: (a) how membersOnly's account-status lookup was resolved (injected lookup vs full LocalAuthApi
wiring vs deferred -- and why), (b) confirmation every internal guard-math read path was left unfiltered,
(c) the decision on the two existing external aggregate call sites.

## Verification
flutter analyze (both packages): clean/not clean.
Test suites: pass counts. Explicitly confirm loom_workflow_engine 200/200 and loom_communities_app_shell
185/186 (only the known a11 flake). Name the new visibility-filtering and pagination tests added.

## Commit
Commit hash, or "staged, not committed" + exact blocker.
```
