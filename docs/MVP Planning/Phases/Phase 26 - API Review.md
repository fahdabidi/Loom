# Phase 26 - API Review

## Scope

Phase 26 wires the gaming YouTube seed references into the five gaming creators' fan feeds, validates the AI-search/external-content showcase, and records the final physical-phone validation gate.

## APIs Reviewed

- `CreatorExperienceApi.getExperienceConfig`
- `ExternalContentSourceApi.getExternalContent`
- `AiGatewayApi.runAiSearch`
- `FanVaultApi.putSearchAgentConfig`
- `FanVaultApi.putExternalSourceConnection`
- `DemoLocalStore.resetDemo`

## Decisions

- Seeded YouTube references remain stored in `public_imported_references`.
- Each gaming creator now gets a seeded `external_content` surface module pointing at its existing YouTube public reference.
- The module config preserves source URL, YouTube embed kind, source attribution, rights basis, accurate-match label, creator note, and search/AI gates.
- Phase 24 playback continues to be the only external playback route; no Loom ads are placed over external embeds.
- Final physical-phone validation is a Phase 26 launch gate and cannot be signed off until adb can see a physical Android phone.

## Gate Evidence To Capture

- `melos bootstrap`
- focused analyze over changed packages
- `melos run analyze`
- `melos run lint:boundaries`
- focused `flutter test test/p26_final_showcase_api_test.dart`
- `melos run test`
- `flutter build apk --debug -t lib/main.dart`
- focused Phase 26 integration tests on emulator
- emulator `adb install -r`
- physical phone `adb devices`, `adb -s <phone_id> install -r`, launch command, manual walkthrough, screenshots, device ID/model

## Residual Risks

- Physical-phone validation is blocked until a real Android phone is connected and visible to WSL/adb.
- Real YouTube playback requires network during manual validation; Loom APIs remain faked/offline.
