## What changed

- Built directly on `cd07d943` (`fix(calendar): stop duplicate recurring RSVP
  fan-out`). `f29177d3` is not in this commit's ancestry. No engine file, no
  `_applyMakeRecurring` code, and no file under
  `docs/references/{reference,guide,archetypes,communities}/` was changed.
- Part 1 — picker matching: the mechanism is confirmed by the ticket's direct
  widget-tree reproduction (`AlertDialog,Dialog`, with no `DatePickerDialog`)
  and by the production `showDatePicker`/`showTimePicker` call sites. The test
  helper now finds the single `AlertDialog`, scopes `OK` to it, taps it, and
  waits for that same finder to disappear. Both date-day finders are also
  scoped to the `AlertDialog`. The local Flutter runner could not load the
  isolated organizer test, so this environment did not independently execute
  the corrected interaction.
- Part 2 — Garden membership visibility: confirmed directly from the call
  chain. `garden-event-rsvp-response` is `membersOnly`; the direct
  `_calendar(...)` harness bypasses `LocalExtensionScreen` and therefore its
  `configureEngineAuthorizationForExtensionId` call; the superseded
  `_gardenAuth` only registered persona types; and
  `LocalWorkflowEngineApi._isActiveMember` returns `false` when its membership
  lookup is absent. `_gardenAuth` now installs the same active-account-status
  lookup used by `LocalExtensionScreen` and registers the three test Garden
  accounts' persona types. Production visibility logic remains unchanged.
- Tests 2, 3, and 5 now follow the current Garden contract after membership is
  configured:
  - the seeded-response test acts as Maya (`garden-member-maya`) and expects
    `respond-waitlist`, not the capacity-rejected `respond-going`;
  - the `respond-going` test owns a valid non-full event and pending Maya
    response, then checks the real capacity and aggregate increment;
  - the reminder test executes `add-reminder`, checks `reminderDueAt`, and
    verifies the matching `garden-notification` instead of referring to the
    removed `send-reminder`/`reminderSentAt` contract.
- Part 3 — organizer event-level actions: confirmed directly from the widget
  lifecycle. `_EventRsvpDetailCardState.initState` starts asynchronous
  `_loadActions()`, while the old test waited only for the card shell before
  asserting `cancel-event`. The fixture transition's guard accepts
  `garden-coordinator`. The test now waits for the `cancel-event` key itself.
  Its intentional bulk event seed also includes the required
  `coordinatorPersonaId` and `recurrenceLabel` fields.
- The custom recurring-creation test now fills the current required
  `recurrenceLabel` and `reminderOffsetHours` form fields and derives expected
  fan-out account IDs from the exact injected auth store used by
  `LocalExtensionScreen`.
- Part 4 — CALR2G hermeticity: the generated-input mechanism is confirmed.
  Package generation is now a reusable function; the test locates the repo by
  the frozen source fixture, generates both package files in a unique system
  temporary directory, installs those exact files, and deletes the directory
  in `finally`. A direct Dart probe successfully generated and cleaned up the
  pair. The Flutter test itself remains unexecuted because its test body could
  not load. Its stack ends in `FlutterTesterTestDevice.start` while binding the
  same `127.0.0.1:0` HTTP server as every other Flutter test; this is the
  general Flutter test-runner socket restriction, not a real-device/emulator
  binding requirement.

## Verification

### Analysis

Changed Dart files:

```text
$ /home/fahd/flutter/bin/cache/dart-sdk/bin/dart analyze test/v3_milestone_a11_event_rsvp_archetype_test.dart test/v3_milestone_calr2g_live_package_test.dart tool/generate_tabletop_club_package.dart
Analyzing v3_milestone_a11_event_rsvp_archetype_test.dart, v3_milestone_calr2g_live_package_test.dart, generate_tabletop_club_package.dart...
No issues found!
```

Whole App Shell package:

```text
$ /home/fahd/flutter/bin/cache/dart-sdk/bin/dart analyze
Analyzing loom_communities_app_shell...

   info - lib/loom_communities_app_shell.dart:12:1 - Sort directive sections alphabetically. Try sorting the directives. - directives_ordering
   info - lib/src/part18_marketplace_rendering.dart:863:11 - Missing an 'await' for the 'Future' computed by this expression. Try adding an 'await' or wrapping the expression with 'unawaited'. - unawaited_futures
   info - lib/src/part18_marketplace_rendering.dart:864:11 - Missing an 'await' for the 'Future' computed by this expression. Try adding an 'await' or wrapping the expression with 'unawaited'. - unawaited_futures
   info - lib/src/part18_marketplace_rendering.dart:865:11 - Missing an 'await' for the 'Future' computed by this expression. Try adding an 'await' or wrapping the expression with 'unawaited'. - unawaited_futures
   info - test/v3_milestone_1b1c_search_ai_answer_widget_test.dart:33:20 - Use 'const' with the constructor to improve performance. Try adding the 'const' keyword to the constructor invocation. - prefer_const_constructors
   info - test/v3_milestone_1b1c_search_ai_answer_widget_test.dart:152:18 - Use 'const' with the constructor to improve performance. Try adding the 'const' keyword to the constructor invocation. - prefer_const_constructors
   info - test/v3_milestone_a6_generic_instance_card_test.dart:1135:18 - Use 'const' with the constructor to improve performance. Try adding the 'const' keyword to the constructor invocation. - prefer_const_constructors
   info - test/v3_milestone_a7_binding_dispatch_test.dart:920:20 - Use 'const' with the constructor to improve performance. Try adding the 'const' keyword to the constructor invocation. - prefer_const_constructors
   info - test/v3_milestone_a7_binding_dispatch_test.dart:1077:20 - Use 'const' with the constructor to improve performance. Try adding the 'const' keyword to the constructor invocation. - prefer_const_constructors

9 issues found.
```

Exit code: **0**. All nine are pre-existing info-level lints in files this
ticket does not change; there are no errors or warnings. The three changed
Dart files are zero-diagnostic.

### Six exact-name A11 tests, two attempts each

Command shape used for every invocation:

```text
$ FLUTTER_ALREADY_LOCKED=true /home/fahd/flutter/bin/cache/dart-sdk/bin/dart /home/fahd/flutter/bin/cache/flutter_tools.snapshot --no-version-check test --no-pub test/v3_milestone_a11_event_rsvp_archetype_test.dart --plain-name '<exact name>' --reporter expanded
```

Each invocation also printed two read-only Flutter-cache stamp warnings for
`libimobiledevice.stamp` and `libusbmuxd.stamp`. The actual result for each
requested test and each run was:

1. `organizer creates an event and one pending response per member`

   ```text
   Run 1, exit 1:
   00:00 +0 -1: loading /home/fahd/Loom/app/packages/core/loom_communities_app_shell/test/v3_milestone_a11_event_rsvp_archetype_test.dart [E]
     Failed to load "/home/fahd/Loom/app/packages/core/loom_communities_app_shell/test/v3_milestone_a11_event_rsvp_archetype_test.dart": Failed to create server socket (OS Error: Operation not permitted, errno = 1), address = 127.0.0.1, port = 0
     package:flutter_tools/src/test/flutter_tester_device.dart 89:15  FlutterTesterTestDevice.start
   00:00 +0 -1: Some tests failed.

   Run 2, exit 1:
   00:00 +0 -1: loading /home/fahd/Loom/app/packages/core/loom_communities_app_shell/test/v3_milestone_a11_event_rsvp_archetype_test.dart [E]
     Failed to load "/home/fahd/Loom/app/packages/core/loom_communities_app_shell/test/v3_milestone_a11_event_rsvp_archetype_test.dart": Failed to create server socket (OS Error: Operation not permitted, errno = 1), address = 127.0.0.1, port = 0
     package:flutter_tools/src/test/flutter_tester_device.dart 89:15  FlutterTesterTestDevice.start
   00:00 +0 -1: Some tests failed.
   ```

2. `custom workflow event uses event-rsvp response actions when the viewer has a seeded response`

   ```text
   Run 1, exit 1:
   00:00 +0 -1: loading /home/fahd/Loom/app/packages/core/loom_communities_app_shell/test/v3_milestone_a11_event_rsvp_archetype_test.dart [E]
     Failed to load "/home/fahd/Loom/app/packages/core/loom_communities_app_shell/test/v3_milestone_a11_event_rsvp_archetype_test.dart": Failed to create server socket (OS Error: Operation not permitted, errno = 1), address = 127.0.0.1, port = 0
     package:flutter_tools/src/test/flutter_tester_device.dart 89:15  FlutterTesterTestDevice.start
   00:00 +0 -1: Some tests failed.

   Run 2, exit 1:
   00:00 +0 -1: loading /home/fahd/Loom/app/packages/core/loom_communities_app_shell/test/v3_milestone_a11_event_rsvp_archetype_test.dart [E]
     Failed to load "/home/fahd/Loom/app/packages/core/loom_communities_app_shell/test/v3_milestone_a11_event_rsvp_archetype_test.dart": Failed to create server socket (OS Error: Operation not permitted, errno = 1), address = 127.0.0.1, port = 0
     package:flutter_tools/src/test/flutter_tester_device.dart 89:15  FlutterTesterTestDevice.start
   00:00 +0 -1: Some tests failed.
   ```

3. `custom workflow respond-going updates the response row and event aggregate counts`

   ```text
   Run 1, exit 1:
   00:00 +0 -1: loading /home/fahd/Loom/app/packages/core/loom_communities_app_shell/test/v3_milestone_a11_event_rsvp_archetype_test.dart [E]
     Failed to load "/home/fahd/Loom/app/packages/core/loom_communities_app_shell/test/v3_milestone_a11_event_rsvp_archetype_test.dart": Failed to create server socket (OS Error: Operation not permitted, errno = 1), address = 127.0.0.1, port = 0
     package:flutter_tools/src/test/flutter_tester_device.dart 89:15  FlutterTesterTestDevice.start
   00:00 +0 -1: Some tests failed.

   Run 2, exit 1:
   00:00 +0 -1: loading /home/fahd/Loom/app/packages/core/loom_communities_app_shell/test/v3_milestone_a11_event_rsvp_archetype_test.dart [E]
     Failed to load "/home/fahd/Loom/app/packages/core/loom_communities_app_shell/test/v3_milestone_a11_event_rsvp_archetype_test.dart": Failed to create server socket (OS Error: Operation not permitted, errno = 1), address = 127.0.0.1, port = 0
     package:flutter_tools/src/test/flutter_tester_device.dart 89:15  FlutterTesterTestDevice.start
   00:00 +0 -1: Some tests failed.
   ```

4. `missing custom response row keeps organizer event-level actions visible`

   ```text
   Run 1, exit 1:
   00:00 +0 -1: loading /home/fahd/Loom/app/packages/core/loom_communities_app_shell/test/v3_milestone_a11_event_rsvp_archetype_test.dart [E]
     Failed to load "/home/fahd/Loom/app/packages/core/loom_communities_app_shell/test/v3_milestone_a11_event_rsvp_archetype_test.dart": Failed to create server socket (OS Error: Operation not permitted, errno = 1), address = 127.0.0.1, port = 0
     package:flutter_tools/src/test/flutter_tester_device.dart 89:15  FlutterTesterTestDevice.start
   00:00 +0 -1: Some tests failed.

   Run 2, exit 1:
   00:00 +0 -1: loading /home/fahd/Loom/app/packages/core/loom_communities_app_shell/test/v3_milestone_a11_event_rsvp_archetype_test.dart [E]
     Failed to load "/home/fahd/Loom/app/packages/core/loom_communities_app_shell/test/v3_milestone_a11_event_rsvp_archetype_test.dart": Failed to create server socket (OS Error: Operation not permitted, errno = 1), address = 127.0.0.1, port = 0
     package:flutter_tools/src/test/flutter_tester_device.dart 89:15  FlutterTesterTestDevice.start
   00:00 +0 -1: Some tests failed.
   ```

5. `custom workflow reminders are sent on custom response instances`

   ```text
   Run 1, exit 1:
   00:00 +0 -1: loading /home/fahd/Loom/app/packages/core/loom_communities_app_shell/test/v3_milestone_a11_event_rsvp_archetype_test.dart [E]
     Failed to load "/home/fahd/Loom/app/packages/core/loom_communities_app_shell/test/v3_milestone_a11_event_rsvp_archetype_test.dart": Failed to create server socket (OS Error: Operation not permitted, errno = 1), address = 127.0.0.1, port = 0
     package:flutter_tools/src/test/flutter_tester_device.dart 89:15  FlutterTesterTestDevice.start
   00:00 +0 -1: Some tests failed.

   Run 2, exit 1:
   00:00 +0 -1: loading /home/fahd/Loom/app/packages/core/loom_communities_app_shell/test/v3_milestone_a11_event_rsvp_archetype_test.dart [E]
     Failed to load "/home/fahd/Loom/app/packages/core/loom_communities_app_shell/test/v3_milestone_a11_event_rsvp_archetype_test.dart": Failed to create server socket (OS Error: Operation not permitted, errno = 1), address = 127.0.0.1, port = 0
     package:flutter_tools/src/test/flutter_tester_device.dart 89:15  FlutterTesterTestDevice.start
   00:00 +0 -1: Some tests failed.
   ```

6. `custom event creation and recurring generation seed custom response rows`

   ```text
   Run 1, exit 1:
   00:00 +0 -1: loading /home/fahd/Loom/app/packages/core/loom_communities_app_shell/test/v3_milestone_a11_event_rsvp_archetype_test.dart [E]
     Failed to load "/home/fahd/Loom/app/packages/core/loom_communities_app_shell/test/v3_milestone_a11_event_rsvp_archetype_test.dart": Failed to create server socket (OS Error: Operation not permitted, errno = 1), address = 127.0.0.1, port = 0
     package:flutter_tools/src/test/flutter_tester_device.dart 89:15  FlutterTesterTestDevice.start
   00:00 +0 -1: Some tests failed.

   Run 2, exit 1:
   00:00 +0 -1: loading /home/fahd/Loom/app/packages/core/loom_communities_app_shell/test/v3_milestone_a11_event_rsvp_archetype_test.dart [E]
     Failed to load "/home/fahd/Loom/app/packages/core/loom_communities_app_shell/test/v3_milestone_a11_event_rsvp_archetype_test.dart": Failed to create server socket (OS Error: Operation not permitted, errno = 1), address = 127.0.0.1, port = 0
     package:flutter_tools/src/test/flutter_tester_device.dart 89:15  FlutterTesterTestDevice.start
   00:00 +0 -1: Some tests failed.
   ```

Result: **all 12 invocations failed before their selected test body loaded**.
These are environment failures, not behavioral passes or behavioral failures,
so none of the six tests is claimed fixed by execution in this STATUS.

### CALR2G

The exact-name Flutter test was invoked twice:

```text
$ FLUTTER_ALREADY_LOCKED=true /home/fahd/flutter/bin/cache/dart-sdk/bin/dart /home/fahd/flutter/bin/cache/flutter_tools.snapshot --no-version-check test --no-pub test/v3_milestone_calr2g_live_package_test.dart --plain-name 'generated Tabletop package installs with CALR RSVP response rows' --reporter expanded

Run 1, exit 1:
00:00 +0 -1: loading /home/fahd/Loom/app/packages/core/loom_communities_app_shell/test/v3_milestone_calr2g_live_package_test.dart [E]
  Failed to load "/home/fahd/Loom/app/packages/core/loom_communities_app_shell/test/v3_milestone_calr2g_live_package_test.dart": Failed to create server socket (OS Error: Operation not permitted, errno = 1), address = 127.0.0.1, port = 0
  package:flutter_tools/src/test/flutter_tester_device.dart 89:15  FlutterTesterTestDevice.start
00:00 +0 -1: Some tests failed.

Run 2, exit 1:
00:00 +0 -1: loading /home/fahd/Loom/app/packages/core/loom_communities_app_shell/test/v3_milestone_calr2g_live_package_test.dart [E]
  Failed to load "/home/fahd/Loom/app/packages/core/loom_communities_app_shell/test/v3_milestone_calr2g_live_package_test.dart": Failed to create server socket (OS Error: Operation not permitted, errno = 1), address = 127.0.0.1, port = 0
  package:flutter_tools/src/test/flutter_tester_device.dart 89:15  FlutterTesterTestDevice.start
00:00 +0 -1: Some tests failed.
```

The extracted generator was also called directly with a unique temporary
directory and explicit repository root:

```text
$ /home/fahd/flutter/bin/cache/dart-sdk/bin/dart --packages=../../../.dart_tool/package_config.json /tmp/acws_calr2g_generator_probe.dart
generated extension=/tmp/acws-calr2g-probe-BJOZCY/ext_verify_tabletop_club.loom-extension.zip init=/tmp/acws-calr2g-probe-BJOZCY/ext_verify_tabletop_club.loom-init.zip
temporary directory removed=true
```

The temporary probe source and generated directory were removed after the
run.

### Full App Shell suite

The full suite was run for real with no file or name filter. The `awk` stage
only retained each loader failure and the final total from the underlying
Flutter command:

```text
$ bash -o pipefail -c "FLUTTER_ALREADY_LOCKED=true /home/fahd/flutter/bin/cache/dart-sdk/bin/dart /home/fahd/flutter/bin/cache/flutter_tools.snapshot --no-version-check test --no-pub --reporter expanded 2>&1 | awk '/Failed to load|Some tests failed/'"
...
00:00 +0 -58: Some tests failed.
```

Exact total: **0 passed / 58 test-file loads failed**. Every failure was
`Failed to create server socket ... address = 127.0.0.1, port = 0`; the 58
failed files were:

1. `test/authz_p4b_permission_wiring_test.dart`
2. `test/authz_p5_membership_flows_test.dart`
3. `test/authz_p6_entry_gate_test.dart`
4. `test/authz_p8_second_account_engine_sync_test.dart`
5. `test/cjm13_fab_content_occlusion_test.dart`
6. `test/cjm8_engine_native_tabs_test.dart`
7. `test/cjm9_preloaded_shell_hydration_test.dart`
8. `test/milestone_1_4_test.dart`
9. `test/milestone_2_1_test.dart`
10. `test/notification_bell_button_test.dart`
11. `test/notification_dedicated_tab_test.dart`
12. `test/notification_delivery_service_test.dart`
13. `test/notification_fab_test.dart`
14. `test/notification_fixed_card_test.dart`
15. `test/notification_inbox_controller_test.dart`
16. `test/v3_as1_dismissible_hero_card_test.dart`
17. `test/v3_calnotify2_7_bell_activation_test.dart`
18. `test/v3_calnotify2_9_calendar_reminder_test.dart`
19. `test/v3_calr3b_tournament_creation_test.dart`
20. `test/v3_calr3g_creatable_action_fab_test.dart`
21. `test/v3_calr3h1_popup_presentation_test.dart`
22. `test/v3_calr3h1_slideoutright_presentation_test.dart`
23. `test/v3_calr3h2a_generic_creation_card_test.dart`
24. `test/v3_calr4b_individual_sign_in_ui_test.dart`
25. `test/v3_calr4e_instance_scoped_create_test.dart`
26. `test/v3_calr4e_instance_scoped_prefill_test.dart`
27. `test/v3_calr4f_instance_scoped_create_fab_test.dart`
28. `test/v3_calr4g_marketplace_transition_action_test.dart`
29. `test/v3_milestone_1_10_export_wizard_test.dart`
30. `test/v3_milestone_1_11_volunteer_roster_test.dart`
31. `test/v3_milestone_1_12_ai_search_test.dart`
32. `test/v3_milestone_1_13_audience_picker_test.dart`
33. `test/v3_milestone_1_14_single_item_preference_test.dart`
34. `test/v3_milestone_1_15_timeline_and_protected_detail_test.dart`
35. `test/v3_milestone_1_17_form_entry_test.dart`
36. `test/v3_milestone_1_18_stage1_repeater_async_guard_test.dart`
37. `test/v3_milestone_1_3_repeater_test.dart`
38. `test/v3_milestone_1_5_calendar_grid_test.dart`
39. `test/v3_milestone_1_6_repeater_grid_test.dart`
40. `test/v3_milestone_1_7_messages_test.dart`
41. `test/v3_milestone_1_8_document_library_test.dart`
42. `test/v3_milestone_1_9_notification_inbox_test.dart`
43. `test/v3_milestone_1b1c_search_ai_answer_widget_test.dart`
44. `test/v3_milestone_a11_event_rsvp_archetype_test.dart`
45. `test/v3_milestone_a4_engine_native_parsing_test.dart`
46. `test/v3_milestone_a5_shared_engine_test.dart`
47. `test/v3_milestone_a6_generic_instance_card_test.dart`
48. `test/v3_milestone_a7_binding_dispatch_test.dart`
49. `test/v3_milestone_a8_calendar_end_to_end_test.dart`
50. `test/v3_milestone_a9_calendar_theming_test.dart`
51. `test/v3_milestone_b1_home_engine_native_test.dart`
52. `test/v3_milestone_calr2g_live_package_test.dart`
53. `test/v3_milestone_gp2_giving_end_to_end_test.dart`
54. `test/v3_milestone_phaseb_votepoll_archetype_test.dart`
55. `test/v3_milestone_phasec_marketplace_archetype_test.dart`
56. `test/v3_milestone_phasee_purchase_proposal_test.dart`
57. `test/v3_milestone_phasef_messages_test.dart`
58. `test/v3_multiuser_login_test.dart`

This is an environment loader-failure total, not the App Shell's behavioral
pass/fail total. No behavioral total is guessed.

### Workflow engine

```text
$ /home/fahd/flutter/bin/cache/dart-sdk/bin/dart test
Running build hooks...Running build hooks...
...
00:07 +232: All tests passed!
```

Exit code: **0**. Exact total: **232 passed / 0 failed**.

## Proposed next steps

- In an environment that permits Flutter's ephemeral loopback test server,
  rerun each of the six exact-name A11 tests twice, rerun CALR2G twice, and run
  the complete App Shell suite. Do not mark the six behavioral fixes verified
  until those runs load and execute their bodies.
- If an A11 target then fails, preserve the first post-setup exception and
  keep the follow-up scoped to that mechanism. The production engine
  visibility defaults and recurring fan-out ownership should remain
  unchanged.

## Anything I could not do

- I could not get any Flutter test body to load because this managed sandbox
  denies the runner's `127.0.0.1:0` server bind. Consequently I could not
  confirm that the picker interaction gets past the dialog, could not produce
  two behavioral passes for any of the six targets, could not behaviorally
  execute CALR2G, and could not obtain a behavioral full-suite total.
- The whole-package analyzer exits successfully but reports nine pre-existing
  info lints in unrelated files. I did not modify those unrelated files merely
  to make the text say `No issues found`; all changed Dart files do say
  `No issues found!`.
- `ROOT_CAUSE_REPORT_2.md` and `ROOT_CAUSE_REPORT_3.md` are user-provided,
  untracked inputs and are intentionally excluded from the commit.
