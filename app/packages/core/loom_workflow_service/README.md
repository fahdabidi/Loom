# Loom workflow service

Phase B.2 exposes the shared `loom_workflow_engine` over HTTP for definition
replacement, visibility-filtered instance queries, available-transition
resolution, and transition application. `createInstance` remains an explicit
`501 Not Implemented` response until Phase B.3 supplies App Access permission
resolution.

The temporary `X-Loom-Fan-Id` adapter is isolated behind
`WorkflowIdentityExtractor`. It is a pre-auth test seam, not a production auth
protocol. Phase C replaces that implementation with JWT validation without
changing the service or engine boundary.

Run the service with the k3s PostgreSQL connection:

```bash
LOOM_POSTGRES_PASSWORD='<from loom/postgres-credentials>' \
  dart run bin/loom_workflow_service.dart
```

The PostgreSQL integration test defaults to the local k3s port-forward at
`127.0.0.1:15432` and creates then drops its own unique schema.
