# Phase 10 - API Review

## Scope

Phase 10 adds the launch-demo API/data foundation for creator re-acquisition, starter-pack onboarding, aggregate conversion analytics, public-metadata import, cross-posting, contextual ad decisions, and premium no-ad provenance.

## Contract Changes

- Added typed launch clients in `loom_api_contracts`: `FanFollowCaptureApi`, `CreatorAnnouncementApi`, `StarterPackApi`, `AudienceAnalyticsApi`, `ExternalAccountLinkApi`, `ImportPublicMetadataApi`, `CrossPostingApi`, `AdDecisionApi`, and `PremiumNoAdApi`.
- Added launch DTOs for capture links, capture landings, re-follow results, announcement templates, rendered announcements, link-in-bio pages, starter packs, aggregate funnels, external account links, public metadata import jobs/references, cross-posts, ad decisions, ad impressions, and premium no-ad status/views.
- Added app-shell registration/resolver functions for every Phase 10 API.

## Persistence

- Bumped Drift schema to version 10.
- Added local tables for capture links, re-follow events, announcement templates, rendered announcements, link-in-bio pages, starter packs, bulk-follow jobs, external accounts, public metadata import jobs/references, cross-post jobs, ad decisions/impressions, and premium no-ad events.
- `resetDemo()` clears mutable launch state and reseeds templates, capture links, link-in-bio pages, starter packs, and verified external accounts over the existing mixed creator world.
- App runs continue to use persistent Drift/SQLite; tests use in-memory Drift.

## Fake Backend Behavior

- Added one fake implementation per new API surface in `loom_fake_backend`.
- All fakes read/write `DemoLocalStore`; there are no UI-only shortcuts and no in-memory fake backend state for Phase 10.
- Idempotent write paths use the shared idempotency table for capture-link creation, re-follow recording, announcement rendering, bulk follow, external-account linking/verification, public import creation, cross-post creation, ad decision/impression recording, and premium no-ad view recording.

## Privacy And Provenance

- Re-follows write through the follow table and emit audit-style re-follow events, not economic receipts.
- Starter-pack bulk follow dedupes existing follows and preserves selected visibility.
- Conversion analytics returns aggregate-only stages and source-channel counts; it does not expose per-fan rows or universal fan identifiers.
- Public metadata import stores public references and rights basis, not private follower graph data.
- Ad decisions use content, creator ad policy, ad posture, and entitlement state only; no behavioral targeting fields are accepted.
- Premium no-ad views emit a receipt only when an active no-ad entitlement exists.

## Validation

- Green: Drift generation, focused `dart analyze` for `loom_local_store`, `loom_app_shell`, `loom_api_contracts`, and `loom_fake_backend`, `flutter analyze` for `loom_demo`, and focused `flutter test test/p10_launch_contracts_api_test.dart`.
- Added integration tests: `it_p10_launch_contract_smoke_test.dart` and `it_p10_reset_launch_state_test.dart`.
- Blocked: Phase 10 integration tests were not runnable in the current WSL session because `adb devices` reported no attached Android emulator and Flutter reported no supported device.
