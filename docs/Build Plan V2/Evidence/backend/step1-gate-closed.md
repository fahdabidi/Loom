# Step 1 gate closed — all three integration tests run and pass live

**Date:** 2026-08-26
**Verified from my own shell**, not from any agent report.

Step 1's acceptance criterion was stated as: *"DONE means the three engine integration
tests STOP SKIPPING."* That wording was chosen deliberately, because a suite that skips
its only real integration test is green and proves nothing. They now run, and they pass.

## The gate

| test | needs | result |
|---|---|---|
| `real PostgreSQL upgrades the legacy creator column without losing rows` | Postgres creds | **pass** |
| `real PostgreSQL supports definition upsert, instance creation, and a transactional transition` | Postgres creds | **pass** |
| `real PostgreSQL sorts queryInstancesKeyset by a bound top-level key` | Postgres creds | **pass** |
| `deployed service createInstance is returned by queryInstances` | fan JWT + live community | **pass** |

Engine suite with credentials present: **290 passed, 1 skipped**, up from 287 / 4. The one
remaining skip is the remote live test when its environment is absent; supplied, it passes.

## How to run them — the recipe, so this is repeatable

Neither set runs by default, and that is the point: they are gated on real infrastructure
rather than quietly faked. Both gates are environment variables, so a run that "passes"
without these has skipped.

**Postgres tests** — port-forward, then take credentials from the cluster secret:

    kubectl port-forward -n loom svc/postgres 15432:5432

    LOOM_POSTGRES_HOST=127.0.0.1
    LOOM_POSTGRES_PORT=15432
    LOOM_POSTGRES_DATABASE=loom_workflow_service
    LOOM_POSTGRES_USERNAME / LOOM_POSTGRES_PASSWORD   # from secret/postgres-credentials

**Remote live test** — a real fan JWT plus a workflow the fan is actually allowed to
create:

    LOOM_WORKFLOW_SERVICE_BASE_URI=http://127.0.0.1:30083     # NodePort; the test's
                                                              # default is 18083, which
                                                              # assumes a port-forward
    LOOM_WORKFLOW_SERVICE_BEARER_TOKEN=<fan JWT from loom-test-client>
    LOOM_WORKFLOW_SERVICE_COMMUNITY_ID=community_cedar_commons_hoa
    LOOM_WORKFLOW_SERVICE_WORKFLOW_TYPE=hoa-facility-reservation
    LOOM_WORKFLOW_SERVICE_INITIAL_INSTANCE_DATA={"title":...,"facility":...,
      "eventDate":...,"eventTime":...,"durationMinutes":...,"reservationWindow":...,
      "locationDetails":...,"requesterFanId":"fan-test-alice"}

Two details that cost time and are easy to hit again:

- **The workflow type must be one the fan may create.** `hoa-architectural-request` has
  `createRoleIds: ['hoa-member']`; a fan holding `hoa-board` is correctly refused with
  403. `hoa-facility-reservation` allows both. A 403 here is the system working.
- **All eight required `instanceDataSchema` fields must be present**, or creation
  correctly returns `400 invalid_request`.

## What had to be true first

Each of these was invisible until the previous one cleared, which is the argument for
running against a live cluster rather than reasoning about it:

1. **k3s was simply not running.** Phases C and D were already built and deployed.
2. **Role resolution was never wired** (1c) — the service registered a fail-closed
   sentinel, so no guarded transition could pass.
3. **The community-to-group map was `{}`** (1d) — every create 503'd before App Access was
   consulted.
4. **App Access held a different role id space** (1e) — `cedar_commons_hoa_admin` vs the
   package's `hoa-board`.
5. **The deployed app-access image predated its own endpoint's implementation** — it
   answered `501 not implemented` for code that had existed since 2026-08-15.
6. **A column rename shipped without a migration** (1n) — every insert failed with
   SQLSTATE 42703 against any database created before the rename.
7. **A package formula threw on an absent optional flag** — `if(reminderEnabled, ...)`
   where the field is not required, killing row hydration before visibility ran.

## The measurement lesson this whole sequence taught

Four separate times, something was declared present or working on the strength of a
**proxy** rather than the artifact that executes:

| checked | what actually ran |
|---|---|
| a hand-written curl | the applier, which sends headers the curl omitted |
| a controller wiring an endpoint | a deployed image that answered 501 |
| a method implemented in source | an image built before that commit |
| the engine's parser in source | an image bundling an older engine |

**Verify against the artifact that actually executes.** Source, controllers, and
hand-built probes are all proxies for it.

And the corollary that closed this gate: **a green suite that skipped its only real
integration test proves nothing** — which is why the criterion was "stop skipping" rather
than "pass".
