Ticket AuthZ.P2 — replace global mutable active-identity state with explicit threading

## Context

This is the second ticket in a larger data-safety hardening effort (AuthZ.P1 just landed: fixed the
sign-up persona picker sourcing the wrong community's personas, commit `6113d194`, independently verified
clean). This ticket is a pure structural refactor with no behavior change, done early and deliberately
before later tickets in this effort add more call sites that would otherwise be built against the same
global-state pattern.

Confirmed (from direct source investigation, not a guess): `_globalAuthApi` and `_currentActiveAccountId` in
`app/packages/core/loom_communities_app_shell/lib/src/part25_engine_native_community_store.dart:5-18` are
module-level mutable global variables. They are mutated via `setCurrentActiveAccountId()` as a build-time
side effect from `app/packages/core/loom_communities_app_shell/lib/src/part01_local_extension_screen.dart:507,
642, 884`, and read via `resolveEnginePersonaId()` from
`app/packages/core/loom_communities_app_shell/lib/src/part28_engine_native_calendar_surface.dart`,
`app/packages/core/loom_communities_app_shell/lib/src/part32_engine_native_list_surface.dart`, and
`app/packages/core/loom_communities_app_shell/lib/src/part36_engine_native_marketplace_surface.dart`.

The per-community `WorkflowDatabase` cache, `_EngineNativeCommunityStore._stores` (same file, keyed by
extensionId), is a legitimate singleton -- one engine per community, not per session -- and is explicitly
**not** part of this refactor. Only the *active-account* globals (`_globalAuthApi`,
`_currentActiveAccountId`, and the free functions that read/write them) are in scope.

## Scope

1. Introduce an explicit identity-context object, e.g.:
   ```dart
   class ActiveIdentityContext {
     const ActiveIdentityContext({required this.accountId, required this.authApi, required this.personaId});
     final String? accountId;
     final LoomAuthApi authApi;
     final String? personaId;
   }
   ```
2. Thread it via an `InheritedWidget` or `InheritedNotifier` (e.g. `ActiveIdentityScope`) wrapping the
   subtree under `LocalExtensionScreen`, exposing a static `ActiveIdentityScope.of(context)` accessor.
3. Replace every direct read of `_currentActiveAccountId`/`_globalAuthApi` (and calls to
   `resolveEnginePersonaId()`/`setCurrentActiveAccountId()`) at the identified call sites (`part01`, `part25`,
   `part28`, `part32`, `part36`) with `ActiveIdentityScope.of(context)` lookups. `resolveEnginePersonaId`/
   `setCurrentActiveAccountId` become instance methods on the scope object (or plain functions taking the
   context object as a parameter) instead of free functions closing over module-level globals.
4. Search for any other read/write site of these two globals beyond the five files listed above (the
   investigation that found them was thorough but grep again yourself to be sure nothing was missed) and
   convert those too.

## Do not do

- Do not touch `_EngineNativeCommunityStore._stores` (the per-community `WorkflowDatabase` cache) -- it
  stays a singleton keyed by extensionId, unchanged. State this explicitly in your STATUS response so it's
  clear it was a deliberate exclusion, not an oversight.
- Do not add any `accessMode`, `visibility`, membership, or invite concept -- out of scope for this ticket
  (a later ticket in this same effort).
- Do not touch the persona-picker/signUp validation logic AuthZ.P1 just added -- that work is done and
  verified; this ticket must not regress it (its tests must keep passing unchanged).
- Do not change any observable app behavior. This is a pure refactor: exactly one active
  screen/account per app instance today, and that must remain true after this change. Any test outcome
  difference before vs. after is a regression to fix, not an expected side effect.

## Required verification

1. `flutter analyze` on `packages/core/loom_communities_app_shell` -- clean, zero new issues.
2. Full `loom_communities_app_shell` test suite -- identical pass/fail outcome to the current baseline
   (182 passing, 1 known pre-existing failure: "organizer creates an event and one pending response per
   member" in `v3_milestone_a11_event_rsvp_archetype_test.dart` -- confirm this exact same single failure,
   not a different one, and not zero failures either, which would suggest the flake was masked rather than
   left alone).
3. If your sandbox cannot run `flutter analyze`/`flutter test`, say so plainly in your STATUS response --
   independent verification will be re-run outside the sandbox regardless.

## Git safety reminder

This repository lives on a OneDrive-synced path. OneDrive's background sync occasionally races with git's own
atomic index writes, producing errors like `fatal: unable to write new index file` or a stale/stuck
`.git/index.lock`. This is a known, transient environment quirk, not a sign anything is broken, and requires
no creative recovery. On an index-lock error: `rm -f .git/index.lock`, wait ~2 seconds, retry the same
command once. If it fails again, STOP -- do not run `git reset --hard`, any broad `--cached` unstage, or
recreate `.git/index` by hand. Report the exact error in your STATUS response and leave the working tree
as-is.

## Commit

One commit, once verified: `refactor: replace global mutable active-identity state with explicit
ActiveIdentityScope threading (AuthZ.P2)`.

## Required response format (write to `data/v3_ticket_authz_p2_identity_context_STATUS.md`)

```
# Ticket status: AuthZ.P2

## Change applied
Status: done | blocked
Summary of the new ActiveIdentityContext/ActiveIdentityScope shape and every call site converted (file:line
for each). Explicitly confirm _EngineNativeCommunityStore._stores was left untouched.

## Verification
flutter analyze: clean/not clean (paste any issues).
Test suite: pass count (X/Y). Explicitly confirm the outcome matches the stated baseline (182/183, same
single known a11 flake) -- if it differs in either direction, explain exactly why before reporting done.

## Commit
Commit hash, or "staged, not committed" + exact blocker.
```
