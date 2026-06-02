# feature_creator_customize Charter

## Scope

Creator Studio fan-experience customization console: creator selection, theme and banner editing, extension install/configure/suspend, module ordering, live preview, and gaming starter-pack assembly.

## Allowed contracts

- Creator Metadata API
- Creator Experience API
- Extension Registry API
- Starter Pack API

## Owned screens

- `CreatorCustomizeConsoleScreen`

## Forbidden imports

Other features, `loom_fake_backend`, `loom_local_store`, and `loom_seed_data`.

Fan-channel rendering remains owned by `feature_creator_channel`; this feature only writes the configuration and install records the fan renderer consumes.
