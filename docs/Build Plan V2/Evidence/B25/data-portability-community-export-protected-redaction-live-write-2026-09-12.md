**Workflow:** `export-protected-redaction` in Data Portability Community
**Outcome:** Both halves of the proof standard were met — created the instance live through the Admin-tab FAB as `fan-portability-owner-1` and drove it `draft` → `previewed` → terminal `confirmed`, confirmed by the Postgres row.

**Package identity:** `app/packages/core/loom_communities_app_shell/assets/Loom_Communities_Workflow_Engine_DataPortabilityCommunity_Example.jsonc`
- `skillVersion`: `3.6.0`
- `sha256`: `f30994c9776871da2a4d48480f1ec83b2e7becaf16f860017dde5733ae0def43`

**Date:** 2026-09-12
**Device:** `emulator-5554` (Windows host, reached via `ADB_SERVER_SOCKET=tcp:192.168.56.1:5037`)
**Backend:** k3s `loom` namespace, all six pods `1/1`

---

## Identity

Already signed in from the two prior walkthroughs; per the ticket I checked before clearing anything
and did **not** `pm clear` either app.

- Account identity dialog: **"Signed in as Portability Owner 1"**, `ID: fan-portability-owner-1`,
  role **Owner/Admin** selected.
- `created_by_fan_id` on the resulting row is `fan-portability-owner-1` — it matches the identity
  driven. No stale-SSO substitution.

## Baseline, measured in this session before touching anything

`workflow_instances` held **37** rows, of which **zero** were `export-protected-redaction` and
**zero** were `export-notification`. Both definitions were published (`workflow_definitions` has one
row each), so a silent no-op `createInstance` was ruled out in advance. The dispatching session's
hint of ~37 rows was accurate this time.

## Path driven

1. **Admin** tab → FAB → speed-dial expanded to eight create options, including
   **"New protected-data review"** exactly as the package declares
   (`byRoleIds: ["portability-owner"]`, `presentation: fab`, `scope: tab`).
2. Creation form rendered **all six** `formEntry` fields editable in `draft`: Review Label,
   Protected Fields, Redaction Choices, Preview Summary, Choice confirmed (a switch), Safe Member
   Notice. Values kept short to avoid `adb shell input text` truncation:
   `RedactB25` / `email` / `mask` / `Masked` / toggle ON / `Notice`.
3. **Create** → row landed in `draft`.
4. Card rendered **"Choose protected-data handling"** with actions **Preview redaction** and
   **Cancel**.
5. **Preview redaction** (`preview-protected-redaction`) → state `previewed`, card became
   **"Redaction preview ready"** showing `Audit: Previewed` and the `previewedAt` stamp, offering all
   four declared previewed-state transitions (Confirm redaction, Record validation failure, Change
   redaction, Cancel).
6. **Confirm redaction** (`confirm-protected-redaction`) → terminal **`confirmed`**. Card became
   **"Redaction confirmed"** with `Audit: Confirmed` and both timestamps, and **no action buttons** —
   correct for a terminal state bound as `summary`.

## Final UI state

Card header **"Redaction confirmed"**, chips `Redact B25`, `Notice`, `Audit: Confirmed`,
`2026-09-12T16:23:51.529183Z` (previewedAt), `2026-09-12T16:24:24.589030Z` (confirmedAt). No
remaining actions. No ANR or crash dialogs — `logcat` scan for `FATAL EXCEPTION` / `ANR in` returned
zero.

## The database row

```
instance_id       community_data_portability_export-protected-redaction_o45jkphkf10j
community_id      community_data_portability
workflow_type     export-protected-redaction
created_by_fan_id fan-portability-owner-1
current_state     confirmed
created_at        2026-09-12 16:20:48 UTC
```

`instance_data` after the walkthrough:

```json
{
  "reviewLabel": "RedactB25",
  "protectedFields": ["email"],
  "redactionChoices": ["mask"],
  "previewSummary": "Masked",
  "protectedChoiceConfirmed": true,
  "safeMemberNotice": "Notice",
  "auditState": "confirmed",
  "previewedAt": "2026-09-12T16:23:51.529183Z",
  "confirmedAt": "2026-09-12T16:24:24.589030Z"
}
```

**Do the two halves agree? Yes.** The terminal state on screen (`Redaction confirmed`) is the
`current_state` in Postgres (`confirmed`); both effect timestamps rendered on the card are
byte-identical to the stored values; `created_by_fan_id` is the identity that was authenticated.

### Guard preconditions verified against the stored row, not the screen

Both guarded transitions depend on stored values, and both were type-checked in Postgres rather than
read off the device (the `input text` truncation trap):

- `protectedFields` — `jsonb_typeof` = **array**, `jsonb_array_length` = **1**. So
  `size(protectedFields) > 0` was genuinely satisfied, not apparently satisfied.
- `protectedChoiceConfirmed` — `jsonb_typeof` = **boolean**, value `true`. Stored as a real JSON
  boolean, **not** the string `"true"`, which is what `confirm-protected-redaction`'s
  `protectedChoiceConfirmed == true` formula compares against.

No field truncated: `RedactB25` and `Notice` are stored in full.

Total `workflow_instances` moved 37 → **39**: this row plus the spawned notification below.

---

## Second measurement: `{id}` interpolation in a cross-type `createInstance` effect

Firing `preview-protected-redaction` spawned the `export-notification` instance as declared. **This
is the first of the ticket's three outcomes: `{id}` resolves correctly in effect `fields`.**

```
instance_id       community_data_portability_export-notification_qniobzc2oaqc
workflow_type     export-notification
created_by_fan_id fan-portability-owner-1
current_state     unread
created_at        2026-09-12 16:23:51 UTC
```

```json
{
  "recipientFanId": "fan-portability-owner-1",
  "title": "Redaction review ready",
  "body": "The protected-data redaction preview is ready for your confirmation.",
  "sourceWorkflowType": "export-protected-redaction",
  "sourceInstanceId": "community_data_portability_export-protected-redaction_o45jkphkf10j",
  "createdAt": "2026-09-12T16:23:51.529183Z"
}
```

**`sourceInstanceId` verbatim:**
`community_data_portability_export-protected-redaction_o45jkphkf10j`

That is **exactly** the redaction instance's id — character for character. So in this position,
`{id}` received the instance id rather than being treated as an ordinary data-field lookup: it is
neither empty, nor null, nor the literal string `{id}`. The other interpolations resolved correctly
too — `$actor` → `fan-portability-owner-1`, and `$timestamp` on the notification's `createdAt` is
identical to the parent's `previewedAt`, so both came from one evaluation.

This measures the effect-`fields` path only. It says nothing about the separate resolver elsewhere in
the engine that the tracker's open question concerns; that remains unmeasured by this run.

---

## Defects observed

None in the workflow itself. Every element of the path the brief predicted from the package was
present on the device, and the device contradicted nothing.

One **harness** note, not a product finding: `adb shell input keyevent 111` (ESC) dismisses the whole
creation dialog, not just the soft keyboard, discarding the filled fields. Nothing was submitted, so
no spurious row was created — the form was refilled and the run continued. The keyboard-hide chevron
at the bottom of the IME dismisses the keyboard while leaving the dialog intact, which is what the
rest of this run used.

## Not done

No test suites were run: this walkthrough changed no application code, community JSON, or tracker —
the only committed artifact is this manifest. No credential was created or reset.
