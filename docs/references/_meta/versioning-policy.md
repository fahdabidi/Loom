---
spec: 4
doc_version: 2.0.0
status: current
last_verified: 2026-08-14
---

# Versioning policy

Normative. Defines what the version number means, when to bump it, and what "breaking" means.

## One version for the whole specification

A Loom community package carries exactly one version stamp, at its root:

```jsonc
{
  "specVersion": 4,
  "packageId": "...",
  "experience": { ... },
  "appShell": { ... }
}
```

`specVersion` governs **everything in the package** — the install wrapper, the way workflows are
declared, the state-machine grammar, and the app-shell block. A change to any component is a change to
the specification, and bumps the specification.

The authoritative value lives in [`../spec-version.json`](../spec-version.json) → `current`.

### Why this replaced three numbers

Until specVersion 4 a package carried three independent stamps: `schemaVersion` (envelope),
`experience.experienceSchemaVersion`, and `experience.workflowGrammarVersion`. The reasoning was that
the layers change at different rates, so a single number would make every file spuriously "old"
whenever the grammar gained one function.

The reasoning was sound and the outcome was still bad, because nothing enforced it.
[`docs-sync-checker.md`](./docs-sync-checker.md) specified the gate and opened with *"Status: specified,
NOT built … Until it exists, sync is maintained by hand and will drift."* It was never built. The
prediction came true three times:

- `docs/CardSurfaces/*.md` documented a `CommunityVoteApi` that had been deleted.
- **Grammar 2 was never declared by anything.** The `actions[]`-replaces-`creatable` break shipped into
  every fixture's content — 68 `actions`, zero `creatable` — while all thirteen packages went on
  declaring `workflowGrammarVersion: 1` for four months. The validator's `supportedGrammarVersions` was
  `{1}`, so the only value it accepted was the stale one.
- The `roleId`/`fanId` identity split renamed keys in all three layers while bumping only the grammar,
  because most of the renames landed there. `experience.personas[]` is a sibling of
  `workflowDefinitions`, and `appShell` is a root key outside `experience` entirely.

Three numbers gave three chances to forget. The third case is the decisive one: the split was
*correctly* a breaking change to all three layers, and getting that right required knowing which of
three fields owned each key — a question with no obvious answer and no tool to check it.

One number cannot be under-declared. The "spuriously old" cost is avoided by the bump rule below, not
by splitting the number: additive changes still do not bump.

## Breaking vs additive — the bump rule

> **Bump only when a change is breaking. Never bump for an additive change.**

**Additive (do NOT bump):** an existing valid file still parses and behaves identically.

- A new optional field attribute (e.g. adding `placeholder` to `instanceDataSchema`).
- A new formula function, effect op, guard kind, or `cardSurfaceFamily` value.

*What you do instead:* record it in [`../CHANGELOG.md`](../CHANGELOG.md) under the current version as an
addition, and update the affected reference doc. The version stays put.

**Breaking (DO bump):** an existing valid file would now parse wrong, fail, or behave differently.

- Renaming or removing a field (`personaId` → `fanId`).
- Changing a default (`bindingKind` defaulting to `summary` instead of `primary`).
- Tightening a rule so previously-valid files now fail (making `renderBindings` mandatory).
- Changing an op's semantics (`append` deduping like `appendUnique`).
- Removing a formula function.

**The test:** *take every existing community JSON. Would they all still load and behave identically?*
If no → breaking → bump.

## Unknown versions are a hard error

A loader that meets a version number **higher than it supports must fail loudly**, never
best-effort-parse. Silently ignoring a construct it doesn't understand is how a community ships with a
guard that never fires — the single most dangerous failure mode in this system, because a guard that
silently doesn't run looks exactly like a guard that passes.

This is normative, and the validator enforces it: `unsupported_schema_version` is an **error**, never a
warning.

An **absent** `specVersion` is likewise an error, not a default. Defaulting would mean a package that
forgot its stamp gets parsed as whatever the loader assumes — and the grammar-2 incident above is
exactly what that looks like in practice.

## Docs carry the stamp too

Every markdown doc in `docs/references/` opens with YAML frontmatter:

```yaml
---
spec: 4
doc_version: 1.0.0
status: current          # current | stale | draft
last_verified: 2026-08-14
---
```

- `spec` — the specification version the doc **describes**. If it differs from
  [`spec-version.json`](../spec-version.json) → `current`, the doc is **stale**.
- `doc_version` — the doc's own edit version (semver; independent of the spec).
- `status` — `current` (synced + reviewed) · `stale` (spec moved, doc hasn't) · `draft` (never verified).
- `last_verified` — when a human or tool last confirmed the doc against the code.

This is now an **enforced gate, not a convention**: `DocsSyncChecker`
(`app/packages/tooling/loom_ux_judges/lib/src/validator/docs_sync_checker.dart`) runs as a test and
fails on a doc that drifts, a doc missing from the manifest, a manifest entry whose file is gone, a
`derivedFrom` source that has moved, or a package on the wrong version. Its own tests inject each of
those faults to prove the gate catches them — a checker that never fails is indistinguishable from the
four months in which there was none.

## Migrating off the legacy stamps

`spec-version.json` → `pendingMigration` lists the surfaces still carrying the three old fields. The
checker treats an entry there as a known exception and everything else as a failure, so the list is
enforced debt: it must shrink to empty, and cannot be closed by forgetting about it.

## Provisional status

While [`spec-version.json`](../spec-version.json) says `"status": "provisional"`, version numbers are
**not stable** and may change without a formal bump — because the spec has not yet survived contact with
a running app (tracker-3 Phase A). The publishing flow's full ceremony begins when status flips to
`stable`.
