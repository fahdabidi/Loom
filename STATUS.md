# ACWS — PostgreSQL sorted `queryInstancesKeyset` fix

## What changed

- Fixed both PostgreSQL query shapes in
  `WorkflowDatabase.queryInstancesKeyset`:

  ```sql
  instance_data::jsonb ->> $2
  instance_data::jsonb ->> $3
  ```

  The old `#>>` operator requires a `text[]` right operand, while
  `drift_postgres` bound the Dart string `'{title}'` as scalar PostgreSQL
  `text`. PostgreSQL therefore tried to resolve the nonexistent
  `jsonb #>> text` operator. `->>` is the correct operator here because the
  engine consistently treats `sortKey` as one top-level map key, including
  cursor comparison and cursor construction through `data[sortKey]`.
- Kept the sort key fully parameterized. The bound value is now the plain key
  (`title`) instead of an array-literal-looking scalar string (`{title}`). No
  key is interpolated into SQL.
- Checked the pinned drivers before choosing the fix. `postgres 3.5.12`
  provides `Type.textArray` and `TypedValue`, and `drift_postgres 1.3.1`
  preserves an incoming `TypedValue`. However, using that from engine library
  code would require adding a runtime Postgres-driver dependency to a package
  whose executor boundary is deliberately driver-independent so it remains
  suitable for the on-device SQLite app. A text-to-`text[]` cast would also
  retain path traversal semantics the API does not implement. `->>` matches
  the existing top-level-key contract directly and works with the driver's
  supported scalar-text binding.
- Did not revive SQL interpolation. In addition to being unnecessary, the
  workflow service currently forwards any non-empty `sortKey` query value, so
  the historical “never caller-supplied” comment is not a sufficient safety
  invariant.
- Added a focused real-PostgreSQL regression to
  `postgres_database_integration_test.dart`. It asserts ordering through both
  conditional branches: all workflow types (`workflowType == null`) and one
  filtered workflow type (`workflowType != null`).
- Checked the SQLite branch. `json_extract` expects its JSON path as text, and
  the existing `$.<sortKey>` string is bound as text, so it has no analogous
  operand-type mismatch. Its logic was not changed.
- No file under `docs/references/{reference,guide,archetypes,communities}/` was
  edited, and nothing in `loom_workflow_service` was changed.

## Verification

Engine static analysis is clean:

```text
$ cd app/packages/core/loom_workflow_engine
$ /home/fahd/flutter/bin/cache/dart-sdk/bin/dart analyze
Analyzing loom_workflow_engine...
No issues found!
```

The ordinary `dart test` entry point attempted an online Pub advisory refresh,
which this sandbox cannot reach:

```text
$ /home/fahd/flutter/bin/cache/dart-sdk/bin/dart test
Running build hooks...Running build hooks...
ClientException with SocketException: Failed host lookup: 'pub.dev'
(OS Error: Name or service not known, errno = -2),
uri=https://pub.dev/api/packages/archive/advisories
```

`dart pub get --offline` completed from the already-cached, pinned workspace
lockfile. I then invoked the resolved `test` snapshot directly to bypass only
Pub's network refresh and execute the same complete engine test suite:

```text
$ cd app
$ /home/fahd/flutter/bin/cache/dart-sdk/bin/dart pub get --offline
Resolving dependencies...
Downloading packages...
Got dependencies!
11 packages have newer versions incompatible with dependency constraints.

$ cd packages/core/loom_workflow_engine
$ /home/fahd/flutter/bin/cache/dart-sdk/bin/dart \
    --packages=/home/fahd/Loom/app/.dart_tool/package_config.json \
    /home/fahd/Loom/app/.dart_tool/pub/bin/test/test.dart-3.11.5.snapshot
00:00 +41: test/postgres_database_integration_test.dart: real PostgreSQL supports definition upsert, instance creation, and a transactional transition
  Skip: Set LOOM_POSTGRES_PASSWORD to run against the k3s PostgreSQL port-forward.
00:00 +42 ~1: test/postgres_database_integration_test.dart: real PostgreSQL sorts queryInstancesKeyset by a bound top-level key with and without a workflow type filter
  Skip: Set LOOM_POSTGRES_PASSWORD to run against the k3s PostgreSQL port-forward.
00:04 +232 ~2: All tests passed!
```

This confirms the unchanged SQLite-backed suite remains at 232 passing. The
two skips are the existing and newly-added live-PostgreSQL integration tests,
because the Kubernetes secret could not be retrieved in this sandbox.

The required live gate could not be entered. The read-only service/secret
discovery command failed before any port-forward or test process could start:

```text
$ kubectl get svc postgres -n loom -o wide
Unable to connect to the server: dial tcp 127.0.0.1:6443:
socket: operation not permitted
```

The alternative local k3s/containerd Unix socket is denied by the same
sandbox boundary:

```text
$ k3s ctr images list
ctr: failed to list images: connection error: desc =
"transport: Error while dialing: dial unix
/run/k3s/containerd/containerd.sock: connect: operation not permitted"
```

Therefore neither the new focused engine regression nor the exact Phase B.2
service reproduction has a real-PostgreSQL pass to report from this process.
That mandatory verification is explicitly not claimed.

## Proposed next steps

Re-run the two decisive tests from an unsandboxed shell that can reach the live
k3s API, then resume/re-verify Phase B.2 only after both are green:

```bash
kubectl -n loom port-forward svc/postgres 15432:5432 \
  >/tmp/loom-workflow-postgres-port-forward.log 2>&1 &
LOOM_WORKFLOW_PORT_FORWARD_PID=$!
trap 'kill "$LOOM_WORKFLOW_PORT_FORWARD_PID"' EXIT

LOOM_TEST_POSTGRES_USERNAME="$(kubectl -n loom get secret postgres-credentials \
  -o jsonpath='{.data.username}' | base64 -d)"
LOOM_TEST_POSTGRES_PASSWORD="$(kubectl -n loom get secret postgres-credentials \
  -o jsonpath='{.data.password}' | base64 -d)"

cd app/packages/core/loom_workflow_engine
LOOM_POSTGRES_USERNAME="$LOOM_TEST_POSTGRES_USERNAME" \
LOOM_POSTGRES_PASSWORD="$LOOM_TEST_POSTGRES_PASSWORD" \
  dart test test/postgres_database_integration_test.dart \
  --plain-name 'real PostgreSQL sorts queryInstancesKeyset by a bound top-level key with and without a workflow type filter' \
  --reporter expanded

cd ../loom_workflow_service
LOOM_POSTGRES_USERNAME="$LOOM_TEST_POSTGRES_USERNAME" \
LOOM_POSTGRES_PASSWORD="$LOOM_TEST_POSTGRES_PASSWORD" \
  dart test test/postgres_guard_refusal_integration_test.dart \
  --plain-name 'Phase B.2 definition replacement and authoritative reads use PostgreSQL' \
  --reporter expanded
```

The expected outcome is one passing test from each command, with no 500 on the
service's sorted `queryInstances` request. Once captured, Phase B.2 can be
resumed and re-verified against that live evidence.

## Anything I could not do

- I could not run either required integration test against the live k3s
  PostgreSQL service. This process is denied socket access to both the local
  Kubernetes API and the k3s/containerd Unix socket, cannot start the required
  port-forward, and therefore cannot retrieve or use `postgres-credentials`.
- I could not obtain a successful invocation of the literal `dart test`
  front-end because it insists on refreshing Pub's advisory endpoint, while
  outbound DNS/network access is disabled. The resolved test snapshot did run
  the complete pinned suite successfully (`232` passing, `2` PostgreSQL tests
  skipped), but this is recorded separately rather than presented as a clean
  literal-command result.
