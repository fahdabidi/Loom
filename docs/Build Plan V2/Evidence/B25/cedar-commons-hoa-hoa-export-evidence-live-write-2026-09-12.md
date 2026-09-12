**Workflow:** `hoa-export-evidence` in Cedar Commons HOA
**Outcome:** Both halves of the proof standard were met — created an HOA export live on the device as `fan-hoa-board-1` and drove it through five state changes, draft → preview → redaction-approved → generating → ready → cancelled, a clearly-advanced state; the row was confirmed in Postgres.

This workflow **declares no terminal state** (none of its ten states carries `isTerminal`, and
`reopen-export` returns `cancelled` → `draft`). The proof is therefore a *clearly advanced* state,
not a terminal one, and this manifest does not claim otherwise.

## Package identity

- Package: `app/packages/core/loom_communities_app_shell/assets/Loom_Communities_Workflow_Engine_CedarCommonsHOA_Example.jsonc`
- `skillVersion`: **3.6.0**
- `sha256`: **38c70ed08eabe2ef07011658bdea2434008e385b271e4ae6b98a29007369fd7f**

## Identity

- Keycloak user **`loom-hoa-board-1`**, fan id **`fan-hoa-board-1`**, role **`hoa-board`**
- Verified at all three layers before the run; the decoy `loom-cedar-board-1` was not used.
- A real Keycloak login form was completed after clearing both Chrome and app data.

`hoa-export-evidence` declares `visibility.readGuard: {allowedRoleIds: ["hoa-board"]}`, which the
authenticated identity satisfies.

## Baseline — measured, not assumed

- `workflow_instances` total before: **55**; after the session's three rows: **59**
- `workflow_type = 'hoa-export-evidence'`: **0 rows** before this run

## Path driven (live UI, Admin tab)

| # | Action fired | Transition | Result |
|---|---|---|---|
| 1 | "New HOA export" (speedDial FAB) | create | `draft` |
| 2 | "Preview redactions" | `preview-export` | → **`preview`** |
| 3 | "Approve redaction preview" | `approve-redaction` | → **`redaction-approved`** |
| 4 | "Generate export" | `generate-export` | → **`generating`** |
| 5 | "Record generation complete" | `complete-export-generation` | → **`ready`** |
| 6 | "Download export" | `request-export-download` (`to: null`) | no bundle exists — see below |
| 7 | "Cancel export" | `cancel-export` | → **`cancelled`** |

**Five state changes fired from the real UI.**

## Row confirmed in Postgres (same session)

```
 instance_id       community_cedar_commons_hoa_hoa-export-evidence_glbkmvcmltft
 community_id      community_cedar_commons_hoa
 workflow_type     hoa-export-evidence
 created_by_fan_id fan-hoa-board-1
 current_state     cancelled
 created_at        1789245794313  (2026-09-12 20:43:14 UTC)
```

`instance_data` at `ready`, before cancelling — note the engine recorded every transition with its
actor:

```json
{"exportLabel": "B25-Export-Board1", "scope": "Board-Records-2026Q3",
 "redactionPreview": "Redact-PII", "provider": "Loom-Export",
 "exportStatus": "Ready; checksum verification pending",
 "transferId": "b1c1150c-80ec-43de-9478-1dd0e849882d",
 "generatedAt": "2026-09-12T20:46:23.593664Z",
 "checksumStatus": "verification-pending",
 "statusHistory": [
   {"status": "preview",            "actorFanId": "fan-hoa-board-1", "at": "2026-09-12T20:45:08.567275Z"},
   {"status": "redaction-approved", "actorFanId": "fan-hoa-board-1", "at": "2026-09-12T20:45:47.647452Z"},
   {"status": "generating",         "actorFanId": "fan-hoa-board-1", "at": "2026-09-12T20:46:23.593664Z"},
   {"status": "ready",              "actorFanId": "fan-hoa-board-1", "at": "2026-09-12T20:47:05.671198Z"}]}
```

The on-screen History block rendered these same four entries verbatim.

**Do the two halves agree? Yes** — every displayed state matched the stored `current_state` when
queried, and `created_by_fan_id` is the identity I authenticated as.

## The `start-export-transfer` dead branch — expected, explained, and confirmed absent

`start-export-transfer` was **not offered at `ready`**, exactly as the brief predicted. Recording it
as an expected, explained absence — **not a defect and not a missing button**.

Mechanism, verified in the package rather than assumed:

- The transition is guarded `instanceDataEquals: {key: checksumVerified, value: true}`.
- `checksumVerified` is declared `type: bool`, **`writableBy: "platform"`**, `hideWhenEmpty: true`.
- It is one of the four missing platform services (checksum). **Nothing writes it**, and it is
  absent from `instance_data` entirely — not `false`, simply not present.

Consequently the whole `transferring` → `transferred` → `rolled-back` branch is unreachable today.

**A control makes this a precise negative rather than a rendering failure.** At `ready` the three
*other* transitions valid from that state — `change-export-scope`, `request-export-download`,
`cancel-export` — were **all rendered** ("Change scope", "Download export", "Cancel export"). So the
card is evaluating and rendering `ready` transitions correctly; only the checksum-guarded one is
withheld, which is the guard doing its job.

The gap is visible in the product surface too, honestly rather than silently: the card displays
**"Checksum status: Verification Pending"** and **"Status: Ready; checksum verification pending"**,
both written by the `generate-export` effect into `checksumStatus`/`exportStatus`. The workflow
states plainly that it is waiting on a verification that will never arrive.

**Contrast worth noting:** `transferId` is also `writableBy: "platform"`, but it declares
`platformSource: "opaqueId"` and **was** minted (`b1c1150c-80ec-43de-9478-1dd0e849882d`). So the
platform-write mechanism itself works; `checksumVerified` is specifically the field whose backing
service does not exist. That distinction is what separates "declared but unimplemented service" from
"broken platform writer".

## Second missing-service surface, reported honestly by the UI

Firing "Download export" (`request-export-download`) did not produce a download. The card displayed:

> **Export download is unavailable until this app session generates a bundle.**

`workflow_export_bundles` contains **0 rows**, confirming no bundle was created. The state correctly
remained `ready` (the transition is `to: null`).

**Reported precisely:** I observed the message and the empty table. I cannot distinguish from the
outside whether the UI short-circuited before calling the engine or the engine ran a no-op, because
a `to: null` transition with no authored effects would leave no trace either way. What is certain is
that no bundle exists and the user is told so explicitly rather than being handed a silent failure —
which is the correct behaviour for an unimplemented capability.

## Defects observed

None. Both gaps above are declared-but-unimplemented platform services, surfaced honestly by the
product rather than papered over.
