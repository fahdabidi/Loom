# Phase 21 - API Review

## Scope Reviewed

Phase 21 adds the typed API and fake-backend foundation for fan-owned AI search and external content references:

- `ExternalContentSourceApi` with `searchExternalContent` and `getExternalContent`.
- `AiGatewayApi.runAiSearch` for bounded creator + external candidate merging.
- `FanVaultApi` search-agent config and external-source connection methods.
- Drift schema version 11 with `fan_search_agent_configs`, `external_source_connections`, `ai_search_runs`, and external-reference embed/source metadata.

## API Decisions

- The fake backend writes through `DemoLocalStore` and Drift/SQLite; tests use in-memory Drift only through the existing test dependency setup.
- External titles and thumbnails are stored as original source metadata and are never rewritten by AI search. AI wording is additive through `accurateMatchLabel`, `rankReason`, and `titleRiskSignals`.
- `SearchReceipt` is represented as an audit-only `ai_search_runs.receiptId`; it does not create economics, ads, boosts, or paid placement.
- YouTube is implemented first through `EmbedDescriptor(kind: youtubeIframe)`. Other source types are modeled as `link` so later phases can add UX without changing the API shape.
- `preferCreators` is a fan setting, not a monetization control. The fake ranks creator-owned matches ahead of external matches when the setting is enabled.

## Validation Evidence

- `dart run build_runner build` completed for `loom_local_store`.
- `dart analyze packages/core/loom_api_contracts packages/core/loom_fake_backend packages/core/loom_local_store packages/core/loom_app_shell apps/loom_demo` passed with no issues.
- From `apps/loom_demo`: `flutter test test/p21_ai_search_foundation_api_test.dart` passed 4/4.

## Follow-Up For Later Phases

- Phase 22 should expose the persisted search-agent and source-connection settings in Fan Settings.
- Phase 23 should route the discovery result UI through `AiGatewayApi.runAiSearch` only when the fan has connected an agent.
- Phase 24 should use the `EmbedDescriptor` without obscuring the official YouTube player.
