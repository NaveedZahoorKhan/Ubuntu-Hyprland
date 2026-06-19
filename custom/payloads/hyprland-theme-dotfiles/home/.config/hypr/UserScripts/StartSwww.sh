#!/usr/bin/env bash
set -euo pipefail

wallpaper="$HOME/.config/hypr/wallpaper_effects/.wallpaper_current"
fallback="$HOME/Pictures/wallpapers/Lady.png"
log_dir="${XDG_STATE_HOME:-$HOME/.local/state}/hyprland"
log_file="$log_dir/swww-startup.log"

mkdir -p "$log_dir"

if [[ ! -f "$wallpaper" && -f "$fallback" ]]; then
  mkdir -p "$(dirname -- "$wallpaper")"
  cp "$fallback" "$wallpaper"
fi

if ! pgrep -x swww-daemon >/dev/null 2>&1; then
  swww-daemon --format xrgb >>"$log_file" 2>&1 &
fi

for _ in {1..30}; do
  if swww query >/dev/null 2>&1; then
    break
  fi
  sleep 0.2
done

if ! swww query >/dev/null 2>&1; then
  echo "swww-daemon did not become ready" >>"$log_file"
  exit 1
fi

if [[ -f "$wallpaper" ]]; then
  swww img "$wallpaper" \
    --transition-type fade \
    --transition-duration 1 \
    --transition-fps 60 >>"$log_file" 2>&1
fi
