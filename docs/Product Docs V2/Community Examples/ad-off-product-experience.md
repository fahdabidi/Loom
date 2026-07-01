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

## 3.1 Persona Tabs, Pins, And Customization

| Persona | Required tabs | Pinned surfaces | Customization notes |
| --- | --- | --- | --- |
| Member | Home, Ad-Free, Receipts, Messages | entitlement status, renewal date, suppressed ad slots | Account-style palette, receipt clarity, restore/manage actions. |
| Owner/operator | Home, Ad-Free, Settlement, Documents, Messages | settlement review, allocation corrections, audit export | Operator tabs expose settlement and correction surfaces hidden from members. |

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
| ad-off-member-checkout | member | Member checkout | price, payer, payment method, review step, receipt, active entitlement | Wallet/ads/receipts | B16/B25 |
| ad-off-community-checkout | member | Community ad-off funding | funded coverage, community payer context, review step, settlement status | Wallet/settlement/ads | B16/B25 |
| ad-off-entitlement-status | member | Entitlement status | active/inactive state, renewal/expiry, managed subscription, affected ad surfaces | Ads/entitlements | B16/B25 |
| ad-off-receipt-evidence | member | Receipt evidence | receipt ID, amount, payer, date, entitlement link, export/view action | Receipts/audit | B16/B25 |
| ad-off-ad-suppression | member | Ad suppression proof | suppressed surface, no-fill/ad-off reason, restoration/manage path | Ads/ad decision | B16/B25 |
| ad-off-settlement-utility | member | Utility allocation | funded amount, settlement ID, utility impact, audit status | Settlement/utility | B16/B25 |

## 7. Persona And State Matrix

| Workflow | Actor state | Receiver state | Read-only state | Disabled/hidden state | Unauthorized behavior |
| --- | --- | --- | --- | --- | --- |
| ad-off-member-checkout | member pays for personal ad-off | shell suppresses eligible ads after confirmation | receipt remains readable/exportable | checkout disabled when active until manage path | non-payer cannot manage receipt |
| ad-off-community-checkout | member funds community ad-off | members see funded ad-off status where eligible | funding record readable | duplicate funding disabled during active period | non-owner cannot alter settlement record |
| ad-off-entitlement-status | member manages entitlement | shell/ad slots honor active state | entitlement status readable | manage disabled when no entitlement | other members cannot view private payment details |
| ad-off-receipt-evidence | member views receipt | receipt can be exported/shared as allowed | issued receipt read-only | refund/manage disabled unless eligible | non-payer cannot view receipt |
| ad-off-ad-suppression | member sees suppressed ad surface | ad decision records suppression | no-fill/ad-off reason readable | ad click hidden while suppressed | extension cannot bypass entitlement |
| ad-off-settlement-utility | member reviews utility allocation | owner/settlement records show funded utility | allocation audit readable | edit disabled after settlement | non-owner cannot mutate settlement |

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


### B25 Card Surface Registry Mapping

This B25 advisory registry maps each documented community workflow to the canonical card surface family, OpenAPI contract, required interactions/actions, and Demo App renderer/fake-backend support expected by remediation. It is used as implementation context only; B25 does not yet enforce this as a standalone card-surface/API coverage gate.

| Workflow | Card surface family | API contract | Required interactions/actions | Renderer/fake-backend support |
| --- | --- | --- | --- | --- |
| `ad-off-member-checkout` | [payment](../../CardSurfaces/payment-donation-dues-ad-off.md) | `CommunityPaymentSurfaceApi` | intent/confirm/retry, receipt/refund, recurring/entitlement, settlement state | Demo renderer must show price, payer, payment method, review, confirm, receipt, manage/change, and active entitlement. |
| `ad-off-community-checkout` | [payment](../../CardSurfaces/payment-donation-dues-ad-off.md) | `CommunityPaymentSurfaceApi` | community funding intent/confirm/retry, settlement, utility allocation | Demo renderer must show funded coverage, community payer, review/confirm, settlement, and utility allocation. |
| `ad-off-entitlement-status` | [ad-off-entitlement](../../CardSurfaces/ads-no-fill-ad-off.md) | `CommunityAdSurfaceApi` | entitlement active/inactive, renewal, restore/manage, affected surfaces | Demo renderer must show active state, renewal, manage/cancel, and surfaces affected. |
| `ad-off-receipt-evidence` | [receipt](../../CardSurfaces/payment-donation-dues-ad-off.md) | `CommunityPaymentSurfaceApi` | receipt lookup/export/refund eligibility, audit trail | Demo renderer must show receipt ID, amount, payer, date, view/export, and entitlement link. |
| `ad-off-ad-suppression` | [ad](../../CardSurfaces/ads-no-fill-ad-off.md) | `CommunityAdSurfaceApi` | ad-off suppression/no-fill reason, restore/receipt evidence | Demo renderer must show suppressed slot, reason, manage/restore path, and no content overlap. |
| `ad-off-settlement-utility` | [settlement](../../CardSurfaces/payment-donation-dues-ad-off.md) | `CommunityPaymentSurfaceApi` | settlement status, utility allocation, audit | Demo renderer must show settlement ID, funded utility amount, allocation status, and audit state. |

## 10. Review And Remediation Log

| Review run | Product-spec gap? | Implementation gap? | Product doc changes | UI changes required | Status |
| --- | --- | --- | --- | --- | --- |
| B25 next pass | no | pending review | Added semantic interaction model addendum. | Use documented primary and alternate actions in the UI, then recapture screenshots. | open |
