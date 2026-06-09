# Loom Communities Product Definition 07: Provider Marketplace and Certified APIs

Status: Draft for review
Product area: 07 of 22 (Loom Communities / V2)
Source inputs: [Core Thesis V2](./01-core-thesis-and-platform-principles.md), [API Reference 2.10-2.11](./Extensible%20Loom%20API%20Reference.md#210-extension-certification-tiers)
Predecessor: [Loom V1 Provider Marketplace and Certified APIs](../Product%20Docs/07-provider-marketplace-and-certified-apis.md)

## 1. Product Definition

The provider marketplace lets certified providers offer community infrastructure capabilities through
standard APIs, transparent terms, and public scorecards. Providers compete on cost, quality, geography,
support, specialty, and reliability, not on proprietary lock-in.

For V2, the marketplace is community-scoped: owners choose providers for the capabilities their
community needs, while Loom keeps identity, consent, receipts, audit, export, and App Shell invariants
stable across providers.

## 2. Scope

This area covers provider roles, capability manifests, certified APIs, marketplace listings, scorecards,
conformance tests, role-scoped signing keys, provider terms, incidents, suspension, and owner selection.
It does not cover extension marketplace economics in detail; those belong to Products 10, 16, 19, and
22.

## 3. Key Features and Differentiators

| Feature | Definition | Product value | Interacting areas |
| --- | --- | --- | --- |
| Capability manifest | Provider declares roles, API versions, geography, cost, limits, export obligations, and keys. | Owners can compare providers before selection. | 06, 19 |
| Certified APIs | Providers implement standard contracts and conformance suites. | Provider swapping is feasible. | 16, 19 |
| Marketplace listing | Public listing with capabilities, terms, certifications, incidents, and scorecard. | Reduces opaque vendor selection. | 06, 22 |
| Role-scoped keys | Signing keys are limited by provider, role, API version, and certification state. | Receipt and API trust can be revoked precisely. | 17, 19 |
| Provider scorecard | Uptime, export SLA, incidents, support, cost, conformance, and dispute history. | Incentivizes portability and quality. | 06, 21 |
| Community-specific fit | Listings can filter by vertical: HOA, mosque, youth sports, school, nonprofit, etc. | Communities find providers that understand their constraints. | 20, 21 |

## 4. Product Experience Requirements

Owners should be able to view provider roles currently used by their community, compare alternatives,
understand certification and export implications, switch roles, and file disputes. Providers should be
able to publish manifests, run conformance tests, submit evidence, monitor incidents, rotate keys, and
see marketplace analytics. Members should receive continuity: provider changes should not create new
accounts or erase receipts.

## 5. User Stories

1. **As an owner**, I compare document providers by cost, export SLA, and incident history.
   End state: provider listings show certified capability and portability score.
2. **As a provider**, I certify my reservation service API.
   End state: conformance tests pass and a role-scoped listing is created.
3. **As governance**, I limit a provider's payment role but leave its document role active.
   End state: certification scope changes by role, not as an all-or-nothing ban.
4. **As a member**, I keep access when a community changes search provider.
   End state: App Shell resolves through Loom contracts and no identity migration is required.
5. **As an extension builder**, I rely on fakes and certified contracts instead of private provider SDKs.
   End state: the extension remains provider-neutral.

## 6. End-to-End Workflows

### Workflow 1: Provider certification and listing

1. Provider submits `ProviderCapabilityManifest`, terms, regions, role list, API versions, and evidence.
2. Provider runs conformance tests locally and uploads results.
3. Certification system reruns tests and verifies security, export, audit, and receipt behavior.
4. Governance approves, limits, or rejects the scope.
5. Marketplace listing becomes visible with scorecard, keys, and restrictions.

### Workflow 2: Owner selects provider

1. Owner opens provider settings for a capability role.
2. Marketplace filters by certification, cost, geography, score, vertical fit, and export terms.
3. Owner compares tradeoffs and selects provider.
4. Community registry stores provider role grant and migration/export policy.
5. App Shell and services continue using Loom contracts.

### Workflow 3: Provider key rotation or revocation

1. Provider rotates key or governance detects compromise.
2. Key management records new, limited, suspended, or revoked key status.
3. Receipts and API calls validate against key-time and certification scope.
4. Future invalid signatures fail; historical receipts remain auditable.

## 7. Cross-Area Requirements

- Every provider capability needs a fake for component-phase development and tests.
- Certification is by role, API version, geography, data class, and signing authority.
- Marketplace terms must include export obligations and incident-disclosure rules.
- Provider economics must not reward export friction or ad-invariant bypass.

## 8. Prototype Implications

The MVP can model a small marketplace with faked providers and scorecards for storage, documents,
search/AI, payments, ads, and import/export. The essential proof is that provider roles are explicit
and switchable even before external providers are integrated.

## 9. FAQ

**Is this still needed if Loom runs the default backend?**
Yes. The marketplace prevents managed hosting from becoming permanent lock-in and gives governance a
clear certification vocabulary.

**Can one provider offer many roles?**
Yes, but each role has separate certification scope, scorecard, keys, and suspension state.

## 10. Open Questions

- Which provider categories are launch-critical versus post-MVP?
- Should marketplace listings be public to members or only owners/admins?
- How should provider scorecards account for small-community support quality?
