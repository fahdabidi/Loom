# Chess Club — live Android walkthrough (B25 coverage pass)

- **Date:** 2026-09-03
- **Community:** Chess Club (`ext_chess_club`, accent `#6B4F2A`, card image `generated fallback`, *No seed files recorded*)
- **Device:** `emulator-5554`, 1080x2400, `com.example.loom_communities_demo/.MainActivity`
- **adb path:** Windows-hosted emulator reached over an SSH reverse tunnel to adb on `127.0.0.1:5037`.
  Every command issued as `adb -s emulator-5554 …`. `get-state` = `device` at start and at end.
  No `kill-server` / `start-server` / `connect` / `disconnect` / `-a`; `ANDROID_ADB_SERVER_ADDRESS`
  and `ANDROID_ADB_SERVER_PORT` never set. Tunnel intact for the whole run.
- **Mode:** local package rendering. Documents surfaces state *"Member state unavailable. Member state
  is available when connected to a community."* — no backend attached.

## Personas

All three created in-app through **Create New Account**. The Chess Club sign-up gate offers three roles;
**Organizer is the pre-selected default**, so the walkthrough persona accepted Organizer as instructed.

| # | Display name | Account ID | Role assigned | How created |
|---|---|---|---|---|
| 1 | Nadia Walkthrough | `chess-organizer-20` | **Organizer** (accepted the default) | sign-up gate on entering the community |
| 2 | Omar Player | `chess-member-21` | **Player** (role dropdown → Player) | AppBar identity picker → *Sign in as a specific person…* → Create New Account |
| 3 | Rita Owner | `chess-owner-22` | **Owner** (role dropdown → Owner) | same route as persona 2 |

Role descriptions as shown in-app:
- **Organizer** — "Organizer - Schedules club activity, manages pairings, publishes rankings, and maintains rules."
- **Player** — "Member - Schedules and plays matches, reports results, joins club nights, and participates in discussions."
- **Owner** — "Owner - Sets up the community and owns its data-export responsibilities; admission authority remains in App Access and is not modeled as a workflow."

## Tab set

The bottom tab bar **does** scroll horizontally. Swiping it left from the initial four revealed three more;
a repeat swipe produced a **pixel-identical tab-bar region** (`ImageChops.difference(...).getbbox()` → `None`
over rows 2150–2400), which is how the end of the bar was confirmed rather than assumed.

- **Organizer / Owner — 7 tabs:** Home, Calendar, Matches, Rankings, Documents, Admin, Messages
- **Player — 6 tabs:** Home, Calendar, Matches, Rankings, Documents, Messages (**no Admin**)

## Per-tab affordances — persona 1 (Nadia Walkthrough, Organizer)

| Tab | Primary affordance (exact label) | Alternate affordance (exact label) | Screenshot |
|---|---|---|---|
| Home | `Send reminder` | `Cancel club night` | `chess-club_07_postsignup.png`, `chess-club_10_home_bottom.png` |
| Calendar | `Schedule club night` (FAB) | `Send reminder` | `chess-club_13_calendar.png`, `chess-club_14_calendar_bottom.png` |
| Matches | `Record standings impact` | `Save changes` (disabled until a field is edited) | `chess-club_15_matches.png`, `chess-club_18_matches_actions.png` |
| Rankings | `Revise ranking` (row-detail dialog) | `Retire ranking row` | `chess-club_19_rankings.png`, `chess-club_22_rankings_dialog.png` |
| Documents | `Add rules document` (FAB) | `Open embedded` (also `Open external`, `Download`, `Archive document`) | `chess-club_24_documents.png`, `chess-club_25_documents_actions.png` |
| Admin | `New pairing queue` (in the `+` FAB speed dial) | `New ranking row` (same speed dial); inline: `Assign pairing`, `Close queue` | `chess-club_66_admin_org3.png`, `chess-club_67_admin_fab.png` |
| Messages | `New thread` (FAB) | `Reply` (also `Mute`, `Archive`) | `chess-club_29_messages.png`, `chess-club_30_messages_actions.png` |

**Primary/alternate was found on every tab.** No surface was left unresolved.

Note on Admin: the FAB renders **icon-only (`+`)** when collapsed under Organizer, unlike Calendar
(`Schedule club night`), Documents (`Add rules document`) and Messages (`New thread`), which are labelled
extended FABs. Its two actions are only discoverable by tapping it. Under Owner the same slot renders as a
labelled extended FAB reading `New export`, because that role has a single create rather than a speed dial.

## Create-form observation — Calendar → `Schedule club night`

Chosen as the clearest labelled create the Organizer persona can use.

Fields presented, in order (7):

1. `Event Title`
2. `Event Kind`
3. `Event Date`
4. `Event Time`
5. `Location`
6. `Pairing Note`
7. `Reminder recipient`

Actions: `Cancel`, `Create`. **`Cancel` was tapped; nothing was submitted.**

**Cancel verified clean.** The post-cancel frame was diffed against the pre-dialog frame excluding the
status-bar clock (rows 120–2400): `ImageChops.difference(pre, post).getbbox()` returned `None` — zero
differing pixels. The whole-file md5s differ only because the status-bar clock advanced 10:46 → 10:47.

- pre-dialog: `chess-club_31_predialog.png`
- form: `chess-club_32_createform.png`
- post-cancel: `chess-club_33_postcancel.png`

## Absence classification

Every absence below was tested before being recorded: scrolled to both ends of the surface, expanded the
`Local package details` disclosure, confirmed taps register, and re-checked under a second (and where
relevant a third) role. FABs in this app are pinned to the viewport's bottom-right, so a scrolled frame
with an empty FAB zone is conclusive for that role; the crop of the Calendar FAB zone under Player was
taken specifically to prove that rather than infer it.

| Surface | What was missing | Verdict | Evidence |
|---|---|---|---|
| Matches (Organizer) | no create control at all | **role-gated** | Absent under Organizer across the whole scroll (`chess-club_34_matches_end.png`). Under **Player** a `+` FAB appears and expands to `Record match` and `Propose match` (`chess-club_49_matches_player.png`, `chess-club_50_matches_create.png`). |
| Calendar (Player) | no `Schedule club night` FAB | **role-gated** | Present under Organizer (`chess-club_13_calendar.png`); absent under Player at top and after scrolling — FAB zone crop empty (`chess-club_53_calendar_player.png`, `chess-club_54_calendar_player_scroll.png`). |
| Documents (Player) | no `Add rules document` FAB, no `Archive document` | **role-gated** | Player sees only `Open embedded` / `Open external` / `Download` (`chess-club_55_documents_player.png`) vs Organizer's full set (`chess-club_25_documents_actions.png`). |
| Admin tab (Player) | entire tab absent from the bar | **role-gated** | Player's bar ends at Messages, confirmed by an identical-frame repeat swipe (`chess-club_51_tabs_player.png`, `chess-club_52_tabs_player2.png`). Present for Organizer and Owner. |
| Admin → export controls (Organizer) | no export record, no export action | **role-gated (Owner)** | Under **Owner** the Admin tab opens on a `Ready to export` record — `August ladder and match archive`, `3 data groups`, `Chess Owner`, `Ready to generate` — with `Change scope`, `Generate export`, `Cancel export`, and a labelled `New export` FAB (`chess-club_61_admin_owner.png`). |
| Admin + Matches → **result disputes** | no dispute record and no dispute create control, under **any** of the three roles | **unseeded / unwritable** | Both blurbs promise it — Admin: *"Pairing queues, result disputes, rankings, and export controls."*; Matches: *"Match proposals, results, corrections, disputes, and completed games."* Organizer's Admin `+` offers only `New ranking row` and `New pairing queue` (`chess-club_67_admin_fab.png`); Player's Matches `+` offers only `Record match` and `Propose match` (`chess-club_50_matches_create.png`); Owner's Admin FAB is `New export` alone (`chess-club_61_admin_owner.png`, `chess-club_62_admin_owner2.png`). No seeded dispute row on any surface, and `Local package details` reports *"No seed files recorded."* |

## Product finding — the in-community role selector silently ignores a different role

The AppBar identity picker (`Account role and permissions`) lists all three roles as radio options under
the heading *"Choose the role you want to use in this community."* With persona 1 (Organizer) active,
**Player was selected twice** — once on the radio control, once on the row label. Both times the dialog
dismissed and the community stayed on **Organizer**: the role banner still read `Organizer`, and reopening
the picker showed the radio still on Organizer.

Re-checked with persona 2: the picker correctly shows the radio on **Player** for `chess-member-21`, so the
control does reflect the account's granted role. The likely reading is that an account holds exactly one
role and the other two rows are not selectable — but they are **rendered identically to the selectable one**:
no disabled styling, no toast, no error, no explanation. Choosing one dismisses the dialog as though it
worked. Given a heading that explicitly invites the user to choose, this reads as a silent no-op.

The working route is the same dialog's `Sign in as a specific person…` → `Create New Account` with a role
dropdown, which was used for personas 2 and 3 and behaved correctly every time.

Evidence: `chess-club_37_identity.png` (Organizer, radio on Organizer) → `chess-club_38_player_selected.png`
(after tapping Player) → `chess-club_39_player_role.png` (banner still Organizer) →
`chess-club_40_identity_recheck.png` (radio still Organizer) → `chess-club_42_player_retry.png` (row-label
tap, still Organizer) → `chess-club_56_picker_player.png` (persona 2, radio correctly on Player).

## Stability

- **No crashes, no ANRs, no blank frames** across 67 captures and three persona switches.
- `mCurrentFocus` was `com.example.loom_communities_demo/.MainActivity` at the start of the run and after
  the final interaction. No system dialog ever overlaid the app.
- logcat sweep: `grep -c -E "FATAL EXCEPTION|ANR in"` → **0**.
  - **Control 1** — same pipeline, term that must exist: `grep -c "loom_communities_demo"` → **468** at
    mid-run, **524** at end. The buffer is readable and non-empty.
  - **Control 2** — same alternation syntax: `grep -c -E "FATAL EXCEPTION|MainActivity"` → **61**. The `-E`
    alternation matches when there is something to match.
  - Buffer size at sweep: **80,247 lines**. The zero is a real zero, not an empty pipe.
- `adb -s emulator-5554 get-state` → `device` at start and end.

## Screenshot index

Captured to `/tmp` on the agent host. `*.png` is gitignored — these are transient; this manifest is the
durable record. All 1080x2400.

| # | File | Bytes | What it shows |
|---|---|---:|---|
| 01 | chess-club_01_list.png | 317440 | community list "Loom Communities" |
| 02 | chess-club_02_list_scrolled.png | 302628 | Chess Club card in view |
| 03 | chess-club_03_open.png | 122950 | sign-up gate, default role Organizer |
| 04 | chess-club_04_name.png | 189709 | display name entered |
| 05 | chess-club_05_roles.png | 131512 | role dropdown: Organizer / Player / Owner |
| 06 | chess-club_06_presignup.png | 128142 | pre-Sign Up state |
| 07 | chess-club_07_postsignup.png | 208642 | Home, signed in as Organizer |
| 08 | chess-club_08_home_scroll1.png | 181314 | Home, club-night record |
| 09 | chess-club_09_home_scroll2.png | 166744 | Home, further records |
| 10 | chess-club_10_home_bottom.png | 137570 | Home bottom: Send reminder / Cancel club night |
| 11 | chess-club_11_tabbar_scroll1.png | 137310 | tab bar scrolled — Documents, Admin, Messages |
| 12 | chess-club_12_tabbar_scroll2.png | 137310 | identical frame = end of bar |
| 13 | chess-club_13_calendar.png | 237853 | Calendar, `Schedule club night` FAB |
| 14 | chess-club_14_calendar_bottom.png | 150095 | Calendar alternates |
| 15 | chess-club_15_matches.png | 220790 | Matches top (Organizer) |
| 16 | chess-club_16_matches_mid.png | 167929 | Matches scrolled |
| 17 | chess-club_17_matches_upper.png | 187636 | Matches upper records |
| 18 | chess-club_18_matches_actions.png | 173751 | Matches inline actions |
| 19 | chess-club_19_rankings.png | 198348 | Rankings grid, search + sortable columns |
| 20 | chess-club_20_rankings_bottom.png | 134804 | Rankings full extent |
| 21 | chess-club_21_rankings_select.png | 193679 | row tap opens detail dialog |
| 22 | chess-club_22_rankings_dialog.png | 194214 | `Revise ranking` / `Retire ranking row` |
| 23 | chess-club_23_postclose.png | 135098 | dialog closed cleanly |
| 24 | chess-club_24_documents.png | 245003 | Documents, `Add rules document` FAB |
| 25 | chess-club_25_documents_actions.png | 154239 | Open embedded / external / Download / Archive |
| 26 | chess-club_26_admin.png | 232836 | Admin, "Tuned for Organizer" |
| 27 | chess-club_27_admin_actions.png | 178746 | Assign pairing / Close queue / Revise / Retire |
| 28 | chess-club_28_admin_more.png | 126372 | Admin bottom |
| 29 | chess-club_29_messages.png | 236608 | Messages, `New thread` FAB |
| 30 | chess-club_30_messages_actions.png | 140796 | Reply / Mute / Archive |
| 31 | chess-club_31_predialog.png | 238560 | **pre-dialog baseline** |
| 32 | chess-club_32_createform.png | 139452 | **create form, 7 fields** |
| 33 | chess-club_33_postcancel.png | 238199 | **post-cancel, zero-pixel diff vs 31** |
| 34 | chess-club_34_matches_end.png | 168272 | Matches bottom, no create (Organizer) |
| 35 | chess-club_35_disclosure.png | 191845 | `Local package details` expanded |
| 36 | chess-club_36_disclosure_end.png | 152701 | package metadata, "No seed files recorded." |
| 37 | chess-club_37_identity.png | 251565 | role picker, radio on Organizer |
| 38 | chess-club_38_player_selected.png | 189305 | after tapping Player |
| 39 | chess-club_39_player_role.png | 216158 | banner still Organizer |
| 40 | chess-club_40_identity_recheck.png | 249284 | radio still Organizer |
| 41 | chess-club_41_identity_scrolled.png | 240854 | `Sign in as a specific person…` revealed |
| 42 | chess-club_42_player_retry.png | 215598 | row-label tap, still Organizer |
| 43 | chess-club_43_specific_person.png | 177007 | account picker "Welcome to Loom" |
| 44 | chess-club_44_create2.png | 167954 | Create New Account form |
| 45 | chess-club_45_persona2_name.png | 171097 | "Omar Player" entered |
| 46 | chess-club_46_roledrop2.png | 174546 | role dropdown open |
| 47 | chess-club_47_player_chosen.png | 169527 | role = Player |
| 48 | chess-club_48_persona2_in.png | 205588 | signed in as Omar Player / Player |
| 49 | chess-club_49_matches_player.png | 226435 | **`+` FAB present on Matches under Player** |
| 50 | chess-club_50_matches_create.png | 248350 | **`Record match` / `Propose match`** |
| 51 | chess-club_51_tabs_player.png | 229231 | Player tab bar ends at Messages |
| 52 | chess-club_52_tabs_player2.png | 229240 | repeat swipe, identical bar region |
| 53 | chess-club_53_calendar_player.png | 217237 | Calendar under Player, no FAB |
| 54 | chess-club_54_calendar_player_scroll.png | 154047 | scrolled, FAB zone still empty |
| 55 | chess-club_55_documents_player.png | 178713 | Documents under Player, read-only |
| 56 | chess-club_56_picker_player.png | 241786 | radio correctly on Player (`chess-member-21`) |
| 57 | chess-club_57_create3.png | 182286 | account list: Player, Organizer |
| 58 | chess-club_58_roledrop3.png | 189102 | role dropdown for persona 3 |
| 59 | chess-club_59_owner_chosen.png | 184350 | role = Owner |
| 60 | chess-club_60_owner_in.png | 180581 | signed in as Rita Owner, Admin tab present |
| 61 | chess-club_61_admin_owner.png | 192709 | **export controls under Owner** |
| 62 | chess-club_62_admin_owner2.png | 185085 | Owner Admin bottom, no dispute record |
| 63 | chess-club_63_picker3.png | 196288 | all three personas listed |
| 64 | chess-club_64_back_organizer.png | 188879 | switched back to Organizer |
| 65 | chess-club_65_admin_org2.png | 189157 | tab-bar mis-tap, retried |
| 66 | chess-club_66_admin_org3.png | 212091 | Admin as Organizer |
| 67 | chess-club_67_admin_fab.png | 242739 | **`New ranking row` / `New pairing queue`** |

67 files, 12,895,886 bytes total.

## Pipeline result

**PASS (with one product finding).** adb control held for the whole run; all 7 Organizer tabs visited with
primary and alternate affordances named on every one; the create form opened, was enumerated and cancelled
with a zero-pixel-diff return; six absences classified with per-role evidence; zero FATAL EXCEPTION / ANR
against two positive controls. One product finding recorded: the in-community role selector accepts a
selection it does not apply and gives no feedback.

## B25 coverage

### Provable now — local package rendering, no backend

- **Tab enumeration and horizontal tab-bar scroll**, including proof-of-end by identical-frame repeat.
- **Per-role tab visibility.** Admin present for Organizer and Owner, absent for Player.
- **Per-role affordance gating**, demonstrated in both directions rather than one: Organizer loses
  `Record match` / `Propose match`, Player loses `Schedule club night`, `Add rules document` and
  `Archive document`, and only Owner gets `Generate export` / `Change scope` / `Cancel export` / `New export`.
  A single-role pass would have recorded four of these as missing features.
- **Create-form field enumeration and clean cancel**, verified by pixel diff, not by eye.
- **Row-detail dialogs** on the Rankings grid (`Revise ranking`, `Retire ranking row`) and clean dismissal.
- **Speed-dial creates** on Matches (Player) and Admin (Organizer).
- **Multi-persona creation and switching** via the account picker — three accounts, three roles, correct
  role banner and correct picker radio for each after creation.
- **Stability under a 67-capture session** with three identity switches.

### Blocked, and why

- **Any workflow terminal state.** Nothing was submitted — the ticket required cancelling out of the create
  form, and no other action was committed. Transitions such as `Generate export`, `Assign pairing`,
  `Close queue` and `Record standings impact` are present and tappable but unexercised, so the write path
  and the resulting state change remain unproven here.
- **Member-state-dependent surfaces.** Documents reports *"Member state unavailable. Member state is
  available when connected to a community."* and shows `0 document actions`. Member-scoped behaviour needs
  the backend stack running; it cannot be proven in local mode.
- **Result disputes, end to end.** Not blocked by environment — blocked by the package. Two tab blurbs
  promise disputes; no seeded dispute record and no dispute create control exists under Organizer, Player
  or Owner. Nothing on this device can reach that state, so it stays unproven until the package seeds a
  dispute record or declares a create for one.
- **Role switching within one account.** The selector does not apply a different role (see the product
  finding), so per-role coverage can only be obtained by creating one account per role. That worked, and it
  is what was done, but it means the picker's own switching path is itself unproven.

## Independent verification (orchestrator, by eye)
`chess-club_61_admin_owner.png` pulled byte-identically to Windows and viewed: the Owner's Admin tab
renders the "Ready to export" record ("August ladder and match archive", "3 data groups", "Chess Owner",
"Ready to generate") with `Change scope` / `Generate export` / `Cancel export` and a labelled `New export`
FAB, exactly as reported. The Admin descriptor also reads "Pairing queues, result disputes, rankings, and
export controls. Tuned for Owner." — corroborating the disputes-gap finding. Owner persona and role
differentiation confirmed real.

## Refinement to the cross-community finding
Chess Club is **well-built**: primary+alternate affordances were found on every Organizer tab, and nearly
every absence is **role-gating** (proven by re-checking under Player/Owner), not unseeded. The only
package-side gap is **result disputes** (promised in tab blurbs, no seed, no create under any role). So the
"declared surface, no working affordance" pattern is **community-specific**, NOT a platform-wide flaw:
Cedar dues, Book Club messages, and Chess disputes are three discrete product-completeness gaps in three
packages — the workflow engine, role model, and surface rendering are sound (Chess exercises all three fully).
