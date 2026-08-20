---
spec: 4
doc_version: 1.0.0
status: partially-approved
last_verified: 2026-08-19
audience: llm-agent
---

# Spec-version compatibility — binding the app to the JSON it renders

**Status: proposed, not built.** Written 2026-08-19 at the user's direction ("everything is
connected to the JSON specification version and we need to make strong links"). The evidence
below is measured, not estimated.

## What already works, and is the pattern to copy

`docs/references/spec-version.json` is the declared source of truth for the specification
version (`current: 4`). Every document under `docs/references/**` carries a `spec:` stamp in
its frontmatter, and **`DocsSyncChecker` runs as a test** that fails when a doc's stamp drifts
from `current`.

That is exactly the right shape: one source of truth, a stamp on each participant, and a test
that fails on drift. It exists for **documents only**. Nothing equivalent binds the *code*.

`spec-version.json` is also explicit about why this matters — the three-number scheme it
replaced "was a convention that nothing executed, and it drifted three times."

## The gap, measured

### Three independent literals, no common source

| Component | Declares | Form |
|---|---|---|
| Validator | `supportedSpecVersions = <int>{4}` | named constant |
| Workflow service | `supportedWorkflowSpecVersions = <int>{4}` | named constant |
| App shell | `if (specVersion != 4)` | **bare literal** |
| Archetype Dart code | — | nothing |
| Tab / FAB code | — | nothing |
| Backend APIs (Java) | — | separate repo, vendors its own vocabulary |
| Authoring Skill | — | nothing |

Three hardcoded `4`s that can drift from each other and from `spec-version.json`, plus four
participants that make no statement at all.

### Real drift exists today, in both directions

The app shell hardcodes 26 distinct `tabId` literals. The shipped corpus declares 15. Comparing:

- **Declared by a shipped community, absent from the shell's hardcoded set:** `organize`,
  `resources`, `team`
- **Hardcoded in the shell, used by no shipped community:** `audience`, `coach`, `details`,
  `export`, `form`, `library`, `matches`, `notifications`, `payments`, `preferences`,
  `rankings`, `registration`, `roster`, `schedule`, `search`, `timeline`

Nothing tests this correspondence in either direction.

### Why a version number alone cannot fix it

`spec-version.json`'s own bump rule says additive changes do **not** bump the version: "a new
formula function, effect op, guard kind, or cardSurfaceFamily does not bump."

That rule is correct — without it every file goes spuriously stale. But it means
**`specVersion: 4` cannot tell you whether a given app-shell build supports a `cardSurfaceFamily`
added last week.** Two builds both honestly claim v4; one renders the package and one does not.
This is the precise gap the version stamp does not close, and it is why capability declarations
are needed alongside it rather than instead of it.

## Proposal

### Layer 1 — one generated constant

Generate a Dart constant from `spec-version.json` (`kLoomSpecVersion`, `kSupportedSpecVersions`).
Every component imports it; no component writes its own literal. A test fails on any bare
spec-version literal outside the generated file.

Cheap, mechanical, removes the three-literal drift class entirely.

### Layer 2 — each component declares what it implements

A version number says *which contract*; a capability manifest says *how much of it*. Each
participant declares its own, as ordinary Dart constants that tests can read:

- **App shell** — `cardSurfaceFamily` values it can render, `tabId` values it recognises, FAB
  styles, presentation modes
- **Validator** — finding codes it can emit, families that require `action`
- **Workflow service** — effect ops, guard kinds, formula functions
- **Skill** — the reference documents it fetches

### Layer 3 — conformance tests that cross-check manifest against docs and corpus

This is the layer that turns "we believe these match" into a failing build. Each is a real test:

1. Every `cardSurfaceFamily` in `archetypes/README.md` is either bespoke-dispatched or
   explicitly listed as generic-rendered — **no family renders by accident**.
2. Every `tabId` any shipped package declares is recognised by the shell. *(Would have caught
   `organize` / `resources` / `team`.)*
3. Every finding code documented in `05-validation.md` exists in the validator, and vice versa.
4. Every effect op and guard kind in the reference docs is implemented by the engine.
5. No spec-version literal exists outside the Layer 1 generated constant.

Checks 1-4 are the same shape as `DocsSyncChecker`, pointed at code instead of frontmatter.

### Layer 4 — packages declare the capabilities they use (needs a spec decision)

Layers 1-3 catch drift between *our own* components at build time. They do not answer the
runtime question: *can this specific app-shell build render this specific package?*

Proposal: a package declares what it actually needs.

```jsonc
{
  "specVersion": 4,
  "requiresCapabilities": ["archetype.searchAiAnswer", "effect.transitionRelated"]
}
```

The shell refuses to install a package naming a capability it lacks, with a precise message,
instead of rendering it wrongly. This closes the additive-change gap the bump rule leaves open,
and it fails loudly rather than silently — the failure mode that has cost the most on this
project.

**Approved by the user 2026-08-19 and now specified** in `docs/references/_meta/versioning-policy.md`
(section "Capabilities — what the version number cannot tell you"), which the authoring Skill already
fetches. Implementation — validator rules `unsupported_capability`, `undeclared_capability` and
`unused_capability`, plus the loader refusal — is a ticket, staged behind the specVersion-4-only cut.

## Sequencing

Layers 1-3 should land **with the specVersion-4-only cut**, not before it. After that cut every
component is v4-only, so the manifests are simple statements of fact rather than descriptions of
a straddle. Attempting them mid-migration would mean encoding a moving target.

Layer 4 needs the decision above first.

## Known related items already in the queue

All three are instances of the same defect — the shell inferring a JSON-authored identifier
from a literal compiled into it — and all three are what Layer 3 would catch:

- 73 hardcoded `tabId == '…'` comparisons across 8 files
- `Calendar` hardcodes the transition id `send-reminder`; four communities declare something
  else and silently get no reminder
- `responseTable`'s member field is inferred as `personaId`
