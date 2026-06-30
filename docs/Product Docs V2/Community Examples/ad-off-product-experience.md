# Ad-Off Product Experience

## 1. Community Identity And Promise

| Field | Value |
| --- | --- |
| Community name | Ad-Off |
| Evidence community name | Ad-Free Community |
| Community type | Subscription and owner ad-off flow |
| Product promise | Let members or owners understand ad-off purchase, entitlement, receipts, and funded utility impact. |
| Brand cues | Payment/entitlement/receipt clarity, calm trust-oriented shell. |
| What this must not feel like | Abstract entitlement and ad-decision status chips. |

## 2. Personas, Roles, And Jobs

| Persona | Role/capabilities | Primary jobs-to-be-done | Sensitive constraints | Success state |
| --- | --- | --- | --- | --- |
| Member | Buy/view ad-off | Remove ads and see receipt/entitlement state. | Payment and receipt must be explicit. | Ads are suppressed according to entitlement and receipt is visible. |
| Owner | Fund/sponsor community ad-off | Understand cost, settlement, and utility allocation. | Settlement/utility records need audit clarity. | Community ad-off state and funding record are clear. |

## 3. Information Architecture

| Surface | Purpose | Primary persona | Required content | Primary action |
| --- | --- | --- | --- | --- |
| Ad-off offer | Explain value and price. | Member/owner | price, coverage, duration, disclosure. | Turn off ads |
| Entitlement status | Show active state. | Member | active/inactive, renewal, affected surfaces. | Manage |
| Receipt/settlement | Prove payment allocation. | Member/owner | receipt, settlement, utility funding. | View receipt |

## 4. Home Screen Requirements

The user must understand what ad-off changes, what it costs, and what receipt/entitlement state exists
without reading implementation terms.

## 5. Domain-Native Product Surfaces

| Surface | Required visible content | Required states | Natural actions | Anti-patterns |
| --- | --- | --- | --- | --- |
| Purchase | price, payer, coverage, payment method | available/purchased/failed | buy, retry | abstract entitlement row |
| Entitlement | active state, expiry/renewal, ad surfaces affected | active/inactive | manage | hidden ad decision proof |
| Receipt | amount, date, payer, settlement/utility | issued/refunded | view/export | generic receipt chip |

## 6. Workflow-To-Surface Mapping

| Workflow | Persona | Product surface | Required visible proof | Loom APIs/rules/events | Test/evidence IDs |
| --- | --- | --- | --- | --- | --- |
| member-ad-off-purchase | member | Purchase/entitlement | price, receipt, active ad-off | Wallet/ads/receipts | B16/B25 |
| owner-ad-off-funding | owner | Funding/settlement | funding amount, utility allocation | Settlement/utility | B16/B25 |

## 7. Persona And State Matrix

| Workflow | Actor state | Receiver state | Read-only state | Disabled/hidden state | Unauthorized behavior |
| --- | --- | --- | --- | --- | --- |
| ad-off purchase | member pays | shell suppresses eligible ads | receipt is read-only | buy disabled when active | non-payer cannot manage receipt |

## 8. Content And Seed Data Requirements

Use prices, receipt IDs, entitlement dates, ad suppression state, settlement IDs, and utility allocation
details.

## 9. Visual And Interaction Standard

Use trust-first payment surfaces with clear hierarchy, receipt details, and no ambiguity about ads or
funding.

### B25 Semantic Interaction Models

This B25 addendum defines the production interaction model the UI must prove from fresh after-screenshot evidence. A workflow cannot pass with only a happy-path action; it must show the expected decision, required primary action, alternate/change/reject path, durable result state, and receiver or continuation state.

| Workflow | Persona | Expected decision | Required primary actions | Required alternate/change/reject actions | Result and receiver state |
| --- | --- | --- | --- | --- | --- |
| ad-off-member-checkout | member | Payer decides what amount or entitlement to pay for, sees cost/recipient/visibility, and can change or manage the payment. | pay, donate, give, checkout, subscribe | change amount, edit payment, manage, cancel subscription, refund, retry payment | Fresh screenshots must show status, receipt/history/confirmation, and any receiver or continuation state for this persona. |
| ad-off-community-checkout | member | Payer decides what amount or entitlement to pay for, sees cost/recipient/visibility, and can change or manage the payment. | pay, donate, give, checkout, subscribe | change amount, edit payment, manage, cancel subscription, refund, retry payment | Fresh screenshots must show status, receipt/history/confirmation, and any receiver or continuation state for this persona. |
| ad-off-entitlement-status | member | Payer decides what amount or entitlement to pay for, sees cost/recipient/visibility, and can change or manage the payment. | pay, donate, give, checkout, subscribe | change amount, edit payment, manage, cancel subscription, refund, retry payment | Fresh screenshots must show status, receipt/history/confirmation, and any receiver or continuation state for this persona. |
| ad-off-receipt-evidence | member | Payer decides what amount or entitlement to pay for, sees cost/recipient/visibility, and can change or manage the payment. | pay, donate, give, checkout, subscribe | change amount, edit payment, manage, cancel subscription, refund, retry payment | Fresh screenshots must show status, receipt/history/confirmation, and any receiver or continuation state for this persona. |
| ad-off-ad-suppression | member | Payer decides what amount or entitlement to pay for, sees cost/recipient/visibility, and can change or manage the payment. | pay, donate, give, checkout, subscribe | change amount, edit payment, manage, cancel subscription, refund, retry payment | Fresh screenshots must show status, receipt/history/confirmation, and any receiver or continuation state for this persona. |
| ad-off-settlement-utility | member | Payer decides what amount or entitlement to pay for, sees cost/recipient/visibility, and can change or manage the payment. | pay, donate, give, checkout, subscribe | change amount, edit payment, manage, cancel subscription, refund, retry payment | Fresh screenshots must show status, receipt/history/confirmation, and any receiver or continuation state for this persona. |


## 10. Review And Remediation Log

| Review run | Product-spec gap? | Implementation gap? | Product doc changes | UI changes required | Status |
| --- | --- | --- | --- | --- | --- |
| B25 next pass | no | pending review | Added semantic interaction model addendum. | Use documented primary and alternate actions in the UI, then recapture screenshots. | open |
