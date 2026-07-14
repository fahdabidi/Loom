# Phase 3 — The Skill (JSON-only, no code, no archetype edits, ever, once this starts)

Part of [Loom_Communities_Workflow_Engine.md](./Loom_Communities_Workflow_Engine.md).

**Depends on [tracker 3](./Loom_Communities_Workflow_Engine_3.md) (the engine-native rebuild) being fully
closed**, and on Phase 2 (community extension). Supersedes
[V2 Phase 6](../Loom%20Communities%20Workflow%20Engine%20V2/Loom_Communities_Workflow_Engine_Phase6_SkillIntegration.md),
which was placeholder-only and never started.

Status: not started.

---

## 1. The constraint that governs everything

> Once this phase begins, every community — including re-doing Tabletop Club's own JSON through the
> Skill as the first proof run — is rebuilt by having the Skill **write JSON**. The Skill never edits a
> `.dart` file and never adds an archetype.

**If this phase discovers a real archetype or grammar gap, that means tracker 3 / Phase 2 was not
actually finished — it is not licence for the Skill to start improvising code.**

The point: a community becomes something the Skill **declares** (JSON, mechanically validated), not
something an LLM hand-writes UI/button code for, per extension.

---

## 2. What changed: the Skill now has a real contract to read

**This is the substantive update to this plan.** When it was first written, there was no authoring
specification — the Skill would have had to reverse-engineer the JSON grammar from Dart source and from
docs that described APIs which never existed.

That is fixed. [`docs/references/`](../../../references/README.md) is now the Skill's grounding:

| The Skill reads | For |
|---|---|
| [`guide/01-authoring-procedure.md`](../../../references/guide/01-authoring-procedure.md) | The 12-step algorithm: requirements → validated JSON |
| [`guide/03-common-patterns.md`](../../../references/guide/03-common-patterns.md) | Six canonical templates (RSVP · ballot · approval queue · loan · payment · thread) covering nearly every requirement |
| [`guide/04-antipatterns.md`](../../../references/guide/04-antipatterns.md) | 11 detection-rule + fix pairs; the mandatory self-check before emitting |
| [`guide/05-validation.md`](../../../references/guide/05-validation.md) | The mandatory gate + the full error→fix table (the repair loop) |
| [`reference/*.md`](../../../references/README.md) | Normative: the complete grammar, all 6 guard kinds, all 9 effect ops, all 20 formula functions, field types, render bindings, the platform-services boundary |
| [`archetypes/README.md`](../../../references/archetypes/README.md) | The **only** legal `cardSurfaceFamily` values, with an honest status per archetype |
| [`communities/`](../../../references/communities/README.md) | Worked reference communities |

The docs are written **for an LLM agent**: complete enumerations, MUST/MUST-NOT invariants, decision
tables, error→fix tables. Not human tutorial prose.

**Consequence for this plan:** old milestone 3.3's "update `components/card-surfaces/*.md`" is
**superseded**. Those 26 prose docs (mirrored 3×, describing a non-existent `CommunityVoteApi`) are
retired in favour of `docs/references/`. They are not to be used for authoring.

---

## 3. Input format — audit before generating anything

**Input:** a community design doc shaped like
[Loom_Communities_Workflow_Engine_Mosque.md](../Loom%20Communities%20Workflow%20Engine%20V2/Loom_Communities_Workflow_Engine_Mosque.md)
(personas, tabs → cards → archetype → actions, customizations).

**Open question this phase answers first:** do the existing 7 community docs carry enough structured
detail to mechanically derive a full JSON definition (state graph, transitions, guards, effects,
formulas, `instanceDataSchema`, `renderBindings`)?

**Working assumption: no.** They were written for a human engineer to interpret and fill gaps — not for
mechanical derivation. The authoring procedure's Step 3 (**states vs data**) is the highest-risk
inference, and a doc that says *"members can queue for a game"* does not tell you whether `queued` is a
state or a data list. **Getting that wrong is the single most damaging modeling error** (see AP-1) — so
the input template must make it explicit rather than leave it to inference.

Treat "does the input doc need a stricter template" as **milestone 3.1**, not an assumption.

---

## 4. Method — the Skill's operating procedure

The Skill follows [`guide/01-authoring-procedure.md`](../../../references/guide/01-authoring-procedure.md)
verbatim. Each step gets its own explicit guidance, not one undifferentiated prompt:

1. **Personas** ← the doc's persona list.
2. **Workflow types** ← the "things" the community manipulates. *One type, many instances.*
3. **States vs data** ← the decision rule. **The riskiest step; the input template must disambiguate it.**
4. **States + transitions** (incl. `to: null` for orthogonal transitions).
5. **`instanceDataSchema`** — form-entry vs effect vs **computed**. *If it can be derived, derive it.*
6. **Guards** ← the permission/condition table.
7. **Effects** ← the change table.
8. **Render bindings** ← tab + role + archetype + binding kind.
9. **Seed instances**.
10. **Anti-pattern self-check** (all 11).
11. **Validate** — the hard gate. Repair-loop against the error→fix table until clean.
12. **Report gaps honestly** — never approximate, never silently drop a requirement.

---

## 5. Gap protocol — carries forward from tracker 3

The Skill inherits tracker 3's **[STOP-and-surface rule](./Loom_Communities_Workflow_Engine_3_LanguageGaps.md)**:

> If a requirement cannot be expressed in the grammar, the Skill **MUST NOT** approximate it, hardcode a
> value, substitute a scripted card for a real interaction, or silently drop it.
>
> It marks the gap (`// NEEDS IMPLEMENTATION: …`), lists it in its final response, and **stops**.

A gap discovered here is evidence that tracker 3 or Phase 2 is incomplete — the correction is an engine/
grammar/archetype change, **never** a bent community JSON.

---

## 6. Milestones

### 3.1 — Community-doc template audit and upgrade  `[ ]`
- [ ] Read all 7 community docs against §3/§4. Produce a concrete gap list: what structured detail is
      missing for mechanical derivation?
- [ ] **Specifically:** does each doc disambiguate **states vs data** (procedure Step 3)? If not, the
      template MUST be upgraded to force it — this is the highest-risk inference the Skill makes.
- [ ] If gaps found: upgrade the template, re-run across all 7 docs, confirm each still reads as a
      human-authored design doc. *Machine-parseability must not cost human readability.*
- [ ] If no gaps: state why, with a worked mechanical-derivation trace on one section of one doc.

### 3.2 — Validation as a required Skill gate  `[ ]`
Carries forward V2 Phase 6 milestone 6.1, now with the real tooling.
- [ ] **`community_package_validator`** (built in tracker-3 A.2) wired into SKILL.md's "Required Workflow
      Validation Gate". This validates the *whole package* — envelope, schema versions, definitions,
      instances, cross-instance references — not just definitions.
- [ ] **`docs_sync_checker`** (built in tracker-3 Phase G) wired in as a **pre-flight**: **the Skill MUST
      refuse to author against stale docs.** It reads them as truth; if they are stale, everything it
      generates is wrong in a way that is very hard to see.
- [ ] A test extension with an intentionally broken workflow (stuck state, dangling reference, unknown
      formula function, circular formula dependency, a **seeded computed field**) is **rejected** before
      any generation proceeds.
- [ ] A valid test extension passes and proceeds unmodified.

### 3.3 — Skill methodology implementation  `[ ]`
- [ ] The 12-step procedure implemented as the Skill's operating procedure
      (`.agents/skills/using-loom-to-build-an-extension/SKILL.md`), each step with its own guidance.
- [ ] SKILL.md points at [`docs/references/`](../../../references/README.md) as the authoring contract,
      and **explicitly marks the legacy doc sets as superseded** (`components/card-surfaces/*.md`, the V2
      Archetype Catalog, the shallow `loom.initialization.json` examples).
- [ ] The Skill's context-load order follows
      [`references/README.md`](../../../references/README.md#load-order-context-budget).
- [ ] The Skill emits `experienceSchemaVersion: 2` **only**, with all three version stamps.

### 3.4 — First proof run: Tabletop Club through the Skill  `[ ]`
Depends on 3.1-3.3.
- [ ] Run the Skill against Tabletop Club's (now-upgraded) design doc, producing JSON from scratch.
- [ ] Validator passes on the generated output.
- [ ] **The acid test:** the generated JSON is *semantically equivalent* to the hand-authored
      [reference JSON](./Loom_Communities_Workflow_Engine_Phase1_TabletopClub_Example.jsonc) — same
      workflow types, states, transitions, guards, effects, formulas, bindings. Diff and explain **every**
      divergence. (Byte-identity is not expected; behavioural equivalence is.)
- [ ] Generated JSON drives the running app to the **same** real interactions tracker 3 built — proven by
      re-running tracker 3's widget/unit suites against the Skill-generated fixture instead of the
      hand-authored one. **Zero regressions.**
- [ ] Code review confirms **zero** hand-written per-workflow wiring was needed — no new Dart introduces a
      bespoke per-workflow branch.
- [ ] Live emulator walk per the
      [UI Review Prompts](./Loom_Communities_Workflow_Engine_3_UIReviewPrompts.md) — full-tab audits,
      evidence matrix, regression re-check.

> **This is the milestone that proves the entire three-tracker effort.** If the Skill can regenerate
> Tabletop Club from its design doc, with no code, and the app behaves identically — the "JSON only, no
> code" promise is real. If it cannot, the gap it hits is the most valuable finding in the project.

### 3.5-3.11 — Community rollout  `[ ]`
Garden Club · Camera Club · Book Club · Chess Club · Youth Soccer · Mosque · HOA.

These currently run on the **legacy shallow schema (`experienceSchemaVersion: 1`)** with hand-written Dart
behind each feature. Each rollout **migrates the community to v2** by regenerating it through the Skill.

Each milestone: Skill run against the (upgraded) design doc → validator pass → generated JSON replaces the
hand-authored fixture → that community's existing test suite passes **unmodified** against the generated
fixture → live walk per the UI Review Prompts → its bespoke Dart engine-store is **deleted**.

**Success metric: net Dart deleted.** Each community migrated should *remove* the hand-written store that
existed only because there was no way to load a state machine from JSON.

---

## 7. Definition of done

- [ ] All 8 communities (Tabletop + 7) run from Skill-generated, validator-clean, `v2`-stamped JSON.
- [ ] No community has a bespoke Dart engine-store.
- [ ] The Skill wrote **zero** lines of Dart.
- [ ] `docs/references/` is in sync (the docs-sync checker is green in CI).
- [ ] Every gap the Skill surfaced is either closed in the grammar or explicitly, honestly deferred.
