# Phase A2 - Registry and Control-Plane Components

Layer: registry/control-plane
Components: Community Registry, Spaces Service, Membership Service, Invitation Service, Extension
Registry, Certification System, Public Registry Read Model, Workflow Inventory Registry, Phase/Test
Manifest Bridge.
Depends on: A1
Parallelism: one agent per component
Gate: all tests touching A2 components pass against built A1 providers

## 0. Prerequisite Gate

- A1 complete and recorded.
- A1 required tests pass and are not stale.
- Contract fakes for A1 components are available.
- Manifest has no stale required A1 tests.

## 1. Components in This Phase

| Component | Architecture source | Contract |
| --- | --- | --- |
| workflow-inventory-registry | [Arch 02](../../Architecture%20V2/02-workflow-inventory-and-function-map.md) | `CommunityWorkflowInventoryApi` |
| phase-test-manifest-bridge | [Arch 02](../../Architecture%20V2/02-workflow-inventory-and-function-map.md) | `CommunityTestManifestApi` |
| community-registry | [Arch 04](../../Architecture%20V2/04-community-spaces-membership-and-roles.md) | `CommunityRegistryApi` |
| spaces-service | [Arch 04](../../Architecture%20V2/04-community-spaces-membership-and-roles.md) | `CommunitySpacesApi` |
| membership-service | [Arch 04](../../Architecture%20V2/04-community-spaces-membership-and-roles.md) | `CommunityMembershipApi` |
| invitation-service | [Arch 04](../../Architecture%20V2/04-community-spaces-membership-and-roles.md) | `CommunityInvitationApi` |
| extension-registry | [Arch 06](../../Architecture%20V2/06-extension-certification-governance-and-builder-supply-chain.md) | `CommunityExtensionRegistryApi` |
| certification-system | [Arch 06](../../Architecture%20V2/06-extension-certification-governance-and-builder-supply-chain.md) | `CommunityCertificationApi` |
| public-registry-read-model | [Arch 06](../../Architecture%20V2/06-extension-certification-governance-and-builder-supply-chain.md) | `CommunityPublicRegistryApi` |

## 2. Agent Assignment and Parallelism

Run one agent per component. Merge in this order:

1. Workflow inventory and manifest bridge.
2. Community registry.
3. Spaces and membership.
4. Invitation.
5. Certification.
6. Extension registry.
7. Public registry read model.

## 3. Per-Component Build Spec

Each component implements its contract, fake, owned tables, seed fixtures, and tests. Registry
components may consume A1 foundation fakes only. They must not call service or UX components
synchronously.

## 4. Basic Validation Tests

Required examples:

- `vt_workflow-inventory_test-index`
- `vt_test-manifest_staleness`
- `vt_community-registry_discovery`
- `vt_spaces_nesting`
- `vt_membership_join-approval`
- `vt_invitation_create-revoke`
- `vt_extension-registry_resolve-latest`
- `vt_certification_validate-package`
- `vt_public-registry_status`

## 5. Consumer-Contract Tests Authored for Dependents

Author and register:

- `ct_community-registry__app-shell_resolve-by-qr`
- `ct_community-registry__extension-registry_installed-pointers`
- `ct_spaces__membership_space-join`
- `ct_membership__app-shell_member-state`
- `ct_invitation__membership_accept`
- `ct_extension-registry__app-shell_resolve-latest`
- `ct_certification__extension-registry_certify-package`
- `ct_public-registry__app-shell_trust-state`

Tests targeting A5/A6 consumers remain `pending-counterpart` until those phases.

## 6. Cross-Component Test Gate

Run all A2 validation tests, all A1 provider contract tests consumed by A2, all A2 provider tests with
built consumers, and manifest gate. Rerun A1 tests touched by contract changes.

## 7. Tenet-Adherence Checks

Verify registry components call only foundation contracts/fakes synchronously. Extension registry must
not inspect artifact internals beyond contract metadata. Certification owns decisions; public registry
owns projections only.

## 8. Skill Contribution

Add component guides for all A2 components. Each guide must show how an extension builder discovers,
installs, certifies, or references community/space/membership state without bypassing contracts.

## 9. Manifest Update

Refresh statuses, component hashes, test hashes, and pending counterpart states. Resolve any A1
contract tests unblocked by A2.

## 10. API Review

Create `Phase A2 - API Review.md`. Record OpenAPI specs for registry, spaces, membership, invitation,
extension registry, certification, public registry, and manifest APIs.

## 11. Definition of Done

All A2 tests and affected A1 regressions pass; Skill guides, manifest, API Review, tracker, and commit
SHA are complete.

## 12. Next Phase

Proceed to [Phase A3 - Service Components I (Experience Core).md](./Phase%20A3%20-%20Service%20Components%20I%20%28Experience%20Core%29.md).
