#!/usr/bin/env bash
set -euo pipefail

ACTION="${1:-decrease}"
STEP="${OPACITY_STEP:-0.10}"
MIN_OPACITY="${OPACITY_MIN:-0.25}"
MAX_OPACITY="${OPACITY_MAX:-1.00}"

notify_opacity() {
  local value="$1"

  if command -v notify-send >/dev/null 2>&1; then
    notify-send \
      -h string:x-canonical-private-synchronous:hypr-window-opacity \
      -u low \
      "Window opacity" "$value"
  fi
}

current_opacity() {
  local value

  value="$(hyprctl getprop active opacity 2>/dev/null | awk 'NF { print $1; exit }')"
  if [[ "$value" =~ ^[0-9]+([.][0-9]+)?$ ]]; then
    printf '%s\n' "$value"
  else
    printf '1\n'
  fi
}

set_opacity() {
  local value="$1"

  hyprctl dispatch setprop active opacity "$value" >/dev/null
  notify_opacity "$value"
}

case "$ACTION" in
  decrease|down|-)
    current="$(current_opacity)"
    next="$(
      awk -v current="$current" -v step="$STEP" -v min="$MIN_OPACITY" \
        'BEGIN { value = current - step; if (value < min) value = min; printf "%.2f", value }'
    )"
    set_opacity "$next"
    ;;
  increase|up|+)
    current="$(current_opacity)"
    next="$(
      awk -v current="$current" -v step="$STEP" -v max="$MAX_OPACITY" \
        'BEGIN { value = current + step; if (value > max) value = max; printf "%.2f", value }'
    )"
    set_opacity "$next"
    ;;
  reset)
    set_opacity "$MAX_OPACITY"
    ;;
  status)
    current_opacity
    ;;
  *)
    echo "Usage: $0 [decrease|increase|reset|status]" >&2
    exit 2
    ;;
esac
