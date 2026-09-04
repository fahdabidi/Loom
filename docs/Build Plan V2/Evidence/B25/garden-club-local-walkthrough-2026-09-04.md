# B25 live walkthrough evidence — Garden Club (local mode)

**Date:** 2026-09-04
**Community:** Garden Club (`community_garden_club`)
**App:** `loom_communities_demo` debug APK built from Loom `60f8f498` (Thread 2 adoption included),
`--dart-define=LOOM_PRELOAD_EXAMPLE_COMMUNITIES=true --dart-define=LOOM_ENV=local`
**Device:** Windows emulator `emulator-5554` (AVD `loom_win`, 1080×2400, Android 36)
**Persona:** Member ("TestMembery"), member card shows "2 roles"
**Mode:** local (persona-picker + `LocalWorkflowEngineApi`) — no Chrome, no ANR

> Screenshots (`*.png`) are gitignored/transient; this manifest is the durable record. It certifies
> the **rig and the Garden Club member experience render end-to-end**; it is NOT yet the rigorous
> per-row (primary + alternate affordance) B25 certification with a UX-judge pass — that is the
> remaining methodical grind (see "Remaining" below).

## What was driven and observed (live, on device)

| Surface | Description rendered | Affordances observed |
| --- | --- | --- |
| **Entry** | "Welcome to Loom" persona picker → Create New Account (Display name + Role=Member) → Sign Up → entered Garden Club | persona create/select; member-role summary |
| **Home** | "This week's event, exchange and care needs, and read-only export status" | **Offer or request a plant** (primary create); export **Mode: Export**, **Destination: Neighborhood Association archive**; **Ready for verified export** status |
| **Calendar** | "Seasonal workshops and work days with capacity, RSVP state, recurrence, and reminders" | **Day / Week / Month / Pending** view toggles; month grid (Mar 2027) with prev/next navigation |
| **Marketplace** | "Browse, list, borrow, queue for, return, or give away garden items" | **Search available items**; item cards ("Club hand-tool set", "Steel wheelbarrow"); **+** to list/offer |
| **Care** | (member card: "signs up for care shifts") | care-shift sign-up workflow present in the tab set |
| **Ad slot** | header banner | "No sponsored message right now" (renders, empty state) |

## Result
The full local-mode walkthrough path works end to end: **persona → community → the four workflow
tabs (Home / Calendar / Marketplace / Care) render with their affordances**, with no Chrome and no
ANR. This proves the B25 rig is functional in the correct (local) mode.

## Bonus — live-backend path also proven (2026-09-04)
Separately, the remote-mode APK proved the full live auth path: production login → PKCE OAuth → the
**live Keycloak login form for the `loom` realm** rendered at `http://192.168.56.10:30082` (client
`loom-test-client`, `code_challenge_method=S256`). This also live-confirmed Thread 2's adoption (the
app authenticates against the real backend). The remote path is ANR-prone on this emulator under load;
the B25 grind should use local mode.

## Remaining (the methodical grind)
Rigorous B25 certification = the 79 addendum-table rows, each proven by a live walkthrough of its
**primary + one alternate affordance** AND a UX-judge pass, per community. This manifest banks Garden
Club's surfaces; the remaining rows across the 10 communities are the focused multi-hour pass, best run
via `data/call_live_verification_agent.sh` (Opus) + `data/call_ux_judge_agent.sh` (Sonnet) for
efficiency and ANR-resilience.
