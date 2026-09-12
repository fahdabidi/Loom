**Workflow:** `export-transfer-verification` in Data Portability Community
**Outcome:** Both halves of the proof standard were met — created a provider transfer live through the Admin-tab FAB as `fan-portability-owner-1`, drove it `draft → transferring → awaiting-provider → cancelled` (a declared `isTerminal` state) through the real UI, and confirmed the single resulting row in Postgres.

**Package identity:** `skillVersion: "3.6.0"`, sha256 `f30994c9776871da2a4d48480f1ec83b2e7becaf16f860017dde5733ae0def43`
(`app/packages/core/loom_communities_app_shell/assets/Loom_Communities_Workflow_Engine_DataPortabilityCommunity_Example.jsonc`)

**Date:** 2026-09-12
**Device:** `emulator-5554` (Windows host, reached via `ADB_SERVER_SOCKET=tcp:192.168.56.1:5037`)

## Identity

- Account: `loom-portability-owner-1`, fan id `fan-portability-owner-1`, role `portability-owner`
- No sign-in or identity switch was required: the app was already authenticated as this account. Confirmed
  in-app before acting — the community header rendered **"Signed in as Portability Owner 1 — Owner/Admin"** —
  and confirmed again after the fact on the stored row, whose `created_by_fan_id` is `fan-portability-owner-1`.
- Nothing was cleared (`pm clear` was not run), per the ticket's instruction when the identity is already correct.
  No credential was created or reset.

## Baseline, measured in this session before acting

    select count(*) from workflow_instances;                          -- 45
    ... where workflow_type='export-transfer-verification'            -- 0 rows
    ... where workflow_type='export-transfer-rollback'                -- 0 rows

Both definitions were confirmed published before driving anything (a `createInstance` naming an unpublished
type returns success and does nothing):

    community_data_portability_export-transfer-verification | version 4
    community_data_portability_export-transfer-rollback     | version 4

After the run the table holds **46** rows — the one new row is mine, identified below by instance id and
`created_at`, not by the count.

## Path driven through the real UI

1. **Admin** tab → FAB → **"New provider transfer"**. Filled Transfer Label `B25Xfer`, From `VaultA`,
   To `VaultB`, Transfer Scope `posts`. → `draft` ("Transfer prepared").
2. **"Start transfer"** (`start-provider-transfer`, guard `size(transferScope) > 0`) → `transferring`
   ("Transfer running"). Card showed `Status: Transferring`, `Rollback: Available`, and a minted
   `Transfer ID: ec7f027b-1df5-43d9-984c-3f4faa007634`.
3. **"Send for provider verification"** (`submit-transfer-for-verification`) → `awaiting-provider`.
4. **"Cancel transfer"** (`cancel-provider-transfer-awaiting`) → **`cancelled`**, declared `isTerminal`.

Final UI state: card reads **"Transfer cancelled"** with no remaining action buttons.

In `awaiting-provider` the only action rendered to me was "Cancel transfer" — the two transitions into
`verified` (`provider-accept-transfer`, `provider-reject-transfer`) are guarded on
`portability-receiving-provider`, which I do not hold. That is the intended two-party design, not a defect,
and no identity switch was attempted.

## Database confirmation (same session)

    instance_id       community_data_portability_export-transfer-verification_0tx8cno6yx9j
    community_id      community_data_portability
    workflow_type     export-transfer-verification
    created_by_fan_id fan-portability-owner-1
    current_state     cancelled
    created_at        1789233869461  (2026-09-12 17:24:29 UTC)

Stored `instance_data`:

    {
      "startedAt": "2026-09-12T17:27:47.645606Z",
      "transferId": "ec7f027b-1df5-43d9-984c-3f4faa007634",
      "submittedAt": "2026-09-12T17:33:45.059849Z",
      "auditHistory": [
        { "at": "2026-09-12T17:27:47.645606Z", "by": "fan-portability-owner-1", "status": "transfer started" }
      ],
      "transferLabel": "B25Xfer",
      "transferScope": ["posts"],
      "sourceProvider": "VaultA",
      "transferStatus": "awaiting provider",
      "destinationProvider": "VaultB",
      "rollbackAvailability": "available"
    }

**Do the two halves agree? Yes.** The UI's terminal "Transfer cancelled" matches `current_state = cancelled`;
the identity I drove matches `created_by_fan_id`; and every value typed on the device is stored in full.

## Truncation check (explicitly verified, not assumed)

`adb shell input text` truncates silently, and `transferScope` gates step 2. All four values were read back
**from Postgres**, not off the screen: `transferLabel` `"B25Xfer"`, `sourceProvider` `"VaultA"`,
`destinationProvider` `"VaultB"`, and `transferScope` `["posts"]` — a real JSON list of one element, which is
why `size(transferScope) > 0` was satisfiable. Nothing was truncated.

Incidental note: the card renders these as "B25 Xfer" / "Vault A" / "Vault B", i.e. display-time word
splitting. The stored values are unspaced, as shown above.

## Other observations

- `transferId` is declared `platformSource: "opaqueId"` and was minted as a real UUID
  (`ec7f027b-1df5-43d9-984c-3f4faa007634`) — the opaque-id mechanism fired correctly on this path.
- No ANR or crash dialog at any point (`dumpsys window lastanr` → "no ANR has occurred since boot").
- One defect was found during this run, in the *paired* workflow rather than this one; it is reported in
  `data-portability-community-export-transfer-rollback-live-write-2026-09-12.md` and does not affect this row.
