# Phase B7 - API Review

Status: Completed

## Scope

Ad-off workflow: shell-owned checkout, member entitlement, community-wide entitlement, eligible ad
suppression, sensitive no-fill, receipts, settlement, and utility allocation.

## Review Checklist

- Ad-off checkout: covered by `PaymentSurfaceProps` with `shellOwned=true`.
- Member ad-off entitlement: covered by `CommunityWalletApi.purchaseAdOff` and `hasAdOff`.
- Community ad-off entitlement: covered locally by `purchaseAdOff(scopeId, passportId: 'community')`
  and wallet fallback lookup.
- Eligible ad suppression: covered by `CommunityAdDecisionApi.decide` returning `noFill` with
  `ad-off-entitlement`.
- Sensitive no-fill: still covered by `CommunityAdDecisionApi.decide(sensitiveContext: true)`.
- Receipts: covered by `CommunityReceiptLedgerApi.listReceipts`.
- Settlement: covered by `CommunitySettlementApi.runSettlement`.
- Utility funding: covered by `CommunityUtilityFundingApi.calculate`.

## OpenAPI Outputs

- Hosted Wallet/OpenAPI should add a first-class `adOffScope` enum (`member`, `community`) instead of
  relying on the local `passportId=community` encoding.
- Ad Decision OpenAPI should document precedence: sensitive no-fill first, ad-off entitlement second,
  campaign eligibility third.
- Receipt OpenAPI should expose entitlement receipt linkage, receipt history, refund/dispute status, and
  exportable receipt records.
- Settlement/Utility APIs should expose allocation rationale, basis points, owner net, utility share,
  and auditable settlement run IDs.
- Payment Surface API should expose restore/recheck status when real billing providers are integrated.

## WSL Ubuntu Tooling Requirement

Run all phase tooling from WSL Ubuntu, not Windows PowerShell. Use this command shape from the Windows host:

```powershell
wsl.exe -d Ubuntu -- bash -lc 'cd "/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app" && <command>'
```

Inside WSL Ubuntu, `dart`, `flutter`, and `melos` must resolve from the Ubuntu toolchain. Do not run Dart, Flutter, Melos, package validation, manifest gates, phase gates, or workflow tests from Windows-native shells.

## Commit Gate

Before starting the next phase:

- Stage only this phase's intended changes.
- Run `git diff --staged` and confirm the staged scope matches this phase.
- Commit the phase changes.
- Record the resulting commit SHA in [../Build Tracker.md](../Build%20Tracker.md).
- Do not begin the next phase until the commit exists and the tracker points to it.
