# Archetype Implementation Standard

Part of [Loom_Communities_Workflow_Engine.md](./Loom_Communities_Workflow_Engine.md). Reference doc —
the living status table every phase reads and Phase 1 updates as each archetype is actually built.
Base per-archetype JSON field schemas stay in
[V2's Archetype Catalog](../Loom%20Communities%20Workflow%20Engine%20V2/Loom_Communities_Workflow_Engine_Archetype_Catalog.md)
(§2 — not duplicated here); this doc adds the implementation-status axis V2 never tracked: is the UI
genuinely real, what primitive does it need, and which milestone builds it.

Status markers match the main tracker: `[ ]` not started, `[~]` in progress, `[r]` implementation
claims done, `[!]` sent back, `[x]` closed (code-verified + screenshot-validated). **A row only moves
to `[x]` once Tabletop Club genuinely exercises that archetype's real interaction model** — not when a
fixture merely declares the archetype name.

| Archetype | V2 verdict | Primitive(s) needed | Phase 1 milestone | Status |
|---|---|---|---|---|
| `calendarAgenda` | Fake — never a grid | Repeater (day-cells) | 1.5 | `[ ]` |
| `stateMachineGrid` / `table` | Fake except Marketplace | Repeater | 1.6 | `[ ]` |
| `discussionThread` | Fake despite real widget existing | Repeater (live query) | 1.7 | `[ ]` |
| `documentLibrary` | Dead code (real widget, no real data) | none (fixture only) | 1.8 | `[ ]` |
| `notificationInbox` | Fake — one hardcoded instance | Repeater (live query) + `createInstance` effect op | 1.9 | `[ ]` |
| `exportWizard` | Fake — no step indicator | none (pure UI) | 1.10 | `[ ]` |
| `volunteerRoster` | Fake — no meter, single instance shown | Repeater + arithmetic formula (`remaining`) | 1.11 | `[ ]` |
| `searchAiAnswer` | Fake — no real query input | none (pure UI) + platform search service | 1.12 | `[ ]` |
| `audienceSelector` | Fake — comma-separated text | Repeater (checkable list) | 1.13 | `[ ]` |
| `singleItem` | Fake — generic button-jump card | none (pure UI) | 1.14 | `[ ]` |
| `statusTimeline` | Fake — plain text list | Repeater (timestamped nodes) | 1.15 | `[ ]` |
| `protectedDetail` | Permission logic real, visual treatment fake | Formula (`if($viewer==...)` masking) | 1.15 | `[ ]` |
| `dashboard` | Fake — hardcoded section order | Formula (ranking) or documented simpler design | 1.16 | `[ ]` |
| `formEntry` | Fake — always flat TextField | Formula-readable guard (checkbox/relative-time control) | 1.17 | `[ ]` |
| `votePoll` | Broken — hardcoded 2-candidate Book Club special case | Repeater + Formula (tally/winner/runoff) + cross-instance eligibility guard | 1.18 (Tournament + Voting) | `[ ]` |
| `paymentCheckout` | Fake — hardcoded receipt IDs, generic template | ID-generation platform service | reused as-is, receipt-id fix folded into 1.18 or its own follow-up | `[ ]` |
| `guidedProcess` | **Real** — Youth Soccer registration wizard | none — reference implementation | validation pass only (1.19) | `[x]` already real, re-confirm |

## Reference implementations once built

- **Repeater** (`_RepeaterSurface`): built once in milestone 1.3
  ([Phase1_TabletopClub.md](./Loom_Communities_Workflow_Engine_Phase1_TabletopClub.md)), reused by
  every row above tagged "Repeater" — never re-implemented per archetype.
- **Computed fields / extended effect ops / aggregate API**: built once in milestones 1.1-1.2, reused by
  every row tagged "Formula." Full spec:
  [ComputationModel.md](./Loom_Communities_Workflow_Engine_ComputationModel.md).
- **`guidedProcess`**: already real (`part19_youth_soccer_engine.dart:267-328`) — the pattern other
  wizard-shaped interactions (if any emerge in Phase 2) should follow directly, no rebuild needed.

## How Phase 2 uses this doc

Phase 2 ([Phase2_CommunityExtension.md](./Loom_Communities_Workflow_Engine_Phase2_CommunityExtension.md))
re-reads each community's design doc against this table's `[x]` rows. If a community's documented need
fits an already-`[x]` archetype's real implementation, that community's milestone is a validation pass.
If it needs something stricter (e.g. Mosque's field-level `protectedDetail` masking by viewer identity
is a stricter case than anything Tabletop Club exercises), that's new scope for that community's
milestone — still expressed as a Formula/Repeater extension, never a one-off widget.

## How Phase 3 (the Skill) uses this doc

The Skill never edits this table's implementations. It reads the `renderBindings` config shape each
`[x]` archetype expects (Repeater source/template/actions, formula fields, guard references) and
writes JSON against it. If Phase 3 discovers a real archetype gap, that is a sign Phase 2 wasn't
actually done — not a reason for the Skill to improvise code.
