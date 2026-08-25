## UX Review — Camera Club B25, phase B15 (second pass)

### photo-walk-rsvp — **PASS** (holds from prior review)

Primary and alternate both produce real, durable, verifiable state changes:
- **Primary** (`start`→`primary_action`→`primary_result`): tapping **"Going"** moves the attendee roster from "Maybe · camera-club-member / Going · camera-club-organizer" to "Going · Evidence camera-club-member, camera-club-organizer / Maybe · camera-club-member," and the counter updates **1/12 going, 11 seats left → 2/12 going, 10 seats left**. Real backend state, not a toast.
- **Alternate** (`alternate_action`→`result_receiver`): tapping **"Maybe"** reverts the roster to "Maybe · Evidence camera-club-member, camera-club-member / Going · camera-club-organizer" and the counter drops back to **1/12 going, 11 seats left**. A **"Cancel RSVP"** control also appears once a response exists — a genuine change-response path.

No defects worth flagging here.

### critique-submission — **FAIL**

- **Primary** ("Comment") is genuinely demonstrated: the "Lighthouse at dusk" critique goes from **"1 comments"** to **"2 comments"**, with a new comment visibly attributed to `camera-club-member`, body "Evidence commentBody," timestamped `2026-08-25T02:45:13.572137Z`. That's a real, durable result.
- **Alternate** ("Withdraw critique") is not. The **red "Withdraw critique"** button is visible in `alternate_action`, but comparing `alternate_action` and `result_receiver` frame-for-frame, the content is byte-for-byte the same list — same two critiques, same comment counts (2 and 1), same buttons — just scrolled a few pixels further down. Nothing was withdrawn. The button being on-screen and styled as enabled satisfies a substring/keyword check, but there is no confirmation, no removal, no state transition — i.e., no durable result for the required alternate path.

This is exactly the "distinct bytes ≠ distinct outcome" trap the recapture note warned about for gear-loan-request, just showing up here instead: the frames differ in scroll position only, not in state.

### gear-loan-request — **FAIL** (this is the one under specific re-scrutiny)

- **Primary** ("Request loan") is real: the Canon 70-200mm's **Status: Available → Status: Requested**, and its action row changes from **"Request loan | Report damage"** to **"Join queue | Cancel request | Report damage."** Genuine, durable, backend-reflected state change.
- **Alternate** ("Report damage") is not. I diffed `primary_result`, `alternate_action`, and `result_receiver` directly: all three show **identical** content — Status: Requested, "Cancel request | Report damage" visible, Fujifilm still "Status: Overdue," speedlite still "Status: Available." The only difference across these three frames is scroll position (a few pixels), not state. The condition text ("Condition: Excellent — minor cosmetic wear only") is unchanged, there's no damage flag, no confirmation, no altered status. The 15 fresh frames are confirmed to hash distinctly per the recapture note, but that's explained entirely by scroll drift — not by "Report damage" ever being tapped.

**This directly reproduces the same category of defect the first review caught (byte-identical primary_result/result_receiver), just one level more subtle: this time the bytes differ, but the underlying state doesn't.** The manifest's `visibleAlternateActions: ["report damage"]` and `pass` status are describing that a string was present on screen, not that the action was exercised or had any consequence — which is exactly the gap this judging pass exists to catch.

**Minor defect, independent of the above:** in the `start` frame, the floating "List gear" button overlaps the third gear card, truncating the Fujifilm item's name to "Fu…" / "wa…" fragments. Not blocking, but worth a fix.

### Overall

Camera Club does **not** meet the production bar as captured. `photo-walk-rsvp` is solid. `critique-submission` and `gear-loan-request` both fail on the same underlying defect: the required alternate/change/reject action is shown as an available, enabled control, but never actually invoked in the walkthrough, so no durable consequence is proven. To flip these to pass, I'd need to see, between the alternate_action and result_receiver frames: for critique-submission, the withdrawn critique either removed from the list or marked withdrawn with a receipt; for gear-loan-request, a visible consequence of "Report damage" — e.g., condition text updated, a damage flag/badge, an owner-visible notice, or a confirmation state — not just the same screen at a different scroll offset.

---

## Independent corroboration

The "scroll-only" reading is supported by frame sizes. A scroll changes few bytes; a real state
change does not:

| Workflow | alternate_action | result_receiver | delta |
|---|---:|---:|---:|
| photo-walk-rsvp (PASS) | 149,597 | 173,496 | **16%** |
| critique-submission (FAIL) | 169,177 | 168,043 | 0.7% |
| gear-loan-request (FAIL) | 159,021 | 162,194 | 2% |

The one row that passes is the one whose frames genuinely diverge. Not proof on its own, but it
aligns with the verdict rather than against it.

## What this overturns

The first pass PASSED `critique-submission`, and "2 of 79 proven" was reported on that basis.
The same judge, re-reading fresh frames, now fails it for the same defect it originally caught
only in `gear-loan-request`. **The honest count is 1 of 79.**
