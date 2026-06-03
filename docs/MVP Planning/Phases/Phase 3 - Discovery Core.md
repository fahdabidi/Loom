# Phase 3 — Discovery Core

**Surface:** Fan App · **UX gate:** MAJOR · **On green:** continue; manual UX validation runs in parallel
**Shared conventions:** [README.md](./README.md). This is the largest, highest-API-risk phase.

## 0. Prerequisite gate (validate Phase 2 done)
README gate + confirm: the demo creator has **live published content with summaries** and a `CreatorAdPolicy` (Phase 2), the seed world has surrounding creators/content, fan interest profile exists (Phase 1). Discovery consumes this; do not start without live + seeded content.

## 1. Workflows & user stories in this phase
- **FE-S9A / RE-S3A** — Startup content tiles (PlatformIntent × FanInterestProfile).
- **FE-S9 / RE-W3** — Trusted recommendation feed (glass-box, why-shown).
- **RE-W3A** — Startup tile selection + mid-session intent switch.
- **FE-S9B / RE-S8** — Like/dislike/mute/block feedback shaping the profile.
- **FE-S9C** — Hover-mode swipe-right (long-press + drag right) → like: tile springs back; after a 3-second client undo window the `like` feedback is committed, ranking is boosted for the item (+0.30) and same-creator content (+0.12 halo), and `pullAdditionalContent` appends any newly-surfaced items to the end of the grid.
- **FE-S9D** — Hover-mode swipe-left (long-press + drag left) → dismiss: tile is removed from the grid immediately (optimistic); after the 3-second undo window the `dislike` feedback is committed (no server-side refresh — the local list is already correct).
- **FE-S9E** — Undo window: after any swipe action a viewport-level overlay appears showing the action label, a circle-with-X (tapping it restores the dismissed tile / cancels the like commit), and an "Undo" label. Tapping anywhere else on the feed immediately accepts the action. The overlay auto-accepts after 3 seconds. The background feed is fully inert while the overlay is visible.
- **RE-S9** — Summary-first ranking hook (BYO-agent preference flag; AI wiring lands Phase 5, the flag/scoring path here).
- **RE-S7 / RE-W7** — Host trending statistics consumed for Entertainment/Trending intents.
- **FE-S5 / FE-W5** — Search as an intent (neutral, no ads in results).

## 2. Tools (WSL Ubuntu)
Standard set. Add seed for platform-intent registry + external-provider candidates + a small search index projection.

## 2A. UX reference research & decision output
Before implementing discovery UX, review reference mockups and design guidance from popular social/video apps such as YouTube, Instagram, TikTok, Facebook, WhatsApp Channels, and adjacent recommendation/search products. Focus on feed cards, why-shown explanations, interest/intention entry points, ranking transparency, feedback affordances, search-as-intent, pagination/load-more patterns, and disclosure without overwhelming the feed.

Apply the shared social-app UX baseline from [README.md](./README.md), plus these Phase 3 specifics:
- Make Home/Discover a modern social feed: compact top bar, bottom nav, horizontal intent/topic chips, visual startup tiles, and thumbnail-first feed cards.
- Offer an immersive TikTok/Reels-style discovery mode for trending or intent exploration, with near full-height media, floating action icons, and a bottom metadata panel.
- Keep why-shown and score explanations discoverable but not noisy: show compact badges in the feed and open the full explanation in a bottom sheet.
- Use icon feedback controls for like, dislike, mute, block, save, and share; debounce visually with optimistic state and keep load-more/pagination skeletons polished.
- Search should feel like a native social search surface with a focused top field, recent/intent chips, result thumbnails, creator rows, and neutral result labeling.

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
- `it_p3_swipe_dismiss_undo` — Hover mode: long-press + drag-left past threshold → tile removed from grid; undo overlay visible (`p3_undo_button`); tap `p3_undo_button` within 3 s → tile restored at original index.
- `it_p3_swipe_dismiss_commit` — same as above, but tap elsewhere on screen → overlay closes, `dislike` committed (tile stays gone); background scroll disabled while overlay was visible.
- `it_p3_swipe_like_pull` — long-press + drag-right → tile springs back; after 3 s like committed; fake-backend score boosted; `pullAdditionalContent` called; grid may gain a new tile at the end.
- `it_p3_hover_card_viewport` — scroll grid to bottom, tap a tile → expanded card fully within viewport bounds (not off-screen); dragging the blurred background does not scroll the feed.

## 10. Definition of done
Tiles → session intent → glass-box feed with why-shown, feedback, mid-session switch, trending-backed Entertainment intent, and neutral search all work on the Flutter Android emulator; feed is single-call + paginated; all checks green; API Review filed (esp. the N+1/batching/payload findings); UX Decisions doc filed. Update the Phase completion tracker in [../Demo App Implementation Plan.md](../Demo%20App%20Implementation%20Plan.md) with Phase 3 status, completion date, API review link/name, and gate evidence before marking this phase complete. Commit all Phase 3 changes to git and record the commit SHA in the tracker before proceeding.

## 11. Next phase
**Manual UX validation checkpoint (MAJOR).** Discovery UX dictates candidate **batching**, **pagination**, and **score-explanation payload** shape — the most consequential API decisions in the app. Keep the app available for human review of tile design, disclosure card, feed card (summary + why-shown), feedback affordances, intent switching, and search while implementation proceeds to [Phase 4 — Channel, Follow, Playback & Ads](./Phase%204%20-%20Channel%20Follow%20Playback%20and%20Ads.md).
