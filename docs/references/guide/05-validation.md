---
spec: { envelope: 1, experience: 2, grammar: 1 }
doc_version: 1.0.0
status: current
last_verified: 2026-07-14
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

> **Status:** the community-package validator is being built (tracker-3 milestones A.1-A.2). Until it
> lands, the definition-level validator exists and covers most checks:
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
| `missing_schema_version` | A version stamp is absent | Add all three: `schemaVersion`, `experienceSchemaVersion`, `workflowGrammarVersion` |
| `unsupported_schema_version` | Version higher than the build supports | Author against the current spec ([`spec-version.json`](../spec-version.json)) |
| `legacy_experience_schema` (warning) | `experienceSchemaVersion: 1` | Re-author at v2. v1 cannot express state machines. |

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
| `unknown_effect_op` | `op` isn't one of the nine | See [effects.md](../reference/effects.md) |
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
| `unknown_formula_function` | Not one of the 20 | See [formulas.md](../reference/formulas.md). Note: there is no `!` and no `!=`. |
| `invalid_formula_syntax` | Won't parse | Check operators; no `!`/`!=` |
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
| `missing_template` (warning) | Unknown `cardSurfaceFamily` | Use one from [`archetypes/README.md`](../archetypes/README.md) |
| `missing_action_button_row` | A `primary` binding's surface has no action row | Use `summary`, or a surface that supports actions |
| `binding_cap_exceeded` (warning) | >32 bindings or >16 roles | A smell — likely two workflows. Split. |

---

## What the validator does NOT catch

**Passing is necessary, not sufficient.** It cannot tell you:

- That your **modeling** is right (AP-1: a "state" that should be data will validate happily as long as
  it has transitions).
- That your **requirements** are met — it never saw the brief.
- That the app **renders** it correctly — the spec is provisional and has not run in a real app.

So: run the validator, **and** run the [anti-pattern self-check](./04-antipatterns.md), **and** re-read
the requirements against the emitted JSON.
