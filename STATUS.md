# ACWS Phase B.2 — definition replacement and authoritative reads

## What changed

- Implemented `replaceWorkflowDefinitions` at
  `PUT /v1/communities/{communityId}/workflow-definitions` in the existing
  `WorkflowService` routing/error/identity pattern.
  - Requires the OpenAPI correlation and idempotency headers and an identity
    from the injected `WorkflowIdentityExtractor`.
  - Accepts only `specVersion: 4`. An unsupported version returns a 422
    `WorkflowDefinitionsSummary` without attempting to parse the newer
    definition grammar.
  - Separates malformed JSON/model structure (`400 invalid_request`) from
    structurally valid definitions the engine cannot execute (`422` findings).
    The executable checks cover unknown surface families, invalid bespoke
    actions, malformed/unknown/cyclic formulas, and unknown effect operations.
  - Persists the raw definition maps and replaces all definitions for the
    community inside one database transaction. The response reports sorted
    `workflowTypes` and `removedWorkflowTypes`.
  - Clears and repopulates the community engine's definition cache only after
    the durable replacement succeeds. Instances of a removed workflow type
    remain stored for audit/recovery purposes but become unreachable through
    authoritative reads.

- Implemented `queryInstances` at
  `GET /v1/communities/{communityId}/instances`.
  - Requires the correlation header and an extracted identity; request data
    cannot name its own fan or roles.
  - Passes `sortKey`, the opaque cursor, and the OpenAPI `limit` (default 25,
    range 1–100) into `LocalWorkflowEngineApi.queryInstances`.
  - Added an optional concrete-engine/database `workflowType` predicate before
    keyset pagination. Filtering after pagination would produce short pages,
    incorrect `hasMore` values, and skipped/duplicated rows.
  - Returns only the engine's hydrated, visibility-filtered instances. The
    security test includes a hidden instance id and secret value and proves
    neither string occurs anywhere in the response—not even in a redacted
    stub.
  - The server engine treats a missing definition as unreadable. This is the
    fail-closed behavior required for wholesale definition replacement.

- Implemented `availableTransitions` at
  `GET /v1/communities/{communityId}/instances/{instanceId}/available-transitions`.
  - Requires the correlation header and an extracted identity.
  - Reads the instance through a new single-instance engine method that shares
    `queryInstances`' hydration and visibility code. Missing, cross-community,
    retired, and unreadable instances all return the same 404, so the route
    does not disclose existence or state.
  - Calls `LocalWorkflowEngineApi.availableTransitionsAsync` for the actual
    guard evaluation. Forbidden transitions are absent, while allowed
    transitions include the OpenAPI `transitionId`, `label`, optional
    `action`/`tone`, and declared input specifications.
  - Updated `availableTransitionsAsync` to load a persisted definition on a
    cold engine cache instead of incorrectly returning an empty list until a
    different operation happened to hydrate that cache first.

- Kept `createInstance` as the same explicit
  `501 operation_not_implemented` stub. Its implementation still depends on
  App Access's per-workflow `create` permission and remains Phase B.3 work.
  `applyTransition`'s route, implementation, and five B.1 unit behaviors were
  not changed.

- Added the specVersion 4 `allowedRoleIds` spelling as an alias at the shared
  model boundary so the engine cannot silently ignore a role guard. Until B.3
  resolves real roles from App Access, the two new read operations register a
  non-matching internal role placeholder. This deliberately fails role-only
  reads/actions closed and prevents a fan whose id happens to equal a role id
  from claiming that role. A unit test proves that case returns no instances.

- Added one real-PostgreSQL integration test, beside B.1's existing test and
  using the same `drift_postgres` connection, environment variables, unique
  schema, and cleanup pattern. The test exercises all three B.2 operations:
  atomic wholesale replacement/removal, server-side visibility omission, and
  async transition omission/admission.

- The service now has 11 unit tests, up from the B.1 baseline of 5. The
  integration-test count is 2, up from 1: the unchanged B.1 guard-refusal test
  plus the new B.2 three-operation PostgreSQL test.

- No file under
  `docs/references/{reference,guide,archetypes,communities}/` was edited. The
  pre-existing untracked `ROOT_CAUSE_REPORT_2.md` and
  `ROOT_CAUSE_REPORT_3.md` remain untouched.

### Read path versus the serial executor

`queryInstances` and `availableTransitions` do go through the same
`_databaseSerialExecutor` as writes.

This is a correctness requirement for the current database ownership model,
not a conservative guess. `WorkflowDatabase.transaction` issues raw `BEGIN`,
then runs later reads/writes, then issues raw `COMMIT` or `ROLLBACK` through the
same `_db` executor. The service supplies `PgDatabase.opened(connection)`, and
`drift_postgres` 1.3.1 implements that executor with one `_openedSession` and a
`NoTransactionDelegate`. Its `isSequential: true` setting sequences individual
statements only; it does not reserve the connection from `BEGIN` through
`COMMIT` for one HTTP request.

Consequently, a read that bypassed the service queue could be scheduled after
another request's `BEGIN` and before its `COMMIT`. It would run inside that
request's transaction, could observe data that later rolls back, and could
affect guard/visibility results using an in-flight state. The correct current
choice is therefore to serialize reads with writes. The performance cost is
real for `queryInstances`; the safe optimization is a future store redesign
using a connection pool plus transaction-scoped sessions, after which ordinary
reads can use separate connections and bypass the write queue.

## Verification

Service analysis is clean:

```text
$ cd app/packages/core/loom_workflow_service
$ /home/fahd/flutter/bin/cache/dart-sdk/bin/dart analyze
Analyzing loom_workflow_service...
No issues found!
```

The normal requested launcher still fails before package:test because Dart pub
tries to refresh advisories from the network-restricted sandbox:

```text
$ /home/fahd/flutter/bin/cache/dart-sdk/bin/dart test --reporter expanded
Running build hooks...Running build hooks...
ClientException with SocketException: Failed host lookup: 'pub.dev'
(OS Error: Name or service not known, errno = -2),
uri=https://pub.dev/api/packages/archive/advisories
```

The cached package:test entrypoint ran the actual service suite successfully:

```text
$ /home/fahd/flutter/bin/cache/dart-sdk/bin/dart \
    --packages=/home/fahd/Loom/app/.dart_tool/package_config.json \
    /home/fahd/.pub-cache/hosted/pub.dev/test-1.30.0/bin/test.dart \
    --reporter expanded
00:00 +0: test/postgres_guard_refusal_integration_test.dart: a client-allowed transition is genuinely refused by the service guard
  Skip: Set LOOM_POSTGRES_PASSWORD to run against the k3s PostgreSQL port-forward.
00:00 +0 ~1: test/postgres_guard_refusal_integration_test.dart: Phase B.2 definition replacement and authoritative reads use PostgreSQL
  Skip: Set LOOM_POSTGRES_PASSWORD to run against the k3s PostgreSQL port-forward.
00:00 +0 ~2: test/workflow_service_test.dart: createInstance remains an explicit 501 response
00:00 +1 ~2: test/workflow_service_test.dart: replaceWorkflowDefinitions replaces wholesale and reports removals
00:00 +2 ~2: test/workflow_service_test.dart: replaceWorkflowDefinitions distinguishes malformed input from 422 findings
00:00 +3 ~2: test/workflow_service_test.dart: queryInstances omits an unreadable instance instead of redacting it
00:00 +4 ~2: test/workflow_service_test.dart: queryInstances never treats the extracted fan id as a role claim
00:00 +5 ~2: test/workflow_service_test.dart: queryInstances passes workflow type, sort, and cursor pagination
00:00 +6 ~2: test/workflow_service_test.dart: availableTransitions omits a guarded action and returns it for the owner
00:00 +7 ~2: test/workflow_service_test.dart: applyTransition requires identity from the extractor boundary
00:00 +8 ~2: test/workflow_service_test.dart: applyTransition validates required OpenAPI headers and JSON
00:00 +9 ~2: test/workflow_service_test.dart: applyTransition ignores a body identity and evaluates the header fan
00:00 +10 ~2: test/workflow_service_test.dart: an instance belonging to another community is returned as absent
00:00 +11 ~2: All tests passed!
```

The shared engine analyzes cleanly and its requested suite remains unchanged at
232 passing tests. The one skip is its pre-existing credential-gated PostgreSQL
test:

```text
$ cd app/packages/core/loom_workflow_engine
$ /home/fahd/flutter/bin/cache/dart-sdk/bin/dart analyze
Analyzing loom_workflow_engine...
No issues found!

$ /home/fahd/flutter/bin/cache/dart-sdk/bin/dart \
    --packages=/home/fahd/Loom/app/.dart_tool/package_config.json \
    /home/fahd/.pub-cache/hosted/pub.dev/test-1.30.0/bin/test.dart \
    --reporter compact
00:08 +232 ~1: 1 skipped test.
00:08 +232 ~1: All other tests passed!
```

Whitespace and scope checks are clean:

```text
$ git diff --check
# no output

$ git diff --cached --name-only
STATUS.md
app/packages/core/loom_workflow_engine/lib/loom_workflow_engine.dart
app/packages/core/loom_workflow_engine/lib/src/api/local_workflow_engine_api.dart
app/packages/core/loom_workflow_engine/lib/src/models/workflow_models.dart
app/packages/core/loom_workflow_engine/lib/src/store/database.dart
app/packages/core/loom_workflow_service/README.md
app/packages/core/loom_workflow_service/lib/src/definition_validation.dart
app/packages/core/loom_workflow_service/lib/src/workflow_service.dart
app/packages/core/loom_workflow_service/test/postgres_guard_refusal_integration_test.dart
app/packages/core/loom_workflow_service/test/workflow_service_test.dart
```

The live k3s PostgreSQL gate could not be entered from this sandbox. The
read-only discovery command fails before service lookup or secret retrieval:

```text
$ kubectl -n loom get svc postgres -o jsonpath='{.metadata.name}{"\\n"}'
Unable to connect to the server: dial tcp 127.0.0.1:6443:
socket: operation not permitted
```

The new integration test is ready for the established live reproduction:

```bash
kubectl -n loom port-forward svc/postgres 15432:5432 \
  >/tmp/loom-workflow-postgres-port-forward.log 2>&1 &
LOOM_WORKFLOW_PORT_FORWARD_PID=$!
trap 'kill "$LOOM_WORKFLOW_PORT_FORWARD_PID"' EXIT

LOOM_TEST_POSTGRES_USERNAME="$(kubectl -n loom get secret postgres-credentials \
  -o jsonpath='{.data.username}' | base64 -d)"
LOOM_TEST_POSTGRES_PASSWORD="$(kubectl -n loom get secret postgres-credentials \
  -o jsonpath='{.data.password}' | base64 -d)"

cd app/packages/core/loom_workflow_service
LOOM_POSTGRES_USERNAME="$LOOM_TEST_POSTGRES_USERNAME" \
LOOM_POSTGRES_PASSWORD="$LOOM_TEST_POSTGRES_PASSWORD" \
  dart test test/postgres_guard_refusal_integration_test.dart \
  --plain-name 'Phase B.2 definition replacement and authoritative reads use PostgreSQL' \
  --reporter expanded
```

## Proposed next steps

Phase B.3 remains the right next slice:

1. Add the App Access client and a short-lived role cache keyed by
   `(fanId, communityId)`. Register only server-resolved role ids with the
   engine; never accept roles from headers, query parameters, or JSON bodies.
2. Use App Access's package role vocabulary to emit a real
   `undeclared_role_in_guard` definition finding. The B.2 request schema does
   not carry declared roles, so that cross-package check needs the B.3 client.
3. Implement `createInstance` only after the client's derived
   archetype-`create` permission check exists. Keep the current 501 until then.
4. Add the workflow-service image/Kubernetes deployment and run both service
   integration tests against the live `loom/postgres` service. A pooled,
   transaction-scoped database ownership model can then remove read requests
   from the serial write queue without sacrificing isolation.

## Anything I could not do

- I could not successfully run the new test against the real k3s PostgreSQL
  service. This process is denied access to the local Kubernetes API socket at
  `127.0.0.1:6443` with `OS Error: Operation not permitted`, cannot retrieve the
  `postgres-credentials` secret, and has no pre-existing
  `LOOM_POSTGRES_PASSWORD`. Therefore the required live-PostgreSQL verification
  gate is **not claimed as passed** in this environment. The test itself is
  present and uses the exact B.1 connection/schema/cleanup path, but a future
  unsandboxed run must execute it before Phase B.2 is considered independently
  verified.
- The service cannot yet distinguish a declared App Access role from an
  undeclared role referenced by `allowedRoleIds`, because this OpenAPI request
  contains only `specVersion` and workflow definitions—no package role
  vocabulary—and the App Access client is Phase B.3. It does not silently
  ignore the construct or grant access: the shared parser recognizes
  `allowedRoleIds`, and server reads/transitions fail role checks closed until
  B.3 supplies resolved roles. The missing install-time cross-check is recorded
  above as B.3 work rather than replaced with a client-claimed role list.
