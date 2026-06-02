# Phase 16 — Config-Driven Channel Renderer & Per-Creator Persona/Ads

**Surface:** Fan App · **UX gate:** HIGH · **On green:** STOP for UX
**Shared conventions:** [README.md](./README.md).

> **Status:** Ready for execution after Phase 15. This phase makes the fan-facing creator channel a
> **generic, data-driven renderer**: it reads each creator's `CreatorExperienceConfig` and produces a
> distinct experience — theme + banner + ordered surface modules + extension slots + per-creator AI
> persona and ad posture. The six extension modules render as **placeholders** here; their interactive
> behavior arrives in Phases 17–18. Success = the five gaming creators visibly feel like five different
> worlds, with **zero per-creator hardcoding** in feature code.

## 0. Prerequisite gate (validate Phase 15 done)
README gate + confirm Phase 15 committed/recorded: extension platform contracts/fakes/store and
`CreatorExperienceConfig` exist; five gaming creators + six certified extensions are seeded with
per-creator installs/configs; Phase 15 integration tests pass.

## 1. Workflows & user stories in this phase
- **FE-S14 / customized channel** — Fan opens a creator channel and sees that creator's theme, banner,
  and **ordered surface modules** driven entirely by `CreatorExperienceConfig`.
- **FE-S14 / per-creator persona & ads** — The channel's AI-archive entry shows the creator's **persona**
  (e.g., strategy coach vs lore guide) and the ad slot reflects the creator's **contextual ad posture**.
- **CE-S12 (fan-visible result)** — The differences across the five creators are produced by data, not by
  creator-specific widgets.
- Regression: existing non-gaming creators still render correctly through the same generic path.

## 2. Tools (WSL Ubuntu)
Standard set. Emulator screenshots of all five gaming channels for the UX checkpoint.

## 2A. UX reference research & decision output
Review and record in [Phase 16 - UX Decisions.md](./Phase%2016%20-%20UX%20Decisions.md):
- Twitch/YouTube channel pages: banner + identity header, themed accents, and modular panel ordering.
- Theming systems (palette tokens, accent-on-surface contrast) that keep one layout legible across themes.
- Modular "surface module" stacks: how reorderable sections (live, clips, guides, leaderboards, Q&A) read on a phone.
- AI-assistant entry points and ad-disclosure patterns that adapt copy per creator without new layouts.

Apply the shared baseline plus Phase 16 specifics: themes must preserve contrast/touch targets; the
renderer must degrade gracefully when a module/extension is absent; extension-slot placeholders must read
as "coming alive in this channel," not broken.

## 3. APIs invoked & stubs to implement
No new API surfaces. Reuse:
- **Creator Experience Config / Creator Metadata API:** theme, banner, ordered modules, installed extensions, persona, ad posture.
- **Extension Registry API:** resolve installed extensions + approved surfaces for slot rendering.
- **AI Gateway API:** per-creator archive persona label/prompt on the channel Q&A entry.
- **Ad Decision API / CreatorAdPolicy:** contextual ad posture in the channel ad slot.
- **Creator Metadata / Content Host:** content sections within the module order.

Any field the renderer needs but the config lacks → log in Phase 16 API Review and fix contract/fake/seed before shipping.

## 4. Data storage (local store)
No new domain tables. Read `creator_experience_configs` and `extension_installs` from Phase 15. Confirm
`resetDemo()` restores seeded configs.

## 5. Source files & components to create/update
Design system:
- `core/loom_design_system/lib/components/channel/channel_theme.dart` — theme tokens (palette, accent, banner treatment) derived from `ChannelTheme`.
- `core/loom_design_system/lib/components/channel/channel_banner.dart` — per-creator banner header.
- `core/loom_design_system/lib/components/channel/surface_module.dart` — generic module container + a registry that maps `SurfaceModule.type` → widget (content sections now; extension widgets in 17–18).
- `core/loom_design_system/lib/components/channel/extension_slot.dart` — placeholder slot for an installed extension surface.
- Update `creator_channel_header.dart` to consume theme + banner instead of fixed `LoomColors.ink`.

Features:
- `features/fan/feature_creator_channel`: rebuild `channel_home` to render `CreatorExperienceConfig.surfaceModules` in order via the module registry; apply theme; show per-creator AI persona entry + ad posture.
- `features/fan/feature_discovery`: replace the retired `_paletteFor()` with theme-driven accents from config.

## 6. API best-practice checks (phase-specific)
- One bounded set of calls per channel open (config + installs + content page); no N+1 per module.
- Renderer reads only fields present in config/installs; no per-creator branching in feature code.
- AI persona and ad posture come from data, not hardcoded maps.
- Unknown module/extension types render a safe placeholder, never crash.

## 7. Component boundary / design checks
- Theme/module/slot components live in `loom_design_system`; the channel feature maps config → view models only.
- No feature→feature or feature→fake imports; `lint:boundaries` clean.
- Charters updated for `feature_creator_channel` and `feature_discovery`.

## 8. Automated validation checks
README baseline plus: theme token contrast/availability tests; module-registry mapping tests; widget tests
that the same renderer produces **different** module order/theme for two different configs; graceful
placeholder for unknown types; regression render of a non-gaming creator.

## 9. Integration tests
- `it_p16_five_worlds` — Opening each of the five gaming creators renders distinct theme + banner + module
  order; asserts divergence (e.g., NovaClutch leaderboard-slot-first vs EmberHollow guides/Q&A-first).
- `it_p16_persona_and_ads` — Two creators show different AI-archive persona copy and different contextual ad posture.
- `it_p16_generic_regression` — A non-gaming creator still renders correctly via the generic path.

## 10. Definition of done
The creator channel is fully config-driven; the five gaming creators render as distinct worlds with no
per-creator hardcoding; per-creator AI persona and ad posture render from data; `_paletteFor()` is retired;
non-gaming creators regress cleanly; all checks + integration tests green; emulator screenshots of all five
channels captured. [Phase 16 - API Review.md](./Phase%2016%20-%20API%20Review.md) and
[Phase 16 - UX Decisions.md](./Phase%2016%20-%20UX%20Decisions.md) filed; tracker updated with status, date,
API review, gate evidence, and commit SHA.

## 11. Next phase
After Phase 16 changes are committed and recorded, **AUTO-PROCEED: immediately begin
[Phase 17 — Extension Modules I: Competitive & Economy](./Phase%2017%20-%20Extension%20Modules%20I%20Competitive%20and%20Economy.md).**
