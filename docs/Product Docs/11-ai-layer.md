# Loom Product Definition 11: AI Layer

Status: Draft for review  
Product area: 11 of 22  
Depends on: 01 Core Thesis and Platform Principles; 04 Creator Channel and Metadata Architecture; 05 Fan Passport, Wallet, Vaults, and Identity Architecture

## 1. Product Definition

The AI Layer is a pluggable, permissioned, auditable service layer for creators, fans, apps, and providers. AI should help creators produce, manage, translate, summarize, and monetize content; help fans search, understand, and navigate creator archives; and generate new revenue through source attribution and AI royalties.

AI in Loom should not be a centralized platform-owned assistant that silently absorbs creator archives and fan behavior. Creators choose AI permissions and providers. Fans choose AI assistants, memory settings, and privacy modes. AI usage creates receipts for audit, attribution, and settlement.

## 2. Scope

This product area covers:

- AI Gateway and AI Provider API.
- Creator Copilot.
- Creator Channel Brain.
- Fan AI Assistant.
- AI summaries and digests.
- AI Q&A over creator archives.
- AI translation, dubbing, captioning, and clipping.
- AI-powered search and recommendation workbench.
- AI content access permissions.
- Fan AI memory policy.
- AI usage receipts and source attribution receipts.
- AI provider marketplace integration.
- MCP/AI tool integrations.
- Private in-vault AI recommendations.

It does not define the models themselves. It defines how AI capabilities interact with Loom data, permissions, receipts, and user experiences.

## 3. Key Features and Differentiators

| Feature / differentiator | Definition | Product value | Interacting product areas |
| --- | --- | --- | --- |
| Pluggable AI providers | Creators, apps, and fans can use certified AI providers. | Avoids central AI lock-in. | Provider Marketplace and Certified APIs |
| Creator AI permissions | `AIContentPolicy` controls summaries, Q&A, training, translation, source use, and royalties. | Creators control archive use. | Creator Channel and Metadata Architecture |
| Fan AI memory controls | Fan controls retention, memory, training, and ad-use settings. | AI respects fan privacy. | Fan Passport, Wallet, Vaults, and Identity Architecture |
| Creator Channel Brain | AI assistant grounded in creator-approved channel archive and metadata. | Turns creator archive into a knowledge product. | Creator Experience |
| Fan AI Assistant | Summaries, Q&A, search refinement, digests, and trusted recommendations. | Fans get more value from creator content. | Fan Experience |
| Source attribution receipts | AI records which creator sources contributed. | Enables royalties and trust. | Revenue, Receipts, Ledgers, and Settlement |
| AI usage receipts | AI interactions are auditable and billable. | Supports subscriptions, credits, provider payment, and governance. | Monetization Models |
| AI workbench tools | AI helps creators draft recommendations, campaigns, summaries, and metadata. | Improves creator productivity. | Creator-Led Recommendation Economy |
| In-vault private AI | Sensitive fan behavior can be processed inside Private Event Vault boundaries. | Personalization without raw data export. | Audience Data Firewall and Data Rights |

## 4. Product Experience Requirements

### 4.1 Creator AI Experience

Creators should be able to:

- Enable or disable AI features by content type.
- Approve summaries, archive Q&A, translation, dubbing, clipping, and training permissions.
- Choose AI providers.
- Set source attribution and royalty rules.
- See AI usage and revenue.
- Review AI-generated outputs before publication where needed.
- Export AI permissions and usage history.

### 4.2 Fan AI Experience

Fans should be able to:

- Summarize content.
- Ask questions over creator-approved archives.
- Search across public or permissioned content.
- Generate digests.
- Filter recommendations through personal preferences.
- Control memory, retention, and data use.
- See when AI answers use creator sources.

### 4.3 Provider and Governance Experience

AI providers should:

- Declare capabilities and data use.
- Pass certification tests.
- Respect creator and fan policies.
- Generate AI usage receipts.
- Support source attribution.
- Support audit and dispute workflows.

## 5. User Stories

### Story 1: Creator enables archive Q&A

As a creator, I want fans to ask questions over my archive so old content becomes useful and monetizable.

End state:

- Creator AI policy allows archive Q&A.
- AI provider can access approved content.
- Fan questions generate AI usage receipts.
- Source attribution supports creator royalties.

### Story 2: Fan asks for a summary

As a fan, I want AI summaries so I can decide whether to watch, read, or save content.

End state:

- AI checks content permissions.
- Summary is generated.
- AI usage receipt is recorded if relevant.

### Story 3: Creator chooses AI provider

As a creator, I want to choose an AI provider based on privacy, quality, price, and royalty support.

End state:

- Marketplace shows certified AI providers.
- Creator selects provider.
- Channel AI settings update.

### Story 4: Fan limits AI memory

As a fan, I want to use AI without long-term memory so my private interests are not retained.

End state:

- Fan AI Memory Policy disables retention.
- AI Gateway enforces policy.
- DataAccessReceipt records access where applicable.

### Story 5: AI drafts creator recommendations

As a creator, I want AI to help find and draft recommendations while I remain responsible for publishing them.

End state:

- Creator delegates bounded AI access.
- AI drafts candidate recommendations.
- Creator reviews disclosures and publishes `RecommendationManifest`.

### Story 6: AI translates creator content

As a creator, I want AI translation and dubbing so fans in more languages can access my work.

End state:

- AI policy permits translation/dubbing.
- Generated assets are linked to content metadata.
- Usage and provider receipts are generated.

## 6. End-to-End Workflows

### Workflow 1: Creator enables AI archive Q&A

Actors:

- Creator
- Creator Studio
- Creator Metadata Host
- AI Provider
- AI Gateway
- Fan App
- Fan Wallet
- Entitlement Ledger
- Receipt Ledger

Steps:

1. Creator opens AI settings.
2. Creator selects archive Q&A and allowed content scopes.
3. Creator chooses certified AI provider.
4. `AIContentPolicy` is written to channel metadata.
5. `AIIndexingAPI` creates policy-versioned source/index records from approved transcripts, metadata, or content chunks.
6. Fan asks question in Fan App.
7. Entitlement Ledger validates `AICreditEntitlement` or included access.
8. Fan sees cost/credit disclosure where applicable.
9. AI Gateway invokes provider through `AIProviderAPI` and records sources.
10. `AIUsageReceipt` and `SourceAttributionReceipt` are generated.
11. Fan receives answer, credits are consumed where applicable, and creator sees AI usage.

### Workflow 2: Fan AI search

Actors:

- Fan
- Fan App
- Search Utility
- AI Gateway
- Private Event Vault
- Entitlement Ledger

Steps:

1. Fan asks AI to find content.
2. AI Gateway checks `FanAIMemoryPolicy`, `AIConversationPolicy`, and any `AICreditEntitlement`.
3. AI uses public search tools to retrieve neutral candidates using `OpenSearchKernel` behavior and `PublicSearchResultSchema`.
4. `SearchReceipt` is generated for audit/utility funding only.
5. If private context is requested, `DataUseGrant` is checked before Private Event Vault access.
6. `DataAccessReceipt` records actual private context access.
7. AI summarizes or ranks retrieved results after neutral candidate retrieval; it cannot create paid ranking, search ads, or per-click search monetization.
8. `AIUsageReceipt` is generated where applicable.
9. Fan opens result.

### Workflow 3: Creator AI copilot for publishing

Actors:

- Creator
- Creator Studio
- AI Gateway
- Creator Metadata Host

Steps:

1. Creator uploads or drafts content.
2. Creator requests title, description, chapters, clips, tags, or summary.
3. AI Gateway checks allowed provider and data policy.
4. AI returns suggestions.
5. Creator edits and approves.
6. Approved metadata is written to Creator Metadata Host.
7. AI usage receipt is recorded.

### Workflow 4: AI recommendation workbench

Actors:

- Creator
- Creator Discovery Exchange
- AI Gateway
- Recommendation Workbench
- Creator Metadata Host

Steps:

1. Creator requests recommendation ideas.
2. Creator delegates bounded access through `CreatorAgentDelegationToken`.
3. AI queries Creator Discovery Exchange for creators, content, promotions, referral terms, and reputation.
4. AI drafts recommendation candidates and disclosure suggestions.
5. Creator reviews and edits.
6. Recommendation Workbench publishes `RecommendationManifest`.

### Workflow 5: Private in-vault recommendation assistant

Actors:

- Fan
- Fan AI Assistant
- Private Event Vault
- Fan Scoped Recommendation Engine
- Fan App

Steps:

1. Fan enables private recommendation mode.
2. Private Event Vault stores behavior under fan policy.
3. Fan AI Assistant requests local ranking context for a specific purpose.
4. `DataUseGrant` is checked and `FanAIMemoryPolicy` / `AIConversationPolicy` are enforced.
5. `PrivateRankingAPI` ranks trusted candidates inside vault boundary.
6. `DataAccessReceipt` records actual access.
7. Fan App receives ranked results or derived tokens, not raw history.
8. Fan can clear memory or disable mode.

### Workflow 6: AI provider certification and audit

Actors:

- AI Provider
- Developer Console
- Provider Certification System
- Governance Admin

Steps:

1. AI provider accepts `ProviderParticipationTerms`.
2. AI provider declares capabilities, data use, retention, training behavior, source attribution, and pricing in `ProviderCapabilityManifest`.
3. Provider submits certification through `ProviderCertificationAPI`.
4. Provider runs conformance tests.
5. Certification system checks policy enforcement and receipt generation.
6. Governance records `CertificationScopeRecord`.
7. `ProviderKeyManagementAPI` issues/activates signing keys for certified roles.
8. Marketplace listing appears.
9. `ProviderAuditAPI` verifies continued compliance.

### Workflow 7: Creator revokes AI indexing or source access

Actors:

- Creator
- Creator Studio
- Creator Metadata Host
- AI Gateway
- AI Provider
- Receipt Ledger

Steps:

1. Creator changes or revokes `AIContentPolicy`.
2. Creator Metadata Host records a new policy version.
3. AI Gateway identifies affected source chunks, indexes, generated embeddings, and cached context.
4. `AIIndexingAPI` triggers re-indexing, purge, or access cutoff.
5. AI Provider confirms purge or no-longer-accessible state where required.
6. Audit receipt records policy change and purge result.

### Workflow 8: AI translation, dubbing, or clipping

Actors:

- Creator
- Creator Studio
- AI Gateway
- AI Provider
- Content Host
- Creator Metadata Host
- Receipt Ledger

Steps:

1. Creator requests translation, dubbing, captions, clipping, or derived asset generation.
2. AI Gateway checks `AIContentPolicy`, provider certification, and source availability.
3. AI Provider generates derived asset with provenance metadata.
4. Creator reviews and approves generated asset.
5. Content Host stores approved asset.
6. `ContentManifest` updates with labels, provenance, language, derivative status, and revocation rules.
7. `AIUsageReceipt` and provider service receipts are generated.
8. Creator can later remove or revoke derived asset.

## 7. Cross-Area Interactions

- Creator Experience: Creator Studio exposes `AIContentPolicy`, creator AI tools, and `CreatorAgentDelegationToken`.
- Fan Experience: Fan App exposes AI summaries, Q&A, search, and digests through `AIGateway` and fan settings.
- Creator Channel and Metadata Architecture: `AIContentPolicy`, source permissions, and no-training defaults live in channel metadata.
- Fan Passport, Wallet, Vaults, and Identity Architecture: `FanAIMemoryPolicy`, `AIConversationPolicy`, `AICreditEntitlement`, and vault access govern fan AI behavior.
- Provider Marketplace and Certified APIs: AI providers are certified through `ProviderCapabilityManifest`, `ProviderCertificationAPI`, and `CertificationScopeRecord`.
- Revenue, Receipts, Ledgers, and Settlement: `AIUsageReceipt` and `SourceAttributionReceipt` feed settlement.
- Audience Data Firewall and Data Rights: `DataUseGrant`, `DataAccessReceipt`, and no-training policy make AI data use purpose-bound and auditable.
- Creator-Led Recommendation Economy: `RecommendationWorkbenchMCPServer` and `CreatorAgentDelegationToken` assist recommendations while creators publish `RecommendationManifest`.

## 8. FAQ

### What key systems and/or capabilities need to be created/implemented or modified to implement the key features, user stories, and end-to-end workflows?

#### AI gateway and provider systems

- AI Gateway: policy enforcement, provider routing, metering, source tracking, and receipt generation.
- `AIProviderAPI`: model invocation, streaming, embeddings, summarization, Q&A, translation, dubbing, and moderation hooks.
- AI Provider Registry: certified providers, capabilities, pricing, regions, data use, and supported policies.
- AI Provider Conformance Tests: source attribution, no-training behavior, retention, memory isolation, and receipt generation.
- `ProviderParticipationTerms`, `ProviderCapabilityManifest`, `ProviderCertificationAPI`, `CertificationScopeRecord`, `ProviderAuditAPI`, and `ProviderKeyManagementAPI`: AI provider certification, audit, and key lifecycle.

#### Creator AI systems

- `AIContentPolicy`: summary, Q&A, training, source royalty, translation, dubbing, clipping, and no-training rules.
- `AIContentAccessAPI`: controlled access to creator content and transcripts.
- `AIIndexingAPI`: policy-versioned indexing, source chunk provenance, re-indexing, purge, and revocation behavior.
- Creator Copilot: titles, descriptions, tags, chapters, clips, newsletters, summaries, and campaign drafts.
- Creator Channel Brain: approved archive Q&A and knowledge product behavior.
- CreatorAgentDelegationToken: bounded AI access for creator workbench tasks.

#### Fan AI systems

- Fan AI Assistant: summaries, archive Q&A, search, digests, and trusted recommendation filtering.
- `FanAIMemoryPolicy` and `AIConversationPolicy`: retention, memory, training, ad-use, delete, no-memory settings, and conversation handling.
- Private Event Vault integration: private behavior and memory storage.
- `DataUseGrant` and `DataAccessReceipt`: purpose-bound private context access and audit.
- `PrivateRankingAPI`: in-vault recommendations.
- `AICreditEntitlement` and `EntitlementLedgerAPI`: paid or bundled AI access and credit consumption.

#### Receipt and settlement systems

- `AIUsageReceipt`: interaction, provider, model, cost, policy, entitlement, and user context.
- `SourceAttributionReceipt`: source content, creator, contribution, and royalty basis.
- Settlement Engine integration: AI credits, subscriptions, provider costs, and creator royalties.
- Creator AI Revenue Dashboard: source usage, royalties, provider costs, and top archive queries.

#### Search and recommendation tools

- `SearchMCPServer`: AI access to public search tools.
- `RecommendationWorkbenchMCPServer`: AI support for creator recommendation drafting.
- `FanRecommendationMCPServer`: fan AI trusted filtering.
- Tool Permission Scopes: tool calls must respect `CreatorAgentDelegationToken`, fan permissions, and tool-call audit records.
- Public Search Utility integration: neutral search results retrieved through `OpenSearchKernel` and `PublicSearchResultSchema`; AI personalization happens after retrieval and cannot create paid ranking.

#### Trust and governance systems

- `AIAuditAPI`: policy checks, source attribution review, retention checks, and incident investigation.
- `AbuseReportAPI`: harmful AI output, privacy violations, impersonation, or source misuse.
- Key Revocation: AI provider signing and access revocation.
- `DataAccessReceipt`: audit trail for fan or creator data used by AI.
