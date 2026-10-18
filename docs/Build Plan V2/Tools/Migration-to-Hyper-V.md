# Migrating a VirtualBox VM to Hyper-V on this host

For the orchestrator agent working in the Loom repo. Written 2026-10-18 by the ai-controller
orchestrator after migrating the shared Loom VM. Part 1 says what already changed for the Loom VM you
drive. Part 2 is the runbook for migrating any other VirtualBox VM on this host the same way.

## Part 1 — The Loom VM is already on Hyper-V

The VM that `docs/Build Plan V2/Tools/code/loom-vm.ps1` is hard-locked to, `ubuntu-24.04.4-loom`, was
migrated on 2026-10-18 at 14:27. Nothing inside the guest moved: same disk contents, same users, same
`~/Loom`, `~/loom-backend`, `~/ai-range` and `~/ai-controller` checkouts, same k3s cluster, same addresses.

| Item | Before | Now |
| --- | --- | --- |
| Hypervisor | VirtualBox 7 on the Hyper-V fallback engine (NEM) | Hyper-V, Generation 1 VM named `loom-vm` |
| Disk | `C:\VirtualBox\ubuntu-24.04.4-loom\loom-root-300g.vdi` (kept, powered off) | `C:\Hyper-V\loom\loom-root.vhdx` (dynamic, 300 GB virtual) |
| CPU / RAM | 8 vCPU / 8 GB | 8 vCPU / 8 GB static |
| LAN NIC | bridged, guest `enp0s3`, MAC 08:00:27:3f:05:f1 | switch `loom-external` on the Realtek adapter, guest `eth0`, same MAC, same DHCP lease 192.168.50.86 |
| Host-only NIC | VirtualBox host-only adapter, guest `enp0s8`, 192.168.56.10 | switch `loom-internal`, guest `eth1`, 192.168.56.10; host side 192.168.56.1 on `vEthernet (loom-internal)` |
| Guest services | `vboxadd`, `vboxadd-service` | disabled; `hv_vmbus hv_netvsc hv_storvsc hv_utils hv_balloon` loaded |
| k3s | node IP followed DHCP | pinned `node-ip: 192.168.56.10` in `/etc/rancher/k3s/config.yaml`; still not enabled at boot |
| Stalls | 60–170 s `rcu_preempt kthread starved` every 10–35 min | none in the first hours; 24 h proof in progress |

What this means for your tooling:

1. **`loom-vm.ps1` no longer controls the live VM.** It drives the VirtualBox copy, which must stay
   powered off: it has the same MACs and IPs as the Hyper-V VM, so starting both breaks the network for
   both. Treat `loom-vm.ps1 start` as forbidden until the script is retargeted. Rollback to VirtualBox
   is still possible (stop the Hyper-V VM first), and the `.vdi` is kept for two weeks from 2026-10-18.
2. **Lifecycle now goes through Hyper-V**, which needs an elevated shell:
   `Start-VM loom-vm`, `Stop-VM loom-vm` (ACPI), `Stop-VM loom-vm -TurnOff`, `(Get-VM loom-vm).State`.
   A thin wrapper exists at `ai-controller/data/vm/loom-vm-hyperv.ps1 start|stop|poweroff|state`. Your
   script's in-guest features (`run`, `screenshot`, `fix-network`) relied on VirtualBox Guest Additions;
   their Hyper-V equivalents are `Invoke-Command -VMName loom-vm` (PowerShell Direct, needs a guest
   login) and `vmconnect`. ssh is the normal path and is unchanged (`ssh loom-vm`).
3. **After a host reboot:** `Start-VM loom-vm` (elevated), wait for ssh, `sudo systemctl start k3s`,
   wait for `kubectl get pods -n loom` to show 1/1 (it took 10 s on Hyper-V against 90 s+ before). The
   adb reverse tunnel steps are unchanged. The VM is not set to autostart (`AutomaticStartAction
   Nothing`) on purpose.
4. **Interface names changed** inside the guest (`eth0`, `eth1`). Anything in your docs or scripts that
   greps `enp0s3`/`enp0s8` must switch to MAC or address. NetworkManager profiles already match by MAC.
5. **Loom tracker and CLAUDE.md** should record the new recovery steps (your "VM recovery" section still
   names `loom-vm.ps1`), and the script should be retargeted or retired. Details of the migration run are
   in the ai-controller tracker, §8 rows "INFRA-1 slotted" and "INFRA-1 landed", and the ticket
   `ai-controller/docs/Build Plan/Tickets/infra-move-vm-to-hyperv.md`.

## Part 2 — Runbook for the remaining VirtualBox VMs

Two other VMs are still on VirtualBox on this host, both powered off at the time of writing:

| VM | Disk | Size on disk | RAM / CPUs | NICs |
| --- | --- | --- | --- | --- |
| `ubuntu-24.04.4-Genio520-firmware` | `C:\Virtualbox VMs\...\ubuntu-24.04.4-Genio520-firmware.vdi` | 437 GB (467 GB virtual) | 16 GB / 8 | one bridged, MAC 08:00:27:91:3e:0f |
| `Ubuntu-24.04.4` | `D:\VirtualBox\Ubuntu-24.04.4\Ubuntu-24.04.4.vdi` | — | 8 GB / 8 | one bridged |

Both are BIOS-boot Ubuntu 24.04, so the same Generation 1 recipe applies. Confirm each owner wants its VM
moved before touching it; the Loom VM's owner decision covered only the Loom VM.

### Prerequisites

- Windows 11 Pro with Hyper-V enabled (done on this host; `Get-Service vmms` is Running).
- An elevated PowerShell for every Hyper-V and `Convert-VHD` step. A non-elevated shell cannot even
  list VMs or switches, so do not read "no VMs" from a user shell as "migration failed".
- Free space: the clone needs the disk's size-on-disk twice over for a moment (VHD plus VHDX) on the
  target drive. The Genio520 disk needs about 900 GB free during conversion; C: had 2.7 TB.
- Timings seen for 189 GB on disk: `clonemedium` 16 min at about 10 GB/min, `Convert-VHD` 16 min.
  Scale linearly: the Genio520 disk is about 2.3× that.
- The switches `loom-internal` (192.168.56.1/24) and `loom-external` (Realtek, management OS allowed)
  already exist. Reuse `loom-external` for any bridged NIC. Use `loom-internal` only if the VM needs the
  host-only network, and give it a different address from 192.168.56.10.

### Step 1 — Prepare the guest while it still runs on VirtualBox

Reversible; everything also works on VirtualBox, so do it in advance and reboot once to prove it.

```bash
# record identity
ip -br link                      # MACs; Hyper-V will name the NICs eth0, eth1...
ls /etc/netplan; sudo cat /etc/netplan/*.yaml
sudo mkdir -p /root/hyperv-backup && sudo cp -a /etc/netplan /root/hyperv-backup/

# match NICs by MAC, not by name (one block per NIC; keep whatever addressing each already has)
# e.g. for a DHCP bridged NIC with MAC 08:00:27:91:3e:0f:
printf 'network:\n  version: 2\n  ethernets:\n    lan0:\n      match:\n        macaddress: "08:00:27:91:3e:0f"\n      dhcp4: true\n' \
  | sudo tee /etc/netplan/50-cloud-init.yaml >/dev/null
sudo chmod 600 /etc/netplan/*.yaml
sudo netplan generate            # must print no error

# Hyper-V drivers are in Ubuntu's stock initramfs (MODULES=most); verify:
lsinitramfs /boot/initrd.img-$(uname -r) | grep -c hv_   # expect >= 4

# retire the VirtualBox guest services
sudo systemctl disable --now vboxadd.service vboxadd-service.service 2>/dev/null

# if the guest runs k3s or anything that binds to an address, pin it (the Loom VM needed
# node-ip: 192.168.56.10 in /etc/rancher/k3s/config.yaml)
```

If the guest has a NetworkManager-managed profile (the Loom VM's `loom-hostonly`), edit its netplan
override to `match: macaddress:` as well; `nmcli` profiles that match by interface name silently fail
to attach on Hyper-V.

Then a clean shutdown: `sudo poweroff`, and confirm `VBoxManage showvminfo <vm> --machinereadable |
findstr VMState` says `poweroff`. Never clone a running or saved VM's disk.

### Step 2 — Convert the disk (elevated)

```powershell
$VBox='C:\Program Files\Oracle\VirtualBox\VBoxManage.exe'
$Dir='C:\Hyper-V\<vm>'; New-Item -ItemType Directory -Force $Dir | Out-Null
& $VBox clonemedium disk '<path to .vdi>' "$Dir\root.vhd" --format VHD      # long
& $VBox closemedium disk "$Dir\root.vhd"      # drop it from VirtualBox's media registry
Convert-VHD -Path "$Dir\root.vhd" -DestinationPath "$Dir\root.vhdx" -VHDType Dynamic   # long
Remove-Item "$Dir\root.vhd"
```

A 2 TB+ VHD is fine; `Convert-VHD` handles it. Disks over 2040 GB virtual cannot stay VHD and must go
to VHDX, which this does anyway.

### Step 3 — Create the VM (elevated)

```powershell
$Vm='<name>'
New-VM -Name $Vm -Generation 1 -MemoryStartupBytes 16GB -VHDPath "$Dir\root.vhdx" -SwitchName 'loom-external'
Set-VM -Name $Vm -ProcessorCount 8 -StaticMemory -AutomaticCheckpointsEnabled $false `
       -AutomaticStopAction ShutDown -AutomaticStartAction Nothing
Set-VMNetworkAdapter -VMName $Vm -StaticMacAddress '080027913E0F'     # the VirtualBox MAC, no colons
Set-VMProcessor -VMName $Vm -ExposeVirtualizationExtensions $false    # note: -VMName, not -Name
# only if the VM needs the host-only network:
# Add-VMNetworkAdapter -VMName $Vm -SwitchName 'loom-internal' -StaticMacAddress '<its MAC>'
Start-VM $Vm
```

Keep the VirtualBox MACs so DHCP leases and any MAC-based config survive. Static memory: k3s, Gradle
and firmware builds misbehave under dynamic memory on an 8 GB host budget. Generation 1 because the
guests boot BIOS (GPT with a `bios_grub` partition); Generation 2 would need a UEFI reinstall of GRUB.

The reference implementation of steps 2 and 3, with the Loom VM's values and an idempotent structure,
is `ai-controller/data/vm/infra1-migrate-to-hyperv.ps1`. Copy it per VM; do not run it unchanged.

### Step 4 — Verify with your own commands

- ssh answers within about a minute of `Start-VM`; `systemd-detect-virt` prints `microsoft`.
- `ip -br addr` shows the expected addresses on `eth0`/`eth1`; `lsmod | grep hv_` lists five modules.
- `nproc` and `free -h` match the requested CPUs and RAM.
- Whatever the VM serves answers from the host (for the Loom VM: Keycloak `:30082` gave 302, app-access
  `:30080/healthz` gave 401 as expected without a token).
- If the VM needs the Android emulator: `adb -H 192.168.56.1 -P 5037 devices` from the guest. No
  firewall change was needed on this host; the existing "adb" rules already applied.
- Leave it 24 h and count `journalctl -k -b | grep -c "kthread starved"`; the VirtualBox baseline was
  23 in 14 h. Zero is the bar.

### Step 5 — Rollback and cleanup

- Rollback at any point: `Stop-VM <name>` (or `-TurnOff`), re-enable the VirtualBox host-only adapter if
  the VM used it (`Enable-NetAdapter -Name 'Ethernet 2'`; the internal switch then conflicts on
  192.168.56.1, so remove its address or the switch), then start the VirtualBox VM. The guest changes
  from step 1 work on both hypervisors.
- Keep the `.vdi` for two weeks after step 4 passes, then delete it and the stale copies (the Loom VM
  also has an unattached 286 GB `D:\VirtualBox\ubuntu-24.04.4-loom\ubuntu-24.04.4-loom.vdi`).
- Never run the VirtualBox copy and the Hyper-V copy at the same time: identical MACs and addresses.

### Traps met during the Loom migration

- `Set-VMProcessor` takes `-VMName`, not `-Name`; the first run of the script died on that line after the
  VM was already created, and the firewall step after it was skipped.
- Windows does not update a file's size while another process holds it open, so the clone looks stuck
  at 0 bytes; watch the drive's free space instead.
- Building the external switch drops the host's network for a few seconds; do it at the console.
- The auto-mode permission classifier in Claude Code may refuse guest config edits as "shared
  resources" on one run and allow them on the next; have the owner present or add a permission rule.
- The guest's netplan file for the DHCP NIC was root-only (`0600`); keep that mode when rewriting it or
  `netplan generate` warns and cloud-init may re-render it.
