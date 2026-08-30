<#
.SYNOPSIS
  Host-side control for the Loom VirtualBox Ubuntu VM.

.DESCRIPTION
  Drives the Loom VM from the Windows host without needing SSH -- power state,
  configuration, console screenshots, and in-guest command execution via
  VirtualBox Guest Additions. Use this when SSH is unavailable (broken
  networking, VM powered off, boot hang) or when a setting requires the VM to
  be off.

  SAFETY: this script is hard-locked to the VM named in $VM_NAME. There is a
  second, unrelated VM on this host ("Ubuntu-24.04.4", another project's) that
  was once modified by mistake. Every operation validates the target name, so
  this script cannot touch it.

  In-guest execution (`run`, `net-restart`, `fix-network`) needs the guest
  login. It is read from a DPAPI-encrypted credential file that is tied to
  your Windows account -- the password is never passed on a command line
  (VBoxManage --passwordfile is used) and never appears in any log.

  Create it once:
    Get-Credential -UserName fahd -Message "Loom VM guest login" |
      Export-Clixml "$env:USERPROFILE\.loom-vm-cred.xml"

.EXAMPLE
  .\loom-vm.ps1 status
  .\loom-vm.ps1 start
  .\loom-vm.ps1 screenshot
  .\loom-vm.ps1 run "df -h /"
  .\loom-vm.ps1 fix-network
  .\loom-vm.ps1 config-set --nested-hw-virt on
#>
[CmdletBinding()]
param(
  [Parameter(Mandatory = $true, Position = 0)]
  [ValidateSet('status', 'start', 'start-headless', 'resume', 'stop', 'poweroff', 'restart',
    'ip', 'screenshot', 'run', 'net-restart', 'fix-network', 'wait-ready',
    'config-get', 'config-set', 'snapshot-take', 'snapshot-list',
    'snapshot-restore', 'ssh-config', 'help')]
  [string]$Command,

  [Parameter(ValueFromRemainingArguments = $true)]
  [string[]]$Rest
)

$ErrorActionPreference = 'Stop'

# --- Constants ---------------------------------------------------------------
$VM_NAME       = 'ubuntu-24.04.4-loom'   # hard-locked; see SAFETY above
$VBM           = 'C:\Program Files\Oracle\VirtualBox\VBoxManage.exe'
$CRED_PATH     = Join-Path $env:USERPROFILE '.loom-vm-cred.xml'
$GUEST_USER    = 'fahd'
$HOSTONLY_IP   = '192.168.56.10'         # static, outside the host-only DHCP pool
$HOSTONLY_CIDR = '192.168.56.10/24'
$SSH_KEY       = Join-Path $env:USERPROFILE '.ssh\loom_vm_ed25519'

if (-not (Test-Path $VBM)) { throw "VBoxManage not found at $VBM" }

# --- Helpers -----------------------------------------------------------------
function Get-VMState {
  $line = & $VBM showvminfo $VM_NAME --machinereadable 2>$null | Select-String '^VMState='
  if (-not $line) { return 'unknown' }
  return ($line -replace '^VMState=', '' -replace '"', '').Trim()
}

function Assert-Running {
  $s = Get-VMState
  if ($s -ne 'running') { throw "VM '$VM_NAME' is '$s', not running. Start it first: .\loom-vm.ps1 start" }
}

function Assert-PoweredOff {
  $s = Get-VMState
  if ($s -ne 'poweroff' -and $s -ne 'aborted' -and $s -ne 'saved') {
    throw "VM '$VM_NAME' is '$s'. This operation needs it powered off. Run: .\loom-vm.ps1 stop"
  }
}

function Get-GuestIPs {
  $props = & $VBM guestproperty enumerate $VM_NAME 2>$null
  $ips = @()
  foreach ($p in $props) {
    if ($p -match '/VirtualBox/GuestInfo/Net/(\d+)/V4/IP\s+=\s+''([^'']+)''') {
      $ips += [pscustomobject]@{ Index = [int]$Matches[1]; IP = $Matches[2] }
    }
  }
  return $ips | Sort-Object Index
}

function Get-GuestCred {
  if (-not (Test-Path $CRED_PATH)) {
    throw @"
Guest credential file not found: $CRED_PATH
Create it once (you will be prompted for the VM password for user '$GUEST_USER'):

  Get-Credential -UserName $GUEST_USER -Message "Loom VM guest login" |
    Export-Clixml "$CRED_PATH"
"@
  }
  return Import-Clixml $CRED_PATH
}

# Runs a shell command inside the guest via Guest Additions. Needs no network.
# The password goes to a temp file (VBoxManage --passwordfile), never argv --
# argv is visible to any process listing on the host.
function Invoke-GuestCommand {
  param([Parameter(Mandatory = $true)][string]$Script)

  Assert-Running
  $cred = Get-GuestCred
  $pwFile = [System.IO.Path]::GetTempFileName()
  try {
    $plain = $cred.GetNetworkCredential().Password
    [System.IO.File]::WriteAllText($pwFile, $plain)
    # Guest output goes to the host console via Write-Host so that callers can
    # discard this function's return value without also swallowing the output.
    & $VBM guestcontrol $VM_NAME run `
      --username $cred.UserName --passwordfile $pwFile `
      --wait-stdout --wait-stderr `
      -- /bin/bash -c $Script 2>&1 | ForEach-Object { Write-Host $_ }
    $code = $LASTEXITCODE
    if ($code -ne 0) { Write-Warning "guest command exited $code" }
    return $code
  } finally {
    if (Test-Path $pwFile) { Remove-Item $pwFile -Force -ErrorAction SilentlyContinue }
  }
}

# VirtualBox reports VMState=poweroff a moment BEFORE it releases the machine's
# session lock, so a modifyvm/startvm issued immediately after a shutdown fails
# with "already locked for a session". There is no lock field in
# `showvminfo --machinereadable` to poll, so retry the operation itself.
function Invoke-VBoxRetry {
  param([string[]]$VBoxArgs, [int]$Attempts = 12, [int]$DelaySec = 3)
  for ($i = 1; $i -le $Attempts; $i++) {
    $out = & $VBM @VBoxArgs 2>&1
    if ($LASTEXITCODE -eq 0) {
      $out | ForEach-Object { Write-Host $_ }
      return
    }
    if ("$out" -match 'locked for a session|locked by a session|being (un)?locked') {
      Start-Sleep -Seconds $DelaySec
      continue
    }
    $out | ForEach-Object { Write-Host $_ }
    throw "VBoxManage failed: $($VBoxArgs -join ' ')"
  }
  throw "VBoxManage still session-locked after $Attempts attempts: $($VBoxArgs -join ' ')"
}

function Wait-ForState {
  param([string]$Target, [int]$TimeoutSec = 120)
  $deadline = (Get-Date).AddSeconds($TimeoutSec)
  while ((Get-Date) -lt $deadline) {
    if ((Get-VMState) -eq $Target) { return $true }
    Start-Sleep -Seconds 2
  }
  return $false
}

function Test-SSH {
  param([string]$TargetIP, [int]$TimeoutSec = 5)
  $r = Test-NetConnection -ComputerName $TargetIP -Port 22 -WarningAction SilentlyContinue
  return $r.TcpTestSucceeded
}

# --- Commands ----------------------------------------------------------------
switch ($Command) {

  'help' {
    Get-Help $PSCommandPath -Detailed
  }

  'status' {
    $state = Get-VMState
    "VM:     $VM_NAME"
    "State:  $state"
    if ($state -eq 'running') {
      $ips = Get-GuestIPs
      if ($ips) {
        foreach ($i in $ips) { "IP[$($i.Index)]: $($i.IP)" }
      } else {
        "IP:     (none reported -- guest has no IPv4 address; try: .\loom-vm.ps1 fix-network)"
      }
      $ga = & $VBM guestproperty get $VM_NAME '/VirtualBox/GuestAdd/Version' 2>$null
      "GuestAdd: $($ga -replace '^Value: ', '')"
      "SSH ${HOSTONLY_IP}:22 reachable: $(Test-SSH $HOSTONLY_IP)"
    }
    "Cred file: $(if (Test-Path $CRED_PATH) { 'present' } else { 'MISSING -- see .\loom-vm.ps1 help' })"
  }

  'start'          { Invoke-VBoxRetry @('startvm', $VM_NAME, '--type', 'gui') }
  'start-headless' { Invoke-VBoxRetry @('startvm', $VM_NAME, '--type', 'headless') }

  'resume' {
    # A paused VM is running but frozen: ssh times out exactly as it does for a
    # wedged one, and 'status' is the only thing that tells them apart. Added
    # 2026-08-28, when a paused VM had no recovery path through this script --
    # the only sanctioned way to touch it -- so the alternative was a power
    # cycle that would have destroyed another session's in-flight work.
    $info = & $VBM showvminfo $VM_NAME --machinereadable
    if ($info -match 'VMState="paused"') {
      & $VBM controlvm $VM_NAME resume
      if (Wait-ForState 'running' 30) { 'Resumed.' }
      else { Write-Warning 'Did not reach running within 30s.' }
    } else {
      Write-Warning 'VM is not paused. Nothing to resume; check status.'
    }
  }

  'stop' {
    # Graceful ACPI shutdown. Does not need guest credentials.
    Assert-Running
    & $VBM controlvm $VM_NAME acpipowerbutton
    "Sent ACPI shutdown; waiting up to 120s..."
    if (Wait-ForState 'poweroff' 120) { "Powered off." }
    else { Write-Warning "Still not off after 120s. Force with: .\loom-vm.ps1 poweroff" }
  }

  'poweroff' {
    # Hard power cut -- data loss risk. Only after 'stop' has failed.
    Assert-Running
    Write-Warning "Forcing power off (unsaved guest work is lost)."
    & $VBM controlvm $VM_NAME poweroff
    Wait-ForState 'poweroff' 30 | Out-Null
    Get-VMState
  }

  'restart' {
    if ((Get-VMState) -eq 'running') {
      & $VBM controlvm $VM_NAME acpipowerbutton
      if (-not (Wait-ForState 'poweroff' 120)) {
        Write-Warning "Graceful shutdown timed out; forcing."
        & $VBM controlvm $VM_NAME poweroff
        Wait-ForState 'poweroff' 30 | Out-Null
      }
    }
    Start-Sleep -Seconds 2
    Invoke-VBoxRetry @('startvm', $VM_NAME, '--type', 'gui')
  }

  'ip' {
    Assert-Running
    $ips = Get-GuestIPs
    if ($ips) { $ips | ForEach-Object { "$($_.IP)" } }
    else { "(no IPv4 reported)"; exit 1 }
  }

  'screenshot' {
    # Works with no network and no credentials -- the way to see a boot hang.
    Assert-Running
    $out = if ($Rest -and $Rest[0]) { $Rest[0] } else { Join-Path $env:TEMP 'loom_vm_screen.png' }
    & $VBM controlvm $VM_NAME screenshotpng $out
    "Saved: $out"
  }

  'run' {
    if (-not $Rest) { throw 'usage: .\loom-vm.ps1 run "<shell command>"' }
    Invoke-GuestCommand ($Rest -join ' ') | Out-Null
  }

  'net-restart' {
    # The common case: link is up but DHCPv4 never completed.
    Invoke-GuestCommand @'
set -x
sudo nmcli networking off || true
sleep 2
sudo nmcli networking on || true
sleep 5
sudo systemctl restart NetworkManager || true
sleep 5
ip -4 addr show
ip route show default
'@ | Out-Null
  }

  'fix-network' {
    # Idempotent: ensure the host-only NIC has its static address and the
    # bridged NIC is actively trying DHCP. Safe to re-run.
    Invoke-GuestCommand @"
set -e
echo '--- interfaces ---'
ip -br link
echo '--- ensuring host-only static address ---'
HOSTONLY_DEV="`$(ls /sys/class/net | grep -E '^en' | sed -n 2p)"
if [ -n "`$HOSTONLY_DEV" ]; then
  sudo nmcli con add type ethernet ifname "`$HOSTONLY_DEV" con-name loom-hostonly \
    ip4 $HOSTONLY_CIDR 2>/dev/null || sudo nmcli con mod loom-hostonly ip4 $HOSTONLY_CIDR
  sudo nmcli con up loom-hostonly || true
else
  echo 'No second interface found -- host-only NIC not attached yet.'
fi
echo '--- renewing bridged DHCP ---'
BRIDGED_DEV="`$(ls /sys/class/net | grep -E '^en' | sed -n 1p)"
sudo nmcli device reapply "`$BRIDGED_DEV" 2>/dev/null || sudo dhclient -v "`$BRIDGED_DEV" || true
echo '--- result ---'
ip -4 addr show
"@ | Out-Null
  }

  'wait-ready' {
    $timeout = 180
    if ($Rest -and $Rest[0]) { $timeout = [int]$Rest[0] }
    $deadline = (Get-Date).AddSeconds($timeout)
    while ((Get-Date) -lt $deadline) {
      if (Test-SSH $HOSTONLY_IP 3) { "SSH ready at $HOSTONLY_IP"; exit 0 }
      Start-Sleep -Seconds 5
    }
    Write-Warning "SSH not reachable at $HOSTONLY_IP after ${timeout}s."
    "Diagnose without SSH:  .\loom-vm.ps1 screenshot   |   .\loom-vm.ps1 status"
    exit 1
  }

  'config-get' {
    $filter = if ($Rest -and $Rest[0]) { $Rest[0] } else { '.' }
    & $VBM showvminfo $VM_NAME --machinereadable | Select-String $filter
  }

  'config-set' {
    # e.g. .\loom-vm.ps1 config-set --nested-hw-virt on
    if (-not $Rest) { throw 'usage: .\loom-vm.ps1 config-set --<setting> <value> [...]' }
    Assert-PoweredOff
    Invoke-VBoxRetry (@('modifyvm', $VM_NAME) + $Rest)
    "Applied: modifyvm $VM_NAME $($Rest -join ' ')"
  }

  'snapshot-take' {
    $name = if ($Rest -and $Rest[0]) { $Rest[0] } else { "auto-$(Get-Date -Format yyyyMMdd-HHmmss)" }
    & $VBM snapshot $VM_NAME take $name --live
    "Snapshot taken: $name"
  }

  'snapshot-list' { & $VBM snapshot $VM_NAME list }

  'snapshot-restore' {
    if (-not $Rest) { throw 'usage: .\loom-vm.ps1 snapshot-restore <name>' }
    Assert-PoweredOff
    & $VBM snapshot $VM_NAME restore $Rest[0]
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

