#!/bin/bash
# loop_emitter.sh [registry_dir] [poll_seconds]
#
# The wake channel for named, recurring prompts. Wrap ONE instance of this in a
# persistent Monitor; it serves any number of loops.
#
# WHY THIS EXISTS (measured 2026-08-18, see loop.md section 4a): time-based
# waking does not work in this setup. `ScheduleWakeup` (a 25-minute relative
# delay silently registered as a daily absolute one-shot) and `CronCreate`
# (~32 consecutive missed firings) never fired once across two overnight
# stalls, while every Monitor fired promptly. Monitor is the only mechanism
# that reaches into a session unprompted -- each stdout line below becomes a
# task-notification -- so the cadence is emitted as EVENTS, never slept on.
#
# WHY NOT MCP: an MCP server is request/response. It can hold loop state, but
# it cannot wake a session on its own -- it only answers when already called,
# which is precisely the moment waking is unnecessary. The wake must come from
# Monitor.
#
# The emitted line carries the prompt text itself, which is what the woken
# session acts on.
#
# Usage (as a Monitor command, run LOCALLY -- it needs no VM access, and a
# heartbeat must not die with an ssh blip):
#   bash data/loop_emitter.sh
#
# Registry: one file per loop at <registry_dir>/<name>.loop, managed by
# loop_ctl.sh. Definitions are re-read on EVERY pass, so loops can be added,
# retuned, paused or removed with no need to re-arm the Monitor.
#
# Emits (each line is one Monitor event):
#   LOOP-FIRE <name> :: <prompt>   -- this loop is due; act on <prompt>
#   LOOP-EXPIRED <name> :: <why>   -- loop hit max_fires or expires_at and was
#                                     auto-disabled (emitted once)
#   LOOP-SKIP <name> :: <why>      -- malformed definition, skipped this pass
#
# IMPORTANT -- a fired prompt is a TRIGGER, NOT AUTHORIZATION. These arrive as
# task-notifications, which are explicitly not user input. A loop may tell the
# session to do work; it can never supply the fresh per-instance approval that
# community-JSON changes require (loop.md section 1.1).

set -uo pipefail

REG_DIR="${1:-data/loops}"
POLL_SECONDS="${2:-30}"

# Monitors that emit too frequently are throttled and eventually stopped
# automatically -- which would silently kill the wake channel. Enforced here as
# well as in loop_ctl.sh so a hand-edited registry file cannot bypass it.
MIN_INTERVAL=300

emit() { printf '%s\n' "$*"; }

read_field() {
  # read_field <file> <key> -- prints the value, empty if absent.
  # Splits on the FIRST '=' only, so prompt values may contain '='.
  local file="$1" key="$2" line k v
  while IFS= read -r line || [ -n "$line" ]; do
    case "$line" in
      "$key"=*)
        v="${line#*=}"
        printf '%s' "$v"
        return 0
        ;;
    esac
  done < "$file"
  printf ''
}

write_registry() {
  # write_registry <file> <interval> <enabled> <last_fired> <fires> <max_fires> <expires_at> <prompt>
  local file="$1"
  local tmp="${file}.tmp.$$"
  {
    printf 'interval=%s\n' "$2"
    printf 'enabled=%s\n' "$3"
    printf 'last_fired=%s\n' "$4"
    printf 'fires=%s\n' "$5"
    printf 'max_fires=%s\n' "$6"
    printf 'expires_at=%s\n' "$7"
    printf 'prompt=%s\n' "$8"
  } > "$tmp" && mv -f "$tmp" "$file"
}

is_uint() { case "${1:-}" in ''|*[!0-9]*) return 1 ;; *) return 0 ;; esac; }

# A malformed definition must be reported ONCE, not on every pass. Repeating it
# every poll would emit hundreds of events an hour, and Monitors that emit too
# frequently are throttled and eventually stopped -- so a single bad file would
# silently kill the wake channel it was meant to warn about. Found in testing
# 2026-08-18. Keyed by name+mtime so an edited file is re-checked and re-warned.
WARNED=" "
already_warned() {
  case "$WARNED" in *" $1 "*) return 0 ;; *) return 1 ;; esac
}
mark_warned() { WARNED="$WARNED$1 "; }

warn_once() {
  # warn_once <file> <name> <message>
  local key
  key="$2@$(date -r "$1" +%s 2>/dev/null || echo 0)"
  already_warned "$key" && return 0
  mark_warned "$key"
  emit "LOOP-SKIP $2 :: $3"
}


# ---------------------------------------------------------------------------
# Singleton guard. Multiple Monitors serving the same registry steal each
# other's ticks: whichever fires first stamps last_fired, so the others stay
# quiet, and an orphan (one surviving a dead session, or a harness that restarts
# a persistent monitor under a fresh task id) silently consumes the live
# channel's cadence. See the orphaned-emitter note in CLAUDE.md. One lock means
# exactly one emitter is ever live, regardless of how many are launched -- the
# losers exit immediately rather than fight over the registry.
LOCK_DIR="$REG_DIR/.emitter.lock"
if mkdir "$LOCK_DIR" 2>/dev/null; then
  printf '%s\n' "$$" > "$LOCK_DIR/pid"
  trap 'rm -rf "$LOCK_DIR"' EXIT INT TERM
else
  holder="$(cat "$LOCK_DIR/pid" 2>/dev/null || true)"
  if [ -n "$holder" ] && kill -0 "$holder" 2>/dev/null; then
    emit "EMITTER-SINGLETON :: another emitter (pid $holder) already serves $REG_DIR; exiting"
    exit 0
  fi
  # Stale lock (previous holder gone): take it over.
  printf '%s\n' "$$" > "$LOCK_DIR/pid"
  trap 'rm -rf "$LOCK_DIR"' EXIT INT TERM
fi

while true; do
  now="$(date +%s)"

  if [ -d "$REG_DIR" ]; then
    for file in "$REG_DIR"/*.loop; do
      [ -e "$file" ] || continue

      name="$(basename "$file" .loop)"

      interval="$(read_field "$file" interval)"
      enabled="$(read_field "$file" enabled)"
      last_fired="$(read_field "$file" last_fired)"
      fires="$(read_field "$file" fires)"
      max_fires="$(read_field "$file" max_fires)"
      expires_at="$(read_field "$file" expires_at)"
      prompt="$(read_field "$file" prompt)"

      # Defensive defaults: a malformed field must never crash the emitter,
      # because a dead emitter is a silently dead wake channel.
      is_uint "$last_fired" || last_fired=0
      is_uint "$fires"      || fires=0
      is_uint "$max_fires"  || max_fires=0
      is_uint "$expires_at" || expires_at=0

      [ "${enabled:-1}" = "0" ] && continue

      if ! is_uint "$interval"; then
        warn_once "$file" "$name" "interval is not a positive integer"
        continue
      fi
      if [ -z "$prompt" ]; then
        warn_once "$file" "$name" "empty prompt"
        continue
      fi
      if [ "$interval" -lt "$MIN_INTERVAL" ]; then
        warn_once "$file" "$name" "interval ${interval}s is below the ${MIN_INTERVAL}s floor (Monitor throttling risk)"
        continue
      fi

      # Auto-expiry, checked before firing.
      if [ "$expires_at" -gt 0 ] && [ "$now" -ge "$expires_at" ]; then
        write_registry "$file" "$interval" 0 "$last_fired" "$fires" "$max_fires" "$expires_at" "$prompt"
        emit "LOOP-EXPIRED $name :: reached expires_at; auto-disabled after $fires fire(s)"
        continue
      fi
      if [ "$max_fires" -gt 0 ] && [ "$fires" -ge "$max_fires" ]; then
        write_registry "$file" "$interval" 0 "$last_fired" "$fires" "$max_fires" "$expires_at" "$prompt"
        emit "LOOP-EXPIRED $name :: reached max_fires=$max_fires; auto-disabled"
        continue
      fi

      # Due?
      if [ $(( now - last_fired )) -ge "$interval" ]; then
        fires=$(( fires + 1 ))
        write_registry "$file" "$interval" 1 "$now" "$fires" "$max_fires" "$expires_at" "$prompt"
        emit "LOOP-FIRE $name :: $prompt"
      fi
    done
  fi

  sleep "$POLL_SECONDS"
done
