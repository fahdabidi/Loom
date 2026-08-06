---
spec: { envelope: 1, experience: 2, grammar: 2 }
doc_version: 1.0.0
status: current
last_verified: 2026-08-05
audience: llm-agent
derived_from:
  - app/packages/core/loom_communities_app_shell/lib/src/part35_votepoll_archetype_card.dart
  - app/packages/core/loom_communities_app_shell/lib/src/part27_engine_native_binding_dispatcher.dart
---

# `votePoll` — ballot with tally, tie, and runoff

`cardSurfaceFamily: "votePoll"` is a genuinely distinct, bespoke widget
(`VotePollArchetypeCard`), reached purely by declaring the family in a
`renderBindings` entry — no per-community wiring required. See
[archetypes/README.md](./README.md) for the dispatch mechanism and the honesty
axis every archetype is judged on.

## What it renders

Two shapes, both driven by the same widget:

1. **Candidate ballot** (repeater-backed instance data) — per-candidate vote
   buttons, a live tally, a tap-to-open candidate detail dialog, and (once the
   guard closes) a tie/runoff resolution banner.
2. **Tournament attendance summary** — when the workflow type is
   `tournament-event` rather than a candidate list, the same
   `cardSurfaceFamily` renders a quorum/attendance summary instead. The
   dispatcher branches on the presence of a repeater-shaped candidate source
   vs. a `tournament-event` type, not on a second family name.

## JSON shape

```jsonc
{
  "states": ["open"], "role": "any", "tabId": "home",
  "cardSurfaceFamily": "votePoll", "bindingKind": "primary",
  "creatable": [
    { "kind": "create", "label": "New tournament",
      "byPersonaIds": ["tabletop-organizer"], "scope": "tab", "presentation": "fab" },
    { "kind": "create", "workflowType": "tournament-ballot", "...": "..." }
  ]
}
```

A closed-state `summary` binding (`"states": ["closed"] ... "bindingKind": "summary"`)
renders the same family in a condensed, non-interactive form — declare it
alongside the `primary` binding so the card degrades correctly once voting
closes.

## Tally, tie, and runoff

The tally/winner/runoff logic is **engine-evaluated formula state**, not
widget logic: `groupCount`/`argMaxKey`/`topKeys`/`isTie` operate over the
candidate instances' vote counts. A real runoff is created via a `branch`
transition effect + `createInstance` when `isTie` is true — the widget only
renders whatever state the engine already resolved. See
[ComputationModel.md](../../Build%20Plan%20V2/Loom%20Communities%20Workflow%20Engine%20V3/Loom_Communities_Workflow_Engine_ComputationModel.md)
for the formula vocabulary.

## Cross-instance eligibility

A voter's eligibility to vote a second time (or vote in a runoff) is a
cross-instance guard, not client-side state — declare it as a guard
expression referencing the sibling ballot instance, evaluated by the real
engine at transition time, not assumed by the UI.

## Known gap

Ballot/tournament **creation** is still seed-driven in Tabletop Club's
frozen JSON, not a real organizer-facing creation form beyond the
`creatable` binding shown above. Tracked open in
[Phase1_TabletopClub.md](../../Build%20Plan%20V2/Loom%20Communities%20Workflow%20Engine%20V3/Loom_Communities_Workflow_Engine_Phase1_TabletopClub.md),
judged lower priority than the capability gaps this archetype was built to
close.

## History

The hardcoded `'ballot'`-tab, `rendererId`-switch path this archetype used to
require (`_TournamentBallotTabSurface`/`_TournamentBallotEngineStore`) was
deleted outright — not just bypassed — in tracker 3 Phase B.8. What renders
today is exclusively the generic `cardSurfaceFamily` dispatch.
