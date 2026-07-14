# Phase A — Foundation + Calendar tab (the vertical slice)

Part of [tracker 3](./Loom_Communities_Workflow_Engine_3.md). **Blocks every other phase.**

## Goal

Build the entire engine-native pipeline — JSON load → shared engine → formulas → guards → generic
renderer → `renderBindings` dispatch — but wire **only the Calendar tab** to it. Then stop at a human
gate.

**Why one tab first:** the Calendar slice exercises every layer end-to-end (a real state machine, a real
formula guard, real effects, computed capacity fields, the generic renderer, binding dispatch) on the
smallest possible surface. If the JSON, an archetype, a formula, or an API shape is wrong, it surfaces
here — where fixing it is cheap — instead of after six tabs have been built on the same wrong
assumption.

**Out of scope for Phase A** (deliberately — other phases): the ballot, marketplace, giving, proposals,
messages, and the Home tab. Their workflow definitions stay in the JSON and simply don't render yet; the
binding dispatcher only honors `tabId: "calendar"` in this phase.

## The Calendar slice, concretely

From [the Tabletop Club JSON](./Loom_Communities_Workflow_Engine_Phase1_TabletopClub_Example.jsonc), two
workflow types declare a `calendar` render binding:

| Workflow type | Instance | What must genuinely work |
|---|---|---|
| `event-rsvp` | `event-friday-game-night` (Jul 10, cap 20, 12 going) | Going / Maybe / Can't go, each moving the actor between `goingPersonaIds`/`maybePersonaIds`/`notGoingPersonaIds`; **Join waitlist appears only when genuinely full** (a real `formula` guard: `size(goingPersonaIds) >= capacity`); computed `goingCount`/`seatsRemaining`/`isFull` update live |
| `tournament-event` | `event-summer-tournament` (Jul 10, min 8) | "I'm going" / "Can't make it" (guarded by `actorInList`, so the right one shows); computed `accepted` updates live. *(Its `home` binding is ignored this phase — Phase B.)* |

Both events land on the **same date (Jul 10)** on purpose — it re-exercises the same-date grouping the
calendar grid already handles.

## User stories this phase must satisfy

- *As a member, I open Calendar and see both of this week's events on a real month grid.*
- *As a member, I RSVP Going and the seat count updates immediately — computed by the engine, not by
  parsing a label string.*
- *As a member, when the event is full, Going is unavailable and Join waitlist appears instead.*
- *As a member, I change my mind to Maybe and I'm removed from the going list.*
- *As an organizer, I can cancel an event.*
- *As either persona, the card is readable* — no dark-purple text on a near-black fill.

---

## Milestones

Each is one concern, sized for a single dispatch. Kickoff tickets carry the production-quality bar
verbatim and a required structured status response.

---

### A.1 — Validator: close 4 `WorkflowValidator` gaps  `[x]`

**Ticket already written:** `data/v3_ticket_validator_a_workflow_validator_gaps.md` (contains
ready-to-apply snippets).

The existing `WorkflowValidator`
(`app/packages/tooling/loom_ux_judges/lib/src/validator/workflow_validator.dart`) is real and thorough
but has four gaps that would either miss errors in our JSON or false-positive on it:

1. **Nested effects are never walked** — `branch`'s `then`/`else` (so `createInstance` and cross-instance
   `set` escape all validation).
2. **Cross-instance `set` false-positives** — the ballot writes `selectedGame`, a field on the *event*;
   the current check flags it as dangling.
3. **`createInstance` unvalidated** — target `workflowType` and its `fields` keys unchecked.
4. **Guard formulas and `branch` conditions unvalidated** — only `instanceDataSchema` formulas are.

Also extracts the string-aware JSONC stripper from the existing CLI into
`lib/src/validator/jsonc.dart` so A.2 can reuse it rather than copy it.

**Accept:** 10 new tests (one per rule, incl. a regression guard that a valid definition still passes
clean); the entire pre-existing `loom_ux_judges` suite passes **unmodified**.

**Closed 2026-07-14.** Implementation commit `9c2d073`; status commit `938e0b6`. Independent validation
read the implementation and reran the complete tooling suite successfully as part of the A.2/A.3 gate.

---

### A.2 — Validator: `CommunityPackageValidator` + CLI  `[x]`

**Ticket already written:** `data/v3_ticket_validator_b_community_package_validator.md`.

New validator over a whole community package. Delegates all definition-level checks to A.1's
`WorkflowValidator` (no re-implementation) and adds the layers it can't see:

- **Envelope + versions** per
  [JSON_Schema_Versions.md](./Loom_Communities_Workflow_Engine_JSON_Schema_Versions.md) — all three
  stamps required; unknown version = hard error, never a best-effort parse.
- **Instances** — `workflowType` exists; `currentState` is a declared state; `instanceData` keys are all
  declared; `required` fields present; **computed (`formula`) fields must not be seeded** (seeding one
  is the "hardcoded value masquerading as computed" anti-pattern).
- **Cross-instance reference integrity** — resolvable only here, because a target's workflowType comes
  from instance data: the ballot's `eventId` must name a real instance whose schema declares
  `goingPersonaIds` (the eligibility guard) and `selectedGame` (the cross-instance write).

Plus `bin/community_package_validator.dart` (`--package`, `--output`, `--warnings-as-errors`), modeled
on the existing CLI. **This becomes the Skill's hard gate in Phase 3.**

**Accept:** 15 tests incl. the cross-instance happy path (the regression guard that stops it
false-positiving on the real ballot); full suite green.

**Closed 2026-07-14.** Production implementation commit `4c682b7`; independent-test remediation commits
`4494df4` and `d16a0d5`; evidence commits `fab96bc` and `62477c2`. The verification agent read the
diffs and independently reran formatting, `dart analyze` (`No issues found!`), all 64 tooling tests,
and the real CLI hard gate. The final suite contains exactly 15 isolated Ticket B rule tests.

---

### A.3 — Validate the Tabletop Club JSON; fix real findings  `[x]`  *(JSON edits only — no code)*

Run A.2's CLI against
[Loom_Communities_Workflow_Engine_Phase1_TabletopClub_Example.jsonc](./Loom_Communities_Workflow_Engine_Phase1_TabletopClub_Example.jsonc)
and fix whatever it legitimately finds.

That file was hand-authored against the grammar **before any validator existed** — it is unverified.
Two specific unknowns to settle here:

- Does `"availabilityState == 'available'"` (single-quoted string literal, `equipment-loan.isAvailable`)
  actually parse? If `analyzeFormula` rejects string literals, that is a **real grammar limitation** to
  record in JSON_Schema_Versions.md — not something to paper over.
- Do the cross-instance checks resolve `ballot.eventId → event-summer-tournament` and its `selectedGame`
  write?

**Rule:** fix the JSON to match the grammar, or record the grammar gap. **Never** weaken the validator
to make its input pass.

**Accept:** the CLI exits clean (or with only findings explicitly triaged and recorded here).

**Closed 2026-07-14.** Before the freeze baseline, four invalid `createdByPersonaId` seed values were
corrected to the declared `tabletop-member` persona. That was a data-integrity correction, not a JSON
language gap. Baseline commit `c5eb7aa` now freezes the canonical file at SHA-256
`822A776F997F6C627C1BC42FB77DD227933630795E27D3D4BECCE94AD7CC1813`; its post-baseline diff is empty.
The verification agent ran the CLI with `--warnings-as-errors`: exit 0, 0 errors, 0 warnings. The
single-quoted formula literal parses, and the ballot eligibility reference plus `selectedGame`
cross-instance write resolve. **No new Tabletop-JSON or JSON-language gap was discovered in A.1–A.3.**

---

### A.4 — Parse `workflowDefinitions` / `workflowInstances` at install  `[ ]`  *(parsing only — no UI, no engine)*

- Add `workflowDefinitions: Map<String, LoomWorkflowStateMachine>?` and
  `workflowInstances: List<SeedInstance>?` to `LoomExperienceDefinition`
  (`part11_shell_models.dart`).
- Parse them in `_experienceFromConfiguration` (`part15_evidence_catalog.dart`) **using the existing
  `LoomWorkflowStateMachine.fromJson`** — do not write a second parser.
- Gate on the version stamps: parse the engine-native branch only when
  `experienceSchemaVersion == 2`; leave the shallow v1 path **exactly as-is** (every other community
  still uses it).

**Accept:** a unit test installs the Tabletop Club JSON and asserts the parsed
`experience.workflowDefinitions` contains all 11 types with the right states/transitions, and
`workflowInstances` all 17. **No UI changes. Nothing renders differently yet.**

**Do not:** touch any existing community's parsing, or the `workflows[]` shallow branch.

---

### A.5 — One shared engine per community  `[ ]`  *(no UI)*

Today every bespoke store creates its **own private** `WorkflowDatabase.memory()` +
`LocalWorkflowEngineApi` (~20 of them). The engine-native path needs **one shared engine per community**,
so cross-instance guards/effects can actually see other workflows' instances (the ballot must be able to
read the event's `goingPersonaIds`).

- One `LocalWorkflowEngineApi` per `extensionId`, created at install.
- Register every parsed definition; seed every parsed `workflowInstances` entry via the real engine.
- Reuse the established `static _stores`-keyed-by-`extensionId` memoization pattern.

**Accept:** a test that, after installing the Tabletop Club package, calls `queryInstances` **directly on
the engine** and gets the seeded instances back with correct `currentState` and `instanceData` —
including a **computed field** (`event-rsvp.goingCount == 12`) proving the formula evaluator runs on real
seeded data. Still no UI change.

**Do not:** modify or delete any existing bespoke store yet (Phase G retires them). Additive only.

---

### A.6 — Generic schema-driven instance card  `[ ]`

The one widget that replaces "a hand-written card per feature." Given any `WorkflowInstance` + its
`LoomWorkflowStateMachine`, render:

- **Fields** from `instanceDataSchema` — honoring `displayIcon`, `labelTemplate` (`{value}`,
  `{value.length}`), `hideWhenEmpty`, `displayContexts` (`tile` vs `detail`).
- **Editable fields** for the current state's `editableFields`, with a control chosen by field `type`
  (`text`/`textarea` → text field, `date` → date picker, `bool` → checkbox, `number` → numeric).
- **Actions** — one button per transition returned by `availableTransitionsAsync` (which already
  evaluates guards, including cross-instance ones), wired to `applyTransition`.

Seed from Mosque's `_pills` (`part20_mosque_engine.dart:357-369`) — the only existing code that reads
`instanceDataSchema` generically — but it is **display-only**; the field-type dispatch and the action row
are new.

**Accept:** a widget test renders ONE JSON-declared workflow through this card with **zero bespoke Dart
for that workflow** — fields display per schema, a guarded transition's button is absent when its guard
fails and present when it passes.

**Do not:** wire it into any tab yet (that's A.7). Build and test it in isolation.

---

### A.7 — `renderBindings` → tab dispatch (Calendar only)  `[ ]`

`resolveBindings()` (`loom_workflow_engine/lib/src/evaluator/binding_resolver.dart:10-38`) is a real,
generic state+role tab matcher with **zero production call sites** today. Wire it up.

- For each engine-native instance, resolve its bindings; render it on the tab(s) its own JSON names.
- **Scope: honor `tabId: "calendar"` only** in this phase. Bindings for `home`/`marketplace`/`giving`/
  `admin`/`messages` are parsed and ignored — their phases turn them on.
- This is also what will eventually retire Home's blanket duplication (`matchesWorkflow` hardcodes
  `tabId == 'home' → true`), but **do not touch Home in this phase** — it still renders the old way.

**Accept:** a widget test proves an instance whose binding says `calendar` appears on Calendar, and one
whose binding says `home` does **not** appear on Calendar.

---

### A.8 — Calendar tab end-to-end from JSON  `[ ]`  ← **the payoff**

Wire it together: the Calendar tab renders `event-friday-game-night` and `event-summer-tournament` from
the JSON-declared definitions, through A.6's generic card, dispatched by A.7's bindings, backed by A.5's
shared engine.

**Every interaction must be real** (engine `applyTransition`, not local state):

- Going / Maybe / Can't go move the actor between the three lists.
- `goingCount` / `seatsRemaining` / `accepted` update live — **computed by the formula evaluator**, never
  parsed from a label string (the exact anti-pattern the audit found in
  `_goingCountFromLabel`/`_isCapacityFull`).
- **Join waitlist appears only when the event is genuinely full** — driven by the real
  `formula` guard `size(goingPersonaIds) >= capacity`, proven by a test that fills the event and watches
  the button set change.
- Organizer can cancel; a cancelled event renders via its `cancelled` binding.

**Accept (all required):**
1. Widget test: RSVP Going → `goingCount` increments and the instance's real `instanceData` in the engine
   reflects it (assert via `queryInstances`, not just the pixels).
2. Widget test: fill the event to capacity → Going disappears, Join waitlist appears. Un-fill → reverses.
3. Widget test: switch Going → Maybe → the persona leaves `goingPersonaIds` and enters `maybePersonaIds`.
4. **Negative test:** a persona already in `goingPersonaIds` does not get a second "I'm going" on
   `tournament-event` (the `actorInList` guard genuinely blocks it).
5. `flutter analyze` clean; full app-shell suite green; **every other community's tests pass unmodified**
   (the additive-pathway regression guard).

---

### A.9 — Calendar theming fixes  `[ ]`

Two real, already-diagnosed bugs on this tab:

- `_CalendarAgendaDateStrip` (`part02_tab_shell.dart:5453,5462`) sets unselected date text to the **raw
  `accent`** against the shared near-black fill (`_neutralCardFill = 0xff1c2024`) — the reported
  dark-purple-on-black. Derive the text color from the theme's foreground for that fill, not from the
  accent.
- `CalendarMonthGrid` (`calendar_month_grid.dart:3-110`) takes **no** accent/theme parameter at all and
  falls back to `Theme.of(context).dividerColor` — outside the community theme cascade entirely.

**Keep the cascade.** The community→tab→workflow `theme`/`tabThemes` system is deliberate and tested
(`b26_package_driven_experience_test.dart`) — do **not** remove `LoomWorkflowDefinition.theme`,
`themeOverride`, `tabThemeOverrides`, or `LoomCardTheme.merge`. These are two bugs *within* it, not a
reason to delete it.

**Accept:** a widget test asserting the date-strip text color is the theme's resolved foreground (not the
raw accent); month grid renders with the community accent; contrast is legible in a screenshot.

---

### A.10 — Live emulator walk → **HUMAN GATE**  `[ ]`

Full walk on `PantryVision_Manual_API_36`, per the tracker's verification standard:

- **Full-tab audit:** every card on Calendar, not just the new ones — each is the right archetype with
  its real interactions.
- **Evidence matrix:** one screenshot per (Tab × User story × Interaction) cell — every user story listed
  at the top of this doc.
- **Random regression re-check:** one re-take of a previously-closed milestone's interaction.

**Then stop.** The user inspects the running Calendar tab and the JSON side by side, and revises the JSON
— archetypes, formulas, field shapes, render bindings, API ergonomics. **This gate is the entire point of
Phase A.** Phases B-G do not start until it closes, because their JSON depends on what is learned here.

**Expected outcome:** the JSON *changes*. That is success, not rework.

---

## Phase A definition of done

- [ ] A.1-A.9 all `[x]`, each independently verified (diff read + suite run by the verification agent).
- [x] The Tabletop Club JSON validates clean through the new CLI.
- [ ] Calendar renders entirely from JSON-declared `workflowDefinitions` — **zero bespoke Dart for
      `event-rsvp` or `tournament-event`**.
- [ ] Every other community, and every other tab, works exactly as before (regression proven, not
      assumed).
- [ ] Live walk complete with the full evidence matrix.
- [ ] **User has reviewed the running tab + JSON and signed off on (or revised) the schema.**
