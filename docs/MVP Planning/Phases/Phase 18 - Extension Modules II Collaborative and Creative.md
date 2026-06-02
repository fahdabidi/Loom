# Phase 18 — Extension Modules II: Collaborative & Creative

**Surface:** Fan App · **UX gate:** HIGH · **On green:** AUTO → Phase 19
**Shared conventions:** [README.md](./README.md).

> **Status:** Ready for execution after Phase 17. Completes the six showcase mechanics with the
> **collaborative/creative** extensions: **Quest Log**, **Build Showcase**, and **Guild Quest**. Same
> Extension Runtime primitive and reward/receipt path as Phase 17 — different mechanics and feel,
> emphasizing creation and community over competition.

## 0. Prerequisite gate (validate Phase 17 done)
README gate + confirm Phase 17 committed/recorded: Clip Arena, Pick'Em, and HypeWars run live via the
Extension Runtime and the `feature_extensions` host; Phase 17 integration tests pass.

## 1. Workflows & user stories in this phase
- **FE-S15 / Quest Log** — Fan views creator-set quests/challenges, completes one, earns a **badge**.
  Installed on **EmberHollow** and **IronVael** (cozy build quests vs guild objectives).
- **FE-S15 / Build Showcase** — Fan submits a build/screenshot to a **gallery** and the community votes;
  featured entries surface. Installed on **EmberHollow** and **IronVael**.
- **FE-S15 / Guild Quest** — Fans contribute to a **shared collaborative goal** with combined progress.
  Installed on **DriftAndChill** and **IronVael**.
- **CE-S13 (fan-visible result)** — Same extension renders differently per creator from install config.

## 2. Tools (WSL Ubuntu)
Standard set. Emulator screenshots of each module on at least two creators to show config-driven variation.

## 2A. UX reference research & decision output
Record in [Phase 18 - UX Decisions.md](./Phase%2018%20-%20UX%20Decisions.md):
- Quest/achievement systems: quest list, progress, completion, badge award, badge shelf.
- Community gallery/showcase UIs: submission, grid, voting, featured state.
- Collaborative/shared-goal UIs: combined progress bar, contributor list, milestone states.

Apply the shared baseline plus: modules render inside the channel surface; badges/galleries reuse the
reward/receipt path; collaborative progress reads clearly at phone width; empty states invite participation.

## 3. APIs invoked & stubs to implement
No new API surfaces. Reuse Phase 15 runtime/reward fakes:
- **Extension Runtime API:** sessions + events (complete quest, submit build, cast vote, contribute to goal) — idempotent.
- **Campaign / Reward + Receipt Ledger:** badge/reward issuance and receipts.
- **Extension Registry API:** read install config (quest set, gallery rules, shared-goal target).
- **Recommendation & Referral / Content Host:** featured-build ordering and media where relevant.

## 4. Data storage (local store)
Use the Phase 15 `extension_state` KV (and any dedicated tables) for: quests + completions + badges; build
submissions + votes + featured flags; guild-quest target + contributions + milestone state. Reward/badge
issuance writes through existing reward/receipt tables. Confirm `resetDemo()` clears these.

## 5. Source files & components to create/update
Design system (registered with the Phase 16 module registry):
- `core/loom_design_system/lib/components/extensions/quest_log_module.dart`
- `core/loom_design_system/lib/components/extensions/build_showcase_module.dart`
- `core/loom_design_system/lib/components/extensions/guild_quest_module.dart`
- Shared bits: `badge_chip.dart`, `submission_grid.dart`, `shared_progress_bar.dart`.

Feature:
- Extend `features/fan/feature_extensions` (from Phase 17) to start sessions and map runtime state for the
  three collaborative module types; wire them into the channel surface-module registry.

## 6. API best-practice checks (phase-specific)
- Complete/submit/vote/contribute events are idempotent; no double award on replay.
- Sessions scoped to approved permissions/surfaces; badges/rewards only via the reward+receipt path.
- Gallery and contributor reads are bounded/paginated; no "fetch all".
- Shared-goal progress is an aggregate; no per-fan behavioral leakage.

## 7. Component boundary / design checks
- Module widgets in `loom_design_system`; session logic in `feature_extensions`.
- No feature→feature/fake/store imports; `lint:boundaries` clean; charters updated.

## 8. Automated validation checks
README baseline plus unit/widget tests: quest completion → badge award; build submit → vote → featured
ordering; guild-quest contribution → combined progress math; idempotent events; reward/badge receipt
emission; config-driven variation across two creators per module.

## 9. Integration tests
- `it_p18_quest_log` — Fan completes a quest on EmberHollow, earns a badge, receipt recorded; badge appears on the shelf.
- `it_p18_build_showcase` — Fan submits a build, community vote updates ordering, featured state resolves.
- `it_p18_guild_quest` — Multiple contributions advance the shared goal to a milestone idempotently.
- `it_p18_same_extension_two_creators` — Quest Log renders with different config on EmberHollow vs IronVael.

## 10. Definition of done
Quest Log, Build Showcase, and Guild Quest run live via the Extension Runtime; badges/rewards reuse the
receipt path; the same extension visibly varies by creator config; all six showcase mechanics now work
across the five creators; all checks + integration tests green; screenshots captured.
[Phase 18 - API Review.md](./Phase%2018%20-%20API%20Review.md) and
[Phase 18 - UX Decisions.md](./Phase%2018%20-%20UX%20Decisions.md) filed; tracker updated with status, date,
API review, gate evidence, and commit SHA.

## 11. Next phase
After Phase 18 changes are committed and recorded, **AUTO-PROCEED: immediately begin
[Phase 19 — Creator Studio: Customize Fan Experience Console](./Phase%2019%20-%20Creator%20Studio%20Customize%20Console.md).**
