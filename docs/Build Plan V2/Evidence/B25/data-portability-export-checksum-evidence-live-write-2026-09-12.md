**Workflow:** `export-checksum-evidence` in Data Portability Community
**Outcome:** Both halves of the proof standard were met — created a new instance live through the Admin-tab FAB as `fan-portability-owner-1`, drove it `pending` → `verified` via "Record verification pass", then fired both `verified` bookkeeping transitions ("Enable transfer", "Export verification record"), and confirmed the row and every resulting `instance_data` mutation directly in Postgres.

**Package identity:** `Loom_Communities_Workflow_Engine_DataPortabilityCommunity_Example.jsonc`
- `skillVersion`: `3.6.0`
- `sha256`: `f30994c9776871da2a4d48480f1ec83b2e7becaf16f860017dde5733ae0def43`

**Date:** 2026-09-12
**Device:** `emulator-5554` (Windows host, reached via `ADB_SERVER_SOCKET=tcp:192.168.56.1:5037`)

---

## Identity

Signed in already from the immediately preceding walkthrough; **no `pm clear` was run and no
re-authentication was needed**, per the campaign sequencing instruction.

Confirmed in-app before touching anything, via the community app-bar "Account role and permissions"
dialog:

- **Signed in as Portability Owner 1**, `ID: fan-portability-owner-1`
- Selected role **Owner/Admin** — "Owner - Selects export scope, verifies packages, transfers data,
  and starts rollbacks."

The two pre-existing Data Portability rows in Postgres are both `created_by_fan_id =
fan-portability-owner-1`, consistent with an unbroken session. The row this run created carries the
same fan id, so the evidence is attributed to the identity that was actually driven.

## Baseline, measured in this session before acting

    select count(*) from workflow_instances;                                  ->  36
    select ... where workflow_type='export-checksum-evidence' ...             ->  0 rows

The brief's hint ("about 36 rows, few or none of this type") was accurate this time. Zero prior
instances of this workflow type existed, so this row is unambiguously new; it is nonetheless
identified below by instance id and `created_at` rather than by the count moving.

## Path driven through the real UI

1. **Admin tab** of Data Portability Community → create FAB → **"New checksum evidence"**
   (present exactly as the brief predicted, `byRoleIds: ["portability-owner"]`).
2. Creation form offered three fields: **Evidence Label**, **Scope Summary**, **Verification**.
   There is no `checksum` field on the form — correct, since it is `writableBy: "platform"`.
   `Verification` is a free-text input, not a picker.
   - Evidence Label = `B25 checksum evidence`
   - Scope Summary  = `Core export bundle`
   - Verification   = `passed`
3. **Create** → instance landed in `pending`.
4. Card rendered **"Record verification pass"** and **"Cancel verification"**. Fired
   **Record verification pass** → `verified`.
5. Card then rendered **"Enable transfer"** and **"Export verification record"**. Fired **both**.

Final UI state: card shows `Verification: Passed`, `Transfer: Enabled`, three timestamp chips
(`16:09:03`, `16:09:37`, `16:10:15`), and a History entry
`{result: passed, at: 2026-09-12T16:09:03.799602Z, by: fan-portability-owner-1}`. Both `verified`
bookkeeping actions remain offered, which is correct — they are `to: null` and do not consume the
state.

No ANR and no crash dialog at any point (`dumpsys window lastanr` → "no ANR has occurred since
boot"); the app remained the resumed activity throughout.

## Independent Postgres confirmation (same session)

    instance_id        community_data_portability_export-checksum-evidence_d7hkza4ahcbw
    community_id       community_data_portability
    workflow_type      export-checksum-evidence
    created_by_fan_id  fan-portability-owner-1
    current_state      verified
    created_at         1789229309383
    updated_at         1789229415093

Final `instance_data`:

    {
        "verifiedAt": "2026-09-12T16:09:03.799602Z",
        "auditHistory": [
            {
                "at": "2026-09-12T16:09:03.799602Z",
                "by": "fan-portability-owner-1",
                "result": "passed"
            }
        ],
        "scopeSummary": "Core export bundle",
        "evidenceLabel": "B25 checksum evidence",
        "transferEnabledAt": "2026-09-12T16:09:37.932707Z",
        "evidenceExportedAt": "2026-09-12T16:10:15.093798Z",
        "verificationResult": "passed",
        "transferEligibility": "enabled"
    }

Row count after the run: **37 total, 1 of type `export-checksum-evidence`** (was 36 / 0).

### Do the two halves agree?

**Yes, on every checked field.** The UI showed `Verification: Passed` / `Transfer: Enabled` and three
timestamps; the row holds `verificationResult: "passed"`, `transferEligibility: "enabled"` and
exactly those three timestamps. `created_by_fan_id` is `fan-portability-owner-1`, matching the
identity confirmed in-app before the run.

### The two `to: null` transitions proved themselves in `instance_data`, not in `current_state`

As the brief anticipated, these two look like no-ops on screen. They are not:

| Transition fired | `current_state` | What actually changed in `instance_data` |
|---|---|---|
| `record-checksum-pass` | `pending` → **`verified`** | `verifiedAt` set; `auditHistory` gained its one entry |
| `enable-transfer` | `verified` → `verified` | `transferEligibility` **`disabled` → `enabled`**; `transferEnabledAt` added |
| `export-checksum-evidence-record` | `verified` → `verified` | `evidenceExportedAt` added |

Each was confirmed by a separate query taken immediately after that tap, so the three mutations are
attributed to the three transitions individually rather than inferred from the end state.

### `checksum` is absent, and that is the expected result

`checksum` (`writableBy: "platform"`, `platformSource: "checksum"`, `text?`, `hideWhenEmpty: true`)
does **not** appear in `instance_data` and is not rendered on the card. The checksum platform service
does not exist yet; the package declares this honestly. **Not reported as a defect.** It was not
found populated, which would have been the surprising outcome.

## Defects observed

**None.** Every affordance the brief predicted from the shipped package was present on the device,
every guard admitted the `portability-owner` identity, and no transition was refused. No `403`, no
`unknown_permission_id`, no unreachable state.

## Note on method, not a product finding

`adb shell input text "B25 checksum evidence"` delivered only **`B25`** — the remote shell splits on
spaces, so everything after the first word was lost. The same happened to `Core export bundle`
(→ `Core`). This is a defect in my input method, not in the product. It was caught on-screen before
submission and corrected by appending the remainder with `%s`-escaped spaces, and all three final
values were verified against the stored row afterwards.

Worth recording because it is a *different mechanism* from the truncation trap already documented
(which loses a suffix mid-word and leaves a plausible-looking prefix): here the value is cut at the
first space, and the surviving text is a clean word that reads like a deliberate short entry.
`verificationResult` — the single load-bearing value here, read by three of the seven transitions —
is a single word and so was never at risk from this particular failure, and it was confirmed as
exactly `passed` in Postgres before any conclusion was drawn about button availability.
