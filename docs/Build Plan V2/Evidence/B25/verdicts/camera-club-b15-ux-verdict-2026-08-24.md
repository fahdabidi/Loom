# UX Review — Camera Club, B25 phase B15

## 1. photo-walk-rsvp — **PASS**

**What's visible:** `start` shows the Golden Gate sunrise photo walk (route, 06:15, Battery Spencer trailhead, "Led by Maya Chen," 1/12 going, "No response record is available for you") with four clearly labeled buttons: **Going**, **Maybe**, **Not attending**, **Add reminder**. The primary-action frame shows **Going** in its pressed/selected outline before the state commits. `primary_result` shows a real backend-driven change: count moves to **2/12 going, 10 seats left**, the attendee roster now lists "Evidence camera-club-member" under **Going**, and a new **Cancel RSVP** button (red) appears. The alternate-action frame captures the tap-in-progress on the response controls; `result_receiver` shows another genuine state transition — **1/12 going, 11 seats left**, with the member now listed under **Maybe** instead of Going.

**Result frame:** Durable and receiver-visible — the roster list and capacity counter both update to reflect the member's changed response, not just a local UI toggle.

**Defects:** None blocking. Minor nit: "Add reminder" renders in the same muted gray as other secondary buttons across all five frames; it reads as slightly duller than **Going**/**Maybe**, which could look disabled at a glance, but it's consistent across every frame so it isn't a state-dependent bug.

## 2. critique-submission — **PASS, with a caveat on result clarity**

**What's visible:** `start` shows "Lighthouse at dusk" (the actor's own critique, prompt "Weekly theme: silhouettes," organizer's comment, **Reply** and **Withdraw critique** buttons) and a second critique "Night market reflections" by another member below it. The primary action is **comment/reply**: `primary_result` shows a new comment — "Evidence commentBody," attributed to `camera-club-member`, timestamped `2026-08-24T23:57:50Z` — appended under the organizer's existing comment, with the count moving from 1 to 2 comments. That's a genuine, attributed, timestamped append, not a placeholder.

The alternate action is **Withdraw critique**, tapped on the same "Lighthouse at dusk" item. Comparing `alternate_action` to `result_receiver`: the **Reply** and **Withdraw critique** buttons that were present in every prior frame are gone from `result_receiver`. That's a real UI change consistent with the critique moving to a withdrawn/read-only state.

**Result frame:** The durable-result signal here is indirect — I can confirm the withdraw controls disappeared, but the visible crop of `result_receiver.png` is scrolled such that the top of the "Lighthouse at dusk" card (where a "Withdrawn" status label would presumably sit) is cut off above the screen edge. I can't see explicit confirmation text telling the member their critique was withdrawn; I can only infer it from missing buttons. If there genuinely is no status label and the UI relies solely on button disappearance, that's a defect worth fixing — a user could read a critique with no action buttons as broken rather than intentionally withdrawn.

## 3. gear-loan-request — **FAIL on the alternate/result requirement (evidence, not just UI)**

**What's visible:** `start` shows the gear marketplace with search, "List gear," and three items scrolled into view. `primary_action` shows the Canon 70-200mm f/2.8 lens (Excellent condition, Owner: Camera Club Member, 0 borrowers/claimants) with **Request loan** (green, primary) and **Report damage** buttons. `primary_result` shows a genuine state transition: **Request loan** is replaced by **Cancel request**, confirming the item moved to a Requested state — a real, durable, backend-reflected result.

**The problem:** I checksummed the files directly. `B15_ext_camera_club_gear-loan-request_member_primary_result.png` and `B15_ext_camera_club_gear-loan-request_member_result_receiver.png` are **byte-for-byte identical** (same MD5: `4732f4315d5bfccec62a36cf7ec76feb`). This is not two screenshots that happen to look similar — it is the same file. The `alternate_action.png` frame (different hash, but visually the same crop — "Cancel request" / "Report damage" both present, "0 borrowers or claimants," Fujifilm still "Overdue," speedlite still "Available") shows no evidence that **Report damage** was actually invoked, and `result_receiver` — the frame that's supposed to prove the consequence of that alternate action — is a literal duplicate of `primary_result`, taken (or copied) before any damage report could have registered.

This means: no evidence exists that tapping "Report damage" changes anything — no condition-field update, no status change, no confirmation. The manifest marks `"screenshotStatus": "complete"` and `"b25ActionProofStatus": "pass"`, but one of the five "fresh" screenshots for this workflow is not fresh at all.

**Verdict rationale:** Per the judge brief, disagreeing with the manifest is the point of this review. The primary path (browse → request loan → Requested state) is real and durable. The alternate path (report damage) is asserted by the manifest but not evidenced by the screenshots — the result frame proves nothing happened, because it's a copy of an earlier frame. I'm failing this row specifically on the alternate/result leg of the bar, not on the primary leg.

## Overall

Camera Club is close to the bar but does not clear it as captured: 2 of 3 rows (photo-walk-rsvp, critique-submission) show real, attributable, receiver-visible state changes for both primary and alternate paths. gear-loan-request only proves its primary path; its alternate-action evidence is a duplicate file and proves nothing.

**To flip gear-loan-request to a pass:** re-run the capture for this workflow's `alternate_action`/`result_receiver` steps specifically, confirm the two output files have distinct hashes, and confirm the "Report damage" tap produces a visible field change (e.g., a condition/status update or a damage-report acknowledgment) between them — the same way "Request loan" → "Cancel request" was proven for the primary path.

**To fully close out critique-submission:** confirm (via a screenshot scrolled to show the top of the withdrawn card, not just the bottom) that there's an explicit "Withdrawn" or equivalent status label, not just the absence of Reply/Withdraw buttons.
e flag, or the request disappearing), not just the buttons sitting idle.

To fully close out critique-submission, I'd want one more captured frame showing the critique after "Withdraw critique" is actually pressed — either removed from the list or marked withdrawn — so the alternate path has the same standard of proof as the primary.

---

## Independent verification of this verdict

The duplicate-frame claim above was checked rather than taken on trust. MD5 across all 15
captured Camera Club frames finds exactly one duplicate pair, and it is the pair the judge named:

```
4732F4315D5BFCCEC62A36CF7EC76FEB  ..._gear-loan-request_member_primary_result.png
4732F4315D5BFCCEC62A36CF7EC76FEB  ..._gear-loan-request_member_result_receiver.png
```

The other three gear-loan frames, and all ten frames for the other two workflows, are distinct.
The manifest recorded this workflow as `screenshotStatus: complete` and
`b25ActionProofStatus: pass`. It was wrong, and only the judge caught it.
