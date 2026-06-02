# Phase 26 — Gaming Seed, Full AI-Search Showcase & Final Physical-Phone Validation

**Surface:** both · **UX gate:** FINAL launch + customization + AI-search + phone · **On green:** STOP for final sign-off
**Shared conventions:** [README.md](./README.md).

> **Status:** Ready for execution after Phase 25. **This is the final phase of the whole demo.** It wires the
> seeded YouTube videos into the five gaming creators' recommendation feeds, ties the AI-search + external-content
> story into one scripted showcase, hardens the new surfaces, and runs the **authoritative final physical-phone
> validation** — relocated here from Phase 20 (Phase 20 is now emulator-only). On green, the entire demo
> (launch + customization + AI search) is signed off.

## 0. Prerequisite gate (validate Phases 21–25 done)
README gate + confirm Phases 21–25 committed/recorded: AI-search foundation, fan settings/connections, merged
results with compliant titles, embedded player + AI-next, and creator external linking are all green on the
emulator. Confirm the five gaming creators (Phase 15) and their seeded YouTube refs (Phase 21) exist.

## 1. Workflows & user stories in this phase
- **Gaming external-content seed** — Wire the seeded YouTube videos into the **recommendation feeds** of the five
  gaming creators (NovaClutch, EmberHollow, FrameByFrame, DriftAndChill, IronVael); they render as native tiles and play in-app.
- **Full AI-search showcase (end to end)** — Connect a (simulated) AI agent → run a search → merged creator+external
  results with **compliant de-ragebaited** presentation → play a YouTube video in the **in-app embedded player** →
  the **"next" rail is AI-search-driven** → open a gaming creator and play a **creator-linked** YouTube tile.
- **UX hardening on new surfaces** — Apply richer media + loading/empty/error states (Phase 14 components) to the
  AI-search results, settings, embedded player, and external tiles.
- **Final physical-phone validation** — Install, launch, and manually validate the full demo (launch + customization
  + AI search) on a **physical Android phone**, including real YouTube playback over the network.

## 2. Tools (WSL Ubuntu)
Standard set plus physical-phone adb (relocated from Phase 20): `adb devices`; `flutter build apk --debug`;
`adb -s <phone_id> install -r build/app/outputs/flutter-apk/app-debug.apk`;
`adb -s <phone_id> shell monkey -p com.example.loom_demo -c android.intent.category.LAUNCHER 1`.
**Network required** on emulator + phone for YouTube playback. Capture emulator + phone screenshots into `data/validation/` (gitignored).

## 2A. UX reference research & decision output
Record in [Phase 26 - UX Decisions.md](./Phase%2026%20-%20UX%20Decisions.md):
- Showcase/demo-script patterns that make the AI-search + external-content story obvious end to end.
- Polished async/empty/error + offline states on the network-dependent surfaces (the embedded player especially).
- Phone-validation checklist: safe areas, clipping, scrolling, text overlap, theme contrast, and **real external playback** on hardware.

Apply the shared baseline plus: the showcase makes the "bring your own AI to search the open web, de-ragebaited,
creator-preferred" story unmistakable; the embedded player degrades gracefully offline; attribution/compliance hold on hardware.

## 3. APIs invoked & stubs to implement
No new API surfaces. Reuse: AI Gateway (`runAiSearch`), External Content Source, Search, Recommendation & Referral,
Creator Metadata, Fan Vault, Playback/Receipt, plus the YouTube IFrame player (external). Any missing field → log in
Phase 26 API Review and fix the contract/fake/seed before shipping.

## 4. Data storage (local store)
No new domain tables. Ensure the gaming YouTube refs are wired into the creators' recommendation-feed surfaces.
Verify `resetDemo()` restores all seed (creators, configs, external refs) and clears mutable search/agent/play state.

## 5. Source files & components to create/update
- `loom_seed_data`: attach the seeded YouTube refs to the five gaming creators' recommendation feeds / content modules.
- Apply Phase 14 async-state + richer-media components to: AI-search results, `feature_fan_settings`, the embedded
  player surface, and external tiles.
- Validation/docs: update [Demo Runbook.md](./Demo%20Runbook.md) with the AI-search + external-content showcase loop,
  and [../Phase Validation Walkthrough.md](../Phase%20Validation%20Walkthrough.md) with final manual steps (incl. physical phone).

## 6. API best-practice checks (phase-specific)
- Showcase uses bounded/paginated reads; no "fetch all"; AI-search calls bounded.
- Full provenance audit passes (every screen field traces to API/seed); external title compliance holds across all surfaces.
- Export/reset regression still reconciles and clears mutable AI-search/external state.
- No Loom ads over external embeds; attribution retained; official player unobscured.

## 7. Component boundary / design checks
- Async/media components remain reusable/business-agnostic in `loom_design_system`.
- No unrelated feature imports introduced during polish; `lint:boundaries` clean; all touched charters accurate.

## 8. Automated validation checks
README baseline plus: regression across launch (11–14), customization (15–20), and AI-search (21–25) suites;
widget tests that async/offline states apply on the network-dependent surfaces; screenshot/golden smoke checks for
AI-search results + embedded player + gaming external tiles; full integration suite green on the emulator.

## 9. Integration tests
- `it_p26_gaming_external_seed` — Each gaming creator's recommendation feed includes a native YouTube tile that opens the embedded player.
- `it_p26_ai_search_showcase` — End to end: connect agent → AI search (creator+external, compliant titles) → play YouTube in-app → AI-driven next → creator-linked external tile plays.
- `it_p26_offline_states` — Network-dependent surfaces show graceful offline/error states.
- `it_p26_full_regression` — Launch + customization + AI-search loops run together on the emulator.
- Physical-phone manual validation: install APK, launch, run the full walkthrough (incl. real YouTube playback), capture screenshots, record device ID/model.

## 10. Definition of done
The five gaming creators have playable YouTube content in their feeds; the full AI-search + external-content
showcase runs end to end on the emulator; new surfaces use richer media + async/offline states; the debug APK
installs, launches, and **all key flows (incl. real external playback) pass on a physical Android phone**; all
automated checks and the full launch + customization + AI-search integration suite are green;
[Phase 26 - API Review.md](./Phase%2026%20-%20API%20Review.md) and
[Phase 26 - UX Decisions.md](./Phase%2026%20-%20UX%20Decisions.md) are filed; the AI-search showcase loop is
appended to [Demo Runbook.md](./Demo%20Runbook.md); the tracker is updated with Phase 26 completion date, commit
SHA, API review, emulator evidence, and **physical-phone device/evidence**.

## 11. Next phase
END of the MVP + launch + customization + AI-search demo. Optional follow-ups: real YouTube Data API + Google/
Twitch OAuth (live external search + account login), full Twitch embedded player, real MCP agent connections,
more external source types, and production HTTP clients.
