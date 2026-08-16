# Phase E.4a — `RemoteWorkflowEngineApi`

## What changed

- Added `RemoteWorkflowEngineApi implements WorkflowEngineApi` in
  `loom_workflow_engine` and exported it from the package barrel. Its
  constructor takes an absolute `baseUri`, `communityId`, an injected
  `Future<String> Function()` bearer-token provider, and an injected
  `http.Client`; it owns no login, token cache, refresh flow, or HTTP-client
  lifecycle.
- Added `http: ^1.6.0` as a direct package dependency. Version 1.6.0 was
  already present in `app/pubspec.lock` and the local pub cache, and the whole
  workspace resolved successfully with `dart pub get --offline`; no new
  network-fetched dependency or lockfile version change was needed.
- Implemented all seven remotely legitimate interface operations against the
  exact OpenAPI routes and JSON projections:

  | Engine method | HTTP operation |
  | --- | --- |
  | `queryInstances` | `GET /v1/communities/{communityId}/instances` |
  | `availableTransitionsAsync` | `GET /v1/communities/{communityId}/instances/{instanceId}/available-transitions` |
  | `applyTransition` | `POST /v1/communities/{communityId}/instances/{instanceId}/transitions` |
  | `createInstance` | `POST /v1/communities/{communityId}/instances` |
  | `createInstances` | `POST /v1/communities/{communityId}/instances/batch` |
  | `updateInstanceFields` | `PATCH /v1/communities/{communityId}/instances/{instanceId}/fields` |
  | `aggregate` | `POST /v1/communities/{communityId}/instances/aggregate` |

- Every outbound request obtains the bearer token exactly once and sends
  `Authorization: Bearer <token>` plus a fresh RFC 4122 version-4
  `X-Loom-Correlation-Id`. The four mutations (`applyTransition`, singular and
  batch creation, and field update) also send a separate fresh UUID in
  `Idempotency-Key`. The aggregate route remains a read-only POST and correctly
  has no idempotency key, matching the authoritative OpenAPI operation.
- The remote service derives fan identity from the token, so interface-only
  `personaId`, `tabId`, current-state, and local instance-data inputs are never
  serialized as forged authority. `queryInstances` exposes the same additive
  optional `workflowType` argument as `LocalWorkflowEngineApi`; only the
  OpenAPI-supported `workflowType`, `sortKey`, `limit`, and `cursor` query
  parameters go over the wire.
- Adapted the OpenAPI response projections without inventing authority. The
  service does not expose `createdByPersonaId`, so remotely queried instances
  use the empty string as the interface model's explicit "not provided"
  value. Available-transition responses intentionally contain render advice,
  not full workflow definitions, so their `transitionId`, label, action, tone,
  inputs, and response `currentState` are projected into
  `LoomWorkflowTransition`; no target state, guards, or effects are fabricated.
- `availableTransitions` throws `UnsupportedError` synchronously and points to
  `availableTransitionsAsync`, because a network round trip cannot satisfy a
  synchronous return. `dueNotifications` also throws synchronously because no
  workflow-service OpenAPI operation exists. Tests prove neither path obtains
  a token or invokes HTTP.
- Added three remote-only exception classes for failures a local SQLite call
  cannot experience: `RemoteWorkflowAuthenticationError`,
  `RemoteWorkflowProtocolError`, and `RemoteWorkflowServiceError`, all carrying
  a code, message, optional HTTP status, and optional correlation id. Malformed
  success/error payloads and network failures are normalized into these same
  remote-only categories instead of leaking arbitrary JSON/client exceptions.
- Added 25 mock-client unit cases: all seven successful operation shapes,
  fresh request identifiers and token-provider invocation, every service error
  code, and both unsupported methods. `package:http/testing.dart` supplies
  `MockClient`, so no mocking dependency was added.
- Added a live integration test that uses the production remote class against
  a configured deployed-service base URI, creates a real instance, paginates
  `queryInstances`, and requires the created id and initial data to come back.
  It is gated on a real fan JWT plus an installed/creatable community fixture;
  it never fabricates a token.
- No app-shell file, `LocalWorkflowEngineApi`, `WorkflowEngineApi`, workflow
  service file, or protected `docs/references/{reference,guide,archetypes,communities}`
  file changed.

### Full exception-vocabulary mapping

The mapping preserves the local implementation's domain exception vocabulary
where the remote code represents the same outcome. It uses a remote-only type
where authentication, transport, or protocol semantics have no honest local
equivalent.

| Workflow-service `code` | Client exception | Mapping decision |
| --- | --- | --- |
| `workflow_field_edit_refused` | `WorkflowAuthorizationError` | Exact parity with `LocalWorkflowEngineApi.updateInstanceFields`, whose edit-guard/schema refusals use this type rather than `StateError`. |
| `workflow_guard_refused` | `StateError` | Exact parity with local transition-guard refusal. |
| `workflow_read_refused` | `StateError` | Exact parity with the local surface-permission refusal path. |
| `workflow_instance_not_found` | `StateError` | Exact parity with local missing-instance failures. |
| `workflow_type_not_found` | `StateError` | Exact parity with local unknown-workflow-type failures. |
| `workflow_state_conflict` | `StateError` | Exact parity with a locally unavailable source state. |
| `workflow_create_refused` | `StateError` | Matches local creation-guard refusal, so an existing domain catch continues to work. |
| `invalid_transition_request` | `StateError` | The service currently emits this additional code for unknown transitions and missing required inputs; both are local `StateError` outcomes. It is covered even though the ticket's enumerated grep result omitted it. |
| `invalid_request` | `RemoteWorkflowProtocolError` | The service collapses malformed JSON, schema validation, and invalid aggregate arguments into one code; local behavior spans `WorkflowValidationError`, `ArgumentError`, and other input failures. Claiming one of those as exact parity would be false, so the loss of specificity is represented explicitly as a remote protocol rejection. |
| `invalid_correlation_id` | `RemoteWorkflowProtocolError` | Client/service protocol failure; the local engine has no correlation header. A correctly generated request should never receive it. |
| `invalid_idempotency_key` | `RemoteWorkflowProtocolError` | Client/service protocol failure; the local engine has no idempotency header. A correctly generated mutation should never receive it. |
| `unsupported_spec_version` | `RemoteWorkflowProtocolError` | Contract/version mismatch with no local-call equivalent. The seven methods do not install definitions, but the code is mapped and tested as part of the service's complete vocabulary. |
| `authentication_required` | `RemoteWorkflowAuthenticationError` | Authentication exists only at the remote boundary and must not masquerade as a workflow guard or field authorization decision. |
| `authorization_service_unavailable` | `RemoteWorkflowServiceError` | Upstream App Access availability is an infrastructure failure, not a caller authorization refusal and not a local `StateError`. |
| `route_not_found` | `RemoteWorkflowProtocolError` | Base-path/client-service contract mismatch, impossible for an in-process local call. |
| `workflow_service_error` | `RemoteWorkflowServiceError` | Remote infrastructure/internal failure with no local domain-equivalent exception. |

An unknown future server code maps to `RemoteWorkflowProtocolError` so contract
drift is visible. Client transport failures use `RemoteWorkflowServiceError`
with `network_error`; malformed successful/error HTTP projections use
`RemoteWorkflowProtocolError` with `malformed_response` or
`malformed_error_response`.

## Verification

The clean pre-change engine baseline was 232 passing tests and 2 existing
credential-gated PostgreSQL skips:

```text
$ /home/fahd/flutter/bin/cache/dart-sdk/bin/dart test --reporter expanded
...
00:04 +232 ~2: All tests passed!
```

The cached dependency resolved without network access. `http` stayed at the
already-locked 1.6.0:

```text
$ /home/fahd/flutter/bin/cache/dart-sdk/bin/dart pub get --offline
Resolving dependencies...
Downloading packages...
...
Got dependencies!
11 packages have newer versions incompatible with dependency constraints.
```

Static analysis is clean:

```text
$ /home/fahd/flutter/bin/cache/dart-sdk/bin/dart analyze
Analyzing loom_workflow_engine...
No issues found!
```

All 25 focused mock-client/error/unsupported cases pass:

```text
$ /home/fahd/flutter/bin/cache/dart-sdk/bin/dart test \
    test/remote_workflow_engine_api_test.dart --reporter expanded
...
00:00 +23: RemoteWorkflowEngineApi error vocabulary workflow_service_error maps to RemoteWorkflowServiceError
00:00 +24: unsupported methods throw immediately without token or HTTP calls
00:00 +25: All tests passed!
```

The final exact engine count is 257 passing and 3 skipped: the original
232/2 plus 25 new unit passes and one new live credential-gated skip. No
existing test changed or weakened.

```text
$ /home/fahd/flutter/bin/cache/dart-sdk/bin/dart test --reporter expanded
...
00:04 +257 ~3: All tests passed!
```

The live integration test compiles, is selected, and reports precisely which
real fixture values are absent. This is skip evidence, not a live round-trip
claim:

```text
$ /home/fahd/flutter/bin/cache/dart-sdk/bin/dart test \
    test/remote_workflow_engine_api_live_test.dart --reporter expanded
Running build hooks...Running build hooks...00:00 +0: loading test/remote_workflow_engine_api_live_test.dart
00:00 +0: deployed service createInstance is returned by queryInstances
  Skip: Set LOOM_WORKFLOW_SERVICE_BEARER_TOKEN (a real fan JWT), LOOM_WORKFLOW_SERVICE_COMMUNITY_ID (an installed live community id), LOOM_WORKFLOW_SERVICE_WORKFLOW_TYPE (a creatable live workflow type), LOOM_WORKFLOW_SERVICE_INITIAL_INSTANCE_DATA (valid JSON for that workflow type) to run against the deployed k3s workflow service.
00:00 +0 ~1: All tests skipped.
```

An explicit attempt to reach the real cluster failed at the sandbox socket
boundary before a Keycloak port-forward or token request could be made:

```text
$ kubectl get pods -n loom -o wide
Unable to connect to the server: dial tcp 127.0.0.1:6443: socket: operation not permitted

$ kubectl get deployment -n loom loom-workflow-service ...
Unable to connect to the server: dial tcp 127.0.0.1:6443: socket: operation not permitted
```

The untouched workflow-service package remains clean at exactly its baseline
48 passing tests and 5 existing live skips:

```text
$ /home/fahd/flutter/bin/cache/dart-sdk/bin/dart analyze
Analyzing loom_workflow_service...
No issues found!

$ /home/fahd/flutter/bin/cache/dart-sdk/bin/dart test --reporter expanded
...
00:01 +48 ~5: All tests passed!
```

Final formatting and whitespace checks are clean:

```text
$ /home/fahd/flutter/bin/cache/dart-sdk/bin/dart format \
    lib/src/api/remote_workflow_engine_api.dart \
    test/remote_workflow_engine_api_test.dart \
    test/remote_workflow_engine_api_live_test.dart
Formatted 3 files (0 changed) in 0.06 seconds.

$ git diff --check
<no output; exit 0>
```

## Proposed next steps

1. From an environment with k3s socket access, port-forward Keycloak and
   `loom-workflow-service`, mint a real `loom`-realm fan JWT using the already
   established client-credentials/direct-grant recipe, provide an installed
   community/workflow fixture and valid initial JSON, and run the focused live
   test until it reports `+1: All tests passed!`.
2. Treat Phase E.4b as separate, larger, unscoped work. Before wiring the app
   shell to this client, migrate the 10 synchronous `availableTransitions`
   call sites to `availableTransitionsAsync`; then introduce a real factory/DI
   seam for the roughly 19 direct `LocalWorkflowEngineApi` construction sites.
   Phase E.4b was not started here.

## Anything I could not do

- I could not mint a real JWT or execute the deployed-service create/query
  round trip because this sandbox has no live fixture variables and the k3s
  API socket is denied (`127.0.0.1:6443: operation not permitted`). Reporting
  the credential-gated skip as a live pass would be inaccurate.
- Everything else requested for the client-only Phase E.4a scope completed,
  including offline dependency resolution, all seven operation adapters,
  complete error-code tests, clean analysis, both full package regressions,
  and preservation of every prohibited path.
