# Loom Communities Product Definition 09: Monetization: Free Backend, Ads, and Ad-Off

Status: Draft for review
Product area: 09 of 22 (Loom Communities / V2)
Source inputs: [Extensible Loom Product Definition 10](./Extensible%20Loom%20Product%20Definition.md#10-monetization--business-model), [API Reference 1.18](./Extensible%20Loom%20API%20Reference.md#118-ads--ad-off-api)
Predecessor: [Loom V1 Monetization Models](../Product%20Docs/09-monetization-models.md)

## 1. Product Definition

V2 monetization starts with a simple owner promise: the backend can be free. In return, the Main Loom
App enforces platform ad inventory that a community extension cannot remove: a top App Shell ad banner
and in-stream ad items. A community owner or member can pay to turn ads off through approved ad-off
products, but free communities cannot design ads out of the required structure.

This model funds shared infrastructure while keeping owners from paying upfront and while preserving
member choice through ad-off, subscriptions, and premium paths.

## 2. Scope

This area covers free backend economics, mandatory ad surfaces, ad-off products, owner-paid and
member-paid ad removal, premium/private modes, revenue allocation, ad eligibility guardrails, and
extension certification requirements. Ad operations and advertiser tooling are Product 18; ad delivery
internals are Architecture V2 11.

## 3. Key Features and Differentiators

| Feature | Definition | Product value | Interacting areas |
| --- | --- | --- | --- |
| Free backend | Core community backend starts without owner infrastructure fees. | Lowers adoption friction for small communities. | 06, 22 |
| Mandatory shell banner | App Shell owns top ad surface outside extension control. | Extensions cannot remove platform funding inventory. | 15, 18 |
| In-stream ad items | Stream renderer injects `StreamItem{kind: ad}` between content items. | Ads integrate without raw extension placement control. | 15, 18 |
| Ad-off products | Member or owner pays to suppress eligible ads. | Gives users and communities a clean paid path. | 08, 22 |
| Sensitive-context exclusion | Ads do not appear in care, minor, donor, safety, or protected contexts. | Monetization does not violate trust boundaries. | 14, 17 |
| Creator/community policy | Owners can block categories and brands but cannot remove required free-tier inventory. | Community values are respected while funding remains. | 18 |
| Receipt-backed allocation | Ad impressions, ad-off payments, and settlement produce receipts. | Economics are auditable. | 08, 22 |

## 4. Product Experience Requirements

Owners should understand the free-backend bargain during setup: ads are required unless the community
chooses owner-paid ad-off. Members should see ad disclosures, sensitive-context protections, and
member-paid ad-off options. Builders should know that extensions must reserve required surfaces and
cannot obscure, suppress, or fake ad inventory.

## 5. Monetization Products

| Product | Payer | Effect | Notes |
| --- | --- | --- | --- |
| Free backend with ads | No upfront payer | Required ads active. | Default launch path. |
| Member ad-off | Member | Suppresses eligible ads for that member across allowed surfaces. | Does not remove platform UI requirements. |
| Community ad-off | Owner/community | Suppresses eligible ads for members in that community. | Priced by usage/size. |
| Premium private mode | Member | Narrows data use and ad personalization where applicable. | Uses protected/private data rules. |
| Sponsored/community-approved inventory | Advertiser or sponsor | Shows eligible ads or product placements. | Product 18 owns tooling. |

## 6. User Stories

1. **As an owner**, I launch a community for free and understand where ads appear.
   End state: App Shell includes required ad surfaces and owner sees ad-off pricing.
2. **As a member**, I pay for no ads in my communities.
   End state: ad-off entitlement suppresses eligible ads for that member.
3. **As an owner**, I block gambling ads for a youth soccer club.
   End state: creator/community ad policy excludes the category.
4. **As governance**, I fail an extension that hides ad surfaces.
   End state: certification reports required-structure violation.
5. **As settlement**, I allocate ad and ad-off value to providers, utilities, apps, and communities.
   End state: receipts support allocation.

## 7. End-to-End Workflows

### Workflow 1: Free community launch

1. Owner selects free managed backend.
2. Setup explains mandatory ad surfaces and ad-off options.
3. Community registry records monetization mode.
4. App Shell renders banner and stream renderer accepts ad items.
5. Certification lints installed extensions for ad-surface compliance.

### Workflow 2: Member buys ad-off

1. Member opens ad preferences or payment surface.
2. Wallet presents ad-off price and scope.
3. Payment succeeds and entitlement ledger records `PremiumNoAdEntitlement`.
4. Ads service checks entitlement before fill.
5. Receipt ledger records payment and no-ad usage for settlement.

### Workflow 3: Sensitive-context ad exclusion

1. Member opens protected care, minor, donor, moderation, or dispute context.
2. App Shell passes protected context to ad decision service.
3. Ads service returns no-fill with policy reason.
4. UI preserves layout without showing an ad.
5. Audit/metrics record aggregate exclusion without exposing sensitive detail.

## 8. Cross-Area Requirements

- App Shell ad banner and in-stream ad item support are platform invariants.
- Extensions cannot hide, overlay, simulate, or intercept ad surfaces.
- Ad decisions must use policy-safe context, not protected raw data.
- Ad-off entitlements and receipts must integrate with wallet and settlement.
- Owners can define category/brand exclusions but cannot remove free-tier inventory.

## 9. Prototype Implications

The MVP must include visible ad slots, certification lint for required surfaces, a fake ad decision
service, ad-off entitlement simulation, no-fill for protected contexts, and receipt records for ad and
ad-off events. Real ad marketplace fill can be stubbed.

## 10. FAQ

**Can a community use Loom without ads?**
Yes, through owner-paid or member-paid ad-off. Free managed communities keep ads.

**Can extensions choose their own ad layout?**
No. Extensions can provide content surfaces; the App Shell and stream renderer own required ad slots.

## 11. Open Questions

- What is the launch pricing model for community ad-off?
- Which ad categories are globally prohibited versus community-configurable?
- How should ad-off value be allocated across communities a member uses?
