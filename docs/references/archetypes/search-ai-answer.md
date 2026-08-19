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

# `searchAiAnswer`

A member asks a question; the community curates an answer, cites sources, and moderates what shows.

Used by 2 communities: Masjid Nur and Neighborhood Book Club.

Contract summary: [`CONTRACTS.md`](./CONTRACTS.md).

## 1. Actions

Seven. Permission ids are `search_ai_answer.<action>`.

| Action | Meaning |
|---|---|
| `ask` | submit or refine a query |
| `withdraw_query` | take back your own question |
| `curate` | write or revise the answer, including digests |
| `add_citation` | attach a source |
| `report` | flag a stale or wrong citation |
| `moderate` | act on someone else's contribution |
| `view` | read-only |

**`moderate` is deliberately separate from `curate`.** Hiding a search source and reopening a reported
question act on **other members'** contributions; writing your own curated answer does not. Collapsing
them would grant every curator moderation power over other people's content.

**`curate` covers digests.** Book Club's `edit-digest` and `save-digest` are curated output and the
capability is the same one -- a separate action would have split a single privilege in two.

## 2. Bookkeeping the archetype owns

`savedFanIds` -- who saved this answer.

## 3. Visibility

Model: **`roles` + `owner`**. The asker always reads their own query.

Both communities declare `membersOnly`.

## 4. Community-defined actions

Permitted. None in the corpus.

## 5. Open

- **Platform-service gap.** `searchAiAnswer` carries one unimplemented platform-service field (see
  `platform-services.md`). The archetype contract does not depend on it, but a community authoring
  against this archetype should know the surface is not fully live.

## 6. Worked example

Bespoke, so every transition declares an `action` from the seven in §1. Note that `savedFanIds` is
**not** declared — the archetype owns it.

```jsonc
"club-question-answer": {
  "initialState": "asked",
  "visibility": { "default": "membersOnly" },

  "instanceDataSchema": {
    "questionText":   { "type": "textarea", "required": true },
    "answerText":     { "type": "textarea" },
    "citations":      { "type": "list", "labelTemplate": "Sources: {value.length}" },
    "createdByFanId": { "type": "fanId", "required": true }
    // savedFanIds is NOT declared -- section 2, the archetype maintains it.
  },

  "states": {
    "asked":     { "label": "Awaiting an answer", "tone": "info",
                   "editableFields": ["questionText"],
                   "editGuard": { "actorEqualsField": { "key": "createdByFanId" } } },
    "answered":  { "label": "Answered", "tone": "positive" },
    "hidden":    { "label": "Hidden by a moderator", "tone": "warning" },
    "withdrawn": { "label": "Withdrawn", "tone": "neutral", "isTerminal": true }
  },

  "transitions": [
    { "id": "refine-question", "action": "ask", "label": "Refine question",
      "from": ["asked"], "to": null,
      "guard": { "actorEqualsField": { "key": "createdByFanId" } },
      "inputs": { "questionText": { "type": "textarea", "required": true } },
      "effects": [ { "op": "set", "key": "questionText",
                     "value": "{input.questionText}" } ] },

    { "id": "withdraw-question", "action": "withdraw_query", "label": "Withdraw",
      "tone": "destructive", "from": ["asked"], "to": "withdrawn",
      "guard": { "actorEqualsField": { "key": "createdByFanId" } } },

    { "id": "write-answer", "action": "curate", "label": "Write answer",
      "from": ["asked", "answered"], "to": "answered",
      "guard": { "allowedRoleIds": ["club-curator"] },
      "inputs": { "answerText": { "type": "textarea", "required": true } },
      "effects": [ { "op": "set", "key": "answerText",
                     "value": "{input.answerText}" } ] },

    { "id": "attach-source", "action": "add_citation", "label": "Add a source",
      "from": ["answered"], "to": null,
      "guard": { "allowedRoleIds": ["club-curator"] },
      "effects": [ { "op": "append", "key": "citations",
                     "value": "{input.citationUrl}" } ],
      "inputs": { "citationUrl": { "type": "url", "required": true } } },

    { "id": "hide-answer", "action": "moderate", "label": "Hide",
      "from": ["answered"], "to": "hidden",
      "guard": { "allowedRoleIds": ["club-moderator"] } }
  ],

  "renderBindings": [
    { "tabId": "search", "audience": "any",
      "cardSurfaceFamily": "searchAiAnswer", "bindingKind": "primary",
      "states": ["asked", "answered", "hidden", "withdrawn"],
      "actions": [ { "kind": "create", "label": "Ask a question" } ] }
  ]
}
```

### Why each part is the way it is

- **`curate` and `moderate` are different actions on different roles.** §1: hiding someone else's
  answer acts on another member's contribution; writing your own does not. Giving `write-answer` the
  `moderate` action would hand every curator moderation power.
- **`refine-question` is `ask`, not `curate`.** The asker refining their own query is the same
  capability as asking it.
- **`savedFanIds` is absent from the schema.** §2 — the archetype maintains it. Declaring it would
  duplicate archetype logic and is the mistake `CONTRACTS.md` warns about.
- **The asker keeps `withdraw_query`, guarded by `actorEqualsField`.** A role list cannot express
  "the person who asked this".
- **`hidden` is not terminal.** Moderation is reversible; a terminal `hidden` would make reopening a
  reported question impossible, and `moderate` explicitly covers reopening (§1).

### What not to do

- Do not fabricate the answer. A curated answer is written by a member through `curate`; a
  *platform-generated* AI answer is a platform service (`platform-services.md`) — declare the field
  and leave it unwritten rather than seeding a plausible-looking one.
- Do not fold `moderate` into `curate` to reduce the vocabulary. It splits a real privilege boundary.
