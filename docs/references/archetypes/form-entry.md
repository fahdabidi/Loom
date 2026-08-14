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
