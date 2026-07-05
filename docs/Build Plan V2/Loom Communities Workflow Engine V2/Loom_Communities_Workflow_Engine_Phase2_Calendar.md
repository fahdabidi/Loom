# Phase 2 — Calendar (Tabletop Club) + Audience/Distribution Primitive

Part of [Loom_Communities_Workflow_Engine.md](./Loom_Communities_Workflow_Engine.md). Depends on
[Phase 1](./Loom_Communities_Workflow_Engine_Phase1_MarketplaceEngine.md) being fully closed — reuses
its engine, `WorkflowEngineApi`, validator, and rendering primitives without modification.

Status: not started.

**Note on renumbering (2026-07-05):** the original monolithic doc labeled the audience/distribution
work "Phase 3.5" with a header saying it "folds into Phase 3" but body text saying to build it
"alongside Phase 2's calendar work" — an internal inconsistency. Corrected here: audience/distribution
is this phase's own Milestone 2.1, since Calendar RSVP is the workflow that first needs it and Phase 3
(Giving) has no distribution concept at all.

## 1. Scope & goal

Reuses all Phase 1 infrastructure — should be materially smaller than Phase 1. Two things land
together because RSVP is exactly the workflow shape that first needs audience/distribution: (1) the
audience/distribution primitive designed in
[Phase 1 §2c](./Loom_Communities_Workflow_Engine_Phase1_MarketplaceEngine.md#2c-audience-distribution--invite-cardinality-design-update-2026-07-04),
built and tested for real here; (2) Tabletop Calendar migrated onto the new engine via a new
`event-rsvp` `cardSurfaceFamily`.

## 2. Open design question — resolve during this phase, not before

Today's calendar RSVP workflows aren't really a rich state machine (mostly a fixed actor/receiver
lifecycle + `responseChoices`). This phase needs to determine whether RSVP maps cleanly onto
`states`/`transitions` (Phase 1's full FSM model), or whether the schema needs a lighter-weight
"simple response" mode alongside the full FSM mode. **Don't force-fit — the milestone below is a
design spike with a documented finding, not an assumed answer.**

## 3. Relationship to existing Calendar UI fixes

Migrating Calendar onto the new engine also fixes the two Calendar UI bugs from the current AppShell
V2 tracker as a side effect of using the schema's `instanceDataSchema` icons/labels — **but only if
those interim fixes haven't already landed independently first.** Per the current tracker, M4
(Calendar) was reopened for exactly these two defects (duplicate date-strip chips, generic checkmark
iconography) and **re-closed 2026-07-04 with live evidence** — so by the time this phase starts, the
interim fixes should already be in place. The date-strip dedup bug is a separate, date-grouping-
specific concern this phase must not assume is automatically solved by the engine migration alone —
verify it explicitly (Milestone 2.3 below), don't just assume schema-driven icons cover it.

## 4. Milestones

### Milestone 2.1 — Audience/distribution primitive
Build the `audienceSelector` `formEntry` field type, per-instance audience `instanceData`
(`audienceScope`/`invitedPersonaIds`/`rsvpByPersona`), and dynamic `receiver` role resolution via
`audienceMemberField` (full design in Phase 1 §2c).

**Validation tests required to close this milestone:**
- [ ] Unit test per cardinality: `audienceScope: "all"` resolves `receiver` from the static role list
  (unchanged legacy behavior); `"selected"` with 3 `invitedPersonaIds` resolves `receiver` to exactly
  those 3 personas and no others; `"individual"` with 1 id resolves to exactly that persona.
- [ ] Unit test: a persona NOT in `invitedPersonaIds` under `scope: "selected"` does not see the
  `role: receiver` binding at all (not a disabled view — the binding shouldn't resolve for them),
  proving the membership gate actually excludes non-invitees.
- [ ] Widget test: the `audienceSelector` field in a `formEntry` surface correctly switches which
  sub-inputs render per mode (all → no picker; selected-many → multi-select picker; individual →
  single-select picker) and the submitted `instanceData` matches the selection.
- [ ] `queryInstances` test (fan-out-on-read, per Phase 1 §2c's backend-shape decision): a persona in
  the audience of 2 of 5 seeded instances queries "instances where I'm in the audience" and gets back
  exactly those 2 — proving the read-side distribution query (the mechanism a `notificationInbox`/
  `dashboard` "you're invited" surface relies on) actually works end to end, not just that the write
  side stores the list correctly.
- [ ] Round-trip test combining both directions: creator sets `scope: "selected"` with 2 invitees →
  each invitee's own session sees the receive-side `renderBinding` and can respond (RSVP going/maybe/
  not-going into `rsvpByPersona`) → creator's session sees both responses reflected on the same
  instance.

### Milestone 2.2 — RSVP schema design spike
Resolve §2's open design question with a real decision, backed by an actual attempt to model Tabletop's
existing RSVP workflow both ways.

**Validation tests required to close this milestone:**
- [ ] A written finding (in this doc, replacing this milestone's text once resolved) stating which
  approach was chosen and why, with the rejected approach's concrete failure mode named (e.g. "full FSM
  modeling required N states for what is actually a 3-way fixed response, adding no real guard/effect
  value" or "a lighter-weight mode would have duplicated logic already in the FSM evaluator — not worth
  a second code path").
- [ ] Whichever shape is chosen, a parsed-and-validated fixture (passes the Phase 1 §7c validator)
  modeling Tabletop's actual current RSVP workflow (going/maybe/not-going + capacity + waitlist),
  proving the decision works against real data, not a toy example.

### Milestone 2.3 — `event-rsvp` cardSurfaceFamily template + Calendar tab replacement
New template using `WorkflowActionButtonRow`/`WorkflowFactPillRow` (Phase 1 §7d); replace Tabletop's
Calendar tab implementation with the new engine end to end.

**Validation tests required to close this milestone:**
- [ ] Full behavioral-parity widget-test suite against today's Calendar tab: date-strip navigation,
  agenda list, event detail expand/collapse, RSVP going/maybe/not-going, capacity/waitlist display —
  one test per interaction.
- [ ] Explicit regression tests for the two AppShell V2 M4 defects, run against the NEW engine
  implementation specifically (not inherited from the interim fix's own tests): two same-date events
  render exactly one date-strip chip; the event-detail fact pills render distinct icons
  (`Icons.schedule`/`person_outline`/`location_on_outlined`/`groups_outlined`), not a shared checkmark.
  **Do not mark this milestone's evidence bar green by pointing at the interim fix's tests alone** —
  the new engine is a different code path and needs its own proof.
- [ ] Live emulator walk (WSL Ubuntu, `PantryVision_Manual_API_36` AVD): screenshot evidence of the new
  Calendar tab, including a two-same-date-event day and an expanded event detail with distinct icons.
- [ ] Full `flutter test` suite green, exact pass count cited, zero regressions elsewhere.
- [ ] Phase 1 §7c validator run against the Calendar/RSVP fixture, output pasted into the evidence log.
