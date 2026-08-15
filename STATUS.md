# ACWS Phase B.3 — App Access-authorized `createInstance`

## What changed

- Confirmed before implementation that the workflow service's `communityId`
  path value is **not** the App Access `communityHandle`, and cannot safely be
  converted to it. Every current workflow-service caller is a test and passes
  the path value straight through as the engine/database community id; there is
  no app-shell HTTP client or production workflow-service call site that
  substitutes a handle. Elsewhere, the Community Registry model stores
  `communityId` and `handle` as separate fields, and package envelopes store
  `communityId` and `communityHandle` separately. The corpus contains decisive
  non-derivable examples: `community_mosque` / `masjid-nur`,
  `community_verify_tabletop_club` / `tabletop-club`, and
  `community_data_portability` / `data-portability-community`. App Access then
  derives its group id from the handle, not the canonical id.
- Added an explicit `CommunityGroupIdResolver` boundary and a map-backed
  implementation. The executable accepts the map as
  `LOOM_COMMUNITY_GROUP_IDS`, keyed by canonical `communityId` and valued by
  the full App Access `groupId`. A missing mapping fails closed with a generic
  503; the service never guesses by removing `community_`, changing
  separators, or treating the two identifiers as equal.
- Added a minimal App Access HTTP client containing only `checkAccess`. It
  calls `POST /v1/access-decisions`, forwards the workflow request's
  correlation id, sends the extracted `fanId`, `appId: loom_communities`, the
  derived permission, and the explicitly resolved group id. It accepts only a
  200 response whose echoed fan/app/permission/group fields match the request
  and whose `allowed` field is boolean. Malformed, mismatched, and non-200
  decisions fail closed without exposing the upstream response.
- Implemented `POST /v1/communities/{communityId}/instances`:

  1. validates correlation/idempotency headers, token-bound identity seam, and
     the OpenAPI request shape;
  2. loads every raw definition for the canonical community so
     `ArchetypeResolver.resolveAll` remains correct after restart and for
     response-table inheritance;
  3. derives `<archetype_snake_case>.create` through the shared resolver;
  4. calls the real App Access decision boundary;
  5. calls `LocalWorkflowEngineApi.createInstance` only when allowed, then
     returns the persisted instance as HTTP 201.

  Definition resolution, the App Access decision, and insertion stay inside
  the service's serialized mutation boundary, so a concurrent wholesale
  definition replacement cannot change the archetype between authorization
  and creation.
- Denials return `403 workflow_create_refused` with a generic message. Unit
  coverage asserts that neither `event_rsvp.create`, role ids, nor App Access's
  `grantingRoleIds` shape appears in the response.
- Added a real-integration test that creates a unique App Access group, calls
  the already-implemented `createRole`, `setRolePermissions`, and
  `setGroupMembership` operations over HTTP, starts the workflow Shelf service
  on a real TCP boundary over PostgreSQL, and proves both directions: the
  granted fan receives 201 and persists one row; a fan without the role
  receives the generic 403 and creates no second row.
- Updated the workflow-service executable and README for the App Access base
  URL and explicit community/group map. No app-shell file, Kubernetes file,
  Dockerfile, `installCommunityPackage`, or other workflow operation was
  changed. No file under
  `docs/references/{reference,guide,archetypes,communities}/` was edited.

## Verification

Formatting and the required workflow-service analysis are clean:

```text
$ cd app/packages/core/loom_workflow_service
$ /home/fahd/flutter/bin/cache/dart-sdk/bin/dart format \
    --output=none --set-exit-if-changed lib bin test
Formatted 11 files (0 changed) in 0.25 seconds.

$ /home/fahd/flutter/bin/cache/dart-sdk/bin/dart analyze
Analyzing loom_workflow_service...
No issues found!
```

The literal `dart test` front-end did not reach the test runner. It remained at
the Pub/build-hook preflight until interrupted; this environment cannot reach
Pub's advisory endpoint:

```text
$ /home/fahd/flutter/bin/cache/dart-sdk/bin/dart test --reporter expanded
Running build hooks...Running build hooks...
^C
```

The already-resolved package:test snapshot then ran the exact package suite
without Pub's network preflight:

```text
$ /home/fahd/flutter/bin/cache/dart-sdk/bin/dart \
    --packages=/home/fahd/Loom/app/.dart_tool/package_config.json \
    /home/fahd/Loom/app/.dart_tool/pub/bin/test/test.dart-3.11.5.snapshot \
    --reporter expanded
...
00:00 +13 ~3: All tests passed!
```

B.2's baseline was 11 unit tests plus 2 live PostgreSQL integration tests. The
new suite contains **13 passing unit tests plus 3 integration tests**. All 3
integration tests were skipped in this sandbox because
`LOOM_POSTGRES_PASSWORD` could not be obtained through the inaccessible k3s
API. The new test is present and gated on both `LOOM_POSTGRES_PASSWORD` and
`LOOM_APP_ACCESS_BASE_URL`; a skip is not claimed as the required live pass.

The shared engine remains clean and exactly at its requested count:

```text
$ cd app/packages/core/loom_workflow_engine
$ /home/fahd/flutter/bin/cache/dart-sdk/bin/dart analyze
Analyzing loom_workflow_engine...
No issues found!

$ /home/fahd/flutter/bin/cache/dart-sdk/bin/dart \
    --packages=/home/fahd/Loom/app/.dart_tool/package_config.json \
    /home/fahd/Loom/app/.dart_tool/pub/bin/test/test.dart-3.11.5.snapshot \
    --reporter compact
...
00:08 +232 ~2: 2 skipped tests.
00:08 +232 ~2: All other tests passed!
```

The two skips are the existing live-PostgreSQL engine tests. The passing count
is unchanged at 232.

No app-shell file changed. Its Dart analysis completes with exit code 0 and the
same 9 information-level findings in untouched files:

```text
$ cd app/packages/core/loom_communities_app_shell
$ /home/fahd/flutter/bin/cache/dart-sdk/bin/dart analyze
Analyzing loom_communities_app_shell...
...
9 issues found.
```

The full app-shell Flutter suite could not begin executing tests: Flutter's
test harness must bind a loopback control socket, and this sandbox denies every
such bind. The first and subsequent files failed at load time with the same
environmental error, so the run was stopped rather than reporting dozens of
identical non-test failures:

```text
$ FLUTTER_ROOT=/tmp/loom-flutter-shim \
    /home/fahd/flutter/bin/cache/dart-sdk/bin/dart \
    /home/fahd/flutter/bin/cache/flutter_tools.snapshot \
    test --no-pub --reporter compact
Failed to load ".../authz_p4b_permission_wiring_test.dart":
Failed to create server socket (OS Error: Operation not permitted, errno = 1),
address = 127.0.0.1, port = 0
```

The required live test could not be reached. Read-only discovery fails before
credentials, a port-forward, App Access HTTP, PostgreSQL, or the workflow test
server can be reached:

```text
$ kubectl -n loom get pods -o wide
Unable to connect to the server: dial tcp 127.0.0.1:6443:
socket: operation not permitted

$ kubectl -n loom get svc app-access -o yaml
Unable to connect to the server: dial tcp 127.0.0.1:6443:
socket: operation not permitted
```

From an unsandboxed shell, the exact intended connection and test command are:

```bash
kubectl -n loom port-forward svc/postgres 15432:5432 \
  >/tmp/loom-b3-postgres-port-forward.log 2>&1 &
LOOM_B3_POSTGRES_PID=$!

kubectl -n loom port-forward svc/app-access 18081:8080 \
  >/tmp/loom-b3-app-access-port-forward.log 2>&1 &
LOOM_B3_APP_ACCESS_PID=$!

trap 'kill "$LOOM_B3_POSTGRES_PID" "$LOOM_B3_APP_ACCESS_PID"' EXIT

LOOM_B3_POSTGRES_USERNAME="$(kubectl -n loom get secret postgres-credentials \
  -o jsonpath='{.data.username}' | base64 -d)"
LOOM_B3_POSTGRES_PASSWORD="$(kubectl -n loom get secret postgres-credentials \
  -o jsonpath='{.data.password}' | base64 -d)"

cd app/packages/core/loom_workflow_service
LOOM_POSTGRES_USERNAME="$LOOM_B3_POSTGRES_USERNAME" \
LOOM_POSTGRES_PASSWORD="$LOOM_B3_POSTGRES_PASSWORD" \
LOOM_APP_ACCESS_BASE_URL=http://127.0.0.1:18081 \
  dart test test/app_access_create_instance_integration_test.dart \
  --reporter expanded
```

That run should report `+1: All tests passed!`. The test leaves uniquely named
App Access group/role/membership fixtures because App Access exposes no role or
group deletion operation; its PostgreSQL workflow schema is dropped in
`finally`.

`git diff --check` is clean.

## Proposed next steps

Deployment is still the obvious next slice, but only after the unsandboxed
live command above is green. That deployment should wire the in-cluster App
Access DNS URL and the canonical community-id/group-id mapping without adding
any heuristic conversion. Phase D can replace the initial explicit deployment
map with a dynamic canonical mapping maintained alongside package install; it
should not be pulled into this ticket by implementing the currently
out-of-scope `installCommunityPackage` operation.

## Anything I could not do

- I could not execute the mandatory end-to-end test against live App Access
  and PostgreSQL. This process cannot access the local k3s API socket, retrieve
  `postgres-credentials`, or start either required port-forward. It also cannot
  bind the loopback TCP socket used by the real workflow HTTP boundary. The
  live gate is therefore explicitly **not passed**.
- I could not complete the app-shell Flutter suite because the Flutter test
  harness is denied its loopback control socket before any test loads. No
  app-shell file changed, its analyzer completed, and the engine's 232 tests
  passed, but I do not claim a full app-shell-suite pass from those proxies.
- I could not obtain a completed literal `dart test` invocation because its
  Pub/build-hook preflight waits on unavailable network access. The resolved
  package:test runner executed the full pinned service suite successfully, and
  that distinction is recorded rather than hidden.
