**Workflow:** `export-schema-listing` in Data Portability Community
**Outcome:** Both halves of the proof standard were met — signed in as `loom-portability-owner-1` through the real Keycloak form, created a schema listing through the Admin tab's "New schema listing" FAB, and drove the full preferred path (`lock-schema-listing` → `mark-schema-package-generated` → `retire-schema-listing-locked`) into the terminal `retired` state, confirming every step in Postgres.

(That outcome sentence is deliberately kept on one line: `check_b25_status.sh` matches the phrase
with a line-based grep, so wrapping it mid-phrase makes a proven row read as unproven.)

**Package identity:** `Loom_Communities_Workflow_Engine_DataPortabilityCommunity_Example.jsonc`
- `skillVersion`: `3.6.0`
- `sha256`: `f30994c9776871da2a4d48480f1ec83b2e7becaf16f860017dde5733ae0def43`
- Verified byte-identical to the copy **bundled in the installed APK**: extracted from the device's
  own `base.apk` (193,851,555 bytes) at
  `assets/flutter_assets/packages/loom_communities_app_shell/assets/…` and hashed to the same
  sha256, with `cmp` reporting no difference. This hash therefore describes the package actually
  driven, not merely the one in the working tree.

---

## Identity

| | |
|---|---|
| Keycloak account | `loom-portability-owner-1` |
| Fan id | `fan-portability-owner-1` |
| Role | `portability-owner` (app shell showed "Owner/Admin") |
| Realm / client | `loom` at `192.168.56.10:30082`, client `loom-test-client` |

Identity was switched from the previous walkthrough's `fan-hoa-member-1`. Both Chrome and the Loom
app were cleared (`pm clear com.android.chrome` and `pm clear com.example.loom_communities_demo`),
which is what produced a **real Keycloak login form** rather than a silent SSO re-issue for the old
fan. The relaunched app showed "Loaded 10 example communities", confirming the preload flag is
compiled into the installed build.

## Baseline, measured in this session before touching anything

    select count(*) from workflow_instances;                          -- 35
    select … where workflow_type='export-schema-listing' …            -- 0 rows

The dispatching session's hint ("about 35 rows, few or none of this type") was accurate this time.
A control in the same query proved the `community_id` spelling was right rather than merely empty:
`community_data_portability` already held one `export-full-bundle` row. `export-schema-listing` was
also confirmed **published** (`workflow_definitions`, version 4), ruling out the failure mode where
`createInstance` returns success and silently does nothing.

After the run the table held **36** rows. The row below is distinguished by its own instance id and
`created_at`, not by that count.

## What was driven

| Step | UI action | Resulting state |
|---|---|---|
| Create | Admin tab FAB → "New schema listing", six fields, **Create** | `editable` |
| 1 | "Lock schema scope" (`lock-schema-listing`, formula-guarded) | `locked`, `lockedAt` written |
| 2 | "Mark package generated" (`mark-schema-package-generated`, `to: null`) | stays `locked`, `packageGenerated` false→true, `generatedAt` written |
| 3 | "Retire listing" (`retire-schema-listing-locked`) | **`retired`** (terminal) |

Every engine call logged `LOOM_BINDING service=workflow-engine mode=remote … outcome=ok status=200`
against `scope=ext_data_portability_community`. No `FATAL EXCEPTION`, and `dumpsys window lastanr`
reported no ANR since boot.

Final UI state: card headed **"Schema listing retired"** with "This is an off-path export state",
carrying chips `Core`, `2 schemas`, `2 included`, `1 excluded`, `1 protected labels`, and both
timestamps — and **no action buttons**, consistent with a terminal state.

## The database row

    instance_id       community_data_portability_export-schema-listing_ee7wp6q5bh17
    community_id      community_data_portability
    workflow_type     export-schema-listing
    created_by_fan_id fan-portability-owner-1
    current_state     retired
    created_at        1789228495371  (2026-09-12 15:54:55 UTC)

Final `instance_data`:

    {"packageGenerated":true,"listingLabel":"Core",
     "schemaNames":["members.v2","events.v1"],
     "includedComponents":["members","events"],
     "excludedComponents":["tokens"],
     "protectedDataLabels":["secret"],
     "nextStep":"Lock-scope",
     "lockedAt":"2026-09-12T15:56:01.676484Z",
     "generatedAt":"2026-09-12T15:56:34.783194Z"}

**The two halves agree.** `created_by_fan_id` is `fan-portability-owner-1` — the identity actually
authenticated and selected, so this evidence is attributed to the right person. `current_state` is
`retired`, matching the terminal card on screen. The card's chips are derived from exactly the
values stored above.

## The branch the brief expected to be blocked was NOT blocked

The brief flagged that `lock-schema-listing` needs `schemaNames` and `includedComponents` to be
non-empty lists which the create action does not prefill, and that this could make the transition
unofferable. **It did not happen.** The creation form renders all six `required` fields — including
all four `list`-typed ones — as plain text inputs, and comma-separated text is parsed into real JSON
arrays. `members.v2,events.v1` was stored as `["members.v2","events.v1"]`, not as a string, so
`size(schemaNames) > 0 && size(includedComponents) > 0` evaluated true and "Lock schema scope"
was offered and fired.

Worth recording for whoever writes the next brief: the definition marks **six** fields
`required: true`, not the two the guard needs — `listingLabel`, `schemaNames`,
`includedComponents`, `excludedComponents`, `protectedDataLabels`, `nextStep`. The brief mentioned
only the two guard inputs.

## Defects observed

**None in the product.** All four transitions behaved exactly as the package declares, including
the `to: null` bookkeeping transition, which correctly preserved `locked` while mutating instance
data — and whose button then correctly disappeared once its `packageGenerated == false` guard became
unsatisfiable.

One **harness** note, not a product defect: `adb shell input text 'Core v1'` delivered only `Core`,
because the space truncated the argument. This is the documented `input text` truncation trap firing
again, in a new form (a space rather than length). It was caught by reading the value back from
Postgres rather than off the screen. `listingLabel` is not load-bearing for any guard, so the run is
unaffected — but it is why every value here was kept space-free and settled against the database.
The value on screen and the value stored agree at `Core`; nothing was silently mis-recorded.
