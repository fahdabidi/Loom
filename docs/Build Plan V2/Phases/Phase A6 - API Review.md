# Phase A6 - API Review

Status: Completed in A6

## Scope

UX micro-component contracts: App Shell, community card, nav panel, stream renderer, connections shell,
ad slots, payment surface, data dashboard/consent, Loom Communities Demo App, and local in-app backend
adapter.

## Review Checklist

- Required nav entries.
- App Shell latest-version route behavior.
- Community-card branding props: display name, tagline, logo, card image, hero image, category, accent
  color, alt/decorative metadata, and fallback state.
- Stream item rendering contracts.
- Ad slot fill/no-fill contracts.
- Payment surface and consent prompt ownership.
- Accessibility and visual test hooks.
- Demo App empty-state and `Add Community` command.
- Local file loader contract for extension packages and initialization packages.
- Local asset cache and card-image loading behavior.
- Local fake-backend import/reset/reload APIs.
- Stubbed API behavior when no hosted backend is present.

## OpenAPI Outputs

Record App Shell, UI, local-loader, and local fake-backend contract gaps.

## A6 Contract Additions

- `CommunityAppShellRuntime`
- `CommunityCardProps`
- `NavigationPanelProps`
- `StreamItemProps`
- `ConnectionsShellProps`
- `AdSlotProps`
- `PaymentSurfaceProps`
- `DataDashboardProps`
- `LocalInAppBackend`

These contracts are currently implemented in `app/packages/core/loom_app_shell` and
`app/packages/core/loom_demo_local_backend`. The Demo App is implemented in
`app/apps/loom_communities_demo`.

## Local Demo Contract

- The Demo App starts with no communities.
- `Add Community` is visible and enabled in the empty state.
- The local backend can load an extension package summary and import an initialization package summary.
- Initialization import is idempotent.
- Local backend snapshots can be reloaded.
- Community-card branding props include logo, card image, hero image, accent color, and fallback data.

## OpenAPI Follow-Ups

- Promote the local backend package/import contracts into JSON Schema for B1a package generation.
- Replace the sample Add Community action with emulator-safe local file picking in B1a.
- Add visual screenshots once the B1a workflow packages are generated.

## Validation Evidence

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

## WSL Ubuntu Tooling Requirement

Run all phase tooling from WSL Ubuntu, not Windows PowerShell. Use this command shape from the Windows host:

```powershell
wsl.exe -d Ubuntu -- bash -lc 'cd "/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app" && <command>'
```

Inside WSL Ubuntu, `dart`, `flutter`, and `melos` must resolve from the Ubuntu toolchain. Do not run Dart, Flutter, Melos, package validation, manifest gates, phase gates, or workflow tests from Windows-native shells.

## Commit Gate

Before starting the next phase:

- Stage only this phase's intended changes.
- Run `git diff --staged` and confirm the staged scope matches this phase.
- Commit the phase changes.
- Record the resulting commit SHA in [../Build Tracker.md](../Build%20Tracker.md).
- Do not begin the next phase until the commit exists and the tracker points to it.
