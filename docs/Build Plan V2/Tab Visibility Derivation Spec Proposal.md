---
spec: 4
doc_version: 1.0.0
status: approved
last_verified: 2026-08-20
audience: llm-agent
---

# Tab visibility should be derived, not declared

**Status: APPROVED by the user 2026-08-20, not yet built.** Written 2026-08-20. Supersedes the `requiredPermission` direction
taken earlier the same day, which was wrong for the reason in §2.

## 1. The proposal, in one line

Remove `requiredPermission` from the `appShell.tabs[]` grammar. Derive a tab's visibility from the
role guards on the workflows bound to it, which the author already writes.

## 2. Why the current field violates the permissions model

`permissions.md` §1 is unambiguous:

> A community's JSON says **which role performs which action**. That statement, and nothing else, is
> what grants a permission.
>
> Community authors never write a permission, a permission id, a role-to-permission mapping, or a
> user... **community JSON never contains a permission.**

`requiredPermission` is a permission id, written by a community author, inside community JSON. It is
the one field in the grammar that contradicts the model's founding rule.

Two directions were considered earlier and both are wrong for the same reason:

- **Add `community.surface.*` to the permissions vocabulary.** Still has authors writing permission
  ids; it legitimises the violation rather than removing it.
- **Map tabs onto the existing vocabulary** (an admin tab requires `community.manage_settings`).
  Reads well, and still has authors writing permission ids.

The field's origin explains its shape: until 2026-08-20 the app shell supplied the value from a
hardcoded per-community table, so no author ever wrote one. Deleting that table exposed the field
for the first time — and what it exposed is that the field should not exist.

**The corpus already agrees.** Before this pass, **46 of 46 tabs declared no `requiredPermission`**,
across eleven independently authored communities. Authors were following the model correctly. The
one exception is Ad-Free Community, which now declares it because this pass asked it to — see §6.

## 3. What derivation looks like

The author writes the access rule where the model wants it, on the transition:

```jsonc
"ad-off-settlement": {
  "renderBindings": [
    { "tabId": "admin", "cardSurfaceFamily": "approvalQueueItem", "bindingKind": "primary" }
  ],
  "transitions": [
    { "id": "settle-allocation", "action": "approve",
      "guard": { "allowedRoleIds": ["ad-off-owner"] } }
  ]
}
```

And the tab declares only what it *is*:

```jsonc
"appShell": {
  "tabs": [
    { "tabId": "admin",
      "label": "Admin",
      "rendererContractId": "admin-review-compose-queue",
      "iconKey": "admin",
      "description": "Settlement, allocation correction, and audit operations." }
  ]
}
```

The Admin tab is visible to `ad-off-owner` because that is the only role that can do anything bound
to it. No permission string appears anywhere.

This is exactly `permissions.md` §1's own derivation, applied one level up:

```
guard.allowedRoleIds on T      ->  those roles may perform T
T.action + workflow archetype  ->  the permission T requires
                               ->  grant that permission to those roles
tab renders T                  ->  the tab is visible to those roles     <- the new line
```

### The rule

A tab is visible to a role if that role appears in `allowedRoleIds` (or `byRoleIds` on a create
action) of **any** transition on **any** workflow bound to that tab.

`home` and `messages` remain unconditionally present, per `render-bindings.md` — they are platform
tabs and their existence is not community-configurable.

## 4. The runtime-guard case, and why it is smaller than it looks

`permissions.md` §2 divides access into two layers, and only one is pre-grantable:

| Kind | Occurrences | Resolved by |
|---|---|---|
| `allowedRoleIds`, `byRoleIds` | 652 | App Access — pre-granted |
| `actorEqualsField`, `actorInList` | 243 | Workflow engine — per-instance, at runtime |

The obvious worry is a tab whose visibility depends on per-instance ownership, which cannot be
decided before the instances are read. Measured across all 46 tabs in the eleven shipped
communities:

| | tabs |
|---|---|
| **mixed** — role guards *and* runtime guards | 35 |
| **role-only** — derivable outright | 11 |
| runtime-only | **0** |
| no bindings at all | **0** |
| no guards at all | **0** |

**Every tab in the corpus has role-based guards.** Not one depends solely on runtime identity.

That resolves the worry rather than deferring it: the two layers answer different questions. Role
guards decide *whether this role can act in this tab at all* — which is what visibility needs.
Runtime guards decide *which instances that person sees inside it* — which is filtering, and already
happens after the tab is open.

So tab visibility needs only the derivable layer. A mixed tab is visible to the role, and its
contents are then filtered per-instance exactly as today.

**The residual case is real but empty today**: a tab bound only to workflows guarded solely by
`actorEqualsField`. Nothing in the corpus does this. Proposed rule: such a tab is visible to all
members, and its contents filter to nothing for a viewer who owns no instance — the same
empty-state the shell already renders. A validator warning (`tab_visibility_not_derivable`) can flag
it if one ever appears, rather than the grammar growing a field for a case that does not exist.

## 5. Why this is also the smaller change

`personaHasPermission` already derives its answer from the JSON's guards. It takes the declared
permission string, parses it by **suffix** (`.read` vs `.configure`), and then reads the guards
anyway. The string is vestigial: it selects a branch and contributes nothing else.

Removing `requiredPermission` deletes the parsing, not the logic.

It also closes the client/backend vocabulary split without inventing anything. There is no second
namespace to reconcile, because there is no namespace: the client derives from the same guards App
Access derives from, so both sides answer from one source.

## 6. Migration

1. **Spec** — remove `requiredPermission` from `render-bindings.md`'s tab shape; delete the
   "declare it on every privileged tab" section added earlier today (`61a23356`); document the
   derivation rule and the platform-tab exception.
2. **Validator** — error on `requiredPermission` in a tab declaration, naming the derivation rule.
   It is a permission in community JSON, which `permissions.md` forbids.
3. **App shell** — replace the permission-string branch in `isVisibleFor` with the derivation. Keep
   the enforcement default from `99f9a162` — that change was correct and is independent: it made
   Dart act on the answer, and this changes how the answer is computed.
4. **Ad-Free Community** — is now the only package declaring the field, added by this pass before
   the model conflict was understood. It reverts with the rest of the deferred JSON rework, not
   before. Harmless meanwhile: the value it declares matches what derivation would conclude.

Nothing here needs the ten deferred regenerations. The other ten packages are **already correct**
under this proposal, because they never declared the field.

## 7. What this does not change

- `visibleRoleIds` on a tab stays. It narrows visibility explicitly and is not a permission — it
  names roles, which is what the model says authors write. Note `99f9a162` fixed it to *only*
  narrow; it used to short-circuit past the permission check entirely.
- Runtime guards keep filtering instance contents.
- The backend stays the authority for data and actions. This is the visibility layer only.

## 8. Resolved: derive from any transition's roles

**Decided with the approval, 2026-08-20**, by taking this section's own recommendation. If the stricter reading was intended, say so and it changes one predicate.

Whether visibility should derive from **any** transition's roles (proposed above) or only from
`view`-action bindings. "Any" is simpler and matches the intuition that a tab you can act in is a
tab you can see. A stricter reading — visible only if you can *read* something there — would need
`view` to be reliably declared, and it currently is not.
