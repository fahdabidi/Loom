**Workflow:** `platform-in-stream-ad` in Member Social Space
**Outcome:** Both halves of the proof standard were met — the instance was created live on device through the Home-tab "Provision sponsored item" FAB as the authenticated moderator, and the `report-sponsor` transition was fired and confirmed in Postgres to have mutated `instance_data` (`reportedByFanIds` `[]` → `["fan-social-moderator-1"]`) with `current_state` correctly unchanged at `filled`.

**Package identity:**
- `"skillVersion": "3.3.0"`
- `3b2081ccf7fd223e5254276f4d70f08411df3a49659b0c00ad417a277d1ea3d5  app/packages/core/loom_communities_app_shell/assets/Loom_Communities_Workflow_Engine_MemberSocialSpace_Example.jsonc`

**Date:** 2026-09-12
**Device:** `emulator-5554` (Windows host, reached via `ADB_SERVER_SOCKET=tcp:192.168.56.1:5037`)

## Identity

- Keycloak account: `loom-social-moderator-1` (realm `loom`, client `loom-test-client`)
- Fan id: `fan-social-moderator-1`; community role: `moderator`
- This was an identity switch from a prior Masjid Nur run, so **both** Chrome and the Loom app were
  cleared (`pm clear com.android.chrome`, `pm clear com.example.loom_communities_demo`). The launch
  screen then showed **"Loaded 10 example communities"**, confirming the preload flag is compiled
  into the installed APK.
- The real Keycloak login form appeared with an **empty** username field — no stale SSO cookie
  re-issued a previous fan's token. Credentials were typed and verified on screen before submitting
  (username untruncated; password field showed 12 characters, matching `LoomTest123!`).
- After OAuth, **Social Moderator 1 / `fan-social-moderator-1`** was selected from the account list,
  and the app rendered "Signed in as Social Moderator 1 — Moderator".

## Baseline, measured in this session before touching anything

    select count(*) from workflow_instances;   ->  52
    workflow_type = 'platform-in-stream-ad'    ->  0 rows

The three target definitions were confirmed published before driving anything, so a silent
create-into-nothing was ruled out:

    community_member_social_space_platform-in-stream-ad        | platform-in-stream-ad       | version 4

## Path driven

1. Launcher → community list → **Platform Social** (the Member Social Space package's `displayName`).
2. Signed in as above; landed on the **Home** tab.
3. Tapped the create FAB. All three moderator create actions rendered on `home`:
   "Provision protected no-fill", "Provision banner slot", "Provision sponsored item".
4. Tapped **"Provision sponsored item"**. The dialog carried no form fields — every field in this
   workflow is `writableBy: "platform"` and fully supplied by the create action's `prefill`, so the
   dialog is a plain confirm. Tapped **Create**. (No `adb shell input text` was used anywhere in this
   run, so the silent-truncation trap does not apply to any value recorded here.)
5. The card rendered in the Home stream with state **Filled**, `Sponsor: Riverside Outdoors Co.`,
   `Sponsored`, the body and context text, `Open sponsor`, and `Reports: 0`.
6. Three transitions were offered: **View** (`record-impression`), **Open sponsor**
   (`open-sponsor-link`), **Report sponsor** (`report-sponsor`). **Dismiss** was correctly absent —
   `dismiss-ad` is `member`-guarded and this actor is a moderator. This is expected, not a defect.
7. Fired **Report sponsor**.

## Final UI state

The card remained in state **Filled**. The `reportCount` formula chip changed from **"Reports: 0"**
to **"Reports: 1"**, and the **Report sponsor** button disappeared from the card — correct, because
`report-sponsor` guards on `actorInList: {key: reportedByFanIds, present: false}` and the actor is
now in that list. View and Open sponsor remained.

## Database confirmation (same session)

    instance_id       community_member_social_space_platform-in-stream-ad_9ypr9ovvh8gb
    community_id      community_member_social_space
    workflow_type     platform-in-stream-ad
    created_by_fan_id fan-social-moderator-1
    current_state     filled
    created_at        1789243097050  =  2026-09-12 19:58:17 UTC

`created_at` is one second after the locally recorded pre-create timestamp of 19:58:16Z, so this row
is distinguished by its own instance id and timestamp rather than by any change in row count. The
`community_id` was read off the row itself, not constructed from the group handle.

`instance_data`, before and after the transition:

    before  {... ,"dismissible":true,"reportedByFanIds":[]}
    after   {... ,"dismissible":true,"reportedByFanIds":["fan-social-moderator-1"]}

## Do the two halves agree?

**Yes.** The device showed "Reports: 1" and withdrew the Report sponsor affordance; the database
shows `reportedByFanIds: ["fan-social-moderator-1"]` on the same instance, `created_by_fan_id`
matching the identity actually authenticated, and `current_state` still `filled`.

**On the absence of a state change:** `platform-in-stream-ad` declares exactly one state (`filled`)
and every transition is `to: null`. There is no terminal state to reach, so the proof here is
creation plus a bookkeeping mutation, not advancement. The unchanged `current_state` is correct by
design.

## Defects observed

None. Every affordance the package declares for a moderator rendered and behaved as declared, and
both guard self-exclusions fired correctly.
