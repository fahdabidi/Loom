# Remote `LoomAuthApi` status

## Result

The app shell now has `RemoteLoomAuthApi`, selected only when a complete
`LoomRemoteServiceConfiguration` exists. It uses the existing
`LoomAuthSession` for bearer-token retrieval, refresh, logout, secure storage,
and interactive login; it does not create another OAuth client, token cache, or
storage layer.

`LocalAuthApi` was not modified. With no remote configuration, the resolver
returns `LocalAuthApi` exactly as before. The `LocalExtensionScreen.authApi`
injection point remains intact. The demo's per-community provider now calls the
same resolver, so it cannot accidentally keep injecting local auth into a
configured production host.

## Production seam and mapping source

`configureLoomRemoteServicesFromEnvironment()` remains the production entry
point. It now requires all-or-none definitions for the existing auth token
endpoint/client id and workflow base URI plus:

- `LOOM_APP_ACCESS_BASE_URI`
- `LOOM_FAN_PASSPORT_BASE_URI`
- `LOOM_COMMUNITY_GROUP_IDS`, a JSON map from canonical community id to the
  deployed App Access group id.

The group map is the app-shell copy of the deployed mapping that the workflow
service uses; it is not derived in the client. The auth implementation looks up
its group with the canonical community id and does not derive it from an
extension id or handle. Therefore **0/11** community group ids are derived
locally; a configured host must supply the server mapping for **11/11**
installed communities it enables. Missing entries fail loudly.

The `@visibleForTesting` remote-configuration override is deliberately
separate from the existing session override. Replacing a test session does not
select remote App Access/Fan Passport behavior in production. Only the complete
production configuration selects the remote API.

## `LoomAuthApi` member coverage

| Member | Status | Real-service behavior |
| --- | --- | --- |
| `listAccounts` | Backed | Pages `GET /v1/apps/{appId}/groups/{groupId}/members`, reads each `GET /v1/fan-passports/{fanId}`, and maps `active` to `MembershipStatus.active` and `requested`/`pending` to `MembershipStatus.pendingApproval`. Unknown states and memberships that cannot fit the single-role `LoomAccount` model throw loudly. |
| `signIn` | Backed | Uses `LoomAuthSession.currentAccessToken()`, obtains the bearer token's `fanId`, reads that fan's group membership and passport, and never lets the local account picker impersonate another fan. |
| `signUp` | Backed | Uses the authenticated fan's existing or newly created Fan Passport and puts the configured package-verbatim role id into App Access. Open identities request `active` and return `LoomActiveSignUpResult`; approval-gated identities request `requested` and return `LoomPendingApprovalSignUpResult`. A response state that differs from the requested result fails loudly. |
| `approveAccount` | Backed | Reads the pending membership then posts `{"decision":"approve","roleIds":[...]}` to `POST /v1/apps/{appId}/groups/{groupId}/membership-requests/{fanId}/decision`; it requires an active local session and relies on App Access for real admin authorization. |
| `signOut` | Backed | Calls `LoomAuthSession.logout()` and clears the in-memory app session. |
| `currentSession` | Backed | Exposes the in-memory, successfully remote-verified account session. |
| `issueInvite` | Unbacked (clear `UnimplementedError`) | App Access has membership requests and decisions, but no endpoint to mint, persist, address, or look up an invite code. It needs a real invitation service. |
| `redeemInvite` | Unbacked (clear `UnimplementedError`) | The deployed surface has no invite-code resolution/redeem endpoint. It needs the same invitation service, including code-to-community/role lookup. |

That is **6/8 members backed** and **2/8 explicitly unbacked**. No member
falls back to local behavior or returns a fabricated empty/synthesized result.

Every App Access request generates a UUIDv4 `x-loom-correlation-id`; mutations
also carry an idempotency key. Tokens are not logged.

## Test evidence

Complete focused app-shell verification:

- `flutter test --no-pub test/remote_auth_api_test.dart test/remote_auth_session_test.dart test/remote_service_configuration_environment_test.dart --reporter expanded` — **19 passed, 2 skipped, 0 failed**. The two skips are intentional dart-define-only environment cases. This includes the new fake-HTTP tests for local-vs-configured selection, session-backed sign-in, member listing, active/pending membership-state mapping, open and approval-gated signup, approval decision request shape, UUID correlation ids, session logout delegation, and loud invite failures.
- `flutter test --no-pub test/remote_auth_api_test.dart --reporter expanded` — **9 passed, 0 skipped, 0 failed**.

Static checks:

- `flutter analyze --no-pub lib test/remote_auth_api_test.dart test/remote_auth_session_test.dart test/remote_service_configuration_environment_test.dart` — **0 errors, 0 warnings, 3 existing informational findings**. The infos are all `unawaited_futures` in `lib/src/part18_marketplace_rendering.dart:856-858`, outside this change.
- `dart format --output=none --set-exit-if-changed` over all changed app-shell Dart files — **8 files checked, 0 changed**.
- `git diff --check` — **0 whitespace errors**.

Requested full-suite command attempts (recorded exactly; none is overstated as
green):

| Command | Observed result | Total/status |
| --- | --- | --- |
| `cd app/packages/core/loom_communities_app_shell && flutter test` | Flutter tester crashed with a segmentation fault during finalization of `v3_milestone_phasee_purchase_proposal_test.dart`; no assertion was changed. | Final runner tally: **227 passed, 2 skipped, 56 did not complete/error**. That enumerates 285 cases, but it is not a completed suite total. The ticket's expected 274 cannot be compared to a passing completion. |
| `cd app/packages/core/loom_workflow_engine && flutter test` | The environment execution window ended mid-run. | **122 passed, 3 skipped observed; final total unavailable**. |
| `cd app/packages/tooling/loom_ux_judges && flutter test` | The environment execution window ended mid-run. | **180 passed observed; final total unavailable**. |
| `cd app/apps/loom_communities_demo && flutter test` | The environment execution window ended mid-run. | **9 passed observed; final total unavailable**. |

No completed existing-suite total moved down in the available evidence. The new
focused test file contributes nine tests; it accounts for the focused
app-shell total increasing to 19 passed plus two intentional skips. The full
app-shell result is a test-runner crash finding, not evidence that its expected
total is lower.

## Unable to complete

I could not produce successful full-suite totals for app shell, workflow
engine, judges, or demo in this environment. The app shell has a concrete
Flutter tester segmentation-fault finding; the other three commands were
terminated by the execution window before their final summary. No test was
weakened, deleted, skipped, or inverted to hide either condition.
