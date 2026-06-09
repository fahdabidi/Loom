# Phase B7 - Ad-Off

Workflow bundle: member ad-off, community ad-off, eligible ad suppression, sensitive no-fill, receipts,
settlement, utility allocation.
Components involved: Wallet, Entitlements, Ad Decision, Ad Slots, Receipt Ledger, Settlement, Utility
Funding, App Shell Payment Surface.
UX gate: medium-high
Gate: `wf_ad-off` plus affected component regressions pass.

## 0. Prerequisite Gate

- B6 complete and committed.
- Wallet, ad decision, receipt, settlement, and payment-surface tests are current.

## 1. Workflows and End States

| Workflow | End state |
| --- | --- |
| `wf_ad-off` | Member or community purchases ad-off, eligible ads are suppressed, sensitive no-fill still applies, receipts and settlement/utility allocation update. |

## 2. Workflow Tests Mapped to Owning Components

| Step | Owning component | Supporting tests |
| --- | --- | --- |
| Open ad-off checkout | payment-surface, app-shell-runtime | `vt_payment-surface_shell-owned` |
| Create payment and entitlement | wallet-dues-donations | `vt_wallet_ad-off`, `vt_wallet_payment` |
| Suppress eligible ads | ad-decision-service | `vt_ad-decision_ad-off` |
| Preserve sensitive no-fill | ad-decision-service, protected-visibility-vault | `vt_ad-decision_sensitive-no-fill` |
| Record receipts | receipt-ledger | `ct_receipt-ledger__wallet_append-payment` |
| Allocate value | settlement-engine, utility-funding-service | `vt_settlement_run`, `vt_utility-funding_calculate` |

## 3. UX Research and Decisions

Create `Phase B7 - UX Decisions.md`. Review subscription/ad-off, purchase confirmation, entitlement
status, receipt, and ad preference UX.

## 4. Execution and Issue-Triage Loop

Run `wf_ad-off`. Payment, entitlement, ad suppression, and settlement failures must first strengthen the
owning component validation or contract test.

## 5. Per-Component Regression Gate

Run all tests for altered components plus workflows involving Wallet, Ads, Payment Surface, Receipt,
Settlement, and Utility Funding.

## 6. Skill Contribution

Add:

- `Skill/workflows/ad-off.md`

Update wallet, ad decision, payment surface, receipt, settlement, and utility funding component guides.

## 7. Manifest Update

Stamp `wf_ad-off` and affected tests.

## 8. API Review

Create `Phase B7 - API Review.md`. Record ad-off entitlement, ad decision, receipt, settlement, and
utility-funding gaps.

## 9. Definition of Done

Ad-off workflow passes, regressions pass, Skill updated, manifest current, UX/API docs filed, tracker
and commit SHA recorded.

## 10. Next Phase

Proceed to [Phase B8 - Export and Migration.md](./Phase%20B8%20-%20Export%20and%20Migration.md).
