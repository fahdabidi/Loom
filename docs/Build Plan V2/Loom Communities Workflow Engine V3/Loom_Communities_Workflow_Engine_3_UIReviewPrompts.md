# UI review prompts (verification agent)

Part of [tracker 3](./Loom_Communities_Workflow_Engine_3.md). Used at every milestone's live-walk step
and at every phase gate.

## Why these exist

Milestone 1.18 passed every automated test, was code-verified, and had a live emulator walk — and still
shipped: unreadable dark-purple-on-black calendar text, a "Marketplace coming soon" placeholder, duplicate
generic cards on Home, and no way to start a message thread.

**Cause:** the walk only opened the ONE tab the milestone touched, and only checked that the NEW feature
worked. Nobody looked at the rest.

These prompts exist so a UI review is a **checklist, not a vibe.** Every question below has a definite
answer, and "I didn't look" is not one of them.

---

## Rule 1 — Audit every card on the tab, not just the new one

> For **each** card currently visible on this tab (not only the one this milestone added):
> 1. Which **workflow instance** is it rendering? Which **archetype** (`cardSurfaceFamily`)?
> 2. Is that the **correct** archetype for this card's purpose, per the tab's user stories?
> 3. Does it show the **real interactions** that archetype promises — or is it the generic fallback
>    card (icon + title + fact pills + buttons)?
> 4. If it is the generic fallback: **is that correct**, or is it a workflow that should have a real
>    archetype and doesn't?
> 5. Is it a **duplicate** of a card that already appears on its own proper tab?

Any card that fails 2, 3, or 5 is a **finding**, even if this milestone did not create it.

## Rule 2 — Verify against the frozen JSON, not against expectations

> Open [the frozen JSON](./Loom_Communities_Workflow_Engine_Phase1_TabletopClub_Example.jsonc)
> side-by-side with the running app. For this tab:
> 1. Which workflows declare a `renderBinding` for this `tabId`? **Exactly those** should appear —
>    no more (duplication), no fewer (missing).
> 2. For each, does the **state** shown match the instance's `currentState`?
> 3. Are the **buttons** exactly the transitions whose guards currently pass — no more, no fewer?
> 4. Are the **fact pills** the `instanceDataSchema` fields with a `labelTemplate`, each with its own
>    `displayIcon`, respecting `hideWhenEmpty` and `displayContexts`?
> 5. Are **computed** field values correct — and computed, not hardcoded? (Change the underlying data;
>    the computed value must move.)

**The JSON is the spec. Any divergence is a bug in the app — never a reason to edit the JSON.**

## Rule 3 — Prove guards, do not infer them

> For every guarded transition on this tab:
> 1. As a persona who **should** be blocked: is the button absent?
> 2. **And** does the transition genuinely **fail if invoked directly**?
>
> A hidden button is **not** proof. Guard enforcement lives in the engine. Prove it by attempting the
> transition and observing the refusal.

## Rule 4 — Readability and theming

> 1. Is **every** text element legible against its background? Name any element with poor contrast.
> 2. Do the colours derive from the community `accentColor` cascade — or is anything hardcoded
>    (an off-palette black/grey card, a stray hue)?
> 3. Does each fact pill have a **distinct, meaningful** icon — not the same icon repeated?
> 4. Are card borders/outlines visible?

## Rule 5 — The regression re-check

> Re-take **one** screenshot of a *previously-closed* milestone's interaction, chosen at random.
> Does it still work?

## Rule 6 — Gap check (the STOP condition)

> Did anything on this tab reveal a workflow the JSON declares that the app **cannot** implement?
>
> If yes: **STOP.** File a gap report per
> [Language Gaps](./Loom_Communities_Workflow_Engine_3_LanguageGaps.md) and halt the milestone.
> **Do not** edit the JSON. **Do not** hardcode a workaround.

---

## Evidence matrix (required to close any milestone)

One row per (Tab × User story × Interaction) cell the milestone touches. Not one screenshot per tab.

| Tab | User story | Interaction | Screenshot | Pass? | Notes |
|---|---|---|---|---|---|
| Calendar | Member RSVPs to an event | Tap "Going" → count increments | `screenNN.png` | ✅ | computed, verified via queryInstances |
| Calendar | Member cannot join a full event | Fill to capacity → "Going" gone, "Join waitlist" appears | `screenNN.png` | ✅ | formula guard |
| Calendar | *(full-tab audit)* | Every other card on Calendar is the right archetype | `screenNN.png` | ✅ | Rule 1 |
| *(regression)* | *(prior milestone)* | *(prior interaction)* | `screenNN.png` | ✅ | Rule 5 |

**A milestone does not close without a completed matrix.**

---

## Per-tab user stories

The definitive list each tab is audited against. Sourced from the phase docs.

### Calendar (Phase A)
- Member sees both of this week's events on a real month grid.
- Member RSVPs Going; the seat count updates (computed, not string-parsed).
- When full, Going is unavailable and Join waitlist appears instead.
- Member changes to Maybe and leaves the going list.
- Organizer cancels an event.
- All text is legible.

### Home (Phase B)
- Eligible member sees the ballot, taps a candidate for detail, votes.
- A member who did **not** RSVP genuinely cannot vote (engine refuses).
- The tally updates live.
- "Voting closes ⟨date⟩" shows; the "closing soon" banner appears once due.
- Organizer closes the vote → a tie opens a **real runoff**; otherwise the winner lands on the event.
- Published announcements appear; drafts do not.

### Marketplace (Phase C)
- Paid-up member browses and borrows.
- A member who hasn't paid dues is genuinely refused.
- Member joins a queue and sees their position.
- A member already queued sees "Leave queue", not "Join queue".
- Borrower returns; the item becomes available.
- Member claims the giveaway; it leaves the grid.

### Giving (Phase D)
- Member sees outstanding dues and pays.
- After paying, status is "paid" with a receipt/confirmation.
- Paying unlocks borrowing (cross-workflow).
- The Giving tab is visibly themed from the JSON cascade.

### Proposals — Home + Admin (Phase E)
- Member writes and submits a real proposal.
- Organizer sees every pending proposal in a **live** list — new ones appear unaided.
- Organizer approves / requests changes / rejects a specific one.
- The proposing member sees the real outcome on **their own** proposal.
- Member revises and resubmits.

### Messages (Phase F)
- Member reads and replies within a thread.
- Marking read genuinely clears unread.
- **Member starts a new thread**, and it appears for the participants.
- Member archives a thread.
