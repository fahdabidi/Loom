# feature_creator_channel Charter

## Scope

Fan-facing creator channel screens. Phase 0 owns the proof slice that renders a paginated public catalog from `CreatorMetadataApi`.

## Allowed contracts

- `CreatorMetadataApi.getPublicCatalog`

## Owned screens

- `CreatorContentListScreen`

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

