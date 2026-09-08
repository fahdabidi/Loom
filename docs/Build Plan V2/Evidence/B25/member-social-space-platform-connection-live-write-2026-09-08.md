# Member Social Space — `platform-connection` live write, re-verified with database proof

**Date:** 2026-09-08 (device local, America/Los_Angeles = UTC-7; engine stamps are UTC, so
`13:42:47Z` is 06:42 local)
**Device:** `emulator-5554`, Android 1080x2400, Windows-hosted
**adb path:** this session ran **on the Loom VM itself** (`fahd-VirtualBox`), which has no AVD. The
emulator was reached through the **Windows host's adb server** — `adb -H 192.168.56.1 -P 5037`.
**App:** `com.example.loom_communities_demo/.MainActivity`, installed build `lastUpdateTime=2026-09-08 00:17:13`
**Workflow:** `platform-connection` in Platform Social (`community_member_social_space`,
`ext_member_social_space`)
**Supersedes:** the reopened Member Social Space claim, which had no corresponding database row.

## Outcome

Both halves of the proof standard were met **in one session**, and the UI evidence and the Postgres
row are reported together and **agree**.

- Signed in for real as **`loom-social-member-1`** (fan `fan-social-member-1`, role `member`)
  through the in-app OAuth flow against Keycloak — the real login form, not a silent SSO re-issue.
- Created a `platform-connection` **from nothing** through the real UI, reaching `draft`.
- Drove `send-invite` → `invited`.
- Read the row back from Postgres with `kubectl exec … psql` after each step.

**Then a second, deliberate check that produced the more valuable result:** I re-authenticated as
the **invitee** and found the invite cannot be accepted or declined by anyone. Details under
*Unreachability finding* below.

## Baseline control

Measured immediately before the dispatch and re-confirmed by me at the start of this session:

| | Baseline | After |
|---|---:|---:|
| `workflow_instances` total | 18 | **19** |
| `workflow_type = 'platform-connection'` | 0 | **1** |

The zero was a real negative result, so the row below is necessarily mine.

## The row

```
instance_id       community_member_social_space_platform-connection_dk85uakyedz4
community_id      community_member_social_space
workflow_type     platform-connection
created_by_fan_id fan-social-member-1
current_state     invited
created_at        2026-09-08 13:42:47+00
instance_data     {"inviterFanId":"fan-social-member-1",
                   "reason":"Met at the community meetup",
                   "inviteeFanId":"fan-social-moderator-1"}
```

`created_by_fan_id` is **`fan-social-member-1`**, matching the identity I authenticated as and drove.
The UI and the database agree at every step: the card read `Draft` when the row read `draft`, and
`Invite sent` when the row read `invited`.

## Field values settled against the stored row, not the screen

`adb shell input text` **truncated on the first attempt** — `Met at the community meetup` was typed
and only `Met` reached the device, cut at the first space. Retyped with `%s` space escapes. Both
load-bearing values were then settled against `instance_data`, not against the field on screen:

- `reason` — `Met at the community meetup`, complete.
- `inviteeFanId` — `fan-social-moderator-1`, complete, no truncated prefix.

`inviterFanId` was written by the create action's `prefill: {inviterFanId: "$actor"}` and resolved
correctly to the authenticated fan. `expiresAt` was deliberately left blank so the `accept-invite`
guard's formula `if(expiresAt == null, true, !isPast(expiresAt))` could not be the thing that
blocked the invitee.

## Unreachability finding — `connected` cannot be reached by any provisioned pair

**This is failure shape 1 (role never provisioned), and it is not a consequence of my choice of
invitee.**

Both halves of a connection require the actor to hold the package role `member`. From the
**deployed** definition in `workflow_definitions` (not merely the package on disk):

```
send-invite    {"allowedRoleIds": ["member"], "actorEqualsField": {"key": "inviterFanId"}}
accept-invite  {"allowedRoleIds": ["member"], "actorEqualsField": {"key": "inviteeFanId"},
                "formula": "if(expiresAt == null, true, !isPast(expiresAt))"}
decline-invite {"allowedRoleIds": ["member"], "actorEqualsField": {"key": "inviteeFanId"}}
```

App Access provisions exactly three fans in this community, and **only one holds `member`**:

```
fan-social-member-1     loom_communities_member-social-space  active  member
fan-social-moderator-1  loom_communities_member-social-space  active  moderator
fan-social-admin        loom_communities_member-social-space  active  member-social-space-admin
```

The single `member` is the inviter. There is therefore **no pair of provisioned accounts in which
both the inviter and the invitee hold `member`**, so `connected` is unreachable for any genuine
two-party connection, and `declined` is unreachable by the invitee. The only string that satisfies
both guards is a self-invite, where `inviterFanId == inviteeFanId` — degenerate, and not a
legitimate path.

`member-social-space-admin` is the generated governance role and holds none of the package's domain
roles, so it does not close the gap either.

### Confirmed live on the device, not merely reasoned from JSON

I re-authenticated as the invitee — **`loom-social-moderator-1`** (fan `fan-social-moderator-1`),
named here as the ticket requires — and opened the same instance.

- The invitee **can see** the record, on both the `home` and `admin` surfaces. Failure shape 2 does
  **not** apply: `visibility.fields.parties` correctly admits both parties, and the moderator is
  additionally in the `readGuard`.
- The invitee's card carries **zero action buttons**. No `Accept`, no `Decline`, no `Block` — the
  card ends after the field chips.
- **Control:** the inviter's card, in the same `approvalQueueItem` surface, rendered `Cancel invite`
  and `Block` as full-width buttons. Action buttons do render in this surface, so their absence for
  the invitee is a guard result and not a rendering gap.

The invite is consequently stranded in `invited` with only inviter-side exits (`cancel-invite`,
which lands in `declined`). A member can send an invitation that its recipient can neither accept
nor refuse.

**Recommended fix is provisioning, not grammar:** seed a second fan holding `member` (e.g.
`fan-social-member-2`). The definition itself is coherent — a connection between two members
legitimately requires both parties to be members.

## Failure shape 4 — checked and clean

The only `createInstance` effect on this workflow is inside `block`, targeting
`platform-blocked-target`. That type **is** present in the deployed catalog:

```
platform-blocked-target      platform-message-thread
platform-connection          platform-sensitive-no-fill
platform-in-stream-ad        platform-top-banner-no-fill
```

All six `platform-*` types this package declares are published. The `block` path was not driven, so
no `platform-blocked-target` instance exists — confirmed by query, which returned `platform-connection | 1`
as the only `platform-*` row.

## Failure shape 3 — not applicable

No transition on this workflow carries a state precondition beyond the expiry formula, and that
formula was satisfied by leaving `expiresAt` null.

## Observations

- **No raw field key reached the user as a label.** Every field on the create form and the card
  rendered a proper label — `Reason`, `Invitee`, `Invite expires`, `Invited by Fan Social Member 1`,
  `Invitee: Fan Social Moderator 1`. This community does not reproduce the `memberNotice` /
  `photoImage` defect.
- **Tab visibility is correct.** `admin` declares `visibleRoleIds: ["moderator"]`; it was absent for
  the member and present for the moderator. `home` and `messages` are platform-generated tabs
  (`_defaultTabSpecs` / `_mergeDeclarativeTabSpecs`), which is why this package declares only
  `admin` and still renders three tabs.
- **The anti-impersonation guard fired correctly and cost real time.** With a stored session for a
  previous fan, tapping `Social Member 1` returned
  `LoomAuthException(accountNotFound): The authenticated Loom identity cannot sign in as account
  "fan-social-member-1"`. The account rows look identical whether or not they are actionable, and
  the failure is a transient SnackBar — it is invisible unless the screenshot is taken within ~2s of
  the tap. `pm clear` on both the app and `com.android.chrome`, plus the Keycloak logout endpoint,
  was required before the real login form appeared.

## Reproduction

```bash
PW=$(kubectl get secret postgres-credentials -n loom -o jsonpath='{.data.password}' | base64 -d)
kubectl exec -i -n loom postgres-0 -- env PGPASSWORD="$PW" \
  psql -U loom -d loom_workflow_service \
  -c "select instance_id, created_by_fan_id, current_state, instance_data
        from workflow_instances where workflow_type='platform-connection';"

kubectl exec -i -n loom postgres-0 -- env PGPASSWORD="$PW" \
  psql -U loom -d loom_app_access -c "
    select gm.fan_id, gm.state, gmr.role_id
      from group_membership gm
      left join group_membership_role gmr
        on gmr.app_id=gm.app_id and gmr.group_id=gm.group_id and gmr.fan_id=gm.fan_id
     where gm.fan_id like 'fan-social%' order by gm.fan_id;"
```

Screenshots were captured to `/tmp/msp_evidence/` and are **not** durable — `*.png` is gitignored.
This manifest is the evidence of record.
