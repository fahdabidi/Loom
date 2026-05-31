# Phase 1 — Identity & Onboarding

**Surface:** both · **UX gate:** HIGH · **On green:** STOP for manual UX validation
**Shared conventions:** [README.md](./README.md). This doc adds Phase-1 specifics.

## 0. Prerequisite gate (validate Phase 0 done)
Run the README prerequisite gate. Specifically confirm: workspace bootstraps, role switcher works, the `CreatorMetadataApi` content-list slice renders from the fake on the Flutter Android emulator, boundary lints pass. If not green → finish Phase 0 first.

## 1. Workflows & user stories in this phase
- **FE-W1** — Fan onboarding & first follow.
- **MISSING-S2** — Fan interest cold-start picker (build it; story text still to be added to Doc 03). Pick ≥10 interest categories → seeds `FanInterestProfile`.
- **FE-S1A** — Fan changes relationship visibility (public/private baseline).
- **CE-S1 / CE-W1 (steps 1–6) / CE-W1A** — Creator channel onboarding + free managed hosting acceptance (publishing is Phase 2).

## 2. Tools (WSL Ubuntu)
Standard set from README. New seed assets for the interest taxonomy added to `loom_seed_data`.

## 2A. UX reference research & decision output
Before implementing onboarding UX, review reference mockups and design guidance from popular social apps such as YouTube, Instagram, TikTok, Facebook, WhatsApp, and adjacent creator/fan products. Focus on account creation, interest cold-start pickers, follow prompts, privacy defaults, persona/profile switching, creator channel setup, and first-run progressive disclosure.

Create [Phase 1 - UX Decisions.md](./Phase%201%20-%20UX%20Decisions.md) summarizing references reviewed, UX patterns extracted, key UX and implementation decisions, and a walkthrough of how the implemented onboarding UX demonstrates FE-W1, MISSING-S2, FE-S1A, CE-S1, CE-W1, and CE-W1A using the collected guidance.

## 3. APIs invoked & stubs to implement
- **Fan Passport API:** `createPassport`, `getPassport`, `setPersona`, `createFollow`, `setFollowVisibility`, baseline `createConsentGrant`. Fake: `FanPassportFake`.
- **Fan Vault API:** `getInterestProfile`, `putInterests` (batch), `putDislikes`, `getAdPreferences`. Fake: `FanVaultFake`.
- **Creator Channel Registry API:** `createChannel`, `bindHandle`, key records. Fake: `CreatorChannelRegistryFake`.
- **Creator Metadata API:** `createChannelProfile` (+ initial `CreatorChannelManifest`), `attachHostingContract` (managed default). Extend `CreatorMetadataFake`.

## 4. Data storage (local store)
New tables: `fan_passports`, `personas`, `follows(creatorId, visibility, blocked)`, `consent_grants`, `fan_interest_profile(interests[], dislikedInterests[], dislikedCreators[], mutedProviders[])`, `ad_preferences`, `creator_channels`, `channel_manifests`, `hosting_contracts`. Seed: **interest taxonomy** (`assets/seed/interest_taxonomy.json` — categories + tokens) for the picker; 1 managed-host record.

## 5. Source files & components to create/update
- `core/loom_api_contracts/clients/`: fill `fan_passport_api.dart`, `fan_vault_api.dart`, `creator_channel_registry_api.dart`; extend `creator_metadata_api.dart`. Add models: `FanPassportClaim`, `Persona`, `FollowView`, `InterestProfile`, `InterestToken`, `CreatorChannel`, `CreatorChannelManifest`.
- `core/loom_fake_backend/`: `fan_passport_fake.dart`, `fan_vault_fake.dart`, `creator_channel_registry_fake.dart`; extend `creator_metadata_fake.dart`.
- `core/loom_local_store/`: tables above + DAOs; extend `resetDemo()` + seed loader for taxonomy.
- `core/loom_design_system/components/`: `interest_chip_grid.dart`, `persona_selector.dart`, `onboarding_scaffold.dart`, `channel_setup_form.dart`.
- `features/fan/feature_fan_onboarding/`: screens `welcome`, `passport_create`, `interest_picker`, `privacy_mode`, `first_follow`; state notifiers; mappers. Update `CHARTER.md`.
- `features/creator/feature_creator_onboarding/`: screens `channel_create`, `handle_profile`, `managed_hosting_accept`; state; mappers. Update `CHARTER.md`.

## 6. API best-practice checks (phase-specific)
- `createPassport` and `createChannel` are **idempotent** (`Idempotency-Key`); re-submit returns the same entity, no duplicates.
- Interest taxonomy fetched **once** and cached for the session — not re-fetched per screen.
- Interest selections written in **one batched** `putInterests` call (not one call per chip).
- `InterestProfile` payload carries only tokens + minimal metadata the UI shows.
- Provenance: `createFollow` uses a `creatorId` obtained from a prior catalog/search response.

## 7. Component boundary / design checks
- `feature_fan_onboarding` and `feature_creator_onboarding` import only contracts + design_system + app_shell. Confirm via `melos run lint:boundaries`.
- Interest picker UI components live in `loom_design_system` (reused later by data-rights). No API logic in components.

## 8. Automated validation checks
README baseline (analyze, boundaries, test, build APK). Unit tests for interest-profile mapper and onboarding notifiers.

## 9. Integration tests
- `it_p1_FE-W1` — create passport → first follow recorded with visibility; appears in fan state.
- `it_p1_interest_coldstart` — pick ≥10 interests → `FanInterestProfile` persisted via one batched write.
- `it_p1_FE-S1A` — toggle follow visibility → state updates, prior receipts retained.
- `it_p1_CE-W1` — create channel + handle + managed hosting accepted → `CreatorChannel` + `CreatorChannelManifest` + `HostingContract` persisted.

## 10. Definition of done
All four story groups demonstrable on the Flutter Android emulator; interest taxonomy drives the picker; creator channel + fan passport created via idempotent calls; all checks green; API Review filed; UX Decisions doc filed. Update the Phase completion tracker in [../Demo App Implementation Plan.md](../Demo%20App%20Implementation%20Plan.md) with Phase 1 status, completion date, API review link/name, and gate evidence before marking this phase complete. Commit all Phase 1 changes to git and record the commit SHA in the tracker before proceeding.

## 11. Next phase
**STOP for manual UX validation.** The interest picker and creator onboarding define the **interest taxonomy** and identity payloads that shape discovery (Phase 3) and data-rights (Phase 7) APIs. Get human sign-off on: interest taxonomy granularity, picker UX, persona/privacy defaults, channel-setup flow. After sign-off, proceed to [Phase 2 — Creator Publishing & Monetization Setup](./Phase%202%20-%20Creator%20Publishing%20and%20Monetization%20Setup.md).
