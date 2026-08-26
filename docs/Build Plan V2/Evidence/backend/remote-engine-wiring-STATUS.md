# Remote engine wiring — status

## Result

Complete. The Communities demo startup now reads the existing
`LoomRemoteServiceConfiguration` and, only when it is present, supplies a
remote `EngineNativeCommunityEngineFactory` through the production factory
seam. The factory passes the unchanged `extensionId` through as the remote
engine's `communityId`.

With no remote configuration, startup does not select a factory and the
production seam retains the exact pre-existing local construction:
`LocalWorkflowEngineApi(db: database, communityId: extensionId, ...)`.

No secrets, bearer tokens, or service URIs are hardcoded. The bearer token
comes from `LoomAuthSession.currentAccessToken`; the service URI comes from
`LoomRemoteServiceConfiguration`.

## Seam boundaries

`configureEngineNativeCommunityEngineFactoryForProduction` is the
production-facing selection point. The demo app calls it at startup only
after `configureLoomRemoteServicesFromEnvironment` returns a configuration.
The supplied factory is the existing remote implementation adapted directly
from that configuration.

`overrideEngineNativeCommunityEngineFactoryForTesting` remains a separate
`@visibleForTesting` override. It is not used by startup or by remote-service
configuration. For an unregistered community store, an explicit test override
temporarily wins over the production factory; resetting it exposes the still
selected production factory again. A per-community production registration
continues to take precedence over both, preserving its existing behavior.

## Selection evidence

The three requested selection checks are **3/3 passing**:

1. No production remote configuration produces `LocalWorkflowEngineApi`.
2. A `LoomRemoteServiceConfiguration` produces `RemoteWorkflowEngineApi` with
   `communityId == extensionId` and base URI
   `https://workflow.test/api/`.
3. A testing override returns its fake engine while installed, then resetting
   it returns the configured production `RemoteWorkflowEngineApi` for the next
   store.

## Tests changed

Only `app/packages/core/loom_communities_app_shell/test/remote_auth_session_test.dart`
was updated. Three obsolete factory-routing checks were replaced with the
three required production-selection checks above; no test was changed to
preserve a local path, and the app-shell test total therefore remains 273.

## Verification

| Suite | Command | Result |
| --- | --- | --- |
| Focused app-shell selection coverage | `flutter test test/remote_auth_session_test.dart test/engine_native_community_engine_factory_test.dart` | **9/9 passed** |
| Communities app shell | `flutter test` | **273/273 passed** |
| Workflow engine | `flutter test` | **287 passed, 4 skipped** |
| Workflow service | `flutter test` | **54 passed, 5 skipped** |
| App Access provisioning | `flutter test` | **15/15 passed** |
| UX judges | `flutter test` | **432/432 passed** |
| Communities demo | `flutter test` | **160/160 passed** |

All listed commands were run from their respective package directories. No
test total moved down: the app-shell total was 273 before and after this
change.

The 4 workflow-engine skips and 5 workflow-service skips are the existing
PostgreSQL credential-gated integrations; `LOOM_POSTGRES_PASSWORD` was not
provided. I did not rerun the deployed-stack integration gate because this
ticket identifies it as already measured and closed.

## Messages store

`_MessagesEngineStore` in `part02_tab_shell.dart` was not changed. I do not
recommend migrating it as follow-on work merely because community workflows
now use the remote engine: it is a separate, private, seed-backed Messages-tab
store. Re-evaluate a migration only if Messages is given a durable,
cross-client workflow/service contract; that would be a distinct architecture
and product decision.
