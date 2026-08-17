# Phase E.4c + E.4d — production login and remote bearer-token wiring

## What changed

- Added the app-shell dependency and imports needed for the real remote path:
  - `app/packages/core/loom_communities_app_shell/pubspec.yaml` now has the
    in-repo path dependency on `loom_auth_session`, plus direct `http` and
    `flutter_secure_storage` dependencies for the public factory and production
    secure-storage construction.
  - `lib/loom_communities_app_shell.dart` imports those packages and registers
    the two new part files. No part file carries an import.
- Added `part37_remote_auth_session.dart`:
  - The app-shell-owned `LoomAuthSession?` is private and **null/unconfigured by
    default**. The public `loomAuthSession` accessor and test-only override/reset
    functions expose the seam without changing normal local startup.
  - `configureLoomRemoteServicesFromEnvironment()` lazily reads exactly
    `LOOM_AUTH_TOKEN_ENDPOINT`, `LOOM_AUTH_CLIENT_ID`, and
    `LOOM_WORKFLOW_SERVICE_BASE_URI` through `String.fromEnvironment`. With no
    defines it returns `null`; partial/invalid configuration fails only when the
    host explicitly calls the function. It constructs the real session with
    `FlutterSecureStorageBackend`, never a production fake.
  - `createRemoteEngineNativeCommunityEngineFactory()` returns the existing
    `EngineNativeCommunityEngineFactory` shape while capturing the session,
    workflow-service URI, and HTTP client. Its remote engine uses the exact
    required wiring:

    ```dart
    bearerTokenProvider: session.currentAccessToken,
    ```

  - The typedef and `part25` are unchanged. In particular,
    `_engineNativeCommunityEngineFactory` still defaults to
    `_createLocalEngineNativeCommunityEngine`; no community is remotely enabled
    by this ticket.
- Added `part38_production_login_screen.dart`, a real IdP screen which:
  - calls `completeInteractiveLogin()` on load and `loginInteractively()` from
    its real action;
  - renders distinct callback-checking, redirect-in-progress, success,
    Keycloak/auth-error, and unsupported-platform states;
  - surfaces `LoomAuthSessionException.message`, preserving Keycloak's real
    interactive error description;
  - never calls `loginWithTestCredentials` and never falls back to local demo
    auth.
- Added a conditional entry in `part01_local_extension_screen.dart`: the
  persona/account dialog shows a separate “Sign in securely with Loom…” action
  only when `loomAuthSession` is non-null. This location keeps real identity
  login visibly separate from persona selection. With no session, the widget
  subtree is absent and the existing “Sign in as a specific person…” route
  continues to open the unchanged `LoomAuthScreen` demo picker.
- Added eight focused tests:
  - the seam is null by default, accepts a fake override, and reset restores
    null (with reset in `tearDown`);
  - the remote factory produces a `RemoteWorkflowEngineApi` whose
    `bearerTokenProvider()` resolves to the fake session's exact known token;
  - a real `RemoteWorkflowEngineApi` also flows through the shared store's
    initialization and authorization gates without invoking Local-only setup;
  - the login screen invokes `loginInteractively`, remains visibly pending,
    handles both callback-time and action-time `UnsupportedError`, renders
    success, and surfaces the real auth error message.
- `LoomAuthScreen`, `LoomAuthApi`, `LocalAuthApi`, the demo-account picker,
  `EngineNativeCommunityEngineFactory`, the default engine factory, all
  community JSON/reference material, and all 11 shipped community selections
  are unchanged.

## Verification

The installed Flutter SDK and the repository-standard Flutter test coordinator
cannot write their cache stamps or bind their localhost protocol socket in this
sandbox. I copied the SDK to `/tmp` and changed only that disposable copy's test
transport from localhost WebSocket to stdin/stdout. The test programs still ran
under the real `flutter_tester`; the repository and installed SDK were not
modified. I validated the transport first with all eight new focused tests.

App-shell analysis is unchanged at exactly the expected eight pre-existing
informational lints and zero new diagnostics:

| App-shell `flutter analyze --no-pub` | Infos | Warnings | Errors |
| --- | ---: | ---: | ---: |
| Before (`ff39c46d`) | 8 | 0 | 0 |
| After | 8 | 0 | 0 |

Real final output:

```text
Analyzing loom_communities_app_shell...
...
8 issues found. (ran in 34.0s)
```

All eight are the same three existing `unawaited_futures` infos in
`part18_marketplace_rendering.dart` and five existing
`prefer_const_constructors` infos in unchanged tests. The two dependency
packages are fully clean:

```text
Analyzing loom_auth_session...
No issues found! (ran in 26.9s)

Analyzing loom_workflow_engine...
No issues found! (ran in 10.3s)
```

The complete app-shell suite ran once in an untouched detached `ff39c46d`
worktree and once after the change:

| App-shell full suite | Passed | Failed | Delta |
| --- | ---: | ---: | ---: |
| Before | 230 | 3 | baseline |
| After | 238 | 3 | +8 focused passes, zero new failures |

Exact summaries:

```text
# Before
02:18 +230 -3: Some tests failed.

# After
02:22 +238 -3: Some tests failed.
```

The same three pre-existing failures occurred before and after, by exact name:

- `organizer creates an event and one pending response per member`
- `custom event creation and recurring generation seed custom response rows`
- `missing custom response row keeps organizer event-level actions visible`

The new focused run is independently green:

```text
00:00 +0: ... session seam defaults to null and reset restores that default
00:00 +1: ... remote factory exposes the session access-token provider tear-off
00:00 +2: ... real remote engine passes through the store Local-only gates
00:02 +3: ... real sign-in action invokes loginInteractively and stays pending
00:02 +4: ... unsupported interactive platform renders an honest state
00:03 +5: ... unsupported sign-in action cannot crash or silently fall back
00:03 +6: ... completed redirect renders success and notifies the caller
00:03 +7: ... identity-provider error surfaces its real message
00:03 +8: All tests passed!
```

The unchanged dependency suites also ran in full:

```text
# loom_workflow_engine
00:05 +259 ~3: All tests passed!

# loom_auth_session
00:02 +16 ~1: All tests passed!
```

The workflow-engine skips are its opt-in live PostgreSQL/service tests. The
auth-session skip is its live Keycloak test because this sandbox rejects the
NodePort connection with `Operation not permitted`; all 16 executable tests
passed.

Zero behavior change with no session configured was checked, not assumed. Both
full app-shell runs omitted all three dart defines, so the changed run exercised
the default-null seam across the existing shipped-community coverage. It added
only the eight new passing tests and reproduced exactly the baseline's three
known failures. No existing community selected the remote factory.

Final scope checks:

```text
$ git diff --check
# no output

$ rg -n "loginWithTestCredentials" app/packages/core/loom_communities_app_shell
# no output

$ git diff --name-only -- docs/references/reference docs/references/guide \
    docs/references/archetypes docs/references/communities
# no output
```

## Proposed next steps

- Keep per-community remote enablement as separate, later work. That work can
  call `configureLoomRemoteServicesFromEnvironment()`, retain its returned
  workflow-service URI, and deliberately select
  `createRemoteEngineNativeCommunityEngineFactory()` only for approved
  communities. This ticket does not flip the factory for any community.
- When a community is selected, add its host-level browser route/restoration
  wiring and repeat the already-proven real Keycloak browser pass plus live
  workflow-service calls for that community.

## Anything I could not do

- I could not run the repository-standard unmodified `flutter test` transport:
  it fails before loading tests with `Failed to create server socket (OS Error:
  Operation not permitted), address = 127.0.0.1, port = 0`. The disposable
  stdin/stdout transport described above closed this verification gap and
  produced genuine before/after `flutter_tester` executions.
- I could not reach the live Keycloak NodePort from this sandbox, so the
  existing opt-in live auth-session test skipped. This ticket did not alter the
  already live-proven Authorization Code + PKCE implementation.
- The Phase E.4e Local-only gating **does genuinely cover a real
  `RemoteWorkflowEngineApi`**. `_initialize()` and `configureAuthorization()`
  both return on `engine is! LocalWorkflowEngineApi`, and the new focused test
  sends an actual remote engine through both store paths, then retrieves it and
  resolves its captured token successfully. There is no unresolved E.4e gating
  gap to report.
