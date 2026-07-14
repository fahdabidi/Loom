---
spec: { envelope: 1, experience: 2, grammar: 1 }
doc_version: 1.0.0
status: current
last_verified: 2026-07-14
audience: llm-agent
---

# Reference communities

Worked examples to pattern-match against.

## ⚠️ ALL REFERENCE COMMUNITIES ARE CURRENTLY UNVETTED

**No community in this list has been loaded and run by the app at `experienceSchemaVersion: 2`.** The
pipeline that loads engine-native JSON is under construction (tracker 3, Phase A).

**Consequence for the agent:**
- These are **structurally** correct — written against the engine's real grammar, and (once the
  validator lands) validated against it.
- They are **not behaviourally proven** — nobody has watched them run.
- Pattern-match on their **shape**. Do not assume every interaction works end-to-end.

## The communities

| Community | JSON | Status | Covers |
|---|---|---|---|
| **Tabletop Club** | [`Loom_Communities_Workflow_Engine_Phase1_TabletopClub_Example.jsonc`](../../Build%20Plan%20V2/Loom%20Communities%20Workflow%20Engine%20V3/Loom_Communities_Workflow_Engine_Phase1_TabletopClub_Example.jsonc) | 🔨 **UNVETTED** — the reference build, in progress | Every capability: RSVP, ballot (cross-instance guard, tally, tie→runoff), loan lifecycle, dues, proposals, threads |

**Notes:** [tabletop-club.md](./tabletop-club.md)

## The seven legacy communities

Garden Club · Camera Club · Chess Club · Book Club · Youth Soccer · Mosque · HOA

These run today, but on **`experienceSchemaVersion: 1`** (the legacy shallow schema) with hand-written
Dart behind each feature.

**The agent MUST NOT use them as authoring references.** Their JSON cannot express a state machine, a
guard, or a formula — copying their shape would produce a v1 community. They are scheduled for migration
to v2 via the Skill.

## Why Tabletop Club is the reference

It was deliberately built to exercise **every** capability in the grammar, including the ones nothing
else uses:

| Capability | Where it appears in Tabletop Club |
|---|---|
| Formula-computed capacity/attendance | `event-rsvp`, `tournament-event` |
| Cross-instance eligibility guard | Only RSVP'd attendees may vote in the ballot |
| Computed tally / winner / tie | `groupCount` → `argMaxKey` → `topKeys` → `isTie` |
| `branch` + `createInstance` | A tie spawns a **real runoff ballot** |
| Cross-instance `set` | The ballot writes the winner onto the **event** |
| Cross-workflow guard | Cannot borrow from the library until **dues are paid** |
| Orthogonal state (data, not states) | Loan availability + queue |
| One workflow, two tabs, two roles | Proposals: author on Home, organizer in Admin |
| Live query-bound list | The organizer's pending-proposal queue |

If you need to see how a capability is expressed, look there first.
