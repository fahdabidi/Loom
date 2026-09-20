# B25 live walkthrough — Garden Club, `garden-tool-giveaway`

**Workflow:** `garden-tool-giveaway`
**Outcome:** Both halves of the proof standard were met — signed in through the real Keycloak form as `loom-garden-coordinator-1`, created a giveaway listing through the Marketplace "Give away a garden item" FAB, then cleared Chrome AND the app, signed in as `loom-garden-member-1`, and fired `claim-giveaway` from the listing's detail dialog into the terminal state `given`, confirming every field and both timestamps directly in Postgres.

(That outcome sentence is deliberately kept on one line: `check_b25_status.sh` matches the phrase
with a line-based grep, so wrapping it mid-phrase makes a proven row read as unproven.)

**Community:** Garden Club (`community_garden_club`)
**Date:** 2026-09-19 local / 2026-09-20 UTC
**Device:** `emulator-5554` (Windows-hosted AVD reached over the ssh reverse tunnel to `:5037`)
**Backend:** workflow-service `http://192.168.56.10:30083`, Keycloak `:30082`, app-access `:30080`; six pods `1/1`

**Supersedes:** `garden-club-garden-tool-giveaway-live-write-BLOCKED-2026-09-19.md`, which recorded an
attempt that could not reach the device after a VM reboot killed the tunnel. That manifest's layer
checks (definition published, deployed guard vs package, both credentials) remain accurate and were
independently re-confirmed here.

## Package identity

`app/packages/core/loom_communities_app_shell/assets/Loom_Communities_Workflow_Engine_GardenClub_Example.jsonc`

- `specVersion`: `4`
- `skillVersion`: `3.6.0`
- `sha256`: `e82a8b39015268dba34e2782bb81613e247fa7c7f7e94e402a80309c5b439d97`
- Last touched by `1b5c9f70` (2026-09-19, "seed the five unprovable B25 rows by ADDING instances")
- **Verified byte-identical to the copy bundled in the installed APK**: pulled
  `base.apk` (232,240,791 bytes) off the device, extracted
  `assets/flutter_assets/packages/loom_communities_app_shell/assets/Loom_Communities_Workflow_Engine_GardenClub_Example.jsonc`,
  and its sha256 is the same `e82a8b39…`. So the app under test rendered *this* package, not a stale one.

## The app was on the remote path, from its own telemetry

Not assumed. The app's binding log at launch, before any sign-in:

```
LOOM_BINDING service=workflow-engine mode=remote endpoint=http://192.168.56.10:30083/ \
  scope=ext_garden_club outcome=failure status=- error=authentication_required
```

`mode=remote` with a real endpoint, and `authentication_required` because the session had just been
cleared — which is the correct state for a freshly wiped app, and is itself evidence that the engine
call goes to the service rather than to a local database.

## Control read, taken before any write

```
select workflow_type, count(*) from workflow_instances group by workflow_type;   -- 29 types, all populated
select instance_id, current_state, created_by_fan_id, created_at, updated_at
  from workflow_instances where workflow_type='garden-tool-giveaway';
```

Exactly **one** pre-existing row, `…_zn48lnqz605l`, already terminal (`given`) from a run on
2026-09-20 04:27Z. So the two rows this walkthrough produced are unambiguously new, and an empty
result at any point would have been a real negative rather than a broken query.

Deployed definition confirmed present as a control on the same query shape: seven `garden-*` types in
`workflow_definitions`, `garden-tool-giveaway` at `version 4`, and its stored `claim-giveaway`
transition is identical to the shipped package's — same `allowedRoleIds: ["garden-member"]`, same
`instanceDataEquals availabilityState = available`, same `formula "if(ownerFanId == $actor, false, true)"`,
same two required inputs, same six effects.

## Identity discipline — both stores cleared, and the clearing was PROVEN, not assumed

Before **each** of the two sign-ins: `pm clear com.android.chrome` **and**
`pm clear com.example.loom_communities_demo`.

Proof it worked, rather than a stale SSO cookie silently re-issuing the previous fan's token:

1. Both times, Keycloak served a **real, empty** "Sign in to your account" form at
   `192.168.56.10:30082` — not a silent redirect back with a token.
2. Before selecting the member account, I deliberately tapped **Garden Coordinator 1** as a control.
   The app refused, on screen:

   > Sign-in failed: LoomAuthException(accountNotFound): The authenticated Loom identity cannot sign in
   > as account "fan-garden-coordinator-1". Sign in with that person's identity provider session instead.

   That is the anti-impersonation guard comparing the selected account id against the token's `fanId`.
   It is positive proof the bearer token in hand was **member-1's and not coordinator-1's** — the exact
   failure mode ("the app says you're signed in, as the wrong person") that this check exists to catch.
3. The community header then read **"Signed in as Garden Member 1 / Member"**, and during the create
   leg it had read **"Signed in as Garden Coordinator 1 / Coordinator"**.

`POST_NOTIFICATIONS` was re-granted after each `pm clear` (`pm grant … android.permission.POST_NOTIFICATIONS`)
so no permission dialog could steal focus mid-run.

## Leg 1 — create the listing, as `loom-garden-coordinator-1` / `fan-garden-coordinator-1`

Marketplace tab → `+` FAB → **"Give away a garden item"** (the package's declared create action,
`byRoleIds: ["garden-member", "garden-coordinator"]`, `presentation: "fab"`, `scope: "tab"`).

The form's four required fields were filled as follows. `coordinatorFanId` was **selected, not typed**
— the picker offered real fan ids (`fan-garden-admin`, `fan-garden-coordinator-1/-2`,
`fan-garden-member-1/-2`) with their roles, so no identifier had to be entered by hand.

| Field | Method | Value |
|---|---|---|
| `title` | typed | `B25-Giveaway-Hand-Trowel-Set` |
| `itemDescription` | typed | `Stainless-hand-trowel-set-offered-free-to-a-club-member` |
| `coordinatorFanId` | **selected** | `fan-garden-coordinator-1` |
| `ownerContactInfo` | typed | `coordinator1-at-gardenclub-test` |

**Create tapped 04:51:19.760Z → row written 04:51:21.104Z. Tap→write gap 1,344 ms.**

```
instance_id  community_garden_club_garden-tool-giveaway_4slfkashtavb
current_state  published        created_by_fan_id  fan-garden-coordinator-1
created_at  1789879881104 (2026-09-20T04:51:21.104Z)   updated_at = created_at
```

Stored `instance_data`:

```json
{"mode":"giveaway","title":"B25-Giveaway-Hand-Trowel-Set",
 "ownerFanId":"fan-garden-coordinator-1","conditionState":"good",
 "itemDescription":"Stainless-hand-trowel-set-offered-free-to-a-club-member",
 "coordinatorFanId":"fan-garden-coordinator-1",
 "ownerContactInfo":"coordinator1-at-gardenclub-test","availabilityState":"available"}
```

All four `prefill` values from the package landed: `ownerFanId = $actor`, `mode = giveaway`,
`availabilityState = available`, `conditionState = good`. Note `$actor` resolved to the **real fan id**
`fan-garden-coordinator-1`, not a role-id-shaped string.

## Leg 2 — claim it, as `loom-garden-member-1` / `fan-garden-member-1`

Marketplace → searched `Trowel` → tapped the listing → detail dialog. The dialog rendered
**"Claim giveaway"**, which is the guard passing on all three clauses at once: the actor holds
`garden-member`, `availabilityState == "available"`, and `ownerFanId ("fan-garden-coordinator-1") != $actor`.
The dialog also correctly redacted the owner's contact for a non-claimant viewer
("Owner contact: Protected until ownership handoff").

Both required inputs were typed and then settled against the stored row, not read off the screen:

| Input | Value | Stored length |
|---|---|---|
| `pickupWindow` | `Sunday-1000-to-1400` | 19 ✓ |
| `claimantContactInfo` | `member1-at-gardenclub-test` | 26 ✓ |

**Claim tapped 04:56:52.158Z → row updated 04:56:52.781Z. Tap→write gap 623 ms.**

```
instance_id  community_garden_club_garden-tool-giveaway_4slfkashtavb
current_state  given   (terminal)
created_at  1789879881104   updated_at  1789880212781
updated_at − created_at = 331,677 ms  — a real transition, not a bare insert
```

Stored `instance_data` after the claim:

```json
{"mode":"giveaway","title":"B25-Giveaway-Hand-Trowel-Set",
 "claimedAt":"2026-09-20T04:56:52.781578Z","ownerFanId":"fan-garden-coordinator-1",
 "pickupWindow":"Sunday-1000-to-1400","claimantFanId":"fan-garden-member-1",
 "conditionState":"good",
 "itemDescription":"Stainless-hand-trowel-set-offered-free-to-a-club-member",
 "coordinatorFanId":"fan-garden-coordinator-1",
 "ownerContactInfo":"coordinator1-at-gardenclub-test","availabilityState":null,
 "claimantContactInfo":"member1-at-gardenclub-test"}
```

Every one of the transition's **six** declared effects is accounted for — including the sixth, which is
the one a state check alone would miss:

| Effect | Expected | Stored | |
|---|---|---|---|
| `set availabilityState = null` | `null` | `null` | ✓ |
| `set claimantFanId = $actor` | the claiming fan | `fan-garden-member-1` | ✓ |
| `set pickupWindow = {input.pickupWindow}` | typed input | `Sunday-1000-to-1400` | ✓ |
| `set claimantContactInfo = {input.claimantContactInfo}` | typed input | `member1-at-gardenclub-test` | ✓ |
| `set claimedAt = $timestamp` | equal to `updated_at` | `04:56:52.781578Z` | ✓ exact match |
| `createInstance garden-notification` | a row for the owner | see below | ✓ |

The `createInstance` effect fired, at the same millisecond:

```
community_garden_club_garden-notification_71222n98fuds
current_state       unread
created_at          1789880212781   — identical to the giveaway's updated_at
created_by_fan_id   fan-garden-member-1        (the claimant, who fired the transition)
recipientFanId      fan-garden-coordinator-1   (resolved from {ownerFanId})
title               Giveaway claimed
sourceWorkflowType  garden-tool-giveaway
```

## Where I stopped, and why

**At the terminal state, which is the end of the designed path.** `given` is declared
`isTerminal: true`, and the detail dialog correctly withdrew every action once the instance reached it.
There is nothing further to advance and no second role is required.

The three alternate transitions — `pause-giveaway`, `resume-giveaway`, `delist-giveaway` — were **not**
exercised. All three are `actorEqualsField: ownerFanId` and all three leave `published`, so firing any
of them would have made the row's own primary outcome (`claim-giveaway` into `given`) unreachable on
this instance. They are owner-side alternates to the claim, not steps after it. No role substitution
was made, and in particular `garden-club-admin` was never used in place of `garden-coordinator`.

## Product observation — derived display fields render empty on the post-mutation frame, correct on reload

Reported as an observation, **not** as a diagnosis: I did not trace the mechanism, and the modest
statement is all the evidence supports.

Immediately after the claim, the still-open detail dialog rendered four formula-derived fields with
**empty values** — `Transfer:`, `Claim:`, `Owner contact:` as label-only chips, and
`Claimant contact:` absent (it carries `hideWhenEmpty: true`). The same fields had rendered correctly
one frame earlier ("Transfer: Awaiting claim", "Claim: Not claimed",
"Owner contact: Protected until ownership handoff").

Closing and re-opening the same dialog resolved all four correctly:

- `transferSummary` → **"Transfer: Ownership transferred"**
- `claimantDisplay` → **"Claim: Fan Garden Member 1"** (disclosed because `$viewer == claimantFanId`)
- `ownerContactDisplay` → **"Owner contact: Coordinator1 At Gardenclub Test"** (correctly unlocked for the claimant)
- `claimantContactDisplay` → **"Claimant contact: Member1 At Gardenclub Test"**

So the formulas and their `$viewer` disclosure rules are correct; only the frame rendered in the
moment after the mutation showed them blank. Notably `transferSummary` reads no `$viewer` at all
(`if(claimantFanId == null, 'Awaiting claim', 'Ownership transferred')`) and was blank too, so this is
not a viewer-resolution problem. **What I did not establish:** whether the post-mutation render
re-evaluates formulas at all, or patches `instanceData` without recomputing derived fields. That needs
a code read, not another device run.

User impact is low — the correct values appear on the very next open — but a member who watches their
own claim land sees three fields momentarily lose their text at exactly the moment they are confirming
the handoff details.

## The judge half

Carried by `garden-club-phase-b13-ux-judge-ev31-2026-09-19.md`, which assesses this workflow as its
Row 5 and declares `**Workflow:** \`garden-tool-giveaway\`` in its machine-readable footer. Phase
verdict: **pass-with-findings**.

Two qualifications from that artifact are repeated here so a reader of this manifest meets them too,
rather than only the favourable half:

- It states its own scope limit up front — its frames come from the capture harness, which never runs
  the demo app's `main()`, so it judges **local-engine** rendering and does not certify the shipped app.
- Its Row 5 finding is that **no giveaway item was in frame** (both visible cards were `Mode: Loan`),
  so the row's own subject was unevidenced in the judged pixels.

**This walkthrough is the part that closes that gap on the remote path**: the giveaway instance was
created, rendered, claimed and driven to its terminal state against the real backend, and every claim
above is the stored Postgres row rather than a screen reading.

## What I could not do

- **Screenshots are not durable.** `*.png` is gitignored, so the 42 frames captured during this run are
  transient; this manifest is the durable artifact, and every state claim in it is backed by a Postgres
  read taken in the same session rather than by a pixel.
- **The tap→write gaps are wall-clock, not a trace.** They bound the latency between the input event
  and the committed row; they do not establish which layer spent the time.
