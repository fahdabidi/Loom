# Phase 16 - API Review

Date: 2026-06-02

## Scope Reviewed

Phase 16 makes the fan-facing creator channel renderer data-driven:
- `CreatorExperienceApi.getExperienceConfig(channelId)`
- `CreatorExperienceConfig.theme`, `bannerRef`, `surfaceModules`, `aiPersona`, `adPosture`, and `installedExtensions`
- Existing `CreatorMetadataApi.getChannelHome(...)` for creator identity, content, follow/block state, and ad policy

## API And Efficiency Decisions

- Channel open performs one metadata read plus one experience-config read. Module rendering does not issue per-module API calls.
- The design-system package remains API-contract-free. The feature maps API `ChannelTheme` to design-system `LoomChannelTheme`.
- Header theme, banner, module order, AI persona, and ad posture now come from config data.
- Unknown module kinds render a safe placeholder instead of crashing.
- Discovery no longer uses the old per-creator `_paletteFor()` map; poster gradients are generic until a full channel config is loaded.
- `CreatorChannelHomeScreen.didUpdateWidget` reloads when `channelId` or `passportId` changes, fixing same-widget channel swaps.

## Contract Gaps

No new API surface was required. Phase 17-18 should replace extension placeholders with real module widgets using the existing `ExtensionRuntimeApi`.

## Validation Evidence

Green:
- `dart format`
- focused analyzes for `loom_demo`, `loom_design_system`, `feature_creator_channel`, and `feature_discovery`
- `melos run analyze`
- `melos run lint:boundaries`
- focused `flutter test test/p16_config_driven_channel_widget_test.dart`
- `melos run test` (40 tests)
- `flutter build apk --debug -t lib/main.dart`

Blocked device evidence:
- WSL `adb devices` reports no attached Android device.
- `flutter devices` only reports Linux desktop.
- Focused Phase 16 integration tests fail with no supported `emulator-5554`.
- Emulator `adb install` fails with no devices/emulators found.
