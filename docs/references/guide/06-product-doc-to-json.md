---
spec: 4
doc_version: 1.0.0
status: current
last_verified: 2026-07-15
audience: llm-agent
derived_from:
  - docs/Build Plan V2/Skill/references/community-product-experience-template.md
  - docs/references/communities/tabletop-club.md
  - docs/references/communities/Loom_Communities_Workflow_Engine_Phase1_TabletopClub_Example.jsonc
---

# Product doc → JSON (the crosswalk)

**When to use this.** Your input is a filled-in
[Community Product Experience Template](../../Build%20Plan%20V2/Skill/references/community-product-experience-template.md)
— a human-authored, human-verifiable description of a community (identity, personas, workflow types,
surfaces, seed data). Your output is one validated `experienceSchemaVersion: 2` package. This doc is the
**mechanical mapping** from each of the template's 11 sections to the JSON it produces, and which
reference doc governs the legal values for that JSON.

**How this relates to [`01-authoring-procedure.md`](./01-authoring-procedure.md).** Doc 01 is the
emit-and-validate algorithm (steps 1–12). This doc (06) is the step *before* 01: it tells you **what raw
material each product-doc section hands to which of 01's steps.** Read 06 to extract structure from the
product doc; then run 01's steps 4–12 to emit and validate. When 06 and 01 describe the same JSON, 01 is
the normative shape; 06 only says "this product-doc section is where that JSON comes from."

## The four rules that never bend (restated from the [README](../README.md))

1. **JSON only. Never Dart, never "the app should…".** If a requirement seems to need code, it is
   (a) already expressible and you have not found it — re-read [`effects.md`](../reference/effects.md) and
   [`formulas.md`](../reference/formulas.md); or (b) a [platform service](../reference/platform-services.md);
   or (c) a genuine grammar gap — **stop and report it** (see [§Gap set](#the-gap-set--what-the-product-doc-can-ask-for-that-the-grammar-cannot-yet-express)).
2. **Only emit keys enumerated in `reference/`.** An invented key parses silently and does nothing.
3. **If a value can be derived, derive it** — computed `formula` field, never a stored/seeded count.
4. **Pass the validator before you emit** ([`05-validation.md`](./05-validation.md)). A community that
   does not validate is not a deliverable.

---

## Section-by-section map (the index)

| Product-doc section | Produces (JSON) | Governed by | Feeds 01 step |
|---|---|---|---|
| §1 Community Identity And Promise | package envelope + `experience.{displayName,tagline,accentColor,theme}` | [README envelope](../README.md), [theming.md](../reference/theming.md) | — (envelope) |
| §2 Personas, Roles, And Jobs | `experience.personas[]` | [guards.md](../reference/guards.md) (allowlist targets) | Step 1 |
| §3 Workflow Types: Lifecycle And Data | `workflowDefinitions` keys · each type's `states` (Lifecycle) · `instanceDataSchema` (Independent facts) | [workflow-grammar.md](../reference/workflow-grammar.md), [field-types.md](../reference/field-types.md) | Steps 2, 3, 4, 5 |
| §4 Information Architecture | `renderBindings[].tabId` (which surfaces exist) | [render-bindings.md](../reference/render-bindings.md) | Step 8 |
| §4.1 Persona Tabs / Customization | `experience.theme` + `theme.tabThemes`; tab *presence* is derived from bindings | [theming.md](../reference/theming.md) | Step 8 |
| §5 Home Screen Requirements | `renderBindings` with `tabId: "home"` (curated, not everything) | [render-bindings.md](../reference/render-bindings.md) | Step 8 |
| §6 Domain-Native Product Surfaces | `cardSurfaceFamily` (archetype) + required content → schema fields + required states → `states` + natural actions → `transitions` | [archetypes/README.md](../archetypes/README.md) | Steps 4, 5, 8 |
| §7 Workflow-To-Surface Mapping | the concrete `renderBindings` rows + proof fields (`displayContexts`/`labelTemplate`) + guards/effects/formulas | [render-bindings.md](../reference/render-bindings.md) | Steps 6, 7, 8 |
| §8 Persona And State Matrix | `guard`s (who) + binding `role`/`bindingKind` (actor/receiver, primary/summary) | [guards.md](../reference/guards.md), [render-bindings.md](../reference/render-bindings.md) | Steps 6, 8 |
| §9 Content And Seed Data Requirements | `workflowInstances[]` | [field-types.md](../reference/field-types.md) (seed rules) | Step 9 |
| §10 Visual And Interaction Standard | `displayIcon`/`tone`/`theme` metadata; the rest is App Shell | [theming.md](../reference/theming.md), [field-types.md](../reference/field-types.md) | Steps 5, 8 |
| §11 Review And Remediation Log | **nothing emitted** — process ledger, not JSON | — | — |

The rest of this doc walks each row with the exact rules and a Tabletop Club worked example. The finished
Tabletop Club JSON is
[`communities/Loom_Communities_Workflow_Engine_Phase1_TabletopClub_Example.jsonc`](../communities/Loom_Communities_Workflow_Engine_Phase1_TabletopClub_Example.jsonc);
open it side-by-side — every rule below points at a real line there.

---

## §1 → package envelope + experience header

The product doc's identity table becomes fixed top-level keys. All three version fields are **mandatory**
(README hard rule 2).

| Product-doc field (§1) | JSON key |
|---|---|
| Community name | `displayName` (root **and** `experience.displayName`) |
| Community type / handle | `communityHandle` (kebab), `packageId`, `communityId`, `extensionId` |
| Brand cues → accent | `branding.accentColor`, `experience.accentColor`, `experience.theme.accent` |
| Product promise / tagline | `experience.tagline` |

```jsonc
"schemaVersion": 1,                     // envelope — always 1
"packageId": "init_verify_tabletop_club_2",
"communityId": "community_verify_tabletop_club",
"communityHandle": "tabletop-club",
"displayName": "Tabletop Club",
"extensionId": "ext_verify_tabletop_club",
"branding": { "accentColor": "#C4703F", /* logo/hero/altText optional */ },
"experience": {
  "experienceSchemaVersion": 2,         // engine-native — always 2 for new communities
  "workflowGrammarVersion": 1,          // always 1
  "displayName": "Tabletop Club",
  "tagline": "Board game nights, tournaments, loaner games, and dues for local tabletop fans.",
  "accentColor": "#C4703F",
  "theme": { "accent": "#C4703F", "tabThemes": { "giving": { "accent": "#8A5A34" } } }
}
```

**Rule:** "What this must not feel like" (§1's anti-goal row) has no JSON target — it is a review
criterion you check the emitted bindings against, not a key. If §1 says "must not feel like a generic
workflow list," that is a reminder to bind workflows to *domain* tabs (§4), not dump them all on `home`.

---

## §2 → `experience.personas[]`  (01 Step 1)

Every row of the §2 persona table becomes one persona object.

```jsonc
"personas": [
  { "personaId": "tabletop-organizer", "label": "Organizer", "roleLabel": "Organizer",
    "description": "Plans game nights and tournaments, manages the library, decides proposals, collects dues." },
  { "personaId": "tabletop-member", "label": "Member", "roleLabel": "Member",
    "description": "RSVPs, borrows games, proposes purchases, votes, pays dues." }
]
```

**Rules:**
- `personaId` is kebab-case and **stable** — every `allowedPersonaIds`, `byPersonaIds`, and seed
  `createdByPersonaId` you write later must match one of these exactly, or the validator warns
  (`dangling_allowed_persona_id`).
- The §2 "Sensitive constraints" and "Success state" columns do **not** become persona fields. They drive
  *guards* (§8) and *render bindings* (§7) downstream — note them, do not emit them here.
- Collapse near-duplicate personas. If two rows have the same capabilities and differ only by which
  instances they act on, they are **one** persona differentiated by `role` on a binding (§8), not two
  personas. (The Tabletop "organizer vs member" split is real — they can fire different transitions.)

---

## §3 → `workflowDefinitions`  (01 Steps 2–5) — the load-bearing section

§3 is the template's own highest-risk section, and it maps to the highest-risk JSON. Each **row** of the
§3 table becomes **one `workflowDefinitions` entry**; each row's **two columns** split into two different
JSON places:

| §3 column | Becomes | Reference |
|---|---|---|
| **Lifecycle (→ states)** — "phase → phase, mutually exclusive" | the type's `states` map + the `to: "<state>"` transitions that move between them | [workflow-grammar.md](../reference/workflow-grammar.md) |
| **Independent facts (→ data)** — "true for many at once, independent of phase" | `instanceDataSchema` fields + the `to: null` orthogonal transitions that mutate them | [field-types.md](../reference/field-types.md) |

### 3a. One row = one type (01 Step 2)

**Test:** do two things share the same states *and* the same transitions? Yes → one type, many instances.
No → two types. A community with 40 game nights has **one** `event-rsvp` type and 40 instances.

### 3b. The states-vs-data decision (01 Step 3) — apply the template's two litmus tests mechanically

For every condition the §3 row mentions, run **both** tests. They come straight from the template:

- **Simultaneity test** — picture ten members interacting at once. Can this be true for some and false
  for others *at the same moment*? **Yes → data** (`instanceData` + a `to: null` transition).
- **Exclusivity test** — can the *thing itself* be in two of these at once (e.g. "on loan" *and*
  "queued")? **Yes → both are data.** Only a value that never coexists with another from the same column
  is a **state**.

| §3 phrase in the product doc | Verdict | JSON |
|---|---|---|
| "signups are open / the event is cancelled" | state (mutually exclusive) | `states: { open, cancelled }`, `cancel` transition `to: "cancelled"` |
| "members who have RSVP'd going" | data (many, simultaneous) | `goingPersonaIds: personaId[]`, `rsvp-going` transition `to: null` |
| "a game is on loan / available" | data (coexists with a queue) | `availabilityState: text`, set by `to: null` transitions |
| "members queued for a game" | data (coexists with on-loan) | `queuedPersonaIds: personaId[]` |
| "a proposal is draft / pending / approved / rejected" | state (mutually exclusive) | four `states`, `to:`-changing transitions |
| "a vote has been cast" | data — but see 3c | a **row** in a child type, not a field |

**Failure mode this prevents:** modeling "queued" as a *state*. Because an item can be on-loan *and*
queued, "queued" has no coherent transitions, becomes a dead-end, and renders **no buttons** — a real
shipped bug the validator now catches as `stuck_state`.

### 3c. When "many independent records" is really a child table

If a §3 fact is "a list of records each carrying their own fields, that you later count/tally/audit"
(votes, donations, sign-off signatures), model it as a **separate one-row-per-record type**, not a `list`
field:

- Parent type (`tournament-ballot`) holds the question; child type (`tournament-vote`) is one row per
  vote (`instanceDataSchema` = the columns `ballotId`, `voterId`, `choice`; `transitions: []`;
  `renderBindings: []` — it renders nowhere, it exists to be aggregated).
- Casting a vote is a `createInstance` **INSERT** — atomic, so two concurrent voters cannot clobber a
  shared list.
- The tally is a `formula` (`groupCount`), never a stored counter.

**This pattern needs GAP-1 and GAP-4** to be fully live (see the [Gap set](#the-gap-set--what-the-product-doc-can-ask-for-that-the-grammar-cannot-yet-express)).
The child-table shape itself is valid JSON today; wiring the parent's aggregate field to the child rows
is the part still under construction.

### 3d. Emit states, transitions, schema (01 Steps 4–5)

Once the split is decided, write the type per [workflow-grammar.md](../reference/workflow-grammar.md).
Invariants the validator enforces: every non-terminal state has ≥1 outgoing transition (`stuck_state`);
every state is reachable (`unreachable_state`); `to: null` for orthogonal (data-only) transitions; only
`writableBy: "formEntry"` fields may appear in a state's `editableFields`; **computed fields are never
seeded and never effect-written**.

**Worked example (Tabletop `event-rsvp`):** Lifecycle `open → cancelled`. Everything else is data:
`goingPersonaIds`/`maybePersonaIds`/`notGoingPersonaIds`/`waitlistPersonaIds` (all `to: null`
transitions), `capacity` (form-entry), and computed `goingCount`/`seatsRemaining`/`isFull` (formulas).
That single split *is* the RSVP feature.

---

## §4 / §4.1 → tabs, and how tabs come to exist  (01 Step 8)

**A tab is not declared. It appears because a workflow binds to it.** `home` and `messages` are always
present (structural). `calendar`, `marketplace`, `giving`, `admin` appear **iff** at least one
`renderBindings` entry names them. So §4's surface table is realized entirely through §7's bindings —
there is no separate "tabs" array to emit.

| §4 "Surface" | `tabId` |
|---|---|
| Home | `home` (always) |
| Messages / Communication | `messages` (always) |
| Calendar / schedule | `calendar` |
| Marketplace / library / browse | `marketplace` |
| Giving / dues / donations | `giving` |
| Organizer queues / publishing | `admin` |

**§4.1 customization — what IS and ISN'T expressible:**
- ✅ Per-tab accent: `experience.theme.tabThemes.<tabId>.accent` (see [theming.md](../reference/theming.md)).
- ❌ Per-persona *different tab sets*, pinned surfaces, custom tab order, per-persona labels/icons,
  hidden/disabled tabs. **None of these are in grammar v1.** If §4.1 asks for them, this is App Shell
  behavior — **report it as out-of-grammar**, do not invent keys (README hard rule 3). You *can*
  approximate "this surface is only for organizers" by giving its bindings `role: "receiver"` and
  `tabId: "admin"`, but you cannot reorder or rename tabs per persona.

---

## §5 → Home bindings (curated, not a dump)  (01 Step 8)

§5 says the first screen shows *curated* current activity and role-specific next actions, and explicitly
**not** a global workflow list. Translate that as: bind to `home` **only** the workflows §5 names as
belonging there, with the right `role`.

- "the member sees their proposal's status" → the proposal's `role: "actor"` home binding.
- "the ballot is a Home card, not its own tab" → the ballot binds `tabId: "home"`, and you do **not**
  create a `ballot` tab.
- Anti-pattern (from [render-bindings.md](../reference/render-bindings.md)): every workflow bound to
  `home` "so the user sees it." Home is a curated feed. Bind each workflow to the tab it belongs on.

---

## §6 → archetype + content + states + actions  (01 Steps 4, 5, 8)

Each §6 row ("Announcement/feed", "Event/RSVP", "Payment", …) is a **product surface**, and its four
columns map to four different JSON places:

| §6 column | JSON |
|---|---|
| Required visible content | `instanceDataSchema` fields with `displayContexts`/`labelTemplate`/`displayIcon` |
| Required states | the type's `states` |
| Natural actions | the type's `transitions` |
| Anti-patterns | review criteria (not emitted) |
| *(the surface itself)* | `cardSurfaceFamily` on the binding — **choose by structural match, below** |

### 6a. Deriving `cardSurfaceFamily` — structural match, do not guess

Do **not** pick an archetype from the surface's *name*. Pick it by matching the **shape** you derived in
§3/§6 against the archetype's fingerprint. Only the values in
[`archetypes/README.md`](../archetypes/README.md) exist (inventing one → `missing_template`, renders as a
generic card).

| If the derived shape is… | `cardSurfaceFamily` |
|---|---|
| lifecycle + a member list + capacity/waitlist formula | `event-rsvp` |
| a question + candidate list + `groupCount` tally + tie/runoff | `votePoll` |
| an item with availability data + queue + borrow/return | `equipment-loan` |
| an amount + pay transition + receipt | `paymentCheckout` |
| a live `queryInstances(state == pending)` list a receiver decides | `approvalQueueItem` |
| author/edit a record via typed controls | `formEntry` |
| a status progression the owner watches read-only | `statusTimeline` |
| threads + messages + compose | `discussionThread` |
| an organizer notice members read | `notificationInbox` |

⚠️ **Honesty gate (from [archetypes/README.md](../archetypes/README.md)):** most archetypes are being
rebuilt (tracker 3). Declaring `cardSurfaceFamily: "volunteerRoster"` today gets you a generic card, not
a capacity meter. Your JSON is correct and forward-looking, but **do not tell the user an interaction
works when the archetype is `NOT REAL`.** Check the Status column and say so.

### 6b. Content → fields

Every noun in the §6 "required visible content" cell becomes a declared field, given a **distinct**
`displayIcon` (never the same icon on every pill — a real shipped bug), a `labelTemplate` for how it
reads, and `displayContexts` (`["tile"]` compact, `["detail"]` expanded, both = everywhere). Derive
everything derivable as a `formula` (§3 rule 3).

---

## §7 → the concrete `renderBindings` rows  (01 Steps 6–8)

§7 is a table of (workflow × persona × surface × proof × APIs). It is the most direct 1:1 map in the
whole doc: **each §7 row becomes one or more `renderBindings` entries**, plus it tells you which guards,
effects, and formulas the type needs.

| §7 column | JSON |
|---|---|
| Workflow | which `workflowDefinitions` key |
| Persona | binding `role` (`actor` = owns/acts, `receiver` = approves, else `any`) |
| Product surface | binding `tabId` + `cardSurfaceFamily` |
| Required visible proof | fields' `displayContexts`/`labelTemplate` (the pills that must show) |
| Loom APIs/rules/events | the `guard`s / `effects` / `formula`s the type must carry |
| Test/evidence IDs | not emitted — traceability for the reviewer |

**One workflow, several rows.** A proposal binds `role: "actor"` on `home` (the author tracks it) *and*
`role: "receiver"` on `admin` (the organizer decides it). That is **one** workflow with two bindings, not
two workflows. A state with **no** binding does not render — the correct way to hide a `draft` from the
organizer (omission, never a permission flag).

**`bindingKind`:** `primary` for the state where the user acts (includes the action-button row — a
`primary` binding **must** have actions or the validator errors `missing_action_button_row`); `summary`
for states they only observe (a closed ballot, a cancelled event).

---

## §8 → guards + role/kind  (01 Steps 6, 8)

The §8 matrix (actor / receiver / read-only / disabled-hidden / unauthorized) is where **guards** and
**binding roles** come from. Map each cell:

| §8 cell | JSON mechanism | Reference |
|---|---|---|
| "actor state" — who may act | `guard.allowedPersonaIds` (+ `actorInList`, `relatedListMembership`, `requiresWorkflowsComplete` as the condition dictates) | [guards.md](../reference/guards.md) |
| "receiver state" — who approves/sees the queue | a `role: "receiver"` binding | [render-bindings.md](../reference/render-bindings.md) |
| "read-only state" — observe, don't act | `bindingKind: "summary"` (or a terminal state with no actions) | render-bindings |
| "disabled/hidden" — conditionally unavailable | a `guard` (`formula` / `actorInList` / `instanceDataEquals`) that makes the button not appear | guards |
| "unauthorized behavior" — must be refused | a `guard` — **the engine refuses `applyTransition`, not the UI.** Never rely on hiding for correctness | guards |

**Guard-selection table** (the six kinds; there are no others):

| §8 requirement phrasing | Guard |
|---|---|
| "only organizers can …" | `allowedPersonaIds` |
| "only if not already in / already in the list" | `actorInList: { key, present }` |
| "only while the item is available" | `instanceDataEquals: { key, value }` |
| "only if there's room / before the deadline / any computed condition" | `formula` |
| "only members who RSVP'd to the linked event" | `relatedListMembership` (`relatedInstanceField` + `relatedListField` — **flat sibling keys**) |
| "only if they've paid dues / finished another workflow" | `requiresWorkflowsComplete` |

All guards on a transition are **AND**-ed. There is **no OR** — express alternatives as two transitions
with different guards (they usually want different labels anyway: "Borrow" vs "Join queue").

**A guard may hold only ONE `formula` key.** When a single transition needs *two* computed conditions,
fold them into one expression with `if()` (there is no `&&`-across-guard-keys for two formulas because
there is only one formula slot):

```jsonc
// "the holder may renew, but only when nobody is queued" — two computed conditions, one formula:
"guard": { "formula": "if(holderPersonaId == $actor, size(queuedPersonaIds) == 0, false)" }
```

**Worked example (§8 "owner-only approval" for peer game sharing):** "approve/decline hidden from
everyone except the owner" → the transition guard is `formula: "ownerPersonaId == $actor"`. This is a real
engine guard — a `formula` guard binds `$actor` (verified in `guard_evaluator.dart`), so no new grammar is
needed. ⚠️ **But mind the identity model:** if the community authenticates as a small set of *roles*
(e.g. one `member` persona shared by every member) rather than per-individual ids, `ownerPersonaId ==
$actor` distinguishes *role*, not *person* — "only THIS owner" then needs per-user identity, which is a
[platform service](../reference/platform-services.md). The guard shape is correct for a real backend;
flag the degradation for a role-based demo rather than pretending it isolates individuals.

---

## §9 → `workflowInstances[]`  (01 Step 9)

Every concrete card the §9 seed-data list describes becomes one instance. Shape:

```jsonc
{ "instanceId": "<unique>", "workflowType": "<a declared type>",
  "currentState": "<a declared state of that type>",
  "createdByPersonaId": "<a declared persona>",
  "instanceData": { /* declared fields only; NO computed fields */ } }
```

**Rules (validator-enforced):** `instanceId` unique; `workflowType` exists; `currentState` is a declared
state; every `instanceData` key is declared; every `required` non-computed field is present
(`missing_required_field`); **no computed field appears** (`computed_field_seeded`); every cross-instance
reference (an `eventId`, a `ballotId`) names an existing `instanceId`.

**Make the seed prove the feature.** §9 exists so a screenshot shows a *production* surface. Seed the
states that exercise the interaction: an event near capacity (so the waitlist guard is live), a listing
that is on-loan-with-a-queue (so queue math shows), one already-decided and one pending proposal (so both
the actor's outcome view and the receiver's queue render). A computed value (a tally, a count) is **never
seeded** — seed the underlying rows/lists and let the formula produce it.

---

## §10 → display + theme metadata (mostly)  (01 Steps 5, 8)

§10 ("how it should feel") is largely realized by metadata you already emit, plus theme:
- Accent cascade → `experience.theme` + `tabThemes` ([theming.md](../reference/theming.md)). Every card
  derives its colors from the resolved theme; **never hardcode a color** — and there is no per-card color
  key to hardcode one with anyway.
- Iconography → each field's `displayIcon` (distinct, meaningful).
- State tone → `states[].tone` (`positive`/`negative`/`warning`/`info`) and `transitions[].tone`
  (`primary`/`secondary`/`destructive`).

❌ **Not in grammar:** layout density, navigation/back-stack behavior, card-vs-list presentation,
spacing, typography. These are App Shell concerns. If §10 pins a specific navigation model (e.g.
"breadcrumbs follow real depth; back goes one level up"), **report it as App Shell scope** — it is
correct to record in the product doc, but there is no JSON key for it.

---

## §11 → nothing

The Review And Remediation Log is a process ledger. It emits no JSON. Do not try to encode it.

---

## The gap set — what the product doc can ask for that the grammar cannot yet express

Four blocking gaps are registered in [`spec-version.json`](../spec-version.json) `knownGaps`. When a
product-doc requirement lands on one, do **exactly** what the reference Tabletop JSON does: write the
construct in its intended forward-looking shape, mark it inline with a
`// NEEDS IMPLEMENTATION: <what and why>` comment, and **list it in your final report**. Never fake it
with a workaround (a seeded blank draft, a shared scratch field, a hardcoded winner) — workarounds in the
spec teach the wrong thing.

| Product-doc phrasing that triggers it | Gap | Forward-looking shape | Status |
|---|---|---|---|
| "**any member can list / create a new** X" (list your own game, start a thread, submit a proposal) | **GAP-2** `instanceCreation` | ⚠️ Shipped as `renderBindings[].actions: [{"kind":"create", "label", "byPersonaIds", "scope", "presentation"}]`, **not** the `creatable: {...}` shape this row originally proposed — `creatable` is dead grammar-1 vocabulary, silently dropped if used. See `render-bindings.md` for the real `actions[]` shape. | SHIPPED (Phases E/F) |
| "a **per-item button that carries which item**" (vote for THIS candidate; borrow THIS one with a note) | **GAP-1** `transitionInputs` | `transitions[].inputs` + `{input.x}` interpolation + `renderBindings[].repeater.itemActions` | BLOCKING (Phase B) |
| "a parent shows a **live tally/list of child rows**" as a field a formula reads (ballot reads its votes) | **GAP-4** `queryBackedSources` | `instanceDataSchema[].source: "query(childType where fk == id)"` | BLOCKING (Phase B) |
| "notify / mark unread for **everyone except me**" | **GAP-3** `listMinusActor` | `setFromFormula` effect op + `removeAll(list, value)` formula fn | non-blocking |
| "pre-fill the create form with **the context I tapped from**" (the tapped calendar date) | GAP-2 addition `prefill` | ⚠️ Shipped as `actions[].prefill: { field: "{context.date}" }` + `{context.x}` (on the `actions[]` entry, not a `creatable` key — see above) | SHIPPED |

The full designed shapes and validator additions for all of these live in
[`Loom_Communities_Workflow_Engine_3_GrammarExtensions.md`](../../Build%20Plan%20V2/Loom%20Communities%20Workflow%20Engine%20V3/Loom_Communities_Workflow_Engine_3_GrammarExtensions.md)
(proposal, awaiting sign-off). The **approval-queue itself is not a gap** — a receiver `renderBindings`
row over `queryInstances(state == pending)` is ordinary. Only the *parent-field aggregation* of child
rows (GAP-4) and the *create affordance* (GAP-2) are.

### Two formula-vocabulary limits you *will* hit (and how to handle them)

These are narrower than the four registered gaps but recur in loan/queue/deadline features. Neither is in
`spec-version.json` `knownGaps` yet — **flag them if a product-doc requirement needs them:**

| You need… | Why it's blocked | Handle it by |
|---|---|---|
| a **computed future date** ("due back = now + 2 weeks", "renew extends the deadline") | no formula function *returns a date* — `daysUntil`/`daysBetween` return numbers, `now()` is only "now" | mark the date-setting effect `// NEEDS IMPLEMENTATION` and leave it unset, or take the date as form-entry; never fake a hardcoded date |
| **promote the head of a queue** ("on return, the first queued member becomes the pending borrower") | no list-head / `elementAt` / `first` function exists; `indexOf` finds a position but you can't read `list[0]` | model the hand-off as a fresh re-request (queue members re-request), and `// NEEDS IMPLEMENTATION` the auto-promotion |

Both surfaced writing the Tabletop peer game-loan (`tabletop-game-loan`) — see its inline
`NEEDS IMPLEMENTATION` comments for the exact shape.

### Platform services are not gaps — they are the closed not-JSON set

If the product doc asks for real payment processing, a generated receipt id, real push notifications /
timers, image/file storage, or an AI/search answer, that is a
[platform service](../reference/platform-services.md): engine-provided, demo-stubbed. Mark the field
`// NEEDS IMPLEMENTATION (platform service)` and leave the fake value **out** rather than hardcoding it
(a hardcoded `receiptId` is the exact anti-pattern the audit exists to kill).

---

## ⚠️ Reference-folder gap found while writing this guide (flag for maintainers)

Per the user's instruction to flag anything missing from `docs/references/` that a medium-reasoning model
would need: **the four forward-looking constructs above are used by the reference community
(`Loom_Communities_Workflow_Engine_Phase1_TabletopClub_Example.jsonc`) but are documented *only* in
`spec-version.json` `knownGaps` and the product docs — not in the normative `reference/*.md` files.**

Concretely, `reference/render-bindings.md` does not list `creatable` / `repeater` / `itemActions`,
`reference/effects.md`/`guards.md` do not list transition `inputs` / `{input.x}`, and
`reference/field-types.md` does not list query-backed `source` / `{context.x}` / `prefill`. A model told
"only emit keys enumerated in `reference/`" (README hard rule 3) would therefore **refuse to emit exactly
the keys the reference community relies on.** This guide bridges that by pointing at the GrammarExtensions
proposal, but the durable fix is:

> When GrammarExtensions is signed off and implemented, add each construct to its governing
> `reference/*.md` (render-bindings, effects, guards, field-types) and move the `knownGaps` entries into a
> `resolvedInGrammar` section — the publishing flow this repo already documents in
> [`_meta/publishing-flow.md`](../_meta/publishing-flow.md). Until then, treat these four as **write +
> mark + report**, never as ordinary grammar.

---

## Conversion checklist (run top to bottom, then hand to 01 Step 10)

1. §1 → envelope + experience header, all three version fields stamped.
2. §2 → `personas[]`; every id kebab and stable.
3. §3 → one `workflowDefinitions` entry per row; **split each row with both litmus tests** into
   `states` (lifecycle) vs `instanceDataSchema`+`to:null` transitions (data); child-table any
   count/tally/audit list.
4. §6 → `cardSurfaceFamily` by **structural match** (check archetype Status); content → fields with
   distinct icons; derive all derivable values as formulas.
5. §7 → concrete `renderBindings` rows (workflow × role × tabId × surface); `primary` where they act,
   `summary` where they observe; omit bindings to hide states.
6. §8 → guards (six kinds, AND-ed, engine-enforced); role/kind for actor vs receiver.
7. §9 → `workflowInstances[]`; seed the states that prove each feature; **never seed a computed field**.
8. §10 → `displayIcon`/`tone`/`theme`; report any navigation/layout ask as App Shell scope.
9. Gap set → any GAP-1/2/3/4 or platform-service requirement is **written forward-looking, marked
   `NEEDS IMPLEMENTATION`, and reported** — never worked around.
10. Run [`04-antipatterns.md`](./04-antipatterns.md) self-check, then the mandatory validator gate
    ([`05-validation.md`](./05-validation.md)). A community that does not validate is not a deliverable.
