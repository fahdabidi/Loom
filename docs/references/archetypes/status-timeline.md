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

# `statusTimeline`

A read-mostly view of where something stands.

Used by 2 communities directly, with only 4 community-defined transitions -- but it is the most common
**secondary** binding in the corpus: 8 of Data Portability's 9 workflows pair a `statusTimeline`
summary with an `exportWizard` primary.

Contract summary: [`CONTRACTS.md`](./CONTRACTS.md).

## 1. Actions

**None named.** Derives structurally.

Most `statusTimeline` bindings carry no transitions at all -- they render state, and the actions live
on the workflow's primary binding.

## 2. Bookkeeping

**None.**

## 3. Visibility

Model: **`roles`**, and in practice it inherits its workflow's model, because it is usually a second
binding on a workflow whose primary surface is something else.

## 4. Why it matters more than its usage count suggests

`statusTimeline` is the archetype that makes **mixed-family workflows normal**. A workflow rendering
`exportWizard` on an admin tab and `statusTimeline` on a home tab names two families and is completely
unambiguous -- only one is bespoke.

An earlier draft of `permissions.md` section 8 made *any* disagreement among a workflow's bindings an
error. Measured against the corpus, that rule rejected **27 workflows**, 26 of them wrongly -- and most
of those 26 were a bespoke primary paired with a `statusTimeline` summary.

## 5. Community-defined actions

**The norm.** `acknowledge`, `deactivate`, `mark-audited`, `review-completion`.

## 6. Open

- **Whether a summary binding should declare its own visibility**, separate from the workflow's primary
  surface. Today it cannot, which is why a `guarded` export shows a `guarded` timeline even where a
  community might want the timeline visible more widely.
