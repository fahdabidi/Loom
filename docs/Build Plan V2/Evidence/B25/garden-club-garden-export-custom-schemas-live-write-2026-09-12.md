# Garden Club — `garden-export-custom-schemas` live write, 2026-09-12

**Workflow:** `garden-export-custom-schemas` in Garden Club
**Outcome:** Both halves of the proof standard were met — created live through the real UI as `fan-garden-coordinator-1` and driven through six transitions to the declared terminal state `cancelled`, with the Postgres row confirmed after every step in the same session.
**Frames:** captured to `/tmp` during the run and gitignored (`*.png`); this record is the durable artifact.

## Package identity exercised

    skillVersion: 3.6.0
    sha256:       71659f0896f3d28d27f2d24b20da616b42834e66b6e313150e6c654e42b9ef3b
    file:         app/packages/core/loom_communities_app_shell/assets/Loom_Communities_Workflow_Engine_GardenClub_Example.jsonc

## Baseline — measured, not assumed

Queried before touching the device:

- `workflow_instances` total: **59 rows**
- `workflow_type = 'garden-export-custom-schemas'`: **0 rows** (a real negative)

After the run the total was **61**. This row is distinguished by its own instance id and `created_at`,
not by the count. The type was confirmed **published** (`community_garden_club_garden-export-custom-schemas`,
version 4) before driving.

## Identity

- Keycloak user: `loom-garden-coordinator-1` (realm `loom`, client `loom-test-client`)
- Fan id: `fan-garden-coordinator-1`
- Role: `garden-coordinator` ("Coordinator")
- Password grant returned HTTP 200 with `fanId=fan-garden-coordinator-1`, verified from my own shell.

Reached by a clean identity switch from the member used for the `plant-exchange-submission` row:
`pm clear` on **both** the app and `com.android.chrome`, a real Keycloak login form with empty fields,
and `Garden Coordinator 1` selected from the account list. `created_by_fan_id` on the resulting row
confirms the attribution.

**Every transition on this workflow is guarded by `allowedRoleIds: ["garden-coordinator"]` **and**
`actorEqualsField: ownerFanId`,** so the same coordinator who created it drove all of it. No account
switch occurred mid-row.

## Path driven

Created via the **"New export package"** FAB on the `documents` tab. That tab declares
`visibleRoleIds: ["garden-coordinator"]` and was correctly **absent** from the member's navigation
earlier in the session — expected, not a defect.

| # | Transition | From → To | Result |
|---|---|---|---|
| 1 | *(create)* | — → `scope-selection` | row written, `ownerFanId=$actor` |
| 2 | `open-redaction-preview` | `scope-selection` → `redaction-review` | `redactionStatus` previewed |
| 3 | `approve-redaction` | `redaction-review` → `ready` | `redactionApprovedAt` stamped |
| 4 | `start-export` | `ready` → `processing` | `operationStartedAt` stamped |
| 5 | `complete-operation` | `processing` → `exported` | `exportedAt` stamped |
| 6 | `download-export` | `exported` → *(null)* | **refused by the app — see below** |
| 7 | `change-scope` | `exported` → `scope-selection` | `statusMessage` = "Scope reopened for changes" |
| 8 | `cancel-transfer` | `scope-selection` → **`cancelled`** (terminal) | `statusMessage` = "Operation cancelled" |

`cancel-transfer` is not reachable from `exported` (its `from` list omits that state), so the declared
route to the terminal runs back through `change-scope`, exactly as the ticket sets out.

## The database row

    instance_id       community_garden_club_garden-export-custom-schemas_fxfh6uyocnay
    community_id      community_garden_club
    workflow_type     garden-export-custom-schemas
    created_by_fan_id fan-garden-coordinator-1
    current_state     cancelled
    created_at        1789248683772  (2026-09-12 21:31:23 UTC)

### The two guard-bearing values, settled against Postgres

Both were verified **before** any forward transition was attempted, because a wrong type on either one
makes every forward button vanish and reads exactly like a dead end:

| field | type | value | guard |
|---|---|---|---|
| `selectedSchemaIds` | **list** | `['garden_event', 'plant_exchange']` | `size(selectedSchemaIds) > 0` → **satisfied**, len 2 |
| `operationMode` | str | `export` | `operationMode == 'export'` → **satisfied**, exact match |

`selectedSchemaIds` is declared `type: "list"` and is rendered as a single text field; the
comma-separated entry `garden_event,plant_exchange` was parsed into a genuine two-element JSON array,
not left as a string.

That `operationMode` discriminates correctly was visible on the device: in `ready` the card offered
exactly **one** start action, "Export". `start-transfer` and `start-import` are the same transition
discriminated on that field and were correctly not offered.

### Final stored `instance_data`

| field | type | value |
|---|---|---|
| `ownerFanId` | str | `fan-garden-coordinator-1` |
| `operationMode` | str | `export` |
| `selectedSchemaIds` | list | `['garden_event', 'plant_exchange']` |
| `destination` | str | `Neighborhood Association archive` |
| `redactionPreview` | str | `Member contact details redacted` |
| `exportableDataSummary` | str | `Events and plant exchange records` |
| `redactionStatus` | str | `approved` |
| `redactionApprovedAt` | str | `2026-09-12T21:33:17.610574Z` |
| `operationStartedAt` | str | `2026-09-12T21:33:49.321778Z` |
| `exportedAt` | str | `2026-09-12T21:34:21.311Z` |
| `transferId` | str | `40a655a7-6686-4bb0-afb1-1884f08728f3` |
| `receiptId` | str | `945c02a6-0e79-49a8-936e-e9abbd700730` |
| `downloadStatus` | str | `available` |
| `errorMessage` | null | `None` |
| `statusMessage` | str | `Operation cancelled` |

## Do screen and database agree?

Yes, at every one of the eight steps — each transition was confirmed by querying `current_state`
immediately after the tap, and the card's state chip matched each time
(`Choose export scope` → `Review redaction` → `Ready for verified export` → `Export operation in
progress` → `Exported` → `Choose export scope` → `Cancelled`).

The final screen showed **"Cancelled"**, the annotation *"This is an off-path export state"*,
*"Status: Operation cancelled"*, and **no action buttons** — matching `current_state=cancelled` and
`isTerminal: true`.

## Finding — `download-export` is refused by the app, while the instance advertises it as available

Step 6 was tapped and did **not** fire. This was established rather than assumed: `instance_data` was
captured immediately before and after the tap and **no field changed**, while the transition declares
three real effects (`downloadRequestedAt`, `downloadStatus: "download-requested"`, `statusMessage`).

The tap did register. The app rendered a message in its place:

> **Export download is unavailable until this app session generates a bundle.**

So this is a **client-side gate in the app shell, not an engine guard** — the engine-side guard
(`garden-coordinator` + `actorEqualsField: ownerFanId` + `operationMode == 'export'`) was satisfied on
every count, and the request was never sent.

The contradiction worth recording: the same card simultaneously displayed **`Download: Available`**
(from the stored `downloadStatus = "available"`) while refusing the download. One of the two is
misleading to a user.

This is consistent with — and looks downstream of — the missing platform export service, which the
package declares honestly rather than faking: the `exported` card's own status text reads *"Operation
complete; checksum and export receipt are generated by the platform."* It is **not** a per-package
authoring defect, and no Skill dispatch would fix it.

It did not block the proof: `download-export` is a `to: null` bookkeeping mutation and is not on the
path to the terminal state, which was reached through `change-scope` → `cancel-transfer`.

## `transitionRelated` — not exercised on this path

The ticket flags a known open defect where `{id}` inside a `transitionRelated` filter matches nothing,
and notes Garden does use `transitionRelated`. **I did not observe it**, because `cancel-transfer`
carries no `transitionRelated` block at all — its only effect is
`{ "op": "set", "key": "statusMessage", "value": "Operation cancelled" }`. Recorded here so this run is
not read as evidence either way about that defect. Not investigated, per the ticket.

## Observations carried from the same session

The create dialog for this workflow collapses under the soft keyboard in the same way as Garden's
plant-exchange create dialog — form content drops to zero height, leaving only title and buttons.
Full write-up is in `garden-club-plant-exchange-submission-live-write-2026-09-12.md`; it is a shared
create-dialog behaviour, not specific to one workflow. The soft IME was disabled to complete data
entry and restored as the device default at the end of the run.

## Verification commands

    PW=$(kubectl get secret postgres-credentials -n loom -o jsonpath='{.data.password}' | base64 -d)
    kubectl exec -i -n loom postgres-0 -- env PGPASSWORD="$PW" psql -U loom -d loom_workflow_service \
      -c "select instance_id, community_id, workflow_type, created_by_fan_id, current_state, created_at \
          from workflow_instances where workflow_type='garden-export-custom-schemas';"
