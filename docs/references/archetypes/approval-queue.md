---
spec: 4
doc_version: 1.0.0
status: current
last_verified: 2026-08-05
audience: llm-agent
derived_from:
  - app/packages/core/loom_communities_app_shell/lib/src/part26_generic_instance_card.dart
  - app/packages/core/loom_communities_app_shell/lib/src/part27_engine_native_binding_dispatcher.dart
---

# `approvalQueueItem` + `formEntry` — submit, then decide

**Read [archetypes/README.md](./README.md) first — both families are
🟡 GENERIC.** No dispatcher case exists for either; both reach
`GenericWorkflowInstanceCard`. What is real is the pattern connecting them:
one workflow type, one instance, rendered differently on two tabs by two
different `renderBindings` entries scoped by `role` and `state`.

## The pattern: one workflow, two roles, two tabs

Tabletop Club's `game-purchase-proposal` workflow declares three bindings on
the same workflow type:

```jsonc
// Home tab — the member who submitted it, while it's editable
{ "states": ["draft", "changes-requested"], "role": "actor", "tabId": "home",
  "cardSurfaceFamily": "formEntry", "bindingKind": "primary",
  "actions": [
    { "kind": "create", "label": "Propose a game",
      "byPersonaIds": ["tabletop-member"], "...": "..." }
  ] },

// Home tab — the same member, read-only status once submitted
{ "states": ["pending", "approved", "rejected"], "role": "actor", "tabId": "home",
  "cardSurfaceFamily": "statusTimeline", "bindingKind": "summary" },

// Admin tab — the organizer, deciding
{ "states": ["pending"], "role": "receiver", "tabId": "admin",
  "cardSurfaceFamily": "approvalQueueItem", "bindingKind": "primary" }
```

`role: "actor"` vs `role: "receiver"` is what makes the same instance render
as an editable form to its submitter and a decision queue item to the
organizer — not two separate workflow types, and not client-side role
branching. The engine resolves which binding applies per viewer.

## Live query-bound queue

The admin queue is a genuinely live `queryInstances`-bound Repeater: a new
proposal appears in the organizer's queue with no polling or manual refresh,
because the query re-evaluates against the shared engine, not a one-time
fetch. Approve/Reject/Request-changes are real transitions — a
`changes-requested` decision moves the instance back to the `formEntry`
binding above, which the same member sees as an editable card again (the
`draft`/`changes-requested` states share one binding).

## Why no bespoke widget

Rather than build a one-off proposal-shaped widget, tracker 3 Phase E
verified the generic card's live-query/role-scoped/creatable machinery
end-to-end on this workflow — that machinery, not a bespoke widget, is what a
new community's approval-flavored workflow actually needs from the Skill.

## Known gotcha this pattern exposed

A transition's `guard` must be checked against only the transitions reachable
from the states a binding actually declares when deciding tab visibility —
checking *any* transition in the whole workflow definition can incorrectly
grant a member-only tab to the wrong role (found and fixed in tracker 3 Phase
E; see `part12_persona_and_tabs.dart`'s `_personaCanAdministerAnyWorkflow`).
