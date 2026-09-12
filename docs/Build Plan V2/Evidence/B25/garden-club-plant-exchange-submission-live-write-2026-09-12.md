# Garden Club — `plant-exchange-submission` live write, 2026-09-12

**Workflow:** `plant-exchange-submission` in Garden Club
**Outcome:** Both halves of the proof standard were met — created live through the real UI as `fan-garden-member-1`, driven `draft` → `submitted`, then finished `submitted` → `reviewed` (terminal) as `fan-garden-coordinator-1`, with the Postgres row agreeing with the screen at every step.
**Frames:** captured to `/tmp` during the run and gitignored (`*.png`); this record is the durable artifact.

## Package identity exercised

    skillVersion: 3.6.0
    sha256:       71659f0896f3d28d27f2d24b20da616b42834e66b6e313150e6c654e42b9ef3b
    file:         app/packages/core/loom_communities_app_shell/assets/Loom_Communities_Workflow_Engine_GardenClub_Example.jsonc

## Baseline — measured, not assumed

Queried before touching the device:

- `workflow_instances` total: **59 rows**
- `workflow_type = 'plant-exchange-submission'`: **0 rows** (a real negative — no prior instance existed)

The dispatching session's hint ("about 59 rows, few or none of this type") matched what was measured.
After the run the total was **61** (this row plus the export row). The row below is distinguished by its
own instance id and `created_at`, not by the count moving.

Both target types were confirmed **published** before driving, since a `createInstance` naming an
unpublished type returns success and does nothing:

    community_garden_club_plant-exchange-submission     | plant-exchange-submission     | version 4
    community_garden_club_garden-export-custom-schemas  | garden-export-custom-schemas  | version 4
    (control: 85 definitions total)

## Identity

Two identities were used, in the order the ticket specifies, which required **one** switch.

| Step | Keycloak user | fan id | Role |
|---|---|---|---|
| create + submit | `loom-garden-member-1` | `fan-garden-member-1` | `garden-member` (Member) |
| approve | `loom-garden-coordinator-1` | `fan-garden-coordinator-1` | `garden-coordinator` (Coordinator) |

Both password grants against `loom-test-client` returned HTTP 200 with the expected `fanId` claim,
verified from my own shell before the run.

**Stale-SSO precaution, both times:** `pm clear` on **both** `com.example.loom_communities_demo` and
`com.android.chrome`. The real Keycloak login form appeared on each sign-in with empty fields — no
silent re-issue of a previous fan's token. After the app-data clear the launch screen showed
**"Loaded 10 example communities"**, confirming the APK carries
`LOOM_PRELOAD_EXAMPLE_COMMUNITIES=true`. The identity actually written to the row was confirmed
afterwards against `created_by_fan_id`.

## Path driven

Created via the **"Offer or request a plant"** FAB on the `home` tab (`byRoleIds: ["garden-member"]`),
landing in `draft` with `ownerFanId` prefilled to `$actor`.

| # | Transition | From → To | Acting fan | Result |
|---|---|---|---|---|
| 1 | *(create)* | — → `draft` | `fan-garden-member-1` | row written |
| 2 | `submit-exchange` | `draft` → `submitted` | `fan-garden-member-1` | `handoffStatus=awaiting-review`, `submittedAt` stamped |
| 3 | `approve-handoff` | `submitted` → **`reviewed`** (terminal) | `fan-garden-coordinator-1` | `handoffStatus=approved`, `reviewedAt` stamped |

`withdraw-submission` was deliberately **not** fired — the ticket asks for the richer terminal.

## The database row

    instance_id       community_garden_club_plant-exchange-submission_x729kif0as8q
    community_id      community_garden_club
    workflow_type     plant-exchange-submission
    created_by_fan_id fan-garden-member-1
    current_state     reviewed
    created_at        1789247984671  (2026-09-12 21:19:44 UTC)

`created_by_fan_id` is `fan-garden-member-1` — the identity that was authenticated and selected, so
the attribution is correct.

### Stored `instance_data`, with types

Read back from Postgres, not from the screen:

| field | type | value |
|---|---|---|
| `ownerFanId` | str | `fan-garden-member-1` |
| `plantVariety` | str | `Lavender cuttings` |
| `offerType` | str | `offer` |
| `notes` | str | `Rooted lavender cuttings from the herb bed` |
| `pickupWindow` | str | `Sunday 10-12 at the community shed` |
| `pickupDate` | str | `2026-09-20` |
| `pickupTime` | str | `10:00` |
| `reminderOffsetHours` | **int** | `24` |
| `safePickupDetails` | str | `Meet beside the public shed door` |
| `availabilityNote` | str | `Four available` |
| `contactInfo` | str | `Private club message` |
| `privacyLabel` | str | `Contact protected until approved handoff` |
| `privacyAcknowledged` | **bool** | `True` |

Effect-written after the two transitions:

| field | value |
|---|---|
| `submittedAt` | `2026-09-12T21:21:21.531615Z` |
| `handoffStatus` | `approved` |
| `reviewedByFanId` | `fan-garden-coordinator-1` |
| `handoffRecipientFanId` | `fan-garden-member-2` |
| `reviewNote` | `Approved for handoff to Test garden-member-2` |
| `reviewedAt` | `2026-09-12T21:28:39.869899Z` |

**`privacyAcknowledged` stored as a real JSON boolean `true`, not the string `"true"`.** This is the
value the ticket flagged: it gates `submit-exchange` via `instanceDataEquals`, and a string would have
made the submit button silently absent. It is written by a real **toggle** on the create form, and the
`Submit exchange` button duly rendered and fired.

## Do screen and database agree?

Yes, at every step.

- After `submit-exchange` the card showed *"Submitted for review"*, *"Submitted 2026-09-12T21:21:21.531615Z"*,
  *"Handoff: Awaiting Review"* — matching `current_state=submitted` and the stored fields exactly.
- After `approve-handoff` the card showed *"Reviewed for handoff"* and *"Handoff: Approved"* with **no
  remaining action buttons**, matching `current_state=reviewed` and `isTerminal: true`.

## Observations

**Role-scoped visibility behaves correctly.** As `garden-member` the bottom nav showed
Home/Calendar/Marketplace/**Care** and no Documents or Organize; as `garden-coordinator` it showed
Documents and **Organize** and no Care. That matches `visibleRoleIds` on those three tabs and is not a
defect. The submitted instance appeared in the coordinator's **Organize** approval queue
(`audience: "any"`, `approvalQueueItem`) while `approve-handoff` was correctly absent for the member —
cross-user visibility through the remote engine works.

**The `approve-handoff` fanId input uses a real fan directory.** Its picker listed genuine fan ids
(`fan-garden-admin`, `fan-garden-coordinator-1/2`, `fan-garden-member-1/2`) with role labels, and the
selection stored `handoffRecipientFanId = fan-garden-member-2` — a real fan id in a `fanId` field.
This is worth recording because it is the **opposite** of the documented creation-card defect where
`AudienceMultiSelectPicker` writes role ids into a `fanId[]` field. The transition-input path and the
creation-card path do not share that flaw.

## Defect observed — create dialog collapses when the soft keyboard opens

Reproducible, and it cost real time before it was worked around.

Tapping any text field in the **"Offer or request a plant"** create dialog raises the soft keyboard,
and the dialog's scrollable form content collapses to **zero height** — leaving only the title and the
Cancel/Create buttons on screen. The focused field still receives text, but nothing about the form is
visible while typing, so a value cannot be checked as it is entered. Pressing ESC to dismiss the
keyboard dismisses the **entire dialog** and discards all input.

Verified this is specific to the *create* dialog: the `approve-handoff` transition-input dialog keeps
its content visible and usable with the keyboard raised.

Worked around by disabling the soft IME (`adb shell ime disable …LatinIME`), after which the form
rendered fully and `input text` still injected into the focused field. The IME was re-enabled and
re-selected as the default at the end of the run.

This is a real usability finding on a shipped surface, not a harness artifact — a human on a real
device would hit it on the first field they tap.

## Harness note (not a product defect)

`adb shell input text 'Lavender cuttings'` stored only **`Lavender`** — `input text` truncates at the
first space unless spaces are escaped as `%s`. Caught by reading the field back, then corrected, and
every load-bearing value was finally settled against Postgres rather than the screen, per the standing
rule. No value in the final row is truncated.

## Verification commands

    PW=$(kubectl get secret postgres-credentials -n loom -o jsonpath='{.data.password}' | base64 -d)
    kubectl exec -i -n loom postgres-0 -- env PGPASSWORD="$PW" psql -U loom -d loom_workflow_service \
      -c "select instance_id, community_id, workflow_type, created_by_fan_id, current_state, created_at \
          from workflow_instances where workflow_type='plant-exchange-submission';"
