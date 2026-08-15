# Loom workflow service

The service exposes the shared `loom_workflow_engine` over HTTP for definition
replacement, visibility-filtered instance queries, App Access-authorized
instance creation, available-transition resolution, and transition
application. Instance creation derives `<archetype_snake_case>.create` with the
engine's shared `ArchetypeResolver` and calls App Access's live
`POST /v1/access-decisions` operation before inserting anything.

Canonical community ids and community handles are separate identifiers. The
service therefore requires an explicit JSON object mapping canonical ids to
the App Access group ids created from handles; it never guesses that mapping.

The temporary `X-Loom-Fan-Id` adapter is isolated behind
`WorkflowIdentityExtractor`. It is a pre-auth test seam, not a production auth
protocol. Phase C replaces that implementation with JWT validation without
changing the service or engine boundary.

Run the service with the k3s PostgreSQL connection:

```bash
LOOM_POSTGRES_PASSWORD='<from loom/postgres-credentials>' \
LOOM_COMMUNITY_GROUP_IDS='{"community_book_club":"loom_communities_book-club"}' \
  dart run bin/loom_workflow_service.dart
```

`LOOM_APP_ACCESS_BASE_URL` defaults to the in-cluster
`http://app-access.loom.svc.cluster.local:8080`. Override it with the local
App Access port-forward URL when running the live integration test.

The PostgreSQL integration tests default to the local k3s port-forward at
`127.0.0.1:15432` and create then drop their own unique schemas. The B.3 test
also requires `LOOM_APP_ACCESS_BASE_URL`; it creates a unique App Access group,
role, and membership through the real HTTP API, then starts the workflow Shelf
server on a real loopback port and proves both the allow and deny directions.
