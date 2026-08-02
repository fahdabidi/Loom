# Ticket status: CAL.Notify2.9 fix9

## Change applied
Status: done

## Design notes

The remaining failure was specific to this test's real `LocalExtensionScreen`
App Shell path. `_selectCalendar` only pumps the first frame after selecting
Calendar, while the engine-native Calendar surface is still loading and
publishing its follow-up frame. The calendar create FAB can therefore already
match the finder while the speed-dial animation's `IgnorePointer` still blocks
the event action. `_pumpUntil(tester, createEvent)` checked only widget
presence, so the tap could be missed and no creation sheet/editor was opened;
the later `new-event-editor-title` wait then timed out.

The fix is scoped to this file's `_openEventCreation` flow. It first polls for
`engine-native-calendar-root`, then polls the event FAB until it is present,
not ignored by an ancestor `IgnorePointer`, and has no pending animation or
scheduled frame before tapping it. The existing condition-based title wait is
unchanged. `_selectCalendar` in this file and `_selectCalendarTab` in the a8
file were not modified. No production code, frozen fixture, or reminder test
was changed.

## Verification

Target test run twice:

- Run 1: blocked before test discovery. Flutter could not create its local
  `127.0.0.1` server socket (`Operation not permitted`), so the test did not
  execute.
- Run 2: blocked before test discovery for the same socket restriction; the
  test did not execute.

Full a11 test file: blocked before test discovery by the same Flutter tester
socket restriction; no pass count is available.

Full a8 test file: blocked before test discovery by the same Flutter tester
socket restriction; no pass count is available.

Full `loom_communities_app_shell` suite: blocked before test execution. The
runner attempted all 46 test files, executed 0 tests, and reported 46 test-file
load failures from the same `127.0.0.1` socket error; 167/167 could not be
verified in this sandbox.

Full `loom_workflow_engine` suite: 192/192 passed; unaffected.

`flutter analyze`:

- `loom_communities_app_shell`: clean (`No issues found!`).
- `loom_workflow_engine`: no errors, but not clean under the analyzer's strict
  exit status because of 21 pre-existing informational
  `prefer_const_constructors` hints.

## Commit
staged, not committed + the required widget-test verification is blocked by
the sandbox's `flutter_tester` local-server socket restriction; the exact
commit hash will be reported after the single requested commit.
