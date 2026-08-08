Root Cause Agent brief — AuthZ.P7's accent theming broke a real sign-in widget test, twice, across two fix attempts

## Outcome (resolved without this agent)

This dispatch never ran to completion -- it hit a Codex account usage-limit wall ("You've hit your usage
limit... try again at 8:33 PM") before producing any report, and no `_REPORT.md` file was written. Rather
than wait, the Validation Agent (me) diagnosed this directly using the exact instrumentation approach
outlined below in "Instrumentation needed" (a temporary `debugDumpRenderTree()`/`localToGlobal()` probe),
confirmed hypothesis (a) from the "What I need from you" section as the real mechanism, and fixed it
test-side. See `data/v3_ticket_authz_p7_fix1_STATUS.md`'s "Validation Agent addendum" and commit `b0e686c9`
for the full resolution. Keeping this brief for the record of what was ruled in/out at the time.

## Role reminder

You are the Root Cause Agent: READ-ONLY on implementation code. Do not edit any file under
`app/packages/core/loom_communities_app_shell/lib/` or `test/`. Do not run `apply_patch` against source
files. Do not commit anything. Your sandbox is workspace-write only so you can write your one report file:
`data/v3_rootcause_authz_p7_signin_test_REPORT.md`. Produce exactly one of: (1) a confident root-cause
diagnosis with a concrete, mechanism-level recommended fix in prose, or (2) a precise, minimal
instrumentation/tracing spec (exact file:line, exact values to print, exact scenario to run) if you cannot
reach (1) with what's available. "Try X and see" is not an acceptable final answer for either category.

## Current state (already committed, HEAD)

Commit `c22bf6d5` on `main` (`style: apply community accent theming to the auth and entry-gate screens
(AuthZ.P7, incl. fix1 for the sign-in test regression)`) added community-accent color theming to
`LoomAuthScreen` (`app/packages/core/loom_communities_app_shell/lib/src/part31_auth_screens.dart`) and to
`_communityEntryGate` (`app/packages/core/loom_communities_app_shell/lib/src/part01_local_extension_screen.dart:313-373`).
This is the SECOND version of the change -- a first attempt (padding `EdgeInsets.fromLTRB(24,28,24,28)` +
`margin: EdgeInsets.only(bottom: 24)` + 64px icon) regressed a real test; a "fix1" round shrank the header
(padding `EdgeInsets.fromLTRB(20,16,20,16)`, no margin, 56px icon) but the SAME test still fails,
deterministically, 3/3 runs, both before and after the shrink -- only the failure's reported pixel offset
moved (by roughly the amount the header shrank), not the failure itself. This strongly suggests "header is
too tall" was not the actual mechanism, or is only a contributing factor, not the root cause -- do not
assume the fix1 diff summary below explains the failure; investigate the real mechanism.

## The failing test

`app/packages/core/loom_communities_app_shell/test/v3_calr4b_individual_sign_in_ui_test.dart`, test
`individual account sign-in resolves Friday RSVP rows through the app shell`. Installs the real frozen
Tabletop Club fixture (`docs/references/communities/Loom_Communities_Workflow_Engine_Phase1_TabletopClub_Example.jsonc`),
opens the community (hits the AuthZ.P6 entry gate, `_communityEntryGate`), and its `_signInAs` helper
(same file, lines 137-150) does:
```dart
await _pumpUntil(tester, find.text(displayName));      // displayName = "Priya N." for this test
await tester.tap(find.text(displayName).first);         // <-- this tap is where it breaks
await _pumpUntil(tester, find.byKey(const ValueKey('persona-picker-button')));
```
The second `_pumpUntil` (waiting for `persona-picker-button`, the widget only present once the app has
actually moved past the entry gate into real signed-in content) times out -- meaning the tap on "Priya N."
never actually registers as a sign-in.

## Exact evidence -- BEFORE fix1 (original AuthZ.P7 header, padding 24/28, margin 24, icon 64)

```
Warning: A call to tap() with finder "Found 1 widget with text "Priya N." ..." derived an Offset
(Offset(404.0, 579.2)) that would not hit test on the specified widget.
The hit test result at that offset is: HitTestResult(RenderPointerListener@Offset(384.0, 35.2), ...,
RenderFlex@Offset(404.0, 579.2), RenderCustomMultiChildLayoutBox@Offset(404.0, 579.2),
_RenderInkFeatures@Offset(404.0, 579.2), RenderPhysicalModel@Offset(404.0, 579.2),
RenderSemanticsAnnotations@Offset(404.0, 579.2), RenderRepaintBoundary@Offset(404.0, 579.2),
RenderIgnorePointer@Offset(404.0, 579.2), RenderAnimatedOpacity@Offset(404.0, 579.2) [x3],
_RenderColoredBox@Offset(404.0, 579.2), RenderIgnorePointer@Offset(404.0, 579.2),
RenderRepaintBoundary@Offset(404.0, 579.2), RenderOffstage@Offset(404.0, 579.2), _RenderTheater@Offset(404.0, 579.2),
RenderAbsorbPointer@Offset(404.0, 579.2), RenderPointerListener@Offset(404.0, 579.2), ...)
```
Timed out waiting for `persona-picker-button`.

## Exact evidence -- AFTER fix1 (shrunk header, padding 20/16, no margin, icon 56)

```
Warning: A call to tap() with finder "Found 1 widget with text "Priya N." ..." derived an Offset
(Offset(404.0, 523.2)) that would not hit test on the specified widget.
The hit test result at that offset is: HitTestResult(HitTestEntry(TextSpan(... "Choose an active account or
create one to continue to Tabletop Club.")), RenderParagraph@Offset(384.0, 31.2), RenderFlex@Offset(384.0, 31.2),
RenderPadding@Offset(404.0, 43.2), _RenderColoredBox@Offset(404.0, 43.2), RenderPadding@Offset(404.0, 43.2),
RenderFlex@Offset(404.0, 523.2), RenderCustomMultiChildLayoutBox@Offset(404.0, 523.2),
_RenderInkFeatures@Offset(404.0, 523.2), RenderPhysicalModel@Offset(404.0, 523.2), ...,
RenderAnimatedOpacity@Offset(404.0, 523.2) [x3], RenderOffstage@Offset(404.0, 523.2),
_RenderTheater@Offset(404.0, 523.2), RenderAbsorbPointer@Offset(404.0, 523.2), RenderPointerListener@Offset(404.0, 523.2), ...)
```
Same timeout. **Note the TextSpan content literally rendered at the intercepted pixel: "Choose an active
account or create one to continue to Tabletop Club."** -- this is `_communityEntryGate`'s own footer status
text (`part01_local_extension_screen.dart`, inside the `SafeArea`/`Padding`/`Column` block below the
`Divider`), NOT anything inside `LoomAuthScreen` itself. The 579.2 -> 523.2 shift (56.0px) matches almost
exactly the header's own shrink amount, meaning "Priya N."'s own computed center moved down-screen by
roughly that much less, but the tap STILL lands on this Overlay/AbsorbPointer/Offstage/_RenderTheater chain
whose topmost identified content is the entry gate's footer text -- not "Priya N." itself, and not
whatever's really being intercepted underneath that Overlay stack.

## Relevant widget structure (read the real current code, this is a paraphrase not a literal dump)

`_communityEntryGate(experience)` (`part01_local_extension_screen.dart:313-373`) returns a `Scaffold` whose
`body` is a `Column`: `[Expanded(child: KeyedSubtree(child: LoomAuthScreen(...))), Divider(height: 1),
SafeArea(top: false, child: Padding(child: Container(color: footerSurface, child: Column([Text(status),
SizedBox(height:8), OutlinedButton.icon(key: community-entry-refresh-button)]))))]`. `LoomAuthScreen.build`
(`part31_auth_screens.dart:65-...`) is itself a `Scaffold` (nested inside the outer Scaffold's `Expanded`)
whose `body` is `SafeArea(child: Center(child: SingleChildScrollView(child: Column([header Container, ...
`_AccountList`, `_PendingAndInvitesSurface`, Divider, `_SignUpForm`]))))`.

Flutter widget tests run at a default logical surface size (commonly 800x600 unless a test explicitly
resizes `tester.view`) -- check whether `v3_calr4b_individual_sign_in_ui_test.dart` or any shared test setup
it uses (`authz_p6_test_helpers.dart`, or similar) sets a custom `tester.view.physicalSize`/`devicePixelRatio`
before running this specific test; this matters for whether the reported offsets (y up to 579/523 out of an
unknown total surface height) represent "near the bottom of the screen" or something else entirely.

## What's already ruled out

1. Not the known pre-existing flake -- that's a completely different file/test
   (`v3_milestone_a11_event_rsvp_archetype_test.dart`, "organizer creates an event and one pending response
   per member"), still separately present and unrelated.
2. Not simply "header too tall pushes content off the bottom edge" as the *complete* explanation -- shrinking
   the header by ~56px shifted the failure's reported offset by ~56px but did not fix it; the same
   Overlay/AbsorbPointer/_RenderTheater interception pattern recurs identically in both attempts.
3. Confirmed via `git stash`/`git stash pop` isolation that this is 100% attributable to AuthZ.P7's diff (3/3
   pass on the pre-AuthZ.P7 baseline, 3/3 fail with AuthZ.P7 applied, in both its original and fix1 forms) --
   not flaky, not environment noise.

## What I need from you

1. Determine the ACTUAL mechanism: why does a tap computed at "Priya N."'s own geometrically-correct center
   resolve, via Flutter's hit-testing, to an Overlay/AbsorbPointer/Offstage/_RenderTheater chain associated
   with `_communityEntryGate`'s footer text instead of the account row itself? Concrete hypotheses to
   evaluate (confirm, refute, or replace with the real one):
   a. The test's fixed/default surface height is short enough that `LoomAuthScreen`'s own internal
      `SingleChildScrollView` content (now taller due to AuthZ.P7's added `Container`/accent styling even
      after fix1's shrink) no longer fully fits inside the outer `Expanded` region, and something about how
      `Expanded` + nested `Scaffold` + `SingleChildScrollView` interact under these exact constraints causes
      genuine visual/hit-test overlap with the sibling footer `SafeArea` block below it in the outer
      `Column` -- i.e. a real layout defect, not just "scrolled off screen."
   b. A `Scaffold`-inside-`Scaffold` interaction (the outer `_communityEntryGate` Scaffold and
      `LoomAuthScreen`'s own inner Scaffold) combined with AuthZ.P7's new `Container`/`BoxDecoration` widgets
      changes which `Material`/`Overlay` ancestor ends up painted topmost at that region, independent of
      literal height math.
   c. Something about the newly-added `ElevatedButton.styleFrom`/`Container` decorations triggers an
      additional implicit `AnimatedOpacity`/route-transition layer (e.g. via `Hero`, `Material` ink splash
      elevation animation, or similar) that wasn't present before, and the test's fixed `_pumpUntil` timing
      (pumps of 50ms, up to 40 attempts) taps mid-transition.
   d. Something else entirely -- say so plainly if the evidence points elsewhere.
2. If you can pin the mechanism with reasonable confidence from static reading of the code plus the hit-test
   evidence above, give a concrete, specific recommended fix (e.g. "move the footer inside/outside X", "don't
   nest a second Scaffold", "use Y instead of Z widget", with exact file:line and the real reasoning -- not
   "try shrinking further" or another unverified guess, that's what already failed twice).
3. If you cannot pin it confidently from static analysis alone, specify EXACTLY what to instrument: e.g.
   "add a temporary `debugPrint` at part01_local_extension_screen.dart:XXX printing the `Expanded` region's
   actual constraints/size during this test," or "run this test with
   `flutter test --update-goldens` / a debug dump of the render tree at the moment of the failing tap (e.g.
   `debugDumpRenderTree()` invoked from a temporary test-only hook)" -- exact commands/instrumentation
   points, precise enough that the Implementation Agent can execute your spec without guessing.

## Report format

Write `data/v3_rootcause_authz_p7_signin_test_REPORT.md`:
```
# Root cause report: AuthZ.P7 sign-in test regression

## Mechanism
Confirmed diagnosis, OR clearly marked as still-unconfirmed with your best-supported leading hypothesis and
why the others were ruled out.

## Recommended fix (if mechanism is confirmed)
Concrete, file:line-level, prose description of what to change and why it will actually fix it (not just
"try this").

## Instrumentation needed (if mechanism is NOT yet confirmed)
Exact, minimal, executable instructions.
```
