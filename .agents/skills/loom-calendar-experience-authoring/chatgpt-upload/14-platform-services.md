---
spec: 4
doc_version: 1.1.0
status: current
last_verified: 2026-08-30
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
| **ID generation** | An opaque unique id is not a field value | Receipts, export ids | 🚧 Grammar defined 2026-08-29 (`platformSource: "opaqueId"`); export/transfer ids being built, payment receipts deferred with payment |
| **External search / AI answer** | Calls an index or an LLM | `searchAiAnswer` | ❌ Not implemented — demo would return a canned answer for seeded queries |
| **Checksum / integrity hash** | A hash, not arithmetic | `exportWizard` | ✅ **REAL** since 2026-08-27 — a real SHA-256 over the bytes the export bundle service serves |

**This list is closed.** If a requirement seems to need a *seventh* kind of service, re-read
[`formulas.md`](./formulas.md) and [`effects.md`](./effects.md) first — it is very likely expressible.
If it genuinely is not, **stop and report it** rather than inventing a mechanism.

## Three that are already REAL and usable from JSON

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
### Notification delivery — which channels, and the community's default

Scheduling says *when*. This says *how*, and it is community configuration rather than a platform
service: it lives in the package beside `theme` and `creatableAction`, because it describes the
experience this community offers.

```jsonc
"experience": {
  "notifications": {
    "allowedChannels": ["inbox", "push"],  // "inbox" | "push". Omitted: ["inbox"].
    "default":         ["inbox"],          // subset of allowedChannels. Omitted: ["inbox"].
    "muted":           false               // Omitted: false.
  }
}
```

`allowedChannels` is what this community **offers**; `default` is what a member gets **before they
choose**. They are different facts, and collapsing them would make "we do not offer push"
indistinguishable from "we offer it but do not default to it".

The name follows `allowedRoleIds`, the grammar's existing spelling for a permitted set. It is
deliberately **not** `channels`: fan-passport uses that key for the set a member has *chosen*, and one
word covering both the offered set and the chosen set is the ambiguity this grammar avoids everywhere
else.

**The channel set is closed, and it is closed to what can actually be delivered.** Both values have
working delivery paths on a running device — `inbox` is the `notificationInbox` archetype, `push` is
`FlutterLocalNotificationsPlugin`. There is deliberately no third value: server-initiated push, for a
member whose app is closed, is **not implemented**, and a key promising it would be a field claiming a
writer it does not have.

**`muted` suppresses interruption without suppressing the record.** A muted community still files
notifications in the inbox; a member who looks still sees them. It is retained rather than inferred
from `default` because it mirrors fan-passport's own model exactly, so a member's stored preference
overlays the community default field-for-field with no translation step. Silence is
`default: ["inbox"]` with `muted: true`, never an empty list — an empty array reads as "no opinion" to
a client and "no delivery" to a server, and those must not be the same value.

**This is the community's default, not a member's choice.** A package is identical for every member,
so a per-member preference cannot live in it. fan-passport stores one member's departure from this
default; the two compose, and neither replaces the other.

| Rule | Severity |
|---|---|
| `allowedChannels` non-empty, unique, all within `["inbox", "push"]` | error |
| `default` non-empty, unique, and a subset of `allowedChannels` | error |
| `muted: true` while `inbox` is absent from `default` | error — mutes into silence with nothing left readable |
| an unknown key under `notifications` | error |


### Export bundles and their checksum

Real as of 2026-08-27, and previously the clearest example of why a fabricated value is worse than an
absent one: the only implementation used to return the string
`checksum_<communityId>_<documentCount>_<r|full>`, which hashes nothing.

`docs/API/OpenAPI/community-surfaces/export-bundle-api.openapi.yaml` specifies four operations —
generate, read metadata, download, verify. The workflow service serialises the instance's export scope
canonically, stores the octets, and returns a SHA-256 **over the bytes it actually serves**. Verifying
re-reads those bytes and hashes them again rather than returning the stored value, so a truncated or
replaced bundle fails.

So a `checksum` field is `writableBy: "platform"` — the platform genuinely writes it:

```jsonc
"checksum":         { "type": "text?", "writableBy": "platform" },
"checksumVerified": { "type": "bool",  "writableBy": "platform" }
```

Two constraints worth knowing before authoring against it. Every operation is gated on the caller
being able to invoke a `download` transition, and the bundle is generated when a transition lands the
instance in a state that exposes `download` — so a workflow with no `download` transition never
generates one, by design. And a receipt or transfer id sitting beside a checksum is a **different**
platform service, covered below — not by this one.

### Opaque ids

A `checksum` and a `receiptId` are both `"type": "text?"` with `"writableBy": "platform"`. Nothing in
that distinguishes them, so the platform cannot know which value a field is owed. `platformSource`
does:

```jsonc
"checksum":   { "type": "text?", "writableBy": "platform", "platformSource": "checksum" },
"transferId": { "type": "text?", "writableBy": "platform", "platformSource": "opaqueId" }
```

The workflow service mints an `opaqueId` **once**, on the first transition after which the field is
declared and still empty, and never rewrites it. An id that changes is not an identifier: everything
that quoted the previous value silently stops matching.

**Scope, and why it is not all of them.** Only ids for things that actually happen are minted:
`transferId` and `exportReceiptId`, where a bundle really is produced. `receiptId`,
`paymentConfirmationId` and `settlementId` stay declared-and-unwritten alongside **payment
processing**, which is deferred. A receipt id for a payment that never occurred is a confirmation
number for a transaction that did not happen — the same fabrication the canned
`checksum_<communityId>_<count>` string was, and worse, because it looks like proof of money moving.

So a declared id field being empty is **correct** wherever payment is its trigger. Do not author
around it, and do not add an effect to fill it in.

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
