---
spec: { envelope: 1, experience: 2, grammar: 2 }
doc_version: 1.1.0
status: current
last_verified: 2026-07-21
audience: llm-agent
---

# Common patterns — canonical templates

**Six patterns cover nearly every community requirement.** Match the requirement to a pattern, copy the
template, rename.

| Requirement sounds like… | Pattern |
|---|---|
| "members sign up for events / sessions / shifts" | [P1 — RSVP with capacity](#p1--rsvp-with-capacity-and-waitlist) |
| "members vote / choose / elect" | [P2 — Ballot](#p2--ballot-with-tally-eligibility-and-runoff) |
| "someone proposes, someone approves" | [P3 — Approval queue](#p3--approval-queue-propose--decide) |
| "members borrow / reserve / check out items" | [P4 — Loan lifecycle](#p4--loan-lifecycle-with-queue) |
| "members pay dues / donate" | [P5 — Payment](#p5--payment) |
| "members discuss / message" | [P6 — Discussion thread](#p6--discussion-thread) |

---

## P1 — RSVP with capacity and waitlist

**Key ideas:** attendance is **data**, not state (many members simultaneously). Capacity is enforced by a
**formula guard**. The waitlist appears only when genuinely full.

```jsonc
"event-rsvp": {
  "initialState": "open",
  "states": {
    "open":      { "label": "RSVP open", "tone": "positive",
                   "editableFields": ["title", "eventDate", "location", "capacity"] },
    "cancelled": { "label": "Cancelled", "tone": "negative", "isTerminal": true }
  },
  "transitions": [
    { "id": "rsvp-going", "label": "Going", "icon": "event_available", "tone": "primary",
      "from": ["open"], "to": null,
      "guard": { "allowedPersonaIds": ["member"],
                 "formula": "size(goingPersonaIds) < capacity" },
      "effects": [
        { "op": "appendUnique", "key": "goingPersonaIds",   "value": "$actor" },
        { "op": "removeValue",  "key": "maybePersonaIds",   "value": "$actor" },
        { "op": "removeValue",  "key": "waitlistPersonaIds","value": "$actor" }
      ] },
    { "id": "rsvp-maybe", "label": "Maybe", "icon": "help_outline", "tone": "secondary",
      "from": ["open"], "to": null,
      "guard": { "allowedPersonaIds": ["member"] },
      "effects": [
        { "op": "appendUnique", "key": "maybePersonaIds",  "value": "$actor" },
        { "op": "removeValue",  "key": "goingPersonaIds",  "value": "$actor" }
      ] },
    { "id": "join-waitlist", "label": "Join waitlist", "icon": "groups", "tone": "secondary",
      "from": ["open"], "to": null,
      "guard": { "allowedPersonaIds": ["member"],
                 "formula": "size(goingPersonaIds) >= capacity",
                 "actorInList": { "key": "waitlistPersonaIds", "present": false } },
      "effects": [ { "op": "appendUnique", "key": "waitlistPersonaIds", "value": "$actor" } ] },
    { "id": "cancel-event", "label": "Cancel event", "tone": "destructive",
      "from": ["open"], "to": "cancelled",
      "guard": { "allowedPersonaIds": ["organizer"] } }
  ],
  "renderBindings": [
    { "states": ["open"], "role": "any", "tabId": "calendar",
      "cardSurfaceFamily": "event-rsvp", "bindingKind": "primary" }
  ],
  "instanceDataSchema": {
    "title":     { "type": "text",   "required": true, "writableBy": "formEntry",
                   "labelTemplate": "{value}" },
    "eventDate": { "type": "date",   "required": true, "writableBy": "formEntry",
                   "sortable": true, "displayIcon": "calendar_today" },
    "location":  { "type": "text",   "writableBy": "formEntry",
                   "displayIcon": "location_on_outlined" },
    "capacity":  { "type": "number", "required": true, "writableBy": "formEntry",
                   "displayIcon": "groups_outlined", "labelTemplate": "{value} seats" },

    "goingPersonaIds":    { "type": "personaId[]", "writableBy": "effect" },
    "maybePersonaIds":    { "type": "personaId[]", "writableBy": "effect" },
    "waitlistPersonaIds": { "type": "personaId[]", "writableBy": "effect",
                            "labelTemplate": "Waitlist: {value.length}", "hideWhenEmpty": true },

    "goingCount":     { "type": "number", "formula": "size(goingPersonaIds)",
                        "labelTemplate": "Going: {value}" },
    "spotsRemaining": { "type": "number", "formula": "capacity - size(goingPersonaIds)" },
    "isFull":         { "type": "bool",   "formula": "size(goingPersonaIds) >= capacity" }
  }
}
```

---

## P2 — Ballot with tally, eligibility, and runoff

**Key ideas:** the entire tally/winner/tie is **four formulas**. Eligibility is a **cross-instance
guard**. A tie spawns a **real runoff** via `branch` + `createInstance`.

```jsonc
"ballot": {
  "initialState": "open",
  "states": {
    "open":   { "label": "Voting open", "tone": "positive", "editableFields": ["pendingChoice"] },
    "closed": { "label": "Closed", "tone": "info", "isTerminal": true }
  },
  "transitions": [
    { "id": "cast-vote", "label": "Vote", "icon": "how_to_vote", "tone": "primary",
      "from": ["open"], "to": null,
      "guard": {
        "allowedPersonaIds": ["member"],
        // Only personas on the linked EVENT's going-list may vote. Engine-enforced.
        "relatedInstanceField": "eventId",
        "relatedListField": "goingPersonaIds"
      },
      "effects": [
        { "op": "append", "key": "ballots",
          "value": { "personaId": "$actor", "choice": "{pendingChoice}" } }
      ] },
    { "id": "close-vote", "label": "Close vote", "tone": "primary",
      "from": ["open"], "to": "closed",
      "guard": { "allowedPersonaIds": ["organizer"] },
      "effects": [
        { "op": "branch", "if": "isTie",
          "then": [
            { "op": "createInstance", "workflowType": "ballot",
              "fields": { "eventId": "{eventId}", "candidates": "{tiedCandidates}",
                          "round": "runoff", "pendingChoice": "", "ballots": [] } },
            { "op": "set", "key": "outcome", "value": "runoff" }
          ],
          "else": [
            { "op": "set", "key": "outcome", "value": "decided" },
            { "op": "set", "key": "selectedOption", "value": "{winner}",
              "relatedInstance": "eventId" }
          ] }
      ] }
  ],
  "renderBindings": [
    { "states": ["open"],   "role": "any", "tabId": "home",
      "cardSurfaceFamily": "votePoll", "bindingKind": "primary" },
    { "states": ["closed"], "role": "any", "tabId": "home",
      "cardSurfaceFamily": "votePoll", "bindingKind": "summary" }
  ],
  "instanceDataSchema": {
    "eventId":       { "type": "text", "required": true },
    "candidates":    { "type": "list", "required": true },
    "round":         { "type": "text" },
    "pendingChoice": { "type": "text", "writableBy": "formEntry" },
    "ballots":       { "type": "list", "writableBy": "effect" },
    "outcome":       { "type": "text", "writableBy": "effect" },

    "voteCounts":     { "type": "map",    "formula": "groupCount(ballots, choice)" },
    "totalVotes":     { "type": "number", "formula": "size(ballots)",
                        "labelTemplate": "{value} votes" },
    "winner":         { "type": "text",   "formula": "argMaxKey(voteCounts)" },
    "tiedCandidates": { "type": "list",   "formula": "topKeys(voteCounts)" },
    "isTie":          { "type": "bool",   "formula": "size(tiedCandidates) > 1" }
  }
}
```

---

## P3 — Approval queue (propose → decide)

**Key ideas:** model **both halves** (AP-5). **One** workflow, **two** tabs via role-keyed bindings.
`draft` has no `receiver` binding — unsubmitted drafts are invisible to the approver.

```jsonc
"purchase-proposal": {
  "initialState": "draft",
  "states": {
    "draft":             { "label": "Draft", "editableFields": ["itemName", "reason"] },
    "pending":           { "label": "Awaiting decision", "tone": "info" },
    "changes-requested": { "label": "Changes requested", "tone": "warning",
                           "editableFields": ["itemName", "reason"] },
    "approved":          { "label": "Approved", "tone": "positive", "isTerminal": true },
    "rejected":          { "label": "Rejected", "tone": "negative", "isTerminal": true }
  },
  "transitions": [
    { "id": "submit", "label": "Submit", "icon": "send", "tone": "primary",
      "from": ["draft", "changes-requested"], "to": "pending",
      "guard": { "allowedPersonaIds": ["member"] },
      "effects": [
        { "op": "set", "key": "proposedByPersonaId", "value": "$actor" },
        { "op": "set", "key": "submittedAt",         "value": "$timestamp" }
      ] },
    { "id": "approve", "label": "Approve", "icon": "check_circle", "tone": "primary",
      "from": ["pending"], "to": "approved",
      "guard": { "allowedPersonaIds": ["organizer"] },
      "effects": [ { "op": "set", "key": "decidedByPersonaId", "value": "$actor" } ] },
    { "id": "request-changes", "label": "Request changes", "icon": "undo", "tone": "secondary",
      "from": ["pending"], "to": "changes-requested",
      "guard": { "allowedPersonaIds": ["organizer"] } },
    { "id": "reject", "label": "Reject", "icon": "cancel", "tone": "destructive",
      "from": ["pending"], "to": "rejected",
      "guard": { "allowedPersonaIds": ["organizer"] } }
  ],
  "renderBindings": [
    { "states": ["draft", "changes-requested"], "role": "actor", "tabId": "home",
      "cardSurfaceFamily": "formEntry", "bindingKind": "primary" },
    { "states": ["pending", "approved", "rejected"], "role": "actor", "tabId": "home",
      "cardSurfaceFamily": "statusTimeline", "bindingKind": "summary" },
    { "states": ["pending"], "role": "receiver", "tabId": "admin",
      "cardSurfaceFamily": "approvalQueueItem", "bindingKind": "primary" }
  ],
  "instanceDataSchema": {
    "itemName": { "type": "text",     "required": true, "writableBy": "formEntry",
                  "labelTemplate": "{value}" },
    "reason":   { "type": "textarea", "required": true, "writableBy": "formEntry",
                  "maxLength": 500 },
    "proposedByPersonaId": { "type": "personaId?", "writableBy": "effect",
                             "displayIcon": "person_outline",
                             "labelTemplate": "Proposed by {value}", "hideWhenEmpty": true },
    "submittedAt":         { "type": "date?", "writableBy": "effect", "sortable": true },
    "decidedByPersonaId":  { "type": "personaId?", "writableBy": "effect",
                             "hideWhenEmpty": true }
  }
}
```

> ⚠️ **Creating a *brand-new* draft from blank** is a `renderBindings[].actions[]` entry
> (`kind: "create"`, `scope: "tab"`) — see [`07-actions-and-fabs.md`](./07-actions-and-fabs.md) and
> [`render-bindings.md`](../reference/render-bindings.md). Do not seed a placeholder draft instead (AP-13).

---

## P4 — Loan lifecycle with queue

**Key ideas:** availability and the queue are **data, not states** (AP-1). Borrowing requires a
**cross-workflow guard** (dues paid). Paired `actorInList` guards drive Join vs Leave.

```jsonc
"equipment-loan": {
  "initialState": "published",
  "states": {
    "published": { "label": "In library", "tone": "positive" },
    "delisted":  { "label": "Delisted", "isTerminal": true }
  },
  "transitions": [
    { "id": "borrow", "label": "Borrow", "icon": "arrow_forward", "tone": "primary",
      "from": ["published"], "to": null,
      "guard": {
        "allowedPersonaIds": ["member"],
        "instanceDataEquals": { "key": "availabilityState", "value": "available" },
        "requiresWorkflowsComplete": ["dues-payment"]
      },
      "effects": [
        { "op": "set", "key": "availabilityState", "value": "onLoan" },
        { "op": "set", "key": "holderPersonaId",   "value": "$actor" }
      ] },
    { "id": "join-queue", "label": "Join queue", "tone": "secondary",
      "from": ["published"], "to": null,
      "guard": { "allowedPersonaIds": ["member"],
                 "actorInList": { "key": "queuedPersonaIds", "present": false } },
      "effects": [ { "op": "appendUnique", "key": "queuedPersonaIds", "value": "$actor" } ] },
    { "id": "leave-queue", "label": "Leave queue", "tone": "secondary",
      "from": ["published"], "to": null,
      "guard": { "allowedPersonaIds": ["member"],
                 "actorInList": { "key": "queuedPersonaIds", "present": true } },
      "effects": [ { "op": "removeValue", "key": "queuedPersonaIds", "value": "$actor" } ] },
    { "id": "return", "label": "Return", "tone": "primary",
      "from": ["published"], "to": null,
      "guard": { "allowedPersonaIds": ["member", "organizer"],
                 "instanceDataEquals": { "key": "availabilityState", "value": "onLoan" } },
      "effects": [
        { "op": "set", "key": "availabilityState", "value": "available" },
        { "op": "set", "key": "holderPersonaId",   "value": null }
      ] }
  ],
  "renderBindings": [
    { "states": ["published"], "role": "any", "tabId": "marketplace",
      "cardSurfaceFamily": "equipment-loan", "bindingKind": "primary" }
  ],
  "instanceDataSchema": {
    "title":     { "type": "text", "required": true, "writableBy": "formEntry",
                   "searchable": true, "sortable": true, "labelTemplate": "{value}",
                   "displayContexts": ["tile", "detail"] },
    "condition": { "type": "text", "writableBy": "formEntry",
                   "displayIcon": "verified_outlined", "displayContexts": ["detail"] },
    "availabilityState": { "type": "text",       "writableBy": "effect" },
    "holderPersonaId":   { "type": "personaId?", "writableBy": "effect",
                           "displayIcon": "person_outline",
                           "labelTemplate": "Holder: {value}", "hideWhenEmpty": true },
    "queuedPersonaIds":  { "type": "personaId[]","writableBy": "effect",
                           "displayIcon": "groups_outlined",
                           "labelTemplate": "Queue: {value.length}", "hideWhenEmpty": true },

    "queueLength": { "type": "number", "formula": "size(queuedPersonaIds)" },
    "isAvailable": { "type": "bool",   "formula": "availabilityState == 'available'" }
  }
}
```

---

## P5 — Payment

**Key ideas:** terminal `paid` state — which is what a `requiresWorkflowsComplete` guard elsewhere reads.

```jsonc
"dues-payment": {
  "initialState": "unpaid",
  "states": {
    "unpaid": { "label": "Unpaid", "tone": "warning" },
    "paid":   { "label": "Paid", "tone": "positive", "isTerminal": true }
  },
  "transitions": [
    { "id": "pay", "label": "Pay $15", "icon": "payments_outlined", "tone": "primary",
      "from": ["unpaid"], "to": "paid",
      "guard": { "allowedPersonaIds": ["member"] },
      "effects": [
        { "op": "set", "key": "receiptStatus", "value": "complete" },
        { "op": "set", "key": "paidAt",        "value": "$timestamp" }
      ] }
  ],
  "renderBindings": [
    { "states": ["unpaid", "paid"], "role": "actor", "tabId": "giving",
      "cardSurfaceFamily": "paymentCheckout", "bindingKind": "primary" }
  ],
  "instanceDataSchema": {
    "amountLabel":   { "type": "text", "required": true, "displayIcon": "payments_outlined",
                       "labelTemplate": "{value}" },
    "purpose":       { "type": "text", "required": true, "displayIcon": "receipt_long" },
    "receiptStatus": { "type": "text",  "writableBy": "effect" },
    "paidAt":        { "type": "date?", "writableBy": "effect", "hideWhenEmpty": true }
  }
}
```

> ⚠️ **Do not fabricate a receipt id.** Payment processing and ID generation are
> [platform services](../reference/platform-services.md) — they cannot be JSON. Omit and report, or use
> the service if it exists. A hardcoded receipt id is AP-6.

---

## P6 — Discussion thread

**Key ideas:** the message list is **data**; posting is an orthogonal `append`. `discussionThread` is a
real, fully-supported generic archetype (`archetypes/README.md`) — this pattern itself is still correct
and in active use across 6 shipped communities.

> ⚠️ **Never bind it (or anything else) to `tabId: "messages"` — see [AP-14](./03-antipatterns.md#ap-14--authoring-a-custom-messaging-workflow-or-a-messages-render-binding-locked-2026-08-16).**
> `messages` is a fixed, system-provided App Shell tab, same as `home` — no community-authored workflow
> content backs it, ever. Bind a `discussionThread` instance to a real, community-declared tab instead
> (`"discussions"` below is illustrative — pick whatever name fits the product doc's own vocabulary, and
> declare it in `appShell.tabs[]` like any other custom tab per pattern 8 in `20-solved-patterns.md`).
> Some older shipped communities still bind `discussionThread` to `tabId: "messages"` — that is legacy
> content pending a separate, deferred fix, not something to imitate in new output.

```jsonc
"discussion-thread": {
  "initialState": "open",
  "states": {
    "open":     { "label": "Open", "tone": "positive", "editableFields": ["pendingMessage"] },
    "archived": { "label": "Archived", "isTerminal": true }
  },
  "transitions": [
    { "id": "post-message", "label": "Post", "icon": "send", "tone": "primary",
      "from": ["open"], "to": null,
      "guard": { "allowedPersonaIds": ["member", "organizer"] },
      "effects": [
        { "op": "append", "key": "messages",
          "value": { "senderPersonaId": "$actor", "body": "{pendingMessage}",
                     "timestamp": "$timestamp" } },
        { "op": "set", "key": "pendingMessage", "value": "" }
      ] },
    { "id": "archive", "label": "Archive", "tone": "secondary",
      "from": ["open"], "to": "archived",
      "guard": { "allowedPersonaIds": ["member", "organizer"] } }
  ],
  "renderBindings": [
    { "states": ["open"], "role": "any", "tabId": "discussions",
      "cardSurfaceFamily": "discussionThread", "bindingKind": "primary" }
  ],
  "instanceDataSchema": {
    "subject":        { "type": "text", "required": true, "writableBy": "formEntry",
                        "searchable": true, "labelTemplate": "{value}" },
    "participantPersonaIds": { "type": "personaId[]" },
    "messages":       { "type": "list", "writableBy": "effect" },
    "pendingMessage": { "type": "text", "writableBy": "formEntry" },
    "messageCount":   { "type": "number", "formula": "size(messages)",
                        "displayIcon": "forum", "labelTemplate": "{value}" }
  }
}
```

Remember the corresponding `appShell.tabs[]` entry for `"discussions"` (or whatever real tabId you chose)
— see pattern 8.

> ⚠️ **Starting a *new* thread** is the same tab-scoped `actions[]` create affordance as P3 — see
> [`07-actions-and-fabs.md`](./07-actions-and-fabs.md).

---

## Composing patterns

Real communities **link** patterns:

| Link | How |
|---|---|
| Ballot eligibility ← RSVP | `relatedListMembership` on the ballot reads the event's `goingPersonaIds` |
| Ballot result → Event | Cross-instance `set` writes `selectedOption` onto the event |
| Borrowing ← Dues | `requiresWorkflowsComplete: ["dues-payment"]` on `borrow` |
| Runoff ← Ballot | `branch` + `createInstance` spawns a new ballot |

See [`communities/tabletop-club.md`](../communities/tabletop-club.md) for all four, wired together.
