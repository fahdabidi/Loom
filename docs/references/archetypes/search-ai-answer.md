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
