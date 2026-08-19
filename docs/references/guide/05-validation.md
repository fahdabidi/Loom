---
spec: 4
doc_version: 1.7.0
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
3. If errors: DIAGNOSE the cause (see "Diagnosing a finding" below), then apply the fix, go to 2
4. If clean: emit
```

**Never** exit this loop by weakening the validator, deleting the requirement, or hand-waving. If an
error cannot be fixed within the grammar, **stop and report the gap** (see AP-11).

---

## Diagnosing a finding — work out the cause before choosing the fix

The error → fix table below tells you what a finding means. It does **not** tell you which of several
possible causes produced it, and for most findings there are several, with different correct fixes.
Applying the table's fix without diagnosing first is how a package ends up validating clean while
having quietly lost a product feature.

**The governing rule: a finding is almost always something referenced but never declared, or declared
but never read. The fix is to make the intent real.** Deleting the reference clears the finding too,
and the validator cannot tell the difference — so the burden is on you to know which you did.

### The diagnostic, in order

Given any finding, ask these in sequence and stop at the first that matches.

**1. Did I misspell something that already exists?**
Compare the name in the finding against the declared names nearby — the same workflow's
`instanceDataSchema`, its `states`, the package's `roles[]`. A one-character difference, a
singular/plural slip, or a legacy spelling (`*PersonaId` where the package now uses `*FanId`) is the
single most common cause. Fix: correct the spelling. Nothing else changes.

**2. Is this something an archetype already owns?**
Check `archetypes/CONTRACTS.md` for the workflow's family. If the name is one of the archetype's own
bookkeeping sets — read, acknowledged, saved, downloaded, response sets — then **you must not declare
it**, and the finding is telling you the reference is in the wrong place, not that a declaration is
missing. Fix: remove your declaration or guard and let the archetype maintain it. This is the one case
where removing is correct, and it is why "always declare" is the wrong rule.

**3. Does the product doc actually ask for this?**
If the reference expresses a real requirement — a field a guard needs, a value a formula computes, a
state a transition reaches — then the declaration is genuinely missing. Fix: declare it properly, with
the right type and `writableBy`, and make sure something populates it on every path that creates the
workflow.

**4. Is the reference itself a mistake?**
Occasionally a guard, effect or binding was copied from another workflow and names something that has
no meaning here. Fix: remove the reference — and **say so explicitly in your Gaps/assumptions**,
naming what you removed and why it did not belong. If you cannot write that sentence convincingly, you
are in case 3, not case 4.

### Before you accept your own fix

Two checks, both cheap, both worth doing every round:

- **Did the package get smaller?** Field, formula, transition and binding counts should generally rise
  across a fix round, not fall. A round that clears ten findings while shrinking the package is a
  signal to re-read what you removed.
- **Can the workflow still do what it did?** If the fix makes a workflow less capable than the shipped
  package — a transition gone, a guard dropped, a formula deleted — you have removed a feature rather
  than declared an intent, unless case 2 or case 4 applies and you have said so.

### When the same finding keeps coming back

If a finding type survives two fix rounds, stop editing and re-read the reference doc for that
construct. Three attempts at the same finding means the model of the grammar is wrong, and the fourth
edit will be wrong for the same reason. Report the gap rather than iterating — a package returned with
a clearly-described unresolved finding is more useful than one that was hammered until the validator
went quiet.

### What never counts as a fix

- Weakening or bypassing the validator.
- Deleting a requirement the product doc states.
- Changing `visibility.default` to dodge a visibility requirement — that changes who can read the
  workflow.
- Re-homing a workflow to a different archetype to escape that archetype's rules.
- Retyping a field to something permissive to silence a type error.

If an error genuinely cannot be fixed within the grammar, **stop and report the gap** (AP-11).

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
| `editable_fields_without_edit_guard` (warning) | A state declares `editableFields` but no `editGuard`. `editGuard`'s absent-default is the *opposite* of every other guard: with none, the editor never renders for anyone, for any persona — the field list is silently inert. | Add `"editGuard": {"allowedRoleIds": [...]}` to the state naming who may edit, or remove `editableFields` if editing was never actually meant to be exposed. |
| `no_creation_path_for_editable_type` (warning) | A workflow type has `formEntry` fields but nothing anywhere in the package (`renderBindings[].actions[].kind: "create"`, `createInstance`, or `generateRecurringInstances`) ever creates an instance of it. Every instance that will ever exist is whatever was seeded (AP-13). | Add a `kind: "create"` action to one of the type's `renderBindings` (see `07-actions-and-fabs.md`), or have another type's effect create it, or explicitly note in your gaps section that instances are deliberately provisioned only outside this package. **Exempt:** a workflow reached through `responseTable.workflowType` — provisioning is archetype-owned, fanned out by the `action: "create"` transition on the event (see [`archetypes/event-rsvp.md`](../archetypes/event-rsvp.md) §4), so there is deliberately no authored creation path to find. Do **not** satisfy this by adding a `createInstance` effect: that would create one row, where the archetype creates one per member. |
| `no_destructive_exit_for_managed_type` (warning) | A primary-bound type with an `editGuard` declared somewhere (i.e. clearly meant to be actively managed) has zero `tone: "destructive"` transition anywhere. | Add a cancel/withdraw/delete-shaped transition with `"tone": "destructive"`, or confirm every instance of this type is genuinely meant to be permanent once created. |
| `redundant_transition` (warning) | Two transitions on the same workflow share a guard and both move to the same state from an overlapping source set, so the same member is offered both at once with the same outcome. Riverside's `cancel-rsvp` (`going\|maybe\|waitlisted → declined`) is a strict subset of its own `respond-declined`, differing only in an audit string — two buttons, one effect. | Confirm they are meaningfully different. Two distinct *operations* may legitimately share a target state (an export and a transfer both reaching `running`) — that is fine and the check tolerates it whenever the guards differ. If they differ only in bookkeeping, give one a distinct target — for a `withdraw_response`, a `pendingStates` member or a declared `withdrawn` state ([`archetypes/event-rsvp.md`](../archetypes/event-rsvp.md) §4) — or remove it. |
| `orphaned_response_rows` (warning) | A terminal/destructive transition ends a workflow that owns response rows, without sweeping them. A row cannot see its parent's state, so those rows stay live and keep accepting responses after the event is cancelled. All six response-row communities trip this today — it is a pre-existing hole the array shape merely hid, since arrays lived on the event and were cancelled along with it. | Add one `transitionRelated` effect **per source state** to the ending transition (a filter matches one state at a time), targeting a transition on the response workflow: `{"op": "transitionRelated", "transitionId": "event-cancelled", "relatedQuery": {"workflowType": "<response-type>", "filter": {"eventId": "{id}", "$state": "going"}}}`. Worked example: [`archetypes/event-rsvp.md`](../archetypes/event-rsvp.md) §5. |
| `missing_visibility_fields` | The workflow's archetype uses a visibility model that reads instance-data identities (`owner_and_shared`, `participants`, `parties`, `recipient`) but declares no `visibility.fields` mapping. The engine cannot guess which field is a party rather than an audit actor. | Declare the mapping — see [`workflow-grammar.md`](../reference/workflow-grammar.md)'s `visibility.fields`. For `notificationInbox` specifically, an omitted `recipient` is **legal** and means broadcast, so this does not fire for that case. |
| `dangling_visibility_field` | A field named in `visibility.fields` is not declared in this workflow's `instanceDataSchema`. | Declare the field, or fix the name. A mapping pointing at a non-existent field silently admits nobody. |
| `invalid_parties_arity` | `visibility.fields.parties` does not name exactly two fields. | `parties` means the two sides of a request. For more than two readers use `participants`; for one, use `recipient`. |
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
