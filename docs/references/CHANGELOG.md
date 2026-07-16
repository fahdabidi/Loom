---
spec: { envelope: 1, experience: 2, grammar: 1 }
doc_version: 1.1.0
status: current
last_verified: 2026-07-16
---

# Specification changelog

Every change to the Loom community-JSON specification. Newest first.

Format per entry: **what changed · breaking or additive · what an author must do about it.**
See [_meta/versioning-policy.md](./_meta/versioning-policy.md) for what "breaking" means.

---

## grammar 1 (additive) — 2026-07-16 — Phase A′ grammar extensions (GAP-1, GAP-2, GAP-4)

**Additive. No version bump** — every addition is a new optional key, a new interpolation source, or a
new formula-adjacent execution path; nothing existing changes shape or becomes required.

### Established

- **GAP-1, transition inputs (fully resolved — grammar + engine + validator):**
  `transitions[].inputs` (declared per-transition input parameters) + `{input.<name>}` interpolation
  (resolves inside effect `value`s/`fields`, including recursively in nested lists/maps) +
  `renderBindings[].repeater` (`source` + `itemActions`, for a per-item action button whose inputs draw
  from that item's own fields via `{item.<field>}`). Closes the "shared scratch field, two racy calls"
  workaround (now [AP-12](./guide/04-antipatterns.md#ap-12--a-shared-scratch-field-for-a-per-item-action-superseded-2026-07-16--gap-1-closed)) —
  proven end-to-end on `tournament-ballot.cast-vote` (two concurrent-shaped calls with different `choice`
  values produce two distinct, non-racing rows).
- **`{id}` interpolation (new, discovered during GAP-4 closure):** resolves to the acting instance's own
  `instanceId`. Not one of the four originally-scoped gaps — found because the frozen JSON's own
  `cast-vote` effect (`"ballotId": "{id}"`) depended on it and nothing had ever implemented it.
- **GAP-4, query-backed `source` fields (fully resolved — grammar + engine + validator):**
  `instanceDataSchema[].source: "query(type where foreignField == localField)"` now genuinely executes
  (previously: A.5 parsed and preserved it as metadata only). Hydrates on every read path that
  materializes instance data for a caller (`queryInstances`, `availableTransitionsAsync`,
  `applyTransition`'s result, `dueNotifications`). Proven on `tournament-ballot.ballots` — its
  already-existing, unchanged formulas (`voteCounts`/`winner`/`tiedCandidates`/`isTie`) now compute
  correctly over real hydrated rows.
- **GAP-2, `renderBindings[].creatable` (grammar/model layer resolved; UI/runtime still open):**
  `creatable.byPersonaIds`/`label`/`prefill` (+ `{context.x}` interpolation, valid only inside `prefill`)
  parse and validate. **Nothing in the running app consumes this yet** — no "+ New" affordance renders.
  See `spec-version.json` → `knownGaps.instanceCreation` for the precise remaining scope (App Shell UI,
  not grammar).
- **8 new validator checks**: `unknown_input_type`, `unknown_input_reference`, `unknown_item_reference`,
  `dangling_allowed_persona_id` (reused, extended to `creatable.byPersonaIds`),
  `context_reference_outside_creatable`, `invalid_source_query_syntax`,
  `dangling_source_query_workflow_type`, plus `computed_field_written_by_effect`/`computed_field_seeded`
  widened to cover `source`-backed fields (previously only checked `formula`).

### Migration

**None required.** Every existing community JSON (all seven legacy `experienceSchemaVersion: 1`
communities, and the frozen Tabletop Club `v2` JSON as it stood before this release) continues to load
and behave identically — confirmed by re-running the community-package validator against the frozen JSON
after every change in this release (0 errors/0 warnings throughout).

### Docs touched

`reference/effects.md`, `reference/render-bindings.md`, `reference/field-types.md`,
`guide/04-antipatterns.md` (AP-12, AP-13), `spec-version.json` (`knownGaps` → `resolvedInGrammar` for
GAP-1/GAP-4; GAP-2's entry updated to reflect its partial closure).

### Verification

`app/packages/core/loom_workflow_engine/test/v3_milestone_aprime_grammar_extensions_test.dart` (12/12),
`app/packages/tooling/loom_ux_judges/test/v3_milestone_aprime_validator_test.dart` (21/21, incl. a
zero-new-findings regression against the frozen JSON). Full combined suite (`loom_workflow_engine` +
`loom_communities_app_shell`): 210/210. `loom_ux_judges`: 85/85. Real CLI validator against the frozen
JSON: 0 errors/0 warnings. Commits `10666f5`, `f439e38`, `0de4a36`, `34d76ef`, `392d7eb` on `main`.

---

## envelope 1 · experience 2 · grammar 1 — 2026-07-14 — **PROVISIONAL**

The first formally versioned specification. Nothing before this carried a version stamp at all.

### Why this exists

An audit found the repo had **three** JSON shapes for declaring a community's workflows, **none
version-stamped**, and no way for a reader — human or Skill — to tell which one a given file used:

1. **Shallow `experience.workflows[]`** — the only shape the app actually loaded. Cannot express a state
   machine, guard, effect, or formula.
2. **Engine-native `workflowDefinitions`** — the shape the engine genuinely parses and executes. But
   nothing loaded it from an installed package; every "real" feature was instead a hand-written Dart
   engine-store, ~20 of them.
3. **Archetype-config blocks** (`{"archetype": "calendarAgenda", …}`) — documented in the V2 Archetype
   Catalog, **parsed by no code at all.**

This release names them, versions them, and declares **shape 2 (engine-native) the target**.

### Established

- **Three independently-versioned layers** — envelope / experience / grammar. Rationale:
  [versioning-policy.md](./_meta/versioning-policy.md).
- **`experienceSchemaVersion: 1`** — the legacy shallow form. Documented, supported for the seven
  existing communities, **not for new work**.
- **`experienceSchemaVersion: 2`** — the engine-native form: `workflowDefinitions` + `workflowInstances`.
- **`workflowGrammarVersion: 1`** — the state-machine grammar as the engine implements it *today*:
  - 2 state attrs + `editableFields` + `isTerminal`
  - transitions with `from`/`to` (`to: null` = orthogonal, top-level state unchanged)
  - **6 guard kinds** — `allowedPersonaIds`, `actorInList`, `instanceDataEquals`, `formula`,
    `relatedListMembership` (cross-instance), `requiresWorkflowsComplete` (cross-workflow)
  - **9 effect ops** — `set`, `append`, `appendUnique`, `removeValue`, `increment`, `decrement`,
    `branch`, `createInstance`, `removeFromTileGrid`; plus cross-instance `set` via `relatedInstance`
  - **13 `instanceDataSchema` field attrs**, incl. `formula` (computed, read-only)
  - **20 formula functions**
  - `renderBindings` — `{states, role, tabId, cardSurfaceFamily, bindingKind, audienceMemberField?}`
- **Hard-error rule** — a loader meeting an unsupported version **must fail loudly**, never
  best-effort-parse. A silently-ignored guard is indistinguishable from a guard that passes.
- **Stamp rule** — no Loom JSON ships without all three version fields. An absent
  `experienceSchemaVersion` is an **error**, not a v1 default.

### Migration

**None required.** The seven existing communities remain on `experienceSchemaVersion: 1` and are
unaffected; the engine-native pathway is **additive**. They migrate later, via the Skill.

**New communities: author at experience v2.** Start at
[guide/01-getting-started.md](./guide/01-getting-started.md).

### Known gaps at this version

Tracked in [`spec-version.json`](./spec-version.json) → `knownGaps`. Summary:

| Gap | Impact | Scheduled |
|---|---|---|
| **No declarative instance creation** — no way to say "this type is member-creatable, show a + New affordance" | Blocks member-authored proposals and starting a new message thread | tracker-3 Phase E |
| **`responseModel` sugar is not parsed** | RSVP must be modeled with plain transitions + effects + formulas | Not scheduled — the plain modeling works |
| **String literals in formulas: unconfirmed** | e.g. `"availabilityState == 'available'"` — may not parse | tracker-3 milestone A.3 (settled by running the validator) |
| **`rank` / `topN` unimplemented** | `sortBy` covers the need | Not scheduled |

### ⚠️ Why this release is PROVISIONAL

**The engine-native schema has never been loaded by the running app.** Every construct here is verified
against the engine's parser, evaluator, and validator — but the pipeline that loads it from an installed
package is being built now (tracker 3, Phase A), and **Phase A deliberately ends in a human review gate
whose expected outcome is that this specification changes.**

Version numbers here are **not stable** until that gate closes and
[`spec-version.json`](./spec-version.json) flips to `"status": "stable"`.

---

## Before 2026-07-14 — unversioned

No specification version existed. Three competing shapes, no stamps, no changelog, no sync between the
docs and the engine — which is how `docs/CardSurfaces/*.md` came to document a `CommunityVoteApi` that
has **never existed in any version of the codebase.**

That is the failure this changelog and [publishing-flow.md](./_meta/publishing-flow.md) exist to
prevent.
