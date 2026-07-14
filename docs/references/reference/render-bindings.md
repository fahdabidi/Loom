---
spec: { envelope: 1, experience: 2, grammar: 1 }
doc_version: 1.0.0
status: current
last_verified: 2026-07-14
audience: llm-agent
derived_from:
  - app/packages/core/loom_workflow_engine/lib/src/evaluator/binding_resolver.dart
  - app/packages/core/loom_communities_app_shell/lib/src/part12_persona_and_tabs.dart
---

# Render bindings (normative) — grammar v1

A render binding answers: **where does an instance of this workflow appear, in this state, for this
role?**

**Key idea:** a workflow lands on a tab because **its own JSON says so** — not because of any hardcoded
rule. A workflow with **no** binding for a state does not render in that state (the correct way to hide
drafts).

## Binding object — all 6 keys

```jsonc
{
  "states": ["open"],                  // REQUIRED
  "role": "any",                       // REQUIRED
  "tabId": "calendar",                 // REQUIRED
  "cardSurfaceFamily": "event-rsvp",   // REQUIRED
  "bindingKind": "primary",            // REQUIRED
  "audienceMemberField": "invitedPersonaIds"  // optional
}
```

| Key | Type | Required | Meaning |
|---|---|---|---|
| `states` | string[] | **yes** | Which states this binding applies to. Each MUST be declared. |
| `role` | string | **yes** | `any` · `actor` · `receiver` |
| `tabId` | string | **yes** | Which tab (enumerated below) |
| `cardSurfaceFamily` | string | **yes** | Which archetype renders it |
| `bindingKind` | string | **yes** | `primary` · `summary` |
| `audienceMemberField` | string | no | Field holding invited personas, for targeted visibility |

## `tabId` — complete list

| `tabId` | Purpose | Always present? |
|---|---|---|
| `home` | The curated feed — what needs attention | **Yes** (structural) |
| `messages` | Discussion threads | **Yes** (structural, renameable but not removable) |
| `calendar` | Events, schedules, RSVPs | Only if the community declares calendar content |
| `marketplace` | Browse/borrow/claim items | Only if declared |
| `giving` | Payments, dues, donations | Only if declared |
| `admin` | Organizer-only queues and publishing | Only if declared |

`home` and `messages` are added **unconditionally** by the App Shell. The rest appear only when a
workflow binds to them.

## `role` — complete list

| `role` | Renders for |
|---|---|
| `any` | Everyone who can see the community |
| `actor` | The persona who acts on / owns this instance |
| `receiver` | The persona on the receiving end (approver, organizer) |

**Role is how one workflow serves two audiences differently.** A proposal binds `actor` → the author's
Home card, and `receiver` → the organizer's Admin queue. **One workflow, two surfaces.**

## `bindingKind` — complete list

| `bindingKind` | Renders as |
|---|---|
| `primary` | Full, interactive card — includes the action buttons |
| `summary` | Compact/read-only card |

Use `primary` for the state where the user acts; `summary` for states where they only observe (a closed
ballot, a cancelled event).

---

## Canonical patterns

### One workflow, two tabs, two roles

```jsonc
"renderBindings": [
  // The author composes it on Home
  { "states": ["draft", "changes-requested"], "role": "actor", "tabId": "home",
    "cardSurfaceFamily": "formEntry", "bindingKind": "primary" },

  // The author watches its status on Home
  { "states": ["pending", "approved", "rejected"], "role": "actor", "tabId": "home",
    "cardSurfaceFamily": "statusTimeline", "bindingKind": "summary" },

  // The organizer decides it in the Admin queue
  { "states": ["pending"], "role": "receiver", "tabId": "admin",
    "cardSurfaceFamily": "approvalQueueItem", "bindingKind": "primary" }
]
```

Note: `draft` has **no** `receiver` binding — an unsubmitted draft is invisible to the organizer. That
is expressed by *omission*, not by a permission flag.

### One instance, two tabs (same role)

```jsonc
// A tournament shows on Calendar as an event AND on Home next to its ballot.
"renderBindings": [
  { "states": ["open"], "role": "any", "tabId": "calendar",
    "cardSurfaceFamily": "event-rsvp", "bindingKind": "primary" },
  { "states": ["open"], "role": "any", "tabId": "home",
    "cardSurfaceFamily": "votePoll", "bindingKind": "summary" }
]
```

### Hiding a state

```jsonc
"states": { "draft": {...}, "published": {...} },
"renderBindings": [
  { "states": ["published"], "role": "any", "tabId": "home",
    "cardSurfaceFamily": "notificationInbox", "bindingKind": "summary" }
  // No binding for "draft" -> drafts do not appear on Home. Correct.
]
```

---

## Rules (validator-enforced)

| Rule | Severity |
|---|---|
| Every `states` entry must be a declared state | error |
| `cardSurfaceFamily` must be a registered archetype | warning (`missing_template`) |
| A `primary` binding's surface must include an action-button row | error (`missing_action_button_row`) |
| >32 bindings on one workflow | warning — a smell; likely two workflows |
| >16 distinct roles | warning — same |

## Anti-patterns

| ❌ Wrong | ✅ Right |
|---|---|
| Every workflow bound to `home` "so the user sees it" | Bind to the tab it belongs on. Home is a curated feed, not a dumping ground. |
| Two near-identical workflows for two personas | **One** workflow, two `role`-keyed bindings |
| A `hidden`/`archived` state with a binding, then filtering it out in the UI | Simply declare **no binding** for that state |
| Inventing a `cardSurfaceFamily` | Only values in [`archetypes/README.md`](../archetypes/README.md) exist |
