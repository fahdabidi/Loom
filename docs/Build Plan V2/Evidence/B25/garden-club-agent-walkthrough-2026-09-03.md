# Garden Club — live Android walkthrough (B25 coverage pass)

- **Ticket date / filename date:** 2026-09-03
- **Actual run date:** **2026-09-04**, device clock `Fri Sep  4 04:11:14 PDT 2026`; frames stamped
  03:51 → 04:16. The filename keeps the ticket's date; the evidence is from 2026-09-04.
- **Community:** Garden Club — package `ext_garden_club`, accent `#3F7D4A`, card image
  `generated fallback`, **`No seed files recorded.`** (read from the in-app `Local package details`
  disclosure, `garden-club_13_home_pkgdetails.png`)
- **Device:** `emulator-5554`, 1080x2400, `com.example.loom_communities_demo/.MainActivity`
- **adb path:** Windows-hosted emulator reached over an SSH reverse tunnel to adb on
  `127.0.0.1:5037`. Every command issued as `adb -s emulator-5554 …`. `get-state` = `device` at the
  start and at the end. No `kill-server` / `start-server` / `connect` / `disconnect` / `-a`;
  `ANDROID_ADB_SERVER_ADDRESS` and `ANDROID_ADB_SERVER_PORT` never set. Tunnel intact for the whole run.
- **Mode:** local package rendering. `Local package details` reports no seed files and no backend
  attachment; all records rendered come from the shipped package.

## Personas

Both created in-app. The Garden Club sign-up gate offers exactly **two** roles and **Member is the
pre-selected default**, so the walkthrough persona accepted Member as instructed.

| # | Display name | Account ID | Role assigned | How created |
|---|---|---|---|---|
| 1 | Priya Walkthrough | `garden-member-20` | **Member** (accepted the pre-selected default) | sign-up gate on entering the community |
| 2 | Dev Coordinator | `garden-coordinator-21` | **Coordinator** (role dropdown → Coordinator) | AppBar identity picker → *Sign in as a specific person…* → Create New Account |

Role descriptions exactly as shown in-app:

- **Member** — "Member - RSVPs to events, offers or requests plants, borrows or gives away items, and signs up for care shifts."
- **Coordinator** — "Coordinator - Organizes events, reviews plant handoffs, coordinates shared items and care shifts, and owns club exports."

## Tab set

The bottom tab bar **does** scroll horizontally. Under each persona the bar was swiped left until a
repeat swipe produced a **pixel-identical tab-bar region** (`ImageChops.difference(...).getbbox()`
→ `None` over rows 2150–2400), which is how the end of the bar was established rather than assumed.
Member: end confirmed by two identical repeats. Coordinator: three.

- **Member — 5 tabs:** Home, Calendar, Marketplace, Care, Messages
- **Coordinator — 6 tabs:** Home, Calendar, Marketplace, Documents, Organize, Messages

The two sets are **not nested**: Member has `Care` and no `Documents`/`Organize`; Coordinator has
`Documents` and `Organize` and no `Care`.

## Per-tab affordances — persona 1 (Priya Walkthrough, Member)

| Tab | Primary affordance (exact label) | Alternate affordance (exact label) | Screenshot |
|---|---|---|---|
| Home | `Offer or request a plant` (extended FAB) | `Sign up` (care-shift card); also `Request loan`, `Claim giveaway`, `Save changes` (disabled) | `05_postsignup`, `66_home_m2`, `66_home_m4`, `66_home_m5` |
| Calendar | `Join waitlist` | `Add reminder`; also `Maybe`, `Not attending`; view toggles `Day` / `Week` / `Month` / `Pending` | `14_calendar`, `15_cal_scroll2`, `17_cal_pending` |
| Marketplace | `List a tool to loan` (in the `+` FAB speed dial) | `Give away a garden item` (same speed dial); `Request loan` in the item-detail dialog; `Search available items` | `18_marketplace`, `65_member_mkt_fab`, `23_mkt_dialog_bottom` |
| Care | `Sign up` | `Save changes` (disabled, with "No changes to save yet.") | `25_care`, `26_care_scroll1` |
| Messages | **none found** | **none found** | `27_messages`, `28_messages_top`, `29_messages_bottom` |

Two notes on the Calendar row. The only seeded event is at capacity (`0 seats left`, `2 / 2 going`),
so **no affirmative "attending" control renders for the Member** — `Join waitlist` is what the
capacity state offers, and it is the primary in that state, not a fallback. And the FAB slot is
**empty** on the Member's Calendar; that absence is classified below.

## Per-tab affordances — persona 2 (Dev Coordinator, Coordinator)

| Tab | Primary affordance (exact label) | Alternate affordance (exact label) | Screenshot |
|---|---|---|---|
| Home | `Repeat this event` | `Cancel event`; also `Save changes` (disabled). **No FAB.** | `58_p2_home_a`, `68_p2home_c5` |
| Calendar | `New garden event` (extended FAB) | `Repeat this event`, `Cancel event`, `Maybe`, `Not attending`, `Join waitlist`, `Add reminder`, `Event cancelled` | `52_p2_calendar`, `54_p2_cal_actions` |
| Marketplace | `List a tool to loan` (in the `+` FAB speed dial) | `Give away a garden item` (same speed dial); `Search available items` | `56_p2_marketplace`, `61_mkt_createform` |
| Documents | `New export package` (extended FAB) | **none found** — see below | `47_p2_documents`, `48_p2_docs_s1`, `49/50_docs_pre/posttap` |
| Organize | `New volunteer shift` (extended FAB) | `Approve handoff`; also `Save changes` (disabled) | `45_p2_organize`, `46_p2_org_s1` |
| Messages | **none found** | **none found** | `43_p2_messages`, `44_p2_messages_top` |

**Documents has a primary but no alternate.** The tab's only other content is the export-status card,
which is inert: tapping it produced **zero differing pixels** below the status bar
(`ImageChops.difference(pre, post).getbbox()` → `None`, frames 49 → 50). Its chips
(`Mode: Export`, `Redaction: Approved`, `Download: Unavailable`, `2 schemas`) are state, not controls.

## Create-form observation — Home → `Offer or request a plant`

Chosen as the clearest labelled create the walkthrough persona (Member) can use.

Fields presented, in order (**10**):

1. `Plant Variety`
2. `Offer Type`
3. `Notes`
4. `Pickup`
5. `Pickup date`
6. `Pickup time`
7. `Reminder:  hours before pickup`
8. `Safe pickup`
9. `Availability`
10. `Contact Info`

Actions: `Cancel`, `Create`. **`Cancel` was tapped; nothing was submitted.**

**Cancel verified clean.** The post-cancel frame was diffed against the pre-dialog frame excluding the
status bar (rows 120–2400): `ImageChops.difference(pre, post).getbbox()` returned `None` — zero
differing pixels. The whole-file md5s differ (`737f82bd…` vs `7536dcbe…`) only because the status-bar
clock advanced 4:00 → 4:01 and the battery glyph changed.

- pre-dialog: `garden-club_34_home_predialog.png`
- form: `garden-club_35_createform.png`
- post-cancel: `garden-club_36_postcancel.png`

A second create surface was opened and dismissed without submitting: the Marketplace `+` FAB, which
is a **speed dial**, not a single create — it expands to `Give away a garden item` and
`List a tool to loan` (`garden-club_61_mkt_createform.png`, `garden-club_65_member_mkt_fab.png`).
Identical under both roles.

## Absence classification

Every row below was taken through the full protocol before being recorded as absent: scrolled to
**both** ends with a repeat swipe proving the end (identical frames), the `Local package details`
disclosure expanded, taps proven to register on that same surface, and then re-checked under a
second persona with a different role.

| Surface | What is missing | Verdict | Evidence | Seeded data present? |
|---|---|---|---|---|
| **Messages** (Member) | thread list, `New thread`/create control, any empty-state text | **unseeded/unwritable** | Empty under **both** roles (`27`, `28`, `29`, `43`, `44`). No FAB in any frame; nothing renders between the tab header card and the package disclosure. Taps demonstrably register on this exact surface: the AppBar chat icon routed here (`30`) and the AppBar bell opened a sheet reading **"No notifications yet."** (`31`). | **No.** Every other tab renders seeded records (events, care shifts, exchanges, marketplace items), so the local engine does surface seeded data when it exists — Messages showing nothing is absence of data, not a render failure. |
| **Messages** (Coordinator) | same | **unseeded/unwritable** — *not* role-gated | The second persona (`garden-coordinator-21`, Coordinator) sees the identical empty surface (`43`, `44`). This is exactly the check that would have shown role-gating, and it came back negative. | No |
| **Calendar create** (Member) | any create-event control; FAB slot empty | **role-gated** | Member Calendar top and bottom both show an empty FAB slot (`14`, `16`). Switching to the Coordinator persona on the same device renders **`New garden event`** in that slot (`52`). | n/a — the control, not data |
| **Care create** (Member) | any create-shift control | **role-gated** | Member Care has no FAB (`25`, `26`). The Coordinator has no `Care` tab at all; the equivalent create lives on `Organize` as **`New volunteer shift`** (`45`). | n/a |
| **Home create** (Coordinator) | `Offer or request a plant` FAB | **role-gated (inverse)** | Coordinator Home has no FAB at top or bottom (`55`, `58`, `59`); the Member's Home has it (`05`, `64`). Likewise `Request loan` and `Claim giveaway` render for the Member (`66_home_m4`, `66_home_m5`) and **not** for the Coordinator on the same cards (`68_p2home_c5`). | n/a |
| **Documents alternate** (Coordinator) | any second actionable control | **unseeded/unwritable** | The export-status card is inert — tap produced zero pixel change (`49` → `50`). The tab holds one export record and one FAB. | Yes, one export record renders; it is simply read-only. |
| **Seeded fan identities** | `garden-coordinator`, `garden-member-rina`, `garden-member-maya` as sign-in identities | **identity-scoped, unreachable** | The Calendar attendee list and `Signed up: 1` on the care shift prove records exist under seeded fan ids. But *Sign in as a specific person… — "Use one of this community's individual accounts"* lists **only the accounts created during this run** (`38`, `63`, `67`). There is no route to sign in as a seeded id. | Yes — the data exists; the identity does not. |

## Product findings (not blockers, but real)

1. **`accessibilityNote` renders as a bare camelCase key with no value.** On the Home event summary
   the chip reads literally `accessibilityNote` (`66_home_m4`, `68_p2home_c4`), while the same field
   in the Coordinator's event editor renders correctly as `Accessibility Note` → "Paved path to Plot A;
   seated potting station available." (`53_p2_cal_s2`, `68_p2home_c5`). So the value is present and the
   summary chip is losing both the label and the value. Present under both roles.
2. **Two labels have a hole where an inline number should sit.** The create form's field 7 reads
   `Reminder:  hours before pickup` and the event editor reads `Default reminder:  hours before`
   (with the value `24` on the line below). Double space in both — the number is rendered
   out-of-line rather than in the sentence.
3. **Marketplace grid tiles clip their content.** `Due back 2026-08-20` and `Current holder:` are cut
   off at a fixed card height (`19_mkt_scroll1`, `20_mkt_items`). The same values render fully in the
   item-detail dialog, so it is a tile-height issue, not missing data.

None of these were worked around, and no assertion was weakened — this walkthrough changed no code.

## Stability

| Check | Result |
|---|---|
| `mCurrentFocus` at start and end | `com.example.loom_communities_demo/.MainActivity` both times — never lost focus, never handed to a system dialog |
| `adb get-state` at start / end | `device` / `device` |
| Blank frames | **none** — all 105 captures rendered content |
| System dialogs overlaying the app | none encountered |
| logcat lines swept | **120,705** (`-v brief`), buffer starts `09-04 00:00:00.005`, i.e. ~4 h before the run began at 03:51 |
| `FATAL EXCEPTION` | **0** |
| `ANR in` | **0** |
| **Control counts** (proving the grep is not silently broken) | `loom_communities_demo` → **1511** hits; `flutter` → **466**; `Displayed` → **4**. A query in the same shape returning thousands of hits is why the two zeros above are absence, not a broken pattern. |
| `/data/anr/` trace files | 7 present, **all dated 2026-09-03**; `ls \| grep 2026-09-04` exits 1 — **no ANR trace was written during this run** |

## Screenshot index

Captured to `/tmp` on the agent host. `*.png` is gitignored — these are transient; this manifest is
the durable record. All 1080x2400 except the four cropped tab-bar strips (1080x200), which were made
locally with PIL for the identical-frame proof.

| # | File | Bytes | What it shows |
|---|---|---:|---|
| 01 | `garden-club_00_start.png` | 316579 | starting frame — community list "Loom Communities" |
| 02 | `garden-club_01_list.png` | 316579 | copy of 00 (list, Garden Club card at top) |
| 03 | `garden-club_02_open.png` | 119831 | Garden Club sign-up gate, role pre-selected **Member** |
| 04 | `garden-club_03_roles.png` | 129016 | role dropdown open — exactly two options: Member / Coordinator |
| 05 | `garden-club_04_presignup.png` | 126410 | name "Priya Walkthrough", role Member, pre-Sign Up |
| 06 | `garden-club_05_postsignup.png` | 268201 | Home as Member; FAB `Offer or request a plant` |
| 07 | `garden-club_06_tabbar_s1.png` | 268964 | tab bar scrolled once — Calendar, Marketplace, Care, Messages |
| 08 | `garden-club_07_tabbar_s2.png` | 268964 | repeat swipe — identical tab-bar region |
| 09 | `garden-club_08_tabbar_s3.png` | 268964 | third swipe — identical again = end of bar |
| 10 | `garden-club_09_home_scroll1.png` | 199317 | Member Home — export status card + care shift |
| 11 | `garden-club_09_home_scroll2.png` | 203487 | Member Home — `Save changes` (disabled) + `Sign up` |
| 12 | `garden-club_09_home_scroll3.png` | 250775 | Member Home — plant exchange record |
| 13 | `garden-club_09_home_scroll4.png` | 210831 | Member Home — event record, `accessibilityNote` bare-key chip |
| 14 | `garden-club_10_home_bottomA.png` | 157220 | Member Home bottom (sample A) |
| 15 | `garden-club_11_home_bottomB.png` | 157227 | Member Home bottom (sample B) — only status bar differs = end |
| 16 | `garden-club_12_home_disclosure.png` | 184283 | `Local package details` expanded |
| 17 | `garden-club_13_home_pkgdetails.png` | 152669 | ext_garden_club / #3F7D4A / generated fallback / No seed files recorded |
| 18 | `garden-club_14_calendar.png` | 167878 | Member Calendar — Day/Week/Month/Pending, Mar 2027 grid, **no FAB** |
| 19 | `garden-club_15_cal_scroll1.png` | 199948 | Member Calendar — event card, 0 seats left |
| 20 | `garden-club_15_cal_scroll2.png` | 151241 | Member Calendar — `Maybe` / `Not attending` / `Join waitlist` / `Add reminder` |
| 21 | `garden-club_15_cal_scroll3.png` | 151241 | repeat scroll — identical = end |
| 22 | `garden-club_16_cal_top.png` | 244999 | Member Calendar top — confirms no create FAB |
| 23 | `garden-club_17_cal_pending.png` | 250575 | `Pending` view toggle engaged — proof taps register on Calendar |
| 24 | `garden-club_18_marketplace.png` | 249786 | Member Marketplace — `Search available items`, item grid, `+` FAB |
| 25 | `garden-club_19_mkt_scroll1.png` | 178523 | Marketplace grid, cards clipped at fixed height |
| 26 | `garden-club_19_mkt_scroll2.png` | 117022 | Marketplace bottom |
| 27 | `garden-club_19_mkt_scroll3.png` | 117022 | repeat = identical |
| 28 | `garden-club_19_mkt_scroll4.png` | 117022 | repeat = identical (end confirmed twice) |
| 29 | `garden-club_20_mkt_items.png` | 205155 | Marketplace item cards, "Current holder:" clipped |
| 30 | `garden-club_21_mkt_pretap.png` | 204863 | pre-tap frame for item-dialog cleanliness check |
| 31 | `garden-club_22_mkt_itemtap.png` | 205524 | item detail dialog "Steel wheelbarrow" |
| 32 | `garden-club_23_mkt_dialog_bottom.png` | 206339 | dialog scrolled — `Request loan` + `Close` |
| 33 | `garden-club_24_mkt_postclose.png` | 204908 | post-Close — pixel-identical to 21 below the status bar |
| 34 | `garden-club_25_care.png` | 192274 | Member Care — "Tuned for Member", **no FAB** |
| 35 | `garden-club_26_care_scroll1.png` | 169572 | Member Care — `Save changes` (disabled) + `Sign up` |
| 36 | `garden-club_26_care_scroll2.png` | 130482 | Care bottom |
| 37 | `garden-club_26_care_scroll3.png` | 130482 | repeat = identical = end |
| 38 | `garden-club_27_messages.png` | 150593 | **Member Messages — empty**: header card then package disclosure |
| 39 | `garden-club_28_messages_top.png` | 223680 | Messages scrolled to top — nothing above the header |
| 40 | `garden-club_29_messages_bottom.png` | 150508 | Messages scrolled to bottom — nothing below |
| 41 | `garden-club_30_appbar_chat.png` | 150437 | AppBar chat icon routes to the Messages tab (tap registers) |
| 42 | `garden-club_31_notifications.png` | 64811 | notifications sheet — explicit empty state "No notifications yet." |
| 43 | `garden-club_32_overflow.png` | 155582 | overflow menu — single item `Sync settings` |
| 44 | `garden-club_33_crop.png` | 16217 | cropped tab-bar region of 33 |
| 45 | `garden-club_33_tabbar_back.png` | 147832 | tab bar scrolled back to Home/Calendar/Marketplace/Care |
| 46 | `garden-club_34_home_predialog.png` | 230048 | **pre-dialog** frame for the create-form cancel check |
| 47 | `garden-club_35_createform.png` | 93324 | **create form** `Offer or request a plant` — 10 fields, Cancel/Create |
| 48 | `garden-club_36_postcancel.png` | 230233 | **post-Cancel** — zero differing pixels vs 34 below row 120 |
| 49 | `garden-club_37_identity_picker.png` | 254516 | identity picker — persona 1 id `garden-member-20`, roles Member/Coordinator |
| 50 | `garden-club_38_specific_person.png` | 117429 | "Sign in as a specific person…" lists ONLY the created account |
| 51 | `garden-club_39_p2_roles.png` | 125796 | persona 2 role dropdown — Member / Coordinator |
| 52 | `garden-club_40_p2_presignup.png` | 124350 | persona 2 "Dev Coordinator", role Coordinator, pre-Sign Up |
| 53 | `garden-club_41_p2_home.png` | 216605 | Coordinator Home — tab bar now Home/Calendar/Marketplace/**Documents** |
| 54 | `garden-club_42_p2_tabbar_s1.png` | 218181 | Coordinator tab bar scrolled — Marketplace/Documents/Organize/Messages |
| 55 | `garden-club_42_p2_tabbar_s2.png` | 217757 | repeat = identical |
| 56 | `garden-club_42_p2_tabbar_s3.png` | 217757 | repeat = identical |
| 57 | `garden-club_42_p2_tabbar_s4.png` | 217757 | repeat = identical (end confirmed three times) |
| 58 | `garden-club_42_p2_tabcrop_1.png` | 17369 | cropped Coordinator tab bar — 6 tabs total |
| 59 | `garden-club_42_p2_tabcrop_2.png` | 17369 | crop, repeat |
| 60 | `garden-club_42_p2_tabcrop_3.png` | 17369 | crop, repeat |
| 61 | `garden-club_42_p2_tabcrop_4.png` | 17369 | crop, repeat |
| 62 | `garden-club_43_p2_messages.png` | 154800 | **Coordinator Messages — equally empty**, no create control |
| 63 | `garden-club_44_p2_messages_top.png` | 224748 | Coordinator Messages scrolled to top — nothing above |
| 64 | `garden-club_45_p2_organize.png` | 262379 | Organize tab (Coordinator-only) — FAB `New volunteer shift` |
| 65 | `garden-club_46_p2_org_s1.png` | 217896 | Organize — `Approve handoff` |
| 66 | `garden-club_46_p2_org_s2.png` | 192709 | Organize — shift editor, `Save changes` (disabled), no `Sign up` |
| 67 | `garden-club_46_p2_org_s3.png` | 226326 | Organize — approved handoff record |
| 68 | `garden-club_46_p2_org_s4.png` | 171104 | Organize bottom |
| 69 | `garden-club_46_p2_org_s5.png` | 171104 | repeat = identical = end |
| 70 | `garden-club_47_p2_documents.png` | 226521 | Documents tab (Coordinator-only) — FAB `New export package` |
| 71 | `garden-club_48_p2_docs_s1.png` | 179444 | Documents bottom — no second actionable control |
| 72 | `garden-club_49_docs_pretap.png` | 179445 | pre-tap on the export status card |
| 73 | `garden-club_50_docs_posttap.png` | 179445 | post-tap — zero differing pixels: the card is not tappable |
| 74 | `garden-club_51_crop.png` | 18128 | cropped tab bar — Home/Calendar/Marketplace/Documents |
| 75 | `garden-club_51_p2_tabbar_home.png` | 177323 | Coordinator tab bar scrolled back to start |
| 76 | `garden-club_52_p2_calendar.png` | 171824 | **Coordinator Calendar — FAB `New garden event` present** |
| 77 | `garden-club_53_p2_cal_s1.png` | 205279 | Coordinator Calendar scrolled |
| 78 | `garden-club_53_p2_cal_s2.png` | 195187 | Coordinator event editor; `Accessibility Note` renders correctly here |
| 79 | `garden-club_54_p2_cal_actions.png` | 183045 | Coordinator Calendar actions — Repeat/Cancel/Maybe/Not attending/Join waitlist/Add reminder/Event cancelled |
| 80 | `garden-club_55_p2_home.png` | 207651 | Coordinator Home — **no FAB** |
| 81 | `garden-club_56_p2_marketplace.png` | 202661 | Coordinator Marketplace |
| 82 | `garden-club_57_p2_home_s1.png` | 126561 | (MISLABELLED — actually Coordinator **Marketplace** bottom, `+` FAB) |
| 83 | `garden-club_57_p2_home_s2.png` | 115751 | (MISLABELLED — Coordinator Marketplace, repeat) |
| 84 | `garden-club_57_p2_home_s3.png` | 115751 | (MISLABELLED — Coordinator Marketplace, repeat) |
| 85 | `garden-club_58_p2_home_a.png` | 206839 | Coordinator Home top — no FAB |
| 86 | `garden-club_59_p2_home_bottom.png` | 148193 | Coordinator Home bottom — no FAB, no `Claim giveaway` |
| 87 | `garden-club_60_mkt_prefab.png` | 190701 | Coordinator Marketplace before expanding `+` |
| 88 | `garden-club_61_mkt_createform.png` | 226133 | `+` speed dial — `Give away a garden item` / `List a tool to loan` |
| 89 | `garden-club_62_picker2.png` | 254864 | identity picker — persona 2 id `garden-coordinator-21` |
| 90 | `garden-club_63_switchback.png` | 148119 | account list — only the two created accounts exist |
| 91 | `garden-club_64_member_back.png` | 221646 | switched back to Member — Care tab and plant FAB return |
| 92 | `garden-club_65_member_mkt_fab.png` | 229053 | Member `+` speed dial — same two create actions |
| 93 | `garden-club_66_home_m1.png` | 192858 | Member Home re-scroll 1 |
| 94 | `garden-club_66_home_m2.png` | 233830 | Member Home — `Save changes` (disabled) + `Sign up` |
| 95 | `garden-club_66_home_m3.png` | 212881 | Member Home — exchange record |
| 96 | `garden-club_66_home_m4.png` | 209523 | Member Home — `Request loan`; `accessibilityNote` bare-key chip |
| 97 | `garden-club_66_home_m5.png` | 150719 | Member Home — `Claim giveaway`, then package disclosure |
| 98 | `garden-club_66_home_m6.png` | 150719 | repeat = identical |
| 99 | `garden-club_66_home_m7.png` | 150719 | repeat = identical = end |
| 100 | `garden-club_67_picker3.png` | 147304 | account list again before switching back to Coordinator |
| 101 | `garden-club_68_p2home_c1.png` | 181820 | Coordinator Home scroll 1 |
| 102 | `garden-club_68_p2home_c2.png` | 231388 | Coordinator Home — `Save changes` only; **no `Sign up`** |
| 103 | `garden-club_68_p2home_c3.png` | 213596 | Coordinator Home scroll 3 |
| 104 | `garden-club_68_p2home_c4.png` | 172192 | Coordinator Home — event editor fields |
| 105 | `garden-club_68_p2home_c5.png` | 182403 | Coordinator Home — `Repeat this event` / `Cancel event`; no `Request loan` / `Claim giveaway` |

Three files are **mislabelled** and are named honestly here rather than renamed after the fact:
`garden-club_57_p2_home_s1/s2/s3.png` were intended as Coordinator Home scrolls but a mistyped tab
coordinate landed on **Marketplace**, so that is what they show. The Coordinator Home scroll set was
re-captured correctly as `garden-club_68_p2home_c1…c5.png`.

## Pipeline result

The rig drove the full loop end to end on a real device with no code change and no test run:
community list → community open → in-app account creation (two personas, two different roles) →
every tab under both roles, with the tab bar's horizontal extent proven rather than assumed →
one create form opened, enumerated and cancelled cleanly with a pixel-diff proof → one item-detail
dialog opened and closed cleanly with the same proof → identity switching in both directions →
logcat and ANR sweep with controls. No crash, no ANR, no blank frame, no lost focus.

## B25 coverage

**Provable now, from this run:**

- Garden Club's **tab inventory under both shipped roles** — 5 for Member, 6 for Coordinator, with
  end-of-bar proven by identical-frame diffs rather than by assuming four tabs.
- **Primary + alternate affordance with exact label text on 9 of the 11 tab/persona pairs**
  (Member: Home, Calendar, Marketplace, Care; Coordinator: Home, Calendar, Marketplace, Organize —
  plus Documents at primary-only).
- **One create form fully enumerated** (10 fields) and **cancel proven non-destructive** by a
  zero-differing-pixel diff, not by eyeballing.
- **Role-gating proven in both directions on the same device**: `New garden event` and
  `New volunteer shift` appear only for Coordinator; `Offer or request a plant`, `Sign up`,
  `Request loan` and `Claim giveaway` appear only for Member.
- **Stability**: 0 FATAL EXCEPTION and 0 ANR across 120,705 log lines, with control counts proving
  the sweep was live.

**Blocked, and why:**

- **Messages cannot be certified at all, under any role.** There is no create control and no data,
  so there is no primary and no alternate to name. This is not a coverage gap in the walkthrough —
  it is an absent surface, classified above as unseeded/unwritable. Certifying it needs seeded
  thread data or a write path in the package; neither exists today.
- **Documents cannot be certified at "primary + alternate"** — it has exactly one control. Same
  cause: the export record is read-only and nothing else on the tab is actionable.
- **Nothing beyond local package rendering is proven.** No backend was attached, `No seed files
  recorded.`, and the only accounts that exist are the two created in this session. Any B25 row that
  depends on a seeded fan identity (per-member RSVP history, prior sign-ups, thread membership) is
  **unreachable from the app**, because the "sign in as a specific person" list offers only
  locally-created accounts.
- **No workflow was submitted.** Per the ticket, every create was cancelled without submitting, so
  terminal states, receipts and reminder firing remain unproven for this community.
- **No UX-judge pass was run.** This is the adb walkthrough half of the B25 bar only.

## Independent verification (orchestrator, by eye)
Two screenshots pulled byte-identically to Windows and viewed:
- `garden-club_27_messages.png` — Messages tab confirmed empty (descriptor card only; the expanded
  "Local package details" disclosure shows "No seed files recorded."). Matches Book Club's identical
  gap shape.
- `garden-club_66_home_m4.png` — the bare `accessibilityNote` chip confirmed rendering literally,
  with no label and no value, directly below "Seasonal focus: Pollinator habitat workshop" on the
  Member Home event card. Real rendering bug, not a misreading.

## Dispatch history (for the record)
This community needed **4 attempts** before a clean run: r1 died mid-signup when the SSH reverse
tunnel's original 2h lifetime expired; r2 (a duplicate the first failure's silent death triggered)
correctly detected the ambiguity and deferred without writing a manifest rather than guess; r3 hit
the VM claude account's monthly spend limit mid-run (confirmed cleared by a live test call before
retrying); r4 succeeded cleanly. The tunnel was re-opened with an 8h lifetime after r1's failure,
which safely covered the rest of the grind. No prior community's evidence was affected.

## Running tally (6 rigorous walkthroughs)
Cedar (1 gap: dues unseeded), Book Club (1: Messages no writer), Chess (1: disputes unseeded),
Masjid Nur (0), Youth Soccer (0), Garden Club (1: Messages no writer — same shape as Book Club).
Messages-as-empty-surface is now a 2-of-6 pattern, the most repeated single gap so far.
