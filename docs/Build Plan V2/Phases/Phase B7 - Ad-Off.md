# Phase B7 - Ad-Off

Workflow bundle: member ad-off, community ad-off, eligible ad suppression, sensitive no-fill, receipts,
settlement, utility allocation.
Components involved: Wallet, Entitlements, Ad Decision, Ad Slots, Receipt Ledger, Settlement, Utility
Funding, App Shell Payment Surface.
UX gate: medium-high
Gate: `wf_ad-off` plus affected component regressions pass.

## WSL Ubuntu Tooling Requirement

Run all phase tooling from WSL Ubuntu, not Windows PowerShell. Use this command shape from the Windows host:

```powershell
wsl.exe -d Ubuntu -- bash -lc 'cd "/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app" && <command>'
```

Inside WSL Ubuntu, `dart`, `flutter`, and `melos` must resolve from the Ubuntu toolchain. Do not run Dart, Flutter, Melos, package validation, manifest gates, phase gates, or workflow tests from Windows-native shells.

## 0. Prerequisite Gate

- B6 complete and committed.
- Wallet, ad decision, receipt, settlement, and payment-surface tests are current.
- Workflow validation target is the Demo Loom Communities App with the Local Backend.

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

Complete `Phase B7 - UX Decisions.md` before implementation work that affects UI, interaction, user-visible state, or workflow copy. The UX Decisions file is a gate artifact and must follow this required format:

1. **Reference Sources Reviewed** - find several reference implementations of subscription/ad-off purchase, purchase confirmation, entitlement status, receipt, ad preferences, ad suppression, sensitive no-fill, settlement explanation, and utility allocation UX; record each source, surface/flow reviewed, why it applies, patterns observed, applicability/gaps, and review date.
2. **UX Patterns Extracted** - learn from the reference implementations and extract concrete patterns for task flow, entry points, state handling, trust/privacy/payment cues, layout density, accessibility, and error recovery.
3. **Key UX Decisions** - list the UX decisions made for Loom, with rationale, affected surfaces, and the acceptance signal or covering test.
4. **Key Implementation Decisions** - record implementation choices that materially alter UX, including component ownership, state model, layout behavior, validation behavior, copy source, and test coverage.
5. **Workflow Walkthrough** - walk through the workflow step by step, mapping each user goal/action to the screen or state, owning component, UX decision applied, and covering test.
6. **Open Questions / Tradeoffs** - capture unresolved questions, options considered, recommendation, owner, and when resolution is required.

The phase cannot be marked done if the UX Decisions file only contains generic notes or unreviewed placeholders. If no external references are available, record the internal reference surfaces reviewed and the reason external reference research was not possible.

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

## Commit Gate

Before starting the next phase:

- Stage only this phase's intended changes.
- Run `git diff --staged` and confirm the staged scope matches this phase.
- Commit the phase changes.
- Record the resulting commit SHA in [../Build Tracker.md](../Build%20Tracker.md).
- Do not begin the next phase until the commit exists and the tracker points to it.

## 10. Next Phase

Proceed to [Phase B8 - Export and Migration.md](./Phase%20B8%20-%20Export%20and%20Migration.md).
