# feature_creator_channel Charter

## Scope

Fan-facing creator channel screens: channel home, follow controls, creator blocking, content launch, creator-linked external-content tiles, and config-driven channel module layout.

## Allowed contracts

- `CreatorMetadataApi.getPublicCatalog`
- `CreatorMetadataApi.getChannelHome`
- `CreatorExperienceApi.getExperienceConfig`
- `FanPassportApi`

## Owned screens

- `CreatorContentListScreen`
- `CreatorChannelHomeScreen`

## Allowed imports

- `loom_api_contracts`
- `loom_design_system`
- `loom_app_shell`
- Flutter SDK packages

## Forbidden imports

- Other `feature_*` packages
- `loom_fake_backend`
- `loom_local_store`
- `loom_seed_data`
