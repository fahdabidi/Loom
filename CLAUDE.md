# Loom — working rules

## Infrastructure is recoverable; recover it and keep going

**Never stop work because the Loom VM is unreachable.** Symptoms: ssh times out during banner
exchange, `VBoxManage guestcontrol` refuses a session ("current status is: starting"), console
screenshot blank. The VM can still report `running` while sshd cannot complete a handshake —
that is resource exhaustion, not a decision point.

Recover it:

    docs/Build Plan V2/Tools/code/loom-vm.ps1 stop        # ACPI; may time out
    docs/Build Plan V2/Tools/code/loom-vm.ps1 poweroff    # if stop times out
    docs/Build Plan V2/Tools/code/loom-vm.ps1 start

Then wait for ssh, re-arm the loop (`enabled=1`, push `expires_at` forward in
`data/loops/v4final.loop`), and continue. Always go through `loom-vm.ps1` — it is hard-locked
to `ubuntu-24.04.4-loom`, which prevents targeting the unrelated `Ubuntu-24.04.4` VM.

Rebooting a dev VM whose emulator is wedged is routine maintenance. Do not wait for a human.

## The Android emulator belongs on Windows, not in the VM

Windows has **WHPX** hardware acceleration (`emulator -accel-check` reports "WHPX is installed
and usable"), because the host hypervisor is enabled. That same hypervisor is why the VM cannot
have KVM. Measured 2026-08-24: **72 seconds to boot on Windows** versus 10–20 minutes in the VM,
which also failed four times in one day.

Windows SDK lives at `C:\Android\Sdk` (JDK at `C:\Android\jdk`), AVD `loom_win`, configured
1080x2400 to match the VM's `loom_demo`.

An idle KVM-less emulator costs ~70% CPU on the VM and roughly quadruples Flutter suite times —
a suite TIMEOUT under that load is environmental. Re-run the single test in isolation before
calling it a regression. A failed `expect` is a different matter.

## Evidence rules

- `*.png` is gitignored: screenshots are transient. **Only a committed manifest is durable.** A
  capture run that does not commit its manifest has proven nothing.
- Never match product vocabulary by substring. `"Not attending"` contains `attend`;
  `"Join waitlist"` contains `wait`. Match on word boundaries, and never let a span claimed by an
  ALTERNATE term also count as a PRIMARY one.
- Process checks lie in both directions: `pgrep -c qemu-system-x86_64` returns 0 when it IS
  running (15-char `comm` truncation), and `pgrep -fc` returns 1 when nothing is (it matches its
  own command line). Use `adb devices` plus a bracketed `pgrep -fc '[q]emu...'`.

## Instrument the silence before theorising about it

Five explanations for one walkthrough stall were wrong, each reasoned from a symptom — a
screenshot, a process state, an agent's illustrative example. The cause only surfaced after the
run was made to report what it was waiting for. **Treat only text a system emitted about itself
as evidence**; example output inside an agent's report is prose, not telemetry.

## Standing constraints

- Community JSON is authored only by the Skill. Copy/relocate is allowed; hand-editing is not.
- The product doc is upstream of the JSON: the Skill designs the doc, then derives the package.
- Application code changes go through `data/call_implementation_agent.sh`.
- UX judging runs on Claude Sonnet (`data/call_ux_judge_agent.sh`) and live walkthroughs on
  Claude Opus (`data/call_live_verification_agent.sh`) — the DeepSeek gateway is text-only and
  refuses images, which a UX judge fundamentally needs.
