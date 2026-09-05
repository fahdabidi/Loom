# Cedar Commons HOA — live multi-persona dues write (B25 gap closure)

**Date:** 2026-09-04 (device local, America/Los_Angeles; engine stamps are UTC — the write lands at
`2026-09-05T01:15:19Z`, which is 18:15 local on 2026-09-04)
**Device:** `emulator-5554`, Android, 1080x2400
**adb path:** Windows-hosted emulator reached over an SSH reverse tunnel to adb on `127.0.0.1:5037`;
every command issued as `adb -s emulator-5554 …`. `get-state` = `device` before and after the run.
No `kill-server`/`start-server`/`connect`/`disconnect` was issued and no
`ANDROID_ADB_SERVER_ADDRESS`/`PORT` was set.
**App:** `com.example.loom_communities_demo/.MainActivity`
**Workflow:** `hoa-dues-payment` in Cedar Commons HOA

## Outcome

**This row is closed.** A dues charge was created from nothing and driven to the terminal-money state
`paid` by two distinct personas, both submits real (nothing cancelled), and the result is visible to
**both** the board and the payer. The `start-checkout` / "Pay dues" path — the one marked
`NEEDS IMPLEMENTATION (platform service)` — was **not** used and is not claimed.

## Personas

Both created live in-app during this run; both ids are as displayed by the in-app
"Account role and permissions" dialog.

| # | Display name | Account / fan id | Role (label) | Role id |
|---|---|---|---|---|
| 1 | Maya Torres | `hoa-member-20` | Homeowner | `hoa-member` |
| 2 | Dana Whitfield | `hoa-board-21` | Board | `hoa-board` |

Persona 1 was created at the community entry gate (role dropdown defaulted to Homeowner).
Persona 2 was created via **"Sign in as a specific person…" → Create New Account**, with the role
dropdown switched from Homeowner to **Board** before Sign Up.

## Step-by-step

| # | Step | Result | Screenshot |
|---|---|---|---|
| 0 | Community list "Loom Communities", 10 example communities loaded | — | `cedar-dues_00_start.png` |
| 1 | Open **Cedar Commons HOA** → entry gate, no existing accounts | Create-account form shown | `cedar-dues_01_cedar_open.png` |
| 2 | Persona 1: name "Maya Torres", role Homeowner (default), **Sign Up** | Signed in as Maya Torres / Homeowner | `cedar-dues_02_p1_name.png`, `cedar-dues_03_p1_form.png`, `cedar-dues_04_p1_signed_in.png` |
| 3 | Identity dialog → record id | **ID: hoa-member-20** | `cedar-dues_05_identity_picker.png` |
| 4 | "Sign in as a specific person…" → Create New Account, name "Dana Whitfield", role dropdown → **Board**, **Sign Up** | Signed in as Dana Whitfield / Board | `cedar-dues_06`…`cedar-dues_10_p2_signed_in.png` |
| 5 | Identity dialog → record id | **ID: hoa-board-21** | `cedar-dues_11_p2_id.png` |
| 6 | Bottom nav scrolled right → **Admin** tab (board-only; `visibleRoleIds: ["hoa-board"]`) | Admin tab opens | `cedar-dues_12_nav_scroll.png`, `cedar-dues_13_admin_tab.png` |
| 7 | Create FAB → 4 create actions offered; chose **"New dues charge"** | Create form opens with all 9 required fields | `cedar-dues_14_fab.png`, `cedar-dues_15_create_form.png` |
| 8 | Filled every required field (values below), then **Create** — SUBMITTED, not cancelled | Dialog closed, instance created | `cedar-dues_16`…`cedar-dues_30_method_full_form.png`, `cedar-dues_31_after_create.png` |
| 9 | Giving tab as Board → locate new charge | State **"Dues due"**, `Receipt: Due` | `cedar-dues_37_new_charge_due.png` |
| 10 | Switched to **Maya (payer)** → charge visible in "Dues due" on her surface | Payer visibility confirmed pre-payment | `cedar-dues_39_maya_signed.png` |
| 11 | Switched back to **Dana (Board)** → **"Record offline payment"** on that card | Dialog asks required **Confirmation Note** | `cedar-dues_41`…`cedar-dues_43_record_dialog.png` |
| 12 | Note entered, **Record offline payment** — SUBMITTED for real | Transition applied | `cedar-dues_44_note.png`, `cedar-dues_45_after_record.png` |
| 13 | Board view of the charge | State **"Paid"** + full history | `cedar-dues_47_paid_board.png` |
| 14 | Switched to **Maya (payer)** → her Giving tab | State **"Paid"**, same history, member-only actions offered | `cedar-dues_49_payer_paid.png`, `cedar-dues_50_payer_paid_chip.png`, `cedar-dues_52_maya_giving_1.png` |

Screenshots were written to `/tmp/cedar-dues_<step>.png` on the driving host. Per this repo's evidence
rule (`*.png` is gitignored and transient), **this manifest is the durable artefact**; the images are
not committed and will not survive a reboot.

## Values submitted on the create form

Every field on `hoa-dues-payment` marked `required: true, writableBy: formEntry` was filled honestly —
no placeholder, no stub.

| Field | Value entered |
|---|---|
| Title | `2026 third-quarter HOA assessment` |
| $ (amount) | `285` |
| Due (date) | `2026-09-30` (picked Wed, Sep 30 in the date picker) |
| Deadline time | `18:00` (time picker) |
| Payer (`payerFanId`) | `hoa-member-20` — persona 1 |
| Recipient | `Cedar Commons HOA operating fund` |
| Entitlement | `Q3 2026 common-area and pool access` |
| Visibility | `Visible to the payer and the board` |
| Method | `Bank transfer or check to the HOA office` |

After create, the tile rendered `Payer: Hoa Member 20` — the engine resolved the entered fan id to a
display name, which is independent confirmation the id bound to a real account rather than being
stored as loose text.

## The terminal transition

Action used: **`record-offline-payment`** ("Record offline payment"), `from: ["due","processing","failed"] → to: "paid"`,
`guard.allowedRoleIds: ["hoa-board"]`, required input `confirmationNote`.

Confirmation note submitted:

> Check 4417 received at the HOA office on 2026-09-04 and deposited to the operating fund

Post-transition state as rendered on the card (identical for both personas):

- State chip: **Paid** (positive tone)
- `Receipt: Offline payment recorded`
- `Paid 2026-09-05T01:15:19.251547Z`
- History entry:
  - `Event: Offline payment recorded`
  - `Note: Check 4417 received at the HOA office on 2026-09-04 and deposited to the operating fund`
  - `Actor Fan Id: hoa-board-21`
  - `At: 2026-09-05T01:15:19.251729Z`

The actor recorded is persona 2's real fan id, and the note is stored verbatim — both effects
(`set receiptStatus`, `set paidAt`, `append history`) fired as declared.

## Visibility proven on both sides

- **Board (`hoa-board-21`)** — sees the charge on Giving and Admin, in `due` before and `paid` after.
- **Payer (`hoa-member-20`)** — sees the same charge on her own Giving tab ("Tuned for Homeowner"),
  in `due` before the payment and **`Paid`** after, with the confirmation note in its history. This
  exercises the declared rule `visibility.fields.parties: ["payerFanId", {"role": "hoa-board"}]`
  against a `default: "guarded"` workflow whose `readGuard` alone would admit only the board.
- Once `paid`, the payer's card correctly offers the two member-only actions whose guards combine
  `allowedRoleIds: ["hoa-member"]` with `actorEqualsField: payerFanId` — **"Subscribe to quarterly
  autopay"** and **"Request refund"**. The board's card offers neither. Guard evaluation is therefore
  resolving the acting identity correctly, not just the role.

## Findings

1. **The create control is on the Admin tab, not Giving.** "New dues charge" is declared on the
   `admin` renderBinding (`presentation: "fab"`, `byRoleIds: ["hoa-board"]`). The Giving tab has no
   create affordance for dues in any role. A walkthrough that looks for the dues create on the Giving
   tab will correctly conclude it is absent, and be looking in the wrong place. Not a defect — worth
   recording because the ticket anticipated it on Giving.

2. **The "zero seeded instances" premise is wrong, and the real blocker is narrower.** Cedar ships at
   least **two** seeded `hoa-dues-payment` instances, both visible to the board:
   - `2026 second-quarter HOA assessment`, $425, Due 2026-06-15 — **Paid**, history
     `Offline payment recorded / hoa-board / 2026-06-10T14:35:00-07:00`
   - `2026 third-quarter HOA assessment`, $425, Due 2026-09-15 23:59, method `ACH ending in 1842` —
     **Dues due**, history `Quarterly assessment posted / hoa-board / 2026-08-01T09:00:00-07:00`

   Both name `payerFanId: hoa-member` — a seed id, not any account a live persona can be issued. Since
   the workflow is `guarded` with `readGuard.allowedRoleIds: ["hoa-board"]` and parties keyed on
   `payerFanId`, a **freshly created Homeowner is not a party to either**, so they are invisible to
   her. Confirmed directly: on Maya's Giving tab the charge created in this run is the *only* dues
   card present; neither seeded instance appears.

   So the original BLOCKED finding was right about the symptom and wrong about the cause. It is not
   "no instances exist" — it is "the seeded instances are addressed to a fan id no live persona can
   hold, and creating one is board-only". A second, board-role persona is the fix, which is what this
   run did.

3. **UI quirk, cosmetic, no data impact.** While the soft keyboard is up, the create dialog collapses
   to show only the focused field plus the action row; the remaining fields are not scrollable into
   view until the keyboard is dismissed. Every value survived correctly — verified field-by-field
   after each entry — so this cost extra steps, not correctness. Recording it because it makes the
   form look like it lost its fields mid-entry.

## Stability

- No crash, no ANR, no blank frame observed across the whole run.
- `mCurrentFocus` was
  `Window{2656ba1 u0 com.example.loom_communities_demo/com.example.loom_communities_demo.MainActivity}`
  at every check, including immediately after both submits.
- `logcat -d -t 4000` filtered for `FATAL EXCEPTION|ANR in|Force finishing` returned **zero** lines.
  Control: the same buffer contains 79 lines mentioning `loom_communities_demo`, so the filter was
  reading a populated log rather than an empty one.

## Scope note

No test suites were run — this ticket is a live-device walkthrough and changed no code. Nothing was
committed. No file other than this manifest was created or modified; no community `*.jsonc` and
nothing under `docs/references/**` was touched.

## Independent verification (orchestrator, by eye)
`cedar-dues_49_payer_paid.png` pulled byte-identically and viewed: confirms the payer's (Maya's) own
Giving tab shows "Receipt: Offline payment recorded", "Paid 2026-09-05T01:15:19.251547Z", the exact
history note ("Check 4417 received at the HOA office on 2026-09-04...") with "Actor Fan Id:
hoa-board-21", and the two member-only actions "Subscribe to quarterly autopay" / "Request refund".
Real, live, submitted-for-real create-to-terminal-state sequence, genuinely closing this row.

## B25 tally update
Cedar Commons HOA's dues gap is now CLOSED via live multi-persona write (not seeding, not accepted as
incomplete) -- 4 of 5 original isolated gaps remain: Book Club Messages, Chess disputes, Camera Club
(Critique + Messages), Garden Club Messages.
