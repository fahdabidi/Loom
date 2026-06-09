# Loom Communities Product Definition 19: Governance, Extension Certification, and Foundation Model

Status: Draft for review
Product area: 19 of 22 (Loom Communities / V2)
Source inputs: [Core Thesis V2](./01-core-thesis-and-platform-principles.md), [API Reference 2.10-2.11](./Extensible%20Loom%20API%20Reference.md)
Predecessor: [Loom V1 Governance, Certification, and Foundation Model](../Product%20Docs/19-governance-certification-and-foundation-model.md)

## 1. Product Definition

Governance protects Loom's interoperability, safety, portability, and trust boundary. The foundation or
governance body owns protocol standards, certification rules, public registries, conformance tests,
policy versions, key management, disputes, incidents, and enforcement. Commercial providers, builders,
advertisers, and app operators can participate, but none should control the rules.

V2 adds extension certification as a central governance responsibility because AI-generated packages
can change the member experience rapidly.

## 2. Scope

This area covers foundation model, protocol governance, API and manifest versioning, provider
certification, app certification, extension certification, conformance tests, public registries, signing
keys, policy versions, incident reports, disputes, appeals, audit, utility funding oversight, and
certification marks.

## 3. Key Features and Differentiators

| Feature | Definition | Product value | Interacting areas |
| --- | --- | --- | --- |
| Neutral foundation | Stewardship separated from commercial providers. | Prevents protocol capture. | 22 |
| Capability certification | Certification scoped by actor, role, API, version, geography, data class, and risk tier. | Precise trust and revocation. | 07, 16 |
| Extension certification | Validates manifests, permissions, UI invariants, data rights, ads, export, tests, and supply chain. | AI-built apps can be trusted. | 10, 11 |
| Public registries | Published status for providers, apps, extensions, keys, incidents, and API versions. | Ecosystem transparency. | 17 |
| Dispute resolution | Handles payouts, data misuse, moderation, takedowns, export, provider issues, and certification appeals. | Enforcement is accountable. | 08, 14 |
| Policy/version governance | Changes have deprecation windows, tests, and migration guidance. | Builders and communities can keep working. | 16, 21 |

## 4. Product Experience Requirements

Owners and members should see certification status and risk tier before trusting an extension,
provider, advertiser, or app. Builders should get clear certification output and appeal paths.
Governance should be able to revoke narrowly and provide incident transparency without overexposing
sensitive evidence.

## 5. Certification Tiers

| Tier | Extension/provider behavior | Review level |
| --- | --- | --- |
| 0 | Theme/content-only package. | Automated lint. |
| 1 | Read public/community-visible data. | Automated conformance. |
| 2 | Writes ordinary community records. | Automated tests + export checks. |
| 3 | Payments, ads, roles, workflows, or messaging automation. | Manual or enhanced review. |
| 4 | Minors, protected vault, donor/care data, or safety contexts. | Strict review and monitoring. |
| 5 | External connectors, sandboxed functions, or high-risk providers. | Security review and ongoing audit. |

## 6. User Stories

1. **As governance**, I certify an extension that uses payments and protected data.
   End state: risk tier, restrictions, and tests are recorded.
2. **As an owner**, I see why an extension is high risk before installing.
   End state: install screen shows certification facts.
3. **As a provider**, I certify one role without certifying all roles.
   End state: certification scope is precise.
4. **As a member**, I trust that revoked extensions stop running.
   End state: App Shell fails closed.
5. **As a builder**, I appeal a rejected certification decision.
   End state: dispute process records evidence and outcome.

## 7. End-to-End Workflows

### Workflow 1: Extension certification

1. Builder submits signed package version and evidence.
2. Certification validates manifest, permissions, tests, shell invariants, ads, data rights, export, and
   supply chain.
3. Risk tier is assigned.
4. Manual review runs for higher-risk tiers.
5. Approved, limited, rejected, or revoked status is written to registry.

### Workflow 2: API version governance

1. Proposal identifies API/manifest change and compatibility impact.
2. Conformance tests and fakes update.
3. Deprecation and migration windows are published.
4. Providers/apps/extensions certify new version.
5. Registries expose compatibility matrix.

### Workflow 3: Dispute and appeal

1. Actor files dispute about certification, payout, moderation, export, or incident.
2. Governance gathers receipts, audit, policies, manifests, keys, and evidence.
3. Decision is issued with policy version and remediation.
4. Registries, settlement, runtime, or export systems update.
5. Appeal window and public/private record rules apply.

## 8. Cross-Area Requirements

- Certification is contract/test-backed, not discretionary only.
- Revocation must propagate to runtime and App Shell quickly.
- Public records must balance transparency with protected data redaction.
- Governance must maintain fakes/conformance tests used by builders and phase gates.
- Foundation funding must not compromise neutral search, certification, or portability.

## 9. Prototype Implications

The MVP needs certification records, risk tiers, validator output, public registry read model, key status
stub, extension/provider/app status checks, and one dispute workflow. Full legal foundation formation
can be represented by policy docs and registry state.

## 10. FAQ

**Is certification one global approval?**
No. It is scoped by actor, capability, version, data class, geography, and risk.

**Who can change APIs?**
Governance controls protocol changes through published versioning, tests, and migration windows.

## 11. Open Questions

- What governance body exists at launch versus later?
- Which certification tiers require manual review in MVP?
- What public registry fields are safe to expose?
