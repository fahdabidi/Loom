# B25 UX judge verdict -- phase B15 (Chess Club, Camera Club), capture run ev36

- Capture: ev36, instrumented APK at 962d4700, --mode full-b25, emulator-5554
- Phase B15: screenshotStatus=complete, TOOL_EXIT=0, traversal finalised
- Judged: the 4 rows that reached outcome attempted, 20 frames, all five-frame sequences
- Judge: Claude Code CLI, model fable, effort medium, label b15-ev36
- Frames are gitignored and transient; this verdict is the durable artifact.

All 20 frames read and legible. Here is my verdict.

---

# B25 UX judge verdict — phase B15, capture run ev36

**Scope disclaimer (required):** these frames come from the B25 capture harness, which constructs the app widget directly and never runs the demo app's `main()`. Every frame shows the **local engine** (the `LOCAL ENGINE` pill is visible in every top bar), with the demo identity model that aliases fan ids to role ids. This verdict is evidence about local-engine rendering only; it does not certify the shipped remote-backed app, and some cards are known to render differently there.

All 20 frames were readable, non-blank, and showed what their names claim. No row was unassessable.

## Chess Club — chess-export-package, owner: **pass-with-findings**

The five frames tell a complete, well-differentiated story. `…start.png` shows the Admin tab with a "Ready to export" card ("August ladder and match archive", "3 data groups", "Ready to generate") and a "New export" FAB. `…primary_action.png` shows the "Generate export" button in view. `…primary_result.png` is genuinely load-bearing: the card's state chip is now **"Export generated"** in green, with a timestamp, a "Download export" affordance that did not exist before, and a history entry naming the actor (`chess-owner-22`). This is a real, legible consequence in a member's words — not the same screen. `…alternate_action.png` shows the red "Rollback" button in view; `…result_receiver.png` shows the state renamed **"Export rolled back"** with a two-entry history (generated, then rolled-back) and recovery actions ("Change scope", "Generate again"). State communication is the strongest of the four rows.

Findings:
1. The "Export rolled back" header chip in `…result_receiver.png` renders washed-out (pale amber on light background) — the most important state name on the screen is the least legible element on it.
2. The history renders raw developer syntax to the member: `{action: generated, actorFanId: chess-owner-22, at: 2026-09-19T21:31:05.152942Z}` — braces, camelCase keys, and microsecond ISO timestamps are not words a member would use.
3. "This is an off-path export state" is system vocabulary; it explains that something is unusual without saying what the member should do about it.

## Camera Club — photo-walk-rsvp, member: **pass**

The cleanest row of the phase. `…start.png` states the pre-state in plain words — "No response record is available for you for this event" — above Going / Maybe / Not attending buttons. `…primary_result.png` clearly differs from `…primary_action.png`: "Evidence camera-club-member" now appears under **Going**, the Going button is selected-and-disabled, and a **Cancel RSVP** affordance has appeared. `…alternate_action.png` shows Maybe about to be taken; `…result_receiver.png` shows the member moved to the **Maybe** list with the Maybe button now selected and Going re-enabled. The attendee-list-plus-button-state combination names the state without the member having to infer it.

Minor findings (not blocking): the chip `weatherChecklistNotes` leaks a raw camelCase field name onto the card; and the attendee lists mix identity styles ("Evidence camera-club-member" next to role-shaped names like "camera-club-organizer") — the known local-engine fanId/roleId aliasing seam, visible to a member.

## Camera Club — critique-submission, member: **pass-with-findings**

The story completes, but the load-bearing middle pair is the weakest of the phase. `…primary_action.png` shows the Reply affordance on the "Lighthouse at dusk" critique, but is scrolled so that the acted-on card's title and its before-count are off-screen. `…primary_result.png`'s only visible change is a "2 comments" chip — and because the "1 comments" before-state is not visible in the action frame, the pair alone does not demonstrate the change. The proof arrives in `…result_receiver.png`, which shows the new comment in full ("Evidence commentBody", by camera-club-member, timestamped 2026-09-19T21:32 — the capture run's own day) alongside the original organizer comment, and the card's state chip flipped to a red **"Critique withdrawn"** after the alternate action. So the row is proven, but by the fifth frame rather than the third.

Findings:
1. `primary_result` is only weakly distinguishable from `primary_action` in isolation; the consequence of Reply (the comment body) is not shown on the result frame, only a count.
2. "1 comments" / "2 comments" — grammatical number is ignored.
3. The withdrawn card retains a live-looking comment thread with no visual muting other than the chip; the member must find the one red chip to know the critique is dead.

## Camera Club — gear-loan-request, member: **pass-with-findings**

`…primary_action.png` shows the Canon 70-200mm detail dialog with **"Status: Available"** and a prominent "Request loan" button. `…primary_result.png` shows a real state change in member words: **"Status: Requested"** plus a new "Requested by: Camera Club Member" chip, and the action set has changed (Request loan gone; Join queue / Approve / Decline / Cancel request appeared). `…result_receiver.png` shows the alternate action's consequence: a new **"1 reported issues"** chip after Report damage. State communication passes.

Findings:
1. **The "Borrower/claim count:" chip loses its value after the request** — `primary_action` shows "Borrower/claim count: 0"; in `primary_result`, `alternate_action` and `result_receiver` the chip renders as a bare label with no number. An empty labeled chip is worse than no chip.
2. **The member is offered "Approve request" and "Decline request" on their own request** — and the dialog says the owner and the requester are the same person ("Owner: Camera Club Member", "Requested by: Camera Club Member"). This is the local-engine role-aliasing model collapsing owner and requester into one identity, so as *member evidence* this row proves a self-loan; the affordance set a real distinct member would see is not what these frames show. This is exactly the class of thing the scope disclaimer exists for.
3. `…alternate_action.png` is visually near-identical to `…primary_result.png` (same scroll, same chips, same buttons); only the harness's declaration says Report damage is the pending action. Fine under the declared-tap-boundary rule, but the frame itself carries no information the previous one lacked.

## Overall phase verdict: **pass-with-findings**

All four rows have a genuine, legible before/action/after story, and in all four the `primary_result` frame (or, for critique-submission, the sequence completed by `result_receiver`) shows a real state change named on screen — no row shows an action that rendered nothing. The recurring cross-row findings worth fixing once, centrally: raw developer vocabulary reaching members (camelCase field names, JSON history entries, microsecond timestamps), grammatical number on count chips, the low-contrast state chip for warning states, and — specific to gear-loan — a labeled chip that renders with no value after a state change. The truncated app title in the top bar (only "(" visible beside the LOCAL ENGINE pill) appears in all 20 frames and is worth a cosmetic ticket.

No application code, community JSON, or tests were touched; no suites were run (review-only dispatch, nothing to verify by test).

---

## Machine-readable row index

Added 2026-09-19, same reason as the B13 verdict: `check_b25_status.sh` matches the literal
`**Workflow:** \`<id>\`` form, and this verdict named its rows only in prose headings. Each line
corresponds to a per-row verdict above — nothing is claimed here that was not judged.

**Workflow:** `chess-export-package`
**Workflow:** `photo-walk-rsvp`
**Workflow:** `critique-submission`
**Workflow:** `gear-loan-request`
