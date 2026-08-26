# Instance-column migration and unexpected-500 logging — status

Status: complete.

The creator-column migration was exercised against **real PostgreSQL through
the local port-forward**, in a fresh isolated schema. It was not verified only
against SQLite. Persistent SQLite also has direct regression coverage.

## Red → green evidence

### Creator-column migration

| Regression | Before implementation | After implementation |
| --- | --- | --- |
| Persistent SQLite legacy upgrade, idempotency, and both-columns guard | **0/3 passed, 3/3 failed.** The legacy insert failed because `created_by_fan_id` did not exist; the ambiguous two-column table was accepted. | **3/3 passed.** The legacy row retains `legacy-fan`, the physical column is `created_by_fan_id`, repeat opening is a no-op, and both columns cause startup failure. |
| Real PostgreSQL legacy upgrade | **0/1 passed, 1/1 failed.** Pre-fix source failed with PostgreSQL SQLSTATE `42703`: `created_by_fan_id` did not exist. | **1/1 passed.** The isolated-schema test pre-created the legacy table and row, opened `WorkflowDatabase`, inserted and read a new row, asserted the physical rename, and verified the old row still holds `legacy-fan`. |

The PostgreSQL red run used a temporary detached worktree at the repository
baseline and was removed after the check. Neither the production database nor
an existing `workflow_instances` table was altered by the test; each run used
and dropped its own schema.

### Unexpected-500 logging

| Regression | Before terminal logging | After implementation |
| --- | --- | --- |
| Forced SQLite database exception during `POST /v1/communities/{id}/instances` | **0/1 passed, 1/1 failed.** The injected log sink remained empty. | **1/1 passed.** Exactly one JSON log record includes the correlation id, `POST`, request path, error runtime type, error text, and stack trace. The response remains the identical generic `500 workflow_service_error` body and correlation id. Authorization-header and instance-data sentinels are absent from the record. |

## Implementation

- `WorkflowDatabase._migrate` now inspects active-dialect schema metadata after
  `workflow_instances` is ensured. It renames only the legacy-only column with
  `ALTER TABLE ... RENAME COLUMN`, making the upgrade safe for repeat runs and
  fresh databases.
- SQLite uses `PRAGMA table_info`; PostgreSQL uses `information_schema.columns`
  for the current schema.
- If both creator columns exist, startup fails with a diagnostic instead of
  choosing a source column.
- Each terminal unexpected-500 branch records one structured JSON line to
  stderr by default. Unclassified `StateError` 500 paths are logged before the
  generic response is returned. Logs contain no headers or request bodies.

## Verification totals

| Suite / command | Result |
| --- | --- |
| Focused persistent-SQLite migration suite | **3/3 passed** |
| Focused real-PostgreSQL migration suite | **1/1 passed** |
| Focused unexpected-database-error logging suite | **1/1 passed** |
| `app/packages/core/loom_workflow_engine: flutter test` | **287 passed + 4 skipped = 291 total**. The previous 284 passed + 3 skipped baseline grows by the 3 SQLite migration tests and 1 credential-gated PostgreSQL migration test. |
| `app/packages/core/loom_workflow_service: flutter test` | **54 passed + 5 skipped = 59 total**. The previous 53 passed baseline grows by the 1 logging regression. |
| `app/packages/tooling/loom_app_access_provisioning: flutter test` | **15/15 passed** |
| `app/packages/core/loom_communities_app_shell: flutter test` | **273/273 passed** |
| `app/packages/tooling/loom_ux_judges: flutter test` | **432/432 passed** |
| `app/apps/loom_communities_demo: flutter test` | **160/160 passed** |

No requested verification was left undone. No file under `docs/references/` or
any community JSON file was modified.
