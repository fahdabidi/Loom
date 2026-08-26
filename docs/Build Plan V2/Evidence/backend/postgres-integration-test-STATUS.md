# Postgres integration test: fan ID / role ID correction

## Change made

`postgres_database_integration_test.dart` now registers the production actor-role
mapping immediately after constructing `LocalWorkflowEngineApi` and before the
guarded workflow call:

```dart
api.setRoleForFan('member', 'member');
```

No engine or service source, fixture guard, transition, states, or existing
assertions were changed.

## Live Postgres evidence

The local `127.0.0.1:15432` Kubernetes Postgres port-forward was live for both
runs. The cluster password was supplied only to the test process; it is not
included in this report. Both targeted runs **RAN** (neither was skipped).

### Before the change — RAN, 2/3 passed, 1/3 failed, 0/3 skipped

Verbatim test-runner output from:

```text
flutter test test/postgres_database_integration_test.dart --reporter expanded
```

```text
00:00 +0: loading /home/fahd/Loom/app/packages/core/loom_workflow_engine/test/postgres_database_integration_test.dart
00:00 +0: real PostgreSQL upgrades the legacy creator column without losing rows
00:02 +1: real PostgreSQL supports definition upsert, instance creation, and a transactional transition
00:05 +1 -1: real PostgreSQL supports definition upsert, instance creation, and a transactional transition [E]
  Bad state: Transition publish is not available for member
  package:loom_workflow_engine/src/api/local_workflow_engine_api.dart 973:7  LocalWorkflowEngineApi.applyTransition
  
00:05 +1 -1: real PostgreSQL sorts queryInstancesKeyset by a bound top-level key with and without a workflow type filter
00:06 +2 -1: Some tests failed.
```

The failed case is the guarded transition. The migration and sibling keyset-query
tests passed in this live run.

### After the change — RAN, 3/3 passed, 0/3 skipped

Verbatim test-runner output from the same command:

```text
00:00 +0: loading /home/fahd/Loom/app/packages/core/loom_workflow_engine/test/postgres_database_integration_test.dart
00:00 +0: real PostgreSQL upgrades the legacy creator column without losing rows
00:02 +1: real PostgreSQL supports definition upsert, instance creation, and a transactional transition
00:03 +2: real PostgreSQL sorts queryInstancesKeyset by a bound top-level key with and without a workflow type filter
00:04 +3: All tests passed!
```

The guarded transactional transition is **1/1 passed**. The sibling
`queryInstancesKeyset` PostgreSQL test is **1/1 passed**. The test file overall
is **3/3 passed** and explicitly ran against live Postgres.

## Completed verification

Exact totals below exclude the test framework's hidden per-file loader entries,
which is how Flutter's visible `+passed ~skipped` totals are reported.

| Suite | Command | Result |
| --- | --- | --- |
| Workflow engine, live Postgres | `cd app/packages/core/loom_workflow_engine && flutter test` | **290/291 passed, 1/291 skipped, 0 failed** |
| Communities app shell | `cd app/packages/core/loom_communities_app_shell && flutter test --reporter silent --file-reporter json:<temporary-file>` | **273/273 passed, 0 skipped, 0 failed** |
| UX judges | `cd app/packages/tooling/loom_ux_judges && flutter test --reporter silent --file-reporter json:<temporary-file>` | **432/432 passed, 0 skipped, 0 failed** |
| Communities demo | `cd app/apps/loom_communities_demo && flutter test --reporter silent --file-reporter json:<temporary-file>` | **160/160 passed, 0 skipped, 0 failed** |

The workflow-engine result differs from the `d97f8bd5` environment-gated
baseline of 287 passed / 4 skipped because the live Postgres credentials caused
all three pre-existing Postgres cases in this file to run. Thus the total number
of tests is unchanged at 291, while the result is 290 passed / 1 skipped. The
only remaining skip is the unrelated deployed-workflow-service test, whose
required live-service configuration was not supplied. No suite's test total
moved down.

No requested work was left incomplete.
