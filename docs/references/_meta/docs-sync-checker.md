---
spec: 4
doc_version: 1.0.0
status: current
last_verified: 2026-07-14
---

# Docs-sync checker — tool specification

**Status: specified, NOT built.** This document is the spec for the tool that turns the version
convention into an enforced gate. Until it exists, sync is maintained by hand and *will* drift — the
whole reason `docs/CardSurfaces/*.md` still documents a `CommunityVoteApi` that never existed.

## What it does

Fails the build when a doc in `docs/references/` has drifted from the specification.

## Checks

### 1. Frontmatter present and well-formed
Every `.md` under `docs/references/` must open with YAML frontmatter carrying `spec`, `doc_version`,
`status`, `last_verified`.
→ `missing_frontmatter` / `malformed_frontmatter` (**error**)

### 2. Doc spec version matches the current spec
Each doc's `spec` must equal `spec-version.json` → `current`, unless the doc's `status` is `draft` or
`planned`.
→ `stale_doc` (**error**), message naming which layer drifted and by how much.

*This is the core check.* It is what makes a grammar bump physically unable to ship with stale docs.

### 3. Manifest and reality agree
- Every `.md` on disk has an entry in `doc-manifest.json`. → `unlisted_doc` (**error**)
  *(Catches a doc added without registering it — it would otherwise escape every other check.)*
- Every manifest entry with `status != planned` exists on disk. → `missing_doc` (**error**)
- Each entry's `syncedTo` matches the doc's own frontmatter `spec`. → `manifest_mismatch` (**error**)

### 4. `derivedFrom` sources still exist
Every path in a manifest entry's `derivedFrom` resolves. → `dangling_source` (**error**)

*Cheap, high value:* if `workflow_models.dart` is renamed or moved, every doc claiming to derive from it
is now unverifiable, and this catches it immediately rather than six months later.

### 5. Code-drift warning (heuristic)
If any `derivedFrom` file's git mtime is **newer** than the doc's `last_verified`, warn.
→ `possible_code_drift` (**warning**)

Deliberately a warning, not an error: an unrelated edit to a big file (`workflow_models.dart`) shouldn't
break the build. But it *should* prompt a human to look. Promote to error with `--strict`.

### 6. Example JSON still validates
Every `.jsonc`/`.json` community package referenced by the docs must pass the community-package
validator at the **current** spec version. → `invalid_example` (**error**)

*This is the one that matters most.* A doc can look perfectly in sync and still teach a shape the engine
rejects. The only proof the docs are right is that their examples actually validate.

### 7. Known gaps are honest
Every `NEEDS IMPLEMENTATION` marker in a reference JSON should correspond to an entry in
`spec-version.json` → `knownGaps`, and vice versa. → `undocumented_gap` / `stale_gap` (**warning**)

*Prevents both directions of lying:* a gap in the JSON nobody tracked, and a "known gap" that was
actually closed months ago and is still sending the Skill down a workaround path.

## CLI

```
dart run loom_ux_judges:docs_sync_checker \
  --references docs/references \
  [--strict]          # promote warnings to errors
  [--output <json>]   # machine-readable report
```

Exit codes: `0` = in sync · `1` = drift found · `64` = usage error.
Report shape: reuse `ValidationReport` / `ValidationFinding` from the existing validator — same
`{type, message, location, isWarning}` findings, same JSON envelope. One report format for every gate.

## Where it runs

1. **CI, on every PR touching `docs/references/` or any `groundedIn` source file.** Non-negotiable —
   this is the only thing standing between us and doc rot.
2. **The publishing flow** ([publishing-flow.md](./publishing-flow.md) step 6) — must be clean before a
   spec change ships.
3. **The Skill's own pre-flight** — the Skill must refuse to author against stale docs. It reads them as
   truth; if they're stale, everything it generates is wrong in a way that's very hard to see.

## Build it when

The tool is small (a few hundred lines: parse frontmatter, compare ints, stat files, shell out to the
package validator). Build it **after tracker-3 Phase A**, once `spec-version.json` flips from
`provisional` to `stable` — before then the spec is expected to move, and a checker screaming about
intentional churn is noise that teaches people to ignore it.

Tracked as a follow-up to Phase A, before Phase 3 (the Skill) starts. **The Skill must not ship without
it.**
