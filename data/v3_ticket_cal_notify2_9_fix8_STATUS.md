# Ticket status: CAL.Notify2.9 fix8

## Change applied
Status: done

## Design notes

Removed only the redundant `calendar-tab-surface` wait that fix7 added after the
calendar-tab tap in each helper:

- `app/packages/core/loom_communities_app_shell/test/v3_milestone_a8_calendar_end_to_end_test.dart`:
  `_selectCalendarTab` now waits for the calendar tab, ensures it is visible, taps it,
  pumps once, and returns. The helper no longer waits for `calendar-tab-surface`.
- `app/packages/core/loom_communities_app_shell/test/v3_milestone_a11_event_rsvp_archetype_test.dart`:
  `_selectCalendar` has the same four-line wait removed and otherwise remains unchanged.

No other test, helper, production file, fixture, or test assertion needed adjustment.
The existing caller-level waits for more specific calendar widgets remain in place,
as does the a8 `findsNothing` assertion for `calendar-tab-surface`.

## Verification

- The targeted `organizer creates an event and one pending response per member` test:
  blocked before test discovery. The Flutter test runner could not create its
  `127.0.0.1` server socket (`Operation not permitted`).
- The targeted `new event control is hidden from a non-creatable persona` test:
  blocked before test discovery for the same socket restriction.
- The targeted `App Shell selects the frozen engine-native Calendar through its shared engine`
  test: blocked before test discovery for the same socket restriction.
- Full a8 test file: blocked before test discovery; pass count unavailable. The runner
  failed while starting `flutter_tester` with the same `127.0.0.1` socket restriction.
- Full a11 test file: blocked before test discovery; pass count unavailable. Same blocker.
- Full `loom_communities_app_shell` suite: blocked before test execution; `0` tests
  executed and `46` test-file load failures were reported, so there is no valid suite
  pass count to report against the `167/167` target.
- Full `loom_workflow_engine` suite: `192/192` passed; unaffected.
- `flutter analyze` on both packages: not runnable in this sandbox. The Flutter wrapper
  failed before analysis with the WSL interop/vsock error. Direct Dart analyzer fallback
  found no issues in `loom_communities_app_shell`; `loom_workflow_engine` had no errors
  and its 21 existing informational `prefer_const_constructors` hints.

## Commit
staged, not committed + the requested single commit is pending; the exact hash will be reported in the final response.
