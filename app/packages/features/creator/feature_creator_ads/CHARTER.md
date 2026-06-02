# feature_creator_ads Charter

## Scope

Creator ad-policy setup and sponsor-campaign controls.

## Allowed contracts

- Creator Metadata API
- Ad Decision API
- Sponsor Campaign API

## Owned screens

Phase 13 owns `CreatorAdPolicyConsoleScreen`, which saves creator ad-policy categories and verifies downstream ad decisions consume the latest saved policy. Phase 2 ad-policy setup remains available in the shared Studio setup console.

## Forbidden imports

Other features, `loom_fake_backend`, `loom_local_store`, and `loom_seed_data`.
