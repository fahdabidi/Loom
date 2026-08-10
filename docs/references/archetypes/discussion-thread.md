---
spec: { envelope: 1, experience: 2, grammar: 2 }
doc_version: 1.0.0
status: current
last_verified: 2026-08-05
audience: llm-agent
derived_from:
  - app/packages/core/loom_communities_app_shell/lib/src/part26_generic_instance_card.dart
  - app/packages/core/loom_communities_app_shell/lib/src/part27_engine_native_binding_dispatcher.dart
---

# `discussionThread` — threads, messages, compose

**Read [archetypes/README.md](./README.md) first — this family is
🟡 GENERIC.** No dispatcher case exists for it; it reaches
`GenericWorkflowInstanceCard` — plus a new **generic** (not thread-specific)
structured-list field renderer that any workflow with a list-of-maps field
can use.

## JSON shape

```jsonc
{
  "states": ["open"], "role": "any", "tabId": "messages",
  "cardSurfaceFamily": "discussionThread", "bindingKind": "primary",
  "actions": [
    { "kind": "create", "label": "New thread", "...": "..." }
  ]
}
```

## The generic structured-list renderer

`instanceDataSchema` can declare a field whose value is a **list of maps**
(a thread's messages: each entry has sender/body/timestamp). Rather than
build a `discussionThread`-only widget to render that field, tracker 3
Phase F added a generic renderer (`_GenericInstanceListField`,
`part26_generic_instance_card.dart`) that infers sender/body/timestamp shape
from any list-of-maps field and falls back gracefully for unrecognized
shapes. Any future workflow type with a similar list-of-records field gets
this rendering for free — it is not scoped to `discussionThread`.

## What's real

Live thread list (query-bound, new threads appear without polling), open
thread → send reply, mute/archive toggle, unread tracking, and a real
"start a new thread" creation action (`actions[]`, above) — all engine-
backed. What's explicitly **not** built: invites. The renderer contract this
family used to claim (`'messages-inbox-thread-composer'` in
`part11_shell_models.dart`) previously asserted invite support that does not
exist in the frozen JSON; Phase F corrected the contract to match reality
rather than build a fake invite affordance.

## Unread tracking — a degraded capability, by design

"All participants except the actor" is not expressible in the current
grammar (tracked as `knownGaps.listMinusActor` in `spec-version.json`) — a
transition cannot both read the actor's identity and write "everyone but
them" into a list field in one step. Thread unread state is therefore a
single shared boolean via `setFromFormula` + `removeAll()`, not a per-
participant unread set. This is an explicit, documented degradation, not a
bug — do not build a workaround for it in a new community's JSON; wait for
the grammar gap to close.
