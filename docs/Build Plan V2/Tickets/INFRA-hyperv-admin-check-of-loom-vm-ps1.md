# INFRA — exercise the retargeted `loom-vm.ps1` against Hyper-V once, elevated

**Status:** DONE 2026-10-18 — run elevated with the user's UAC approval and verified. Not an
implementation-agent ticket: host infrastructure, done by the validation agent with the user present.

## Why

`loom-vm.ps1` was retargeted from VirtualBox to Hyper-V on 2026-10-18, after the Loom VM moved
(runbook `docs/Build Plan V2/Tools/Migration-to-Hyper-V.md`). Its non-elevated verbs were tested then;
its Hyper-V side could not be, because an agent shell is not elevated and `Get-VM` refuses even to read
state from one.

## What was run

`docs/Build Plan V2/Tools/code/loom-vm.ps1 state` and `status` from an elevated PowerShell, plus an
independent `Get-VM` / `Get-VMNetworkAdapter` read so the script was not checking itself.

## Result

| check | result |
|---|---|
| elevated | True |
| `loom-vm.ps1 state` | `Running` |
| `loom-vm.ps1 status` | State `Running`; VirtualBox copy `poweroff`; ssh + all three NodePorts reachable; C: 2,558.8 GB free; VHDX 183.3 GB |
| `Get-VM loom-vm` | Generation 1, 8 CPUs, MemoryStartup 8 GiB, **DynamicMemoryEnabled False**, AutomaticStartAction Nothing, AutomaticStopAction ShutDown |
| NICs | `loom-external` 0800273F05F1, `loom-internal` 0800279057FD — the old VirtualBox MACs |
| Hyper-V VMs on host | `loom-vm` only |

## Still untested, deliberately

The state-changing verbs — `start`, `stop`, `poweroff`, `restart`, `resume`, `console`. Three of them
would take the live VM down, and there was no reason to. The first real recovery is their test; their
refusal paths (non-elevated → exit 1 with guidance; VirtualBox copy running or unreadable → refuse)
were tested 2026-10-18, the latter against stub `VBoxManage` binaries in four states.
