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
- **Committed handoff, every time.** The implementation agent commits all scoped code/tests before
  handoff, reports the full immutable SHA, then commits any status/evidence artifact separately when it
  needs to name that SHA. No milestone advances from an uncommitted or dirty implementation worktree.
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
