# Phase 20 — Customization Showcase, UX Hardening & Final Physical-Phone Validation

**Surface:** both · **UX gate:** FINAL launch + customization + phone · **On green:** STOP for final sign-off
**Shared conventions:** [README.md](./README.md).

> **Status:** Ready for execution after Phase 19. This is the **final phase of the whole demo**. It ties
> the customization sequence into one scripted showcase, applies UX-hardening polish to the new surfaces,
> updates the runbook, and runs the **authoritative final physical-phone validation** (relocated here from
> Phase 14). On green, the launch + customization demo is signed off.

## 0. Prerequisite gate (validate Phases 15–19 done)
README gate + confirm Phases 15–19 committed/recorded: extension platform + config model, config-driven
renderer, all six extension modules, and the Studio customize console + gaming starter pack are green on
the emulator. Confirm Phase 14 UX-hardening components (immersive feed, skeleton/empty/error states) exist.

## 1. Workflows & user stories in this phase
- **Customization showcase (end to end)** — One fan, one passport/wallet/follow graph, visits all five
  gaming creators and experiences five distinct worlds (theme, surfaces, extensions, AI persona, ad
  posture); enters one extension per creator and earns a reward/badge; then the demo switches to Creator
  Studio to show a creator **authoring** that experience (theme + install/configure extension + arrange +
  preview), with a live change propagating to the fan channel.
- **Gaming starter-pack onramp** — A new fan onboards via the gaming starter pack (Phase 12 + Phase 19) and
  lands directly into the customized gaming segment.
- **UX hardening on new surfaces** — Apply richer generated media and reusable loading/empty/error states
  (Phase 14 components) to channel/theme, extension modules, and the Studio customize console.
- **Final physical-phone validation** — Install, launch, and manually validate the full launch +
  customization demo on a physical Android phone.

## 2. Tools (WSL Ubuntu)
Standard set plus physical-phone adb (as in the former Phase 14):
- `adb devices`; `flutter build apk --debug`; `adb -s <phone_id> install -r build/app/outputs/flutter-apk/app-debug.apk`;
  `adb -s <phone_id> shell monkey -p com.example.loom_demo -c android.intent.category.LAUNCHER 1`.
- Capture emulator + phone screenshots into `data/validation/` (gitignored). No runtime network.

## 2A. UX reference research & decision output
Record in [Phase 20 - UX Decisions.md](./Phase%2020%20-%20UX%20Decisions.md):
- Showcase/demo-script patterns: a guided path that makes the "five worlds + creator authoring" contrast obvious.
- Polished async/empty/error states and richer generated media applied to the new customization surfaces.
- Phone-validation checklist: safe areas, clipping, scrolling, text overlap, theme contrast on real hardware.

Apply the shared baseline plus: the showcase must make the **creator-authored difference** unmistakable;
new surfaces must use the reusable async-state components; generated media must signal each creator's vibe
without external assets.

## 3. APIs invoked & stubs to implement
No new API surfaces. Reuse: Extension Registry/Runtime, Creator Experience Config, AI Gateway, Ad Decision,
Recommendation & Referral / Starter Pack, Fan Follow Capture, Playback Authorization, Campaign/Reward,
Migration & Export (export/reset regression). Any missing field → log in Phase 20 API Review and fix the
contract/fake/seed before shipping the screen.

## 4. Data storage (local store)
No new domain tables. Add only local asset references/seed metadata for richer generated media. Verify
`resetDemo()` restores seed creators, extensions, installs, and `CreatorExperienceConfig`, and clears
mutable extension/session/reward state.

## 5. Source files & components to create/update
- Apply Phase 14 components (`loading_skeleton.dart`, `empty_state.dart`, `error_state.dart`, richer media)
  to: `feature_creator_channel` (theme/banner/modules), `feature_extensions` (all six modules),
  `feature_creator_customize` (console + preview), and the gaming starter-pack onboarding path.
- `loom_seed_data`: richer generated media for the five gaming creators (offline, no external assets).
- Validation/docs: update [Demo Runbook.md](./Demo%20Runbook.md) with the customization showcase loop and
  [../Phase Validation Walkthrough.md](../Phase%20Validation%20Walkthrough.md) with final manual steps.

## 6. API best-practice checks (phase-specific)
- Showcase uses bounded/paginated reads; no "fetch all" across creators or modules.
- Loading/error states never trigger duplicate writes; extension events stay idempotent under the demo script.
- Every screen field traces to an API response or seed (full provenance audit passes).
- Export/reset regression still reconciles receipts and clears mutable customization state.

## 7. Component boundary / design checks
- Async-state and media components remain reusable/business-agnostic in `loom_design_system`.
- No unrelated feature imports introduced during polish; `lint:boundaries` clean; all touched charters accurate.

## 8. Automated validation checks
README baseline plus: regression tests for all six extensions and the five-creator render after media/state
changes; widget tests that async states apply on the new surfaces; screenshot/golden smoke checks for the
five themed channels and the Studio preview; full launch + customization integration suite green.

## 9. Integration tests
- `it_p20_customization_showcase` — One fan traverses all five creator worlds, enters an extension per
  creator and earns a reward/badge, then a Studio reconfigure propagates to the fan channel — end to end.
- `it_p20_starter_pack_onramp` — New fan onboards via the gaming starter pack and lands in the customized segment.
- `it_p20_async_states_on_new_surfaces` — Channel/extension/console surfaces expose loading/empty/error states without layout breakage.
- `it_p20_full_demo_regression` — Launch loop (Phases 11–14) + customization (Phases 15–19) + export/reset run together on the emulator.
- Physical-phone manual validation: install APK, launch, run the full walkthrough, capture screenshots, record device ID/model.

## 10. Definition of done
The customization showcase runs end to end on the emulator (five distinct worlds + creator authoring +
starter-pack onramp); new surfaces use richer media and loading/empty/error states; the debug APK installs,
launches, and key flows pass on a **physical Android phone**; all automated checks and the full launch +
customization integration suite are green; [Phase 20 - API Review.md](./Phase%2020%20-%20API%20Review.md) and
[Phase 20 - UX Decisions.md](./Phase%2020%20-%20UX%20Decisions.md) are filed; the customization showcase loop
is appended to [Demo Runbook.md](./Demo%20Runbook.md); the tracker is updated with Phase 20 completion date,
commit SHA, API review, emulator evidence, and physical-phone device/evidence.

## 11. Next phase
END of the MVP + launch + customization demo. Optional follow-ups: real extension marketplace + third-party
extension certification, live/streaming extension surfaces, production HTTP clients, additional vertical
showcases beyond gaming, and inventory cleanup of any remaining narrative-only APIs.
