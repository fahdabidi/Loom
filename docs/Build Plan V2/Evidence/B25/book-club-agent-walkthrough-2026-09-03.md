# Neighborhood Book Club — live agent walkthrough (B25 coverage pass)

- **Date:** 2026-09-03
- **Community:** Neighborhood Book Club (`ext_neighborhood_book_club`), card #2 of 10 on "Loom Communities"
- **Persona:** `Bea Reader` — **ID `book-member-20`**, role **Member** (the DEFAULT role offered by the
  signup form; accepted unmodified). Role description as rendered: *"Member - Nominates books, votes,
  RSVPs to meetings, discusses, borrows/lists shared items, and searches for reading context."*
- **Second persona (gating probe only):** `Ollie Organizer`, role **Organizer** — created solely to
  separate *role-gated* from *unseeded* on the empty surfaces (see "Absence classification").
- **adb path:** `emulator-5554` on the Windows host via SSH reverse tunnel to adb on 127.0.0.1:5037.
  `adb -s emulator-5554 get-state` = `device` throughout. Screen 1080x2400. No `kill-server` /
  `start-server` / `connect` / `disconnect` issued; tunnel intact for the whole run.

## Tab set is role-dependent

The bottom tab bar **scrolls horizontally** — the first frame shows only four tabs, which reads as the
complete set and is not. Swiping the bar revealed the rest.

| Role | Tabs (in bar order) | Count |
| --- | --- | ---: |
| Member (`Bea Reader`) | Home, Calendar, Marketplace, Books, Documents, Discussions, Messages | 7 |
| Organizer (`Ollie Organizer`) | Home, Calendar, Marketplace, **Admin**, Books, Documents, Discussions, Messages | 8 |

Confirmed the bar was at its end by byte-identical screenshots across two further swipes
(`book-club_09` = `book-club_11`, md5 `4c4032ff…`) rather than by assuming four tabs was all.

## Per-tab affordances — persona `Bea Reader` / Member

| Tab | PRIMARY affordance (exact label) | ALTERNATE affordance (exact label) | Screenshot |
| --- | --- | --- | --- |
| Home | FAB **"Cast a vote"** | **"Unmute"** (notification control on a discussion card) | `book-club_05_after_signup.png`, `book-club_08_home_end.png` |
| Calendar | **"Going"** (RSVP, emphasized) | **"Add my reminder"**; also view toggle **"Day" / "Week" / "Month" / "Pending"** | `book-club_27_calendar.png`, `book-club_28_calendar_scroll.png` |
| Marketplace | FAB **"List an item"** | search field **"Search available items"** | `book-club_29_marketplace.png` |
| Books | FAB **"+"** (icon only, no text label) | **"Save digest"**; also **"Add citation"** | `book-club_12_books.png`, `book-club_13_books_scroll.png` |
| Documents | **"Acknowledge"** (filled/emphasized) | **"Download"**; also "Request access", "Mark unread", "Save" | `book-club_14_documents.png`, `book-club_15_documents_end.png` |
| Discussions | FAB **"New thread"** | **"Reply"**; also "Mark read", "Mute" | `book-club_17_discussions.png`, `book-club_18_discussions_scroll.png` |
| Messages | **NOT FOUND** — see below | **NOT FOUND** — see below | `book-club_21_messages.png`, `book-club_23_messages_top.png` |

Distinct RSVP labels were read on word boundaries, not by substring: "Going", "Maybe" and
"Not attending" are three separate controls; "Not attending" was **not** counted as an instance of
"attending".

Organizer-only tab, recorded for completeness: **Admin** — *"Role-specific publishing, approvals, and
operations. Tuned for Organizer."* Primary = FAB **"+"**; content is nomination approval cards
(`Submitted` / Circe / Cycle: September 2026). Screenshot `book-club_43_org_admin.png`.

## Create-form observation (step 3)

Tapped the **"New thread"** FAB on Discussions — the clearest labelled create control available to
the Member persona.

- Dialog title: **"New thread"**
- Fields: **one** — `Prompt` (single-line text input)
- Buttons: **"Cancel"**, **"Create"**
- Screenshot: `book-club_19_newthread_form.png`

Dismissed with **Cancel**; nothing submitted. Verified the cancel was clean rather than assumed: the
post-cancel frame is **byte-identical** to the pre-dialog frame (`book-club_20_after_cancel.png` and
`book-club_18_discussions_scroll.png`, both 133,501 bytes), so no thread was created.

## Absence classification — surfaces with no create affordance

Each of these was checked against "a search that finds nothing is not evidence of absence" **before**
being recorded: scrolled to both ends, expanded the "Local package details" disclosure, confirmed taps
register elsewhere on the same surface, then re-checked the surface under the *other* role.

| Surface | Missing for Member | Verdict | Evidence |
| --- | --- | --- | --- |
| Documents — create | no FAB at all | **Role-gated** | Under Organizer the same tab renders FAB **"Add reading material"** (`book-club_39_org_documents.png`). The control exists; Member cannot see it. |
| Calendar — create event | no FAB at all | **Role-gated** | Under Organizer the same tab renders FAB **"New meeting"** (`book-club_45_org_calendar_scroll.png`). Matches the Organizer charter "manages meetings". |
| Messages — everything | no FAB, no cards, no empty-state action | **Unseeded AND unwritable — no create affordance under EITHER role** | Empty for Member (`book-club_23_messages_top.png`) *and* for Organizer (`book-club_41_org_messages_scroll.png`). Not role-gating. |

Checks run before calling Messages empty, so the empty is a measured result and not a missed control:

1. Scrolled to the top and to the bottom of the tab — content is only the identity card, the
   "Messages" section header, and the collapsed "Local package details" panel. Nothing between them.
2. Expanded the "Local package details" disclosure — it opens and renders `Package
   ext_neighborhood_book_club` / `Accent` (`book-club_16_documents_disclosure.png` shows the same
   panel opening on a sibling tab), so taps on this surface do register.
3. Tapped the app-bar chat icon in case compose lived there — it merely routes to the Messages tab
   and is not a compose control (`book-club_24_appbar_chat.png`).
4. Re-checked the whole tab as Organizer — still empty.

**Product finding.** The Messages surface advertises *"Messages and connections with other members"*
and neither of the community's two roles can start one: there is no compose control, no seeded
conversation, and no empty-state call to action. Both halves are missing at once, so this cannot be
dismissed as "just unseeded" — an unseeded surface with a writer would still show its create control.

**Secondary finding — silent no-op in the role picker.** "Account role and permissions" lists both
Member and Organizer as selectable radio options for a persona holding only the Member membership.
Selecting **Organizer** closes the dialog and changes nothing; the identity card still reads "Member"
(`book-club_32_role_switched.png`). The dialog's own text says memberships determine availability, so
refusing is defensible — doing it silently, with the unavailable option rendered identically to the
available one, is not. Switching role required creating a second account through
"Sign in as a specific person…" → Create New Account → Role: Organizer. The seeded `book-organizer`
identity referenced in discussion and RSVP data is **not** offered in that picker
(`book-club_33_specific_person.png`).

## Stability

- No ANR, no crash dialog, no blank frame at any point in the run.
- `adb -s emulator-5554 shell dumpsys window | grep mCurrentFocus` =
  `Window{4f2e833 u0 com.example.loom_communities_demo/com.example.loom_communities_demo.MainActivity}`
  at start and at end — focus never left the app.
- logcat swept for `FATAL EXCEPTION`, `ANR in`, `Force finishing`: **zero matches**. Control run
  alongside it (406 log lines present, `grep -c .` = 406) so the empty result is a real absence and
  not a broken query.

## Screenshots

45 frames, `/tmp/book-club_*.png` (transient — `*.png` is gitignored; this manifest is the durable
record).

| File | Bytes | File | Bytes |
| --- | ---: | --- | ---: |
| book-club_01_list.png | 316611 | book-club_24_appbar_chat.png | 228231 |
| book-club_02_card.png | 123358 | book-club_25_roles.png | 252468 |
| book-club_03_name.png | 177659 | book-club_26_tabbar_start.png | 227411 |
| book-club_04_signup_ready.png | 127091 | book-club_27_calendar.png | 236072 |
| book-club_05_after_signup.png | 250184 | book-club_28_calendar_scroll.png | 180222 |
| book-club_06_home_scroll1.png | 193289 | book-club_29_marketplace.png | 249140 |
| book-club_07_home_scroll2.png | 190582 | book-club_30_organizer.png | 249263 |
| book-club_08_home_end.png | 197517 | book-club_31_roledialog2.png | 256357 |
| book-club_09_tabbar_scroll.png | 197014 | book-club_32_role_switched.png | 249269 |
| book-club_10_tabbar_scroll2.png | 197014 | book-club_33_specific_person.png | 115159 |
| book-club_11_tabbar_end.png | 197014 | book-club_34_role_dropdown.png | 118285 |
| book-club_12_books.png | 234650 | book-club_35_organizer_signup.png | 120586 |
| book-club_13_books_scroll.png | 180627 | book-club_36_organizer_home.png | 239159 |
| book-club_14_documents.png | 255880 | book-club_37_org_tabs.png | 236698 |
| book-club_15_documents_end.png | 126561 | book-club_38_org_tabs2.png | 236967 |
| book-club_16_documents_disclosure.png | 150655 | book-club_39_org_documents.png | 270519 |
| book-club_17_discussions.png | 252043 | book-club_40_org_messages.png | 205547 |
| book-club_18_discussions_scroll.png | 133501 | book-club_41_org_messages_scroll.png | 203688 |
| book-club_19_newthread_form.png | 41311 | book-club_42_org_tabstart.png | 204247 |
| book-club_20_after_cancel.png | 133501 | book-club_43_org_admin.png | 240982 |
| book-club_21_messages.png | 201973 | book-club_44_org_calendar.png | 244147 |
| book-club_22_messages_down.png | 201543 | book-club_45_org_calendar_scroll.png | 174993 |
| book-club_23_messages_top.png | 228229 | | |

## Pipeline result

**PASS with one product finding.** The rig drove a real emulator end-to-end against a fourth community
type: community list → identity gate → account creation at the default role → community entry → all 7
Member tabs → create-form open and cancel → role-differential re-check across all 8 Organizer tabs. No
crash, no ANR, no blank frame, no adb tunnel loss. 6 of 7 Member tabs expose both a primary and an
alternate affordance; Messages exposes neither, under either role.

## B25 coverage

**Provable now from this run** — surfaces where a live affordance was observed, named and reachable by
a real persona on a real device:

- Home: ballot/vote entry (`Cast a vote`) and per-thread notification control (`Unmute`).
- Calendar: full RSVP triad (`Going` / `Maybe` / `Not attending`), member reminder (`Add my reminder`),
  view toggles (`Day`/`Week`/`Month`/`Pending`), capacity rendering (`1 / 20 going`, `19 seats left`).
- Marketplace: item listing create (`List an item`) and item search (`Search available items`).
- Books: nomination/ballot surface with `Save digest`, `Add citation`, editable ballot fields with a
  correctly-disabled `Save changes` ("No changes to save yet.").
- Documents: acknowledgement and access-request lifecycle (`Acknowledge`, `Download`, `Record open`,
  `Mark unread`, `Save`, `Remove saved material`, `Request access`, `Withdraw access request`).
- Discussions: thread create (`New thread`, one field `Prompt`), `Reply`, read-state and mute controls.
- Role differentiation: the tab set and the create affordances genuinely differ by role — Organizer
  gains `Admin`, `Add reading material` and `New meeting`. This is proven by observation under both
  roles, not inferred from the package.

**Blocked, and why:**

- **Any Messages/DM row — blocked, product-side.** No create affordance and no seeded instance under
  either role. Not an environment or harness limitation; the surface has no writer to exercise.
- **Rows requiring a *submitted* create.** Every create form here was opened and cancelled per ticket
  instruction, so create-to-terminal-state paths (thread published, item listed, vote recorded) are
  proven *reachable* but not proven *to complete*.
- **Rows requiring the seeded `book-organizer` identity.** That account is referenced in seeded data
  (discussion author, RSVP `Going`) but is not offered in the identity picker; the Organizer probe
  used a newly created account, so any row keyed to the seeded organizer's own history is unproven.
- **Backend-dependent rows.** This was a local-package run — the Documents surface reports
  *"Member state unavailable. Member state is available when connected to a community."*, so
  server-side member-state rows cannot be closed from this evidence.

## Independent verification (orchestrator, by eye — not the agent's report)
Pulled byte-identically to Windows and viewed directly:
- **`book-club_23_messages_top.png`** — Messages tab (Member) confirmed empty: descriptor "Messages and
  connections with other members" and then nothing — no list, no compose FAB, no empty-state. Finding real.
- **`book-club_43_org_admin.png`** — confirmed role differentiation: signed in as Ollie **Organizer**, an
  **Admin** tab is present (absent for Member), rendering a "Submitted" nomination approval card
  (Circe / by Madeline Miller / Cycle: September 2026) with a "+" FAB. The agent's self-directed
  two-persona method (Member vs Organizer) genuinely distinguishes role-gated from unseeded.

**Cross-community pattern (2 of 2 rigorous walkthroughs so far):** a declared surface renders its
descriptor but no working affordance for any persona — Cedar **Giving/dues** (unseeded + board-only
create + payment "NEEDS IMPLEMENTATION") and Book Club **Messages** (no writer, no seed, under either
role). This is shaping into the central B25 product finding: some rows are unprovable not because the
rig can't reach them but because the capability isn't built/seeded. Tracking systemically across the grind.
