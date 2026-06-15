# Ad-Off

Use this workflow when building extension experiences that expose Loom's ad-off purchase, entitlement,
ad suppression, receipt, settlement, and utility funding behavior.

## Process

1. Route checkout through the shell-owned payment surface; do not implement custom payment collection in
   an extension.
2. Show the scope before purchase: member ad-off or community-wide ad-off.
3. Use `CommunityWalletApi.purchaseAdOff` to create the entitlement and receipt.
4. In local-demo mode, encode community-wide ad-off as `passportId=community`.
5. Use `CommunityWalletApi.hasAdOff` and `CommunityAdDecisionApi.decide` to prove the entitlement
   suppresses eligible ad fills.
6. Keep sensitive-context no-fill separate from ad-off. It should still return
   `reason=sensitive-context`.
7. Use `CommunityReceiptLedgerApi`, `CommunitySettlementApi`, and `CommunityUtilityFundingApi` to show
   auditable economic outcomes.
8. Validate in the Demo Loom Communities App with Local Backend.

## Covering Test

- `wf_ad-off`

## Gotchas

- Ad-off suppresses eligible Loom ad fills. It does not remove required shell structure.
- Community ad-off needs a first-class hosted API enum later; B7 uses the local contract-compatible
  `passportId=community` encoding.
- Never promise ad-off will hide owner-authored sponsor content unless that content is served through
  Loom's ad decision pipeline.
