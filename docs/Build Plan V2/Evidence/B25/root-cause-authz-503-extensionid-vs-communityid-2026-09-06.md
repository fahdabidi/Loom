# Root cause: intermittent `authorization_service_unavailable` (503) — app vs curl

**Found:** 2026-09-06, via the Muse-based Root Cause Agent (`data/call_root_cause_agent.sh`,
model `muse-spark-1.3`, reasoning effort `xhigh`) — its first real dispatch since the Codex→Muse
migration. Investigation only; no code was modified.

**Status: root cause confirmed with live proof. Not yet fixed.**

## The claim, and why it's airtight

The app and curl were never sending the same request. The Flutter app puts the package
**extension id** (`ext_*`) in the workflow-service URL path where the server expects the
canonical **community id** (`community_*`). The server's community→group map is keyed exclusively
by canonical ids, so every app-originated workflow call resolves to "no group" and returns 503
`authorization_service_unavailable`. Curl reproductions this session used the canonical id (taken
from the spec/package docs), so they returned 200. Same host, same token, same headers — only the
path segment differed.

## Live proof (same JWT, same backend, seconds apart)

```
GET http://192.168.56.10:30083/v1/communities/community_neighborhood_book_club/instances?limit=5
  -> HTTP 200  {"items":[],"pageInfo":{"hasMore":false,"nextCursor":null}}

GET http://192.168.56.10:30083/v1/communities/ext_neighborhood_book_club/instances?limit=5
  -> HTTP 503  {"code":"authorization_service_unavailable",
                "message":"Workflow creation authorization is unavailable.",...}
```

A single sequential curl with the extension id reproduces the exact app symptom. Concurrency,
connection pooling, and token-refresh races are not needed to explain anything.

## Mechanism, end to end

**Client side — the app sends `ext_*` as the URL community id:**

1. `app/apps/loom_communities_demo/lib/main.dart:241-242` installs each community experience under
   `community.extensionId` (the `ext_*` value; shipped packages carry both fields, e.g.
   `communityId: "community_neighborhood_book_club"` alongside
   `extensionId: "ext_neighborhood_book_club"`, loaded into distinct fields by
   `app/packages/core/loom_demo_local_backend/lib/loom_demo_local_backend.dart:208-226`).
2. `app/packages/core/loom_communities_app_shell/lib/src/part25_engine_native_community_store.dart:237-240`
   invokes the engine factory with that `extensionId`.
3. `.../part37_remote_auth_session.dart:405-409`
   (`createRemoteEngineNativeCommunityEngineFactory`) passes it straight through as
   `RemoteWorkflowEngineApi(communityId: extensionId)`.
4. `app/packages/core/loom_workflow_engine/lib/src/api/remote_workflow_engine_api.dart:352-357,377-384`
   builds `v1/communities/<ext_*>/instances` with an otherwise-correct request (valid
   `Authorization: Bearer`, valid `X-Loom-Correlation-Id` UUID). Request *shape* is fine — the
   path id is the only wrong byte.

**Server side — `ext_*` matches nothing, and "no group" is reported as 503:**

5. `app/packages/core/loom_workflow_service/lib/src/workflow_service.dart:3657-3661`
   (`_resolveRolesForRequest`, used by every read: query, aggregate, available-transitions,
   due-notifications, documents, export, item-queue) does `resolveGroupId("ext_...")`, gets null,
   and returns `_authorizationServiceUnavailable` (defined at `:3768-3773`) → 503. The same
   null-group → 503 pattern exists at six more sites (`:555-565`, `:749-759`, `:1870-1873`,
   `:3356-3359`, `:3432-3435`, `:3709-3712`).
6. `app/packages/core/loom_workflow_service/lib/src/community_group_id_resolver.dart:51-52`
   (`MapCommunityGroupIdResolver`) is an exact-match lookup, and its map — both the live
   `workflow-service-config/community-group-ids` secret (verified: all 11 keys are `community_*`)
   and the app's own mirror in `part40_service_environments.dart:84-99` — is keyed exclusively by
   canonical `community_*` ids. Everyone agrees on the key space except the engine path.

## Why the earlier ruled-out candidates stayed ruled out

- **Token freshness/expiry, stale-vs-fresh races: cannot produce this 503.**
  `jwt_identity_extractor.dart:38-84` returns null for any bad token, and every handler maps that
  to **401**, never 503. A wrong fan yields 403/empty, not 503.
- **Concurrency / pool exhaustion: not needed.** The live A/B above is sequential and
  deterministic.
- **Backend health / node load: consistent with the finding** — a config-level id mismatch 503s on
  an idle node with all pods green, and survives pod restarts, exactly as observed this session.
- **On "intermittent":** the mechanism is deterministic per endpoint, not flaky — every
  workflow-service read with an `ext_*` id 503s, while login, community listing, and direct
  app-access/fan-passport calls (which correctly use the canonical id) succeed. From the device
  this reads as "some authenticated calls work, workflow calls mostly fail." Writes with `ext_*`
  should 404 `workflow_type_not_found` via the definitions check at `:529-539` — a different
  symptom worth knowing when reading future reports.

## Recommended fix

Translate extension id → canonical community id on the client before it reaches
`RemoteWorkflowEngineApi`, so the URL carries what the server maps:

- **Preferred:** at engine-factory invocation, resolve the canonical id (the `LocalInAppBackend`
  registry already holds both per community) and pass *that* as the engine `communityId`. Note the
  local engine namespaces by `extensionId` (`part25:141`), while server data is namespaced by
  canonical id — the remote factory must use the canonical form.
- **Do NOT** fix this server-side by adding `ext_*` keys to the group map alone: definitions and
  stored rows are keyed by canonical id, so that would turn the 503 into 200-with-empty-data /
  404s rather than real data.
- **Follow-ups worth filing alongside:** (a) the server should return 404 (or a distinct code)
  rather than 503 for an unmapped community — the misleading code is what made this look like an
  authz outage; (b) a regression test asserting a request with an unmapped community id does not
  return `authorization_service_unavailable` once the client contract is fixed, and a client test
  asserting the engine URL contains the canonical id.

## Evidence gaps (none blocking)

No app-side capture was needed — server behavior was proven with curl against the deployed
service. No server-log examination was possible (the service logs no per-request lines at current
level, and no failure timestamp was supplied), but it was also unnecessary — the code path plus
the live A/B is conclusive. No emulator was reachable from the VM sandbox this ran in, and none was
required.

## Tooling note

This was the first production dispatch through the newly Muse-migrated
`call_root_cause_agent.sh` (model `muse-spark-1.3`, `--reasoning-effort xhigh`, `--yolo`). It took
~8 minutes end to end, dominated by occasional Meta-provider rate-limit retries (HTTP 429,
resolved automatically after 5s) visible in
`~/.local/share/muse/local-tracing/bootstrap/cli-*.log` — those retries print misleading repeated
`muse: retrying meta model stream in 5000ms (attempt 2/10)` lines to stdout that look identical
whether progress is happening or not; the actual evidence of liveness was the growing
`session.jsonl` and the bootstrap log's `provider_stream.terminal ... outcome="success"` lines
between retries. A completion-watcher (`watch_dispatch_log.sh`) run against this script's real
output path failed with "log not found" because `call_root_cause_agent.sh` writes to a
self-deleting `mktemp` file, not `.codex-logs/<label>_dispatch.out.log` — that convention is
`call_implementation_agent.sh`-specific and does not apply here. Not yet fixed in the script.
