## What changed

- Added synchronous engine-owned response-row fan-out for `event-rsvp`. An applied transition with `action: "create"` now creates one response workflow instance per active registered member before the transition transaction returns. Each row starts in the response workflow's declared `initialState` and carries the binding's declared `responseTable.eventField` pointing at the event instance.
- Reused the engine's existing archetype and membership boundaries:
  - `_resolvedArchetypes`/`ArchetypeResolver` must resolve the source workflow to `event-rsvp`, and the source must have an `event-rsvp` binding with `responseTable`.
  - `setPersonaType` supplies the engine's enumerable account ids. When `activeMembershipLookup` is installed, the fan-out filters those same ids through it so inactive/pending accounts are not materialized. No community JSON member list was introduced or read.
- Extracted `_identityFieldMatchesDuringD8Straddle`'s spelling expansion into one shared helper. Fan-out selects `personaId` or `fanId` from the response workflow's actual `instanceDataSchema`; reads, bookkeeping writes, and fan-out now share the same temporary D8 alias logic.
- Preserved current packages whose tab-level render action calls singular `createInstance` directly and does not yet declare an `action: "create"` transition: that singular creation path fans out before returning. A workflow that does declare the create transition defers fan-out to that transition, preventing premature rows. Recurrence-generated event instances also fan out synchronously.
- Kept `createInstances` as the raw bulk primitive used by D7a's per-member create-or-get and by test/setup paths that intentionally need an orphan event or response. Repeated create transitions are idempotent for an existing `(event, member)` row.
- Removed the older app-shell `_seedResponseRowsFor` callback, which instantiated its own `LocalAuthApi`, hard-coded `personaId`, and therefore enumerated a second and often empty membership source. The app shell now relies on the engine behavior.
- Left D7a's create-or-get implementation in `part28_engine_native_calendar_surface.dart` unchanged. It remains the late-joiner/self-healing fallback when a member has no eager row.
- Added five engine tests covering active-membership filtering, initial state, custom `eventField`, both D8 identity spellings, idempotence, strict `event-rsvp`/`create` scoping, current singular-create compatibility, and recurring-event fan-out.
- Did not edit anything under `docs/references/{reference,guide,archetypes,communities}/`.

## Verification

The repository's `dart`/`flutter` wrappers try to rewrite the read-only Flutter SDK cache in this environment, so Dart verification used the same installed SDK binary at `/home/fahd/flutter/bin/cache/dart-sdk/bin/dart`. Flutter verification used a writable `/tmp/loom-flutter-sdk` mirror of that same SDK.

`/home/fahd/flutter/bin/cache/dart-sdk/bin/dart analyze` in `app/packages/core/loom_workflow_engine`:

```text
Analyzing loom_workflow_engine...
No issues found!
```

`/home/fahd/flutter/bin/cache/dart-sdk/bin/dart test -r compact` in `app/packages/core/loom_workflow_engine`:

```text
Running build hooks...Running build hooks...00:00 +0: loading test/notification_delivery_service_test.dart
...
00:06 +232: All tests passed!
```

The new engine total is **232 passing**, up from the stated **227** baseline; no existing test was removed or weakened.

Focused fan-out run, `/home/fahd/flutter/bin/cache/dart-sdk/bin/dart test test/event_rsvp_response_fan_out_test.dart -r expanded`:

```text
Running build hooks...Running build hooks...00:00 +0: loading test/event_rsvp_response_fan_out_test.dart
00:00 +0: create action fans out one initial-state row per active registered member
00:00 +1: fan-out writes custom eventField and the declared D8 fanId spelling
00:00 +2: fan-out is exclusive to event-rsvp create actions
00:00 +3: singular create API fans out legacy binding create actions immediately
00:00 +4: recurrence-generated event instances fan out before transition returns
00:00 +5: All tests passed!
```

The requested stock Flutter invocation first failed before test startup because the installed SDK cache is read-only:

```text
/home/fahd/flutter/bin/internal/update_engine_version.sh: line 64: /home/fahd/flutter/bin/cache/engine.stamp: Read-only file system
```

`/tmp/loom-flutter-sdk/bin/flutter test --no-pub` in `app/packages/core/loom_communities_app_shell` reached the Flutter harness, but the managed sandbox prohibits its required ephemeral localhost socket. The same load failure repeated for every attempted file, including both named RSVP files:

```text
00:00 +0 -5: loading /home/fahd/Loom/app/packages/core/loom_communities_app_shell/test/v3_milestone_calr2g_live_package_test.dart [E]
  Failed to load "/home/fahd/Loom/app/packages/core/loom_communities_app_shell/test/v3_milestone_calr2g_live_package_test.dart": Failed to create server socket (OS Error: Operation not permitted, errno = 1), address = 127.0.0.1, port = 0
  dart:io-patch/socket_patch.dart 1216:7                           _NativeSocket.bind
  ===== asynchronous gap ===========================
  package:flutter_tools/src/test/flutter_tester_device.dart 89:15  FlutterTesterTestDevice.start

...

00:00 +0 -41: loading /home/fahd/Loom/app/packages/core/loom_communities_app_shell/test/v3_milestone_a11_event_rsvp_archetype_test.dart [E]
  Failed to load "/home/fahd/Loom/app/packages/core/loom_communities_app_shell/test/v3_milestone_a11_event_rsvp_archetype_test.dart": Failed to create server socket (OS Error: Operation not permitted, errno = 1), address = 127.0.0.1, port = 0
  dart:io-patch/socket_patch.dart 1216:7                           _NativeSocket.bind
  ===== asynchronous gap ===========================
  package:flutter_tools/src/test/flutter_tester_device.dart 89:15  FlutterTesterTestDevice.start
```

After 51 identical file-load failures, the run was stopped (`exit 130`). No application test body executed, so this environment produced neither the stated `+231 -8` baseline nor a post-change pass/fail count. It therefore cannot honestly identify which of the eight app assertions closed. The expected result remains the seven fan-out failures green and the unrelated Admin-tab leak as the sole failure (`+238 -1`), but that expectation is **not claimed as verified** here.

As a non-socket compile check, `/home/fahd/flutter/bin/cache/dart-sdk/bin/dart analyze` in `app/packages/core/loom_communities_app_shell` completed successfully with the same 13 existing info-level lints and no errors or warnings:

```text
Analyzing loom_communities_app_shell...
...
13 issues found.
```

D7a source regression check:

```text
$ git diff --quiet HEAD -- app/packages/core/loom_communities_app_shell/lib/src/part28_engine_native_calendar_surface.dart
part28 diff exit=0
```

`part28_engine_native_calendar_surface.dart` is byte-for-byte unchanged relative to `HEAD`. Its widget test `a member with no response row can RSVP; the row is created` was among the tests that could not load because of the same sandbox socket restriction.

`git diff --check`:

```text
```

(No output; clean.)

## Proposed next steps

- Rerun `flutter test --no-pub` for `loom_communities_app_shell` in an environment that permits binding an ephemeral `127.0.0.1` test-harness socket. Confirm the seven named fan-out-related failures close, D7a's `a member with no response row can RSVP` stays green, and only the unrelated Admin-tab leak remains (`+238 -1`).
- Keep D7a until a separate decision removes late-joiner support; eager fan-out intentionally covers only identities active at event creation time.
- At Phase F, remove the shared D8 spelling helper only after response schemas and the rest of the corpus have completed the `personaId` to `fanId` rename.

## Anything I could not do

- I could not obtain the required app-shell post-change result or report exactly which of the eight assertions closed because Flutter cannot create its localhost test-device socket in this managed sandbox. This blocks the full suite and the focused D7a widget test before their test bodies run. Engine analysis and all 232 engine tests completed successfully, and the app-shell package analyzes without errors or warnings.
