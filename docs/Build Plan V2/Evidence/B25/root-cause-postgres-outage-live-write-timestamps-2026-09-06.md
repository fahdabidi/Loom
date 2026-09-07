# Root cause: B25 "live-write" closures with no trace in the live database, spanning a confirmed Postgres outage

**Headline, updated same day as first written:** what started as "3 rows have a suspicious
timestamp" is now "all 16 live-verification dispatches from Sept 3 evening through Sept 5 morning
correspond to zero rows in the live database" — see "Scope escalation" below. The 3-row framing in
the rest of this document is the part I've most rigorously checked (timestamp vs. confirmed outage
window); it is a lower bound, not the full extent.

**Date found:** 2026-09-06, during a routine autonomous tracker sweep (unrelated task — the Cedar
document-content upload ticket led here by accident, while minting a real fan JWT to test the
document-upload API and finding the target instance didn't exist in the live database).

**Status: DECIDED 2026-09-07 (user) — reopen and re-verify all 16, now.** See the decision section
near the end of this doc for the full directive and execution plan.

## The claim

Three community "live-write" B25 evidence docs, all authored 2026-09-04, each claim to have created a
real workflow instance and driven it to a terminal state via a live device walkthrough against the
deployed cluster, each citing a server-recorded engine timestamp as part of that proof:

| Evidence doc | Community | Claimed terminal transition | Recorded server timestamp |
|---|---|---|---|
| `cedar-dues-live-write-2026-09-04.md` | Cedar Commons HOA | `record-offline-payment` → `paid` | `2026-09-05T01:15:19.251547Z` |
| `camera-club-critique-live-write-2026-09-04.md` | Camera Club | (critique workflow) | `2026-09-05T01:34:22.622283Z` |
| `chess-club-dispute-live-write-2026-09-04.md` | Chess Club | (dispute workflow) | `2026-09-05T01:48:47.317964Z`, `2026-09-05T01:49:01.263438Z` |

Each doc's own verification section describes pulling a screenshot and confirming the rendered UI
state byte-identically. None of the three independently queried the backing database.

## Scope escalation: this affects far more than 3 rows, verified not guessed

The 3 rows above are the ones with a *directly confirmed timestamp-inside-outage* conflict. But
`~/Loom/.codex-logs/live-verification/` shows **16** live-verification dispatches ran across this
same stretch, Sept 3 evening through Sept 5 morning: `cedar-proof`, `bookclub`, `chessclub`,
`masjidnur`, `youthsoccer`, `gardenclub` (attempted 4 times — r1 through r4), `cameraclub`,
`adfree`, `exportmigration`, `platformsocial`, plus the 3 already named above. **Fact already
established in this document, just not yet connected**: the live database's `workflow_instances`
table holds exactly 3 rows total, all pre-existing Cedar `hoa-facility-reservation` rows from
2026-08-26. That means **none of the 16 dispatches' target communities have any corresponding
database row today** — not just the 3 whose timestamp I happened to check against the outage
window. Whether each specific dispatch ran while Postgres was reachable or not is a separate
question from whether its claimed write actually persists, and right now, none of them do.

I have not individually re-examined all 16 evidence docs' own verification methodology (whether
each checked the database or only the rendered UI) — that would be the natural next step if the
user wants a full accounting, and is called out again in the open questions below.

## What's actually true right now (verified directly, 2026-09-06)

**1. The entire cluster's `workflow_instances` table holds 3 rows, all from 2026-08-26, all Cedar
`hoa-facility-reservation`.** Queried directly as the `loom` superuser (bypasses RLS, sees everything):

    SELECT community_id, workflow_type, count(*) FROM workflow_instances GROUP BY community_id, workflow_type;
    -- community_cedar_commons_hoa | hoa-facility-reservation | 3

No `hoa-dues-payment`, no Camera Club community, no Chess Club community, anywhere in the table.
Nothing from any date after 2026-08-26 exists.

**2. Postgres was confirmed down across the entire window all three timestamps fall in.** From the
previous container instance's own log (not inferred, not a kubectl metadata guess):

    2026-09-05 04:54:29.977 UTC [29] LOG: database system was interrupted; last known up at 2026-09-04 03:27:48 UTC
    2026-09-05 04:55:06.469 UTC [29] LOG: database system was not properly shut down; automatic recovery in progress
    2026-09-05 04:55:07.239 UTC [1]  LOG: database system is ready to accept connections

So Postgres was unreachable from at or before **2026-09-04 03:27:48 UTC** until **2026-09-05
04:55:07 UTC** — roughly 25 hours. All three evidence docs' timestamps (01:15, 01:34, 01:48/01:49 on
2026-09-05) fall inside this window.

**3. `workflow-service` shows the identical restart signature at the identical moment** (`Last State:
Terminated, Exit Code 255, Started: Fri 04 Sep 2026 21:54:24 -0700` = `2026-09-05 04:54:24 UTC`,
5 seconds off from Postgres's own recovery-start log line).

**CORRECTION (same investigation, later pass): this is NOT a whole-node/VM event — checked and
ruled out, not assumed.** My first pass over this evidence guessed a VM reboot as the likely
cause, reasoning from CLAUDE.md's documented "k3s does not restart itself after a VM reboot"
behavior. That guess doesn't survive a check against the VM's own boot history:

    journalctl --list-boots
    -4 fff4484d... Mon 2026-08-24 08:54:35 PDT  Fri 2026-09-04 15:58:50 PDT
    -3 f6b851d3... Fri 2026-09-04 16:01:53 PDT  Sat 2026-09-05 17:04:37 PDT

Converted to UTC, boot **-4** runs continuously from 2026-08-24 15:54:35 UTC to **2026-09-04
22:58:50 UTC** — a single, unbroken VM session that fully contains the entire confirmed outage
window (2026-09-04 03:27:48 UTC to 2026-09-05 04:55:07 UTC). The VM did not reboot until roughly
**one hour after** Postgres had already recovered. `journalctl -u k3s` across the whole outage
window shows k3s's own process (same PID, `216548`) running continuously throughout, logging
ordinary API-server request-timeout noise (`FinishRequest: post-timeout activity`,
`context canceled`/`context deadline exceeded`) rather than any crash or restart — the k3s control
plane itself was healthy the entire time.

**So the real, narrower finding is: the `postgres-0` pod specifically was unreachable/unresponsive
for ~25 hours while the VM, k3s's control plane, and (per its own steady journal activity)
everything else around it stayed up.** That is arguably more concerning than a clean VM reboot,
not less — it means kubelet's own liveness/readiness handling did not detect and restart a
day-long-unresponsive pod on its own within that window, or detected it very late. The later VM
reboot at 22:58:50 UTC (boot -4 → -3) is a separate, subsequent event; Postgres's own clean
`shutting down ... administrator command` log line at `2026-09-06 00:04:24 UTC` lines up with the
*end* of boot -3 (`2026-09-06 00:04:37 UTC`), suggesting that later shutdown was a deliberate
action (plausibly this session's own VM-recovery work), unrelated to the original 25-hour gap this
document is about.

## What this does and doesn't prove

**Proves:** the three evidence docs' claimed server timestamps could not have been produced by a
write actually landing on *this* Postgres instance at that recorded moment, because it was not
running. And today, none of the three claimed instances exist in the database that instance now
serves.

**Does not prove, and I'm not asserting:**
- *That the writes never happened.* A clock-skew-at-reboot explanation (the timestamp being wrong
  while the write was genuine) is weaker than I first considered, now that the VM's own boot history
  rules out a reboot during the actual outage window — there's no boot-time clock-resync event
  sitting inside it to have caused skew. I have no direct evidence either confirming or ruling out
  some *other* clock-skew cause at that specific moment, but it's no longer the natural explanation
  it looked like on a first pass.
- *That this is the cause of the 3 surviving Aug-26 rows also going untouched.* Those rows predate the
  outage by over a week and were not examined for their own history beyond confirming they still exist.
- *Any single root cause.* This is presented as a timeline conflict with strong, directly-observed
  evidence on both sides (the docs' claims, Postgres's own recovery log, the current DB state) — not as
  a solved incident.

## Why this matters beyond these three rows

All three evidence docs were treated as genuine, closing evidence for their respective B25 addendum
rows — matching this effort's own stated production bar (a live walkthrough *and* a UX judge, per row).
Their verification sections describe checking the *rendered UI*, which would look identical whether the
write truly reached the server or not, if the app's error handling on a dead backend connection doesn't
surface distinctly (untested here). **The methodology gap, if there is one, generalizes**: any other
"closed via live write" row from the same working session, or any future one, is only as trustworthy as
whether its verification independently queried the database rather than trusting the UI plus a
self-reported timestamp.

## Open questions for the user, not decided here

1. Should the three affected B25 rows (Cedar dues, Camera Club critique, Chess Club dispute) be
   reopened pending a real re-verification (a fresh live write, checked against the DB this time), or
   is there a way to confirm the original writes landed that I haven't found?
2. Should every other "closed via live write" B25 row be retroactively spot-checked against the
   database, given this session's own repeated finding this cycle that status tags are not evidence?
3. **Narrowed, not answered:** the VM itself did not reboot during the outage (confirmed via
   `journalctl --list-boots`), and k3s's own control-plane process ran continuously throughout
   (same PID, no restart) — so this was specifically the `postgres-0` pod being unresponsive for
   ~25 hours while everything around it stayed healthy, not a whole-node event. Is there a known
   cause for a single pod going unresponsive that long without kubelet restarting it — a resource-
   starvation episode (matching this repo's own documented "a heavy build can starve the shared
   node" pattern), a storage/PVC stall, or something else? And separately: is this the same kind of
   event as the ~25-hour gap, or a different one entirely? **One concrete lead**: 2 Docker image
   builds (`loom-workflow-service:1.0.3`, `loom/app-access:0.3.9`) completed at 16:53 and 18:08 PDT
   on 2026-09-03, roughly 2-3.5 hours before the outage's earliest bound, and the outage window
   itself overlaps a stretch of 16 back-to-back live-verification dispatches (each driving a live
   Android emulator plus hitting the backend) — a plausible, not confirmed, resource-starvation
   correlation matching this repo's own documented "the build and the cluster share one machine"
   pattern, except the recovery this time took ~25 hours rather than resolving once load passed.
4. **New, broader than the original 3 rows**: given all 16 live-verification dispatches from this
   stretch correspond to zero rows in the live database today (see "Scope escalation" above), should
   *every one* of those 16 evidence docs be re-examined for whether its own verification actually
   queried the database, rather than assuming the 3 already flagged are the full extent?

## Decided, 2026-09-07 (user)

**Reopen and re-verify all 16, now.** Not just the 3 timestamp-confirmed rows, not deferred —
answers open questions 1, 2, and 4 above at once. Open question 3 (root cause of the ~25-hour
`postgres-0` unresponsiveness itself) remains genuinely open and is a separate, lower-priority
investigation from re-verifying the 16 claimed writes.

**What "re-verify" means, per this session's separately-decided seed-data policy** (see
`root-cause-seed-instances-never-reach-remote.md`): communities are expected to start empty against
the remote backend, so a valid re-verification must perform the real role-based action live (sign
in as the actual persona, actually create/submit/drive the workflow to its claimed terminal state
through the app) — not just check whether a pre-existing row happens to be present. **The proof
standard changes from "screenshot of the rendered UI" to "screenshot of the rendered UI AND a direct
database query for that exact instance"**, run in the same session, so the two can't drift apart the
way this incident's 3 original docs did.

**The 16 target communities/dispatches** (from `~/Loom/.codex-logs/live-verification/`): `cedar-proof`
(Cedar dues), `cameraclub` (critique), `chessclub` (dispute), `bookclub`, `masjidnur`,
`youthsoccer`, `gardenclub`, `adfree`, `exportmigration`, `platformsocial` — 10 named dispatches;
"16" counts `gardenclub`'s 4 attempts (r1–r4) separately, which are the same community and do not
each need a separate re-verification target — 10 distinct communities need a fresh live write, not 16
separate runs.

**Execution plan**, to run across subsequent autonomous-loop ticks (this is too large for one dispatch
and must respect "one dispatch at a time"):
1. Start with the 3 most-suspicious first (Cedar dues, Camera Club critique, Chess Club dispute) —
   already fully scoped with known target workflows/transitions from the table above.
2. Then the remaining 7 (Book Club, Masjid Nur, Youth Soccer, Garden Club, Ad-Free, Export
   Migration, Platform Social) — for each, identify a real workflow+transition to drive live from
   that community's own product doc, matching how the original dispatch's claim was framed if its
   evidence doc states one, or picking any real, board/admin-guarded transition if not.
3. Each re-verification dispatch: sign in as the real role via `data/call_live_verification_agent.sh`
   (Claude Opus, device-driven), drive the workflow to its terminal state, THEN independently query
   `workflow_instances` directly (not through the app) for that exact instance, citing both the
   screenshot and the query result in the same evidence doc.
4. Only flip a B25 row back to closed once BOTH proofs exist for it. Until re-verified, treat the
   row as **not** proven, regardless of what its current tracker status says — this document is the
   authoritative override for those 10 communities' live-write rows until each is individually
   re-closed with the new dual-proof standard.

None of the 10 have been re-verified yet as of this decision being recorded. This is the first
concrete next step for the autonomous loop's B25 work.

## Scope note

No file other than this one was created. No community `*.jsonc`, no tracker row, no code was
modified as part of this investigation. All port-forwards opened during the investigation
(postgres, workflow-service, keycloak) were closed; confirmed via `pgrep -af port-forward` returning
empty (only the check command itself, expected).
