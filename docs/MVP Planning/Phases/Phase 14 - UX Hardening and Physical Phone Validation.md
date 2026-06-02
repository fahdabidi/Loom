# Phase 14 — UX Hardening & Physical Phone Validation

**Surface:** both · **UX gate:** FINAL launch + phone · **On green:** STOP for final launch-demo sign-off
**Shared conventions:** [README.md](./README.md).

> **Status:** Ready for execution after Phase 13. This is the final launch-demo phase. It closes the
> remaining cross-cutting UX gaps (**U1**, **U2**, **U3**, **U7**), runs the full launch demo, and validates
> the APK on a physical Android phone.

## 0. Prerequisite gate (validate Phase 13 done)
README gate + confirm Phases 10-13 are committed and tracker-recorded. The launch acquisition loop,
starter-pack onboarding, conversion analytics, and creator utility consoles must all be green on the emulator.

## 1. Workflows & user stories in this phase
- **U1 / immersive discovery** — Add an immersive vertical/short-form discovery surface alongside the dense feed.
- **U2 / richer generated media** — Replace generic placeholders with richer generated/offline demo media across
  feed, channel, player, campaign, launch, starter-pack, and Studio preview surfaces.
- **U3 / loading-empty-error states** — Add reusable loading skeleton, empty state, and error state components and
  apply them on key async surfaces.
- **U7 / feed-style pagination** — Offer modern feed-style pagination while retaining explicit "Load more" hooks
  for deterministic integration tests.
- **Final launch demo** — Run re-acquisition → starter pack → consume → conversion analytics → utility consoles
  → export/reset end to end.
- **Physical phone validation** — Install, launch, and manually validate key flows on physical Android hardware.

## 2. Tools (WSL Ubuntu)
Standard set plus physical-phone adb setup:
- Use `adb devices` to confirm the physical phone is visible.
- Build with `flutter build apk --debug`.
- Install with `adb -s <phone_id> install -r build/app/outputs/flutter-apk/app-debug.apk`.
- Launch with `adb -s <phone_id> shell monkey -p com.example.loom_demo -c android.intent.category.LAUNCHER 1`.
- Capture emulator and phone screenshots into `data/validation/` (gitignored).

No external network dependency is allowed for app runtime. Generated media should be local assets.

## 2A. UX reference research & decision output
Before implementing final UX hardening, review:
- TikTok and Instagram Reels: full-height media, floating action rail, bottom metadata/action panel, safe-area behavior.
- YouTube Shorts and YouTube feed: dense vs immersive browsing transitions and creator metadata placement.
- Instagram/TikTok skeleton and empty-state conventions: polished async states without raw spinner/test harness feel.
- YouTube Studio / creator tools visual density: compact charts, cards, and preview surfaces at phone widths.
- Mobile accessibility and Material guidance: touch targets, safe areas, text wrapping, contrast, and scrolling behavior.

Apply the shared social-app UX baseline from [README.md](./README.md), plus these Phase 14 specifics:
- Immersive discovery must be reachable from Fan App discovery and remain visually distinct from dense feed.
- Media assets must make content inspectable: thumbnails/posters/avatars should signal creator/content category.
- Loading, empty, and error states must be reusable and applied to launch/starter-pack/analytics/discovery surfaces.
- Feed-style pagination can be automatic or near-automatic, but explicit test controls must remain stable.
- Phone validation must check safe areas, clipping, scrolling, and text overlap on physical hardware, not only emulator.

Create [Phase 14 - UX Decisions.md](./Phase%2014%20-%20UX%20Decisions.md) with references, extracted
patterns, key UX/implementation decisions, final launch-demo walkthrough, emulator screenshots, and physical-phone
validation notes.

## 3. APIs invoked & stubs to implement
No new API surfaces are expected. Reuse:
- **Search / Recommendation & Referral / Content Host APIs:** immersive discovery content.
- **Fan Follow Capture / Starter Pack / Audience Analytics APIs:** final launch-loop regression.
- **Playback Authorization / Ad Decision / Premium No-Ad APIs:** playback/ad/no-ad regression.
- **Migration & Export API:** final export/reset regression.

If final UX exposes a field not available from APIs, log it in Phase 14 API Review and fix the contract/fake before
shipping the screen.

## 4. Data storage (local store)
No new domain tables expected. Add only local asset references or seed metadata needed for richer generated media.
Verify `resetDemo()` restores seed media references and clears mutable launch/demo state.

## 5. Source files & components to create/update
Design system:
- `core/loom_design_system/lib/components/discovery/immersive_feed.dart`
- `core/loom_design_system/lib/components/loading_skeleton.dart`
- `core/loom_design_system/lib/components/empty_state.dart`
- `core/loom_design_system/lib/components/error_state.dart`
- Media/thumbnail helpers if needed for generated offline assets.

Features:
- `feature_discovery`: dense/immersive toggle, immersive feed state, feed-style pagination.
- `feature_creator_channel`, `feature_playback`, `feature_campaigns`, `feature_creator_launch`,
  `feature_fan_onboarding`, `feature_creator_revenue`, and Studio utility features: apply richer media and async states
  where the phase touches them.
- `loom_seed_data`: add or reference richer generated media assets without changing the vertical-agnostic seed world.

Validation:
- Update [../Phase Validation Walkthrough.md](../Phase%20Validation%20Walkthrough.md) if final manual steps change.
- Update [Demo Runbook.md](./Demo%20Runbook.md) with the launch loop.

## 6. API best-practice checks (phase-specific)
- Immersive feed uses paginated/bounded feed APIs, not "fetch all".
- Feed-style pagination does not create duplicate content or repeated receipts.
- Loading/error states do not trigger duplicate writes.
- Media fields are sourced from API/seed data; no UI-only magic content.
- Final full-demo provenance audit still passes: every screen field traces to response or seed.

## 7. Component boundary / design checks
- Immersive/feed components remain in design system or discovery feature as appropriate; no unrelated feature imports.
- Async state components are reusable and business-agnostic.
- Generated media assets are referenced through seed/API data, not hard-coded in feature widgets.
- All touched charters remain accurate.

## 8. Automated validation checks
README baseline plus:
- Widget tests for immersive feed rendering at emulator phone width.
- Widget tests for loading skeleton, empty state, and error state.
- Unit/widget tests for feed-style pagination and duplicate suppression.
- Regression tests for launch/starter-pack/analytics after media/state changes.
- Screenshot or golden-style smoke checks where practical to catch blank/overlapped immersive surfaces.

## 9. Integration tests
- `it_p14_immersive_discovery` — Fan opens immersive discovery, content renders full-height with action rail and bottom metadata.
- `it_p14_async_states` — Key async surfaces expose loading/empty/error states without layout breakage.
- `it_p14_feed_pagination` — Feed-style pagination loads additional content without duplicates and explicit test path still works.
- `it_p14_full_launch_demo` — Re-acquisition → starter pack → consume → conversion analytics → export/reset works end to end on emulator.
- Physical-phone manual validation: install APK, launch app, run key flows from [../Phase Validation Walkthrough.md](../Phase%20Validation%20Walkthrough.md),
  capture screenshots, and record device ID/model in the tracker.

## 10. Definition of done
UX gaps U1, U2, U3, and U7 are closed; final launch loop works end to end on the emulator; debug APK installs,
launches, and key flows pass on a physical Android phone; all automated checks and full integration tests are green;
[Phase 14 - API Review.md](./Phase%2014%20-%20API%20Review.md) and
[Phase 14 - UX Decisions.md](./Phase%2014%20-%20UX%20Decisions.md) are filed; the final launch loop is appended to
[Demo Runbook.md](./Demo%20Runbook.md); tracker is updated with Phase 14 completion date, commit SHA, API review,
emulator evidence, physical-phone device/evidence, and residual manual validation notes.

## 11. Next phase
END of the MVP + launch demo. Optional follow-ups: full extension marketplace, live/streaming formats, production
HTTP clients, deeper vertical-specific launch packs, and inventory cleanup of narrative-only APIs.
