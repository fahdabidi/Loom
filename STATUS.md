# Live workflow-creation App Access authentication fix

## What changed

- `HttpAppAccessDecisionClient` now obtains a Keycloak client-credentials
  access token and sends `Authorization: Bearer <token>` on every
  `POST /v1/access-decisions` request. Authentication lives in the HTTP client
  itself because it owns both the outbound decision call and its HTTP-client
  lifecycle; callers cannot accidentally omit the bearer token.
- The token is cached and refreshed proactively 30 seconds before
  `expires_in` (halfway through lifetimes shorter than 30 seconds). The cache
  deliberately reuses `JwtWorkflowIdentityExtractor`'s shape: a cached value,
  an expiry/refresh timestamp, and one shared in-flight refresh future. It does
  not call Keycloak for every access decision.
- Non-200, malformed, and transport-failed token acquisition is normalized to
  `AppAccessDecisionException`, preserving `WorkflowService`'s existing
  `503 authorization_service_unavailable` behavior.
- The production entrypoint now requires `LOOM_KEYCLOAK_TOKEN_URL`,
  `LOOM_APP_ACCESS_CLIENT_ID`, and `LOOM_APP_ACCESS_CLIENT_SECRET` using the
  existing `StateError`-if-missing pattern. `LOOM_KEYCLOAK_TOKEN_URL` was
  reused because its only existing package use is the same `loom`-realm token
  endpoint; there is no naming conflict.
- The README run example documents the three required variables. The live App
  Access integration test now gives `HttpAppAccessDecisionClient` the
  throwaway client credentials that test already provisions.
- Added four in-memory HTTP-client tests that assert the exact outbound
  `Authorization` header and client-credentials form, cached reuse, proactive
  refresh, and `AppAccessDecisionException` on token rejection.
- The normal `createInstance`/`createInstances` success and refusal suites did
  remain mock-based as expected (`_RecordingAppAccessClient` and
  `_DenyAppAccessClient`); neither test file nor `WorkflowService` routing and
  request handling changed. No file under protected `docs/references` paths,
  no Java service, and no `loom-backend` file changed.

## Verification

The untouched workflow-service baseline was clean and contained 31 passing
tests plus the same 3 credential-gated live skips:

```text
$ /home/fahd/flutter/bin/cache/dart-sdk/bin/dart analyze
Analyzing loom_workflow_service...
No issues found!

$ /home/fahd/flutter/bin/cache/dart-sdk/bin/dart test --reporter expanded
...
00:01 +31 ~3: All tests passed!
```

The new focused unit suite passes all four required cases:

```text
$ /home/fahd/flutter/bin/cache/dart-sdk/bin/dart test test/app_access_client_test.dart --reporter expanded
Running build hooks...Running build hooks...00:00 +0: loading test/app_access_client_test.dart
00:00 +0: attaches the Keycloak bearer token to the App Access request
00:00 +1: reuses a cached token for repeated access decisions
00:00 +2: refreshes a token proactively when it is nearing expiry
00:00 +3: wraps token acquisition failure as AppAccessDecisionException
00:00 +4: All tests passed!
```

After the change, static analysis remains clean and the exact workflow-service
count is 35 passing, 3 skipped: four new passing tests and no new skip or
failure.

```text
$ /home/fahd/flutter/bin/cache/dart-sdk/bin/dart analyze
Analyzing loom_workflow_service...
No issues found!

$ /home/fahd/flutter/bin/cache/dart-sdk/bin/dart test --reporter expanded
...
00:01 +35 ~3: All tests passed!
```

The three workflow-service skips are unchanged live, credential-gated
PostgreSQL/App Access integration tests. The complete workflow-engine suite is
also unaffected:

```text
$ cd app/packages/core/loom_workflow_engine
$ /home/fahd/flutter/bin/cache/dart-sdk/bin/dart test --reporter expanded
...
00:05 +232 ~2: All tests passed!
```

The two engine skips are its unchanged credential-gated PostgreSQL integration
tests. Final whitespace validation is clean:

```text
$ git diff --check
<no output; exit 0>
```

The SDK binary was invoked directly because this sandbox's `dart` wrapper
tries to update `/home/fahd/flutter/bin/cache/engine.stamp`, which is read-only
here; the direct binary is the same installed Dart SDK 3.11.5.

## Proposed next steps

1. Urgently build and redeploy the fixed `loom-workflow-service` image. Yes,
   redeployment is the immediate next step: the currently deployed image still
   sends unauthenticated App Access decisions and therefore still breaks real
   `createInstance`/`createInstances` calls.
2. Supply the existing `loom-workflow-service` Keycloak client's ID and secret
   to the deployment as `LOOM_APP_ACCESS_CLIENT_ID` and
   `LOOM_APP_ACCESS_CLIENT_SECRET`, and set `LOOM_KEYCLOAK_TOKEN_URL` to the
   `loom` realm's in-cluster token endpoint. Do not provision another client.
3. After rollout, make a real creation request and confirm App Access returns a
   decision instead of `401`, then verify both single and batch creation no
   longer become `503 authorization_service_unavailable`.

## Anything I could not do

- I could not build/redeploy the production image, update its external secret
  or manifest, or perform a live post-rollout creation check; those systems are
  outside this ticket's writable repository scope and this sandbox cannot
  access the local Kubernetes API/network sockets.
- Consequently, the credential-gated live integration tests remained skipped.
  All runnable unit and package regression suites passed as recorded above.
- I did not modify or provision anything in the live Keycloak realm, as
  required. The fix only consumes the already-provisioned service-account
  credentials through configuration.
