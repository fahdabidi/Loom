# Phase 17 — Extension Modules I: Competitive & Economy

**Surface:** Fan App · **UX gate:** HIGH · **On green:** AUTO → Phase 18
**Shared conventions:** [README.md](./README.md).

> **Status:** Ready for execution after Phase 16. Brings the **competitive/economy** extension mechanics
> to life as fan-facing runtime modules rendered in the channel's extension slots: **Clip Arena**,
> **Pick'Em**, and **HypeWars**. Each runs through the Extension Runtime (sessions + events + scoped
> permissions) and reuses the existing reward + receipt + wallet paths — proving the six extensions are
> one shared primitive, differently configured per creator.

## 0. Prerequisite gate (validate Phase 16 done)
README gate + confirm Phase 16 committed/recorded: the config-driven channel renderer and extension slots
exist; the five creators render as distinct worlds; Phase 16 integration tests pass.

## 1. Workflows & user stories in this phase
- **FE-S15 / Clip Arena** — Fan submits/upvotes a clip; sees a **seasonal ranked leaderboard**; a winner
  receives a reward. Installed on **NovaClutch** and **FrameByFrame** (different configs: best frags vs best runs).
- **FE-S15 / Pick'Em** — Fan predicts a match/run outcome and climbs a **pick'em ladder**. Installed on
  **NovaClutch** and **FrameByFrame**.
- **FE-S15 / HypeWars** — Fan sends a tip/hype that moves a **hype meter / tip-battle** tied to the Fan
  Wallet. Installed on **NovaClutch** and **DriftAndChill**.
- **CE-S13 (fan-visible result)** — The same extension renders differently per creator from install config.

## 2. Tools (WSL Ubuntu)
Standard set. Emulator screenshots of each module on at least two creators to show config-driven variation.

## 2A. UX reference research & decision output
Record in [Phase 17 - UX Decisions.md](./Phase%2017%20-%20UX%20Decisions.md):
- Clip-leaderboard and esports ladder UIs: submission entry, vote affordance, rank rows, season banner, winner state.
- Prediction/pick'em UIs: lock-before-start, pick state, resolved outcome, ladder standing.
- Tip/hype meters: progress toward a goal, contribution feedback, wallet confirmation, simulated-money labels.

Apply the shared baseline plus: modules render inside the channel surface (not full takeovers); wallet
actions reuse the Phase 6 purchase-sheet pattern; competitive states stay legible at phone width; all
money is simulated and labeled.

## 3. APIs invoked & stubs to implement
No new API surfaces. Reuse and extend Phase 15 fakes:
- **Extension Runtime API:** `createExtensionSession` (surface=channel module), `submitExtensionEvent`
  (submit clip, cast vote, make pick, send hype) — idempotent.
- **Campaign / Reward + Receipt Ledger:** winner reward issuance and reward receipts.
- **Fan Wallet / Entitlement Ledger:** HypeWars tips/hype (simulated) and any reward entitlements.
- **Extension Registry API:** read install config (season length, prize, prediction subject, hype goal).

## 4. Data storage (local store)
Use the Phase 15 `extension_state` KV (and any dedicated tables created there) for: clip submissions/votes
+ leaderboard standings; predictions + ladder standings; hype/tip meter totals + contribution log. Reward
issuance writes through the existing reward/receipt tables. Confirm `resetDemo()` clears these.

## 5. Source files & components to create/update
Design system (extension module widgets, registered with the Phase 16 module registry):
- `core/loom_design_system/lib/components/extensions/clip_arena_module.dart`
- `core/loom_design_system/lib/components/extensions/pick_em_module.dart`
- `core/loom_design_system/lib/components/extensions/hype_wars_module.dart`
- Shared bits: `leaderboard_row.dart`, `vote_button.dart`, `hype_meter.dart`.

Feature:
- `features/fan/feature_extensions` — fan runtime host: starts an extension session for a slot, submits
  events, maps runtime state → module view models, handles reward/wallet results. (New package; imports
  contracts + design system + app_shell only.)
- Wire the three module types into the channel surface-module registry so installed slots render live.

## 6. API best-practice checks (phase-specific)
- Submit/vote/pick/hype events are idempotent; no double-count on replay.
- Sessions are scoped to the install's approved permissions/surfaces; a module cannot act outside them.
- Rewards flow only through the Campaign/Reward + Receipt path; HypeWars uses Fan Wallet (simulated) — no bespoke economy.
- Leaderboard/ladder reads are bounded/paginated; no "fetch all".
- No per-fan behavioral data leaks into any creator-visible aggregate.

## 7. Component boundary / design checks
- Module widgets live in `loom_design_system`; runtime/session logic lives in `feature_extensions`.
- `feature_extensions` does not import other features, fakes, or the local store directly.
- `lint:boundaries` clean; charters updated.

## 8. Automated validation checks
README baseline plus unit/widget tests: clip submit→vote→leaderboard ordering; pick lock + ladder update;
hype contribution + wallet confirmation + meter math; idempotent event handling; reward receipt emission;
config-driven variation (same module, two creators, different config renders differently).

## 9. Integration tests
- `it_p17_clip_arena` — Fan submits a clip on NovaClutch, votes, leaderboard updates, winner reward emits a receipt.
- `it_p17_pick_em` — Fan makes a pick, outcome resolves, ladder standing updates idempotently.
- `it_p17_hype_wars` — Fan sends a simulated hype/tip via the wallet sheet; meter advances; receipt recorded.
- `it_p17_same_extension_two_creators` — Clip Arena renders with different config on NovaClutch vs FrameByFrame.

## 10. Definition of done
Clip Arena, Pick'Em, and HypeWars run live in their creators' channels via the Extension Runtime; rewards
and wallet actions reuse existing receipt/wallet paths; the same extension visibly varies by creator
config; all checks + integration tests green; screenshots captured. [Phase 17 - API Review.md](./Phase%2017%20-%20API%20Review.md)
and [Phase 17 - UX Decisions.md](./Phase%2017%20-%20UX%20Decisions.md) filed; tracker updated with status,
date, API review, gate evidence, and commit SHA.

## 11. Next phase
After Phase 17 changes are committed and recorded, **AUTO-PROCEED: immediately begin
[Phase 18 — Extension Modules II: Collaborative & Creative](./Phase%2018%20-%20Extension%20Modules%20II%20Collaborative%20and%20Creative.md).**
