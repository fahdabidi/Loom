# Migrating the dispatch pipeline from WSL Ubuntu to a VirtualBox Ubuntu VM

This guide moves the Loom agent tooling (`docs/Build Plan V2/Tools/`) off WSL2 and onto a
VirtualBox Ubuntu 24.04 VM. It is written against the VM that was actually built and validated for
this purpose — hostname `fahd-VirtualBox`, user `fahd`, bridged IP `192.168.50.86`.

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
| Android emulator | Ran on the Windows host | Inside the guest — **needs the Hyper-V decision in §7** |

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
- **SSH key access** — `~/.ssh/loom_vm_ed25519` on the Windows host, aliased as `loom-vm` in
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
    HostName 192.168.50.86
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

## 7. Hyper-V, WSL2, and emulator acceleration

**This is the one genuinely unresolved item, and it is deferred by decision, not oversight.**

### 7.1 The conflict

Windows can only have one thing owning the CPU's virtualization extensions at a time. WSL2 requires
the Hyper-V hypervisor. When that hypervisor is running, VirtualBox is demoted to running *on top of*
it (via the Windows Hypervisor Platform API), and in that mode it cannot reliably expose nested
AMD-V/SVM to its own guests.

Measured on this machine, with `nested-hw-virt` already set to `on` and CPU profile `host`:

```bash
$ ssh loom-vm 'grep -oE "svm|vmx" /proc/cpuinfo | sort -u'      # -> empty
$ ssh loom-vm 'sudo /usr/sbin/kvm-ok'
INFO: Your CPU does not support KVM extensions
KVM acceleration can NOT be used
```

The guest sees no virtualization flags at all. This is not a guest misconfiguration — the flags are
not being passed down. The practical cost is that the Android emulator inside the VM falls back to
pure software rendering, which is slow enough to make emulator-based integration testing impractical.

### 7.2 Current decision: leave Hyper-V enabled, test on a physical device

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

### 7.3 When WSL is retired: disabling Hyper-V

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

`nested-hw-virt` is already `on` for this VM, so no VirtualBox-side change is needed — but if you
rebuild the VM, set it while the VM is **powered off**:

```powershell
& "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe" modifyvm "Ubuntu-24.04.4" --nested-hw-virt on
```

Then the emulator becomes usable:

```bash
ssh loom-vm '. ~/.loom-env.sh && nohup emulator -avd loom_demo -no-window -gpu swiftshader_indirect > /tmp/emulator.log 2>&1 &'
ssh loom-vm '. ~/.loom-env.sh && adb wait-for-device && adb devices'
```

### 7.4 Reversing it, if you need WSL back

```powershell
Enable-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform -NoRestart
Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V-All  -NoRestart
bcdedit /set hypervisorlaunchtype auto
Restart-Computer
# then, if the distro was removed:  wsl --import Ubuntu C:\WSL\Ubuntu D:\backups\ubuntu-wsl-final.tar
```

---

## 8. The dispatch pipeline, post-migration

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
#    - UI-touching change -> live device re-verification (§7.2), not analyze/test alone

# 6. Fold the outcome into the TODO record (README step 7.5). Still manual, still every time.
```

**No concurrency budget applies any more.** The "cap total concurrent sessions at 4" rule existed
solely because of the vsock cap. Delete it from your working memory along with `wsl_slot.sh`.

---

## 9. Verification checklist

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

# Repo builds
ssh loom-vm '. ~/.loom-env.sh && cd ~/Loom/app && melos bootstrap && melos run analyze'

# Ported scripts are present and executable
ssh loom-vm 'ls -l ~/Loom/data/*.sh'

# Deleted things are actually gone
ssh loom-vm 'ls ~/.codex-git-shim 2>&1'                      # expect: No such file or directory
ssh loom-vm 'ls ~/Loom/data/wsl_*.sh 2>&1'                   # expect: No such file or directory

# Emulator acceleration -- expected to FAIL until §7.3 is done
ssh loom-vm 'sudo /usr/sbin/kvm-ok'
```

---

## 10. Known gaps

| Gap | Status | Action |
|---|---|---|
| Android emulator has no hardware acceleration | **Open, deferred by decision** | §7.3, once WSL is retired |
| `~/.config/loom-vm/secrets.env` is scaffolded but empty | Open, low priority | Only needed if you install `opencode`; nothing in the Loom repo reads `GEMINI_API_KEY`/`OPENAI_API_KEY`/`GOOGLE_API_KEY`. Rotate the old values first — they were exposed in a terminal transcript during the WSL inventory. |
| USB passthrough not yet exercised end to end | Open | Needs a physical device present; §7.2 |
| Dispatch pipeline not yet run end to end on the VM | Open | Do one low-stakes ticket before trusting it for a real round |
| DeepSeek gateway URL still points at a WSL IP | Inert | Only matters if a `deepseek_*` profile is revived; §5.1 note |

---

## 11. Why this is worth doing

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
