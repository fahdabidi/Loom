# Language Gap Register + STOP-AND-SURFACE protocol

Part of [tracker 3](./Loom_Communities_Workflow_Engine_3.md).

## The rule (binding, for every agent)

> **The Tabletop Club JSON is FROZEN.**
> [`Loom_Communities_Workflow_Engine_Phase1_TabletopClub_Example.jsonc`](./Loom_Communities_Workflow_Engine_Phase1_TabletopClub_Example.jsonc)
> **MUST NOT be edited during the implementation/validation cycle. Not one character.**

The JSON is the **specification**. The job is to make the app implement it.

**Therefore: if a workflow in the JSON cannot be implemented, that is a gap in the JSON *language* — not
a bug in the JSON.** The fix is never "change the JSON." The fix is to change the language, the engine,
or an archetype.

### What to do when you hit a gap

**STOP. Do not work around it.**

Do **not**: edit the JSON · hardcode the behaviour in Dart · fake the value · silently drop the
interaction · "approximate" it.

Instead, **surface it** with a completed gap report (template below), and **halt that milestone**. The
user decides whether to extend the language or defer the workflow.

### Why this rule exists

Every previous failure in this codebase came from the opposite reflex — quietly making the JSON fit what
the code could already do. That is how 15 of 17 archetypes became the same generic card, how a vote poll
came to hardcode its winner, and how a state machine ended up with a state that had no transitions.

**A gap that gets worked around is a gap that never gets fixed.** Freezing the JSON removes the escape
hatch on purpose: the only way forward is through the language.

### Who surfaces gaps

| Agent | When |
|---|---|
| **Implementation agent** | While implementing — "the JSON asks for X and the grammar/engine cannot express it" |
| **Verification agent** | While reviewing code, fixing bugs, or doing a UI review — "this renders/behaves wrong and no JSON change could fix it" |

Both use the same template. Both **must stop the milestone**, not push through.

---

## Gap report template

```markdown
## GAP-<n> — <one-line summary>

**Surfaced by:** implementation agent | verification agent
**Milestone:** <e.g. B.3>
**Blocking:** yes | no (workflow degraded but usable)

**What the JSON asks for**
<quote the exact JSON, with file line numbers>

**Why the language cannot express it**
<the specific missing capability. Cite the grammar/engine file that would need to change.>

**Proposed correction** (choose one and justify)
- [ ] **Add an engine API** — <signature, semantics, demo-stub behaviour>
- [ ] **Add a grammar construct** — <new key/op/guard, with JSON syntax>
- [ ] **Add a formula function** — <name, signature, semantics>
- [ ] **Change an archetype contract** — <which archetype, what it must now know>

**Blast radius**
<what else this affects; whether it is a BREAKING grammar change (-> version bump)>

**Workaround available?**
<if non-blocking: what degraded behaviour ships in the meantime, and what is lost>
```

Every gap is appended to the register below, and to
[`docs/references/spec-version.json`](../../../references/spec-version.json) → `knownGaps`.

---

# The register

## Gaps found in the pre-freeze audit (2026-07-14)

Found by reviewing the frozen JSON against
[`docs/references/`](../../../references/README.md) **before** starting implementation, so that
dispatches are not wasted discovering them.

---

## GAP-1 — A transition cannot receive user input

**Surfaced by:** verification agent (pre-freeze audit)
**Blocking:** **YES** for Phase B (ballot). Also degrades Phase F (threads).

### What the JSON asks for

`tournament-ballot` (line ~336): a member votes **for a specific candidate**.

```jsonc
"candidates": [ { "id": "catan", ... }, { "id": "azul", ... }, { "id": "wingspan", ... } ],

{ "id": "cast-vote", "from": ["open"], "to": null,
  "effects": [ { "op": "append", "key": "ballots",
                 "value": { "personaId": "$actor", "choice": "{pendingChoice}" } } ] }
```

The UI must render **one Vote button per candidate**. Each button means "vote for *this* candidate."

### Why the language cannot express it

**There is no way to pass a value into a transition.** `{pendingChoice}` interpolates a field on the
*shared instance*, so the only expressible flow is:

1. write `pendingChoice = "catan"` (an `updateInstanceFields` call), **then**
2. fire `cast-vote` (an `applyTransition` call).

Two calls, orchestrated by something outside the JSON. **Nothing in the grammar links a per-candidate
button to the candidate it represents** — the `candidates` list, the `pendingChoice` field, and the
`cast-vote` transition are three unrelated declarations. The linkage exists only in Dart.

Two consequences:
- **Not declarative.** The archetype must *hardcode* the convention (`candidates` + `pendingChoice` +
  `cast-vote`), an undocumented contract between widget and field names. The Skill could never generate a
  new list-action workflow, because the convention is invisible.
- **Racy.** `pendingChoice` lives on the *shared* ballot. Two concurrent voters: A writes
  `pendingChoice=catan`; B writes `pendingChoice=azul`; A fires `cast-vote` → **A votes for Azul.** The
  same flaw exists on `discussion-thread.pendingMessage`.

### Proposed correction

☑ **Add a grammar construct — transition `inputs`, plus per-item action binding.**

```jsonc
// 1. A transition declares its inputs:
{ "id": "cast-vote",
  "inputs": { "choice": { "type": "text", "required": true } },
  "effects": [ { "op": "append", "key": "ballots",
                 "value": { "personaId": "$actor", "choice": "{input.choice}" } } ] }

// 2. A render binding says where the input comes from, per repeated item:
"renderBindings": [
  { "states": ["open"], "role": "any", "tabId": "home",
    "cardSurfaceFamily": "votePoll", "bindingKind": "primary",
    "repeater": {
      "source": "candidates",
      "itemActions": [ { "transitionId": "cast-vote", "inputs": { "choice": "{item.id}" } } ]
    } }
]
```

- New interpolation scopes: `{input.<name>}` and `{item.<field>}`.
- `applyTransition` gains an `inputs` map — **atomic**: the value travels *with* the transition, so no
  shared scratch field and no race.
- `pendingChoice` and `pendingMessage` disappear from the schema entirely.

**Additive** (existing JSON keeps parsing) → **no version bump**, per
[versioning-policy](../../../references/_meta/versioning-policy.md).

### Blast radius

`WorkflowEffect` interpolation · `applyTransition` signature (add optional `inputs`) · `RenderBinding`
(add optional `repeater`) · the generic renderer. Unlocks **every** "act on one item in a list" pattern —
per-candidate voting, per-shift signup, per-row approval.

### Workaround if deferred

The votePoll archetype hardcodes the `candidates`/`pendingChoice`/`cast-vote` convention. Voting works in
the single-persona demo. **Lost:** genuine declarativeness (the Skill cannot generate this pattern), and
correctness under concurrency.

---

## GAP-2 — No declarative instance creation

**Surfaced by:** verification agent (pre-freeze audit)
**Blocking:** **YES** for Phase E (a member cannot create a proposal) and Phase F (cannot start a thread).

### What the JSON asks for

- `game-purchase-proposal` — *"As a member, I propose a game."* Requires creating a **new** `draft`
  instance.
- `discussion-thread` — *"As a member, I start a new thread."*

### Why the language cannot express it

The engine can `createInstance` **as an effect** — i.e. only as a consequence of *another* transition on
an *existing* instance. There is **no declarative way to say "this workflowType is member-creatable;
render a + New affordance."**

A user cannot transition into existence.

The JSON works around this by seeding a blank `proposal-draft-member` draft — so a member can edit and
submit **one** proposal, but never a second.

### Proposed correction

☑ **Add a grammar construct — a creation binding.**

```jsonc
"renderBindings": [
  { "states": ["draft"], "role": "actor", "tabId": "home",
    "cardSurfaceFamily": "formEntry", "bindingKind": "primary",
    "creatable": { "byPersonaIds": ["tabletop-member"], "label": "Propose a game" } }
]
```

### Creation semantics — **collect first, then create** (this detail is load-bearing)

The affordance MUST:

1. Render a form for the **`initialState`'s `editableFields`** — reusing the existing concept; no new
   "which fields does creation collect" construct is needed.
2. Collect the values.
3. **Then** call `createInstance(workflowType, collectedValues, $actor)`, setting
   `createdByPersonaId = $actor`.

**Do NOT create a blank instance and then let the user fill it in.** A blank instance violates every
`required: true` field the moment it exists, and leaves an orphaned empty row if the user abandons the
form. Collecting first makes creation atomic and keeps `required` meaningful.

**Authoring rule this implies (validator MUST enforce):** if a binding is `creatable`, then every
`required`, non-derived field of that workflow MUST appear in the `initialState`'s `editableFields` —
otherwise a created instance is invalid on arrival. *(This exact bug was found in the Tabletop JSON on
2026-07-14: `discussion-thread` was `creatable` but its required `subject` was not collectable, and
`collab-table` could not collect its `columns` — which would have made user-created tables useless. A
`creatable_missing_required_field` check is now part of A.2's validator scope.)*

**Additive** → no version bump.

### Blast radius

`RenderBinding` (add optional `creatable`) · the generic renderer · one engine call
(`createInstance`, which already exists and already accepts initial data) · one new validator rule.
**Solves Phase E and Phase F with one construct** — build once.

---

## GAP-3 — "All participants except the actor" is not expressible

**Surfaced by:** verification agent (pre-freeze audit)
**Blocking:** no — degraded behaviour ships.

### What the JSON asks for

`discussion-thread` tracks unread state. Correct semantics: posting a message marks it unread **for
everyone except the sender**.

### Why the language cannot express it

No effect op can compute "every participant except `$actor`". `appendUnique` adds **one** value;
`removeValue` removes **one**. There is no set-difference op and no way to write a *list* derived from
another list minus the actor.

The JSON therefore models `unread` as a **single bool for the whole thread** — so the sender's own post
marks the thread unread for the sender too.

### Proposed correction

☑ **Add an effect op — `setFromFormula`** (write a computed list into an effect-written field):

```jsonc
{ "op": "setFromFormula", "key": "unreadByPersonaIds",
  "formula": "removeAll(participantPersonaIds, $actor)" }
```
plus a `removeAll(list, value)` formula function.

Alternatively a narrower `appendAllExceptActor` op — but `setFromFormula` is far more general and closes
a whole class of "derive a stored list" needs.

**Additive** → no version bump.

### Workaround (shipping now)

`unread` stays a single bool. **Lost:** per-persona unread accuracy. Acceptable for the demo; must be
fixed before any real multi-user deployment.

---

---

## GAP-4 — Query-backed fields (`source`) — a table cannot compose with formulas

**Surfaced by:** verification agent (2026-07-14, during the tables re-model)
**Blocking:** **YES** for Phase B (the ballot tally).

### What the JSON asks for

Votes are now **rows in a `tournament-vote` table**, not entries in a list field on the ballot (see the
re-model note below). The ballot still needs its tally:

```jsonc
"ballots": { "type": "list",
             "source": "query(tournament-vote where ballotId == id)" },   // <- the gap

"voteCounts":     { "type": "map",  "formula": "groupCount(ballots, choice)" },
"winner":         { "type": "text", "formula": "argMaxKey(voteCounts)" },
"tiedCandidates": { "type": "list", "formula": "topKeys(voteCounts)" },
"isTie":          { "type": "bool", "formula": "size(tiedCandidates) > 1" }
```

### Why the language cannot express it

**A.5 integration update (2026-07-14):** `InstanceDataField` now preserves the nullable `source` string
as metadata through parsing and persisted definition reload. This lets the read path distinguish a
deliberately unavailable query-backed field from an ordinary missing/typo field and defer only its
dependent formulas without swallowing unrelated formula errors. The engine still does **not** parse or
execute the query expression, load matching rows, or supply the source value. This metadata-only step
does not close GAP-4.

A formula can otherwise only see fields on **its own instance**. So the moment votes become rows in
another table, the tally formulas have nothing to read — and `isTie` is needed *inside the engine*, by
`close-vote`'s `branch` effect, so it cannot be computed in the UI either.

The read-side `aggregate({workflowType, column, op, groupBy})` API **does** exist and works
(`local_workflow_engine_api.dart:169-199`) — but it is a *read* API. The effect evaluator cannot call it.

**This is the missing piece that makes tables composable.** Without it, rows and formulas are two
separate worlds.

### Proposed correction

☑ **Add an `instanceDataSchema` field attribute: `source`.**

```jsonc
"<field>": { "type": "list", "source": "query(<workflowType> where <column> == <thisField>)" }
```

Populated at read time by the same engine that already backs `aggregate`/`queryInstances`. It is a
**derived** field: never seeded, never effect-written — the same rules as `formula`.

**This was in the original design.** ComputationModel.md §1(a) specifies exactly
`"ballots": { "source": "query(vote-ballot where voteId == id)" }`. It was simply never implemented.

**Additive** → no version bump.

### Blast radius

`InstanceDataField.source` metadata preservation is complete. Remaining work: parse/execute its bounded
query, resolve the source before formulas in `_withComputedFields`, and make the validator treat source
fields as derived. This unlocks **every** parent↔child table relationship: a ballot's votes, a table's
rows, a thread's messages, an event's attendees.

---

## Summary — decisions required

| Gap | Blocks | Correction | Additive? |
|---|---|---|---|
| **GAP-1** transition inputs / per-item actions | **Phase B** (voting), Phase F (posting) | Grammar: `inputs` + `{input.x}` + `repeater.itemActions` | Yes |
| **GAP-4** query-backed `source` fields | **Phase B** (tally) | Grammar: `instanceDataSchema[].source` | Yes |
| **GAP-2** `creatable` render binding | **Phase E, F** | Grammar: `renderBindings[].creatable` | Yes |
| **GAP-3** list-minus-actor | Phase F (degraded) | Effect op `setFromFormula` + `removeAll()` | Yes |

**All four are additive** — no version bump, no existing JSON breaks.

**Phase A (Calendar) is blocked by none of them.** It uses only plain transitions, guards, effects, and
same-instance formulas — all of which exist. **Phase A starts immediately.**

**GAP-1 + GAP-4 + GAP-2 are the "tables" milestone (Phase A′).** Together they turn the engine from
"a state machine per row" into a genuine, user-writable table store:

| Capability | Needs |
|---|---|
| INSERT a row with user-supplied values | GAP-1 |
| Read a parent's child rows, and compute over them | GAP-4 |
| Let a user create a new row/table from a "+ New" affordance | GAP-2 |
| UPDATE a cell (claim an item, put your name on a task) | ✅ **already works** |
| `SELECT … WHERE … ORDER BY`, `GROUP BY` | ✅ **already works** (`queryInstances`, `aggregate`) |

---

# Appendix — the 2026-07-14 tables re-model (pre-freeze)

The frozen JSON was **re-modelled before implementation started**, after the table framing exposed a
better design. The freeze protects against mid-cycle drift; it was never meant to prevent fixing a
design we already knew was wrong.

**What changed:**

| Was | Now | Why |
|---|---|---|
| Votes in a `ballots` **list field** on the ballot, written via a shared `pendingChoice` scratch field | Votes are **rows** in a `tournament-vote` table; the choice travels as a transition **input** | The old design was **racy** (A picks Catan, B picks Azul, A's vote lands as Azul) and did not scale (a 10,000-vote ballot = a 10,000-element field on one row) |
| Tally computed over a stored list | Tally computed over a **query-backed** field — **all four formulas unchanged** | Derived, never stored; a counter cannot drift from the votes it summarises |
| `pendingMessage` scratch field on the thread | Message body travels as a transition **input** | Same race: two members typing, one posts the other's text |
| A seeded blank proposal draft (a workaround) | `creatable` on the draft binding | A member can propose *many* games, not fill in one pre-seeded row |
| — | **`collab-table` + `collab-table-row`** — a user-created coordination scratchpad | The requested "group collaboration table" |

**On the atomic-increment proposal:** deliberately **not** adopted. With one row per vote, the count is
`groupCount` over the rows — derived, never stored, so it *cannot* drift, and two voters are two
independent INSERTs with nothing to contend on. A shared counter needs an atomic increment precisely
*because* it is shared, and it discards the facts (who voted for what) that make change-vote,
one-vote-per-person, and auditing possible.

**On user-created tables:** they need **no runtime schema registration**. `collab-table.columns` is a
**data field** — a member "creating a table" creates an *instance* whose `columns` they define, and
"adding a row" creates a `collab-table-row` *instance*. Both types are author-declared and validated at
build time like everything else. The engine never registers a workflowType at runtime, so the security
model, the validator, and the install path are all untouched.

**Later the same day — dropped from scope.** After drafting `collab-table`/`collab-table-row` above and
confirming they were technically sound, the user judged the "let members define their own columns at
runtime" affordance not worth the complexity for this milestone and asked to drop it ("lets ignore the
'user defined' tables... since that is difficult"). Both types and their seed instances
(`table-snack-signup`, `snack-row-1`, `snack-row-2`) were removed from the frozen JSON before the
implementation/validation cycle began; `docs/references/` was not amended since no doc had yet shipped
describing them as real. This does **not** remove GAP-1, GAP-2, or GAP-4 from scope — `tournament-ballot`
(votes-as-rows) and `game-purchase-proposal`/`discussion-thread` (`creatable`) still require all three,
so Phase A′ is unaffected. Only the free-form user-defined-schema table feature itself is gone.

**On embedding Google Sheets:** rejected. (a) Google serves the Sheets editor with
`X-Frame-Options: SAMEORIGIN` — an **editable** sheet cannot be embedded in a WebView; only a published
read-only view can. (b) It would put community data in Google Drive, contradicting the product's own
`core-member-vault` / `protected-visibility-vault` / `export-service` data-sovereignty model. (c) It
adds OAuth, Google accounts for every member, and a hard network dependency to a local-first app. (d) The
coordination use cases need concurrent row-insert and per-cell edit — not character-level OT/CRDT.
