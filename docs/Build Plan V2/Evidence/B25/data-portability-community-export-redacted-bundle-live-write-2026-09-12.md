**Workflow:** `export-redacted-bundle` in Data Portability Community
**Outcome:** Both halves of the proof standard were met — signed in as `fan-portability-owner-1`, I created a redacted bundle through the Admin tab FAB, drove it `draft → generating → complete`, set `redactionValidationResult = passed` through the real in-card editor, and fired `download-redacted-bundle`, confirming every step against the stored Postgres row.

**Package identity:** `skillVersion` `3.6.0`, `sha256` `f30994c9776871da2a4d48480f1ec83b2e7becaf16f860017dde5733ae0def43`
(`app/packages/core/loom_communities_app_shell/assets/Loom_Communities_Workflow_Engine_DataPortabilityCommunity_Example.jsonc`, `specVersion 4`)

**Date:** 2026-09-12 · **Device:** `emulator-5554` (Windows host, reached via `ADB_SERVER_SOCKET=tcp:192.168.56.1:5037`)

---

## 1. Identity — already authenticated, nothing cleared

The ticket said the three prior walkthroughs had signed in as `loom-portability-owner-1`, and to check
before clearing anything. I checked first: the AppBar identity dialog read **"Signed in as Portability
Owner 1 … ID: fan-portability-owner-1"**, role **Owner/Admin** (`portability-owner`), with Member and
Receiving Provider listed as other available roles.

That is the identity this row needs, so I ran **no** `pm clear` on either Chrome or the app, and made no
OAuth round trip. No credential was created or reset. The community's own header banner repeated
`Signed in as Portability Owner 1 / Owner/Admin` on every tab I visited, and the final row's
`created_by_fan_id` independently confirms the attribution.

## 2. Baseline — measured, not trusted

The brief's hint (~39 rows, few or none of this type) was accurate, unlike the two stale baselines of
2026-09-09:

| Query | Result |
|---|---|
| `count(*) from workflow_instances` | **39** |
| `where workflow_type='export-redacted-bundle'` | **0 rows** |
| Data Portability rows by type | 5 (checksum-evidence, full-bundle, notification, protected-redaction, schema-listing — 1 each) |

So there was no prior instance of this workflow. I did not look for one, and distinguish my row by its
own instance id and `created_at` rather than by any change in the count.

Both definitions this run depends on are published: `community_data_portability_export-redacted-bundle`
and `community_data_portability_export-notification`, both `version 4`. (The 2026-09-08 full-bundle
manifest recorded `export-notification` as **declared but unpublished** — that gap has since been
closed, which this run then exercised for real; see §5.)

## 3. The path I drove

Create affordance and states matched the shipped package exactly; the device contradicted nothing.

| # | Action | UI result | Stored row after |
|---|---|---|---|
| 1 | Admin tab FAB → speed-dial → **"New redacted bundle"** | Dialog with 5 required fields | — |
| 2 | Filled `bundleLabel=RB25`, `scope=core`, `redactionSummary=pii`, `destination=s3`, `memberNotice=note` → **Create** | Card "Redacted bundle scope" | `draft`, `scope: ["core"]` |
| 3 | **"Generate redacted bundle"** | Card "Generating redacted bundle" | `generating`, `generationStatus: running`, `generationStartedAt: 16:34:35.088430Z` |
| 4 | **"Mark generation complete"** | Card "Redacted bundle complete", chip `Download: waiting for redaction validation` | `complete`, `generationStatus: complete`, `generationCompletedAt: 16:35:08.362507Z` |
| 5 | Home tab card → **"Redaction validation"** field → typed `passed` → **"Save changes"** | Chip `Redaction validation: Passed` | `redactionValidationResult: "passed"` |
| 6 | **"Download redacted bundle"** | Chip `Download: Downloaded` | `downloadState: downloaded`, `downloadedAt: 16:41:37.676641Z`, state still `complete` |

Step 6's transition declares `to: null`, so the state correctly **stays** `complete` — the proof it
fired is the `instance_data` mutation, not a state change, and both effects landed.

### Both load-bearing typed values were settled against the database, not the screen

`scope` gates Generate and `redactionValidationResult` gates Download, and `adb shell input text`
truncates silently. I kept both values short and read both back from Postgres:

- `scope` → `["core"]` — a genuine 1-element **list**, so `size(scope) > 0` was satisfied by real data.
  Note the create form renders `scope` as a **free-text field, not a picker**, so typing was the only
  option here; the picker-manufactures-invalid-data failure mode did not apply.
- `redactionValidationResult` → exactly `"passed"` (6 chars, untruncated). A truncated `passe` would
  have made the Download button silently absent and looked like a missing affordance.

All five creation fields round-tripped intact:
`{"bundleLabel":"RB25","scope":["core"],"redactionSummary":"pii","destination":"s3","memberNotice":"note"}`

## 4. The DB row, and whether it agrees with the UI

```
select instance_id, community_id, workflow_type, created_by_fan_id, current_state,
       to_timestamp(created_at/1000.0) at time zone 'UTC'
from workflow_instances where workflow_type='export-redacted-bundle';
```

| Field | Value |
|---|---|
| `instance_id` | `community_data_portability_export-redacted-bundle_1bcijdoij78z` |
| `community_id` | `community_data_portability` |
| `workflow_type` | `export-redacted-bundle` |
| `created_by_fan_id` | **`fan-portability-owner-1`** |
| `current_state` | `complete` |
| `created_at` | **2026-09-12 16:32:00.104 UTC** |

Final `instance_data`:

```json
{"bundleLabel":"RB25","scope":["core"],"redactionSummary":"pii","destination":"s3",
 "memberNotice":"note","generationStatus":"complete",
 "generationStartedAt":"2026-09-12T16:34:35.088430Z",
 "downloadState":"downloaded","generationCompletedAt":"2026-09-12T16:35:08.362507Z",
 "redactionValidationResult":"passed","downloadedAt":"2026-09-12T16:41:37.676641Z"}
```

**The two halves agree, field by field.** Every chip the card rendered has a matching stored value:
`RB25` ↔ `bundleLabel`, `1 components` ↔ `scope` length 1, `Redaction validation: Passed` ↔
`redactionValidationResult`, `Generation: Complete` ↔ `generationStatus`, `Download: Downloaded` ↔
`downloadState`, and the three timestamp chips ↔ `generationStartedAt` / `generationCompletedAt` /
`downloadedAt`. `created_by_fan_id` is the identity I authenticated as and drove as.

Exactly **one** `export-redacted-bundle` row exists and it is mine. Totals moved 39 → **41**: my
instance plus one `export-notification` (§5).

No ANR and no crash: `dumpsys window lastanr` reported `<no ANR has occurred since boot>` and
`logcat` showed no `FATAL EXCEPTION`.

## 5. The `createInstance` effect fired for real — a positive delta since 2026-09-08

`complete-redacted-bundle` carries a `createInstance` effect targeting `export-notification`. The
2026-09-08 full-bundle manifest recorded that **all 7** such effects across this package pointed at an
**unpublished** type, so every one of them silently did nothing. That is no longer true here:

- `export-notification` count went **1 → 2**.
- The new row `community_data_portability_export-notification_mrni8ax93n05` is `unread`, created
  `16:35:08` — the same instant as my `generationCompletedAt` — with `created_by_fan_id`
  `fan-portability-owner-1`.
- The **Home tab rendered it**, naming my instance: `Source: Export Redacted Bundle`,
  `Record: Community Data Portability Export Redacted Bundle 1bcijdoij78z`.

So the effect target is published and the effect is observable end to end in the UI, not merely in a
table.

## 6. Defect observed — a known UX discoverability defect, re-confirmed on this workflow

**This is not a new finding.** It is the same defect the 2026-09-08 `export-full-bundle` manifest
recorded under "Shape 3", and this run confirms it reproduces identically on `export-redacted-bundle`.
Recording it here because it is a second instance of the same shape, in the same community, on a
different workflow — not because it is newly discovered.

The editor for the field and the actions gated on that field live on **different tabs**:

| Tab | Binding | Card | `redactionValidationResult` editor | Actions gated on it |
|---|---|---|---|---|
| `admin` (primary, has the create FAB) | `exportWizard` | `ExportWizardArchetypeCard` | **absent** | rendered |
| `documents` | `exportWizard` | `ExportWizardArchetypeCard` | **absent** | rendered |
| `home` (summary) | `statusTimeline` | falls through to `GenericWorkflowInstanceCard` | **present** | rendered |

Mechanism, verified in code and then on the device:

- `part27_engine_native_binding_dispatcher.dart:461` routes `exportWizard` to the bespoke
  `ExportWizardArchetypeCard`, and that widget (`part36_engine_native_marketplace_surface.dart`,
  lines 1990–2680, 691 lines) contains **zero** occurrences of `editableFields`, `editGuard`,
  `TextField`, `TextFormField` or `TextEditingController`. It renders transitions only.
- `statusTimeline` is **not** one of the dispatcher's bespoke families, so it falls through to
  `GenericWorkflowInstanceCard`, whose `_editableKeys` honours the state's `editableFields`.
- No transition on this workflow declares `inputs`, so `_collectTransitionInputs` can never collect
  the field either — the transition-input dialog is not an alternative route.

On the device, in `complete`, the Admin and Documents cards offered **only "Change redaction"**. That
is not a missing affordance: `download-redacted-bundle` requires `== 'passed'` and
`record-redaction-validation-failure` requires `== 'failed'`, and the field was empty, so both guards
correctly failed closed. Tapping the card and long-pressing it opened nothing — the card has no
detail route.

**Two controls kept this from being reported as a dead path.** First, the sibling
`export-full-bundle` card, on the same `exportWizard` surface two cards above mine, *did* render
**"Download full bundle"** — proving the surface renders `download` actions fine, so my card's
omission was guard-driven rather than a rendering fault. Second, after I set the field on Home, the
Admin card itself began rendering **"Download redacted bundle"**. So the action renders on Admin and
the editor never does.

**Why it still matters.** An owner works from the Admin tab — it hosts the create FAB and the package
describes it as "Export scope, verification, provider transfer, rollback, and audit operations." From
there the instance reaches `complete` and presents no way forward, and the one escape the card does
offer, "Change redaction", sends the instance **back to `draft`**, discarding the completed
generation. Nothing on the Admin card indicates the required field is editable one tab away. The
capability is reachable; discovering it is not.

Structurally the workflow is sound: every state is reachable, `complete` has all its declared exits,
and the guards are well-formed and correctly fail closed on an empty field.

**The product doc confirms the guard behaviour is the intended design, not the defect.**
`docs/references/communities/data-portability-community-product-experience.md:107` states for this
workflow: *"download disabled until redaction passes"*. So the withheld Download button in `complete`
is the doc's own requirement being honoured, and this run demonstrated it in both directions — absent
while the field was empty, present and firing once it read `passed`. The defect is strictly the
placement of the editor relative to the actions, nothing about the gating itself.

## 7. Scope note

I did not modify application code, community JSON, or any tracker, and created/reset no credential.
This manifest is the only file added. `integration_test/on_device_remote_backend_proof_test.dart` was
not used. No test suites were run — this was a live device walkthrough, not a code change.
