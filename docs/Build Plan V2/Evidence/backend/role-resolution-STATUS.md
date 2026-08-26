# Role resolution in the deployed workflow service — status

## Result

Implemented the Phase B.3 role-resolution path. The service now obtains the
authenticated fan's effective App Access roles for the community and registers
the complete set with the local engine before query, aggregate,
available-transitions, and transition execution. It never accepts a role from
the HTTP request.

No `docs/references/**` file or community `*.jsonc` file was modified.

## Part 1 — engine multi-role support

- Changed the local engine registry from `Map<String, String>` to
  `Map<String, Set<String>>`.
- Added `setRolesForFan(fanId, roleIds)`, which replaces the complete set and
  stores a defensive immutable copy. `setRoleForFan` remains source-compatible
  and delegates to the one-element set form.
- Threaded `roleIds` through `evaluateGuard` and the transition evaluator.
  Existing `roleId` callers remain valid as a one-element set. A non-empty
  `allowedRoleIds` guard passes if *any* held role matches; an empty set fails.
- Updated guarded visibility and role-principal visibility. Existing
  single-role surface-permission callbacks are evaluated against each held role
  and grant only if at least one role grants.

### Red, then green

All three engine tests were added before the API existed. Their first targeted
run was red at test load (`0 passed, 1 load failure`):

```text
Error: The method 'setRolesForFan' isn't defined for the type
'LocalWorkflowEngineApi'.
```

That error occurred at each of the multi-role, replacement, and empty-set test
calls. After the implementation:

```text
resolved fan roles a fan holding both roles passes either role guard
resolved fan roles setting roles again replaces roles that were revoked
resolved fan roles an empty held-role set fails a non-empty role guard closed
00:00 +3: All tests passed!
```

## Part 2 — App Access effective-permissions client

- Added `resolveRoleIds` to `AppAccessDecisionClient` and implemented it in
  `HttpAppAccessDecisionClient`.
- It reuses the cached Keycloak bearer-token flow and calls
  `GET /v1/apps/{appId}/effective-permissions/{fanId}?groupId=...` with the
  original `x-loom-correlation-id` header.
- It accepts the live response shape's `roleIds` string array, returns a set,
  and throws `AppAccessDecisionException` for non-200 responses, invalid JSON,
  and malformed role arrays.

### Red, then green

The parse/request test was written before the method existed and first failed:

```text
NoSuchMethodError: Class 'HttpAppAccessDecisionClient' has no instance method
'resolveRoleIds'.
```

The malformed-response test was also red first because it expected an
`AppAccessDecisionException` but received that same `NoSuchMethodError`.
After implementation, `test/app_access_client_test.dart` passed **6/6**
(four existing tests plus two new tests), including the literal deployed
response shape, query parameter, correlation header, non-200, invalid JSON,
and non-string role-entry cases.

## Part 3 — workflow service wiring and fail-closed behavior

- Removed `_unresolvedRoleId` and all three Phase B.3 placeholder comments.
- Replaced the three sentinel registrations (query, aggregate, and
  available-transitions) with a common resolver that obtains the community
  group id, calls App Access, and calls `engine.setRolesForFan`.
- Added the same resolution to `applyTransition`. The current transition
  endpoint had no sentinel registration at all, so without this addition the
  ticket's required guarded-transition success case could not pass.
- Missing/blank group mappings return the existing `503`
  `authorization_service_unavailable` JSON shape. An empty successful
  resolution registers an empty set and produces the normal guard refusal;
  an `AppAccessDecisionException` or `SocketException` clears the set then
  returns that 503 shape. Clearing first prevents stale roles held by the
  cached engine from authorizing a later request after resolution fails.

### Red, then green

The actual deployed-shape bug test first failed:

```text
applyTransition accepts a role guard resolved by App Access
Expected: <200>
  Actual: <403>
```

It now passes (**1/1**) and verifies `hoa-board` authorizes an
`allowedRoleIds: ["hoa-board"]` transition, with the request's original UUID
correlation id, `loom_communities` app id, and the resolved community group id.

The empty/unavailable resolution test first failed because no role lookup was
made:

```text
Expected: <1>
  Actual: <0>
```

It now passes (**1/1**): `[]` is denied with `403 workflow_guard_refused`, and
an `AppAccessDecisionException` returns `503 authorization_service_unavailable`
without changing the instance.

The additional blank-group test first failed:

```text
Expected: <503>
  Actual: <403>
```

It now passes (**1/1**) and confirms no role lookup occurs when the community
group mapping is unavailable.

## Verification totals

| Command / suite | Exact result |
| --- | --- |
| `loom_workflow_engine`: new targeted role tests | 3 passed |
| `loom_workflow_service`: targeted client test file | 6 passed |
| `loom_workflow_service`: each of the three named service role tests | 1 passed each |
| `loom_workflow_engine`: full `flutter test` | **284 passed, 3 skipped** |
| `loom_workflow_service`: full `flutter test` | **53 passed, 5 skipped** |
| `loom_communities_app_shell`: full `flutter test` | **273 passed** |
| `loom_ux_judges`: full `flutter test` | **432 passed** |
| `loom_communities_demo`: full `flutter test` | **160 passed** |
| `loom_workflow_engine`: `flutter analyze .` | passed, no issues |
| `loom_workflow_service`: `flutter analyze .` | passed, no issues |

The engine total rose from the stated 281 to 284 because this ticket adds the
three required engine tests; its three skips are unchanged environment-gated
PostgreSQL/deployed-service tests. The service total includes five new tests
(two HTTP-client and three workflow-service cases); its five skips are the
existing environment-gated PostgreSQL/live App Access tests. No total moved
down. The app-shell, judges, and demo totals match their stated baselines.

`melos run analyze` was run but is **not clean**. Melos fails fast in
`loom_communities_app_shell` on 10 existing info-level findings that are outside
this ticket's diff:

- `lib/src/part18_marketplace_rendering.dart:856-858` — three
  `unawaited_futures` findings.
- `test/completed_action_visible_result_test.dart:132`,
  `test/v3_milestone_1b1c_search_ai_answer_widget_test.dart:33,151`,
  `test/v3_milestone_a6_generic_instance_card_test.dart:1082,1231`, and
  `test/v3_milestone_a7_binding_dispatch_test.dart:925,1082` — seven
  `prefer_const_constructors` findings.

I did not weaken analyzer policy or edit those unrelated app-shell files. The
two packages changed by this ticket each analyze cleanly, as recorded above.

## Findings and scope notes

No verified fact was contradicted. One additional current-tree finding mattered
to the fix: unlike the three documented sentinel sites, `applyTransition` had
no role registration at all. It therefore failed closed for every
role-guarded transition even before considering the sentinel; it is now wired
to the same resolver.

No per-community fraction is applicable to this backend authorization ticket.
The tests use service/engine fixtures rather than community UI workflows.

I could not run the skipped live PostgreSQL or deployed-service tests because
their required environment credentials/tokens were not supplied. No live
cluster state was changed.
