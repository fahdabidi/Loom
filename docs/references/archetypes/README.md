---
spec: 4
doc_version: 1.6.0
status: current
last_verified: 2026-08-12
audience: llm-agent
---

# Archetypes — index and status

`cardSurfaceFamily` in a render binding names an **archetype** — the widget family that renders the
instance.

## AGENT: hard rules

1. **MUST NOT invent a `cardSurfaceFamily`.** Only the 13 values in "The archetypes" table below exist —
   all 13, including the 4 promoted 2026-08-11 (`table`/`documentLibrary`/`searchAiAnswer`/`exportWizard`),
   are now real, registered, and enforced by the validator (`TabId-Archetype Gap Closure.md`'s Milestone 1
   closed 2026-08-12 — see "Promoted archetypes" below for the full per-archetype evidence). Community JSON
   declaring any of these 13 values is correct; anything outside this list is not, regardless of how
   plausible it looks.
   **Enforced by the real validator**: an unrecognized `cardSurfaceFamily` is a hard validation error
   (`unknown_card_surface_family`), not a warning.
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

> **This bespoke-vs-generic split is also what decides how permissions are derived.** A family with a
> dispatcher case has a **closed action vocabulary** and its transitions must declare `action`; a family
> that falls through to the generic card has an **open** one, declares no `action`, and derives its
> permissions structurally instead. See [`reference/permissions.md`](../reference/permissions.md) —
> which is also why community JSON never contains a permission.

`EngineNativeArchetypeCard.build()` (`part27_engine_native_binding_dispatcher.dart`) is the **single**
per-instance dispatch point `cardSurfaceFamily` is switched on. Six branches route to a bespoke widget;
every other value falls to the generic card:

```
case 'event-rsvp'       -> _EventRsvpDetailCard                (part28_engine_native_calendar_surface.dart:1427)
case 'votePoll'         -> VotePollArchetypeCard (repeater/tournament-event)  (part35_votepoll_archetype_card.dart)
case 'equipment-loan'   -> EquipmentLoanArchetypeCard           (part36_engine_native_marketplace_surface.dart)
case 'documentLibrary'  -> DocumentLibraryArchetypeCard         (part36_engine_native_marketplace_surface.dart)
case 'searchAiAnswer'   -> SearchAiAnswerArchetypeCard          (part36_engine_native_marketplace_surface.dart)
case 'exportWizard'     -> ExportWizardArchetypeCard            (part36_engine_native_marketplace_surface.dart)
default                  -> GenericWorkflowInstanceCard         (part26_generic_instance_card.dart)
```

**`table` is the one exception — it does NOT go through this per-instance switch at all.** Confirmed by
direct read (`TabId-Archetype Gap Closure.md`'s Milestone 1 architectural finding, 2026-08-12): a
`table`-family row is one *workflow instance* per row, not one instance holding an array, so a bespoke
widget needs every instance sharing a binding at once — something `EngineNativeArchetypeCard.build()`
structurally cannot see, since it only ever receives one resolved binding at a time. The real dispatch
point is one level up: `EngineNativeListSurface.build()`'s `builder` callback
(`part32_engine_native_list_surface.dart`), which partitions the full binding list for a tab by
`(tabId, workflowType)`, grouping every `cardSurfaceFamily: "table"` binding into one
`WorkflowTableArchetypeCard` grid instead of N separate cards — non-`table` bindings keep the ordinary
per-item path unchanged. Both real usages (Chess Club's ranking table, Riverside Youth Soccer's team
roster) route exclusively through this surface, not the calendar or marketplace surfaces.

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

## The archetypes (all 13, re-verified 2026-08-12)

Tabletop Club's original 9, re-verified 2026-08-05, plus the 4 promoted 2026-08-11 and closed out
2026-08-12 (full per-archetype implementation account in "Promoted archetypes" below — this table is the
current-status summary, that section is the historical record of how each got there).

| `cardSurfaceFamily` | Purpose | Status | Evidence |
|---|---|---|---|
| `event-rsvp` | Event with RSVP + capacity + waitlist, a container of cards scoped to a view (Day/Week/Month/Pending), organizer-creatable | ✅ REAL | Per-row `event-rsvp-response` table (one row/member/event) queried live (`part28...:806-844,809`); scoped Day/Week/Month/Pending views (`part28...:983-1002`); real "+ New event" creation via an `actions: [{"kind":"create", ...}]` entry on the renderBinding (`...jsonc:271-297`) — ⚠️ **not** a binding-level `creatable` key, which is dead grammar-1 vocabulary removed by grammar 2 (`CHANGELOG.md:17-21`) and silently dropped if used; see `workflow-grammar.md`'s render-binding shape and `render-bindings.md` for the real `actions[]` shape. The CAL.1-CAL.4 redesign — spec-only as of 2026-07-17 — is fully implemented, not just proposed. |
| `equipment-loan` | Browse/borrow/queue/return items | ✅ REAL | `EquipmentLoanArchetypeCard` (`part36...:369-693`): real borrow/join-queue/leave-queue/return/return-game/claim buttons driven by live `availableTransitionsAsync`, giveaway-vs-loan branching. Zero fallback to the generic template anywhere in the file (grepped). Flipped from 🟡 PARTIAL — Phase C built the missing per-item interaction. |
| `votePoll` | Ballot: candidates, tally, tie/runoff; also tournament-attendance summary | ✅ REAL | `VotePollArchetypeCard` (`part35_votepoll_archetype_card.dart`), dispatched purely by `cardSurfaceFamily`. The old hardcoded `'ballot'`-tab path this archetype used to require is **deleted** (Phase B.8) — confirmed zero references to `TournamentBallotTabSurface`/`'ballot'` remain in `part02_tab_shell.dart`/`part11_shell_models.dart`. |
| `table` | Sortable/filterable grid — browsing many rows at scale (leaderboards, rosters) | ✅ REAL | `WorkflowTableArchetypeCard` (`part32_engine_native_list_surface.dart`) — a real sortable/filterable `DataTable`, dispatched at the list-surface level (see "The dispatch mechanism" above for why this one is structurally different from the others). Real sort-cycle, search across `searchable` fields, row-tap-to-detail. Confirmed against both real fixtures (Chess Club's ranking table, Riverside Youth Soccer's team roster). |
| `documentLibrary` | Categorized document browsing, version history, acknowledgement/access-request tracking | ✅ REAL | `DocumentLibraryArchetypeCard` (`part36_engine_native_marketplace_surface.dart`). Real `openMode: "choice"` rendering (embedded viewer via `webview_flutter` + external via `url_launcher`, both reachable) in the shared field renderer (`part18_marketplace_rendering.dart`). Every one of the 7 `*PersonaIds` engagement affordances (open/acknowledge/mark-unread/request-access/save/download/follow-up) renders only when both its transition and its backing field are actually declared — real communities declare different subsets. |
| `searchAiAnswer` | Query + AI-generated or curated answer + cited sources | ✅ REAL, **the answer computation itself is a real, separate platform-service gap** | `SearchAiAnswerArchetypeCard` (`part36...`). Resolves the real answer-field-naming divergence found across real communities (Masjid Nur's `displayAnswer` formula field vs. Book Club's `curatedSummary`) via a formula-first-then-writable-priority heuristic — `query`/`citations` bind by consistent literal name, the answer text never does. The *AI-answer computation itself* remains `❌ Not implemented` per `platform-services.md` ("External search / AI answer") — the widget renders correctly against a perpetually-empty answer field, never fabricates one. |
| `exportWizard` | Stepped export/transfer flow (scope → redact → generate → verify → download), with retry/rollback | ✅ REAL, **checksum/transfer-ID generation remain a real, separate platform-service gap** | `ExportWizardArchetypeCard` (`part36...`). Core progress display derives from the workflow's own generic `currentState`/`states` data, never a named business field (real fixtures diverge on those: `exportScope`/`statusMessage` vs. `scope`/`exportStatus`) — correctly distinguishes real side-exit states (`failed`/`rolled-back`/`cancelled`) from the happy path. Checksum/integrity-hash and opaque-ID generation remain `❌ Not implemented` platform services; the widget renders correctly with those fields perpetually unset. |
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

**All 13 are now reached purely by declaring the `cardSurfaceFamily` in JSON — the "is it reachable at
all" axis is fully resolved for every one of these.** Seven (`event-rsvp`, `equipment-loan`, `votePoll`,
`table`, `documentLibrary`, `searchAiAnswer`, `exportWizard`) render a genuinely distinct bespoke widget;
the other six are 🟡 GENERIC — functionally real, visually/interactionally generic.

## Promoted archetypes — closed 2026-08-12 (locked 2026-08-11)

Found while auditing the 7 non-Tabletop real communities for dropped/collapsed functionality after the
tabId-open/archetype-closed migration: several communities' real product interactions had no home in the
9-value registry above and were quietly rendering through a generic `formEntry`/`statusTimeline`
substitute. Per the standing rule (`Community JSON Migration Tracker.md`: "only ever EXPAND — never remove
a documented or implemented workflow/interaction"), these 4 were locked into the canonical vocabulary
2026-08-11 and are now, as of 2026-08-12, fully implemented — registry, dispatch, and a real bespoke
widget each. Full account: **[`TabId-Archetype Gap Closure.md`](../../Build%20Plan%20V2/TabId-Archetype%20Gap%20Closure.md)
Milestones 1 and 1.5, both closed.** This section is kept as the historical record of the promotion
decision and evidence; current status lives in "The archetypes" table above.

| `cardSurfaceFamily` | Purpose | Status | Implementation | Real usage found in audit |
|---|---|---|---|---|
| `table` | Sortable/filterable grid — browsing many rows at scale (leaderboards, rosters), not a card-per-item list | ✅ REAL | `WorkflowTableArchetypeCard`, consuming existing `sortable`/`searchable`/`labelTemplate`/`displayIcon` `instanceDataSchema` flags every other archetype already reads — no new JSON grammar needed. | Chess Club's ranking table, Riverside Youth Soccer's restored team roster |
| `documentLibrary` | Categorized document browsing, version history, acknowledgement/access-request tracking | ✅ REAL | `DocumentLibraryArchetypeCard` + real `openMode: "choice"` rendering (`field-types.md`) — `external` mode was already real, `choice` (what every real fixture's primary document field actually declares) is the piece this milestone built. | Cedar Commons HOA, Chess Club, Book Club, Youth Soccer, Masjid Nur document workflows |
| `searchAiAnswer` | Query + AI-generated or curated answer + cited sources | ✅ REAL, **the answer computation itself remains a real platform-service gap** | `SearchAiAnswerArchetypeCard`, consuming the real `citations[]` list shape (`field-types.md`'s "Citation lists"). The *widget* is real; the *AI-answer computation itself* stays `❌ Not implemented` per `platform-services.md` ("External search / AI answer") — unchanged, by design. | Masjid Nur's search citation workflow, Book Club's AI digest workflow |
| `exportWizard` | Stepped export/transfer flow (scope → redact → generate → verify → download), with retry/rollback | ✅ REAL, **checksum/transfer-ID generation remain a real platform-service gap** | `ExportWizardArchetypeCard`, driving progress off the workflow's own state machine. Checksum/integrity-hash and opaque-ID generation stay `❌ Not implemented` platform services (`platform-services.md`) — unchanged, by design. | Data Portability Community's whole domain (9 workflows), plus one export workflow each in Chess Club, Garden Club, Book Club, Cedar Commons HOA, Youth Soccer |

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
`table`/`documentLibrary`/`searchAiAnswer`/`exportWizard` were `🔲 PENDING` (correct content, temporarily
failing validation) through 2026-08-11 — as of 2026-08-12 all 4 are `✅ REAL`, registered, dispatched, and
validate cleanly like any other archetype (`TabId-Archetype Gap Closure.md`'s Milestone 1, closed).

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
  now-closed implementation milestone for the 4 archetypes above (Milestone 1), plus Milestone 2 (in
  progress, 2026-08-12, explicit human approval received): updating every `NEEDS IMPLEMENTATION` comment
  in real community JSON that this implementation resolves
