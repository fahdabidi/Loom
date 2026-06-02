# feature_fan_settings

Owns fan-facing settings for AI search agent and external source connections.

## Allowed dependencies

- `loom_api_contracts`
- `loom_app_shell`
- `loom_design_system`

## Boundary rules

- Reads and writes settings only through `FanVaultApi`.
- Does not import fake backend or local store packages.
- Does not perform AI search; Phase 23 discovery consumes the persisted settings.
