# UX judge verdict — Garden Club, `garden-tool-loan` — B25 row

**Workflow:** `garden-tool-loan` in Garden Club (`community_garden_club`)
**Verdict:** PASS
**Judged:** 2026-09-09, model `fable`, against 15 frames from the same-day live walkthrough
**Walkthrough manifest:** `fe0ce6af` — evidence/b25-garden-tool-loan-20260909/manifest.md
**Frames:** gitignored and not committed; this verdict is the durable record of what they showed.


- **Judged:** 2026-09-09, against the 15 judge-relevant frames itemised in `manifest.md` (all viewed).
- **Verdict: PASS.** Both B25 affordances are visibly present and comprehensible to the
  `garden-member` persona, and the regression claim this run existed for is confirmed from pixels.

## The regression check — confirmed from frame 42, corroborated by frame 41

Frames `41-owner-detail.png` (sheet top) and `42-owner-actions-scrolled.png` (sheet end) together
cover the complete owner detail sheet for the `published`/`available` listing "LoomB25Spade". The
sheet is: title → data chips → "Queue length: 0" / "You are not queued." → action buttons → Close.
No action exists above the chip list, so the two frames jointly show the **entire** action set:

1. **Pause listing**
2. **Report issue**
3. **Delist** (rendered red/destructive)

**"Join queue" is not shown anywhere on either frame.** "Request loan" and "Leave queue" are also
absent. The 2026-09-08 defect (owner offered "Join queue" on their own available listing) is not
present in this build's frames. This matches the walkthrough's account exactly.

## B25 bar

- **Primary affordance:** "List a tool to loan" (speed-dial entry, frame 32) → create form titled
  "List a tool to loan" with a **Create** button (frames 33, 39). Plain-language, unambiguous for a
  member persona.
- **Alternate/change/reject affordance:** **Delist** (destructive terminal action) and **Pause
  listing** (change), both on frames 41/42.
- Word-boundary discipline: "Delist" does not word-boundary-match "list"; the primary span
  ("List a tool to loan", frame 32/33) and the alternate spans ("Delist", "Pause listing", frame 42)
  are distinct UI elements on distinct frames — no span is double-counted.

## Frame-by-frame agreement with the manifest

| Frame | Claim | Verdict from pixels |
|---|---|---|
| 16 | gate states `LoomAuthNotLoggedInException`, "Continue to secure sign-in" present | confirmed |
| 17 | in-app "Sign in to Loom" interstitial | confirmed |
| 20 | real Keycloak form at `192.168.56.10:30082`, fields empty | confirmed — form demanded credentials, no silent SSO re-issue |
| 26 | username `loom-garden-member-1` character-exact | confirmed |
| 27 | password typed before submit | confirmed (visible cleartext, test credential) |
| 28 | account list grouped by role; "Garden Member 1 / ID: fan-garden-member-1" | confirmed |
| 29 | **entry** — inside Garden Club, "Signed in as Garden Member 1", role Member, 4 tabs | confirmed |
| 31 | Marketplace with one pre-existing card, create FAB | confirmed |
| 32 | speed dial: "List a tool to loan" + "Give away a garden item" | confirmed |
| 33 | empty create form, nine fields | confirmed (Title, Tool Description, Coordinator Fan Id, Owner Contact Info, Condition Note, Loan terms, Pickup instructions, Return instructions, Tool care) |
| 39 | **action** — four required fields filled: `LoomB25Spade`, `SteelDiggingSpade`, `fan-garden-coordinator-1`, `owner5551234` | confirmed |
| 40 | **result** — new card "Loom B25 Spade", Availability: Available | confirmed |
| 41 | owner sheet top | confirmed |
| 42 | **regression** — exactly Pause listing / Report issue / Delist; no "Join queue" | **confirmed** |
| 43 | **terminal** — no action buttons (only Close), Availability chip gone | confirmed |

## What the frames cannot prove (not claimed)

The database row, its `created_by_fan_id`, the `sha256` of the package, and the causal link between
the Delist tap and the state change are the walkthrough's claims, verified by it against the row;
the frames only bracket them (owner sheet with actions at 10:47 → same sheet actionless at 10:48).
I judged pixels only.

## Observations (none blocking)

1. **Terminal sheet renders label-only chips.** Frame 43 shows "Available:", "Overdue:",
   "Current holder:", and "Owner contact:" with **empty values**, and the "Availability" chip absent.
   The manifest notes only "Availability empty"; the empty-value rendering extends to three more
   chips (owner contact should still be stored per the manifest's own `instance_data`). Display-only
   and post-terminal, but to a member it reads as broken data. Worth a look, not a B25 failure.
2. **Display humanisation confirmed as described:** chips render "Loom B25 Spade" /
   "Steel Digging Spade" / "Owner contact: Owner5551234" while the sheet title and the stored row
   keep raw `LoomB25Spade` / `owner5551234` (frames 41/42 vs 39). Cosmetic; the manifest already
   flags it.
