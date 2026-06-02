# Phase 17 - API Review

Date: 2026-06-02

## Scope Reviewed

Phase 17 brings the competitive/economy extension modules to life through existing contracts:
- `ExtensionRuntimeApi.createExtensionSession(...)`
- `ExtensionRuntimeApi.submitExtensionEvent(...)`
- `ExtensionRuntimeApi.createExtensionStateExport(...)`
- `FanWalletApi.createPaymentIntent(...)` and `confirmPaymentIntent(...)`
- `ReceiptLedgerApi.receiptsForPassport(...)`

## API And Efficiency Decisions

- Channel slots still come from `CreatorExperienceConfig.surfaceModules`; the app composition root supplies a live extension module builder so feature packages do not import each other.
- Extension sessions are created once per channel/module/passport idempotency key and scoped to the install's approved surface and permissions.
- Clip submit/vote, Pick'Em, and HypeWars all use `submitExtensionEvent`; aggregate state is persisted in the existing Phase 15 extension-state KV.
- HypeWars uses a new `PurchaseKind.extensionHype` wallet intent instead of misusing membership purchases. Confirmation emits typed payment and extension-hype receipts, while the runtime event advances the extension meter and emits a reward receipt.
- The same state export endpoint powers bounded reads for leaderboards, ladders, and hype meter state.

## Contract Gaps

- `FanWalletApi.createPaymentIntent` still has a fixed amount for `extensionHype`; a real API should accept a validated tip amount or SKU reference.
- `ExtensionRuntimeApi.createExtensionStateExport` works for the demo, but a production API should offer paginated module-state reads instead of export-shaped reads for live UI.
- Reward issuance is proven through runtime reward payload receipts. A production API should formalize reward campaign references and prize settlement fields.

## Validation Evidence

Green:
- `melos bootstrap`
- focused analyzes for `feature_extensions` and `loom_demo`
- `melos run analyze` across 28 packages
- `melos run lint:boundaries`
- focused `flutter test test/p17_extension_runtime_api_test.dart test/p17_extension_modules_widget_test.dart`
- `melos run test` (45 tests)
- `flutter build apk --debug -t lib/main.dart`

Blocked device evidence:
- WSL `adb devices` reports no attached Android device.
- `flutter devices` only reports Linux desktop.
- Focused Phase 17 integration tests fail with no supported `emulator-5554`.
- Emulator `adb install` fails with no devices/emulators found.
