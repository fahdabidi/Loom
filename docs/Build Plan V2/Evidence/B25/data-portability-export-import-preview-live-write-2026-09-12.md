**Workflow:** `export-import-preview` in Data Portability Community
**Outcome:** Both halves of the proof standard were met — created a new instance live through the Admin-tab FAB as `fan-portability-owner-1` and drove it `draft → previewed → running → complete → (download, to:null) → rolled-back` (terminal), with every state change and data mutation independently confirmed in Postgres in the same session.

**Package identity:** `Loom_Communities_Workflow_Engine_DataPortabilityCommunity_Example.jsonc`
- `skillVersion`: `3.6.0`
- `sha256`: `f30994c9776871da2a4d48480f1ec83b2e7becaf16f860017dde5733ae0def43`

**Date:** 2026-09-12 · **Device:** `emulator-5554` (Windows host, reached via `ADB_SERVER_SOCKET=tcp:192.168.56.1:5037`)

---

## Identity

Authenticated account was **already signed in**; per the ticket I checked before clearing and did **not** `pm clear` anything.

- Verified in-app via the AppBar identity dialog: *"Signed in as Portability Owner 1 … ID: fan-portability-owner-1"*, role **Owner/Admin** selected.
- Fan id: `fan-portability-owner-1` · role `portability-owner`
- No sign-in or credential creation was performed. No credential was reset.

## Baseline, measured in this session before touching anything

    select count(*) from workflow_instances;                   -> 43
    select ... where workflow_type='export-import-preview';     -> 0 rows

The brief's hint (≈43 rows, few or none of this type) was **accurate this time**. Zero prior
`export-import-preview` rows existed, so this row is the first. It is distinguished by its own
instance id and `created_at`, not by the row count.

## Path driven (real UI, no test harness)

| # | Action in UI | Transition | Result state |
|---|---|---|---|
| 1 | Admin-tab FAB → **"New export or import preview"**, all 7 fields filled, **Create** | create | `draft` |
| 2 | **Preview scope** | `preview-scope` | `previewed` |
| 3 | **Export** | `start-preview-export` | `running` |
| 4 | **Confirm complete** | `complete-preview-operation` | `complete` |
| 5 | **Download export** | `download-preview-export` (`to: null`) | `complete` (unchanged — by design) |
| 6 | **Roll back** | `rollback-preview-operation` | **`rolled-back` (TERMINAL)** |

Final card header read **"Rolled back"** with **no action buttons remaining**, which is the visual
signature of the terminal state.

### The discriminated union behaved correctly

In `previewed` the card offered exactly **one** of the three start transitions — **"Export"** — and
neither "Transfer" nor "Import". That is the guard `operationType == "export"` being satisfied by
exactly one branch, which is the documented behaviour, not a missing affordance.

`operationType` was typed with `adb shell input text` and **read back from Postgres** rather than
trusted from the screen: stored value is exactly `"export"`, untruncated and correctly cased. All
seven typed fields survived intact (see below) — no truncation occurred in this run.

## Database confirmation (same session)

    PW=$(kubectl get secret postgres-credentials -n loom -o jsonpath='{.data.password}' | base64 -d)
    kubectl exec -i -n loom postgres-0 -- env PGPASSWORD="$PW" psql -U loom -d loom_workflow_service \
      -c "select instance_id, community_id, workflow_type, created_by_fan_id, current_state, created_at \
          from workflow_instances where workflow_type='export-import-preview' order by created_at desc limit 5;"

| field | value |
|---|---|
| `instance_id` | `community_data_portability_export-import-preview_4i1bbsf45q8d` |
| `community_id` | `community_data_portability` |
| `workflow_type` | `export-import-preview` |
| `created_by_fan_id` | **`fan-portability-owner-1`** |
| `current_state` | **`rolled-back`** (terminal) |
| `created_at` | `1789232878010` = **2026-09-12 17:07:58 UTC** |

`created_by_fan_id` **matches the identity I authenticated as and drove**. Exactly one row of this
workflow type exists; it is mine.

### Final `instance_data`

    {
      "startedAt":      "2026-09-12T17:10:06.010957Z",
      "completedAt":    "2026-09-12T17:10:38.113263Z",
      "previewedAt":    "2026-09-12T17:09:42.374274Z",
      "downloadedAt":   "2026-09-12T17:11:02.829030Z",
      "rolledBackAt":   "2026-09-12T17:11:49.725847Z",
      "previewLabel":   "B25ExportPreview",
      "operationType":  "export",
      "selectedScope":  ["members", "events"],
      "statusHistory": [
        {"at":"2026-09-12T17:09:42.374274Z","by":"fan-portability-owner-1","status":"previewed"},
        {"at":"2026-09-12T17:10:06.010957Z","by":"fan-portability-owner-1","status":"export started"},
        {"at":"2026-09-12T17:10:38.113263Z","by":"fan-portability-owner-1","status":"complete"}
      ],
      "redactionPreview":     "PIIRedacted",
      "destinationProvider":  "LocalVault",
      "protectedDataPolicy":  "RestrictedHold",
      "affectedMemberNotice": "MembersNotified"
    }

**`download-preview-export` (`to: null`) is proven by data, not by state**, as the ticket requires:
`current_state` stayed `complete` across the tap while `downloadedAt` was written
(`2026-09-12T17:11:02.829030Z`). The UI rendered that as a fourth timestamp chip on an otherwise
unchanged "Operation complete" card.

## Do the two halves agree?

**Yes, without qualification.** Every state the UI displayed was confirmed server-side immediately
after the tap that caused it, and every `by:` attribution in `statusHistory` — rendered on-device in
the card's History list and stored in Postgres — is `fan-portability-owner-1`. The on-device history
timestamps are byte-identical to the stored ones.

## Additional verification: the cross-workflow effect target exists and fired

`complete-preview-operation` carries a `createInstance` effect targeting `export-notification`. Per
the standing rule that a `createInstance` naming an unpublished type *returns success and does
nothing*, I checked rather than assumed:

    community_data_portability_export-notification_mt9eb3xevrhd | export-notification
      | fan-portability-owner-1 | unread | 2026-09-12 17:10:38

The notification instance was genuinely created, and its `created_at` matches this run's
`completedAt` (17:10:38) exactly. Both definitions are published in the deployed catalog at
`version 4`:

    community_data_portability_export-import-preview | export-import-preview | 4
    community_data_portability_export-notification   | export-notification   | 4

So the effect target is real, published, and observed to fire — not merely declared.

## Defects observed

**None.** Two things looked like candidate findings and both were checked against the package
declaration and found to be correct-as-designed:

1. **`statusHistory` holds 3 entries, not 5**, despite six transitions being driven. Reading the
   definition: only `preview-scope`, `start-preview-export` and `complete-preview-operation` declare
   an `append` to `statusHistory`. `download-preview-export` declares only `set downloadedAt`, and
   `rollback-preview-operation` declares only `set rolledBackAt`. The engine appended exactly the
   three entries the package asks for. Not a defect.
2. **"This is an off-path export state"** renders on the `rolled-back` card. This annotation also
   appears on other cards in this community (e.g. "Replay verified", "Redaction confirmed"), so it is
   a render-binding label for states outside a tab's primary path, not an error condition. The state
   itself is declared `"tone": "positive", "isTerminal": true` and rendered with its declared label
   "Rolled back".

**Cosmetic note, not filed as a defect:** the card title-cases stored values for display —
`PIIRedacted` renders as "Piiredacted", `LocalVault` as "Local Vault", `B25ExportPreview` as
"B25 Export Preview". The **stored** values are exact and untruncated (verified in Postgres above);
this is display formatting only.

**ANR/crash scan:** `dumpsys window` reported `<no ANR has occurred since boot>`, and a logcat scan
for `FATAL EXCEPTION`/`ANR in` returned nothing — with a control confirming logcat was readable
(203 lines) so the empty result is a real negative rather than a broken query.

## Anything not done

- No application code, community JSON, or tracker was modified. This manifest is the only file written.
- No credential was created or reset. No `pm clear` was run (the correct session already existed).
- `integration_test/on_device_remote_backend_proof_test.dart` was **not** used.
- The `error`, `cancelled`, `transfer` and `import` branches were not exercised — out of scope for
  this row, which asked for a terminal or clearly-advanced state on the preferred path.
- No test suites were run; this ticket is a live walkthrough and changed no code.
