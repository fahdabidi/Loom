#!/bin/bash
# docs/Build Plan V2/Tools/code/recover_loom_vm.sh
#
# ONE script that recovers every service this project depends on, after ANY
# kind of disruption -- a VM reboot, a host sleep/resume, a k3s crash, or the
# DeepSeek gateway dying with no other symptom at all. Written 2026-09-11 after
# an 8-hour dispatch stall traced back to exactly this: the VM had rebooted,
# k3s (disabled in systemd) never came back, and nothing said so until a
# Postgres-dependent dispatch burned 121k tokens failing to connect.
#
# ============================================================================
# READ THIS FIRST -- there are TWO layers, and this script is only the inner one
# ============================================================================
# Layer 1: is the VM itself reachable at all? That is a WINDOWS-side question,
#          answered with docs/Build Plan V2/Tools/code/loom-vm.ps1, NOT this
#          script (this script runs ON the VM and can't help you if the VM
#          can't be reached in the first place).
# Layer 2: given the VM is reachable, are the SERVICES inside it healthy? That
#          is what this script does. Run it FROM the VM:
#
#            ssh loom-vm 'bash ~/Loom/"docs/Build Plan V2/Tools/code/recover_loom_vm.sh" [stage...]'
#
# Do Layer 1 first if ssh itself is failing. Jumping straight to "just run the
# recovery script" when the VM can't be reached is how a real wedge gets
# mistaken for "the script must be broken."
#
# ----------------------------------------------------------------------------
# LAYER 1 IN DETAIL (Windows side, PowerShell, loom-vm.ps1) -- do this FIRST
# ----------------------------------------------------------------------------
#   docs/Build Plan V2/Tools/code/loom-vm.ps1 status
#
# Read the result before touching anything else:
#
#   * status = "running", ssh connects fine
#       -> the VM is fine. Go straight to Layer 2 (this script) below.
#
#   * status = "paused"
#       -> THE HOST DISK IS FULL (the D:\ drive holding the VDI). VirtualBox
#          pauses a guest whose backing store cannot grow. This looks exactly
#          like a wedged VM over ssh -- both time out identically -- but
#          power-cycling will NOT fix it; the guest will write a little and
#          pause again within seconds. Free D:\ space FIRST:
#            - archive files anywhere on D: (*.zip *.rar *.7z *.tar *.gz *.xz)
#            - D:\Users\<you>\Downloads
#            - D:\Users\<you>\OneDrive -- an ORPHANED copy from an old
#              install; verify OneDrive's real sync root in the registry
#              before deleting (see CLAUDE.md "Disk hygiene") -- if that ever
#              points at D:, deleting there propagates to the cloud.
#            - the D: recycle bin (Clear-RecycleBin -DriveLetter D -Force)
#          THEN, only once D: has real headroom:
#            docs/Build Plan V2/Tools/code/loom-vm.ps1 stop       # ACPI, may time out
#            docs/Build Plan V2/Tools/code/loom-vm.ps1 poweroff   # if stop times out
#            docs/Build Plan V2/Tools/code/loom-vm.ps1 start
#
#   * status = "running", but ssh times out mid-handshake and stays that way
#       -> this is RESOURCE EXHAUSTION (a build or a dispatch running all five
#          suites pegged all 8 cores), not a wedge, and the two look identical
#          from outside. Confirmed 2026-09-08: rebooting a VM that was merely
#          loaded would have destroyed a dispatch with 8 modified files and no
#          record of what it had finished. It finished fine on its own.
#          Do NOT power-cycle. Arm ONE waiter with `ssh -o ServerAliveInterval=30`
#          and stop polling -- every extra probe adds load to the exact box
#          you are trying to measure, and under saturation the probes time out
#          anyway, so they cost something and return nothing.
#
#   * genuinely wedged (status="running" but Guest Additions unresponsive,
#     TCP port refusing even after minutes, no build/dispatch could plausibly
#     be running)
#       -> docs/Build Plan V2/Tools/code/loom-vm.ps1 stop / poweroff / start,
#          same as the disk-full case above (skip the disk cleanup -- that
#          part was disk-specific).
#
# Always go through loom-vm.ps1, never raw VBoxManage -- it is hard-locked to
# `ubuntu-24.04.4-loom`, which is the only thing preventing an easy mistake of
# power-cycling the OTHER, unrelated `Ubuntu-24.04.4` VM on the same host.
#
# ============================================================================
# USAGE (Layer 2, this script, run ON the VM)
# ============================================================================
#   ssh loom-vm 'bash ~/Loom/"docs/Build Plan V2/Tools/code/recover_loom_vm.sh" [stage...]'
#
# With NO arguments, runs every stage below, in order, and prints a final
# pass/fail summary. Pass one or more stage names to run only those -- do this
# whenever you already know only ONE thing is broken, which is the common
# case (e.g. the gateway died with no other symptom at all -- see STAGE 4 --
# and k3s was never touched):
#
#   all         (default) every stage below, in order
#   k3s         STAGE 1 -- start k3s if it's not active, wait for all pods 1/1
#   postgres    STAGE 2 -- (re)establish the port-forward to 127.0.0.1:15432
#   verify      STAGE 3 -- prove the stack actually SERVES real requests,
#                          not just that pods report Running
#   validator   STAGE 4 -- restart the community-package validator on :8787
#                          if it's down OR running grammar older than the
#                          last relevant change (reports both timestamps;
#                          the "is it stale" call is still yours to make)
#   gateway     STAGE 5 -- restart the DeepSeek gateway if it's down or
#                          running with the wrong thinking-mode setting
#   orphans     STAGE 6 -- sweep for known-stale waiter/dispatch processes
#                          on THIS machine (the VM). Windows-side orphans
#                          need PowerShell and are NOT covered here -- see
#                          the bottom of this header.
#
# Examples:
#   ssh loom-vm 'bash ~/Loom/"docs/Build Plan V2/Tools/code/recover_loom_vm.sh"'                    # full recovery
#   ssh loom-vm 'bash ~/Loom/"docs/Build Plan V2/Tools/code/recover_loom_vm.sh" gateway'             # just the gateway
#   ssh loom-vm 'bash ~/Loom/"docs/Build Plan V2/Tools/code/recover_loom_vm.sh" k3s postgres verify' # backend only
#
# Every stage is IDEMPOTENT and safe to re-run: each one checks current state
# first and only acts if something is actually wrong. Running `all` on an
# already-healthy stack is a normal way to double-check before a heavy
# dispatch, not just a repair tool.
#
# ============================================================================
# WHY EACH STAGE EXISTS -- read once per stage, then trust the script
# ============================================================================
#
# STAGE 1 (k3s). k3s is `disabled` in systemd on this VM, so it does NOT come
# back on its own after any VM restart -- confirmed 2026-09-11 after a VM
# reboot (uptime showed the gap) left k3s `inactive (dead)` for hours with
# nothing surfacing it, during which a real dispatch failed trying to reach
# Postgres. `kubectl get pods -n loom` genuinely hangs/refuses while the API
# server (port 6443) is down, which is itself the tell -- don't mistake that
# for "the cluster is fine, just slow."
#
# STAGE 2 (postgres). Nothing auto-forwards 15432. Every workflow-service AND
# app-access test that needs real Postgres silently SKIPS without it (the
# Dart suites) or fails with `Connection refused` after burning a full
# dispatch's token budget trying to figure out why (this is exactly what cost
# 121k tokens on 2026-09-11 -- the dispatching session, not the dispatched
# agent, is responsible for having this running first).
#
# STAGE 3 (verify). A pod reporting `1/1 Running` proves the container is up,
# not that the service inside it answers correctly -- CLAUDE.md's whole
# "verification traps" section exists because of this gap. This stage runs a
# REAL psql query and hits a REAL HTTP health endpoint rather than trusting
# `kubectl get pods`.
#
# STAGE 4 (validator). The validator server on :8787 answers happily forever
# on whatever grammar was loaded when it started -- it does not restart
# itself when the validator, engine models, or grammar change. Confirmed
# 2026-08-29: a server up since the day before rejected a brand-new key as
# `unknown_key`; restarting it against the SAME file passed clean. This stage
# cannot fully automate "should I restart it" (that needs knowing what you
# just changed), but it prints the server's start time next to the latest
# relevant commit so the comparison is a 5-second glance instead of a hunt.
#
# STAGE 5 (gateway). Two independent failure modes, both real: (a) the
# gateway is simply not running (VM reboot -- nothing auto-starts it either),
# and (b) it dies mid-session with ZERO trace -- no OOM in dmesg, no error in
# its own log, just stops logging requests and the port goes to
# `connection refused` (observed live, 2026-09-11, no root cause found). This
# stage does not try to explain (b); it just checks health, and if it's down,
# resolves the exact pid bound to 8791 (never a pattern-kill), confirms it
# really is the gateway's node process, kills only that, and restarts via the
# canonical `start.sh`. It ALSO explicitly re-checks the `thinking` field in
# `/health` after restart -- DEEPSEEK_THINKING must be `disabled`, never
# `enabled`. That setting is not cosmetic: with it enabled, DeepSeek's own API
# rejects any tool-call turn whose reasoning wasn't substantial, discarding
# the whole in-flight ticket (confirmed live the same day, two real ticket
# dispatches lost to exactly this before the setting was corrected). If you
# ever touch ~/deepseek-gateway/.env by hand, re-run this stage afterward --
# a stale value there is invisible until a real dispatch dies on it.
#
# STAGE 6 (orphans, VM side only). A dispatch's own wrapper script writes its
# pid to .last_dispatch.pid, and a completion-watcher (or an ad-hoc `until
# grep ...` loop) can be left running past real completion if its match logic
# has a gap -- this happened twice on 2026-09-11 alone, in OPPOSITE
# directions: once from trusting an embedded sentinel string mid-transcript
# (fixed in watch_dispatch_log.sh, see its own header), and once from an
# ad-hoc waiter checking ONLY the log's last line, which missed the real exit
# line because the wrapper prints several more lines of git-status output
# after it -- that one hung silently for 8 hours. This stage sweeps for
# processes matching known-stale shapes and reports them; it does NOT
# auto-kill anything without listing full command lines first, per the
# standing "never kill by pattern, resolve the pid, confirm identity" rule.
#
# WINDOWS-SIDE ORPHANS (not covered by this script -- PowerShell, not bash):
# stale ssh.exe / bash.exe waiter processes and duplicate CronList jobs from
# this project's own `/loop` cycles live on the WINDOWS side and need
# PowerShell (`Get-CimInstance Win32_Process`) plus `CronList` from the
# Claude session itself, not anything reachable from inside the VM. See the
# 2026-09-11 cleanup in this project's own session history for the exact
# commands if this needs doing again: resolve each pid's FULL command line
# first (a dispatch's command line can legitimately contain long ticket text
# or grep patterns that make `pgrep`-style substring matching lie in both
# directions), confirm it's genuinely stale (missing target file, dead
# parent, or CPU time that could only come from days of idle looping), only
# then `Stop-Process -Id <exact pid> -Force`.
#
# ============================================================================

set -uo pipefail

# Resolve via git rather than a fixed "../../../.." climb: this script is
# mirrored at TWO paths by this project's own convention (data/ and
# docs/Build Plan V2/Tools/code/), each a different depth from the repo
# root, so a fixed climb is only ever correct from one of them. Found by
# actually running it from data/ on the VM 2026-09-11: `cd //app` failed
# silently different from what a fixed climb would have hidden.
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && git rev-parse --show-toplevel)"
[ -f "$HOME/.loom-env.sh" ] && . "$HOME/.loom-env.sh"

STAGES=("$@")
[ ${#STAGES[@]} -eq 0 ] && STAGES=("all")
run_stage() {
  local name="$1"
  for s in "${STAGES[@]}"; do
    [ "$s" = "all" ] && return 0
    [ "$s" = "$name" ] && return 0
  done
  return 1
}

# Bounded wait helper: polls a check command every $2 seconds for up to $1
# seconds total. Never loops forever -- every stage that waits for something
# uses this, so a genuinely stuck condition reports "gave up" instead of
# hanging the whole script (or the session watching it) indefinitely.
wait_for() {
  local timeout_s="$1" interval_s="$2" desc="$3"; shift 3
  local waited=0
  while ! "$@" >/dev/null 2>&1; do
    if [ "$waited" -ge "$timeout_s" ]; then
      echo "  TIMED OUT after ${timeout_s}s waiting for: $desc"
      return 1
    fi
    sleep "$interval_s"
    waited=$((waited + interval_s))
  done
  return 0
}

OVERALL_STATUS=0
mark_fail() { OVERALL_STATUS=1; }

echo "===================================================================="
echo "recover_loom_vm.sh -- stages requested: ${STAGES[*]}"
echo "$(date -Is)"
echo "===================================================================="

# ----------------------------------------------------------------------------
# STAGE 1 -- k3s
# ----------------------------------------------------------------------------
if run_stage k3s; then
  echo; echo "--- STAGE 1: k3s ---"
  if systemctl is-active --quiet k3s; then
    echo "  k3s already active."
  else
    echo "  k3s is NOT active (this is expected after any VM restart -- it is"
    echo "  disabled in systemd and never comes back on its own). Starting it."
    if sudo systemctl start k3s; then
      echo "  systemctl start k3s: OK"
    else
      echo "  systemctl start k3s: FAILED"
      mark_fail
    fi
  fi

  echo "  Waiting for all pods in the loom namespace to reach 1/1 (up to 180s;"
  echo "  readiness probes take a couple of minutes after a cold start)..."
  pods_all_ready() {
    local out ready total
    out="$(kubectl get pods -n loom --no-headers 2>/dev/null)" || return 1
    total="$(echo "$out" | grep -c .)"
    [ "$total" -gt 0 ] || return 1
    ready="$(echo "$out" | awk '{split($2,a,"/"); if (a[1]==a[2] && a[1]!=0) c++} END{print c+0}')"
    [ "$ready" = "$total" ]
  }
  if wait_for 180 5 "all loom pods 1/1" pods_all_ready; then
    echo "  All pods 1/1:"
    kubectl get pods -n loom --no-headers | sed 's/^/    /'
  else
    echo "  Current pod state (NOT all healthy):"
    kubectl get pods -n loom --no-headers 2>/dev/null | sed 's/^/    /'
    mark_fail
  fi
fi

# ----------------------------------------------------------------------------
# STAGE 2 -- postgres port-forward
# ----------------------------------------------------------------------------
if run_stage postgres; then
  echo; echo "--- STAGE 2: postgres port-forward (127.0.0.1:15432) ---"
  if ss -ltn 2>/dev/null | grep -q ':15432 '; then
    echo "  Port 15432 already forwarded."
  else
    echo "  Starting: kubectl port-forward -n loom svc/postgres 15432:5432"
    setsid nohup kubectl port-forward -n loom svc/postgres 15432:5432 \
      > "$REPO_ROOT/.codex-logs/recover_pf_postgres.log" 2>&1 < /dev/null &
    disown
    if wait_for 15 1 "port 15432 listening" bash -c "ss -ltn 2>/dev/null | grep -q ':15432 '"; then
      echo "  Port-forward OK."
    else
      echo "  Port-forward FAILED to come up -- check .codex-logs/recover_pf_postgres.log"
      cat "$REPO_ROOT/.codex-logs/recover_pf_postgres.log" 2>/dev/null | sed 's/^/    /'
      mark_fail
    fi
  fi
  echo "  Credentials, for reference (two DIFFERENT env-var conventions in"
  echo "  this repo -- do not mix them up):"
  echo "    Dart suites (workflow-service, workflow-engine) want:"
  echo "      LOOM_POSTGRES_HOST=127.0.0.1 LOOM_POSTGRES_PORT=15432"
  echo "      LOOM_POSTGRES_DATABASE=<db> LOOM_POSTGRES_USERNAME=loom"
  echo "      LOOM_POSTGRES_PASSWORD=<from postgres-credentials secret>"
  echo "      (+ LOOM_POSTGRES_APP_USERNAME/APP_PASSWORD from"
  echo "       postgres-workflow-app-credentials for the RLS-restricted tests --"
  echo "       omitting these silently SKIPS the one test that matters, see"
  echo "       CLAUDE.md \"the workflow service needs TWO credential sets\")"
  echo "    Java/Maven (app-access) wants:"
  echo "      DB_URL=jdbc:postgresql://localhost:15432/loom_app_access"
  echo "      DB_USERNAME=loom DB_PASSWORD=<from postgres-credentials secret>"
  echo "      (found the hard way 2026-09-11: app-access's own default port"
  echo "       is 5432, not 15432 -- always set DB_URL explicitly, never rely"
  echo "       on the default when testing against the forwarded port)"
fi

# ----------------------------------------------------------------------------
# STAGE 3 -- verify (real requests, not pod status)
# ----------------------------------------------------------------------------
if run_stage verify; then
  echo; echo "--- STAGE 3: verify the stack actually serves ---"
  if PW="$(kubectl get secret -n loom postgres-credentials -o jsonpath='{.data.password}' 2>/dev/null | base64 -d)" \
      && [ -n "$PW" ] \
      && ROLES="$(PGPASSWORD="$PW" psql -h 127.0.0.1 -p 15432 -U loom -d loom_app_access -t -c 'select count(*) from app_role;' 2>/dev/null | tr -d '[:space:]')" \
      && [ -n "$ROLES" ]; then
    echo "  Real psql query against loom_app_access: OK (app_role count = $ROLES)"
  else
    echo "  Real psql query against loom_app_access: FAILED"
    mark_fail
  fi

  if curl -s -m 8 http://192.168.56.10:30080/actuator/health/readiness 2>/dev/null | grep -q '"status":"UP"'; then
    echo "  app-access /actuator/health/readiness: UP"
  else
    echo "  app-access /actuator/health/readiness: NOT UP (or unreachable)"
    mark_fail
  fi

  if curl -s -m 8 -o /dev/null -w '%{http_code}' http://192.168.56.10:30083/healthz 2>/dev/null | grep -q '^200$'; then
    echo "  workflow-service /healthz: 200"
  else
    echo "  workflow-service /healthz: NOT 200"
    mark_fail
  fi
fi

# ----------------------------------------------------------------------------
# STAGE 4 -- validator (:8787)
# ----------------------------------------------------------------------------
if run_stage validator; then
  echo; echo "--- STAGE 4: community-package validator (:8787) ---"
  HEALTH_CODE="$(curl -s -m 5 -o /dev/null -w '%{http_code}' http://127.0.0.1:8787/health 2>/dev/null)"
  if [ "$HEALTH_CODE" = "200" ]; then
    VPID="$(pgrep -f '[v]alidator_server' | head -1)"
    if [ -n "$VPID" ]; then
      STARTED="$(ps -o lstart= -p "$VPID" 2>/dev/null)"
      echo "  Validator is up. Started: $STARTED"
    else
      echo "  Validator answers on :8787 but its process could not be resolved via pgrep."
    fi
    echo "  Latest commit touching validator/grammar/engine sources (compare"
    echo "  this date to the start time above -- if the commit is NEWER, the"
    echo "  running server predates your change and is answering from stale"
    echo "  grammar; restart it):"
    git -C "$REPO_ROOT" log -1 --format='    %ad  %h  %s' --date=iso \
      -- app/packages/tooling/loom_ux_judges/lib/src/validator \
         app/packages/core/loom_workflow_engine/lib/src/archetypes \
         docs/references/reference/workflow-grammar.md 2>/dev/null
    echo "  To force a restart regardless: kill the pid above (confirm identity"
    echo "  first), then:"
    echo "    cd \"$REPO_ROOT/app\" && dart run packages/tooling/loom_ux_judges/bin/validator_server.dart"
  else
    echo "  Validator NOT answering on :8787 (health check returned '$HEALTH_CODE'). Starting it."
    # NOT wrapped in a `( cd dir && cmd & disown )` subshell -- that was
    # tried first and left the WHOLE SCRIPT blocked in do_wait forever
    # (found by actually running this, 2026-09-11: `ps`/`/proc/<pid>/wchan`
    # showed this script's own pid asleep in do_wait, holding the SSH
    # channel open -- even though the backgrounded dart process itself had
    # its fds correctly redirected to a log file, not the channel). `cd` +
    # `setsid nohup ... & disown` directly in THIS shell, with a `cd -`
    # back afterward, is the exact idiom CLAUDE.md already documents and
    # the Codex dispatch scripts in this repo already rely on -- no subshell.
    cd "$REPO_ROOT/app"
    setsid nohup dart run packages/tooling/loom_ux_judges/bin/validator_server.dart \
      > "$REPO_ROOT/.codex-logs/recover_validator.log" 2>&1 < /dev/null &
    disown
    cd - >/dev/null
    echo "  Compiling and serving takes ~60s. Waiting up to 90s..."
    if wait_for 90 3 "validator /health 200" bash -c "[ \"\$(curl -s -m 5 -o /dev/null -w '%{http_code}' http://127.0.0.1:8787/health 2>/dev/null)\" = 200 ]"; then
      echo "  Validator now answers on :8787."
    else
      echo "  Validator still not answering after 90s -- check .codex-logs/recover_validator.log"
      mark_fail
    fi
  fi
fi

# ----------------------------------------------------------------------------
# STAGE 5 -- DeepSeek gateway (:8791)
# ----------------------------------------------------------------------------
if run_stage gateway; then
  echo; echo "--- STAGE 5: DeepSeek gateway (127.0.0.1:8791) ---"
  HEALTH="$(curl -s -m 5 http://127.0.0.1:8791/health 2>/dev/null)"
  THINKING="$(echo "$HEALTH" | grep -oE '"thinking":"[a-z]+"' | cut -d'"' -f4)"

  NEEDS_RESTART=0
  if [ -z "$HEALTH" ]; then
    echo "  Gateway not reachable (down, or never started -- this has happened"
    echo "  with NO OOM kill and NO error in its own log; do not spend time"
    echo "  hunting for a cause before just restarting it)."
    NEEDS_RESTART=1
  elif [ "$THINKING" != "disabled" ]; then
    echo "  Gateway is up but thinking mode = '$THINKING' (must be 'disabled')."
    echo "  With it enabled, DeepSeek's own API rejects any tool-call turn"
    echo "  whose reasoning was thin, discarding the whole in-flight ticket --"
    echo "  confirmed live 2026-09-11, cost two real dispatches before this fix."
    NEEDS_RESTART=1
  else
    echo "  Gateway healthy, thinking=disabled. $HEALTH"
  fi

  if [ "$NEEDS_RESTART" = 1 ]; then
    EXISTING_PID="$(ss -ltnp 2>/dev/null | grep ':8791 ' | grep -oE 'pid=[0-9]+' | head -1 | cut -d= -f2)"
    if [ -n "$EXISTING_PID" ]; then
      IDENTITY="$(ps -p "$EXISTING_PID" -o cmd= 2>/dev/null)"
      echo "  Found something on :8791 (pid $EXISTING_PID): $IDENTITY"
      case "$IDENTITY" in
        *server.mjs*)
          echo "  Confirmed it's the gateway's own node process -- killing pid $EXISTING_PID (not a pattern-kill, this exact pid)."
          kill "$EXISTING_PID"
          sleep 2
          ;;
        *)
          echo "  That pid does NOT look like the gateway (unexpected command). NOT killing it automatically."
          echo "  Investigate by hand before proceeding -- something else may be bound to this port."
          mark_fail
          ;;
      esac
    fi
    if [ -x "$HOME/deepseek-gateway/start.sh" ]; then
      echo "  Starting: ~/deepseek-gateway/start.sh"
      # Not subshell-wrapped -- see the identical comment on the validator
      # restart above; this exact shape hung the whole script the same way.
      cd "$HOME/deepseek-gateway"
      setsid nohup ./start.sh > gateway.log 2>&1 < /dev/null &
      disown
      cd - >/dev/null
      if wait_for 15 1 "gateway /health reachable" bash -c "curl -s -m 3 http://127.0.0.1:8791/health >/dev/null 2>&1"; then
        FINAL_HEALTH="$(curl -s -m 5 http://127.0.0.1:8791/health 2>/dev/null)"
        FINAL_THINKING="$(echo "$FINAL_HEALTH" | grep -oE '"thinking":"[a-z]+"' | cut -d'"' -f4)"
        echo "  Gateway restarted: $FINAL_HEALTH"
        if [ "$FINAL_THINKING" != "disabled" ]; then
          echo "  WARNING: restarted gateway still reports thinking='$FINAL_THINKING', expected 'disabled'."
          echo "  Check ~/deepseek-gateway/.env -- DEEPSEEK_THINKING=disabled must be set there."
          mark_fail
        fi
      else
        echo "  Gateway did not come up after start.sh -- check ~/deepseek-gateway/gateway.log"
        tail -20 "$HOME/deepseek-gateway/gateway.log" 2>/dev/null | sed 's/^/    /'
        mark_fail
      fi
    else
      echo "  ~/deepseek-gateway/start.sh not found or not executable -- cannot auto-start. Investigate by hand."
      mark_fail
    fi
  fi
fi

# ----------------------------------------------------------------------------
# STAGE 6 -- orphan sweep (VM side only; report, do not auto-kill)
# ----------------------------------------------------------------------------
if run_stage orphans; then
  echo; echo "--- STAGE 6: orphan sweep (VM side; report only, never auto-kills) ---"

  echo "  Ad-hoc 'until ... done' waiter shells still running:"
  FOUND=0
  while read -r line; do
    [ -z "$line" ] && continue
    echo "    $line"
    FOUND=1
  done < <(ps -ef | grep -E 'until .*done' | grep -v grep)
  [ "$FOUND" = 0 ] && echo "    none found"

  echo "  codex/claude/muse dispatch processes:"
  FOUND=0
  while read -r line; do
    [ -z "$line" ] && continue
    echo "    $line"
    FOUND=1
  done < <(ps -ef | grep -iE 'codex exec|claude -p|muse exec' | grep -v grep)
  [ "$FOUND" = 0 ] && echo "    none found"

  # `pgrep -f` alone matches ANY command line containing the pattern --
  # including this very script's own invocation, when it's run inside a
  # wrapper whose command line happens to quote "server.mjs" (hit this
  # live 2026-09-11: an ssh command that both grepped for and then ran
  # this script counted itself as a second gateway). Filter matches down
  # to processes whose actual `comm` is "node" -- a wrapper shell quoting
  # the string is not, only the real gateway process is.
  GATEWAY_COUNT=0
  GATEWAY_LINES=""
  for gp in $(pgrep -f 'server\.mjs' 2>/dev/null); do
    if [ "$(ps -p "$gp" -o comm= 2>/dev/null)" = "node" ]; then
      GATEWAY_COUNT=$((GATEWAY_COUNT + 1))
      GATEWAY_LINES="${GATEWAY_LINES}$(ps -p "$gp" -o pid=,cmd=)
"
    fi
  done
  echo "  DeepSeek gateway processes running: $GATEWAY_COUNT (should be exactly 1)"
  if [ "$GATEWAY_COUNT" -gt 1 ]; then
    echo "    MULTIPLE gateway processes -- resolve each pid and confirm before killing any:"
    printf '%s' "$GATEWAY_LINES" | sed 's/^/    /'
    mark_fail
  fi

  echo "  If anything above looks stale: resolve the pid, confirm its full"
  echo "  command line and identity, THEN kill that specific pid. Never"
  echo "  pattern-kill -- a dispatch's own command line can legitimately"
  echo "  contain the exact text you're searching for."
fi

echo
echo "===================================================================="
if [ "$OVERALL_STATUS" = 0 ]; then
  echo "recover_loom_vm.sh: ALL REQUESTED STAGES OK"
else
  echo "recover_loom_vm.sh: ONE OR MORE STAGES FAILED -- see output above"
fi
echo "===================================================================="
exit "$OVERALL_STATUS"
