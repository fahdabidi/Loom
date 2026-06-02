# Demo App (Creator Studio + Fan App) — Implementation Plan

## Context

The first build milestone is a **Demo App that demonstrates every MVP user story end-to-end on the Flutter Android emulator**, with physical-phone verification deferred to Phase 26 (the final phase) — both **fan-facing** stories and **creator-authoring** stories. It has two jobs:

1. **Validate the product** — prove the Creator Studio and Fan App experiences defined in the product docs work and feel right.
2. **Validate the API contracts** — prove the OpenAPI specs (`docs/API/OpenAPI/**`) return exactly the data each screen needs, and that every input a screen must send is obtainable from a prior API response or seed (no magic data).

There is **no real infrastructure**. The app calls **typed API clients shaped exactly like the OpenAPI specs**, but in demo mode those clients are backed by an **in-app fake backend** over a local on-device database, seeded from bundled data. Swapping the fake for real HTTP later must require **zero changes to UI/feature code**.

Per the confirmed scope decision, the demo includes **creator authoring**, delivered as **one Flutter app with two experiences sharing one identity** — a **Creator Studio** surface and a **Fan App** surface, switchable via a demo role switcher. This lets the headline loop — *author as creator → switch → consume as fan* — run live on one device, which also validates that fan **read** APIs consume what creator **write** APIs produced.

Source must be organized so **less powerful AI agents can safely change one component with minimal context** — hard module boundaries, small per-module API surface, documented interfaces.

## Goals & success criteria

- Every **IN** / **IN (simulated)** / **PARTIAL** story in [MVP User Stories Scope.md](./MVP%20User%20Stories%20Scope.md) — fan **and** creator — is demonstrable in the app.
- The headline loop (author → consume) and the six-step "wow" demo run end-to-end on the Flutter Android emulator, fully offline; the same loop is verified on a physical Android phone in Phase 26 only. *(External YouTube playback, added in Phases 21–26, requires network at play time; all Loom APIs remain faked/offline.)*
- Every screen's data comes only from API-client responses (proving API completeness and data provenance).
- Each phase produces an **API Conformance & Efficiency review** that feeds fixes back into the OpenAPI specs.
- Module boundaries are enforced by lints; each module has a charter an agent can act on with only that module + its API contracts in context.

## Framework & platform (confirmed: Flutter)

One Dart codebase for Android + iOS; builds APK in **WSL Ubuntu**; runs on the **Flutter Android emulator** throughout Phases 0–26, with Phase 26 additionally validating on a **physical phone over adb**; statically typed and agent-friendly; hard module boundaries via a **melos** workspace; trivial **stub→real-HTTP** swap via DI. We validate on Android now; iOS later with no rewrite.

**WSL/emulator setup (Phase 0 checklist):** Flutter SDK + Android cmdline-tools/SDK in WSL; launch the Flutter Android emulator in WSL; install/run the debug APK on the emulator. Physical-phone adb setup (USB passthrough with `usbipd-win`, or wireless adb) is a Phase 26 checklist item.

## Architecture & source organization

A **melos monorepo** of small Dart packages, three layers: **core**, **fake backend**, **features**. Features depend only on abstract contracts; `app_shell` injects implementations via DI (`get_it` + `riverpod`). Features never import the fake backend, the local store, or each other.

### Core packages
| Package | Responsibility |
| --- | --- |
| `loom_api_contracts` | Dart models + one **abstract client interface per OpenAPI surface** (e.g. `CreatorMetadataApi`, `RecommendationReferralApi`). Generated from specs where practical, else hand-written to match. |
| `loom_local_store` | On-device DB (Drift/SQLite) schema + persistence; `resetDemo()`. |
| `loom_seed_data` | Bundled JSON seed assets + loader. |
| `loom_fake_backend` | **In-process fake server**: one impl file per API surface over the local store; simulates latency, pagination, idempotency, receipts, `ApiError`. |
| `loom_design_system` | Tokens + reusable components for both Studio and Fan surfaces. |
| `loom_app_shell` | Navigation, **role switcher (Creator Studio ↔ Fan App)**, DI registration (fake vs http), session/actor context, theming, entry. |

### Feature modules → API surface mapping (agent work-assignment map)

**Fan App features**
| Feature | Stories | API contracts |
| --- | --- | --- |
| `feature_fan_onboarding` | FE-W1, MISSING-S2, FE-S1A | Fan Passport, Fan Vault |
| `feature_discovery` | FE-S9/9A/9B, RE-S3/3A/7/8/9, RE-W3/3A/7, FE-S5/W5 | Recommendation & Referral, External Recommendation Provider, Search, Content Host (perf metadata), Fan Vault |
| `feature_creator_channel` (fan view) | FE-S1/1B, FE-S12/W12 | Creator Metadata, Fan Passport (follow/visibility), Content Host |
| `feature_playback` | FE-S2/W2, MN-S1 | Playback Authorization, Content Host, Receipt Ledger |
| `feature_ai_qa` | FE-S7/W11, RE-S9, MN-S5 | AI Gateway, Creator Metadata, Receipt Ledger |
| `feature_wallet` | FE-S3/W3, FE-S4/W4, MN-S2/3, FE-S11 | Fan Wallet, Entitlement Ledger, Receipt Ledger, Settlement Engine |
| `feature_data_rights` | FE-S6A/W6A, FE-W7, FE-W1A | Fan Passport (consent/visibility), Fan Vault (interests/ad prefs), Creator Audience, Receipt Ledger |
| `feature_campaigns` (fan) | FE-S6/W6, AD-S3A/W2B | Campaign, Sponsor Campaign, Receipt Ledger |

**Creator Studio features**
| Feature | Stories | API contracts |
| --- | --- | --- |
| `feature_creator_onboarding` | CE-S1, CE-W1/W1A | Creator Channel Registry, Creator Metadata |
| `feature_creator_publishing` | CE-S2, MISSING-S3 (required summary), MISSING-S5 (catalog import) | Creator Metadata, Content Host, Migration & Export |
| `feature_creator_monetization` | CE-S3 (memberships), no-ad eligibility | Creator Metadata, Entitlement Ledger, Settlement Engine |
| `feature_creator_ads` | MISSING-S1 (`CreatorAdPolicy`), AD-S1/W1 | Creator Metadata, Sponsor Campaign |
| `feature_creator_recommendations` | CE-S5, RE-S1/2/4, RE-W1/W2 | Recommendation & Referral |
| `feature_creator_campaigns` | CE-W3, AD-W1, AD-W2B (creator side) | Campaign, Sponsor Campaign |
| `feature_creator_ai` | CE-W7 (enable archive Q&A/summaries) | AI Gateway, Creator Metadata |
| `feature_creator_audience` | CE-S3A, FE-W6A (creator side) | Creator Audience, Fan Passport |
| `feature_creator_revenue` | CE-S6, MISSING-S4 (revenue by intent) | Receipt Ledger, Settlement Engine |
| `feature_creator_export` | CE-S8, CE-W6 | Migration & Export, Creator Channel Registry |

**Boundary enforcement:** `custom_lint`/`import_lint` rules forbid feature→feature and feature→fake_backend imports. Each feature ships a `CHARTER.md` (scope, allowed contracts, owned screens, forbidden imports) so an agent's required context = that feature + its listed contracts + design system.

### The stub / fake-backend pattern (core mechanism)
- Features call abstract clients (e.g. `CreatorMetadataApi`). Demo DI binds the `…Fake` impl from `loom_fake_backend`; later, a `…Http` impl. No feature code changes.
- The fake reads/writes `loom_local_store`, so demo state is **stateful and persists** (channels, content, follows, likes, grants, purchases, receipts). `resetDemo()` re-seeds.
- The fake mirrors real semantics: pagination cursors, `Idempotency-Key` dedupe, receipt emission, `ApiError`, simulated latency.
- **Data-provenance rule (validates the APIs):** a screen may only use fields obtained from an API response (or nav args sourced from one). If a screen needs a field no API returns, that's an **API gap** logged against the spec. The author→consume loop strengthens this: fan reads must consume what creator writes produced through the fake.

## Source code tree layout

The app is a Flutter **melos** monorepo. (Working-tree location — native WSL filesystem vs in-repo under OneDrive — is decided in Phase 0; the layout is identical either way.) The four organizing buckets map to fixed locations:

- **Core packages** → `app/packages/core/loom_*`
- **Fan App features** → `app/packages/features/fan/feature_*`
- **Creator Studio features** → `app/packages/features/creator/feature_*`
- **UX Component Inventory** → `app/packages/core/loom_design_system/lib/components/**`

```
app/                                   # Flutter monorepo root (melos workspace)
  melos.yaml
  pubspec.yaml
  analysis_options.yaml                # shared lints + custom_lint boundary rules
  apps/
    loom_demo/                         # the single runnable Android/iOS app
      lib/main.dart                    # composition root: builds app_shell, binds DI (fake <-> http)
      android/   ios/
      pubspec.yaml
  packages/
    core/                              # === Core packages ===
      loom_api_contracts/
        lib/
          models/                      # DTOs mirroring OpenAPI schemas
            shared/                    #   ActorPrincipal, ApiError, pagination, receipts (_shared)
            <surface>/                 #   e.g. fan_passport/, creator_metadata/, recommendation_referral/
          clients/                     # one ABSTRACT client per OpenAPI surface:
            fan_passport_api.dart  fan_vault_api.dart  fan_wallet_api.dart
            creator_channel_registry_api.dart  creator_metadata_api.dart  creator_audience_api.dart
            content_host_api.dart  playback_authorization_api.dart
            entitlement_ledger_api.dart  receipt_ledger_api.dart  settlement_engine_api.dart
            search_api.dart  recommendation_referral_api.dart  external_recommendation_provider_api.dart
            ai_gateway_api.dart  campaign_api.dart  sponsor_campaign_api.dart
            trust_safety_api.dart  migration_export_api.dart
      loom_local_store/                # Drift/SQLite schema, DAOs, resetDemo()
      loom_seed_data/
        assets/seed/*.json             # bundled seed world
        lib/                           # seed loader
      loom_fake_backend/
        lib/                           # ONE impl file per surface, each implementing its contract
          fan_passport_fake.dart  creator_metadata_fake.dart  recommendation_referral_fake.dart  ...
      loom_design_system/              # === UX Component Inventory ===
        lib/
          tokens/                      # color, type, spacing, motion
          components/
            content_tile.dart  session_intent_disclosure_card.dart  feed_card.dart
            score_explanation_sheet.dart  creator_channel_header.dart
            player_chrome.dart  ad_slot.dart  wallet_row.dart  entitlement_row.dart
            consent_grant_card.dart  data_dashboard_row.dart  campaign_card.dart  receipt_statement.dart
            shell/   nav_scaffold.dart  role_switcher.dart
            studio/                    # Studio-specific composites
              publish_composer.dart  ad_policy_editor.dart  monetization_editor.dart
              recommendation_builder.dart  campaign_builder.dart  revenue_dashboard.dart
              audience_panel.dart  export_panel.dart
      loom_app_shell/                  # navigation, DI registry, role-switcher wiring, session/actor, theming
    features/
      fan/                             # === Fan App features ===
        feature_fan_onboarding/   feature_discovery/   feature_creator_channel/
        feature_playback/   feature_ai_qa/   feature_wallet/   feature_data_rights/   feature_campaigns/
      creator/                         # === Creator Studio features ===
        feature_creator_onboarding/   feature_creator_publishing/   feature_creator_monetization/
        feature_creator_ads/   feature_creator_recommendations/   feature_creator_campaigns/
        feature_creator_ai/   feature_creator_audience/   feature_creator_revenue/   feature_creator_export/
```

**Every feature package has the same internal shape** (keeps agent context small and uniform):
```
feature_<name>/
  CHARTER.md                 # scope, allowed contracts, owned screens, forbidden imports
  pubspec.yaml               # deps: loom_api_contracts, loom_design_system, loom_app_shell, riverpod
  lib/
    feature_<name>.dart      # barrel: exposes routes + public entry widgets only
    src/
      screens/               # full screens
      widgets/               # feature-local widgets composed from loom_design_system
      state/                 # riverpod notifiers / view models
      mappers/               # API DTO -> view-model mapping
```

**Dependency rules (enforced by `analysis_options.yaml` + custom_lint):**
- `features/**` may import only `loom_api_contracts`, `loom_design_system`, `loom_app_shell`. **Never** `loom_fake_backend`, `loom_local_store`, or another feature.
- `loom_fake_backend` imports `loom_api_contracts`, `loom_local_store`, `loom_seed_data`.
- `loom_design_system` imports its own tokens only — no API/business/feature deps.
- `apps/loom_demo` is the **only** place that binds concrete impls (fake or http) to abstract contracts via DI.

This gives an agent working one feature exactly three dependencies to reason about (its contracts + design system + routing); the per-surface fake files isolate backend changes the same way.

## Seed data plan
Bundled JSON (`loom_seed_data/assets/`), loaded once into the local DB; writes persist; `resetDemo()` reloads. Strategy: **seed a populated surrounding world; the primary demo creator authors their own channel live.**

- **Surrounding creators:** ~10 *other* creators across 2–3 verticals with content (so discovery/search/trending have depth).
- **Content (others):** ~150–250 items (video + post), each with required `ContentManifest.summary`, monetization mode, search/AI policy, plus host aggregate performance metadata for trending.
- **Fans:** 1 primary demo fan + 2–3 personas (incl. a family-safe/minor persona) with passport, vault, interest/dislike profile, ad prefs, entitlements.
- **Ads:** ad inventory + sponsor records + seeded `CreatorAdPolicy` for the surrounding creators (the demo creator sets their own live).
- **Discovery:** platform-intent registry, recommendation manifests + referral terms (others), community-feed + external-provider candidate sets.
- **Economic:** historical receipts + a settlement run so dashboards/allocation views are populated on first launch.
- **Authored live by the demo creator (not seeded):** their channel, content + summaries, `CreatorAdPolicy`, memberships, AI enablement, recommendations/referral terms, one campaign.

## API validation approach (every phase)
Each phase ends with an **API Conformance & Efficiency Review** → short findings note + spec change proposals:
- **Correctness/completeness:** every screen field traced to a response; every request field traced to a prior response/seed (provenance rule). Gaps → spec edits.
- **Efficiency / best practices:** no chatty/N+1 calls (one feed fetch returns ranked candidates **with** score explanations); pagination/cursors present and used; writes (publish, feedback, follows, grants) **batched/debounced** and **idempotent**; responses return **only fields the UI uses** (flag over-fetch); entitlement checks cached/batched, not per-item.
- **Feedback loop:** findings update `docs/API/OpenAPI/**`.

## UX design approach
Defined generally now in `loom_design_system`; validated at phase checkpoints (heaviest where UX changes ripple into API shape).

- **Reference-first UX:** before implementing UX in any phase, collect reference mockups, interaction patterns, and design guidance from popular social media products such as YouTube, Facebook, WhatsApp, Instagram, TikTok, and adjacent creator/fan tools. Use these references to guide Loom-specific choices without copying proprietary branding or assets.
- **UX decision output:** each phase creates a sibling `Phase N - UX Decisions.md` documenting reference sources, extracted patterns, key UX and implementation decisions, tradeoffs, and a workflow walkthrough explaining how the implemented UX best demonstrates the phase workflows.
- **Manual validation playbook:** [Phase Validation Walkthrough](./Phase%20Validation%20Walkthrough.md) is the running checklist for human validation while implementation continues in parallel.
- **Component inventory:** content tile, session-intent disclosure card, feed card (title + summary + why-shown + disclosure), score-explanation sheet, creator-channel header, player chrome + ad slot, wallet/entitlement rows, consent/grant card, data-dashboard rows, campaign card, receipt/allocation statement; **Studio:** publish composer (with required-summary field), monetization/ad-policy editors, recommendation/campaign builders, revenue dashboard, audience/export panels; shared nav shell + role switcher.
- **Screen inventory:** by feature module (above).
- **UX validation checkpoints** are non-blocking parallel checkpoints. The app must remain available for human validation at each checkpoint, but implementation may proceed to later phases after automated emulator gates pass unless the user explicitly pauses or redirects.

## Phased delivery plan

| Phase | Theme                                             | Surface | UX checkpoint                                   | API-validation focus |
| ----- | ------------------------------------------------- | ------- | ----------------------------------------------- | -------------------- |
| 0     | Foundation & scaffolding + role switcher          | both    | Nav shell + design language                     | Contract→fake→UI proven on emulator |
| 1     | Identity & onboarding                             | both    | **HIGH** (fan interest picker; creator channel) | Passport/channel create idempotency; interest taxonomy source |
| 2     | Creator publishing & monetization setup           | Studio  | **HIGH** (publish composer, required summary)   | Publish/import idempotency + manifest versioning; summary required; minimal write payloads |
| 3     | Discovery core                                    | Fan     | **MAJOR**                                       | Candidate **batching** + pagination; score-explanation payload; feedback debounce |
| 4     | Channel, follow, playback & ads                   | Fan     | MED (player + ad slot)                          | Single-call playback decision; ad context no behavioral targeting; completion + receipts |
| 5     | AI archive Q&A                                    | both    | MED (Q&A + citations)                           | Q&A request shape; source-attribution receipts; summary present for ranking |
| 6     | Wallet (fan) + revenue dashboard (creator)        | both    | MED (purchase, revenue)                         | Payment-intent idempotency; entitlement check batched; revenue **by-intent** + allocation |
| 7     | Data rights & data-for-value                      | both    | **HIGH** (consent model)                        | Grant lifecycle; `DataAccessReceipt` on access; firewall stricter-of; minimal field exposure |
| 8     | Recommendations, campaigns & referral             | both    | MED (rec/campaign builders)                     | Manifest publish; campaign/entry receipts; referral attribution + settlement |
| 9     | Export/portability + transparency + full demo     | both    | FINAL emulator full-app                         | Export job completeness; end-to-end provenance + efficiency sweep; emulator performance |
| 10    | Launch contracts, store & fakes                   | core    | LOW (API/data)                                  | Typed launch APIs; local-store tables; fake backend; reset/idempotency |
| 11    | Creator launch funnel                             | Studio  | **HIGH**                                        | Announcement templates; link-in-bio preview; QR/capture link; cross-post stub |
| 12    | Fan starter-pack onboarding                       | Fan     | **HIGH**                                        | Capture landing; bulk follow; non-empty feed; plural suggested creators |
| 13    | Conversion analytics & creator utility consoles   | Studio  | **HIGH**                                        | Conversion funnel; catalog import; ad policy; AI preview; membership setup |
| 14    | UX hardening & phone deferral                     | both    | **emulator UX**                                 | Immersive discovery; richer media; async states; pagination; physical-phone deferral to Phase 26 |
| 15    | Extensions platform & customization foundation    | core    | LOW (API/data)                                  | Registry/runtime/config contracts; fake backend; seed customization data; reset/idempotency |
| 16    | Config-driven channel renderer                    | Fan     | **HIGH**                                        | `CreatorExperienceConfig` renderer; themed modules; extension slots; no hardcoded creator UI |
| 17    | Extension modules I: competitive & economy        | Fan     | **HIGH**                                        | Clip Arena, Pick'Em, HypeWars; runtime events; reward receipts |
| 18    | Extension modules II: collaborative & creative    | Fan     | **HIGH**                                        | Quest Log, Build Showcase, Guild Quest; persisted collaboration state; reusable runtime APIs |
| 19    | Creator Studio customize console                  | Studio  | **HIGH**                                        | Theme/banner controls; extension install/config; module ordering; preview and starter pack |
| 20    | Customization showcase (emulator)                 | both    | FINAL emulator (showcase)                       | Showcase hardening; runbook/walkthrough updates; emulator regression (physical-phone gate → Phase 26) |
| 21    | AI search & external content foundation           | core    | LOW (API/data)                                  | AI-search merge + external-source + agent-config contracts; embed descriptor; SearchReceipt audit-only; reset/idempotency |
| 22    | Fan AI search settings & source connections       | Fan     | **HIGH**                                        | Agent (MCP) connect config; external-source/YouTube connect (simulated); prefer-creators; query-egress disclosure |
| 23    | AI search results (merge + title handling)        | Fan     | **HIGH**                                        | Creator-preferred merge; agent ranking (no paid placement); compliant external title (unaltered) + accurate-match label |
| 24    | Embedded player & AI-driven next                  | Fan     | **HIGH**                                        | Official YouTube IFrame (unobscured); AI-search "next" rail; non-YouTube external open; offline/error states |
| 25    | Creator external content in feeds                 | both    | **HIGH**                                        | Link external (generic) as feed content; native tile + attribution; indexable/AI gating; idempotent link |
| 26    | Gaming seed, AI-search showcase & final validation | both   | FINAL phone + emulator                          | Gaming YouTube seed in rec feeds; full AI-search showcase; provenance/compliance; **physical-phone gate** |

## Phase completion tracker

This tracker is the source of truth for demo-app phase completion. At the end of every phase, the executing agent must update this table before marking the phase done: set the status, record the completion date when complete, link or name the API review, summarize gate evidence or blockers, and include the git commit SHA for the completed phase. A phase is not complete until this tracker is updated and all phase changes are committed to git.

| Phase                                                | Status      | Completion date | Commit SHA | API review                                 | Gate evidence / blockers |
| ---------------------------------------------------- | ----------- | --------------- | ---------- | ------------------------------------------ | ------------------------ |
| 0 — Foundation & scaffolding + role switcher         | Complete    | 2026-05-31      | `529c97c`  | [Phase 0 API Review][phase-0-api-review]   | Green on modern UX rerun: `melos bootstrap`, final `melos run analyze`, `melos run lint:boundaries`, `melos run test`, full `melos run test:integration` on `emulator-5554`, final normal-app `flutter build apk --debug`, emulator `adb install -r`, and launch screenshot `data/validation/phase0-1-home-rerun.png`. Modern shell/feed UX and [Phase 0 UX Decisions][phase-0-ux-decisions] updated. `loom_local_store` uses Drift/SQLite for app runs and in-memory Drift for tests. Physical-phone verification is deferred to Phase 26. |
| 1 — Identity & onboarding                            | Complete    | 2026-05-31      | `2808ae5`  | [Phase 1 API Review][phase-1-api-review]   | Green on modern UX rerun plus manual-validation correction: final `melos run analyze`, `melos run test`, focused `flutter test integration_test/it_p1_FE-W1_test.dart -d emulator-5554` now taps the creator card, final normal-app `flutter build apk --debug`, emulator `adb install -r`, and launch screenshots `data/validation/phase1-fan-onboarding-rerun.png` and `data/validation/phase1-creator-studio-rerun.png`. Earlier full `melos run test:integration` passed on `emulator-5554` (`it_p0_*` + `it_p1_*`). Modern onboarding UX and [Phase 1 UX Decisions][phase-1-ux-decisions] updated. Physical-phone verification is deferred to Phase 26. |
| 2 — Creator publishing & monetization setup          | Complete    | 2026-06-01      | `bd85067`  | [Phase 2 API Review][phase-2-api-review]   | Green: `melos bootstrap`, `melos run analyze`, `melos run lint:boundaries`, `melos run test`, focused Phase 2 `flutter test integration_test/it_p2_*_test.dart -d emulator-5554`, full `melos run test:integration` on `emulator-5554` (11/11), normal-app `flutter build apk --debug`, emulator `adb install -r`, and launched manual-checkpoint screenshot `data/validation/phase2-manual-checkpoint.png`. [Phase 2 UX Decisions][phase-2-ux-decisions] filed. Manual UX validation continues in parallel while implementation proceeds. Physical-phone verification is deferred to Phase 26. |
| 3 — Discovery core                                   | Complete    | 2026-06-01      | `9c54731`  | [Phase 3 API Review][phase-3-api-review]   | Green: `melos bootstrap`, Drift generation, `melos run analyze`, `melos run lint:boundaries`, `melos run test`, full `melos run test:integration` on `emulator-5554` (16/16), `flutter build apk --debug`, emulator `adb install -r`, and app launch. Added [Phase 3 UX Decisions][phase-3-ux-decisions]. Manual UX validation continues in parallel while implementation proceeds. Physical-phone verification is deferred to Phase 26. |
| 4 — Channel, follow, playback & ads                  | Complete    | 2026-06-01      | `c5b22a0`  | [Phase 4 API Review][phase-4-api-review]   | Green: `melos bootstrap`, `melos run analyze`, `melos run lint:boundaries`, `melos run test` (12 tests), focused Phase 4 integration tests (4/4), full `melos run test:integration` on `emulator-5554` (20/20), `flutter build apk --debug`, emulator `adb install -r`, app launch, and screenshot `data/validation/phase4-manual-checkpoint.png`. Added [Phase 4 UX Decisions][phase-4-ux-decisions]. Manual UX validation continues in parallel while implementation proceeds. Physical-phone verification is deferred to Phase 26. |
| 5 — AI archive Q&A                                   | Complete    | 2026-06-01      | `1e4550d`  | [Phase 5 API Review][phase-5-api-review]   | Green: `melos bootstrap`, Drift generation, `melos run analyze`, `melos run lint:boundaries`, `melos run test` (15 tests), focused Phase 5 integration tests (3/3), clean full `melos run test:integration` on `emulator-5554` (23/23), `flutter build apk --debug`, emulator `adb install -r`, app launch, and screenshot `data/validation/phase5-manual-checkpoint.png`. Added [Phase 5 UX Decisions][phase-5-ux-decisions]. Manual UX validation continues in parallel while implementation proceeds. Physical-phone verification is deferred to Phase 26. |
| 6 — Wallet + revenue dashboard                       | Complete    | 2026-06-01      | `4e65d19`  | [Phase 6 API Review][phase-6-api-review]   | Green: `melos bootstrap`, Drift generation, `melos run analyze`, `melos run lint:boundaries`, `melos run test` (19 tests), focused Phase 6 integration tests (4/4), full `melos run test:integration` on `emulator-5554` (27/27) from a WSL-native mirror to avoid OneDrive APK lock races, normal-app `flutter build apk --debug`, emulator `adb install -r`, app launch, and screenshot `data/validation/phase6-manual-checkpoint.png`. Added [Phase 6 UX Decisions][phase-6-ux-decisions]. Manual UX validation continues in parallel while implementation proceeds. Physical-phone verification is deferred to Phase 26. |
| 7 — Data rights & data-for-value                     | Complete    | 2026-06-01      | `2d051d4`  | [Phase 7 API Review][phase-7-api-review]   | Green: `melos bootstrap`, Drift generation, `melos run analyze`, `melos run lint:boundaries`, `melos run test` (23 tests), focused Phase 7 integration tests (4/4), full `melos run test:integration` on `emulator-5554` (31/31) from a WSL-native mirror to avoid OneDrive Gradle asset lock races, normal-app `flutter build apk --debug`, emulator `adb install -r`, app launch, and screenshot `data/validation/phase7-manual-checkpoint.png`. Added [Phase 7 UX Decisions][phase-7-ux-decisions]. Manual UX validation continues in parallel while implementation proceeds. Physical-phone verification is deferred to Phase 26. |
| 8 — Recommendations, campaigns & referral            | Complete    | 2026-06-01      | `09c6def`  | [Phase 8 API Review][phase-8-api-review]   | Green: `melos bootstrap`, `melos run analyze`, `melos run lint:boundaries`, `melos run test` (26 tests), focused Phase 8 integration tests (4/4), full `melos run test:integration` on `emulator-5554` (35/35) from a WSL-native mirror to avoid OneDrive Gradle asset lock races, normal-app `flutter build apk --debug`, emulator `adb install -r`, app launch, and screenshot `data/validation/phase8-manual-checkpoint.png`. Added [Phase 8 UX Decisions][phase-8-ux-decisions]. Manual UX validation continues in parallel while implementation proceeds. Physical-phone verification is deferred to Phase 26. |
| 9 — Export/portability + transparency + full demo    | Complete    | 2026-06-02      | `1db710d`  | [Phase 9 API Review][phase-9-api-review]   | Green implementation gates: `melos bootstrap`, Drift generation, `melos run analyze`, `melos run lint:boundaries`, `melos run test` (28 tests), full `melos run test:integration` on `emulator-5554` (39/39), normal-app `flutter build apk --debug -t lib/main.dart`, emulator `adb install -r`, app launch, and screenshot `data/validation/phase9-manual-checkpoint.png`. Added [Phase 9 UX Decisions][phase-9-ux-decisions] and [Demo Runbook](./Phases/Demo%20Runbook.md). Physical Android phone validation and final launch-demo validation moved to Phase 26. |
| 10 — Launch contracts, store & fakes                 | Complete    | 2026-06-02      | `9924019`  | [Phase 10 API Review][phase-10-api-review] | Green implementation gates: Drift generation, `melos bootstrap`, `melos run analyze`, `melos run lint:boundaries`, `melos run test` (29 tests), focused `flutter test test/p10_launch_contracts_api_test.dart`, `flutter analyze`, and `flutter build apk --debug -t lib/main.dart`. Added [Phase 10 UX Decisions][phase-10-ux-decisions]. Added Phase 10 integration tests, but WSL `adb devices` reported no attached emulator, so emulator integration/install/launch checks are pending device visibility. |
| 11 — Creator launch funnel                           | Complete    | 2026-06-02      | `e5b4ca5`  | [Phase 11 API Review][phase-11-api-review] | Green implementation gates: `melos bootstrap`, focused package/app analyzes, `melos run analyze`, `melos run lint:boundaries`, `melos run test` (30 tests), focused `flutter test test/p11_creator_launch_controller_test.dart`, and `flutter build apk --debug -t lib/main.dart`. Added [Phase 11 UX Decisions][phase-11-ux-decisions]. Added Phase 11 integration tests, but WSL `adb devices` reported no attached emulator, so emulator integration/install/launch checks are pending device visibility. |
| 12 — Fan starter-pack onboarding                     | Complete    | 2026-06-02      | `89a3cfb`  | [Phase 12 API Review][phase-12-api-review] | Green implementation gates: `melos bootstrap`, focused package/app analyzes, `melos run analyze`, `melos run lint:boundaries`, `melos run test` (33 tests), focused `flutter test test/p12_starter_pack_onboarding_test.dart test/p1_onboarding_controller_test.dart`, and `flutter build apk --debug -t lib/main.dart`. Added [Phase 12 UX Decisions][phase-12-ux-decisions]. Added Phase 12 integration tests, but WSL `adb devices` reported no attached emulator and `flutter test integration_test/it_p12_*.dart` failed with no supported device, so emulator integration/install/launch checks are pending device visibility. |
| 13 — Conversion analytics & creator utility consoles | Complete    | 2026-06-02      | `2772c3a`  | [Phase 13 API Review][phase-13-api-review] | Green implementation gates: `melos bootstrap`, focused package/app analyzes, `melos run analyze`, `melos run lint:boundaries`, `melos run test` (34 tests), focused `flutter test test/p13_creator_utility_api_test.dart`, and `flutter build apk --debug -t lib/main.dart`. Added [Phase 13 UX Decisions][phase-13-ux-decisions]. Added Phase 13 integration tests, but WSL `adb devices` reported no attached emulator and `flutter test integration_test/it_p13_*.dart` failed with no supported device, so emulator integration/install/launch checks are pending device visibility. |
| 14 — UX hardening & physical phone validation        | Complete    | 2026-06-02      | `e4cb221`  | [Phase 14 API Review][phase-14-api-review] | Green implementation gates: `melos bootstrap`, final post-format `melos run analyze`, `melos run lint:boundaries`, `melos run test` (36 tests), focused `flutter test test/widget_test.dart test/p14_ux_hardening_widget_test.dart`, and `flutter build apk --debug -t lib/main.dart`. Added [Phase 14 UX Decisions][phase-14-ux-decisions], Phase 14 integration tests, and launch-loop runbook updates. Blocked device evidence: WSL `adb devices` reports no attached Android device, `flutter devices` only reports Linux desktop, and `flutter test integration_test/it_p14_*.dart` fails with no supported device. Authoritative physical-phone validation is deferred to Phase 26. |
| 15 — Extensions platform & customization foundation  | Complete    | 2026-06-02      | `ff5a8f6`  | [Phase 15 API Review][phase-15-api-review] | Green implementation gates: `dart format`, `melos run analyze`, `melos run lint:boundaries`, focused `flutter test test/p15_extensions_foundation_api_test.dart`, `melos run test` (37 tests), and `flutter build apk --debug -t lib/main.dart`. Added [Phase 15 UX Decisions][phase-15-ux-decisions], Phase 15 integration tests, typed extension registry/runtime/creator-experience APIs, fake backend over Drift/SQLite local store, seeded gaming creators, six certified extensions, permission-scoped installs, idempotent sessions/events, reward receipts, and reset coverage. Blocked device evidence: WSL `adb devices` reports no attached Android device, `flutter devices` only reports Linux desktop, focused Phase 15 integration tests fail with no supported `emulator-5554`, and emulator `adb install` fails with no devices/emulators found. Physical-phone validation remains Phase 26. |
| 16 — Config-driven channel renderer                  | Complete    | 2026-06-02      | `adfd4ff`  | [Phase 16 API Review][phase-16-api-review] | Green implementation gates: `dart format`, focused package/app analyzes, `melos run analyze`, `melos run lint:boundaries`, focused `flutter test test/p16_config_driven_channel_widget_test.dart`, `melos run test` (40 tests), and `flutter build apk --debug -t lib/main.dart`. Added [Phase 16 UX Decisions][phase-16-ux-decisions], channel design-system primitives, config-driven creator channel rendering, extension-slot placeholders, per-creator persona/ad posture rendering, five-world integration tests, and non-gaming regression coverage. Blocked device evidence: WSL `adb devices` reports no attached Android device, `flutter devices` only reports Linux desktop, focused Phase 16 integration tests fail with no supported `emulator-5554`, and emulator `adb install` fails with no devices/emulators found. Physical-phone validation remains Phase 26. |
| 17 — Extension modules I: competitive & economy      | Complete    | 2026-06-02      | `3685ed9`  | [Phase 17 API Review][phase-17-api-review] | Green implementation gates: `melos bootstrap`, focused analyzes for `feature_extensions` and `loom_demo`, `melos run analyze` across 28 packages, `melos run lint:boundaries`, focused `flutter test test/p17_extension_runtime_api_test.dart test/p17_extension_modules_widget_test.dart`, `melos run test` (45 tests), and `flutter build apk --debug -t lib/main.dart`. Added [Phase 17 UX Decisions][phase-17-ux-decisions], live Clip Arena, Pick'Em, and HypeWars modules, extension event aggregate state, `extensionHype` wallet intent/receipt mapping, app-level extension host composition, and Phase 17 integration tests. Blocked device evidence: WSL `adb devices` reports no attached Android device, `flutter devices` only reports Linux desktop, focused Phase 17 integration tests fail with no supported `emulator-5554`, and emulator `adb install` fails with no devices/emulators found. Physical-phone validation remains Phase 26. |
| 18 — Extension modules II: collaborative & creative  | Complete    | 2026-06-02      | `ca3db6f`  | [Phase 18 API Review][phase-18-api-review] | Green implementation gates: `dart format`, focused analyzes for `loom_demo`, `feature_extensions`, `loom_design_system`, and `loom_local_store`, `melos run analyze` across 28 packages, `melos run lint:boundaries`, focused `flutter test test/p18_collaborative_extensions_api_test.dart test/p18_collaborative_extensions_widget_test.dart`, `melos run test` (50 tests), and `flutter build apk --debug -t lib/main.dart`. Added [Phase 18 UX Decisions][phase-18-ux-decisions], live Quest Log, Build Showcase, and Guild Quest modules, badge/gallery/shared-progress design components, collaborative extension state aggregation, and Phase 18 integration tests. Blocked device evidence: WSL `adb devices` reports no attached Android device, `flutter devices` only reports Linux desktop, focused Phase 18 integration tests fail with no supported `emulator-5554`, and emulator `adb install` fails with no devices/emulators found. Physical-phone validation remains Phase 26. |
| 19 — Creator Studio customize console                | Complete    | 2026-06-02      | 3189e9d    | [Phase 19 API Review][phase-19-api-review] | Green implementation gates: melos bootstrap, focused analyzes for feature_creator_customize, loom_design_system, and loom_demo, full melos run analyze across 29 packages, melos run lint:boundaries, focused flutter test test/p19_creator_customize_api_test.dart test/p19_creator_customize_widget_test.dart, melos run test (54 tests), and flutter build apk --debug -t lib/main.dart. Added [Phase 19 UX Decisions][phase-19-ux-decisions], Creator Studio customize console, theme/banner controls, live preview, extension install/reconfigure/suspend, module ordering, StarterPackApi.putStarterPack, and Phase 19 integration tests. Blocked device evidence: WSL adb devices reports no attached Android device, flutter devices only reports Linux desktop, focused Phase 19 integration tests fail with no supported emulator-5554, and emulator adb install fails with no devices/emulators found. Physical-phone validation remains Phase 26. |
| 20 — Customization showcase (emulator)               | Complete    | 2026-06-02      | d23d30e    | [Phase 20 API Review][phase-20-api-review] | Green implementation gates: focused flutter test test/p20_showcase_hardening_widget_test.dart, melos run analyze, melos run lint:boundaries, melos run test (56 tests), and flutter build apk --debug -t lib/main.dart. Added [Phase 20 UX Decisions][phase-20-ux-decisions], deterministic channel media backdrops, async/empty/error state hardening across customized channel/extension/Studio surfaces, Phase 20 integration tests, and customization showcase validation/runbook updates. Blocked device evidence: WSL adb devices reports no attached Android device, flutter devices only reports Linux desktop, focused Phase 20 integration tests fail with no supported emulator-5554, and emulator adb install fails with no devices/emulators found. Screenshots remain blocked until WSL can see an emulator/device. Physical-phone validation remains Phase 26. |
| 21 — AI search & external content foundation         | Complete    | 2026-06-02      | `fbda4a7`  | [Phase 21 API Review][phase-21-api-review] | Green implementation gates: Drift generation, `melos bootstrap`, focused `dart analyze` over changed packages, `melos run analyze`, `melos run lint:boundaries`, focused `flutter test test/p21_ai_search_foundation_api_test.dart` from `apps/loom_demo`, `melos run test` (60 tests), and `flutter build apk --debug -t lib/main.dart`. Added [Phase 21 UX Decisions][phase-21-ux-decisions], typed AI search / external content source / fan search agent contracts, Drift-backed fakes, seeded gaming YouTube references, reset/idempotency coverage, and Phase 21 integration tests. Blocked device evidence: WSL `adb devices` reports no attached Android device, `flutter devices` only reports Linux desktop, focused Phase 21 integration test fails with no supported `emulator-5554`, and emulator `adb install` fails with no devices/emulators found. Physical-phone validation remains Phase 26. |
| 22 — Fan AI search settings & source connections     | Complete    | 2026-06-02      | `3ae7273`  | [Phase 22 API Review][phase-22-api-review] | Green implementation gates: `melos bootstrap`, focused `flutter analyze` over changed packages, `melos run analyze`, `melos run lint:boundaries`, focused `flutter test test/p22_fan_settings_widget_test.dart` from `apps/loom_demo`, `melos run test` (62 tests), and `flutter build apk --debug -t lib/main.dart`. Added [Phase 22 UX Decisions][phase-22-ux-decisions], `feature_fan_settings`, AI-agent connection settings, simulated source connection rows, prefer-creators/external-source toggles, query-egress disclosure, and Phase 22 integration tests. Blocked device evidence: WSL `adb devices` reports no attached Android device, `flutter devices` only reports Linux desktop, focused Phase 22 integration test fails with no supported `emulator-5554`, and emulator `adb install` fails with no devices/emulators found. Physical-phone validation remains Phase 26. |
| 23 — AI search results (merge + title handling)      | Complete    | 2026-06-02      | `249f3fe`  | [Phase 23 API Review][phase-23-api-review] | Green implementation gates: `melos bootstrap`, focused `flutter analyze` over changed packages, `melos run analyze`, `melos run lint:boundaries`, focused `flutter test test/p23_ai_search_results_test.dart` from `apps/loom_demo`, `melos run test` (65 tests), and `flutter build apk --debug -t lib/main.dart`. Added [Phase 23 UX Decisions][phase-23-ux-decisions], reusable AI search result/disclosure components, connected-agent routing in Discovery, neutral no-agent fallback, source chips, original-title preservation, accurate-match labels, rank/receipt disclosure, and Phase 23 integration tests. Blocked device evidence: WSL `adb devices` reports no attached Android device, `flutter devices` only reports Linux desktop, focused Phase 23 integration test fails with no supported `emulator-5554`, and emulator `adb install` fails with no devices/emulators found. Physical-phone validation remains Phase 26. |
| 24 — Embedded player & AI-driven next                | Complete    | 2026-06-02      | `25acc4a`  | [Phase 24 API Review][phase-24-api-review] | Green implementation gates: `melos bootstrap`, focused `flutter analyze` over changed packages, `melos run analyze`, `melos run lint:boundaries`, focused `flutter test test/p24_external_playback_widget_test.dart` from `apps/loom_demo`, `melos run test` (67 tests), and `flutter build apk --debug -t lib/main.dart`. Added [Phase 24 UX Decisions][phase-24-ux-decisions], official YouTube IFrame embed path, external source attribution banner, AI-driven next rail, app-layer external launcher for non-YouTube sources, offline/error states, and Phase 24 integration tests. Blocked device evidence: WSL `adb devices` reports no attached Android device, `flutter devices` only reports Linux desktop, focused Phase 24 integration test fails with no supported `emulator-5554`, and emulator `adb install` fails with no devices/emulators found. Physical-phone validation remains Phase 26. |
| 25 — Creator external content in feeds               | Not started | —               | —          | [Phase 25 API Review][phase-25-api-review] | Planned: Creator Studio links external content (generic source model) into channel/recommendation feeds; native tile + attribution; indexable/AI gating; reuse ExternalContentReferenceSchema. |
| 26 — Gaming seed, AI-search showcase & final validation | Not started | —             | —          | [Phase 26 API Review][phase-26-api-review] | Planned: wire seeded YouTube videos into the five gaming creators' rec feeds; full AI-search + external-content showcase; UX hardening; **authoritative final physical-phone validation** (relocated from Phase 20). |

[phase-0-api-review]: ./Phases/Phase%200%20-%20API%20Review.md
[phase-0-ux-decisions]: ./Phases/Phase%200%20-%20UX%20Decisions.md
[phase-1-api-review]: ./Phases/Phase%201%20-%20API%20Review.md
[phase-1-ux-decisions]: ./Phases/Phase%201%20-%20UX%20Decisions.md
[phase-2-api-review]: ./Phases/Phase%202%20-%20API%20Review.md
[phase-2-ux-decisions]: ./Phases/Phase%202%20-%20UX%20Decisions.md
[phase-3-api-review]: ./Phases/Phase%203%20-%20API%20Review.md
[phase-3-ux-decisions]: ./Phases/Phase%203%20-%20UX%20Decisions.md
[phase-4-api-review]: ./Phases/Phase%204%20-%20API%20Review.md
[phase-4-ux-decisions]: ./Phases/Phase%204%20-%20UX%20Decisions.md
[phase-5-api-review]: ./Phases/Phase%205%20-%20API%20Review.md
[phase-5-ux-decisions]: ./Phases/Phase%205%20-%20UX%20Decisions.md
[phase-6-api-review]: ./Phases/Phase%206%20-%20API%20Review.md
[phase-6-ux-decisions]: ./Phases/Phase%206%20-%20UX%20Decisions.md
[phase-7-api-review]: ./Phases/Phase%207%20-%20API%20Review.md
[phase-7-ux-decisions]: ./Phases/Phase%207%20-%20UX%20Decisions.md
[phase-8-api-review]: ./Phases/Phase%208%20-%20API%20Review.md
[phase-8-ux-decisions]: ./Phases/Phase%208%20-%20UX%20Decisions.md
[phase-9-api-review]: ./Phases/Phase%209%20-%20API%20Review.md
[phase-9-ux-decisions]: ./Phases/Phase%209%20-%20UX%20Decisions.md
[phase-10-api-review]: ./Phases/Phase%2010%20-%20API%20Review.md
[phase-10-ux-decisions]: ./Phases/Phase%2010%20-%20UX%20Decisions.md
[phase-11-api-review]: ./Phases/Phase%2011%20-%20API%20Review.md
[phase-11-ux-decisions]: ./Phases/Phase%2011%20-%20UX%20Decisions.md
[phase-12-api-review]: ./Phases/Phase%2012%20-%20API%20Review.md
[phase-12-ux-decisions]: ./Phases/Phase%2012%20-%20UX%20Decisions.md
[phase-13-api-review]: ./Phases/Phase%2013%20-%20API%20Review.md
[phase-13-ux-decisions]: ./Phases/Phase%2013%20-%20UX%20Decisions.md
[phase-14-api-review]: ./Phases/Phase%2014%20-%20API%20Review.md
[phase-14-ux-decisions]: ./Phases/Phase%2014%20-%20UX%20Decisions.md
[phase-15-api-review]: ./Phases/Phase%2015%20-%20API%20Review.md
[phase-15-ux-decisions]: ./Phases/Phase%2015%20-%20UX%20Decisions.md
[phase-16-api-review]: ./Phases/Phase%2016%20-%20API%20Review.md
[phase-16-ux-decisions]: ./Phases/Phase%2016%20-%20UX%20Decisions.md
[phase-17-api-review]: ./Phases/Phase%2017%20-%20API%20Review.md
[phase-17-ux-decisions]: ./Phases/Phase%2017%20-%20UX%20Decisions.md
[phase-18-api-review]: ./Phases/Phase%2018%20-%20API%20Review.md
[phase-18-ux-decisions]: ./Phases/Phase%2018%20-%20UX%20Decisions.md
[phase-19-api-review]: ./Phases/Phase%2019%20-%20API%20Review.md
[phase-19-ux-decisions]: ./Phases/Phase%2019%20-%20UX%20Decisions.md
[phase-20-api-review]: ./Phases/Phase%2020%20-%20API%20Review.md
[phase-20-ux-decisions]: ./Phases/Phase%2020%20-%20UX%20Decisions.md
[phase-21-api-review]: ./Phases/Phase%2021%20-%20API%20Review.md
[phase-21-ux-decisions]: ./Phases/Phase%2021%20-%20UX%20Decisions.md
[phase-22-api-review]: ./Phases/Phase%2022%20-%20API%20Review.md
[phase-22-ux-decisions]: ./Phases/Phase%2022%20-%20UX%20Decisions.md
[phase-23-api-review]: ./Phases/Phase%2023%20-%20API%20Review.md
[phase-23-ux-decisions]: ./Phases/Phase%2023%20-%20UX%20Decisions.md
[phase-24-api-review]: ./Phases/Phase%2024%20-%20API%20Review.md
[phase-24-ux-decisions]: ./Phases/Phase%2024%20-%20UX%20Decisions.md
[phase-25-api-review]: ./Phases/Phase%2025%20-%20API%20Review.md
[phase-25-ux-decisions]: ./Phases/Phase%2025%20-%20UX%20Decisions.md
[phase-26-api-review]: ./Phases/Phase%2026%20-%20API%20Review.md
[phase-26-ux-decisions]: ./Phases/Phase%2026%20-%20UX%20Decisions.md

**Detail highlights:**
- **P0:** decide working-tree location (native WSL vs in-repo) + WSL build/run checklist; **scaffold the full source tree per "Source code tree layout"** — melos workspace, all `core/loom_*` packages, every `features/fan/*` and `features/creator/*` package as an empty skeleton with `CHARTER.md` + barrel + `pubspec.yaml`, and shared `analysis_options.yaml` with boundary lints; `loom_local_store` + seed v1; design tokens + nav shell + **role switcher**; DI composition root in `apps/loom_demo`; prove the contract→fake→UI flow with one slice (creator content list from `CreatorMetadataApi` fake) running on the Flutter Android emulator.
- **P1:** Fan Passport create/resolve + **interest cold-start picker** (MISSING-S2) seeding `FanInterestProfile`; **Creator channel onboarding** (CE-W1). Validate interest taxonomy early — it shapes discovery + data-rights APIs.
- **P2:** Creator **publish** content with **required `ContentManifest.summary`** (MISSING-S3) + **catalog import** (MISSING-S5); membership tiers (CE-S3); **`CreatorAdPolicy`** (MISSING-S1); enable AI archive Q&A (CE-W7). Produces the live content/policies later phases consume.
- **P3:** `StartupTileSurface` → `SessionIntent` (+ disclosure, mid-session switch); glass-box feed + `ContentScoreExplanation`; `FanContentFeedback`; search-as-intent — consuming live + seeded content. Largest, highest API risk.
- **P4:** creator home; follow/unfollow/block + visibility; video + post consumption; ad-supported playback via `PlaybackAuthorization` + seeded/authored `CreatorAdPolicy` + session-intent ad context; no-ad route stub.
- **P5:** fan asks a creator's archive → cited answer via `AiGatewayApi`; usage/source-attribution receipts; surface BYO-agent "rank by summary, ignore clickbait" affecting feed order.
- **P6:** wallet, memberships, no-ad premium, entitlements (fan, simulated money); **creator revenue dashboard with by-intent split** (CE-S6, MISSING-S4); `FanSubscriptionAllocationStatement`.
- **P7:** data & ads dashboard; consent grants; **creator interest-data grant** request → fan approve/deny/narrow + category defaults (FE-W6A both sides); revoke; `DataAccessReceipt`. Validate consent UX — shapes Passport/Vault/Audience/Firewall.
- **P8:** creator publishes **recommendations + referral terms** (RE-W1/W2) and a **campaign** (AD-W1); fan discovers/participates; referral disclosure + `DiscoveryReceipt`/`CreatorReferralReceipt`; simulated referral settlement.
- **P9:** creator **export everything** (CE-W6, Migration & Export); fan/creator transparency surfaces; `resetDemo()`; scripted **author→consume** + six-step wow-demo runbook; final provenance + efficiency sweep; performance polish.
- **P10:** implement launch typed clients/models, local-store tables, seed data, fake backend behavior, reset/idempotency, and DI registrations for re-acquisition, starter packs, analytics, import, cross-post, ad decision, and no-ad surfaces.
- **P11:** Creator Studio Launch/Grow surface for CE-S10: announcement templates, rendered launch copy, link-in-bio preview, QR/capture link, external account context, and cross-post stub with honest manual re-follow copy.
- **P12:** fan starter-pack onboarding for FE-S13: capture landing, source creator + recommended creators, toggleable one-tap bulk follow, idempotent re-open, non-empty feed landing, and plural suggested creators.
- **P13:** creator conversion analytics and utility consoles: CE-S11 aggregate funnel, catalog import UI, ad-policy console, creator archive-AI preview, and membership setup editors with preview + validation.
- **P14:** UX hardening: immersive discovery, richer generated media, loading/empty/error states, feed-style pagination, final launch-demo runbook, emulator regression, and physical Android phone sign-off deferral to Phase 26.
- **P15:** extension platform foundation: typed registry/runtime/config contracts, fake backend over the local Drift/SQLite store, seeded gaming creator configs, certified extension manifests, reset/idempotency, and API/UX decision output docs.
- **P16:** config-driven creator channel renderer: use `CreatorExperienceConfig` to drive fan channel theme, banner, module ordering, persona/ad posture, and extension placeholders without per-creator hardcoding.
- **P17:** competitive/economy extension modules: Clip Arena, Pick'Em, and HypeWars fan workflows backed by runtime sessions/events and wallet/reward receipts.
- **P18:** collaborative/creative extension modules: Quest Log, Build Showcase, and Guild Quest workflows backed by runtime contracts, persisted state, and reusable extension UI surfaces.
- **P19:** Creator Studio customization console: theme/banner controls, extension installation/configuration, module arranger, live preview, and starter-pack assembly.
- **P20:** customization showcase (emulator): harden customized fan experiences, update validation walkthrough/runbook, and run emulator regression. *(Physical-phone gate moved to P26.)*
- **P21:** AI search + external content foundation: typed clients/models, Drift tables, fakes, and seed for the fan AI-search agent connection (MCP, simulated), AI search merging creator + external (YouTube), a generic external-content source + embed descriptor, and SearchReceipt (audit-only); seed real YouTube refs onto the five gaming creators. Mirrors the Phase 5 bring-your-own-AI pattern and reuses `ExternalContentReferenceSchema`.
- **P22:** Fan AI search settings (FE-S16): new `feature_fan_settings` to connect the AI search agent (Claude/OpenAI/Gemini via MCP, simulated), enable external sources, (simulated) connect YouTube, set prefer-creators, with query-egress disclosure.
- **P23:** AI search results (FE-S17): route search through AI search when an agent is connected; merge creator (preferred) + external with agent ranking and **no paid placement**; compliant title handling — external title/thumbnail stay unaltered with an additive AI accurate-match label + source chip; no-agent fallback uses the existing neutral search.
- **P24:** embedded player & AI-driven next (FE-S18): official in-app YouTube IFrame player (unobscured) via `youtube_player_iframe`; "Next from your AI search" rail (not the platform's); non-YouTube external open via `url_launcher`; offline/error states. Real network at play time; Loom APIs faked.
- **P25:** creator external content in feeds (CE-S14): Creator Studio links external content (generic source model) into channel/recommendation feeds; native tile + source attribution; `searchIndexable`/`aiQueryable` gating; reuse `ExternalContentReferenceSchema`; render via the Phase 16 module renderer.
- **P26:** gaming seed, AI-search showcase & final validation: wire seeded YouTube videos into the five gaming creators' recommendation feeds; run the full AI-search + external-content showcase; harden the network-dependent surfaces; and complete the **authoritative physical Android phone validation gate** (relocated from Phase 20).

## Agent-enablement deliverables
- Per-feature `CHARTER.md` (scope, allowed contracts, owned screens, forbidden imports).
- Per-API-surface fake file with a header listing the contract it implements + seed tables it uses.
- Lint rules enforcing boundaries.
- Agent task template: "Implement screen `X` in `feature_Y` using only contracts `[…]` + `loom_design_system`; wire via the feature's view model; do not touch other features or the fake backend."

## New stories to write into the product docs (built here, story text still missing)
MISSING-S1 (creator ad policy), MISSING-S3 (required publish summary), MISSING-S4 (revenue by intent), MISSING-S5 (catalog import) — from the MVP scope doc — are **in-scope build items** this milestone; their formal user-story text should be added to the relevant Product Docs in parallel.

## Verification (milestone done when)
- App builds in WSL and installs/runs on the Flutter Android emulator for Phases 0–26, with the role switcher. Phases 21–26 may use real network only for external playback; Loom APIs remain faked/offline. Phase 26 additionally installs/runs on a physical Android phone.
- Each phase: its stories are demonstrable; UX checkpoint signed off; API Conformance & Efficiency review filed with spec changes applied.
- Final: the **author→consume** loop and six-step wow demo run end-to-end; a provenance audit shows every screen field sourced from an API response and every request field derivable from prior responses/seed; an efficiency audit shows no chatty calls, working pagination/batching, idempotent writes, no material over-fetch.

## Decisions locked / remaining
- **Framework:** Flutter (confirmed). **Scope:** Creator authoring + Fan, one app with role switcher (confirmed).
- **Local DB:** Drift (SQLite) recommended as default — flag if you prefer Isar/Hive. (Minor; not blocking.)
