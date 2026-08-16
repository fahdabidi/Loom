# Phase C.4 — real JWT identity extraction for loom_workflow_service

## What changed

- Added the hosted pub.dev package `jose` 0.3.5+1 to
  `loom_workflow_service`. I chose `jose` because it is an established,
  actively maintained JOSE implementation with native JWS, JWT, JWK/JWKS,
  `kid`, and real RS256 support. The package performs the RSA signature
  verification; the service does not implement RSA or RS256 itself.
- Added `JwtWorkflowIdentityExtractor`, preserving
  `WorkflowIdentityExtractor` and `HeaderWorkflowIdentityExtractor` as the
  existing swappable boundary and test adapter.
- The extractor accepts only a well-formed `Authorization: Bearer <token>`
  value and only RS256 compact JWS tokens. It selects a JWK by the protected
  `kid` header, verifies the signature with `jose`, compares the raw `iss`
  claim to the configured issuer exactly, requires an unexpired `exp`, and
  rejects a future `nbf` when present. Every parse, fetch, signature, or claim
  validation failure returns `null`.
- Successful verification reads only the `fanId` claim. It must be a nonblank
  string. Missing, empty, whitespace-only, or non-string values return `null`;
  there is no `sub` fallback. The decisive no-`fanId` test deliberately gives
  the valid token a `sub` claim to prove this behavior.
- JWKS values are cached per extractor for five minutes in an in-memory map
  keyed by `kid`. A TTL expiry triggers a refresh. A token whose `kid` is not
  in an otherwise-fresh cache triggers one immediate re-fetch, allowing
  Keycloak signing-key rotation without waiting for the TTL. Concurrent
  refreshes reuse the same in-flight future.
- Wired the production entrypoint to require `JWT_JWKS_URI` and `JWT_ISSUER`
  with the existing `StateError`-if-missing pattern, construct
  `JwtWorkflowIdentityExtractor`, and close its owned HTTP client during
  shutdown. The package README now documents the real in-cluster values. The
  production values remain deployment configuration; the code contains no
  placeholder or alternate defaults.
- Added 12 unit tests backed by three locally generated 2048-bit RSA JWK key
  pairs. They cover valid extraction, missing and empty `fanId`, expiry,
  `nbf`, a bad signature from a colliding-`kid` key, wrong issuer, absent and
  malformed authorization, malformed JWT, cache reuse, and unknown-`kid`
  rotation refresh.
- No workflow-engine file, workflow routing/execution operation, App Access
  client, community-group resolver, or file under
  `docs/references/{reference,guide,archetypes,communities}/` changed.

## Verification

The pre-change workflow-service baseline was 14 runnable tests with 3 existing
credential-gated integration skips:

```text
$ dart test --reporter compact  # resolved package:test runner, before changes
00:02 +14 ~3: 3 skipped tests.
00:02 +14 ~3: All other tests passed!
```

Formatting and the required package analysis are clean:

```text
$ cd app/packages/core/loom_workflow_service
$ dart format --output=none --set-exit-if-changed lib bin test
Formatted 13 files (0 changed) in 0.51 seconds.

$ dart analyze
Analyzing loom_workflow_service...
No issues found!
```

The real `dart test` command passes all 26 runnable service tests after the
change, with the same 3 pre-existing live-integration skips. This is an exact
before/after increase from 14 to 26 runnable passing tests (+12):

```text
$ dart test --reporter expanded
Running build hooks...Running build hooks...
...
00:00 +15 ~3: accepts a valid token and extracts its fanId claim
00:00 +16 ~3: returns null for a validly-signed token with no fanId claim
00:00 +17 ~3: returns null for a validly-signed token with an empty fanId claim
00:00 +18 ~3: returns null for an expired token
00:00 +19 ~3: returns null for a not-yet-valid token
00:00 +20 ~3: returns null for a token signed with a different key
00:00 +21 ~3: returns null for a token with the wrong issuer
00:00 +22 ~3: returns null when the Authorization header is absent
00:00 +23 ~3: returns null when the Authorization header is malformed
00:00 +24 ~3: returns null for a malformed bearer token
00:00 +25 ~3: reuses a cached JWKS for repeated requests
00:00 +26 ~3: refreshes a fresh JWKS cache when kid is unknown
00:01 +26 ~3: All tests passed!
```

The unchanged workflow-engine suite remains at exactly 232 passing tests with
its same 2 live-PostgreSQL skips:

```text
$ cd ../loom_workflow_engine
$ dart test --reporter compact
Running build hooks...Running build hooks...
...
00:15 +232 ~2: 2 skipped tests.
00:15 +232 ~2: All other tests passed!
```

`git diff --check` is clean.

## Proposed next steps

Run a live guarded workflow-service request against the deployed Keycloak
using:

```text
JWT_JWKS_URI=http://keycloak.loom.svc.cluster.local:8080/realms/loom/protocol/openid-connect/certs
JWT_ISSUER=http://keycloak.loom.svc.cluster.local:8080/realms/loom
```

The request should use a real Phase C.2 broker-issued access token and prove
both directions: its real `fanId` reaches workflow guard evaluation, while a
cryptographically valid token without `fanId` receives the existing
unauthenticated outcome. This is the obvious next step because unit coverage
already exercises the same RS256/JWK/claim path without depending on the live
cluster.

## Anything I could not do

- I could not run the live Keycloak request. `JWT_JWKS_URI`, `JWT_ISSUER`,
  `LOOM_POSTGRES_PASSWORD`, and `LOOM_APP_ACCESS_BASE_URL` are unset in this
  process, and the sandbox cannot reach the local k3s API:

  ```text
  $ kubectl -n loom get pods -o name
  Unable to connect to the server: dial tcp 127.0.0.1:6443:
  socket: operation not permitted
  ```

- Consequently, the 3 existing workflow-service integration tests remained
  skipped, as did the engine's 2 existing live-PostgreSQL tests. I do not claim
  that those live tests passed; all 26 runnable service tests and all 232
  runnable engine tests did pass.
- The sandbox also blocks loopback server sockets, so the unit suite injects a
  deterministic in-memory JWKS fetcher into the extractor instead of binding a
  local HTTP endpoint. The tests still generate real RSA keys and execute real
  RS256 signing and verification; the production HTTP JWKS fetch path is
  compiled and clean under `dart analyze`, and the live Keycloak step above is
  still required to exercise that transport end to end.
