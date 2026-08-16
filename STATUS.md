# Phase E.2 — `updateInstanceFields`

## What changed

- Added `PATCH /v1/communities/{communityId}/instances/{instanceId}/fields`
  with `operationId: updateInstanceFields` to the workflow-engine OpenAPI
  contract. It requires correlation and idempotency headers, accepts a
  non-empty `fieldUpdates` object, and returns the updated
  `WorkflowInstance`.
- Added `WorkflowService._updateInstanceFields` with the same authenticated,
  community-owned instance lookup and serialized mutation boundary used by
  transition application. It calls the workflow engine directly and makes no
  App Access request.
- Confirmed from the class definitions that `WorkflowAuthorizationError
  implements Exception`; it does not extend `StateError`. The handler therefore
  catches `WorkflowAuthorizationError` explicitly before `StateError` and maps
  all engine field-edit refusals to `403 workflow_field_edit_refused` with the
  same generic response for edit-guard, editable-field, computed-field, and
  effect-only-field failures. No guard, persona, or field detail is returned.
- Preserved `StateError` handling for the engine's missing-instance and
  unknown-workflow-type cases, mapping both to the generic instance `404`.
- Added seven service unit tests for the allowed edit, state `editGuard`
  refusal and non-leakage, field absent from `editableFields`, computed field,
  effect-only field, empty update, and cross-community instance cases. The
  success and refusal tests also prove this operation makes zero App Access
  calls.
- Added a credential-gated integration test to the package's existing
  PostgreSQL test harness. It creates a unique schema, edits a real row through
  the Shelf service, reads the stored row back through PostgreSQL, reads it
  again through `queryInstances`, and drops the schema in `finally`.
- No protected `docs/references/{reference,guide,archetypes,communities}` file,
  app-shell file, existing workflow operation, or `app_access_client.dart` was
  changed.

## Verification

The untouched `loom_workflow_service` baseline was 35 passing tests and 3
credential-gated skips:

```text
$ dart --packages=../../../.dart_tool/package_config.json \
    /home/fahd/.pub-cache/hosted/pub.dev/test-1.30.0/bin/test.dart \
    --reporter expanded
...
00:01 +35 ~3: All tests passed!
```

The package-test entrypoint was used for that before snapshot because the
workspace package config timestamp predated a lockfile-only integrity-hash
repair, causing the `dart test` launcher to attempt a blocked pub.dev advisory
refresh. It uses the same installed test runner and package configuration.

All seven new unit cases pass:

```text
$ dart --packages=../../../.dart_tool/package_config.json \
    /home/fahd/.pub-cache/hosted/pub.dev/test-1.30.0/bin/test.dart \
    test/workflow_service_test.dart --name updateInstanceFields \
    --reporter expanded
00:00 +0: loading test/workflow_service_test.dart
00:00 +0: updateInstanceFields allows an engine-authorized edit and returns it
00:00 +1: updateInstanceFields maps editGuard refusal to a detail-free 403
00:00 +2: updateInstanceFields refuses a field absent from editableFields
00:00 +3: updateInstanceFields refuses a computed field
00:00 +4: updateInstanceFields refuses an effect-only-writable field
00:00 +5: updateInstanceFields rejects an empty update as 400
00:00 +6: updateInstanceFields returns another community instance as absent
00:00 +7: All tests passed!
```

Static analysis is clean:

```text
$ /home/fahd/flutter/bin/cache/dart-sdk/bin/dart analyze
Analyzing loom_workflow_service...
No issues found!
```

After the change, the exact `loom_workflow_service` count is 42 passing and 4
skipped: seven new unit passes, one new live-PostgreSQL skip, and no failure or
weakened test.

```text
$ /home/fahd/flutter/bin/cache/dart-sdk/bin/dart test --reporter expanded
...
00:01 +42 ~4: All tests passed!
```

The new PostgreSQL test is present and selected correctly, but this sandbox
could not execute it live because no database credential or reachable
port-forward is available:

```text
$ /home/fahd/flutter/bin/cache/dart-sdk/bin/dart test \
    test/postgres_guard_refusal_integration_test.dart \
    --name 'live PostgreSQL updateInstanceFields persists and is readable afterward' \
    --reporter expanded
Running build hooks...Running build hooks...00:00 +0: loading test/postgres_guard_refusal_integration_test.dart
00:00 +0: live PostgreSQL updateInstanceFields persists and is readable afterward
  Skip: Set LOOM_POSTGRES_PASSWORD to run against the k3s PostgreSQL port-forward.
00:00 +0 ~1: All tests skipped.
```

The complete, unchanged `loom_workflow_engine` suite remains green:

```text
$ cd app/packages/core/loom_workflow_engine
$ /home/fahd/flutter/bin/cache/dart-sdk/bin/dart test --reporter expanded
...
00:04 +232 ~2: All tests passed!
```

The OpenAPI file parses and contains the required operation and non-empty
request constraint:

```text
$ python3 -c "import yaml; ..."
OpenAPI YAML parsed; updateInstanceFields contract present
```

Final whitespace validation is clean:

```text
$ git diff --check
<no output; exit 0>
```

## Proposed next steps

1. In an environment with the existing k3s PostgreSQL port-forward and
   `LOOM_POSTGRES_PASSWORD`, run the focused live test above and retain its
   `+1: All tests passed!` output as the remaining Phase E.2 evidence.
2. Implement `aggregate`; it is confirmed as the last remaining real
   server-expansion ticket after Phase E.1 `createInstances` and this Phase E.2
   `updateInstanceFields` operation.

## Anything I could not do

- I could not produce the required live-PostgreSQL edit-persists execution
  proof in this sandbox. `LOOM_POSTGRES_PASSWORD` is unset, no local port is
  listening on `15432`, and the available cluster client cannot open its local
  API socket:

  ```text
  $ kubectl get pods -A -o wide
  Unable to connect to the server: dial tcp 127.0.0.1:6443: socket: operation not permitted
  ```

  The real-PostgreSQL test and its persistence plus service-readback assertions
  are implemented, but reporting its skipped output as a live pass would be
  inaccurate.
- All other requested implementation and runnable verification completed.
