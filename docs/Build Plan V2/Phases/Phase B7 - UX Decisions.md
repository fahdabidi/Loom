# Phase B7 - UX Decisions

Status: Completed

Purpose: document UX research, extracted patterns, decisions, implementation impacts, workflow
walkthrough, and tradeoffs for subscription/ad-off purchase, purchase confirmation, entitlement
status, receipt, ad preferences, ad suppression, sensitive no-fill, settlement explanation, and utility
allocation UX.

## Reference Sources Reviewed

| Reference | Surface / Flow Reviewed | Why It Applies | Patterns Observed | Applicability / Gaps | Date Reviewed |
| --- | --- | --- | --- | --- | --- |
| [Apple subscription cancellation](https://support.apple.com/en-us/118428) | Subscription status and cancellation affordance | Ad-off needs clear entitlement status and exit/management path. | Status is tied to account settings; cancellation state is explicit when no cancel action remains. | Loom B7 validates purchase/status, not cancellation. | 2026-06-09 |
| [Apple refund request](https://support.apple.com/en-us/118223) | Refund request and receipt problem flow | Payment UX needs a path from receipt to support. | Refund starts from purchase/account problem context and requires a reason. | Refund/dispute routes are B8+/trust work. | 2026-06-09 |
| [Google Play manage purchases](https://developer.android.com/google/play/billing/manage-purchases) | Purchase/subscription management, refund/revocation, entitlement lifecycle | Loom needs receipt and entitlement state that can survive backend changes. | Entitlements can be revoked/refunded; lifecycle events update access. | B7 uses local fake receipts; hosted backend needs lifecycle events. | 2026-06-09 |
| [Google Play subscription management](https://support.google.com/googleplay/answer/7018481) | User-facing subscription management and ad reappearance after cancellation | Clarifies how ad-removal benefits are explained. | Benefits are removed when entitlement ends; ads can reappear after cancellation. | B7 does not implement cancellation; it records status and suppression. | 2026-06-09 |
| [YouTube ads with Premium help](https://support.google.com/youtube/answer/7437519) | Explaining what "ad-free" does not remove | Loom ad-off must explain remaining shell structure and sensitive no-fill behavior. | Some promotions/creator-integrated surfaces can remain even with premium status. | Loom policy differs; ad-off suppresses eligible Loom ads but not required shell structure. | 2026-06-09 |
| [Spotify receipts](https://support.spotify.com/us/article/check-receipts/) | Receipt history and payment proof | Ad-off confirmation should link to receipt history. | Receipts are available in account payment history and emailed on payment. | B7 proves receipt IDs; visual receipt history is later UI. | 2026-06-09 |
| [Spotify Premium troubleshooting](https://community.spotify.com/t5/FAQs/Subscribed-but-not-getting-Premium-features/ta-p/5399898) | Active entitlement but benefit not applied | Helps shape recovery copy when ads still appear. | Users should verify plan status and account identity when entitlement and benefit diverge. | Loom will need restore/recheck affordances in hosted mode. | 2026-06-09 |

## UX Patterns Extracted

| Pattern | Source References | User Problem Solved | Loom Application | Risk / Constraint |
| --- | --- | --- | --- | --- |
| Show scope, price, and benefit before purchase | Apple, Google Play | Users must understand what is being bought. | B7 uses shell-owned `PaymentSurfaceProps` for member and community ad-off checkout scopes. | Final UI needs richer plan copy and terms. |
| Confirmation must include receipt and active entitlement status | Google Play, Spotify receipts | Users need proof of purchase and trust that benefits applied. | B7 asserts entitlement active and receipt IDs for member/community purchases. | Hosted backend needs receipt history UI and email/export behavior. |
| Explain what ad-off removes and what it does not | YouTube Premium, Google Play | Prevents confusion when required structure remains visible. | B7 treats top/banner slots as shell-owned while ad decisions suppress eligible fills. | Copy must avoid promising removal of shell surfaces. |
| Entitlement-benefit mismatch needs a recovery path | Spotify troubleshooting, Apple restore references | Users need a way to recover when paid status is not reflected. | B7 records the need for restore/recheck in OpenAPI; local flow proves entitlement lookup. | Restore is deferred until hosted billing. |
| Economic impact should be auditable | Google Play purchase lifecycle, Spotify receipts | Owners and members need transparent value allocation. | Settlement and utility allocation are validated after ad-off purchase. | Detailed ledger visualizations are later admin UI. |

## Key UX Decisions

| Decision | Rationale | Applies To | Acceptance Signal / Test |
| --- | --- | --- | --- |
| Ad-off checkout is shell-owned, not extension-owned. | Payment trust and platform economics must not be spoofable by extensions. | Payment Surface, App Shell. | `wf_ad-off`, `vt_payment-surface_shell-owned`. |
| B7 supports both member ad-off and community-wide ad-off. | Members can opt out individually; owners can fund the whole community experience. | Wallet, Ad Decision, Payment Surface. | `wf_ad-off`, `vt_wallet_community-ad-off`. |
| Ad-off suppresses eligible Loom ads but does not remove required shell structure. | Required ad slots are platform invariants; fill state changes, structure remains. | Ad Slots, Ad Decision, App Shell. | `wf_ad-off`, `wf_messaging-ads-connections`. |
| Sensitive no-fill overrides normal monetization logic. | Sensitive contexts should not monetize even if the user has or lacks ad-off. | Ad Decision, Protected Vault policy. | `wf_ad-off`, `vt_ad-decision_sensitive-no-fill`. |
| Confirmation requires receipt, entitlement, settlement, and utility allocation evidence. | Economic flows must be auditable by construction. | Receipt Ledger, Settlement, Utility Funding. | `wf_ad-off`. |

## Key Implementation Decisions

| Implementation Decision | UX Impact | Owning Component | Tests / Gates |
| --- | --- | --- | --- |
| Represent community-wide ad-off as `passportId=community` within the current ad-off contract. | Enables community ad-off without expanding the interface mid-phase. | wallet-dues-donations, ad-decision-service | `vt_wallet_community-ad-off`, `wf_ad-off`. |
| Keep ad-off benefit lookup inside `CommunityWalletApi.hasAdOff`. | Ad Decision stays contract-only and does not inspect payment records directly. | wallet-dues-donations, ad-decision-service | `wf_ad-off`, A4b regressions. |
| Validate settlement and utility allocation after entitlement creation. | Confirms that ad-off is economically auditable, not just a UI preference. | settlement-engine, utility-funding-service | `wf_ad-off`, `vt_settlement_run`, `vt_utility-funding_calculate`. |
| Continue to assert sensitive no-fill separately from ad-off. | Prevents ad-off from masking privacy-specific ad suppression logic. | ad-decision-service, protected-visibility-vault | `wf_ad-off`. |

## Workflow Walkthrough

| Step | User Goal / Action | Screen or State | Owning Component | UX Decision Applied | Covering Test |
| --- | --- | --- | --- | --- | --- |
| 1 | Open ad-off checkout | Shell-owned payment surface for member ad-off. | payment-surface, app-shell-runtime | Payment is shell-owned. | `wf_ad-off` |
| 2 | Review scope and price | Member scope is $2.99; community scope is $19.99 in local fixture. | payment-surface | Scope/price before purchase. | `wf_ad-off` |
| 3 | Purchase ad-off | Wallet creates active member entitlement. | wallet-dues-donations | Member ad-off support. | `wf_ad-off` |
| 4 | Show confirmation and receipt | Receipt ledger contains entitlement receipt. | receipt-ledger | Receipt evidence required. | `wf_ad-off` |
| 5 | Show entitlement status | `hasAdOff` returns true and ad decision no-fills. | wallet-dues-donations, ad-decision-service | Entitlement-benefit link. | `wf_ad-off` |
| 6 | Update ad preference/status surface | Eligible top banner/in-stream fills become `ad-off-entitlement` no-fill. | ad-decision-service, ad-slots | Suppress eligible ads only. | `wf_ad-off` |
| 7 | Suppress eligible ads | Member and community entitlement paths suppress eligible ads. | ad-decision-service | Member and community ad-off. | `wf_ad-off` |
| 8 | Preserve sensitive no-fill | Sensitive stream context returns `sensitive-context`. | ad-decision-service, protected-visibility-vault | Sensitive no-fill override. | `wf_ad-off` |
| 9 | Show settlement/utility explanation | Settlement net and utility allocation are calculated. | settlement-engine, utility-funding-service | Auditable economics. | `wf_ad-off` |

## Open Questions / Tradeoffs

| Question / Tradeoff | Options Considered | Recommendation | Owner | Resolution Required Before |
| --- | --- | --- | --- | --- |
| Should community ad-off get a first-class API field? | Add interface now; encode as `passportId=community` locally. | Encode locally for B7 and add hosted OpenAPI issue. | Wallet/API owner | Hosted billing implementation |
| How should restore/recheck be exposed? | Local no-op; hosted billing restore; user support link. | Defer restore until real billing provider integration. | Payments owner | Real backend publish/billing phase |
| Should ad-off remove sponsor-created embedded content? | Remove all sponsor content; remove only Loom ad fills. | Remove only eligible Loom ad fills; embedded creator/owner content is separate. | Ads + Product | Ad policy UX copy |

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
