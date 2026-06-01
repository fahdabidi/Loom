# Phase 3 - API Review

Date: 2026-06-01

## Reviewed surfaces

- `RecommendationReferralApi`: startup intent tiles, session creation/switching, paged ranked feed, and explicit feedback submission.
- `ExternalRecommendationProviderApi`: bounded candidate retrieval by session and interest set.
- `SearchApi`: neutral query path returning search results without ad placement signals.
- `ContentHostApi`: trending stats extension for discovery surfaces.
- `loom_app_shell`: dependency registration and resolution for recommendation, external-provider, and search APIs.
- `DemoLocalStore`: Drift schema version 4 with platform intents, session intents, fan feedback, external candidates, and search index entries.

## Contract decisions

- Discovery ranking is session-scoped. A `SessionIntent` records the current intent and selected interest set so mid-session switching is explicit and inspectable.
- Feed items carry `ContentScoreExplanation`, provider labels, trending labels, and a score so the UI can show "why this" without per-card network calls.
- Feedback actions are explicit enum values (`like`, `dislike`, `muteCreator`, `blockCreator`) and persist as feedback events before the next feed refresh.
- Search results reuse `ContentTile` so the neutral-search workflow and feed workflow render content consistently while keeping the `neutralityLabel` visible.
- Trending stats remain in `ContentHostApi` because creator performance metadata is owned by hosting/content infrastructure, not the recommender.

## Store and fake backend review

- New Drift tables persist the phase state instead of using process-only maps: `platform_intents`, `session_intents`, `fan_feedback`, `external_provider_candidates`, and `search_index_entries`.
- Seeded platform intents model a modern fan-app cold start: For you, Learn, Trending, and Reset.
- Recommendation fake ranks from seed content, explicit session intent, external candidate score, and transparent performance velocity.
- Disliked content is suppressed from the next feed page; muted or blocked creators are persisted on the fan profile and excluded from subsequent ranking.
- Search fake reads the local search index and labels results as neutral: no ads, boosts, or paid placement.

## Gate evidence

- `melos bootstrap`: passed after adding `feature_discovery` to the demo app.
- Drift generation: `dart run build_runner build --delete-conflicting-outputs` completed; Drift ignored the removed flag and regenerated outputs.
- `melos run analyze`: passed.
- `melos run lint:boundaries`: passed.
- `melos run test`: passed, 9 tests.
- `melos run test:integration`: passed, 16 tests on `emulator-5554`.
- `flutter build apk --debug`: passed.
- `adb -s emulator-5554 install -r build/app/outputs/flutter-apk/app-debug.apk`: passed.
- `adb -s emulator-5554 shell am start -n com.example.loom_demo/.MainActivity`: passed.

## Residual notes

- Physical-device validation remains deferred to Phase 9 per project decision.
- The implementation keeps the Phase 3 ranking deterministic for validation; later phases can replace the fake scoring internals without changing the public contracts.
