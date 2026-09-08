# Data Portability Community — `export-full-bundle` live write, re-verified with database proof

**Date:** 2026-09-08 (device local, America/Los_Angeles = UTC-7; engine stamps are UTC, so
`13:13:40Z` is 06:13 local)
**Device:** `emulator-5554`, Android 1080x2400, Windows-hosted
**adb path:** this session ran **on the Loom VM itself** (`192.168.56.10`), which has no AVD. The
emulator was reached through the **Windows host's adb server** — `adb -H 192.168.56.1 -P 5037`. The
VM-local adb server saw zero devices.
**App:** `com.example.loom_communities_demo/.MainActivity`
**Workflow:** `export-full-bundle` in Export and Migration (`community_data_portability`,
`ext_data_portability_community`)
**Supersedes:** the reopened Data Portability claim, which had no corresponding database row.

## Outcome

Both halves of the proof standard were met **in one session**, and the UI evidence and the Postgres
row are reported together and **agree**.

- Signed in for real as **`loom-portability-owner-1`** (fan `fan-portability-owner-1`, role
  `portability-owner`) through the in-app OAuth flow against Keycloak.
- Created an `export-full-bundle` **from nothing** through the real UI, reaching `draft`.
- Drove `generate-full-bundle` → `generating`, `complete-full-bundle` → `complete`, wrote
  `verificationResult = passed` through the real in-card editor, and fired `download-full-bundle`.
- Read the row back from Postgres with `kubectl exec … psql` after every step.

The success path was driven **end to end**. `download-full-bundle` declares `to: null`, so the
instance correctly remains in `complete` with `downloadState = downloaded` — that is the product's
success state, not a stall. The only `isTerminal: true` state is `cancelled`, which is the
destructive exit and was deliberately **not** driven.

## Escalation — stated explicitly, as the ticket requires

The ticket nominated `loom-portability-member-1`. **That account cannot perform this workflow**, and
this is by design rather than a defect:

- Every one of the ten transitions on `export-full-bundle` is guarded
  `allowedRoleIds: ["portability-owner"]`.
- The create action (`New full bundle`) is `byRoleIds: ["portability-owner"]` and is bound to the
  `admin` tab, whose `visibleRoleIds` are `portability-owner` and `portability-receiving-provider`.
  `portability-member` cannot see that tab at all.
- `portability-member` *is* in the `readGuard`, so a member can read the record on the `home` tab —
  read-only participation is the intended member role here.

I therefore escalated to **`loom-portability-owner-1`**, a package role (not the generated
`data-portability-community-admin`, which was left untouched).

## Baseline — confirmed, not stale

The ticket's control was *"`workflow_instances` held **17** rows total, and **zero** of
`workflow_type = 'export-full-bundle'`."*

**That was exactly correct** at this session's first database read, before any device interaction:

```
 count
-------
    17

 instance_id | community_id | workflow_type | created_by_fan_id | current_state | created_at
-------------+--------------+---------------+-------------------+---------------+------------
(0 rows)
```

The row below is therefore necessarily this session's. The total moved **17 → 18**: exactly one row,
created by hand. No effect created a second row — see "Shape 4" below, which is why.

## The row

```
                        instance_id                         |        community_id        |   workflow_type    |    created_by_fan_id    | current_state |       created_utc
------------------------------------------------------------+----------------------------+--------------------+-------------------------+---------------+-------------------------
 community_data_portability_export-full-bundle_wy3omunby74m | community_data_portability | export-full-bundle | fan-portability-owner-1 | complete      | 2026-09-08 13:13:40.758
```

`created_by_fan_id` is **`fan-portability-owner-1`**, matching the identity actually driven. Final
`instance_data`:

```json
{
    "scope": ["members", "events", "documents"],
    "bundleLabel": "B25 Full Bundle",
    "destination": "Provider Archive",
    "downloadedAt": "2026-09-08T13:25:50.786506Z",
    "memberNotice": "Full export in progress.",
    "downloadState": "downloaded",
    "generationStatus": "complete",
    "verificationResult": "passed",
    "generationStartedAt": "2026-09-08T13:15:16.593427Z",
    "generationCompletedAt": "2026-09-08T13:15:56.023890Z"
}
```

**The UI and the database agree** at every step: the card read `Full bundle complete`,
`Verification: Passed`, `Download: Downloaded`, `3 files`, and each matches the stored row. The
`fileCount` formula (`size(scope)`) correctly computed 3 from the 3-element list.

## Identity hygiene

The device arrived holding the **previous dispatch's Ad-Free session**. Before signing in:
Keycloak logout endpoint (HTTP 200), `pm clear com.android.chrome`, `pm clear` on the demo app.
The app then showed `LoomAuthNotLoggedInException: No Loom authentication session is stored`, and
the OAuth flow presented a **real Keycloak login form** rather than silently re-issuing the old
fan's token. That is the check that matters — a green "you're signed in" proves a token exists, not
whose it is.

## Input fidelity — settled against the database, not the screen

All four created fields were verified against stored `instance_data`, not the on-screen text. **No
truncation occurred**: `bundleLabel` 15/15 chars, `destination` 16/16, `memberNotice` 24/24, and
`scope` parsed into a real 3-element list. Values were kept short deliberately, and each field was
read back on screen before the next was typed.

## Terminal-state reachability — all four known shapes checked

| Shape | Verdict |
|---|---|
| 1. Role never provisioned | **Not present.** All three package roles exist in `app_role` and are assigned in `group_membership_role`: `fan-portability-owner-1`→`portability-owner`, `fan-portability-member-1`→`portability-member`, `fan-portability-provider-1`→`portability-receiving-provider`, all `state=active`. Proven live by firing four owner-guarded transitions. |
| 2. Guarded role cannot see the instance | **Not present.** The owner holds every guard *and* sees the instance on `admin`, `documents` and `home`. |
| 3. Precondition unsatisfiable | **Not present — but I nearly reported it wrongly.** See below. |
| 4. Effect target not published | **PRESENT, and worse than Ad-Free's.** See below. |

### Shape 3 — a false finding I caught with a control

Both exits from `complete` depend on `verificationResult`: `download-full-bundle` requires
`verificationResult == 'passed'` and `record-full-bundle-verification-failure` requires `'failed'`.
That field is `writableBy: formEntry`, editable **only** in `complete`/`error` — never in the
initial `draft` state, so the creation dialog cannot supply it.

On the `admin` and `documents` tabs the card offered **no editor at all** — only `Change scope`. The
code explains why: those bindings use `cardSurfaceFamily: exportWizard`, which the dispatcher routes
to the bespoke `ExportWizardArchetypeCard`, and that widget contains **zero** occurrences of
`editableFields`, `editGuard`, `TextField` or `TextEditingController`. I was one step from reporting
`verificationResult` as unwritable and the success path as dead.

**The control saved it.** `export-full-bundle` also carries a `statusTimeline` binding on the `home`
tab, and `statusTimeline` is *not* one of the dispatcher's four bespoke families
(`votePoll`, `documentLibrary`, `searchAiAnswer`, `exportWizard`), so it falls through to
`GenericWorkflowInstanceCard` — which **does** render editors. On the Home tab a `Verification`
field and a `Save changes` button were present; typing `passed` and saving persisted
`verificationResult = passed` to Postgres, after which `Download full bundle` appeared and fired
successfully.

So the field is writable and the path is complete. What remains is a genuine **UX discoverability
defect, not a reachability failure**: the editor for `verificationResult` exists only on the Home
summary card, while the two actions gated on it are rendered on `admin`/`documents`, where no editor
exists. An owner working from the Admin tab — the tab the create FAB lives on, and the one the
package describes as "Export scope, verification, provider transfer…" — sees an action-less card and
no way forward.

### Shape 4 — present, and a strictly larger gap than Ad-Free's

Ad-Free's shape 4 was *effect published, target missing*. Here **both** are missing.

- The package declares **10** workflow definitions; **9** are published.
  `export-notification` is declared and **absent** from `workflow_definitions`.
- The package declares **7 `createInstance` effects** across 6 workflows
  (`export-checksum-evidence`, `export-full-bundle`, `export-import-preview`,
  `export-import-replay` ×2, `export-protected-redaction`, `export-redacted-bundle`) and **every one
  targets `export-notification`**. **Zero** of them are present in the published definitions.

The published `complete-full-bundle` carries only its three `set` effects; the `createInstance` is
not merely unfirable, it is **not in the deployed definition at all**. This was confirmed live: the
transition succeeded, all three `set` effects landed, and the instance total stayed at 18 with no
error surfaced anywhere.

**Control:** 13 published definitions in other communities *do* contain `createInstance`
(`ad-off-member-checkout`, `garden-tool-loan`, `hoa-architectural-request`, …), so the query finds
the pattern when it is there. The absence is real and specific to this community.

**Net effect:** the entire notification mechanism of the Data Portability community is missing from
the deployed catalog. No member or owner can ever receive an export notification, from any of its
six notification-producing workflows.

## Second defect — a raw field key rendered to the user

On the Home tab the card renders a chip reading literally **`memberNotice`** instead of its value
"Full export in progress." The same field renders correctly on the `exportWizard` surfaces.

Cause, in `part26_generic_instance_card.dart`: `_isVisibleField` ends with
`_renderLabel(schema.labelTemplate ?? key, value)`, so a field with **no `labelTemplate`** is
rendered using its own key as the template; with no `{value}` placeholder to substitute, the literal
key reaches the screen. `memberNotice` declares `displayContexts: ["tile","detail"]` and no
`labelTemplate`, while its sibling `bundleLabel` declares `labelTemplate: "{value}"` and renders
fine. This is a user-visible defect on the community's default tab.

## What was not done

- **No test suites were run**, because no application code, community JSON or tracker was modified —
  this was a walkthrough-only ticket and those changes are explicitly out of scope for it.
- **`cancelled`**, the only terminal state, was not driven: it is the destructive exit, and driving
  it would have destroyed the successful record this ticket exists to bank.
- No credential was created or reset. The documented convention (`loom-<slug>` / `LoomTest123!`)
  worked as recorded.

## Stability

No ANR (`dumpsys window`: "no ANR has occurred since boot") and zero `FATAL EXCEPTION` in the crash
buffer across the whole session.
