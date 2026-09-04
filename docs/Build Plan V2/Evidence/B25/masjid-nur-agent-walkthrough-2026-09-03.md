# B25 agent-driven live walkthrough — Masjid Nur (coverage pass)

**Date:** 2026-09-03
**Community:** Masjid Nur — package `ext_mosque` (read from the app's own "Local package details"
panel: accent `#2E7D5B`, card image "generated fallback", "No seed files recorded.")
**Repo:** Loom `85ba3aa8`
**Device:** `emulator-5554`, 1080×2400, Android 16, app `com.example.loom_communities_demo`

**Personas / roles**

| # | Display name | Role | Account ID | How created |
| --- | --- | --- | --- | --- |
| 1 | Amina Walkthrough | **Masjid Admin** (the DEFAULT selection — pre-selected in the Role dropdown, accepted unchanged) | `masjid-admin-20` | Create New Account → Sign Up from the community entry gate |
| 2 | Yusuf Member | **Community Member** | not surfaced in this run | AppBar identity picker → "Sign in as a specific person…" → Create New Account with Role switched to Community Member |

The role dropdown offers exactly **two** roles: "Masjid Admin" and "Community Member"
(`masjid-nur_04_roles.png`). Persona 1's member card reads *"Admin - Publishes trusted updates,
coordinates events and volunteers, records donations, and reviews protected care requests."*
Persona 2's reads *"Member - Reads updates, RSVPs, gives, volunteers, uses resources, joins
discussions, and requests care."* Both show the "2 roles" chip.

**adb path used:** agent shell → SSH reverse tunnel → adb server on `127.0.0.1:5037` → Windows-hosted
`emulator-5554`. Every command issued as `adb -s emulator-5554 …`. `get-state` returned `device` at
the start of the run. No `kill-server` / `start-server` / `connect` / `disconnect` / `-a` was issued
and `ANDROID_ADB_SERVER_ADDRESS`/`PORT` were never set; the tunnel was intact for the whole run.

## The bottom tab bar scrolls — four tabs is not all of them

The bar shows four tabs at rest. Swiping it left revealed two more. A second identical swipe returned
a **byte-identical frame** (`masjid-nur_09_tabbar_a.png` and `masjid-nur_10_tabbar_b.png` share md5
`f8d3de4226432ca0fd7fe549c6176c2d`), which is how the end of the bar was established rather than
assumed.

- **Persona 1 (Masjid Admin) — 6 tabs:** Home, Calendar, Giving, Admin, Resources, Messages.
- **Persona 2 (Community Member) — 5 tabs:** Home, Calendar, Giving, Resources, Messages.
  **The Admin tab is absent**, confirmed by scrolling the bar to both ends under persona 2
  (`masjid-nur_33_p2_home.png` = right end, `masjid-nur_35_p2_tabbar.png` = left end, with the
  repeat swipe again byte-identical, md5 `2723a3f8f349744f255cab047784c922`).

## Per-tab affordances — persona 1 (Masjid Admin)

| Tab | Primary affordance | Alternate affordance | Screenshot |
| --- | --- | --- | --- |
| Home | **"Approve and assign"** — filled action on the "Submitted for private review" care-request card | **"Reject request"** (also present: "Request changes") | `masjid-nur_06_home.png`, `masjid-nur_07_home_scroll1.png`, `masjid-nur_08_home_scroll2.png` |
| Calendar | **"+ New event"** — labelled FAB, bottom-right | **"Close signup"** (also present: "Record coordinator follow-up", "Save changes" — disabled with helper text "No changes to save yet.") | `masjid-nur_11_calendar.png`, `masjid-nur_12_calendar_s1.png`, `masjid-nur_12_calendar_s2.png` |
| Giving | **NOT FOUND** — see the absence classification below | **NOT FOUND** — no FAB, no card action, no empty-state control | `masjid-nur_13_giving.png`, `masjid-nur_14_giving_s1.png`, `masjid-nur_16_giving_bottom.png` |
| Admin | **"+"** — unlabelled speed-dial FAB expanding to **"New announcement"** and **"New volunteer shift"** | **"Approve and assign"** (also present: "Request changes", "Reject request") | `masjid-nur_17_admin.png`, `masjid-nur_18_admin_top.png`, `masjid-nur_20_admin_fab.png` |
| Resources | **"+"** — unlabelled speed-dial FAB expanding to **"Ask Masjid Nur"** and **"Add resource"** | **"Refine query"** (also present: "Save answer", "Hide source", "Report stale citation", "Open embedded", "Open externally") | `masjid-nur_23_resources.png`, `masjid-nur_24_resources_fab.png`, `masjid-nur_25_resources_s1.png` |
| Messages | **"+ New discussion"** — labelled FAB, bottom-right | **"Reply"** (also present: "Mute thread", "Unmute thread", "Archive thread") | `masjid-nur_26_messages.png`, `masjid-nur_27_messages_s1.png` |

Note on the two unlabelled FABs: the Admin and Resources FABs render as a bare **"+"** with no text.
Their labels exist only *after* the tap that expands the speed dial. The exact label text above was
read from the expanded state, not guessed from the icon.

## Per-tab affordances — persona 2 (Community Member), partial

Persona 2 was created to classify the Giving absence, so its sweep is deliberately narrow. What was
observed:

| Tab | Primary affordance | Screenshot |
| --- | --- | --- |
| Home | **"+ Request care"** — labelled FAB (absent for persona 1) | `masjid-nur_33_p2_home.png` |
| Giving | **"+ Donate"** — labelled FAB (absent for persona 1) | `masjid-nur_34_p2_giving.png` |
| Admin | tab does not exist for this role | `masjid-nur_35_p2_tabbar.png` |

Calendar, Resources and Messages were **not** re-swept under persona 2; no claim is made about their
persona-2 affordances.

## Create-form observation — "New announcement" (Admin, persona 1)

Route: Admin tab → "+" FAB → **"New announcement"**.

The form is a dialog titled **"New announcement"** (`masjid-nur_21_create_form.png`) with **five
fields**, all empty on open:

1. Title
2. Body
3. Audience
4. Channel
5. Scheduled

Buttons: **Cancel** and **Create**.

**Cancel** was tapped. **Nothing was submitted.**

**Clean-cancel verification.** The pre-frame (`masjid-nur_19_admin_pre.png`, captured immediately
before the FAB tap) and the post-cancel frame (`masjid-nur_22_admin_post_cancel.png`) were compared
pixel-by-pixel with PIL. Cropping away the status bar (`y ≥ 110`), `ImageChops.difference().getbbox()`
returned **`None`** — the two frames are byte-for-byte identical below the status bar. The only
whole-frame difference is bounded to `(155, 47, 966, 80)`, which is the status-bar clock ticking from
11:17 to 11:18. Scroll position, FAB collapsed state, and card list all returned exactly as they were,
and no new announcement card appeared.

## Absence classification

Only one surface produced no affordance for its persona. It is **role-gated**, and the proof is a
control appearing under a different role on the same surface in the same session.

| Surface | Persona 1 (Masjid Admin) | Persona 2 (Community Member) | Classification | Proof |
| --- | --- | --- | --- | --- |
| **Giving tab** | No FAB, no card action, no empty-state control | **"+ Donate"** FAB present | **Role-gated** (member-gated, not admin-gated) | The identical tab renders a create control the moment the acting role changes — `masjid-nur_16_giving_bottom.png` vs `masjid-nur_34_p2_giving.png` |
| **Admin tab** | Present, with speed-dial FAB and three review actions | Tab is absent from the bar entirely | **Role-gated** | Bar scrolled to both ends under persona 2; six tabs become five |
| **Home "+ Request care"** | Absent | Present | **Role-gated** | `masjid-nur_06_home.png` vs `masjid-nur_33_p2_home.png` |

**Controls run on the Giving tab before recording it as absent** (per "a search that finds nothing is
not evidence of absence"):

- **Scrolled to both ends.** Three consecutive downward swipes produced three byte-identical frames
  (`masjid-nur_14_giving_s1/s2/s3.png`, all md5 `305ffab6d01f3c1452b4bf1699cc783b`), establishing the
  true bottom rather than assuming it. The top was re-checked in `masjid-nur_13_giving.png`.
- **Expanded the disclosure on that very surface.** Tapping "Local package details" flipped the
  chevron and revealed Package `ext_mosque` / Accent `#2E7D5B` / Card image "generated fallback" /
  "No seed files recorded." (`masjid-nur_15_giving_disclosure.png`, `masjid-nur_16_giving_bottom.png`).
  So the tab is live and rendering, not stalled — and **taps register on it**.
- **The surface is not empty.** It renders a full donation record for persona 1: "Paid — manually
  recorded", Amount `$ 50`, Fund "Community iftar meals", Privacy "Restricted", "Recorded paid
  2026-08-10T12:00:00-07:00", Status "Paid Manual", a receipt line, and a two-entry payment history
  (`intent-submitted` by community-member, `offline-payment-recorded` by masjid-admin). This rules out
  "unseeded" — there is data, and still no control.
- **The same rendering path works elsewhere in the same session.** Calendar, Admin, Resources and
  Messages each rendered a FAB under the same persona.

**A second observation on the Giving tab, reported as observed and not as a proven mechanism:** under
persona 2 the seeded donation card is **not visible at all** — the surface goes header → "Local
package details" with no record between them. The record carries "Privacy: Restricted". That is
consistent with per-record privacy scoping, but this run did not exercise the mechanism, so it is
recorded as a rendering difference, not as proof of how privacy is enforced.

## Stability

- **No crash, no ANR, no blank frame** was observed across 41 captures and roughly 12 minutes of
  driving.
- `mCurrentFocus` was `com.example.loom_communities_demo/.MainActivity` at both the start and the end
  of the run — the app never lost focus to a system dialog, and no system dialog ever overlaid the UI.
- **logcat sweep, with controls.** `FATAL EXCEPTION` = **0**; `ANR in` = **0**. Those zeros are load-
  bearing only because the controls returned non-zero in the same pipeline: the `main`+`crash` buffers
  held **89,353 lines**, of which **564** mention `loom_communities_demo`. `grep -a` was used
  throughout (dispatch/logcat output is binary-ish and an un-`-a`'d grep silently reports 0 matches).
- **`/data/anr/` was checked directly rather than trusted to logcat.** It does contain ANR traces, but
  the newest is `anr_2026-09-03-20-03-56-896`, and the device clock read `Thu Sep 3 23:25:04 PDT 2026`
  at the end of this run, which began at 23:12. **Every ANR file predates this walkthrough by over
  three hours.** None was produced by it.
- The dedicated `crash` buffer is **completely empty (0 lines)**, so "0 matches for our package there"
  proves nothing on its own; the `main`-buffer control above is the evidence that carries.

## Screenshot index

All captures are 1080×2400 PNG, written to `/tmp/` on the agent host. **`*.png` is gitignored, so
these files are transient — this manifest is the durable artifact.** 41 files, 8,082,523 bytes total.

| File | Bytes | What it shows |
| --- | ---: | --- |
| `masjid-nur_01_list.png` | 315,727 | "Loom Communities" list, "Loaded 10 example communities" |
| `masjid-nur_02_open.png` | 119,737 | Community entry gate, "Welcome to Loom" |
| `masjid-nur_03_name.png` | 186,243 | Display name "Amina Walkthrough" entered |
| `masjid-nur_04_roles.png` | 131,389 | Role dropdown: Masjid Admin (default, highlighted) / Community Member |
| `masjid-nur_05_predsignup.png` | 125,838 | Pre-Sign Up state, default role intact |
| `masjid-nur_06_home.png` | 230,564 | Home, persona 1 signed in, 4 tabs at rest |
| `masjid-nur_07_home_scroll1.png` | 194,283 | Home — Request changes / Approve and assign / Reject request |
| `masjid-nur_08_home_scroll2.png` | 204,873 | Home — care notice, volunteer signup card |
| `masjid-nur_09_tabbar_a.png` | 206,845 | Tab bar swiped left: Giving, Admin, Resources, Messages |
| `masjid-nur_10_tabbar_b.png` | 206,845 | Repeat swipe — byte-identical, end of bar proven |
| `masjid-nur_11_calendar.png` | 257,346 | Calendar + "+ New event" FAB |
| `masjid-nur_12_calendar_s1.png` | 183,369 | Calendar — shift detail, Capacity 6, Volunteers 1 |
| `masjid-nur_12_calendar_s2.png` | 197,524 | Calendar — Record coordinator follow-up / Close signup |
| `masjid-nur_13_giving.png` | 245,800 | Giving top, persona 1 — no FAB |
| `masjid-nur_14_giving_s1.png` | 171,658 | Giving bottom (1 of 3 identical) |
| `masjid-nur_14_giving_s2.png` | 171,658 | Giving bottom (2 of 3 identical) |
| `masjid-nur_14_giving_s3.png` | 171,658 | Giving bottom (3 of 3 identical) — end proven |
| `masjid-nur_15_giving_disclosure.png` | 193,732 | "Local package details" expanded — taps register |
| `masjid-nur_16_giving_bottom.png` | 145,164 | Giving true bottom, `ext_mosque`, no seed files |
| `masjid-nur_17_admin.png` | 194,909 | Admin tab, "+" FAB, three review actions |
| `masjid-nur_18_admin_top.png` | 239,873 | Admin top, surface descriptor |
| `masjid-nur_19_admin_pre.png` | 239,873 | **Create-test pre-frame** |
| `masjid-nur_20_admin_fab.png` | 261,035 | Speed dial: New volunteer shift / New announcement |
| `masjid-nur_21_create_form.png` | 58,960 | **"New announcement" form** — 5 fields, Cancel/Create |
| `masjid-nur_22_admin_post_cancel.png` | 240,501 | **Create-test post-frame** — identical below status bar |
| `masjid-nur_23_resources.png` | 250,166 | Resources tab, "+" FAB |
| `masjid-nur_24_resources_fab.png` | 275,256 | Speed dial: Ask Masjid Nur / Add resource |
| `masjid-nur_25_resources_s1.png` | 199,294 | Resources — Refine query / Save answer / Hide source / Report stale citation |
| `masjid-nur_25_resources_s2.png` | 163,435 | Resources — further scroll |
| `masjid-nur_26_messages.png` | 210,699 | Messages tab, "+ New discussion" FAB |
| `masjid-nur_27_messages_s1.png` | 201,027 | Messages — Reply / Mute thread / Unmute thread / Archive thread |
| `masjid-nur_27_messages_s2.png` | 227,260 | Messages — further scroll |
| `masjid-nur_28_identity.png` | 258,002 | "Account role and permissions" picker, ID `masjid-admin-20` |
| `masjid-nur_29_specific_person.png` | 173,956 | Account picker, Pending & Invites, Create New Account |
| `masjid-nur_30_p2_form.png` | 178,794 | Persona 2 name entered |
| `masjid-nur_31_p2_roledd.png` | 184,082 | Persona 2 role dropdown open |
| `masjid-nur_32_p2_ready.png` | 180,149 | Persona 2 role = Community Member |
| `masjid-nur_33_p2_home.png` | 203,760 | Persona 2 Home, "+ Request care" FAB, **no Admin tab** |
| `masjid-nur_34_p2_giving.png` | 162,149 | **Persona 2 Giving with "+ Donate" FAB** — the role-gate proof |
| `masjid-nur_35_p2_tabbar.png` | 159,545 | Persona 2 bar at left end: Home, Calendar, Giving, Resources |
| `masjid-nur_35b_p2_tabbar.png` | 159,545 | Repeat swipe — byte-identical, 5 tabs confirmed |

## Pipeline result

**The rig works end to end on Masjid Nur.** A single agent shell drove a Windows-hosted emulator over
the SSH/adb tunnel through: community list → entry gate → account creation at the default role → six
tabs including two only reachable by scrolling the tab bar → a create form opened and cancelled with
pixel-proven cleanliness → a second persona created at a different role → a role-gated control
observed appearing. No manual intervention, no tunnel resets, no crashes.

Two rig properties are worth carrying forward:

- **Byte-identical-frame comparison is the cheap end-of-scroll oracle**, and it settled three separate
  questions here (tab-bar end for both personas, Giving bottom). It is stronger than "it looked like
  the end".
- **Pixel-diffing a cancel** turns "the form closed" into "nothing changed", which is the claim the
  ticket actually wants. Cropping the status bar first is required — the clock alone breaks md5.

## B25 coverage

**Provable now from this run:**

- Masjid Nur's tab set, both roles, with the end of the tab bar proven rather than assumed
  (6 tabs admin / 5 tabs member).
- Primary and alternate affordances with exact label text for **all 6** persona-1 tabs — 5 of 6 with a
  real control, 1 (Giving) proven affordance-free for that role.
- One create form fully characterised (New announcement: 5 fields) and a clean, pixel-verified cancel.
- Role-gating demonstrated on three distinct surfaces (Giving FAB, Admin tab, Home "Request care" FAB)
  by direct A/B against a second persona in the same session.
- Stability: 0 FATAL EXCEPTION, 0 ANR, with passing controls, and `/data/anr/` timestamps checked
  against the device clock rather than assumed.

**Blocked, and why:**

- **Nothing here proves a backend row.** This is a local-mode run: "Local package details" reports
  `ext_mosque` with **"No seed files recorded."**, and no request was made against app-access,
  fan-passport or the workflow service. Every observation is of the **rendered UI**. Per the standing
  rule that an assertion against engine state proves a different thing than the rendered UI, the
  converse holds too — these frames cannot stand in for a row-level assertion.
- **No workflow was advanced to a terminal state.** Every create/act control was identified and, where
  exercised, explicitly cancelled. So "the control exists and opens a well-formed form" is proven;
  "submitting it writes and the workflow reaches a live end" is not.
- **Persona 2's Calendar, Resources and Messages tabs were not swept.** Persona 2 existed to classify
  the Giving absence. Their member-role affordances are unknown, not absent.
- **The UX judge and the live-verification walkthrough have not been run** against these frames. This
  is a coverage/affordance map, not the B25 addendum's paired proof (live walkthrough *and* UX judge)
  for any of the 79 rows.

## Independent verification (orchestrator, by eye)
`masjid-nur_13_giving.png` pulled byte-identically and viewed: the Admin's Giving tab renders a seeded
"Paid — manually recorded" donation record (Amount: $50, Fund: Community iftar meals, Privacy:
Restricted, Recorded paid 2026-08-10T12:00:00-07:00) — real seeded data, no create control. Confirms
the agent's role-gated classification: Members create donations ("+ Donate"), Admins review them.

## Correction to the cross-community finding
Masjid Nur is **well-built with ZERO genuine surface gaps** — every absence (Giving-create, Admin tab,
Home "Request care") is **role-gating**, proven under a second persona, with real seeded data present.
This CORRECTS an over-hasty read that "Giving is empty in two communities": Masjid Nur's Giving is
fine. The refined, accurate tally across 4 rigorous walkthroughs — each community has AT MOST ONE
genuine, isolated single-surface gap, and the gaps are distinct, not a class:
- **Cedar** — dues surface empty (unseeded + board-only create + payment "NEEDS IMPLEMENTATION").
- **Book Club** — Messages surface empty (no writer/seed/empty-state under either role).
- **Chess** — disputes surface empty (promised, no seed, no create under any role).
- **Masjid Nur** — none; fully role-differentiated with seeded data.
The common thread for Cedar/Chess is **seeding**: a declared workflow with no seeded instance whose
create is gated to a role the walkthrough persona isn't. Book Club Messages is the one true "no writer"
gap. This is package-completeness, community-specific — the engine/roles/rendering are sound.
