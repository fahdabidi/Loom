# Loom workflow service

Phase B.1 exposes the shared `loom_workflow_engine` over HTTP. Only
`applyTransition` is implemented; the other four OpenAPI operations return
explicit `501 Not Implemented` responses.

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
