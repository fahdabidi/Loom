Ticket AuthZ.P4b fix1 — notification surfaces incorrectly denied by new engine-boundary permission check

## Context

AuthZ.P4b (commit `d0f5046c`) wired `personaHasPermission` into `LocalWorkflowEngineApi.queryInstances`/
`applyTransition` via a new `_requireSurfacePermission` check, and wired the real production policy into it
via `configureEngineAuthorizationForExtensionId`, called from `_syncEnginePersonaTypes()`
(`part01_local_extension_screen.dart:364-386`). I independently re-ran the full `loom_communities_app_shell`
suite outside the Implementation Agent's own sandbox (which could not run it) and found 4 new failures beyond
the one pre-existing known a11 flake -- all in notification-related surfaces:

- `test/notification_fab_test.dart`: `FAB notification style is global, scoped, and marks unread rows read`
- `test/notification_fixed_card_test.dart`: `fixed card is home-scoped, persona-scoped, and marks unread
  through the engine`
- `test/notification_fixed_card_test.dart`: `fixed card collapses when the viewing persona has no
  notifications`
- `test/v3_calnotify2_7_bell_activation_test.dart`: `real Tabletop Club fixture activates only the bell
  notification presentation`

I confirmed this is a real regression, not flakiness, by re-running `test/notification_fixed_card_test.dart`
in isolation -- same two failures every time. The second one is the most telling: the test now finds a widget
keyed `notification-fixed-error` where it expected nothing, meaning the notification query is now genuinely
*throwing* (surfacing as a visible error card in the UI) rather than returning an empty/successful result.
This is exactly the shape `_requireSurfacePermission`'s `throw StateError('Permission denied for surface
...')` produces (`local_workflow_engine_api.dart:353-372`) when its injected `_surfacePermissionLookup`
returns `false`.

**Working hypothesis, not yet confirmed -- verify before fixing, don't assume:** notification surfaces
(bell/FAB/fixed-card) likely query the `notification` workflow type through a path that either isn't bound to
a normal content `tabId` the way `requiredPermissionForTab` expects (notifications are a cross-cutting,
persona's-own-inbox surface, not a regular tab a persona browses), or query with a `tabId`/`workflowType`
combination that `requiredPermissionForTab`/`personaHasPermission` resolves to `false` for -- when it should
instead always allow a persona to read notifications addressed to them. Trace the actual call site(s) these
four failing tests exercise (`notification_inbox_controller.dart`, the bell/FAB/fixed-card widgets, whatever
`queryInstances`/`aggregate` call they make) and find precisely which `tabId`/`workflowType` reaches
`_requireSurfacePermission` and why the resulting policy decision comes back `false` for a persona reading
their own notifications.

## Scope

1. Find and fix the actual reason notification-surface reads are being denied. Likely fix shapes (confirm
   which is actually correct from your trace, don't guess): (a) notifications need their own `requiredPermission`
   value/tab registration that `personaHasPermission` correctly resolves as always-allowed for the querying
   persona (e.g. an "own inbox" permission that isn't derived from `allowedPersonaIds`-style guards at all),
   or (b) the `_requireSurfacePermission` call site in `queryInstances`/`applyTransition` needs to skip the
   check for the notification workflow type specifically (with a clear, principled reason why notifications
   are structurally different from every other surface this check correctly applies to), or (c) something
   else you find that's more precisely correct than either guess above.
2. Whatever the fix, it must preserve AuthZ.P4a's existing notification-scoping behavior (a persona only ever
   sees notifications addressed to them -- `NotificationInboxController.filterMine`,
   `recipientPersonaId == personaId`) -- this ticket's fix must not accidentally make notifications globally
   visible while fixing the permission-denied regression. Read that existing scoping logic before touching
   anything so you don't weaken it while fixing this.
3. Fix it in the production code, not by changing what the 4 failing tests assert -- their expectations
   (empty state when no notifications, real cards when there are, no error card) reflect the correct,
   pre-existing behavior that this ticket accidentally broke.

## Do not do

- Do not touch AuthZ.P1-P4a code beyond what's needed to fix this regression precisely.
- Do not weaken, skip, or delete any of the 4 failing tests, or the pre-existing known a11 flake -- fix the
  real regression.
- Do not remove `_requireSurfacePermission` or make it a global no-op -- it's doing its job correctly for
  every other surface; this is a narrow, notification-specific gap.
- Do not add or change any JSON grammar or field.

## Required verification

1. `flutter analyze` on `packages/core/loom_communities_app_shell` and `packages/core/loom_workflow_engine`
   -- clean.
2. Full test suites, both packages. `loom_workflow_engine`: 206/206. `loom_communities_app_shell`: must
   return to exactly 191 passing / 1 failing (185 original baseline + 6 AuthZ.P4b tests), with the 1 failure
   being ONLY the pre-existing "organizer creates an event and one pending response per member" a11 flake.
   Run the 4 previously-failing tests individually first to confirm, then the full suite to confirm no other
   regression.
3. If your sandbox cannot run `flutter analyze`/`flutter test`, say so plainly -- independent verification
   will be re-run outside the sandbox regardless (this is what caught the regression in the first place, for
   the second time in this effort).

## Git safety reminder

This repository lives on a OneDrive-synced path. OneDrive's background sync occasionally races with git's own
atomic index writes, producing errors like `fatal: unable to write new index file` or a stale/stuck
`.git/index.lock`. This is a known, transient environment quirk, not a sign anything is broken, and requires
no creative recovery. On an index-lock error: `rm -f .git/index.lock`, wait ~2 seconds, retry the same
command once. If it fails again, STOP -- do not run `git reset --hard`, any broad `--cached` unstage, or
recreate `.git/index` by hand. Report the exact error in your STATUS response and leave the working tree
as-is.

## Commit

One commit, once verified: `fix: stop the AuthZ.P4b engine-boundary permission check from denying a
persona's own notification reads (AuthZ.P4b fix1)`.

## Required response format (write to `data/v3_ticket_authz_p4b_fix1_STATUS.md`)

```
# Ticket status: AuthZ.P4b fix1

## Root cause found
Exactly which tabId/workflowType/permission resolution was wrong and why, with the specific mechanism.

## Change applied
Status: done | blocked

## Verification
flutter analyze: clean/not clean.
Test suite: pass count (X/Y). Explicitly confirm all 4 previously-failing tests pass individually, and the
full suite is 191/192 with only the known a11 flake failing. Confirm notification recipient-scoping
(persona only sees their own notifications) was not weakened -- name the existing test(s) that prove this.

## Commit
Commit hash, or "staged, not committed" + exact blocker.
```
