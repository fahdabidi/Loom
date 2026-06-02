# Phase 15 — Extensions Platform & Customization Foundation

**Surface:** core · **UX gate:** low (API/data foundation only) · **On green:** AUTO → Phase 16
**Shared conventions:** [README.md](./README.md).

> **Status:** Ready for execution after Phase 14. This phase begins the **Creator-Customized Fan
> Experiences** sequence (Phases 15–20). It implements the **extension platform** primitive (Extension
> Registry + Extension Runtime) and the **per-creator customization model** (`CreatorExperienceConfig`)
> as typed contracts, Drift state, fakes, and seed — then seeds **five gaming creators** and **six
> certified extensions**. It deliberately avoids building the customized fan/Studio UX so contract
> correctness, permission scoping, idempotency, and provenance are proven before Phases 16–19 render them.
> Goal of the sequence: prove the fan app is a **generic, data-driven renderer** and the experience is
> **creator-authored**, using the gaming segment for a high-contrast showcase.

## 0. Prerequisite gate (validate Phase 14 done)
README gate + confirm Phases 10–14 are committed and tracker-recorded; the launch loop, starter-pack
onboarding, conversion analytics, creator utility consoles, and emulator UX hardening are green.

## 1. Workflows & user stories in this phase
Contract/data foundation for the customization stories (added to
[../MVP User Stories Scope.md](../MVP%20User%20Stories%20Scope.md) Part J):
- **CE-S12 foundation** — creator channel experience config: theme, banner, ordered `surfaceModules[]`.
- **CE-S13 foundation** — install + configure a certified experience extension with scoped permissions.
- **FE-S14 foundation** — fan-side resolution of a creator's customized channel config.
- **FE-S15 foundation** — fan participation state for the six extension mechanics (sessions, events,
  rewards/badges).

No new fan or creator screen is required beyond keeping the app bootable. Prove the extension platform
and config model can support Phases 16–19 without magic values.

## 2. Tools (WSL Ubuntu)
Standard set. After schema changes: `dart run build_runner build --delete-conflicting-outputs` in
`app/packages/core/loom_local_store`; `melos bootstrap` after new exports/dependencies. No network.

## 2A. UX reference research & decision output
Low-UX phase, but create [Phase 15 - UX Decisions.md](./Phase%2015%20-%20UX%20Decisions.md) because the
manifest/config data choices shape Phases 16–19 screens.

Review reference patterns only to extract **data requirements**:
- Twitch Extensions / Discord activities: how a creator installs add-ons that render in defined surfaces
  (panel, overlay, component) with scoped permissions.
- Streamer toolkits (clip leaderboards, prediction/pick'em, hype/tip meters): the state each mechanic needs.
- Cozy/creative community tools (quest logs, build galleries, badges, collaborative goals): state shapes.
- Channel theming systems: palette, banner, and module-ordering fields.

Decision doc must record: which `CreatorExperienceConfig` fields are persisted vs computed; how installs
and runtime sessions stay idempotent and permission-scoped; how the six extensions share one manifest
primitive; and how extension state stays creator/fan-owned and exportable.

## 3. APIs invoked & stubs to implement
Implement typed Dart clients/models matching the OpenAPI specs already in `docs/API/OpenAPI/ecosystem/**`.

New clients:
- **Extension Registry API:** `publishExtension`, `getExtension`, `installExtension`, `suspendExtension`.
- **Extension Runtime API:** `createExtensionSession`, `submitExtensionEvent`, `createExtensionStateExport`.

New customization surface (extends creator metadata ownership):
- **Creator Experience Config** read/write: `getExperienceConfig(channelId)`, `putExperienceConfig`,
  surface-module ordering, installed-extension references. Persisted through Creator Metadata API where
  it owns channel business state; add a thin client if a dedicated surface is cleaner.

Reuse/extend:
- **Campaign / Reward + Receipt Ledger:** extension rewards/badges reuse the existing reward+receipt path.
- **Fan Wallet / Entitlement Ledger:** HypeWars tip/hype state and reward entitlements.
- **Recommendation & Referral:** Build/Clip showcase ordering and the gaming starter pack (Phase 19) read path.
- **AI Gateway / Ad Decision / Creator Metadata:** per-creator AI persona label and ad posture fields (rendered in Phase 16).

Fake implementations: one fake per new surface in `core/loom_fake_backend`; register all in
`apps/loom_demo/lib/main.dart`; fakes read/write `loom_local_store` and simulate latency/error/idempotency.

## 4. Data storage (local store)
Add Drift tables (or extend existing):
- `extensions`: extensionId, name, category, riskTier, surfaces, permissions, exportBehavior, certificationState.
- `extension_versions`: extensionId, version, state(submitted|certified|rejected|suspended).
- `extension_installs`: channelId, extensionId, version, approvedPermissions, approvedSurfaces, config(json), state(active|revoked|suspended).
- `extension_sessions`: sessionId, extensionId, version, surface, fanId|pairwise, channelId, state, allowedPermissions.
- `extension_events`: sessionId, type, payload(json), createdAt, idempotencyKey.
- `extension_state`: scopeKey (creator/fan/extension), key, value(json), exportBehavior — generic KV backing the six mechanics.
- `creator_experience_configs`: channelId, themeId, palette, bannerRef, surfaceModules(ordered json), aiPersona, adPosture, installedExtensionIds, version, updatedAt.
- Mechanic-state seeds backed by `extension_state` (clip submissions/votes/leaderboard, predictions/ladder, hype/tip meter, quests/badges, build submissions/votes, guild-quest progress).

Seed is the **gaming** showcase world (see §5); existing non-gaming creators remain untouched.

## 5. Source files & components to create/update
API contracts:
- `core/loom_api_contracts/lib/clients/extension_registry_api.dart`
- `core/loom_api_contracts/lib/clients/extension_runtime_api.dart`
- `core/loom_api_contracts/lib/clients/creator_experience_api.dart` (or extend creator metadata client)

Models:
- `ExtensionManifest`, `ExtensionVersion`, `ExtensionInstall`, `ExtensionSession`, `ExtensionEvent`, `ExtensionStateExport`
- `CreatorExperienceConfig`, `ChannelTheme`, `SurfaceModule`, `InstalledExtensionRef`

Fake backend / local store:
- Matching fakes + exports in `loom_fake_backend`; extend `loom_local_store` schema + generated Drift code.
- **Seed loader** (`loom_seed_data` + `assets/seed/*.json`): five gaming creators —
  **NovaClutch** (FPS/esports), **EmberHollow** (cozy survival-builder + lore), **FrameByFrame**
  (speedrunner of *Hollowfall*), **DriftAndChill** (variety streamer of *Hollowfall*), **IronVael**
  (MMO/RPG guild) — each with content, avatar, **banner**, distinct **theme**, AI persona, and ad
  posture; six certified extensions — **Clip Arena, Pick'Em, HypeWars, Quest Log, Build Showcase,
  Guild Quest** — installed/configured per the plan's creator→extension matrix; gaming interest taxonomy.
- **Retire `_paletteFor()`**: move per-creator palette into `ChannelTheme` consumed by the design system
  in Phase 16 (Phase 15 only stores it; keep a temporary shim so the app still boots).

No new design-system component is required beyond test fixtures.

## 6. API best-practice checks (phase-specific)
- `installExtension` and `createExtensionSession` are idempotent; sessions are scoped to `approvedPermissions`/`approvedSurfaces`.
- `submitExtensionEvent` is idempotent by key; reward issuance reuses the Campaign/Reward + Receipt path (no bespoke economy).
- `CreatorExperienceConfig` writes are versioned; reads return the active version.
- The six extensions share one `ExtensionManifest` shape (no per-mechanic schema forks).
- Extension state honors `exportBehavior` (creator/fan-owned exportable); no per-fan behavioral leakage into aggregates.
- Seeded mechanic state is provenance-tagged; no UI-only magic values.

## 7. Component boundary / design checks
- `loom_api_contracts` stays pure contracts/models; `loom_fake_backend` imports contracts + store + seed only.
- Features do not import the new fakes/tables. `apps/loom_demo` is the only DI binding site.
- Update affected barrels and `CHARTER.md` only where scope changes.

## 8. Automated validation checks
README baseline plus unit tests: manifest/permission validation; install-grant scoping; session permission
enforcement; idempotent event recording; reward issuance via receipt path; `CreatorExperienceConfig`
resolution per creator; seed integrity (5 distinct creators, 6 certified extensions, distinct themes +
per-creator install matrix); Drift migration + `resetDemo()` clearing mutable extension/session state.

## 9. Integration tests
- `it_p15_extensions_foundation_smoke` — app boots with all extension fakes registered; resolves each of
  the five creators' `CreatorExperienceConfig`; creates a runtime session per extension surface; records an
  event; issues a reward via the receipt path — without opening a Phase 16–19 UI.
- `it_p15_reset_extension_state` — after creating sessions/events/rewards, `resetDemo()` clears mutable
  state and restores seed extensions, installs, and configs.

## 10. Definition of done
All Phase 15 typed clients, models, local-store tables, fakes, DI registrations, seed entries (five gaming
creators + six certified extensions + installs/configs), and tests complete; app still boots on the
emulator; no customization UX required yet. `melos bootstrap`, Drift gen, `melos run analyze`,
`lint:boundaries`, `test`, focused Phase 15 integration tests, full suite, APK build, emulator install, and
launch are green. [Phase 15 - API Review.md](./Phase%2015%20-%20API%20Review.md) and
[Phase 15 - UX Decisions.md](./Phase%2015%20-%20UX%20Decisions.md) filed. Update the tracker in
[../Demo App Implementation Plan.md](../Demo%20App%20Implementation%20Plan.md) with status, date, API
review, gate evidence, and commit SHA.

## 11. Next phase
After Phase 15 changes are committed and recorded, **AUTO-PROCEED: immediately begin
[Phase 16 — Config-Driven Channel Renderer & Per-Creator Persona/Ads](./Phase%2016%20-%20Config-Driven%20Channel%20Renderer.md).**
