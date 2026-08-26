# `createInstance` HTTP 500: root-cause diagnosis

## Outcome

Confident root-cause diagnosis. The deployed PostgreSQL schema was not migrated when the persisted creator column was renamed from `created_by_persona_id` to `created_by_fan_id`. The current engine inserts into the new column, but the live `workflow_instances` table still exposes only the legacy column. PostgreSQL rejects the insert before it can persist the instance.

The exact exception produced through the repository's current `WorkflowDatabase` + `drift_postgres` path against the live `loom_workflow_service` database is:

```text
Severity.error 42703: column "created_by_fan_id" of relation "workflow_instances" does not exist
```

Its runtime type is `ServerException` (`package:postgres`). The relevant captured stack frame is:

```text
#11 WorkflowDatabase.insertInstance (package:loom_workflow_engine/src/store/database.dart:239:15)
```

The diagnostic used a schema guard that would run the insert only while `created_by_persona_id` existed and `created_by_fan_id` did not. PostgreSQL rejected the statement during preparation, and a subsequent read confirmed that the diagnostic instance count was zero.

## Precise failure mechanism

1. `WorkflowService._createInstance` reaches `workflow_service.dart:418-423` after definition lookup and App Access authorization succeed.
2. `LocalWorkflowEngineApi._createInstanceValidated` calls `_db.insertInstance` at `local_workflow_engine_api.dart:1314-1321`.
3. `WorkflowDatabase.insertInstance` calls `_db.runCustom` at `database.dart:239`. Its PostgreSQL SQL, assembled at `database.dart:245-248`, names `created_by_fan_id` in the insert column list.
4. The live `public.workflow_instances` table has this final column instead:

   ```text
   created_by_persona_id | text | not null
   ```

   It has no `created_by_fan_id` column. PostgreSQL therefore raises SQLSTATE `42703` at statement preparation. This is the exception that becomes the reported HTTP 500.

The deployed `/app/workflow_service` binary contains `created_by_fan_id`, confirming that this is not merely a source-versus-image discrepancy.

## Why the in-memory database succeeds

`WorkflowDatabase.memory()` creates a new SQLite database. On first use, `_migrate()` creates `workflow_instances` from the current declaration at `database.dart:100-109`, which already contains `created_by_fan_id`. There is no legacy table to upgrade, so the insert succeeds.

The deployed PostgreSQL database is persistent and predates the identity-vocabulary rename. Commit `7449587a` changed the table declaration, inserts, fan queries, and row decoding from `created_by_persona_id` to `created_by_fan_id`, but did not add a forward schema migration. `_migrate()` issues only `CREATE TABLE IF NOT EXISTS` and `CREATE INDEX IF NOT EXISTS`. For an existing table, those statements do not reconcile or rename columns, so every service restart preserves the stale schema. This is a missing migration, not an engine-validation, JSON/type-mapping, or authorization defect.

The existing PostgreSQL integration tests create a fresh temporary schema. They exercise only the current table declaration and therefore cannot expose an upgrade failure from the legacy schema.

## Why `kubectl logs` is empty

The `ServerException` is caught by the terminal branch at `workflow_service.dart:483-489`:

```dart
} catch (_) {
  return _error(/* generic 500 */);
}
```

That branch discards both the exception object and its stack trace. `ServerException` does not match any preceding typed branch (`AppAccessDecisionException`, `SocketException`, `WorkflowValidationError`, or `StateError`), so this terminal catch is the exact catch boundary used here.

`_error` at `workflow_service.dart:1454-1474` only constructs the JSON response; it performs no logging. The process entry point passes `service.handler` directly to `shelf_io.serve` at `bin/loom_workflow_service.dart:67-70`, with no request-logging or error-logging middleware. Consequently the handled 500 writes neither an exception/stack trace nor a request line to stdout or stderr. The correlation ID survives only in the response.

## Minimal correct fix

Two changes are required; the HTTP status and generic client-facing error should remain unchanged.

1. Add a forward, idempotent schema migration in `WorkflowDatabase._migrate`, after ensuring `workflow_instances` exists and before any instance read or write. Detect the legacy/new columns for the active dialect. When `created_by_persona_id` exists and `created_by_fan_id` does not, rename the legacy column to `created_by_fan_id`. PostgreSQL's effective migration is:

   ```sql
   ALTER TABLE workflow_instances
     RENAME COLUMN created_by_persona_id TO created_by_fan_id;
   ```

   Guard the rename via schema metadata or a versioned migration so it is safe on both already-upgraded and freshly-created databases. Apply the same logical upgrade to persistent SQLite databases, because they use the same schema declaration and can also predate the rename. If both old and new columns are present, fail startup with a diagnostic instead of silently choosing one. The rollout must run this migration against the existing `loom_workflow_service` database; changing only `CREATE TABLE IF NOT EXISTS` is insufficient.

2. Preserve the existing catches and response mappings, but log every unexpected 500 at the catch boundary. Change the terminal branch to `catch (error, stackTrace)` and emit one structured stderr record containing at least the correlation ID, HTTP method, request path, error runtime type, `error.toString()`, and stack trace. Do the same before the unclassified `StateError` branch returns its 500. Do not include authorization headers, JWTs, request bodies, instance data, or database credentials. Add request logging around the Shelf handler if request-line visibility is desired, but do not rely on request middleware alone for the exception: this exception is already converted into a normal `Response`, so only the catch boundary still has the error and stack trace.

Regression coverage should pre-create the legacy `workflow_instances` schema in PostgreSQL, open the current `WorkflowDatabase`, create and read an instance, and assert that the physical column was renamed without losing its value. A separate service test should force an unexpected database exception, capture the logger, and assert that the correlation ID, exception, and stack are recorded while the client still receives the same generic `500 workflow_service_error` body.
