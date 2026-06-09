# Loom Communities Product Definition 22: Business Model and Incentive Design

Status: Draft for review
Product area: 22 of 22 (Loom Communities / V2)
Source inputs: [Extensible Loom Product Definition 10](./Extensible%20Loom%20Product%20Definition.md#10-monetization--business-model)
Predecessor: [Loom V1 Business Model and Incentive Design](../Product%20Docs/22-business-model-and-incentive-design.md)

## 1. Product Definition

Loom Communities' business model should make the platform easy to adopt while preserving portability,
data rights, governance, and provider competition. The initial wedge is a free backend funded by
mandatory ads, with paid ad-off and premium/community payments as clear upgrade paths.

The model should reward communities, builders, providers, apps, advertisers, and shared utilities for
creating value without recreating a locked, extractive platform.

## 2. Scope

This area covers free backend economics, ad and ad-off revenue, community subscriptions, dues/donations
processing, extension marketplace fees, builder payouts, provider fees, advertiser spend, certification
fees, utility funding, settlement allocation, and incentive guardrails for search, data, AI, export,
ads, and governance.

## 3. Key Features and Differentiators

| Feature | Definition | Product value | Interacting areas |
| --- | --- | --- | --- |
| Free backend | No upfront community backend fee; ads fund shared infrastructure. | Adoption wedge for small communities. | 06, 09 |
| Ad-off | Member or owner pays to suppress eligible ads. | Clear paid value and user choice. | 08, 18 |
| Community payments | Dues, donations, tickets, events, facilities, and paid services. | Communities can operate on Loom. | 08 |
| Extension marketplace | Builders can sell or support extensions. | Ecosystem grows beyond internal team. | 10, 16 |
| Provider competition | Providers earn for certified roles, not lock-in. | Portability and quality improve. | 07 |
| Utility funding | Identity, vaults, search, receipts, settlement, and governance funded transparently. | Shared primitives remain sustainable. | 19 |
| Incentive guardrails | No paid search ranking, protected-data exploitation, export friction, or ad-invariant bypass. | Trust remains economically reinforced. | 13, 14, 17 |

## 4. Revenue Participants

| Participant | Revenue / cost path |
| --- | --- |
| Communities | Dues, donations, events, facilities, commerce, sponsorships, grants, and owner-paid ad-off. |
| Members | Pay for dues, donations, tickets, memberships, ad-off, premium private mode, and optional services. |
| Builders | Extension sales, customization, support, templates, marketplace revenue, and agency services. |
| Providers | Hosting, storage, AI, search, payments, ads, export/migration, and support services. |
| Advertisers/sponsors | Contextual ads, local sponsorships, product cards, campaign delivery, and aggregate reporting. |
| Foundation/utilities | Utility fees, certification fees, marketplace fees, enterprise support, grants, and governed allocations. |

## 5. Incentive Guardrails

- Search cannot use paid ranking, paid routing, merge priority, or per-click monetization.
- Extensions cannot monetize by bypassing App Shell ads, payments, consent, or protected data.
- Providers cannot earn through export friction; export fees must be predeclared, cost-based, capped,
  receipt-backed, scorecard-visible, and disputeable.
- Advertisers cannot use protected vault data or hidden member behavior.
- AI providers cannot train or retain data beyond explicit policy.
- Certification and governance funding must remain independent enough to avoid capture.
- Settlement follows manifests and receipts, not opaque platform discretion.

## 6. Product Experience Requirements

Owners should understand free versus paid options, ad-off pricing, payment fees, provider costs,
extension costs, and export costs. Members should understand what they pay for and what data/ad tradeoff
applies. Builders and providers should see transparent economics and requirements. Governance should be
able to publish utility budgets and fee policies.

## 7. User Stories

1. **As a new owner**, I start for free and accept ads.
   End state: backend is live, required ads are enabled, and ad-off pricing is visible.
2. **As a member**, I pay for ad-off.
   End state: entitlement suppresses eligible ads and settlement allocates value.
3. **As a builder**, I sell an HOA extension template.
   End state: marketplace fee and builder payout are recorded.
4. **As a provider**, I earn for certified document hosting without owning identity.
   End state: provider statements follow receipts and service terms.
5. **As governance**, I publish utility fee allocation.
   End state: shared infrastructure funding is transparent.

## 8. End-to-End Workflows

### Workflow 1: Free backend economics

1. Owner chooses free managed backend.
2. Required ad surfaces are enabled and certified.
3. Ads generate impression/fill/no-fill receipts.
4. Settlement allocates revenue to providers, utilities, apps, and communities where policy allows.
5. Owner can upgrade to community ad-off.

### Workflow 2: Extension marketplace payout

1. Builder lists certified extension or template.
2. Owner buys or subscribes.
3. Payment receipt records purchase.
4. Settlement allocates marketplace fee, builder payout, taxes/reserves, and utility fees.
5. Extension remains exportable and uninstallable.

### Workflow 3: Provider/service utility funding

1. Provider emits service usage receipts.
2. Utility funding policy applies caps and allocation rules.
3. Settlement produces provider, utility, and community statements.
4. Scorecard and export obligations remain visible.

## 9. Cross-Area Requirements

- Business model must reinforce portability, not punish it.
- Search and data rights are protected from monetization pressure.
- Ads/ad-off must integrate with wallet, entitlements, receipts, and settlement.
- Provider and builder economics require certification and audit.
- Foundation utility funding must be transparent and governed.

## 10. Prototype Implications

The MVP should simulate ad revenue, ad-off payment, extension marketplace fee, provider service fee,
dues/donations, and utility allocation in the settlement simulator. The important proof is transparent
receipts and guardrails, not real external payouts.

## 11. FAQ

**Why lead with free backend plus ads?**
It removes the biggest adoption barrier for small communities while preserving a paid path for those
that want fewer ads.

**Can search become an ad product later?**
Not under the V2 principles. Ads belong in disclosed ad surfaces, not search ranking.

## 12. Open Questions

- What ad-off price and provider allocation are viable?
- Which extension marketplace fees should apply before external builders arrive?
- How should utility budgets be published and governed at launch?
