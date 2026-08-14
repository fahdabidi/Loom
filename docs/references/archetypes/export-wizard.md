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

# `exportWizard`

A long-running export, transfer or replay, with a preview step, a redaction review, and an outcome to
record.

Used by 6 communities. **All 14 of its workflows declare `visibility: guarded`** -- the only archetype
with a uniform guarded default, and it fits: an export contains whatever the exporter could read.

Contract summary: [`CONTRACTS.md`](./CONTRACTS.md).

## 1. Actions

Eleven. Permission ids are `export_wizard.<action>`.

| Group | Actions |
|---|---|
| Setup | `configure_scope` - `preview` |
| Review | `approve_redaction` |
| Execution | `run` - `retry` - `cancel` |
| Delivery | `download` - `decide_transfer` |
| Undo | `rollback` |
| Bookkeeping | `record_outcome` |
| Reading | `view` |

**`record_outcome` deliberately covers the state-machine bookkeeping** -- `record-*`, `fail-*`,
`complete-*`, `mark-*`, `retire-*`. These are usually platform- or admin-recorded rather than
member-invoked, and grouping them keeps the member-facing vocabulary honest.

Four lookalike pairs resolve by the precedence rules in `permissions.md` section 4, and are worth
stating because the rule alone is easy to misread:

| Transition | Action | Not |
|---|---|---|
| `start-preview-export` | `preview` | `run` -- the longer pattern wins |
| `start-transfer-rollback` | `rollback` | `run` -- literal beats pattern |
| `complete-transfer-rollback` | `rollback` | `record_outcome` |
| `cancel-transfer-rollback` | `cancel` | it really does cancel the rollback |

`confirm-*` has **no pattern at all**: its three occurrences land in three different actions.

## 2. Bookkeeping

**None per-person.** Export state is per-instance, not per-viewer. This is the only bespoke archetype
with no bookkeeping clause.

## 3. Visibility

Model: **`roles` + `owner`**. An export is owned by whoever ran it.

Data Portability Community is the extreme case: 9 workflows, 80 transitions, every one `guarded`. That
community exists to exercise export/transfer semantics, and its shape is why the vocabulary carries 11
actions rather than 4.

## 4. Community-defined actions

Permitted. None in the corpus -- all 80 Data Portability transitions map to the vocabulary, which is
what made it possible to widen that vocabulary from evidence rather than invention.

## 5. Open

- **`record-download` means different things in different families.** In `exportWizard` it is
  `record_outcome` (the owner recording that a download happened); in `documentLibrary` it is
  `download`. Both are correct per family, but a reader moving between them will be surprised.
