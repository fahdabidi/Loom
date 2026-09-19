# B25 UX judge verdict -- Garden Club (phase B13), capture run ev31

- Capture: ev31, instrumented APK at 256d22ea, --mode full-b25, emulator-5554
- Phase B13: screenshotStatus=complete, 9 frames, 5 rows, zero duplicate-frame findings
- Judge: Claude Code CLI, model fable, effort medium, label b13-ev31
- Frames are gitignored and transient; this verdict is the durable artifact.

All nine frames read and legible. Here is the verdict.

# B25 UX judge — Garden Club (B13), capture run ev31

**Scope limitation, stated up front:** these frames come from the B25 capture harness, which constructs the app widget directly and never runs the demo app's `main()`. They depict the **local-engine** rendering only. Cards are known to render differently on the remote path (e.g. the Publish-button case), so this verdict is evidence about local-engine rendering and does not certify the shipped app.

## Row 1 — `garden-export-custom-schemas`, coordinator, attempted — **pass-with-findings**

The five-frame sequence is coherent and genuinely reads as before → action → consequence:

- `…_coordinator_start.png`: Documents tab active, community header, "Signed in as Shipped garden-coordinator / Coordinator" with a role description that names export ownership, and a "New export package" FAB. The member is fully oriented.
- `…_primary_action.png`: the export card with chips `Mode: Export`, `2 schemas selected`, `Destination: Neighborhood Association archive`, `Redaction: Approved`, `Download: Unavailable`, and a clear action hierarchy — filled **Export**, outlined **Change scope**, red **Cancel transfer**. Affordance clarity is good: what you may do and how dangerous it is are both visually encoded.
- `…_primary_result.png`: the state visibly changes — an amber **"Export operation in progress"** banner, `Status: Generating export package`, and the action set swaps to **Confirm completion / Record export error / Cancel transfer**. This is a real, legible consequence of the tap, in words a member would use.
- `…_alternate_action.png`: same in-progress surface with the alternate affordance (Cancel transfer) in view — consistent with the harness capturing after only an `ensureVisible`, no tap between it and `primary_result`.
- `…_result_receiver.png`: **"Cancelled"** banner, "This is an off-path export state", `Status: Operation cancelled`. The alternate action's consequence is shown and explained.

Findings (none verdict-blocking):

1. **The app-bar title is clipped to a single "(" glyph in every frame of the phase** (visible next to the LOCAL ENGINE badge in all nine frames). A member cannot read which community they are in from the app bar; the community-card header rescues it, but the bar itself communicates nothing.
2. **`primary_action.png`: the status banner is clipped under the app bar** — "Ready for verified export" is half-hidden behind the green header. The single most important state line on the screen is the one partially occluded.
3. **`result_receiver.png`: the "Cancelled" banner text is very low-contrast** — faded orange-on-amber, markedly weaker than the "Export operation in progress" banner in the sibling frames. A terminal, off-path state deserves at least the legibility of the in-progress one.
4. **`start.png`: the "New export package" FAB overlaps and truncates the Documents card's description text** ("Coordinator-owned e… integrity, history, and p…").

## Rows 2–5 — the four `primary_action_unavailable` rows

Per the ticket, one `start` frame per row is correct and expected; I judged the screen that is there. All four frames are readable, match their filenames, and none is blank. All four get **pass-with-findings**, and they share one structural finding I state once:

**Shared finding: the single `start` frame in each of these rows is captured at (or near) the top of the tab scroll, so the instance whose primary action was unavailable is not in view.** The frame proves the member reached the right tab as the right identity; it cannot show whether the member, looking at the actual item/event, is told *why* no action is offered (full, on loan, owned-by-you). The recorded reason lives in the manifest, not the pixels. This is a harness-evidence limitation, not a product defect — but it means my affordance-clarity assessment for these rows is limited to what the frame shows.

- **Row 2 — `garden-event-rsvp`, member** (`…garden-event-rsvp_member_start.png`): Calendar tab selected, "Signed in as Evidence garden-member / Member", Calendar section descriptor ("Seasonal workshops and work days with capacity, RSVP state, recurrence, and reminders"). Oriented and legible. The event itself — and any "full / join waitlist" wording — is below the fold, so I could not assess whether the full-event state is communicated. Withholding "Going" on a full event is confirmed-correct product behaviour and is not reported as a defect.
- **Row 3 — `plant-exchange-submission`, member** (`…plant-exchange-submission_member_start.png`): Home tab, member identity, and a prominent **"Offer or request a plant"** FAB — the member is clearly not stranded; a creation path is on screen even though the row's primary action on the existing instance was unavailable. Finding: the FAB again overlaps the Home card's description text.
- **Row 4 — `garden-tool-loan`, member** (`…garden-tool-loan_member_start.png`): Marketplace tab, member identity, tab descriptor ("Browse, list, borrow, queue for, return, or give away garden items"), a "+" FAB. Oriented, but no item cards in view, so the on-loan/owner state of the specific tool is not evidenced. An owner being unable to borrow their own item is confirmed-correct and not reported as a defect.
- **Row 5 — `garden-tool-giveaway`, member** (`…garden-tool-giveaway_member_start.png`): the strongest of the four — Marketplace scrolled to real item cards. State communication here is genuinely good, in member words: "Club hand-tool set — Mode: Loan, Availability: **On Loan**, Pickup: Saturday mornings, Due back 2026-08-20"; "Steel wheelbarrow — Mode: Loan, Availability: **Available**, Condition: Good, Overdue: No". Two findings: **both visible items are `Mode: Loan` — no giveaway item is in frame for a giveaway row**, so the row's own subject is unevidenced; and the "+" FAB overlaps the wheelbarrow's "Current hold…" chip, truncating it.

## Rows I could not assess, and why

None were skipped. All five rows were assessed; the qualification is that for rows 2–4 the *specific instance* behind the unavailable outcome is off-screen, so the "why is the action absent" half of affordance clarity could not be judged from pixels — only orientation, hierarchy, and tab-level state.

## Overall phase verdict: **pass-with-findings**

No row fails: every frame is readable, matches its name, and row 1's action sequence demonstrably shows a real state change and its consequence. The recurring findings worth fixing, in order of user impact:

1. App-bar community title clipped to "(" across the entire phase (all nine frames).
2. Status banner clipped under the app bar on the export card (`primary_action.png`).
3. FAB overlapping content text in three frames (rows 1, 3, 5).
4. Low-contrast "Cancelled" terminal-state banner (`result_receiver.png`).
5. Harness-level, not product: single-frame unavailable rows capture the top of the tab rather than the instance in question, so the frame cannot evidence the (correct) reason for the absent action.
