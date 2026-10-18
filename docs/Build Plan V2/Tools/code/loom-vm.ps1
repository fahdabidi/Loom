<#
.SYNOPSIS
  Host-side control for the Loom VM, which runs on Hyper-V as 'loom-vm'.

.DESCRIPTION
  Retargeted 2026-10-18 from VirtualBox to Hyper-V, after the VM itself was
  migrated (runbook: docs/Build Plan V2/Tools/Migration-to-Hyper-V.md; ai-controller ticket
  docs/Build Plan/Tickets/infra-move-vm-to-hyperv.md). Nothing inside the guest
  moved: same disk contents, same ~/Loom, same k3s cluster, same addresses.

  SAFETY -- two hard locks:
  1. Lifecycle verbs act ONLY on the Hyper-V VM named in $VM_NAME.
  2. This script NEVER starts, stops or modifies any VirtualBox VM. The
     VirtualBox copy ('ubuntu-24.04.4-loom') is kept for rollback and has the
     SAME MAC addresses and IPs as the Hyper-V VM, so running both at once
     breaks the network for both. 'status' reads its state and warns if it is
     not powered off, and 'start'/'restart' refuse while it is running.

  Lifecycle verbs need Hyper-V access: an elevated PowerShell, or membership of
  the local 'Hyper-V Administrators' group (then sign out and back in). A
  non-elevated shell cannot even read the VM's state, so a refusal from Get-VM
  is NOT evidence that the VM is missing or stopped. 'status' therefore probes
  the guest over the network and works without elevation.

  Rollback to VirtualBox is manual and deliberate, never through this script:
    Stop-VM -Name loom-vm                       # elevated; wait for Off
    Enable-NetAdapter -Name 'Ethernet 2'        # the VirtualBox host-only adapter
    # it also wants 192.168.56.1: remove that address from
    # 'vEthernet (loom-internal)' (or remove the switch) first
    & 'C:\Program Files\Oracle\VirtualBox\VBoxManage.exe' startvm ubuntu-24.04.4-loom --type headless
  The VirtualBox-era version of this script is in git history.

.EXAMPLE
  .\loom-vm.ps1 status        # no elevation needed
  .\loom-vm.ps1 start         # elevated
  .\loom-vm.ps1 stop          # elevated; integration-services shutdown (ACPI-like)
  .\loom-vm.ps1 poweroff      # elevated; hard cut, only after 'stop' fails
  .\loom-vm.ps1 wait-ready
  .\loom-vm.ps1 console       # elevated; the console, for when ssh is down
#>
[CmdletBinding()]
param(
  [Parameter(Mandatory = $true, Position = 0)]
  [ValidateSet('status', 'state', 'start', 'stop', 'poweroff', 'restart', 'resume',
    'wait-ready', 'console', 'ssh-config', 'help',
    # VirtualBox-era verbs: kept in the set so an old invocation gets an
    # explanation of what replaces it rather than a parameter error.
    'start-headless', 'ip', 'screenshot', 'run', 'net-restart', 'fix-network',
    'config-get', 'config-set', 'snapshot-take', 'snapshot-list', 'snapshot-restore')]
  [string]$Command,

  [Parameter(ValueFromRemainingArguments = $true)]
  [string[]]$Rest
)

$ErrorActionPreference = 'Stop'

# --- Constants ---------------------------------------------------------------
$VM_NAME      = 'loom-vm'               # Hyper-V VM; hard-locked
$VBOX_COPY    = 'ubuntu-24.04.4-loom'   # VirtualBox rollback copy; READ-ONLY here
$VBM          = 'C:\Program Files\Oracle\VirtualBox\VBoxManage.exe'
$GUEST_USER   = 'fahd'
$HOSTONLY_IP  = '192.168.56.10'         # guest eth1, switch 'loom-internal'
$HOST_SIDE_IP = '192.168.56.1'          # host side, 'vEthernet (loom-internal)'
$VHDX_PATH    = 'C:\Hyper-V\loom\loom-root.vhdx'
$SSH_KEY      = Join-Path $env:USERPROFILE '.ssh\loom_vm_ed25519'
$script:HyperVError = ''

# --- Retired VirtualBox-only verbs -------------------------------------------
$Retired = @{
  'start-headless'   = "Hyper-V has no GUI/headless distinction. Use: .\loom-vm.ps1 start"
  'ip'               = "Addresses are fixed: $HOSTONLY_IP on eth1 (host-only) plus a DHCP lease on eth0. Use: ssh loom-vm 'ip -br addr'"
  'screenshot'       = "Guest Additions feature. On Hyper-V open the console instead: .\loom-vm.ps1 console (elevated)"
  'run'              = "Guest Additions feature. Use ssh: ssh loom-vm '<command>'. If ssh is down: .\loom-vm.ps1 console"
  'net-restart'      = "Guest Additions feature. Use: ssh loom-vm 'sudo systemctl restart NetworkManager', or the console if ssh is down"
  'fix-network'      = "Retired: it found NICs by the VirtualBox names enp0s3/enp0s8. On Hyper-V they are eth0/eth1 and netplan matches them by MAC. Use the console if ssh is down"
  'config-get'       = "Use (elevated): Get-VM -Name $VM_NAME | Format-List *"
  'config-set'       = "Retired: change Hyper-V settings deliberately with Set-VM / Set-VMProcessor -VMName (note: -VMName, not -Name) while the VM is Off"
  'snapshot-take'    = "Use (elevated): Checkpoint-VM -Name $VM_NAME -SnapshotName <name>"
  'snapshot-list'    = "Use (elevated): Get-VMCheckpoint -VMName $VM_NAME"
  'snapshot-restore' = "Use (elevated): Restore-VMCheckpoint -VMName $VM_NAME -Name <name>"
}
if ($Retired.ContainsKey($Command)) {
  Write-Warning "'$Command' was a VirtualBox-only command and is retired since the 2026-10-18 move to Hyper-V."
  $Retired[$Command]
  exit 2
}

# --- Helpers -----------------------------------------------------------------
# Returns the Hyper-V state string, or $null with the reason in $script:HyperVError.
function Get-HyperVState {
  try {
    $vm = Get-VM -Name $VM_NAME -ErrorAction Stop
    return [string]$vm.State
  } catch {
    $script:HyperVError = $_.Exception.Message
    return $null
  }
}

function Assert-HyperVAccess {
  $s = Get-HyperVState
  if ($null -eq $s) {
    throw @"
Cannot read Hyper-V VM '$VM_NAME': $($script:HyperVError)
Lifecycle commands need an elevated PowerShell (Run as administrator), or
membership of the local 'Hyper-V Administrators' group (then sign out and in).
Read-only diagnosis that works without elevation:  .\loom-vm.ps1 status
"@
  }
  return $s
}

# State of the VirtualBox rollback copy. Read-only: this script never changes it.
# 'not-registered' is checked explicitly so the guard does not turn into a
# permanent refusal once the copy is deleted after the rollback window: an
# unregistered machine would otherwise read as 'unknown', and 'unknown' must
# fail closed.
function Get-VBoxCopyState {
  if (-not (Test-Path $VBM)) { return 'not-installed' }
  try {
    $registered = @(& $VBM list vms) -match ('^"' + [regex]::Escape($VBOX_COPY) + '"')
    if (-not $registered) { return 'not-registered' }
    $line = & $VBM showvminfo $VBOX_COPY --machinereadable | Select-String '^VMState='
  } catch {
    return 'unknown'
  }
  if (-not $line) { return 'unknown' }
  return ("$line" -replace '^VMState=', '' -replace '"', '').Trim()
}

# 'unknown' is deliberately NOT off: if the copy's state cannot be read, refuse.
function Test-VBoxCopyOff {
  $v = Get-VBoxCopyState
  return ($v -eq 'poweroff' -or $v -eq 'aborted' -or $v -eq 'not-installed' -or $v -eq 'not-registered')
}

function Assert-VBoxCopyOff {
  if (-not (Test-VBoxCopyOff)) {
    throw "Refusing: the VirtualBox copy '$VBOX_COPY' is '$(Get-VBoxCopyState)'. It has the same MACs and IPs as '$VM_NAME'; running both breaks the network for both. Power it off in VirtualBox first."
  }
}

# A TCP connect with a real timeout. Test-NetConnection takes ~20s to fail.
function Test-TcpPort {
  param([string]$TargetHost, [int]$Port, [int]$TimeoutMs = 3000)
  $client = New-Object System.Net.Sockets.TcpClient
  try {
    $ar = $client.BeginConnect($TargetHost, $Port, $null, $null)
    if (-not $ar.AsyncWaitHandle.WaitOne($TimeoutMs)) { return $false }
    $client.EndConnect($ar)
    return $true
  } catch {
    return $false
  } finally {
    $client.Close()
  }
}

function Wait-HyperVState {
  param([string]$Target, [int]$TimeoutSec = 120)
  $deadline = (Get-Date).AddSeconds($TimeoutSec)
  while ((Get-Date) -lt $deadline) {
    if ((Get-HyperVState) -eq $Target) { return $true }
    Start-Sleep -Seconds 2
  }
  return $false
}

function Start-LoomVM {
  Assert-VBoxCopyOff
  Start-VM -Name $VM_NAME
  "Started. k3s is NOT enabled at boot -- once ssh answers: ssh loom-vm 'sudo systemctl start k3s'"
  "Wait for ssh with: .\loom-vm.ps1 wait-ready"
}

# --- Commands ----------------------------------------------------------------
switch ($Command) {

  'help' {
    Get-Help $PSCommandPath -Detailed
  }

  'status' {
    "VM (Hyper-V):    $VM_NAME"
    $hv = Get-HyperVState
    if ($hv) {
      "State:           $hv"
    } else {
      "State:           unavailable from this shell -- NOT evidence about the VM; probing the guest instead"
      "                 ($($script:HyperVError))"
    }

    $vb = Get-VBoxCopyState
    if (Test-VBoxCopyOff) {
      "VirtualBox copy: $VBOX_COPY is '$vb' (must stay off)"
    } else {
      Write-Warning "VirtualBox copy '$VBOX_COPY' is '$vb'. It shares MACs and IPs with '$VM_NAME' -- power it off."
    }

    "SSH ${HOSTONLY_IP}:22:  $(Test-TcpPort $HOSTONLY_IP 22)"
    foreach ($p in 30080, 30082, 30083) {
      "Cluster :${p}:      $(Test-TcpPort $HOSTONLY_IP $p)"
    }

    $hostIp = Get-NetIPAddress -IPAddress $HOST_SIDE_IP -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($hostIp) {
      "Host side:       $HOST_SIDE_IP on '$($hostIp.InterfaceAlias)'"
    } else {
      Write-Warning "Nothing on this host holds $HOST_SIDE_IP -- the loom-internal switch address is missing."
    }
    $vbAdapters = Get-NetAdapter -ErrorAction SilentlyContinue |
      Where-Object { $_.InterfaceDescription -match 'VirtualBox Host-Only' }
    foreach ($a in $vbAdapters) {
      if ($a.Status -ne 'Disabled') {
        Write-Warning "VirtualBox host-only adapter '$($a.Name)' is $($a.Status); it also claims $HOST_SIDE_IP. Disable it (elevated): Disable-NetAdapter -Name '$($a.Name)'"
      }
    }

    # The guest can reach the Windows adb server directly only when it listens
    # on all interfaces. It does when started as 'adb -a nodaemon server'; a
    # default 'adb start-server' binds loopback only, after which the guest
    # needs the ssh reverse tunnel again.
    $adb = @(Get-NetTCPConnection -State Listen -LocalPort 5037 -ErrorAction SilentlyContinue)
    if ($adb.Count -eq 0) {
      "adb server:      not listening on :5037"
    } elseif ($adb | Where-Object { $_.LocalAddress -eq '0.0.0.0' -or $_.LocalAddress -eq '::' }) {
      "adb server:      all interfaces -- the guest can use: adb -H $HOST_SIDE_IP -P 5037 ..."
    } else {
      "adb server:      $($adb[0].LocalAddress) only -- the guest needs the reverse tunnel, or restart: adb kill-server; adb -a nodaemon server"
    }

    $drive = (Split-Path $VHDX_PATH -Qualifier).TrimEnd(':')
    $free = (Get-PSDrive -Name $drive).Free
    "Host ${drive}: free:      $([math]::Round($free / 1GB, 1)) GB  (a full volume pauses the VM as PausedCritical)"
    if (Test-Path $VHDX_PATH) {
      "VHDX:            $VHDX_PATH ($([math]::Round((Get-Item $VHDX_PATH).Length / 1GB, 1)) GB on disk)"
    } else {
      "VHDX:            $VHDX_PATH not visible from this shell (missing, or not readable without elevation)"
    }
  }

  'state' {
    Assert-HyperVAccess
  }

  'start' {
    $s = Assert-HyperVAccess
    if ($s -eq 'Running') { 'Already running.'; break }
    Start-LoomVM
  }

  'stop' {
    # Integration-services shutdown (the guest's hv_utils handles it): the
    # Hyper-V equivalent of an ACPI power button.
    $s = Assert-HyperVAccess
    if ($s -ne 'Running') { Write-Warning "VM is '$s'; nothing to stop."; break }
    Stop-VM -Name $VM_NAME -Confirm:$false
    if (Wait-HyperVState 'Off' 120) { 'Powered off.' }
    else { Write-Warning "Still not Off after 120s. Force with: .\loom-vm.ps1 poweroff" }
  }

  'poweroff' {
    # Hard power cut -- data loss risk. Only after 'stop' has failed.
    $s = Assert-HyperVAccess
    if ($s -eq 'Off') { 'Already off.'; break }
    Write-Warning "Forcing power off (unsaved guest work is lost)."
    Stop-VM -Name $VM_NAME -TurnOff -Confirm:$false
    Wait-HyperVState 'Off' 30 | Out-Null
    Get-HyperVState
  }

  'restart' {
    $s = Assert-HyperVAccess
    Assert-VBoxCopyOff
    if ($s -eq 'Running') {
      Stop-VM -Name $VM_NAME -Confirm:$false
      if (-not (Wait-HyperVState 'Off' 120)) {
        Write-Warning "Graceful shutdown timed out; forcing."
        Stop-VM -Name $VM_NAME -TurnOff -Confirm:$false
        Wait-HyperVState 'Off' 30 | Out-Null
      }
    }
    Start-LoomVM
  }

  'resume' {
    # A paused VM is running but frozen: ssh times out exactly as it does for a
    # wedged one, and the state is the only thing that tells them apart.
    $s = Assert-HyperVAccess
    if ($s -like 'Paused*') {
      if ($s -eq 'PausedCritical') {
        Write-Warning "PausedCritical means the volume holding the VHDX filled. Free space first, or it will pause again within seconds."
      }
      Resume-VM -Name $VM_NAME
      if (Wait-HyperVState 'Running' 30) { 'Resumed.' }
      else { Write-Warning 'Did not reach Running within 30s.' }
    } else {
      Write-Warning "VM is '$s', not paused. Nothing to resume."
    }
  }

  'wait-ready' {
    $timeout = 180
    if ($Rest -and $Rest[0]) { $timeout = [int]$Rest[0] }
    $deadline = (Get-Date).AddSeconds($timeout)
    while ((Get-Date) -lt $deadline) {
      if (Test-TcpPort $HOSTONLY_IP 22) { "SSH ready at $HOSTONLY_IP"; exit 0 }
      Start-Sleep -Seconds 5
    }
    Write-Warning "SSH not reachable at $HOSTONLY_IP after ${timeout}s."
    "Diagnose without ssh:  .\loom-vm.ps1 status   |   .\loom-vm.ps1 console (elevated)"
    exit 1
  }

  'console' {
    Assert-HyperVAccess | Out-Null
    & (Join-Path $env:WINDIR 'System32\vmconnect.exe') localhost $VM_NAME
  }

  'ssh-config' {
    @"
Add to $env:USERPROFILE\.ssh\config (replaces any earlier loom-vm block):

Host loom-vm
    HostName $HOSTONLY_IP
    User $GUEST_USER
    IdentityFile $SSH_KEY
    StrictHostKeyChecking accept-new
    ServerAliveInterval 30

The host-only address is static and independent of your LAN's DHCP, so it
survives router reboots, lease changes, and the VM moving networks.
"@
  }
}
