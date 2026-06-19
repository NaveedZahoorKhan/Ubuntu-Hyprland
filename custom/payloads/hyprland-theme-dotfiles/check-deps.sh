#!/usr/bin/env bash
set -euo pipefail

PATH="$HOME/.local/bin:$PATH"
export PATH

required=(
  Hyprland
  hyprctl
  waybar
  rofi
  kitty
  swww
  mpv
  wallust
  swaync
  wlogout
  rsync
)

optional=(
  hyprlock
  hypridle
  grim
  slurp
  swappy
  wl-copy
  cliphist
  brightnessctl
  playerctl
  pamixer
  pavucontrol
  nm-connection-editor
  mpvpaper
  secret-tool
  zenity
  qt5ct
  qt6ct
  kvantummanager
  nwg-look
  yad
  jq
  python3
  hyprrice
)

missing_required=0

echo "Required:"
for cmd in "${required[@]}"; do
  if command -v "$cmd" >/dev/null 2>&1; then
    printf '  ok      %s\n' "$cmd"
  else
    printf '  missing %s\n' "$cmd"
    missing_required=1
  fi
done

echo
echo "Optional integrations:"
for cmd in "${optional[@]}"; do
  if command -v "$cmd" >/dev/null 2>&1; then
    printf '  ok      %s\n' "$cmd"
  else
    printf '  missing %s\n' "$cmd"
  fi
done

exit "$missing_required"
