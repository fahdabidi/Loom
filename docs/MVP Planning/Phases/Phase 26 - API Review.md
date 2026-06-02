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
- Normal app launch now draws a Flutter bootstrap surface immediately while persistent Drift/SQLite dependency setup completes, preventing Android from staying on the native splash if startup work is slow.
- Final physical-phone validation is a Phase 26 manual launch sign-off owned by the validator after automated emulator gates pass.

## Gate Evidence Captured

- `melos bootstrap`
- `melos run analyze`
- `melos run lint:boundaries`
- focused `flutter test test/p26_final_showcase_api_test.dart`
- focused regression `flutter test test/p25_creator_external_content_test.dart`
- `melos run test` (72 tests)
- `flutter build apk --debug -t lib/main.dart`
- focused Phase 26 integration tests on `emulator-5554`: `it_p26_gaming_external_seed.dart`, `it_p26_ai_search_showcase.dart`, `it_p26_offline_states.dart`, `it_p26_full_regression.dart`, and `it_p26_normal_app_bootstrap.dart`
- emulator `adb install -r build/app/outputs/flutter-apk/app-debug.apk`
- emulator normal-app launch command and `reportedDrawn=true`
- emulator screenshots under `data/validation/phase26-emulator-final-home.png` (gitignored)

## Residual Risks

- Physical-phone validation remains a manual user sign-off on real hardware.
- Real YouTube playback requires network during manual validation; Loom APIs remain faked/offline.
