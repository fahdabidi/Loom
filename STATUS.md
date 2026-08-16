# Phase E.3 — `aggregate`

## What changed

- Added `POST /v1/communities/{communityId}/instances/aggregate` with
  `operationId: aggregate` to the OpenAPI 3.1 workflow-engine contract. The
  read-only operation requires `CorrelationId` but no `IdempotencyKey`, accepts
  the exact six engine operations, an optional free-form equality `filter`, and
  an optional `groupBy` field.
- Added `AggregateRequest` and `AggregateResponse`. The response's required
  `result` property is an empty OpenAPI 3.1 schema, so it accurately permits a
  number, string, null, or grouped result array instead of narrowing the engine
  result to numbers.
- Added `WorkflowService._aggregate` within the existing database serial
  executor. It validates the correlation id, extracts the authenticated fan
  identity, parses the JSON body, sets the same unresolved-role sentinel used
  by the other read path, calls the shared engine, and returns `{result: ...}`.
  It makes no App Access request.
- Confirmed from `LocalWorkflowEngineApi.aggregate` that an unsupported `op`
  throws `ArgumentError.value`; `ArgumentError` is not a `StateError`. The HTTP
  adapter therefore validates `op` against `count`, `sum`, `avg`, `min`, `max`,
  and `countDistinct` before the engine call, mapping an unsupported operation
  to `400 invalid_request` rather than letting it reach the generic `500` path.
- Confirmed from `_readAllInstancesOfType`, `_readVisibleInstancesOfType`, and
  `aggregate` that a null `personaId` selects the unscoped system-truth path
  used by internal guard math. The HTTP handler never accepts a persona from
  the body and always passes `personaId: identity.fanId`. A visibility test
  sends a forged body `personaId: null` while seeding one visible and one hidden
  row; the returned count is one, directly excluding the unscoped path.
- Confirmed from `aggregateValues` that an empty `sum` returns `0`, while an
  empty `avg` returns `null`, and covered both through the HTTP endpoint.
- Added six service unit tests covering filtered count plus zero App Access
  calls, grouped sum results, empty-set sum/average semantics, unsupported-op
  `400`, missing/empty/malformed fields, and caller-scoped visibility.
- Added a credential-gated integration test to the existing live-PostgreSQL
  harness. It creates a unique schema, writes three real persisted rows, reads
  one back directly, sums the two matching rows through the Shelf service,
  expects `result: 12`, and drops the schema in `finally`.
- No file under
  `docs/references/{reference,guide,archetypes,communities}/`, no app-shell file,
  no existing workflow operation implementation, and no
  `app_access_client.dart` file was changed.

## Verification

The untouched `loom_workflow_service` baseline was 42 passing tests and 4
credential-gated skips:

```text
$ /home/fahd/flutter/bin/cache/dart-sdk/bin/dart test
...
00:01 +42 ~4: All tests passed!
```

All six new unit cases pass:

```text
$ /home/fahd/flutter/bin/cache/dart-sdk/bin/dart test \
    test/workflow_service_test.dart --name aggregate --reporter expanded
Running build hooks...Running build hooks...00:00 +0: loading test/workflow_service_test.dart
00:00 +0: aggregate returns a filtered count without App Access
00:00 +1: aggregate groups rows and returns each group value
00:00 +2: aggregate preserves empty sum and average semantics
00:00 +3: aggregate rejects an unsupported operation as 400
00:00 +4: aggregate rejects missing, empty, and malformed fields as 400
00:00 +5: aggregate counts only instances visible to the extracted fan
00:00 +6: All tests passed!
```

Static analysis is clean:

```text
$ /home/fahd/flutter/bin/cache/dart-sdk/bin/dart analyze
Analyzing loom_workflow_service...
No issues found!
```

After the change, the exact `loom_workflow_service` count is 48 passing and 5
skipped: six new unit passes, one new live-PostgreSQL skip, and no failure or
weakened test.

```text
$ /home/fahd/flutter/bin/cache/dart-sdk/bin/dart test --reporter expanded
...
00:03 +48 ~5: All tests passed!
```

The new PostgreSQL test compiles and is selected correctly, but this sandbox
could not execute it against a live server. This is skipped output, not a live
proof:

```text
$ /home/fahd/flutter/bin/cache/dart-sdk/bin/dart test \
    test/postgres_guard_refusal_integration_test.dart \
    --name 'live PostgreSQL aggregate reflects persisted rows' \
    --reporter expanded
Running build hooks...Running build hooks...00:00 +0: loading test/postgres_guard_refusal_integration_test.dart
00:00 +0: live PostgreSQL aggregate reflects persisted rows
  Skip: Set LOOM_POSTGRES_PASSWORD to run against the k3s PostgreSQL port-forward.
00:00 +0 ~1: All tests skipped.
```

The complete, unchanged `loom_workflow_engine` suite remains green:

```text
$ cd app/packages/core/loom_workflow_engine
$ /home/fahd/flutter/bin/cache/dart-sdk/bin/dart test --reporter expanded
...
00:12 +232 ~2: All tests passed!
```

The OpenAPI document parses, is confirmed as 3.1, and has the required
aggregate shapes:

```text
$ python3 - <<'PY'
... yaml.safe_load and aggregate contract assertions ...
PY
OpenAPI 3.1 YAML parsed; aggregate enum, free-form filter/result, and no-idempotency rule verified
```

Formatting and whitespace validation are clean:

```text
$ /home/fahd/flutter/bin/cache/dart-sdk/bin/dart format \
    lib/src/workflow_service.dart test/workflow_service_test.dart \
    test/postgres_guard_refusal_integration_test.dart
Formatted 3 files (3 changed) in 0.24 seconds.

$ git diff --check
<no output; exit 0>
```

## Proposed next steps

1. Run the focused live-PostgreSQL test above in the existing k3s
   port-forward environment with `LOOM_POSTGRES_PASSWORD`, and retain its
   `+1: All tests passed!` output as the outstanding Phase E.3 execution proof.
2. Proceed to Phase E.4: implement the app-shell `RemoteWorkflowEngineApi`
   client against the now-complete real server operation set.

This closes the real server-side operation coverage gap against
`WorkflowEngineApi`. The only interface methods left without server operations
are `dueNotifications` (it has no app-shell callers and was correctly excluded
per Phase E.1) and the synchronous `availableTransitions` variant (the
architecturally client-side-only form; the async authoritative variant is
already exposed).

## Anything I could not do

- I could not produce the required live-PostgreSQL aggregate execution proof
  in this sandbox. `LOOM_POSTGRES_PASSWORD` is unset, the k3s API cannot be
  reached because socket access is denied, Docker's local API is denied, and
  only the PostgreSQL client is installed locally:

  ```text
  $ kubectl get pods -A -o wide
  Unable to connect to the server: dial tcp 127.0.0.1:6443: socket: operation not permitted

  $ docker ps
  permission denied while trying to connect to the docker API at unix:///var/run/docker.sock
  ```

  The real-PostgreSQL test is implemented using the package's existing
  connection, unique-schema, and cleanup pattern, but reporting the skipped run
  as a live pass would be inaccurate.
- All other requested implementation and runnable verification completed.
