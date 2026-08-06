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

**Reconciliation note (2026-08-05, tracker 3 Phase G.4).** This table's `[x]` rows record whether a
genuinely rich UI was ever *built* (milestones 1.5-1.19, hand-copied JSON fixtures, one bespoke
per-community engine store per feature). [Tracker 3](./Loom_Communities_Workflow_Engine_3.md) then
rebuilt Tabletop Club's UI onto the **real engine-native, JSON-declared pipeline** and added a second,
stricter axis this table doesn't track: *is the widget reached purely by declaring
`cardSurfaceFamily` in JSON, with zero hardcoded per-community wiring*. That axis — plus the current,
re-verified-against-source status of every archetype — now lives in
[`docs/references/archetypes/README.md`](../../references/archetypes/README.md), which supersedes this
table for "is it real and reachable today" questions. This table is retained for its historical build
record; do not update its `[x]` markers going forward — update the README instead.

| Archetype | V2 verdict | Primitive(s) needed | Phase 1 milestone | Status |
|---|---|---|---|---|
| `calendarAgenda` | Fake — never a grid | Repeater (day-cells) | 1.5 | `[x]` real month grid, code-verified 11/11 (commit `c860045`); live walk deferred to batch before 1.20 |
| `stateMachineGrid` / `table` | Fake except Marketplace | Repeater | 1.6 | `[x]` Marketplace reformalized onto a new Repeater grid mode, suite 13/13 + `b34_marketplace_browse_test.dart` 16/16 byte-identical (zero behavior change, confirmed via `git diff --stat`) |
| `discussionThread` | Fake despite real widget existing | Repeater (live query) | 1.7 | `[x]` generalized `_MessagesTabSurface` off live query, `v3_milestone_1_7_messages_test.dart` 3/3, suite 16/16 |
| `documentLibrary` | Dead code (real widget, no real data) | none (fixture only) | 1.8 | `[x]` fixture now populates real category/document data, suite 17/17 |
| `notificationInbox` | Fake — one hardcoded instance | Repeater (live query) + `createInstance` effect op | 1.9 | `[x]` live list + dismiss + unread aggregate, suite 18/18 |
| `exportWizard` | Fake — no step indicator | none (pure UI) | 1.10 | `[x]` real step progression, `v3_milestone_1_10_export_wizard_test.dart` 1/1, suite 19/19 |
| `volunteerRoster` | Fake — no meter, single instance shown | Repeater + arithmetic formula (`remaining`) | 1.11 | `[x]` multi-shift + capacity meter, `..._1_11_volunteer_roster_test.dart` 1/1, suite 20/20 |
| `searchAiAnswer` | Fake — no real query input | none (pure UI) + platform search service | 1.12 | `[x]` real query input replaces cited result, suite 22/22 |
| `audienceSelector` | Fake — comma-separated text | Repeater (checkable list) | 1.13 | `[x]` checkable chip picker, `..._1_13_audience_picker_test.dart` 1/1, suite 23/23 (commit `2ee3d9b`) — caught + fixed a real missing-`editableFields` auth bug |
| `singleItem` | Fake — generic button-jump card | none (pure UI) | 1.14 | `[x]` segmented/exclusive control, suite 24/24 (commit `a00e233`) |
| `statusTimeline` | Fake — plain text list | Repeater (timestamped nodes) | 1.15 | `[x]` timestamped chronological nodes, suite 26/26 (commit `9ead6a9`+`0d639d4`) — caught + fixed a real layout bug |
| `protectedDetail` | Permission logic real, visual treatment fake | Formula (`if($viewer==...)` masking) | 1.15 | `[x]` real masking treatment alongside already-real permission logic, suite 26/26 |
| `dashboard` | Fake — hardcoded section order | Formula (ranking) or documented simpler design | 1.16 | `[x]` documented no-build decision (no shared urgency model across 11 categories) + a real copy fix, suite 26/26 (commit `aa197bc`) |
| `formEntry` | Fake — always flat TextField | Formula-readable guard (checkbox/relative-time control) | 1.17 | `[x]` real checkbox + relative-time-picker control, suite 27/27 (commits `10750b7`+`3fa2091`) |
| `votePoll` | Broken — hardcoded 2-candidate Book Club special case | Repeater + Formula (tally/winner/runoff) + cross-instance eligibility guard | 1.18 (Tournament + Voting) | `[x]` rich organizer-authored-shaped candidates (tap-to-detail popup), real cross-instance eligibility guard, `groupCount`/`argMaxKey`/`topKeys`/`isTie` tally+tie+real runoff, cross-instance `selectedGame` propagation, formula-backed attendance, real `dueNotifications`-backed deadline/reminder banner — suite 33/33 cumulative. **Known remaining gap**: ballot/tournament creation itself is still seed-driven, not a real organizer-facing creation form — tracked open in Phase1_TabletopClub.md, judged lower-priority than the capability gaps above which are what this milestone was created to prove out |
| `paymentCheckout` | Fake — hardcoded receipt IDs, generic template | ID-generation platform service | reused as-is, receipt-id fix folded into 1.18 or its own follow-up | `[ ]` not started — no milestone has touched this yet |
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
