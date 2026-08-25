# Root cause: `publish` is rejected for `member` against real PostgreSQL

## Outcome: confident diagnosis and recommended fix

The PostgreSQL adapter is not resolving the role differently, and the created
instance is in `draft`. The failing integration fixture never registers a role
for its fan after the engine was changed to fail closed when a role is absent.

There is also a production wiring gap with the same consequence: the deployed
workflow service authenticates a fan id but does not resolve and register that
fan's real community role before role-guarded engine calls. Fixing the test alone
will make the direct engine integration test honest, but it will not make
role-guarded transitions work through the deployed service.

## Exact failure mechanism

1. `postgres_database_integration_test.dart:118-121` constructs a new
   `LocalWorkflowEngineApi`. Its `_roleIdByFanId` registry starts empty.
2. The test calls `createInstance(... fanId: 'member')` at lines 122-126 but
   never calls `setRoleForFan('member', 'member')`. A fan id is an account
   identity; passing it to `createInstance` does not declare its role.
3. `_createInstanceValidated` writes `currentState: machine.initialState` at
   `local_workflow_engine_api.dart:1277-1284`. This definition's initial state
   is `draft`, so the persisted row is `draft`.
4. `applyTransition` enters `_resolveTransition`, which reads that persisted
   row and calls `availableTransitions` with
   `roleId: _roleIdByFanId[fanId]` at
   `local_workflow_engine_api.dart:958-978`. Because the fixture never
   registered the fan, that expression is `null`.
5. `evaluateGuard` deliberately rejects a non-empty `allowedRoleIds` guard
   when `roleId` is null at `guard_evaluator.dart:25-30`. It explicitly does
   not compare the individual fan id to a role id. Therefore `publish` is
   filtered out even though both strings happen to be `"member"` in this
   fixture.
6. `_resolveTransition` separately checks the declared transition's source
   state at `local_workflow_engine_api.dart:980-988`, then fails because the
   filtered candidate list does not contain `publish` at lines 989-999.

The observed message is decisive about the state question. A row outside
`draft` would have produced `Transition publish not available from state ...`
at lines 984-987. The emitted message, `Transition publish is not available for
member`, is the later guard-filter failure at lines 996-999, so the source-state
check passed.

## Why it appeared now

The test was added in commit `88306528` on 2026-08-15. At that time guard
evaluation used the acting identity as a compatibility fallback when no
separate role was supplied. Commit `13fb5f49` on 2026-08-22 intentionally
removed that fallback:

```text
before: identityIdForAllowedCheck = roleId ?? fanId
after:  roleId == null => allowedRoleIds fails closed
```

That commit changed this PostgreSQL test's named arguments from `personaId` to
`fanId`, but did not add the now-required role registration. The test is skipped
unless `LOOM_POSTGRES_PASSWORD` is present, so ordinary green suite runs did not
exercise the stale fixture. This test may therefore never have passed under the
current fail-closed identity semantics.

## PostgreSQL versus in-memory behavior

There is no database-specific role lookup in this path. `setRoleForFan` writes
only the `LocalWorkflowEngineApi` instance's in-memory `_roleIdByFanId` map at
`local_workflow_engine_api.dart:156-164`. `_resolveTransition` uses that same map
regardless of whether `WorkflowDatabase` is backed by SQLite memory or
PostgreSQL. The fresh PostgreSQL schema contains workflow definitions and
instances, not this actor-to-role registration.

The sibling keyset-query test does not exercise transition guards, so its pass
is consistent with this diagnosis and does not distinguish role behavior.

## Production impact

The deployed service currently has the same missing input at its HTTP boundary:

- `WorkflowRequestIdentity` carries only `fanId`
  (`workflow_service/lib/src/identity.dart:5-14`).
- The available-transitions route registers
  `\u0000loom-role-resolution-pending` rather than a real role
  (`workflow_service.dart:943-964`). That sentinel cannot match a package role.
- The apply-transition route calls `engine.applyTransition` without registering
  any role (`workflow_service.dart:1270-1280`). Depending on prior requests to
  the cached community engine, the lookup is therefore either absent or the
  sentinel; both fail `allowedRoleIds`.
- The current `AppAccessDecisionClient` returns only a boolean decision. It does
  not expose the role ids that App Access already represents in its
  `EffectivePermissions.roleIds` contract.

Consequently, the successful authenticated `GET .../instances` proves JWT,
App Access reachability, and database reads, but it does not exercise a
role-guarded transition. In the current service wiring, a correctly configured
App Access membership still cannot make an `allowedRoleIds` transition pass.

## Recommended fix

### Direct PostgreSQL engine test

Immediately after constructing `api`, register the fixture's account-to-role
mapping:

```text
api.setRoleForFan('member', 'member')
```

Do this before `createInstance`, so the fixture remains correct if the initial
state later gains a role-gated `creationGuard`. Do not remove or relax the
`allowedRoleIds` guard, and do not restore the old `fanId`-as-role fallback.

The test should additionally assert the security boundary explicitly: the same
fan id without role registration is rejected, while the registered mapping
succeeds. That prevents another environment-skipped integration fixture from
silently relying on account-id/role-id string equality.

### Deployed workflow service

Add a trusted server-side role-resolution boundary backed by App Access. For
each guard-evaluating request, resolve the authenticated fan's effective role
ids in the community's mapped group and supply those resolved roles to the
engine before availability, creation, update, visibility, or transition
evaluation. Never accept a role id from the request body or JWT without the
server-side App Access check.

The App Access effective-permissions response already carries `roleIds`; expose
that result through the workflow service's App Access client instead of using
`_unresolvedRoleId`. Because App Access can return multiple roles while
`setRoleForFan` currently stores one, the implementation must preserve the full
set (for example, by extending the engine role registry and guard evaluator to
pass when any trusted effective role is in `allowedRoleIds`) rather than picking
an arbitrary role. Remove the sentinel only when every guard-evaluating service
route supplies the trusted result and continues to fail closed if resolution is
unavailable.

Add a real-service/PostgreSQL regression that seeds an App Access group
membership, proves an allowed role can execute a role-guarded transition, and
proves a different or unresolved fan receives the generic guard refusal while
the row remains in its source state.

## Instrumentation decision

No additional runtime instrumentation is required for this diagnosis. The
existing emitted error identifies the post-source-state guard-filter branch,
the role registry is deterministically empty in the fixture, and commit
`13fb5f49` records the exact semantic change that made the missing registration
fail closed.
