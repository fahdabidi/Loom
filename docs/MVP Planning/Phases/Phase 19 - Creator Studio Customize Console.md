# Phase 19 — Creator Studio: Customize Fan Experience Console

**Surface:** Creator Studio · **UX gate:** HIGH · **On green:** AUTO → Phase 20
**Shared conventions:** [README.md](./README.md).

> **Status:** Ready for execution after Phase 18. Delivers the **supply-side** half of the story: a
> Creator Studio console where a creator **authors** their fan experience — pick a theme/banner, install
> and configure extensions (with scoped-permission grants), arrange the surface modules, and **preview**
> the result. This proves the differences fans see in Phases 16–18 are **creator-controlled**, not
> platform-fixed. Also assembles the **gaming starter pack** that ties the five creators into the
> Phase 12 onboarding flow.

## 0. Prerequisite gate (validate Phase 18 done)
README gate + confirm Phases 15–18 committed/recorded: extension platform + config model, config-driven
channel renderer, and all six extension modules work across the five creators; their integration tests pass.

## 1. Workflows & user stories in this phase
- **CE-S12 / customize experience** — Creator selects a theme + banner and arranges ordered surface modules; a live preview reflects changes.
- **CE-S13 / install & configure extension** — Creator browses certified extensions, installs one with a **scoped-permission grant**, and configures it (e.g., season length, prize, quest set, hype goal).
- **CE-S13 / manage installs** — Creator can reconfigure, reorder, or remove/suspend an installed extension; the fan surface reflects it.
- **Gaming starter pack** — Creator (or curator) assembles a starter pack bundling the five gaming creators for onboarding (consumed by Phase 12's starter-pack flow).

## 2. Tools (WSL Ubuntu)
Standard set. Emulator screenshots of the console configured for at least two contrasting creators
(e.g., NovaClutch vs EmberHollow) plus their resulting fan channels.

## 2A. UX reference research & decision output
Record in [Phase 19 - UX Decisions.md](./Phase%2019%20-%20UX%20Decisions.md):
- Creator console patterns (YouTube Studio, Twitch creator dashboard, Shopify theme editor): left-config / right-preview, status cards, validation.
- Extension marketplace + install/permission-grant flows: risk-tier disclosure, scoped-permission consent, configure-after-install.
- Drag-to-reorder / module arrangement patterns that stay usable at phone width.

Apply the shared Creator-Studio baseline plus: the console is a work-focused editor with **live preview**;
permission grants are explicit and reversible; theme/module/extension choices write `CreatorExperienceConfig`
and installs that the Phase 16 renderer already consumes.

## 3. APIs invoked & stubs to implement
No new API surfaces. Reuse:
- **Extension Registry API:** list certified extensions, `installExtension` (scoped permissions), `suspendExtension`.
- **Creator Experience Config / Creator Metadata API:** `putExperienceConfig` (theme, banner, ordered modules, persona, ad posture).
- **Recommendation & Referral API:** assemble/persist the gaming starter pack (reuses the Phase 8 graph + Phase 12 starter-pack surface).
- **Extension Runtime API:** preview a module with seeded/sample state.

## 4. Data storage (local store)
No new domain tables. Write `creator_experience_configs` and `extension_installs` (from Phase 15) and a
`starter_packs` entry (from Phase 10) for the gaming pack. Confirm `resetDemo()` restores seed configs and
removes creator-made console changes.

## 5. Source files & components to create/update
Design system:
- `core/loom_design_system/lib/components/studio/customize_console.dart` — config + live-preview shell.
- `core/loom_design_system/lib/components/studio/theme_picker.dart`, `banner_picker.dart`.
- `core/loom_design_system/lib/components/studio/extension_browser.dart`, `extension_install_sheet.dart` (risk tier + scoped-permission grant), `extension_config_form.dart`.
- `core/loom_design_system/lib/components/studio/module_arranger.dart` — reorder surface modules.

Feature:
- `features/creator/feature_creator_customize` — new Studio feature: customize console, extension install/config, module arrangement, preview; writes config + installs.
- Reuse `feature_creator_launch`/Studio entry to surface a "Customize fan experience" action.
- Starter-pack assembly entry (curator/demo) producing the gaming pack consumed by Phase 12.

## 6. API best-practice checks (phase-specific)
- `installExtension` and `putExperienceConfig` are idempotent and versioned; preview does not write live state.
- Permission grants are explicit, scoped, and reversible; suspend/remove updates the fan surface.
- Starter-pack assembly reuses the Phase 8 recommendation graph; no second ranking system.
- Bounded calls; no over-fetch of the extension catalog (paginate/limit).

## 7. Component boundary / design checks
- Console components in `loom_design_system`; write/install logic in `feature_creator_customize` (contracts + design system + app_shell only).
- No feature→feature/fake/store imports; `lint:boundaries` clean; charters updated.

## 8. Automated validation checks
README baseline plus unit/widget tests: theme/banner selection writes config; install with scoped
permissions produces an `ExtensionInstall`; module reorder persists ordering; preview reflects pending
config without committing; reconfigure/suspend updates installs; starter-pack assembly persists the five creators.

## 9. Integration tests
- `it_p19_author_experience` — Creator picks a theme, installs an extension (permission grant), arranges modules; opening that creator's channel as a fan shows the authored result.
- `it_p19_reconfigure_propagates` — Reconfiguring/removing an extension in Studio changes the fan channel surface.
- `it_p19_two_creators_diverge` — Configuring NovaClutch vs EmberHollow yields the two distinct fan experiences.
- `it_p19_gaming_starter_pack` — The assembled gaming starter pack resolves through the Phase 12 onboarding flow.

## 10. Definition of done
A creator can author their fan experience end to end (theme, banner, install+configure extensions with
scoped permissions, arrange modules, preview), and changes propagate to the fan channel; the gaming starter
pack assembles and feeds Phase 12 onboarding; all checks + integration tests green; screenshots of the
console and two contrasting authored channels captured. [Phase 19 - API Review.md](./Phase%2019%20-%20API%20Review.md)
and [Phase 19 - UX Decisions.md](./Phase%2019%20-%20UX%20Decisions.md) filed; tracker updated with status,
date, API review, gate evidence, and commit SHA.

## 11. Next phase
After Phase 19 changes are committed and recorded, **AUTO-PROCEED: immediately begin
[Phase 20 — Customization Showcase, UX Hardening & Final Physical-Phone Validation](./Phase%2020%20-%20Customization%20Showcase%20and%20Final%20Validation.md).**
