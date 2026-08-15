## What changed

- Updated `v3_calr3h1_slideoutright_presentation_test.dart` so event submission waits for the observable disappearance of the creation `AlertDialog` instead of relying on ten fixed settle iterations. The new bounded poll continues to interleave real async time and widget pumps, and its timeout reports any visible `new-event-error` text so a real submit failure is not mistaken for slow route dismissal.
- Updated `v3_milestone_a8_calendar_end_to_end_test.dart` so `_InstalledTabletop` carries the exact account IDs registered with `LocalWorkflowEngineApi.setPersonaType`. The recurring-event assertion now verifies that the registered fixture has 13 identities, that each generated sibling has exactly 13 response rows, and that the response identity set exactly equals the registered set.
- Added `ROOT_CAUSE_REPORT.md`, the read-only investigation cited by this fix. It records why both changes are test-only and why the production fan-out must remain synchronous.
- Did not change production or engine code, `part28_engine_native_calendar_surface.dart`, the seven separately tracked fan-out target failures, the Admin-tab test, or anything under `docs/references/{reference,guide,archetypes,communities}/`.

## Verification

`/home/fahd/flutter/bin/cache/dart-sdk/bin/dart analyze` in `app/packages/core/loom_communities_app_shell`:

```text
Analyzing loom_communities_app_shell...
...
13 issues found.
```

Exit code **0**. The 13 findings are the package's existing info-level lints; there are no errors or warnings and no finding in either edited test.

The first required focused invocation was attempted with the writable Flutter SDK mirror:

```text
$ /tmp/loom-flutter-sdk/bin/flutter test --no-pub -r expanded test/v3_calr3h1_slideoutright_presentation_test.dart --plain-name 'slideOutRight presents and submits the same event creation flow'
00:00 +0 -1: loading .../v3_calr3h1_slideoutright_presentation_test.dart [E]
  Failed to load ".../v3_calr3h1_slideoutright_presentation_test.dart": Failed to create server socket (OS Error: Operation not permitted, errno = 1), address = 127.0.0.1, port = 0
00:00 +0 -1: Some tests failed.
```

Retrying with Flutter's `--ipv6` option produced the same `127.0.0.1` tester-device socket failure. The test body did not load in either attempt.

The second required focused invocation failed at the same environment boundary:

```text
$ /tmp/loom-flutter-sdk/bin/flutter test --no-pub -r expanded test/v3_milestone_a8_calendar_end_to_end_test.dart --plain-name 'Make recurring creates calendar occurrences and seeds every RSVP response row'
00:00 +0 -1: loading .../v3_milestone_a8_calendar_end_to_end_test.dart [E]
  Failed to load ".../v3_milestone_a8_calendar_end_to_end_test.dart": Failed to create server socket (OS Error: Operation not permitted, errno = 1), address = 127.0.0.1, port = 0
00:00 +0 -1: Some tests failed.
```

The full app-shell command was also attempted:

```text
$ /tmp/loom-flutter-sdk/bin/flutter test --no-pub -r compact
00:03 +0 -1: loading .../authz_p4b_permission_wiring_test.dart [E]
  Failed to load ".../authz_p4b_permission_wiring_test.dart": Failed to create server socket (OS Error: Operation not permitted, errno = 1), address = 127.0.0.1, port = 0
...
00:34 +0 -21: loading .../v3_calr3h1_popup_presentation_test.dart [E]
  Failed to load ".../v3_calr3h1_popup_presentation_test.dart": Failed to create server socket (OS Error: Operation not permitted, errno = 1), address = 127.0.0.1, port = 0
```

The run was stopped with exit code **130** after 21 identical pre-test load failures. No test body ran, so this sandbox did not produce a 239-test behavioral total and the target `+231 -8` is not claimed as verified.

`/home/fahd/flutter/bin/cache/dart-sdk/bin/dart test -r compact` in `app/packages/core/loom_workflow_engine`:

```text
Running build hooks...Running build hooks...
...
00:08 +232: All tests passed!
```

Exit code **0**; the engine total remains exactly **232 passing**.

`dart format` on both edited tests:

```text
Formatted 2 files (0 changed) in 0.05 seconds.
```

`git diff --check`:

```text
```

(No output; clean.)

## Proposed next steps

- In an environment that permits Flutter's ephemeral loopback tester socket, run each named `--plain-name` test at least three times and then run the full app-shell suite. The required acceptance result remains 239 loaded tests with `+231 -8`: these two regressions closed and the eight known failures unchanged.
- Continue the existing separate investigation for the six A11 failures and one CALR2g failure; this fix deliberately does not alter or mask them.

## Anything I could not do

- I could not execute either edited widget-test body, repeat it three successful times, or obtain the full app-shell `+231 -8` result because the managed sandbox rejects the `127.0.0.1` server socket that Flutter opens before loading every test. The failure is before test compilation/execution and is unchanged under `--ipv6`.
