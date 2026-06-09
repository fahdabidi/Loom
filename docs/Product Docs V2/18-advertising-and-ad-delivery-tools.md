# Loom Communities Product Definition 18: Advertising and Ad-Delivery Tools

Status: Draft for review
Product area: 18 of 22 (Loom Communities / V2)
Source inputs: [API Reference 1.18](./Extensible%20Loom%20API%20Reference.md#118-ads--ad-off-api)
Predecessor: [Loom V1 Brand/Sponsor/Advertiser Tools](../Product%20Docs/18-brand-sponsor-advertiser-tools.md)

## 1. Product Definition

Advertising in V2 funds the free backend while respecting community policy, member consent, protected
data, and required App Shell structure. Ad tools include ad inventory configuration, category/brand
policy, advertiser approval, creative review, ad decisioning, campaign delivery, reporting, receipts,
ad-off checks, sensitive-context no-fill, and settlement.

This doc covers ad product and tools; Architecture V2 11 covers ad-delivery internals.

## 2. Scope

This area covers shell banner ads, in-stream ad items, community/creator ad policy, advertiser console,
creative review, campaign setup, targeting constraints, contextual categories, frequency caps, ad-off
entitlements, sensitive context exclusions, ad receipts, fraud controls, reporting, and settlement.

## 3. Key Features and Differentiators

| Feature | Definition | Product value | Interacting areas |
| --- | --- | --- | --- |
| Shell banner inventory | App Shell-owned top ad slot. | Free backend funding cannot be removed by extensions. | 09, 15 |
| In-stream inventory | Stream renderer injects disclosed ad items. | Ads fit community feeds without extension control. | 15 |
| Community ad policy | Owners block categories, brands, formats, and surfaces within platform constraints. | Communities maintain values and trust. | 17 |
| Sensitive no-fill | Care/minor/donor/safety/protected contexts return no ad. | Ads do not exploit sensitive data. | 14 |
| Ad-off checks | Member/community entitlements suppress eligible ads. | Paid path is enforceable. | 08, 09 |
| Ad receipts | Impressions, fills, no-fills, clicks/conversions where allowed, and settlement evidence. | Ad economics are auditable. | 08, 22 |
| Advertiser tools | Campaign setup, creative, policy, reporting, and billing. | Advertisers can participate without raw member data. | 19 |

## 4. Product Experience Requirements

Owners should configure blocked categories and see ad-off options. Members should see disclosures,
ad-off controls, and why ads are absent in paid or sensitive contexts. Advertisers should configure
campaigns using contextual/community-safe criteria, not raw protected data. Governance should review
creative, policy, fraud, and incidents.

## 5. User Stories

1. **As an owner**, I block alcohol and gambling ads.
   End state: ad decisions respect community policy.
2. **As a member**, I buy ad-off.
   End state: eligible ads are suppressed and receipts record no-ad usage.
3. **As an advertiser**, I run a local sponsor campaign for public community surfaces.
   End state: creative is approved and reporting is aggregate.
4. **As governance**, I detect invalid ad traffic.
   End state: fraud signal adjusts settlement without deleting receipts.
5. **As a parent**, I open a minor medical form with no ads.
   End state: sensitive no-fill applies.

## 6. End-to-End Workflows

### Workflow 1: Ad campaign setup

1. Advertiser creates campaign, creative, budget, schedule, context, geography, and policy category.
2. Creative and advertiser identity are reviewed.
3. Campaign is checked against global policy and eligible community policies.
4. Ads service activates campaign for approved contexts.
5. Reporting and billing use aggregate/ad receipt data.

### Workflow 2: Ad decision

1. App Shell requests fill for banner or stream item with community, surface, context, ad-off state, and
   policy-safe metadata.
2. Ads service checks ad-off, sensitive context, community policy, frequency caps, and campaign rules.
3. Service returns fill or no-fill reason.
4. App Shell renders disclosure or preserves layout on no-fill.
5. Receipt ledger records impression/no-fill/click/conversion where policy allows.

### Workflow 3: Ad-off and settlement

1. Member or community pays for ad-off.
2. Entitlement ledger stores ad-off scope.
3. Ads service suppresses eligible ads.
4. Receipt ledger records ad-off usage.
5. Settlement allocates ad or ad-off value to communities, apps, providers, and utilities.

## 7. Cross-Area Requirements

- Advertisers never receive raw protected vault data or private member graphs.
- Ad inventory cannot be hidden by extensions.
- Community policy can narrow but not remove required free-tier ad inventory.
- Sensitive contexts always return no-fill.
- Ad receipts and fraud signals must feed settlement.

## 8. Prototype Implications

The MVP should implement fake ad campaign data, ad decision API, shell banner, stream ad item, category
blocklist, ad-off entitlement, no-fill for protected contexts, and receipt/fraud stubs.

## 9. FAQ

**Are ads targeted with member behavior?**
MVP should use contextual/community-safe signals and explicit policies, not protected or hidden member
behavior.

**Can a sponsor buy placement inside private care spaces?**
No. Sensitive contexts are excluded.

## 10. Open Questions

- Which ad formats are allowed at launch?
- How should local community sponsorship differ from platform ads?
- What reporting threshold protects small communities from re-identification?
