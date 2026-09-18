---
spec: 4
doc_version: 1.0.0
status: current
last_verified: 2026-08-05
audience: llm-agent
derived_from:
  - app/packages/core/loom_communities_app_shell/lib/src/part36_engine_native_marketplace_surface.dart
  - app/packages/core/loom_communities_app_shell/lib/src/part27_engine_native_binding_dispatcher.dart
---

# `equipment-loan` — browse, borrow, queue, return

`cardSurfaceFamily: "equipment-loan"` is a genuinely distinct, bespoke widget
(`EquipmentLoanArchetypeCard`), reached purely by declaring the family — no
per-community wiring required. Covers both **loan** (borrow/queue/return) and
**giveaway/peer-sharing** (claim) lifecycles from the same widget; it branches
internally rather than needing a second family name.

## JSON shape

```jsonc
{
  "states": ["published"], "role": "any", "tabId": "marketplace",
  "cardSurfaceFamily": "equipment-loan", "bindingKind": "primary",
  "actions": [
    { "kind": "create", "label": "Share a game", "...": "..." }
  ]
}
```

An `"available"`-state binding with the same family covers the
already-in-catalog item shown for browsing before anyone has borrowed it.

## Real per-item interaction

The widget renders real transition buttons driven live off
`availableTransitionsAsync` — it does not hardcode which buttons to show:
`borrow`, `join-queue`, `leave-queue`, `return`, `return-game`, `claim`. Which
subset appears depends on the instance's current state and the guard results
the engine actually evaluates (e.g. an outstanding-dues guard can block
`borrow` even though the item is otherwise available — see
[guards.md](../reference/guards.md) for the guard-expression grammar).

**`join-queue` and `leave-queue` are the deliberate exception to the sentence above.** Those two are
NOT sourced from `availableTransitionsAsync`. The engine's availability for them is computed from
`queuedFanIds`, an instance-local list the durable cross-member item queue replaced, so the surface
selects them from the **declared** machine instead and asks the queue service whether the viewer is
already queued — that is what decides join-versus-leave. See
[platform-services.md](../reference/platform-services.md) for the service and the shape a package
should declare.

Two consequences worth knowing, because each has produced a real defect:

- **Bypassing engine availability does not license bypassing the guard.** These transitions still
  carry `allowedRoleIds` and `formula` guards, and the service enforces them — a surface that offers
  the button without evaluating them produces a button the server refuses. Evaluating the guard
  requires the viewer's **role**, not just their fan id: a role-less evaluation fails every
  non-empty `allowedRoleIds` and hides the button from everyone, which looks like a fix and is worse.
- **Do not "restore" `availableTransitionsAsync` for this pair.** It would reintroduce the
  legacy-membership dependency the item queue exists to escape. Every other button in the list above
  genuinely is driven live, and that part of the sentence is accurate.

## Delisting an item that is out — the owner always keeps an exit

**An owner must never be stranded by a counterparty's inaction.** The obvious authoring gets this
wrong, and it is shipping in Garden Club today: `delist` and `pause-listing` are guarded to the owner
*and* preconditioned on `availabilityState == "available"`, while every transition that clears
`onLoan` — `return-item`, `mark-damaged`, `report-lost` — is guarded to the borrower. So once an item
is on loan, the owner's exits are precondition-blocked and every state-clearing action belongs to
someone else. A borrower who simply stops responding keeps the owner's property listed forever, and
the owner's only remaining action is `report-issue`, which declares `"to": null` and changes nothing.

**Every one of those guards is individually correct**, which is the point: the defect exists only in
the graph. A borrower *should* be the one who returns an item. What is wrong is that no path out
remains for the owner.

**The required shape: `delist` is always available to the owner, and what differs is where it lands.**

| Item state | `delist` result | Why |
|---|---|---|
| `available` | `delisted`, terminal | nothing is outstanding |
| `reserved` | `delisted`, terminal — the reservation is released with it | a reservation is a claim on the future, not custody |
| `onLoan` | **`delisted-pending-return`**, non-terminal | the listing stops accepting new borrowers immediately, and the outstanding custody is still tracked |

`delisted-pending-return` keeps exactly the transitions that discharge the obligation — the borrower's
`return-item`, `mark-damaged` and `report-lost` — and offers no new-borrower actions. Returning from
it lands in `delisted`, terminal. **The owner's decision takes effect at once; only the physical
custody waits**, which is the honest model: revoking a listing cannot teleport a tool out of someone's
hands, but it must not depend on that person to take effect either.

**Do not solve this with a coordinator override instead.** An override adds a third party who must
act, which is the same dependency one step removed — and Garden's coordinator role appears only on a
create action, never on a transition guard, so today there is no such actor anyway. The owner's own
exit is the fix.

**The general rule, which is why this sits in the archetype and not in one community's package:** when
a destructive transition is guarded to party A and preconditioned on a state only party B can clear,
A is stranded. Either A gets an exit from that state, or the precondition is wrong. It is not
something each package is expected to notice, because every declaration involved looks correct on its
own — so the validator catches it as
[`destructive_exit_blocked_by_counterparty`](../guide/05-validation.md) (warning).

**What quiets it** — either repair works, and the rule deliberately accepts both: give the blocked
party a transition of their own out of the stuck value (the `delist` → `delisted-pending-return` shape
above), or make the clearing transitions **role**-guarded rather than exclusive to one individual, so
the owner can fire them by holding the role. Book Club and Camera Club already take the second route,
which is why they ship the same archetype with no strand. **The check runs over the availability
field's value graph, not declared states** — this family keeps its real lifecycle in
`availabilityState` with `"to": null` transitions, and a state-based check would see one node and
report everything as fine.

## Cross-workflow guard example

Tabletop Club gates `borrow` on the member's dues-payment workflow being
current — a guard expression that reads a *different* workflow instance
(`tabletop-club-dues-payment`), not just this one. This is the pattern to
follow whenever an interaction should be blocked by state living in another
workflow type: express it as a guard, not client-side conditional rendering,
so it stays correct if the underlying instance changes between renders.

## Search/filter/grid shell

The browse chrome above the per-item cards (search, filter, paginated grid)
predates this archetype and is not part of the `cardSurfaceFamily` contract
itself — it is the marketplace tab's own list surface, reused unchanged by
every workflow type shown on that tab.

## History

Before tracker 3 Phase C, this family was 🟡 PARTIAL: the browse/grid shell
was real but every per-item action fell back to the generic template. Phase C
built the missing bespoke interaction; verified zero remaining fallback to
`GenericWorkflowInstanceCard` anywhere in the widget.
