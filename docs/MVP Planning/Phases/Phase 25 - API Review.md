# Phase 25 - API Review

## Scope

Phase 25 adds creator-authored external-content linking into fan feeds without adding a new API object. It extends the existing External Content Source API with typed preview and link methods, then persists placement through Creator Experience API surface modules.

## APIs Reviewed

- `ExternalContentSourceApi.resolveExternalContentLink`
- `ExternalContentSourceApi.linkCreatorExternalContent`
- `CreatorExperienceApi.putExperienceConfig`
- `AiGatewayApi.runAiSearch`

## Decisions

- Reused the existing Drift-backed `public_imported_references` write path via `DemoLocalStore.upsertExternalReference`.
- Stored fan-channel placement in `CreatorExperienceConfig.surfaceModules` using kind `external_content`.
- Preserved original external title, thumbnail, source URL, source attribution, embed kind, rights basis, creator note, and search/AI gates in module config.
- Tapping a fan-channel external tile maps the module back into `AiSearchItem` and reuses Phase 24 playback.

## Gate Evidence To Capture

- `melos bootstrap`
- focused analyze over changed packages
- `melos run analyze`
- `melos run lint:boundaries`
- focused `flutter test test/p25_creator_external_content_test.dart`
- `melos run test`
- `flutter build apk --debug -t lib/main.dart`
- focused Phase 25 integration tests on emulator when WSL can see `emulator-5554`
- emulator `adb install -r`

## Residual Risks

- The fake resolver generates deterministic public metadata when the pasted URL/ID does not match seeded references. Production should replace this with source-specific metadata resolvers.
- Physical-phone playback validation remains Phase 26.
