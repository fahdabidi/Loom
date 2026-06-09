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
| A6 | UX micro-components + local demo | `vt_app-shell_required-nav`, `vt_app-shell_ad-slots`, `vt_payment-surface_shell-owned`, `vt_connections-shell_invite-blocked`, `vt_community-card_branding-priority`, `vt_demo-app_empty-community-state`, `vt_demo-app_empty-state-cta-loads-community`, `vt_demo-app_card-image-after-load`, `vt_fake-backend_import-init-package`, `vt_local-store_persist-reload` |

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
| `ct_role-policy__extension-runtime_effective-permission` | contract | role-policy-consent-engine | role-policy-consent-engine, extension-runtime-bridge | pass |
| `ct_protected-vault__ads_no-fill-sensitive` | contract | protected-visibility-vault | protected-visibility-vault, ad-decision-service | pass |
| `ct_receipt-ledger__wallet_append-payment` | contract | receipt-ledger | receipt-ledger, wallet-dues-donations | pass |
| `ct_event-bus__rule-engine_publish-replay` | contract | event-bus | event-bus, rule-engine | pass |
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
| `ct_community-registry__app-shell_resolve-by-qr` | contract | community-registry | community-registry, app-shell-runtime | pass |
| `ct_extension-registry__app-shell_resolve-latest` | contract | extension-registry | extension-registry, app-shell-runtime | pass |
| `ct_membership__app-shell_member-state` | contract | membership-service | membership-service, app-shell-runtime | pass |
| `ct_public-registry__app-shell_trust-state` | contract | public-registry-read-model | public-registry-read-model, app-shell-runtime | pass |

## Phase A3 Execution Status

| Test | Type | Owner | Covers | Status |
| --- | --- | --- | --- | --- |
| `vt_publishing_publish` | validation | publishing-service | publishing-service, role-policy-consent-engine | pass |
| `vt_publishing_visibility` | validation | publishing-service | publishing-service | pass |
| `vt_messaging_stream-render` | validation | messaging-stream-service | messaging-stream-service | pass |
| `vt_messaging_direct-group` | validation | messaging-stream-service | messaging-stream-service | pass |
| `vt_notification_deliver` | validation | notification-service | notification-service | pass |
| `vt_events_rsvp` | validation | events-service | events-service | pass |
| `vt_events_ticketing` | validation | events-service | events-service | pass |
| `vt_forms-voting_submit` | validation | forms-voting-service | forms-voting-service, protected-visibility-vault | pass |
| `vt_forms-voting_poll-results` | validation | forms-voting-service | forms-voting-service | pass |
| `ct_forms-voting__protected-vault_sensitive-fields` | contract | forms-voting-service | forms-voting-service, protected-visibility-vault | pass |
| `ct_publishing__search_index-visible-content` | contract | publishing-service | publishing-service, search-service | pass |
| `ct_publishing__stream-renderer_render-post` | contract | publishing-service | publishing-service, stream-renderer | pass |
| `ct_messaging__stream-renderer_render-message-and-ad-item` | contract | messaging-stream-service | messaging-stream-service, stream-renderer | pass |
| `ct_messaging__ad-decision_in-stream-insertion` | contract | messaging-stream-service | messaging-stream-service, ad-decision-service | pass |
| `ct_events__workflow-engine_event-registration` | contract | events-service | events-service, workflow-engine | pass |
| `ct_notification__workflow-engine_delivery` | contract | notification-service | notification-service, workflow-engine | pass |

## Phase A4a Execution Status

| Test | Type | Owner | Covers | Status |
| --- | --- | --- | --- | --- |
| `vt_case-task_transition` | validation | case-task-service | case-task-service | pass |
| `vt_documents_permissions` | validation | documents-service | documents-service, role-policy-consent-engine | pass |
| `vt_facilities_reservation` | validation | facilities-service | facilities-service | pass |
| `vt_import_dry-run` | validation | import-service | import-service | pass |
| `vt_import_commit` | validation | import-service | import-service | pass |
| `vt_export_assemble` | validation | export-service | export-service | pass |
| `vt_export_redaction` | validation | export-service | export-service, protected-visibility-vault | pass |
| `vt_provider-transfer_execute-verify` | validation | provider-transfer-service | provider-transfer-service | pass |
| `vt_provider-transfer_rollback` | validation | provider-transfer-service | provider-transfer-service | pass |
| `vt_abuse-report_submit` | validation | abuse-report-service | abuse-report-service | pass |
| `vt_moderation_case-lifecycle` | validation | moderation-case-service | moderation-case-service | pass |
| `vt_incident_create` | validation | incident-service | incident-service | pass |
| `vt_dispute_open-case` | validation | dispute-service | dispute-service | pass |
| `ct_documents__export_include-documents` | contract | documents-service | documents-service, export-service | pass |
| `ct_import__protected-vault_write` | contract | import-service | import-service, protected-visibility-vault | pass |
| `ct_protected-vault__import-export_redaction` | contract | protected-visibility-vault | protected-visibility-vault, import-service, export-service | pass |
| `ct_incident__certification_revoke` | contract | incident-service | incident-service, certification-system | pass |
| `ct_case-task__workflow-engine_transition` | contract | case-task-service | case-task-service, workflow-engine | pass |
| `ct_documents__search_index-visible-documents` | contract | documents-service | documents-service, search-service | pass |
| `ct_export__components_enumerate` | contract | export-service | export-service, data-schema-store, provider-transfer-service | pass |
| `ct_facilities__wallet_reservation-payment` | contract | facilities-service | facilities-service, wallet-dues-donations | pass |
| `ct_fraud__dispute_resolution-path` | contract | fraud-signal-service | fraud-signal-service, dispute-service | pass |

## Phase A4b Execution Status

| Test | Type | Owner | Covers | Status |
| --- | --- | --- | --- | --- |
| `vt_wallet_payment` | validation | wallet-dues-donations | wallet-dues-donations, receipt-ledger | pass |
| `vt_wallet_ad-off` | validation | wallet-dues-donations | wallet-dues-donations | pass |
| `vt_wallet_community-ad-off` | validation | wallet-dues-donations | wallet-dues-donations | pass |
| `vt_ad-campaign_setup` | validation | ad-campaign-service | ad-campaign-service | pass |
| `vt_ad-decision_slot-eligibility` | validation | ad-decision-service | ad-decision-service | pass |
| `vt_ad-decision_sensitive-no-fill` | validation | ad-decision-service | ad-decision-service, protected-visibility-vault | pass |
| `vt_ad-decision_ad-off` | validation | ad-decision-service | ad-decision-service, wallet-dues-donations | pass |
| `vt_search_permission-aware` | validation | search-service | search-service, role-policy-consent-engine | pass |
| `vt_search_deindex` | validation | search-service | search-service | pass |
| `vt_ai-gateway_answer` | validation | ai-gateway | ai-gateway, search-service | pass |
| `vt_ai-gateway_source-policy` | validation | ai-gateway | ai-gateway | pass |
| `vt_digest_on-demand` | validation | digest-service | digest-service | pass |
| `vt_settlement_run` | validation | settlement-engine | settlement-engine, receipt-ledger | pass |
| `vt_utility-funding_calculate` | validation | utility-funding-service | utility-funding-service | pass |
| `vt_fraud_create-signal` | validation | fraud-signal-service | fraud-signal-service | pass |
| `ct_wallet__ad-decision_ad-off-entitlement` | contract | wallet-dues-donations | wallet-dues-donations, ad-decision-service | pass |
| `ct_search__ai-gateway_retrieval` | contract | search-service | search-service, ai-gateway | pass |
| `ct_ai-gateway__digest_citations` | contract | ai-gateway | ai-gateway, digest-service | pass |
| `ct_receipt-ledger__settlement_read-window` | contract | receipt-ledger | receipt-ledger, settlement-engine | pass |
| `ct_settlement__utility-funding_allocation` | contract | settlement-engine | settlement-engine, utility-funding-service | pass |
| `ct_fraud__settlement_apply-adjustment` | contract | fraud-signal-service | fraud-signal-service, settlement-engine | pass |
| `ct_ad-decision__app-shell_banner-fill` | contract | ad-decision-service | ad-decision-service, app-shell-runtime | pass |
| `ct_ad-decision__stream-renderer_in-stream-ad` | contract | ad-decision-service | ad-decision-service, stream-renderer | pass |
| `ct_search__app-shell_result-explanations` | contract | search-service | search-service, app-shell-runtime | pass |
| `ct_wallet__payment-surface_checkout` | contract | wallet-dues-donations | wallet-dues-donations, payment-surface | pass |

## Phase A5 Execution Status

| Test | Type | Owner | Covers | Status |
| --- | --- | --- | --- | --- |
| `vt_extension-runtime_session` | validation | extension-runtime-bridge | extension-runtime-bridge, extension-registry, role-policy-consent-engine | pass |
| `vt_extension-runtime_bridge-call` | validation | extension-runtime-bridge | extension-runtime-bridge | pass |
| `vt_extension-runtime_permission` | validation | extension-runtime-bridge | extension-runtime-bridge | pass |
| `vt_rule-engine_evaluate` | validation | rule-engine | rule-engine, event-bus | pass |
| `vt_rule-engine_action` | validation | rule-engine | rule-engine | pass |
| `vt_workflow-engine_start` | validation | workflow-engine | workflow-engine | pass |
| `vt_workflow-engine_transition` | validation | workflow-engine | workflow-engine | pass |
| `vt_job-scheduler_trigger` | validation | job-scheduler | job-scheduler | pass |
| `vt_function-runtime_sandbox-permission` | validation | function-runtime | function-runtime | pass |
| `vt_data-schema_register` | validation | data-schema-store | data-schema-store | pass |
| `vt_data-schema_export-index` | validation | data-schema-store | data-schema-store, export-service, search-service | pass |
| `vt_secrets-connector_scoped-secret` | validation | secrets-connector-broker | secrets-connector-broker | pass |
| `vt_extension-package_downloadable-shape` | validation | extension-package-validator | extension-package-validator | pass |
| `vt_extension-package_asset-manifest` | validation | extension-package-validator | extension-package-validator | pass |
| `vt_extension-package_asset-policy` | validation | extension-package-validator | extension-package-validator | pass |
| `vt_initialization-package_schema` | validation | initialization-package-schema | initialization-package-schema | pass |
| `vt_initialization-package_idempotency` | validation | initialization-package-schema | initialization-package-schema | pass |
| `vt_initialization-package_community-branding` | validation | initialization-package-schema | initialization-package-schema, community-registry | pass |
| `ct_rule-engine__extension-runtime_action-dispatch` | contract | rule-engine | rule-engine, extension-runtime-bridge | pass |
| `ct_job-scheduler__rule-engine_trigger` | contract | job-scheduler | job-scheduler, rule-engine | pass |
| `ct_workflow-engine__case-task_transition` | contract | workflow-engine | workflow-engine, case-task-service | pass |
| `ct_data-schema-store__import-export_schema-enumeration` | contract | data-schema-store | data-schema-store, export-service | pass |
| `ct_data-schema-store__search_indexability` | contract | data-schema-store | data-schema-store, search-service | pass |
| `ct_extension-runtime__protected-vault_write` | contract | extension-runtime-bridge | extension-runtime-bridge, protected-visibility-vault | pass |
| `ct_extension-runtime__app-shell_session` | contract | extension-runtime-bridge | extension-runtime-bridge, app-shell-runtime | pass |
| `ct_extension-package__demo-loader_validate-load` | contract | extension-package-validator | extension-package-validator, loom-communities-demo-app | pass |
| `ct_initialization-package__fake-backend_import` | contract | initialization-package-schema | initialization-package-schema, local-in-app-backend | pass |
| `ct_initialization-package__fake-backend_branding-import` | contract | initialization-package-schema | initialization-package-schema, local-in-app-backend | pass |

## Phase A6 Execution Status

| Test | Type | Owner | Covers | Status |
| --- | --- | --- | --- | --- |
| `vt_app-shell_cards` | validation | app-shell-runtime | app-shell-runtime | pass |
| `vt_app-shell_required-nav` | validation | app-shell-runtime | app-shell-runtime, navigation-panel | pass |
| `vt_app-shell_route-host` | validation | app-shell-runtime | app-shell-runtime | pass |
| `vt_app-shell_ad-slots` | validation | app-shell-runtime | app-shell-runtime, ad-slots | pass |
| `vt_community-card_render-bind` | validation | community-card | community-card | pass |
| `vt_community-card_branding-priority` | validation | community-card | community-card, extension-package-validator, initialization-package-schema | pass |
| `vt_demo-app_card-image-after-load` | validation | loom-communities-demo-app | loom-communities-demo-app, community-card, local-in-app-backend | pass |
| `vt_navigation-panel_messages-connections` | validation | navigation-panel | navigation-panel | pass |
| `vt_stream-renderer_ad-item-disclosure` | validation | stream-renderer | stream-renderer | pass |
| `vt_connections-shell_invite-blocked` | validation | connections-shell | connections-shell | pass |
| `vt_payment-surface_shell-owned` | validation | payment-surface | payment-surface, wallet-dues-donations | pass |
| `vt_data-dashboard_consent-revoke` | validation | data-dashboard-consent | data-dashboard-consent | pass |
| `vt_demo-app_empty-community-state` | validation | loom-communities-demo-app | loom-communities-demo-app | pass |
| `vt_demo-app_add-community-button` | validation | loom-communities-demo-app | loom-communities-demo-app | pass |
| `vt_demo-app_empty-state-cta-loads-community` | validation | loom-communities-demo-app | loom-communities-demo-app, local-in-app-backend, community-card | pass |
| `vt_demo-app_local-file-load-extension` | validation | loom-communities-demo-app | loom-communities-demo-app, extension-package-validator | pass |
| `vt_demo-app_cards-after-load` | validation | loom-communities-demo-app | loom-communities-demo-app, community-card, local-in-app-backend | pass |
| `vt_demo-app_open-local-extension` | validation | loom-communities-demo-app | loom-communities-demo-app | pass |
| `vt_fake-backend_import-init-package` | validation | local-in-app-backend | local-in-app-backend | pass |
| `vt_fake-backend_import-idempotent` | validation | local-in-app-backend | local-in-app-backend | pass |
| `vt_local-store_persist-reload` | validation | local-in-app-backend | local-in-app-backend | pass |
| `ct_app-shell__workflow_install-latest` | contract | app-shell-runtime | app-shell-runtime, workflow-engine | pass |
| `ct_navigation-panel__workflow_messages-connections-reachable` | contract | navigation-panel | navigation-panel | pass |
| `ct_stream-renderer__workflow_in-stream-ad` | contract | stream-renderer | stream-renderer | pass |
| `ct_payment-surface__workflow_ad-off-checkout` | contract | payment-surface | payment-surface, wallet-dues-donations | pass |
| `ct_data-dashboard__workflow_consent-revoke` | contract | data-dashboard-consent | data-dashboard-consent | pass |
| `ct_local-backend__community-card_branding-props` | contract | local-in-app-backend | local-in-app-backend, community-card | pass |
| `ct_extension-runtime__app-shell_local-session` | contract | extension-runtime-bridge | extension-runtime-bridge, app-shell-runtime | pass |

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

## Phase B1a Execution Status

| Test | Type | Owner | Covers | Status |
| --- | --- | --- | --- | --- |
| `vt_skill-prereq_manifest-complete` | validation | skill-prereq-setup | skill-prereq-setup | pass |
| `vt_skill-prereq_host-detection` | validation | skill-prereq-setup | skill-prereq-setup | pass |
| `vt_skill-prereq_install-plan` | validation | skill-prereq-setup | skill-prereq-setup | pass |
| `vt_skill-prereq_environment-lock` | validation | skill-prereq-setup | skill-prereq-setup | pass |
| `vt_skill-prereq_demo-app-smoke` | validation | skill-prereq-setup | skill-prereq-setup, loom-communities-demo-app, local-in-app-backend | pass |
| `ct_skill-prereq-setup__workflow-validation-harness_environment-ready` | contract | skill-prereq-setup | skill-prereq-setup, workflow-validation-harness | pass |
| `vt_skill_skeleton` | validation | ai-skill-extension-builder | ai-skill-extension-builder | pass |
| `vt_skill_debug_golden-flow` | validation | ai-skill-extension-builder | ai-skill-extension-builder | pass |
| `vt_skill-debug-harness_fixture-replay` | validation | skill-debug-harness | skill-debug-harness | pass |
| `vt_skill_generate-downloadable-extension` | validation | ai-skill-extension-builder | ai-skill-extension-builder | pass |
| `vt_skill_generate-initialization-package` | validation | ai-skill-extension-builder | ai-skill-extension-builder | pass |
| `vt_skill_generate-brand-assets` | validation | ai-skill-extension-builder | ai-skill-extension-builder, extension-package-validator, initialization-package-schema | pass |
| `vt_demo-app_local-loader-opens` | validation | loom-communities-demo-app | loom-communities-demo-app | pass |
| `vt_demo-app_local-loader-invalid-extension-error` | validation | loom-communities-demo-app | loom-communities-demo-app, local-in-app-backend | pass |
| `vt_demo-app_local-loader-validates-package-pair` | validation | loom-communities-demo-app | loom-communities-demo-app, local-in-app-backend, community-card | pass |
| `vt_demo-app_duplicate-local-import-status` | validation | loom-communities-demo-app | loom-communities-demo-app, local-in-app-backend, community-card | pass |
| `vt_fake-backend_local-package-pair-validation` | validation | local-in-app-backend | local-in-app-backend | pass |
| `wf_local-demo-prereq-to-validation-ready` | workflow | none | skill-prereq-setup, workflow-validation-harness, loom-communities-demo-app, local-in-app-backend, loom-local-store | pass |
| `wf_local-build-download-sideload-install` | workflow | none | skill-prereq-setup, workflow-validation-harness, ai-skill-extension-builder, extension-package-validator, initialization-package-schema, loom-communities-demo-app, local-in-app-backend, loom-local-store, community-card, app-shell-runtime, extension-runtime-bridge | pass |

## Phase B1b Execution Status

| Test | Type | Owner | Covers | Status |
| --- | --- | --- | --- | --- |
| `vt_ai-skill_generate-package` | validation | ai-skill-extension-builder | ai-skill-extension-builder | pass |
| `wf_build-publish-discover-install` | workflow | none | ai-skill-extension-builder, builder-app-id-service, extension-registry, certification-system, community-registry, app-shell-runtime, loom-communities-demo-app, local-in-app-backend, community-card | pass |

## Phase B2 Execution Status

| Test | Type | Owner | Covers | Status |
| --- | --- | --- | --- | --- |
| `wf_book-club-headline` | workflow | none | community-registry, events-service, forms-voting-service, publishing-service, messaging-stream-service, search-service, ai-gateway, digest-service, app-shell-runtime, loom-communities-demo-app, local-in-app-backend, community-card | pass |

## Phase B3 Execution Status

| Test | Type | Owner | Covers | Status |
| --- | --- | --- | --- | --- |
| `wf_youth-soccer-headline` | workflow | none | membership-service, spaces-service, protected-visibility-vault, wallet-dues-donations, events-service, notification-service, app-shell-runtime, community-registry, loom-communities-demo-app, local-in-app-backend, community-card | pass |

## Phase B4 Execution Status

| Test | Type | Owner | Covers | Status |
| --- | --- | --- | --- | --- |
| `wf_hoa-headline` | workflow | none | workflow-validation-harness, wallet-dues-donations, documents-service, facilities-service, case-task-service, workflow-engine, export-service, notification-service, receipt-ledger, app-shell-runtime, loom-communities-demo-app, local-in-app-backend, community-card | pass |

## Phase B5 Execution Status

| Test | Type | Owner | Covers | Status |
| --- | --- | --- | --- | --- |
| `wf_mosque-headline` | workflow | none | workflow-validation-harness, publishing-service, wallet-dues-donations, events-service, forms-voting-service, core-member-vault, protected-visibility-vault, notification-service, search-service, ai-gateway, app-shell-runtime, loom-communities-demo-app, local-in-app-backend, community-card | pass |

## Phase B6 Execution Status

| Test | Type | Owner | Covers | Status |
| --- | --- | --- | --- | --- |
| `wf_messaging-ads-connections` | workflow | none | workflow-validation-harness, messaging-stream-service, connections-graph, ad-campaign-service, ad-decision-service, stream-renderer, navigation-panel, connections-shell, ad-slots, protected-visibility-vault, app-shell-runtime, loom-communities-demo-app, local-in-app-backend, community-card | pass |

## Phase B7 Execution Status

| Test | Type | Owner | Covers | Status |
| --- | --- | --- | --- | --- |
| `vt_wallet_community-ad-off` | validation | wallet-dues-donations | wallet-dues-donations | pass |
| `vt_ad-decision_ad-off` | validation | ad-decision-service | ad-decision-service, wallet-dues-donations | pass |
| `wf_ad-off` | workflow | none | workflow-validation-harness, wallet-dues-donations, ad-decision-service, ad-campaign-service, receipt-ledger, settlement-engine, utility-funding-service, payment-surface, ad-slots, protected-visibility-vault, app-shell-runtime, loom-communities-demo-app, local-in-app-backend, community-card | pass |

## Phase B8 Execution Status

| Test | Type | Owner | Covers | Status |
| --- | --- | --- | --- | --- |
| `vt_api_specs_complete` | validation | api-spec-inventory | api-spec-inventory | pass |
| `vt_provider-transfer_rollback` | validation | provider-transfer-service | provider-transfer-service | pass |
| `wf_export-migration` | workflow | none | workflow-validation-harness, export-service, import-service, provider-transfer-service, protected-visibility-vault, data-schema-store, receipt-ledger, wallet-dues-donations, documents-service, app-shell-runtime, loom-communities-demo-app, local-in-app-backend, community-card | pass |

## Required B1a Local Flow Coverage

| Capability | Test IDs |
| --- | --- |
| Skill validation environment | `vt_skill-prereq_manifest-complete`, `vt_skill-prereq_host-detection`, `vt_skill-prereq_install-plan`, `vt_skill-prereq_environment-lock`, `vt_skill-prereq_demo-app-smoke`, `ct_skill-prereq-setup__workflow-validation-harness_environment-ready`, `wf_local-demo-prereq-to-validation-ready` |
| Empty app and Add Community | `vt_demo-app_empty-community-state`, `vt_demo-app_add-community-button`, `vt_demo-app_empty-state-cta-loads-community` |
| Skill local artifacts | `vt_skill_generate-downloadable-extension`, `vt_skill_generate-initialization-package`, `vt_skill_generate-brand-assets`, `vt_skill_debug_golden-flow` |
| Package validation and local load | `vt_extension-package_downloadable-shape`, `vt_extension-package_asset-manifest`, `vt_extension-package_asset-policy`, `vt_demo-app_local-file-load-extension`, `vt_demo-app_local-loader-opens`, `vt_demo-app_local-loader-invalid-extension-error`, `vt_demo-app_local-loader-validates-package-pair`, `vt_fake-backend_local-package-pair-validation`, `ct_extension-package__demo-loader_validate-load` |
| Initialization import | `vt_initialization-package_schema`, `vt_initialization-package_idempotency`, `vt_initialization-package_community-branding`, `vt_fake-backend_import-init-package`, `vt_fake-backend_import-idempotent`, `vt_demo-app_duplicate-local-import-status`, `ct_initialization-package__fake-backend_import`, `ct_initialization-package__fake-backend_branding-import` |
| Local persistence, branded card, and open | `vt_local-store_persist-reload`, `vt_demo-app_cards-after-load`, `vt_demo-app_card-image-after-load`, `vt_community-card_branding-priority`, `vt_demo-app_open-local-extension`, `ct_local-backend__community-card_branding-props`, `ct_extension-runtime__app-shell_local-session` |
| End to end | `wf_local-build-download-sideload-install` |

## Manifest Rules

- A `pass` result is valid only for the recorded component version hashes and test hash.
- Any component hash change makes tests covering that component `stale`.
- Any test file hash change makes that test `stale`.
- `pending-counterpart` is allowed only when a provider or consumer component does not exist yet.
