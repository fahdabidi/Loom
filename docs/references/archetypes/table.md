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

# `table`

Rows in a grid.

Used directly by 1 community (Riverside Youth Soccer's roster) with 9 community-defined transitions.
Chess Club's rankings pair it with `formEntry`.

Contract summary: [`CONTRACTS.md`](./CONTRACTS.md).

## 1. `table` is generic, despite the grid

This is the archetype most often mistaken for a bespoke one, and the mistake has already been made once
in this repo's own specification.

`table` has **no dispatcher case**. It falls through to `GenericWorkflowInstanceCard` like every other
generic family. Its only special treatment is **list layout**: `part32` groups sibling `table` bindings
into one `WorkflowTableArchetypeCard` per `(tabId, workflowType)`.

**A tabular layout is not a semantic contract.** An earlier draft of `permissions.md` listed `table` as
a seventh bespoke family with a two-action vocabulary, `view` and `publish`. The corpus disproved it:
13 `table` transitions exist -- applying consent, redacting fields, archiving roster rows, requesting
guardian updates, revising and discarding ranking drafts -- and only `publish-ranking` fits either
action.

## 2. Actions

**None named.** Derives structurally.

## 3. Bookkeeping

**None.**

## 4. Visibility

Model: **`roles` + `owner`**.

Riverside's roster rows are guardian-scoped, expressed today with `actorEqualsField` guards -- a
per-instance check the workflow engine resolves, not a role permission.

## 5. Community-defined actions

**The norm**, and they are substantial: `apply-private-consent`, `apply-shared-consent`,
`redact-fields`, `undo-last-redaction-change`, `archive-roster-row`, `request-guardian-update`,
`apply-correction-request`, `save-roster-update`, `mark-waiver-acknowledged`.

Consent and redaction are real privacy operations on minors' data. They derive `advance` and
`terminate` structurally, which expresses *may edit the roster* but not *may redact specifically*.

## 6. Open

- **Redaction may deserve promotion.** If Riverside needs "may correct a row" separated from "may
  redact a minor's fields", that is precisely the signal `permissions.md` section 5 describes for
  promoting a family to bespoke -- not a reason to complicate the generic path.
