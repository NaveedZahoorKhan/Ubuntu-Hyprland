#!/usr/bin/env bash
set -euo pipefail

MPVPAPER_BIN="${MPVPAPER_BIN:-$HOME/.local/bin/mpvpaper}"
DEFAULT_VIDEO_DIR="${MPVPAPER_VIDEO_DIR:-$HOME/Videos/Hidamari}"
FALLBACK_VIDEO="$HOME/Pictures/wallpapers/jake-the-dog.960x540.mp4"
OUTPUT="${MPVPAPER_OUTPUT:-ALL}"
MPV_OPTIONS="${MPVPAPER_OPTIONS:-no-audio loop panscan=1.0}"
SWWW_START="$HOME/.config/hypr/UserScripts/StartSwww.sh"
STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
STATE_DIR="$STATE_HOME/hyprland"
STATE_FILE="${MPVPAPER_STATE_FILE:-$STATE_DIR/mpvpaper-live-current}"

notify() {
  local title="$1"
  local body="${2:-}"

  if command -v notify-send >/dev/null 2>&1; then
    notify-send -u low "$title" "$body"
  fi
}

mpvpaper_active() {
  pgrep -x mpvpaper >/dev/null 2>&1
}

load_videos() {
  VIDEOS=()

  if [[ -d "$DEFAULT_VIDEO_DIR" ]]; then
    mapfile -d '' VIDEOS < <(
      find -L "$DEFAULT_VIDEO_DIR" -maxdepth 1 -type f \( \
        -iname '*.mp4' -o -iname '*.mkv' -o -iname '*.mov' -o -iname '*.webm' -o -iname '*.avi' \
      \) -print0 | sort -z
    )
  fi

  if [[ "${#VIDEOS[@]}" -eq 0 && -f "$FALLBACK_VIDEO" ]]; then
    VIDEOS=("$FALLBACK_VIDEO")
  fi
}

is_known_video() {
  local video="$1"
  local item

  for item in "${VIDEOS[@]}"; do
    [[ "$item" == "$video" ]] && return 0
  done

  return 1
}

current_video() {
  local stored=""

  load_videos
  [[ "${#VIDEOS[@]}" -gt 0 ]] || return 1

  if [[ -f "$STATE_FILE" ]]; then
    stored="$(<"$STATE_FILE")"
  fi

  if [[ -n "$stored" && -f "$stored" ]] && is_known_video "$stored"; then
    printf '%s\n' "$stored"
    return 0
  fi

  printf '%s\n' "${VIDEOS[0]}"
}

save_current_video() {
  mkdir -p "$STATE_DIR"
  printf '%s\n' "$1" >"$STATE_FILE"
}

next_video_path() {
  local direction="${1:-1}"
  local current
  local index=0
  local i
  local next_index

  load_videos
  [[ "${#VIDEOS[@]}" -gt 0 ]] || return 1

  current="$(current_video)"

  for i in "${!VIDEOS[@]}"; do
    if [[ "${VIDEOS[$i]}" == "$current" ]]; then
      index="$i"
      break
    fi
  done

  next_index=$(( (index + direction + ${#VIDEOS[@]}) % ${#VIDEOS[@]} ))
  printf '%s\n' "${VIDEOS[$next_index]}"
}

stop_swww() {
  if command -v swww >/dev/null 2>&1; then
    swww kill >/dev/null 2>&1 || true
  fi
  pkill -x swww-daemon >/dev/null 2>&1 || true
}

stop_mpvpaper() {
  pkill -x mpvpaper >/dev/null 2>&1 || true
  pkill -x mpvpaper-holder >/dev/null 2>&1 || true
}

start_mpvpaper() {
  local video="${1:-}"

  if [[ ! -x "$MPVPAPER_BIN" ]]; then
    notify "mpvpaper not installed" "$MPVPAPER_BIN"
    echo "mpvpaper not found or not executable: $MPVPAPER_BIN" >&2
    return 1
  fi

  if [[ -z "$video" ]]; then
    video="$(current_video)"
  elif [[ -d "$video" ]]; then
    DEFAULT_VIDEO_DIR="$video"
    video="$(current_video)"
  fi

  if [[ ! -f "$video" ]]; then
    notify "Live wallpaper missing" "$video"
    echo "Video file not found: $video" >&2
    return 1
  fi

  stop_mpvpaper
  stop_swww
  "$MPVPAPER_BIN" --fork --auto-pause --mpv-options "$MPV_OPTIONS" "$OUTPUT" "$video"
  save_current_video "$video"
  notify "mpvpaper started" "$(basename "$video")"
}

restore_swww() {
  stop_mpvpaper
  if [[ -x "$SWWW_START" ]]; then
    "$SWWW_START" >/dev/null 2>&1 &
  fi
  notify "mpvpaper stopped" "swww restored"
}

case "${1:-toggle}" in
  start)
    shift
    start_mpvpaper "${1:-}"
    ;;
  next)
    start_mpvpaper "$(next_video_path 1)"
    ;;
  previous|prev)
    start_mpvpaper "$(next_video_path -1)"
    ;;
  stop)
    restore_swww
    ;;
  toggle)
    shift || true
    if mpvpaper_active; then
      start_mpvpaper "$(next_video_path 1)"
    else
      start_mpvpaper "${1:-}"
    fi
    ;;
  current)
    current_video
    ;;
  list)
    load_videos
    printf '%s\n' "${VIDEOS[@]}"
    ;;
  status)
    if mpvpaper_active; then
      printf 'active: %s\n' "$(current_video)"
    else
      printf 'inactive: %s\n' "$(current_video)"
    fi
    ;;
  outputs)
    "$MPVPAPER_BIN" --help-output
    ;;
  *)
    echo "Usage: $0 [start [video|dir]|next|previous|stop|toggle [video|dir]|current|list|status|outputs]" >&2
    exit 2
    ;;
esac
