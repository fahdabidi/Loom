# Ad-Free Community — live agent walkthrough (B25 coverage pass)

- **Filename date:** 2026-09-03 (as specified by the ticket).
- **Actual run date/time:** 2026-09-04, 04:51–05:06 device local time. The device clock and every
  screenshot in the index below read `09-04`. Recorded here rather than silently adopting the
  filename's date.
- **Community:** Ad-Free Community (`ext_ad_free_community`, package
  `app/packages/core/loom_communities_app_shell/assets/Loom_Communities_Workflow_Engine_AdFreeCommunity_Example.jsonc`)
- **App:** `com.example.loom_communities_demo` / `MainActivity`, emulator-5554, 1080x2400.
- **adb path:** Windows-hosted `emulator-5554` over the pre-wired SSH reverse tunnel to adb on
  127.0.0.1:5037. `adb -s emulator-5554 get-state` = `device` at start and at end. No
  `kill-server` / `start-server` / `connect` / `disconnect` / `-a` was run, and
  `ANDROID_ADB_SERVER_ADDRESS`/`_PORT` were never set. The tunnel was intact for the whole run.

## Personas

| # | Display name | Role chosen | Assigned role (as rendered) | Fan id |
|---|---|---|---|---|
| 1 | Ada Member | **Default** — the Role field pre-selected `Member` | `Member` — "Member - Buys personal ad-off and privately manages entitlement, receipts, and suppression proof." | `ad-off-member-20` |
| 2 | Ola Owner | `Owner` (explicitly selected) | `Owner` — "Owner - Records payment outcomes, funds community ad-off, and audits settlement and utility allocation." | not surfaced in-app; created via the same Create New Account form |

The role dropdown offers exactly two values: **Member** and **Owner**. `Member` is the default —
recorded before signup (screenshot 08) and again on the second visit to the picker (27).

Package oracle: `experience.roles` declares `ad-off-member` (label `Member`) and `ad-off-owner`
(label `Owner`). Two roles, matching the "2 roles" chip in the app.

## Entry-path note (not a defect)

The first tap on the community list landed on **Export and Migration**, not Ad-Free Community: the
list was still settling from a fling when the tap was dispatched, so the row under the coordinate
had changed by the time it registered. The identity gate's own footer — "Choose an active account or
create one to continue to **Export and Migration**." — is what caught it. Backed out, re-tapped on a
settled frame, and the footer then read "…to continue to **Ad-Free Community**." (screenshot 06).
The footer naming its destination is what made a mis-tap self-evident rather than silent.

## Per-tab table

The bottom bar was swipe-tested for horizontal overflow under **both** roles. Under Member, two
consecutive left-swipes left the bar region **pixel-identical** (3 tabs is the whole set). Under
Owner the bar scrolls by ~31px and then stops — the tab-bar region of two consecutive post-swipe
frames diffs to `None`, exposing **no fifth tab**. Four is the end.

### Persona 1 — Ada Member (`Member`), 3 tabs

| Tab | Primary affordance (exact label) | Alternate affordance (exact label) | Notes |
|---|---|---|---|
| **Home** | *none found* | *none found* | Renders exactly one card, "Settlement recorded", with **zero** action buttons. Only interactive control on the surface is the `Local package details` disclosure (developer metadata: `Package / ext_ad_free_community`, `Accent`). Classified below. |
| **Giving** | `Buy ad-off` (FAB, bottom-right) | *none found* | Tab body renders **zero** workflow cards. The FAB is a single button, not a speed dial — correct, since only one create action is available to this role. |
| **Messages** | *none found* | *none found* | No cards, no FAB, no compose control. Classified below. |

### Persona 2 — Ola Owner (`Owner`), 4 tabs

| Tab | Primary affordance (exact label) | Alternate affordance (exact label) | Notes |
|---|---|---|---|
| **Home** | `Record entitlement inactive` | `Mark audited` | Also `Attach verified receipt link`, `Export audit`, `Record refunded allocation`. Five seeded cards render: Ad-off active, Payment failed, Entitlement active, Receipt issued, Settlement recorded, Suppression proof ready. |
| **Giving** | `Fund community ad-off` (FAB) | `Record entitlement inactive` | Also `Attach verified receipt link`. `Buy ad-off` is **absent** for this role. |
| **Admin** | `Mark audited` | `Record refunded allocation` | Also `Export audit`, `Attach verified audit link`. No FAB — correct; the package binds no create action to `tabId: "admin"`. Header: "Settlement, allocation correction, and audit operations. Tuned for Owner." |
| **Messages** | *none found* | *none found* | Identical emptiness to Persona 1. |

## Create-form observation

Surface: **Giving → `Buy ad-off`** (the only create affordance Persona 1 can use).

Fields, in render order (screenshot 24):

| # | Label | Control |
|---|---|---|
| 1 | `Price` | single-line text |
| 2 | `Currency` | single-line text |
| 3 | `Plan` | single-line text |
| 4 | `Coverage Description` | single-line text |
| 5 | `Paying with` | single-line text |
| 6 | `Disclosure accepted` | toggle, default **off** |

Buttons: `Cancel`, `Create`. Title: `Buy ad-off`.

All six map 1:1 onto `ad-off-member-checkout`'s instance data
(`priceAmount`, `currency`, `billingPeriod`, `coverageDescription`, `paymentMethodLabel`,
`disclosureAcknowledged`) and every one carries a human label — **no bare camelCase keys in this
form**.

**Cancel verified clean.** Dismissed via `Cancel`; nothing submitted. Pre-frame (23) vs post-frame
(25) diffed with PIL: the full-frame difference bounding box is `(134, 47, 966, 80)` — entirely
inside the status bar, i.e. the clock advancing 04:58 → 04:59. Cropping to `y >= 120` (everything
below the status bar) the difference bounding box is **`None`**: the two frames are pixel-identical.

## Absence classification

Every "absent" below was checked against the ticket's rule before being recorded: scrolled to both
ends (confirmed by byte-identical consecutive frames), disclosures expanded, taps confirmed to
register, and then cross-checked against the shipped package.

**Tap-registration control:** the `Local package details` disclosure on Member/Home expanded on tap
and revealed `Package / ext_ad_free_community` (13), then collapsed on a second tap. Taps on that
surface register — the emptiness is not a dead frame.

| Surface | What is missing | Verdict | Evidence | Seeded data? |
|---|---|---|---|---|
| **Member / Home** — action buttons on the "Settlement recorded" card | every state transition | **role-gated** | Card renders identically for both roles, but Persona 1 sees zero buttons (11) and Persona 2 sees four on the same card (39): `Mark audited`, `Record refunded allocation`, `Export audit`, `Attach verified audit link`. Package: all 7 `ad-off-settlement-utility` transitions carry `guard.allowedRoleIds: ["ad-off-owner"]`. | **Yes** — `ad-off-settlement-review`, state `settled`. It renders for Persona 1; only the actions are withheld. |
| **Member / Giving** — workflow cards | all 5 member-side instances | **identity-scoped** | Tab body empty at both ends for Persona 1 (17, 18) with the `Buy ad-off` FAB present. Persona 2 renders the very same instances (29–33, 42). Persona 1's fan id is **`ad-off-member-20`** (read off the role dialog, 22); every seeded instance carries `memberFanId: "ad-off-member"`. The guard is `readGuard.actorEqualsField(memberFanId)` — a different id, so no match. Owner sees them because `visibility.fields.parties` also lists `{"role": "ad-off-owner"}`. | **Yes — 5 instances**: `ad-off-checkout-active`, `ad-off-checkout-retry`, `ad-off-entitlement-active`, `ad-off-receipt-issued`, `ad-off-suppression-proof`, all under `ad-off-member`. |
| **Member / bottom bar** — the `Admin` tab | the whole tab | **role-gated** | Absent for Persona 1 across two swipe-confirmed ends (14, 15); present for Persona 2 (29). Package: `appShell.tabs[admin].visibleRoleIds: ["ad-off-owner"]`. | n/a (tab, not data) |
| **Member / Giving** — `Fund community ad-off` | the owner create action | **role-gated** | Persona 1's FAB reads `Buy ad-off` (16); Persona 2's reads `Fund community ad-off` and `Buy ad-off` is gone (37). Package declares exactly two create actions, `byRoleIds: ["ad-off-member"]` and `["ad-off-owner"]` respectively. | n/a |
| **Messages (both roles)** | any card, any create control | **unseeded/unwritable** | Empty under **both** roles (19/20 and 41), scroll-end confirmed by identical consecutive frames, no FAB, no compose control. Package grep with a control: `"tabId"` occurrences are `admin`=2, `giving`=8, `home`=6 (control returns hits), `messages`=**0**. No workflow anywhere binds to a messages surface, so there is nothing to seed and nothing to write. Note `ad-off-notification` — the one messaging-shaped workflow — binds to `tabId: "home"`, not messages. | **No** — no messages-bound surface exists in the package at all. |
| **Identity picker** — the seeded fan accounts | `ad-off-member` / `ad-off-owner` as signable identities | **unwritable (by design, but limits verification)** | "Sign in as a specific person… / Use one of this community's individual accounts" (22) opens the picker, which lists only accounts created in-session — after Persona 1, exactly one entry, `Ada Member / ID: ad-off-member-20` (26). The seeded fan ids are not offered. | n/a — see B25 note below. |

### A query that was wrong, and how it was caught

My first pass grepped the transitions for `byRoleIds` and got `None` on all seven settlement
transitions, which would have made Member/Home's missing buttons look **ungated** — i.e. a product
bug. The observed UI contradicted it (Owner plainly had the buttons). Dumping a whole transition
object showed the real key is **`guard.allowedRoleIds`**; `byRoleIds` is the key used for *create
actions* on render bindings, a different thing. Re-run against the correct key, all 7 settlement
transitions gate to `ad-off-owner` and the UI is correct. Recording it because the empty result read
exactly like a finding.

## Rendering bugs

Ordered by severity. All are in the **card/detail renderer**, not the create form.

1. **Engine-internal sigil keys leak into the UI.** The "Suppression proof ready" card carries a
   `Linked Entitlements` block that renders the linked instance's raw record, ending with two lines
   an end user should never see:
   `$state: active` and `$id: ad-off-entitlement-active`.
   Screenshots 32, 33. Every other line in that block has a humanized key ("Member Fan Id",
   "Renewal Date"); these two are bare.
2. **Dart list literal printed verbatim in the same block.**
   `Affected Ad Surfaces: [Home feed promotions, Giving surfaces, Community ad slots]` — square
   brackets are `List.toString()`. This is provably the wrong path rather than a styling choice,
   because the **sibling chip on the same card** renders the *same* array correctly comma-joined
   with no brackets: `Suppressed ad surfaces: Home feed promotions, Giving surfaces, Community ad …`.
   Two renderers, one array, different output.
3. **Raw boolean.** `Reminder Enabled: true` in the same block — the engine value, not "On"/"Yes".
   Note the card's own chip does this correctly elsewhere: `Ads suppressed now: Yes`.
4. **Raw ids shown instead of names.** `Payer: Ad Off Member` and
   `Entitlement purchase: Ad Off Checkout Active` (31, 42) are the slugs `ad-off-member` and
   `ad-off-checkout-active` title-cased, not display names. The `Linked Entitlements` block does not
   even title-case them: `Member Fan Id: ad-off-member`,
   `Checkout Instance Id: ad-off-checkout-active`.
5. **Raw ISO-8601 timestamps in user-facing chips.** `Funded 2026-08-01T09:08:00Z`,
   `Settled 2026-08-02T15:30:00Z`, `Active since 2026-08-15T10:05:00Z`,
   `Issued 2026-08-15T10:05:00Z`. Date-only fields in the same cards render cleanly
   (`Coverage ends 2026-10-30`, `Renews 2026-09-15`), so the gap is specifically datetime formatting.
6. **Money rendered as a bare double with no currency.** `Funded amount: 250.0`, `Price: 4.99`,
   `Price: 49.0`, `Amount: 4.99`. Every one of these instances carries `"currency": "USD"` in its
   instance data and none of it reaches the screen; `49.0` and `250.0` also read as unformatted
   floats rather than `49.00` / `250.00`.
7. **Clipped content.** `Suppressed ad surfaces: Home feed promotions, Giving surfaces, Community ad …`
   truncates at two lines (32, 33) while the unstyled block below shows the full value — so the
   truncated chip is the *only* place the value is presented properly and it is the one cut off.
8. **Minor — label casing is inconsistent in the create form.** `Coverage Description` is Title Case
   while `Paying with` and `Disclosure accepted` are sentence case (24).
9. **Minor — the identity picker's group heading reads `Member (Member)`** (26, 27), repeating the
   role label. Harmless but reads like a formatting placeholder.
10. **Minor — the FAB overlaps the `Local package details` disclosure row** at one scroll position on
    Giving (17), covering the only interactive control on that row. Standard floating-FAB behaviour;
    noted only because that row is interactive.

No pluralization defects were observed ("2 roles" is correct and no other counted noun appears).

## Stability

- **No crash, no ANR, no blank frame.** Every one of the 44 captures rendered content.
- `mCurrentFocus` at start **and** at end:
  `Window{8367a32 u0 com.example.loom_communities_demo/com.example.loom_communities_demo.MainActivity}`
  — same window id throughout, so the activity was never restarted.
- logcat sweep, using `grep -ac` throughout (never `grep -c … || echo 0`, which yields `"00"`):

| Pattern | Count |
|---|---|
| **CONTROL** `loom_communities_demo` | **1265** (pre) / **1216** (post) — non-zero, so the buffer is real and the greps work |
| `FATAL EXCEPTION` | **0** |
| `ANR in` | **0** |
| `E/flutter` | **0** |

  The control is the load-bearing part: a zero for `FATAL EXCEPTION` means nothing unless a pattern
  that must match does. (The post-run control is *lower* than the pre-run one because the ring
  buffer rotated, not because lines were lost from the app.)
- `Exception` matches 183 lines, all traced and none attributable to the app: 136 are the literal
  token `11`, 21 are `No such file or directory`, 4 are `package android.xr cannot be found`, and 10
  are `android.os.DeadObjectException`. Only **one** package-related exception falls inside the
  session window (04:51–05:06) — at `04:51:19.932`, a `W`-level WindowManager
  `Exception thrown during dispatchAppVisibility Window{… MainActivity EXITING}` raised in
  **system_server** (pid 702) against an already-dead window from a *previous* app instance. It is a
  teardown race in the system, not a fault in this session's process. The other nine are dated
  09-03 22:36 through 09-04 04:23, all before the run.

## Screenshot index

Transient (`*.png` is gitignored); paths are `/tmp/`, sizes in bytes, all 1080x2400.

| # | File | Bytes | What it shows |
|---|---|---:|---|
| 01 | `adfree-community_01_list.png` | 316158 | Community list, "Loaded 10 example communities" |
| 02 | `adfree-community_02_list_scroll.png` | 304623 | List scrolled, Ad-Free Community card visible |
| 03 | `adfree-community_03_open.png` | 263312 | List settled (pre-navigation) |
| 04 | `adfree-community_04_entry.png` | 124089 | **Wrong** gate — footer names Export and Migration |
| 05 | `adfree-community_05_back.png` | 263323 | Back on the settled list |
| 06 | `adfree-community_06_gate.png` | 121635 | Correct gate — "…continue to Ad-Free Community", Role=**Member** |
| 07 | `adfree-community_07_name.png` | 181043 | Display name "Ada Member" entered |
| 08 | `adfree-community_08_roles.png` | 127352 | Role dropdown: Member (highlighted) / Owner |
| 09 | `adfree-community_09_presignup.png` | 125817 | Pre-signup, Member selected |
| 10 | `adfree-community_10_home.png` | 205817 | Persona 1 Home, "Signed in as Ada Member / Member", 3 tabs |
| 11 | `adfree-community_11_home2.png` | 179679 | Member Home scrolled — one card, **no action buttons** |
| 12 | `adfree-community_12_home3.png` | 179679 | Byte-identical to 11 → scroll end |
| 13 | `adfree-community_13_home_disclosure.png` | 204094 | `Local package details` expanded — tap-registration control |
| 14 | `adfree-community_14_tabswipe1.png` | 180739 | Tab bar after swipe 1 (Member) |
| 15 | `adfree-community_15_tabswipe2.png` | 180743 | After swipe 2 — tab region identical → 3 tabs is all |
| 16 | `adfree-community_16_giving.png` | 185548 | Member Giving, FAB `Buy ad-off`, zero cards |
| 17 | `adfree-community_17_giving_top.png` | 209127 | Giving scrolled to top |
| 18 | `adfree-community_18_giving_bottom.png` | 185097 | Giving scrolled to bottom — still zero cards |
| 19 | `adfree-community_19_messages.png` | 180591 | Member Messages — empty |
| 20 | `adfree-community_20_messages_bottom.png` | 180591 | Messages scroll end |
| 20b | `adfree-community_20b.png` | 180591 | Identical to 20 → confirmed end |
| 21 | `adfree-community_21_appbar_chat.png` | 180641 | AppBar chat icon — no-op (Messages already selected) |
| 22 | `adfree-community_22_appbar_people.png` | 232861 | "Account role and permissions" — **`ID: ad-off-member-20`** |
| 23 | `adfree-community_23_pre_create.png` | 193418 | **Pre-frame** for the cancel test |
| 24 | `adfree-community_24_createform.png` | 73480 | `Buy ad-off` form — 6 fields, Cancel/Create |
| 25 | `adfree-community_25_post_cancel.png` | 193193 | **Post-frame** — identical to 23 below the status bar |
| 26 | `adfree-community_26_specific_person.png` | 115443 | Identity picker — only `Ada Member` listed |
| 27 | `adfree-community_27_role_owner.png` | 120291 | Persona 2 name entered, role dropdown open |
| 28 | `adfree-community_28_owner_selected.png` | 118664 | Owner selected |
| 29 | `adfree-community_29_owner_home.png` | 221647 | Persona 2 Home — **4 tabs incl. Admin**, seeded checkout visible |
| 30 | `adfree-community_30_owner_home2.png` | 215250 | Payment failed + Entitlement active + `Record entitlement inactive` |
| 31 | `adfree-community_31_owner_home3.png` | 225909 | Receipt issued + Settlement recorded + `Mark audited`; raw-id chips |
| 32 | `adfree-community_32_owner_home4.png` | 240441 | **`Linked Entitlements` block — `$state` / `$id` / `[...]` leak** |
| 33 | `adfree-community_33_owner_home5.png` | 214267 | Same block, full view; scroll end |
| 34 | `adfree-community_34_owner_home6.png` | 214267 | Identical to 33 → end confirmed |
| 35 | `adfree-community_35_tabswipe_owner1.png` | 214261 | Owner tab bar after swipe 1 |
| 36 | `adfree-community_36_tabswipe_owner2.png` | 214261 | After swipe 2 — tab region diff `None` → 4 tabs is all |
| 37 | `adfree-community_37_owner_giving.png` | 238007 | Owner Giving — FAB `Fund community ad-off`, `Buy ad-off` gone |
| 38 | `adfree-community_38_owner_admin.png` | 241749 | Admin tab — "Tuned for Owner" |
| 39 | `adfree-community_39_owner_admin2.png` | 176658 | Admin actions: Mark audited / Record refunded allocation / Export audit / Attach verified audit link |
| 40 | `adfree-community_40_owner_admin3.png` | 176658 | Identical to 39 → scroll end |
| 41 | `adfree-community_41_owner_messages.png` | 183884 | Owner Messages — empty under this role too |
| 42 | `adfree-community_42_owner_giving2.png` | 220426 | Owner Giving scrolled — in-tab affordances |

## Pipeline result

**Functional end to end, with a renderer defect cluster.** The rig drove a real emulator through
community selection, two persona creations, all tabs under both roles, a create form and a clean
cancel, with zero crashes and zero ANRs. Every visibility behaviour observed in the app matched the
shipped package's declarations independently re-derived from the JSON — role-gated tab, role-gated
create actions, role-gated transitions, and identity-scoped guarded instances all behaved exactly as
declared. The app's *access control* is correct.

What is not correct is **presentation of linked records**: the `Linked Entitlements` block bypasses
the chip renderer entirely and dumps engine-internal state (`$state`, `$id`), a Dart list literal, a
raw boolean and raw ids to an end user. The proof that this is a defect rather than a design choice
is on the same card — the chip above it renders the same array correctly. Money and datetime
formatting are missing across every card in the community.

## B25 coverage

### Provable now

- Community opens, themes, and gates on identity; the gate names its destination, which is what made
  a mis-tap self-evident.
- Persona creation with the **default** role, and with an explicitly chosen second role.
- Full tab enumeration under both roles, with horizontal overflow ruled out by frame-identity rather
  than assumption (3 tabs Member, 4 tabs Owner).
- Create affordance discovery, form field enumeration, and **cancel-is-clean** proven by pixel diff
  rather than by eye.
- Absence classification for all five empty surfaces, each with a package-level oracle **and** a
  control query, and each distinguishing role-gating from identity-scoping from genuine absence.
- Stability: focus stable, 0 FATAL EXCEPTION, 0 ANR, 0 E/flutter, against a non-zero control.

### Blocked, and why

- **No workflow was advanced to a new state.** Every capture is read-only by design — the ticket
  directs cancelling without submitting, so no `Create` and no transition (`Mark audited`,
  `Record entitlement inactive`, …) was fired. State-transition behaviour, effect writes and
  post-transition rendering are therefore **unproven** by this run.
- **The member-side view of the seeded instances cannot be reached by any signable account.** The
  identity picker offers only in-session accounts; `ad-off-member` and `ad-off-owner` are not
  selectable. Persona 1's absence is confirmed *identity-scoped* by inference from the guard plus
  Owner's party-clause view of the same instances — which is solid — but the specific rendering a
  seeded member would see (their own checkout, entitlement, receipt and suppression cards on Giving)
  was never displayed under a member identity. Closing that gap needs either a seeded-identity
  sign-in path or a member-role persona whose fan id is `ad-off-member`.
- **The owner-side create form was not opened.** `Fund community ad-off` was identified and
  photographed but not tapped; only `Buy ad-off`'s form was enumerated. The ticket asks for one
  create affordance, so this is scope, not failure — but `ad-off-community-checkout`'s field set is
  unverified.
- **Rendering defects are reported, not fixed.** Per the standing rules, application code changes go
  through `data/call_implementation_agent.sh`; nothing was edited here.

## Independent verification (orchestrator, by eye)
`adfree-community_32_owner_home4.png` pulled byte-identically and viewed: confirms four rendering bugs
on one card simultaneously — leaked engine sigils `$state: active` / `$id: ad-off-entitlement-active`,
raw boolean `Reminder Enabled: true`, and the Dart list literal `Affected Ad Surfaces: [Home feed
promotions, Giving surfaces, Community ad slots]` with brackets, sitting directly below the correctly
comma-joined sibling chip. Also confirms the three owner-only action buttons (`Record refunded
allocation`, `Export audit`, `Attach verified audit link`).

## Significance: the security model's guard mechanism, read directly from the package
This walkthrough went one level deeper than prior ones: rather than only observing role differences, it
read the package's raw JSON guards and traced each empty surface to its actual mechanism —
`guard.allowedRoleIds` on settlement transitions, `readGuard.actorEqualsField(memberFanId)` on Giving
instances, `visibility.fields.parties` explaining why Owner (but not a fresh same-role persona) can see
Member-owned records. Every empty surface resolved to a *correct, declared* access-control rule, not a
gap. This is a direct, code-level confirmation that the target security model's per-user-id and
per-role data scoping is implemented and working in the deployed app.

## Running tally (8 rigorous walkthroughs)
Cedar (1: dues), Book Club (1: Messages), Chess (1: disputes), Masjid Nur (0), Youth Soccer (0),
Garden Club (1: Messages), Camera Club (2: Critique identity-scoped + Messages), Ad-Free Community
(0 genuine gaps — Messages is unwritable by package design, everything else is correctly guarded).
Richest rendering-bug find yet: 10 distinct defects, most severe being unformatted currency
(`Funded amount: 250.0`, no "$", no 2-decimal format) and leaked engine-internal sigil keys.
