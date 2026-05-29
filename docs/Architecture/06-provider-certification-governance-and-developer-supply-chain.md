# Loom Architecture 06: Provider Certification, Governance, And Developer Supply Chain

Status: Draft for review  
Source workflow map: `docs/Architecture/02-workflow-inventory-and-function-map.md`

## 1. Purpose

This document defines transaction packet models for provider/app/extension certification, provider marketplace discovery, continuous audit, API version governance, key revocation, developer tooling, conformance tests, supply-chain incidents, disputes, privacy governance, and utility fee governance.

## 2. Functional System Diagram

```mermaid
flowchart TB
  Provider[Provider]
  Developer[Developer]
  AppDev[App Developer]
  Governance[Governance]
  Creator[Creator]
  FanApp[Fan App]

  DeveloperConsole[Developer Console]
  ProviderConsole[Provider Console]
  GovernanceAdmin[Governance Admin]
  CreatorStudio[Creator Studio]

  Certification[Certification System]
  Conformance[Conformance Test Suite]
  ProviderRegistry[Provider Capability Registry]
  Marketplace[Marketplace Listing API]
  AppRegistry[App Marketplace / App Certification]
  ExtensionRegistry[Extension Registry]
  APIVersionRegistry[API Version Registry]
  KeyManagement[Provider Key Management]
  Audit[Provider / App / Extension Audit APIs]
  Incident[Incident / Supply Chain Response]
  Dispute[Dispute Resolution System]
  PublicRegistry[Public Registry Read Model]

  Provider --> ProviderConsole
  Developer --> DeveloperConsole
  AppDev --> DeveloperConsole
  Governance --> GovernanceAdmin
  Creator --> CreatorStudio
  FanApp --> ProviderRegistry

  DeveloperConsole --> Certification
  ProviderConsole --> Certification
  GovernanceAdmin --> Certification
  Certification --> Conformance
  Certification --> ProviderRegistry
  Certification --> AppRegistry
  Certification --> ExtensionRegistry
  Certification --> KeyManagement
  Certification --> PublicRegistry
  ProviderRegistry --> Marketplace
  AppRegistry --> Marketplace
  ExtensionRegistry --> Marketplace
  APIVersionRegistry --> Certification
  Audit --> Incident
  Incident --> Dispute
  KeyManagement --> PublicRegistry
  GovernanceAdmin --> APIVersionRegistry
  GovernanceAdmin --> Audit
  GovernanceAdmin --> Dispute
  CreatorStudio --> Marketplace
```

## 3. Packet Envelope

| Field | Meaning |
| --- | --- |
| `actorIdentity` | Provider, developer, app, extension, governance, or creator identity and signing keys. |
| `capabilityContext` | Service role, capability, API version, manifest version, geography, data scope, and certification target. |
| `evidenceContext` | Test results, artifacts, build attestation, SBOM, audit logs, incident evidence, and manual review notes. |
| `keyContext` | Public keys, signing keys, key scope, rotation state, suspension state, and revocation evidence. |
| `registryContext` | Provider/app/extension listing state, certification state, restrictions, incidents, and public records. |
| `versionContext` | API version, deprecation window, migration fixture, compatibility matrix, and required upgrade timeline. |
| `governanceContext` | Policy authority, dispute case, privacy/data-rights issue, utility fee policy, and public comment state. |

## 4. Interfaces And Contracts

| Interface or contract | Packet responsibility |
| --- | --- |
| `ProviderCapabilityManifest` | Declares provider roles, versions, regions, pricing, data use, export support, and keys. |
| `ProviderCertificationAPI` | Submits and resolves provider certification requests. |
| `AppCertificationAPI` | Submits and resolves fan-app certification requests. |
| `ExtensionManifest` | Declares extension surfaces, permissions, risk tier, pricing, export behavior, and runtime needs. |
| `ExtensionArtifactAPI` | Stores and retrieves signed extension artifacts. |
| `ExtensionBuildAttestation` | Build provenance evidence for extension artifacts. |
| `SoftwareBillOfMaterials` | Dependency and supply-chain transparency evidence. |
| `ConformanceTestSuite` | Capability-specific tests pinned to API/manifest versions. |
| `AppConformanceTestSuite` | App tests for login, grants, manifests, receipts, search, recommendations, privacy controls, and sandboxing. |
| `CertificationScopeRecord` | Certified role, version, state, restrictions, expiration, key scope, and public status. |
| `ProviderCapabilityRegistry` | Durable provider capability, certification, key, incident, and version state. |
| `MarketplaceListingAPI` | Public and creator/app-facing listings and comparisons. |
| `ProviderAuditAPI` | Audit probes, evidence, incidents, and remediation. |
| `AppAuditAPI` | App privacy, receipt, manifest, search, recommendation, and extension audits. |
| `ProviderKeyManagementAPI` | Key issuance, rotation, suspension, revocation, and recovery. |
| `APIVersionRegistry` | API and manifest versions, deprecation windows, migration fixtures, and certification impact. |
| `DisputeCaseRecord` | Append-only dispute evidence and outcome record. |
| `PublicRegistryReadModel` | Public status for providers, apps, extensions, keys, incidents, versions, and marks. |
| `UtilityFeePolicy` | Shared utility funding scope, caps, covered utilities, and reporting requirements. |

## 5. Workflow Transaction Packet Models

| Ref | Trigger | Primary packet path | Durable writes / receipts | Completion response |
| --- | --- | --- | --- | --- |
| `07/W1` | Provider registers/certifies. | Provider Console -> Certification -> Conformance -> Registry -> Marketplace. | Capability manifest, certification scope, key state, listing. | Provider listed by certified role. |
| `07/W2` | Creator selects provider. | Creator Studio -> Marketplace -> Registry -> Metadata boundary. | Provider role grant. | Provider attached to creator role. |
| `07/W3` | App discovers capabilities. | App -> Provider Discovery -> Registry. | No durable write unless selection stored. | Certified provider endpoint/key returned. |
| `07/W4` | Continuous provider audit. | Governance/Audit -> Provider -> Registry/Incident. | Audit evidence, incident, remediation state. | Certification unchanged, limited, suspended, or revoked. |
| `07/W5` | Provider version migration. | Provider/Governance -> API Version Registry -> Certification -> Marketplace. | Version state and migration schedule. | Apps/creators migrate before deprecation. |
| `15/W5` | App certification. | App Developer -> App Certification -> App conformance -> Marketplace. | App certification scope and listing. | Certified app can operate. |
| `16/W1` | Extension development. | Developer -> SDK/test/build/sign -> Extension Registry. | Signed artifact, manifest, attestation, listing. | Extension ready for certification/listing. |
| `16/W2` | Provider certification. | Developer Console -> Provider Certification -> Conformance. | Certification evidence and scope. | Provider capability certified or denied. |
| `16/W3` | Fan app development. | App Developer -> SDK -> app tests -> certification. | App manifest, test evidence, certification request. | App approved or remediation returned. |
| `16/W4` | API version upgrade. | Governance -> API Version Registry -> SDK/tests -> certification impact. | Version record, compatibility matrix, deprecation windows. | Ecosystem migration plan published. |
| `16/W5` | Supply chain incident. | Audit/incident -> registry/key revocation -> apps/runtime. | Incident record, revocation/suspension, remediation. | Unsafe artifacts blocked. |
| `19/W1` | Capability certification. | Actor -> Certification -> Conformance -> Registry/Public read model. | `CertificationScopeRecord`. | Capability approved, limited, or rejected. |
| `19/W2` | Continuous audit. | Governance -> Audit APIs -> registry state. | Audit case, evidence, lifecycle state. | Scope remains or changes state. |
| `19/W3` | Dispute resolution. | Actor -> Dispute System -> evidence systems -> outcome. | `DisputeCaseRecord`. | Outcome and appeal/remediation path. |
| `19/W4` | API version governance. | Foundation -> API Version Registry -> public comment -> migration. | Version policy and deprecation state. | New API/manifest version lifecycle. |
| `19/W5` | Key revocation. | Incident/governance -> Key Management -> public registry/runtime. | Key suspension/revocation record. | Runtime rejects invalid key scope. |
| `19/W6` | Privacy/data-rights governance. | Report/audit -> governance -> audit APIs -> remediation. | Privacy case, restrictions, notices. | Grants/scopes revoked or corrected. |
| `19/W7` | Utility fee governance. | Foundation -> policy -> settlement/public reports. | `UtilityFeePolicy` and reports. | Shared infrastructure funding rules active. |

## 6. Step-By-Step Life Of A Packet Overlays

### 6.1 `07/W1`: Provider Registration And Certification

```mermaid
sequenceDiagram
  actor P as Provider
  participant PC as Provider Console
  participant Cert as Certification System
  participant Test as Conformance Test Suite
  participant Reg as Provider Capability Registry
  participant KM as Key Management
  participant ML as Marketplace Listing

  P->>PC: Register provider and capability
  PC->>Cert: Submit ProviderCapabilityManifest
  Cert->>Test: Run role conformance
  Test-->>Cert: Test evidence
  Cert->>Reg: Write CertificationScopeRecord
  Cert->>KM: Issue/bind scoped keys
  Reg->>ML: Publish listing
  ML-->>P: Certified listing status
```

1. Provider submits identity, public keys, role, API versions, pricing, data use, export support, and terms.
2. Certification system runs role-specific conformance tests.
3. Approved capability creates `CertificationScopeRecord`.
4. Key management binds signing keys to capability scope.
5. Marketplace publishes provider listing and restrictions.

### 6.2 `07/W2`: Creator Selects A Provider

```mermaid
sequenceDiagram
  actor C as Creator
  participant CS as Creator Studio
  participant ML as Marketplace Listing
  participant Reg as Provider Registry
  participant CMH as Creator Metadata Host

  C->>CS: Compare provider role
  CS->>ML: Query certified alternatives
  ML->>Reg: Fetch capability and scorecard
  Reg-->>ML: Certified provider records
  ML-->>CS: Comparisons and terms
  C->>CS: Select provider
  CS->>CMH: Write ProviderRoleGrant
  CS-->>C: Provider attached
```

1. Creator chooses a provider role such as host, AI, analytics, ads, or settlement.
2. Marketplace returns certified alternatives, prices, incidents, and export support.
3. Creator confirms provider.
4. Metadata Host stores `ProviderRoleGrant` and role manifest.
5. Runtime services can route calls to the selected certified provider.

### 6.3 `07/W3`: App Discovers Provider Capabilities

```mermaid
sequenceDiagram
  participant App as Fan App / Service
  participant Discovery as ProviderDiscoveryAPI
  participant Reg as Provider Capability Registry
  participant KM as Key Registry

  App->>Discovery: Request provider by capability/version/region
  Discovery->>Reg: Query certified scopes
  Reg-->>Discovery: Provider candidates
  Discovery->>KM: Resolve active keys
  KM-->>Discovery: Key and revocation state
  Discovery-->>App: Certified endpoint and policy metadata
```

1. App requests provider by capability, version, geography, and policy requirements.
2. Registry returns certified provider scopes.
3. Discovery resolves active keys and revocation state.
4. App receives endpoint, key, API version, and restrictions.

### 6.4 `07/W4`: Continuous Provider Audit

```mermaid
sequenceDiagram
  participant Gov as Governance / Audit Scheduler
  participant Audit as ProviderAuditAPI
  participant P as Provider
  participant Reg as Provider Registry
  participant Incident as Incident System

  Gov->>Audit: Start audit probe
  Audit->>P: Request evidence/API responses
  P-->>Audit: Evidence and responses
  Audit->>Audit: Evaluate conformance and policy
  alt Violation
    Audit->>Incident: Open incident/remediation
    Audit->>Reg: Set Limited/Suspended/Revoked
  else Pass
    Audit->>Reg: Record audit pass
  end
```

1. Audit is scheduled or triggered.
2. Provider supplies evidence or API responses.
3. Audit checks conformance, receipts, data use, export, keys, and incident obligations.
4. Registry state remains certified or changes to limited/suspended/revoked.
5. Incident system tracks remediation.

### 6.5 `07/W5`: Provider Version Migration

```mermaid
sequenceDiagram
  actor P as Provider
  participant API as API Version Registry
  participant Cert as Certification System
  participant ML as Marketplace Listing
  participant Apps as Apps / Creators

  P->>API: Declare new supported version
  API->>Cert: Determine certification impact
  Cert-->>API: Required tests and compatibility
  API->>ML: Publish version support/deprecation
  ML-->>Apps: Migration deadline and docs
```

1. Provider declares new API or manifest version.
2. API Version Registry records support and compatibility.
3. Certification system identifies required tests.
4. Marketplace publishes support and deprecation windows.
5. Apps and creators migrate before old versions retire.

### 6.6 `15/W5`: App Certification

```mermaid
sequenceDiagram
  actor Dev as App Developer
  participant DC as Developer Console
  participant Cert as AppCertificationAPI
  participant Tests as AppConformanceTestSuite
  participant Listing as App Marketplace Listing

  Dev->>DC: Submit AppCapabilityManifest
  DC->>Cert: Start app certification
  Cert->>Tests: Run app conformance
  Tests-->>Cert: Evidence and failures
  alt Pass
    Cert->>Listing: Publish app certification
  else Fail
    Cert-->>DC: Remediation report
  end
```

1. App developer submits app manifest, surfaces, data use, devices, and extension runtime support.
2. App tests verify login, grants, manifests, receipts, search neutrality, recommendation boundaries, privacy controls, and sandboxing.
3. Passing app receives certification scope and listing.
4. Failing app receives remediation report.

### 6.7 `16/W1`: Extension Development

```mermaid
sequenceDiagram
  actor Dev as Extension Developer
  participant SDK as SDK / Local Emulator
  participant CI as Build Pipeline
  participant Registry as Extension Registry
  participant Cert as Certification System

  Dev->>SDK: Scaffold and test extension
  SDK-->>Dev: Local test results
  Dev->>CI: Build signed artifact
  CI-->>Dev: Artifact, SBOM, attestation
  Dev->>Registry: Submit ExtensionManifest and artifact
  Registry->>Cert: Start certification if requested
```

1. Developer scaffolds extension using SDK.
2. Local emulator runs manifest, permission, and sandbox tests.
3. Build pipeline signs artifact and emits SBOM/attestation.
4. Extension Registry stores manifest and artifact.
5. Certification can proceed using submitted evidence.

### 6.8 `16/W2`: Provider Certification

```mermaid
sequenceDiagram
  actor Dev as Provider Developer
  participant DC as Developer Console
  participant Cert as ProviderCertificationAPI
  participant Tests as ConformanceTestSuite
  participant Reg as Provider Registry

  Dev->>DC: Register provider capability
  DC->>Cert: Submit manifest and evidence
  Cert->>Tests: Run version-pinned tests
  Tests-->>Cert: Pass/fail evidence
  Cert->>Reg: Record scope if passed
  Cert-->>DC: Status and remediation
```

1. Provider developer submits capability manifest and evidence.
2. Version-pinned tests validate API behavior.
3. Certification records approved scope or returns remediation.
4. Registry and marketplace update on approval.

### 6.9 `16/W3`: Fan App Development

```mermaid
sequenceDiagram
  actor Dev as App Developer
  participant SDK as FanAppSDK
  participant Sandbox as Test Sandbox
  participant Cert as AppCertificationAPI
  participant Listing as App Marketplace

  Dev->>SDK: Build app integrations
  SDK->>Sandbox: Test identity, grants, wallet, content, search, extensions
  Sandbox-->>Dev: Test evidence
  Dev->>Cert: Submit AppCapabilityManifest
  Cert-->>Listing: Publish if approved
```

1. Developer integrates Fan Passport, grants, entitlements, content, search, recommendations, receipts, and extension runtime.
2. Test sandbox produces conformance evidence.
3. App capability manifest is submitted.
4. Certification publishes approved app or returns fixes.

### 6.10 `16/W4`: API Version Upgrade

```mermaid
sequenceDiagram
  participant Gov as Governance
  participant API as API Version Registry
  participant SDK as SDK Registry
  participant Tests as Conformance Tests
  participant Actors as Providers / Apps / Extensions

  Gov->>API: Propose new API version
  API->>SDK: Publish updated SDK/contracts
  API->>Tests: Publish version-pinned tests
  API-->>Actors: Deprecation and migration windows
  Actors->>Tests: Re-certify impacted capabilities
```

1. Governance proposes version change.
2. Registry records compatibility, migration fixtures, and deprecation dates.
3. SDKs and tests update.
4. Impacted actors re-certify.
5. Older versions retire after migration window.

### 6.11 `16/W5`: Supply Chain Incident

```mermaid
sequenceDiagram
  participant Audit as Audit / Security Scanner
  participant Incident as Incident System
  participant Registry as Extension/App Registry
  participant KM as Key Management
  participant Runtime as Apps / Runtime Gateways

  Audit->>Incident: Report vulnerable artifact or dependency
  Incident->>Registry: Mark artifact/app limited or suspended
  Incident->>KM: Rotate or revoke keys if needed
  Registry-->>Runtime: Revocation state
  Runtime-->>Runtime: Fail closed or disable feature
```

1. Scanner or report identifies supply-chain risk.
2. Incident system records affected artifact, app, provider, or extension.
3. Registry changes lifecycle state.
4. Keys rotate or revoke if needed.
5. Runtime gates fail closed until remediation.

### 6.12 `19/W1`: Capability Certification

```mermaid
sequenceDiagram
  actor Actor as Provider / App / Extension
  participant Cert as Certification System
  participant Tests as Conformance Tests
  participant Gov as Governance Admin
  participant Registry as Canonical Registries
  participant Public as Public Registry Read Model

  Actor->>Cert: Submit manifest and terms
  Cert->>Tests: Run required tests
  Tests-->>Cert: Evidence
  Cert->>Gov: Manual review if high risk
  Gov-->>Cert: Decision
  Cert->>Registry: Write CertificationScopeRecord
  Registry->>Public: Publish status
```

1. Actor submits correct manifest and accepts terms.
2. Tests run for capability, version, geography, data scope, and signing role.
3. Governance reviews high-risk scopes.
4. Certification scope is recorded.
5. Public registry exposes status, keys, incidents, and versions.

### 6.13 `19/W2`: Continuous Audit

```mermaid
sequenceDiagram
  participant Gov as Governance
  participant Audit as Audit APIs
  participant Actor as Provider/App/Extension
  participant Registry as Canonical Registries
  participant Notify as User Notices

  Gov->>Audit: Schedule or trigger audit
  Audit->>Actor: Request evidence
  Actor-->>Audit: Evidence/API responses
  Audit->>Registry: Update audit state
  alt Revoked/Suspended
    Registry->>Notify: Notify affected users/runtimes
  end
```

1. Audit is triggered by schedule, incident, or probe.
2. Actor provides evidence.
3. Audit checks conformance, data use, receipts, manifests, keys, export, and policy.
4. Certification status changes if needed.
5. Affected users/runtimes are notified.

### 6.14 `19/W3`: Dispute Resolution

```mermaid
sequenceDiagram
  actor A as Creator/Fan/Provider/Sponsor/Developer
  participant DS as Dispute Resolution
  participant Evidence as Evidence Systems
  participant Gov as Governance Admin
  participant Outcome as Outcome / Remediation

  A->>DS: File dispute
  DS->>Evidence: Gather receipts, manifests, contracts, audits
  Evidence-->>DS: Evidence bundle
  DS->>Gov: Review case
  Gov-->>DS: Decision
  DS->>Outcome: Apply adjustment or remediation
  DS-->>A: Outcome and appeal path
```

1. Actor files dispute.
2. System gathers receipts, manifests, contracts, audit records, and provider evidence.
3. Governance reviews evidence.
4. Outcome can adjust settlement, require export, reinstate access, revoke scope, or deny claim.
5. Append-only case record stores decision and appeal path.

### 6.15 `19/W4`: API Version Governance

```mermaid
sequenceDiagram
  participant Foundation as Foundation
  participant API as API Version Registry
  participant Public as Public Comment
  participant Tests as Conformance Governance
  participant Ecosystem as Providers/Apps/Developers

  Foundation->>API: Propose version/policy change
  API->>Public: Publish proposal and migration impact
  Public-->>API: Comments
  API->>Tests: Update required pass criteria
  API-->>Ecosystem: Final version and deprecation window
```

1. Foundation proposes API or manifest version change.
2. Public proposal includes compatibility and migration impact.
3. Comments are reviewed.
4. Test ownership and pass criteria update.
5. Final version and deprecation windows are published.

### 6.16 `19/W5`: Key Revocation

```mermaid
sequenceDiagram
  participant Incident as Incident / Report
  participant KM as Key Management
  participant Registry as Public Registry
  participant Runtime as Runtime Services
  participant Audit as Audit Trail

  Incident->>KM: Request key suspension/revocation
  KM->>KM: Validate actor, scope, and severity
  KM->>Registry: Publish key status
  Registry-->>Runtime: Revocation state
  Runtime-->>Runtime: Reject invalid signatures
  KM->>Audit: Record key action
```

1. Incident, audit, or governance action triggers key review.
2. Key Management validates affected actor, capability, version, service role, and severity.
3. Key status is suspended or revoked.
4. Runtime systems reject invalid signatures.
5. Audit trail preserves pre-revocation receipt validity by key-time evidence.

### 6.17 `19/W6`: Privacy And Data-Rights Governance

```mermaid
sequenceDiagram
  participant Report as Report / Audit Probe
  participant Gov as Governance Admin
  participant Audit as Provider/App/Extension Audits
  participant Registry as Registries
  participant Notify as Fan/Creator Notices

  Report->>Gov: Suspected data misuse
  Gov->>Audit: Request evidence and remediation
  Audit-->>Gov: Grant, access, export, tombstone evidence
  Gov->>Registry: Restrict, suspend, or revoke scopes
  Gov->>Notify: Required notices
```

1. Report or audit identifies possible privacy misuse.
2. Governance reviews grants, receipts, export/delete records, relationship records, tombstones, and revocation state.
3. Audit systems collect remediation evidence.
4. Governance can revoke grants, rotate keys, block runtime, require deletion, or suspend scopes.
5. Fan/creator notices and disputes follow policy.

### 6.18 `19/W7`: Utility Fee Governance

```mermaid
sequenceDiagram
  participant Foundation as Foundation
  participant Policy as UtilityFeePolicy
  participant Settlement as Settlement Engine
  participant Reports as Public Utility Reports

  Foundation->>Policy: Publish fee caps and covered utilities
  Policy->>Settlement: Provide allocation rules
  Settlement-->>Policy: Utility funding receipts and totals
  Policy->>Reports: Publish transparency report
```

1. Foundation publishes utility fee caps, covered utilities, conflict rules, and transparency requirements.
2. Settlement applies the policy through settlement manifests.
3. Utility funding receipts explain identity, vault, search, settlement, and governance funding.
4. Public reports show budgets, fees, and policy changes.

## 7. Error And Recovery Behavior

| Condition | Required behavior |
| --- | --- |
| Conformance test fails | Certification remains draft/submitted; remediation report is returned. |
| High-risk capability lacks manual approval | Certification remains blocked or limited. |
| Provider key revoked | Runtime rejects signatures for affected key scope and exposes fallback/degraded state. |
| Version deprecation missed | Capability can become limited or suspended until upgraded. |
| Supply-chain artifact revoked | Extension/app runtime fails closed and notifies affected creators/apps. |
| Privacy audit finds misuse | Grants/scopes can be revoked, data deletion verified, and affected users notified. |
