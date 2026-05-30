# Loom Product Definition 17: Trust, Safety, Fraud, and Compliance

Status: Draft for review  
Product area: 17 of 22  
Depends on: 01 Core Thesis and Platform Principles; 04 Creator Channel and Metadata Architecture; 07 Provider Marketplace and Certified APIs; 08 Revenue, Receipts, Ledgers, and Settlement; 10 Creator Plugins / Extensions / Campaign Layer; 11 AI Layer; 12 Creator-Led Recommendation Economy; 13 Neutral Public Search Utility; 14 Audience Data Firewall and Data Rights; 15 Fan Apps and App Ecosystem; 16 Developer Ecosystem and DevOps Supply Chain; 19 Governance, Certification, and Foundation Model

## 1. Product Definition

Trust, Safety, Fraud, and Compliance must be built into Loom's protocol, not bolted onto one app later. Loom needs protection against spam, fraud, ad manipulation, recommendation abuse, extension abuse, campaign abuse, illegal content, privacy violations, payment abuse, AI abuse, and provider misconduct.

The product should use signed receipts, certified providers, scoped permissions, sandboxed extensions, audit records, takedown workflows, dispute APIs, and governance enforcement to keep the network trustworthy.

## 2. Scope

This product area covers:

- Content moderation labels.
- Abuse reports.
- Takedown workflows.
- Fraud signals.
- Invalid traffic detection.
- Ad fraud controls.
- Playback token validation.
- Payment and chargeback abuse.
- Recommendation abuse.
- Search manipulation probes.
- Extension and app abuse.
- Campaign compliance.
- Sponsor disclosure enforcement.
- AI safety and source misuse.
- Provider incidents.
- Disputes and adjustments.
- Key revocation and provider/app/extension suspension.

## 3. Key Features and Differentiators

| Feature / differentiator | Definition | Product value | Interacting product areas |
| --- | --- | --- | --- |
| Signed receipts | Usage and monetization events are auditable. | Reduces fake activity and payout fraud. | Revenue, Receipts, Ledgers, and Settlement |
| Provider certification | Providers must pass conformance and audits. | Limits rogue infrastructure. | Provider Marketplace and Certified APIs |
| Scoped data access | `DataUseGrant`, `CampaignDataGrant`, and `DataAccessReceipt` make permissioned access enforceable. | Reduces privacy violations. | Audience Data Firewall and Data Rights |
| Creator audience misuse controls | Follower visibility, direct-contact grants, blocks, and tombstones are enforceable safety signals. | Reduces harassment, scraping, resale, and creator/sponsor misuse of fan data. | Fan Passport, Wallet, Vaults, and Identity Architecture |
| Extension sandboxing | Extensions run with scoped permissions and certification. | Reduces app/plugin abuse. | Creator Plugins / Extensions / Campaign Layer |
| Recommendation reputation | Recommendation abuse affects trust signals and settlement. | Reduces clickbait and fake referral loops. | Creator-Led Recommendation Economy |
| Search audit probes | Detect paid ranking or manipulation. | Protects neutral search. | Neutral Public Search Utility |
| Campaign compliance manifests | Giveaways and sponsors declare rules and eligibility. | Reduces legal and sponsor risk. | Brand/Sponsor/Advertiser Tools |
| Dispute workflows | Actors can challenge takedowns, payouts, fraud, export, or data use. | Makes enforcement accountable. | Governance, Certification, and Foundation Model |

## 4. Product Experience Requirements

Fans should be able to:

- Report content, creators, apps, campaigns, sponsors, extensions, AI outputs, or providers.
- See clear labels and restrictions.
- Understand privacy incidents and revocations.
- Block creators, revoke direct-contact permission, and request creator-scoped deletion when audience access is misused.

Creators should be able to:

- See moderation status and appeal.
- See fraud adjustments.
- Report provider misconduct.
- Resolve campaign or sponsor issues.

Providers/apps/developers should:

- Receive clear incident notices.
- Have remediation paths.
- Support audit and evidence requests.

Governance should:

- Investigate incidents.
- Suspend or revoke capabilities.
- Publish public incident records where appropriate.
- Maintain dispute and appeal workflows.

## 5. User Stories

### Story 1: Fan reports abuse

As a fan, I want to report unsafe content or campaigns.

End state:

- Abuse report is recorded.
- Moderator or provider receives case.
- Fan can see status where appropriate.

### Story 2: Fraud adjusts payout

As settlement governance, I want invalid traffic to reduce payouts without deleting original receipts.

End state:

- FraudAdjustmentRecord offsets settlement.
- Creator/provider statements explain adjustment.

### Story 3: Creator appeals takedown

As a creator, I want to appeal a takedown or moderation label.

End state:

- Dispute case is created.
- Evidence and policy are reviewed.
- Outcome is recorded.

### Story 4: Extension is suspended

As governance, I want to suspend an extension that violates privacy rules.

End state:

- Extension certification state changes.
- Fan apps block or limit runtime.
- Creators and developer are notified.

### Story 5: Search manipulation is detected

As governance, I want to detect a host manipulating search ranking.

End state:

- Search audit probe records violation.
- Host capability can be limited or suspended.

## 6. End-to-End Workflows

### Workflow 1: Abuse report

Actors:

- Fan or Creator
- Fan App / Creator Studio
- Abuse Report API
- Moderation Provider
- Governance Admin

Steps:

1. User reports content, app, extension, creator, sponsor, AI output, or provider.
2. Report includes context, receipts, policy versions, artifact versions, app/provider ids, and evidence.
3. Moderation provider or governance triages.
4. Labels, restrictions, takedowns, or dismissals are applied.
5. Parties are notified.
6. Appeal path is available where policy allows.

### Workflow 2: Invalid traffic adjustment

Actors:

- `FraudSignalAPI`
- `ReceiptIngestAPI`
- `ReceiptLedger`
- Settlement Engine
- Creator Studio
- Provider Console

Steps:

1. `ReceiptIngestAPI` validates signed receipts, certification scope, provider/app keys, and manifest-version bindings.
2. Fraud system identifies suspicious activity without deleting original receipts.
3. Fraud confidence score, hold, reserve, invalid-traffic flag, or chargeback signal is attached.
4. Settlement Engine applies adjustment rules.
5. `FraudAdjustmentRecord`, `RefundChargebackRecord`, or `SettlementAdjustmentRecord` is created.
6. `SettlementRunRecord`, creator payout statements, and provider statements show the adjustment and evidence.
7. Evidence-backed dispute can be opened.

### Workflow 3: Takedown and appeal

Actors:

- Rights Holder or Authority
- Takedown API
- Creator
- Governance Admin
- Content Host
- Search Provider
- AI Provider
- Fan App

Steps:

1. Takedown request is submitted.
2. System validates authority and policy.
3. `SafetyPolicyManifest` and affected `ContentManifest` records are updated with policy-versioned status.
4. Content hosts label, restrict, or remove content.
5. Fan apps update labels and access restrictions.
6. Search providers de-index or downgrade indexed records according to policy.
7. AI indexing/source access is revoked or purged where required.
8. Receipts, migration/export evidence, and audit records are linked to the case.
9. Creator is notified.
10. Creator appeals.
11. Governance resolves, records outcome, and propagates reinstatement or final enforcement.

### Workflow 4: Provider incident

Actors:

- Provider
- Governance Admin
- Marketplace Listing API
- Affected Creators/Apps
- Fan Apps
- Extension Runtime

Steps:

1. Provider reports incident or audit detects issue.
2. `ProviderIncidentReport` records severity, affected `ProviderCapabilityManifest`, `CertificationScopeRecord`, API versions, signing keys, artifact versions, and impacted data classes.
3. `ProviderAuditAPI` and `ProviderKeyManagementAPI` collect evidence and update key status.
4. Marketplace listing updates.
5. Capability may become `Limited`, `Suspended`, or `Revoked` by role/capability scope.
6. Fan apps, app runtimes, and extension runtimes fail closed for revoked keys, revoked app certifications, or invalid extension artifacts.
7. Migration, remediation, notification, and dispute workflows are offered.

### Workflow 5: Campaign compliance enforcement

Actors:

- Creator
- Sponsor
- Campaign Ledger
- Governance Admin
- Fan App

Steps:

1. Campaign is configured with compliance manifest.
2. `CampaignManifest`, `CampaignComplianceManifest`, and `SponsorDisclosurePolicy` declare eligibility, age/region, odds/rules, data use, alternate entry, rewards, and sponsor obligations.
3. `EligibilityAPI` and clean-room checks run without raw Private Event Vault export.
4. `CampaignDataGrant` and `DataAccessReceipt` verify permitted fan data use.
5. `CampaignEntryReceipt`, `RewardReceipt`, `SponsorDeliveryReceipt`, and `ConversionReceipt` provide settlement and dispute evidence.
6. Violation is detected.
7. Campaign is limited, paused, corrected, or ended.
8. Fans, creator, and sponsor receive appropriate notice and dispute paths.

### Workflow 6: Privacy and data-misuse enforcement

Actors:

- Fan or Creator
- Fan App / Creator Studio
- Audience Data Firewall
- Provider/App/Extension/AI/Sponsor
- Governance Admin

Steps:

1. Report, audit probe, or receipt review identifies suspected data misuse.
2. Investigation checks `DataUseGrant`, `CampaignDataGrant`, `DataAccessReceipt`, `AudienceDataFirewallPolicy`, `FollowVisibilityPolicy`, `DirectContactGrant`, `CreatorAudienceExportPolicy`, vault boundaries, privacy mode, and revocation state.
3. Misuse can involve app access, provider processing, extension data access, AI memory/training, sponsor reporting, creator audience export, direct-contact misuse, scraping, resale, or harassment based on follower visibility.
4. Governance limits scopes, revokes grants, rotates keys, blocks runtime access, requires deletion or `CreatorScopedTombstoneRecord`, applies `SensitiveRelationshipDefaultPolicy`, or opens incident remediation.
5. `ProviderAuditAPI`, `AppAuditAPI`, and extension audit records verify remediation.
6. Fans/creators receive notice where required, and disputes can be opened.

### Workflow 6A: Creator audience misuse report

Actors:

- Fan
- Fan App
- AbuseReportAPI
- DataDashboard
- Governance Admin
- Creator Studio
- Provider/App/Extension Audit APIs

Steps:

1. Fan reports off-platform contact, harassment, scraping, resale, sponsor pressure, or exposure of a sensitive follow relationship.
2. `AbuseReportAPI` attaches fan-provided evidence, relationship state, relevant `CreatorRelationshipActionRecord`, and available `DataAccessReceipt` records.
3. Investigation checks `FollowVisibilityPolicy`, `DirectContactGrant`, `CreatorAudienceExportPolicy`, `CreatorScopedTombstoneRecord`, sponsor/campaign grants, app permissions, and extension permissions.
4. If access was unauthorized, governance revokes grants, restricts creator CRM export, suspends app/extension/provider scopes, requires deletion verification, or applies `SensitiveRelationshipDefaultPolicy`.
5. If an export breach occurred, `CreatorAudienceExportPolicy` defines notification, retention, deletion, and no-resale remediation obligations.
6. DataDashboard shows the fan case state, retained audit exceptions, and available dispute or appeal paths.

### Workflow 7: AI safety and source misuse

Actors:

- Fan or Creator
- AI Gateway
- AI Provider
- Search/Content/Metadata Provider
- Governance Admin

Steps:

1. User reports unsafe AI output, source misuse, no-training violation, or private-context leakage.
2. Governance reviews `AIContentPolicy`, `AIUsageReceipt`, `SourceAttributionReceipt`, `DataUseGrant`, `DataAccessReceipt`, and `AIAuditAPI` evidence.
3. Source indexing, AI memory, or model/tool access is limited, purged, or revoked where required.
4. AI provider certification scope, keys, or marketplace status can be limited, suspended, or revoked.
5. Affected creators and fans receive notice and dispute paths where appropriate.

## 7. Cross-Area Interactions

- Revenue, Receipts, Ledgers, and Settlement: `FraudAdjustmentRecord`, `RefundChargebackRecord`, `SettlementAdjustmentRecord`, and disputes affect payouts.
- Creator Channel and Metadata Architecture: `SafetyPolicyManifest`, `ContentManifest`, and policy-version records carry enforcement state.
- Provider Marketplace and Certified APIs: `CertificationScopeRecord`, `ProviderAuditAPI`, and `ProviderKeyManagementAPI` enforce provider behavior.
- Audience Data Firewall and Data Rights: `DataUseGrant`, `CampaignDataGrant`, `DataAccessReceipt`, `FollowVisibilityPolicy`, `DirectContactGrant`, `CreatorAudienceExportPolicy`, and `AudienceDataFirewallPolicy` create enforceable data-misuse evidence.
- Creator Plugins / Extensions / Campaign Layer: `ExtensionArtifactAPI`, `ExtensionPermissionGrant`, and `CampaignComplianceManifest` govern extension abuse and campaign compliance.
- AI Layer: `AIContentPolicy`, `AIUsageReceipt`, `SourceAttributionReceipt`, and `AIAuditAPI` govern AI safety, privacy, and source misuse.
- Neutral Public Search Utility: `SearchAuditProbeAPI`, `OpenSearchKernelConformance`, and `SearchReceipt` support search manipulation probes.
- Creator-Led Recommendation Economy: `RecommendationAbuseAPI`, `DiscoveryReceipt`, `CreatorReferralReceipt`, and reputation policy support enforcement.
- Fan Apps and App Ecosystem: `AppCertificationAPI`, `AppAuditAPI`, and `AppRevocationWorkflow` handle app certification, audits, and revocation.
- Developer Ecosystem and DevOps Supply Chain: `ExtensionBuildAttestation`, `SoftwareBillOfMaterials`, `ProviderKeyManagementAPI`, and supply-chain incidents provide evidence.
- Governance, Certification, and Foundation Model: `DisputeResolutionAPI`, `DisputeCaseRecord`, and `CertificationScopeRecord` provide final authority and process.

## 8. FAQ

### What key systems and/or capabilities need to be created/implemented or modified to implement the key features, user stories, and end-to-end workflows?

- `ModerationLabelAPI`: content, user, creator, app, extension, sponsor, and provider labels.
- `AbuseReportAPI`: report intake and case tracking.
- `TakedownAPI`: legal and safety takedowns.
- `DisputeResolutionAPI`: appeals, payout disputes, export disputes, privacy disputes, and takedown disputes.
- `FraudSignalAPI`: fraud risk scoring.
- `InvalidTrafficAPI`: playback/ad validity.
- `PlaybackTokenValidation`: anti-replay and access checks.
- `ReceiptIngestAPI`: signed receipt validation.
- `ReceiptLedger`: immutable receipt evidence.
- `SettlementRunRecord`: settlement run output.
- `FraudAdjustmentRecord`: invalid activity settlement offset.
- `RefundChargebackRecord`: refund and chargeback evidence.
- `SettlementAdjustmentRecord`: correction or dispute adjustment.
- `RecommendationAbuseAPI`: clickbait, ragebait, title-summary mismatch, fake referral, undisclosed paid relationship, and spam signals.
- `DiscoveryReceipt`: recommendation-driven discovery evidence.
- `CreatorReferralReceipt`: qualified referral evidence.
- `SearchAuditProbeAPI`: search manipulation detection.
- `OpenSearchKernelConformance`: neutral search certification tests.
- `PublicSearchResultSchema`: signed public search result format.
- `SearchReceipt`: audit/utility funding evidence, never paid-ranking input.
- `DataUseGrant`: purpose-bound data access.
- `CampaignDataGrant`: campaign-specific fan data exchange.
- `DataAccessReceipt`: grant-protected data access evidence.
- `AudienceDataFirewallPolicy`: data boundary and misuse policy.
- `FollowVisibilityPolicy`: fan-selected creator relationship visibility state that safety systems enforce during audits, reporting, and remediation.
- `DirectContactGrant`: explicit fan permission for creator direct-contact use; misuse, scraping, resale, or off-platform contact without a valid grant is enforceable.
- `CreatorRelationshipActionRecord`: evidence for follow visibility changes, unfollows, blocks, direct-contact revocations, and creator-scoped deletion requests.
- `CreatorScopedTombstoneRecord`: deletion/remediation marker that prevents rehydration of creator-scoped audience data while preserving required audit, safety, settlement, and legal records.
- `SensitiveRelationshipDefaultPolicy`: stricter defaults for minors, vulnerable users, sensitive creator categories, private-mode users, and regulated regions.
- `CreatorAudienceExportPolicy`: field, destination, retention, watermarking, no-resale, revocation, breach-notice, and remediation rules for creator audience exports.
- `CampaignManifest`: campaign configuration.
- `CampaignComplianceManifest`: eligibility, disclosures, legal terms, and alternate entry.
- `SponsorDisclosurePolicy`: sponsor disclosure rules.
- `CampaignEntryReceipt`: campaign entry evidence.
- `RewardReceipt`: reward fulfillment evidence.
- `SponsorDeliveryReceipt`: sponsor delivery evidence.
- `ConversionReceipt`: permitted conversion evidence.
- `ProviderCapabilityManifest`: provider role/capability declaration.
- `ProviderIncidentReport`: provider misconduct, outages, data incidents, and export failures.
- `ProviderAuditAPI`: provider audit evidence and remediation.
- `ProviderKeyManagementAPI`: app/provider/extension signing-key issuance, rotation, suspension, and revocation.
- `CertificationScopeRecord`: capability, role, API-version, key, app, extension, or provider certification boundary.
- `AppAuditAPI`: app privacy, manifest, receipt, search, recommendation, and extension audits.
- `AppRevocationWorkflow`: app suspension and revocation.
- `ExtensionArtifactAPI`: certified extension artifact lookup.
- `ExtensionPermissionGrant`: extension data and capability permissions.
- `AIContentPolicy`: AI source, output, retention, and training policy.
- `AIUsageReceipt`: AI usage evidence.
- `SourceAttributionReceipt`: AI source attribution evidence.
- `AIAuditAPI`: AI provider and tool audit evidence.
- `ProviderSuspensionWorkflow`: `Limited`, `Suspended`, and `Revoked` states.
- `PublicIncidentRecord`: external trust reporting where appropriate.
