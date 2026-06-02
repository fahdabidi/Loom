# Phase 21 — AI Search & External Content Foundation

**Surface:** core · **UX gate:** low (API/data foundation only) · **On green:** AUTO → Phase 22
**Shared conventions:** [README.md](./README.md).

> **Status:** Ready for execution after Phase 20. This phase begins the **Fan AI Search + External
> Content** sequence (Phases 21–26). It implements the typed contracts, Drift state, fakes, and seed for:
> a fan **AI search agent** connection (MCP, simulated), **AI Search** that merges creator + external
> candidates with agent ranking, a generic **External Content Source** provider (YouTube first;
> twitch/discord/blog/webpage modeled generically), and **embed descriptors**. It deliberately avoids
> building the search/settings/player UX so contract correctness, idempotency, neutrality, and provenance
> are proven before Phases 22–26 render them.
>
> Builds on the existing **bring-your-own-AI** precedent (Phase 5 summary-first agent) and the existing
> `ExternalContentReferenceSchema` / `PublicImportedReferences` table — reuse, don't reinvent.

## 0. Prerequisite gate (validate Phase 20 done)
README gate + confirm Phases 10–20 are committed/recorded; the launch loop, customization showcase, and
emulator UX hardening are green. Confirm the five gaming creators + `CreatorExperienceConfig` exist (Phase 15).

## 1. Workflows & user stories in this phase
Contract/data foundation for the new stories (added to
[../MVP User Stories Scope.md](../MVP%20User%20Stories%20Scope.md) Part L):
- **FE-S16 foundation** — fan **AI search agent** connection config (provider + MCP endpoint/token,
  simulated) and external-source connection state.
- **FE-S17 foundation** — **AI Search** that merges creator (preferred) + external candidates and applies
  agent ranking, with an **accurate-match annotation** and title-risk signals (external title never altered).
- **FE-S18 foundation** — external content **embed descriptor** (youtube_iframe vs link) for later playback.
- **CE-S14 foundation** — external content references usable as **feed** content (not just import).

No fan/creator screen beyond keeping the app bootable. Prove the APIs/fakes support Phases 22–26 without magic values.

## 2. Tools (WSL Ubuntu)
Standard set. After schema changes: `dart run build_runner build --delete-conflicting-outputs` in
`app/packages/core/loom_local_store`; `melos bootstrap` after new exports/deps. No network in this phase
(playback arrives in Phase 24).

## 2A. UX reference research & decision output
Low-UX phase, but create [Phase 21 - UX Decisions.md](./Phase%2021%20-%20UX%20Decisions.md) because the
schema choices shape Phases 22–26.

Review reference patterns only to extract **data requirements** and **compliance constraints**:
- MCP (Model Context Protocol) tool-server pattern: a fan connects their agent which calls Loom search tools and returns ranked results.
- YouTube/Twitch developer policies: title + thumbnail must stay **visible and unaltered**; official player must be used and unobscured; attribution kept. These constrain the result/annotation schema (annotation is additive; original title/thumbnail are mandatory fields).
- Neutral search: the **fan's agent** ranks; **no paid placement / no search ads**; SearchReceipt is audit-only.

Decision doc must record: which fields are persisted vs computed; how the agent ranking is represented without
enabling paid placement; how the accurate-match annotation stays additive (never replacing external title);
how external inclusion respects quotas/privacy; and which fields Phases 22–26 need.

## 3. APIs invoked & stubs to implement
Implement typed Dart clients/models matching the OpenAPI specs (one new spec is added in this phase's API work).

New / extended clients:
- **AI Gateway API (extend `runSearchAssistant`):** accept connected-agent context + source set; return a
  **merged ranked result set** (creator + external) with per-item `accurateMatchLabel`, `titleRiskSignals`,
  `rankReason`, and source attribution; emit AI-usage + source-attribution receipts.
- **External Content Source API (new, generic):** `searchExternalContent`, `getExternalContent` →
  `ExternalContentCandidate` with `embedDescriptor`. Source types: `youtube` (now), `twitch`/`discord`/
  `blog`/`webpage` (modeled, link-only for now).
- **Fan Vault API (extend):** `getSearchAgentConfig` / `putSearchAgentConfig` (mirror `putRankPreference`);
  external-source connection state (simulated OAuth/connected flags).
- **Search API (extend):** allow an **external target ref** in results and a merged/neutral result path;
  keep SearchReceipt audit-only.
- **Creator Metadata API (reuse/extend):** external content references usable as feed content + `embedDescriptor`.

Fakes: one per new/extended surface in `core/loom_fake_backend`; register in `apps/loom_demo/lib/main.dart`;
read/write `loom_local_store`; simulate latency/error/idempotency. The AI-search fake ranks deterministically
(creator-preferred default, then agent score) and **generates an accurate-match label without touching the
external title** — mirroring `ai_gateway_fake.dart` `rankBySummary` scoring.

## 4. Data storage (local store)
Add/extend Drift tables:
- `fan_search_agent_configs`: passportId, provider(enum: anthropic_claude|openai|google_gemini|custom), mcpEndpoint, connected, preferCreators(default true), externalSourcesEnabled, updatedAt.
- `external_source_connections`: passportId, sourceType, connected, displayName, updatedAt (simulated OAuth state).
- **Reuse** `public_imported_references` for external content (platform/externalId/title/summary/sourceUrl/
  thumbnailRef/rightsBasis/searchIndexable/aiQueryable); **add** `embed_kind` (youtube_iframe|link),
  `accurate_match_label` (nullable), `source_attribution`.
- `ai_search_runs` (optional, audit): query, agentProvider, resultRefs, receiptId — to back SearchReceipt + transparency.

Seed real **YouTube video IDs** as external content references attached to the five gaming creators
(NovaClutch, EmberHollow, FrameByFrame, DriftAndChill, IronVael) — `searchIndexable=true`, `embed_kind=youtube_iframe`.

## 5. Source files & components to create/update
API contracts (`core/loom_api_contracts/lib/clients/` + `models/`):
- `external_content_source_api.dart` + models `ExternalContentCandidate`, `EmbedDescriptor`, `ExternalTargetRef`.
- Extend `ai_gateway_api.dart` with `runAiSearch` (or extend the existing search-assistant method) → `AiSearchResult`
  with `items: List<AiSearchItem>` (creator|external, originalTitle, accurateMatchLabel, titleRiskSignals, rankReason, sourceAttribution, embedDescriptor?).
- Extend `fan_vault_api.dart` with `FanSearchAgentConfig` get/put.
- Extend `search_api.dart` result model for external targets.

Fakes/store: `external_content_source_fake.dart`; extend `ai_gateway_fake.dart`, `fan_vault_fake.dart`,
`search_fake.dart`; extend `loom_local_store` schema + generated Drift; extend `loom_seed_data` with YouTube refs.

No design-system component required beyond test fixtures.

## 6. API best-practice checks (phase-specific)
- AI-search merge is **deterministic + bounded**; one search action ⇒ bounded calls (no N+1 per result).
- Result schema **always carries the unaltered `originalTitle` + thumbnail** for external items; `accurateMatchLabel` is additive and nullable.
- Ranking carries a `rankReason`; **no field represents paid placement**; creator-preference is a fan flag, not a purchase.
- SearchReceipt is **audit/utility only** (no per-click monetization); AI-usage + source-attribution receipts emitted.
- External candidates respect `searchIndexable`; agent connection is simulated (no secrets persisted in plaintext beyond demo scope).

## 7. Component boundary / design checks
- `loom_api_contracts` stays pure contracts/models; `loom_fake_backend` imports contracts + store + seed only.
- Features do not import the new fakes/tables. `apps/loom_demo` is the only DI binding site.
- Update affected barrels + `CHARTER.md` only where scope changes.

## 8. Automated validation checks
README baseline plus unit tests: AI-search merge ordering (creator-preferred then agent score); accurate-match
annotation present while external `originalTitle` unchanged; external-source candidate mapping + embed descriptor;
agent-config get/put idempotency; SearchReceipt audit-only shape; Drift migration + `resetDemo()` clearing mutable
search/agent state while restoring seed YouTube refs.

## 9. Integration tests
- `it_p21_ai_search_foundation_smoke` — app boots with new fakes; put a (simulated) agent config; run AI search;
  receive a merged creator+external result set with unaltered external titles + accurate-match labels + a SearchReceipt — without a Phase 22–26 UI.
- `it_p21_reset_search_state` — after creating agent config + search runs, `resetDemo()` clears mutable state and restores seed external refs.

## 10. Definition of done
All Phase 21 clients, models, Drift tables, fakes, DI registrations, seed (YouTube refs on the five gaming
creators), and tests complete; app still boots on the emulator; no search/settings/player UX yet. `melos bootstrap`,
Drift gen, `melos run analyze`, `lint:boundaries`, `test`, focused Phase 21 integration tests, full suite, APK build,
emulator install, and launch are green. [Phase 21 - API Review.md](./Phase%2021%20-%20API%20Review.md) and
[Phase 21 - UX Decisions.md](./Phase%2021%20-%20UX%20Decisions.md) filed; new `external-content-source-api` OpenAPI
spec added + registered in the inventory and lint-clean. Update the tracker in
[../Demo App Implementation Plan.md](../Demo%20App%20Implementation%20Plan.md) with status, date, API review,
gate evidence, and commit SHA.

## 11. Next phase
After Phase 21 changes are committed and recorded, **AUTO-PROCEED: immediately begin
[Phase 22 — Fan AI Search Settings & Source Connections](./Phase%2022%20-%20Fan%20AI%20Search%20Settings.md).**
