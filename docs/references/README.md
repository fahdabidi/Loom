---
spec: { envelope: 1, experience: 2, grammar: 1 }
doc_version: 2.0.0
status: current
last_verified: 2026-07-14
audience: llm-agent
---

# Loom Community JSON — Authoring References

**Audience: an LLM agent (the Skill) that authors community JSON. Not a human tutorial.**

This tree is the complete and authoritative context for generating a Loom community as JSON. It is
written to be loaded into an agent's context and acted on directly: complete enumerations, explicit
invariants, decision tables, canonical templates, and an error→fix table.

## AGENT: read this section first

### Hard rules (never violate)

1. **MUST emit `experienceSchemaVersion: 2`** (engine-native). Never author v1 (legacy shallow) for a new
   community.
2. **MUST stamp all three version fields** — `schemaVersion`, `experienceSchemaVersion`,
   `workflowGrammarVersion`. Omission is a hard error, not a default.
3. **MUST NOT emit any key not enumerated in `reference/`.** The parser ignores unknown keys silently —
   an invented key produces a community that looks right and does nothing.
4. **MUST NOT write Dart, or request that Dart be written.** If a requirement seems to need code, it is
   either (a) expressible in the grammar and you have not found it yet — re-read
   `reference/formulas.md` and `reference/effects.md`; or (b) a **platform service**
   (`reference/platform-services.md`); or (c) a genuine grammar gap — **stop and report it**, do not
   invent a workaround.
5. **MUST NOT seed or effect-write a computed (`formula`) field.** Computed fields are derived on read.
6. **MUST pass the validator before emitting.** A community that does not validate is not a deliverable.
   See `guide/05-validation.md`.
7. **MUST NOT invent `cardSurfaceFamily` values.** Only those listed in `archetypes/README.md` exist.
8. **When the grammar cannot express the requirement, say so explicitly.** Never approximate, never
   silently drop a requirement, never substitute a hardcoded value for a computed one.

### Load order (context budget)

| Step | Load | When |
|---|---|---|
| 1 | `guide/01-authoring-procedure.md` | Always — the deterministic algorithm to follow |
| 2 | `reference/workflow-grammar.md` | Always — the contract |
| 3 | `reference/guards.md`, `reference/effects.md`, `reference/formulas.md`, `reference/field-types.md` | Always — the four you will reach for constantly |
| 4 | `guide/03-common-patterns.md` | When the requirement matches a known pattern (usually) |
| 5 | `reference/render-bindings.md` | When deciding where a workflow appears |
| 6 | `archetypes/README.md` | When choosing a `cardSurfaceFamily` |
| 7 | `guide/04-antipatterns.md` | Before emitting — self-check |
| 8 | `guide/05-validation.md` | Before emitting — mandatory gate |
| 9 | `reference/theming.md`, `reference/platform-services.md` | Only when relevant |
| 10 | `communities/` | For a full worked example to pattern-match against |

### Current specification

```json
{ "envelope": 1, "experience": 2, "grammar": 1 }
```

Machine-readable source of truth: [`spec-version.json`](./spec-version.json).
If your `spec` frontmatter differs from that file's `current`, **these docs are stale — stop and report
it.**

### ⚠️ Spec status: PROVISIONAL

The engine-native schema described here **has never been loaded by a running app.** Every construct is
verified against the engine's parser, evaluator, and validator — but the loading pipeline is under
construction (tracker 3, Phase A), and Phase A's review gate is **expected to change this spec.**

Consequence for the agent: **treat generated communities as provisional.** Do not assume a passing
validator means a working app.

---

## Tree map

| Path | Contents |
|---|---|
| `guide/01-authoring-procedure.md` | **The algorithm.** Step-by-step procedure from requirements → validated JSON |
| `guide/02-package-anatomy.md` | Every key of the package, top to bottom |
| `guide/03-common-patterns.md` | Canonical templates: RSVP · ballot · approval queue · loan · payment · thread |
| `guide/04-antipatterns.md` | Detection rules + fixes for known-bad modeling |
| `guide/05-validation.md` | The mandatory gate; full error→fix table |
| `reference/workflow-grammar.md` | Normative: the complete grammar of a workflow definition |
| `reference/field-types.md` | Normative: all field types + display metadata |
| `reference/guards.md` | Normative: all 6 guard kinds |
| `reference/effects.md` | Normative: all 9 effect ops |
| `reference/formulas.md` | Normative: all 20 formula functions |
| `reference/render-bindings.md` | Normative: tabs, roles, binding kinds |
| `reference/theming.md` | Normative: the accent cascade |
| `reference/platform-services.md` | Normative: the closed set of things that cannot be JSON |
| `archetypes/` | Per-archetype JSON shapes + **status** (which are real) |
| `communities/` | Worked reference communities (**all currently UNVETTED**) |
| `_meta/` | Versioning policy, publishing flow, doc manifest, sync-checker spec |

## Superseded — do NOT use for authoring

The agent MUST NOT read these for JSON structure. They describe shapes the runtime does not parse.

| Path | Why it is wrong |
|---|---|
| `docs/CardSurfaces/*.md` (26 files, mirrored 3×) | Zero JSON. Their "API Support" sections reference APIs that **do not exist** (e.g. `CommunityVoteApi`). |
| `Loom_Communities_Workflow_Engine_Archetype_Catalog.md` | Documents a third shape (`{"archetype": "calendarAgenda", …}`) that **no code parses**. Self-labelled "not implemented". |
| `.../examples/*/loom.initialization.json` | Legacy shallow schema (`experienceSchemaVersion: 1`). Cannot express state machines. |
