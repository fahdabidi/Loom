# Remote-service configuration coverage — status

**Status:** complete — 2026-08-26

## Result

`configureLoomRemoteServicesFromEnvironment` now has **3/3** behavioural
checks in
`app/packages/core/loom_communities_app_shell/test/remote_service_configuration_environment_test.dart`.
Production code, including the function under test, was not changed.

The source confirms all three required paths:

1. If all three compile-time defines are empty, it returns `null` and leaves
   `loomAuthSession` unset.
2. If at least one define is present but one or more are empty, it throws a
   `StateError` that names every missing key.
3. If all three are present, it constructs a
   `LoomRemoteServiceConfiguration`; the test verifies the workflow base URI
   and observes the configured `LoomAuthSession` issue its token request to
   the defined endpoint with the defined client ID. The HTTP client is mocked,
   so this check makes no backend request and stores no credentials.

The token endpoint and client ID are private fields of `LoomAuthSession`, so
the configured test verifies them through its public, observable token-request
behaviour. The mock responds with `invalid_client`; that expected error stops
before storage is used while proving both values reached the session.

## Compile-time test modes

The default focused run was:

```sh
cd app/packages/core/loom_communities_app_shell
flutter test test/remote_service_configuration_environment_test.dart -r expanded
```

It executed the local-default assertion: **1 passed, 2 skipped (3 total)**.
The two explicit skip reasons were:

```text
Set LOOM_AUTH_TOKEN_ENDPOINT, LOOM_AUTH_CLIENT_ID, and
LOOM_WORKFLOW_SERVICE_BASE_URI with --dart-define to run the configured
remote-services assertion.

Set one or two of LOOM_AUTH_TOKEN_ENDPOINT, LOOM_AUTH_CLIENT_ID, and
LOOM_WORKFLOW_SERVICE_BASE_URI with --dart-define to run the
partial-configuration failure assertion.
```

This is deliberate. `String.fromEnvironment` is compile-time, so a normal
test process cannot exercise the other two modes. The skips are visible and
explain exactly how to run each mode; they are not silent test exclusions.

### All three defines set

This is the exact define-gated command that ran against the real development
service addresses and public test client ID. The test supplies its own mock
HTTP client, so no request is made to those addresses.

```sh
cd app/packages/core/loom_communities_app_shell
flutter test test/remote_service_configuration_environment_test.dart -r expanded \
  --dart-define=LOOM_AUTH_TOKEN_ENDPOINT=http://192.168.56.10:30082/realms/loom/protocol/openid-connect/token \
  --dart-define=LOOM_AUTH_CLIENT_ID=loom-test-client \
  --dart-define=LOOM_WORKFLOW_SERVICE_BASE_URI=http://192.168.56.10:30083
```

Passing output:

```text
00:00 +0: no remote-service defines leaves the app shell local
  Skip: Run without LOOM_AUTH_TOKEN_ENDPOINT, LOOM_AUTH_CLIENT_ID, and LOOM_WORKFLOW_SERVICE_BASE_URI to verify the local default.
00:00 +0 ~1: all remote-service defines configure the token session and workflow URI
00:00 +1 ~1: partial remote-service defines fail loudly and name every missing key
  Skip: Set one or two of LOOM_AUTH_TOKEN_ENDPOINT, LOOM_AUTH_CLIENT_ID, and LOOM_WORKFLOW_SERVICE_BASE_URI with --dart-define to run the partial-configuration failure assertion.
00:00 +1 ~2: All tests passed!
```

Result: the configured assertion ran and passed — **1 passed, 2 skipped
(3 total)**. It did not skip.

### Partial configuration failure

This command intentionally omits `LOOM_WORKFLOW_SERVICE_BASE_URI` while
providing the other two real development values:

```sh
cd app/packages/core/loom_communities_app_shell
flutter test test/remote_service_configuration_environment_test.dart -r expanded \
  --dart-define=LOOM_AUTH_TOKEN_ENDPOINT=http://192.168.56.10:30082/realms/loom/protocol/openid-connect/token \
  --dart-define=LOOM_AUTH_CLIENT_ID=loom-test-client
```

Passing output (the partial-configuration test ran rather than skipped):

```text
00:00 +0: no remote-service defines leaves the app shell local
  Skip: Run without LOOM_AUTH_TOKEN_ENDPOINT, LOOM_AUTH_CLIENT_ID, and LOOM_WORKFLOW_SERVICE_BASE_URI to verify the local default.
00:00 +0 ~1: all remote-service defines configure the token session and workflow URI
  Skip: Set LOOM_AUTH_TOKEN_ENDPOINT, LOOM_AUTH_CLIENT_ID, and LOOM_WORKFLOW_SERVICE_BASE_URI with --dart-define to run the configured remote-services assertion.
00:00 +0 ~2: partial remote-service defines fail loudly and name every missing key
00:00 +1 ~2: All tests passed!
```

Result: **1 passed, 2 skipped (3 total)**. The test exact-matches the loud
failure, including this `StateError` message:

```text
Bad state: Remote Loom services are only partially configured. Missing dart defines: LOOM_WORKFLOW_SERVICE_BASE_URI.
```

## Regression verification

All commands below were run from the package directory shown. No total moved
down. The app-shell default suite increased from the previously recorded 274
passing tests to 275 because this change adds the new local-default assertion;
its two additional skipped declarations are the visible compile-time modes
described above.

| Suite | Command | Exact result |
| --- | --- | --- |
| Communities app shell | `cd app/packages/core/loom_communities_app_shell && flutter test` | **275 passed, 2 skipped (277 total)** |
| UX judges | `cd app/packages/tooling/loom_ux_judges && flutter test` | **432 passed (432 total)** |
| Workflow engine | `cd app/packages/core/loom_workflow_engine && flutter test` | **287 passed, 4 skipped (291 total)** |
| Workflow service | `cd app/packages/core/loom_workflow_service && flutter test` | **54 passed, 5 skipped (59 total)** |
| App Access provisioning | `cd app/packages/tooling/loom_app_access_provisioning && flutter test` | **15 passed (15 total)** |
| Communities demo | `cd app/apps/loom_communities_demo && flutter test` | **160 passed (160 total)** |

The workflow engine's four skips and workflow service's five skips are the
existing optional live PostgreSQL/deployed-service integrations. No existing
assertion was weakened, deleted, inverted, or skipped to obtain these results.
