# Enabling KVM in the Loom VM (disabling the host hypervisor)

**Written 2026-08-18.** Run this to give the Android emulator hardware acceleration inside
`ubuntu-24.04.4-loom`. Every step below is elevated-PowerShell on the **Windows host**, except where it
says otherwise.

## Why this is the fix (and why "enable Hyper-V" is not)

The Android emulator needs **KVM** inside the Ubuntu guest. KVM needs the CPU's VT-x extensions. On this
machine VT-x is currently owned by the **Windows hypervisor**, which does not hand it down to VirtualBox,
so the guest has no `/dev/kvm` and the emulator falls back to pure software emulation.

Measured state before the change:

| Check | Value |
|---|---|
| `(Get-CimInstance Win32_ComputerSystem).HypervisorPresent` | `True` |
| VirtualBox `nested-hw-virt` / `hwvirtex` / `nestedpaging` | already `on` / `on` / `on` |
| Guest `/dev/kvm` | absent |
| Guest `vmx`/`svm` CPU flags | absent |
| `sudo kvm-ok` in guest | "Your CPU does not support KVM extensions" |

**VirtualBox is already configured correctly — nothing to change there.** The only lever is stopping the
Windows hypervisor from claiming VT-x at boot.

## Why it is now safe

`wsl-to-virtualbox-migration.md` §9 deferred this with: *"Until WSL is fully retired, the host keeps
Hyper-V and the emulator stays unaccelerated."* That condition is now met:

- The dispatch pipeline runs entirely on this VM over `ssh loom-vm` — WSL is no longer in the loop.
- `wsl --list --verbose` shows one distro (`Ubuntu`, v2) in state **Stopped**.
- Docker Desktop is **not installed**.

**What this breaks:** WSL2 stops working while the hypervisor is off (WSL2 requires it). WSL1 distros
still work. Nothing else on this host depends on it. Fully reversible — see Rollback.

---

## Procedure

### 1. Shut the guest down cleanly first — do not skip this

A host reboot while the VM is running is an unclean guest shutdown. This VM has **already had one real
ext4 emergency-read-only incident** (2026-08-17) that required recovery, so give it a clean stop:

```powershell
ssh loom-vm 'sudo shutdown -h now'
```

Wait ~30 seconds, then confirm it is off:

```powershell
& "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe" list runningvms
```

That should print nothing (or not list `ubuntu-24.04.4-loom`).

### 2. Record the current boot setting, so rollback is exact

```powershell
bcdedit /enum "{current}" | Select-String hypervisorlaunchtype
```

Note what it prints (typically `Auto`). If it prints nothing, the value is unset and defaults to `Auto`.

### 3. Turn the hypervisor off at boot

```powershell
bcdedit /set hypervisorlaunchtype off
```

This is the minimal, reversible change: it stops the hypervisor launching **without uninstalling the
Hyper-V feature**, so re-enabling is one command rather than a feature reinstall.

### 4. Check Core Isolation / Memory Integrity

Even with the hypervisor off at boot, **Memory Integrity** (Windows Security → Device security → Core
isolation) re-enables virtualization-based security and will hold VT-x. If it is **On**, turn it **Off**
— it is a UI toggle, not a command, and it also requires a reboot.

### 5. Reboot the host

```powershell
Restart-Computer
```

### 6. After reboot — verify on the host

```powershell
(Get-CimInstance Win32_ComputerSystem).HypervisorPresent    # expect: False
```

If this still prints `True`, something else is holding the hypervisor — most likely Memory Integrity
(step 4), or Windows Sandbox / Virtual Machine Platform / Windows Hypervisor Platform. Check those before
going further; do not proceed expecting KVM to appear.

### 7. Start the VM and verify in the guest

```powershell
& "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe" startvm "ubuntu-24.04.4-loom" --type headless
```

Then, once SSH answers:

```powershell
ssh loom-vm 'ls -l /dev/kvm; grep -o -m1 "vmx\|svm" /proc/cpuinfo; sudo /usr/sbin/kvm-ok; groups | tr " " "\n" | grep -x kvm'
```

Expected: `/dev/kvm` exists, `vmx` present, `KVM acceleration can be used`, and the user is in the `kvm`
group. **If `/dev/kvm` exists but the group is missing**, add it and re-login:

```powershell
ssh loom-vm 'sudo usermod -aG kvm $USER'
```

### 8. Confirm the emulator actually accelerates

```powershell
ssh loom-vm '~/Android/Sdk/emulator/emulator -accel-check'
```

Expected: accel is working. Then a real boot, which should now take a couple of minutes rather than
tens:

```powershell
ssh loom-vm 'setsid nohup ~/Android/Sdk/emulator/emulator -avd loom_demo -no-window -no-audio -no-snapshot -no-metrics > ~/emulator_boot.log 2>&1 < /dev/null & disown'
ssh loom-vm '~/Android/Sdk/platform-tools/adb wait-for-device shell getprop sys.boot_completed'
```

Note: drop `-no-accel` and `-gpu swiftshader_indirect` once KVM works — those were software-mode
workarounds.

---

## Rollback

To restore the previous behaviour (and WSL2):

```powershell
bcdedit /set hypervisorlaunchtype auto
Restart-Computer
```

Re-enable Memory Integrity in Windows Security if you turned it off. Nothing was uninstalled, so no
feature reinstall is needed.

---

## Known state at time of writing

- Local and VM git both at `b9b6c766`, everything pushed to `origin/main` — nothing is lost by rebooting.
- The only untracked files on the VM are the pre-existing `ROOT_CAUSE_REPORT_2.md` / `_3.md`.
- The community-JSON lock (`chmod 444`) does **not** survive a `git reset`; re-apply after any sync
  (`loop.md` §1.2).
- The session-local loop agent and any Monitors die with the host reboot; re-arm with
  `bash data/loop_emitter.sh data/loops 30` as a persistent Monitor. The registry in `data/loops/`
  survives on disk.
