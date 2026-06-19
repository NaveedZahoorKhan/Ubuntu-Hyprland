#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
SKIP_BASE=0
SKIP_SDDM=0
ENABLE_SDDM=1
SKIP_HYPRRICE=0
NO_REBOOT_PROMPT=0
USE_ICARUS_MONITOR_PROFILE=0

usage() {
  cat <<'EOF'
Usage: ./install-japanese-hyprland.sh [options]

One-click installer for the forked Ubuntu Hyprland setup. It runs the upstream
Ubuntu Hyprland install scripts, then applies the bundled Japanese aesthetic
dotfiles and SDDM theme.

Options:
  --custom-only       Skip upstream package/base install and apply custom layer only.
  --skip-sddm         Do not install/configure SDDM.
  --no-sddm-enable    Install SDDM theme but do not enable sddm.service.
  --skip-hyprrice     Do not install the HyprRice helper app.
  --use-icarus-monitor-profile
                      Apply the captured eDP-1 + HDMI-A-1 monitor layout.
  --no-reboot-prompt  Finish without asking to reboot.
  -h, --help          Show this help.
EOF
}

while (($#)); do
  case "$1" in
    --custom-only) SKIP_BASE=1 ;;
    --skip-sddm) SKIP_SDDM=1 ;;
    --no-sddm-enable) ENABLE_SDDM=0 ;;
    --skip-hyprrice) SKIP_HYPRRICE=1 ;;
    --use-icarus-monitor-profile) USE_ICARUS_MONITOR_PROFILE=1 ;;
    --no-reboot-prompt) NO_REBOOT_PROMPT=1 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage >&2; exit 2 ;;
  esac
  shift
done

if [[ $EUID -eq 0 ]]; then
  echo "Run this as your normal user; sudo is used only when needed." >&2
  exit 1
fi

sudo -v
mkdir -p "$ROOT_DIR/Install-Logs"

run_step() {
  local label="$1"
  shift
  echo
  echo "==> $label"
  "$@"
}

run_upstream_script() {
  local script="$1"
  run_step "Upstream: $script" env DEBIAN_FRONTEND=noninteractive bash "$ROOT_DIR/install-scripts/$script"
}

if [[ "$SKIP_BASE" -eq 0 ]]; then
  run_step "Install custom package prerequisites" bash "$ROOT_DIR/custom/install-required-libs.sh"
  run_upstream_script "02-pre-cleanup.sh"
  run_upstream_script "00-dependencies.sh"
  run_upstream_script "fonts.sh"
  run_upstream_script "01-hypr-pkgs.sh"
  run_upstream_script "hyprland-ppa.sh"
  run_upstream_script "wallust.sh"
  run_upstream_script "swww.sh"
  run_upstream_script "rofi-wayland.sh"
  run_upstream_script "hyprlock.sh"
  run_upstream_script "hypridle.sh"
  run_upstream_script "gtk_themes.sh"
  run_upstream_script "bluetooth.sh"
  run_upstream_script "thunar.sh"
  run_upstream_script "thunar_default.sh"
  run_upstream_script "InputGroup.sh"
  run_upstream_script "ags.sh"
  run_upstream_script "zsh.sh"
  run_upstream_script "zsh_pokemon.sh"
fi

if [[ "$SKIP_SDDM" -eq 0 ]]; then
  sddm_args=()
  [[ "$ENABLE_SDDM" -eq 0 ]] && sddm_args+=(--no-enable)
  run_step "Install Japanese SDDM theme" bash "$ROOT_DIR/custom/install-sddm-japanese.sh" "${sddm_args[@]}"
fi

dot_args=()
[[ "$SKIP_HYPRRICE" -eq 1 ]] && dot_args+=(--skip-hyprrice)
[[ "$USE_ICARUS_MONITOR_PROFILE" -eq 1 ]] && dot_args+=(--use-icarus-monitor-profile)
run_step "Apply custom Hyprland dotfiles" bash "$ROOT_DIR/custom/apply-dotfiles.sh" "${dot_args[@]}"

if [[ -x "$ROOT_DIR/install-scripts/03-Final-Check.sh" ]]; then
  run_step "Final upstream package check" bash "$ROOT_DIR/install-scripts/03-Final-Check.sh" || true
fi

echo
echo "Japanese Hyprland installer complete."
echo "A reboot is recommended before logging into Hyprland through SDDM."

if [[ "$NO_REBOOT_PROMPT" -eq 0 ]]; then
  read -r -p "Reboot now? [y/N]: " answer
  case "$answer" in
    y|Y|yes|YES) systemctl reboot ;;
  esac
fi
