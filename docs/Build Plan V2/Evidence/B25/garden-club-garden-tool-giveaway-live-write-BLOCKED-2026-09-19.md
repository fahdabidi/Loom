# B25 live walkthrough — Garden Club, `garden-tool-giveaway`

> **SUPERSEDED 2026-09-19 (UTC 2026-09-20).** The device was recovered and the row was proven
> live. See `garden-club-garden-tool-giveaway-live-write-2026-09-19.md`, which creates a fresh
> listing as `loom-garden-coordinator-1` and claims it as `loom-garden-member-1` into the terminal
> state `given`. This manifest is kept because its blocked-cause analysis and layer checks are
> accurate and were re-confirmed by that run.

**Workflow:** `garden-tool-giveaway`
**Community:** Garden Club (`community_garden_club`)
**Date:** 2026-09-19 (UTC 2026-09-20)
**Outcome:** **BLOCKED — this dispatch did not drive the device, so it proves nothing about the UI path.**

A complete `claim-giveaway` transition *is* stored in Postgres and is recorded below, but it was
written by a **previous** session ~10 minutes before this dispatch began. This dispatch could not
reach the emulator and therefore cannot certify how that row was produced. The row is recorded as
corroborating evidence, **not** as this dispatch's walkthrough.

## Why it was blocked

The VM rebooted at approximately **04:28Z** (`uptime` showed 5 minutes at 04:33Z). That reboot took
out both halves of the environment the ticket described as "already verified":

| Thing | Ticket said | Actual state at 04:33Z | Action |
|---|---|---|---|
| Backend, six pods `1/1` | up and serving | `k3s` **inactive**, nothing running | **recovered by me** — `sudo systemctl start k3s`, all six pods `1/1` at 04:37Z |
| `emulator-5554` over ssh reverse tunnel to `:5037` | reachable | **no tunnel; device unreachable** | **not recoverable from the VM** |

The tunnel is gone because the Windows-side ssh session that carried it died with the reboot. It
cannot be re-established from inside the VM, and this was measured rather than assumed:

- The only listener on `127.0.0.1:5037` is a **VM-local adb server** (pid 2743, started **21:29:35
  PDT**, parent pid 1) — started after the reboot and **before** my ssh session (21:31:22 PDT), so
  it is not mine. This is exactly the squatting-adb condition `CLAUDE.md` names as blocking the
  reverse forward; the forward never bound, and OpenSSH does not retry a failed remote forward.
- No `sshd`-owned forward exists. The single ssh connection (`192.168.56.1:53417`) is this
  dispatch's own shell.
- `adb devices` → empty. `adb devices -l` → empty.
- Windows host ports probed and **all closed**: `192.168.56.1` on 5037, 5554, 5555, 22, 2222.
  The host answers ping (0% loss), so this is port-level closure, not an unreachable host.
- Port 5037 probed across **every** reachable interface — `192.168.56.1`, `192.168.50.1`,
  `192.168.50.134`, and the cluster CNI neighbours — all closed.
- Windows runs no sshd, so an outbound `ssh -L` from the VM is not available either.

Per the standing rule, `adb kill-server` / `adb start-server` were **not** run.

**Recovery requires a host-side action:** re-establish `ssh -R 5037:localhost:5037` from Windows
after killing the squatting VM-local adb server. Nothing inside the VM can do this.

## Control read (taken before any write; no write was performed)

Query proven working by a control in the same session — a by-type count returned 10 populated rows,
so an empty giveaway result would have been a real negative rather than a broken query.

```
select instance_id, current_state, created_by_fan_id, created_at, updated_at
  from workflow_instances where workflow_type='garden-tool-giveaway';
```

Exactly **one** row, and it was already terminal before this dispatch started.

## The stored row — recorded with its provenance caveat

| Field | Value |
|---|---|
| `instance_id` | `community_garden_club_garden-tool-giveaway_zn48lnqz605l` |
| `community_id` | `community_garden_club` |
| `current_state` | **`given`** (terminal) |
| `created_by_fan_id` | `fan-garden-coordinator-1` |
| `created_at` | 1789877912479 → **2026-09-20 04:18:32Z** |
| `updated_at` | 1789878425573 → **2026-09-20 04:27:05Z** |
| `updated_at − created_at` | **513,094 ms** — a real transition, not a bare insert |

`instance_data` as stored:

```json
{"ownerFanId":"fan-garden-coordinator-1","mode":"giveaway","availabilityState":null,
 "conditionState":"good","coordinatorFanId":"fan-garden-coordinator-1",
 "title":"B25-Giveaway-Wheelbarrow",
 "itemDescription":"Steel-wheelbarrow-offered-free-to-a-club-member",
 "ownerContactInfo":"coordinator1-at-gardenclub-test",
 "claimantFanId":"fan-garden-member-1","pickupWindow":"Saturday-0900-to-1200",
 "claimantContactInfo":"member1-at-gardenclub-test",
 "claimedAt":"2026-09-20T04:27:05.446211Z"}
```

Every declared effect of `claim-giveaway` is present and internally consistent:

| Effect | Expected | Stored |
|---|---|---|
| `set availabilityState = null` | `null` | `null` ✓ |
| `set claimantFanId = $actor` | the claiming fan | `fan-garden-member-1` ✓ |
| `set pickupWindow = {input.pickupWindow}` | required input | `Saturday-0900-to-1200` ✓ |
| `set claimantContactInfo = {input.claimantContactInfo}` | required input | `member1-at-gardenclub-test` ✓ |
| `set claimedAt = $timestamp` | = `updated_at` | `04:27:05.446211Z` ✓ matches |

The guard is satisfied on its face: the actor `fan-garden-member-1` holds `garden-member`, the owner
was `fan-garden-coordinator-1`, so the anti-self-claim formula
`if(ownerFanId == $actor, false, true)` returns true.

### What this row does NOT establish

**I cannot certify the transition was driven through the app's UI**, and that distinction is the
entire point of a live walkthrough. Provenance was pursued and could not be settled:

- The prior run directory `.codex-logs/live-verification/garden-giveaway` (21:09 PDT) is a
  **0-byte** `output.log` — the Claude dispatchers buffer until completion, and the reboot killed
  that run before it flushed. It names the workflow but records nothing about method.
- `kubectl logs --previous` on `workflow-service` retains only **3 lines**, all
  `workflow_service_unexpected_error` for an unrelated Riverside Youth Soccer instance. The service
  does not log successful requests, so the garden transition was never logged at all.

The hyphenated field values are the documented signature of avoiding `adb shell input text` space
truncation, and real fan ids imply genuine OAuth tokens rather than the shell's role-id aliasing —
but that is circumstantial. Attributing it to a UI tap would be the mechanism claim `CLAUDE.md`
warns against making without a trace that establishes the mechanism.

## Layer checks completed — these are now clear for the next attempt

All read-only, all verified in this session on the recovered backend:

| Layer | Result |
|---|---|
| Definition published | **`garden-tool-giveaway` present** in `workflow_definitions`; all 8 garden types published (control) |
| Deployed guard vs shipped package | **identical** — `allowedRoleIds:["garden-member"]`, `instanceDataEquals availabilityState=available`, `formula if(ownerFanId == $actor, false, true)`, `to: given`, inputs `pickupWindow` + `claimantContactInfo` both required |
| Credential `loom-garden-member-1` | HTTP 200, `fanId=fan-garden-member-1` ✓ |
| Credential `loom-garden-coordinator-1` | HTTP 200, `fanId=fan-garden-coordinator-1` ✓ |

Package identity: `skillVersion 3.6.0`, `specVersion 4`,
`sha256 e82a8b39015268dba34e2782bb81613e247fa7c7f7e94e402a80309c5b439d97`.

## Finding — the ticket's premise about the seeds does not hold on the remote path

The ticket states `terracotta-pots-giveaway` is member-owned and "correctly refuses self-claim".
That is true only under the **local/demo** identity aliasing. Both shipped seeds carry **role ids**
in a fan-id field — `ownerFanId: "garden-member"` and `ownerFanId: "garden-coordinator"` — while a
remote actor is `fan-garden-member-1`. The formula compares `ownerFanId == $actor`, so on the remote
path `"garden-member" != "fan-garden-member-1"` and the self-claim guard **would not refuse**.

This is moot in practice — package seeds reach only the local engine, and the live community
contains no seeded giveaway rows — but the stated reason for preferring one seed over the other does
not survive the move to the remote path.

## Where I stopped, and why

Stopped at device access. The workflow could not be advanced by this dispatch because no emulator is
reachable from this VM and the bridge is host-side only. No credential was created or reset, no
instance was created, and no transition was fired by me — a direct API write was deliberately not
performed, because it would prove the service boundary rather than the UI path and would pollute the
state a real walkthrough needs.

The next attempt needs only the tunnel restored. Because the single existing instance is terminal
(`given`), it must create a fresh listing as `loom-garden-coordinator-1` and then claim it as
`loom-garden-member-1`.
