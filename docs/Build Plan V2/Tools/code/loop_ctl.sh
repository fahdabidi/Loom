#!/bin/bash
# loop_ctl.sh -- manage the recurring-prompt registry that loop_emitter.sh serves.
#
# The registry is plain files, re-read by the emitter on every pass, so every
# command here takes effect immediately with NO need to re-arm the Monitor.
#
# Usage:
#   bash data/loop_ctl.sh add <name> <interval_seconds> "<prompt>" [--max-fires N] [--hours H]
#   bash data/loop_ctl.sh rm <name>
#   bash data/loop_ctl.sh pause <name>
#   bash data/loop_ctl.sh resume <name>
#   bash data/loop_ctl.sh ls
#
# Defaults: --max-fires 200, --hours 24. Both are safety rails so a forgotten
# loop cannot fire indefinitely; pass 0 to either to disable that rail.
#
# The interval floor is 300s: Monitors that emit too frequently are throttled
# and eventually stopped automatically, which would silently kill the wake
# channel (loop.md section 4a).
#
# Registry lives in data/loops/ -- deliberately gitignored runtime state, so
# `git reset --hard` cannot revert it and it cannot trip the tracked-file
# hazard in loop.md section 1.1a.

set -uo pipefail

MIN_INTERVAL=300
REG_DIR="${LOOP_REGISTRY_DIR:-data/loops}"

usage() {
  sed -n '3,25p' "$0" | sed 's/^# \{0,1\}//'
  exit "${1:-64}"
}

is_uint() { case "${1:-}" in ''|*[!0-9]*) return 1 ;; *) return 0 ;; esac; }

valid_name() { case "$1" in ''|*[!a-zA-Z0-9_-]*) return 1 ;; *) return 0 ;; esac; }

read_field() {
  local file="$1" key="$2" line
  while IFS= read -r line || [ -n "$line" ]; do
    case "$line" in "$key"=*) printf '%s' "${line#*=}"; return 0 ;; esac
  done < "$file"
  printf ''
}

set_field() {
  # set_field <file> <key> <value> -- rewrites just that key, preserving order.
  local file="$1" key="$2" value="$3" tmp="${1}.tmp.$$" line found=0
  : > "$tmp"
  while IFS= read -r line || [ -n "$line" ]; do
    case "$line" in
      "$key"=*) printf '%s=%s\n' "$key" "$value" >> "$tmp"; found=1 ;;
      *)        printf '%s\n' "$line" >> "$tmp" ;;
    esac
  done < "$file"
  [ "$found" = "0" ] && printf '%s=%s\n' "$key" "$value" >> "$tmp"
  mv -f "$tmp" "$file"
}

cmd="${1:-}"
[ -z "$cmd" ] && usage 64
shift || true

case "$cmd" in
  add)
    name="${1:-}"; interval="${2:-}"; prompt="${3:-}"
    shift 3 2>/dev/null || { echo "add: need <name> <interval_seconds> \"<prompt>\"" >&2; exit 64; }

    max_fires=200
    hours=24
    while [ $# -gt 0 ]; do
      case "$1" in
        --max-fires) max_fires="${2:-}"; shift 2 ;;
        --hours)     hours="${2:-}";     shift 2 ;;
        *) echo "add: unknown option '$1'" >&2; exit 64 ;;
      esac
    done

    valid_name "$name" || { echo "add: name must be [A-Za-z0-9_-]+ (got '$name')" >&2; exit 64; }
    is_uint "$interval" || { echo "add: interval must be a positive integer" >&2; exit 64; }
    is_uint "$max_fires" || { echo "add: --max-fires must be an integer" >&2; exit 64; }
    is_uint "$hours" || { echo "add: --hours must be an integer" >&2; exit 64; }
    [ -n "$prompt" ] || { echo "add: prompt must not be empty" >&2; exit 64; }

    if [ "$interval" -lt "$MIN_INTERVAL" ]; then
      echo "add: interval ${interval}s is below the ${MIN_INTERVAL}s floor." >&2
      echo "     Monitors that emit too frequently are throttled and stopped," >&2
      echo "     which silently kills the wake channel. Use ${MIN_INTERVAL}s or more." >&2
      exit 64
    fi

    case "$prompt" in *$'\n'*)
      echo "add: prompt must be a single line (it is emitted as one event)" >&2; exit 64 ;;
    esac

    expires_at=0
    [ "$hours" -gt 0 ] && expires_at=$(( $(date +%s) + hours * 3600 ))

    mkdir -p "$REG_DIR"
    file="$REG_DIR/$name.loop"
    {
      printf 'interval=%s\n' "$interval"
      printf 'enabled=%s\n' 1
      printf 'last_fired=%s\n' 0
      printf 'fires=%s\n' 0
      printf 'max_fires=%s\n' "$max_fires"
      printf 'expires_at=%s\n' "$expires_at"
      printf 'prompt=%s\n' "$prompt"
    } > "$file"

    echo "added '$name': every ${interval}s, max_fires=${max_fires}, expires_at=${expires_at}"
    echo "  prompt: $prompt"
    echo "  NOTE: fires on the NEXT emitter pass (last_fired=0 means due immediately)."
    ;;

  rm)
    name="${1:?rm: need <name>}"
    file="$REG_DIR/$name.loop"
    [ -e "$file" ] || { echo "rm: no such loop '$name'" >&2; exit 1; }
    rm -f "$file" && echo "removed '$name'"
    ;;

  pause|resume)
    name="${1:?$cmd: need <name>}"
    file="$REG_DIR/$name.loop"
    [ -e "$file" ] || { echo "$cmd: no such loop '$name'" >&2; exit 1; }
    [ "$cmd" = "pause" ] && set_field "$file" enabled 0 || set_field "$file" enabled 1
    echo "${cmd}d '$name'"
    ;;

  ls)
    if [ ! -d "$REG_DIR" ] || [ -z "$(ls -A "$REG_DIR" 2>/dev/null)" ]; then
      echo "(no loops registered in $REG_DIR)"
      exit 0
    fi
    now="$(date +%s)"
    printf '%-16s %-8s %-9s %-7s %-12s %s\n' NAME INTERVAL ENABLED FIRES NEXT_IN PROMPT
    for file in "$REG_DIR"/*.loop; do
      [ -e "$file" ] || continue
      n="$(basename "$file" .loop)"
      iv="$(read_field "$file" interval)"
      en="$(read_field "$file" enabled)"
      lf="$(read_field "$file" last_fired)"
      fr="$(read_field "$file" fires)"
      pr="$(read_field "$file" prompt)"
      is_uint "$iv" || iv=0
      is_uint "$lf" || lf=0
      nxt="due"
      if [ "$iv" -gt 0 ]; then
        remain=$(( lf + iv - now ))
        [ "$remain" -gt 0 ] && nxt="${remain}s"
      fi
      [ "${en:-1}" = "0" ] && nxt="paused"
      printf '%-16s %-8s %-9s %-7s %-12s %s\n' "$n" "${iv}s" "${en:-1}" "${fr:-0}" "$nxt" "$pr"
    done
    ;;

  -h|--help|help) usage 0 ;;
  *) echo "unknown command '$cmd'" >&2; usage 64 ;;
esac
