---
spec: 4
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

| Community | Product experience doc |
|---|---|
| Garden Club | [garden-club-product-experience.md](./garden-club-product-experience.md) |
| Camera Club | [camera-club-product-experience.md](./camera-club-product-experience.md) |
| Chess Club | [chess-club-product-experience.md](./chess-club-product-experience.md) |
| Book Club | [neighborhood-book-club-product-experience.md](./neighborhood-book-club-product-experience.md) |
| Youth Soccer | [riverside-youth-soccer-product-experience.md](./riverside-youth-soccer-product-experience.md) |
| Mosque | [masjid-nur-product-experience.md](./masjid-nur-product-experience.md) |
| HOA | [cedar-commons-hoa-product-experience.md](./cedar-commons-hoa-product-experience.md) |

These run today, but on **`experienceSchemaVersion: 1`** (the legacy shallow schema) with hand-written
Dart behind each feature. Their product-experience docs (moved here from
`docs/Product Docs V2/Community Examples/` — same content, relocated so every community's product doc
lives in one place) predate the engine-native grammar and describe the old shallow-schema card-surface
architecture (`CommunityEventRsvpApi`-style API contracts), not `workflowDefinitions`/`renderBindings`.

**The agent MUST NOT use them as authoring references** for the v2 grammar. Their JSON cannot express a
state machine, a guard, or a formula — copying their shape would produce a v1 community. They are
scheduled for migration to v2 via the Skill.

## Three more legacy communities (no JSON at all — pure hardcoded Dart)

| Community | Product experience doc |
|---|---|
| Member Social Space | [member-social-space-product-experience.md](./member-social-space-product-experience.md) |
| Ad-Free Community | [ad-free-community-product-experience.md](./ad-free-community-product-experience.md) |
| Data Portability Community | [data-portability-community-product-experience.md](./data-portability-community-product-experience.md) |

Moved here 2026-08-10 from `docs/Product Docs V2/Community Examples/` (filenames there were generic —
`ad-off-product-experience.md`, `export-and-migration-product-experience.md`,
`platform-social-product-experience.md` — see each doc's own "Evidence community name" row). Unlike the
seven above, these have **no JSON at all**, hardcoded/hand-authored in Dart with no `workflowDefinitions`.
Same warning applies: do not use them as v2 authoring references; scheduled for migration via the Skill.

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
