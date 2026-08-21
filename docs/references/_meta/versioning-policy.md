---
spec: 4
doc_version: 2.2.0
status: current
last_verified: 2026-08-20
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

## Capabilities — what the version number cannot tell you

The bump rule above is correct and it leaves a real hole. Because an additive change does **not**
bump the version, `specVersion: 4` cannot tell you whether a particular build implements a
`cardSurfaceFamily`, effect op or guard kind that was added after that build shipped. Two builds
both honestly claim 4; one renders the package and one silently does not.

That silence is the failure mode this document already names as the most dangerous in the system.
Capabilities close it, by the same rule and for the same reason as an unknown version: **a loader
that meets a capability it does not implement must refuse the package, loudly.**

### Declaring capabilities

A package **may** carry a package-root `requiresCapabilities` array:

```jsonc
{
  "specVersion": 4,
  "requiresCapabilities": ["archetype.searchAiAnswer", "effect.transitionRelated"],
  ...
}
```

Entries are namespaced by what they name:

| Namespace | Names | Example |
|---|---|---|
| `archetype.` | a `cardSurfaceFamily` | `archetype.searchAiAnswer` |
| `effect.` | an effect `op` | `effect.transitionRelated` |
| `guard.` | a guard kind | `guard.relatedListMembership` |
| `formula.` | a formula function | `formula.groupCount` |
| `field.` | an `instanceDataSchema` `type` | `field.url` |

### Rules

- **Optional.** An absent `requiresCapabilities` means "nothing beyond the baseline for this
  `specVersion`" — which is what most packages will honestly be.
- **Declare only what postdates the baseline.** A capability that shipped *with* a `specVersion`
  is implied by that version and must not be listed. Listing the whole baseline would make every
  package noisy and the array meaningless.
- **Declare everything you actually use** from beyond the baseline. This is the half that makes
  the mechanism worth having.
- **A loader refuses on any entry it does not implement**, naming the entry — never a generic
  failure, and never a best-effort parse. `unsupported_capability` is an **error**.
- **A loader refuses on any entry it does not recognise at all.** An unknown namespace or an
  unknown name is a package written against something newer, which is precisely the case that
  must fail loudly.


### Defining the baseline

The rules above lean on "the baseline for this `specVersion`", and until 2026-08-20 this document
never said what that was. That omission made `undeclared_capability` unimplementable — a rule that
fires when a package uses a post-baseline capability cannot run without knowing where the baseline
sits — so the rule was deliberately left unbuilt rather than guessed at.

**The baseline is a snapshot, not a reconstruction.** It is the set of capabilities the engine,
validator and app shell implemented at the moment `specVersion: 4` was declared baselined, recorded
explicitly. It is not derived from the `NEW <date>` strings scattered through `spec-version.json`:
those are per-feature prose, written inconsistently, and reading them as a machine-readable history
would be inventing precision that was never there.

Concretely:

- `spec-version.json` gains a `capabilityBaseline` object: the version it belongs to, the date it
  was snapshotted, and the capability names in the same namespaced form `requiresCapabilities` uses
  (`archetype.*`, `effect.*`, `guard.*`, `formula.*`, `field.*`).
- It is generated from the capability manifests, never hand-maintained — the same rule those
  manifests already follow, and for the same reason: a hand-kept list rots away from what the code
  does.
- A capability **in** the baseline is implied by `specVersion: 4` and must not be declared.
- A capability **added after** the snapshot is post-baseline: a package using it must declare it,
  and `undeclared_capability` fires when it does not.

**Snapshotting now is the honest option, and it has a cost worth stating.** Everything implemented
today lands in the baseline, including capabilities added well after specVersion 4 was first
released. So `undeclared_capability` will catch nothing until the next capability ships. The
alternative — reconstructing which features predate the release — would require archaeology across
inconsistent prose, and a wrong reconstruction is worse than a late start: it would demand
declarations for capabilities that are actually implied, and every author would learn to add
whatever the validator asked for without meaning it.

The rule earns its keep from the next capability onward. That is late, not useless.

### The validator keeps the declaration honest

A declaration nothing checks will rot, exactly as the three-number scheme did. So the validator
enforces both directions:

- A package that **uses** a post-baseline capability without declaring it → error
  (`undeclared_capability`). Without this the array is optional in practice as well as in
  principle, and nobody fills it in.
- A package that **declares** a capability it never uses → error (`unused_capability`). Without
  this, declarations accumulate defensively until they mean nothing.

Both are errors rather than warnings for the reason stated at the top of this section: the
alternative is silent divergence between what a package needs and what a build provides.

### What this is not

It is **not** a second version number, and it must never be used as one. Capabilities name
individual constructs. If a change is breaking rather than additive, it bumps `specVersion` — the
bump rule is unchanged by any of this.

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
