# GAP TICKET — RLS community-isolation backstop is inert (service runs as a Postgres superuser)

**Status:** IN PROGRESS (2026-09-03) — two-role split approved by the user. Role `loom_workflow_app`
provisioned (`NOSUPERUSER NOBYPASSRLS`; creds in secret `postgres-workflow-app-credentials`;
provisioning SQL at loom-backend `deploy/postgres/provision-loom-workflow-app-role.sql`, commit
`364be85`). Runtime/migration code split dispatched; build + redeploy + live verification pending.
**Severity:** security — a defense-in-depth isolation backstop exists in code but is bypassed in
production, AND the service is over-privileged regardless of RLS
**Found:** 2026-09-03, by the RLS-backstop dispatch (Batch v4, Thread 1). The agent implemented the
backstop correctly and its own integration test caught that the backstop does nothing under the
current credentials — an honest self-catch, not a silent pass.

## What shipped (committed, correct, inert-safe)

The workflow-service now carries a per-community Postgres Row-Level-Security backstop:

- `migrateCommunityIsolationPolicy(connection, tableName)` — for each of the 8 tenant tables
  (`workflow_instances`, `workflow_documents`, `workflow_document_acknowledgements`,
  `workflow_document_member_states`, `workflow_document_revision_requests`,
  `workflow_document_revisions`, `workflow_export_bundles`, `workflow_item_queue_entries`) runs
  `ALTER TABLE … ENABLE ROW LEVEL SECURITY`, `… FORCE ROW LEVEL SECURITY`, and a repeatable
  `DROP POLICY IF EXISTS community_isolation` + `CREATE POLICY community_isolation … USING
  (community_id = current_setting('app.current_community_id', true))`. Wired into repo
  initialisation, so it self-applies on startup and is idempotent/corrective.
- Per-request session context: `runWithCommunity(communityId, action)` / `runTx` issue
  `SELECT set_config('app.current_community_id', @communityId, true)` (`SET LOCAL`, parameterised)
  so the policy resolves to the caller's community for the life of the transaction.
- The one legitimate cross-community writer (`bin/publish_workflow_definitions.dart`) is exempted
  through a dedicated `_runWithoutCommunityTransaction` path, not by weakening the policy.

**This is safe to keep deployed today:** a `BYPASSRLS` superuser ignores `FORCE ROW LEVEL SECURITY`,
so the running service is unaffected by the new policies — behaviour is unchanged. The code is the
correct end state; it simply cannot *enforce* until the runtime role can be subject to it.

## The gap (confirmed against the live DB)

```
SELECT rolname, rolsuper, rolbypassrls FROM pg_roles WHERE rolname='loom';
loom | t | t
```

The workflow-service authenticates to Postgres as **`loom`, a superuser with `BYPASSRLS`**. Such a
role bypasses every policy even under `FORCE ROW LEVEL SECURITY`. The dispatch's integration test
proved the consequence: with no community context set, `workflow_instances` returned **2/2** seeded
rows instead of the required **0/2**, and the same leak crosses community boundaries. So the
isolation backstop provides **zero** protection as deployed.

This is two problems, not one:
1. The RLS backstop is inert (the thing Thread 1 set out to build does not actually guard anything).
2. Independently of RLS, a line-of-business service holding a **superuser** DB connection is an
   over-privilege weakness worth closing on its own.

## The acceptance test (lives in `test/`, gated on its precondition)

`postgres_rls_integration_test.dart` (326 lines) is the acceptance proof. It asserts, per tenant
table: no-context read → `isEmpty`; community-B context cannot see community-A rows → `isEmpty`;
in-context read returns the row; and the catalog row confirms `relrowsecurity` + `relforcerowsecurity`
+ `polname = 'community_isolation'`. Because it cannot pass under a role that bypasses RLS, it **skips
with a documented reason** when the connecting role has `rolsuper`/`rolbypassrls` — exactly the pattern
the PG integration tests already use to skip without `LOOM_POSTGRES_PASSWORD`. So the suite stays green
and the gap stays visible in the skip reason; the moment a non-bypassing role runs it, the test executes
and must pass. A skip here never means the assertions were dropped.

## What "done" looks like — DECISION NEEDED on the role model

Completion requires a least-privilege runtime role and rotating the deployed service onto it. Two
viable shapes, both ending at the same enforced state:

- **Two-role split (recommended).** Migrations/DDL run as an owner/admin role (`loom`); the service
  *runtime* connects as a new `loom_app` role created `NOSUPERUSER NOBYPASSRLS`, granted
  `SELECT/INSERT/UPDATE/DELETE` on the tenant tables + `USAGE` on their sequences. Needs a small code
  change so the service opens a migration connection (admin) distinct from its runtime pool
  (restricted). Cleanest least-privilege; the runtime role never holds DDL.
- **Owner-role.** A single `loom_app` (`NOSUPERUSER NOBYPASSRLS`) *owns* the tenant tables — it can
  then run the RLS migration (owners may `ALTER … FORCE RLS` / `CREATE POLICY`) **and** is itself
  subject to the policy (because `FORCE` binds even the owner, and `NOBYPASSRLS` blocks the escape).
  Simpler wiring (one connection), but the runtime role retains DDL power on its own tables.

Either way the last step is the sensitive one: **rotate the deployed workflow-service's DB
credentials** (new secret, deployment env, redeploy). That is an outward-facing change to a live
service and is why this is a decision, not an autonomous edit — a missing grant would break all DB
access at once.

### Acceptance
1. Restricted role provisioned; `pg_roles` shows `rolsuper=f, rolbypassrls=f` for it.
2. `postgres_rls_integration_test.dart` **executes and passes** (no longer skips) when run *as the
   restricted role* (0/2 without context, 0 cross-community, in-context read works). Report the **skip
   count** — the PG tests skip silently without creds, so a green run that skipped the RLS test proves
   nothing.
3. Deployed service connects as the restricted role; a real request against the live stack still
   serves (per CLAUDE.md: verify it still *serves*, not just that pods are `Running`).
4. Manifest/secret changes committed — a deploy is not done until the record is committed.

## Notes
- Related over-privilege to sweep while here: whether *other* services (`app-access`, `fan-passport`)
  also connect as `loom`. Same fix pattern if so.
- This ticket exists because the RLS *code* is already merged as inert defense-in-depth; the remaining
  work is infrastructure (a role + a credential rotation), not application logic.
