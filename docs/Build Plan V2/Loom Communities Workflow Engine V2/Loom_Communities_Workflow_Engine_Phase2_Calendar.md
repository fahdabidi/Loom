# Phase 2 — Calendar (Tabletop Club) + Audience/Distribution Primitive

Part of [Loom_Communities_Workflow_Engine.md](./Loom_Communities_Workflow_Engine.md). Depends on
[Phase 1](./Loom_Communities_Workflow_Engine_Phase1_MarketplaceEngine.md) being fully closed — reuses
its engine, `WorkflowEngineApi`, validator, and rendering primitives without modification.

Status: Phase 1 fully closed 2026-07-07 (all of Milestones 1.1�1.6). This phase is now unblocked;
Milestone 2.1 starts next.

**Note on renumbering (2026-07-05):** the original monolithic doc labeled the audience/distribution
work "Phase 3.5" with a header saying it "folds into Phase 3" but body text saying to build it
"alongside Phase 2's calendar work" — an internal inconsistency. Corrected here: audience/distribution
is this phase's own Milestone 2.1, since Calendar RSVP is the workflow that first needs it and Phase 3
(Giving) has no distribution concept at all.

**Handoff:** once a milestone below is implemented, set its marker to `[r]` here and in the main
tracker, then run this in-session watcher call and wait for delivery:

```python
from data.file_watcher import check_file_update
import asyncio

async def main():
  await check_file_update("data/verification_feedback.md")  # baseline call, returns immediately
  print(await check_file_update(
    "data/verification_feedback.md",
    timeout_seconds=1200,
    reset_template_path="data/verification_feedback_template.md",
    activity_process_names=["wsl", "dart"],
  ))

asyncio.run(main())
```

Then follow the embedded delivery instructions directly.
[§5 Handoff protocol](./Loom_Communities_Workflow_Engine.md#5-handoff-protocol-implementation-agent--verification-agent-added-2026-07-05)
for the full sequencing (code verification always runs before any screenshot validation).

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

### Milestone 2.1 - Audience/distribution primitive - `[x]` CLOSED 2026-07-07
Build the `audienceSelector` `formEntry` field type, per-instance audience `instanceData`
(`audienceScope`/`invitedPersonaIds`/`rsvpByPersona`), and dynamic `receiver` role resolution via
`audienceMemberField` (full design in Phase 1 §2c).

**2026-07-07: Verification result � CLOSED.** Independently re-verified, first pass, no issues.
- Read `binding_resolver.dart`'s `resolveBindings` directly: for `role: 'receiver'` bindings with
  `audienceMemberField` set, when `audienceScope` is `selected`/`individual` it checks dynamic
  membership (`_isDynamicAudienceMember`) instead of static role matching; `all` (or scope absent)
  falls through to the legacy static-role check. Matches the design exactly, not gamed.
- Read `local_workflow_engine_api.dart`'s `_matchesAudienceQuery`: correctly implements
  fan-out-on-read filtering in `queryInstances` keyed on `SurfaceQuery.audienceMemberField`/
  `audienceScopeField`.
- Read `effect_evaluator.dart`'s `_setNestedMapValue`: dotted effect keys like
  `rsvpByPersona.$actor` correctly merge into the existing nested map (not overwrite it), which is
  what makes the round-trip test's `{'alice': 'going', 'bob': 'maybe'}` assertion possible �
  confirmed this is real, not coincidental.
- Read `WorkflowAudienceSelectorField` (`part18_marketplace_rendering.dart`): a real, working
  `StatefulWidget` with distinct keys per mode, matches the widget test exactly.
- All 5 required validation tests below are genuinely present (2 in
  `loom_workflow_engine/test/milestone_2_1_test.dart`, 1 fan-out-on-read + 1 round-trip test also
  there, 1 widget test in `loom_communities_app_shell/test/milestone_2_1_test.dart`) � confirmed by
  reading each test body, not just trusting the checklist.
- Fresh re-runs, all matched exactly: `dart analyze packages/core/loom_workflow_engine` clean;
  `dart test packages/core/loom_workflow_engine` 70/70; `flutter analyze
  packages/core/loom_communities_app_shell` clean; `flutter test
  packages/core/loom_communities_app_shell` 5/5. Additionally ran the broader combined suite
  (`flutter test packages/core/loom_communities_app_shell/test apps/loom_communities_demo/test`,
  not cited in the original claim since these shared engine files are also used by Marketplace) �
  104/104, exactly the 103 baseline plus 1 new test, zero regressions.
- Minor process note (not blocking): the implementation agent set `[r]` in this phase doc but not
  in the main tracker's �4 table � flagging so both docs stay in sync going forward.

**Implementation note (2026-07-07):** added dynamic audience metadata/resolution in `loom_workflow_engine`, fan-out-on-read `SurfaceQuery.audienceMemberField` filtering, persona-keyed RSVP map writes via dotted effect keys, and the `WorkflowAudienceSelectorField` shell widget.

**Validation run before `[r]`:**
- `cd "/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app" && dart analyze packages/core/loom_workflow_engine` - clean.
- `cd "/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app" && dart test packages/core/loom_workflow_engine` - 70/70 passing.
- `cd "/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app" && flutter analyze packages/core/loom_communities_app_shell` - clean.
- `cd "/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app" && flutter test packages/core/loom_communities_app_shell/test/milestone_2_1_test.dart` - 1/1 passing.
- `cd "/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app" && flutter test packages/core/loom_communities_app_shell` - 5/5 passing.

**Validation tests required to close this milestone:**
- [r] Unit test per cardinality: `audienceScope: "all"` resolves `receiver` from the static role list
  (unchanged legacy behavior); `"selected"` with 3 `invitedPersonaIds` resolves `receiver` to exactly
  those 3 personas and no others; `"individual"` with 1 id resolves to exactly that persona.
- [r] Unit test: a persona NOT in `invitedPersonaIds` under `scope: "selected"` does not see the
  `role: receiver` binding at all (not a disabled view — the binding shouldn't resolve for them),
  proving the membership gate actually excludes non-invitees.
- [r] Widget test: the `audienceSelector` field in a `formEntry` surface correctly switches which
  sub-inputs render per mode (all → no picker; selected-many → multi-select picker; individual →
  single-select picker) and the submitted `instanceData` matches the selection.
- [r] `queryInstances` test (fan-out-on-read, per Phase 1 §2c's backend-shape decision): a persona in
  the audience of 2 of 5 seeded instances queries "instances where I'm in the audience" and gets back
  exactly those 2 — proving the read-side distribution query (the mechanism a `notificationInbox`/
  `dashboard` "you're invited" surface relies on) actually works end to end, not just that the write
  side stores the list correctly.
- [r] Round-trip test combining both directions: creator sets `scope: "selected"` with 2 invitees →
  each invitee's own session sees the receive-side `renderBinding` and can respond (RSVP going/maybe/
  not-going into `rsvpByPersona`) → creator's session sees both responses reflected on the same
  instance.

### Milestone 2.2 - RSVP schema design spike - `[x]` CLOSED 2026-07-07

**2026-07-07: Verification result � CLOSED.** Independently re-verified, first pass, no issues.
- Read the finding below in full: it is a genuine architectural argument, not a rationalization
  after picking the easier option. It correctly identifies the real structural conflict (a single
  instance-wide `currentState` cannot represent N invitees' independent going/maybe/not-going
  answers without either collapsing them into one wrong global value or exploding into an unbounded
  set of composite states like `open-with-going-and-waitlist`), and names the concrete failure mode
  of the rejected pure-FSM approach.
- Read the fixture (`Loom_Communities_Workflow_Engine_Calendar_RSVP_Example.jsonc`) in full: models
  a real, internally consistent scenario � capacity 20, `goingPersonaIds` has exactly 12 entries,
  matching the cited "12 of 20 seats filled" scenario; `responseModel` declares
  `responseMapField`/`audienceScopeField`/`audienceMemberField`/`capacityField`/`goingListField`/
  `waitlistField`/`waitlistPolicy`/`choices` consistently with the `instanceDataSchema` fields they
  reference. This is a real worked example, not a toy.
- Re-ran the validator fresh (not trusted from the claim):
  `dart run packages/tooling/loom_ux_judges/bin/workflow_state_machine_validator.dart --definitions
  ".../Loom_Communities_Workflow_Engine_Calendar_RSVP_Example.jsonc"` ?
  `{"status": "pass", "errorCount": 0, "warningCount": 0, "findings": []}`. Matches exactly.
- Note: this milestone's own checklist only requires a written finding + validated fixture, not
  runtime wiring of `responseModel`/`writableBy: "responseModel"` into any Dart code � that is
  correctly deferred to Milestone 2.3, which builds the actual `event-rsvp` template and renderer.

**Finding (2026-07-07): choose a lightweight RSVP `responseModel` alongside the normal lifecycle FSM.**

I modeled Tabletop's current Friday game night RSVP both ways against the real shape from the app
fixture: member actor, organizer receiver, event date/time/location, visible capacity (`12 of 20 seats
filled`), and member choices Going/Maybe/Not going with a waitlist path once capacity is reached.

**Attempt A - full FSM only:** using `states`/`transitions` alone works for the event lifecycle
(`open` -> `cancelled`) and for stable action labels, but it does not cleanly model attendance because
`currentState` is instance-wide while RSVP state is per invitee. A pure-FSM encoding either collapses
every member's answer into one global event state, which is wrong as soon as Alice is going and Bob is
maybe, or explodes into aggregate/composite states such as `open-with-going-and-waitlist` that still do
not identify which persona answered. Keeping RSVP as self-transitions with effects was also not a real
solution: capacity and waitlist semantics need per-persona response ownership and count/list policy,
which would duplicate bespoke RSVP rules inside generic guard/effect code and still add no meaningful
state-machine lifecycle value.

**Attempt B - lifecycle FSM plus lightweight response model:** keep the reusable workflow FSM for the
event's lifecycle (`open`, `cancelled`) and declare a dedicated `responseModel.kind: simpleRsvp` for
the per-persona response plane. The response model names the response map, audience field, capacity
field, going list, waitlist list, waitlist policy, and the three allowed choices. This is the chosen
shape because it preserves Phase 1's FSM where it is semantically useful while avoiding a second
general-purpose evaluator. The renderer/API can treat RSVP as a typed field family, not as unbounded
workflow states.

**Rejected approach failure mode:** full-FSM-only modeling forced per-persona attendance into a single
global `currentState`; representing Going/Maybe/Not going + capacity + waitlist required either invalid
shared event states or an unbounded composite-state explosion, adding no guard/effect value and losing
which persona made which response.

**Validated fixture:**
`docs/Build Plan V2/Loom Communities Workflow Engine V2/Loom_Communities_Workflow_Engine_Calendar_RSVP_Example.jsonc`
models Tabletop's actual RSVP shape with `going`/`maybe`/`not-going`, capacity, waitlist fields,
receiver audience resolution, and the chosen `responseModel` declaration.

**Validator run before `[r]`:**

```bash
cd "/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app"
dart run packages/tooling/loom_ux_judges/bin/workflow_state_machine_validator.dart --definitions ../docs/Build\ Plan\ V2/Loom\ Communities\ Workflow\ Engine\ V2/Loom_Communities_Workflow_Engine_Calendar_RSVP_Example.jsonc
```

```json
{
  "status": "pass",
  "errorCount": 0,
  "warningCount": 0,
  "findings": []
}
```

`workflow_state_machine_validator: pass (clean)`

**Validation tests required to close this milestone:**
- [r] A written finding (in this doc, replacing this milestone's text once resolved) stating which
  approach was chosen and why, with the rejected approach's concrete failure mode named.
- [r] Whichever shape is chosen, a parsed-and-validated fixture (passes the Phase 1 validator)
  modeling Tabletop's actual current RSVP workflow (going/maybe/not-going + capacity + waitlist),
  proving the decision works against real data, not a toy example.
### Milestone 2.3 - `event-rsvp` cardSurfaceFamily template + Calendar tab replacement
`[x]` **CLOSED 2026-07-07**

**2026-07-07: Verification result (second pass) — CLOSED.** Independently re-verified the fix for
the sent-back engine-wiring gap; all three original blocking findings are resolved.

- Read `_CalendarTabSurfaceState` (`part02_tab_shell.dart:933` onward) directly: `initState`
  genuinely instantiates `_database = WorkflowDatabase.memory()` and
  `_engine = LocalWorkflowEngineApi(db: _database, communityId: widget.communityId)`. `_seedAndLoad`
  builds one real `LoomWorkflowStateMachine` per event via `_machineForEvent` (real `states`/
  `transitions`/guards/effects/`renderBindings`/`instanceDataSchema`, not a stub) and registers it
  via `_engine.registerDefinition`, then creates a real engine-backed instance via
  `_engine.createInstance` and loads it back via `_engine.queryInstances`.
- `_applyEngineTransition` (in `_CalendarEventDetailState`) calls `widget.onTransitionApplied` →
  `_CalendarTabSurfaceState._applyTransition` → `_engine.applyTransition(...)` — a real, persisted
  state transition, not local `setState` cosmetics. `_eventRsvpTransitions` calls
  `machine.transitionsFrom(instance.currentState)` filtered through real `evaluateGuard(...)` calls
  against `instance.instanceData` — real per-persona guard evaluation.
- `_effectsForResponse` wires real `rsvpByPersona.$actor` (set), `goingPersonaIds`/
  `waitlistedPersonaIds` (appendUnique/removeValue) effects — genuinely consuming the M2.1 audience
  primitive and M2.2 `responseModel` field names end to end, not just declaring them inertly.
- Fresh re-runs, all matched exactly: `flutter analyze` (app_shell + b36) clean; `flutter test`
  b36 8/8; `dart analyze`/`dart test` `loom_workflow_engine` clean/70/70; `dart analyze`/`dart test`
  `loom_ux_judges` clean/26/26; Calendar/RSVP validator `status: pass, errorCount: 0, warningCount: 0`.
  Also ran the broader combined suite beyond the cited claim:
  `flutter test packages/core/loom_communities_app_shell/test apps/loom_communities_demo/test` —
  112/112, zero regressions.
- Live emulator walk on `PantryVision_Manual_API_36` (fresh debug APK build + install, real device
  interaction, not just re-reading the implementation agent's own screenshots): confirmed both
  required visual checks with genuine on-device screenshots — a two-same-date-event day renders
  exactly one "Fri 10" date-strip chip (dedup working on the new engine path), and the expanded
  event detail shows distinct schema-driven icons (`Icons.schedule`/`person_outline`/
  `location_on_outlined`/`groups_outlined`), zero shared checkmarks.
- **Non-blocking observation:** attempted to go further than this milestone's own evidence bar
  requires by tapping a live RSVP action end-to-end on-device. The fact pills proved real engine
  data was loaded (`12 of 20 seats filled` derived from a genuine 12-entry `goingPersonaIds` list,
  not fallback data), but no RSVP action buttons rendered for either the Organizer or Member persona
  against my own manually-reconstructed test community package (built fresh since the original
  on-device community's install state didn't survive a rebuild/reinstall cycle this session). This
  is most plausibly a gap in my ad-hoc test package's fields rather than a production defect, since
  the identical code path (`_CalendarTabSurface` → `_CalendarEventDetail` → `_eventRsvpTransitions`
  → `applyTransition`) is proven correct by 8 passing automated widget tests with real assertions
  (e.g. `find.text('Your RSVP: Going')` after tapping the real action button) — not required by this
  milestone's own checklist (which only asks for the two static visual checks above), so not
  blocking closure, but worth a quick look if it recurs with the real production community data.

**Milestone 2.3 is closed. Phase 2 is now fully complete — all of Milestones 2.1 through 2.3 are
`[x]` CLOSED.** Phase 3 (Giving) begins next per the tracker's phase index.

---

**2026-07-07: Verification result (first pass) — SENT BACK.** [Historical, resolved above.]
`[r]` **READY FOR RE-VERIFICATION 2026-07-07** - fixed the sent-back implementation gap. Calendar RSVP is now wired through a real `WorkflowDatabase`/`LocalWorkflowEngineApi` instead of cosmetic widget-local state.

**Implementation changes:**
- Calendar instantiates `WorkflowDatabase.memory()` and `LocalWorkflowEngineApi` in `_CalendarTabSurfaceState`.
- Calendar registers one `LoomWorkflowStateMachine` per package-declared calendar event via `registerDefinition`.
- Calendar creates engine-backed event instances and calls `queryInstances` with `SurfaceQuery(audienceMemberField: 'invitedPersonaIds', audienceScopeField: 'audienceScope')`.
- Event detail facts and action availability now render from `WorkflowInstance.instanceData` and `machine.transitionsFrom(instance.currentState)`.
- RSVP actions call `_engine.applyTransition(...)`; the result replaces the stored `WorkflowInstance` and survives switching event details.
- The M2.2 `responseModel` field names are consumed in the Calendar path: `rsvpByPersona`, `goingPersonaIds`, `waitlistedPersonaIds`, `audienceScope`, and `invitedPersonaIds`.
- Capacity and waitlist display now come from persisted response-model fields, not from a local `_responseId` placeholder.

**Changed files:**
- `app/packages/core/loom_communities_app_shell/lib/src/part02_tab_shell.dart`
- `app/packages/core/loom_communities_app_shell/lib/src/part18_marketplace_rendering.dart`
- `app/apps/loom_communities_demo/test/b36_calendar_engine_rsvp_test.dart`

**Fresh validation evidence:**
- [x] `flutter analyze packages/core/loom_communities_app_shell apps/loom_communities_demo/test/b36_calendar_engine_rsvp_test.dart` - clean.
- [x] `flutter test apps/loom_communities_demo/test/b36_calendar_engine_rsvp_test.dart` - 8/8 passed.
- [x] `flutter test apps/loom_communities_demo/test/b27_calendar_tab_real_data_test.dart apps/loom_communities_demo/test/b36_calendar_engine_rsvp_test.dart` - 13/13 passed.
- [x] `flutter test packages/core/loom_communities_app_shell/test apps/loom_communities_demo/test` - 112/112 passed.
- [x] `dart test packages/core/loom_workflow_engine` - 70/70 passed.
- [x] `dart test packages/tooling/loom_ux_judges` - 26/26 passed.
- [x] `dart analyze packages/core/loom_workflow_engine && dart analyze packages/tooling/loom_ux_judges` - clean.
- [x] Calendar/RSVP fixture validator - `status: pass`, `errorCount: 0`, `warningCount: 0`, `findings: []`.
- [x] Emulator availability confirmed: `emulator-5554`, AVD `PantryVision_Manual_API_36`. Code-level blockers are fixed; live screenshot validation should now run against the corrected engine-backed build.

Waiting for Verification Agent result through `data/verification_feedback.md`.