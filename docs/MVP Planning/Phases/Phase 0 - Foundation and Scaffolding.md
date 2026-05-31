# Phase 0 — Foundation & Scaffolding + Role Switcher

**Surface:** both · **UX gate:** low (optional design-language glance) · **On green:** AUTO → Phase 1
**Shared conventions:** [README.md](./README.md) (tooling, gates, checks). This doc adds Phase-0 specifics.

## 0. Prerequisite gate
None (first phase). Instead, verify the build environment in WSL Ubuntu:
- `flutter --version` (stable channel), `dart --version`, `adb --version`, `java -version` present.
- `flutter doctor` shows Android toolchain + a Flutter Android emulator.
- An emulator launches (`flutter emulators --launch <id>`) and is visible in `flutter devices`.
- **Decision recorded:** working-tree location — native WSL filesystem (recommended, e.g. `~/loom/app`) vs in-repo under OneDrive. Document the choice in `app/README.md`.

## 1. Workflows & user stories in this phase
No user-facing scope stories. Foundational only. **Proof slice:** a read-only creator content list rendered from the `CreatorMetadataApi` fake, to prove the `contract → fake → local store → UI` path and the role switcher.

## 2. Tools (WSL Ubuntu)
- Create workspace + packages with `flutter create` (for `apps/loom_demo` + android/ios) and plain Dart packages for libs.
- `melos` for the workspace; `dart pub global activate melos`; author `app/melos.yaml` scripts: `analyze`, `test`, `test:integration`, `lint:boundaries`, `bootstrap`.
- `custom_lint` + a small local lint package `loom_lints` for boundary rules.
- Build/run: `flutter build apk --debug`; `adb -s <emulator_id> install -r ...`; `flutter run -d <emulator_id>`.

## 2A. UX reference research & decision output
Before implementing the nav shell, role switcher, content-list proof slice, and initial design tokens, review reference mockups and design guidance from popular social/social-video apps such as YouTube, Instagram, TikTok, Facebook, WhatsApp, and adjacent creator/fan products. Focus on role/account switching, mobile navigation, creator/content cards, feed density, loading states, and emulator-friendly mobile layout conventions.

Create [Phase 0 - UX Decisions.md](./Phase%200%20-%20UX%20Decisions.md) summarizing references reviewed, UX patterns extracted, key UX and implementation decisions, and a walkthrough of how the implemented shell and proof slice demonstrate the Phase 0 workflows using the collected guidance.

## 3. APIs invoked & stubs to implement
- **Contracts scaffolded (interfaces only) for all surfaces** in `loom_api_contracts/lib/clients/` so later phases just fill them — but only one is implemented now.
- **Implemented this phase:** `CreatorMetadataApi.getPublicCatalog(channelId, {cursor, limit})` → paginated `ContentSummaryView` list (id, title, summary, thumbnailRef, contentType). Fake: `CreatorMetadataFake` reads `content` + `creators` tables, returns a cursor page.
- Shared models: `ActorPrincipal`, `ApiError`, `Page<T>` (cursor + items), `ContentManifestView` (incl. required `summary`).

## 4. Data storage (local store)
`loom_local_store` (Drift/SQLite). Tables for the slice + seed v1:
- `creators(id, handle, displayName, vertical, avatarRef)`
- `content(id, creatorId, contentType, title, summary, thumbnailRef, createdAt, perfVelocity)`
- `kv_meta(key, value)` for `seedVersion` + demo flags.
- `resetDemo()` clears tables and reloads from `loom_seed_data`.
- Seed v1: 3 creators, ~15 content items (each with a `summary`).

## 5. Source files & components to create/update
- `app/melos.yaml`, `app/pubspec.yaml`, `app/analysis_options.yaml` (+ enable `custom_lint`, register `loom_lints`).
- `app/packages/tooling/loom_lints/` — boundary lint rules (feature import allowlist; no feature→feature; no feature→fake_backend/local_store).
- `core/loom_api_contracts/` — `models/shared/*`, `clients/*.dart` (all surfaces as abstract stubs), `clients/creator_metadata_api.dart` (concrete signatures for `getPublicCatalog`).
- `core/loom_local_store/` — Drift schema (tables above), DAOs, `resetDemo()`.
- `core/loom_seed_data/` — `assets/seed/creators.json`, `content.json`; loader.
- `core/loom_fake_backend/` — `creator_metadata_fake.dart` (header comment: implements `CreatorMetadataApi`; uses `creators`,`content`).
- `core/loom_design_system/` — `tokens/*`, `components/shell/nav_scaffold.dart`, `components/shell/role_switcher.dart`, `components/content_tile.dart`, `components/feed_card.dart` (minimal).
- `core/loom_app_shell/` — DI registry (`registerFakes()` / `registerHttp()` placeholder), router, `RoleScope` (Studio/Fan), theming, app entry helper.
- `features/fan/feature_creator_channel/` — `CHARTER.md`, barrel, `src/screens/content_list_screen.dart`, `src/state/content_list_notifier.dart`, `src/mappers/content_view_mapper.dart` (the slice).
- All other feature packages — created as **empty skeletons**: `CHARTER.md` + `pubspec.yaml` + `lib/feature_*.dart` barrel only.
- `apps/loom_demo/lib/main.dart` — composition root: bootstrap DI with fakes, mount role switcher + nav shell.

## 6. API best-practice checks (phase-specific)
- `getPublicCatalog` is **paginated** (cursor + limit); the content-list screen requests one page and supports load-more — never fetches all.
- Response (`ContentSummaryView`) carries **only** fields the tile renders; confirm no unused fields.
- Plus README baseline checks for `CreatorMetadataApi`.

## 7. Component boundary / design checks
- `loom_lints` rules authored and passing via `melos run lint:boundaries`.
- Verify `feature_creator_channel` imports only `loom_api_contracts` + `loom_design_system` + `loom_app_shell`.
- `loom_design_system` has zero API imports.

## 8. Automated validation checks
- `melos bootstrap` resolves all packages.
- `melos run analyze`, `melos run lint:boundaries`, `melos run test` green.
- `flutter build apk --debug` succeeds; APK installs on the Flutter Android emulator.

## 9. Integration tests
- `it_p0_boot` — app launches; role switcher toggles Studio ↔ Fan shells without error.
- `it_p0_content_list` — Fan content-list slice renders ≥1 item sourced from `CreatorMetadataFake`; load-more fetches page 2.

## 10. Definition of done
- Workspace builds in WSL; APK runs on the Flutter Android emulator.
- Role switcher works; content-list slice renders from the contract→fake→store path.
- All skeleton packages exist with charters; boundary lints pass; all checks green.
- `Phase 0 - UX Decisions.md` filed with reference research, key UX/implementation decisions, and proof-slice workflow walkthrough.
- Update the Phase completion tracker in [../Demo App Implementation Plan.md](../Demo%20App%20Implementation%20Plan.md) with Phase 0 status, completion date, API review link/name, and gate evidence before marking this phase complete.
- Commit all Phase 0 changes to git and record the commit SHA in the Phase completion tracker before proceeding.

## 11. Next phase
UX impact is low (no API-shaping UI). After Phase 0 changes are committed and the commit SHA is recorded, **AUTO-PROCEED: immediately begin [Phase 1 — Identity & Onboarding](./Phase%201%20-%20Identity%20and%20Onboarding.md).** Optional: capture screenshots of the nav shell/design language for an async glance; not a blocking gate.
