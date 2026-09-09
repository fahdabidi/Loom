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
