# ACWS Phase B.3 follow-up — refuse direct response-row creation

## What changed

- `WorkflowService._createInstance` now refuses a resolved archetype whose
  origin is `ArchetypeOrigin.inheritedFromResponseTable`. It returns the same
  generic `403 workflow_create_refused` response as every other creation
  refusal, so the response does not reveal the archetype origin or permission.
- The origin check runs immediately after experience-wide archetype resolution
  and before permission derivation, community-group resolution, or the App
  Access decision call. This ordering avoids spending a live authorization
  round-trip on a workflow type that can never be created directly; its rows
  remain exclusive to the parent's eager fan-out path.
- Added a focused unit fixture with an `event-rsvp` parent and an unbound
  response workflow targeted by `responseTable.workflowType`. The test first
  proves that the target resolves as
  `ArchetypeOrigin.inheritedFromResponseTable` with the shared
  `event_rsvp.create` permission, then proves a genuinely allowed mock client
  still receives `403 workflow_create_refused` and records zero App Access
  calls.
- Expanded the existing successful-create test, without weakening or removing
  it, to exercise both allowed origins: `declaredBespoke` still creates with
  `event_rsvp.create`, and `generic` still creates with `form_entry.create`.
- No workflow-engine file and no file under
  `docs/references/{reference,guide,archetypes,communities}/` changed. The
  service operations outside `createInstance` were not touched.

## Verification

The focused regression passes and confirms the refusal occurs before App
Access (`callCount == 0`):

```text
$ cd app/packages/core/loom_workflow_service
$ /home/fahd/flutter/bin/cache/dart-sdk/bin/dart \
    --packages=/home/fahd/Loom/app/.dart_tool/package_config.json \
    /home/fahd/Loom/app/.dart_tool/pub/bin/test/test.dart-3.11.5.snapshot \
    test/workflow_service_test.dart \
    --name 'createInstance refuses a response-table-owned type before App Access' \
    --reporter expanded
00:00 +0: loading test/workflow_service_test.dart
00:00 +0: createInstance refuses a response-table-owned type before App Access
00:00 +1: All tests passed!
```

Formatting and the required service analysis are clean:

```text
$ /home/fahd/flutter/bin/cache/dart-sdk/bin/dart format \
    --output=none --set-exit-if-changed lib bin test
Formatted 11 files (0 changed) in 0.22 seconds.

$ /home/fahd/flutter/bin/cache/dart-sdk/bin/dart analyze
Analyzing loom_workflow_service...
No issues found!
```

The resolved package:test runner executed the complete service suite. The 13
pre-existing unit tests and the new focused unit test all pass (`+14`). The
three pre-existing live integration tests were discovered but skipped because
this sandbox does not expose the required PostgreSQL/App Access credentials:

```text
$ /home/fahd/flutter/bin/cache/dart-sdk/bin/dart \
    --packages=/home/fahd/Loom/app/.dart_tool/package_config.json \
    /home/fahd/Loom/app/.dart_tool/pub/bin/test/test.dart-3.11.5.snapshot \
    --reporter expanded
...
00:00 +0 ~2: createInstance keeps declaredBespoke and generic origins creatable
00:00 +1 ~2: createInstance refuses a response-table-owned type before App Access
...
00:00 +14 ~3: All tests passed!
```

The unchanged workflow-engine suite remains at exactly 232 passing tests:

```text
$ cd ../loom_workflow_engine
$ /home/fahd/flutter/bin/cache/dart-sdk/bin/dart \
    --packages=/home/fahd/Loom/app/.dart_tool/package_config.json \
    /home/fahd/Loom/app/.dart_tool/pub/bin/test/test.dart-3.11.5.snapshot \
    --reporter compact
...
00:08 +232 ~2: 2 skipped tests.
00:08 +232 ~2: All other tests passed!
```

The two engine skips are its existing live-PostgreSQL tests. No engine file was
modified.

The live-service prerequisites are unavailable in this execution sandbox:

```text
$ for name in LOOM_POSTGRES_PASSWORD LOOM_POSTGRES_USERNAME \
    LOOM_POSTGRES_HOST LOOM_POSTGRES_PORT LOOM_APP_ACCESS_BASE_URL; do \
    if [ -n "${!name:-}" ]; then echo "$name=set"; \
    else echo "$name=unset"; fi; done
LOOM_POSTGRES_PASSWORD=unset
LOOM_POSTGRES_USERNAME=unset
LOOM_POSTGRES_HOST=unset
LOOM_POSTGRES_PORT=unset
LOOM_APP_ACCESS_BASE_URL=unset

$ kubectl -n loom get pods -o wide
Unable to connect to the server: dial tcp 127.0.0.1:6443:
socket: operation not permitted
```

`git diff --check` is clean.

## Proposed next steps

Deployment remains the obvious next slice after running the three existing
service integration tests from an unsandboxed shell with live PostgreSQL and
App Access. The deployment should keep the explicit canonical
community-id/group-id mapping introduced by Phase B.3; this follow-up requires
no new configuration or engine rollout.

## Anything I could not do

- I could not turn the three existing service integration skips into live
  passes. This process has no `LOOM_POSTGRES_PASSWORD` or
  `LOOM_APP_ACCESS_BASE_URL`, and sandbox policy blocks access to the local
  k3s API at `127.0.0.1:6443`, so it cannot retrieve credentials or establish
  the required port-forwards. I therefore do not claim those three integration
  tests passed; all 14 runnable unit tests did pass.
- The two unchanged engine live-PostgreSQL tests likewise remained skipped;
  the engine's required passing count is unchanged at 232.
