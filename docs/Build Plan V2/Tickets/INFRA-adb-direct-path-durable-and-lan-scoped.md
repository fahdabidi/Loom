# INFRA — make the VM's direct adb path survive a reboot, without exposing the emulator to the LAN

**Status:** DONE 2026-10-18, verified end to end — except the one proof only a real reboot can give
(see the last section). User-approved 2026-10-18. Host configuration, done by the validation agent.

## Why

Since the Hyper-V move the Loom VM can reach the Windows emulator directly with
`adb -H 192.168.56.1 -P 5037`, but only while the Windows adb server listens on all interfaces. It did
because it had been started by hand as `adb.exe -a nodaemon server`; after a reboot or any
`adb kill-server`, a default server binds 127.0.0.1 and the VM falls back to the reverse ssh tunnel,
which died twice in one tick on 2026-10-12.

## The finding that changed the order of work: the emulator was open to the whole LAN

Before making anything permanent, measured with a control, from a LAN source address (192.168.50.86):

| probe | result |
|---|---|
| TCP `192.168.50.134:5037` (the host's LAN address) | **OPEN** |
| `adb -H 192.168.50.134 -P 5037 devices` | **`emulator-5554 device`** |
| control, TCP `192.168.50.134:5038` | closed |

Cause: Windows' four auto-created `adb` inbound allow rules admitted **remote address Any** on both
Private and Public profiles, and the LAN adapter is Private. So since 13:14 that day any device on the
network could drive the emulator. Making the all-interfaces server durable as it stood would have made
that permanent.

## What was done

1. **Firewall scoped** (elevated, user-approved UAC): all four `adb` rules set to
   `-RemoteAddress 192.168.56.0/24 -EdgeTraversalPolicy Block`. The first attempt failed — these rules
   carry `EdgeTraversalPolicy DeferToUser`, which forbids any extra condition — and **my script printed
   "applied" anyway**, because the errors did not stop it; only the AFTER listing caught it. The second
   script used `-ErrorAction Stop` and decided success from the AFTER state alone: `VERDICT: SCOPED`,
   0 failures, 0 rules admitting Any. No other inbound rule admits adb.exe or port 5037.
   Rollback: `Get-NetFirewallRule -DisplayName adb | Set-NetFirewallRule -RemoteAddress Any -EdgeTraversalPolicy DeferToUser`
2. **Launcher** `docs/Build Plan V2/Tools/code/adb-all-interfaces.ps1`, idempotent: no-op if already
   on all interfaces; kill-and-restart with `-a` if loopback-only; start if absent. It **refuses (exit 3)
   to start an all-interfaces server while any `adb` rule admits Any**, so an adb update that re-creates
   the rules cannot silently re-open the LAN. Exit codes: 0 ok, 2 started but never listened, 3 refused,
   4 adb missing, 1 unhandled error.
3. **Startup shortcut** `%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\Loom - adb on all interfaces.lnk`
   → `powershell.exe -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File "%LOCALAPPDATA%\Loom\adb-all-interfaces.ps1"`.
   It runs a **local** copy because the repo lives under OneDrive; re-copy after editing the tracked one.

## Verified

| step | result |
|---|---|
| launcher while rules admitted Any | **refused**, exit 3, adb untouched |
| after scoping — LAN `192.168.50.134:5037` | **closed**, no device |
| after scoping — host-only `192.168.56.1:5037` | open, `emulator-5554 device` |
| launcher on a healthy all-interfaces server | no-op, exit 0 |
| simulated reboot: default server, loopback only | VM direct path **fails** (the control) |
| shortcut's exact command from that state | restart with `-a`, exit 0, `0.0.0.0:5037` |
| server persists into a new command | yes, `adb.exe -a nodaemon server` |
| emulator re-registered | `emulator-5554 device`; VM `get-state` → `device` |

The launcher's first version **failed** the reboot simulation (exit 2, server still loopback): it called
a function returning one `CimInstance`, PowerShell unrolled it, and `CimInstance.Count` is empty in
PowerShell 5.1, so "is anything listening" read false and the kill never ran. Fixed by wrapping at the
call site, `@(Get-AdbListeners)`, and re-proven from the same loopback state.

## Owed: the real-reboot proof

The shortcut's command line was tested; a real logon running it was not. After the next host reboot:

    loom-vm.ps1 status          # its 'adb server:' line must read 'all interfaces'
    type "%LOCALAPPDATA%\Loom\adb-all-interfaces.log"

If it reads loopback-only, the shortcut did not run or ran before something else started a default
server — run the launcher by hand and record which.
