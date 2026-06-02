# Phase 23 — AI Search Results: Creator + External, Agent Ranking, Title Normalization

**Surface:** Fan App · **UX gate:** HIGH · **On green:** AUTO → Phase 24
**Shared conventions:** [README.md](./README.md).

> **Status:** Ready for execution after Phase 22. When a fan has connected an AI search agent, search routes
> through **AI Search**: it merges **creator (preferred) + external (YouTube)** results, the agent determines
> final ranking, and ragebait is handled **compliantly** — creator content shows summary-over-clickbait, while
> external content keeps its **unaltered title + thumbnail** and leads the tile with an AI **accurate-match**
> label. Neutrality is preserved (the fan's agent ranks; no paid placement). Builds on the existing search +
> summary-first patterns.

## 0. Prerequisite gate (validate Phase 22 done)
README gate + confirm Phase 22 committed/recorded: a fan can connect an agent + enable external sources +
set prefer-creators; settings persist; Phase 22 integration tests pass.

## 1. Workflows & user stories in this phase
- **FE-S17 / AI search merges creator + external** — With an agent connected, a query returns a single ranked
  list merging creator content (preferred on match) and external (YouTube) results.
- **FE-S17 / agent ranking, disclosed** — The agent determines ordering; the result surface discloses "ranked by
  your agent," shows a per-item "why ranked / source," and carries **no paid placement** (neutrality preserved).
- **FE-S17 / compliant title normalization** — Creator tiles show summary instead of clickbait; **external tiles
  keep the unaltered original title + thumbnail**, lead with an AI **accurate-match** label, and show a
  **source-attribution chip** (e.g., "YouTube"). Native tile styling, no heavy platform chrome in the list.
- Fallback: with no agent connected, search uses the existing neutral search (Phase 3) unchanged.

## 2. Tools (WSL Ubuntu)
Standard set. Emulator screenshots of a merged result list (creator + external tiles) with the accurate-match label + source chip.

## 2A. UX reference research & decision output
Record in [Phase 23 - UX Decisions.md](./Phase%2023%20-%20UX%20Decisions.md):
- Multi-source search result lists (mixed native + external) with clear source attribution.
- "Ranked by your AI" disclosure patterns; per-result why/source affordances (reuse the Phase 3 "Why" sheet).
- Compliant external-content presentation: original title visible, additive descriptive label, unaltered thumbnail.

Apply the shared baseline plus: creator vs external tiles are visually distinct but consistent; the accurate-match
label is clearly the AI's phrasing (not presented as the platform's title); the original external title remains
visible (secondary) for attribution; neutrality label persists ("no ads, boosts, or paid placement").

## 3. APIs invoked & stubs to implement
No new API surfaces. Reuse Phase 21:
- **AI Gateway API:** `runAiSearch` — input: query + connected-agent config + enabled sources + prefer-creators;
  output: merged ranked `AiSearchItem[]` (creator|external) with `originalTitle`, `accurateMatchLabel`,
  `titleRiskSignals`, `rankReason`, `sourceAttribution`, optional `embedDescriptor`; emits AI-usage + SearchReceipt.
- **Search API / External Content Source API:** candidate retrieval feeding the merge.
- **Fan Vault API:** read the agent config + prefer-creators.

## 4. Data storage (local store)
No new tables. Reads agent config + external refs from Phase 21; AI-search runs optionally logged for transparency/receipts. Confirm `resetDemo()` clears run logs.

## 5. Source files & components to create/update
- `features/fan/feature_discovery`: route `search()` through `AiGatewayApi.runAiSearch` when an agent is connected
  (else existing `SearchApi.search`); add merged-result state + disclosure.
- Design system: `search/ai_result_tile.dart` (creator + external variants; accurate-match label, original title secondary,
  source chip), `search/ai_rank_disclosure.dart` ("ranked by your agent" + neutrality), reuse the Phase 3 "Why" sheet for per-item rank/source explanation.

## 6. API best-practice checks (phase-specific)
- One search action ⇒ bounded calls; merge is server-side (fake) not N+1 per item.
- External items **always** render the unaltered `originalTitle` + thumbnail; `accurateMatchLabel` is additive (compliance).
- Ranking exposes `rankReason`; prefer-creators is a fan default, **never** a paid boost; SearchReceipt audit-only.
- Source attribution present on every external item; no implication of Loom ownership.

## 7. Component boundary / design checks
- Result tiles/disclosure in `loom_design_system`; merge/route logic in `feature_discovery`.
- No feature→feature/fake/store imports; `lint:boundaries` clean; charter updated.

## 8. Automated validation checks
README baseline plus unit/widget tests: merge orders creator-before-external on equal match (prefer-creators);
agent score reorders within policy; external tile keeps original title (assert unchanged) + shows accurate-match
label + source chip; no-agent fallback uses neutral search; SearchReceipt audit-only.

## 9. Integration tests
- `it_p23_ai_search_merge` — With agent connected, a query returns merged creator+external results; creator preferred on match; disclosure shown.
- `it_p23_external_title_compliance` — External result renders the unaltered original title + thumbnail + source chip, with the AI accurate-match label as an additive lead.
- `it_p23_no_agent_fallback` — With no agent, search uses the existing neutral path unchanged.

## 10. Definition of done
AI search merges creator (preferred) + external with agent ranking and compliant title handling; external titles/
thumbnails are unaltered with additive accurate-match labels + source chips; neutrality preserved; no-agent
fallback intact; all checks + integration tests green; screenshots captured.
[Phase 23 - API Review.md](./Phase%2023%20-%20API%20Review.md) and
[Phase 23 - UX Decisions.md](./Phase%2023%20-%20UX%20Decisions.md) filed; tracker updated with status, date,
API review, gate evidence, and commit SHA.

## 11. Next phase
After Phase 23 changes are committed and recorded, **AUTO-PROCEED: immediately begin
[Phase 24 — Embedded Player & AI-Driven Next](./Phase%2024%20-%20Embedded%20Player%20and%20AI-Driven%20Next.md).**
