# Loom Communities V2 Test Manifest

Status: Generated human view seed
Machine source: [test-manifest.json](./test-manifest.json)

This file is the human-readable view of the machine manifest. During execution it should be generated
from `test-manifest.json`, not hand-maintained.

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

## Set A - Component Phases

| Phase | Component group | Required examples |
| --- | --- | --- |
| A1 | Foundation | `vt_passport-ledger_create-resolve`, `vt_role-policy_effective-permission`, `vt_event-bus_publish`, `vt_receipt-ledger_append` |
| A2 | Registry/control-plane | `vt_community-registry_discovery`, `vt_spaces_nesting`, `vt_extension-registry_resolve-latest`, `vt_certification_validate-package` |
| A3 | Experience services | `vt_publishing_publish`, `vt_messaging_stream-render`, `vt_events_rsvp`, `vt_forms-voting_submit` |
| A4a | Ops/community services | `vt_case-task_transition`, `vt_documents_permissions`, `vt_facilities_reservation`, `vt_export_redaction`, `vt_moderation_case-lifecycle` |
| A4b | Economic/search/ads | `vt_wallet_payment`, `vt_ad-decision_sensitive-no-fill`, `vt_search_permission-aware`, `vt_ai-gateway_answer`, `vt_settlement_run` |
| A5 | Extension engines | `vt_extension-runtime_session`, `vt_rule-engine_evaluate`, `vt_workflow-engine_transition`, `vt_data-schema_export-index` |
| A6 | UX micro-components | `vt_app-shell_required-nav`, `vt_app-shell_ad-slots`, `vt_payment-surface_shell-owned`, `vt_connections-shell_invite-blocked` |

## Set B - Workflow Phases

| Phase | Workflow test | Covered workflow |
| --- | --- | --- |
| B1 | `wf_build-publish-discover-install` | Skill build -> publish -> certify -> QR/handle -> install -> latest open |
| B2 | `wf_book-club-headline` | Book nominate/vote/event/discussion/digest |
| B3 | `wf_youth-soccer-headline` | Parent join, minor protected data, payment, roster, schedule |
| B4 | `wf_hoa-headline` | Dues, documents, facility, architectural request, export |
| B5 | `wf_mosque-headline` | Donations, events, volunteers, care request |
| B6 | `wf_messaging-ads-connections` | Required nav, messaging, connections, in-stream ads |
| B7 | `wf_ad-off` | Member/community ad-off, ad suppression, settlement |
| B8 | `wf_export-migration` | Community export, protected redaction, provider transfer |

## Manifest Rules

- A `pass` result is valid only for the recorded component version hashes and test hash.
- Any component hash change makes tests covering that component `stale`.
- Any test file hash change makes that test `stale`.
- `pending-counterpart` is allowed only when a provider or consumer component does not exist yet.
