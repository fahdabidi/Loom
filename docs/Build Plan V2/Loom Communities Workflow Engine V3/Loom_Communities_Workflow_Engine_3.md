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
| **GAP-4** — query-backed `source` fields are not parsed or evaluated, so a parent cannot compute over its child-row instances | **Phase B** | Grammar: `instanceDataSchema[].source` | Yes |
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
| **A** | **Foundation + Calendar tab** (validator, JSON loading, shared engine, generic renderer, binding dispatch, Calendar end-to-end) — **ends in a human JSON-review gate** | [PhaseA_Calendar](./Loom_Communities_Workflow_Engine_3_PhaseA_Calendar.md) | `[ ]` In progress — A.1–A.4 complete; A.5 in implementation |
| **A′** | **Grammar extensions** — close **GAP-1** (transition `inputs` + repeater `itemActions`), **GAP-4** (query-backed `source` fields), and **GAP-2** (`creatable` binding). Small, additive, engine+grammar only. **Required before B and E/F.** | [LanguageGaps](./Loom_Communities_Workflow_Engine_3_LanguageGaps.md) | `[ ]` Blocked on A |
| **B** | **Home tab** — tournament ballot (cross-instance eligibility guard, tally/tie/**real runoff** via branch+createInstance, deadline/reminder), tournament attendance card, published announcements | [PhaseB_Home](./Loom_Communities_Workflow_Engine_3_PhaseB_Home.md) | `[ ]` Blocked on A′ (GAP-1) |
| **C** | **Marketplace tab** — equipment-loan lifecycle (borrow/queue/return, cross-workflow dues guard), giveaway | [PhaseC_Marketplace](./Loom_Communities_Workflow_Engine_3_PhaseC_Marketplace.md) | `[ ]` Blocked on A |
| **D** | **Giving tab** — quarterly dues payment (gates Marketplace's borrow) | [PhaseD_Giving](./Loom_Communities_Workflow_Engine_3_PhaseD_Giving.md) | `[ ]` Blocked on A |
| **E** | **Game purchase proposals** — one feature spanning Home (member submits) + Admin (organizer's live pending queue decides). Replaces the old scripted "committee decision" card | [PhaseE_Proposals](./Loom_Communities_Workflow_Engine_3_PhaseE_Proposals.md) | `[ ]` Blocked on A′ (GAP-2) |
| **F** | **Messages tab** — threads on the engine + the missing **"start a new thread"** action | [PhaseF_Messages](./Loom_Communities_Workflow_Engine_3_PhaseF_Messages.md) | `[ ]` Blocked on A′ (GAP-2) |
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
| A.5 | One shared engine per community: register definitions + seed instances at install (no UI) | `[ ]` |
| A.6 | Generic schema-driven instance card (fields from `instanceDataSchema`, buttons from `availableTransitionsAsync`) | `[ ]` |
| A.7 | `renderBindings` → tab dispatch, **Calendar only** | `[ ]` |
| A.8 | Calendar tab end-to-end from JSON: both events, real RSVP + waitlist, formula-driven capacity | `[ ]` |
| A.9 | Calendar theming fixes (date-strip dark-on-dark, month grid takes no theme) | `[ ]` |
| A.10 | Live emulator walk + evidence matrix → **HUMAN GATE: user reviews and improves the JSON** | `[ ]` |

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
- Update [`archetypes/README.md`](../../../references/archetypes/README.md) — flip its archetype's status
  from 🔨 REBUILDING to ✅ REAL. *An honest status table is the whole value of that index.*
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
