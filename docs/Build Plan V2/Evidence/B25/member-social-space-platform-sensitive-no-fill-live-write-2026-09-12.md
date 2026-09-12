**Workflow:** `platform-sensitive-no-fill` in Member Social Space
**Outcome:** Both halves of the proof standard were met — the instance was created live on device through the Home-tab "Provision protected no-fill" FAB as the authenticated moderator, and the `review-policy` transition was fired and confirmed in Postgres to have mutated `instance_data` (`policyReviewedByFanIds` `[]` → `["fan-social-moderator-1"]`) with `current_state` correctly unchanged at `suppressed`.

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
    workflow_type = 'platform-sensitive-no-fill'    ->  0 rows

Definition confirmed published beforehand, ruling out a silent create-into-nothing:

    community_member_social_space_platform-sensitive-no-fill  | platform-sensitive-no-fill  | version 4

## Path driven

1. **Platform Social** community → **Home** tab, signed in as above.
2. Tapped the create FAB; all three moderator create actions rendered on `home`.
3. Tapped **"Provision protected no-fill"**. The dialog carried no form fields — every field is
   `writableBy: "platform"` and fully supplied by the create action's `prefill` — so it is a plain
   confirm. Tapped **Create**. No text was typed anywhere in this run.
4. The card rendered in the Home stream with state **Suppressed**, and the chips
   `Ad suppressed in this context`, `Ads are not shown alongside sensitive or protected content.`,
   `Protected community content`, `Protected content remains visible without an ad.`
5. Three transitions were offered, which is the full moderator set for this workflow:
   **Continue** (`acknowledge-suppression`), **Review policy** (`review-policy`),
   **Hide explanation** (`hide-explanation`).
6. Fired **Review policy** — the one transition of the three carrying an authored effect.

## Final UI state

The card remained in state **Suppressed**. The **Review policy** button disappeared from the card,
correctly, because `review-policy` guards on
`actorInList: {key: policyReviewedByFanIds, present: false}` and the actor is now in that list.
**Continue** and **Hide explanation** remained.

## Database confirmation (same session)

    instance_id       community_member_social_space_platform-sensitive-no-fill_yboqjsjuarnl
    community_id      community_member_social_space
    workflow_type     platform-sensitive-no-fill
    created_by_fan_id fan-social-moderator-1
    current_state     suppressed
    created_at        1789243243836  =  2026-09-12 20:00:43 UTC

`created_at` matches the locally recorded pre-create timestamp of 20:00:43Z, so the row is
identified by its own instance id and timestamp, not by a change in row count. The `community_id`
was read off the row itself rather than derived from the group handle.

`instance_data`, before and after the transition:

    before  {... ,"layoutStatus":"Protected content remains visible without an ad.","policyReviewedByFanIds":[]}
    after   {... ,"layoutStatus":"Protected content remains visible without an ad.","policyReviewedByFanIds":["fan-social-moderator-1"]}

## Do the two halves agree?

**Yes.** The device withdrew the Review policy affordance and held state Suppressed; the database
shows `policyReviewedByFanIds: ["fan-social-moderator-1"]` on the same instance, with
`created_by_fan_id` matching the identity actually authenticated and `current_state` still
`suppressed`.

**On the absence of a state change:** `platform-sensitive-no-fill` declares exactly one state
(`suppressed`) and every transition is `to: null`. There is no terminal state to reach, so the proof
is creation plus a bookkeeping mutation, not advancement. The unchanged `current_state` is correct
by design.

## Defects observed

None. Every declared moderator affordance rendered and behaved as declared.
