# B25 — Data Portability run plan (the campaign's single biggest lever)

Written 2026-09-12 from a reachability sweep of the shipped package, not from the tracker. Every
claim below was derived by parsing `Loom_Communities_Workflow_Engine_DataPortabilityCommunity_Example.jsonc`
and checking the live backend; re-derive rather than trust this file if it is more than a few days old.

## Why this community, ahead of the rest of the queue

Of the 43 rows needing only a walkthrough, **8 belong to Data Portability, and all 8 are created by
ONE role (`portability-owner`) from ONE tab (`admin`)**. No other community in the queue clusters
like this — Book Club splits across two roles, Masjid across two, Cedar's remainder needs `hoa-board`
or is only reachable through cross-type effects. One sign-in here is worth more than the rest of the
queue combined: it would move the bar **15 → 23 of 72**.

## Pre-flight, already verified — do not re-litigate these

| Check | Result |
|---|---|
| Seeding layer 1 — Keycloak + `fanId` attribute | `loom-portability-owner-1` returns HTTP 200, claim `fanId: fan-portability-owner-1` |
| Seeding layer 2 — `fan_passport` row | present (`fan-portability-owner-1`, created 2026-09-07) |
| Seeding layer 3 — membership + role grant | `portability-owner` has **2** holders, both `active` |
| Published definitions | 85/85 declared types published; no silent no-op creates |
| Tab visibility | `admin` declares `visibleRoleIds: ["portability-owner", "portability-receiving-provider"]` |
| `role_kind` | `portability-owner` is `package_domain`; the generated admin is `community_system_admin` — correctly separated |

**Three identifiers, none derivable from another.** App Access group is
`loom_communities_data-portability-community`; the workflow-service `community_id` is
`community_data_portability` — it drops the handle's trailing `-community` — and instance ids are
`community_data_portability_<workflowType>_<suffix>`. The obvious guess
(`community_data_portability_community`) is wrong. Verified against the live `export-full-bundle` row.

## The sweep result

**7 of the 8 rows are drivable end to end by `portability-owner` alone.** Only
`export-transfer-verification` has a foreign guard, and even it has an owner-only terminal exit.

| Row | Owner-only? | Note |
|---|---|---|
| `export-schema-listing` | yes | `lock` needs `schemaNames` + `includedComponents` non-empty; unconditional `retire` always reaches terminal |
| `export-protected-redaction` | yes | `preview` needs `protectedFields` non-empty; `confirm` needs `protectedChoiceConfirmed == true` |
| `export-checksum-evidence` | yes | `verificationResult` is **formEntry**, so a human types `passed` — see the platform-service note below |
| `export-redacted-bundle` | yes | `download` needs `redactionValidationResult == 'passed'` |
| `export-import-replay` | yes | every transition also allows the provider role, but owner alone suffices |
| `export-import-preview` | yes | richest graph: 7 states, three `operationType`-discriminated starts |
| `export-transfer-verification` | **partly** | `verified` needs `portability-receiving-provider`; `cancel-provider-transfer-awaiting` gives the owner a terminal exit |
| `export-transfer-rollback` | yes | **has no standalone create** — see below |

### `export-transfer-rollback` has no create FAB, and that is not a defect

It is created only by a `scope: "instance"` button labelled **"Request rollback"**, rendered on an
`export-transfer-verification` card in states `transferring`, `awaiting-provider`, `failed` or
`verified`, prefilling `sourceTransferInstanceId: "{context.id}"` and `rollbackAvailable: true`.

`transferring` is owner-reachable (`start-provider-transfer`, needing only `size(transferScope) > 0`),
so **one owner-only run can bank BOTH rows**: create the transfer, start it, press "Request rollback",
drive the rollback `available → running → complete`, then take the transfer to a terminal state via
`cancel-provider-transfer-*`. Do not brief these as two separate runs.

### The checksum row does NOT depend on the missing platform service

`export-checksum-evidence` looked like it would be blocked by the unbuilt checksum service. It is not.
The `checksum` field is `writableBy: "platform"`, `platformSource: "checksum"` — but it is typed
`text?` with `hideWhenEmpty: true`, so it is an **honest unwritten declaration**, not a blocker. The
field the guards actually read, `verificationResult`, is `writableBy: "formEntry"` and `required`.
A person types it. The row is drivable today; the empty `checksum` is the designed state.

## Suggested order

1. `export-schema-listing` — dispatched 2026-09-12
2. `export-checksum-evidence` — shortest graph, good second proof of the session
3. `export-protected-redaction`
4. `export-redacted-bundle`
5. `export-import-replay`
6. `export-import-preview` — richest, leave until the session is known-good
7. `export-transfer-verification` + `export-transfer-rollback` — **one run, two rows**

Keep the same signed-in identity across all of them: every identity switch risks the stale-SSO trap,
which fails green in both directions. Only step 7 might warrant a second identity, and only if the
`verified` outcome is wanted rather than the owner-only terminal exit.

---

# Phase two — the judge half, and why it must be PAIRED with the walkthrough

Traced 2026-09-12. This section exists because the obvious sequencing is wrong and would cost a
whole second pass over the device.

## The constraint

A judge run does not look at a device. It reads **PNG files at explicit paths** and applies a rubric
to them — `call_ux_judge_agent.sh` runs on a vision-capable model precisely so it can, and a real
judge prompt lists each frame as
`docs/Build Plan V2/Evidence/B15/screenshots/B15_ext_chess_club_<workflow>_<state>.png`.

**Those frames do not survive.** `.gitignore:7` is a blanket `*.png`, so no capture is ever
committed, and today there are **zero** PNGs anywhere in the tree newer than the campaign's own
start. The live-verification run directories hold `output.log` and nothing else. The
`chess-club-night` manifest says so in its own words: *"Screenshots were captured at every step but
`*.png` is gitignored, so they are transient."*

**So a walkthrough's evidence cannot be judged later.** By the time anyone looks, the pixels are
gone.

## What follows for the remaining 14 both-halves rows

**Do NOT run 14 walkthroughs and then 14 judge runs.** The first pass's frames would be gone before
the second pass began, and every row would need capturing twice. Pair them instead: for each row,
capture/drive and judge **in the same sitting**, then commit the verdict — which is the durable
artifact and the thing the bar actually counts.

The capture pipeline already exists and is not manual `adb`:

    app/packages/tooling/loom_ux_judges/bin/b25_capture_workflow_screenshots.dart
      --device emulator-5554
      --app-package com.example.loom_communities_demo
      --mode full-b25 | targeted-precheck
      --phases B12,<the community's own phase>

**`--phases` is not optional and not cosmetic.** Each community has exactly ONE phase it has
coverage in, and asking for a phase it lacks is a hard failure — pass `B12` plus that community's
own phase. Chess Club is **B15** (`"phase": "B15"`, `appId: ext_chess_club`, per its legacy review
input).

## `chess-club-night` is the cheapest +1 on the board, but it is NOT free

It already has a live write (2026-09-12, proven) and no judge artifact, so it is the only row on the
bar needing just one half. But its frames are gone, so it needs a **fresh capture** before a judge
can see anything. Budget a capture run, not merely a judge dispatch.

**Do not be fooled into thinking it is already judged.** The legacy Chess judge artifact
(`phase-a-legacy/chess-club/llm-vision-ux-review-phaseA-legacy-chess-club-1.json`) *contains the
string* `chess-club-night` — but it has **no `workflowId` field at all**, and the string appears
only inside screen ids such as `chess-club-chess-club-night-start`. A screen id is derived FROM a
workflow id, so its slug resembles a bar key without being one. I checked this specifically on
2026-09-12 while chasing exactly that false positive.

## Device contention

Captures and walkthroughs both need the emulator, so they serialize. Do not start a capture while a
walkthrough is running — and note this is a *device* constraint, separate from the load constraint
on the VM. Check both.

---

# Post-Data-Portability queue order — REVISED 2026-09-12 by the parity gate

`check_permission_parity.sh` reports live drift on five package-derived role sets. **Two of the
queue's biggest clusters are affected and should be DEFERRED until the grants are fixed**, because a
missing derived permission is exactly what produced the live `403` on Cedar's
`hoa-facility-reservation` earlier in this campaign.

## Defer until the parity drift is remediated

| Cluster | Rows | Why |
|---|---|---|
| Neighborhood Book Club | 7 | `book-member` and `book-organizer` each missing derived permissions (`document_library.download`, `equipment_loan.*`, `event_rsvp.withdraw_response`) |
| Riverside Youth Soccer | 6 | `soccer-owner` missing `export_wizard.download` (hits `soccer-export-metadata`); `soccer-guardian` missing `document_library.download`; `soccer-coach` holds `document_library.upload` where the package derives `document_library.edit` (hits `soccer-waiver-document`) |

That is 13 of the 34 remaining walkthrough-only rows. Walking them first would likely burn runs on
403s and produce "missing affordance" findings that are really provisioning gaps.

## Safe to walk now — the gate flagged none of these roles

**Masjid Nur is safe despite being the community with the famous over-grant.** The rule-1 violation
is on **`masjid-nur-admin`**, the generated governance role. Masjid's walkthroughs use the *domain*
roles `owner` (2 holders) and `community-member` (2 holders), and **neither was flagged** — both
passed the exact-set comparison. Do not skip Masjid on the strength of the admin finding; that would
be conflating governance and domain roles, which is the same confusion that caused the over-grant in
the first place.

Suggested order, largest clean cluster first:

1. **Masjid Nur** — 7 rows. Splits across two identities: `owner` creates announcement / event /
   volunteer shift / resource; `community-member` creates donate / request care; "Ask Masjid Nur"
   and "New discussion" allow both. **Note `mosque-discussion-thread` binds `tabId: "messages"`** —
   AP-14, the shell ignores community bindings there, so it will not render. It is in the
   both-halves set, not this queue, but do not brief it blind.
2. **Ad-Free Community** — 4 rows, `ad-off-member` and `ad-off-owner`.
3. **Member Social Space** — 4 rows, `moderator` creates the three provisioning workflows,
   `member` creates messages/invites.
4. **Cedar Commons HOA** — 4 rows, all needing `hoa-board`; two of them
   (`hoa-committee-decision`, `hoa-owner-notification`) have **no create action at all** and are
   only produced by cross-type effects from `hoa-architectural-request`, so they pair the same way
   the transfer rows do.
5. **Garden Club** — 2 rows.

## Re-run the gate before each cluster

It takes under a minute and it is the only thing standing between a briefed run and a 403 that
looks like a product defect:

    bash "docs/Build Plan V2/Tools/code/check_permission_parity.sh"

A gate nobody runs is a gate that does not exist — that is how six live violations sat unread after
the tool that finds them was built and closed as done.
