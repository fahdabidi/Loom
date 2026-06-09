# Loom Communities V2 Test Manifest

Status: Generated human view seed
Machine source: [test-manifest.json](./test-manifest.json)

This file is the human-readable view of the machine manifest. During execution it should be generated
from `test-manifest.json`, not hand-maintained.

All Set B workflow tests run against the Demo Loom Communities App with the Local Backend. The Skill
has two modes: `local-demo` and `real-backend-publish`; both are validated locally before any external
backend is required.

The first supported Skill execution targets are Codex and Claude Code. Online-only execution targets
are deferred until a hosted Loom build and validation backend exists.

## Test Types

| Type | Prefix | Meaning |
| --- | --- | --- |
| Validation | `vt_` | Owned by one component; proves one capability or conformance behavior. |
| Contract | `ct_` | Provider-authored test that a consumer runs against provider contract/fake. |
| Workflow | `wf_` | End-to-end workflow/user-story test. |

## Phase 0

| Test | Type | Owner | Covers | Status |
| --- | --- | --- | --- | --- |
| `vt_manifest_schema` | validation | phase-test-manifest-bridge | phase-test-manifest-bridge | planned |
| `vt_skill_skeleton` | validation | ai-skill-extension-builder | ai-skill-extension-builder | planned |
| `vt_api-spec-inventory_schema` | validation | api-spec-inventory | api-spec-inventory | planned |
| `vt_skill-debug-harness_fixture-replay` | validation | skill-debug-harness | skill-debug-harness | planned |
| `vt_skill-prereq_manifest-complete` | validation | skill-prereq-setup | skill-prereq-setup | planned |
| `vt_skill-prereq_host-detection` | validation | skill-prereq-setup | skill-prereq-setup | planned |
| `vt_skill-prereq_install-plan` | validation | skill-prereq-setup | skill-prereq-setup | planned |

## Set A - Component Phases

| Phase | Component group | Required examples |
| --- | --- | --- |
| A1 | Foundation | `vt_passport-ledger_create-resolve`, `vt_role-policy_effective-permission`, `vt_event-bus_publish`, `vt_receipt-ledger_append` |
| A2 | Registry/control-plane | `vt_community-registry_discovery`, `vt_community-registry_branding`, `vt_spaces_nesting`, `vt_extension-registry_resolve-latest`, `vt_certification_validate-package`, `vt_certification_asset-evidence` |
| A3 | Experience services | `vt_publishing_publish`, `vt_messaging_stream-render`, `vt_events_rsvp`, `vt_forms-voting_submit` |
| A4a | Ops/community services | `vt_case-task_transition`, `vt_documents_permissions`, `vt_facilities_reservation`, `vt_export_redaction`, `vt_moderation_case-lifecycle` |
| A4b | Economic/search/ads | `vt_wallet_payment`, `vt_ad-decision_sensitive-no-fill`, `vt_search_permission-aware`, `vt_ai-gateway_answer`, `vt_settlement_run` |
| A5 | Extension engines | `vt_extension-runtime_session`, `vt_rule-engine_evaluate`, `vt_workflow-engine_transition`, `vt_data-schema_export-index`, `vt_extension-package_downloadable-shape`, `vt_extension-package_asset-manifest`, `vt_extension-package_asset-policy`, `vt_initialization-package_schema`, `vt_initialization-package_community-branding` |
| A6 | UX micro-components + local demo | `vt_app-shell_required-nav`, `vt_app-shell_ad-slots`, `vt_payment-surface_shell-owned`, `vt_connections-shell_invite-blocked`, `vt_community-card_branding-priority`, `vt_demo-app_empty-community-state`, `vt_demo-app_card-image-after-load`, `vt_fake-backend_import-init-package`, `vt_local-store_persist-reload` |

## Phase A1 Execution Status

| Test | Type | Owner | Covers | Status |
| --- | --- | --- | --- | --- |
| `vt_passport-ledger_create-resolve` | validation | passport-ledger | passport-ledger | pass |
| `vt_role-policy_effective-permission` | validation | role-policy-consent-engine | role-policy-consent-engine | pass |
| `vt_core-vault_preferences` | validation | core-member-vault | core-member-vault | pass |
| `vt_protected-vault_read-gated` | validation | protected-visibility-vault | protected-visibility-vault, role-policy-consent-engine | pass |
| `vt_connections_invite-permission` | validation | connections-graph | connections-graph | pass |
| `vt_receipt-ledger_append` | validation | receipt-ledger | receipt-ledger | pass |
| `vt_event-bus_publish` | validation | event-bus | event-bus | pass |
| `vt_builder-app-id_signing-scope` | validation | builder-app-id-service | builder-app-id-service, key-management | pass |
| `ct_role-policy__extension-runtime_effective-permission` | contract | role-policy-consent-engine | role-policy-consent-engine, extension-runtime-bridge | pending-counterpart |
| `ct_protected-vault__ads_no-fill-sensitive` | contract | protected-visibility-vault | protected-visibility-vault, ad-decision-service | pending-counterpart |
| `ct_receipt-ledger__wallet_append-payment` | contract | receipt-ledger | receipt-ledger, wallet-dues-donations | pending-counterpart |
| `ct_event-bus__rule-engine_publish-replay` | contract | event-bus | event-bus, rule-engine | pending-counterpart |
| `ct_connections__invitation_blocked-path` | contract | connections-graph | connections-graph, invitation-service | pass |
| `ct_builder-app-id__extension-registry_signing-scope` | contract | builder-app-id-service | builder-app-id-service, extension-registry | pass |

## Phase A2 Execution Status

| Test | Type | Owner | Covers | Status |
| --- | --- | --- | --- | --- |
| `vt_workflow-inventory_test-index` | validation | workflow-inventory-registry | workflow-inventory-registry | pass |
| `vt_test-manifest_staleness` | validation | phase-test-manifest-bridge | phase-test-manifest-bridge | pass |
| `vt_community-registry_discovery` | validation | community-registry | community-registry | pass |
| `vt_community-registry_branding` | validation | community-registry | community-registry | pass |
| `vt_spaces_nesting` | validation | spaces-service | spaces-service, community-registry | pass |
| `vt_membership_join-approval` | validation | membership-service | membership-service, passport-ledger, community-registry | pass |
| `vt_invitation_create-revoke` | validation | invitation-service | invitation-service, connections-graph | pass |
| `vt_extension-registry_resolve-latest` | validation | extension-registry | extension-registry, certification-system | pass |
| `vt_certification_validate-package` | validation | certification-system | certification-system | pass |
| `vt_certification_asset-evidence` | validation | certification-system | certification-system | pass |
| `vt_public-registry_status` | validation | public-registry-read-model | public-registry-read-model | pass |
| `ct_certification__extension-registry_certify-package` | contract | certification-system | certification-system, extension-registry | pass |
| `ct_community-registry__extension-registry_installed-pointers` | contract | community-registry | community-registry, extension-registry | pass |
| `ct_invitation__membership_accept` | contract | invitation-service | invitation-service, membership-service | pass |
| `ct_spaces__membership_space-join` | contract | spaces-service | spaces-service, membership-service | pass |
| `ct_community-registry__app-shell_resolve-by-qr` | contract | community-registry | community-registry, app-shell-runtime | pending-counterpart |
| `ct_extension-registry__app-shell_resolve-latest` | contract | extension-registry | extension-registry, app-shell-runtime | pending-counterpart |
| `ct_membership__app-shell_member-state` | contract | membership-service | membership-service, app-shell-runtime | pending-counterpart |
| `ct_public-registry__app-shell_trust-state` | contract | public-registry-read-model | public-registry-read-model, app-shell-runtime | pending-counterpart |

## Set B - Workflow Phases

| Phase | Workflow test | Covered workflow |
| --- | --- | --- |
| B1a | `wf_local-demo-prereq-to-validation-ready` | Skill prereq setup -> install/configure tools -> environment lock -> Demo App smoke |
| B1a | `wf_local-build-download-sideload-install` | Skill build -> download package/init package -> local file load -> fake backend import -> card -> local latest open |
| B1b | `wf_build-publish-discover-install` | Skill build -> publish -> certify -> QR/handle -> install -> latest open |
| B2 | `wf_book-club-headline` | Book nominate/vote/event/discussion/digest |
| B3 | `wf_youth-soccer-headline` | Parent join, minor protected data, payment, roster, schedule |
| B4 | `wf_hoa-headline` | Dues, documents, facility, architectural request, export |
| B5 | `wf_mosque-headline` | Donations, events, volunteers, care request |
| B6 | `wf_messaging-ads-connections` | Required nav, messaging, connections, in-stream ads |
| B7 | `wf_ad-off` | Member/community ad-off, ad suppression, settlement |
| B8 | `wf_export-migration` | Community export, protected redaction, provider transfer |

## Required B1a Local Flow Coverage

| Capability | Test IDs |
| --- | --- |
| Skill validation environment | `vt_skill-prereq_manifest-complete`, `vt_skill-prereq_host-detection`, `vt_skill-prereq_install-plan`, `vt_skill-prereq_environment-lock`, `vt_skill-prereq_demo-app-smoke`, `ct_skill-prereq-setup__workflow-validation-harness_environment-ready`, `wf_local-demo-prereq-to-validation-ready` |
| Empty app and Add Community | `vt_demo-app_empty-community-state`, `vt_demo-app_add-community-button` |
| Skill local artifacts | `vt_skill_generate-downloadable-extension`, `vt_skill_generate-initialization-package`, `vt_skill_generate-brand-assets`, `vt_skill_debug_golden-flow` |
| Package validation and local load | `vt_extension-package_downloadable-shape`, `vt_extension-package_asset-manifest`, `vt_extension-package_asset-policy`, `vt_demo-app_local-file-load-extension`, `ct_extension-package__demo-loader_validate-load` |
| Initialization import | `vt_initialization-package_schema`, `vt_initialization-package_idempotency`, `vt_initialization-package_community-branding`, `vt_fake-backend_import-init-package`, `vt_fake-backend_import-idempotent`, `ct_initialization-package__fake-backend_import`, `ct_initialization-package__fake-backend_branding-import` |
| Local persistence, branded card, and open | `vt_local-store_persist-reload`, `vt_demo-app_cards-after-load`, `vt_demo-app_card-image-after-load`, `vt_community-card_branding-priority`, `vt_demo-app_open-local-extension`, `ct_local-backend__community-card_branding-props`, `ct_extension-runtime__app-shell_local-session` |
| End to end | `wf_local-build-download-sideload-install` |

## Manifest Rules

- A `pass` result is valid only for the recorded component version hashes and test hash.
- Any component hash change makes tests covering that component `stale`.
- Any test file hash change makes that test `stale`.
- `pending-counterpart` is allowed only when a provider or consumer component does not exist yet.
