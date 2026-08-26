# Reset-path test restoration — status

Status: complete (2026-08-25)

## Restored coverage

Restored `resetting all registrations restores local routing for all` in
`app/packages/core/loom_communities_app_shell/test/remote_auth_session_test.dart`
from its `HEAD~1` body. The test:

1. Enables remote routing for `per-community-reset-first` and
   `per-community-reset-second`.
2. Calls `resetEngineNativeCommunityFactoryRegistrationsForTesting()`.
3. Installs both experiences and resolves both engines.
4. Requires both resolved engines to be `LocalWorkflowEngineApi`.

Both complementary tests are present in that file:

- `production factory defaults to the local engine`
- `resetting all registrations restores local routing for all`

No production code remains changed. No community JSON or locked reference documentation was changed.

## Direct test and can-fail proof

| Run | Command | Result |
| --- | --- | --- |
| Restored test | `cd app/packages/core/loom_communities_app_shell && flutter test test/remote_auth_session_test.dart --name 'resetting all registrations restores local routing for all'` | 1/1 passed |
| Temporary negative control | Same command after temporarily making `resetEngineNativeCommunityFactoryRegistrationsForTesting()` a no-op | Expected failure: 0/1 passed. Both actual engines were `RemoteWorkflowEngineApi`, and the local-engine matcher failed at `remote_auth_session_test.dart:162`. |
| Restored implementation | The registration-map `.clear()` call was restored immediately, before full-suite verification. | Confirmed by the subsequent green app-shell suite. |

The temporary no-op was not retained.

## Regression verification

| Suite | Command directory | Exact result |
| --- | --- | --- |
| Communities app shell | `app/packages/core/loom_communities_app_shell` | 274/274 passed |
| UX judges | `app/packages/tooling/loom_ux_judges` | 432/432 passed |
| Workflow engine | `app/packages/core/loom_workflow_engine` | 287/287 passed, with 4 skipped (287 passed of 291 enumerated) |
| Workflow service | `app/packages/core/loom_workflow_service` | 54/54 passed, with 5 skipped (54 passed of 59 enumerated) |
| App-access provisioning | `app/packages/tooling/loom_app_access_provisioning` | 15/15 passed |
| Communities demo | `app/apps/loom_communities_demo` | 160/160 passed |

All suites used `flutter test` from the listed directory. The app-shell total is 274 rather than the
ticket's stated 273: it moved up by one because this change adds the restored reset-path test while
keeping the default-local test. No test total moved down. The app-shell run emitted one non-fatal,
off-screen `tap()` warning in
`v3_milestone_phasee_purchase_proposal_test.dart`; the suite still completed 274/274.

## Limitations

None. The requested test restoration, direct pass, reversible can-fail proof, and all listed
regression suites completed.
