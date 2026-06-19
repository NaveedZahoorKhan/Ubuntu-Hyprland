#!/usr/bin/env bash
set -euo pipefail

STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
BACKUP_ROOT="$STATE_HOME/hyprland-theme-dotfiles/backups"
STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP_DIR="$BACKUP_ROOT/manual-$STAMP"

TARGETS=(
  ".config/hypr"
  ".config/waybar"
  ".config/rofi"
  ".config/wlogout"
  ".config/swaync"
  ".config/kitty"
  ".config/gtk-3.0"
  ".config/gtk-4.0"
  ".config/wallust"
  ".config/Kvantum"
  ".config/qt5ct"
  ".config/qt6ct"
  ".config/fastfetch"
  ".config/swappy"
  ".config/btop"
  ".config/cava"
  ".config/hyprrice/config.yaml"
  ".themes/Wal-GTK"
  ".themes/Wal-GTK-hdpi"
  ".themes/Flat-Remix-GTK-Blue-Dark"
  ".hyprrice/themes"
  ".hyprrice/.first_run"
  ".icons/catppuccin-frappe-maroon-cursors"
  ".icons/default/index.theme"
  ".local/bin/mpvpaper"
  ".local/bin/mpvpaper-holder"
  ".local/share/icons/kora"
  ".local/share/mpvpaper-deps"
  ".local/share/applications/hyprland-wallpaper-selector.desktop"
  ".local/share/applications/hyprrice.desktop"
  ".ssh/config"
  ".zshrc"
  "Pictures/wallpapers/Lady.png"
  "Pictures/wallpapers/jake-the-dog.960x540.mp4"
  "Pictures/wallpapers/Live-GIF/preview.gif"
)

if ! command -v rsync >/dev/null 2>&1; then
  echo "rsync is required for backup." >&2
  exit 1
fi

mkdir -p "$BACKUP_DIR"

for rel in "${TARGETS[@]}"; do
  target="$HOME/$rel"
  if [[ -e "$target" || -L "$target" ]]; then
    mkdir -p "$BACKUP_DIR/$(dirname -- "$rel")"
    rsync -a "$target" "$BACKUP_DIR/$(dirname -- "$rel")/"
  fi
done

echo "Backup saved at: $BACKUP_DIR"
