# Loom Communities — JSON Schema Versions

Status: **Normative.** Every Loom community JSON MUST carry the version fields defined here. Written
2026-07-13 as the precursor to the Tabletop Club engine-native rebuild (tracker
[Loom_Communities_Workflow_Engine_3.md](./Loom_Communities_Workflow_Engine_3.md)).

## Why this exists

The repo grew **two different, unversioned JSON shapes** for declaring a community's workflows, with no
marker to tell them apart at load time — so a reader (human or code) could not know which grammar a
given file follows. This doc names and versions each schema, defines the fields that stamp a file with
its versions, and states the loader's dispatch rule. From now on, no Loom JSON is written without these
fields.

## The three versioned layers

A community install package nests three independently-versioned schemas. Each has its own field so a
loader can pick the right parser for each layer without guessing.

| Layer | Version field | Where | Current | What it governs |
|---|---|---|---|---|
| **Package Envelope** | `schemaVersion` | package root | `1` | The install wrapper: `packageId`, `communityId`, `communityHandle`, `displayName`, `extensionId`, `branding`, `seedDataFiles`, `experience`. |
| **Experience Content** | `experience.experienceSchemaVersion` | inside `experience` | `2` | How the `experience` block declares workflows (see the two values below). |
| **Workflow State-Machine Grammar** | `experience.workflowGrammarVersion` | inside `experience` | `1` | The grammar each `workflowDefinitions` entry follows (states/transitions/guards/effects/renderBindings/instanceDataSchema/formulas). |

### Package Envelope Schema — v1

Unchanged from what ships today. `schemaVersion: 1` at the package root. Governs the outer wrapper
only; it says nothing about how workflows inside `experience` are shaped — that's the Experience
Content layer's job.

### Experience Content Schema — v1 vs v2

- **v1 — legacy shallow form.** `experience.workflows[]` is a flat list of cards
  (`workflowId`/`title`/`entryText`/`actionText`/`resultText`/`calendar?`/`responseChoices?`), plus one
  bespoke top-level block per special feature (`tournamentBallot`, `marketplaceListings`, `threads`,
  `givingPayment` on a workflow, …). This is what `_experienceFromConfiguration`
  (`part15_evidence_catalog.dart:41-221`) loads today. It **cannot** express a real state machine,
  guard, effect, or formula — unmatched workflows fall back to a generic fact-pill card. A file with no
  `experienceSchemaVersion` field is treated as v1 for backward compatibility.
- **v2 — engine-native form.** `experience.workflowDefinitions` is a map of real state machines
  (Workflow State-Machine Grammar below) that the real `WorkflowEngineApi`/`LocalWorkflowEngineApi`
  parses (`LoomWorkflowStateMachine.fromJson`, `workflow_models.dart:341-371`) and executes, plus
  `experience.workflowInstances[]` seed data. This is the target: every workflow/transition/
  interaction/effect declared in JSON and run by the engine. A real backend would execute it for real;
  the demo runs it against a local `WorkflowDatabase` — same API shape, stubbed transitions.

  v1 and v2 may coexist during migration (a v2 file may still carry legacy bespoke blocks the app
  hasn't moved off yet), but a v2 file's canonical source of truth for any workflow it declares under
  `workflowDefinitions` is that definition — not a duplicate shallow `workflows[]` entry.

### Workflow State-Machine Grammar — v1

The grammar of one `workflowDefinitions` entry, exactly as `LoomWorkflowStateMachine.fromJson` +
`WorkflowGuard`/`WorkflowEffect`/`LoomWorkflowTransition`/`LoomWorkflowState`/`RenderBinding`/
`InstanceDataField`.fromJson parse it today (`workflow_models.dart`). v1 covers:

- **states**: `{ label, tone?, editableFields?, isTerminal? }`.
- **transitions**: `{ id, label, icon?, tone?, from[], to?, guard?, effects?, linkedWorkflowId? }`
  (`to: null` = orthogonal transition, top-level state unchanged).
- **guard**: any of `allowedPersonaIds[]`, `actorInList{key,present}`, `instanceDataEquals{key,value}`,
  `formula` (must eval true), `relatedInstanceField`+`relatedListField` (cross-instance membership),
  `requiresWorkflowsComplete[]`. AND semantics across all present.
- **effects** (`op`): `set`, `appendUnique`, `append`, `removeValue`, `increment`, `decrement`;
  extended ops `branch` (`if`/`then`/`else`), `createInstance` (`workflowType`/`fields`), and
  cross-instance `set` (`relatedInstance`). `$actor` → acting persona id; `{fieldName}` → interpolated
  field value.
- **instanceDataSchema** field attrs: `type`, `required?`, `writableBy?` (`formEntry`|`effect`),
  `storage?`, `storageTarget?`, `searchable?`, `sortable?`, `displayIcon?`, `labelTemplate?`,
  `displayContexts?`, `hideWhenEmpty?`, `maxLength?`, `formula?` (computed, read-only).
- **formula vocabulary** (evaluator, `formula_evaluator.dart:19-40`): `count`, `sum`, `avg`, `min`,
  `max`, `countDistinct`, `groupCount`, `sortBy`, `argMaxKey`, `topKeys`, `size`, `contains`,
  `indexOf`, `if`, `now`, `daysBetween`, `daysUntil`, `isBefore`, `isAfter`, `isPast`, plus arithmetic
  `+ - * /`, comparison `>= > == < <=`, boolean `&& || !`.
- **renderBindings**: `{ states[], role, tabId, cardSurfaceFamily, bindingKind, audienceMemberField? }`.

**Known not-yet-in-grammar (mark `NEEDS IMPLEMENTATION` when a v2 file relies on them):**
- A declarative "member creates a brand-new instance of workflowType X via a form" affordance — today
  creation is either a seeded instance or an app-shell `+ New` button calling `engine.createInstance`;
  there is no `renderBinding`/flag that says "this type is member-creatable." The
  `game-purchase-proposal` and `discussion-thread` "compose new" flows depend on this.
- `responseModel` (the `simpleRsvp` sugar in V2's Calendar_RSVP design doc) is **not** parsed by the
  engine. RSVP going/maybe/not-going + capacity + waitlist must be modeled with plain transitions +
  effects + formulas instead (as this doc's Tabletop Club JSON does), until/unless that sugar is added.
- `rank`/`topN` named ranking functions (proposed in ComputationModel.md) are unimplemented; `sortBy`
  covers the same need.

## The stamp — every JSON carries this

```jsonc
{
  "schemaVersion": 1,                         // Package Envelope
  "packageId": "...",
  "communityId": "...",
  "extensionId": "...",
  "branding": { "accentColor": "#RRGGBB", "...": "..." },
  "experience": {
    "experienceSchemaVersion": 2,             // Experience Content: 2 = engine-native
    "workflowGrammarVersion": 1,              // Workflow State-Machine Grammar
    "displayName": "...",
    "workflowDefinitions": { "...": { "...": "..." } },
    "workflowInstances": [ { "...": "..." } ]
  }
}
```

A loader dispatches as: read `schemaVersion` → parse the envelope; read
`experience.experienceSchemaVersion` (absent ⇒ 1) → if 1, use the legacy shallow parser; if 2, parse
`workflowDefinitions` via the grammar at `workflowGrammarVersion`. Unknown/newer numbers than the
running build supports are a hard load error, never a silent best-effort parse.

## Versioning rules going forward

- **Additive change to a grammar** (new optional field, new formula function, new effect op) → bump
  that layer's minor understanding but keep the integer version if old files still parse unchanged;
  only bump the integer when a change is **breaking** (an old file would parse wrong or a new file
  won't load on an old build).
- **Never** ship a Loom JSON without all three version fields present (envelope always; the two
  `experience.*` fields whenever an `experience` block exists).
- The authoritative worked example of a fully-stamped v2 file is
  [Loom_Communities_Workflow_Engine_Phase1_TabletopClub_Example.jsonc](./Loom_Communities_Workflow_Engine_Phase1_TabletopClub_Example.jsonc).
