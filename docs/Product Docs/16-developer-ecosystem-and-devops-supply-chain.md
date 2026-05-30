# Loom Product Definition 16: Developer Ecosystem and DevOps Supply Chain

Status: Draft for review  
Product area: 16 of 22  
Depends on: 07 Provider Marketplace and Certified APIs; 10 Creator Plugins / Extensions / Campaign Layer; 12 Creator-Led Recommendation Economy; 13 Neutral Public Search Utility; 14 Audience Data Firewall and Data Rights; 15 Fan Apps and App Ecosystem; 17 Trust, Safety, Fraud, and Compliance; 19 Governance, Certification, and Foundation Model; 22 Business Model and Incentive Design

## 1. Product Definition

The Developer Ecosystem and DevOps Supply Chain enables developers to build providers, extensions, fan apps, AI tools, search tools, creator dashboards, recommendation workbenches, and governance tools through open SDKs, templates, conformance tests, signed artifacts, and verified deployment pipelines.

The developer platform must make openness practical without compromising creator ownership, fan data rights, security, or settlement integrity.

## 2. Scope

This product area covers:

- Open API specs.
- SDKs for providers, fan apps, extensions, AI/search/recommendation tools.
- Local emulators and test sandboxes.
- Developer Console.
- CI/CD templates.
- Manifest validators.
- Conformance test suites.
- Signed artifacts and build attestations.
- Software bill of materials.
- Extension and provider submission.
- MCP server templates.
- Documentation and examples.

## 3. Key Features and Differentiators

| Feature / differentiator | Definition | Product value | Interacting product areas |
| --- | --- | --- | --- |
| Open API specs | Standard interfaces for major platform roles. | Developers can build without private platform deals. | Provider Marketplace and Certified APIs |
| SDKs and templates | Starter kits for apps, providers, extensions, and tools. | Reduces implementation cost. | Fan Apps and App Ecosystem |
| Local emulators | Simulated identity, wallet, receipts, content, and settlement. | Enables rapid prototype and testing. | MVP / Prototype Roadmap |
| Conformance tests | Automated verification of API behavior, including relationship privacy and export boundaries. | Certification can scale. | Governance, Certification, and Foundation Model |
| Verified build pipeline | Signed artifacts, SBOM, and build attestations. | Secures extension and app supply chain. | Trust, Safety, Fraud, and Compliance |
| MCP/tool integrations | AI agents can use search, recommendation, and dev tools with explicit permission scopes and audit records. | Extends Loom into AI workflows without bypassing data rights or search neutrality. | AI Layer |
| Developer marketplace | Developers earn from extensions, apps, tools, and provider services. | Creates ecosystem incentives. | Business Model and Incentive Design |

## 4. Product Experience Requirements

Developers should be able to:

- Read clear API docs.
- Generate manifests.
- Run local services.
- Test against emulators.
- Run conformance tests in CI.
- Sign artifacts.
- Submit providers, apps, or extensions.
- See certification failures with actionable output.
- Monitor usage, revenue, incidents, and audits.

## 5. User Stories

### Story 1: Developer builds extension

As a developer, I want an extension template so I can build a creator campaign tool.

End state:

- Project includes manifest, tests, runtime adapter, and CI template.
- Artifact can be signed and submitted.

### Story 2: Provider certifies API

As a provider, I want conformance tests so I can prove my service works with Loom.

End state:

- Tests run locally and in CI.
- Certification evidence is submitted.

### Story 3: App developer builds fan app

As an app developer, I want SDKs for Fan Passport, Wallet, content, search, recommendations, and extensions.

End state:

- App can authenticate fans and enforce manifests.
- App can submit for certification.

### Story 4: AI tool developer builds MCP server

As an AI tool developer, I want MCP server templates for search and recommendation tools.

End state:

- Tool can use certified APIs and respect permissions.

### Story 5: Governance audits artifact provenance

As governance, I want artifact provenance so unsafe builds can be blocked.

End state:

- Build attestation, SBOM, and signatures are verifiable.

## 6. End-to-End Workflows

### Workflow 1: Extension development

Actors:

- Developer
- Developer Console
- Local Emulator
- CI/CD System
- Extension Registry

Steps:

1. Developer creates project from extension template.
2. Developer edits `ExtensionManifest`.
3. Local emulator simulates creator install and fan runtime.
4. Tests validate permissions and API behavior.
5. CI/CD creates signed artifact, `ExtensionBuildAttestation`, and `SoftwareBillOfMaterials`.
6. Artifact is uploaded through `ExtensionArtifactAPI` to a certified Extension Artifact Host.
7. Developer submits extension.
8. `ExtensionRegistryAPI` validates artifact signature, manifest-version match, SBOM, build attestation, and `CertificationScopeRecord`.
9. Registry starts certification.
10. Fan-app runtimes fail closed when artifact, certification, manifest, or signature checks fail.

### Workflow 2: Provider certification

Actors:

- Provider Developer
- Developer Console
- Conformance Test Suite
- Provider Certification System

Steps:

1. Provider declares `ProviderCapabilityManifest`.
2. Provider accepts `ProviderParticipationTerms` and completes business/legal verification.
3. Developer runs version-pinned `ConformanceTestSuite`.
4. CI publishes test evidence and audit artifacts.
5. Provider submits certification request through `ProviderCertificationAPI`.
6. Certification system reruns tests, verifies evidence, and records `CertificationScopeRecord` by provider role, capability, API version, and geography where relevant.
7. `ProviderKeyManagementAPI` issues role-scoped signing keys after approval and supports rotation, suspension, and revocation.
8. `ProviderAuditAPI` exposes audit evidence, probe results, incidents, and remediation status.
9. Marketplace listing is created after approval.

### Workflow 3: Fan app development

Actors:

- App Developer
- SDKs
- Local Emulator
- App Certification System

Steps:

1. Developer scaffolds fan app.
2. App defines `AppCapabilityManifest`.
3. App integrates Fan Passport login, `AppPermissionGrant`, `FollowVisibilityPolicy`, `DirectContactGrant`, `DataUseGrant`, entitlements, content rendering, search, recommendations, receipts, and extension runtime.
4. Emulator provides test creators, fans, content, receipts, campaigns, search results, recommendation manifests, and extension artifacts.
5. `AppConformanceTestSuite` verifies entitlement checks, manifest enforcement, receipt generation, search neutrality, recommendation boundaries, data permissions, and extension sandboxing.
6. `AppCertificationAPI` receives submission and records `CertificationScopeRecord`.
7. `AppAuditAPI` supports continuous probes, key revocation, and suspension notices.

### Workflow 4: API version upgrade

Actors:

- Foundation/Governance
- Developer
- Provider
- App

Steps:

1. New API version is published.
2. `APIVersionRegistry` records compatibility matrix, manifest versions, receipt versions, SDK versions, and provider/app certification impact.
3. SDKs and version-pinned conformance tests update.
4. Providers and apps test compatibility against migration fixtures.
5. Certification scopes update by API version and capability.
6. Deprecation windows, breaking-change notices, and migration guides are published.
7. `CertificationScopeRecord` changes are audited and linked to provider/app signing-key eligibility.

### Workflow 5: Supply chain incident

Actors:

- Developer
- Extension Registry
- Governance Admin
- Creators
- Fan Apps

Steps:

1. Vulnerable dependency or compromised build is detected.
2. Registry checks SBOM and build attestations.
3. Affected artifacts are limited, suspended, or revoked.
4. Creators and apps are notified.
5. Developer publishes fixed signed artifact.
6. Certification is restored after validation.

## 7. Cross-Area Interactions

- Provider Marketplace and Certified APIs: developers build `ProviderCapabilityManifest` implementations and certify with `ProviderCertificationAPI`.
- Creator Plugins / Extensions / Campaign Layer: extension supply chain depends on `ExtensionArtifactAPI`, `ExtensionBuildAttestation`, `SoftwareBillOfMaterials`, and `ExtensionRegistryAPI`.
- Fan Apps and App Ecosystem: apps require `FanAppSDK`, `AppCapabilityManifest`, `AppCertificationAPI`, and `AppConformanceTestSuite`.
- Creator-Led Recommendation Economy: `RecommendationWorkbenchAPI`, `RecommendationWorkbenchMCPServer`, and `FanRecommendationMCPServer` need SDKs and tests.
- Neutral Public Search Utility: `SearchMCPServer`, `OpenSearchKernelConformance`, and `NeutralSearchMergePolicy` must preserve neutrality.
- Audience Data Firewall and Data Rights: development tools must support `DataUseGrant`, `DataAccessReceipt`, `FollowVisibilityPolicy`, `DirectContactGrant`, `CreatorAudienceExportPolicy`, and private data boundaries.
- AI Layer: MCP/tool templates use permission scopes, `CreatorAgentDelegationToken`, and `ToolCallAuditRecord`.
- Trust, Safety, Fraud, and Compliance: `ProviderIncidentReport`, `ProviderKeyManagementAPI`, and `AppRevocationWorkflow` handle supply chain incidents.
- Governance, Certification, and Foundation Model: `CertificationScopeRecord`, `ConformanceTestGovernance`, and `APIVersionRegistry` provide standards, tests, and approvals.
- Business Model and Incentive Design: `MarketplaceFeePolicy`, `DeveloperPayoutStatement`, and utility funding define developer economics.

## 8. FAQ

### What key systems and/or capabilities need to be created/implemented or modified to implement the key features, user stories, and end-to-end workflows?

- `DeveloperConsoleAPI`: projects, manifests, tests, submissions, certification, usage, and revenue.
- `OpenAPISpecRegistry`: APIs for identity, metadata, hosting, wallet, receipts, settlement, search, AI, recommendations, extensions, campaigns, and governance.
- `SDKRegistry`: provider, fan app, extension, AI/search/recommendation, and governance SDKs.
- `LocalEmulator`: creator, fan, wallet, content, extension, receipts, settlement, search, and AI test environment.
- `ManifestValidationService`: validates provider, extension, campaign, recommendation, AI, search, settlement, and migration manifests.
- `ConformanceTestSuite`: capability-specific tests pinned to API and manifest versions.
- `AppConformanceTestSuite`: app login, permissions, entitlement checks, relationship privacy controls, manifest enforcement, receipt generation, search neutrality, recommendations, and extension sandboxing.
- `APIVersionRegistry`: version registry, compatibility matrices, deprecation windows, migration fixtures, and certification impact.
- `CICDTemplateRegistry`: GitHub Actions, GitLab, and self-hosted CI.
- `ArtifactSigningService`: signed bundles and key management.
- `ExtensionArtifactAPI`: signed extension artifact upload and retrieval.
- `ExtensionRegistryAPI`: extension submission, certification, revocation, and marketplace publication.
- `ExtensionBuildAttestation`: provenance and build evidence.
- `SoftwareBillOfMaterials`: dependency transparency.
- `CertificationScopeRecord`: approved provider/app/extension capabilities and API-version scope.
- `ProviderParticipationTerms`: provider legal/business obligations.
- `ProviderCertificationAPI`: provider certification submission and status.
- `ProviderKeyManagementAPI`: role-scoped signing-key issuance, rotation, suspension, and revocation.
- `ProviderAuditAPI`: audit evidence, probes, incidents, and remediation.
- `AppCapabilityManifest`: app surfaces, data use, extension runtime, devices, and API versions.
- `AppCertificationAPI`: fan-app certification submission and status.
- `AppPermissionGrant`: app access scopes.
- `FollowVisibilityPolicy`: app/provider/extension test fixture for relationship visibility behavior.
- `DirectContactGrant`: app/provider/extension test fixture for direct-contact permission and revocation.
- `CreatorAudienceExportPolicy`: conformance fixture for creator audience export field limits, destinations, retention, no-resale, watermarking, and breach-notice behavior.
- `AppAuditAPI`: app privacy, receipt, manifest, search, recommendation, and extension behavior checks.
- `SearchMCPServer`: search tool template with `NeutralSearchMergePolicy` and no paid-ranking/search-ad behavior.
- `RecommendationWorkbenchMCPServer`: creator recommendation research and draft tools.
- `FanRecommendationMCPServer`: fan-scoped recommendation tools, including summary-first relevance and title-deemphasis options over eligible creator/recommendation candidates.
- `CreatorAgentDelegationToken`: scoped creator-agent tool access.
- `DataUseGrant`: private-context permission where MCP tools access private data.
- `ToolCallAuditRecord`: MCP/tool-call audit record.
- `TestSandbox`: safe test data and simulated providers.
- `DeveloperDocs`: reference implementations and guides.
