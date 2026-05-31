# Phase 6 — Wallet (Fan) + Revenue Dashboard (Creator)

**Surface:** both · **UX gate:** med · **On green:** AUTO → Phase 7
**Shared conventions:** [README.md](./README.md). All money is **simulated**.

## 0. Prerequisite gate (validate Phase 5 done)
README gate + confirm: membership tiers + no-ad eligibility defined (Phase 2), playback honors entitlements (Phase 4), receipts flowing (Phase 4–5). Phase 5 integration tests pass.

## 1. Workflows & user stories in this phase
- **FE-S3 / FE-W3 / MN-S2** — Buy global no-ad premium (simulated) → no-ad playback.
- **FE-S4 / FE-W4 / MN-S3** — Buy a creator membership (simulated) → member access.
- **FE-S11** — Wallet manages memberships + no-ad (boosts/gifts deferred).
- **CE-S6 / MISSING-S4** — Creator revenue dashboard with **by-intent** breakdown.
- Fan **subscription allocation statement** ("how this supported creators").

## 2. Tools (WSL Ubuntu)
Standard set. No payment SDK — payment intents are simulated and resolved locally.

## 2A. UX reference research & decision output
Before implementing wallet and revenue UX, review reference mockups and design guidance from popular social/creator monetization products such as YouTube memberships/analytics, Instagram subscriptions, TikTok creator tools, Facebook/Meta monetization, WhatsApp payments where relevant, and adjacent wallet/dashboard products. Focus on purchase confirmation, membership/no-ad affordances, entitlement status, allocation statements, creator revenue summaries, by-intent breakdowns, trust/receipt presentation, and dense-but-readable dashboard layout.

Apply the shared social-app UX baseline from [README.md](./README.md), plus these Phase 6 specifics:
- Fan wallet should look like a modern subscriptions/payments surface: entitlement rows, membership/no-ad cards, clear status labels, and purchase confirmation in a bottom sheet.
- Use receipt-ledger presentation for purchases and allocation statements: amount, creator, entitlement, date, state, and "how this supports creators" details.
- Creator revenue should use a dense Studio dashboard pattern with summary metric cards, source/intent segmented views, compact charts, and recent receipt rows.
- Keep simulated-money language explicit and visible, but do not let it dominate the UI or make the screen feel like a test harness.
- Use icon actions and sheets for renewal/cancel/details rather than large text buttons repeated in every row.

Create [Phase 6 - UX Decisions.md](./Phase%206%20-%20UX%20Decisions.md) summarizing references reviewed, UX patterns extracted, key UX and implementation decisions, and a walkthrough of how the implemented UX demonstrates simulated purchases, entitlements, fan allocation, and creator revenue by source/intent using the collected guidance.

## 3. APIs invoked & stubs to implement
- **Fan Wallet API:** `getWallet`, `createPaymentIntent` (simulated, idempotent), `confirmPaymentIntent`, `listSubscriptions`. Fake: `FanWalletFake`.
- **Entitlement Ledger API:** `grantEntitlement`, `checkEntitlements` (**batch**). Extend `EntitlementLedgerFake`.
- **Receipt Ledger API:** `PaymentReceipt`, `MembershipReceipt`, `PremiumNoAdReceipt`. Reuse `ReceiptLedgerFake`.
- **Settlement Engine API:** `runSettlement` (sim), `getCreatorPayoutStatement` (**by source + by session intent**), `getFanSubscriptionAllocation`. Fake: `SettlementEngineFake`.
- **Playback Authorization API:** consume no-ad entitlement (reuse Phase 4 fake).

## 4. Data storage (local store)
New tables: `wallets`, `payment_intents`, `entitlements`, `subscriptions`, `settlement_runs`, `payout_statements(bySource, byIntent)`, `allocation_statements`. Receipts extended with `intentContext` (already captured at playback). Seed: historical receipts + one prior settlement run so the creator dashboard is populated at launch.

## 5. Source files & components to create/update
- `core/loom_api_contracts/clients/`: fill `fan_wallet_api.dart`, `settlement_engine_api.dart`; extend `entitlement_ledger_api.dart`. Models: `Wallet`, `PaymentIntent`, `Entitlement`, `Subscription`, `CreatorPayoutStatement` (source + intent breakdown), `FanSubscriptionAllocationStatement`.
- `core/loom_fake_backend/`: `fan_wallet_fake.dart`, `settlement_engine_fake.dart`; extend `entitlement_ledger_fake.dart`.
- `core/loom_design_system/components/`: `wallet_row.dart`, `entitlement_row.dart`, `purchase_sheet.dart`, `receipt_statement.dart`, `studio/revenue_dashboard.dart` (source + intent charts).
- `features/fan/feature_wallet/`: screens `wallet`, `purchase` (no-ad + membership), `allocation_statement`; `wallet_notifier`; `CHARTER.md`.
- `features/creator/feature_creator_revenue/`: screen `revenue_dashboard` (by source + by intent); `revenue_notifier`; `CHARTER.md`.

## 6. API best-practice checks (phase-specific)
- `createPaymentIntent` / `confirmPaymentIntent` **idempotent** (`Idempotency-Key`); re-submit never double-charges/double-grants.
- **Entitlement checks are batched/cached:** the player/app checks a fan's entitlement **set once** (or via a bulk `checkEntitlements`), not one call per content item. Verify no per-item entitlement N+1.
- Revenue **by-intent** breakdown is returned in **one** `getCreatorPayoutStatement` call (a grouping param), not one call per intent.
- Minimal payload on wallet/statement responses.

## 7. Component boundary / design checks
- `feature_wallet` and `feature_creator_revenue` import only contracts + design_system + app_shell.
- Revenue dashboard component is presentational (charts fed by mapped view models); no settlement logic in UI.
- `melos run lint:boundaries` clean.

## 8. Automated validation checks
README baseline. Unit tests: payment-intent idempotency, batched entitlement check, payout-by-intent aggregation, allocation-statement math.

## 9. Integration tests
- `it_p6_no_ad_purchase` — buy no-ad (sim) → `PremiumNoAdEntitlement` → eligible playback skips ads; `PremiumNoAdReceipt` emitted.
- `it_p6_membership_purchase` — buy membership (sim) → member content unlocks; receipts emitted.
- `it_p6_revenue_by_intent` — creator dashboard shows revenue split by source **and** session intent from one statement call.
- `it_p6_allocation_statement` — fan sees how their subscription supported creators.

## 10. Definition of done
Fan can buy no-ad + membership (simulated) and see allocation; creator sees revenue by source and by intent; payments idempotent, entitlement checks batched; all checks green; API Review filed; UX Decisions doc filed. Update the Phase completion tracker in [../Demo App Implementation Plan.md](../Demo%20App%20Implementation%20Plan.md) with Phase 6 status, completion date, API review link/name, and gate evidence before marking this phase complete. Commit all Phase 6 changes to git and record the commit SHA in the tracker before proceeding.

## 11. Next phase
Med UX, no API-shaping beyond validated. After Phase 6 changes are committed and the commit SHA is recorded, **AUTO-PROCEED: immediately begin [Phase 7 — Data Rights & Data for Value](./Phase%207%20-%20Data%20Rights%20and%20Data%20for%20Value.md).**
