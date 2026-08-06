Ticket AuthZ.P4b — personaHasPermission helper + requiredPermission enforcement

## Context

Fifth ticket in a larger data-safety hardening effort. AuthZ.P1-P3 (persona-picker fix, identity-state
refactor, JSON grammar) and AuthZ.P4a (read-path row filtering by workflow visibility/readGuard) are all
merged and independently verified: commits `6113d194`/`eeb95b48`, `9498ed77`/`a86ec086`, `b52da1b9`/`ef89f9c2`.

**No new JSON grammar in this ticket.** `requiredPermission` is an EXISTING field, already declared
throughout `part12_persona_and_tabs.dart`'s tab specs (values like `community.surface.calendar.read`,
`community.surface.navigation.configure`) and already JSON-authorable for declaratively-authored communities
via `_readShellString(value, ['requiredPermission', 'permission'])`
(`part12_persona_and_tabs.dart:632-633`) -- confirmed directly from source earlier in this effort. It is
parsed and stored but never actually enforced anywhere. This ticket wires it up; it does not add or change
any JSON field. If your work here reveals a need for new JSON grammar, STOP and report that in your STATUS
response rather than adding it -- JSON schema changes in this project require the user's explicit review
before implementation, separate from this ticket's own review.

## Scope

**1. `personaHasPermission` helper**, new, placed next to the existing `_personaCanAdministerAnyWorkflow` in
`app/packages/core/loom_communities_app_shell/lib/src/part12_persona_and_tabs.dart:1274-1329` (verify the
exact current line numbers -- AuthZ.P1-P4a may have shifted them slightly; that function is itself already a
JSON-derived permission-style check and should become part of this helper's write-side logic, not be
duplicated):

- Signature roughly: `bool personaHasPermission(LoomExperienceDefinition experience, String personaId,
  String requiredPermission)`.
- For a `.read`-shaped permission (the tab's bound workflow type is `T`): true if `T`'s `visibility` is
  `public` (or undeclared), OR (`membersOnly` and the caller has active membership -- you will need the same
  kind of membership-status lookup capability AuthZ.P4a used; check how AuthZ.P4a resolved `ActiveMembershipLookup`
  and reuse/extend that pattern rather than inventing a second one), OR (`guarded` and the given `personaId`
  passes at least one state's `readGuard` for `T` -- i.e., there's something in that tab they could read; you
  don't need to enumerate actual instances, just whether the guard shape could ever admit this persona, similar
  in spirit to how `availableTransitions` reasons about guard admissibility without needing live data).
- For a `.write`/`.configure`-shaped permission: true if the persona appears in `allowedPersonaIds` on any
  transition/editGuard/creationGuard for workflow type `T` -- generalize `_personaCanAdministerAnyWorkflow`'s
  existing logic rather than reimplementing it from scratch.
- The permission-string taxonomy already in use (`community.surface.<domain>.read` /
  `community.surface.<domain>.configure`) tells you which shape you're looking at -- `.read` suffix vs
  everything else (`.configure`, `.write`, etc.). Confirm this taxonomy is actually consistent across every
  `requiredPermission` value already in the codebase before relying on a naive suffix check; if it isn't
  fully consistent, say so and handle the exceptions explicitly.

**2. Wire it into tab-visibility resolution** for declaratively-authored communities (the generic/JSON-driven
tab-spec path, as opposed to the hardcoded Dart archetypes in `part12_persona_and_tabs.dart` which keep their
explicit, already-trusted `visiblePersonaIds` lists unchanged -- do not touch those). Find where declarative
tab specs are resolved into the actual tab list shown to a persona and have `LoomAppShellTabSpec.isVisibleFor`
(or its declarative-path caller) additionally consult `personaHasPermission(experience, personaId,
tab.requiredPermission)` when `visiblePersonaIds` is empty/unset for that tab -- i.e., this becomes the
*computed* fallback for communities that don't hand-author a persona allowlist, not a replacement for
communities that do.

**3. Defensive re-check at the engine boundary.** Add a `personaHasPermission`-based check inside
`LocalWorkflowEngineApi.queryInstances` and `applyTransition` (or the most natural chokepoint you find) that
denies the call if the caller's persona genuinely lacks permission for the relevant surface -- mirroring the
existing pattern where transition guards are checked both for UI availability *and* re-checked at apply-time,
so a tab-visibility bug alone can never be the only thing standing between a persona and data/actions it
shouldn't have. Be careful this defensive check does not duplicate or conflict with AuthZ.P4a's row-level
visibility filtering (which already runs inside `queryInstances`) -- this new check is about whether the
persona should reach the surface/tab at all, not row-level filtering within it; if the distinction proves
genuinely redundant with what AuthZ.P4a already enforces for a given call, say so explicitly rather than
adding a no-op check.

## Do not do

- Do not add, remove, or change any JSON field or grammar. `requiredPermission` already exists; you are
  wiring existing data, not authoring new schema. If you find you need a new field to make this work
  correctly, STOP and describe exactly what's missing in your STATUS response instead of adding it.
- Do not touch the hardcoded Dart archetype communities' explicit `visiblePersonaIds` lists -- those stay as
  first-party, already-trusted declarations.
- Do not touch AuthZ.P1-P4a code beyond what's needed to reuse `_personaCanAdministerAnyWorkflow` and
  whatever membership-lookup mechanism AuthZ.P4a introduced -- read, don't modify, unless a genuine bug in
  that existing code blocks this ticket (if so, say so explicitly).
- Do not build the membership/invitation UI (sign-up branching, approve/invite flows) -- that is AuthZ.P5, a
  separate ticket.
- Do not build the community-open entry gate -- that is AuthZ.P6, a separate ticket.

## Required verification

1. `flutter analyze` on `packages/core/loom_communities_app_shell` and `packages/core/loom_workflow_engine`
   -- clean, zero new issues. This effort has twice found the sandbox's own analyzer-workaround missed real
   lints a plain `flutter analyze` catches -- if you cannot run the real one, say so plainly.
2. Full test suites, both packages. Baselines: `loom_workflow_engine` 206/206. `loom_communities_app_shell`
   185/186 (only the known a11 flake).
3. New tests for `personaHasPermission`: a `.read` permission on a `public` workflow (always true), a
   `.read` permission on a `guarded` workflow for an allowed vs. disallowed persona, a `.write`/`.configure`
   permission derived correctly from `allowedPersonaIds` across transitions/editGuard/creationGuard.
4. A test confirming a declaratively-authored community's tab visibility is now correctly computed from
   `personaHasPermission` when no explicit `visiblePersonaIds` is set, while a hardcoded Dart archetype
   community's explicit list is unaffected.
5. If your sandbox cannot run `flutter analyze`/`flutter test`, say so plainly -- independent verification
   will be re-run outside the sandbox regardless.

## Git safety reminder

This repository lives on a OneDrive-synced path. OneDrive's background sync occasionally races with git's own
atomic index writes, producing errors like `fatal: unable to write new index file` or a stale/stuck
`.git/index.lock`. This is a known, transient environment quirk, not a sign anything is broken, and requires
no creative recovery. On an index-lock error: `rm -f .git/index.lock`, wait ~2 seconds, retry the same
command once. If it fails again, STOP -- do not run `git reset --hard`, any broad `--cached` unstage, or
recreate `.git/index` by hand. Report the exact error in your STATUS response and leave the working tree
as-is.

## Commit

One commit, once verified: `feat: wire requiredPermission into real tab-visibility and engine-boundary
enforcement (AuthZ.P4b)`.

## Required response format (write to `data/v3_ticket_authz_p4b_permission_wiring_STATUS.md`)

```
# Ticket status: AuthZ.P4b

## Change applied
Status: done | blocked
Exact file:line for personaHasPermission, the tab-visibility wiring, and the engine-boundary check. Confirm
no JSON grammar was added or changed. Confirm hardcoded Dart archetypes' visiblePersonaIds were left
untouched.

## Verification
flutter analyze (both packages): clean/not clean.
Test suites: pass counts. Confirm loom_workflow_engine 206/206 and loom_communities_app_shell 185/186 (only
the known a11 flake). Name the new tests added.

## Commit
Commit hash, or "staged, not committed" + exact blocker.
```
