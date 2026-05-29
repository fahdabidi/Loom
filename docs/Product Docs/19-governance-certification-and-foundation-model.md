# Loom Product Definition 19: Governance, Certification, and Foundation Model

Status: Draft for review  
Product area: 19 of 22  
Depends on: 01 Core Thesis and Platform Principles; 07 Provider Marketplace and Certified APIs; 08 Revenue, Receipts, Ledgers, and Settlement; 10 Creator Plugins / Extensions / Campaign Layer; 11 AI Layer; 13 Neutral Public Search Utility; 14 Audience Data Firewall and Data Rights; 15 Fan Apps and App Ecosystem; 16 Developer Ecosystem and DevOps Supply Chain; 17 Trust, Safety, Fraud, and Compliance; 22 Business Model and Incentive Design

## 1. Product Definition

Loom requires neutral governance to prevent capture by any one provider, app, AI company, hosting company, payment company, sponsor, or creator network. Governance should enforce interoperability, portability, certification, auditability, security, data rights, and fair participation.

The foundation model should separate open protocol stewardship from commercial providers. Providers compete, but they do not unilaterally define portability, certification, settlement, or data-rights rules.

Certification is actor plus capability plus versioned scope. Provider, app, and extension certification are lifecycle categories; AI, search, settlement, clean-room, receipt-signing, and similar functions are role-specific scopes within those categories.

## 2. Scope

This product area covers:

- Neutral foundation.
- Protocol governance.
- API and manifest version governance.
- Provider, app, and extension certification with role-specific scopes for AI, search, settlement, clean-room, receipt-signing, and other capabilities.
- Conformance test governance.
- Certification marks.
- Public registries.
- Audit processes.
- Key management and revocation.
- Marketplace suspension.
- Dispute resolution.
- Incident reporting.
- Utility fee governance.
- Security review.
- Creator/fan/provider/developer representation.

## 3. Key Features and Differentiators

| Feature / differentiator | Definition | Product value | Interacting product areas |
| --- | --- | --- | --- |
| Neutral foundation | Independent steward of protocol and certification. | Reduces platform capture risk. | Core Thesis and Platform Principles |
| Capability certification | Certification by role and API version. | Precise trust instead of blanket approval. | Provider Marketplace and Certified APIs |
| Conformance tests | Standard tests for apps/providers/extensions. | Certification is enforceable. | Developer Ecosystem and DevOps Supply Chain |
| Public registries | Public certification status, keys, incidents, and versions. | Ecosystem trust and transparency. | Trust, Safety, Fraud, and Compliance |
| Version governance | API and manifest changes have migration/deprecation rules. | Prevents ecosystem breakage. | Developer Ecosystem and DevOps Supply Chain |
| Dispute resolution | Handles payouts, takedowns, export, privacy, provider, and campaign disputes. | Makes enforcement accountable. | Revenue, Receipts, Ledgers, and Settlement |
| Data-rights certification | Apps, providers, extensions, and sponsor tools must prove they honor follow visibility, direct-contact grants, export policy, and tombstones. | Prevents open protocol transparency from becoming unrestricted fan-data exposure. | Audience Data Firewall and Data Rights |
| Key revocation | Compromised or abusive actors can be blocked. | Protects receipts and API trust. | Provider Marketplace and Certified APIs |
| Utility fee governance | Shared infrastructure funding is transparent. | Avoids hidden rent extraction. | Business Model and Incentive Design |

## 4. Product Experience Requirements

Governance should provide:

- Clear certification states.
- Capability-level records.
- Public incident reports where appropriate.
- Audit trails.
- Dispute submission and tracking.
- Version migration guides.
- Security advisories.
- Provider/app/extension revocation records.
- Data-rights certification criteria for follower visibility, direct-contact grants, export policy, and creator-scoped deletion.

Creators, fans, providers, and developers should be able to:

- See certification status.
- Understand restrictions.
- File disputes.
- Receive incident notifications.
- Migrate away from suspended providers where possible.

## 5. User Stories

### Story 1: Provider becomes certified

As a provider, I want to become certified so I can participate in the marketplace.

End state:

- Certification scope is recorded.
- Public listing is updated.
- Provider can sign valid receipts for certified roles.

### Story 2: Governance revokes compromised key

As governance, I want to revoke compromised provider keys.

End state:

- Key status changes.
- Apps/providers reject future signatures.
- Incident record is published where appropriate.

### Story 3: Creator disputes provider export failure

As a creator, I want governance support if a provider refuses export.

End state:

- Dispute case is created.
- Provider obligations are checked.
- Remediation or enforcement occurs.

### Story 4: API version changes safely

As a developer, I want clear version migration rules.

End state:

- New API version is published.
- Deprecation window is announced.
- Conformance tests update.

### Story 5: Foundation allocates utility fees

As the ecosystem, we need transparent utility funding.

End state:

- Utility fee policy is published.
- Identity, vaults, search, and settlement funding is explainable.

## 6. End-to-End Workflows

### Workflow 1: Capability certification

Actors:

- Provider/App/Extension Developer
- Developer Console
- Certification System
- Governance Admin
- Canonical Registries

Steps:

1. Actor submits the correct manifest: `ProviderCapabilityManifest`, `AppCapabilityManifest`, or `ExtensionManifest`.
2. Providers accept `ProviderParticipationTerms`; app and extension developers accept their certification and marketplace terms.
3. Extension submissions include `ExtensionArtifactAPI` artifact reference, `ExtensionBuildAttestation`, `SoftwareBillOfMaterials`, risk tier, permissions, and export/deletion obligations.
4. Version-pinned conformance tests run for the requested capability, API version, geography, data scope, and signing role.
5. Manual review occurs for higher-risk scopes.
6. `CertificationScopeRecord` is recorded with actor type, capability, API/manifest versions, restrictions, expiration, geography, key scope, and lifecycle state.
7. `ProviderCapabilityRegistry`, `AppMarketplaceListing`, `ExtensionRegistryAPI`, `MarketplaceListingAPI`, and `APIVersionRegistry` update.
8. `PublicRegistryReadModel` exposes approved status, keys, incidents, versions, and certification marks.
9. Keys or certification marks are issued where appropriate.

### Workflow 2: Continuous audit

Actors:

- Governance Admin
- Provider/App/Extension
- Audit APIs
- Canonical Registries

Steps:

1. Audit is scheduled or triggered by incident.
2. Actor provides evidence or API responses.
3. Audit checks conformance, data use, `DataUseGrant`, `CampaignDataGrant`, `DataAccessReceipt`, `FollowVisibilityPolicy`, `DirectContactGrant`, `CreatorAudienceExportPolicy`, `CreatorScopedTombstoneRecord`, receipts, export support, manifest versions, extension artifact status, key scope, and policy.
4. `ProviderAuditAPI`, `AppAuditAPI`, extension audit records, and supply-chain evidence are attached to the case.
5. Status remains certified or changes to `Limited`, `Suspended`, or `Revoked` by capability scope.
6. Affected users are notified and runtimes fail closed where keys, app certification, or extension artifacts are revoked.

### Workflow 3: Dispute resolution

Actors:

- Creator/Fan/Provider/Sponsor/Developer
- Governance Admin
- Evidence Systems
- Settlement Engine

Steps:

1. Actor files dispute.
2. Governance gathers receipts, manifests, contracts, audit records, and provider evidence.
3. Case is reviewed.
4. `DisputeCaseRecord` outcome is issued.
5. Outcomes are append-only: original receipts remain intact.
6. Settlement changes use `SettlementAdjustmentRecord`, `FraudAdjustmentRecord`, or `RefundChargebackRecord`.
7. Export failures use export remediation records and provider incident evidence.
8. Takedown changes use policy-versioned moderation/takedown records.
9. Certification changes update `CertificationScopeRecord` and key/artifact status.
10. Public incident or private record is updated according to policy and appeal windows.

### Workflow 4: API version governance

Actors:

- Foundation
- Developers
- Providers
- Apps

Steps:

1. Proposal for API/manifest change is published.
2. Feedback and compatibility analysis occur.
3. Version is approved.
4. SDKs and conformance tests update.
5. Deprecation timeline is published.
6. Providers/apps certify updated versions.

### Workflow 5: Key revocation

Actors:

- Governance Admin
- Provider/App/Extension
- `ProviderKeyManagementAPI`
- Apps/Providers

Steps:

1. Compromise or abuse is detected.
2. Governance validates severity.
3. Key is suspended or revoked by actor, capability, API version, service role, and certification scope.
4. Registries update.
5. Pre-revocation receipts remain auditable with key-time and certification-scope evidence.
6. Post-revocation receipts fail validation.
7. Extension artifact revocation is enforced separately from key revocation through `ExtensionRegistryAPI` and runtime fail-closed checks.
8. Recovery or re-certification path is defined.

### Workflow 6: Privacy and data-rights governance

Actors:

- Fan/Creator
- Governance Admin
- App/Provider/Extension/AI/Sponsor
- Audit APIs

Steps:

1. Report, probe, or audit identifies suspected data misuse.
2. Governance reviews `ConsentGrantAPI`, `DataUseGrant`, `CampaignDataGrant`, `DataAccessReceipt`, `FollowVisibilityPolicy`, `DirectContactGrant`, `CreatorAudienceExportPolicy`, vault boundaries, privacy mode, export/delete records, `CreatorRelationshipActionRecord`, `CreatorScopedTombstoneRecord`, and revocation state.
3. Outcome can revoke grants, rotate keys, block app or extension runtime, require deletion verification, enforce stricter `SensitiveRelationshipDefaultPolicy`, suspend provider/app/sponsor scopes, or require fan/creator notices.
4. Remediation evidence is collected through `ProviderAuditAPI`, `AppAuditAPI`, extension audit records, and sponsor/clean-room audit records.
5. Disputes and appeals follow append-only `DisputeCaseRecord` handling.

### Workflow 7: Utility fee governance

Actors:

- Foundation
- Settlement Engine
- Providers
- Creators/Fans
- Governance Admin

Steps:

1. Foundation publishes `UtilityFeePolicy`, fee caps, covered utilities, conflict rules, and transparency requirements.
2. Settlement Engine applies the policy through `SettlementManifest`; the foundation does not directly alter individual settlement runs.
3. Search utility funding is cost/budget based and cannot create paid ranking, search ads, per-click search monetization, routing priority, merge priority, or ordering advantage.
4. `UtilityFundingReceipt` and public reports explain identity, vault, search, settlement, and governance funding.
5. Policy changes follow version governance and public comment.

## 7. Cross-Area Interactions

- Provider Marketplace and Certified APIs: `ProviderCertificationAPI`, `CertificationScopeRecord`, and `ProviderCapabilityRegistry` power marketplace trust.
- Developer Ecosystem and DevOps Supply Chain: `ConformanceTestSuite`, `ExtensionArtifactAPI`, signed artifacts, and `APIVersionRegistry` support certification.
- Creator Plugins / Extensions / Campaign Layer: `ExtensionManifest`, `ExtensionArtifactAPI`, `ExtensionPermissionGrant`, and runtime certification enforce extension trust.
- Fan Apps and App Ecosystem: `AppCertificationAPI`, `AppAuditAPI`, app signing keys, and `AppRevocationWorkflow` govern app trust.
- AI Layer: AI provider and AI tool scopes are certified as provider/app capabilities through `CertificationScopeRecord`.
- Neutral Public Search Utility: `OpenSearchKernelConformance`, `SearchAuditProbeAPI`, and `SearchUtilityFundingPolicy` preserve neutrality.
- Trust, Safety, Fraud, and Compliance: `ProviderIncidentReport`, `DisputeCaseRecord`, and enforcement workflows handle incidents.
- Revenue, Receipts, Ledgers, and Settlement: disputes and audits depend on `ReceiptLedger`, `SettlementAdjustmentRecord`, and immutable receipts.
- Audience Data Firewall and Data Rights: `DataUseGrant`, `CampaignDataGrant`, `DataAccessReceipt`, `FollowVisibilityPolicy`, `DirectContactGrant`, `CreatorAudienceExportPolicy`, and deletion/export controls support privacy enforcement.
- Migration Strategy from Existing Platforms: `MigrationManifest`, `MigrationPlanAPI`, and export APIs enforce export rights and provider exit.
- Business Model and Incentive Design: `UtilityFeePolicy`, `FoundationFundingPolicy`, and `FoundationUtilityReport` govern utility fees.

## 8. FAQ

### What key systems and/or capabilities need to be created/implemented or modified to implement the key features, user stories, and end-to-end workflows?

- `FoundationGovernanceCharter`: authority, representation, decision process, and anti-capture rules.
- `ProviderCertificationAPI`: certification submissions.
- `ProviderCapabilityManifest`: capabilities and API versions.
- `AppCapabilityManifest`: app surfaces, data use, devices, extension runtime, and API versions.
- `AppCertificationAPI`: app certification submissions and status.
- `AppAuditAPI`: app privacy, receipt, manifest, search, recommendation, and extension audits.
- `ExtensionManifest`: extension capabilities, permissions, risk tier, and runtime requirements.
- `ExtensionArtifactAPI`: signed extension artifact lookup.
- `ExtensionBuildAttestation`: build provenance.
- `SoftwareBillOfMaterials`: dependency transparency.
- `ExtensionRegistryAPI`: extension certification, revocation, and public status.
- `CertificationScopeRecord`: certified role, version, state, restrictions, expiration, and public record.
- `ConformanceTestGovernance`: test ownership, updates, and required pass criteria.
- `ProviderParticipationTerms`: legal and marketplace obligations.
- `ProviderAuditAPI`: continuous audits and evidence.
- `ProviderKeyManagementAPI`: key issuance, rotation, suspension, and revocation.
- `ProviderCapabilityRegistry`: provider capabilities and states.
- `MarketplaceListingAPI`: provider marketplace listing status.
- `APIVersionRegistry`: API and manifest version state.
- `PublicRegistryReadModel`: public read model over canonical provider, app, extension, key, incident, certification mark, and version records.
- `DisputeResolutionAPI`: disputes and appeals.
- `DisputeCaseRecord`: append-only dispute case and outcome record.
- `SettlementAdjustmentRecord`: settlement correction record.
- `IncidentReportSystem`: public and private records.
- `APIVersionGovernance`: proposals, approvals, deprecation, and migration.
- `UtilityFeePolicy`: funding policy owned by governance and applied by settlement.
- `FoundationUtilityReport`: public funding, fee caps, conflicts, and utility allocation report.
- `UtilityFundingReceipt`: transparent utility allocation evidence.
- `DataUseGrant`, `CampaignDataGrant`, and `DataAccessReceipt`: privacy/data-rights enforcement evidence.
- `FollowVisibilityPolicy`: certification and audit target for creator relationship visibility handling.
- `DirectContactGrant`: certification and audit target for direct-contact permissions and exports.
- `CreatorAudienceExportPolicy`: certification and audit target for creator audience export field limits, destinations, no-resale obligations, retention, revocation, watermarking, and breach notices.
- `CreatorRelationshipActionRecord`: evidence for relationship lifecycle changes and fan remediation.
- `CreatorScopedTombstoneRecord`: deletion/remediation marker that certified systems must preserve and honor.
- `SensitiveRelationshipDefaultPolicy`: governance-controlled default policy for minors, vulnerable users, sensitive creator categories, private-mode users, and regulated regions.
