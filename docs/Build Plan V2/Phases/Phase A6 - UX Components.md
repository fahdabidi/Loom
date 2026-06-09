# Phase A6 - UX Components

Layer: UX
Components: App Shell Runtime, Community Card, Navigation Panel, Stream Renderer, Connections Shell,
Ad Slots, Payment Surface, Data Dashboard/Consent Prompt, Loom Communities Demo App, Local In-App
Backend Adapter.
Depends on: A5
Parallelism: one agent per UX micro-component
Gate: UX validation, visual/interaction tests, and contract tests pass

## WSL Ubuntu Tooling Requirement

Run all phase tooling from WSL Ubuntu, not Windows PowerShell. Use this command shape from the Windows host:

```powershell
wsl.exe -d Ubuntu -- bash -lc 'cd "/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app" && <command>'
```

Inside WSL Ubuntu, `dart`, `flutter`, and `melos` must resolve from the Ubuntu toolchain. Do not run Dart, Flutter, Melos, package validation, manifest gates, phase gates, or workflow tests from Windows-native shells.

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
| loom-communities-demo-app | [Arch 12](../../Architecture%20V2/12-mvp-prototype-transaction-slices.md) | `LoomCommunitiesDemoApp` |
| local-in-app-backend | [Arch 12](../../Architecture%20V2/12-mvp-prototype-transaction-slices.md) | `LocalLoomBackendApi` |

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
9. Local In-App Backend Adapter.
10. Loom Communities Demo App.

## 3. Per-Component Build Spec

Each UI component owns typed props/state, interaction behavior, accessibility, visual tests, and
contract tests against dependency fakes. UI components do not import fakes or storage directly.
The Demo App owns the local developer shell, empty-state behavior, `Add Community` action, local file
loader, and emulator-safe test hooks. The Local In-App Backend Adapter owns fake API routing to
`loom_local_store`, import/reset/reload operations, and stubbed network calls.

## 4. Basic Validation Tests

Required:

- `vt_app-shell_cards`
- `vt_app-shell_required-nav`
- `vt_app-shell_route-host`
- `vt_app-shell_ad-slots`
- `vt_community-card_render-bind`
- `vt_community-card_branding-priority`
- `vt_demo-app_card-image-after-load`
- `vt_navigation-panel_messages-connections`
- `vt_stream-renderer_ad-item-disclosure`
- `vt_connections-shell_invite-blocked`
- `vt_payment-surface_shell-owned`
- `vt_data-dashboard_consent-revoke`
- `vt_demo-app_empty-community-state`
- `vt_demo-app_add-community-button`
- `vt_demo-app_local-file-load-extension`
- `vt_demo-app_cards-after-load`
- `vt_demo-app_open-local-extension`
- `vt_fake-backend_import-init-package`
- `vt_fake-backend_import-idempotent`
- `vt_local-store_persist-reload`

## 5. Consumer-Contract Tests Authored for Dependents

UX components publish tests that workflow phases will reuse:

- `ct_app-shell__workflow_install-latest`
- `ct_navigation-panel__workflow_messages-connections-reachable`
- `ct_stream-renderer__workflow_in-stream-ad`
- `ct_payment-surface__workflow_ad-off-checkout`
- `ct_data-dashboard__workflow_consent-revoke`
- `ct_extension-package__demo-loader_validate-load`
- `ct_initialization-package__fake-backend_import`
- `ct_initialization-package__fake-backend_branding-import`
- `ct_local-backend__community-card_branding-props`
- `ct_extension-runtime__app-shell_local-session`

## 6. Cross-Component Test Gate

Run A6 validation tests, all App Shell contract tests from A2/A4b/A5 providers, Demo App local-backend
adapter tests, visual/interaction tests, manifest gate, and full component test suite.

## 7. Tenet-Adherence Checks

Verify T10:

- Top ad banner exists unless valid ad-off or sensitive no-fill.
- Stream renderer can render `kind: ad`.
- Nav panel always exposes Messages and Connections.
- Payment surface is Loom-owned.
- Extensions mount inside App Shell, not around it.
- The Demo App starts with no communities unless seed data is explicitly loaded.
- `Add Community` is visible and reachable in the empty state.
- Local file loading is limited to extension and initialization package formats accepted by A5.
- Community cards are rendered by the App Shell from typed branding props, not arbitrary extension UI.
- Card image priority is community card image -> community logo -> extension default card image ->
  generated initials/category/accent-color fallback.

## 8. Skill Contribution

Add guides for App Shell, community cards, nav panel, stream renderer, connections shell, ad slots,
payment surface, data dashboard, Demo App sideloading, and the local in-app backend. Include examples
of extension UI fragments that preserve shell invariants, branded community-card rendering, asset
fallback behavior, and an example local initialization package import.

## 9. Manifest Update

Stamp A6 tests and resolve all pending Set A contract tests whose consumers now exist.

## 10. API Review

Create `Phase A6 - API Review.md`. Record App Shell, UI props, surface, ad slot, payment surface,
data-dashboard, Demo App local loader, local fake-backend, local DB import/reset, and stubbed API
contract gaps. Include community-card branding props and local asset cache behavior.

## 11. UX Decisions

Create `Phase A6 - UX Decisions.md`. Include reference research, interaction decisions, visual
component rules, accessibility, card/logo/image fallback states, empty/loading/error states, and
screenshot validation.

## 12. Definition of Done

All Set A component tests pass, manifest is current, Skill guides are added, API Review and UX
Decisions are filed, tracker records hashes and commit SHA.

## Commit Gate

Before starting the next phase:

- Stage only this phase's intended changes.
- Run `git diff --staged` and confirm the staged scope matches this phase.
- Commit the phase changes.
- Record the resulting commit SHA in [../Build Tracker.md](../Build%20Tracker.md).
- Do not begin the next phase until the commit exists and the tracker points to it.

## 13. Next Phase

Proceed to [Phase B1a - Local Build Download Sideload Install.md](./Phase%20B1a%20-%20Local%20Build%20Download%20Sideload%20Install.md).
