---
spec: 4
doc_version: 1.4.0
status: current
last_verified: 2026-08-09
audience: llm-agent
derived_from:
  - app/packages/tooling/loom_ux_judges/lib/src/validator/workflow_validator.dart
  - app/packages/tooling/loom_ux_judges/bin/workflow_state_machine_validator.dart
---

# Validation — the mandatory gate

**A community that does not pass the validator is not a deliverable.** No exceptions.

## Run it

```bash
dart run loom_ux_judges:community_package_validator \
  --package <your-community>.jsonc \
  [--warnings-as-errors] \
  [--output report.json]
```

Exit codes: `0` = pass · `1` = errors found · `64` = usage error.

> **Status:** the community-package validator has shipped and is the gate. `--package` accepts a single
> `.jsonc` or a directory. The definition-level validator still exists for narrower checks:
> `dart run loom_ux_judges:workflow_state_machine_validator --definitions <file>`

## The repair loop

```
1. Emit JSON
2. Run validator
3. If errors: find each error code in the table below, apply the fix, go to 2
4. If clean: emit
```

**Never** exit this loop by weakening the validator, deleting the requirement, or hand-waving. If an
error cannot be fixed within the grammar, **stop and report the gap** (see AP-11).

---

## Error → fix table

### Version / envelope

| Code | Meaning | Fix |
|---|---|---|
| `missing_schema_version` | The version stamp is absent or not an int | Add a single package-root `specVersion: 4`. **Not** the legacy triple — a package declaring `specVersion` must not also carry `schemaVersion` / `experienceSchemaVersion` / `workflowGrammarVersion`, and doing so is its own error. |
| `unsupported_schema_version` | Version higher than the build supports | Author against the current spec ([`spec-version.json`](../spec-version.json)) |
| `legacy_experience_schema` (warning) | The package uses the pre-4 version triple | Re-author at `specVersion: 4`. The triple's v1 could not express state machines at all; v4 folds all three into one package-root stamp. |

### States

| Code | Meaning | Fix |
|---|---|---|
| `stuck_state` | Non-terminal state with no outgoing transition | Add a transition out, **or** mark `"isTerminal": true`. Often the real fix is AP-1 — it shouldn't be a state. |
| `unreachable_state` | No transition path from `initialState` | Add a transition into it, or delete it |
| `invalid_instance_state` | An instance's `currentState` isn't declared | Fix the instance, or declare the state |

### Transitions

| Code | Meaning | Fix |
|---|---|---|
| `missing_label` | Empty `label` | Every transition needs button text |
| `dangling_instance_data_key` | Guard/effect names an undeclared field | Declare it in `instanceDataSchema`, or fix the typo |
| `unknown_effect_op` | `op` isn't one of the twelve | See [effects.md](../reference/effects.md) |
| `computed_field_written_by_effect` | An effect writes a `formula` field | Delete the effect. Computed fields are read-only. |
| `dangling_related_instance_field` | `relatedInstance` / `relatedInstanceField` names an undeclared field | Declare the id-holding field on **this** workflow |
| `dangling_create_instance_target` | `createInstance.workflowType` doesn't exist | Declare the target type, or fix the name |
| `dangling_requires_workflows_complete` | Prerequisite workflow doesn't exist | Declare it, or drop the guard |
| `dependency_cycle` | Cyclic `requiresWorkflowsComplete` | Break the cycle |
| `dangling_linked_workflow_id` (warning) | `linkedWorkflowId` not in the set | Declare it, or accept if genuinely external |

### Fields and formulas

| Code | Meaning | Fix |
|---|---|---|
| `unknown_formula_field` | Formula references an undeclared field | Declare it. Formulas may only see **this** workflow's schema. |
| `unknown_formula_function` | Not one of the 23 | See [formulas.md](../reference/formulas.md). Note: unary `!` (not) IS supported; `!=` is NOT — restructure as `if(a == b, false, true)`. |
| `invalid_formula_syntax` | Won't parse | Check operators; `!` is fine, `!=` is not |
| `circular_formula_dependency` | Computed fields reference each other cyclically | Break the cycle |
| `effect_field_in_editable_fields` | `editableFields` names a non-`formEntry` field | Only `writableBy: "formEntry"` fields may be edited |

### Instances

| Code | Meaning | Fix |
|---|---|---|
| `unknown_instance_workflow_type` | `workflowType` isn't declared | Fix the name, or declare the type |
| `duplicate_instance_id` | Two instances share an id | Make ids unique |
| `unknown_instance_data_key` | `instanceData` has an undeclared key | Declare it, or remove it |
| `missing_required_field` | A `required: true` field is absent | Add it to `instanceData` |
| `computed_field_seeded` | A `formula` field appears in `instanceData` | **Delete it from the seed.** It's derived. |
| `dangling_instance_reference` | A cross-instance ref doesn't resolve | Point it at a real `instanceId` |
| `unknown_instance_persona` (warning) | `createdByPersonaId` isn't declared | Declare the persona |

### Bindings

| Code | Meaning | Fix |
|---|---|---|
| `missing_template` (warning, ⚠️ **NOT ENFORCED** as of 2026-08-09 — see `archetypes/README.md` hard rule 1) | Unknown `cardSurfaceFamily` | Use one from [`archetypes/README.md`](../archetypes/README.md) — check by hand, the validator does not currently catch this |
| `missing_action_button_row` | A `primary` binding's surface has no action row | Use `summary`, or a surface that supports actions |
| `binding_cap_exceeded` (warning) | >32 bindings or >16 roles | A smell — likely two workflows. Split. |

### Expected affordances (added 2026-08-04)

These three are heuristic, warning-only checks — never hard failures — but each has caught a real,
otherwise-invisible bug in practice (including in this repo's own legacy example fixtures), so treat them
seriously rather than dismissing them as noise.

| Code | Meaning | Fix |
|---|---|---|
| `editable_fields_without_edit_guard` (warning) | A state declares `editableFields` but no `editGuard`. `editGuard`'s absent-default is the *opposite* of every other guard: with none, the editor never renders for anyone, for any persona — the field list is silently inert. | Add `"editGuard": {"allowedPersonaIds": [...]}` to the state naming who may edit, or remove `editableFields` if editing was never actually meant to be exposed. |
| `no_creation_path_for_editable_type` (warning) | A workflow type has `formEntry` fields but nothing anywhere in the package (`renderBindings[].actions[].kind: "create"`, `createInstance`, or `generateRecurringInstances`) ever creates an instance of it. Every instance that will ever exist is whatever was seeded (AP-13). | Add a `kind: "create"` action to one of the type's `renderBindings` (see `07-actions-and-fabs.md`), or have another type's effect create it, or explicitly note in your gaps section that instances are deliberately provisioned only outside this package. |
| `no_destructive_exit_for_managed_type` (warning) | A primary-bound type with an `editGuard` declared somewhere (i.e. clearly meant to be actively managed) has zero `tone: "destructive"` transition anywhere. | Add a cancel/withdraw/delete-shaped transition with `"tone": "destructive"`, or confirm every instance of this type is genuinely meant to be permanent once created. |
| `no_read_visibility_declared` (warning) | A workflow type omits the workflow-level `visibility` block, so its read policy is implicit even though the compatibility default remains `public`. | Add `"visibility": {"default": "public"}` (or `"default": "membersOnly"` / `"default": "guarded"` with a sibling `"readGuard"`) to make the community's intended read policy explicit. |
| `no_render_binding_for_reachable_state` (warning) | A state is reachable via a transition path but no `renderBinding`'s `states` list covers it, so an instance sitting there renders on no tab. | Add a `renderBinding` (often `"bindingKind": "summary"`) whose `"states"` includes it, or confirm the state is intentionally never surfaced. |
| `dead_role_binding` (warning) | `role: "receiver"` used on a `tabId` other than `admin` without `audienceMemberField` (only `admin` ever grants the receiver role), or a non-`"any"` role used on `tabId: "calendar"` (which passes no role-resolution callback at all — only `"any"`, or `"receiver"` + a working `audienceMemberField`, can render there). | Use `role: "any"` instead, move the binding to `admin`, or add `audienceMemberField` for a dynamic-audience notification. See `render-bindings.md`'s per-tab resolution table. |

---

## What the validator does NOT catch

**Passing is necessary, not sufficient.** It cannot tell you:

- That your **modeling** is right (AP-1: a "state" that should be data will validate happily as long as
  it has transitions).
- That your **requirements** are met — it never saw the brief.
- That the app **renders** it correctly — the spec is provisional and has not run in a real app.

So: run the validator, **and** run the [anti-pattern self-check](./04-antipatterns.md), **and** re-read
the requirements against the emitted JSON.
