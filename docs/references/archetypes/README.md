---
spec: { envelope: 1, experience: 2, grammar: 2 }
doc_version: 1.5.0
status: current
last_verified: 2026-08-11
audience: llm-agent
---

# Archetypes — index and status

`cardSurfaceFamily` in a render binding names an **archetype** — the widget family that renders the
instance.

## AGENT: hard rules

1. **MUST NOT invent a `cardSurfaceFamily`.** Only the values in the two tables below exist — the 9 in
   "The archetypes" (implemented, enforced by the real validator today) plus the 4 in "Promoted archetypes
   — pending implementation" (locked into the target vocabulary 2026-08-11, but **not yet** in the Dart
   registry — see that section before using one). Community JSON declaring any of these 13 values is
   correct; anything outside this list is not, regardless of how plausible it looks.
   **Enforced by the real validator** as of the tabId-open/archetype-closed migration for the 9 implemented
   values: an unrecognized `cardSurfaceFamily` is a hard validation error (`unknown_card_surface_family`),
   not a warning. The 4 pending values will **currently** also trip this same error, until
   `TabId-Archetype Gap Closure.md` (see below) lands the registry addition — that's expected, not a bug,
   for any fixture using them before then.
2. **Check the Status column.** A `🟡 GENERIC` archetype below still renders correctly — live
   transitions, live queries, creation, guards all genuinely work — it is just the shared
   icon+pills+buttons template, not a bespoke widget shaped like its name.
3. **Read the honesty note below** before assuming any archetype "works" the way its name implies.
4. **STANDING RULE for whoever closes an archetype-related milestone:** updating this README's status
   table (and, once an archetype is BOTH rich AND generically reachable, writing its per-archetype doc)
   is part of that milestone's own definition of done. See
   [Loom_Communities_Workflow_Engine_3.md](../../Build%20Plan%20V2/Loom%20Communities%20Workflow%20Engine%20V3/Loom_Communities_Workflow_Engine_3.md) §5a.

## Status legend

| Status | Meaning |
|---|---|
| ✅ REAL | A genuinely distinct widget with the interactions its name implies, reached purely by declaring the `cardSurfaceFamily` in JSON — no hardcoded per-community wiring |
| 🟡 GENERIC | Reached purely by declaring the `cardSurfaceFamily` in JSON (no hardcoded wiring) — transitions/creation/live-query all genuinely work — but renders via the shared `GenericWorkflowInstanceCard` (icon + title + fact pills + buttons), not a distinct widget |
| 🔲 PENDING | **Locked into the canonical vocabulary, not yet in the Dart registry.** This is the intended, correct name for the interaction it describes — but it is not yet in `knownWorkflowArchetypeIds`, so it currently fails validation. Tracked in `TabId-Archetype Gap Closure.md`. |
| ❌ NOT REAL | Does not render or does not work as declared |

**Re-verified 2026-08-05 against Dart source at commit `743395e0`** (tracker 3 Phases B-G, all closed
except G.4/G.5), superseding the 2026-07-17 table below. Every claim in this table was checked by
grepping `EngineNativeArchetypeCard`'s dispatch switch and the actual widget files — not carried
forward from a prior doc claim.

## The dispatch mechanism (read this before the table)

`EngineNativeArchetypeCard.build()` (`part27_engine_native_binding_dispatcher.dart:322-436`) is the
**single** place `cardSurfaceFamily` is switched on. Three branches route to a bespoke widget; every
other value falls to the generic card:

```
case 'event-rsvp'     -> _EventRsvpDetailCard                (part28_engine_native_calendar_surface.dart:1427)
case 'votePoll'       -> VotePollArchetypeCard (repeater/tournament-event)  (part35_votepoll_archetype_card.dart)
case 'equipment-loan' -> EquipmentLoanArchetypeCard           (part36_engine_native_marketplace_surface.dart:369-693)
default                -> GenericWorkflowInstanceCard         (part26_generic_instance_card.dart)
```

`tabId` is open (not a closed enum) as of the tabId-open/archetype-closed migration — see
`render-bindings.md`'s `tabId — complete rule`. **Every real community, not just Tabletop Club, routes
entirely through `EngineNativeListSurface`/`EngineNativeBindingDispatcher`/`EngineNativeArchetypeCard`** —
confirmed by direct grep, zero occurrences of `rendererId` across all 11 real community fixtures. The old
hardcoded `'ballot'` tab and `_TournamentBallotTabSurface`/`_TournamentBallotEngineStore` were deleted
outright in Phase B.8 (not just bypassed). The other bespoke rendererId-keyed widgets the 2026-07-17 table
described (`FormEntryTabSurface`, `StatusTimelineTabSurface`, `NotificationInboxTabSurface`, the old
thread-detail code) are dead code for every real community, not load-bearing for any of them —
superseding this doc's prior claim that they remained load-bearing for "the other seven, still-shallow-
schema communities": that claim predated this session's Skill-authoring migration of all 10 communities to
real engine-native JSON (2026-08-09 vs. 2026-08-10/11). Slated for removal in a dedicated follow-on pass.

## The archetypes (Tabletop Club's 9, re-verified 2026-08-05)

| `cardSurfaceFamily` | Purpose | Status | Evidence |
|---|---|---|---|
| `event-rsvp` | Event with RSVP + capacity + waitlist, a container of cards scoped to a view (Day/Week/Month/Pending), organizer-creatable | ✅ REAL | Per-row `event-rsvp-response` table (one row/member/event) queried live (`part28...:806-844,809`); scoped Day/Week/Month/Pending views (`part28...:983-1002`); real "+ New event" creation via an `actions: [{"kind":"create", ...}]` entry on the renderBinding (`...jsonc:271-297`) — ⚠️ **not** a binding-level `creatable` key, which is dead grammar-1 vocabulary removed by grammar 2 (`CHANGELOG.md:17-21`) and silently dropped if used; see `workflow-grammar.md`'s render-binding shape and `render-bindings.md` for the real `actions[]` shape. The CAL.1-CAL.4 redesign — spec-only as of 2026-07-17 — is fully implemented, not just proposed. |
| `equipment-loan` | Browse/borrow/queue/return items | ✅ REAL | `EquipmentLoanArchetypeCard` (`part36...:369-693`): real borrow/join-queue/leave-queue/return/return-game/claim buttons driven by live `availableTransitionsAsync`, giveaway-vs-loan branching. Zero fallback to the generic template anywhere in the file (grepped). Flipped from 🟡 PARTIAL — Phase C built the missing per-item interaction. |
| `votePoll` | Ballot: candidates, tally, tie/runoff; also tournament-attendance summary | ✅ REAL | `VotePollArchetypeCard` (`part35_votepoll_archetype_card.dart`), dispatched purely by `cardSurfaceFamily`. The old hardcoded `'ballot'`-tab path this archetype used to require is **deleted** (Phase B.8) — confirmed zero references to `TournamentBallotTabSurface`/`'ballot'` remain in `part02_tab_shell.dart`/`part11_shell_models.dart`. |
| `paymentCheckout` | Dues/donations + receipt | 🟡 GENERIC | No dispatcher case → `GenericWorkflowInstanceCard`. Reached purely by `cardSurfaceFamily` (Phase D wired the Giving tab into the pipeline) — genuinely live, but the pay action itself is the shared template, not a bespoke widget. Phase D deliberately declined to build a fake receipt-ID platform service rather than fake the missing capability (`PhaseD_Giving.md`); a real ID-generation service remains a named, honest gap. |
| `approvalQueueItem` | A live queue of items awaiting decision | 🟡 GENERIC | No dispatcher case → `GenericWorkflowInstanceCard`. The queue mechanics are genuinely real: a live `queryInstances`-bound Repeater (a new proposal really appears with no polling/hacks), real Approve/Reject/Request-changes transitions (`PhaseE_Proposals.md`) — but no bespoke widget exists. |
| `formEntry` | Author/edit a record (typed controls) | 🟡 GENERIC | No dispatcher case → `GenericWorkflowInstanceCard`. The old bespoke checkbox/reminder-offset widget still exists but is dead code for Tabletop Club (diverted before the rendererId switch). |
| `discussionThread` | Threads + messages + compose | 🟡 GENERIC | No dispatcher case → `GenericWorkflowInstanceCard` + a new **generic** (not Messages-specific) structured-list renderer for the `messages` list-of-maps field. Phase F built real thread list, open/reply, mute/archive, unread tracking, and a "start new thread" creation action — all live-query/engine-backed — deliberately as generic infrastructure, not a bespoke `discussionThread` widget (`PhaseF_Messages.md:63`: "zero bespoke `discussionThread` widget"). |
| `statusTimeline` | Timestamped progression of an item | 🟡 GENERIC | No dispatcher case → `GenericWorkflowInstanceCard`. Old bespoke timeline widget is dead code for Tabletop Club (still live for other communities). |
| `notificationInbox` | List of notices, unread state | 🟡 GENERIC | No dispatcher case → `GenericWorkflowInstanceCard`. A bespoke `notificationInbox` widget was explicitly deferred as separate, larger, out-of-scope work (`PhaseB_Home.md:75`); only a small tweak so it shows full body in detail context. |

⚠️ **`event-rsvp` requires `instanceData` fields literally named `eventDate` and `eventTime` — not
illustrative names, hardcoded ones.** Found 2026-08-09: `EngineNativeCalendarSurface`
(`part28_engine_native_calendar_surface.dart:343,635,642`) reads `instanceData['eventDate']` and
`instanceData['eventTime']` by literal string key for the tile's displayed time label and its
day-position sort — not by any field marked `type: "date"`/`type: "time"` in `instanceDataSchema`, and not
configurable. A workflow bound to `tabId: "calendar"` with a differently-named time field (e.g.
`startTime`) validates cleanly and installs, but silently renders no time label and sorts to midnight
within its day. This is invisible in the validator and easy to miss when a workflow's own domain
vocabulary suggests a better field name — confirm the exact names `eventDate`/`eventTime` before shipping
any `event-rsvp`-bound workflow, regardless of what the data conceptually represents (a reservation start
time, a meeting time, etc.).

**All nine are now reached purely by declaring the `cardSurfaceFamily` in JSON — the "is it reachable
at all" axis that used to gate every one of these is fully resolved for Tabletop Club.** Only three
(`event-rsvp`, `equipment-loan`, `votePoll`) currently render a genuinely distinct bespoke widget; the
other six are 🟡 GENERIC — functionally real, visually/interactionally generic.

## Promoted archetypes — pending implementation (locked 2026-08-11)

Found while auditing the 7 non-Tabletop real communities for dropped/collapsed functionality after the
tabId-open/archetype-closed migration: several communities' real product interactions had no home in the
9-value registry above and were quietly rendering through a generic `formEntry`/`statusTimeline`
substitute. Per the standing rule (`Community JSON Migration Tracker.md`: "only ever EXPAND — never remove
a documented or implemented workflow/interaction"), these 4 are now locked into the canonical vocabulary.
**Registry + dispatch + widget work is tracked in
[`TabId-Archetype Gap Closure.md`](../../Build%20Plan%20V2/TabId-Archetype%20Gap%20Closure.md) — not done
yet.** Until that lands, community JSON declaring these values is *correct content, currently failing
validation* — expected, not a bug. **Community JSON is only ever authored by dispatching the
[`loom-calendar-experience-authoring`](../../../.agents/skills/loom-calendar-experience-authoring/SKILL.md)
Skill against the community's product doc — never hand-authored.** That Skill's own Scope section is the
authoritative statement of which of the 4 below it will actually use and how; this table is the status
summary, not authoring instructions.

| `cardSurfaceFamily` | Purpose | Status | Grammar needed | Real usage found in audit |
|---|---|---|---|---|
| `table` | Sortable/filterable grid — browsing many rows at scale (leaderboards, rosters), not a card-per-item list | 🔲 PENDING | None new — consumes existing `sortable`/`searchable`/`labelTemplate`/`displayIcon` `instanceDataSchema` flags every other archetype already reads. | Chess Club's ranking table, Riverside Youth Soccer's dropped team roster |
| `documentLibrary` | Categorized document browsing, version history, acknowledgement/access-request tracking | 🔲 PENDING | None new — consumes the `type: "url"` field (`field-types.md`, itself still ⚠️ PROPOSED/not-yet-implemented at the renderer level — this is a real prerequisite, not just a registry entry) | Cedar Commons HOA, Chess Club, Book Club, Youth Soccer, Masjid Nur document workflows |
| `searchAiAnswer` | Query + AI-generated or curated answer + cited sources | 🔲 PENDING, **plus a real platform-service gap** | None new — consumes the `citations[]` list shape (`field-types.md`'s "Citation lists", also ⚠️ PROPOSED). The *widget* is buildable now; the *AI-answer computation itself* is `❌ Not implemented` per `platform-services.md` ("External search / AI answer") and stays that way after this milestone. | Masjid Nur's search citation workflow, Book Club's AI digest workflow |
| `exportWizard` | Stepped export/transfer flow (scope → redact → generate → verify → download), with retry/rollback | 🔲 PENDING, **plus a real platform-service gap** | None new — the stepped flow is already a plain state machine in every real fixture. Checksum/integrity-hash and opaque-ID generation are `❌ Not implemented` platform services (`platform-services.md`) and stay that way after this milestone. | Data Portability Community's whole domain (5 workflows), plus one export workflow each in Chess Club, Garden Club, Book Club, Cedar Commons HOA, Youth Soccer |

**Considered and explicitly NOT promoted** (same audit, different verdict — recorded so this isn't
re-litigated per community):

| `cardSurfaceFamily` | Why not |
|---|---|
| `volunteerRoster` | The capacity meter (`capacity`/`signedUpCount`/`spotsRemaining`/`isFull`) already computes and displays correctly today via `formEntry` — live proof in Garden Club's and Masjid Nur's volunteer-shift workflows. A dedicated archetype would only give it a nicer layout, not new capability. |
| `singleItem` | Masjid Nur's donor-visibility workflow already implements its 3-way exclusive choice today as 3 real transitions/buttons. Cosmetic gap (a segmented control vs. 3 buttons), not functional. |
| `protectedDetail` | Field masking by viewer is already solved, generically, via a `formula` field (`platform-services.md`: `if($viewer==owner, full, masked)`) — proven live in Riverside Youth Soccer's minor-redaction workflow. The current `protectedDetail` widget isn't reusable anyway (a single hardcoded demo instance, not `renderBindings`-driven). A real archetype would only add a lock-icon visual treatment. |
| `guidedProcess` | No widget exists anywhere in the app shell (confirmed by direct grep, zero results) despite this doc's prior "✅ REAL" claim — that claim was wrong, carried forward unverified. Its one historical use case is already fully covered by a linear `statusTimeline` approval flow. |
| `dashboard` | Not a per-workflow card archetype at all — it's Home's own tab-level section ordering, mislabeled in a prior version of this table. Removed below rather than promoted. |

## Other archetypes still not real, not promoted

| `cardSurfaceFamily` | Purpose | Status |
|---|---|---|
| `audienceSelector` | Multi-select member picker | ❌ NOT REAL |

## ⚠️ Honesty note — read this

An earlier audit of all 17 archetypes found that 15 of 17 were the same generic card, reskinned. Tracker
3 has since closed every phase (A through G.3): 9 of 9 Tabletop Club archetypes are now genuinely
reachable purely by JSON declaration, and 3 of 9 (`event-rsvp`, `equipment-loan`, `votePoll`) render a
truly distinct, bespoke interaction. The other 6 are honestly labeled 🟡 GENERIC above — this is a
**deliberate scope decision made and documented in each phase's own closing doc** (Phases D/E/F each
explicitly chose to build the generic queue/list/creation infrastructure rather than a one-off bespoke
widget per workflow type, since that infrastructure is what Phase 3's Skill actually needs). It is not
an oversight and not silently dropped.

**Consequence for the agent:** declaring `cardSurfaceFamily: "volunteerRoster"` (❌ NOT REAL — not in the
canonical registry) now fails validation outright, in addition to never having produced a working
interaction. Declaring `cardSurfaceFamily: "paymentCheckout"`
(🟡 GENERIC) **does** get you a real, live, transition-capable card — just not a bespoke payment-shaped
one. Do not tell the user an interaction doesn't work when it does (🟡 GENERIC is still fully
functional), and do not tell the user a card is bespoke when it renders through the shared template.
Declaring one of the 4 🔲 PENDING values (`table`/`documentLibrary`/`searchAiAnswer`/`exportWizard`) is
**correct content that currently fails validation** — a third, distinct case from the two above. Don't
"fix" it by reverting to a generic archetype; the JSON is right, the Dart registry just hasn't caught up
yet (`TabId-Archetype Gap Closure.md`).

**Tabletop Club is now a finished reference community for the purposes of this rebuild** — every
archetype it declares is genuinely reachable from JSON with no hardcoded per-community wiring, which is
the bar Phase 3 (the Skill) actually needs. See
[Loom_Communities_Workflow_Engine_3.md](../../Build%20Plan%20V2/Loom%20Communities%20Workflow%20Engine%20V3/Loom_Communities_Workflow_Engine_3.md)'s
Phase G for the closing evidence (G.1-G.3 closed; G.4 is this documentation pass; G.5 is the pending
human sign-off).

`docs/CardSurfaces/` (all 26 files) remains superseded — every file invents a nonexistent
`CommunityXxxApi`. Nothing from it is promoted here.

Per-archetype JSON reference docs, now that generic reachability is confirmed live for all 9:
[`vote-poll.md`](./vote-poll.md), [`equipment-loan.md`](./equipment-loan.md),
[`payment-checkout.md`](./payment-checkout.md), [`approval-queue.md`](./approval-queue.md),
[`discussion-thread.md`](./discussion-thread.md). `calendar-agenda.md` remains **not yet written** —
Phase A's own responsibility, still pending its A.10 human review gate.

Until then, also use:
- [`guide/03-common-patterns.md`](../guide/03-common-patterns.md) — canonical templates (grammar-correct
  JSON; silent on which archetypes actually render richly today)
- [`communities/tabletop-club.md`](../communities/tabletop-club.md) — a full worked community
- **This README's status table above** — the current, honest source for what renders richly right now
- [`TabId-Archetype Gap Closure.md`](../../Build%20Plan%20V2/TabId-Archetype%20Gap%20Closure.md) — the
  implementation milestone for the 4 🔲 PENDING archetypes above, plus the cleanup milestone that updates
  every `NEEDS IMPLEMENTATION` comment in real community JSON once that implementation is verified (gated
  on explicit human approval — see that doc, do not run it unprompted)
