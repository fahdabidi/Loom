# Local In-App Backend

Use `LocalInAppBackend` to run the Demo App without a hosted backend.

## Extension Use

- Load the extension package summary before importing initialization data.
- Import initialization packages idempotently.
- Persist and reload local state from snapshots during validation.

## Validation

- `vt_fake-backend_import-init-package`, `vt_fake-backend_import-idempotent`, and `vt_local-store_persist-reload` prove local backend behavior.
