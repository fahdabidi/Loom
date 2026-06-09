# Wallet Dues Donations

Use `CommunityWalletApi` for dues, donations, reservation payments, and ad-off purchases.

## Extension Use

- Record payments through Loom so receipts are appended by the receipt ledger.
- Use `purchaseAdOff` for member or community ad-off entitlements.
- Treat payment confirmation as a Loom-owned result that UI components display, not calculate.

## Validation

- `vt_wallet_payment` proves payment and receipt linkage.
- `vt_wallet_ad-off` proves ad-off entitlement state.
- `ct_wallet__ad-decision_ad-off-entitlement` proves ad decisions honor ad-off.
