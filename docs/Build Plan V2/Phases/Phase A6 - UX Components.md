# Phase A6 - UX Components

Layer: UX
Components: App Shell Runtime, Community Card, Navigation Panel, Stream Renderer, Connections Shell,
Ad Slots, Payment Surface, Data Dashboard/Consent Prompt.
Depends on: A5
Parallelism: one agent per UX micro-component
Gate: UX validation, visual/interaction tests, and contract tests pass

## 0. Prerequisite Gate

- A5 complete and committed.
- All component tests for dependencies are current.
- App Shell dependencies have fakes.
- UI test harness and emulator/screenshot path are ready.

## 1. Components in This Phase

| Component | Architecture source | Contract |
| --- | --- | --- |
| app-shell-runtime | [Arch 03](../../Architecture%20V2/03-identity-member-data-wallets-and-app-shell.md) | `CommunityAppShellApi` |
| community-card | [Arch 00](../../Architecture%20V2/00-system-design-tenets.md#7-ux-micro-component-rules-t10) | `CommunityCardProps` |
| navigation-panel | [Arch 00](../../Architecture%20V2/00-system-design-tenets.md#7-ux-micro-component-rules-t10) | `NavigationPanelProps` |
| stream-renderer | [Arch 00](../../Architecture%20V2/00-system-design-tenets.md#7-ux-micro-component-rules-t10) | `StreamRendererProps` |
| connections-shell | [Arch 00](../../Architecture%20V2/00-system-design-tenets.md#7-ux-micro-component-rules-t10) | `ConnectionsShellProps` |
| ad-slots | [Arch 00](../../Architecture%20V2/00-system-design-tenets.md#7-ux-micro-component-rules-t10) | `AdSlotProps` |
| payment-surface | [Arch 00](../../Architecture%20V2/00-system-design-tenets.md#7-ux-micro-component-rules-t10) | `PaymentSurfaceProps` |
| data-dashboard-consent | [Arch 03](../../Architecture%20V2/03-identity-member-data-wallets-and-app-shell.md) | `DataDashboardProps` |

## 2. Agent Assignment and Parallelism

Run one agent per micro-component. Merge order:

1. App Shell Runtime.
2. Community Card.
3. Navigation Panel.
4. Stream Renderer.
5. Ad Slots.
6. Payment Surface.
7. Connections Shell.
8. Data Dashboard/Consent Prompt.

## 3. Per-Component Build Spec

Each UI component owns typed props/state, interaction behavior, accessibility, visual tests, and
contract tests against dependency fakes. UI components do not import fakes or storage directly.

## 4. Basic Validation Tests

Required:

- `vt_app-shell_cards`
- `vt_app-shell_required-nav`
- `vt_app-shell_route-host`
- `vt_app-shell_ad-slots`
- `vt_community-card_render-bind`
- `vt_navigation-panel_messages-connections`
- `vt_stream-renderer_ad-item-disclosure`
- `vt_connections-shell_invite-blocked`
- `vt_payment-surface_shell-owned`
- `vt_data-dashboard_consent-revoke`

## 5. Consumer-Contract Tests Authored for Dependents

UX components publish tests that workflow phases will reuse:

- `ct_app-shell__workflow_install-latest`
- `ct_navigation-panel__workflow_messages-connections-reachable`
- `ct_stream-renderer__workflow_in-stream-ad`
- `ct_payment-surface__workflow_ad-off-checkout`
- `ct_data-dashboard__workflow_consent-revoke`

## 6. Cross-Component Test Gate

Run A6 validation tests, all App Shell contract tests from A2/A4b/A5 providers, visual/interaction
tests, manifest gate, and full component test suite.

## 7. Tenet-Adherence Checks

Verify T10:

- Top ad banner exists unless valid ad-off or sensitive no-fill.
- Stream renderer can render `kind: ad`.
- Nav panel always exposes Messages and Connections.
- Payment surface is Loom-owned.
- Extensions mount inside App Shell, not around it.

## 8. Skill Contribution

Add guides for App Shell, community cards, nav panel, stream renderer, connections shell, ad slots,
payment surface, and data dashboard. Include examples of extension UI fragments that preserve shell
invariants.

## 9. Manifest Update

Stamp A6 tests and resolve all pending Set A contract tests whose consumers now exist.

## 10. API Review

Create `Phase A6 - API Review.md`. Record App Shell, UI props, surface, ad slot, payment surface, and
data-dashboard contract gaps.

## 11. UX Decisions

Create `Phase A6 - UX Decisions.md`. Include reference research, interaction decisions, visual
component rules, accessibility, empty/loading/error states, and screenshot validation.

## 12. Definition of Done

All Set A component tests pass, manifest is current, Skill guides are added, API Review and UX
Decisions are filed, tracker records hashes and commit SHA.

## 13. Next Phase

Proceed to [Phase B1 - Build Publish Discover Install.md](./Phase%20B1%20-%20Build%20Publish%20Discover%20Install.md).
