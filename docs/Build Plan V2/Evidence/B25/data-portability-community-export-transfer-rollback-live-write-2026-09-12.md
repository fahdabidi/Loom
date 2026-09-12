**Workflow:** `export-transfer-rollback` in Data Portability Community
**Outcome:** Both halves of the proof standard were met — signed in as `fan-portability-owner-1`, created a provider transfer, drove it to `transferring`, pressed the now-rendering "Request rollback" button to create `export-transfer-rollback`, and drove that instance through `available → running → complete` (terminal), confirmed in Postgres.

**Package identity:** `Loom_Communities_Workflow_Engine_DataPortabilityCommunity_Example.jsonc`
- `skillVersion`: `3.6.0`
- `sha256`: `f30994c9776871da2a4d48480f1ec83b2e7becaf16f860017dde5733ae0def43`

**Build under test:** `com.example.loom_communities_demo`, `lastUpdateTime=2026-09-12 11:28:15` — after fix commit `f869e81e` (2026-09-12 11:23:19 -0700, "fix(app-shell): forward instance-scoped create actions to every card family").

**Identity:** Keycloak `loom-portability-owner-1` / fan id `fan-portability-owner-1`, role `portability-owner` (shown in-app as "Portability Owner 1 — Owner/Admin"). The session survived the `adb install -r` reinstall; no credential was created or reset, and nothing was cleared.

---

## The defect this run re-tested: FIXED, confirmed on device

The earlier walkthrough today found `export-transfer-rollback` uncreatable because the app shell's
binding dispatcher did not forward instance-scoped create actions to the `exportWizard` card family.

**"Request rollback" now renders.** On the Admin tab, on the `export-transfer-verification` card in
state `transferring`, the card showed four actions: *Send for provider verification*, *Record
transfer error*, *Cancel transfer*, and **Request rollback**. Pressing it opened the create dialog
and created a real instance. The defect is closed.

### One thing that would have been mis-reported, recorded so nobody repeats it

The same card on the **Transfer** tab shows only three actions and **no "Request rollback"** — and
that is correct, not a residual bug. The package declares the rollback create action only on
`tabId: "admin"` bindings (states `transferring`/`awaiting-provider`/`failed`, and separately
`verified`); the `tabId: "transfer"` binding for the same states declares **no actions at all**.
I observed the Transfer-tab card first and it looked exactly like the unfixed defect. Reading the
package's binding declarations, not the screen, is what distinguished "action not declared on this
tab" from "action declared and dropped by the dispatcher".

---

## Path driven

1. **Admin** tab → FAB → **"New provider transfer"**. Fields: Transfer Label `RB1`, From `srcA`,
   To `dstB`, Transfer Scope `posts`. Created in `draft`.
2. **Start transfer** (`start-provider-transfer`, guard `size(transferScope) > 0`) → `transferring`.
   Card showed `Status: Transferring`, `Rollback: Available`.
3. **Request rollback** pressed on that card (Admin tab) → create dialog, prefilled.
4. Dialog: Rollback Label `RBK1`, Rollback Reason `bad`, Available toggle ON. **Create** →
   new instance in `available`.
5. **Roll back transfer** (`start-transfer-rollback`, guard `rollbackAvailable == true`) → `running`.
6. **Confirm rollback complete** (`complete-transfer-rollback`) → **`complete`** (`isTerminal`).
   Card rendered "Rollback complete", `Status: Restored`, and no further action buttons.
7. **Cancel transfer** on the source transfer → `cancelled` (terminal).

## Database confirmation (same session)

```
 instance_id                                                      | workflow_type            | created_by_fan_id       | current_state
 community_data_portability_export-transfer-rollback_8dmyaeanrm0d | export-transfer-rollback | fan-portability-owner-1 | complete
```

- `created_at`: `1789238364197` = **2026-09-12 18:39:24 UTC**
- `community_id`: `community_data_portability`
- Source transfer: `community_data_portability_export-transfer-verification_tqt9zpajt8b4`,
  final state `cancelled`, also `created_by_fan_id = fan-portability-owner-1`.

**Do the two halves agree?** Yes. The device showed "Rollback complete" / `Status: Restored` with no
remaining actions, and the row reads `current_state = complete`. `created_by_fan_id` is
`fan-portability-owner-1`, the identity I authenticated and acted as — no stale-SSO mismatch.

## `sourceTransferInstanceId` — `{context.id}` RESOLVES CORRECTLY

Stored value, read verbatim from Postgres:

```
community_data_portability_export-transfer-verification_tqt9zpajt8b4
```

This is **exactly equal** to my transfer instance's id (verified by SQL equality, which returned
`t`). It is not empty, not null, and not the literal `{context.id}`.

**This answers the open tracker question.** `{context.id}` in a `scope: "instance"` create prefill —
a third interpolation context, distinct from the effect-field `{id}` measured earlier today and from
the `transitionRelated` filter case — resolves to the context instance's id. The other three prefills
resolved too: `sourceProvider` → `srcA`, `destinationProvider` → `dstB`, both from `{context.*}`.

## `rollbackAvailable` stored type

`jsonb_typeof` returns **`boolean`**, value `true` — a real JSON boolean, not the string `"true"`.
`start-transfer-rollback` (guard `instanceDataEquals: rollbackAvailable == true`) rendered and fired,
consistent with that.

## Baseline (measured, not assumed)

- Before: **46** rows in `workflow_instances`; **zero** `export-transfer-rollback` rows.
- After: **48** rows; **one** `export-transfer-rollback` row — mine, distinguished by instance id
  `..._8dmyaeanrm0d` and `created_at` 18:39:24 UTC.
- The brief's hint of ~46 rows was accurate this time.
- A prior `export-transfer-verification` row (`..._0tx8cno6yx9j`, `cancelled`, 17:24 UTC) exists from
  today's earlier run. Not mine; excluded by id and timestamp.

## Defects and observations

- **No product defect found in this workflow.** Every declared transition rendered for the guarded
  role, the terminal state was reached, and the prefill mechanism worked.
- **`adb shell input text` truncation hit twice, both cosmetic and both caught:**
  - Typing into the first form before the keyboard settled put two values in one field
    (`RB1srcA`); corrected and re-verified on screen and against the stored row.
  - `"bad count"` stored as `"bad"` — the space truncated the input. `rollbackReason` is free text
    and gates nothing. The load-bearing values (`transferScope`, `sourceTransferInstanceId`) were
    settled against the database, not the screen.
- **`uiautomator dump` was useless here** — it returned trees with every `text` attribute empty, so
  text searches over it proved nothing in either direction. All findings above rest on screenshots.
- No ANR or crash dialog: `dumpsys window lastanr` reports `<no ANR has occurred since boot>`.
- No `403` / `unknown_permission_id`. Every create and transition was accepted.

## Not done

- No test suites were run; this was a device walkthrough. No application code, community JSON, or
  tracker was modified, and no credential was created or reset. This manifest is the only commit.
