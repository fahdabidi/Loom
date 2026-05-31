# Phase 0 — API Conformance & Efficiency Review

## Scope reviewed

- `CreatorMetadataApi.getPublicCatalog(channelId, {cursor, limit})`
- `CreatorMetadataFake`
- `CreatorContentListScreen`

## Conformance findings

- **Contract boundary proven:** the fan content-list proof slice reads only through `CreatorMetadataApi`; the feature package does not import `loom_fake_backend`, `loom_local_store`, or another feature.
- **Response provenance:** every rendered field (`creatorDisplayName`, `title`, `summary`, `contentType`) is returned by `ContentSummaryView`.
- **Pagination:** the screen requests a bounded page (`limit: 3`) and loads the next page using `nextCursor`; it does not fetch all catalog content.
- **Minimal payload:** `ContentSummaryView` currently contains only fields the Phase 0 tile can render plus IDs needed for provenance and future navigation.
- **Error shape:** invalid limits and missing creators raise `ApiError`.

## Efficiency findings

- **No N+1:** initial catalog render is one API call; load-more is one additional API call.
- **Cursor semantics:** fake cursor is an index cursor. This is acceptable for Phase 0 seed data, but the real OpenAPI contract should clarify cursor opacity and ordering guarantees.
- **Simulated latency:** fake backend latency is centralized on the fake implementation.

## Residual notes

- Physical-phone validation is intentionally deferred to Phase 9. Phase 0 validation is complete when the Flutter Android emulator gates pass.
- `loom_local_store` now uses Drift/SQLite for app runs and an in-memory Drift database for test runs.
- `seedV1` constants are the authoritative generated seed representation for Phase 0; JSON files under `assets/seed/` are retained as human-readable seed mirrors until the seed loader is hardened.

## Proposed OpenAPI/spec notes

- Define `getPublicCatalog` cursor as opaque and stable for the selected ordering.
- Keep `ContentSummaryView.summary` required for all content returned by creator catalog endpoints.
- Preserve the minimal Phase 0 tile payload unless Phase 1/2 navigation needs additional fields.
