# Ad-Off Product Experience

> **Correction, 2026-08-10 (Community JSON Migration effort, `docs/Build Plan V2/Community JSON Migration
> Tracker.md` §3):** three gaps found during this doc's reconciliation pass, to resolve at JSON-authoring
> time:
> - §2 is missing an **Ad-Free Viewer** persona row — every workflow's §7 row describes a materially
>   different experience once entitlement is active ("shell/ad slots honor active state", ads suppressed)
>   than a Member who hasn't purchased ad-off and still sees ads. Added below as its own row rather than
>   folded silently into the general Member persona.
> - §3.1 requires a `Settlement` tab (and reuses `Ad-Free`/`Receipts`/`Documents`), none of which exist in
>   the real, closed `tabId` enum (`docs/references/reference/render-bindings.md`: only
>   admin/calendar/giving/home/marketplace/messages are real). The engine-native JSON must remap this doc's
>   purchase/entitlement/receipt/settlement surfaces onto real tabs — `giving` is the natural fit for
>   purchase/receipt (it already exists for exactly this kind of payment surface), `admin`/`home` for
>   settlement/entitlement-management — the same structural constraint already resolved this migration
>   effort for Cedar Commons HOA, Camera Club, and others.
> - The B25 Card Surface Registry Mapping table below links to `../../CardSurfaces/*` files — confirmed
>   (same as every other community doc this migration effort has touched) to be a superseded vocabulary that
>   doesn't correspond to the 13 real archetypes (9 original + `table`/`documentLibrary`/`searchAiAnswer`/`exportWizard`, promoted 2026-08-11) (`docs/references/archetypes/README.md`; `paymentCheckout`
>   is the real generic fit for every workflow in this doc). Treat the `Card surface family` column as
>   historical context only.
>
> **AP-6 reminder for whoever authors the JSON:** none of `ad-off-receipt-evidence`'s receipt ID,
> `ad-off-settlement-utility`'s settlement ID, or any payment-confirmation value may be fabricated — payment
> processing and receipt/ID generation are `❌ Not implemented` platform services
> (`docs/references/reference/platform-services.md`). Model the state/status honestly; leave any
> would-be-backend-computed value unset or explicitly marked as a gap, the same pattern already used for
> every other community's export-checksum fields this migration effort has touched.

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
| Member | Buy and manage personal ad-off | Remove ads; review private entitlement, receipt, refund, restoration, and suppression state. | Personal payment, entitlement, receipt, and suppression details are private to the payer, with Owner access for verified outcome handling. | Eligible ads are suppressed while entitlement is active, and the member can see and manage the linked evidence. |
| Owner | Set up the community; fund and audit community ad-off | Fund community-wide ad-off; record externally verified outcomes; review settlement, correction, refund, and utility-allocation evidence. | Community admission authority remains entirely in App Access and is never encoded as a workflow. Payment processing and opaque identifiers are platform-service gaps. | Community funding, coverage, settlement, correction, refund, and audit states are clear. |

“Ad-Free Viewer” is a runtime condition, not a role: a person holding `ad-off-member` becomes an ad-free viewer while their entitlement is active. It is represented by `ad-off-entitlement-status` and `ad-off-ad-suppression`, never by a third `roles[]` entry.

## 3. Information Architecture

| Surface | Purpose | Primary persona | Required content | Primary action |
| --- | --- | --- | --- | --- |
| Ad-off offer | Explain value and price. | Member/owner | price, coverage, duration, disclosure. | Turn off ads |
| Entitlement status | Show active state. | Member | active/inactive, renewal, affected surfaces. | Manage |
| Receipt/settlement | Prove payment allocation. | Member/owner | receipt, settlement, utility funding. | View receipt |

## 3.1 Persona Tabs, Pins, And Customization

| Persona | Required tabs | Pinned surfaces | Customization notes |
| --- | --- | --- | --- |
| Member | Home, Giving, Messages | entitlement status, renewal date, suppressed ad surfaces | Giving contains personal checkout, receipt, and entitlement evidence; Home carries concise entitlement and suppression summaries. Per-person pinning remains an App Shell requirement outside community JSON. |
| Owner/operator | Home, Giving, Admin, Messages | community funding, settlement review, allocation corrections, audit export | Admin contains settlement and correction operations; Giving contains community-funding checkout. Per-role tab ordering and pinning remain App Shell requirements outside community JSON. |

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
| ad-off-member-checkout | member | Personal ad-off checkout | price, payer, payment method, disclosure, review/pending/failure/active/refund/cancel states, linked entitlement continuation | Workflow guards/effects plus external Wallet processing and receipt services | B16/B25 |
| ad-off-community-checkout | owner | Community ad-off funding | funded amount, payer, payment method, coverage, utility allocation, review/pending/failure/funded/refund/cancel states | Workflow guards/effects plus external Wallet/settlement processing | B16/B25 |
| ad-off-entitlement-status | member | Private entitlement status | active/inactive state, renewal/expiry, plan change/restoration decisions, affected ad surfaces | Workflow guards/effects; shell suppression consumes active entitlement | B16/B25 |
| ad-off-receipt-evidence | member | Private receipt evidence | amount, payer, issued/refunded state, entitlement link, view/export/refund actions; opaque receipt ID only when supplied by a real service | Workflow guards/effects plus external receipt/ID generation | B16/B25 |
| ad-off-ad-suppression | member | Private ad-suppression proof | suppressed surfaces, no-fill/ad-off reason, live entitlement-derived suppression state, review/restoration path | Query-backed entitlement state plus workflow guards/effects | B16/B25 |
| ad-off-settlement-utility | owner | Utility allocation and settlement audit | funded amount, coverage, utility impact, allocation, correction/settlement/audit/refund state; opaque settlement ID only when supplied by a real service | Workflow guards/effects plus external settlement/ID generation | B16/B25 |

## 7. Persona And State Matrix

| Workflow | Actor state | Receiver state | Read-only state | Disabled/hidden state | Unauthorized behavior |
| --- | --- | --- | --- | --- | --- |
| ad-off-member-checkout | member starts, edits, submits, retries, cancels, requests/withdraws refund, and can subscribe again | owner records externally verified payment/failure/refund outcomes; confirmation creates entitlement, receipt, and suppression rows | active/refunded history remains privately readable | checkout path is gated by state; disclosure is required before submission | non-payer cannot act on or read the private checkout; non-owner cannot record external outcomes |
| ad-off-community-checkout | owner starts, edits, submits, retries, cancels, and requests/withdraws refund | owner records externally verified funding/refund decisions and creates settlement evidence | funded/refunded history remains readable to the Owner | duplicate paths are state-gated during pending or funded periods | members cannot create or mutate community-funding or settlement records |
| ad-off-entitlement-status | member requests/withdraws plan changes, deactivates, requests/cancels restoration | owner applies/declines plan changes and records/declines restoration | entitlement, renewal/expiry, plan, and affected surfaces remain privately readable | each management action is available only in its matching lifecycle state | other members cannot read or mutate another payer’s entitlement |
| ad-off-receipt-evidence | member views/exports receipt evidence and requests/withdraws a refund | owner attaches a verified receipt link and records/declines verified refund outcomes | issued/refunded evidence remains privately readable | refund action is formula-gated by the declared refund window | non-payer cannot read or act; no role can fabricate a receipt ID |
| ad-off-ad-suppression | member marks proof reviewed, revisits it, and requests restoration when suppression is inactive | entitlement workflow records whether eligible ad surfaces are actively suppressed | no-fill/ad-off reason and affected surfaces remain privately readable | restoration is hidden while entitlement-derived suppression is active; ad click remains absent | extension cannot bypass entitlement; other members cannot read the proof |
| ad-off-settlement-utility | owner requests/applies allocation corrections, records settlement/audit/refund, requests export, and attaches a verified audit link | owner/operator sees the same durable settlement and audit state | settled, audited, and refunded evidence remains readable | correction/settlement paths are lifecycle-gated; identifiers stay empty without a real service | members cannot mutate settlement; no role can fabricate settlement IDs |

## 8. Content And Seed Data Requirements

Use prices, receipt IDs, entitlement dates, ad suppression state, settlement IDs, and utility allocation
details.

## 9. Visual And Interaction Standard

Use trust-first payment surfaces with clear hierarchy, receipt details, and no ambiguity about ads or
funding.


### Notification Delivery

Both channels are offered and both are on by default. An entitlement lapsing, a checkout that needs a
second attempt, or a settlement that has landed are all things a member acts on rather than browses,
and a receipt nobody sees is the same as no receipt.

A member who mutes stops the interruption and keeps the record: the notification still arrives in
the inbox and is there when they look. Muting is not unsubscribing.

### B25 Semantic Interaction Models

This B25 addendum defines the production interaction model the UI must prove from fresh after-screenshot evidence. A workflow cannot pass with only a happy-path action; it must show the expected decision, required primary action, alternate/change/reject path, durable result state, and receiver or continuation state.

| Workflow | Persona | Expected decision | Required primary actions | Required alternate/change/reject actions | Result and receiver state |
| --- | --- | --- | --- | --- | --- |
| ad-off-member-checkout | member | Member decides whether and how to buy personal ad-off after reviewing price, plan, coverage, payment method, and disclosure. | turn off ads, checkout, retry payment | edit payment, cancel checkout, cancel subscription, request refund, withdraw refund request, subscribe again | Screenshots show review/pending/failure/active/refund/cancel states and the resulting private entitlement, receipt, and suppression evidence; Owner-only buttons record external outcomes. |
| ad-off-community-checkout | owner | Owner decides whether and how much to fund for community-wide ad-off after reviewing coverage, utility impact, allocation, and payment method. | give community ad-off, checkout funding, retry payment | change amount or payment, cancel funding, request funding refund, withdraw refund request, try community funding again | Screenshots show pending/failure/funded/refund/cancel states and the resulting settlement/utility record; members have no actionable community-funding instance. |
| ad-off-entitlement-status | member | Member decides whether to manage, deactivate, or restore personal ad-off while seeing plan, renewal/expiry, and affected surfaces. | manage subscription, restore ad-off, keep current plan | deactivate ad-off, cancel restore request | Screenshots show active/change-requested/change-declined/inactive/restoration-pending states; Owner records apply/decline/restore outcomes without exposing another member’s private row. |
| ad-off-receipt-evidence | member | Member decides whether to view/export receipt evidence or request a refund within the visible eligibility window. | view receipt, export receipt, request refund | withdraw refund request | Screenshots show issued/refund-requested/refunded evidence, amount/date/payer/entitlement link, and an openable verified receipt link when externally supplied; opaque receipt ID remains empty without its service. |
| ad-off-ad-suppression | member | Member confirms which surfaces are suppressed and whether to acknowledge the proof or request restoration when entitlement is inactive. | mark reviewed, restore ad-off | review later | Screenshots show suppressed surfaces, the no-fill reason, and entitlement-derived active/inactive suppression proof; no ad-click action appears while suppressed. |
| ad-off-settlement-utility | owner | Owner decides whether allocation is correct and whether to settle, audit, refund, or export the funding record. | record settlement, mark audited, export audit | request correction, apply correction, record refunded allocation | Screenshots show allocated/correction-requested/settled/audited/refunded states, funded amount, coverage, utility impact, allocation, and verified audit link when supplied; opaque settlement ID remains empty without its service. |


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
| Skill-authoring judge pass 1 (2026-08-10) | no | yes (engine bug, CJM.6) | None. | `ad-off-member-checkout`/`ad-off-community-checkout` used `$actor` inside a `scope:"tab"` create action's `prefill`, which the real App Shell never resolves for tab-scoped creates — both checkout entry points were permanently broken (unreadable and/or un-actionable). Fixed by moving the actor-identity stamp into each type's own first transition's `effects` instead (a confirmed-working mechanism), independent of whether CJM.6 itself ever lands. | fixed |
