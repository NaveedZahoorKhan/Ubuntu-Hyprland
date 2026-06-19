#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
BUNDLE="$ROOT_DIR/custom/payloads/hyprland-theme-dotfiles"
NO_LIVE_RELOAD=0
INSTALL_HYPRRICE=1

usage() {
  cat <<'EOF'
Usage: custom/apply-dotfiles.sh [--no-live-reload] [--skip-hyprrice]

Applies the bundled dotfile snapshot, including Waybar, Rofi, Hyprland fixes,
cursor/theme settings, live wallpaper helpers, SSH-agent startup, VPN button,
Print Screen bindings, hints, opacity shortcuts, and mpvpaper support.
EOF
}

while (($#)); do
  case "$1" in
    --no-live-reload) NO_LIVE_RELOAD=1 ;;
    --skip-hyprrice) INSTALL_HYPRRICE=0 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage >&2; exit 2 ;;
  esac
  shift
done

if [[ ! -x "$BUNDLE/install.sh" ]]; then
  echo "Missing bundled dotfile installer: $BUNDLE/install.sh" >&2
  exit 1
fi

if [[ "$NO_LIVE_RELOAD" -eq 1 ]]; then
  "$BUNDLE/install.sh" --no-live-reload
else
  "$BUNDLE/install.sh"
fi

if [[ "$INSTALL_HYPRRICE" -eq 1 && -x "$BUNDLE/install-hyprrice.sh" ]]; then
  "$BUNDLE/install-hyprrice.sh" || {
    echo "HyprRice helper install failed; dotfiles were still installed." >&2
  }
fi
