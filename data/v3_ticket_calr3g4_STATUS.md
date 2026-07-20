# Ticket status: CALR.3g4 tap investigation

## Root cause found

The failing test was deriving the tap point while the `Scaffold` was still
bringing its newly-added, extended single-action FAB into its paint/hit-test
layer.  The evidence is the failure's own `RenderMergeSemantics ...
NEEDS-PAINT` target and the `RenderAnimatedOpacity`/`_RenderTheater`/
`RenderAbsorbPointer` chain.  Flutter's `Scaffold` implements an entrance
transition for a newly supplied `floatingActionButton`; for an extended FAB it
uses scale and fade transitions around that child.  The real fixture is the
only test here that taps that direct, extended-FAB branch.  The passing
speed-dial test first taps a different, non-extended trigger; the stacked and
singleFirst cases only assert widget presence.

Reading the app tree also rules out the earlier scrolling theory: the legacy
`engine-native-calendar-new-event` button is in the calendar `Column` inside
the `SingleChildScrollView`, while the new FAB is supplied through the
top-level `Scaffold.floatingActionButton` slot.  Therefore it cannot be made
hit-testable with `ensureVisible`, and no frozen fixture data is involved.

I could not execute the Flutter test to measure the extra frame in this
sandbox: Flutter exits before running tests because its read-only SDK/analytics
cache cannot persist its session/engine metadata.  The timing conclusion is
therefore based on the observed render trace and Flutter Scaffold source,
rather than a local passing run.

## Fix applied

Status: done.

Updated `app/packages/core/loom_communities_app_shell/test/v3_calr3g_creatable_action_fab_test.dart` only.  After selecting Calendar, the real-fixture test now advances 50 ms before locating and tapping the direct extended FAB, allowing the Scaffold entrance transition to paint it.  Removed the ineffective `ensureVisible` and its zero-duration pump.  No production code, frozen JSON, or reference documentation changed.

## Verification

dart analyze: clean (direct Dart SDK invocation reported `No issues found`; its subsequent read-only telemetry write error did not affect the analyze result).

Test suite: blocked: `flutter test` could not start because the sandbox prevents Flutter/Dart from writing `/home/fahd_/.dart-tool/dart-flutter-telemetry-session.json` (and the Flutter SDK cache is read-only).  The change is reasoned but not self-verified by Flutter tests in this sandbox.

## Commit

Staged, not committed: pending final git safety/count check and commit.
