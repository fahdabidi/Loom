# On-device remote-backend proof — status

**Status:** blocked — the integration test is implemented and statically
validated, but it was not executed on Android because this VM has no connected
Android device or installed AVD. Therefore this dispatch does **not** prove
that an app request reached the deployed backend.

## Change

Added
`app/apps/loom_communities_demo/integration_test/on_device_remote_backend_proof_test.dart`.
It is an integration-only test, so it is not selected by the demo app's default
`flutter test` suite.

The test:

1. Calls the real demo `main()` entrypoint, which is the production path that
   reads the three dart defines and configures the production engine factory.
2. Loads the bundled, shipped Cedar package and installs its engine-native
   experience using the deployed community id `community_cedar_commons_hoa`.
   This matters because the service is installed under that id; it must not be
   queried through the package extension id.
3. Resolves that engine through `workflowEngineForExtensionId` and asserts
   `isA<RemoteWorkflowEngineApi>()`, plus the remote engine's community id and
   defined base URI.
4. Logs in through the app-owned `LoomAuthSession` using the already committed
   `test-fan-alice` test credential. No new credential was added and the test
   never logs a token.
5. Confirms the shipped experience declares all **7** Cedar workflow
   definitions, then queries `hoa-facility-reservation` and requires at least
   one returned instance with a non-empty server instance id, state, and data
   map. The test's `ON_DEVICE_REMOTE_PROOF` line records the returned count,
   first server instance id, state, and data for the report.

The explicit define gate is:

```text
Set LOOM_AUTH_TOKEN_ENDPOINT, LOOM_AUTH_CLIENT_ID, and
LOOM_WORKFLOW_SERVICE_BASE_URI with --dart-define to run the on-device
remote-backend proof.
```

It is a visible skip reason, not a fallback. No production configuration code,
community JSONC, or locked reference documentation was modified.

## Required Android run — not completed

Run this from a host that has `emulator-5554` attached:

```sh
cd app/apps/loom_communities_demo
flutter test -d emulator-5554 integration_test/on_device_remote_backend_proof_test.dart -r expanded \
  --dart-define=LOOM_AUTH_TOKEN_ENDPOINT=http://192.168.56.10:30082/realms/loom/protocol/openid-connect/token \
  --dart-define=LOOM_AUTH_CLIENT_ID=loom-test-client \
  --dart-define=LOOM_WORKFLOW_SERVICE_BASE_URI=http://192.168.56.10:30083
```

Immediately collect the service-side window for that run:

```sh
kubectl logs -n loom deploy/workflow-service --since=10m
kubectl logs -n loom deploy/keycloak --since=10m
```

The exact `--since` duration should begin before the Flutter command and end
after it finishes. Preserve the test's `ON_DEVICE_REMOTE_PROOF` line, but do
not print or retain the bearer token.

## Attempted execution and service evidence

At this host, `adb devices` returned no devices and
`$ANDROID_HOME/emulator/emulator -list-avds` returned no AVDs. The required
`emulator-5554` was therefore unavailable.

I attempted the identical integration target on the available Linux desktop
target at `2026-08-26T09:37:38Z`, with all three defines. Flutter emitted only
`Building Linux application...`; it did not report a test result or execute the
test body. This is not counted as a passing test and is not a substitute for an
Android run.

Service logs collected after that attempt were:

```sh
kubectl logs -n loom deploy/workflow-service --since-time=2026-08-26T09:37:38Z --timestamps
kubectl logs -n loom deploy/keycloak --since-time=2026-08-26T09:37:38Z --timestamps
```

Both commands returned no request-level lines. Because the client test never
ran, this is expectedly **not service-side evidence** of the intended request.

| Required proof | Result |
| --- | --- |
| Android test total | **Not run** — no `emulator-5554` available |
| Engine type assertion | **Not observed** — the Android test did not execute |
| Returned instance data | **Not observed** — no remote query was made |
| Keycloak service-side request | **Not observed** |
| Workflow-service request | **Not observed** |

The request is neither observed from the service side nor inferred from a
client-side pass. The remaining action is the exact Android command above plus
the two log captures; until then, the remote-backed app path remains unproven.

## Static and regression verification

`flutter analyze integration_test/on_device_remote_backend_proof_test.dart`
completed with **no issues**.

All default suites below passed. Exact totals are shown; no total moved down.

| Suite | Command | Exact result |
| --- | --- | --- |
| Communities app shell | `cd app/packages/core/loom_communities_app_shell && flutter test` | **275 passed, 2 skipped (277 total)** |
| Workflow engine | `cd app/packages/core/loom_workflow_engine && flutter test` | **287 passed, 4 skipped (291 total)** |
| Workflow service | `cd app/packages/core/loom_workflow_service && flutter test` | **54 passed, 5 skipped (59 total)** |
| UX judges | `cd app/packages/tooling/loom_ux_judges && flutter test` | **432 passed (432 total)** |
| App Access provisioning | `cd app/packages/tooling/loom_app_access_provisioning && flutter test` | **15 passed (15 total)** |
| Communities demo | `cd app/apps/loom_communities_demo && flutter test` | **160 passed (160 total)** |

The app-shell suite is one pass above the ticket's 274 baseline because the
already-present remote-service configuration coverage introduced its local
default assertion before this change. This dispatch adds no app-shell unit test
and does not reduce any total.
