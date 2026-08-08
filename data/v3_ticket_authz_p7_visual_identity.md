Ticket AuthZ.P7 — apply community accent theming to the auth/entry-gate screens

## Context

Follow-up to the AuthZ.P1-P6 authorization hardening effort (all merged and independently verified:
persona-picker fix, identity-context refactor, JSON grammar, read-path filtering, permission enforcement,
membership/invite flows, community-open entry gate). This ticket is pure visual polish on top of already-
verified, already-locked authorization logic -- **no functional/authorization behavior changes at all.**

Independent verification of AuthZ.P6 included running this repo's real B25 pixel-heuristic visual judge
(`app/packages/tooling/loom_ux_judges/bin/b25_visual_inspection_auditor.dart`) against real emulator
screenshots of the new entry-gate and account-creation screens. It found genuine, reproducible findings on
every one of them: `B25-WEAK-VISUAL-IDENTITY` (near-zero community-accent-color pixel presence),
`B25-THIN-CONTENT-LIKELY` (very sparse layout, especially on first open before any accounts exist), and
`B25-DEFAULT-SCAFFOLD-LIKELY` (reads as an unstyled generic Flutter scaffold). These are legitimate --
confirmed by direct code read, not just the heuristic: `LoomAuthScreen.build`
(`app/packages/core/loom_communities_app_shell/lib/src/part31_auth_screens.dart:66-98`) already receives
`widget.experience` (which carries `accentColor`) but never uses it -- the header icon, "Welcome to Loom"
title, and buttons all use the *global app* `Theme.of(context).colorScheme`, not the community's own accent.
Same gap in `_communityEntryGate` (`part01_local_extension_screen.dart:313-360`): a plain `Scaffold` with a
plain `Text`/`OutlinedButton.icon`, no accent applied at all.

**The correct pattern already exists elsewhere in this exact file and is proven/shipped** --
`_CommunityLaunchCard.build` (`part01_local_extension_screen.dart:36-43`):
```dart
final accent = Color(experience.accentColor);
final background = isFocused
    ? Color.alphaBlend(accent.withValues(alpha: 0.10), Colors.white)
    : Color.alphaBlend(accent.withValues(alpha: 0.05), Colors.white);
```
This ticket is: apply that same, already-established accent-theming pattern to the auth/entry-gate screens
too, so they read as belonging to the specific community being joined rather than a generic unbranded form --
never invent a new/different theming mechanism.

## Scope

1. `LoomAuthScreen.build` (`part31_auth_screens.dart:66-98`): resolve `final accent =
   Color(widget.experience.accentColor);` and use it -- header icon color, a subtle accent-tinted background
   or header band (reuse the `Color.alphaBlend(accent.withValues(alpha: ...), Colors.white)` pattern from
   `_CommunityLaunchCard`, don't invent new blend math), and primary action buttons (`ElevatedButton` for
   sign-up/retry) using the accent as their background/foreground per Material's own `ElevatedButton.styleFrom`
   convention.
2. `_communityEntryGate` (`part01_local_extension_screen.dart:313-360`): apply the same accent to the
   `OutlinedButton.icon` ("Check membership status") and consider a light accent-tinted background behind the
   bottom status/action section (the `SafeArea`/`Padding`/`Column` block at lines 331-356), so the gate reads
   as themed, not a bare default scaffold. Leave `_communityEntryChecking` (lines 306-311, the brief loading
   spinner) alone -- it's on screen too briefly for this to matter, and adding theming there risks a visible
   flash/flicker between it and the gate.
3. `_AccountList`/`_SignUpForm`/`_PendingAndInvitesSurface` (rest of `part31_auth_screens.dart`): thread
   `experience`/accent through if useful for consistency (e.g. the selected/focused state of an account row),
   but the header + primary buttons in scope item 1 are the actual fix -- don't over-scope into a full visual
   redesign of every row and control in these widgets.
4. Specifically target the B25 findings: `B25-THIN-CONTENT-LIKELY` fires on screens with very few visually
   distinct content bands -- a themed header band (icon + title on an accent-tinted surface, not just plain
   white) is expected to also address this, not just `B25-WEAK-VISUAL-IDENTITY`. Do not add unrelated content
   or padding purely to defeat this heuristic; the accent theming itself should be sufficient. If it isn't,
   say so plainly in your STATUS response rather than padding the screen with filler.

## Do not do

- Do not touch any AuthZ.P1-P6 authorization/permission/membership logic -- `LocalAuthApi`, `personaHasPermission`,
  `_requireAdminAccount`, `_requireSurfacePermission`, `ActiveIdentityScope`, the entry-gate's three-state
  logic (`_communityEntryAllowed`), or any JSON grammar. This ticket only changes colors/visual chrome.
- Do not add or change any JSON field.
- Do not change widget keys already relied on by existing tests (`community-entry-gate`,
  `community-entry-refresh-button`, `community-auth-screen-$_entryGateRevision`, `issue-invite-button`,
  `issued-invite-code`, etc.) -- verified via `grep -rn "ValueKey('community-entry\|ValueKey('issue"`
  `app/packages/core/loom_communities_app_shell/test/` before changing anything nearby, and confirm this
  check was actually run in your STATUS response.
- Do not invent a new accent-blending helper -- reuse `Color.alphaBlend(accent.withValues(alpha: ...),
  Colors.white)` exactly as `_CommunityLaunchCard` already does.
- Do not change behavior for legacy-schema communities (`experience.workflowDefinitions == null || .isEmpty`)
  -- they bypass the entry gate entirely already (untouched by this ticket) and `experience.accentColor` still
  resolves safely for them via its existing default, so no special-casing should be needed; confirm this
  rather than assume it.

## Required verification

1. `flutter analyze` on `packages/core/loom_communities_app_shell` -- clean.
2. Full `loom_communities_app_shell` test suite -- identical pass count to the current baseline (this is a
   pure visual/color change; any test-outcome diff is a regression, not an expected new-feature test, unless
   a widget test specifically asserted the *absence* of theming, in which case say so explicitly).
3. If your sandbox cannot run `flutter analyze`/`flutter test`, say so plainly -- independent verification
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

One commit, once verified: `style: apply community accent theming to the auth and entry-gate screens
(AuthZ.P7)`.

## Required response format (write to `data/v3_ticket_authz_p7_visual_identity_STATUS.md`)

```
# Ticket status: AuthZ.P7

## Change applied
Status: done | blocked
Exact file:line for each accent application. Confirm the widget-key grep check was run and nothing broke.
Confirm no JSON grammar and no AuthZ.P1-P6 logic was touched.

## Verification
flutter analyze: clean/not clean.
Test suite: pass count, before/after.

## Commit
Commit hash, or "staged, not committed" + exact blocker.
```
