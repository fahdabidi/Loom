# feature_creator_monetization Charter

## Scope

Creator membership tiers, no-ad eligibility, entitlement setup, and settlement hooks.

## Allowed contracts

- Creator Metadata API
- Entitlement Ledger API
- Settlement Engine API

## Owned screens

Phase 13 owns `CreatorMembershipSetupScreen`, which validates tier drafts, saves membership definitions, registers entitlement definitions, and previews the resulting tiers. Phase 2 membership setup remains available in the shared Studio setup console.

## Forbidden imports

Other features, `loom_fake_backend`, `loom_local_store`, and `loom_seed_data`.
