# Loom Communities — Engine-Native Rebuild (V3, tracker 3)

Status: In progress — opened 2026-07-13 during Milestone 1.20's human sign-off review.

Continuation of [Loom_Communities_Workflow_Engine_2.md](./Loom_Communities_Workflow_Engine_2.md)
(milestones 1.1-1.20; its 1.20 row points here). The original
`Loom_Communities_Workflow_Engine.md` is untouched.

## 1. Why this rebuild exists

Milestone 1.20's human review — the first hands-on walk of *every* tab, not just Ballot — found real
defects, and investigating them surfaced something bigger: the repo has **two JSON schemas** for
declaring workflows, and the app only loads the shallow one.

- **The real, engine-native schema** (`workflowDefinitions` → states/transitions/guards/effects/
  renderBindings/instanceDataSchema) is genuinely parsed (`LoomWorkflowStateMachine.fromJson`) and
  genuinely executed (`LocalWorkflowEngineApi`: real guards, real effects incl. `branch`/
  `createInstance`/cross-instance `set`, a real formula evaluator). **But nothing loads it from an
  installed package at runtime.** The V2 `.jsonc` files are design references, hand-copied into Dart
  string literals or inline `const` objects — one hand-written engine-store class **per feature**,
  ~20 times over in `part02_tab_shell.dart` alone (the Tournament Ballot included).
- **The shallow schema** (`experience.workflows[]`: flat title/entryText/actionText cards) IS what
  loads. It cannot express a state machine, guard, or formula — unmatched workflows fall to a generic
  fact-pill card.

Every "real" feature this effort has built so far is the bespoke-Dart pattern. That is precisely the
anti-pattern the archetype audit exists to kill, and it would break Phase 3 (the Skill)'s "JSON only,
no code" promise on day one.

**Direction (user, 2026-07-13): rebuild Tabletop Club on the engine-native schema for real** — every
workflow, transition, interaction, effect, and formula declared in JSON and executed by the real engine
("real APIs, stubbed transitions" — which is exactly what `LocalWorkflowEngineApi` already is).

**Strategy (user, 2026-07-14): one tab at a time, Calendar first.** Phase A builds the whole pipeline
(load → engine → formulas → guards → generic renderer → binding dispatch) but wires only the **Calendar**
tab to it, then stops at a **human gate** so the JSON, archetypes, formulas, and APIs can be inspected
and corrected on a small surface **before** the same pipeline is scaled to every other tab. Cheap to
fix here; expensive to fix after six tabs are built on a wrong assumption.

## 1a. Archetype UI Design gate (added 2026-07-15 — blocks Phase G; retroactively found)

**Finding:** re-verifying every one of Tabletop Club's 9 archetypes directly against the Dart source
(not against this tracker's own prior `[x]` claims) found two distinct, unclosed problems — full evidence
and file:line citations now live permanently in
[`archetypes/README.md`](../../../references/archetypes/README.md):

1. **Generic-widget problem (`event-rsvp`, `equipment-loan`, `paymentCheckout` — 🟡 PARTIAL).** Each has a
   real, rich *browse/shell* (Calendar's month grid, Marketplace's search+grid+filter, Giving's
   amount/history header) — but the actual per-item **interaction** (RSVP going/maybe/waitlist,
   borrow/queue/return, the pay action) still calls the exact same shared
   `WorkflowCardSurfaceTemplateRenderer` fact-pill-row + button-row widget every other archetype falls
   back to. A.8/A.9 closed real, verified Calendar-chrome work — but their acceptance criteria never
   required the RSVP interaction itself to stop being generic, and this tracker's own §5a rule ("flip
   status to REAL") was applied to Phase A without re-checking that specific claim against source. **That
   is exactly the failure mode §3a exists to prevent, just found in documentation instead of in the JSON.**
2. **Unreachable-widget problem (`votePoll`, `discussionThread`, `notificationInbox`, `statusTimeline`,
   `formEntry` — ✅ REAL widget, but only reachable through a hardcoded dispatch).** A genuinely rich,
   bespoke widget exists for each — but every one is wired through a **hardcoded `rendererId` switch**
   keyed to a **fixed tab** (`_TournamentBallotTabSurface` only renders because `tabId == 'ballot'` maps
   to `rendererId: 'TournamentBallotTabSurface'` in a static contract table), reading a Tabletop-Club-only
   special JSON block (`experience.tournamentBallot`), **not** by resolving the workflow's own
   `renderBindings`/`cardSurfaceFamily` from `workflowDefinitions`. A brand-new community's JSON declaring
   `cardSurfaceFamily: "votePoll"` today gets **none of this** — there is no generic path from that string
   to this widget. A real, separate, generic path DOES exist —
   `EngineNativeBindingDispatcher`/`resolveBindings()` — but it is enabled for exactly one tab
   (`_enabledTabs = {'calendar'}`), and whether Tabletop Club's own running install currently exercises it
   for Calendar (vs. still falling back to the legacy hardcoded path) was **not verified live this pass**.

**Consequence — this is now a hard, explicit closing gate:** Tabletop Club is not a finished reference
community, and Phase G (retirement/closeout) does not start, while **any of its 9 archetypes fails either
test**: (a) does a genuinely bespoke, rich widget exist for the interaction, **and** (b) does declaring
that `cardSurfaceFamily` in `workflowDefinitions`/`renderBindings` JSON alone — with no hardcoded
per-community wiring — actually produce that widget. Both must hold. Folded into each phase below as an
explicit acceptance criterion, not a separate phase (Phases C/D/E already own `equipment-loan`/
`paymentCheckout`/`approvalQueueItem` respectively; a new milestone **A.11** is added to Phase A for
`event-rsvp`, since A.8/A.9 already closed without it).

**Standing instruction (user, 2026-07-15), binding on every future milestone in this tracker:** updating
[`archetypes/README.md`](../../../references/archetypes/README.md)'s status table — re-verified against
the actual Dart source, never carried forward from a prior claim — is part of that milestone's own
definition of done, the moment it makes any archetype real (or partially real). This is not a follow-up
task for a later session. §5a below is amended accordingly.

## 1b. Scope correction, 2026-07-16 — A.11's closure surfaced a systemic gap affecting Phases B-F

A.11 (`event-rsvp`) closed cleanly because Calendar had already received Phase A's full pipeline
treatment (A.4 parsing, A.5 shared engine, A.7 binding dispatch, A.8 end-to-end proof) — A.11 only needed
to swap the generic per-item widget for a bespoke one at an already-proven-live call site. **Investigating
Phase C (Marketplace) to draft its own ticket found this is not true anywhere else**:
`EngineNativeBindingDispatcher._enabledTabs` (`part27_engine_native_binding_dispatcher.dart:70`) is
**`{'calendar'}` — exactly one tab.** Every other tab (`home`, `marketplace`, `giving`, `admin`,
`messages`) still loads its content through the legacy per-feature mechanism: either a Shape-B special
top-level field (confirmed for Marketplace: `_MarketplaceBrowseSurface` reads
`experience.marketplaceListings`, `part02_tab_shell.dart:4177-4189` — not `workflowDefinitions`/
`workflowInstances` at all) or a hardcoded `rendererId` switch (confirmed for the ballot, and — per
`archetypes/README.md`'s already-documented "unreachable-widget problem" — the same mechanism behind
`discussionThread`/`notificationInbox`/`statusTimeline`/`formEntry`).

**Consequence:** Phases B, C, D, E, F are each bigger than the tracker originally scoped them — every one
needs its own equivalent of Calendar's A.4/A.5/A.7/A.8 pipeline work (parse the real `workflowDefinitions`
for that tab's community, wire a shared engine, extend `_enabledTabs`, prove it end-to-end) **before**
any bespoke-widget archetype fix in that tab is meaningful. None of B/C/D/E/F should be dispatched as a
single ticket the way A.11 was — each needs its own milestone breakdown first, mirroring Phase A's own
structure. This is not yet done for any of them (see the corrected Phase index below); it is the next
piece of design work, not implementation, and is exactly the kind of scope decision that should go back to
the user rather than being sized unilaterally.

## 1c. Generic pipeline extraction (GP), 2026-07-17 — the concrete mechanism closing §1b's gap

§1b found that `_enabledTabs = {'calendar'}` (`part27_engine_native_binding_dispatcher.dart:70`) blocks
every tab but Calendar from the generic engine-native pipeline, and that opening a tab needs its own
Calendar-style milestone sequence (parse → shared engine → binding dispatch → end-to-end proof) before a
bespoke archetype widget in that tab means anything. Investigating what Calendar's proven pipeline
actually consists of found `EngineNativeBindingDispatcher` itself (querying instances, resolving
`renderBindings`) was **already fully tab-agnostic** — `_enabledTabs` is its only tab-specific gate. What
was NOT generic was the per-instance archetype-rendering decision (`cardSurfaceFamily == 'event-rsvp' →
bespoke widget, else → generic card`), which lived inlined, once, only inside Calendar's own detail-panel
code (`part28_engine_native_calendar_surface.dart:446-472`, added by A.11).

**GP.1 (2026-07-17, complete):** extracted that inline dispatch into a new shared, tab-agnostic
`EngineNativeArchetypeCard` widget (`part27_engine_native_binding_dispatcher.dart`), and migrated
Calendar's detail panel to call it — a pure, behavior-preserving extraction proving the shared piece
works before any other tab depends on it. `_enabledTabs` intentionally untouched (still `{'calendar'}`
only). Implementation deviated from the ticket sketch in one deliberate, correctly-reasoned way: the
widget takes a `contentKey` parameter applied directly to the inner archetype widget, rather than the
ticket's `key: key` forwarding, to avoid inserting an extra keyed element into the tree. Verified
independently: `dart analyze` clean, full `loom_communities_app_shell` suite 83/83 (including
`v3_milestone_a8_calendar_end_to_end_test.dart` and `v3_milestone_a11_event_rsvp_archetype_test.dart`
unmodified), plus a live emulator re-check confirming the RSVP detail card still renders identically
post-extraction. Commit `fb78805`.

**Correction to §1b's cost estimate (2026-07-17):** checked directly against source rather than assumed.
A.4 (`part15_evidence_catalog.dart:240-302`, `_experienceFromEngineNativeConfiguration` or equivalent)
parses **every** entry in `experience.workflowDefinitions` with no tab filtering — all 11 workflow types,
not just Calendar's. A.5 (`_EngineNativeCommunityStore._initialize`,
`part25_engine_native_community_store.dart:57-92`) registers **every** parsed definition and seeds
**every** `workflowInstances` entry onto the one shared engine at install time — also with no tab
filtering. **Both were already fully generic before A.11/GP.1** — they were never Calendar-specific, only
exercised by Calendar so far because nothing else queried the results. §1b's framing ("every other tab
needs Calendar's whole A.4/A.5/A.7/A.8 sequence repeated") overstated the remaining cost: A.4 and A.5 are
**done, for every tab, today** — no new ticket touches them. What actually remains, per tab, is only:

1. A generic **list/feed surface** (GP.2, not yet built) — analogous to Calendar's month-grid content
   widget, but for tabs without calendar semantics: wraps `EngineNativeBindingDispatcher` +
   `EngineNativeArchetypeCard` for a `displayContext: 'tile'` list. Built once, reused by every remaining
   tab (this is the actual generic-pipeline payoff — one surface widget, not five).
2. Widen `_enabledTabs` (`part27_engine_native_binding_dispatcher.dart:70`) to include that tab.
3. Wire that tab's real entry point in the tab shell to the new surface, in place of (or alongside,
   during transition) whatever legacy/hardcoded mechanism currently renders there (Shape-B special field
   for Marketplace, hardcoded `rendererId` switch for Home's ballot, etc. — per §1b's citations, still
   accurate for what each tab's *current* content is fed by).
4. An end-to-end proof test for that tab, analogous to A.8.

Prove this smaller shape on one tab (next candidate: Home, since Phase B is first in the index and the
ordering note already says B-F can be reordered/parallelized) before touching the rest.

**GP.2 (2026-07-17, complete):** proved the smaller shape above on the Giving tab (one workflow type,
no bespoke archetype — proves the *generic fallback* path specifically, not just the bespoke-archetype
path GP.1 proved on Calendar). Built `EngineNativeListSurface` (`part32_engine_native_list_surface.dart`)
— the non-calendar analog of `EngineNativeCalendarSurface`: wraps `EngineNativeBindingDispatcher` +
GP.1's `EngineNativeArchetypeCard` in a plain `Column` (a nested `ListView` threw "unbounded height" once
embedded in the tab shell's own scrollable content — fixed to match Calendar's own established `Column`
pattern, not a new one). Widened `_enabledTabs` to `{'calendar', 'giving'}` and added a new
`_hasEngineNativeBinding(experience, tabId)` helper — Giving's own tab-visibility gate in
`appShellTabsFor` (`part12_persona_and_tabs.dart`) was missing the engine-native OR-condition Calendar's
gate already had, so the Giving tab never appeared in the bottom bar at all for engine-native communities,
independent of anything else GP.2 changed — found only by independently re-running the real test suite,
not by trusting the implementation agent's (sandbox-blocked, honestly-reported-as-such) self-report. Four
rounds total (GP.2/2b/2c/2d): a stale A.7 "disabled tabs" test-list assertion, the missing tab-visibility
gate, the layout crash, and a test not waiting for `GenericWorkflowInstanceCard`'s own second async load.
Independently verified: `dart analyze` clean, 84/84 `loom_communities_app_shell` tests. Commit `bad6f1b`.

**Next candidates, not yet started:** Home (bigger — spans 4 workflow types across several
`cardSurfaceFamily` values, no bespoke widget for most of them yet) or Marketplace/Admin/Messages, each
needing its own tab-shell wiring investigated on its own (Home in particular does not go through the same
`rendererId` switch Giving/Calendar do — confirmed by grep, not yet designed).

## 1d. Calendar archetype redesign (CALR), 2026-07-17 — architecturally-pure RSVP tracking + real event creation + multi-view container

Live review of the running app (user driving the emulator directly) surfaced three product gaps in the
`event-rsvp` archetype, on top of GP's generic-pipeline work: (1) Calendar only ever showed a 7×6 month
grid — no day view, no week view, no way to see events scoped to a smaller window; (2) the event/RSVP
"archetype" was a single always-expanded detail card, not a scoped list of cards; (3) there was no way
for the organizer to create a new Calendar event at all — `creatable` (GAP-2, closed at the grammar layer
2026-07-16) had zero real consumers anywhere in the app. Working through the fix with the user surfaced a
deeper, explicitly-requested architectural change: **`event-rsvp`'s RSVP tracking moves from four
`personaId[]` list fields to a real per-row table** (`event-rsvp-response`, one row per community member
per event — the same `tournament-vote`/GAP-4 pattern already proven by `tournament-ballot`), because a
list-field capacity guard cannot be evaluated live against per-row data without a guard capability that
did not exist. **User's explicit instruction: "we are building for production... do not descope,"
architecturally pure over expedient — Option B (the per-row conversion) chosen deliberately over the
cheaper Option A (keep the list, expose `goingCount` as a facet).**

**Spec-design phase closed 2026-07-17** (JSON + reference docs only, no code, no tracker — per explicit
user instruction to review the spec before any implementation starts). Full design conversation and
grounding is preserved in the session transcript; the artifacts are:

- **Frozen JSON**: new `event-rsvp-response` workflow type (states pending/going/maybe/declined/
  waitlisted, real mutable transitions — unlike `tournament-vote`'s insert-only rows, a response can
  change); `event-rsvp` rewritten onto query-backed aggregates (`responses`, `responseCounts` via
  `groupCount(responses, '$state')`, `goingCount`/`maybeCount`/`declinedCount`/`waitlistedCount` via
  `mapGet`, `isFull`/`hasWaitlist`/`seatsRemaining` derived from those) and gains `creatable`/
  `responseTable`/`filterableFacets`; `tournament-event` gains `creatable` only (its RSVP tracking
  deliberately NOT converted — see the explicit gap below); `tournament-ballot` gains `creatable` (invoked
  from the tournament-event's own card via `{context.eventId}` prefill) + `editableFields` on its `open`
  state + a computed `dueAt` (was hand-seeded, now `subtractHours(deadline, ...)` — a real formula,
  removing a driftable stored value); seed data converted to 13 real per-account `event-rsvp-response`
  rows for Friday game night, preserving the exact prior going/maybe/pending scenario (validated
  structurally — no orphaned references).
- **New engine/validator grammar, PROPOSED (not yet implemented — see `spec-version.json` →
  `proposedNotImplemented`)**: `guards.md` kind 7 `relatedAggregate` (a live count/sum over a related
  table vs. a threshold, evaluated by the caller pre-computing the aggregate via the existing real
  `aggregate()` method before the still-synchronous `evaluateGuard` runs — same pattern already used for
  `completedWorkflowIds`); `formulas.md`'s `subtractHours`/`mapGet` functions and `$state` reserved column
  (exposes a query-backed row's own FSM state to `groupCount`, which today only sees raw `instanceData`);
  `render-bindings.md`'s `responseTable`/`filterableFacets` keys (point a calendar-family archetype at its
  response table and named facets generically, not via hardcoded field-name assumptions).
- **A real doc-accuracy correction found while grounding this**: `formulas.md`/`spec-version.json`
  previously claimed unary `!` was unsupported alongside `!=`. Verified directly against the parser
  (`formula_evaluator.dart:458-462`/`:236`) — only `!=` is actually absent; `!` genuinely works. Corrected
  in both docs, recorded in `spec-version.json` → `resolvedQuestions.unaryNotOperator`.
- **`archetypes/README.md`**: `event-rsvp` reopened from ✅ REAL to 🔨 REBUILDING with full context —
  the A.11 closure evidence describes the pre-redesign shape, now superseded.
- **`tabletop-club.md`**: new user stories (Day/Week/Month/Pending views; organizer creates a Calendar
  event; organizer creates a tournament ballot), §11 review-log entry recording the full rationale.

**Explicit, deliberately deferred gap — not silently done, needs its own decision later:**
`tournament-event`'s own RSVP tracking (`goingPersonaIds`) was NOT converted to the per-row pattern in
this pass — it has no capacity ceiling (only an unenforced `minimumAttendance` quorum), so reusing
`event-rsvp-response` verbatim would apply the wrong guard semantics. Converting it for full consistency
would need a second, simpler response type and rewriting `tournament-ballot`'s eligibility guard from
`relatedListMembership` to a `relatedAggregate` existence check. Tracked, not scheduled.

**Implementation milestones (this section), engine-native, `event-rsvp` archetype only — Calendar tab
only, Tabletop Club only. Do not touch Home/Marketplace/Giving/Admin/Messages or any other community in
this phase. Once CALR closes and is human-reviewed, the same pattern extends to other tabs, then other
communities — not before.**

**Addendum 2026-07-21 — `creatable` replaced by `actions[]`, expanding CALR.4's scope.** A FAB-design
conversation (context engine / in-focus tracking, predefined-vs-generic FABs, nested-tables-per-tab)
surfaced that the flat `creatable` object could express only one shape ("brand-new instance, tab FAB")
and had no way to express (a) an action related to one specific existing instance (a button or contextual
FAB on that card — exactly what bare CALR.4 below needed for "Create ballot for this tournament"), or (b)
giving one specific *transition* (not a create) its own distinguished FAB/button instead of leaving it in
the automatic row. Both gaps are now closed at the grammar layer: `render-bindings.md`'s `actions[]` is a
two-kind model (`kind: "create"` / `kind: "transition"`), `scope` (`tab` | `instance`) and `presentation`
(`fab` | `button`) are orthogonal, and `{context.*}` resolves from the host/in-focus instance for both
kinds. See [`guide/07-actions-and-fabs.md`](../../../references/guide/07-actions-and-fabs.md) for the full
decision procedure. **This is a real grammar bump (`creatable` removed, not just extended) plus new scope
beyond the original CALR.4** (the `kind: "transition"` FAB pattern was not anticipated when CALR.4 was
first scoped) — bare CALR.4 below is superseded by CALR.4a/CALR.4c-CALR.4h (skipping `4b`, already taken
by the member-login milestone).

**Frozen JSON already migrated (2026-07-21, commit pending — see CALR.4a):** all 6 former `creatable`
bindings in the Tabletop Club fixture are now `actions[]` (5 tab-scoped creates, 1 instance-scoped create —
"Create ballot for this tournament", moved onto `tournament-event`'s own binding per the locked
cross-archetype rule — and 1 `kind: "transition"` action — `equipment-loan`'s `borrow` transition pulled
into a "Request loan" contextual FAB). **This fixture change is deliberately NOT yet committed**: it has
zero `creatable` keys left, but `part01_local_extension_screen.dart:870-891`/`:1181-1184` still reads
`binding.creatable?.byPersonaIds`/`.label` to build the tab FAB (`RenderBinding.fromJson`,
`workflow_models.dart:380-405`, has no `actions` handling at all) — committing the fixture standalone
would silently empty every tab's FAB and fail `v3_calr3g_creatable_action_fab_test.dart`'s
`ValueKey('creatable-fab-speed-dial')`/`creatable-fab-event-rsvp` assertions. It lands in the same commit
as CALR.4a's parser/dispatch migration, not before.

| # | Milestone | Depends on | Status |
|---|---|---|---|
| CALR.1 | Engine + validator: `createInstances` (new abstract `WorkflowEngineApi` method, atomic bulk-create), `relatedAggregate` guard (model + evaluator + caller-side pre-computation in `applyTransition`/`availableTransitionsAsync`), `$state` reserved column in `_readAllInstancesOfType`/`aggregate()`, `subtractHours`/`mapGet` formula functions, and the matching validator rules (`loom_ux_judges`) for `relatedAggregate`/`responseTable`/`filterableFacets`. No UI. | none | `[x]` Done — commits `fd7a8ea` (CALR.1), `30d87ce` (CALR.1b: fixed a fail-open `relatedAggregate` guard bug and a missing `$id` on hydrated rows, both found via my own diff review). dart analyze clean, 137/138 tests, real validator 0/0. |
| CALR.2 | RSVP archetype rewire: the RSVP detail card's action buttons call `applyTransition` on the viewer's own `event-rsvp-response` row (found via query), not the event instance. Proves the new per-row model end-to-end against the ALREADY-seeded Friday game night data — no event creation needed to test this milestone. | CALR.1 | `[x]` **Done, live-verified 2026-07-19.** Commit `5d2240b`, six rounds (CALR.2/2b/2c/2d/2e/2f): identity-resolution test bugs, an `InputChip` widget-cast bug, and one real production bug found via my own code reading (the organizer's own RSVP response row was shadowing their organizer-only `cancel-event` action). First live walkthrough found no installable package matched the redesigned schema (every prior "live emulator re-check" this cycle, including CALR.1/1b's, was almost certainly checking stale pre-redesign data) — fixed via CALR.2g/2h (commits `456ac56`, `df128da`, `c241f1d`): reusable generation script `app/packages/core/loom_communities_app_shell/tool/generate_tabletop_club_package.dart` regenerates a real installable package at `.codex-logs/ext_verify_tabletop_club.loom-{extension,init}.zip`, plus a permanent regression test. 86/86 tests, dart analyze clean. **Re-run live walkthrough against the regenerated package confirmed the must-fix bug live**: organizer sees Maybe/Cancel event/Going/Can't go together, tapping Cancel event removes it permanently (survives navigating away and back). |

**Live-walkthrough findings, not blocking CALR.2 closure:**
- **Real member-persona testing is unreachable through the live app's own UI** — slotted into the milestone table below as **CALR.4b**, since CALR.5's own acceptance methodology depends on it.
- No visual "cancelled" indicator appears on the event card after a successful cancel — only the button's disappearance signals it.
- Response-row actions (Maybe/Going/Can't go) stayed enabled after the event was cancelled, seemingly at odds with `tabletop-club.md`'s expectation that past/cancelled events remain read-only.

| CALR.3 | Real event creation: "+ New event" (event-rsvp only — split from tournament creation to keep milestone size manageable, given CALR.2 alone took eight rounds) consuming `creatable` + `editableFields`. `creatable`/`CreatableSpec` has been fully parsed/validated since GAP-2 but has zero real consumers anywhere in the app — this milestone builds the first one. Calls `createInstance` for the event and `createInstances` for its bulk per-member response rows. | CALR.1, CALR.2 | `[x]` Creation flow done and verified (commit `3aebf07`, plus `3572f5b`/`8e3ba85` fixing a vacuous test and a viewport regression — 88/88 tests). **The FAB affordance itself is not yet closed** — see CALR.3g/3h below. Three attempts (CALR.3e, CALR.3f, CALR.3f2) tried variations of a nested `Scaffold` and were all reverted after real regressions; the corrected design attaches the FAB to `LocalExtensionScreen`'s existing top-level Scaffold instead — see CALR.3f's row for the root-cause writeup. |
| CALR.3f | **ABANDONED 2026-07-20** — tried to give the active tab bounded height in `_TabNativeRenderer`/`LocalExtensionScreen` (via `Expanded`, then via `CustomScrollView`+`SliverFillRemaining` in a follow-up round) so a nested `Scaffold`+FAB could live inside a tab's own content. Both attempts reverted (`b06f0e2`) after regressions up to 18 test failures. **Root cause found**: `SingleChildScrollView` always gives unbounded height to its child regardless of what bounds the scrollview itself — a nested Scaffold inside that child can never get bounded constraints, no matter how the outer layers are restructured. This whole approach was solving the wrong problem; see CALR.3g. | CALR.3 | `[x]` Abandoned, reverted, superseded by CALR.3g |
| CALR.3g | **Stage 1 of the corrected design**: generic creatable-action FAB attached directly to `LocalExtensionScreen`'s **existing** top-level Scaffold (`part01_local_extension_screen.dart:762` — already bounded, already computes `selectedTab`/`activePersona`/`experience` in `build()`) — no nested Scaffold, no layout restructuring anywhere. Detects every `creatable` binding matching the current tab + viewer persona (naturally reloads on every tab switch, since `selectedTab` is already a `build()`-local value); resolves `creatableAction.multiActionStyle`/`tabCreatableActionStyles` (render-bindings.md) to render `speedDial`/`stacked`/`singleFirst`. Tapping an action reuses CALR.3's existing creation dialog as-is for now (moved, not rebuilt) — proving the FAB mechanism in isolation before CALR.3h adds presentation style + the generic archetype-in-create-mode dispatch. Deliberately split from CALR.3h given how expensive the CALR.3e/3f single-shot attempts got. | CALR.3 | `[x]` **Done, production code verified correct on the first round** (commit `2f7d355`'s ancestor `6ea90f2`/`db018ca`: FAB on the real Scaffold, all 3 `multiActionStyle` variants, correct reused-dialog wiring — `part28`'s old inline button correctly left untouched for CALR.3h). **Its own new test took six rounds to get green** (CALR.3g2-3g6) chasing one recurring hit-test-miss failure. Root cause, finally confirmed via temporary diagnostic instrumentation (CALR.3g5: `debugPrint`+`debugDumpRenderTree()`, run by the verification agent directly since the implementation sandbox's Flutter cache is read-only and cannot execute `flutter test`): the test's own premise was wrong, not any product code. The frozen Tabletop Club fixture actually declares `tournament-event` as *also* `creatable` on `tabId: "calendar"` for the same `tabletop-organizer` persona as `event-rsvp` — so the real fixture has **two** creatable actions on Calendar, not one, and with the community's default `multiActionStyle: "speedDial"`, the rendered widget is the closed speed dial (target mini-FAB hidden behind `IgnorePointer(ignoring: true)`+`AnimatedOpacity(opacity: 0)`), not the bare single-action FAB the test assumed. Three earlier rounds (broadening a text assertion, adding `ensureVisible`, adding a settle-pump) all failed to change the outcome because none addressed the real cause. Fixed (CALR.3g6, commit `fdf9a2c`) by opening the speed dial before tapping the target mini-FAB, mirroring the already-passing parametrized `speedDial` test's own pattern. 92/92 tests, dart analyze clean — both independently re-run by the verification agent. |
| CALR.3h1 | **Stage 2a**: `creatableAction.presentationStyle` (`popup`/`slideOutBottom`/`slideOutLeft`/`slideOutRight`, render-bindings.md), wrapping CALR.3g's existing, unmodified creation dialog content in the right presentation container — `popup` via the official Flutter-team `animations` package's `OpenContainer` (Material's "container transform": expand from the FAB, hover, shrink back on close); `slideOutBottom` via `showModalBottomSheet`; `slideOutLeft`/`slideOutRight` via `showGeneralDialog`+`SlideTransition`. Deliberately split from CALR.3h2's archetype-dispatch generalization, mirroring the same small-stages discipline as CALR.3g/3h's own split. | CALR.3g | `[x]` **Done.** Production code (all 4 presentation styles, resolution cascade, `animations` package dependency) verified correct on the first round. **Its own new tests took twelve rounds to get fully green** (CALR.3h1b–CALR.3h1l) chasing a `popup`/`slideOutRight` test hang, all independently diagnosed and verified by the verification agent (the implementation sandbox's Flutter cache is read-only and cannot execute `flutter test` at all, so every round's fix was verified directly by the verification agent in a working environment). Chronology: (1) traced an indeterminate `CircularProgressIndicator` + `pumpAndSettle()` hang (a well-known Flutter gotcha) and replaced it with bounded pumps (CALR.3h1b/c); (2) diagnostic prints (`debugPrint`, run by the verification agent) pinpointed the hang to a `queryInstances` call wrapped in a *second*, separate `tester.runAsync()` — combining it into one call, matching this repo's own proven pattern, seemed to fix it (CALR.3h1d–f); (3) discovered `popup` and `slideOutRight` couldn't run in the same process without one hanging the other, isolated each into its own test file, and scoped `popup`'s own test down to open-only since the full submit flow was already proven via other tests (CALR.3h1g–j); (4) **this cross-test-isolation theory turned out to be a false lead** — `slideOutRight`, run completely alone in its own new file, still hung, proving the issue was never about `OpenContainer` or cross-test interference at all; (5) the real root cause, found by comparing against the proven-working `v3_milestone_a8_calendar_end_to_end_test.dart` pattern: the workflow engine's real sqlite-backed database connection was first created inside a *pumped widget* (Flutter's fake test-async zone, when the app's own creation dialog first called `workflowEngineForExtensionId`), then accessed later from `tester.runAsync()`'s real async zone for the test's own `queryInstances` call — a genuine zone-crossing on a native resource. Fixed (CALR.3h1k/l, commits `0fca6f1`) by pre-warming the engine (`experienceForExtensionId` + `workflowEngineForExtensionId`) inside the test's own `_install` helper, entirely within the same `runAsync` call used to install the community, matching the working milestone test's own explicit pattern exactly. **94/94 tests, dart analyze clean** — both independently re-run by the verification agent. Also fixed one incidental, unrelated discovery along the way: a git index corruption (0-byte `.git/index`, a known OneDrive-sync race) was hit twice during this saga's dispatch cycle; both times recovered safely via `git read-tree HEAD` (HEAD was always intact) with zero data loss, per this repo's own established recovery protocol. |
| CALR.3h2 | **Stage 2b**: generalizes CALR.3g/3h1's reused `_EventRsvpCreationDialog` into the real archetype `cardSurfaceFamily` dispatch in creation mode (so a workflow's creation form is the same archetype used to view/edit it, not a bespoke class) — extending `GenericWorkflowInstanceCard`/the `cardSurfaceFamily` switch in `part27_engine_native_binding_dispatcher.dart` with a genuine "no instance yet, create on submit" mode. Replaces `_EventRsvpCreationDialog` and the old inline Calendar-specific "New event" button (`part28_engine_native_calendar_surface.dart:345-354`, deliberately left untouched through CALR.3g/3h1) for good. | CALR.3h1 | `[x]` **Done.** Split into five small stages per user direction ("work completed approximately every 20 minutes with commits") — user explicitly overrode a leaner scoping (`no shortcuts, always build the architecturally pure implementation`), so **3h2b builds a genuine creation-mode `cardSurfaceFamily` dispatch switch with an explicit `event-rsvp` case even though it resolves to the same generic widget as `default` today** — mirroring `EngineNativeArchetypeCard`'s existing view-mode switch exactly, not skipped as premature abstraction. (1) **3h2a** (`6caa906`): new, purely additive `GenericWorkflowCreationCard` widget, zero callers — found and fixed 3 real bugs via independent verification the sandbox itself couldn't run (a missing closing brace; a double-escaped regex that silently didn't strip trailing punctuation; a corrected-but-still-wrong regex whose unescaped hyphen formed an unintended `U+003A`–`U+2013` character range, caught by reasoning through regex character-class parsing before it shipped, confirmed with a new regression test). (2) **3h2b** (`5921f2c`): `EngineNativeArchetypeCreationCard`, the creation-mode dispatch switch, still purely additive. (3) **3h2c** (`2bef983`): wired the FAB's event-rsvp path to it (`keyPrefix: 'new-event'`/`title: 'New event'` preserve every existing test's assertions exactly); deliberately kept scoped to event-rsvp only — the fixture's other creatable type (`tournament-event`) stays on the "not wired up yet" placeholder, since making it work for real is CALR.3b's own separate, not-yet-verified milestone, not a side effect of this one. (4) **3h2d** (`f7c8e1b`): found the old inline Calendar button was *not* dead code — two real tests in `v3_milestone_a11_event_rsvp_archetype_test.dart` exercised it directly (a full organizer-creates-event-with-response-rows check, and a hidden-for-non-organizer check) — migrated both to the FAB path before any deletion, preserving their exact verification value. (5) **3h2e** (`78aefe7`): deleted the now-genuinely-dead `_EventRsvpCreationDialog`/`_showNewEventDialog`/old inline button (part28: 1474→1199 lines); `_EventRsvpDetailCard`, the unrelated viewing archetype, untouched. **97/97 tests, dart analyze clean** at every stage, independently verified by the verification agent throughout (implementation sandbox hit persistent WSL vsock/networking errors blocking its own `dart`/`flutter` tooling all night). Also: git index corrupted twice more during this sequence (0-byte `.git/index`, the same recurring OneDrive-sync race) — recovered safely both times via `git read-tree HEAD`, zero data loss. |
| CALR.3b | Tournament creation: "New tournament" (tournament-event), same pattern as CALR.3 but for `tournament-event`'s own schema — deliberately deferred out of CALR.3. Its `creatable` FAB should land via CALR.3g/3h's generic mechanism, not a second bespoke implementation. | CALR.1, CALR.3h2 | `[x]` **Done** (`b0fcbef`). Generalized `_openCreatableAction`/renamed `_creationContentFor` to route **every** creatable workflow type through the real `EngineNativeArchetypeCreationCard` pipeline — retiring the "Creation for X is not wired up yet" `SnackBar` placeholder entirely, not just adding a second special case. `event-rsvp` keeps its exact existing `keyPrefix`/`onCreated` (response-row seeding); `tournament-event` gets `keyPrefix: 'new-tournament-event'` and `onCreated: null` — per the fixture's own explicit design (`...jsonc:351-355`), tournament RSVPs use a plain `goingPersonaIds` array field, not the response-row-table pattern, so no post-creation side effect is needed. Three follow-up rounds after independent verification (`3658168`): (1) the new test's own "no side-effect" check asserted zero `event-rsvp-response` rows exist community-wide, but the real fixture pre-seeds ~12 for Friday game night — fixed to a before/after count comparison; (2) retiring the placeholder broke an existing FAB test that still expected it for a synthetic second creatable action — updated to expect the real dialog opening instead; (3) that update's own first attempt hit the exact same label/dialog-title ambiguity CALR.3g2 fixed earlier tonight (bare `find.text` matching both the trigger and the dialog) — scoped to `find.descendant(of: find.byType(AlertDialog), ...)`. **98/98 tests, dart analyze clean** — independently re-run by the verification agent throughout (implementation sandbox hit the same persistent WSL vsock/networking errors blocking its own tooling all night; one round's `git commit` itself hung, worked around with `git commit-tree`/`update-ref` plumbing). |
| CALR.4 | **SUPERSEDED 2026-07-21 — see the addendum above and CALR.4a/CALR.4c-CALR.4h below.** Original scope ("Ballot creation: a second `creatable` affordance on the tournament-event's own card... resolving `{context.eventId}`") is now CALR.4e's job, expressed via `actions[]` (`{context.id}`, not `{context.eventId}` — the tournament instance's own id). | — | `[x]` Superseded, not implemented as originally scoped |
| CALR.4a | **Model + parser + tab-FAB dispatch migration.** Replace `creatable`/`CreatableSpec` with a new model (e.g. `WorkflowAction`) parsing `actions[]` for both `kind: "create"` and `kind: "transition"` per `render-bindings.md` (`RenderBinding.fromJson`, `workflow_models.dart:380-405`, currently only reads `json['creatable']` — zero `actions` handling exists anywhere in this file). Migrate the FAB-detection code in `part01_local_extension_screen.dart:870-891`/`:1181-1184` (currently reads `binding.creatable?.byPersonaIds`/`.label` to build `creatableActions`) to read `actions[]` filtered to `kind: "create", scope: "tab"` instead — **zero behavior change** for every already-shipped tab FAB (`event-rsvp`'s "New event", `tournament-event`'s "New tournament"). **Must land in the same commit as the frozen fixture's `creatable`→`actions[]` migration** (already written, deliberately held uncommitted — see the addendum above) — the fixture alone regresses `v3_calr3g_creatable_action_fab_test.dart` otherwise. | CALR.3b | `[x]` **Done** (`9e8c9e9`). `WorkflowAction`/`RenderBinding.actions` parse the complete grammar-v2 shape for both kinds (not just the tab-scope subset this round renders); the tab-FAB dispatch and the FAB test's synthetic second-action fixture were migrated with zero behavior change. `workflow_validator.dart`'s three existing `creatable`-based checks were migrated onto `actions[]` (required to keep it compiling at all once `creatable` was removed — not full new-rule scope, that stays CALR.4c) and `context_reference_outside_creatable` renamed to `context_reference_outside_instance_action`. **Two rounds**: the implementation sandbox hit its own `WSL ERROR: UtilBindVsockAnyPort:307: socket failed` in both rounds and could not run any of its own tooling or commit anything — every check below was run independently by the verification agent. Round 1's diff review was clean, but the verification agent's own real-CLI-validator run (not the sandbox's, which never ran) found a genuine bug the ticket itself hadn't anticipated: `_checkCreatablePrefill` validated a cross-archetype create action's `prefill` keys against the *binding's own* `instanceDataSchema` instead of the *target `workflowType`'s* schema — a false-positive `dangling_instance_data_key` on exactly `tournament-event`'s "Create ballot for this tournament" action (correct under old v1 `creatable`, which had no `workflowType` override, but wrong for v2's cross-archetype case). Round 2 fixed it (`allWorkflows[action.workflowType ?? machine.workflowType]`, silently skipping an unresolvable target rather than adding a new `dangling_action_workflow_type` rule ahead of CALR.4c) with a dedicated regression test. **Final counts, independently verified**: `loom_workflow_engine` 139/139, `loom_ux_judges` 87/87, `loom_communities_app_shell` 98/98, `dart analyze`/`flutter analyze` clean in all three (2 pre-existing, unrelated `unused_element_parameter` warnings in `v3_milestone_aprime_validator_test.dart`'s `_machine()` helper, present before this ticket, left alone), real CLI validator against the frozen fixture 0 errors/0 warnings. |
| CALR.4c | **Validator: full `actions[]` grammar-v2 rule set**, both kinds — `unknown_action_kind`, `unknown_action_scope`/`unknown_action_presentation`, `tab_action_cannot_be_button`, `dangling_action_workflow_type`, `dangling_instance_data_key`/`computed_field_written_by_effect` extended to `actions[].prefill`, `context_reference_outside_instance_action`, and the `kind: "transition"`-only checks: `dangling_action_transition_id`, `transition_action_cannot_be_tab_scoped`, `transition_action_cannot_set_workflow_type`/`_prefill`/`_by_persona_ids`, `unknown_action_input_reference`, `duplicate_action_transition_id`, `create_action_cannot_set_inputs` (full list: `render-bindings.md`'s validator-checks table). **User-requested explicitly, 2026-07-21**: confirm the frozen Tabletop Club fixture passes the *real* updated validator with 0 errors/0 warnings — today's 0/0 only proves the current v1-grammar validator silently ignores the unknown `actions` key, not that the new rules actually pass it. | CALR.4a | `[x]` **Done** (`6b8b260`). All 13 new checks added, each with a flagged-case + passing-case test via a shared `actionRule()` test helper — `dangling_action_workflow_type` correctly errors on an unresolvable `workflowType` while preserving CALR.4a round 2's fix for the *resolvable* cross-archetype case (`_checkCreatablePrefill`'s existing schema-target resolution untouched). Implementation sandbox hit the same `WSL ERROR: UtilBindVsockAnyPort:307: socket failed` both this ticket and CALR.4a's two rounds — every check below was run independently by the verification agent. **113/113 tests, `dart analyze` clean** (2 pre-existing, unrelated `unused_element_parameter` warnings, unchanged since CALR.4a), **real CLI validator against the frozen fixture: 0 errors/0 warnings against the complete new rule set** — confirming the fixture's instance-scoped cross-archetype create (tournament-ballot) and transition action (equipment-loan's "Request loan") are genuinely valid grammar-v2 JSON, not just unchecked. |
| CALR.4d | **Focus/context tracker.** A real "which card is currently in focus" mechanism (App Shell state, not grammar) — needed by both `scope: "instance", presentation: "fab"` create actions and any `kind: "transition", presentation: "fab"` action. Exposes the in-focus instance's id/fields for `{context.*}` resolution. | CALR.4a | `[x]` **Done** (`68faad0`). Exposed, not rebuilt: `_CalendarPresentationController` (`part28_engine_native_calendar_surface.dart`) already tracked which agenda entry was selected, on real user taps (`_selectEntry`, the date-strip selector) and via a sensible default (`_reconcileSelection`) — this ticket only exposes that same selection's full `WorkflowInstance` externally via a new `onFocusedInstanceChanged` callback, kept in sync at all three existing call sites through one new `_setSelectedEntry` helper, threaded through `_TabNativeRenderer` into `LocalExtensionScreen`'s own `_focusedInstanceForActiveTab` state — mirroring CALR.4e's `onInstanceScopedCreate` threading pattern exactly. Deliberately plumbing-only: no FAB, no UI, no `{context.*}` resolution added yet (CALR.4f's job). New widget test proves the callback fires correctly both on initial default and on an explicit tap, using the already-proven `v3_milestone_a8` test harness (not the flaky two-instance pattern CALR.4e hit). Implementation sandbox hit the WSL vsock error again during its own post-edit verification — the new hardening in `data/call_implementation_agent.sh` (see the addendum's dispatch-reliability note) flagged it immediately and correctly, and the real edits were confirmed intact in the working tree before proceeding. **Independently verified: flutter analyze 1 expected warning** (`_focusedInstanceForActiveTab` unused — by design, resolved when CALR.4f starts reading it), **full suite 101/101.** |
| CALR.4e | **Instance-scoped CREATE, `button` presentation** — the actual ballot-creation deliverable (bare CALR.4's original scope): render `tournament-event`'s "Create ballot for this tournament" button on each tournament card, resolve `{context.id}` (the tournament instance's own id — **not** `{context.eventId}`, corrected during the redesign) into the creation form's prefill, call `createInstance`. Proves the cross-archetype rule end-to-end (the action is declared on `tournament-event`'s binding, not `tournament-ballot`'s). | CALR.4a, CALR.4c | `[x]` **Done** (`cd946ad`), **11 rounds** — by far the longest of this cycle. New `resolveInstanceScopedPrefill` helper resolves `{context.id}`/`{context.<field>}` from the tapped card's own instance (never a fixed value); threaded via a new `EngineNativeInstanceScopedCreate` callback through both the Calendar and generic list surfaces into the existing `EngineNativeArchetypeCreationCard`/`GenericWorkflowCreationCard` pipeline (new `resolvedInitialValues` param). **Real regression caught and fixed** (round 2): an early attempt routed `tournament-event` away from its shared `_EventRsvpDetailCard` widget (which intentionally renders both `event-rsvp` and `tournament-event`, same `cardSurfaceFamily`) — fixed by adding the button to the shared widget instead of rerouting. **Two genuine, previously-undiscovered production bugs found via this ticket's own end-to-end test** (tournament-ballot creation was never reachable through any UI before this ticket, so nothing had ever exercised the path): (1) `GenericWorkflowCreationCard` force-defaulted every untouched editable field to `''`, crashing `tournament-ballot`'s computed `dueAt`/`isExpiringSoon` formulas whenever the legitimately-optional `deadline` field was left blank — fixed by omitting untouched fields instead of synthesizing `''` (round 10); (2) the formula evaluator's `isPast`/`subtractHours` didn't tolerate a genuinely absent date input at all — fixed to propagate `null` for that specific case while staying strict for any other malformed value (round 11, `loom_workflow_engine`, elevated verification bar given the shared blast radius). A flaky two-tournament end-to-end scenario (proving `{context.id}` resolves per-card, not a fixed value) could not be made to reliably render a second, dynamically-created same-type Calendar entry despite the engine layer being independently confirmed correct via standalone diagnostic scripts the verification agent wrote and ran directly, not committed (rounds 5-7 tried different dates, longer waits, and a full widget-tree rebuild; none resolved it, and the verification agent's own deeper repro attempts hung rather than reproducing a clean failure). Rather than keep chasing a UI-only rendering mystery with zero bearing on correctness, round 8 proved that specific claim at the right layer instead: a deterministic unit test against `resolveInstanceScopedPrefill` with two distinct `WorkflowInstance`s, alongside the already-proven single-instance real end-to-end flow. Implementation sandbox hit its own `WSL ERROR: UtilBindVsockAnyPort:307: socket failed` on nearly every round (sometimes 2-3 consecutive blocked attempts before making progress) and could not run any of its own tooling or commit at any point in this ticket — every result below was independently verified by the verification agent throughout. **Final: `loom_workflow_engine` 141/141, `loom_communities_app_shell` 100/100, `dart analyze`/`flutter analyze` clean in both** (21 pre-existing, unrelated `prefer_const_constructors` info hints in `loom_workflow_engine`, unchanged). |
| CALR.4f | **Instance-scoped CREATE, `fab` presentation + tab-FAB exclusion.** Contextual FAB bound to the in-focus tournament-event card (CALR.4d's tracker); confirm `scope: "instance"` actions never appear in the tab-level `creatableAction`/`multiActionStyle` FAB resolution (a distinct rendering surface — see `render-bindings.md`'s scope table) and correctly disappear when zero `tournament-event` instances exist. | CALR.4d, CALR.4e | `[x]` **Done** (`60ea67b`). Renders the contextual instance-scoped FAB (`instance-creatable-fab-<workflowType>`) alongside the existing tab-scope FAB surface (not replacing it), resolved from `_focusedInstanceForActiveTab` (CALR.4d) via the existing `resolveInstanceScopedPrefill` (CALR.4e) — no new resolution logic. New synthetic-fixture test proves all three acceptance criteria: the contextual FAB is additional to (not instead of) the tab FABs; `scope: "instance"` actions of both `button` and `fab` presentation are confirmed excluded from `multiActionStyle` resolution; and the FAB is absent both with no focused instance and when the focused instance's type has no matching action. **Real test-setup bug found and fixed by the verification agent** (not the implementation sandbox, which stayed vsock-blocked through 5 consecutive dispatch rounds on this fix alone): the new test's `_install()` helper was missing the `experienceForExtensionId`/`workflowEngineForExtensionId` pre-warm that its CALR.4e sibling always does before pumping the widget — found by direct diff against that proven-passing sibling test, since without it the widget's own lazy engine init raced the test's later `queryInstances` call and hung for the full 10-minute test timeout, cascading into a second, unrelated-looking "Reentrant call to runAsync()" failure on the next test in the same file. A first fix-ticket dispatch attempt also failed `apply_patch` verification by assuming the wrong existing code shape (CALR.4e's awaited call chain, not this file's differently-shaped synchronous one) — resolved by rewriting the ticket with the exact literal before/after text instead of a described intent. Also hardened `data/call_implementation_agent.sh` during this ticket: it now records its own PID to `.codex-logs/.last_dispatch.pid` on every run, replacing a `pgrep`-by-command-substring completion check that gave wrong answers in both directions (unanchored patterns self-match the polling loop's own script text and never terminate; anchored patterns miss the real process, which runs through an `npm exec @openai/codex exec` wrapper rather than a literal `codex exec` argv[0]). **Independently verified: full `loom_communities_app_shell` suite 103/103, `flutter analyze` clean on both touched files** (a whole-workspace analyze run surfaced 30 pre-existing issues elsewhere in the monorepo, unrelated to this ticket and not newly introduced). |
| CALR.4g | **`kind: "transition"` actions.** Pull a named transition out of its archetype's automatic button row into a `button`/`fab` presentation, without touching the transition's own `guard`/`effects`/`inputs`. Proven on `equipment-loan`'s `borrow` transition → "Request loan" contextual FAB (frozen fixture, already authored) — confirm `join-queue`/`leave-queue`/`return`/`delist` keep rendering as ordinary row buttons, unchanged, and that `borrow` no longer double-renders in the row. | CALR.4a, CALR.4d | `[x]` **Done** (`1a8e003`), **5 rounds**. `_transitionActionsFor`/`_presentedTransitionsFor` (new, `part02_tab_shell.dart`) read `kind: "transition"` actions off the matching Marketplace `renderBindings[]` entry and exclude those transitionIds from the automatic row (`_actionsFor`); `borrow` renders as its own guarded `FloatingActionButton.extended` ("Request loan"), reusing the existing `_applyTransition` path. **Wiring Marketplace onto `workflowDefinitions` for the first time surfaced three separate, real, pre-existing gaps** (each its own round, each independently verified before the next): (round 2) `_hasAnySurfaceFamily` — gating the Marketplace tab's very existence — only checked the legacy `experience.workflows` list, never `workflowDefinitions`, so the tab never appeared at all for this workflowDefinitions-only fixture; fixed additively (`part12_persona_and_tabs.dart`). (round 3) round 1's own `_marketplaceListingsFromEngineNative` projected *every* marketplace-tabId type generically, sweeping in `tabletop-game-loan` (a real, already-seeded peer-owned type requiring `ownerPersonaId`, a field the legacy `LoomMarketplaceListing` flat model has no slot for) and crashing seed-instance validation; fixed by narrowing the projection to `equipment-loan` only, deferring the other types' full support to later, separately-scoped work. (round 4) `_loadNextPage`'s query filter only matched the legacy per-listing synthesized `marketplace_<id>` workflowType convention, never the real declared type round 1's `declared` branch returns — so the seeded `equipment-loan` instance never surfaced in the browse list even after round 3's crash was fixed; fixed by widening the filter to also accept any instance whose registered machine has a `renderBindings[]` entry with `tabId == 'marketplace'`. (round 5, test-only) the test's own `_openCatanAsMember` helper tapped the now-correctly-rendering listing without first scrolling it into view — an off-screen hit-test miss, fixed with one `ensureVisible` call matching the file's own existing pattern. **Also surfaced and fixed a verification-process bug this same cycle**: three of round 5's dispatch attempts were wasted re-requesting an already-landed fix because the new test file sat uncommitted (untracked, `??`) across multiple rounds, and `git diff` shows nothing for an untracked file's content changes no matter how many times it's edited — corrected going forward via §6's amended "commit immediately, paired with WSL cleanup, before verifying" rule and a new `data/handoff_gate.sh` pre-validation check. **Independently verified: full `loom_communities_app_shell` suite 105/105, `flutter analyze` clean.** |
| CALR.4h | **Live emulator walkthrough + full regression**, per §7's Verification Standard (full-tab card audit, screen-validation evidence matrix, random regression re-check). Exercises: tab-scope create FABs (regression check, unchanged), ballot instance-scope create (button + fab), `equipment-loan`'s transition-fab ("Request loan"), full-tab audit on Calendar + Marketplace, confirms every other archetype/tab still renders correctly. | CALR.4c, CALR.4e, CALR.4f, CALR.4g | `[x]` **Done**, live walk on `PantryVision_Manual_API_36` (Android 36 emulator, WSLg-visible), `loom_communities_demo` installed fresh via `flutter run`, Tabletop Club sideloaded through the real "Add local community" dialog (not a test harness) using a freshly-built, comment-stripped copy of the frozen fixture. **Evidence matrix** (screenshots in `.codex-logs/loom-calr4h-*.png`): Calendar tab-scope create FABs ("New tournament" + "New event", multi-action resolution, `#10`) — regression-clean; ballot instance-scope create **button** on the Summer Tournament card opens correctly prefilled and cancels cleanly (`#08`-`#09b`) — CALR.4e confirmed live; Marketplace's Catan listing automatic action row correctly shows only `Delist` as Organizer and only `Join queue` as Member (`#13`, `#16`) — confirms `borrow` stays excluded from the row for both personas, matching CALR.4g; the `equipment-loan` **transition-FAB** ("Request loan") is correctly **absent** pre-dues-payment under the real `requiresWorkflowsComplete` guard (not a synthetic bypass this time) — direct, stronger live proof of the same guard the automated test exercises. Giving (dues payment removes the Pay button, `#17`-`#18`), Messages (real thread list, `#29`-`#30`), and Calendar re-checked under Member persona (`#31`, random regression re-check) all render correctly with no regressions found. **Two gaps found and explicitly logged, both pre-existing and out of CALR.4c/e/f/g's own scope** (neither blocks this milestone — the automated suite already proves those tickets' own logic correct in isolation): (1) Home tab shows "Nothing is pinned yet" for Tabletop Club under both personas — expected, since Home's own tab dispatch still hardcodes `tabId=='home' -> true` rather than reading `renderBindings` (tracked separately, Addendum Milestone 1.30, never in CALR.4's scope). (2) The `equipment-loan` transition-FAB did not appear even after genuinely paying dues live (Giving tab) and forcing full widget/community reloads (re-entering the community, switching persona) — `_completedWorkflowIds` appears not to be recomputed against the freshly-paid state by the time Marketplace re-renders; root cause not isolated (would require Dart changes to diagnose further, out of the verification agent's remit) — filed as a new gap for a future ticket, distinct from `_hasAnySurfaceFamily`/`_loadNextPage`'s already-fixed CALR.4g gaps. Emulator and app left running and visible for the user's own manual inspection. |
| CALR.4b | Real member login/identity flow. Found during CALR.2's live walkthrough (2026-07-19): the only reachable persona control ("Switch role": Organizer/Member) maps "Member" to a generic placeholder id that matches none of the 13 individually-seeded accounts (`tabletop-member-03`..`14`) the CALR.1/2 redesign requires — a live "member" sees "No response record is available for you for this event." on every event. `LoomAuthScreen` (real individual-account sign-in) exists in code (`part31_auth_screens.dart`) but is never instantiated anywhere in the app — dead code; `v3_multiuser_login_test.dart` only exercises identity switching via the private `setCurrentActiveAccountId()` test hook, never through real UI. Wire a real account-selection/sign-in flow into actual navigation (reusing `LoomAuthScreen` if it's fit for purpose, or replacing it if not) so a live viewer can pick one of the individually-seeded accounts, not just the generic type. Pre-existing app-shell identity gap, not a CALR.2 regression — CALR.2's redesign just exposed it (the old list-based RSVP tolerated the generic type id fine). | none (app-shell, not Calendar-specific) | `[x]` **Done** (`ed859df`), **5 rounds**. Added a `persona-sign-in-specific-person` entry to the persona picker's Organizer/Member dialog (`_showPersonaPicker`, `part01_local_extension_screen.dart`) that pushes the existing `LoomAuthScreen` — no new identity-resolution logic needed, since `_activeAccountId`/`resolveEnginePersonaId` already preferred a real signed-in session end-to-end; the picker was the only missing entry point. New `v3_calr4b_individual_sign_in_ui_test.dart` drives the real UI (not the `setCurrentActiveAccountId()` test hook) through the frozen Tabletop fixture: signs in as Priya N., confirms her real per-individual RSVP row resolves on Friday game night, changes her response to Maybe, then signs in as Casey M. through the same UI and confirms Casey's independently-seeded row still shows Going — proving genuine per-individual resolution, not a shared/generic id. **4 fix-round gotchas, all test-only, implementation itself correct from round 1**: (round 2) `InputChip.isSelected` doesn't exist, real property is `.selected`; (round 3) the RSVP action chip's `ValueKey` sits on a private wrapper widget (`_RsvpActionChip`, `part28_engine_native_calendar_surface.dart:1087-1135`) that builds a real `InputChip` internally — `tester.widget<InputChip>(find.byKey(...))` must resolve through `find.descendant(of: ..., matching: find.byType(InputChip))`, not cast the keyed widget directly; (round 4) 4 `prefer_const_constructors` info lints — confirmed this repo's `flutter analyze` treats info-level issues as build-breaking (nonzero exit), so "clean analyze" means 0 issues, not just 0 errors; (round 5) the `respond-maybe` chip tap needed `tester.ensureVisible(...)` first, matching the same off-screen-hit-test-miss pattern CALR.4g's `_openCatanAsMember` fix already established. **Independently verified: full `loom_communities_app_shell` suite 106/106, `flutter analyze` 0 issues.** |
| CALR.5 | Day/Week/Month/Pending views: the generalized holding-container widget, parametrized by `responseTable`/`filterableFacets` (timeframe scope + response-status filter), minimized cards expanding via `EngineNativeArchetypeCard` (reuse GP.1, accordion-style), month-grid date-cell tap → Day view, filterable-facets UI (boolean chips + numeric stat display). Acceptance test follows the user's own methodology exactly: create randomized events as organizer (CALR.3) → switch to member → RSVP (CALR.2) → verify correct Day/Week/Month/Pending scoping — **the "switch to member" step needs CALR.4b's real login flow to be genuinely live-verifiable, not just unit-tested via the `setCurrentActiveAccountId()` hook.** | CALR.1-CALR.3b, CALR.4h, CALR.4b | `[x]` **Done** — broken into CALR.5a-5d below (2026-07-22, per §5's "one concern per milestone" sizing rule) rather than dispatched as one ticket; all four closed. |

**Layout reference for CALR.5 (user direction, 2026-07-20, three screenshots reviewed — Google Calendar's
schedule/agenda view):**
- **Single screen, not separate tabs/routes**: the month grid stays visible at the top of the Calendar
  tab; the RSVP agenda list renders directly underneath it, scoped to whatever timeframe is currently
  selected (unbounded / month / week / day) — not a full-screen navigation away from the grid.
- **Agenda list layout**: chronological, grouped by date — the date rendered once on the left, with one or
  more "slim" RSVP cards stacked to its right for that date (title + time, compact — not the full detail
  card). Matches Google Calendar's schedule view exactly (date rail on the left, event chips on the right,
  one row per day that has events, empty days skipped).
- **Slim card → full card is the same accordion-expand behavior CALR.5 already planned** (`EngineNativeArchetypeCard`,
  GP.1 pattern) — this direction confirms/sharpens that plan with a concrete reference rather than changing
  it: tapping a slim card in the agenda list expands it in place to the same full `_EventRsvpDetailCard`
  (going/maybe/waitlist actions, capacity bar, etc.) already built in CALR.2, not a new detail widget.
- **Month-grid date-cell tap** still scopes the agenda list to that one day (Day view) — matches the
  milestone's existing "month-grid date-cell tap → Day view" line; the screenshots just clarify this means
  re-scoping the SAME on-screen agenda list, not navigating to a separate Day screen.
- **CALR.5's live walkthrough must visually compare against these reference screenshots**, not just
  functionally exercise the interactions — the point of citing Google Calendar's schedule view is to hit a
  modern layout pattern, which only a side-by-side screenshot comparison (date rail placement, slim-card
  density, grid-then-list vertical composition) can actually confirm. A walkthrough that only proves the
  RSVP actions still work would miss the actual point of this direction.

**CALR.5 milestone breakdown (added 2026-07-22, per §5's "one concern per milestone" sizing rule).**
Grounded by reading the current Calendar surface (`part28_engine_native_calendar_surface.dart:360-519`)
directly rather than assuming: the month grid, a horizontal date-strip, and a chronological
date-grouped agenda list (slim `ListTile` title+time rows) already exist — but there is **no**
Day/Week/Pending timeframe scoping (only "whatever month is selected" is ever shown), **no**
`responseTable`/`filterableFacets` consumption anywhere in the App Shell (both are already fully parsed
and validator-checked — `workflow_validator.dart:243-291` — and already declared on the frozen fixture's
`event-rsvp` binding, lines 148-157 — this is pure App-Shell consumption work, no JSON/spec change
needed), and the "selected" full detail card always renders once at the fixed bottom of the whole list
(`EngineNativeArchetypeCard` at line 489) rather than expanding in place under the tapped slim row, so
the current layout does not yet match the Google Calendar date-rail/slim-card reference. No frozen-spec
edits required for any of the four milestones below — only `part28_engine_native_calendar_surface.dart`
and its test file are in scope.

| # | Milestone | Depends on | Status |
|---|---|---|---|
| CALR.5a | **Timeframe scope control + generic `responseTable` resolution.** Add a Day/Week/Month/Pending segmented control above the agenda list. Month = today's existing behavior (unchanged). Day = only entries on `selectedDate`. Week = the 7-day window containing `selectedDate`. Pending = a new, fully generic helper that reads the active render binding's `responseTable` (`workflowType`/`eventField`/`pendingStates` — never hardcode `event-rsvp-response`'s field names) and keeps only events where the current persona's own row is in a pending state — proven with a second, differently-shaped synthetic `responseTable` fixture in the test, not just the real one, so it's provably generic rather than coincidentally correct for one shape. Month-grid date-cell tap sets scope to Day (currently it only calls `_selectEntry`, which selects but never re-scopes — this is the fix that makes "date-cell tap → Day view" from the milestone's original one-line description actually true). | CALR.1-CALR.3b, CALR.4h, CALR.4b | `[x]` **Done** (`fc7d7e0`), **3 rounds**. `_entriesForScope` implements Day/Week/Month exactly as scoped; `_isPendingForViewer` resolves Pending generically off `entry.resolved.binding.responseTable` alone — matches the schema field whose declared `source` equals `query(<workflowType> where <eventField> == id)` (the same mechanism `event-rsvp`'s own `responses` field already uses), reads that already-hydrated list, checks the viewer's own row's `$state` against `pendingStates`. Proven against a second, differently-named synthetic `responseTable` (`attendance-record`/`gatheringKey`/`awaiting`) in the new test, not just the real `event-rsvp-response` shape. Month-grid tap now routes through a new `_selectMonthGridEntry` that sets `scope = 'day'`, leaving the date-strip/agenda-tap selection path (`_selectEntry`) unchanged. **Round 1** landed the real implementation correctly but round-1's own diff review (by the verification agent, not the sandbox) caught 3 test failures before commit was trusted: 2 regressions in pre-existing tests (`v3_milestone_a8`/`v3_milestone_a11`) from off-screen hit-test misses — the new scope-control row's added height pushed already-fragile fixed-offset taps below the 600px test viewport, same class of bug as CALR.4g's `_openCatanAsMember` fix — and one genuine bug in the new test's own fixture helper (`_addScopedCalendarFixture` read `workflowDefinitions`/`workflowInstances` off the top-level fixture JSON; the real fixture nests both under `experience`). **Round 2** (`09e9ed2`) fixed all 3, but full re-verification surfaced a **real, previously-undiscovered engine-interaction bug**: `LocalWorkflowEngineApi._hydrateSourceFields` only assigns a source-query field when at least one row matches (`local_workflow_engine_api.dart:867-873`), so an event with genuinely zero response rows leaves the field absent (`null`), not `[]` — `_isPendingForViewer` treated `null` the same as "binding declared a responseTable but no matching schema field exists" (excluded), rather than falling through to the intended "no row for this viewer → pending" case. **Round 3** (`e62c03c`) fixed it with a 2-line change (`responses != null && responses is! List` guard, `as List<dynamic>? ?? const <dynamic>[]` on the loop). **Final: full `loom_communities_app_shell` suite 107/107, `flutter analyze` 0 issues**, independently re-run by the verification agent after every round (the implementation sandbox itself was blocked by the WSL/codex vsock bug — openai/codex#8322 — for 4 consecutive dispatch rounds before round 1 actually landed; traced to a genuinely different cause than prior sessions' zombie dispatch processes — a leaked Monitor `tail -F \| grep` pipeline that matched but never exited, holding a live WSL session open for up to 30 minutes; fixed going forward via a new self-terminating `data/watch_dispatch_log.sh` and an automatic zombie-sweep step added to `data/wsl_dispatch_tracker.sh`'s `cleanup`). |
| CALR.5b | **`filterableFacets` UI.** Render a row of boolean filter chips + numeric stat labels from the active binding's `filterableFacets[]` (formula-backed, e.g. `isFull`/`hasWaitlist`/`goingCount` in the real fixture — but read generically from whatever the binding declares, same genericity bar as 5a's `responseTable` work). Toggling a boolean facet narrows the agenda list (computed per-instance via the existing formula evaluator, no new formula vocabulary needed); a non-boolean facet renders as a read-only stat, not a toggle. | CALR.5a | `[x]` **Done** (`f1a2470`), **1 round, no fix rounds needed**. `_facetsForEntries` computes the union of distinct `(field, label)` pairs across every binding represented in the scope-filtered list (dedupes by `field`), resolving boolean-ness via `machine.instanceDataSchema[field]?.type == 'bool'` rather than assuming — non-`bool`/unresolvable fields render as a read-only stat, never a toggle, matching the ticket exactly. Boolean facets render as `FilterChip`s (`calendar-facet-<field>`) and narrow the agenda via `_entriesForActiveFacets`: an entry whose own binding doesn't declare a given active facet is left unaffected (kept), proven in the new test by toggling a synthetic `featured` facet and confirming the real, unrelated `event-friday-game-night` entry (whose binding never declares `featured`) stays visible throughout. Non-boolean facets render as `calendar-facet-stat-<field>` aggregate sums over the scope-filtered (pre-facet-toggle) list, confirmed to update correctly when scope changes (Month's sum of 10 narrows to Day's single-entry 3). **Independently verified: full `loom_communities_app_shell` suite 108/108, `flutter analyze` 0 issues** — no regression of the off-screen-hit-test-miss class CALR.5a round 2 hit, despite this ticket's own verification bar flagging that exact risk (the new facet row's added height did not push any pre-existing test's tap target out of the test viewport). Implementation sandbox hit the WSL vsock error before its own verification could run (self-reported, consistent with every other ticket this cycle) — real edits were confirmed correct via independent diff review and the full toolchain re-run by the verification agent before commit. |
| CALR.5c | **Google Calendar-style layout + accordion expand-in-place.** Restructure the per-day agenda group into the reference layout: date rendered once on the left, one or more slim event cards stacked to its right for that date (not the current vertical date-header-then-list-below stack). Tapping a slim card expands it in place to the existing `_EventRsvpDetailCard`/`EngineNativeArchetypeCard` (collapsing any other expanded card), replacing the current single fixed "selected" detail card pinned to the bottom of the whole list. Reuses the exact same detail card widget already built in CALR.2 — no new detail UI. | CALR.5a, CALR.5b | `[x]` **Done** (`413f16f`), **3 rounds** (plus 4 dispatch attempts fully blocked before any edit by the WSL vsock bug — see the environment note below). Each day's `Container` became a `Row`: a fixed-width (`96`) date rail on the left (`SizedBox`+`Text`, same key as before), an `Expanded(Column(...))` of that day's entries on the right — matching the Google Calendar reference exactly. Each entry's slim `ListTile` is unchanged (same key/type every existing finder already depended on); the selected entry's full `EngineNativeArchetypeCard` now renders immediately after its own row (same key as the old fixed-bottom card) instead of once, unconditionally, at the end of the whole list — the old unconditional card is fully removed. Computed from the scope/facet-filtered list (CALR.5a/5b), not the raw unfiltered one, so an entry hidden by an active filter correctly shows no detail card anywhere (proven in the new test, an intentional design choice, not a bug). **2 real regressions found and fixed via independent verification, both genuine async/layout subtleties CALR.5c's own restructuring exposed, not test-authoring carelessness**: (round 2, wrong diagnosis) a `pump()` → `pumpAndSettle()` swap after an already-present `ensureVisible` call did NOT fix a hit-test miss on the Friday agenda row, proving the round-2 hypothesis (incomplete scroll animation) wrong; (round 3, correct diagnosis after the verification agent traced the actual mechanism through the fixture data) Summer Tournament and Friday game night share the same date and Summer Tournament — chronologically first, auto-selected by default — loads its own RSVP actions **asynchronously**; `ensureVisible` was scrolling against Summer Tournament's pre-load (shorter) height, and its actions arrived and grew the card *after* the scroll had already executed, pushing Friday back out of the fixed test viewport — fixed by waiting for Summer Tournament's own action chip to exist (proving its final height) before scrolling to Friday. **Independently verified: full `loom_communities_app_shell` suite 108/108, `flutter analyze` 0 issues.** **Environment note**: this milestone hit the WSL/codex vsock bug (openai/codex#8322) 4 consecutive times before any edit landed — investigated live with the user: killing 3 genuinely stale (~2hr-old) zombie `wslhost.exe` processes broke CALR.5a's earlier streak, but for CALR.5c even a clean process table and a passing sandbox smoke-test didn't prevent 4 straight blocks; a `git status` smoke-test showed the process itself blocked in uninterruptible I/O wait (`D` state), which the user addressed by disabling OneDrive sync — the very next dispatch attempt succeeded. Whether OneDrive was the true root cause or a contributing stressor on the same shared WSL2 VM remains circumstantial, not confirmed (the two subsystems — Hyper-V vsock transport vs. DrvFs disk I/O — are technically distinct). **Reopened 2026-07-23** — see the correction below; a genuine visual gap survived this milestone's own closure. |
| CALR.5d | **Live emulator walkthrough + full regression**, per §7's Verification Standard (full-tab card audit, screen-validation evidence matrix, random regression re-check) — **plus the side-by-side screenshot comparison against the three Google Calendar reference screenshots this milestone's own layout direction requires** (date-rail placement, slim-card density, grid-then-list vertical composition), not just a functional exercise of Day/Week/Month/Pending and the RSVP actions. Exercises the full acceptance methodology: create randomized events as organizer → switch to a real individual member account (CALR.4b) → RSVP → verify correct Day/Week/Month/Pending scoping and filterableFacets narrowing, live. | CALR.5a, CALR.5b, CALR.5c | `[ ]` **Reopened 2026-07-23** — see below. Prior walkthrough (screenshots in `.codex-logs/loom-calr5d-*.png`) genuinely confirmed the accordion expand-in-place swap (both directions), Pending scope correctness for the organizer, a Marketplace regression check, and the full organizer→real-member→RSVP→live-mutation acceptance methodology (Priya N., `Going`→`Maybe`, capacity recomputed `11/20`→`10/20` correctly) — none of that is in question. **But the user's own manual inspection immediately after found two things this walkthrough's own evidence should have caught and didn't:** (1) tapping Day/Week/Month produced no visible change in the agenda — traced to the **fixture itself**: both real seeded events (`event-friday-game-night`, `event-summer-tournament`) sit on the identical date, `2026-07-10`, so Day/Week/Month have nothing to visibly differentiate no matter how correct the underlying filter is; the milestone's own automated test proves the filter logic correct against a genuinely multi-date *synthetic* fixture, but that is not a substitute for live proof, and this walkthrough never created a second real event on a different date to actually show it live. (2) **A real, unclosed visual gap in CALR.5c**: each agenda row is a bare `ListTile` (`part28_engine_native_calendar_surface.dart:659-675`) with no card styling at all — no background fill, border, or rounded shape — only the whole day-group shares one undifferentiated box. This does not match the milestone's own "slim event cards" language from the Google Calendar reference direction (§1d) — Google Calendar's schedule view renders each event as its own distinct chip, not plain text sharing a neighbor's box. The verification agent's own screenshots showed this plainly and it should have been caught before claiming the reference-layout comparison passed. **Follow-up ticket needed**: style each agenda row as its own real card (background/border/shape, still nested in the date-rail `Row`/`Expanded(Column(...))` CALR.5c already built — this is a styling-only fix, not a structural one) and re-run the live walkthrough with a second, real, different-dated event created live to actually show Day/Week/Month differ on screen, not just in the automated suite. |

## 1e. App Shell milestones (outside the Calendar-only CALR scope)

| # | Milestone | Depends on | Status |
|---|---|---|---|
| AS.1 | Dismissible community-description card. From the original multi-part Calendar feature request (pre-spec-design phase): a dismissible ("X" to close) card summarizing the community — name, description, current persona/role — appearing at the top of each tab, App Shell-wide (not Calendar-specific). **Never formally approved as deferred** — it fell out of the "Calendar tab only, then other tabs" instruction by inference, not by an explicit decision at the time (corrected 2026-07-20). **Not yet grounded**: the community-card layout the user pointed at (title + tagline + role card) matches `part01_local_extension_screen.dart:90,910` (`experience.tagline`), which renders on the community catalog/"Add local community" browsing screen — but the original request describes this appearing on every tab *after* installing, which is a different surface. Confirm which screen(s) this actually needs to touch before writing the implementation ticket. | none | `[ ]` Not started, not yet scoped |



**Verification gate for every CALR milestone (binding, per explicit user instruction 2026-07-17):**
beyond the usual `dart analyze`/test-suite/real-validator checks, **every milestone's closing evidence
must include a live Android emulator walkthrough I (the verification agent) drive myself**, confirming
the implemented behavior against `tabletop-club.md`'s own user-story/interaction rows — not just that
tests pass. A milestone whose live behavior does not match what `tabletop-club.md` describes is **not
closed** — a follow-up fix ticket goes back to the implementation agent, exactly as GP.2's four

**Read [`Loom_Communities_Workflow_Engine_3_VerificationTooling.md`](./Loom_Communities_Workflow_Engine_3_VerificationTooling.md)
before closing any milestone whose ticket cites a visual/UX reference** (added 2026-07-23 after CALR.5d's
own screenshot self-review missed a real, obvious styling defect that an already-built independent pixel
auditor — `b25_visual_inspection_auditor.dart` — would have caught, and was never run). That doc has the
exact lightweight recipe: fixture-data-variance check before testing a filter, the pixel-auditor's exact
minimal input schema, and an explicit "does this look like the reference" step separate from both. Do
not substitute an automated test's synthetic-fixture proof for this live check, even when its logic is
correct — the milestone's own acceptance bar is what's live, on screen, in front of you.
remediation rounds this session already demonstrated the value of independent re-verification over
trusting a sandbox-blocked self-report.

**THE FROZEN SPEC RULE, extended for this phase (binding on every CALR dispatch):** in addition to the
frozen JSON (§3a, unchanged), the following reference docs are ALSO frozen for the duration of CALR —
written and reviewed 2026-07-17, describing the target contract implementation must match, not a draft
implementation may "fix" by editing:
[`guards.md`](../../../references/reference/guards.md),
[`formulas.md`](../../../references/reference/formulas.md),
[`render-bindings.md`](../../../references/reference/render-bindings.md),
[`archetypes/README.md`](../../../references/archetypes/README.md),
[`communities/tabletop-club.md`](../../../references/communities/tabletop-club.md),
[`spec-version.json`](../../../references/spec-version.json). **Only the validator's own Dart
implementation** (`loom_ux_judges/lib/src/validator/*.dart`) may be edited to add the new rules these
docs already describe — that is code, not spec. If an implementation agent hits a genuine gap between
what these docs say and what's actually buildable, the protocol is identical to §3a: **STOP, do not edit
the doc/JSON, file a gap report, halt the milestone.**

**Corrected 2026-07-18 (user direction, overriding this section's earlier text):** the verification agent
does **not** unilaterally own spec corrections. **No changes to the frozen JSON specification or to
`tabletop-club.md` are allowed without the user's explicit approval** — a gap report from an
implementation agent gets surfaced to the user first, with the exact proposed fix shown for review, and
only applied after explicit sign-off. This applies to every file in this rule, not just those two named —
treat the whole frozen-spec list above the same way. (One correction was made 2026-07-18 to
`tournament-ballot`'s `instanceDataSchema` — missing `writableBy: "formEntry"` on four fields already
named in `editableFields`, found by the CALR.1 implementation agent — shown to the user and explicitly
confirmed before being committed; that is the pattern to repeat, not a standing delegation.)

## 2. Precursors — DONE (docs/JSON only, no code)

- **[JSON Schema Versions](./Loom_Communities_Workflow_Engine_JSON_Schema_Versions.md)** — normative.
  Three independently-versioned layers (package envelope `schemaVersion`; experience content
  `experienceSchemaVersion` v1=shallow / v2=engine-native; `workflowGrammarVersion`), the loader's
  dispatch rule (unknown version = hard error, never a silent best-effort parse), and the rule that no
  Loom JSON ships without all three stamps.
- **[Tabletop Club Example JSON](./Loom_Communities_Workflow_Engine_Phase1_TabletopClub_Example.jsonc)**
  — the full desired experience as a stamped **v2 engine-native** package: 11 workflow types, 17
  instances, real states/transitions/guards/effects/formulas/renderBindings. **Not yet validated by a
  tool** (that's A.1-A.3) and **expected to change** at the Phase A gate.

## 3. Additive, not a rewrite

The engine-native pathway is added **alongside** the existing shallow path. The ~20 bespoke stores and
all seven other communities keep working, unmodified, throughout. Only Tabletop Club moves — one tab at
a time. Every phase carries a regression check proving the untouched path still passes.

## 3a. THE FROZEN JSON RULE (binding on every agent)

> **[The Tabletop Club JSON](./Loom_Communities_Workflow_Engine_Phase1_TabletopClub_Example.jsonc) is
> FROZEN. It MUST NOT be edited during this cycle. Not one character.**

The JSON is the **specification**. The job is to make the app implement it.

**Therefore: if a workflow in it cannot be implemented, that is a gap in the JSON *language* — never a
bug in the JSON.** The fix is to change the language, the engine, or an archetype — never the spec.

**When any agent hits a gap: STOP.** Do not edit the JSON, hardcode the behaviour, fake a value, or
silently drop the interaction. File a gap report and **halt the milestone**. Protocol, template, and the
live register: **[Language Gaps](./Loom_Communities_Workflow_Engine_3_LanguageGaps.md)**.

Gaps may be surfaced by the **implementation agent** (while building) or the **verification agent**
(while reviewing, bug-fixing, or doing a UI review). Same template, same halt.

*Why:* every past failure here came from the opposite reflex — quietly bending the spec to fit what the
code could already do. That is how 15 of 17 archetypes became the same generic card and a vote poll came
to hardcode its winner. Freezing the JSON removes the escape hatch on purpose.

## 3b. Pre-freeze audit result — 4 language gaps found

The JSON was audited against [`docs/references/`](../../../references/README.md) **before** freezing, so
dispatches are not wasted rediscovering known gaps.

| Gap | Blocks | Proposed correction | Additive? |
|---|---|---|---|
| **GAP-1** — a transition cannot receive user input (so a per-candidate Vote button cannot say *which* candidate; `pendingChoice` is a shared, racy scratch field) | **Phase B** | Grammar: transition `inputs` + `renderBindings[].repeater.itemActions` | Yes |
| **GAP-4** — query-backed `source` metadata is preserved but its query is not hydrated/evaluated, so a parent cannot compute over its child-row instances | **Phase B** | Grammar/runtime: hydrate `instanceDataSchema[].source` | Yes |
| **GAP-2** — no declarative instance creation (a member cannot create a proposal or start a thread) | **Phase E, F** | Grammar: `renderBindings[].creatable` | Yes |
| **GAP-3** — "all participants except the actor" is not expressible (thread unread is a single bool) | Phase F (degraded) | Effect op `setFromFormula` + `removeAll()` | Yes |

All four are **additive** — no version bump, no existing JSON breaks. Detail:
[Language Gaps](./Loom_Communities_Workflow_Engine_3_LanguageGaps.md).

**Phase A is blocked by none of them** — Calendar uses only constructs that already exist. It starts
immediately. **Phase A′ (below) closes GAP-1, GAP-4, and GAP-2 before their dependent phases; GAP-3
remains an explicitly degraded, non-blocking Phase F capability.**

## 4. Phase index

| Phase | Scope | Doc | Status |
|---|---|---|---|
| **A** | **Foundation + Calendar tab** (validator, JSON loading, shared engine, generic renderer, binding dispatch, Calendar end-to-end) — **ends in a human JSON-review gate** | [PhaseA_Calendar](./Loom_Communities_Workflow_Engine_3_PhaseA_Calendar.md) | `[ ]` In progress — A.1–A.9 complete; A.10 human gate remains |
| **A′** | **Grammar extensions** — close **GAP-1** (transition `inputs` + repeater `itemActions`), **GAP-4** (query-backed `source` fields), and **GAP-2** (`creatable` binding). Small, additive, engine+grammar only. **Required before B and E/F.** | [LanguageGaps](./Loom_Communities_Workflow_Engine_3_LanguageGaps.md), [GrammarExtensions](./Loom_Communities_Workflow_Engine_3_GrammarExtensions.md) | `[x]` **Complete 2026-07-16.** GAP-1 and GAP-4 fully resolved (grammar + engine + validator); GAP-2's grammar/model layer resolved, UI/runtime consumption still pending Phases E/F (see `spec-version.json` → `knownGaps.instanceCreation`). 210/210 engine+app-shell tests, 85/85 validator tests, real CLI validator 0/0 against the frozen JSON. Commits `10666f5`..`45ab6e2`. Publishing flow run in full (reference/guide docs, CHANGELOG, spec-version.json). |
| **B** | **Home tab** — tournament ballot (cross-instance eligibility guard, tally/tie/**real runoff** via branch+createInstance, deadline/reminder), tournament attendance card, published announcements. **Scope corrected 2026-07-16 — same finding as Phase C below: `_enabledTabs = {'calendar'}` in `EngineNativeBindingDispatcher` (`part27_engine_native_binding_dispatcher.dart:70`) means `home` is NOT wired to the generic engine-native pipeline either. The existing "REAL" ballot widget (`_TournamentBallotTabSurface`) is reachable only via a hardcoded `rendererId` switch reading `experience.tournamentBallot` (a legacy Shape-B special block) — already documented in `archetypes/README.md`'s "unreachable-widget problem," now confirmed to be the SAME root cause affecting every non-Calendar tab, not an isolated votePoll/discussionThread/notificationInbox quirk.** | [PhaseB_Home](./Loom_Communities_Workflow_Engine_3_PhaseB_Home.md) | `[ ]` Blocked on A — scope corrected, needs its own milestone breakdown |
| **C** | **Marketplace tab** — equipment-loan lifecycle (borrow/queue/return, cross-workflow dues guard), giveaway, `tabletop-game-loan` peer-sharing. **Scope corrected 2026-07-16 — bigger than originally scoped: `_MarketplaceBrowseSurface` (`part02_tab_shell.dart:4177-4189`) is fed by `experience.marketplaceListings`, a LEGACY Shape-B special top-level field — NOT `experience.workflowDefinitions`/`workflowInstances`. Unlike Calendar, Marketplace never received ANY of Phase A's pipeline work (no A.4-style parsing integration, no A.5-style shared-engine registration, no A.7-style binding dispatch, no A.8-style end-to-end proof against the frozen JSON). No V3 test exists that proves Marketplace renders from the real engine-native schema at all (confirmed: only a pre-V3 `milestone_1_4_test.dart` and the parsing-only `v3_milestone_a4_engine_native_parsing_test.dart` reference this surface — neither is an end-to-end UI proof). Phase C is therefore NOT "swap one generic widget for a bespoke one" (that was A.11's scope, already closed) — it needs Calendar's whole A.1-A.9 sequence repeated for the marketplace tab BEFORE a bespoke `equipment-loan`/`tabletop-game-loan` widget is even meaningful. Do not dispatch this as a single ticket; break it into a milestone sequence mirroring Phase A's own structure.** | [PhaseC_Marketplace](./Loom_Communities_Workflow_Engine_3_PhaseC_Marketplace.md) | `[ ]` Blocked on A — scope corrected, needs its own milestone breakdown before implementation starts |
| **D** | **Giving tab** — quarterly dues payment (gates Marketplace's borrow). **Scope corrected 2026-07-16 — same `_enabledTabs` finding as Phase B/C: `giving` is not wired to the generic pipeline either; confirm its actual data source (likely another `experience.*` legacy special block, unverified this pass) before assuming this is only a widget-swap.** | [PhaseD_Giving](./Loom_Communities_Workflow_Engine_3_PhaseD_Giving.md) | `[ ]` Blocked on A — scope needs the same re-verification as B/C before a ticket is written |
| **E** | **Game purchase proposals** — one feature spanning Home (member submits) + Admin (organizer's live pending queue decides). Replaces the old scripted "committee decision" card. `approvalQueueItem` has ZERO implementation today — no binding or widget of that name exists anywhere in `lib/src`; this phase builds it from scratch. **Scope corrected 2026-07-16 — same `_enabledTabs` finding: `admin` is not wired to the generic pipeline either, so this phase needs BOTH a new widget AND the pipeline wiring to reach it, not just the widget.** | [PhaseE_Proposals](./Loom_Communities_Workflow_Engine_3_PhaseE_Proposals.md) | `[ ]` Blocked on A — scope corrected, needs its own milestone breakdown |
| **F** | **Messages tab** — threads on the engine + the missing **"start a new thread"** action. **Scope corrected 2026-07-16 — same `_enabledTabs` finding: `messages` is not wired to the generic pipeline; the existing "REAL" `discussionThread` widget is reachable only via the same kind of hardcoded dispatch as the ballot (per `archetypes/README.md`'s "unreachable-widget problem").** | [PhaseF_Messages](./Loom_Communities_Workflow_Engine_3_PhaseF_Messages.md) | `[ ]` Blocked on A — scope corrected, needs its own milestone breakdown |
| **G** | **Retirement + close-out** — delete the bespoke stores the new pipeline replaced, global theming fixes, full regression, re-present Milestone 1.20 | [PhaseG_Closeout](./Loom_Communities_Workflow_Engine_3_PhaseG_Closeout.md) | `[ ]` Blocked on B-F |

**Ordering note.** Phases B-F are independent of each other (each is a different workflow type on the
same, already-built pipeline) and could be reordered or parallelized after A. They are all blocked on A
because A builds the pipeline they all use — and because A's gate may change the JSON they consume.

## 5. Phase A milestone summary (detail in the phase doc)

| # | Milestone | Status |
|---|---|---|
| A.1 | Validator: close 4 `WorkflowValidator` gaps (nested `branch` effects, cross-instance `set` false-positive, `createInstance` targets, guard/branch formulas) | `[x]` |
| A.2 | Validator: `CommunityPackageValidator` + CLI (envelope, schema versions, personas, instances, cross-instance refs) | `[x]` |
| A.3 | Run the validator on the Tabletop Club JSON; fix real findings (**JSON edits only**) | `[x]` |
| A.4 | Parse `workflowDefinitions`/`workflowInstances` into `LoomExperienceDefinition` (parsing only, no UI) | `[x]` |
| A.5 | One shared engine per community: register definitions + seed instances at install (no UI) | `[x]` |
| A.6 | Generic schema-driven instance card (fields from `instanceDataSchema`, buttons from `availableTransitionsAsync`) | `[x]` |
| A.7 | `renderBindings` → tab dispatch, **Calendar only** | `[x]` |
| A.8 | Calendar tab end-to-end from JSON: both events, real RSVP + waitlist, formula-driven capacity | `[x]` |
| A.9 | Calendar theming fixes (engine-native and legacy month grids consume resolved card theme) | `[x]` |
| A.10 | Live emulator walk + evidence matrix → **HUMAN GATE: user reviews and improves the JSON** | `[ ]` |
| A.11 | **Archetype UI Design gate for `event-rsvp` (added 2026-07-15, corrected 2026-07-16).** **Correction:** the original milestone text cited `part02_tab_shell.dart:5579-5591` (`CalendarEventDetail`/`WorkflowCardSurfaceTemplateRenderer`) — confirmed via `v3_milestone_a8_calendar_end_to_end_test.dart` (which asserts `find.byType(GenericWorkflowInstanceCard)`) that this is the **legacy, non-live path**; Tabletop Club's real, tested Calendar path is `EngineNativeCalendarSurface` → `GenericWorkflowInstanceCard` (`part28_engine_native_calendar_surface.dart:442-455`) — confirming `EngineNativeBindingDispatcher`/`resolveBindings()` IS already live for the `calendar` tab, so that half of the original milestone is already done. Replace the `GenericWorkflowInstanceCard` call at that exact site with a bespoke RSVP widget (real going/maybe/can't-go/waitlist controls, a real capacity/seats-remaining visualization, not fact-pills) whenever the selected binding's `cardSurfaceFamily == 'event-rsvp'` (covers both `event-rsvp` and `tournament-event`, which share that archetype on the calendar tab); keep the generic fallback for any other archetype. Closing evidence must re-verify `archetypes/README.md`'s `event-rsvp` row flips to ✅ REAL against source, not by assertion. | `[x]` **Complete 2026-07-16.** `_EventRsvpDetailCard` built and wired via `cardSurfaceFamily` dispatch; `archetypes/README.md`'s `event-rsvp` row re-verified ✅ REAL against source. Took 6 remediation rounds (stale test key/text assertions from replacing the generic card, a missing `selectedGame` field-display gap closed with a generic non-RSVP-field fallback, and a genuine test-arithmetic bug in the waitlist scenario) — full history in `data/v3_ticket_a11_*`. Independently verified: `dart analyze` clean, 300/300 combined tests across all three packages, real CLI validator 0 errors/0 warnings against the frozen JSON. Commits `0b01c60`..`232ed4d`. |

## 5a. Documentation backfill — every phase writes the docs for what it made real

[`docs/references/`](../../../references/README.md) is the authoring contract the **Skill** (Phase 3)
reads. Nine of its docs are deliberately marked `planned` rather than written, because **documenting the
JSON shape of a widget that does not exist yet is exactly how `docs/CardSurfaces/` came to describe a
`CommunityVoteApi` that has never existed in any version of this codebase.**

**Rule: a phase does not close until it has written the reference docs for the archetype it just made
real.** Each is a closing deliverable of its phase, not a follow-up.

| Doc | Written by | Content |
|---|---|---|
| `archetypes/calendar-agenda.md` | **Phase A** | The verified `event-rsvp` JSON shape + its archetype field contract |
| `guide/02-package-anatomy.md` | **Phase A** | Every envelope/experience key, once the loader is real |
| `reference/theming.md` | **Phase A** (A.9 touches theming) | The community→tab→workflow accent cascade |
| `archetypes/vote-poll.md` | **Phase B** | `votePoll` + the per-item action contract from GAP-1 |
| `archetypes/equipment-loan.md` | **Phase C** | `equipment-loan` + the orthogonal-state pattern |
| `archetypes/payment-checkout.md` | **Phase D** | `paymentCheckout` + the platform-services boundary |
| `archetypes/approval-queue.md` | **Phase E** | `approvalQueueItem` + `formEntry` + the live query-bound list + GAP-2's `creatable` |
| `archetypes/discussion-thread.md` | **Phase F** | `discussionThread` |
| `communities/tabletop-club.md` | **Phase G** | The reference community, once it is finally **vetted** |

Additionally, **every phase MUST**:
- Update [`archetypes/README.md`](../../../references/archetypes/README.md) — re-verify its archetype's
  status **directly against the Dart source** (grep the actual widget, read the actual dispatch path) and
  record the result, which may be 🟡 PARTIAL, not necessarily ✅ REAL. **Never flip a status by assertion
  or by carrying forward a prior phase's claim** — that is exactly how A.8/A.9 closed while `event-rsvp`'s
  RSVP interaction was still generic (§1a). Confirm BOTH: a bespoke widget exists for the interaction, AND
  declaring the `cardSurfaceFamily` alone (no hardcoded per-community wiring) actually reaches it. *An
  honest status table is the whole value of that index.*
- Update [`_meta/doc-manifest.json`](../../../references/_meta/doc-manifest.json) — `planned` → `current`,
  with `syncedTo` and `derivedFrom`.
- If it changed the grammar (Phase A′): run the full
  [publishing flow](../../../references/_meta/publishing-flow.md) — update the normative `reference/`
  docs, the CHANGELOG, `spec-version.json` (including removing the closed gap from `knownGaps`), and
  re-validate every community JSON.

**Phase G additionally builds the [docs-sync checker](../../../references/_meta/docs-sync-checker.md)** —
the tool that fails the build when a doc drifts from the spec. **The Skill (Phase 3) must not ship
without it**, because the Skill reads these docs as truth; if they are stale, everything it generates is
wrong in a way that is very hard to see.

## 6. Working agreement (carries forward, unchanged)

- **Ticketed dispatch, hard gate.** The implementation agent writes all code; the verification agent
  (me) never self-writes implementation code — only tickets, snippets, docs, and JSON. Every dispatch is
  independently re-verified (read the diff, run the suite myself) before a milestone closes; the
  agent's own "done" self-report is never sufficient. It has been wrong before.
- **Committed handoff, every time — and commit BEFORE verifying, not after.** In practice the
  implementation agent's own git commit almost never happens: it's either blocked by the WSL vsock error
  before it reaches that step, or deliberately avoids git writes per the repo's own OneDrive
  index-safety instructions. So the verification agent commits — but the correction (2026-07-22, found
  after CALR.4g round 5 wasted three redundant dispatch rounds re-fixing an already-fixed file) is
  **when**: commit immediately once a round's real edits are confirmed present in the working tree,
  *before* running `flutter analyze`/the test suite, not after. Only then start the independent
  verification cycle. If verification finds a problem, that's a new round with its own ticket, its own
  dispatch, and its own immediate commit once *that* round's edits land — never held open across
  multiple rounds. Reasoning: a new file the implementation agent creates is untracked (`??`) until
  someone runs `git add`; `git diff` shows **nothing** for an untracked file's content changes no matter
  how many times it's edited, so holding a file uncommitted across several fix-rounds makes it
  impossible to tell via `git diff` whether a later round actually changed anything — the exact mistake
  that cost three rounds on CALR.4g. Committing each round's edits immediately keeps the file tracked
  from that point on, so every subsequent `git diff` is trustworthy. No milestone advances from an
  uncommitted or dirty implementation worktree at final close, but intermediate rounds should not sit
  uncommitted while iterating either.
- **Code first, screenshots second, never both at once.** A screenshot proves the UI *rendered*; it
  cannot prove a guard or formula is correct.
- **Milestones are sized for a less-powerful implementation agent**: one concern each, exact files
  named, ready-to-apply snippets, explicit "do not do" list, and a required structured status response.
  Past stalls were caused by task size, not comprehension.
- **Production-quality bar** (verbatim in every kickoff): no stubs, no local state standing in for real
  engine wiring, no hardcoded values masquerading as computed ones, no tests weakened to pass. If it
  can't be done to that bar, stop and say so rather than shipping a fake.

## 7. Verification standard (extends §5 of tracker 2)

**The UI review is a checklist, not a vibe.** Every live walk and every phase gate runs the six rules in
**[UI Review Prompts](./Loom_Communities_Workflow_Engine_3_UIReviewPrompts.md)** — which also carries the
per-tab user stories each tab is audited against, and the evidence-matrix template.

The four additions to tracker 2's standard:

1. **Full-tab card audit, not just the new work** (UI Review Rule 1). When a tab is touched, validate
   *every* card on it — each must be the right archetype with its real interactions — not only the card
   the milestone added. *This rebuild exists because the 1.18 walk only ever opened one tab.*
2. **Verify against the frozen JSON, not against expectations** (Rule 2). Exactly the workflows whose
   `renderBindings` name this tab should appear — no more (duplication), no fewer (missing). **Any
   divergence is a bug in the app, never a reason to edit the JSON.**
3. **Screen-validation evidence matrix** (Rules 1-5). One screenshot per (Tab × User story ×
   Interaction) cell the milestone touches — not one representative shot per tab. **A milestone does not
   close without a completed matrix.**
4. **Random regression re-check** (Rule 5). Each milestone also re-takes ONE screenshot of a
   *previously-closed* interaction, chosen at random.

**Plus the STOP condition** (Rule 6): if a review reveals a workflow the JSON declares that the app
cannot implement, **halt the milestone** and file a gap report per
[Language Gaps](./Loom_Communities_Workflow_Engine_3_LanguageGaps.md). Never edit the JSON; never
hardcode a workaround.

Guards are proven by **attempting the transition and observing the refusal** (Rule 3). A hidden button is
not proof — guard enforcement lives in the engine.
