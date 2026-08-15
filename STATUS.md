# ACWS `WorkflowDatabase` PostgreSQL dialect fix

## What changed

- Fixed the three PostgreSQL blockers identified by the Phase B.1 dispatch in
  `app/packages/core/loom_workflow_engine/lib/src/store/database.dart`:

  1. `upsertDefinition` keeps SQLite's existing `INSERT OR REPLACE` statement and
     uses PostgreSQL `INSERT ... ON CONFLICT (definition_id) DO UPDATE` for the
     PostgreSQL dialect. `definition_id` is the table's declared primary key, so it
     is the correct conflict target.
  2. `_executeTx` keeps SQLite's existing `BEGIN IMMEDIATE` and uses plain `BEGIN`
     for PostgreSQL, followed by the existing `COMMIT`/`ROLLBACK` handling.
  3. The `workflow_instances` migration keeps SQLite's existing `INTEGER` spelling
     for `created_at` and `updated_at`, while PostgreSQL now receives `BIGINT` for
     both millisecond-epoch columns.

- The exhaustive custom-SQL scan found one additional instance of the same dialect
  defect in this file: parameterized statements used SQLite `?` placeholders for
  PostgreSQL too. `drift_postgres` 1.3.1 sends `runCustom`/`runSelect` SQL verbatim,
  and PostgreSQL requires `$1`, `$2`, and so on. Every parameterized PostgreSQL path
  in `database.dart` now uses numbered placeholders; every existing SQLite SQL
  string remains unchanged.
- Added `test/postgres_database_integration_test.dart`. With k3s credentials present,
  it opens a real `postgres` connection, wraps it in `PgDatabase` and
  `WorkflowDatabase.withExecutor`, performs a conflicting definition upsert, creates
  an instance, applies a state-and-data transition through the engine transaction
  path, and reads the stored row back. It also asserts both persisted millisecond
  timestamps exceed PostgreSQL's 32-bit integer maximum.
- The PostgreSQL test creates a uniquely named schema in `loom_app_access`, sets that
  schema as its connection search path, and drops only that schema in `finally`.
  Shared Java-service schemas and tables are never cleaned or modified.
- Added the integration test's `drift_postgres` and `postgres` dev dependencies and
  refreshed `app/pubspec.lock` offline from the existing package cache.
- No existing test was changed or weakened. No file under
  `docs/references/{reference,guide,archetypes,communities}/` was edited. The
  pre-existing untracked `ROOT_CAUSE_REPORT_2.md` and `ROOT_CAUSE_REPORT_3.md` files
  were left untouched.

## Verification

Commands used the SDK binary directly because the workspace's `dart` launcher tries
to update Flutter cache files outside this run's writable roots.

Analysis:

```text
$ cd app/packages/core/loom_workflow_engine
$ PATH=/home/fahd/flutter/bin/cache/dart-sdk/bin:$PATH dart analyze
Analyzing loom_workflow_engine...
No issues found!
```

Full SQLite-backed suite:

```text
$ cd app/packages/core/loom_workflow_engine
$ PATH=/home/fahd/flutter/bin/cache/dart-sdk/bin:$PATH dart test --reporter expanded
...
00:01 +73: test/postgres_database_integration_test.dart: real PostgreSQL supports definition upsert, instance creation, and a transactional transition
  Skip: Set LOOM_POSTGRES_PASSWORD to run against the k3s PostgreSQL port-forward.
...
00:05 +232 ~1: All tests passed!
```

This preserves the requested baseline exactly: all 232 existing SQLite tests pass.
The one skip is the newly added, explicitly credential-gated real-PostgreSQL test.

The repository's Java-service deployment and runbook establish the intended real
connection as follows:

- Kubernetes namespace: `loom`
- Service: `postgres`, in-cluster host
  `postgres.loom.svc.cluster.local:5432`
- Local connection method: `kubectl -n loom port-forward svc/postgres 15432:5432`
- Test host/port: `127.0.0.1:15432`
- Database: `loom_app_access` (the test isolates itself in a unique schema)
- Credentials source: Kubernetes secret `loom/postgres-credentials`, keys `username`
  and `password`; the deployed username is supplied by that secret and the test
  defaults to the documented `loom` user. No credential value is printed or stored.
- Driver path: `postgres` `Connection.open` -> `PgDatabase.opened` ->
  `WorkflowDatabase.withExecutor(..., dialect: WorkflowSqlDialect.postgres)`
- TLS: disabled for this local k3s port-forward, matching the cluster-local setup.

The reproducible unsandboxed command sequence is:

```bash
kubectl -n loom port-forward svc/postgres 15432:5432 &
PGPW=$(kubectl -n loom get secret postgres-credentials \
  -o jsonpath='{.data.password}' | base64 -d)
cd app/packages/core/loom_workflow_engine
LOOM_POSTGRES_PASSWORD="$PGPW" \
  PATH=/home/fahd/flutter/bin/cache/dart-sdk/bin:$PATH \
  dart test test/postgres_database_integration_test.dart --reporter expanded
```

This run attempted that same route. The sandbox denied access to the local Kubernetes
API before the secret or service could be reached:

```text
$ kubectl -n loom get secret postgres-credentials -o jsonpath='{.data.username}'
Unable to connect to the server: dial tcp 127.0.0.1:6443: socket: operation not permitted

$ kubectl -n loom port-forward svc/postgres 15432:5432
Unable to connect to the server: dial tcp 127.0.0.1:6443: socket: operation not permitted
```

A direct invocation of the integration test likewise fails at socket creation before
PostgreSQL authentication (the supplied placeholder is not a real credential):

```text
$ LOOM_POSTGRES_PASSWORD='<unavailable-in-sandbox>' \
    PATH=/home/fahd/flutter/bin/cache/dart-sdk/bin:$PATH \
    dart test test/postgres_database_integration_test.dart --reporter expanded
00:00 +0: real PostgreSQL supports definition upsert, instance creation, and a transactional transition
00:00 +0 -1: real PostgreSQL supports definition upsert, instance creation, and a transactional transition [E]
  SocketException: Connection failed (OS Error: Operation not permitted, errno = 1), address = 127.0.0.1, port = 15432
...
00:00 +0 -1: Some tests failed.
```

No Testcontainers or replacement database was used.

## Proposed next steps

1. Run the single PostgreSQL integration test with the unsandboxed port-forward and
   secret command above. Its expected success terminator is `+1: All tests passed!`.
2. Once that real-database gate is green, resume Phase B.1 and scaffold
   `loom_workflow_service` over this corrected shared store. The Phase B.1 decisive
   server-side guard-refusal test should use the same real k3s PostgreSQL instance.

## Anything I could not do

- I could not complete the required successful real-PostgreSQL execution. This
  Codex process runs in an isolated network namespace that denies both the local k3s
  API socket at `127.0.0.1:6443` and the port-forward endpoint at
  `127.0.0.1:15432` with `OS Error: Operation not permitted`. The failure occurs
  before credential retrieval, TCP connection, SQL parsing, or authentication, so I
  do not claim the real-PostgreSQL test passed.
