# Ticket status: CAL.Notify2.9 fix10

## Change applied
Status: done

## Design notes

The date-picker step tapped day `15` and immediately waited for the date
picker's `OK` button without yielding a frame. The working event-time step
immediately after it includes that frame pump, so the date-picker interaction
could be observed before Flutter rebuilt the dialog after the day selection.

The target test source contains no other `find.text('15')` use, and the editor
uses Flutter's standard `showDatePicker`; no competing finder match was found
that required replacing `.last`. The exact fix was one line, added immediately
after `await tester.tap(find.text('15').last);`:

```dart
await tester.pump();
```

No helper, production code, frozen fixture, reminder test, or other test was
modified.

## Verification

Target test, run twice:

- Run 1: blocked before test discovery. The Flutter tester could not create
  its local `127.0.0.1` server socket (`Operation not permitted`, port `0`).
- Run 2: blocked before test discovery for the same socket restriction.

Full a11 test file: blocked before test discovery by the same Flutter tester
socket restriction; no pass count is available.

Full `loom_communities_app_shell` suite: blocked before test execution. The
runner attempted all 46 test files, executed 0 test bodies, and reported 46
test-file load failures from the same `127.0.0.1` socket error. The required
167/167 result could not be verified in this sandbox; the verification agent
must run it independently.

Full `loom_workflow_engine` suite: 192/192 passed; unaffected.

`flutter analyze` (both packages):

- `loom_communities_app_shell`: clean (`No issues found!`).
- `loom_workflow_engine`: not clean under the analyzer's strict exit status
  because of 21 pre-existing informational `prefer_const_constructors`
  issues in `test/v3_milestone_aprime_grammar_extensions_test.dart`; no
  errors or warnings were introduced by this ticket.

## Commit
staged, not committed + the required Flutter widget-test verification is
blocked by the sandbox's local-server socket restriction; the exact commit
hash will be reported after the single requested commit.
