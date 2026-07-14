---
spec: { envelope: 1, experience: 2, grammar: 1 }
doc_version: 1.0.0
status: current
last_verified: 2026-07-14
---

# Versioning policy

Normative. Defines what each version number means, when to bump it, and what "breaking" means.

## Why three version numbers, not one

The three layers change at wildly different rates, and a reader/loader needs to know about each
independently:

| Layer | Field | Changes when… | Rate |
|---|---|---|---|
| **Envelope** | `schemaVersion` (root) | The install wrapper changes (`packageId`, `branding`, `seedDataFiles`…) | Almost never |
| **Experience** | `experience.experienceSchemaVersion` | The *way workflows are declared* changes shape | Rarely — a generational change (v1 shallow → v2 engine-native) |
| **Grammar** | `experience.workflowGrammarVersion` | A state-machine construct is added/changed (a new effect op, a new guard kind, a new field attr) | Most often |

A single version would force a bump of everything whenever the grammar gained one function — making
every existing file spuriously "old". Three numbers keep the blast radius honest.

## What each layer governs

Authoritative definitions live in [`../spec-version.json`](../spec-version.json) → `layers`. Summary:

- **Envelope v1** — the package wrapper. Says nothing about how workflows inside `experience` are
  shaped.
- **Experience v1** — legacy shallow (`workflows[]` flat cards). Cannot express state machines. Seven
  communities still use it; **not** for new work.
- **Experience v2** — engine-native (`workflowDefinitions` + `workflowInstances`). What this whole
  reference tree describes.
- **Grammar v1** — the current state-machine grammar: `states`, `transitions`, `guard` (6 kinds),
  `effects` (9 ops), `renderBindings`, `instanceDataSchema` (13 attrs), formulas (20 functions).

## Breaking vs additive — the bump rule

> **Bump the integer only when a change is breaking. Never bump for an additive change.**

**Additive (do NOT bump):** an existing valid file still parses and behaves identically.
- A new optional field attribute (e.g. adding `placeholder` to `instanceDataSchema`).
- A new formula function.
- A new effect op.
- A new guard kind.
- A new `cardSurfaceFamily` value.

*What you do instead:* record it in [`../CHANGELOG.md`](../CHANGELOG.md) under the current version as an
addition, and update the affected reference doc. The version number stays put.

**Breaking (DO bump):** an existing valid file would now parse wrong, fail, or behave differently.
- Renaming or removing a field (`instanceDataSchema` → `dataSchema`).
- Changing a default (`bindingKind` defaulting to `summary` instead of `primary`).
- Tightening a rule so previously-valid files now fail (making `renderBindings` mandatory).
- Changing an op's semantics (`append` deduping like `appendUnique`).
- Removing a formula function.

**The test:** *take every existing community JSON. Would they all still load and behave identically?*
If no → breaking → bump.

## Unknown versions are a hard error

A loader that meets a version number **higher than it supports must fail loudly**, never
best-effort-parse. Silently ignoring a construct it doesn't understand is how a community ships with a
guard that never fires — the single most dangerous failure mode in this system (a guard that silently
doesn't run looks exactly like a guard that passes).

This is normative, and the validator enforces it:
`unsupported_schema_version` is an **error**, never a warning.

## Every JSON carries all three stamps

No Loom community JSON ships without them:

```jsonc
{
  "schemaVersion": 1,                        // envelope
  "experience": {
    "experienceSchemaVersion": 2,            // experience content
    "workflowGrammarVersion": 1              // state-machine grammar
  }
}
```

An absent `experienceSchemaVersion` is an **error**, not a v1 default. Defaulting would mean a v2 file
that forgot its stamp gets silently parsed as legacy — and every state machine in it silently ignored.

## Docs carry the stamp too

Every markdown doc in `docs/references/` opens with YAML frontmatter:

```yaml
---
spec: { envelope: 1, experience: 2, grammar: 1 }
doc_version: 1.0.0
status: current          # current | stale | draft
last_verified: 2026-07-14
---
```

- `spec` — the specification version the doc **describes**. If it differs from
  [`spec-version.json`](../spec-version.json) → `current`, the doc is **stale**.
- `doc_version` — the doc's own edit version (semver; independent of the spec).
- `status` — `current` (synced + reviewed) · `stale` (spec moved, doc hasn't) · `draft` (never verified).
- `last_verified` — when a human/tool last confirmed the doc against the code.

[`docs-sync-checker.md`](./docs-sync-checker.md) specifies the tool that turns this from a convention
into an enforced gate.

## Provisional status

While [`spec-version.json`](../spec-version.json) says `"status": "provisional"`, version numbers are
**not stable** and may change without a formal bump — because the spec has not yet survived contact with
a running app (tracker-3 Phase A). The publishing flow's full ceremony begins when status flips to
`stable`.
