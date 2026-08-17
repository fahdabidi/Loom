# Phase E.4b — interactive Flutter Web authorization code + PKCE

## What changed

- Added a Flutter-Web-only interactive path to `LoomAuthSession`:
  - `loginInteractively()` discovers the issuer, constructs an explicit
    `Flow.authorizationCodeWithPKCE`, persists the one-time transaction in
    per-tab `sessionStorage`, and redirects the current browser window to
    Keycloak.
  - `completeInteractiveLogin()` detects the returned authorization response,
    rejects missing or forged `state` before discovery or code exchange,
    consumes the stored transaction, reconstructs the same PKCE flow, exchanges
    the real authorization code, and removes the callback query from browser
    history after success.
  - A conditional non-web implementation throws `UnsupportedError`; no
    `dart:js_interop` or browser DOM dependency enters non-web compilation.
- Used `package:openid_client` 0.4.10+1 directly. No `Authenticator` or
  implicit-flow API is present. The request is created only through
  `Flow.authorizationCodeWithPKCE`, with an explicit verifier, `S256`
  challenge, redirect URI, and CSRF `state`.
- Reused the existing token-session machinery. The authorization-code result
  is normalized by the same `_TokenResponse` parser and then passed through the
  existing `_sessionFromTokenResponse` and `_persistSession` functions used by
  `loginWithTestCredentials`; refresh and secure-storage behavior were not
  duplicated.
- Added focused unit coverage for verifier length/alphabet, the RFC 7636 `S256`
  known vector, authorization URL parameters, and forged/missing-state
  rejection.
- Added a minimal Flutter Web harness with one login button plus a host-side
  WebDriver controller. The controller is written to:
  - click the harness trigger;
  - wait for the real hosted Keycloak page;
  - locate the rendered `#username`, `#password`, and `#kc-login` elements (and
    print the live page source if any selector is absent);
  - type `test-fan-alice` / `LoomTest123!` and submit;
  - follow the redirect to the harness; and
  - retrieve and independently decode the resulting access JWT, asserting
    `fanId == fan-test-alice`.
- Added only a test-harness `web/index.html`; this is not a production login
  screen.
- Did not change either existing test file, Android configuration,
  `RemoteWorkflowEngineApi`, Keycloak configuration, or any file under
  `docs/references/{reference,guide,archetypes,communities}`. The unrelated
  untracked `ROOT_CAUSE_REPORT_2.md` and `ROOT_CAUSE_REPORT_3.md` remain
  untouched and are excluded from this change.

## Verification

The installed Flutter SDK is read-only in this sandbox, so all Flutter commands
used an exact temporary copy at `/tmp/loom-flutter-sdk`. Pub registry DNS is
also unavailable; dependency resolution was performed offline after populating
the local cache with the upstream `openid_client` 0.4.10+1 source. No vendored
dependency is part of the repository change.

Package-wide analysis is clean:

```text
$ /tmp/loom-flutter-sdk/bin/flutter analyze --no-pub .
Analyzing loom_auth_session...
No issues found! (ran in 30.3s)
exit_code=0
```

The five new non-browser security tests all execute and pass:

```text
$ /tmp/loom-flutter-sdk/bin/dart test \
    test/interactive_authorization_test.dart --reporter expanded
Running build hooks...Running build hooks...
00:00 +0: loading test/interactive_authorization_test.dart
00:00 +0: PKCE verifier has RFC 7636 length and unreserved encoding
00:00 +1: S256 derivation matches the RFC 7636 known vector
00:00 +2: authorization URL contains code, PKCE, state, and redirect data
00:00 +3: forged callback state is rejected before code exchange
00:00 +4: missing callback state is rejected before code exchange
00:00 +5: All tests passed!
exit_code=0
```

The real harness compiles as Flutter Web production output, including the
conditional web implementation and `openid_client` code exchange:

```text
$ /tmp/loom-flutter-sdk/bin/flutter build web --no-pub \
    --target integration_test/interactive_login_harness.dart \
    --output /tmp/loom-auth-interactive-web
Compiling integration_test/interactive_login_harness.dart for the Web...
Wasm dry run succeeded. Consider building and testing your application with the `--wasm` flag.
Compiling integration_test/interactive_login_harness.dart for the Web...        61.9s
✓ Built ../../../../../../../tmp/loom-auth-interactive-web
exit_code=0
```

The required existing Flutter suite was invoked without modifying its 11 unit
tests or one live-Keycloak test. The sandbox denied Flutter Test's mandatory
loopback server before any test body ran, so this is not a passing-suite claim:

```text
$ /tmp/loom-flutter-sdk/bin/flutter test --no-pub --reporter expanded
00:00 +0: loading .../test/loom_auth_session_test.dart
00:00 +0 -1: loading .../test/loom_auth_session_test.dart [E]
Failed to create server socket (OS Error: Operation not permitted, errno = 1),
address = 127.0.0.1, port = 0
...
00:00 +0 -2: loading .../test/loom_auth_session_live_test.dart [E]
Failed to create server socket (OS Error: Operation not permitted, errno = 1),
address = 127.0.0.1, port = 0
...
00:00 +0 -3: loading .../test/interactive_authorization_test.dart [E]
Failed to create server socket (OS Error: Operation not permitted, errno = 1),
address = 127.0.0.1, port = 0
00:00 +0 -3: Some tests failed.
exit_code=1
```

ChromeDriver was then started directly to make the genuine browser attempt. It
is the expected matching binary, but this dispatch sandbox denied both listen
sockets before it could accept a WebDriver session:

```text
$ chromedriver --port=9515 --verbose
Starting ChromeDriver 151.0.7922.138 (...) on port 9515
Only local connections are allowed.
Unable to start server with either IPv4 or IPv6. Exiting...
[...][SEVERE]: CreatePlatformSocket() failed: Operation not permitted (1)
[...][INFO]: listen on IPv6 failed with error ERR_ACCESS_DENIED
[...][SEVERE]: CreatePlatformSocket() failed: Operation not permitted (1)
[...][INFO]: listen on IPv4 failed with error ERR_ACCESS_DENIED
exit_code=1
```

Finally, the actual `flutter drive` command was invoked against the real
harness and host-side WebDriver controller. It stopped at the app server's
first bind, before Chrome launch, Keycloak navigation, or credential entry:

```text
$ /tmp/loom-flutter-sdk/bin/flutter drive --no-pub -d web-server \
    --driver=tool/interactive_login_webdriver.dart \
    --target=integration_test/interactive_login_harness.dart \
    --web-hostname=localhost --web-port=7357 --driver-port=9515 --headless
Launching integration_test/interactive_login_harness.dart on Web Server in debug mode...
Failed to bind web development server:
SocketException: Failed to create server socket
(OS Error: Operation not permitted, errno = 1),
address = localhost, port = 7357
#0      _NativeSocket.bind (dart:io-patch/socket_patch.dart:1216:7)
...
#4      WebAssetServer.start
(package:flutter_tools/src/isolated/web_asset_server.dart:231:24)
...
exit_code=1
```

Therefore the real WebDriver end-to-end proof did **not** succeed in this
dispatch sandbox. The stopping point is precise: local process socket creation,
before any browser session or network request to Keycloak. No partial browser
result is reported as an end-to-end pass.

## Proposed next steps

1. Re-run the exact ChromeDriver and `flutter drive` commands above in the
   independent verification environment that permits localhost listeners and
   access to `192.168.56.10:30082`. Confirm the rendered Keycloak selectors,
   credential submission, redirect URI acceptance, real code exchange, stored
   session, and decoded `fanId: fan-test-alice` assertion. If the rendered IDs
   differ, the committed controller prints the real WebDriver page source so
   the selectors can be updated from evidence.
2. Android custom-URL-scheme redirect/manifest wiring remains separate,
   unscoped follow-on work.
3. A production login screen remains separate, unscoped follow-on work.
4. Wiring `LoomAuthSession.currentAccessToken` into
   `RemoteWorkflowEngineApi.bearerTokenProvider` remains separate, unscoped
   follow-on work.

## Anything I could not do

- I could not complete or truthfully claim the real interactive WebDriver proof
  because this sandbox rejects every server-socket bind with `EPERM`, including
  both Flutter's web/test servers and ChromeDriver's IPv4/IPv6 listeners.
- I could not inspect the real client-rendered Keycloak DOM in WebDriver, so
  `#username`, `#password`, and `#kc-login` remain the supplied starting
  hypothesis, not selectors confirmed by this run.
- I could not confirm the existing 11 unit tests and one live-Keycloak test pass
  under their required Flutter runner. Their files are unmodified, but Flutter
  failed before test execution, and direct access to the live NodePort is also
  denied by the same process-network sandbox. The five new pure-Dart security
  tests, package analysis, and production Web compilation are green; none is
  presented as a substitute for the missing live browser proof.
- I did not loosen PKCE, widen redirect URIs, modify `loom-test-client`, or make
  any other live Keycloak change to work around the environment.
