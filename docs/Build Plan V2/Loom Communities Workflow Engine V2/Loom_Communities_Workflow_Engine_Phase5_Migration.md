# Phase 5 — Automated/Semi-Automated Migration of Remaining Communities

Part of [Loom_Communities_Workflow_Engine.md](./Loom_Communities_Workflow_Engine.md). Depends on
[Phase 4](./Loom_Communities_Workflow_Engine_Phase4_HOA.md) being fully closed, **including its
Milestone 4.4 generality finding** — that finding directly determines how much of this phase can be
mechanical (fixture JSON transformation) versus needing per-community judgment calls.

Status: not started. **Not designed in detail yet, deliberately** — a fresh planning pass happens once
Phase 4's actual findings are in hand, not guessed at now. This doc holds only the known targets and a
placeholder milestone shape; do not treat the validation-test bullets below as final until that
planning pass fills them in per community.

## 1. Scope & goal

Targets: Mosque, Book Club, Youth Soccer, Garden Club, Chess Club, Camera Club, and any others with
real fixture data. Each gets its own per-community doc already in this folder
([Mosque](./Loom_Communities_Workflow_Engine_Mosque.md),
[BookClub](./Loom_Communities_Workflow_Engine_BookClub.md),
[YouthSoccer](./Loom_Communities_Workflow_Engine_YouthSoccer.md),
[GardenClub](./Loom_Communities_Workflow_Engine_GardenClub.md),
[ChessClub](./Loom_Communities_Workflow_Engine_ChessClub.md),
[CameraClub](./Loom_Communities_Workflow_Engine_CameraClub.md)) with their tabs/cards/archetypes/
customizations already mapped — this phase reimplements each on the engine, it does not redesign them.

## 2. Placeholder milestone shape (one per community, to be filled in after Phase 4)

For each community: `Milestone 5.<n> — <Community> tab reimplementation`, following the same
evidence-bar shape used in every prior phase:
- [ ] Community's workflow fixtures parse and pass the Phase 1 §7c validator.
- [ ] Full behavioral-parity widget-test suite against the community's existing tab implementation,
  one test per interaction named in its own per-community doc.
- [ ] Live emulator walk with screenshot evidence for each reimplemented tab.
- [ ] Full `flutter test` suite green, exact pass count cited, zero regressions elsewhere.
- [ ] A generality finding, same shape as Phase 4 Milestone 4.4, per community (or waived if Phase 4's
  finding already established the schema needs zero further changes and this phase turns out to be
  purely mechanical — decide during the fresh planning pass, not here).

## 3. What the fresh planning pass (post-Phase-4) needs to determine
- Migration order across the 6 remaining communities — likely sequenced by how much each diverges
  from patterns Phases 1-4 already proved (Garden Club/Camera Club were noted in Phase 4 as
  dominated by already-proven loan/giveaway + RSVP patterns — likely earliest/most mechanical; Mosque
  was the Phase-4 runner-up specifically because Care/protected-vault and Admin/volunteer-signup are
  still novel — likely needs the same scrutiny Phase 4 gave HOA).
- How much of the migration can be scripted (JSON transformation from existing fixture shapes into the
  engine schema) versus requiring hand authoring per community.
- Whether any community surfaces a genuinely new archetype or guard/effect need beyond the 15+1
  cataloged in Phase 1 §2b — if so, that's a signal this phase isn't purely mechanical after all and
  needs its own Phase-4-style generality finding before continuing to the next community.
