# Loom Product Definition 13: Neutral Public Search Utility

Status: Draft for review  
Product area: 13 of 22  
Depends on: 01 Core Thesis and Platform Principles; 03 Fan Experience; 04 Creator Channel and Metadata Architecture; 07 Provider Marketplace and Certified APIs; 08 Revenue, Receipts, Ledgers, and Settlement; 09 Monetization Models; 10 Creator Plugins / Extensions / Campaign Layer; 11 AI Layer; 12 Creator-Led Recommendation Economy; 15 Fan Apps and App Ecosystem

## 1. Product Definition

The Neutral Public Search Utility is Loom's fan-initiated path for broad discovery outside the creator trust graph. Search should help fans intentionally find creators, content, events, campaigns, transcripts, posts, newsletters, courses, and communities without turning search into paid ranking or another engagement-maximizing feed.

Search is not recommendations. Search is not ad inventory. Search should be distributed across certified hosts and indexes, merged neutrally by apps, and funded as shared utility infrastructure through audit/utility receipts rather than paid placement.

## 2. Scope

This product area covers:

- Host public catalog and search exposure.
- Search Directory.
- `SearchDirectoryPolicy`.
- `HostPublicSearchAPI`.
- `PublicCatalogAPI`.
- `PublicSearchResultSchema`.
- `OpenSearchKernel`.
- `OpenSearchKernelConformance`.
- `SearchAccessPolicy`.
- `NeutralSearchMergePolicy`.
- Certified `SearchIndexProvider` participation.
- `SearchReceipt` as audit and utility-funding receipt.
- App-side neutral result merge.
- Search filters.
- Transcript snippet search where allowed.
- Public search over creators, content, events, promotions, and giveaways.
- Sponsor/campaign labels for searchable promotions and giveaways.
- Optional fan-controlled AI search tools.

It does not cover creator-led recommendations or paid ad ranking.

## 3. Key Features and Differentiators

| Feature / differentiator | Definition | Product value | Interacting product areas |
| --- | --- | --- | --- |
| Fan-initiated search | Search starts from explicit fan intent. | Separates search from algorithmic feeds. | Fan Experience |
| No paid ranking | Search results cannot be sold as ranking placement. | Preserves trust and neutrality. | Core Thesis and Platform Principles |
| No search ads | Search does not become ad inventory. | Avoids search incentives corrupting discovery. | Business Model and Incentive Design |
| Distributed host search | Certified hosts expose searchable public metadata. | Avoids one centralized search owner. | Hosting Provider Lifecycle and Progressive Unbundling |
| Open Search Kernel | Certified lightweight implementation for host-local search. | Makes neutral search easier for providers. | Developer Ecosystem and DevOps Supply Chain |
| Standard result schema | `PublicSearchResultSchema` lets apps merge results consistently. | Fan apps can build good search UX. | Fan Apps and App Ecosystem |
| Search access policy | Creators define what metadata, transcripts, and snippets are searchable. | Creator control over public discoverability. | Creator Channel and Metadata Architecture |
| Search receipts | `SearchReceipt` supports audit and utility funding only. | Search can be measured without per-click monetization. | Revenue, Receipts, Ledgers, and Settlement |
| AI search tools | Fan-controlled AI can use search as a tool. | Fans can refine, summarize, and explore results. | AI Layer |

## 4. Product Experience Requirements

Fans should be able to:

- Search creators, content, posts, videos, newsletters, events, courses, livestreams, promotions, and communities.
- Filter by type, creator, freshness, language, duration, access mode, transcript availability, and topic.
- Understand why a result is searchable.
- Use AI to refine or summarize results where permitted.
- Save, follow, or open results.

Creators should be able to:

- Control searchability of content.
- Allow or deny transcript snippet indexing.
- See public search visibility and errors.
- Export search policies and public catalog metadata.

Providers and apps should:

- Expose certified search APIs.
- Return signed result records.
- Avoid paid ranking or search ad injection.
- Avoid paid routing priority, paid merge priority, provider self-preference, app-owned boosts, or engagement-max ranking.
- Generate `SearchReceipt` for audit and utility funding.

## 5. User Stories

### Story 1: Fan searches public content

As a fan, I want to search public Loom content so I can find creators and topics beyond my follows.

End state:

- Host search APIs return signed results.
- App merges results neutrally.
- `SearchReceipt` records audit/utility event.

### Story 2: Creator controls searchability

As a creator, I want to decide which content can appear in public search.

End state:

- `SearchAccessPolicy` is stored with content/channel metadata.
- Search providers index only allowed metadata.

### Story 3: Fan searches transcripts

As a fan, I want transcript snippets in search results when creators allow it.

End state:

- Search returns allowed snippets.
- Full content access still follows entitlement rules.

### Story 4: Fan uses AI search

As a fan, I want AI to help refine search results without paid ranking.

End state:

- AI uses certified search tools.
- Results remain sourced from neutral search.
- AI respects fan memory and creator search policies.

### Story 5: Governance audits search manipulation

As governance, I want to detect hosts or apps manipulating search results.

End state:

- Search receipts and probes are reviewed.
- Noncompliant providers can be limited, suspended, or revoked.

## 6. End-to-End Workflows

### Workflow 1: Public search query

Actors:

- Fan
- Fan App
- Search Directory
- Host Public Search APIs
- Receipt Ledger

Steps:

1. Fan enters query.
2. Fan App sends query to Search Directory.
3. Search Directory applies `SearchDirectoryPolicy` to route across relevant certified hosts and optional certified `SearchIndexProvider` services without paid routing priority.
4. Routing decisions are signed for audit.
5. Hosts query local `OpenSearchKernel` or equivalent certified implementation.
6. Hosts return signed `PublicSearchResultSchema` results with policy-version, source, ranking inputs, snippet permissions, and campaign/sponsor labels where relevant.
7. Fan App applies `NeutralSearchMergePolicy`; it cannot sell merge priority, add app-owned boosts, or reorder by undisclosed paid relationships.
8. Merge decisions are logged for audit probes.
9. Fan filters or opens result.
10. `SearchReceipt` is submitted through `ReceiptIngestAPI` to `ReceiptLedger` for audit/utility funding only.
11. Opening a result transitions to normal entitlement, playback, content, campaign, or purchase receipts rather than search-click monetization.

### Workflow 2: Creator sets search policy

Actors:

- Creator
- Creator Studio
- Creator Metadata Host
- Search Provider

Steps:

1. Creator edits content search settings.
2. Creator sets whether title, description, metadata, transcript, snippet, event/campaign data, promotion/giveaway metadata, or full text is searchable.
3. Creator Studio writes policy-versioned `SearchAccessPolicy`.
4. Search providers separate indexability, snippet display, and full-content access in index records.
5. Transcript snippets include provenance and redaction rules.
6. Campaign and promotion results expose `CampaignManifest`, `CampaignComplianceManifest`, and `SponsorDisclosurePolicy` labels through `PublicSearchResultSchema`.
7. Search providers update indexes without paid placement.
8. Creator sees indexing status and errors.

### Workflow 3: Host search certification

Actors:

- Host Provider
- Developer Console
- Provider Certification System
- Governance Admin

Steps:

1. Host declares search capability in `ProviderCapabilityManifest`.
2. Host accepts `ProviderParticipationTerms` and completes business/legal verification.
3. Host implements `HostPublicCatalogAPI`, `HostPublicSearchAPI`, `OpenSearchKernel`, role-scoped signing keys, and optional `SearchIndexProvider` interfaces.
4. `ProviderCertificationAPI` runs conformance tests for result schema, neutral behavior, no paid ranking, signed results, search policy enforcement, snippet controls, and receipt behavior.
5. Governance records `CertificationScopeRecord` by provider role, API version, and key scope.
6. `ProviderKeyManagementAPI` issues, rotates, suspends, or revokes search signing keys.
7. `ProviderAuditAPI` supports probes and incident review.
8. Host becomes discoverable through Search Directory.

### Workflow 4: Fan AI search assistant

Actors:

- Fan
- Fan App
- AI Gateway
- Search Directory
- Private Event Vault

Steps:

1. Fan asks AI to find content.
2. AI Gateway checks `FanSearchPermissionGrant`, `DataUseGrant`, `FanAIMemoryPolicy`, `AIConversationPolicy`, and fan privacy settings.
3. AI calls certified `SearchMCPServer` tools.
4. Search results are returned neutrally and remain bound to `PublicSearchResultSchema` source links.
5. AI summarizes or clusters results with source links and no paid-ranking/search-ad behavior.
6. Private Event Vault stores behavior only if fan policy allows.
7. Any grant-protected private context access creates `DataAccessReceipt`.

### Workflow 5: Search audit probe

Actors:

- Governance Admin
- `SearchAuditProbeAPI`
- Host Provider
- Fan App

Steps:

1. Governance runs probe query.
2. Host returns signed search results and routing/merge logs are retrieved where relevant.
3. Probe checks `SearchDirectoryPolicy`, `NeutralSearchMergePolicy`, policy enforcement, ranking neutrality, paid placement absence, provider self-preference, app-owned boosts, and result consistency.
4. Violations create provider incident, app incident, key action, or certification action.
5. Marketplace status updates where needed.

## 7. Cross-Area Interactions

- Fan Experience: search is a core fan discovery path through `SearchDirectoryAPI`, filters, and audit-only `SearchReceipt`.
- Creator Channel and Metadata Architecture: searchability is defined by metadata, `SearchAccessPolicy`, and `PublicSearchResultSchema`.
- Provider Marketplace and Certified APIs: host and index providers require `ProviderCertificationAPI`, `CertificationScopeRecord`, and `ProviderKeyManagementAPI`.
- Hosting Provider Lifecycle and Progressive Unbundling: hosts expose `HostPublicCatalogAPI`, `HostPublicSearchAPI`, and `OpenSearchKernel`.
- Revenue, Receipts, Ledgers, and Settlement: `SearchReceipt`, `ReceiptIngestAPI`, and `UtilityFundingReceipt` support audit and utility funding only.
- Monetization Models: paid premium features and `PaymentReceipt` cannot influence neutral public search ordering.
- Creator Plugins / Extensions / Campaign Layer: promotions and giveaways are searchable only as eligible `CampaignManifest` objects with `SponsorDisclosurePolicy`.
- AI Layer: `SearchMCPServer` can use search tools without owning ranking or creating paid placement.
- Creator-Led Recommendation Economy: `RecommendationManifest` and `CommunityFeedAPI` remain distinct from neutral search results.
- Fan Apps and App Ecosystem: apps must apply `NeutralSearchMergePolicy` and produce merge audit evidence.
- Governance, Certification, and Foundation Model: `OpenSearchKernelConformance`, `SearchAuditProbeAPI`, and certification enforce neutral behavior.
- Business Model and Incentive Design: `SearchUtilityFundingPolicy` funds search without paid ranking.

## 8. FAQ

### What key systems and/or capabilities need to be created/implemented or modified to implement the key features, user stories, and end-to-end workflows?

- `HostPublicCatalogAPI`: host-local public content metadata exposure.
- `HostPublicSearchAPI`: host-local public search endpoint.
- `PublicCatalogAPI`: app-facing public catalog aggregation.
- `SearchDirectoryAPI`: query routing to relevant certified hosts.
- `SearchDirectoryPolicy`: no paid routing priority, no self-preference, and auditable routing criteria.
- `SearchAccessPolicy`: content and transcript searchability rules.
- `PublicSearchResultSchema`: standard result format.
- `OpenSearchKernel`: reference host-local search implementation.
- `OpenSearchKernelConformance`: tests for neutral search behavior.
- `SearchIndexProvider`: certified optional index/metadata provider role.
- `ProviderParticipationTerms`: provider obligations for neutral public search.
- `ProviderCertificationAPI`: capability and API-version scoped certification.
- `CertificationScopeRecord`: approved search roles, versions, and signing-key scopes.
- `ProviderKeyManagementAPI`: search result key issuance, rotation, suspension, and revocation.
- `ProviderAuditAPI`: audit evidence, probes, and incident support.
- `SearchReceipt`: audit and utility-funding receipt, never paid-ranking input.
- `ReceiptIngestAPI`: validates and submits `SearchReceipt`.
- `ReceiptLedger`: immutable store for search audit and utility-funding receipts.
- `UtilityFeePolicy`: shared infrastructure funding rules for search.
- `UtilityFundingReceipt`: utility funding allocation record, not a paid click record.
- `SearchMCPServer`: AI/fan search tooling.
- `FanSearchPermissionGrant`: fan permission for AI-assisted search.
- `DataUseGrant`: private-context permission for AI search.
- `DataAccessReceipt`: audit record for grant-protected private context access.
- `FanAIMemoryPolicy`: fan memory policy for AI-assisted search.
- `AIConversationPolicy`: conversation retention and source-use policy.
- `NeutralSearchMergePolicy`: app-side or shared result merge contract that does not sell ranking.
- `SearchAuditProbeAPI`: detects manipulation, paid placement, and policy violations.
- `SearchIndexingDashboard`: creator/provider indexing status and errors.
- `CampaignManifest`: public campaign object metadata for searchable campaigns.
- `CampaignComplianceManifest`: eligibility, legal, and alternate-entry controls.
- `SponsorDisclosurePolicy`: sponsor labels for public search results.
