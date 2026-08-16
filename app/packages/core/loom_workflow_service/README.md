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

Production authenticates `Authorization: Bearer` tokens through
`JwtWorkflowIdentityExtractor`, using the configured Keycloak JWKS and exact
issuer before reading Loom's `fanId` claim. The `X-Loom-Fan-Id` adapter remains
available only as an isolated test seam behind `WorkflowIdentityExtractor`.

Run the service with the k3s PostgreSQL connection:

```bash
LOOM_POSTGRES_PASSWORD='<from loom/postgres-credentials>' \
LOOM_COMMUNITY_GROUP_IDS='{"community_book_club":"loom_communities_book-club"}' \
JWT_JWKS_URI='http://keycloak.loom.svc.cluster.local:8080/realms/loom/protocol/openid-connect/certs' \
JWT_ISSUER='http://keycloak.loom.svc.cluster.local:8080/realms/loom' \
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

## Deployment

`./build.sh` builds `loom-workflow-service:0.1.0` (requires the workspace
already bootstrapped, and Docker). See `Dockerfile` for why the build stages a
pre-resolved workspace rather than resolving inside Docker, and why the Dart
SDK version pinned there must match the host Dart SDK exactly.

Deployed to k3s via `deploy/k8s/workflow-service.yaml` in the `loom-backend`
repo, alongside the App Access/Fan Passport/Keycloak manifests. No health
endpoint exists yet, so that manifest deliberately has no readiness/liveness
probe -- Kubernetes considers the pod ready once the container starts.

`LOOM_COMMUNITY_GROUP_IDS` is deployed as an empty `{}` until a real community
completes `installCommunityPackage` against this cluster (Phase D implements
that endpoint; nothing calls it live yet) -- every community fails closed
(503) until real entries exist.
