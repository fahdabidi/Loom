# Phase 2 — Extend archetypes for the other communities' real needs

Part of [Loom_Communities_Workflow_Engine.md](./Loom_Communities_Workflow_Engine.md). Depends on
[Phase 1](./Loom_Communities_Workflow_Engine_Phase1_TabletopClub.md) being fully closed, **including
milestone 1.20's manual human sign-off** — this phase does not start on automated-green alone.

Status: not started.

**Handoff:** implementation is invoked directly via `data/call_implementation_agent.sh` (see the main
tracker's [§5 Handoff protocol](./Loom_Communities_Workflow_Engine.md#5-handoff-protocol)).

## 1. Scope & goal

Re-read each existing community's design doc
([HOA](../Loom%20Communities%20Workflow%20Engine%20V2/Loom_Communities_Workflow_Engine_HOA.md),
[Mosque](../Loom%20Communities%20Workflow%20Engine%20V2/Loom_Communities_Workflow_Engine_Mosque.md),
[BookClub](../Loom%20Communities%20Workflow%20Engine%20V2/Loom_Communities_Workflow_Engine_BookClub.md),
[YouthSoccer](../Loom%20Communities%20Workflow%20Engine%20V2/Loom_Communities_Workflow_Engine_YouthSoccer.md),
[GardenClub](../Loom%20Communities%20Workflow%20Engine%20V2/Loom_Communities_Workflow_Engine_GardenClub.md),
[CameraClub](../Loom%20Communities%20Workflow%20Engine%20V2/Loom_Communities_Workflow_Engine_CameraClub.md),
[ChessClub](../Loom%20Communities%20Workflow%20Engine%20V2/Loom_Communities_Workflow_Engine_ChessClub.md))
against the now-real
[Archetype Implementation Standard](./Loom_Communities_Workflow_Engine_Archetype_Implementation_Standard.md),
and extend/modify archetypes as needed to cover whatever those docs call for that Tabletop Club's own
feature set didn't happen to exercise. This phase is explicitly about closing *remaining* gaps
discovered by confronting real community requirements — **not** about touching the communities' own
JSON, which is [Phase 3's](./Loom_Communities_Workflow_Engine_Phase3_Skill.md) job via the Skill.

Per-community scrutiny points, identified from each doc during planning (each milestone below states
whether it's a validation pass — the archetype already covers this community's need — or new scope):
- **Mosque**: field-level `protectedDetail` masking by viewer identity is a stricter case than anything
  in Tabletop Club (per-field visibility, not just per-instance) — likely new scope beyond milestone
  1.15's formula pattern. Volunteer roster "open-spots-vs-filled counter" and donation totals per fund
  are direct applications of the arithmetic/grouped-aggregate vocabulary — likely validation passes.
- **Book Club**: `votePoll` needs re-validation against the richer Tournament+Voting implementation —
  Book Club's ballot is simpler (no eligibility guard, no rich candidates), so this is likely scope
  reduction/validation, not new work. Library/browse-many and Discussion threads map directly to
  milestones 1.6/1.7.
- **Youth Soccer**: `guidedProcess` already real (Youth Soccer's own registration wizard) — validation
  pass. Protected minor data is a second `protectedDetail` stress case alongside Mosque's.
  Sortable roster table maps to milestone 1.6.
- **Chess Club**: standings rank/delta is a direct `sortBy`/arithmetic formula application (validation
  pass against milestone 1.1's vocabulary) — re-verify against `_rankingsEffect`'s existing correct
  behavior, don't regress it.
- **Garden Club / Camera Club**: mostly validation passes — `calendarAgenda`, `stateMachineGrid`
  loan/giveaway, `formEntry`, `discussionThread` all map to already-`[x]` Phase 1 archetypes.
- **HOA**: dues due/overdue (date-arithmetic formula), "who's paid" ledger (grouped/filtered aggregate)
  — direct vocabulary applications; re-verify against the existing real `_ArchitecturalRequestTabSurface`
  implementation, don't regress it.

## 2. Milestones

One per community. Each starts `[ ]` Not started; the implementation agent determines during kickoff
whether the community's needs are a validation pass or require new archetype scope, and states which
explicitly in its submission note (mirroring V2 Phase 5's per-community generality-note pattern).

### Milestone 2.1 — Garden Club
**Status:** `[ ]` Not started.
- [ ] Re-verify `calendarAgenda`, `stateMachineGrid` (tool loan/giveaway), `formEntry`,
  `discussionThread`, `exportWizard`, `volunteerRoster` against Garden Club's actual documented needs
  using the now-real Phase 1 implementations — no regression against V2's existing working migration.
- [ ] State explicitly whether this was a validation pass or required new archetype scope.
- [ ] Full suite green, live emulator walk, exact counts cited.

### Milestone 2.2 — Camera Club
**Status:** `[ ]` Not started.
- [ ] Re-verify `calendarAgenda` (photo-walk RSVP), `stateMachineGrid` (gear loan), and the
  `formEntry`+`stateMachineGrid`+`discussionThread` critique composition against Phase 1's real
  implementations.
- [ ] State explicitly whether this was a validation pass or required new archetype scope.
- [ ] Full suite green, live emulator walk, exact counts cited.

### Milestone 2.3 — Book Club
**Status:** `[ ]` Not started.
- [ ] Re-verify `votePoll` against the Tournament+Voting implementation (§3 of Phase 1) — Book Club's
  ballot is a simpler case (no eligibility guard requirement per its own doc); confirm the general
  Repeater+formula ballot correctly handles it without a Tabletop-specific carve-out.
- [ ] Re-verify Library (`stateMachineGrid`), Discussions (`discussionThread`), `notificationInbox`,
  `documentLibrary`, `searchAiAnswer` against Phase 1's real implementations.
- [ ] State explicitly whether this was a validation pass or required new archetype scope.
- [ ] Full suite green, live emulator walk, exact counts cited.

### Milestone 2.4 — Chess Club
**Status:** `[ ]` Not started.
- [ ] Re-verify standings `table`+`rankingMode` against milestone 1.1's `sortBy`/arithmetic formula
  vocabulary — confirm the existing correct `_rankingsEffect` behavior (real per-match computed
  deltas, not hardcoded literals) is preserved or improved, not regressed, when moved onto formulas.
- [ ] Re-verify `formEntry` (result), `statusTimeline`, `calendarAgenda`, `dashboard`, `exportWizard`.
- [ ] State explicitly whether this was a validation pass or required new archetype scope.
- [ ] Full suite green, live emulator walk, exact counts cited.

### Milestone 2.5 — Youth Soccer
**Status:** `[ ]` Not started.
- [ ] Re-verify `guidedProcess` (registration wizard) — already real, confirm it still matches Phase 1's
  finalized standard with no drift.
- [ ] Re-verify `protectedDetail` for minor data — second stress case alongside Mosque (milestone 2.6);
  confirm the real guardian-identity relationship gating (already fixed during V2's M5.5) composes
  correctly with the new field-masking formula pattern from Phase 1 milestone 1.15.
- [ ] Re-verify roster `table`, `paymentCheckout`, `exportWizard` (minor-redaction preview mandatory).
- [ ] State explicitly whether this was a validation pass or required new archetype scope.
- [ ] Full suite green, live emulator walk, exact counts cited.

### Milestone 2.6 — Mosque
**Status:** `[ ]` Not started. Highest-scrutiny milestone in this phase.
- [ ] Extend `protectedDetail` for genuine field-level masking by viewer identity (not just
  per-instance) — likely new scope beyond milestone 1.15's baseline; if new scope is needed, it must
  still be expressed as a formula (per-field `if($viewer==..., full, masked)`), never per-community
  Dart.
- [ ] Re-verify `volunteerRoster` (open-spots-vs-filled counter — arithmetic formula), donation totals
  per fund (grouped aggregate), `audienceSelector` (Repeater checkable list), `notificationInbox`
  (privacy-safe — confirm no care-request detail leaks through a notification card).
- [ ] State explicitly whether each surface was a validation pass or required new archetype scope.
- [ ] Full suite green, live emulator walk, exact counts cited.

### Milestone 2.7 — HOA
**Status:** `[ ]` Not started.
- [ ] Extend dues due/overdue display via the date-arithmetic formula vocabulary; "who's paid" ledger
  via grouped/filtered aggregate read.
- [ ] Re-verify `documentLibrary`, `formEntry`/`statusTimeline` (Requests+Board), `paymentCheckout`
  against the existing real `_ArchitecturalRequestTabSurface`/`_DocumentsTabSurface`/`_GivingTabSurface`
  implementations — no regression.
- [ ] State explicitly whether this was a validation pass or required new archetype scope.
- [ ] Full suite green, live emulator walk, exact counts cited.

### Milestone 2.8 — Phase close-out
**Status:** `[ ]` Not started.
- [ ] All 7 community milestones `[x]`.
- [ ] [Archetype_Implementation_Standard.md](./Loom_Communities_Workflow_Engine_Archetype_Implementation_Standard.md)
  updated with any Phase-2-discovered extensions (e.g. field-level masking) and their status.
- [ ] Full combined suite green across all packages, exact count cited — this is the last automated
  gate before Phase 3 (the Skill) begins.
