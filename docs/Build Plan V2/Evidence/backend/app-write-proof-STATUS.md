# App-driven remote WRITE proof — status

**Status:** implemented and statically validated; **not run on Android**.
This VM has no Android emulator, and on-device runs occur on Windows. No
`APP_WRITE_PROOF` instance id was produced here, so this dispatch does not
claim that a persisted service row was observed.

## Implemented proof

`app/apps/loom_communities_demo/integration_test/on_device_remote_backend_proof_test.dart`
now retains the existing production-factory read proof and then, using that
same factory-resolved `RemoteWorkflowEngineApi`:

1. creates a `hoa-facility-reservation` for
   `community_cedar_commons_hoa` as `fan-test-alice`;
2. supplies **8/8** required instance-data fields: `title`, `facility`,
   `eventDate`, `eventTime`, `durationMinutes`, `reservationWindow`,
   `locationDetails`, and `requesterFanId`;
3. uses a nonce in `facility`, avoiding the deployed reservation workflow's
   location-overlap guard on repeated runs;
4. applies `board-reserve-facility` as `fan-test-alice`, asserts the returned
   state is `reserved`, and emits exactly:

   ```text
   APP_WRITE_PROOF instanceId=<id> state=<state>
   ```

The implementation covers **1/1** requested app-driven create-and-transition
path. The returned state remains only the client's view; the printed instance
id is deliberately the independent database-correlation handle. No client
query is treated as persistence evidence.

The test remains an integration test and is not selected by the demo app's
default `flutter test` suite. It shares the existing explicit skip gate rather
than adding a fallback or a test-only engine.

### Define-gate finding

The ticket refers to three dart defines, but the current production entrypoint
requires an all-or-nothing set of **6/6** defines: auth token endpoint, auth
client id, workflow-service base URI, App Access base URI, Fan Passport base
URI, and the community-to-App-Access-group JSON map. Gating the write with
only three would cause production startup to fail as a partial configuration.
The write therefore uses the same existing six-define skip reason and cannot
run by default or with partial production configuration.

## Android execution — not completed

| Cedar Commons HOA measure | Result |
| --- | --- |
| Required data fields supplied | **8/8** implemented; **0/8** observed on device |
| Factory-resolved remote engine assertion | **1/1** implemented; **0/1** observed on device |
| Create plus `board-reserve-facility` transition | **1/1** implemented; **0/1** observed on device |
| Greppable persisted-row correlation line | **1/1** implemented; **0/1** emitted on device |

Run the integration target on the Windows host with an attached Android device
and all six production defines. Preserve the `APP_WRITE_PROOF` line and use
its `instanceId` to inspect the deployed Postgres row independently. That
database check is still required to establish the real write; it was not and
cannot be performed from this VM.

## Static and regression verification

`flutter analyze integration_test/on_device_remote_backend_proof_test.dart`
completed with **0 issues**. The Android integration test itself was not run
because no emulator/device is available here.

| Suite | Command | Exact result |
| --- | --- | --- |
| Communities app shell | `cd app/packages/core/loom_communities_app_shell && flutter test` | **284 passed, 0 failed, 2 skipped (286 total)** |
| UX judges | `cd app/packages/tooling/loom_ux_judges && flutter test` | **432 passed, 0 failed, 0 skipped (432 total)** |
| Workflow engine | `cd app/packages/core/loom_workflow_engine && flutter test` | **287 passed, 0 failed, 4 skipped (291 total)** |
| Workflow service | `cd app/packages/core/loom_workflow_service && flutter test` | **54 passed, 0 failed, 5 skipped (59 total)** |
| App Access provisioning | `cd app/packages/tooling/loom_app_access_provisioning && flutter test` | **15 passed, 0 failed, 0 skipped (15 total)** |
| Communities demo | `cd app/apps/loom_communities_demo && flutter test` | **159 passed, 1 failed, 0 skipped (160 total)** |

No suite's total moved down. The demo suite still contains **160 total** tests,
but it is not green: the unrelated
`test/retired_vocabulary_gate_test.dart` reports pre-existing occurrences of
`free_personalized` in
`packages/core/loom_communities_app_shell/test/remote_auth_api_test.dart:397`
and `impersonation` in
`packages/core/loom_communities_app_shell/lib/src/part39_remote_auth_api.dart:60`.
Neither file nor the failing assertion was modified in this dispatch.

No community JSONC, locked reference documentation, production factory, or
messages engine was changed.
