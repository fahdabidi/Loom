---
spec: 4
doc_version: 1.0.0
status: current
last_verified: 2026-07-14
audience: llm-agent
derived_from: docs/Build Plan V2/Loom Communities Workflow Engine V3/Loom_Communities_Workflow_Engine_ComputationModel.md
---

# Platform services (normative) — what cannot be JSON

**The boundary.** Almost everything a community needs is expressible as JSON: states, transitions,
guards, effects, and formulas cover all *data math* — tallies, totals, thresholds, rankings, queue
positions, deadlines, redaction, audience resolution.

**A small, closed, community-agnostic set of operations cannot be**, because they are not math over
fields. You cannot express "charge the card" as a formula.

## AGENT: the rule

When a requirement needs one of these:

1. **Do not fake it.** A hardcoded receipt id, a canned "payment succeeded", or a fixed AI answer is
   **AP-6** — a hardcoded value masquerading as a computed one. This is the exact failure the archetype
   audit exists to eliminate.
2. **Do not write code.** These are engine-provided, implemented once, community-agnostic.
3. **Use the service if it exists** (see status below), otherwise **mark and report the gap**:
   ```jsonc
   // NEEDS IMPLEMENTATION (platform service): real receipt-id generation.
   ```

## The closed set

| Service | Why it cannot be a formula | Used by | Status |
|---|---|---|---|
| **Scheduled notifications** — `dueNotifications({asOf})` | Needs a clock/scheduler | Any deadline/reminder | ✅ **REAL** — the engine implements a genuine `dueAt <= asOf` query |
| **Cross-instance eligibility** | Needs another instance's state | Ballot eligibility | ✅ **REAL** — expressible in JSON as the `relatedListMembership` guard |
| **Payment processing** | Calls a payment gateway | `paymentCheckout` | ❌ Not implemented — demo would stub canned success |
| **ID generation** | An opaque unique id is not a field value | Receipts, export ids | ❌ Not implemented |
| **External search / AI answer** | Calls an index or an LLM | `searchAiAnswer` | ❌ Not implemented — demo would return a canned answer for seeded queries |
| **Checksum / integrity hash** | A hash, not arithmetic | `exportWizard` | ❌ Not implemented |

**This list is closed.** If a requirement seems to need a *seventh* kind of service, re-read
[`formulas.md`](./formulas.md) and [`effects.md`](./effects.md) first — it is very likely expressible.
If it genuinely is not, **stop and report it** rather than inventing a mechanism.

## Two that are already REAL and usable from JSON

### Scheduled notifications

Declare a `reminder` block and the platform works out the instant; or, for a materialised
notification, store a `dueAt` outright. Both are swept by `dueNotifications({asOf})`, which is a real
query rather than a stub, and is exposed over HTTP as
`GET /v1/communities/{id}/notifications/due?asOf=`.

```jsonc
"reminder": { "anchorDateField": "eventDate", "anchorTimeField": "eventTime", "leadHours": 24 }
```

A **formula-computed** `dueAt` is not swept. That idiom existed before the block and could not carry a
timezone — see [`workflow-grammar.md`](./workflow-grammar.md)'s `reminder` section.

```jsonc
"deadline":       { "type": "date" },
"dueAt":          { "type": "date" },     // deadline minus the reminder offset
"isExpiringSoon": { "type": "bool", "formula": "isPast(dueAt)" }
```

### Cross-instance eligibility
Fully expressible in JSON — see [`guards.md`](./guards.md) §5. No service call needed.

## Deliberately NOT platform services

These *look* like they might need code but are plain JSON. Do not reach for a service:

| Looks like it needs code | Actually |
|---|---|
| Vote tallying | `groupCount(ballots, choice)` |
| Winner / tie detection | `argMaxKey` / `topKeys` / `size(...) > 1` |
| Runoff creation | `branch` + `createInstance` |
| Capacity / quorum | A `formula` guard |
| Queue position | `indexOf(queuedFanIds, $viewer)` |
| Standings | `sortBy(players, score, 'desc')` |
| Totals / averages | `sum` / `avg` |
| Deadline checks | `isPast(dueAt)` |
| Field masking by viewer | `if($viewer == owner, full, masked)` |
| Propagating a result across workflows | Cross-instance `set` |

## The design principle

> The engine implements each **aggregate function** and each **effect op** exactly once. That fixed
> instruction set is the only Dart. JSON authors — human or Skill — only ever **compose** them; they
> never write a function body.

If a future community genuinely needs an aggregate the vocabulary lacks, that is a **one-time engine
addition** of a new named function (with its own test) — still never per-community code. The "JSON only,
no code" promise holds.

---

## Identity (LoomAuthApi / LocalAuthApi) — established 2026-07-15

**Rationale.** Every guard/effect that references a `personaId` (e.g. `ownerFanId == $actor`,
`allowedRoleIds`, `actorInList`, `voterId`) needs to resolve against a *concrete individual*, not
merely a *role*. The engine's formula evaluator (`$actor`) echoes whatever `personaId` string the
app passes to `applyTransition` / `availableTransitionsAsync`. Until 2026-07-15, the app only ever
passed persona **types** (e.g. `"tabletop-member"`), so `ownerFanId == $actor` could distinguish
an organizer from a member, but never tell `tabletop-member-03` from `tabletop-member-05` apart.

**The contract.** `LoomAuthApi` (`app/packages/core/loom_communities_app_shell/lib/src/part29_auth_api.dart`)
is an abstract identity-provider contract modelled on `WorkflowEngineApi`'s own pattern:

- `listAccounts({communityExtensionId})` → `List<LoomAccount>`
- `signIn({accountId})` → `LoomSession`
- `signUp({communityExtensionId, displayName, personaTypeId})` → `LoomSession`
- `signOut()` → void
- `currentSession` → `LoomSession?`

`LoomAccount` carries **two** identity values:
- `accountId` — the stable per-individual id (e.g. `"tabletop-member-05"`) used for `$actor`/`ownerFanId`/`voterId` resolution
- `personaTypeId` — the declared persona type (e.g. `"tabletop-member"`) used for `allowedRoleIds` guard checks

**Demo backend.** `LocalAuthApi` (`part30_local_auth_api.dart`) seeds accounts from each
community's own frozen JSON individual ids — a genuine interface a real backend could implement
later, not a UI-only illusion.

**Engine integration.** `LocalWorkflowEngineApi` accepts `setPersonaType(individualId, typeId)`
mappings. The guard evaluator's `personaTypeId` parameter enables `allowedRoleIds` checks to
compare against the **type** while all other guard/effect/formula evaluation uses the **individual
id**. This is the load-bearing distinction — see the multi-user login ticket
(`data/v3_ticket_login_multiuser_STATUS.md`) for the full threading audit.

| Service | Why it cannot be a formula | Used by | Status |
|---|---|---|---|
| **Identity / multi-user login** — `LoomAuthApi` | A sign-in session, individual-vs-type distinction, and account management are not data-math | Every guard that distinguishes individuals | ✅ **REAL** — `LoomAuthApi`/`LocalAuthApi` with demo-stubbed backend, seeded from frozen JSON individual ids |
