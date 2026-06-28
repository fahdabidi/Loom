#!/usr/bin/env bash
set -euo pipefail

pkg=com.example.loom_communities_demo
root=/data/user/0/com.example.loom_communities_demo/files
handles=(
  garden-club
  book-club
  youth-soccer
  cedar-hoa
  masjid-nur
  chess-club
  camera-club
  platform-social
  ad-off-demo
  portability-demo
)

delete_codes() {
  yes 67 | head -n 150 | tr '\n' ' '
}

clear_and_type() {
  local x=$1
  local y=$2
  local text=$3

  adb shell input tap "$x" "$y" >/dev/null
  sleep 0.25
  adb shell input keyevent 123 >/dev/null
  adb shell input keyevent $(delete_codes) >/dev/null
  sleep 0.1
  adb shell input text "$text" >/dev/null
  sleep 0.25
}

dump_ui() {
  local out=$1
  adb shell uiautomator dump /sdcard/window.xml >/dev/null
  adb pull /sdcard/window.xml "$out" >/dev/null
}

adb shell am force-stop "$pkg"
adb shell am start -n "$pkg/.MainActivity" >/dev/null
sleep 2

for handle in "${handles[@]}"; do
  echo "Installing $handle"
  adb shell input tap 800 2150 >/dev/null
  sleep 0.8
  clear_and_type 540 1135 "$root/$handle.loom-extension.zip"
  clear_and_type 540 1380 "$root/$handle.loom-init.zip"
  adb shell input tap 650 1635 >/dev/null
  sleep 1.4
done

dump_ui /mnt/c/Users/fahd_/OneDrive/Documents/Loom/.codex-logs/loom-loaded-all.xml
echo "Loaded ${#handles[@]} communities"
