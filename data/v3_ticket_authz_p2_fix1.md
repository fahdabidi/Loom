Ticket AuthZ.P2 fix1 — attendee-name resolution broken by ActiveIdentityScope refactor

## Context

AuthZ.P2 (commit not yet made -- currently staged/uncommitted pending this fix) replaced the module-level
`_globalAuthApi`/`_currentActiveAccountId` globals in
`app/packages/core/loom_communities_app_shell/lib/src/part25_engine_native_community_store.dart` with an
explicit `ActiveIdentityContext`/`ActiveIdentityScope` threaded via `InheritedWidget`. I independently
re-ran the full `loom_communities_app_shell` suite outside the Implementation Agent's own sandbox (whose
network/filesystem restrictions blocked it from running the suite itself) and found a real regression: 2
new failures beyond the one pre-existing known flake, both in
`test/v3_milestone_a11_event_rsvp_archetype_test.dart`:

- `Calendar attendee lists resolve frozen-fixture names by response state`
- `Calendar attendee lists resolve tournament names and retain unknown ids`

Both fail identically:
```
Timed out waiting for Found 0 widgets with text "• Jordan W.": []; last observed matches=0
```

I traced this partway (do not re-derive what's below, but verify it before assuming it's the whole
picture):

1. Account-name resolution lives in `_loadAccountNames()`,
   `app/packages/core/loom_communities_app_shell/lib/src/part28_engine_native_calendar_surface.dart:1640-1657`:
   ```dart
   final accounts = await ActiveIdentityScope.of(context).authApi.listAccounts(
     communityExtensionId: communityExtensionId,
   );
   ```
   then populates `_accountNames` via `setState`. Errors are swallowed (`catch (_) { if (!mounted ...`), so
   a failure here produces no visible error -- just a name that never resolves, matching the observed
   symptom exactly.
2. Both failing tests use the shared `_calendar(...)` harness
   (`test/v3_milestone_a11_event_rsvp_archetype_test.dart:101-127`), which wraps
   `EngineNativeCalendarSurface` in `ActiveIdentityScope(identity: ActiveIdentityContext(accountId:
   accountId, authApi: authApi ?? LocalAuthApi(), personaId: personaId), ...)`.
3. I confirmed both failing tests DO pass a real, pre-seeded `authApi` explicitly (via `final auth = await
   _useFixtureAccounts(installed); ... _calendar(installed, 'tabletop-member', authApi: auth)`) -- this
   rules out my first hypothesis (a test accidentally falling back to the harness's default empty
   `LocalAuthApi()`). Something else about the refactor is breaking name resolution for these two tests
   specifically, even with the correct `authApi` wired in.
4. Both failing tests navigate into an agenda/attendee-list view via `_selectAgenda(tester,
   '<instanceId>', 0)` before asserting on the attendee name -- worth checking whether the attendee-list
   widget that calls `_loadAccountNames` ends up in a part of the widget tree (a route, overlay, or dialog)
   that does not actually descend from the `ActiveIdentityScope` established at the `MaterialApp` root in
   `_calendar(...)`, or whether `ActiveIdentityScope.of(context)` is being called from a `context` captured
   too early (e.g. in `initState` before the scope is fully established, or from a context that gets
   disposed/replaced by the time the async `listAccounts` call resolves).
5. Every OTHER test in this same file that exercises the calendar/attendee surface (the full suite run was
   182 passing before AuthZ.P2, only 1 known flake) was unaffected -- so this is not a wholesale breakage of
   `ActiveIdentityScope`, just these two specific attendee-name-resolution paths. Compare against a nearby
   passing test in the same file that also renders attendee-adjacent UI, if one exists, to find the actual
   behavioral difference.

## Scope

1. Find and fix the actual reason `ActiveIdentityScope.of(context).authApi.listAccounts(...)` (or the
   `context` it's called with) fails to resolve/populate `_accountNames` for these two specific tests, even
   though the correct `authApi` is demonstrably passed into `ActiveIdentityScope` at the widget-tree root.
2. Fix it in the production code (`part28_engine_native_calendar_surface.dart` and/or
   `part25_engine_native_community_store.dart`'s `ActiveIdentityScope`/`ActiveIdentityContext`
   implementation) -- not by changing the test's expectations or weakening what it asserts. If the true fix
   turns out to require a change in the test harness (e.g. the `_calendar()` helper's tree structure), that
   is acceptable, but explain precisely why in your STATUS response rather than silently patching around the
   symptom.
3. Do not remove or weaken the swallowed-error handling in `_loadAccountNames` as a way to "fix" this --
   if you find it's actively hiding a real error during your investigation, surfacing it temporarily for
   diagnosis is fine, but the final state should still degrade gracefully (no visible crash) if account
   lookup genuinely fails for an unrelated reason; just make sure it does NOT fail here.

## Do not do

- Do not touch AuthZ.P1's persona-picker/signUp code -- unrelated, already verified, must keep passing.
- Do not weaken, skip, or delete either failing test, or the one pre-existing known-flake test
  ("organizer creates an event and one pending response per member" in the same file) -- fix the real
  regression, don't hide it.
- Do not revert any part of the `ActiveIdentityScope` refactor wholesale -- find the actual bug in it.

## Required verification

1. `flutter analyze` on `packages/core/loom_communities_app_shell` -- clean.
2. Full `loom_communities_app_shell` test suite -- must return to exactly 182 passing / 1 failing, with the
   1 failure being ONLY the pre-existing "organizer creates an event and one pending response per member"
   flake. Both attendee-name tests named above must pass. Run them individually first to confirm, then run
   the full suite to confirm no other regression was introduced by this fix.
3. If your sandbox cannot run `flutter analyze`/`flutter test`, say so plainly in your STATUS response --
   independent verification will be re-run outside the sandbox regardless (this is what caught the
   regression in the first place).

## Git safety reminder

This repository lives on a OneDrive-synced path. OneDrive's background sync occasionally races with git's own
atomic index writes, producing errors like `fatal: unable to write new index file` or a stale/stuck
`.git/index.lock`. This is a known, transient environment quirk, not a sign anything is broken, and requires
no creative recovery. On an index-lock error: `rm -f .git/index.lock`, wait ~2 seconds, retry the same
command once. If it fails again, STOP -- do not run `git reset --hard`, any broad `--cached` unstage, or
recreate `.git/index` by hand. Report the exact error in your STATUS response and leave the working tree
as-is.

## Commit

One commit, once verified, covering the fix on top of AuthZ.P2's already-staged (uncommitted) changes:
`fix: restore attendee-name resolution broken by ActiveIdentityScope refactor (AuthZ.P2 fix1)`.

## Required response format (write to `data/v3_ticket_authz_p2_fix1_STATUS.md`)

```
# Ticket status: AuthZ.P2 fix1

## Root cause found
Exactly what was wrong and why, with the specific mechanism (not just "context timing" vaguely -- name the
actual widget/lifecycle/tree issue).

## Change applied
Status: done | blocked

## Verification
flutter analyze: clean/not clean.
Test suite: pass count (X/Y). Explicitly confirm both attendee-name tests pass individually, and confirm the
full suite is 182/183 with only the known a11 flake failing.

## Commit
Commit hash, or "staged, not committed" + exact blocker.
```
