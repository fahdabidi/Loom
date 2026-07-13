# Archetype Audit — findings that triggered V3

Part of [Loom_Communities_Workflow_Engine.md](./Loom_Communities_Workflow_Engine.md). Reference doc,
not phase-sequenced — every V3 phase reads this to know which archetypes are real vs. fake and why.

## 1. How this audit happened

Live review of the running app (all 7 V2-migrated communities, Book Club specifically) surfaced that
Book Club's `votePoll` archetype is non-functional: no per-candidate choice UI exists, and the
organizer's "declare winner" action hardcodes a fixed candidate name regardless of actual vote
tallies. Investigating that one defect triggered a full audit (3 parallel research passes, ~30k tokens
of direct code citations, cross-checked against a manual correction where one pass's search missed
HOA's real generically-named classes) of every declared archetype across every migrated community,
answering: **do the "archetypes" V2 was built around actually deliver distinct, modern UI screens with
real interaction models — or are they all the same generic card, reskinned?**

## 2. Verdict

**Almost entirely the latter.** Of 17 catalogued archetypes
([V2's Archetype Catalog](../Loom%20Communities%20Workflow%20Engine%20V2/Loom_Communities_Workflow_Engine_Archetype_Catalog.md)),
only two are genuinely distinct implementations. Everything else resolves to the same handful of
generic helper functions (icon + title + subtitle + fact-pill row + button row, optionally a flat
`TextField` edit form) duplicated near-verbatim across Garden Club, Camera Club, Chess Club, Book
Club, Youth Soccer, and Mosque. Even the *shared* template renderer (`workflowCardSurfaceTemplates`,
`part18_marketplace_rendering.dart:192-228`) collapses `paymentCheckout`/`event-rsvp`/`equipment-loan`
to the identical two-slot shape — the lack of differentiation goes all the way down to the foundational
rendering infrastructure, not just per-community shortcuts. This is a real, large architectural gap,
not a handful of isolated bugs: V2 proved the *engine* (state machines, guards, effects, persona
gating) works correctly, but never proved the *UI layer* delivers what each archetype's name promises.

Two real, reusable, engine-backed widgets already exist and are simply unused by the migrated
communities: `_MessagesTabSurface` (genuine multi-thread inbox) and `_MarketplaceBrowseSurface`
(genuine search+filter+grid). `_DocumentsTabSurface`/`_DocumentLibraryWorkflowSurface` also exists and
is genuinely capable, but is dead code — no community's fixture populates the real `documentLibrary`
field it depends on. A true calendar month/week grid does not exist anywhere in the codebase.

## 3. Archetype-by-archetype verdict

| Archetype | Verdict | Evidence |
|---|---|---|
| **calendarAgenda** | Fake. Never a grid anywhere. The one real widget, `_CalendarAgendaDateStrip` (horizontal date-chip strip, `part02_tab_shell.dart:2133`), is dispatched *around* by every engine community — each renders one hardcoded `_first()` card instead. | Confirmed for Garden, Camera, Chess, Mosque, Youth Soccer — 5/5 checked |
| **stateMachineGrid / table** (browse-many) | Fake except Marketplace. Chess rankings = plain `Text` column, no sort. Youth Soccer roster's "Sortable columns" is a hardcoded caption over more `Text` rows — no `onSort` exists anywhere in the package. Garden/Camera = unfiltered `for`-loops, zero search. | `grep` for `DataTable`/`onSort`: 0 hits package-wide. `GridView`: 1 hit (Marketplace) |
| **discussionThread** | Fake for every engine community despite a real widget existing. `_MessagesTabSurface` (genuine multi-thread inbox, mute/archive, per-thread composer) is dispatch-routed around for Chess/Mosque/Youth Soccer/Camera/Book Club — all render one hardcoded thread instance with an appendable string list. | 5/5 engine communities confirmed routed away from the real widget |
| **votePoll** | Broken. Book-Club-exclusive. Hardcodes 2 candidate names as literal field keys (`parableVotes`/`leftHandVotes`); "cast vote" always votes the same candidate; organizer's "declare winner" ignores actual tallies. | `part02_tab_shell.dart:8385-8405, 8936-8961, 9082-9083`; `b43_book_engine_migration_test.dart:48-53,117-120` |
| **dashboard** (Home) | Fake. Section order is a hardcoded global constant (`_orderedSectionTitles`, `part03_workflow_sections.dart:76-88`), not data-driven despite UI copy claiming "prioritized surfaces." Every community reimplements the identical 3-pin-card stack. | 6/6 communities checked, identical pattern |
| **formEntry** | Fake. Always a flat `TextField` list + submit. HOA's only non-text control, a project-type dropdown, is wired `onChanged: (_) {}` — genuinely inert, cannot be changed by the user. | `part02_tab_shell.dart:4514` |
| **statusTimeline** | Fake. Always a plain text list via generic string-key sniffing (any field whose name *contains* "history"/"trail"/"messages"). No vertical line, no timestamped nodes, no visual progression. | HOA, Youth Soccer, Chess Club — 3/3 identical mechanism |
| **protectedDetail** | Permission logic is real and correct. Visual treatment is not — just a ternary swapped into plain `Text`, no masking/blur/lock affordance, no distinct "why hidden" UI. | Mosque, Youth Soccer — 2/2 |
| **paymentCheckout** | Fake. Fact-pills + one "Pay" button, hardcoded receipt IDs (not generated). Resolves to the *identical* shared template as `event-rsvp`/`equipment-loan` at the infrastructure level. | `part18_marketplace_rendering.dart:192-228` |
| **guidedProcess** | **Real — the one clear positive example.** Youth Soccer's registration wizard has a genuine step indicator, visually distinct step chips, real per-step gating copy tied to state. | `part19_youth_soccer_engine.dart:267-328` |
| **documentLibrary** | Dead code, not fake exactly — `_DocumentsTabSurface`/`_DocumentLibraryWorkflowSurface` is a genuinely real multi-document library widget, but no community's fixture populates the real `documentLibrary` field it reads. Falls back to single hardcoded-document cards everywhere. | Confirmed via `_parseDocumentLibrary` call site + fixture grep across all communities |
| **notificationInbox** | Fake. Always exactly one hardcoded instance. No list, no unread badge, no dismiss gesture. | Youth Soccer, Mosque (×2 workflows), Book Club — identical pattern |
| **exportWizard** | Fake. Flat button sequence (preview→generate→transfer→rollback→retry), no step indicator, no `Stepper` anywhere in the package. | Chess, Youth Soccer, Book Club, Garden — 4/4 |
| **volunteerRoster** | Fake. No meter/progress widget exists anywhere. Mosque's 2 real seed instances are never shown together — a hardcoded persona-priority selector shows exactly one at a time. | `part20_mosque_engine.dart:398-417` |
| **searchAiAnswer** | Fake. No `TextField` for entering a new query anywhere. Mosque's "Refine query" force-overwrites the query with a fixed hardcoded string, not user input. | Book Club, Mosque — 2/2 |
| **audienceSelector** | Fake. Plain `TextField`; "multi-select member picker" is a comma-separated text box, split by `,` in code — no picker widget, no chips, no checkboxes. | `part20_mosque_engine.dart:109-116` |
| **singleItem** | Fake. Same generic button-jump card as everything else — no radio group, no segmented control. | `part20_mosque_engine.dart:1149-1258` |

**Net**: 2 of 17 archetypes are genuine. 3 more have a genuinely capable widget sitting unused
(`_MessagesTabSurface`, `_MarketplaceBrowseSurface`'s pattern generalized, `_DocumentsTabSurface`). The
rest need real implementation work — a scope comparable to the whole V2 Phase 1-6 effort.

Also faked in ad-hoc Dart, found while enumerating what computation the interactions actually need (see
[ComputationModel.md](./Loom_Communities_Workflow_Engine_ComputationModel.md)): RSVP capacity/"seats
filled" math is done by **regex-parsing a display label string**
(`_goingCountFromLabel`/`_isCapacityFull`, `part02_tab_shell.dart:2439-2458`) instead of real arithmetic
over `goingPersonaIds`/`capacity` fields.

## 4. Reuse vs. build, per archetype

**Reuse + generalize** (already engine-backed, just hardwired to their original fixture — need
generalizing and wiring into the dispatch switch for whichever communities need them):
- `_MarketplaceBrowseSurface` → the pattern for any "browse many items with search/filter" tab (Chess
  rankings, Youth Soccer roster, Garden/Camera listings, Book Club library) — reformalized onto the
  Data-bound Repeater primitive (see ComputationModel.md §2) for consistency, not rebuilt.
- `_MessagesTabSurface` → the pattern for any `discussionThread` tab, generalized to read threads from
  engine `WorkflowInstance`s (Repeater bound to a live query) instead of its current data source.
- `_DocumentsTabSurface`/`_DocumentLibraryWorkflowSurface` → once fixtures actually populate the real
  `documentLibrary` field with multiple documents, this already renders a real library.

**Build new** (nothing adequate exists anywhere in the codebase today). Items tagged **[Repeater]**
and/or **[Formula]** route through the two primitives in
[ComputationModel.md](./Loom_Communities_Workflow_Engine_ComputationModel.md) rather than bespoke
per-community widgets — that routing is a hard acceptance criterion, not an implementation detail:
- A real calendar month/week grid (the biggest visible gap). **[Repeater]** for day-cell event lists.
- A real multi-option voting/ballot widget — organizer-side creation, rich candidates, cross-instance
  eligibility, scheduled deadline/reminders, real runoff tie-handling. **[Repeater]** for per-candidate
  buttons, **[Formula]** for tally/winner/runoff. Full spec: Tournament + Voting
  ([Phase1_TabletopClub.md §3](./Loom_Communities_Workflow_Engine_Phase1_TabletopClub.md)).
- A real notification inbox. **[Repeater]** bound to a live query, **[Formula]** effect-op for
  `createInstance`.
- A real export wizard with genuine step progression (`Stepper`).
- A real volunteer roster with a capacity meter and multiple shifts. **[Repeater]** for the shift list.
- A real AI-search input (actual `TextField` driving a new query).
- A real audience/multi-select picker (chips + checkable member list). **[Repeater]** for the checkable
  list — the tournament's own RSVP-gated eligibility is the same underlying capability.
- A real single-item preference control (segmented button / radio group).
- A real status timeline visual + a real protectedDetail masking treatment. **[Repeater]** for the
  timeline's timestamped nodes; masking becomes a `[Formula]` (`if($viewer==owner || ..., full,
  masked)`).
- A genuinely data-driven dashboard prioritization (or an honest, simpler design — decide during
  Phase 1, don't overbuild speculatively).
- A real checkbox/relative-time-picker `formEntry` control.
