# Phase 12 - API Review

## Scope

Phase 12 implements fan-side launch entry from a creator capture link, a selectable starter pack, idempotent bulk follow, and plural suggested creators in the original fan onboarding flow.

## APIs Reviewed

- `FanFollowCaptureApi.resolveCaptureLink` remains read-only and returns only the creator-branded landing fields used by the UI.
- `FanFollowCaptureApi.recordReFollow` is called only after explicit fan confirmation and uses a stable idempotency key: `p12-refollow-{passportId}-{captureToken}`.
- `StarterPackApi.getStarterPack` returns the source creator plus recommended members with display fields, default selection, and already-following state.
- `StarterPackApi.bulkFollow` receives only selected channel IDs, keeps fan visibility explicit, and returns followed/skipped state plus `feedReady`.
- Existing `FanPassportApi.createFollow` calls in Phase 1 onboarding now execute for a selected set of suggested creators rather than a single hard-coded creator.

## Boundary Findings

- `feature_fan_onboarding` imports typed API contracts, app-shell resolvers, and design-system components only.
- The fan capture flow does not import creator launch feature code.
- Design-system starter-pack widgets use simple view models and do not import API clients.
- The fake backend continues to persist through Drift/SQLite for app runs and uses in-memory Drift only for tests.

## Validation Evidence

- Focused analyzes: `loom_design_system`, `feature_fan_onboarding`, `feature_discovery`, and `loom_demo`.
- Focused tests: `flutter test test/p12_starter_pack_onboarding_test.dart test/p1_onboarding_controller_test.dart`.
- Phase 12 integration tests were added for capture landing, bulk follow, idempotency, and plural onboarding suggestions. Device execution is pending WSL `adb devices` visibility.
