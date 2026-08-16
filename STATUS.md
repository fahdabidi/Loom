# App Access integration-test bearer authentication

## What changed

- The only functional code change is in
  `app/packages/core/loom_workflow_service/test/app_access_create_instance_integration_test.dart`.
  This `STATUS.md` handoff is the only other changed file in the commit. No
  workflow-service implementation, workflow-engine contract, App Access
  source, or `loom-backend` file changed.
- Added explicit credential gates for `LOOM_KEYCLOAK_TOKEN_URL`,
  `LOOM_KEYCLOAK_ADMIN_URL`, `LOOM_KEYCLOAK_ADMIN_USERNAME`, and
  `LOOM_KEYCLOAK_ADMIN_PASSWORD`, alongside the existing PostgreSQL and App
  Access gates. `LOOM_KEYCLOAK_ADMIN_URL` is the Keycloak base URL;
  `LOOM_KEYCLOAK_TOKEN_URL` is the full `loom`-realm token endpoint.
- The test now obtains an `admin-cli` password-grant token from the `master`
  realm, creates a uniquely named confidential `openid-connect` client in the
  `loom` realm with `serviceAccountsEnabled: true`, reads its generated secret,
  and obtains a client-credentials access token from the configured `loom`
  token endpoint.
- All four existing direct App Access setup mutations (`createGroup`,
  `createRole`, `setRolePermissions`, and `setGroupMembership`) now send that
  token as `Authorization: Bearer <token>` without changing their payloads,
  idempotency keys, expected statuses, or seeded identities and permissions.
- The Keycloak client UUID is captured from the create response's `Location`
  header and deleted in the test's outer cleanup path. Cleanup is attempted
  after setup or assertion failures as well as successful runs.
- The workflow `createInstances`/`createInstance` requests and all assertions
  remain unchanged. This follows the requested test-only scope for a test that
  predates Phase C.1's deployed JWT enforcement.

## Verification

Formatting and static analysis are clean, using the installed SDK binary
directly because the `dart` wrapper attempts to update a read-only Flutter
engine stamp in this sandbox:

```text
$ /home/fahd/flutter/bin/cache/dart-sdk/bin/dart format test/app_access_create_instance_integration_test.dart
Formatted test/app_access_create_instance_integration_test.dart
Formatted 1 file (1 changed) in 0.06 seconds.

$ /home/fahd/flutter/bin/cache/dart-sdk/bin/dart analyze
Analyzing loom_workflow_service...
No issues found!
```

The full workflow-service suite has no runnable-test regression:

```text
$ /home/fahd/flutter/bin/cache/dart-sdk/bin/dart test --reporter expanded
...
00:01 +31 ~3: All tests passed!
```

The three skips are the package's live, credential-gated integration tests.
For the changed target, the ordinary unconfigured output is explicit:

```text
$ /home/fahd/flutter/bin/cache/dart-sdk/bin/dart test test/app_access_create_instance_integration_test.dart --reporter expanded
...
Skip: Set LOOM_POSTGRES_PASSWORD to run against the k3s PostgreSQL instance or port-forward.
00:00 +0 ~1: All tests skipped.
```

I could not produce the required real `+1: All tests passed!` result in this
execution environment. The cluster is configured locally and its manifests
document App Access on NodePort `30080`, Keycloak on NodePort `30082`, and
PostgreSQL behind its cluster service. However, the sandbox blocks access to
the Kubernetes API and local network sockets:

```text
$ kubectl -n loom get svc,pods
Unable to connect to the server: dial tcp 127.0.0.1:6443: socket: operation not permitted
```

I also ran the exact test with every gate set and the documented Keycloak and
App Access NodePort addresses (using placeholder credentials because the
connection fails before authentication). This proves it did not skip, but it
could not reach Keycloak:

```text
$ LOOM_POSTGRES_PASSWORD=unavailable \
  LOOM_APP_ACCESS_BASE_URL=http://127.0.0.1:30080 \
  LOOM_KEYCLOAK_TOKEN_URL=http://127.0.0.1:30082/realms/loom/protocol/openid-connect/token \
  LOOM_KEYCLOAK_ADMIN_URL=http://127.0.0.1:30082 \
  LOOM_KEYCLOAK_ADMIN_USERNAME=loom-admin \
  LOOM_KEYCLOAK_ADMIN_PASSWORD=unavailable \
  /home/fahd/flutter/bin/cache/dart-sdk/bin/dart test test/app_access_create_instance_integration_test.dart --reporter expanded
...
SocketException: Connection failed (OS Error: Operation not permitted, errno = 1),
address = 127.0.0.1, port = 30082
00:00 +0 -1: Some tests failed.
```

`git diff --check` is clean.

## Proposed next steps

1. Re-run the exact target test from a network-enabled environment that can
   reach the three live services. Running in the `loom` namespace is the least
   ambiguous Keycloak route because the token endpoint then uses
   `http://keycloak.loom.svc.cluster.local:8080`, matching App Access's expected
   issuer. Supply the bootstrap admin and PostgreSQL credentials from their
   Kubernetes secrets and require the literal `+1: All tests passed!` result.
2. Before claiming that pass, resolve or explicitly authorize the separate
   service-to-service authentication gap described below. The smallest
   test-only option would be an authenticated HTTP client injected into the
   existing `HttpAppAccessDecisionClient`; the production-correct option is a
   real workflow-service credential/token-provider design. That choice is
   outside this ticket's explicit setup-only scope and should not be guessed.

## Anything I could not do

- I could not establish the PostgreSQL, App Access, or Keycloak port-forwards,
  retrieve the live Kubernetes secrets, or run the target test against the
  live cluster because this sandbox rejects the Kubernetes API and socket
  operations. I therefore do not claim the required live pass.
- There is a second JWT-enforcement consequence visible in unchanged code:
  `HttpAppAccessDecisionClient.checkAccess` sends no `Authorization` header on
  `POST /v1/access-decisions`, while the deployed App Access
  `JwtSecurityConfiguration` permits only the two literal health paths and
  requires authentication for every other request. The batch path performs
  this decision before writing and converts that client's non-200 response to
  `503 authorization_service_unavailable`. The requested scope says to change
  only this test's App Access setup calls and specifically forbids changing the
  actual create calls or service implementation, so I left this separate
  boundary untouched. It is likely to be the next live failure after the four
  seed requests begin succeeding.
