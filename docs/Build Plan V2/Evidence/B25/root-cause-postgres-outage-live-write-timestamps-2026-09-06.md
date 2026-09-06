# Root cause: three B25 "live-write" closures recorded server timestamps during a confirmed Postgres outage

**Date found:** 2026-09-06, during a routine autonomous tracker sweep (unrelated task — the Cedar
document-content upload ticket led here by accident, while minting a real fan JWT to test the
document-upload API and finding the target instance didn't exist in the live database).

**Status: reported to the user, holding for direction. No tracker row closed, reopened, or edited as
part of this finding — this document is evidence only.**

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
   event as the ~25-hour gap, or a different one entirely?

## Scope note

No file other than this one was created. No community `*.jsonc`, no tracker row, no code was
modified as part of this investigation. All port-forwards opened during the investigation
(postgres, workflow-service, keycloak) were closed; confirmed via `pgrep -af port-forward` returning
empty (only the check command itself, expected).
