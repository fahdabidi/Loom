# Loom Communities V2 Build Tracker

Status: Draft execution ledger

This tracker records what each phase is intended to achieve, what it must deliver, what counts as
completed, and the evidence captured when the phase is closed. Update it at the end of every phase
before starting the next phase.

Source rules: [Rules.md](./Rules.md)  
Source manifest: [test-manifest.json](./test-manifest.json)

## How To Use This Tracker

For each phase:

1. Confirm the predecessor phase is complete.
2. Run the prerequisite gate in the phase file from WSL Ubuntu.
3. Execute the phase deliverables.
4. Run all required validation, contract, workflow, manifest, and staleness gates.
5. Stage only the phase's intended changes and review `git diff --staged`.
6. Commit the phase changes to git.
7. Record component version hashes, API/UX/Skill artifacts, gate evidence, and the resulting commit SHA.
8. Start the next phase only after the commit exists and this tracker points to that SHA.

Set B workflow tests must run against the Demo Loom Communities App with the Local Backend. The Skill
supports both `local-demo` and `real-backend-publish` modes, but no Set B gate may depend on an
external backend. The first supported Skill execution targets are Codex and Claude Code; online-only
support is deferred until a hosted Loom build and validation backend exists. All Dart, Flutter, Melos,
package-validation, phase-gate, manifest-gate, and workflow-test commands run from WSL Ubuntu using:

```powershell
wsl.exe -d Ubuntu -- bash -lc 'cd "/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app" && <command>'
```

## Phase Status Tracker

| Phase | Status | Required predecessor | Phase doc | Primary completion checkpoint | Gate evidence | Commit SHA |
| --- | --- | --- | --- | --- | --- | --- |
| 0 | Complete | None | [Initialize Build](./Phases/Phase%200%20-%20Initialize%20Build.md) | Rules, manifest, tracker, Skill skeleton, Skill setup manifest, workspace scaffold, and gates exist. | WSL Ubuntu toolchain verified; `dart format`, `melos bootstrap`, manifest gate, phase gate with `--check-env`, Skill prereq setup/check, boundary lint, and focused scaffold analysis passed. | `17b4b81` |
| A1 | Complete | 0 | [Foundation Components](./Phases/Phase%20A1%20-%20Foundation%20Components.md) | Foundation contracts, fakes, stores, validation tests, and provider test kits pass. | A1 contracts/fakes/schema/seed/test suite added; validation tests pass; consumer-contract kits are pending only for unbuilt counterparts; manifest and phase gates pass in WSL Ubuntu. | `e3c0357` |
| A2 | Complete | A1 | [Registry and Control-Plane Components](./Phases/Phase%20A2%20-%20Registry%20and%20Control-Plane%20Components.md) | Registry/control-plane components pass tests to and from built providers. | A2 contracts/fakes/schema/seed/test suite added; A1 unblocked contract tests pass; App Shell counterpart tests remain pending; manifest and phase gates pass in WSL Ubuntu. | `3d6a388` |
| A3 | Complete | A2 | [Service Components I](./Phases/Phase%20A3%20-%20Service%20Components%20I%20%28Experience%20Core%29.md) | Experience service components pass validation and unblocked contract tests. | A3 contracts/fakes/schema/seed/test suite added; forms/protected-vault contract passes; A4b/A5/A6 consumer tests remain pending; manifest and phase gates pass in WSL Ubuntu. | `a4cc268` |
| A4a | Complete | A3 | [Service Components II](./Phases/Phase%20A4a%20-%20Service%20Components%20II%20%28Ops%20and%20Community%29.md) | Ops/community services pass validation and unblocked contract tests. | A4a contracts/fakes/schema/seed/test suite added; document/export, import/protected-vault, incident/certification contracts pass; A4b/A5 consumer tests remain pending; manifest and phase gates pass in WSL Ubuntu. | `c56f45b` |
| A4b | Complete | A4a | [Service Components III](./Phases/Phase%20A4b%20-%20Service%20Components%20III%20%28Economic%20Search%20and%20Ads%29.md) | Economic/search/ad services pass validation and unblocked contract tests. | A4b contracts/fakes/schema/seed/test suite added; wallet/ad decision, search/AI/digest, settlement/utility, receipt/settlement, fraud/dispute, and earlier unblocked provider contracts pass; A6 consumer tests remain pending; manifest and phase gates pass in WSL Ubuntu. | `4ab715d` |
| A5 | Complete | A4b | [Extension Engine Components](./Phases/Phase%20A5%20-%20Extension%20Engine%20Components.md) | Runtime, rules, workflows, package validator, and initialization package contracts pass. | A5 contracts/fakes/schema/seed/test suite added; runtime/rules/workflows/jobs/functions/schema/secrets/package/init validations pass; engine-unblocked provider contracts pass; A6/B1a consumer tests remain pending; manifest and phase gates pass in WSL Ubuntu. | `b4c8b25` |
| A6 | Complete | A5 | [UX Components](./Phases/Phase%20A6%20-%20UX%20Components.md) | App Shell, UX micro-components, Demo App, and Local Backend Adapter pass. | A6 shell/local-backend/demo app contracts and tests added; all Set A pending counterpart tests are resolved; Demo App starts empty, Add Community loads a local sample package/init package, cards render, and local backend import/reload passes; manifest and phase gates pass in WSL Ubuntu. | Pending A6 commit |
| B1a | Not started | A6 | [Local Build Download Sideload Install](./Phases/Phase%20B1a%20-%20Local%20Build%20Download%20Sideload%20Install.md) | Skill prereq setup, local package/init package, fake backend import, card render, and local open pass. | TBD | TBD |
| B1b | Not started | B1a | [Publish Discover Certify Install](./Phases/Phase%20B1b%20-%20Publish%20Discover%20Certify%20Install.md) | Real-backend publish mode is validated through local stubs/contracts. | TBD | TBD |
| B2 | Not started | B1b | [Book Club Headline Flow](./Phases/Phase%20B2%20-%20Book%20Club%20Headline%20Flow.md) | Book club workflow passes in the Demo App with Local Backend. | TBD | TBD |
| B3 | Not started | B2 | [Youth Soccer Headline Flow](./Phases/Phase%20B3%20-%20Youth%20Soccer%20Headline%20Flow.md) | Youth soccer workflow passes in the Demo App with Local Backend. | TBD | TBD |
| B4 | Not started | B3 | [HOA Headline Flow](./Phases/Phase%20B4%20-%20HOA%20Headline%20Flow.md) | HOA workflow passes in the Demo App with Local Backend. | TBD | TBD |
| B5 | Not started | B4 | [Mosque Headline Flow](./Phases/Phase%20B5%20-%20Mosque%20Headline%20Flow.md) | Mosque workflow passes in the Demo App with Local Backend. | TBD | TBD |
| B6 | Not started | B5 | [Messaging In-Stream Ads and Connections](./Phases/Phase%20B6%20-%20Messaging%20In-Stream%20Ads%20and%20Connections.md) | Messaging, connections, ad surfaces, and shell invariants pass. | TBD | TBD |
| B7 | Not started | B6 | [Ad-Off](./Phases/Phase%20B7%20-%20Ad-Off.md) | Ad-off purchase, ad suppression, receipts, settlement, and utility funding pass. | TBD | TBD |
| B8 | Not started | B7 | [Export and Migration](./Phases/Phase%20B8%20-%20Export%20and%20Migration.md) | Export/migration, redaction, full workflow suite, and API spec inventory pass. | TBD | TBD |

## Phase Outcome Summary

| Phase | What This Phase Achieves | Main Deliverables | Completed In This Phase |
| --- | --- | --- | --- |
| 0 | Establishes the execution system. | Rules, manifest, tracker, Skill skeleton, Skill setup/prereq manifest, workspace package placeholders, phase gates, API inventory scaffold. | The build system can identify every planned component/workflow test, supported local execution target, and manifest/staleness/setup gate. |
| A1 | Builds the foundation layer. | Identity/passport, roles/policy/consent, vaults, connections, receipts, audit, event bus, keys, builder App ID, local store baseline. | Foundational APIs, fakes, owned stores, seed fixtures, and provider-authored contract tests are available. |
| A2 | Builds registry and control-plane services. | Community registry, community branding, spaces, membership, invitations, extension registry, certification, certification asset evidence, public registry, workflow inventory. | Communities, spaces, membership, branding, extension versions, and certification status can be represented through contracts/fakes. |
| A3 | Builds experience-core services. | Publishing, messaging/stream, notifications, events, forms/polls/voting. | Core community interactions can be validated against foundation and registry fakes. |
| A4a | Builds ops/community services. | Cases/tasks, documents, facilities, import/export, provider transfer, abuse reports, moderation, incidents, disputes. | Operational and portability behaviors exist with validation and consumer-contract tests. |
| A4b | Builds economic/search/ad services. | Wallet/dues/donations, ad decision/campaigns, search, AI gateway, digest, settlement, utility funding, fraud signals. | Payments, ads, search/AI, receipts-adjacent settlement, and economic flows are contract-testable. |
| A5 | Builds extension engine components. | Runtime bridge, rules, workflows, jobs, functions, schemas, secrets/connectors, extension package validator, initialization package schema, asset manifest validation, initialization branding schema. | The Skill can target documented extension/package contracts, bundled asset contracts, and local initialization package contracts. |
| A6 | Builds UX and local demo runtime. | App Shell, branded community cards, nav panel, stream renderer, connections shell, ad slots, payment surface, data dashboard, Demo App, Local Backend Adapter. | The Demo App can start empty, expose Add Community, load local files, import fake-backend data and branding, persist locally, render branded cards, and host extensions. |
| B1a | Proves local extension creation and install. | Skill prereq setup, validation environment lock, Skill `local-demo` workflow, downloadable extension package, initialization package, bundled branding assets, local file load, fake backend import, branded community card, local latest open. | A user can validate the local toolchain, create/download an extension and initialization package, sideload them into the Demo App, see the branded community card, and run the community locally. |
| B1b | Proves real-backend publish mode locally. | Skill `real-backend-publish` workflow, publish/certify/discover/install contracts, local backend stubs/fakes for hosted APIs. | Hosted publish behavior is validated without requiring an external backend. |
| B2 | Validates the book club vertical. | Book nomination, voting, meeting event, discussion, search/digest, worked Skill example. | Book club extension works end to end in the Demo App with Local Backend. |
| B3 | Validates the youth soccer vertical. | Guardian/minor protected data, registration payment, roster, schedule, notifications, worked Skill example. | Youth soccer extension works end to end with protected-data and payment assertions. |
| B4 | Validates the HOA vertical. | Dues, documents, facility reservations, architectural request, workflow review, export coverage, worked Skill example. | HOA extension works end to end with docs, facilities, payments, case workflow, and export coverage. |
| B5 | Validates the mosque vertical. | Announcements, events, volunteer signup, donations with visibility controls, protected care requests, worked Skill example. | Mosque extension works end to end with sensitive-data and donation behavior. |
| B6 | Validates required social and ad surfaces. | Messages, Connections, invite/block behavior, stream rendering, in-stream ads, top banner behavior. | Platform invariants are proven: Messages and Connections are reachable, ads render or no-fill correctly, extensions cannot suppress required surfaces. |
| B7 | Validates ad-off economics. | Member/community ad-off purchase, entitlement checks, ad decision behavior, receipts, settlement, utility allocation. | Ad-off works end to end and economic records stay auditable. |
| B8 | Closes portability and final readiness. | Export/migration, redaction, transfer verification/rollback, full workflow regression, API spec inventory, final Skill/example updates. | Every workflow remains green, every required API/local contract is present and validated, and V2 is ready for roadmap review. |

## Per-Phase Completion Ledger

### Phase 0 - Initialize Build

- **Achieves:** Creates the build constitution and all control artifacts.
- **Deliverables:** `Rules.md`, `test-manifest.json`, `Test Manifest.md`, Build Tracker, Skill skeleton,
  Skill setup docs, prereq manifest, placeholder validation environment lock, workspace package
  placeholders, `manifest_gate`, `phase_gate`, API inventory placeholder.
- **Completed when:** Manifest parses; planned/pending tests are registered; Skill skeleton exists;
  Skill setup manifest and placeholder lock parse; workspace scaffolds and gate placeholders exist; API
  Review is filed; tracker records SHA.
- **Evidence to record:** Manifest parse output, prereq manifest parse output, placeholder lock parse
  output, gate placeholder output, created package paths, API Review path, Skill paths, commit SHA.

#### Execution Record - 2026-06-08

- **Created/confirmed scaffold:** `apps/loom_communities_demo`, `loom_extension_package`,
  `loom_demo_local_backend`, `api_spec_inventory`, `loom_skill_prereq_setup`,
  `loom_skill_debug_harness`, and top-level tooling scripts for manifest, phase, prereq setup, and
  prereq check gates.
- **Registered workspace entries:** Added the new V2 app/package namespaces to `app/pubspec.yaml`; added
  melos commands for `manifest:gate`, `phase:gate`, `skill:prereq:check`, and `skill:prereq:setup`.
- **Passed checks:** `test-manifest.json`, `prereq-manifest.json`, and
  `validation-environment.lock.json` parse; manifest component/test references validate; Skill prereq
  targets are `codex` and `claude-code`; required scaffold paths exist; melos gate scripts are present.
- **WSL toolchain:** Ubuntu 24.04 on WSL2; `dart` resolves to `/home/fahd_/flutter/bin/dart`,
  `flutter` resolves to `/home/fahd_/flutter/bin/flutter`, and `melos` resolves to
  `/home/fahd_/.pub-cache/bin/melos`.
- **Passed WSL checks:** `dart format` on Phase 0 scaffold files; `melos bootstrap` with 36 packages;
  `dart run packages/tooling/manifest_gate.dart --manifest ../docs/Build\ Plan\ V2/test-manifest.json`;
  `dart run packages/tooling/phase_gate.dart --phase 0 --check-env`; `dart run
  packages/tooling/skill_prereq_check.dart --mode local-demo`; `dart run
  packages/tooling/skill_prereq_setup.dart --target codex --mode local-demo`; `melos run
  manifest:gate`; `melos run phase:gate`; `melos run skill:prereq:check`; `melos run
  skill:prereq:setup`; `melos run lint:boundaries`; focused `flutter analyze` / `dart analyze` on the
  Phase 0 scaffold packages and tooling scripts.
- **Notes:** Full historical workspace `melos run analyze` exceeded the command timeout; focused analysis
  of the Phase 0 scaffold passed. No Set A phase has started.

### Phase A1 - Foundation Components

- **Achieves:** Builds the lowest layer used by every other component.
- **Deliverables:** Passport, role/policy/consent, core vault, protected vault, connections graph,
  receipt ledger, audit ledger, event bus, key management, builder App ID, local store baseline.
- **Completed when:** Each foundation component has contract, fake, owned data, validation tests,
  consumer-contract tests for dependents, Skill component guide, API Review entry, and current manifest
  version stamp.
- **Evidence to record:** A1 validation and contract test output, component hashes, API Review path,
  Skill component guide paths, commit SHA.

#### Execution Record - 2026-06-09

- **Contracts:** Added `CommunityPassportApi`, `CommunityRolePolicyApi`, `CommunityCoreVaultApi`,
  `CommunityProtectedVaultApi`, `CommunityConnectionsApi`, `CommunityReceiptLedgerApi`,
  `CommunityAuditApi`, `CommunityEventBusApi`, `CommunityKeyManagementApi`, and
  `CommunityBuilderAppIdApi`.
- **Fakes and harness:** Added `CommunityFoundationFakeBackend`, A1 owned-table schema metadata, A1 seed
  fixture, and `test/a1_foundation_components_test.dart`.
- **Skill/API docs:** Added ten Skill component guides and completed `Phase A1 - API Review.md`.
- **Manifest:** A1 validation tests are stamped `pass`; higher-layer consumer-contract tests remain
  `pending-counterpart`.
- **Passed WSL checks:** `dart test test/a1_foundation_components_test.dart`; `melos exec
  --scope=loom_fake_backend --dir-exists=test -- dart test`; `dart analyze` on touched A1 packages;
  `dart run packages/tooling/manifest_gate.dart --manifest ../docs/Build\ Plan\ V2/test-manifest.json`;
  `dart run packages/tooling/phase_gate.dart --phase A1 --check-env`; `melos run lint:boundaries`.

### Phase A2 - Registry and Control-Plane Components

- **Achieves:** Establishes community, branding, membership, extension, certification, and discovery
  control planes.
- **Deliverables:** Community registry, community branding fields, spaces, membership, invitations,
  extension registry, certification system with asset evidence checks, public registry read model,
  workflow inventory registry.
- **Completed when:** Registry components pass their own validation tests and all available contract tests
  to/from A1 providers; pending higher-layer consumer tests are registered.
- **Evidence to record:** A2 gate output, manifest staleness output, component hashes, API Review path,
  Skill guide paths, commit SHA.

#### Execution Record - 2026-06-09

- **Contracts:** Added `CommunityWorkflowInventoryApi`, `CommunityTestManifestApi`,
  `CommunityRegistryApi`, `CommunitySpacesApi`, `CommunityMembershipApi`, `CommunityInvitationApi`,
  `CommunityCertificationApi`, `CommunityExtensionRegistryApi`, and `CommunityPublicRegistryApi`.
- **Fakes and harness:** Added `CommunityRegistryControlPlaneFakeBackend`, A2 owned-table schema
  metadata, A2 seed fixture, and `test/a2_registry_control_plane_test.dart`.
- **Skill/API docs:** Added nine Skill component guides and completed `Phase A2 - API Review.md`.
- **Manifest:** A2 validation tests and built-counterpart contract tests are stamped `pass`; App Shell
  consumer-contract tests remain `pending-counterpart`; A1 connections and builder App ID contract
  tests are now unblocked and stamped `pass`.
- **Passed WSL checks:** `dart test test/a1_foundation_components_test.dart
  test/a2_registry_control_plane_test.dart`; `dart analyze` on touched A1/A2 packages; `dart run
  packages/tooling/manifest_gate.dart --manifest ../docs/Build\ Plan\ V2/test-manifest.json`; `dart run
  packages/tooling/phase_gate.dart --phase A2 --check-env`; `melos run lint:boundaries`.

### Phase A3 - Service Components I

- **Achieves:** Adds core community interaction services.
- **Deliverables:** Publishing, messaging/stream, notifications, events, forms/polls/voting.
- **Completed when:** Experience services pass validation, consume A1/A2 providers only through
  contracts/fakes, publish dependent test kits, and update Skill/API docs.
- **Evidence to record:** A3 component test output, dependency-fake evidence, manifest updates, API Review
  path, Skill guide paths, commit SHA.

#### Execution Record - 2026-06-09

- **Contracts:** Added `CommunityPublishingApi`, `CommunityMessagingApi`, `CommunityNotificationApi`,
  `CommunityEventsApi`, and `CommunityFormsVotingApi`.
- **Fakes and harness:** Added `CommunityExperienceServicesFakeBackend`, A3 owned-table schema metadata,
  A3 seed fixture, and `test/a3_experience_services_test.dart`.
- **Skill/API docs:** Added five Skill component guides and completed `Phase A3 - API Review.md`.
- **Manifest:** A3 validation tests are stamped `pass`; `ct_forms-voting__protected-vault_sensitive-fields`
  is stamped `pass`; A4b/A5/A6 consumer-contract tests remain `pending-counterpart`.
- **Passed WSL checks:** `dart test test/a1_foundation_components_test.dart
  test/a2_registry_control_plane_test.dart test/a3_experience_services_test.dart`; `dart analyze` on
  touched A1-A3 packages; `dart run packages/tooling/manifest_gate.dart --manifest
  ../docs/Build\ Plan\ V2/test-manifest.json`; `dart run packages/tooling/phase_gate.dart --phase A3
  --check-env`; `melos run lint:boundaries`.

### Phase A4a - Service Components II

- **Achieves:** Adds operational and community-management services.
- **Deliverables:** Case/task, documents, facilities, import, export, provider transfer, abuse report,
  moderation case, incident, dispute scaffolding.
- **Completed when:** Ops/community services pass validation and unblocked contract tests; export/import
  use contracts instead of reading sibling storage directly.
- **Evidence to record:** A4a gate output, component hashes, import/export contract evidence, API Review
  path, Skill guide paths, commit SHA.

#### Execution Record - 2026-06-09

- **Contracts:** Added `CommunityCaseTaskApi`, `CommunityDocumentsApi`, `CommunityFacilitiesApi`,
  `CommunityImportApi`, `CommunityExportApi`, `CommunityProviderTransferApi`,
  `CommunityAbuseReportApi`, `CommunityModerationApi`, `CommunityIncidentApi`, and
  `CommunityDisputeApi`.
- **Fakes and harness:** Added `CommunityOpsServicesFakeBackend`, A4a owned-table schema metadata, A4a
  seed fixture, and `test/a4a_ops_services_test.dart`.
- **Skill/API docs:** Added ten Skill component guides and completed `Phase A4a - API Review.md`.
- **Manifest:** A4a validation tests and built-counterpart contract tests are stamped `pass`;
  A4b/A5 consumer-contract tests remain `pending-counterpart`.
- **Component versions:** abuse-report-service `5c220d916543`; case-task-service `e8924d019980`;
  dispute-service `5f035552f46b`; documents-service `bc037ffdc17c`; export-service
  `d4d34a47066a`; facilities-service `0c23efd3c350`; import-service `0a178c20caba`;
  incident-service `d6d2177db39e`; moderation-case-service `860c5e41ffe4`;
  provider-transfer-service `91de09a48370`.
- **Passed WSL checks:** `dart test test/a1_foundation_components_test.dart
  test/a2_registry_control_plane_test.dart test/a3_experience_services_test.dart
  test/a4a_ops_services_test.dart`; `dart analyze` on touched A1-A4a packages; manifest and phase
  gates; boundary lint.

### Phase A4b - Service Components III

- **Achieves:** Adds economic, search, AI, ad, and settlement services.
- **Deliverables:** Wallet/dues/donations, ad decision, ad campaign, search, AI gateway, digest,
  settlement, utility funding, fraud signals.
- **Completed when:** Economic/search/ad services pass validation and unblocked contract tests; ad-off,
  protected no-fill, receipts, settlement, and search permission checks are testable.
- **Evidence to record:** A4b gate output, component hashes, ad/search/payment test output, API Review
  path, Skill guide paths, commit SHA.

#### Execution Record - 2026-06-09

- **Contracts:** Added `CommunityWalletApi`, `CommunityAdCampaignApi`, `CommunityAdDecisionApi`,
  `CommunityIndexingApi`, `CommunitySearchApi`, `CommunityAiGatewayApi`, `CommunityDigestApi`,
  `CommunitySettlementApi`, `CommunityUtilityFundingApi`, and `CommunityFraudApi`.
- **Fakes and harness:** Added `CommunityEconomicServicesFakeBackend`, A4b owned-table schema metadata,
  A4b seed fixture, and `test/a4b_economic_services_test.dart`.
- **Skill/API docs:** Added ten Skill component guides and completed `Phase A4b - API Review.md`.
- **Manifest:** A4b validation and built-counterpart contract tests are stamped `pass`; A1/A3/A4a
  provider contracts unblocked by A4b are stamped `pass`; App Shell, stream renderer, and payment
  surface consumer tests remain `pending-counterpart`.
- **Component versions:** ad-campaign-service `7d781eea95a9`; ad-decision-service `e5a7593ee1ea`;
  ai-gateway `66fa617e8d1b`; digest-service `d6d8d601ba0a`; fraud-signal-service
  `e82f961e8a1d`; indexing-service `085147318d54`; search-service `00f0b4124434`;
  settlement-engine `12129ce8f929`; utility-funding-service `9e0362c7cc0f`;
  wallet-dues-donations `071871e00937`.
- **Passed WSL checks:** `dart test test/a1_foundation_components_test.dart
  test/a2_registry_control_plane_test.dart test/a3_experience_services_test.dart
  test/a4a_ops_services_test.dart test/a4b_economic_services_test.dart`; `dart analyze` on touched
  A1-A4b packages; manifest and phase gates; boundary lint.

### Phase A5 - Extension Engine Components

- **Achieves:** Builds the extension execution and packaging layer.
- **Deliverables:** Extension runtime bridge, rule engine, workflow engine, job scheduler, function
  runtime, data schema store, secrets/connector broker, extension package validator, initialization
  package schema, asset manifest validator, initialization branding schema.
- **Completed when:** Engine components pass validation and contract tests; extension package and
  initialization package contracts validate; asset manifest/policy checks pass; Skill guides explain
  local package generation, bundled assets, card defaults, and fake backend seeding.
- **Evidence to record:** A5 gate output, package validator output, asset validator output,
  initialization schema/branding validation, component hashes, API Review path, Skill guide paths,
  commit SHA.

#### Execution Record - 2026-06-09

- **Contracts:** Added `CommunityExtensionRuntimeApi`, `CommunityRuleEngineApi`,
  `CommunityWorkflowApi`, `CommunityJobSchedulerApi`, `CommunityFunctionRuntimeApi`,
  `CommunityDataSchemaApi`, `CommunitySecretsConnectorApi`, `CommunityExtensionPackageApi`, and
  `CommunityInitializationPackageApi`.
- **Fakes and harness:** Added `CommunityEngineServicesFakeBackend`, A5 owned-table schema metadata,
  A5 seed fixture, and `test/a5_engine_services_test.dart`.
- **Skill/API docs:** Added nine Skill component guides and completed `Phase A5 - API Review.md`.
- **Manifest:** A5 validation and built-counterpart contract tests are stamped `pass`; A1/A3/A4a
  provider contracts unblocked by A5 are stamped `pass`; App Shell, Demo loader, and local in-app
  backend consumer tests remain `pending-counterpart`.
- **Component versions:** extension-runtime-bridge `1aff2ed72457`; rule-engine `b5071a6c9402`;
  workflow-engine `15f4ac99a8db`; job-scheduler `1f5f4cd3da14`; function-runtime
  `875d131947fb`; data-schema-store `6a09d351f11f`; secrets-connector-broker
  `b008328af7af`; extension-package-validator `512380dc6848`; initialization-package-schema
  `1dd4a2b2ca52`.
- **Passed WSL checks:** `dart test test/a1_foundation_components_test.dart
  test/a2_registry_control_plane_test.dart test/a3_experience_services_test.dart
  test/a4a_ops_services_test.dart test/a4b_economic_services_test.dart test/a5_engine_services_test.dart`;
  `dart analyze` on touched A1-A5 packages; manifest and phase gates; boundary lint.

### Phase A6 - UX Components

- **Achieves:** Builds the UX micro-components and the local demo runtime.
- **Deliverables:** App Shell, community card, navigation panel, stream renderer, connections shell, ad
  slots, payment surface, data dashboard, Loom Communities Demo App, Local In-App Backend Adapter.
- **Completed when:** App starts empty, `Add Community` is reachable, local package files can be loaded,
  initialization data and branding import into fake backend/local DB, community cards render with image
  fallback priority, and App Shell invariants pass.
- **Evidence to record:** A6 visual/interaction output, Demo App local backend tests, local persistence
  tests, branded-card screenshot/output, API Review and UX Decisions paths, Skill guide paths, commit
  SHA.

#### Execution Record - 2026-06-09

- **Contracts:** Added App Shell and UX micro-component contracts in `loom_app_shell`, local backend
  contracts in `loom_demo_local_backend`, and an enabled Add Community local load flow in
  `loom_communities_demo`.
- **Tests:** Added `test/a6_app_shell_components_test.dart`, `test/a6_local_backend_test.dart`, and
  `test/a6_loom_communities_demo_test.dart`.
- **Skill/API/UX docs:** Added ten Skill component guides and completed `Phase A6 - API Review.md` and
  `Phase A6 - UX Decisions.md`.
- **Manifest:** A6 validation and contract tests are stamped `pass`; all Set A pending counterpart tests
  are resolved.
- **Component versions:** ad-slots `12d754c97f76`; app-shell-runtime `c7c0a602fdad`;
  community-card `690cea54a8d2`; connections-shell `212f751b3eb5`; data-dashboard-consent
  `917fd80d8266`; local-in-app-backend `4067f3df7a7f`; loom-communities-demo-app
  `1979adae7eba`; navigation-panel `ffc2aecac272`; payment-surface `637ca25646d9`;
  stream-renderer `07547f0370c6`.
- **Passed WSL checks:** `flutter test packages/core/loom_app_shell/test/a6_app_shell_components_test.dart`;
  `dart test test/a6_local_backend_test.dart`; `flutter test
  apps/loom_communities_demo/test/a6_loom_communities_demo_test.dart`; A1-A5 component regression tests;
  focused `flutter analyze`; manifest and phase gates; boundary lint.

### Phase B1a - Local Build, Download, Sideload, Install

- **Achieves:** Proves the preliminary product flow without a hosted backend.
- **Deliverables:** Skill prereq setup, validation environment lock, Skill `local-demo` workflow,
  downloadable extension package, downloadable initialization package, bundled brand assets, Skill
  debug golden fixture, Demo App local file load, fake backend import, branded community card render,
  local App Shell open.
- **Completed when:** `wf_local-demo-prereq-to-validation-ready` and
  `wf_local-build-download-sideload-install` pass against the Demo App with Local Backend; the selected
  execution target is Codex or Claude Code; the app starts with zero communities, loads the first
  community from local files, imports fake backend data and branding assets, persists them, renders the
  branded card, and opens the extension.
- **Evidence to record:** Environment lock hash, prereq setup output, workflow output, Skill
  prompt/transcript/golden package hashes, package validator output, asset validator output, fake
  backend import report, branded-card screenshot/output, API Review and UX Decisions paths, commit SHA.

### Phase B1b - Publish, Discover, Certify, Install

- **Achieves:** Proves the real-backend publish mode through local stubs/contracts.
- **Deliverables:** Skill `real-backend-publish` workflow, hosted publish payloads, certification and
  registry stubs/fakes, QR/handle discovery contract, latest certified install/open behavior.
- **Completed when:** `wf_build-publish-discover-install` passes against the Demo App with Local Backend
  using local backend stubs/contracts for hosted behavior; B1a local package behavior remains green.
- **Evidence to record:** Workflow output, hosted API stub/contract output, package/certification test
  output, API Review and UX Decisions paths, Skill workflow guide path, commit SHA.

### Phase B2 - Book Club Headline Flow

- **Achieves:** Validates the first complete vertical extension.
- **Deliverables:** Book club package fragments, nomination schema, voting workflow, meeting event,
  discussion thread, permitted search/digest behavior, Skill workflow guide and example updates.
- **Completed when:** `wf_book-club-headline` passes in the Demo App with Local Backend and all altered
  component validation/regression tests pass.
- **Evidence to record:** Workflow output, package fixture hashes, component regression output, API Review
  and UX Decisions paths, Skill example paths, commit SHA.

### Phase B3 - Youth Soccer Headline Flow

- **Achieves:** Validates guardian/minor, schedule, payment, roster, and notification behavior.
- **Deliverables:** Youth soccer package, protected minor-data flow, registration payment, roster views,
  schedule/events, notifications, Skill workflow guide and example updates.
- **Completed when:** `wf_youth-soccer-headline` passes in the Demo App with Local Backend and protected
  data, permission, and payment regressions pass.
- **Evidence to record:** Workflow output, protected-data assertions, payment test output, API Review and
  UX Decisions paths, Skill example paths, commit SHA.

### Phase B4 - HOA Headline Flow

- **Achieves:** Validates dues, documents, facilities, case workflow, and export behavior.
- **Deliverables:** HOA package, dues payment, document visibility, facility reservation, architectural
  request workflow, export metadata, Skill workflow guide and example updates.
- **Completed when:** `wf_hoa-headline` passes in the Demo App with Local Backend and documents,
  facilities, wallet, case/task, workflow, and export regressions pass.
- **Evidence to record:** Workflow output, export coverage output, component regression output, API Review
  and UX Decisions paths, Skill example paths, commit SHA.

### Phase B5 - Mosque Headline Flow

- **Achieves:** Validates donation, event, volunteer, announcement, and protected care-request behavior.
- **Deliverables:** Mosque package, announcements, event RSVP, volunteer signup, donor visibility,
  protected care request, notifications, Skill workflow guide and example updates.
- **Completed when:** `wf_mosque-headline` passes in the Demo App with Local Backend and sensitive data,
  donation, event, form, notification, search/AI, and App Shell regressions pass.
- **Evidence to record:** Workflow output, protected-vault assertions, donation receipt output, API Review
  and UX Decisions paths, Skill example paths, commit SHA.

### Phase B6 - Messaging, In-Stream Ads, and Connections

- **Achieves:** Validates required platform social and ad surfaces.
- **Deliverables:** Messages and Connections navigation, invite/block behavior, stream rendering,
  in-stream ad item behavior, top banner behavior, no-fill behavior, Skill workflow guide update.
- **Completed when:** `wf_messaging-ads-connections` passes in the Demo App with Local Backend; shell
  invariants prove extensions cannot hide Messages, Connections, or required ad surfaces.
- **Evidence to record:** Workflow output, shell invariant lint output, ad decision/no-fill output, API
  Review and UX Decisions paths, Skill workflow guide path, commit SHA.

### Phase B7 - Ad-Off

- **Achieves:** Validates ad-off purchase and economic side effects.
- **Deliverables:** Member/community ad-off purchase, entitlement checks, ad decision changes, receipts,
  settlement, utility funding allocation, Skill workflow guide update.
- **Completed when:** `wf_ad-off` passes in the Demo App with Local Backend and wallet, ad decision,
  receipt, settlement, utility funding, payment surface, and ad slot regressions pass.
- **Evidence to record:** Workflow output, payment/receipt output, settlement output, API Review and UX
  Decisions paths, Skill workflow guide path, commit SHA.

### Phase B8 - Export and Migration

- **Achieves:** Validates portability and closes the build-plan readiness gate.
- **Deliverables:** Community export, member export/delete behavior, extension custom-data export,
  protected redaction, provider transfer verify/rollback, full workflow regression, final API spec
  inventory, final Skill/example updates.
- **Completed when:** `wf_export-migration`, `vt_api_specs_complete`, the full Set B workflow suite, and
  all altered component regressions pass; every required API/local contract exists and validates.
- **Evidence to record:** Workflow output, full regression output, API inventory output, export package
  checksums, API Review and UX Decisions paths, Skill/example paths, commit SHA.

## Gate Evidence Template

For each completed phase, paste or link:

- `melos bootstrap`
- `melos run analyze`
- `melos run lint:boundaries`
- `melos run test`
- `melos run test:integration` or focused phase command
- `melos run validate:extension`, when package behavior changed
- `melos run test:demo-local`, when Demo App/local backend behavior changed
- `melos run test:workflows:demo-local`, for every Set B workflow phase
- `manifest_gate`
- `phase_gate --phase <phase>`
- API Review path
- UX Decisions path, if applicable
- Skill files updated
- Component version hashes
- Test hash updates
- Commit SHA

Run each command above through WSL Ubuntu from `app/`, for example:

```powershell
wsl.exe -d Ubuntu -- bash -lc 'cd "/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app" && melos bootstrap'
```

## Component Version Template

Use the component hash generated by `manifest_gate`.

| Component | Phase built | Current version hash | Last phase verified |
| --- | --- | --- | --- |
| passport-ledger | A1 | f6e17f408e74 | A1 |
| role-policy-consent-engine | A1 | 01288a26926f | A1 |
| core-member-vault | A1 | 67421d04854e | A1 |
| protected-visibility-vault | A1 | 3795b6a09b20 | A1 |
| connections-graph | A1 | 297b5d201b5f | A1 |
| receipt-ledger | A1 | 9f9e82fd4a2f | A1 |
| audit-ledger | A1 | 0b57bac5ec69 | A1 |
| event-bus | A1 | 1f233230d7c9 | A1 |
| key-management | A1 | 16c1bdc8be88 | A1 |
| builder-app-id-service | A1 | 46dfcdb9934e | A1 |
| loom-local-store | A1 | 2d8dbc534574 | A1 |
| community-registry | A2 | 10643e91b879 | A2 |
| extension-registry | A2 | 845149fec120 | A2 |
| certification-system | A2 | 7d026e0c94bc | A2 |
| invitation-service | A2 | d762581a0d01 | A2 |
| membership-service | A2 | 743b4c1a71e2 | A2 |
| public-registry-read-model | A2 | 092951c163e1 | A2 |
| spaces-service | A2 | 669c7e405b9a | A2 |
| workflow-inventory-registry | A2 | 7ab9c7b379ee | A2 |
| phase-test-manifest-bridge | 0/A2 | 89e620c5af33 | A2 |
| publishing-service | A3 | 0e31d279bf88 | A3 |
| messaging-stream-service | A3 | 709572cac272 | A3 |
| notification-service | A3 | b7c57774de42 | A3 |
| events-service | A3 | dee493ff7d53 | A3 |
| forms-voting-service | A3 | 72bf23f58102 | A3 |
| export-service | A4a | TBD | TBD |
| wallet-dues-donations | A4b | TBD | TBD |
| ad-decision-service | A4b | TBD | TBD |
| search-service | A4b | TBD | TBD |
| extension-runtime-bridge | A5 | TBD | TBD |
| extension-package-validator | A5 | TBD | TBD |
| initialization-package-schema | A5 | TBD | TBD |
| app-shell-runtime | A6 | TBD | TBD |
| loom-communities-demo-app | A6 | TBD | TBD |
| local-in-app-backend | A6 | TBD | TBD |

## Artifact Completion Checklist

Use this checklist when closing a phase:

- Phase status changed from `Not started` to `Complete`.
- Gate evidence pasted or linked.
- Component hashes recorded.
- Test hashes and manifest stamps updated.
- API Review updated and linked.
- UX Decisions updated and linked where applicable.
- Skill component/workflow guides updated.
- Example packages or fixtures updated where applicable.
- Commit SHA recorded.
