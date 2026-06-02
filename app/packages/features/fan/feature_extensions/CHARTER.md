# feature_extensions Charter

## Scope

Fan-facing extension runtime host widgets for certified creator-channel modules.
This package starts scoped extension sessions, submits runtime events, maps
extension state into design-system module view models, and keeps wallet/reward
actions on existing API contracts.

## Allowed contracts

- `ExtensionRuntimeApi`
- `FanWalletApi`

## Owned widgets

- `ExtensionRuntimeModule`

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
