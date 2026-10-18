# INFRA — delete the two VirtualBox disks of the Loom VM, on or after 2026-11-01

**Status:** QUEUED — **do not start before 2026-11-01**, and not before both preconditions below hold.
User-approved 2026-10-18 ("do all of these"), with the date as part of what was approved. Irreversible.

## What

| file | size on disk (2026-10-18) | role |
|---|---|---|
| `C:\VirtualBox\ubuntu-24.04.4-loom\loom-root-300g.vdi` | 176.3 GB | **the only rollback path** to VirtualBox; attached to the powered-off `ubuntu-24.04.4-loom` |
| `D:\VirtualBox\ubuntu-24.04.4-loom\ubuntu-24.04.4-loom.vdi` | 285.8 GB | unattached stale copy, last written 2026-09-18 |

## Preconditions — check each at the time, do not carry them forward from this ticket

1. **The date is 2026-11-01 or later** — the runbook's two-week rollback window from the 2026-10-18 migration.
2. **The 24-hour guest-stall proof on Hyper-V has passed** (tracker row-359): zero `kthread starved`
   lines over a full day. If stalls persist on Hyper-V, rollback may still be wanted — keep the C: disk.
3. **Nothing references either file.** `VBoxManage showvminfo ubuntu-24.04.4-loom --machinereadable`
   names the attached disk; `VBoxManage list hdds` lists every disk VirtualBox knows. A disk still
   registered must be released with `VBoxManage closemedium disk <path>` before deletion, or VirtualBox
   keeps a dangling registry entry.

## How

    $VB = 'C:\Program Files\Oracle\VirtualBox\VBoxManage.exe'
    & $VB showvminfo ubuntu-24.04.4-loom --machinereadable | Select-String '\.vdi'   # record first
    & $VB list hdds
    # unregister the rollback VM and its disk together, which also deletes the C: VDI:
    & $VB unregistervm ubuntu-24.04.4-loom --delete
    # the D: copy is unattached; release it if listed, then delete:
    & $VB closemedium disk 'D:\VirtualBox\ubuntu-24.04.4-loom\ubuntu-24.04.4-loom.vdi'
    Remove-Item 'D:\VirtualBox\ubuntu-24.04.4-loom\ubuntu-24.04.4-loom.vdi'

**Never touch the other two VirtualBox VMs** (`Ubuntu-24.04.4`, `ubuntu-24.04.4-Genio520-firmware`) —
they belong to other projects. `unregistervm` takes the exact name; confirm it before running.

## Verify

Free space on C: rises by ~176 GB and on D: by ~286 GB; `VBoxManage list vms` no longer lists
`ubuntu-24.04.4-loom`; `loom-vm.ps1 status` reports the VirtualBox copy as `not-registered` (the
script treats that as safe — it was built so a deleted copy does not become a permanent refusal).
