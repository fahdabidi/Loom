**Workflow:** `export-import-replay` in Data Portability Community
**Outcome:** Both halves of the proof standard were met — signed in as `fan-portability-owner-1`, created a new import replay through the Admin-tab FAB and drove it `prepared` → `validating` → `replayed` (declared terminal) through the real UI, with the row independently confirmed in Postgres.

**Package identity:** `Loom_Communities_Workflow_Engine_DataPortabilityCommunity_Example.jsonc`
`skillVersion: "3.6.0"`
`sha256: f30994c9776871da2a4d48480f1ec83b2e7becaf16f860017dde5733ae0def43`

Date: 2026-09-12. Device `emulator-5554` (Windows host, reached via `ADB_SERVER_SOCKET=tcp:192.168.56.1:5037`).

## Identity

Already signed in on arrival, so nothing was cleared. Confirmed **before** creating anything by
opening the account dialog from the community AppBar, which read:

    Signed in as Portability Owner 1
    Owner/Admin — Owner - Selects export scope, verifies packages, transfers data, and starts rollbacks.
    ID: fan-portability-owner-1

Role `portability-owner`, which is in the `allowedRoleIds` of every transition this run used, so no
identity switch was needed and the stale-SSO trap was not exercised.

## Baseline, measured in this session

Before touching the device:

    select count(*) from workflow_instances;                        ->  41
    select ... where workflow_type='export-import-replay';          ->  0 rows

The brief's hint (~41 rows, none of this type) was accurate this time. My row is distinguished by its
own instance id and `created_at`, not by the count.

## The path driven

Admin tab -> FAB -> speed-dial entry **"New import replay"** -> creation dialog with four fields.
Filled `Replay Label: IR25`, `Source: SRC25`, `Destination: DST25`, `Affected Member Notice: NOTE25`
— deliberately short, because `replaySource` is `required` and a truncated value would still satisfy
"non-empty". **Create** landed the instance in `prepared`.

The card was then driven from the **Transfer** tab (the package binds all five states there):

| Step | Button on device | State after | Confirmed in PG |
|---|---|---|---|
| create | "Create" | `prepared` | yes |
| `start-import-replay` | **"Import data"** | `validating` | yes |
| `confirm-import-replay` | **"Confirm replay verified"** | `replayed` (terminal) | yes |

All three `validating` exits rendered ("Confirm replay verified", "Record validation failure",
"Cancel replay"); in `replayed` the card showed **no action buttons**, consistent with a terminal
state. On-screen History read `validating · fan-portability-owner-1` and
`replayed · fan-portability-owner-1` with matching timestamps.

## The database row

    instance_id       community_data_portability_export-import-replay_uuv1m34l24oj
    community_id      community_data_portability
    workflow_type     export-import-replay
    created_by_fan_id fan-portability-owner-1
    current_state     replayed
    created_at        1789231855924  (2026-09-12 16:50:55 UTC)

`created_by_fan_id` **matches the identity I authenticated as and drove.** The UI and the row agree
on every point: same terminal state, same actor, same timestamps.

Stored `instance_data`, confirming **no `adb input text` truncation** — all four typed values are
byte-complete, and the effects wrote as declared:

    replayLabel          IR25
    replaySource         SRC25          <- required field, verified against the DB, not the screen
    destinationProvider  DST25
    affectedMemberNotice NOTE25
    validationStatus     passed
    receiverState        replay accepted
    startedAt            2026-09-12T16:53:55.166734Z
    completedAt          2026-09-12T16:54:30.482094Z
    auditHistory         [validating @16:53:55 by fan-portability-owner-1,
                          replayed   @16:54:30 by fan-portability-owner-1]

### The row count moved by 2, and both rows are accounted for

`workflow_instances` went 41 -> 43 while I created one instance. The second row is
`community_data_portability_export-notification_yghrw32zf9wn`, created at **16:54:30** — the exact
timestamp of the confirm transition. That is `confirm-import-replay`'s declared `createInstance`
effect firing, not a stray write. Worth recording because a `createInstance` naming an unpublished
type returns success and does nothing: here the target exists in the deployed catalog and the
`"{id}"` placeholder resolved correctly to the parent —

    sourceInstanceId    community_data_portability_export-import-replay_uuv1m34l24oj
    sourceWorkflowType  export-import-replay
    recipientFanId      fan-portability-owner-1

## Health

Every engine call logged `LOOM_BINDING service=workflow-engine mode=remote
endpoint=http://192.168.56.10:30083/ scope=ext_data_portability_community outcome=ok status=200`.
Zero `FATAL EXCEPTION` in logcat; `dumpsys window lastanr` reports no ANR since boot. No `403`,
no `unknown_permission_id`.

## Defect observed — a declared-positive terminal state is rendered as an "off-path" warning

**This does not affect the proof above** (the workflow reached its terminal state correctly and the
data is right); it is a presentation defect, and it is newly recorded here.

The package declares the success state as positive:

    "replayed": { "label": "Replay verified", "tone": "positive", "isTerminal": true }

The device renders it **amber, with a warning triangle, captioned "This is an off-path export
state"** — the same treatment given to a rollback or a retirement. A member completing the intended
happy path is told their successful replay is off-path.

Root cause, read in `part36_engine_native_marketplace_surface.dart` (method confirmed to sit inside
`_ExportWizardArchetypeCardState`, lines 1990–2681, not a neighbouring card class in the same file):

    bool _isOffPathState(LoomWorkflowState? state) {
      final stateId = _instance.currentState.toLowerCase();
      if (state?.isTerminal == true) {          // <- ANY terminal state
        return true;
      }
      if (stateId == 'failed' || stateId == 'rolled-back' ||
          stateId == 'error' || stateId == 'cancelled') {
        return true;
      }
      return false;
    }

`isTerminal` alone decides it, so **every** terminal state is off-path regardless of tone. All three
presentation paths then short-circuit ahead of the tone switch that would have distinguished them —
`_stateTint` returns `Colors.orange` before reaching `'positive' => Colors.green`, `_stateIcon`
returns `Icons.warning_amber_outlined` before reaching `Icons.check_circle_outline`, and the caption
renders. The `tone` field is exactly the signal that separates "rolled back" from "replay verified",
and it is ignored.

**Control, observed side by side in one screenshot of the Admin tab.** Directly above my card,
`export-full-bundle`'s **"Full bundle complete"** (`tone: positive`, *not* terminal) renders green
with a check circle and no caption; my **"Replay verified"** (`tone: positive`, terminal) renders
amber with a warning triangle and the off-path caption. The discriminator is terminality, not tone.

The earlier `export-schema-listing` manifest from today records the same caption on "Schema listing
retired" and did not flag it — correctly, because that state is declared `tone: negative`, where the
caption is appropriate. The defect only shows on positive terminals.

**Population.** `grep` across the shipped packages for `"tone": "positive", "isTerminal": true`:
Data Portability **5**, Book Club 3, Cedar Commons HOA 2, Masjid 1. Data Portability is by far the
most exposed, carrying 38 `exportWizard` bindings. Its five are `rolled-back`, `replayed`,
`confirmed` ("Redaction confirmed"), `verified` ("Transfer verified") and `complete` ("Rollback
complete"). Three of those — replay verified, redaction confirmed, transfer verified — are
unambiguously intended successes being labelled as off-path.

**A test currently locks the behaviour in.** `v3_milestone_1_10_export_wizard_test.dart:765` asserts
the `export-wizard-off-path-…` tile *is* present after a rollback transition. A fix keying on tone
rather than terminality should keep that test passing (`rolled-back` would need to remain off-path
by state-id, which the second branch already does), but the test is worth reading before changing
`_isOffPathState`, not after.

I did not change any application code, community JSON, or tracker, and created no credential.

## Second observation, reported without a root cause

Immediately after creation, the new `prepared` card did **not** appear on the Admin tab across a
full scroll to the end of the list, although the package binds `prepared` to `admin` with
`audience: "any"` and `bindingKind: "primary"`. It rendered immediately on the Transfer tab. After
switching tabs and returning, the card renders on Admin normally (confirmed by screenshot in the
`replayed` state).

I am reporting this as observed behaviour and explicitly **not** diagnosing it — I did not
instrument the list, and a stale-list-until-reload explanation is plausible but untested. The
proof above was unaffected, since the Transfer tab carries the same bindings.

## Suites

None run. This walkthrough changed no code, so there was no suite result to report; the
`_isOffPathState` finding above is a reading of shipped source plus live device behaviour, not a
change to it.
