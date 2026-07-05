# Chess Club — Tabs, Cards, Actions (workflow-engine target design)

Source: `docs/Product Docs V2/Community Examples/chess-club-product-experience.md` (an arbitrary
local-package example — proves generated content renders as a real club home, not proof-only
metadata). Anti-patterns explicitly named: "package proof card only," "generic request without
opponent/time," "raw event row."

## Personas
| Persona   | Role                                 | Key constraint             |
| --------- | ------------------------------------ | -------------------------- |
| Organizer | actor on pairing/disputes/export     | —                          |
| Player    | actor on match-propose/result-report | no sensitive data expected |

## Tabs → Cards → Archetype → Actions

### Home (both) — `dashboard`
Explicit requirement: "player sees tonight ladder, pairings, and standings" — three heterogeneous
data types (next-event, pairing-list, leaderboard) on one screen; the clearest single-community proof
that Home must be a `dashboard` compositing mini-cards from other archetypes, not one archetype.

### Matches (both) — `formEntry` (propose) + `statusTimeline` (negotiate) + `calendarAgenda` (confirmed)
- **Match-meetup card**: propose opponent/time/place/board (`formEntry`) → opponent receives invite,
  accept/decline/reschedule/cancel/suggest-new-time (`statusTimeline`, two-party negotiation) → syncs
  to calendar/reminder on confirm (`calendarAgenda`). Per §3b: composed from existing archetypes via
  role/state-keyed `renderBindings` on one instance (proposer fills the `formEntry`; both parties
  watch the `statusTimeline` while unconfirmed; everyone sees the `calendarAgenda` event once
  confirmed) — not a new "negotiation" archetype.
- **Match result card** (`statusTimeline`, lightweight): players, round, score/result, correction/
  dispute path. On save, this instance's effect writes into the Rankings table below (cross-workflow
  effect, not a separate manual step).

### Calendar (both) — `calendarAgenda`
- **Club night/tournament card**: title, date/time, location, opponent/pairing, reminder — same
  archetype as Matches' confirmed state, tournament-pairing flavor.

### Rankings (player only) — `table` with `rankingMode`
- **Standings card**: rank/player/score/delta, live-updates when a match result is saved. Confirms
  §3b's decision to fold leaderboard into `table` + a ranking-emphasis flag rather than inventing a
  14th top-level archetype — this is still fundamentally rows+columns.

### Admin (organizer only) — `dashboard` (pairing queue, disputes) + `exportWizard`
- **Pairing queue card**: outstanding pairings needing assignment.
- **Result dispute card** (`statusTimeline`): same shape as match result, reviewer/dispute path.
- **Export package card** (`exportWizard`): same shape as every other community's export.

### Documents (organizer) — `documentLibrary`
- Club rules/policies — standard document library, nothing chess-specific about this one.

### Messages (both) — `discussionThread`

### Match result → Rankings (cross-workflow effect)
- **Match result form** (`formEntry`): players/round/score. On submit, its effect writes into the
  Rankings `table` (a cross-workflow effect, not a manual second step) — the clearest example of one
  workflow's `formEntry` mutating another archetype's data.

## Community-specific customizations (per archetype, per persona)

| Archetype                                | Community customization (theme/fields/states/copy)   | Player needs                                    | Organizer needs                              |
| ---------------------------------------- | ---------------------------------------------------- | ----------------------------------------------- | -------------------------------------------- |
| `dashboard` (Home)                       | Board/tournament visual language; composites 3 types | pins: next match, open challenge, latest result | pins: pairing queue, disputes, export        |
| `formEntry` (propose match)              | Fields opponent/time/place/board                     | propose a match                                 | —                                            |
| `statusTimeline` (negotiate)             | Two-party accept/decline/reschedule                  | respond to/negotiate invite                     | —                                            |
| `calendarAgenda` (confirmed/club nights) | Opponent/pairing on event; tournament flavor         | see schedule, reminders                         | create club nights/tournaments, set pairings |
| `formEntry` (result)                     | Score/result fields; feeds rankings on submit        | report result                                   | —                                            |
| `table` (+`rankingMode`) (standings)     | Rank/player/score/delta; live-update on result save  | view standings                                  | recompute/correct standings                  |
| `statusTimeline` (result dispute)        | Reviewer/dispute path                                | file dispute                                    | resolve dispute                              |
| `exportWizard`                           | Club records; scope/checksum                         | —                                               | run export package                           |
| `documentLibrary`                        | Club rules/policies                                  | read rules                                      | manage rules docs                            |

## Cross-cutting notes
- Chess Club is the only community with a genuine leaderboard/standings requirement, and the only
  one whose Home dashboard explicitly names three distinct composited data types in one sentence —
  both were used directly to settle two open §3b design questions (leaderboard: `table` variant, not
  new archetype; Home: confirmed as a `dashboard` meta-archetype, not guessed).
- The match-result → rankings cross-workflow effect is the clearest evidence that `formEntry`'s
  `effects` can write into *another* archetype's backing data — validating that the archetype set is
  interconnected via the shared engine, not a set of siloed surfaces.
