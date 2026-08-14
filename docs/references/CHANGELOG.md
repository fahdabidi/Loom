---
spec: { envelope: 1, experience: 2, grammar: 3 }
doc_version: 1.3.0
status: current
last_verified: 2026-08-13
---

# Specification changelog

Every change to the Loom community-JSON specification. Newest first.

Format per entry: **what changed · breaking or additive · what an author must do about it.**
See [_meta/versioning-policy.md](./_meta/versioning-policy.md) for what "breaking" means.

---

## grammar 3 (breaking) — 2026-08-13 — `personaId` splits into `roleId` and `fanId`

**Breaking.** The single identity type `personaId` did two incompatible jobs: naming a *kind of member*
(shared by many) and naming a *specific person*. Guards needing the second meaning were given values that
only ever satisfy the first, so per-individual guards were silently unsatisfiable — Member Social Space's
Messages tab is empty because of it, and ten of eleven fixtures carry the same latent defect.

Full definition and rationale: [`reference/identity-types.md`](./reference/identity-types.md).

| Was (v1/v2) | Now (v3) | Occurrences |
|---|---|---|
| `experience.personas[]` → `personaId` | `experience.roles[]` → `roleId` | — |
| `guard.allowedPersonaIds` | `guard.allowedRoleIds` | 582 |
| `actions[].byPersonaIds` | `actions[].byRoleIds` | 70 |
| `tabs[].visiblePersonaIds` | `tabs[].visibleRoleIds` | 15 |
| `personaTabs` | `roleTabs` | — |
| field type `personaId` / `personaId[]` | `fanId` / `fanId[]` | ~857 keys |
| `renderBindings[].role` | `renderBindings[].audience` | 247 |

`$actor` and `$viewer` are now `fanId`-typed. Comparing either to a declared `roleId` is an **error**,
which is the point of the change: three formulas in the corpus are broken by exactly that mechanism today
and produce no diagnostic. They are fixed by this migration rather than hand-patched, so the type split is
demonstrated to catch them.

`renderBindings[].role` is renamed because it never meant a community role — its values are
`actor`/`receiver`/`any`, the viewer's relationship to an instance. Leaving two unrelated meanings of
"role" in one file, one of them now a real type, was untenable.

**What an author must do:** nothing by hand. Packages are regenerated through the authoring Skill. The
validator rejects a v1/v2 key in a v3 package, and rejects an identity field whose type is not `fanId`
or `roleId`.

**Also fixed here:** every fixture declared `workflowGrammarVersion: 1` while carrying grammar-2 content
(`actions[]`, no `creatable`). `supportedGrammarVersions` was `{1}`, so the validator only ever accepted
the stale value and the drift was invisible. v3 packages declare 3 and the validator gates on it.

---

## grammar 2 (breaking) — 2026-07-21 — `actions[]` replaces `creatable`; adds a `transition` kind

**Breaking.** `renderBindings[].creatable` (a single flat create-affordance object) no longer exists.
Replaced by `renderBindings[].actions[]` — an array of archetype-owned actions, each with a `kind`. Any
existing `creatable` object must be rewritten as one `{ "kind": "create", ... }` array entry (see
Migration below) — this is why the bump is breaking, not additive: a file with the old key would now
fail to parse as intended.

### Established

- **`kind: "create"` (replaces `creatable` 1:1, plus new capability):** `label`, `byPersonaIds`, optional
  `workflowType` (defaults to the binding's own type — set only for the cross-archetype case),
  new `scope` (`tab` default | `instance`) and `presentation` (`fab` default | `button`), `prefill`.
  **New beyond what `creatable` could express:** `scope: "instance"` — an action related to one specific
  existing instance, rendering as a card `button` or a contextual FAB bound to the in-focus instance,
  with `{context.id}` / `{context.<field>}` resolving from that host instance. `scope: "tab"` behaves
  exactly as `creatable` always did (a tab-wide FAB, always reachable, no context). A cross-archetype
  instance-scoped action is declared on the **host's** binding, never the created type's own binding (the
  ballot-creation action moved from `tournament-ballot`'s binding onto `tournament-event`'s).
- **`kind: "transition"` (additive, same date — a second action kind, not a second version bump):** names
  an already-declared `transitions[].id` on the binding's own workflow type and gives it a distinguished
  `fab`/`button` presentation instead of the automatic per-instance button row generated from
  `availableTransitions` — removing only that one transition from the row, leaving every other transition
  on the type rendering automatically as before. `scope` is fixed to `instance` (a transition always acts
  on an existing instance); `byPersonaIds`/`workflowType`/`prefill` do not apply (the transition's own
  `guard`/`inputs` remain the sole source of truth for eligibility and shape). Per the additive rule
  above, this did not require its own version bump — recorded here under the version it landed in.
- **`{context.*}` interpolation**, valid inside an instance-scoped action's `prefill` (create) or `inputs`
  (transition) only: `{context.id}` (the host instance's own id) and `{context.<fieldName>}` (that
  instance's own data). A `{context.*}` reference anywhere else, or on a `scope: "tab"` action, is a
  validator error.
- **New validator checks:** `unknown_action_kind`, `unknown_action_scope`/`unknown_action_presentation`,
  `tab_action_cannot_be_button`, `dangling_action_workflow_type`,
  `context_reference_outside_instance_action`, `dangling_action_transition_id`,
  `transition_action_cannot_be_tab_scoped`,
  `transition_action_cannot_set_workflow_type`/`_prefill`/`_by_persona_ids`,
  `unknown_action_input_reference`, `duplicate_action_transition_id`, `create_action_cannot_set_inputs`
  (`dangling_allowed_persona_id`, `dangling_instance_data_key`, `computed_field_written_by_effect` are
  reused from the prior `creatable` grammar, now checked against `actions[]` instead).

### Migration

Rewrite every `renderBindings[].creatable` object as one `renderBindings[].actions[]` entry:

```jsonc
// Before (grammar 1)
"creatable": { "label": "New event", "byPersonaIds": ["organizer"] }

// After (grammar 2) — identical behavior; scope/presentation now explicit
"actions": [
  { "kind": "create", "label": "New event", "byPersonaIds": ["organizer"],
    "scope": "tab", "presentation": "fab" }
]
```

No community shipped on grammar 1's `creatable` outside this release's own frozen Tabletop Club JSON,
which was migrated in the same pass (all 6 prior `creatable` bindings → `actions[]`, plus the new
cross-archetype instance-scoped ballot-create action and one `kind: "transition"` action on
`equipment-loan`). The seven legacy communities remain on `experienceSchemaVersion: 1` and are
unaffected — grammar only applies under `experienceSchemaVersion: 2`.

### Docs touched

`reference/render-bindings.md` (`actions` section fully rewritten for two kinds), new
[`guide/07-actions-and-fabs.md`](./guide/07-actions-and-fabs.md) (decision procedure + worked examples —
create vs. transition, scope/presentation, cross-archetype rule, the nested-tables case),
`guide/03-common-patterns.md` (P3/P6 known-gap notes updated to point at the real mechanism),
`guide/04-antipatterns.md` (AP-13 updated: `scope: "tab"` creates now render end-to-end, not just
parse), `communities/tabletop-club.md` (§3/§7/§10/§11), `spec-version.json`
(`layers.grammar` bumped to 2, `knownGaps.instanceCreation` and `proposedNotImplemented.actionsGrammar`
updated), `_meta/doc-manifest.json` (`syncedTo` bumped for every doc above).

### Verification

Real CLI validator (`community_package_validator.dart`) against the updated frozen JSON: 0 errors/0
warnings. Node.js JSONC-parse check: valid JSON, 5 tab-scoped creates + 1 instance-scoped create + 1
transition action counted, matching the design. **App Shell implementation status, honestly stated:**
`scope: "tab"` creates render end-to-end (CALR.3g/3h/3b, unaffected by this rename beyond the JSON key
migration). `scope: "instance"` creates and the entire `kind: "transition"` surface are grammar/validator
only as of this entry — no running UI consumes them yet. Tracked in the tracker's CALR.4a-f rows.

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
