# Membership actor-header fix — live probe evidence, 2026-09-12

Ticket: `app_access_create_instance_integration_test.dart`'s membership `PUT` needed App Access's
actor header (`X-Loom-Actor`), not the workflow-service `x-loom-fan-id` that `_sendJson`'s existing
`fanId:` parameter sets.

Ticket status: **the header is now sent, and the call no longer fails with `missing_actor`. It fails
with `fan_identity_mismatch`, because the test authenticates as a service account and App Access's
membership route requires a fan actor whose `fanId` claim equals the header.** The ticket's premise
("add the header and it passes") is therefore incomplete for the current service, not wrong about the
header.

## How the probe was run

The sandbox cannot bind a listener that survives a child process (`ss -ltn` in a later command shows
the loopback listeners gone), so `kubectl port-forward` is unusable here. A Python TCP forwarder
running in the *same* process as the `dart test` child was used instead:

  in-process forwarder: 127.0.0.1:18080 -> 127.0.0.1:30080 (app-access NodePort)
  in-process forwarder: 127.0.0.1:18082 -> 127.0.0.1:30082 (keycloak NodePort)

Credentials came from the cluster's own secrets (`postgres-credentials`,
`postgres-workflow-app-credentials`, `keycloak-admin-credentials`) read with
`kubectl get secret`. No credential was invented.

Command (exact):

    LOOM_POSTGRES_PASSWORD=<from secret> \
    LOOM_POSTGRES_APP_PASSWORD=<from secret> \
    LOOM_APP_ACCESS_BASE_URL=http://127.0.0.1:18080 \
    LOOM_KEYCLOAK_TOKEN_URL=http://127.0.0.1:18082/realms/loom/protocol/openid-connect/token \
    LOOM_KEYCLOAK_ADMIN_URL=http://127.0.0.1:18082 \
    LOOM_KEYCLOAK_ADMIN_USERNAME=<from secret> LOOM_KEYCLOAK_ADMIN_PASSWORD=<from secret> \
    python3 /tmp/run_live.py     # starts the forwarders, then runs:
    # dart test test/app_access_create_instance_integration_test.dart --concurrency=1

## Result A — with the fix (this working tree)

    00:01 +0 -1: live App Access authorizes create and Postgres rolls back an invalid batch [E]
      Expected: <200>
        Actual: <403>
      {"code":"fan_identity_mismatch","message":"X-Loom-Actor does not match the authenticated token's fanId claim","correlationId":"33333333-3333-4333-8333-333333333333","details":[]}
      test/app_access_create_instance_integration_test.dart 697:3  _seedAppAccess
    RC=1

Line 697 is `expect(membership.statusCode, HttpStatus.ok, ...)`. The install call above it
(`installCommunityPackage`, all five assertions) passed again in this same run, and the
`missing_actor` 400 is gone.

## Result B — the header alone was the ticket; the identity is the next blocker

`_seedAppAccess`'s bearer token is the throwaway Keycloak client's **client-credentials** token. Its
claims, decoded from the live token:

    azp: <throwaway client> (per run)
    client_id: <throwaway client>
    sub: <service-account user uuid>
    fanId: (absent)

App Access's membership route requires a **fan** actor whose `fanId` claim equals the header value
(`CallerActor` constants: `fan_identity_mismatch`, `fan`, `ACTOR_HEADER`, `FAN_ID_CLAIM`; the
`fanId` branch is `request.getHeader("X-Loom-Actor")` == jwt claim `fanId`). A client-credentials
token has no `fanId` claim at all, so **every possible value** of `X-Loom-Actor` fails.

Four-value probe using the persistent provisioning client's token
(`loom-app-access-provisioner`, which *does* hold the `app-access-provisioner` realm role) against
`PUT /v1/apps/loom_communities/groups/loom_communities_chess-club/members/probe-actor-<ts>`:

| X-Loom-Actor value | Result |
| --- | --- |
| `fan-probe-actor-<ts>` (a fan-id-looking string) | `403 fan_identity_mismatch` |
| the provisioner's own `client_id` | `403 fan_identity_mismatch` |
| `{"actorType":"fan","actorId":"fan-probe-actor-<ts>"}` | `403 fan_identity_mismatch` |
| `{"actorType":"service","actorId":"<client_id>"}` | `400 missing_actor`, message `Only a fan actor may act on a membership request, not 'service'` |

**Cleanup:** zero `group_membership`, `group_membership_role` and `idempotency_record` rows match
`%probe-actor%` (verified by psql after the probe). No durable row was created.

## What this means for the ticket

- The fix as dispatched is correct and necessary: `X-Loom-Actor` is now set, and the
  `missing_actor` 400 it was filed against is resolved.
- It is not sufficient. The test cannot pass end-to-end with a service-account token: App Access
  requires a fan actor on the membership route. Either the test must obtain a **fan** token for
  `fan-b3-allowed-<unique>` (and that fan must hold a group-administrator role in the group it is
  being added to, or the route's administrator check will refuse it next), or the service must accept
  a provisioning actor on this route.
- That is a product/design question (who may assign membership — the fan-facing path is
  administrator-gated), not something to settle by weakening the assertion. The assertion is
  unchanged.
