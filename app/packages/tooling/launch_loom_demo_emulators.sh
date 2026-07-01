#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Launch Loom Communities Android emulators in a repeatable way.

Usage:
  bash app/packages/tooling/launch_loom_demo_emulators.sh [options]

Options:
  --mode primary|manual|both|attached
      Which emulator set to use. Default: both.
      "attached" does not launch an emulator; it runs against currently attached devices.
  --restart
      Stop attached emulator instances before launching. Required for reliable --mode both when any
      emulator is already running, because Android requires concurrent instances to start read-only.
  --run-app
      Run the Loom Communities Demo App after the target device boots.
  --app-target primary|manual|first|last
      Device to run the app on. Default: manual for --mode both, otherwise first.
  --preload-examples / --no-preload-examples
      Pass LOOM_PRELOAD_EXAMPLE_COMMUNITIES=true to flutter run. Default: preload.
  --wait-seconds <seconds>
      Boot wait timeout. Default: 420.
  --logs-dir <path>
      Directory for emulator logs. Default: <repo>/.codex-logs.
  --dry-run
      Print what would run without starting/stopping emulators or running Flutter.
  --help
      Show this help.

Environment overrides:
  PRIMARY_AVD, MANUAL_AVD, EMULATOR_BIN, ADB_BIN, FLUTTER_BIN

Recommended manual-review command from Windows:
  wsl.exe -d Ubuntu -- bash -lc 'cd "/mnt/c/Users/fahd_/OneDrive/Documents/Loom" && bash app/packages/tooling/launch_loom_demo_emulators.sh --restart --mode both --run-app --app-target manual'
EOF
}

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
app_root="$(cd "$script_dir/../.." && pwd)"
repo_root="$(cd "$app_root/.." && pwd)"
demo_app_dir="$app_root/apps/loom_communities_demo"

mode="both"
restart=false
run_app=false
app_target=""
preload_examples=true
wait_seconds=420
dry_run=false

primary_avd="${PRIMARY_AVD:-PantryVision_API_36}"
manual_avd="${MANUAL_AVD:-PantryVision_Manual_API_36}"
emulator_bin="${EMULATOR_BIN:-/usr/lib/android-sdk/emulator/emulator}"
adb_bin="${ADB_BIN:-/usr/lib/android-sdk/platform-tools/adb}"
flutter_bin="${FLUTTER_BIN:-$HOME/flutter/bin/flutter}"
logs_dir="${LOOM_EMULATOR_LOGS_DIR:-$repo_root/.codex-logs}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --mode)
      mode="${2:-}"
      shift 2
      ;;
    --restart)
      restart=true
      shift
      ;;
    --run-app)
      run_app=true
      shift
      ;;
    --app-target)
      app_target="${2:-}"
      shift 2
      ;;
    --preload-examples)
      preload_examples=true
      shift
      ;;
    --no-preload-examples)
      preload_examples=false
      shift
      ;;
    --wait-seconds)
      wait_seconds="${2:-}"
      shift 2
      ;;
    --logs-dir)
      logs_dir="${2:-}"
      shift 2
      ;;
    --dry-run)
      dry_run=true
      shift
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

case "$mode" in
  primary|manual|both|attached) ;;
  *)
    echo "Invalid --mode '$mode'. Expected primary, manual, both, or attached." >&2
    exit 2
    ;;
esac

if [[ -z "$app_target" ]]; then
  if [[ "$mode" == "both" ]]; then
    app_target="manual"
  else
    app_target="first"
  fi
fi

case "$app_target" in
  primary|manual|first|last) ;;
  *)
    echo "Invalid --app-target '$app_target'. Expected primary, manual, first, or last." >&2
    exit 2
    ;;
esac

log() {
  printf '[loom-emulators %s] %s\n' "$(date +%H:%M:%S)" "$*"
}

die() {
  echo "ERROR: $*" >&2
  exit 1
}

require_file() {
  local path="$1"
  local label="$2"
  [[ -e "$path" ]] || die "$label not found at $path"
}

run_cmd() {
  if [[ "$dry_run" == true ]]; then
    printf '+'
    printf ' %q' "$@"
    printf '\n'
  else
    "$@"
  fi
}

list_devices() {
  "$adb_bin" devices | awk '/^emulator-[0-9]+[[:space:]]+device$/ {print $1}' | sort -V
}

device_count() {
  list_devices | wc -l | tr -d ' '
}

ensure_avd_exists() {
  local avd="$1"
  if [[ "$dry_run" == true ]]; then
    log "Would verify AVD '$avd'"
    return 0
  fi
  "$emulator_bin" -list-avds | grep -Fx "$avd" >/dev/null ||
    die "AVD '$avd' was not found. Available AVDs: $("$emulator_bin" -list-avds | tr '\n' ' ')"
}

kill_attached_emulators() {
  mapfile -t devices < <(list_devices || true)
  if [[ "${#devices[@]}" -eq 0 ]]; then
    log "No attached emulator instances to stop."
    return 0
  fi

  for device in "${devices[@]}"; do
    log "Stopping attached emulator $device"
    run_cmd "$adb_bin" -s "$device" emu kill || true
  done

  if [[ "$dry_run" == true ]]; then
    return 0
  fi

  local start=$SECONDS
  while [[ "$(device_count)" -gt 0 ]]; do
    if (( SECONDS - start > 45 )); then
      die "Timed out waiting for existing emulators to stop. Close emulator windows and retry."
    fi
    sleep 2
  done
  log "Existing emulator instances stopped."
}

launch_avd() {
  local avd="$1"
  local label="$2"
  local timestamp
  timestamp="$(date +%Y%m%d-%H%M%S)"
  local out_log="$logs_dir/emulator-${label}-${timestamp}.out.log"
  local err_log="$logs_dir/emulator-${label}-${timestamp}.err.log"

  log "Launching $label AVD '$avd' with -read-only"
  log "Logs: $out_log / $err_log"

  if [[ "$dry_run" == true ]]; then
    printf '+ %q %q -read-only -no-snapshot-load -no-boot-anim\n' "$emulator_bin" "@$avd"
    return 0
  fi

  mkdir -p "$logs_dir"
  nohup "$emulator_bin" "@$avd" -read-only -no-snapshot-load -no-boot-anim \
    >"$out_log" 2>"$err_log" &
  echo "$!" >"$logs_dir/emulator-${label}-${timestamp}.pid"
}

wait_for_device_count() {
  local expected="$1"
  local start=$SECONDS

  while true; do
    local count
    count="$(device_count)"
    log "Boot progress: $count/$expected Android emulator device(s) attached."
    if [[ "$count" -ge "$expected" ]]; then
      return 0
    fi
    if (( SECONDS - start > wait_seconds )); then
      "$adb_bin" devices || true
      die "Timed out waiting for $expected emulator device(s). See $logs_dir/emulator-*.err.log."
    fi
    sleep 5
  done
}

wait_for_boot_completed() {
  local device="$1"
  local start=$SECONDS
  log "Waiting for $device to finish Android boot."
  "$adb_bin" -s "$device" wait-for-device
  while true; do
    local booted
    booted="$("$adb_bin" -s "$device" shell getprop sys.boot_completed 2>/dev/null | tr -d '\r' || true)"
    if [[ "$booted" == "1" ]]; then
      log "$device boot completed."
      return 0
    fi
    if (( SECONDS - start > wait_seconds )); then
      die "Timed out waiting for $device to boot."
    fi
    sleep 3
  done
}

select_app_device() {
  mapfile -t devices < <(list_devices)
  [[ "${#devices[@]}" -gt 0 ]] || die "No Android emulator devices are attached."

  case "$app_target" in
    first|primary)
      printf '%s\n' "${devices[0]}"
      ;;
    last|manual)
      printf '%s\n' "${devices[$((${#devices[@]} - 1))]}"
      ;;
  esac
}

run_demo_app() {
  local device="$1"
  local args=("$flutter_bin" run -d "$device")
  if [[ "$preload_examples" == true ]]; then
    args+=("--dart-define=LOOM_PRELOAD_EXAMPLE_COMMUNITIES=true")
  fi

  log "Running Loom Communities Demo App on $device from $demo_app_dir"
  log "This command keeps Flutter attached for manual review. Press Ctrl+C to stop."
  if [[ "$dry_run" == true ]]; then
    printf '+ cd %q &&' "$demo_app_dir"
    printf ' %q' "${args[@]}"
    printf '\n'
    return 0
  fi

  cd "$demo_app_dir"
  "${args[@]}"
}

require_file "$emulator_bin" "Android emulator binary"
require_file "$adb_bin" "adb binary"
require_file "$flutter_bin" "Flutter binary"
[[ -d "$demo_app_dir" ]] || die "Demo app directory not found at $demo_app_dir"

if [[ "$mode" == "primary" || "$mode" == "both" ]]; then
  ensure_avd_exists "$primary_avd"
fi
if [[ "$mode" == "manual" || "$mode" == "both" ]]; then
  ensure_avd_exists "$manual_avd"
fi

existing_count="$(device_count || true)"
if [[ "$restart" == true ]]; then
  kill_attached_emulators
elif [[ "$mode" != "attached" && "$existing_count" -gt 0 ]]; then
  die "Detected $existing_count attached emulator(s). For repeatable launches, rerun with --restart so all concurrent emulator windows start with -read-only."
fi

case "$mode" in
  primary)
    launch_avd "$primary_avd" "primary"
    expected_count=1
    ;;
  manual)
    launch_avd "$manual_avd" "manual"
    expected_count=1
    ;;
  both)
    launch_avd "$primary_avd" "primary"
    launch_avd "$manual_avd" "manual"
    expected_count=2
    ;;
  attached)
    expected_count=1
    ;;
esac

if [[ "$dry_run" == false ]]; then
  wait_for_device_count "$expected_count"
  mapfile -t attached_devices < <(list_devices)
  for device in "${attached_devices[@]}"; do
    wait_for_boot_completed "$device"
  done
  log "Attached emulator devices: ${attached_devices[*]}"
else
  log "Dry run complete."
fi

if [[ "$run_app" == true ]]; then
  if [[ "$dry_run" == true ]]; then
    target_device="<selected-$app_target-device>"
  else
    target_device="$(select_app_device)"
  fi
  run_demo_app "$target_device"
else
  log "Launch complete. Use --run-app to start the Demo App automatically."
fi
