# Camera Club — live multi-persona Critique write (B25 gap closure)

**Date:** 2026-09-04 (device local, America/Los_Angeles — `adb shell date` = `Fri Sep  4 18:37:19 PDT
2026`; engine stamps are UTC, so the review effect lands at `2026-09-05T01:34:22.622283Z`, which is
18:34 local on 2026-09-04)
**Device:** `emulator-5554`, Android, 1080x2400
**adb path:** Windows-hosted emulator reached over an SSH reverse tunnel to adb on `127.0.0.1:5037`;
every command issued as `adb -s emulator-5554 …`. `get-state` = `device` before and after the run.
No `kill-server`/`start-server`/`connect`/`disconnect` was issued, no `-a`, and no
`ANDROID_ADB_SERVER_ADDRESS`/`PORT` was set.
**App:** `com.example.loom_communities_demo/.MainActivity`
**Workflow:** `critique-submission` in Camera Club

## Outcome

**This row is closed.** A critique was created from nothing by a freshly minted Member persona and
driven all the way to the workflow's terminal state `reviewed` by a second, Organizer persona. Both
submits were real — nothing was cancelled — and the final state plus the reviewer's feedback are
visible to **both** the author and the reviewer.

The blocked premise is resolved as the ticket predicted: the create action is declared
`byRoleIds: ["camera-club-member", "camera-club-organizer"]`, so a fresh persona does not need the
un-sign-in-able seeded instances. It made its own.

## Personas

Both created live in-app during this run; both ids are as displayed by the in-app
"Account role and permissions" dialog.

| # | Display name | Account / fan id | Role (label) | Role id |
|---|---|---|---|---|
| 1 | Marisol Vega | `camera-club-organizer-20` | Organizer | `camera-club-organizer` |
| 2 | Priya Raghunathan | `camera-club-member-21` | Member | `camera-club-member` |

Persona 1 was created at the community entry gate. **The role dropdown defaulted to Organizer** and
was accepted unchanged, exactly as the earlier walkthrough recorded. Persona 2 was created via
**"Sign in as a specific person…" → Create New Account**, with the role dropdown switched from
Organizer to **Member** before Sign Up.

The author of the new critique is persona 2, the **Member** — the role whose access to this workflow
was previously unproven.

## Step-by-step

| # | Step | Result | Screenshot |
|---|---|---|---|
| 0 | Community list "Loom Communities", 10 example communities loaded | — | `camera-critique_00_start.png` |
| 1 | Scroll list → open **Camera Club** | Entry gate, **no** existing accounts | `camera-critique_01_list.png`, `camera-critique_02_camera-club.png` |
| 2 | Persona 1: name "Marisol Vega", role **Organizer (default, unchanged)**, Sign Up | Signed in as Marisol Vega / Organizer | `camera-critique_03_persona1-name.png`, `camera-critique_04_persona1-ready.png`, `camera-critique_05_persona1-signedin.png` |
| 3 | Identity dialog → record id | **ID: camera-club-organizer-20** | `camera-critique_06_identity-picker.png` |
| 4 | "Sign in as a specific person…" → Create New Account, name "Priya Raghunathan", role dropdown → **Member**, Sign Up | Signed in as Priya Raghunathan / Member | `camera-critique_07`…`camera-critique_11_persona2-signedin.png` |
| 5 | Identity dialog → record id | **ID: camera-club-member-21** | `camera-critique_12_persona2-id.png` |
| 6 | As Priya (Member) → **Critique** tab | Tab opens; **"New critique" FAB present for the Member role**; no critique instances visible to her | `camera-critique_13_critique-tab-member.png` |
| 7 | Tap **"New critique"** FAB | Create form opens with all 5 declared `formEntry` fields | `camera-critique_14_new-critique-form.png` |
| 8 | Filled every required field (values below), then **Create** — SUBMITTED, not cancelled | Dialog closed, instance created in **`draft`** | `camera-critique_15`…`camera-critique_23_form-complete.png`, `camera-critique_24_created.png` |
| 9 | Read back the new card on the Critique tab | State **"Draft critique"**, `By Camera Club Member 21`, 0 comments, all fields rendered | `camera-critique_25_draft-card.png` |
| 10 | Scroll to the card's action row | **"Submit critique"** and "Withdraw critique" offered; "Save changes" disabled ("No changes to save yet.") | `camera-critique_26_draft-actions.png` |
| 11 | Tap **"Submit critique"** — real transition, not cancelled | State → **"Submitted for critique"**; actions become **Reply** / **Withdraw critique** | `camera-critique_27_submitted.png` |
| 12 | Identity dialog → "Sign in as a specific person…" → **Marisol Vega** | Signed in as Marisol Vega / Organizer | `camera-critique_28_switch-accounts.png`, `camera-critique_29_organizer-active.png` |
| 13 | Bottom nav scrolled right → **Admin** tab (organizer-only; `visibleRoleIds: ["camera-club-organizer"]`) | Admin tab opens, "Tuned for Organizer" | `camera-critique_30_tabs-scrolled.png`, `camera-critique_31_admin-tab.png` |
| 14 | Locate the new critique in the Admin queue | Present as a review item: **"Submitted for critique" / "Fog on the Old Ferry Pier" / By Camera Club Member 21**, with **Complete critique**, **Request changes**, **Add critique comment** | `camera-critique_32_admin-scroll.png`, `camera-critique_33_admin-review-item.png`, `camera-critique_34_before-complete.png` |
| 15 | Tap **"Complete critique"** | Dialog asks for the required **Feedback** input | `camera-critique_35_feedback-prompt.png` |
| 16 | Feedback entered, **Complete critique** — SUBMITTED for real | State → **"Critique reviewed"** (terminal), comment appended under `camera-club-organizer-20` | `camera-critique_36_feedback-filled.png`, `camera-critique_37_reviewed.png` |
| 17 | Switched back to **Priya (author)** | Signed in as Priya Raghunathan / Member; Admin tab correctly gone from her nav | `camera-critique_38`…`camera-critique_40_back-to-author.png` |
| 18 | Her own **Critique** tab | State **"Critique reviewed"**, organizer's feedback and timestamp visible to the author | `camera-critique_41_author-sees-feedback.png`, `camera-critique_42_notes-stored.png` |

Screenshots were written to `/tmp/camera-critique_<step>.png` on the driving host. Per this repo's
evidence rule (`*.png` is gitignored and transient), **this manifest is the durable artefact**; the
images are not committed and will not survive a reboot.

## Values submitted on the create form

Every field on `critique-submission` marked `required: true, writableBy: formEntry` was filled
honestly — no placeholder, no stub.

| Field | Value entered |
|---|---|
| Photo Title (`photoTitle`) | `Fog on the Old Ferry Pier` |
| Prompt (`promptOrTopic`) | `Boundaries, transitions, and overlooked urban edges` |
| Notes (`notes`) | `Blue hour on the old ferry pier, 35mm at f2.8, one sixtieth of a second, ISO 800, handheld against the railing. I wanted the point where the walkway stops being a structure and becomes fog, so the eye has to guess where the pier ends. Two questions for the group. First, does the mooring bollard in the lower left anchor the frame or does it compete with the railing line. Second, the wet planks hold a lot of highlight and I have already pulled them back half a stop, but I cannot tell if they still draw the eye from the vanishing point.` |
| Consent Note (`consentNote`) | `No identifiable people appear in the frame. The two figures at the far end are silhouetted and unrecognisable. Shot from a public walkway where no permit is required. I consent to this image being shown in the September critique session and kept in the members gallery.` |
| Photo Image (`photoImage`) | `camera-club/fog-old-ferry-pier-2026-09-04.jpg` |

The prompt value deliberately matches the community's own seeded announcement, which asks members to
"bring one image about boundaries, transitions, or overlooked urban edges to the September critique".

**Two honest caveats on the Notes value, both caused by my input tooling, not by the app.**
`adb shell input text` silently truncated the second half of the Notes string at
"…I cannot tell if they stil"; I detected it by reading the field back (`camera-critique_20_notes-end.png`),
re-focused the field, moved to end and typed the remaining tail
(`camera-critique_21_notes-fixed.png`). Separately, the emulator's soft keyboard autocorrected
"pier" to "Pier" and dropped one sentence-ending period, visible in the rendered card at
`camera-critique_25_draft-card.png` ("…where the Pier ends Two questions…"). Neither is a product
defect; both are recorded because the stored string differs very slightly from the table above.

## The terminal transition

Action used: **`review`** ("Complete critique"), `from: ["submitted"] → to: "reviewed"`
(`isTerminal: true`), `guard.allowedRoleIds: ["camera-club-organizer"]`, required input `feedback`.

Feedback submitted:

> The fog does the work here. Keep the bollard, it gives the eye somewhere to stand before the
> railing dissolves. Crop a little tighter on the right instead. Highlights on the planks read fine
> at this size. Bring a print to the September session.

Post-transition state as rendered on the card (identical for both personas):

- State chip: **Critique reviewed** (positive tone)
- Comment block: sender **`camera-club-organizer-20`**, body verbatim as above,
  timestamp **`2026-09-05T01:34:22.622283Z`**
- Comment count: **1 comments** (was `0 comments` / "No comments yet" immediately before)

The sender recorded is persona 1's real fan id, and the note is stored verbatim — the declared
effects (`append comments` with `senderFanId: $actor`, `set reviewedByFanId`, `set reviewedAt`) all
fired.

## Visibility proven on both sides

- **Author (`camera-club-member-21`, Member)** — created the instance, saw it in `draft`, submitted
  it, saw `submitted`, and after the review sees **`Critique reviewed`** with the organizer's
  feedback on her own Critique tab. This exercises
  `visibility.fields.parties: ["authorFanId", {"role": "camera-club-organizer"}]` on a
  `default: "guarded"` workflow whose `readGuard` is `actorEqualsField: authorFanId` alone.
- **Reviewer (`camera-club-organizer-20`, Organizer)** — saw the instance appear on the **Admin** tab
  the moment it entered `submitted`, which is the `audience: "receiver"` / `approvalQueueItem`
  binding, and retains it afterwards through the `["changes-requested","reviewed"]`,
  `audience: "any"` summary binding.
- Role gating is real in both directions and was observed directly: the **Admin** tab is present in
  Marisol's bottom nav and absent from Priya's; the "New announcement" FAB is offered to the
  Organizer on Home and not to the Member.
- Guards resolve the acting identity, not just the role: in `submitted` the author was offered
  **Reply** (`add-comment-author`, guarded by `actorEqualsField: authorFanId`) and the organizer was
  offered **Add critique comment** (`add-comment-organizer`, guarded by `allowedRoleIds`) — different
  buttons on the same instance in the same state.

## Findings

1. **Create does not reach `submitted`; it lands in `draft`, and that is correct.** The ticket's
   step 4 anticipated the new critique appearing in "submitted" straight after the create. It does
   not — `critique-submission` declares `initialState: "draft"`, so the FAB produces a **"Draft
   critique"** and reaching `submitted` requires a **second, separate real action** ("Submit
   critique") that only the author can fire. The row is still closed, because both actions were
   performed for real; recording this so a future walkthrough that stops at Create does not report
   the workflow as stuck.

2. **A `type: image` field renders as a free-text input with no picker or attach affordance.**
   `photoImage` is declared `type: "image", required: true, writableBy: "formEntry", storage:
   "reference"`. On the create form it presents as an ordinary text line labelled "Photo Image";
   tapping it opens the **alphabetic soft keyboard** (`camera-critique_22_photoimage-tap.png`) — there
   is no gallery picker, no camera launch, no file chooser. Any string is accepted and stored, and
   the card then renders the literal chip `photoImage` rather than an image. A photography community
   whose central workflow is photo critique cannot currently attach a photograph. This is the one
   real product gap this run surfaced; it did not block the state machine, so it does not block this
   row, but it is a genuine finding against the Camera Club product doc.

3. **The original BLOCKED cause is confirmed, and it is not "no instances exist".** Camera Club ships
   two seeded `critique-submission` instances — `critique-lighthouse-portrait` (`submitted`) and
   `critique-night-market-reflections` (`reviewed`) — and both carry
   `authorFanId: "camera-club-member"`, a seed id no live persona can be issued (a persona created as
   Member is minted `camera-club-member-21`). Because the workflow is `guarded` with
   `readGuard.actorEqualsField: authorFanId`, a fresh Member is not a party to either. Confirmed
   directly: on Priya's Critique tab the critique created in this run is the **only** card present,
   while on Marisol's Admin tab the seeded `reviewed` one is visible alongside it (prompt "Color and
   motion", By Camera Club Member, with the seeded organizer comment timestamped
   `2026-08-12T19:30:00Z`) — see `camera-critique_33_admin-review-item.png`. Same shape as the Cedar
   dues gap: the seeds are addressed to an id no live persona can hold.

4. **In the terminal state the card collapses to a summary, by design.** Once `reviewed`, the
   author's card no longer renders the Photo Title / Prompt / Notes / Consent Note / Photo Image
   detail block — only the chips, the author, and the comments. That matches the package: the
   `["reviewed","withdrawn"]` binding on tab `critique` is `bindingKind: "summary"`, where `draft` and
   `submitted` are `primary`. Not a defect; noted because the fields look lost after review.

5. **UI quirk, cosmetic, no data impact — same one recorded for Cedar.** While the soft keyboard is
   up, the create dialog collapses to show only the title and the action row; the remaining fields
   cannot be scrolled into view until the keyboard is dismissed
   (`camera-critique_15_title.png`). Every value survived correctly — verified field-by-field after
   each entry — so this cost extra steps, not correctness.

## Stability

- No crash, no ANR, no blank frame observed across the whole run.
- `mCurrentFocus` was
  `Window{60b8b8 u0 com.example.loom_communities_demo/com.example.loom_communities_demo.MainActivity}`
  at the start and unchanged at the end, including after both submits.
- `logcat -d -t 4000` filtered for `FATAL EXCEPTION|ANR in|Force finishing` returned **zero** lines.
  Control: the same buffer holds **54** lines mentioning `loom_communities_demo`, so the filter was
  reading a populated log rather than an empty one. The only app-related warnings in the wider buffer
  are `W WindowManager: Exception thrown during dispatchAppVisibility … EXITING`, all timestamped
  **before** this run began (latest `09-04 18:23:25`, from a prior app instance).

## Does this genuinely close the B25 Critique row?

**Yes.** The row required the Critique tab to be provable for a fresh persona, and it now is, by a
real create-to-terminal-state sequence rather than by seeding or by accepting an incomplete result:

- a brand-new **Member** persona created a brand-new critique through the product's own "New
  critique" FAB, filling every required field with honest values;
- the same persona drove it `draft → submitted` with a real submit;
- a brand-new **Organizer** persona found it in the Admin review queue and drove it
  `submitted → reviewed` — the workflow's terminal positive state — through a real
  `review` transition carrying required feedback;
- the final state and the reviewer's feedback are confirmed visible to **both** personas on their own
  surfaces, with correct role gating and correct actor-level guard evaluation.

Nothing in the sequence depended on the un-sign-in-able seeded instances. The one product gap found
(finding 2, `photoImage` has no image picker) is recorded honestly and is **not** claimed as passing;
it does not affect the state machine this row is about.

Camera Club's **Messages** row is untouched by this run and remains open.

## Scope note

No test suites were run — this ticket is a live-device walkthrough and changed no code. Nothing was
committed. No file other than this manifest was created or modified; no community `*.jsonc` and
nothing under `docs/references/**` was touched.

## B25 tally update

Camera Club's **Critique** half is now CLOSED via live multi-persona write. The Camera Club entry
itself stays open, because its **Messages** half is untouched, so the count does not move: **4 of the
5 original isolated gaps remain** — Book Club Messages, Chess disputes, Camera Club (**Critique
closed**, Messages outstanding), Garden Club Messages. Cedar Commons HOA dues was the one closed
earlier today.

## Independent verification (orchestrator, by eye)
`camera-critique_41_author-sees-feedback.png` pulled byte-identically and viewed: confirms the
author's own Critique tab shows "Fog on the Old Ferry Pier", the organizer's verbatim feedback
("The fog does the work here...") with the exact timestamp `2026-09-05T01:34:22.622283Z`, and
"1 comments". Also confirms finding 2 (the bare `photoImage` chip renders with no value/picker) --
real, genuine product gap, distinct from and not blocking this row's closure.

## B25 tally update
Camera Club's Critique half is now CLOSED via live multi-persona write (Cedar's is also closed).
Camera Club's Messages half remains open. 4 of 5 isolated gaps in play: Book Club Messages, Chess
disputes, Camera Club Messages, Garden Club Messages -- plus this run's new, separate finding
(photoImage has no image picker) to triage independently of the B25 closure count.
