# Camera Club — live Android walkthrough (B25 coverage pass)

- **Date:** run 2026-09-04 04:23–04:46 PDT (device clock `Fri Sep 4 04:46:27 PDT 2026`).
  Filed under the ticket's `-2026-09-03` filename to sit with the rest of the B25 walkthrough series;
  the run date above is the real one.
- **Community:** Camera Club (`ext_camera_club`, accent `#37474F`, card image `generated fallback`,
  *No seed files recorded*)
- **Device:** `emulator-5554`, 1080x2400, `com.example.loom_communities_demo/.MainActivity`
- **adb path:** Windows-hosted emulator reached over an SSH reverse tunnel to adb on `127.0.0.1:5037`.
  Every command issued as `adb -s emulator-5554 …`. `get-state` = `device` at start **and** at end.
  No `kill-server` / `start-server` / `connect` / `disconnect` / `-a`; `ANDROID_ADB_SERVER_ADDRESS`
  and `ANDROID_ADB_SERVER_PORT` never set. Tunnel intact for the whole run.
- **Mode:** local package rendering. The *Local package details* disclosure reports
  *"No seed files recorded"* — no backend attached.

## Personas

Both created in-app through **Create New Account**. The Camera Club sign-up gate offers exactly two roles;
**Organizer is the pre-selected default**, so persona 1 accepted Organizer as instructed.

| # | Display name | Account ID | Role assigned | How created |
|---|---|---|---|---|
| 1 | Ansel Walkthrough | `camera-club-organizer-20` | **Organizer** (accepted the default) | sign-up gate on entering the community |
| 2 | Robin Member | `camera-club-member-21` | **Member** (role dropdown → Member) | AppBar identity picker → *Sign in as a specific person…* → Create New Account |

Role descriptions as shown in-app:
- **Organizer** — "Organizer - Schedules photo walks, reviews critiques, publishes announcements, and oversees gear custody."
- **Member** — "Member - Joins photo walks, submits critiques, and lists, borrows, queues for, claims, or returns gear."

**The in-app role switcher does not switch role.** The AppBar people icon opens *Account role and
permissions* with an Organizer/Member radio. Selecting **Member** on persona 1 closed the dialog and left
the role at Organizer — twice, on two different hit targets (the radio at `(240,1463)` and the row text at
`(550,1500)`); reopening the dialog showed Organizer still selected. Consistent with the dialog's own
wording ("Your memberships determine which community actions are available") — the account holds only an
Organizer membership. Persona 2 therefore had to be created through the sign-up form, not switched into.
Recorded as an observation, not a defect: no doc consulted in this run promises cross-role switching.

**The seeded identities are not sign-in-able.** The identity picker's *Existing Accounts* listed only the
accounts created during this run. `camera-club-member` and `camera-club-organizer` — the fan ids that own
every seeded record — are never offered. *Pending & Invites* read "No accounts are waiting for approval"
and "No invite-only roles are declared." This is load-bearing for the absence table below.

## Tab set

The bottom tab bar **does** scroll horizontally. Swiping left from the initial four revealed two more; a
repeat swipe produced a **byte-identical frame** (`md5sum` equal on
`camera-club_08_tabs_scroll1.png` / `camera-club_09_tabs_scroll2.png`), which is how the end of the bar was
confirmed rather than assumed. Had I stopped at the visible four, **Admin and Messages would both have been
missed**.

- **Organizer — 6 tabs:** Home, Walks, Critique, Gear, **Admin**, Messages
- **Member — 5 tabs:** Home, Walks, Critique, Gear, Messages (**no Admin**)

Cross-checked against the shipped package (`docs/references/communities/Loom_Communities_Workflow_Engine_CameraClub_Example.jsonc`,
read-only), which declares **five** tabs — `home`, `calendar`→Walks, `critique`, `marketplace`→Gear, `admin` —
and gates the last one explicitly:

```jsonc
{ "tabId": "admin", "label": "Admin", "visibleRoleIds": ["camera-club-organizer"], … }
```

**Messages is not declared by the package at all** (control grep: `message` occurs **0** times in the Camera
Club package, against `critique` = 27 in the same file, so the grep works). It is a platform-injected surface.
6 = 5 declared + Messages; 5 = 4 declared visible + Messages. Both counts reconcile exactly.

## Per-tab affordances — persona 1 (Ansel Walkthrough, Organizer)

| Tab | Primary affordance (exact label) | Alternate affordance (exact label) | Screenshot |
|---|---|---|---|
| Home | `New announcement` (extended FAB) | `Review completion` (also `Request loan`, `Report damage`, `Join queue`, `Cancel walk`, `Archive announcement`) | `camera-club_07_home.png`, `camera-club_10_home_a.png`, `camera-club_11_home_b.png`, `camera-club_14_home_end.png` |
| Walks | `New photo walk` (extended FAB) | `Going` (also `Maybe`, `Not attending`, `Add reminder`, `Cancel walk`, `Event cancelled`) | `camera-club_16_walks.png`, `camera-club_18_walks_c.png` |
| Critique | `New critique` (extended FAB) | **not found — see absence table** | `camera-club_22_critique.png`, `camera-club_24_critique_disclosure.png` |
| Gear | `List gear` (extended FAB) | `Search available items` (also `Request loan`, `Report damage`, `Claim giveaway`) | `camera-club_25_gear.png`, `camera-club_26_gear_b.png` |
| Admin | `Review completion` (inline filled button; **this tab has no FAB**) | `Claim giveaway` (also `Report damage`) | `camera-club_27_admin.png`, `camera-club_30_admin_end.png` |
| Messages | **not found — see absence table** | **not found — see absence table** | `camera-club_31_messages.png`, `camera-club_47_messages_top_org.png` |

**Primary/alternate was found on 4 of 6 tabs.** Critique yielded a primary but no alternate; Messages yielded
neither. Both are classified with evidence below rather than recorded as bare absences.

## Per-tab affordances — persona 2 (Robin Member, Member)

| Tab | Primary affordance (exact label) | Alternate affordance (exact label) | Screenshot |
|---|---|---|---|
| Home | **no FAB** — primary is inline `Return gear` | `Join queue` (also `Report damage`, `Report lost`) | `camera-club_46_p2home.png`, `camera-club_53_p2home_actions.png` |
| Walks | `Going` (**no `New photo walk` FAB**) | `Maybe` (also `Not attending`, `Add reminder`) | `camera-club_50_p2walks.png`, `camera-club_51_p2walks_actions.png` |
| Critique | `New critique` (extended FAB) | **not found** | `camera-club_43_p2critique.png` |
| Gear | `List gear` (extended FAB) | `Search available items` | `camera-club_52_p2gear.png` |
| Messages | **not found** | **not found** | `camera-club_45_p2messages.png` |

Role-gated affordances confirmed by direct comparison, not inference:
`New announcement` (Home FAB), `New photo walk` (Walks FAB), `Cancel walk`, `Event cancelled` and the
editable walk form with `Save changes` are all **present under Organizer and absent under Member**.
`List gear` is present under both, matching the Member role text ("lists, borrows, queues for, claims, or
returns gear"). Member's Walks also surfaces a capacity meter Organizer's Home did not show at that
position — `1 / 12 going`, `11 seats left`.

## Create-form observation — Walks → `New photo walk`

Chosen as the clearest labelled create persona 1 can use.

Dialog title **New photo walk**. Eight fields, in order:

| # | Field label as rendered |
|---|---|
| 1 | `Title` |
| 2 | `Route` |
| 3 | `Event Date` |
| 4 | `Event Time` |
| 5 | `Location` |
| 6 | `Led by` |
| 7 | **`spots`** — bare lowercase key, see rendering bugs |
| 8 | `Weather Checklist Notes` |

Buttons: `Cancel` and `Create`. **Nothing was submitted.**

**Cancel verified clean, pixel-exactly.** Pre-frame captured immediately before tapping the FAB, post-frame
immediately after `Cancel`, compared below the status bar (rows 110–2400) to exclude the clock:

```
ImageChops.difference(pre, post).getbbox()  →  None
```

`None` means zero differing pixels across the whole content area — the create dialog left no residue and
did not disturb scroll position. (`camera-club_19_create_pre.png` 173747 B vs
`camera-club_21_create_post.png` 173760 B — the 13-byte delta is the status-bar clock, which the crop excludes.)

## Absence classification

Every row below was scrolled to both ends, had its disclosure expanded, and had tap-registration proven by a
control **before** anything was recorded as absent.

| Surface | What is missing | Verdict | Evidence | Seeded data? |
|---|---|---|---|---|
| **Critique tab** (both roles) | any critique record; no alternate affordance | **identity-scoped** | Package holds **two** `critique-submission` instances — `critique-lighthouse-portrait` (state `submitted`) and `critique-night-market-reflections` (state `reviewed`) — both `createdByFanId: camera-club-member`. Both **render correctly on the Admin tab** under Organizer (`camera-club_27_admin.png`, `camera-club_28_admin_b.png`), so the data is loaded in the engine, not missing. The Critique tab is nonetheless empty for `camera-club-organizer-20` **and** for `camera-club-member-21` — a freshly-created persona of the *same role as the seeded author*. The seeded `camera-club-member` identity is not offered by the identity picker, so its view cannot be reached. Tab is not scrollable (`getbbox()` → `None` after 3 swipes) and taps register (disclosure expanded, bbox `(42,1297,1038,1838)`). | **Yes** — 2 records, both under a fan id no persona can sign in as |
| **Messages tab** (both roles) | message list, compose control, any affordance | **unseeded / unwritable** | Empty under Organizer *and* Member. Scrolled both directions: down `getbbox()` → `None` (already at end), up revealed only the community header. Disclosure expanded. Control grep on the package: `message` occurs **0** times (control `critique` = 27 in the same file). The package declares **no** messages tab and no messaging workflow — Messages is a platform surface this package never populates. **Cross-community positive control:** the Chess Club package contains **33** `message` occurrences and declares a `messages` tab, and its Messages tab renders content with a `New thread` FAB — so the platform surface demonstrably works when a package feeds it. | **No** — nothing declared or seeded |
| **Admin tab** (Member) | the entire tab | **role-gated** | Organizer sees 6 tabs, Member sees 5; Admin is the only difference. Package declares `"visibleRoleIds": ["camera-club-organizer"]` on that tab. | n/a |
| **Home `New announcement` FAB** (Member) | the create FAB | **role-gated** | Present for Organizer (`camera-club_07_home.png`), absent for Member (`camera-club_46_p2home.png`); matches "publishes announcements" appearing only in the Organizer role text. | n/a |
| **Walks `New photo walk` FAB, `Cancel walk`, `Event cancelled`, `Save changes`** (Member) | create + lifecycle controls | **role-gated** | Present for Organizer (`camera-club_18_walks_c.png`), absent for Member (`camera-club_51_p2walks_actions.png`); matches "Schedules photo walks" appearing only in the Organizer role text. | n/a |

**Note on the Critique verdict.** My first pass at this nearly recorded "no seeded critique exists" — a
title-based grep over the package returned walk, gear and announcement titles and no critique, because
critique instances key their headline on `photoTitle`, not `title`. A control grep for the bare string
`critique` returned 27 hits and overturned it. The narrow query was the broken instrument, exactly the
failure mode the working rules warn about; the absence was not real.

## Rendering bugs

Five, all reproducible and all visible without leaving the default surfaces.

1. **Bare camelCase chips rendered with no value.** A chip shows the raw key where the value should be:
   - `requestedCount` and `implementedCount` — Home and Admin (`camera-club_10_home_a.png`,
     `camera-club_27_admin.png`). Damning detail: they sit **directly beneath** `3 requested workflows` and
     `3 implemented workflows`, which render the *same* numbers correctly. So the surface prints each count
     twice — once formatted, once as a bare key with the value dropped.
   - `weatherChecklistNotes` — Walks and Home (`camera-club_17_walks_b.png`,
     `camera-club_53_p2home_actions.png`). The value is not missing: the same screen renders
     `Weather Checklist Notes` with the full text a few rows down.
   - `photoImage` — Admin, on both critique cards (`camera-club_27_admin.png`,
     `camera-club_28_admin_b.png`). Underlying value is `seed://photos/lighthouse-dusk.jpg`.
2. **`spots` renders as a bare lowercase key in a field label**, among siblings that are all correctly
   title-cased (`Route`, `Event Date`, `Event Time`, `Location`, `Led by`, `Weather Checklist Notes`).
   Appears in the read view (`camera-club_12_home_c.png`) **and in the `New photo walk` create form**
   (`camera-club_20_create_form.png`), where an author has to understand the field to fill it in.
   The package's own key is `capacity`, so this is not even the source field name.
3. **Raw fan ids surfaced as human names.** The Walks RSVP roster lists `• camera-club-member` and
   `• camera-club-organizer` under `Maybe` / `Going` (`camera-club_17_walks_b.png`), and the critique
   comment header on Admin reads `camera-club-organizer` (`camera-club_28_admin_b.png`) — while a chip on
   the *same card* correctly renders `By Camera Club Member`. So the humanised form exists and is not used
   consistently.
4. **`Local package details` disclosure header is near-invisible** — very light text on a light background,
   on every tab (clearest in `camera-club_26_gear_b.png`). The chevron and the expanded content render at
   normal contrast; only the header label is affected.
5. **Pluralisation not applied:** `1 comments` on the Admin critique card (`camera-club_28_admin_b.png`).

Also observed, reported as cosmetic rather than defects: the `New announcement` / `List gear` FABs overlap
card content while scrolling (content remains reachable by scrolling), and long values truncate with `…`
(`Route: Battery Spencer to Kirby Cove…`), which appears intentional.

## Stability

No crash, no ANR, no blank frame, no system dialog at any point.

| Check | Result | Control |
|---|---|---|
| `mCurrentFocus` | `com.example.loom_communities_demo/.MainActivity` at start and at end — never lost focus | — |
| `FATAL EXCEPTION` | **0** | total logcat lines = **122385**; lines mentioning `loom_communities_demo` = **1243** |
| `ANR in` | **0** | as above |
| `E/flutter` | **0** | lines matching `flutter` (case-insensitive) = **423** |
| `Unhandled Exception` | **0** | as above |
| `RenderFlex` / `overflowed by` | **0** / **0** | as above |

All counts taken with `grep -ac` (always exits 0, prints one number, `-a` because dispatch/logcat output can
read as binary) — the failure mode where `grep -c … || echo 0` yields `"00"` cannot occur here. Every zero
above is paired with a non-zero control from the same command, so a zero means "absent", not "grep broken".

## Screenshot index

Captured to `/tmp` on the agent host. `*.png` is gitignored — these are transient; this manifest is the
durable record. All 1080x2400.

| # | File | Bytes | What it shows |
|---|---|---:|---|
| 01 | camera-club_01_list.png | 316795 | community list "Loom Communities", 10 loaded |
| 02 | camera-club_02_list_scroll.png | 291902 | Camera Club card in view |
| 03 | camera-club_03_open.png | 120785 | sign-up gate; default role Organizer; Existing Accounts empty |
| 04 | camera-club_04_name.png | 188339 | display name "Ansel Walkthrough" entered |
| 05 | camera-club_05_roles.png | 128386 | role dropdown: **Organizer / Member** (two only) |
| 06 | camera-club_06_predismiss.png | 126722 | dropdown dismissed, Organizer retained |
| 07 | camera-club_07_home.png | 235771 | Home as Organizer; `New announcement` FAB; "2 roles" |
| 08 | camera-club_08_tabs_scroll1.png | 236044 | tab bar scrolled — Critique, Gear, **Admin**, **Messages** |
| 09 | camera-club_09_tabs_scroll2.png | 236044 | byte-identical to 08 = end of bar |
| 10 | camera-club_10_home_a.png | 210474 | completion card; **`requestedCount` / `implementedCount` bare chips** |
| 11 | camera-club_11_home_b.png | 197125 | gear cards; `Request loan`, `Report damage`, `Join queue` |
| 12 | camera-club_12_home_c.png | 191421 | editable walk form; **`spots` bare label**; `Cancel walk` |
| 13 | camera-club_13_home_d.png | 191094 | announcement card; `Archive announcement` |
| 14 | camera-club_14_home_end.png | 191094 | identical to 13 = end of Home |
| 15 | camera-club_15_tabbar_home.png | 190483 | tab bar back at start: Home, Walks, Critique, Gear |
| 16 | camera-club_16_walks.png | 233374 | Walks: Day/Week/Month/Pending, Sep 2026 calendar, `New photo walk` FAB |
| 17 | camera-club_17_walks_b.png | 196515 | **`weatherChecklistNotes` bare chip**; **raw fan ids in RSVP roster** |
| 18 | camera-club_18_walks_c.png | 173746 | RSVP actions: `Going`/`Maybe`/`Not attending`/`Add reminder`/`Cancel walk`/`Event cancelled` |
| 19 | camera-club_19_create_pre.png | 173747 | pre-frame for the cancel-clean comparison |
| 20 | camera-club_20_create_form.png | 72014 | **`New photo walk` create form**, 8 fields, `Cancel`/`Create` |
| 21 | camera-club_21_create_post.png | 173760 | post-Cancel; pixel-identical to 19 below the status bar |
| 22 | camera-club_22_critique.png | 193869 | Critique tab **empty** (Organizer); `New critique` FAB |
| 23 | camera-club_23_critique_bottom.png | 193615 | after 3 swipes — surface does not scroll |
| 24 | camera-club_24_critique_disclosure.png | 219845 | disclosure expanded → taps register; `ext_camera_club`, `#37474F` |
| 25 | camera-club_25_gear.png | 243730 | Gear: `Search available items`, 2-column grid, `List gear` FAB |
| 26 | camera-club_26_gear_b.png | 147667 | 3rd gear item; **faint `Local package details` header** |
| 27 | camera-club_27_admin.png | 192892 | Admin (Organizer only); **seeded critique "Lighthouse at dusk" renders here**; `photoImage` bare chip |
| 28 | camera-club_28_admin_b.png | 214613 | 2nd critique "Night market reflections"; **raw `camera-club-organizer` comment author**; **`1 comments`** |
| 29 | camera-club_29_admin_c.png | 133565 | Admin bottom: `Claim giveaway`, `Report damage` |
| 30 | camera-club_30_admin_end.png | 133565 | identical to 29 = end of Admin |
| 31 | camera-club_31_messages.png | 147549 | Messages tab **empty**, no compose control |
| 32 | camera-club_32_appbar_chat.png | 203454 | AppBar chat icon tapped — **frame unchanged** |
| 33 | camera-club_33_appbar_people.png | 245611 | **control**: people icon opens *Account role and permissions*; ID `camera-club-organizer-20` |
| 34 | camera-club_34_member_switch.png | 203532 | after selecting Member — banner still reads Organizer |
| 35 | camera-club_35_roledlg2.png | 246464 | dialog reopened — Organizer still selected |
| 36 | camera-club_36_after_member_tap.png | 204130 | second attempt on the row text — still Organizer |
| 37 | camera-club_37_specific_person.png | 178893 | identity picker; **seeded ids absent**; Pending & Invites empty |
| 38 | camera-club_38_p2form.png | 177922 | Create New Account form reached |
| 39 | camera-club_39_p2name.png | 181738 | "Robin Member" entered |
| 40 | camera-club_40_p2roles.png | 182992 | role dropdown open for persona 2 |
| 41 | camera-club_41_p2member.png | 180165 | role set to **Member** |
| 42 | camera-club_42_p2home.png | 225652 | signed in as Robin Member / Member |
| 43 | camera-club_43_p2critique.png | 218350 | **Critique still empty for a Member persona** — the identity-scoped proof |
| 44 | camera-club_44_p2id.png | 246086 | persona 2 ID **`camera-club-member-21`**, Member selected |
| 45 | camera-club_45_p2messages.png | 203933 | Messages empty under Member too |
| 46 | camera-club_46_p2home.png | 224030 | Member Home — **no FAB** |
| 47 | camera-club_47_messages_top_org.png | 203454 | Messages scrolled to top (Organizer) — header only |
| 48 | camera-club_48_member_tabbar_start.png | 225025 | Member tab bar start: Home, Walks, Critique, Gear |
| 49 | camera-club_49_member_tabbar_end.png | 226255 | Member tab bar end: Walks, Critique, Gear, Messages — **no Admin** |
| 50 | camera-club_50_p2walks.png | 221620 | Member Walks — no `New photo walk` FAB |
| 51 | camera-club_51_p2walks_actions.png | 145045 | Member RSVP only; no `Cancel walk`, no `Save changes` |
| 52 | camera-club_52_p2gear.png | 209961 | Member Gear — `List gear` FAB present |
| 53 | camera-club_53_p2home_actions.png | 161987 | Member Home inline: `Join queue`, `Return gear`, `Report damage`, `Report lost`; `1 / 12 going` |


## Pipeline result

The rig drove the app end to end without intervention. Two personas created through the real sign-up gate,
six tabs enumerated for Organizer and five for Member, one create form opened and cancelled with a
pixel-exact clean-cancel proof, three absences classified against package evidence and a cross-community
control, and a clean stability sweep with non-zero controls on every check.

The run's most useful outcome is not the pass — it is that **two of the three absences would have been
recorded wrongly by a less careful pass**: Admin and Messages were invisible until the tab bar was scrolled,
and the Critique emptiness read as "nothing seeded" until a control grep proved two records exist. Both were
caught by the working rules' own remedy: run a control in the same shape as the query.

## B25 coverage

**Provable now from this run**

- Community entry, sign-up gate, default-role acceptance, and role assignment display — Camera Club, both roles.
- Full tab enumeration including horizontally-scrolled tabs, reconciled exactly against the package's
  declared `appShell.tabs`.
- Role gating: Admin tab, `New announcement`, `New photo walk`, `Cancel walk`, `Event cancelled`,
  `Save changes` — each shown present under one role and absent under the other, on the device.
- Create-form inventory and a **clean, non-mutating cancel** (`getbbox()` → `None`).
- Primary + alternate affordances with exact label text on 4 of 6 Organizer tabs.
- Stability: 0 FATAL EXCEPTION, 0 ANR, 0 `E/flutter`, 0 RenderFlex overflow, each with a non-zero control.
- Five rendering defects with per-screenshot citations.

**Blocked, and why**

- **Critique alternate affordance (both roles)** — blocked on identity scoping. The two seeded critiques
  belong to `camera-club-member`, and no persona can sign in as that id, so the per-record controls
  (revise / discuss / review) are unreachable from a created persona. Reachable only via Admin under
  Organizer, which is a different surface. Unblocking needs either a sign-in-able seeded identity or a
  critique authored in-app through `New critique`.
- **Messages primary and alternate (both roles)** — blocked on the package: Camera Club declares no
  messaging at all. Not a UI defect; the same platform surface works in Chess Club, which declares 33.
  Unblocking is a package-authoring change, and package JSON is the Skill's to write.
- **End-to-end workflow submission** — out of scope for this ticket, which required cancelling without
  submitting. No workflow was advanced, so no state-transition or write-path evidence was produced.
- **Backend-attached behaviour** — this was a local package rendering run ("No seed files recorded"); nothing
  here exercises app-access, fan-passport or the workflow service.

## Independent verification (orchestrator, by eye)
`camera-club_10_home_a.png` pulled byte-identically and viewed: confirms the double-render bug exactly
as reported — "3 requested workflows" / "3 implemented workflows" / "0 failed workflows" render
correctly, then bare `requestedCount` / `implementedCount` chips with no value directly beneath. Also
visible: the `New announcement` FAB overlapping "Borrower/claim coun[t]" text, matching the reported
cosmetic FAB-overlap note.

## Running tally (7 rigorous walkthroughs)
Cedar (1: dues unseeded), Book Club (1: Messages), Chess (1: disputes), Masjid Nur (0), Youth Soccer
(0), Garden Club (1: Messages), Camera Club (2: Critique identity-scoped-unreachable + Messages
unseeded — the same "seeded identity nobody can sign in as" shape as Cedar/Chess, now proven with a
cross-community positive control against Chess Club's own package). Camera Club is also the richest
rendering-bug find yet: 5 distinct, reproducible UI defects (double-rendered counts, raw fan ids shown
instead of names, a bare `spots` field label, near-invisible disclosure header text, missing
pluralization).
