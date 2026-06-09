# Loom Communities Product Definition 06: Hosting Provider Lifecycle and Portability

Status: Draft for review
Product area: 06 of 22 (Loom Communities / V2)
Source inputs: [Core Thesis V2](./01-core-thesis-and-platform-principles.md), [API Reference 1.17](./Extensible%20Loom%20API%20Reference.md#117-import-export-migration--provider-portability-apis)
Predecessor: [Loom V1 Hosting Provider Lifecycle and Progressive Unbundling](../Product%20Docs/06-hosting-provider-lifecycle-and-progressive-unbundling.md)

## 1. Product Definition

Hosting in V2 is community-scoped. A community may start on Loom-managed infrastructure, use a certified
provider for files/media/data/compute, move to a direct paid provider, or export and migrate later. The
owner experience must feel simple, but the underlying provider boundary must remain explicit,
certified, portable, auditable, and replaceable.

The default V2 business stance is a free backend funded by mandatory ad surfaces unless the community or
member pays for ad-off. Hosting therefore includes both operational infrastructure and the policy that a
provider cannot remove platform invariants such as export, receipts, audit, ad surfaces, or required App
Shell structure.

## 2. Scope

This area covers hosting roles, provider lifecycle, managed/free hosting, direct paid hosting, provider
switching, export packages, migration plans, data residency, provider incidents, portability scorecards,
and community-visible hosting terms. Provider marketplace details are Product 07; migration from
external tools is Product 21.

## 3. Key Features and Differentiators

| Feature | Definition | Product value | Interacting areas |
| --- | --- | --- | --- |
| Managed free backend | Loom or a certified provider hosts the basic backend with ad-supported economics. | Owners can start without upfront infrastructure cost. | 09, 22 |
| Provider roles | Data, files, media, search, AI, payments, receipts, export, and compute can be separate roles. | Providers compete without owning the whole community. | 07, 19 |
| Portability class | Each data class declares export/migration behavior, cost, SLA, and limitations. | Owners can evaluate lock-in before choosing a provider. | 14, 21 |
| Migration plan | Versioned plan with source, destination, data classes, checksums, downtime, and rollback. | Provider exit is operational, not just aspirational. | 10, 19 |
| Provider scorecard | Uptime, conformance, incidents, export time, support, cost, and community fit. | Marketplace comparison is transparent. | 07 |
| Incident and suspension path | Limited, suspended, or revoked providers fail closed and trigger migration options. | Communities are protected from provider abuse or failure. | 17, 19 |

## 4. Hosting Tiers

| Tier | Typical user | Included | Constraints |
| --- | --- | --- | --- |
| Free managed | New or small communities | Core APIs, App Shell, storage limits, receipts, export, mandatory ads. | Ads required unless paid ad-off applies. |
| Growth managed | Growing communities | Higher limits, support, optional paid features. | Still certified and portable. |
| Direct paid provider | Mature communities | Chosen provider with direct cost or negotiated terms. | Must pass certification and export rules. |
| Self-hosted/certified | Advanced institutions | Community-controlled deployment or provider relationship. | Certification, audit, and key management still apply. |

## 5. Product Experience Requirements

Owners should see hosting terms before launch: cost, free/ad-supported state, export obligations,
limits, data residency, support, and scorecard. Provider changes should be explainable and reversible
where possible. Members should not lose Passport, entitlements, receipts, or grants when hosting
changes. Extensions should not depend on provider-specific APIs unless certified connectors are
declared.

## 6. User Stories

1. **As a new owner**, I start on the free managed backend.
   End state: community is live, export policy exists, and mandatory ad surfaces are active.
2. **As a growing HOA**, I move files to a higher-capacity certified provider.
   End state: documents migrate and App Shell continues to work.
3. **As governance**, I suspend a provider after a data export failure.
   End state: marketplace state changes and affected communities get migration options.
4. **As a member**, I keep my Passport and receipts when a community switches host.
   End state: member identity and wallet state remain portable.
5. **As an extension**, I run against Loom APIs without host-specific coupling.
   End state: extension continues after provider switch.

## 7. End-to-End Workflows

### Workflow 1: Start on managed hosting

1. Owner creates community and accepts managed hosting terms.
2. Provider capability registry assigns default providers for required roles.
3. Community registry stores hosting pointers and portability classes.
4. App Shell and extensions receive standard Loom API endpoints.
5. Export and audit obligations are active from day one.

### Workflow 2: Switch provider role

1. Owner selects a new certified provider role, such as documents or media.
2. System validates certification scope, geography, cost, and compatibility.
3. Migration plan is generated with data classes, checksums, dry-run output, and rollback.
4. Owner approves downtime and cost.
5. Import/export system migrates data, verifies integrity, updates pointers, and records receipts.

### Workflow 3: Provider incident

1. Incident report or audit probe detects issue.
2. Governance marks provider limited, suspended, or revoked by role/capability.
3. Runtime and App Shell fail closed where keys or endpoints are invalid.
4. Affected owners receive migration, remediation, and dispute options.
5. Public scorecard and incident history update.

## 8. Cross-Area Requirements

- Provider choices must never bypass identity, consent, ads, receipts, audit, export, or certification.
- Extensions target Loom contracts and fakes, not provider-specific private APIs.
- Migration packages must include extension custom data where export policy allows.
- Hosting terms and scorecards must be visible to owners before and after selection.

## 9. Prototype Implications

The MVP should simulate provider roles and switching using local fakes: registry pointers, export
packages, migration receipts, and scorecard state. Real cloud migration can be deferred, but the data
model and owner-facing controls should be present.

## 10. FAQ

**Do communities need a provider marketplace in V2?**
Yes, but it can be narrower than V1 at first. Communities need at least visible provider roles,
certification state, and portability terms so hosting does not become hidden lock-in.

**Can a provider remove ads for a free community?**
No. Free hosting economics require the mandatory app-shell and in-stream ad surfaces unless the paid
ad-off path applies.

## 11. Open Questions

- Which provider roles are real in MVP versus represented by fakes?
- Should self-hosting be allowed before governance and conformance are mature?
- What export SLA is acceptable for small versus large communities?
