**Workflow:** `platform-top-banner-no-fill` in Member Social Space
**Outcome:** Both halves of the proof standard were met — the instance was created live on device through the Home-tab "Provision banner slot" FAB as the authenticated moderator, and both of its transitions were fired and confirmed in Postgres to have mutated `instance_data` (`reasonInspectedByFanIds` `[]` → `["fan-social-moderator-1"]`, and `lastRefreshedAt` written as a new timestamp field) with `current_state` correctly unchanged at `no-fill`.

**Package identity:**
- `"skillVersion": "3.3.0"`
- `3b2081ccf7fd223e5254276f4d70f08411df3a49659b0c00ad417a277d1ea3d5  app/packages/core/loom_communities_app_shell/assets/Loom_Communities_Workflow_Engine_MemberSocialSpace_Example.jsonc`

**Date:** 2026-09-12
**Device:** `emulator-5554` (Windows host, reached via `ADB_SERVER_SOCKET=tcp:192.168.56.1:5037`)

## Identity

- Keycloak account: `loom-social-moderator-1` (realm `loom`, client `loom-test-client`)
- Fan id: `fan-social-moderator-1`; community role: `moderator`
- Same authenticated session as the other two Member Social Space rows driven on this date. Chrome
  and the Loom app were both cleared before signing in; the real Keycloak form appeared with an
  empty username field (no stale SSO re-issue), and the app then reported
  "Signed in as Social Moderator 1 — Moderator". The launch screen confirmed
  **"Loaded 10 example communities"**.

## Baseline, measured in this session before touching anything

    select count(*) from workflow_instances;        ->  52
    workflow_type = 'platform-top-banner-no-fill'   ->  0 rows

Definition confirmed published beforehand, ruling out a silent create-into-nothing:

    community_member_social_space_platform-top-banner-no-fill | platform-top-banner-no-fill | version 4

## Path driven

1. **Platform Social** community → **Home** tab, signed in as above.
2. Tapped the create FAB; all three moderator create actions rendered on `home`.
3. Tapped **"Provision banner slot"**. The dialog carried no form fields — every field is
   `writableBy: "platform"` and fully supplied by the create action's `prefill` — so it is a plain
   confirm. Tapped **Create**. No text was typed anywhere in this run.
4. The card rendered in the Home stream with state **No fill** (warning tone) and the chips
   `Ad space reserved`, `No eligible sponsor available for this slot right now.`,
   `Reserved banner space remains available.`
5. Both declared transitions were offered: **Refresh slot** (`refresh-slot`) and
   **Inspect no-fill reason** (`inspect-reason`).
6. Fired **Inspect no-fill reason**, then **Refresh slot** — deliberately exercising both authored
   effect shapes this workflow has: an `appendUnique` of `$actor` and a `set` of `$timestamp`.

## Final UI state

The card remained in state **No fill**. After the first transition, **Inspect no-fill reason**
disappeared from the card — correct, because it guards on
`actorInList: {key: reasonInspectedByFanIds, present: false}` and the actor is now in that list.
**Refresh slot** carries no such guard and correctly remained available, and was fired second.

## Database confirmation (same session)

    instance_id       community_member_social_space_platform-top-banner-no-fill_5xn6vnzww3ze
    community_id      community_member_social_space
    workflow_type     platform-top-banner-no-fill
    created_by_fan_id fan-social-moderator-1
    current_state     no-fill
    created_at        1789243366038  =  2026-09-12 20:02:46 UTC

`created_at` matches the locally recorded pre-create timestamp of 20:02:45Z, so the row is
identified by its own instance id and timestamp, not by a change in row count. The `community_id`
was read off the row itself rather than derived from the group handle.

`instance_data`, before and after the two transitions:

    before  {"disclosureText":"Ad space reserved","noFillReason":"No eligible sponsor available for this slot right now.",
             "slotLayoutStatus":"Reserved banner space remains available.","reasonInspectedByFanIds":[]}

    after   {"disclosureText":"Ad space reserved","noFillReason":"No eligible sponsor available for this slot right now.",
             "slotLayoutStatus":"Reserved banner space remains available.",
             "reasonInspectedByFanIds":["fan-social-moderator-1"],
             "lastRefreshedAt":"2026-09-12T20:04:05.692341Z"}

Note that `lastRefreshedAt` is a field the create action does not prefill; it appears only because
`refresh-slot` wrote it. That is a second, independent witness that a transition ran server-side.

## Do the two halves agree?

**Yes.** The device withdrew the Inspect affordance and held state No fill; the database shows both
mutations on the same instance, with `created_by_fan_id` matching the identity actually
authenticated and `current_state` still `no-fill`.

**On the absence of a state change:** `platform-top-banner-no-fill` declares exactly one state
(`no-fill`) and both transitions are `to: null`. There is no terminal state to reach, so the proof
is creation plus bookkeeping mutations, not advancement. The unchanged `current_state` is correct by
design — and with `refresh-slot` producing no visible on-screen change at all, the database was the
only witness available for it.

## Defects observed

None. Both declared transitions rendered and behaved as declared.
