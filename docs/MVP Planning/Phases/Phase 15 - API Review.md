# Phase 15 - API Review

Date: 2026-06-02

## Scope Reviewed

Phase 15 adds the creator-customized fan experience foundation:
- `ExtensionRegistryApi`
- `ExtensionRuntimeApi`
- `CreatorExperienceApi`
- `ExtensionManifest`, `ExtensionInstall`, `ExtensionSession`, `ExtensionEvent`, `ExtensionStateExport`
- `CreatorExperienceConfig`, `ChannelTheme`, `SurfaceModule`, `InstalledExtensionRef`

## Contract Decisions

- The extension platform uses one manifest shape for all six certified extensions: Clip Arena, Pick'Em, HypeWars, Quest Log, Build Showcase, and Guild Quest.
- `CreatorExperienceConfig` is a dedicated typed API instead of being folded into `CreatorMetadataApi`; this keeps Phase 16-20 fan rendering and Studio customization code pointed at one explicit customization surface.
- Extension installs are permission-scoped and surface-scoped. Session creation rejects a surface that is not approved by the active install.
- Runtime events are idempotent by key. Reward events reuse the existing `ReceiptLedgerApi`/receipt table path with `ReceiptType.reward`; no separate economy ledger was introduced.
- App runs persist through Drift/SQLite. Phase 15 stores extension/config/runtime records as typed JSON records in the existing `kvMeta` table, so no schema migration is needed. Tests continue to use in-memory Drift.

## Seed And Provenance

- Added five gaming creators to `loom_seed_data`: NovaClutch, EmberHollow, FrameByFrame, DriftAndChill, and IronVael.
- Added gaming content and interest taxonomy tokens so discovery/search can resolve seeded creators without UI-only values.
- Seeded five distinct channel themes, banners, AI persona labels, ad posture strings, ordered surface modules, and a creator-to-extension install matrix.
- `resetDemo()` restores seed manifests, installs, config, and seed mechanic state while clearing mutable sessions/events.

## Validation Evidence

Green:
- `dart format`
- `melos run analyze`
- `melos run lint:boundaries`
- `flutter test test/p15_extensions_foundation_api_test.dart`
- `melos run test` (37 tests)

Pending device gates:
- Focused Phase 15 integration tests are present, but emulator execution depends on WSL seeing an Android device.
- APK build/install/launch evidence should be recorded in the tracker after the build/device checks complete.
