# B25 evidence manifest — Member Social Space / `platform-connection`

- **Date (UTC):** 2026-09-09
- **Dispatch:** B25 re-verification, walkthrough + UX-judge frame capture, two-party path
- **Result:** Both halves of the proof standard met in one session, and they agree. The workflow
  was driven end-to-end by **two** authenticated identities to the state `connected`.

## Package identity (the artifact actually driven)

```
P=app/packages/core/loom_communities_app_shell/assets/Loom_Communities_Workflow_Engine_MemberSocialSpace_Example.jsonc
"skillVersion": "3.3.0"
sha256 3b2081ccf7fd223e5254276f4d70f08411df3a49659b0c00ad417a277d1ea3d5
```

- `extensionId` `ext_member_social_space`, `communityId` `community_member_social_space`,
  `communityHandle` `member-social-space`, display name **Platform Social**
- Repo HEAD at capture: `0b966cb5`
- APK on device: `com.example.loom_communities_demo` versionName `0.1.0`,
  `lastUpdateTime=2026-09-09 09:56:01`
- Deployed definition: `community_member_social_space_platform-connection`, **version 4**,
  present in `workflow_definitions` — so `createInstance` was not a silent no-op.

## Identities

Two accounts were used, because this workflow **requires two members by construction** — every
invite transition is guarded `allowedRoleIds: ["member"]` plus an `actorEqualsField` on either
`inviterFanId` or `inviteeFanId`, so one identity cannot drive it alone.

| Step | Keycloak user | fan id | role |
|---|---|---|---|
| create + `send-invite` | `loom-social-member-1` | `fan-social-member-1` | `member` |
| `accept-invite` | `loom-social-member-2` | `fan-social-member-2` | `member` |

- **This is not an escalation.** Both accounts hold the same declared package role, `member`.
  The ticket named `loom-social-member-1` and explicitly authorised `loom-social-member-2` for
  the second party.
- No credential was created or reset.
- Independent control before touching the device: password-grant against `loom-test-client`
  returned HTTP 200 for **both** accounts, with `preferred_username`/`fanId` pairs matching the
  seeded convention exactly.
- Role holders confirmed in `loom_app_access`: `member` is held by `fan-social-member-1` and
  `fan-social-member-2`, both `state=active`; both have `fan_passport` rows.

### Stale-SSO trap handled twice, and it never fired

Before *each* sign-in: Keycloak logout endpoint (HTTP 200), then `pm clear` on
**both** `com.android.chrome` and the app. Each time the entry gate then stated in its own words
`LoomAuthNotLoggedInException: No Loom authentication session is stored; login is required`
(negative control), and the **real Keycloak form appeared with empty fields** —
`02-keycloak-login-form.png` and `11a-keycloak-form-member2.png`. No silent re-issue in either
direction.

The identity was independently confirmed a second way: selecting **Test social-member-2** in the
picker succeeded, and the app compares the selected account id against the token's `fanId` and
rejects a mismatch — so the accept was driven by a token genuinely belonging to
`fan-social-member-2`, not merely a selection. `13-member2-in-community.png` reads
"Signed in as Test social-member-2 / Member".

## Path driven

**As `fan-social-member-1`:** Platform Social → Home → create FAB → **"Send connection invite"** →
filled `Reason` and `Invitee`, left `Invite expires` empty → **Create** → instance created in
`draft` → scrolled to the draft card → **"Send invite"** → **`invited`**.

**As `fan-social-member-2`:** re-entered the community → the invite addressed to them rendered
with **Accept / Decline / Block** → **Accept** → **`connected`**.

`connected` is the workflow's intended successful outcome. (`declined` is the only state flagged
`isTerminal`; `connected` is the positive-tone state the product doc's connection flow exists to
reach, and it retains only `block` as an exit.)

## The row — and it agrees with the screen

| | |
|---|---|
| `instance_id` | `community_member_social_space_platform-connection_s7w9bdft4lhb` |
| `community_id` | `community_member_social_space` |
| `workflow_type` | `platform-connection` |
| `created_by_fan_id` | **`fan-social-member-1`** — matches the identity that created and invited |
| `current_state` | **`connected`** |
| `created_at` | 1788978418685 → 2026-09-09 18:26:58 UTC |

`instance_data` at `connected`, verified against what was typed — **no truncation**:

```json
{ "inviterFanId": "fan-social-member-1",
  "reason": "B25 re-verification connect",
  "inviteeFanId": "fan-social-member-2",
  "respondedAt": "2026-09-09T18:44:18.956296Z" }
```

The `accept-invite` effect `{"op":"set","key":"respondedAt","value":"$timestamp"}` fired, and the
create action's `prefill` of `inviterFanId=$actor` fired. `inviteeFanId` is the full
19-character value, **not** the truncation this ticket warns about — see the defect note below,
where the trap did fire and was caught.

**Both halves agree.** The screen at `16-after-accept-2.png` shows a green **Connected** chip,
"Invited by Fan Social Member 1", "Invitee: Fan Social Member 2", and **only** `Block` remaining
as an action — which is exactly right, since `block` is the sole transition whose `from` includes
`connected`.

## Baseline — the ticket's stated control was stale, corrected here

The ticket said `workflow_instances` held **6** rows and **zero** of `platform-connection`, and
that "no corresponding row exists in the database today. **Do not** look for the old instance".
**Both claims are false as measured.**

Pre-dispatch snapshot at 2026-09-09T18:11Z: **22 rows total**, and **one**
`platform-connection` — `community_member_social_space_platform-connection_dk85uakyedz4`,
state `invited`, `created_by_fan_id` `fan-social-member-1`, created **2026-09-08 13:42:47 UTC**.
That is exactly the row the previous dispatch reported; it was never missing.

Post-dispatch: **2** rows of this type. Mine is distinguished by instance id
(`…_s7w9bdft4lhb`), by `created_at` one second after my own tap, and by its `reason`
(`B25 re-verification connect`) — **not** by the ticket's count, which could not have
distinguished anything.

## Defects and observations

1. **The 2026-09-08 instance has an invitee who can never respond — a real reachability gap.**
   `…_dk85uakyedz4` names `inviteeFanId = fan-social-moderator-1`. Both `accept-invite` and
   `decline-invite` are guarded `allowedRoleIds: ["member"]` **and** `actorEqualsField:
   inviteeFanId`. Verified live: `fan-social-moderator-1` holds **only** `moderator` in
   `group_membership_role` for this group. So the addressed invitee has **no path to accept or
   decline**, and that instance still sits in `invited` after 29 hours.
   The instance is not fully dead — the *inviter* retains `cancel-invite` and `block`, and both
   render (`04b-member1-existing-invite-card.png`) — but the invitee's side is unreachable.
   **Root cause is the free-text `Invitee` field:** the create form accepts any fan id with no
   check that the target holds `member`, so a member can address an invite to someone who is
   structurally incapable of answering it. This is the "guarded role cannot act" shape, arising
   from data rather than declaration. **This is a finding about the seeded/typed data and the
   unvalidated input, not a request to edit the package.**

2. **No product defect found in `platform-connection` itself on this build.** Every guard behaved
   exactly as declared: the inviter saw `Send invite` on `draft` and `Cancel invite`/`Block` on
   `invited`; the invitee saw `Accept`/`Decline`/`Block`; after `connected` only `Block` remained;
   and the invite addressed to Moderator 1 was **not** shown to member-2 (party-scoped
   visibility working).

3. **The previously reported "invitee sees zero action buttons" is resolved — by seeding, as
   designed.** With two `member` holders now present, the invitee is offered all three actions
   (`14-member2-offered-accept.png`). This confirms the earlier defect was a seeding gap, not a
   package defect, and it was fixed without touching the JSON.

4. **A near-miss worth recording: I almost reported a rendering defect that does not exist.**
   Each `invited` connection renders **twice** on Home — once with its reason chip and full
   actions, once without the reason chip. That is **by design**: the package declares two `home`
   `renderBindings` matching `invited` — a `primary` `approvalQueueItem` and a `summary`
   `notificationInbox`. I initially read the duplicate as a wrong render because I had not
   scrolled far enough to see my own `draft` card, which was further down and rendered perfectly.
   Reading the `renderBindings` settled it. Recorded because the surface genuinely looks like a
   duplication bug until you read the bindings.

5. **`adb shell input text` corrupted input twice, exactly as documented.**
   `loom-social-member-1` was truncated to `loom-soc` (20 chars → 8), and trailing spaces in
   chunked writes were silently dropped, yielding `B25re-verificationconnect`. Both were caught
   **before submit** by screenshotting the field, and retyped in short chunks using `%s` for
   spaces. Every load-bearing value was then settled against the database, not the screen —
   which is how `inviteeFanId` is known to be complete.

6. **Environment, not product: Chrome ANR'd repeatedly during the second sign-in.**
   "Chrome isn't responding" persisted across three `Wait` taps and ~2.5 minutes, with the
   Keycloak form rendered but unresponsive behind it. VM load was **3.85 / 3.03 / 3.15** on 8
   cores — not saturation. Recovered with `am force-stop com.android.chrome` and restarting the
   OAuth flow from the app; the Custom Tab then opened directly (no first-run) and the form
   worked. Chrome's **first-run onboarding** also intercepted the first OAuth launch, as the
   ticket warned, and was dismissed with "Use without an account".
   The device's `lastanr` record was `Sep 9, 2026 10:21:48 AM` — **before** this session began at
   11:13 device time — so that earlier ANR is not attributable to this run.

## Screenshots for the UX judge

Written to **`evidence/b25/social-platform-connection-20260909/`** on the Loom VM
(`fahd-VirtualBox`), **16 PNG frames**, 1080x2400. **`*.png` is gitignored, so these frames are
NOT committed** — only this manifest is durable. The judge must be run against them before this
directory is cleaned.

| Frame | Shows |
|---|---|
| `01-entry-platform-social.png` | community entry gate, unauthenticated; `LoomAuthNotLoggedInException` stated plainly |
| `02-keycloak-login-form.png` | the real Keycloak form at `192.168.56.10:30082` — proof of no silent SSO re-issue (member-1) |
| `03-signed-in.png` | account list after successful OAuth; identities grouped by role |
| `04-community-open.png` | **entry** — inside Platform Social, "Signed in as Social Member 1", role Member |
| `04b-member1-existing-invite-card.png` | the 2026-09-08 instance as its inviter: `Cancel invite` / `Block` |
| `05-create-menu.png` | create affordance — speed dial with "Send connection invite" |
| `06-invite-form.png` | empty create form: Reason, Invitee, Invite expires |
| `07-invite-form-filled.png` | **action** — both fields filled and verified character-exact before submit |
| `09-draft-with-send-invite.png` | the new instance in `draft`, invitee `fan-social-member-2` untruncated, `Send invite` offered |
| `10-after-send-invite.png` | **result (party 1)** — `Invite sent`, invitee Member 2, reason chip present |
| `11a-keycloak-form-member2.png` | real Keycloak form again, empty fields — no SSO carryover to the second identity |
| `11-member2-credentials.png` | member-2 credentials verified character-exact before submit |
| `12-member2-signed-in.png` | account list; both members present under role Member |
| `13-member2-in-community.png` | **entry (party 2)** — "Signed in as Test social-member-2", role Member |
| `14-member2-offered-accept.png` | **the key frame** — invitee is offered `Accept` / `Decline` / `Block` |
| `16-after-accept-2.png` | **terminal result** — green `Connected`, only `Block` remains |

## Scope

No application code, community JSON, or tracker was modified. No credential was created or reset.
No test suites were run — this dispatch changed no code, so the five suite baselines are untouched
and **no claim is made about them**. Only this manifest is committed.
