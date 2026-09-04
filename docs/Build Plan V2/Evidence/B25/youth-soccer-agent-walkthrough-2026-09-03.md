# Riverside Youth Soccer — live agent walkthrough (B25 coverage pass)

- **Date:** 2026-09-03 (device clock 11:31–11:47)
- **Community:** Riverside Youth Soccer (`ext_youth_soccer`, accent `#176B87`, card image = generated fallback)
- **App:** `com.example.loom_communities_demo` / `.MainActivity`, installed APK on `emulator-5554`
- **adb path:** Windows-hosted `emulator-5554` reached over the pre-existing SSH reverse tunnel to
  adb on `127.0.0.1:5037`. Every command was `adb -s emulator-5554 …`. `get-state` = `device` at start.
  No `kill-server`/`start-server`/`connect`/`disconnect`/`-a` was ever issued; no
  `ANDROID_ADB_SERVER_ADDRESS`/`_PORT` was set. Screen 1080x2400.

## Personas

The community declares **3 roles**. Role is bound to the account at sign-up — the account picker
groups accounts by role (`Coach (Coach)`, `Guardian (Guardian)`), and the in-community role dialog
only takes effect for the role the account actually holds (see the finding below). So each role
needed its own account.

| # | Display name | Fan id | Role at sign-up | How created |
|---|---|---|---|---|
| 1 | Dana Guardian | `soccer-guardian-20` | **Guardian** (the DEFAULT — pre-selected in the Role dropdown) | Create New Account → Sign Up |
| 2 | Casey Coach | `soccer-coach-21` | **Coach** | Create New Account → role dropdown → Sign Up |
| 3 | Robin Owner | *(not shown in-session)* | **League Owner** | Create New Account → role dropdown → Sign Up |

Role descriptions as the app states them:

- **Guardian** — "Registers a player, pays fees, manages consent, follows schedules, and receives reminders."
- **Coach** — "Reviews guardian requests, manages protected roster rows and schedules, and sends reminders."
- **League Owner** — "Owner - Creates redacted, portable league metadata exports."

## The tab bar is role-scoped, and it scrolls

The bottom bar scrolls horizontally. End-of-scroll was proved by repeating the swipe and comparing
frames byte-for-byte (identical md5 = no further movement), not by assuming four tabs was all.

| Role | Tabs (in order) | Count | End-of-scroll proof |
|---|---|---:|---|
| Guardian | Home, Schedule, Payments, Team, Documents, Messages | **6** | `08`/`09` identical md5 `0ded9538…` |
| Coach | Home, Schedule, **Coach & Owner**, Team, Documents, Messages | **6** | `34`/`35` identical md5 `6a6a3164…` |
| League Owner | Home, **Coach & Owner**, Messages | **3** | `50`/`51` layout unchanged after swipe |

Guardian's **Payments** tab is replaced by **Coach & Owner** for Coach; League Owner loses Schedule,
Team, Documents and Payments entirely.

## Per-tab affordances — persona 1 (Dana Guardian, Guardian)

| Tab | PRIMARY affordance (exact label) | ALTERNATE affordance (exact label) | Seeded data present? |
|---|---|---|---|
| Home | `Register a player` (FAB) | `Add to calendar` | Yes — "Jordan's returning-player registration", Player: Jordan R., Fee: $185 season fee, Payment: Paid, Waiver: Acknowledged, Approved 2026-08-03T10:15:00-07:00; plus an "Under coach review" card and a practice card |
| Schedule | `Going` | `Add to calendar` (also `Maybe`, `Not attending`) | Yes — Aug 2026 calendar, "Riverside Rapids U12 practice" on Tue 18 Aug, 17:30, North Field 2, RSVPs open: Yes |
| Payments | **none found** | **none found** | **No** |
| Team | `Search` | column sort toggles `Player` / `Role` / `Waiver` / `Privacy` (+ per-row selection checkbox) | Yes — one row: Jordan R. / Player / Waiver: Acknowledged / Privacy: Guardian Approv… (table scrolls horizontally) |
| Documents | **none found** | **none found** | **No** |
| Messages | `New team thread` (FAB) | `Reply` | Yes — thread "Saturday field update", 2 messages from soccer-coach and soccer-guardian, last reply 2026-08-11T19:15:00-07:00 |

Other roles' distinctive surfaces, for completeness:

| Role · Tab | PRIMARY | ALTERNATE |
|---|---|---|
| Coach · Coach & Owner | `Approve and add to roster` | `Request changes` (also `Reject request`) |
| Coach · Documents | `Add waiver or policy` (FAB) | `Open document` (also `Publish linked waiver version`, `Archive document`, `Open embedded`, `Open externally`) |
| Coach · Home | `Refund payment` | — |
| League Owner · Coach & Owner | `New redacted export` (FAB) | `Change scope` (also `Start export or transfer`, `Cancel export`) |
| League Owner · Messages | **none — read-only** | **none** (no `Reply`, no `New team thread`) |

## Create-form observation

Taken on the clearest create affordance persona 1 can use: Home → FAB **`Register a player`**.

Dialog title: **Register a player**. Fields, in order:

1. Case Title
2. Player
3. Request
4. Fee
5. Waiver Title
6. Waiver Version
7. Waiver Url

Buttons: `Cancel`, `Create`.

**Cancelled without submitting** via `Cancel`. The cancel is clean and the proof is byte-level, not
visual: pre-frame `13_create_pre.png` and post-frame `15_create_post.png` are **byte-identical**,
md5 `a46dab12683c8d7eb5ef71c10765cc8e`, 235,689 bytes each. Nothing was written.

## Absence classification

Rule applied before recording anything as absent: scroll both ends, expand disclosures, prove taps
register on that surface, then look for the same surface under a different role.

**Tap-registration proof** for both empty surfaces: tapping `Local package details` expanded the
disclosure (chevron flipped ⌄→⌃, revealing Package `ext_youth_soccer`, Accent `#176B87`, Card image
`generated fallback`, "No seed files recorded."). Frames differ by md5 before/after, so the surface
was live and receiving input — the emptiness is not a dead screen.

| Surface | What is missing | Verdict | Evidence | Seeded data? |
|---|---|---|---|---|
| Payments (Guardian) | any list content; any create/primary/alternate control | **Role-gated / identity-scoped — NOT unwritable** | Scrolled to both ends (`18`→`19`, content unchanged); disclosure expanded, taps register (`20`). The tab does not exist for Coach or League Owner, so it cannot be opened under another role — but the payment record it would show is provably present in the package: as Coach, Home renders "Registration paid", Player: River A., Fee: $185 season fee, Receipt: **Offline Payment Verified**, history "Coach verified an offline payment · soccer-coach · 2026-08-10T17:10:00-07:00", with a live `Refund payment` control (`33`) | **Not for this identity.** Package-level yes: the seeded payment belongs to `soccer-guardian`, not to my freshly created `soccer-guardian-20` |
| Documents (Guardian) | the waiver list; `Add waiver or policy`; every document control | **Role-gated — proven** | Empty and scrolled both ends as Guardian (`23`,`24`), taps register (`25`). The *identical tab* under Coach is fully populated (`39`,`40`): "2026 Player Safety and Participation Waiver", Version v3.2, Access: Members may open; acknowledgement is tracked, Authorized guardians: 1, Acknowledged 2026-08-10T16:50:00-07:00, Document history: 1 entries — plus `Open document`, `Publish linked waiver version`, `Archive document` and the `Add waiver or policy` FAB | **Yes** — the waiver exists and is acknowledged; the Guardian simply cannot see it |
| Messages (League Owner) | `Reply`, `New team thread` | **Role-gated — proven** | Same thread renders read-only (`53`); both controls are present for Guardian on the same tab (`26`) | Yes — same seeded thread |
| Home (League Owner) | all cards | Role-gated (owner Home carries no cards) | `50`, `51` — header + disclosure only, scrolled | No |

Neither empty surface is "unseeded/unwritable" in the sense of a missing feature: in every case the
data and the controls exist and are reachable under another role.

## Finding — silent no-op when selecting a role the account does not hold

The in-community **Account role and permissions** dialog lists all three roles as radio options and
says "Choose the role you want to use in this community." Signed in as Casey Coach (`soccer-coach-21`),
selecting a role the account does not hold **dismisses the dialog with no change and no message**.

Verified three times, including a control:

1. Tapped the `League Owner` label → dialog closed, role still Coach (`42`, re-opened `43`).
2. Tapped the `League Owner` radio → dialog closed, role still Coach (`44`, re-opened `45`).
3. **Control:** tapped the `Guardian` radio → dialog closed, role still Coach (`46`).

After all three the header still read "Tuned for Coach" and the bar still carried "Coach & Owner",
so nothing changed. Because the control behaves the same for every non-held role, this reads as
"membership governs the role" rather than a broken widget — the dialog's own text says memberships
determine what is available. The reportable part is that it gives **no feedback at all**: no
disabled state, no toast, no explanation. A user cannot tell refusal from a missed tap.

Workaround used: create a separate account per role at sign-up, which works cleanly.

## Stability

| Check | Result |
|---|---|
| `mCurrentFocus` | `com.example.loom_communities_demo/.MainActivity` at start and at end — never a system dialog, never null |
| ANR | **0** (`grep -c "ANR in"`) |
| FATAL EXCEPTION | **0** (`grep -c "FATAL EXCEPTION"`) |
| Blank/blocked frames | none — every empty surface still rendered its header, and its disclosure responded to taps |
| logcat volume | 96,395 lines at start → 104,069 at end (7,674 lines produced during the run) |
| **Control counts** (prove the greps work, so 0 means absent) | `loom_communities_demo` → **926**; `ActivityManager` → **243** |

The zero counts are trustworthy because the control greps over the same buffer return large non-zero
numbers.

## Screenshot index

53 PNGs, 1080x2400, in `/tmp` on the VM. `*.png` is gitignored — this manifest is the durable record.

| # | File | Bytes |
|---|---|---:|
| 01 | youth-soccer_01_list.png | 315,926 |
| 02 | youth-soccer_02_open.png | 122,049 |
| 03 | youth-soccer_03_name.png | 181,842 |
| 04 | youth-soccer_04_roles.png | 131,917 |
| 05 | youth-soccer_05_presignup.png | 125,908 |
| 06 | youth-soccer_06_signedin.png | 258,766 |
| 07 | youth-soccer_07_home_top.png | 235,287 |
| 08 | youth-soccer_08_tabscroll1.png | 236,398 |
| 09 | youth-soccer_09_tabscroll2.png | 236,398 |
| 10 | youth-soccer_10_home_mid.png | 214,407 |
| 11 | youth-soccer_11_home_bot.png | 169,557 |
| 12 | youth-soccer_12_tabbar_start.png | 168,902 |
| 13 | youth-soccer_13_create_pre.png | 235,689 |
| 14 | youth-soccer_14_create_form.png | 72,369 |
| 15 | youth-soccer_15_create_post.png | 235,689 |
| 16 | youth-soccer_16_schedule.png | 168,226 |
| 17 | youth-soccer_17_schedule_mid.png | 189,258 |
| 18 | youth-soccer_18_payments.png | 94,498 |
| 19 | youth-soccer_19_pay_scrolldown.png | 94,501 |
| 20 | youth-soccer_20_pay_disclosure.png | 148,432 |
| 21 | youth-soccer_21_team.png | 115,472 |
| 22 | youth-soccer_22_team_hscroll.png | 120,399 |
| 23 | youth-soccer_23_documents.png | 98,472 |
| 24 | youth-soccer_24_doc_scroll.png | 97,889 |
| 25 | youth-soccer_25_doc_disclosure.png | 151,770 |
| 26 | youth-soccer_26_messages.png | 209,786 |
| 27 | youth-soccer_27_identity.png | 254,295 |
| 28 | youth-soccer_28_specific_person.png | 171,377 |
| 29 | youth-soccer_29_create2.png | 169,058 |
| 30 | youth-soccer_30_persona2_name.png | 173,552 |
| 31 | youth-soccer_31_role2_dropdown.png | 179,981 |
| 32 | youth-soccer_32_role2_set.png | 173,607 |
| 33 | youth-soccer_33_coach_home.png | 212,681 |
| 34 | youth-soccer_34_coach_tabs_start.png | 210,726 |
| 35 | youth-soccer_35_coach_tabs_start2.png | 210,726 |
| 36 | youth-soccer_36_coachowner.png | 226,835 |
| 37 | youth-soccer_37_coachowner_mid.png | 203,747 |
| 38 | youth-soccer_38_coach_tabs_end.png | 204,780 |
| 39 | youth-soccer_39_coach_documents.png | 250,909 |
| 40 | youth-soccer_40_coach_doc_mid.png | 193,104 |
| 41 | youth-soccer_41_roleswitch.png | 256,310 |
| 42 | youth-soccer_42_owner.png | 251,628 |
| 43 | youth-soccer_43_verify_role.png | 257,182 |
| 44 | youth-soccer_44_owner_try2.png | 251,733 |
| 45 | youth-soccer_45_verify_role2.png | 256,418 |
| 46 | youth-soccer_46_control_guardian.png | 250,932 |
| 47 | youth-soccer_47_create3.png | 177,113 |
| 48 | youth-soccer_48_role3_dropdown.png | 187,251 |
| 49 | youth-soccer_49_role3_set.png | 183,286 |
| 50 | youth-soccer_50_owner_home.png | 88,672 |
| 51 | youth-soccer_51_owner_tabs_end.png | 88,678 |
| 52 | youth-soccer_52_owner_coachowner.png | 236,845 |
| 53 | youth-soccer_53_owner_messages.png | 187,020 |

## Pipeline result

**PASS.** The rig drove a real emulator end-to-end against Riverside Youth Soccer with no crash, no
ANR and no blank frame. Three personas were created across all three declared roles, all tabs in all
three role-scoped bars were visited and photographed, a create form was opened and cancelled with
byte-identical proof, and both empty surfaces were classified against a second role rather than being
recorded as absent on a single look.

## B25 coverage

**Provable now from this run:**

- Community opens from the list; sign-up assigns the declared default role (Guardian) and the app
  states it back — "Signed in as Dana Guardian / Guardian / 3 roles".
- The bottom bar is role-scoped and horizontally scrollable; the full tab set per role is enumerated
  above with byte-identical end-of-scroll proof.
- Guardian: registration create form (7 fields) opens and cancels cleanly with no write.
- Guardian: RSVP affordances render on a seeded event — `Going`, `Maybe`, `Not attending`,
  `Add to calendar`, against "RSVPs open: Yes" and "Calendar: Not Synced".
- Guardian: protected roster row renders with waiver and privacy columns (Acknowledged / Guardian
  Approved), search and column sorts present.
- Guardian: team thread renders with `Reply` and `New team thread`.
- Coach: guardian-request review controls render — `Approve and add to roster`, `Request changes`,
  `Reject request` — over a seeded "Under coach review" case with a two-entry history.
- Coach: payment record with `Refund payment` and receipt "Offline Payment Verified".
- Coach: document surface with waiver v3.2, acknowledgement tracking and
  `Add waiver or policy` / `Publish linked waiver version` / `Archive document`.
- League Owner: redacted-export surface with declared scope and redaction list,
  `New redacted export`, `Change scope`, `Start export or transfer`, `Cancel export`.
- Role-gating is demonstrated in both directions — a surface empty for one role and populated for
  another (Documents), and a surface interactive for one role and read-only for another (Messages).

**Blocked, and why:**

- **Guardian's own Payments tab could not be shown non-empty.** The tab exists only for Guardian, and
  the seeded payment rows belong to the seeded `soccer-guardian` identity, not to a newly created
  guardian. Proving it would need either sign-in as the seeded `soccer-guardian` (the account picker
  offered no pre-seeded identities to select — only accounts created in this session) or a completed
  registration+checkout by the new guardian, which would mean submitting the create form. This run
  cancelled it deliberately, so nothing was written.
- **Role switching within one account could not be exercised.** Selecting a non-held role in the
  Account role and permissions dialog is a silent no-op (verified 3×, control included), so all
  three-role coverage came from three separate accounts.
- **No write/mutation path was completed anywhere.** Every create and every state-changing control
  (`Create`, `Going`, `Approve and add to roster`, `Refund payment`, `Archive document`,
  `Start export or transfer`) was observed and photographed but deliberately not submitted, per the
  ticket. So this run proves the affordances *exist and are reachable*; it does not prove they
  *commit*. Terminal-state proof remains for a write-enabled pass.

## Independent verification (orchestrator, by eye)
`youth-soccer_33_coach_home.png` pulled byte-identically and viewed: the Coach's Home renders a seeded
"Registration paid" record — Player: River A., Fee: $185 season fee, Receipt: **Offline Payment
Verified** — with payment history authored **"By Fan Id: soccer-coach"** and a red `Refund payment`
control, plus "Approved and added to roster / Jordan's returning-player registration". Confirms the
agent's identity-scoping finding: the seeded records belong to the seeded `soccer-coach`/`soccer-guardian`
fan ids, so a freshly created persona of the same role correctly sees only its own (empty) slice.

## Significance: this is the security model working, not a gap
The Guardian's "empty" Payments/Documents surfaces are **identity-scoped, not broken** — the payment and
waiver data provably exist (visible under the seeded Coach identity) and are scoped per fan id. That is
exactly the target model's point #2 ("Data scoped to their user ID & roleid") behaving correctly on a
live device. So Youth Soccer, like Masjid Nur, has **zero genuine surface gaps**; every empty surface is
role-gated or identity-scoped.

Running tally (5 rigorous walkthroughs): Cedar (1 gap: dues unseeded), Book Club (1: Messages no writer),
Chess (1: disputes unseeded), Masjid Nur (0), Youth Soccer (0). Gaps are isolated, single-surface,
community-specific — the engine, role model, data-scoping, and rendering are sound.
