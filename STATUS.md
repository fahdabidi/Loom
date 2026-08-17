# Phase E.4e — engine-native community engine DI seam

## What changed

- Changed `_EngineNativeCommunityStore.engine` from
  `LocalWorkflowEngineApi` to the abstract `WorkflowEngineApi`.
- Added one process-wide, encapsulated factory seam:
  `_engineNativeCommunityEngineFactory`. The top-level seam matches the
  process-wide store and leaves both `install()` and
  `workflowEngineForExtensionId()` signatures and all callers unchanged.
  Tests can replace it through
  `overrideEngineNativeCommunityEngineFactoryForTesting()` and restore the
  default through `resetEngineNativeCommunityEngineFactoryForTesting()`
  without exposing the mutable factory variable itself.
- Preserved the default construction behavior exactly. The default factory
  still creates `LocalWorkflowEngineApi` with the store's existing in-memory
  database as `db`, `extensionId` as `communityId`, and a new
  `LocalNotificationDeliveryService()` as `notificationDeliveryService`.
- Gated the Local-only setup at both requested call sites using the engine's
  runtime type:
  - `_initialize()` returns before calling `registerDefinition` or
    `seedInstances` when the factory result is not a
    `LocalWorkflowEngineApi`.
  - `configureAuthorization()` returns before calling
    `setActiveMembershipLookup` or `setSurfacePermissionLookup` when the
    factory result is not a `LocalWorkflowEngineApi`.
  These methods do not exist on the abstract API and have no remote
  equivalent, so a future non-Local implementation must skip client-side
  definition/seed installation and callback-based authorization setup.
- Added `engine_native_community_engine_factory_test.dart`. Its fake implements
  only `WorkflowEngineApi` (through `noSuchMethod`) and has none of the four
  Local-only methods. The test overrides the factory, installs a seeded
  engine-native experience, configures authorization, awaits initialization,
  checks that the exact fake is returned and the factory ran once, and resets
  the global override in `tearDown`.
- Did not touch `RemoteWorkflowEngineApi`, `LoomAuthSession`,
  `part02_tab_shell.dart`, any caller, or any file under
  `docs/references/{reference,guide,archetypes,communities}/`.

## Verification

Before any edit, the package contained 50 test files and 228 static
`test`/`testWidgets` declarations:

```text
$ rg -l "\b(?:test|testWidgets)\s*\(" test -g '*.dart' | wc -l
50
$ rg -o "\b(?:test|testWidgets)\s*\(" test -g '*.dart' | wc -l
228
```

The pre-change full-suite command reached Flutter Test, but the sandbox denied
the localhost listener required by Flutter's test device before any test body
loaded. The repeated loader failures were stopped after confirming the same
cause across 22 files:

```text
$ flutter test --no-pub --reporter expanded
00:00 +0 -1: loading .../authz_p4b_permission_wiring_test.dart [E]
Failed to create server socket (OS Error: Operation not permitted, errno = 1),
address = 127.0.0.1, port = 0
...
00:00 +0 -22: loading .../v3_calr3h1_slideoutright_presentation_test.dart [E]
```

Static analysis of every changed Dart file is clean:

```text
$ dart analyze lib/src/part25_engine_native_community_store.dart \
    test/engine_native_community_engine_factory_test.dart
Analyzing part25_engine_native_community_store.dart,
engine_native_community_engine_factory_test.dart...
No issues found!
```

Whole-package Flutter analysis exits successfully with no errors or warnings.
It reports the same eight pre-existing informational lints documented by the
preceding cleanup ticket, all in untouched files (three `unawaited_futures`
infos in `part18_marketplace_rendering.dart` and five
`prefer_const_constructors` infos in existing tests):

```text
$ flutter analyze --no-pub --no-fatal-infos .
Analyzing loom_communities_app_shell...
8 issues found. (ran in 7.3s)
exit_code=0
```

The focused seam test was attempted after the change. Flutter Test again
failed before loading the test body for the environment-level socket denial;
there was no assertion or compilation failure:

```text
$ flutter test --no-pub --reporter expanded \
    test/engine_native_community_engine_factory_test.dart
00:00 +0 -1: loading .../engine_native_community_engine_factory_test.dart [E]
Failed to create server socket (OS Error: Operation not permitted, errno = 1),
address = 127.0.0.1, port = 0
00:00 +0 -1: Some tests failed.
exit_code=1
```

The representative existing tests for the real engine-native tab allowlist,
generic list/home surface, Calendar, Marketplace, binding dispatcher, and
Messages were attempted together. All six hit the identical pre-load bind
denial, with zero executed test bodies:

```text
$ flutter test --no-pub --reporter expanded \
    test/cjm8_engine_native_tabs_test.dart \
    test/v3_milestone_b1_home_engine_native_test.dart \
    test/v3_milestone_a8_calendar_end_to_end_test.dart \
    test/v3_milestone_phasec_marketplace_archetype_test.dart \
    test/v3_milestone_a7_binding_dispatch_test.dart \
    test/v3_milestone_phasef_messages_test.dart
...
00:00 +0 -6: Some tests failed.
Failed to create server socket (OS Error: Operation not permitted, errno = 1),
address = 127.0.0.1, port = 0
exit_code=1
```

The post-change full package invocation reconciled all 51 test files and
failed every file at the same runner startup boundary:

```text
$ flutter test --no-pub --reporter expanded
...
00:00 +0 -51: Some tests failed.
Failed to create server socket (OS Error: Operation not permitted, errno = 1),
address = 127.0.0.1, port = 0
exit_code=1
```

The static post-change inventory is 51 files and 229 declarations. The exact
`+1` is the newly required focused test; the pre-existing suite remains 50
files/228 declarations with no test edited, weakened, or removed. A literal
zero total-count delta would be incompatible with the ticket's simultaneous
requirement to add that test.

```text
$ find test -maxdepth 1 -name '*_test.dart' -type f | wc -l
51
$ rg -o "\b(?:test|testWidgets)\s*\(" test -g '*.dart' | wc -l
229
$ git diff --check
exit_code=0
```

## Proposed next steps

1. Re-run the focused test, the six live-surface files, and the complete
   package suite in an environment that permits Flutter Test to bind an
   ephemeral localhost port.
2. Wiring a real login session and changing the factory to construct
   `RemoteWorkflowEngineApi` for some or all communities remains separate,
   later, explicitly unscoped work. This commit deliberately keeps the
   default factory Local.

## Anything I could not do

- I could not truthfully report passing before/after Flutter test counts.
  This sandbox denied every Flutter test process its mandatory
  `127.0.0.1:0` server socket before any test body executed. The executed-test
  count is therefore zero in both attempts; the static inventory comparison
  above is evidence of test preservation, not a substitute claim that the
  suite passed.
- Consequently, I could not confirm the live Calendar, Marketplace, generic
  list, binding dispatcher, or Messages behavior through executed tests in
  this environment. Their source and existing tests are untouched, and the
  relevant Dart changes analyze cleanly, but the required runtime proof must
  be collected where Flutter Test can open its listener.
- I could not report a literal zero-info whole-package analysis because eight
  pre-existing informational lints remain in untouched, out-of-scope files.
  The analyzer reports no errors or warnings, exits successfully with
  `--no-fatal-infos`, and reports no issue in either changed Dart file.
