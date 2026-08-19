---
spec: 4
doc_version: 1.0.0
status: proposed
last_verified: 2026-08-14
audience: llm-agent
derived_from:
  - docs/references/archetypes/CONTRACTS.md
  - docs/references/reference/permissions.md
---

# `formEntry`

A form someone fills in, which then moves through whatever states the community defines.

Used by 7 communities with **43 community-defined transitions** -- the second most customised archetype
after `approvalQueueItem`.

Contract summary: [`CONTRACTS.md`](./CONTRACTS.md).

## 1. Actions

**None named.** Everything derives structurally: `create`, `advance`, `terminate`, `view`.

This is the archetype to reach for when a community's process matches no bespoke family. It is
deliberately the least opinionated: a form has no inherent semantics beyond "someone submitted
something, and it has a state".

## 2. Bookkeeping

**None owned by the archetype.**

The corpus does declare per-person arrays on `formEntry` workflows -- `readFanIds`, `signedUpFanIds`,
`contactSharingFanIds` -- and those stay **community-declared**. A form's fields are its own; the
archetype has no idea what they mean, so it cannot maintain them.

That is the honest boundary, and it is worth stating as a general rule: **an archetype owns bookkeeping
only for actions it defines.** An archetype with no vocabulary owns no bookkeeping.

## 3. Visibility

Model: **`roles` + `owner`**. The submitter always reads their own submission.

Corpus split: 4 `membersOnly`, 3 `guarded`, 2 `public`.

## 4. Community-defined actions

**The norm.** `submit-form`, `approve-case`, `begin-review`, `cancel-signup`, `change-consent`,
`archive-announcement`, and 37 more.

## 5. Open

- **Chess Club's rankings pair `formEntry` with `table`** on one workflow. Both are generic so nothing
  is ambiguous today, but it is the only workflow in the corpus mixing two generic families where the
  primary surface is arguably the `table`.

## 6. Worked example

The archetype to reach for when no bespoke family fits. Everything derives structurally, so the shape
is carried entirely by states, guards and bindings.

```jsonc
"club-volunteer-signup": {
  "initialState": "submitted",
  "visibility": { "default": "membersOnly" },

  "instanceDataSchema": {
    "shiftChoice":    { "type": "text",    "required": true },
    "notes":          { "type": "textarea" },
    "createdByFanId": { "type": "fanId",   "required": true },
    // Community-declared and community-maintained -- see section 2.
    "confirmedFanIds":{ "type": "fanId[]", "writableBy": "effect" }
  },

  "states": {
    "submitted": { "label": "Signed up", "tone": "info",
                   "editableFields": ["shiftChoice", "notes"],
                   "editGuard": { "actorEqualsField": { "key": "createdByFanId" } } },
    "confirmed": { "label": "Confirmed", "tone": "positive" },
    "cancelled": { "label": "Cancelled", "tone": "neutral", "isTerminal": true }
  },

  "transitions": [
    // No "action" key: formEntry is generic (section 1).
    { "id": "confirm-signup", "label": "Confirm",
      "from": ["submitted"], "to": "confirmed",
      "guard": { "allowedRoleIds": ["club-coordinator"] },
      "effects": [ { "op": "append", "key": "confirmedFanIds", "value": "$actor" } ] },

    { "id": "cancel-signup", "label": "Cancel signup", "tone": "destructive",
      "from": ["submitted", "confirmed"], "to": "cancelled",
      "guard": { "actorEqualsField": { "key": "createdByFanId" } } }
  ],

  "renderBindings": [
    { "tabId": "home", "audience": "any",
      "cardSurfaceFamily": "formEntry", "bindingKind": "primary",
      "states": ["submitted", "confirmed", "cancelled"],
      "actions": [ { "kind": "create", "label": "Sign up" } ] }
  ]
}
```

### Why each part is the way it is

- **No `action` anywhere.** Generic family (§1). `create` derives from the create affordance,
  `advance` from `confirm-signup`, `terminate` from `cancel-signup`'s destructive tone and terminal
  target, `view` from reading.
- **`confirmedFanIds` is declared, and that is correct here.** §2: `formEntry` owns no bookkeeping, so
  a per-person array on it is the community's own field, written by the community's own effect. The
  rule that forbids declaring archetype-owned sets does not apply — this archetype owns none.
- **The submitter edits their own submission.** `actorEqualsField` on `createdByFanId` expresses
  "owner", which is half of this archetype's visibility model (§3).
- **`cancel-signup` accepts two `from` states.** Cancelling should work before *and* after
  confirmation; a transition that only left `submitted` would strand confirmed signups.

### What not to do

- Do not use `formEntry` for something a bespoke family already models. A payment is
  `paymentCheckout`; a submit-then-decide queue is `approvalQueueItem` (see
  [`approval-queue.md`](./approval-queue.md) for that pairing). Reaching for `formEntry` because it is
  permissive loses the archetype's bookkeeping and its actions.
- Do not add an `action` to make a transition "explicit". It is a validator error on a generic family.
