# Computation Model — declarative formulas, extended effect ops, aggregate API, Repeater primitive

Part of [Loom_Communities_Workflow_Engine.md](./Loom_Communities_Workflow_Engine.md). Full design doc —
built first in Phase 1 ([Phase1_TabletopClub.md](./Loom_Communities_Workflow_Engine_Phase1_TabletopClub.md)
milestones 1.1-1.3), then reused without re-deriving it by every later phase, the same way V2's Phase 1
doc held the base engine design for its later phases.

## 0. Why this exists

The V2 effect model (`loom_workflow_engine/lib/src/evaluator/effect_evaluator.dart`) only supports
`set`/`appendUnique`/`append`/`removeValue`/`increment`/`decrement`, with `{field}`/`$actor`/
`$timestamp` interpolation on **values only, never dynamic keys**. It cannot express "tally votes by
candidate," "compute a max/tie across fields," "capacity minus filled," or "spawn a new instance." The
[Archetype Audit](./Loom_Communities_Workflow_Engine_Archetype_Audit.md) found every one of these
needs faked today — either in hand-written, per-community Dart (Chess Club's `_rankingsEffect`,
`part02_tab_shell.dart:6916-6918`) or by regex-parsing a display string
(`_goingCountFromLabel`/`_isCapacityFull`, `part02_tab_shell.dart:2439-2458`).

This matters beyond Phase 1: [Phase 3's Skill](./Loom_Communities_Workflow_Engine_Phase3_Skill.md)
promises to rebuild every community from JSON alone, **writing no code**. If computed effects stay
per-community Dart, that promise is false the first time a community needs a ballot. So the fix has to
be a way to express computation *in the JSON itself* — not a registry of named Dart functions the
Skill merely calls (that framing was considered and rejected during planning: it still keeps the actual
logic in Dart, so a genuinely new computation still needs a code change).

**Hard constraints** (set explicitly during planning, not engineering taste): (1) easy for the Skill
(an LLM) to author, (2) well-understood syntax, (3) references only the workflow's own
declared/visible fields — no parameter lists, (4) no author-written loops, (5) each formula well under
50 lines. Together these describe a **spreadsheet formula / SQL computed-column** model: a field
references only other named fields, no argument list, no loop, one line, and it is about the most
well-understood computation syntax that exists.

## 1. Computed fields (pure formulas)

A field in `instanceDataSchema` may carry a `formula` — a one-line expression in spreadsheet/SQL
syntax that references only *other declared fields of the same workflow by name* (plus `$viewer`/
`$actor`, resolved the same way effect interpolation already resolves them) and re-evaluates reactively
when its inputs change. No loop ever appears in a formula; all iteration is hidden inside a small fixed
vocabulary of engine-provided aggregate functions — exactly as `SUM()`/`COUNT()`/`MAX()` iterate inside
a spreadsheet while the author never writes a loop.

```jsonc
"instanceDataSchema": {
  "ballots":        { "type": "list",   "source":  "query(vote-ballot where voteId == id)" },
  "voteCounts":     { "type": "map",    "formula": "groupCount(ballots, choice)" },
  "winner":         { "type": "string", "formula": "argMaxKey(voteCounts)" },
  "tiedCandidates": { "type": "list",   "formula": "topKeys(voteCounts)" },
  "isTie":          { "type": "bool",   "formula": "size(tiedCandidates) > 1" }
}
```

Field-masking and audience resolution are also pure formulas, not code, once `$viewer` is available:
`if($viewer == owner || contains(assignedTo, $viewer), full, masked)`.

## 2. Extended effect ops (side effects)

Pure formulas can't create instances or write another workflow. Transition `effects` gain two ops
beyond today's `set`/`appendUnique`/`append`/`removeValue`/`increment`/`decrement`: `createInstance`
(spawn a new instance) and cross-instance `set` (write a field on a related instance), plus a `branch`
op to choose between effect lists. No new looping.

```jsonc
// close-vote transition effects:
[ { "op": "branch", "if": "isTie",
    "then": [ { "op": "createInstance", "workflowType": "vote",
                "fields": { "candidates": "tiedCandidates", "round": "runoff" } },
              { "op": "set", "field": "status", "value": "runoff" } ],
    "else": [ { "op": "set", "field": "status", "value": "closed" },
              { "op": "set", "relatedInstance": "tournamentId",
                "field": "selectedGame", "value": "winner" } ] } ]
```

The engine implements the interpreter for each aggregate function and each op kind **once** — that
fixed instruction set is the only Dart, exactly like `set`/`increment` are today; the Skill only ever
*composes* formulas and effect ops, never writes a body. Safety boundary preserved: every field
reference resolves against the declared `instanceDataSchema` (validator-checked), values interpolate
but keys never do, nothing outside the fixed grammar is ever evaluated.

This generalizes Chess Club's `_rankingsEffect` precedent (`part02_tab_shell.dart:6916-6918`), which
becomes `rankings = sortByDesc(players, score)` + a rank/delta formula rather than a hand-written
wrapper.

## 3. Read-side aggregate API (display-only stats)

The same aggregate vocabulary is also exposed as a read API —
`WorkflowEngineApi.aggregate({ collection, column, op, filter, groupBy })` returning a scalar or, with
`groupBy`, rows — so the UI can bind a displayed value (a header stat, a running total, a max, a
per-option tally) directly to `sum`/`avg`/`min`/`max`/`count`/`countDistinct` over a column, with no
stored computed field needed. A real backend implements it as `SELECT SUM(col) FROM … WHERE …`
(literally); the demo's `LocalWorkflowEngineApi` computes the same reduce in-memory over loaded
instances (genuinely real, not a stub). The UI never loops to total a column — it asks the API. The
Skill selects the column + op in JSON on the archetype's `renderBindings` entry
(`{ "stat": "avg", "column": "price", "over": "listings" }`); it writes no code. Both façades — the
computed-field `formula` in §1 and this read API — hit the same engine reducers, so there is exactly
one implementation of each aggregate.

**Grouped form** covers per-option tallies directly (SQL `SELECT choice, count(*) FROM ballots GROUP
BY choice`), returning rows a Repeater (§5) renders directly — equivalent to the `groupCount` formula
in §1, same reducer either way.

**Gating vs. display.** A threshold that only needs to be *shown* (progress like `accepted /
minimumAttendance`) is a scalar read + a comparison in the label. A threshold that must *gate an
action* (e.g. "Close vote" disabled until quorum) cannot be gated by a displayed number — it must be a
computed `bool` field (`isQuorumMet = count(ballots) >= minimumVotes`) that the transition **guard**
reads. So transition `guard`s may reference same-instance computed fields — a strictly simpler
capability than the cross-instance eligibility guard in §6, reusable everywhere a threshold gates
progress (quorum, capacity-full, deadline-passed).

## 4. Complete computation vocabulary — grounded in every community's interactions

Swept the current engine stores (what math is computed today) *and* all seven community design docs
(what the interactions call for), so this vocabulary is complete, not voting-driven:

| Category | Ops | Exposed as | Motivating interactions (community) |
|---|---|---|---|
| Scalar aggregates | `count`, `sum`, `avg`, `min`, `max`, `countDistinct` | formula + read API | Giving total-raised & donor count; marketplace avg-price; chess top-score; Mosque donation totals |
| Grouped aggregate | `groupBy` + count/sum (SQL `GROUP BY`) | formula + read API | per-option vote tally (Book/Tabletop); Mosque donation totals per fund; HOA "who's paid" ledger by status |
| Arithmetic | `+ − × ÷` over fields/aggregates | formula | `remaining = capacity − filled` (Mosque roster, all RSVP); `progress = raised ÷ goal` (Giving); `winRate = wins ÷ (wins+losses)` (Chess/Soccer); `score = current + delta` (Chess) |
| Ratio / percentage | `x ÷ y`, formatted via `{field}` interpolation (no new primitive) | formula + display | funding % (Giving); seats-filled % (all calendar); win % (Chess) |
| Ranking / ordering | `sortBy(list, col, asc\|desc)`, `rank`/position, `topN` | formula | standings rank + delta (Chess); leaderboards; `argMaxKey`/`topKeys` are the degenerate top-1 case |
| Membership / position | `size`, `contains`→bool, `indexOf`→position | formula + guard | queue position "you are #3" (marketplace/lending); RSVP eligibility; "am I going?" |
| Comparison → bool | `>= > == < <=`, `if(cond, a, b)` | formula + guard | `isFull` / `isQuorumMet` / `isReady` gates; status derivation |
| Date / time | `now`, `daysBetween`/`daysUntil`, `isBefore`/`isAfter`/`isPast` | formula + guard + schedule API | ballot deadline countdown + "about-to-expire" (Book/Tabletop); event countdown; dues due/overdue (HOA); lending overdue (Book/Garden); powers `dueNotifications({asOf})` (§6) |

Two categories are net-new engine primitives that the audit found **faked in ad-hoc Dart today** and
must become real: **scalar arithmetic** (inline everywhere) and **date/time functions** (today faked by
regex-parsing label strings — `_goingCountFromLabel`/`_isCapacityFull`). Everything else is either
already scoped (aggregates, `groupBy`, `if`, `argMax`) or a thin generalization (sort/rank, `indexOf`).
None introduces loops; all are standard spreadsheet/SQL semantics the Skill already writes fluently.

## 5. Data-bound Repeater primitive (UI cardinality)

Solves the second half of the gap: buttons/rows whose *count* varies with data, not with code (one
"Vote for {candidate}" button per candidate, a variable-length grid, a growing notification list).
Checked how Oracle's Redwood/JET design system solves this: `oj-list-view`/`oj-table` never hardcode a
row count — they bind to a `DataProvider` abstraction (`fetchFirst`, sort, filter over an
arbitrary-length collection) plus a row/item template, and wire select+action generically per row
regardless of how many rows exist
([Oracle JET DataProvider docs](https://docs.oracle.com/en/middleware/developer-tools/jet/10/develop/work-collections.html);
[Redwood Collection Details pattern](https://redwood.oracle.com/?pageId=CORE65754EBA7C424CAD818A44400E8F089B&shell=guideline)).

Our equivalent: a `repeater` config block on an archetype's `renderBindings` entry declaring —
- **source**: either a static array-valued instance field (e.g. `candidates`) or a live filter
  (`workflowType` + field-match) passed straight to the engine's existing `queryInstances`;
- **item template**: which instance/array-element fields map to title/subtitle/icon/image slots,
  reusing `{field}` interpolation;
- **per-item actions**: either the existing `availableTransitions`-per-instance pattern (now applied to
  each repeated item, not just one focused instance) or an extended effect op from §2 (e.g.
  `createInstance` casting a ballot for `{candidate}`).

One generic, community-agnostic `_RepeaterSurface` widget renders all of this, parametrized entirely by
JSON — not rebuilt per archetype or per community. This is the shared foundation for: ballot candidate
buttons, the marketplace grid, volunteer roster shifts, notification inbox rows, discussion thread
messages/threads, audience/multi-select member pickers, and calendar day-cell event lists.

## 6. Live/query-bound lists ("streaming" UI growth)

Notifications, chat messages, threads, and events should appear as new list entries the moment they're
created, not require a UI rebuild — a production-app-standard pattern the audit found nowhere in this
codebase. Falls out of §2+§5 together, no separate mechanism needed: bind a Repeater's source to a live
`queryInstances` filter instead of a static field, and make instance *creation* go through §2's
`createInstance` effect op instead of ad hoc Dart. Once both are true, a newly created instance simply
satisfies the query on the next read and the query-bound Repeater renders it as a new row/card/bubble
automatically.

**Platform-level scheduling piece** (referenced by Phase 1's Tournament+Voting feature): a real API
concept, `WorkflowEngineApi.dueNotifications({required DateTime asOf})`, that a real backend would
implement by checking genuine schedule state — the demo's `LocalWorkflowEngineApi` returns
pre-seeded canned "due" instances rather than actually watching a clock. Firing a due notification is a
`createInstance` effect op (§2), so it renders through the same query-bound Repeater as everything else
— no bespoke "new item arrived" UI code anywhere.

## 7. Cross-instance eligibility guard

The other platform-level extension Phase 1's Tournament+Voting feature needs: extending
`WorkflowTransition.guard` to express "actor must appear in `<field>` on the instance identified by
`<relationship>`" (e.g. "only people who RSVP'd going on the tournament may vote"), evaluated for real
by `LocalWorkflowEngineApi.availableTransitions`/`applyTransition` — not an app-layer-only filter, since
this is genuinely reusable (any community with RSVP-gated actions needs it).

## 8. With this vocabulary, is any per-community custom logic still needed?

Swept every community's interactions against §1-§7. **For data math, no per-community custom logic
remains**: tallies, totals, remaining/progress, standings/rank, queue position, thresholds, deadlines,
winner/tie/runoff, redaction-by-viewer, and audience resolution are all formulas + effect ops + guards.

What *cannot* be a field formula — because it isn't math over fields — is a small, closed,
**community-agnostic** set of platform services: real engine APIs, implemented once, demo-stubbed with
canned data, referenced from JSON by name. This is deliberately **not** the rejected named-function
registry (that was rejected for *data computation*, which now lives in formulas) — these are genuinely
*external/opaque* operations (you cannot express "charge the card" or "hash the records" as a formula):

| Platform service | Why it can't be a formula | Archetype / community | Demo behavior |
|---|---|---|---|
| Scheduled notifications (`dueNotifications({asOf})`) | needs a clock/scheduler | notificationInbox (all) | canned "due" instances (§6) |
| Cross-instance eligibility guard | needs another instance's state | votePoll eligibility (Tabletop) | real evaluation (§7) |
| External search / AI answer | calls an external index/LLM | searchAiAnswer (Book, Mosque) | canned answer for seeded queries |
| Payment processing | calls a payment gateway | paymentCheckout (HOA, Mosque, Youth Soccer) | canned success + generated receipt |
| Checksum / integrity hash | a hash, not arithmetic | exportWizard (Chess/Garden/Book/Soccer) | real in-memory hash of the records |
| ID generation | opaque unique id, not a field value | receipts, export ids | real UUID / monotonic id |

Two math functions sit on the boundary and are needed **only if** a community ever wants a richer
behavior than today's fixtures: `pow`/`exp` (true Elo expected-score vs. Chess's current fixed ±16) and
a Swiss-pairing generator (vs. Chess's current manual pairing queue). Both, if ever wanted, are one-time
community-agnostic engine primitives referenced from JSON — neither is needed for current interactions.

**Bottom line for Phase 3:** the Skill writes JSON that composes the computation vocabulary (§1-§5) and
references this fixed service list — and writes no function body of either kind. Once Phase 1/2 finish
the vocabulary plus this closed service set, no remaining seam forces a community to add code.

## 9. Worked proof — the full voting lifecycle

| Voting need | Expressed as | Loops? Params? |
|---|---|---|
| Live tally per candidate | `voteCounts = groupCount(ballots, choice)` (computed field) | none / none |
| Winner | `winner = argMaxKey(voteCounts)` | none / none |
| Tie detection | `tiedCandidates = topKeys(voteCounts)`, `isTie = size(tiedCandidates) > 1` | none / none |
| Quorum / attendance | `isReady = size(goingPersonaIds) >= minimumAttendance` | none / none |
| Cast / change a vote | transition effect `createInstance`/update on the voter's own ballot | none / none |
| Close → runoff **or** winner | effect `branch: if isTie → createInstance(runoff) else set winner` | none / none |
| Propagate result | effect cross-instance `set tournament.selectedGame = winner` | none / none |
| Total votes cast | scalar read, `aggregate(ballots, *, count)` | none / none |
| Per-option live tally (display) | grouped read, `aggregate(ballots, choice, count, groupBy: choice)` | none / none |

Five one-line formulas + one branch effect + two read-API calls. **Every voting need is covered** —
creation, live counting, final display, tie→runoff, and ending the vote — with room to spare under the
50-line constraint.

**The one precise reading required**: constraint (4) in §0 ("no loops") means *no author-written
loops* — iteration lives only inside the fixed aggregate vocabulary, the same way `SUM()` iterates
inside a spreadsheet while the author never writes a loop. If a future community ever needs an
aggregate this vocabulary lacks, that is a one-time **engine** addition of a new named aggregate (with
its own test), still never per-community code.
