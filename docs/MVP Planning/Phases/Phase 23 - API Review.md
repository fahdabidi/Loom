# Phase 23 - API Review

## Scope Reviewed

Phase 23 consumes existing Phase 21 contracts and adds no new API surface:

- `FanVaultApi.getSearchAgentConfig`
- `AiGatewayApi.runAiSearch`
- `SearchApi.search`

## API Decisions

- `DiscoveryController.search()` first reads the fan's search-agent config through `FanVaultApi`. Connected agents route to `AiGatewayApi.runAiSearch`; disconnected agents keep the Phase 3 neutral `SearchApi.search` path.
- The UI stores the AI run response as `AiSearchResult` rather than flattening it into neutral `SearchResult`, preserving `searchReceiptId`, `neutralityLabel`, item `type`, `rankReason`, `sourceAttribution`, and external `embedDescriptor`.
- No N+1 calls were introduced in the UI. A search action makes one config read and one search call; the fake backend performs the creator/external merge server-side over the local store.
- External titles and thumbnails are displayed from `AiSearchItem.originalTitle` / `thumbnailRef`; `accurateMatchLabel` is additive and never replaces the original title.
- The search receipt remains audit-only. It is surfaced as a receipt label but does not unlock ranking, placement, or monetized treatment.

## Validation Evidence

- Focused tests added in `apps/loom_demo/test/p23_ai_search_results_test.dart`.
- Integration smokes added in `apps/loom_demo/integration_test/it_p23_ai_search_results.dart`.

## Follow-Up For Later Phases

- Phase 24 should use `AiSearchItem.embedDescriptor` for YouTube iframe playback and keep the Phase 23 tile presentation intact.
- Phase 25 should reuse the same external-reference model when Creator Studio links external content into feeds.
