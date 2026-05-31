# Phase 3 — Discovery Core

**Surface:** Fan App · **UX gate:** MAJOR · **On green:** STOP for manual UX validation
**Shared conventions:** [README.md](./README.md). This is the largest, highest-API-risk phase.

## 0. Prerequisite gate (validate Phase 2 done)
README gate + confirm: the demo creator has **live published content with summaries** and a `CreatorAdPolicy` (Phase 2), the seed world has surrounding creators/content, fan interest profile exists (Phase 1). Discovery consumes this; do not start without live + seeded content.

## 1. Workflows & user stories in this phase
- **FE-S9A / RE-S3A** — Startup content tiles (PlatformIntent × FanInterestProfile).
- **FE-S9 / RE-W3** — Trusted recommendation feed (glass-box, why-shown).
- **RE-W3A** — Startup tile selection + mid-session intent switch.
- **FE-S9B / RE-S8** — Like/dislike/mute/block feedback shaping the profile.
- **RE-S9** — Summary-first ranking hook (BYO-agent preference flag; AI wiring lands Phase 5, the flag/scoring path here).
- **RE-S7 / RE-W7** — Host trending statistics consumed for Entertainment/Trending intents.
- **FE-S5 / FE-W5** — Search as an intent (neutral, no ads in results).

## 2. Tools (WSL Ubuntu)
Standard set. Add seed for platform-intent registry + external-provider candidates + a small search index projection.

## 2A. UX reference research & decision output
Before implementing discovery UX, review reference mockups and design guidance from popular social/video apps such as YouTube, Instagram, TikTok, Facebook, WhatsApp Channels, and adjacent recommendation/search products. Focus on feed cards, why-shown explanations, interest/intention entry points, ranking transparency, feedback affordances, search-as-intent, pagination/load-more patterns, and disclosure without overwhelming the feed.

Create [Phase 3 - UX Decisions.md](./Phase%203%20-%20UX%20Decisions.md) summarizing references reviewed, UX patterns extracted, key UX and implementation decisions, and a walkthrough of how the implemented discovery UX demonstrates startup tiles, session intent, glass-box feed, feedback, mid-session switching, trending, and neutral search using the collected guidance.

## 3. APIs invoked & stubs to implement
- **Recommendation & Referral API:** `getStartupTiles`, `createSessionIntent`, `switchSessionIntent`, `getFeed` (returns a **ranked page WITH `ContentScoreExplanation` per item**), `submitFeedback` (batched). Fake: `RecommendationReferralFake` (ranking respects intent blend, interest profile, dislikes, trending, summary weighting).
- **External Recommendation Provider API:** `getCandidates` (quota- + privacy-bounded). Fake: `ExternalRecommendationProviderFake`.
- **Content Host API:** `getTrendingStats` (aggregate velocity/novelty). Extend `ContentHostFake`.
- **Search API:** `search` (neutral, paginated, **no ad fields**). Fake: `SearchFake`.
- **Fan Vault API:** feedback updates interest/dislike state (reuse `FanVaultFake`).

## 4. Data storage (local store)
New tables: `platform_intents` (seed), `session_intents(platformIntentId, interestTokens[], dislikeFilters[], blend, adPosture)`, `fan_feedback(contentId, action)`, `external_provider_candidates` (seed), `search_index` (projection over content). Extend `content_perf` for trending. Feedback writes update `fan_interest_profile`.

## 5. Source files & components to create/update
- `core/loom_api_contracts/clients/`: fill `recommendation_referral_api.dart`, `external_recommendation_provider_api.dart`, `search_api.dart`; extend `content_host_api.dart`. Models: `PlatformIntent`, `ContentTile`, `SessionIntent`, `SessionIntentDisclosure`, `FeedItem`, `ContentScoreExplanation`, `FeedbackEvent`, `SearchResult`.
- `core/loom_fake_backend/`: `recommendation_referral_fake.dart`, `external_recommendation_provider_fake.dart`, `search_fake.dart`; extend `content_host_fake.dart`. Implement a deterministic scoring function with explanation output.
- `core/loom_design_system/components/`: `content_tile.dart` (finalize), `session_intent_disclosure_card.dart`, `feed_card.dart` (title + summary + why-shown + disclosure), `score_explanation_sheet.dart`, `feedback_bar.dart` (like/dislike/mute/block).
- `features/fan/feature_discovery/`: screens `tile_launcher`, `feed`, `search`; `session_intent_controller`, `feed_notifier` (paginated), `feedback_notifier` (debounced); mappers; `CHARTER.md`.

## 6. API best-practice checks (phase-specific — CRITICAL)
- **No N+1:** one `getFeed` call returns the ranked page **plus** each item's `ContentScoreExplanation` and disclosure — **no per-item follow-up calls**. This is the headline check.
- **Pagination:** `getFeed` and `search` use cursor + limit; infinite scroll requests pages.
- **Session intent as context:** intent is created once and passed/echoed; not re-fetched on every scroll.
- **Feedback batching + debounce:** rapid like/dislike actions coalesce into batched, idempotent `submitFeedback` calls.
- **External candidates:** fetched within the intent's quota in the feed assembly (one bounded call), labeled.
- **Minimal payload:** `ContentScoreExplanation` is compact (top factors only); no raw private signals leave the vault; search results contain no ad fields.

## 7. Component boundary / design checks
- `feature_discovery` imports only contracts + design_system + app_shell.
- Scoring logic lives in `loom_fake_backend` (server side), **not** in the feature — the feature only renders responses. Verify no ranking logic leaked into UI.
- `melos run lint:boundaries` clean.

## 8. Automated validation checks
README baseline. Unit tests: scoring/explanation determinism, dislike suppression, intent-blend quotas, feedback batching/debounce, search neutrality (no ad fields).

## 9. Integration tests
- `it_p3_tiles_session_intent` — launch → tiles from intents×interests → select → `SessionIntent` + disclosure shown.
- `it_p3_feed_ranked` — feed renders one page with per-item why-shown; load-more fetches page 2; **assert no per-item network calls**.
- `it_p3_feedback` — dislike an item/creator → suppressed on next fetch; profile updated in vault.
- `it_p3_mid_session_switch` — switch intent → re-rank from new policy; disclosure updates.
- `it_p3_search_no_ads` — search returns neutral results, zero ad fields, paginated.

## 10. Definition of done
Tiles → session intent → glass-box feed with why-shown, feedback, mid-session switch, trending-backed Entertainment intent, and neutral search all work on the Flutter Android emulator; feed is single-call + paginated; all checks green; API Review filed (esp. the N+1/batching/payload findings); UX Decisions doc filed. Update the Phase completion tracker in [../Demo App Implementation Plan.md](../Demo%20App%20Implementation%20Plan.md) with Phase 3 status, completion date, API review link/name, and gate evidence before marking this phase complete. Commit all Phase 3 changes to git and record the commit SHA in the tracker before proceeding.

## 11. Next phase
**STOP for manual UX validation (MAJOR).** Discovery UX dictates candidate **batching**, **pagination**, and **score-explanation payload** shape — the most consequential API decisions in the app. Get human sign-off on: tile design, disclosure card, feed card (summary + why-shown), feedback affordances, intent switching, search. After sign-off, proceed to [Phase 4 — Channel, Follow, Playback & Ads](./Phase%204%20-%20Channel%20Follow%20Playback%20and%20Ads.md).
