# Phase E.1 — atomic `createInstances` workflow-service batch

## What changed

- Added `POST /v1/communities/{communityId}/instances/batch` with
  `operationId: createInstances` to the workflow-engine OpenAPI contract. It
  reuses the singular operation's correlation, idempotency, community,
  permission-derivation, `400`, and `403` conventions. Its request requires one
  `workflowType` and a non-empty `initialInstanceDataList`; its `201` response
  reuses `WorkflowInstance` and preserves request order.
- Added `WorkflowService._createInstances`. It validates the same headers as
  `createInstance`, resolves the archetype and derives its `create` permission
  once, performs one real App Access decision for the whole batch, and invokes
  the engine's existing atomic `createInstances` inside the service's serialized
  database mutation boundary.
- Reused the singular creation refusal behavior exactly: denied access returns
  generic `403 workflow_create_refused` without permission or role details, and
  `ArchetypeOrigin.inheritedFromResponseTable` is refused before App Access.
- Added five service unit tests covering ordered multi-item success, one-check
  generic denial with zero writes, response-table-origin refusal, empty-batch
  `400`, and rollback of a valid first item when the second item fails required
  field validation.
- Extended the existing live App Access/PostgreSQL integration harness. It now
  sends `[valid, invalid]` to the batch route before any singular create and
  asserts that querying PostgreSQL returns zero instances.
- No app-shell file, workflow-engine source/test file, singular `createInstance`,
  other workflow-service operation, or file under
  `docs/references/{reference,guide,archetypes,communities}/` changed.

## Verification

The OpenAPI YAML parses and contains the expected operation:

```text
$ /home/fahd/flutter/bin/cache/dart-sdk/bin/dart --packages=/home/fahd/Loom/app/.dart_tool/package_config.json /tmp/validate_workflow_openapi.dart docs/API/OpenAPI/community-surfaces/workflow-engine-api.openapi.yaml
YAML/OpenAPI batch operation parse: ok
```

Formatting and service analysis are clean:

```text
$ cd app/packages/core/loom_workflow_service
$ /home/fahd/flutter/bin/cache/dart-sdk/bin/dart format --output=none --set-exit-if-changed lib/src/workflow_service.dart test/workflow_service_test.dart test/app_access_create_instance_integration_test.dart
Formatted 3 files (0 changed) in 0.31 seconds.

$ /home/fahd/flutter/bin/cache/dart-sdk/bin/dart analyze
Analyzing loom_workflow_service...
No issues found!
```

The focused service unit file passes all 19 tests, including the five new batch
tests:

```text
$ /home/fahd/flutter/bin/cache/dart-sdk/bin/dart --packages=/home/fahd/Loom/app/.dart_tool/package_config.json /home/fahd/.pub-cache/hosted/pub.dev/test-1.30.0/bin/test.dart --reporter expanded test/workflow_service_test.dart
...
00:00 +8: createInstances rolls back earlier items when later validation fails
...
00:00 +19: All tests passed!
```

The full workflow-service suite has exactly 34 tests after this change: 31
runnable passes and 3 credential-gated skips. Before this change it had exactly
29 tests: 26 runnable passes and the same 3 skips. The exact before/after count
is therefore **29 -> 34** (`+5`), with no existing test weakened or deleted.

```text
$ /home/fahd/flutter/bin/cache/dart-sdk/bin/dart --packages=/home/fahd/Loom/app/.dart_tool/package_config.json /home/fahd/.pub-cache/hosted/pub.dev/test-1.30.0/bin/test.dart --reporter expanded
...
00:00 +0 ~3: live App Access authorizes create and Postgres rolls back an invalid batch
  Skip: Set LOOM_POSTGRES_PASSWORD to run against the k3s PostgreSQL port-forward.
...
00:02 +31 ~3: All tests passed!
```

The local rollback path executed successfully: the service received a valid
first item followed by an invalid second item, returned `400 invalid_request`,
performed exactly one App Access check, and the post-request engine query found
zero rows. The unchanged engine suite also retains its own atomic
`createInstances` coverage and passes at 232 runnable tests with 2 unchanged
live-PostgreSQL skips:

```text
$ cd ../loom_workflow_engine
$ /home/fahd/flutter/bin/cache/dart-sdk/bin/dart --packages=/home/fahd/Loom/app/.dart_tool/package_config.json /home/fahd/.pub-cache/hosted/pub.dev/test-1.30.0/bin/test.dart --reporter expanded
...
00:00 +109 ~2: createInstances is atomic and preserves input order
...
00:06 +232 ~2: All tests passed!
```

`git diff --check` is clean. No workflow-engine file changed.

The requested live PostgreSQL/App Access atomicity assertion is present, but it
could not execute in this sandbox. The real output was:

```text
Skip: Set LOOM_POSTGRES_PASSWORD to run against the k3s PostgreSQL port-forward.

$ kubectl get namespaces
Unable to connect to the server: dial tcp 127.0.0.1:6443:
socket: operation not permitted
```

I do not claim a live-PostgreSQL atomicity pass from this environment.

## Proposed next steps

1. Run `app_access_create_instance_integration_test.dart` with live PostgreSQL
   and App Access port-forwards in a network-enabled environment to capture the
   required zero-row rollback proof.
2. `updateInstanceFields` and `aggregate` are the remaining server-expansion
   tickets. `dueNotifications` remains deliberately non-public, and synchronous
   `availableTransitions` remains separate client-side migration work.

## Anything I could not do

- I could not produce the required live-PostgreSQL atomicity pass because
  `LOOM_POSTGRES_PASSWORD` and `LOOM_APP_ACCESS_BASE_URL` are unset, while the
  sandbox forbids access to the local k3s API needed to establish port-forwards.
- The literal `dart test` wrapper could not complete dependency resolution: six
  pre-existing hosted entries are absent from the local pub cache, their
  committed lock entries contain no SHA fields, and outbound pub.dev access is
  blocked. I restored their exact upstream release sources outside the repo and
  ran the resolved `package:test` executable directly. All runnable service and
  engine tests passed as reported above; the three service live tests and two
  engine live tests remained explicitly skipped.
