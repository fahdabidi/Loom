---
spec: 4
doc_version: 1.0.0
status: current
last_verified: 2026-07-21
audience: llm-agent
derived_from:
  - docs/references/reference/render-bindings.md
  - docs/references/communities/Loom_Communities_Workflow_Engine_Phase1_TabletopClub_Example.jsonc
  - docs/references/archetypes/README.md
---

# Actions & FABs — choosing create vs. transition, and designing the affordance

**This doc answers one question the Skill hits on nearly every requirement:** *"a member can do X — is X a
new instance, or a change to an existing one, and how should the affordance render?"* `render-bindings.md`
is the normative grammar for `actions[]`; this doc is the decision procedure and worked examples for using
it. Read `render-bindings.md`'s `actions` section first if you have not — this doc assumes it.

## The two primitives

Every member-facing affordance in a Loom community is one of exactly two things:

| | **Create** | **Transition** |
|---|---|---|
| What it does | Makes a **brand-new instance** of some workflow type | Changes the **state or data** of an **existing** instance |
| Declared | Statically, in `renderBindings[].actions[]` (`kind: "create"`) | Statically, in `transitions[]` — rendering is **automatic** (a button row from `availableTransitions`) unless pulled out via `renderBindings[].actions[]` (`kind: "transition"`) |
| Eligibility | `byPersonaIds` (a UI-level allow-list on the action itself) | The transition's own `guard` (engine-enforced — see [`guards.md`](../reference/guards.md), AP-4) |
| Example | "New event", "Propose a game", "List a game you own" | "Going" / "Maybe", "Reserve", "Approve", "Cast vote" |

**The test:** *is the set of things-that-can-exist unbounded (a club can have any number of game nights,
proposals, threads), or bounded to the instances that already exist (this one tournament, this one
listing)?* Unbounded → create. Bounded, acting on one already-existing thing → transition. See
[`common-patterns.md`](./03-common-patterns.md) P1–P6 for the transitions side; this doc is about the
create side plus how either kind chooses its presentation.

**A resource can need both.** `event-rsvp`: the event itself is a create ("New event" — the set of game
nights is unbounded); each member's RSVP is a transition (`rsvp-going`/`rsvp-maybe` — bounded to "this
member, this event"). Do not model an unbounded resource as a transition on a seeded placeholder (AP-13),
and do not model a bounded state change as a second workflow type (AP-7).

## `kind: "create"` — scope and presentation

A create action's `scope` decides everything else. See `render-bindings.md`'s full matrix; summary:

| Scope | Renders as | Context | Visible with zero instances? |
|---|---|---|---|
| `tab` (default) | always a tab FAB | none (no `{context.*}`) | **yes** — creation-from-nothing must always be reachable |
| `instance` | `button` on each host card, or a contextual `fab` bound to the in-focus card | `{context.id}` / `{context.<field>}` from the host instance | **no** — nothing to attach the action to |

```jsonc
// Tab-scoped: "New event" — a brand-new event-rsvp, unrelated to anything on screen.
{ "kind": "create", "label": "New event", "byPersonaIds": ["tabletop-organizer"],
  "scope": "tab", "presentation": "fab" }

// Instance-scoped, cross-archetype: "Create ballot for this tournament" — owned by the
// tournament-event card, {context.id} = that specific tournament's own id.
{ "kind": "create", "workflowType": "tournament-ballot",
  "label": "Create ballot for this tournament", "byPersonaIds": ["tabletop-organizer"],
  "scope": "instance", "presentation": "button", "prefill": { "eventId": "{context.id}" } }
```

**Choosing `fab` vs. `button` for a create action:** `fab` for the primary, always-reachable way to make a
brand-new thing on a tab (there is usually exactly one, or a handful resolved via `multiActionStyle`).
`button` for an instance-scoped create that belongs visually to one specific card among several on the
same tab (a tournament's own "Create ballot" button lives on *that* card, not floating contextless above
a list of tournaments).

## `kind: "transition"` — elevating one transition out of the automatic row

**Nothing is required to make a transition work.** Every declared `transitions[]` entry already renders
automatically as a button in the archetype's action row, gated by its own `guard` — this is P1–P6's whole
model and needs no `actions[]` entry at all. `kind: "transition"` exists for a narrower, purely
presentational need: **product design wants one particular transition to stand out** — a floating "Reserve"
FAB instead of one button among several, or a visually distinguished primary button — while every other
transition on the same type keeps rendering in the row exactly as before.

```jsonc
// equipment-loan already declares "borrow"/"join-queue"/"leave-queue"/"return"/"delist" as
// plain transitions (see common-patterns.md P4). Pulling "borrow" out as a contextual FAB:
{ "kind": "transition", "transitionId": "borrow", "label": "Request loan", "presentation": "fab" }
// join-queue/leave-queue/return/delist keep rendering as row buttons, unchanged.
```

Declaring this **removes only `borrow`** from the automatic row — never both, to avoid two affordances for
one transition. `byPersonaIds`, `workflowType`, and `prefill` do not apply here: the transition's own
`guard` is still the sole eligibility check (unchanged, still engine-enforced, still testable by attempting
the transition per AP-4) and it always acts on its own binding's own type. Use `inputs` (not `prefill`) if
the transition itself declares `inputs` — same `{input.x}`/`{context.<field>}` grammar as a repeater's
`itemActions` (`render-bindings.md`).

**When to reach for this vs. leaving the row alone:** the row is the default and is correct for most
transitions (secondary/administrative ones — `delist`, `leave-queue`, `request-changes`). Promote a
transition to its own FAB/button only when the product doc calls out that action as *the* primary,
attention-grabbing thing to do on that card — not for every transition a workflow declares. Overusing this
just re-creates the row with extra JSON.

## Same grammar, every archetype

The `actions[]` shape does not change per archetype — only the workflow type being created/transitioned,
and the label, do.

```jsonc
// discussionThread — tab-scoped create, unbounded threads.
{ "kind": "create", "label": "New thread", "byPersonaIds": ["tabletop-member", "tabletop-organizer"],
  "scope": "tab", "presentation": "fab" }

// formEntry — tab-scoped create, unbounded proposals.
{ "kind": "create", "label": "Propose a game", "byPersonaIds": ["tabletop-member"],
  "scope": "tab", "presentation": "fab" }

// votePoll — cross-archetype instance-scoped create, exactly like the tournament-ballot example above:
// the vote-poll's OWN binding never declares this; it is declared on the HOST (e.g. tournament-event).
{ "kind": "create", "workflowType": "meeting-agenda-poll", "label": "Start a poll for this meeting",
  "byPersonaIds": ["tabletop-organizer"], "scope": "instance", "presentation": "button",
  "prefill": { "meetingId": "{context.id}" } }
```

**Cross-archetype rule (locked design):** an action that creates workflow type B, contextualised by an
instance of type A, is declared on **A's** binding — never B's. B's binding does not know, and should not
need to know, every type that might create instances scoped to it. This is why `tournament-event` (not
`tournament-ballot`) owns "Create ballot for this tournament."

## Archetype inventory — what each can create, and its typical transitions

| Archetype | Typical tab-scoped create | Typical instance-scoped create (cross-archetype, on the host) | Typical transitions (automatic row) |
|---|---|---|---|
| `event-rsvp` (calendar) | New event | — | `respond-going`/`respond-maybe`/`respond-declined`/`respond-waitlist`, `cancel-event` |
| `tournament-event` (calendar) | New tournament | Create ballot for this tournament (`tournament-ballot`) | `rsvp-going`, `rsvp-withdraw`, `cancel-tournament` |
| `tournament-ballot` | — (never created directly; always via its host) | — | `cast-vote` (via `repeater.itemActions`), `close-vote` |
| `equipment-loan` / `tabletop-game-loan` (marketplace) | Share/list a game | — | `borrow` (candidate for a transition-FAB), `join-queue`, `leave-queue`, `return`, `delist` |
| `equipment-giveaway` (marketplace) | — (giveaways are listed via `equipment-loan`'s own create) | — | `claim` |
| `formEntry` (proposals, home/admin) | Propose a game | — | `submit`, `approve`, `request-changes`, `reject` |
| `discussionThread` (messages) | New thread | — | `post-message`, `mark-read`, `archive` |
| `paymentCheckout` (giving) | — (dues are seeded per member, not member-created) | — | `pay` |
| `votePoll` (home, general) | — (created via its host, see above) | Start a poll for this &lt;host&gt; | `cast-vote`, `close-vote` |
| `statusTimeline` / `approvalQueueItem` | — (summary/decision views over a `formEntry`-created instance) | — | `approve`, `request-changes`, `reject` |
| `notificationInbox` | — | — | `mark-read`, `archive` |
| `documentLibrary` | Upload a document | — | `archive`, `delete` |
| `volunteerRoster` | — | Add a shift for this &lt;event&gt; | `sign-up`, `withdraw` |
| `guidedProcess` | Start a &lt;process&gt; | — | step-advancing transitions, one per step |

Rows with no tab-scoped create ("—") are either summary/decision surfaces over instances created
elsewhere, or exist only via a cross-archetype instance-scoped create on their host. Never invent a
tab-scoped create for a type that is always contextually created — that reintroduces AP-13's "seeded blank
draft" problem one level up.

## The hard case: two "creates" on one Table-family binding

**"Create a new potluck event" vs. "sign up to bring a dish to this potluck"** are different scopes on
possibly the same archetype family:

```jsonc
"potluck-event": {
  // ... states/transitions ...
  "renderBindings": [
    { "states": ["open"], "role": "any", "tabId": "calendar",
      "cardSurfaceFamily": "stateMachineGrid", "bindingKind": "primary",
      "actions": [
        // Container-create: a brand-new potluck, unrelated to any existing one.
        { "kind": "create", "label": "New potluck", "byPersonaIds": ["tabletop-organizer"],
          "scope": "tab", "presentation": "fab" },

        // Entry-create: a dish signed up to THIS potluck. Instance-scoped, owned by THIS
        // binding (dish-signup's own type is created FROM the potluck card, same rule as
        // tournament-ballot above — just same-archetype instead of cross-archetype).
        { "kind": "create", "workflowType": "potluck-dish-signup", "label": "Sign up to bring a dish",
          "byPersonaIds": ["tabletop-member"], "scope": "instance", "presentation": "button",
          "prefill": { "potluckId": "{context.id}" } }
      ] }
  ]
}
```

**Why this never collides, even with several potlucks on the same tab:**

| Action | Scope | Collision risk | Why |
|---|---|---|---|
| New potluck | `tab` | Yes, if another tab-scoped create shares the tab | Resolved by the **already-implemented** `multiActionStyle` (`speedDial`/`stacked`/`singleFirst`) — the mechanism this exact case exists for |
| Sign up to bring a dish | `instance` | No | As a `button`, each potluck's card renders its own button, bound to its own `{context.id}` — never ambiguous. As a `fab`, only the in-focus card's action is live at all |

Container-creates are tab-level and can multiply; entry-creates are card-level and self-scoping. No new
grammar concept is needed for "multiple tables in one tab" beyond what `scope` and `multiActionStyle`
already provide.

## Self-check before emitting an `actions[]` entry

- [ ] Is this really unbounded (create) or acting on one existing instance (transition)? Do not model a
      bounded state change as a `kind: "create"` of a redundant type, and do not fake an unbounded resource
      as a seeded placeholder (AP-13).
- [ ] Did you declare a `kind: "transition"` action only because the product doc calls this one out as the
      primary, attention-grabbing action — not for every transition a type has?
- [ ] Is `byPersonaIds`/`workflowType`/`prefill` absent from every `kind: "transition"` action? (They are
      inapplicable — the transition's own `guard` and `inputs` are already the source of truth.)
- [ ] Is `inputs` absent from every `kind: "create"` action, and `prefill` absent from every `kind:
      "transition"` action? (Wrong field for that kind.)
- [ ] For a cross-type instance-scoped action, is it declared on the **host's** binding, not the created
      type's own binding?
- [ ] Does every `scope: "tab"` action stay reachable with zero instances of its own type, and does every
      `scope: "instance"` action correctly disappear when zero host instances exist?
- [ ] If two or more `scope: "tab"` creates land on the same tab, did you consider
      `creatableAction.multiActionStyle` rather than inventing a new disambiguation concept?

## Reference

- [`render-bindings.md`](../reference/render-bindings.md) — normative `actions[]` grammar, full validator
  check list.
- [`03-common-patterns.md`](./03-common-patterns.md) — the transition side (P1–P6) this doc builds on.
- [`04-antipatterns.md`](./04-antipatterns.md) — AP-4 (guard, not UI, is the security boundary), AP-7 (no
  duplicated workflow per persona), AP-13 (no seeded placeholder standing in for a real create).
- [`archetypes/README.md`](../archetypes/README.md) — the authoritative `cardSurfaceFamily` enum and each
  archetype's real render status.
