Ticket AuthZ.P7 fix1 — accent header pushed the account list far enough down to break a real sign-in test

## Context

AuthZ.P7 (currently uncommitted in the working tree -- your own prior STATUS response is at
`data/v3_ticket_authz_p7_visual_identity_STATUS.md`) added community-accent theming to
`LoomAuthScreen`/`_communityEntryGate`. Its own sandbox could not run `flutter analyze`/`flutter test` at all
(hit the documented WSL vsock error), so none of this was verified before you reported it. I independently
ran `flutter analyze` (clean) and the full `loom_communities_app_shell` test suite outside that sandbox and
found **one real, deterministic regression**: `test/v3_calr4b_individual_sign_in_ui_test.dart`, `individual
account sign-in resolves Friday RSVP rows through the app shell`.

**Isolation performed (do not re-derive, but do verify it yourself before trusting it):**
- `git stash` the two AuthZ.P7 files, ran this one test file 3x on the clean baseline -- passed 3/3.
- `git stash pop` to restore AuthZ.P7's changes, ran the same test file 3x again -- failed 3/3, identical
  error every time. This is a real, deterministic regression caused by AuthZ.P7's diff, not a pre-existing
  flake (the one known pre-existing flake in this suite is a completely different test,
  `v3_milestone_a11_event_rsvp_archetype_test.dart`'s "organizer creates an event and one pending response
  per member" -- unrelated, still present, not this ticket's concern).

**Root cause (my hypothesis from the failure output -- confirm or correct it with your own investigation,
don't just trust this blindly):** the test's `_signInAs` helper (`test/v3_calr4b_individual_sign_in_ui_test.dart:137-150`)
waits for an account's display-name `Text` to appear, then taps it. The failure output shows
`WidgetController.tap` computing a *geometrically correct* center offset for that Text widget, but the hit
test at that exact offset resolves to unrelated overlay chrome (`RenderOffstage`/`AbsorbPointer`/
`_RenderTheater`/multiple `AnimatedOpacity` -- the Navigator's own Overlay stack), not the account row itself,
and the subsequent wait for `persona-picker-button` (the widget only visible once signed-in content renders)
times out. Flutter widget tests run at a default ~800x600 logical-pixel surface (much smaller than a real
device -- the live emulator walkthrough this session used a real 1080x2340 phone, where this same layout
had no visible problem). AuthZ.P7's new header block in `LoomAuthScreen.build`
(`part31_auth_screens.dart:87-116`) wraps the icon/title in a `Container` with
`padding: EdgeInsets.fromLTRB(24, 28, 24, 28)` (56px added vertical) plus
`margin: EdgeInsets.only(bottom: 24)` (24px more) -- roughly **80 logical pixels of added height** before the
account list even starts. On the small test surface, this is plausibly enough to push the account row far
enough down that it interacts badly with the Navigator's overlay hit-testing (whether that's literally
"off past the bottom edge" or some other geometry interaction, your own investigation should confirm the
exact mechanism, not just assume).

## Scope

1. Confirm the root cause above with your own investigation (e.g. temporarily dump the account row's actual
   `Offset`/`RenderBox` bounds during a failing test run, or bisect which specific piece of the new header --
   padding, margin, icon size -- is responsible) before changing anything.
2. Reduce the header's added vertical footprint enough that this test passes reliably, while preserving the
   actual intent of AuthZ.P7 (community-accent theming should still be visually present -- don't just delete
   the header block to make the test pass). Concretely: tighten the padding/margin numbers (e.g. smaller
   `EdgeInsets` values, or drop the `margin` and let the existing `SizedBox(height: 32)` below it do that job
   instead of stacking both), and/or make the icon smaller. Use your judgment on the exact numbers, but the
   bar is: this specific test passes reliably (3 consecutive local runs, not just once), and the header still
   visibly reads as accent-themed on a real screen (you will not have emulator access to re-confirm this
   visually yourself -- I will re-run the live emulator walkthrough independently after your fix; don't discard
   the theming to "solve" this, that would just move the problem to my re-verification).
3. Re-check whether the same class of issue could affect `_communityEntryGate`'s footer block
   (`part01_local_extension_screen.dart:313-360`, the `Color.alphaBlend`-tinted `Container` you added around
   the bottom action row) -- it's a smaller addition (no extra padding/margin, just a background color) so is
   less likely to be the cause, but confirm rather than assume; if you find it also needs adjustment, fix it
   too and say so.

## Do not do

- Do not touch any AuthZ.P1-P6 authorization/permission/membership logic, or any JSON grammar (same
  boundary as the original AuthZ.P7 ticket).
- Do not weaken, delete, or skip `v3_calr4b_individual_sign_in_ui_test.dart` or any other currently-passing
  test to make numbers look better.
- Do not remove the accent theming entirely to sidestep the sizing problem -- shrink it, don't delete it.
- Do not change any widget keys (`community-entry-gate`, `community-entry-refresh-button`,
  `community-auth-screen-$_entryGateRevision`, `issue-invite-button`, `issued-invite-code`,
  `persona-picker-button`, `open-signup-submit`, `redeem-invite-submit`) -- re-run
  `rg -n "ValueKey\(" app/packages/core/loom_communities_app_shell/lib/src/part31_auth_screens.dart
  app/packages/core/loom_communities_app_shell/lib/src/part01_local_extension_screen.dart` before and after
  your change and confirm the same key set is present.

## Required verification

1. `flutter analyze` on `packages/core/loom_communities_app_shell` -- clean.
2. `flutter test test/v3_calr4b_individual_sign_in_ui_test.dart` run **3 times in a row** -- must pass all 3
   times (not just once; the original bug was 100% deterministic, so the fix's proof bar is the same).
3. Full `loom_communities_app_shell` test suite -- must return to exactly one known failure (the pre-existing
   a11 flake named above), no others.
4. If your sandbox cannot run `flutter analyze`/`flutter test`, say so plainly -- independent verification
   will be re-run outside the sandbox regardless (this is exactly what caught this regression in the first
   place, since AuthZ.P7 itself could not verify anything before its STATUS report).

## Git safety reminder

This repository lives on a OneDrive-synced path. OneDrive's background sync occasionally races with git's own
atomic index writes, producing errors like `fatal: unable to write new index file` or a stale/stuck
`.git/index.lock`. This is a known, transient environment quirk, not a sign anything is broken, and requires
no creative recovery. On an index-lock error: `rm -f .git/index.lock`, wait ~2 seconds, retry the same
command once. If it fails again, STOP -- do not run `git reset --hard`, any broad `--cached` unstage, or
recreate `.git/index` by hand. Report the exact error in your STATUS response and leave the working tree
as-is.

## Commit

One commit, once verified, covering both the original AuthZ.P7 changes (already in the working tree,
uncommitted) and this fix together: `style: apply community accent theming to the auth and entry-gate
screens (AuthZ.P7, incl. fix1 for the sign-in test regression)`.

## Required response format (write to `data/v3_ticket_authz_p7_fix1_STATUS.md`)

```
# Ticket status: AuthZ.P7 fix1

## Root cause found
Confirmed mechanism, with evidence (not just the hypothesis above restated).

## Change applied
Status: done | blocked
Exact file:line, exact before/after values changed, and why those specific numbers were chosen.

## Verification
flutter analyze: clean/not clean.
v3_calr4b_individual_sign_in_ui_test.dart: 3/3 runs, pass/fail each.
Full suite: pass count, confirm only the known a11 flake remains.

## Commit
Commit hash, or "staged, not committed" + exact blocker.
```
