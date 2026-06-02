# Phase 22 - API Review

## Scope Reviewed

Phase 22 adds fan settings UX over the Phase 21 Fan Vault API:

- `getSearchAgentConfig` / `putSearchAgentConfig`
- `getExternalSourceConnections` / `putExternalSourceConnection`

No new API surfaces were added.

## API Decisions

- The screen never reads local store or fake backend directly; `FanAiSearchSettingsController` persists only through `FanVaultApi`.
- Agent connection is simulated through a provider enum and MCP endpoint string. No real secret exchange is stored.
- YouTube source connection is simulated and reversible. Other source types remain modeled but available for later connectors.
- `preferCreators` is stored as a fan search default and is explicitly represented as non-monetized preference state.

## Validation Evidence

- Focused analyze over `feature_fan_settings`, `feature_discovery`, `loom_design_system`, and `loom_demo` passed.
- From `apps/loom_demo`: `flutter test test/p22_fan_settings_widget_test.dart` passed 2/2.

## Follow-Up For Later Phases

- Phase 23 consumes connected-agent, external-source, and prefer-creator settings in the discovery search path.
- Phase 24 consumes connected YouTube state through AI search embed descriptors; the Settings UX does not perform playback.
