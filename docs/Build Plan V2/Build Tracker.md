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
3. If the phase has UI, interaction, workflow UX, or user-facing copy, complete the R20 UX Decisions
   gate before implementation: reference sources reviewed, UX patterns extracted, key UX decisions,
   key implementation decisions, workflow walkthrough, and open questions / tradeoffs.
4. Execute the phase deliverables.
5. Run all required validation, contract, workflow, manifest, and staleness gates.
6. Stage only the phase's intended changes and review `git diff --staged`.
7. Commit the phase changes to git.
8. Record component version hashes, API/UX/Skill artifacts, gate evidence, and the resulting commit SHA.
9. Start the next phase only after the commit exists and this tracker points to that SHA.

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
| 0 | Complete | None | [Initialize Build](./Phases/Phase%200%20-%20Initialize%20Build.md) | Rules, manifest, tracker, Skill skeleton, Skill setup manifest, workspace scaffold, and gates exist. | R20 UX methodology, phase instructions, tracker reset, manifest gate, Phase 0 gate, Skill prereq check, boundary lint, and diff check passed in WSL Ubuntu. | `17b4b81` prior scaffold commit; R20 closeout `b838fa8` |
| A1 | Complete | 0 | [Foundation Components](./Phases/Phase%20A1%20-%20Foundation%20Components.md) | Foundation contracts, fakes, stores, validation tests, and provider test kits pass. | A1 contracts/fakes/schema/seed/test suite added; validation tests pass; consumer-contract kits are pending only for unbuilt counterparts; manifest and phase gates pass in WSL Ubuntu. | `e3c0357` |
| A2 | Complete | A1 | [Registry and Control-Plane Components](./Phases/Phase%20A2%20-%20Registry%20and%20Control-Plane%20Components.md) | Registry/control-plane components pass tests to and from built providers. | A2 contracts/fakes/schema/seed/test suite added; A1 unblocked contract tests pass; App Shell counterpart tests remain pending; manifest and phase gates pass in WSL Ubuntu. | `3d6a388` |
| A3 | Complete | A2 | [Service Components I](./Phases/Phase%20A3%20-%20Service%20Components%20I%20%28Experience%20Core%29.md) | Experience service components pass validation and unblocked contract tests. | A3 contracts/fakes/schema/seed/test suite added; forms/protected-vault contract passes; A4b/A5/A6 consumer tests remain pending; manifest and phase gates pass in WSL Ubuntu. | `a4cc268` |
| A4a | Complete | A3 | [Service Components II](./Phases/Phase%20A4a%20-%20Service%20Components%20II%20%28Ops%20and%20Community%29.md) | Ops/community services pass validation and unblocked contract tests. | A4a contracts/fakes/schema/seed/test suite added; document/export, import/protected-vault, incident/certification contracts pass; A4b/A5 consumer tests remain pending; manifest and phase gates pass in WSL Ubuntu. | `c56f45b` |
| A4b | Complete | A4a | [Service Components III](./Phases/Phase%20A4b%20-%20Service%20Components%20III%20%28Economic%20Search%20and%20Ads%29.md) | Economic/search/ad services pass validation and unblocked contract tests. | A4b contracts/fakes/schema/seed/test suite added; wallet/ad decision, search/AI/digest, settlement/utility, receipt/settlement, fraud/dispute, and earlier unblocked provider contracts pass; A6 consumer tests remain pending; manifest and phase gates pass in WSL Ubuntu. | `4ab715d` |
| A5 | Complete | A4b | [Extension Engine Components](./Phases/Phase%20A5%20-%20Extension%20Engine%20Components.md) | Runtime, rules, workflows, package validator, and initialization package contracts pass. | A5 contracts/fakes/schema/seed/test suite added; runtime/rules/workflows/jobs/functions/schema/secrets/package/init validations pass; engine-unblocked provider contracts pass; A6/B1a consumer tests remain pending; manifest and phase gates pass in WSL Ubuntu. | `b4c8b25` |
| A6 | Complete | A5 + Phase 0 R20 closeout | [UX Components](./Phases/Phase%20A6%20-%20UX%20Components.md) | App Shell, UX micro-components, Demo App, and Local Backend Adapter pass. | R20 UX Decisions completed; empty-state CTA gap fixed; A6 tests, existing B1a-B3 workflow regressions, manifest gate, A6 phase gate, analyze, boundary lint, and diff check pass in WSL Ubuntu. | `0346c99` prior code commit; R20 closeout `39af637` |
| B1a | Complete | A6 R20 closeout | [Local Build Download Sideload Install](./Phases/Phase%20B1a%20-%20Local%20Build%20Download%20Sideload%20Install.md) | Skill prereq setup, local package/init package, fake backend import, card render, and local open pass. | R20 UX Decisions completed; local package loader, package-pair validation, invalid-file error, duplicate import status, B1a workflow, B1b-B3 regressions, manifest gate, B1a phase gate, analyze, boundary lint, and diff check pass in WSL Ubuntu. | `df6f543` prior code commit; R20 closeout `471677a` |
| B1b | Complete | B1a R20 closeout | [Publish Discover Certify Install](./Phases/Phase%20B1b%20-%20Publish%20Discover%20Certify%20Install.md) | Real-backend publish mode is validated through local stubs/contracts. | R20 UX Decisions completed; B1b workflow, B1a/A6 regressions, manifest gate, B1b phase gate, boundary lint, and diff check pass in WSL Ubuntu. | `7825b59` prior code commit; R20 closeout `105cb16` |
| B2 | Complete | B1b R20 closeout | [Book Club Headline Flow](./Phases/Phase%20B2%20-%20Book%20Club%20Headline%20Flow.md) | Book club workflow passes in the Demo App with Local Backend. | R20 UX Decisions completed; B2 workflow, B1b/B1a/A6 regressions, manifest gate, B2 phase gate, boundary lint, and diff check pass in WSL Ubuntu. | `e362090` prior code commit; R20 closeout `e97ba72` |
| B3 | Complete | B2 R20 closeout | [Youth Soccer Headline Flow](./Phases/Phase%20B3%20-%20Youth%20Soccer%20Headline%20Flow.md) | Youth soccer workflow passes in the Demo App with Local Backend. | R20 UX Decisions completed; B3 workflow, B2/B1b/B1a/A6 regressions, manifest gate, B3 phase gate, boundary lint, and diff check pass in WSL Ubuntu. | `36aee10` prior code commit; R20 closeout `23dd422` |
| B4 | Complete | B3 R20 closeout | [HOA Headline Flow](./Phases/Phase%20B4%20-%20HOA%20Headline%20Flow.md) | HOA workflow passes in the Demo App with Local Backend. | R20 UX Decisions completed; HOA workflow, affected fake backend regressions, manifest gate, B4 phase gate, analyze, boundary lint, and diff check pass in WSL Ubuntu. | `f3ffad3` |
| B5 | Complete | B4 | [Mosque Headline Flow](./Phases/Phase%20B5%20-%20Mosque%20Headline%20Flow.md) | Mosque workflow passes in the Demo App with Local Backend. | R20 UX Decisions completed; mosque workflow, affected component regressions, manifest gate, B5 phase gate, analyze, boundary lint, and diff check pass in WSL Ubuntu. | `163dad1` |
| B6 | Complete | B5 | [Messaging In-Stream Ads and Connections](./Phases/Phase%20B6%20-%20Messaging%20In-Stream%20Ads%20and%20Connections.md) | Messaging, connections, ad surfaces, and shell invariants pass. | R20 UX Decisions completed; messaging/ads/connections workflow, affected component regressions, manifest gate, B6 phase gate, analyze, boundary lint, and diff check pass in WSL Ubuntu. | `b8c348d` |
| B7 | Complete | B6 | [Ad-Off](./Phases/Phase%20B7%20-%20Ad-Off.md) | Ad-off purchase, ad suppression, receipts, settlement, and utility funding pass. | R20 UX Decisions completed; ad-off workflow, wallet community-ad-off validation, ad-decision validation, affected regressions, manifest gate, B7 phase gate, analyze, boundary lint, and diff check pass in WSL Ubuntu. | `b06d3c7` |
| B8 | Complete | B7 | [Export and Migration](./Phases/Phase%20B8%20-%20Export%20and%20Migration.md) | Export/migration, redaction, full workflow suite, and API spec inventory pass. | R20 UX Decisions completed; export/migration workflow, provider rollback validation, API inventory validation, full Set B regression, manifest gate, B8 phase gate, analyze, boundary lint, and diff check pass in WSL Ubuntu. | `762f556` |
| B9 | Complete | B8 | [Arbitrary Local Package Ingestion](./Phases/Phase%20B9%20-%20Arbitrary%20Local%20Package%20Ingestion.md) | Arbitrary local package pairs install from selected file contents without Book Club fixture substitution. | B9 backend/widget/workflow tests, B1a-B8 regressions, manifest gate, B9 phase gate, analyze, boundary lint, and diff check pass in WSL Ubuntu. | Implementation `db3c476`; tracker stamp TBD |

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
| B8 | Closes portability and API inventory readiness. | Export/migration, redaction, transfer verification/rollback, full workflow regression, API spec inventory, Skill/example updates. | Every B1a-B8 workflow remains green and every required API/local contract in that scope is present and validated before arbitrary-ingestion hardening. |
| B9 | Closes arbitrary local package ingestion. | File-backed package parsing, arbitrary init import, parsed branding/card rendering, local latest open, API/UX/Skill docs, manifest rows. | The Demo App can install an arbitrary Skill/developer-generated local package pair and display the parsed community instead of a built-in fixture. |

## UX Methodology Reset - 2026-06-09

R20 was added after A6, B1a, B1b, B2, and B3 had already been marked complete. Those phases are now
reopened for UX methodology only. Their prior implementation commits remain useful technical evidence,
but the phases are not considered fully closed until their UX Decisions files are recreated with the
new method and the affected regressions pass again.

| Phase | Prior closeout commit | Current status | Required UX recreation |
| --- | --- | --- | --- |
| 0 | `17b4b81`; R20 closeout `b838fa8` | Complete | R20 rules, UX Decisions templates, phase instructions, and tracker reset are now the Phase 0 second-pass baseline. |
| A6 | `0346c99`; R20 closeout `39af637` | Complete | Recreated App Shell, UX micro-component, Demo App empty/load/import, branded card, local backend, ad slot, payment surface, data dashboard, and required shell-surface UX decisions using R20. |
| B1a | `df6f543`; R20 closeout `471677a` | Complete | Recreated local-demo build/download/sideload/install UX decisions using R20, including local file picker/path entry, validation errors, import progress/status, duplicate import, rollback tradeoff, card branding fallback, and local latest-open states. |
| B1b | `7825b59`; R20 closeout `105cb16` | Complete | Recreated real-backend-publish, certification, permission review, QR/handle discovery, install preview, and latest-certified open UX decisions using R20. |
| B2 | `e362090`; R20 closeout `e97ba72` | Complete | Recreated book club nomination, voting, event, RSVP, discussion, digest, citations, and local card/open UX decisions using R20. |
| B3 | `36aee10`; R20 closeout `23dd422` | Complete | Recreated youth soccer guardian join, protected minor data, roster, registration payment, schedule, notification, and local card/open UX decisions using R20. |
| B4 | None | Complete | Completed HOA dues, documents, facilities, architectural review, export, and local card/open UX decisions using R20. |
| B5 | None | Complete | Completed mosque announcement, event, volunteer, donation, donor visibility, protected care request, notification, and local card/open UX decisions using R20. |
| B6 | None | Complete | Completed Messages, Connections, stream rendering, in-stream ad disclosure, top banner, no-fill, and block/invite UX decisions using R20. |
| B7 | None | Complete | Completed ad-off checkout, entitlement, status, receipt, ad preference, ad suppression, sensitive no-fill, settlement, and utility allocation UX decisions using R20. |
| B8 | None | Complete | Completed export scope, redaction, checksums, transfer verify/rollback, retained-record disclosure, API inventory, and readiness-summary UX decisions using R20. |

Closeout rule for reopened phases:

1. Complete the phase's UX Decisions file with current reference sources, extracted patterns, key UX
   decisions, key implementation decisions, workflow walkthrough, and open tradeoffs.
2. Apply any UX-driven implementation/test changes.
3. Rerun the phase workflow and all affected regressions.
4. Update manifest/test stamps if tests or UX-owned component behavior changed.
5. Commit the phase closeout and replace the `new closeout TBD` entry in the status table.

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

#### Second-Pass Execution Record - 2026-06-09

- **R20 baseline:** Added R20 as the required UX research and decision gate; updated Phase 0, the Build
  Plan README, and every UX-bearing phase file so UX Decisions are completed before implementation.
- **UX Decisions standard:** Updated the UX Decisions siblings for A6 and B1a-B8 to require reference
  sources reviewed, UX patterns extracted, key UX decisions, key implementation decisions, workflow
  walkthrough, and open questions / tradeoffs.
- **Tracker reset:** Reopened A6, B1a, B1b, B2, and B3 for UX-methodology closeout; marked B4-B8 as
  R20-required-before-implementation; kept the prior technical closeout commits as historical evidence.
- **Passed WSL checks:** `dart run packages/tooling/manifest_gate.dart --manifest ../docs/Build\ Plan\ V2/test-manifest.json`;
  `dart run packages/tooling/phase_gate.dart --phase 0 --check-env`; `dart run
  packages/tooling/skill_prereq_check.dart --mode local-demo`; `melos run lint:boundaries`; `git diff --check`.
- **Commit:** R20 baseline closeout `b838fa8`.

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
  `9079b5ad7e37`; facilities-service `0c23efd3c350`; import-service `0a178c20caba`;
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
  `917fd80d8266`; local-in-app-backend `332432d7b39d`; loom-communities-demo-app
  `fe03608c5230`; navigation-panel `ffc2aecac272`; payment-surface `637ca25646d9`;
  stream-renderer `07547f0370c6`.
- **Passed WSL checks:** `flutter test packages/core/loom_app_shell/test/a6_app_shell_components_test.dart`;
  `dart test test/a6_local_backend_test.dart`; `flutter test
  apps/loom_communities_demo/test/a6_loom_communities_demo_test.dart`; A1-A5 component regression tests;
  focused `flutter analyze`; manifest and phase gates; boundary lint.
- **R20 reopen note:** This technical closeout predates the R20 UX research/decision gate. Recreate
  `Phase A6 - UX Decisions.md` with the new method, apply any UX-driven changes, rerun affected
  regressions, and record a new closeout commit before A6 can be treated as complete again.

#### Second-Pass Execution Record - 2026-06-09

- **R20 UX decisions:** Completed `Phase A6 - UX Decisions.md` with current reference sources, extracted
  patterns, key UX decisions, implementation decisions, workflow walkthrough, and tradeoffs.
- **UX-driven fix:** The empty-state Add Community CTA now uses the same local-load handler as the
  shell floating Add Community action, so the first-run state provides a direct path to install.
- **Tests:** Added `vt_demo-app_empty-state-cta-loads-community` and registered it in the machine and
  human test manifests.
- **Component version update:** `loom-communities-demo-app` is now stamped `fe03608c5230`.
- **Passed WSL checks:** `dart format apps/loom_communities_demo/lib/main.dart
  apps/loom_communities_demo/test/a6_loom_communities_demo_test.dart`; `flutter test
  packages/core/loom_app_shell/test/a6_app_shell_components_test.dart`; `dart test
  packages/core/loom_demo_local_backend/test/a6_local_backend_test.dart`; `flutter test
  apps/loom_communities_demo/test/a6_loom_communities_demo_test.dart`; `flutter test
  apps/loom_communities_demo/test/b1a_local_workflow_test.dart
  apps/loom_communities_demo/test/b1b_publish_discover_install_test.dart
  apps/loom_communities_demo/test/b2_book_club_workflow_test.dart
  apps/loom_communities_demo/test/b3_youth_soccer_workflow_test.dart`; `flutter analyze
  apps/loom_communities_demo`; `dart run packages/tooling/manifest_gate.dart --manifest
  ../docs/Build\ Plan\ V2/test-manifest.json`; `dart run packages/tooling/phase_gate.dart --phase
  A6 --check-env`; `melos run lint:boundaries`; `git diff --check`.
- **Commit:** R20 closeout `39af637`.

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

#### Execution Record - 2026-06-09

- **Validated Skill setup:** `validation-environment.lock.json` is `validated` for Codex `local-demo`
  execution in WSL Ubuntu with Dart, Flutter, and Melos resolved from the Ubuntu toolchain.
- **Implemented workflow test:** Added
  `apps/loom_communities_demo/test/b1a_local_workflow_test.dart` covering
  `wf_local-demo-prereq-to-validation-ready` and `wf_local-build-download-sideload-install`.
- **Skill and examples:** Added the local build/download/sideload workflow guide and a book-club
  extension/init-package example under `Skill/examples/book-club/phase-b1a-local/`.
- **Manifest stamps:** Skill/prereq/tooling components now have concrete version hashes:
  ai-skill-extension-builder `b06a5c0bdc86`, skill-prereq-setup `8517e97898ef`,
  workflow-validation-harness `37f93fec7784`, and skill-debug-harness `809fc9cb1902`.
- **Passed WSL checks:** `melos bootstrap`; `flutter test
  apps/loom_communities_demo/test/b1a_local_workflow_test.dart
  apps/loom_communities_demo/test/a6_loom_communities_demo_test.dart`; `flutter analyze
  apps/loom_communities_demo`; `dart run packages/tooling/skill_prereq_check.dart --mode local-demo`;
  `dart run packages/tooling/skill_prereq_setup.dart --target codex --mode local-demo`; `dart run
  packages/tooling/manifest_gate.dart --manifest ../docs/Build\ Plan\ V2/test-manifest.json`; `dart run
  packages/tooling/phase_gate.dart --phase B1a --check-env`; `melos run lint:boundaries`.
- **R20 reopen note:** This technical closeout predates the R20 UX research/decision gate. Recreate
  `Phase B1a - UX Decisions.md` with the new method, apply any UX-driven changes, rerun B1a/A6
  regressions, and record a new closeout commit before B1a can be treated as complete again.

#### Second-Pass Execution Record - 2026-06-09

- **R20 UX decisions:** Completed `Phase B1a - UX Decisions.md` with current reference sources,
  extracted patterns, local-demo decisions, implementation decisions, workflow walkthrough, and
  tradeoffs.
- **UX-driven implementation:** `Add Community` now opens a local package loader with extension/init
  package path fields. The Demo App validates package suffixes before import, shows invalid-file
  errors, imports through the fake backend, renders the branded community card, and reports duplicate
  imports as updates.
- **Validation ownership:** Added reusable local package-pair validation to the Local In-App Backend.
- **Tests:** Added `vt_demo-app_local-loader-opens`,
  `vt_demo-app_local-loader-invalid-extension-error`,
  `vt_demo-app_local-loader-validates-package-pair`,
  `vt_demo-app_duplicate-local-import-status`, and
  `vt_fake-backend_local-package-pair-validation`.
- **Manifest:** Registered the new B1a validation tests and refreshed current component stamps:
  `loom-communities-demo-app` `fe03608c5230`; `local-in-app-backend` `332432d7b39d`.
- **Skill docs:** Updated `Skill/workflows/local-build-download-sideload-install.md` with the local
  package-pair selection and validation process.
- **Passed WSL checks:** `dart format` on changed Dart files; `dart test
  packages/core/loom_demo_local_backend/test/a6_local_backend_test.dart`; `flutter test
  packages/core/loom_app_shell/test/a6_app_shell_components_test.dart`; `flutter test
  apps/loom_communities_demo/test/a6_loom_communities_demo_test.dart
  apps/loom_communities_demo/test/b1a_local_workflow_test.dart
  apps/loom_communities_demo/test/b1b_publish_discover_install_test.dart
  apps/loom_communities_demo/test/b2_book_club_workflow_test.dart
  apps/loom_communities_demo/test/b3_youth_soccer_workflow_test.dart`; `flutter analyze
  apps/loom_communities_demo`; `dart analyze packages/core/loom_demo_local_backend`; `dart run
  packages/tooling/manifest_gate.dart --manifest ../docs/Build\ Plan\ V2/test-manifest.json`; `dart
  run packages/tooling/phase_gate.dart --phase B1a --check-env`; `melos run lint:boundaries`; `git
  diff --check`.
- **Commit:** R20 closeout `471677a`.

### Phase B1b - Publish, Discover, Certify, Install

- **Achieves:** Proves the real-backend publish mode through local stubs/contracts.
- **Deliverables:** Skill `real-backend-publish` workflow, hosted publish payloads, certification and
  registry stubs/fakes, QR/handle discovery contract, latest certified install/open behavior.
- **Completed when:** `wf_build-publish-discover-install` passes against the Demo App with Local Backend
  using local backend stubs/contracts for hosted behavior; B1a local package behavior remains green.
- **Evidence to record:** Workflow output, hosted API stub/contract output, package/certification test
  output, API Review and UX Decisions paths, Skill workflow guide path, commit SHA.

#### Execution Record - 2026-06-09

- **Implemented workflow test:** Added
  `apps/loom_communities_demo/test/b1b_publish_discover_install_test.dart` for
  `wf_build-publish-discover-install`.
- **Validated local hosted-publish stubs:** The workflow registers a builder App ID, verifies signing
  scope, certifies the package, publishes a certified extension version, resolves the community by
  handle and QR, imports the initialization package into the Local Backend, renders the card, and opens
  `local:ext_book_club@latest`.
- **Skill and examples:** Added `Skill/workflows/build-publish-discover-install.md` and the book-club
  `phase-b1b-publish` example package/init artifacts.
- **Manifest stamps:** ai-skill-extension-builder `29acc7de90fa`; workflow-validation-harness
  `44632537bded`; `wf_build-publish-discover-install` test hash `617a61fa0308`.
- **Passed WSL checks:** `dart format` on the B1b workflow test; `melos bootstrap`; `flutter test
  apps/loom_communities_demo/test/b1a_local_workflow_test.dart
  apps/loom_communities_demo/test/b1b_publish_discover_install_test.dart
  apps/loom_communities_demo/test/a6_loom_communities_demo_test.dart`; `flutter analyze
  apps/loom_communities_demo`.
- **R20 reopen note:** This technical closeout predates the R20 UX research/decision gate. Recreate
  `Phase B1b - UX Decisions.md` with the new method, apply any UX-driven changes, rerun B1b/B1a/A6
  regressions, and record a new closeout commit before B1b can be treated as complete again.

#### Second-Pass Execution Record - 2026-06-09

- **R20 UX decisions:** Completed `Phase B1b - UX Decisions.md` with current publish/review,
  certification, permission, QR/handle discovery, install preview, and latest-open references.
- **Implementation outcome:** No code change was required in B1b. The existing workflow already
  validates builder signing, certification, registry publication, handle/QR discovery, local import,
  and latest-open against local fakes and the Demo App with Local Backend.
- **Passed WSL checks:** `flutter test apps/loom_communities_demo/test/b1b_publish_discover_install_test.dart
  apps/loom_communities_demo/test/b1a_local_workflow_test.dart
  apps/loom_communities_demo/test/a6_loom_communities_demo_test.dart`; `dart run
  packages/tooling/manifest_gate.dart --manifest ../docs/Build\ Plan\ V2/test-manifest.json`; `dart
  run packages/tooling/phase_gate.dart --phase B1b --check-env`; `melos run lint:boundaries`; `git
  diff --check`.
- **Commit:** R20 closeout `105cb16`.

### Phase B2 - Book Club Headline Flow

- **Achieves:** Validates the first complete vertical extension.
- **Deliverables:** Book club package fragments, nomination schema, voting workflow, meeting event,
  discussion thread, permitted search/digest behavior, Skill workflow guide and example updates.
- **Completed when:** `wf_book-club-headline` passes in the Demo App with Local Backend and all altered
  component validation/regression tests pass.
- **Evidence to record:** Workflow output, package fixture hashes, component regression output, API Review
  and UX Decisions paths, Skill example paths, commit SHA.

#### Execution Record - 2026-06-09

- **Implemented workflow test:** Added `apps/loom_communities_demo/test/workflow_test_harness.dart` and
  `apps/loom_communities_demo/test/b2_book_club_workflow_test.dart`.
- **Validated end state:** The book club workflow installs a local community, submits a nomination,
  records a vote, creates and RSVPs to the meeting, publishes the winning selection, sends a discussion
  message, indexes the selection, generates a cited digest, and opens `local:ext_book_club@latest`.
- **Skill and examples:** Added `Skill/workflows/book-club-headline.md` and
  `Skill/examples/book-club/phase-b2-headline/`.
- **Manifest stamps:** ai-skill-extension-builder `1a5665e8b68d`; workflow-validation-harness
  `a5d952a0a466`; `wf_book-club-headline` test hash `ce5f487585dc`.
- **R20 reopen note:** This technical closeout predates the R20 UX research/decision gate. Recreate
  `Phase B2 - UX Decisions.md` with the new method, apply any UX-driven changes, rerun B2 and prior
  Set B regressions, and record a new closeout commit before B2 can be treated as complete again.

#### Second-Pass Execution Record - 2026-06-09

- **R20 UX decisions:** Completed `Phase B2 - UX Decisions.md` with current book club, poll, event,
  RSVP, discussion, thread, and digest references.
- **Implementation outcome:** No code change was required in B2. The existing workflow already
  validates nomination, vote, selected-book publishing, event/RSVP, discussion message, indexing,
  AI answer, cited digest, card render, and local latest-open behavior.
- **Passed WSL checks:** `flutter test apps/loom_communities_demo/test/b2_book_club_workflow_test.dart
  apps/loom_communities_demo/test/b1b_publish_discover_install_test.dart
  apps/loom_communities_demo/test/b1a_local_workflow_test.dart
  apps/loom_communities_demo/test/a6_loom_communities_demo_test.dart`; `dart run
  packages/tooling/manifest_gate.dart --manifest ../docs/Build\ Plan\ V2/test-manifest.json`; `dart
  run packages/tooling/phase_gate.dart --phase B2 --check-env`; `melos run lint:boundaries`; `git
  diff --check`.
- **Commit:** R20 closeout `e97ba72`.

### Phase B3 - Youth Soccer Headline Flow

- **Achieves:** Validates guardian/minor, schedule, payment, roster, and notification behavior.
- **Deliverables:** Youth soccer package, protected minor-data flow, registration payment, roster views,
  schedule/events, notifications, Skill workflow guide and example updates.
- **Completed when:** `wf_youth-soccer-headline` passes in the Demo App with Local Backend and protected
  data, permission, and payment regressions pass.
- **Evidence to record:** Workflow output, protected-data assertions, payment test output, API Review and
  UX Decisions paths, Skill example paths, commit SHA.

#### Execution Record - 2026-06-09

- **Implemented workflow test:** Added
  `apps/loom_communities_demo/test/b3_youth_soccer_workflow_test.dart`.
- **Validated end state:** The workflow approves guardian membership, creates a team space, writes and
  reads protected minor data with redaction, records registration payment, creates a practice event,
  delivers a deduped reminder, and opens `local:ext_youth_soccer@latest`.
- **Skill and examples:** Added `Skill/workflows/youth-soccer-headline.md` and
  `Skill/examples/youth-soccer/phase-b3-headline/`.
- **Manifest stamps:** ai-skill-extension-builder `ebb94a52333e`; workflow-validation-harness
  `09c26b466480`; `wf_youth-soccer-headline` test hash `e404d2433f01`.
- **R20 reopen note:** This technical closeout predates the R20 UX research/decision gate. Recreate
  `Phase B3 - UX Decisions.md` with the new method, apply any UX-driven changes, rerun B3 and prior
  Set B regressions, and record a new closeout commit before B3 can be treated as complete again.

#### Second-Pass Execution Record - 2026-06-09

- **R20 UX decisions:** Completed `Phase B3 - UX Decisions.md` with current youth sports
  registration, payments, roster, schedule, communication, and child-privacy references.
- **Implementation outcome:** No code change was required in B3. The existing workflow already
  validates guardian membership approval, team space creation, protected minor-data redaction,
  registration payment, schedule event, notification delivery, and local latest-open behavior.
- **Passed WSL checks:** `flutter test apps/loom_communities_demo/test/b3_youth_soccer_workflow_test.dart
  apps/loom_communities_demo/test/b2_book_club_workflow_test.dart
  apps/loom_communities_demo/test/b1b_publish_discover_install_test.dart
  apps/loom_communities_demo/test/b1a_local_workflow_test.dart
  apps/loom_communities_demo/test/a6_loom_communities_demo_test.dart`; `dart run
  packages/tooling/manifest_gate.dart --manifest ../docs/Build\ Plan\ V2/test-manifest.json`; `dart
  run packages/tooling/phase_gate.dart --phase B3 --check-env`; `melos run lint:boundaries`; `git
  diff --check`.
- **Commit:** R20 closeout `23dd422`.

### Phase B4 - HOA Headline Flow

- **Achieves:** Validates dues, documents, facilities, case workflow, and export behavior.
- **Deliverables:** HOA package, dues payment, document visibility, facility reservation, architectural
  request workflow, export metadata, Skill workflow guide and example updates.
- **Completed when:** `wf_hoa-headline` passes in the Demo App with Local Backend and documents,
  facilities, wallet, case/task, workflow, and export regressions pass.
- **Evidence to record:** Workflow output, export coverage output, component regression output, API Review
  and UX Decisions paths, Skill example paths, commit SHA.

#### Second-Pass Execution Record - 2026-06-09

- **R20 UX decisions:** Completed `Phase B4 - UX Decisions.md` with current HOA portal,
  homeowner payment, document, amenity reservation, architectural request, and case-status
  references.
- **Implementation outcome:** Added the HOA workflow test and example package. The workflow validates
  dues payment, document visibility, facility reservation with payment, architectural review case
  lifecycle, workflow transition, notification delivery, export component coverage, and local
  latest-open behavior in the Demo App with Local Backend.
- **Skill/API artifacts:** Added `Skill/workflows/hoa-headline.md`,
  `Skill/examples/hoa/README.md`, `Skill/examples/hoa/loom.extension.json`,
  `Skill/examples/hoa/loom.initialization.json`, and `Phase B4 - API Review.md`; updated the
  master Skill walkthrough.
- **Manifest stamps:** workflow-validation-harness `09c26b466480`; export-service `9079b5ad7e37`;
  `wf_hoa-headline` test hash `563319be521c`.
- **Passed WSL checks:** `flutter test apps/loom_communities_demo/test/b4_hoa_workflow_test.dart
  apps/loom_communities_demo/test/b3_youth_soccer_workflow_test.dart
  apps/loom_communities_demo/test/b2_book_club_workflow_test.dart
  apps/loom_communities_demo/test/b1b_publish_discover_install_test.dart
  apps/loom_communities_demo/test/b1a_local_workflow_test.dart
  apps/loom_communities_demo/test/a6_loom_communities_demo_test.dart`; fake backend A4a/A4b/A5
  regression tests; `flutter analyze apps/loom_communities_demo`; `dart analyze
  packages/core/loom_fake_backend`; manifest and B4 phase gates; boundary lint; `git diff --check`.
- **Commit:** B4 closeout `f3ffad3`.

### Phase B5 - Mosque Headline Flow

- **Achieves:** Validates donation, event, volunteer, announcement, and protected care-request behavior.
- **Deliverables:** Mosque package, announcements, event RSVP, volunteer signup, donor visibility,
  protected care request, notifications, Skill workflow guide and example updates.
- **Completed when:** `wf_mosque-headline` passes in the Demo App with Local Backend and sensitive data,
  donation, event, form, notification, search/AI, and App Shell regressions pass.
- **Evidence to record:** Workflow output, protected-vault assertions, donation receipt output, API Review
  and UX Decisions paths, Skill example paths, commit SHA.

#### Second-Pass Execution Record - 2026-06-09

- **R20 UX decisions:** Completed `Phase B5 - UX Decisions.md` with current mosque app,
  mosque-management, faith-community giving, event, volunteer, donor privacy, and private
  prayer/care-request references.
- **Implementation outcome:** Added the mosque workflow test and example package. The workflow validates
  public announcement publishing, event RSVP, volunteer signup with protected contact details,
  anonymous donor visibility, donation payment, protected care request, neutral notification,
  public announcement search/AI citation, and local latest-open behavior in the Demo App with Local
  Backend.
- **Skill/API artifacts:** Added `Skill/workflows/mosque-headline.md`,
  `Skill/examples/mosque/loom.extension.json`, `Skill/examples/mosque/loom.initialization.json`,
  updated `Skill/examples/mosque/README.md`, updated the master Skill walkthrough, and completed
  `Phase B5 - API Review.md`.
- **Manifest stamps:** `wf_mosque-headline` test hash `6887a1ff12ff`; workflow-validation-harness
  `09c26b466480`; publishing-service `0e31d279bf88`; wallet-dues-donations `071871e00937`;
  protected-visibility-vault `3795b6a09b20`; search-service `00f0b4124434`; ai-gateway
  `66fa617e8d1b`.
- **Passed WSL checks:** `flutter test apps/loom_communities_demo/test/b5_mosque_workflow_test.dart
  apps/loom_communities_demo/test/b4_hoa_workflow_test.dart
  apps/loom_communities_demo/test/b3_youth_soccer_workflow_test.dart
  apps/loom_communities_demo/test/b2_book_club_workflow_test.dart
  apps/loom_communities_demo/test/b1b_publish_discover_install_test.dart
  apps/loom_communities_demo/test/b1a_local_workflow_test.dart
  apps/loom_communities_demo/test/a6_loom_communities_demo_test.dart`; A1/A3/A4b component
  regression tests; `flutter analyze apps/loom_communities_demo`; manifest and B5 phase gates;
  boundary lint; `git diff --check`.
- **Commit:** B5 closeout `163dad1`.

### Phase B6 - Messaging, In-Stream Ads, and Connections

- **Achieves:** Validates required platform social and ad surfaces.
- **Deliverables:** Messages and Connections navigation, invite/block behavior, stream rendering,
  in-stream ad item behavior, top banner behavior, no-fill behavior, Skill workflow guide update.
- **Completed when:** `wf_messaging-ads-connections` passes in the Demo App with Local Backend; shell
  invariants prove extensions cannot hide Messages, Connections, or required ad surfaces.
- **Evidence to record:** Workflow output, shell invariant lint output, ad decision/no-fill output, API
  Review and UX Decisions paths, Skill workflow guide path, commit SHA.

#### Second-Pass Execution Record - 2026-06-09

- **R20 UX decisions:** Completed `Phase B6 - UX Decisions.md` with current navigation, messaging
  request/block, native ad disclosure, sponsored content, and native ad load/no-fill references.
- **Implementation outcome:** Added the messaging/ads/connections workflow test. The workflow validates
  shell-owned Messages and Connections, required top banner no-fill state, message stream rendering,
  connection invite and blocked-target prevention, in-stream/top-banner ad fills, sensitive-context
  no-fill, Sponsored disclosure, and local latest-open behavior.
- **Skill/API artifacts:** Added `Skill/workflows/messaging-ads-connections.md`, updated the master
  Skill walkthrough, and completed `Phase B6 - API Review.md`.
- **Manifest stamps:** `wf_messaging-ads-connections` test hash `15e89fb50365`; messaging-stream-service
  `709572cac272`; connections-graph `297b5d201b5f`; ad-campaign-service `7d781eea95a9`;
  ad-decision-service `e5a7593ee1ea`; app-shell-runtime `c7c0a602fdad`; stream-renderer
  `07547f0370c6`.
- **Passed WSL checks:** `flutter test
  apps/loom_communities_demo/test/b6_messaging_ads_connections_workflow_test.dart
  apps/loom_communities_demo/test/b5_mosque_workflow_test.dart
  apps/loom_communities_demo/test/b4_hoa_workflow_test.dart
  apps/loom_communities_demo/test/b3_youth_soccer_workflow_test.dart
  apps/loom_communities_demo/test/b2_book_club_workflow_test.dart
  apps/loom_communities_demo/test/b1b_publish_discover_install_test.dart
  apps/loom_communities_demo/test/b1a_local_workflow_test.dart
  apps/loom_communities_demo/test/a6_loom_communities_demo_test.dart`; A1/A3/A4b/A6 component
  regression tests; `flutter analyze apps/loom_communities_demo`; manifest and B6 phase gates;
  boundary lint; `git diff --check`.
- **Commit:** B6 closeout `b8c348d`.

### Phase B7 - Ad-Off

- **Achieves:** Validates ad-off purchase and economic side effects.
- **Deliverables:** Member/community ad-off purchase, entitlement checks, ad decision changes, receipts,
  settlement, utility funding allocation, Skill workflow guide update.
- **Completed when:** `wf_ad-off` passes in the Demo App with Local Backend and wallet, ad decision,
  receipt, settlement, utility funding, payment surface, and ad slot regressions pass.
- **Evidence to record:** Workflow output, payment/receipt output, settlement output, API Review and UX
  Decisions paths, Skill workflow guide path, commit SHA.

#### Second-Pass Execution Record - 2026-06-09

- **R20 UX decisions:** Completed `Phase B7 - UX Decisions.md` with current subscription/ad-off,
  purchase management, entitlement status, receipt, restore/recheck, and ad-removal expectation
  references.
- **Implementation outcome:** Added community-wide ad-off support to the local wallet fake, added
  `vt_wallet_community-ad-off` and `vt_ad-decision_ad-off`, and added the ad-off workflow test. The
  workflow validates shell-owned member/community checkout, pre-entitlement ad fill, member ad-off
  suppression, community ad-off suppression, sensitive-context no-fill, receipt linkage, settlement,
  utility allocation, and local latest-open behavior.
- **Skill/API artifacts:** Added `Skill/workflows/ad-off.md`, updated the master Skill walkthrough,
  and completed `Phase B7 - API Review.md`.
- **Manifest stamps:** wallet-dues-donations `f49eb0bac62d`; A4b economic test hash `842b87d3f51a`;
  `wf_ad-off` test hash `2e3f04bafe9d`.
- **Passed WSL checks:** `flutter test apps/loom_communities_demo/test/b7_ad_off_workflow_test.dart
  apps/loom_communities_demo/test/b6_messaging_ads_connections_workflow_test.dart
  apps/loom_communities_demo/test/b5_mosque_workflow_test.dart
  apps/loom_communities_demo/test/b4_hoa_workflow_test.dart
  apps/loom_communities_demo/test/b3_youth_soccer_workflow_test.dart
  apps/loom_communities_demo/test/b2_book_club_workflow_test.dart
  apps/loom_communities_demo/test/b1b_publish_discover_install_test.dart
  apps/loom_communities_demo/test/b1a_local_workflow_test.dart
  apps/loom_communities_demo/test/a6_loom_communities_demo_test.dart`; A4b/A6 component regression
  tests; `dart analyze packages/core/loom_fake_backend`; `flutter analyze apps/loom_communities_demo`;
  manifest and B7 phase gates; boundary lint; `git diff --check`.
- **Commit:** B7 closeout `b06d3c7`.

### Phase B8 - Export and Migration

- **Achieves:** Validates portability and closes the build-plan readiness gate.
- **Deliverables:** Community export, member export/delete behavior, extension custom-data export,
  protected redaction, provider transfer verify/rollback, full workflow regression, final API spec
  inventory, final Skill/example updates.
- **Completed when:** `wf_export-migration`, `vt_api_specs_complete`, the full Set B workflow suite, and
  all altered component regressions pass; every required API/local contract exists and validates.
- **Evidence to record:** Workflow output, full regression output, API inventory output, export package
  checksums, API Review and UX Decisions paths, Skill/example paths, commit SHA.

#### Second-Pass Execution Record - 2026-06-09

- **R20 UX decisions:** Completed `Phase B8 - UX Decisions.md` with current export, import/export,
  retention, provider migration, verification, and rollback/readiness references.
- **Implementation outcome:** Added provider-transfer rollback to the local API contract and fake,
  added `vt_provider-transfer_rollback`, added the export/migration workflow test, and added the
  `vt_api_specs_complete` validator. The workflow validates import preview/replay, protected-field
  routing, exportable custom schema enumeration, full/redacted export bundles, checksum evidence,
  receipt inclusion, provider transfer verification, provider transfer rollback, and local latest-open
  behavior.
- **Skill/API artifacts:** Added `Skill/workflows/export-migration.md`, updated the master Skill
  walkthrough, added export metadata to the book club, youth soccer, HOA, and mosque examples, and
  completed `Phase B8 - API Review.md`.
- **Manifest stamps:** api-spec-inventory `9d57761d8326`; provider-transfer-service
  `7a931f77c1e1`; A4a ops test hash `28947a0e1dd0`; `wf_export-migration` test hash
  `90ae5bef5a27`.
- **Passed WSL checks:** `flutter test apps/loom_communities_demo/test/b8_export_migration_workflow_test.dart
  apps/loom_communities_demo/test/b7_ad_off_workflow_test.dart
  apps/loom_communities_demo/test/b6_messaging_ads_connections_workflow_test.dart
  apps/loom_communities_demo/test/b5_mosque_workflow_test.dart
  apps/loom_communities_demo/test/b4_hoa_workflow_test.dart
  apps/loom_communities_demo/test/b3_youth_soccer_workflow_test.dart
  apps/loom_communities_demo/test/b2_book_club_workflow_test.dart
  apps/loom_communities_demo/test/b1b_publish_discover_install_test.dart
  apps/loom_communities_demo/test/b1a_local_workflow_test.dart
  apps/loom_communities_demo/test/a6_loom_communities_demo_test.dart`; A4a/A4b/A5/A6 component
  regression tests; API inventory validator; `dart analyze packages/core/loom_api_contracts`;
  `dart analyze packages/core/loom_fake_backend`; `flutter analyze apps/loom_communities_demo`;
  manifest and B8 phase gates; boundary lint; `git diff --check`.
- **Commit:** B8 closeout `762f556`.

### Phase B9 - Arbitrary Local Package Ingestion

- **Achieves:** Validates that local-demo install consumes arbitrary selected package contents instead
  of substituting a fixture.
- **Deliverables:** File-backed package pair parsing in Local In-App Backend, Demo App loader import via
  parsed files, arbitrary widget/backend/workflow tests, B9 API Review, B9 UX Decisions, Skill
  arbitrary-ingestion workflow guide, manifest rows.
- **Completed when:** `vt_fake-backend_parse-arbitrary-local-package-pair`,
  `vt_fake-backend_import-arbitrary-package-pair`, `vt_demo-app_arbitrary-local-extension-loads-card`,
  `wf_arbitrary-local-package-ingestion`, affected A6/B1a/B8 regressions, manifest gate, B9 phase
  gate, analyze, boundary lint, and diff check pass in WSL Ubuntu.
- **Evidence to record:** Focused backend/widget/workflow test output, Set B regression output, API
  Review and UX Decisions paths, Skill workflow guide path, component/test hashes, implementation
  commit SHA, tracker stamp SHA.

#### Execution Record - 2026-06-09

- **Implementation outcome:** Added file-backed local package parsing/import to
  `LocalInAppBackend`, routed the Demo App loader through the parsed package pair, and removed the
  hardcoded Book Club install path from the UI.
- **Tests added/updated:** Added arbitrary backend parsing/import assertions, updated Demo App widget
  tests to enter generated package paths, and added `wf_arbitrary-local-package-ingestion` for an
  arbitrary Chess Club package pair.
- **Skill/API/UX artifacts:** Added `Phase B9 - API Review.md`,
  `Phase B9 - UX Decisions.md`, `Phase B9 - Arbitrary Local Package Ingestion.md`,
  `Skill/workflows/arbitrary-local-package-ingestion.md`, and the master Skill walkthrough update.
- **Manifest stamps:** `local-in-app-backend` `f5a3e98e5595`; `loom-communities-demo-app`
  `42175a068b2a`; backend test hash `69045e9512a0`; widget test hash `d4401d6651a`;
  B9 workflow test hash `c63d67658e18`.
- **Passed WSL checks:** `dart test packages/core/loom_demo_local_backend/test/a6_local_backend_test.dart`;
  `flutter test apps/loom_communities_demo/test/a6_loom_communities_demo_test.dart
  apps/loom_communities_demo/test/b1a_local_workflow_test.dart
  apps/loom_communities_demo/test/b1b_publish_discover_install_test.dart
  apps/loom_communities_demo/test/b2_book_club_workflow_test.dart
  apps/loom_communities_demo/test/b3_youth_soccer_workflow_test.dart
  apps/loom_communities_demo/test/b4_hoa_workflow_test.dart
  apps/loom_communities_demo/test/b5_mosque_workflow_test.dart
  apps/loom_communities_demo/test/b6_messaging_ads_connections_workflow_test.dart
  apps/loom_communities_demo/test/b7_ad_off_workflow_test.dart
  apps/loom_communities_demo/test/b8_export_migration_workflow_test.dart
  apps/loom_communities_demo/test/b9_arbitrary_local_package_ingestion_test.dart`;
  `dart analyze packages/core/loom_demo_local_backend`; `flutter analyze apps/loom_communities_demo`;
  manifest and B9 phase gates; boundary lint; `git diff --check`.
- **Commit:** B9 implementation `db3c476`; tracker stamp TBD.

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
| api-spec-inventory | 0 | 9d57761d8326 | B8 |
| phase-test-manifest-bridge | 0/A2 | 89e620c5af33 | A2 |
| publishing-service | A3 | 0e31d279bf88 | A3 |
| messaging-stream-service | A3 | 709572cac272 | A3 |
| notification-service | A3 | b7c57774de42 | A3 |
| events-service | A3 | dee493ff7d53 | A3 |
| forms-voting-service | A3 | 72bf23f58102 | A3 |
| export-service | A4a | 9079b5ad7e37 | B4 |
| import-service | A4a | 0a178c20caba | B8 |
| provider-transfer-service | A4a | 7a931f77c1e1 | B8 |
| wallet-dues-donations | A4b | f49eb0bac62d | B7 |
| ad-decision-service | A4b | e5a7593ee1ea | A4b |
| search-service | A4b | 00f0b4124434 | A4b |
| extension-runtime-bridge | A5 | 1aff2ed72457 | A5 |
| extension-package-validator | A5 | 512380dc6848 | A5 |
| initialization-package-schema | A5 | 1dd4a2b2ca52 | A5 |
| data-schema-store | A5 | 6a09d351f11f | B8 |
| app-shell-runtime | A6 | c7c0a602fdad | A6 |
| loom-communities-demo-app | A6 | 42175a068b2a | B9 |
| local-in-app-backend | A6 | f5a3e98e5595 | B9 |

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
