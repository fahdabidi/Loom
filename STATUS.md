# ACWS Phase B.1 status

## What changed

- Added this status report only. I did not scaffold `loom_workflow_service` or modify
  `loom_workflow_engine` because the ticket explicitly says to stop and report if a
  genuine engine change is required.
- Confirmed that `app/melos.yaml` discovers `packages/core/*`, so the eventual service
  belongs at `app/packages/core/loom_workflow_service`.
- Confirmed that the repository does not establish another Dart HTTP framework
  convention; `shelf` remains the appropriate choice when B.1 resumes.
- Found three PostgreSQL blockers in the engine store used by
  `LocalWorkflowEngineApi`:

  1. `WorkflowDatabase.upsertDefinition` emits SQLite-only
     `INSERT OR REPLACE` for every dialect
     (`app/packages/core/loom_workflow_engine/lib/src/store/database.dart:126`).
  2. `WorkflowDatabase.transaction` emits SQLite-only `BEGIN IMMEDIATE` for every
     dialect (`database.dart:337`). An allowed `applyTransition` necessarily reaches
     this path after the engine resolves its guard
     (`lib/src/api/local_workflow_engine_api.dart:874`).
  3. The PostgreSQL migration declares `created_at` and `updated_at` as `INTEGER`
     (`database.dart:105-106`), but instance writes store
     `DateTime.now().millisecondsSinceEpoch` (`database.dart:155` and `:198`). In
     PostgreSQL, `INTEGER` is 32-bit and cannot hold a current millisecond epoch.

  `drift_postgres` 1.3.1 does not translate these statements. Its `PgDatabase`
  delegate sends `runCustom` through `_runWithArgs`, which executes the supplied SQL
  verbatim. Consequently, wrapping a real `PgDatabase` with
  `WorkflowDatabase.withExecutor(..., dialect: WorkflowSqlDialect.postgres)` cannot
  support successful definition persistence, instance creation, or an allowed
  transition. Implementing only the pre-transaction refusal path would make the
  decisive test pass while leaving `applyTransition` non-functional, which would not
  satisfy the requirement to implement the operation for real.

## Verification

Commands used the SDK binary directly because the workspace's `dart` launcher tries
to update `/home/fahd/flutter/bin/cache/engine.stamp`, which is outside this run's
writable roots.

```text
$ cd app/packages/core/loom_workflow_engine
$ PATH=/home/fahd/flutter/bin/cache/dart-sdk/bin:$PATH dart analyze
Analyzing loom_workflow_engine...
No issues found!
```

```text
$ cd app/packages/core/loom_workflow_engine
$ PATH=/home/fahd/flutter/bin/cache/dart-sdk/bin:$PATH dart test --reporter expanded
...
00:08 +232: All tests passed!
```

This confirms the requested 232-test engine baseline is unchanged. No engine source
or test file was edited.

Static inspection of the dialect-sensitive statements produced:

```text
$ rg -n "INSERT OR REPLACE|BEGIN IMMEDIATE|created_at INTEGER|updated_at INTEGER" \
    app/packages/core/loom_workflow_engine/lib/src/store/database.dart
105:        created_at INTEGER NOT NULL,
106:        updated_at INTEGER NOT NULL,
126:      'INSERT OR REPLACE INTO workflow_definitions '
337:    await _db.runCustom('BEGIN IMMEDIATE');
```

I attempted to inspect the real k3s PostgreSQL already used by the Java services:

```text
$ kubectl get pods,services -A -o wide
Unable to connect to the server: dial tcp 127.0.0.1:6443: socket: operation not permitted
```

The execution sandbox blocks the local Kubernetes API socket, so no PostgreSQL
instance was used and no service integration test can honestly be reported. Once the
engine prerequisite is fixed, a future local or CI/dispatch run should use the same
real k3s PostgreSQL as the two Java services, expose its connection details through
test-only environment variables, create a test-specific database or schema, and run
the service test twice. It should not use Testcontainers, matching the tracker's
Docker 29/API 1.44 constraint.

## Proposed next steps

1. Add a narrowly scoped engine prerequisite ticket before resuming B.1. It should
   make `WorkflowDatabase` genuinely dialect-aware for PostgreSQL upsert, transaction
   handling, and 64-bit timestamp columns, and add PostgreSQL-backed store tests while
   preserving the 232 SQLite tests. This must be an explicit engine change with its
   own review; it should not be hidden inside the service commit.
2. Resume B.1 after that prerequisite: create
   `app/packages/core/loom_workflow_service`, use `shelf`, inject a small swappable
   principal extractor (for example, handlers receive a `PrincipalExtractor`
   callback whose temporary implementation reads `x-loom-fan-id` only from the
   request header), construct/reuse `LocalWorkflowEngineApi` over
   `WorkflowDatabase.withExecutor(PgDatabase(...), dialect: postgres)`, implement
   `applyTransition`, return honest 501 responses for the other four routes, and run
   the server-side guard-refusal integration test twice against real PostgreSQL. The
   decisive test should first show a client-side engine allowing an owner-guarded
   transition for the owner's fan id, then send the same transition over HTTP with a
   different header-derived fan id and no identity in the body. A service `403` plus
   an unchanged PostgreSQL row would prove that the service called the engine and
   independently refused the guard, rather than trusting the client's prior result.
   Phase C would replace only that callback's internals with JWT validation.
3. **B.2 — deployment:** add the service's container/build artifact, Kubernetes
   workload and service resources, configuration/secrets wiring, health/readiness
   checks, and ingress/routing. Verify the running pod and database schema rather than
   only committed manifests.
4. **B.3 — complete the workflow surface and authorization integration:** implement
   `replaceWorkflowDefinitions`, `queryInstances`, `createInstance`, and
   `availableTransitions`; integrate App Access role resolution so the token-derived
   fan id is mapped to server-resolved effective roles per community; and add the
   tracker's omission tests for unreadable instances and unavailable transitions.
   Phase C should then replace the B.1 principal extractor's internals with real JWT
   validation without changing service handlers.

## Anything I could not do

- I could not implement or test the service without either changing the engine or
  knowingly shipping an `applyTransition` endpoint that always fails after an allowed
  guard. The ticket disallows making that engine change silently and explicitly
  directs this stop-and-report outcome.
- I could not reach the k3s PostgreSQL from this sandbox because access to
  `127.0.0.1:6443` was denied. Therefore I did not run `dart analyze` or `dart test` in
  a new service package, did not run the decisive HTTP/PostgreSQL integration test
  twice, and do not claim those verification gates passed.
- I did not alter anything under `docs/references/`, did not modify or weaken an
  existing test, and did not touch the user's pre-existing untracked
  `ROOT_CAUSE_REPORT_2.md` or `ROOT_CAUSE_REPORT_3.md` files.
