# Phase E.4b (core) — `LoomAuthSession`

## What changed

- Added the new Flutter-aware workspace package
  `app/packages/core/loom_auth_session`. The workspace manifest was updated so
  the package participates in normal workspace dependency resolution; no
  existing package source was edited.
- Added `LoomAuthSession`, configured with an absolute Keycloak token endpoint,
  a required client id, and an injected `LoomAuthSecureStorageBackend`. The
  package takes the token endpoint directly because password and refresh grants
  are the only flows in scope; discovery and interactive authorization add no
  value to this phase. Nothing hardcodes a different client, and the live test
  supplies the provisioned `loom-test-client` id.
- Chose a small storage interface rather than coupling the session core
  directly to a plugin singleton. Unit and live tests can use an in-memory
  implementation, while `FlutterSecureStorageBackend` delegates production
  reads/writes/deletes to an injected `FlutterSecureStorage`. Access token,
  refresh token, proactive refresh time, access expiry, and known refresh
  expiry are serialized together under one secure-storage key. A newly created
  session object reloads that record, so an app process restart does not discard
  a still-renewable session.
- `currentAccessToken()` returns the cached token outside its refresh window and
  otherwise performs a Keycloak `grant_type=refresh_token` exchange. It mirrors
  the existing token-client caching shape: a 30-second proactive refresh skew,
  a half-lifetime fallback for short-lived tokens, and a shared in-flight
  refresh future so concurrent callers do not stampede the endpoint. Successful
  refreshes replace and persist both rotated tokens. An operation generation
  also prevents a stale in-flight refresh from re-persisting tokens after
  logout or a newer login.
- Added dedicated, inspectable failures. `LoomAuthNotLoggedInException`,
  `LoomAuthRefreshTokenExpiredException`, and `LoomAuthNetworkException` let a
  caller distinguish no session, mandatory re-login, and reachability failure.
  Test-credential rejection, other token-endpoint failures, malformed token
  responses, and secure-storage failures also have distinct exception types.
  A locally known refresh expiry or Keycloak `invalid_grant` clears the unusable
  stored session before requiring login again; a transient network failure does
  not destroy it.
- Added `loginWithTestCredentials`, using a form-encoded Direct Access Grant
  with `grant_type=password`, `client_id`, username, and password. The class and
  method documentation both state explicitly that this is a **test-only bypass
  of the interactive browser flow for automated/local testing against
  Keycloak-native accounts and must never be called by production UI code**.
  Failed credentials never write a partial token record or replace a prior
  session.
- Added local-only `logout()`. It deletes the persisted token record and does
  not call Keycloak's browser-oriented end-session endpoint.
- Used minimal `package:http` form posts instead of adding `openid_client`.
  Authorization Code + PKCE is intentionally absent, so bringing its discovery
  and interactive machinery into this core phase would be unused scope.
- Declared `http: ^1.6.0` (already locked/cached) and
  `flutter_secure_storage: ^10.3.1`. The latter is the current stable release,
  but it was not cached and this sandbox cannot resolve pub.dev; consequently
  the real dependency could not be added to `app/pubspec.lock`. No temporary
  override or stub is present in the committed tree.
- Added 11 unit cases plus one live Keycloak test. The live test invokes the
  production session API with `test-fan-alice` / `LoomTest123!`, obtains the
  result via `currentAccessToken()`, decodes the JWT payload, and asserts both
  the pinned issuer and `fanId == fan-test-alice` whenever the NodePort is
  reachable.
- No `loom_workflow_engine`, `loom_workflow_service`, app-shell, Android
  manifest, UI, or protected
  `docs/references/{reference,guide,archetypes,communities}` file changed.

## Verification

The mandated offline dependency check was attempted first and failed only
because `flutter_secure_storage` was not in the existing pub cache:

```text
$ /home/fahd/flutter/bin/cache/dart-sdk/bin/dart pub get --offline
Resolving dependencies...
Because loom_auth_session depends on flutter_secure_storage any which doesn't exist (could not find package flutter_secure_storage in cache), version solving failed.

Try again without --offline!
exit_code=69
```

The online retry confirmed that this sandbox cannot reach pub.dev:

```text
$ /home/fahd/flutter/bin/cache/dart-sdk/bin/dart pub get
Resolving dependencies...
Got socket error trying to find package flutter_secure_storage at https://pub.dev.
exit_code=69
```

To validate the authored source despite that environmental gap, I temporarily
overrode only `flutter_secure_storage` with an uncommitted compile-only package
that exposes the documented 10.3.1 `read`, `write`, and `delete` signatures.
That stub did not implement storage and was never exercised: every session test
injects the package's own in-memory `LoomAuthSecureStorageBackend`. The override,
stub, and generated path lock entry were removed after verification. Under that
explicitly limited compile setup, static analysis was clean:

```text
$ /home/fahd/flutter/bin/cache/dart-sdk/bin/dart analyze
Analyzing loom_auth_session...
No issues found!
```

All 11 mocked-HTTP/in-memory-storage unit tests pass. This includes cached and
proactive-refresh paths, persisted restart recovery, concurrent refresh
coalescing, no-login/no-HTTP behavior, the exact password-grant form, rejected
credentials without partial persistence, logout clearing, locally expired and
server-rejected refresh tokens, and the distinct network failure:

```text
$ /home/fahd/flutter/bin/cache/dart-sdk/bin/dart \
    --packages=/home/fahd/Loom/app/.dart_tool/package_config.json \
    /home/fahd/.pub-cache/hosted/pub.dev/test-1.30.0/bin/test.dart \
    test/loom_auth_session_test.dart --reporter expanded
00:00 +0: loading test/loom_auth_session_test.dart
00:00 +0: returns a cached access token while it is unexpired
00:00 +1: proactively refreshes a token that is nearing expiry
00:00 +2: refreshes an expired token and re-stores the new tokens
00:00 +3: coalesces concurrent refresh-token exchanges
00:00 +4: no prior login throws without making an HTTP call
00:00 +5: test credential login posts a password grant and stores tokens
00:00 +6: bad test credentials are clear and do not store a partial session
00:00 +7: logout clears persistence and leaves no current session
00:00 +8: known refresh-token expiry requires login without HTTP
00:00 +9: invalid_grant refresh requires login and clears persistence
00:00 +10: network failure stays distinct from login-required failures
00:00 +11: All tests passed!
```

The live test genuinely attempted the already-exposed Keycloak NodePort through
`LoomAuthSession.loginWithTestCredentials`; the sandbox denied that distinct
plain-HTTP socket with `EPERM`, so the reachability-gated test reported one skip
rather than a fabricated pass:

```text
$ /home/fahd/flutter/bin/cache/dart-sdk/bin/dart \
    --packages=/home/fahd/Loom/app/.dart_tool/package_config.json \
    /home/fahd/.pub-cache/hosted/pub.dev/test-1.30.0/bin/test.dart \
    test/loom_auth_session_live_test.dart --reporter expanded
00:00 +0: loading test/loom_auth_session_live_test.dart
00:00 +0: live Keycloak login returns test-fan-alice fanId claim
  Live Keycloak NodePort is unreachable: LoomAuthNetworkException: Failed to reach the Keycloak token endpoint: ClientException with SocketException: Connection failed (OS Error: Operation not permitted, errno = 1), address = 192.168.56.10, port = 30082, uri=http://192.168.56.10:30082/realms/loom/protocol/openid-connect/token
00:00 +0 ~1: All tests skipped.
```

The requested port-forward fallback was also attempted, but the sandbox denies
the k3s API socket before a Keycloak pod can be selected:

```text
$ kubectl get pods -n loom -o name
Unable to connect to the server: dial tcp 127.0.0.1:6443: socket: operation not permitted
exit_code=1
```

The new package therefore has **11 passing unit tests and one live reachability
skip**. A standard final `dart test` using the real dependency graph cannot run
until `flutter_secure_storage` resolves; the direct cached test-runner command
above avoids claiming otherwise.

Final formatting and whitespace checks are clean:

```text
$ /home/fahd/flutter/bin/cache/dart-sdk/bin/dart format lib test
Formatted 7 files (0 changed) in 0.11 seconds.

$ git diff --check
<no output; exit 0>
```

## Proposed next steps

1. In a network-enabled environment, run `dart pub get`/`flutter pub get` from
   `app` to download the real `flutter_secure_storage` 10.3.1 packages, commit
   the resulting lockfile, then rerun the package's normal `dart analyze` and
   `dart test` commands. From an environment with NodePort access, rerun the
   focused live test until its real JWT issuer and `fanId` assertions pass.
2. Build the interactive Authorization Code + PKCE browser flow as the separate
   Phase E.4b-interactive ticket.
3. Add Android manifest redirect handling for
   `com.loom.communities:/oauthredirect` as separate platform integration work.
4. Add a minimal production login screen only after the interactive flow and
   redirect wiring exist; it must never call `loginWithTestCredentials`.
5. Separately wire `currentAccessToken` into
   `RemoteWorkflowEngineApi.bearerTokenProvider` after the app-shell integration
   design is in scope.

All four requested product follow-ons—the interactive PKCE/browser flow,
Android redirect wiring, minimal login UI, and remote-engine token-provider
wiring—remain deliberately unscoped here.

## Anything I could not do

- I could not resolve or exercise the real `flutter_secure_storage` plugin,
  update `app/pubspec.lock`, or run the standard real-dependency `dart analyze`
  / `dart test` verification because the package was absent from the pub cache
  and DNS/network access to pub.dev is denied. The exact failures and the
  limited temporary compile setup are recorded above.
- I could not obtain a live Keycloak JWT proof because direct HTTP access to
  `192.168.56.10:30082` is denied with `operation not permitted`, while the
  port-forward fallback is independently blocked at the k3s API socket. The
  live test made the real request and skipped for that reachability error only;
  reachable credential, issuer, or `fanId` failures remain hard failures.
- Everything else in the additive session-core scope is implemented. No
  interactive flow, redirect manifest, production login UI, end-session call,
  remote-engine wiring, new Keycloak client/account, or prohibited package/doc
  edit was attempted.
