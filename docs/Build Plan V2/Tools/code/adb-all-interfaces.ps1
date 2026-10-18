<#
.SYNOPSIS
  Ensure the Windows adb server listens on all interfaces, so the Loom VM can reach the
  emulator directly with `adb -H 192.168.56.1 -P 5037`.

.DESCRIPTION
  Written 2026-10-18 after the Loom VM moved to Hyper-V. The guest reaches the Windows adb
  server directly only while that server was started with `-a` (listen on all interfaces).
  A default `adb start-server` -- which any adb command runs if no server is up -- binds
  127.0.0.1 only, and after a reboot nothing restarted it with `-a`. This script is run at
  logon from the user's Startup folder to close that gap, and is safe to run by hand at any
  time: it is idempotent.

    already listening on 0.0.0.0:5037  -> does nothing
    listening on loopback only         -> adb kill-server, then restarts with -a
    not listening                      -> starts with -a

  SECURITY: listening on all interfaces would expose the emulator to the whole LAN. The
  four inbound 'adb' firewall rules were scoped on 2026-10-18 to RemoteAddress
  192.168.56.0/24 (the VM's host-only network) for exactly that reason. This script REFUSES
  to start an all-interfaces server while any enabled inbound 'adb' allow rule admits remote
  address 'Any' -- so it cannot silently re-open the LAN exposure if the rules are reset
  (adb.exe updates can re-create them on the firewall prompt).

  Restarting the server drops current adb clients for a moment; the emulator re-registers on
  its own. Do not run it in the middle of a capture.

  The authoritative copy is tracked at docs/Build Plan V2/Tools/code/adb-all-interfaces.ps1.
  The Startup-folder shortcut runs a LOCAL copy (%LOCALAPPDATA%\Loom\adb-all-interfaces.ps1),
  because the repo lives under OneDrive and a cloud-only placeholder may not be readable at
  logon. Re-copy it after editing.
#>
$ErrorActionPreference = 'Stop'
$adb = 'C:\Android\Sdk\platform-tools\adb.exe'
$logDir = Join-Path $env:LOCALAPPDATA 'Loom'
$log = Join-Path $logDir 'adb-all-interfaces.log'
New-Item -ItemType Directory -Force -Path $logDir | Out-Null

function Write-Log([string]$msg) {
  $line = '{0:yyyy-MM-dd HH:mm:ss} {1}' -f (Get-Date), $msg
  Add-Content -Path $log -Value $line
  $line
}

function Get-AdbListeners {
  @(Get-NetTCPConnection -State Listen -LocalPort 5037 -ErrorAction SilentlyContinue)
}

# Exit codes: 0 all-interfaces server running; 2 started but never listened; 3 refused
# (firewall would expose the LAN); 4 adb not found. 1 means an unhandled error.
if (-not (Test-Path $adb)) { Write-Log "adb not found at $adb -- nothing to do"; exit 4 }

# Refuse to expose the emulator to the LAN. (-DisplayName cannot be combined with
# -Direction/-Action/-Enabled in one Get-NetFirewallRule call, hence the Where-Object.)
$open = Get-NetFirewallRule -DisplayName adb -ErrorAction SilentlyContinue |
  Where-Object { "$($_.Direction)" -eq 'Inbound' -and "$($_.Action)" -eq 'Allow' -and "$($_.Enabled)" -eq 'True' } |
  Where-Object { ($_ | Get-NetFirewallAddressFilter).RemoteAddress -contains 'Any' }
if ($open) {
  Write-Log "REFUSING: $(@($open).Count) inbound 'adb' allow rule(s) admit remote address Any, so an all-interfaces server would expose the emulator to the LAN. Scope them first (elevated): Get-NetFirewallRule -DisplayName adb | Set-NetFirewallRule -RemoteAddress 192.168.56.0/24"
  exit 3
}

$l = @(Get-AdbListeners)   # @() at the CALL SITE: a function returning one CimInstance unrolls it, and CimInstance.Count is empty in PS 5.1
if ($l | Where-Object { $_.LocalAddress -eq '0.0.0.0' -or $_.LocalAddress -eq '::' }) {
  Write-Log 'adb already listens on all interfaces -- nothing to do'
  exit 0
}
if ($l.Count -gt 0) {
  Write-Log "adb listens on $($l[0].LocalAddress) only -- restarting it with -a"
  & $adb kill-server 2>&1 | Out-Null
  for ($i = 0; $i -lt 20 -and @(Get-AdbListeners).Count -gt 0; $i++) { Start-Sleep -Milliseconds 250 }
}

Start-Process -FilePath $adb -ArgumentList '-a', 'nodaemon', 'server' -WindowStyle Hidden
for ($i = 0; $i -lt 40; $i++) {
  Start-Sleep -Milliseconds 250
  if (Get-AdbListeners | Where-Object { $_.LocalAddress -eq '0.0.0.0' -or $_.LocalAddress -eq '::' }) {
    Write-Log 'adb now listens on all interfaces'
    exit 0
  }
}
Write-Log 'FAILED: started adb -a nodaemon server but nothing listens on 0.0.0.0:5037 after 10s'
exit 2
