# Phase A1 - Foundation Components

Layer: foundation
Components: Passport Ledger, Role/Policy/Consent Engine, Core Member Vault, Protected-Visibility
Vault, Connections Graph, Receipt Ledger, Audit Ledger, Event Bus, Key Management, Builder App ID
Service.
Depends on: Phase 0
Parallelism: one agent per component
Gate: all A1 validation and built-counterpart contract tests pass

## 0. Prerequisite Gate

- Phase 0 complete and recorded in [../Build Tracker.md](../Build%20Tracker.md).
- Manifest parses and gate script reports no unexpected stale/failed required tests.
- Workspace boots and boundary lints run.
- Component cards are available from Architecture V2 docs 03, 04, 05, 06, 07, 08, and 11.

## 1. Components in This Phase

| Component | Architecture card source | Contract |
| --- | --- | --- |
| passport-ledger | [Arch 03](../../Architecture%20V2/03-identity-member-data-wallets-and-app-shell.md) | `CommunityPassportApi` |
| role-policy-consent-engine | [Arch 04](../../Architecture%20V2/04-community-spaces-membership-and-roles.md) | `CommunityRolePolicyApi` |
| core-member-vault | [Arch 03](../../Architecture%20V2/03-identity-member-data-wallets-and-app-shell.md) | `CommunityCoreVaultApi` |
| protected-visibility-vault | [Arch 03](../../Architecture%20V2/03-identity-member-data-wallets-and-app-shell.md) | `CommunityProtectedVaultApi` |
| connections-graph | [Arch 07](../../Architecture%20V2/07-search-discovery-connections-and-ai.md) | `CommunityConnectionsApi` |
| receipt-ledger | [Arch 05](../../Architecture%20V2/05-content-publishing-payments-ads-and-settlement.md) | `CommunityReceiptLedgerApi` |
| audit-ledger | [Arch 00](../../Architecture%20V2/00-system-design-tenets.md) | `CommunityAuditApi` |
| event-bus | [Arch 08](../../Architecture%20V2/08-extension-platform-runtime.md) | `CommunityEventBusApi` |
| key-management | [Arch 06](../../Architecture%20V2/06-extension-certification-governance-and-builder-supply-chain.md) | `CommunityKeyManagementApi` |
| builder-app-id-service | [Arch 06](../../Architecture%20V2/06-extension-certification-governance-and-builder-supply-chain.md) | `CommunityBuilderAppIdApi` |

## 2. Agent Assignment and Parallelism

Start one worktree-isolated agent per component. Each agent owns:

- Contract file.
- Fake implementation.
- Owned local-store tables.
- Seed fixtures.
- Validation tests.
- Provider-authored consumer-contract tests.
- Skill component guide.

Merge order is serialized by dependency weight: Audit/Keys -> Passport -> Policy -> Vaults ->
Connections -> Receipts -> Event Bus -> Builder App ID.

## 3. Per-Component Build Spec

For each component:

- Implement `Community*Api` in `loom_api_contracts`.
- Add fake in `loom_fake_backend`.
- Add owned tables in `loom_local_store`.
- Add seed fixtures in `loom_seed_data`.
- Ensure mutations are idempotent and audited.
- Expose only contract/fake dependencies.

Owned data must be disjoint. If an agent needs to write another component's data directly, stop and
revise the card.

## 4. Basic Validation Tests

Required examples:

| Test | Component |
| --- | --- |
| `vt_passport-ledger_create-resolve` | passport-ledger |
| `vt_role-policy_effective-permission` | role-policy-consent-engine |
| `vt_core-vault_preferences` | core-member-vault |
| `vt_protected-vault_read-gated` | protected-visibility-vault |
| `vt_connections_invite-permission` | connections-graph |
| `vt_receipt-ledger_append` | receipt-ledger |
| `vt_event-bus_publish` | event-bus |
| `vt_builder-app-id_signing-scope` | builder-app-id-service |

Each component also adds a contract-conformance suite.

## 5. Consumer-Contract Tests Authored for Dependents

Provider agents author these tests and register them in the manifest:

- `ct_role-policy__extension-runtime_effective-permission`
- `ct_protected-vault__ads_no-fill-sensitive`
- `ct_receipt-ledger__wallet_append-payment`
- `ct_event-bus__rule-engine_publish-replay`
- `ct_connections__invitation_blocked-path`
- `ct_builder-app-id__extension-registry_signing-scope`

Most are `pending-counterpart` until later phases build the consumers.

## 6. Cross-Component Test Gate

Run:

- All A1 `vt_` tests.
- All contract tests where both provider and consumer exist.
- All altered integration tests touching A1 components.
- Manifest gate.

Pending counterpart tests remain pending only if the counterpart phase has not executed.

## 7. Tenet-Adherence Checks

Verify T1-T9 explicitly:

- Owned tables are disjoint.
- Dependencies are contracts and fakes.
- No upward synchronous calls.
- Events are typed.
- Idempotency, versioning, and audit are present.

UX tenet T10 is only referenced where App Shell consumers are pending.

## 8. Skill Contribution

Add:

- `Skill/components/passport-ledger.md`
- `Skill/components/role-policy-consent-engine.md`
- `Skill/components/core-member-vault.md`
- `Skill/components/protected-visibility-vault.md`
- `Skill/components/connections-graph.md`
- `Skill/components/receipt-ledger.md`
- `Skill/components/audit-ledger.md`
- `Skill/components/event-bus.md`
- `Skill/components/key-management.md`
- `Skill/components/builder-app-id-service.md`

Each guide explains how an extension safely uses the component through Loom APIs.

## 9. Manifest Update

Stamp all passed tests with:

- Current component version hashes.
- Current test hashes.
- `lastRunAt`.
- `pass`, `fail`, or `pending-counterpart`.

## 10. API Review

Create `Phase A1 - API Review.md`. Log OpenAPI additions/renames for identity, vault, policy, receipt,
audit, event, key, and builder App ID APIs.

## 11. Definition of Done

All required A1 gates pass, Skill guides are present, manifest is current, API Review is filed, tracker
is updated with component hashes and commit SHA.

## 12. Next Phase

Proceed to [Phase A2 - Registry and Control-Plane Components.md](./Phase%20A2%20-%20Registry%20and%20Control-Plane%20Components.md).
