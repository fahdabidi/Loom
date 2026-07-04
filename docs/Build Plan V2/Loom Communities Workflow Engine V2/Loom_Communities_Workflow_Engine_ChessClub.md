# Chess Club — Tabs, Cards, Actions (workflow-engine target design)

Source: `docs/Product Docs V2/Community Examples/chess-club-product-experience.md` (an arbitrary
local-package example — proves generated content renders as a real club home, not proof-only
metadata). Anti-patterns explicitly named: "package proof card only," "generic request without
opponent/time," "raw event row."

## Personas
| Persona | Role | Key constraint |
| --- | --- | --- |
| Organizer | actor on pairing/disputes/export | — |
| Player | actor on match-propose/result-report | no sensitive data expected |

## Tabs → Cards → Archetype → Actions

### Home (both) — `dashboard`
Explicit requirement: "player sees tonight ladder, pairings, and standings" — three heterogeneous
data types (next-event, pairing-list, leaderboard) on one screen; the clearest single-community proof
that Home must be a `dashboard` compositing mini-cards from other archetypes, not one archetype.

### Matches (both) — `statusTimeline` (scheduling variant, composed with `calendarAgenda`)
- **Match-meetup card**: propose opponent/time/place/board → opponent receives invite → accept/
  decline/reschedule/cancel/suggest-new-time → syncs to calendar/reminder on confirm. Per §3b: this
  composes `calendarAgenda`'s event-detail shape with `statusTimeline`'s propose/respond/confirm
  sequence rather than being a new "negotiation" archetype — two `renderBindings` on one workflow
  instance (a `statusTimeline` binding while unconfirmed, a `calendarAgenda` binding once confirmed).
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

## Cross-cutting notes
- Chess Club is the only community with a genuine leaderboard/standings requirement, and the only
  one whose Home dashboard explicitly names three distinct composited data types in one sentence —
  both were used directly to settle two open §3b design questions (leaderboard: `table` variant, not
  new archetype; Home: confirmed as a `dashboard` meta-archetype, not guessed).
