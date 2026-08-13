# Migrating the dispatch pipeline from WSL Ubuntu to a VirtualBox Ubuntu VM

This guide moves the Loom agent tooling (`docs/Build Plan V2/Tools/`) off WSL2 and onto a
VirtualBox Ubuntu 24.04 VM. It is written against the VM that was actually built and validated for
this purpose — VirtualBox VM name **`ubuntu-24.04.4-loom`**, guest hostname `fahd-VirtualBox`,
user `fahd`.

> **There are two Ubuntu VMs on this host.** `ubuntu-24.04.4-loom` is Loom's.
> `Ubuntu-24.04.4` belongs to an unrelated project — **never touch it**. They are easy to confuse
> (near-identical names, both Ubuntu 24.04, both bridged); a VM operation aimed at the wrong one has
> already happened once. Distinguish by MAC: Loom's is `08:00:27:3F:05:F1`. `loom-vm.ps1` (§8) is
> hard-locked to the correct VM name for exactly this reason — prefer it over raw `VBoxManage`.

**Addressing:** the VM has two NICs — a bridged NIC for internet/LAN (DHCP, currently
`192.168.50.86`) and a host-only NIC with the **static** address **`192.168.56.10`**, which is what
`ssh loom-vm` targets. The static address is deliberate: it does not depend on your router's DHCP,
so it survives lease changes, router reboots, and the LAN being down entirely. See §7.

**Read this first — the migration is not a port, it is a deletion.** Roughly half the tooling in
`code/` exists solely to work around WSL2 and OneDrive pathologies that do not exist in a VM. The
correct migration for those scripts is to **stop using them**, not to translate them. §4 is the
important section; §5–§6 are mechanical.

---

## 1. What changes, architecturally

| Concern | WSL2 (old) | VirtualBox VM (new) |
|---|---|---|
| Repo location | `/mnt/c/Users/fahd_/OneDrive/.../Loom` — Windows NTFS + OneDrive, seen through v9fs | `~/Loom` — native ext4 inside the guest |
| Git binary | `git.exe` via a shim, forced by the OneDrive corruption bug | the guest's own `/usr/bin/git`, no shim |
| How the orchestrator reaches the agent | `wsl.exe -e bash -lc '...'` from the Windows host | `ssh loom-vm '...'` |
| Session cost | Each `wsl.exe` call consumes ~9 vsock connections against a hard, non-tunable cap | An SSH channel; `MaxSessions` defaults to 10 and *is* tunable |
| Process cleanup | Manual PID-set diffing + kill + re-verify (WSL2 leaked sessions for 5+ hours) | `sshd` reaps its own children on channel close |
| Android emulator | Ran on the Windows host | Inside the guest — **needs the Hyper-V decision in §9** |

The single most important consequence: **the repo no longer lives on OneDrive, and no longer
crosses a filesystem translation layer.** Every guard built for that combination becomes dead code.

---

## 2. Prerequisites — already done on this VM

These were completed while building the VM. Listed so you can verify, not repeat.

```bash
ssh loom-vm '. ~/.loom-env.sh && flutter --version && melos --version && codex --version && claude --version && gh auth status'
```

Expected: Flutter 3.41.7 (revision `cc0734ac71`, matching `app/apps/loom_demo/.metadata`),
melos 7.8.1, Codex CLI, Claude Code CLI, and `gh` logged in as `fahdabidi`.

Also in place:
- **SSH key access** — `~/.ssh/loom_vm_ed25519` on the Windows host, aliased as `loom-vm`
  (→ `192.168.56.10`, host-only static) and `loom-vm-lan` (→ the bridged DHCP address) in
  `~/.ssh/config`. No password needed.
- **Passwordless sudo** — `/etc/sudoers.d/fahd-nopasswd`.
- **`~/.loom-env.sh`** — see §3, this is load-bearing for every script.
- **Android SDK** — build-tools 34/35/36, platforms 34/35/36, NDK 28.2.13676358, an
  `android-36 google_apis x86_64` system image, and a `loom_demo` AVD.
- **`~/Loom`** — cloned from `github.com/fahdabidi/Loom`, `melos bootstrap` verified (39 packages).

---

## 3. The `~/.loom-env.sh` rule (read before writing any script)

Ubuntu's stock `~/.bashrc` begins with:

```bash
case $- in
    *i*) ;;
      *) return;;
esac
```

That returns immediately for **non-interactive** shells — which is exactly what
`ssh loom-vm 'some command'` creates. Any PATH export appended to `.bashrc` is therefore invisible
to every automated dispatch, while working perfectly when you SSH in and type by hand. This is a
classic silent-failure trap: it works when you test it interactively and fails in automation.

The fix already applied: all environment setup lives in **`~/.loom-env.sh`**, sourced explicitly.

```bash
# WRONG -- melos/flutter/codex will not be found
ssh loom-vm 'cd ~/Loom/app && melos bootstrap'

# RIGHT
ssh loom-vm '. ~/.loom-env.sh && cd ~/Loom/app && melos bootstrap'
```

Every migrated script in §5 begins with `. "$HOME/.loom-env.sh"`. Do not omit it, and do not
substitute `bash -l` (a login shell reads `.profile`, whose PATH additions are ordered differently
and do not include the Android SDK).

---

## 4. Scripts to delete, not port

Five of the eight scripts in `code/` are WSL2 artifacts. Deleting them is the point of the
migration — carrying them across would preserve cost while discarding the benefit.

### 4.1 `wsl_dispatch_tracker.sh` — **delete**

Its entire job was diffing the `wsl.exe`/`wslhost.exe` process set before and after a dispatch,
killing survivors, and re-verifying the kill, because WSL2's idle-timeout teardown left orphans
alive for 5+ hours. `sshd` has no equivalent failure: when the SSH channel closes, the remote
command's process group is reaped by the server.

Verify the claim yourself rather than trusting it — run a dispatch, then:

```bash
ssh loom-vm 'pgrep -af "codex|node" | grep -v pgrep'
```

An empty result after a completed dispatch means there is nothing for a tracker to track. (If you
ever *do* background something with `setsid nohup` inside the guest, that survives deliberately —
use `pkill -f <pattern>` directly; you do not need a 160-line tracker for it.)

Consequence: `handoff_gate.sh` check #2 must go too (§5.3).

### 4.2 `wsl_slot.sh` — **delete**

This capped ad-hoc `wsl.exe` invocations at 2 concurrent because WSL2 enforces a hard,
**non-tunable** vsock connection cap (confirmed by WSL maintainers — no `.wslconfig` key reaches
it), and this workflow's usage pattern exhausted it.

SSH's equivalent limit is `MaxSessions` (default 10 multiplexed sessions per connection) and
`MaxStartups` (default `10:30:100`) — both configurable in `/etc/ssh/sshd_config`. You are unlikely
to approach either, but if you ever run heavily parallel dispatches:

```bash
ssh loom-vm 'sudo sed -i "s/^#*MaxSessions.*/MaxSessions 40/" /etc/ssh/sshd_config && sudo systemctl reload ssh'
```

Better: enable connection multiplexing on the **Windows** side so repeated `ssh loom-vm` calls
reuse one TCP connection instead of paying a fresh handshake each time. Add to `~/.ssh/config`:

```
Host loom-vm
    HostName 192.168.56.10          # host-only static -- see §7
    User fahd
    IdentityFile ~/.ssh/loom_vm_ed25519
    StrictHostKeyChecking accept-new
    ControlMaster auto
    ControlPath ~/.ssh/cm-%r@%h:%p
    ControlPersist 10m
    ServerAliveInterval 30
```

`ControlPath` on Windows OpenSSH works but is finicky with some builds; if you see
`ControlPath too long` or multiplexing errors, drop the three `Control*` lines — you lose only
speed, not correctness.

### 4.3 The `git.exe` shim (`~/.codex-git-shim/`) — **delete**

Root cause was specific: `.git` under OneDrive's Files-On-Demand cloud-filter driver, *accessed
through v9fs* (`/mnt/c`), broke git's atomic index-rename guarantee, producing
`fatal: .git/index: index file smaller than expected` mid-dispatch. Native `git.exe` on NTFS removed
the v9fs half.

In the VM, `~/Loom` is native ext4 with no cloud-sync driver and no translation layer. Use the
guest's own git. Every `git.exe` reference in `call_implementation_agent.sh` becomes plain `git`
(§5.1).

**Do not** put the repo on a VirtualBox shared folder pointing back at the OneDrive path — that
recreates the exact pathology in a new form (vboxsf instead of v9fs, same cloud filter underneath).
Keep the working copy inside the guest and use `git` + GitHub to move code, as §6 describes.

### 4.4 `GIT_SAFETY_PREAMBLE` — **delete**

This ~20-line block was prepended to every dispatch prompt, instructing the agent how to survive
transient OneDrive `index.lock` errors without improvising destructive recovery. The underlying
error cannot occur on ext4 without a sync engine. Removing it also reclaims prompt budget on every
single dispatch.

Keep only the final sanity instruction, folded into your ticket template if you want belt-and-braces:
*"Before your final commit, confirm `git ls-files | wc -l` is in the thousands, not a handful."*

### 4.5 The vsock-exhaustion detector — **delete**

The `grep -qE "UtilBindVsockAnyPort|UtilAcceptVsock|accept4 failed"` block, the
`DISPATCH_HIT_VSOCK=1` banner, and the `wsl.exe --shutdown` mitigation advice all target
[openai/codex#8322](https://github.com/openai/codex/issues/8322) ×
[microsoft/WSL#40650](https://github.com/microsoft/WSL/issues/40650). Neither applies to a VM.

`watch_dispatch_log.sh` also loses its vsock-alert branch, leaving it a handful of lines (§5.2).

### 4.6 What survives

| Script | Status | Why |
|---|---|---|
| `call_implementation_agent.sh` | **port** (§5.1) | Core dispatch. Strip WSL/OneDrive guards, keep model profiles + TODO hooks + integrity guard. |
| `call_root_cause_agent.sh` | **port** | Same edits as above; role preamble and stricter HEAD check unchanged. |
| `call_skill_authoring_agent.sh` | **port, nearly unchanged** | Its isolation (`-C` scratch dir, `--skip-git-repo-check`, `--ephemeral`, live `github.fetch_file`) is deliberate and platform-independent. Only the nvm PATH resolution changes. |
| `watch_dispatch_log.sh` | **port, simplified** (§5.2) | Still needed — a completion watcher is not a WSL concept. |
| `handoff_gate.sh` | **port, 5 checks → 4** (§5.3) | Drop the WSL-cleanup check; keep the rest. |
| `verify_apk_freshness.sh` | **port verbatim** | Gradle staleness was *worsened* by drvfs mtime unreliability but is not caused by it. Cheap insurance; keep it. |

---

## 5. The ported scripts

Place these at `~/Loom/data/` inside the guest (one level below repo root — the scripts compute
`REPO_ROOT` as `$(dirname "$0")/..`).

```bash
ssh loom-vm 'mkdir -p ~/Loom/data'
```

### 5.1 `call_implementation_agent.sh`

Diff from the WSL version, in full:

1. Delete the `GIT_SAFETY_PREAMBLE` variable and change `PROMPT="$GIT_SAFETY_PREAMBLE$(cat ...)"` to
   `PROMPT="$(cat "$PROMPT_FILE")"`.
2. Delete the `~/.codex-git-shim` PATH block.
3. Replace all four `git.exe` calls with `git`.
4. Delete the vsock detector block and its `CODEX_OUTPUT_CAPTURE` plumbing (the `tee` capture exists
   only to feed that grep — but see the note below before removing `tee` itself).
5. Replace the nvm-resolution block with `. "$HOME/.loom-env.sh"`.
6. Keep unchanged: profile/sandbox env overrides, the DeepSeek gateway preflight (see note), the
   `.last_dispatch.pid` write, `--add-dir` grants, the pre/post tracked-file integrity guard, the
   TODO-tracking hooks and completion banner.

> **On the `tee` capture:** you can keep it. It costs nothing and preserves a side copy of the
> transcript for post-mortems. Only the *grep for vsock patterns* is obsolete.

> **On the DeepSeek gateway:** the profile preflight (`GATEWAY_HEALTH_URL`, default
> `http://172.31.16.1:8787/health`) only fires for `deepseek_*` profiles, which are not the current
> default. That IP was WSL's default-route address — meaningless from the VM. If you ever revive
> that path, the gateway runs on the Windows host and the VM is bridged, so the correct URL becomes
> the host's LAN IP (`http://192.168.50.x:8787/health`), plus a Windows Firewall rule allowing 8787
> from the LAN rather than just from WSL. Leave the block in place; it is inert until used.

Resulting invocation shape (from the Windows host):

```bash
ssh loom-vm '. ~/.loom-env.sh && cd ~/Loom && \
  DISPATCH_TRACKER_FILE="docs/Build Plan V2/<Tracker>.md" \
  DISPATCH_TODO_ITEM="<§8 row title>" \
  setsid nohup bash data/call_implementation_agent.sh data/v3_ticket_<slug>.md --fresh \
  < /dev/null > .codex-logs/<label>_dispatch.out.log 2>&1 & disown'
```

### 5.2 `watch_dispatch_log.sh`

Drop the vsock-alert branch; keep the self-terminating structure (which exists because
`tail -F | grep` never exits on its own — still true over SSH, and now it holds an SSH channel open
instead of a WSL session).

```bash
#!/bin/bash
# data/watch_dispatch_log.sh <label> [post-completion-sleep-seconds]
set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
LABEL="${1:?usage: watch_dispatch_log.sh <label> [post-completion-sleep-seconds]}"
POST_SLEEP="${2:-5}"
LOG="$REPO_ROOT/.codex-logs/${LABEL}_dispatch.out.log"
[ -f "$LOG" ] || { echo "watch_dispatch_log.sh: log not found: $LOG" >&2; exit 1; }

exec 3< <(tail -F "$LOG")
TAILPID=$!
trap 'kill "$TAILPID" >/dev/null 2>&1' EXIT

while IFS= read -r line <&3; do
  if [[ "$line" =~ ^codex\ exec\ exited\ with\ status ]]; then
    echo "$line"
    sleep "$POST_SLEEP"
    break
  fi
done
exit 0
```

Invoke as a `Monitor` command:

```bash
ssh loom-vm '. ~/.loom-env.sh && cd ~/Loom && bash data/watch_dispatch_log.sh <label>'
```

An alternative that needs no watcher script at all, since the dispatch writes its own PID:

```bash
ssh loom-vm 'cd ~/Loom && while kill -0 "$(cat .codex-logs/.last_dispatch.pid)" 2>/dev/null; do sleep 5; done; echo DISPATCH_COMPLETE'
```

### 5.3 `handoff_gate.sh`

Delete **check #2** (the `wsl_dispatch_tracker.sh` log lookup) entirely, along with the `LABEL`
plumbing it needed. The remaining four checks are all still meaningful:

1. Most recent dispatch process has exited (`.last_dispatch.pid` + `kill -0`).
2. ~~WSL session cleanup confirmed~~ — **removed**.
3. `git status --short` is empty. **Keep — this is the check that mattered most.** It was built
   after CALR.4g round 5 burned three redundant dispatch rounds re-fixing an already-fixed file that
   sat untracked (`??`), invisible to `git diff`. That failure mode is a git property, not a WSL
   one, and survives the migration completely intact.
4. `git ls-files | wc -l` ≥ 100. Keep — cheap, and now guards against ordinary accidents rather than
   OneDrive corruption.
5. `git rev-parse HEAD` resolves. Keep.

Renumber and update the header comment so the next reader is not hunting for a check that no longer
exists.

### 5.4 One-time Codex config inside the guest

`trust_level` must be set for the **new** path — the old `/mnt/c/...` entry is meaningless here.

```bash
ssh loom-vm 'mkdir -p ~/.codex && cat >> ~/.codex/config.toml << "EOF"

[projects."/home/fahd/Loom"]
trust_level = "trusted"
EOF'
```

Recreate the model profiles (these live outside the repo and did not come across with the clone):

```bash
ssh loom-vm 'cat > ~/.codex/gpt5_3_spark_xhigh.config.toml << "EOF"
model = "gpt-5.3-codex-spark"
model_reasoning_effort = "xhigh"
model_verbosity = "medium"
model_context_window = 272000
EOF
cat > ~/.codex/gpt5_6_sol_xhigh.config.toml << "EOF"
model = "gpt-5.6-sol"
model_reasoning_effort = "xhigh"
model_verbosity = "medium"
model_context_window = 272000
EOF'
```

Smoke-test before trusting either on a real ticket — and remember the standing lesson from the
model history: **a profile that passes a one-line smoke test can still fail a ticket-length prompt**
(DeepSeek V4 Pro @ `high` did exactly that). Test both.

```bash
ssh loom-vm '. ~/.loom-env.sh && codex exec -p gpt5_3_spark_xhigh --sandbox read-only "Reply with exactly: PROFILE_OK"'
```

**This smoke test alone is not sufficient** — see §5.5 immediately below. `--sandbox read-only`
happens to skip the exact codepath that broke on this VM; only a `--sandbox workspace-write` call
(what every real dispatch actually uses) exercises it.

### 5.5 Required fix: AppArmor blocks bubblewrap's sandbox network namespace

Found 2026-08-12 while running the first real end-to-end dispatch through the migrated pipeline — a
`--sandbox read-only` smoke test passes cleanly, but every `--sandbox workspace-write` call (i.e.
every real Implementation/Root Cause Agent dispatch) fails immediately with:

```
bwrap: loopback: Failed RTM_NEWADDR: Operation not permitted
```

**Root cause:** Ubuntu 24.04 ("noble") ships `kernel.apparmor_restrict_unprivileged_userns=1` by
default (the same hardening that broke Chrome/Electron/Flatpak sandboxing for many people on
23.10+). Codex's sandbox (bubblewrap) needs an unprivileged user namespace to set up its own
loopback interface; with the restriction on and no AppArmor profile permitting it, the kernel
refuses. `bwrap --unshare-net --dev-bind / / echo hello` reproduces this directly, with no Codex
involved — confirms this is a VM/kernel-policy issue, not a Codex or dispatch-script bug.

**Fix applied (targeted, not a blanket sysctl disable):** install a local AppArmor profile that
grants `userns` specifically to `/usr/bin/bwrap`, leaving the restriction in place for every other
process on the VM.

```bash
ssh loom-vm 'sudo tee /etc/apparmor.d/bwrap > /dev/null << "EOF"
abi <abi/4.0>,
include <tunables/global>

profile bwrap /usr/bin/bwrap flags=(unconfined) {
  userns,

  # Site-specific additions and overrides. See local/README for details.
  include if exists <local/bwrap>
}
EOF
sudo apparmor_parser -r /etc/apparmor.d/bwrap'
```

This is a one-time fix per VM (survives reboots — it's a normal AppArmor profile file under
`/etc/apparmor.d/`, loaded automatically by the `apparmor` service at boot; no need to re-run
`apparmor_parser` after a restart). Verify it took with `sudo aa-status | grep bwrap` (should list
`bwrap`) and by re-running the direct `bwrap --unshare-net ...` repro above (should print `hello`,
not the RTM_NEWADDR error).

A broader alternative — `sudo sysctl -w kernel.apparmor_restrict_unprivileged_userns=0`, persisted
via `/etc/sysctl.d/` — was considered and explicitly rejected: it disables the restriction for every
unprivileged process on the VM, not just bwrap, which is a materially larger security-posture change
for no extra benefit here.

---

## 6. Moving the repo and its untracked state

`~/Loom` is already cloned and bootstrapped. What is *not* there is everything gitignored — which
for this workflow is most of the operational state.

`data/` is gitignored in this repo (`.gitignore:1`), so the scripts, tickets, and logs never left
the old machine via git. Copy what you want to keep directly:

```bash
# From the Windows host. Tickets are worth keeping; dispatch logs usually are not.
scp -i ~/.ssh/loom_vm_ed25519 \
  "/c/Users/fahd_/OneDrive/Documents/Pi Project/Loom/data/v3_ticket_"*.md \
  loom-vm:~/Loom/data/
```

Deliberately **not** copied:
- `.codex-logs/` — every `.pids` file in it refers to Windows PIDs that mean nothing in the guest,
  and the tracker log describes a mechanism that no longer exists. Start clean.
- `~/.codex-git-shim/` — deleted by design (§4.3).
- `~/.deepseek_gateway_key` — only if you revive that path (§5.1 note).

Verify the clone is current and the toolchain works end to end:

```bash
ssh loom-vm '. ~/.loom-env.sh && cd ~/Loom && git fetch && git status -sb && cd app && melos bootstrap && melos run analyze'
```

**Push discipline matters more now than it did under WSL.** `call_skill_authoring_agent.sh` refuses
to dispatch unless local `HEAD` matches `origin/main`, because that channel fetches
`docs/references/**` live from GitHub rather than from disk. With the working copy now inside a VM
and no OneDrive sync papering over anything, "I forgot to push" becomes the default failure. The
preflight already catches it — do not reflexively set `ALLOW_STALE_PUSH=1`.

---

## 7. Networking: why the VM used to come up with no IP, and what fixes it

**Symptom:** after a reboot the VM had no IPv4 address at all and was unreachable over SSH, while
the console showed `enp0s3` `UP,LOWER_UP` with working IPv6.

**Root cause**, from `journalctl -u NetworkManager`:

```
dhcp4 (enp0s3): activation: beginning transaction (timeout in 45 seconds)
dhcp4 (enp0s3): state changed no lease
```

The VirtualBox bridged adapter's link is not yet forwarding when NetworkManager sends its first
DHCP DISCOVER at boot. The transaction times out, NetworkManager **gives up rather than retrying**,
and the VM sits with no IPv4 address indefinitely. It is not a router or DHCP-pool problem — a
manual `nmcli con up netplan-enp0s3` acquires a lease in under a second, every time.

Three independent layers now prevent this, deliberately overlapping:

**1. A static host-only address (the important one).** A second NIC on VirtualBox's host-only
network carries a static `192.168.56.10`, configured with `ipv4.never-default yes` so it can never
hijack the default route away from the bridged NIC. `ssh loom-vm` targets this address, so host↔VM
access no longer depends on your LAN, your router, or DHCP at all.

```bash
ssh loom-vm 'ip -4 -br addr; ip route show default'
# enp0s3  UP  192.168.50.86/24     <- bridged, DHCP, carries the default route
# enp0s8  UP  192.168.56.10/24     <- host-only, static, management only
# default via 192.168.50.1 dev enp0s3
```

**2. NetworkManager retries instead of giving up** — `/etc/NetworkManager/conf.d/99-loom-dhcp.conf`:

```ini
[connection]
ipv4.dhcp-timeout=90
connection.autoconnect-retries=0
```

`autoconnect-retries=0` means infinite retries. The per-attempt timeout is deliberately **bounded**
rather than `infinity`: `NetworkManager-wait-online.service` is enabled, and an unbounded DHCP
transaction gives it something it can never finish waiting for.

**3. A watchdog, as the backstop.** `/usr/local/sbin/loom-net-watchdog`, run by
`loom-net-watchdog.timer` at boot+30s and every 30s thereafter, activates any ethernet interface
that has been without an IPv4 address for a **grace period**.

> **The grace period is the whole design, and it was learned the hard way.** The first version of
> this watchdog called `nmcli con up` the moment it saw a missing address. That *cancels* any
> in-flight DHCP transaction — visible in the log as `disconnecting for new activation request`
> then `canceled DHCP transaction` — and restarts the clock. DHCP plus Address Conflict Detection
> needs only ~1–2 seconds here, but the interface sits in `connecting` for a while first, so a 60s
> watchdog interrupted it *every single time* and the interface never got an address at all. The
> watchdog caused a worse outage than the bug it was written for, and the host-only NIC masked it:
> SSH worked fine while the VM had no route to the internet. Always give NetworkManager first
> refusal.

Grace is per-method, because the two cases are not alike:

| `ipv4.method` | Grace | Rationale |
|---|---|---|
| `auto` (DHCP) | 5 checks ≈ 150s | Must outlast NetworkManager's own `ipv4.dhcp-timeout` (90s) |
| `manual` (static) | 2 checks ≈ 60s | Nothing to wait for — a static address absent after a minute is not coming |

That distinction is not academic: with a single 150s grace for both, boot-to-SSH was 206s; splitting
it cut that to **53s**, because the host-only NIC no longer waits out a DHCP timeout it never had.

Both paths are exercised in practice. A healthy boot, where the watchdog correctly stands down:

```
loom-net-watchdog: enp0s3 no IPv4 (check 1/5, method=auto,
                   state='connecting (checking IP connectivity)') -- letting NetworkManager finish
```

And a boot where NetworkManager genuinely failed and the watchdog earned its place:

```
loom-net-watchdog: enp0s3 still no IPv4 after 5 checks (method=auto,
                   state='connecting (getting IP configuration)') -- activating 'netplan-enp0s3'
```

Verify all of it the only way that counts — reboot and don't touch anything:

```powershell
.\loom-vm.ps1 restart
.\loom-vm.ps1 wait-ready 300      # -> "SSH ready at 192.168.56.10", ~53s
```

**Do not stop at "SSH ready".** That only proves the host-only NIC is up. The bridged NIC — and
therefore all internet access, `git fetch`, `pub get`, and every dispatch — is a separate question:

```bash
ssh loom-vm 'ip -4 -br addr; ip route show default; curl -sS -o /dev/null -w "%{http_code}\n" https://github.com'
```

Expect an address on both interfaces, a default route via `enp0s3`, and `200`.

---

## 8. Driving the VM from the host (`loom-vm.ps1`)

`code/loom-vm.ps1` is host-side control for the VM: power state, configuration, console
screenshots, and command execution **inside** the guest — none of which need SSH or a working
guest network. This is what you use when the VM is off, mid-boot-hang, or has no IP.

It is hard-locked to the VM named `ubuntu-24.04.4-loom` so it cannot act on the unrelated VM.

### One-time setup

In-guest execution needs the guest login. Store it once, DPAPI-encrypted and tied to your Windows
account, so it never appears in a transcript, a script, or a command line:

```powershell
Get-Credential -UserName fahd -Message "Loom VM guest login" |
  Export-Clixml "$env:USERPROFILE\.loom-vm-cred.xml"
```

The script passes it to VBoxManage via `--passwordfile` (a temp file it deletes afterwards), never
`--password`, which would expose it in the host's process list.

### Commands

| Command | Needs SSH? | Needs creds? | Purpose |
|---|---|---|---|
| `status` | no | no | State, all guest IPs, Guest Additions version, SSH reachability |
| `start` / `start-headless` | no | no | Boot the VM |
| `stop` | no | no | Graceful ACPI shutdown, waits for poweroff |
| `poweroff` | no | no | Hard power cut — only after `stop` has failed |
| `restart` | no | no | Graceful stop, falling back to force, then start |
| `screenshot [path]` | no | no | **PNG of the console — how you diagnose a boot hang** |
| `run "<cmd>"` | no | yes | Run a shell command in the guest via Guest Additions |
| `net-restart` | no | yes | Bounce NetworkManager |
| `fix-network` | no | yes | Re-assert the host-only static IP and renew bridged DHCP |
| `wait-ready [sec]` | — | no | Poll until SSH answers |
| `config-get [regex]` | no | no | Read VM settings |
| `config-set --opt val` | no | no | Change VM settings (requires powered off) |
| `snapshot-take/list/restore` | no | no | Snapshots |
| `ssh-config` | no | no | Print the `~/.ssh/config` block |

### Worked example — the VM is unreachable

```powershell
.\loom-vm.ps1 status          # running? does it have an IP at all?
.\loom-vm.ps1 screenshot      # then read the PNG -- boot hang? login screen? kernel panic?
.\loom-vm.ps1 run "ip -4 -br addr; systemctl is-active ssh"
.\loom-vm.ps1 fix-network     # re-assert addressing
.\loom-vm.ps1 wait-ready 180
```

If `run` fails with *"The specified user was not able to logon on guest"*, the guest is usually
still booting — Guest Additions answers before PAM can authenticate. Screenshot instead; it works
at every stage of boot, including the GRUB menu and a kernel panic.

To see boot messages when the Ubuntu splash is hiding them, inject an ESC keypress (no credentials
needed):

```powershell
& "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe" `
  controlvm "ubuntu-24.04.4-loom" keyboardputscancode 01 81
```

### Known quirk this script works around

VirtualBox reports `VMState=poweroff` a moment **before** it releases the machine's session lock, so
a `modifyvm`/`startvm` issued immediately after a shutdown fails with *"already locked for a
session"*. No lock field is exposed in `showvminfo --machinereadable` to poll, so the script retries
those operations with backoff. If you drive `VBoxManage` directly, expect this and retry.

### If the guest hangs at boot with RCU stalls

Observed once during this migration — the console showed:

```
rcu: INFO: rcu_preempt detected expedited stalls on CPUs/tasks: { 3-...D } 444555 jiffies
NMI backtrace for cpu 3 ... Comm: swapper/3
[FAILED] polkit.service / accounts-daemon.service / systemd-logind.service
```

A kernel RCU stall on an idle vCPU, cascading into core service failures and a boot that never
completed. The host was not under load (38 GB free, 1% CPU), and a clean power-cycle booted
normally in 52 seconds — so treat it as transient:

```powershell
.\loom-vm.ps1 poweroff
.\loom-vm.ps1 start-headless
.\loom-vm.ps1 wait-ready 300
```

If it becomes repeatable rather than one-off, reduce the VM's vCPU count (currently 8) before
investigating further — VirtualBox RCU stalls commonly track vCPU over-allocation.

---

## 9. Hyper-V, WSL2, and emulator acceleration

**This is the one genuinely unresolved item, and it is deferred by decision, not oversight.**

### 9.1 The conflict

Windows can only have one thing owning the CPU's virtualization extensions at a time. WSL2 requires
the Hyper-V hypervisor. When that hypervisor is running, VirtualBox is demoted to running *on top of*
it (via the Windows Hypervisor Platform API), and in that mode it cannot reliably expose nested
AMD-V/SVM to its own guests.

Measured on `ubuntu-24.04.4-loom` with `nested-hw-virt=on` (verified set on **this** VM) and CPU
profile `host`:

```bash
$ ssh loom-vm 'grep -oE "svm|vmx" /proc/cpuinfo | sort -u'   # -> empty
$ ssh loom-vm 'ls -l /dev/kvm'                               # -> No such file or directory
$ ssh loom-vm 'sudo /usr/sbin/kvm-ok'
INFO: Your CPU does not support KVM extensions
KVM acceleration can NOT be used
```

Host side, confirming a hypervisor owns the virtualization extensions:

```powershell
PS> (Get-CimInstance Win32_ComputerSystem).HypervisorPresent
True
PS> Get-Service vmcompute,hvhost | Select Name,Status
vmcompute Running ; hvhost Running
```

The guest sees no virtualization flags at all, on an AMD Ryzen 9 7900X that certainly has them. The
practical cost is that the Android emulator inside the VM falls back to pure software rendering,
slow enough to make emulator-based integration testing impractical.

> **Correction, recorded deliberately.** An earlier revision of this section drew the same
> conclusion from an *invalid* test: `nested-hw-virt` had been enabled on the wrong VM
> (`Ubuntu-24.04.4`, the unrelated one), so the Loom VM was tested with nested virt still `off` —
> which proves nothing. The setting has since been applied to `ubuntu-24.04.4-loom` and the test
> re-run; the numbers above are from that valid run, and they reach the same conclusion. Kept as a
> reminder to check *which* VM a `VBoxManage` command actually targeted before trusting its result.

### 9.2 Current decision: leave Hyper-V enabled, test on a physical device

Until WSL is fully retired, the host keeps Hyper-V and the emulator stays unaccelerated. For
integration tests, use a real Android device over VirtualBox USB passthrough:

1. Plug the phone into the Windows host.
2. In the VirtualBox window: **Devices → USB →** select the phone. (Requires the Extension Pack.)
3. Confirm inside the guest:
   ```bash
   ssh loom-vm '. ~/.loom-env.sh && adb devices'
   ```
   If it shows `unauthorized`, accept the USB-debugging prompt on the phone. If it does not appear
   at all, check the udev rules installed during provisioning
   (`/etc/udev/rules.d/51-android.rules`) and confirm your device's vendor ID is listed — add it and
   `sudo udevadm control --reload-rules` if not.
4. Point the test suite at it:
   ```bash
   ssh loom-vm '. ~/.loom-env.sh && cd ~/Loom/app && LOOM_EMULATOR=<device-serial> melos run test:integration'
   ```
   (`melos.yaml` defaults `LOOM_EMULATOR` to `emulator-5554`; any adb serial works.)

### 9.3 When WSL is retired: disabling Hyper-V

**Do this only after confirming nothing else on the host needs Hyper-V** — WSL2 itself, Docker
Desktop's WSL2 backend, Windows Sandbox, WSA, and Windows Defender's Credential Guard / Memory
Integrity all depend on it. Credential Guard in particular re-enables the hypervisor silently, which
is the usual reason "I disabled Hyper-V but VirtualBox is still slow."

Take stock first, from an **elevated** PowerShell:

```powershell
Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V-All  | Select FeatureName,State
Get-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform | Select FeatureName,State
Get-WindowsOptionalFeature -Online -FeatureName HypervisorPlatform     | Select FeatureName,State
bcdedit /enum | Select-String hypervisorlaunchtype
```

Then, still elevated:

```powershell
# 1. Export anything in WSL you still want, BEFORE disabling it.
wsl --export Ubuntu D:\backups\ubuntu-wsl-final.tar

# 2. Turn off the features. VirtualMachinePlatform is the one WSL2 actually needs;
#    Microsoft-Hyper-V-All is the full Hyper-V role.
Disable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V-All  -NoRestart
Disable-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform -NoRestart
Disable-WindowsOptionalFeature -Online -FeatureName HypervisorPlatform     -NoRestart

# 3. Stop the hypervisor from launching at boot (the step people skip).
bcdedit /set hypervisorlaunchtype off

# 4. Also turn off Memory Integrity / Credential Guard in the Windows Security UI:
#    Windows Security > Device security > Core isolation > Memory integrity -> Off
#    (It silently re-enables the hypervisor regardless of the above.)

# 5. Reboot. This is required, not optional.
Restart-Computer
```

After the reboot, verify from the host that the hypervisor is gone, then confirm from inside the
guest that the flags now arrive:

```powershell
systeminfo | Select-String "Hyper-V Requirements" -Context 0,4
# Want: "A hypervisor has been detected..." ABSENT, and the four requirements listed as Yes.
```

```bash
ssh loom-vm 'grep -oE "svm|vmx" /proc/cpuinfo | sort -u'   # expect: svm  (AMD Ryzen 9 7900X)
ssh loom-vm 'sudo /usr/sbin/kvm-ok'                        # expect: KVM acceleration can be used
ssh loom-vm 'groups | tr " " "\n" | grep -x kvm'           # expect: kvm
```

`nested-hw-virt` is already `on` for `ubuntu-24.04.4-loom`, so no VirtualBox-side change is needed —
but if you rebuild the VM, set it while the VM is **powered off**:

```powershell
.\loom-vm.ps1 stop
.\loom-vm.ps1 config-set --nested-hw-virt on
```

Then the emulator becomes usable:

```bash
ssh loom-vm '. ~/.loom-env.sh && nohup emulator -avd loom_demo -no-window -gpu swiftshader_indirect > /tmp/emulator.log 2>&1 &'
ssh loom-vm '. ~/.loom-env.sh && adb wait-for-device && adb devices'
```

### 9.4 Reversing it, if you need WSL back

```powershell
Enable-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform -NoRestart
Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V-All  -NoRestart
bcdedit /set hypervisorlaunchtype auto
Restart-Computer
# then, if the distro was removed:  wsl --import Ubuntu C:\WSL\Ubuntu D:\backups\ubuntu-wsl-final.tar
```

---

## 10. The dispatch pipeline, post-migration

The recipe from `README.md`, with WSL steps removed. Steps 1, 3, and 5's cleanup half are gone;
what remains is what was ever actually about correctness.

```bash
# 0. Author the ticket (reference-ticket-template.md). Save to ~/Loom/data/v3_ticket_<slug>.md.
#    Queue its row in the tracker's §8 BEFORE dispatching.

# 1. Dispatch, backgrounded. Never foreground -- still blocks for 5-20+ minutes.
ssh loom-vm '. ~/.loom-env.sh && cd ~/Loom && \
  DISPATCH_TRACKER_FILE="docs/Build Plan V2/<Tracker>.md" \
  DISPATCH_TODO_ITEM="<§8 row title>" \
  setsid nohup bash data/call_implementation_agent.sh data/v3_ticket_<slug>.md --fresh \
  < /dev/null > .codex-logs/<label>_dispatch.out.log 2>&1 & disown'

# 2. Watch for genuine completion.
ssh loom-vm '. ~/.loom-env.sh && cd ~/Loom && bash data/watch_dispatch_log.sh <label>'

# 3. Commit the round's real edits immediately -- BEFORE verifying, not after.
#    (This rule is unchanged and non-negotiable; see handoff_gate.sh check #3.)
ssh loom-vm 'cd ~/Loom && git status --short && git diff --stat'

# 4. Gate check -- must print READY FOR VALIDATION.
ssh loom-vm 'cd ~/Loom && bash data/handoff_gate.sh'

# 5. Independent verification -- yours, never the dispatch's self-report.
ssh loom-vm '. ~/.loom-env.sh && cd ~/Loom/app && melos run analyze'
ssh loom-vm '. ~/.loom-env.sh && cd ~/Loom/app && melos run test'
#    - shared-code change -> Regression Impact Judge (regression-impact-judge-tool.md)
#    - UI-touching change -> live device re-verification (§9.2), not analyze/test alone

# 6. Fold the outcome into the TODO record (README step 5.5). Still manual, still every time.
```

**No concurrency budget applies any more.** The "cap total concurrent sessions at 4" rule existed
solely because of the vsock cap. Delete it from your working memory along with `wsl_slot.sh`.

---

## 11. Verification checklist

Run this after completing the migration. Every line should succeed.

```bash
# Toolchain resolves non-interactively (the §3 trap)
ssh loom-vm '. ~/.loom-env.sh && which flutter dart melos codex claude git adb'

# Versions match the old environment's pins
ssh loom-vm '. ~/.loom-env.sh && flutter --version | head -1'   # 3.41.7, revision cc0734ac71
ssh loom-vm '. ~/.loom-env.sh && melos --version'               # 7.8.1

# Auth is live
ssh loom-vm 'gh auth status'
ssh loom-vm '. ~/.loom-env.sh && claude auth status'
ssh loom-vm '. ~/.loom-env.sh && codex login status'

# Codex trusts the new repo path and the profile works on a real prompt
ssh loom-vm 'grep -A1 "projects." ~/.codex/config.toml'
ssh loom-vm '. ~/.loom-env.sh && codex exec -p gpt5_3_spark_xhigh --sandbox read-only "Reply with exactly: PROFILE_OK"'

# Not sufficient on its own -- read-only skips the bwrap loopback codepath (§5.5). Confirm
# workspace-write (what every real dispatch uses) also works, post-AppArmor-fix:
ssh loom-vm '. ~/.loom-env.sh && codex exec -p gpt5_3_spark_xhigh --sandbox workspace-write "Run the shell command: echo hello"'

# Repo builds (run from app/, the actual melos workspace root -- not the repo root)
ssh loom-vm '. ~/.loom-env.sh && cd ~/Loom/app && melos bootstrap && melos run analyze'
ssh loom-vm '. ~/.loom-env.sh && cd ~/Loom/app && melos run test'

# Ported scripts are present and executable
ssh loom-vm 'ls -l ~/Loom/data/*.sh'

# Deleted things are actually gone
ssh loom-vm 'ls ~/.codex-git-shim 2>&1'                      # expect: No such file or directory
ssh loom-vm 'ls ~/Loom/data/wsl_*.sh 2>&1'                   # expect: No such file or directory

# The real proof: one throwaway ticket through dispatch -> watch -> commit -> gate, then confirm
# nothing was left running (this is what actually retires wsl_dispatch_tracker.sh -- not an
# assumption that sshd cleans up, an observed empty process list right after a real dispatch)
ssh loom-vm 'pgrep -af "codex|node" | grep -v pgrep'          # expect: no genuine codex/node hits
                                                                # (a "nodev" mount-option substring
                                                                # match is a known harmless false
                                                                # positive, not a real process)

# Emulator acceleration -- expected to FAIL until §9.3 is done
ssh loom-vm 'sudo /usr/sbin/kvm-ok'

# --- Networking + host-side control (§7, §8) ---

# Both NICs addressed, default route on the bridged one
ssh loom-vm 'ip -4 -br addr; ip route show default'

# The watchdog is installed and fires when needed
ssh loom-vm 'systemctl is-enabled loom-net-watchdog.timer; journalctl -t loom-net-watchdog -b --no-pager | tail -3'

# The real test: reboot and touch nothing
cd "docs/Build Plan V2/Tools/code"
.\loom-vm.ps1 restart
.\loom-vm.ps1 wait-ready 300      # -> "SSH ready at 192.168.56.10"

# Host-side control works without SSH
.\loom-vm.ps1 status
.\loom-vm.ps1 screenshot
.\loom-vm.ps1 run "uptime"
```

---

## 12. Known gaps

| Gap | Status | Action |
|---|---|---|
| Android emulator has no hardware acceleration | **Open, deferred by decision.** Now confirmed by a *valid* test (`nested-hw-virt=on` on the correct VM, `HypervisorPresent=True` on the host) | §9.3, once WSL is retired |
| VM lost its IP on reboot | **Closed** | Host-only static IP + infinite DHCP retry + `loom-net-watchdog.timer`; verified across repeated unattended reboots (§7) |
| No way to drive the VM when SSH is down | **Closed** | `code/loom-vm.ps1` — power, config, screenshots, in-guest commands, none requiring SSH (§8) |
| Guest RCU stall / boot hang | Seen once, transient | Recovered by a clean power-cycle. If it recurs, reduce vCPU count (§8, last subsection) |
| Dispatch pipeline not yet run end to end on the VM | **Closed 2026-08-12** | A real throwaway ticket ran the full pipeline (dispatch → watch → commit → `handoff_gate.sh`, all 4 checks passed) end to end; commit reverted immediately after (§10 recipe, proof captured in this migration's closing session) |
| AppArmor (`kernel.apparmor_restrict_unprivileged_userns=1`, Ubuntu 24.04 default) blocks bubblewrap's sandbox loopback setup under `--sandbox workspace-write` | **Closed 2026-08-12** | Local AppArmor profile at `/etc/apparmor.d/bwrap` granting only `bwrap` the `userns` permission (§5.5) — found via the throwaway ticket above, which failed until this was applied |
| `melos run analyze`/`melos run test` surfaced 2 pre-existing, migration-unrelated failures (a `directives_ordering` lint in `loom_api_contracts.dart`, a widget-finder assertion failure in `v3_milestone_phasee_purchase_proposal_test.dart` under `loom_communities_app_shell`) | **Open, out of scope for this migration** | Both predate this work (last touched by unrelated feature commits, identical on host and guest at the same commit) and live under `app/`, which this migration explicitly does not touch. Worth a real ticket separately — not filed as part of this task |
| `~/.config/loom-vm/secrets.env` is scaffolded but empty | Open, low priority | Only needed if you install `opencode`; nothing in the Loom repo reads `GEMINI_API_KEY`/`OPENAI_API_KEY`/`GOOGLE_API_KEY`. Rotate the old values first — they were exposed in a terminal transcript during the WSL inventory. |
| USB passthrough not yet exercised end to end | Open | Needs a physical device present; §9.2 |
| Dispatch pipeline not yet run end to end on the VM | Open | Do one low-stakes ticket before trusting it for a real round |
| DeepSeek gateway URL still points at a WSL IP | Inert | Only matters if a `deepseek_*` profile is revived; §5.1 note |

---

## 13. Why this is worth doing

Beyond the emulator, the migration deletes an entire class of failure this project spent real time
fighting — every one of these is a documented incident from `dispatch-pipeline-tools.md`:

- **Git index corruption** (`index file smaller than expected`, `unable to write new index file`) —
  caused by OneDrive's cloud-filter driver racing git's atomic index writes across v9fs. Twice
  collapsed the tracked tree while `git status` still reported clean. **Gone with the filesystem.**
- **vsock exhaustion** — dispatches exiting 0 having silently done nothing. **Gone with WSL.**
- **Orphaned WSL processes** surviving 5+ hours, requiring a purpose-built tracker to reap.
  **Gone with WSL.**
- **Stale Gradle builds** from unreliable drvfs mtime propagation — a 9-day-old cached APK passed
  `flutter build apk` and only failed as a live runtime crash. **Substantially reduced** on ext4;
  keep `verify_apk_freshness.sh` anyway, because Gradle staleness is not exclusively a drvfs problem.

What does **not** change, and still requires the same discipline: dispatch, then independently
verify, every single time. The VM removes environmental failure modes. It does not make an agent's
self-report trustworthy.
