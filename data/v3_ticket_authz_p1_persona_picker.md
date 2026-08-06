Ticket AuthZ.P1 — persona picker sources the wrong community's personas

## Context

Live-testing on the emulator found a real data-integrity bug: opening the externally-authored "Apartment
Events" community and tapping "Sign in as a specific person" -> "Create New Account" offered
`tabletop-member`/`tabletop-organizer` as the persona/role choices -- persona IDs belonging to a completely
different community ("Tabletop Club"), not anything Apartment Events itself declares
(`apartment-event-manager`, `apartment-resident`, `facility-privileged-resident`). A new account was created
under one of these wrong persona IDs; signed in as it, the user could still view the entire calendar (every
event, every RSVP) but had no permission to act on anything, since every transition guard correctly (if
accidentally) rejects a persona type the community never declared.

Root cause, already found and verified against source (not a guess -- confirm this diagnosis as part of your
own work, but you should not need to re-derive it):
`_SignUpFormState._availableTypes` in
`app/packages/core/loom_communities_app_shell/lib/src/part31_auth_screens.dart:224` is a hardcoded
`const ['tabletop-member', 'tabletop-organizer']` -- copy-pasted from the Tabletop Club demo, never
parameterized by whatever community is actually open. `_AccountList._personaLabelFor` (same file, lines
191-200) has the identical smell: a hardcoded switch on the same two ids. `LoomAuthScreen`'s constructor
never receives `experience`/personas at all.

The correct pattern already exists and is proven elsewhere in this exact codebase:
`personasForExtensionId(extensionId, experience: experience)`
(`app/packages/core/loom_communities_app_shell/lib/src/part12_persona_and_tabs.dart:3-12`) returns
`experience.personas` (the currently-open community's own JSON-declared personas) when non-empty. It is
already used correctly by `_showPersonaPicker`
(`app/packages/core/loom_communities_app_shell/lib/src/part01_local_extension_screen.dart:680-787`) -- the
only call site that pushes `LoomAuthScreen` (line 793), which already has `experience` in scope at that
point.

## Scope

1. `part01_local_extension_screen.dart:793` -- pass `experience: experience` into the `LoomAuthScreen(...)`
   constructor call.
2. `part31_auth_screens.dart`:
   - `LoomAuthScreen` (lines 5-19): add `required LoomExperienceDefinition experience` to its constructor;
     thread it through to `_AccountList` and `_SignUpForm`.
   - `_AccountList` (135-201): accept `experience`; replace the hardcoded `_personaLabelFor` switch with a
     lookup against `personasForExtensionId(experience.extensionId, experience: experience)`, matching on
     `persona.personaId == typeId` and rendering `persona.label`/`persona.roleLabel` (fall back to the raw
     `typeId` string only if genuinely no match is found -- defensive, not a silent success path).
   - `_SignUpFormState` (218-303): resolve `personas = personasForExtensionId(widget.experience.extensionId,
     experience: widget.experience)` in `initState`; replace the `const _availableTypes` list with
     `personas.map((p) => p.personaId).toList()`; initialize `_selectedType` from `personas.first.personaId`
     instead of the literal `'tabletop-member'`; render dropdown items using `persona.label` instead of the
     raw id string (currently `Text(type)` around line 287).
3. `part30_local_auth_api.dart` -- add independent, defense-in-depth validation, not just trusting whatever
   the UI computed (a check that only re-validates the same value the buggy UI already trusted would not have
   caught this exact historical bug). Give `LocalAuthApi` an optional, injected persona resolver:
   ```dart
   LocalAuthApi({List<LoomPersonaDefinition> Function(String communityExtensionId)? personaResolver})
   ```
   `null` (the default) must preserve today's unchecked behavior exactly -- confirm the two existing bare
   `LocalAuthApi()` test call sites still compile and pass unchanged. When `personaResolver` is non-null,
   `signUp` (lines 120-140) must reject (throw `ArgumentError`, with a message naming the invalid
   `personaTypeId` and the community) a `personaTypeId` not present in the resolver's result for that
   community. Wire the real resolver at the one production construction site --
   `late final LoomAuthApi _authApi = LocalAuthApi();` in `_LocalExtensionScreenState`
   (`part01_local_extension_screen.dart:179`) -- back to `personasForExtensionId`, resolving `experience` the
   same way the rest of that file already does for the current community. This must be a second,
   independently-wired path into the same source of truth, not a value forwarded from the form, so a future
   regression in the dropdown alone would still be rejected server-side.

## Do not do

- Do not touch calendar, marketplace, or any surface file outside auth/persona plumbing.
- Do not change the abstract `LoomAuthApi.signUp` contract's required parameters
  (`part29_auth_api.dart:49-53`) -- `personaResolver` is `LocalAuthApi`-specific constructor wiring, not an
  abstract-interface change.
- Do not add any `accessMode`, membership, invite, or "pending approval" concept -- that is explicitly
  out of scope for this ticket (a later ticket in this same effort).
- Do not touch `_EngineNativeCommunityStore`, `_currentActiveAccountId`, or any other global-identity-state
  code -- also out of scope for this ticket.

## Required verification

1. `flutter analyze` on `packages/core/loom_communities_app_shell` -- clean, zero new issues.
2. Full `loom_communities_app_shell` test suite -- same pass count as the current baseline, plus at least one
   new regression test that reproduces the original bug directly: construct (or reuse) a community fixture
   whose `personas` are NOT `tabletop-member`/`tabletop-organizer`, open its sign-up dialog, and assert the
   rendered persona options match that community's own declared personas exactly (not Tabletop Club's). Add a
   second test asserting `LocalAuthApi.signUp` (constructed with a `personaResolver`) throws for a
   `personaTypeId` outside the resolved list, and a third confirming it still succeeds normally when
   `personaResolver` is `null` (today's existing tests should already cover this -- just confirm, don't
   weaken them).
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

One commit, once verified: `fix: source the account sign-up persona picker from the actual open community,
not a hardcoded Tabletop Club list (AuthZ.P1)`.

## Required response format (write to `data/v3_ticket_authz_p1_persona_picker_STATUS.md`)

```
# Ticket status: AuthZ.P1

## Root cause confirmed
Confirm (or correct, with evidence, if this ticket's diagnosis above turns out to be wrong in some detail)
the root cause described above.

## Change applied
Status: done | blocked
Summary of exactly what changed in each of the three files.

## Verification
flutter analyze: clean/not clean (paste any issues).
Test suite: pass count (X/Y). Explicitly confirm the new regression test(s) pass and name them.

## Commit
Commit hash, or "staged, not committed" + exact blocker.
```
