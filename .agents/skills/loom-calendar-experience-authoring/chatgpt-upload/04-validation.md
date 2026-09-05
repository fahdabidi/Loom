---
spec: 4
doc_version: 1.9.0
status: current
last_verified: 2026-08-30
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
| `stale_skill_version` (added 2026-09-05) | The package's `skillVersion` is absent, or behind the value in [`generated/skill-version.json`](../generated/skill-version.json) | Fetch [`reference/skill-versioning.md`](../reference/skill-versioning.md), apply every migration between the package's stamped version (or `0.0.0` if the field is absent) and current, in order, then stamp `skillVersion` to the current value. A warning, not a hard error — flags real drift (a package authored or last touched before a ratified convention existed) without breaking a build over it while the migration backlog is being worked through. |

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
| `computed_field_cannot_be_required` | A field declares a `formula` (or `source`) **and** `required: true` | Remove `required: true`, keep the formula. Never the reverse — the formula is what supplies the value. The engine checks `required` **before** evaluating formulas, so this declaration makes every instance of that workflow fail to create (`Required field is missing or null`) and the package fails to install even though it validated clean. |
| `dangling_related_instance_field` | `relatedInstance` / `relatedInstanceField` names an undeclared field | Declare the id-holding field on **this** workflow |
| `dangling_create_instance_target` | `createInstance.workflowType` doesn't exist | Declare the target type, or fix the name |
| `dangling_requires_workflows_complete` | Prerequisite workflow doesn't exist | Declare it, or drop the guard |
| `dependency_cycle` | Cyclic `requiresWorkflowsComplete` | Break the cycle |
| `dangling_linked_workflow_id` (warning) | `linkedWorkflowId` not in the set | Declare it, or accept if genuinely external |
| `noop_affordance` (warning) | A transition changes no state (`to: null`) **and** declares no `effects` — a button that renders but does nothing | If its backing service is not built yet, KEEP it as a placeholder and mark it `not_implemented` with a `// NEEDS IMPLEMENTATION (platform service): <what is missing>` comment (see [solved-patterns.md](../reference/solved-patterns.md) pattern 23) — never a silent no-op and never dropped; otherwise add the effect/state change it is missing. |

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

### Bindings

| Code | Meaning | Fix |
|---|---|---|
| `missing_template` (warning, ⚠️ **NOT ENFORCED** as of 2026-08-09 — see `archetypes/README.md` hard rule 1) | Unknown `cardSurfaceFamily` | Use one from [`archetypes/README.md`](../archetypes/README.md) — check by hand, the validator does not currently catch this |
| `missing_action_button_row` | A `primary` binding's surface has no action row | Use `summary`, or a surface that supports actions |
| `binding_cap_exceeded` (warning) | >32 bindings or >16 roles | A smell — likely two workflows. Split. |

### Capabilities that do not exist yet (added 2026-08-28)

| Code | Meaning | Fix |
| --- | --- | --- |
| `messaging_feature_not_available` *(warning)* | A transition manages **thread** state — muting, unmuting, or moving a read position on a discussion or message thread — which belongs to the messaging tab. That tab is not built, and no service answers for it, so the transition cannot do anything. Today these render as buttons that change nothing. | Do not model thread state as workflow data. Remove the transition and record the requirement in Gaps, citing this code and `docs/API/OpenAPI/community-surfaces/messaging-api.openapi.yaml`, which marks the boundary. The messages themselves stay a workflow where a community models discussion that way — this is about state *about* a thread, not its content. |

**Why this warns rather than asking for a workaround.** The honest implementation does not exist yet.
Fourteen transitions across Book Club, Member Social Space and Masjid Nur already declare no action,
change no state and carry no effects — they are buttons that do nothing, and each was a reasonable
attempt to express a real requirement with no place to put it. Member Social Space went further and
modelled per-member unread state as `unreadForA` / `unreadForB`: two fields that work for exactly two
participants and cannot generalise to three.

Naming the gap is worth more than another workaround. A package that says "this belongs to messaging"
in its Gaps section is accurate; one that ships a dead mute button is not, and looks finished.

### Transitions that do nothing (added 2026-08-28)

| Code | Meaning | Fix |
| --- | --- | --- |
| `transition_has_no_observable_effect` *(warning)* | A transition changes no state (`to` is null or equals its own `from`) and declares no effects, so applying it leaves the instance exactly as it was. The button works, the action succeeds, and nothing anywhere records that it happened. | Give it an observable result: an effect that writes what the action means — `append $actor` for a join or acknowledge, `set` for a status — or a state change. **Exempt**, and not reported: an action the client performs itself (`open`, `share`, `download`, `preview`), and one a platform service completes (`upload`, where the Document Library API writes the field). If a transition is genuinely display-only, say so in Gaps naming this code. |

`transition_has_no_observable_effect` exists because this class is invisible from every other angle.
The transition is well-formed, its guard is correct, it appears in the UI, it applies without error,
and the instance is unchanged afterwards. A walkthrough records the tap as a success. The defect is
only visible by asking what the instance looked like before and after, which nothing did until this
rule.

Measured at introduction, 2026-08-28: **37 transitions across 6 communities** — Book Club 14, Cedar 7,
Member Social Space 7, Masjid Nur 5, Camera Club 2, Garden Club 2 — carrying actions including
`join_queue`, `leave_queue`, `acknowledge`, `save`, `request_access` and `grant_access`. Five more are
exempt client-side actions and are not counted.

A warning, not an error, on the same reasoning as the writer rules: the packages did not break, the
grammar learned to ask a question it had never asked. Promote once the corpus has moved.

### Field writers (added 2026-08-27)

| Code | Meaning | Fix |
| --- | --- | --- |
| `effect_writable_field_has_no_effect` *(warning)* | A field declares `writableBy: "effect"` and no effect anywhere in the package writes it — not in its own workflow, and not through a `createInstance` from another. It names a writer that does not exist, so the field stays empty forever. | Say who actually writes it. A platform service — a checksum, an opaque receipt or transfer id, a stored document's URL — is `writableBy: "platform"`. A member is `"formEntry"`. Nothing is `writableBy` omitted entirely. **Not** by adding an effect that sets a placeholder: a fabricated value is worse than an empty field, because it looks real. |
| `prefill_written_field_not_platform` *(warning)* | A field is stamped by a create-action `prefill` — `"ownerFanId": "$actor"`, or a literal starting value — no state lists it in `editableFields`, and its `writableBy` is anything other than `platform`. The platform writes it at creation, so `effect` is false (prefill is not an effect), `formEntry` is false (no member types it, and on an identity field that claim is actively wrong), and omitting the key is false too (something does write it). | Declare `writableBy: "platform"`. If instead the prefill is seeding a **default a member then edits**, the field belongs in that state's `editableFields` and `"formEntry"` is correct — the rule stays silent in that case, and it is the case worth checking first. |

### Platform sources (added 2026-08-29)

| Code | Meaning | Fix |
| --- | --- | --- |
| `platform_source_requires_platform_writer` *(error)* | A field declares `platformSource` without `writableBy: "platform"`. It is not a shorthand for both. | Add `"writableBy": "platform"`, or drop the `platformSource`. |
| `unknown_platform_source` *(error)* | A `platformSource` outside the closed set `{checksum, opaqueId}`. A new mechanism is a grammar decision, not something a package may invent. | Use a defined value, or report the gap rather than inventing one. |
| `platform_writable_field_missing_platform_source` *(warning)* | A field declares `writableBy: "platform"` but never says *which* value it receives. | Add the `platformSource`. Regeneration closes these. |

The third is a warning **on purpose**. `writableBy: "platform"` shipped before `platformSource`
existed, so 138 fields across the shipped corpus declare the first and not the second. Making that
fatal would have invalidated every shipped community in the same commit that added the rule, and a
validator that fails the corpus it ships with teaches everyone to ignore it. It becomes an error once
the corpus has moved -- the same staging `effect_writable_field_has_no_effect` went through.

Why the distinction is worth a rule at all: `writableBy: "platform"` says only *that* a service
writes the field. A `checksum` and a `receiptId` are both `"type": "text?"` with
`"writableBy": "platform"` and are otherwise identical, so nothing could decide which value either
was owed. Matching on the field's name is the one thing this project forbids -- see
[`solved-patterns.md`](../reference/solved-patterns.md) § 20.

`prefill_written_field_not_platform` is a warning about honesty rather than behaviour. A field is
editable only when a state lists it in `editableFields`, and the engine checks that membership
*before* it consults `writableBy`, so a misdeclared prefill field is not editable today whatever it
says. It is still worth fixing: the declaration should state what actually happens, two authoring
passes should not answer the same question differently, and `formEntry` on an identity field becomes
a real hole the moment someone adds that field to `editableFields`.

**Why this only became checkable in 2026-08.** `effect` used to cover two different things: a JSON
effect setting a value, and something outside the package filling one in. A field nothing wrote was
therefore indistinguishable from one the platform wrote, and neither could be flagged without flagging
the other. `platform` separates them, and the check follows.

It is a warning because 64 fields across 9 communities declare `effect` today with nothing writing
them. Most are genuinely platform-written; a few are fields nobody ever populates. Failing the corpus
on introduction would report that the packages broke, when what happened is that the grammar learned
to tell two things apart.

### Community notifications (added 2026-08-30)

| Code | Meaning | Fix |
| --- | --- | --- |
| `unknown_notification_channel` *(error)* | A channel outside the closed set `{inbox, push}`. A third delivery path is a platform decision, not something a package may name. | Use `inbox`, `push`, or both. |
| `empty_notification_channels` *(error)* | `allowedChannels` or `default` is present but empty. | Give it at least one channel, or omit the key and take the default. |
| `notification_default_not_offered` *(error)* | `default` names a channel absent from `allowedChannels` — a default nobody can receive. | Add it to `allowedChannels`, or drop it from `default`. |
| `notification_muted_without_inbox` *(error)* | `muted: true` while `inbox` is absent from `default`. | Keep `inbox` in `default`; muting stops the interruption, not the record. |
| `unknown_notification_key` *(error)* | A key under `notifications` that the grammar does not define. | Remove it, or propose the key — see [`platform-services.md`](../reference/platform-services.md). |

**All five are errors, and that is safe only because the block is optional and absent everywhere.**
`experience.notifications` does not appear in any of the eleven shipped packages, and an omitted block
is legal — it means `allowedChannels: ["inbox"]` and `default: ["inbox"]`. So no rule here can fire on
the corpus as it stands, and none of them had to be staged as a warning the way
`platform_writable_field_missing_platform_source` did. A rule that fails the corpus it ships with
teaches everyone to ignore the validator.

**Why the channel set is closed at two.** `inbox` and `push` both have working delivery on a running
device — the `notificationInbox` archetype and `FlutterLocalNotificationsPlugin`. Server-initiated
push, for a member whose app is closed, is **not implemented**
(`push-delivery-api.openapi.yaml` is `0.0.0-placeholder`). A package naming a third channel would be
declaring delivery that cannot happen, which is the fabricated-value failure this whole effort exists
to remove.

**Why `notification_default_not_offered` is separate from `unknown_notification_channel`.** They fail
differently and are fixed differently: an unknown channel is a typo or an invention, while a default
outside the offered set is a coherent pair of values that contradict each other. Collapsing them into
one code would tell an author "bad channel" when the channel is fine and the relationship is wrong.

### Documents (added 2026-08-26)

| Code | Meaning | Fix |
| --- | --- | --- |
| `document_upload_stores_no_content` | A transition declares the `documentLibrary` `upload` action while setting the library's `url` content field from a member-supplied `{input.…}`. It publishes a link under the upload action's name. | Decide which the community actually wants. For a **stored** library, drop the input and let the Document Library API write the field — see [`document-library.md` §3a](../archetypes/document-library.md). For a **link** library, this transition is not an upload: use `edit`, or a community-defined transition with no `action`. |
| `document_library_is_link_only` *(warning)* | A `documentLibrary` workflow keeps its content in a `url` field and declares no `upload` action, so nothing can ever be stored through the Document Library API. | Nothing, if the product doc describes a library of external resources — four of the five shipped document libraries are exactly that, deliberately. Justify it in Gaps/assumptions naming this finding. Only add an `upload` transition if the product doc says members add files. |

**Why `upload` is not just a label.** The Document Library API derives permission to store files from
whether a fan can invoke an `upload` transition. Declaring one therefore grants file-storage
authority; declaring one for what is really a URL paste hands that authority out for a paste. This is
the only action in any archetype vocabulary that carries a platform capability, so it is the only one
where the wrong choice is a security question rather than a wording question.

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
| `orphaned_response_rows` | A terminal/destructive transition ends a workflow that owns response rows, without sweeping them. A row cannot see its parent's state, so those rows stay live and keep accepting responses after the event is cancelled. **Promoted from warning to error on 2026-08-20 (the D3 ratchet).** It was a warning while six shipped communities tripped it; Phase F regeneration brought the corpus to zero, which was the exit condition its approval named, so the fix can no longer regress. Historically it was a pre-existing hole the array shape merely hid, since arrays lived on the event and were cancelled along with it. | Add one `transitionRelated` effect **per source state** to the ending transition (a filter matches one state at a time), targeting a transition on the response workflow: `{"op": "transitionRelated", "transitionId": "event-cancelled", "relatedQuery": {"workflowType": "<response-type>", "filter": {"eventId": "{id}", "$state": "going"}}}`. Worked example: [`archetypes/event-rsvp.md`](../archetypes/event-rsvp.md) §5. |
| `missing_visibility_fields` | The workflow's archetype uses a visibility model that reads instance-data identities (`owner_and_shared`, `participants`, `parties`, `recipient`) but declares no `visibility.fields` mapping. The engine cannot guess which field is a party rather than an audit actor. | Declare the mapping — see [`workflow-grammar.md`](../reference/workflow-grammar.md)'s `visibility.fields`. For `notificationInbox` specifically, an omitted `recipient` is **legal** and means broadcast, so this does not fire for that case. |
| `dangling_visibility_field` | A field named in `visibility.fields` is not declared in this workflow's `instanceDataSchema`. | Declare the field, or fix the name. A mapping pointing at a non-existent field silently admits nobody. |
| `invalid_visibility_field_type` | A field named in `visibility.fields` has a declared type that the mapping cannot read: `sharedWith` requires `fanId[]`; each `participants` entry requires `fanId` or `fanId[]`; each field-backed `parties` entry and `recipient` require `fanId`. | Change the named field's schema type to the required identity shape, or point the mapping at the correctly typed identity field. |
| `invalid_parties_arity` | `visibility.fields.parties` does not name exactly two fields. | `parties` means the two sides of a request. For more than two readers use `participants`; for one, use `recipient`. |
| `no_read_visibility_declared` (warning) | A workflow type omits the workflow-level `visibility` block, so its read policy is implicit even though the compatibility default remains `public`. | Add `"visibility": {"default": "public"}` (or `"default": "membersOnly"` / `"default": "guarded"` with a sibling `"readGuard"`) to make the community's intended read policy explicit. |
| `no_render_binding_for_reachable_state` (warning) | A state is reachable via a transition path but no `renderBinding`'s `states` list covers it, so an instance sitting there renders on no tab. | Add a `renderBinding` (often `"bindingKind": "summary"`) whose `"states"` includes it, or confirm the state is intentionally never surfaced. |
| `dead_role_binding` (warning) | `role: "receiver"` used on a `tabId` other than `admin` without `audienceMemberField` (only `admin` ever grants the receiver role), or a non-`"any"` role used on `tabId: "calendar"` (which passes no role-resolution callback at all — only `"any"`, or `"receiver"` + a working `audienceMemberField`, can render there). | Use `role: "any"` instead, move the binding to `admin`, or add `audienceMemberField` for a dynamic-audience notification. See `render-bindings.md`'s per-tab resolution table. |

---


> **Two codes were removed from this table on 2026-08-20** because the validator can no longer emit
> them, and the conformance test caught that they still had entries here. `legacy_experience_schema`
> warned that a package used the pre-4 version triple; the specVersion-4-only cut replaced that
> warning with the `legacy_version_stamp` **error**, since a legacy package no longer loads at all.
> `unknown_instance_persona` described an undeclared `createdByPersonaId`, and that spelling is
> retired — the v4 equivalent is `seed_instance_missing_creator`.

## The remaining findings — what the validator reports

The table above is the curated set: each row carries a diagnosis and a fix direction, because those
are the findings that most need one.

The validator can emit **115** finding codes. The table above documents 41 of them. The 74 below were
undocumented entirely until 2026-08-20, when the capability conformance test in
`validator_capability_conformance_test.dart` counted them — an author who hit one had nothing to
look up.

**These rows quote the validator's own message rather than paraphrasing it.** A paraphrase of 74
messages is 74 chances to describe something the validator does not actually say, and the point of
this section is that the codes stop being invisible, not that they read prettily. `<x>` stands where
the message interpolates a workflow, field or transition name.

They do not yet carry a *fix direction*, which is what makes the curated table above worth reading.
Adding those is real per-code work — the diagnostic in "Diagnosing a finding" applies to every one of
them meanwhile, and it is the part that generalises.

| Error | What the validator reports |
|---|---|
| `actor_equals_field_on_list_type` | Transition "<x>"'s guard.actorEqualsField references "<x>", which is list-typed. actorEqualsField compares a single scalar value and cannot be used with a list field (use actorInList instead). |
| `ambiguous_workflow_archetype` | Workflow "<x>" names more than one bespoke cardSurfaceFamily (<x>), so its archetype is undecidable and its transitions could belong to either closed vocabulary. Mixing one bespoke family with. |
| `context_reference_outside_instance_action` | {context.x} interpolation is only valid inside instance-scoped action prefill or inputs values, not in transition effects. |
| `create_action_cannot_set_inputs` | Create actions cannot set inputs; use prefill instead. |
| `dangling_action_transition_id` | Transition action transitionId "<x>" is not declared on "<x>". |
| `dangling_action_workflow_type` | Create action workflowType "<x>" is not declared. |
| `dangling_actor_equals_field` | Transition "<x>"'s guard.actorEqualsField references "<x>", which is not declared in instanceDataSchema. |
| `dangling_allowed_persona_id` | Transition "<x>"'s guard.allowedRoleIds references "<x>", which does not appear in the known role registry. This may indicate a typo or a role ID that was not declared anywhere. |
| `dangling_filterable_facet_field` | filterableFacets field "<x>" must be a declared formula field. |
| `dangling_generate_recurring_target` | generateRecurringInstances references workflowType "<x>", which is not a known workflow type in the loaded definitions set. |
| `dangling_recurrence_anchor_field` | generateRecurringInstances anchorField "<x>" must be a key in fields. |
| `dangling_recurrence_set_pos_without_weekday` | monthly recurrence bySetPos requires byDayOfWeek. |
| `dangling_related_aggregate_filter_field` | relatedAggregate.filter references "<x>", which is not declared on "<x>". |
| `dangling_related_aggregate_workflow_type` | relatedAggregate.workflowType "<x>" is not declared. |
| `dangling_related_list_field` | dangling_instance_data_key Target instance workflow "<x>" does not declare "<x>". computed_field_written_by_effect Effect writes computed target field "<x>". |
| `dangling_response_table_workflow_type` | responseTable.workflowType "<x>" is not declared. |
| `dangling_source_query_workflow_type` | Source query references workflowType "<x>", which is not a known workflow type in the loaded definitions set. dangling_instance_data_key Source query foreignField "<x>" is not declared in "<x>"'s. |
| `dangling_transition_related_sort_key` | transitionRelated sortKey "<x>" is not declared in "<x>"'s instanceDataSchema. |
| `dangling_transition_related_transition_id` | transitionRelated transitionId "<x>" is not declared on "<x>". |
| `dangling_transition_related_workflow_type` | transitionRelated references workflowType "<x>", which is not a known workflow type in the loaded definitions set. |
| `dangling_visibility_role` | A role named in `visibility.fields.parties` is not declared in `experience.roles[]`. invalid_visibility_principal A `visibility.fields.parties` entry must be a non-empty field name or an object. |
| `destructive_transition_ignores_availability_field` | Transition "<x>" is destructive on workflow "<x>" but does not guard on availability field "<x>", while sibling transition "<x>" on the same workflow does. This can allow terminal paths to bypass. |
| `duplicate_action_transition_id` | More than one transition action names "<x>" on this binding. |
| `identity_compared_to_role` | Compares \<x>/\<x> (a fanId) against "<x>", which is a declared roleId. This can never be true. "This person, or anyone with this role" is a fanId comparison plus an allowedRoleIds guard — they are di. |
| `invalid_recurrence_anchor_field_type` | generateRecurringInstances anchorField "<x>" must name a date field on "<x>". |
| `invalid_recurrence_count` | recurrenceRule.count must be an integer from 1 to 366. |
| `invalid_recurrence_freq` | recurrenceRule.freq must be daily, weekly, or monthly. |
| `invalid_recurrence_interval` | recurrenceRule.interval must be an integer >= 1. |
| `invalid_recurrence_month_day` | recurrenceRule.byMonthDay must be an integer from 1 to 31. |
| `invalid_recurrence_set_pos_value` | recurrenceRule.bySetPos must be first, second, third, fourth, or last. |
| `invalid_recurrence_set_pos_weekday_count` | monthly recurrence bySetPos requires exactly one byDayOfWeek entry. |
| `invalid_recurrence_weekday_code` | recurrenceRule.byDayOfWeek must be a non-empty list of unique weekday codes. |
| `invalid_source_query_syntax` | Source query "<x>" does not match the expected grammar: query(<workflowType> where <foreignField> == <localField>). dangling_source_query_workflow_type Source query references workflowType "<x>". |
| `invalid_visibility_principal` | A `visibility.fields.parties` string must be a non-empty instance-data field name. ) && principal[ ] is String && (principal[ ] as String).isNotEmpty. |
| `invalid_workflow_definition` | Workflow "<x>" could not be parsed: <x> experience/workflowDefinitions/<x>. |
| `legacy_identity_key` | specVersion 4 renamed renderBindings[].role to "audience". It never meant a community role — its values are actor/receiver/any, the viewer's relationship to an. |
| `legacy_identity_type` | Pre-specVersion-4 identity type "<x>" is unsupported. Use the corresponding fanId type in a specVersion: <x> package. See docs/references/reference/identity-types.md. |
| `legacy_version_stamp` | Pre-specVersion-4 packages are unsupported. Remove "<x>" and re-author the package with specVersion: <x> See docs/references/reference/identity-types.md. |
| `missing_experience` | Package must contain an experience object. |
| `missing_instance_id` | Instance must have a non-empty instanceId. |
| `missing_recurrence_anchor_field` | generateRecurringInstances requires a non-empty anchorField. |
| `missing_recurrence_count` | recurrenceRule.count is required. |
| `missing_recurrence_freq` | recurrenceRule.freq is required. |
| `missing_recurrence_rule` | generateRecurringInstances requires a recurrenceRule. |
| `missing_transition_action` | Transition "<x>" of bespoke workflow "<x>" must declare an action<x> Without it the transition still runs without an error, but the archetype's per-person bookkeeping for it is silently skipped. Besp. |
| `missing_workflow_definitions` | experience.workflowDefinitions must be a non-empty map. experience/workflowDefinitions. |
| `possible_fabricated_identifier` | Transition "<x>" sets identifier-like field "<x>" to a hardcoded string value "<x>", which may indicate a fabricated value instead of a platform-provided identifier. This pattern aligns with docs/refe. |
| `recurrence_field_invalid_for_freq` | recurrenceRule.<x> is invalid for daily recurrence. |
| `recurrence_month_day_set_pos_conflict` | monthly recurrence cannot use both byMonthDay and bySetPos. |
| `recurrence_weekday_without_set_pos` | monthly recurrence byDayOfWeek requires bySetPos. |
| `seed_instance_missing_creator` | Seed instance<x> must declare a non-empty creator using createdByFanId. Without that creator, the community fails to install. The field identifies a person (fanId), not a. |
| `sortable_column_without_backing_field` | Table archetype column "<x>" is declared sortable:true but the instanceDataSchema field "<x>" has sortable:false. A sortable column requires the backing field to also declare sortable:true (§3b). |
| `tab_action_cannot_be_button` | A tab-scoped action cannot use presentation "button". |
| `tab_declares_permission` | Tabs are surfaces, not capabilities, so a tab cannot grant or require a permission. permissions.md §1 defines permissions solely from role/action statements and says community JSON never contains a pe. |
| `transition_action_cannot_be_tab_scoped` | Transition actions must be instance-scoped. |
| `transition_action_cannot_set_by_persona_ids` | Transition actions cannot set byRoleIds; use the transition guard. |
| `transition_action_cannot_set_prefill` | Transition actions cannot set prefill; use inputs instead. |
| `transition_action_cannot_set_workflow_type` | Transition actions cannot set workflowType. |
| `unexpected_transition_action` | Transition "<x>" declares action "<x>", but workflow "<x>" <x> Remove the action field. |
| `unknown_action_input_reference` | Transition action input "<x>" is not declared by transition "<x>". |
| `unknown_action_kind` | actions[].kind "<x>" is not "create" or "transition". |
| `unknown_action_presentation` | actions[].presentation "<x>" is not "fab" or "button". |
| `unknown_action_scope` | actions[].scope "<x>" is not "tab" or "instance". |
| `unknown_card_surface_family` | cardSurfaceFamily "<x>" is not declared in knownWorkflowArchetypeIds (the registry-backed source of truth for render-binding families). |
| `unknown_input_reference` | Effect references {input.<x>}, but "<x>" is not declared in this transition's inputs map. |
| `unknown_input_type` | Transition "<x>" input "<x>" has unknown type "<x>". Known types: <x>. |
| `unknown_item_reference` | itemActions[].inputs references {item.<x>}, but "<x>" is not declared in the source type's instanceDataSchema. |
| `unknown_key` | Unknown key `<x>` in <x> The parser ignores it. Legal keys for this position: <x> <x>. |
| `unknown_response_table_field` | responseTable.eventField "<x>" is not declared on "<x>". |
| `unknown_response_table_state` | responseTable.pendingStates contains undeclared state "<x>". |
| `unknown_tab_id` | tabId "<x>" is not a built-in tab ("home", "messages") and is not declared in appShell.tabs/roleTabs. |
| `unknown_transition_action` | Transition "<x>" declares action "<x>", which is not in the closed vocabulary for "<x>". Allowed: <x>. |
| `unsupported_capability` | requiresCapabilities must be an array of implemented, namespaced capability names; found "<x>". requiresCapabilities unsupported_capability This build does not implement or recognise capability "<x>". |
| `unused_capability` | Package declares capability "<x>" but never uses it. requiresCapabilities[<x>] archetype.<x>. |

## What the validator does NOT catch

**Passing is necessary, not sufficient.** It cannot tell you:

- That your **modeling** is right (AP-1: a "state" that should be data will validate happily as long as
  it has transitions).
- That your **requirements** are met — it never saw the brief.
- That the app **renders** it correctly — the spec is provisional and has not run in a real app.

So: run the validator, **and** run the [anti-pattern self-check](./04-antipatterns.md), **and** re-read
the requirements against the emitted JSON.
