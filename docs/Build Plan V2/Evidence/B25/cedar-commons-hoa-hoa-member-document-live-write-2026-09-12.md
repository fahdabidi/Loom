**Workflow:** `hoa-member-document` in Cedar Commons HOA
**Outcome:** Both halves of the proof standard were met — created an HOA document live on the device as `fan-hoa-board-1`, drove it draft → published → archived → published through two bookkeeping mutations and three state changes, and separately drove a second instance to the declared terminal `deleted`; all rows confirmed in Postgres.

## Package identity

- Package: `app/packages/core/loom_communities_app_shell/assets/Loom_Communities_Workflow_Engine_CedarCommonsHOA_Example.jsonc`
- `skillVersion`: **3.6.0**
- `sha256`: **38c70ed08eabe2ef07011658bdea2434008e385b271e4ae6b98a29007369fd7f**

## Identity

- Keycloak user **`loom-hoa-board-1`** (realm `loom`, client `loom-test-client`)
- Fan id **`fan-hoa-board-1`**, role **`hoa-board`** in App Access group `loom_communities_cedar-commons-hoa`
- Verified before the run at all three layers: Keycloak token (HTTP 200, `fanId: fan-hoa-board-1`),
  a `fan_passport` row, and a `group_membership_role` row.
- The decoy `loom-cedar-board-1` was **not** used. It authenticates (HTTP 200,
  `fanId: fan-cedar-board-1`) and holds **zero** rows in `group_membership_role` — confirmed by query.
- A real Keycloak login form was presented and completed (Chrome and app data both cleared first),
  so this is not a stale-SSO re-issue. `created_by_fan_id` on every row below is `fan-hoa-board-1`.

## Baseline — measured, not assumed

Queried before touching anything:

- `workflow_instances` total: **55** (the brief's hint of ~55 was accurate this time)
- `workflow_type = 'hoa-member-document'`: **0 rows**

Final total after this session's three rows: **59**. My rows are identified by instance id and
`created_at`, not by the count.

## Path driven (live UI, Admin tab)

The create action is declared in `renderBindings[].actions` as `{kind: create, label: "Add HOA
document", byRoleIds: ["hoa-board"], scope: tab, presentation: fab, tabId: "admin"}` — so it is on
the **Admin** tab, not Documents. (Documents pins the workflow for *reading*; only `published`
documents bind there.)

### Instance 1 — `community_cedar_commons_hoa_hoa-member-document_rr92xnnw0ob8`

| # | Action fired | Transition | Result |
|---|---|---|---|
| 1 | "Add HOA document" (speedDial FAB) | create | `draft` |
| 2 | "Upload document" | `upload-document` (`to: null`) | real file upload; state stayed `draft` |
| 3 | "Save document edits" | `record-document-edit` (`to: null`) | `versionHistory` entry; state stayed `draft` |
| 4 | "Publish document" | `publish-document` | → **`published`** |
| 5 | "Archive document" | `archive-document` | → **`archived`** |
| 6 | "Restore document" | `restore-document` | → **`published`** |

**Three state changes and two bookkeeping mutations, all fired from the real UI.**

Form validation was exercised: the create form rejected submission three times in sequence
("Publication date is required.", then "Owner is required.") until all nine fields were supplied.

**The upload is genuinely end-to-end, not a stub.** "Upload document" opens the Android system file
picker; selecting a file produced a real `workflow_documents` row backed by object storage:

```
document_id     doc_f7cae9011ac03e34f1f5a4dff083d111
instance_id     community_cedar_commons_hoa_hoa-member-document_rr92xnnw0ob8
field_name      documentUrl
filename        z3.png     content_type image/png     byte_size 177717
owner_fan_id    fan-hoa-board-1
object_key      communities/community_cedar_commons_hoa/instances/…/doc_f7cae9011ac03e34f1f5a4dff083d111
```

and a `workflow_document_revisions` row at `version 1`.

**Stored `instance_data` verified against Postgres, not the screen** (the `adb shell input text`
truncation trap). Every typed value survived intact:

```json
{"explicitReaderFanIds": [], "versionHistory": [{"note": "B25-edit-note",
 "authorFanId": "fan-hoa-board-1", "at": "2026-09-12T20:28:23.486737Z"}],
 "title": "B25-CCR-Board1", "version": "v1", "publishedDate": "2026-09-12",
 "documentOwner": "Board-Records", "provider": "Loom-Docs", "sourceLabel": "Board-Upload",
 "accessLabel": "Members", "auditLabel": "Audit-2026Q3",
 "documentUrl": "/v1/communities/community_cedar_commons_hoa/documents/doc_f7ca…/content"}
```

The declared `prefill` (`explicitReaderFanIds: []`, `versionHistory: []`) landed correctly.

### Instance 2 — `community_cedar_commons_hoa_hoa-member-document_orh706rc56ug` (terminal proof)

Created and then fired "Delete mistaken draft" (`delete-document`) → **`deleted`**, the workflow's
**declared terminal state** (`isTerminal: true`; verified with a control — 8 `isTerminal`
occurrences package-wide). The card then rendered on Admin with **no actions at all**, correct for a
terminal state.

A second instance was required because **`deleted` is reachable only from `draft`**: `delete-document`
is the sole transition into it and its `from` is `["draft"]`. See the structural note below.

## Database confirmation (same session)

```
                         instance_id                          | created_by_fan_id | current_state |     created_utc
--------------------------------------------------------------+-------------------+---------------+---------------------
 community_cedar_commons_hoa_hoa-member-document_rr92xnnw0ob8 | fan-hoa-board-1   | published     | 2026-09-12 20:24:25
 community_cedar_commons_hoa_hoa-member-document_orh706rc56ug | fan-hoa-board-1   | deleted       | 2026-09-12 20:34:45
```

`community_id` = `community_cedar_commons_hoa`, read off the rows themselves.

**Do the two halves agree? Yes.** Every state the UI displayed matched the stored `current_state` at
the moment it was queried, and `created_by_fan_id` is `fan-hoa-board-1` on both rows — the identity
I authenticated as.

## Role filtering behaved correctly (with a control)

Six transitions are `hoa-member`-only (`acknowledge-document`, `mark-document-unread`,
`save-document`, `remove-saved-document`, `request-document-access`, `withdraw-access-request`).
None were offered to me. **This is not a rendering failure**, and the control proves it: on the same
`published` card the two transitions allowed to *both* roles — "Open document" and "Download
document" — **were** rendered alongside the board-only actions. So the filter discriminates; it is
not simply hiding everything.

## Render bindings behaved as declared

The card moved between tabs exactly as `renderBindings` specifies, which is itself worth recording:

- `draft` → Admin (with the create FAB)
- `published` → Documents and Home; **left Admin on publish**, confirmed on screen
- `archived`, `deleted` → Admin

## Observation — not a defect, but worth recording

**The only terminal state is unreachable from the main path.** `deleted` is the sole `isTerminal`
state, and the only transition into it (`delete-document`) has `from: ["draft"]`. Once a document is
published it can cycle `published ⇄ archived` indefinitely but can never reach a terminal state.
That is a coherent design for a document library — a published governing document arguably *should
not* be deletable — and the destructive action's label ("Delete mistaken draft") says as much. I am
recording it because a naive reading of "the terminal is `deleted`" implies the main path ends
there, and it does not. No change recommended without a product decision.

## Corrections to the brief

- The brief stated all three workflows are created from the Admin tab. That is **correct**, and my
  first reading of `pinnedWorkflowIds` (which lists `hoa-member-document` under `documents`) was
  wrong. `pinnedWorkflowIds` governs where a workflow is *surfaced for reading*; the create action's
  `tabId` in `renderBindings[].actions` governs where it is *created*. Both point at Admin here.

## Defects observed

None for this workflow.
