# Phase A6 - UX Decisions

Status: Complete - R20 second-pass UX decisions applied

Purpose: document the UX research, extracted patterns, decisions, implementation impacts, workflow walkthrough, and open tradeoffs for App Shell and UX micro-components: community cards, nav panel, stream renderer, connections shell, ad slots, payment surface, data dashboard, Demo App empty state, local loader, and local backend import surfaces. This file is a phase gate artifact, not a placeholder.

## Reference Sources Reviewed

| Reference | Surface / Flow Reviewed | Why It Applies | Patterns Observed | Applicability / Gaps | Date Reviewed |
| --- | --- | --- | --- | --- | --- |
| [Material Design 3 - Navigation drawer](https://m3.material.io/components/navigation-drawer/overview) | App shell navigation and persistent destinations. | Loom requires Messages and Connections to stay reachable across extensions. | Navigation should expose stable destinations, current location, and predictable destination switching. | Loom uses a required nav panel contract rather than allowing extension-owned navigation. | 2026-06-09 |
| [Material Design 3 - Cards](https://m3.material.io/components/cards/guidelines) | Community card structure, scanability, and action affordance. | Installed communities are represented as cards in the Demo App and App Shell. | Cards should present one topic, be easy to scan, and bind content/actions clearly. | Loom cards are shell-rendered from typed branding props; extension UI cannot replace them. | 2026-06-09 |
| [NN/g - Empty-state interface design](https://www.nngroup.com/articles/empty-state-interface-design/) | Empty community state and first install path. | A new Demo App starts with no communities. | Empty states should communicate status, teach the next step, and provide a direct task path. | The shell needs both a global Add Community action and an empty-state CTA. | 2026-06-09 |
| [file_picker package](https://pub.dev/packages/file_picker) | Local file selection for extension and initialization packages. | Local-demo mode loads packages from the emulator or local file system. | Native file pickers support extension filtering and local path/file metadata. | A6 keeps a deterministic sample loader; B1a expands this into package validation and error recovery. | 2026-06-09 |
| [Google AdMob native ad display](https://developers.google.com/admob/android/native/advanced) and [native ads playbook](https://admob.google.com/home/resources/native-ads-playbook/) | Top ad slot and in-stream ad disclosure. | Loom requires shell ad surfaces and stream ad items. | Ads need clear attribution/disclosure and must not masquerade as organic content. | Loom uses a shell-owned `Sponsored` disclosure and required ad slot props; real network policy handling stays behind ad components. | 2026-06-09 |
| [Stripe PaymentSheet](https://docs.stripe.com/payments/mobile/payment-sheet) | Payment surface ownership and checkout placement. | Loom-owned payments must not be implemented inside extension UI. | Payment collection is safest when surfaced through a trusted shell-owned component. | A6 validates ownership and amount binding; B7 validates ad-off purchase flow. | 2026-06-09 |
| [Apple Privacy Control](https://www.apple.com/privacy/control/) and [Google Play Data safety](https://support.google.com/googleplay/android-developer/answer/10787469?hl=en) | Data dashboard and consent transparency. | Loom exposes consent, protected vault, and data rights surfaces. | Users need readable summaries of data use and controls before/after install. | A6 covers consent revoke props; later workflow phases add richer data-rights flows. | 2026-06-09 |

## UX Patterns Extracted

| Pattern | Source References | User Problem Solved | Loom Application | Risk / Constraint |
| --- | --- | --- | --- | --- |
| Stable shell destinations | Material navigation | Members lose trust if extension screens hide core platform actions. | `NavigationPanelProps` always includes Messages and Connections; shell owns the top banner. | Extensions must not redefine shell navigation. |
| Shell-rendered cards | Material cards | Users need a consistent installed-community inventory. | Community cards bind display name, tagline, image, accent, and alt text from typed branding props. | Branded assets can be missing, so image fallback order must be deterministic. |
| Empty state with direct action | NN/g empty states | First-run users need to know whether the app is broken or just empty. | Empty state states that no communities are installed and includes a working Add Community CTA. | Duplicate Add Community entry points must execute the same loader. |
| Local picker plus validation | file_picker | Local sideloading can fail because files are missing, wrong type, or mismatched. | A6 uses deterministic sample load; B1a validates extension/init package pair and error states. | Native picker behavior differs by platform and emulator. |
| Ad disclosure and required surfaces | Google AdMob references | Users must distinguish sponsor content from community content. | `renderAdStreamItem` returns `kind: ad` with `Sponsored`; shell top ad slot is required. | Ad-off and sensitive no-fill rules must be handled without removing the reserved surface. |
| Trusted shell-owned payments | Stripe PaymentSheet | Payment trust drops when checkout appears inside arbitrary extension UI. | `PaymentSurfaceProps.shellOwned` is required for checkout surfaces. | Rich payment confirmation and receipt UX is deferred to B7. |
| Data use transparency and control | Apple privacy and Google Play Data safety | Members need visible control over consent and data use. | Data dashboard props expose revocation state. | Full deletion/export flows are covered later. |

## Key UX Decisions

List the UX decisions that must be reflected in implementation. Each decision must trace to either a reference pattern, a Loom platform invariant, or a workflow requirement.

| Decision | Rationale | Applies To | Acceptance Signal / Test |
| --- | --- | --- | --- |
| Keep the shell-owned Add Community action visible globally and inside the empty state. | First-run users need a direct path from "nothing installed" to local load. | Demo App empty state, App Shell action area. | `vt_demo-app_add-community-button`, `vt_demo-app_empty-state-cta-loads-community` |
| Render community cards only from typed branding props and deterministic image fallback. | Prevents extensions from spoofing the app inventory and keeps cards scannable. | Community Card, Local Backend import. | `vt_community-card_render-bind`, `vt_community-card_branding-priority`, `ct_local-backend__community-card_branding-props` |
| Messages and Connections are required shell destinations. | These are platform invariants, not extension options. | Navigation Panel, App Shell Runtime. | `vt_app-shell_required-nav`, `vt_navigation-panel_messages-connections`, `ct_navigation-panel__workflow_messages-connections-reachable` |
| Reserve shell ad surfaces and disclose stream ads. | Required monetization surfaces must be visible without misleading users. | Ad Slots, Stream Renderer. | `vt_app-shell_ad-slots`, `vt_stream-renderer_ad-item-disclosure`, `ct_ad-decision__stream-renderer_in-stream-ad` |
| Route all payments through the Loom-owned payment surface. | Payments, receipts, and ad-off entitlements must remain auditable. | Payment Surface. | `vt_payment-surface_shell-owned`, `ct_payment-surface__workflow_ad-off-checkout` |
| Keep consent controls visible through a shell-owned data dashboard contract. | Sensitive-data handling must remain consistent across extensions. | Data Dashboard/Consent Prompt. | `vt_data-dashboard_consent-revoke`, `ct_data-dashboard__workflow_consent-revoke` |
| Use deterministic sample loading in A6, then expand to real local file validation in B1a. | A6 validates UX component wiring without introducing file-system nondeterminism. | Demo App, Local In-App Backend. | `vt_demo-app_local-file-load-extension`, `ct_extension-package__demo-loader_validate-load` |

## Key Implementation Decisions

Record implementation decisions that materially alter the UX, including component ownership, state model, copy source, layout behavior, validation behavior, and test coverage.

| Implementation Decision | UX Impact | Owning Component | Tests / Gates |
| --- | --- | --- | --- |
| Empty-state CTA uses the same `_loadSampleLocalCommunity` handler as the floating Add Community button. | The visible first-run CTA now performs the expected action instead of being inert. | Loom Communities Demo App. | `vt_demo-app_empty-state-cta-loads-community` |
| Local backend import returns a stable report with `created`, imported seed files, and shell card props. | Users and tests can distinguish first import from duplicate import. | Local In-App Backend Adapter. | `vt_fake-backend_import-init-package`, `vt_fake-backend_import-idempotent` |
| Community card image resolution is a pure priority function. | Missing image/logo assets produce predictable fallback instead of broken cards. | Community Card. | `vt_community-card_branding-priority`, `vt_demo-app_card-image-after-load` |
| Stream ad item rendering hard-codes the ad kind and disclosure in props. | Extension content cannot silently create undisclosed sponsor cards. | Stream Renderer. | `vt_stream-renderer_ad-item-disclosure` |
| Payment and consent are props contracts, not extension-owned widget implementations. | Shell remains responsible for sensitive flows even when extension UI is mounted. | Payment Surface, Data Dashboard. | `vt_payment-surface_shell-owned`, `vt_data-dashboard_consent-revoke` |

## Workflow Walkthrough

Workflow under review: `A6 UX component validation`. Walk through the experience step by step after the UX decisions are made. Include the screen or state shown, the user action, the owning component, and the covering test.

| Step | User Goal / Action | Screen or State | Owning Component | UX Decision Applied | Covering Test |
| --- | --- | --- | --- | --- | --- |
| 1 | Launch the Demo App with no installed communities. | Empty state says no communities are installed and shows Add Community. | Loom Communities Demo App. | Empty state with direct action. | `vt_demo-app_add-community-button` |
| 2 | Trigger local load from the empty state CTA or shell FAB. | Deterministic sample extension/init package load starts. | Loom Communities Demo App, Local In-App Backend. | Both entry points share one load handler. | `vt_demo-app_empty-state-cta-loads-community`, `vt_demo-app_cards-after-load` |
| 3 | Load extension package and import initialization data. | Local backend records loaded extension and imported seed files. | Local In-App Backend Adapter. | Local picker plus validation pattern, deterministic in A6. | `vt_demo-app_local-file-load-extension`, `ct_initialization-package__fake-backend_import` |
| 4 | Re-run import or reload the app state. | Duplicate import is idempotent; snapshot reload keeps community and extension. | Local In-App Backend Adapter. | Error prevention and recovery state. | `vt_fake-backend_import-idempotent`, `vt_local-store_persist-reload` |
| 5 | See the installed community inventory. | Branded community card appears with fallback image behavior. | Community Card, App Shell Runtime. | Shell-rendered cards. | `vt_community-card_render-bind`, `vt_demo-app_card-image-after-load` |
| 6 | Open the local extension. | Shell opens the local extension session and preserves required shell surfaces. | App Shell Runtime, Navigation Panel, Ad Slots. | Stable shell destinations and required ad slot. | `vt_demo-app_open-local-extension`, `ct_extension-runtime__app-shell_local-session` |

## Open Questions / Tradeoffs

Capture unresolved UX questions and tradeoffs before implementation starts. A phase can proceed only when blockers are resolved or explicitly accepted.

| Question / Tradeoff | Options Considered | Recommendation | Owner | Resolution Required Before |
| --- | --- | --- | --- | --- |
| Should A6 invoke a real native file picker? | Real picker now, deterministic sample now and picker in B1a. | Keep A6 deterministic; implement full picker/package validation UX in B1a. | Demo App / Local Backend Adapter. | B1a closeout |
| How rich should the community card image fallback be? | Initials only, category icon, generated local image. | A6 keeps generated initials/category/accent metadata; later phases can add generated bitmap assets. | Community Card. | Before visual polish release |
| Should ad no-fill hide the top banner? | Hide empty surface, reserve shell slot with no-fill state. | Reserve shell slot so the platform invariant is testable; B6/B7 refine sensitive/no-fill and ad-off display. | Ad Slots. | B6/B7 closeout |
| Should consent dashboard show full privacy labels in A6? | Full labels now, revocation contract now and full labels later. | A6 validates revocation props; workflow phases add full data-rights copy and export. | Data Dashboard. | B8 closeout |

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
