# ACWS Phase B.1 — workflow-service scaffold and server guard proof

## What changed

- Added the workspace package
  `app/packages/core/loom_workflow_service`, following `app/melos.yaml`'s
  `packages/core/*` discovery convention and registering it in
  `app/pubspec.yaml`'s Dart workspace.
- Added a direct path dependency on `loom_workflow_engine`, plus `shelf`,
  `postgres`, and the required exact `drift_postgres: 1.3.1` dependency. No
  workflow models, guards, effects, visibility logic, or evaluator code was
  copied into the service.
- Added a runnable Shelf server backed by
  `WorkflowDatabase.withExecutor(PgDatabase..., dialect: postgres)`. It owns
  one PostgreSQL connection and serializes whole transition calls so two HTTP
  requests cannot interleave statements inside the engine's explicit
  `BEGIN`/`COMMIT` boundary.
- Implemented the OpenAPI `applyTransition` route:
  `POST /v1/communities/{communityId}/instances/{instanceId}/transitions`.
  The adapter validates the required correlation/idempotency headers and JSON
  request shape, derives `workflowType` from the stored instance, verifies the
  instance belongs to the path community, calls
  `LocalWorkflowEngineApi.applyTransition`, and returns the persisted state,
  data, and timestamp. It maps the engine's outcomes to the specified 400,
  403, 404, and 409 response classes without evaluating a guard itself. The
  403 body is deliberately generic and does not disclose the failed clause.
- Added explicit `501 Not Implemented` responses naming each of the four
  deferred operations: `replaceWorkflowDefinitions`, `queryInstances`,
  `createInstance`, and `availableTransitions`.
- Added the small, injected `WorkflowIdentityExtractor` boundary. The Phase
  B.1 implementation reads only `X-Loom-Fan-Id`; the service never reads
  identity or roles from request JSON. The header adapter is documented as a
  temporary pre-auth test seam, not a permanent authentication protocol.
  Phase C can replace that implementation with JWT validation without
  changing routing or engine execution.
- Added fast Shelf-handler tests for the four honest stubs, required headers
  and JSON, missing authentication, community isolation, success, state
  conflict, and body-identity forgery.
- Added
  `test/postgres_guard_refusal_integration_test.dart`. It opens the real
  Postgres driver/executor path in an isolated schema and proves the intended
  distinction:

  1. a separate client-side `LocalWorkflowEngineApi` allows and applies the
     owner transition;
  2. the service receives the same transition with a forged owner `fanId` in
     the body but an attacker identity from the extraction boundary, returns
     `403 workflow_guard_refused`, and leaves the PostgreSQL row in `draft`;
  3. the same service route with the extracted owner identity returns 200 and
     persists `approved`, ruling out a blanket HTTP denial.

- No file in `loom_workflow_engine` was modified. No existing test was changed
  or weakened. No file under
  `docs/references/{reference,guide,archetypes,communities}/` was edited. The
  pre-existing untracked `ROOT_CAUSE_REPORT_2.md` and
  `ROOT_CAUSE_REPORT_3.md` remain untouched.

## Verification

Dependencies were resolved entirely from the existing cache:

```text
$ cd app
$ /home/fahd/flutter/bin/cache/dart-sdk/bin/dart pub get --offline
Resolving dependencies...
Downloading packages...
...
Got dependencies!
11 packages have newer versions incompatible with dependency constraints.
```

New-package formatting and analysis are clean:

```text
$ cd app/packages/core/loom_workflow_service
$ /home/fahd/flutter/bin/cache/dart-sdk/bin/dart format .
Formatted 7 files (0 changed) in 0.04 seconds.

$ /home/fahd/flutter/bin/cache/dart-sdk/bin/dart analyze
Analyzing loom_workflow_service...
No issues found!
```

The normal `dart test` launcher tries to refresh pub.dev advisories in this
network-restricted sandbox and exits before starting package:test:

```text
$ /home/fahd/flutter/bin/cache/dart-sdk/bin/dart test --reporter expanded
Running build hooks...Running build hooks...ClientException with SocketException:
Failed host lookup: 'pub.dev' (OS Error: Name or service not known, errno = -2),
uri=https://pub.dev/api/packages/archive/advisories
```

I therefore invoked the installed package:test entrypoint directly with the
workspace-generated package config. This is the same test runner and test
suite, without the failing pub advisory preflight. Two consecutive runs both
passed every fast test; the real-PostgreSQL test was credential-gated and
therefore skipped in these runs:

```text
$ /home/fahd/flutter/bin/cache/dart-sdk/bin/dart \
    --packages=/home/fahd/Loom/app/.dart_tool/package_config.json \
    /home/fahd/.pub-cache/hosted/pub.dev/test-1.30.0/bin/test.dart \
    --reporter expanded
00:00 +0: test/postgres_guard_refusal_integration_test.dart: a client-allowed transition is genuinely refused by the service guard
  Skip: Set LOOM_POSTGRES_PASSWORD to run against the k3s PostgreSQL port-forward.
00:00 +0 ~1: test/workflow_service_test.dart: the other four OpenAPI operations return explicit 501 responses
00:00 +1 ~1: test/workflow_service_test.dart: applyTransition requires identity from the extractor boundary
00:00 +2 ~1: test/workflow_service_test.dart: applyTransition validates required OpenAPI headers and JSON
00:00 +3 ~1: test/workflow_service_test.dart: applyTransition ignores a body identity and evaluates the header fan
00:00 +4 ~1: test/workflow_service_test.dart: an instance belonging to another community is returned as absent
00:00 +5 ~1: All tests passed!

$ /home/fahd/flutter/bin/cache/dart-sdk/bin/dart \
    --packages=/home/fahd/Loom/app/.dart_tool/package_config.json \
    /home/fahd/.pub-cache/hosted/pub.dev/test-1.30.0/bin/test.dart \
    --reporter expanded
00:00 +0: test/postgres_guard_refusal_integration_test.dart: a client-allowed transition is genuinely refused by the service guard
  Skip: Set LOOM_POSTGRES_PASSWORD to run against the k3s PostgreSQL port-forward.
...
00:00 +5 ~1: All tests passed!
```

The shared engine remains clean and unchanged at its requested baseline:

```text
$ cd app/packages/core/loom_workflow_engine
$ /home/fahd/flutter/bin/cache/dart-sdk/bin/dart analyze
Analyzing loom_workflow_engine...
No issues found!

$ /home/fahd/flutter/bin/cache/dart-sdk/bin/dart \
    --packages=/home/fahd/Loom/app/.dart_tool/package_config.json \
    /home/fahd/.pub-cache/hosted/pub.dev/test-1.30.0/bin/test.dart \
    --reporter expanded
...
00:04 +232 ~1: All tests passed!
```

The `~1` is the engine's existing credential-gated PostgreSQL integration test;
all 232 existing SQLite-backed tests pass. `git diff` reports no engine file.

The intended real database is the same k3s PostgreSQL used by the two Java
services, because it is the repository's established integration target and
avoids the known Docker 29/Testcontainers incompatibility:

- namespace/service: `loom/postgres`
- local access: `kubectl -n loom port-forward svc/postgres 15432:5432`
- database: `loom_app_access`
- username/password: Kubernetes secret `loom/postgres-credentials`
- test isolation: a unique `workflow_service_test_<timestamp>_<pid>` schema,
  dropped in `finally`
- driver path: `postgres Connection` -> `PgDatabase.opened` ->
  `WorkflowDatabase.withExecutor(..., dialect: postgres)` ->
  `LocalWorkflowEngineApi.applyTransition`

This run attempted that instance. The sandbox denied its Kubernetes API socket
before the service or secret could be reached:

```text
$ kubectl -n loom get svc postgres -o jsonpath='{.metadata.name}'
Unable to connect to the server: dial tcp 127.0.0.1:6443:
socket: operation not permitted
```

A direct forced invocation proves the failure is also before PostgreSQL
authentication, SQL, or guard evaluation:

```text
$ LOOM_POSTGRES_PASSWORD='<unavailable-in-sandbox>' <package:test runner> \
    test/postgres_guard_refusal_integration_test.dart --reporter expanded
00:00 +0: a client-allowed transition is genuinely refused by the service guard
00:00 +0 -1: a client-allowed transition is genuinely refused by the service guard [E]
  SocketException: Connection failed (OS Error: Operation not permitted, errno = 1),
  address = 127.0.0.1, port = 15432
00:00 +0 -1: Some tests failed.
```

No Testcontainers or substitute database was used. A future unsandboxed
CI/dispatch run can reproduce the real gate twice with:

```bash
kubectl -n loom port-forward svc/postgres 15432:5432 \
  >/tmp/loom-workflow-postgres-port-forward.log 2>&1 &
LOOM_PORT_FORWARD_PID=$!
trap 'kill "$LOOM_PORT_FORWARD_PID"' EXIT

LOOM_TEST_POSTGRES_USERNAME="$(kubectl -n loom get secret postgres-credentials \
  -o jsonpath='{.data.username}' | base64 -d)"
LOOM_TEST_POSTGRES_PASSWORD="$(kubectl -n loom get secret postgres-credentials \
  -o jsonpath='{.data.password}' | base64 -d)"

cd app/packages/core/loom_workflow_service
LOOM_POSTGRES_USERNAME="$LOOM_TEST_POSTGRES_USERNAME" \
LOOM_POSTGRES_PASSWORD="$LOOM_TEST_POSTGRES_PASSWORD" \
  dart test test/postgres_guard_refusal_integration_test.dart --reporter expanded
LOOM_POSTGRES_USERNAME="$LOOM_TEST_POSTGRES_USERNAME" \
LOOM_POSTGRES_PASSWORD="$LOOM_TEST_POSTGRES_PASSWORD" \
  dart test test/postgres_guard_refusal_integration_test.dart --reporter expanded
```

Each successful run should terminate with `+1: All tests passed!`.

## Proposed next steps

1. **B.2 — deployment:** add the Dockerfile/image build, Kubernetes Deployment
   and Service, health/readiness endpoints, secret/config wiring, resource
   limits, and ingress/network-policy integration. Verify the running pod
   against the live PostgreSQL service; do not treat repository state as
   deployment evidence.
2. **B.3 — complete the service surface and authorization inputs:** implement
   `replaceWorkflowDefinitions`, `queryInstances`, `createInstance`, and
   `availableTransitions` through the same shared engine/store boundary. Add
   App Access role-resolution integration and a short-lived cache keyed by
   `(fanId, communityId)`; register only server-resolved roles with the engine,
   never body/header role claims. Finish durable idempotency-key handling. The
   Phase B completion gates must then prove `availableTransitions` omits a
   forbidden action and `queryInstances` omits an unreadable instance.
3. **Phase C dependency:** replace only `WorkflowIdentityExtractor`'s temporary
   header implementation with real JWT validation and token-derived `fanId`;
   verify unauthenticated calls against the deployed service return 401.

## Anything I could not do

- I could not perform even one successful real-PostgreSQL execution of the new
  service integration test, so I also could not run that test successfully
  twice. This process is denied socket access to both the local k3s API at
  `127.0.0.1:6443` and the intended port-forward at `127.0.0.1:15432` with
  `OS Error: Operation not permitted`. The failure occurs before credentials,
  connection negotiation, schema creation, HTTP adaptation, or engine guard
  evaluation. Consequently, I do **not** claim the decisive Phase B.1
  real-database completion gate has passed in this environment.
- The normal `dart test` command could not get past its automatic pub.dev
  advisory refresh because outbound DNS/network access is blocked. The cached
  package:test runner executed the actual fast suite twice successfully, as
  shown above.
