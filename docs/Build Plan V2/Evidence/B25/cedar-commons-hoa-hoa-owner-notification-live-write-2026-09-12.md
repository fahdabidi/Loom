**Workflow:** `hoa-owner-notification` in Cedar Commons HOA
**Outcome:** Both halves of the proof standard were met — sent an owner notice live on the device as `fan-hoa-board-1` to a real recipient fan, then withdrew it, advancing the instance from `sent` to the clearly-advanced state `withdrawn`; the row was confirmed in Postgres.

This workflow **declares no terminal state** (states are `sent` and `withdrawn`, neither carries
`isTerminal`, and `resend-notification` cycles back). The proof is therefore a *clearly advanced*
state, not a terminal one, and this manifest does not claim otherwise.

## Package identity

- Package: `app/packages/core/loom_communities_app_shell/assets/Loom_Communities_Workflow_Engine_CedarCommonsHOA_Example.jsonc`
- `skillVersion`: **3.6.0**
- `sha256`: **38c70ed08eabe2ef07011658bdea2434008e385b271e4ae6b98a29007369fd7f**

## Identity

- Keycloak user **`loom-hoa-board-1`**, fan id **`fan-hoa-board-1`**, role **`hoa-board`**
- Verified at all three layers before the run (Keycloak token, `fan_passport` row,
  `group_membership_role` row in `loom_communities_cedar-commons-hoa`).
- The decoy `loom-cedar-board-1` was **not** used — it authenticates but holds zero roles.
- A real Keycloak login form was presented and completed after clearing **both** Chrome and app data.

## Baseline — measured, not assumed

**This row had two pre-existing instances**, so the count is useless as a signal and I distinguish my
row by instance id and `created_at`:

```
 community_cedar_commons_hoa_hoa-owner-notification_gbduggeiojjd | fan-hoa-board-1  | sent | 2026-09-07 02:42:01
 community_cedar_commons_hoa_hoa-owner-notification_7wi6ylrjxdth | fan-hoa-member-1 | sent | 2026-09-12 15:12:05
```

Both sat in `sent`. **Neither had ever left the initial state**, which makes my row unambiguous:
it is the only `hoa-owner-notification` instance in the database that has ever reached `withdrawn`.

`workflow_instances` total before the session: **55**; after: **59**.

## Path driven (live UI, Admin tab)

| # | Action fired | Transition | Result |
|---|---|---|---|
| 1 | "Send owner notice" (speedDial FAB) | create | lands directly in **`sent`** (not a draft) |
| 2 | "Withdraw notice" | `withdraw-notification` | → **`withdrawn`** |

`resend-notification` (`withdrawn` → `sent`) was offered on the resulting card and I **deliberately
did not fire it**, so the final stored state remains the advanced one. Its presence is recorded here
as evidence the cycle is live in both directions.

## My row, confirmed in Postgres (same session)

```
 instance_id       community_cedar_commons_hoa_hoa-owner-notification_j6twg8klbjaz
 community_id      community_cedar_commons_hoa
 workflow_type     hoa-owner-notification
 created_by_fan_id fan-hoa-board-1
 current_state     withdrawn
 created_at        1789245481358  (2026-09-12 20:38:01 UTC)
```

Stored `instance_data`:

```json
{"senderFanId": "fan-hoa-board-1", "sentAt": "2026-09-12T20:34:48.927024Z",
 "deliveryState": "Withdrawn", "readFanIds": [],
 "title": "B25-Notice-Board1", "body": "B25-live-owner-notice",
 "recipientFanId": "fan-hoa-member-1", "withdrawnAt": "2026-09-12T20:40:15.052050Z"}
```

The withdraw effects both landed: `withdrawnAt` was written and `deliveryState` flipped to
`Withdrawn`. `senderFanId` was correctly derived from `$actor`.

**Do the two halves agree? Yes.** The card showed "Withdrawn" with `Delivery: Withdrawn`, and the
stored row reads `withdrawn`; `created_by_fan_id` is the identity I authenticated as.

## Role filtering behaved correctly

`mark-notification-read` and `mark-notification-unread` are `hoa-member`-only **and** additionally
guarded on `actorEqualsField: recipientFanId`. I am the sender, not the recipient, and hold
`hoa-board` — neither was offered. Correct on both counts. The card offered exactly one transition
in `sent` ("Withdraw notice") and exactly one in `withdrawn` ("Resend notice"), matching the
declaration.

## Observation — the recipient picker is a real member directory writing real fan ids

Worth recording because it bears on a known identifier-space concern.

The create form rendered a **Recipient** list of actual community members with their real fan ids
and roles, read from a live source:

```
Hoa Admin        fan-hoa-admin      Active  cedar-commons-hoa-admin
Hoa Board 1      fan-hoa-board-1    Active  hoa-board
Hoa Member 1     fan-hoa-member-1   Active  hoa-member
Test hoa-member-2 fan-hoa-member-2  Active  hoa-member
Alice Homeowner  fan-test-alice     Active  hoa-board
```

I selected "Hoa Member 1" and the stored value is **`recipientFanId: "fan-hoa-member-1"`** — a
genuine fan id, not a role id.

**Scoped precisely:** `recipientFanId` is declared `type: "fanId"` (scalar) with
`writableBy: "formEntry"`. This exercises the **scalar** fan-id picker. It is *not* evidence about
the separate, previously-recorded concern that `fanId[]` array fields rendered through
`AudienceMultiSelectPicker` write role ids — that is a different widget on a different field type,
and this run did not exercise it. I am reporting only what I drove.

## Defects observed

None for this workflow.
