# B25 agent-driven live walkthrough — Cedar Commons HOA (pipeline proof run)

**Date:** 2026-09-03
**Community:** Cedar Commons HOA — package `ext_cedar_commons_hoa` (read from the app's own
"Local package details" panel, accent `#285A7B`, card image "generated fallback",
"No seed files recorded.")
**Persona / role:** "CedarResident" → **Homeowner** ("2 roles" chip). Member card reads
"Homeowner - Pays dues, reads governing documents, reserves facilities, and submits property requests."
**Repo:** Loom `85ba3aa8`
**Device:** `emulator-5554`, 1080×2400, app `com.example.loom_communities_demo`

**adb path used:** agent shell → SSH reverse tunnel → adb server on `127.0.0.1:5037` → Windows-hosted
`emulator-5554`. Every command issued as `adb -s emulator-5554 ...`. `get-state` returned `device`
at the start of the run. No `kill-server` / `start-server` / `connect` / `disconnect` was issued and
`ANDROID_ADB_SERVER_ADDRESS`/`PORT` were never set; the tunnel was intact for the whole run.

## Per-tab affordances

| Tab | Primary affordance | Alternate affordance | Screenshot |
| --- | --- | --- | --- |
| Home | **"Open document"** — filled action on the pinned Cedar Commons CC&Rs card | **"Download document"** (also present: Acknowledge, Mark unread, Save document, Remove saved document, Request access, Withdraw access request, Share document) | `cedar_01_home.png`, `cedar_02_home_scroll.png`, `cedar_03_home_scroll2.png`, `cedar_16_home_tail.png` |
| Calendar | **"+ Reserve a facility"** — FAB, bottom-right | **"Save changes"** — inline edit on a reservation card (disabled, with helper text "No changes to save yet.") | `cedar_04_calendar.png`, `cedar_05_calendar_scroll.png`, `cedar_06_calendar_scroll2.png` |
| Giving | **NOT FOUND** — see finding below | **NOT FOUND** — no filter, no view toggle, no empty-state action | `cedar_07_giving.png`, `cedar_08_giving_top.png` |
| Documents | **"Open document"** — filled action on the Cedar Commons CC&Rs card | **"Download document"** (same nine-action set as Home) | `cedar_11_documents.png`, `cedar_12_documents_scroll.png` |

Home and Calendar render the same three reservation cards (Home is the pinned/unassigned union view):
"Cedar Commons annual HOA meeting" (Reserved, Cedar Clubhouse, 2026-09-28 18:30, Reminder: On),
"Clubhouse design meeting" (**Conflict** — "Overlaps the September board workshop from 18:00 to 20:00.",
2026-09-19 18:30, Reminder: Off), and "Pool House family gathering" (Reserved, Pool House,
2026-09-12 16:00, Reminder: On).

## Finding — the Giving surface renders no dues affordance at all

Ticket step 3 (tap the primary "pay dues / contribute" control) **could not be performed: the control
does not exist.** The Giving tab renders, top to bottom and with nothing below the fold:

1. the sponsored slot ("No sponsored message right now."),
2. the community header card,
3. the surface descriptor card — "Giving — HOA assessments, checkout status, offline payment records,
   and refund requests. Tuned for Homeowner.",
4. the "Local package details" expander.

There is no dues card, no assessment row, no FAB, and **no empty-state text or action** — the surface
simply ends. The persona is the entitled one: the surface says "Tuned for Homeowner" and the role
description says "Pays dues".

Controls run before recording this as absent (per the "a search that finds nothing is not evidence of
absence" rule):

- **Scrolled the surface to both ends** (`cedar_08_giving_top.png` is the true top, and the content
  ends above the nav bar) — this is the whole surface, not a scroll artifact.
- **Expanded "Local package details" on this very surface** (`cedar_09_giving_details.png`,
  `cedar_10_giving_details2.png`): it opened and reported `ext_cedar_commons_hoa` / "No seed files
  recorded." So the tab is live and rendering, not stalled.
- **The same rendering path works elsewhere in the same session:** Calendar rendered a FAB plus three
  workflow cards, Documents rendered a nine-action card. A surface with rows renders rows.
- **Taps register:** four tab switches and the expander toggle all produced visible change.
- **Checked Home's tail** (`cedar_16_home_tail.png`) — no dues/assessment card there either, so the
  affordance is absent app-wide for this persona, not merely misfiled onto another tab.

This narrows an earlier claim in `cedar-commons-hoa-local-walkthrough-2026-09-04.md`, which recorded
that "the four HOA workflows (dues/Giving, …) are all present in the rendered tab set." The Giving
**tab** is present; the dues **workflow** does not render on it. Tab presence is not workflow presence.

## Substitute form exercise (Calendar)

Because the Giving form was unreachable, the nearest equivalent was driven instead, to prove the agent
can open a create form and back out cleanly. Tapping "+ Reserve a facility" opened a **"Reserve a
facility"** dialog (`cedar_17_reserve_form.png`) with six fields — **Title, Facility, Event Date,
Event Time, Window, Location** — and **Cancel / Create** buttons. "Cancel" was tapped;
`cedar_18_after_cancel.png` shows the Calendar list restored with the same first card
("Cedar Commons annual HOA meeting"). **Nothing was submitted and no reservation was created.**

## CC&Rs document observation

The Documents card exposes the document as metadata chips: **"Cedar Commons CC&Rs"**,
**"Version 2025.3"**, **"Publication date 2025-11-18"**, **"Provider: Cedar Commons document
storage"**, **"Access: Available to all homeowners"**, followed by the text
"Member state unavailable. / Member state is available when connected to a community."

**"Open document" was tapped twice** (`cedar_13_ccrs_open.png`, `cedar_14_ccrs_open_immediate.png`,
`cedar_15_ccrs_open_after.png`). No viewer opened, no sheet or dialog appeared, no navigation
occurred, no snackbar was shown, and no chip changed state. The first tap only scrolled the list to
the card's top. So the document's *metadata* renders correctly and version/date/provider are all
present and readable, but the open action is inert in this local/offline mode — consistent with the
card's own "Member state unavailable" text. Recorded as an observation, not a crash.

## Stability

No ANR dialog, no crash, and no blank frame at any point. `mCurrentFocus` was
`com.example.loom_communities_demo/.MainActivity` at the start, after the CC&Rs taps, and after the
dialog cancel. `logcat` was alive (202 lines in a 200-line tail) while emitting **zero** lines from
the app's pid (3495) across a 2000-line tail — the app was quiet, not failing silently.

## Pipeline result

**The agent could drive the emulator and capture evidence end-to-end.** Over one unbroken session it
confirmed device state, visited all four tabs, scrolled each surface to its ends, expanded a
disclosure panel, opened a create form and cancelled it, tapped a document action, read `dumpsys` and
`logcat` for stability, captured 18 screenshots, and inspected every one before choosing the next tap.
The adb reverse-tunnel path held for the entire run with no resets. This clears the host-split blocker
recorded in `cedar-commons-hoa-local-walkthrough-2026-09-04.md`: agent-driven walkthroughs no longer
require `claude` on the Windows host.

One surface of four (**Giving**) yielded neither a primary nor an alternate affordance, and that is a
product finding rather than a rig failure — the rig reported it, with controls, instead of passing
over it.

## Independent verification (by the orchestrator, not the agent's report)
Screenshots `cedar_08_giving_top.png`, `cedar_17_reserve_form.png`, `cedar_09_giving_details.png` and
`cedar_11_documents.png` were pulled byte-identically to the Windows host and viewed directly:
- **Giving finding confirmed by eye.** The Giving tab renders the sponsored slot, the community header
  card, and the descriptor "HOA assessments, checkout status, offline payment records, and refund
  requests. Tuned for Homeowner." — and then ends. No dues card, no assessment row, no create control,
  no empty-state. The entitled "Pays dues" Homeowner has no way to pay dues. **This is a real product
  gap and blocks the Cedar B25 dues/assessment rows** (their affordances do not exist to prove).
- **Agent drive capability confirmed.** The "Reserve a facility" dialog shows the six fields
  (Title/Facility/Event Date/Event Time/Window/Location) with Cancel/Create exactly as reported.

**Pipeline milestone:** first-ever agent-driven live walkthrough, VM→(ssh reverse tunnel)→Windows
emulator, 18 screenshots, one real finding, verified independently. The host-split blocker is retired.
