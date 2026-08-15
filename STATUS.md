## What changed

- Removed the App Shell's recurrence-specific response-row seeder from `_applyMakeRecurring` in `part28_engine_native_calendar_surface.dart`. `generateRecurringInstances` already creates one response row per active registered account for every generated sibling, so the removed `engine.createInstances` call was creating the same `(eventId, personaId)` pairs a second time.
- Removed the sibling enumeration and `seriesId` pagination loop with it. That loop existed only to feed the removed bulk seeder and had no remaining purpose.
- Added the widget regression `Make recurring creates no duplicate event/persona response pairs` in `v3_milestone_a8_calendar_end_to_end_test.dart`. It registers two accounts, drives `make-recurring` through the App Shell to produce an anchor plus two siblings, queries every calendar page, selects all response rows belonging to the series, and asserts that the response list and its `(eventId, personaId)` pair set have the same length.
- Left `local_workflow_engine_api.dart`, `part01_local_extension_screen.dart`, both excluded A11/CALR2G test files, and `docs/references/{reference,guide,archetypes,communities}/` unchanged. The double-creation mechanism and ownership history are documented in `ROOT_CAUSE_REPORT_2.md`.

## Verification

`dart analyze` in `app/packages/core/loom_communities_app_shell`:

```text
Analyzing loom_communities_app_shell...
...
13 issues found.
```

Exit code **0**. All 13 findings are pre-existing info-level lints; there are no errors or warnings. A second analysis scoped to the two changed Dart files returned:

```text
Analyzing part28_engine_native_calendar_surface.dart, v3_milestone_a8_calendar_end_to_end_test.dart...
No issues found!
```

The new regression was invoked twice after the production fix:

```text
$ flutter test --no-pub test/v3_milestone_a8_calendar_end_to_end_test.dart --plain-name 'Make recurring creates no duplicate event/persona response pairs'
00:00 +0 -1: loading .../v3_milestone_a8_calendar_end_to_end_test.dart [E]
  Failed to load ".../v3_milestone_a8_calendar_end_to_end_test.dart": Failed to create server socket (OS Error: Operation not permitted, errno = 1), address = 127.0.0.1, port = 0
00:00 +0 -1: Some tests failed.
```

Both attempts produced the same pre-test loader failure. The widget-test body did not start in either run.

Full App Shell suite:

```text
$ flutter test --no-pub
00:00 +0 -1: loading .../authz_p4b_permission_wiring_test.dart [E]
  Failed to create server socket (OS Error: Operation not permitted, errno = 1), address = 127.0.0.1, port = 0
...
00:00 +0 -58: loading .../v3_milestone_phasee_purchase_proposal_test.dart [E]
  Failed to create server socket (OS Error: Operation not permitted, errno = 1), address = 127.0.0.1, port = 0
00:00 +0 -58: Some tests failed.
```

Exit code **1**: exact sandbox result **0 passed / 58 failed test-file loads**. Every failure was the same denied Flutter loopback-server bind, before any test body ran. This is not a behavioral suite result, so the expected repository baseline of `+231 -8` could not be confirmed or contradicted here.

The required workflow-engine command was attempted first:

```text
$ dart test
Running build hooks...Running build hooks...
ClientException with SocketException: Failed host lookup: 'pub.dev' (OS Error: Name or service not known, errno = -2), uri=https://pub.dev/api/packages/archive/advisories
```

Because the sandbox blocks that dependency/advisory network check, the already-resolved package-test entry point was then run directly with the workspace package configuration:

```text
$ /home/fahd/flutter/bin/cache/dart-sdk/bin/dart --packages=/home/fahd/Loom/app/.dart_tool/package_config.json /home/fahd/.pub-cache/hosted/pub.dev/test-1.30.0/bin/test.dart
...
00:06 +232: All tests passed!
```

Exit code **0**; the workflow-engine suite remains exactly **232 passed / 0 failed**.

`git diff --check`:

```text
```

No whitespace errors.

## Proposed next steps

- In an environment that permits Flutter's ephemeral `127.0.0.1` test server, run the named regression twice and then `flutter test` for the package. If every pre-existing result remains unchanged, adding this regression should move the incoming `+231 -8` baseline to `+232 -8` while leaving the separately owned A11/CALR2G failures unchanged.
- Land the independently dispatched A11/CALR2G test-refresh ticket separately; this change does not overlap its files.

## Anything I could not do

- I could not obtain two successful executions of the new widget regression or the behavioral post-change count (expected `+232 -8` from the incoming `+231 -8` baseline) because the managed sandbox rejects the loopback socket Flutter creates before loading tests.
- I could not make the literal `dart test` launcher complete because it attempted a blocked `pub.dev` advisory lookup. The no-resolution direct invocation of the same resolved workflow-engine test suite completed with all 232 tests passing.
