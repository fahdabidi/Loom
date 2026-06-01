# Phase 6 - API Conformance And Efficiency Review

## Scope

Phase 6 implemented simulated fan wallet purchases, entitlement grants, no-ad playback eligibility, fan allocation statements, and creator revenue by source and session intent.

## APIs Reviewed

- `FanWalletApi`: `getWallet`, `createPaymentIntent`, `confirmPaymentIntent`, `listSubscriptions`.
- `EntitlementLedgerApi`: `grantEntitlement`, batch `checkEntitlements`.
- `SettlementEngineApi`: `runSettlement`, `getCreatorPayoutStatement`, `getFanSubscriptionAllocation`.
- `ReceiptLedgerApi`: added payment, membership, and premium no-ad receipt types.
- `PlaybackAuthorizationApi`: consumes the batched premium no-ad entitlement state before authorizing playback.

## Findings

| Area | Result | Evidence |
| --- | --- | --- |
| Payment idempotency | Pass | `createPaymentIntent` is idempotent by key and `confirmPaymentIntent` does not double-grant on replay. Covered by `p6_wallet_revenue_api_test.dart`. |
| Entitlement checks | Pass | Player uses one batch `checkEntitlements(passportId, ['premium_no_ads'])` before playback authorization; no per-content entitlement loop was added. |
| No-ad playback | Pass | Premium entitlement changes the playback authorization idempotency key and returns an ad-free authorization. Covered by `it_p6_no_ad_purchase`. |
| Revenue by intent | Pass | `getCreatorPayoutStatement` returns total, by-source, by-intent, and recent receipts in one response. Covered by `it_p6_revenue_by_intent`. |
| Allocation statement | Pass | Fan allocation is computed from active creator subscriptions and returned in one statement response. Covered by `it_p6_allocation_statement`. |
| Minimal payloads | Pass | Wallet and statement DTOs expose only screen fields: status, amount, entitlement/subscription rows, allocation lines, and receipt summaries. |
| Persistence | Pass | Drift schema version 7 adds wallet, payment intent, entitlement, subscription, settlement, payout, and allocation tables. |

## API Shape Decisions

- Payment flow uses local simulated payment intents rather than a payment SDK, keeping request/response shape close to a real payment provider without infrastructure.
- Entitlement grants are stored separately from entitlement definitions. Definitions describe creator tiers; grants represent fan-owned active entitlements.
- Playback uses `EntitlementState.noAdsPremium` only after a batch entitlement lookup, preserving the single-call playback authorization contract from Phase 4.
- Creator revenue returns source and intent breakdowns together to avoid N+1 dashboard calls.
- Fan allocation statements are settlement-engine reads, not wallet-only reads, because the statement reconciles subscriptions with creator support.

## Spec Follow-Ups

- OpenAPI should model `PaymentIntent`, `Wallet`, `Subscription`, `EntitlementGrant`, `CreatorPayoutStatement`, and `FanSubscriptionAllocationStatement` as explicit schemas.
- Receipt schemas should include typed payment, membership, and premium no-ad receipts, with amount and currency fields in the future real API.
- Settlement statement responses should keep by-source and by-intent breakdowns in one payload and include pagination only if recent receipts grow beyond the compact demo list.

## Verification

- `melos bootstrap`
- Drift generation: `dart run build_runner build --delete-conflicting-outputs`
- `melos run analyze`
- `melos run lint:boundaries`
- `melos run test` (19 tests)
- Focused Phase 6 integration tests (4/4) on `emulator-5554`
- Full `melos run test:integration` (27/27) on `emulator-5554` from a WSL-native mirror of the same `app/` tree to avoid OneDrive APK lock races
- `flutter build apk --debug`
- `adb install -r`
- App launch and screenshot: `data/validation/phase6-manual-checkpoint.png`
